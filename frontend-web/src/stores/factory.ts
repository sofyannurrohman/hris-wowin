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
  weight_unit: string
  cost_price: number
  selling_price: number
  category?: string
  brand?: string
  specs?: string
  description: string
  image_url?: string
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
  delivery_order_no?: string
  notes: string
  created_at: string
  product?: Product
  from_factory?: {
    name: string
  }
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
    allInventory: [] as FactoryStock[],
    inventoryLogs: [] as any[],
    productionHistory: [] as ProductionLog[],
    allProductionHistory: [] as ProductionLog[],
    transferHistory: [] as ProductTransfer[],
    allTransfers: [] as ProductTransfer[],
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

    async createFactory(data: any) {
      try {
        await factoryApi.createFactory(data)
        await this.fetchFactories()
      } catch (err: any) {
        throw err.response?.data?.error || 'Failed to create factory'
      }
    },

    async updateFactory(id: string, data: any) {
      try {
        await factoryApi.updateFactory(id, data)
        await this.fetchFactories()
      } catch (err: any) {
        throw err.response?.data?.error || 'Failed to update factory'
      }
    },

    async deleteFactory(id: string) {
      try {
        await factoryApi.deleteFactory(id)
        await this.fetchFactories()
      } catch (err: any) {
        throw err.response?.data?.error || 'Failed to delete factory'
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

    async createProduct(data: any) {
      try {
        await factoryApi.createProduct(data)
        await this.fetchProducts()
      } catch (err: any) {
        throw err.response?.data?.error || 'Failed to create product'
      }
    },

    async updateProduct(id: string, data: any) {
      try {
        await factoryApi.updateProduct(id, data)
        await this.fetchProducts()
      } catch (err: any) {
        throw err.response?.data?.error || 'Failed to update product'
      }
    },

    async deleteProduct(id: string) {
      try {
        await factoryApi.deleteProduct(id)
        await this.fetchProducts()
      } catch (err: any) {
        throw err.response?.data?.error || 'Failed to delete product'
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

    async fetchAllInventory() {
      this.loading = true
      try {
        const response = await factoryApi.getAllInventory()
        this.allInventory = response.data
      } catch (err: any) {
        this.error = err.response?.data?.error || 'Failed to fetch all inventory'
      } finally {
        this.loading = false
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

    async fetchAllProductionHistory() {
      this.loading = true
      try {
        const response = await factoryApi.getAllProductionHistory()
        this.allProductionHistory = response.data
      } catch (err: any) {
        this.error = err.response?.data?.error || 'Failed to fetch all production history'
      } finally {
        this.loading = false
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

    async fetchAllTransfers() {
      this.loading = true
      try {
        const response = await factoryApi.getAllTransfers()
        this.allTransfers = response.data
      } catch (err: any) {
        this.error = err.response?.data?.error || 'Failed to fetch all transfers'
      } finally {
        this.loading = false
      }
    },

    async logProduction(factoryId: string, data: any) {
      try {
        await factoryApi.logProduction(factoryId, data)
        await this.fetchInventory(factoryId)
        await this.fetchProductionHistory(factoryId)
      } catch (err: any) {
        throw err
      }
    },

    async updateProductionLog(factoryId: string, id: string, data: any) {
      try {
        await factoryApi.updateProductionLog(id, data)
        await this.fetchInventory(factoryId)
        await this.fetchProductionHistory(factoryId)
      } catch (err: any) {
        throw err
      }
    },

    async deleteProductionLog(factoryId: string, id: string) {
      try {
        await factoryApi.deleteProductionLog(id)
        await this.fetchInventory(factoryId)
        await this.fetchProductionHistory(factoryId)
      } catch (err: any) {
        throw err
      }
    },

    async adjustStock(factoryId: string, data: any) {
      try {
        await factoryApi.adjustStock(factoryId, data)
        await this.fetchInventory(factoryId)
      } catch (err: any) {
        throw err
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
