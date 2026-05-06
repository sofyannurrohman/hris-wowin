<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue'
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
  ImagePlus
} from 'lucide-vue-next'
import { Button } from '@/components/ui/button'
import { useMasterDataStore } from '@/stores/masterData'

const masterDataStore = useMasterDataStore()
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import 'leaflet-defaulticon-compatibility'
import 'leaflet-defaulticon-compatibility/dist/leaflet-defaulticon-compatibility.css'

const isLoading = ref(true)
const stores = ref<any[]>([])
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
    const res = await apiClient.get(`/stores?company_id=${masterDataStore.selectedBranchCompanyId || ''}`)
    if (res.data?.data) {
      stores.value = res.data.data
    }
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

const initMap = () => {
  if (map.value) return
  
  setTimeout(() => {
    const defaultLat = currentStore.value.latitude || -6.2088
    const defaultLng = currentStore.value.longitude || 106.8456
    
    map.value = L.map('store-map').setView([defaultLat, defaultLng], 15)
    
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
      reverseGeocode(pos.lat, pos.lng)
    })

    map.value.on('click', (e: any) => {
      const pos = e.latlng
      marker.value.setLatLng(pos)
      currentStore.value.latitude = pos.lat
      currentStore.value.longitude = pos.lng
      reverseGeocode(pos.lat, pos.lng)
    })
  }, 300)
}

const reverseGeocode = async (lat: number, lng: number) => {
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
  initMap()
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
  initMap()
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
  return stores.value.filter(s => {
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

    <!-- Store Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
      <div 
        v-for="store in filteredStores" 
        :key="store.id"
        class="bg-white rounded-[32px] border border-slate-200 shadow-sm hover:shadow-xl transition-all duration-500 group overflow-hidden flex flex-col"
      >
        <div class="p-7 flex-1">
          <div class="flex items-start justify-between mb-6">
            <div class="flex items-center gap-4">
              <div v-if="store.photo_url" class="w-16 h-16 rounded-2xl overflow-hidden border-2 border-slate-100 shrink-0 bg-slate-50">
                  <img :src="store.photo_url" class="w-full h-full object-cover" />
              </div>
              <div class="p-4 bg-slate-50 rounded-2xl group-hover:bg-primary/10 transition-colors" v-else>
                <Store class="w-6 h-6 text-slate-400 group-hover:text-primary transition-colors" />
              </div>
            </div>
            <span :class="[
              'px-3 py-1 rounded-lg text-[10px] font-black tracking-widest uppercase border',
              store.is_active ? 'bg-emerald-50 text-emerald-600 border-emerald-100' : 'bg-red-50 text-red-600 border-red-100'
            ]">
              {{ store.is_active ? 'AKTIF' : 'NON-AKTIF' }}
            </span>
          </div>

          <h3 class="text-xl font-black text-slate-900 mb-1 group-hover:text-primary transition-colors">{{ store.name }}</h3>
          <p class="text-xs font-bold text-slate-400 flex items-center gap-2 mb-6">
            <User class="w-3.5 h-3.5" /> Owner: {{ store.owner_name || '-' }}
          </p>

          <div class="space-y-4 pt-6 border-t border-slate-50">
            <div class="flex items-center gap-3">
              <div class="w-8 h-8 rounded-xl bg-blue-50 flex items-center justify-center text-blue-600 shrink-0">
                <Phone class="w-4 h-4" />
              </div>
              <p class="text-sm font-bold text-slate-700">{{ store.phone_number || '-' }}</p>
            </div>
            <div class="flex items-start gap-3">
              <div class="w-8 h-8 rounded-xl bg-purple-50 flex items-center justify-center text-purple-600 shrink-0">
                <MapPin class="w-4 h-4" />
              </div>
              <p class="text-sm font-bold text-slate-600 leading-relaxed line-clamp-2">{{ store.address || 'Alamat belum diset' }}</p>
            </div>
            <div class="flex items-center gap-3">
              <div class="w-8 h-8 rounded-xl bg-amber-50 flex items-center justify-center text-amber-600 shrink-0">
                <User class="w-4 h-4" />
              </div>
              <div class="flex flex-col">
                <p class="text-[10px] font-black text-slate-400 uppercase tracking-widest">Salesman Penanggung Jawab</p>
                <p class="text-sm font-bold text-slate-900">{{ store.assigned_employee?.first_name || 'Belum diplot' }} {{ store.assigned_employee?.last_name || '' }}</p>
              </div>
            </div>
          </div>
        </div>

        <!-- Footer Actions -->
        <div class="px-7 py-5 bg-slate-50/50 border-t border-slate-100 flex items-center justify-between">
          <div class="flex gap-2">
            <button @click="handleEdit(store)" class="p-2.5 bg-white text-slate-400 hover:text-primary hover:bg-white rounded-xl transition-all shadow-sm border border-slate-100">
              <Pencil class="w-4 h-4" />
            </button>
            <button @click="handleDelete(store.id)" class="p-2.5 bg-white text-slate-400 hover:text-red-500 hover:bg-white rounded-xl transition-all shadow-sm border border-slate-100">
              <Trash2 class="w-4 h-4" />
            </button>
          </div>
          <button class="flex items-center gap-2 px-4 py-2 bg-white text-slate-700 text-xs font-black rounded-xl border border-slate-100 shadow-sm hover:bg-slate-50 transition-all">
            <Navigation class="w-3.5 h-3.5" /> LOKASI
          </button>
        </div>
      </div>
    </div>

    <!-- No Data State -->
    <div v-if="!isLoading && filteredStores.length === 0" class="flex flex-col items-center justify-center py-20 bg-white rounded-[40px] border-2 border-dashed border-slate-100">
      <div class="w-20 h-20 bg-slate-50 rounded-full flex items-center justify-center mb-6">
        <Store class="w-10 h-10 text-slate-300" />
      </div>
      <h3 class="text-xl font-black text-slate-900">Toko tidak ditemukan</h3>
      <p class="text-slate-500 font-medium mt-2">Coba sesuaikan kata kunci pencarian atau filter Anda.</p>
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
