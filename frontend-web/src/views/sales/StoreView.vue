<script setup lang="ts">
import { ref, onMounted, computed, watch, nextTick } from 'vue'
import apiClient from '@/api/axios'
import { toast } from 'vue-sonner'
import { 
  Plus, 
  Search, 
  Store, 
  User, 
  Phone, 
  MapPin, 
  Pencil, 
  Trash2, 
  Save, 
  X,
  CheckCircle2,
  AlertCircle,
  MoreVertical,
  Navigation,
  Globe,
  ImagePlus,
  Banknote,
  AlertTriangle
} from 'lucide-vue-next'
import { Button } from '@/components/ui/button'
import { useMasterDataStore } from '@/stores/masterData'

const masterDataStore = useMasterDataStore()
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import 'leaflet-defaulticon-compatibility'
import 'leaflet-defaulticon-compatibility/dist/leaflet-defaulticon-compatibility.css'

const isLoading = ref(true)
const stores = computed(() => masterDataStore.stores)
const salesmen = ref<any[]>([])
const searchQuery = ref('')
const selectedStatus = ref('ALL')
const showModal = ref(false)
const isEditing = ref(false)
const map = ref<any>(null)
const marker = ref<any>(null)
const isGeocoding = ref(false)

const currentStore = ref({
  id: '',
  name: '',
  owner_name: '',
  phone_number: '',
  address: '',
  latitude: 0,
  longitude: 0,
  assigned_employee_id: '',
  is_active: true,
  photo_url: ''
})

const selectedFile = ref<File | null>(null)
const imagePreview = ref<string | null>(null)

const handleFileChange = (e: any) => {
  const file = e.target.files[0]
  if (file) {
    selectedFile.value = file
    imagePreview.value = URL.createObjectURL(file)
  }
}

const fetchStores = async () => {
  if (!masterDataStore.selectedBranchId) return
  isLoading.value = true
  try {
    await masterDataStore.fetchStores(masterDataStore.selectedBranchCompanyId)
  } catch (error) {
    toast.error('Gagal mengambil data toko')
  } finally {
    isLoading.value = false
  }
}

const fetchSalesmen = async () => {
  if (!masterDataStore.selectedBranchId) return
  try {
    const res = await apiClient.get(`/employees?company_id=${masterDataStore.selectedBranchCompanyId || ''}`)
    if (res.data?.data) {
      salesmen.value = res.data.data.filter((emp: any) => {
        const jobTitle = (emp.job_position?.title || '').toLowerCase()
        return jobTitle.includes('sales') || jobTitle.includes('marketing')
      })
    }
  } catch (error) {
    console.error('Failed to fetch salesmen:', error)
  }
}

const initMap = async () => {
  if (map.value) return
  
  await nextTick()
  const mapElement = document.getElementById('store-map')
  if (!mapElement) return

  // Small delay to ensure modal transition finished
  setTimeout(() => {
    const el = document.getElementById('store-map')
    if (!el || map.value) return
    
    const defaultLat = currentStore.value.latitude || -6.2088
    const defaultLng = currentStore.value.longitude || 106.8456
    
    map.value = L.map('store-map', {
      zoomControl: true,
      scrollWheelZoom: true
    }).setView([defaultLat, defaultLng], 15)

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap contributors'
    }).addTo(map.value)

    marker.value = L.marker([defaultLat, defaultLng], {
      draggable: true
    }).addTo(map.value)

    marker.value.on('dragend', (e: any) => {
      const pos = e.target.getLatLng()
      currentStore.value.latitude = pos.lat
      currentStore.value.longitude = pos.lng
    })

    map.value.on('click', (e: any) => {
      const pos = e.latlng
      marker.value.setLatLng(pos)
      currentStore.value.latitude = pos.lat
      currentStore.value.longitude = pos.lng
    })
    
    // Force invalidation to fix grey tiles
    setTimeout(() => {
       map.value?.invalidateSize()
    }, 400)
  }, 100)
}

// Watch showModal to trigger map init and cleanup
watch(showModal, (newVal) => {
  if (newVal) {
    initMap()
  } else {
    if (map.value) {
      map.value.remove()
      map.value = null
      marker.value = null
    }
  }
})

const reverseGeocode = async (lat: number, lng: number) => {
  if (lat === 0 && lng === 0) return
  isGeocoding.value = true
  try {
    const res = await fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}`)
    const data = await res.json()
    if (data.display_name) {
      currentStore.value.address = data.display_name
    }
  } catch (error) {
    console.error('Reverse geocoding failed:', error)
  } finally {
    isGeocoding.value = false
  }
}

const openAddModal = () => {
  isEditing.value = false
  currentStore.value = {
    id: '',
    name: '',
    owner_name: '',
    phone_number: '',
    address: '',
    latitude: -6.2088,
    longitude: 106.8456,
    assigned_employee_id: '',
    is_active: true,
    photo_url: ''
  }
  selectedFile.value = null
  imagePreview.value = null
  showModal.value = true
}

const handleEdit = (store: any) => {
  isEditing.value = true
  currentStore.value = {
    id: store.id,
    name: store.name,
    owner_name: store.owner_name,
    phone_number: store.phone_number,
    address: store.address,
    latitude: store.latitude,
    longitude: store.longitude,
    assigned_employee_id: store.assigned_employee_id || '',
    is_active: store.is_active,
    photo_url: store.photo_url || ''
  }
  selectedFile.value = null
  imagePreview.value = null
  showModal.value = true
}

const handleDelete = async (id: string) => {
  if (!confirm('Yakin ingin menghapus toko ini? Semua riwayat penjualan akan tetap ada namun toko tidak akan muncul di daftar aktif.')) return
  try {
    await apiClient.delete(`/stores/${id}`)
    toast.success('Toko berhasil dihapus')
    fetchStores()
  } catch (error) {
    toast.error('Gagal menghapus toko')
  }
}

const handleSubmit = async () => {
  try {
    const formData = new FormData()
    formData.append('name', currentStore.value.name)
    formData.append('owner_name', currentStore.value.owner_name || '')
    formData.append('phone_number', currentStore.value.phone_number || '')
    formData.append('address', currentStore.value.address || '')
    formData.append('latitude', String(currentStore.value.latitude))
    formData.append('longitude', String(currentStore.value.longitude))
    if (currentStore.value.assigned_employee_id) {
      formData.append('assigned_employee_id', currentStore.value.assigned_employee_id)
    }
    formData.append('is_active', String(currentStore.value.is_active))
    formData.append('company_id', masterDataStore.selectedBranchCompanyId)
    
    if (selectedFile.value) {
      formData.append('photo', selectedFile.value)
    }

    if (isEditing.value) {
      await apiClient.put(`/stores/${currentStore.value.id}`, formData)
      toast.success('Data toko diperbarui')
    } else {
      await apiClient.post('/stores', formData)
      toast.success('Toko baru berhasil terdaftar')
    }
    showModal.value = false
    fetchStores()
  } catch (error) {
    toast.error('Gagal menyimpan data toko')
  }
}

watch(() => currentStore.value.latitude, (newVal) => {
  if (newVal && currentStore.value.longitude && !isGeocoding.value) {
    reverseGeocode(newVal, currentStore.value.longitude)
  }
})

watch(() => currentStore.value.longitude, (newVal) => {
  if (newVal && currentStore.value.latitude && !isGeocoding.value) {
    reverseGeocode(currentStore.value.latitude, newVal)
  }
})

const filteredStores = computed(() => {
  return stores.value.filter((s: any) => {
    const matchesSearch = s.name.toLowerCase().includes(searchQuery.value.toLowerCase()) || 
                          (s.owner_name && s.owner_name.toLowerCase().includes(searchQuery.value.toLowerCase())) ||
                          (s.address && s.address.toLowerCase().includes(searchQuery.value.toLowerCase()))
    
    const matchesStatus = selectedStatus.value === 'ALL' || 
                          (selectedStatus.value === 'ACTIVE' && s.is_active) ||
                          (selectedStatus.value === 'INACTIVE' && !s.is_active)
    
    return matchesSearch && matchesStatus
  })
})

onMounted(() => {
  fetchStores()
  fetchSalesmen()
})

watch(() => masterDataStore.selectedBranchId, () => {
  fetchStores()
  fetchSalesmen()
})
const formatCurrency = (amount: number) => {
  return new Intl.NumberFormat('id-ID', {
    style: 'currency',
    currency: 'IDR',
    minimumFractionDigits: 0
  }).format(amount)
}
</script>

<template>
  <div class="space-y-8 pb-10">
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-6">
      <div>
        <h1 class="text-3xl font-extrabold text-slate-900 tracking-tight">Toko Customer</h1>
        <p class="text-[15px] font-medium text-slate-500 mt-1.5 flex items-center gap-2">
          <Store class="w-4 h-4 text-primary" />
          Manajemen data pelanggan dan titik distribusi outlet.
        </p>
      </div>
      <Button @click="openAddModal" class="bg-primary hover:bg-primary/90 text-white rounded-2xl px-6 py-6 font-bold shadow-lg shadow-primary/20 flex items-center gap-2">
        <Plus class="w-5 h-5" /> Daftarkan Toko Baru
      </Button>
    </div>

    <!-- Filters -->
    <div class="bg-white p-4 rounded-3xl border border-slate-200 shadow-sm flex flex-col lg:flex-row gap-4 items-center">
      <div class="relative flex-1 w-full">
        <Search class="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
        <input 
          v-model="searchQuery"
          type="text" 
          placeholder="Cari Nama Toko, Owner, atau Alamat..." 
          class="w-full pl-12 pr-4 py-3.5 bg-slate-50 border-none rounded-2xl focus:ring-2 focus:ring-primary/20 transition-all font-medium text-slate-900"
        />
      </div>
      <div class="flex gap-3 w-full lg:w-auto">
        <button 
          @click="selectedStatus = 'ALL'"
          class="px-5 py-3 rounded-2xl text-sm font-bold transition-all"
          :class="selectedStatus === 'ALL' ? 'bg-slate-900 text-white shadow-lg' : 'bg-slate-50 text-slate-500 hover:bg-slate-100'"
        >
          Semua
        </button>
        <button 
          @click="selectedStatus = 'ACTIVE'"
          class="px-5 py-3 rounded-2xl text-sm font-bold transition-all"
          :class="selectedStatus === 'ACTIVE' ? 'bg-emerald-500 text-white shadow-lg' : 'bg-slate-50 text-slate-500 hover:bg-slate-100'"
        >
          Aktif
        </button>
      </div>
    </div>

    <!-- Store DataTable -->
    <div class="bg-white rounded-[32px] border border-slate-200 shadow-sm overflow-hidden flex flex-col">
      <div class="overflow-x-auto no-scrollbar">
        <table class="w-full border-collapse text-left">
          <thead class="bg-slate-50/50 border-b border-slate-100">
            <tr>
              <th class="p-6 text-[10px] font-black text-slate-400 uppercase tracking-widest">Toko / Outlet</th>
              <th class="p-6 text-[10px] font-black text-slate-400 uppercase tracking-widest">Pemilik</th>
              <th class="p-6 text-[10px] font-black text-slate-400 uppercase tracking-widest">Kontak</th>
              <th class="p-6 text-[10px] font-black text-slate-400 uppercase tracking-widest">Salesman</th>
              <th class="p-6 text-[10px] font-black text-slate-400 uppercase tracking-widest">Wilayah / Alamat</th>
              <th class="p-6 text-[10px] font-black text-slate-400 uppercase tracking-widest text-right">Total Piutang</th>
              <th class="p-6 text-[10px] font-black text-slate-400 uppercase tracking-widest text-center">Status</th>
              <th class="p-6 text-[10px] font-black text-slate-400 uppercase tracking-widest text-right">Aksi</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-50">
            <tr v-if="isLoading" v-for="i in 5" :key="i" class="animate-pulse">
              <td v-for="j in 7" :key="j" class="p-6">
                <div class="h-4 bg-slate-100 rounded-lg w-full"></div>
              </td>
            </tr>
            
            <tr v-else-if="filteredStores.length === 0">
              <td colspan="7" class="py-24 text-center">
                <div class="flex flex-col items-center gap-3">
                  <Store class="w-12 h-12 text-slate-200" />
                  <p class="font-bold text-slate-400">Tidak ada toko ditemukan.</p>
                </div>
              </td>
            </tr>

            <tr 
              v-for="store in filteredStores" 
              :key="store.id"
              class="group hover:bg-slate-50/50 transition-all"
            >
              <td class="p-6">
                <div class="flex items-center gap-4">
                   <div v-if="store.photo_url" class="w-10 h-10 rounded-xl overflow-hidden border border-slate-100 shrink-0">
                      <img :src="store.photo_url" class="w-full h-full object-cover" />
                   </div>
                   <div class="w-10 h-10 rounded-xl bg-slate-100 flex items-center justify-center shrink-0" v-else>
                      <Store class="w-5 h-5 text-slate-400" />
                   </div>
                   <div>
                     <p class="text-sm font-black text-slate-900 leading-none">{{ store.name }}</p>
                     <p class="text-[10px] font-bold text-slate-400 mt-1 uppercase tracking-tighter">ID: {{ store.id.split('-')[0] }}</p>
                   </div>
                </div>
              </td>
              <td class="p-6">
                <p class="text-sm font-bold text-slate-700">{{ store.owner_name || '-' }}</p>
              </td>
              <td class="p-6">
                <div class="flex items-center gap-2">
                  <Phone class="w-3.5 h-3.5 text-slate-300" />
                  <p class="text-sm font-bold text-slate-700">{{ store.phone_number || '-' }}</p>
                </div>
              </td>
              <td class="p-6">
                <div class="flex items-center gap-2">
                   <div class="w-7 h-7 rounded-lg bg-primary/10 flex items-center justify-center text-primary shrink-0">
                      <User class="w-3.5 h-3.5" />
                   </div>
                   <p class="text-sm font-bold text-slate-700">{{ store.assigned_employee?.first_name || 'Unassigned' }}</p>
                </div>
              </td>
              <td class="p-6 max-w-xs">
                <p class="text-xs font-medium text-slate-500 line-clamp-1 leading-relaxed">{{ store.address || '-' }}</p>
              </td>
              <td class="p-6 text-right">
                <div class="flex flex-col items-end">
                   <p :class="['text-sm font-black', store.total_receivable > 0 ? 'text-rose-600' : 'text-slate-900']">
                     {{ formatCurrency(store.total_receivable || 0) }}
                   </p>
                   <div v-if="store.overdue_count > 0" class="flex items-center gap-1 mt-1">
                      <AlertTriangle class="w-3 h-3 text-rose-500 animate-pulse" />
                      <p class="text-[9px] font-bold text-rose-500 uppercase">{{ store.overdue_count }} Nota Jatuh Tempo</p>
                   </div>
                   <p v-else-if="store.total_receivable > 0" class="text-[9px] font-bold text-orange-500 uppercase mt-1">Belum Lunas</p>
                   <p v-else class="text-[9px] font-bold text-emerald-500 uppercase mt-1">Lunas</p>
                </div>
              </td>
              <td class="p-6">
                <div class="flex justify-center">
                  <span :class="[
                    'text-[10px] font-black px-3 py-1 rounded-full uppercase tracking-wider border',
                    store.is_active ? 'bg-emerald-50 text-emerald-600 border-emerald-100' : 'bg-red-50 text-red-600 border-red-100'
                  ]">
                    {{ store.is_active ? 'AKTIF' : 'NON-AKTIF' }}
                  </span>
                </div>
              </td>
              <td class="p-6 text-right">
                <div class="flex justify-end gap-1">
                  <button 
                    @click="handleEdit(store)"
                    class="p-2 hover:bg-slate-100 rounded-xl transition-all text-slate-400 hover:text-primary"
                    title="Edit Toko"
                  >
                    <Pencil class="w-5 h-5" />
                  </button>
                  <button 
                    @click="handleDelete(store.id)"
                    class="p-2 hover:bg-red-50 rounded-xl transition-all text-red-400 hover:text-red-600"
                    title="Hapus Toko"
                  >
                    <Trash2 class="w-5 h-5" />
                  </button>
                  <button 
                    class="p-2 hover:bg-slate-100 rounded-xl transition-all text-slate-400 hover:text-blue-500"
                    title="Lihat Lokasi"
                  >
                    <Navigation class="w-5 h-5" />
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Store Modal -->
    <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="absolute inset-0 bg-slate-900/60 backdrop-blur-sm" @click="showModal = false"></div>
      <div class="bg-white rounded-[32px] w-full max-w-2xl relative z-10 shadow-2xl flex flex-col max-h-[90vh] overflow-hidden animate-in fade-in zoom-in duration-300">
        <!-- Header -->
        <div class="px-8 py-6 border-b border-slate-100 flex items-center justify-between bg-white shrink-0">
          <div>
            <h3 class="text-2xl font-black text-slate-900 tracking-tight">{{ isEditing ? 'Edit Data Toko' : 'Daftarkan Toko Baru' }}</h3>
            <p class="text-[10px] font-black text-slate-400 uppercase tracking-widest mt-0.5">Informasi Outlet Customer</p>
          </div>
          <button @click="showModal = false; map = null" class="p-2 hover:bg-slate-100 rounded-xl transition-all text-slate-400 hover:text-slate-900">
            <X class="w-6 h-6" />
          </button>
        </div>
        
        <!-- Body (Scrollable) -->
        <div class="p-8 overflow-y-auto space-y-6 custom-scrollbar">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div class="space-y-2">
              <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Nama Toko</label>
              <input v-model="currentStore.name" type="text" placeholder="Masukkan nama toko..." class="w-full bg-slate-50 border-2 border-transparent rounded-2xl px-5 py-4 font-bold text-slate-900 focus:bg-white focus:border-primary/20 focus:ring-0 transition-all" />
            </div>
            <div class="space-y-2">
              <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Nama Pemilik</label>
              <input v-model="currentStore.owner_name" type="text" placeholder="Nama pemilik toko..." class="w-full bg-slate-50 border-2 border-transparent rounded-2xl px-5 py-4 font-bold text-slate-900 focus:bg-white focus:border-primary/20 focus:ring-0 transition-all" />
            </div>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div class="space-y-2">
              <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Nomor Telepon</label>
              <input v-model="currentStore.phone_number" type="text" placeholder="0812..." class="w-full bg-slate-50 border-2 border-transparent rounded-2xl px-5 py-4 font-bold text-slate-900 focus:bg-white focus:border-primary/20 focus:ring-0 transition-all" />
            </div>
            <div class="space-y-2">
              <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Salesman Penanggung Jawab</label>
              <select v-model="currentStore.assigned_employee_id" class="w-full bg-slate-50 border-2 border-transparent rounded-2xl px-5 py-4 font-bold text-slate-900 focus:bg-white focus:border-primary/20 focus:ring-0 transition-all appearance-none">
                <option value="">Pilih Salesman</option>
                <option v-for="s in salesmen" :key="s.id" :value="s.id">{{ s.first_name }} {{ s.last_name }}</option>
              </select>
            </div>
          </div>

          <div class="space-y-2">
            <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Foto Toko (Tampak Depan)</label>
            <div class="flex items-center gap-4">
               <div v-if="imagePreview || currentStore.photo_url" class="w-24 h-24 rounded-2xl overflow-hidden border-2 border-slate-100 shrink-0 bg-slate-50">
                  <img :src="imagePreview || currentStore.photo_url" class="w-full h-full object-cover" />
               </div>
               <label class="flex-1 h-24 rounded-2xl border-2 border-dashed border-slate-200 hover:border-primary/40 hover:bg-primary/5 transition-all cursor-pointer flex flex-col items-center justify-center gap-2">
                  <ImagePlus class="w-6 h-6 text-slate-400" />
                  <span class="text-[10px] font-black text-slate-400 uppercase tracking-widest">Pilih Foto Toko</span>
                  <input type="file" class="hidden" accept="image/*" @change="handleFileChange" />
               </label>
            </div>
          </div>

          <div class="space-y-2">
            <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Alamat Lengkap</label>
            <textarea v-model="currentStore.address" placeholder="Masukkan alamat lengkap toko..." class="w-full bg-slate-50 border-2 border-transparent rounded-2xl px-5 py-4 font-bold text-slate-900 focus:bg-white focus:border-primary/20 focus:ring-0 transition-all h-24 resize-none"></textarea>
          </div>

          <div class="space-y-4">
            <div class="flex items-center justify-between">
              <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Titik Lokasi (Map Picker)</label>
              <div v-if="isGeocoding" class="flex items-center gap-2 text-[10px] font-black text-primary animate-pulse">
                <Globe class="w-3 h-3 animate-spin" /> MENCARI ALAMAT...
              </div>
            </div>
            <div id="store-map" class="w-full h-64 rounded-3xl border border-slate-100 shadow-inner z-10 overflow-hidden"></div>
            
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mt-4">
              <div class="space-y-2">
                <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Latitude</label>
                <input v-model.number="currentStore.latitude" type="number" step="any" class="w-full bg-slate-50 border-2 border-transparent rounded-2xl px-5 py-4 font-bold text-slate-900 focus:bg-white focus:border-primary/20 focus:ring-0 transition-all" />
              </div>
              <div class="space-y-2">
                <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Longitude</label>
                <input v-model.number="currentStore.longitude" type="number" step="any" class="w-full bg-slate-50 border-2 border-transparent rounded-2xl px-5 py-4 font-bold text-slate-900 focus:bg-white focus:border-primary/20 focus:ring-0 transition-all" />
              </div>
            </div>
          </div>

          <div class="flex items-center gap-3 bg-slate-50 p-4 rounded-2xl border border-slate-100">
            <input type="checkbox" v-model="currentStore.is_active" id="is_active" class="w-5 h-5 rounded-lg border-2 border-slate-300 text-primary focus:ring-primary/20 transition-all" />
            <label for="is_active" class="text-sm font-bold text-slate-700 cursor-pointer">Status Toko Aktif</label>
          </div>
        </div>

        <!-- Footer -->
        <div class="p-8 border-t border-slate-100 flex gap-4 bg-white shrink-0">
          <button @click="showModal = false; map = null" class="flex-1 py-4 text-xs font-black text-slate-400 hover:text-slate-900 transition-all uppercase tracking-widest">
            BATAL
          </button>
          <button 
            @click="handleSubmit"
            class="flex-[2] bg-primary text-white rounded-2xl py-4 text-xs font-black shadow-lg shadow-primary/20 hover:scale-[1.02] active:scale-[0.98] transition-all flex items-center justify-center gap-2 uppercase tracking-widest"
          >
            <Save class="w-5 h-5" /> SIMPAN DATA TOKO
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.custom-scrollbar::-webkit-scrollbar {
  width: 6px;
}
.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background: #e2e8f0;
  border-radius: 10px;
}
.custom-scrollbar::-webkit-scrollbar-thumb:hover {
  background: #cbd5e1;
}
</style>
