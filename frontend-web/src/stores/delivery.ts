import { defineStore } from 'pinia'
import apiClient from '../api/axios'

export const useDeliveryStore = defineStore('delivery', {
  state: () => ({
    batches: [] as any[],
    pendingOrders: [] as any[],
    loading: false
  }),
  actions: {
    async fetchPendingOrders(companyId: string) {
      this.loading = true
      try {
        // We might need a specific endpoint for validated TOs
        const response = await apiClient.get(`/sales/transactions?status=VERIFIED&company_id=${companyId}`)
        this.pendingOrders = response.data
      } finally {
        this.loading = false
      }
    },
    async createBatch(data: any) {
      const response = await apiClient.post('/delivery/batch', data)
      return response.data
    },
    async fetchBatches() {
      // For simplicity, fetch all batches
      const response = await apiClient.get('/delivery/tasks') // Note: this might need adjustment for admin view
      this.batches = response.data
    }
  }
})
