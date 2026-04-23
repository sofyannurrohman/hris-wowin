<script setup lang="ts">
import { ref, h, onMounted } from 'vue'
import { toast } from 'vue-sonner'
import { Trash2, FileSearch, Download, Play, Calendar, Banknote, CheckCircle2, Search, Filter, X, TrendingUp, Wallet, ShieldCheck } from 'lucide-vue-next'
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
        h('span', { class: 'text-slate-400 text-[11px] font-bold uppercase tracking-widest mt-0.5' }, 'Performance log')
    ])
  },
  {
    accessorKey: 'paymentSchedule',
    header: 'TGL PENCAIRAN',
    cell: (info: any) => h('div', { class: 'flex items-center gap-2 text-rose-600 font-black text-[13px]' }, [
        h(Calendar, { class: 'w-3.5 h-3.5' }),
        h('span', {}, info.getValue())
    ])
  },
  {
    accessorKey: 'totalPayout',
    header: 'TOTAL BIAYA (PAYOUT)',
    cell: ({ getValue }: any) => {
        const val = getValue() as number
        return h('span', { class: 'font-black text-slate-900 text-[14px] tabular-nums' }, `Rp ${val.toLocaleString('id-ID')}`)
    }
  },
  {
    accessorKey: 'status',
    header: 'STATUS',
    cell: ({ getValue }: any) => {
        const val = getValue() as string
        let classes = 'bg-slate-50 text-slate-400 border-slate-100' 
        if (val === 'PROCESSED') classes = 'bg-rose-50 text-rose-600 border-rose-100'
        return h('span', { class: `${classes} px-3 py-1 rounded-full text-[10px] font-black uppercase border tracking-[0.2em]` }, val)
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
            variant: 'ghost', size: 'sm', class: 'h-9 px-3 text-slate-500 hover:bg-rose-50 hover:text-rose-600 rounded-xl font-bold gap-2 transition-all' 
        }, () => [h(FileSearch, { class: 'w-4 h-4' }), 'Rincian']))

      if (run.status === 'PROCESSED') {
        actions.push(h(Button, { 
            onClick: () => exportBankCSV(run.id),
            variant: 'outline', size: 'sm', class: 'h-9 px-3 border-emerald-100 bg-emerald-50 text-emerald-600 hover:bg-emerald-100 hover:text-emerald-700 rounded-xl font-bold gap-2' 
        }, () => [h(Download, { class: 'w-4 h-4' }), 'Bank CSV']))
      }

      actions.push(h(Button, { 
            onClick: () => deletePayrollRun(run.id),
            variant: 'ghost', size: 'sm', class: 'h-9 px-2 text-slate-400 hover:bg-rose-50 hover:text-rose-600 rounded-xl' 
        }, () => h(Trash2, { class: 'w-4 h-4' })))

      return h('div', { class: 'flex items-center gap-2' }, actions)
    },
    enableSorting: false
  }
]
</script>

<template>
  <div class="space-y-10 pb-20 animate-in fade-in duration-1000">
    <!-- Classy Premium Header -->
    <div class="flex flex-col lg:flex-row lg:items-end justify-between gap-8 border-b border-slate-100 pb-10">
      <div class="space-y-3">
        <div class="flex items-center gap-4">
           <div class="w-12 h-12 bg-rose-600 rounded-2xl flex items-center justify-center text-white shadow-xl shadow-rose-200">
            <Wallet class="w-6 h-6" />
          </div>
          <h1 class="text-4xl font-black text-slate-900 tracking-tighter">
            Siklus <span class="text-rose-600">Penggajian</span>
          </h1>
        </div>
        <p class="text-[16px] font-medium text-slate-500 max-w-2xl leading-relaxed">
          Automated Financial Settlement Center. Kelola distribusi gaji, rincian slip, dan laporan bank dalam satu dashboard.
        </p>
      </div>
      
      <Button @click="openAddModal" class="gap-4 shadow-2xl shadow-rose-200 rounded-[2rem] h-16 px-10 font-black bg-rose-600 hover:bg-rose-700 transition-all hover:translate-y-[-4px] active:translate-y-[0px] group">
        <Play class="w-5 h-5 fill-current group-hover:scale-110 transition-transform" /> 
        <span>JALANKAN BATCH BARU</span>
      </Button>
    </div>

    <!-- Premium Stats Row -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
        <div class="bg-white p-10 rounded-[3.5rem] border border-slate-100 shadow-xl shadow-slate-100/30 flex items-center gap-8 overflow-hidden relative group">
            <div class="w-16 h-16 bg-rose-50 rounded-[1.5rem] flex items-center justify-center text-rose-600 shrink-0 group-hover:bg-rose-600 group-hover:text-white transition-all duration-500">
                <CheckCircle2 class="w-8 h-8" />
            </div>
            <div>
                <h4 class="text-[11px] font-black text-slate-400 uppercase tracking-[0.2em] mb-2">Siklus Selesai</h4>
                <p class="text-3xl font-black text-slate-900 tracking-tight">{{ payrollRuns.filter(r => r.status === 'PROCESSED').length }}</p>
            </div>
            <Banknote class="absolute -right-10 -bottom-10 w-32 h-32 opacity-[0.03] text-rose-600 group-hover:scale-110 transition-transform duration-700" />
        </div>
        
        <div class="bg-white p-10 rounded-[3.5rem] border border-slate-100 shadow-xl shadow-slate-100/30 flex items-center gap-8 overflow-hidden relative group">
            <div class="w-16 h-16 bg-emerald-50 rounded-[1.5rem] flex items-center justify-center text-emerald-600 shrink-0 group-hover:bg-emerald-600 group-hover:text-white transition-all duration-500">
                <Download class="w-8 h-8" />
            </div>
            <div>
                <h4 class="text-[11px] font-black text-slate-400 uppercase tracking-[0.2em] mb-2">Bank Export</h4>
                <p class="text-3xl font-black text-slate-900 tracking-tight">{{ payrollRuns.filter(r => r.status === 'PROCESSED').length }}</p>
            </div>
            <ShieldCheck class="absolute -right-10 -bottom-10 w-32 h-32 opacity-[0.03] text-emerald-600 group-hover:scale-110 transition-transform duration-700" />
        </div>

        <div class="bg-slate-900 p-10 rounded-[3.5rem] shadow-2xl shadow-slate-200 flex items-center gap-8 text-white overflow-hidden relative group">
            <div class="w-16 h-16 bg-white/10 rounded-[1.5rem] flex items-center justify-center text-rose-500 shrink-0 group-hover:bg-rose-600 group-hover:text-white transition-all duration-500">
                <Calendar class="w-8 h-8" />
            </div>
            <div>
                <h4 class="text-[11px] font-black text-white/40 uppercase tracking-[0.2em] mb-2">Total Batch</h4>
                <p class="text-3xl font-black text-white tracking-tight">{{ payrollRuns.length }}</p>
            </div>
            <Play class="absolute -right-10 -bottom-10 w-32 h-32 opacity-[0.05] fill-white group-hover:scale-110 transition-transform duration-700" />
        </div>
    </div>

    <!-- Data Area -->
    <div class="bg-white rounded-[3.5rem] border border-slate-100 shadow-[0_40px_100px_-20px_rgba(0,0,0,0.05)] overflow-hidden">
        <DataTable :data="payrollRuns" :columns="columns" :isLoading="isLoading">
            <template #headerActions>
                <div class="flex items-center gap-4">
                    <div class="relative w-72 group">
                        <Search class="absolute left-5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400 group-focus-within:text-rose-600 transition-colors" />
                        <Input placeholder="Cari Kode Run..." class="pl-12 h-12 rounded-2xl border-none bg-slate-50 font-bold focus:ring-2 focus:ring-rose-600 px-6" />
                    </div>
                    <Button variant="ghost" class="h-12 px-6 rounded-2xl font-black text-slate-400 gap-3 hover:bg-slate-50">
                        <Filter class="w-4 h-4" /> <span>FILTER</span>
                    </Button>
                </div>
            </template>
        </DataTable>
    </div>

    <!-- Run Detail Modal -->
    <Dialog v-model:open="isDetailModalOpen">
      <DialogContent class="sm:max-w-6xl rounded-[3.5rem] p-0 overflow-hidden border-none shadow-3xl max-h-[95vh] flex flex-col">
        <div class="bg-slate-900 p-10 md:p-14 text-white flex flex-col md:flex-row justify-between items-start md:items-end relative overflow-hidden shrink-0">
            <div class="relative z-10">
                <h2 class="text-3xl md:text-4xl font-black tracking-tighter">Rincian <span class="text-rose-600">Slip Gaji</span></h2>
                <p class="text-[11px] font-black text-rose-500 uppercase tracking-[0.3em] mt-4 border-l-4 border-rose-600 pl-6 leading-loose">
                    PERIODE: {{ selectedRun?.periodStart }} - {{ selectedRun?.periodEnd }}
                </p>
            </div>
            <div class="text-left md:text-right relative z-10 mt-6 md:mt-0">
                <p class="text-[11px] font-black text-slate-500 uppercase tracking-[0.2em] mb-2">TOTAL PENGELUARAN (IDR)</p>
                <p class="text-3xl md:text-5xl font-black text-white tracking-tighter tabular-nums">Rp {{ selectedRun?.totalPayout.toLocaleString('id-ID') }}</p>
            </div>
            <Banknote class="absolute -right-16 -top-16 w-64 h-64 opacity-[0.03] text-white" />
        </div>

        <div class="p-8 md:p-12 flex-1 overflow-y-auto custom-scrollbar bg-white">
            <div v-if="isDetailLoading" class="py-32 flex flex-col items-center justify-center gap-6 text-slate-300">
                <div class="w-12 h-12 border-4 border-rose-600/10 border-t-rose-600 rounded-full animate-spin"></div>
                <p class="font-black text-xs uppercase tracking-[0.3em] text-slate-400">Synchronizing Ledger Records...</p>
            </div>
            <div v-else class="space-y-6">
                <div v-for="slip in payslips" :key="slip.id" class="flex flex-col bg-slate-50/50 rounded-[2.5rem] border border-slate-100 shadow-sm overflow-hidden transition-all group hover:bg-white hover:shadow-xl hover:shadow-rose-100/50">
                    <!-- Summary Card Header -->
                    <div @click="toggleSlip(slip.id)" class="p-6 md:p-8 flex flex-col md:flex-row items-start md:items-center justify-between cursor-pointer transition-all gap-6">
                        <div class="flex items-center gap-6">
                            <div class="w-16 h-16 bg-white rounded-[1.5rem] border border-slate-100 flex items-center justify-center font-black text-slate-900 group-hover:bg-rose-600 group-hover:text-white group-hover:border-rose-600 transition-all shadow-sm shrink-0 text-xl">
                                {{ slip.employee?.first_name?.charAt(0) || '?' }}
                            </div>
                            <div class="flex flex-col">
                                <span class="text-lg font-black text-slate-900 tracking-tight">{{ slip.employee ? `${slip.employee.first_name} ${slip.employee.last_name || ''}` : 'Unknown Employee' }}</span>
                                <span class="text-[11px] font-black text-slate-400 uppercase tracking-[0.2em] mt-0.5">{{ slip.snapshot_job_title }}</span>
                            </div>
                        </div>

                        <div class="flex items-center justify-between w-full md:w-auto md:gap-12">
                            <div class="flex flex-col text-left md:text-right">
                                <span class="text-[10px] font-black text-rose-600 uppercase tracking-[0.2em] mb-1 leading-none">TAKE HOME PAY</span>
                                <span class="text-xl md:text-2xl font-black text-slate-900 tracking-tighter tabular-nums">Rp {{ slip.take_home_pay.toLocaleString('id-ID') }}</span>
                            </div>
                            <div :class="['transition-all duration-500 p-2 rounded-full bg-white group-hover:bg-rose-50', expandedSlipId === slip.id ? 'rotate-180 bg-rose-600 text-white group-hover:bg-rose-600' : 'text-slate-400']">
                                <svg class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M19 9l-7 7-7-7" />
                                </svg>
                            </div>
                        </div>
                    </div>

                    <!-- Expandable Detail Section -->
                    <div v-if="expandedSlipId === slip.id" class="p-10 md:p-14 bg-white border-t border-slate-50 animate-in slide-in-from-top duration-500">
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-12 md:gap-20">
                            <!-- Earnings Column -->
                            <div class="space-y-8">
                                <div class="flex items-center gap-3 pb-3 border-b-2 border-emerald-50">
                                    <TrendingUp class="w-5 h-5 text-emerald-600" />
                                    <h4 class="text-[11px] font-black text-emerald-600 uppercase tracking-[0.25em]">PENDAPATAN (EARNINGS)</h4>
                                </div>
                                <div class="space-y-4">
                                    <div v-for="item in slip.items?.filter((i: any) => i.type === 'EARNING')" :key="item.id" class="flex justify-between items-center group/item">
                                        <span class="text-[15px] font-bold text-slate-500 group-hover/item:text-slate-900 transition-colors">{{ item.component_name }}</span>
                                        <span class="text-[15px] font-black text-slate-900 tabular-nums">Rp {{ item.amount.toLocaleString('id-ID') }}</span>
                                    </div>
                                    <div class="pt-6 mt-6 border-t border-slate-50 flex justify-between items-end">
                                        <span class="text-[11px] font-black text-slate-400 uppercase tracking-widest">Subtotal Pendapatan</span>
                                        <span class="text-xl font-black text-emerald-600 tabular-nums">Rp {{ (slip.basic_salary + (slip.total_allowance || 0)).toLocaleString('id-ID') }}</span>
                                    </div>
                                </div>
                            </div>

                            <!-- Deductions Column -->
                            <div class="space-y-8">
                                <div class="flex items-center gap-3 pb-3 border-b-2 border-rose-50">
                                    <X class="w-5 h-5 text-rose-600" />
                                    <h4 class="text-[11px] font-black text-rose-600 uppercase tracking-[0.25em]">POTONGAN (DEDUCTIONS)</h4>
                                </div>
                                <div class="space-y-4">
                                    <div v-for="item in slip.items?.filter((i: any) => i.type === 'DEDUCTION')" :key="item.id" class="flex justify-between items-center group/item">
                                        <span class="text-[15px] font-bold text-slate-500 group-hover/item:text-slate-900 transition-colors">{{ item.component_name }}</span>
                                        <span class="text-[15px] font-black text-rose-500 tabular-nums">- Rp {{ item.amount.toLocaleString('id-ID') }}</span>
                                    </div>
                                    <div class="pt-6 mt-6 border-t border-slate-50 flex justify-between items-end">
                                        <span class="text-[11px] font-black text-slate-400 uppercase tracking-widest">Subtotal Potongan</span>
                                        <span class="text-xl font-black text-rose-600 tabular-nums">Rp {{ (slip.total_deduction || 0).toLocaleString('id-ID') }}</span>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Summary footer inside expanded view -->
                        <div class="mt-12 md:mt-16 p-10 md:p-12 bg-slate-900 rounded-[3.5rem] flex flex-col md:flex-row items-center justify-between gap-8 pointer-events-none overflow-hidden relative">
                            <div class="flex items-center gap-6 relative z-10">
                                <div class="w-14 h-14 md:w-16 md:h-16 bg-white/10 rounded-[1.5rem] flex items-center justify-center text-rose-500 shadow-inner border border-white/5">
                                    <ShieldCheck class="w-7 h-7 md:w-8 md:h-8" />
                                </div>
                                <div>
                                    <p class="text-[11px] font-black text-slate-500 uppercase tracking-[0.25em] leading-none mb-2">FINAL SETTLEMENT VERIFIED</p>
                                    <p class="text-[13px] font-bold text-slate-400 italic">Financial snapshot generated by HRIS Core.</p>
                                </div>
                            </div>
                            <div class="text-center md:text-right relative z-10">
                                <p class="text-[11px] font-black text-rose-500 uppercase tracking-[0.25em] leading-none mb-2">TRANSFER AMOUNT</p>
                                <p class="text-3xl md:text-4xl font-black text-white tracking-tighter tabular-nums">Rp {{ slip.take_home_pay.toLocaleString('id-ID') }}</p>
                            </div>
                            <Wallet class="absolute -right-10 -bottom-10 w-48 h-48 opacity-[0.05] text-white" />
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="p-10 md:p-12 pt-0 bg-white border-t border-slate-50 flex justify-end shrink-0">
            <Button @click="isDetailModalOpen = false" class="rounded-[1.75rem] h-16 px-12 md:px-20 font-black bg-rose-600 text-white hover:bg-slate-900 shadow-2xl shadow-rose-100 transition-all hover:translate-y-[-4px] active:translate-y-[0px]">TUTUP RINCIAN</Button>
        </div>
      </DialogContent>
    </Dialog>

    <!-- Create Payroll Batch Dialog -->
    <Dialog v-model:open="isModalOpen">
      <DialogContent class="sm:max-w-xl rounded-[3.5rem] p-0 overflow-hidden border-none shadow-3xl max-h-[95vh] flex flex-col">
        <div class="bg-rose-600 p-10 md:p-14 text-white relative shrink-0">
          <DialogHeader>
            <div class="w-14 h-14 md:w-16 md:h-16 bg-white/20 rounded-[1.5rem] flex items-center justify-center mb-8 backdrop-blur-md">
                <Play class="w-7 h-7 md:w-8 md:h-8 fill-current" />
            </div>
            <DialogTitle class="text-2xl md:text-3xl font-black uppercase tracking-tighter">Initiate Final Settlement</DialogTitle>
            <DialogDescription class="text-white/80 font-bold mt-3 uppercase text-[11px] tracking-[0.3em] border-l-4 border-white/40 pl-6 leading-loose">
                Batch Payroll Processing
            </DialogDescription>
          </DialogHeader>
          <Banknote class="absolute -right-16 -bottom-16 w-64 h-64 opacity-10" />
        </div>

        <div class="p-10 md:p-14 space-y-10 bg-white overflow-y-auto custom-scrollbar flex-1">
          <div class="grid grid-cols-2 gap-8">
             <div class="space-y-4">
                <label class="text-[11px] font-black text-slate-400 uppercase tracking-widest ml-1">Mulai Periode</label>
                <div class="relative">
                    <Calendar class="absolute left-5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                    <Input v-model="newRun.periodStart" type="date" class="h-16 pl-14 rounded-[1.5rem] bg-slate-50 border-none font-bold focus:ring-2 focus:ring-rose-600 text-lg shadow-sm px-6" />
                </div>
              </div>
              <div class="space-y-4">
                <label class="text-[11px] font-black text-slate-400 uppercase tracking-widest ml-1">Akhir Periode</label>
                <div class="relative">
                    <Calendar class="absolute left-5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                    <Input v-model="newRun.periodEnd" type="date" class="h-16 pl-14 rounded-[1.5rem] bg-slate-50 border-none font-bold focus:ring-2 focus:ring-rose-600 text-lg shadow-sm px-6" />
                </div>
              </div>
          </div>
          
          <div class="space-y-4">
            <label class="text-[11px] font-black text-slate-400 uppercase tracking-widest ml-1">Target Tanggal Transfer</label>
            <div class="relative">
                <Banknote class="absolute left-5 top-1/2 -translate-y-1/2 w-5 h-5 text-rose-600" />
                <Input v-model="newRun.paymentSchedule" type="date" class="h-16 pl-14 rounded-[1.5rem] bg-rose-50/50 border-none font-black text-rose-700 focus:ring-2 focus:ring-rose-600 text-lg shadow-sm px-6" />
            </div>
          </div>

          <div class="p-8 bg-slate-50 rounded-[2.5rem] border border-slate-100 flex items-start gap-6 shadow-inner transition-all hover:bg-white hover:border-rose-100">
              <div class="p-3 bg-white rounded-xl shadow-sm border border-slate-100">
                <ShieldCheck class="w-6 h-6 text-rose-600 shrink-0" />
              </div>
              <p class="text-[13px] font-medium text-slate-500 leading-relaxed">
                  Sistem akan secara otomatis menghitung <span class="font-black text-slate-900">Gaji Pokok, Tunjangan Aktif, KPI Terfinalisasi, dan Potongan Absen</span> berdasarkan periode yang dipilih.
              </p>
          </div>
        </div>
        
        <DialogFooter class="p-10 md:p-14 pt-0 bg-white grid grid-cols-2 gap-6 shrink-0">
          <Button variant="ghost" @click="isModalOpen = false" :disabled="isSubmitting" class="rounded-[1.75rem] h-16 font-black text-slate-400 border-2 border-slate-50 hover:bg-slate-50 transition-all">BATAL</Button>
          <Button @click="generatePayroll" :disabled="isSubmitting" class="bg-rose-600 hover:bg-rose-700 text-white rounded-[1.75rem] h-16 font-black shadow-2xl shadow-rose-200 transform active:scale-95 transition-all">
             <span v-if="isSubmitting" class="w-5 h-5 border-3 border-white/30 border-t-white rounded-full animate-spin mr-3"></span>
             <span>PROSES BATCH GAJI</span>
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
