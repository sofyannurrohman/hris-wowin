<template>
  <div class="p-8 space-y-8 bg-[#f8fafc] min-h-screen">
    <!-- Header -->
    <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
      <div>
        <h1 class="text-3xl font-extrabold tracking-tight text-slate-900">Dashboard Pabrik</h1>
        <p class="text-slate-500 mt-1">Pantau produksi, stok, dan pengiriman barang dari seluruh pabrik Wowin.</p>
      </div>
      <div class="flex gap-3">
        <Button variant="outline" class="rounded-xl bg-white border-slate-200 text-slate-600 hover:bg-slate-50">
          <Download class="mr-2 h-4 w-4" /> Export Report
        </Button>
        <Button @click="showAddFactory = true" class="rounded-xl shadow-lg shadow-primary/20 transition-all hover:scale-105">
          <Plus class="mr-2 h-4 w-4" /> Tambah Pabrik
        </Button>
      </div>
    </div>

    <!-- KPI Stats -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
      <Card class="border-none shadow-sm bg-white overflow-hidden relative group">
        <div class="absolute right-0 top-0 p-3 opacity-10 group-hover:scale-110 transition-transform">
          <Factory class="h-16 w-16 text-primary" />
        </div>
        <CardContent class="p-6">
          <p class="text-sm font-medium text-slate-500 uppercase tracking-wider">Total Pabrik</p>
          <h3 class="text-3xl font-bold text-slate-900 mt-2">{{ factoryStore.factories.length }}</h3>
          <div class="flex items-center mt-4 text-emerald-600 text-sm font-medium">
            <span class="bg-emerald-50 px-2 py-0.5 rounded-full">Operasional Aktif</span>
          </div>
        </CardContent>
      </Card>

      <Card class="border-none shadow-sm bg-white overflow-hidden relative group">
        <div class="absolute right-0 top-0 p-3 opacity-10 group-hover:scale-110 transition-transform">
          <Package class="h-16 w-16 text-blue-600" />
        </div>
        <CardContent class="p-6">
          <p class="text-sm font-medium text-slate-500 uppercase tracking-wider">Total Produk</p>
          <h3 class="text-3xl font-bold text-slate-900 mt-2">{{ factoryStore.products.length }}</h3>
          <div class="flex items-center mt-4 text-slate-500 text-sm">
            <span>Master data produk aktif</span>
          </div>
        </CardContent>
      </Card>

      <Card class="border-none shadow-sm bg-white overflow-hidden relative group">
        <div class="absolute right-0 top-0 p-3 opacity-10 group-hover:scale-110 transition-transform">
          <Truck class="h-16 w-16 text-orange-600" />
        </div>
        <CardContent class="p-6">
          <p class="text-sm font-medium text-slate-500 uppercase tracking-wider">Pengiriman Pending</p>
          <h3 class="text-3xl font-bold text-slate-900 mt-2">12</h3>
          <div class="flex items-center mt-4 text-orange-600 text-sm font-medium">
            <AlertCircle class="mr-1 h-3.5 w-3.5" />
            <span>Butuh konfirmasi gudang</span>
          </div>
        </CardContent>
      </Card>

      <Card class="border-none shadow-sm bg-white overflow-hidden relative group">
        <div class="absolute right-0 top-0 p-3 opacity-10 group-hover:scale-110 transition-transform">
          <Activity class="h-16 w-16 text-indigo-600" />
        </div>
        <CardContent class="p-6">
          <p class="text-sm font-medium text-slate-500 uppercase tracking-wider">Produksi Hari Ini</p>
          <h3 class="text-3xl font-bold text-slate-900 mt-2">1,240 <span class="text-sm font-normal text-slate-400">pcs</span></h3>
          <div class="flex items-center mt-4 text-emerald-600 text-sm font-medium">
            <TrendingUp class="mr-1 h-3.5 w-3.5" />
            <span>8% vs kemarin</span>
          </div>
        </CardContent>
      </Card>
    </div>

    <!-- Main Content Grid -->
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
      <!-- Factory List (2/3 width) -->
      <div class="lg:col-span-2 space-y-6">
        <div class="flex items-center justify-between">
          <h2 class="text-xl font-bold text-slate-900">Lokasi Pabrik</h2>
          <Button variant="link" class="text-primary font-semibold">Lihat Semua</Button>
        </div>

        <div v-if="factoryStore.loading" class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div v-for="i in 4" :key="i" class="h-48 bg-slate-100 animate-pulse rounded-2xl"></div>
        </div>

        <div v-else-if="factoryStore.factories.length === 0" class="flex flex-col items-center justify-center py-20 bg-white rounded-3xl border-2 border-dashed border-slate-200 text-center px-6">
          <div class="w-20 h-20 bg-slate-50 rounded-full flex items-center justify-center mb-4">
            <Factory class="h-10 w-10 text-slate-300" />
          </div>
          <h3 class="text-lg font-bold text-slate-900">Belum Ada Pabrik</h3>
          <p class="text-slate-500 max-w-xs mt-2">Daftarkan lokasi pabrik baru Anda untuk mulai mengelola inventory dan produksi.</p>
          <Button @click="showAddFactory = true" class="mt-6 rounded-xl px-8">Tambah Sekarang</Button>
        </div>

        <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div 
            v-for="factory in factoryStore.factories" 
            :key="factory.id" 
            class="group bg-white rounded-2xl p-6 shadow-sm border border-slate-100 hover:border-primary/20 hover:shadow-xl hover:shadow-primary/5 transition-all duration-300 cursor-pointer"
            @click="goToFactory(factory.id)"
          >
            <div class="flex justify-between items-start mb-4">
              <div class="w-12 h-12 bg-slate-50 rounded-xl flex items-center justify-center text-primary group-hover:bg-primary group-hover:text-white transition-colors">
                <Factory class="h-6 w-6" />
              </div>
              <Badge variant="secondary" class="bg-blue-50 text-blue-600 border-none rounded-full px-3 py-1">
                {{ factory.branch?.name || 'No Branch' }}
              </Badge>
            </div>
            
            <h3 class="text-lg font-bold text-slate-900 group-hover:text-primary transition-colors">{{ factory.name }}</h3>
            <p class="text-sm text-slate-500 mt-1 flex items-center">
              <MapPin class="mr-1 h-3.5 w-3.5" /> {{ factory.location }}
            </p>

            <div class="mt-6 pt-6 border-t border-slate-50 flex items-center justify-between">
              <div class="flex -space-x-2">
                <div v-for="i in 3" :key="i" class="w-8 h-8 rounded-full bg-slate-100 border-2 border-white flex items-center justify-center">
                  <Package class="h-3 w-3 text-slate-400" />
                </div>
                <div class="w-8 h-8 rounded-full bg-slate-50 border-2 border-white flex items-center justify-center text-[10px] font-bold text-slate-400">
                  +5
                </div>
              </div>
              <Button variant="ghost" size="sm" class="text-primary font-bold group-hover:translate-x-1 transition-transform">
                Kelola <ChevronRight class="ml-1 h-4 w-4" />
              </Button>
            </div>
          </div>
        </div>
      </div>

      <!-- Demand Analysis / Backorder Queue (1/3 width) -->
      <div class="space-y-6">
        <div class="flex items-center justify-between">
          <h2 class="text-xl font-bold text-slate-900">Analisis Permintaan</h2>
          <Badge variant="outline" class="bg-red-50 text-red-600 border-red-100 px-3 py-1 rounded-full text-[10px] font-bold">
            Real-time
          </Badge>
        </div>

        <Card class="border-none shadow-sm bg-white rounded-3xl overflow-hidden">
          <CardHeader class="p-6 pb-2">
            <CardTitle class="text-sm font-bold text-slate-500 uppercase tracking-wider">Antrean Backorder (FIFO)</CardTitle>
            <CardDescription class="text-xs">Produk yang habis stok & ditunggu pelanggan.</CardDescription>
          </CardHeader>
          <CardContent class="p-0">
            <div v-if="factoryStore.backorderDemand.length === 0" class="p-8 text-center">
              <CheckCircle2 class="h-10 w-10 text-emerald-400 mx-auto mb-3" />
              <p class="text-sm font-medium text-slate-900">Semua Terpenuhi</p>
              <p class="text-xs text-slate-500 mt-1">Tidak ada antrean pesanan menggantung.</p>
            </div>
            <div v-else class="divide-y divide-slate-50">
              <div v-for="item in factoryStore.backorderDemand" :key="item.product_id" class="p-5 hover:bg-slate-50/50 transition-colors group">
                <div class="flex items-center gap-4">
                  <div class="w-12 h-12 rounded-2xl bg-red-50 flex flex-col items-center justify-center text-red-600 group-hover:bg-red-600 group-hover:text-white transition-all duration-300">
                    <span class="text-lg font-black leading-none">{{ item.total_qty }}</span>
                    <span class="text-[8px] font-bold uppercase mt-1">PCS</span>
                  </div>
                  <div class="flex-1 min-w-0">
                    <div class="flex justify-between items-start">
                      <p class="text-sm font-extrabold text-slate-900 truncate">{{ item.product_name }}</p>
                    </div>
                    <div class="mt-2 flex items-center gap-2">
                      <Badge variant="secondary" class="text-[9px] font-bold bg-slate-100 text-slate-600 border-none">
                        {{ item.order_count }} Invoice
                      </Badge>
                      <div class="h-1 flex-1 bg-slate-100 rounded-full overflow-hidden mt-0.5">
                        <div class="h-full bg-red-500 w-full animate-pulse"></div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        <h2 class="text-xl font-bold text-slate-900">Pengiriman Terbaru</h2>
        
        <Card class="border-none shadow-sm bg-white rounded-3xl overflow-hidden">
          <CardContent class="p-0">
            <div class="divide-y divide-slate-50">
              <div v-for="i in 5" :key="i" class="p-5 hover:bg-slate-50/50 transition-colors">
                <div class="flex items-center gap-4">
                  <div class="w-10 h-10 rounded-xl bg-orange-50 flex items-center justify-center text-orange-600">
                    <Truck class="h-5 w-5" />
                  </div>
                  <div class="flex-1 min-w-0">
                    <div class="flex justify-between items-start">
                      <p class="text-sm font-bold text-slate-900 truncate">SJ-2024-00{{i}}</p>
                      <span class="text-[10px] text-slate-400">2j yang lalu</span>
                    </div>
                    <p class="text-xs text-slate-500 mt-0.5">Pabrik A &rarr; Cabang Surabaya</p>
                    <div class="mt-2 flex items-center justify-between">
                      <span class="text-[10px] font-bold px-2 py-0.5 rounded-full bg-blue-50 text-blue-600 uppercase">Dalam Perjalanan</span>
                      <span class="text-[10px] font-medium text-slate-400">120 KG</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
            <div class="p-4 bg-slate-50 text-center">
              <Button variant="link" class="text-xs text-slate-500 font-bold uppercase tracking-wider">Lihat Semua Logistik</Button>
            </div>
          </CardContent>
        </Card>

        <!-- Quick Help Card -->
        <Card class="bg-primary border-none text-white rounded-3xl p-6 relative overflow-hidden">
          <div class="relative z-10">
            <h3 class="text-lg font-bold">Butuh Bantuan?</h3>
            <p class="text-primary-foreground/80 text-xs mt-2 leading-relaxed">
              Pelajari cara mengelola stok produksi dan pengiriman barang ke cabang dengan dokumentasi kami.
            </p>
            <Button variant="secondary" size="sm" class="mt-4 rounded-xl font-bold bg-white text-primary hover:bg-slate-100">
              Buka Panduan
            </Button>
          </div>
          <HelpCircle class="absolute -right-4 -bottom-4 w-24 h-24 text-white/10 rotate-12" />
        </Card>
      </div>
    </div>

    <!-- Add Factory Modal -->
    <div v-if="showAddFactory" class="fixed inset-0 bg-slate-900/40 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <Card class="w-full max-w-lg shadow-2xl animate-in zoom-in-95 duration-200 rounded-3xl overflow-hidden border-none">
        <CardHeader class="bg-white border-b p-6">
          <div class="flex justify-between items-center">
            <div>
              <CardTitle class="text-xl font-bold">Tambah Pabrik Baru</CardTitle>
              <CardDescription>Daftarkan lokasi operasional pabrik Wowin.</CardDescription>
            </div>
            <Button variant="ghost" size="icon" @click="showAddFactory = false" class="rounded-full">
              <Plus class="h-5 w-5 rotate-45" />
            </Button>
          </div>
        </CardHeader>
        <CardContent class="p-6 space-y-6 bg-white">
          <div class="space-y-2">
            <label class="text-sm font-bold text-slate-700">Nama Pabrik</label>
            <div class="relative">
              <Factory class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
              <input 
                v-model="newFactoryForm.name" 
                type="text" 
                placeholder="e.g. Pabrik Utama Wowin" 
                class="w-full pl-10 pr-4 py-3 bg-slate-50 border border-slate-100 rounded-2xl text-sm focus:ring-2 focus:ring-primary/20 transition-all outline-none" 
              />
            </div>
          </div>

          <div class="space-y-2">
            <label class="text-sm font-bold text-slate-700">Lokasi / Alamat</label>
            <div class="relative">
              <MapPin class="absolute left-3 top-3 h-4 w-4 text-slate-400" />
              <textarea 
                v-model="newFactoryForm.location" 
                rows="3" 
                placeholder="Alamat lengkap operasional..." 
                class="w-full pl-10 pr-4 py-3 bg-slate-50 border border-slate-100 rounded-2xl text-sm focus:ring-2 focus:ring-primary/20 outline-none resize-none"
              ></textarea>
            </div>
          </div>

          <div class="space-y-2">
            <label class="text-sm font-bold text-slate-700">Cabang Terkait</label>
            <div class="relative">
              <select 
                v-model="newFactoryForm.branch_id" 
                class="w-full px-4 py-3 bg-slate-50 border border-slate-100 rounded-2xl text-sm focus:ring-2 focus:ring-primary/20 outline-none appearance-none"
              >
                <option value="">Pilih Cabang (Opsional)</option>
                <option v-for="branch in masterDataStore.branches" :key="branch.id" :value="branch.id">
                  {{ branch.name }}
                </option>
              </select>
              <ChevronRight class="absolute right-4 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400 rotate-90" />
            </div>
            <p class="text-[10px] text-slate-400">Pabrik biasanya mensuplai stok ke satu cabang utama.</p>
          </div>
        </CardContent>
        <CardFooter class="bg-slate-50/50 p-6 flex justify-end gap-3">
          <Button variant="ghost" @click="showAddFactory = false" class="rounded-xl font-bold">Batal</Button>
          <Button @click="handleAddFactory" :loading="submitting" class="rounded-xl px-8 shadow-lg shadow-primary/20 font-bold">
            Simpan Pabrik
          </Button>
        </CardFooter>
      </Card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { useFactoryStore } from '@/stores/factory'
import { useMasterDataStore } from '@/stores/masterData'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { 
  Plus, 
  Factory, 
  Package, 
  Truck, 
  Activity, 
  AlertCircle, 
  TrendingUp, 
  Download, 
  MapPin, 
  ChevronRight,
  HelpCircle,
  CheckCircle2
} from 'lucide-vue-next'

const router = useRouter()
const factoryStore = useFactoryStore()
const masterDataStore = useMasterDataStore()

const showAddFactory = ref(false)
const submitting = ref(false)

const newFactoryForm = reactive({
  name: '',
  location: '',
  branch_id: ''
})

onMounted(() => {
  factoryStore.fetchFactories()
  factoryStore.fetchProducts()
  factoryStore.fetchBackorderDemand(masterDataStore.selectedBranchCompanyId || '')
  masterDataStore.fetchBranches()
})


const goToFactory = (id: string) => {
  router.push({ name: 'factoryInventory', params: { id } })
}

const handleAddFactory = async () => {
  if (!newFactoryForm.name) return
  submitting.value = true
  try {
    await factoryStore.createFactory(newFactoryForm)
    showAddFactory.value = false
    // Reset form
    newFactoryForm.name = ''
    newFactoryForm.location = ''
    newFactoryForm.branch_id = ''
  } catch (err) {
    alert(err)
  } finally {
    submitting.value = false
  }
}
</script>
