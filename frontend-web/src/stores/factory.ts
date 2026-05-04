import { defineStore } from 'pinia'
import { factoryApi } from '@/api/factory'

export interface Factory {
  id: string
  company_id: string
  branch_id: string
  name: string
  location: string
  branch?: {
    id: string
    name: string
  }
}

export interface Product {
  id: string
  company_id: string
  name: string
  sku: string
  unit: string
  weight: number
  description: string
}

export interface FactoryStock {
  id: string
  factory_id: string
  product_id: string
  quantity: number
  updated_at: string
  product?: Product
}

export interface ProductionLog {
  id: string
  factory_id: string
  product_id: string
  employee_id: string
  quantity: number
  production_date: string
  notes: string
  product?: Product
  employee?: {
    first_name: string
    last_name: string
  }
}

export interface ProductTransfer {
  id: string
  from_factory_id: string
  to_branch_id: string
  product_id: string
  quantity: number
  total_weight: number
  status: string
  notes: string
  created_at: string
  product?: Product
  to_branch?: {
    name: string
  }
}

export const useFactoryStore = defineStore('factory', {
  state: () => ({
    factories: [] as Factory[],
    products: [] as Product[],
    currentFactory: null as Factory | null,
    inventory: [] as FactoryStock[],
    inventoryLogs: [] as any[],
    productionHistory: [] as ProductionLog[],
    transferHistory: [] as ProductTransfer[],
    loading: false,
    error: null as string | null,
  }),

  actions: {
    async fetchFactories() {
      this.loading = true
      try {
        const response = await factoryApi.getFactories()
        this.factories = response.data
      } catch (err: any) {
        this.error = err.response?.data?.error || 'Failed to fetch factories'
      } finally {
        this.loading = false
      }
    },

    async fetchProducts() {
      try {
        const response = await factoryApi.getProducts()
        this.products = response.data
      } catch (err: any) {
        this.error = err.response?.data?.error || 'Failed to fetch products'
      }
    },

    async fetchFactoryDetail(id: string) {
      this.loading = true
      try {
        const response = await factoryApi.getFactory(id)
        this.currentFactory = response.data
      } catch (err: any) {
        this.error = err.response?.data?.error || 'Failed to fetch factory detail'
      } finally {
        this.loading = false
      }
    },

    async fetchInventory(factoryId: string) {
      try {
        const response = await factoryApi.getInventory(factoryId)
        this.inventory = response.data
      } catch (err: any) {
        this.error = err.response?.data?.error || 'Failed to fetch inventory'
      }
    },

    async fetchProductionHistory(factoryId: string) {
      try {
        const response = await factoryApi.getProductionHistory(factoryId)
        this.productionHistory = response.data
      } catch (err: any) {
        this.error = err.response?.data?.error || 'Failed to fetch production history'
      }
    },

    async fetchTransferHistory(factoryId: string) {
      try {
        const response = await factoryApi.getTransferHistory(factoryId)
        this.transferHistory = response.data
      } catch (err: any) {
        this.error = err.response?.data?.error || 'Failed to fetch transfer history'
      }
    },

    async logProduction(factoryId: string, data: any) {
      try {
        await factoryApi.logProduction(factoryId, data)
        await this.fetchInventory(factoryId)
        await this.fetchProductionHistory(factoryId)
      } catch (err: any) {
        throw err.response?.data?.error || 'Failed to log production'
      }
    },

    async sendToBranch(factoryId: string, data: any) {
      try {
        await factoryApi.sendToBranch(factoryId, data)
        await this.fetchInventory(factoryId)
        await this.fetchTransferHistory(factoryId)
      } catch (err: any) {
        throw err.response?.data?.error || 'Failed to initiate transfer'
      }
    }
  }
})
