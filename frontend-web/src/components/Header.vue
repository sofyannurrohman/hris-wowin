<script setup lang="ts">
import { useLayoutStore } from '@/stores/layout'
import { useMasterDataStore } from '@/stores/masterData'
import { Menu, Search, Bell, Briefcase, Users, PieChart, ChevronDown, Factory, Warehouse, Building2 } from 'lucide-vue-next'
import { Button } from '@/components/ui/button'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { computed, onMounted } from 'vue'
import NotificationDropdown from '@/components/NotificationDropdown.vue'

const layoutStore = useLayoutStore()
const masterDataStore = useMasterDataStore()

onMounted(() => {
  masterDataStore.fetchBranches()
})

const modules = [
  { id: 'hris', name: 'HRIS', icon: Users, color: 'text-primary' },
  { id: 'factory', name: 'Pabrik', icon: Factory, color: 'text-slate-600' },
  { id: 'warehouse', name: 'Gudang', icon: Warehouse, color: 'text-slate-600' },
  { id: 'sales', name: 'Sales & Marketing', icon: PieChart, color: 'text-slate-600' },
  { id: 'erecruitment', name: 'eRecruitment', icon: Briefcase, color: 'text-slate-600', url: 'https://hrd-room.wowinapps.cloud/login' }
]

const currentModuleName = computed(() => {
  return modules.find(m => m.id === layoutStore.currentModule)?.name || 'HRIS'
})

const handleModuleClick = (mod: any) => {
  if (mod.url) {
    window.open(mod.url, '_blank')
    return
  }
  layoutStore.setModule(mod.id)
}

const handleModuleChange = (moduleId: string) => {
  const mod = modules.find(m => m.id === moduleId)
  if (mod) handleModuleClick(mod)
}
</script>

<template>
  <header class="sticky top-0 z-30 flex h-18 w-full items-center justify-between border-b border-slate-200/60 bg-white/70 px-4 backdrop-blur-xl lg:px-8">
    <div class="flex items-center gap-6">
      <Button 
        variant="ghost" 
        size="icon" 
        class="h-10 w-10 text-slate-500 hover:bg-slate-100/80 hover:text-primary transition-all duration-300 rounded-xl"
        @click="layoutStore.toggleSidebar"
      >
        <Menu class="h-5.5 w-5.5 transition-transform duration-500" :class="{ 'rotate-180': layoutStore.isSidebarCollapsed }" />
        <span class="sr-only">Toggle Sidebar</span>
      </Button>

      <!-- Module Switcher (Desktop) -->
      <div class="hidden items-center gap-1 rounded-2xl bg-slate-100/50 p-1.5 md:flex border border-slate-200/50">
        <button
          v-for="mod in modules"
          :key="mod.id"
          @click="handleModuleClick(mod)"
          class="group flex items-center gap-2.5 rounded-xl px-5 py-2 text-sm font-semibold transition-all duration-300 ease-out"
          :class="[
            layoutStore.currentModule === mod.id 
              ? 'bg-white text-primary shadow-lg shadow-primary/5 ring-1 ring-slate-200/50' 
              : 'text-slate-500 hover:bg-white/50 hover:text-slate-900'
          ]"
        >
          <component 
            :is="mod.icon" 
            class="h-4.5 w-4.5 transition-colors duration-300" 
            :class="[layoutStore.currentModule === mod.id ? 'text-primary' : 'text-slate-400 group-hover:text-slate-600']" 
          />
          {{ mod.name }}
        </button>
      </div>

      <!-- Module Switcher (Mobile) -->
      <div class="flex md:hidden">
        <Select :model-value="layoutStore.currentModule" @update:model-value="(val) => handleModuleChange(val as string)">
          <SelectTrigger class="flex h-10 items-center gap-2 rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm font-bold text-slate-800 shadow-sm active:scale-95 transition-transform">
            <div class="flex items-center gap-2">
              <SelectValue :placeholder="currentModuleName" />
            </div>
          </SelectTrigger>
          <SelectContent class="rounded-xl border-slate-200 shadow-xl">
            <SelectItem 
              v-for="mod in modules" 
              :key="mod.id" 
              :value="mod.id"
              class="rounded-lg m-1"
            >
              <div class="flex items-center gap-2">
                <component :is="mod.icon" class="h-4 w-4" :class="mod.color" />
                {{ mod.name }}
              </div>
            </SelectItem>
          </SelectContent>
        </Select>
      </div>
    </div>

    <div class="flex items-center gap-3 md:gap-6">
      <!-- Branch Selector -->
      <div v-if="masterDataStore.branches.length > 0" class="hidden sm:block">
        <Select :model-value="masterDataStore.selectedBranchId || undefined" @update:model-value="(val) => masterDataStore.setSelectedBranchId(val as string)">
          <SelectTrigger class="w-[180px] h-10 bg-slate-100/50 border-slate-200/50 rounded-xl focus:ring-primary/20">
            <div class="flex items-center gap-2 text-slate-700">
              <Building2 class="h-4 w-4 text-slate-400" />
              <SelectValue placeholder="Pilih Cabang" />
            </div>
          </SelectTrigger>
          <SelectContent class="rounded-xl border-slate-200 shadow-xl">
            <SelectItem value="ALL_BRANCHES" class="rounded-lg m-1 font-bold text-primary">
              <div class="flex items-center gap-2">
                <Globe class="h-4 w-4" />
                Semua Cabang
              </div>
            </SelectItem>
            <SelectItem 
              v-for="branch in masterDataStore.branches" 
              :key="branch.id" 
              :value="branch.id"
              class="rounded-lg m-1"
            >
              {{ branch.name }}
            </SelectItem>
          </SelectContent>
        </Select>
      </div>

      <NotificationDropdown />
      
      <div class="h-10 w-px bg-slate-200/80 mx-1"></div>
      
      <div class="flex items-center gap-4 pl-1 hover:bg-slate-50 p-1.5 rounded-2xl transition-all duration-300 cursor-pointer group">
        <div class="hidden text-right lg:block">
          <p class="text-sm font-bold text-slate-900 leading-tight">Admin HR</p>
          <p class="text-[11px] text-primary font-bold uppercase tracking-wider mt-0.5">Super Administrator</p>
        </div>
        <div class="h-10 w-10 rounded-2xl bg-gradient-to-br from-primary via-primary/90 to-primary/80 p-0.5 shadow-lg shadow-primary/20 rotate-0 group-hover:rotate-6 transition-transform duration-500">
          <div class="h-full w-full rounded-[14px] border-2 border-white/20 bg-primary flex items-center justify-center overflow-hidden shadow-inner">
            <span class="text-white font-black text-xs">AH</span>
          </div>
        </div>
      </div>
    </div>
  </header>
</template>

<style scoped>
button {
  -webkit-tap-highlight-color: transparent;
}
</style>
