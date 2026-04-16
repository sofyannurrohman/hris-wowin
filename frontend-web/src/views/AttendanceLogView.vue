<script setup lang="ts">
import { ref, h, onMounted } from 'vue'
import apiClient from '@/api/axios'
import DataTable from '@/components/DataTable.vue'

const logs = ref<any[]>([])
const isLoading = ref(true)

const fetchLogs = async () => {
  isLoading.value = true
  try {
    const res = await apiClient.get('/attendance/all')
    logs.value = res.data.data
  } catch (e) {
    console.error(e)
  } finally {
    isLoading.value = false
  }
}

onMounted(fetchLogs)

const fmt = (iso: string) => {
  if (!iso) return '-'
  const d = new Date(iso)
  if (isNaN(d.getTime())) return '-'
  const date = d.toLocaleDateString('id-ID', { dateStyle: 'medium' })
  const h = String(d.getUTCHours()).padStart(2, '0')
  const m = String(d.getUTCMinutes()).padStart(2, '0')
  return `${date} ${h}.${m}`
}

const columns = [
  {
    id: 'employee',
    header: 'KARYAWAN',
    cell: ({ row }: any) => {
      const emp = row.original.Employee
      return h('span', { class: 'font-bold text-gray-900' }, emp ? `${emp.FirstName} ${emp.LastName}` : '-')
    }
  },
  {
    accessorKey: 'CheckInTime',
    header: 'MASUK',
    cell: (info: any) => h('span', { class: 'text-[13px] text-gray-700' }, fmt(info.getValue()))
  },
  {
    accessorKey: 'CheckOutTime',
    header: 'KELUAR',
    cell: (info: any) => h('span', { class: 'text-[13px] text-gray-700' }, fmt(info.getValue()))
  },
  {
    accessorKey: 'Status',
    header: 'STATUS',
    cell: (info: any) => {
      const s = info.getValue() as string
      const cls = s === 'PRESENT' ? 'border-green-200 text-green-700'
                : s === 'LATE' ? 'border-orange-200 text-orange-600'
                : 'border-gray-200 text-gray-600'
      return h('span', { class: `border ${cls} px-2 py-0.5 rounded-full text-[11px] font-bold uppercase` }, s || '-')
    }
  },
  {
    accessorKey: 'Note',
    header: 'CATATAN',
    cell: (info: any) => h('span', { class: 'text-gray-400 text-[13px] italic' }, info.getValue() || '-')
  },
  {
    accessorKey: 'IsManual',
    header: 'TYPE',
    cell: (info: any) => {
      const manual = info.getValue()
      return h('span', { class: manual ? 'text-purple-600 text-[11px] font-bold uppercase' : 'text-gray-500 text-[11px] uppercase' }, manual ? 'Manual' : 'Mobile')
    }
  }
]
</script>

<template>
  <div class="space-y-6">
    <div>
      <h1 class="text-[22px] font-bold text-gray-900">Log Absensi</h1>
      <p class="text-[14px] text-gray-500 mt-1">Rekap data absensi seluruh karyawan. Data bersumber dari mobile app dan face recognition.</p>
    </div>

    <div class="p-4 bg-primary/5 border border-blue-200 rounded-lg flex gap-3 items-start">
      <svg class="w-5 h-5 text-primary mt-0.5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
      <p class="text-[13px] text-primary">Data absensi diinput otomatis dari check-in mobile karyawan. Koreksi manual tersedia di menu individual karyawan jika diperlukan.</p>
    </div>

    <DataTable :data="logs" :columns="columns" :isLoading="isLoading" />
  </div>
</template>
