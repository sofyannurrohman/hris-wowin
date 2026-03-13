<script setup lang="ts">
import { ref, onMounted, h } from 'vue'
import { toast } from 'vue-sonner'
import axios from '@/api/axios'
import DataTable from '@/components/DataTable.vue'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'

const isLoading = ref(true)
const isSubmitting = ref(false)
const displayData = ref<any[]>([])

const rejectModalOpen = ref(false)
const selectedLeaveId = ref<string>('')
const rejectReason = ref<string>('')

const columns = [
  {
    accessorKey: 'name',
    header: 'KARYAWAN',
    cell: ({ row }: any) => {
       const item = row.original
       const name = item.Employee?.FirstName || 'Unknown'
       const image = `https://i.pravatar.cc/150?u=${item.EmployeeID}`
       return h('div', { class: 'flex items-center gap-3' }, [
         h('img', { src: image, class: 'w-8 h-8 rounded-full border border-gray-200 object-cover' }),
         h('div', { class: 'font-bold text-gray-900 leading-tight' }, name)
       ])
    }
  },
  {
    accessorKey: 'LeaveType.Name',
    header: 'TIPE CUTI',
    cell: ({ row }: any) => h('span', { class: 'font-bold text-gray-700' }, row.original.LeaveType?.Name || '-')
  },
  {
    id: 'dateRange',
    header: 'TANGGAL',
    cell: ({ row }: any) => {
      const start = new Date(row.original.StartDate).toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' })
      const end = new Date(row.original.EndDate).toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' })
      return h('span', { class: 'text-gray-600 text-[13px]' }, start === end ? start : `${start} - ${end}`)
    }
  },
  {
    id: 'days',
    header: 'JUMLAH HARI',
    cell: ({ row }: any) => {
      const start = new Date(row.original.StartDate)
      const end = new Date(row.original.EndDate)
      const days = Math.ceil((end.getTime() - start.getTime()) / (1000 * 3600 * 24)) + 1
      return h('span', { class: 'text-gray-700 font-medium' }, `${days} Hari`)
    }
  },
  {
    accessorKey: 'Status',
    header: 'STATUS',
    cell: ({ getValue }: any) => {
        const val = getValue() as string
        let classes = 'border border-[#fef08a] text-[#ca8a04]' // PENDING
        if (val === 'APPROVED') classes = 'border border-[#bbf7d0] text-[#16a34a]'
        else if (val === 'REJECTED') classes = 'border border-red-200 text-red-600 bg-red-50'
        return h('span', { class: `${classes} px-3 py-1 rounded-full text-[11px] font-bold inline-block` }, val)
    }
  },
  {
    id: 'actions',
    header: '',
    cell: ({ row }: any) => {
        const status = row.original.Status
        const id = row.original.ID

        if (status === 'PENDING') {
          return h('div', { class: 'flex items-center justify-end gap-2' }, [
            h('button', { 
              onClick: () => changeStatus(id, 'APPROVED'),
              class: 'px-3 py-1.5 text-emerald-600 hover:bg-emerald-50 rounded text-[12px] transition-colors font-bold border border-transparent hover:border-emerald-200' 
            }, 'Setujui'),
            h('button', {
              onClick: () => openRejectModal(id),
              class: 'px-3 py-1.5 text-red-600 hover:bg-red-50 rounded text-[12px] transition-colors font-bold border border-transparent hover:border-red-200' 
            }, 'Tolak')
          ])
        } else {
          return null
        }
    },
    enableSorting: false
  }
]

const openRejectModal = (id: string) => {
  selectedLeaveId.value = id
  rejectReason.value = ''
  rejectModalOpen.value = true
}

const cancelReject = () => {
  rejectModalOpen.value = false
  selectedLeaveId.value = ''
}

const changeStatus = async (id: string, newStatus: string) => {
  if (newStatus === 'APPROVED' && !confirm('Yakin ingin menyetujui pengajuan cuti ini?')) return

  isSubmitting.value = true
  try {
    const payload: any = { status: newStatus }
    if (newStatus === 'REJECTED') {
      payload.reject_reason = rejectReason.value
    }

    await axios.put(`/time-off/${id}/approve`, payload)
    
    if (newStatus === 'REJECTED') {
      toast.success('Cuti otomatis ditolak dan saldo dikembalikan.')
      rejectModalOpen.value = false
    } else {
      toast.success('Cuti berhasil disetujui.')
    }
    
    fetchLeaves()
  } catch(e: any) {
    toast.error('Gagal memperbarui status cuti: ' + (e.response?.data?.message || e.message))
  } finally {
    isSubmitting.value = false
  }
}

const fetchLeaves = async () => {
  isLoading.value = true
  try {
    const res = await axios.get('/time-off')
    if (res.data?.data) {
      displayData.value = res.data.data
    }
  } catch (error) {
    console.error('Failed fetching leave data', error)
  } finally {
    isLoading.value = false
  }
}

onMounted(() => {
  fetchLeaves()
})
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h1 class="text-[22px] font-bold text-gray-900 leading-tight">Pengajuan Cuti</h1>
        <p class="text-[14px] text-gray-500 mt-1">Kelola dan tinjau permintaan cuti karyawan.</p>
      </div>
    </div>

    <DataTable :data="displayData" :columns="columns" :isLoading="isLoading">
      <template #headerTitle>
        <h2 class="text-[15px] font-bold text-gray-900">Semua Permohonan</h2>
      </template>
    </DataTable>

    <!-- Reject Reason Dialog -->
    <Dialog v-model:open="rejectModalOpen">
      <DialogContent class="sm:max-w-md">
        <DialogHeader>
          <DialogTitle class="text-xl text-red-600">Alasan Penolakan</DialogTitle>
          <DialogDescription>
            Cuti yang ditolak akan secara otomatis membatalkan pemotongan hari dan mengembalikan saldo cuti karyawan yang bersangkutan untuk tahun terkait.
          </DialogDescription>
        </DialogHeader>

        <div class="grid gap-4 py-4">
          <div class="grid gap-2">
            <label class="text-[13px] font-medium text-gray-700">Pesan ke Karyawan</label>
            <Input v-model="rejectReason" placeholder="e.g. Tidak bisa cuti mendadak di periode closing..." />
          </div>
        </div>
        
        <DialogFooter>
          <Button variant="outline" @click="cancelReject">Batalkan Penolakan</Button>
          <Button variant="destructive" @click="changeStatus(selectedLeaveId, 'REJECTED')" :disabled="isSubmitting || !rejectReason.trim()">
            {{ isSubmitting ? 'Memproses...' : 'Konfirmasi Penolakan' }}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>

  </div>
</template>
