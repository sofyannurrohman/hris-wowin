<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue'
import { useSalesVisitStore, type SalesVisit } from '@/stores/salesVisit'
import { useMasterDataStore } from '@/stores/masterData'
import { toast } from 'vue-sonner'
import { 
  MapPin, 
  Calendar, 
  User, 
  Search, 
  Filter, 
  RefreshCw, 
  Camera, 
  ExternalLink,
  Clock,
  CheckCircle2,
  AlertCircle,
  FileText,
  Maximize2,
  Plus,
  Trash2,
  Edit,
  X,
  XCircle
} from 'lucide-vue-next'
import { Button } from '@/components/ui/button'

const formatTime = (d: Date | string) => {
  const date = typeof d === 'string' ? new Date(d) : d
  return date.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })
}
const formatFullTime = (d: Date | string) => {
  const date = typeof d === 'string' ? new Date(d) : d
  return date.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit', second: '2-digit' })
}
const formatDateISO = (d: Date) => d.toISOString().split('T')[0]

const visitStore = useSalesVisitStore()
const masterStore = useMasterDataStore()

const searchQuery = ref('')
const selectedEmployee = ref('ALL')
const selectedDate = ref(formatDateISO(new Date()))

const isLoading = ref(false)

const fetchVisits = async () => {
  isLoading.value = true
  try {
    await visitStore.fetchVisits({
      start_date: selectedDate.value,
      end_date: selectedDate.value,
      employee_id: selectedEmployee.value === 'ALL' ? undefined : selectedEmployee.value,
      branch_id: masterStore.selectedBranchId
    })
  } finally {
    isLoading.value = false
  }
}

onMounted(async () => {
  await masterStore.fetchBranches()
  await masterStore.fetchEmployees()
  await masterStore.fetchStores()
  fetchVisits()
})

watch(() => masterStore.selectedBranchId, () => {
  fetchVisits()
})

const filteredVisits = computed(() => {
  return visitStore.visits.filter(v => {
    const q = searchQuery.value.toLowerCase()
    return !q || 
      v.store?.name?.toLowerCase().includes(q) || 
      v.employee?.first_name?.toLowerCase().includes(q)
  })
})

const selectedVisit = ref<SalesVisit | null>(null)
const showDetail = ref(false)
const showFormModal = ref(false)
const isEditing = ref(false)

const form = ref({
  id: '',
  employee_id: '',
  store_id: '',
  check_time: formatDateISO(new Date()) + 'T08:00',
  type: 'CHECKIN',
  notes: '',
  latitude: 0,
  longitude: 0,
  selfie_url: ''
})

const openDetail = (visit: SalesVisit) => {
  selectedVisit.value = visit
  showDetail.value = true
}

const openCreate = () => {
  isEditing.value = false
  form.value = {
    id: '',
    employee_id: '',
    store_id: '',
    check_time: formatDateISO(new Date()) + 'T08:00',
    type: 'CHECKIN',
    notes: '',
    latitude: 0,
    longitude: 0,
    selfie_url: ''
  }
  showFormModal.value = true
}

const openEdit = (visit: SalesVisit) => {
  isEditing.value = true
  form.value = {
    id: visit.id,
    employee_id: visit.employee_id,
    store_id: visit.store_id,
    check_time: visit.check_in_time.substring(0, 16),
    type: visit.type || 'CHECKIN',
    notes: visit.notes || '',
    latitude: visit.latitude || 0,
    longitude: visit.longitude || 0,
    selfie_url: visit.selfie_url || ''
  }
  showFormModal.value = true
}

const handleSubmit = async () => {
  try {
    const payload = {
      ...form.value,
      check_time: new Date(form.value.check_time).toISOString()
    }
    
    if (isEditing.value) {
      await visitStore.updateVisit(form.value.id, payload)
      toast.success('Kunjungan berhasil diperbarui')
    } else {
      await visitStore.createVisit(payload)
      toast.success('Kunjungan berhasil dibuat')
    }
    
    showFormModal.value = false
    fetchVisits()
  } catch (error: any) {
    toast.error(error.response?.data?.error || 'Gagal menyimpan data')
  }
}

const handleDelete = async (id: string) => {
  if (!confirm('Apakah Anda yakin ingin menghapus data kunjungan ini?')) return
  
  try {
    await visitStore.deleteVisit(id)
    toast.success('Kunjungan berhasil dihapus')
    fetchVisits()
  } catch (error: any) {
    toast.error(error.response?.data?.error || 'Gagal menghapus data')
  }
}

const getDuration = (visit: SalesVisit) => {
  if (!visit.check_out_time) return 'Active'
  const start = new Date(visit.check_in_time)
  const end = new Date(visit.check_out_time)
  const diff = Math.floor((end.getTime() - start.getTime()) / 1000 / 60)
  return `${diff} menit`
}

const getStatusColor = (visit: SalesVisit) => {
  if (visit.check_out_time) return 'text-emerald-600 bg-emerald-50 border-emerald-100'
  return 'text-amber-600 bg-amber-50 border-amber-100'
}

</script>

<template>
  <div class="h-full flex flex-col gap-6 p-6 overflow-hidden bg-[#F8FAFC]">
    <!-- Header Section -->
    <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
      <div>
        <h1 class="text-3xl font-black text-slate-900 tracking-tight flex items-center gap-3">
          <MapPin class="w-8 h-8 text-primary" />
          Manajemen Kunjungan
        </h1>
        <p class="text-slate-500 font-medium mt-1">Pantau aktivitas dan hasil kunjungan tim sales di lapangan.</p>
      </div>
      
      <div class="flex items-center gap-3">
        <Button @click="openCreate" class="rounded-2xl px-6 font-black gap-2">
          <Plus class="w-4 h-4" /> Tambah Kunjungan
        </Button>
        <div class="bg-white p-1.5 rounded-2xl border border-slate-200 shadow-sm flex items-center gap-2">
          <input 
            type="date" 
            v-model="selectedDate" 
            @change="fetchVisits"
            class="bg-transparent border-none focus:ring-0 text-sm font-bold text-slate-700 px-3"
          />
          <div class="w-px h-6 bg-slate-200"></div>
          <button @click="fetchVisits" class="p-2 hover:bg-slate-50 rounded-xl transition-all text-slate-400">
            <RefreshCw class="w-4 h-4" :class="{ 'animate-spin': isLoading }" />
          </button>
        </div>
      </div>
    </div>

    <!-- Filters Row -->
    <div class="flex flex-wrap items-center gap-4 shrink-0">
      <!-- Search -->
      <div class="relative flex-1 min-w-[300px]">
        <Search class="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
        <input 
          v-model="searchQuery"
          type="text" 
          placeholder="Cari toko atau salesman..."
          class="w-full pl-11 pr-4 py-3 bg-white border border-slate-200 rounded-2xl text-sm font-medium focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all shadow-sm"
        />
      </div>

      <!-- Employee Filter -->
      <select 
        v-model="selectedEmployee"
        @change="fetchVisits"
        class="px-6 py-3 bg-white border border-slate-200 rounded-2xl text-sm font-bold text-slate-700 focus:ring-2 focus:ring-primary/20 transition-all shadow-sm outline-none"
      >
        <option value="ALL">Semua Salesman</option>
        <option v-for="emp in masterStore.employees" :key="emp.id" :value="emp.id">
          {{ emp.first_name }} {{ emp.last_name }}
        </option>
      </select>
    </div>

    <!-- Main Content Area -->
    <div class="flex-1 min-h-0 bg-white rounded-[32px] border border-slate-200 shadow-sm overflow-hidden flex flex-col">
      <div class="flex-1 overflow-y-auto no-scrollbar">
        <table class="w-full border-collapse text-left">
          <thead class="sticky top-0 bg-white/80 backdrop-blur-md z-10">
            <tr class="border-b border-slate-100">
              <th class="p-6 text-[11px] font-black text-slate-400 uppercase tracking-widest">Salesman</th>
              <th class="p-6 text-[11px] font-black text-slate-400 uppercase tracking-widest">Toko / Customer</th>
              <th class="p-6 text-[11px] font-black text-slate-400 uppercase tracking-widest">Waktu</th>
              <th class="p-6 text-[11px] font-black text-slate-400 uppercase tracking-widest">Durasi</th>
              <th class="p-6 text-[11px] font-black text-slate-400 uppercase tracking-widest">Hasil</th>
              <th class="p-6 text-right text-[11px] font-black text-slate-400 uppercase tracking-widest">Aksi</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-50">
            <tr v-if="isLoading" v-for="i in 5" :key="i" class="animate-pulse">
              <td v-for="j in 6" :key="j" class="p-6">
                <div class="h-4 bg-slate-100 rounded-lg w-full"></div>
              </td>
            </tr>
            
            <tr v-else-if="filteredVisits.length === 0">
              <td colspan="6" class="py-24 text-center">
                <div class="flex flex-col items-center gap-3">
                  <AlertCircle class="w-12 h-12 text-slate-200" />
                  <p class="font-bold text-slate-400">Tidak ada data kunjungan ditemukan.</p>
                </div>
              </td>
            </tr>

            <tr 
              v-for="visit in filteredVisits" 
              :key="visit.id"
              class="group hover:bg-slate-50/50 transition-all"
            >
              <td class="p-6">
                <div class="flex items-center gap-3">
                  <div class="w-10 h-10 rounded-2xl bg-slate-100 flex items-center justify-center font-black text-slate-500 group-hover:bg-primary/10 group-hover:text-primary transition-all">
                    {{ visit.employee?.first_name?.charAt(0) }}
                  </div>
                  <div>
                    <p class="font-bold text-slate-900">{{ visit.employee?.first_name }} {{ visit.employee?.last_name }}</p>
                    <p class="text-[10px] font-bold text-slate-400">{{ visit.employee?.branch?.name || 'Cabang' }}</p>
                  </div>
                </div>
              </td>
              <td class="p-6">
                <div class="max-w-[200px]">
                  <p class="font-bold text-slate-900 truncate">{{ visit.store?.name || 'New Store' }}</p>
                  <p class="text-[10px] font-medium text-slate-400 truncate">{{ visit.store?.address }}</p>
                </div>
              </td>
              <td class="p-6">
                <div>
                  <p class="text-xs font-black text-slate-700">IN: {{ formatTime(visit.check_in_time) }}</p>
                  <p class="text-[10px] font-bold text-slate-400" v-if="visit.check_out_time">
                    OUT: {{ formatTime(visit.check_out_time) }}
                  </p>
                </div>
              </td>
              <td class="p-6">
                <span :class="['px-3 py-1 rounded-full text-[10px] font-black border uppercase', getStatusColor(visit)]">
                  {{ getDuration(visit) }}
                </span>
              </td>
              <td class="p-6">
                <div class="flex flex-col gap-1">
                  <div v-if="visit.transactions?.length" class="flex items-center gap-1.5">
                    <CheckCircle2 class="w-3.5 h-3.5 text-emerald-500" />
                    <span class="text-[10px] font-black text-emerald-600 uppercase tracking-tighter">Order ({{ visit.transactions.length }})</span>
                  </div>
                  <div v-else class="flex items-center gap-1.5 text-slate-400">
                    <XCircle class="w-3.5 h-3.5" />
                    <span class="text-[10px] font-black uppercase tracking-tighter">No Order</span>
                  </div>
                </div>
              </td>
              <td class="p-6 text-right">
                <div class="flex justify-end gap-1">
                  <button 
                    @click="openDetail(visit)"
                    class="p-2 hover:bg-white hover:shadow-md rounded-xl transition-all text-slate-400 hover:text-primary border border-transparent hover:border-slate-100"
                    title="Detail"
                  >
                    <Maximize2 class="w-4 h-4" />
                  </button>
                  <button 
                    @click="openEdit(visit)"
                    class="p-2 hover:bg-white hover:shadow-md rounded-xl transition-all text-slate-400 hover:text-amber-500 border border-transparent hover:border-slate-100"
                    title="Edit"
                  >
                    <Edit class="w-4 h-4" />
                  </button>
                  <button 
                    @click="handleDelete(visit.id)"
                    class="p-2 hover:bg-white hover:shadow-md rounded-xl transition-all text-slate-400 hover:text-red-500 border border-transparent hover:border-slate-100"
                    title="Hapus"
                  >
                    <Trash2 class="w-4 h-4" />
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Form Modal -->
    <div v-if="showFormModal" class="fixed inset-0 z-[100] flex items-center justify-center p-6">
      <div class="absolute inset-0 bg-slate-900/60 backdrop-blur-sm" @click="showFormModal = false"></div>
      <div class="relative w-full max-w-xl bg-white rounded-[40px] shadow-2xl overflow-hidden flex flex-col animate-in fade-in zoom-in duration-300">
        <div class="p-8 border-b border-slate-100 flex items-center justify-between">
          <div>
            <h2 class="text-2xl font-black text-slate-900 tracking-tight">
              {{ isEditing ? 'Edit Kunjungan' : 'Tambah Kunjungan Manual' }}
            </h2>
            <p class="text-slate-500 font-medium text-sm mt-1">Lengkapi data kunjungan di bawah ini.</p>
          </div>
          <button @click="showFormModal = false" class="p-3 bg-slate-100 hover:bg-slate-200 rounded-2xl transition-all text-slate-500">
            <X class="w-6 h-6" />
          </button>
        </div>

        <form @submit.prevent="handleSubmit" class="p-8 space-y-6 overflow-y-auto no-scrollbar">
          <div class="grid grid-cols-2 gap-6">
            <div class="space-y-2">
              <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Salesman</label>
              <select v-model="form.employee_id" required class="w-full px-5 py-4 bg-slate-50 border-none rounded-2xl text-sm font-bold text-slate-700 focus:ring-2 focus:ring-primary/20 transition-all outline-none">
                <option value="" disabled>Pilih Salesman</option>
                <option v-for="emp in masterStore.employees" :key="emp.id" :value="emp.id">
                  {{ emp.first_name }} {{ emp.last_name }}
                </option>
              </select>
            </div>
            <div class="space-y-2">
              <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Toko</label>
              <select v-model="form.store_id" required class="w-full px-5 py-4 bg-slate-50 border-none rounded-2xl text-sm font-bold text-slate-700 focus:ring-2 focus:ring-primary/20 transition-all outline-none">
                <option value="" disabled>Pilih Toko</option>
                <option v-for="s in masterStore.stores" :key="s.id" :value="s.id">{{ s.name }}</option>
              </select>
            </div>
          </div>

          <div class="grid grid-cols-2 gap-6">
            <div class="space-y-2">
              <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Waktu Masuk</label>
              <input v-model="form.check_time" type="datetime-local" required class="w-full px-5 py-4 bg-slate-50 border-none rounded-2xl text-sm font-bold text-slate-700 focus:ring-2 focus:ring-primary/20 transition-all outline-none" />
            </div>
            <div class="space-y-2">
              <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Tipe</label>
              <select v-model="form.type" class="w-full px-5 py-4 bg-slate-50 border-none rounded-2xl text-sm font-bold text-slate-700 focus:ring-2 focus:ring-primary/20 transition-all outline-none">
                <option value="CHECKIN">CHECKIN</option>
                <option value="CHECKOUT">CHECKOUT</option>
              </select>
            </div>
          </div>

          <div class="space-y-2">
            <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Catatan / Feedback</label>
            <textarea v-model="form.notes" rows="3" class="w-full px-5 py-4 bg-slate-50 border-none rounded-2xl text-sm font-bold text-slate-700 focus:ring-2 focus:ring-primary/20 transition-all outline-none resize-none" placeholder="Masukkan catatan kunjungan..."></textarea>
          </div>

          <div class="pt-4">
            <Button type="submit" class="w-full py-8 rounded-[24px] font-black text-lg shadow-xl shadow-primary/20">
              {{ isEditing ? 'Simpan Perubahan' : 'Simpan Kunjungan' }}
            </Button>
          </div>
        </form>
      </div>
    </div>

    <!-- Detail Modal -->
    <div v-if="showDetail" class="fixed inset-0 z-[100] flex items-center justify-center p-6">
      <div class="absolute inset-0 bg-slate-900/60 backdrop-blur-sm" @click="showDetail = false"></div>
      
      <div class="relative w-full max-w-4xl bg-white rounded-[40px] shadow-2xl overflow-hidden flex flex-col md:flex-row h-[80vh] animate-in fade-in zoom-in duration-300">
        <!-- Left: Image & Info -->
        <div class="md:w-[400px] bg-slate-900 relative">
          <img 
            v-if="selectedVisit?.selfie_url"
            :src="selectedVisit?.selfie_url" 
            class="w-full h-full object-cover opacity-60"
            alt="Visit Selfie"
          />
          <div v-else class="w-full h-full flex flex-col items-center justify-center text-slate-500 gap-4">
             <Camera class="w-16 h-16 opacity-20" />
             <p class="text-xs font-bold uppercase tracking-widest">Tidak ada foto</p>
          </div>
          <div class="absolute inset-0 bg-gradient-to-t from-slate-900 via-transparent to-transparent"></div>
          
          <div class="absolute bottom-8 left-8 right-8 text-white">
            <div class="flex items-center gap-3 mb-4">
              <div class="w-12 h-12 rounded-2xl bg-white/20 backdrop-blur-md flex items-center justify-center">
                <Camera class="w-6 h-6 text-white" />
              </div>
              <div>
                <p class="text-[10px] font-black text-white/60 uppercase tracking-widest">Selfie Kunjungan</p>
                <p class="text-sm font-bold">{{ selectedVisit?.employee?.first_name }}</p>
              </div>
            </div>
            
            <div class="bg-white/10 backdrop-blur-md rounded-2xl p-4 border border-white/10">
              <div class="flex items-center gap-3">
                <MapPin class="w-4 h-4 text-primary" />
                <p class="text-[11px] font-medium leading-relaxed">{{ selectedVisit?.store?.address }}</p>
              </div>
            </div>
          </div>
        </div>

        <!-- Right: Activity Data -->
        <div class="flex-1 p-10 flex flex-col gap-8 overflow-y-auto no-scrollbar">
          <div class="flex items-center justify-between">
            <div>
              <h2 class="text-2xl font-black text-slate-900 tracking-tight">{{ selectedVisit?.store?.name }}</h2>
              <p class="text-slate-400 font-bold text-sm uppercase tracking-wider mt-1">{{ selectedVisit?.type }} KUNJUNGAN</p>
            </div>
            <button @click="showDetail = false" class="p-3 bg-slate-100 hover:bg-slate-200 rounded-2xl transition-all text-slate-500">
              <X class="w-6 h-6" />
            </button>
          </div>

          <div class="grid grid-cols-2 gap-4">
              <div class="bg-slate-50 p-4 rounded-3xl border border-slate-100">
                <div class="flex items-center gap-2 text-slate-400 mb-1">
                  <Clock class="w-4 h-4" />
                  <span class="text-[10px] font-black uppercase tracking-wider">Waktu Masuk</span>
                </div>
                <p class="text-lg font-black text-slate-900">
                  {{ selectedVisit ? formatFullTime(selectedVisit.check_in_time) : '-' }}
                </p>
              </div>
              <div class="bg-slate-50 p-4 rounded-3xl border border-slate-100">
                <div class="flex items-center gap-2 text-slate-400 mb-1">
                  <Clock class="w-4 h-4" />
                  <span class="text-[10px] font-black uppercase tracking-wider">Waktu Keluar</span>
                </div>
                <p class="text-lg font-black text-slate-900">
                  {{ selectedVisit?.check_out_time ? formatFullTime(selectedVisit.check_out_time) : 'Masih Aktif' }}
                </p>
              </div>
          </div>

          <div>
            <h4 class="text-xs font-black text-slate-400 uppercase tracking-[0.2em] mb-4">Hasil / Transaksi</h4>
            <div v-if="selectedVisit?.transactions?.length" class="space-y-3">
              <div v-for="t in selectedVisit.transactions" :key="t.id" class="p-4 bg-emerald-50 rounded-3xl border border-emerald-100 flex items-center justify-between">
                <div class="flex items-center gap-3">
                  <div class="w-10 h-10 rounded-2xl bg-emerald-500 flex items-center justify-center shadow-lg shadow-emerald-200">
                    <FileText class="w-5 h-5 text-white" />
                  </div>
                  <div>
                    <p class="font-bold text-slate-900">{{ t.receipt_no }}</p>
                    <p class="text-xs font-black text-emerald-600">Rp {{ new Intl.NumberFormat('id-ID').format(t.total_amount) }}</p>
                  </div>
                </div>
                <div class="px-3 py-1 bg-emerald-500 text-white text-[10px] font-black rounded-full uppercase">{{ t.status }}</div>
              </div>
            </div>
            <div v-else class="py-10 text-center bg-slate-50 rounded-3xl border border-dashed border-slate-200">
              <p class="text-sm font-bold text-slate-400 italic">Tidak ada transaksi tercatat dalam kunjungan ini.</p>
            </div>
          </div>

          <div v-if="selectedVisit?.notes">
            <h4 class="text-xs font-black text-slate-400 uppercase tracking-[0.2em] mb-3">Catatan / Feedback</h4>
            <div class="bg-amber-50 p-6 rounded-3xl border border-amber-100 italic text-slate-700 leading-relaxed">
              "{{ selectedVisit.notes }}"
            </div>
          </div>
        </div>
      </div>
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
