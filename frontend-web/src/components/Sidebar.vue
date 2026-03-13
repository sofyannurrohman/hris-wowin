<script setup lang="ts">
import { RouterLink, useRouter } from 'vue-router'
import { Button } from '@/components/ui/button'
import { useAuthStore } from '@/stores/auth'
import { computed } from 'vue'

const authStore = useAuthStore()
const router = useRouter()

const user = computed(() => authStore.user)

const handleLogout = () => {
  authStore.logout()
  router.push('/login')
}

// Generate avatar URL based on name
const avatarUrl = computed(() => {
  if (!user.value?.FirstName) return 'https://i.pravatar.cc/150?u=tom'
  return `https://ui-avatars.com/api/?name=${user.value.FirstName}+${user.value.LastName || ''}&background=random`
})
</script>

<template>
  <aside class="w-[260px] bg-white border-r border-gray-200 flex flex-col h-full shrink-0">
    <!-- User Profile Dropdown Area -->
    <div class="p-6 pb-8">
```vue
      <div class="flex items-center gap-3">
        <img src="@/assets/logo.svg" alt="Logo" class="w-10 h-10" />
        <span class="text-lg font-bold text-gray-900 tracking-tight">SENTRAWEB HRIS</span>
      </div>
```
    </div>
    
    <!-- Navigation Links -->
    <nav class="flex-1 px-4 space-y-1 overflow-y-auto">
      <RouterLink 
        to="/" 
        class="flex items-center gap-3 px-3 py-2.5 text-gray-600 rounded-lg transition-colors hover:bg-gray-50 group border-l-4 border-transparent"
        active-class="!bg-blue-50/60 !text-blue-700 !border-blue-600 font-medium"
      >
        <!-- Custom icon for Dasbor (4 squares) -->
        <svg class="w-5 h-5 opacity-70 group-[.router-link-exact-active]:text-blue-600 group-[.router-link-exact-active]:opacity-100" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z" />
        </svg>
        <span class="text-[15px]">Dasbor</span>
      </RouterLink>
      
      <RouterLink 
        to="/employees" 
        class="flex items-center gap-3 px-3 py-2.5 text-gray-600 rounded-lg transition-colors hover:bg-gray-50 group border-l-4 border-transparent"
        active-class="!bg-blue-50/60 !text-blue-700 !border-blue-600 font-medium"
      >
        <!-- Icon Karyawan -->
        <svg class="w-5 h-5 opacity-70 group-[.router-link-exact-active]:text-blue-600 group-[.router-link-exact-active]:opacity-100" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
        </svg>
        <span class="text-[15px]">Karyawan</span>
      </RouterLink>

      <RouterLink 
        to="/attendance" 
        class="flex items-center gap-3 px-3 py-2.5 text-gray-600 rounded-lg transition-colors hover:bg-gray-50 group border-l-4 border-transparent"
        active-class="!bg-blue-50/60 !text-blue-700 !border-blue-600 font-medium"
      >
        <!-- Icon Kehadiran (Clock) -->
        <svg class="w-5 h-5 opacity-70 group-[.router-link-exact-active]:text-blue-600 group-[.router-link-exact-active]:opacity-100" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <span class="text-[15px]">Kehadiran</span>
      </RouterLink>

      <RouterLink 
        to="/payroll" 
        class="flex items-center gap-3 px-3 py-2.5 text-gray-600 rounded-lg transition-colors hover:bg-gray-50 group border-l-4 border-transparent"
        active-class="!bg-blue-50/60 !text-blue-700 !border-blue-600 font-medium"
      >
        <!-- Icon Payroll (Wallet/Money) -->
        <svg class="w-5 h-5 opacity-70 group-[.router-link-exact-active]:text-blue-600 group-[.router-link-exact-active]:opacity-100" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z" />
        </svg>
        <span class="text-[15px]">Payroll</span>
      </RouterLink>

      <RouterLink 
        to="/leaves" 
        class="flex items-center gap-3 px-3 py-2.5 text-gray-600 rounded-lg transition-colors hover:bg-gray-50 group border-l-4 border-transparent"
        active-class="!bg-blue-50/60 !text-blue-700 !border-blue-600 font-medium"
      >
        <!-- Icon Laporan (Document) -->
        <svg class="w-5 h-5 opacity-70 group-[.router-link-exact-active]:text-blue-600 group-[.router-link-exact-active]:opacity-100" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
           <path stroke-linecap="round" stroke-linejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
        </svg>
        <span class="text-[15px]">Laporan</span>
      </RouterLink>

      <RouterLink 
        to="/settings" 
        class="flex items-center gap-3 px-3 py-2.5 text-gray-600 rounded-lg transition-colors hover:bg-gray-50 group border-l-4 border-transparent"
        active-class="!bg-blue-50/60 !text-blue-700 !border-blue-600 font-medium"
      >
        <!-- Icon Pengaturan (Cog) -->
        <svg class="w-5 h-5 opacity-70 group-[.router-link-exact-active]:text-blue-600 group-[.router-link-exact-active]:opacity-100" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
          <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
        </svg>
        <span class="text-[15px]">Pengaturan</span>
      </RouterLink>

      <RouterLink 
        to="/job-positions" 
        class="flex items-center gap-3 px-3 py-2.5 text-gray-600 rounded-lg transition-colors hover:bg-gray-50 group border-l-4 border-transparent"
        active-class="!bg-blue-50/60 !text-blue-700 !border-blue-600 font-medium"
      >
        <!-- Icon Jabatan (Briefcase) -->
        <svg class="w-5 h-5 opacity-70 group-[.router-link-exact-active]:text-blue-600 group-[.router-link-exact-active]:opacity-100" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
        </svg>
        <span class="text-[15px]">Jabatan</span>
      </RouterLink>

      <RouterLink 
        to="/payroll-components" 
        class="flex items-center gap-3 px-3 py-2.5 text-gray-600 rounded-lg transition-colors hover:bg-gray-50 group border-l-4 border-transparent"
        active-class="!bg-blue-50/60 !text-blue-700 !border-blue-600 font-medium"
      >
        <!-- Icon Komponen Gaji (Calculator) -->
        <svg class="w-5 h-5 opacity-70 group-[.router-link-exact-active]:text-blue-600 group-[.router-link-exact-active]:opacity-100" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M9 7h6m0 10v-3m-3 3h.01M9 17h.01M9 14h.01M12 14h.01M15 11h.01M12 11h.01M9 11h.01M7 21h10a2 2 0 002-2V5a2 2 0 00-2-2H7a2 2 0 00-2 2v14a2 2 0 002 2z" />
        </svg>
        <span class="text-[15px]">Komponen Gaji</span>
      </RouterLink>

      <RouterLink 
        to="/leave-types" 
        class="flex items-center gap-3 px-3 py-2.5 text-gray-600 rounded-lg transition-colors hover:bg-gray-50 group border-l-4 border-transparent"
        active-class="!bg-blue-50/60 !text-blue-700 !border-blue-600 font-medium"
      >
        <!-- Icon Tipe Cuti (Calendar) -->
        <svg class="w-5 h-5 opacity-70 group-[.router-link-exact-active]:text-blue-600 group-[.router-link-exact-active]:opacity-100" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
        </svg>
        <span class="text-[15px]">Tipe Cuti</span>
      </RouterLink>

      <RouterLink 
        to="/shifts" 
        class="flex items-center gap-3 px-3 py-2.5 text-gray-600 rounded-lg transition-colors hover:bg-gray-50 group border-l-4 border-transparent"
        active-class="!bg-blue-50/60 !text-blue-700 !border-blue-600 font-medium"
      >
        <!-- Icon Shift Kerja (Clock Arrow) -->
        <svg class="w-5 h-5 opacity-70 group-[.router-link-exact-active]:text-blue-600 group-[.router-link-exact-active]:opacity-100" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
          <path stroke-linecap="round" stroke-linejoin="round" d="M19.07 4.93l-2.83 2.83M19.07 19.07l-2.83-2.83M4.93 19.07l2.83-2.83M4.93 4.93l2.83 2.83" />
        </svg>
        <span class="text-[15px]">Shift Kerja</span>
      </RouterLink>

      <RouterLink 
        to="/users" 
        class="flex items-center gap-3 px-3 py-2.5 text-gray-600 rounded-lg transition-colors hover:bg-gray-50 group border-l-4 border-transparent"
        active-class="!bg-blue-50/60 !text-blue-700 !border-blue-600 font-medium"
      >
        <!-- Icon Pengguna (Users) -->
        <svg class="w-5 h-5 opacity-70 group-[.router-link-exact-active]:text-blue-600 group-[.router-link-exact-active]:opacity-100" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
        </svg>
        <span class="text-[15px]">Pengguna Akun</span>
      </RouterLink>

      <RouterLink 
        to="/departments" 
        class="flex items-center gap-3 px-3 py-2.5 text-gray-600 rounded-lg transition-colors hover:bg-gray-50 group border-l-4 border-transparent"
        active-class="!bg-blue-50/60 !text-blue-700 !border-blue-600 font-medium"
      >
        <!-- Icon Department (Office building) -->
        <svg class="w-5 h-5 opacity-70 group-[.router-link-exact-active]:text-blue-600 group-[.router-link-exact-active]:opacity-100" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
        </svg>
        <span class="text-[15px]">Departemen</span>
      </RouterLink>

      <RouterLink 
        to="/companies" 
        class="flex items-center gap-3 px-3 py-2.5 text-gray-600 rounded-lg transition-colors hover:bg-gray-50 group border-l-4 border-transparent"
        active-class="!bg-blue-50/60 !text-blue-700 !border-blue-600 font-medium"
      >
        <!-- Icon Company (Globe/Briefcase) -->
        <svg class="w-5 h-5 opacity-70 group-[.router-link-exact-active]:text-blue-600 group-[.router-link-exact-active]:opacity-100" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
        </svg>
        <span class="text-[15px]">Perusahaan Utama</span>
      </RouterLink>

      <RouterLink 
        to="/branches" 
        class="flex items-center gap-3 px-3 py-2.5 text-gray-600 rounded-lg transition-colors hover:bg-gray-50 group border-l-4 border-transparent"
        active-class="!bg-blue-50/60 !text-blue-700 !border-blue-600 font-medium"
      >
        <svg class="w-5 h-5 opacity-70 group-[.router-link-exact-active]:text-blue-600 group-[.router-link-exact-active]:opacity-100" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
          <path stroke-linecap="round" stroke-linejoin="round" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
        </svg>
        <span class="text-[15px]">Kantor Cabang</span>
      </RouterLink>

      <!-- Section: Transaksional -->
      <p class="px-3 pt-4 pb-1 text-[11px] font-bold uppercase tracking-widest text-gray-400">Transaksional</p>

      <RouterLink 
        to="/employee-shifts" 
        class="flex items-center gap-3 px-3 py-2.5 text-gray-600 rounded-lg transition-colors hover:bg-gray-50 group border-l-4 border-transparent"
        active-class="!bg-blue-50/60 !text-blue-700 !border-blue-600 font-medium"
      >
        <svg class="w-5 h-5 opacity-70 group-[.router-link-exact-active]:text-blue-600 group-[.router-link-exact-active]:opacity-100" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
        </svg>
        <span class="text-[15px]">Penugasan Shift</span>
      </RouterLink>

      <RouterLink 
        to="/leave-requests" 
        class="flex items-center gap-3 px-3 py-2.5 text-gray-600 rounded-lg transition-colors hover:bg-gray-50 group border-l-4 border-transparent"
        active-class="!bg-blue-50/60 !text-blue-700 !border-blue-600 font-medium"
      >
        <svg class="w-5 h-5 opacity-70 group-[.router-link-exact-active]:text-blue-600 group-[.router-link-exact-active]:opacity-100" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
        </svg>
        <span class="text-[15px]">Pengajuan Cuti</span>
      </RouterLink>

      <RouterLink 
        to="/leave-balances" 
        class="flex items-center gap-3 px-3 py-2.5 text-gray-600 rounded-lg transition-colors hover:bg-gray-50 group border-l-4 border-transparent"
        active-class="!bg-blue-50/60 !text-blue-700 !border-blue-600 font-medium"
      >
        <svg class="w-5 h-5 opacity-70 group-[.router-link-exact-active]:text-blue-600 group-[.router-link-exact-active]:opacity-100" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M3 6l3 1m0 0l-3 9a5.002 5.002 0 006.001 0M6 7l3 9M6 7l6-2m6 2l3-1m-3 1l-3 9a5.002 5.002 0 006.001 0M18 7l3 9m-3-9l-6-2m0-2v2m0 16V5m0 16H9m3 0h3" />
        </svg>
        <span class="text-[15px]">Saldo Cuti</span>
      </RouterLink>

      <RouterLink 
        to="/attendance-logs" 
        class="flex items-center gap-3 px-3 py-2.5 text-gray-600 rounded-lg transition-colors hover:bg-gray-50 group border-l-4 border-transparent"
        active-class="!bg-blue-50/60 !text-blue-700 !border-blue-600 font-medium"
      >
        <svg class="w-5 h-5 opacity-70 group-[.router-link-exact-active]:text-blue-600 group-[.router-link-exact-active]:opacity-100" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
        </svg>
        <span class="text-[15px]">Log Absensi</span>
      </RouterLink>

      <RouterLink 
        to="/payroll-runs" 
        class="flex items-center gap-3 px-3 py-2.5 text-gray-600 rounded-lg transition-colors hover:bg-gray-50 group border-l-4 border-transparent"
        active-class="!bg-blue-50/60 !text-blue-700 !border-blue-600 font-medium"
      >
        <svg class="w-5 h-5 opacity-70 group-[.router-link-exact-active]:text-blue-600 group-[.router-link-exact-active]:opacity-100" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z" />
        </svg>
        <span class="text-[15px]">Penggajian</span>
      </RouterLink>
    </nav>

    <!-- Logout Area -->
    <div class="p-6">
      <Button @click="handleLogout" variant="ghost" class="w-full justify-start gap-3 text-gray-500 hover:text-gray-900 hover:bg-transparent px-3">
        <svg class="w-5 h-5 opacity-70" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
        </svg>
        <span class="text-[15px] font-medium">Keluar</span>
      </Button>
    </div>
  </aside>
</template>

<style scoped>
/* Custom scrollbar for a cleaner sidebar look */
nav::-webkit-scrollbar {
  width: 5px;
}

nav::-webkit-scrollbar-track {
  background: transparent;
}

nav::-webkit-scrollbar-thumb {
  background: #e5e7eb;
  border-radius: 10px;
}

nav::-webkit-scrollbar-thumb:hover {
  background: #d1d5db;
}

/* For Firefox */
nav {
  scrollbar-width: thin;
  scrollbar-color: #e5e7eb transparent;
}
</style>
