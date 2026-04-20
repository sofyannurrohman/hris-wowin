<script setup lang="ts">
import Sidebar from '@/components/Sidebar.vue'
import Header from '@/components/Header.vue'
import { RouterView } from 'vue-router'
import { useLayoutStore } from '@/stores/layout'

const layoutStore = useLayoutStore()
</script>

<template>
  <div class="flex h-screen bg-[#fafbfc] font-sans text-gray-900 overflow-hidden text-[15px]">
    <Sidebar />
    
    <div class="flex flex-col flex-1 overflow-hidden">
      <Header />
      
      <main class="flex-1 overflow-x-hidden overflow-y-auto">
        <div class="p-4 md:p-8 w-full max-w-[1600px] mx-auto">
          <RouterView v-slot="{ Component }">
            <Transition name="page-fade" mode="out-in">
              <component :is="Component" />
            </Transition>
          </RouterView>
        </div>
      </main>
    </div>
  </div>
</template>

<style>
/* Base typography reset to match the screenshot */
body {
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
}
</style>
