<script setup lang="ts">
import { ref, onMounted, computed, reactive, watch } from 'vue'
import { useDeliveryStore } from '@/stores/delivery'
import { useSalesOrderStore } from '@/stores/salesOrder'
import { useMasterDataStore } from '@/stores/masterData'
import { toast } from 'vue-sonner'
import apiClient from '@/api/axios'
import { 
  Truck, CheckCircle2, MapPin, Calendar, 
  Search, RefreshCw, Camera, X, User,
  Printer, PackagePlus, PackageOpen, 
  Trash2, Pencil, History, ClipboardList,
  ShoppingBag, Banknote
} from 'lucide-vue-next'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Card, CardFooter } from '@/components/ui/card/index'
import DataTable from '@/components/DataTable.vue'

const deliveryStore = useDeliveryStore()
const soStore = useSalesOrderStore()
const masterStore = useMasterDataStore()

const activeTab = ref<'queue' | 'active' | 'history'>('queue')
const searchQuery = ref('')
const loading = ref(false)
const isSubmitting = ref(false)
const showPODModal = ref(false)
const selectedOrder = ref<any>(null)
const isEditingBatch = ref(false)
const editingBatchId = ref<string | null>(null)

const drivers = ref<any[]>([])
const vehicles = ref<any[]>([])
const selectedOrders = ref<string[]>([]) // berisi sales_order_id

const podData = ref({ received_by: '', pod_image_url: '' })
const batchForm = reactive({ driver_id: '', vehicle_id: '' })

// Antrean = SO berstatus CONFIRMED yang belum masuk batch
const filteredQueue = computed(() => {
  return deliveryStore.confirmedOrders.filter(o => {
    const q = searchQuery.value.toLowerCase()
    return !q || 
      o.so_number?.toLowerCase().includes(q) || 
      o.store?.name?.toLowerCase().includes(q) ||
      o.employee?.first_name?.toLowerCase().includes(q)
  })
})

const filteredActive = computed(() => {
  return deliveryStore.batches.filter(b => {
    const isActive = b.status !== 'COMPLETED'
    const q = searchQuery.value.toLowerCase()
    return isActive && (!q || b.delivery_order_no?.toLowerCase().includes(q) || b.driver?.first_name?.toLowerCase().includes(q))
  })
})

const selectedTotal = computed(() => {
  return filteredQueue.value
    .filter(o => selectedOrders.value.includes(o.id))
    .reduce((sum, o) => sum + (o.total_amount || 0), 0)
})

async function fetchData() {
  if (!masterStore.selectedBranchId) return
  loading.value = true
  try {
    const branchId = masterStore.selectedBranchId
    const companyId = masterStore.selectedBranchCompanyId || ''
    await deliveryStore.fetchConfirmedOrders(branchId)
    await deliveryStore.fetchBatches()
    const dRes = await apiClient.get(`/employees?job_title=DRIVER&company_id=${companyId}`)
    drivers.value = dRes.data?.data || []
    const vRes = await apiClient.get(`/vehicles?company_id=${companyId}`)
    vehicles.value = vRes.data?.data || vRes.data || []
  } finally {
    loading.value = false
  }
}

const toggleOrder = (id: string) => {
  selectedOrders.value = selectedOrders.value.includes(id) 
    ? selectedOrders.value.filter(o => o !== id) 
    : [...selectedOrders.value, id]
}

const handleCreateBatch = async () => {
  if (selectedOrders.value.length === 0) {
    toast.error('Pilih minimal 1 nota untuk dibuatkan batch')
    return
  }
  isSubmitting.value = true
  try {
    const payload = {
      company_id: masterStore.selectedBranchCompanyId,
      branch_id: masterStore.selectedBranchId,
      driver_id: batchForm.driver_id || null,
      vehicle_id: batchForm.vehicle_id || null,
      // Alur baru: gunakan sales_order_ids
      sales_order_ids: selectedOrders.value
    }
    if (isEditingBatch.value) {
      await apiClient.put(`/delivery/batches/${editingBatchId.value}`, payload)
    } else {
      await deliveryStore.createBatch(payload)
    }
    toast.success(`Batch berhasil dibuat! Surat Jalan telah diterbitkan untuk ${selectedOrders.value.length} nota.`)
    cancelEdit()
    fetchData()
  } catch (err: any) {
    toast.error(err.response?.data?.error || 'Gagal membuat batch')
  } finally { isSubmitting.value = false }
}

const handleSupervisorApprove = async (id: string) => {
  try {
    await apiClient.post(`/delivery/batch/${id}/supervisor-approve`)
    toast.success('Batch disetujui Supervisor! Surat Jalan siap dicetak.')
    fetchData()
  } catch (err: any) { toast.error('Gagal menyetujui batch') }
}

const handleStartPicking = async (id: string) => {
  try {
    await apiClient.post(`/delivery/batch/${id}/start-picking`)
    toast.success('Status pengambilan barang di Gudang dimulai.')
    fetchData()
  } catch (err: any) { toast.error('Gagal update status') }
}

const openPODModal = (batch: any) => {
  selectedOrder.value = batch
  podData.value = { received_by: '', pod_image_url: '' }
  showPODModal.value = true
}

const handleConfirmPOD = async () => {
  loading.value = true
  try {
    await apiClient.post(`/delivery/batches/${selectedOrder.value.id}/receive`, podData.value)
    toast.success('POD Berhasil!')
    showPODModal.value = false
    fetchData()
  } catch (e: any) { toast.error('Gagal konfirmasi POD') }
  finally { loading.value = false }
}

const cancelEdit = () => {
  isEditingBatch.value = false
  editingBatchId.value = null
  selectedOrders.value = []
  batchForm.driver_id = ''
  batchForm.vehicle_id = ''
}

const handleEditBatch = (batch: any) => {
  isEditingBatch.value = true
  editingBatchId.value = batch.id
  batchForm.driver_id = batch.driver_id || ''
  batchForm.vehicle_id = batch.vehicle_id || ''
  selectedOrders.value = batch.items.map((i: any) => i.sales_order_id).filter(Boolean)
}

const getBatchStatusColor = (status: string) => {
  const map: Record<string, string> = {
    'WAITING_APPROVAL': 'bg-yellow-100 text-yellow-700',
    'SUPERVISOR_APPROVED': 'bg-blue-100 text-blue-700',
    'PICKING': 'bg-orange-100 text-orange-700',
    'ON_DELIVERY': 'bg-indigo-100 text-indigo-700',
    'COMPLETED': 'bg-green-100 text-green-700',
  }
  return map[status] || 'bg-slate-100 text-slate-600'
}

const getBatchStatusLabel = (status: string) => {
  const map: Record<string, string> = {
    'WAITING_APPROVAL': 'Menunggu Persetujuan',
    'SUPERVISOR_APPROVED': 'Surat Jalan Terbit',
    'PICKING': 'Driver di Gudang',
    'ON_DELIVERY': 'Sedang Dikirim',
    'COMPLETED': 'Selesai',
  }
  return map[status] || status
}

const formatCurrency = (val: number) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(val)
const formatDate = (date: string) => date ? new Date(date).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' }) : '-'

onMounted(() => { if (masterStore.selectedBranchId) fetchData() })
watch(() => masterStore.selectedBranchId, fetchData)
</script>

<template>
  <div class="space-y-8 p-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-3xl font-black text-slate-900 tracking-tight flex items-center gap-3">
          <Truck class="w-8 h-8 text-primary" /> Manajemen Pengiriman
        </h1>
        <p class="text-sm text-slate-500 mt-1 font-bold">Supervisor: Buat Batch → Surat Jalan Terbit → Driver kirim ke Customer.</p>
      </div>
      <Button @click="fetchData" variant="outline" class="rounded-2xl h-12 px-6 font-black shadow-sm">
        <RefreshCw class="w-4 h-4 mr-2" :class="{ 'animate-spin': loading }" /> SEGARKAN
      </Button>
    </div>

    <div class="flex gap-2 bg-slate-100 p-1.5 rounded-[24px] w-fit shadow-inner">
      <button v-for="tab in [{ id: 'queue', label: '1. Buat Batch', icon: PackagePlus }, { id: 'active', label: '2. Dalam Pengiriman', icon: Truck }, { id: 'history', label: '3. Riwayat', icon: History }]" 
        :key="tab.id" @click="activeTab = tab.id as any"
        class="flex items-center gap-2 px-6 py-3 rounded-[18px] text-xs font-black transition-all"
        :class="activeTab === tab.id ? 'bg-white text-primary shadow-md' : 'text-slate-400 hover:text-slate-600'">
        <component :is="tab.icon" class="w-4 h-4" /> {{ tab.label }}
      </button>
    </div>

    <!-- Tab 1: Antrian Nota Terverifikasi & Buat Batch -->
    <div v-if="activeTab === 'queue'" class="grid grid-cols-1 lg:grid-cols-12 gap-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
      <!-- Daftar SO yang siap dibatch -->
      <div class="lg:col-span-7 space-y-4">
        <div class="flex items-center justify-between px-2">
          <div>
            <h3 class="text-[10px] font-black text-slate-400 uppercase tracking-[0.2em]">Nota Terverifikasi Admin</h3>
            <p class="text-[9px] text-slate-300 mt-0.5">Centang nota yang ingin digabungkan dalam satu armada pengiriman</p>
          </div>
          <div class="relative w-64">
            <Search class="absolute left-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-slate-400" />
            <input v-model="searchQuery" type="text" placeholder="Cari No. SO / Toko / Sales..." class="w-full pl-9 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl text-xs font-bold outline-none focus:ring-2 focus:ring-primary/20" />
          </div>
        </div>
        <div class="bg-white border border-slate-200 rounded-[32px] overflow-hidden shadow-sm divide-y divide-slate-50 max-h-[600px] overflow-y-auto">
          <div v-for="order in filteredQueue" :key="order.id" @click="toggleOrder(order.id)" 
            class="p-5 flex items-center gap-4 hover:bg-slate-50 transition-all cursor-pointer group"
            :class="selectedOrders.includes(order.id) ? 'bg-primary/5 border-l-4 border-l-primary' : ''">
            <div class="w-6 h-6 rounded-lg border-2 flex items-center justify-center transition-all shrink-0" 
              :class="selectedOrders.includes(order.id) ? 'bg-primary border-primary' : 'border-slate-200 group-hover:border-primary/50'">
              <CheckCircle2 v-if="selectedOrders.includes(order.id)" class="w-4 h-4 text-white" />
            </div>
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2 mb-0.5">
                <p class="text-[10px] font-black text-primary font-mono">{{ order.so_number }}</p>
                <span class="text-[8px] font-bold bg-green-100 text-green-700 px-1.5 py-0.5 rounded-full uppercase">CONFIRMED</span>
              </div>
              <h4 class="text-sm font-black text-slate-900 truncate">{{ order.store?.name }}</h4>
              <p class="text-[9px] text-slate-400 font-bold flex items-center gap-1 mt-0.5">
                <User class="w-3 h-3" /> {{ order.employee?.first_name }} {{ order.employee?.last_name }}
                <span class="text-slate-200">•</span>
                <MapPin class="w-3 h-3" /> {{ order.store?.address }}
              </p>
            </div>
            <div class="text-right shrink-0">
              <p class="text-sm font-black text-slate-900">{{ formatCurrency(order.total_amount) }}</p>
              <p class="text-[9px] text-slate-400">{{ formatDate(order.order_date) }}</p>
            </div>
          </div>
          <div v-if="filteredQueue.length === 0" class="p-16 text-center text-slate-300">
            <PackageOpen class="w-12 h-12 mx-auto mb-4 opacity-10" />
            <p class="text-[10px] font-black uppercase tracking-[0.2em]">Belum ada nota yang diverifikasi</p>
            <p class="text-[9px] mt-1 text-slate-200">Minta Admin Nota untuk memverifikasi pesanan salesman</p>
          </div>
        </div>
      </div>

      <!-- Panel Buat Batch -->
      <div class="lg:col-span-5 space-y-4">
        <div class="bg-white border border-slate-200 rounded-[40px] p-8 shadow-sm">
          <h3 class="text-xl font-black text-slate-900 mb-1">Buat Surat Jalan</h3>
          <p class="text-[10px] text-slate-500 mb-6 font-bold">Surat Jalan terbit otomatis saat batch dibuat</p>
          
          <!-- Summary Pilihan -->
          <div v-if="selectedOrders.length > 0" class="bg-slate-50 border border-slate-100 rounded-2xl p-4 mb-6 space-y-1">
            <div class="flex justify-between text-xs">
              <span class="text-slate-500">Nota dipilih</span>
              <span class="font-black text-slate-900">{{ selectedOrders.length }} nota</span>
            </div>
            <div class="flex justify-between text-xs">
              <span class="text-slate-500">Total tagihan</span>
              <span class="font-black text-primary">{{ formatCurrency(selectedTotal) }}</span>
            </div>
          </div>
          
          <div class="space-y-4">
            <div class="space-y-2">
              <label class="text-[9px] font-black text-slate-400 uppercase tracking-widest ml-1">Pilih Supir (Opsional)</label>
              <select v-model="batchForm.driver_id" class="w-full bg-slate-50 border-2 border-transparent focus:border-primary/20 focus:bg-white rounded-2xl px-5 py-4 font-bold text-slate-900 outline-none transition-all">
                <option value="">— Tanpa Supir (assign nanti) —</option>
                <option v-for="d in drivers" :key="d.id" :value="d.id" class="text-slate-900">{{ d.first_name }} {{ d.last_name }}</option>
              </select>
            </div>
            <div class="space-y-2">
              <label class="text-[9px] font-black text-slate-400 uppercase tracking-widest ml-1">Pilih Armada (Opsional)</label>
              <select v-model="batchForm.vehicle_id" class="w-full bg-slate-50 border-2 border-transparent focus:border-primary/20 focus:bg-white rounded-2xl px-5 py-4 font-bold text-slate-900 outline-none transition-all">
                <option value="">— Tanpa Armada (assign nanti) —</option>
                <option v-for="v in vehicles" :key="v.id" :value="v.id" class="text-slate-900">{{ v.license_plate }}</option>
              </select>
            </div>
          </div>
          
          <Button 
            class="w-full mt-6 bg-primary hover:bg-primary/90 text-white rounded-2xl py-8 font-black shadow-xl shadow-primary/20" 
            :disabled="selectedOrders.length === 0 || isSubmitting" 
            @click="handleCreateBatch">
            <Truck class="w-5 h-5 mr-2" /> 
            {{ isSubmitting ? 'MEMBUAT...' : `TERBITKAN SURAT JALAN (${selectedOrders.length} NOTA)` }}
          </Button>
        </div>
      </div>
    </div>

    <!-- Tab 2: Batch Aktif -->
    <div v-if="activeTab === 'active'" class="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
      <div v-if="filteredActive.length === 0" class="text-center py-20 text-slate-300">
        <Truck class="w-16 h-16 mx-auto mb-4 opacity-10" />
        <p class="font-black text-[10px] uppercase tracking-[0.2em]">Tidak ada pengiriman aktif</p>
      </div>
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div v-for="batch in filteredActive" :key="batch.id" class="bg-white border border-slate-200 rounded-[32px] p-6 shadow-sm hover:shadow-xl transition-all relative overflow-hidden group">
          <div class="flex items-center justify-between mb-4">
            <span class="text-[9px] font-black px-3 py-1 rounded-full uppercase tracking-widest" :class="getBatchStatusColor(batch.status)">
              {{ getBatchStatusLabel(batch.status) }}
            </span>
            <span class="text-[10px] font-black text-slate-300 font-mono">{{ batch.delivery_order_no }}</span>
          </div>
          <div class="flex items-center gap-3 mb-5">
            <div class="w-12 h-12 rounded-2xl bg-slate-50 border border-slate-100 flex items-center justify-center shrink-0">
              <User class="w-6 h-6 text-slate-300" />
            </div>
            <div>
              <h4 class="text-base font-black text-slate-900 leading-tight">
                {{ batch.driver?.first_name || '— Belum Ditugaskan —' }}
              </h4>
              <p class="text-[9px] font-black text-slate-400 uppercase">
                {{ batch.vehicle?.license_plate || 'Armada belum ditentukan' }} • {{ batch.items?.length || 0 }} Nota
              </p>
            </div>
          </div>
          <!-- Daftar toko dalam batch -->
          <div class="bg-slate-50 rounded-2xl p-3 mb-5 max-h-32 overflow-y-auto">
            <div v-for="item in batch.items" :key="item.id" class="flex items-center gap-2 py-1">
              <ShoppingBag class="w-3 h-3 text-slate-300 shrink-0" />
              <span class="text-[10px] font-bold text-slate-600 truncate">{{ item.sales_order?.store?.name || item.sales_transaction?.store?.name || '—' }}</span>
              <span class="ml-auto text-[8px] font-black px-1.5 py-0.5 rounded-full shrink-0"
                :class="item.status === 'DELIVERED' ? 'bg-green-100 text-green-700' : item.status === 'FAILED' ? 'bg-red-100 text-red-700' : 'bg-slate-100 text-slate-500'">
                {{ item.status }}
              </span>
            </div>
          </div>
          <div class="flex gap-2">
            <Button v-if="batch.status === 'WAITING_APPROVAL'" @click="handleSupervisorApprove(batch.id)" 
              class="flex-1 bg-indigo-600 hover:bg-indigo-700 text-white rounded-2xl py-5 font-black text-[10px]">
              ✓ Setujui & Terbitkan SJ
            </Button>
            <Button v-if="batch.status === 'SUPERVISOR_APPROVED'" @click="handleStartPicking(batch.id)" 
              class="flex-1 bg-orange-600 hover:bg-orange-700 text-white rounded-2xl py-5 font-black text-[10px]">
              📦 Driver di Gudang
            </Button>
            <Button v-if="batch.status === 'PICKING' || batch.status === 'ON_DELIVERY'" @click="openPODModal(batch)" 
              class="flex-1 bg-slate-900 text-white rounded-2xl py-5 font-black text-[10px]">
              <CheckCircle2 class="w-3.5 h-3.5 mr-1" /> Input POD
            </Button>
          </div>
        </div>
      </div>
    </div>

    <!-- Tab 3: Riwayat -->
    <div v-if="activeTab === 'history'" class="bg-white border border-slate-200 rounded-[32px] overflow-hidden shadow-sm animate-in fade-in slide-in-from-bottom-4 duration-500">
      <DataTable :columns="[
        { key: 'created_at', label: 'Tanggal', type: 'datetime' }, 
        { key: 'delivery_order_no', label: 'No SJ' }, 
        { key: 'driver.first_name', label: 'Supir' }, 
        { key: 'items.length', label: 'Nota' }, 
        { key: 'status', label: 'Status' }
      ]" :data="deliveryStore.batches.filter(b => b.status === 'COMPLETED')">
        <template #cell-status>
          <Badge class="rounded-lg font-black text-[10px] uppercase px-3 py-1 bg-green-100 text-green-700">SELESAI</Badge>
        </template>
      </DataTable>
    </div>

    <!-- POD Modal -->
    <div v-if="showPODModal" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="absolute inset-0 bg-slate-900/60 backdrop-blur-sm" @click="showPODModal = false" />
      <div class="bg-white rounded-[40px] w-full max-w-md relative z-10 shadow-2xl overflow-hidden p-8 space-y-6">
        <h3 class="text-2xl font-black text-slate-900">Konfirmasi POD</h3>
        <p class="text-xs text-slate-500 -mt-4">Batch: {{ selectedOrder?.delivery_order_no }}</p>
        <input v-model="podData.received_by" type="text" placeholder="Nama Penerima di Toko?" class="w-full bg-slate-50 border-2 border-transparent focus:border-primary rounded-2xl px-5 py-4 font-black outline-none transition-all" />
        <Button @click="handleConfirmPOD" :disabled="loading" class="w-full bg-primary text-white rounded-2xl py-7 font-black shadow-xl shadow-primary/20">
          {{ loading ? 'PROSES...' : 'KONFIRMASI TERIMA' }}
        </Button>
      </div>
    </div>
  </div>
</template>
