<script setup lang="ts">
import { ref, onMounted, computed, reactive, watch } from 'vue'
import { useSalesOrderStore } from '@/stores/salesOrder'
import { useDeliveryStore } from '@/stores/delivery'
import { useMasterDataStore } from '@/stores/masterData'
import { toast } from 'vue-sonner'
import apiClient from '@/api/axios'
import { 
  Truck, CheckCircle2, MapPin, Calendar, 
  Search, RefreshCw, Camera, X, User,
  Printer, PackagePlus, PackageOpen, 
  Trash2, Pencil, History, ClipboardList
} from 'lucide-vue-next'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Card, CardFooter } from '@/components/ui/card/index'
import DataTable from '@/components/DataTable.vue'

const deliveryStore = useDeliveryStore()
const masterStore = useMasterDataStore()

const activeTab = ref<'queue' | 'active' | 'history'>('queue')
const searchQuery = ref('')
const loading = ref(false)
const isSubmitting = ref(false)
const showPODModal = ref(false)
const selectedOrder = ref<any>(null)
const selectedDO = ref<any>(null)
const isEditingBatch = ref(false)
const editingBatchId = ref<string | null>(null)

const drivers = ref<any[]>([])
const vehicles = ref<any[]>([])
const selectedOrders = ref<string[]>([])

const podData = ref({ received_by: '', pod_image_url: '' })
const batchForm = reactive({ driver_id: '', vehicle_id: '' })

const filteredQueue = computed(() => {
  return deliveryStore.pendingOrders.filter(o => {
    const q = searchQuery.value.toLowerCase()
    return !q || o.receipt_no?.toLowerCase().includes(q) || o.store?.name?.toLowerCase().includes(q)
  })
})

const filteredActive = computed(() => {
  return deliveryStore.batches.filter(b => {
    const isActive = b.status === 'SHIPPED' || b.status === 'WAITING_APPROVAL' || b.status === 'APPROVED'
    const q = searchQuery.value.toLowerCase()
    return isActive && (!q || b.delivery_order_no?.toLowerCase().includes(q) || b.driver?.first_name?.toLowerCase().includes(q))
  })
})

async function fetchData() {
  if (!masterStore.selectedBranchId) return
  loading.value = true
  try {
    const companyId = masterStore.selectedBranchCompanyId || ''
    await deliveryStore.fetchPendingOrders(companyId)
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
  isSubmitting.value = true
  try {
    const payload = {
      company_id: masterStore.selectedBranchCompanyId,
      driver_id: batchForm.driver_id,
      vehicle_id: batchForm.vehicle_id,
      sales_transaction_ids: selectedOrders.value
    }
    if (isEditingBatch.value) await apiClient.put(`/delivery/batches/${editingBatchId.value}`, payload)
    else await deliveryStore.createBatch(payload)
    toast.success('Batch berhasil diproses!')
    cancelEdit()
    fetchData()
  } catch (err: any) {
    toast.error(err.response?.data?.error || 'Gagal proses batch')
  } finally { isSubmitting.value = false }
}

const handleSupervisorApprove = async (id: string) => {
  try {
    await apiClient.post(`/delivery/batch/${id}/supervisor-approve`)
    toast.success('Batch difinalisasi!')
    fetchData()
  } catch (err: any) { toast.error('Gagal finalisasi') }
}

const handleShipBatch = async (id: string) => {
  try {
    await apiClient.post(`/delivery/batches/${id}/ship`)
    toast.success('Status: DIKIRIM')
    fetchData()
  } catch (err: any) { toast.error('Gagal update status') }
}

const openPODModal = (batch: any) => {
  selectedOrder.value = batch
  podData.value = { 
    received_by: batch.received_by || '', 
    pod_image_url: batch.pod_image_url || '' 
  }
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
  selectedOrders.value = batch.items.map((i: any) => i.sales_transaction_id)
  batch.items.forEach((item: any) => {
    if (!deliveryStore.pendingOrders.find(o => o.id === item.sales_transaction_id)) 
      deliveryStore.pendingOrders.push(item.sales_transaction)
  })
}

const formatCurrency = (val: number) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(val)
const formatDate = (date: string) => date ? new Date(date).toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' }) : '-'

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
        <p class="text-sm text-slate-500 mt-1 font-bold">Unified Dashboard: Batching, In-Transit & POD.</p>
      </div>
      <Button @click="fetchData" variant="outline" class="rounded-2xl h-12 px-6 font-black shadow-sm">
        <RefreshCw class="w-4 h-4 mr-2" :class="{ 'animate-spin': loading }" /> SEGARKAN
      </Button>
    </div>

    <div class="flex gap-2 bg-slate-100 p-1.5 rounded-[24px] w-fit shadow-inner">
      <button v-for="tab in [{ id: 'queue', label: '1. Antrian', icon: PackagePlus }, { id: 'active', label: '2. Pengiriman', icon: Truck }, { id: 'history', label: '3. Riwayat', icon: History }]" 
        :key="tab.id" @click="activeTab = tab.id as any"
        class="flex items-center gap-2 px-6 py-3 rounded-[18px] text-xs font-black transition-all"
        :class="activeTab === tab.id ? 'bg-white text-primary shadow-md' : 'text-slate-400 hover:text-slate-600'">
        <component :is="tab.icon" class="w-4 h-4" /> {{ tab.label }}
      </button>
    </div>

    <!-- Queue & Batching -->
    <div v-if="activeTab === 'queue'" class="grid grid-cols-1 lg:grid-cols-12 gap-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
      <div class="lg:col-span-7 space-y-4">
        <div class="flex items-center justify-between px-2">
          <h3 class="text-[10px] font-black text-slate-400 uppercase tracking-[0.2em]">Antrian Nota Valid</h3>
          <div class="relative w-64">
            <Search class="absolute left-3 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-slate-400" />
            <input v-model="searchQuery" type="text" placeholder="Cari..." class="w-full pl-9 pr-4 py-2.5 bg-white border border-slate-200 rounded-xl text-xs font-bold outline-none focus:ring-2 focus:ring-primary/20" />
          </div>
        </div>
        <div class="bg-white border border-slate-200 rounded-[32px] overflow-hidden shadow-sm divide-y divide-slate-50 max-h-[600px] overflow-y-auto">
          <div v-for="order in filteredQueue" :key="order.id" @click="toggleOrder(order.id)" class="p-5 flex items-center gap-4 hover:bg-slate-50 transition-all cursor-pointer group">
            <div class="w-6 h-6 rounded-lg border-2 flex items-center justify-center transition-all" :class="selectedOrders.includes(order.id) ? 'bg-primary border-primary' : 'border-slate-200 group-hover:border-primary/50'">
              <CheckCircle2 v-if="selectedOrders.includes(order.id)" class="w-4 h-4 text-white" />
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-[10px] font-black text-slate-400 mb-0.5">{{ order.receipt_no }}</p>
              <h4 class="text-base font-black text-slate-900 truncate">{{ order.store?.name }}</h4>
              <p class="text-[9px] text-slate-400 font-bold uppercase truncate flex items-center gap-1"><MapPin class="w-3 h-3" /> {{ order.store?.address }}</p>
            </div>
            <div class="text-right">
              <p class="text-sm font-black text-slate-900">{{ formatCurrency(order.total_amount) }}</p>
              <Badge variant="outline" class="text-[8px] border-slate-200">{{ order.payment_method }}</Badge>
            </div>
          </div>
          <div v-if="filteredQueue.length === 0" class="p-20 text-center text-slate-300">
            <PackageOpen class="w-12 h-12 mx-auto mb-4 opacity-10" />
            <p class="text-[10px] font-black uppercase tracking-[0.2em]">Kosong</p>
          </div>
        </div>
      </div>
      <div class="lg:col-span-5 space-y-6">
        <div class="bg-slate-900 rounded-[40px] p-8 text-white shadow-2xl relative overflow-hidden">
          <div class="relative z-10 space-y-6">
            <h3 class="text-2xl font-black">Buat Batch Baru</h3>
            <div class="space-y-4">
              <div class="space-y-2">
                <label class="text-[9px] font-black text-slate-500 uppercase tracking-widest ml-1">Pilih Supir</label>
                <select v-model="batchForm.driver_id" class="w-full bg-white/5 border-none rounded-2xl px-5 py-4 font-bold text-white focus:ring-2 focus:ring-primary outline-none"><option value="" disabled>Supir</option><option v-for="d in drivers" :key="d.id" :value="d.id" class="text-slate-900">{{ d.first_name }}</option></select>
              </div>
              <div class="space-y-2">
                <label class="text-[9px] font-black text-slate-500 uppercase tracking-widest ml-1">Pilih Armada</label>
                <select v-model="batchForm.vehicle_id" class="w-full bg-white/5 border-none rounded-2xl px-5 py-4 font-bold text-white focus:ring-2 focus:ring-primary outline-none"><option value="" disabled>Kendaraan</option><option v-for="v in vehicles" :key="v.id" :value="v.id" class="text-slate-900">{{ v.license_plate }}</option></select>
              </div>
            </div>
            <Button class="w-full bg-primary hover:bg-primary/90 text-white rounded-2xl py-8 font-black shadow-xl shadow-primary/20" :disabled="!batchForm.driver_id || !batchForm.vehicle_id || selectedOrders.length === 0 || isSubmitting" @click="handleCreateBatch">
              <Truck class="w-5 h-5 mr-2" /> {{ isSubmitting ? 'PROSES...' : 'CETAK SURAT JALAN' }}
            </Button>
          </div>
        </div>
      </div>
    </div>

    <!-- Active Deliveries -->
    <div v-if="activeTab === 'active'" class="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
       <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
         <div v-for="batch in filteredActive" :key="batch.id" class="bg-white border border-slate-200 rounded-[32px] p-6 shadow-sm hover:shadow-xl transition-all relative overflow-hidden group">
            <div class="flex items-center justify-between mb-6">
              <Badge :variant="batch.status === 'SHIPPED' ? 'default' : 'warning'" class="rounded-lg font-black text-[10px] px-3 py-1 uppercase tracking-widest">{{ batch.status }}</Badge>
              <span class="text-[10px] font-black text-slate-300 font-mono">{{ batch.delivery_order_no }}</span>
            </div>
            <div class="flex items-center gap-4 mb-6">
              <div class="w-14 h-14 rounded-2xl bg-slate-50 border border-slate-100 flex items-center justify-center"><User class="w-7 h-7 text-slate-200" /></div>
              <div><h4 class="text-lg font-black text-slate-900 leading-tight">{{ batch.driver?.first_name }}</h4><p class="text-[10px] font-black text-slate-400 uppercase">{{ batch.vehicle?.license_plate }} • {{ batch.items?.length }} Nota</p></div>
            </div>
            <div class="flex gap-2">
               <Button v-if="batch.status === 'APPROVED'" @click="handleShipBatch(batch.id)" class="flex-1 bg-primary text-white rounded-2xl py-6 font-black text-xs">MARK SHIPPED</Button>
               <Button v-if="batch.status === 'SHIPPED'" @click="openPODModal(batch)" class="flex-1 bg-slate-900 text-white rounded-2xl py-6 font-black text-xs">INPUT POD</Button>
               <Button v-if="batch.status === 'WAITING_APPROVAL'" @click="handleSupervisorApprove(batch.id)" class="flex-1 bg-indigo-600 text-white rounded-2xl py-6 font-black text-xs">FINALIZE</Button>
            </div>
         </div>
       </div>
    </div>

    <!-- History -->
    <div v-if="activeTab === 'history'" class="bg-white border border-slate-200 rounded-[32px] overflow-hidden shadow-sm animate-in fade-in slide-in-from-bottom-4 duration-500">
        <DataTable :columns="[
          { key: 'created_at', label: 'Tanggal', type: 'datetime' }, 
          { key: 'delivery_order_no', label: 'No SJ' }, 
          { key: 'driver.first_name', label: 'Supir' }, 
          { key: 'items.length', label: 'Nota' }, 
          { key: 'status', label: 'Status' },
          { key: 'actions', label: 'Aksi' }
        ]" :data="deliveryStore.batches.filter(b => b.status === 'COMPLETED')">
          <template #cell-status><Badge variant="success" class="rounded-lg font-black text-[10px] uppercase px-3 py-1">COMPLETED</Badge></template>
          <template #cell-actions="{ row }">
            <Button variant="ghost" size="sm" class="font-black text-[10px] text-primary" @click="openPODModal(row)">EDIT POD</Button>
          </template>
        </DataTable>
    </div>

    <!-- POD Modal -->
    <div v-if="showPODModal" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="absolute inset-0 bg-slate-900/60 backdrop-blur-sm" @click="showPODModal = false" />
      <div class="bg-white rounded-[40px] w-full max-w-md relative z-10 shadow-2xl overflow-hidden p-8 space-y-6">
        <h3 class="text-2xl font-black text-slate-900">Konfirmasi Terima (POD)</h3>
        <input v-model="podData.received_by" type="text" placeholder="Nama Penerima?" class="w-full bg-slate-50 border-2 border-transparent focus:border-primary rounded-2xl px-5 py-4 font-black outline-none transition-all" />
        <Button @click="handleConfirmPOD" :disabled="loading" class="w-full bg-primary text-white rounded-2xl py-7 font-black shadow-xl shadow-primary/20">{{ loading ? 'PROSES...' : 'BARANG DITERIMA' }}</Button>
      </div>
    </div>
  </div>
</template>
