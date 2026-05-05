<template>
  <div class="p-6 space-y-6">
    <!-- Header -->
    <div class="flex justify-between items-center">
      <div>
        <h1 class="text-3xl font-bold tracking-tight">Manajemen Stok & Penerimaan</h1>
        <p class="text-muted-foreground">Kelola stok produk dan konfirmasi penerimaan barang dalam satu layar.</p>
      </div>
      <div class="flex gap-2">
        <Button variant="outline" @click="refreshAll" :loading="warehouseStore.loading">
          <RefreshCw class="h-4 w-4 mr-2" :class="{ 'animate-spin': warehouseStore.loading }" />
          Refresh Data
        </Button>
        <Button class="bg-primary hover:bg-primary/90 text-white font-bold px-6 rounded-xl shadow-lg flex gap-2" @click="showScanner = true">
          <ScanLine class="h-5 w-5" />
          SCAN BARCODE SJ
        </Button>
      </div>
    </div>

    <!-- Dashboard Stats -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <Card class="bg-primary/5 border-primary/10">
        <CardHeader class="pb-2">
          <CardDescription>Total Produk</CardDescription>
          <CardTitle class="text-3xl font-bold">{{ warehouseStore.inventory.length }}</CardTitle>
        </CardHeader>
      </Card>
      <Card :class="warehouseStore.pendingShipments.length > 0 ? 'bg-amber-50 border-amber-200' : ''">
        <CardHeader class="pb-2">
          <CardDescription>Kiriman Menunggu</CardDescription>
          <CardTitle class="text-3xl font-bold" :class="warehouseStore.pendingShipments.length > 0 ? 'text-amber-600' : ''">
            {{ warehouseStore.pendingShipments.length }}
          </CardTitle>
        </CardHeader>
      </Card>
      <Card>
        <CardHeader class="pb-2">
          <CardDescription>Status Gudang</CardDescription>
          <CardTitle class="text-xl font-bold flex items-center gap-2">
            <CheckCircle2 class="h-5 w-5 text-green-500" />
            Operasional
          </CardTitle>
        </CardHeader>
      </Card>
    </div>

    <!-- Main Content Split Layout -->
    <div class="grid grid-cols-1 lg:grid-cols-12 gap-8">
      
      <!-- Left Column: Inventory (60%) -->
      <div class="lg:col-span-7 space-y-4">
        <div class="flex justify-between items-center">
          <h2 class="text-xl font-bold flex items-center gap-2">
            <Boxes class="h-5 w-5 text-primary" />
            Stok Saat Ini
          </h2>
          <Button size="sm" @click="showAdjustment = true">Penyesuaian Stok</Button>
        </div>
        <Card class="border-none shadow-sm overflow-hidden">
          <DataTable :columns="stockColumns" :data="warehouseStore.inventory" />
        </Card>
      </div>

      <!-- Right Column: Receiving (40%) -->
      <div class="lg:col-span-5 space-y-4">
        <h2 class="text-xl font-bold flex items-center gap-2">
          <Truck class="h-5 w-5 text-primary" />
          Penerimaan Barang
        </h2>
        
        <div v-if="warehouseStore.pendingShipments.length === 0" class="flex flex-col items-center justify-center py-20 bg-muted/20 rounded-2xl border border-dashed border-slate-200 text-center space-y-3">
          <div class="bg-slate-100 p-4 rounded-full">
            <PackageSearch class="h-8 w-8 text-slate-400" />
          </div>
          <p class="text-muted-foreground font-medium text-lg">Tidak ada pengiriman menunggu.</p>
          <p class="text-xs text-slate-400">Semua barang dari pabrik telah diterima.</p>
        </div>

        <div v-else class="space-y-4 max-h-[calc(100vh-350px)] overflow-y-auto pr-2 no-scrollbar">
          <Card v-for="transfer in warehouseStore.pendingShipments" :key="transfer.id" class="relative overflow-hidden group hover:shadow-md transition-all duration-300">
            <div class="absolute top-0 left-0 w-1.5 h-full bg-primary"></div>
            <CardHeader class="p-4 pb-2">
              <div class="flex justify-between items-start">
                <div>
                  <CardTitle class="text-base font-bold">{{ transfer.product?.name }}</CardTitle>
                  <CardDescription class="text-xs">Dari: {{ transfer.from_factory?.name || 'Pabrik Utama' }}</CardDescription>
                </div>
                <div class="bg-primary/10 text-primary px-2 py-0.5 rounded-full text-[10px] font-black uppercase tracking-wider">
                  {{ transfer.status }}
                </div>
              </div>
            </CardHeader>
            <CardContent class="p-4 pt-0 space-y-3">
              <div class="grid grid-cols-2 gap-4">
                <div>
                  <p class="text-[10px] text-muted-foreground uppercase font-bold tracking-tighter">Jumlah</p>
                  <p class="text-base font-black">
                    {{ transfer.quantity }} {{ transfer.product?.unit }}
                  </p>
                </div>
                <div>
                  <p class="text-[10px] text-muted-foreground uppercase font-bold tracking-tighter">Tonase</p>
                  <p class="text-base font-black">
                    {{ (transfer.total_weight / 1000).toFixed(2) }} Ton
                  </p>
                </div>
              </div>
              <div v-if="transfer.notes" class="bg-slate-50 p-2 rounded-lg text-xs border border-slate-100 italic text-slate-600">
                 "{{ transfer.notes }}"
              </div>
            </CardContent>
            <CardFooter class="bg-slate-50/50 border-t flex justify-end p-3 gap-2">
              <template v-if="transfer.status === 'REQUESTED'">
                <Button variant="ghost" size="sm" class="text-destructive h-8 px-3 font-bold hover:bg-destructive/5" @click="handleReject(transfer.id)">Tolak</Button>
                <Button size="sm" class="h-8 px-4 font-bold" @click="handleApprove(transfer.id)">Setujui</Button>
              </template>
              <template v-else-if="transfer.status === 'SHIPPED'">
                <Button size="sm" class="h-8 px-4 font-bold w-full" @click="handleReceive(transfer.id)" :loading="processingId === transfer.id">
                  Konfirmasi Terima Barang
                </Button>
              </template>
            </CardFooter>
          </Card>
        </div>
      </div>
    </div>

    <!-- Stock Adjustment Modal -->
    <div v-if="showAdjustment" class="fixed inset-0 bg-background/80 backdrop-blur-sm z-50 flex items-center justify-center p-4">
       <Card class="w-full max-w-md shadow-2xl border-2">
         <CardHeader>
           <CardTitle>Penyesuaian Stok (Stock Opname)</CardTitle>
           <CardDescription>Sesuaikan jumlah fisik produk di gudang jika ada selisih.</CardDescription>
         </CardHeader>
         <CardContent class="space-y-4">
           <div class="space-y-2">
             <label class="text-sm font-medium">Pilih Produk</label>
             <select v-model="adjustForm.product_id" class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm focus:ring-2 focus:ring-primary/20 transition-all outline-none">
               <option v-for="item in warehouseStore.inventory" :key="item.product_id" :value="item.product_id">
                 {{ item.product?.name }} (SKU: {{ item.product?.sku }})
               </option>
             </select>
           </div>
           <div class="space-y-2">
             <label class="text-sm font-medium">Jumlah Fisik Baru</label>
             <div class="relative">
               <input type="number" v-model="adjustForm.quantity" class="flex h-12 w-full rounded-md border border-input bg-background px-3 py-2 text-lg font-bold focus:ring-2 focus:ring-primary/20 transition-all outline-none" />
               <div class="absolute right-3 top-3.5 text-xs font-bold text-slate-400 uppercase">Input Fisik</div>
             </div>
           </div>
           <div class="space-y-2">
             <label class="text-sm font-medium">Alasan Penyesuaian</label>
             <textarea v-model="adjustForm.reason" placeholder="Contoh: Rusak, Selisih Hitung, dll" class="flex min-h-[80px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm focus:ring-2 focus:ring-primary/20 transition-all outline-none"></textarea>
           </div>
         </CardContent>
         <CardFooter class="flex justify-end gap-2 bg-slate-50 p-4 border-t rounded-b-lg">
           <Button variant="outline" class="font-bold" @click="showAdjustment = false">Batal</Button>
           <Button class="font-bold px-6" @click="handleAdjust" :loading="isAdjusting">Simpan Perubahan</Button>
         </CardFooter>
       </Card>
    </div>

    <!-- Scanner Mock Modal -->
    <div v-if="showScanner" class="fixed inset-0 bg-background/80 backdrop-blur-sm z-50 flex items-center justify-center p-4">
       <Card class="w-full max-w-md border-2 border-primary shadow-2xl overflow-hidden rounded-2xl">
         <CardHeader class="bg-primary text-primary-foreground p-6">
           <CardTitle class="flex items-center gap-2">
             <ScanLine class="h-6 w-6" />
             Scan Surat Jalan (SJ)
           </CardTitle>
           <CardDescription class="text-primary-foreground/70">Scan barcode pada surat jalan atau masukkan nomor SJ secara manual.</CardDescription>
         </CardHeader>
         <CardContent class="p-6 space-y-6">
           <div class="aspect-square bg-slate-100 rounded-3xl border-4 border-dashed border-slate-200 flex flex-col items-center justify-center text-slate-400 gap-4 relative overflow-hidden">
             <div class="w-48 h-48 border-4 border-primary/20 rounded-[2rem] flex items-center justify-center relative z-10 bg-white shadow-inner">
               <div class="absolute inset-0 border-2 border-primary rounded-[1.8rem] animate-pulse"></div>
               <QrCode class="w-24 h-24 text-primary opacity-30" />
               <div class="absolute w-full h-1 bg-primary/50 top-1/2 left-0 -translate-y-1/2 animate-bounce"></div>
             </div>
             <p class="text-[10px] font-black uppercase tracking-[0.3em] text-primary/60 z-10 bg-white/80 px-4 py-1 rounded-full border border-primary/10">Scanner Aktif</p>
             
             <!-- Decorative scanner effect -->
             <div class="absolute inset-0 bg-gradient-to-b from-primary/5 to-transparent opacity-50"></div>
           </div>
           
           <div class="space-y-2">
             <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Input Manual No. Surat Jalan</label>
             <div class="relative">
               <Input 
                 v-model="scannedDO" 
                 placeholder="DO-YYYYMMDD-XXXX" 
                 class="h-14 rounded-2xl border-2 focus-visible:ring-primary font-mono text-center text-xl tracking-[0.1em] font-bold"
                 @keyup.enter="handleScanSubmit"
               />
               <Search class="absolute right-4 top-4.5 h-5 w-5 text-slate-300" />
             </div>
           </div>
         </CardContent>
         <CardFooter class="flex justify-between gap-3 p-6 bg-slate-50 border-t">
           <Button variant="ghost" class="font-bold text-slate-500 px-6" @click="showScanner = false">BATAL</Button>
           <Button class="flex-1 font-black h-12 rounded-xl text-base shadow-lg shadow-primary/20" @click="handleScanSubmit" :loading="isScanning">
             KONFIRMASI PENERIMAAN
           </Button>
         </CardFooter>
       </Card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref, reactive, watch } from 'vue'
import { useWarehouseStore } from '@/stores/warehouse'
import { useMasterDataStore } from '@/stores/masterData'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card/index'
import DataTable from '@/components/DataTable.vue'
import { 
  Boxes, 
  Truck, 
  ScanLine, 
  RefreshCw, 
  CheckCircle2, 
  PackageSearch, 
  QrCode, 
  Search,
  AlertCircle
} from 'lucide-vue-next'

const warehouseStore = useWarehouseStore()
const masterDataStore = useMasterDataStore()

// State
const showAdjustment = ref(false)
const showScanner = ref(false)
const processingId = ref('')
const scannedDO = ref('')
const isScanning = ref(false)
const isAdjusting = ref(false)

const adjustForm = reactive({
  product_id: '',
  quantity: 0,
  reason: ''
})

// Columns for stock table
const stockColumns = [
  { key: 'product.name', label: 'Nama Produk', class: 'font-bold' },
  { key: 'product.sku', label: 'SKU', class: 'font-mono text-xs' },
  { 
    key: 'quantity', 
    label: 'Stok Fisik', 
    render: (val: number, item: any) => {
      const isLow = val < item.min_limit
      return `<div class="flex items-center gap-2">
        <span class="font-black text-lg ${isLow ? 'text-red-600 animate-pulse' : 'text-slate-900'}">${val} ${item.product.unit}</span>
        ${isLow ? '<span class="bg-red-100 text-red-600 text-[8px] font-black px-1.5 py-0.5 rounded uppercase tracking-tighter">Low</span>' : ''}
      </div>`
    }
  },
  { 
    key: 'min_limit', 
    label: 'Limit Min.',
    render: (val: number, item: any) => {
      return `<input type="number" value="${val}" class="w-16 px-2 py-1 border rounded-lg text-xs font-bold focus:ring-2 focus:ring-primary/20 outline-none transition-all" onchange="window.dispatchEvent(new CustomEvent('set-limit', {detail: {id: '${item.product_id}', val: this.value}}))" />`
    }
  },
  { key: 'updated_at', label: 'Terakhir Update', type: 'datetime', class: 'text-xs text-slate-400' }
]

// Methods
const refreshAll = async () => {
  await Promise.all([
    warehouseStore.fetchInventory(),
    warehouseStore.fetchPendingShipments()
  ])
}

const handleApprove = async (id: string) => {
  try {
    await warehouseStore.approveShipment(id)
  } catch (err) {
    alert(err)
  }
}

const handleReject = async (id: string) => {
  if (!confirm('Tolak permintaan pengiriman ini?')) return
  try {
    await warehouseStore.rejectShipment(id)
  } catch (err) {
    alert(err)
  }
}

const handleReceive = async (id: string) => {
  if (!confirm('Pastikan jumlah barang yang diterima sesuai dengan fisik. Lanjutkan?')) return
  
  processingId.value = id
  try {
    await warehouseStore.receiveShipment(id)
    // Inventory refresh is handled by the store action
  } catch (err) {
    alert(err)
  } finally {
    processingId.value = ''
  }
}

const handleScanSubmit = async () => {
  if (!scannedDO.value) return
  
  isScanning.value = true
  try {
    await warehouseStore.receiveByDO(scannedDO.value)
    showScanner.value = false
    scannedDO.value = ''
    alert('✓ Barang telah diterima berdasarkan Surat Jalan: ' + scannedDO.value)
  } catch (err) {
    alert('Gagal menerima barang: ' + err)
  } finally {
    isScanning.value = false
  }
}

const handleAdjust = async () => {
  if (!adjustForm.product_id || !adjustForm.reason) {
    alert('Mohon lengkapi semua data penyesuaian.')
    return
  }
  
  isAdjusting.value = true
  try {
    await warehouseStore.adjustStock(adjustForm)
    showAdjustment.value = false
    // Reset form
    adjustForm.product_id = ''
    adjustForm.quantity = 0
    adjustForm.reason = ''
  } catch (err) {
    alert(err)
  } finally {
    isAdjusting.value = false
  }
}

const handleSetLimit = async (productId: string, newLimit: number) => {
  try {
    await warehouseStore.setStockLimit({ product_id: productId, limit: newLimit })
  } catch (err) {
    alert(err)
  }
}

// Lifecycle & Watchers
watch(() => masterDataStore.selectedBranchId, () => {
  refreshAll()
})

onMounted(() => {
  refreshAll()
  
  window.addEventListener('set-limit', (e: any) => {
    handleSetLimit(e.detail.id, parseInt(e.detail.val))
  })
})
</script>

<style scoped>
.no-scrollbar::-webkit-scrollbar {
  display: none;
}
.no-scrollbar {
  -ms-overflow-style: none;
  scrollbar-width: none;
}
</style>
