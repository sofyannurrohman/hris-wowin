<script setup lang="ts">
import { ref, h, onMounted } from 'vue'
import { Pencil, Trash2 } from 'lucide-vue-next'
import apiClient from '@/api/axios'
import DataTable from '@/components/DataTable.vue'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { toast } from 'vue-sonner'

const isModalOpen = ref(false)
const newShift = ref({
  id: '',
  name: '',
  startTime: '',
  endTime: '',
  breakStart: '',
  breakEnd: '',
  isFlexible: false
})

const isEditMode = ref(false)
const isSubmitting = ref(false)
const shifts = ref<any[]>([])
const isLoading = ref(true)

const openAddModal = () => {
  isEditMode.value = false
  newShift.value = {
    id: '',
    name: '',
    startTime: '',
    endTime: '',
    breakStart: '',
    breakEnd: '',
    isFlexible: false
  }
  isModalOpen.value = true
}

const openEditModal = (shift: any) => {
  isEditMode.value = true
  
  // Convert full ISO string to HH:mm for simple input type="time"
  const parseTime = (isoString: string) => {
    if (!isoString) return ''
    const d = new Date(isoString)
    if (isNaN(d.getTime())) return ''
    return d.toISOString().substring(11, 16)
  }

  newShift.value = {
    id: shift.ID,
    name: shift.Name || '',
    startTime: parseTime(shift.StartTime),
    endTime: parseTime(shift.EndTime),
    breakStart: shift.BreakStart ? parseTime(shift.BreakStart) : '',
    breakEnd: shift.BreakEnd ? parseTime(shift.BreakEnd) : '',
    isFlexible: shift.IsFlexible || false
  }
  isModalOpen.value = true
}

const closeAddModal = () => {
  isModalOpen.value = false
}

const fetchShifts = async () => {
  isLoading.value = true
  try {
    const response = await apiClient.get('/shifts')
    shifts.value = response.data.data
  } catch (error) {
    console.error('Failed to fetch shifts:', error)
  } finally {
    isLoading.value = false
  }
}

const saveShift = async () => {
  isSubmitting.value = true
  try {
    // Format back to ISO String for backend (fake date 1970-01-01 is fine for time types in our GORM schema usually, or use full current date)
    const toISO = (timeStr: string) => {
      if (!timeStr) return null
      return `0000-01-01T${timeStr}:00Z` // backend parsing can usually handle this if it's purely time, or we can use 1970 
    }

    const payload = {
      name: newShift.value.name,
      startTime: toISO(newShift.value.startTime),
      endTime: toISO(newShift.value.endTime),
      breakStart: toISO(newShift.value.breakStart),
      breakEnd: toISO(newShift.value.breakEnd),
      isFlexible: newShift.value.isFlexible
    }

    if (isEditMode.value) {
      await apiClient.put(`/shifts/${newShift.value.id}`, payload)
      toast.success('Shift berhasil diperbarui!')
    } else {
      await apiClient.post('/shifts', payload)
      toast.success('Shift berhasil ditambahkan!')
    }
    closeAddModal()
    fetchShifts()
  } catch (error: any) {
    toast.error(`Gagal ${isEditMode.value ? 'memperbarui' : 'menambahkan'} shift: ` + (error.response?.data?.error || error.message))
  } finally {
    isSubmitting.value = false
  }
}

const deleteShift = async (id: string) => {
  if (!confirm('Apakah Anda yakin ingin menghapus shift ini? Operasi ini tidak dapat dibatalkan.')) return
  
  try {
    await apiClient.delete(`/shifts/${id}`)
    toast.success('Shift berhasil dihapus!')
    fetchShifts()
  } catch (error: any) {
    toast.error('Gagal menghapus shift: ' + (error.response?.data?.error || error.message))
  }
}

onMounted(() => {
  fetchShifts()
})

const columns = [
  {
    accessorKey: 'Name',
    header: 'NAMA SHIFT',
    cell: (info: any) => h('span', { class: 'font-bold text-gray-900' }, info.getValue() || '-')
  },
  {
    id: 'waktu',
    header: 'JAM KERJA',
    cell: ({ row }: any) => {
      const shift = row.original
      const parseTime = (isoString: string) => {
        if (!isoString) return '-'
        const d = new Date(isoString)
        if (isNaN(d.getTime())) return '-'
        return d.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })
      }
      return h('span', { class: 'text-gray-600' }, `${parseTime(shift.StartTime)} - ${parseTime(shift.EndTime)}`)
    }
  },
  {
    id: 'istirahat',
    header: 'ISTIRAHAT',
    cell: ({ row }: any) => {
      const shift = row.original
      if (!shift.BreakStart || !shift.BreakEnd) return h('span', { class: 'text-gray-400' }, 'Tidak Ada')
      const parseTime = (isoString: string) => {
        const d = new Date(isoString)
        if (isNaN(d.getTime())) return ''
        return d.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })
      }
      return h('span', { class: 'text-gray-600 text-[13px]' }, `${parseTime(shift.BreakStart)} - ${parseTime(shift.BreakEnd)}`)
    }
  },
  {
    accessorKey: 'IsFlexible',
    header: 'FLEXIBLE',
    cell: (info: any) => {
      const isFlex = info.getValue()
      return h('span', { 
        class: isFlex ? 'border border-[#bbf7d0] text-[#16a34a] px-3 py-1 rounded-full text-[11px] font-bold inline-block' 
                      : 'border border-[#e5e7eb] text-gray-600 px-3 py-1 rounded-full text-[11px] font-bold inline-block' 
      }, isFlex ? 'Ya' : 'Tidak')
    }
  },
  {
    id: 'actions',
    header: 'AKSI',
    cell: ({ row }: any) => {
      const shift = row.original
      return h('div', { class: 'flex items-center gap-2' }, [
        h(Button, { 
            variant: 'ghost', 
            size: 'sm', 
            class: 'h-8 px-2 text-blue-600 hover:text-blue-700 hover:bg-blue-50',
            onClick: () => openEditModal(shift)
        }, () => h(Pencil, { class: 'w-4 h-4' })),
        h(Button, { 
            variant: 'ghost', 
            size: 'sm', 
            class: 'h-8 px-2 text-red-600 hover:text-red-700 hover:bg-red-50',
            onClick: () => deleteShift(shift.ID)
        }, () => h(Trash2, { class: 'w-4 h-4' }))
      ])
    }
  }
]
</script>

<template>
  <div class="space-y-6">
    <!-- Header Page -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h1 class="text-[22px] font-bold text-gray-900 leading-tight">Master Shift Kerja</h1>
        <p class="text-[14px] text-gray-500 mt-1">Kelola data jadwal dan aturan waktu shift kerja.</p>
      </div>
      
      <div class="flex items-center gap-3">
        <Button @click="openAddModal" class="gap-2 shadow-sm rounded-lg" size="sm">
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
          </svg>
          Tambah Shift
        </Button>
      </div>
    </div>

    <!-- DataTable Instance -->
    <DataTable :data="shifts" :columns="columns" :isLoading="isLoading" />

    <!-- Add/Edit Modal -->
    <Dialog v-model:open="isModalOpen">
      <DialogContent class="sm:max-w-xl">
        <DialogHeader>
          <DialogTitle class="text-xl">{{ isEditMode ? 'Edit Shift Kerja' : 'Tambah Shift Kerja' }}</DialogTitle>
          <DialogDescription>
            Tentukan konfigurasi waktu untuk shift ini.
          </DialogDescription>
        </DialogHeader>
        
        <div class="grid gap-4 py-4">
          <div class="grid gap-2">
            <label class="text-[13px] font-medium text-gray-700">Nama Shift</label>
            <Input v-model="newShift.name" placeholder="e.g. Shift Pagi" />
          </div>
          
          <div class="grid grid-cols-2 gap-4">
            <div class="grid gap-2">
              <label class="text-[13px] font-medium text-gray-700">Jam Masuk (Start)</label>
              <Input v-model="newShift.startTime" type="time" class="h-10" />
            </div>
            <div class="grid gap-2">
              <label class="text-[13px] font-medium text-gray-700">Jam Keluar (End)</label>
              <Input v-model="newShift.endTime" type="time" class="h-10" />
            </div>
          </div>

          <div class="h-px bg-gray-100 my-2"></div>
          <h3 class="text-[13px] font-bold text-gray-900 uppercase tracking-wider">Jam Istirahat (Opsional)</h3>

          <div class="grid grid-cols-2 gap-4">
            <div class="grid gap-2">
              <label class="text-[13px] font-medium text-gray-700">Mulai Istirahat</label>
              <Input v-model="newShift.breakStart" type="time" class="h-10" />
            </div>
            <div class="grid gap-2">
              <label class="text-[13px] font-medium text-gray-700">Selesai Istirahat</label>
              <Input v-model="newShift.breakEnd" type="time" class="h-10" />
            </div>
          </div>

          <div class="flex items-center space-x-2 mt-4">
            <input type="checkbox" id="isFlexible" v-model="newShift.isFlexible" class="w-4 h-4 rounded border-gray-300 text-blue-600 focus:ring-blue-600" />
            <label for="isFlexible" class="text-sm font-medium leading-none">
              Shift Fleksibel (Boleh absen kapan saja selagi 8 jam)
            </label>
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" @click="closeAddModal">Batal</Button>
          <Button @click="saveShift" :disabled="isSubmitting">
            {{ isSubmitting ? 'Menyimpan...' : 'Simpan Data' }}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  </div>
</template>
