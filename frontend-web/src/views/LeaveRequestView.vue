<script setup lang="ts">
import { ref, h, onMounted } from 'vue'
import { toast } from 'vue-sonner'
import apiClient from '@/api/axios'
import DataTable from '@/components/DataTable.vue'

const leaveRequests = ref<any[]>([])
const isLoading = ref(true)
const activeFilter = ref('ALL')

const statusFilters = ['ALL', 'PENDING', 'APPROVED', 'REJECTED']

const fetchLeaveRequests = async () => {
  isLoading.value = true
  try {
    const params = activeFilter.value !== 'ALL' ? `?status=${activeFilter.value}` : ''
    const res = await apiClient.get(`/time-off${params}`)
    leaveRequests.value = res.data.data
  } catch (e) {
    console.error(e)
  } finally {
    isLoading.value = false
  }
}

const processLeave = async (id: string, status: 'APPROVED' | 'REJECTED') => {
  const reason = status === 'REJECTED' ? prompt('Alasan penolakan (opsional):') : null
  try {
    await apiClient.put(`/time-off/${id}/approve`, { status, rejectReason: reason || '' })
    toast.success(`Pengajuan berhasil ${status === 'APPROVED' ? 'disetujui' : 'ditolak'}!`)
    fetchLeaveRequests()
  } catch (err: any) {
    toast.error('Gagal: ' + (err.response?.data?.error || err.message))
  }
}

onMounted(fetchLeaveRequests)

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
    cell: ({ row }: any) => {
      const lt = row.original.LeaveType
      return h('span', { class: 'text-gray-700' }, lt?.Name || '-')
    }
  },
  {
    id: 'duration',
    header: 'PERIODE',
    cell: ({ row }: any) => {
      const r = row.original
      const fmt = (d: string) => new Date(d).toLocaleDateString('id-ID', { dateStyle: 'medium' })
      return h('span', { class: 'text-[13px] text-gray-600' }, `${fmt(r.StartDate)} - ${fmt(r.EndDate)}`)
    }
  },
  {
    accessorKey: 'Reason',
    header: 'ALASAN',
    cell: (info: any) => h('span', { class: 'text-gray-500 text-[13px] max-w-[160px] truncate inline-block', title: info.getValue() }, info.getValue() || '-')
  },
  {
    accessorKey: 'Status',
    header: 'STATUS',
    cell: (info: any) => {
      const s = info.getValue()
      const cls = s === 'APPROVED' ? 'border-green-200 text-green-700'
                : s === 'REJECTED' ? 'border-red-200 text-red-600'
                : 'border-yellow-200 text-yellow-700'
      return h('span', { class: `border ${cls} px-3 py-1 rounded-full text-[11px] font-bold` }, s)
    }
  },
  {
    id: 'actions',
    header: 'AKSI',
    cell: ({ row }: any) => {
      const r = row.original
      if (r.Status !== 'PENDING') return h('span', { class: 'text-gray-400 text-[13px]' }, 'Sudah Diproses')
      return h('div', { class: 'flex gap-2' }, [
        h('button', { class: 'text-[13px] font-semibold text-green-700 hover:underline', onClick: () => processLeave(r.ID, 'APPROVED') }, 'Setujui'),
        h('button', { class: 'text-[13px] font-semibold text-red-600 hover:underline', onClick: () => processLeave(r.ID, 'REJECTED') }, 'Tolak')
      ])
    }
  }
]
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h1 class="text-[22px] font-bold text-gray-900">Pengajuan Cuti</h1>
        <p class="text-[14px] text-gray-500 mt-1">Review dan proses pengajuan cuti karyawan.</p>
      </div>
    </div>

    <!-- Filter tabs -->
    <div class="flex gap-2 flex-wrap">
      <button
        v-for="f in statusFilters"
        :key="f"
        @click="activeFilter = f; fetchLeaveRequests()"
        :class="[
          'px-4 py-1.5 rounded-full text-[13px] font-semibold border transition-colors',
          activeFilter === f
            ? 'bg-blue-600 text-white border-blue-600'
            : 'bg-white text-gray-600 border-gray-300 hover:border-blue-400'
        ]"
      >{{ f }}</button>
    </div>

    <DataTable :data="leaveRequests" :columns="columns" :isLoading="isLoading" />
  </div>
</template>
