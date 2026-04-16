<script setup lang="ts">
import { ref, onMounted, h, computed } from 'vue'
import { toast } from 'vue-sonner'
import { Plus, Pencil, Trash2, CheckCircle, XCircle, FileText, Eye } from 'lucide-vue-next'
import axios from '@/api/axios'
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
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'

const isLoading = ref(true)
const isSubmitting = ref(false)
const displayData = ref<any[]>([])
const employees = ref<any[]>([])
const leaveTypes = ref<any[]>([])

// --- Filter ---
const activeFilter = ref('ALL')
const statusFilters = ['ALL', 'PENDING', 'APPROVED', 'REJECTED']

const filteredData = computed(() => {
  if (activeFilter.value === 'ALL') return displayData.value
  return displayData.value.filter(r => r.Status === activeFilter.value)
})

// --- CRUD Modal ---
const isModalOpen = ref(false)
const isEditMode = ref(false)
const form = ref({
  id: '',
  employee_id: '',
  leave_type_id: '',
  start_date: '',
  end_date: '',
  reason: '',
  attachment_url: '',
  status: 'PENDING',
})

// --- Reject Modal ---
const rejectModalOpen = ref(false)
const selectedLeaveId = ref<string>('')
const rejectReason = ref<string>('')

// --- View Attachment Modal ---
const attachmentModalOpen = ref(false)
const selectedAttachmentURL = ref<string>('')

const openAddModal = () => {
  isEditMode.value = false
  form.value = {
    id: '',
    employee_id: '',
    leave_type_id: '',
    start_date: '',
    end_date: '',
    reason: '',
    attachment_url: '',
    status: 'PENDING',
  }
  isModalOpen.value = true
}

const openEditModal = (row: any) => {
  isEditMode.value = true
  form.value = {
    id: row.ID,
    employee_id: row.EmployeeID,
    leave_type_id: row.LeaveTypeID,
    start_date: row.StartDate ? new Date(row.StartDate).toISOString().split('T')[0] : '',
    end_date: row.EndDate ? new Date(row.EndDate).toISOString().split('T')[0] : '',
    reason: row.Reason || '',
    attachment_url: row.AttachmentURL || '',
    status: row.Status || 'PENDING',
  }
  isModalOpen.value = true
}

const closeModal = () => {
  isModalOpen.value = false
}

const saveLeave = async () => {
  if (!form.value.employee_id || !form.value.leave_type_id || !form.value.start_date || !form.value.end_date) {
    toast.error('Karyawan, jenis izin, dan tanggal wajib diisi.')
    return
  }
  isSubmitting.value = true
  try {
    if (isEditMode.value) {
      await axios.put(`/time-off/${form.value.id}`, {
        leave_type_id: form.value.leave_type_id,
        start_date: form.value.start_date,
        end_date: form.value.end_date,
        reason: form.value.reason,
        attachment_url: form.value.attachment_url,
        status: form.value.status,
      })
      toast.success('Pengajuan berhasil diperbarui!')
    } else {
      await axios.post('/time-off', {
        employee_id: form.value.employee_id,
        leave_type_id: form.value.leave_type_id,
        start_date: form.value.start_date,
        end_date: form.value.end_date,
        reason: form.value.reason,
        attachment_url: form.value.attachment_url,
        status: form.value.status || 'PENDING',
      })
      toast.success('Pengajuan berhasil ditambahkan!')
    }
    closeModal()
    fetchLeaves()
  } catch (e: any) {
    toast.error('Gagal menyimpan: ' + (e.response?.data?.message || e.message))
  } finally {
    isSubmitting.value = false
  }
}

const deleteLeave = async (id: string) => {
  if (!confirm('Hapus pengajuan ini? Tindakan ini tidak dapat dibatalkan.')) return
  try {
    await axios.delete(`/time-off/${id}`)
    toast.success('Pengajuan berhasil dihapus.')
    fetchLeaves()
  } catch (e: any) {
    toast.error('Gagal menghapus: ' + (e.response?.data?.message || e.message))
  }
}

const approveLeave = async (id: string) => {
  if (!confirm('Setujui pengajuan cuti/izin ini?')) return
  try {
    await axios.put(`/time-off/${id}/approve`, { status: 'APPROVED' })
    toast.success('Pengajuan berhasil disetujui.')
    fetchLeaves()
  } catch (e: any) {
    toast.error('Gagal menyetujui: ' + (e.response?.data?.message || e.message))
  }
}

const openRejectModal = (id: string) => {
  selectedLeaveId.value = id
  rejectReason.value = ''
  rejectModalOpen.value = true
}

const confirmReject = async () => {
  if (!rejectReason.value.trim()) {
    toast.error('Alasan penolakan wajib diisi.')
    return
  }
  isSubmitting.value = true
  try {
    await axios.put(`/time-off/${selectedLeaveId.value}/approve`, {
      status: 'REJECTED',
      reject_reason: rejectReason.value,
    })
    toast.success('Pengajuan berhasil ditolak.')
    rejectModalOpen.value = false
    fetchLeaves()
  } catch (e: any) {
    toast.error('Gagal menolak: ' + (e.response?.data?.message || e.message))
  } finally {
    isSubmitting.value = false
  }
}

const openAttachmentModal = (url: string) => {
  selectedAttachmentURL.value = url
  attachmentModalOpen.value = true
}

const fetchLeaves = async () => {
  isLoading.value = true
  try {
    const res = await axios.get('/time-off')
    if (res.data?.data) displayData.value = res.data.data
  } catch (error) {
    console.error('Failed fetching leave data', error)
  } finally {
    isLoading.value = false
  }
}

const fetchEmployees = async () => {
  try {
    const res = await axios.get('/employees?limit=100')
    employees.value = res.data.data || []
  } catch (e) { console.error(e) }
}

const fetchLeaveTypes = async () => {
  try {
    const res = await axios.get('/leave-types')
    leaveTypes.value = res.data.data || []
  } catch (e) { console.error(e) }
}

const fmt = (d: string) => d ? new Date(d).toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' }) : '-'

const columns = [
  {
    id: 'employee',
    header: 'KARYAWAN',
    cell: ({ row }: any) => {
      const emp = row.original.Employee
      const name = emp ? `${emp.FirstName || ''} ${emp.LastName || ''}`.trim() : '-'
      const image = `https://ui-avatars.com/api/?name=${name}&background=990000&color=ffffff&bold=true`
      return h('div', { class: 'flex items-center gap-3' }, [
        h('img', { src: image, class: 'w-8 h-8 rounded-full border border-gray-200 object-cover' }),
        h('div', { class: 'font-bold text-gray-900 leading-tight text-[13px]' }, name)
      ])
    }
  },
  {
    id: 'leaveType',
    header: 'JENIS CUTI/IZIN',
    cell: ({ row }: any) => {
      const name = row.original.LeaveType?.Name || '-'
      const isSick = name.toLowerCase().includes('sakit') || name.toLowerCase().includes('sick')
      return h('div', { class: 'flex flex-col gap-0.5' }, [
        h('span', { class: 'font-semibold text-gray-700 text-[13px]' }, name),
        isSick ? h('span', { class: 'text-[11px] text-orange-600 font-medium flex items-center gap-1' }, '★ Perlu Dok. Dokter') : null
      ])
    }
  },
  {
    id: 'period',
    header: 'PERIODE',
    cell: ({ row }: any) => {
      const r = row.original
      const start = fmt(r.StartDate)
      const end = fmt(r.EndDate)
      const days = Math.ceil((new Date(r.EndDate).getTime() - new Date(r.StartDate).getTime()) / (1000 * 3600 * 24)) + 1
      return h('div', { class: 'flex flex-col' }, [
        h('span', { class: 'text-gray-700 text-[13px]' }, `${start} - ${end}`),
        h('span', { class: 'text-gray-400 text-[11px]' }, `${days} hari`)
      ])
    }
  },
  {
    accessorKey: 'Reason',
    header: 'ALASAN',
    cell: (info: any) => h('span', {
      class: 'text-gray-500 text-[13px] max-w-[180px] truncate inline-block',
      title: info.getValue()
    }, info.getValue() || '-')
  },
  {
    id: 'attachment',
    header: 'LAMPIRAN (DOKTER)',
    cell: ({ row }: any) => {
      const url = row.original.AttachmentURL
      if (!url) return h('span', { class: 'text-gray-400 text-[12px]' }, '—')
      return h('button', {
        class: 'flex items-center gap-1 text-primary text-[12px] font-semibold hover:underline',
        onClick: () => openAttachmentModal(url)
      }, [
        h(FileText, { class: 'w-3.5 h-3.5' }),
        'Lihat Lampiran'
      ])
    }
  },
  {
    accessorKey: 'Status',
    header: 'STATUS',
    cell: ({ getValue }: any) => {
      const val = getValue() as string
      let cls = 'border-yellow-200 text-yellow-700 bg-yellow-50'
      if (val === 'APPROVED') cls = 'border-green-200 text-green-700 bg-green-50'
      else if (val === 'REJECTED') cls = 'border-red-200 text-red-600 bg-red-50'
      return h('span', { class: `border ${cls} px-3 py-1 rounded-full text-[11px] font-bold inline-block` }, val)
    }
  },
  {
    id: 'actions',
    header: 'AKSI',
    cell: ({ row }: any) => {
      const r = row.original
      const status = r.Status
      return h('div', { class: 'flex items-center gap-1' }, [
        // Edit always allowed (if pending)
        h('button', {
          class: 'p-1.5 rounded hover:bg-blue-50 text-blue-600 transition-colors',
          title: 'Edit',
          onClick: () => openEditModal(r)
        }, h(Pencil, { class: 'w-3.5 h-3.5' })),

        // Approve button
        status === 'PENDING' ? h('button', {
          class: 'p-1.5 rounded hover:bg-green-50 text-green-600 transition-colors',
          title: 'Setujui',
          onClick: () => approveLeave(r.ID)
        }, h(CheckCircle, { class: 'w-3.5 h-3.5' })) : null,

        // Reject button
        status === 'PENDING' ? h('button', {
          class: 'p-1.5 rounded hover:bg-red-50 text-red-600 transition-colors',
          title: 'Tolak',
          onClick: () => openRejectModal(r.ID)
        }, h(XCircle, { class: 'w-3.5 h-3.5' })) : null,

        // Delete
        h('button', {
          class: 'p-1.5 rounded hover:bg-red-50 text-red-400 hover:text-red-600 transition-colors',
          title: 'Hapus',
          onClick: () => deleteLeave(r.ID)
        }, h(Trash2, { class: 'w-3.5 h-3.5' }))
      ])
    }
  }
]

onMounted(() => {
  fetchLeaves()
  fetchEmployees()
  fetchLeaveTypes()
})
</script>

<template>
  <div class="space-y-6">

    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h1 class="text-[22px] font-bold text-gray-900 leading-tight">Pengajuan Cuti & Izin</h1>
        <p class="text-[14px] text-gray-500 mt-1">Kelola, validasi, dan proses permohonan cuti dan izin karyawan.</p>
      </div>
      <Button @click="openAddModal" class="flex items-center gap-2 shrink-0">
        <Plus class="w-4 h-4" />
        Tambah Pengajuan
      </Button>
    </div>

    <!-- Status Filter Tabs -->
    <div class="flex gap-2 flex-wrap">
      <button
        v-for="f in statusFilters" :key="f"
        @click="activeFilter = f"
        :class="[
          'px-4 py-1.5 rounded-full text-[13px] font-semibold border transition-colors',
          activeFilter === f
            ? 'bg-primary text-white border-primary'
            : 'bg-white text-gray-600 border-gray-300 hover:border-primary/50'
        ]"
      >{{ f }}</button>
    </div>

    <!-- Stats Summary -->
    <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
      <div v-for="[label, color, filterKey] in [
        ['Total Pengajuan', 'text-gray-700', 'ALL'],
        ['Menunggu', 'text-yellow-600', 'PENDING'],
        ['Disetujui', 'text-green-600', 'APPROVED'],
        ['Ditolak', 'text-red-500', 'REJECTED'],
      ]" :key="label"
        class="bg-white rounded-xl border border-gray-200 px-4 py-3 shadow-sm cursor-pointer hover:shadow-md transition-shadow"
        @click="activeFilter = filterKey"
      >
        <p class="text-xs text-gray-500 font-medium">{{ label }}</p>
        <p :class="['text-2xl font-bold mt-1', color]">
          {{ filterKey === 'ALL' ? displayData.length : displayData.filter(r => r.Status === filterKey).length }}
        </p>
      </div>
    </div>

    <!-- Table -->
    <DataTable :data="filteredData" :columns="columns" :isLoading="isLoading" />

    <!-- ─────────── ADD/EDIT MODAL ─────────── -->
    <Dialog v-model:open="isModalOpen">
      <DialogContent class="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle class="text-xl">{{ isEditMode ? 'Edit Pengajuan' : 'Tambah Pengajuan Cuti/Izin' }}</DialogTitle>
          <DialogDescription>Isi data pengajuan cuti atau izin karyawan. Lampirkan surat dokter untuk izin sakit.</DialogDescription>
        </DialogHeader>

        <div class="grid gap-4 py-4">
          <!-- Karyawan -->
          <div class="grid gap-2">
            <label class="text-sm font-medium">Karyawan <span class="text-red-500">*</span></label>
            <Select v-model="form.employee_id">
              <SelectTrigger><SelectValue placeholder="Pilih Karyawan" /></SelectTrigger>
              <SelectContent>
                <SelectItem v-for="e in employees" :key="e.ID" :value="e.ID">
                  {{ e.FirstName }} {{ e.LastName || '' }}
                </SelectItem>
              </SelectContent>
            </Select>
          </div>

          <!-- Jenis Cuti -->
          <div class="grid gap-2">
            <label class="text-sm font-medium">Jenis Cuti / Izin <span class="text-red-500">*</span></label>
            <Select v-model="form.leave_type_id">
              <SelectTrigger><SelectValue placeholder="Pilih Jenis Izin" /></SelectTrigger>
              <SelectContent>
                <SelectItem v-for="lt in leaveTypes" :key="lt.ID" :value="lt.ID">{{ lt.Name }}</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <!-- Tanggal -->
          <div class="grid grid-cols-2 gap-4">
            <div class="grid gap-2">
              <label class="text-sm font-medium">Tanggal Mulai <span class="text-red-500">*</span></label>
              <Input type="date" v-model="form.start_date" />
            </div>
            <div class="grid gap-2">
              <label class="text-sm font-medium">Tanggal Selesai <span class="text-red-500">*</span></label>
              <Input type="date" v-model="form.end_date" />
            </div>
          </div>

          <!-- Alasan -->
          <div class="grid gap-2">
            <label class="text-sm font-medium">Alasan / Keterangan</label>
            <textarea
              v-model="form.reason"
              class="min-h-[72px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
              placeholder="Alasan cuti atau izin..."
            ></textarea>
          </div>

          <!-- Lampiran surat dokter -->
          <div class="grid gap-2">
            <label class="text-sm font-medium flex items-center gap-1.5">
              <FileText class="w-4 h-4 text-orange-500" />
              URL Lampiran Surat Dokter
            </label>
            <Input v-model="form.attachment_url" placeholder="https://..." type="url" />
            <p class="text-xs text-gray-500">Wajib diisi untuk izin sakit agar dapat divalidasi oleh manajerial.</p>
          </div>

          <!-- Status (Only in Edit Mode) -->
          <div v-if="isEditMode" class="grid gap-2 border-t pt-4">
            <label class="text-sm font-medium">Status Pengajuan <span class="text-red-500">*</span></label>
            <Select v-model="form.status">
              <SelectTrigger><SelectValue placeholder="Update Status" /></SelectTrigger>
              <SelectContent>
                <SelectItem value="PENDING">PENDING</SelectItem>
                <SelectItem value="APPROVED">APPROVED</SelectItem>
                <SelectItem value="REJECTED">REJECTED</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" @click="closeModal" :disabled="isSubmitting">Batal</Button>
          <Button @click="saveLeave" :disabled="isSubmitting">
            {{ isSubmitting ? 'Menyimpan...' : 'Simpan Pengajuan' }}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>

    <!-- ─────────── REJECT MODAL ─────────── -->
    <Dialog v-model:open="rejectModalOpen">
      <DialogContent class="sm:max-w-md">
        <DialogHeader>
          <DialogTitle class="text-xl text-red-600">Tolak Pengajuan</DialogTitle>
          <DialogDescription>
            Cuti yang ditolak akan otomatis membatalkan pemotongan saldo cuti karyawan.
          </DialogDescription>
        </DialogHeader>
        <div class="grid gap-4 py-4">
          <div class="grid gap-2">
            <label class="text-sm font-medium">Alasan Penolakan <span class="text-red-500">*</span></label>
            <textarea
              v-model="rejectReason"
              class="min-h-[72px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
              placeholder="Masukkan alasan penolakan..."
            ></textarea>
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" @click="rejectModalOpen = false" :disabled="isSubmitting">Batal</Button>
          <Button variant="destructive" @click="confirmReject" :disabled="isSubmitting || !rejectReason.trim()">
            {{ isSubmitting ? 'Memproses...' : 'Tolak Pengajuan' }}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>

    <!-- ─────────── ATTACHMENT VIEWER MODAL ─────────── -->
    <Dialog v-model:open="attachmentModalOpen">
      <DialogContent class="sm:max-w-3xl">
        <DialogHeader>
          <DialogTitle class="flex items-center gap-2">
            <FileText class="w-5 h-5 text-orange-500" />
            Dokumen Surat Dokter / Lampiran
          </DialogTitle>
          <DialogDescription>Validasi keabsahan dokumen yang dilampirkan karyawan.</DialogDescription>
        </DialogHeader>
        <div class="py-4">
          <div class="border rounded-lg overflow-hidden bg-gray-50 h-[400px] flex items-center justify-center">
            <!-- Try to embed PDF or image -->
            <iframe
              v-if="selectedAttachmentURL.endsWith('.pdf') || selectedAttachmentURL.includes('pdf')"
              :src="selectedAttachmentURL"
              class="w-full h-full"
              frameborder="0"
            ></iframe>
            <img
              v-else-if="selectedAttachmentURL.match(/\.(jpg|jpeg|png|gif|webp)/i)"
              :src="selectedAttachmentURL"
              class="max-h-full max-w-full object-contain"
              alt="Lampiran"
            />
            <div v-else class="text-center p-6">
              <FileText class="w-16 h-16 text-gray-400 mx-auto mb-4" />
              <p class="text-gray-600 font-medium">Format tidak dapat dipratinjau langsung.</p>
              <a :href="selectedAttachmentURL" target="_blank" class="mt-3 inline-flex items-center gap-2 text-primary hover:underline font-semibold">
                <Eye class="w-4 h-4" />
                Buka di Tab Baru
              </a>
            </div>
          </div>
          <div class="mt-3 flex items-center justify-between">
            <p class="text-xs text-gray-400 truncate max-w-[60%]">{{ selectedAttachmentURL }}</p>
            <a :href="selectedAttachmentURL" target="_blank" class="text-sm text-primary font-semibold hover:underline flex items-center gap-1">
              <Eye class="w-3.5 h-3.5" />
              Buka Penuh
            </a>
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" @click="attachmentModalOpen = false">Tutup</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>

  </div>
</template>
