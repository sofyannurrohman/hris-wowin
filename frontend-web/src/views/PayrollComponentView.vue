<script setup lang="ts">
import { ref, h, onMounted } from 'vue'
import { Pencil, Trash2 } from 'lucide-vue-next'
import apiClient from '@/api/axios'
import DataTable from '@/components/DataTable.vue'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectGroup, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { toast } from 'vue-sonner'

const isModalOpen = ref(false)
const newComponent = ref({
  id: '',
  name: '',
  type: 'EARNING',
  isTaxable: true
})

const isEditMode = ref(false)

const isSubmitting = ref(false)
const components = ref<any[]>([])
const isLoading = ref(true)

const openAddModal = () => {
  isEditMode.value = false
  newComponent.value = {
    id: '',
    name: '',
    type: 'EARNING',
    isTaxable: true
  }
  isModalOpen.value = true
}

const openEditModal = (component: any) => {
  isEditMode.value = true
  newComponent.value = {
    id: component.id,
    name: component.name || '',
    type: component.type || 'EARNING',
    isTaxable: component.is_taxable
  }
  isModalOpen.value = true
}

const closeAddModal = () => {
  isModalOpen.value = false
}

const fetchComponents = async () => {
  isLoading.value = true
  try {
    const response = await apiClient.get('/payroll-components')
    components.value = response.data.data
  } catch (error) {
    console.error('Failed to fetch payroll components:', error)
  } finally {
    isLoading.value = false
  }
}

const saveComponent = async () => {
  isSubmitting.value = true
  try {
    if (isEditMode.value) {
      await apiClient.put(`/payroll-components/${newComponent.value.id}`, newComponent.value)
      toast.success('Komponen gaji berhasil diperbarui!')
    } else {
      await apiClient.post('/payroll-components', newComponent.value)
      toast.success('Komponen gaji berhasil ditambahkan!')
    }
    closeAddModal()
    fetchComponents() // Refresh data
  } catch (error: any) {
    toast.error(`Gagal ${isEditMode.value ? 'memperbarui' : 'menambahkan'} komponen gaji: ` + (error.response?.data?.error || error.message))
  } finally {
    isSubmitting.value = false
  }
}

const deleteComponent = async (id: string) => {
  if (!confirm('Apakah Anda yakin ingin menghapus komponen gaji ini? Operasi ini tidak dapat dibatalkan.')) return
  
  try {
    await apiClient.delete(`/payroll-components/${id}`)
    toast.success('Komponen gaji berhasil dihapus!')
    fetchComponents()
  } catch (error: any) {
    toast.error('Gagal menghapus komponen gaji: ' + (error.response?.data?.error || error.message))
  }
}

onMounted(() => {
  fetchComponents()
})

const columns = [
  {
    accessorKey: 'name',
    header: 'NAMA KOMPONEN',
    cell: (info: any) => h('span', { class: 'font-bold text-gray-900' }, info.getValue() || '-')
  },
  {
    accessorKey: 'type',
    header: 'TIPE',
    cell: ({ getValue }: any) => {
        const val = getValue() as string || 'Unknown'
        let classes = 'border border-[#fecaca] text-[#dc2626]' 
        if (val === 'EARNING') classes = 'border border-[#bbf7d0] text-[#16a34a]'
        else if (val === 'BENEFIT') classes = 'border border-[#fef08a] text-[#ca8a04]'
        else if (val === 'DEDUCTION') classes = 'border border-[#fecaca] text-[#dc2626]'
        return h('span', { class: `${classes} px-3 py-1 rounded-full text-[11px] font-bold inline-block` }, val)
    }
  },
  {
    accessorKey: 'is_taxable',
    header: 'KENA PAJAK',
    cell: (info: any) => h('span', { class: 'text-gray-500 font-medium' }, info.getValue() ? 'Ya' : 'Tidak')
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
      const component = row.original
      return h('div', { class: 'flex items-center gap-2' }, [
        h(Button, { 
            variant: 'ghost', 
            size: 'sm', 
            class: 'h-8 px-2 text-primary hover:text-primary hover:bg-primary/5',
            onClick: () => openEditModal(component)
        }, () => h(Pencil, { class: 'w-4 h-4' })),
        h(Button, { 
            variant: 'ghost', 
            size: 'sm', 
            class: 'h-8 px-2 text-red-600 hover:text-red-700 hover:bg-red-50',
            onClick: () => deleteComponent(component.id)
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
        <h1 class="text-[22px] font-bold text-gray-900 leading-tight">Komponen Gaji</h1>
        <p class="text-[14px] text-gray-500 mt-1">Kelola data komponen pendapatan dan potongan gaji.</p>
      </div>
      
      <div class="flex items-center gap-3">
        <Button @click="openAddModal" class="gap-2 shadow-sm rounded-lg" size="sm">
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
          </svg>
          Tambah Komponen
        </Button>
      </div>
    </div>

    <!-- DataTable Instance -->
    <DataTable :data="components" :columns="columns" :isLoading="isLoading" />

    <!-- Add/Edit Modal -->
    <Dialog v-model:open="isModalOpen">
      <DialogContent class="sm:max-w-xl">
        <DialogHeader>
          <DialogTitle class="text-xl">{{ isEditMode ? 'Edit Komponen Gaji' : 'Tambah Komponen Gaji' }}</DialogTitle>
          <DialogDescription>
            Tentukan detail komponen gaji berikut.
          </DialogDescription>
        </DialogHeader>
        
        <div class="grid gap-4 py-4">
          <div class="grid gap-2">
            <label class="text-[13px] font-medium text-gray-700">Nama Komponen</label>
            <Input v-model="newComponent.name" placeholder="e.g. Tunjangan Transport" />
          </div>
          <div class="grid gap-2">
            <label class="text-[13px] font-medium text-gray-700">Tipe</label>
            <Select v-model="newComponent.type">
              <SelectTrigger>
                <SelectValue placeholder="Pilih Tipe" />
              </SelectTrigger>
              <SelectContent>
                <SelectGroup>
                  <SelectItem value="EARNING">Pendapatan (EARNING)</SelectItem>
                  <SelectItem value="BENEFIT">Benefit (BENEFIT)</SelectItem>
                  <SelectItem value="DEDUCTION">Potongan (DEDUCTION)</SelectItem>
                </SelectGroup>
              </SelectContent>
            </Select>
          </div>
          <div class="flex items-center space-x-2 mt-2">
            <input type="checkbox" id="taxable" v-model="newComponent.isTaxable" class="w-4 h-4 rounded border-gray-300 text-primary focus:ring-primary" />
            <label for="taxable" class="text-sm font-medium leading-none">
              Kena Pajak
            </label>
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" @click="closeAddModal">Batal</Button>
          <Button @click="saveComponent" :disabled="isSubmitting">
            {{ isSubmitting ? 'Menyimpan...' : 'Simpan Data' }}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  </div>
</template>
