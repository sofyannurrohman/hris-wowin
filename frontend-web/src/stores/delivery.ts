import { defineStore } from 'pinia'
import axios from 'axios'

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080/api/v1'

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
        const response = await axios.get(`${API_URL}/sales/transactions?status=VERIFIED&company_id=${companyId}`)
        this.pendingOrders = response.data
      } finally {
        this.loading = false
      }
    },
    async createBatch(data: any) {
      const response = await axios.post(`${API_URL}/delivery/batch`, data)
      return response.data
    },
    async fetchBatches() {
      // For simplicity, fetch all batches
      const response = await axios.get(`${API_URL}/delivery/tasks`) // Note: this might need adjustment for admin view
      this.batches = response.data
    }
  }
})
