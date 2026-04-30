<script setup lang="ts">
import { ref, onMounted } from 'vue'
import apiClient from '@/api/axios'
import { toast } from 'vue-sonner'
import { 
  Search, 
  Plus, 
  MoreVertical, 
  Edit2, 
  Trash2, 
  Users,
  Target,
  TrendingUp,
  MapPin,
  Mail,
  Phone,
  Building2
} from 'lucide-vue-next'
import { Button } from '@/components/ui/button'

const searchQuery = ref('')
const isModalOpen = ref(false)
const isLoading = ref(true)

const salesmen = ref<any[]>([])
const allEmployees = ref<any[]>([])
const isEditing = ref(false)
const currentSalesman = ref({
  employeeID: '',
  name: '',
  targetOmzet: 0,
  targetNewStores: 0,
  workingTerritory: '',
  month: new Date().getMonth() + 1,
  year: new Date().getFullYear()
})

const currentMonth = ref(new Date().getMonth() + 1)
const currentYear = ref(new Date().getFullYear())

const months = [
  { value: 1, label: 'Januari' },
  { value: 2, label: 'Februari' },
  { value: 3, label: 'Maret' },
  { value: 4, label: 'April' },
  { value: 5, label: 'Mei' },
  { value: 6, label: 'Juni' },
  { value: 7, label: 'Juli' },
  { value: 8, label: 'Agustus' },
  { value: 9, label: 'September' },
  { value: 10, label: 'Oktober' },
  { value: 11, label: 'November' },
  { value: 12, label: 'Desember' }
]

const years = Array.from({ length: 5 }, (_, i) => new Date().getFullYear() - 2 + i)

const fetchSalesmen = async () => {
  isLoading.value = true
  const month = currentMonth.value
  const year = currentYear.value

  try {
    const res = await apiClient.get(`/admin/sales/reports/performance?month=${month}&year=${year}`)
    if (res.data?.data) {
      salesmen.value = res.data.data.map((kpi: any) => ({
        id: kpi.ID,
        employeeID: kpi.EmployeeID,
        name: kpi.Employee ? `${kpi.Employee.first_name} ${kpi.Employee.last_name}` : 'Salesman',
        email: kpi.Employee?.user?.email || '-',
        phone: kpi.Employee?.phone_number || '-',
        area: kpi.Employee?.branch?.name || 'Kantor Pusat',
        target: kpi.TargetOmzet,
        targetNewStores: kpi.TargetNewStores,
        workingTerritory: kpi.working_territory || '-',
        branch: kpi.Employee?.branch?.name || '-',
        current: kpi.AchievedOmzet,
        currentLama: kpi.AchievedOmzetLama || 0,
        currentBaru: kpi.AchievedOmzetBaru || 0
      }))
    }
  } catch (error) {
    console.error('Failed to fetch salesmen:', error)
  } finally {
    isLoading.value = false
  }
}

const fetchEmployees = async () => {
  try {
    const res = await apiClient.get('/employees')
    if (res.data?.data) {
      allEmployees.value = res.data.data
    }
  } catch (error) {
    console.error('Failed to fetch employees:', error)
  }
}

const handleEditTarget = (s: any) => {
  isEditing.value = true
  const rawData = salesmen.value.find(item => item.id === s.id)
  currentSalesman.value = {
    employeeID: rawData.employeeID,
    name: s.name,
    targetOmzet: s.target,
    targetNewStores: rawData.targetNewStores || 0,
    workingTerritory: rawData.workingTerritory || '',
    month: currentMonth.value,
    year: currentYear.value
  }
  isModalOpen.value = true
}

const handleSaveTarget = async () => {
  try {
    await apiClient.post('/admin/sales/targets', {
      employee_id: currentSalesman.value.employeeID,
      month: currentSalesman.value.month,
      year: currentSalesman.value.year,
      target_omzet: currentSalesman.value.targetOmzet,
      target_new_stores: currentSalesman.value.targetNewStores,
      working_territory: currentSalesman.value.workingTerritory
    })
    toast.success('Target berhasil diperbarui!')
    isModalOpen.value = false
    fetchSalesmen()
  } catch (error) {
    console.error('Failed to save target:', error)
  }
}

const openAddSalesman = () => {
  isEditing.value = false
  currentSalesman.value = {
    employeeID: '',
    name: '',
    targetOmzet: 0,
    targetNewStores: 0,
    workingTerritory: '',
    month: currentMonth.value,
    year: currentYear.value
  }
  isModalOpen.value = true
}


onMounted(() => {
  fetchSalesmen()
  fetchEmployees()
})

const formatCurrency = (val: number) => {
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(val)
}
</script>

<template>
  <div class="space-y-8 pb-10">
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-6">
      <div>
        <h1 class="text-3xl font-extrabold text-slate-900 tracking-tight">Data Salesman</h1>
        <p class="text-[15px] font-medium text-slate-500 mt-1.5 flex items-center gap-2">
          <Users class="w-4 h-4 text-primary" />
          Manajemen tim lapangan dan monitoring target omzet mereka.
        </p>
      </div>
      <Button @click="openAddSalesman" class="bg-primary hover:bg-primary/90 text-white px-6 py-6 rounded-2xl shadow-lg shadow-primary/20 flex items-center gap-2 font-bold">
        <Plus class="w-5 h-5" /> Tambah Salesman
      </Button>
    </div>

    <!-- Filters & Search -->
    <div class="bg-white p-4 rounded-3xl border border-slate-200 shadow-sm flex flex-col md:flex-row gap-4 items-center">
      <div class="relative flex-1 w-full">
        <Search class="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
        <input 
          v-model="searchQuery"
          type="text" 
          placeholder="Cari nama, email, atau area..." 
          class="w-full pl-12 pr-4 py-3.5 bg-slate-50 border-none rounded-2xl focus:ring-2 focus:ring-primary/20 transition-all font-medium text-slate-900"
        />
      </div>
      <div class="flex gap-2 w-full md:w-auto">
        <select v-model="currentMonth" @change="fetchSalesmen" class="bg-slate-50 border-none rounded-2xl px-6 py-3.5 font-bold text-slate-600 text-sm focus:ring-2 focus:ring-primary/20">
          <option v-for="m in months" :key="m.value" :value="m.value">{{ m.label }}</option>
        </select>
        <select v-model="currentYear" @change="fetchSalesmen" class="bg-slate-50 border-none rounded-2xl px-6 py-3.5 font-bold text-slate-600 text-sm focus:ring-2 focus:ring-primary/20">
          <option v-for="y in years" :key="y" :value="y">{{ y }}</option>
        </select>
      </div>
    </div>

    <!-- Table -->
    <div class="bg-white rounded-3xl border border-slate-200 shadow-sm overflow-hidden">
      <table class="w-full text-left border-collapse">
        <thead>
          <tr class="bg-slate-50/50 uppercase text-[10px] font-extrabold text-slate-400 tracking-[0.1em]">
            <th class="px-8 py-5">Identitas</th>
            <th class="px-8 py-5">Kantor Cabang</th>
            <th class="px-8 py-5">Wilayah Kerja</th>
            <th class="px-8 py-5">Target Bulanan</th>
            <th class="px-8 py-5">Omzet Toko Lama</th>
            <th class="px-8 py-5">Omzet Toko Baru</th>
            <th class="px-8 py-5">Total Realisasi</th>
            <th class="px-8 py-5 text-right">Aksi</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-slate-100">
          <tr v-for="s in salesmen" :key="s.id" class="group hover:bg-slate-50/70 transition-all">
            <td class="px-8 py-6">
              <div class="flex items-center gap-4">
                <div class="w-12 h-12 rounded-2xl bg-primary/5 flex items-center justify-center font-black text-primary border border-primary/10">
                  {{ s.name.charAt(0) }}
                </div>
                <div>
                  <p class="font-extrabold text-slate-900 group-hover:text-primary transition-colors">{{ s.name }}</p>
                  <p class="text-[12px] text-slate-400 font-bold flex items-center gap-1.5 mt-0.5">
                    <Mail class="w-3 h-3" /> {{ s.email }}
                  </p>
                </div>
              </div>
            </td>
            <td class="px-8 py-6">
              <div class="flex items-center gap-2 text-sm font-bold text-slate-600">
                <Building2 class="w-4 h-4 text-slate-400" />
                {{ s.branch }}
              </div>
            </td>
            <td class="px-8 py-6">
              <div class="flex items-center gap-2 text-sm font-bold text-blue-600">
                <MapPin class="w-4 h-4 text-blue-400" />
                {{ s.workingTerritory }}
              </div>
            </td>
            <td class="px-8 py-6">
              <p class="text-sm font-black text-slate-900">{{ formatCurrency(s.target) }}</p>
            </td>
            <td class="px-8 py-6">
              <p class="text-sm font-bold text-slate-600">{{ formatCurrency(s.currentLama) }}</p>
            </td>
            <td class="px-8 py-6">
              <p class="text-sm font-bold text-blue-600">{{ formatCurrency(s.currentBaru) }}</p>
            </td>
            <td class="px-8 py-6">
              <div class="space-y-2">
                <div class="flex items-center justify-between">
                  <span class="text-[13px] font-black" :class="s.current >= s.target ? 'text-emerald-600' : 'text-primary'">
                    {{ formatCurrency(s.current) }}
                  </span>
                  <span class="text-[10px] font-black text-slate-400">
                    {{ s.target > 0 ? Math.round((s.current / s.target) * 100) : 0 }}%
                  </span>
                </div>
                <div class="h-2 w-full bg-slate-100 rounded-full overflow-hidden">
                  <div 
                    class="h-full transition-all duration-1000 rounded-full" 
                    :class="s.current >= s.target ? 'bg-emerald-500' : 'bg-primary'"
                    :style="`width: ${s.target > 0 ? Math.min((s.current / s.target) * 100, 100) : 0}%`"
                  ></div>
                </div>
              </div>
            </td>
            <td class="px-8 py-6 text-right">
              <div class="flex items-center justify-end gap-2">
                <Button @click="handleEditTarget(s)" variant="ghost" size="icon" class="h-10 w-10 rounded-xl hover:bg-slate-100 text-slate-400 hover:text-primary">
                  <Edit2 class="w-4.5 h-4.5" />
                </Button>
                <Button variant="ghost" size="icon" class="h-10 w-10 rounded-xl hover:bg-red-50 text-slate-400 hover:text-red-500">
                  <Trash2 class="w-4.5 h-4.5" />
                </Button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Modal CRUD Target -->
    <div v-if="isModalOpen" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="absolute inset-0 bg-slate-900/60 backdrop-blur-sm" @click="isModalOpen = false"></div>
      <div class="bg-white rounded-[40px] w-full max-w-lg relative z-10 shadow-2xl overflow-hidden animate-in fade-in zoom-in duration-300">
        <div class="p-8 border-b border-slate-100 flex items-center justify-between bg-slate-50/50">
          <div>
            <h3 class="text-2xl font-black text-slate-900 tracking-tight">{{ isEditing ? 'Edit Target' : 'Tambah Salesman' }}</h3>
            <p class="text-sm font-bold text-slate-400 uppercase tracking-widest mt-1">Manajemen Performa</p>
          </div>
          <button @click="isModalOpen = false" class="p-3 hover:bg-white rounded-2xl transition-all text-slate-400 hover:text-slate-900 shadow-sm">
            <Edit2 class="w-6 h-6 rotate-45" />
          </button>
        </div>

        <div class="p-8 space-y-6">
          <div v-if="!isEditing" class="space-y-2">
            <label class="text-[11px] font-black text-slate-400 uppercase tracking-widest">Pilih Karyawan</label>
            <select v-model="currentSalesman.employeeID" class="w-full bg-slate-50 border-none rounded-2xl px-5 py-4 font-bold text-slate-900 focus:ring-2 focus:ring-primary/20 transition-all appearance-none">
              <option value="" disabled>Pilih Karyawan</option>
              <option v-for="e in allEmployees" :key="e.id" :value="e.id">{{ e.first_name }} {{ e.last_name }}</option>
            </select>
          </div>
          <div v-else class="space-y-2">
            <label class="text-[11px] font-black text-slate-400 uppercase tracking-widest">Salesman</label>
            <div class="w-full bg-slate-100/50 rounded-2xl px-5 py-4 font-bold text-slate-900 border border-slate-100">
              {{ currentSalesman.name }}
            </div>
          </div>

          <div class="space-y-2">
            <label class="text-[11px] font-black text-slate-400 uppercase tracking-widest">Wilayah Kerja (Area)</label>
            <input v-model="currentSalesman.workingTerritory" type="text" placeholder="Contoh: Kabupaten Boyolali" class="w-full bg-slate-50 border-none rounded-2xl px-5 py-4 font-bold text-slate-900 focus:ring-2 focus:ring-primary/20 transition-all" />
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div class="space-y-2">
              <label class="text-[11px] font-black text-slate-400 uppercase tracking-widest">Target Omzet</label>
              <input v-model.number="currentSalesman.targetOmzet" type="number" placeholder="Rp 0" class="w-full bg-slate-50 border-none rounded-2xl px-5 py-4 font-bold text-slate-900 focus:ring-2 focus:ring-primary/20 transition-all" />
            </div>
            <div class="space-y-2">
              <label class="text-[11px] font-black text-slate-400 uppercase tracking-widest">Target Toko Baru</label>
              <input v-model.number="currentSalesman.targetNewStores" type="number" placeholder="0" class="w-full bg-slate-50 border-none rounded-2xl px-5 py-4 font-bold text-slate-900 focus:ring-2 focus:ring-primary/20 transition-all" />
            </div>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div class="space-y-2">
              <label class="text-[11px] font-black text-slate-400 uppercase tracking-widest">Bulan</label>
              <select v-model="currentSalesman.month" class="w-full bg-slate-50 border-none rounded-2xl px-5 py-4 font-bold text-slate-900 focus:ring-2 focus:ring-primary/20 transition-all appearance-none">
                <option v-for="m in 12" :key="m" :value="m">{{ new Date(2024, m-1).toLocaleString('id-ID', { month: 'long' }) }}</option>
              </select>
            </div>
            <div class="space-y-2">
              <label class="text-[11px] font-black text-slate-400 uppercase tracking-widest">Tahun</label>
              <select v-model="currentSalesman.year" class="w-full bg-slate-50 border-none rounded-2xl px-5 py-4 font-bold text-slate-900 focus:ring-2 focus:ring-primary/20 transition-all appearance-none">
                <option :value="new Date().getFullYear()">{{ new Date().getFullYear() }}</option>
                <option :value="new Date().getFullYear() + 1">{{ new Date().getFullYear() + 1 }}</option>
              </select>
            </div>
          </div>
        </div>

        <div class="p-8 bg-slate-50/50 border-t border-slate-100 flex gap-4">
          <button @click="isModalOpen = false" class="flex-1 py-4 text-sm font-black text-slate-500 hover:text-slate-900 transition-all">
            BATAL
          </button>
          <button 
            @click="handleSaveTarget"
            class="flex-[2] bg-primary text-white rounded-2xl py-4 text-sm font-black shadow-xl shadow-primary/20 hover:scale-[1.02] active:scale-[0.98] transition-all flex items-center justify-center gap-2"
          >
            <TrendingUp class="w-5 h-5" /> SIMPAN TARGET
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
