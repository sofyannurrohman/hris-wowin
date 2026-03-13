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
const newCompany = ref({
  id: '',
  name: '',
  taxNumber: '',
  address: '',
  logoUrl: ''
})

const isEditMode = ref(false)
const isSubmitting = ref(false)
const companies = ref<any[]>([])
const isLoading = ref(true)

const openAddModal = () => {
  isEditMode.value = false
  newCompany.value = {
    id: '',
    name: '',
    taxNumber: '',
    address: '',
    logoUrl: ''
  }
  isModalOpen.value = true
}

const openEditModal = (company: any) => {
  isEditMode.value = true
  newCompany.value = {
    id: company.ID,
    name: company.Name || '',
    taxNumber: company.TaxNumber || '',
    address: company.Address || '',
    logoUrl: company.LogoURL || ''
  }
  isModalOpen.value = true
}

const closeAddModal = () => {
  isModalOpen.value = false
}

const fetchCompanies = async () => {
  isLoading.value = true
  try {
    const response = await apiClient.get('/companies')
    companies.value = response.data.data
  } catch (error) {
    console.error('Failed to fetch companies:', error)
  } finally {
    isLoading.value = false
  }
}

const saveCompany = async () => {
  isSubmitting.value = true
  try {
    if (isEditMode.value) {
      await apiClient.put(`/companies/${newCompany.value.id}`, newCompany.value)
      toast.success('Perusahaan berhasil diperbarui!')
    } else {
      await apiClient.post('/companies', newCompany.value)
      toast.success('Perusahaan berhasil ditambahkan!')
    }
    closeAddModal()
    fetchCompanies()
  } catch (error: any) {
    toast.error(`Gagal ${isEditMode.value ? 'memperbarui' : 'menambahkan'} perusahaan: ` + (error.response?.data?.error || error.response?.data?.message || error.message))
  } finally {
    isSubmitting.value = false
  }
}

const deleteCompany = async (id: string) => {
  if (!confirm('Apakah Anda yakin ingin menghapus perusahaan ini? Operasi ini tidak dapat dibatalkan.')) return
  
  try {
    await apiClient.delete(`/companies/${id}`)
    toast.success('Perusahaan berhasil dihapus!')
    fetchCompanies()
  } catch (error: any) {
    toast.error('Gagal menghapus perusahaan: ' + (error.response?.data?.error || error.response?.data?.message || error.message))
  }
}

onMounted(() => {
  fetchCompanies()
})

const columns = [
  {
    accessorKey: 'Name',
    header: 'NAMA PERUSAHAAN',
    cell: (info: any) => h('span', { class: 'font-bold text-gray-900' }, info.getValue() || '-')
  },
  {
    accessorKey: 'TaxNumber',
    header: 'NPWP',
    cell: (info: any) => h('span', { class: 'text-gray-600' }, info.getValue() || '-')
  },
  {
    accessorKey: 'Address',
    header: 'ALAMAT',
    cell: (info: any) => h('span', { class: 'text-gray-600 truncate max-w-[200px] inline-block', title: info.getValue() }, info.getValue() || '-')
  },
  {
    id: 'actions',
    header: 'AKSI',
    cell: ({ row }: any) => {
      const company = row.original
      return h('div', { class: 'flex items-center gap-2' }, [
        h(Button, { 
            variant: 'ghost', 
            size: 'sm', 
            class: 'h-8 px-2 text-blue-600 hover:text-blue-700 hover:bg-blue-50',
            onClick: () => openEditModal(company)
        }, () => h(Pencil, { class: 'w-4 h-4' })),
        h(Button, { 
            variant: 'ghost', 
            size: 'sm', 
            class: 'h-8 px-2 text-red-600 hover:text-red-700 hover:bg-red-50',
            onClick: () => deleteCompany(company.ID)
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
        <h1 class="text-[22px] font-bold text-gray-900 leading-tight">Master Perusahaan</h1>
        <p class="text-[14px] text-gray-500 mt-1">Kelola data grup perusahaan / entitas bisnis.</p>
      </div>
      
      <div class="flex items-center gap-3">
        <Button @click="openAddModal" class="gap-2 shadow-sm rounded-lg" size="sm">
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
          </svg>
          Tambah Perusahaan
        </Button>
      </div>
    </div>

    <DataTable :data="companies" :columns="columns" :isLoading="isLoading" />

    <Dialog v-model:open="isModalOpen">
      <DialogContent class="sm:max-w-xl">
        <DialogHeader>
          <DialogTitle class="text-xl">{{ isEditMode ? 'Edit Perusahaan' : 'Tambah Perusahaan' }}</DialogTitle>
          <DialogDescription>
            Masukkan detail informasi perusahaan.
          </DialogDescription>
        </DialogHeader>
        
        <div class="grid gap-4 py-4">
          <div class="grid gap-2">
            <label class="text-[13px] font-medium text-gray-700">Nama Perusahaan</label>
            <Input v-model="newCompany.name" placeholder="e.g. PT Maju Bersama" />
          </div>

          <div class="grid gap-2">
            <label class="text-[13px] font-medium text-gray-700">Nomor NPWP</label>
            <Input v-model="newCompany.taxNumber" placeholder="XX.XXX.XXX.X-XXX.XXX" />
          </div>

          <div class="grid gap-2">
            <label class="text-[13px] font-medium text-gray-700">Alamat Lengkap</label>
            <textarea v-model="newCompany.address" placeholder="Tuliskan alamat letak fisik utama." rows="3" class="flex min-h-[80px] w-full rounded-md border border-gray-200 bg-transparent px-3 py-2 text-sm shadow-sm placeholder:text-gray-500 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-gray-950 disabled:cursor-not-allowed disabled:opacity-50"></textarea>
          </div>
          
          <div class="grid gap-2">
            <label class="text-[13px] font-medium text-gray-700">URL Logo (Opsional)</label>
            <Input v-model="newCompany.logoUrl" placeholder="https://..." />
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" @click="closeAddModal">Batal</Button>
          <Button @click="saveCompany" :disabled="isSubmitting || !newCompany.name">
            {{ isSubmitting ? 'Menyimpan...' : 'Simpan Data' }}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  </div>
</template>
