<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useSalesReturnStore, type SalesReturn } from '@/stores/salesReturn'
import { useMasterDataStore } from '@/stores/masterData'
import { toast } from 'vue-sonner'
import { 
  RotateCcw, CheckCircle2, AlertCircle, 
  Search, RefreshCw, X, Box, Info
} from 'lucide-vue-next'
import { Button } from '@/components/ui/button'

const returnStore = useSalesReturnStore()
const masterStore = useMasterDataStore()

const searchQuery = ref('')
const selectedStatus = ref('ALL')
const loading = ref(false)

const filteredReturns = computed(() => {
  return returnStore.returns.filter(r => {
    const matchStatus = selectedStatus.value === 'ALL' || r.status === selectedStatus.value
    const q = searchQuery.value.toLowerCase()
    const matchSearch = !q || r.return_no.toLowerCase().includes(q) || r.sales_order?.so_number?.toLowerCase().includes(q)
    return matchStatus && matchSearch
  })
})

async function fetchReturns() {
  if (!masterStore.selectedBranchId) return
  await returnStore.fetchByBranch(masterStore.selectedBranchId, selectedStatus.value)
}

async function handleApprove(id: string) {
  if (!confirm('Setujui retur ini? Stok karantina akan bertambah dan tagihan akan dipotong.')) return
  
  loading.value = true
  try {
    await returnStore.approveReturn(id)
    toast.success('Retur berhasil disetujui')
    await fetchReturns()
  } catch (e: any) {
    toast.error(e?.response?.data?.error || 'Gagal menyetujui retur')
  } finally {
    loading.value = false
  }
}

const formatDate = (d: string) => d ? new Date(d).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' }) : '-'
const formatCurrency = (v: number) => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(v)

onMounted(() => {
  if (masterStore.selectedBranchId) fetchReturns()
})
</script>

<template>
  <div class="space-y-8 p-6">
    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h1 class="text-3xl font-extrabold text-slate-900 tracking-tight flex items-center gap-3">
          <RotateCcw class="w-8 h-8 text-red-600" />
          Retur Penjualan
        </h1>
        <p class="text-sm text-slate-500 mt-1">Kelola pengembalian barang pelanggan dan penyesuaian tagihan (Credit Note).</p>
      </div>
      <Button @click="fetchReturns" variant="outline" class="rounded-2xl shadow-sm">
        <RefreshCw class="w-4 h-4 mr-2" :class="{ 'animate-spin': returnStore.loading }" /> Segarkan
      </Button>
    </div>

    <!-- Filters -->
    <div class="flex flex-col md:flex-row gap-4 items-center">
      <div class="relative flex-1 w-full">
        <Search class="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
        <input v-model="searchQuery" type="text" placeholder="Cari No. Retur atau No. SO..." class="w-full pl-11 pr-4 py-3 bg-white border border-slate-200 rounded-2xl text-sm outline-none focus:ring-2 focus:ring-red-500/20" />
      </div>
      <div class="flex bg-slate-100 p-1.5 rounded-2xl w-full md:w-auto">
        <button v-for="s in ['ALL', 'PENDING', 'APPROVED']" :key="s" @click="selectedStatus = s; fetchReturns()" :class="[selectedStatus === s ? 'bg-white text-slate-900 shadow-sm' : 'text-slate-500 hover:text-slate-700']" class="px-6 py-2 rounded-xl text-[10px] font-black uppercase tracking-widest transition-all">{{ s }}</button>
      </div>
    </div>

    <!-- Empty -->
    <div v-if="filteredReturns.length === 0 && !returnStore.loading" class="text-center py-24 bg-white border border-slate-200 rounded-[40px] shadow-sm">
      <Box class="w-16 h-16 text-slate-200 mx-auto mb-4" />
      <h3 class="text-lg font-black text-slate-900">Data Retur Kosong</h3>
      <p class="text-slate-500 text-sm mt-1">Belum ada pengajuan retur barang di cabang ini.</p>
    </div>

    <!-- List -->
    <div v-else class="grid grid-cols-1 xl:grid-cols-2 gap-6">
      <div v-for="ret in filteredReturns" :key="ret.id" class="bg-white border border-slate-200 rounded-[40px] p-8 shadow-sm hover:shadow-xl transition-all relative overflow-hidden group">
        <!-- Status Badge -->
        <div class="absolute top-0 right-0 px-8 py-2 rounded-bl-[20px] font-black text-[10px] tracking-widest uppercase shadow-sm" :class="ret.status === 'APPROVED' ? 'bg-emerald-500 text-white' : 'bg-amber-500 text-white'">
          {{ ret.status }}
        </div>

        <div class="flex flex-col sm:flex-row gap-6">
          <div class="flex-1">
            <p class="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1">No. Retur: {{ ret.return_no }}</p>
            <h4 class="text-2xl font-black text-slate-900 mb-4 tracking-tight">SO: {{ ret.sales_order?.so_number }}</h4>
            
            <div class="flex items-center gap-3 text-sm text-slate-600 font-bold mb-6">
              <span class="bg-slate-100 px-3 py-1 rounded-lg">Pelapor: {{ ret.employee?.first_name }}</span>
              <span class="bg-slate-100 px-3 py-1 rounded-lg">{{ formatDate(ret.created_at) }}</span>
            </div>

            <div class="bg-slate-50 rounded-3xl p-5 border border-slate-100 mb-6">
              <p class="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-3">Item Pengembalian</p>
              <div class="space-y-3">
                <div v-for="item in ret.items" :key="item.id" class="flex items-center justify-between">
                  <div class="flex items-center gap-3">
                    <div class="w-8 h-8 rounded-xl bg-white border border-slate-200 flex items-center justify-center text-xs font-black text-slate-400">
                      {{ item.quantity }}
                    </div>
                    <div>
                      <p class="text-xs font-black text-slate-900">{{ item.product?.name }}</p>
                      <p class="text-[10px] text-red-500 font-bold uppercase tracking-tighter">{{ item.reason }}</p>
                    </div>
                  </div>
                  <span class="text-xs font-black text-slate-900">{{ formatCurrency(item.price * item.quantity) }}</span>
                </div>
              </div>
            </div>

            <div v-if="ret.notes" class="flex gap-2 text-xs text-slate-500 mb-6 italic">
              <Info class="w-4 h-4 shrink-0" /> "{{ ret.notes }}"
            </div>
          </div>

          <div class="sm:w-48 flex flex-col justify-between">
            <div class="bg-red-50 rounded-3xl p-6 text-center border border-red-100">
              <p class="text-[10px] font-black text-red-600 uppercase tracking-widest mb-1 leading-tight">Total Kredit Nota</p>
              <p class="text-xl font-black text-red-700 tracking-tighter">{{ formatCurrency(ret.total_amount) }}</p>
            </div>

            <div class="mt-6 sm:mt-0">
              <Button v-if="ret.status === 'PENDING'" @click="handleApprove(ret.id)" :disabled="loading" class="w-full bg-slate-900 hover:bg-emerald-600 text-white rounded-2xl py-6 font-black text-xs transition-all shadow-lg shadow-slate-900/10">
                Setujui Retur
              </Button>
              <div v-else class="flex items-center justify-center gap-2 text-emerald-600 font-black text-xs bg-emerald-50 py-4 rounded-2xl border border-emerald-100">
                <CheckCircle2 class="w-4 h-4" /> SELESAI
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
