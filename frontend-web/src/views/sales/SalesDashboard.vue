<script setup lang="ts">
import { ref, onMounted } from 'vue'
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

use([CanvasRenderer, LineChart, BarChart, PieChart, GridComponent, TooltipComponent, LegendComponent, TitleComponent])

const isLoading = ref(true)
const mapContainer = ref<HTMLElement | null>(null)
let map: L.Map | null = null
const stores = ref<any[]>([])

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
  isLoading.value = true
  const now = new Date()
  const month = now.getMonth() + 1
  const year = now.getFullYear()

  try {
    // 1. Fetch Summary
    const summaryRes = await apiClient.get(`/admin/sales/reports/summary?month=${month}&year=${year}`)
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
    const perfRes = await apiClient.get(`/admin/sales/reports/performance?month=${month}&year=${year}`)
    if (perfRes.data?.data) {
      // Map to topSalesman format
      topSalesman.value = perfRes.data.data
        .map((kpi: any) => ({
          id: kpi.ID,
          name: kpi.Employee ? `${kpi.Employee.first_name} ${kpi.Employee.last_name}` : 'Salesman',
          omzet: kpi.AchievedOmzet,
          achievement: Math.round((kpi.AchievedOmzet / (kpi.TargetOmzet || 1)) * 100),
          rank: 0 // Will sort later
        }))
        .sort((a: any, b: any) => b.omzet - a.omzet)
        .slice(0, 3)
        .map((item: any, index: number) => ({ ...item, rank: index + 1 }))

      // Update total salesman placeholder
      totalSalesmen.value = perfRes.data.data.length

      // Update Chart Data (Target vs Actual per Salesman)
      if (omzetChartOption.value.xAxis && !Array.isArray(omzetChartOption.value.xAxis) && omzetChartOption.value.series) {
        omzetChartOption.value.xAxis.data = perfRes.data.data.map((k: any) => k.Employee?.first_name || 'Sales')
        if (omzetChartOption.value.series[0]) omzetChartOption.value.series[0].data = perfRes.data.data.map((k: any) => k.TargetOmzet)
        if (omzetChartOption.value.series[1]) omzetChartOption.value.series[1].data = perfRes.data.data.map((k: any) => k.AchievedOmzet)
      }
    }

    // 3. Fetch Pending Notas
    const pendingRes = await apiClient.get('/admin/sales/transactions/all-pending')
    if (pendingRes.data?.data) {
      pendingNotesCount.value = pendingRes.data.data.length
      recentNotas.value = pendingRes.data.data.slice(0, 3).map((n: any) => ({
        id: n.receipt_no || n.id.slice(0, 8),
        store: n.store?.name || 'Toko',
        amount: n.total_amount,
        status: n.status,
        time: new Date(n.created_at).toLocaleTimeString()
      }))
    }

    // 4. Fetch Banner Stats
    const bannerRes = await apiClient.get('/banner-orders')
    if (bannerRes.data?.data) {
      const banners = bannerRes.data.data
      const completed = banners.filter((b: any) => b.status === 'COMPLETED').length
      const inProgress = banners.filter((b: any) => b.status === 'IN_PROGRESS').length
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
    const storeRes = await apiClient.get('/stores')
    if (storeRes.data?.data) {
      stores.value = storeRes.data.data
      initMap()
    }
  } catch (error) {
    console.error('Failed to fetch dashboard data:', error)
  } finally {
    isLoading.value = false
  }
}

const initMap = () => {
  if (!mapContainer.value || map) return

  // Default center (Jakarta area or average of stores)
  const center: L.LatLngExpression = stores.value.length > 0 
    ? [stores.value[0].latitude, stores.value[0].longitude]
    : [-6.2088, 106.8456]

  map = L.map(mapContainer.value).setView(center, 12)

  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '© OpenStreetMap contributors'
  }).addTo(map)

  // Add markers
  stores.value.forEach(store => {
    if (store.latitude && store.longitude) {
      const marker = L.marker([store.latitude, store.longitude]).addTo(map!)
      marker.bindPopup(`
        <div class="p-2">
          <h4 class="font-black text-slate-900">${store.name}</h4>
          <p class="text-[10px] text-slate-500 mt-1 uppercase font-bold">${store.address || 'Tanpa Alamat'}</p>
          <div class="mt-2 pt-2 border-t border-slate-100 flex items-center gap-2">
             <span class="w-2 h-2 rounded-full ${store.is_active ? 'bg-emerald-500' : 'bg-red-500'}"></span>
             <span class="text-[10px] font-black">${store.is_active ? 'AKTIF' : 'NON-AKTIF'}</span>
          </div>
        </div>
      `)
    }
  })
}

onMounted(() => {
  fetchDashboardData()
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
        <button @click="initMap" class="p-2.5 bg-white border border-slate-200 text-slate-400 hover:text-primary rounded-xl transition-all shadow-sm">
          <Maximize2 class="w-4 h-4" />
        </button>
      </div>
      <div ref="mapContainer" class="h-[450px] w-full z-0"></div>
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
