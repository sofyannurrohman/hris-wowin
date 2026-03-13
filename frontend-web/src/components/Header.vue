<script setup lang="ts">
</script>

<template>
  <header class="h-16 bg-white/70 backdrop-blur-lg border-b border-gray-200 flex items-center justify-between px-8 sticky top-0 z-10 transition-all shadow-sm">
    <div class="text-gray-600 font-medium text-sm flex items-center gap-2">
      <span class="text-xl">👋</span> Welcome back, Manager
    </div>
    
    <div class="flex items-center gap-4">
      <button class="p-2 text-gray-400 hover:text-gray-600 transition-colors rounded-full hover:bg-gray-100/50">
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-5 h-5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M14.857 17.082a23.848 23.848 0 005.454-1.31A8.967 8.967 0 0118 9.75v-.7V9A6 6 0 006 9v.75a8.967 8.967 0 01-2.312 6.022c1.733.64 3.56 1.085 5.455 1.31m5.714 0a24.255 24.255 0 01-5.714 0m5.714 0a3 3 0 11-5.714 0" />
        </svg>
      </button>
      <div class="w-9 h-9 rounded-full bg-gradient-to-br from-emerald-400 to-cyan-500 shadow-md border-2 border-white ring-2 ring-gray-100"></div>
    </div>
  </header>
</template>
