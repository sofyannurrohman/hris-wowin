<script setup lang="ts">
import { ref, h, onMounted, toRaw } from 'vue'
import { CheckCircle2, XCircle, FileText, ExternalLink, MoreVertical, Plus, Pencil, Trash2, Eye } from 'lucide-vue-next'
import apiClient from '@/api/axios'
import DataTable from '@/components/DataTable.vue'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { toast } from 'vue-sonner'
import { Label } from '@/components/ui/label'

const reimbursements = ref<any[]>([])
const employees = ref<any[]>([])
const isLoading = ref(true)
const isSubmitting = ref(false)

// Review Modal State
const isModalOpen = ref(false)
const selectedItem = ref<any>(null)
const rejectReason = ref('')

// CRUD Modal State
const isCRUDModalOpen = ref(false)
const isEditMode = ref(false)
const form = ref({
  id: '',
  employee_id: '',
  title: '',
  amount: 0,
  description: '',
  attachment_url: '',
  attachment_file: null as File | null,
  status: 'PENDING'
})

const fetchReimbursements = async () => {
  isLoading.value = true
  try {
    const res = await apiClient.get('/reimbursements/manage?limit=100')
    reimbursements.value = res.data.data || []
  } catch (error) {
    console.error('Failed to fetch reimbursements:', error)
    toast.error('Gagal mengambil data reimbursement')
  } finally {
    isLoading.value = false
  }
}

const fetchEmployees = async () => {
  try {
    const res = await apiClient.get('/employees?limit=100')
    employees.value = res.data.data || []
  } catch (e) {
    console.error('Failed to fetch employees:', e)
  }
}

const openReviewModal = (item: any) => {
  selectedItem.value = item
  rejectReason.value = ''
  isModalOpen.value = true
}

const updateStatus = async (status: 'APPROVED' | 'REJECTED') => {
  if (!selectedItem.value) return
  
  if (status === 'REJECTED' && !rejectReason.value) {
    toast.error('Gagal: Alasan penolakan harus diisi.')
    return
  }

  isSubmitting.value = true
  try {
    await apiClient.put(`/reimbursements/manage/${selectedItem.value.id}/approve`, {
      status: status,
      rejected_reason: status === 'REJECTED' ? rejectReason.value : null
    })
    toast.success(`Berhasil ${status === 'APPROVED' ? 'menyetujui' : 'menolak'} pengajuan.`)
    isModalOpen.value = false
    fetchReimbursements()
  } catch (error: any) {
    toast.error('Gagal memperbarui status: ' + (error.response?.data?.message || error.message))
  } finally {
    isSubmitting.value = false
  }
}

const openAddModal = () => {
  isEditMode.value = false
  form.value = {
    id: '',
    employee_id: '',
    title: '',
    amount: 0,
    description: '',
    attachment_url: '',
    attachment_file: null,
    status: 'PENDING'
  }
  isCRUDModalOpen.value = true
}

const openEditModal = (item: any) => {
  isEditMode.value = true
  form.value = {
    id: item.id,
    employee_id: item.employee_id,
    title: item.title,
    amount: Number(item.amount),
    description: item.description || '',
    attachment_url: item.attachment_url || '',
    attachment_file: null,
    status: item.status
  }
  isCRUDModalOpen.value = true
}

const onFileChange = (e: any) => {
  const file = e.target.files[0]
  if (file) {
    form.value.attachment_file = file
  }
}

const saveReimbursement = async () => {
  if (!form.value.employee_id || !form.value.title || !form.value.amount) {
    toast.error('Harap isi semua field wajib.')
    return
  }

  isSubmitting.value = true
  try {
    const formData = new FormData()
    formData.append('employee_id', form.value.employee_id)
    formData.append('title', form.value.title)
    formData.append('amount', String(form.value.amount))
    formData.append('description', form.value.description)
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
      await apiClient.put(`/reimbursements/manage/${form.value.id}`, formData, config)
      toast.success('Berhasil memperbarui reimbursement')
    } else {
      await apiClient.post('/reimbursements/manage', formData, config)
      toast.success('Berhasil menambahkan reimbursement')
    }
    isCRUDModalOpen.value = false
    fetchReimbursements()
  } catch (error: any) {
    toast.error('Gagal menyimpan: ' + (error.response?.data?.message || error.message))
  } finally {
    isSubmitting.value = false
  }
}

const deleteReimbursement = async (id: string) => {
  if (!confirm('Hapus data reimbursement ini?')) return
  try {
    await apiClient.delete(`/reimbursements/manage/${id}`)
    toast.success('Berhasil menghapus reimbursement')
    fetchReimbursements()
  } catch (error: any) {
    toast.error('Gagal menghapus: ' + (error.response?.data?.message || error.message))
  }
}

onMounted(() => {
  fetchReimbursements()
  fetchEmployees()
})

const columns = [
  {
    accessorKey: 'created_at',
    id: 'created_at',
    header: 'TANGGAL',
    cell: (info: any) => h('span', { class: 'text-gray-500 text-[13px]' }, info.getValue() ? new Date(info.getValue()).toLocaleDateString('id-ID') : '-')
  },
  {
    accessorFn: (row: any) => {
      const emp = row.employee
      return emp ? `${emp.first_name} ${emp.last_name || ''}`.trim() : '-'
    },
    id: 'employee',
    header: 'KARYAWAN',
    cell: (info: any) => h('div', { class: 'flex flex-col' }, [
      h('div', { class: 'font-bold text-gray-900 leading-tight text-[13px]' }, info.getValue())
    ])
  },
  {
    accessorKey: 'title',
    header: 'JUDUL KLAIM',
    cell: (info: any) => h('span', { class: 'font-semibold text-gray-700' }, info.getValue() || '-')
  },
  {
    accessorKey: 'amount',
    header: 'NOMINAL',
    cell: (info: any) => h('span', { class: 'font-bold text-gray-900' }, `Rp ${Number(info.getValue()).toLocaleString('id-ID')}`)
  },
  {
    accessorKey: 'status',
    header: 'STATUS',
    cell: ({ getValue }: any) => {
      const val = getValue() as string || 'PENDING'
      let classes = 'bg-amber-100 text-amber-700'
      if (val === 'APPROVED') classes = 'bg-emerald-100 text-emerald-700'
      else if (val === 'REJECTED') classes = 'bg-red-100 text-red-700'
      return h('span', { class: `${classes} px-2.5 py-1 text-[11px] font-bold rounded-full` }, val)
    }
  },
  {
    id: 'attachment',
    header: 'LAMPIRAN',
    cell: ({ row }: any) => {
      const url = row.original.attachment_url
      if (!url) return h('span', { class: 'text-gray-400 italic text-[12px]' }, 'Tidak ada')
      const baseUrl = import.meta.env.VITE_API_BASE_URL.replace('/api', '')
      return h('a', { 
        href: url.startsWith('http') ? url : `${baseUrl}${url}`, 
        target: '_blank',
        class: 'text-primary hover:underline flex items-center gap-1.5 font-bold text-[12px]'
      }, [
        h(FileText, { class: 'w-3.5 h-3.5' }),
        'Lihat Nota'
      ])
    }
  },
  {
    id: 'actions',
    header: 'AKSI',
    cell: ({ row }: any) => {
      const item = row.original
      return h('div', { class: 'flex items-center gap-1' }, [
        // Edit Action
        h('button', {
          class: 'p-1.5 rounded hover:bg-blue-50 text-blue-600 transition-colors',
          title: 'Edit',
          onClick: () => openEditModal(item)
        }, h(Pencil, { class: 'w-3.5 h-3.5' })),

        // Review Action (Only for PENDING)
        item.status === 'PENDING' ? h('button', {
          class: 'p-1.5 rounded hover:bg-amber-50 text-amber-600 transition-colors',
          title: 'Review Status',
          onClick: () => openReviewModal(item)
        }, h(MoreVertical, { class: 'w-3.5 h-3.5' })) : null,

        // Delete Action
        h('button', {
          class: 'p-1.5 rounded hover:bg-rose-50 text-rose-600 transition-colors',
          title: 'Hapus',
          onClick: () => deleteReimbursement(item.id)
        }, h(Trash2, { class: 'w-3.5 h-3.5' }))
      ])
    },
    enableSorting: false
  }
]
</script>

<template>
  <div class="space-y-6">
    <!-- Header Page -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-6">
      <div>
        <h1 class="text-2xl font-black text-slate-900 tracking-tight">Pusat Persetujuan Reimbursement</h1>
        <p class="text-[14px] font-medium text-slate-500 mt-1">Validasi dan kelola pengajuan klaim operasional oleh karyawan secara real-time.</p>
      </div>
      <div class="flex items-center gap-3">
        <Button @click="openAddModal" class="gap-2 h-10 px-5 rounded-xl text-sm font-bold shadow-lg shadow-primary/20">
          <Plus class="w-4 h-4" />
          Tambah Pengajuan
        </Button>
      </div>
    </div>

    <!-- DataTable Instance -->
    <DataTable :data="reimbursements" :columns="columns" :isLoading="isLoading" />

    <!-- Review Modal -->
    <Dialog v-model:open="isModalOpen">
      <DialogContent class="sm:max-w-lg rounded-3xl p-0 overflow-hidden border-none shadow-2xl">
        <DialogHeader class="p-8 bg-slate-900 text-white relative">
          <div class="absolute right-8 top-8 opacity-10">
            <FileText class="w-20 h-20" />
          </div>
          <DialogTitle class="text-xl font-black tracking-tight">Review Pengajuan Klaim</DialogTitle>
          <DialogDescription class="text-slate-400 mt-2 font-medium">
            Tinjau detail bukti nota dan nominal sebelum memberikan keputusan persetujuan.
          </DialogDescription>
        </DialogHeader>
        
        <div class="p-8 space-y-6">
          <div v-if="selectedItem" class="space-y-4">
            <!-- Summary Info -->
            <div class="grid grid-cols-2 gap-4">
              <div class="p-4 bg-slate-50 rounded-2xl border border-slate-100">
                <p class="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1">Karyawan</p>
                <p class="font-bold text-slate-900 truncate">{{ selectedItem.employee?.first_name }}</p>
              </div>
              <div class="p-4 bg-slate-50 rounded-2xl border border-slate-100">
                <p class="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1">Nominal Klaim</p>
                <p class="font-black text-primary text-lg">Rp {{ Number(selectedItem.amount).toLocaleString('id-ID') }}</p>
              </div>
            </div>

            <div class="space-y-2">
              <p class="text-[11px] font-black text-slate-400 uppercase tracking-[0.2em]">Judul & Keterangan</p>
              <div class="p-5 bg-white border border-slate-200 rounded-2xl shadow-sm italic text-slate-600 text-sm leading-relaxed">
                <p class="font-bold text-slate-900 not-italic mb-1">{{ selectedItem.title }}</p>
                {{ selectedItem.description || 'Tidak ada deskripsi tambahan.' }}
              </div>
            </div>

            <!-- Rejection Reason (Input) -->
            <div class="space-y-2">
              <p class="text-[11px] font-black text-slate-400 uppercase tracking-[0.2em]">Alasan Penolakan (Wajib jika ditolak)</p>
              <Textarea 
                v-model="rejectReason"
                placeholder="Tulis alasan mengapa pengajuan ini ditolak..." 
                class="min-h-[100px] rounded-2xl border-slate-200 focus:ring-4 focus:ring-red-50 focus:border-red-200 transition-all text-sm font-medium"
              />
            </div>
          </div>
        </div>

        <DialogFooter class="p-8 bg-slate-50 flex gap-3 sm:gap-4 sm:justify-end">
          <Button 
            variant="ghost" 
            @click="isModalOpen = false" 
            class="rounded-xl font-bold text-slate-500 hover:bg-slate-200 h-12 px-6"
          >Batal</Button>
          
          <Button 
            variant="outline"
            @click="updateStatus('REJECTED')"
            :disabled="isSubmitting"
            class="rounded-xl font-bold border-red-200 text-red-600 hover:bg-red-50 h-12 px-6 gap-2"
          >
            <XCircle class="w-4 h-4" />
            Tolak Klaim
          </Button>

          <Button 
            @click="updateStatus('APPROVED')"
            :disabled="isSubmitting"
            class="rounded-xl font-bold bg-emerald-600 hover:bg-emerald-700 h-12 px-8 gap-2 shadow-lg shadow-emerald-200"
          >
            <CheckCircle2 class="w-4 h-4" />
            Setujui Klaim
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>

    <!-- CRUD Modal (Add/Edit) -->
    <Dialog v-model:open="isCRUDModalOpen">
      <DialogContent class="sm:max-w-xl rounded-3xl p-0 overflow-hidden border-none shadow-2xl">
        <DialogHeader class="p-8 bg-primary text-white relative">
          <DialogTitle class="text-xl font-black tracking-tight">
            {{ isEditMode ? 'Edit Pengajuan Reimbursement' : 'Tambah Pengajuan Reimbursement' }}
          </DialogTitle>
          <DialogDescription class="text-white/70 mt-2 font-medium">
            Lengkapi data pengajuan reimbursement karyawan berikut ini.
          </DialogDescription>
        </DialogHeader>

        <div class="p-8 space-y-6">
          <div class="grid gap-6">
            <!-- Karyawan -->
            <div class="space-y-2">
              <Label class="text-[11px] font-black text-slate-400 uppercase tracking-widest pl-1">Karyawan</Label>
              <Select v-model="form.employee_id" :disabled="isEditMode">
                <SelectTrigger class="h-12 rounded-2xl border-slate-200">
                  <SelectValue placeholder="Pilih Karyawan" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem v-for="e in employees" :key="e.id" :value="e.id">
                    {{ e.first_name }} {{ e.last_name || '' }}
                  </SelectItem>
                </SelectContent>
              </Select>
            </div>

            <!-- Judul -->
            <div class="grid gap-2">
              <Label class="text-[11px] font-black text-slate-400 uppercase tracking-widest pl-1">Judul Klaim</Label>
              <Input v-model="form.title" placeholder="Contoh: Pembelian Monitor LG" class="h-12 rounded-2xl border-slate-200" />
            </div>

            <!-- Nominal -->
            <div class="grid gap-2">
              <Label class="text-[11px] font-black text-slate-400 uppercase tracking-widest pl-1">Nominal (Rp)</Label>
              <Input type="number" v-model="form.amount" placeholder="0" class="h-12 rounded-2xl border-slate-200" />
            </div>

            <!-- Deskripsi -->
            <div class="grid gap-2">
              <Label class="text-[11px] font-black text-slate-400 uppercase tracking-widest pl-1">Deskripsi / Catatan</Label>
              <Textarea v-model="form.description" placeholder="Detail pengeluaran..." class="min-h-[80px] rounded-2xl border-slate-200" />
            </div>

            <!-- Status (Edit Mode Only) -->
            <div v-if="isEditMode" class="space-y-2">
              <Label class="text-[11px] font-black text-slate-400 uppercase tracking-widest pl-1">Status</Label>
              <Select v-model="form.status">
                <SelectTrigger class="h-12 rounded-2xl border-slate-200">
                  <SelectValue placeholder="Pilih Status" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="PENDING">PENDING</SelectItem>
                  <SelectItem value="APPROVED">APPROVED</SelectItem>
                  <SelectItem value="REJECTED">REJECTED</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <!-- Lampiran -->
            <div class="grid gap-2">
              <Label class="text-[11px] font-black text-slate-400 uppercase tracking-widest pl-1">Unggah Nota / Bukti Bayar</Label>
              <Input type="file" @change="onFileChange" accept="image/*,.pdf" class="h-12 rounded-2xl border-slate-200 pt-2.5" />
              <div v-if="form.attachment_url && !form.attachment_file" class="flex items-center gap-2 mt-1 px-2">
                <span class="text-[11px] text-slate-500 font-bold">Nota terunggah:</span>
                <a :href="form.attachment_url.startsWith('http') ? form.attachment_url : `${import.meta.env.VITE_API_BASE_URL.replace('/api', '')}${form.attachment_url}`" target="_blank" class="text-[11px] text-primary font-black hover:underline flex items-center gap-1">
                  <Eye class="w-3 h-3" /> Lihat Nota
                </a>
              </div>
            </div>
          </div>
        </div>

        <DialogFooter class="p-8 bg-slate-50 flex gap-3 sm:gap-4 sm:justify-end">
          <Button variant="ghost" @click="isCRUDModalOpen = false" class="rounded-xl font-bold h-12 px-6">Batal</Button>
          <Button @click="saveReimbursement" :disabled="isSubmitting" class="rounded-xl font-black h-12 px-10 shadow-lg shadow-primary/20">
            {{ isSubmitting ? 'Menyimpan...' : (isEditMode ? 'Simpan Perubahan' : 'Tambah Pengajuan') }}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  </div>
</template>
