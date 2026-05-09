<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import apiClient from '@/api/axios'
import DeliveryManagement from './DeliveryManagement.vue'
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
  RotateCcw,
  Truck,
  Printer,
  ClipboardList,
  MapPin,
  RefreshCw,
  PackageOpen
} from 'lucide-vue-next'
import { useDeliveryStore } from '@/stores/delivery'
import { useMasterDataStore } from '@/stores/masterData'
import { useFactoryStore } from '@/stores/factory'
import { Badge } from '@/components/ui/badge'
import { Card, CardContent, CardFooter } from '@/components/ui/card/index'
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
const deliveryStore = useDeliveryStore()
const masterDataStore = useMasterDataStore()
const selectedDO = ref<any>(null)
const selectedNota = ref<any>(null)
const selectedQR = ref<string | null>(null)

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
  notes: '',
  items: [] as any[]
})

const factoryStore = useFactoryStore()

const waitingAdminDO = computed(() => {
  return deliveryStore.batches.filter((b: any) => b.status === 'SUPERVISOR_APPROVED')
})

const handleApproveBatch = async (id: string) => {
  try {
    await apiClient.post(`/delivery/batch/${id}/approve`)
    toast.success('Surat Jalan berhasil dibuat!')
    deliveryStore.fetchBatches()
    const approvedBatch = deliveryStore.batches.find((b: any) => b.id === id)
    if (approvedBatch) {
      selectedDO.value = approvedBatch
    }
  } catch (err: any) {
    toast.error('Gagal membuat Surat Jalan: ' + (err.response?.data?.error || err.message))
  }
}

const handlePrint = () => {
  window.print()
}

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

const fetchData = async () => {
  if (!masterDataStore.selectedBranchId) return
  isLoading.value = true
  const companyId = masterDataStore.selectedBranchCompanyId || ''
  try {
    await Promise.all([
      factoryStore.fetchProducts(),
      masterDataStore.fetchEmployees(),
      masterDataStore.fetchBranches()
    ])
    const res = await apiClient.get(`/admin/sales/transactions/all?company_id=${companyId}`)
    if (res.data?.data) {
      console.log('DEBUG SALES DATA:', res.data.data)
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
        items: trx.items?.map((i: any) => `${i.product?.name} (${i.quantity})`) || (trx.notes ? [trx.notes] : []),
        rawItems: trx.items || [],
        rawDate: trx.transaction_date,
        notaImage: trx.receipt_image_url || 'https://placehold.co/600x400/f1f5f9/64748b?text=Foto+Nota',
        deliveryOrders: trx.delivery_items?.map((di: any) => ({
          ...di.delivery_batch,
          id: di.delivery_batch?.id || di.delivery_batch_id,
          no: di.delivery_batch?.delivery_order_no,
          status: di.delivery_batch?.status,
          date: di.delivery_batch?.assigned_at
        })) || [],
        raw: trx
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
    notes: '',
    items: []
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
    receiptNo: sale.receiptNo,
    receiptImageURL: sale.notaImage === 'https://placehold.co/600x400/f1f5f9/64748b?text=Foto+Nota' ? '' : sale.notaImage,
    status: sale.status === 'APPROVED' ? 'VERIFIED' : sale.status,
    notes: sale.items && sale.items[0] && !sale.rawItems?.length ? sale.items[0] : '',
    items: sale.rawItems?.map((ri: any) => ({
      product_id: ri.product_id,
      quantity: ri.quantity,
      price: ri.price_at_transaction
    })) || []
  }
  showModal.value = true
}

const handleDelete = async (id: string) => {
  if (!confirm('Yakin ingin menghapus transaksi ini? Data KPI akan diperbarui otomatis.')) return
  
  try {
    await apiClient.delete(`/admin/sales/transactions/${id}`)
    toast.success('Transaksi berhasil dihapus')
    fetchData()
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
  if (!currentSale.value.employeeID) {
    toast.error('Silakan pilih salesman terlebih dahulu!')
    return
  }

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
      company_id: masterDataStore.selectedBranchCompanyId,
      items: currentSale.value.items.filter((i: any) => i.product_id)
    }

    if (isEditing.value) {
      await apiClient.put(`/admin/sales/transactions/${currentSale.value.id}`, payload)
      toast.success('Transaksi diperbarui')
    } else {
      await apiClient.post('/admin/sales/manual-entry', payload)
      toast.success('Transaksi baru ditambahkan')
    }
    showModal.value = false
    fetchData()
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
    fetchData() // Refresh
  } catch (error) {
    toast.error('Gagal menyetujui nota')
  }
}

const addItem = () => {
  currentSale.value.items.push({
    product_id: '',
    quantity: 1,
    price: 0
  })
}

const removeItem = (index: number) => {
  currentSale.value.items.splice(index, 1)
}

const updateItemPrice = (index: number) => {
  const item = currentSale.value.items[index]
  const product = factoryStore.products.find(p => p.id === item.product_id)
  if (product) {
    item.price = product.selling_price
  }
}

watch(() => currentSale.value.items, (newItems) => {
  if (!newItems) return
  const total = newItems.reduce((acc: number, item: any) => acc + (item.quantity * item.price), 0)
  currentSale.value.totalAmount = total
}, { deep: true })

const handleReject = async (id: string) => {
  if (!confirm('Apakah Anda yakin ingin menolak nota ini?')) return
  try {
    await apiClient.patch(`/sales/transactions/${id}/reject`, { notes: 'Ditolak oleh Admin' })
    toast.success('Nota berhasil ditolak')
    fetchData()
  } catch (err) {
    toast.error('Gagal menolak nota')
  }
}

const generateReceiptNo = async () => {
  try {
    const companyId = masterDataStore.selectedBranchCompanyId
    const date = currentSale.value.transactionDate
    const res = await apiClient.get(`/admin/sales/transactions/next-receipt-no?company_id=${companyId}&date=${date}`)
    if (res.data?.receipt_no) {
      currentSale.value.receiptNo = res.data.receipt_no
    }
  } catch (error) {
    toast.error('Gagal membuat nomor nota')
  }
}


onMounted(() => {
  fetchData()
  fetchSalesmen()
  fetchStores()
  deliveryStore.fetchBatches()
})

// Watch for branch changes
watch(() => masterDataStore.selectedBranchId, () => {
  fetchData()
  fetchSalesmen()
  fetchStores()
  deliveryStore.fetchBatches()
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

const batchProductColumns = computed(() => {
  if (!selectedDO.value || !selectedDO.value.items) return []
  const productMap = new Map()
  selectedDO.value.items.forEach((item: any) => {
    if (item.sales_transaction?.items) {
      item.sales_transaction.items.forEach((si: any) => {
        if (si.product) {
          productMap.set(si.product_id, {
            id: si.product_id,
            name: si.product.name.split(' ').map((w:string)=>w[0]).join('')
          })
        }
      })
    }
  })
  return Array.from(productMap.values())
})

const getProductQty = (trx: any, productId: string) => {
  if (!trx || !trx.items) return 0
  const item = trx.items.find((i: any) => i.product_id === productId)
  return item ? item.quantity : 0
}

const calculateBatchTotal = computed(() => {
  if (!selectedDO.value || !selectedDO.value.items) return 0
  return selectedDO.value.items.reduce((sum: number, item: any) => sum + (item.sales_transaction?.total_amount || 0), 0)
})

const calculateProductTotal = (productId: string) => {
  if (!selectedDO.value || !selectedDO.value.items) return 0
  return selectedDO.value.items.reduce((sum: number, item: any) => sum + getProductQty(item.sales_transaction, productId), 0)
}

const openSJPriority = async (batch: any) => {
  console.log('DEBUG: Opening SJ for batch:', batch)
  if (!batch.id) return
  isLoading.value = true
  try {
    const res = await apiClient.get(`/delivery/batch/${batch.id}`)
    if (res.data) {
      selectedDO.value = res.data
    }
  } catch (err) {
    toast.error('Gagal mengambil detail Surat Jalan')
  } finally {
    isLoading.value = false
  }
}
const openNotaPreview = (sale: any) => {
  // Find raw data to get all details including store and items
  const rawSale = salesData.value.find(s => s.id === sale.id)
  selectedNota.value = {
    ...sale,
    raw: rawSale?.raw || rawSale
  }
}

</script>

<template>
  <div class="space-y-12 pb-20">
    
    <!-- SECTION 1: Admin Nota (Log Batch & Verifikasi Penjualan) -->
    <div class="space-y-8">
      <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-6">
        <div>
          <h1 class="text-3xl font-extrabold text-slate-900 tracking-tight">Admin Nota: Verifikasi & Cetak SJ</h1>
          <p class="text-[15px] font-medium text-slate-500 mt-1.5 flex items-center gap-2">
            <Banknote class="w-4 h-4 text-emerald-600" />
            Cetak Surat Jalan dari batch Supervisor dan verifikasi nota baru.
          </p>
        </div>
        <div class="flex items-center gap-4">
          <Button @click="openAddModal" class="bg-primary hover:bg-primary/90 text-white rounded-2xl px-6 py-6 font-bold shadow-lg shadow-primary/20 flex items-center gap-2">
            <Plus class="w-5 h-5" /> Tambah Transaksi Manual
          </Button>
          <div class="hidden md:block bg-emerald-50 px-4 py-2 rounded-2xl border border-emerald-100">
            <p class="text-[10px] font-bold text-emerald-600 uppercase tracking-wider">Total Hari Ini</p>
            <p class="text-lg font-black text-emerald-700">{{ formatCurrency(7550000) }}</p>
          </div>
        </div>
      </div>

      <!-- Log Batch Disetujui (Admin Nota) - SIAP CETAK SJ -->
      <div class="bg-slate-50/50 border-2 border-dashed border-slate-200 rounded-[40px] p-8 space-y-6">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-3">
            <div class="bg-white p-2 rounded-xl shadow-sm">
              <ClipboardList class="w-5 h-5 text-primary" />
            </div>
            <div>
              <h3 class="text-sm font-black text-slate-900 uppercase tracking-widest">Log Batch Siap Cetak Surat Jalan</h3>
              <p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest mt-0.5">Approved by Supervisor</p>
            </div>
          </div>
          <Badge v-if="waitingAdminDO.length > 0" class="bg-emerald-600 text-white font-black px-3 py-1">{{ waitingAdminDO.length }} BATCH</Badge>
        </div>
        
        <div v-if="waitingAdminDO.length > 0" class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          <div v-for="batch in waitingAdminDO" :key="batch.id" class="bg-white rounded-3xl border border-emerald-100 p-6 flex flex-col justify-between shadow-sm hover:shadow-md transition-all">
            <div class="space-y-3">
              <div class="flex justify-between items-start">
                <span class="text-[9px] font-black bg-emerald-50 text-emerald-700 px-2 py-0.5 rounded-full uppercase tracking-widest">Siap Cetak</span>
                <span class="text-[10px] font-bold text-slate-400">{{ formatDate(batch.assigned_at) }}</span>
              </div>
              <div>
                <h4 class="text-base font-black text-slate-900 truncate">{{ batch.driver?.first_name }} • {{ batch.vehicle?.license_plate }}</h4>
                <p class="text-[11px] font-bold text-slate-500 uppercase tracking-widest mt-0.5">{{ batch.items?.length || 0 }} NOTA DALAM BATCH</p>
              </div>
            </div>
            <Button @click="handleApproveBatch(batch.id)" class="w-full bg-emerald-600 hover:bg-emerald-700 text-white rounded-2xl py-6 font-black text-xs shadow-lg shadow-emerald-100 flex items-center justify-center gap-2 mt-6">
              <Printer class="w-4 h-4" /> CETAK SURAT JALAN
            </Button>
          </div>
        </div>

        <div v-else class="py-10 text-center">
          <div class="bg-white w-12 h-12 rounded-2xl shadow-sm flex items-center justify-center mx-auto mb-4">
            <RefreshCw class="w-6 h-6 text-slate-200 animate-spin-slow" />
          </div>
          <p class="text-[11px] font-black text-slate-400 uppercase tracking-widest">Belum ada batch yang difinalisasi oleh Supervisor</p>
          <p class="text-[10px] font-bold text-slate-300 mt-1 italic">Data akan muncul otomatis setelah Supervisor menyetujui batch pengiriman</p>
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
              <div class="flex items-center gap-3">
                <img v-if="sale.receiptNo" :src="`https://api.qrserver.com/v1/create-qr-code/?size=60x60&data=${sale.receiptNo}`" class="w-8 h-8 rounded border border-slate-200 shadow-sm" />
                <div class="flex flex-col">
                  <span class="text-[10px] font-black text-slate-400 uppercase tracking-widest cursor-pointer hover:text-primary transition-colors flex items-center gap-1.5" @click="selectedQR = sale.receiptNo">
                    {{ sale.receiptNo || 'NO RECEIPT' }}
                    <Maximize2 class="w-3 h-3 opacity-40" />
                  </span>
                  <span class="text-[11px] font-bold text-slate-500">{{ sale.id.split('-')[0] }}...</span>
                </div>
              </div>
              <div class="flex flex-col items-end gap-2">
                <span :class="[
                  'text-[11px] font-black px-3 py-1 rounded-lg',
                  sale.status === 'PENDING' ? 'bg-amber-50 text-amber-600' :
                  sale.status === 'APPROVED' ? 'bg-emerald-50 text-emerald-600' :
                  'bg-red-50 text-red-600'
                ]">
                  {{ sale.status }}
                </span>
              </div>
            </div>
            
            <h3 class="text-xl font-extrabold text-slate-900 group-hover:text-primary transition-colors flex items-center gap-2">
              <Store class="w-5 h-5 text-slate-400" />
              {{ sale.store }}
            </h3>
            
            <div class="grid grid-cols-2 gap-4 mt-6">
              <div class="space-y-1">
                <p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Salesman</p>
                <div class="flex flex-col">
                  <p class="text-sm font-bold text-slate-700 flex items-center gap-2">
                    <User class="w-3.5 h-3.5" /> {{ sale.salesman }}
                  </p>
                  <p class="text-[10px] font-medium text-slate-500 mt-0.5 ml-5">
                    {{ sale.raw?.employee?.job_position?.title || 'Sales' }} • 
                    {{ sale.raw?.employee?.company?.name || '-' }}
                  </p>
                </div>
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

              <div v-if="sale.deliveryOrders.length > 0" class="mt-6 pt-6 border-t border-dashed border-slate-100">
                <p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-3">Riwayat Logistik / Surat Jalan</p>
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <div 
                    v-for="doItem in sale.deliveryOrders" 
                    :key="doItem.no" 
                    @click="openSJPriority(doItem)"
                    class="flex items-center justify-between bg-slate-900 text-white p-3 rounded-2xl shadow-sm cursor-pointer hover:bg-slate-800 transition-all group/sj"
                  >
                    <div class="flex items-center gap-3">
                      <div class="bg-white/10 p-2 rounded-xl group-hover/sj:bg-primary transition-colors">
                        <Truck class="w-4 h-4 text-white" />
                      </div>
                      <div>
                        <p class="text-[10px] font-black text-white/50 uppercase tracking-widest leading-none">Nomor SJ</p>
                        <p class="text-xs font-black mt-1">{{ doItem.no || 'DALAM PROSES' }}</p>
                      </div>
                    </div>
                    <div class="flex items-center gap-2">
                       <p class="text-[9px] font-black px-2 py-1 bg-white/10 rounded-lg uppercase tracking-wider">{{ doItem.status }}</p>
                       <Printer class="w-3.5 h-3.5 text-white/40 group-hover/sj:text-white transition-colors" />
                    </div>
                  </div>
                </div>
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

            <div class="space-y-3">
               <!-- Status Based Actions -->
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
               <div v-else-if="sale.status === 'APPROVED'" class="bg-emerald-50 text-emerald-700 rounded-2xl py-3 px-4 text-xs font-black flex items-center justify-center gap-2 border border-emerald-100">
                 <CheckCircle2 class="w-4 h-4" /> SIAP DIKIRIM (MENUNGGU BATCH)
               </div>
               <div v-else-if="sale.status === 'REJECTED'" class="bg-red-50 text-red-700 rounded-2xl py-3 px-4 text-xs font-black flex items-center justify-center gap-2 border border-red-100">
                 <XCircle class="w-4 h-4" /> TRANSAKSI DITOLAK
               </div>

                <!-- Admin General Actions -->
                <div class="flex flex-wrap gap-3">
                  <button 
                    @click="openNotaPreview(sale)"
                    class="flex-1 bg-primary/10 hover:bg-primary/20 text-primary rounded-2xl py-3 text-xs font-black transition-all flex items-center justify-center gap-2 border border-primary/10"
                  >
                    <Printer class="w-4 h-4" /> CETAK NOTA
                  </button>
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

          <!-- Items Table -->
          <div class="space-y-4">
            <div class="flex items-center justify-between">
              <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Rincian Produk</label>
              <button @click="addItem" class="text-[10px] font-black text-primary flex items-center gap-1 hover:underline">
                <Plus class="w-3 h-3" /> TAMBAH PRODUK
              </button>
            </div>
            
            <div v-if="currentSale.items?.length > 0" class="space-y-3">
              <div v-for="(item, index) in currentSale.items" :key="index" class="grid grid-cols-12 gap-3 items-center bg-slate-50 p-3 rounded-2xl border border-slate-100">
                <div class="col-span-5">
                  <select v-model="item.product_id" @change="updateItemPrice(index)" class="w-full bg-white border-0 rounded-xl px-3 py-2 text-xs font-bold text-slate-900 focus:ring-2 focus:ring-primary/20 transition-all">
                    <option value="" disabled>Pilih Produk</option>
                    <option v-for="p in factoryStore.products" :key="p.id" :value="p.id">{{ p.name }}</option>
                  </select>
                </div>
                <div class="col-span-2">
                  <input v-model.number="item.quantity" type="number" placeholder="Qty" class="w-full bg-white border-0 rounded-xl px-3 py-2 text-xs font-bold text-slate-900 focus:ring-2 focus:ring-primary/20 transition-all" />
                </div>
                <div class="col-span-4">
                   <div class="relative">
                     <span class="absolute left-2 top-1/2 -translate-y-1/2 text-[10px] font-bold text-slate-400">Rp</span>
                     <input v-model.number="item.price" type="number" placeholder="Harga" class="w-full bg-white border-0 rounded-xl pl-7 pr-3 py-2 text-xs font-bold text-slate-900 focus:ring-2 focus:ring-primary/20 transition-all" />
                   </div>
                </div>
                <div class="col-span-1 flex justify-center">
                  <button @click="removeItem(index)" class="text-red-400 hover:text-red-600">
                    <Trash2 class="w-4 h-4" />
                  </button>
                </div>
              </div>
            </div>
            <div v-else class="text-center py-6 border-2 border-dashed border-slate-100 rounded-2xl">
              <p class="text-[10px] font-bold text-slate-300 uppercase tracking-widest italic">Belum ada item ditambahkan</p>
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
            <div class="flex gap-2">
              <input v-model="currentSale.receiptNo" type="text" placeholder="INV/YYYYMMDD/SEQ" class="flex-1 bg-slate-50 border-2 border-transparent rounded-2xl px-5 py-3.5 font-bold text-slate-900 focus:bg-white focus:border-primary/20 focus:ring-0 transition-all" />
              <button @click="generateReceiptNo" type="button" class="bg-slate-900 text-white px-4 rounded-2xl text-[10px] font-black uppercase tracking-widest hover:bg-slate-800 transition-all shrink-0">GENERATE</button>
            </div>
          </div>

          <div class="space-y-2">
            <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Foto Nota (Opsional - Digital First)</label>
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

    <!-- DO Printing Modal (SJ Preview) - LANDSCAPE VERSION -->
    <div v-if="selectedDO" class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-[200] flex items-start justify-center p-0 sm:p-8 overflow-y-auto print:p-0">
       <Card id="surat-jalan-card" class="w-full max-w-[297mm] bg-white shadow-2xl border-0 sm:rounded-[24px] print:rounded-none my-auto">
          <!-- Compact Landscape Header -->
          <div class="bg-white p-4 print:p-2">
             <div class="grid grid-cols-3 gap-8 items-center">
               <div class="space-y-1">
                 <p class="text-[9px] font-black text-slate-900 uppercase tracking-widest">SOPIR / ARMADA</p>
                 <p class="text-[11px] font-black text-slate-900">
                   {{ selectedDO.driver?.first_name || '........................' }} / {{ selectedDO.vehicle?.license_plate || '..........' }}
                 </p>
               </div>
               <div class="space-y-1">
                  <p class="text-[9px] font-black text-slate-900 uppercase tracking-widest">SALESMAN / HELPER</p>
                  <p class="text-[11px] font-black text-slate-900 leading-tight">
                    {{ selectedDO.items?.[0]?.sales_transaction?.employee?.first_name || '........................' }}
                  </p>
                  <p class="text-[8px] font-bold text-slate-500 uppercase tracking-tighter">
                    {{ selectedDO.items?.[0]?.sales_transaction?.employee?.job_position?.title || '.....' }} • 
                    {{ selectedDO.items?.[0]?.sales_transaction?.employee?.company?.name || '.....' }}
                  </p>
                </div>
               <div class="text-right">
                 <p class="text-[10px] font-mono font-bold text-slate-900 pb-1 italic uppercase tracking-tighter">SURAT JALAN #{{ selectedDO.delivery_order_no }}</p>
                 <p class="text-[9px] font-bold text-slate-900 mt-1 uppercase">{{ new Date(selectedDO.created_at).toLocaleDateString('id-ID', { dateStyle: 'long' }) }}</p>
               </div>
             </div>
          </div>
          
          <div class="p-4 sm:p-6 space-y-4 print:p-2">
             <!-- Main Table with Placeholders -->
             <div class="border-2 border-slate-900 rounded-lg overflow-x-auto bg-white">
               <table class="w-full text-left text-[10px] border-collapse whitespace-nowrap">
                 <thead>
                   <tr class="bg-slate-50 border-b-2 border-slate-900">
                     <th class="p-2 border-r border-slate-300 font-black text-center w-8">NO</th>
                     <th class="p-2 border-r border-slate-300 font-black">NAMA TOKO / TELP / ALAMAT</th>
                     <th class="p-2 border-r border-slate-300 font-black text-right w-20 bg-amber-50">TAGIHAN</th>
                     
                     <th class="p-1 border-r border-slate-300 font-black text-center w-8 bg-slate-100/50">GLN</th>
                     <th class="p-1 border-r border-slate-300 font-black text-center w-8 bg-slate-100/50">BTL</th>
                     <th class="p-1 border-r border-slate-300 font-black text-center w-8 bg-slate-100/50">KRT</th>
                     <th class="p-2 border-r border-slate-300 font-black text-center w-24 bg-emerald-50">BAYAR</th>
                     <th class="p-2 border-r border-slate-300 font-black text-center w-16">KET</th>

                     <th v-for="prod in batchProductColumns" :key="prod.id" class="p-1 border-r border-slate-300 font-black text-center text-[7px] bg-slate-100/30 w-10 uppercase">
                       {{ prod.name }}
                     </th>

                     <th class="p-2 border-r border-slate-300 font-black text-center w-10 bg-pink-50 text-[8px]">HADIAH</th>
                     <th class="p-2 font-black text-center w-10 text-[8px]">RETUR</th>
                   </tr>
                 </thead>
                 <tbody class="divide-y border-slate-300">
                   <tr v-for="(item, idx) in selectedDO.items" :key="item.id" class="h-8">
                     <td class="p-2 border-r border-slate-300 text-center font-bold">{{ (idx as number) + 1 }}</td>
                     <td class="p-2 border-r border-slate-300 whitespace-normal">
                       <p class="font-black text-slate-900 leading-none">
                         {{ item.sales_transaction?.store?.name }} 
                         <span class="text-[8px] text-slate-900 font-normal">/ {{ item.sales_transaction?.store?.phone || '-' }}</span>
                       </p>
                       <p class="text-[7px] text-slate-900 font-bold mt-0.5">{{ item.sales_transaction?.store?.address }}</p>
                     </td>
                     <td class="p-2 border-r border-slate-300 text-right font-black bg-amber-50/20">{{ formatCurrency(item.sales_transaction?.total_amount).replace('Rp', '').trim() }}</td>
                     <td class="p-2 border-r border-slate-300"></td>
                     <td class="p-2 border-r border-slate-300"></td>
                     <td class="p-2 border-r border-slate-300"></td>
                     <td class="p-2 border-r border-slate-300 bg-emerald-50/10"></td>
                     <td class="p-2 border-r border-slate-300 text-center font-bold text-[8px]">{{ item.sales_transaction?.payment_method || 'COD' }}</td>
                     <td v-for="prod in batchProductColumns" :key="prod.id" class="p-1 border-r border-slate-300 text-center font-black">
                       {{ getProductQty(item.sales_transaction, prod.id) || '' }}
                     </td>
                     <td class="p-2 border-r border-slate-300"></td>
                     <td class="p-2"></td>
                   </tr>

                   <!-- Placeholder Rows -->
                   <tr v-for="n in Math.max(0, 20 - (selectedDO.items?.length || 0))" :key="'blank-'+n" class="h-6 bg-slate-50/10">
                     <td class="p-2 border-r border-slate-300 text-center text-slate-900">{{ (selectedDO.items?.length || 0) + n }}</td>
                     <td class="p-2 border-r border-slate-300"></td>
                     <td class="p-2 border-r border-slate-300 bg-amber-50/10"></td>
                     <td class="p-2 border-r border-slate-300"></td>
                     <td class="p-2 border-r border-slate-300"></td>
                     <td class="p-2 border-r border-slate-300"></td>
                     <td class="p-2 border-r border-slate-300 bg-emerald-50/5"></td>
                     <td class="p-2 border-r border-slate-300"></td>
                     <td v-for="prod in batchProductColumns" :key="prod.id" class="p-1 border-r border-slate-300"></td>
                     <td class="p-2 border-r border-slate-300"></td>
                     <td class="p-2"></td>
                   </tr>

                   <!-- Total Row -->
                   <tr class="bg-slate-50 font-black border-t-2 border-slate-900 h-8">
                     <td colspan="2" class="p-2 text-right border-r border-slate-300 uppercase tracking-widest text-[8px]">TOTAL BATCH</td>
                     <td class="p-2 text-right border-r border-slate-300 bg-amber-50">{{ formatCurrency(calculateBatchTotal).replace('Rp', '').trim() }}</td>
                     <td colspan="4" class="border-r border-slate-300"></td>
                     <td class="border-r border-slate-300"></td>
                     <td v-for="prod in batchProductColumns" :key="prod.id" class="p-1 border-r border-slate-300 text-center text-primary bg-slate-100/30">
                        {{ calculateProductTotal(prod.id) }}
                     </td>
                     <td colspan="2"></td>
                   </tr>
                 </tbody>
               </table>
             </div>

             <!-- Signatures -->
             <div class="grid grid-cols-3 gap-8 mt-6">
               <div class="text-center space-y-8">
                 <p class="text-[9px] font-black uppercase tracking-widest">SOPIR / HELPER</p>
                 <p class="text-[8px] font-bold text-slate-900">( .................................. )</p>
               </div>
               <div class="text-center space-y-8">
                 <p class="text-[9px] font-black uppercase tracking-widest">ADMIN NOTA</p>
                 <p class="text-[8px] font-bold text-slate-900">( {{ selectedDO.admin_nota?.first_name || '........................' }} )</p>
               </div>
               <div class="flex justify-end items-center pr-10">
                  <div class="text-right mr-4">
                     <p class="text-[8px] font-black text-slate-400 uppercase leading-none">SCAN VALIDASI</p>
                     <p class="text-[7px] text-slate-300 italic mt-1 uppercase text-slate-400">SJ DIGITAL</p>
                  </div>
                  <img :src="`https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=${selectedDO.delivery_order_no}`" class="w-20 h-20 border-2 border-slate-900 p-1 rounded bg-white shadow-sm" />
               </div>
             </div>
          </div>

          <CardFooter class="p-6 bg-slate-50 border-t flex justify-end gap-3 print:hidden">
             <Button variant="ghost" class="font-bold text-slate-500" @click="selectedDO = null">TUTUP PREVIEW</Button>
             <Button class="bg-slate-900 hover:bg-slate-800 text-white font-black px-12 py-6 rounded-2xl shadow-xl shadow-slate-200" @click="handlePrint">
               <Printer class="w-5 h-5 mr-3" />
               CETAK SURAT JALAN
             </Button>
          </CardFooter>
       </Card>
    </div>

    <!-- Nota Printing Modal (Individual Receipt) -->
    <div v-if="selectedNota" class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-[200] flex items-start justify-center p-0 sm:p-8 overflow-y-auto print:p-0">
      <Card id="nota-penjualan-card" class="w-full max-w-[210mm] bg-white shadow-2xl border-0 sm:rounded-[24px] print:rounded-none my-auto">
        <div class="p-8 print:p-4">
          <!-- Header -->
          <div class="flex justify-between items-start border-b-2 border-slate-900 pb-6 mb-6">
            <div class="flex items-center gap-4">
              <div class="bg-primary p-3 rounded-2xl">
                <Store class="w-8 h-8 text-white" />
              </div>
              <div>
                <h2 class="text-2xl font-black text-slate-900 tracking-tighter uppercase italic">WOWIN FOOD</h2>
                <p class="text-[10px] font-bold text-slate-500 uppercase tracking-widest leading-tight">
                  CV. WOWIN FOOD • CABANG {{ masterDataStore.branches.find(b => b.id === masterDataStore.selectedBranchId)?.name || 'UTAMA' }}
                </p>
              </div>
            </div>
            <div class="text-right">
              <h3 class="text-xl font-black text-slate-900 italic tracking-tighter">NOTA PENJUALAN</h3>
              <p class="text-xs font-black text-slate-400 mt-1">#{{ selectedNota.receiptNo || selectedNota.id.slice(0, 8).toUpperCase() }}</p>
            </div>
          </div>

          <!-- Transaction Info -->
          <div class="grid grid-cols-2 gap-8 mb-8">
            <div class="space-y-4">
              <div>
                <p class="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1">PELANGGAN / TOKO</p>
                <p class="text-sm font-black text-slate-900 uppercase">{{ selectedNota.store }}</p>
                <p class="text-[11px] font-bold text-slate-500 mt-0.5">{{ selectedNota.raw?.store?.address || '-' }}</p>
              </div>
              <div>
                <p class="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1">SALESMAN</p>
                <p class="text-sm font-black text-slate-900 uppercase">{{ selectedNota.salesman }}</p>
                <p class="text-[10px] font-bold text-slate-500 mt-0.5">
                  {{ selectedNota.raw?.employee?.job_position?.title || 'SALES' }} • 
                  {{ selectedNota.raw?.employee?.company?.name || '-' }}
                </p>
              </div>
            </div>
            <div class="space-y-4 text-right">
              <div>
                <p class="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1">TANGGAL TRANSAKSI</p>
                <p class="text-sm font-black text-slate-900">{{ formatDate(selectedNota.rawDate) }}</p>
              </div>
              <div>
                <p class="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1">METODE PEMBAYARAN</p>
                <p class="text-sm font-black text-slate-900 uppercase">{{ selectedNota.raw?.payment_method || 'CASH' }}</p>
              </div>
              <!-- Midtrans Info -->
              <div v-if="selectedNota.raw?.midtrans_qris_url" class="flex flex-col items-end">
                <p class="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1">SCAN QRIS</p>
                <img :src="`https://api.qrserver.com/v1/create-qr-code/?size=100x100&data=${selectedNota.raw.midtrans_qris_url}`" class="w-24 h-24 border border-slate-200 p-1 rounded" />
              </div>
              <div v-if="selectedNota.raw?.midtrans_va_number || selectedNota.raw?.midtrans_bill_key" class="text-right">
                <p class="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1">
                  {{ selectedNota.raw?.midtrans_bank?.toUpperCase() }} VA
                </p>
                <p class="text-base font-black text-primary tracking-wider">
                  {{ selectedNota.raw?.midtrans_va_number || selectedNota.raw?.midtrans_bill_key }}
                </p>
                <p v-if="selectedNota.raw?.midtrans_biller_code" class="text-[10px] font-bold text-slate-500">
                  Biller: {{ selectedNota.raw?.midtrans_biller_code }}
                </p>
              </div>
            </div>
          </div>

          <!-- Items Table -->
          <div class="border-2 border-slate-900 rounded-xl overflow-hidden mb-8">
            <table class="w-full text-left text-xs border-collapse">
              <thead>
                <tr class="bg-slate-50 border-b-2 border-slate-900">
                  <th class="p-3 font-black text-center w-12 border-r border-slate-300">NO</th>
                  <th class="p-3 font-black border-r border-slate-300">NAMA PRODUK</th>
                  <th class="p-3 font-black text-center w-20 border-r border-slate-300">QTY</th>
                  <th class="p-3 font-black text-right w-32 border-r border-slate-300">HARGA</th>
                  <th class="p-3 font-black text-right w-32 bg-slate-100/50">SUBTOTAL</th>
                </tr>
              </thead>
              <tbody class="divide-y border-slate-300">
                <tr v-for="(item, idx) in selectedNota.raw?.items" :key="item.id" class="h-10">
                  <td class="p-3 text-center font-bold border-r border-slate-300">{{ (idx as number) + 1 }}</td>
                  <td class="p-3 font-bold text-slate-900 border-r border-slate-300 uppercase">{{ item.product?.name }}</td>
                  <td class="p-3 text-center font-bold border-r border-slate-300">{{ item.quantity }}</td>
                  <td class="p-3 text-right font-bold border-r border-slate-300">{{ formatCurrency(item.price_at_transaction).replace('Rp', '').trim() }}</td>
                  <td class="p-3 text-right font-black bg-slate-50/50">{{ formatCurrency(item.subtotal).replace('Rp', '').trim() }}</td>
                </tr>
                <!-- Padding Rows if few items -->
                <tr v-for="n in Math.max(0, 5 - (selectedNota.raw?.items?.length || 0))" :key="'blank-'+n" class="h-10">
                  <td class="p-3 border-r border-slate-300"></td>
                  <td class="p-3 border-r border-slate-300"></td>
                  <td class="p-3 border-r border-slate-300"></td>
                  <td class="p-3 border-r border-slate-300"></td>
                  <td class="p-3 bg-slate-50/20"></td>
                </tr>
              </tbody>
              <tfoot>
                <tr class="bg-slate-900 text-white font-black">
                  <td colspan="4" class="p-4 text-right uppercase tracking-widest text-[10px]">TOTAL TAGIHAN</td>
                  <td class="p-4 text-right text-base">{{ formatCurrency(selectedNota.amount) }}</td>
                </tr>
              </tfoot>
            </table>
          </div>

          <!-- Footer/Signatures -->
          <div class="grid grid-cols-3 gap-8 mt-12">
            <div class="text-center space-y-12">
              <p class="text-[10px] font-black uppercase tracking-widest">PELANGGAN</p>
              <div class="border-b border-slate-400 w-32 mx-auto"></div>
            </div>
            <div class="text-center space-y-12">
              <p class="text-[10px] font-black uppercase tracking-widest">SALESMAN</p>
              <p class="text-xs font-black uppercase">( {{ selectedNota.salesman }} )</p>
            </div>
            <div class="flex justify-end items-center pr-4">
              <div class="text-right mr-4">
                <p class="text-[9px] font-black text-slate-400 uppercase leading-none">VALIDASI NOTA</p>
                <p class="text-[7px] text-slate-300 italic mt-1 uppercase">DIGITAL RECORD</p>
              </div>
              <img :src="`https://api.qrserver.com/v1/create-qr-code/?size=100x100&data=${selectedNota.receiptNo || selectedNota.id}`" class="w-16 h-16 border-2 border-slate-900 p-1 rounded bg-white shadow-sm" />
            </div>
          </div>

          <div class="mt-8 pt-6 border-t border-dashed border-slate-200">
            <p class="text-[9px] text-slate-400 italic text-center">
              Nota ini dihasilkan secara otomatis oleh Sistem HRIS & Penjualan Wowin Food. 
              Dokumen digital ini sah dan valid untuk keperluan audit internal.
            </p>
          </div>
        </div>

        <CardFooter class="p-6 bg-slate-50 border-t flex justify-end gap-3 print:hidden">
          <Button variant="ghost" class="font-bold text-slate-500" @click="selectedNota = null">BATAL</Button>
          <Button class="bg-slate-900 hover:bg-slate-800 text-white font-black px-12 py-6 rounded-2xl shadow-xl shadow-slate-200" @click="handlePrint">
            <Printer class="w-5 h-5 mr-3" />
            CETAK NOTA
          </Button>
        </CardFooter>
      </Card>
    </div>

    <!-- Receipt QR Modal -->
    <div v-if="selectedQR" class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-[250] flex items-center justify-center p-6" @click="selectedQR = null">
       <Card class="w-full max-w-sm bg-white shadow-2xl rounded-[32px] overflow-hidden" @click.stop>
          <div class="p-8 text-center space-y-6">
             <div>
               <h3 class="text-lg font-black text-slate-900 uppercase tracking-tighter italic">Scan QR Nota</h3>
               <p class="text-xs font-bold text-slate-400 mt-1 uppercase tracking-widest">{{ selectedQR }}</p>
             </div>
             
             <div class="bg-slate-50 p-6 rounded-3xl border-2 border-slate-100 flex items-center justify-center">
                <img :src="`https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${selectedQR}`" class="w-64 h-64 shadow-sm" />
             </div>

             <Button class="w-full bg-slate-900 hover:bg-slate-800 text-white rounded-2xl py-6 font-black" @click="selectedQR = null">
               TUTUP
             </Button>
          </div>
       </Card>
    </div>
  </div>
</template>

<style scoped>
@media print {
  @page {
    size: landscape;
    margin: 0;
  }
  html, body {
    height: 100vh !important;
    margin: 0 !important;
    padding: 0 !important;
    overflow: hidden !important;
    background: white !important;
  }
  body * {
    visibility: hidden;
  }
  .fixed.inset-0,
  .fixed.inset-0 *,
  #surat-jalan-card,
  #surat-jalan-card *,
  #nota-penjualan-card,
  #nota-penjualan-card * {
    visibility: visible;
  }
  .fixed.inset-0 {
    position: absolute !important;
    top: 0 !important;
    left: 0 !important;
    width: 100% !important;
    height: 100vh !important;
    background: white !important;
    padding: 0 !important;
    overflow: hidden !important;
    display: block !important;
    z-index: 9999 !important;
  }
  #surat-jalan-card, #nota-penjualan-card {
    position: static !important;
    margin: 0 auto !important;
    width: 100% !important;
    border: none !important;
    box-shadow: none !important;
    transform: none !important;
    page-break-after: avoid !important;
    break-after: avoid !important;
  }
  #surat-jalan-card {
    zoom: 0.80;
    -moz-transform: scale(0.80);
    -moz-transform-origin: top left;
    transform: scale(0.80);
    transform-origin: top left;
  }
  #nota-penjualan-card {
    max-width: 210mm !important;
    padding: 20px !important;
  }
  #surat-jalan-card .p-4, #nota-penjualan-card .p-8 {
    padding: 2px 4px !important;
  }
  #surat-jalan-card table, #nota-penjualan-card table {
    font-size: 7.5pt !important;
    border-collapse: collapse !important;
    width: 100% !important;
    line-height: 1.0 !important;
  }
  #surat-jalan-card th, #surat-jalan-card td,
  #nota-penjualan-card th, #nota-penjualan-card td {
    padding: 1.5px !important;
    border: 1px solid #000 !important;
    visibility: visible !important;
  }
  .print\:hidden {
    display: none !important;
  }
  #surat-jalan-card div, #nota-penjualan-card div {
    max-height: none !important;
    overflow: visible !important;
    margin: 0 !important;
  }
}
</style>

