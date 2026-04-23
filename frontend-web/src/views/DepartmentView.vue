<script setup lang="ts">
import { ref, h, onMounted, computed } from 'vue'
import { Pencil, Trash2 } from 'lucide-vue-next'
import apiClient from '@/api/axios'
import DataTable from '@/components/DataTable.vue'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectGroup, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { toast } from 'vue-sonner'

const isModalOpen = ref(false)
const newDepartment = ref({
  id: '',
  name: '',
  parentId: 'none'
})

const isEditMode = ref(false)
const isSubmitting = ref(false)
const departments = ref<any[]>([])
const isLoading = ref(true)

const openAddModal = () => {
  isEditMode.value = false
  newDepartment.value = {
    id: '',
    name: '',
    parentId: 'none'
  }
  isModalOpen.value = true
}

const openEditModal = (department: any) => {
  isEditMode.value = true
  newDepartment.value = {
    id: department.id,
    name: department.name || '',
    parentId: department.parent_id || 'none'
  }
  isModalOpen.value = true
}

const closeAddModal = () => {
  isModalOpen.value = false
}

const fetchDepartments = async () => {
  isLoading.value = true
  try {
    const response = await apiClient.get('/departments')
    departments.value = response.data.data
  } catch (error) {
    console.error('Failed to fetch departments:', error)
  } finally {
    isLoading.value = false
  }
}

// Ensure the dropdown doesn't show the current edited department as its own parent option
const validParentOptions = computed(() => {
  if (!isEditMode.value) return departments.value
  return departments.value.filter((d: any) => d.id !== newDepartment.value.id)
})

const saveDepartment = async () => {
  isSubmitting.value = true
  try {
    const payload = {
      name: newDepartment.value.name,
      parentId: newDepartment.value.parentId === 'none' ? null : newDepartment.value.parentId
    }

    if (isEditMode.value) {
      await apiClient.put(`/departments/${newDepartment.value.id}`, payload)
      toast.success('Departemen berhasil diperbarui!')
    } else {
      await apiClient.post('/departments', payload)
      toast.success('Departemen berhasil ditambahkan!')
    }
    closeAddModal()
    fetchDepartments()
  } catch (error: any) {
    toast.error(`Gagal ${isEditMode.value ? 'memperbarui' : 'menambahkan'} departemen: ` + (error.response?.data?.error || error.response?.data?.message || error.message))
  } finally {
    isSubmitting.value = false
  }
}

const deleteDepartment = async (id: string) => {
  if (!confirm('Apakah Anda yakin ingin menghapus departemen ini? Operasi ini tidak dapat dibatalkan.')) return
  
  try {
    await apiClient.delete(`/departments/${id}`)
    toast.success('Departemen berhasil dihapus!')
    fetchDepartments()
  } catch (error: any) {
    toast.error('Gagal menghapus departemen: ' + (error.response?.data?.error || error.response?.data?.message || error.message))
  }
}

onMounted(() => {
  fetchDepartments()
})

const columns = [
  {
    accessorKey: 'name',
    header: 'NAMA DEPARTEMEN',
    cell: (info: any) => h('span', { class: 'font-bold text-gray-900' }, info.getValue() || '-')
  },
  {
    id: 'parentDepartment',
    header: 'DEPARTEMEN INDUK',
    cell: ({ row }: any) => {
      const parent = row.original.parent_department
      if (parent && parent.name) {
         return h('span', { class: 'inline-block bg-primary/5 text-primary px-3 py-1 rounded-full text-[12px] font-medium' }, parent.name)
      }
      return h('span', { class: 'text-gray-400 italic' }, 'Utama (Tidak Ada)')
    }
  },
  {
    accessorFn: (row: any) => row.created_at ? new Date(row.created_at).toLocaleDateString() : '-',
    id: 'createdAt',
    header: 'TANGGAL DIBUAT',
    cell: (info: any) => h('span', { class: 'text-gray-500 text-[13px]' }, info.getValue())
  },
  {
    id: 'actions',
    header: 'AKSI',
    cell: ({ row }: any) => {
      const department = row.original
      return h('div', { class: 'flex items-center gap-2' }, [
        h(Button, { 
            variant: 'ghost', 
            size: 'sm', 
            class: 'h-8 px-2 text-primary hover:text-primary hover:bg-primary/5',
            onClick: () => openEditModal(department)
        }, () => h(Pencil, { class: 'w-4 h-4' })),
        h(Button, { 
            variant: 'ghost', 
            size: 'sm', 
            class: 'h-8 px-2 text-red-600 hover:text-red-700 hover:bg-red-50',
            onClick: () => deleteDepartment(department.id)
        }, () => h(Trash2, { class: 'w-4 h-4' }))
      ])
    }
  }
]
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h1 class="text-[22px] font-bold text-gray-900 leading-tight">Master Departemen</h1>
        <p class="text-[14px] text-gray-500 mt-1">Kelola data struktur departemen perusahaan Anda.</p>
      </div>
      
      <div class="flex items-center gap-3">
        <Button @click="openAddModal" class="gap-2 shadow-sm rounded-lg" size="sm">
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
          </svg>
          Tambah Departemen
        </Button>
      </div>
    </div>

    <DataTable :data="departments" :columns="columns" :isLoading="isLoading" />

    <Dialog v-model:open="isModalOpen">
      <DialogContent class="sm:max-w-xl rounded-[2rem] md:rounded-[3rem] p-0 overflow-hidden border-none shadow-2xl max-h-[95vh] flex flex-col">
        <div class="bg-slate-900 p-8 md:p-10 text-white relative shrink-0">
          <DialogHeader>
            <DialogTitle class="text-xl md:text-2xl font-black">{{ isEditMode ? 'Edit Departemen' : 'Tambah Departemen' }}</DialogTitle>
            <DialogDescription class="text-slate-400 font-bold mt-2 uppercase text-[10px] md:text-[11px] tracking-widest border-l-4 border-primary pl-4 leading-relaxed">
                Organisir struktur perusahaan dengan mendefinisikan departemen baru.
            </DialogDescription>
          </DialogHeader>
        </div>

        <div class="p-6 md:p-10 bg-white space-y-6 overflow-y-auto custom-scrollbar flex-1">
          <div class="grid gap-2">
            <label class="text-[13px] font-medium text-gray-700">Nama Departemen</label>
            <Input v-model="newDepartment.name" placeholder="e.g. Teknik" />
          </div>

          <div class="grid gap-2">
            <label class="text-[13px] font-medium text-gray-700">Departemen Induk (Opsional)</label>
            <Select v-model="newDepartment.parentId">
              <SelectTrigger>
                <SelectValue placeholder="Pilih Induk (Atau biarkan kosong)" />
              </SelectTrigger>
              <SelectContent>
                <SelectGroup>
                  <SelectItem value="none">-- Tidak Ada (Tingkat Utama) --</SelectItem>
                  <SelectItem v-for="dept in validParentOptions" :key="dept.id" :value="dept.id">
                    {{ dept.name }}
                  </SelectItem>
                </SelectGroup>
              </SelectContent>
            </Select>
          </div>
        </div>

        <DialogFooter class="p-6 md:p-10 pt-0 bg-white grid grid-cols-2 gap-4 shrink-0">
          <Button variant="ghost" @click="isModalOpen = false" :disabled="isSubmitting" class="rounded-2xl h-12 md:h-14 font-black text-slate-400 border border-slate-100 hover:bg-slate-50 transition-all">BATAL</Button>
          <Button @click="saveDepartment" :disabled="isSubmitting" class="bg-primary hover:bg-primary/90 text-white rounded-2xl h-12 md:h-14 font-black shadow-xl shadow-primary/20 transform active:scale-95 transition-all">
            {{ isSubmitting ? 'MENYIMPAN...' : 'SIMPAN DATA' }}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  </div>
</template>
