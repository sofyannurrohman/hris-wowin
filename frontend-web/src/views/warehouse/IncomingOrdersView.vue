<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useSalesOrderStore, type SalesOrder } from '@/stores/salesOrder'
import { useMasterDataStore } from '@/stores/masterData'
import { toast } from 'vue-sonner'
import {
  ClipboardList, CheckCircle2, Package, Truck,
  Search, RefreshCw, X, Box
} from 'lucide-vue-next'
import { Button } from '@/components/ui/button'

const soStore = useSalesOrderStore()
const masterStore = useMasterDataStore()

const activeTab = ref('READY') // 'READY' or 'BACKORDER'
const searchQuery = ref('')
const showProcessModal = ref(false)
const selectedOrder = ref<SalesOrder | null>(null)
const loading = ref(false)

// Data untuk validasi qty fisik
const actualQtys = ref<Record<string, number>>({})

const filteredOrders = computed(() => {
  return soStore.orders.filter(o => {
    const isReady = o.status === 'WAITING_WAREHOUSE' || o.status === 'PROCESSING'
    const isBackorder = o.status === 'WAITING_STOCK'
    
    const matchesTab = activeTab.value === 'READY' ? isReady : isBackorder
    
    const q = searchQuery.value.toLowerCase()
    const matchSearch = !q || o.so_number.toLowerCase().includes(q) || o.store?.name?.toLowerCase().includes(q)
    return matchesTab && matchSearch
  })
})

async function fetchOrders() {
  if (!masterStore.selectedBranchId) return
  await soStore.fetchByBranch(masterStore.selectedBranchId, 'ALL')
}

function openProcessModal(order: SalesOrder) {
  selectedOrder.value = order
  // Reset actual qtys ke qty pesanan awal sebagai default
  actualQtys.value = {}
  order.items.forEach(item => {
    actualQtys.value[item.product_id] = item.quantity
  })
  showProcessModal.value = true
}

async function handleProcess() {
  if (!selectedOrder.value) return
  
  loading.value = true
  try {
    const items = selectedOrder.value.items.map(item => ({
      product_id: item.product_id,
      actual_qty: actualQtys.value[item.product_id] || 0
    }))

    await soStore.processByWarehouse(selectedOrder.value.id, items)
    toast.success('Pesanan berhasil diproses. Surat Jalan telah diterbitkan.')
    showProcessModal.value = false
    await fetchOrders()
  } catch (e: any) {
    toast.error(e?.response?.data?.error || 'Gagal memproses pesanan')
  } finally {
    loading.value = false
  }
}

async function handleOverride(order: SalesOrder) {
  if (!confirm('Apakah Anda yakin ingin memaksa kirim pesanan ini (Parsial)? Sisa stok yang tidak tersedia akan dibatalkan otomatis saat Surat Jalan terbit.')) return
  
  loading.value = true
  try {
    await soStore.overrideBackorder(order.id)
    toast.success('Pesanan berhasil dipindahkan ke antrean Siap Kirim.')
    activeTab.value = 'READY'
    await fetchOrders()
  } catch (e: any) {
    toast.error(e?.response?.data?.error || 'Gagal override pesanan')
  } finally {
    loading.value = false
  }
}

const formatDate = (d: string) => d ? new Date(d).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' }) : '-'

onMounted(async () => {
  if (masterStore.selectedBranchId) fetchOrders()
})
</script>

<template>
  <div class="space-y-8 p-6">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h1 class="text-3xl font-extrabold text-slate-900 tracking-tight flex items-center gap-3">
          <Package class="w-8 h-8 text-blue-600" />
          Pesanan Masuk (Gudang)
        </h1>
        <p class="text-sm text-slate-500 mt-1">Validasi fisik stok dan terbitkan Surat Jalan untuk pesanan salesman.</p>
      </div>
      <Button @click="fetchOrders" variant="outline" class="rounded-2xl flex items-center gap-2">
        <RefreshCw class="w-4 h-4" :class="{ 'animate-spin': soStore.loading }" /> Segarkan Data
      </Button>
    </div>

    <!-- Tabs -->
    <div class="flex gap-2 bg-white p-1.5 rounded-[24px] border border-slate-200 w-fit">
      <button 
        @click="activeTab = 'READY'"
        :class="activeTab === 'READY' ? 'bg-blue-600 text-white shadow-lg' : 'text-slate-500 hover:bg-slate-50'"
        class="px-8 py-3 rounded-[20px] text-xs font-black transition-all flex items-center gap-2"
      >
        <Package class="w-4 h-4" /> Siap Kirim
      </button>
      <button 
        @click="activeTab = 'BACKORDER'"
        :class="activeTab === 'BACKORDER' ? 'bg-red-600 text-white shadow-lg' : 'text-slate-500 hover:bg-slate-50'"
        class="px-8 py-3 rounded-[20px] text-xs font-black transition-all flex items-center gap-2"
      >
        <RefreshCw class="w-4 h-4" /> Antrean Backorder
      </button>
    </div>

    <!-- Empty State -->
    <div v-if="filteredOrders.length === 0 && !soStore.loading" class="text-center py-24 bg-slate-50 rounded-[40px] border-2 border-dashed border-slate-200">
      <div class="bg-white w-20 h-20 rounded-3xl shadow-sm flex items-center justify-center mx-auto mb-6">
        <ClipboardList class="w-10 h-10 text-slate-300" />
      </div>
      <h3 class="text-xl font-black text-slate-900">
        {{ activeTab === 'READY' ? 'Belum Ada Pesanan Baru' : 'Antrean Backorder Kosong' }}
      </h3>
      <p class="text-slate-500 mt-2 max-w-xs mx-auto text-sm font-medium">
        {{ activeTab === 'READY' ? 'Semua pesanan telah diproses atau belum ada yang dikonfirmasi.' : 'Bagus! Semua pesanan pelanggan sudah memiliki alokasi stok.' }}
      </p>
    </div>

    <!-- List -->
    <div v-else class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
      <div v-for="order in filteredOrders" :key="order.id" 
        class="bg-white border border-slate-200 rounded-[32px] p-6 shadow-sm hover:shadow-xl transition-all group relative overflow-hidden"
        :class="activeTab === 'READY' ? 'border-b-4 border-b-blue-500' : 'border-b-4 border-b-red-500'"
      >
        <div class="flex items-center justify-between mb-4">
          <span :class="activeTab === 'READY' ? 'bg-blue-100 text-blue-700' : 'bg-red-100 text-red-700'" class="text-[10px] font-black px-3 py-1 rounded-full uppercase tracking-widest">{{ order.status }}</span>
          <span class="text-[10px] font-mono text-slate-400">{{ order.so_number }}</span>
        </div>

        <h4 class="text-xl font-black text-slate-900 mb-1 group-hover:text-blue-600 transition-colors">{{ order.store?.name }}</h4>
        <p class="text-xs text-slate-500 font-medium mb-6 flex items-center gap-1.5">
          <Truck class="w-3.5 h-3.5" /> {{ order.employee?.first_name }} {{ order.employee?.last_name }} • {{ formatDate(order.order_date) }}
        </p>

        <div class="bg-slate-50 rounded-2xl p-4 mb-6">
          <p class="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-3">Item Pesanan & Alokasi Batch</p>
          <div class="space-y-4">
            <div v-for="item in order.items" :key="item.id" class="space-y-2">
              <div class="flex justify-between text-sm">
                <span class="font-bold text-slate-700 truncate mr-2">{{ item.product?.name }}</span>
                <span class="font-black text-slate-900 shrink-0">{{ item.quantity }} {{ item.product?.unit || 'pcs' }}</span>
              </div>
              
              <!-- Batch Allocation Badges -->
              <div class="flex flex-wrap gap-1.5 mt-1">
                <div v-for="b in item.batches" :key="b.id" 
                  :class="b.batch_no === 'BACKORDER' ? 'bg-red-50 text-red-600 border-red-100' : 'bg-emerald-50 text-emerald-700 border-emerald-100'"
                  class="text-[9px] font-bold px-2 py-0.5 rounded-lg border flex items-center gap-1 shadow-sm"
                >
                  <span class="opacity-50 text-[8px]">BATCH:</span> {{ b.batch_no }} 
                  <span class="ml-1 px-1 bg-white/50 rounded-md">{{ b.quantity }}</span>
                </div>
              </div>

              <!-- Progress alokasi stok untuk backorder -->
              <div v-if="activeTab === 'BACKORDER'" class="h-1.5 bg-slate-200 rounded-full overflow-hidden flex mt-2">
                <div 
                  class="h-full bg-emerald-500 transition-all duration-500" 
                  :style="{ width: `${(item.reserved_quantity / item.quantity) * 100}%` }"
                ></div>
              </div>
              <p v-if="activeTab === 'BACKORDER'" class="text-[9px] font-bold text-slate-400">
                Ter-alokasi: {{ item.reserved_quantity }} / {{ item.quantity }}
              </p>
            </div>
          </div>
        </div>

        <Button v-if="activeTab === 'READY'" @click="openProcessModal(order)" class="w-full bg-slate-900 hover:bg-blue-600 text-white rounded-2xl py-6 font-black text-xs flex items-center justify-center gap-2 transition-all">
          <CheckCircle2 class="w-4 h-4" /> Proses & Validasi Stok
        </Button>
        <Button v-else @click="handleOverride(order)" :disabled="loading" class="w-full bg-white border-2 border-red-200 text-red-600 hover:bg-red-50 rounded-2xl py-6 font-black text-xs flex items-center justify-center gap-2 transition-all">
          <X class="w-4 h-4" /> Paksa Kirim Parsial (Override)
        </Button>
      </div>
    </div>

    <!-- Modal Validasi Stok Riil -->
    <div v-if="showProcessModal && selectedOrder" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="absolute inset-0 bg-slate-900/60 backdrop-blur-sm" @click="showProcessModal = false" />
      <div class="bg-white rounded-[40px] w-full max-w-lg relative z-10 shadow-2xl overflow-hidden flex flex-col max-h-[90vh]">
        <div class="p-8 border-b border-slate-100 flex items-center justify-between bg-slate-50/50">
          <div>
            <h3 class="text-2xl font-black text-slate-900">Validasi Fisik Barang</h3>
            <p class="text-xs font-bold text-slate-500 mt-1 uppercase tracking-widest">SO: {{ selectedOrder.so_number }}</p>
          </div>
          <button @click="showProcessModal = false" class="p-2 hover:bg-white rounded-2xl text-slate-400 transition-all shadow-sm">
            <X class="w-6 h-6" />
          </button>
        </div>

        <div class="p-8 overflow-y-auto space-y-6">
          <div class="bg-blue-50 border border-blue-100 rounded-3xl p-5 flex items-start gap-4">
            <Box class="w-6 h-6 text-blue-600 shrink-0 mt-1" />
            <p class="text-xs font-bold text-blue-800 leading-relaxed">
              Masukkan jumlah barang riil yang siap dikirim. Jika stok fisik kurang, masukkan jumlah yang ada. Selisih akan otomatis dikembalikan ke sistem.
            </p>
          </div>

          <div class="space-y-4">
            <div v-for="item in selectedOrder.items" :key="item.id" class="flex items-center gap-4 bg-slate-50 p-4 rounded-3xl border border-transparent hover:border-blue-200 transition-all">
              <div class="flex-1">
                <p class="font-black text-slate-900 text-sm">{{ item.product?.name }}</p>
                <p class="text-[10px] font-black text-slate-400 uppercase tracking-widest mt-0.5">Dipesan: {{ item.quantity }} {{ item.product?.unit }}</p>
              </div>
              <div class="w-32">
                <div class="relative">
                  <input v-model.number="actualQtys[item.product_id]" type="number" min="0" :max="item.quantity" class="w-full bg-white border-2 border-slate-200 rounded-2xl px-4 py-3 font-black text-center text-blue-600 focus:border-blue-500 outline-none transition-all" />
                  <span class="absolute -top-2 -right-1 bg-slate-900 text-white text-[8px] font-black px-1.5 py-0.5 rounded-full uppercase">Riil</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="p-8 border-t border-slate-100 bg-slate-50/50 flex gap-4">
          <Button variant="outline" @click="showProcessModal = false" class="flex-1 rounded-2xl py-7 font-black text-slate-500">Batal</Button>
          <Button @click="handleProcess" :disabled="loading" class="flex-[2] bg-blue-600 hover:bg-blue-700 text-white rounded-2xl py-7 font-black shadow-xl shadow-blue-500/20">
            {{ loading ? 'Memproses...' : 'Terbitkan Surat Jalan' }}
          </Button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* Chrome, Safari, Edge, Opera */
input::-webkit-outer-spin-button,
input::-webkit-inner-spin-button {
  -webkit-appearance: none;
  appearance: none;
  margin: 0;
}
/* Firefox */
input[type=number] {
  -moz-appearance: textfield;
  appearance: textfield;
}
</style>
