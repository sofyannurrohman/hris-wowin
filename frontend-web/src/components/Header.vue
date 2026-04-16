<script setup lang="ts">
import { useLayoutStore } from '@/stores/layout'
import { Menu, Search, Bell, Briefcase, Users, PieChart, ChevronDown } from 'lucide-vue-next'
import { Button } from '@/components/ui/button'
import { computed } from 'vue'

const layoutStore = useLayoutStore()

const modules = [
  { id: 'hris', name: 'HRIS', icon: Users, color: 'text-primary' },
  { id: 'erecruitment', name: 'eRecruitment', icon: Briefcase, color: 'text-slate-600' },
  { id: 'sales', name: 'Sales & Marketing', icon: PieChart, color: 'text-slate-600' }
]

const currentModuleName = computed(() => {
  return modules.find(m => m.id === layoutStore.currentModule)?.name || 'HRIS'
})

const setModule = (moduleId: string) => {
  layoutStore.setModule(moduleId)
}
</script>

<template>
  <header class="sticky top-0 z-30 flex h-18 w-full items-center justify-between border-b border-slate-200/60 bg-white/70 px-4 backdrop-blur-xl lg:px-8">
    <div class="flex items-center gap-6">
      <Button 
        variant="ghost" 
        size="icon" 
        class="h-10 w-10 text-slate-500 hover:bg-slate-100/80 hover:text-primary transition-all duration-300"
        @click="layoutStore.toggleSidebar"
      >
        <Menu class="h-5.5 w-5.5" />
        <span class="sr-only">Toggle Sidebar</span>
      </Button>

      <!-- Module Switcher (Desktop) -->
      <div class="hidden items-center gap-1 rounded-2xl bg-slate-100/50 p-1.5 md:flex border border-slate-200/50">
        <button
          v-for="mod in modules"
          :key="mod.id"
          @click="setModule(mod.id)"
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
        <button class="flex items-center gap-2 rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm font-bold text-slate-800 shadow-sm active:scale-95 transition-transform">
          <span>{{ currentModuleName }}</span>
          <ChevronDown class="h-4 w-4 text-primary" />
        </button>
      </div>
    </div>

    <div class="flex items-center gap-3 md:gap-6">
      <div class="relative hidden sm:block group">
        <Search class="absolute left-3.5 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400 group-focus-within:text-primary transition-colors duration-300" />
        <input 
          type="search" 
          placeholder="Cari data..." 
          class="h-11 w-72 rounded-2xl border border-slate-200/80 bg-slate-50/50 pl-11 pr-4 text-sm font-medium focus:bg-white focus:ring-4 focus:ring-primary/5 focus:border-primary/30 transition-all duration-300 outline-none"
        />
      </div>

      <Button variant="ghost" size="icon" class="relative h-11 w-11 rounded-2xl border border-transparent hover:border-slate-200 hover:bg-white hover:shadow-sm text-slate-500 transition-all duration-300">
        <Bell class="h-5.5 w-5.5" />
        <span class="absolute right-3 top-3 flex h-3 w-3">
          <span class="absolute inline-flex h-full w-full animate-ping rounded-full bg-primary/40 opacity-75"></span>
          <span class="relative inline-flex h-3 w-3 rounded-full bg-primary border-2 border-white"></span>
        </span>
      </Button>
      
      <div class="h-10 w-px bg-slate-200/80 mx-1"></div>
      
      <div class="flex items-center gap-4 pl-1 hover:bg-slate-50 p-1.5 rounded-2xl transition-all duration-300 cursor-pointer group">
        <div class="hidden text-right lg:block">
          <p class="text-sm font-bold text-slate-900 leading-tight">Admin HR</p>
          <p class="text-[11px] text-primary font-bold uppercase tracking-wider mt-0.5">Super Administrator</p>
        </div>
        <div class="h-10 w-10 rounded-2xl bg-gradient-to-br from-primary via-primary/90 to-primary/80 p-0.5 shadow-lg shadow-primary/20 rotate-0 group-hover:rotate-6 transition-transform duration-500">
          <div class="h-full w-full rounded-[14px] border-2 border-white/20 bg-white overflow-hidden shadow-inner">
            <img src="https://ui-avatars.com/api/?name=Admin+HR&background=990000&color=ffffff&bold=true" alt="Avatar" class="h-full w-full object-cover" />
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
