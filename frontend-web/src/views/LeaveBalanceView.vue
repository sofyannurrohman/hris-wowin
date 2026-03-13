<script setup lang="ts">
import { ref, h, onMounted } from 'vue'
import apiClient from '@/api/axios'
import DataTable from '@/components/DataTable.vue'

const balances = ref<any[]>([])
const isLoading = ref(true)

const fetchBalances = async () => {
  isLoading.value = true
  try {
    // HR views all leave balances directly via DB
    const res = await apiClient.get('/leave-balances')
    balances.value = res.data.data
  } catch (e) {
    console.error(e)
  } finally {
    isLoading.value = false
  }
}

onMounted(fetchBalances)

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
    id: 'leaveType',
    header: 'JENIS CUTI',
    cell: ({ row }: any) => h('span', { class: 'text-gray-700' }, row.original.LeaveType?.Name || '-')
  },
  {
    accessorKey: 'Year',
    header: 'TAHUN',
    cell: (info: any) => h('span', { class: 'text-gray-600' }, info.getValue())
  },
  {
    accessorKey: 'BalanceTotal',
    header: 'TOTAL JATAH',
    cell: (info: any) => h('span', { class: 'font-semibold text-gray-900' }, `${info.getValue()} hari`)
  },
  {
    accessorKey: 'BalanceUsed',
    header: 'TERPAKAI',
    cell: (info: any) => h('span', { class: 'text-orange-600 font-semibold' }, `${info.getValue()} hari`)
  },
  {
    id: 'remaining',
    header: 'SISA',
    cell: ({ row }: any) => {
      const r = row.original
      const sisa = (r.BalanceTotal || 0) - (r.BalanceUsed || 0)
      return h('span', { class: `font-bold ${sisa > 0 ? 'text-green-600' : 'text-red-500'}` }, `${sisa} hari`)
    }
  }
]
</script>

<template>
  <div class="space-y-6">
    <div>
      <h1 class="text-[22px] font-bold text-gray-900">Saldo Cuti Karyawan</h1>
      <p class="text-[14px] text-gray-500 mt-1">Lihat saldo cuti per karyawan. Data dikelola sistem secara otomatis.</p>
    </div>

    <div class="p-4 bg-amber-50 border border-amber-200 rounded-lg flex gap-3 items-start">
      <svg class="w-5 h-5 text-amber-600 mt-0.5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
      <p class="text-[13px] text-amber-700">Saldo cuti diperbarui otomatis oleh sistem ketika pengajuan cuti disetujui. Tidak ada perubahan manual yang tersedia.</p>
    </div>

    <DataTable :data="balances" :columns="columns" :isLoading="isLoading" />
  </div>
</template>
