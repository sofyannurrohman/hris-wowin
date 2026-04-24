<script setup lang="ts">
import { ref, onMounted, h, computed } from 'vue'
import { toast } from 'vue-sonner'
import { 
  Pencil, 
  Trash2, 
  CheckCircle2, 
  XCircle, 
  Clock, 
  Calendar, 
  Info,
  MoreVertical,
  ChevronRight,
  Plus
} from 'lucide-vue-next'
import apiClient from '@/api/axios'
import DataTable from '@/components/DataTable.vue'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()
const isLoading = ref(true)
const allOvertimes = ref<any[]>([])
const myOvertimes = ref<any[]>([])
const activeTab = ref('all') // 'all' or 'me'
const isSubmitting = ref(false)

const isAdmin = computed(() => {
  const roles = ['superadmin', 'hr_admin', 'manager']
  return authStore.user && roles.includes(authStore.user.role)
})

// Initialize activeTab based on role
onMounted(() => {
  if (!isAdmin.value) {
    activeTab.value = 'me'
  }
})

// Form State
const isModalOpen = ref(false)
const isEditMode = ref(false)
const requestForm = ref({
  id: '',
  date: new Date().toISOString().split('T')[0],
  start_time: '17:00',
  end_time: '19:00',
  duration_minutes: 120,
  type: 'working_day',
  reason: ''
})

// Reject modal
const isRejectModalOpen = ref(false)
const selectedOvertimeId = ref<string>('')
const rejectReason = ref<string>('')

const overtimeTypes = [
  { value: 'working_day', label: 'Hari Kerja' },
  { value: 'holiday', label: 'Hari Libur / Weekend' }
]

const columns = [
  {
    accessorKey: 'name',
    header: 'KARYAWAN',
    cell: ({ row }: any) => {
       const item = row.original
       return h('div', { class: 'flex items-center gap-3' }, [
         h('div', { 
           class: 'w-8 h-8 rounded-full bg-primary/10 text-primary flex items-center justify-center font-bold text-[10px] border border-primary/20' 
         }, item.name.substring(0, 2).toUpperCase()),
         h('div', { class: 'flex flex-col' }, [
           h('span', { class: 'font-bold text-gray-900 leading-tight' }, item.name),
           h('span', { class: 'text-[11px] text-gray-500 uppercase tracking-wider' }, item.type_label)
         ])
       ])
    }
  },
  {
    accessorKey: 'date',
    header: 'TANGGAL & WAKTU',
    cell: ({ row }: any) => {
      const item = row.original
      return h('div', { class: 'flex flex-col' }, [
        h('div', { class: 'flex items-center gap-1.5 text-gray-900 font-medium' }, [
          h(Calendar, { class: 'w-3.5 h-3.5 text-gray-400' }),
          h('span', {}, item.date_formatted)
        ]),
        h('div', { class: 'flex items-center gap-1.5 text-gray-500 text-[12px]' }, [
          h(Clock, { class: 'w-3.5 h-3.5' }),
          h('span', {}, `${item.start_time_only} - ${item.end_time_only} (${item.duration_formatted})`)
        ])
      ])
    }
  },
  {
    accessorKey: 'reason',
    header: 'KETERANGAN',
    cell: (info: any) => h('div', { class: 'max-w-[200px]' }, [
      h('p', { class: 'text-[13px] text-gray-600 line-clamp-2 leading-relaxed italic' }, `"${info.getValue() || '-'}"`)
    ])
  },
  {
    accessorKey: 'status',
    header: 'STATUS',
    cell: ({ row }: any) => {
        const val = row.original.status || 'pending'
        let styles = 'bg-amber-50 text-amber-700 border-amber-200'
        let icon = Clock
        
        if (val === 'approved') {
          styles = 'bg-emerald-50 text-emerald-700 border-emerald-200'
          icon = CheckCircle2
        } else if (val === 'rejected') {
          styles = 'bg-rose-50 text-rose-700 border-rose-200'
          icon = XCircle
        }
        
        return h('div', { class: 'flex flex-col gap-1' }, [
          h('span', { class: `${styles} border px-2.5 py-0.5 rounded-full text-[11px] font-bold inline-flex items-center gap-1.5 w-fit uppercase tracking-wider` }, [
            h(icon, { class: 'w-3 h-3' }),
            val
          ]),
          row.original.reject_reason ? h('span', { class: 'text-[10px] text-rose-500 font-medium ml-1 truncate max-w-[120px]' }, `Ket: ${row.original.reject_reason}`) : null
        ])
    }
  },
  {
    id: 'actions',
    header: 'AKSI',
    cell: ({ row }: any) => {
        const item = row.original
        const isOwner = authStore.user && item.employee_id === authStore.user.employee_id
        
        return h('div', { class: 'flex items-center gap-2' }, [
          // Admin Actions (Approve/Reject)
          item.status === 'pending' && isAdmin.value ? [
            h(Button, {
              variant: 'ghost',
              size: 'sm',
              class: 'h-8 px-2 text-emerald-600 hover:text-emerald-700 hover:bg-emerald-50',
              onClick: () => updateStatus(item.id, 'approved')
            }, () => h(CheckCircle2, { class: 'w-4 h-4' })),
            h(Button, {
              variant: 'ghost',
              size: 'sm',
              class: 'h-8 px-2 text-rose-600 hover:text-rose-700 hover:bg-rose-50',
              onClick: () => openRejectModal(item.id)
            }, () => h(XCircle, { class: 'w-4 h-4' }))
          ] : null,
          
          // Owner Actions (Edit/Delete)
          item.status === 'pending' && (isOwner || isAdmin.value) ? [
            h(Button, {
              variant: 'ghost',
              size: 'sm',
              class: 'h-8 px-2 text-slate-400 hover:text-slate-900',
              onClick: () => openEditModal(item)
            }, () => h(Pencil, { class: 'w-4 h-4' })),
            h(Button, {
              variant: 'ghost',
              size: 'sm',
              class: 'h-8 px-2 text-slate-400 hover:text-rose-600',
              onClick: () => deleteOvertime(item.id)
            }, () => h(Trash2, { class: 'w-4 h-4' }))
          ] : null,
          
          // Finalized Label
          item.status !== 'pending' ? h('span', { class: 'text-[11px] font-bold text-slate-300 uppercase' }, 'Selesai') : null
        ])
    }
  }
]

const fetchOvertimes = async () => {
  isLoading.value = true
  try {
    const requests = [apiClient.get('/overtimes/me')]
    if (isAdmin.value) {
      requests.push(apiClient.get('/overtimes/'))
    }
    
    const responses = await Promise.all(requests)
    
    const transform = (item: any) => ({
      ...item,
      name: item.Employee?.first_name || 'Karyawan',
      type_label: overtimeTypes.find(t => t.value === item.type)?.label || 'Lembur',
      date_formatted: new Date(item.date).toLocaleDateString('id-ID', { day: '2-digit', month: 'long', year: 'numeric' }),
      start_time_only: new Date(item.start_time).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }),
      end_time_only: new Date(item.end_time).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }),
      duration_formatted: `${Math.floor(item.duration_minutes / 60)}j ${item.duration_minutes % 60}m`
    })

    const myRes = responses[0]
    if (myRes && myRes.data) {
      myOvertimes.value = (myRes.data.data || []).map(transform)
    }

    if (isAdmin.value && responses.length > 1) {
      const allRes = responses[1]
      if (allRes && allRes.data) {
        allOvertimes.value = (allRes.data.data || []).map(transform)
      }
    }
  } catch (e) {
    console.error('Failed to fetch overtime data', e)
    toast.error('Gagal mengambil data lembur')
  } finally {
    isLoading.value = false
  }
}

const calculateDuration = () => {
  if (requestForm.value.start_time && requestForm.value.end_time) {
    const start = new Date(`2000-01-01T${requestForm.value.start_time}`)
    const end = new Date(`2000-01-01T${requestForm.value.end_time}`)
    let diff = (end.getTime() - start.getTime()) / (1000 * 60)
    if (diff < 0) diff += 24 * 60 // Handle overnight
    requestForm.value.duration_minutes = Math.max(0, diff)
  }
}

const openAddModal = () => {
  isEditMode.value = false
  requestForm.value = {
    id: '',
    date: new Date().toISOString().split('T')[0],
    start_time: '17:00',
    end_time: '19:00',
    duration_minutes: 120,
    type: 'working_day',
    reason: ''
  }
  isModalOpen.value = true
}

const openEditModal = (item: any) => {
  isEditMode.value = true
  requestForm.value = {
    id: item.id,
    date: new Date(item.date).toISOString().split('T')[0],
    start_time: new Date(item.start_time).toTimeString().substring(0, 5),
    end_time: new Date(item.end_time).toTimeString().substring(0, 5),
    duration_minutes: item.duration_minutes,
    type: item.type || 'working_day',
    reason: item.reason || ''
  }
  isModalOpen.value = true
}

const saveOvertime = async () => {
  if (!requestForm.value.reason.trim()) {
    toast.error('Alasan lembur harus diisi')
    return
  }
  
  isSubmitting.value = true
  try {
    const payload = {
      ...requestForm.value,
      start_time: new Date(`${requestForm.value.date}T${requestForm.value.start_time}:00`).toISOString(),
      end_time: new Date(`${requestForm.value.date}T${requestForm.value.end_time}:00`).toISOString(),
      duration_minutes: Number(requestForm.value.duration_minutes)
    }

    if (isEditMode.value) {
      await apiClient.put(`/overtimes/${requestForm.value.id}`, payload)
      toast.success('Pengajuan lembur diperbarui')
    } else {
      await apiClient.post('/overtimes/', payload)
      toast.success('Pengajuan lembur berhasil dikirim')
    }
    
    isModalOpen.value = false
    fetchOvertimes()
  } catch (e: any) {
    toast.error('Gagal menyimpan data: ' + (e.response?.data?.message || e.message))
  } finally {
    isSubmitting.value = false
  }
}

const deleteOvertime = async (id: string) => {
  if (!confirm('Hapus pengajuan lembur ini?')) return
  try {
    await apiClient.delete(`/overtimes/${id}`)
    toast.success('Pengajuan dihapus')
    fetchOvertimes()
  } catch (e: any) {
    toast.error('Gagal menghapus: ' + (e.response?.data?.message || e.message))
  }
}

const updateStatus = async (id: string, newStatus: string) => {
  if (newStatus === 'approved' && !confirm('Setujui lembur ini?')) return
  isSubmitting.value = true
  try {
    await apiClient.put(`/overtimes/${id}/status`, { status: newStatus })
    toast.success(`Lembur ${newStatus === 'approved' ? 'disetujui' : 'ditolak'}`)
    fetchOvertimes()
  } catch (e: any) {
    toast.error('Gagal update status: ' + (e.response?.data?.message || e.message))
  } finally {
    isSubmitting.value = false
  }
}

const openRejectModal = (id: string) => {
  selectedOvertimeId.value = id
  rejectReason.value = ''
  isRejectModalOpen.value = true
}

const confirmReject = async () => {
  if (!rejectReason.value.trim()) {
    toast.error('Alasan penolakan harus diisi')
    return
  }
  isSubmitting.value = true
  try {
    await apiClient.put(`/overtimes/${selectedOvertimeId.value}/status`, {
      status: 'rejected',
      reject_reason: rejectReason.value
    })
    toast.success('Pengajuan ditolak')
    isRejectModalOpen.value = false
    fetchOvertimes()
  } catch (e: any) {
    toast.error('Gagal menolak: ' + (e.response?.data?.message || e.message))
  } finally {
    isSubmitting.value = false
  }
}

onMounted(() => {
  fetchOvertimes()
})
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h1 class="text-[24px] font-black text-slate-900 tracking-tight leading-tight italic">Manajemen Lembur</h1>
        <p class="text-[14px] text-slate-500 mt-1 font-medium italic">Kelola penugasan waktu kerja tambahan dan persetujuan.</p>
      </div>
      <div class="flex items-center gap-3">
        <Button @click="openAddModal" class="gap-2 shadow-lg shadow-primary/20 rounded-2xl h-11 px-6 font-bold" size="sm">
          <Plus class="w-4 h-4" />
          Ajukan Lembur
        </Button>
      </div>
    </div>

    <!-- Tabs for filtering -->
    <div class="flex items-center gap-1 bg-slate-100 p-1.5 rounded-2xl w-fit">
      <button 
        v-if="isAdmin"
        @click="activeTab = 'all'" 
        class="px-5 py-2 rounded-xl text-[13px] font-bold transition-all"
        :class="activeTab === 'all' ? 'bg-white text-primary shadow-sm ring-1 ring-slate-200' : 'text-slate-500 hover:text-slate-700'"
      >
        Semua Pengajuan
      </button>
      <button 
        @click="activeTab = 'me'" 
        class="px-5 py-2 rounded-xl text-[13px] font-bold transition-all"
        :class="activeTab === 'me' ? 'bg-white text-primary shadow-sm ring-1 ring-slate-200' : 'text-slate-500 hover:text-slate-700'"
      >
        Pengajuan Saya
      </button>
    </div>

    <!-- Table container -->
    <div class="bg-white rounded-[2.5rem] border border-slate-100 shadow-xl shadow-slate-200/50 overflow-hidden">
      <DataTable 
        :data="activeTab === 'all' ? allOvertimes : myOvertimes" 
        :columns="columns" 
        :isLoading="isLoading"
      />
    </div>

    <!-- Add/Edit Modal -->
    <Dialog v-model:open="isModalOpen">
      <DialogContent class="sm:max-w-xl rounded-[2.5rem] md:rounded-[3.5rem] p-0 overflow-hidden border-none shadow-2xl flex flex-col">
        <div class="bg-slate-900 p-8 md:p-12 text-white relative shrink-0">
          <DialogHeader>
            <DialogTitle class="text-2xl md:text-3xl font-black tracking-tight italic">{{ isEditMode ? 'Koreksi Data' : 'Buat Pengajuan' }}</DialogTitle>
            <DialogDescription class="text-slate-400 font-bold mt-2 uppercase text-[10px] md:text-[11px] tracking-[0.2em] border-l-4 border-primary pl-4 leading-relaxed">
              Pastikan jam lembur sesuai dengan aktivitas pekerjaan aktual.
            </DialogDescription>
          </DialogHeader>
        </div>
        
        <div class="p-8 md:p-12 bg-white space-y-8 overflow-y-auto max-h-[60vh] custom-scrollbar">
          <div class="grid grid-cols-2 gap-6">
            <div class="space-y-2">
              <label class="text-[12px] font-black text-slate-400 uppercase tracking-widest ml-1">Tanggal</label>
              <div class="relative">
                <Calendar class="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                <Input v-model="requestForm.date" type="date" class="pl-11 h-12 rounded-2xl bg-slate-50 border-none font-bold" />
              </div>
            </div>
            <div class="space-y-2">
              <label class="text-[12px] font-black text-slate-400 uppercase tracking-widest ml-1">Tipe Hari</label>
              <Select v-model="requestForm.type">
                <SelectTrigger class="h-12 rounded-2xl bg-slate-50 border-none font-bold focus:ring-0">
                  <SelectValue placeholder="Pilih Tipe" />
                </SelectTrigger>
                <SelectContent class="rounded-xl border-slate-100 shadow-xl">
                  <SelectItem v-for="t in overtimeTypes" :key="t.value" :value="t.value" class="font-bold py-3">{{ t.label }}</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <div class="grid grid-cols-2 gap-6">
            <div class="space-y-2">
              <label class="text-[12px] font-black text-slate-400 uppercase tracking-widest ml-1">Mulai</label>
              <Input v-model="requestForm.start_time" type="time" @input="calculateDuration" class="h-12 rounded-2xl bg-slate-50 border-none font-bold" />
            </div>
            <div class="space-y-2">
              <label class="text-[12px] font-black text-slate-400 uppercase tracking-widest ml-1">Selesai</label>
              <Input v-model="requestForm.end_time" type="time" @input="calculateDuration" class="h-12 rounded-2xl bg-slate-50 border-none font-bold" />
            </div>
          </div>

          <div class="p-6 bg-primary/5 rounded-[2.5rem] border border-primary/10 flex items-center justify-between">
            <div class="flex items-center gap-4">
              <div class="bg-primary/10 p-3 rounded-2xl text-primary shadow-sm shadow-primary/10">
                <Clock class="w-6 h-6" />
              </div>
              <div>
                <p class="text-[11px] font-black text-primary/60 uppercase tracking-[0.2em] mb-1">Durasi Kalkulasi</p>
                <p class="text-xl font-black text-primary leading-none">{{ Math.floor(requestForm.duration_minutes / 60) }}j {{ requestForm.duration_minutes % 60 }}m</p>
              </div>
            </div>
            <div class="text-right">
               <span class="text-[10px] font-bold text-slate-400 italic">Terhitung Otomatis</span>
            </div>
          </div>

          <div class="space-y-2">
            <label class="text-[12px] font-black text-slate-400 uppercase tracking-widest ml-1">Tugas / Alasan Lembur</label>
            <div class="relative group">
              <Info class="absolute left-4 top-4 w-4 h-4 text-slate-300 group-focus-within:text-primary transition-colors duration-300" />
              <textarea 
                v-model="requestForm.reason" 
                placeholder="Deskripsikan pekerjaan yang Anda selesaikan..." 
                class="w-full min-h-[120px] pl-11 pr-4 py-4 rounded-3xl bg-slate-50 border-none font-bold text-slate-700 placeholder:text-slate-300 focus:ring-4 focus:ring-primary/5 transition-all outline-none resize-none"
              ></textarea>
            </div>
          </div>
        </div>

        <DialogFooter class="p-8 md:p-12 pt-0 bg-white grid grid-cols-2 gap-4 shrink-0 border-t border-slate-50 pt-8">
          <Button variant="ghost" @click="isModalOpen = false" :disabled="isSubmitting" class="rounded-2xl h-14 font-black text-slate-400 border border-slate-100 hover:bg-slate-50 transition-all">BATAL</Button>
          <Button @click="saveOvertime" :disabled="isSubmitting" class="bg-primary hover:bg-primary/90 text-white rounded-2xl h-14 font-black shadow-xl shadow-primary/20 transform active:scale-95 transition-all uppercase tracking-widest">
            {{ isSubmitting ? 'MENYIMPAN...' : 'SIMPAN DATA' }}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>

    <!-- Reject Reason Modal -->
    <Dialog v-model:open="isRejectModalOpen">
      <DialogContent class="sm:max-w-md rounded-[2.5rem] p-0 overflow-hidden border-none shadow-2xl flex flex-col">
        <div class="bg-rose-900 p-8 text-white relative shrink-0">
          <DialogHeader>
            <DialogTitle class="text-xl font-black uppercase tracking-tighter italic">Tolak Pengajuan</DialogTitle>
            <DialogDescription class="text-rose-300 font-bold mt-2 uppercase text-[10px] tracking-widest border-l-4 border-white/30 pl-4">
              Wajib menyertakan alasan penolakan.
            </DialogDescription>
          </DialogHeader>
        </div>
        <div class="p-8 bg-white space-y-6">
          <div class="space-y-2">
            <label class="text-[12px] font-black text-slate-400 uppercase tracking-widest ml-1">Alasan Penolakan</label>
            <textarea 
              v-model="rejectReason" 
              placeholder="Contoh: Belum ada koordinasi supervisor, tugas bisa diselesaikan di jam reguler..." 
              class="w-full min-h-[100px] px-5 py-4 rounded-3xl bg-slate-50 border-none font-bold text-slate-700 outline-none focus:ring-4 focus:ring-rose-500/5 transition-all resize-none"
            ></textarea>
          </div>
        </div>
        <DialogFooter class="p-8 pt-0 bg-white grid grid-cols-2 gap-4">
          <Button variant="ghost" @click="isRejectModalOpen = false" class="rounded-2xl h-14 font-black text-slate-400 border border-slate-100">BATAL</Button>
          <Button @click="confirmReject" :disabled="isSubmitting || !rejectReason.trim()" class="bg-rose-600 hover:bg-rose-700 text-white rounded-2xl h-14 font-black shadow-xl shadow-rose-600/20 uppercase tracking-widest">
            KONFIRMASI
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  </div>
</template>

<style scoped>
.custom-scrollbar::-webkit-scrollbar {
  width: 6px;
}
.custom-scrollbar::-webkit-scrollbar-track {
  background: #f8fafc;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background: #e2e8f0;
  border-radius: 10px;
}
.custom-scrollbar::-webkit-scrollbar-thumb:hover {
  background: #cbd5e1;
}
</style>
