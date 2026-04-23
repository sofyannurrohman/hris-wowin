<script setup lang="ts">
import { ref, onMounted, computed, watch, h } from 'vue'
import { toast } from 'vue-sonner'
import apiClient from '@/api/axios'
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
import { 
  TrendingUp, 
  Users, 
  Award, 
  CheckCircle2, 
  Timer, 
  Filter, 
  Lock,
  ChevronRight,
  Star,
  Building2,
  Box
} from 'lucide-vue-next'
import { useMasterDataStore } from '@/stores/masterData'
import { useAuthStore } from '@/stores/auth'

const masterData = useMasterDataStore()
const authStore = useAuthStore()

const activeTab = ref('sales')
const isLoading = ref(false)

const selectedMonth = ref(new Date().getMonth() + 1)
const selectedYear = ref(new Date().getFullYear())
const selectedDept = ref('ALL')

const regularKPIs = ref<any[]>([])

const fetchKPIs = async () => {
  if (activeTab.value === 'sales') return
  isLoading.value = true
  try {
    const res = await apiClient.get(`/performance/regular?month=${selectedMonth.value}&year=${selectedYear.value}`)
    if (res.data?.data) {
      regularKPIs.value = res.data.data.map((item: any) => {
        return {
          id: item.id,
          employee_id: item.employee_id,
          name: item.employee?.first_name || 'Karyawan',
          role: item.employee?.job_position?.title || '-',
          dept_id: item.employee?.department_id,
          dept_name: item.employee?.department?.name || '',
          attendance_score: item.attendance_score,
          productivity_score: item.productivity_score,
          final_score: item.final_score,
          status: item.status,
          _raw: item
        }
      })
    }
  } catch (e: any) {
    if (e.response && e.response.status === 404) {
      regularKPIs.value = []
    } else {
      toast.error('Gagal mengambil data KPI: ' + (e.response?.data?.message || e.message))
    }
  } finally {
    isLoading.value = false
  }
}

const filteredKPIs = computed(() => {
  let list = regularKPIs.value

  // Global Department Filter from dropdown
  if (selectedDept.value !== 'ALL') {
    list = list.filter(k => k.dept_id === selectedDept.value)
  }

  // Tab Filtering (Heuristic for Office vs Warehouse)
  if (activeTab.value === 'office') {
    return list.filter(k => !k.dept_name.toLowerCase().includes('gudang'))
  } else if (activeTab.value === 'warehouse') {
    return list.filter(k => k.dept_name.toLowerCase().includes('gudang'))
  }

  return list
})

// Dialog State
const isModalOpen = ref(false)
const evaluatingEmployee = ref<any>(null)
const evaluateForm = ref({
  productivity_score: 0,
  notes: '',
  rating: 3,
})
const isSubmitting = ref(false)

const openEvaluateModal = (kpiData: any) => {
  evaluatingEmployee.value = kpiData
  evaluateForm.value = {
    productivity_score: kpiData.productivity_score,
    notes: '',
    rating: 3
  }
  isModalOpen.value = true
}

const closeEvaluateModal = () => {
  isModalOpen.value = false
  evaluatingEmployee.value = null
}

const saveEvaluation = async () => {
  isSubmitting.value = true
  try {
    await apiClient.put(`/performance/regular/${evaluatingEmployee.value.id}`, {
      productivity_score: Number(evaluateForm.value.productivity_score)
    })
    
    if (evaluateForm.value.notes.trim() !== '') {
      await apiClient.post(`/performance/appraise`, {
        employee_id: evaluatingEmployee.value.employee_id,
        manager_id: authStore.user?.id, // Use real Manager ID
        notes: evaluateForm.value.notes,
        rating: Number(evaluateForm.value.rating)
      })
    }

    toast.success('Penilaian berhasil disimpan!')
    closeEvaluateModal()
    fetchKPIs()
  } catch(e: any) {
    toast.error('Gagal menyimpan penilaian: ' + e.message)
  } finally {
    isSubmitting.value = false
  }
}

const finalizeKPI = async (id: string) => {
  if (!confirm('Finalisasi KPI ini? Data akan segera digunakan untuk penggajian.')) return
  isLoading.value = true
  try {
    await apiClient.post(`/performance/regular/${id}/finalize`)
    toast.success('KPI berhasil difinalisasi!')
    fetchKPIs()
  } catch (e: any) {
    toast.error('Gagal finalisasi: ' + e.message)
  } finally {
    isLoading.value = false
  }
}

const finalizeAll = async () => {
    const draftKPIs = filteredKPIs.value.filter(k => k.status === 'DRAFT')
    if (draftKPIs.length === 0) {
        toast.info('Tidak ada KPI draf untuk difinalisasi di filter ini.')
        return
    }

    if (!confirm(`Finalisasi ${draftKPIs.length} KPI secara massal? Data akan dikirim ke modul payroll.`)) return

    isLoading.value = true
    let successCount = 0
    try {
        for (const kpi of draftKPIs) {
            await apiClient.post(`/performance/regular/${kpi.id}/finalize`)
            successCount++
        }
        toast.success(`${successCount} KPI berhasil difinalisasi!`)
        fetchKPIs()
    } catch (e: any) {
        toast.error('Kesalahan saat finalisasi massal.')
        fetchKPIs()
    } finally {
        isLoading.value = false
    }
}

const columns = [
  { 
    accessorKey: 'name', 
    header: 'Karyawan',
    cell: ({ row }: any) => {
        const item = row.original
        return h('div', { class: 'flex items-center gap-4 py-2' }, [
            h('div', { class: 'flex flex-col' }, [
                h('span', { class: 'font-black text-slate-900 text-sm group-hover:text-primary transition-colors cursor-default' }, item.name),
                h('span', { class: 'text-[11px] font-bold text-slate-400 uppercase tracking-tight' }, item.role)
            ])
        ])
    }
  },
  { 
    accessorKey: 'attendance_score', 
    header: 'Kehadiran (50%)',
    cell: ({ row }: any) => {
        const score = parseFloat(row.original.attendance_score)
        return h('div', { class: 'flex items-center gap-3' }, [
            h('div', { class: 'w-24 h-2 bg-slate-100 rounded-full overflow-hidden border border-slate-200' }, [
                h('div', { class: 'h-full bg-emerald-500 shadow-[0_0_8px_rgba(16,185,129,0.5)]', style: `width: ${score}%` })
            ]),
            h('span', { class: 'text-xs font-black text-slate-600' }, `${score.toFixed(0)}%`)
        ])
    }
  },
  { 
    accessorKey: 'productivity_score', 
    header: 'Produktivitas (50%)',
    cell: ({ row }: any) => {
        const score = parseFloat(row.original.productivity_score)
        return h('div', { class: 'flex items-center gap-3' }, [
            h('div', { class: 'w-24 h-2 bg-slate-100 rounded-full overflow-hidden border border-slate-200' }, [
                h('div', { class: 'h-full bg-primary shadow-[0_0_8px_rgba(153,0,0,0.4)]', style: `width: ${score}%` })
            ]),
            h('span', { class: 'text-xs font-black text-slate-600' }, `${score.toFixed(0)}%`)
        ])
    }
  },
  { 
    accessorKey: 'final_score', 
    header: 'Skor Akhir',
    cell: ({ row }: any) => {
        const score = parseFloat(row.original.final_score)
        return h('div', { class: `px-5 py-2 rounded-2xl text-xs font-black border-2 w-fit shadow-md flex items-center gap-2 ring-1 ring-inset ${getScoreColor(score)}` }, 
            score.toFixed(1)
        )
    }
  },
  { 
    accessorKey: 'status', 
    header: 'Status',
    cell: ({ row }: any) => {
        const status = row.original.status
        const cls = status === 'FINALIZED' ? 'bg-primary/5 text-primary border-primary/20 shadow-sm' : 'bg-slate-50 text-slate-500 border-slate-200'
        return h('span', { class: `px-4 py-1.5 rounded-full text-[10px] font-black uppercase tracking-widest border ${cls}` }, status)
    }
  },
  { 
    id: 'actions', 
    header: 'Aksi',
    cell: ({ row }: any) => {
        const item = row.original
        if (item.status === 'DRAFT') {
            return h('div', { class: 'flex items-center gap-2' }, [
                h(Button, {
                    variant: 'outline',
                    size: 'sm',
                    onClick: () => openEvaluateModal(item),
                    class: 'rounded-xl font-black text-primary border-primary/10 hover:bg-primary/5 h-9 transition-all hover:px-6'
                }, () => [ 'REVIEW ', h(ChevronRight, { class: 'w-4 h-4 ml-1' }) ]),
                h(Button, {
                    variant: 'ghost',
                    size: 'icon',
                    onClick: () => finalizeKPI(item.id),
                    class: 'rounded-xl text-slate-300 hover:text-primary hover:bg-primary/5 h-9 w-9 transition-all',
                    title: 'Lock & Finalize'
                }, () => h(Lock, { class: 'w-4 h-4' }))
            ])
        }
        return h('div', { class: 'flex flex-col items-end px-3' }, [
            h('span', { class: 'text-[10px] font-black text-emerald-500 flex items-center gap-1' }, [
                h(CheckCircle2, { class: 'w-3.5 h-3.5' }), ' FINALIZED'
            ]),
            h('span', { class: 'text-[8px] font-bold text-slate-400' }, 'READY FOR PAYROLL')
        ])
    }
  }
]

const getScoreColor = (score: number) => {
  if (score >= 80) return 'text-emerald-700 bg-emerald-50 ring-emerald-200'
  if (score >= 60) return 'text-amber-700 bg-amber-50 ring-amber-200'
  return 'text-rose-700 bg-rose-50 ring-rose-200'
}

watch(activeTab, (newTab) => {
    if (newTab !== 'sales') {
        fetchKPIs()
    }
})

onMounted(() => {
  fetchKPIs()
  masterData.fetchDepartments()
})
</script>

<template>
  <div class="space-y-8 pb-12 animate-in fade-in duration-700">
    <!-- Premium Header Area -->
    <div class="flex flex-col xl:flex-row xl:items-center justify-between gap-6">
      <div>
        <h1 class="text-4xl font-black text-slate-900 tracking-tight flex items-center gap-4">
          Performa & KPI
        </h1>
        <p class="text-[15px] font-medium text-slate-500 mt-3 max-w-2xl leading-relaxed flex items-center gap-2">
          Pusat kendali metrik kinerja. Pantau pencapaian sales, staf kantor, dan operasional gudang secara terpisah.
        </p>
      </div>
      
      <div class="flex items-center gap-3">
        <div class="bg-white/60 backdrop-blur-md border border-slate-200 p-1.5 rounded-2xl flex shadow-sm overflow-x-auto no-scrollbar">
            <button 
              @click="activeTab = 'sales'"
              :class="[
                'px-5 py-2.5 rounded-xl text-sm font-bold transition-all duration-300 flex items-center gap-2 whitespace-nowrap',
                activeTab === 'sales' ? 'bg-primary text-white shadow-lg shadow-primary/20' : 'text-slate-500 hover:text-slate-800'
              ]"
            >
              <TrendingUp class="w-4 h-4" /> Sales & Lapangan
            </button>
            <button 
              @click="activeTab = 'office'"
              :class="[
                'px-5 py-2.5 rounded-xl text-sm font-bold transition-all duration-300 flex items-center gap-2 whitespace-nowrap',
                activeTab === 'office' ? 'bg-primary text-white shadow-lg shadow-primary/20' : 'text-slate-500 hover:text-slate-800'
              ]"
            >
              <Building2 class="w-4 h-4" /> Staf Kantor
            </button>
            <button 
              @click="activeTab = 'warehouse'"
              :class="[
                'px-5 py-2.5 rounded-xl text-sm font-bold transition-all duration-300 flex items-center gap-2 whitespace-nowrap',
                activeTab === 'warehouse' ? 'bg-primary text-white shadow-lg shadow-primary/20' : 'text-slate-500 hover:text-slate-800'
              ]"
            >
              <Box class="w-4 h-4" /> Gudang / Ops
            </button>
        </div>
      </div>
    </div>

    <!-- Main Content for Sales -->
    <div v-if="activeTab === 'sales'" class="space-y-6 animate-in slide-in-from-left-4 duration-500">
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div class="bg-gradient-to-br from-primary to-primary/80 p-8 rounded-[2rem] text-white shadow-2xl shadow-primary/20 relative overflow-hidden group">
            <TrendingUp class="absolute -right-4 -bottom-4 w-32 h-32 opacity-10 group-hover:scale-110 transition-transform duration-700" />
            <p class="text-white/80 font-bold uppercase tracking-wider text-xs">Target Omzet Lapangan</p>
            <h3 class="text-3xl font-black mt-3 text-white">Rp 1.500M</h3>
            <div class="mt-6 flex items-center gap-2 bg-white/10 w-fit px-3 py-1 rounded-full text-xs font-bold border border-white/20 backdrop-blur-sm">
                <TrendingUp class="w-3 h-3 text-emerald-400" /> +15% dari Target
            </div>
        </div>
        
        <div class="bg-white p-8 rounded-[2rem] border border-slate-200 shadow-sm relative group overflow-hidden">
            <Users class="absolute -right-4 -bottom-4 w-32 h-32 text-amber-500/5 group-hover:scale-110 transition-transform duration-700" />
            <p class="text-slate-400 font-bold uppercase tracking-wider text-xs">Penjualan Terbanyak</p>
            <h3 class="text-3xl font-black mt-3 text-slate-900 leading-tight">Yandi Pratama</h3>
            <p class="text-emerald-600 font-bold text-sm mt-3 flex items-center gap-1">Growth 22% <TrendingUp class="w-3 h-3" /></p>
        </div>

        <div class="bg-white p-8 rounded-[2rem] border border-slate-200 shadow-sm relative group overflow-hidden">
             <Filter class="absolute -right-4 -bottom-4 w-32 h-32 text-primary/5 group-hover:scale-110 transition-transform duration-700" />
            <p class="text-slate-400 font-bold uppercase tracking-wider text-xs">Rata-rata Rating Customer</p>
            <h3 class="text-3xl font-black mt-3 text-slate-900">4.8 / 5.0</h3>
            <div class="mt-5 w-full h-2 bg-slate-100 rounded-full overflow-hidden">
                <div class="h-full bg-primary w-[96%] rounded-full shadow-[0_0_8px_rgba(153,0,0,0.3)]"></div>
            </div>
        </div>
      </div>

      <div class="bg-white/40 backdrop-blur-xl border-2 border-dashed border-slate-200 rounded-[2.5rem] p-20 text-center relative overflow-hidden group">
          <div class="relative z-10">
              <div class="w-20 h-20 bg-primary/5 rounded-3xl flex items-center justify-center mx-auto mb-6 transform group-hover:rotate-6 transition-transform duration-500 shadow-inner border border-primary/10">
                  <TrendingUp class="w-10 h-10 text-primary" />
              </div>
              <h3 class="text-2xl font-black text-slate-900">Dashboard Lapangan Real-time</h3>
              <p class="text-slate-500 mt-3 max-w-sm mx-auto font-medium leading-relaxed">Menunggu sinkronisasi data GPS dan Omzet dari aplikasi CRM Wowin.</p>
              <Button variant="outline" class="mt-8 rounded-2xl px-8 font-bold border-primary/10 text-primary hover:bg-primary/5 transition-all hover:scale-105 active:scale-95">HUBUNGI ADMINISTRATOR</Button>
          </div>
          <div class="absolute top-0 right-0 w-64 h-64 bg-primary/5 blur-3xl rounded-full -mr-20 -mt-20"></div>
          <div class="absolute bottom-0 left-0 w-64 h-64 bg-primary/10 blur-3xl rounded-full -ml-20 -mb-20"></div>
      </div>
    </div>

    <!-- Regular Employee Section (Office & Warehouse) -->
    <div v-else class="space-y-6 animate-in slide-in-from-right-4 duration-500">
      
      <!-- Smart Filtering Bar -->
      <div class="bg-white/80 backdrop-blur-lg p-5 rounded-[2rem] border border-slate-200 shadow-sm flex flex-col md:flex-row items-center justify-between gap-6">
        <div class="flex items-center gap-6 overflow-x-auto w-full md:w-auto pb-2 md:pb-0 no-scrollbar">
            <div class="flex flex-col">
                <span class="text-[10px] font-black uppercase text-slate-400 tracking-widest ml-1 mb-1">Periode</span>
                <div class="flex items-center gap-2 bg-slate-100/50 p-1 rounded-xl border border-slate-200/50">
                    <select v-model="selectedMonth" @change="fetchKPIs" class="bg-transparent border-none text-sm font-bold text-slate-700 focus:ring-0 cursor-pointer px-3">
                        <option v-for="m in 12" :key="m" :value="m">Bulan {{ m }}</option>
                    </select>
                    <div class="w-px h-4 bg-slate-300 mx-1"></div>
                    <input type="number" v-model="selectedYear" @change="fetchKPIs" class="bg-transparent border-none text-sm font-bold text-slate-700 w-20 focus:ring-0" />
                </div>
            </div>

            <div class="flex flex-col" v-if="selectedDept">
                <span class="text-[10px] font-black uppercase text-slate-400 tracking-widest ml-1 mb-1">Filter Departemen</span>
                <select v-model="selectedDept" class="bg-slate-100/50 border border-slate-200/50 text-sm font-bold text-slate-700 p-2 px-4 rounded-xl focus:ring-0 cursor-pointer min-w-[200px]">
                    <option value="ALL">Semua Departemen</option>
                    <option v-for="dept in masterData.departments" :key="dept.id" :value="dept.id">{{ dept.name }}</option>
                </select>
            </div>
        </div>

        <div class="flex items-center gap-3 w-full md:w-auto">
            <Button 
                @click="finalizeAll" 
                :disabled="isLoading"
                class="w-full md:w-auto bg-slate-900 hover:bg-slate-800 text-white rounded-2xl px-6 font-bold flex items-center justify-center gap-2 h-11 transform active:scale-95 transition-all shadow-lg active:shadow-none"
            >
                <Lock class="w-4 h-4" /> FINALISASI MASSAL
            </Button>
        </div>
      </div>

      <!-- KPI Table with Rich Design -->
      <div class="bg-white rounded-[2.5rem] border border-slate-200 shadow-sm overflow-hidden shadow-2xl shadow-slate-100/50">
        <DataTable :data="filteredKPIs" :columns="columns" :isLoading="isLoading">
            <template #headerTitle>
                <h2 class="text-[16px] font-black text-slate-900 uppercase tracking-tighter ml-2">Catatan Harian Log Presensi</h2>
            </template>
          </DataTable>
          
          <div v-if="!isLoading && filteredKPIs.length === 0" class="p-24 text-center">
              <div class="w-20 h-20 bg-slate-50 rounded-[2rem] flex items-center justify-center mx-auto mb-6 shadow-inner">
                <Users class="w-10 h-10 text-slate-200" />
              </div>
              <h3 class="text-xl font-black text-slate-900">Belum Ada Records di Sini</h3>
              <p class="text-slate-400 font-bold max-w-xs mx-auto mt-2 leading-relaxed uppercase text-[11px] tracking-widest">Pastikan departemen dan periode yang Anda pilih sudah memiliki data absensi aktif.</p>
          </div>
      </div>

      <!-- Performance Analysis Section -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <div class="bg-gradient-to-br from-primary to-primary/80 rounded-[3rem] p-12 text-white shadow-2xl shadow-primary/20 relative overflow-hidden flex flex-col justify-between min-h-[350px] group">
              <div class="relative z-10">
                  <div class="flex items-center gap-4 mb-8">
                      <div class="p-4 bg-white/10 rounded-2xl border border-white/20 backdrop-blur-sm">
                          <TrendingUp class="w-8 h-8" />
                      </div>
                      <h3 class="text-2xl font-black leading-tight uppercase tracking-tight">Evaluasi Performa<br />{{ activeTab === 'office' ? 'Staf Kantor' : 'Gudang & Operasional' }}</h3>
                  </div>
                  <p class="text-white/80 mt-4 text-[15px] font-medium leading-relaxed max-w-sm opacity-90">
                    {{ activeTab === 'office' ? 'Monitoring kompetensi administratif, responsivitas laporan, dan kepatuhan jam kerja kantor.' : 'Monitoring ketepatan logistik, penanganan stok, dan efisiensi operasional gudang harian.' }}
                  </p>
              </div>
              <div class="flex items-center gap-8 relative z-10">
                  <div class="flex flex-col">
                      <span class="text-5xl font-black tracking-tighter">50:50</span>
                      <span class="text-[10px] font-black uppercase text-white/60 mt-2 tracking-widest">Weightage Ratio</span>
                  </div>
              </div>
              <Timer class="absolute -right-16 -bottom-16 w-80 h-80 text-white/5 transform group-hover:scale-110 transition-transform duration-1000" />
          </div>

          <div class="bg-white rounded-[3rem] p-12 border border-slate-200 shadow-sm flex flex-col justify-center min-h-[350px]">
              <h3 class="text-2xl font-black text-slate-900 tracking-tight mb-10">Metrik Penilaian Individual</h3>
              <div class="space-y-8">
                  <div class="flex items-start gap-6 group">
                      <div class="p-5 bg-emerald-50 rounded-[1.5rem] text-emerald-600 border border-emerald-100 group-hover:scale-110 transition-transform duration-300">
                          <Timer class="w-7 h-7" />
                      </div>
                       <div>
                          <h4 class="font-black text-lg text-slate-800">50% Kehadiran & Kedisiplinan</h4>
                          <p class="text-[13px] text-slate-500 font-medium mt-1 leading-relaxed">Kalkulasi otomatis dari data absensi: Tepat waktu vs Keterlambatan dan Mangkir.</p>
                      </div>
                  </div>
                  <div class="flex items-start gap-6 group">
                      <div class="p-5 bg-primary/5 rounded-[1.5rem] text-primary border border-primary/10 group-hover:scale-110 transition-transform duration-300">
                          <Award class="w-7 h-7" />
                      </div>
                      <div>
                          <h4 class="font-black text-lg text-slate-800">50% Produktivitas & Review</h4>
                          <p class="text-[13px] text-slate-500 font-medium mt-1 leading-relaxed">Penilaian manual oleh HR/Manager berdasarkan evaluasi target kerja bulanan.</p>
                      </div>
                  </div>
              </div>
          </div>
      </div>

      <!-- Evaluate Modal -->
      <Dialog v-model:open="isModalOpen">
        <DialogContent class="sm:max-w-lg rounded-[2rem] md:rounded-[3rem] p-0 overflow-hidden border-none shadow-2xl max-h-[95vh] flex flex-col">
          <div class="bg-gradient-to-r from-primary to-primary/80 p-8 md:p-10 text-white relative shrink-0">
            <div class="absolute right-0 top-0 w-64 h-64 bg-white/5 blur-3xl rounded-full -mr-20 -mt-20"></div>
            <DialogHeader class="relative z-10">
                <div class="w-12 h-12 md:w-16 md:h-16 bg-white/10 rounded-2xl flex items-center justify-center mb-4 md:mb-6 border border-white/20 shadow-inner backdrop-blur-md">
                    <TrendingUp class="w-6 h-6 md:w-8 md:h-8 text-white" />
                </div>
                <DialogTitle class="text-2xl md:text-3xl font-black tracking-tight">Review Performa</DialogTitle>
                <DialogDescription class="text-white/80 font-black opacity-80 mt-2 uppercase text-[10px] md:text-[11px] tracking-[0.2em] border-l-4 border-white/30 pl-4">
                    {{ evaluatingEmployee?.name }} — {{ evaluatingEmployee?.role }}
                </DialogDescription>
            </DialogHeader>
          </div>

          <div class="p-6 md:p-10 space-y-6 md:space-y-8 bg-white overflow-y-auto custom-scrollbar">
            <div class="grid grid-cols-2 gap-4">
                <div class="bg-slate-50 p-6 rounded-3xl border border-slate-100">
                  <span class="text-[10px] font-black text-slate-400 uppercase tracking-widest block mb-2">Automated Score</span> 
                  <span class="font-black text-primary text-3xl">{{ parseInt(evaluatingEmployee?.attendance_score) }}%</span>
                  <span class="text-[9px] font-bold text-slate-400 block mt-1">ATTENDANCE LOGS</span>
                </div>
                <div class="bg-slate-900 p-6 rounded-3xl flex flex-col justify-center">
                    <span class="text-[10px] font-black text-slate-500 uppercase tracking-widest block mb-2">Weight Method</span>
                    <span class="text-white font-black text-xl">50 / 50</span>
                    <span class="text-[9px] font-bold text-slate-500 block mt-1">EQUAL BALANCE</span>
                </div>
            </div>

            <div class="space-y-4">
              <label class="text-[11px] font-black text-slate-500 uppercase tracking-[0.15em] ml-2">Skor Produktivitas (0-100)</label>
              <div class="relative">
                  <Input type="number" min="0" max="100" v-model="evaluateForm.productivity_score" class="h-16 rounded-2xl bg-white border-2 border-slate-100 focus:border-primary focus:ring-0 text-2xl font-black px-8 transition-all" />
                  <div class="absolute right-8 top-1/2 -translate-y-1/2 text-slate-300 font-bold text-lg">%</div>
              </div>
            </div>

            <div class="space-y-4">
              <label class="text-[11px] font-black text-slate-500 uppercase tracking-[0.15em] ml-2">Manajerial Note (Appraisal)</label>
              <textarea 
                v-model="evaluateForm.notes" 
                class="w-full min-h-[120px] rounded-[2rem] border-2 border-slate-100 bg-white px-8 py-6 text-sm font-bold text-slate-700 focus:border-primary focus:ring-0 transition-all placeholder:text-slate-300 shadow-inner"
                placeholder="Tuliskan catatan khusus mengenai performa karyawan bulan ini..."
              ></textarea>
            </div>

            <div class="space-y-4">
              <label class="text-[11px] font-black text-slate-500 uppercase tracking-[0.15em] ml-2 text-center block">Rating Bintang</label>
              <div class="flex justify-between bg-slate-50 p-2 rounded-[2rem] border border-slate-100 shadow-inner">
                <label v-for="r in 5" :key="r" :class="[
                    'flex-1 flex flex-col items-center justify-center py-4 rounded-2xl cursor-pointer transition-all duration-300',
                    evaluateForm.rating == r ? 'bg-white shadow-xl shadow-primary/20 text-primary border border-primary/10' : 'text-slate-300 hover:text-slate-500'
                ]">
                  <input type="radio" :value="r" v-model="evaluateForm.rating" class="sr-only" />
                  <Star :class="['w-6 h-6 mb-1 transition-all', evaluateForm.rating >= r ? 'fill-current scale-110' : '']" />
                  <span class="text-[9px] font-black">{{ r }}</span>
                </label>
              </div>
            </div>
          </div>

          <DialogFooter class="p-8 md:p-10 pt-0 bg-white grid grid-cols-2 gap-4 shrink-0">
            <Button variant="ghost" @click="closeEvaluateModal" :disabled="isSubmitting" class="rounded-2xl h-12 md:h-14 font-black text-slate-400 border border-slate-100 hover:bg-slate-50 transition-all">BATAL</Button>
            <Button @click="saveEvaluation" :disabled="isSubmitting" class="bg-primary hover:bg-primary/90 text-white rounded-2xl h-12 md:h-14 font-black shadow-xl shadow-primary/20 transform active:scale-95 transition-all">
              {{ isSubmitting ? 'SAVING...' : 'PUBLIKASI NILAI' }}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>

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
