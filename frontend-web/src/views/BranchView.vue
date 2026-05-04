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
    id: branch.id,
    companyId: branch.company_id || '',
    name: branch.name || '',
    address: branch.address || '',
    timezone: branch.timezone || 'Asia/Jakarta',
    latitude: branch.latitude || 0,
    longitude: branch.longitude || 0,
    radiusMeter: branch.radius_meter || 100
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
      companyId: newBranch.value.companyId || null,
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
    accessorKey: 'name',
    header: 'NAMA CABANG',
    cell: (info: any) => h('span', { class: 'font-bold text-gray-900' }, info.getValue() || '-')
  },
  {
    id: 'company',
    header: 'PERUSAHAAN',
    cell: ({ row }: any) => {
      const company = row.original.company
      return h('span', { class: 'text-gray-600' }, company?.name || '-')
    }
  },
  {
    accessorKey: 'address',
    header: 'ALAMAT',
    cell: (info: any) => h('span', { class: 'text-gray-600 max-w-[200px] truncate inline-block', title: info.getValue() }, info.getValue() || '-')
  },
  {
    accessorKey: 'timezone',
    header: 'ZONA WAKTU',
    cell: (info: any) => h('span', { class: 'text-[13px] bg-gray-100 px-2 py-1 rounded font-mono' }, info.getValue() || '-')
  },
  {
    accessorKey: 'radius_meter',
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
          onClick: () => deleteBranch(branch.id)
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
      <DialogContent class="sm:max-w-2xl rounded-[2rem] md:rounded-[3rem] p-0 overflow-hidden border-none shadow-2xl max-h-[95vh] flex flex-col">
        <div class="bg-slate-900 p-8 md:p-10 text-white relative shrink-0">
            <DialogHeader>
              <DialogTitle class="text-xl md:text-2xl font-black">{{ isEditMode ? 'Edit Cabang' : 'Tambah Kantor Cabang' }}</DialogTitle>
              <DialogDescription class="text-slate-400 font-bold mt-2 uppercase text-[10px] md:text-[11px] tracking-widest border-l-4 border-primary pl-4">
                Konfigurasi lokasi, zona waktu, dan radius absensi kantor.
              </DialogDescription>
            </DialogHeader>
        </div>

        <div class="p-6 md:p-10 bg-white space-y-6 overflow-y-auto custom-scrollbar flex-1">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 md:gap-6">
            <div class="grid gap-2">
              <label class="text-[13px] font-black text-slate-400 uppercase tracking-widest pl-1">Nama Cabang</label>
              <Input v-model="newBranch.name" placeholder="e.g. Kantor Pusat Jakarta" class="h-12 rounded-2xl border-slate-200" />
            </div>
            <div class="grid gap-2">
              <label class="text-[13px] font-black text-slate-400 uppercase tracking-widest pl-1">Perusahaan</label>
              <Select v-model="newBranch.companyId">
                <SelectTrigger class="h-12 rounded-2xl border-slate-200">
                  <SelectValue placeholder="Pilih perusahaan" />
                </SelectTrigger>
                <SelectContent>
                  <SelectGroup>
                    <SelectItem v-for="c in companies" :key="c.id" :value="c.id">
                      {{ c.name }}
                    </SelectItem>
                  </SelectGroup>
                </SelectContent>
              </Select>
            </div>
          </div>

          <div class="grid gap-2">
            <label class="text-[13px] font-black text-slate-400 uppercase tracking-widest pl-1">Alamat Lengkap</label>
            <textarea v-model="newBranch.address" placeholder="Alamat kantor cabang..." rows="2" class="flex min-h-[80px] w-full rounded-2xl border border-slate-200 bg-transparent px-4 py-3 text-sm shadow-sm placeholder:text-gray-400 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 transition-all"></textarea>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 md:gap-6">
            <div class="grid gap-2">
              <label class="text-[13px] font-black text-slate-400 uppercase tracking-widest pl-1">Zona Waktu</label>
              <Select v-model="newBranch.timezone">
                <SelectTrigger class="h-12 rounded-2xl border-slate-200">
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
              <label class="text-[13px] font-black text-slate-400 uppercase tracking-widest pl-1">Radius Absensi (Meter)</label>
              <Input v-model.number="newBranch.radiusMeter" type="number" min="10" placeholder="e.g. 100" class="h-12 rounded-2xl border-slate-200" />
            </div>
          </div>

          <div class="h-px bg-slate-100 my-2"></div>
          
          <div class="space-y-3">
            <label class="text-[13px] font-black text-slate-400 uppercase tracking-widest pl-1">Pilih Lokasi di Peta</label>
            <MapPicker 
              :latitude="newBranch.latitude" 
              :longitude="newBranch.longitude" 
              :radius="newBranch.radiusMeter"
              height="200px"
              @update:location="(lat, lng) => { newBranch.latitude = lat; newBranch.longitude = lng }"
              @update:address="(addr) => { newBranch.address = addr }"
            />
          </div>

          <div class="h-px bg-slate-100 my-2"></div>
          
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 md:gap-6 pt-2">
            <div class="grid gap-2">
              <label class="text-[13px] font-black text-slate-400 uppercase tracking-widest pl-1">Latitude</label>
              <Input v-model.number="newBranch.latitude" type="number" step="0.000001" placeholder="-6.200000" class="h-12 rounded-2xl border-slate-200" />
            </div>
            <div class="grid gap-2">
              <label class="text-[13px] font-black text-slate-400 uppercase tracking-widest pl-1">Longitude</label>
              <Input v-model.number="newBranch.longitude" type="number" step="0.000001" placeholder="106.816666" class="h-12 rounded-2xl border-slate-200" />
            </div>
          </div>
        </div>

        <DialogFooter class="p-8 md:p-10 pt-0 bg-white grid grid-cols-2 gap-4 shrink-0">
          <Button variant="ghost" @click="closeModal" :disabled="isSubmitting" class="rounded-2xl h-12 md:h-14 font-black text-slate-400 border border-slate-100 hover:bg-slate-50 transition-all">BATAL</Button>
          <Button @click="saveBranch" :disabled="isSubmitting || !newBranch.name" class="bg-primary hover:bg-primary/90 text-white rounded-2xl h-12 md:h-14 font-black shadow-xl shadow-primary/20 transform active:scale-95 transition-all">
            {{ isSubmitting ? 'MENYIMPAN...' : 'SIMPAN DATA' }}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  </div>
</template>
