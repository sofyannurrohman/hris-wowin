<script setup lang="ts">
import { ref, onMounted, h } from 'vue'
import { toast } from 'vue-sonner'
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

const isLoading = ref(true)
const displayData = ref<any[]>([])
const isSubmitting = ref(false)

// Request Overtime modal
const isRequestModalOpen = ref(false)
const requestForm = ref({
  date: new Date().toISOString().split('T')[0],
  start_time: '',
  end_time: '',
  duration_minutes: 60,
  reason: ''
})

// Reject modal
const isRejectModalOpen = ref(false)
const selectedOvertimeId = ref<string>('')
const rejectReason = ref<string>('')

const columns = [
  {
    accessorKey: 'name',
    header: 'KARYAWAN',
    cell: ({ row }: any) => {
       const user = row.original
       return h('div', { class: 'flex items-center gap-3' }, [
         h('img', { src: user.avatar, class: 'w-8 h-8 rounded-full border border-gray-200 object-cover' }),
         h('div', { class: 'font-bold text-gray-900 leading-tight' }, user.name)
       ])
    }
  },
  {
    accessorKey: 'date',
    header: 'TANGGAL',
    cell: (info: any) => h('span', { class: 'text-gray-600 text-[13px]' }, info.getValue())
  },
  {
    accessorKey: 'duration',
    header: 'DURASI',
    cell: (info: any) => h('span', { class: 'font-bold text-gray-900' }, info.getValue())
  },
  {
    accessorKey: 'reason',
    header: 'ALASAN',
    cell: (info: any) => h('span', { class: 'text-[13px] text-gray-600 truncate max-w-[200px] block' }, info.getValue())
  },
  {
    accessorKey: 'status',
    header: 'STATUS',
    cell: ({ getValue }: any) => {
        const val = (getValue() as string) || ''
        let classes = 'border border-[#fef08a] text-[#ca8a04]' // pending
        if (val === 'approved') classes = 'border border-[#bbf7d0] text-[#16a34a]'
        else if (val === 'rejected') classes = 'border border-red-200 text-red-600 bg-red-50'
        return h('span', { class: `${classes} px-3 py-1 rounded-full text-[11px] font-bold inline-block` }, val)
    }
  },
  {
    id: 'actions',
    header: '',
    cell: ({ row }: any) => {
        const item = row.original
        if (item.status === 'pending') {
          return h('div', { class: 'flex items-center justify-end gap-2' }, [
            h('button', {
              onClick: () => updateStatus(item.id, 'approved'),
              class: 'px-3 py-1.5 text-emerald-600 hover:bg-emerald-50 rounded text-[12px] transition-colors font-bold border border-transparent hover:border-emerald-200'
            }, 'Setujui'),
            h('button', {
              onClick: () => openRejectModal(item.id),
              class: 'px-3 py-1.5 text-red-600 hover:bg-red-50 rounded text-[12px] transition-colors font-bold border border-transparent hover:border-red-200'
            }, 'Tolak')
          ])
        } else {
          return h('span', { class: 'text-gray-400 text-[12px] text-right block' }, item.status === 'approved' ? 'Disetujui' : 'Ditolak')
        }
    },
    enableSorting: false
  }
]

const fetchOvertimes = async () => {
  isLoading.value = true
  try {
    const res = await apiClient.get('/overtimes/')
    if (res.data?.data) {
      displayData.value = res.data.data.map((item: any) => ({
        id: item.ID,
        name: item.Employee?.FirstName || 'Karyawan',
        date: item.Date ? new Date(item.Date).toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' }) : '-',
        duration: item.DurationMinutes ? `${Math.floor(item.DurationMinutes / 60)}j ${item.DurationMinutes % 60}m` : '-',
        reason: item.Reason || '-',
        status: item.Status || 'pending',
        avatar: `https://i.pravatar.cc/150?u=${item.EmployeeID}`
      }))
    } else {
      displayData.value = []
    }
  } catch (e) {
    console.error('Failed to fetch overtime data', e)
    displayData.value = []
  } finally {
    isLoading.value = false
  }
}

const updateStatus = async (id: string, newStatus: string) => {
  if (newStatus === 'approved' && !confirm('Yakin ingin menyetujui pengajuan lembur ini?')) return
  isSubmitting.value = true
  try {
    await apiClient.put(`/overtimes/${id}/status`, { status: newStatus })
    toast.success(`Lembur berhasil ${newStatus === 'approved' ? 'disetujui' : 'ditolak'}`)
    fetchOvertimes()
  } catch (e: any) {
    toast.error('Gagal memperbarui status: ' + (e.response?.data?.message || e.message))
  } finally {
    isSubmitting.value = false
  }
}

const openRejectModal = (id: string) => {
  selectedOvertimeId.value = id
  rejectReason.value = ''
  isRejectModalOpen.value = true
}

const cancelReject = () => {
  isRejectModalOpen.value = false
  selectedOvertimeId.value = ''
}

const confirmReject = async () => {
  isSubmitting.value = true
  try {
    await apiClient.put(`/overtimes/${selectedOvertimeId.value}/status`, {
      status: 'rejected',
      reject_reason: rejectReason.value
    })
    toast.success('Pengajuan lembur ditolak.')
    isRejectModalOpen.value = false
    fetchOvertimes()
  } catch (e: any) {
    toast.error('Gagal menolak lembur: ' + (e.response?.data?.message || e.message))
  } finally {
    isSubmitting.value = false
  }
}

const openRequestModal = () => {
  requestForm.value = {
    date: new Date().toISOString().split('T')[0],
    start_time: '',
    end_time: '',
    duration_minutes: 60,
    reason: ''
  }
  isRequestModalOpen.value = true
}

const submitOvertimeRequest = async () => {
  isSubmitting.value = true
  try {
    // Combine date + time into RFC3339
    const startISO = new Date(`${requestForm.value.date}T${requestForm.value.start_time}:00`).toISOString()
    const endISO = new Date(`${requestForm.value.date}T${requestForm.value.end_time}:00`).toISOString()
    await apiClient.post('/overtimes/', {
      date: requestForm.value.date,
      start_time: startISO,
      end_time: endISO,
      duration_minutes: Number(requestForm.value.duration_minutes),
      reason: requestForm.value.reason
    })
    toast.success('Pengajuan lembur berhasil dikirim.')
    isRequestModalOpen.value = false
    fetchOvertimes()
  } catch (e: any) {
    toast.error('Gagal mengajukan lembur: ' + (e.response?.data?.message || e.message))
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
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h1 class="text-[22px] font-bold text-gray-900 leading-tight">Pengajuan Lembur</h1>
        <p class="text-[14px] text-gray-500 mt-1">Kelola permohonan jam tambahan dan kompensasi.</p>
      </div>
      <Button @click="openRequestModal" class="gap-2 shadow-sm rounded-lg" size="sm">
        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
        </svg>
        Ajukan Lembur
      </Button>
    </div>

    <DataTable :data="displayData" :columns="columns" :isLoading="isLoading">
      <template #headerTitle>
         <h2 class="text-[15px] font-bold text-gray-900">Semua Permohonan</h2>
      </template>
    </DataTable>

    <!-- Reject Reason Dialog -->
    <Dialog v-model:open="isRejectModalOpen">
      <DialogContent class="sm:max-w-md">
        <DialogHeader>
          <DialogTitle class="text-xl text-red-600">Alasan Penolakan</DialogTitle>
          <DialogDescription>
            Pengajuan lembur akan ditolak dan karyawan akan menerima notifikasi alasan penolakan.
          </DialogDescription>
        </DialogHeader>
        <div class="grid gap-4 py-4">
          <div class="grid gap-2">
            <label class="text-[13px] font-medium text-gray-700">Pesan ke Karyawan</label>
            <Input v-model="rejectReason" placeholder="e.g. Tidak ada kebutuhan lembur di periode ini..." />
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" @click="cancelReject">Batalkan</Button>
          <Button variant="destructive" @click="confirmReject" :disabled="isSubmitting || !rejectReason.trim()">
            {{ isSubmitting ? 'Memproses...' : 'Konfirmasi Penolakan' }}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>

    <!-- Request Overtime Dialog -->
    <Dialog v-model:open="isRequestModalOpen">
      <DialogContent class="sm:max-w-md">
        <DialogHeader>
          <DialogTitle class="text-xl">Ajukan Lembur</DialogTitle>
          <DialogDescription>
            Isi detail pengajuan lembur. Durasi dihitung otomatis dari jam mulai dan selesai.
          </DialogDescription>
        </DialogHeader>
        <div class="grid gap-4 py-4">
          <div class="grid gap-2">
            <label class="text-[13px] font-medium text-gray-700">Tanggal</label>
            <Input v-model="requestForm.date" type="date" />
          </div>
          <div class="grid grid-cols-2 gap-4">
            <div class="grid gap-2">
              <label class="text-[13px] font-medium text-gray-700">Jam Mulai</label>
              <Input v-model="requestForm.start_time" type="time" />
            </div>
            <div class="grid gap-2">
              <label class="text-[13px] font-medium text-gray-700">Jam Selesai</label>
              <Input v-model="requestForm.end_time" type="time" />
            </div>
          </div>
          <div class="grid gap-2">
            <label class="text-[13px] font-medium text-gray-700">Durasi (menit)</label>
            <Input v-model="requestForm.duration_minutes" type="number" min="30" max="480" placeholder="e.g. 120" />
          </div>
          <div class="grid gap-2">
            <label class="text-[13px] font-medium text-gray-700">Alasan / Keterangan</label>
            <Input v-model="requestForm.reason" placeholder="e.g. Deadline proyek klien, server maintenance..." />
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" @click="isRequestModalOpen = false">Batal</Button>
          <Button @click="submitOvertimeRequest" :disabled="isSubmitting">
            {{ isSubmitting ? 'Mengirim...' : 'Kirim Pengajuan' }}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  </div>
</template>
