<script setup lang="ts">
import { ref, h, onMounted } from 'vue'
import { Pencil, Trash2 } from 'lucide-vue-next'
import apiClient from '@/api/axios'
import DataTable from '@/components/DataTable.vue'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { toast } from 'vue-sonner'

const isModalOpen = ref(false)
const newLeaveType = ref({
  id: '',
  name: '',
  isPaid: true,
  defaultQuota: 12
})

const isEditMode = ref(false)

const isSubmitting = ref(false)
const leaveTypes = ref<any[]>([])
const isLoading = ref(true)

const openAddModal = () => {
  isEditMode.value = false
  newLeaveType.value = {
    id: '',
    name: '',
    isPaid: true,
    defaultQuota: 12
  }
  isModalOpen.value = true
}

const openEditModal = (leaveType: any) => {
  isEditMode.value = true
  newLeaveType.value = {
    id: leaveType.ID,
    name: leaveType.Name || '',
    isPaid: leaveType.IsPaid,
    defaultQuota: leaveType.DefaultQuota || 12
  }
  isModalOpen.value = true
}

const closeAddModal = () => {
  isModalOpen.value = false
}

const fetchLeaveTypes = async () => {
  isLoading.value = true
  try {
    const response = await apiClient.get('/leave-types')
    leaveTypes.value = response.data.data
  } catch (error) {
    console.error('Failed to fetch leave types:', error)
  } finally {
    isLoading.value = false
  }
}

const saveLeaveType = async () => {
  isSubmitting.value = true
  try {
    if (isEditMode.value) {
      await apiClient.put(`/leave-types/${newLeaveType.value.id}`, newLeaveType.value)
      toast.success('Tipe Cuti berhasil diperbarui!')
    } else {
      await apiClient.post('/leave-types', newLeaveType.value)
      toast.success('Tipe Cuti berhasil ditambahkan!')
    }
    closeAddModal()
    fetchLeaveTypes() // Refresh data
  } catch (error: any) {
    toast.error(`Gagal ${isEditMode.value ? 'memperbarui' : 'menambahkan'} tipe cuti: ` + (error.response?.data?.error || error.message))
  } finally {
    isSubmitting.value = false
  }
}

const deleteLeaveType = async (id: string) => {
  if (!confirm('Apakah Anda yakin ingin menghapus tipe cuti ini? Operasi ini tidak dapat dibatalkan.')) return
  
  try {
    await apiClient.delete(`/leave-types/${id}`)
    toast.success('Tipe Cuti berhasil dihapus!')
    fetchLeaveTypes()
  } catch (error: any) {
    toast.error('Gagal menghapus tipe cuti: ' + (error.response?.data?.error || error.message))
  }
}

onMounted(() => {
  fetchLeaveTypes()
})

const columns = [
  {
    accessorKey: 'Name',
    header: 'NAMA TIPE CUTI',
    cell: (info: any) => h('span', { class: 'font-bold text-gray-900' }, info.getValue() || '-')
  },
  {
    accessorKey: 'IsPaid',
    header: 'DIBAYAR',
    cell: (info: any) => {
      const isPaid = info.getValue()
      return h('span', { 
        class: isPaid ? 'border border-[#bbf7d0] text-[#16a34a] px-3 py-1 rounded-full text-[11px] font-bold inline-block' 
                      : 'border border-[#fecaca] text-[#dc2626] px-3 py-1 rounded-full text-[11px] font-bold inline-block' 
      }, isPaid ? 'Ya' : 'Tidak')
    }
  },
  {
    accessorKey: 'DefaultQuota',
    header: 'KUOTA DEFAULT (HARI)',
    cell: (info: any) => h('span', { class: 'text-gray-500 font-medium' }, info.getValue())
  },
  {
    accessorFn: (row: any) => row.CreatedAt ? new Date(row.CreatedAt).toLocaleDateString() : '-',
    id: 'createdAt',
    header: 'TANGGAL DIBUAT',
    cell: (info: any) => h('span', { class: 'text-gray-500 text-[13px]' }, info.getValue())
  },
  {
    id: 'actions',
    header: 'AKSI',
    cell: ({ row }: any) => {
      const leaveType = row.original
      return h('div', { class: 'flex items-center gap-2' }, [
        h(Button, { 
            variant: 'ghost', 
            size: 'sm', 
            class: 'h-8 px-2 text-blue-600 hover:text-blue-700 hover:bg-blue-50',
            onClick: () => openEditModal(leaveType)
        }, () => h(Pencil, { class: 'w-4 h-4' })),
        h(Button, { 
            variant: 'ghost', 
            size: 'sm', 
            class: 'h-8 px-2 text-red-600 hover:text-red-700 hover:bg-red-50',
            onClick: () => deleteLeaveType(leaveType.ID)
        }, () => h(Trash2, { class: 'w-4 h-4' }))
      ])
    }
  }
]
</script>

<template>
  <div class="space-y-6">
    <!-- Header Page -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h1 class="text-[22px] font-bold text-gray-900 leading-tight">Master Tipe Cuti</h1>
        <p class="text-[14px] text-gray-500 mt-1">Kelola data tipe dan jatah cuti karyawan.</p>
      </div>
      
      <div class="flex items-center gap-3">
        <Button @click="openAddModal" class="gap-2 shadow-sm rounded-lg" size="sm">
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
          </svg>
          Tambah Tipe Cuti
        </Button>
      </div>
    </div>

    <!-- DataTable Instance -->
    <DataTable :data="leaveTypes" :columns="columns" :isLoading="isLoading" />

    <!-- Add/Edit Modal -->
    <Dialog v-model:open="isModalOpen">
      <DialogContent class="sm:max-w-xl">
        <DialogHeader>
          <DialogTitle class="text-xl">{{ isEditMode ? 'Edit Tipe Cuti' : 'Tambah Tipe Cuti' }}</DialogTitle>
          <DialogDescription>
            Tentukan detail tipe cuti berikut.
          </DialogDescription>
        </DialogHeader>
        
        <div class="grid gap-4 py-4">
          <div class="grid gap-2">
            <label class="text-[13px] font-medium text-gray-700">Nama Tipe Cuti</label>
            <Input v-model="newLeaveType.name" placeholder="e.g. Cuti Tahunan" />
          </div>
          <div class="grid gap-2">
            <label class="text-[13px] font-medium text-gray-700">Kuota Default (Hari)</label>
            <Input v-model.number="newLeaveType.defaultQuota" type="number" min="0" placeholder="e.g. 12" />
          </div>
          <div class="flex items-center space-x-2 mt-2">
            <input type="checkbox" id="isPaid" v-model="newLeaveType.isPaid" class="w-4 h-4 rounded border-gray-300 text-blue-600 focus:ring-blue-600" />
            <label for="isPaid" class="text-sm font-medium leading-none">
              Dibayar / Paid Leave
            </label>
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" @click="closeAddModal">Batal</Button>
          <Button @click="saveLeaveType" :disabled="isSubmitting">
            {{ isSubmitting ? 'Menyimpan...' : 'Simpan Data' }}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  </div>
</template>
