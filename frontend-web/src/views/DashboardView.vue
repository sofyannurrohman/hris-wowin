<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { toast } from 'vue-sonner'
import apiClient from '@/api/axios'
import { use } from 'echarts/core'
import { CanvasRenderer } from 'echarts/renderers'
import { LineChart, BarChart } from 'echarts/charts'
import { GridComponent, TooltipComponent, LegendComponent, TitleComponent } from 'echarts/components'
import VChart from 'vue-echarts'
import { 
  Users, 
  CheckCircle2, 
  Clock, 
  AlertCircle, 
  ArrowRight, 
  CalendarClock,
  TrendingUp,
  Mail
} from 'lucide-vue-next'

use([CanvasRenderer, LineChart, BarChart, GridComponent, TooltipComponent, LegendComponent, TitleComponent])

const chartOption = ref({
  tooltip: { 
    trigger: 'axis',
    backgroundColor: 'rgba(255, 255, 255, 0.95)',
    borderWidth: 0,
    shadowBlur: 10,
    shadowColor: 'rgba(0,0,0,0.1)',
    textStyle: { color: '#1e293b', fontWeight: 'bold' }
  },
  legend: { 
    data: ['Target Omzet', 'Capaian Aktual'], 
    bottom: 0,
    icon: 'circle',
    textStyle: { fontFamily: 'Plus Jakarta Sans', fontWeight: '600' }
  },
  grid: { left: '3%', right: '4%', bottom: '15%', top: '5%', containLabel: true },
  xAxis: { 
    type: 'category', 
    data: ['M1', 'M2', 'M3', 'M4'],
    axisLine: { lineStyle: { color: '#e2e8f0' } },
    axisLabel: { color: '#64748b', fontWeight: 'bold' }
  },
  yAxis: { 
    type: 'value',
    splitLine: { lineStyle: { color: '#f1f5f9' } },
    axisLabel: { color: '#64748b', fontWeight: 'bold' }
  },
  series: [
    { 
      name: 'Target Omzet', 
      type: 'line', 
      data: [100, 100, 100, 100], 
      itemStyle: { color: '#94a3b8' },
      smooth: true,
      lineStyle: { width: 3, type: 'dashed' }
    },
    { 
      name: 'Capaian Aktual', 
      type: 'bar', 
      data: [90, 140, 120, 150], 
      itemStyle: { 
        color: '#990000',
        borderRadius: [8, 8, 0, 0]
      }, 
      barMaxWidth: 32 
    }
  ]
})

// --- Reactive State ---
const totalEmployees = ref(0)
const presentToday = ref(0)
const lateToday = ref(0)
const recentAttendance = ref<any[]>([])
const pendingLeaves = ref<any[]>([])
const pendingLeavesCount = ref(0)
const isSubmittingLeave = ref(false)
const isLoading = ref(true)

const attendanceRate = computed(() => {
  if (totalEmployees.value === 0) return '0'
  return ((presentToday.value / totalEmployees.value) * 100).toFixed(1)
})

// --- Helpers ---
const isToday = (dateStr: string) => {
  const d = new Date(dateStr)
  const now = new Date()
  return d.getFullYear() === now.getFullYear() &&
    d.getMonth() === now.getMonth() &&
    d.getDate() === now.getDate()
}

const avatarColor = (name: string) => {
  const colors = [
    'bg-primary/10 text-primary',
    'bg-slate-100 text-slate-600',
    'bg-emerald-100 text-emerald-600',
    'bg-amber-100 text-amber-600',
  ]
  const idx = (name.charCodeAt(0) || 0) % colors.length
  return colors[idx]
}

const getInitials = (name: string) =>
  name.split(' ').map(w => w[0]).join('').toUpperCase().slice(0, 2)

// --- Data Fetching ---
const fetchStats = async () => {
  isLoading.value = true
  try {
    await Promise.all([
      fetchEmployeeCount(),
      fetchTodayAttendance(),
      fetchPendingLeaves()
    ])
  } finally {
    isLoading.value = false
  }
}

const fetchEmployeeCount = async () => {
  try {
    const res = await apiClient.get('/employees')
    if (res.data?.data) {
      totalEmployees.value = res.data.data.length
    }
  } catch (e) {
    console.error('Failed to fetch employee count', e)
  }
}

const fetchTodayAttendance = async () => {
  try {
    const res = await apiClient.get('/attendance/all?limit=200')
    if (res.data?.data) {
      const todayRecords = res.data.data.filter((item: any) =>
        item.clock_in_time && isToday(item.clock_in_time)
      )
      presentToday.value = todayRecords.length
      lateToday.value = todayRecords.filter((item: any) =>
        item.status === 'LATE'
      ).length

      // Build recent attendance table (latest 5)
      recentAttendance.value = todayRecords.slice(0, 5).map((item: any) => {
        const name = item.employee?.first_name || 'Karyawan'
        const role = item.employee?.job_position?.title || '-'
        const dept = item.employee?.department?.name || '-'
        
        const fmtTime = (timeStr: string) => {
          if (!timeStr) return '-'
          
          // Handle HH:mm:ss format
          if (timeStr.includes(':') && !timeStr.includes('-') && !timeStr.includes('T')) {
            const parts = timeStr.split(':')
            const h = (parts[0] || '00').padStart(2, '0')
            const m = (parts[1] || '00').padStart(2, '0')
            return `${h}.${m}`
          }

          const d = new Date(timeStr)
          if (isNaN(d.getTime())) return '-'
          const h = String(d.getUTCHours()).padStart(2, '0')
          const m = String(d.getUTCMinutes()).padStart(2, '0')
          return `${h}.${m}`
        }

        const checkInTime = item.clock_in_time ? fmtTime(item.clock_in_time) : '-'
        const status = item.status === 'LATE' ? 'Terlambat' : 'Tepat Waktu'
        return {
          id: item.id,
          name,
          role,
          dept,
          initials: getInitials(name),
          checkIn: checkInTime,
          status,
          color: avatarColor(name)
        }
      })
    }
  } catch (e) {
    console.error('Failed to fetch today attendance', e)
  }
}

const fetchPendingLeaves = async () => {
  try {
    const res = await apiClient.get('/time-off/manage?status=PENDING&limit=10')
    if (res.data?.data) {
      pendingLeavesCount.value = res.data.data.length
      pendingLeaves.value = res.data.data.slice(0, 3).map((item: any) => ({
        id: item.id,
        name: item.employee?.first_name || 'Karyawan',
        type: item.leave_type?.name || 'Cuti',
        days: (() => {
          const start = new Date(item.start_date)
          const end = new Date(item.end_date)
          const d = Math.ceil((end.getTime() - start.getTime()) / (1000 * 3600 * 24)) + 1
          return `${d} Hari`
        })(),
        time: (() => {
          const created = new Date(item.created_at || item.start_date)
          const diffH = Math.round((Date.now() - created.getTime()) / 3600000)
          return diffH < 1 ? 'Baru saja' : `${diffH}j lalu`
        })(),
        initials: getInitials(item.employee?.first_name || 'K')
      }))
    }
  } catch (e) {
    console.error('Failed to fetch pending leaves', e)
  }
}

const approveLeave = async (id: string) => {
  if (!confirm('Yakin ingin menyetujui cuti ini?')) return
  isSubmittingLeave.value = true
  try {
    await apiClient.put(`/time-off/manage/${id}/approve`, { status: 'APPROVED' })
    toast.success('Permohonan cuti disetujui!')
    await fetchPendingLeaves()
  } catch (e: any) {
    toast.error('Gagal menyetujui cuti: ' + (e.response?.data?.message || e.message))
  } finally {
    isSubmittingLeave.value = false
  }
}

const rejectLeave = async (id: string) => {
  const reason = prompt('Alasan penolakan cuti:')
  if (!reason) return
  isSubmittingLeave.value = true
  try {
    await apiClient.put(`/time-off/manage/${id}/approve`, { status: 'REJECTED', reject_reason: reason })
    toast.success('Permohonan cuti ditolak!')
    await fetchPendingLeaves()
  } catch (e: any) {
    toast.error('Gagal menolak cuti: ' + (e.response?.data?.message || e.message))
  } finally {
    isSubmittingLeave.value = false
  }
}

onMounted(() => {
  fetchStats()
})
</script>

<template>
  <div class="space-y-8 pb-10">
    <!-- Header Page -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-6">
      <div>
        <h1 class="text-3xl font-extrabold text-slate-900 tracking-tight">Ringkasan Dashboard</h1>
        <p class="text-[15px] font-medium text-slate-500 mt-1.5 flex items-center gap-2">
          <TrendingUp class="w-4 h-4 text-primary" />
          Selamat datang kembali! Berikut metrik operasional terbaru saat ini.
        </p>
      </div>
      <div class="flex items-center gap-3">
        <button class="flex items-center gap-2 bg-white border border-slate-200 px-5 py-2.5 rounded-2xl text-sm font-bold text-slate-700 hover:bg-slate-50 transition-all shadow-sm">
          <span>Hari Ini</span>
        </button>
      </div>
    </div>

    <!-- Top 4 Stats -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      <!-- Total Karyawan -->
      <div class="group bg-white p-6 rounded-3xl border border-slate-200 shadow-[0_4px_20px_rgba(0,0,0,0.03)] hover:shadow-[0_10px_30px_rgba(153,0,0,0.05)] transition-all duration-500 relative overflow-hidden">
        <div class="flex items-start justify-between relative z-10">
          <div>
            <p class="text-[13px] font-bold text-slate-500 uppercase tracking-wider">Total Karyawan</p>
            <h3 class="text-3xl font-extrabold text-slate-900 mt-2">
              <span v-if="isLoading" class="inline-block w-16 h-10 bg-slate-100 rounded-xl animate-pulse"></span>
              <span v-else>{{ totalEmployees }}</span>
            </h3>
          </div>
          <div class="p-3.5 bg-primary/5 rounded-2xl text-primary transition-transform duration-500 group-hover:scale-110 group-hover:rotate-6">
            <Users class="w-6 h-6" />
          </div>
        </div>
        <div class="mt-4 flex items-center gap-2 relative z-10">
          <span class="text-[12px] font-bold text-slate-400">Total staf terdaftar</span>
        </div>
        <!-- Abstract BG Decoration -->
        <div class="absolute -right-6 -bottom-6 w-24 h-24 bg-primary/5 rounded-full blur-2xl opacity-0 group-hover:opacity-100 transition-opacity duration-500"></div>
      </div>

      <!-- Hadir Hari Ini -->
      <div class="group bg-white p-6 rounded-3xl border border-slate-200 shadow-[0_4px_20px_rgba(0,0,0,0.03)] hover:shadow-[0_10px_30px_rgba(16,185,129,0.05)] transition-all duration-500 relative overflow-hidden">
        <div class="flex items-start justify-between relative z-10">
          <div>
            <p class="text-[13px] font-bold text-slate-500 uppercase tracking-wider">Hadir Hari Ini</p>
            <h3 class="text-3xl font-extrabold text-slate-900 mt-2">
              <span v-if="isLoading" class="inline-block w-16 h-10 bg-slate-100 rounded-xl animate-pulse"></span>
              <span v-else>{{ presentToday }}</span>
            </h3>
          </div>
          <div class="p-3.5 bg-emerald-500/10 rounded-2xl text-emerald-600 transition-transform duration-500 group-hover:scale-110 group-hover:rotate-6">
            <CheckCircle2 class="w-6 h-6" />
          </div>
        </div>
        <div class="mt-5 space-y-2 relative z-10">
          <div class="flex items-center justify-between text-[11px] font-bold uppercase tracking-wider">
            <span class="text-slate-400">Tingkat Kehadiran</span>
            <span class="text-emerald-600">{{ attendanceRate }}%</span>
          </div>
          <div class="h-2 w-full bg-slate-100 rounded-full overflow-hidden">
            <div class="h-full bg-emerald-500/100 rounded-full transition-all duration-1000" :style="`width: ${attendanceRate}%`"></div>
          </div>
        </div>
      </div>

      <!-- Cuti Tertunda -->
      <div class="group bg-white p-6 rounded-3xl border border-slate-200 shadow-[0_4px_20px_rgba(0,0,0,0.03)] hover:shadow-[0_10px_30px_rgba(153,0,0,0.05)] transition-all duration-500 relative overflow-hidden">
        <div class="flex items-start justify-between relative z-10">
          <div>
            <p class="text-[13px] font-bold text-slate-500 uppercase tracking-wider">Cuti Menunggu</p>
            <h3 class="text-3xl font-extrabold text-slate-900 mt-2">
              <span v-if="isLoading" class="inline-block w-16 h-10 bg-slate-100 rounded-xl animate-pulse"></span>
              <span v-else>{{ pendingLeavesCount }}</span>
            </h3>
          </div>
          <div class="p-3.5 bg-amber-50 rounded-2xl text-amber-600 transition-transform duration-500 group-hover:scale-110 group-hover:rotate-6">
            <CalendarClock class="w-6 h-6" />
          </div>
        </div>
        <div class="mt-4 flex items-center gap-2 relative z-10">
          <span class="flex h-2 w-2 rounded-full bg-amber-400"></span>
          <span class="text-[12px] font-bold text-slate-500">Perlu peninjauan segera</span>
        </div>
      </div>

      <!-- Datang Terlambat -->
      <div class="group bg-white p-6 rounded-3xl border border-slate-200 shadow-[0_4px_20px_rgba(0,0,0,0.03)] hover:shadow-[0_10px_30px_rgba(239,68,68,0.05)] transition-all duration-500 relative overflow-hidden">
        <div class="flex items-start justify-between relative z-10">
          <div>
            <p class="text-[13px] font-bold text-slate-500 uppercase tracking-wider">Datang Terlambat</p>
            <h3 class="text-3xl font-extrabold text-slate-900 mt-2">
              <span v-if="isLoading" class="inline-block w-16 h-10 bg-slate-100 rounded-xl animate-pulse"></span>
              <span v-else>{{ lateToday }}</span>
            </h3>
          </div>
          <div class="p-3.5 bg-red-50 rounded-2xl text-red-500 transition-transform duration-500 group-hover:scale-110 group-hover:rotate-6">
            <Clock class="w-6 h-6" />
          </div>
        </div>
        <div class="mt-4 flex items-center gap-2 relative z-10">
          <AlertCircle class="w-4 h-4 text-red-400" />
          <span class="text-[12px] font-bold text-red-400">Update hari ini</span>
        </div>
      </div>
    </div>

    <!-- ECharts KPI Section -->
    <div class="bg-white rounded-3xl border border-slate-200 shadow-[0_4px_25px_rgba(0,0,0,0.04)] p-8">
      <div class="flex items-center justify-between mb-8">
        <div>
          <h3 class="text-lg font-extrabold text-slate-900 tracking-tight">Performa Sales Marketing</h3>
          <p class="text-sm text-slate-500 mt-1">Status capaian KPI mingguan divisi pemasaran.</p>
        </div>
        <button class="text-sm font-bold text-primary flex items-center gap-2 px-4 py-2 hover:bg-primary/5 rounded-xl transition-all">
          Lihat Detail <ArrowRight class="w-4 h-4" />
        </button>
      </div>
      <v-chart class="h-80 w-full" :option="chartOption" autoresize />
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
      
      <!-- Recent Attendance Table -->
      <div class="lg:col-span-2">
        <div class="bg-white rounded-3xl border border-slate-200 shadow-[0_4px_25px_rgba(0,0,0,0.04)] overflow-hidden">
          <div class="p-6 border-b border-slate-100 flex items-center justify-between">
            <h3 class="text-lg font-extrabold text-slate-900 tracking-tight">Kehadiran Hari Ini</h3>
            <router-link to="/attendance" class="text-sm font-bold text-primary flex items-center gap-1.5 hover:underline">
              Semua Log
              <ArrowRight class="w-4 h-4" />
            </router-link>
          </div>
          <!-- Loading skeleton -->
          <div v-if="isLoading" class="p-6 space-y-5">
            <div v-for="i in 4" :key="i" class="flex items-center gap-4">
              <div class="w-10 h-10 rounded-2xl bg-slate-50 animate-pulse"></div>
              <div class="flex-1 space-y-2">
                <div class="h-4 bg-slate-50 rounded w-1/3 animate-pulse"></div>
                <div class="h-3 bg-slate-50 rounded w-1/4 animate-pulse"></div>
              </div>
            </div>
          </div>
          <!-- Empty state -->
          <div v-else-if="recentAttendance.length === 0" class="p-16 text-center text-slate-400">
            <Mail class="w-12 h-12 mx-auto mb-4 opacity-10" />
            <p class="text-sm font-bold">Belum ada catatan log masuk hari ini.</p>
          </div>
          <!-- Data table -->
          <div v-else class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="bg-slate-50/50 uppercase text-[10px] font-extrabold text-slate-400 tracking-[0.1em]">
                  <th class="px-6 py-4">Karyawan</th>
                  <th class="px-6 py-4">Departemen</th>
                  <th class="px-6 py-4">Waktu</th>
                  <th class="px-6 py-4 text-right">Status</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100">
                <tr v-for="user in recentAttendance" :key="user.id" class="group hover:bg-slate-50/70 transition-colors">
                  <td class="px-6 py-4">
                    <div class="flex flex-col">
                      <p class="font-bold text-slate-900 group-hover:text-primary transition-colors">{{ user.name }}</p>
                      <p class="text-[12px] text-slate-400 font-medium">{{ user.role }}</p>
                    </div>
                  </td>
                  <td class="px-6 py-4 text-sm font-bold text-slate-500">{{ user.dept }}</td>
                  <td class="px-6 py-4 text-sm font-extrabold text-slate-900">{{ user.checkIn }}</td>
                  <td class="px-6 py-4 text-right">
                    <span :class="[
                      user.status === 'Tepat Waktu' 
                        ? 'bg-emerald-500/10 text-emerald-700 ring-1 ring-emerald-200' 
                        : 'bg-primary/5 text-primary ring-1 ring-primary/20', 
                      'px-3 py-1 rounded-xl text-[11px] font-extrabold tracking-wide'
                    ]">
                      {{ user.status.toUpperCase() }}
                    </span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- Right Column: Pending Leaves -->
      <div>
        <div class="bg-primary/[0.02] rounded-3xl border border-slate-200 p-6 relative h-full">
          <div class="flex items-center justify-between mb-6">
            <h3 class="text-lg font-extrabold text-slate-900 tracking-tight">Pengajuan Cuti</h3>
            <div v-if="pendingLeavesCount > 0" class="bg-primary text-white text-[10px] font-black px-2.5 py-1.5 rounded-xl shadow-lg shadow-primary/20">
              NEW
            </div>
          </div>
          
          <!-- Loading state -->
          <div v-if="isLoading" class="space-y-4">
            <div v-for="i in 2" :key="i" class="bg-white p-5 rounded-3xl shadow-sm border border-slate-100 animate-pulse">
              <div class="flex items-start gap-4">
                <div class="w-12 h-12 rounded-2xl bg-slate-50"></div>
                <div class="flex-1 space-y-2">
                  <div class="h-4 bg-slate-50 rounded w-1/2"></div>
                  <div class="h-3 bg-slate-50 rounded w-1/3"></div>
                </div>
              </div>
            </div>
          </div>

          <!-- Empty state -->
          <div v-else-if="pendingLeaves.length === 0" class="text-center py-12 text-slate-400">
            <div class="bg-white w-20 h-20 rounded-full flex items-center justify-center mx-auto mb-4 border border-dashed border-slate-200">
              <CheckCircle2 class="w-8 h-8 opacity-20" />
            </div>
            <p class="text-sm font-bold">Semua pengajuan sudah diproses.</p>
          </div>

          <!-- Leave cards -->
          <div v-else class="space-y-4">
            <div v-for="leave in pendingLeaves" :key="leave.id" class="bg-white p-5 rounded-3xl shadow-[0_4px_15px_rgba(0,0,0,0.02)] border border-slate-100 hover:shadow-lg hover:shadow-primary/5 transition-all duration-300">
                <div>
                  <div class="flex items-start justify-between">
                    <p class="text-sm font-extrabold text-slate-900">{{ leave.name }}</p>
                    <span class="text-[10px] font-bold text-primary bg-primary/5 px-2 py-0.5 rounded-lg">{{ leave.time }}</span>
                  </div>
                  <p class="text-[12px] text-slate-500 font-bold mt-1 uppercase tracking-tight">{{ leave.type }} <span class="text-slate-300 mx-1">•</span> <span class="text-slate-900">{{ leave.days }}</span></p>
                </div>
                <div class="flex gap-2.5 mt-5">
                  <button
                    @click="approveLeave(leave.id)"
                    :disabled="isSubmittingLeave"
                    class="flex-1 bg-primary text-white hover:bg-primary/90 rounded-xl py-2.5 text-[12px] font-extrabold transition-all shadow-md shadow-primary/20 disabled:opacity-50 active:scale-95"
                  >SETUJUI</button>
                  <button
                    @click="rejectLeave(leave.id)"
                    :disabled="isSubmittingLeave"
                    class="flex-1 bg-white border border-slate-200 text-slate-600 hover:bg-slate-50 rounded-xl py-2.5 text-[12px] font-extrabold transition-all disabled:opacity-50 active:scale-95"
                  >TOLAK</button>
                </div>
            </div>
          </div>
          
          <router-link to="/leaves" class="block group mt-6">
            <button class="w-full flex items-center justify-center gap-2 border-2 border-dashed border-slate-200 text-slate-400 py-3.5 rounded-3xl text-[12px] font-bold group-hover:bg-white group-hover:border-primary/30 group-hover:text-primary transition-all duration-300">
              LIHAT SEMUA PENGAJUAN
            </button>
          </router-link>
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
