<script setup lang="ts">
import { ref, h, onMounted } from 'vue'
import { toast } from 'vue-sonner'
import { Trash2, FileSearch, Download, Play, Calendar, Banknote, CheckCircle2, Search, Filter, X } from 'lucide-vue-next'
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

// Details State
const isDetailModalOpen = ref(false)
const selectedRun = ref<any>(null)
const payslips = ref<any[]>([])
const isDetailLoading = ref(false)
const expandedSlipId = ref<string | null>(null)

const toggleSlip = (id: string) => {
    expandedSlipId.value = expandedSlipId.value === id ? null : id
}

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
        id: r.id || r.ID,
        periodStart: r.period_start || r.PeriodStart ? new Date(r.period_start || r.PeriodStart).toISOString().split('T')[0] : '',
        periodEnd: r.period_end || r.PeriodEnd ? new Date(r.period_end || r.PeriodEnd).toISOString().split('T')[0] : '',
        paymentSchedule: r.payment_schedule || r.PaymentSchedule ? new Date(r.payment_schedule || r.PaymentSchedule).toISOString().split('T')[0] : '',
        status: r.status || r.Status,
        totalPayout: r.total_payout || r.TotalPayout || 0
      }))
    }
  } catch (error) {
    console.error('Failed to fetch payroll history', error)
  } finally {
    isLoading.value = false
  }
}

const openDetails = async (run: any) => {
    selectedRun.value = run
    isDetailModalOpen.value = true
    isDetailLoading.value = true
    try {
        const res = await axios.get(`/payroll/${run.id}/details`)
        payslips.value = res.data.data || []
    } catch (e) {
        toast.error('Gagal memuat rincian slip gaji.')
    } finally {
        isDetailLoading.value = false
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

const exportBankCSV = async (runId: string) => {
  try {
     const res = await axios.get(`/payroll/${runId}/export`, { responseType: 'blob' })
     const url = window.URL.createObjectURL(new Blob([res.data]))
     const link = document.createElement('a')
     link.href = url
     link.setAttribute('download', `payout_bank_${runId.substring(0,8)}.csv`)
     document.body.appendChild(link)
     link.click()
     if (link.parentNode) link.parentNode.removeChild(link)
     toast.success('File ekspor bank siap diunduh.')
  } catch(e: any) {
     toast.error('Gagal mengunduh CSV.')
  }
}

const deletePayrollRun = async (runId: string) => {
  if (!confirm('Hapus siklus ini? Tindakan ini akan menghapus semua slip gaji terkait.')) return
  try {
     await axios.delete(`/payroll/${runId}`)
     toast.success('Siklus gaji dihapus.')
     fetchPayrollRuns()
  } catch(e: any) {
     toast.error('Gagal menghapus.')
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
    toast.success('Batch Payroll Berhasil Diproses!')
    isModalOpen.value = false
    fetchPayrollRuns()
  } catch(e: any) {
    toast.error('Gagal memproses payroll: ' + (e.response?.data?.message || e.message))
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
    header: 'KODE RUN',
    cell: (info: any) => h('span', { class: 'font-black text-slate-400 text-[11px] tracking-tight uppercase' }, '#' + info.getValue().substring(0, 8))
  },
  {
    accessorKey: 'periodStart',
    id: 'period',
    header: 'PERIODE GAJI',
    cell: ({ row }: any) => h('div', { class: 'flex flex-col' }, [
        h('span', { class: 'text-slate-900 font-black text-[13px]' }, `${row.original.periodStart} - ${row.original.periodEnd}`),
        h('span', { class: 'text-slate-400 text-[11px] font-bold' }, 'Log Kehadiran & KPI')
    ])
  },
  {
    accessorKey: 'paymentSchedule',
    header: 'TGL PENCAIRAN',
    cell: (info: any) => h('div', { class: 'flex items-center gap-2 text-indigo-600 font-black text-[13px]' }, [
        h(Calendar, { class: 'w-3.5 h-3.5' }),
        h('span', {}, info.getValue())
    ])
  },
  {
    accessorKey: 'totalPayout',
    header: 'TOTAL BIAYA (PAYOUT)',
    cell: ({ getValue }: any) => {
        const val = getValue() as number
        return h('span', { class: 'font-black text-slate-900 text-[14px]' }, `Rp ${val.toLocaleString('id-ID')}`)
    }
  },
  {
    accessorKey: 'status',
    header: 'STATUS',
    cell: ({ getValue }: any) => {
        const val = getValue() as string
        let classes = 'bg-slate-50 text-slate-400 border-slate-100' 
        if (val === 'PROCESSED') classes = 'bg-indigo-50 text-indigo-600 border-indigo-100'
        return h('span', { class: `${classes} px-3 py-1 rounded-full text-[10px] font-black uppercase border tracking-widest` }, val)
    }
  },
  {
    id: 'actions',
    header: 'NAVIGASI',
    cell: ({ row }: any) => {
      const run = row.original
      const actions = []
      
      actions.push(h(Button, { 
            onClick: () => openDetails(run),
            variant: 'ghost', size: 'sm', class: 'h-9 px-3 text-slate-500 hover:bg-slate-50 hover:text-indigo-600 rounded-xl font-bold gap-2' 
        }, () => [h(FileSearch, { class: 'w-4 h-4' }), 'Rincian']))

      if (run.status === 'PROCESSED') {
        actions.push(h(Button, { 
            onClick: () => exportBankCSV(run.id),
            variant: 'outline', size: 'sm', class: 'h-9 px-3 border-emerald-100 bg-emerald-50 text-emerald-600 hover:bg-emerald-100 hover:text-emerald-700 rounded-xl font-bold gap-2' 
        }, () => [h(Download, { class: 'w-4 h-4' }), 'Bank CSV']))
      }

      actions.push(h(Button, { 
            onClick: () => deletePayrollRun(run.id),
            variant: 'ghost', size: 'sm', class: 'h-9 px-2 text-rose-400 hover:bg-rose-50 hover:text-rose-600 rounded-xl' 
        }, () => h(Trash2, { class: 'w-4 h-4' })))

      return h('div', { class: 'flex items-center gap-2' }, actions)
    },
    enableSorting: false
  }
]
</script>

<template>
  <div class="space-y-8 pb-12 animate-in fade-in duration-700">
    <!-- Premium Header -->
    <div class="flex flex-col md:flex-row md:items-center justify-between gap-6">
      <div class="space-y-1">
        <h1 class="text-3xl font-black text-slate-900 tracking-tight flex items-center gap-3">
          <Banknote class="w-8 h-8 text-indigo-600" />
          Siklus Penggajian
        </h1>
        <p class="text-[14px] font-medium text-slate-400 uppercase tracking-widest leading-loose">Automated Financial Settlement Center</p>
      </div>
      
      <Button @click="openAddModal" class="gap-3 shadow-xl shadow-indigo-100 rounded-2xl h-14 px-8 font-black bg-indigo-600 hover:bg-indigo-700 transition-all hover:scale-105 active:scale-95">
        <Play class="w-5 h-5 fill-current" /> JALANKAN BATCH BARU
      </Button>
    </div>

    <!-- Quick Stats Cards (Visual Decoration) -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div class="bg-white p-8 rounded-[2.5rem] border border-slate-200 shadow-xl shadow-slate-100/30 flex items-center gap-6 overflow-hidden relative">
            <div class="w-14 h-14 bg-indigo-50 rounded-2xl flex items-center justify-center text-indigo-600 shrink-0">
                <CheckCircle2 class="w-7 h-7" />
            </div>
            <div>
                <h4 class="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1">Total Siklus Selesai</h4>
                <p class="text-2xl font-black text-slate-900">{{ payrollRuns.filter(r => r.status === 'PROCESSED').length }}</p>
            </div>
            <Banknote class="absolute -right-6 -bottom-6 w-24 h-24 opacity-5 text-indigo-600" />
        </div>
        <div class="bg-white p-8 rounded-[2.5rem] border border-slate-200 shadow-xl shadow-slate-100/30 flex items-center gap-6 overflow-hidden relative">
            <div class="w-14 h-14 bg-emerald-50 rounded-2xl flex items-center justify-center text-emerald-600 shrink-0">
                <Download class="w-7 h-7" />
            </div>
            <div>
                <h4 class="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1">Siap Ekspor Bank</h4>
                <p class="text-2xl font-black text-slate-900">{{ payrollRuns.filter(r => r.status === 'PROCESSED').length }}</p>
            </div>
            <CheckCircle2 class="absolute -right-6 -bottom-6 w-24 h-24 opacity-5 text-emerald-600" />
        </div>
        <div class="bg-indigo-600 p-8 rounded-[2.5rem] shadow-xl shadow-indigo-100 flex items-center gap-6 text-white overflow-hidden relative">
            <div class="w-14 h-14 bg-white/20 rounded-2xl flex items-center justify-center text-white shrink-0">
                <Calendar class="w-7 h-7" />
            </div>
            <div>
                <h4 class="text-[10px] font-black text-white/50 uppercase tracking-widest mb-1">Periode Terdaftar</h4>
                <p class="text-2xl font-black">{{ payrollRuns.length }}</p>
            </div>
            <Play class="absolute -right-6 -bottom-6 w-24 h-24 opacity-10 fill-white" />
        </div>
    </div>

    <!-- Data Area -->
    <div class="bg-white rounded-[2.5rem] border border-slate-200 shadow-2xl shadow-slate-100/50 overflow-hidden">
        <DataTable :data="payrollRuns" :columns="columns" :isLoading="isLoading">
            <template #headerActions>
                <div class="flex items-center gap-3">
                    <div class="relative w-64 group">
                        <Search class="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400 group-focus-within:text-indigo-600 transition-colors" />
                        <Input placeholder="Cari Kode Run..." class="pl-11 h-11 rounded-2xl border-none bg-slate-50 font-bold focus:ring-2 focus:ring-indigo-600" />
                    </div>
                    <Button variant="ghost" class="h-11 px-4 rounded-xl font-black text-slate-400 gap-2">
                        <Filter class="w-4 h-4" /> Filter
                    </Button>
                </div>
            </template>
        </DataTable>
    </div>

    <!-- Run Detail Modal -->
    <Dialog v-model:open="isDetailModalOpen">
      <DialogContent class="sm:max-w-5xl rounded-[3rem] p-0 overflow-hidden border-none shadow-2xl">
        <div class="bg-slate-900 p-10 text-white flex justify-between items-end relative overflow-hidden">
            <div class="relative z-10">
                <h2 class="text-2xl font-black">Rincian Slip Gaji</h2>
                <p class="text-[11px] font-black text-indigo-400 uppercase tracking-[0.2em] mt-2 border-l-4 border-indigo-600 pl-4">
                    Periode: {{ selectedRun?.periodStart }} - {{ selectedRun?.periodEnd }}
                </p>
            </div>
            <div class="text-right relative z-10">
                <p class="text-[10px] font-black text-slate-500 uppercase tracking-widest mb-1">Total Pengeluaran</p>
                <p class="text-3xl font-black text-indigo-400">Rp {{ selectedRun?.totalPayout.toLocaleString('id-ID') }}</p>
            </div>
            <Banknote class="absolute -right-10 -top-10 w-48 h-48 opacity-10 text-white" />
        </div>

        <div class="p-10 max-h-[60vh] overflow-y-auto no-scrollbar">
            <div v-if="isDetailLoading" class="py-20 flex flex-col items-center justify-center gap-4 text-slate-300">
                <div class="w-10 h-10 border-4 border-indigo-100 border-t-indigo-600 rounded-full animate-spin"></div>
                <p class="font-black text-xs uppercase tracking-widest">Memuat database slip gaji...</p>
            </div>
            <div v-else class="space-y-4">
                <div v-for="slip in payslips" :key="slip.id" class="flex flex-col bg-slate-50 rounded-[2rem] border border-slate-100 shadow-sm overflow-hidden transition-all group">
                    <!-- Summary Card Header -->
                    <div @click="toggleSlip(slip.id)" class="p-6 flex items-center justify-between cursor-pointer hover:bg-slate-100 transition-colors">
                        <div class="flex items-center gap-6">
                            <div class="w-14 h-14 bg-white rounded-2xl border border-slate-200 flex items-center justify-center font-black text-slate-900 group-hover:bg-indigo-600 group-hover:text-white transition-all shadow-sm">
                                {{ slip.employee?.first_name?.charAt(0) || '?' }}
                            </div>
                            <div class="flex flex-col">
                                <span class="text-sm font-black text-slate-900 tracking-tight">{{ slip.employee ? `${slip.employee.first_name} ${slip.employee.last_name || ''}` : 'Unknown Employee' }}</span>
                                <span class="text-[11px] font-bold text-slate-400 uppercase tracking-widest">{{ slip.snapshot_job_title }}</span>
                            </div>
                        </div>

                        <div class="flex items-center gap-8">
                            <div class="flex flex-col text-right">
                                <span class="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1 leading-none text-emerald-600">Net Take Home Pay</span>
                                <span class="text-lg font-black text-slate-900 tracking-tighter">Rp {{ slip.take_home_pay.toLocaleString('id-ID') }}</span>
                            </div>
                            <div :class="['transition-transform duration-300', expandedSlipId === slip.id ? 'rotate-180' : '']">
                                <svg class="w-5 h-5 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
                                </svg>
                            </div>
                        </div>
                    </div>

                    <!-- Expandable Detail Section -->
                    <div v-if="expandedSlipId === slip.id" class="p-10 bg-white border-t border-slate-100 animate-in slide-in-from-top duration-300">
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-12">
                            <!-- Earnings Column -->
                            <div class="space-y-6">
                                <div class="flex items-center gap-2 pb-2 border-b-2 border-emerald-50">
                                    <TrendingUp class="w-4 h-4 text-emerald-600" />
                                    <h4 class="text-[11px] font-black text-emerald-600 uppercase tracking-[0.2em]">Pendapatan (Earnings)</h4>
                                </div>
                                <div class="space-y-3">
                                    <div v-for="item in slip.items?.filter((i: any) => i.type === 'EARNING')" :key="item.id" class="flex justify-between items-center group/item">
                                        <span class="text-sm font-bold text-slate-500 group-hover/item:text-slate-900 transition-colors">{{ item.component_name }}</span>
                                        <span class="text-sm font-black text-slate-900">Rp {{ item.amount.toLocaleString('id-ID') }}</span>
                                    </div>
                                    <div class="pt-4 mt-4 border-t border-slate-50 flex justify-between items-center">
                                        <span class="text-xs font-black text-slate-400 uppercase">Subtotal Pendapatan</span>
                                        <span class="text-md font-black text-emerald-600">Rp {{ (slip.basic_salary + (slip.total_allowance || 0)).toLocaleString('id-ID') }}</span>
                                    </div>
                                </div>
                            </div>

                            <!-- Deductions Column -->
                            <div class="space-y-6">
                                <div class="flex items-center gap-2 pb-2 border-b-2 border-rose-50">
                                    <X class="w-4 h-4 text-rose-600" />
                                    <h4 class="text-[11px] font-black text-rose-600 uppercase tracking-[0.2em]">Potongan (Deductions)</h4>
                                </div>
                                <div class="space-y-3">
                                    <div v-for="item in slip.items?.filter((i: any) => i.type === 'DEDUCTION')" :key="item.id" class="flex justify-between items-center group/item">
                                        <span class="text-sm font-bold text-slate-500 group-hover/item:text-slate-400 transition-colors">{{ item.component_name }}</span>
                                        <span class="text-sm font-black text-rose-500">- Rp {{ item.amount.toLocaleString('id-ID') }}</span>
                                    </div>
                                    <div class="pt-4 mt-4 border-t border-slate-50 flex justify-between items-center">
                                        <span class="text-xs font-black text-slate-400 uppercase">Subtotal Potongan</span>
                                        <span class="text-md font-black text-rose-600">Rp {{ (slip.total_deduction || 0).toLocaleString('id-ID') }}</span>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Summary footer inside expanded view -->
                        <div class="mt-12 p-8 bg-slate-900 rounded-[2rem] flex flex-col md:flex-row items-center justify-between gap-6 pointer-events-none">
                            <div class="flex items-center gap-4">
                                <div class="w-12 h-12 bg-white/10 rounded-2xl flex items-center justify-center text-indigo-400 shadow-inner">
                                    <CheckCircle2 class="w-6 h-6" />
                                </div>
                                <div>
                                    <p class="text-[10px] font-black text-slate-500 uppercase tracking-widest leading-none mb-1">Final Settlement</p>
                                    <p class="text-sm font-bold text-slate-300 italic italic">Slips generated & verified by System.</p>
                                </div>
                            </div>
                            <div class="text-right">
                                <p class="text-[10px] font-black text-slate-500 uppercase tracking-widest leading-none mb-1">Transfer Amount</p>
                                <p class="text-3xl font-black text-white tracking-tighter">Rp {{ slip.take_home_pay.toLocaleString('id-ID') }}</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="p-10 pt-0 bg-white border-t border-slate-50 flex justify-end">
            <Button @click="isDetailModalOpen = false" class="rounded-2xl h-14 px-12 font-black bg-indigo-600 text-white hover:bg-slate-900 transition-all">TUTUP</Button>
        </div>
      </DialogContent>
    </Dialog>

    <!-- Create Payroll Run Dialog -->
    <Dialog v-model:open="isModalOpen">
      <DialogContent class="sm:max-w-xl rounded-[3rem] p-0 overflow-hidden border-none shadow-2xl">
        <div class="bg-indigo-600 p-10 text-white relative">
          <DialogHeader>
            <div class="w-14 h-14 bg-white/20 rounded-2xl flex items-center justify-center mb-6">
                <Play class="w-7 h-7 fill-current" />
            </div>
            <DialogTitle class="text-2xl font-black italic italic uppercase tracking-tighter">Initiate Final Settlement</DialogTitle>
            <DialogDescription class="text-indigo-100 font-bold opacity-80 mt-2 uppercase text-[11px] tracking-[0.25em] border-l-4 border-indigo-300 pl-4 leading-loose">
              Pemrosesan Payroll Massal
            </DialogDescription>
          </DialogHeader>
          <Banknote class="absolute -right-10 -bottom-10 w-48 h-48 opacity-10" />
        </div>

        <div class="p-10 space-y-8 bg-white">
          <div class="grid grid-cols-2 gap-6">
             <div class="space-y-3">
                <label class="text-[11px] font-black text-slate-500 uppercase tracking-widest ml-1">Mulai Periode Absen</label>
                <div class="relative">
                    <Calendar class="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                    <Input v-model="newRun.periodStart" type="date" class="h-14 pl-12 rounded-2xl bg-slate-50 border-none font-bold focus:ring-2 focus:ring-indigo-600" />
                </div>
              </div>
              <div class="space-y-3">
                <label class="text-[11px] font-black text-slate-500 uppercase tracking-widest ml-1">Akhir Periode Absen</label>
                <div class="relative">
                    <Calendar class="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                    <Input v-model="newRun.periodEnd" type="date" class="h-14 pl-12 rounded-2xl bg-slate-50 border-none font-bold focus:ring-2 focus:ring-indigo-600" />
                </div>
              </div>
          </div>
          
          <div class="space-y-3">
            <label class="text-[11px] font-black text-slate-500 uppercase tracking-widest ml-1">Target Tanggal Transfer (Payroll Date)</label>
            <div class="relative">
                <Banknote class="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-indigo-600" />
                <Input v-model="newRun.paymentSchedule" type="date" class="h-14 pl-12 rounded-2xl bg-indigo-50 border-none font-black text-indigo-800 focus:ring-2 focus:ring-indigo-600" />
            </div>
          </div>

          <div class="p-6 bg-slate-50 rounded-3xl border border-slate-100 flex items-start gap-4">
              <CheckCircle2 class="w-5 h-5 text-indigo-600 shrink-0 mt-0.5" />
              <p class="text-[12px] font-medium text-slate-500 leading-relaxed">
                  Sistem akan menarik data <span class="font-bold text-slate-900 italic italic">Gaji Pokok, Tunjangan Aktif, KPI Terfinalisasi, dan Potongan Absen</span> secara real-time.
              </p>
          </div>
        </div>
        
        <DialogFooter class="p-10 pt-0 bg-white grid grid-cols-2 gap-4">
          <Button variant="ghost" @click="isModalOpen = false" :disabled="isSubmitting" class="h-14 rounded-2xl font-black text-slate-400 border border-slate-100 hover:bg-slate-50 transition-all">BATAL</Button>
          <Button @click="generatePayroll" :disabled="isSubmitting" class="h-14 rounded-2xl bg-indigo-600 text-white font-black shadow-xl shadow-indigo-100 transition-all active:scale-95">
             <span v-if="isSubmitting" class="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin"></span>
             <span v-else>PROSES SEMUA GAJI</span>
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  </div>
</template>

<style scoped>
.no-scrollbar::-webkit-scrollbar {
    display: none;
}
.no-scrollbar {
    -ms-overflow-style: none;
    scrollbar-width: none;
}
</style>
