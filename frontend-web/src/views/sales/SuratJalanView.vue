<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useDeliveryStore } from '@/stores/delivery'
import { toast } from 'vue-sonner'
import { 
  FileText, Search, Truck, CheckCircle2, 
  Calendar, User, Car, ArrowRight, Eye,
  Clock, Package, MapPin, X
} from 'lucide-vue-next'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Card, CardFooter } from '@/components/ui/card/index'
import DataTable from '@/components/DataTable.vue'
import { Printer } from 'lucide-vue-next'

const formatDate = (date: string) => {
  if (!date) return '—'
  try {
    return new Intl.DateTimeFormat('id-ID', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    }).format(new Date(date))
  } catch (e) {
    return date
  }
}

const deliveryStore = useDeliveryStore()
const searchQuery = ref('')
const selectedStatus = ref('ALL')
const showDetailModal = ref(false)
const selectedBatch = ref<any>(null)
const selectedDO = ref<any>(null)
const isSubmitting = ref(false)
const zoomedQR = ref<string | null>(null)

const fetchData = async () => {
  try {
    await deliveryStore.fetchBatches()
  } catch (err) {
    toast.error('Gagal mengambil data surat jalan')
  }
}

onMounted(fetchData)

const filteredBatches = computed(() => {
  return deliveryStore.batches.filter(b => {
    const q = searchQuery.value.toLowerCase()
    const matchesSearch = !q || 
      b.delivery_order_no?.toLowerCase().includes(q) || 
      b.driver?.first_name?.toLowerCase().includes(q) ||
      b.driver?.last_name?.toLowerCase().includes(q)
    
    const matchesStatus = selectedStatus.value === 'ALL' || b.status === selectedStatus.value
    
    return matchesSearch && matchesStatus
  }).sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
})

// Computed for Product Matrix in SJ
const batchProductColumns = computed(() => {
  if (!selectedDO.value || !selectedDO.value.items) return []
  
  const productMap = new Map()
  selectedDO.value.items.forEach((item: any) => {
    const trx = item.sales_order || item.sales_transaction
    if (trx?.items) {
      trx.items.forEach((si: any) => {
        if (si.product) {
          productMap.set(si.product_id, {
            id: si.product_id,
            name: si.product.name.split(' ').map((w: string) => w[0]).join('') // Abbreviate
          })
        }
      })
    }
  })
  return Array.from(productMap.values())
})

const getProductQty = (item: any, productId: string) => {
  const trx = item.sales_order || item.sales_transaction
  if (!trx || !trx.items) return 0
  const si = trx.items.find((i: any) => i.product_id === productId)
  return si ? si.quantity : 0
}

const calculateBatchTotal = computed(() => {
  if (!selectedDO.value || !selectedDO.value.items) return 0
  return selectedDO.value.items.reduce((sum: number, item: any) => {
    const trx = item.sales_order || item.sales_transaction
    return sum + (trx?.total_amount || 0)
  }, 0)
})

const calculateProductTotal = (productId: string) => {
  if (!selectedDO.value || !selectedDO.value.items) return 0
  return selectedDO.value.items.reduce((sum: number, item: any) => {
    return sum + getProductQty(item, productId)
  }, 0)
}

const formatCurrency = (val: number) => {
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(val)
}

const handlePrint = () => {
  window.print()
}

const openPrintPreview = (batch: any) => {
  selectedDO.value = batch
}

const getStatusColor = (status: string) => {
  const map: Record<string, string> = {
    'WAITING_APPROVAL': 'bg-yellow-100 text-yellow-700 border-yellow-200',
    'SUPERVISOR_APPROVED': 'bg-blue-100 text-blue-700 border-blue-200',
    'PENDING': 'bg-indigo-100 text-indigo-700 border-indigo-200',
    'PICKING': 'bg-orange-100 text-orange-700 border-orange-200',
    'ON_DELIVERY': 'bg-slate-800 text-white border-slate-900',
    'COMPLETED': 'bg-emerald-100 text-emerald-700 border-emerald-200'
  }
  return map[status] || 'bg-slate-100 text-slate-700'
}

const getStatusLabel = (status: string) => {
  const map: Record<string, string> = {
    'WAITING_APPROVAL': 'MENUNGGU PERSETUJUAN',
    'SUPERVISOR_APPROVED': 'DISETUJUI SUPERVISOR',
    'PENDING': 'DIPROSES ADMIN',
    'PICKING': 'PENGAMBILAN BARANG',
    'ON_DELIVERY': 'DALAM PENGIRIMAN',
    'COMPLETED': 'SELESAI'
  }
  return map[status] || status
}


const openDetail = (batch: any) => {
  selectedBatch.value = batch
  showDetailModal.value = true
}

const columns = [
  { key: 'delivery_order_no', label: 'NO SURAT JALAN' },
  { key: 'driver', label: 'DRIVER & ARMADA' },
  { key: 'items_count', label: 'TOTAL NOTA' },
  { key: 'created_at', label: 'TANGGAL TERBIT' },
  { key: 'status', label: 'STATUS' },
  { key: 'actions', label: 'AKSI' }
]
</script>

<template>
  <div class="space-y-8 animate-in fade-in duration-700">
    <!-- Header -->
    <div class="flex flex-col md:flex-row md:items-center justify-between gap-6 bg-white p-8 rounded-[40px] border border-slate-200/60 shadow-sm shadow-slate-100/50">
      <div class="flex items-center gap-5">
        <div class="bg-primary/10 p-4 rounded-[24px] border border-primary/20">
          <FileText class="w-8 h-8 text-primary" />
        </div>
        <div>
          <h1 class="text-3xl font-black text-slate-900 tracking-tight">Data Surat Jalan</h1>
          <p class="text-slate-500 font-bold text-sm mt-1">Daftar dokumen pengiriman yang telah diterbitkan</p>
        </div>
      </div>
    </div>

    <!-- Filters -->
    <div class="bg-white p-6 rounded-[32px] border border-slate-200/60 shadow-sm flex flex-col md:flex-row gap-4 items-center">
      <div class="relative flex-1 w-full">
        <Search class="absolute left-5 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
        <input 
          v-model="searchQuery"
          type="text" 
          placeholder="Cari No. SJ atau Nama Driver..." 
          class="w-full bg-slate-50 border-2 border-transparent focus:border-primary/20 focus:bg-white rounded-2xl pl-14 pr-6 py-4 font-bold text-slate-900 outline-none transition-all placeholder:text-slate-400 shadow-inner"
        />
      </div>
      <select 
        v-model="selectedStatus"
        class="w-full md:w-64 bg-slate-50 border-2 border-transparent focus:border-primary/20 focus:bg-white rounded-2xl px-6 py-4 font-bold text-slate-900 outline-none transition-all shadow-inner"
      >
        <option value="ALL">Semua Status</option>
        <option value="WAITING_APPROVAL">Menunggu Persetujuan</option>
        <option value="SUPERVISOR_APPROVED">Disetujui Supervisor</option>
        <option value="PENDING">Diproses Admin</option>
        <option value="ON_DELIVERY">Dalam Pengiriman</option>
        <option value="COMPLETED">Selesai</option>
      </select>
    </div>

    <!-- Main Table -->
    <div class="bg-white border border-slate-200/60 rounded-[40px] overflow-hidden shadow-xl shadow-slate-200/20">
      <DataTable :columns="columns" :data="filteredBatches">
        <template #cell-delivery_order_no="{ row }">
          <div class="flex flex-col">
            <span class="text-sm font-black text-slate-900">{{ row.delivery_order_no }}</span>
            <span class="text-[10px] text-slate-400 font-bold uppercase tracking-wider">SJ NUMBER</span>
          </div>
        </template>

        <template #cell-driver="{ row }">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-xl bg-slate-50 border border-slate-100 flex items-center justify-center">
              <User class="w-5 h-5 text-slate-400" />
            </div>
            <div class="flex flex-col">
              <span class="text-sm font-bold text-slate-900">
                {{ row.driver ? `${row.driver.first_name} ${row.driver.last_name}` : 'Belum Assign' }}
              </span>
              <span class="text-[11px] text-slate-500 font-medium">
                {{ row.vehicle ? row.vehicle.license_plate : 'Tanpa Armada' }}
              </span>
            </div>
          </div>
        </template>

        <template #cell-items_count="{ row }">
          <Badge variant="outline" class="bg-blue-50 text-blue-600 border-blue-100 rounded-lg px-3 py-1 font-black text-[11px]">
            {{ row.items?.length || 0 }} NOTA
          </Badge>
        </template>

        <template #cell-created_at="{ row }">
          <div class="flex items-center gap-2 text-slate-600">
            <Calendar class="w-4 h-4 text-slate-400" />
            <span class="text-sm font-bold">{{ formatDate(row.created_at) }}</span>
          </div>
        </template>

        <template #cell-status="{ row }">
          <Badge :class="`${getStatusColor(row.status)} rounded-full px-4 py-1.5 font-black text-[9px] uppercase tracking-widest border`" variant="outline">
            {{ getStatusLabel(row.status) }}
          </Badge>
        </template>

        <template #cell-actions="{ row }">
          <div class="flex items-center gap-2">
            <Button variant="ghost" size="sm" @click="openDetail(row)" class="text-slate-600 hover:bg-slate-50 rounded-xl font-black text-[10px] px-3">
              <Eye class="w-3.5 h-3.5 mr-1" /> DETAIL
            </Button>
            <Button variant="ghost" size="sm" @click="openPrintPreview(row)" class="text-primary hover:bg-primary/5 rounded-xl font-black text-[10px] px-3">
              <Printer class="w-3.5 h-3.5 mr-1" /> CETAK
            </Button>
          </div>
        </template>
      </DataTable>

      <!-- Empty State -->
      <div v-if="filteredBatches.length === 0" class="py-24 text-center">
        <div class="bg-slate-50 w-24 h-24 rounded-[32px] flex items-center justify-center mx-auto mb-6 border-2 border-dashed border-slate-200">
          <Truck class="w-10 h-10 text-slate-300" />
        </div>
        <h3 class="text-xl font-black text-slate-900">Data Tidak Ditemukan</h3>
        <p class="text-slate-500 font-bold mt-2">Coba gunakan kata kunci pencarian atau filter lain</p>
      </div>
    </div>

    <!-- Detail Modal -->
    <div v-if="showDetailModal" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="absolute inset-0 bg-slate-900/60 backdrop-blur-sm" @click="showDetailModal = false" />
      <div class="bg-white rounded-[40px] w-full max-w-4xl relative z-10 shadow-2xl overflow-hidden flex flex-col max-h-[90vh] animate-in zoom-in-95 duration-300">
        <div class="p-8 border-b border-slate-100 flex justify-between items-center bg-slate-50/50">
            <div class="flex items-center gap-4">
              <div class="w-16 h-16 rounded-2xl bg-white flex items-center justify-center border border-slate-200 shadow-sm overflow-hidden shrink-0 cursor-zoom-in hover:border-primary transition-colors" @click="zoomedQR = selectedBatch?.delivery_order_no">
                <img :src="`https://api.qrserver.com/v1/create-qr-code/?size=100x100&margin=0&data=${selectedBatch?.delivery_order_no}`" class="w-12 h-12" />
              </div>
              <div>
                <h3 class="text-2xl font-black text-slate-900">Detail Surat Jalan</h3>
                <p class="text-xs text-slate-500 font-bold uppercase tracking-widest">{{ selectedBatch?.delivery_order_no }}</p>
              </div>
            </div>
          <Button variant="ghost" size="icon" @click="showDetailModal = false" class="rounded-full hover:bg-slate-100">
            <X class="w-6 h-6" />
          </Button>
        </div>
        
        <div class="p-8 overflow-y-auto space-y-8 flex-1 bg-slate-50/20">
          <!-- Info Cards -->
          <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div class="bg-white p-6 rounded-3xl border border-slate-200 shadow-sm space-y-4">
              <div class="flex items-center gap-3 text-slate-400">
                <User class="w-4 h-4" />
                <span class="text-[10px] font-black uppercase tracking-widest">Supir</span>
              </div>
              <p class="text-lg font-black text-slate-900">
                {{ selectedBatch?.driver ? `${selectedBatch.driver.first_name} ${selectedBatch.driver.last_name}` : '—' }}
              </p>
            </div>
            <div class="bg-white p-6 rounded-3xl border border-slate-200 shadow-sm space-y-4">
              <div class="flex items-center gap-3 text-slate-400">
                <Car class="w-4 h-4" />
                <span class="text-[10px] font-black uppercase tracking-widest">Armada</span>
              </div>
              <p class="text-lg font-black text-slate-900">
                {{ selectedBatch?.vehicle ? selectedBatch.vehicle.license_plate : '—' }}
              </p>
            </div>
            <div class="bg-white p-6 rounded-3xl border border-slate-200 shadow-sm space-y-4">
              <div class="flex items-center gap-3 text-slate-400">
                <Clock class="w-4 h-4" />
                <span class="text-[10px] font-black uppercase tracking-widest">Status Terakhir</span>
              </div>
              <Badge :class="`${getStatusColor(selectedBatch?.status)} rounded-full px-4 py-1.5 font-black text-[9px] uppercase tracking-widest`" variant="outline">
                {{ getStatusLabel(selectedBatch?.status) }}
              </Badge>
            </div>
          </div>

          <!-- Items Table -->
          <div class="bg-white rounded-3xl border border-slate-200 shadow-sm overflow-hidden">
            <div class="px-8 py-6 border-b border-slate-100 flex items-center justify-between bg-slate-50/30">
              <h4 class="text-sm font-black text-slate-900 uppercase tracking-widest">Daftar Nota dalam Pengiriman</h4>
              <span class="text-[11px] font-black bg-blue-100 text-blue-700 px-4 py-1.5 rounded-full border border-blue-200">{{ selectedBatch?.items?.length }} NOTA TERHITUNG</span>
            </div>
            <div class="divide-y divide-slate-100">
              <div v-for="(item, idx) in selectedBatch?.items" :key="item.id" class="p-6 flex flex-col md:flex-row md:items-center justify-between gap-6 hover:bg-slate-50/50 transition-colors">
                <div class="flex items-start gap-5">
                  <div class="flex flex-col items-center gap-2">
                    <div class="w-12 h-12 rounded-2xl bg-slate-100 border border-slate-200 flex items-center justify-center font-black text-slate-400 shrink-0 shadow-inner">
                      {{ Number(idx) + 1 }}
                    </div>
                    <div class="w-10 h-10 rounded-lg bg-white border border-slate-200 flex items-center justify-center shadow-sm overflow-hidden cursor-zoom-in hover:border-primary transition-colors" @click="zoomedQR = (item.sales_order || item.sales_transaction)?.so_number || (item.sales_order || item.sales_transaction)?.invoice_no || item.id">
                      <img :src="`https://api.qrserver.com/v1/create-qr-code/?size=60x60&margin=0&data=${(item.sales_order || item.sales_transaction)?.so_number || (item.sales_order || item.sales_transaction)?.invoice_no || item.id}`" class="w-8 h-8" />
                    </div>
                  </div>
                  <div>
                    <h5 class="text-lg font-black text-slate-900">{{ item.sales_order?.so_number || item.sales_transaction?.invoice_no || 'NOT-SET' }}</h5>
                    <div class="flex items-center gap-2 mt-1">
                      <MapPin class="w-3 h-3 text-slate-400" />
                      <span class="text-xs font-bold text-slate-500">{{ item.sales_order?.store?.name || item.sales_transaction?.store?.name || 'Toko tidak terdaftar' }}</span>
                    </div>
                  </div>
                </div>
                <div class="flex items-center gap-8 px-6 py-4 bg-slate-50 rounded-2xl border border-slate-100">
                  <div class="flex flex-col">
                    <span class="text-[10px] font-black text-slate-400 uppercase tracking-widest">Total Tagihan</span>
                    <span class="text-md font-black text-slate-900">Rp {{ (item.sales_order?.total_amount || item.sales_transaction?.total_amount || 0).toLocaleString('id-ID') }}</span>
                  </div>
                  <div class="flex flex-col border-l border-slate-200 pl-8">
                    <span class="text-[10px] font-black text-slate-400 uppercase tracking-widest">Status Item</span>
                    <Badge :class="`${item.status === 'DELIVERED' ? 'bg-emerald-100 text-emerald-700' : 'bg-slate-200 text-slate-600'} rounded-lg px-3 py-1 font-black text-[10px] mt-1`" variant="outline">
                      {{ item.status === 'DELIVERED' ? 'DITERIMA' : 'PENDING' }}
                    </Badge>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div class="p-8 bg-white border-t border-slate-100 flex justify-end">
          <Button @click="showDetailModal = false" class="bg-slate-900 text-white rounded-2xl px-12 py-7 font-black shadow-xl shadow-slate-900/10 hover:bg-slate-800 transition-all">
            TUTUP DETAIL
          </Button>
        </div>
      </div>
    </div>

    <!-- Zoomed QR Overlay -->
    <div v-if="zoomedQR" class="fixed inset-0 z-[100] flex items-center justify-center p-8">
      <div class="absolute inset-0 bg-slate-900/80 backdrop-blur-md" @click="zoomedQR = null" />
      <div class="bg-white p-12 rounded-[48px] relative z-10 shadow-2xl flex flex-col items-center gap-8 animate-in zoom-in-50 duration-300">
        <div class="text-center">
          <h4 class="text-xl font-black text-slate-900 uppercase tracking-widest">SCAN VALIDASI</h4>
          <p class="text-sm font-bold text-slate-500 mt-2">{{ zoomedQR }}</p>
        </div>
        <div class="bg-white p-6 rounded-[32px] border-4 border-slate-100">
          <img :src="`https://api.qrserver.com/v1/create-qr-code/?size=400x400&margin=0&data=${zoomedQR}`" class="w-64 h-64 sm:w-80 sm:h-80" />
        </div>
        <Button @click="zoomedQR = null" variant="outline" class="rounded-2xl px-8 font-black border-2">TUTUP</Button>
      </div>
    </div>

    <!-- DO Printing Modal (SJ Preview - Landscape Format) -->
    <div v-if="selectedDO" class="fixed inset-0 bg-slate-900/60 backdrop-blur-md z-[60] flex items-center justify-center p-0 sm:p-4 overflow-y-auto">
       <Card id="surat-jalan-card" class="w-full max-w-[95%] sm:max-w-6xl bg-white shadow-2xl border-0 overflow-hidden my-auto print:shadow-none print:max-w-full">
         <!-- Header -->
         <div class="bg-white p-4 print:p-2 border-b border-slate-100">
            <div class="grid grid-cols-3 gap-8 items-center">
              <div class="space-y-1">
                <p class="text-[9px] font-black text-slate-400 uppercase tracking-widest">SOPIR / ARMADA</p>
                <p class="text-[11px] font-black text-slate-900">
                  {{ selectedDO.driver ? `${selectedDO.driver.first_name} ${selectedDO.driver.last_name}` : '........................' }} / {{ selectedDO.vehicle?.license_plate || '..........' }}
                </p>
              </div>
              <div class="space-y-1 text-center">
                <div class="inline-block bg-primary/10 px-4 py-1 rounded-full border border-primary/20 print:border-slate-900">
                  <p class="text-[10px] font-black text-primary uppercase tracking-tighter print:text-slate-900">SURAT JALAN DIGITAL</p>
                </div>
                <p class="text-[12px] font-black text-slate-900 mt-1 uppercase tracking-tight">{{ selectedDO.delivery_order_no }}</p>
              </div>
              <div class="text-right">
                <p class="text-[9px] font-black text-slate-400 uppercase tracking-widest">TANGGAL TERBIT</p>
                <p class="text-[10px] font-black text-slate-900 uppercase leading-tight mt-1">{{ formatDate(selectedDO.created_at) }}</p>
              </div>
            </div>
         </div>
         
         <div class="p-4 sm:p-6 space-y-4 print:p-2">
            <!-- Main Table -->
            <div class="border-2 border-slate-900 rounded-lg overflow-x-auto bg-white">
              <table class="w-full text-left text-[10px] border-collapse whitespace-nowrap">
                <thead>
                  <tr class="bg-slate-50 border-b-2 border-slate-900">
                    <th class="p-2 border-r border-slate-300 font-black text-center w-8">NO</th>
                    <th class="p-1 border-r border-slate-300 font-black text-center w-12 text-[8px]">QR SCAN</th>
                    <th class="p-2 border-r border-slate-300 font-black">NAMA TOKO / ALAMAT</th>
                    <th class="p-2 border-r border-slate-300 font-black text-right w-20 bg-amber-50">TAGIHAN</th>
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
                    <td class="p-2 border-r border-slate-300 text-center font-bold">{{ Number(idx) + 1 }}</td>
                    <td class="p-1 border-r border-slate-300 text-center align-middle">
                      <img :src="`https://api.qrserver.com/v1/create-qr-code/?size=60x60&margin=0&data=${(item.sales_order || item.sales_transaction)?.so_number || (item.sales_order || item.sales_transaction)?.invoice_no || item.id}`" class="w-8 h-8 mx-auto" />
                    </td>
                    <td class="p-2 border-r border-slate-300 whitespace-normal">
                      <p class="font-black text-slate-900 leading-none">{{ (item.sales_order || item.sales_transaction)?.store?.name }}</p>
                      <p class="text-[7px] text-slate-500 font-bold mt-0.5">{{ (item.sales_order || item.sales_transaction)?.store?.address }}</p>
                    </td>
                    <td class="p-2 border-r border-slate-300 text-right font-black bg-amber-50/20">
                      {{ formatCurrency((item.sales_order || item.sales_transaction)?.total_amount || 0).replace('Rp', '').trim() }}
                    </td>
                    <td class="p-2 border-r border-slate-300 bg-emerald-50/10"></td>
                    <td class="p-2 border-r border-slate-300 text-center font-bold text-[8px]">
                      {{ (item.sales_order || item.sales_transaction)?.payment_method || 'COD' }}
                    </td>
                    <td v-for="prod in batchProductColumns" :key="prod.id" class="p-1 border-r border-slate-300 text-center font-black">
                      {{ getProductQty(item, prod.id) || '' }}
                    </td>
                    <td class="p-2 border-r border-slate-300"></td>
                    <td class="p-2"></td>
                  </tr>

                  <!-- Placeholder Rows for Manual Entry (Fills up to 15 rows) -->
                  <tr v-for="n in Math.max(0, 15 - (selectedDO.items?.length || 0))" :key="'blank-'+n" class="h-6 bg-slate-50/10">
                    <td class="p-2 border-r border-slate-300 text-center text-slate-300 font-bold">{{ (selectedDO.items?.length || 0) + n }}</td>
                    <td class="p-2 border-r border-slate-300"></td>
                    <td class="p-2 border-r border-slate-300"></td>
                    <td class="p-2 border-r border-slate-300 bg-amber-50/10"></td>
                    <td class="p-2 border-r border-slate-300 bg-emerald-50/5"></td>
                    <td class="p-2 border-r border-slate-300"></td>
                    <td v-for="prod in batchProductColumns" :key="prod.id" class="p-1 border-r border-slate-300"></td>
                    <td class="p-2 border-r border-slate-300"></td>
                    <td class="p-2"></td>
                  </tr>

                  <!-- Total Row -->
                  <tr class="bg-slate-50 font-black border-t-2 border-slate-900 h-8">
                    <td colspan="3" class="p-2 text-right border-r border-slate-300 uppercase tracking-widest text-[8px]">TOTAL BATCH</td>
                    <td class="p-2 text-right border-r border-slate-300 bg-amber-50">{{ formatCurrency(calculateBatchTotal).replace('Rp', '').trim() }}</td>
                    <td colspan="2" class="border-r border-slate-300"></td>
                    <td v-for="prod in batchProductColumns" :key="prod.id" class="p-1 border-r border-slate-300 text-center text-primary bg-slate-100/30">
                       {{ calculateProductTotal(prod.id) }}
                    </td>
                    <td colspan="2"></td>
                  </tr>
                </tbody>
              </table>
            </div>

            <!-- Compact Signature Section -->
            <div class="grid grid-cols-3 gap-8 mt-6">
              <div class="text-center space-y-8">
                <p class="text-[9px] font-black uppercase tracking-widest">SOPIR / HELPER</p>
                <p class="text-[8px] font-bold text-slate-900">( .................................. )</p>
              </div>
              <div class="text-center space-y-8">
                <p class="text-[9px] font-black uppercase tracking-widest">ADMIN GUDANG</p>
                <p class="text-[8px] font-bold text-slate-900">( .................................. )</p>
              </div>
              <div class="flex justify-end items-center pr-10">
                 <div class="text-right mr-4">
                    <p class="text-[8px] font-black text-slate-400 uppercase leading-none">VALIDASI SCAN</p>
                    <p class="text-[7px] text-slate-300 italic mt-1 uppercase">Sistem Digital</p>
                 </div>
                 <img :src="`https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=${selectedDO.delivery_order_no}`" class="w-20 h-20 border-2 border-slate-900 p-1 rounded bg-white shadow-sm" />
              </div>
            </div>
         </div>

         <CardFooter class="p-6 bg-slate-50 border-t flex justify-end gap-3 print:hidden">
            <Button variant="ghost" class="font-bold text-slate-500 rounded-xl" @click="selectedDO = null">TUTUP PREVIEW</Button>
            <Button class="bg-slate-900 hover:bg-slate-800 text-white font-black px-12 py-6 rounded-2xl shadow-xl shadow-slate-200" @click="handlePrint">
              <Printer class="w-5 h-5 mr-3" />
              CETAK SURAT JALAN (LANDSCAPE)
            </Button>
         </CardFooter>
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
  #surat-jalan-card,
  #surat-jalan-card * {
    visibility: visible;
  }
  #surat-jalan-card {
    position: absolute !important;
    top: 0 !important;
    left: 0 !important;
    width: 100% !important;
    margin: 0 !important;
    border: none !important;
    box-shadow: none !important;
    transform: none !important;
    zoom: 0.85;
    -moz-transform: scale(0.85);
    -moz-transform-origin: top left;
  }
  .print\:hidden {
    display: none !important;
  }
}
</style>
