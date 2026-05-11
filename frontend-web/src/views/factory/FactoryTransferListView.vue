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
        <p class="text-slate-500 mt-1">Kelola surat jalan dan proses permintaan barang dari cabang.</p>
      </div>
      <div class="flex gap-3">
        <Button variant="outline" class="rounded-2xl border-slate-200 bg-white hover:bg-slate-50 text-slate-600 font-bold" @click="factoryStore.fetchAllTransfers()">
          <RefreshCw class="mr-2 h-4 w-4" :class="{ 'animate-spin': factoryStore.loading }" /> Segarkan
        </Button>
        <Button @click="openManualShipmentModal" class="rounded-2xl shadow-lg shadow-primary/20 font-bold">
          <Plus class="mr-2 h-4 w-4" /> Buat Surat Jalan Manual
        </Button>
      </div>
    </div>

    <!-- Main Content Layout -->
    <div class="grid grid-cols-1 lg:grid-cols-12 gap-8">
      
      <!-- LEFT SIDE: ACTIVE & COMPLETED SHIPMENTS (8/12) -->
      <div class="lg:col-span-8 space-y-6">
        <div class="flex items-center justify-between px-2">
          <h2 class="text-xl font-black text-slate-900 flex items-center gap-2">
             Daftar Surat Jalan 
             <Badge variant="secondary" class="rounded-full bg-slate-100 text-slate-500">{{ processedShipments.length }}</Badge>
          </h2>
          <div class="relative w-64">
            <Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
            <input v-model="searchQuery" type="text" placeholder="Cari No. SJ..." class="w-full pl-10 pr-4 py-2 bg-white border border-slate-200 rounded-xl text-sm outline-none" />
          </div>
        </div>

        <div v-if="processedShipments.length === 0" class="bg-white rounded-[2rem] p-12 text-center border border-dashed border-slate-200">
          <div class="bg-slate-50 h-16 w-16 rounded-2xl flex items-center justify-center mx-auto mb-4 text-slate-300">
            <Truck class="h-8 w-8" />
          </div>
          <h3 class="font-bold text-slate-900">Belum ada pengiriman</h3>
          <p class="text-sm text-slate-500 mt-1">Proses permintaan di sebelah kanan untuk membuat surat jalan baru.</p>
        </div>

        <div v-for="shipment in processedShipments" :key="shipment.doNo" class="bg-white rounded-[2rem] border border-slate-100 shadow-sm overflow-hidden transition-all hover:shadow-md">
          <div class="p-6 flex flex-col md:flex-row justify-between items-start md:items-center gap-4 bg-slate-50/30 border-b border-slate-50">
            <div class="flex items-center gap-4">
              <div class="bg-white p-3 rounded-2xl shadow-sm border border-slate-100">
                <Truck class="h-6 w-6 text-primary" />
              </div>
              <div>
                <p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">No. Surat Jalan</p>
                <h3 class="text-lg font-black text-slate-900 font-mono">{{ shipment.doNo }}</h3>
              </div>
            </div>
            <div class="flex items-center gap-6">
              <div class="text-right">
                <p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Tujuan</p>
                <p class="text-sm font-bold text-slate-700">{{ shipment.to }}</p>
              </div>
              <div class="text-right" v-if="shipment.items[0]?.target_shipment_date">
                <p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Tgl Kirim</p>
                <p class="text-sm font-bold text-blue-600">
                  {{ new Date(shipment.items[0].target_shipment_date).toLocaleDateString('id-ID', { day: 'numeric', month: 'short' }) }}
                </p>
              </div>
              <div class="text-right" v-if="shipment.items[0]?.estimated_arrival">
                <p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Est. Sampai</p>
                <p class="text-sm font-bold text-orange-600">
                  {{ new Date(shipment.items[0].estimated_arrival).toLocaleDateString('id-ID', { day: 'numeric', month: 'short' }) }}
                </p>
              </div>
              <Badge :class="getStatusClass(shipment.status)" class="rounded-full px-4 py-1.5 font-bold uppercase text-[10px]">
                {{ shipment.status }}
              </Badge>
              <Button v-if="shipment.status === 'APPROVED'" @click="processShipment(shipment)" class="bg-primary hover:bg-primary/90 text-white font-bold h-10 px-6 rounded-xl shadow-lg shadow-primary/20">
                Proses & Kirim
              </Button>
              <Button variant="ghost" size="icon" class="h-10 w-10 text-slate-400 hover:text-primary">
                <Printer class="h-5 w-5" />
              </Button>
            </div>
          </div>
          <div class="p-6">
            <table class="w-full text-sm">
              <tbody class="divide-y divide-slate-50">
                <tr v-for="item in shipment.items" :key="item.id" class="group">
                  <td class="py-3 px-2">
                    <span class="font-bold text-slate-800">{{ item.product?.name }}</span>
                  </td>
                  <td class="py-3 px-2 text-right">
                    <span class="font-black text-slate-700">{{ item.quantity }}</span>
                    <span class="text-[10px] text-slate-400 ml-1 uppercase font-bold">{{ item.product?.unit }}</span>
                  </td>
                  <td class="py-3 px-2 text-right w-32">
                    <span class="font-bold text-primary">{{ item.total_weight.toFixed(2) }} KG</span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- RIGHT SIDE: INCOMING REQUESTS (4/12) -->
      <div class="lg:col-span-4 space-y-6">
        <div class="flex items-center justify-between px-2">
          <h2 class="text-xl font-black text-slate-900 flex items-center gap-2 text-orange-600">
             Permintaan Cabang 
             <Badge variant="secondary" class="rounded-full bg-orange-100 text-orange-600 border-none">{{ incomingRequests.length }}</Badge>
          </h2>
        </div>

        <div v-if="incomingRequests.length === 0" class="bg-white rounded-[2rem] p-12 text-center border border-dashed border-slate-200">
           <p class="text-sm text-slate-400">Tidak ada permintaan barang baru.</p>
        </div>

        <div v-for="request in incomingRequests" :key="request.doNo" class="bg-white rounded-3xl border border-orange-100 shadow-sm overflow-hidden">
          <div class="p-5 bg-orange-50/50 border-b border-orange-100 flex justify-between items-center">
            <div>
              <p class="text-[10px] font-bold text-orange-400 uppercase tracking-widest">ID Permintaan</p>
              <h4 class="text-sm font-black text-orange-900 font-mono">{{ request.doNo }}</h4>
            </div>
            <Badge class="bg-orange-100 text-orange-600 border-none text-[9px] font-bold">WAITING</Badge>
          </div>
          <div class="p-5 space-y-4">
            <div>
              <p class="text-[10px] font-bold text-slate-400 uppercase mb-2">Tujuan Pengiriman</p>
              <div class="flex items-center gap-2">
                <MapPin class="h-4 w-4 text-primary" />
                <span class="text-sm font-black text-slate-700">{{ request.to }}</span>
              </div>
            </div>
            
            <div class="space-y-2">
              <div v-for="item in request.items" :key="item.id" class="flex justify-between items-center bg-slate-50 p-2.5 rounded-xl border border-slate-100">
                <span class="text-xs font-bold text-slate-600">{{ item.product?.name }}</span>
                <span class="text-xs font-black text-slate-900">{{ item.quantity }} {{ item.product?.unit }}</span>
              </div>
            </div>

            <div v-if="request.status === 'REQUESTED'">
              <template v-if="request.items[0]?.initiated_by === 'BRANCH'">
                <Button @click="handleApproveRequest(request)" class="w-full rounded-2xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold h-12 shadow-lg shadow-emerald-200 mt-2">
                  Setujui Permintaan
                </Button>
              </template>
              <template v-else>
                <div class="w-full py-4 text-center text-[10px] font-black text-orange-500 uppercase tracking-widest bg-orange-50 rounded-2xl border border-orange-100 mt-2">
                  Menunggu Approval Cabang
                </div>
              </template>
            </div>
            
            <div v-else-if="request.status === 'APPROVED'">
              <Button @click="processShipment(request)" class="w-full rounded-2xl bg-primary hover:bg-primary/90 text-white font-bold h-12 shadow-lg shadow-primary/20 mt-2">
                Proses & Kirim (Buat SJ)
              </Button>
            </div>
          </div>
        </div>
      </div>

    </div>

    <!-- Process Shipment Modal -->
    <div v-if="showProcessModal" class="fixed inset-0 bg-slate-900/60 backdrop-blur-md z-[100] flex items-center justify-center p-4">
      <Card class="w-full max-w-2xl shadow-2xl rounded-[2.5rem] overflow-hidden border-none animate-in fade-in zoom-in-95 duration-300">
        <CardHeader class="p-8 border-b bg-white">
          <div class="flex justify-between items-center">
            <div>
              <CardTitle class="text-2xl font-black text-slate-900">Konfirmasi Pengiriman</CardTitle>
              <CardDescription>Review item dan buat surat jalan resmi (SJ).</CardDescription>
            </div>
            <Button variant="ghost" size="icon" @click="showProcessModal = false" class="rounded-full">
              <Plus class="h-6 w-6 rotate-45 text-slate-400" />
            </Button>
          </div>
        </CardHeader>
        <CardContent class="p-8 space-y-6 bg-white max-h-[60vh] overflow-y-auto">
          <div class="bg-blue-50 p-6 rounded-3xl border border-blue-100 flex items-center gap-4">
            <div class="bg-white h-12 w-12 rounded-2xl flex items-center justify-center shadow-sm">
              <Building2 class="h-6 w-6 text-blue-600" />
            </div>
            <div>
              <p class="text-[10px] font-bold text-blue-400 uppercase tracking-widest">Tujuan Cabang</p>
              <h4 class="text-lg font-black text-blue-900">{{ selectedRequest?.to }}</h4>
            </div>
          </div>

          <div class="space-y-4">
             <p class="text-[11px] font-black text-slate-400 uppercase tracking-widest ml-1">Item yang dikirim</p>
             <div class="space-y-2">
                <div v-for="item in selectedRequest?.items" :key="item.id" class="flex justify-between items-center p-4 bg-slate-50 rounded-2xl border border-slate-100">
                  <div class="flex items-center gap-3">
                    <Package class="h-5 w-5 text-slate-400" />
                    <span class="font-bold text-slate-700">{{ item.product?.name }}</span>
                  </div>
                  <span class="font-black text-slate-900">{{ item.quantity }} {{ item.product?.unit }}</span>
                </div>
             </div>
          </div>

          <div class="space-y-2">
            <label class="text-sm font-bold text-slate-700 ml-1">Pilih Pabrik Pengirim</label>
            <select v-model="processForm.factory_id" class="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold outline-none appearance-none cursor-pointer">
              <option value="" disabled>Pilih Pabrik...</option>
              <option v-for="factory in factoryStore.factories" :key="factory.id" :value="factory.id">
                {{ factory.name }}
              </option>
            </select>
          </div>

          <div class="space-y-2">
            <label class="text-sm font-bold text-slate-700 ml-1">Catatan Pengiriman (Optional)</label>
            <textarea v-model="processForm.notes" rows="2" class="w-full px-5 py-4 bg-slate-50 border border-slate-100 rounded-2xl text-sm outline-none resize-none"></textarea>
          </div>
        </CardContent>
        <CardFooter class="bg-slate-50/50 border-t p-8 flex justify-end gap-4">
           <Button variant="ghost" @click="showProcessModal = false" class="rounded-2xl font-bold h-12 px-8">Batal</Button>
           <Button @click="handleConfirmProcess" :loading="processing" class="rounded-2xl px-12 h-12 shadow-xl shadow-primary/20 font-black text-white bg-primary hover:bg-primary/90">
             Konfirmasi & Terbitkan SJ
           </Button>
        </CardFooter>
      </Card>
    </div>

    <!-- Manual Shipment Modal -->
    <div v-if="showManualModal" class="fixed inset-0 bg-slate-900/60 backdrop-blur-md z-[100] flex items-center justify-center p-4">
      <Card class="w-full max-w-3xl shadow-2xl rounded-[2.5rem] overflow-hidden border-none animate-in fade-in zoom-in-95 duration-300">
        <CardHeader class="p-8 border-b bg-white">
          <div class="flex justify-between items-center">
            <div>
              <CardTitle class="text-2xl font-black text-slate-900">Buat Surat Jalan Manual</CardTitle>
              <CardDescription>Kirim barang ke cabang tanpa melalui permintaan sistem.</CardDescription>
            </div>
            <Button variant="ghost" size="icon" @click="showManualModal = false" class="rounded-full">
              <Plus class="h-6 w-6 rotate-45 text-slate-400" />
            </Button>
          </div>
        </CardHeader>
        <CardContent class="p-8 space-y-6 bg-white max-h-[60vh] overflow-y-auto">
          <div class="grid grid-cols-2 gap-4">
            <div class="space-y-2">
              <label class="text-sm font-bold text-slate-700 ml-1">Dari Pabrik</label>
              <select v-model="manualShipmentForm.from_factory_id" class="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold outline-none">
                <option v-for="factory in factoryStore.factories" :key="factory.id" :value="factory.id">
                  {{ factory.name }}
                </option>
              </select>
            </div>
            <div class="space-y-2">
              <label class="text-sm font-bold text-slate-700 ml-1">Ke Cabang / Gudang</label>
              <select v-model="manualShipmentForm.to_branch_id" class="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold outline-none">
                <option value="" disabled>Pilih Cabang...</option>
                <option v-for="branch in masterDataStore.branches" :key="branch.id" :value="branch.id">
                  {{ branch.name }}
                </option>
              </select>
            </div>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div class="space-y-2">
              <label class="text-sm font-bold text-slate-700 ml-1 flex items-center gap-2">
                <Calendar class="h-4 w-4 text-primary" /> Tanggal Pengiriman
              </label>
              <Input type="datetime-local" v-model="manualShipmentForm.target_shipment_date" class="rounded-2xl h-12" />
            </div>
            <div class="space-y-2">
              <label class="text-sm font-bold text-slate-700 ml-1 flex items-center gap-2">
                <Clock class="h-4 w-4 text-orange-500" /> Estimasi Sampai
              </label>
              <Input type="datetime-local" v-model="manualShipmentForm.estimated_arrival" class="rounded-2xl h-12" />
            </div>
          </div>

          <div class="space-y-4">
            <div class="flex justify-between items-center">
              <p class="text-[11px] font-black text-slate-400 uppercase tracking-widest ml-1">Daftar Item</p>
              <Button size="sm" variant="outline" @click="addManualItem" class="rounded-xl font-bold">
                <Plus class="h-4 w-4 mr-1" /> Tambah Item
              </Button>
            </div>
            
            <div class="space-y-3">
              <div v-for="(item, index) in manualShipmentForm.items" :key="index" class="flex gap-3 items-end bg-slate-50/50 p-4 rounded-2xl border border-slate-100">
                <div class="flex-1 space-y-1">
                  <label class="text-[10px] font-bold text-slate-400 uppercase">Produk</label>
                  <select v-model="item.product_id" class="w-full px-4 py-2.5 bg-white border border-slate-100 rounded-xl text-xs font-bold outline-none">
                    <option v-for="p in factoryStore.products" :key="p.id" :value="p.id">
                      {{ p.name }}
                    </option>
                  </select>
                  <div class="text-[9px] font-bold text-slate-400 mt-1" v-if="item.product_id">
                    Est. Berat: {{ ((factoryStore.products.find(p => p.id === item.product_id)?.weight || 0) * item.quantity).toFixed(2) }} 
                    {{ factoryStore.products.find(p => p.id === item.product_id)?.weight_unit || 'KG' }}
                  </div>
                </div>
                <div class="w-40 space-y-1">
                  <label class="text-[10px] font-bold text-slate-400 uppercase">Jumlah</label>
                  <div class="relative">
                    <input type="number" v-model="item.quantity" class="w-full pl-4 pr-12 py-2.5 bg-white border border-slate-100 rounded-xl text-xs font-bold outline-none" />
                    <span class="absolute right-3 top-3 text-[9px] font-black text-primary uppercase">
                      {{ factoryStore.products.find(p => p.id === item.product_id)?.unit || 'PCS' }}
                    </span>
                  </div>
                </div>
                <Button variant="ghost" size="icon" class="text-destructive h-10 w-10 hover:bg-destructive/5" @click="removeManualItem(index)">
                  <Trash2 class="h-4 w-4" />
                </Button>
              </div>
            </div>
          </div>

          <div class="space-y-2">
            <label class="text-sm font-bold text-slate-700 ml-1">Catatan</label>
            <textarea v-model="manualShipmentForm.notes" rows="2" placeholder="Catatan untuk sopir atau gudang..." class="w-full px-5 py-4 bg-slate-50 border border-slate-100 rounded-2xl text-sm outline-none resize-none"></textarea>
          </div>
        </CardContent>
        <CardFooter class="bg-slate-50/50 border-t p-8 flex justify-end gap-4">
           <Button variant="ghost" @click="showManualModal = false" class="rounded-2xl font-bold h-12 px-8">Batal</Button>
           <Button @click="handleManualShipment" :loading="processing" class="rounded-2xl px-12 h-12 shadow-xl shadow-primary/20 font-black text-white bg-primary hover:bg-primary/90">
             Terbitkan Surat Jalan
           </Button>
        </CardFooter>
      </Card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref, computed, reactive } from 'vue'
import { useFactoryStore } from '@/stores/factory'
import { useMasterDataStore } from '@/stores/masterData'
import { Button } from '@/components/ui/button'
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from '@/components/ui/card/index'
import { Badge } from '@/components/ui/badge'
import { 
  Truck, 
  Search, 
  RefreshCw, 
  Plus, 
  Printer, 
  MapPin, 
  Building2, 
  Package,
  Trash2,
  ArrowRight,
  Calendar,
  Clock
} from 'lucide-vue-next'
import { toast } from 'vue-sonner'

const factoryStore = useFactoryStore()
const masterDataStore = useMasterDataStore()
const searchQuery = ref('')
const showProcessModal = ref(false)
const processing = ref(false)
const selectedRequest = ref<any>(null)

const processForm = reactive({
  factory_id: '',
  notes: ''
})

const showManualModal = ref(false)
const manualShipmentForm = reactive({
  from_factory_id: '',
  to_branch_id: '',
  notes: '',
  target_shipment_date: '',
  estimated_arrival: '',
  items: [] as any[]
})

const addManualItem = () => {
  manualShipmentForm.items.push({
    product_id: '',
    quantity: 1
  })
}

const removeManualItem = (index: number) => {
  manualShipmentForm.items.splice(index, 1)
}

const openManualShipmentModal = () => {
  manualShipmentForm.items = [{ product_id: '', quantity: 1 }]
  manualShipmentForm.notes = ''
  
  if (factoryStore.factories && factoryStore.factories.length > 0) {
    manualShipmentForm.from_factory_id = factoryStore.factories[0]?.id || ''
  }
  
  showManualModal.value = true
}

const handleManualShipment = async () => {
  if (!manualShipmentForm.from_factory_id || !manualShipmentForm.to_branch_id || manualShipmentForm.items.length === 0) {
    toast.error('Mohon lengkapi data pengiriman.')
    return
  }

  processing.value = true
  try {
    await factoryStore.sendToBranch(manualShipmentForm.from_factory_id, {
      to_branch_id: manualShipmentForm.to_branch_id,
      items: manualShipmentForm.items,
      notes: manualShipmentForm.notes,
      target_shipment_date: manualShipmentForm.target_shipment_date,
      estimated_arrival: manualShipmentForm.estimated_arrival,
      initiated_by: 'FACTORY'
    })
    
    // Auto-ship if the user wants? No, let's keep it as REQUESTED first 
    // so they can see it in the list and then click "Proses" to generate the real SJ.
    // Or just make it SHIPPED immediately? 
    // Usually manual shipment means they are shipping it NOW.
    
    toast.success('Pengiriman manual berhasil dibuat.')
    showManualModal.value = false
    await factoryStore.fetchAllTransfers()
  } catch (err) {
    toast.error('Gagal membuat pengiriman: ' + err)
  } finally {
    processing.value = false
  }
}

onMounted(() => {
  factoryStore.fetchAllTransfers()
  factoryStore.fetchFactories()
  factoryStore.fetchProducts()
  masterDataStore.fetchBranches()
})

const groupedTransfers = computed(() => {
  const groups: Record<string, any> = {}
  
  factoryStore.allTransfers.forEach(item => {
    const doNo = item.delivery_order_no || 'DRAFT-' + item.id.substring(0, 8)
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

const incomingRequests = computed(() => {
  // Requests from Branch that need Factory approval
  return groupedTransfers.value.filter(g => g.status === 'REQUESTED')
})

const processedShipments = computed(() => {
  // Shipments that are already APPROVED, SHIPPED, or RECEIVED
  return groupedTransfers.value.filter(g => g.status !== 'REQUESTED').filter(g => {
    if (!searchQuery.value) return true
    return g.doNo.toLowerCase().includes(searchQuery.value.toLowerCase())
  })
})

const processShipment = (request: any) => {
  selectedRequest.value = request
  processForm.notes = ''
  // Try to find if there's a default factory
  if (factoryStore.factories && factoryStore.factories.length > 0) {
    const firstFactory = factoryStore.factories[0]
    if (firstFactory) {
      processForm.factory_id = firstFactory.id
    }
  }
  showProcessModal.value = true
}

const handleConfirmProcess = async () => {
  if (!processForm.factory_id) {
    toast.error('Pilih pabrik pengirim')
    return
  }

  processing.value = true
  try {
    // Process each item in the request
    for (const item of selectedRequest.value.items) {
      // First approve if needed, then ship
      // But based on my backend change, ship accepts REQUESTED/APPROVED
      await factoryStore.shipTransfer(item.id)
    }
    toast.success('Surat Jalan berhasil diterbitkan')
    showProcessModal.value = false
    await factoryStore.fetchAllTransfers()
  } catch (err) {
    toast.error('Gagal memproses pengiriman: ' + err)
  } finally {
    processing.value = false
  }
}



const handleApproveRequest = async (request: any) => {
  if (!confirm('Setujui permintaan barang dari cabang ini?')) return
  
  processing.value = true
  try {
    for (const item of request.items) {
      await factoryStore.approveTransfer(item.id)
    }
    toast.success('Permintaan telah disetujui.')
    await factoryStore.fetchAllTransfers()
  } catch (err) {
    toast.error('Gagal menyetujui permintaan: ' + err)
  } finally {
    processing.value = false
  }
}

const getStatusClass = (status: string) => {
  switch (status) {
    case 'RECEIVED': return 'bg-emerald-50 text-emerald-600 border-emerald-100'
    case 'SHIPPED': return 'bg-blue-50 text-blue-600 border-blue-100'
    case 'REQUESTED': return 'bg-orange-50 text-orange-600 border-orange-100'
    case 'APPROVED': return 'bg-indigo-50 text-indigo-600 border-indigo-100'
    default: return 'bg-slate-50 text-slate-500 border-slate-100'
  }
}
</script>

<style scoped>
.custom-scrollbar::-webkit-scrollbar {
  width: 6px;
}
.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background: #e2e8f0;
  border-radius: 10px;
}
</style>
