<template>
  <div class="p-6 space-y-6">
    <div class="flex justify-between items-center">
      <div>
        <h1 class="text-3xl font-bold tracking-tight">Perpindahan Barang (Sales)</h1>
        <p class="text-muted-foreground">Manajemen transfer barang ke sales dan retur barang dari sales.</p>
      </div>
      <Button @click="openForm" class="flex gap-2">
        <Plus class="h-5 w-5" />
        Buat Perpindahan
      </Button>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-12 gap-8">
      <!-- Left: History -->
      <div class="lg:col-span-8 space-y-4">
        <h2 class="text-xl font-bold flex items-center gap-2">
          <History class="h-5 w-5 text-primary" />
          Riwayat Perpindahan
        </h2>
        <Card class="border-none shadow-sm overflow-hidden">
          <DataTable :columns="columns" :data="transferStore.transfers">
            <template #cell-type="{ row }">
              <span v-if="row.type === 'TRANSFER'" class="flex items-center gap-1 text-blue-600 font-bold">
                <ArrowRight class="h-3 w-3" /> TRANSFER
              </span>
              <span v-else class="flex items-center gap-1 text-amber-600 font-bold">
                <ArrowLeft class="h-3 w-3" /> RETUR
              </span>
            </template>
            <template #cell-employee_name="{ row }">
              {{ row.employee?.first_name }} {{ row.employee?.last_name }}
            </template>
            <template #cell-quantity="{ row }">
              <strong>{{ row.quantity }} {{ row.product?.unit }}</strong>
            </template>
            <template #cell-status="{ row }">
              <span :class="[
                'px-2 py-1 rounded-full text-[10px] font-bold',
                row.status === 'PENDING' ? 'bg-slate-100 text-slate-600' :
                row.status === 'COMPLETED' ? 'bg-green-100 text-green-600' :
                'bg-red-100 text-red-600'
              ]">
                {{ row.status }}
              </span>
            </template>
            <template #cell-actions="{ row }">
              <div v-if="row.status === 'PENDING'" class="flex gap-1">
                <Button size="sm" class="h-7 px-2 text-[10px] bg-green-600 hover:bg-green-700" @click="handleComplete(row.id)">Selesai</Button>
                <Button size="sm" variant="outline" class="h-7 px-2 text-[10px] text-red-600 border-red-200 hover:bg-red-50" @click="handleCancel(row.id)">Batal</Button>
              </div>
              <Button v-else variant="ghost" size="icon" class="h-8 w-8 text-slate-400 hover:text-red-600" @click="handleDelete(row.id)">
                <Trash2 class="h-4 w-4" />
              </Button>
            </template>
          </DataTable>
        </Card>
      </div>

      <!-- Right: Sales Stock Checker -->
      <div class="lg:col-span-4 space-y-4">
        <h2 class="text-xl font-bold flex items-center gap-2">
          <UserSquare2 class="h-5 w-5 text-primary" />
          Cek Stok Salesman
        </h2>
        <Card>
          <CardHeader>
            <CardDescription>Pilih salesman untuk melihat stok yang mereka bawa.</CardDescription>
          </CardHeader>
          <CardContent class="space-y-4">
            <div class="space-y-2">
              <label class="text-sm font-medium">Salesman</label>
              <select v-model="selectedSalesman" class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm" @change="fetchSalesStock">
                <option value="">Pilih Salesman</option>
                <option v-for="emp in masterStore.employees" :key="emp.id" :value="emp.id">
                  {{ emp.first_name }} {{ emp.last_name }}
                </option>
              </select>
            </div>

            <div v-if="transferStore.salesStock.length > 0" class="space-y-2 border-t pt-4">
              <div v-for="stock in transferStore.salesStock" :key="stock.id" class="flex justify-between items-center p-2 bg-slate-50 rounded-lg">
                <div>
                  <p class="font-bold text-sm">{{ stock.product?.name }}</p>
                  <p class="text-xs text-slate-400">{{ stock.product?.sku }}</p>
                </div>
                <div class="text-right">
                  <p class="font-black text-primary">{{ stock.quantity }} {{ stock.product?.unit }}</p>
                </div>
              </div>
            </div>
            <div v-else-if="selectedSalesman" class="text-center py-8 text-slate-400 text-sm italic">
              Tidak ada stok yang dibawa.
            </div>
          </CardContent>
        </Card>
      </div>
    </div>

    <!-- Create Transfer/Return Modal -->
    <div v-if="showForm" class="fixed inset-0 bg-background/80 backdrop-blur-sm z-50 flex items-center justify-center p-4">
       <Card class="w-full max-w-lg shadow-2xl border-2">
         <CardHeader>
           <CardTitle>Buat Perpindahan Barang</CardTitle>
           <CardDescription>Pindahkan stok dari gudang ke sales atau retur dari sales ke gudang.</CardDescription>
         </CardHeader>
         <CardContent class="space-y-4">
           <div class="grid grid-cols-2 gap-4">
             <div class="space-y-2">
               <label class="text-sm font-medium">Tipe Perpindahan</label>
               <select v-model="form.type" class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm">
                 <option value="TRANSFER">TRANSFER (Gudang -> Sales)</option>
                 <option value="RETURN">RETUR (Sales -> Gudang)</option>
               </select>
             </div>
             <div class="space-y-2">
               <label class="text-sm font-medium">Salesman</label>
               <select v-model="form.employee_id" class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm">
                 <option value="">Pilih Salesman</option>
                 <option v-for="emp in masterStore.employees" :key="emp.id" :value="emp.id">
                   {{ emp.first_name }} {{ emp.last_name }} ({{ emp.employee_id_number }})
                 </option>
               </select>
             </div>
           </div>

           <div class="space-y-2">
             <label class="text-sm font-medium">Produk</label>
             <select v-model="form.product_id" class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm">
               <option value="">Pilih Produk</option>
               <option v-for="item in warehouseStore.inventory" :key="item.product_id" :value="item.product_id">
                 {{ item.product?.name }} (Stok: {{ item.quantity }})
               </option>
             </select>
           </div>

           <div class="space-y-2">
             <label class="text-sm font-medium">Jumlah</label>
             <input type="number" v-model="form.quantity" class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm" />
           </div>

           <div class="space-y-2">
             <label class="text-sm font-medium">Catatan</label>
             <textarea v-model="form.notes" placeholder="Contoh: Stok untuk Kanvas Area A" class="flex min-h-[80px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm"></textarea>
           </div>
         </CardContent>
         <CardFooter class="flex justify-end gap-2 bg-slate-50 p-4 border-t rounded-b-lg">
           <Button variant="outline" class="font-bold" @click="showForm = false">Batal</Button>
           <Button class="font-bold px-6" @click="handleSubmit" :loading="loading">Simpan & Ajukan</Button>
         </CardFooter>
       </Card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref, reactive, watch } from 'vue'
import { useSalesTransferStore } from '@/stores/salesTransfer'
import { useWarehouseStore } from '@/stores/warehouse'
import { useMasterDataStore } from '@/stores/masterData'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card/index'
import DataTable from '@/components/DataTable.vue'
import { Plus, History, UserSquare2, ArrowRight, ArrowLeft, Trash2, Search, X } from 'lucide-vue-next'

const transferStore = useSalesTransferStore()
const warehouseStore = useWarehouseStore()
const masterStore = useMasterDataStore()

const showForm = ref(false)
const loading = ref(false)
const selectedSalesman = ref('')

const form = reactive({
  employee_id: '',
  product_id: '',
  quantity: 1,
  type: 'TRANSFER',
  notes: ''
})

const openForm = async () => {
  showForm.value = true
  loading.value = true
  try {
    await Promise.all([
      masterStore.fetchEmployees(true),
      warehouseStore.fetchInventory()
    ])
  } finally {
    loading.value = false
  }
}

const columns = [
  { key: 'type', label: 'Tipe' },
  { key: 'employee_name', label: 'Salesman' },
  { key: 'product.name', label: 'Produk' },
  { key: 'quantity', label: 'Jumlah' },
  { key: 'status', label: 'Status' },
  { key: 'transfer_date', label: 'Tanggal', type: 'datetime' },
  { key: 'actions', label: 'Aksi' }
]

const fetchSalesStock = () => {
  if (selectedSalesman.value) {
    transferStore.fetchSalesStock(selectedSalesman.value)
  }
}

const handleSubmit = async () => {
  if (!form.employee_id || !form.product_id || form.quantity <= 0) {
    alert('Mohon lengkapi semua data.')
    return
  }
  
  loading.value = true
  try {
    await transferStore.createTransfer(form)
    showForm.value = false
    // Reset form
    form.employee_id = ''
    form.product_id = ''
    form.quantity = 0
    form.notes = ''
  } catch (err) {
    alert(err)
  } finally {
    loading.value = false
  }
}

const handleComplete = async (id: string) => {
  if (!confirm('Selesaikan perpindahan ini? Stok akan dipotong/ditambah.')) return
  try {
    await transferStore.completeTransfer(id)
    warehouseStore.fetchInventory() // Refresh warehouse stock
    if (selectedSalesman.value) fetchSalesStock()
  } catch (err) {
    alert(err)
  }
}

const handleCancel = async (id: string) => {
  if (!confirm('Batalkan perpindahan ini?')) return
  try {
    await transferStore.cancelTransfer(id)
  } catch (err) {
    alert(err)
  }
}

const handleDelete = async (id: string) => {
  if (!confirm('Hapus log perpindahan ini?')) return
  try {
    await transferStore.deleteTransfer(id)
  } catch (err) {
    alert(err)
  }
}

watch(() => masterStore.selectedBranchId, () => {
  transferStore.fetchTransfers()
  warehouseStore.fetchInventory()
})

onMounted(() => {
  transferStore.fetchTransfers()
  warehouseStore.fetchInventory()
  masterStore.fetchEmployees()
})
</script>
