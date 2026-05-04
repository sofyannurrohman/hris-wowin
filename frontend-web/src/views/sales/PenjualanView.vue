<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import apiClient from '@/api/axios'
import { 
  Search, 
  Filter, 
  CheckCircle2, 
  XCircle, 
  Eye, 
  Banknote,
  Calendar,
  Image as ImageIcon,
  Plus,
  Pencil,
  Trash2,
  Save,
  X,
  Store,
  User,
  Clock,
  Maximize2,
  ZoomIn,
  ZoomOut,
  RotateCcw
} from 'lucide-vue-next'
import { Button } from '@/components/ui/button'
import { toast } from 'vue-sonner'

const searchQuery = ref('')
const selectedStatus = ref('ALL')
const isLoading = ref(true)

const salesData = ref<any[]>([])
const salesmen = ref<any[]>([])
const allStores = ref<any[]>([])
const showModal = ref(false)
const isEditing = ref(false)
const showImageModal = ref(false)
const previewImageUrl = ref('')
const zoomLevel = ref(1)
const currentSale = ref({
  id: '',
  employeeID: '',
  storeID: '',
  storeCategory: 'TOKO_LAMA',
  totalAmount: 0,
  transactionDate: new Date().toISOString().split('T')[0],
  receiptNo: '',
  receiptImageURL: '',
  status: 'VERIFIED',
  notes: ''
})

const openImagePreview = (url: string) => {
  previewImageUrl.value = url
  zoomLevel.value = 1
  showImageModal.value = true
}

const handleZoom = (val: number) => {
  zoomLevel.value = Math.max(0.5, Math.min(3, zoomLevel.value + val))
}

const fetchStores = async () => {
  try {
    const res = await apiClient.get('/stores')
    if (res.data?.data) {
      allStores.value = res.data.data
    }
  } catch (error) {
    console.error('Failed to fetch stores:', error)
  }
}

const fetchSalesmen = async () => {
  try {
    const res = await apiClient.get('/employees') // Assuming all employees can be salesmen or filter by role
    if (res.data?.data) {
      salesmen.value = res.data.data
    }
  } catch (error) {
    console.error('Failed to fetch salesmen:', error)
  }
}

const fetchSales = async () => {
  isLoading.value = true
  try {
    const res = await apiClient.get('/admin/sales/transactions/all')
    if (res.data?.data) {
      salesData.value = res.data.data.map((trx: any) => ({
        id: trx.id,
        employeeID: trx.employee_id,
        storeCategory: trx.store_category,
        salesman: trx.employee ? `${trx.employee.first_name} ${trx.employee.last_name}` : 'Unknown',
        store: trx.store?.name || 'Toko Manual',
        amount: trx.total_amount,
        date: formatDate(trx.transaction_date),
        status: trx.status === 'VERIFIED' ? 'APPROVED' : trx.status,
        receiptNo: trx.receipt_no,
        items: trx.notes ? [trx.notes] : [],
        notaImage: trx.receipt_image_url || 'https://placehold.co/600x400/f1f5f9/64748b?text=Foto+Nota'
      }))
    }
  } catch (error) {
    console.error('Failed to fetch sales data:', error)
  } finally {
    isLoading.value = false
  }
}

const openAddModal = () => {
  isEditing.value = false
  currentSale.value = {
    id: '',
    employeeID: '',
    storeID: '',
    storeCategory: 'TOKO_LAMA',
    totalAmount: 0,
    transactionDate: new Date().toISOString().split('T')[0],
    receiptNo: '',
    receiptImageURL: '',
    status: 'PENDING',
    notes: ''
  }
  showModal.value = true
}

const handleEdit = (sale: any) => {
  isEditing.value = true
  // We need to map frontend sale object back to form object
  // Find the raw data from salesData if needed or just use what we have
  const rawSale = salesData.value.find(s => s.id === sale.id)
  currentSale.value = {
    id: sale.id,
    employeeID: rawSale.employeeID || '',
    storeID: rawSale.storeID || '',
    storeCategory: rawSale.storeCategory || 'TOKO_LAMA',
    totalAmount: sale.amount,
    transactionDate: new Date(sale.date).toISOString().split('T')[0],
    receiptNo: sale.receiptNo || '',
    status: rawSale.status || 'PENDING',
    receiptImageURL: rawSale.receiptImageURL || '',
    notes: sale.items[0] || ''
  }
  showModal.value = true
}

const handleDelete = async (id: string) => {
  if (!confirm('Yakin ingin menghapus transaksi ini? Data KPI akan diperbarui otomatis.')) return
  
  try {
    await apiClient.delete(`/admin/sales/transactions/${id}`)
    toast.success('Transaksi berhasil dihapus')
    fetchSales()
  } catch (error) {
    toast.error('Gagal menghapus transaksi')
  }
}

const handleFileUpload = async (event: any) => {
  const file = event.target.files[0]
  if (!file) return

  const formData = new FormData()
  formData.append('file', file)

  try {
    const res = await apiClient.post('/admin/sales/upload', formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    })
    if (res.data?.url) {
      currentSale.value.receiptImageURL = res.data.url
      toast.success('Foto berhasil diunggah')
    }
  } catch (error) {
    console.error('Upload failed:', error)
    toast.error('Gagal mengunggah foto')
  }
}

const handleSubmit = async () => {
  try {
    const payload = {
      employee_id: currentSale.value.employeeID || null,
      store_id: currentSale.value.storeID || null,
      store_category: currentSale.value.storeCategory,
      total_amount: currentSale.value.totalAmount,
      transaction_date: currentSale.value.transactionDate,
      receipt_no: currentSale.value.receiptNo,
      receipt_image_url: currentSale.value.receiptImageURL,
      status: currentSale.value.status === 'APPROVED' ? 'VERIFIED' : currentSale.value.status,
      company_id: 'b72883e2-8bb6-438d-92bd-391edbf9e325'
    }

    if (isEditing.value) {
      await apiClient.put(`/admin/sales/transactions/${currentSale.value.id}`, payload)
      toast.success('Transaksi diperbarui')
    } else {
      await apiClient.post('/admin/sales/manual-entry', payload)
      toast.success('Transaksi baru ditambahkan')
    }
    showModal.value = false
    fetchSales()
  } catch (error) {
    toast.error('Gagal menyimpan transaksi')
  }
}

const handleApprove = async (id: string) => {
  const item = salesData.value.find(s => s.id === id)
  if (!item) return

  try {
    // API requires receipt_no and total_amount for verification
    await apiClient.patch(`/sales/transactions/${id}/verify`, {
      receipt_no: item.receiptNo || 'VERIFIED-' + id.slice(0, 4),
      total_amount: item.amount,
      notes: 'Verified by Admin'
    })
    toast.success(`Nota ${item.receiptNo || id.slice(0,8)} disetujui! Omzet salesman akan diperbarui otomatis.`)
    fetchSales() // Refresh
  } catch (error) {
    toast.error('Gagal menyetujui nota')
  }
}

const handleReject = (id: string) => {
  // Logic for rejection if needed, currently backend handles Verify as the only state change.
  toast.info('Fitur penolakan sedang dikembangkan')
}


onMounted(() => {
  fetchSales()
  fetchSalesmen()
  fetchStores()
})

const formatCurrency = (val: number) => {
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(val)
}

const formatDate = (date: string) => {
  if (!date) return '-'
  return new Date(date).toLocaleDateString('id-ID', {
    day: 'numeric',
    month: 'long',
    year: 'numeric'
  })
}

const filteredSales = computed(() => {
  return salesData.value.filter(s => {
    const matchesStatus = selectedStatus.value === 'ALL' || s.status === selectedStatus.value
    const matchesSearch = s.store.toLowerCase().includes(searchQuery.value.toLowerCase()) || 
                          s.salesman.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
                          (s.receiptNo && s.receiptNo.toLowerCase().includes(searchQuery.value.toLowerCase()))
    return matchesStatus && matchesSearch
  })
})

</script>

<template>
  <div class="space-y-8 pb-10">
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-6">
      <div>
        <h1 class="text-3xl font-extrabold text-slate-900 tracking-tight">Penjualan & Nota</h1>
        <p class="text-[15px] font-medium text-slate-500 mt-1.5 flex items-center gap-2">
          <Banknote class="w-4 h-4 text-emerald-600" />
          Verifikasi laporan penjualan dan nota fisik dari salesman.
        </p>
      </div>
      <div class="flex items-center gap-4">
        <Button @click="openAddModal" class="bg-primary hover:bg-primary/90 text-white rounded-2xl px-6 py-6 font-bold shadow-lg shadow-primary/20 flex items-center gap-2">
          <Plus class="w-5 h-5" /> Tambah Transaksi
        </Button>
        <div class="hidden md:block bg-emerald-50 px-4 py-2 rounded-2xl border border-emerald-100">
          <p class="text-[10px] font-bold text-emerald-600 uppercase tracking-wider">Total Hari Ini</p>
          <p class="text-lg font-black text-emerald-700">{{ formatCurrency(7550000) }}</p>
        </div>
      </div>
    </div>

    <!-- Filters -->
    <div class="bg-white p-4 rounded-3xl border border-slate-200 shadow-sm flex flex-col lg:flex-row gap-4 items-center">
      <div class="relative flex-1 w-full">
        <Search class="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
        <input 
          v-model="searchQuery"
          type="text" 
          placeholder="Cari No. Nota, Toko, atau Salesman..." 
          class="w-full pl-12 pr-4 py-3.5 bg-slate-50 border-none rounded-2xl focus:ring-2 focus:ring-primary/20 transition-all font-medium text-slate-900"
        />
      </div>
      <div class="flex gap-3 w-full lg:w-auto overflow-x-auto no-scrollbar pb-1 lg:pb-0">
        <button 
          v-for="status in ['ALL', 'PENDING', 'APPROVED', 'REJECTED']" 
          :key="status"
          @click="selectedStatus = status"
          class="px-5 py-3 rounded-2xl text-sm font-bold transition-all whitespace-nowrap"
          :class="[
            selectedStatus === status 
              ? 'bg-slate-900 text-white shadow-lg shadow-slate-200' 
              : 'bg-white border border-slate-200 text-slate-500 hover:bg-slate-50'
          ]"
        >
          {{ status }}
        </button>
      </div>
    </div>

    <!-- Sales Cards / List -->
    <div class="grid grid-cols-1 gap-6">
      <div 
        v-for="sale in filteredSales" 
        :key="sale.id"
        class="bg-white rounded-3xl border border-slate-200 shadow-sm hover:shadow-md transition-all overflow-hidden group"
      >
        <div class="flex flex-col lg:flex-row lg:items-stretch">
          <!-- Left Info -->
          <div class="p-8 flex-1">
            <div class="flex items-center justify-between mb-4">
              <span class="text-[11px] font-black bg-slate-100 text-slate-500 px-3 py-1 rounded-lg">{{ sale.id }}</span>
              <span :class="[
                'text-[11px] font-black px-3 py-1 rounded-lg',
                sale.status === 'PENDING' ? 'bg-amber-50 text-amber-600' :
                sale.status === 'APPROVED' ? 'bg-emerald-50 text-emerald-600' :
                'bg-red-50 text-red-600'
              ]">
                {{ sale.status }}
              </span>
            </div>
            
            <h3 class="text-xl font-extrabold text-slate-900 group-hover:text-primary transition-colors flex items-center gap-2">
              <Store class="w-5 h-5 text-slate-400" />
              {{ sale.store }}
            </h3>
            
            <div class="grid grid-cols-2 gap-4 mt-6">
              <div class="space-y-1">
                <p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Salesman</p>
                <p class="text-sm font-bold text-slate-700 flex items-center gap-2">
                  <User class="w-3.5 h-3.5" /> {{ sale.salesman }}
                </p>
              </div>
              <div class="space-y-1">
                <p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Waktu Input</p>
                <p class="text-sm font-bold text-slate-700 flex items-center gap-2">
                  <Clock class="w-3.5 h-3.5" /> {{ sale.date }}
                </p>
              </div>
            </div>

            <div class="mt-6 pt-6 border-t border-slate-100">
              <p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-2">Item Terjual</p>
              <div class="flex flex-wrap gap-2">
                <span v-for="item in sale.items" :key="item" class="text-[11px] font-bold text-slate-600 bg-slate-50 px-2 py-1 rounded-lg border border-slate-100">
                  {{ item }}
                </span>
              </div>
            </div>
          </div>

          <!-- Middle: Amount -->
          <div class="bg-slate-50/50 p-8 lg:w-64 flex flex-col justify-center items-center border-y lg:border-y-0 lg:border-x border-slate-100 text-center">
            <p class="text-[11px] font-black text-slate-400 uppercase tracking-widest mb-1">Nilai Transaksi</p>
            <h4 class="text-2xl font-black text-slate-900">{{ formatCurrency(sale.amount) }}</h4>
          </div>

          <!-- Right: Photo & Actions -->
          <div class="p-8 lg:w-80 flex flex-col justify-between gap-6">
            <div class="relative h-48 bg-slate-100 rounded-2xl overflow-hidden cursor-pointer group/img" @click="openImagePreview(sale.notaImage)">
              <img :src="sale.notaImage" class="w-full h-full object-cover transition-transform duration-500 group-hover/img:scale-110" />
              <div class="absolute inset-0 bg-slate-900/0 group-hover/img:bg-slate-900/20 transition-all flex items-center justify-center">
                <Maximize2 class="w-8 h-8 text-white opacity-0 group-hover/img:opacity-100 transition-all scale-50 group-hover/img:scale-100" />
              </div>
              <div class="absolute top-2 left-2 bg-white/90 backdrop-blur px-2 py-1 rounded-lg shadow-sm">
                <p class="text-[10px] font-black text-slate-900 flex items-center gap-1.5">
                  <ImageIcon class="w-3 h-3 text-primary" /> FOTO NOTA
                </p>
              </div>
            </div>

            <div v-if="sale.status === 'PENDING'" class="flex gap-3">
              <button 
                @click="handleApprove(sale.id)"
                class="flex-1 bg-emerald-600 hover:bg-emerald-700 text-white rounded-2xl py-3 text-xs font-black transition-all flex items-center justify-center gap-2 shadow-lg shadow-emerald-100"
              >
                <CheckCircle2 class="w-4 h-4" /> SETUJUI
              </button>
              <button 
                @click="handleReject(sale.id)"
                class="flex-1 bg-white border border-red-200 text-red-600 hover:bg-red-50 rounded-2xl py-3 text-xs font-black transition-all flex items-center justify-center gap-2"
              >
                <XCircle class="w-4 h-4" /> TOLAK
              </button>
            </div>
            <div v-else class="flex gap-3">
              <button 
                @click="handleEdit(sale)"
                class="flex-1 bg-slate-100 hover:bg-slate-200 text-slate-700 rounded-2xl py-3 text-xs font-black transition-all flex items-center justify-center gap-2"
              >
                <Pencil class="w-4 h-4" /> EDIT
              </button>
              <button 
                @click="handleDelete(sale.id)"
                class="flex-1 bg-red-50 hover:bg-red-100 text-red-600 rounded-2xl py-3 text-xs font-black transition-all flex items-center justify-center gap-2"
              >
                <Trash2 class="w-4 h-4" /> HAPUS
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- CRUD Modal -->
    <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="absolute inset-0 bg-slate-900/60 backdrop-blur-sm" @click="showModal = false"></div>
      <div class="bg-white rounded-[32px] w-full max-w-xl relative z-10 shadow-2xl flex flex-col max-h-[90vh] overflow-hidden animate-in fade-in zoom-in duration-300">
        <!-- Header -->
        <div class="px-6 py-5 border-b border-slate-100 flex items-center justify-between bg-white shrink-0">
          <div>
            <h3 class="text-xl font-black text-slate-900 tracking-tight">{{ isEditing ? 'Edit Transaksi' : 'Tambah Transaksi' }}</h3>
            <p class="text-[10px] font-black text-slate-400 uppercase tracking-widest mt-0.5">Laporan Penjualan</p>
          </div>
          <button @click="showModal = false" class="p-2 hover:bg-slate-100 rounded-xl transition-all text-slate-400 hover:text-slate-900">
            <X class="w-5 h-5" />
          </button>
        </div>
        
        <!-- Body (Scrollable) -->
        <div class="p-6 overflow-y-auto space-y-5 custom-scrollbar">
          <div class="space-y-2">
            <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Pilih Salesman</label>
            <select v-model="currentSale.employeeID" class="w-full bg-slate-50 border-2 border-transparent rounded-2xl px-5 py-3.5 font-bold text-slate-900 focus:bg-white focus:border-primary/20 focus:ring-0 transition-all appearance-none">
              <option value="" disabled>Pilih Salesman</option>
              <option v-for="s in salesmen" :key="s.id" :value="s.id">{{ s.first_name }} {{ s.last_name }}</option>
            </select>
          </div>

          <div class="space-y-2">
            <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Pilih Toko</label>
            <select v-model="currentSale.storeID" class="w-full bg-slate-50 border-2 border-transparent rounded-2xl px-5 py-3.5 font-bold text-slate-900 focus:bg-white focus:border-primary/20 focus:ring-0 transition-all appearance-none">
              <option value="">Pilih Toko (Opsional)</option>
              <option v-for="st in allStores" :key="st.id" :value="st.id">{{ st.name }} - {{ st.address }}</option>
            </select>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div class="space-y-2">
              <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Kategori Toko</label>
              <select v-model="currentSale.storeCategory" class="w-full bg-slate-50 border-2 border-transparent rounded-2xl px-5 py-3.5 font-bold text-slate-900 focus:bg-white focus:border-primary/20 focus:ring-0 transition-all appearance-none">
                <option value="TOKO_LAMA">Toko Lama</option>
                <option value="TOKO_BARU">Toko Baru</option>
              </select>
            </div>
            <div class="space-y-2">
              <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Total Omzet</label>
              <div class="relative">
                <span class="absolute left-5 top-1/2 -translate-y-1/2 font-black text-slate-400 text-sm">Rp</span>
                <input v-model.number="currentSale.totalAmount" type="number" placeholder="0" class="w-full bg-slate-50 border-2 border-transparent rounded-2xl pl-12 pr-5 py-3.5 font-black text-slate-900 focus:bg-white focus:border-primary/20 focus:ring-0 transition-all" />
              </div>
            </div>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div class="space-y-2">
              <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Status Transaksi</label>
              <select v-model="currentSale.status" class="w-full bg-slate-50 border-2 border-transparent rounded-2xl px-5 py-3.5 font-bold text-slate-900 focus:bg-white focus:border-primary/20 focus:ring-0 transition-all appearance-none">
                <option value="VERIFIED">Approved (Disetujui)</option>
                <option value="PENDING">Pending (Menunggu)</option>
                <option value="REJECTED">Rejected (Ditolak)</option>
              </select>
            </div>
            <div class="space-y-2">
              <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Tanggal</label>
              <input v-model="currentSale.transactionDate" type="date" class="w-full bg-slate-50 border-2 border-transparent rounded-2xl px-5 py-3.5 font-bold text-slate-900 focus:bg-white focus:border-primary/20 focus:ring-0 transition-all" />
            </div>
          </div>
          <div class="space-y-2">
            <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">No. Nota (Opsional)</label>
            <input v-model="currentSale.receiptNo" type="text" placeholder="INV-001" class="w-full bg-slate-50 border-2 border-transparent rounded-2xl px-5 py-3.5 font-bold text-slate-900 focus:bg-white focus:border-primary/20 focus:ring-0 transition-all" />
          </div>

          <div class="space-y-2">
            <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Upload Foto Nota (Opsional)</label>
            <div class="flex items-center gap-4">
              <input type="file" @change="handleFileUpload" accept="image/*" class="hidden" id="nota-upload" />
              <label for="nota-upload" class="flex-1 flex items-center justify-center gap-2 bg-slate-50 border-2 border-dashed border-slate-200 rounded-2xl py-4 cursor-pointer hover:border-primary/40 hover:bg-slate-100/50 transition-all">
                <ImageIcon class="w-5 h-5 text-slate-400" />
                <span class="text-xs font-bold text-slate-500">{{ currentSale.receiptImageURL ? 'Ganti Foto' : 'Pilih File Foto' }}</span>
              </label>
              <div v-if="currentSale.receiptImageURL" class="w-12 h-12 rounded-xl overflow-hidden border border-slate-100 shadow-sm">
                <img :src="currentSale.receiptImageURL" class="w-full h-full object-cover" />
              </div>
            </div>
          </div>
        </div>

        <!-- Footer -->
        <div class="p-6 border-t border-slate-100 flex gap-4 bg-white shrink-0">
          <button @click="showModal = false" class="flex-1 py-3.5 text-xs font-black text-slate-400 hover:text-slate-900 transition-all uppercase tracking-widest">
            BATAL
          </button>
          <button 
            @click="handleSubmit"
            class="flex-[2] bg-primary text-white rounded-2xl py-3.5 text-xs font-black shadow-lg shadow-primary/20 hover:scale-[1.02] active:scale-[0.98] transition-all flex items-center justify-center gap-2 uppercase tracking-widest"
          >
            <Save class="w-4 h-4" /> SIMPAN DATA
          </button>
        </div>
      </div>
    </div>

    <!-- Image Preview Modal -->
    <div v-if="showImageModal" class="fixed inset-0 z-[100] flex items-center justify-center p-4">
      <div class="absolute inset-0 bg-slate-900/90 backdrop-blur-md" @click="showImageModal = false"></div>
      
      <!-- Controls -->
      <div class="absolute top-6 right-6 flex items-center gap-3 z-[110]">
        <button @click="handleZoom(0.2)" class="p-3 bg-white/10 hover:bg-white/20 text-white rounded-2xl backdrop-blur-xl border border-white/10 transition-all">
          <ZoomIn class="w-6 h-6" />
        </button>
        <button @click="handleZoom(-0.2)" class="p-3 bg-white/10 hover:bg-white/20 text-white rounded-2xl backdrop-blur-xl border border-white/10 transition-all">
          <ZoomOut class="w-6 h-6" />
        </button>
        <button @click="zoomLevel = 1" class="p-3 bg-white/10 hover:bg-white/20 text-white rounded-2xl backdrop-blur-xl border border-white/10 transition-all">
          <RotateCcw class="w-6 h-6" />
        </button>
        <div class="w-px h-8 bg-white/10 mx-2"></div>
        <button @click="showImageModal = false" class="p-3 bg-white hover:bg-slate-100 text-slate-900 rounded-2xl transition-all">
          <X class="w-6 h-6" />
        </button>
      </div>

      <div class="relative z-[105] max-w-5xl max-h-[85vh] transition-transform duration-300 ease-out flex items-center justify-center overflow-hidden rounded-3xl shadow-2xl">
        <img 
          :src="previewImageUrl" 
          :style="`transform: scale(${zoomLevel})`"
          class="max-w-full max-h-full object-contain transition-transform duration-200 cursor-grab active:cursor-grabbing" 
        />
      </div>
    </div>
  </div>
</template>
