<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
import apiClient from '@/api/axios'
import { toast } from 'vue-sonner'
import { 
  Plus, 
  MapPin, 
  Camera, 
  CheckCircle2, 
  Clock, 
  AlertCircle,
  Megaphone,
  MoreVertical,
  Calendar,
  Layers,
  ArrowUpRight,
  Maximize2,
  Pencil,
  Trash2,
  Save,
  X,
  User
} from 'lucide-vue-next'
import { Button } from '@/components/ui/button'
import { useMasterDataStore } from '@/stores/masterData'

const masterDataStore = useMasterDataStore()

const isLoading = ref(true)
const bannerCampaigns = ref<any[]>([])
const allEmployees = ref<any[]>([])
const showModal = ref(false)
const isEditing = ref(false)
const allStores = ref<any[]>([])
const currentBanner = ref({
  id: '',
  storeID: '',
  bannerType: 'Spanduk',
  employeeID: '',
  designerID: '',
  installerID: '',
  status: 'IN_DESIGN',
  designURL: '',
  documentationImageURL: '',
  notes: ''
})

const fetchStores = async () => {
  try {
    const res = await apiClient.get('/stores')
    if (res.data?.data) {
      allStores.value = res.data.data
    }
  } catch (error) {
    console.error('Failed to fetch stores:', error)
  }
}

const fetchEmployees = async () => {
  try {
    const res = await apiClient.get('/employees')
    if (res.data?.data) {
      allEmployees.value = res.data.data
    }
  } catch (error) {
    console.error('Failed to fetch employees:', error)
  }
}
const stats = ref({
  completed: 0,
  inProgress: 0,
  pending: 0
})

const fetchBanners = async () => {
  if (!masterDataStore.selectedBranchId) return
  isLoading.value = true
  try {
    const res = await apiClient.get(`/banner-orders?company_id=${masterDataStore.selectedBranchCompanyId || ''}`)
    if (res.data?.data) {
      const banners = res.data.data
      bannerCampaigns.value = banners.map((b: any) => ({
        id: b.id,
        title: b.campaign_name || 'Kampanye Spanduk',
        location: b.location || 'Lokasi',
        type: b.banner_type || 'Spanduk',
        status: b.status,
        date: formatDate(b.created_at),
        installer: b.installer ? `${b.installer.first_name} ${b.installer.last_name || ''}` : 'Belum Ditugaskan',
        designer: b.designer ? `${b.designer.first_name} ${b.designer.last_name || ''}` : 'Belum Ditugaskan',
        requester: b.employee ? `${b.employee.first_name} ${b.employee.last_name || ''}` : 'Sales',
        image: b.documentation_image_url,
        designURL: b.design_url,
        store_id: b.store_id,
        notes: b.notes,
        employee_id: b.employee_id,
        designer_id: b.designer_id,
        installer_id: b.installer_id
      }))

      stats.value = {
        completed: banners.filter((b: any) => b.status === 'TERPASANG').length,
        inProgress: banners.filter((b: any) => ['IN_DESIGN', 'ADMIN_REVIEW', 'PERCETAKAN'].includes(b.status)).length,
        pending: banners.filter((b: any) => b.status === 'PENDING').length
      }
    }
  } catch (error) {
    console.error('Failed to fetch banner orders:', error)
  } finally {
    isLoading.value = false
  }
}

const openAddModal = () => {
  isEditing.value = false
  currentBanner.value = {
    id: '',
    storeID: '',
    bannerType: 'Spanduk',
    employeeID: '',
    designerID: '',
    installerID: '',
    status: 'IN_DESIGN',
    designURL: '',
    documentationImageURL: '',
    notes: ''
  }
  showModal.value = true
}

const handleEdit = (banner: any) => {
  isEditing.value = true
  // Mapping back
  const raw = bannerCampaigns.value.find(b => b.id === banner.id)
  currentBanner.value = {
    id: banner.id,
    storeID: raw.store_id || '',
    bannerType: banner.type,
    employeeID: raw.employee_id || '',
    designerID: raw.designer_id || '',
    installerID: raw.installer_id || '',
    status: banner.status,
    designURL: raw.designURL || '',
    documentationImageURL: banner.image || '',
    notes: raw.notes || ''
  }
  showModal.value = true
}

const handleDelete = async (id: string) => {
  if (!confirm('Yakin ingin menghapus kampanye ini?')) return
  try {
    await apiClient.delete(`/banner-orders/${id}`)
    toast.success('Kampanye dihapus')
    fetchBanners()
  } catch (error) {
    console.error('Failed to delete banner:', error)
  }
}

const handleFileUpload = async (event: any) => {
  const file = event.target.files[0]
  if (!file) return

  const formData = new FormData()
  formData.append('file', file)

  try {
    const res = await apiClient.post('/admin/sales/upload', formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    })
    if (res.data?.url) {
      currentBanner.value.documentationImageURL = res.data.url
      toast.success('Foto dokumentasi berhasil diunggah')
    }
  } catch (error) {
    console.error('Upload failed:', error)
    toast.error('Gagal mengunggah foto')
  }
}

const handleSubmit = async () => {
  try {
    const companyId = masterDataStore.selectedBranchCompanyId
    if (!companyId || companyId === '') {
      toast.error('Silakan pilih cabang spesifik terlebih dahulu untuk mengelola spanduk')
      return
    }

    const selectedStore = allStores.value.find(s => s.id === currentBanner.value.storeID)
    const payload = {
      store_id: currentBanner.value.storeID || null,
      store_name: selectedStore?.name || 'Toko',
      location: selectedStore?.address || '',
      banner_type: currentBanner.value.bannerType,
      campaign_name: currentBanner.value.notes?.slice(0, 50) || 'Kampanye Spanduk',
      employee_id: currentBanner.value.employeeID || null,
      designer_id: currentBanner.value.designerID || null,
      installer_id: currentBanner.value.installerID || null,
      status: currentBanner.value.status,
      design_url: currentBanner.value.designURL,
      documentation_image_url: currentBanner.value.documentationImageURL,
      notes: currentBanner.value.notes,
      size: 1.0,
      company_id: companyId
    }

    if (isEditing.value) {
      await apiClient.put(`/banner-orders/${currentBanner.value.id}`, payload)
      toast.success('Kampanye diperbarui')
    } else {
      await apiClient.post('/banner-orders', payload)
      toast.success('Kampanye baru dibuat')
    }
    showModal.value = false
    fetchBanners()
  } catch (error) {
    console.error('Failed to save banner:', error)
  }
}

const updateStatus = async (id: string, newStatus: string) => {
  try {
    await apiClient.patch(`/banner-orders/${id}/status`, { status: newStatus })
    toast.success('Status spanduk diperbarui')
    fetchBanners()
  } catch (error) {
    toast.error('Gagal memperbarui status')
  }
}


const formatDate = (date: string) => {
  if (!date) return '-'
  return new Date(date).toLocaleDateString('id-ID', {
    day: 'numeric',
    month: 'long',
    year: 'numeric'
  })
}

onMounted(() => {
  fetchBanners()
  fetchEmployees()
  fetchStores()
})

watch(() => masterDataStore.selectedBranchId, () => {
  fetchBanners()
})

const getStatusStyle = (status: string) => {
  switch (status) {
    case 'TERPASANG': return 'bg-emerald-50 text-emerald-600 border-emerald-100'
    case 'PERCETAKAN': return 'bg-blue-50 text-blue-600 border-blue-100'
    case 'ADMIN_REVIEW': return 'bg-amber-50 text-amber-600 border-amber-100'
    case 'IN_DESIGN': return 'bg-purple-50 text-purple-600 border-purple-100'
    default: return 'bg-slate-50 text-slate-500 border-slate-100'
  }
}
</script>

<template>
  <div class="space-y-8 pb-10">
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-6">
      <div>
        <h1 class="text-3xl font-extrabold text-slate-900 tracking-tight">Pemasangan Spanduk</h1>
        <p class="text-[15px] font-medium text-slate-500 mt-1.5 flex items-center gap-2">
          <Megaphone class="w-4 h-4 text-primary" />
          Monitoring kampanye promosi fisik dan dokumentasi pemasangan.
        </p>
      </div>
      <Button @click="openAddModal" class="bg-primary hover:bg-primary/90 text-white px-6 py-6 rounded-2xl shadow-lg flex items-center gap-2 font-bold transition-all active:scale-95 shadow-primary/20">
        <Plus class="w-5 h-5" /> Order Pemasangan Baru
      </Button>
    </div>

    <!-- Stats Row -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <div class="bg-white p-6 rounded-3xl border border-slate-200 shadow-sm flex items-center gap-5">
        <div class="p-4 bg-emerald-50 rounded-2xl text-emerald-600">
          <CheckCircle2 class="w-7 h-7" />
        </div>
        <div>
          <p class="text-2xl font-black text-slate-900">{{ stats.completed }}</p>
          <p class="text-xs font-bold text-slate-400 uppercase tracking-widest">Selesai Terpasang</p>
        </div>
      </div>
      <div class="bg-white p-6 rounded-3xl border border-slate-200 shadow-sm flex items-center gap-5">
        <div class="p-4 bg-blue-50 rounded-2xl text-blue-600">
          <Clock class="w-7 h-7" />
        </div>
        <div>
          <p class="text-2xl font-black text-slate-900">{{ stats.inProgress }}</p>
          <p class="text-xs font-bold text-slate-400 uppercase tracking-widest">Dalam Pengerjaan</p>
        </div>
      </div>
      <div class="bg-white p-6 rounded-3xl border border-slate-200 shadow-sm flex items-center gap-5">
        <div class="p-4 bg-amber-50 rounded-2xl text-amber-600">
          <AlertCircle class="w-7 h-7" />
        </div>
        <div>
          <p class="text-2xl font-black text-slate-900">{{ stats.pending }}</p>
          <p class="text-xs font-bold text-slate-400 uppercase tracking-widest">Menunggu Antrian</p>
        </div>
      </div>
    </div>

    <!-- Grid of Campaigns -->
    <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-8">
      <div 
        v-for="campaign in bannerCampaigns" 
        :key="campaign.id"
        class="bg-white rounded-[32px] border border-slate-200 shadow-sm hover:shadow-xl transition-all duration-500 overflow-hidden group flex flex-col"
      >
        <!-- Card Header / Image -->
        <div class="relative h-56 overflow-hidden bg-slate-100 shrink-0">
          <img v-if="campaign.image" :src="campaign.image" class="w-full h-full object-cover transition-transform duration-700 group-hover:scale-110" />
          <div v-else class="w-full h-full flex flex-col items-center justify-center text-slate-300 gap-3">
            <Camera class="w-12 h-12 opacity-20" />
            <p class="text-xs font-bold uppercase tracking-widest opacity-40">Belum ada dokumentasi</p>
          </div>
          
          <div class="absolute top-4 left-4">
             <span :class="['px-4 py-1.5 rounded-xl text-[10px] font-black border backdrop-blur-md', getStatusStyle(campaign.status)]">
                {{ campaign.status.replace('_', ' ') }}
             </span>
          </div>
          
          <div v-if="campaign.image" class="absolute bottom-4 right-4 opacity-0 group-hover:opacity-100 transition-opacity">
            <button class="bg-white/90 backdrop-blur p-2.5 rounded-xl shadow-lg text-slate-900 hover:bg-white">
              <Maximize2 class="w-4 h-4" />
            </button>
          </div>
        </div>

        <!-- Card Body -->
        <div class="p-7 flex-1 flex flex-col">
          <div class="flex items-start justify-between mb-4">
            <div>
              <p class="text-[10px] font-black text-primary uppercase tracking-widest mb-1">{{ campaign.type }}</p>
              <h3 class="text-lg font-black text-slate-900 group-hover:text-primary transition-colors leading-tight">
                {{ campaign.title }}
              </h3>
            </div>
            <div class="flex gap-2">
              <a 
                v-if="campaign.designURL" 
                :href="campaign.designURL" 
                target="_blank"
                class="p-2 bg-purple-50 text-purple-600 rounded-xl hover:bg-purple-100 transition-colors"
                title="Lihat Desain (GDrive)"
              >
                <Layers class="w-4 h-4" />
              </a>
              <button 
                v-if="campaign.status === 'PENDING'"
                @click="updateStatus(campaign.id, 'IN_DESIGN')"
                class="p-2 bg-purple-50 text-purple-600 rounded-xl hover:bg-purple-100 transition-colors"
                title="Mulai Desain"
              >
                <Pencil class="w-4 h-4" />
              </button>
              <button 
                v-if="campaign.status === 'IN_DESIGN'"
                @click="updateStatus(campaign.id, 'ADMIN_REVIEW')"
                class="p-2 bg-amber-50 text-amber-600 rounded-xl hover:bg-amber-100 transition-colors"
                title="Kirim ke Review"
              >
                <Clock class="w-4 h-4" />
              </button>
              <button 
                v-if="campaign.status === 'ADMIN_REVIEW'"
                @click="updateStatus(campaign.id, 'PERCETAKAN')"
                class="p-2 bg-blue-50 text-blue-600 rounded-xl hover:bg-blue-100 transition-colors"
                title="Kirim ke Percetakan"
              >
                <Layers class="w-4 h-4" />
              </button>
              <button 
                v-if="campaign.status === 'PERCETAKAN'"
                @click="updateStatus(campaign.id, 'TERPASANG')"
                class="p-2 bg-emerald-50 text-emerald-600 rounded-xl hover:bg-emerald-100 transition-colors"
                title="Selesai Terpasang"
              >
                <CheckCircle2 class="w-4 h-4" />
              </button>
            </div>
          </div>

          <div class="space-y-4 mt-auto">
            <div class="flex items-center gap-3 text-[13px] font-bold text-slate-500">
              <MapPin class="w-4 h-4 text-slate-400 shrink-0" />
              <span class="truncate">{{ campaign.location }}</span>
            </div>
            
            <div class="flex flex-col gap-1.5 pt-5 border-t border-slate-100">
              <div class="flex items-center gap-1.5 text-[11px] font-bold text-slate-500">
                <User class="w-3 h-3" /> Requester: {{ campaign.requester }}
              </div>
              <div class="flex items-center gap-1.5 text-[11px] font-bold text-purple-600">
                <Pencil class="w-3 h-3" /> Desain: {{ campaign.designer }}
              </div>
              <div class="flex items-center gap-1.5 text-[11px] font-bold text-emerald-600">
                <CheckCircle2 class="w-3 h-3" /> Pasang: {{ campaign.installer }}
              </div>
            </div>
          </div>
        </div>

        <!-- Card Footer -->
        <div class="px-7 py-5 bg-slate-50/50 border-t border-slate-100 flex items-center justify-between">
          <div class="flex gap-2">
            <button @click="handleEdit(campaign)" class="p-2.5 bg-white text-slate-400 hover:text-primary hover:bg-white rounded-xl transition-all shadow-sm border border-slate-100">
              <Pencil class="w-4 h-4" />
            </button>
            <button @click="handleDelete(campaign.id)" class="p-2.5 bg-white text-slate-400 hover:text-red-500 hover:bg-white rounded-xl transition-all shadow-sm border border-slate-100">
              <Trash2 class="w-4 h-4" />
            </button>
          </div>
          <button class="text-xs font-black text-primary flex items-center gap-1.5 hover:underline">
            DETAIL <ArrowUpRight class="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>

    <!-- CRUD Modal -->
    <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="absolute inset-0 bg-slate-900/60 backdrop-blur-sm" @click="showModal = false"></div>
      <div class="bg-white rounded-[32px] w-full max-w-xl relative z-10 shadow-2xl flex flex-col max-h-[90vh] overflow-hidden animate-in fade-in zoom-in duration-300">
        <!-- Header -->
        <div class="px-6 py-5 border-b border-slate-100 flex items-center justify-between bg-white shrink-0">
          <div>
            <h3 class="text-xl font-black text-slate-900 tracking-tight">{{ isEditing ? 'Edit Kampanye' : 'Kampanye Baru' }}</h3>
            <p class="text-[10px] font-black text-slate-400 uppercase tracking-widest mt-0.5">Materi Promosi</p>
          </div>
          <button @click="showModal = false" class="p-2 hover:bg-slate-100 rounded-xl transition-all text-slate-400 hover:text-slate-900">
            <X class="w-5 h-5" />
          </button>
        </div>
        
        <!-- Body (Scrollable) -->
        <div class="p-6 overflow-y-auto space-y-5 custom-scrollbar">
          <div class="space-y-2">
            <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Pilih Toko</label>
            <select v-model="currentBanner.storeID" class="w-full bg-slate-50 border-2 border-transparent rounded-2xl px-5 py-3.5 font-bold text-slate-900 focus:bg-white focus:border-primary/20 focus:ring-0 transition-all appearance-none">
              <option value="" disabled>Pilih Toko Terdaftar</option>
              <option v-for="s in allStores" :key="s.id" :value="s.id">{{ s.name }} - {{ s.address }}</option>
            </select>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div class="space-y-2">
              <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Tipe Media</label>
              <select v-model="currentBanner.bannerType" class="w-full bg-slate-50 border-2 border-transparent rounded-2xl px-5 py-3.5 font-bold text-slate-900 focus:bg-white focus:border-primary/20 focus:ring-0 transition-all appearance-none">
                <option value="Spanduk">Spanduk</option>
                <option value="Baliho">Baliho</option>
                <option value="Poster">Poster</option>
                <option value="Neon Box">Neon Box</option>
              </select>
            </div>
            <div class="space-y-2">
              <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Status</label>
              <select v-model="currentBanner.status" class="w-full bg-slate-50 border-2 border-transparent rounded-2xl px-5 py-3.5 font-bold text-slate-900 focus:bg-white focus:border-primary/20 focus:ring-0 transition-all appearance-none">
                <option value="IN_DESIGN">In Design</option>
                <option value="ADMIN_REVIEW">Admin Review</option>
                <option value="PERCETAKAN">Percetakan</option>
                <option value="TERPASANG">Terpasang</option>
              </select>
            </div>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div class="space-y-2">
              <label class="text-[11px] font-black text-slate-400 uppercase tracking-widest">Petugas Desain</label>
              <select v-model="currentBanner.designerID" class="w-full bg-slate-50 border-none rounded-2xl px-5 py-4 font-bold text-slate-900 focus:ring-2 focus:ring-primary/20 transition-all appearance-none">
                <option value="" disabled>Pilih Designer</option>
                <option v-for="e in allEmployees" :key="e.id" :value="e.id">{{ e.first_name }} {{ e.last_name }}</option>
              </select>
            </div>
            <div class="space-y-2">
              <label class="text-[11px] font-black text-slate-400 uppercase tracking-widest">Petugas Pasang</label>
              <select v-model="currentBanner.installerID" class="w-full bg-slate-50 border-none rounded-2xl px-5 py-4 font-bold text-slate-900 focus:ring-2 focus:ring-primary/20 transition-all appearance-none">
                <option value="" disabled>Pilih Petugas Pasang</option>
                <option v-for="e in allEmployees" :key="e.id" :value="e.id">{{ e.first_name }} {{ e.last_name }}</option>
              </select>
            </div>
          </div>

          <div class="space-y-2">
            <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Link Desain (Google Drive)</label>
            <input v-model="currentBanner.designURL" type="url" placeholder="https://drive.google.com/..." class="w-full bg-slate-50 border-2 border-transparent rounded-2xl px-5 py-3.5 font-bold text-slate-900 focus:bg-white focus:border-primary/20 focus:ring-0 transition-all" />
          </div>

          <div class="space-y-2">
            <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Upload Foto Pemasangan</label>
            <div class="flex items-center gap-4">
              <input type="file" @change="handleFileUpload" accept="image/*" class="hidden" id="banner-upload" />
              <label for="banner-upload" class="flex-1 flex items-center justify-center gap-2 bg-slate-50 border-2 border-dashed border-slate-200 rounded-2xl py-4 cursor-pointer hover:border-primary/40 hover:bg-slate-100/50 transition-all">
                <Camera class="w-5 h-5 text-slate-400" />
                <span class="text-xs font-bold text-slate-500">{{ currentBanner.documentationImageURL ? 'Ganti Foto' : 'Pilih File Foto' }}</span>
              </label>
              <div v-if="currentBanner.documentationImageURL" class="w-12 h-12 rounded-xl overflow-hidden border border-slate-100 shadow-sm">
                <img :src="currentBanner.documentationImageURL" class="w-full h-full object-cover" />
              </div>
            </div>
          </div>

          <div class="space-y-2">
            <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Konten Isi Spanduk / Catatan</label>
            <textarea v-model="currentBanner.notes" placeholder="Tuliskan detail konten atau pesan spanduk..." class="w-full bg-slate-50 border-2 border-transparent rounded-2xl px-5 py-3.5 font-bold text-slate-900 focus:bg-white focus:border-primary/20 focus:ring-0 transition-all h-24 resize-none"></textarea>
          </div>
        </div>

        <!-- Footer -->
        <div class="p-6 border-t border-slate-100 flex gap-4 bg-white shrink-0">
          <button @click="showModal = false" class="flex-1 py-3.5 text-xs font-black text-slate-400 hover:text-slate-900 transition-all uppercase tracking-widest">
            BATAL
          </button>
          <button 
            @click="handleSubmit"
            class="flex-[2] bg-primary text-white rounded-2xl py-3.5 text-xs font-black shadow-lg shadow-primary/20 hover:scale-[1.02] active:scale-[0.98] transition-all flex items-center justify-center gap-2 uppercase tracking-widest"
          >
            <Save class="w-4 h-4" /> SIMPAN KAMPANYE
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
