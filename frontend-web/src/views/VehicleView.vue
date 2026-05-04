<template>
  <div class="p-6 space-y-6">
    <div class="flex justify-between items-center">
      <div>
        <h1 class="text-3xl font-bold tracking-tight">Kendaraan Operasional</h1>
        <p class="text-muted-foreground">Kelola armada kendaraan untuk pengiriman dan operasional sales.</p>
      </div>
      <Button @click="openAddModal">Tambah Kendaraan</Button>
    </div>

    <div v-if="vehicleStore.loading" class="flex justify-center py-12">
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
    </div>

    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <Card v-for="vehicle in vehicleStore.vehicles" :key="vehicle.id" class="relative overflow-hidden group">
        <div 
          class="absolute top-0 right-0 w-24 h-24 -mr-8 -mt-8 rounded-full opacity-10 transition-transform group-hover:scale-110"
          :class="statusColors[vehicle.status]"
        ></div>
        
        <CardHeader>
          <div class="flex justify-between items-start">
            <CardTitle class="text-xl font-bold">{{ vehicle.license_plate }}</CardTitle>
            <Badge :variant="badgeVariants[vehicle.status]">{{ vehicle.status }}</Badge>
          </div>
          <CardDescription>{{ vehicle.name }}</CardDescription>
        </CardHeader>
        
        <CardContent class="space-y-3">
          <div class="flex items-center gap-2 text-sm">
            <Truck class="h-4 w-4 text-muted-foreground" />
            <span>{{ vehicle.model }} ({{ vehicle.type }})</span>
          </div>
          <div class="flex items-center gap-2 text-sm">
            <Calendar class="h-4 w-4 text-muted-foreground" />
            <span>Tahun {{ vehicle.year }}</span>
          </div>
          <div class="flex items-center gap-2 text-sm">
            <Timer class="h-4 w-4 text-muted-foreground" />
            <span>{{ vehicle.mileage.toLocaleString() }} KM</span>
          </div>
          <div v-if="vehicle.branch" class="flex items-center gap-2 text-sm">
            <MapPin class="h-4 w-4 text-muted-foreground" />
            <span>{{ vehicle.branch.name }}</span>
          </div>
        </CardContent>
        
        <CardFooter class="flex justify-end gap-2 bg-slate-50/50 border-t p-3">
          <Button variant="ghost" size="sm" @click="openEditModal(vehicle)">Edit</Button>
          <Button variant="ghost" size="sm" class="text-destructive hover:text-destructive" @click="handleDelete(vehicle.id)">Hapus</Button>
        </CardFooter>
      </Card>
    </div>

    <!-- Modal Form -->
    <div v-if="showModal" class="fixed inset-0 bg-background/80 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <Card class="w-full max-w-lg shadow-2xl">
        <CardHeader>
          <CardTitle>{{ isEditing ? 'Edit Kendaraan' : 'Tambah Kendaraan Baru' }}</CardTitle>
        </CardHeader>
        <CardContent class="space-y-4 max-h-[70vh] overflow-y-auto pr-2">
          <div class="grid grid-cols-2 gap-4">
            <div class="space-y-2">
              <label class="text-sm font-medium">Nama Kendaraan</label>
              <input v-model="form.name" placeholder="Truk Wingbox A1" class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm" />
            </div>
            <div class="space-y-2">
              <label class="text-sm font-medium">Plat Nomor</label>
              <input v-model="form.license_plate" placeholder="B 1234 ABC" class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm" />
            </div>
          </div>
          <div class="grid grid-cols-2 gap-4">
            <div class="space-y-2">
              <label class="text-sm font-medium">Model</label>
              <input v-model="form.model" placeholder="Hino 500" class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm" />
            </div>
            <div class="space-y-2">
              <label class="text-sm font-medium">Tipe</label>
              <select v-model="form.type" class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm">
                <option value="TRUCK">Truk</option>
                <option value="VAN">Blind Van</option>
                <option value="CAR">Mobil Penumpang</option>
                <option value="MOTORCYCLE">Sepeda Motor</option>
              </select>
            </div>
          </div>
          <div class="grid grid-cols-2 gap-4">
            <div class="space-y-2">
              <label class="text-sm font-medium">Tahun</label>
              <input type="number" v-model="form.year" class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm" />
            </div>
            <div class="space-y-2">
              <label class="text-sm font-medium">KM Terakhir</label>
              <input type="number" v-model="form.mileage" class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm" />
            </div>
          </div>
          <div class="space-y-2">
            <label class="text-sm font-medium">Status</label>
            <select v-model="form.status" class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm">
              <option value="AVAILABLE">Tersedia</option>
              <option value="IN_USE">Sedang Digunakan</option>
              <option value="MAINTENANCE">Dalam Perbaikan</option>
              <option value="BROKEN">Rusak</option>
            </select>
          </div>
        </CardContent>
        <CardFooter class="flex justify-end gap-2 border-t pt-4">
          <Button variant="outline" @click="showModal = false">Batal</Button>
          <Button @click="handleSubmit">{{ isEditing ? 'Simpan' : 'Tambah' }}</Button>
        </CardFooter>
      </Card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref, reactive } from 'vue'
import { useVehicleStore } from '@/stores/vehicle'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card/index'
import { Badge } from '@/components/ui/badge/index'
import { Truck, Calendar, Timer, MapPin } from 'lucide-vue-next'

const vehicleStore = useVehicleStore()
const showModal = ref(false)
const isEditing = ref(false)
const currentId = ref('')

const form = reactive({
  name: '',
  license_plate: '',
  model: '',
  type: 'TRUCK',
  status: 'AVAILABLE',
  year: new Date().getFullYear(),
  mileage: 0
})

onMounted(() => {
  vehicleStore.fetchVehicles()
})

const openAddModal = () => {
  isEditing.value = false
  Object.assign(form, {
    name: '',
    license_plate: '',
    model: '',
    type: 'TRUCK',
    status: 'AVAILABLE',
    year: new Date().getFullYear(),
    mileage: 0
  })
  showModal.value = true
}

const openEditModal = (vehicle: any) => {
  isEditing.value = true
  currentId.value = vehicle.id
  Object.assign(form, {
    name: vehicle.name,
    license_plate: vehicle.license_plate,
    model: vehicle.model,
    type: vehicle.type,
    status: vehicle.status,
    year: vehicle.year,
    mileage: vehicle.mileage
  })
  showModal.value = true
}

const handleSubmit = async () => {
  try {
    if (isEditing.value) {
      await vehicleStore.updateVehicle(currentId.value, form)
    } else {
      await vehicleStore.addVehicle(form)
    }
    showModal.value = false
  } catch (err) {
    alert(err)
  }
}

const handleDelete = async (id: string) => {
  if (confirm('Hapus kendaraan ini?')) {
    try {
      await vehicleStore.removeVehicle(id)
    } catch (err) {
      alert(err)
    }
  }
}

const statusColors: Record<string, string> = {
  AVAILABLE: 'bg-green-500',
  IN_USE: 'bg-blue-500',
  MAINTENANCE: 'bg-yellow-500',
  BROKEN: 'bg-red-500'
}

const badgeVariants: Record<string, "default" | "secondary" | "outline" | "destructive"> = {
  AVAILABLE: 'default',
  IN_USE: 'secondary',
  MAINTENANCE: 'outline',
  BROKEN: 'destructive'
}
</script>
