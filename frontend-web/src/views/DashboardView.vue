<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { toast } from 'vue-sonner'
import apiClient from '@/api/axios'

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
    'bg-indigo-100 text-indigo-600',
    'bg-pink-100 text-pink-600',
    'bg-blue-100 text-blue-600',
    'bg-amber-100 text-amber-600',
    'bg-emerald-100 text-emerald-600',
    'bg-purple-100 text-purple-600',
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
        item.ClockInTime && isToday(item.ClockInTime)
      )
      presentToday.value = todayRecords.length
      lateToday.value = todayRecords.filter((item: any) =>
        item.Status === 'LATE'
      ).length

      // Build recent attendance table (latest 5)
      recentAttendance.value = todayRecords.slice(0, 5).map((item: any) => {
        const name = item.Employee?.FirstName || 'Karyawan'
        const role = item.Employee?.JobPosition?.Name || '-'
        const dept = item.Employee?.Department?.Name || '-'
        const checkInTime = item.ClockInTime
          ? new Date(item.ClockInTime).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })
          : '-'
        const status = item.Status === 'LATE' ? 'Terlambat' : 'Tepat Waktu'
        return {
          id: item.ID,
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
    const res = await apiClient.get('/time-off?status=PENDING&limit=10')
    if (res.data?.data) {
      pendingLeavesCount.value = res.data.data.length
      pendingLeaves.value = res.data.data.slice(0, 3).map((item: any) => ({
        id: item.ID,
        name: item.Employee?.FirstName || 'Karyawan',
        type: item.LeaveType?.Name || 'Cuti',
        days: (() => {
          const start = new Date(item.StartDate)
          const end = new Date(item.EndDate)
          const d = Math.ceil((end.getTime() - start.getTime()) / (1000 * 3600 * 24)) + 1
          return `${d} Hari`
        })(),
        time: (() => {
          const created = new Date(item.CreatedAt || item.StartDate)
          const diffH = Math.round((Date.now() - created.getTime()) / 3600000)
          return diffH < 1 ? 'Baru saja' : `${diffH}j lalu`
        })(),
        image: `https://i.pravatar.cc/150?u=${item.EmployeeID}`
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
    await apiClient.put(`/time-off/${id}/approve`, { status: 'APPROVED' })
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
    await apiClient.put(`/time-off/${id}/approve`, { status: 'REJECTED', reject_reason: reason })
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
  <div class="space-y-6">
    <!-- Header Page -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h1 class="text-[22px] font-bold text-gray-900 leading-tight">Ringkasan Dashboard</h1>
        <p class="text-[14px] text-gray-500 mt-1">Pantau kehadiran harian, performa, dan metrik operasional.</p>
      </div>
    </div>

    <!-- Top 4 Stats -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
      <!-- Total Karyawan -->
      <div class="bg-white p-5 rounded-xl border border-gray-200 shadow-sm relative overflow-hidden">
        <div class="flex items-start justify-between">
          <p class="text-[13px] font-medium text-gray-500">Total Karyawan</p>
          <div class="flex items-center text-blue-500 bg-blue-50 px-2 py-1 rounded text-[12px] font-medium gap-1">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" /></svg>
          </div>
        </div>
        <h3 class="text-[28px] font-bold text-gray-900 mt-2">
          <span v-if="isLoading" class="inline-block w-16 h-8 bg-gray-100 rounded animate-pulse"></span>
          <span v-else>{{ totalEmployees }}</span>
        </h3>
        <div class="flex items-center gap-1 text-[12px] mt-2 text-gray-400">
          <span>Total staf terdaftar</span>
        </div>
      </div>

      <!-- Hadir Hari Ini -->
      <div class="bg-white p-5 rounded-xl border border-gray-200 shadow-sm relative overflow-hidden">
        <div class="flex items-start justify-between">
          <p class="text-[13px] font-medium text-gray-500">Hadir Hari Ini</p>
          <div class="flex items-center text-emerald-600 bg-emerald-50 px-2 py-1 rounded text-[12px] font-medium gap-1">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
          </div>
        </div>
        <h3 class="text-[28px] font-bold text-gray-900 mt-2">
          <span v-if="isLoading" class="inline-block w-16 h-8 bg-gray-100 rounded animate-pulse"></span>
          <span v-else>{{ presentToday }}</span>
        </h3>
        <div class="flex items-center gap-2 mt-2">
          <span class="text-[12px] font-medium text-gray-600">{{ attendanceRate }}%</span>
          <div class="h-1.5 flex-1 bg-gray-100 rounded-full overflow-hidden">
            <div class="h-full bg-emerald-500 rounded-full" :style="`width: ${attendanceRate}%`"></div>
          </div>
        </div>
      </div>

      <!-- Cuti Tertunda -->
      <div class="bg-white p-5 rounded-xl border border-gray-200 shadow-sm relative overflow-hidden">
        <div class="flex items-start justify-between">
          <p class="text-[13px] font-medium text-gray-500">Cuti Menunggu</p>
          <div class="flex items-center text-purple-600 bg-purple-50 px-2 py-1 rounded text-[12px] font-medium gap-1">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M15 20.488V18a2 2 0 012-2h3.064M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
          </div>
        </div>
        <h3 class="text-[28px] font-bold text-gray-900 mt-2">
          <span v-if="isLoading" class="inline-block w-16 h-8 bg-gray-100 rounded animate-pulse"></span>
          <span v-else>{{ pendingLeavesCount }}</span>
        </h3>
        <div class="flex items-center gap-1 text-[12px] mt-2 text-gray-500 font-medium">
          <span class="w-2 h-2 rounded-full bg-purple-400"></span> Perlu ditinjau
        </div>
      </div>

      <!-- Datang Terlambat -->
      <div class="bg-white p-5 rounded-xl border border-gray-200 shadow-sm relative overflow-hidden">
        <div class="flex items-start justify-between">
          <p class="text-[13px] font-medium text-gray-500">Datang Terlambat</p>
          <div class="flex items-center text-red-500 bg-red-50 px-2 py-1 rounded text-[12px] font-medium gap-1">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" /></svg>
          </div>
        </div>
        <h3 class="text-[28px] font-bold text-gray-900 mt-2">
          <span v-if="isLoading" class="inline-block w-16 h-8 bg-gray-100 rounded animate-pulse"></span>
          <span v-else>{{ lateToday }}</span>
        </h3>
        <div class="flex items-center gap-1 text-[12px] mt-2 text-gray-400">
          <span>Hari ini</span>
        </div>
      </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      
      <!-- Recent Attendance Table -->
      <div class="lg:col-span-2">
        <div class="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
          <div class="p-5 border-b border-gray-100 flex items-center justify-between">
            <h3 class="text-[15px] font-bold text-gray-900">Catatan Kehadiran Terbaru (Hari Ini)</h3>
            <router-link to="/attendance" class="text-[13px] font-medium text-blue-600 flex items-center gap-1 hover:text-blue-700">
              Lihat Laporan Lengkap
              <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M17 8l4 4m0 0l-4 4m4-4H3" /></svg>
            </router-link>
          </div>
          <!-- Loading skeleton -->
          <div v-if="isLoading" class="p-6 space-y-4">
            <div v-for="i in 4" :key="i" class="flex items-center gap-3">
              <div class="w-8 h-8 rounded-full bg-gray-100 animate-pulse"></div>
              <div class="flex-1 space-y-2">
                <div class="h-3 bg-gray-100 rounded w-1/3 animate-pulse"></div>
                <div class="h-2 bg-gray-100 rounded w-1/4 animate-pulse"></div>
              </div>
            </div>
          </div>
          <!-- Empty state -->
          <div v-else-if="recentAttendance.length === 0" class="p-10 text-center text-gray-400">
            <p class="text-[14px]">Belum ada data kehadiran hari ini</p>
          </div>
          <!-- Data table -->
          <table v-else class="w-full text-left border-collapse text-[13px]">
            <thead>
              <tr class="bg-white border-b border-gray-100 uppercase text-[10px] font-bold text-gray-400 tracking-wide">
                <th class="px-5 py-3">KARYAWAN</th>
                <th class="px-5 py-3">DEPARTEMEN</th>
                <th class="px-5 py-3">JAM MASUK</th>
                <th class="px-5 py-3">STATUS</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-50">
              <tr v-for="user in recentAttendance" :key="user.id" class="hover:bg-gray-50/50">
                <td class="px-5 py-3">
                  <div class="flex items-center gap-3">
                    <div :class="`w-8 h-8 rounded-full flex items-center justify-center font-bold text-[11px] ${user.color}`">{{ user.initials }}</div>
                    <div>
                      <p class="font-bold text-gray-900">{{ user.name }}</p>
                      <p class="text-[11px] text-gray-400">{{ user.role }}</p>
                    </div>
                  </div>
                </td>
                <td class="px-5 py-3 text-gray-500">{{ user.dept }}</td>
                <td class="px-5 py-3 font-bold text-gray-900">{{ user.checkIn }}</td>
                <td class="px-5 py-3">
                  <span :class="[user.status === 'Tepat Waktu' ? 'bg-[#dcfce7] text-[#166534]' : 'bg-[#fee2e2] text-[#991b1b]', 'px-2 py-0.5 rounded-full text-[11px] font-bold']">
                    {{ user.status }}
                  </span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>

      <!-- Right Column: Pending Leaves -->
      <div>
        <div class="bg-[#fafbfc] rounded-xl border border-gray-200 p-5 relative">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-[15px] font-bold text-gray-900 leading-tight w-2/3">Permohonan Cuti Tertunda</h3>
            <div v-if="pendingLeavesCount > 0" class="bg-orange-100 text-orange-600 text-[10px] font-bold px-2 py-1 rounded-md text-center">
              {{ pendingLeavesCount }}<br/>Baru
            </div>
          </div>
          
          <!-- Loading state -->
          <div v-if="isLoading" class="space-y-3">
            <div v-for="i in 2" :key="i" class="bg-white p-4 rounded-xl shadow-sm border border-gray-100 animate-pulse">
              <div class="flex items-start gap-3">
                <div class="w-10 h-10 rounded-full bg-gray-100"></div>
                <div class="flex-1 space-y-2">
                  <div class="h-3 bg-gray-100 rounded w-1/2"></div>
                  <div class="h-2 bg-gray-100 rounded w-1/3"></div>
                </div>
              </div>
              <div class="flex gap-2 mt-4">
                <div class="flex-1 h-8 bg-gray-100 rounded-lg"></div>
                <div class="flex-1 h-8 bg-gray-100 rounded-lg"></div>
              </div>
            </div>
          </div>

          <!-- Empty state -->
          <div v-else-if="pendingLeaves.length === 0" class="text-center py-8 text-gray-400">
            <svg class="w-10 h-10 mx-auto mb-2 opacity-30" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
            <p class="text-[13px]">Tidak ada permohonan cuti</p>
          </div>

          <!-- Leave cards -->
          <div v-else class="space-y-3">
            <div v-for="leave in pendingLeaves" :key="leave.id" class="bg-white p-4 rounded-xl shadow-sm border border-gray-100">
              <div class="flex items-start gap-3">
                <img :src="leave.image" class="w-10 h-10 rounded-full border border-gray-100" />
                <div class="flex-1 min-w-0">
                  <div class="flex items-start justify-between">
                    <p class="text-[14px] font-bold text-gray-900">{{ leave.name }}</p>
                    <span class="text-[11px] text-gray-400">{{ leave.time }}</span>
                  </div>
                  <p class="text-[12px] text-gray-500 mt-0.5">{{ leave.type }} • <span class="font-medium">{{ leave.days }}</span></p>
                </div>
              </div>
              <div class="flex gap-2 mt-4">
                <button
                  @click="approveLeave(leave.id)"
                  :disabled="isSubmittingLeave"
                  class="flex-1 border text-emerald-600 border-emerald-200 bg-emerald-50 hover:bg-emerald-100 rounded-lg py-1.5 text-[12px] font-bold transition-colors disabled:opacity-50"
                >Setujui</button>
                <button
                  @click="rejectLeave(leave.id)"
                  :disabled="isSubmittingLeave"
                  class="flex-1 border text-gray-600 border-gray-200 bg-white hover:bg-gray-50 rounded-lg py-1.5 text-[12px] font-bold transition-colors disabled:opacity-50"
                >Tolak</button>
              </div>
            </div>
          </div>
          
          <router-link to="/leaves">
            <button class="w-full mt-4 border border-dashed border-gray-300 text-gray-500 py-2.5 rounded-xl text-[12px] font-bold hover:bg-white hover:border-gray-400 transition-colors">
              Lihat Semua Permohonan
            </button>
          </router-link>
        </div>
      </div>
    </div>
  </div>
</template>
