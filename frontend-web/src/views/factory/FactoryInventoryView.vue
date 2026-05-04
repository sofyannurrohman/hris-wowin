<template>
  <div class="p-6 space-y-6">
    <div class="flex items-center gap-4">
      <Button variant="ghost" size="icon" @click="router.back()">
        <ArrowLeft class="h-4 w-4" />
      </Button>
      <div>
        <h1 class="text-2xl font-bold tracking-tight">{{ factoryStore.currentFactory?.name || 'Loading...' }}</h1>
        <p class="text-muted-foreground">{{ factoryStore.currentFactory?.location }}</p>
      </div>
    </div>

    <Tabs default-value="stock" class="w-full">
      <TabsList class="grid w-full grid-cols-3 lg:w-[400px]">
        <TabsTrigger value="stock">Current Stock</TabsTrigger>
        <TabsTrigger value="production">Production Log</TabsTrigger>
        <TabsTrigger value="transfers">Transfers</TabsTrigger>
      </TabsList>

      <TabsContent value="stock" class="space-y-4 pt-4">
        <div class="flex justify-between items-center">
          <h2 class="text-xl font-semibold">Inventory Levels</h2>
          <Button size="sm" @click="showLogProduction = true">Log Production</Button>
        </div>

        <DataTable :columns="stockColumns" :data="factoryStore.inventory" />
      </TabsContent>

      <TabsContent value="production" class="space-y-4 pt-4">
        <h2 class="text-xl font-semibold">Production History</h2>
        <DataTable :columns="productionColumns" :data="factoryStore.productionHistory" />
      </TabsContent>

      <TabsContent value="transfers" class="space-y-4 pt-4">
        <div class="flex justify-between items-center">
          <h2 class="text-xl font-semibold">Stock Transfers to Branches</h2>
          <Button size="sm" @click="showSendToBranch = true">Send to Branch</Button>
        </div>
        <DataTable :columns="transferColumns" :data="factoryStore.transferHistory" />
      </TabsContent>
    </Tabs>

    <!-- Modals (Simple implementation for now) -->
    <div v-if="showLogProduction" class="fixed inset-0 bg-background/80 backdrop-blur-sm z-50 flex items-center justify-center p-4">
       <Card class="w-full max-w-md">
         <CardHeader>
           <CardTitle>Log Production</CardTitle>
           <CardDescription>Input daily output into factory stock.</CardDescription>
         </CardHeader>
         <CardContent class="space-y-4">
           <div class="space-y-2">
             <label class="text-sm font-medium">Product</label>
             <select v-model="productionForm.product_id" class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm">
               <option v-for="p in factoryStore.products" :key="p.id" :value="p.id">{{ p.name }} ({{ p.sku }})</option>
             </select>
           </div>
           <div class="space-y-2">
             <label class="text-sm font-medium">Quantity</label>
             <input type="number" v-model="productionForm.quantity" class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm" />
           </div>
           <div class="space-y-2">
             <label class="text-sm font-medium">Operator (Employee ID)</label>
             <input type="text" v-model="productionForm.employee_id" placeholder="UUID" class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm" />
           </div>
         </CardContent>
         <CardFooter class="flex justify-end gap-2">
           <Button variant="outline" @click="showLogProduction = false">Cancel</Button>
           <Button @click="handleProductionSubmit">Save Log</Button>
         </CardFooter>
       </Card>
    </div>

    <!-- Send to Branch Modal -->
    <div v-if="showSendToBranch" class="fixed inset-0 bg-background/80 backdrop-blur-sm z-50 flex items-center justify-center p-4">
       <Card class="w-full max-w-md">
         <CardHeader>
           <CardTitle>Send to Branch</CardTitle>
           <CardDescription>Transfer stock from factory to a branch warehouse.</CardDescription>
         </CardHeader>
         <CardContent class="space-y-4">
           <div class="space-y-2">
             <label class="text-sm font-medium">Target Branch</label>
             <input type="text" v-model="transferForm.to_branch_id" placeholder="Branch UUID" class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm" />
           </div>
           <div class="space-y-2">
             <label class="text-sm font-medium">Product</label>
             <select v-model="transferForm.product_id" class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm">
               <option v-for="p in factoryStore.products" :key="p.id" :value="p.id">{{ p.name }} ({{ p.sku }})</option>
             </select>
           </div>
           <div class="space-y-2">
             <label class="text-sm font-medium">Quantity</label>
             <input type="number" v-model="transferForm.quantity" class="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm" />
           </div>
         </CardContent>
         <CardFooter class="flex justify-end gap-2">
           <Button variant="outline" @click="showSendToBranch = false">Cancel</Button>
           <Button @click="handleTransferSubmit">Ship Now</Button>
         </CardFooter>
       </Card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref, reactive } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useFactoryStore } from '@/stores/factory'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs/index'
import DataTable from '@/components/DataTable.vue'
import { ArrowLeft } from 'lucide-vue-next'

const route = useRoute()
const router = useRouter()
const factoryStore = useFactoryStore()
const factoryId = route.params.id as string

const showLogProduction = ref(false)
const showSendToBranch = ref(false)

const productionForm = reactive({
  product_id: '',
  quantity: 0,
  employee_id: '',
  notes: ''
})

const transferForm = reactive({
  to_branch_id: '',
  product_id: '',
  quantity: 0,
  notes: ''
})

onMounted(async () => {
  await factoryStore.fetchFactoryDetail(factoryId)
  factoryStore.fetchProducts()
  factoryStore.fetchInventory(factoryId)
  factoryStore.fetchProductionHistory(factoryId)
  factoryStore.fetchTransferHistory(factoryId)
})

const handleProductionSubmit = async () => {
  try {
    await factoryStore.logProduction(factoryId, productionForm)
    showLogProduction.value = false
    // Reset form
    productionForm.product_id = ''
    productionForm.quantity = 0
  } catch (err) {
    alert(err)
  }
}

const handleTransferSubmit = async () => {
  try {
    await factoryStore.sendToBranch(factoryId, transferForm)
    showSendToBranch.value = false
    transferForm.product_id = ''
    transferForm.quantity = 0
  } catch (err) {
    alert(err)
  }
}

const stockColumns = [
  { key: 'product.name', label: 'Product' },
  { key: 'product.sku', label: 'SKU' },
  { key: 'quantity', label: 'In-Stock Quantity' },
  { key: 'updated_at', label: 'Last Updated', type: 'datetime' }
]

const productionColumns = [
  { key: 'production_date', label: 'Date', type: 'datetime' },
  { key: 'product.name', label: 'Product' },
  { key: 'quantity', label: 'Produced' },
  { key: 'employee.first_name', label: 'Operator' }
]

const transferColumns = [
  { key: 'created_at', label: 'Date', type: 'datetime' },
  { key: 'product.name', label: 'Product' },
  { key: 'quantity', label: 'Qty' },
  { key: 'to_branch.name', label: 'Target Branch' },
  { key: 'status', label: 'Status' }
]
</script>
