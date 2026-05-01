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
  Building2,
  Calendar,
  History,
  Eye,
  ArrowRight,
  Users,
  MapPin,
  TrendingUp,
  X,
  Mail
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

const showHistoryModal = ref(false)
const visitHistory = ref<any[]>([])
const selectedSalesman = ref<any>(null)
const isHistoryLoading = ref(false)

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
        currentBaru: kpi.AchievedOmzetBaru || 0,
        totalVisits: kpi.TotalVisits || 0
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
  if (rawData) {
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
  } else {
    toast.error('Data salesman tidak ditemukan')
  }
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

const openVisitHistory = async (s: any) => {
  selectedSalesman.value = s
  showHistoryModal.value = true
  isHistoryLoading.value = true
  try {
    const res = await apiClient.get(`/attendance/all?employee_id=${s.employeeID}&limit=50`)
    if (res.data?.data) {
      visitHistory.value = res.data.data
    }
  } catch (error) {
    console.error('Failed to fetch visit history:', error)
    toast.error('Gagal mengambil riwayat kunjungan')
  } finally {
    isHistoryLoading.value = false
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

const getMonthLabel = (m: number) => {
  const found = months.find(item => item.value === m)
  return found ? found.label : ''
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
            <th class="px-8 py-5">Total Kunjungan</th>
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
              <button @click="openVisitHistory(s)" class="flex items-center gap-2 px-4 py-2 bg-emerald-50 text-emerald-700 rounded-xl border border-emerald-100 hover:bg-emerald-100 transition-all group/visit">
                 <span class="text-sm font-black">{{ s.totalVisits }}</span>
                 <span class="text-[10px] font-bold uppercase tracking-tighter opacity-70">Kunjungan</span>
                 <Eye class="w-3.5 h-3.5 opacity-0 group-hover/visit:opacity-100 transition-all translate-x-[-4px] group-hover/visit:translate-x-0" />
              </button>
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
    <!-- Visit History Modal -->
    <div v-if="showHistoryModal" class="fixed inset-0 z-[60] flex items-center justify-center p-4">
      <div class="absolute inset-0 bg-slate-900/60 backdrop-blur-md" @click="showHistoryModal = false"></div>
      <div class="bg-white rounded-[40px] w-full max-w-2xl relative z-10 shadow-2xl flex flex-col max-h-[85vh] overflow-hidden animate-in fade-in slide-in-from-bottom-4 duration-300">
        <!-- Header -->
        <div class="p-8 border-b border-slate-100 flex items-center justify-between bg-slate-50/50 shrink-0">
          <div class="flex items-center gap-5">
            <div class="w-14 h-14 rounded-2xl bg-emerald-500 flex items-center justify-center text-white shadow-lg shadow-emerald-200">
              <History class="w-7 h-7" />
            </div>
            <div>
              <h3 class="text-2xl font-black text-slate-900 tracking-tight">Riwayat Kunjungan</h3>
              <p class="text-sm font-bold text-slate-400 mt-0.5">{{ selectedSalesman?.name }} • {{ getMonthLabel(currentMonth) }} {{ currentYear }}</p>
            </div>
          </div>
          <button @click="showHistoryModal = false" class="p-3 hover:bg-white rounded-2xl transition-all text-slate-400 hover:text-slate-900 shadow-sm">
            <X class="w-6 h-6" />
          </button>
        </div>

        <!-- Content -->
        <div class="flex-1 overflow-y-auto p-8 custom-scrollbar">
          <div v-if="isHistoryLoading" class="flex flex-col items-center justify-center py-20">
            <div class="w-12 h-12 border-4 border-emerald-100 border-t-emerald-500 rounded-full animate-spin"></div>
            <p class="text-sm font-bold text-slate-400 mt-4">Mengambil data kunjungan...</p>
          </div>
          
          <div v-else-if="visitHistory.length === 0" class="flex flex-col items-center justify-center py-20 text-center">
             <div class="w-20 h-20 bg-slate-50 rounded-full flex items-center justify-center mb-4">
                <MapPin class="w-10 h-10 text-slate-200" />
             </div>
             <h4 class="text-lg font-black text-slate-900">Belum ada kunjungan</h4>
             <p class="text-sm font-medium text-slate-400 mt-1 max-w-[240px]">Salesman ini belum melakukan kunjungan tercatat di periode ini.</p>
          </div>

          <div v-else class="space-y-6">
             <div v-for="visit in visitHistory" :key="visit.id" class="group/item flex gap-6 relative">
                <!-- Timeline Line -->
                <div class="absolute left-[27px] top-14 bottom-[-24px] w-0.5 bg-slate-100 group-last/item:hidden"></div>
                
                <!-- Time/Indicator -->
                <div class="shrink-0 flex flex-col items-center">
                   <div class="w-14 h-14 rounded-2xl bg-white border-2 border-slate-100 flex flex-col items-center justify-center group-hover/item:border-emerald-500 transition-colors z-10 shadow-sm">
                      <span class="text-[10px] font-black text-slate-400 uppercase leading-none">{{ new Date(visit.clock_in_time).toLocaleDateString('id-ID', { day: '2-digit' }) }}</span>
                      <span class="text-[10px] font-black text-slate-900 uppercase leading-none mt-1">{{ new Date(visit.clock_in_time).toLocaleDateString('id-ID', { month: 'short' }) }}</span>
                   </div>
                </div>

                <!-- Card -->
                <div class="flex-1 bg-slate-50/50 hover:bg-white rounded-[24px] p-5 border border-slate-100 hover:border-emerald-200 transition-all hover:shadow-xl hover:shadow-emerald-500/5 group-hover/item:translate-x-2">
                   <div class="flex justify-between items-start mb-4">
                      <div class="flex items-center gap-2">
                         <div class="w-2 h-2 rounded-full bg-emerald-500"></div>
                         <span class="text-xs font-black text-slate-900">{{ new Date(visit.clock_in_time).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) }}</span>
                         <span class="text-slate-300 mx-1">—</span>
                         <span class="text-xs font-bold text-slate-400">{{ visit.clock_out_time ? new Date(visit.clock_out_time).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : 'Masih Berkunjung' }}</span>
                      </div>
                      <div class="flex items-center gap-1.5 px-2.5 py-1 bg-white border border-slate-100 rounded-lg shadow-sm">
                         <MapPin class="w-3 h-3 text-emerald-500" />
                         <span class="text-[10px] font-black text-slate-600 uppercase tracking-tighter">Lokasi Terverifikasi</span>
                      </div>
                   </div>

                   <div v-if="visit.sales_transactions && visit.sales_transactions.length > 0">
                      <div v-for="trx in visit.sales_transactions" :key="trx.id" class="mb-2 last:mb-0 bg-white p-3 rounded-xl border border-slate-100 flex items-center justify-between">
                         <div class="flex items-center gap-3">
                            <div class="w-8 h-8 rounded-lg bg-emerald-50 flex items-center justify-center text-emerald-600">
                               <Building2 class="w-4 h-4" />
                            </div>
                            <div>
                               <p class="text-[11px] font-black text-slate-900">{{ trx.store?.name || 'Toko Unknown' }}</p>
                               <p class="text-[9px] font-bold text-slate-400">Transaksi Berhasil</p>
                            </div>
                         </div>
                         <p class="text-xs font-black text-emerald-600">{{ formatCurrency(trx.total_amount) }}</p>
                      </div>
                   </div>
                   <div v-else-if="visit.notes" class="bg-white p-3 rounded-xl border border-slate-100 border-dashed">
                      <p class="text-[11px] font-bold text-slate-500 italic">"{{ visit.notes }}"</p>
                   </div>
                   <div v-else class="flex items-center gap-2 text-slate-300">
                      <div class="h-[1px] flex-1 bg-slate-100"></div>
                      <span class="text-[9px] font-black uppercase tracking-widest">Tidak ada catatan</span>
                      <div class="h-[1px] flex-1 bg-slate-100"></div>
                   </div>
                </div>
             </div>
          </div>
        </div>

        <!-- Footer -->
        <div class="p-8 bg-slate-50/50 border-t border-slate-100 flex justify-between items-center shrink-0">
           <div class="flex items-center gap-3">
              <p class="text-xs font-bold text-slate-400">Total Kunjungan Bulan Ini:</p>
              <span class="px-3 py-1 bg-white border border-slate-200 rounded-lg text-sm font-black text-slate-900 shadow-sm">{{ visitHistory.length }}</span>
           </div>
           <Button @click="showHistoryModal = false" class="bg-slate-900 text-white rounded-2xl px-8 py-3.5 font-bold shadow-lg shadow-slate-200 hover:scale-[1.02] active:scale-[0.98] transition-all">
              TUTUP
           </Button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.custom-scrollbar::-webkit-scrollbar {
  width: 6px;
}
.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background: #e2e8f0;
  border-radius: 10px;
}
.custom-scrollbar::-webkit-scrollbar-thumb:hover {
  background: #cbd5e1;
}
</style>
