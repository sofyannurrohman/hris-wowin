<script setup lang="ts">
import { ref, onMounted, h } from 'vue'
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

const isLoading = ref(true)
const displayData = ref<any[]>([])
const employeeOptions = ref<any[]>([])

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

// Define Columns for TanStack Table
const columns = [
  {
    accessorKey: 'date',
    header: 'TANGGAL',
    cell: (info: any) => h('span', { class: 'text-gray-500' }, info.getValue())
  },
  {
    accessorFn: (row: any) => `${row.name} ${row.role}`,
    id: 'name',
    header: 'KARYAWAN',
    cell: ({ row }: any) => {
       const user = row.original
       return h('div', { class: 'flex items-center gap-3' }, [
         h('img', { src: user.avatar, class: 'w-8 h-8 rounded-full border border-gray-200 object-cover' }),
         h('div', {}, [
           h('p', { class: 'font-bold text-gray-900 leading-tight' }, user.name),
           h('p', { class: 'text-[12px] text-gray-500' }, user.role)
         ])
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
        else if (val.toUpperCase() === 'LATE') classes = 'bg-[#fee2e2] text-[#991b1b]'
        return h('span', { class: `${classes} px-2.5 py-1 rounded-full text-[12px] font-bold` }, val || 'UNKNOWN')
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
            class: 'h-8 px-2 text-blue-600 hover:text-blue-700 hover:bg-blue-50'
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
  const dateStr = item._raw.ClockInTime ? new Date(item._raw.ClockInTime).toISOString().split('T')[0] : ''
  const inTimeStr = item._raw.ClockInTime ? new Date(item._raw.ClockInTime).toLocaleTimeString('en-GB', { hour: "2-digit", minute: "2-digit" }) : ''
  const outTimeStr = item._raw.ClockOutTime ? new Date(item._raw.ClockOutTime).toLocaleTimeString('en-GB', { hour: "2-digit", minute: "2-digit" }) : ''

  currentForm.value = {
    id: item.id,
    employee_id: item._raw.EmployeeID,
    date: dateStr,
    clock_in_time: inTimeStr || '',
    clock_out_time: outTimeStr || '',
    status: item._raw.Status || 'PRESENT',
    notes: item._raw.Notes || ''
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
    const res = await apiClient.get('/attendance/all?limit=50')
    if (res.data?.data && res.data.data.length > 0) {
      displayData.value = res.data.data.map((item: any) => {
        const clockIn = item.ClockInTime ? new Date(item.ClockInTime) : null
        const clockOut = item.ClockOutTime ? new Date(item.ClockOutTime) : null
        let totalStr = '-'
        if (clockIn && clockOut) {
          const diffMs = clockOut.getTime() - clockIn.getTime()
          const totalH = Math.floor(diffMs / 3600000)
          const totalM = Math.floor((diffMs % 3600000) / 60000)
          totalStr = `${totalH}j ${totalM}m`
        }
        return {
          id: item.ID,
          date: clockIn ? clockIn.toLocaleDateString('id-ID') : 'N/A',
          name: item.Employee?.FirstName || 'Karyawan',
          role: item.Employee?.JobPosition?.Name || '-',
          checkIn: clockIn ? clockIn.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }) : '-',
          checkOut: clockOut ? clockOut.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }) : '-',
          total: totalStr,
          status: item.Status || 'PRESENT',
          avatar: `https://i.pravatar.cc/150?u=${item.EmployeeID}`,
          _raw: item
        }
      })
    } else {
      displayData.value = dummyData
    }
  } catch (e) {
    console.error('Failed to fetch from API, falling back to dummy data')
    displayData.value = dummyData
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

onMounted(() => {
  fetchAttendance()
  fetchEmployeesForFilter()
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
      
      <div class="flex items-center gap-3">
        <div class="relative bg-white border border-gray-300 text-gray-700 rounded-lg text-[13px] px-3 py-2 flex items-center gap-2 cursor-pointer shadow-sm">
          <svg class="w-4 h-4 text-gray-500" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
          </svg>
          01/10/2026 - 31/10/2026
          <svg class="w-3 h-3 text-gray-400 ml-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
          </svg>
        </div>
        <Button variant="outline" class="flex items-center gap-2 h-9 px-3">
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12" />
          </svg>
          <span class="hidden sm:inline">Ekspor ke Excel</span>
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
          <p class="text-[13px] font-medium text-gray-600 leading-tight w-20">Total Karyawan</p>
          <div class="w-8 h-8 rounded-lg bg-blue-50 text-blue-600 flex items-center justify-center">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
            </svg>
          </div>
        </div>
        <div>
          <h3 class="text-2xl font-bold text-gray-900 mt-2 mb-3">142</h3>
          <div class="flex items-center gap-2 text-[12px]">
            <span class="flex items-center text-emerald-600 font-medium bg-emerald-50 px-1.5 py-0.5 rounded">
               <svg class="w-3 h-3 mr-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="3"><path stroke-linecap="round" stroke-linejoin="round" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" /></svg>
               2%
            </span>
            <span class="text-gray-500">vs bulan lalu</span>
          </div>
        </div>
      </div>
      
      <!-- Card 2 -->
      <div class="bg-white p-5 rounded-xl border border-gray-200 shadow-sm flex flex-col justify-between">
        <div class="flex items-start justify-between">
          <p class="text-[13px] font-medium text-gray-600 leading-tight w-24">Rata-rata Masuk</p>
          <div class="w-8 h-8 rounded-lg bg-orange-50 text-orange-500 flex items-center justify-center">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
        </div>
        <div>
          <h3 class="text-2xl font-bold text-gray-900 mt-2 mb-3">09:02</h3>
          <div class="flex items-center gap-2 text-[12px]">
            <span class="font-medium bg-gray-100 text-gray-600 px-1.5 py-0.5 rounded">
               0%
            </span>
            <span class="text-gray-500">Tidak ada perubahan</span>
          </div>
        </div>
      </div>
      
      <!-- Card 3 -->
      <div class="bg-white p-5 rounded-xl border border-gray-200 shadow-sm flex flex-col justify-between">
        <div class="flex items-start justify-between">
          <p class="text-[13px] font-medium text-gray-600 leading-tight w-20">Tingkat Ketepatan</p>
          <div class="w-8 h-8 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
        </div>
        <div>
          <h3 class="text-2xl font-bold text-gray-900 mt-2 mb-3">94%</h3>
          <div class="flex items-center gap-2 text-[12px]">
            <span class="flex items-center text-emerald-600 font-medium bg-emerald-50 px-1.5 py-0.5 rounded">
               <svg class="w-3 h-3 mr-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="3"><path stroke-linecap="round" stroke-linejoin="round" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" /></svg>
               5%
            </span>
            <span class="text-gray-500">vs bulan lalu</span>
          </div>
        </div>
      </div>
      
      <!-- Card 4 -->
      <div class="bg-white p-5 rounded-xl border border-gray-200 shadow-sm flex flex-col justify-between">
        <div class="flex items-start justify-between">
          <p class="text-[13px] font-medium text-gray-600 leading-tight">Terlambat</p>
          <div class="w-8 h-8 rounded-lg bg-red-50 text-red-500 flex items-center justify-center">
            <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
          </div>
        </div>
        <div>
          <h3 class="text-2xl font-bold text-gray-900 mt-2 mb-3">12</h3>
          <div class="flex items-center gap-2 text-[12px]">
            <span class="flex items-center text-emerald-600 font-medium bg-emerald-50 px-1.5 py-0.5 rounded">
               <svg class="w-3 h-3 mr-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="3"><path stroke-linecap="round" stroke-linejoin="round" d="M13 17h8m0 0V9m0 8l-8-8-4 4-6-6" /></svg>
               -12%
            </span>
            <span class="text-gray-500">Perbaikan</span>
          </div>
        </div>
      </div>
      
      <!-- Chart Card (Takes 2 cols on very large screens but since we only have 5 total, we'll let it span 2 cols on lg) -->
      <div class="bg-white p-5 rounded-xl border border-gray-200 shadow-sm lg:col-span-2 md:col-span-2">
        <div class="flex items-center justify-between mb-4">
          <h3 class="text-[14px] font-bold text-gray-900">Kehadiran Mingguan</h3>
          <div class="text-[12px] text-gray-500 flex items-center gap-1 cursor-pointer border px-2 py-1 border-gray-200 rounded">Minggu Ini <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7" /></svg></div>
        </div>
        <!-- Simple CSS Bar Chart -->
        <div class="flex items-end justify-between h-20 pt-2 gap-1 px-2">
          <div class="w-full bg-[#8fb6f6] rounded-t-sm" style="height: 50%;"></div>
          <div class="w-full bg-[#6a9bf3] rounded-t-sm" style="height: 75%;"></div>
          <div class="w-full bg-[#2563eb] rounded-t-sm" style="height: 100%;"></div>
          <div class="w-full bg-[#4986ef] rounded-t-sm" style="height: 90%;"></div>
          <div class="w-full bg-[#a9c9fa] rounded-t-sm" style="height: 40%;"></div>
        </div>
        <div class="flex justify-between mt-2 text-[11px] text-gray-500 font-medium px-4">
          <span>Sen</span><span>Sel</span><span>Rab</span><span>Kam</span><span>Jum</span>
        </div>
      </div>
    </div>

    <!-- DataTable Instance -->
    <DataTable :data="displayData" :columns="columns" :isLoading="isLoading">
      <template #headerTitle>
        <h2 class="text-[16px] font-bold text-gray-900">Catatan Harian</h2>
      </template>
    </DataTable>

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
                <SelectItem v-for="emp in employeeOptions" :key="emp.ID" :value="emp.ID">
                  {{ emp.FirstName }} ({{ emp.User?.Email }})
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
