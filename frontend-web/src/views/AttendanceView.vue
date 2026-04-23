<script setup lang="ts">
import { ref, onMounted, h, computed, watch } from 'vue'
import { toast } from 'vue-sonner'
import { Pencil, Trash2, Download, CalendarClock, Plus, Filter, FileSpreadsheet } from 'lucide-vue-next'
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
import { useAuthStore } from '@/stores/auth'

const masterData = useMasterDataStore()
const authStore = useAuthStore()

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
    header: 'FOTO BUKTI',
    cell: ({ row }: any) => {
        const item = row.original
        return h('div', { class: 'flex items-center gap-2' }, [
            item.clockInPhoto ? h('div', {
                onClick: () => openPreview(item.clockInPhoto),
                class: 'w-10 h-10 rounded-lg overflow-hidden border border-gray-200 cursor-pointer hover:ring-2 hover:ring-primary/20 transition-all bg-gray-50 flex items-center justify-center group relative'
            }, [
                h('img', { src: `${apiClient.defaults.baseURL}${item.clockInPhoto}`, class: 'w-full h-full object-cover group-hover:scale-110 transition-transform' }),
                h('div', { class: 'absolute inset-0 bg-black/5 opacity-0 group-hover:opacity-100 transition-opacity' }),
                h('div', { class: 'absolute bottom-0 right-0 bg-emerald-500 text-[8px] text-white px-1 font-bold' }, 'IN')
            ]) : null,
            item.clockOutPhoto ? h('div', {
                onClick: () => openPreview(item.clockOutPhoto),
                class: 'w-10 h-10 rounded-lg overflow-hidden border border-gray-200 cursor-pointer hover:ring-2 hover:ring-primary/20 transition-all bg-gray-50 flex items-center justify-center group relative'
            }, [
                h('img', { src: `${apiClient.defaults.baseURL}${item.clockOutPhoto}`, class: 'w-full h-full object-cover group-hover:scale-110 transition-transform' }),
                h('div', { class: 'absolute inset-0 bg-black/5 opacity-0 group-hover:opacity-100 transition-opacity' }),
                h('div', { class: 'absolute bottom-0 right-0 bg-primary text-[8px] text-white px-1 font-bold' }, 'OUT')
            ]) : null,
            (!item.clockInPhoto && !item.clockOutPhoto) ? h('span', { class: 'text-[11px] text-gray-400 font-medium italic' }, 'Tanpa Foto') : null
        ])
    }
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

const exportCSV = async () => {
  try {
    let url = '/attendance/export-csv?'
    if (selectedBranch.value && selectedBranch.value !== 'all') {
      url += `&branch_id=${selectedBranch.value}`
    }
    if (filterType.value === 'month' && selectedMonth.value) {
      url += `&month=${selectedMonth.value}`
    } else if (filterType.value === 'year' && selectedYear.value) {
      url += `&month=${selectedYear.value}`
    }
    
    const response = await apiClient.get(url, { responseType: 'blob' })
    const blob = new Blob([response.data], { type: 'text/csv' })
    const downloadUrl = window.URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = downloadUrl
    link.setAttribute('download', `laporan_kehadiran_${new Date().getTime()}.csv`)
    document.body.appendChild(link)
    link.click()
    link.remove()
    window.URL.revokeObjectURL(downloadUrl)
  } catch (error) {
    toast.error('Gagal mengunduh laporan kehadiran.')
  }
}

onMounted(() => {
  fetchAttendance()
  fetchEmployeesForFilter()
  masterData.fetchBranches()
})
</script>

<template>
  <div class="space-y-6">
    <!-- Premium Header -->
    <div class="flex flex-col md:flex-row md:items-center justify-between gap-6">
      <div>
        <h1 class="text-3xl font-extrabold text-slate-900 tracking-tight flex items-center gap-3">
            Laporan Kehadiran
        </h1>
        <p class="text-[14px] font-medium text-slate-500 mt-1.5 uppercase tracking-widest flex items-center gap-2">
          Monitoring Presensi & Jam Kerja
        </p>
      </div>
      
      <div class="flex items-center gap-3 flex-wrap">
        <!-- Branch Filter -->
        <Select v-model="selectedBranch" @update:modelValue="fetchAttendance">
          <SelectTrigger class="w-[160px] h-10 rounded-xl border-none bg-white shadow-lg shadow-slate-100/50 font-bold px-4 text-slate-600 focus:ring-2 focus:ring-primary/20 transition-all">
            <SelectValue placeholder="Semua Cabang" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Semua Cabang</SelectItem>
            <SelectItem v-for="b in masterData.branches" :key="b.id" :value="b.id">{{ b.name }}</SelectItem>
          </SelectContent>
        </Select>

        <!-- Type Filter -->
        <Select v-model="filterType" @update:modelValue="fetchAttendance">
          <SelectTrigger class="w-[110px] h-10 rounded-xl border-none bg-white shadow-lg shadow-slate-100/50 font-bold px-4 text-slate-600 focus:ring-2 focus:ring-primary/20 transition-all">
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
            class="h-10 border-none bg-white shadow-lg shadow-slate-100/50 text-slate-600 rounded-xl text-[13px] font-bold px-4 focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all"
          />
          <input
            v-if="filterType === 'year'"
            type="number"
            min="2000"
            max="2099"
            step="1"
            v-model="selectedYear"
            @change="fetchAttendance"
            class="h-10 w-24 border-none bg-white shadow-lg shadow-slate-100/50 text-slate-600 rounded-xl text-[13px] font-bold px-4 focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all"
          />
        </div>

        <!-- Export CSV -->
        <Button variant="outline" @click="exportCSV" class="h-10 px-4 rounded-xl font-bold border-2 border-slate-50 bg-white shadow-lg shadow-slate-100/50 text-slate-600 gap-2 hover:bg-slate-50 transition-all active:scale-95">
          <Download class="w-4 h-4" /> EXPORT
        </Button>

        <Button @click="openAddModal" class="gap-2 shadow-xl shadow-primary/20 rounded-xl h-10 px-5 font-bold bg-primary hover:bg-primary/90 transition-all hover:scale-105 active:scale-95">
          <Plus class="w-4 h-4" /> INPUT MANUAL
        </Button>
      </div>
    </div>

    <!-- Stats Cards -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-6">
      <!-- Card 1 -->
      <div class="group bg-white p-6 rounded-2xl border border-slate-200 shadow-[0_4px_20px_rgba(0,0,0,0.03)] hover:shadow-[0_10px_30px_rgba(153,0,0,0.05)] transition-all duration-500">
        <div class="flex items-start justify-between">
          <p class="text-[11px] font-bold text-slate-500 uppercase tracking-widest leading-tight">Total Data</p>
          <div class="p-2 bg-primary/5 rounded-xl text-primary transition-transform group-hover:scale-110">
            <FileSpreadsheet class="w-4 h-4" />
          </div>
        </div>
        <div>
          <h3 class="text-2xl font-black text-slate-900 mt-3">{{ attendanceStats.total }}</h3>
          <p class="text-[10px] font-bold text-slate-400 mt-1 uppercase">Records</p>
        </div>
      </div>
      
      <!-- Card 2 -->
      <div class="group bg-white p-6 rounded-2xl border border-slate-200 shadow-[0_4px_20px_rgba(0,0,0,0.03)] hover:shadow-[0_10px_30px_rgba(16,185,129,0.05)] transition-all duration-500">
        <div class="flex items-start justify-between">
          <p class="text-[11px] font-bold text-slate-500 uppercase tracking-widest leading-tight">Tepat Waktu</p>
          <div class="p-2 bg-emerald-50 text-emerald-500 rounded-xl transition-transform group-hover:scale-110">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="3">
              <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7" />
            </svg>
          </div>
        </div>
        <div>
          <h3 class="text-2xl font-black text-slate-900 mt-3">{{ attendanceStats.onTime }}</h3>
          <p class="text-[10px] font-bold text-emerald-500 mt-1 uppercase tracking-tighter">On Schedule</p>
        </div>
      </div>
      
      <!-- Card 3 -->
      <div class="group bg-white p-6 rounded-2xl border border-slate-200 shadow-[0_4px_20px_rgba(0,0,0,0.03)] hover:shadow-[0_10px_30px_rgba(245,158,11,0.05)] transition-all duration-500">
        <div class="flex items-start justify-between">
          <p class="text-[11px] font-bold text-slate-500 uppercase tracking-widest leading-tight">Terlambat</p>
          <div class="p-2 bg-orange-50 text-orange-500 rounded-xl transition-transform group-hover:scale-110">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="3">
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4l3 3" />
            </svg>
          </div>
        </div>
        <div>
          <h3 class="text-2xl font-black text-slate-900 mt-3">{{ attendanceStats.late }}</h3>
          <p class="text-[10px] font-bold text-orange-500 mt-1 uppercase tracking-tighter">Delayed</p>
        </div>
      </div>
      
      <!-- Card 4 -->
      <div class="group bg-white p-6 rounded-2xl border border-slate-200 shadow-[0_4px_20px_rgba(0,0,0,0.03)] hover:shadow-[0_10px_30px_rgba(239,68,68,0.05)] transition-all duration-500">
        <div class="flex items-start justify-between">
          <p class="text-[11px] font-bold text-slate-500 uppercase tracking-widest leading-tight">Absen/Cuti</p>
          <div class="p-2 bg-red-50 text-red-500 rounded-xl transition-transform group-hover:scale-110">
            <Plus class="w-4 h-4 rotate-45" />
          </div>
        </div>
        <div>
          <h3 class="text-2xl font-black text-slate-900 mt-3">{{ attendanceStats.absent + attendanceStats.permitted }}</h3>
          <p class="text-[10px] font-bold text-red-500 mt-1 uppercase tracking-tighter">Off Work</p>
        </div>
      </div>
    </div>

    <!-- DataTable Instance -->
    <div class="bg-white rounded-[2.5rem] border border-slate-200 shadow-2xl shadow-slate-100/50 overflow-hidden">
      <DataTable :data="displayData" :columns="columns" :isLoading="isLoading">
        <template #headerTitle>
          <h2 class="text-[16px] font-black text-slate-900 uppercase tracking-tighter ml-2">Catatan Harian Log Presensi</h2>
        </template>
      </DataTable>
    </div>

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
      <DialogContent class="sm:max-w-xl rounded-[2rem] md:rounded-[3rem] p-0 overflow-hidden border-none shadow-2xl max-h-[95vh] flex flex-col">
        <div class="bg-slate-900 p-8 md:p-10 text-white relative shrink-0">
            <DialogHeader>
              <DialogTitle class="text-xl md:text-2xl font-black">{{ isEditMode ? 'Edit Log Kehadiran' : 'Input Kehadiran Manual' }}</DialogTitle>
              <DialogDescription class="text-slate-400 font-bold mt-2 uppercase text-[10px] md:text-[11px] tracking-widest border-l-4 border-primary pl-4">
                Bypass Face-ID untuk memperbaiki data presensi karyawan secara administratif.
              </DialogDescription>
            </DialogHeader>
        </div>

        <div class="p-6 md:p-10 bg-white space-y-6 overflow-y-auto custom-scrollbar">
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
        
        <DialogFooter class="p-8 md:p-10 pt-0 bg-white grid grid-cols-2 gap-4 shrink-0">
          <Button variant="ghost" @click="closeAddModal" :disabled="isSubmitting" class="rounded-2xl h-12 md:h-14 font-black text-slate-400 border border-slate-100 hover:bg-slate-50">BATAL</Button>
          <Button @click="saveManualData" :disabled="isSubmitting" class="bg-primary hover:bg-primary/90 text-white rounded-2xl h-12 md:h-14 font-black shadow-xl shadow-primary/20 transform active:scale-95 transition-all">
            {{ isSubmitting ? 'MENYIMPAN...' : 'SIMPAN OVERRIDE' }}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>

  </div>
</template>
