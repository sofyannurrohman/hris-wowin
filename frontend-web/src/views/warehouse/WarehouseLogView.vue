<template>
  <div class="p-6 space-y-6">
    <div>
      <h1 class="text-3xl font-bold tracking-tight">Log Mutasi Barang</h1>
      <p class="text-muted-foreground">Riwayat keluar masuk barang di gudang cabang.</p>
    </div>

    <Card>
      <CardContent class="p-0">
        <DataTable :columns="columns" :data="warehouseStore.logs" />
      </CardContent>
    </Card>
  </div>
</template>

<script setup lang="ts">
import { onMounted, watch } from 'vue'
import { useWarehouseStore } from '@/stores/warehouse'
import { useMasterDataStore } from '@/stores/masterData'
import { Card, CardContent } from '@/components/ui/card'
import DataTable from '@/components/DataTable.vue'

const warehouseStore = useWarehouseStore()
const masterDataStore = useMasterDataStore()

// Watch for branch changes and refetch data
watch(() => masterDataStore.selectedBranchId, () => {
  warehouseStore.fetchLogs()
})

onMounted(() => {
  warehouseStore.fetchLogs()
})

const columns = [
  { key: 'created_at', label: 'Tanggal & Waktu', type: 'datetime' },
  { key: 'product.name', label: 'Produk' },
  { key: 'type', label: 'Tipe', type: 'badge' },
  { key: 'quantity', label: 'Jumlah' },
  { key: 'source', label: 'Sumber / Keterangan' }
]
</script>
