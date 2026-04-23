<script setup lang="ts">
import { ref, h, onMounted } from 'vue'
import { toast } from 'vue-sonner'
import axios from '@/api/axios'
import apiClient from '@/api/axios'
import { Timer, Heart, Percent, Banknote, ShieldAlert, Calculator, Plus, Pencil, Trash2, X, TrendingUp, Settings2, Wallet, Briefcase } from 'lucide-vue-next'
import DataTable from '@/components/DataTable.vue'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectGroup, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'

const isLoading = ref(false)
const activeTab = ref('bpjs')

// --- GLOBAL CONFIG SECTION ---
const config = ref({
  id: '',
  bpjsKesCompanyPercentage: 4.0,
  bpjsKesEmployeePercentage: 1.0,
  bpjsKesMaxWageBase: 12000000,
  jhtCompanyPercentage: 3.7,
  jhtEmployeePercentage: 2.0,
  jpCompanyPercentage: 2.0,
  jpEmployeePercentage: 1.0,
  jpMaxWageBase: 10042300,
  jkkCompanyPercentage: 0.24,
  jkmCompanyPercentage: 0.3,
  ptkpBaseTK0: 54000000,
  absentDeduction: 100000,
  kpiBonusAmount: 500000
})

const fetchConfig = async () => {
  isLoading.value = true
  try {
    const res = await axios.get('/payroll/config')
    if (res.data?.data) {
      const data = res.data.data
      config.value = {
        id: data.id || data.ID,
        bpjsKesCompanyPercentage: data.bpjs_kes_company_percentage || data.BPJSKesCompanyPercentage,
        bpjsKesEmployeePercentage: data.bpjs_kes_employee_percentage || data.BPJSKesEmployeePercentage,
        bpjsKesMaxWageBase: data.bpjs_kes_max_wage_base || data.BPJSKesMaxWageBase,
        jhtCompanyPercentage: data.jht_company_percentage || data.JHTCompanyPercentage,
        jhtEmployeePercentage: data.jht_employee_percentage || data.JHTEmployeePercentage,
        jpCompanyPercentage: data.jp_company_percentage || data.JPCompanyPercentage,
        jpEmployeePercentage: data.jp_employee_percentage || data.JPEmployeePercentage,
        jpMaxWageBase: data.jp_max_wage_base || data.JPMaxWageBase,
        jkkCompanyPercentage: data.jkk_company_percentage || data.JKKCompanyPercentage,
        jkmCompanyPercentage: data.jkm_company_percentage || data.JKMCompanyPercentage,
        ptkpBaseTK0: data.ptkp_base_tk0 || data.PtkpBaseTK0,
        absentDeduction: data.absent_deduction || data.AbsentDeduction || 100000,
        kpiBonusAmount: data.kpi_bonus_amount || data.KPIBonusAmount || 500000
      }
    }
  } catch (error) {
    console.error('Failed to fetch payroll config', error)
  } finally {
    isLoading.value = false
  }
}

const saveConfig = async () => {
  isLoading.value = true
  try {
    const payload = {
      id: config.value.id || undefined,
      jht_company_percentage: Number(config.value.jhtCompanyPercentage),
      jht_employee_percentage: Number(config.value.jhtEmployeePercentage),
      jp_company_percentage: Number(config.value.jpCompanyPercentage),
      jp_employee_percentage: Number(config.value.jpEmployeePercentage),
      jp_max_wage_base: Number(config.value.jpMaxWageBase),
      jkk_company_percentage: Number(config.value.jkkCompanyPercentage),
      jkm_company_percentage: Number(config.value.jkmCompanyPercentage),
      bpjs_kes_company_percentage: Number(config.value.bpjsKesCompanyPercentage),
      bpjs_kes_employee_percentage: Number(config.value.bpjsKesEmployeePercentage),
      bpjs_kes_max_wage_base: Number(config.value.bpjsKesMaxWageBase),
      ptkp_base_tk0: Number(config.value.ptkpBaseTK0),
      absent_deduction: Number(config.value.absentDeduction),
      kpi_bonus_amount: Number(config.value.kpiBonusAmount)
    }
    await axios.put('/payroll/config', payload)
    toast.success('Konfigurasi Penggajian berhasil diperbarui!')
    fetchConfig()
  } catch (error: any) {
    toast.error('Gagal menyimpan konfigurasi: ' + (error.response?.data?.message || error.message))
  } finally {
    isLoading.value = false
  }
}


// --- COMPONENTS SECTION ---
const isCompModalOpen = ref(false)
const newComponent = ref({
  id: '',
  name: '',
  type: 'EARNING',
  isTaxable: true
})
const isCompEditMode = ref(false)
const isCompSubmitting = ref(false)
const components = ref<any[]>([])
const isCompLoading = ref(true)

const openCompAddModal = () => {
  isCompEditMode.value = false
  newComponent.value = { id: '', name: '', type: 'EARNING', isTaxable: true }
  isCompModalOpen.value = true
}

const openCompEditModal = (component: any) => {
  isCompEditMode.value = true
  newComponent.value = {
    id: component.id,
    name: component.name || '',
    type: component.type || 'EARNING',
    isTaxable: component.is_taxable
  }
  isCompModalOpen.value = true
}

const fetchComponents = async () => {
  isCompLoading.value = true
  try {
    const response = await apiClient.get('/payroll-components')
    components.value = response.data.data
  } catch (error) {
    console.error('Failed to fetch payroll components:', error)
  } finally {
    isCompLoading.value = false
  }
}

const saveComponent = async () => {
  isCompSubmitting.value = true
  try {
    if (isCompEditMode.value) {
      await apiClient.put(`/payroll-components/${newComponent.value.id}`, newComponent.value)
      toast.success('Komponen gaji berhasil diperbarui!')
    } else {
      await apiClient.post('/payroll-components', newComponent.value)
      toast.success('Komponen gaji berhasil ditambahkan!')
    }
    isCompModalOpen.value = false
    fetchComponents()
  } catch (error: any) {
    toast.error(`Gagal menyimpan komponen: ` + (error.response?.data?.error || error.message))
  } finally {
    isCompSubmitting.value = false
  }
}

const deleteComponent = async (id: string) => {
  if (!confirm('Apakah Anda yakin ingin menghapus komponen gaji ini?')) return
  try {
    await apiClient.delete(`/payroll-components/${id}`)
    toast.success('Komponen gaji berhasil dihapus!')
    fetchComponents()
  } catch (error: any) {
    toast.error('Gagal menghapus komponen.')
  }
}

const componentColumns = [
  {
    accessorKey: 'name',
    header: 'NAMA KOMPONEN',
    cell: (info: any) => h('span', { class: 'font-black text-slate-800 text-[13px]' }, info.getValue() || '-')
  },
  {
    accessorKey: 'type',
    header: 'TIPE',
    cell: ({ getValue }: any) => {
        const val = getValue() as string || 'Unknown'
        let classes = 'bg-slate-50 text-slate-400 border-slate-100' 
        if (val === 'EARNING') classes = 'bg-emerald-50 text-emerald-600 border-emerald-100'
        else if (val === 'DEDUCTION') classes = 'bg-rose-50 text-rose-600 border-rose-100'
        return h('span', { class: `${classes} px-3 py-1 rounded-full text-[10px] font-black uppercase border tracking-widest` }, val)
    }
  },
  {
    accessorKey: 'is_taxable',
    header: 'KENA PAJAK',
    cell: (info: any) => h('span', { class: 'text-slate-500 font-bold text-[12px]' }, info.getValue() ? 'Ya' : 'Tidak')
  },
  {
    id: 'actions',
    header: 'AKSI',
    cell: ({ row }: any) => {
      const component = row.original
      return h('div', { class: 'flex items-center gap-2' }, [
        h(Button, { 
            variant: 'ghost', size: 'sm', class: 'h-9 px-2 text-rose-600 hover:bg-rose-50 rounded-xl',
            onClick: () => openCompEditModal(component)
        }, () => h(Pencil, { class: 'w-4 h-4' })),
        h(Button, { 
            variant: 'ghost', size: 'sm', class: 'h-9 px-2 text-slate-400 hover:bg-slate-50 rounded-xl',
            onClick: () => deleteComponent(component.id)
        }, () => h(Trash2, { class: 'w-4 h-4' }))
      ])
    }
  }
]


onMounted(() => {
  fetchConfig()
  fetchComponents()
})
</script>

<template>
  <div class="space-y-10 max-w-7xl pb-20 animate-in fade-in duration-1000">
    <!-- Classy Premium Header -->
    <div class="flex flex-col lg:flex-row lg:items-end justify-between gap-8 border-b border-slate-100 pb-10">
      <div class="space-y-3">
        <div class="flex items-center gap-3">
          <div class="w-12 h-12 bg-rose-600 rounded-2xl flex items-center justify-center text-white shadow-xl shadow-rose-200">
            <Settings2 class="w-6 h-6" />
          </div>
          <h1 class="text-4xl font-black text-slate-900 tracking-tighter">
            Pengaturan <span class="text-rose-600">Gaji</span>
          </h1>
        </div>
        <p class="text-[16px] font-medium text-slate-500 max-w-2xl leading-relaxed">
          Pusat konfigurasi parameter finansial, master komponen pendapatan, asuransi kesehatan, dan kebijakan fiskal perusahaan.
        </p>
      </div>
      
      <div class="flex items-center gap-4">
        <button 
          v-if="activeTab !== 'master-components'"
          @click="saveConfig"
          :disabled="isLoading"
          class="bg-rose-600 text-white hover:bg-rose-700 font-black py-5 px-12 rounded-[2rem] text-sm shadow-2xl shadow-rose-200 transition-all hover:translate-y-[-4px] active:translate-y-[0px] disabled:opacity-50 flex items-center justify-center gap-3 group">
          <span v-if="isLoading" class="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></span>
          <Wallet v-else class="w-5 h-5 group-hover:rotate-12 transition-transform" />
          <span>SIMPAN MASTER KONFIGURASI</span>
        </button>
        <button 
          v-else
          @click="openCompAddModal"
          class="bg-slate-900 text-white hover:bg-slate-800 font-black py-5 px-12 rounded-[2rem] text-sm shadow-2xl shadow-slate-200 transition-all hover:translate-y-[-4px] active:translate-y-[0px] flex items-center justify-center gap-3 group">
          <Plus class="w-5 h-5 text-rose-500 group-hover:scale-125 transition-transform" /> 
          <span>TAMBAH KOMPONEN BARU</span>
        </button>
      </div>
    </div>

    <!-- Layout Grid -->
    <div class="grid grid-cols-1 lg:grid-cols-12 gap-10 items-start">
      
      <!-- Premium Sidebar Navigation -->
      <div class="lg:col-span-3 flex flex-col gap-3 shrink-0 sticky top-10">
        <button 
          @click="activeTab = 'bpjs'"
          :class="[
            'text-left px-6 py-6 rounded-[1.75rem] text-[13px] font-black transition-all flex items-center gap-5 border-2',
            activeTab === 'bpjs' ? 'bg-white border-rose-600 text-rose-600 shadow-2xl shadow-rose-100 scale-[1.05]' : 'bg-transparent border-transparent text-slate-400 hover:text-slate-900 hover:bg-slate-50'
          ]">
           <Heart class="w-5 h-5" /> BPJS & ASURANSI
        </button>
        <button 
          @click="activeTab = 'master-components'"
          :class="[
            'text-left px-6 py-6 rounded-[1.75rem] text-[13px] font-black transition-all flex items-center gap-5 border-2',
            activeTab === 'master-components' ? 'bg-white border-rose-600 text-rose-600 shadow-2xl shadow-rose-100 scale-[1.05]' : 'bg-transparent border-transparent text-slate-400 hover:text-slate-900 hover:bg-slate-50'
          ]">
           <Calculator class="w-5 h-5" /> KOMPONEN GAJI
        </button>
        <button 
          @click="activeTab = 'deduction'"
          :class="[
            'text-left px-6 py-6 rounded-[1.75rem] text-[13px] font-black transition-all flex items-center gap-5 border-2',
            activeTab === 'deduction' ? 'bg-white border-rose-600 text-rose-600 shadow-2xl shadow-rose-100 scale-[1.05]' : 'bg-transparent border-transparent text-slate-400 hover:text-slate-900 hover:bg-slate-50'
          ]">
           <ShieldAlert class="w-5 h-5" /> KEBIJAKAN DENDA
        </button>
        <button 
          @click="activeTab = 'pajak'"
          :class="[
            'text-left px-6 py-6 rounded-[1.75rem] text-[13px] font-black transition-all flex items-center gap-5 border-2',
            activeTab === 'pajak' ? 'bg-white border-rose-600 text-rose-600 shadow-2xl shadow-rose-100 scale-[1.05]' : 'bg-transparent border-transparent text-slate-400 hover:text-slate-900 hover:bg-slate-50'
          ]">
           <Percent class="w-5 h-5" /> AMBANG BATAS PAJAK
        </button>
      </div>

      <!-- Main Dynamic Content -->
      <div class="lg:col-span-9 bg-white rounded-[3.5rem] border border-slate-100 shadow-[0_40px_100px_-20px_rgba(0,0,0,0.05)] overflow-hidden min-h-[600px]">
        
        <!-- BPJS Configuration -->
        <div v-if="activeTab === 'bpjs'" class="animate-in slide-in-from-bottom-8 duration-700">
           <div class="p-12 border-b border-slate-50 bg-slate-50/20">
              <h2 class="text-2xl font-black text-slate-900 tracking-tight">Perlindungan Sosial (BPJS)</h2>
              <p class="text-xs font-black text-rose-500 mt-1 uppercase tracking-[0.2em]">Parameter Iuran BPJS Kesehatan & Ketenagakerjaan</p>
           </div>
           
           <div class="p-12 space-y-16">
             <section class="space-y-10">
                <div class="flex items-center justify-between">
                  <div class="flex items-center gap-4">
                    <div class="w-12 h-12 bg-rose-50 rounded-[1.25rem] flex items-center justify-center text-rose-600 border border-rose-100">
                      <Heart class="w-6 h-6" />
                    </div>
                    <div>
                      <h3 class="font-black text-slate-900 text-xl">BPJS Kesehatan</h3>
                      <p class="text-[11px] text-slate-400 font-bold uppercase tracking-widest">Kontribusi Jaminan Kesehatan Nasional</p>
                    </div>
                  </div>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
                  <div class="space-y-3 p-6 bg-slate-50/50 rounded-3xl border border-slate-100/50">
                    <label class="block text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Company Contrib (%)</label>
                    <input type="number" step="0.1" v-model="config.bpjsKesCompanyPercentage" class="w-full bg-white border-2 border-slate-100 rounded-2xl py-5 px-6 focus:outline-none focus:border-rose-500 font-black text-slate-800 transition-all text-xl shadow-sm">
                  </div>
                  <div class="space-y-3 p-6 bg-slate-50/50 rounded-3xl border border-slate-100/50">
                    <label class="block text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Employee Contrib (%)</label>
                    <input type="number" step="0.1" v-model="config.bpjsKesEmployeePercentage" class="w-full bg-white border-2 border-slate-100 rounded-2xl py-5 px-6 focus:outline-none focus:border-rose-500 font-black text-slate-800 transition-all text-xl shadow-sm">
                  </div>
                  <div class="space-y-3 p-6 bg-slate-50/50 rounded-3xl border border-slate-100/50">
                    <label class="block text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Max Wage Base (Rp)</label>
                    <input type="number" v-model="config.bpjsKesMaxWageBase" class="w-full bg-white border-2 border-slate-100 rounded-2xl py-5 px-6 focus:outline-none focus:border-rose-500 font-black text-rose-600 transition-all text-xl shadow-sm">
                  </div>
                </div>
             </section>

             <hr class="border-slate-50">

             <section class="space-y-10">
                <div class="flex items-center gap-4">
                  <div class="w-12 h-12 bg-slate-900 rounded-[1.25rem] flex items-center justify-center text-white shadow-xl shadow-slate-200">
                    <Briefcase class="w-6 h-6" />
                  </div>
                  <div>
                    <h3 class="font-black text-slate-900 text-xl">Program Jamsostek (JHT & JP)</h3>
                    <p class="text-[11px] text-slate-400 font-bold uppercase tracking-widest">Jaminan Hari Tua & Pensiun Berkala</p>
                  </div>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-10">
                  <div class="p-8 bg-rose-50/30 rounded-[2.5rem] border border-rose-100/50 space-y-8">
                     <h4 class="font-black text-rose-700 text-sm tracking-[0.1em] uppercase">Jaminan Hari Tua (JHT)</h4>
                     <div class="grid grid-cols-2 gap-4">
                        <div class="space-y-2">
                           <label class="text-[9px] font-black text-rose-400 uppercase tracking-widest">Company %</label>
                           <input type="number" step="0.1" v-model="config.jhtCompanyPercentage" class="w-full bg-white border border-rose-100 rounded-xl p-4 font-black text-lg focus:ring-2 focus:ring-rose-500 outline-none">
                        </div>
                        <div class="space-y-2">
                           <label class="text-[9px] font-black text-rose-400 uppercase tracking-widest">Employee %</label>
                           <input type="number" step="0.1" v-model="config.jhtEmployeePercentage" class="w-full bg-white border border-rose-100 rounded-xl p-4 font-black text-lg focus:ring-2 focus:ring-rose-500 outline-none">
                        </div>
                     </div>
                  </div>

                  <div class="p-8 bg-slate-50/50 rounded-[2.5rem] border border-slate-100 space-y-8">
                     <h4 class="font-black text-slate-800 text-sm tracking-[0.1em] uppercase">Jaminan Pensiun (JP)</h4>
                     <div class="grid grid-cols-2 gap-4">
                        <div class="space-y-2">
                           <label class="text-[9px] font-black text-slate-400 uppercase tracking-widest">Company %</label>
                           <input type="number" step="0.1" v-model="config.jpCompanyPercentage" class="w-full bg-white border border-slate-100 rounded-xl p-4 font-black text-lg focus:ring-2 focus:ring-rose-500 outline-none">
                        </div>
                        <div class="space-y-2">
                           <label class="text-[9px] font-black text-slate-400 uppercase tracking-widest">Employee %</label>
                           <input type="number" step="0.1" v-model="config.jpEmployeePercentage" class="w-full bg-white border border-slate-100 rounded-xl p-4 font-black text-lg focus:ring-2 focus:ring-rose-500 outline-none">
                        </div>
                     </div>
                     <div class="space-y-2 pt-2">
                        <label class="text-[9px] font-black text-slate-400 uppercase tracking-widest">Max Wage Limit (Rp)</label>
                        <input type="number" v-model="config.jpMaxWageBase" class="w-full bg-white border border-slate-100 rounded-xl p-4 font-black text-rose-600 focus:ring-2 focus:ring-rose-500 outline-none">
                     </div>
                  </div>
                </div>
             </section>
           </div>
        </div>

        <!-- Master Components Table -->
        <div v-if="activeTab === 'master-components'" class="animate-in slide-in-from-bottom-8 duration-700">
           <div class="p-12 border-b border-slate-50 bg-slate-50/20">
              <h2 class="text-2xl font-black text-slate-900 tracking-tight">Katalog Komponen Pendapatan</h2>
              <p class="text-xs font-black text-rose-500 mt-1 uppercase tracking-[0.2em]">Master data tunjangan, bonus, dan potongan variabel</p>
           </div>
           
           <div class="p-6">
                <DataTable :data="components" :columns="componentColumns" :isLoading="isCompLoading" />
           </div>
        </div>

        <!-- Automated Deductions -->
        <div v-if="activeTab === 'deduction'" class="animate-in slide-in-from-bottom-8 duration-700">
           <div class="p-12 border-b border-slate-50 bg-slate-50/20">
              <h2 class="text-2xl font-black text-slate-900 tracking-tight">Kebijakan Denda Kehadiran</h2>
              <p class="text-xs font-black text-rose-500 mt-1 uppercase tracking-[0.2em]">Penalti Otomatis Berdasarkan Log Absensi</p>
           </div>
           
           <div class="p-12 space-y-12">
              <section class="max-w-2xl">
                 <div class="flex items-center gap-4 mb-10">
                   <div class="w-12 h-12 bg-rose-600 rounded-[1.25rem] flex items-center justify-center text-white shadow-xl shadow-rose-200">
                     <ShieldAlert class="w-6 h-6" />
                   </div>
                   <div>
                     <h3 class="font-black text-slate-900 text-xl tracking-tight">Potongan Mangkir (Absent)</h3>
                     <p class="text-[11px] text-slate-400 font-bold uppercase tracking-widest">Denda ketidakhadiran tanpa keterangan</p>
                   </div>
                 </div>
                
                 <div class="bg-slate-900 p-12 rounded-[3.5rem] text-white shadow-3xl shadow-slate-200 mb-10 overflow-hidden relative group">
                     <div class="relative z-10">
                       <label class="block text-[10px] font-black text-rose-500 uppercase tracking-[0.3em] mb-6">Nominal Per Kejadian (IDR)</label>
                       <div class="flex items-center gap-6">
                         <span class="text-3xl font-black text-white/20 tracking-tighter">Rp</span>
                         <input type="number" v-model="config.absentDeduction" class="bg-transparent border-none text-6xl font-black text-white focus:ring-0 w-full p-0 tracking-tighter" />
                       </div>
                       <div class="h-px bg-white/10 my-10"></div>
                       <p class="text-[12px] font-bold text-slate-400 flex items-center gap-3">
                         <Timer class="w-4 h-4 text-rose-500" /> Kalkulasi otomatis saat Payroll diproses
                       </p>
                     </div>
                     <ShieldAlert class="absolute -right-10 -bottom-10 w-48 h-48 opacity-[0.03] group-hover:scale-110 transition-transform duration-700" />
                 </div>
                 
                 <div class="p-8 bg-rose-50 rounded-[2rem] border border-rose-100 flex gap-6 items-start">
                    <div class="p-3 bg-white rounded-xl shadow-sm">
                      <Calculator class="w-5 h-5 text-rose-600" />
                    </div>
                    <div class="space-y-1">
                      <h4 class="text-sm font-black text-slate-900">Logic Perhitungan:</h4>
                      <p class="text-xs text-slate-600 font-medium leading-relaxed">Sistem memindai log status <span class="font-black text-rose-600">"ABSENT"</span> selama periode berjalan. Setiap entitas mangkir akan dikalikan dengan rate penalti di atas.</p>
                    </div>
                 </div>
              </section>

              <hr class="border-slate-50">

              <section class="max-w-2xl">
                 <div class="flex items-center gap-4 mb-10">
                   <div class="w-12 h-12 bg-emerald-600 rounded-[1.25rem] flex items-center justify-center text-white shadow-xl shadow-emerald-200">
                     <TrendingUp class="w-6 h-6" />
                   </div>
                   <div>
                     <h3 class="font-black text-slate-900 text-xl tracking-tight">Bonus Performa (KPI)</h3>
                     <p class="text-[11px] text-slate-400 font-bold uppercase tracking-widest">Insentif Produktivitas Berbasis Skor</p>
                   </div>
                 </div>
                
                 <div class="bg-emerald-600 p-12 rounded-[3.5rem] text-white shadow-3xl shadow-emerald-100 mb-10 overflow-hidden relative group">
                     <div class="relative z-10">
                       <label class="block text-[10px] font-black text-emerald-100 uppercase tracking-[0.3em] mb-6">Maksimal Bonus Tahunan/Bulanan</label>
                       <div class="flex items-center gap-6">
                         <span class="text-3xl font-black text-emerald-900/20 tracking-tighter">Rp</span>
                         <input type="number" v-model="config.kpiBonusAmount" class="bg-transparent border-none text-6xl font-black text-white focus:ring-0 w-full p-0 tracking-tighter" />
                       </div>
                       <div class="h-px bg-white/10 my-10"></div>
                       <p class="text-[12px] font-bold text-emerald-100 flex items-center gap-3">
                         <Calculator class="w-4 h-4" /> Berdasarkan finalisasi skor KPI (0-100)
                       </p>
                     </div>
                     <TrendingUp class="absolute -right-10 -bottom-10 w-48 h-48 opacity-[0.05] group-hover:scale-110 transition-transform duration-700" />
                 </div>
              </section>
           </div>
        </div>

        <!-- Tax Configurations -->
        <div v-if="activeTab === 'pajak'" class="animate-in slide-in-from-bottom-8 duration-700">
           <div class="p-12 border-b border-slate-50 bg-slate-50/20">
              <h2 class="text-2xl font-black text-slate-900 tracking-tight">Perpajakan (PPh 21)</h2>
              <p class="text-xs font-black text-rose-500 mt-1 uppercase tracking-[0.2em]">Ambang Batas Penghasilan Tidak Kena Pajak (PTKP)</p>
           </div>
           
           <div class="p-12 space-y-12">
               <section class="max-w-2xl">
                 <div class="flex items-center gap-4 mb-10">
                   <div class="w-12 h-12 bg-amber-500 rounded-[1.25rem] flex items-center justify-center text-white shadow-xl shadow-amber-200">
                     <Percent class="w-6 h-6" />
                   </div>
                   <div>
                     <h3 class="font-black text-slate-900 text-xl tracking-tight">Standard PTKP TK/0</h3>
                     <p class="text-[11px] text-slate-400 font-bold uppercase tracking-widest">Batas penghasilan tahunan untuk status Single</p>
                   </div>
                 </div>
                 
                 <div class="p-10 bg-slate-50 rounded-[2.5rem] border-2 border-slate-100 space-y-6">
                    <div class="space-y-4">
                      <label class="block text-[11px] font-black text-slate-400 uppercase tracking-widest ml-1">Nilai Dasar Tahunan (Rp)</label>
                      <input type="number" v-model="config.ptkpBaseTK0" class="w-full bg-white border-2 border-slate-100 rounded-3xl py-6 px-10 focus:outline-none focus:border-rose-500 font-black text-3xl text-slate-900 transition-all shadow-sm">
                      <p class="text-[11px] text-slate-400 font-bold ml-1 italic">Default Regulation: Rp 54.000.000 / Tahun</p>
                    </div>
                 </div>

                 <div class="mt-12 p-10 bg-slate-900 rounded-[3.5rem] text-white flex gap-8 items-center group overflow-hidden relative">
                    <div class="p-5 bg-white/10 rounded-2xl relative z-10">
                      <ShieldAlert class="w-8 h-8 text-rose-500" />
                    </div>
                    <div class="relative z-10">
                      <h4 class="font-black text-xl tracking-tight">Kebijakan Tarif TER 2024</h4>
                      <p class="text-xs text-slate-400 font-medium leading-relaxed mt-2 max-w-md">Sistem secara otomatis menerapkan skema <span class="text-rose-500 font-black">Tarif Efektif Rata-rata</span> terbaru untuk kalkulasi pajak yang akurat dan instan.</p>
                    </div>
                    <Banknote class="absolute -right-6 -bottom-6 w-32 h-32 opacity-[0.03] group-hover:scale-110 transition-transform duration-700" />
                 </div>
               </section>
           </div>
        </div>

      </div>
    </div>

    <!-- Premium Component Editor Modal -->
    <Dialog v-model:open="isCompModalOpen">
      <DialogContent class="sm:max-w-xl rounded-[3.5rem] p-0 overflow-hidden border-none shadow-[0_50px_100px_-20px_rgba(225,29,72,0.15)]">
        <div class="bg-slate-900 p-12 text-white relative">
            <DialogHeader>
                <DialogTitle class="text-3xl font-black tracking-tighter">{{ isCompEditMode ? 'Edit Komponen' : 'Komponen Baru' }}</DialogTitle>
                <DialogDescription class="text-rose-500 font-black mt-2 uppercase text-[11px] tracking-[0.25em] border-l-4 border-rose-600 pl-4">
                    Master Finansial Gaji
                </DialogDescription>
            </DialogHeader>
        </div>

        <div class="p-12 bg-white space-y-10">
           <div class="grid gap-3">
            <label class="text-[11px] font-black text-slate-400 uppercase tracking-widest ml-1">Nama Komponen Gaji</label>
            <Input v-model="newComponent.name" placeholder="e.g. Tunjangan Perumahan" class="h-16 rounded-[1.5rem] bg-slate-50 border-2 border-slate-50 font-bold focus:ring-2 focus:ring-rose-600 px-8 text-lg" />
          </div>
          <div class="grid gap-3">
            <label class="text-[11px] font-black text-slate-400 uppercase tracking-widest ml-1">Kategori Tipe Gaji</label>
            <Select v-model="newComponent.type">
              <SelectTrigger class="h-16 rounded-[1.5rem] bg-slate-50 border-2 border-slate-50 font-bold px-8 text-lg">
                <SelectValue placeholder="Pilih Tipe" />
              </SelectTrigger>
              <SelectContent class="rounded-2xl border-slate-100">
                <SelectGroup>
                  <SelectItem value="EARNING" class="rounded-xl py-3 font-bold">Pendapatan (EARNING)</SelectItem>
                  <SelectItem value="DEDUCTION" class="rounded-xl py-3 font-bold">Potongan (DEDUCTION)</SelectItem>
                </SelectGroup>
              </SelectContent>
            </Select>
          </div>
          <div class="flex items-center space-x-4 p-6 bg-slate-50 rounded-[1.5rem] border border-slate-100 transition-all hover:bg-rose-50/30">
            <input type="checkbox" id="taxable" v-model="newComponent.isTaxable" class="w-6 h-6 rounded-lg border-slate-300 text-rose-600 focus:ring-rose-600" />
            <label for="taxable" class="text-[15px] font-black text-slate-800">
              Kena Pajak PPh 21
            </label>
          </div>
        </div>

        <DialogFooter class="p-12 pt-0 bg-white grid grid-cols-2 gap-4">
          <Button variant="ghost" @click="isCompModalOpen = false" class="h-16 rounded-[1.5rem] font-black text-slate-400 border-2 border-slate-50 hover:bg-slate-50 transition-all">BATAL</Button>
          <Button @click="saveComponent" :disabled="isCompSubmitting" class="h-16 rounded-[1.5rem] bg-rose-600 text-white font-black shadow-2xl shadow-rose-200 transition-all hover:translate-y-[-4px] active:translate-y-[0px]">
             {{ isCompSubmitting ? 'MENYIMPAN...' : (isCompEditMode ? 'PERBARUI' : 'TAMBAHKAN') }}
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
