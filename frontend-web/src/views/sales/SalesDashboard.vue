<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
import apiClient from '@/api/axios'
import { use } from 'echarts/core'
import { CanvasRenderer } from 'echarts/renderers'
import { LineChart, BarChart, PieChart } from 'echarts/charts'
import { GridComponent, TooltipComponent, LegendComponent, TitleComponent } from 'echarts/components'
import VChart from 'vue-echarts'
import { 
  Users, 
  TrendingUp, 
  Banknote, 
  Megaphone,
  ArrowRight,
  Target,
  Award,
  CheckCircle2,
  MapPin,
  Maximize2
} from 'lucide-vue-next'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import 'leaflet-defaulticon-compatibility'
import 'leaflet-defaulticon-compatibility/dist/leaflet-defaulticon-compatibility.css'
import { useMasterDataStore } from '@/stores/masterData'

const masterDataStore = useMasterDataStore()

use([CanvasRenderer, LineChart, BarChart, PieChart, GridComponent, TooltipComponent, LegendComponent, TitleComponent])

const isLoading = ref(true)
const mapContainer = ref<HTMLElement | null>(null)
let map: L.Map | null = null
const stores = ref<any[]>([])
const products = ref<any[]>([])
const mapMode = ref<'STORES' | 'PRODUCTS'>('STORES')
const selectedProductId = ref('')
const productSalesData = ref<any[]>([])
const isMapLoading = ref(false)

// --- Chart Options ---
const omzetChartOption = ref({
  tooltip: { trigger: 'axis', backgroundColor: '#fff', shadowBlur: 10, shadowColor: 'rgba(0,0,0,0.05)', textStyle: { color: '#1e293b' } },
  legend: { bottom: 0, icon: 'circle', textStyle: { fontWeight: '600' } },
  grid: { left: '3%', right: '4%', bottom: '15%', top: '5%', containLabel: true },
  xAxis: { 
    type: 'category', 
    data: [], 
    axisLine: { lineStyle: { color: '#e2e8f0' } },
    axisLabel: { fontSize: 10, fontWeight: '700', color: '#64748b' }
  },
  yAxis: { type: 'value', splitLine: { lineStyle: { color: '#f1f5f9' } } },
  series: [
    { 
      name: 'Target', type: 'bar', data: [], 
      itemStyle: { color: '#e2e8f0', borderRadius: [4, 4, 0, 0] }, barMaxWidth: 20 
    },
    { 
      name: 'Aktual', type: 'bar', data: [], 
      itemStyle: { color: '#990000', borderRadius: [4, 4, 0, 0] }, barMaxWidth: 20 
    }
  ]
})

const spandukChartOption = ref({
  tooltip: { trigger: 'item' },
  series: [
    {
      name: 'Progress Pemasangan',
      type: 'pie',
      radius: ['60%', '85%'],
      avoidLabelOverlap: false,
      itemStyle: { borderRadius: 10, borderColor: '#fff', borderWidth: 2 },
      label: { show: false },
      data: [
        { value: 45, name: 'Selesai', itemStyle: { color: '#10b981' } },
        { value: 20, name: 'Proses', itemStyle: { color: '#3b82f6' } },
        { value: 15, name: 'Pending', itemStyle: { color: '#f59e0b' } }
      ]
    }
  ]
})

const kpiSummary = ref({
  totalOmzetLama: 0,
  totalOmzetBaru: 0,
  totalOmzetAll: 0,
  totalTokoBaru: 0,
})

const spandukStats = ref({ completed: 0, inProgress: 0, pending: 0, total: 1 })
const totalSalesmen = ref(0)
const pendingNotesCount = ref(0)
const topSalesman = ref<any[]>([])
const recentNotas = ref<any[]>([])

const fetchDashboardData = async () => {
  if (!masterDataStore.selectedBranchId) return
  isLoading.value = true
  const now = new Date()
  const month = now.getMonth() + 1
  const year = now.getFullYear()
  const companyId = masterDataStore.selectedBranchCompanyId || ''

  try {
    // 1. Fetch Summary
    const summaryRes = await apiClient.get(`/admin/sales/reports/summary?month=${month}&year=${year}&company_id=${companyId}`)
    if (summaryRes.data?.data) {
      const data = summaryRes.data.data
      kpiSummary.value = {
        totalOmzetLama: data.total_omzet_lama || 0,
        totalOmzetBaru: data.total_omzet_baru || 0,
        totalOmzetAll: data.total_omzet_all || 0,
        totalTokoBaru: data.total_toko_baru || 0,
      }
    }

    // 2. Fetch Performance for Ranking
    const perfRes = await apiClient.get(`/admin/sales/reports/performance?month=${month}&year=${year}&company_id=${companyId}`)
    if (perfRes.data?.data) {
      topSalesman.value = perfRes.data.data
        .map((kpi: any) => ({
          id: kpi.ID,
          name: kpi.Employee ? `${kpi.Employee.first_name} ${kpi.Employee.last_name}` : 'Salesman',
          omzet: kpi.AchievedOmzet,
          achievement: Math.round((kpi.AchievedOmzet / (kpi.TargetOmzet || 1)) * 100),
          rank: 0
        }))
        .sort((a: any, b: any) => b.omzet - a.omzet)
        .slice(0, 3)
        .map((item: any, index: number) => ({ ...item, rank: index + 1 }))

      if (omzetChartOption.value.xAxis && !Array.isArray(omzetChartOption.value.xAxis) && omzetChartOption.value.series) {
        omzetChartOption.value.xAxis.data = perfRes.data.data.map((k: any) => k.Employee?.first_name || 'Sales')
        if (omzetChartOption.value.series[0]) omzetChartOption.value.series[0].data = perfRes.data.data.map((k: any) => k.TargetOmzet)
        if (omzetChartOption.value.series[1]) omzetChartOption.value.series[1].data = perfRes.data.data.map((k: any) => k.AchievedOmzet)
      }
    }

    // 2.1 Fetch All Employees for specific company
    const empRes = await apiClient.get(`/employees?limit=1000&company_id=${companyId}`)
    if (empRes.data?.data) {
      const allEmps = empRes.data.data
      const salesmenEmps = allEmps.filter((emp: any) => {
        const jobTitle = (emp.job_position?.title || '').toLowerCase()
        return jobTitle.includes('sales') || jobTitle.includes('marketing')
      })
      totalSalesmen.value = salesmenEmps.length
    }

    // 3. Fetch Pending Notas
    const pendingRes = await apiClient.get(`/admin/sales/transactions/all-pending?company_id=${companyId}`)
    if (pendingRes.data?.data) {
      pendingNotesCount.value = pendingRes.data.data.length
      recentNotas.value = pendingRes.data.data.slice(0, 3).map((n: any) => ({
        id: n.receipt_no || n.id.slice(0, 8),
        store: n.store?.name || 'Toko',
        amount: n.total_amount,
        status: n.status === 'VERIFIED' ? 'APPROVED' : n.status,
        time: new Date(n.created_at).toLocaleTimeString()
      }))
    }

    // 4. Fetch Banner Stats
    const bannerRes = await apiClient.get(`/banner-orders?company_id=${companyId}`)
    if (bannerRes.data?.data) {
      const banners = bannerRes.data.data
      const completed = banners.filter((b: any) => b.status === 'TERPASANG').length
      const inProgress = banners.filter((b: any) => ['IN_DESIGN', 'ADMIN_REVIEW', 'PERCETAKAN'].includes(b.status)).length
      const pending = banners.filter((b: any) => b.status === 'PENDING').length
      const total = banners.length || 1

      spandukStats.value = { completed, inProgress, pending, total }
      if (spandukChartOption.value.series && spandukChartOption.value.series[0]) {
        spandukChartOption.value.series[0].data = [
          { value: completed, name: 'Selesai', itemStyle: { color: '#10b981' } },
          { value: inProgress, name: 'Proses', itemStyle: { color: '#3b82f6' } },
          { value: pending, name: 'Pending', itemStyle: { color: '#f59e0b' } }
        ]
      }
    }

    // 5. Fetch Stores for Map
    const storeRes = await apiClient.get(`/stores?company_id=${companyId}`)
    if (storeRes.data?.data) {
      stores.value = storeRes.data.data
      if (mapMode.value === 'STORES') updateMarkers()
    }

    // 6. Fetch Products for tracking
    const prodRes = await apiClient.get(`/factory/products?company_id=${companyId}`)
    if (prodRes.data) {
      // Handle both { data: [] } and direct [] responses
      products.value = Array.isArray(prodRes.data) ? prodRes.data : (prodRes.data.data || [])
    }
  } catch (error) {
    console.error('Failed to fetch dashboard data:', error)
  } finally {
    isLoading.value = false
  }
}

const fetchProductDistribution = async () => {
  if (!selectedProductId.value) return
  isMapLoading.value = true
  try {
    const companyId = masterDataStore.selectedBranchCompanyId || ''
    const res = await apiClient.get(`/admin/sales/reports/product-distribution?product_id=${selectedProductId.value}&company_id=${companyId}`)
    if (res.data?.data) {
      productSalesData.value = res.data.data
      updateMarkers()
    }
  } catch (error) {
    console.error('Failed to fetch product distribution:', error)
  } finally {
    isMapLoading.value = false
  }
}

const getEmployeeColor = (id: string | null | undefined) => {
  if (!id) return '#94a3b8' // Default slate-400
  let hash = 0
  for (let i = 0; i < id.length; i++) {
    hash = id.charCodeAt(i) + ((hash << 5) - hash)
  }
  const c = (hash & 0x00FFFFFF).toString(16).toUpperCase()
  return '#' + '000000'.substring(0, 6 - c.length) + c
}

let markerGroup: L.LayerGroup | null = null

const updateMarkers = () => {
  if (!mapContainer.value) return
  
  if (!map) {
    const center: L.LatLngExpression = stores.value.length > 0 
      ? [stores.value[0].latitude, stores.value[0].longitude]
      : [-6.2088, 106.8456]
    map = L.map(mapContainer.value).setView(center, 12)
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '© OpenStreetMap contributors'
    }).addTo(map)
    markerGroup = L.layerGroup().addTo(map)
  }

  if (markerGroup) {
    markerGroup.clearLayers()
  }

  if (mapMode.value === 'STORES') {
    const validStores = stores.value.filter(s => s.latitude && s.longitude)
    validStores.forEach(store => {
      const salesmanColor = getEmployeeColor(store.assigned_employee_id)
      
      const icon = L.divIcon({
        html: `
          <div class="relative group">
            <div class="w-4 h-4 rounded-full border-2 border-white shadow-md transition-all group-hover:scale-150" 
                 style="background-color: ${salesmanColor};"></div>
            <div class="absolute hidden group-hover:block left-6 top-0 bg-white border border-slate-200 rounded-lg p-2 shadow-xl z-[1000] whitespace-nowrap">
              <p class="text-[9px] font-black text-slate-900">${store.name}</p>
              <p class="text-[8px] font-bold text-slate-400 mt-0.5 uppercase">${store.assigned_employee?.first_name || 'Unassigned'}</p>
            </div>
          </div>
        `,
        className: 'custom-store-marker',
        iconSize: [16, 16],
        iconAnchor: [8, 8]
      })

      const marker = L.marker([store.latitude, store.longitude], { icon })
      marker.bindPopup(`
        <div class="p-3 min-w-[200px] font-sans">
          <div class="flex items-center gap-2 mb-2 pb-2 border-b border-slate-100">
             <div class="w-3 h-3 rounded-full" style="background-color: ${salesmanColor};"></div>
             <h4 class="font-black text-slate-900 leading-tight">${store.name}</h4>
          </div>
          <div class="space-y-1.5">
            <div class="flex justify-between items-center text-[10px]">
               <span class="font-bold text-slate-400 uppercase">Salesman</span>
               <span class="font-black text-primary">${store.assigned_employee?.first_name || 'Belum Ditugaskan'}</span>
            </div>
            <div class="flex justify-between items-center text-[10px]">
               <span class="font-bold text-slate-400 uppercase">Status</span>
               <span class="font-black ${store.is_active ? 'text-emerald-500' : 'text-rose-500'}">${store.is_active ? 'AKTIF' : 'NON-AKTIF'}</span>
            </div>
            <p class="text-[9px] text-slate-500 mt-2 italic border-t border-slate-50 pt-2">${store.address || 'Tanpa Alamat'}</p>
          </div>
        </div>
      `)
      marker.addTo(markerGroup!)
    })

    if (validStores.length > 0 && map) {
      const bounds = L.latLngBounds(validStores.map(s => [s.latitude, s.longitude]))
      map.fitBounds(bounds, { padding: [50, 50] })
    }
  } else {
    // Product Distribution Mode
    const validData = productSalesData.value.filter(d => d.latitude && d.longitude)
    const maxQty = Math.max(...validData.map(d => (d.total_quantity || d.totalQuantity || 0)), 1)
    
    // Find the selected product image
    const selectedProduct = products.value.find(p => p.id === selectedProductId.value)
    const productImage = selectedProduct?.image_url || 'https://cdn-icons-png.flaticon.com/512/679/679821.png'

    validData.forEach(data => {
      const qty = data.total_quantity || data.totalQuantity || 0
      // Calculate size based on volume (min 30px, max 80px)
      const size = 30 + (Math.sqrt(qty / maxQty) * 50)
      
      const icon = L.divIcon({
        html: `
          <div class="relative group transition-all duration-300 transform hover:scale-110 flex flex-col items-center">
            <div class="relative" style="width: ${size}px; height: ${size}px;">
              <div class="w-full h-full rounded-full border-4 border-white shadow-xl overflow-hidden bg-white ring-2 ring-primary/20">
                <img src="${productImage}" class="w-full h-full object-cover" />
              </div>
              <div class="absolute -top-1 -right-1 bg-primary text-white text-[9px] font-black px-1.5 py-0.5 rounded-lg shadow-lg z-10 border border-white">
                ${qty}
              </div>
            </div>
            <div class="bg-slate-900 text-white px-2 py-0.5 rounded-full shadow-md mt-1 whitespace-nowrap border border-white/20">
               <span class="text-[8px] font-black uppercase tracking-tighter">${qty} PCS</span>
            </div>
          </div>
        `,
        className: 'custom-product-marker',
        iconSize: [size + 40, size + 40],
        iconAnchor: [(size + 40) / 2, (size + 40) / 2]
      })

      const marker = L.marker([data.latitude, data.longitude], { icon })
      
      marker.bindPopup(`
        <div class="p-3 min-w-[180px]">
          <div class="flex items-center gap-3 mb-3 pb-3 border-b border-slate-100">
             <img src="${productImage}" class="w-10 h-10 rounded-lg object-cover bg-slate-50" />
             <div>
                <h4 class="font-black text-slate-900 leading-tight">${data.store_name}</h4>
                <p class="text-[10px] text-slate-500 font-bold uppercase tracking-tighter">Wilayah Distribusi</p>
             </div>
          </div>
          <div class="space-y-2">
            <div class="flex justify-between items-center">
               <span class="text-[10px] font-bold text-slate-400 uppercase">Total Penjualan</span>
               <span class="text-sm font-black text-primary">${qty} PCS</span>
            </div>
            <div class="h-1.5 w-full bg-slate-100 rounded-full overflow-hidden">
               <div class="h-full bg-primary" style="width: ${(qty/maxQty)*100}%"></div>
            </div>
          </div>
        </div>
      `)
      
      // Add hover effect
      marker.on('mouseover', function(e) {
        e.target.openPopup()
      })
      
      marker.addTo(markerGroup!)
    })

    if (validData.length > 0 && map) {
      const bounds = L.latLngBounds(validData.map(d => [d.latitude, d.longitude]))
      map.fitBounds(bounds, { padding: [100, 100] })
    }
  }
}

onMounted(() => {
  fetchDashboardData()
})

watch(() => masterDataStore.selectedBranchId, () => {
  fetchDashboardData()
})

watch(mapMode, (newMode) => {
  if (newMode === 'STORES') {
    updateMarkers()
  } else if (selectedProductId.value) {
    fetchProductDistribution()
  }
})

watch(selectedProductId, () => {
  if (mapMode.value === 'PRODUCTS') {
    fetchProductDistribution()
  }
})

const formatCurrency = (val: number) => {
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(val)
}
</script>

<template>
  <div class="space-y-8 pb-10">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-6">
      <div>
        <h1 class="text-3xl font-extrabold text-slate-900 tracking-tight">Sales Dashboard</h1>
        <p class="text-[15px] font-medium text-slate-500 mt-1.5 flex items-center gap-2">
          <TrendingUp class="w-4 h-4 text-primary" />
          Pantau performa penjualan dan kampanye spanduk hari ini.
        </p>
      </div>
      <div class="flex items-center gap-3">
        <div class="bg-white border border-slate-200 px-5 py-2.5 rounded-2xl text-sm font-bold text-slate-700 shadow-sm uppercase">
          {{ new Date().toLocaleDateString('id-ID', { month: 'long', year: 'numeric' }) }}
        </div>
      </div>
    </div>

    <!-- Quick Stats -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      <div class="bg-white p-6 rounded-3xl border border-slate-200 shadow-sm hover:shadow-md transition-all">
        <div class="flex items-start justify-between">
          <div>
            <p class="text-[13px] font-bold text-slate-500 uppercase tracking-wider">Total Salesman</p>
            <h3 class="text-3xl font-extrabold text-slate-900 mt-2">{{ totalSalesmen }}</h3>
          </div>
          <div class="p-3 bg-blue-50 rounded-2xl text-blue-600">
            <Users class="w-6 h-6" />
          </div>
        </div>
        <p class="text-xs font-bold text-slate-400 mt-4">8 Aktif hari ini</p>
      </div>

      <div class="bg-white p-6 rounded-3xl border border-slate-200 shadow-sm hover:shadow-md transition-all">
        <div class="flex items-start justify-between">
          <div>
            <p class="text-[13px] font-bold text-slate-500 uppercase tracking-wider">Total Omzet</p>
            <h3 class="text-2xl font-black text-slate-900 mt-2 truncate max-w-[180px]" :title="formatCurrency(kpiSummary.totalOmzetAll)">
              {{ formatCurrency(kpiSummary.totalOmzetAll) }}
            </h3>
          </div>
          <div class="p-3 bg-emerald-50 rounded-2xl text-emerald-600">
            <Banknote class="w-6 h-6" />
          </div>
        </div>
        <div class="mt-4 flex items-center gap-2 text-emerald-600 font-bold text-xs">
          <TrendingUp class="w-3 h-3" /> Berjalan bulan ini
        </div>
      </div>

      <div class="bg-white p-6 rounded-3xl border border-slate-200 shadow-sm hover:shadow-md transition-all">
        <div class="flex items-start justify-between">
          <div>
            <p class="text-[13px] font-bold text-slate-500 uppercase tracking-wider">Nota Menunggu</p>
            <h3 class="text-3xl font-extrabold text-slate-900 mt-2">{{ pendingNotesCount }}</h3>
          </div>
          <div class="p-3 bg-amber-50 rounded-2xl text-amber-600">
            <Target class="w-6 h-6" />
          </div>
        </div>
        <p class="text-xs font-bold text-amber-600 mt-4">Perlu approval admin</p>
      </div>

      <div class="bg-white p-6 rounded-3xl border border-slate-200 shadow-sm hover:shadow-md transition-all">
        <div class="flex items-start justify-between">
          <div>
            <p class="text-[13px] font-bold text-slate-500 uppercase tracking-wider">Spanduk Terpasang</p>
            <h3 class="text-3xl font-extrabold text-slate-900 mt-2">{{ spandukStats.completed }}</h3>
          </div>
          <div class="p-3 bg-primary/5 rounded-2xl text-primary">
            <Megaphone class="w-6 h-6" />
          </div>
        </div>
      </div>
    </div>

    <!-- Store Distribution Map -->
    <div class="bg-white rounded-[32px] border border-slate-200 shadow-sm overflow-hidden animate-in fade-in slide-in-from-bottom-4 duration-700">
      <div class="p-6 border-b border-slate-100 flex items-center justify-between bg-slate-50/30">
        <div>
          <h3 class="text-lg font-extrabold text-slate-900 tracking-tight flex items-center gap-2">
            <MapPin class="w-5 h-5 text-primary" />
            Persebaran Toko & Wilayah
          </h3>
          <p class="text-[10px] font-black text-slate-400 uppercase tracking-widest mt-1">Total {{ stores.length }} titik distribusi aktif</p>
        </div>
        <div class="flex items-center gap-4">
          <div class="flex items-center bg-white border border-slate-200 rounded-xl p-1 shadow-sm">
            <button 
              @click="mapMode = 'STORES'"
              :class="[
                'px-4 py-1.5 rounded-lg text-xs font-black transition-all',
                mapMode === 'STORES' ? 'bg-primary text-white shadow-md' : 'text-slate-400 hover:text-slate-600'
              ]"
            >
              TOKO
            </button>
            <button 
              @click="mapMode = 'PRODUCTS'"
              :class="[
                'px-4 py-1.5 rounded-lg text-xs font-black transition-all',
                mapMode === 'PRODUCTS' ? 'bg-primary text-white shadow-md' : 'text-slate-400 hover:text-slate-600'
              ]"
            >
              PRODUK
            </button>
          </div>

          <select 
            v-if="mapMode === 'PRODUCTS'"
            v-model="selectedProductId"
            class="bg-white border border-slate-200 rounded-xl px-3 py-1.5 text-xs font-black outline-none focus:ring-2 focus:ring-primary/20 transition-all shadow-sm min-w-[200px]"
          >
            <option value="" disabled>Pilih Produk Tracking...</option>
            <option v-for="p in products" :key="p.id" :value="p.id">{{ p.name }}</option>
          </select>

          <button @click="updateMarkers" class="p-2.5 bg-white border border-slate-200 text-slate-400 hover:text-primary rounded-xl transition-all shadow-sm">
            <Maximize2 class="w-4 h-4" />
          </button>
        </div>
      </div>
      <div class="relative">
        <div v-if="isMapLoading" class="absolute inset-0 bg-white/60 backdrop-blur-[2px] z-10 flex items-center justify-center">
           <div class="flex flex-col items-center gap-3">
              <RefreshCw class="w-8 h-8 text-primary animate-spin" />
              <p class="text-xs font-black text-slate-900 uppercase tracking-widest">Memetakan Data...</p>
           </div>
        </div>
        <div ref="mapContainer" class="h-[450px] w-full z-0"></div>
      </div>
    </div>
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
      <div class="lg:col-span-2 bg-white rounded-3xl border border-slate-200 shadow-sm p-8 flex flex-col h-[480px]">
        <div class="flex items-center justify-between mb-8 shrink-0">
          <div>
            <h3 class="text-lg font-extrabold text-slate-900 tracking-tight">Tren Realisasi Omzet</h3>
            <p class="text-sm text-slate-500">Target vs Aktual Bulanan</p>
          </div>
        </div>
        <div class="flex-1 min-h-0 relative">
          <v-chart class="absolute inset-0" :option="omzetChartOption" autoresize />
        </div>
      </div>

      <div class="bg-white rounded-3xl border border-slate-200 shadow-sm p-8 flex flex-col h-[480px]">
        <h3 class="text-lg font-extrabold text-slate-900 tracking-tight mb-2 shrink-0">Campaign Spanduk</h3>
        <p class="text-sm text-slate-500 mb-8 shrink-0">Progress pemasangan materi promosi</p>
        <div class="relative flex-1 min-h-0 flex items-center justify-center">
          <v-chart class="h-full w-full" :option="spandukChartOption" autoresize />
          <div class="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
            <span class="text-3xl font-black text-slate-900">{{ spandukStats.completed }}</span>
            <span class="text-[10px] font-bold text-slate-400 uppercase tracking-widest mt-1">Titik Selesai</span>
          </div>
        </div>
        <div class="grid grid-cols-3 gap-4 mt-8 shrink-0 border-t border-slate-50 pt-6">
          <div class="text-center">
            <p class="text-[10px] font-bold text-slate-400 uppercase">Selesai</p>
            <p class="text-lg font-black text-emerald-600">{{ spandukStats.completed }}</p>
          </div>
          <div class="text-center">
            <p class="text-[10px] font-bold text-slate-400 uppercase">Proses</p>
            <p class="text-lg font-black text-blue-600">{{ spandukStats.inProgress }}</p>
          </div>
          <div class="text-center">
            <p class="text-[10px] font-bold text-slate-400 uppercase">Pending</p>
            <p class="text-lg font-black text-amber-600">{{ spandukStats.pending }}</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Leaderboard & Recent Activity -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
      <div class="bg-white rounded-3xl border border-slate-200 shadow-sm overflow-hidden">
        <div class="p-6 border-b border-slate-100 flex items-center justify-between">
          <h3 class="text-lg font-extrabold text-slate-900 tracking-tight flex items-center gap-2">
            <Award class="w-5 h-5 text-amber-500" />
            Top Salesman
          </h3>
          <router-link to="/sales/salesman" class="text-sm font-bold text-primary flex items-center gap-1.5 hover:underline">
            Lihat Semua <ArrowRight class="w-4 h-4" />
          </router-link>
        </div>
        <div class="divide-y divide-slate-100">
          <div v-for="sales in topSalesman" :key="sales.id" class="p-4 flex items-center gap-4 hover:bg-slate-50/50 transition-all">
            <div :class="[
              'w-10 h-10 rounded-2xl flex items-center justify-center font-black text-sm',
              sales.rank === 1 ? 'bg-amber-100 text-amber-600' : 'bg-slate-100 text-slate-500'
            ]">
              #{{ sales.rank }}
            </div>
            <div class="flex-1">
              <p class="font-bold text-slate-900">{{ sales.name }}</p>
              <div class="flex items-center gap-2 mt-0.5">
                <div class="h-1.5 flex-1 bg-slate-100 rounded-full overflow-hidden max-w-[100px]">
                  <div class="h-full bg-primary/80 rounded-full" :style="`width: ${Math.min(sales.achievement, 100)}%`"></div>
                </div>
                <span class="text-[10px] font-black text-primary">{{ sales.achievement }}%</span>
              </div>
            </div>
            <div class="text-right">
              <p class="text-sm font-black text-slate-900">{{ formatCurrency(sales.omzet) }}</p>
              <p class="text-[10px] font-bold text-slate-400 uppercase">Total Omzet</p>
            </div>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-3xl border border-slate-200 shadow-sm overflow-hidden">
        <div class="p-6 border-b border-slate-100 flex items-center justify-between">
          <h3 class="text-lg font-extrabold text-slate-900 tracking-tight flex items-center gap-2">
            <CheckCircle2 class="w-5 h-5 text-emerald-500" />
            Approval Nota Terbaru
          </h3>
          <router-link to="/sales/penjualan" class="text-sm font-bold text-primary flex items-center gap-1.5 hover:underline">
            Ke Approval <ArrowRight class="w-4 h-4" />
          </router-link>
        </div>
        <div class="divide-y divide-slate-100">
          <div v-for="nota in recentNotas" :key="nota.id" class="p-4 flex items-center justify-between hover:bg-slate-50/50 transition-all">
            <div class="flex items-center gap-4">
              <div class="p-2.5 bg-slate-100 rounded-xl">
                <Banknote class="w-5 h-5 text-slate-500" />
              </div>
              <div>
                <p class="text-sm font-bold text-slate-900">{{ nota.store }}</p>
                <p class="text-[11px] text-slate-500 font-medium">{{ nota.id }} • {{ nota.time }}</p>
              </div>
            </div>
            <div class="text-right">
              <p class="text-sm font-black text-slate-900">{{ formatCurrency(nota.amount) }}</p>
              <span :class="[
                'text-[10px] font-black px-2 py-0.5 rounded-lg',
                nota.status === 'APPROVED' ? 'bg-emerald-50 text-emerald-600' : 'bg-amber-50 text-amber-600'
              ]">
                {{ nota.status }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.v-chart {
  font-family: 'Plus Jakarta Sans', sans-serif !important;
}
</style>
