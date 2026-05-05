import { defineStore } from 'pinia'
import axios from 'axios'
import { useMasterDataStore } from './masterData'

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080/api/v1'

export interface SalesStock {
  id: string
  employee_id: string
  product_id: string
  quantity: number
  updated_at: string
  product?: {
    name: string
    unit: string
    sku: string
  }
}

export interface SalesTransfer {
  id: string
  branch_id: string
  employee_id: string
  product_id: string
  quantity: number
  type: 'TRANSFER' | 'RETURN'
  status: 'PENDING' | 'COMPLETED' | 'CANCELLED'
  notes: string
  transfer_date: string
  employee?: {
    name: string
  }
  product?: {
    name: string
    unit: string
  }
}

export const useSalesTransferStore = defineStore('salesTransfer', {
  state: () => ({
    transfers: [] as SalesTransfer[],
    salesStock: [] as SalesStock[],
    loading: false,
    error: null as string | null,
  }),

  actions: {
    async fetchTransfers() {
      const masterDataStore = useMasterDataStore()
      this.loading = true
      try {
        const response = await axios.get(`${API_URL}/sales-transfers/branch/${masterDataStore.selectedBranchId}`)
        this.transfers = response.data.data
      } catch (err: any) {
        this.error = err.response?.data?.error || 'Failed to fetch transfers'
      } finally {
        this.loading = false
      }
    },

    async fetchSalesStock(employeeId: string) {
      try {
        const response = await axios.get(`${API_URL}/sales-transfers/stock/${employeeId}`)
        this.salesStock = response.data.data
      } catch (err: any) {
        this.error = err.response?.data?.error || 'Failed to fetch sales stock'
      }
    },

    async createTransfer(data: any) {
      const masterDataStore = useMasterDataStore()
      try {
        await axios.post(`${API_URL}/sales-transfers/branch/${masterDataStore.selectedBranchId}`, data)
        await this.fetchTransfers()
      } catch (err: any) {
        throw err.response?.data?.error || 'Failed to create transfer'
      }
    },

    async completeTransfer(id: string) {
      try {
        await axios.patch(`${API_URL}/sales-transfers/${id}/complete`)
        await this.fetchTransfers()
      } catch (err: any) {
        throw err.response?.data?.error || 'Failed to complete transfer'
      }
    },

    async cancelTransfer(id: string) {
      try {
        await axios.patch(`${API_URL}/sales-transfers/${id}/cancel`)
        await this.fetchTransfers()
      } catch (err: any) {
        throw err.response?.data?.error || 'Failed to cancel transfer'
      }
    },

    async deleteTransfer(id: string) {
      try {
        await axios.delete(`${API_URL}/sales-transfers/${id}`)
        await this.fetchTransfers()
      } catch (err: any) {
        throw err.response?.data?.error || 'Failed to delete transfer'
      }
    }
  }
})
