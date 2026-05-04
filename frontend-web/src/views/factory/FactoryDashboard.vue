<template>
  <div class="p-6 space-y-6">
    <div class="flex justify-between items-center">
      <h1 class="text-3xl font-bold tracking-tight">Factory Management</h1>
      <div class="flex gap-2">
        <Button @click="showAddFactory = true">Add Factory</Button>
      </div>
    </div>

    <div v-if="factoryStore.loading" class="flex justify-center py-12">
      <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary"></div>
    </div>

    <div v-else-if="factoryStore.factories.length === 0" class="text-center py-12 bg-muted/20 rounded-lg border border-dashed">
      <p class="text-muted-foreground text-lg">No factories found. Add your first factory to get started.</p>
    </div>

    <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <Card v-for="factory in factoryStore.factories" :key="factory.id" class="hover:shadow-md transition-shadow">
        <CardHeader>
          <CardTitle>{{ factory.name }}</CardTitle>
          <CardDescription>{{ factory.branch?.name || 'No Branch Linked' }}</CardDescription>
        </CardHeader>
        <CardContent>
          <p class="text-sm text-muted-foreground truncate">{{ factory.location }}</p>
        </CardContent>
        <CardFooter class="flex justify-end gap-2">
          <Button variant="outline" size="sm" @click="goToFactory(factory.id)">Manage</Button>
        </CardFooter>
      </Card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useFactoryStore } from '@/stores/factory'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card'

const router = useRouter()
const factoryStore = useFactoryStore()
const showAddFactory = ref(false)

onMounted(() => {
  factoryStore.fetchFactories()
})

const goToFactory = (id: string) => {
  router.push({ name: 'factoryInventory', params: { id } })
}
</script>
