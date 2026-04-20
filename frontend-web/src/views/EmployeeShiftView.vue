<script setup lang="ts">
import { ref, h, onMounted } from 'vue'
import { Pencil, Trash2 } from 'lucide-vue-next'
import apiClient from '@/api/axios'
import DataTable from '@/components/DataTable.vue'
import { Button } from '@/components/ui/button'
import { Select, SelectContent, SelectGroup, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { toast } from 'vue-sonner'

const isModalOpen = ref(false)
const assignment = ref({
  id: '',
  employeeId: '',
  shiftId: '',
  date: '',
  isOffDay: false
})
const isEditMode = ref(false)
const isSubmitting = ref(false)

const assignments = ref<any[]>([])
const employees = ref<any[]>([])
const shifts = ref<any[]>([])
const isLoading = ref(true)

const fetchAll = async () => {
  isLoading.value = true
  try {
    const [aRes, eRes, sRes] = await Promise.all([
      apiClient.get('/employee-shifts'),
      apiClient.get('/employees'),
      apiClient.get('/shifts')
    ])
    assignments.value = aRes.data.data
    employees.value = eRes.data.data
    shifts.value = sRes.data.data
  } catch (e) {
    console.error('Failed to fetch data', e)
  } finally {
    isLoading.value = false
  }
}

const openAddModal = () => {
  isEditMode.value = false
  assignment.value = { id: '', employeeId: '', shiftId: '', date: '', isOffDay: false }
  isModalOpen.value = true
}

const openEditModal = (row: any) => {
  isEditMode.value = true
  assignment.value = {
    id: row.id,
    employeeId: row.employee_id,
    shiftId: row.shift_id,
    date: row.date ? row.date.substring(0, 10) : '',
    isOffDay: row.is_off_day || false
  }
  isModalOpen.value = true
}

const save = async () => {
  isSubmitting.value = true
  try {
    const payload = {
      employeeId: assignment.value.employeeId,
      shiftId: assignment.value.shiftId,
      date: assignment.value.date ? new Date(assignment.value.date).toISOString() : null,
      isOffDay: assignment.value.isOffDay
    }
    if (isEditMode.value) {
      await apiClient.put(`/employee-shifts/${assignment.value.id}`, payload)
      toast.success('Penugasan shift berhasil diperbarui!')
    } else {
      await apiClient.post('/employee-shifts', payload)
      toast.success('Shift berhasil di-assign!')
    }
    isModalOpen.value = false
    fetchAll()
  } catch (err: any) {
    toast.error('Gagal: ' + (err.response?.data?.error || err.message))
  } finally {
    isSubmitting.value = false
  }
}

const remove = async (id: string) => {
  if (!confirm('Hapus penugasan shift ini?')) return
  try {
    await apiClient.delete(`/employee-shifts/${id}`)
    toast.success('Penugasan berhasil dihapus!')
    fetchAll()
  } catch (err: any) {
    toast.error('Gagal: ' + (err.response?.data?.error || err.message))
  }
}

onMounted(fetchAll)

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
    id: 'shift',
    header: 'SHIFT',
    cell: ({ row }: any) => {
      const shift = row.original.shift
      const fmtTime = (iso: string) => {
        if (!iso) return ''
        const d = new Date(iso)
        if (isNaN(d.getTime())) return ''
        const h = String(d.getUTCHours()).padStart(2, '0')
        const m = String(d.getUTCMinutes()).padStart(2, '0')
        return `${h}.${m}`
      }
      const timeRange = shift ? ` (${fmtTime(shift.start_time)} - ${fmtTime(shift.end_time)})` : ''
      return h('span', { class: 'bg-primary/5 text-primary px-3 py-1 rounded-full text-[12px] font-semibold' }, (shift?.name || '-') + timeRange)
    }
  },
  {
    accessorKey: 'date',
    header: 'TANGGAL',
    cell: (info: any) => {
      const d = new Date(info.getValue())
      return h('span', { class: 'text-gray-700' }, isNaN(d.getTime()) ? '-' : d.toLocaleDateString('id-ID', { dateStyle: 'medium' }))
    }
  },
  {
    accessorKey: 'is_off_day',
    header: 'HARI LIBUR',
    cell: (info: any) => {
      const off = info.getValue()
      return h('span', {
        class: off ? 'border border-orange-200 text-orange-600 px-3 py-1 rounded-full text-[11px] font-bold' 
                   : 'border border-green-200 text-green-700 px-3 py-1 rounded-full text-[11px] font-bold'
      }, off ? 'Libur' : 'Kerja')
    }
  },
  {
    id: 'actions',
    header: 'AKSI',
    cell: ({ row }: any) => h('div', { class: 'flex gap-2' }, [
      h(Button, { variant: 'ghost', size: 'sm', class: 'h-8 px-2 text-primary hover:bg-primary/5', onClick: () => openEditModal(row.original) }, () => h(Pencil, { class: 'w-4 h-4' })),
      h(Button, { variant: 'ghost', size: 'sm', class: 'h-8 px-2 text-red-600 hover:bg-red-50', onClick: () => remove(row.original.id) }, () => h(Trash2, { class: 'w-4 h-4' }))
    ])
  }
]
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h1 class="text-[22px] font-bold text-gray-900">Penugasan Shift Karyawan</h1>
        <p class="text-[14px] text-gray-500 mt-1">Assign, edit, dan hapus jadwal shift harian karyawan.</p>
      </div>
      <Button @click="openAddModal" size="sm" class="gap-2">
        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" /></svg>
        Assign Shift
      </Button>
    </div>

    <DataTable :data="assignments" :columns="columns" :isLoading="isLoading" />

    <Dialog v-model:open="isModalOpen">
      <DialogContent class="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>{{ isEditMode ? 'Edit Penugasan Shift' : 'Assign Shift Karyawan' }}</DialogTitle>
          <DialogDescription>Pilih karyawan, shift, dan tanggal berlaku.</DialogDescription>
        </DialogHeader>
        <div class="grid gap-4 py-4">
          <div class="grid gap-2">
            <label class="text-[13px] font-medium">Karyawan</label>
            <Select v-model="assignment.employeeId" :disabled="isEditMode">
              <SelectTrigger><SelectValue placeholder="Pilih Karyawan" /></SelectTrigger>
              <SelectContent>
                <SelectGroup>
                  <SelectItem v-for="emp in employees" :key="emp.id" :value="emp.id">
                    {{ emp.first_name }} {{ emp.last_name || '' }}
                  </SelectItem>
                </SelectGroup>
              </SelectContent>
            </Select>
          </div>
          <div class="grid gap-2">
            <label class="text-[13px] font-medium">Shift</label>
            <Select v-model="assignment.shiftId">
              <SelectTrigger><SelectValue placeholder="Pilih Shift" /></SelectTrigger>
              <SelectContent>
                <SelectGroup>
                  <SelectItem v-for="s in shifts" :key="s.id" :value="s.id">{{ s.name }}</SelectItem>
                </SelectGroup>
              </SelectContent>
            </Select>
          </div>
          <div class="grid gap-2">
            <label class="text-[13px] font-medium">Tanggal</label>
            <Input v-model="assignment.date" type="date" />
          </div>
          <div class="flex items-center gap-2">
            <input type="checkbox" id="isOffDay" v-model="assignment.isOffDay" class="w-4 h-4" />
            <label for="isOffDay" class="text-sm font-medium">Tandai sebagai Hari Libur</label>
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" @click="isModalOpen = false">Batal</Button>
          <Button @click="save" :disabled="isSubmitting">{{ isSubmitting ? 'Menyimpan...' : 'Simpan' }}</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  </div>
</template>
