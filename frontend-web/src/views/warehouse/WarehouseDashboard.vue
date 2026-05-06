<template>
  <div class="p-6 space-y-8 max-w-[1600px] mx-auto animate-in fade-in duration-700">
    <!-- Header with Welcome & Date -->
    <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
      <div>
        <h1 class="text-4xl font-black tracking-tight text-slate-900 flex items-center gap-3">
          <Warehouse class="h-10 w-10 text-primary" />
          Dashboard Gudang
        </h1>
        <p class="text-slate-500 font-medium mt-1">Kondisi stok dan logistik real-time di Cabang Anda.</p>
      </div>
      <div class="flex items-center gap-3 bg-white p-2 rounded-2xl shadow-sm border border-slate-100">
        <div class="bg-primary/10 p-2 rounded-xl text-primary">
          <Calendar class="h-5 w-5" />
        </div>
        <div class="pr-4">
          <p class="text-[10px] font-black uppercase tracking-widest text-slate-400">Hari Ini</p>
          <p class="text-sm font-bold text-slate-700">{{ currentDate }}</p>
        </div>
      </div>
    </div>

    <!-- Main KPIs -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      <!-- Total SKU -->
      <Card class="relative overflow-hidden group hover:shadow-xl transition-all duration-500 border-none bg-gradient-to-br from-white to-slate-50 shadow-sm">
        <div class="absolute top-0 right-0 p-4 opacity-5 group-hover:opacity-10 transition-opacity">
          <Boxes class="h-24 w-24 text-slate-900" />
        </div>
        <CardHeader class="pb-2">
          <CardDescription class="text-xs font-black uppercase tracking-widest text-slate-400">Total Varian Produk</CardDescription>
          <CardTitle class="text-4xl font-black text-slate-900">{{ warehouseStore.inventory.length }}</CardTitle>
        </CardHeader>
        <CardContent>
          <div class="flex items-center gap-1.5 text-xs font-bold text-slate-500">
            <span class="text-primary bg-primary/10 px-2 py-0.5 rounded-full">Aktif</span>
            SKU tersimpan di gudang
          </div>
        </CardContent>
      </Card>

      <!-- Total Pieces -->
      <Card class="relative overflow-hidden group hover:shadow-xl transition-all duration-500 border-none bg-gradient-to-br from-white to-slate-50 shadow-sm">
        <div class="absolute top-0 right-0 p-4 opacity-5 group-hover:opacity-10 transition-opacity">
          <Package class="h-24 w-24 text-slate-900" />
        </div>
        <CardHeader class="pb-2">
          <CardDescription class="text-xs font-black uppercase tracking-widest text-slate-400">Total Stok Fisik</CardDescription>
          <CardTitle class="text-4xl font-black text-slate-900">{{ totalPieces }}</CardTitle>
        </CardHeader>
        <CardContent>
          <div class="flex items-center gap-1.5 text-xs font-bold text-slate-500">
            <TrendingUp class="h-3 w-3 text-emerald-500" />
            Total kuantitas gabungan
          </div>
        </CardContent>
      </Card>

      <!-- Low Stock Alert -->
      <Card class="relative overflow-hidden group hover:shadow-xl transition-all duration-500 border-none shadow-sm" 
            :class="lowStockItems.length > 0 ? 'bg-red-50 ring-1 ring-red-100' : 'bg-white'">
        <div class="absolute top-0 right-0 p-4 opacity-5 group-hover:opacity-10 transition-opacity">
          <AlertTriangle class="h-24 w-24 text-red-600" />
        </div>
        <CardHeader class="pb-2">
          <CardDescription class="text-xs font-black uppercase tracking-widest text-red-400">Stok Menipis</CardDescription>
          <CardTitle class="text-4xl font-black text-red-600">{{ lowStockItems.length }}</CardTitle>
        </CardHeader>
        <CardContent>
          <div class="flex items-center gap-1.5 text-xs font-bold" :class="lowStockItems.length > 0 ? 'text-red-500' : 'text-slate-500'">
            {{ lowStockItems.length > 0 ? 'Perlu segera restock!' : 'Stok aman terkendali' }}
          </div>
        </CardContent>
      </Card>

      <!-- Inbound Shipments -->
      <Card class="relative overflow-hidden group hover:shadow-xl transition-all duration-500 border-none shadow-sm"
            :class="warehouseStore.pendingShipments.length > 0 ? 'bg-amber-50 ring-1 ring-amber-100' : 'bg-white'">
        <div class="absolute top-0 right-0 p-4 opacity-5 group-hover:opacity-10 transition-opacity">
          <Truck class="h-24 w-24 text-amber-600" />
        </div>
        <CardHeader class="pb-2">
          <CardDescription class="text-xs font-black uppercase tracking-widest text-amber-500">Barang Masuk (Inbound)</CardDescription>
          <CardTitle class="text-4xl font-black text-amber-600">{{ warehouseStore.pendingShipments.length }}</CardTitle>
        </CardHeader>
        <CardContent>
          <div class="flex items-center gap-1.5 text-xs font-bold" :class="warehouseStore.pendingShipments.length > 0 ? 'text-amber-600' : 'text-slate-500'">
            {{ warehouseStore.pendingShipments.length > 0 ? 'Menunggu konfirmasi' : 'Tidak ada kiriman baru' }}
          </div>
        </CardContent>
      </Card>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-12 gap-8">
      <!-- Top Stock Distribution (Visual) -->
      <div class="lg:col-span-8 space-y-6">
        <div class="flex justify-between items-center px-2">
          <h2 class="text-xl font-black flex items-center gap-2 text-slate-800">
            <PieChart class="h-5 w-5 text-primary" />
            Distribusi Stok Terbanyak
          </h2>
          <Button variant="ghost" size="sm" @click="$router.push('/warehouse/stock')" class="font-bold text-primary">Lihat Semua</Button>
        </div>
        
        <Card class="border-none shadow-sm p-6 space-y-6 bg-white rounded-3xl">
          <div v-if="topProducts.length > 0" class="space-y-6">
            <div v-for="product in topProducts" :key="product.id" class="space-y-2">
              <div class="flex justify-between items-center text-sm">
                <div class="flex items-center gap-2">
                  <div class="h-2 w-2 rounded-full bg-primary"></div>
                  <span class="font-bold text-slate-700">{{ product.product?.name }}</span>
                  <span class="text-[10px] text-slate-400 font-mono">{{ product.product?.sku }}</span>
                </div>
                <span class="font-black text-slate-900">{{ product.quantity }} <span class="text-[10px] text-slate-400">{{ product.product?.unit }}</span></span>
              </div>
              <div class="h-3 w-full bg-slate-100 rounded-full overflow-hidden">
                <div 
                  class="h-full bg-primary transition-all duration-1000 ease-out rounded-full"
                  :style="{ width: `${(product.quantity / maxStockValue) * 100}%` }"
                ></div>
              </div>
            </div>
          </div>
          <div v-else class="text-center py-20 text-slate-400 italic">
            Belum ada data stok tersedia.
          </div>
        </Card>

        <!-- Low Stock Alerts Center -->
        <div v-if="lowStockItems.length > 0" class="space-y-4">
          <h2 class="text-xl font-black flex items-center gap-2 px-2 text-slate-800">
            <AlertCircle class="h-5 w-5 text-red-500" />
            Peringatan Stok Rendah
          </h2>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div v-for="item in lowStockItems.slice(0, 4)" :key="item.id" class="bg-white p-4 rounded-2xl border border-red-100 shadow-sm flex justify-between items-center">
              <div class="flex items-center gap-3">
                <div class="bg-red-50 p-2 rounded-xl">
                  <Package class="h-5 w-5 text-red-500" />
                </div>
                <div>
                  <p class="font-bold text-sm text-slate-800 truncate max-w-[150px]">{{ item.product?.name }}</p>
                  <p class="text-[10px] font-black text-red-400 uppercase tracking-tighter">Sisa: {{ item.quantity }} / Limit: {{ item.min_limit }}</p>
                </div>
              </div>
              <Button size="sm" variant="outline" class="h-8 text-[10px] border-red-200 text-red-600 hover:bg-red-50 font-bold" @click="$router.push('/warehouse/stock')">Detail</Button>
            </div>
          </div>
        </div>
      </div>

      <!-- Right Column: Activities & Quick Actions -->
      <div class="lg:col-span-4 space-y-8">
        <!-- Quick Actions -->
        <div class="space-y-4">
           <h2 class="text-xl font-black px-2 text-slate-800">Aksi Cepat</h2>
           <div class="grid grid-cols-2 gap-4">
             <Button @click="$router.push('/warehouse/stock')" variant="outline" class="h-24 flex-col gap-2 rounded-3xl border-slate-100 hover:bg-primary/5 hover:border-primary/20 transition-all group bg-white shadow-sm">
               <div class="bg-slate-50 p-2 rounded-xl group-hover:bg-primary/10">
                 <Boxes class="h-6 w-6 text-slate-400 group-hover:text-primary" />
               </div>
               <span class="text-xs font-bold">Stok & Terima</span>
             </Button>
             <Button @click="$router.push('/warehouse/sales-transfers')" variant="outline" class="h-24 flex-col gap-2 rounded-3xl border-slate-100 hover:bg-primary/5 hover:border-primary/20 transition-all group bg-white shadow-sm">
               <div class="bg-slate-50 p-2 rounded-xl group-hover:bg-primary/10">
                 <ArrowLeftRight class="h-6 w-6 text-slate-400 group-hover:text-primary" />
               </div>
               <span class="text-xs font-bold">Transfer Sales</span>
             </Button>
           </div>
        </div>

        <!-- Recent Mutation History -->
        <div class="space-y-4">
          <h2 class="text-xl font-black px-2 flex items-center gap-2 text-slate-800">
            <History class="h-5 w-5 text-primary" />
            Mutasi Terakhir
          </h2>
          <Card class="border-none shadow-sm overflow-hidden divide-y divide-slate-50 bg-white rounded-3xl">
            <div v-for="log in recentLogs" :key="log.id" class="p-4 hover:bg-slate-50/50 transition-colors">
              <div class="flex justify-between items-start">
                <div class="flex gap-3">
                  <div :class="[
                    'p-2 rounded-xl shrink-0',
                    log.type === 'IN' ? 'bg-green-50 text-green-600' : 'bg-amber-50 text-amber-600'
                  ]">
                    <ArrowDownLeft v-if="log.type === 'IN'" class="h-4 w-4" />
                    <ArrowUpRight v-else class="h-4 w-4" />
                  </div>
                  <div class="min-w-0">
                    <p class="text-sm font-bold text-slate-800 truncate max-w-[140px]">{{ log.product?.name }}</p>
                    <p class="text-[10px] font-black text-slate-400 uppercase tracking-tighter">{{ log.source }}</p>
                  </div>
                </div>
                <div class="text-right shrink-0">
                  <p :class="[
                    'font-black text-sm',
                    log.type === 'IN' ? 'text-green-600' : 'text-amber-600'
                  ]">
                    {{ log.type === 'IN' ? '+' : '-' }}{{ log.quantity }}
                  </p>
                  <p class="text-[9px] text-slate-300 font-bold uppercase">{{ formatTime(log.created_at) }}</p>
                </div>
              </div>
            </div>
            <div v-if="recentLogs.length === 0" class="p-8 text-center text-slate-400 text-xs italic">
              Belum ada mutasi tercatat.
            </div>
            <div class="p-3 bg-slate-50/50 text-center">
              <Button @click="$router.push('/warehouse/logs')" variant="ghost" size="sm" class="text-[10px] font-black text-primary hover:bg-primary/5">LIHAT SEMUA LOG</Button>
            </div>
          </Card>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, computed, ref } from 'vue'
import { useWarehouseStore } from '@/stores/warehouse'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card/index'
import { Button } from '@/components/ui/button'
import { 
  Warehouse, 
  Boxes, 
  Package, 
  Truck, 
  AlertTriangle, 
  PieChart, 
  History, 
  ArrowUpRight, 
  ArrowDownLeft, 
  TrendingUp, 
  AlertCircle,
  Calendar,
  ArrowLeftRight
} from 'lucide-vue-next'
// Removed date-fns imports

const warehouseStore = useWarehouseStore()

// Computed
const currentDate = computed(() => {
  return new Intl.DateTimeFormat('id-ID', { 
    weekday: 'long', 
    day: 'numeric', 
    month: 'long', 
    year: 'numeric' 
  }).format(new Date())
})

const totalPieces = computed(() => {
  return warehouseStore.inventory.reduce((sum, item) => sum + item.quantity, 0)
})

const lowStockItems = computed(() => {
  return warehouseStore.inventory.filter(item => item.quantity < item.min_limit)
})

const topProducts = computed(() => {
  return [...warehouseStore.inventory]
    .sort((a, b) => b.quantity - a.quantity)
    .slice(0, 5)
})

const maxStockValue = computed(() => {
  if (topProducts.value.length === 0) return 1
  return Math.max(...topProducts.value.map(p => p.quantity))
})

const recentLogs = computed(() => {
  return warehouseStore.logs.slice(0, 5)
})

// Methods
const formatTime = (dateStr: string) => {
  if (!dateStr) return '-'
  try {
    return new Intl.DateTimeFormat('id-ID', { 
      hour: '2-digit', 
      minute: '2-digit', 
      hour12: false 
    }).format(new Date(dateStr))
  } catch (e) {
    return '-'
  }
}

const refreshData = async () => {
  await Promise.all([
    warehouseStore.fetchInventory(),
    warehouseStore.fetchPendingShipments(),
    warehouseStore.fetchLogs()
  ])
}

onMounted(() => {
  refreshData()
})
</script>

<style scoped>
.custom-scrollbar::-webkit-scrollbar {
  width: 4px;
}
.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background: #e2e8f0;
  border-radius: 10px;
}
</style>
