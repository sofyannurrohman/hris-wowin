<script setup lang="ts">
import { ref, h, onMounted } from 'vue'
import { Pencil, Trash2 } from 'lucide-vue-next'
import apiClient from '@/api/axios'
import DataTable from '@/components/DataTable.vue'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectGroup, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import MapPicker from '@/components/MapPicker.vue'
import { toast } from 'vue-sonner'

const isModalOpen = ref(false)
const newBranch = ref({
  id: '',
  companyId: '',
  name: '',
  address: '',
  timezone: 'Asia/Jakarta',
  latitude: 0,
  longitude: 0,
  radiusMeter: 100
})

const isEditMode = ref(false)
const isSubmitting = ref(false)
const branches = ref<any[]>([])
const companies = ref<any[]>([])
const isLoading = ref(true)

const timezones = [
  'Asia/Jakarta',
  'Asia/Makassar',
  'Asia/Jayapura',
]

const openAddModal = () => {
  isEditMode.value = false
  newBranch.value = {
    id: '',
    companyId: '',
    name: '',
    address: '',
    timezone: 'Asia/Jakarta',
    latitude: 0,
    longitude: 0,
    radiusMeter: 100
  }
  isModalOpen.value = true
}

const openEditModal = (branch: any) => {
  isEditMode.value = true
  newBranch.value = {
    id: branch.ID,
    companyId: branch.CompanyID || '',
    name: branch.Name || '',
    address: branch.Address || '',
    timezone: branch.Timezone || 'Asia/Jakarta',
    latitude: branch.Latitude || 0,
    longitude: branch.Longitude || 0,
    radiusMeter: branch.RadiusMeter || 100
  }
  isModalOpen.value = true
}

const closeModal = () => {
  isModalOpen.value = false
}

const fetchBranches = async () => {
  isLoading.value = true
  try {
    const response = await apiClient.get('/branches')
    branches.value = response.data.data
  } catch (error) {
    console.error('Failed to fetch branches:', error)
  } finally {
    isLoading.value = false
  }
}

const fetchCompanies = async () => {
  try {
    const response = await apiClient.get('/companies')
    companies.value = response.data.data
  } catch (error) {
    console.error('Failed to fetch companies:', error)
  }
}

const saveBranch = async () => {
  isSubmitting.value = true
  try {
    const payload = {
      companyId: newBranch.value.companyId,
      name: newBranch.value.name,
      address: newBranch.value.address,
      timezone: newBranch.value.timezone,
      latitude: Number(newBranch.value.latitude),
      longitude: Number(newBranch.value.longitude),
      radiusMeter: Number(newBranch.value.radiusMeter)
    }

    if (isEditMode.value) {
      await apiClient.put(`/branches/${newBranch.value.id}`, payload)
      toast.success('Kantor Cabang berhasil diperbarui!')
    } else {
      await apiClient.post('/branches', payload)
      toast.success('Kantor Cabang berhasil ditambahkan!')
    }
    closeModal()
    fetchBranches()
  } catch (error: any) {
    toast.error(`Gagal ${isEditMode.value ? 'memperbarui' : 'menambahkan'} kantor cabang: ` + (error.response?.data?.error || error.response?.data?.message || error.message))
  } finally {
    isSubmitting.value = false
  }
}

const deleteBranch = async (id: string) => {
  if (!confirm('Apakah Anda yakin ingin menghapus kantor cabang ini?')) return
  try {
    await apiClient.delete(`/branches/${id}`)
    toast.success('Kantor Cabang berhasil dihapus!')
    fetchBranches()
  } catch (error: any) {
    toast.error('Gagal menghapus: ' + (error.response?.data?.error || error.message))
  }
}

onMounted(() => {
  fetchBranches()
  fetchCompanies()
})

const columns = [
  {
    accessorKey: 'Name',
    header: 'NAMA CABANG',
    cell: (info: any) => h('span', { class: 'font-bold text-gray-900' }, info.getValue() || '-')
  },
  {
    id: 'company',
    header: 'PERUSAHAAN',
    cell: ({ row }: any) => {
      const company = row.original.Company
      return h('span', { class: 'text-gray-600' }, company?.Name || '-')
    }
  },
  {
    accessorKey: 'Address',
    header: 'ALAMAT',
    cell: (info: any) => h('span', { class: 'text-gray-600 max-w-[200px] truncate inline-block', title: info.getValue() }, info.getValue() || '-')
  },
  {
    accessorKey: 'Timezone',
    header: 'ZONA WAKTU',
    cell: (info: any) => h('span', { class: 'text-[13px] bg-gray-100 px-2 py-1 rounded font-mono' }, info.getValue() || '-')
  },
  {
    accessorKey: 'RadiusMeter',
    header: 'RADIUS (METER)',
    cell: (info: any) => h('span', { class: 'text-gray-600' }, info.getValue() ?? '-')
  },
  {
    id: 'actions',
    header: 'AKSI',
    cell: ({ row }: any) => {
      const branch = row.original
      return h('div', { class: 'flex items-center gap-2' }, [
        h(Button, {
          variant: 'ghost', size: 'sm',
          class: 'h-8 px-2 text-primary hover:text-primary hover:bg-primary/5',
          onClick: () => openEditModal(branch)
        }, () => h(Pencil, { class: 'w-4 h-4' })),
        h(Button, {
          variant: 'ghost', size: 'sm',
          class: 'h-8 px-2 text-red-600 hover:text-red-700 hover:bg-red-50',
          onClick: () => deleteBranch(branch.ID)
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
        <h1 class="text-[22px] font-bold text-gray-900 leading-tight">Data Kantor Cabang</h1>
        <p class="text-[14px] text-gray-500 mt-1">Kelola data lokasi dan zona waktu kantor cabang.</p>
      </div>
      <div class="flex items-center gap-3">
        <Button @click="openAddModal" class="gap-2 shadow-sm rounded-lg" size="sm">
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
          </svg>
          Tambah Cabang
        </Button>
      </div>
    </div>

    <DataTable :data="branches" :columns="columns" :isLoading="isLoading" />

    <Dialog v-model:open="isModalOpen">
      <DialogContent class="sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle class="text-xl">{{ isEditMode ? 'Edit Cabang' : 'Tambah Kantor Cabang' }}</DialogTitle>
          <DialogDescription>
            Konfigurasi lokasi, zona waktu, dan radius absensi kantor.
          </DialogDescription>
        </DialogHeader>

        <div class="grid gap-4 py-4">
          <div class="grid grid-cols-2 gap-4">
            <div class="grid gap-2">
              <label class="text-[13px] font-medium text-gray-700">Nama Cabang</label>
              <Input v-model="newBranch.name" placeholder="e.g. Kantor Pusat Jakarta" />
            </div>
            <div class="grid gap-2">
              <label class="text-[13px] font-medium text-gray-700">Perusahaan</label>
              <Select v-model="newBranch.companyId" :disabled="isEditMode">
                <SelectTrigger>
                  <SelectValue placeholder="Pilih perusahaan" />
                </SelectTrigger>
                <SelectContent>
                  <SelectGroup>
                    <SelectItem v-for="c in companies" :key="c.ID" :value="c.ID">
                      {{ c.Name }}
                    </SelectItem>
                  </SelectGroup>
                </SelectContent>
              </Select>
            </div>
          </div>

          <div class="grid gap-2">
            <label class="text-[13px] font-medium text-gray-700">Alamat</label>
            <textarea v-model="newBranch.address" placeholder="Alamat kantor cabang..." rows="2" class="flex min-h-[60px] w-full rounded-md border border-gray-200 bg-transparent px-3 py-2 text-sm shadow-sm placeholder:text-gray-500 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-gray-950"></textarea>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div class="grid gap-2">
              <label class="text-[13px] font-medium text-gray-700">Zona Waktu</label>
              <Select v-model="newBranch.timezone">
                <SelectTrigger>
                  <SelectValue placeholder="Pilih zona waktu" />
                </SelectTrigger>
                <SelectContent>
                  <SelectGroup>
                    <SelectItem v-for="tz in timezones" :key="tz" :value="tz">{{ tz }}</SelectItem>
                  </SelectGroup>
                </SelectContent>
              </Select>
            </div>
            <div class="grid gap-2">
              <label class="text-[13px] font-medium text-gray-700">Radius Absensi (Meter)</label>
              <Input v-model.number="newBranch.radiusMeter" type="number" min="10" placeholder="e.g. 100" />
            </div>
          </div>

          <div class="h-px bg-gray-100 my-1"></div>
          
          <div class="space-y-2">
            <label class="text-[13px] font-medium text-gray-700">Pilih Lokasi di Peta</label>
            <MapPicker 
              :latitude="newBranch.latitude" 
              :longitude="newBranch.longitude" 
              :radius="newBranch.radiusMeter"
              @update:location="(lat, lng) => { newBranch.latitude = lat; newBranch.longitude = lng }"
              @update:address="(addr) => { newBranch.address = addr }"
            />
          </div>

          <div class="h-px bg-gray-100 my-1"></div>
          <h3 class="text-[13px] font-bold text-gray-800 uppercase tracking-wider">Koordinat GPS</h3>

          <div class="grid grid-cols-2 gap-4">
            <div class="grid gap-2">
              <label class="text-[13px] font-medium text-gray-700">Latitude</label>
              <Input v-model.number="newBranch.latitude" type="number" step="0.000001" placeholder="-6.200000" />
            </div>
            <div class="grid gap-2">
              <label class="text-[13px] font-medium text-gray-700">Longitude</label>
              <Input v-model.number="newBranch.longitude" type="number" step="0.000001" placeholder="106.816666" />
            </div>
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" @click="closeModal">Batal</Button>
          <Button @click="saveBranch" :disabled="isSubmitting || !newBranch.name">
            {{ isSubmitting ? 'Menyimpan...' : 'Simpan Data' }}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  </div>
</template>
