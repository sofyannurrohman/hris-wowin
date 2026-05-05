<template>
  <div class="p-8 space-y-8 bg-[#f8fafc] min-h-screen">
    <!-- Header -->
    <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 bg-white p-8 rounded-[2rem] shadow-sm border border-slate-100">
      <div>
        <div class="flex items-center gap-2 text-xs font-bold text-orange-600 uppercase tracking-[0.2em] mb-2">
          <Truck class="h-4 w-4" />
          <span>Logistics & Distribution</span>
        </div>
        <h1 class="text-3xl font-black tracking-tight text-slate-900">Manajemen Pengiriman</h1>
        <p class="text-slate-500 mt-1">Lacak log pengiriman barang dari pabrik ke seluruh cabang Wowin.</p>
      </div>
      <div class="flex gap-3">
        <Button variant="outline" class="rounded-2xl border-slate-200 bg-white hover:bg-slate-50 text-slate-600 font-bold" @click="factoryStore.fetchAllTransfers()">
          <RefreshCw class="mr-2 h-4 w-4" :class="{ 'animate-spin': factoryStore.loading }" /> Segarkan Data
        </Button>
      </div>
    </div>

    <!-- Stats Summary -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-6">
      <Card class="p-6 border-none shadow-sm bg-white rounded-3xl">
        <p class="text-xs font-bold text-slate-400 uppercase tracking-widest">Total Pengiriman</p>
        <p class="text-2xl font-black text-slate-900 mt-1">{{ factoryStore.allTransfers.length }}</p>
      </Card>
      <Card class="p-6 border-none shadow-sm bg-white rounded-3xl">
        <p class="text-xs font-bold text-blue-500 uppercase tracking-widest">Dalam Perjalanan</p>
        <p class="text-2xl font-black text-blue-600 mt-1">{{ stats.shipped }}</p>
      </Card>
      <Card class="p-6 border-none shadow-sm bg-white rounded-3xl">
        <p class="text-xs font-bold text-emerald-500 uppercase tracking-widest">Selesai/Diterima</p>
        <p class="text-2xl font-black text-emerald-600 mt-1">{{ stats.received }}</p>
      </Card>
      <Card class="p-6 border-none shadow-sm bg-white rounded-3xl">
        <p class="text-xs font-bold text-orange-500 uppercase tracking-widest">Menunggu Approval</p>
        <p class="text-2xl font-black text-orange-600 mt-1">{{ stats.requested }}</p>
      </Card>
    </div>

    <!-- Transfers Table (Grouped by DO) -->
    <Card class="border-none shadow-sm bg-white rounded-[2rem] overflow-hidden">
      <div class="p-8">
        <div class="flex items-center justify-between mb-8">
          <div class="flex items-center gap-4">
            <div class="relative">
              <Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
              <input 
                v-model="searchQuery" 
                type="text" 
                placeholder="Cari No. Surat Jalan..." 
                class="pl-10 pr-4 py-2.5 bg-slate-50 border border-slate-100 rounded-xl text-sm w-[300px] outline-none focus:ring-2 focus:ring-primary/20"
              />
            </div>
          </div>
          <div class="flex items-center gap-2 text-xs font-bold text-slate-400">
            Total Tonnage Aktif: <span class="text-primary text-sm ml-1">{{ totalActiveTonnage.toFixed(2) }} KG</span>
          </div>
        </div>

        <div class="space-y-4">
          <div v-for="shipment in groupedTransfers" :key="shipment.doNo" class="border border-slate-100 rounded-3xl overflow-hidden shadow-sm">
            <!-- Shipment Header -->
            <div class="bg-slate-50/50 p-6 flex flex-col md:flex-row justify-between items-start md:items-center gap-4 border-b border-slate-100">
              <div class="flex items-center gap-4">
                <div class="bg-white p-3 rounded-2xl shadow-sm">
                  <Truck class="h-6 w-6 text-primary" />
                </div>
                <div>
                  <p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">No. Surat Jalan</p>
                  <h3 class="text-lg font-black text-slate-900 font-mono">{{ shipment.doNo }}</h3>
                </div>
              </div>
              
              <div class="flex items-center gap-8">
                <div>
                  <p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Rute</p>
                  <p class="text-sm font-bold text-slate-700">{{ shipment.from }} &rarr; {{ shipment.to }}</p>
                </div>
                <div class="text-right">
                  <p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Total Tonase Armada</p>
                  <p class="text-lg font-black text-primary">{{ shipment.totalWeight.toFixed(2) }} KG</p>
                </div>
                <Badge :class="getStatusClass(shipment.status)" class="rounded-full px-4 py-1.5 font-bold uppercase text-[10px]">
                  {{ shipment.status }}
                </Badge>
                <Button variant="ghost" size="icon" class="h-10 w-10 text-slate-400 hover:text-primary">
                  <Printer class="h-5 w-5" />
                </Button>
              </div>
            </div>

            <!-- Shipment Items (Breakdown) -->
            <div class="p-6 bg-white">
              <table class="w-full text-sm">
                <thead>
                  <tr class="text-left text-[10px] font-bold text-slate-400 uppercase tracking-wider border-b border-slate-50">
                    <th class="pb-3 px-4">Informasi Barang</th>
                    <th class="pb-3 px-4">Kategori / Brand</th>
                    <th class="pb-3 px-4 text-right">Jumlah</th>
                    <th class="pb-3 px-4 text-right">Tonase (Weight)</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="item in shipment.items" :key="item.id" class="border-b border-slate-50 last:border-0 hover:bg-slate-50/50 transition-colors">
                    <td class="py-4 px-4 font-bold text-slate-900">{{ item.product?.name }}</td>
                    <td class="py-4 px-4">
                       <Badge variant="outline" class="text-[9px] text-slate-400 border-slate-200">{{ item.product?.category }}</Badge>
                       <span class="ml-2 text-[10px] text-slate-400 font-medium">{{ item.product?.brand }}</span>
                    </td>
                    <td class="py-4 px-4 text-right font-black text-slate-700">{{ item.quantity }} <span class="text-[10px] text-slate-400">{{ item.product?.unit }}</span></td>
                    <td class="py-4 px-4 text-right">
                       <span class="font-bold text-primary">{{ item.total_weight.toFixed(2) }} KG</span>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </Card>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref, computed } from 'vue'
import { useFactoryStore } from '@/stores/factory'
import { Button } from '@/components/ui/button'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import DataTable from '@/components/DataTable.vue'
import { 
  Truck, 
  Search, 
  RefreshCw, 
  ArrowRight, 
  Printer 
} from 'lucide-vue-next'

const factoryStore = useFactoryStore()
const searchQuery = ref('')

onMounted(() => {
  factoryStore.fetchAllTransfers()
})

const filteredTransfers = computed(() => {
  return factoryStore.allTransfers.filter(item => {
    const query = searchQuery.value.toLowerCase()
    return (
      (item.delivery_order_no && item.delivery_order_no.toLowerCase().includes(query)) ||
      (item.product?.name.toLowerCase().includes(query)) ||
      (item.from_factory?.name.toLowerCase().includes(query)) ||
      (item.to_branch?.name.toLowerCase().includes(query))
    )
  })
})

const groupedTransfers = computed(() => {
  const groups: Record<string, any> = {}
  
  filteredTransfers.value.forEach(item => {
    const doNo = item.delivery_order_no || 'DRAFT'
    if (!groups[doNo]) {
      groups[doNo] = {
        doNo,
        from: item.from_factory?.name,
        to: item.to_branch?.name,
        totalWeight: 0,
        status: item.status,
        items: []
      }
    }
    groups[doNo].items.push(item)
    groups[doNo].totalWeight += item.total_weight
  })
  
  return Object.values(groups).sort((a, b) => b.doNo.localeCompare(a.doNo))
})

const totalActiveTonnage = computed(() => {
  return filteredTransfers.value.reduce((acc, curr) => acc + curr.total_weight, 0)
})

const stats = computed(() => {
  const items = factoryStore.allTransfers
  return {
    requested: items.filter(i => i.status === 'REQUESTED').length,
    shipped: items.filter(i => i.status === 'SHIPPED').length,
    received: items.filter(i => i.status === 'RECEIVED').length
  }
})

const getStatusClass = (status: string) => {
  switch (status) {
    case 'RECEIVED': return 'bg-emerald-50 text-emerald-600'
    case 'SHIPPED': return 'bg-blue-50 text-blue-600'
    case 'REQUESTED': return 'bg-orange-50 text-orange-600'
    case 'APPROVED': return 'bg-indigo-50 text-indigo-600'
    default: return 'bg-slate-50 text-slate-500'
  }
}

const columns = [
  { key: 'created_at', label: 'Tgl Pengajuan', type: 'datetime' },
  { key: 'delivery_order_no', label: 'No. Surat Jalan' },
  { key: 'route', label: 'Rute Pengiriman' },
  { key: 'product_info', label: 'Item & Qty' },
  { key: 'status', label: 'Status' },
  { key: 'actions', label: '' }
]
</script>
