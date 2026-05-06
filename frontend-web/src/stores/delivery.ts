import { defineStore } from 'pinia'
import apiClient from '../api/axios'

export const useDeliveryStore = defineStore('delivery', {
  state: () => ({
    batches: [] as any[],
    pendingOrders: [] as any[],
    loading: false
  }),
  actions: {
    async fetchPendingOrders(companyId: string = '') {
      this.loading = true
      try {
        const url = companyId 
          ? `/admin/sales/delivery-pending?status=VERIFIED&company_id=${companyId}`
          : `/admin/sales/delivery-pending?status=VERIFIED`
        const response = await apiClient.get(url)
        this.pendingOrders = response.data?.data || []
      } finally {
        this.loading = false
      }
    },
    async createBatch(data: any) {
      const response = await apiClient.post('/delivery/batch', data)
      return response.data
    },
    async fetchBatches() {
      const response = await apiClient.get('/delivery/batches')
      this.batches = response.data?.data || []
    }
  }
})
