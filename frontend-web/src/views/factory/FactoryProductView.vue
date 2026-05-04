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

    <Card class="border-slate-200/60 shadow-sm overflow-hidden">
      <CardHeader class="bg-slate-50/50 border-b pb-4">
        <div class="flex items-center justify-between">
          <CardTitle>Daftar Produk</CardTitle>
          <div class="relative w-72">
            <Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
            <input 
              v-model="searchQuery"
              type="text" 
              placeholder="Cari nama atau SKU..." 
              class="w-full pl-10 pr-4 py-2 bg-white border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all"
            />
          </div>
        </div>
      </CardHeader>
      <CardContent class="p-0">
        <DataTable :columns="columns" :data="filteredProducts">
          <template #actions="{ item }">
            <div class="flex items-center gap-2">
              <Button variant="ghost" size="icon" @click="openEditModal(item)" class="h-8 w-8 text-slate-500 hover:text-primary hover:bg-primary/5 rounded-lg">
                <Edit2 class="h-4 w-4" />
              </Button>
              <Button variant="ghost" size="icon" @click="handleDelete(item.id)" class="h-8 w-8 text-slate-500 hover:text-destructive hover:bg-destructive/5 rounded-lg">
                <Trash2 class="h-4 w-4" />
              </Button>
            </div>
          </template>
        </DataTable>
      </CardContent>
    </Card>

    <!-- Product Modal -->
    <div v-if="showModal" class="fixed inset-0 bg-slate-900/40 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <Card class="w-full max-w-lg shadow-2xl animate-in zoom-in-95 duration-200">
        <CardHeader class="border-b">
          <CardTitle>{{ isEditing ? 'Edit Produk' : 'Tambah Produk Baru' }}</CardTitle>
          <CardDescription>Lengkapi informasi produk di bawah ini.</CardDescription>
        </CardHeader>
        <CardContent class="p-6 space-y-4">
          <div class="grid grid-cols-2 gap-4">
            <div class="space-y-2">
              <label class="text-sm font-bold text-slate-700">Kode SKU</label>
              <input v-model="form.sku" type="text" placeholder="e.g. WOW-001" class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:ring-2 focus:ring-primary/20 transition-all outline-none" />
            </div>
            <div class="space-y-2">
              <label class="text-sm font-bold text-slate-700">Satuan</label>
              <select v-model="form.unit" class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:ring-2 focus:ring-primary/20 outline-none">
                <option value="PCS">PCS</option>
                <option value="BOX">BOX</option>
                <option value="KG">KG</option>
                <option value="BAL">BAL</option>
              </select>
            </div>
          </div>
          
          <div class="space-y-2">
            <label class="text-sm font-bold text-slate-700">Nama Produk</label>
            <input v-model="form.name" type="text" placeholder="Nama lengkap produk..." class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:ring-2 focus:ring-primary/20 outline-none" />
          </div>

          <div class="space-y-2">
            <label class="text-sm font-bold text-slate-700">Berat Satuan (KG)</label>
            <div class="relative">
              <input v-model="form.weight" type="number" step="0.01" class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:ring-2 focus:ring-primary/20 outline-none" />
              <span class="absolute right-4 top-1/2 -translate-y-1/2 text-xs font-bold text-slate-400">KG</span>
            </div>
            <p class="text-[10px] text-slate-400">Penting untuk perhitungan tonase logistik.</p>
          </div>

          <div class="space-y-2">
            <label class="text-sm font-bold text-slate-700">Deskripsi</label>
            <textarea v-model="form.description" rows="3" placeholder="Keterangan produk..." class="w-full px-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:ring-2 focus:ring-primary/20 outline-none resize-none"></textarea>
          </div>
        </CardContent>
        <CardFooter class="bg-slate-50/50 border-t p-6 flex justify-end gap-3">
          <Button variant="ghost" @click="showModal = false" class="rounded-xl">Batal</Button>
          <Button @click="handleSubmit" :loading="loading" class="rounded-xl px-8 shadow-lg shadow-primary/20">
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
import { Plus, Search, Edit2, Trash2, Package } from 'lucide-vue-next'

const factoryStore = useFactoryStore()
const showModal = ref(false)
const isEditing = ref(false)
const loading = ref(false)
const searchQuery = ref('')
const currentId = ref('')

const form = reactive({
  sku: '',
  name: '',
  unit: 'PCS',
  weight: 0,
  description: ''
})

const columns = [
  { key: 'sku', label: 'SKU', class: 'font-mono text-xs font-bold text-primary bg-primary/5 px-2 py-1 rounded w-fit' },
  { key: 'name', label: 'Nama Produk', class: 'font-bold' },
  { key: 'unit', label: 'Satuan' },
  { 
    key: 'weight', 
    label: 'Berat',
    render: (val: number) => `${val} KG`
  },
  { key: 'actions', label: '', class: 'w-20' }
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
  Object.assign(form, {
    sku: '',
    name: '',
    unit: 'PCS',
    weight: 0,
    description: ''
  })
  showModal.value = true
}

const openEditModal = (item: any) => {
  isEditing.value = true
  currentId.value = item.id
  Object.assign(form, {
    sku: item.sku,
    name: item.name,
    unit: item.unit,
    weight: item.weight,
    description: item.description
  })
  showModal.value = true
}

const handleSubmit = async () => {
  loading.value = true
  try {
    if (isEditing.value) {
      await factoryStore.updateProduct(currentId.value, form)
    } else {
      await factoryStore.createProduct(form)
    }
    showModal.value = false
  } catch (err) {
    alert(err)
  } finally {
    loading.value = false
  }
}

const handleDelete = async (id: string) => {
  if (!confirm('Hapus produk ini? Pastikan tidak ada stok atau transaksi aktif menggunakan produk ini.')) return
  try {
    await factoryStore.deleteProduct(id)
  } catch (err) {
    alert(err)
  }
}
</script>
