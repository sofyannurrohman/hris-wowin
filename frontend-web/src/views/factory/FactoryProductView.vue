<template>
  <div class="p-6 space-y-6">
    <div class="flex justify-between items-center">
      <div>
        <h1 class="text-3xl font-bold tracking-tight">Manajemen Produk Wowin</h1>
        <p class="text-muted-foreground">Kelola master data produk yang diproduksi oleh pabrik.</p>
      </div>
      <Button @click="openCreateModal" class="rounded-xl shadow-lg shadow-primary/20 transition-all hover:scale-105">
        <Plus class="mr-2 h-4 w-4" /> Tambah Produk Baru
      </Button>
    </div>

    <Card class="border-none shadow-sm bg-white rounded-3xl overflow-hidden">
      <CardHeader class="p-8 border-b bg-slate-50/30">
        <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div>
            <CardTitle class="text-xl font-bold text-slate-900">Daftar Produk Wowin</CardTitle>
            <CardDescription>Master data barang hasil produksi yang siap didistribusikan.</CardDescription>
          </div>
          <div class="relative w-full md:w-80">
            <Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
            <input 
              v-model="searchQuery"
              type="text" 
              placeholder="Cari SKU, Nama, atau Kategori..." 
              class="w-full pl-10 pr-4 py-2.5 bg-white border border-slate-200 rounded-2xl text-sm focus:ring-2 focus:ring-primary/10 outline-none transition-all"
            />
          </div>
        </div>
      </CardHeader>
      <CardContent class="p-0">
        <DataTable :columns="columns" :data="filteredProducts" class="border-none">
          <template #cell-sku="{ row }">
            <span class="font-mono text-[11px] font-bold text-primary bg-primary/5 px-2 py-1 rounded-lg ring-1 ring-primary/10">
              {{ (row as any).sku }}
            </span>
          </template>
          <template #cell-image="{ row }">
            <div class="h-12 w-12 rounded-xl bg-slate-100 overflow-hidden flex items-center justify-center border border-slate-100 shadow-sm group">
              <img v-if="(row as any).image_url" :src="`${apiBaseUrl}${(row as any).image_url}`" class="h-full w-full object-cover transition-transform group-hover:scale-110" />
              <Package v-else class="h-6 w-6 text-slate-300" />
            </div>
          </template>
          <template #cell-product_info="{ row }">
            <div class="flex flex-col">
              <span class="font-bold text-slate-900">{{ (row as any).name }}</span>
              <div class="flex items-center gap-2 mt-0.5">
                <Badge variant="secondary" class="bg-slate-100 text-slate-500 text-[9px] px-1.5 py-0 font-bold uppercase">{{ (row as any).category || 'No Category' }}</Badge>
                <span class="text-[10px] text-slate-400 font-medium">{{ (row as any).brand || 'Tanpa Brand' }}</span>
              </div>
            </div>
          </template>
          <template #cell-weight="{ row }">
            <div class="flex items-center gap-1.5">
              <span class="font-black text-slate-700">{{ (row as any).weight }}</span>
              <span class="text-[9px] font-bold text-slate-400 uppercase">{{ (row as any).weight_unit || 'KG' }} / {{ (row as any).unit }}</span>
            </div>
          </template>
          <template #cell-pricing="{ row }">
            <div class="flex flex-col">
              <div class="flex items-center justify-between gap-4">
                <span class="text-[10px] font-bold text-slate-400 uppercase">HPP:</span>
                <span class="font-mono text-xs font-bold text-slate-600">Rp{{ (row as any).cost_price?.toLocaleString() }}</span>
              </div>
              <div class="flex items-center justify-between gap-4 mt-0.5">
                <span class="text-[10px] font-bold text-emerald-500 uppercase">Jual:</span>
                <span class="font-mono text-xs font-black text-emerald-600">Rp{{ (row as any).selling_price?.toLocaleString() }}</span>
              </div>
            </div>
          </template>
          <template #cell-actions="{ row }">
            <div class="flex items-center gap-1">
              <Button variant="ghost" size="icon" @click="openEditModal(row)" class="h-8 w-8 text-slate-400 hover:text-primary hover:bg-primary/5">
                <Edit2 class="h-3.5 w-3.5" />
              </Button>
              <Button variant="ghost" size="icon" @click="handleDelete((row as any).id)" class="h-8 w-8 text-slate-400 hover:text-destructive hover:bg-destructive/5">
                <Trash2 class="h-3.5 w-3.5" />
              </Button>
            </div>
          </template>
        </DataTable>
      </CardContent>
    </Card>

    <!-- Product Modal (Fully Responsive) -->
    <div v-if="showModal" class="fixed inset-0 bg-slate-900/60 backdrop-blur-md z-[100] flex items-center justify-center p-4 md:p-6">
      <Card class="w-full max-h-[90vh] md:max-h-[85vh] md:max-w-2xl shadow-2xl rounded-[2rem] md:rounded-[2.5rem] overflow-hidden border-none animate-in fade-in zoom-in-95 duration-300 flex flex-col">
        <!-- Fixed Header -->
        <CardHeader class="p-6 md:p-8 border-b bg-white shrink-0">
          <div class="flex justify-between items-center">
            <div>
              <CardTitle class="text-2xl font-black text-slate-900">{{ isEditing ? 'Edit Produk Wowin' : 'Tambah Produk Baru' }}</CardTitle>
              <CardDescription class="text-slate-500">Pastikan informasi teknis dan harga sudah benar.</CardDescription>
            </div>
            <Button variant="ghost" size="icon" @click="showModal = false" class="rounded-full hover:bg-slate-100">
              <Plus class="h-6 w-6 rotate-45 text-slate-400" />
            </Button>
          </div>
        </CardHeader>

        <!-- Scrollable Content -->
        <CardContent class="p-6 md:p-8 space-y-8 bg-white overflow-y-auto flex-1 custom-scrollbar">
          <!-- Section 1: Identitas Dasar -->
          <div class="space-y-6">
            <p class="text-[11px] font-black text-primary uppercase tracking-[0.2em] flex items-center gap-2">
              <span class="w-2 h-2 rounded-full bg-primary animate-pulse"></span> Identitas Produk
            </p>
            
            <!-- Image Upload -->
            <div class="flex flex-col md:flex-row gap-8 items-start">
              <div class="relative group h-40 w-40 shrink-0">
                <div class="h-40 w-40 rounded-[2rem] bg-slate-50 border-2 border-dashed border-slate-200 flex flex-col items-center justify-center overflow-hidden transition-all group-hover:border-primary/50 group-hover:bg-primary/5">
                  <img v-if="imagePreview || form.image_url" :src="imagePreview || `${apiBaseUrl}${form.image_url}`" class="h-full w-full object-cover" />
                  <div v-else class="flex flex-col items-center gap-2 text-slate-400">
                    <Plus class="h-8 w-8" />
                    <span class="text-[10px] font-bold uppercase tracking-wider">Upload Foto</span>
                  </div>
                </div>
                <input type="file" @change="handleFileChange" accept="image/*" class="absolute inset-0 opacity-0 cursor-pointer" />
                <div class="absolute -bottom-2 -right-2 h-8 w-8 rounded-xl bg-primary text-white flex items-center justify-center shadow-lg pointer-events-none">
                  <Edit2 class="h-4 w-4" />
                </div>
              </div>

              <div class="flex-1 w-full space-y-6">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div class="space-y-2">
                    <label class="text-sm font-bold text-slate-700 ml-1">Kode SKU</label>
                    <input v-model="form.sku" type="text" placeholder="e.g. WOW-2024-001" class="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-medium focus:ring-4 focus:ring-primary/5 focus:border-primary/20 outline-none transition-all" />
                  </div>
                  <div class="space-y-2">
                    <label class="text-sm font-bold text-slate-700 ml-1">Nama Lengkap Produk</label>
                    <input v-model="form.name" type="text" placeholder="Nama produk..." class="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-medium focus:ring-4 focus:ring-primary/5 focus:border-primary/20 outline-none transition-all" />
                  </div>
                </div>
              </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div class="space-y-2">
                <label class="text-sm font-bold text-slate-700 ml-1">Kategori</label>
                <input v-model="form.category" type="text" placeholder="e.g. Kerupuk, Sambal" class="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-medium outline-none" />
              </div>
              <div class="space-y-2">
                <label class="text-sm font-bold text-slate-700 ml-1">Brand / Merk</label>
                <input v-model="form.brand" type="text" placeholder="e.g. Wowin Gold" class="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-medium outline-none" />
              </div>
            </div>
          </div>

          <!-- Section 2: Fisik & Stok -->
          <div class="space-y-6 pt-4 border-t border-slate-50">
            <p class="text-[11px] font-black text-blue-600 uppercase tracking-[0.2em] flex items-center gap-2">
              <span class="w-2 h-2 rounded-full bg-blue-500"></span> Fisik & Pengemasan
            </p>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div class="space-y-2">
                <label class="text-sm font-bold text-slate-700 ml-1 text-blue-700">Satuan Stok</label>
                <div class="flex gap-2">
                  <select v-if="!customStockUnit" v-model="form.unit" class="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold outline-none appearance-none cursor-pointer">
                    <option value="PCS">PCS (Pieces)</option>
                    <option value="BOX">BOX (Kardus)</option>
                    <option value="BAL">BAL (Ball)</option>
                    <option value="KG">KG (Kilogram)</option>
                    <option value="LITER">LITER</option>
                    <option value="SACHET">SACHET</option>
                    <option value="JERIGEN">JERIGEN</option>
                    <option value="PAIL">PAIL</option>
                    <option value="DRUM">DRUM</option>
                    <option value="BOTOL">BOTOL</option>
                    <option value="DUS">DUS</option>
                  </select>
                  <input v-else v-model="form.unit" type="text" placeholder="Ketik satuan..." class="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-medium outline-none" />
                  <Button variant="ghost" size="icon" @click="customStockUnit = !customStockUnit" class="h-12 w-12 shrink-0 rounded-2xl border border-slate-50 bg-slate-50 hover:bg-white hover:shadow-sm">
                    <Plus v-if="!customStockUnit" class="h-4 w-4" />
                    <List v-else class="h-4 w-4 text-primary" />
                  </Button>
                </div>
              </div>
              <div class="space-y-2">
                <label class="text-sm font-bold text-slate-700 ml-1 text-blue-700">Berat / Volume per Satuan</label>
                <div class="flex gap-2">
                  <input v-model="form.weight" type="number" step="0.01" class="flex-1 px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold outline-none" />
                  <div class="flex gap-2 w-44">
                    <select v-if="!customWeightUnit" v-model="form.weight_unit" class="flex-1 px-3 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-xs font-black outline-none appearance-none">
                      <option value="GR">GR</option>
                      <option value="KG">KG</option>
                      <option value="ML">ML</option>
                      <option value="L">L</option>
                      <option value="TON">TON</option>
                    </select>
                    <input v-else v-model="form.weight_unit" type="text" placeholder="Unit" class="flex-1 px-3 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-xs font-black outline-none" />
                    <Button variant="ghost" size="icon" @click="customWeightUnit = !customWeightUnit" class="h-12 w-12 shrink-0 rounded-2xl border border-slate-50 bg-slate-50 hover:bg-white hover:shadow-sm">
                      <Plus v-if="!customWeightUnit" class="h-3 w-3" />
                      <List v-else class="h-3 w-3 text-primary" />
                    </Button>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Section 3: Finansial -->
          <div class="p-8 bg-emerald-50/40 rounded-[2rem] border border-emerald-100/50 space-y-6">
            <p class="text-[11px] font-black text-emerald-600 uppercase tracking-[0.2em] flex items-center gap-2">
              <span class="w-2 h-2 rounded-full bg-emerald-500"></span> Informasi Finansial
            </p>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
              <div class="space-y-2">
                <label class="text-sm font-bold text-slate-700 ml-1">Harga Pokok (HPP)</label>
                <div class="relative group">
                  <span class="absolute left-5 top-1/2 -translate-y-1/2 text-xs font-bold text-emerald-600/50 group-focus-within:text-emerald-600 transition-colors">Rp</span>
                  <input v-model="form.cost_price" type="number" class="w-full pl-12 pr-5 py-4 bg-white border border-emerald-100 rounded-2xl text-base font-black text-slate-800 outline-none focus:ring-4 focus:ring-emerald-500/10 focus:border-emerald-500/20" placeholder="0" />
                </div>
              </div>
              <div class="space-y-2">
                <label class="text-sm font-bold text-slate-700 ml-1">Harga Jual</label>
                <div class="relative group">
                  <span class="absolute left-5 top-1/2 -translate-y-1/2 text-xs font-bold text-emerald-600/50 group-focus-within:text-emerald-600 transition-colors">Rp</span>
                  <input v-model="form.selling_price" type="number" class="w-full pl-12 pr-5 py-4 bg-white border border-emerald-100 rounded-2xl text-base font-black text-emerald-700 outline-none focus:ring-4 focus:ring-emerald-500/10 focus:border-emerald-500/20" placeholder="0" />
                </div>
              </div>
            </div>
          </div>

          <!-- Section 4: Detail Tambahan -->
          <div class="space-y-6">
            <div class="space-y-2">
              <label class="text-sm font-bold text-slate-700 ml-1">Spesifikasi Teknis</label>
              <textarea v-model="form.specs" rows="2" placeholder="Detail dimensi, komposisi..." class="w-full px-5 py-4 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-medium outline-none focus:ring-4 focus:ring-slate-100 resize-none"></textarea>
            </div>
            <div class="space-y-2">
              <label class="text-sm font-bold text-slate-700 ml-1">Deskripsi Tambahan</label>
              <textarea v-model="form.description" rows="2" placeholder="Keterangan lainnya..." class="w-full px-5 py-4 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-medium outline-none focus:ring-4 focus:ring-slate-100 resize-none"></textarea>
            </div>
          </div>
        </CardContent>

        <!-- Fixed Footer -->
        <CardFooter class="bg-slate-50/50 border-t p-6 md:p-8 flex flex-col md:flex-row justify-end gap-4 shrink-0">
          <Button variant="ghost" @click="showModal = false" class="rounded-2xl font-bold h-12 w-full md:w-auto">Batal</Button>
          <Button @click="handleSubmit" :loading="loading" class="rounded-2xl px-12 h-12 w-full md:w-auto shadow-xl shadow-primary/20 font-black text-white bg-primary hover:bg-primary/90">
            {{ isEditing ? 'Simpan Perubahan' : 'Simpan Produk' }}
          </Button>
        </CardFooter>
      </Card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { useFactoryStore } from '@/stores/factory'
import { Button } from '@/components/ui/button'
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from '@/components/ui/card/index'
import DataTable from '@/components/DataTable.vue'
import { Plus, Search, Edit2, Trash2, Package, List } from 'lucide-vue-next'
import { toast } from 'vue-sonner'

const factoryStore = useFactoryStore()
const showModal = ref(false)
const isEditing = ref(false)
const loading = ref(false)
const searchQuery = ref('')
const currentId = ref('')

const customStockUnit = ref(false)
const customWeightUnit = ref(false)
const imageFile = ref<File | null>(null)
const imagePreview = ref<string>('')
const apiBaseUrl = import.meta.env.VITE_API_BASE_URL

const form = reactive({
  sku: '',
  name: '',
  unit: 'PCS',
  weight: 0,
  weight_unit: 'KG',
  cost_price: 0,
  selling_price: 0,
  category: '',
  brand: '',
  specs: '',
  description: '',
  image_url: ''
})

const handleFileChange = (e: any) => {
  const file = e.target.files[0]
  if (file) {
    imageFile.value = file
    imagePreview.value = URL.createObjectURL(file)
  }
}

const columns = [
  { key: 'image', label: '' },
  { key: 'sku', label: 'SKU' },
  { key: 'product_info', label: 'Produk & Kategori' },
  { key: 'weight', label: 'Spesifikasi Berat' },
  { key: 'pricing', label: 'Informasi Harga' },
  { key: 'actions', label: '' }
]

const filteredProducts = computed(() => {
  if (!searchQuery.value) return factoryStore.products
  const q = searchQuery.value.toLowerCase()
  return factoryStore.products.filter(p => 
    p.name.toLowerCase().includes(q) || 
    p.sku.toLowerCase().includes(q)
  )
})

onMounted(() => {
  factoryStore.fetchProducts()
})

const openCreateModal = () => {
  isEditing.value = false
  imageFile.value = null
  imagePreview.value = ''
  Object.assign(form, {
    sku: '',
    name: '',
    unit: 'PCS',
    weight: 0,
    weight_unit: 'KG',
    cost_price: 0,
    selling_price: 0,
    category: '',
    brand: '',
    specs: '',
    description: '',
    image_url: ''
  })
  showModal.value = true
}

const openEditModal = (item: any) => {
  isEditing.value = true
  currentId.value = item.id
  imageFile.value = null
  imagePreview.value = ''
  Object.assign(form, {
    sku: item.sku,
    name: item.name,
    unit: item.unit,
    weight: item.weight,
    weight_unit: item.weight_unit || 'KG',
    cost_price: item.cost_price || 0,
    selling_price: item.selling_price || 0,
    category: item.category || '',
    brand: item.brand || '',
    specs: item.specs || '',
    description: item.description || '',
    image_url: item.image_url || ''
  })
  showModal.value = true
}

const handleSubmit = async () => {
  loading.value = true
  try {
    const formData = new FormData()
    formData.append('sku', form.sku)
    formData.append('name', form.name)
    formData.append('unit', form.unit)
    formData.append('weight', form.weight.toString())
    formData.append('weight_unit', form.weight_unit)
    formData.append('cost_price', form.cost_price.toString())
    formData.append('selling_price', form.selling_price.toString())
    formData.append('category', form.category)
    formData.append('brand', form.brand)
    formData.append('specs', form.specs)
    formData.append('description', form.description)
    
    if (imageFile.value) {
      formData.append('image', imageFile.value)
    }

    if (isEditing.value) {
      await factoryStore.updateProduct(currentId.value, formData)
      toast.success('Produk berhasil diperbarui')
    } else {
      await factoryStore.createProduct(formData)
      toast.success('Produk baru berhasil ditambahkan')
    }
    showModal.value = false
    await factoryStore.fetchProducts()
  } catch (err) {
    toast.error('Gagal menyimpan produk: ' + err)
  } finally {
    loading.value = false
  }
}

const handleDelete = async (id: string) => {
  if (!confirm('Hapus produk ini? Pastikan tidak ada stok atau transaksi aktif menggunakan produk ini.')) return
  try {
    await factoryStore.deleteProduct(id)
    toast.success('Produk berhasil dihapus')
    await factoryStore.fetchProducts()
  } catch (err) {
    toast.error('Gagal menghapus produk: ' + err)
  }
}
</script>
