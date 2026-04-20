<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
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

const activeTab = ref('sales')
const isLoading = ref(false)

const selectedMonth = ref(new Date().getMonth() + 1)
const selectedYear = ref(new Date().getFullYear())

const regularKPIs = ref<any[]>([])

const fetchKPIs = async () => {
  if (activeTab.value !== 'regular') return
  isLoading.value = true
  try {
    const res = await apiClient.get(`/performance/regular?month=${selectedMonth.value}&year=${selectedYear.value}`)
    if (res.data?.data) {
      regularKPIs.value = res.data.data.map((item: any) => {
        return {
          id: item.ID,
          employee_id: item.EmployeeID,
          name: item.Employee?.first_name || 'Karyawan',
          role: item.Employee?.job_position?.title || '-',
          attendance_score: item.AttendanceScore,
          productivity_score: item.ProductivityScore,
          final_score: item.FinalScore,
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
    // 1. Update Productivity
    await apiClient.put(`/performance/regular/${evaluatingEmployee.value.id}`, {
      productivity_score: Number(evaluateForm.value.productivity_score)
    })
    
    // 2. Add Appraisal if notes exist
    if (evaluateForm.value.notes.trim() !== '') {
      await apiClient.post(`/performance/appraise`, {
        employee_id: evaluatingEmployee.value.employee_id,
        manager_id: '00000000-0000-0000-0000-000000000000', // Auto resolved backend
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

const columns = [
  { key: 'name', label: 'Nama Karyawan' },
  { key: 'role', label: 'Jabatan' },
  { key: 'attendance_score', label: 'Nilai Kehadiran (Auto)' },
  { key: 'productivity_score', label: 'Nilai Produktivitas' },
  { key: 'final_score', label: 'Skor Akhir' },
  { key: 'actions', label: 'Aksi' }
]

const getScoreColor = (score: number) => {
  if (score >= 80) return 'text-emerald-600 bg-emerald-50'
  if (score >= 60) return 'text-orange-600 bg-orange-50'
  return 'text-red-600 bg-red-50'
}

onMounted(() => {
  fetchKPIs()
})
</script>

<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-3xl font-bold tracking-tight text-slate-900">Performa & KPI</h1>
        <p class="text-slate-500 mt-1">Pantau dan evaluasi pencapaian baik untuk tim Operasional/Sales maupun Pekerja Reguler.</p>
      </div>
    </div>

    <!-- Tabs -->
    <div class="border-b border-slate-200">
      <nav class="-mb-px flex space-x-8">
        <button
          @click="activeTab = 'sales'"
          :class="[
            'whitespace-nowrap pb-4 px-1 border-b-2 font-medium text-sm transition-colors',
            activeTab === 'sales' ? 'border-indigo-500 text-indigo-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          ]"
        >
          KPI Sales & Operasional
        </button>
        <button
          @click="() => { activeTab = 'regular'; fetchKPIs() }"
          :class="[
            'whitespace-nowrap pb-4 px-1 border-b-2 font-medium text-sm transition-colors',
            activeTab === 'regular' ? 'border-indigo-500 text-indigo-600' : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
          ]"
        >
          KPI Pekerja Reguler
        </button>
      </nav>
    </div>

    <!-- Content -->
    <div v-if="activeTab === 'sales'" class="space-y-4 animate-in fade-in slide-in-from-bottom-2 duration-300">
      <div class="bg-amber-50 border border-amber-200 rounded-lg p-4 mb-4">
        <div class="flex">
          <div class="flex-shrink-0">
            <svg class="h-5 w-5 text-amber-400" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
            </svg>
          </div>
          <div class="ml-3">
            <h3 class="text-sm font-medium text-amber-800">Tergantung Integrasi Aplikasi Sales</h3>
            <div class="mt-2 text-sm text-amber-700">
              <p>Saat ini data dari aplikasi sales eksternal belum tersedia di sistem. Data pencapaian omzet dan perhitungan bonus otomatis (KPI Sales) akan segera terhubung setelah integrasi rampung.</p>
            </div>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div class="bg-white rounded-xl border border-slate-200 shadow-sm p-6 flex flex-col justify-center items-start opacity-50">
           <h3 class="text-sm font-medium text-slate-500">Omzet Bulan Ini</h3>
           <p class="text-3xl font-bold text-slate-900 mt-2">Rp 450.000.000</p>
           <span class="text-emerald-600 font-medium text-sm mt-2 flex items-center">
             +12.5% dari bulan lalu
           </span>
        </div>
        <div class="bg-white rounded-xl border border-slate-200 shadow-sm p-6 flex flex-col justify-center items-start opacity-50">
           <h3 class="text-sm font-medium text-slate-500">Estimasi Total Bonus</h3>
           <p class="text-3xl font-bold text-slate-900 mt-2">Rp 12.500.000</p>
           <span class="text-slate-500 font-medium text-sm mt-2 flex items-center">
             Berdasarkan capaian sementara
           </span>
        </div>
      </div>
      
      <div class="bg-white rounded-xl border border-slate-200 shadow-sm p-8 text-center mt-6 opacity-50">
         <div class="w-16 h-16 bg-slate-100 rounded-full flex items-center justify-center mx-auto mb-4">
           <svg class="w-8 h-8 text-slate-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
             <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
           </svg>
         </div>
         <h3 class="text-lg font-medium text-slate-900">Data Pencapaian Sales (Mockup)</h3>
         <p class="text-slate-500 mt-1 max-w-sm mx-auto">Grafik dan tabel capaian omzet tiap Sales akan dimuat di sini menggunakan ECharts.</p>
      </div>
    </div>

    <div v-else class="space-y-4 animate-in fade-in slide-in-from-bottom-2 duration-300">
      <div class="flex justify-between items-center bg-white p-4 rounded-xl border border-slate-200 shadow-sm">
        <h3 class="font-medium text-slate-800">Evaluasi Pekerja Reguler</h3>
        <div class="flex gap-3">
          <select v-model="selectedMonth" @change="fetchKPIs" class="border rounded-md px-3 py-1.5 text-sm h-9 bg-white">
            <option v-for="m in 12" :key="m" :value="m">Bulan {{ m }}</option>
          </select>
          <input type="number" v-model="selectedYear" @change="fetchKPIs" class="w-24 border rounded-md px-3 py-1.5 text-sm h-9" />
        </div>
      </div>

      <!-- Regular Employee Table -->
      <DataTable :data="regularKPIs" :columns="columns" :isLoading="isLoading">
        <template #cell-name="{ row }">
          <div class="font-medium text-gray-900">{{ row.name }}</div>
        </template>
        <template #cell-attendance_score="{ row }">
          <span :class="['px-2 py-1 rounded text-xs font-semibold', getScoreColor(row.attendance_score)]">
            {{ parseFloat(row.attendance_score).toFixed(1) }}
          </span>
        </template>
        <template #cell-productivity_score="{ row }">
          <span :class="['px-2 py-1 rounded text-xs font-semibold', getScoreColor(row.productivity_score)]">
            {{ parseFloat(row.productivity_score).toFixed(1) }}
          </span>
        </template>
        <template #cell-final_score="{ row }">
           <span :class="['px-2 py-1 rounded text-xs font-semibold', getScoreColor(row.final_score)]">
            {{ parseFloat(row.final_score).toFixed(1) }}
          </span>
        </template>
        <template #cell-actions="{ row }">
          <Button variant="outline" size="sm" @click="openEvaluateModal(row)">
            Nilai / Peninjauan
          </Button>
        </template>
      </DataTable>

      <!-- Evaluate Modal -->
      <Dialog v-model:open="isModalOpen">
        <DialogContent class="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Evaluasi Kinerja: {{ evaluatingEmployee?.name }}</DialogTitle>
            <DialogDescription>
              Ubah nilai produktivitas dan berikan appraisal langsung.
            </DialogDescription>
          </DialogHeader>

          <div class="space-y-4 py-4">
            <div class="bg-slate-50 p-3 rounded border text-sm">
              <span class="text-slate-500">Nilai Kehadiran (Otomatis):</span> 
              <span class="font-bold text-slate-800 ml-2">{{ evaluatingEmployee?.attendance_score }} / 100</span>
            </div>

            <div class="space-y-2">
              <label class="text-sm font-medium">Nilai Produktivitas (0-100)</label>
              <Input type="number" min="0" max="100" v-model="evaluateForm.productivity_score" />
              <p class="text-xs text-gray-500">Dinilai berdasarkan pencapaian tugas pokok.</p>
            </div>

            <div class="space-y-2">
              <label class="text-sm font-medium">Catatan Penilaian (Appraisal)</label>
              <textarea 
                v-model="evaluateForm.notes" 
                class="w-full flex min-h-[80px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
                placeholder="Evaluasi kinerja umum..."
              ></textarea>
            </div>

            <div class="space-y-2">
              <label class="text-sm font-medium">Rating Eksekutif</label>
              <div class="flex gap-4">
                <label v-for="r in 5" :key="r" class="flex items-center gap-1 cursor-pointer">
                  <input type="radio" :value="r" v-model="evaluateForm.rating" class="text-primary focus:ring-primary h-4 w-4" />
                  <span class="text-sm">{{ r }} Bintang</span>
                </label>
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" @click="closeEvaluateModal" :disabled="isSubmitting">Batal</Button>
            <Button @click="saveEvaluation" :disabled="isSubmitting">
              {{ isSubmitting ? 'Menyimpan...' : 'Simpan Evaluasi' }}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>

  </div>
</template>
