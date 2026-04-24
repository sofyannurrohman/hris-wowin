<script setup lang="ts">
import { RouterLink, useRouter } from 'vue-router'
import { Button } from '@/components/ui/button'
import { useAuthStore } from '@/stores/auth'
import { useLayoutStore } from '@/stores/layout'
import { computed } from 'vue'
import { 
  LayoutDashboard, 
  Users, 
  Clock, 
  Wallet, 
  FileText, 
  Settings, 
  Briefcase, 
  Calculator, 
  Calendar, 
  UserCircle, 
  Building2, 
  Globe, 
  MapPin, 
  ClipboardList, 
  CalendarCheck, 
  Scale, 
  History, 
  Banknote,
  Receipt,
  Target,
  Megaphone,
  Timer,
  LogOut 
} from 'lucide-vue-next'

const authStore = useAuthStore()
const layoutStore = useLayoutStore()
const router = useRouter()

const user = computed(() => authStore.user)

// Logout handler
const handleLogout = () => {
  authStore.logout()
  router.push('/login')
}

const menuGroups = [
  {
    title: 'Utama',
    items: [
      { to: '/', name: 'Dashboard', icon: LayoutDashboard },
      { to: '/employees', name: 'Karyawan', icon: Users },
      { to: '/attendance', name: 'Kehadiran', icon: Clock },
      { to: '/leaves', name: 'Cuti & Izin', icon: FileText },
      { to: '/overtimes', name: 'Lembur', icon: Timer },
      { to: '/reimbursements', name: 'Reimbursement', icon: Receipt },
      { to: '/performance-kpi', name: 'Performa & KPI', icon: Target },
      { to: '/payroll', name: 'Penggajian', icon: Wallet },
      { to: '/payroll-settings', name: 'Pengaturan Gaji', icon: Settings },
    ]
  },
  {
    title: 'Master Data',
    items: [
    { to: '/users', name: 'Pengguna Akun', icon: UserCircle },
    { to: '/leave-types', name: 'Tipe Cuti', icon: Calendar },
    { to: '/branches', name: 'Kantor Cabang', icon: MapPin },
    { to: '/companies', name: 'Perusahaan Utama', icon: Globe },
    { to: '/departments', name: 'Departemen', icon: Building2 },
      { to: '/job-positions', name: 'Jabatan', icon: Briefcase },
      { to: '/shifts', name: 'Shift Kerja', icon: Clock },
      { to: '/announcements', name: 'Pengumuman', icon: Megaphone },
    ]
  },
  {
    title: 'Transaksional',
    items: [
      { to: '/employee-shifts', name: 'Penugasan Shift', icon: ClipboardList },
      { to: '/leave-balances', name: 'Saldo Cuti', icon: Scale },
      { to: '/attendance-logs', name: 'Log Absensi', icon: History },
    ]
  }
]
</script>

<template>
  <aside 
    class="bg-white border-r border-slate-200/60 flex flex-col h-full shrink-0 transition-all duration-500 ease-in-out z-40 relative shadow-[1px_0_10px_rgba(0,0,0,0.02)]"
    :class="[layoutStore.isSidebarCollapsed ? 'w-[88px]' : 'w-[280px]']"
  >
    <!-- Logo Area -->
    <div class="py-8 transition-all duration-500" :class="[layoutStore.isSidebarCollapsed ? 'px-0' : 'px-6']">
      <div class="flex items-center overflow-hidden whitespace-nowrap transition-all duration-500" :class="[layoutStore.isSidebarCollapsed ? 'justify-center gap-0' : 'gap-3.5']">
        <div class="bg-primary/5 p-2 rounded-2xl border border-primary/10 shadow-sm shadow-primary/5 shrink-0 transition-all duration-500" :class="{ 'scale-90': layoutStore.isSidebarCollapsed }">
          <img src="@/assets/logo.svg" alt="Logo" class="w-8 h-8 shrink-0" />
        </div>
        <div 
          class="flex flex-col transition-all duration-500 origin-left"
          :class="[layoutStore.isSidebarCollapsed ? 'opacity-0 w-0 -translate-x-4 scale-75' : 'opacity-100 w-auto translate-x-0 scale-100']"
        >
          <span class="text-xl font-extrabold text-slate-900 tracking-tight leading-tight">HRIS</span>
          <span class="text-[10px] font-bold text-primary uppercase tracking-[0.2em] leading-none">SENTRAWEB</span>
        </div>
      </div>
    </div>
    
    <!-- Navigation Links -->
    <nav class="flex-1 px-4 space-y-7 overflow-y-auto no-scrollbar pb-10">
      <div v-for="group in menuGroups" :key="group.title" class="space-y-2">
        <p 
          v-if="group.title"
          class="px-4 text-[10px] font-extrabold uppercase tracking-[0.15em] text-slate-400 transition-all duration-500 whitespace-nowrap overflow-hidden"
          :class="[layoutStore.isSidebarCollapsed ? 'opacity-0 h-0 my-0' : 'opacity-100 h-auto my-2']"
        >
          {{ group.title }}
        </p>

        <div class="space-y-1">
          <RouterLink 
            v-for="item in group.items"
            :key="item.to"
            :to="item.to" 
            class="group flex items-center px-4 py-3 text-slate-500 rounded-2xl transition-all duration-300 hover:bg-slate-50 hover:text-slate-900 relative overflow-hidden"
            :class="[
                layoutStore.isSidebarCollapsed ? 'justify-center gap-0 px-2' : 'gap-3.5',
                $route.path === item.to ? '!bg-primary/5 !text-primary shadow-sm ring-1 ring-primary/10' : ''
            ]"
          >
            <!-- Vertical Indicator for Active Item -->
            <div 
              class="absolute left-0 top-1/2 -translate-y-1/2 w-1 h-6 bg-primary rounded-r-full transition-transform duration-300 scale-y-0 group-[.router-link-exact-active]:scale-y-100"
            ></div>

            <component 
              :is="item.icon" 
              class="h-5 w-5 transition-all duration-300 group-hover:scale-110 group-[.router-link-exact-active]:scale-110 shrink-0" 
            />
            
            <span 
              class="text-[14px] font-bold transition-all duration-500 origin-left whitespace-nowrap"
              :class="[layoutStore.isSidebarCollapsed ? 'opacity-0 w-0 scale-90 invisible ml-0' : 'opacity-100 w-auto scale-100 visible ml-0']"
            >
              {{ item.name }}
            </span>

            <!-- Tooltip for collapsed state (native title) -->
            <div v-if="layoutStore.isSidebarCollapsed" class="sr-only">{{ item.name }}</div>
          </RouterLink>
        </div>
      </div>
    </nav>

    <!-- Logout Area -->
    <div class="p-4 mt-auto border-t border-slate-100 bg-slate-50/30 transition-all duration-500" :class="[layoutStore.isSidebarCollapsed ? 'px-2' : 'p-6']">
      <Button 
        @click="handleLogout" 
        variant="ghost" 
        class="w-full text-slate-500 hover:text-primary hover:bg-white hover:shadow-sm rounded-2xl py-6 transition-all duration-300 group px-2"
        :class="[layoutStore.isSidebarCollapsed ? 'justify-center gap-0' : 'justify-start gap-3.5 px-4']"
      >
        <div class="bg-slate-100 p-1.5 rounded-xl group-hover:bg-primary/10 transition-colors duration-300 shrink-0">
          <LogOut class="w-5 h-5 shrink-0 transition-transform group-hover:translate-x-0.5" />
        </div>
        <span 
          class="text-[14px] font-bold transition-all duration-500 origin-left whitespace-nowrap"
          :class="[layoutStore.isSidebarCollapsed ? 'opacity-0 w-0 scale-90 invisible' : 'opacity-100 w-auto scale-100 visible']"
        >
          Log Out
        </span>
      </Button>
    </div>
  </aside>
</template>

<style scoped>
/* Custom scrollbar for a cleaner sidebar look */
.no-scrollbar::-webkit-scrollbar {
  display: none;
}

.no-scrollbar {
  -ms-overflow-style: none;
  scrollbar-width: none;
}

aside {
  -webkit-tap-highlight-color: transparent;
}
</style>

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
