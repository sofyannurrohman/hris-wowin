<template>
  <div class="p-6 space-y-6">
    <div class="flex justify-between items-center">
      <div>
        <h1 class="text-3xl font-bold tracking-tight">Gudang Cabang</h1>
        <p class="text-muted-foreground">Manajemen stok produk di cabang ini.</p>
      </div>
      <div class="flex gap-2">
        <Button variant="outline" @click="warehouseStore.fetchInventory()">Refresh</Button>
        <Button @click="showAdjustment = true">Penyesuaian Stok</Button>
      </div>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <Card class="bg-primary/5 border-primary/10">
        <CardHeader class="pb-2">
          <CardDescription>Total Produk</CardDescription>
          <CardTitle class="text-3xl font-bold">{{ warehouseStore.inventory.length }}</CardTitle>
        </CardHeader>
      </Card>
      <Card>
        <CardHeader class="pb-2">
          <CardDescription>Kiriman Menunggu</CardDescription>
          <CardTitle class="text-3xl font-bold">{{ warehouseStore.pendingShipments.length }}</CardTitle>
        </CardHeader>
      </Card>
    </div>

    <div class="space-y-4">
      <h2 class="text-xl font-semibold">Stok Saat Ini</h2>
      <DataTable :columns="columns" :data="warehouseStore.inventory" />
    </div>

    <!-- Stock Adjustment Modal -->
    <div v-if="showAdjustment" class="fixed inset-0 bg-background/80 backdrop-blur-sm z-50 flex items-center justify-center p-4">
       <Card class="w-full max-w-md">
         <CardHeader>
           <CardTitle>Penyesuaian Stok (Stock Opname)</CardTitle>
           <CardDescription>Sesuaikan jumlah fisik produk di gudang.</CardDescription>
         </CardHeader>
         <CardContent class="space-y-4">
           <div class="space-y-2">
             <label class="text-sm font-medium">Pilih Produk</label>
             <select v-model="adjustForm.product_id" class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm">
               <option v-for="item in warehouseStore.inventory" :key="item.product_id" :value="item.product_id">
                 {{ item.product?.name }} (SKU: {{ item.product?.sku }})
               </option>
             </select>
           </div>
           <div class="space-y-2">
             <label class="text-sm font-medium">Jumlah Fisik Baru</label>
             <input type="number" v-model="adjustForm.quantity" class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm" />
           </div>
           <div class="space-y-2">
             <label class="text-sm font-medium">Alasan</label>
             <textarea v-model="adjustForm.reason" class="flex min-h-[80px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm"></textarea>
           </div>
         </CardContent>
         <CardFooter class="flex justify-end gap-2">
           <Button variant="outline" @click="showAdjustment = false">Batal</Button>
           <Button @click="handleAdjust">Simpan Perubahan</Button>
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
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card/index'
import DataTable from '@/components/DataTable.vue'

const warehouseStore = useWarehouseStore()
const masterDataStore = useMasterDataStore()
const showAdjustment = ref(false)

// Watch for branch changes and refetch data
watch(() => masterDataStore.selectedBranchId, () => {
  warehouseStore.fetchInventory()
  warehouseStore.fetchPendingShipments()
})

const adjustForm = reactive({
  product_id: '',
  quantity: 0,
  reason: ''
})

onMounted(() => {
  warehouseStore.fetchInventory()
  warehouseStore.fetchPendingShipments()
})

const handleAdjust = async () => {
  try {
    await warehouseStore.adjustStock(adjustForm)
    showAdjustment.value = false
  } catch (err) {
    alert(err)
  }
}

const handleSetLimit = async (productId: string, newLimit: number) => {
  try {
    await warehouseStore.setStockLimit({ product_id: productId, limit: newLimit })
  } catch (err) {
    alert(err)
  }
}

const columns = [
  { key: 'product.name', label: 'Nama Produk' },
  { key: 'product.sku', label: 'SKU' },
  { 
    key: 'quantity', 
    label: 'Jumlah Stok', 
    class: 'font-bold',
    render: (val: number, item: any) => {
      const isLow = val < item.min_limit
      return `<span class="${isLow ? 'text-red-600 animate-pulse' : ''}">${val} ${item.product.unit}</span>`
    }
  },
  { 
    key: 'min_limit', 
    label: 'Limit Minimum',
    render: (val: number, item: any) => {
      return `<input type="number" value="${val}" class="w-20 px-2 py-1 border rounded text-sm" onchange="window.dispatchEvent(new CustomEvent('set-limit', {detail: {id: '${item.product_id}', val: this.value}}))" />`
    }
  },
  { key: 'updated_at', label: 'Terakhir Diperbarui', type: 'datetime' }
]

onMounted(() => {
  warehouseStore.fetchInventory()
  warehouseStore.fetchPendingShipments()
  
  window.addEventListener('set-limit', (e: any) => {
    handleSetLimit(e.detail.id, parseInt(e.detail.val))
  })
})
</script>
