// src/router/index.ts
import { createRouter, createWebHistory } from 'vue-router'
import DashboardLayout from '@/layouts/DashboardLayout.vue'
import { useAuthStore } from '@/stores/auth'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/login',
      name: 'login',
      component: () => import('@/views/LoginView.vue'),
    },
    {
      path: '/',
      component: DashboardLayout,
      meta: { requiresAuth: true },
      children: [
        {
          path: '',
          name: 'dashboard',
          component: () => import('@/views/DashboardView.vue'),
        },
        {
          path: 'employees',
          name: 'employees',
          component: () => import('@/views/EmployeeView.vue'),
        },
        {
          path: 'attendance',
          name: 'attendance',
          component: () => import('@/views/AttendanceView.vue'),
        },
        {
          path: 'leaves',
          name: 'leaves',
          component: () => import('@/views/LeaveView.vue'),
        },
        {
          path: 'payroll',
          name: 'payroll',
          component: () => import('@/views/PayrollView.vue'),
        },
        {
          path: 'overtimes',
          name: 'overtimes',
          component: () => import('@/views/OvertimeView.vue'),
        },
        {
          path: 'job-positions',
          name: 'jobPositions',
          component: () => import('@/views/JobPositionView.vue'),
        },
        {
          path: 'payroll-components',
          name: 'payrollComponents',
          component: () => import('@/views/PayrollComponentView.vue'),
        },
        {
          path: 'leave-types',
          name: 'leaveTypes',
          component: () => import('@/views/LeaveTypeView.vue'),
        },
        {
          path: 'shifts',
          name: 'shifts',
          component: () => import('@/views/ShiftView.vue'),
        },
        {
          path: 'users',
          name: 'users',
          component: () => import('@/views/UserView.vue'),
        },
        {
          path: 'departments',
          name: 'departments',
          component: () => import('@/views/DepartmentView.vue'),
        },
        {
          path: 'companies',
          name: 'companies',
          component: () => import('@/views/CompanyView.vue'),
        },
        {
          path: 'branches',
          name: 'branches',
          component: () => import('@/views/BranchView.vue'),
        },
        {
          path: 'employee-shifts',
          name: 'employeeShifts',
          component: () => import('@/views/EmployeeShiftView.vue'),
        },
        {
          path: 'leave-requests',
          name: 'leaveRequests',
          component: () => import('@/views/LeaveRequestView.vue'),
        },
        {
          path: 'leave-balances',
          name: 'leaveBalances',
          component: () => import('@/views/LeaveBalanceView.vue'),
        },
        {
          path: 'attendance-logs',
          name: 'attendanceLogs',
          component: () => import('@/views/AttendanceLogView.vue'),
        },
        {
          path: 'payroll-runs',
          name: 'payrollRuns',
          component: () => import('@/views/PayrollRunView.vue'),
        }
      ]
    }
  ],
})

router.beforeEach((to, from, next) => {
  const authStore = useAuthStore()
  
  // 1. Check if route requires auth
  if (to.meta.requiresAuth) {
    if (!authStore.isAuthenticated) {
      // Not logged in -> Login
      return next('/login')
    }
    
    if (!authStore.isAuthorized) {
      // Logged in but not authorized (not superadmin/admin/HR)
      // For now, logout and redirect to login, or we can show an error
      authStore.logout()
      return next('/login')
    }
  }

  // 2. Prevent logged in authorized users from seeing login page
  if (to.name === 'login' && authStore.isAuthenticated && authStore.isAuthorized) {
    return next('/')
  }

  next()
})

export default router
