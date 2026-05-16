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
          path: 'reimbursements',
          name: 'reimbursements',
          component: () => import('@/views/ReimbursementView.vue'),
        },
        {
          path: 'performance-kpi',
          name: 'performanceKpi',
          component: () => import('@/views/PerformanceView.vue'),
        },
        {
          path: 'roles',
          name: 'roles',
          component: () => import('@/views/RoleView.vue'),
        },
        {
          path: 'audit-logs',
          name: 'auditLogs',
          component: () => import('@/views/AuditLogView.vue'),
        },
        {
          path: 'payroll-settings',
          name: 'payrollSettings',
          component: () => import('@/views/PayrollSettingsView.vue'),
        },
        {
          path: 'announcements',
          name: 'announcements',
          component: () => import('@/views/AnnouncementView.vue'),
        },
        {
          path: 'pkwt',
          name: 'pkwt',
          component: () => import('@/views/PKWTView.vue'),
        },
        {
          path: 'vehicles',
          name: 'vehicles',
          component: () => import('@/views/VehicleView.vue'),
        },
        // Sales & Marketing Module
        {
          path: 'sales',
          children: [
            {
              path: '',
              name: 'salesDashboard',
              component: () => import('@/views/sales/SalesDashboard.vue'),
            },
            {
              path: 'salesman',
              name: 'salesman',
              component: () => import('@/views/sales/SalesmanView.vue'),
            },
            {
              path: 'pesanan',
              name: 'salesOrders',
              component: () => import('@/views/sales/SalesOrderView.vue'),
            },
            {
              path: 'retur',
              name: 'salesReturns',
              component: () => import('@/views/sales/SalesReturnView.vue'),
            },
            {
              path: 'delivery',
              name: 'deliveryManagement',
              component: () => import('@/views/sales/LogisticsDashboard.vue'),
            },
            {
              path: 'surat-jalan',
              name: 'suratJalan',
              component: () => import('@/views/sales/SuratJalanView.vue'),
            },
            {
              path: 'penjualan',
              name: 'penjualan',
              component: () => import('@/views/sales/PenjualanView.vue'),
            },
            {
              path: 'pindah-barang',
              alias: 'retur_pindah',
              name: 'salesTransfers',
              component: () => import('@/views/warehouse/SalesTransferView.vue'),
            },
            {
              path: 'spanduk',
              name: 'spanduk',
              component: () => import('@/views/sales/SpandukView.vue'),
            },
            {
              path: 'kunjungan',
              name: 'salesVisits',
              component: () => import('@/views/sales/VisitManagementView.vue'),
            },
            {
              path: 'monitoring',
              name: 'monitoring',
              component: () => import('@/views/sales/Live-Monitoring.vue'),
            },
            {
              path: 'kpi',
              name: 'kpi',
              component: () => import('@/views/sales/KPI-Manager.vue'),
            },
            {
              path: 'customers',
              name: 'customers',
              component: () => import('@/views/sales/StoreView.vue'),
            },
            {
              path: 'verification',
              name: 'cashierVerification',
              component: () => import('@/views/warehouse/CashierVerificationView.vue'),
            }
          ]
        },
        // Factory & Logistics Module
        {
          path: 'factory',
          children: [
            {
              path: '',
              name: 'factoryDashboard',
              component: () => import('@/views/factory/FactoryDashboard.vue'),
            },
            {
              path: 'management',
              name: 'factoryManagement',
              component: () => import('@/views/factory/FactoryManagementView.vue'),
            },
            {
              path: 'products',
              name: 'factoryProducts',
              component: () => import('@/views/factory/FactoryProductView.vue'),
            },
            {
              path: 'recipes',
              name: 'factoryRecipes',
              component: () => import('@/views/factory/RecipeView.vue'),
            },
            {
              path: 'stock',
              name: 'factoryStockGlobal',
              component: () => import('@/views/factory/FactoryStockListView.vue'),
            },
            {
              path: 'transfers',
              name: 'factoryTransfersGlobal',
              component: () => import('@/views/factory/FactoryTransferListView.vue'),
            },
            {
              path: ':id',
              name: 'factoryInventory',
              component: () => import('@/views/factory/FactoryInventoryView.vue'),
            }
          ]
        },
        // Warehouse Module (Gudang Cabang)
        {
          path: 'warehouse',
          children: [
            {
              path: '',
              name: 'warehouseDashboard',
              component: () => import('@/views/warehouse/WarehouseDashboard.vue'),
            },
            {
              path: 'stock',
              alias: 'adjustment',
              name: 'warehouseStock',
              component: () => import('@/views/warehouse/WarehouseManagementView.vue'),
            },
            {
              path: 'logs',
              name: 'warehouseLogs',
              component: () => import('@/views/warehouse/WarehouseLogView.vue'),
            },
            {
              path: 'incoming-orders',
              name: 'warehouseIncomingOrders',
              component: () => import('@/views/warehouse/IncomingOrdersView.vue'),
            },
            {
              path: 'sales-transfers',
              name: 'warehouseSalesTransfers',
              component: () => import('@/views/warehouse/SalesTransferView.vue'),
            }
          ]
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
