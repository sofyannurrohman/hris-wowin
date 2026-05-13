<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useSalesOrderStore, type SalesOrder, type SOStatus } from '@/stores/salesOrder'
import { useMasterDataStore } from '@/stores/masterData'
import { useFactoryStore } from '@/stores/factory'
import { toast } from 'vue-sonner'
import {
  ClipboardList, CheckCircle2, XCircle, FileText,
  Plus, X, Trash2, ChevronDown, Search, RefreshCw, ArrowRight
} from 'lucide-vue-next'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'

const soStore = useSalesOrderStore()
const masterStore = useMasterDataStore()
const factoryStore = useFactoryStore()

const selectedStatus = ref<SOStatus | 'ALL'>('ALL')
const selectedCompanyId = ref('ALL')
const selectedEmployeeId = ref('ALL')
const searchQuery = ref('')
const showCreateModal = ref(false)
const showDetailModal = ref(false)
const selectedOrder = ref<SalesOrder | null>(null)
const loading = ref(false)

// --- Form ---
const form = ref({
  store_id: '',
  store_category: 'TOKO_LAMA',
  notes: '',
  items: [{ product_id: '', ordered_quantity: 1, unit: 'PCS', pieces_per_unit: 1, price: 0 }] as any[]
})

const UNIT_OPTIONS = ['KARTON', 'DUS', 'BOX', 'KRAT', 'PCS', 'BAL', 'PACK', 'KG', 'GRAM', 'SACHET', 'JERIGEN', 'BOTOL']

const statusOptions = ['ALL', 'DRAFT', 'CONFIRMED', 'IN_DELIVERY', 'DELIVERED', 'PAID', 'WAITING_WAREHOUSE', 'WAITING_STOCK', 'SHIPPED', 'CONVERTED', 'CANCELLED', 'REJECTED']

const statusColor: Record<string, string> = {
  DRAFT: 'bg-slate-100 text-slate-600',
  CONFIRMED: 'bg-green-100 text-green-700',
  IN_DELIVERY: 'bg-blue-100 text-blue-700',
  DELIVERED: 'bg-teal-100 text-teal-700',
  PAID: 'bg-emerald-100 text-emerald-700',
  WAITING_WAREHOUSE: 'bg-amber-100 text-amber-700',
  WAITING_STOCK: 'bg-orange-100 text-orange-700',
  PROCESSING: 'bg-blue-100 text-blue-700',
  SHIPPED: 'bg-indigo-100 text-indigo-700',
  CONVERTED: 'bg-emerald-100 text-emerald-700',
  CANCELLED: 'bg-red-100 text-red-600',
  REJECTED: 'bg-red-50 text-red-400',
}


const filteredOrders = computed(() => {
  const filtered = soStore.orders.filter(o => {
    const matchStatus = selectedStatus.value === 'ALL' || o.status === selectedStatus.value
    const matchCompany = selectedCompanyId.value === 'ALL' || o.company_id === selectedCompanyId.value
    const matchEmployee = selectedEmployeeId.value === 'ALL' || o.employee_id === selectedEmployeeId.value
    
    const q = searchQuery.value.toLowerCase()
    const matchSearch = !q || 
      o.so_number.toLowerCase().includes(q) || 
      o.store?.name?.toLowerCase().includes(q) || 
      o.employee?.first_name?.toLowerCase().includes(q) ||
      o.employee?.last_name?.toLowerCase().includes(q)
      
    return matchStatus && matchCompany && matchEmployee && matchSearch
  })
  
  // Urutkan berdasarkan yang terbaru (created_at DESC)
  return [...filtered].sort((a, b) => {
    return new Date(b.created_at).getTime() - new Date(a.created_at).getTime()
  })
})

const stockSummary = computed(() => {
  if (!selectedOrder.value) return []
  return selectedOrder.value.items.map(item => ({
    ...item,
    productName: item.product?.name || item.product_id,
  }))
})

const itemTotal = computed(() =>
  form.value.items.reduce((sum, i) => sum + (i.ordered_quantity * i.pieces_per_unit * i.price), 0)
)

function addItem() {
  form.value.items.push({ product_id: '', ordered_quantity: 1, unit: 'PCS', pieces_per_unit: 1, price: 0 })
}
function removeItem(idx: number) {
  form.value.items.splice(idx, 1)
}
function onProductChange(idx: number) {
  const p = factoryStore.products.find(p => p.id === form.value.items[idx].product_id)
  if (p) form.value.items[idx].price = p.selling_price || 0
}

async function fetchOrders() {
  if (!masterStore.selectedBranchId) return
  await soStore.fetchByBranch(masterStore.selectedBranchId, 'ALL')
}

async function handleCreate() {
  if (!form.value.store_id) { toast.error('Pilih toko terlebih dahulu'); return }
  if (form.value.items.some(i => !i.product_id)) { toast.error('Lengkapi semua produk'); return }
  loading.value = true
  try {
    await soStore.createSO({
      branch_id: masterStore.selectedBranchId,
      company_id: masterStore.selectedBranchCompanyId,
      employee_id: masterStore.employees[0]?.id,
      store_id: form.value.store_id,
      store_category: form.value.store_category,
      notes: form.value.notes,
      items: form.value.items.map(i => ({ 
        product_id: i.product_id, 
        ordered_quantity: i.ordered_quantity, 
        unit: i.unit,
        pieces_per_unit: i.pieces_per_unit,
        price: i.price 
      }))
    })
    toast.success('Pesanan berhasil dibuat')
    showCreateModal.value = false
    form.value = { 
      store_id: '', 
      store_category: 'TOKO_LAMA', 
      notes: '', 
      items: [{ product_id: '', ordered_quantity: 1, unit: 'PCS', pieces_per_unit: 1, price: 0 }] 
    }
  } catch (e: any) { toast.error(e?.response?.data?.error || 'Gagal membuat pesanan') }
  finally { loading.value = false }
}

async function handleConfirm(id: string) {
  if (!confirm('Konfirmasi SO? Stok gudang akan di-reserve.')) return
  try {
    await soStore.confirmSO(id)
    toast.success('SO dikonfirmasi, stok berhasil di-reserve')
  } catch (e: any) { toast.error(e?.response?.data?.error || 'Gagal konfirmasi') }
}

/** Admin Nota: Verifikasi nota salesman → status CONFIRMED, nota siap di-batch */
async function handleAdminConfirm(id: string) {
  if (!confirm('Verifikasi nota ini? Status akan berubah menjadi CONFIRMED dan nota bisa masuk Batch Pengiriman.')) return
  try {
    await soStore.adminConfirmSO(id)
    toast.success('✅ Nota berhasil diverifikasi. Supervisor bisa membuat batch pengiriman.')
  } catch (e: any) { toast.error(e?.response?.data?.error || 'Gagal verifikasi nota') }
}

/** Admin Nota: Tolak nota salesman */
async function handleAdminReject(id: string) {
  const notes = prompt('Alasan penolakan nota (disampaikan ke salesman):')
  if (notes === null) return
  try {
    await soStore.adminRejectSO(id, notes)
    toast.success('Nota berhasil ditolak')
  } catch (e: any) { toast.error(e?.response?.data?.error || 'Gagal menolak nota') }
}

async function handleReject(id: string) {
  const notes = prompt('Alasan penolakan:')
  if (notes === null) return
  try {
    await soStore.rejectSO(id, notes)
    toast.success('SO ditolak')
  } catch (e: any) { toast.error(e?.response?.data?.error || 'Gagal menolak') }
}

async function handleCancel(id: string) {
  if (!confirm('Batalkan SO ini? Reserve stok akan dilepas.')) return
  try {
    await soStore.cancelSO(id)
    toast.success('SO dibatalkan, stok dilepas')
  } catch (e: any) { toast.error(e?.response?.data?.error || 'Gagal membatalkan') }
}

async function handleConvert(id: string) {
  if (!confirm('Terbitkan Faktur Penjualan? Stok akan DIPOTONG PERMANEN dari gudang.')) return
  loading.value = true
  try {
    const invoice = await soStore.convertToInvoice(id, masterStore.selectedBranchCompanyId)
    toast.success(`Faktur ${invoice.receipt_no} berhasil diterbitkan!`)
  } catch (e: any) { toast.error(e?.response?.data?.error || 'Gagal menerbitkan faktur') }
  finally { loading.value = false }
}

async function handleDelete(id: string) {
  if (!confirm('Hapus pesanan ini permanen?')) return
  try {
    await soStore.deleteSO(id, masterStore.selectedBranchId as string)
    toast.success('Pesanan dihapus')
  } catch (e: any) { toast.error(e?.response?.data?.error || 'Gagal menghapus') }
}

function openDetail(order: SalesOrder) {
  selectedOrder.value = order
  showDetailModal.value = true
}

const formatCurrency = (v: number) =>
  new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(v)
const formatDate = (d: string) => d ? new Date(d).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' }) : '-'

onMounted(async () => {
  await Promise.all([
    factoryStore.fetchProducts(), 
    masterStore.fetchBranches(), 
    masterStore.fetchCompanies(),
    masterStore.fetchEmployees(),
    masterStore.fetchStores(masterStore.selectedBranchCompanyId)
  ])
  fetchOrders()
})
watch(() => masterStore.selectedBranchId, () => {
  fetchOrders()
  masterStore.fetchStores(masterStore.selectedBranchCompanyId)
})
</script>

<template>
  <div class="space-y-8 p-6">

    <!-- Header -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h1 class="text-3xl font-extrabold text-slate-900 tracking-tight flex items-center gap-3">
          <ClipboardList class="w-8 h-8 text-primary" />
          Pesanan Order (SO)
        </h1>
        <p class="text-sm text-slate-500 mt-1">Kelola pesanan sebelum diterbitkan sebagai Faktur Penjualan.</p>
      </div>
      <Button @click="showCreateModal = true" class="rounded-2xl px-6 py-6 font-bold flex items-center gap-2 shadow-lg shadow-primary/20">
        <Plus class="w-5 h-5" /> Buat Pesanan Baru
      </Button>
    </div>

    <!-- Status Flow Indicator -->
    <div class="bg-gradient-to-r from-slate-50 to-blue-50 border border-slate-200 rounded-3xl p-5 flex items-center gap-3 overflow-x-auto no-scrollbar">
      <div v-for="(step, i) in [{ label: 'DRAFT', sub: 'Salesman', color: 'bg-slate-200 text-slate-700' }, { label: 'WAITING', sub: 'Gudang', color: 'bg-amber-500 text-white' }, { label: 'SHIPPED', sub: 'Surat Jalan', color: 'bg-indigo-500 text-white' }, { label: 'CONVERTED', sub: 'Faktur/Invoice', color: 'bg-emerald-500 text-white' }]" :key="step.label" class="flex items-center gap-3 shrink-0">
        <div :class="[step.color, 'rounded-2xl px-4 py-2 text-center min-w-[120px] shadow-sm']">
          <p class="text-[10px] font-black uppercase tracking-widest">{{ step.label }}</p>
          <p class="text-[9px] font-medium mt-0.5 opacity-75">{{ step.sub }}</p>
        </div>
        <ArrowRight v-if="i < 3" class="w-4 h-4 text-slate-400 shrink-0" />
      </div>
    </div>


    <!-- Filters -->
    <div class="flex flex-col lg:flex-row gap-4">
      <div class="relative flex-1">
        <Search class="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
        <input v-model="searchQuery" type="text" placeholder="Cari nomor SO, toko, atau salesman..." class="w-full pl-11 pr-4 py-3.5 bg-white border border-slate-200 rounded-2xl text-sm font-medium focus:ring-2 focus:ring-primary/20 focus:border-primary/30 outline-none shadow-sm" />
      </div>
      <div class="flex flex-wrap gap-2">
        <select v-model="selectedCompanyId" class="bg-white border border-slate-200 rounded-2xl px-4 py-3.5 text-xs font-bold outline-none focus:ring-2 focus:ring-primary/20 shadow-sm min-w-[160px]">
          <option value="ALL">Semua Perusahaan</option>
          <option v-for="c in masterStore.companies" :key="c.id" :value="c.id">{{ c.name }}</option>
        </select>
        <select v-model="selectedEmployeeId" class="bg-white border border-slate-200 rounded-2xl px-4 py-3.5 text-xs font-bold outline-none focus:ring-2 focus:ring-primary/20 shadow-sm min-w-[160px]">
          <option value="ALL">Semua Salesman</option>
          <option v-for="e in masterStore.employees" :key="e.id" :value="e.id">{{ e.first_name }} {{ e.last_name }}</option>
        </select>
      </div>
    </div>

    <div class="flex gap-2 overflow-x-auto no-scrollbar">
      <button v-for="s in statusOptions" :key="s" @click="selectedStatus = s as any" :class="['px-4 py-3 rounded-2xl text-xs font-black transition-all whitespace-nowrap', selectedStatus === s ? 'bg-slate-900 text-white shadow-lg' : 'bg-white border border-slate-200 text-slate-500 hover:bg-slate-50']">
        {{ s }}
      </button>
    </div>

    <!-- Orders List -->
    <div v-if="soStore.loading" class="text-center py-20 text-slate-400 flex flex-col items-center gap-3">
      <RefreshCw class="w-8 h-8 animate-spin" />
      <p class="text-sm font-bold">Memuat pesanan...</p>
    </div>

    <div v-else-if="filteredOrders.length === 0" class="text-center py-20 bg-slate-50 rounded-3xl border-2 border-dashed border-slate-200">
      <ClipboardList class="w-12 h-12 text-slate-300 mx-auto mb-3" />
      <p class="font-black text-slate-500">Tidak ada pesanan ditemukan</p>
      <p class="text-sm text-slate-400 mt-1">Buat pesanan baru atau ubah filter status</p>
    </div>

    <div v-else class="bg-white border border-slate-200 rounded-[2.5rem] shadow-sm overflow-hidden">
      <Table>
        <TableHeader class="bg-slate-50/50">
          <TableRow>
            <TableHead class="font-black text-[10px] uppercase tracking-widest pl-8">No. SO / Tanggal</TableHead>
            <TableHead class="font-black text-[10px] uppercase tracking-widest">Toko / Customer</TableHead>
            <TableHead class="font-black text-[10px] uppercase tracking-widest">Salesman</TableHead>
            <TableHead class="font-black text-[10px] uppercase tracking-widest">Item</TableHead>
            <TableHead class="font-black text-[10px] uppercase tracking-widest text-right">Total Amount</TableHead>
            <TableHead class="font-black text-[10px] uppercase tracking-widest text-center">Status</TableHead>
            <TableHead class="font-black text-[10px] uppercase tracking-widest text-right pr-8">Aksi</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          <TableRow v-for="order in filteredOrders" :key="order.id" class="group hover:bg-slate-50/50 transition-colors">
            <TableCell class="pl-8">
              <div class="flex flex-col">
                <span class="font-mono text-[10px] font-bold text-slate-400 mb-1 tracking-tight">{{ order.so_number }}</span>
                <span class="font-bold text-xs text-slate-700 whitespace-nowrap">{{ formatDate(order.order_date) }}</span>
              </div>
            </TableCell>
            <TableCell>
              <div class="flex flex-col">
                <span class="font-black text-slate-900 leading-tight">{{ order.store?.name || 'Unknown Store' }}</span>
                <span class="text-[10px] font-bold text-slate-400 mt-1 uppercase tracking-wider">{{ order.store_category?.replace('_', ' ') }}</span>
              </div>
            </TableCell>
            <TableCell>
              <div class="flex items-center gap-2">
                <div class="h-7 w-7 rounded-full bg-primary/10 flex items-center justify-center text-[10px] font-black text-primary">
                  {{ order.employee?.first_name?.charAt(0) }}{{ order.employee?.last_name?.charAt(0) }}
                </div>
                <span class="font-bold text-slate-700 text-xs">{{ order.employee?.first_name }} {{ order.employee?.last_name }}</span>
              </div>
            </TableCell>
            <TableCell>
              <div class="flex flex-wrap gap-1 max-w-[200px]">
                <Badge variant="outline" v-for="item in order.items.slice(0, 2)" :key="item.id" class="text-[9px] font-bold px-2 py-0 h-5 border-slate-200 bg-white">
                  {{ item.product?.name?.split(' ')[0] }}... x{{ item.ordered_quantity }}
                </Badge>
                <span v-if="order.items.length > 2" class="text-[9px] font-bold text-slate-400 ml-1">+{{ order.items.length - 2 }} more</span>
              </div>
            </TableCell>
            <TableCell class="text-right">
              <span class="font-black text-slate-900">{{ formatCurrency(order.total_amount) }}</span>
            </TableCell>
            <TableCell class="text-center">
              <span :class="[statusColor[order.status], 'text-[9px] font-black px-2.5 py-1 rounded-full uppercase tracking-wider shadow-sm']">
                {{ order.status }}
              </span>
            </TableCell>
            <TableCell class="text-right pr-8">
              <div class="flex items-center justify-end gap-2">
                <Button variant="ghost" size="sm" @click="openDetail(order)" class="h-8 w-8 p-0 rounded-lg hover:bg-primary/5 hover:text-primary transition-all">
                  <FileText class="w-4 h-4" />
                </Button>
                
                <template v-if="order.status === 'DRAFT'">
                  <Button size="sm" @click="handleAdminConfirm(order.id)" class="h-8 px-3 rounded-lg bg-emerald-500 hover:bg-emerald-600 text-white text-[10px] font-black shadow-sm">
                    APPROVE
                  </Button>
                  <Button variant="ghost" size="sm" @click="handleAdminReject(order.id)" class="h-8 w-8 p-0 rounded-lg text-red-400 hover:bg-red-50 hover:text-red-600">
                    <XCircle class="w-4 h-4" />
                  </Button>
                </template>

                <template v-else-if="order.status === 'SHIPPED'">
                  <Button size="sm" @click="handleConvert(order.id)" class="h-8 px-3 rounded-lg bg-indigo-500 hover:bg-indigo-600 text-white text-[10px] font-black shadow-sm flex items-center gap-1">
                    <FileText class="w-3.5 h-3.5" /> INVOICE
                  </Button>
                </template>

                <template v-else-if="order.status === 'WAITING_WAREHOUSE'">
                  <Button variant="ghost" size="sm" @click="handleCancel(order.id)" class="h-8 w-8 p-0 rounded-lg text-slate-400 hover:bg-red-50 hover:text-red-600">
                    <XCircle class="w-4 h-4" />
                  </Button>
                </template>

                <Button v-if="order.status === 'DRAFT' || order.status === 'REJECTED'" variant="ghost" size="sm" @click="handleDelete(order.id)" class="h-8 w-8 p-0 rounded-lg text-slate-300 hover:bg-red-50 hover:text-red-600">
                  <Trash2 class="w-4 h-4" />
                </Button>
              </div>
            </TableCell>
          </TableRow>
        </TableBody>
      </Table>
    </div>

    <!-- Create Modal -->
    <div v-if="showCreateModal" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="absolute inset-0 bg-slate-900/60 backdrop-blur-sm" @click="showCreateModal = false" />
      <div class="bg-white rounded-[32px] w-full max-w-xl relative z-10 shadow-2xl flex flex-col max-h-[90vh] overflow-hidden">
        <div class="px-6 py-5 border-b border-slate-100 flex items-center justify-between">
          <div>
            <h3 class="text-xl font-black text-slate-900">Buat Pesanan Order</h3>
            <p class="text-[10px] font-black text-slate-400 uppercase tracking-widest mt-0.5">Stok belum dipotong hingga faktur diterbitkan</p>
          </div>
          <button @click="showCreateModal = false" class="p-2 hover:bg-slate-100 rounded-xl text-slate-400 hover:text-slate-900">
            <X class="w-5 h-5" />
          </button>
        </div>

        <div class="p-6 overflow-y-auto space-y-5">
          <div class="space-y-2">
            <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest">Toko</label>
            <select v-model="form.store_id" class="w-full bg-slate-50 border-2 border-transparent rounded-2xl px-5 py-3.5 font-bold text-slate-900 focus:bg-white focus:border-primary/20 outline-none appearance-none">
              <option value="">Pilih Toko</option>
              <option v-for="s in masterStore.stores" :key="s.id" :value="s.id">{{ s.name }}</option>
            </select>
          </div>

          <div class="space-y-2">
            <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest">Kategori</label>
            <select v-model="form.store_category" class="w-full bg-slate-50 border-2 border-transparent rounded-2xl px-5 py-3.5 font-bold text-slate-900 focus:bg-white focus:border-primary/20 outline-none appearance-none">
              <option value="TOKO_LAMA">Toko Lama</option>
              <option value="TOKO_BARU">Toko Baru</option>
            </select>
          </div>

          <!-- Items -->
          <div class="space-y-3">
            <div class="flex items-center justify-between">
              <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest">Item Pesanan</label>
              <button @click="addItem" class="text-[10px] font-black text-primary flex items-center gap-1 hover:underline">
                <Plus class="w-3 h-3" /> Tambah
              </button>
            </div>
            <div v-for="(item, idx) in form.items" :key="idx" class="space-y-2 bg-slate-50 p-4 rounded-3xl border border-slate-100">
              <div class="flex items-center gap-2">
                <select v-model="item.product_id" @change="onProductChange(idx)" class="flex-1 bg-white border-0 rounded-xl px-4 py-2.5 text-xs font-bold focus:ring-2 focus:ring-primary/20 outline-none">
                  <option value="">Pilih Produk</option>
                  <option v-for="p in factoryStore.products" :key="p.id" :value="p.id">{{ p.name }}</option>
                </select>
                <button @click="removeItem(idx)" class="p-2.5 text-red-400 hover:text-red-600 hover:bg-red-50 rounded-xl transition-colors"><Trash2 class="w-4 h-4" /></button>
              </div>
              
              <div class="grid grid-cols-4 gap-2">
                <div class="space-y-1">
                  <label class="text-[8px] font-black text-slate-400 uppercase ml-1">Jumlah</label>
                  <input v-model.number="item.ordered_quantity" type="number" min="1" class="w-full bg-white border-0 rounded-xl px-3 py-2 text-xs font-bold focus:ring-2 focus:ring-primary/20 outline-none" />
                </div>
                <div class="space-y-1">
                  <label class="text-[8px] font-black text-slate-400 uppercase ml-1">Satuan</label>
                  <select v-model="item.unit" class="w-full bg-white border-0 rounded-xl px-2 py-2 text-[10px] font-bold focus:ring-2 focus:ring-primary/20 outline-none">
                    <option v-for="u in UNIT_OPTIONS" :key="u" :value="u">{{ u }}</option>
                  </select>
                </div>
                <div class="space-y-1">
                  <label class="text-[8px] font-black text-slate-400 uppercase ml-1">Isi/Unit</label>
                  <input v-model.number="item.pieces_per_unit" type="number" min="1" class="w-full bg-white border-0 rounded-xl px-3 py-2 text-xs font-bold focus:ring-2 focus:ring-primary/20 outline-none" />
                </div>
                <div class="space-y-1">
                  <label class="text-[8px] font-black text-slate-400 uppercase ml-1">Harga Satuan Dasar</label>
                  <div class="relative">
                    <span class="absolute left-2 top-1/2 -translate-y-1/2 text-[9px] text-slate-400 font-bold">Rp</span>
                    <input v-model.number="item.price" type="number" class="w-full bg-white border-0 rounded-xl pl-6 pr-2 py-2 text-[10px] font-bold focus:ring-2 focus:ring-primary/20 outline-none" />
                  </div>
                </div>
              </div>
              <div v-if="item.ordered_quantity > 1 || item.pieces_per_unit > 1" class="px-2 pt-1 flex justify-between items-center text-[9px] font-bold text-slate-400">
                 <span>Total: {{ item.ordered_quantity * item.pieces_per_unit }} PCS</span>
                 <span>Subtotal: {{ formatCurrency(item.ordered_quantity * item.pieces_per_unit * item.price) }}</span>
              </div>
            </div>
          </div>

          <div class="bg-slate-50 rounded-2xl px-5 py-3 flex justify-between items-center">
            <span class="text-xs font-black text-slate-500 uppercase tracking-wider">Total Nilai Pesanan</span>
            <span class="text-lg font-black text-primary">{{ formatCurrency(itemTotal) }}</span>
          </div>

          <div class="space-y-2">
            <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest">Catatan</label>
            <textarea v-model="form.notes" rows="2" class="w-full bg-slate-50 border-2 border-transparent rounded-2xl px-5 py-3 font-medium text-sm focus:bg-white focus:border-primary/20 outline-none resize-none" />
          </div>
        </div>

        <div class="p-5 border-t border-slate-100 bg-slate-50/50 flex gap-3 justify-end">
          <Button variant="outline" @click="showCreateModal = false" class="rounded-2xl font-bold px-6">Batal</Button>
          <Button @click="handleCreate" :disabled="loading" class="rounded-2xl font-bold px-8 shadow-lg shadow-primary/20">
            {{ loading ? 'Menyimpan...' : 'Buat Pesanan' }}
          </Button>
        </div>
      </div>
    </div>

    <!-- Detail Modal -->
    <div v-if="showDetailModal && selectedOrder" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="absolute inset-0 bg-slate-900/60 backdrop-blur-sm" @click="showDetailModal = false" />
      <div class="bg-white rounded-[32px] w-full max-w-lg relative z-10 shadow-2xl flex flex-col max-h-[90vh] overflow-hidden">
        <div class="px-6 py-5 border-b border-slate-100 flex items-center justify-between">
          <div>
            <h3 class="text-xl font-black text-slate-900">{{ selectedOrder.so_number }}</h3>
            <span :class="[statusColor[selectedOrder.status], 'text-[10px] font-black px-3 py-1 rounded-lg uppercase tracking-wider mt-1 inline-block']">{{ selectedOrder.status }}</span>
          </div>
          <button @click="showDetailModal = false" class="p-2 hover:bg-slate-100 rounded-xl text-slate-400 hover:text-slate-900">
            <X class="w-5 h-5" />
          </button>
        </div>
        <div class="p-6 overflow-y-auto space-y-4">
          <div class="grid grid-cols-2 gap-4 text-sm">
            <div><p class="text-[10px] font-black text-slate-400 uppercase tracking-widest">Toko</p><p class="font-bold text-slate-900 mt-1">{{ selectedOrder.store?.name }}</p></div>
            <div><p class="text-[10px] font-black text-slate-400 uppercase tracking-widest">Salesman</p><p class="font-bold text-slate-900 mt-1">{{ selectedOrder.employee?.first_name }} {{ selectedOrder.employee?.last_name }}</p></div>
            <div><p class="text-[10px] font-black text-slate-400 uppercase tracking-widest">Tanggal Pesanan</p><p class="font-bold text-slate-900 mt-1">{{ formatDate(selectedOrder.order_date) }}</p></div>
            <div v-if="selectedOrder.confirmed_at"><p class="text-[10px] font-black text-slate-400 uppercase tracking-widest">Dikonfirmasi</p><p class="font-bold text-slate-900 mt-1">{{ formatDate(selectedOrder.confirmed_at) }}</p></div>
          </div>

          <div class="border-t border-slate-100 pt-4">
            <p class="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-3">Detail Item Pesanan</p>
            <div class="space-y-2">
              <div v-for="item in stockSummary" :key="item.id" class="flex items-center justify-between bg-slate-50 p-3 rounded-2xl">
                <div>
                  <p class="font-bold text-sm text-slate-900">{{ item.productName }}</p>
                  <p class="text-[10px] text-slate-400 font-mono">{{ item.product?.sku }}</p>
                </div>
                <div class="text-right">
                  <p class="font-black text-primary">{{ item.ordered_quantity }} {{ item.unit }}</p>
                  <p class="text-[9px] text-slate-400 font-bold" v-if="item.pieces_per_unit > 1">({{ item.quantity }} PCS)</p>
                  <p class="text-[10px] text-slate-400">{{ formatCurrency(item.subtotal) }}</p>
                </div>
              </div>
            </div>
          </div>

          <div class="bg-primary/5 rounded-2xl p-4 flex justify-between items-center border border-primary/10">
            <span class="font-black text-slate-700">Total Nilai</span>
            <span class="text-xl font-black text-primary">{{ formatCurrency(selectedOrder.total_amount) }}</span>
          </div>

          <div v-if="selectedOrder.reject_notes" class="bg-red-50 border border-red-100 rounded-2xl p-4">
            <p class="text-[10px] font-black text-red-500 uppercase tracking-widest mb-1">Alasan Penolakan</p>
            <p class="text-sm text-red-700 font-medium">{{ selectedOrder.reject_notes }}</p>
          </div>
        </div>
      </div>
    </div>

  </div>
</template>

<style scoped>
.no-scrollbar::-webkit-scrollbar { display: none; }
.no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
</style>
