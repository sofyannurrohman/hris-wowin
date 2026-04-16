import { ref, onMounted } from 'vue'
import { toast } from 'vue-sonner'
import axios from '@/api/axios'

const isLoading = ref(false)
const activeTab = ref('bpjs')

// Config data structure matching domain.PayrollConfig
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
  
  ptkpBaseTK0: 54000000
})

const fetchConfig = async () => {
  isLoading.value = true
  try {
    const res = await axios.get('/payroll/config')
    if (res.data?.data) {
      const data = res.data.data
      config.value = {
        id: data.ID,
        bpjsKesCompanyPercentage: data.BPJSKesCompanyPercentage,
        bpjsKesEmployeePercentage: data.BPJSKesEmployeePercentage,
        bpjsKesMaxWageBase: data.BPJSKesMaxWageBase,
        jhtCompanyPercentage: data.JHTCompanyPercentage,
        jhtEmployeePercentage: data.JHTEmployeePercentage,
        jpCompanyPercentage: data.JPCompanyPercentage,
        jpEmployeePercentage: data.JPEmployeePercentage,
        jpMaxWageBase: data.JPMaxWageBase,
        jkkCompanyPercentage: data.JKKCompanyPercentage,
        jkmCompanyPercentage: data.JKMCompanyPercentage,
        ptkpBaseTK0: data.PtkpBaseTK0
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
      ptkp_base_tk0: Number(config.value.ptkpBaseTK0)
    }

    await axios.put('/payroll/config', payload)
    toast.success('Konfigurasi Penggajian berhasil diperbarui secara permanen!')
    fetchConfig() // Refresh data
  } catch (error: any) {
    toast.error('Gagal menyimpan konfigurasi: ' + (error.response?.data?.message || error.message))
  } finally {
    isLoading.value = false
  }
}

onMounted(() => {
  fetchConfig()
})
</script>

<template>
  <div class="space-y-6 max-w-5xl">
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h1 class="text-[22px] font-bold text-gray-900 leading-tight">Pengaturan Payroll & Parameter Master</h1>
        <p class="text-[14px] text-gray-500 mt-1">Konfigurasikan persentase pemotongan BPJS dan PTKP/Pajak secara global agar kalkulasi selalu akurat tanpa mengubah sistem backend.</p>
      </div>
      <button 
        @click="saveConfig"
        :disabled="isLoading"
        class="bg-indigo-600 text-white hover:bg-indigo-700 font-medium py-2 px-5 rounded-lg text-sm shadow-sm transition-colors flex items-center justify-center min-w-[120px]">
        <span v-if="isLoading" class="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></span>
        <span v-else>Simpan Perubahan</span>
      </button>
    </div>

    <!-- Layout Container -->
    <div class="flex flex-col md:flex-row gap-6 items-start mt-6">
      
      <!-- Left Sidebar Nav -->
      <div class="w-full md:w-64 flex flex-col gap-1 bg-white p-2 rounded-xl border border-gray-200 shadow-sm shrink-0">
        <button 
          @click="activeTab = 'bpjs'"
          :class="[
            'text-left px-4 py-3 rounded-lg text-[14px] font-medium transition-colors',
            activeTab === 'bpjs' ? 'bg-indigo-50 text-indigo-700' : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
          ]">
           Asuransi BPJS
        </button>
        <button 
          @click="activeTab = 'pajak'"
          :class="[
            'text-left px-4 py-3 rounded-lg text-[14px] font-medium transition-colors',
            activeTab === 'pajak' ? 'bg-indigo-50 text-indigo-700' : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
          ]">
           Tarif Pajak (PTKP & TER)
        </button>
      </div>

      <!-- Main Content Area -->
      <div class="flex-1 bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden min-h-[400px]">
        
        <!-- BPJS SETTINGS TAB -->
        <div v-if="activeTab === 'bpjs'" class="animate-in fade-in slide-in-from-right-4 duration-300">
           <div class="p-6 border-b border-gray-100 bg-gray-50/50">
             <h2 class="text-lg font-bold text-gray-900">Konfigurasi Tarif BPJS</h2>
             <p class="text-xs text-gray-500 mt-1">Gunakan format desimal persen (contoh 4.0 untuk 4%).</p>
           </div>
           
           <div class="p-6 space-y-8">
             
             <!-- BPJS KESEHATAN -->
             <section>
                <div class="flex items-center gap-2 mb-4">
                  <div class="w-2 h-6 bg-emerald-500/100 rounded-sm"></div>
                  <h3 class="font-bold text-gray-800 text-[15px]">BPJS Kesehatan</h3>
                </div>
                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
                  <div>
                    <label class="block text-[12px] font-medium text-gray-700 mb-1">Ditanggung Perusahaan (%)</label>
                    <input type="number" step="0.1" v-model="config.bpjsKesCompanyPercentage" class="w-full border border-gray-300 rounded-md py-2 px-3 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm">
                  </div>
                  <div>
                    <label class="block text-[12px] font-medium text-gray-700 mb-1">Ditanggung Karyawan (%)</label>
                    <input type="number" step="0.1" v-model="config.bpjsKesEmployeePercentage" class="w-full border border-gray-300 rounded-md py-2 px-3 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm">
                  </div>
                  <div class="md:col-span-2 lg:col-span-1">
                    <label class="block text-[12px] font-medium text-gray-700 mb-1">Batas Upah Maksimal (Rp)</label>
                    <input type="number" v-model="config.bpjsKesMaxWageBase" class="w-full border border-gray-300 rounded-md py-2 px-3 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm bg-gray-50">
                  </div>
                </div>
             </section>

             <hr class="border-gray-100">

             <!-- JHT -->
             <section>
                <div class="flex items-center gap-2 mb-4">
                  <div class="w-2 h-6 bg-primary/50 rounded-sm"></div>
                  <h3 class="font-bold text-gray-800 text-[15px]">JHT (Jaminan Hari Tua)</h3>
                </div>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                  <div>
                    <label class="block text-[12px] font-medium text-gray-700 mb-1">Garis Perusahaan (%)</label>
                    <input type="number" step="0.1" v-model="config.jhtCompanyPercentage" class="w-full border border-gray-300 rounded-md py-2 px-3 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm">
                  </div>
                  <div>
                    <label class="block text-[12px] font-medium text-gray-700 mb-1">Potong Karyawan (%)</label>
                    <input type="number" step="0.1" v-model="config.jhtEmployeePercentage" class="w-full border border-gray-300 rounded-md py-2 px-3 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm">
                  </div>
                </div>
             </section>

             <!-- JP -->
             <section>
                <div class="flex items-center gap-2 mb-4">
                  <div class="w-2 h-6 bg-purple-500 rounded-sm"></div>
                  <h3 class="font-bold text-gray-800 text-[15px]">JP (Jaminan Pensiun)</h3>
                </div>
                <div class="grid grid-cols-1 md:grid-cols-3 gap-5">
                  <div>
                    <label class="block text-[12px] font-medium text-gray-700 mb-1">Garis Perusahaan (%)</label>
                    <input type="number" step="0.1" v-model="config.jpCompanyPercentage" class="w-full border border-gray-300 rounded-md py-2 px-3 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm">
                  </div>
                  <div>
                    <label class="block text-[12px] font-medium text-gray-700 mb-1">Potong Karyawan (%)</label>
                    <input type="number" step="0.1" v-model="config.jpEmployeePercentage" class="w-full border border-gray-300 rounded-md py-2 px-3 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm">
                  </div>
                  <div>
                    <label class="block text-[12px] font-medium text-gray-700 mb-1">Batas Upah Maks JP (Rp)</label>
                    <input type="number" v-model="config.jpMaxWageBase" class="w-full border border-gray-300 rounded-md py-2 px-3 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm bg-gray-50">
                  </div>
                </div>
             </section>

             <hr class="border-gray-100">

             <!-- JKK & JKM -->
             <section>
                <div class="flex items-center gap-2 mb-4">
                  <div class="w-2 h-6 bg-yellow-500 rounded-sm"></div>
                  <h3 class="font-bold text-gray-800 text-[15px]">JKK & JKM (Kecelakaan Kerja & Kematian)</h3>
                </div>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                  <div>
                    <label class="block text-[12px] font-medium text-gray-700 mb-1">JKK Ditanggung Perusahaan (%)</label>
                    <input type="number" step="0.01" v-model="config.jkkCompanyPercentage" class="w-full border border-gray-300 rounded-md py-2 px-3 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm">
                  </div>
                  <div>
                    <label class="block text-[12px] font-medium text-gray-700 mb-1">JKM Ditanggung Perusahaan (%)</label>
                    <input type="number" step="0.01" v-model="config.jkmCompanyPercentage" class="w-full border border-gray-300 rounded-md py-2 px-3 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm">
                  </div>
                </div>
             </section>

           </div>
        </div>

        <!-- PAJAK TAB -->
        <div v-if="activeTab === 'pajak'" class="animate-in fade-in slide-in-from-right-4 duration-300">
           <div class="p-6 border-b border-gray-100 bg-gray-50/50">
             <h2 class="text-lg font-bold text-gray-900">Konfigurasi Tarif Pajak (TER)</h2>
             <p class="text-xs text-gray-500 mt-1">Mengatur parameter ambang bawah perpajakan negara.</p>
           </div>
           
           <div class="p-6">
              <section>
                <div class="flex items-center gap-2 mb-4">
                  <div class="w-2 h-6 bg-red-500 rounded-sm"></div>
                  <h3 class="font-bold text-gray-800 text-[15px]">Indikator PTKP (Penghasilan Tidak Kena Pajak)</h3>
                </div>
                
                <div class="bg-primary/5 text-blue-800 p-4 rounded-lg mb-6 text-sm border border-blue-100 flex gap-3">
                   <svg class="w-5 h-5 shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                   <p>Besaran dasar PTKP TK/0 yang menjadi acuan pengali status menikah/tanggungan kodingan backend.</p>
                </div>

                <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                  <div>
                    <label class="block text-[12px] font-medium text-gray-700 mb-1">Nilai Dasar TK/0 (Rp)</label>
                    <input type="number" v-model="config.ptkpBaseTK0" class="w-full border border-gray-300 rounded-md py-2 px-3 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm font-medium">
                  </div>
                </div>
             </section>
           </div>
        </div>

      </div>

    </div>
  </div>
</template>
