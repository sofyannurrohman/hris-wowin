<template>
  <div class="p-6 space-y-6">
    <div class="flex justify-between items-center">
      <div>
        <h1 class="text-3xl font-bold tracking-tight">Delivery Management</h1>
        <p class="text-muted-foreground">Manage task orders delivery batches and routing.</p>
      </div>
      <div class="flex gap-2">
        <Button variant="outline" @click="fetchData">
          <RefreshCw class="h-4 w-4 mr-2" :class="{ 'animate-spin': loading }" />
          Refresh
        </Button>
        <Button class="bg-primary shadow-lg shadow-primary/20" @click="showCreateBatch = true">
          <Truck class="h-4 w-4 mr-2" />
          Create New Batch
        </Button>
      </div>
    </div>

    <!-- Active Batches -->
    <div class="grid grid-cols-1 gap-6">
      <Card>
        <CardHeader>
          <CardTitle>Active Delivery Batches</CardTitle>
          <CardDescription>Track ongoing and pending deliveries.</CardDescription>
        </CardHeader>
        <CardContent>
          <DataTable :columns="batchColumns" :data="deliveryStore.batches">
            <template #cell-delivery_order_no="{ row }">
              <div class="flex items-center gap-2">
                <span class="font-mono text-xs font-bold">{{ row.delivery_order_no }}</span>
                <Button size="icon" variant="ghost" class="h-8 w-8" @click="printDO(row)">
                  <Printer class="h-4 w-4" />
                </Button>
              </div>
            </template>
            <template #cell-status="{ row }">
               <Badge :variant="row.status === 'COMPLETED' ? 'success' : 'warning'">{{ row.status }}</Badge>
            </template>
          </DataTable>
        </CardContent>
      </Card>
    </div>

    <!-- Create Batch Modal -->
    <div v-if="showCreateBatch" class="fixed inset-0 bg-background/80 backdrop-blur-sm z-50 flex items-center justify-center p-4">
       <Card class="w-full max-w-4xl max-h-[90vh] overflow-hidden flex flex-col shadow-2xl border-2 border-primary/20">
         <CardHeader class="bg-primary text-primary-foreground">
           <CardTitle class="flex items-center gap-2">
             <PackagePlus class="h-6 w-6" />
             Delivery Batch Builder
           </CardTitle>
           <CardDescription class="text-primary-foreground/70">Select validated orders to include in this delivery trip.</CardDescription>
         </CardHeader>
         
         <div class="flex-1 overflow-y-auto p-6 grid grid-cols-1 md:grid-cols-2 gap-6">
           <!-- Step 1: Assign Resource -->
           <div class="space-y-4">
             <h3 class="text-sm font-black uppercase tracking-widest text-slate-400">1. Assign Logistics</h3>
             <div class="space-y-2">
               <label class="text-xs font-bold">Select Driver</label>
               <select v-model="form.driver_id" class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm focus:ring-2 focus:ring-primary">
                 <option v-for="d in drivers" :key="d.id" :value="d.id">{{ d.first_name }} {{ d.last_name }}</option>
               </select>
             </div>
             <div class="space-y-2">
               <label class="text-xs font-bold">Select Vehicle</label>
               <select v-model="form.vehicle_id" class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm focus:ring-2 focus:ring-primary">
                 <option v-for="v in vehicles" :key="v.id" :value="v.id">{{ v.license_plate }} - {{ v.model }}</option>
               </select>
             </div>
           </div>

           <!-- Step 2: Select Orders -->
           <div class="space-y-4">
             <h3 class="text-sm font-black uppercase tracking-widest text-slate-400">2. Select Task Orders ({{ selectedOrders.length }})</h3>
             <div class="border rounded-xl divide-y max-h-[300px] overflow-y-auto bg-slate-50">
               <div v-for="order in deliveryStore.pendingOrders" :key="order.id" class="p-3 flex items-center gap-3 hover:bg-white transition-colors">
                 <input type="checkbox" v-model="selectedOrders" :value="order.id" class="w-4 h-4 rounded text-primary" />
                 <div class="flex-1 min-w-0">
                   <p class="text-sm font-bold truncate">{{ order.store?.name }}</p>
                   <p class="text-[10px] text-slate-500 font-mono">{{ order.receipt_no }} • Rp {{ order.total_amount.toLocaleString() }}</p>
                 </div>
               </div>
               <div v-if="deliveryStore.pendingOrders.length === 0" class="p-8 text-center text-slate-400">
                 <PackageOpen class="h-8 w-8 mx-auto mb-2 opacity-20" />
                 <p class="text-xs">No validated orders available.</p>
               </div>
             </div>
           </div>
         </div>

         <CardFooter class="bg-slate-50 p-6 border-t flex justify-between">
           <Button variant="ghost" class="font-bold text-slate-500" @click="showCreateBatch = false">CANCEL</Button>
           <Button class="font-black px-8" :disabled="!isFormValid" @click="handleCreateBatch" :loading="isSubmitting">
             GENERATE SURAT JALAN
           </Button>
         </CardFooter>
       </Card>
    </div>

    <!-- DO Printing Modal (SJ Preview) -->
    <div v-if="selectedDO" class="fixed inset-0 bg-background/80 backdrop-blur-sm z-50 flex items-center justify-center p-4">
       <Card class="w-full max-w-2xl bg-white shadow-2xl border-0 overflow-hidden">
         <div class="bg-slate-900 text-white p-8 flex justify-between items-center">
            <div>
              <h2 class="text-2xl font-black tracking-tighter italic">SURAT JALAN PENGIRIMAN</h2>
              <p class="text-xs opacity-60 font-mono tracking-widest uppercase">Delivery Order #{{ selectedDO.delivery_order_no }}</p>
            </div>
            <img :src="`https://api.qrserver.com/v1/create-qr-code/?size=100x100&data=${selectedDO.delivery_order_no}`" class="w-16 h-16 border-2 border-white/20 rounded" />
         </div>
         
         <CardContent class="p-10 space-y-8">
            <div class="flex justify-between border-b pb-6 text-sm">
              <div class="space-y-1">
                <p class="text-[10px] font-black text-slate-400 uppercase tracking-widest">LOGISTICS INFO</p>
                <p><span class="font-bold text-slate-400">DRIVER:</span> {{ selectedDO.driver?.first_name }}</p>
                <p><span class="font-bold text-slate-400">VEHICLE:</span> {{ selectedDO.vehicle?.license_plate }} ({{ selectedDO.vehicle?.model }})</p>
              </div>
              <div class="text-right space-y-1">
                <p class="text-[10px] font-black text-slate-400 uppercase tracking-widest">DATE GENERATED</p>
                <p class="font-bold">{{ new Date(selectedDO.created_at).toLocaleDateString('id-ID', { dateStyle: 'full' }) }}</p>
              </div>
            </div>

            <div class="space-y-4">
              <h3 class="text-xs font-black text-slate-400 uppercase tracking-widest">DESTINATION LIST (TASK ORDERS)</h3>
              <div class="border-2 border-slate-100 rounded-2xl overflow-hidden">
                <table class="w-full text-left text-sm">
                  <thead class="bg-slate-50 border-b">
                    <tr>
                      <th class="p-3 font-bold">#</th>
                      <th class="p-3 font-bold">STORE NAME</th>
                      <th class="p-3 font-bold text-right">TOTAL</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y">
                    <tr v-for="(item, idx) in selectedDO.items" :key="item.id">
                      <td class="p-3 text-slate-400">{{ idx + 1 }}</td>
                      <td class="p-3">
                        <p class="font-bold">{{ item.sales_transaction?.store?.name }}</p>
                        <p class="text-[10px] text-slate-500">{{ item.sales_transaction?.store?.address }}</p>
                      </td>
                      <td class="p-3 text-right font-mono">Rp {{ item.sales_transaction?.total_amount.toLocaleString() }}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>

            <div class="bg-primary/5 p-6 rounded-2xl border border-primary/10 flex items-center gap-4">
              <div class="bg-primary/20 p-3 rounded-xl">
                 <MapPin class="h-6 w-6 text-primary" />
              </div>
              <div>
                <p class="text-xs font-bold text-primary">Rute Optimal Aktif</p>
                <p class="text-[10px] text-slate-500">Scan QR Code di atas dengan aplikasi Driver untuk navigasi rute tercepat.</p>
              </div>
            </div>
         </CardContent>

         <CardFooter class="p-6 bg-slate-50 border-t flex justify-end gap-3">
            <Button variant="ghost" class="font-bold text-slate-500" @click="selectedDO = null">CLOSE</Button>
            <Button class="font-black px-10" @click="handlePrint">PRINT SURAT JALAN</Button>
         </CardFooter>
       </Card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref, reactive, computed } from 'vue'
import { useDeliveryStore } from '@/stores/delivery'
import { useMasterDataStore } from '@/stores/masterData'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card/index'
import { Badge } from '@/components/ui/badge'
import DataTable from '@/components/DataTable.vue'
import { 
  Truck, RefreshCw, Printer, PackagePlus, 
  PackageOpen, MapPin, Search 
} from 'lucide-vue-next'
import axios from 'axios'

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080/api/v1'
const deliveryStore = useDeliveryStore()
const masterDataStore = useMasterDataStore()

const loading = ref(false)
const showCreateBatch = ref(false)
const selectedOrders = ref<string[]>([])
const isSubmitting = ref(false)
const selectedDO = ref<any>(null)

const drivers = ref<any[]>([])
const vehicles = ref<any[]>([])

const form = reactive({
  driver_id: '',
  vehicle_id: '',
})

const isFormValid = computed(() => {
  return form.driver_id && form.vehicle_id && selectedOrders.value.length > 0
})

const fetchData = async () => {
  loading.value = true
  try {
    await deliveryStore.fetchPendingOrders(masterDataStore.selectedBranchCompanyId)
    await deliveryStore.fetchBatches()
    
    // Fetch drivers & vehicles (simplified)
    const dRes = await axios.get(`${API_URL}/employees?job_title=DRIVER`)
    drivers.value = dRes.data
    const vRes = await axios.get(`${API_URL}/vehicles`)
    vehicles.value = vRes.data
  } finally {
    loading.value = false
  }
}

onMounted(fetchData)

const handleCreateBatch = async () => {
  isSubmitting.value = true
  try {
    const batch = await deliveryStore.createBatch({
      company_id: masterDataStore.selectedBranchCompanyId,
      driver_id: form.driver_id,
      vehicle_id: form.vehicle_id,
      sales_transaction_ids: selectedOrders.value
    })
    showCreateBatch.value = false
    selectedOrders.value = []
    await fetchData()
    selectedDO.value = batch
  } catch (err) {
    alert(err)
  } finally {
    isSubmitting.value = false
  }
}

const printDO = (row: any) => {
  selectedDO.value = row
}

const handlePrint = () => {
  window.print()
}

const batchColumns = [
  { key: 'created_at', label: 'Date', type: 'datetime' },
  { key: 'delivery_order_no', label: 'SJ Number' },
  { key: 'driver.first_name', label: 'Driver' },
  { key: 'vehicle.license_plate', label: 'Vehicle' },
  { key: 'items.length', label: 'Total Orders' },
  { key: 'status', label: 'Status' }
]
</script>

<style scoped>
@media print {
  body * {
    visibility: hidden;
  }
  .fixed.inset-0.bg-background\/80 {
    position: absolute;
    left: 0;
    top: 0;
    width: 100%;
    margin: 0;
    padding: 0;
    background: white !important;
    visibility: visible;
    z-index: 9999;
  }
  .fixed.inset-0.bg-background\/80 * {
    visibility: visible;
  }
  .fixed.inset-0.bg-background\/80 button {
    display: none;
  }
}
</style>
