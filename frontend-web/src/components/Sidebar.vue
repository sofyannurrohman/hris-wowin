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
  LogOut 
} from 'lucide-vue-next'

const authStore = useAuthStore()
const layoutStore = useLayoutStore()
const router = useRouter()

const user = computed(() => authStore.user)

const handleLogout = () => {
  authStore.logout()
  router.push('/login')
}

// Generate avatar URL based on name
const avatarUrl = computed(() => {
  if (!user.value?.FirstName) return 'https://i.pravatar.cc/150?u=tom'
  return `https://ui-avatars.com/api/?name=${user.value.FirstName}+${user.value.LastName || ''}&background=990000&color=ffffff&bold=true`
})

const menuGroups = [
  {
    title: 'Utama',
    items: [
      { to: '/', name: 'Dashboard', icon: LayoutDashboard },
      { to: '/employees', name: 'Karyawan', icon: Users },
      { to: '/attendance', name: 'Kehadiran', icon: Clock },
      { to: '/payroll', name: 'Payroll', icon: Wallet },
      { to: '/performance-kpi', name: 'Performa & KPI', icon: Target },
      { to: '/leaves', name: 'Cuti & Izin', icon: FileText },
      { to: '/payroll-settings', name: 'Pengaturan Payroll', icon: Settings },
    ]
  },
  {
    title: 'Master Data',
    items: [
      { to: '/job-positions', name: 'Jabatan', icon: Briefcase },
      { to: '/payroll-components', name: 'Komponen Gaji', icon: Calculator },
      { to: '/leave-types', name: 'Tipe Cuti', icon: Calendar },
      { to: '/shifts', name: 'Shift Kerja', icon: Clock },
      { to: '/users', name: 'Pengguna Akun', icon: UserCircle },
      { to: '/departments', name: 'Departemen', icon: Building2 },
      { to: '/companies', name: 'Perusahaan Utama', icon: Globe },
      { to: '/branches', name: 'Kantor Cabang', icon: MapPin },
    ]
  },
  {
    title: 'Transaksional',
    items: [
      { to: '/employee-shifts', name: 'Penugasan Shift', icon: ClipboardList },
      { to: '/leave-balances', name: 'Saldo Cuti', icon: Scale },
      { to: '/attendance-logs', name: 'Log Absensi', icon: History },
      { to: '/payroll-runs', name: 'Penggajian', icon: Banknote },
      { to: '/reimbursements', name: 'Reimbursement', icon: Receipt },
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
    <div class="px-6 py-8">
      <div class="flex items-center gap-3.5 overflow-hidden whitespace-nowrap">
        <div class="bg-primary/5 p-2 rounded-2xl border border-primary/10 shadow-sm shadow-primary/5">
          <img src="@/assets/logo.svg" alt="Logo" class="w-8 h-8 shrink-0" />
        </div>
        <div 
          class="flex flex-col transition-all duration-500"
          :class="[layoutStore.isSidebarCollapsed ? 'opacity-0 w-0 scale-90' : 'opacity-100 w-auto scale-100']"
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
          class="px-4 text-[10px] font-extrabold uppercase tracking-[0.15em] text-slate-400 transition-all duration-300 whitespace-nowrap"
          :class="[layoutStore.isSidebarCollapsed ? 'opacity-0 pl-0' : 'opacity-100']"
        >
          {{ group.title }}
        </p>

        <div class="space-y-1">
          <RouterLink 
            v-for="item in group.items"
            :key="item.to"
            :to="item.to" 
            class="group flex items-center gap-3.5 px-4 py-3 text-slate-500 rounded-2xl transition-all duration-300 hover:bg-slate-50 hover:text-slate-900 relative overflow-hidden"
            active-class="!bg-primary/5 !text-primary shadow-sm ring-1 ring-primary/10"
          >
            <!-- Vertical Indicator for Active Item -->
            <div 
              class="absolute left-0 top-1/2 -translate-y-1/2 w-1 h-6 bg-primary rounded-r-full transition-transform duration-300 scale-y-0 group-[.router-link-exact-active]:scale-y-100"
            ></div>

            <component 
              :is="item.icon" 
              class="h-5 w-5 transition-transform duration-300 group-hover:scale-110 group-[.router-link-exact-active]:scale-110 shrink-0" 
            />
            
            <span 
              class="text-[14px] font-bold transition-all duration-500 origin-left"
              :class="[layoutStore.isSidebarCollapsed ? 'opacity-0 w-0 scale-90 invisible' : 'opacity-100 w-auto scale-100 visible']"
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
    <div class="p-6 mt-auto border-t border-slate-100 bg-slate-50/30">
      <Button 
        @click="handleLogout" 
        variant="ghost" 
        class="w-full justify-start gap-3.5 text-slate-500 hover:text-primary hover:bg-white hover:shadow-sm rounded-2xl px-4 py-6 transition-all duration-300 group"
      >
        <div class="bg-slate-100 p-1.5 rounded-xl group-hover:bg-primary/10 transition-colors duration-300">
          <LogOut class="w-5 h-5 shrink-0 transition-transform group-hover:translate-x-0.5" />
        </div>
        <span 
          class="text-[14px] font-bold transition-all duration-500"
          :class="[layoutStore.isSidebarCollapsed ? 'opacity-0 w-0 scale-90 invisible' : 'opacity-100 w-auto scale-100 visible']"
        >
          Keluar Sesuai
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
