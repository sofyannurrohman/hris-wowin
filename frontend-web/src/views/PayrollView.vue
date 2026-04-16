<script setup lang="ts">
import { ref, h, onMounted } from 'vue'
import { toast } from 'vue-sonner'
import { Trash2 } from 'lucide-vue-next'
import axios from '@/api/axios'
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
import { Select, SelectContent, SelectGroup, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'

const payrollRuns = ref<any[]>([])
const isLoading = ref(true)
const isModalOpen = ref(false)
const isSubmitting = ref(false)

const newRun = ref({
  periodStart: '',
  periodEnd: '',
  paymentSchedule: ''
})

const fetchPayrollRuns = async () => {
  isLoading.value = true
  try {
    const res = await axios.get('/payroll/all?limit=50')
    if (res.data?.data) {
      payrollRuns.value = res.data.data.map((r: any) => ({
        id: r.ID,
        periodStart: r.PeriodStart ? new Date(r.PeriodStart).toISOString().split('T')[0] : '',
        periodEnd: r.PeriodEnd ? new Date(r.PeriodEnd).toISOString().split('T')[0] : '',
        paymentSchedule: r.PaymentSchedule ? new Date(r.PaymentSchedule).toISOString().split('T')[0] : '',
        status: r.Status,
        totalPayout: r.TotalPayout || 0
      }))
    }
  } catch (error) {
    console.error('Failed to fetch payroll history', error)
  } finally {
    isLoading.value = false
  }
}

const openAddModal = () => {
  newRun.value = {
    periodStart: '',
    periodEnd: '',
    paymentSchedule: ''
  }
  isModalOpen.value = true
}

const closeAddModal = () => {
  isModalOpen.value = false
}

const exportBankCSV = async (runId: string) => {
  try {
     const res = await axios.get(`/payroll/${runId}/export`, { responseType: 'blob' })
     
     // Virtual download link generator
     const url = window.URL.createObjectURL(new Blob([res.data]))
     const link = document.createElement('a')
     link.href = url
     link.setAttribute('download', `payroll_export_${runId.substring(0,8)}.csv`)
     document.body.appendChild(link)
     link.click()
     if (link.parentNode) link.parentNode.removeChild(link)
  } catch(e: any) {
     toast.error('Gagal mengunduh CSV: ' + (e.response?.data?.message || e.message))
  }
}

const deletePayrollRun = async (runId: string) => {
  if (!confirm('Peringatan: Menghapus riwayat siklus gaji ini juga akan menghapus SEMUA Slip Gaji karyawan yang terkait dengannya secara permanen. Lanjutkan?')) return
  try {
     await axios.delete(`/payroll/${runId}`)
     toast.success('Siklus gaji berhasil dihapus.')
     fetchPayrollRuns()
  } catch(e: any) {
     toast.error('Gagal menghapus siklus gaji: ' + (e.response?.data?.message || e.message))
  }
}

const generatePayroll = async () => {
  isSubmitting.value = true
  try {
    await axios.post('/payroll/generate', {
      period_start: newRun.value.periodStart,
      period_end: newRun.value.periodEnd,
      payment_schedule: newRun.value.paymentSchedule
    })
    toast.success('Siklus Penggajian Berhasil Dibuat!')
    closeAddModal()
    fetchPayrollRuns()
  } catch(e: any) {
    toast.error('Gagal membuat payroll: ' + (e.response?.data?.message || e.message))
  } finally {
    isSubmitting.value = false
  }
}

onMounted(() => {
  fetchPayrollRuns()
})

const columns = [
  {
    accessorKey: 'id',
    header: 'KODE PERIODE',
    cell: (info: any) => h('span', { class: 'font-bold text-gray-900' }, info.getValue())
  },
  {
    accessorFn: (row: any) => `${row.periodStart} - ${row.periodEnd}`,
    id: 'period',
    header: 'RENTANG WAKTU GAJI',
    cell: (info: any) => h('span', { class: 'text-gray-600' }, info.getValue())
  },
  {
    accessorKey: 'paymentSchedule',
    header: 'TANGGAL PENCAIRAN',
    cell: (info: any) => h('span', { class: 'font-medium text-gray-700' }, info.getValue())
  },
  {
    accessorKey: 'totalPayout',
    header: 'TOTAL PAYOUT',
    cell: ({ getValue }: any) => {
        const val = getValue() as number
        return h('span', { class: 'font-bold text-gray-900' }, `Rp ${val.toLocaleString('id-ID')}`)
    }
  },
  {
    accessorKey: 'status',
    header: 'STATUS',
    cell: ({ getValue }: any) => {
        const val = getValue() as string
        let classes = 'border border-gray-200 text-gray-600 bg-gray-50' 
        if (val === 'PROCESSED') classes = 'border border-blue-200 text-primary bg-primary/5'
        return h('span', { class: `${classes} px-3 py-1.5 rounded-full text-[11px] font-bold inline-block` }, val)
    }
  },
  {
    id: 'actions',
    header: 'AKSI',
    cell: ({ row }: any) => {
      const run = row.original
      const actions = []
      
      if (run.status === 'PROCESSED') {
        actions.push(h(Button, { 
            onClick: () => exportBankCSV(run.id),
            variant: 'outline',
            size: 'sm',
            class: 'flex items-center gap-1.5 text-emerald-700 hover:bg-emerald-100 hover:text-emerald-800 border-emerald-200 h-8 text-[12px]' 
        }, () => [
            h('svg', { class: 'w-3.5 h-3.5', fill: 'none', stroke: 'currentColor', viewBox: '0 0 24 24' }, [
                h('path', { 'stroke-linecap': 'round', 'stroke-linejoin': 'round', 'stroke-width': '2', d: 'M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4' })
            ]),
            'Export Csv Bank'
        ]))
      }

      // Selalu bisa dihapus selama dalam scope admin role
      actions.push(h(Button, { 
            onClick: () => deletePayrollRun(run.id),
            variant: 'ghost',
            size: 'sm',
            class: 'flex items-center gap-1.5 text-red-600 hover:text-red-700 hover:bg-red-50 h-8 text-[12px]' 
        }, () => h(Trash2, { class: 'w-4 h-4' })))

      return h('div', { class: 'flex items-center gap-2' }, actions)
    }
  }
]
</script>

<template>
  <div class="space-y-6">
    <!-- Header Page -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h1 class="text-[22px] font-bold text-gray-900 leading-tight">Gaji & Pembayaran (Payroll)</h1>
        <p class="text-[14px] text-gray-500 mt-1">Jalankan siklus penggajian dan ekspor file ke sistem Bank untuk pencairan massal.</p>
      </div>
      
      <div class="flex items-center gap-3">
        <Button @click="openAddModal" class="gap-2 shadow-sm rounded-lg" size="sm">
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z" />
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          Jalankan Payroll Baru
        </Button>
      </div>
    </div>

    <!-- DataTable Instance -->
    <DataTable :data="payrollRuns" :columns="columns" :isLoading="isLoading">
      <template #headerActions>
        <div class="flex items-center gap-3 w-full sm:w-auto">
          <Select default-value="Semua Tahun">
            <SelectTrigger class="w-[150px] bg-white h-9 text-[13px]">
              <SelectValue placeholder="Pilih Tahun" />
            </SelectTrigger>
            <SelectContent>
              <SelectGroup>
                <SelectItem value="Semua Tahun">Semua Tahun</SelectItem>
                <SelectItem value="2026">2026</SelectItem>
                <SelectItem value="2025">2025</SelectItem>
              </SelectGroup>
            </SelectContent>
          </Select>
        </div>
      </template>
    </DataTable>

    <!-- Create Payroll Run Dialog -->
    <Dialog v-model:open="isModalOpen">
      <DialogContent class="sm:max-w-md">
        <DialogHeader>
          <DialogTitle class="text-xl">Buat Siklus Gaji Baru</DialogTitle>
          <DialogDescription>
            Sistem otomatis menghitung Take Home Pay dari absen historis, allowance, dan potongan.
          </DialogDescription>
        </DialogHeader>

        <div class="grid gap-4 py-4">
          <div class="grid grid-cols-2 gap-4">
             <div class="grid gap-2">
                <label class="text-[13px] font-medium text-gray-700">Tgl Mulai Periode</label>
                <Input v-model="newRun.periodStart" type="date" />
              </div>
              <div class="grid gap-2">
                <label class="text-[13px] font-medium text-gray-700">Tgl Akhir Periode</label>
                <Input v-model="newRun.periodEnd" type="date" />
              </div>
          </div>
          
          <div class="grid gap-2">
            <label class="text-[13px] font-medium text-gray-700">Rencana Tanggal Transfer (Pencairan)</label>
            <Input v-model="newRun.paymentSchedule" type="date" />
          </div>
        </div>
        
        <DialogFooter>
          <Button variant="outline" @click="closeAddModal">Batal</Button>
          <Button @click="generatePayroll" :disabled="isSubmitting">
            {{ isSubmitting ? 'Memproses Gaji...' : 'Proses Payroll Sekarang' }}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>

  </div>
</template>
