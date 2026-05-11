import { defineStore } from 'pinia'
import apiClient from '@/api/axios'

export type ReturnStatus = 'PENDING' | 'APPROVED' | 'REJECTED'

export interface SalesReturn {
  id: string
  return_no: string
  sales_order_id: string
  transaction_id?: string
  branch_id: string
  employee_id: string
  status: ReturnStatus
  total_amount: number
  notes: string
  approved_at?: string
  created_at: string
  items: any[]
  employee?: { first_name: string; last_name: string }
  sales_order?: { so_number: string }
}

export const useSalesReturnStore = defineStore('salesReturn', {
  state: () => ({
    returns: [] as SalesReturn[],
    loading: false,
    error: null as string | null
  }),

  actions: {
    async fetchByBranch(branchID: string, status = 'ALL') {
      this.loading = true
      try {
        const res = await apiClient.get(`/admin/sales-returns?branch_id=${branchID}&status=${status}`)
        this.returns = res.data.data || []
      } catch (err: any) {
        this.error = err.response?.data?.error || 'Gagal memuat data retur'
      } finally {
        this.loading = false
      }
    },

    async createReturn(data: any) {
      const res = await apiClient.post('/admin/sales-returns', data)
      return res.data.data
    },

    async approveReturn(id: string) {
      await apiClient.patch(`/admin/sales-returns/${id}/approve`)
      const branchID = this.returns.find(r => r.id === id)?.branch_id
      if (branchID) await this.fetchByBranch(branchID)
    }
  }
})
