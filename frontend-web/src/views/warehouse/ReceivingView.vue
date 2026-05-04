<template>
  <div class="p-6 space-y-6">
    <div class="flex justify-between items-center">
      <div>
        <h1 class="text-3xl font-bold tracking-tight">Penerimaan Barang</h1>
        <p class="text-muted-foreground">Konfirmasi barang yang dikirim dari pabrik utama.</p>
      </div>
      <Button class="bg-primary hover:bg-primary/90 text-white font-bold px-6 rounded-xl shadow-lg flex gap-2" @click="showScanner = true">
        <ScanLine class="h-5 w-5" />
        SCAN BARCODE SJ
      </Button>
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

    <!-- Scanner Mock Modal -->
    <div v-if="showScanner" class="fixed inset-0 bg-background/80 backdrop-blur-sm z-50 flex items-center justify-center p-4">
       <Card class="w-full max-w-md border-2 border-primary shadow-2xl">
         <CardHeader class="bg-primary text-primary-foreground rounded-t-lg">
           <CardTitle class="flex items-center gap-2">
             <ScanLine class="h-6 w-6" />
             Scan Surat Jalan
           </CardTitle>
           <CardDescription class="text-primary-foreground/70">Arahkan scanner ke barcode atau masukkan nomor SJ.</CardDescription>
         </CardHeader>
         <CardContent class="p-6 space-y-6">
           <div class="aspect-square bg-slate-100 rounded-2xl border-4 border-dashed border-slate-200 flex flex-col items-center justify-center text-slate-400 gap-4">
             <div class="w-48 h-48 border-4 border-primary/20 rounded-3xl flex items-center justify-center relative">
               <div class="absolute inset-0 border-2 border-primary rounded-3xl animate-pulse"></div>
               <QrCode class="w-24 h-24 text-primary opacity-20" />
             </div>
             <p class="text-xs font-black uppercase tracking-widest">SISTEM SCANNER AKTIF</p>
           </div>
           
           <div class="space-y-2">
             <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Input Manual No. Surat Jalan</label>
             <div class="relative">
               <Input 
                 v-model="scannedDO" 
                 placeholder="Contoh: DO-20240504-..." 
                 class="h-12 rounded-xl border-2 focus-visible:ring-primary font-mono text-center text-lg tracking-widest"
                 @keyup.enter="handleScanSubmit"
               />
               <Search class="absolute right-4 top-3.5 h-5 w-5 text-slate-300" />
             </div>
           </div>
         </CardContent>
         <CardFooter class="flex justify-between gap-3 p-6 bg-slate-50 rounded-b-lg border-t">
           <Button variant="ghost" class="font-bold text-slate-500" @click="showScanner = false">BATAL</Button>
           <Button class="flex-1 font-black" @click="handleScanSubmit" :loading="isScanning">KONFIRMASI PENERIMAAN</Button>
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
import { Input } from '@/components/ui/input'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card/index'
import { ScanLine, QrCode, Search } from 'lucide-vue-next'

const warehouseStore = useWarehouseStore()
const masterDataStore = useMasterDataStore()
const processingId = ref('')
const showScanner = ref(false)
const scannedDO = ref('')
const isScanning = ref(false)

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
</script>
