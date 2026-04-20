<script setup lang="ts">
import { ref, onMounted, h, computed, toRaw } from 'vue'
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
import { useMasterDataStore } from '@/stores/masterData'

const masterData = useMasterDataStore()

const isLoading = ref(true)
const isSubmitting = ref(false)
const displayData = ref<any[]>([])
const employees = ref<any[]>([])

// --- Filter ---
const activeFilter = ref('ALL')
const statusFilters = ['ALL', 'PENDING', 'APPROVED', 'REJECTED']

const filteredData = computed(() => {
  if (activeFilter.value === 'ALL') return displayData.value
  return displayData.value.filter(r => r.status === activeFilter.value)
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
  attachment_file: null as File | null,
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
    attachment_file: null,
    status: 'PENDING',
  }
  isModalOpen.value = true
}

const openEditModal = (row: any) => {
  isEditMode.value = true
  form.value = {
    id: String(row.id || ''),
    employee_id: String(row.employee_id || ''),
    leave_type_id: String(row.leave_type_id || ''),
    start_date: row.start_date ? new Date(row.start_date).toISOString().slice(0, 10) : '',
    end_date: row.end_date ? new Date(row.end_date).toISOString().slice(0, 10) : '',
    reason: (row.reason || '') as string,
    attachment_url: (row.attachment_url || '') as string,
    attachment_file: null,
    status: (row.status || 'PENDING') as string,
  }
  isModalOpen.value = true
}

const onFileChange = (e: any) => {
  const file = e.target.files[0]
  if (file) {
    form.value.attachment_file = file
  }
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
    const formData = new FormData()
    formData.append('employee_id', form.value.employee_id)
    formData.append('leave_type_id', form.value.leave_type_id)
    formData.append('start_date', form.value.start_date)
    formData.append('end_date', form.value.end_date)
    formData.append('reason', form.value.reason)
    formData.append('status', form.value.status)
    if (form.value.attachment_file) {
      formData.append('attachment', toRaw(form.value.attachment_file))
    }

    const config = {
      headers: {
        'Content-Type': 'multipart/form-data'
      }
    }

    if (isEditMode.value) {
      await axios.put(`/time-off/manage/${form.value.id}`, formData, config)
      toast.success('Pengajuan berhasil diperbarui!')
    } else {
      await axios.post('/time-off/manage', formData, config)
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
    await axios.delete(`/time-off/manage/${id}`)
    toast.success('Pengajuan berhasil dihapus.')
    fetchLeaves()
  } catch (e: any) {
    toast.error('Gagal menghapus: ' + (e.response?.data?.message || e.message))
  }
}

const approveLeave = async (id: string) => {
  if (!confirm('Setujui pengajuan cuti/izin ini?')) return
  try {
    await axios.put(`/time-off/manage/${id}/approve`, { status: 'APPROVED' })
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
    await axios.put(`/time-off/manage/${selectedLeaveId.value}/approve`, {
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
  const baseUrl = import.meta.env.VITE_API_BASE_URL.replace('/api', '')
  selectedAttachmentURL.value = url.startsWith('http') ? url : `${baseUrl}${url}`
  attachmentModalOpen.value = true
}

const fetchLeaves = async () => {
  isLoading.value = true
  try {
    const res = await axios.get('/time-off/manage')
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

const fmt = (d: string) => d ? new Date(d).toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' }) : '-'

const getInitials = (name: string) =>
  name.split(' ').map(w => w[0]).join('').toUpperCase().slice(0, 2)

const columns = [
  {
    accessorFn: (row: any) => {
      const emp = row.employee
      return emp ? `${emp.first_name || ''} ${emp.last_name || ''}`.trim() : '-'
    },
    id: 'employee',
    header: 'KARYAWAN',
    cell: (info: any) => h('div', { class: 'flex flex-col' }, [
      h('div', { class: 'font-bold text-gray-900 leading-tight text-[13px]' }, info.getValue())
    ])
  },
  {
    accessorFn: (row: any) => row.leave_type?.name || '-',
    id: 'leaveType',
    header: 'JENIS CUTI/IZIN',
    cell: ({ row }: any) => {
      const name = row.original.leave_type?.name || '-'
      const isSick = name.toLowerCase().includes('sakit') || name.toLowerCase().includes('sick')
      return h('div', { class: 'flex flex-col gap-0.5' }, [
        h('span', { class: 'font-semibold text-gray-700 text-[13px]' }, name),
        isSick ? h('span', { class: 'text-[11px] text-orange-600 font-medium flex items-center gap-1' }, '★ Perlu Dok. Dokter') : null
      ])
    }
  },
  {
    accessorKey: 'start_date',
    id: 'period',
    header: 'PERIODE',
    cell: ({ row }: any) => {
      const r = row.original
      const start = fmt(r.start_date)
      const end = fmt(r.end_date)
      const days = Math.ceil((new Date(r.end_date).getTime() - new Date(r.start_date).getTime()) / (1000 * 3600 * 24)) + 1
      return h('div', { class: 'flex flex-col' }, [
        h('span', { class: 'text-gray-700 text-[13px]' }, `${start} - ${end}`),
        h('span', { class: 'text-gray-400 text-[11px]' }, `${days} hari`)
      ])
    }
  },
  {
    accessorKey: 'reason',
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
      const url = row.original.attachment_url
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
    accessorKey: 'status',
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
      const status = r.status
      return h('div', { class: 'flex items-center gap-1' }, [
        h('button', {
          class: 'p-1.5 rounded hover:bg-blue-50 text-blue-600 transition-colors',
          title: 'Edit',
          onClick: () => openEditModal(r)
        }, h(Pencil, { class: 'w-3.5 h-3.5' })),

        status === 'PENDING' ? h('button', {
          class: 'p-1.5 rounded hover:bg-green-50 text-green-600 transition-colors',
          title: 'Setujui',
          onClick: () => approveLeave(r.id)
        }, h(CheckCircle, { class: 'w-3.5 h-3.5' })) : null,

        status === 'PENDING' ? h('button', {
          class: 'p-1.5 rounded hover:bg-red-50 text-red-600 transition-colors',
          title: 'Tolak',
          onClick: () => openRejectModal(r.id)
        }, h(XCircle, { class: 'w-3.5 h-3.5' })) : null,

        h('button', {
          class: 'p-1.5 rounded hover:bg-rose-50 text-rose-600 transition-colors',
          title: 'Hapus',
          onClick: () => deleteLeave(r.id)
        }, h(Trash2, { class: 'w-3.5 h-3.5' }))
      ])
    },
    enableSorting: false
  }
]

onMounted(() => {
  fetchLeaves()
  fetchEmployees()
  masterData.fetchLeaveTypes()
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
      <div v-for="stat in [
        { label: 'Total Pengajuan', color: 'text-gray-700', key: 'ALL' },
        { label: 'Menunggu', color: 'text-yellow-600', key: 'PENDING' },
        { label: 'Disetujui', color: 'text-green-600', key: 'APPROVED' },
        { label: 'Ditolak', color: 'text-red-500', key: 'REJECTED' },
      ]" :key="stat.label"
        class="bg-white rounded-xl border border-gray-200 px-4 py-3 shadow-sm cursor-pointer hover:shadow-md transition-shadow"
        @click="activeFilter = stat.key"
      >
        <p class="text-xs text-gray-500 font-medium">{{ stat.label }}</p>
        <p :class="['text-2xl font-bold mt-1', stat.color]">
          {{ stat.key === 'ALL' ? displayData.length : displayData.filter(r => r.status === stat.key).length }}
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
                <SelectItem v-for="e in employees" :key="e.id" :value="e.id">
                  {{ e.first_name }} {{ e.last_name || '' }}
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
                <SelectItem v-for="lt in masterData.leaveTypes" :key="lt.id" :value="lt.id">{{ lt.name }}</SelectItem>
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
              Lampiran Surat Dokter
            </label>
            <Input type="file" @change="onFileChange" accept=".jpg,.jpeg,.png,.pdf" />
            <div v-if="form.attachment_url" class="flex items-center gap-2 mt-1">
              <span class="text-[11px] text-gray-500">Berkas saat ini:</span>
              <button
                type="button"
                @click="openAttachmentModal(form.attachment_url)"
                class="text-[11px] text-primary font-semibold hover:underline flex items-center gap-1"
              >
                <Eye class="w-3 h-3" /> Lihat
              </button>
            </div>
            <p class="text-xs text-gray-500 italic">Wajib diisi untuk izin sakit agar dapat divalidasi oleh manajerial.</p>
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
