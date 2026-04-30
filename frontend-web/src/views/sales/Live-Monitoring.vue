<script setup lang="ts">
import { ref, shallowRef, onMounted, onUnmounted, markRaw, toRaw } from 'vue'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import 'leaflet-defaulticon-compatibility'
import 'leaflet-defaulticon-compatibility/dist/leaflet-defaulticon-compatibility.css'
import apiClient from '@/api/axios'
import { 
  Users, 
  MapPin, 
  Clock, 
  Navigation, 
  UserCheck, 
  UserMinus,
  RefreshCcw,
  Banknote,
  FileText,
  CheckCircle2,
  X,
  ZoomIn,
  ZoomOut,
  RotateCcw,
  ImageIcon
} from 'lucide-vue-next'

const map = shallowRef<any>(null)
const markers = shallowRef<any[]>([])
const attendanceData = ref<any[]>([])
const isLoading = ref(true)
const lastUpdated = ref(new Date().toLocaleTimeString())

// Image Preview State
const showImageModal = ref(false)
const previewImageUrl = ref('')
const zoomLevel = ref(1)

const openImagePreview = (url: string) => {
  previewImageUrl.value = url
  zoomLevel.value = 1
  showImageModal.value = true
}

const handleZoom = (val: number) => {
  zoomLevel.value = Math.max(0.5, Math.min(3, zoomLevel.value + val))
}

// Global function for popup clicks (needed because Leaflet popups are raw HTML)
;(window as any).previewReceipt = (url: string) => {
  openImagePreview(url)
}

const initMap = () => {
  if (map.value) return
  
  // Default view to Indonesia coordinates
  const mapInstance = L.map('monitoring-map').setView([-6.2088, 106.8456], 12)
  map.value = markRaw(mapInstance)
  
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '&copy; OpenStreetMap contributors'
  }).addTo(toRaw(map.value) as any)
}

const fetchAttendance = async () => {
  isLoading.value = true
  try {
    const res = await apiClient.get('/attendance/all?limit=100')
    if (res.data?.data) {
      // Filter for today's data, only those with coordinates, AND only Sales-related employees
      const today = new Date().toISOString().split('T')[0]
      const salesKeywords = ['sales', 'motoris', 'booster', 'task order']
      
      attendanceData.value = res.data.data.filter((item: any) => {
        const itemDate = new Date(item.clock_in_time).toISOString().split('T')[0]
        const hasCoords = (item.clock_in_lat && item.clock_in_long) || (item.clock_out_lat && item.clock_out_long)
        const jobTitle = (item.employee?.job_position?.title || '').toLowerCase()
        const isSales = salesKeywords.some(keyword => jobTitle.includes(keyword))
        
        return itemDate === today && hasCoords && isSales
      })
      
      updateMarkers()
    }
  } catch (error) {
    console.error('Failed to fetch attendance data:', error)
  } finally {
    isLoading.value = false
    lastUpdated.value = new Date().toLocaleTimeString()
  }
}

const getSalesTypeInfo = (title: string) => {
  const t = title.toLowerCase()
  if (t.includes('motoris')) return { label: 'Motoris', color: '#3b82f6', icon: 'Motorcycle' }
  if (t.includes('task order') || t.includes('to')) return { label: 'Task Order', color: '#f59e0b', icon: 'Clipboard' }
  if (t.includes('booster')) return { label: 'Booster', color: '#8b5cf6', icon: 'Zap' }
  return { label: 'General Sales', color: '#6366f1', icon: 'User' }
}

const updateMarkers = () => {
  if (!map.value) return

  // Clear existing markers
  markers.value.forEach(marker => marker.remove())
  markers.value = []

  attendanceData.value.forEach(item => {
    const lat = item.clock_out_lat || item.clock_in_lat
    const lng = item.clock_out_long || item.clock_in_long
    const name = item.employee?.first_name || 'Unknown'
    const jobTitle = item.employee?.job_position?.title || 'Sales'
    const salesInfo = getSalesTypeInfo(jobTitle)
    
    if (lat && lng) {
      // Create custom div icon
      const customIcon = L.divIcon({
        className: 'custom-sales-marker',
        html: `
          <div class="relative flex items-center justify-center w-10 h-10">
            <div class="absolute w-full h-full rounded-full opacity-20 animate-ping" style="background-color: ${salesInfo.color}"></div>
            <div class="relative w-8 h-8 rounded-full border-2 border-white shadow-lg flex items-center justify-center text-white font-black text-[10px]" style="background-color: ${salesInfo.color}">
              ${name.charAt(0)}
            </div>
          </div>
        `,
        iconSize: [40, 40],
        iconAnchor: [20, 20],
        popupAnchor: [0, -20]
      })

      // Generate Transactions HTML (re-using previous logic)
      const transactions = item.sales_transactions || []
      let trxsHtml = ''
      
      if (transactions.length > 0) {
        trxsHtml = `
          <div class="mt-3 pt-3 border-t border-slate-100">
            <p class="text-[9px] font-black text-slate-400 uppercase tracking-widest mb-2 flex items-center gap-1">
              Transaksi Terdeteksi
            </p>
            ${transactions.map((t: any) => `
              <div class="bg-slate-50 rounded-xl p-2.5 mb-2 border border-slate-100">
                <div class="flex justify-between items-center mb-1">
                  <span class="text-[11px] font-black text-slate-900">${t.store?.name || 'Toko'}</span>
                  <span class="text-[10px] font-black text-emerald-600">Rp ${new Intl.NumberFormat('id-ID').format(t.total_amount)}</span>
                </div>
                ${t.receipt_image_url ? `
                  <button onclick="window.previewReceipt('${t.receipt_image_url}')" class="w-full mt-1 bg-white border border-slate-200 rounded-lg py-1.5 text-[9px] font-bold text-slate-600 hover:bg-slate-50 transition-all flex items-center justify-center gap-1">
                    Lihat Nota
                  </button>
                ` : ''}
              </div>
            `).join('')}
          </div>
        `
      } else if (item.notes) {
        trxsHtml = `
          <div class="mt-3 pt-3 border-t border-slate-100">
            <p class="text-[9px] font-black text-slate-400 uppercase tracking-widest mb-1 flex items-center gap-1">
              Catatan Kunjungan
            </p>
            <p class="text-[10px] font-medium text-slate-600 leading-relaxed italic">"${item.notes}"</p>
          </div>
        `
      }

      const marker = L.marker([lat, lng], { icon: customIcon })
        .addTo(toRaw(map.value) as any)
        .bindPopup(`
          <div class="w-64 font-sans p-1">
            <div class="flex items-center gap-3 mb-3">
              <div class="w-10 h-10 rounded-xl flex items-center justify-center font-black text-white shadow-sm" style="background-color: ${salesInfo.color}">
                ${name.charAt(0)}
              </div>
              <div class="min-w-0">
                <p class="font-black text-slate-900 text-sm truncate leading-tight">${name}</p>
                <div class="flex items-center gap-1.5 mt-0.5">
                  <span class="px-1.5 py-0.5 rounded-md text-[8px] font-black text-white uppercase tracking-tighter" style="background-color: ${salesInfo.color}">${salesInfo.label}</span>
                  <p class="text-[9px] font-bold text-slate-400 truncate">${jobTitle}</p>
                </div>
              </div>
            </div>
            
            <div class="grid grid-cols-2 gap-2 mb-3">
              <div class="bg-slate-50 rounded-xl p-2 border border-slate-100">
                <p class="text-[8px] font-black text-slate-400 uppercase tracking-tighter">Check In</p>
                <p class="text-[11px] font-black text-slate-900">${new Date(item.clock_in_time).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</p>
              </div>
              <div class="bg-slate-50 rounded-xl p-2 border border-slate-100">
                <p class="text-[8px] font-black text-slate-400 uppercase tracking-tighter">Status</p>
                <p class="text-[10px] font-black ${item.clock_out_time ? 'text-red-500' : 'text-emerald-500'} uppercase">${item.clock_out_time ? 'Out' : 'Active'}</p>
              </div>
            </div>

            ${trxsHtml}
          </div>
        `, {
          maxWidth: 300,
          className: 'custom-monitoring-popup'
        })
      
      markers.value.push(markRaw(marker))
    }
  })

  // Fit bounds if there are markers
  if (markers.value.length > 0) {
    const group = L.featureGroup(toRaw(markers.value) as any)
    map.value.fitBounds(group.getBounds().pad(0.1))
  }
}

let refreshInterval: any = null

onMounted(() => {
  initMap()
  fetchAttendance()
  
  // Auto refresh every 30 seconds
  refreshInterval = setInterval(fetchAttendance, 30000)
})

onUnmounted(() => {
  if (refreshInterval) clearInterval(refreshInterval)
  if (map.value) {
    map.value.remove()
    map.value = null
  }
})

const panToMarker = (lat: number, lng: number) => {
  if (map.value) {
    map.value.flyTo([lat, lng], 16)
  }
}
</script>

<template>
  <div class="h-[calc(100vh-120px)] flex flex-col gap-6">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-6 shrink-0">
      <div>
        <h1 class="text-3xl font-extrabold text-slate-900 tracking-tight flex items-center gap-3">
          <Navigation class="w-8 h-8 text-primary" />
          Live Monitoring
        </h1>
        <p class="text-[15px] font-medium text-slate-500 mt-1.5 flex items-center gap-2">
          <RefreshCcw class="w-4 h-4 text-emerald-500" :class="{ 'animate-spin': isLoading }" />
          Pantau lokasi tim sales secara real-time. Terakhir diperbarui: {{ lastUpdated }}
        </p>
      </div>
      <div class="flex items-center gap-3">
        <button @click="fetchAttendance" class="bg-white border border-slate-200 px-5 py-2.5 rounded-2xl text-sm font-bold text-slate-700 hover:bg-slate-50 transition-all shadow-sm flex items-center gap-2">
          <RefreshCcw class="w-4 h-4" /> Refresh Data
        </button>
      </div>
    </div>

    <!-- Main Content -->
    <div class="flex-1 flex flex-col lg:flex-row gap-6 min-h-0">
      <!-- Left: Sidebar List -->
      <div class="lg:w-80 bg-white rounded-3xl border border-slate-200 shadow-sm flex flex-col overflow-hidden shrink-0">
        <div class="p-6 border-b border-slate-100 bg-slate-50/50">
          <h3 class="font-extrabold text-slate-900 flex items-center gap-2">
            <Users class="w-5 h-5 text-slate-400" />
            Tim Aktif ({{ attendanceData.length }})
          </h3>
        </div>
        
        <div class="flex-1 overflow-y-auto p-4 space-y-3 no-scrollbar">
          <div v-if="attendanceData.length === 0" class="py-20 text-center px-6">
            <MapPin class="w-12 h-12 mx-auto mb-4 text-slate-200" />
            <p class="text-sm font-bold text-slate-400">Tidak ada data lokasi aktif hari ini.</p>
          </div>
          
          <div 
            v-for="item in attendanceData" 
            :key="item.id"
            @click="panToMarker(item.clock_out_lat || item.clock_in_lat, item.clock_out_long || item.clock_in_long)"
            class="p-4 rounded-2xl border border-slate-100 hover:border-primary/30 hover:bg-primary/[0.02] transition-all cursor-pointer group"
          >
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-xl bg-slate-100 flex items-center justify-center font-black text-slate-500 group-hover:bg-primary/10 group-hover:text-primary transition-colors">
                {{ item.employee?.first_name?.charAt(0) }}
              </div>
              <div class="flex-1 min-w-0">
                <p class="font-bold text-slate-900 truncate">{{ item.employee?.first_name }}</p>
                <p class="text-[10px] font-black uppercase tracking-widest" :class="item.clock_out_time ? 'text-red-500' : 'text-emerald-500'">
                  {{ item.clock_out_time ? 'OUT' : 'IN' }} • {{ new Date(item.clock_out_time || item.clock_in_time).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) }}
                </p>
              </div>
              <button class="opacity-0 group-hover:opacity-100 p-2 text-primary">
                <Maximize2 class="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Right: Map -->
      <div class="flex-1 bg-white rounded-3xl border border-slate-200 shadow-sm overflow-hidden relative">
        <div id="monitoring-map" class="w-full h-full z-10"></div>
        
        <!-- Legend Overlay -->
        <div class="absolute bottom-6 left-6 z-20 bg-white/90 backdrop-blur-md p-5 rounded-3xl border border-slate-200 shadow-xl flex flex-col gap-4 min-w-[180px]">
          <p class="text-[10px] font-black text-slate-400 uppercase tracking-[0.2em] mb-1">Kategori Sales</p>
          <div class="flex items-center gap-3">
            <span class="w-4 h-4 rounded-full bg-blue-500 border-2 border-white shadow-sm"></span>
            <span class="text-xs font-black text-slate-700">Sales Motoris</span>
          </div>
          <div class="flex items-center gap-3">
            <span class="w-4 h-4 rounded-full bg-amber-500 border-2 border-white shadow-sm"></span>
            <span class="text-xs font-black text-slate-700">Task Order (TO)</span>
          </div>
          <div class="flex items-center gap-3">
            <span class="w-4 h-4 rounded-full bg-purple-500 border-2 border-white shadow-sm"></span>
            <span class="text-xs font-black text-slate-700">Sales Booster</span>
          </div>
          <div class="mt-2 pt-2 border-t border-slate-100">
             <div class="flex items-center gap-2">
                <div class="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></div>
                <span class="text-[10px] font-black text-emerald-600 uppercase">Live Tracking Active</span>
             </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Image Preview Modal -->
    <div v-if="showImageModal" class="fixed inset-0 z-[100] flex items-center justify-center p-4">
      <div class="absolute inset-0 bg-slate-900/90 backdrop-blur-md" @click="showImageModal = false"></div>
      
      <!-- Controls -->
      <div class="absolute top-6 right-6 flex items-center gap-3 z-[110]">
        <button @click="handleZoom(0.2)" class="p-3 bg-white/10 hover:bg-white/20 text-white rounded-2xl backdrop-blur-xl border border-white/10 transition-all">
          <ZoomIn class="w-6 h-6" />
        </button>
        <button @click="handleZoom(-0.2)" class="p-3 bg-white/10 hover:bg-white/20 text-white rounded-2xl backdrop-blur-xl border border-white/10 transition-all">
          <ZoomOut class="w-6 h-6" />
        </button>
        <button @click="zoomLevel = 1" class="p-3 bg-white/10 hover:bg-white/20 text-white rounded-2xl backdrop-blur-xl border border-white/10 transition-all">
          <RotateCcw class="w-6 h-6" />
        </button>
        <div class="w-px h-8 bg-white/10 mx-2"></div>
        <button @click="showImageModal = false" class="p-3 bg-white hover:bg-slate-100 text-slate-900 rounded-2xl transition-all">
          <X class="w-6 h-6" />
        </button>
      </div>

      <div class="relative z-[105] max-w-5xl max-h-[85vh] transition-transform duration-300 ease-out flex items-center justify-center overflow-hidden rounded-3xl shadow-2xl">
        <img 
          :src="previewImageUrl" 
          :style="`transform: scale(${zoomLevel})`"
          class="max-w-full max-h-full object-contain transition-transform duration-200 cursor-grab active:cursor-grabbing" 
        />
      </div>
    </div>
  </div>
</template>

<style scoped>
#monitoring-map {
  background: #f8fafc;
}

/* Custom Leaflet Popup Styling */
:deep(.leaflet-popup-content-wrapper) {
  border-radius: 16px;
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
  border: 1px solid #f1f5f9;
}

:deep(.leaflet-popup-tip) {
  box-shadow: none;
}

.no-scrollbar::-webkit-scrollbar {
  display: none;
}
.no-scrollbar {
  -ms-overflow-style: none;
  scrollbar-width: none;
}
</style>
