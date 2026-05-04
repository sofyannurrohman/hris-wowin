import { defineStore } from 'pinia'
import { warehouseApi } from '@/api/warehouse'
import { useMasterDataStore } from './masterData'

export interface WarehouseStock {
  id: string
  branch_id: string
  product_id: string
  quantity: number
  min_limit: number
  updated_at: string
  product?: {
    id: string
    name: string
    sku: string
    unit: string
    weight: number
  }
}

export interface ProductTransfer {
  id: string
  from_factory_id: string
  to_branch_id: string
  product_id: string
  quantity: number
  total_weight: number
  status: 'REQUESTED' | 'APPROVED' | 'SHIPPED' | 'RECEIVED' | 'REJECTED'
  notes: string
  created_at: string
  product?: {
    name: string
    unit: string
  }
  from_factory?: {
    name: string
  }
}

export const useWarehouseStore = defineStore('warehouse', {
  state: () => ({
    inventory: [] as WarehouseStock[],
    pendingShipments: [] as ProductTransfer[],
    logs: [] as any[],
    loading: false,
    error: null as string | null,
  }),

  actions: {
    async fetchInventory() {
      const masterDataStore = useMasterDataStore()
      this.loading = true
      try {
        const response = await warehouseApi.getInventory(masterDataStore.selectedBranchId)
        this.inventory = response.data
      } catch (err: any) {
        this.error = err.response?.data?.error || 'Failed to fetch inventory'
      } finally {
        this.loading = false
      }
    },

    async fetchPendingShipments() {
      const masterDataStore = useMasterDataStore()
      try {
        const response = await warehouseApi.getPendingShipments(masterDataStore.selectedBranchId)
        this.pendingShipments = response.data
      } catch (err: any) {
        this.error = err.response?.data?.error || 'Failed to fetch shipments'
      }
    },

    async fetchLogs() {
      const masterDataStore = useMasterDataStore()
      try {
        const response = await warehouseApi.getLogs(masterDataStore.selectedBranchId)
        this.logs = response.data
      } catch (err: any) {
        this.error = err.response?.data?.error || 'Failed to fetch logs'
      }
    },

    async receiveShipment(id: string) {
      try {
        await warehouseApi.receiveShipment(id)
        await this.fetchInventory()
        await this.fetchPendingShipments()
      } catch (err: any) {
        throw err.response?.data?.error || 'Failed to receive shipment'
      }
    },

    async approveShipment(id: string) {
      try {
        await warehouseApi.approveShipment(id)
        await this.fetchPendingShipments()
      } catch (err: any) {
        throw err.response?.data?.error || 'Failed to approve shipment'
      }
    },

    async rejectShipment(id: string) {
      try {
        await warehouseApi.rejectShipment(id)
        await this.fetchPendingShipments()
      } catch (err: any) {
        throw err.response?.data?.error || 'Failed to reject shipment'
      }
    },

    async setStockLimit(data: { product_id: string, limit: number }) {
      try {
        await warehouseApi.setStockLimit(data)
        await this.fetchInventory()
      } catch (err: any) {
        throw err.response?.data?.error || 'Failed to set stock limit'
      }
    },

    async adjustStock(data: any) {
      try {
        await warehouseApi.adjustStock(data)
        await this.fetchInventory()
        await this.fetchLogs()
      } catch (err: any) {
        throw err.response?.data?.error || 'Failed to adjust stock'
      }
    }
  }
})
