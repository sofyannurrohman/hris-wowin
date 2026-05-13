import { defineStore } from 'pinia'
import apiClient from '../api/axios'

export const useDeliveryStore = defineStore('delivery', {
  state: () => ({
    batches: [] as any[],
    // Antrean nota yang sudah diverifikasi Admin Nota, siap dibatch oleh Supervisor
    confirmedOrders: [] as any[],
    // Legacy: pending transactions (dipertahankan agar tidak break kode lama)
    pendingOrders: [] as any[],
    loading: false
  }),
  actions: {
    /** Ambil SO yang sudah diverifikasi Admin Nota (status: CONFIRMED) */
    async fetchConfirmedOrders(branchId: string = '') {
      this.loading = true
      try {
        const url = branchId
          ? `/admin/sales-orders?branch_id=${branchId}&status=CONFIRMED`
          : `/admin/sales-orders?status=CONFIRMED`
        const response = await apiClient.get(url)
        this.confirmedOrders = response.data?.data || []
        // Sync ke pendingOrders agar kode lama yang masih pakai pendingOrders tidak break
        this.pendingOrders = this.confirmedOrders
      } finally {
        this.loading = false
      }
    },
    /** Legacy: dipertahankan agar kode lama tidak break */
    async fetchPendingOrders(companyId: string = '') {
      return this.fetchConfirmedOrders()
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
