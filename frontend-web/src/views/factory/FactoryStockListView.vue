<template>
  <div class="p-6 space-y-6 bg-[#f8fafc] min-h-screen">
    <!-- Header -->
    <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 bg-white p-6 rounded-3xl shadow-sm border border-slate-100">
      <div>
        <div class="flex items-center gap-2 text-xs font-bold text-primary uppercase tracking-[0.2em] mb-1">
          <Boxes class="h-4 w-4" />
          <span>Central Inventory & Production</span>
        </div>
        <h1 class="text-2xl font-black tracking-tight text-slate-900">Manajemen Stok & Produksi Global</h1>
        <p class="text-sm text-slate-500 mt-0.5">Monitoring stok dan hasil produksi di seluruh jaringan pabrik Wowin.</p>
      </div>
      <div class="flex items-center gap-3">
        <Button variant="outline" class="rounded-xl border-slate-200" @click="refreshData">
          <RefreshCw class="mr-2 h-4 w-4" :class="{ 'animate-spin': factoryStore.loading }" /> Segarkan
        </Button>
        <Button @click="router.push('/factory/products')" class="rounded-xl shadow-lg shadow-primary/10 font-bold bg-primary hover:bg-primary/90">
          <Package class="mr-2 h-4 w-4" /> Data Produk
        </Button>
      </div>
    </div>

    <!-- Split Content -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
      
      <!-- LEFT: GLOBAL STOCK -->
      <div class="space-y-6">
        <div class="flex items-center justify-between px-2">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-2xl bg-blue-50 flex items-center justify-center text-blue-600">
              <Boxes class="h-5 w-5" />
            </div>
            <div>
               <h2 class="text-lg font-bold text-slate-900 leading-tight">Manajemen Stok Global</h2>
               <p class="text-[10px] text-slate-400 font-bold uppercase tracking-widest mt-0.5">Seluruh Lokasi Pabrik</p>
            </div>
          </div>
          <div class="flex items-center gap-2">
            <Search class="h-4 w-4 text-slate-300" />
            <input v-model="stockSearch" placeholder="Cari SKU/Produk..." class="text-xs bg-white border-none rounded-lg px-3 py-1.5 focus:ring-1 focus:ring-primary/20 w-40 outline-none" />
          </div>
        </div>

        <Card class="border-none shadow-sm bg-white rounded-3xl overflow-hidden">
          <DataTable :columns="stockColumns" :data="filteredStock" :isLoading="factoryStore.loading" class="border-none">
            <template #cell-factory_name="{ row }">
              <Badge variant="outline" class="rounded-lg text-[10px] border-slate-100 bg-slate-50 text-slate-500 py-0 px-2 font-bold uppercase">
                {{ (row as any).factory?.name }}
              </Badge>
            </template>
            <template #cell-quantity="{ row }">
              <div class="flex items-center gap-2">
                <span class="text-base font-black text-slate-900">{{ (row as any).quantity }}</span>
                <span class="text-[9px] font-black text-slate-400 uppercase tracking-tighter">{{ (row as any).product?.unit }}</span>
              </div>
            </template>
            <template #cell-actions="{ row }">
              <Button variant="ghost" size="sm" @click="openAdjustStock(row)" class="h-8 w-8 p-0 rounded-lg text-slate-300 hover:text-primary">
                <Settings2 class="h-4 w-4" />
              </Button>
            </template>
          </DataTable>
        </Card>
      </div>

      <!-- RIGHT: GLOBAL PRODUCTION LOGS -->
      <div class="space-y-6">
        <div class="flex items-center justify-between px-2">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-2xl bg-emerald-50 flex items-center justify-center text-emerald-600">
              <Activity class="h-5 w-5" />
            </div>
            <div>
               <h2 class="text-lg font-bold text-slate-900 leading-tight">Log Produksi Global</h2>
               <p class="text-[10px] text-slate-400 font-bold uppercase tracking-widest mt-0.5">Aktivitas Terkini</p>
            </div>
          </div>
          <Button size="sm" @click="openLogProduction" class="rounded-xl shadow-md shadow-primary/5 text-xs h-9 px-4">
            <Plus class="mr-1 h-3.5 w-3.5" /> Log Produksi
          </Button>
        </div>

        <Card class="border-none shadow-sm bg-white rounded-3xl overflow-hidden">
          <DataTable :columns="productionColumns" :data="factoryStore.allProductionHistory" :isLoading="factoryStore.loading" class="border-none">
            <template #cell-factory_name="{ row }">
              <span class="text-[11px] font-bold text-slate-400 uppercase">{{ (row as any).factory?.name }}</span>
            </template>
            <template #cell-quantity="{ row }">
              <div class="flex flex-col">
                <span class="font-black text-emerald-600">+{{ (row as any).quantity }} PCS</span>
                <span v-if="(row as any).carton_count" class="text-[9px] font-bold text-slate-400">
                  ({{ (row as any).carton_count }} Karton @ {{ (row as any).pieces_per_carton }} isi)
                </span>
              </div>
            </template>
            <template #cell-actions="{ row }">
              <div class="flex items-center gap-0.5">
                <Button variant="ghost" size="icon" @click="openEditProduction(row)" class="h-7 w-7 text-slate-300 hover:text-primary">
                  <Edit2 class="h-3 w-3" />
                </Button>
                <Button variant="ghost" size="icon" @click="handleDeleteProduction(row)" class="h-7 w-7 text-slate-300 hover:text-destructive">
                  <Trash2 class="h-3 w-3" />
                </Button>
              </div>
            </template>
          </DataTable>
        </Card>
      </div>
    </div>

    <!-- Modals (Adjust Stock) -->
    <div v-if="showAdjustStock" class="fixed inset-0 bg-slate-900/40 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <Card class="w-full max-w-md shadow-2xl rounded-3xl overflow-hidden border-none animate-in zoom-in-95 duration-200">
        <CardHeader class="p-6 border-b bg-white">
          <CardTitle class="text-xl font-bold">Koreksi Stok</CardTitle>
          <CardDescription>Sesuaikan jumlah stok secara manual untuk pabrik {{ selectedStock?.factory?.name }}.</CardDescription>
        </CardHeader>
        <CardContent class="p-6 space-y-4 bg-white">
          <div class="p-4 bg-blue-50 rounded-2xl border border-blue-100 flex justify-between items-center">
            <div>
              <p class="text-xs font-bold text-blue-600 uppercase tracking-widest mb-1">Produk</p>
              <p class="text-sm font-bold text-slate-900">{{ selectedStock?.product?.name }}</p>
            </div>
            <div class="text-right">
              <p class="text-xs font-bold text-slate-400 uppercase">Stok Sekarang</p>
              <p class="text-lg font-black text-slate-900">{{ selectedStock?.quantity }}</p>
            </div>
          </div>
          <div class="space-y-2">
            <label class="text-sm font-bold text-slate-700">Jumlah Stok Baru</label>
            <input type="number" v-model="adjustStockForm.quantity" class="w-full px-4 py-3 bg-slate-50 border border-slate-100 rounded-2xl text-sm outline-none focus:ring-2 focus:ring-primary/20" />
          </div>
          <div class="space-y-2">
            <label class="text-sm font-bold text-slate-700">Alasan</label>
            <textarea v-model="adjustStockForm.reason" placeholder="Audit stok, Barang rusak, dsb..." class="w-full px-4 py-3 bg-slate-50 border border-slate-100 rounded-2xl text-sm outline-none focus:ring-2 focus:ring-primary/20 resize-none" rows="2"></textarea>
          </div>
        </CardContent>
        <CardFooter class="bg-slate-50/50 p-6 flex justify-end gap-3">
          <Button variant="ghost" @click="showAdjustStock = false" class="rounded-xl font-bold">Batal</Button>
          <Button @click="handleAdjustStockSubmit" :loading="submitting" class="rounded-xl px-8 shadow-lg shadow-primary/20 font-bold bg-blue-600 hover:bg-blue-700 text-white">
            Simpan Perubahan
          </Button>
        </CardFooter>
      </Card>
    </div>

    <!-- Log Production Modal -->
    <div v-if="showLogProduction" class="fixed inset-0 bg-slate-900/60 backdrop-blur-md z-50 flex items-center justify-center p-2 sm:p-4">
      <Card class="w-full max-w-2xl shadow-2xl rounded-[2rem] border-none animate-in fade-in zoom-in-95 duration-300 bg-white flex flex-col max-h-[95vh]">
        <CardHeader class="p-5 sm:p-6 border-b">
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-3">
              <div class="w-10 h-10 rounded-2xl bg-primary/10 flex items-center justify-center text-primary">
                <Plus v-if="!isEditingProduction" class="h-5 w-5" />
                <Edit2 v-else class="h-5 w-5" />
              </div>
              <div>
                <CardTitle class="text-lg font-black text-slate-900">{{ isEditingProduction ? 'Edit Log Produksi' : 'Catat Produksi Global' }}</CardTitle>
                <CardDescription class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Sinkronisasi stok otomatis</CardDescription>
              </div>
            </div>
            <Button variant="ghost" size="icon" @click="showLogProduction = false" class="rounded-xl text-slate-400 hover:text-slate-900">
              <X class="h-5 w-5" />
            </Button>
          </div>
        </CardHeader>
        
        <CardContent class="p-5 sm:p-6 space-y-6 overflow-y-auto custom-scrollbar flex-1 pb-40">
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-5">
            <div class="space-y-1.5">
              <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Pabrik Produksi</label>
              <div class="relative">
                <select v-model="productionForm.factory_id" :disabled="isEditingProduction" class="w-full px-4 py-3 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold outline-none appearance-none focus:ring-4 focus:ring-primary/5 transition-all disabled:opacity-50">
                  <option value="" disabled>Pilih Pabrik...</option>
                  <option v-for="f in factoryStore.factories" :key="f.id" :value="f.id">{{ f.name }}</option>
                </select>
                <div class="absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none text-slate-400">
                  <Settings2 class="h-4 w-4" />
                </div>
              </div>
            </div>
            <div class="space-y-1.5">
              <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Pilih Produk</label>
              <div class="relative">
                <select v-model="productionForm.product_id" :disabled="isEditingProduction" class="w-full px-4 py-3 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold outline-none appearance-none focus:ring-4 focus:ring-primary/5 transition-all disabled:opacity-50">
                  <option value="" disabled>Pilih Produk...</option>
                  <option v-for="p in factoryStore.products" :key="p.id" :value="p.id">{{ p.name }}</option>
                </select>
                <div class="absolute right-4 top-1/2 -translate-y-1/2 pointer-events-none text-slate-400">
                  <Package class="h-4 w-4" />
                </div>
              </div>
            </div>
          </div>

          <!-- Modern Carton Calculator -->
          <div class="p-5 bg-slate-50/50 rounded-[2rem] border border-slate-100 flex flex-col gap-4">
            <div class="flex items-center gap-2 text-primary font-black text-[10px] uppercase tracking-widest px-1">
               <Boxes class="h-3.5 w-3.5" />
               <span>Packaging Unit (Karton)</span>
            </div>
            
            <div class="grid grid-cols-2 gap-4">
              <div class="p-4 bg-white rounded-2xl border border-slate-100 shadow-sm focus-within:ring-2 focus-within:ring-primary/20 transition-all">
                <label class="text-[9px] font-black text-slate-400 uppercase tracking-widest mb-1 block">Jumlah Karton</label>
                <input type="number" v-model="productionForm.carton_count" @input="syncQuantity" class="w-full bg-transparent border-none p-0 text-base font-black outline-none" placeholder="0" />
              </div>
              <div class="p-4 bg-white rounded-2xl border border-slate-100 shadow-sm focus-within:ring-2 focus-within:ring-primary/20 transition-all">
                <label class="text-[9px] font-black text-slate-400 uppercase tracking-widest mb-1 block">Isi per Karton</label>
                <input type="number" v-model="productionForm.pieces_per_carton" @input="syncQuantity" class="w-full bg-transparent border-none p-0 text-base font-black outline-none" placeholder="0" />
              </div>
            </div>

            <div class="p-4 bg-primary rounded-2xl shadow-lg shadow-primary/10 flex items-center justify-between text-white">
               <div class="flex flex-col">
                 <span class="text-[9px] font-black text-white/60 uppercase tracking-widest">Total Produksi (PCS)</span>
                 <input type="number" v-model="productionForm.quantity" class="text-xl font-black bg-transparent border-none p-0 outline-none w-32 placeholder:text-white/30" />
               </div>
               <div class="w-10 h-10 rounded-xl bg-white/10 flex items-center justify-center">
                 <Activity class="h-5 w-5" />
               </div>
            </div>
          </div>

          <!-- Searchable Operator Dropdown -->
          <div class="space-y-1.5 relative" ref="operatorDropdownRef">
            <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Operator Produksi</label>
            <div class="relative group">
              <div class="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-primary transition-colors">
                <User class="h-4 w-4" />
              </div>
              <input 
                type="text" 
                v-model="operatorSearch" 
                @focus="showOperatorDropdown = true"
                placeholder="Cari Operator (Nama/ID)..." 
                class="w-full pl-11 pr-11 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold outline-none focus:ring-4 focus:ring-primary/5 transition-all"
              />
              <button v-if="operatorSearch" @click="clearOperator" class="absolute right-4 top-1/2 -translate-y-1/2 text-slate-300 hover:text-rose-500 transition-colors">
                <X class="h-4 w-4" />
              </button>

              <!-- Dropdown - Always visible below the input in scrollable container -->
              <div v-if="showOperatorDropdown" class="absolute top-full left-0 right-0 mt-2 bg-white border border-slate-100 rounded-[2rem] shadow-2xl z-[70] overflow-hidden max-h-56 overflow-y-auto custom-scrollbar border-t-4 border-t-primary animate-in fade-in slide-in-from-top-2 duration-200">
                <div v-if="filteredOperators.length === 0" class="p-6 text-center">
                  <p class="text-xs font-bold text-slate-400 uppercase">Tidak ditemukan</p>
                </div>
                <div v-else>
                  <div v-for="emp in filteredOperators" :key="emp.id" @click="selectOperator(emp)" class="px-5 py-3 hover:bg-slate-50 cursor-pointer flex items-center justify-between group/item border-b border-slate-50 last:border-none">
                    <div>
                      <p class="text-[11px] font-black text-slate-900 group-hover/item:text-primary transition-colors uppercase tracking-tight">{{ emp.first_name }} {{ emp.last_name }}</p>
                      <p class="text-[9px] text-slate-400 font-bold tracking-widest">{{ emp.employee_id_number }}</p>
                    </div>
                    <div class="opacity-0 group-hover/item:opacity-100 transition-opacity">
                      <Badge class="bg-primary/10 text-primary text-[8px] font-black uppercase border-none h-4">Pilih</Badge>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div class="space-y-1.5">
            <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Catatan Tambahan</label>
            <textarea v-model="productionForm.notes" placeholder="Tambahkan keterangan..." class="w-full px-5 py-3 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold outline-none focus:ring-4 focus:ring-primary/5 transition-all resize-none" rows="2"></textarea>
          </div>
        </CardContent>

        <CardFooter class="p-5 sm:p-6 border-t bg-white rounded-b-[2rem] flex flex-col sm:flex-row gap-3">
          <Button variant="ghost" @click="showLogProduction = false" class="rounded-2xl font-bold w-full sm:w-auto order-2 sm:order-1 h-12">Batal</Button>
          <Button @click="handleProductionSubmit" :loading="submitting" class="rounded-2xl px-12 shadow-xl shadow-primary/20 font-black bg-primary hover:bg-primary/90 text-white w-full sm:w-auto flex-1 order-1 sm:order-2 h-12">
            {{ isEditingProduction ? 'Update Log' : 'Simpan Produksi' }}
          </Button>
        </CardFooter>
      </Card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref, reactive, computed, watch } from 'vue'
import { useRouter } from 'vue-router'
import { onClickOutside } from '@vueuse/core'
import { useFactoryStore } from '@/stores/factory'
import { useMasterDataStore } from '@/stores/masterData'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import DataTable from '@/components/DataTable.vue'
import { 
  Boxes, 
  Activity, 
  Plus, 
  Search, 
  RefreshCw, 
  Package, 
  Settings2, 
  Edit2, 
  Trash2,
  User,
  X 
} from 'lucide-vue-next'

const router = useRouter()
const factoryStore = useFactoryStore()
const masterStore = useMasterDataStore()
const stockSearch = ref('')
const submitting = ref(false)

// Modals State
const showAdjustStock = ref(false)
const showLogProduction = ref(false)
const isEditingProduction = ref(false)
const selectedStock = ref<any>(null)
const currentProductionId = ref('')

// Searchable Operator State
const operatorSearch = ref('')
const showOperatorDropdown = ref(false)
const operatorDropdownRef = ref(null)

onClickOutside(operatorDropdownRef, () => {
  showOperatorDropdown.value = false
})

const filteredOperators = computed(() => {
  const query = (operatorSearch.value || '').toLowerCase().trim()
  const employees = masterStore.employees || []
  if (!query) return employees
  return employees.filter(emp => {
    const fullName = `${emp.first_name || ''} ${emp.last_name || ''}`.toLowerCase()
    const empId = (emp.employee_id_number || '').toLowerCase()
    return fullName.includes(query) || empId.includes(query)
  })
})

const selectOperator = (emp: any) => {
  productionForm.employee_id = emp.id
  operatorSearch.value = `${emp.first_name || ''} ${emp.last_name || ''}`.trim()
  showOperatorDropdown.value = false
}

const clearOperator = () => {
  productionForm.employee_id = ''
  operatorSearch.value = ''
  showOperatorDropdown.value = true
}

// Forms
const adjustStockForm = reactive({ quantity: 0, reason: '' })
const productionForm = reactive({ 
  factory_id: '', 
  product_id: '', 
  quantity: 0, 
  carton_count: 0,
  pieces_per_carton: 0,
  employee_id: '', 
  notes: '' 
})


const refreshData = async () => {
  await Promise.all([
    factoryStore.fetchFactories(),
    factoryStore.fetchProducts(),
    factoryStore.fetchAllInventory(),
    factoryStore.fetchAllProductionHistory(),
    masterStore.fetchEmployees()
  ])
}

onMounted(refreshData)

const filteredStock = computed(() => {
  const query = (stockSearch.value || '').toLowerCase()
  return (factoryStore.allInventory || []).filter(item => {
    const name = (item.product?.name || '').toLowerCase()
    const sku = (item.product?.sku || '').toLowerCase()
    return name.includes(query) || sku.includes(query)
  })
})

const syncQuantity = () => {
  if (productionForm.carton_count > 0 && productionForm.pieces_per_carton > 0) {
    productionForm.quantity = productionForm.carton_count * productionForm.pieces_per_carton
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
    await factoryStore.adjustStock(selectedStock.value.factory_id, {
      product_id: selectedStock.value.product_id,
      quantity: adjustStockForm.quantity,
      reason: adjustStockForm.reason
    })
    await factoryStore.fetchAllInventory()
    showAdjustStock.value = false
  } catch (err) {
    alert(err)
  } finally {
    submitting.value = false
  }
}

const openLogProduction = () => {
  isEditingProduction.value = false
  operatorSearch.value = ''
  showOperatorDropdown.value = false
  if (masterStore.employees.length === 0) masterStore.fetchEmployees()
  Object.assign(productionForm, { 
    factory_id: '', 
    product_id: '', 
    quantity: 0, 
    carton_count: 0,
    pieces_per_carton: 0,
    employee_id: '', 
    notes: '' 
  })
  showLogProduction.value = true
}

const openEditProduction = (item: any) => {
  isEditingProduction.value = true
  currentProductionId.value = item.id
  operatorSearch.value = `${item.employee?.first_name || ''} ${item.employee?.last_name || ''}`.trim()
  showOperatorDropdown.value = false
  if (masterStore.employees.length === 0) masterStore.fetchEmployees()
  Object.assign(productionForm, {
    factory_id: item.factory_id,
    product_id: item.product_id,
    quantity: item.quantity,
    carton_count: item.carton_count || 0,
    pieces_per_carton: item.pieces_per_carton || 0,
    employee_id: item.employee_id,
    notes: item.notes
  })
  showLogProduction.value = true
}

const handleProductionSubmit = async () => {
  if (!productionForm.factory_id || !productionForm.product_id || productionForm.quantity <= 0 || !productionForm.employee_id) {
    alert('Lengkapi data produksi dan operator!')
    return
  }
  submitting.value = true
  try {
    if (isEditingProduction.value) {
      await factoryStore.updateProductionLog(productionForm.factory_id, currentProductionId.value, productionForm)
    } else {
      await factoryStore.logProduction(productionForm.factory_id, productionForm)
    }
    await refreshData()
    showLogProduction.value = false
  } catch (err) {
    alert(err)
  } finally {
    submitting.value = false
  }
}

const handleDeleteProduction = async (item: any) => {
  if (!confirm('Hapus log produksi global ini? Stok di pabrik terkait akan dikurangi kembali.')) return
  try {
    await factoryStore.deleteProductionLog(item.factory_id, item.id)
    await refreshData()
  } catch (err) {
    alert(err)
  }
}

const stockColumns = [
  { key: 'factory_name', label: 'Lokasi Pabrik' },
  { key: 'product.name', label: 'Produk' },
  { key: 'quantity', label: 'Stok' },
  { key: 'actions', label: '' }
]

const productionColumns = [
  { key: 'production_date', label: 'Tanggal', type: 'datetime' },
  { key: 'factory_name', label: 'Pabrik' },
  { key: 'product.name', label: 'Produk' },
  { key: 'quantity', label: 'Qty' },
  { key: 'actions', label: '' }
]
</script>

<style scoped>
.custom-scrollbar::-webkit-scrollbar {
  width: 5px;
}
.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background: #e2e8f0;
  border-radius: 10px;
}
</style>
