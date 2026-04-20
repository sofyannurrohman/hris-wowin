<script setup lang="ts">
import { ref, h, onMounted } from 'vue'
import { Trash2 } from 'lucide-vue-next'
import apiClient from '@/api/axios'
import DataTable from '@/components/DataTable.vue'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { toast } from 'vue-sonner'

const payrollRuns = ref<any[]>([])
const isLoading = ref(true)
const isRunModalOpen = ref(false)
const isSubmitting = ref(false)

const newRun = ref({
  periodStart: '',
  periodEnd: '',
  paymentSchedule: ''
})

const fetchRuns = async () => {
  isLoading.value = true
  try {
    const res = await apiClient.get('/payroll/all')
    payrollRuns.value = res.data.data
  } catch (e) {
    console.error(e)
  } finally {
    isLoading.value = false
  }
}

const runPayroll = async () => {
  isSubmitting.value = true
  try {
    await apiClient.post('/payroll/generate', {
      period_start: newRun.value.periodStart,
      period_end: newRun.value.periodEnd,
      payment_schedule: newRun.value.paymentSchedule || null
    })
    toast.success('Payroll berhasil dijalankan!')
    isRunModalOpen.value = false
    fetchRuns()
  } catch (err: any) {
    toast.error('Gagal: ' + (err.response?.data?.error || err.message))
  } finally {
    isSubmitting.value = false
  }
}

const exportCSV = async (id: string) => {
  try {
    const res = await apiClient.get(`/payroll/${id}/export`, { responseType: 'blob' })
    const url = window.URL.createObjectURL(new Blob([res.data]))
    const a = document.createElement('a')
    a.href = url
    a.download = `payroll_${id}.csv`
    a.click()
    window.URL.revokeObjectURL(url)
  } catch (err: any) {
    toast.error('Gagal export: ' + (err.response?.data?.error || err.message))
  }
}

const deleteRun = async (id: string) => {
  if (!confirm('Hapus payroll run ini? Semua payslip terkait juga akan terhapus!')) return
  try {
    await apiClient.delete(`/payroll/${id}`)
    toast.success('Payroll run dihapus!')
    fetchRuns()
  } catch (err: any) {
    toast.error('Gagal: ' + (err.response?.data?.error || err.message))
  }
}

onMounted(fetchRuns)

const fmtCurrency = (val: number) =>
  new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(val || 0)

const fmtDate = (d: string) => d ? new Date(d).toLocaleDateString('id-ID', { dateStyle: 'medium' }) : '-'

const columns = [
  {
    id: 'period',
    header: 'PERIODE',
    cell: ({ row }: any) => {
      const r = row.original
      return h('span', { class: 'font-bold text-gray-900' }, `${fmtDate(r.period_start)} – ${fmtDate(r.period_end)}`)
    }
  },
  {
    accessorKey: 'status',
    header: 'STATUS',
    cell: (info: any) => {
      const s = info.getValue()
      const cls = s === 'COMPLETED' ? 'border-green-200 text-green-700'
                : s === 'PROCESSING' ? 'border-blue-200 text-primary'
                : 'border-gray-200 text-gray-600'
      return h('span', { class: `border ${cls} px-3 py-1 rounded-full text-[11px] font-bold` }, s)
    }
  },
  {
    accessorKey: 'total_payout',
    header: 'TOTAL PEMBAYARAN',
    cell: (info: any) => h('span', { class: 'font-semibold text-gray-900' }, fmtCurrency(info.getValue()))
  },
  {
    accessorKey: 'payment_schedule',
    header: 'JADWAL BAYAR',
    cell: (info: any) => h('span', { class: 'text-gray-500 text-[13px]' }, fmtDate(info.getValue()))
  },
  {
    id: 'actions',
    header: 'AKSI',
    cell: ({ row }: any) => {
      const r = row.original
      return h('div', { class: 'flex gap-2 flex-wrap' }, [
        h(Button, { variant: 'ghost', size: 'sm', class: 'h-8 px-2 text-primary hover:bg-primary/5', onClick: () => exportCSV(r.id) }, () => 'Export CSV'),
        h(Button, { variant: 'ghost', size: 'sm', class: 'h-8 px-2 text-red-600 hover:bg-red-50', onClick: () => deleteRun(r.id) }, () => h(Trash2, { class: 'w-4 h-4' }))
      ])
    }
  }
]
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h1 class="text-[22px] font-bold text-gray-900">Penggajian (Payroll Runs)</h1>
        <p class="text-[14px] text-gray-500 mt-1">Jalankan proses penggajian bulanan dan export rekap payslip.</p>
      </div>
      <Button @click="isRunModalOpen = true" size="sm" class="gap-2">
        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z"/><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>
        Jalankan Payroll
      </Button>
    </div>

    <DataTable :data="payrollRuns" :columns="columns" :isLoading="isLoading" />

    <Dialog v-model:open="isRunModalOpen">
      <DialogContent class="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Jalankan Payroll</DialogTitle>
          <DialogDescription>Tentukan periode penggajian yang akan diproses.</DialogDescription>
        </DialogHeader>
        <div class="grid gap-4 py-4">
          <div class="grid gap-2">
            <label class="text-[13px] font-medium">Awal Periode</label>
            <Input v-model="newRun.periodStart" type="date" />
          </div>
          <div class="grid gap-2">
            <label class="text-[13px] font-medium">Akhir Periode</label>
            <Input v-model="newRun.periodEnd" type="date" />
          </div>
          <div class="grid gap-2">
            <label class="text-[13px] font-medium">Jadwal Pembayaran (Opsional)</label>
            <Input v-model="newRun.paymentSchedule" type="date" />
          </div>
        </div>
        <DialogFooter>
          <Button variant="outline" @click="isRunModalOpen = false">Batal</Button>
          <Button @click="runPayroll" :disabled="isSubmitting || !newRun.periodStart || !newRun.periodEnd">
            {{ isSubmitting ? 'Memproses...' : 'Proses Sekarang' }}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  </div>
</template>
