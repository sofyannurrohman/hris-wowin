import { defineStore } from 'pinia'
import apiClient from '@/api/axios'

export type SOStatus = 'DRAFT' | 'CONFIRMED' | 'IN_DELIVERY' | 'DELIVERED' | 'PAID' | 'WAITING_WAREHOUSE' | 'WAITING_STOCK' | 'PROCESSING' | 'SHIPPED' | 'CONVERTED' | 'CANCELLED' | 'REJECTED'

export interface SOItem {
  id: string
  sales_order_id: string
  product_id: string
  quantity: number
  ordered_quantity: number
  unit: string
  pieces_per_unit: number
  reserved_quantity: number
  actual_quantity: number
  price: number
  subtotal: number
  product?: {
    id: string
    name: string
    sku: string
    unit: string
  }
  batches?: {
    id: string
    sales_order_item_id: string
    batch_no: string
    quantity: number
  }[]
}

export interface SalesOrder {
  id: string
  so_number: string
  delivery_order_no?: string
  shipped_at?: string
  pod_image_url?: string
  received_at?: string
  received_by?: string
  payment_collected_amount?: number
  payment_method?: string
  branch_id: string
  company_id: string
  employee_id: string
  store_id: string
  store_category: string
  status: SOStatus
  total_amount: number
  notes: string
  invoice_id?: string
  confirmed_at?: string
  converted_at?: string
  rejected_at?: string
  reject_notes?: string
  order_date: string
  created_at: string
  items: SOItem[]
  employee?: { first_name: string; last_name: string }
  store?: { name: string; address: string }
  confirmed_by?: { first_name: string; last_name: string }
}


export const useSalesOrderStore = defineStore('salesOrder', {
  state: () => ({
    orders: [] as SalesOrder[],
    currentOrder: null as SalesOrder | null,
    loading: false,
    error: null as string | null,
  }),

  getters: {
    draftOrders: (state) => state.orders.filter(o => o.status === 'DRAFT'),
    waitingWarehouseOrders: (state) => state.orders.filter(o => o.status === 'WAITING_WAREHOUSE'),
    shippedOrders: (state) => state.orders.filter(o => o.status === 'SHIPPED'),
    convertedOrders: (state) => state.orders.filter(o => o.status === 'CONVERTED'),
  },

  actions: {
    async fetchByBranch(branchID: string, status = 'ALL') {
      this.loading = true
      try {
        const res = await apiClient.get(`/admin/sales-orders?branch_id=${branchID}&status=${status}`)
        this.orders = res.data.data || []
      } catch (err: any) {
        this.error = err.response?.data?.error || 'Gagal memuat pesanan'
      } finally {
        this.loading = false
      }
    },

    async fetchByID(id: string) {
      const res = await apiClient.get(`/admin/sales-orders/${id}`)
      this.currentOrder = res.data.data
      return this.currentOrder
    },

    async createSO(data: any): Promise<SalesOrder> {
      const res = await apiClient.post('/admin/sales-orders/manual', data)
      await this.fetchByBranch(data.branch_id)
      return res.data.data
    },

    async confirmSO(id: string): Promise<void> {
      await apiClient.patch(`/admin/sales-orders/${id}/confirm`)
      await this._refreshOrder(id)
    },

    /** Admin Nota: Verifikasi nota dari salesman → SO status CONFIRMED */
    async adminConfirmSO(id: string): Promise<void> {
      await apiClient.patch(`/admin/sales-orders/${id}/admin-confirm`)
      await this._refreshOrder(id)
    },

    /** Admin Nota: Tolak nota dari salesman */
    async adminRejectSO(id: string, notes: string): Promise<void> {
      await apiClient.patch(`/admin/sales-orders/${id}/admin-reject`, { notes })
      await this._refreshOrder(id)
    },

    async processByWarehouse(id: string, items: any[]): Promise<void> {
      await apiClient.patch(`/admin/sales-orders/${id}/process-warehouse`, { 
        so_id: id,
        items 
      })
      await this._refreshOrder(id)
    },

    async confirmPOD(id: string, data: { received_by: string; pod_image_url?: string }): Promise<void> {
      await apiClient.patch(`/admin/sales-orders/${id}/confirm-pod`, {
        so_id: id,
        ...data
      })
      await this._refreshOrder(id)
    },

    async rejectSO(id: string, notes: string): Promise<void> {
      await apiClient.patch(`/admin/sales-orders/${id}/reject`, { notes })
      await this._refreshOrder(id)
    },


    async cancelSO(id: string): Promise<void> {
      await apiClient.patch(`/admin/sales-orders/${id}/cancel`)
      await this._refreshOrder(id)
    },

    async convertToInvoice(id: string, companyID: string): Promise<any> {
      const res = await apiClient.post(`/admin/sales-orders/${id}/convert`, { company_id: companyID })
      await this._refreshOrder(id)
      return res.data.data
    },

    async deleteSO(id: string, branchID: string): Promise<void> {
      await apiClient.delete(`/admin/sales-orders/${id}`)
      await this.fetchByBranch(branchID)
    },

    async overrideBackorder(id: string): Promise<void> {
      await apiClient.patch(`/admin/sales-orders/${id}/override-backorder`)
      await this._refreshOrder(id)
    },

    async _refreshOrder(id: string) {
      try {
        const res = await apiClient.get(`/admin/sales-orders/${id}`)
        const updated = res.data.data as SalesOrder
        const idx = this.orders.findIndex(o => o.id === id)
        if (idx !== -1) this.orders[idx] = updated
        this.currentOrder = updated
      } catch {}
    }
  }
})
