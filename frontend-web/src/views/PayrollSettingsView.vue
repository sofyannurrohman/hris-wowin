<script setup lang="ts">
import { ref, h, onMounted } from 'vue'
import { toast } from 'vue-sonner'
import axios from '@/api/axios'
import apiClient from '@/api/axios'
import { Timer, Heart, Percent, Banknote, ShieldAlert, Calculator, Plus, Pencil, Trash2, X, TrendingUp } from 'lucide-vue-next'
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
            variant: 'ghost', size: 'sm', class: 'h-9 px-2 text-indigo-600 hover:bg-slate-50 rounded-xl',
            onClick: () => openCompEditModal(component)
        }, () => h(Pencil, { class: 'w-4 h-4' })),
        h(Button, { 
            variant: 'ghost', size: 'sm', class: 'h-9 px-2 text-rose-400 hover:bg-rose-50 rounded-xl',
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
  <div class="space-y-8 max-w-6xl pb-12 animate-in fade-in duration-700">
    <!-- Premium Header -->
    <div class="flex flex-col lg:flex-row lg:items-center justify-between gap-6">
      <div class="space-y-1">
        <h1 class="text-3xl font-black text-slate-900 tracking-tight flex items-center gap-3">
          <Banknote class="w-8 h-8 text-indigo-600" />
          Pengaturan Gaji & Upah
        </h1>
        <p class="text-[15px] font-medium text-slate-500 max-w-2xl leading-relaxed">
          Kelola master komponen gaji, asuransi BPJS, kebijakan potongan, dan parameter fiskal PPh 21.
        </p>
      </div>
      
      <button 
        v-if="activeTab !== 'master-components'"
        @click="saveConfig"
        :disabled="isLoading"
        class="bg-indigo-600 text-white hover:bg-indigo-700 font-black py-4 px-10 rounded-[1.5rem] text-sm shadow-2xl shadow-indigo-100 transition-all hover:scale-105 active:scale-95 disabled:opacity-50 flex items-center justify-center gap-2">
        <span v-if="isLoading" class="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></span>
        <span v-else>Simpan Perubahan Master</span>
      </button>
      <button 
        v-else
        @click="openCompAddModal"
        class="bg-slate-900 text-white hover:bg-slate-800 font-black py-4 px-10 rounded-[1.5rem] text-sm shadow-2xl shadow-slate-100 transition-all hover:scale-105 active:scale-95 flex items-center justify-center gap-3">
        <Plus class="w-5 h-5 text-indigo-400" /> Tambah Komponen
      </button>
    </div>

    <!-- Main Grid -->
    <div class="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
      
      <!-- Premium Navigation -->
      <div class="lg:col-span-3 flex flex-col gap-2 bg-white/50 backdrop-blur-md p-4 rounded-[2.5rem] border border-slate-200/60 shadow-sm shrink-0 sticky top-4">
        <button 
          @click="activeTab = 'bpjs'"
          :class="[
            'text-left px-5 py-5 rounded-2xl text-[13px] font-black transition-all flex items-center gap-4',
            activeTab === 'bpjs' ? 'bg-indigo-600 text-white shadow-xl shadow-indigo-100 scale-[1.02]' : 'text-slate-500 hover:bg-white hover:text-slate-900'
          ]">
           <Heart class="w-4 h-4" /> BPJS & Asuransi
        </button>
        <button 
          @click="activeTab = 'master-components'"
          :class="[
            'text-left px-5 py-5 rounded-2xl text-[13px] font-black transition-all flex items-center gap-4',
            activeTab === 'master-components' ? 'bg-indigo-600 text-white shadow-xl shadow-indigo-100 scale-[1.02]' : 'text-slate-500 hover:bg-white hover:text-slate-900'
          ]">
           <Calculator class="w-4 h-4" /> Komponen Pendapatan
        </button>
        <button 
          @click="activeTab = 'deduction'"
          :class="[
            'text-left px-5 py-5 rounded-2xl text-[13px] font-black transition-all flex items-center gap-4',
            activeTab === 'deduction' ? 'bg-indigo-600 text-white shadow-xl shadow-indigo-100 scale-[1.02]' : 'text-slate-500 hover:bg-white hover:text-slate-900'
          ]">
           <ShieldAlert class="w-4 h-4" /> Kebijakan Potongan
        </button>
        <button 
          @click="activeTab = 'pajak'"
          :class="[
            'text-left px-5 py-5 rounded-2xl text-[13px] font-black transition-all flex items-center gap-4',
            activeTab === 'pajak' ? 'bg-indigo-600 text-white shadow-xl shadow-indigo-100 scale-[1.02]' : 'text-slate-500 hover:bg-white hover:text-slate-900'
          ]">
           <Percent class="w-4 h-4" /> Ambang Batas PTKP
        </button>
      </div>

      <!-- Content Area -->
      <div class="lg:col-span-9 bg-white rounded-[3rem] border border-slate-200 shadow-2xl shadow-indigo-50/50 overflow-hidden min-h-[550px]">
        
        <!-- Tab: BPJS -->
        <div v-if="activeTab === 'bpjs'" class="animate-in slide-in-from-right-4 duration-500">
           <div class="p-10 border-b border-slate-50 flex items-center justify-between bg-slate-50/30">
             <div>
                <h2 class="text-xl font-black text-slate-900">Perlindungan Karyawan (BPJS)</h2>
                <p class="text-xs font-bold text-slate-400 mt-1 uppercase tracking-widest">Parameter Pemotongan BPJS Ketenagakerjaan & Kesehatan</p>
             </div>
           </div>
           
           <div class="p-10 space-y-12">
             <section>
                <div class="flex items-center gap-3 mb-8">
                  <div class="w-10 h-10 bg-emerald-50 rounded-2xl flex items-center justify-center text-emerald-600 border border-emerald-100">
                    <Heart class="w-5 h-5" />
                  </div>
                  <h3 class="font-black text-slate-800 text-lg tracking-tight">BPJS Kesehatan</h3>
                </div>
                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
                  <div class="space-y-2">
                    <label class="block text-[11px] font-black text-slate-400 uppercase tracking-widest ml-1">Kompany (%)</label>
                    <input type="number" step="0.1" v-model="config.bpjsKesCompanyPercentage" class="w-full bg-slate-50 border-2 border-slate-100 rounded-2xl py-4 px-6 focus:outline-none focus:border-indigo-500 font-bold text-slate-700 transition-all">
                  </div>
                  <div class="space-y-2">
                    <label class="block text-[11px] font-black text-slate-400 uppercase tracking-widest ml-1">Karyawan (%)</label>
                    <input type="number" step="0.1" v-model="config.bpjsKesEmployeePercentage" class="w-full bg-slate-50 border-2 border-slate-100 rounded-2xl py-4 px-6 focus:outline-none focus:border-indigo-500 font-bold text-slate-700 transition-all">
                  </div>
                  <div class="space-y-2 lg:col-span-1">
                    <label class="block text-[11px] font-black text-slate-400 uppercase tracking-widest ml-1">Limit Upah Max (Rp)</label>
                    <input type="number" v-model="config.bpjsKesMaxWageBase" class="w-full bg-slate-50 border-2 border-slate-100 rounded-2xl py-4 px-6 focus:outline-none focus:border-indigo-500 font-black text-indigo-600 transition-all">
                  </div>
                </div>
             </section>

             <hr class="border-slate-50">

             <section>
                <div class="flex items-center gap-3 mb-8">
                  <div class="w-10 h-10 bg-indigo-50 rounded-2xl flex items-center justify-center text-indigo-600 border border-indigo-100">
                    <Timer class="w-5 h-5" />
                  </div>
                  <h3 class="font-black text-slate-800 text-lg tracking-tight">Jaminan Hari Tua (JHT)</h3>
                </div>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
                  <div class="space-y-2">
                    <label class="block text-[11px] font-black text-slate-400 uppercase tracking-widest ml-1">Kompany (%)</label>
                    <input type="number" step="0.1" v-model="config.jhtCompanyPercentage" class="w-full bg-slate-50 border-2 border-slate-100 rounded-2xl py-4 px-6 focus:outline-none focus:border-indigo-500 font-bold text-slate-700 transition-all">
                  </div>
                  <div class="space-y-2">
                    <label class="block text-[11px] font-black text-slate-400 uppercase tracking-widest ml-1">Karyawan (%)</label>
                    <input type="number" step="0.1" v-model="config.jhtEmployeePercentage" class="w-full bg-slate-50 border-2 border-slate-100 rounded-2xl py-4 px-6 focus:outline-none focus:border-indigo-500 font-bold text-slate-700 transition-all">
                  </div>
                </div>
             </section>

             <section>
                <div class="flex items-center gap-3 mb-8">
                  <div class="w-10 h-10 bg-violet-50 rounded-2xl flex items-center justify-center text-violet-600 border border-violet-100">
                    <Timer class="w-5 h-5" />
                  </div>
                  <h3 class="font-black text-slate-800 text-lg tracking-tight">Jaminan Pensiun (JP)</h3>
                </div>
                <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
                  <div class="space-y-2">
                    <label class="block text-[11px] font-black text-slate-400 uppercase tracking-widest ml-1">Kompany (%)</label>
                    <input type="number" step="0.1" v-model="config.jpCompanyPercentage" class="w-full bg-slate-50 border-2 border-slate-100 rounded-2xl py-4 px-6 focus:outline-none focus:border-indigo-500 font-bold text-slate-700 transition-all">
                  </div>
                  <div class="space-y-2">
                    <label class="block text-[11px] font-black text-slate-400 uppercase tracking-widest ml-1">Karyawan (%)</label>
                    <input type="number" step="0.1" v-model="config.jpEmployeePercentage" class="w-full bg-slate-50 border-2 border-slate-100 rounded-2xl py-4 px-6 focus:outline-none focus:border-indigo-500 font-bold text-slate-700 transition-all">
                  </div>
                  <div class="space-y-2">
                    <label class="block text-[11px] font-black text-slate-400 uppercase tracking-widest ml-1">Limit Upah JP (Rp)</label>
                    <input type="number" v-model="config.jpMaxWageBase" class="w-full bg-slate-50 border-2 border-slate-100 rounded-2xl py-4 px-6 focus:outline-none focus:border-indigo-500 font-black text-indigo-600 transition-all">
                  </div>
                </div>
             </section>
           </div>
        </div>

        <!-- Tab: Komponen Gaji (PROPER TABLE) -->
        <div v-if="activeTab === 'master-components'" class="animate-in slide-in-from-right-4 duration-500">
           <div class="p-10 border-b border-slate-50 flex items-center justify-between bg-slate-50/30">
              <div>
                <h2 class="text-xl font-black text-slate-900">Master Komponen Gaji</h2>
                <p class="text-xs font-bold text-slate-400 mt-1 uppercase tracking-widest">Keluar masuk biaya yang dapat di-assign ke karyawan</p>
              </div>
           </div>
           
           <div class="p-4">
               <DataTable :data="components" :columns="componentColumns" :isLoading="isCompLoading" />
           </div>
        </div>

        <!-- Tab: Potongan Otomatis -->
        <div v-if="activeTab === 'deduction'" class="animate-in slide-in-from-right-4 duration-500">
           <div class="p-10 border-b border-slate-50 bg-slate-50/30">
             <h2 class="text-xl font-black text-slate-900">Kebijakan Potongan</h2>
             <p class="text-xs font-bold text-slate-400 mt-1 uppercase tracking-widest">Penalti keterlambatan dan ketidakhadiran</p>
           </div>
           
           <div class="p-10 space-y-10">
              <section class="max-w-md">
                 <div class="flex items-center gap-3 mb-8">
                  <div class="w-10 h-10 bg-rose-50 rounded-2xl flex items-center justify-center text-rose-600 border border-rose-100">
                    <ShieldAlert class="w-5 h-5" />
                  </div>
                  <h3 class="font-black text-slate-800 text-lg tracking-tight">Denda Mangkir (Absent)</h3>
                </div>
                
                <div class="bg-indigo-600 p-8 rounded-[2rem] text-white shadow-2xl shadow-indigo-100 mb-8 overflow-hidden relative">
                    <div class="relative z-10">
                      <label class="block text-[10px] font-black text-indigo-200 uppercase tracking-[0.2em] mb-4">Nominal Potongan per Hari</label>
                      <div class="flex items-center gap-4">
                        <span class="text-2xl font-black opacity-60">Rp</span>
                        <input type="number" v-model="config.absentDeduction" class="bg-transparent border-none text-4xl font-black text-white focus:ring-0 w-full p-0" />
                      </div>
                      <p class="text-[11px] font-bold text-indigo-200 mt-6 flex items-center gap-2">
                        <Timer class="w-3 h-3" /> Dipotong otomatis saat Payroll Batch
                      </p>
                    </div>
                    <ShieldAlert class="absolute -right-6 -bottom-6 w-32 h-32 opacity-10" />
                </div>
                
                <div class="p-6 bg-slate-50 rounded-3xl border border-slate-100">
                   <h4 class="text-sm font-black text-slate-800 mb-2">Cara Kerja:</h4>
                   <p class="text-xs text-slate-500 font-medium leading-relaxed">Sistem akan menghitung jumlah status <span class="font-black text-indigo-600">"ABSENT"</span> di log kehadiran selama periode payroll, lalu mengalikannya dengan nominal di atas.</p>
                </div>
              </section>

              <hr class="border-slate-50">

              <section class="max-w-md">
                 <div class="flex items-center gap-3 mb-8">
                  <div class="w-10 h-10 bg-emerald-50 rounded-2xl flex items-center justify-center text-emerald-600 border border-emerald-100">
                    <TrendingUp class="w-5 h-5" />
                  </div>
                  <h3 class="font-black text-slate-800 text-lg tracking-tight">Bonus Insentif KPI</h3>
                </div>
                
                <div class="bg-emerald-600 p-8 rounded-[2rem] text-white shadow-2xl shadow-emerald-100 mb-8 overflow-hidden relative">
                    <div class="relative z-10">
                      <label class="block text-[10px] font-black text-emerald-100 uppercase tracking-[0.2em] mb-4">Maksimal Bonus (Skor 100)</label>
                      <div class="flex items-center gap-4">
                        <span class="text-2xl font-black opacity-60">Rp</span>
                        <input type="number" v-model="config.kpiBonusAmount" class="bg-transparent border-none text-4xl font-black text-white focus:ring-0 w-full p-0" />
                      </div>
                      <p class="text-[11px] font-bold text-emerald-100 mt-6 flex items-center gap-2">
                        <Timer class="w-3 h-3" /> Berdasarkan Skor Performa (0-100)
                      </p>
                    </div>
                    <TrendingUp class="absolute -right-6 -bottom-6 w-32 h-32 opacity-10" />
                </div>
                
                <div class="p-6 bg-slate-50 rounded-3xl border border-slate-100">
                   <h4 class="text-sm font-black text-slate-800 mb-2">Cara Kerja:</h4>
                   <p class="text-xs text-slate-500 font-medium leading-relaxed">Komponen ini dihitung sebagai: <span class="font-black text-indigo-600">(Skor Akhir / 100) x Nominal</span>. Berlaku untuk karyawan yang status KPI-nya sudah difinalisasi.</p>
                </div>
              </section>
           </div>
        </div>

        <!-- Tab: Pajak (PTKP) -->
        <div v-if="activeTab === 'pajak'" class="animate-in slide-in-from-right-4 duration-500">
           <div class="p-10 border-b border-slate-50 bg-slate-50/30">
             <h2 class="text-xl font-black text-slate-900">Perpajakan (PPH 21)</h2>
             <p class="text-xs font-bold text-slate-400 mt-1 uppercase tracking-widest">Parameter Nasional Penentu Pajak Penghasilan</p>
           </div>
           
           <div class="p-10 space-y-10">
               <section class="max-w-lg">
                 <div class="flex items-center gap-3 mb-8">
                  <div class="w-10 h-10 bg-amber-50 rounded-2xl flex items-center justify-center text-amber-600 border border-amber-100">
                    <Percent class="w-5 h-5" />
                  </div>
                  <h3 class="font-black text-slate-800 text-lg tracking-tight">Indikator PTKP TK/0</h3>
                </div>
                
                <div class="grid grid-cols-1 gap-6">
                  <div class="space-y-3">
                    <label class="block text-[11px] font-black text-slate-400 uppercase tracking-widest ml-1">Nilai Dasar Tahunan (Rp)</label>
                    <input type="number" v-model="config.ptkpBaseTK0" class="w-full bg-slate-50 border-2 border-slate-100 rounded-3xl py-4 px-8 focus:outline-none focus:border-indigo-500 font-black text-2xl text-slate-900 transition-all">
                    <p class="text-[10px] text-slate-400 font-bold ml-1 italic italic">Standard default: Rp 54,000,000 per tahun</p>
                  </div>
                </div>

                <div class="mt-10 p-8 bg-slate-900 rounded-[2.5rem] text-white flex gap-6 items-center">
                    <div class="p-4 bg-white/10 rounded-2xl">
                      <ShieldAlert class="w-8 h-8 text-amber-400" />
                    </div>
                    <div>
                      <h4 class="font-black text-lg">Catatan Kebijakan TER</h4>
                      <p class="text-xs text-slate-400 font-medium leading-relaxed mt-1">Backend Wowin menggunakan skema Tarif Efektif Rata-rata (TER) terbaru 2024 untuk mempermudah perhitungan PPh 21.</p>
                    </div>
                </div>
              </section>
           </div>
        </div>

      </div>
    </div>

    <!-- Component Editor Modal -->
    <Dialog v-model:open="isCompModalOpen">
      <DialogContent class="sm:max-w-xl rounded-[3rem] p-0 overflow-hidden border-none shadow-2xl">
        <div class="bg-slate-900 p-10 text-white relative">
            <DialogHeader>
                <DialogTitle class="text-2xl font-black">{{ isCompEditMode ? 'Edit Komponen' : 'Baru' }}</DialogTitle>
                <DialogDescription class="text-slate-400 font-bold mt-2 uppercase text-[11px] tracking-widest border-l-4 border-indigo-600 pl-4 uppercase tracking-[0.2em]">
                    Master Komponen Gaji
                </DialogDescription>
            </DialogHeader>
        </div>

        <div class="p-10 bg-white space-y-6">
           <div class="grid gap-2">
            <label class="text-[11px] font-black text-slate-500 uppercase tracking-widest ml-1">Nama Komponen</label>
            <Input v-model="newComponent.name" placeholder="e.g. Tunjangan Prestasi" class="h-14 rounded-2xl bg-slate-50 border-none font-bold focus:ring-2 focus:ring-indigo-600 px-6" />
          </div>
          <div class="grid gap-2">
            <label class="text-[11px] font-black text-slate-500 uppercase tracking-widest ml-1">Kategori Tipe</label>
            <Select v-model="newComponent.type">
              <SelectTrigger class="h-14 rounded-2xl bg-slate-50 border-none font-bold px-6">
                <SelectValue placeholder="Pilih Tipe" />
              </SelectTrigger>
              <SelectContent>
                <SelectGroup>
                  <SelectItem value="EARNING">Pendapatan (EARNING)</SelectItem>
                  <SelectItem value="DEDUCTION">Potongan (DEDUCTION)</SelectItem>
                </SelectGroup>
              </SelectContent>
            </Select>
          </div>
          <div class="flex items-center space-x-3 p-4 bg-slate-50 rounded-2xl">
            <input type="checkbox" id="taxable" v-model="newComponent.isTaxable" class="w-5 h-5 rounded-lg border-slate-300 text-indigo-600 focus:ring-indigo-600" />
            <label for="taxable" class="text-sm font-black text-slate-700">
              Kena Pajak PPh 21
            </label>
          </div>
        </div>

        <DialogFooter class="p-10 pt-0 bg-white grid grid-cols-2 gap-4">
          <Button variant="ghost" @click="isCompModalOpen = false" class="h-14 rounded-2xl font-black text-slate-400 border border-slate-100">BATAL</Button>
          <Button @click="saveComponent" :disabled="isCompSubmitting" class="h-14 rounded-2xl bg-indigo-600 text-white font-black shadow-xl shadow-indigo-100 transition-all active:scale-95">
             {{ isCompSubmitting ? 'MENYIMPAN...' : (isCompEditMode ? 'PERBARUI DATA' : 'TAMBAHKAN MASTER') }}
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
