<template>
  <div class="p-6 space-y-6">
    <div>
      <h1 class="text-3xl font-bold tracking-tight">Penerimaan Barang</h1>
      <p class="text-muted-foreground">Konfirmasi barang yang dikirim dari pabrik utama.</p>
    </div>

    <div v-if="warehouseStore.pendingShipments.length === 0" class="text-center py-12 bg-muted/20 rounded-lg border border-dashed">
      <p class="text-muted-foreground text-lg">Tidak ada pengiriman yang menunggu untuk diterima.</p>
    </div>

    <div v-else class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <Card v-for="transfer in warehouseStore.pendingShipments" :key="transfer.id" class="relative overflow-hidden">
        <div class="absolute top-0 left-0 w-1 h-full bg-primary"></div>
        <CardHeader>
          <div class="flex justify-between items-start">
            <div>
              <CardTitle>{{ transfer.product?.name }}</CardTitle>
              <CardDescription>Dari: {{ transfer.from_factory?.name || 'Pabrik Utama' }}</CardDescription>
            </div>
            <div class="bg-primary/10 text-primary px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider">
              DIKIRIM
            </div>
          </div>
        </CardHeader>
        <CardContent class="space-y-4">
          <div class="grid grid-cols-2 gap-4">
            <div>
              <p class="text-xs text-muted-foreground uppercase">Jumlah & Tonase</p>
              <p class="text-lg font-bold">
                {{ transfer.quantity }} {{ transfer.product?.unit }}
                <span class="text-sm font-medium text-slate-500">({{ (transfer.total_weight / 1000).toFixed(2) }} Ton)</span>
              </p>
            </div>
            <div>
              <p class="text-xs text-muted-foreground uppercase">Status</p>
              <p class="font-bold text-primary">{{ transfer.status }}</p>
            </div>
          </div>
          <div v-if="transfer.notes" class="bg-slate-50 p-3 rounded-lg text-sm border">
             <strong>Catatan:</strong> {{ transfer.notes }}
          </div>
        </CardContent>
        <CardFooter class="bg-slate-50/50 border-t flex justify-end p-4 gap-2">
          <template v-if="transfer.status === 'REQUESTED'">
            <Button variant="outline" class="text-destructive" @click="handleReject(transfer.id)">Tolak</Button>
            <Button @click="handleApprove(transfer.id)">Setujui Permintaan</Button>
          </template>
          <template v-else-if="transfer.status === 'SHIPPED'">
            <Button @click="handleReceive(transfer.id)" :loading="processingId === transfer.id">Terima Barang</Button>
          </template>
          <template v-else>
            <p class="text-sm text-muted-foreground italic">Menunggu aksi pabrik...</p>
          </template>
        </CardFooter>
      </Card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref, watch } from 'vue'
import { useWarehouseStore } from '@/stores/warehouse'
import { useMasterDataStore } from '@/stores/masterData'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card/index'

const warehouseStore = useWarehouseStore()
const masterDataStore = useMasterDataStore()
const processingId = ref('')

// Watch for branch changes and refetch data
watch(() => masterDataStore.selectedBranchId, () => {
  warehouseStore.fetchPendingShipments()
})

onMounted(() => {
  warehouseStore.fetchPendingShipments()
})

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
  } catch (err) {
    alert(err)
  } finally {
    processingId.value = ''
  }
}
</script>
