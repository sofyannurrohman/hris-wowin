<template>
  <div class="p-6 space-y-6 bg-[#f8fafc] min-h-screen">
    <!-- Header with Breadcrumbs -->
    <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 bg-white p-6 rounded-3xl shadow-sm border border-slate-100">
      <div class="flex items-center gap-4">
        <Button variant="ghost" size="icon" @click="router.back()" class="rounded-full hover:bg-slate-100">
          <ArrowLeft class="h-5 w-5" />
        </Button>
        <div>
          <div class="flex items-center gap-2 text-xs font-bold text-primary uppercase tracking-widest mb-1">
            <Factory class="h-3 w-3" />
            <span>Pusat Produksi & Inventory</span>
          </div>
          <h1 class="text-2xl font-extrabold tracking-tight text-slate-900">{{ factoryStore.currentFactory?.name || 'Memuat...' }}</h1>
          <p class="text-sm text-slate-500 flex items-center mt-0.5">
            <MapPin class="mr-1 h-3.5 w-3.5 text-slate-400" /> {{ factoryStore.currentFactory?.location }}
          </p>
        </div>
      </div>
      <div class="flex items-center gap-3">
        <Button variant="outline" @click="showInventoryLogs = true" class="rounded-xl border-slate-200">
          <History class="mr-2 h-4 w-4" /> Log Mutasi
        </Button>
        <Button @click="showSendToBranch = true" class="rounded-xl bg-orange-600 hover:bg-orange-700 shadow-lg shadow-orange-200 transition-all">
          <Truck class="mr-2 h-4 w-4" /> Kirim ke Cabang
        </Button>
      </div>
    </div>

    <!-- Main Split Layout -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
      
      <!-- LEFT COLUMN: STOCK MANAGEMENT -->
      <div class="space-y-6">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-2xl bg-blue-50 flex items-center justify-center text-blue-600">
              <Package class="h-5 w-5" />
            </div>
            <h2 class="text-xl font-bold text-slate-900">Manajemen Stok</h2>
          </div>
          <Badge variant="secondary" class="bg-blue-50 text-blue-600 border-none font-bold">
            {{ factoryStore.inventory.length }} Produk
          </Badge>
        </div>

        <Card class="border-none shadow-sm bg-white rounded-3xl overflow-hidden">
          <DataTable :columns="stockColumns" :data="factoryStore.inventory" class="border-none">
            <template #cell-quantity="{ row }">
              <div class="flex items-center gap-3">
                <span class="text-lg font-black text-slate-900">{{ (row as any).quantity }}</span>
                <span class="text-[10px] font-bold text-slate-400 uppercase tracking-tighter">{{ (row as any).product?.unit }}</span>
              </div>
            </template>
            <template #cell-actions="{ row }">
              <Button 
                variant="ghost" 
                size="sm" 
                @click="openAdjustStock(row)"
                class="h-8 w-8 p-0 rounded-lg text-slate-400 hover:text-primary hover:bg-primary/5"
              >
                <Settings2 class="h-4 w-4" />
              </Button>
            </template>
          </DataTable>
        </Card>
      </div>

      <!-- RIGHT COLUMN: PRODUCTION LOG -->
      <div class="space-y-6">
        <div class="flex items-center justify-between">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-2xl bg-emerald-50 flex items-center justify-center text-emerald-600">
              <Activity class="h-5 w-5" />
            </div>
            <h2 class="text-xl font-bold text-slate-900">Log Produksi</h2>
          </div>
          <Button size="sm" @click="openLogProduction" class="rounded-xl shadow-md shadow-primary/10">
            <Plus class="mr-1 h-4 w-4" /> Log Baru
          </Button>
        </div>

        <Card class="border-none shadow-sm bg-white rounded-3xl overflow-hidden">
          <DataTable :columns="productionColumns" :data="factoryStore.productionHistory" class="border-none">
            <template #cell-quantity="{ row }">
              <span class="font-bold text-emerald-600">+{{ (row as any).quantity }}</span>
            </template>
            <template #cell-actions="{ row }">
              <div class="flex items-center gap-1">
                <Button variant="ghost" size="icon" @click="openEditProduction(row)" class="h-8 w-8 text-slate-400 hover:text-primary">
                  <Edit2 class="h-3.5 w-3.5" />
                </Button>
                <Button variant="ghost" size="icon" @click="handleDeleteProduction((row as any).id)" class="h-8 w-8 text-slate-400 hover:text-destructive">
                  <Trash2 class="h-3.5 w-3.5" />
                </Button>
              </div>
            </template>
          </DataTable>
        </Card>
      </div>
    </div>

    <!-- Modals -->
    <!-- Log Production Modal -->
    <div v-if="showLogProduction" class="fixed inset-0 bg-slate-900/40 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <Card class="w-full max-w-md shadow-2xl animate-in zoom-in-95 duration-200 rounded-3xl overflow-hidden border-none">
        <CardHeader class="p-6 border-b bg-white">
          <CardTitle class="text-xl font-bold">{{ isEditingProduction ? 'Edit Log Produksi' : 'Catat Hasil Produksi' }}</CardTitle>
          <CardDescription>Barang yang dicatat akan otomatis menambah stok inventory.</CardDescription>
        </CardHeader>
        <CardContent class="p-6 space-y-4 bg-white">
          <div class="space-y-2">
            <label class="text-sm font-bold text-slate-700">Pilih Produk</label>
            <select 
              v-model="productionForm.product_id" 
              :disabled="isEditingProduction"
              class="w-full px-4 py-3 bg-slate-50 border border-slate-100 rounded-2xl text-sm focus:ring-2 focus:ring-primary/20 outline-none"
            >
              <option value="" disabled>Pilih Produk...</option>
              <option v-for="p in factoryStore.products" :key="p.id" :value="p.id">{{ p.name }} ({{ p.sku }})</option>
            </select>
          </div>
          <div class="grid grid-cols-2 gap-4">
            <div class="space-y-2">
              <label class="text-sm font-bold text-slate-700">Jumlah Hasil</label>
              <input type="number" v-model="productionForm.quantity" class="w-full px-4 py-3 bg-slate-50 border border-slate-100 rounded-2xl text-sm outline-none focus:ring-2 focus:ring-primary/20" />
            </div>
            <div class="space-y-2">
              <label class="text-sm font-bold text-slate-700">ID Operator</label>
              <input type="text" v-model="productionForm.employee_id" class="w-full px-4 py-3 bg-slate-50 border border-slate-100 rounded-2xl text-sm outline-none focus:ring-2 focus:ring-primary/20" placeholder="UUID" />
            </div>
          </div>
          <div class="space-y-2">
            <label class="text-sm font-bold text-slate-700">Catatan</label>
            <textarea v-model="productionForm.notes" class="w-full px-4 py-3 bg-slate-50 border border-slate-100 rounded-2xl text-sm outline-none focus:ring-2 focus:ring-primary/20 resize-none" rows="2"></textarea>
          </div>
        </CardContent>
        <CardFooter class="bg-slate-50/50 p-6 flex justify-end gap-3">
          <Button variant="ghost" @click="showLogProduction = false" class="rounded-xl font-bold">Batal</Button>
          <Button @click="handleProductionSubmit" :loading="submitting" class="rounded-xl px-8 shadow-lg shadow-primary/20 font-bold">
            Simpan & Update Stok
          </Button>
        </CardFooter>
      </Card>
    </div>

    <!-- Adjust Stock Modal -->
    <div v-if="showAdjustStock" class="fixed inset-0 bg-slate-900/40 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <Card class="w-full max-w-md shadow-2xl rounded-3xl overflow-hidden border-none">
        <CardHeader class="p-6 border-b bg-white">
          <CardTitle class="text-xl font-bold">Penyesuaian Stok</CardTitle>
          <CardDescription>Koreksi jumlah stok secara manual untuk produk ini.</CardDescription>
        </CardHeader>
        <CardContent class="p-6 space-y-4 bg-white">
          <div class="p-4 bg-blue-50 rounded-2xl border border-blue-100 mb-4">
            <p class="text-xs font-bold text-blue-600 uppercase tracking-widest mb-1">Produk</p>
            <p class="text-sm font-bold text-slate-900">{{ selectedStock?.product?.name }}</p>
            <p class="text-[10px] text-slate-500 mt-0.5">SKU: {{ selectedStock?.product?.sku }} | Stok Saat Ini: {{ selectedStock?.quantity }}</p>
          </div>
          <div class="space-y-2">
            <label class="text-sm font-bold text-slate-700">Jumlah Stok Baru</label>
            <input type="number" v-model="adjustStockForm.quantity" class="w-full px-4 py-3 bg-slate-50 border border-slate-100 rounded-2xl text-sm outline-none focus:ring-2 focus:ring-primary/20" />
          </div>
          <div class="space-y-2">
            <label class="text-sm font-bold text-slate-700">Alasan Penyesuaian</label>
            <textarea v-model="adjustStockForm.reason" placeholder="Contoh: Barang rusak, Salah input, Audit stok..." class="w-full px-4 py-3 bg-slate-50 border border-slate-100 rounded-2xl text-sm outline-none focus:ring-2 focus:ring-primary/20 resize-none" rows="2"></textarea>
          </div>
        </CardContent>
        <CardFooter class="bg-slate-50/50 p-6 flex justify-end gap-3">
          <Button variant="ghost" @click="showAdjustStock = false" class="rounded-xl font-bold">Batal</Button>
          <Button @click="handleAdjustStockSubmit" :loading="submitting" class="rounded-xl px-8 shadow-lg shadow-primary/20 font-bold bg-blue-600 hover:bg-blue-700">
            Koreksi Stok
          </Button>
        </CardFooter>
      </Card>
    </div>

    <!-- Send to Branch Modal (Enhanced Multi-Item) -->
    <div v-if="showSendToBranch" class="fixed inset-0 bg-slate-900/40 backdrop-blur-sm z-50 flex items-center justify-center p-4">
       <Card class="w-full max-w-2xl shadow-2xl rounded-3xl overflow-hidden border-none animate-in fade-in zoom-in-95 duration-200">
         <CardHeader class="p-6 border-b bg-white">
           <div class="flex justify-between items-start">
             <div>
               <CardTitle class="text-xl font-bold">Kirim ke Cabang (Multi-Item)</CardTitle>
               <CardDescription>Pilih beberapa barang untuk dikirim dalam satu armada.</CardDescription>
             </div>
             <div class="text-right">
               <p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Total Tonase</p>
               <p class="text-2xl font-black text-primary">{{ totalShipmentWeight.toFixed(2) }} <span class="text-xs">KG</span></p>
             </div>
           </div>
         </CardHeader>
         <CardContent class="p-6 space-y-6 bg-white max-h-[60vh] overflow-y-auto">
           <div class="space-y-2">
             <label class="text-sm font-bold text-slate-700">Cabang Tujuan</label>
             <select v-model="transferForm.to_branch_id" class="w-full px-4 py-3 bg-slate-50 border border-slate-100 rounded-2xl text-sm outline-none">
               <option value="" disabled>Pilih Cabang...</option>
               <option v-for="b in masterDataStore.branches" :key="b.id" :value="b.id">{{ b.name }}</option>
             </select>
           </div>

           <!-- Multi Item List -->
           <div class="space-y-4">
             <div class="flex items-center justify-between">
               <label class="text-sm font-bold text-slate-700">Item Pengiriman</label>
               <Button variant="ghost" size="sm" @click="addTransferItem" class="text-primary font-bold text-xs">
                 <Plus class="mr-1 h-3 w-3" /> Tambah Barang
               </Button>
             </div>
             
             <div v-for="(item, index) in transferForm.items" :key="index" class="p-4 bg-slate-50 rounded-2xl border border-slate-100 space-y-4">
               <div class="flex justify-between items-start gap-4">
                 <div class="flex-1 space-y-2">
                   <label class="text-[10px] font-bold text-slate-400 uppercase">Pilih Produk</label>
                   <select v-model="item.product_id" class="w-full px-3 py-2 bg-white border border-slate-200 rounded-xl text-sm outline-none">
                     <option v-for="s in factoryStore.inventory" :key="s.product_id" :value="s.product_id">
                       {{ s.product?.name }} (Stok: {{ s.quantity }})
                     </option>
                   </select>
                 </div>
                 <div class="w-24 space-y-2">
                   <label class="text-[10px] font-bold text-slate-400 uppercase">Jumlah</label>
                   <input type="number" v-model="item.quantity" class="w-full px-3 py-2 bg-white border border-slate-200 rounded-xl text-sm outline-none" />
                 </div>
                 <div class="w-24 space-y-2 text-right">
                    <label class="text-[10px] font-bold text-slate-400 uppercase">Tonase</label>
                    <p class="py-2 font-bold text-slate-700 text-sm">{{ calculateItemWeight(item).toFixed(1) }} KG</p>
                 </div>
                 <Button variant="ghost" size="icon" @click="removeTransferItem(index)" class="mt-6 h-8 w-8 text-slate-300 hover:text-destructive">
                   <Trash2 class="h-4 w-4" />
                 </Button>
               </div>
             </div>
           </div>

           <div class="space-y-2">
             <label class="text-sm font-bold text-slate-700">Catatan Pengiriman (Opsional)</label>
             <textarea v-model="transferForm.notes" class="w-full px-4 py-3 bg-slate-50 border border-slate-100 rounded-2xl text-sm outline-none resize-none" rows="2" placeholder="Contoh: Titip armada vendor, dll"></textarea>
           </div>
         </CardContent>
         <CardFooter class="bg-slate-50/50 p-6 flex justify-end gap-3">
           <Button variant="ghost" @click="showSendToBranch = false" class="rounded-xl font-bold">Batal</Button>
           <Button @click="handleTransferSubmit" :loading="submitting" class="rounded-xl px-8 shadow-lg shadow-orange-200 font-bold bg-orange-600 hover:bg-orange-700 text-white">
             Konfirmasi & Buat Surat Jalan
           </Button>
         </CardFooter>
       </Card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref, reactive, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useFactoryStore } from '@/stores/factory'
import { useMasterDataStore } from '@/stores/masterData'
import { toast } from 'vue-sonner'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import DataTable from '@/components/DataTable.vue'
import { 
  ArrowLeft, 
  Package, 
  Activity, 
  Plus, 
  Edit2, 
  Trash2, 
  Settings2, 
  Truck, 
  History,
  MapPin,
  Factory,
  ChevronRight
} from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const factoryStore = useFactoryStore()
const masterDataStore = useMasterDataStore()
const factoryId = route.params.id as string

const showLogProduction = ref(false)
const showAdjustStock = ref(false)
const showSendToBranch = ref(false)
const showInventoryLogs = ref(false)
const submitting = ref(false)
const isEditingProduction = ref(false)
const currentProductionId = ref('')
const selectedStock = ref<any>(null)

const productionForm = reactive({
  product_id: '',
  quantity: 0,
  employee_id: '',
  notes: ''
})

const adjustStockForm = reactive({
  quantity: 0,
  reason: ''
})

const transferForm = reactive({
  to_branch_id: '',
  items: [{ product_id: '', quantity: 0 }] as any[],
  notes: ''
})

const addTransferItem = () => {
  transferForm.items.push({ product_id: '', quantity: 0 })
}

const removeTransferItem = (index: number) => {
  if (transferForm.items.length > 1) {
    transferForm.items.splice(index, 1)
  }
}

const calculateItemWeight = (item: any) => {
  const product = factoryStore.products.find(p => p.id === item.product_id)
  return product ? product.weight * item.quantity : 0
}

const totalShipmentWeight = computed(() => {
  return transferForm.items.reduce((total, item) => total + calculateItemWeight(item), 0)
})

onMounted(async () => {
  await factoryStore.fetchFactoryDetail(factoryId)
  factoryStore.fetchProducts()
  factoryStore.fetchInventory(factoryId)
  factoryStore.fetchProductionHistory(factoryId)
  masterDataStore.fetchBranches()
})

const openLogProduction = () => {
  isEditingProduction.value = false
  Object.assign(productionForm, {
    product_id: '',
    quantity: 0,
    employee_id: '',
    notes: ''
  })
  showLogProduction.value = true
}

const openEditProduction = (item: any) => {
  isEditingProduction.value = true
  currentProductionId.value = item.id
  Object.assign(productionForm, {
    product_id: item.product_id,
    quantity: item.quantity,
    employee_id: item.employee_id,
    notes: item.notes
  })
  showLogProduction.value = true
}

const handleProductionSubmit = async () => {
  if (!productionForm.product_id || productionForm.quantity <= 0) return
  submitting.value = true
  try {
    if (isEditingProduction.value) {
      await factoryStore.updateProductionLog(factoryId, currentProductionId.value, productionForm)
      toast.success('Log produksi berhasil diperbarui')
    } else {
      await factoryStore.logProduction(factoryId, productionForm)
      toast.success('Log produksi berhasil dicatat')
    }
    showLogProduction.value = false
  } catch (err) {
    toast.error('Gagal menyimpan log produksi: ' + err)
  } finally {
    submitting.value = false
  }
}

const handleDeleteProduction = async (id: string) => {
  if (!confirm('Hapus log produksi ini? Stok barang akan otomatis dikurangi kembali.')) return
  try {
    await factoryStore.deleteProductionLog(factoryId, id)
    toast.success('Log produksi berhasil dihapus')
  } catch (err) {
    toast.error('Gagal menghapus log produksi: ' + err)
  }
}

const openAdjustStock = (row: any) => {
  selectedStock.value = row
  adjustStockForm.quantity = row.quantity
  adjustStockForm.reason = ''
  showAdjustStock.value = true
}

const handleAdjustStockSubmit = async () => {
  submitting.value = true
  try {
    await factoryStore.adjustStock(factoryId, {
      product_id: selectedStock.value.product_id,
      quantity: adjustStockForm.quantity,
      reason: adjustStockForm.reason
    })
    showAdjustStock.value = false
    toast.success('Stok berhasil disesuaikan')
  } catch (err) {
    toast.error('Gagal menyesuaikan stok: ' + err)
  } finally {
    submitting.value = false
  }
}

const handleTransferSubmit = async () => {
  if (!transferForm.to_branch_id || transferForm.items.length === 0) return
  submitting.value = true
  try {
    await factoryStore.sendToBranch(factoryId, transferForm)
    showSendToBranch.value = false
    toast.success('Permintaan pengiriman berhasil dibuat')
    // Reset form
    Object.assign(transferForm, { to_branch_id: '', items: [{ product_id: '', quantity: 0 }], notes: '' })
  } catch (err) {
    toast.error('Gagal membuat pengiriman: ' + err)
  } finally {
    submitting.value = false
  }
}

const stockColumns = [
  { key: 'product.sku', label: 'SKU' },
  { key: 'product.name', label: 'Produk' },
  { key: 'quantity', label: 'Stok Gudang' },
  { key: 'actions', label: '' }
]

const productionColumns = [
  { key: 'production_date', label: 'Tanggal', type: 'datetime' },
  { key: 'product.name', label: 'Produk' },
  { key: 'quantity', label: 'Qty' },
  { key: 'actions', label: '' }
]
</script>
