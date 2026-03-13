<script setup lang="ts">
import Sidebar from '@/components/Sidebar.vue'
import { RouterView } from 'vue-router'
</script>

<template>
  <div class="flex h-screen bg-[#fafbfc] font-sans text-gray-900 overflow-hidden text-[15px]">
    <Sidebar />
    
    <main class="flex-1 overflow-x-hidden overflow-y-auto">
      <div class="p-8 w-full">
        <RouterView />
      </div>
    </main>
  </div>
</template>

<style>
/* Base typography reset to match the screenshot */
body {
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
}
</style>
