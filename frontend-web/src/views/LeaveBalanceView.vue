<script setup lang="ts">
import { ref, h, onMounted } from 'vue'
import { Pencil, Trash2, Plus } from 'lucide-vue-next'
import apiClient from '@/api/axios'
import DataTable from '@/components/DataTable.vue'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { toast } from 'vue-sonner'

const balances = ref<any[]>([])
const employees = ref<any[]>([])
const leaveTypes = ref<any[]>([])
const isLoading = ref(true)
const isModalOpen = ref(false)
const isSubmitting = ref(false)
const isEditMode = ref(false)

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

const fetchDependencies = async () => {
  try {
    const [empRes, typeRes] = await Promise.all([
      apiClient.get('/employees?limit=500'),
      apiClient.get('/leave-types')
    ])
    employees.value = empRes.data.data
    leaveTypes.value = typeRes.data.data
  } catch (e) {
    console.error('Failed to fetch dependencies', e)
  }
}

const openAddModal = () => {
  isEditMode.value = false
  editingBalance.value = {
    employee_id: '',
    leave_type_id: '',
    year: new Date().getFullYear(),
    balance_total: 0,
    balance_used: 0,
    employeeName: '',
    leaveTypeName: ''
  }
  isModalOpen.value = true
}

const openEditModal = (row: any) => {
  isEditMode.value = true
  editingBalance.value = {
    employee_id: row.employee_id,
    leave_type_id: row.leave_type_id,
    year: row.year,
    balance_total: row.balance_total,
    balance_used: row.balance_used,
    employeeName: row.employee ? `${row.employee.first_name} ${row.employee.last_name || ''}`.trim() : 'Unknown',
    leaveTypeName: row.leave_type?.name || 'Unknown'
  }
  isModalOpen.value = true
}

const deleteBalance = async (row: any) => {
  if (!confirm('Hapus saldo cuti ini? Riwayat cuti karyawan mungkin terpengaruh.')) return
  
  try {
    await apiClient.delete('/time-off/manage/balances', {
      data: {
        employee_id: row.employee_id,
        leave_type_id: row.leave_type_id,
        year: row.year
      }
    })
    toast.success('Saldo cuti berhasil dihapus')
    fetchBalances()
  } catch (error: any) {
    toast.error('Gagal menghapus: ' + (error.response?.data?.message || error.message))
  }
}

const saveBalance = async () => {
  if (!editingBalance.value.employee_id || !editingBalance.value.leave_type_id) {
    toast.error('Karyawan dan Jenis Cuti wajib diisi')
    return
  }

  isSubmitting.value = true
  try {
    await apiClient.put('/time-off/manage/balances', {
      employee_id: editingBalance.value.employee_id,
      leave_type_id: editingBalance.value.leave_type_id,
      year: editingBalance.value.year,
      balance_total: editingBalance.value.balance_total,
      balance_used: editingBalance.value.balance_used
    })
    toast.success(isEditMode.value ? 'Saldo cuti berhasil diperbarui!' : 'Saldo cuti berhasil ditambahkan!')
    isModalOpen.value = false
    fetchBalances()
  } catch (error: any) {
    toast.error('Gagal menyimpan saldo: ' + (error.response?.data?.message || error.message))
  } finally {
    isSubmitting.value = false
  }
}

onMounted(() => {
  fetchBalances()
  fetchDependencies()
})

const columns = [
  {
    id: 'employee',
    header: 'KARYAWAN',
    cell: ({ row }: any) => {
      const emp = row.original.employee
      return h('span', { class: 'font-bold text-gray-900' }, emp ? `${emp.first_name} ${emp.last_name || ''}`.trim() : '-')
    }
  },
  {
    id: 'leaveType',
    header: 'JENIS CUTI',
    cell: ({ row }: any) => h('span', { class: 'text-gray-700' }, row.original.leave_type?.name || '-')
  },
  {
    accessorKey: 'year',
    header: 'TAHUN',
    cell: (info: any) => h('span', { class: 'text-gray-600' }, info.getValue())
  },
  {
    accessorKey: 'balance_total',
    header: 'TOTAL JATAH',
    cell: (info: any) => h('span', { class: 'font-semibold text-gray-900' }, `${info.getValue()} hari`)
  },
  {
    accessorKey: 'balance_used',
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
      return h('div', { class: 'flex items-center gap-2' }, [
        h(Button, {
          variant: 'ghost',
          size: 'sm',
          class: 'h-8 px-2 text-blue-600 hover:text-blue-700 hover:bg-blue-50',
          onClick: () => openEditModal(row.original)
        }, () => h(Pencil, { class: 'w-4 h-4' })),
        h(Button, {
          variant: 'ghost',
          size: 'sm',
          class: 'h-8 px-2 text-rose-600 hover:text-rose-700 hover:bg-rose-50',
          onClick: () => deleteBalance(row.original)
        }, () => h(Trash2, { class: 'w-4 h-4' }))
      ])
    }
  }
]
</script>

<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-[22px] font-bold text-gray-900">Saldo Cuti Karyawan</h1>
        <p class="text-[14px] text-gray-500 mt-1">Kelola saldo cuti per karyawan secara manual jika diperlukan.</p>
      </div>
      <Button @click="openAddModal" class="gap-2">
        <Plus class="w-4 h-4" />
        Tambah Saldo
      </Button>
    </div>

    <DataTable :data="balances" :columns="columns" :isLoading="isLoading" />

    <!-- Edit Modal -->
    <Dialog v-model:open="isModalOpen">
      <DialogContent class="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>{{ isEditMode ? 'Sesuaikan Saldo Cuti' : 'Tambah Saldo Cuti' }}</DialogTitle>
          <DialogDescription>
            <span v-if="isEditMode">
              Mengubah saldo untuk <b>{{ editingBalance.employeeName }}</b> pada tipe <b>{{ editingBalance.leaveTypeName }}</b>.
            </span>
            <span v-else>
              Isi data di bawah untuk menambah atau menginisialisasi saldo cuti baru.
            </span>
          </DialogDescription>
        </DialogHeader>
        
        <div class="grid gap-4 py-4">
          <div v-if="!isEditMode" class="grid gap-4">
            <div class="grid gap-2">
              <Label class="text-[13px]">Karyawan</Label>
              <Select v-model="editingBalance.employee_id">
                <SelectTrigger>
                  <SelectValue placeholder="Pilih Karyawan" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem v-for="emp in employees" :key="emp.id" :value="emp.id">
                    {{ emp.first_name }} {{ emp.last_name || '' }}
                  </SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div class="grid gap-2">
              <Label class="text-[13px]">Jenis Cuti</Label>
              <Select v-model="editingBalance.leave_type_id">
                <SelectTrigger>
                  <SelectValue placeholder="Pilih Jenis Cuti" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem v-for="lt in leaveTypes" :key="lt.id" :value="lt.id">
                    {{ lt.name }}
                  </SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div class="grid gap-2">
              <Label class="text-[13px]">Tahun</Label>
              <Input v-model.number="editingBalance.year" type="number" />
            </div>
          </div>

          <div class="grid gap-4">
            <div class="grid gap-2">
              <Label class="text-[13px]">Total Jatah (Hari)</Label>
              <Input v-model.number="editingBalance.balance_total" type="number" min="0" />
            </div>
            <div class="grid gap-2">
              <Label class="text-[13px]">Terpakai (Hari)</Label>
              <Input v-model.number="editingBalance.balance_used" type="number" min="0" />
            </div>
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
