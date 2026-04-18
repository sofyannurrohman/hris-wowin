<script setup lang="ts">
import { ref, h, onMounted } from 'vue'
import { Pencil } from 'lucide-vue-next'
import apiClient from '@/api/axios'
import DataTable from '@/components/DataTable.vue'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { toast } from 'vue-sonner'

const balances = ref<any[]>([])
const isLoading = ref(true)
const isModalOpen = ref(false)
const isSubmitting = ref(false)

const editingBalance = ref({
  employee_id: '',
  leave_type_id: '',
  year: new Date().getFullYear(),
  balance_total: 0,
  balance_used: 0,
  employeeName: '',
  leaveTypeName: ''
})

const fetchBalances = async () => {
  isLoading.value = true
  try {
    const res = await apiClient.get('/leave-balances')
    balances.value = res.data.data
  } catch (e) {
    console.error(e)
  } finally {
    isLoading.value = false
  }
}

const openEditModal = (row: any) => {
  editingBalance.value = {
    employee_id: row.EmployeeID,
    leave_type_id: row.LeaveTypeID,
    year: row.Year,
    balance_total: row.BalanceTotal,
    balance_used: row.BalanceUsed,
    employeeName: row.Employee ? `${row.Employee.FirstName} ${row.Employee.LastName}` : 'Unknown',
    leaveTypeName: row.LeaveType?.Name || 'Unknown'
  }
  isModalOpen.value = true
}

const saveBalance = async () => {
  isSubmitting.value = true
  try {
    await apiClient.put('/time-off/manage/balances', {
      employee_id: editingBalance.value.employee_id,
      leave_type_id: editingBalance.value.leave_type_id,
      year: editingBalance.value.year,
      balance_total: editingBalance.value.balance_total,
      balance_used: editingBalance.value.balance_used
    })
    toast.success('Saldo cuti berhasil diperbarui!')
    isModalOpen.value = false
    fetchBalances()
  } catch (error: any) {
    toast.error('Gagal memperbarui saldo: ' + (error.response?.data?.message || error.message))
  } finally {
    isSubmitting.value = false
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
  },
  {
    id: 'actions',
    header: 'AKSI',
    cell: ({ row }: any) => {
      return h(Button, {
        variant: 'ghost',
        size: 'sm',
        class: 'h-8 px-2 text-primary hover:text-primary hover:bg-primary/5',
        onClick: () => openEditModal(row.original)
      }, () => h(Pencil, { class: 'w-4 h-4' }))
    }
  }
]
</script>

<template>
  <div class="space-y-6">
    <div>
      <h1 class="text-[22px] font-bold text-gray-900">Saldo Cuti Karyawan</h1>
      <p class="text-[14px] text-gray-500 mt-1">Kelola saldo cuti per karyawan secara manual jika diperlukan.</p>
    </div>

    <DataTable :data="balances" :columns="columns" :isLoading="isLoading" />

    <!-- Edit Modal -->
    <Dialog v-model:open="isModalOpen">
      <DialogContent class="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Sesuaikan Saldo Cuti</DialogTitle>
          <DialogDescription>
            Mengubah saldo untuk <b>{{ editingBalance.employeeName }}</b> pada tipe <b>{{ editingBalance.leaveTypeName }}</b>.
          </DialogDescription>
        </DialogHeader>
        
        <div class="grid gap-4 py-4">
          <div class="grid gap-2">
            <label class="text-[13px] font-medium text-gray-700">Total Jatah (Hari)</label>
            <Input v-model.number="editingBalance.balance_total" type="number" min="0" />
          </div>
          <div class="grid gap-2">
            <label class="text-[13px] font-medium text-gray-700">Terpakai (Hari)</label>
            <Input v-model.number="editingBalance.balance_used" type="number" min="0" />
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" @click="isModalOpen = false">Batal</Button>
          <Button @click="saveBalance" :disabled="isSubmitting">
            {{ isSubmitting ? 'Menyimpan...' : 'Simpan Perubahan' }}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  </div>
</template>
