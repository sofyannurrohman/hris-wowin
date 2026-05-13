<template>
  <div class="p-8 space-y-8 bg-[#f8fafc] min-h-screen">
    <!-- Header -->
    <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 bg-white p-8 rounded-[2rem] shadow-sm border border-slate-100">
      <div>
        <div class="flex items-center gap-2 text-xs font-bold text-primary uppercase tracking-[0.2em] mb-2">
          <Truck class="h-4 w-4" />
          <span>Fleet & Operations</span>
        </div>
        <h1 class="text-3xl font-black tracking-tight text-slate-900">Manajemen Kendaraan</h1>
        <p class="text-slate-500 mt-1">Kelola armada operasional dan pantau riwayat penggunaan kendaraan.</p>
      </div>
      <Button @click="openAddModal" class="rounded-2xl shadow-lg shadow-primary/20 font-bold h-12 px-8">
        <Plus class="mr-2 h-4 w-4" /> Tambah Kendaraan
      </Button>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-12 gap-8">
      <!-- LEFT SIDE: VEHICLE LIST (7/12) -->
      <div class="lg:col-span-7 space-y-6">
        <div class="flex items-center justify-between px-2">
          <h2 class="text-xl font-black text-slate-900 flex items-center gap-2">
             Daftar Armada
             <Badge variant="secondary" class="rounded-full bg-slate-100 text-slate-500">{{ computedVehicles.length }}</Badge>
          </h2>
        </div>

        <div v-if="vehicleStore.loading" class="flex justify-center py-12 bg-white rounded-[2rem] border border-slate-100">
          <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
        </div>

        <div v-else class="space-y-4">
          <Card v-for="vehicle in computedVehicles" :key="vehicle.id" 
            class="relative overflow-hidden group border-slate-100 shadow-sm rounded-[2rem] transition-all hover:shadow-md cursor-pointer bg-white"
            :class="selectedVehicleId === vehicle.id ? 'ring-2 ring-primary border-transparent shadow-lg' : ''"
            @click="selectVehicle(vehicle)"
          >
            <!-- Background Image Pattern or Placeholder -->
            <div 
              v-if="vehicle.image_url"
              class="absolute top-0 right-0 w-48 h-full opacity-20 transition-all group-hover:scale-105 group-hover:opacity-30 z-0 mask-gradient"
              :style="{ backgroundImage: `url(${baseUrl + vehicle.image_url})`, backgroundSize: 'cover', backgroundPosition: 'center' }"
            ></div>
            <div 
              v-else
              class="absolute top-0 right-0 w-32 h-32 -mr-12 -mt-12 rounded-full opacity-5 transition-transform group-hover:scale-110"
              :class="statusColors[vehicle.computedStatus]"
            ></div>
            
            <div class="relative z-10">
              <CardHeader class="p-6 pb-2">
                <div class="flex justify-between items-start">
                  <div class="flex items-center gap-4">
                    <div v-if="vehicle.image_url" class="h-16 w-16 rounded-2xl overflow-hidden border-2 border-white shadow-md">
                      <img :src="baseUrl + vehicle.image_url" class="h-full w-full object-cover" />
                    </div>
                    <div v-else class="h-16 w-16 rounded-2xl flex items-center justify-center text-white shadow-lg" :class="statusColors[vehicle.computedStatus]">
                      <Truck class="h-8 w-8" />
                    </div>
                    <div>
                      <CardTitle class="text-xl font-black text-slate-900 font-mono">{{ vehicle.license_plate }}</CardTitle>
                      <CardDescription class="font-bold text-slate-500">{{ vehicle.name }}</CardDescription>
                    </div>
                  </div>
                  <Badge :class="getStatusBadgeClass(vehicle.computedStatus)" class="rounded-full px-3 py-1 font-bold text-[10px] uppercase border-none">
                    {{ vehicle.computedStatus }}
                  </Badge>
                </div>
              </CardHeader>
              
              <CardContent class="p-6 pt-4 grid grid-cols-2 gap-y-4 gap-x-8">
                <div class="flex items-center gap-2 text-sm font-bold text-slate-600">
                  <Settings class="h-4 w-4 text-slate-400" />
                  <span>{{ vehicle.model }}</span>
                </div>
                <div class="flex items-center gap-2 text-sm font-bold text-slate-600">
                  <Scale class="h-4 w-4 text-primary" />
                  <span>Kapasitas: <span class="text-slate-900 ml-1">{{ vehicle.capacity }} KG</span></span>
                </div>
                <div class="flex items-center gap-2 text-sm font-bold text-slate-600">
                  <Timer class="h-4 w-4 text-slate-400" />
                  <span>{{ vehicle.mileage.toLocaleString() }} KM</span>
                </div>
                <div class="flex items-center gap-2 text-sm font-bold text-slate-600">
                  <MapPin class="h-4 w-4 text-slate-400" />
                  <span>{{ vehicle.branch?.name || 'Pusat' }}</span>
                </div>
              </CardContent>
              
              <CardFooter class="flex justify-end gap-2 bg-slate-50/50 border-t p-4 px-6 mt-2">
                <Button variant="ghost" size="sm" @click.stop="openEditModal(vehicle)" class="rounded-xl font-bold hover:text-primary">Edit</Button>
                <Button variant="ghost" size="sm" class="rounded-xl font-bold text-destructive hover:bg-destructive/5" @click.stop="handleDelete(vehicle.id)">Hapus</Button>
              </CardFooter>
            </div>
          </Card>
        </div>
      </div>

      <!-- RIGHT SIDE: ACTIVITY LOG & DRIVERS (5/12) -->
      <div class="lg:col-span-5 space-y-6">
        <div class="flex items-center justify-between px-2">
          <div class="flex bg-white p-1 rounded-2xl border border-slate-100 shadow-sm">
            <button 
              @click="activeTab = 'LOGS'" 
              :class="[activeTab === 'LOGS' ? 'bg-slate-900 text-white' : 'text-slate-500 hover:bg-slate-50']"
              class="px-4 py-2 rounded-xl text-xs font-black transition-all flex items-center gap-2"
            >
              <History class="h-3.5 w-3.5" /> LOG AKTIVITAS
            </button>
            <button 
              @click="activeTab = 'DRIVERS'" 
              :class="[activeTab === 'DRIVERS' ? 'bg-slate-900 text-white' : 'text-slate-500 hover:bg-slate-50']"
              class="px-4 py-2 rounded-xl text-xs font-black transition-all flex items-center gap-2"
            >
              <User class="h-3.5 w-3.5" /> STATUS DRIVER
            </button>
          </div>
          <Badge v-if="activeTab === 'LOGS' && selectedVehicle" variant="outline" class="rounded-full border-slate-200 text-slate-500 font-mono">{{ selectedVehicle.license_plate }}</Badge>
          <Badge v-else-if="activeTab === 'DRIVERS'" variant="secondary" class="rounded-full bg-primary/10 text-primary font-bold">{{ driverStatus.length }}</Badge>
        </div>

        <div class="bg-white rounded-[2.5rem] border border-slate-100 shadow-sm overflow-hidden min-h-[500px] flex flex-col">
          
          <!-- TAB: LOGS -->
          <template v-if="activeTab === 'LOGS'">
            <!-- Vehicle Detail Preview if selected -->
            <div v-if="selectedVehicle" class="p-6 border-b border-slate-50 bg-slate-50/20">
              <div v-if="selectedVehicle.image_url" class="w-full h-48 rounded-3xl overflow-hidden mb-4 border border-slate-100 shadow-inner">
                 <img :src="baseUrl + selectedVehicle.image_url" class="w-full h-full object-cover" />
              </div>
              <div class="grid grid-cols-2 gap-4">
                 <div class="bg-white p-3 rounded-2xl border border-slate-100 shadow-sm">
                    <p class="text-[9px] font-black text-slate-400 uppercase tracking-widest mb-1">Kapasitas Muatan</p>
                    <p class="text-lg font-black text-primary">{{ selectedVehicle.capacity }} KG</p>
                 </div>
                 <div class="bg-white p-3 rounded-2xl border border-slate-100 shadow-sm">
                    <p class="text-[9px] font-black text-slate-400 uppercase tracking-widest mb-1">Tahun Kendaraan</p>
                    <p class="text-lg font-black text-slate-700">{{ selectedVehicle.year }}</p>
                 </div>
              </div>
            </div>

            <div v-if="!selectedVehicleId" class="flex-1 flex flex-col items-center justify-center text-center p-8">
              <div class="bg-slate-50 h-20 w-20 rounded-[2rem] flex items-center justify-center text-slate-200 mb-4">
                <History class="h-10 w-10" />
              </div>
              <h3 class="font-bold text-slate-900">Pilih Kendaraan</h3>
              <p class="text-sm text-slate-500 mt-1 max-w-xs mx-auto">Klik kendaraan untuk melihat riwayat aktivitasnya.</p>
            </div>

            <div v-else-if="loadingLogs" class="flex-1 flex items-center justify-center">
               <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
            </div>

            <div v-else class="flex-1 p-2 overflow-y-auto custom-scrollbar min-h-0">
              <div v-if="vehicleStore.logs.length === 0" class="flex flex-col items-center justify-center h-full text-center p-8 opacity-50">
                <ClipboardList class="h-12 w-12 text-slate-300 mb-3" />
                <p class="text-sm font-bold text-slate-400">Belum ada riwayat aktivitas</p>
              </div>

              <div v-else class="space-y-4 p-4">
                 <div v-for="log in vehicleStore.logs" :key="log.id" class="relative pl-8 before:absolute before:left-[11px] before:top-8 before:bottom-[-20px] before:w-[2px] before:bg-slate-100 last:before:hidden">
                    <div class="absolute left-0 top-1 h-6 w-6 rounded-full bg-white border-4 border-slate-50 ring-2 ring-primary/20 z-10"></div>
                    <div class="bg-slate-50/50 rounded-2xl p-4 border border-slate-100 group hover:bg-white transition-all hover:shadow-sm">
                      <div class="flex justify-between items-start mb-2">
                         <p class="text-[10px] font-black text-slate-400 uppercase tracking-widest">{{ formatDate(log.created_at) }}</p>
                         <Badge class="bg-primary/10 text-primary border-none text-[9px] font-bold">{{ log.status }}</Badge>
                      </div>
                      <h4 class="font-bold text-slate-900 text-sm mb-1">{{ log.delivery_order_no || 'Tugas Delivery' }}</h4>
                      <div class="flex items-center gap-2 text-xs text-slate-500 font-medium">
                        <User class="h-3 w-3" />
                        <span>Driver: {{ log.driver?.name || 'Unknown' }}</span>
                      </div>
                    </div>
                 </div>
              </div>
            </div>
          </template>

          <!-- TAB: DRIVERS -->
          <template v-else>
            <div v-if="loadingDrivers" class="flex-1 flex items-center justify-center">
               <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
            </div>
            
            <div v-else class="flex-1 p-4 overflow-y-auto custom-scrollbar min-h-0">
               <div class="space-y-3">
                 <div v-for="driver in driverStatus" :key="driver.id" class="p-5 bg-white border border-slate-100 rounded-3xl hover:border-primary/20 transition-all group shadow-sm">
                    <div class="flex items-center justify-between mb-3">
                       <div class="flex items-center gap-3">
                          <div class="h-10 w-10 rounded-2xl bg-slate-100 flex items-center justify-center text-slate-400 group-hover:bg-primary/10 group-hover:text-primary transition-all">
                             <User class="h-5 w-5" />
                          </div>
                          <div>
                             <h4 class="font-black text-slate-900 leading-none">{{ driver.first_name }} {{ driver.last_name }}</h4>
                             <p class="text-[10px] font-bold text-slate-400 mt-1 uppercase tracking-widest">{{ driver.job_position?.title || 'DRIVER' }}</p>
                          </div>
                       </div>
                       <Badge :class="[
                         driver.computedStatus === 'AVAILABLE' ? 'bg-emerald-50 text-emerald-600' :
                         driver.computedStatus === 'DELIVERING' ? 'bg-blue-50 text-blue-600' : 'bg-amber-50 text-amber-600'
                       ]" class="rounded-full border-none text-[9px] font-black uppercase tracking-wider">
                         {{ driver.computedStatus }}
                       </Badge>
                    </div>
                    
                    <div v-if="driver.currentTask" class="mt-4 p-3 bg-slate-50 rounded-2xl flex items-start gap-3 border border-slate-100">
                       <div class="p-2 bg-white rounded-xl text-primary shadow-sm">
                          <Truck class="h-3.5 w-3.5" />
                       </div>
                       <div>
                          <p class="text-[9px] font-black text-slate-400 uppercase tracking-widest leading-none">Aktifitas Saat Ini</p>
                          <p class="text-xs font-black text-slate-700 mt-1.5">{{ driver.currentTask }}</p>
                       </div>
                    </div>
                    <div v-else class="mt-4 p-3 border-2 border-dashed border-slate-50 rounded-2xl flex items-center justify-center">
                       <p class="text-[10px] font-bold text-slate-300 uppercase tracking-widest italic">Belum ada penugasan</p>
                    </div>
                 </div>
               </div>
            </div>
          </template>
        </div>
      </div>
    </div>

    <!-- Modal Form -->
    <div v-if="showModal" class="fixed inset-0 bg-slate-900/60 backdrop-blur-md z-[100] flex items-center justify-center p-4">
      <Card class="w-full max-w-xl shadow-2xl rounded-[2.5rem] overflow-hidden border-none animate-in fade-in zoom-in-95 duration-300">
        <CardHeader class="p-8 border-b bg-white">
          <div class="flex justify-between items-center">
            <div>
              <CardTitle class="text-2xl font-black text-slate-900">{{ isEditing ? 'Edit Kendaraan' : 'Tambah Kendaraan' }}</CardTitle>
              <CardDescription>Lengkapi spesifikasi armada operasional.</CardDescription>
            </div>
            <Button variant="ghost" size="icon" @click="showModal = false" class="rounded-full">
              <Plus class="h-6 w-6 rotate-45 text-slate-400" />
            </Button>
          </div>
        </CardHeader>
        <CardContent class="p-8 space-y-6 bg-white max-h-[70vh] overflow-y-auto custom-scrollbar pr-4">
          <!-- Image Upload Area -->
          <div class="space-y-2">
             <label class="text-xs font-black text-slate-400 uppercase tracking-widest ml-1">Foto Kendaraan (Tampak Depan)</label>
             <div 
               @click="fileInput?.click()"
               class="relative w-full h-48 rounded-[2rem] border-2 border-dashed border-slate-200 bg-slate-50 flex flex-col items-center justify-center cursor-pointer hover:border-primary hover:bg-primary/5 transition-all group overflow-hidden"
             >
                <img v-if="imagePreview" :src="imagePreview" class="absolute inset-0 w-full h-full object-cover" />
                <div v-else class="flex flex-col items-center text-slate-400 group-hover:text-primary">
                  <Camera class="h-10 w-10 mb-2" />
                  <span class="text-xs font-bold uppercase tracking-widest">Klik untuk Upload Foto</span>
                </div>
                <div v-if="imagePreview" class="absolute inset-0 bg-black/40 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                   <div class="bg-white p-3 rounded-full text-slate-900 shadow-xl">
                      <RefreshCw class="h-5 w-5" />
                   </div>
                </div>
                <input ref="fileInput" type="file" accept="image/*" class="hidden" @change="handleImageChange" />
             </div>
          </div>

          <div class="grid grid-cols-2 gap-6">
            <div class="space-y-2">
              <label class="text-xs font-black text-slate-400 uppercase tracking-widest ml-1">Nama Unit</label>
              <input v-model="form.name" placeholder="Truk Wingbox A1" class="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold outline-none focus:ring-4 focus:ring-primary/5 transition-all" />
            </div>
            <div class="space-y-2">
              <label class="text-xs font-black text-slate-400 uppercase tracking-widest ml-1">Plat Nomor</label>
              <input v-model="form.license_plate" placeholder="B 1234 ABC" class="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold font-mono outline-none focus:ring-4 focus:ring-primary/5 transition-all" />
            </div>
          </div>

          <div class="grid grid-cols-2 gap-6">
            <div class="space-y-2">
              <label class="text-xs font-black text-slate-400 uppercase tracking-widest ml-1">Model / Brand</label>
              <input v-model="form.model" placeholder="Hino 500 / Mitsubishi" class="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold outline-none focus:ring-4 focus:ring-primary/5 transition-all" />
            </div>
            <div class="space-y-2">
              <label class="text-xs font-black text-slate-400 uppercase tracking-widest ml-1">Kapasitas Muatan (KG)</label>
              <div class="relative">
                <input type="number" v-model="form.capacity" placeholder="0.00" class="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold outline-none focus:ring-4 focus:ring-primary/5 transition-all pl-12" />
                <Scale class="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
              </div>
            </div>
          </div>

          <div class="grid grid-cols-2 gap-6">
             <div class="space-y-2">
              <label class="text-xs font-black text-slate-400 uppercase tracking-widest ml-1">Tipe Kendaraan</label>
              <select v-model="form.type" class="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold outline-none appearance-none cursor-pointer">
                <option value="TRUCK">Truk</option>
                <option value="VAN">Blind Van</option>
                <option value="CAR">Mobil Penumpang</option>
                <option value="MOTORCYCLE">Sepeda Motor</option>
              </select>
            </div>
            <div class="space-y-2">
              <label class="text-xs font-black text-slate-400 uppercase tracking-widest ml-1">Tahun Armada</label>
              <input type="number" v-model="form.year" class="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold outline-none" />
            </div>
          </div>

          <div class="space-y-2">
            <label class="text-xs font-black text-slate-400 uppercase tracking-widest ml-1">Kilometer Terakhir (KM)</label>
            <input type="number" v-model="form.mileage" class="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold outline-none" />
          </div>

          <div class="space-y-2">
            <label class="text-xs font-black text-slate-400 uppercase tracking-widest ml-1">Status Operasional</label>
            <div class="grid grid-cols-2 gap-3">
              <div v-for="status in ['AVAILABLE', 'IN_USE', 'MAINTENANCE', 'BROKEN']" :key="status"
                @click="form.status = status"
                class="flex items-center gap-3 p-4 rounded-2xl border cursor-pointer transition-all"
                :class="[form.status === status ? 'bg-primary/5 border-primary shadow-sm' : 'bg-slate-50 border-slate-100 opacity-60']"
              >
                <div class="h-3 w-3 rounded-full" :class="statusColors[status]"></div>
                <span class="text-xs font-black text-slate-700">{{ status }}</span>
              </div>
            </div>
          </div>
        </CardContent>
        <CardFooter class="bg-slate-50/50 border-t p-8 flex justify-end gap-4">
          <Button variant="ghost" @click="showModal = false" class="rounded-2xl font-bold h-12 px-8">Batal</Button>
          <Button @click="handleSubmit" :loading="loading" class="rounded-2xl px-12 h-12 shadow-xl shadow-primary/20 font-black text-white bg-primary hover:bg-primary/90">
            {{ isEditing ? 'Simpan Data' : 'Tambah Armada' }}
          </Button>
        </CardFooter>
      </Card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref, reactive, computed, watch } from 'vue'
import { useVehicleStore } from '@/stores/vehicle'
import { useDeliveryStore } from '@/stores/delivery'
import { useMasterDataStore } from '@/stores/masterData'
import { useFactoryStore } from '@/stores/factory'
import apiClient from '@/api/axios'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card/index'
import { Badge } from '@/components/ui/badge/index'
import { 
  Truck, 
  Calendar, 
  Timer, 
  MapPin, 
  Plus, 
  Settings, 
  History, 
  ClipboardList, 
  User,
  Camera,
  RefreshCw,
  Scale 
} from 'lucide-vue-next'
import { toast } from 'vue-sonner'

const vehicleStore = useVehicleStore()
const deliveryStore = useDeliveryStore()
const masterStore = useMasterDataStore()
const factoryStore = useFactoryStore()

const showModal = ref(false)
const isEditing = ref(false)
const loading = ref(false)
const loadingLogs = ref(false)
const loadingDrivers = ref(false)
const currentId = ref('')
const selectedVehicleId = ref('')
const activeTab = ref('LOGS') // 'LOGS' or 'DRIVERS'

const imageFile = ref<File | null>(null)
const imagePreview = ref('')
const fileInput = ref<HTMLInputElement | null>(null)

const drivers = ref<any[]>([])

const baseUrl = import.meta.env.VITE_API_URL || 'http://localhost:8080'

const form = reactive({
  name: '',
  license_plate: '',
  model: '',
  type: 'TRUCK',
  status: 'AVAILABLE',
  year: new Date().getFullYear(),
  mileage: 0,
  capacity: 0
})

const fetchDrivers = async () => {
  loadingDrivers.value = true
  try {
    await masterStore.fetchEmployees()
    await deliveryStore.fetchBatches()
  } finally {
    loadingDrivers.value = false
  }
}

const driverStatus = computed(() => {
  const filteredDrivers = masterStore.employees.filter((emp: any) => {
    const activeBatch = deliveryStore.batches.find(b => b.driver_id === emp.id && b.status !== 'COMPLETED')
    const activeTransfer = factoryStore.allTransfers.find((t: any) => t.driver_id === emp.id && (t.status === 'SHIPPED' || t.status === 'ARRIVED'))
    
    // Always include if they are actively delivering
    if (activeBatch || activeTransfer) return true

    // If job title is missing, include them just in case they are assigned
    if (!emp.job_position?.title) return true
    const jobTitle = emp.job_position.title.toLowerCase()
    return jobTitle.includes('driver') || jobTitle.includes('sopir') || jobTitle.includes('salesman') || jobTitle.includes('motoris')
  })

  const statusArray = filteredDrivers.map(driver => {
    const activeBatch = deliveryStore.batches.find(b => b.driver_id === driver.id && b.status !== 'COMPLETED')
    const activeTransfer = factoryStore.allTransfers.find((t: any) => t.driver_id === driver.id && (t.status === 'SHIPPED' || t.status === 'ARRIVED'))
    
    let status = 'AVAILABLE'
    let currentTask = ''
    
    if (activeTransfer) {
      status = 'DELIVERING'
      const from = activeTransfer.from_factory?.name || 'Pabrik'
      const to = activeTransfer.to_branch?.name || 'Cabang'
      currentTask = `${activeTransfer.delivery_order_no || 'Pindah Gudang'} (${from} → ${to})`
    } else if (activeBatch) {
      if (activeBatch.status === 'ON_DELIVERY' || activeBatch.status === 'PICKING') {
        status = 'DELIVERING'
        currentTask = `${activeBatch.delivery_order_no || 'Tugas Pengiriman'} (Cabang → Pelanggan)`
      } else {
        status = 'WORKING'
        currentTask = 'Persiapan / Standby'
      }
    }
    
    return {
      ...driver,
      computedStatus: status,
      currentTask
    }
  })

  return statusArray.sort((a, b) => {
    const rank = (s: string) => s === 'DELIVERING' ? 0 : s === 'WORKING' ? 1 : 2
    return rank(a.computedStatus) - rank(b.computedStatus)
  })
})

const computedVehicles = computed(() => {
  return vehicleStore.vehicles.map(vehicle => {
    const activeTransfer = factoryStore.allTransfers.find((t: any) => 
      t.vehicle_id === vehicle.id && (t.status === 'SHIPPED' || t.status === 'ARRIVED')
    )
    
    // We don't have vehicle_id in delivery batch yet but just in case for future proof
    const activeBatch = deliveryStore.batches.find((b: any) => 
      b.vehicle_id === vehicle.id && b.status !== 'COMPLETED'
    )
    
    let currentStatus = vehicle.status
    if (currentStatus === 'AVAILABLE') {
      if (activeTransfer || (activeBatch && (activeBatch.status === 'ON_DELIVERY' || activeBatch.status === 'PICKING'))) {
        currentStatus = 'IN_USE'
      }
    }
    
    return {
      ...vehicle,
      computedStatus: currentStatus,
      activeTask: activeTransfer?.delivery_order_no || activeBatch?.delivery_order_no || ''
    }
  })
})

onMounted(() => {
  vehicleStore.fetchVehicles()
  fetchDrivers()
  factoryStore.fetchAllTransfers()
})

watch(() => masterStore.selectedBranchId, () => {
  vehicleStore.fetchVehicles()
  fetchDrivers()
  factoryStore.fetchAllTransfers()
})

const selectedVehicle = computed(() => {
  return vehicleStore.vehicles.find(v => v.id === selectedVehicleId.value)
})

const selectVehicle = async (vehicle: any) => {
  selectedVehicleId.value = vehicle.id
  loadingLogs.value = true
  try {
    await vehicleStore.fetchVehicleLogs(vehicle.id)
  } finally {
    loadingLogs.value = false
  }
}

const handleImageChange = (e: any) => {
  const file = e.target.files[0]
  if (file) {
    imageFile.value = file
    imagePreview.value = URL.createObjectURL(file)
  }
}

const openAddModal = () => {
  isEditing.value = false
  imageFile.value = null
  imagePreview.value = ''
  Object.assign(form, {
    name: '',
    license_plate: '',
    model: '',
    type: 'TRUCK',
    status: 'AVAILABLE',
    year: new Date().getFullYear(),
    mileage: 0,
    capacity: 0
  })
  showModal.value = true
}

const openEditModal = (vehicle: any) => {
  isEditing.value = true
  currentId.value = vehicle.id
  imageFile.value = null
  imagePreview.value = vehicle.image_url ? (baseUrl + vehicle.image_url) : ''
  Object.assign(form, {
    name: vehicle.name,
    license_plate: vehicle.license_plate,
    model: vehicle.model,
    type: vehicle.type,
    status: vehicle.status,
    year: vehicle.year,
    mileage: vehicle.mileage,
    capacity: vehicle.capacity || 0
  })
  showModal.value = true
}

const handleSubmit = async () => {
  if (!form.name || !form.license_plate) {
    toast.error('Nama dan Plat Nomor harus diisi')
    return
  }

  const formData = new FormData()
  Object.keys(form).forEach(key => {
    const val = (form as any)[key]
    if (val !== null && val !== undefined) {
      formData.append(key, val.toString())
    }
  })
  if (imageFile.value) {
    formData.append('image', imageFile.value)
  }

  loading.value = true
  try {
    if (isEditing.value) {
      await vehicleStore.updateVehicle(currentId.value, formData)
      toast.success('Data kendaraan diperbarui')
    } else {
      await vehicleStore.addVehicle(formData)
      toast.success('Kendaraan baru ditambahkan')
    }
    showModal.value = false
  } catch (err) {
    toast.error('Gagal menyimpan: ' + err)
  } finally {
    loading.value = false
  }
}

const handleDelete = async (id: string) => {
  if (!confirm('Hapus kendaraan ini dari armada?')) return
  try {
    await vehicleStore.removeVehicle(id)
    toast.success('Kendaraan dihapus')
    if (selectedVehicleId.value === id) {
      selectedVehicleId.value = ''
    }
  } catch (err) {
    toast.error('Gagal menghapus: ' + err)
  }
}

const formatDate = (dateStr: string) => {
  if (!dateStr) return '-'
  const date = new Date(dateStr)
  return date.toLocaleDateString('id-ID', { 
    day: '2-digit', 
    month: 'short', 
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const statusColors: Record<string, string> = {
  AVAILABLE: 'bg-emerald-500',
  IN_USE: 'bg-blue-500',
  MAINTENANCE: 'bg-orange-500',
  BROKEN: 'bg-rose-500'
}

const getStatusBadgeClass = (status: string) => {
  switch (status) {
    case 'AVAILABLE': return 'bg-emerald-50 text-emerald-600'
    case 'IN_USE': return 'bg-blue-50 text-blue-600'
    case 'MAINTENANCE': return 'bg-orange-50 text-orange-600'
    case 'BROKEN': return 'bg-rose-50 text-rose-600'
    default: return 'bg-slate-50 text-slate-500'
  }
}
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
.mask-gradient {
  mask-image: linear-gradient(to left, rgba(0,0,0,1), rgba(0,0,0,0));
}
</style>
