<script setup lang="ts">
import { ref, onMounted, h, computed, watch } from 'vue'
import { toast } from 'vue-sonner'
import { Pencil, Trash2 } from 'lucide-vue-next'
import apiClient from '@/api/axios'
import DataTable from '@/components/DataTable.vue'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { useMasterDataStore } from '@/stores/masterData'

const masterData = useMasterDataStore()

const isLoading = ref(true)
const displayData = ref<any[]>([])
const employeeOptions = ref<any[]>([])
const selectedBranch = ref<string>('all')
const filterType = ref<string>('month')
const selectedMonth = ref<string>(new Date().toISOString().slice(0, 7)) // default current month: YYYY-MM
const selectedYear = ref<string>(new Date().getFullYear().toString())

const attendanceStats = computed(() => {
  const data = displayData.value
  let onTime = 0, late = 0, permitted = 0, absent = 0
  
  data.forEach(item => {
    const s = (item.status || '').toUpperCase()
    if (s === 'ON_TIME' || s === 'PRESENT') onTime++
    else if (s === 'LATE') late++
    else if (['SICK', 'LEAVE', 'PERMISSION'].includes(s)) permitted++
    else if (s === 'ABSENT') absent++
  })

  return {
    total: data.length,
    onTime,
    late,
    permitted,
    absent
  }
})

const isModalOpen = ref(false)
const isEditMode = ref(false)
const isSubmitting = ref(false)

const currentForm = ref({
  id: '',
  employee_id: '',
  date: new Date().toISOString().split('T')[0],
  clock_in_time: '08:00',
  clock_out_time: '17:00',
  status: 'PRESENT',
  notes: ''
})

const dummyData = [
  { id: 1, date: '24/10/2026', name: 'Sarah Jenkins', role: 'UX Designer', checkIn: '09:15', checkOut: '18:00', total: '8j 45m', status: 'Terlambat (15m)', avatar: 'https://i.pravatar.cc/150?u=sarah' },
  { id: 2, date: '24/10/2026', name: 'Michael Foster', role: 'Front-end Dev', checkIn: '08:55', checkOut: '17:30', total: '8j 35m', status: 'Tepat Waktu', avatar: 'https://i.pravatar.cc/150?u=michael' },
  { id: 3, date: '24/10/2026', name: 'Dries Vincent', role: 'Manajer Proyek', checkIn: '08:30', checkOut: '16:45', total: '8j 15m', status: 'Pulang Cepat', avatar: 'https://i.pravatar.cc/150?u=dries' },
  { id: 4, date: '24/10/2026', name: 'Lindsay Walton', role: 'Marketing Lead', checkIn: '09:00', checkOut: '18:00', total: '9j 00m', status: 'Tepat Waktu', avatar: 'https://i.pravatar.cc/150?u=lindsay' },
  { id: 5, date: '24/10/2026', name: 'Courtney Henry', role: 'Desainer', checkIn: '09:05', checkOut: '18:10', total: '9j 05m', status: 'Tepat Waktu', avatar: 'https://i.pravatar.cc/150?u=courtney' },
]

// Photo Preview State
const isPreviewOpen = ref(false)
const previewImage = ref('')
const openPreview = (url: string) => {
  if (!url) return
  previewImage.value = `${apiClient.defaults.baseURL}${url}`
  isPreviewOpen.value = true
}

// Define Columns for TanStack Table
const columns = [
  {
    accessorKey: 'date',
    header: 'TANGGAL',
    cell: (info: any) => h('span', { class: 'text-gray-500' }, info.getValue())
  },
  {
    accessorFn: (row: any) => row.name || '-',
    id: 'name',
    header: 'KARYAWAN',
    cell: ({ row }: any) => {
       const user = row.original
       return h('div', { class: 'flex flex-col' }, [
         h('p', { class: 'font-bold text-gray-900 leading-tight' }, user.name),
         h('p', { class: 'text-[12px] text-gray-500' }, user.role)
       ])
    }
  },
  {
    accessorKey: 'checkIn',
    header: 'JAM MASUK',
    cell: (info: any) => h('span', { class: 'font-medium text-gray-700' }, info.getValue())
  },
  {
    accessorKey: 'checkOut',
    header: 'JAM KELUAR',
    cell: (info: any) => h('span', { class: 'font-medium text-gray-700' }, info.getValue())
  },
  {
    accessorKey: 'total',
    header: 'TOTAL JAM',
    cell: (info: any) => h('span', { class: 'font-bold text-gray-900' }, info.getValue())
  },
  {
    accessorKey: 'status',
    header: 'STATUS',
    cell: ({ getValue }: any) => {
        const val = getValue() as string || ''
        let classes = 'bg-[#fef3c7] text-[#92400e]' // warning outline
        if (val.toUpperCase() === 'ON_TIME' || val.toUpperCase() === 'PRESENT') classes = 'bg-[#dcfce7] text-[#166534]'
        else if (val.toUpperCase() === 'LATE') classes = 'bg-[#ffedd5] text-[#c2410c]'
        else if (['SICK', 'LEAVE', 'PERMISSION'].includes(val.toUpperCase())) classes = 'bg-[#e0e7ff] text-[#3730a3]'
        else if (val.toUpperCase() === 'ABSENT') classes = 'bg-[#fef2f2] text-[#b91c1c] ring-1 ring-[#b91c1c]/30'
        return h('span', { class: `${classes} px-2.5 py-1 rounded-full text-[12px] font-bold` }, val || 'UNKNOWN')
    }
  },
  {
    accessorKey: 'branch',
    header: 'CABANG',
    cell: (info: any) => h('span', { class: 'text-gray-500 font-medium text-[13px]' }, info.getValue() || '-')
  },
  {
    accessorKey: 'notes',
    header: 'CATATAN',
    cell: (info: any) => h('span', { class: 'text-gray-500 text-[13px]' }, info.getValue() || '-')
  },
  {
    id: 'photo',
    header: 'FOTO BUKTI'
  },
  {
    id: 'actions',
    header: 'AKSI',
    cell: ({ row }: any) => {
        const item = row.original
        return h('div', { class: 'flex gap-2' }, [
          h(Button, {
            variant: 'ghost',
            size: 'sm',
            onClick: () => openEditModal(item),
            class: 'h-8 px-2 text-primary hover:text-primary hover:bg-primary/5'
          }, () => h(Pencil, { class: 'w-4 h-4' })),
          h(Button, {
            variant: 'ghost',
            size: 'sm',
            onClick: () => deleteAttendance(item.id),
            class: 'h-8 px-2 text-red-600 hover:text-red-700 hover:bg-red-50'
          }, () => h(Trash2, { class: 'w-4 h-4' }))
        ])
    },
    enableSorting: false
  }
]

const openAddModal = () => {
  isEditMode.value = false
  currentForm.value = {
    id: '',
    employee_id: '',
    date: new Date().toISOString().split('T')[0],
    clock_in_time: '08:00',
    clock_out_time: '17:00',
    status: 'PRESENT',
    notes: ''
  }
  isModalOpen.value = true
}

const openEditModal = (item: any) => {
  isEditMode.value = true
  
  // parse dates specifically
  const fmtTime = (iso: string) => {
    if (!iso) return ''
    const d = new Date(iso)
    if (isNaN(d.getTime())) return ''
    return `${String(d.getUTCHours()).padStart(2, '0')}.${String(d.getUTCMinutes()).padStart(2, '0')}`
  }
  const dateStr = item._raw.clock_in_time ? new Date(item._raw.clock_in_time).toISOString().split('T')[0] : ''
  const inTimeStr = item._raw.clock_in_time ? fmtTime(item._raw.clock_in_time) : ''
  const outTimeStr = item._raw.clock_out_time ? fmtTime(item._raw.clock_out_time) : ''

  currentForm.value = {
    id: item.id,
    employee_id: item._raw.employee_id,
    date: dateStr,
    clock_in_time: inTimeStr || '',
    clock_out_time: outTimeStr || '',
    status: item._raw.status || 'PRESENT',
    notes: item._raw.notes || ''
  }
  isModalOpen.value = true
}

const closeAddModal = () => {
  isModalOpen.value = false
}

const deleteAttendance = async (id: string) => {
  if (!confirm('Hapus log kehadiran ini? Operasi ini permanen.')) return
  try {
    await apiClient.delete(`/attendance/${id}`)
    toast.success('Log kehadiran berhasil dihapus!')
    fetchAttendance()
  } catch(e: any) {
    toast.error('Gagal menghapus: ' + (e.response?.data?.message || e.message))
  }
}

const saveManualData = async () => {
  isSubmitting.value = true
  try {
    // combine Date + HH:mm strings into RFC3339
    const inDateObj = new Date(`${currentForm.value.date}T${currentForm.value.clock_in_time}:00Z`)
    let outDateObj: Date | null = null
    if (currentForm.value.clock_out_time) {
      outDateObj = new Date(`${currentForm.value.date}T${currentForm.value.clock_out_time}:00Z`)
    }

    const payload = {
      employee_id: currentForm.value.employee_id,
      clock_in_time: inDateObj.toISOString(),
      clock_out_time: outDateObj ? outDateObj.toISOString() : null,
      status: currentForm.value.status,
      notes: currentForm.value.notes
    }

    if (isEditMode.value) {
      await apiClient.put(`/attendance/${currentForm.value.id}`, payload)
      toast.success('Kehadiran berhasil diperbarui!')
    } else {
      await apiClient.post('/attendance/manual', payload)
      toast.success('Kehadiran manual berhasil ditambahkan!')
    }
    closeAddModal()
    fetchAttendance()
  } catch (error: any) {
    toast.error('Gagal menyimpan data: ' + (error.response?.data?.message || error.message))
  } finally {
    isSubmitting.value = false
  }
}

const fetchAttendance = async () => {
  try {
    let url = '/attendance/all?limit=50'
    if (selectedBranch.value && selectedBranch.value !== 'all') {
      url += `&branch_id=${selectedBranch.value}`
    }
    if (filterType.value === 'month' && selectedMonth.value) {
      url += `&month=${selectedMonth.value}`
    } else if (filterType.value === 'year' && selectedYear.value) {
      url += `&month=${selectedYear.value}`
    }
    const res = await apiClient.get(url)
    if (res.data?.data && res.data.data.length > 0) {
      displayData.value = res.data.data.map((item: any) => {
        const clockIn = item.clock_in_time ? new Date(item.clock_in_time) : null
        const clockOut = item.clock_out_time ? new Date(item.clock_out_time) : null
        let totalStr = '-'
        if (clockIn && clockOut) {
          const diffMs = clockOut.getTime() - clockIn.getTime()
          const totalH = Math.floor(diffMs / 3600000)
          const totalM = Math.floor((diffMs % 3600000) / 60000)
          totalStr = `${totalH}j ${totalM}m`
        }
        return {
          id: item.id,
          date: clockIn ? clockIn.toLocaleDateString('id-ID') : 'N/A',
          name: item.employee?.first_name || 'Karyawan',
          role: item.employee?.job_position?.title || '-',
          checkIn: clockIn ? `${String(clockIn.getUTCHours()).padStart(2, '0')}.${String(clockIn.getUTCMinutes()).padStart(2, '0')}` : '-',
          checkOut: clockOut ? `${String(clockOut.getUTCHours()).padStart(2, '0')}.${String(clockOut.getUTCMinutes()).padStart(2, '0')}` : '-',
          total: totalStr,
          status: item.status || 'PRESENT',
          branch: item.employee?.branch?.name || '-',
          notes: item.notes || '-',
          avatar: `https://i.pravatar.cc/150?u=${item.employee_id}`,
          clockInPhoto: item.clock_in_photo_url,
          clockOutPhoto: item.clock_out_photo_url,
          _raw: item
        }
      })
    } else {
      displayData.value = []
    }
  } catch (e: any) {
    console.error('Failed to fetch from API', e)
    displayData.value = []
  } finally {
    isLoading.value = false
  }
}

const fetchEmployeesForFilter = async () => {
  try {
    const res = await apiClient.get('/employees')
    if (res.data?.data) {
      employeeOptions.value = res.data.data
    }
  } catch (error) {
    console.error('Failed fetching core employee references', error)
  }
}

const exportCSV = () => {
  let url = `${apiClient.defaults.baseURL}/attendance/export-csv?`
  if (selectedBranch.value && selectedBranch.value !== 'all') {
    url += `&branch_id=${selectedBranch.value}`
  }
  if (filterType.value === 'month' && selectedMonth.value) {
    url += `&month=${selectedMonth.value}`
  } else if (filterType.value === 'year' && selectedYear.value) {
    url += `&month=${selectedYear.value}`
  }
  window.open(url, '_blank')
}

onMounted(() => {
  fetchAttendance()
  fetchEmployeesForFilter()
  masterData.fetchBranches()
})
</script>

<template>
  <div class="space-y-6">
    <!-- Header Page -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h1 class="text-[22px] font-bold text-gray-900">Laporan Kehadiran</h1>
        <p class="text-[14px] text-gray-500 mt-1">Lacak jam kerja karyawan, check-in, dan status kehadiran.</p>
      </div>
      
      <div class="flex items-center gap-3 flex-wrap">
        <!-- Branch Filter -->
        <Select v-model="selectedBranch" @update:modelValue="fetchAttendance">
          <SelectTrigger class="w-[160px] h-9 text-[13px] bg-white text-gray-700">
            <SelectValue placeholder="Semua Cabang" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Semua Cabang</SelectItem>
            <SelectItem v-for="b in masterData.branches" :key="b.id" :value="b.id">{{ b.name }}</SelectItem>
          </SelectContent>
        </Select>

        <!-- Type Filter -->
        <Select v-model="filterType" @update:modelValue="fetchAttendance">
          <SelectTrigger class="w-[100px] h-9 text-[13px] bg-white text-gray-700">
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="month">Bulanan</SelectItem>
            <SelectItem value="year">Tahunan</SelectItem>
          </SelectContent>
        </Select>

        <!-- Date Filter -->
        <div class="relative">
          <input
            v-if="filterType === 'month'"
            type="month"
            v-model="selectedMonth"
            @change="fetchAttendance"
            class="h-9 border border-gray-300 bg-white text-gray-700 rounded-lg text-[13px] px-3 focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary shadow-sm"
          />
          <input
            v-if="filterType === 'year'"
            type="number"
            min="2000"
            max="2099"
            step="1"
            v-model="selectedYear"
            @change="fetchAttendance"
            class="h-9 w-24 border border-gray-300 bg-white text-gray-700 rounded-lg text-[13px] px-3 focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary shadow-sm"
          />
        </div>

        <!-- Export CSV -->
        <Button variant="outline" class="flex items-center gap-2 h-9 px-3" @click="exportCSV">
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12" />
          </svg>
          <span class="hidden sm:inline">Ekspor CSV</span>
        </Button>
        <Button @click="openAddModal" class="h-9 px-4">
          Tambah Data Manual
        </Button>
      </div>
    </div>

    <!-- Stats Cards -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
      <!-- Card 1 -->
      <div class="bg-white p-5 rounded-xl border border-gray-200 shadow-sm flex flex-col justify-between">
        <div class="flex items-start justify-between">
          <p class="text-[13px] font-medium text-gray-600 leading-tight w-20">Total Data</p>
          <div class="w-8 h-8 rounded-lg bg-primary/5 text-primary flex items-center justify-center">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
            </svg>
          </div>
        </div>
        <div>
          <h3 class="text-2xl font-bold text-gray-900 mt-2 mb-3">{{ attendanceStats.total }}</h3>
          <div class="flex items-center gap-2 text-[12px]">
            <span class="text-gray-500">Record kehadiran dari filter</span>
          </div>
        </div>
      </div>
      
      <!-- Card 2 -->
      <div class="bg-white p-5 rounded-xl border border-gray-200 shadow-sm flex flex-col justify-between">
        <div class="flex items-start justify-between">
          <p class="text-[13px] font-medium text-gray-600 leading-tight w-24">Tepat Waktu</p>
          <div class="w-8 h-8 rounded-lg bg-emerald-50 text-emerald-500 flex items-center justify-center">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
        </div>
        <div>
          <h3 class="text-2xl font-bold text-gray-900 mt-2 mb-3">{{ attendanceStats.onTime }}</h3>
          <div class="flex items-center gap-2 text-[12px]">
            <span class="text-gray-500">Bekerja Sesuai Jadwal</span>
          </div>
        </div>
      </div>
      
      <!-- Card 3 -->
      <div class="bg-white p-5 rounded-xl border border-gray-200 shadow-sm flex flex-col justify-between">
        <div class="flex items-start justify-between">
          <p class="text-[13px] font-medium text-gray-600 leading-tight w-20">Terlambat</p>
          <div class="w-8 h-8 rounded-lg bg-orange-50 text-orange-500 flex items-center justify-center">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
        </div>
        <div>
          <h3 class="text-2xl font-bold text-gray-900 mt-2 mb-3">{{ attendanceStats.late }}</h3>
          <div class="flex items-center gap-2 text-[12px]">
            <span class="text-gray-500">Datang melewati jadwal</span>
          </div>
        </div>
      </div>
      
      <!-- Card 4 -->
      <div class="bg-white p-5 rounded-xl border border-gray-200 shadow-sm flex flex-col justify-between">
        <div class="flex items-start justify-between">
          <p class="text-[13px] font-medium text-gray-600 leading-tight">Mangkir & Cuti</p>
          <div class="w-8 h-8 rounded-lg bg-red-50 text-red-500 flex items-center justify-center">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
          </div>
        </div>
        <div>
          <h3 class="text-2xl font-bold text-gray-900 mt-2 mb-3">{{ attendanceStats.absent + attendanceStats.permitted }}</h3>
          <div class="flex items-center gap-2 text-[12px]">
            <span class="text-gray-500">Mangkir: {{ attendanceStats.absent }}, Lainnya: {{ attendanceStats.permitted }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- DataTable Instance -->
    <DataTable :data="displayData" :columns="columns" :isLoading="isLoading">
      <template #headerTitle>
        <h2 class="text-[16px] font-bold text-gray-900">Catatan Harian</h2>
      </template>
      
      <template #cell-photo="{ row }">
        <div class="flex items-center gap-2">
            <template v-if="row.clockInPhoto">
                <div 
                    @click="openPreview(row.clockInPhoto)"
                    class="w-10 h-10 rounded-lg overflow-hidden border border-gray-200 cursor-pointer hover:ring-2 hover:ring-primary/20 transition-all bg-gray-50 flex items-center justify-center group relative"
                >
                    <img :src="`${apiClient.defaults.baseURL}${row.clockInPhoto}`" class="w-full h-full object-cover group-hover:scale-110 transition-transform" />
                    <div class="absolute inset-0 bg-black/5 opacity-0 group-hover:opacity-100 transition-opacity"></div>
                    <div class="absolute bottom-0 right-0 bg-emerald-500 text-[8px] text-white px-1 font-bold">IN</div>
                </div>
            </template>
            <template v-if="row.clockOutPhoto">
                <div 
                    @click="openPreview(row.clockOutPhoto)"
                    class="w-10 h-10 rounded-lg overflow-hidden border border-gray-200 cursor-pointer hover:ring-2 hover:ring-primary/20 transition-all bg-gray-50 flex items-center justify-center group relative"
                >
                    <img :src="`${apiClient.defaults.baseURL}${row.clockOutPhoto}`" class="w-full h-full object-cover group-hover:scale-110 transition-transform" />
                    <div class="absolute inset-0 bg-black/5 opacity-0 group-hover:opacity-100 transition-opacity"></div>
                    <div class="absolute bottom-0 right-0 bg-indigo-500 text-[8px] text-white px-1 font-bold">OUT</div>
                </div>
            </template>
            <span v-if="!row.clockInPhoto && !row.clockOutPhoto" class="text-[11px] text-gray-400 font-medium italic">Tanpa Foto</span>
        </div>
      </template>
    </DataTable>

    <!-- Photo Preview Dialog -->
    <Dialog v-model:open="isPreviewOpen">
        <DialogContent class="sm:max-w-3xl p-0 bg-transparent border-none">
            <div class="relative group">
                <img :src="previewImage" class="w-full h-auto rounded-2xl shadow-2xl border-4 border-white" />
                <Button 
                    variant="ghost" 
                    size="icon" 
                    @click="isPreviewOpen = false"
                    class="absolute -top-12 right-0 text-white hover:bg-white/10"
                >
                    <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" /></svg>
                </Button>
            </div>
        </DialogContent>
    </Dialog>

    <!-- UI Dialog (Manual Overrides) -->
    <Dialog v-model:open="isModalOpen">
      <DialogContent class="sm:max-w-xl">
        <DialogHeader>
          <DialogTitle class="text-xl">{{ isEditMode ? 'Edit Log Kehadiran' : 'Input Kehadiran Manual' }}</DialogTitle>
          <DialogDescription>
            Bypass Face-ID untuk memperbaiki data presensi karyawan secara administratif.
          </DialogDescription>
        </DialogHeader>

        <div class="grid gap-4 py-4">
          <div class="grid gap-2">
            <label class="text-[13px] font-medium text-gray-700">Pilih Karyawan</label>
            <Select v-model="currentForm.employee_id" :disabled="isEditMode">
              <SelectTrigger>
                <SelectValue placeholder="Pilih Karyawan..." />
              </SelectTrigger>
              <SelectContent>
                <SelectItem v-for="emp in employeeOptions" :key="emp.id" :value="emp.id">
                  {{ emp.first_name }} ({{ emp.user?.email }})
                </SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div class="grid gap-2">
            <label class="text-[13px] font-medium text-gray-700">Tanggal</label>
            <Input v-model="currentForm.date" type="date" />
          </div>

          <div class="grid grid-cols-2 gap-4">
             <div class="grid gap-2">
                <label class="text-[13px] font-medium text-gray-700">Jam Masuk</label>
                <Input v-model="currentForm.clock_in_time" type="time" />
              </div>
              <div class="grid gap-2">
                <label class="text-[13px] font-medium text-gray-700">Jam Keluar</label>
                <Input v-model="currentForm.clock_out_time" type="time" />
              </div>
          </div>

          <div class="grid gap-2">
            <label class="text-[13px] font-medium text-gray-700">Status Penyelesaian</label>
            <Select v-model="currentForm.status">
              <SelectTrigger>
                <SelectValue placeholder="Status Kehadiran" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="ON_TIME">Tepat Waktu (ON_TIME)</SelectItem>
                <SelectItem value="LATE">Terlambat (LATE)</SelectItem>
                <SelectItem value="ABSENT">Mangkir (ABSENT)</SelectItem>
                <SelectItem value="LEAVE">Cuti/Izin (LEAVE)</SelectItem>
                <SelectItem value="SICK">Sakit (SICK)</SelectItem>
                <SelectItem value="PERMISSION">Izin Tanpa Dibayar (PERMISSION)</SelectItem>
              </SelectContent>
            </Select>
          </div>
          
          <div class="grid gap-2">
            <label class="text-[13px] font-medium text-gray-700">Catatan Khusus</label>
            <Input v-model="currentForm.notes" placeholder="e.g. Lupa absen pulang, dikoreksi manual" />
          </div>

        </div>
        
        <DialogFooter>
          <Button variant="outline" @click="closeAddModal">Batal</Button>
          <Button @click="saveManualData" :disabled="isSubmitting">
            {{ isSubmitting ? 'Menyimpan...' : 'Simpan Override' }}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>

  </div>
</template>
