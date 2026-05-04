import axios from 'axios'

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080/api/v1'

export const factoryApi = {
  // Factories
  getFactories: () => axios.get(`${API_URL}/factory`),
  createFactory: (data: any) => axios.post(`${API_URL}/factory`, data),
  getFactory: (id: string) => axios.get(`${API_URL}/factory/${id}`),
  updateFactory: (id: string, data: any) => axios.put(`${API_URL}/factory/${id}`, data),
  deleteFactory: (id: string) => axios.delete(`${API_URL}/factory/${id}`),

  // Products
  getProducts: () => axios.get(`${API_URL}/factory/products`),
  createProduct: (data: any) => axios.post(`${API_URL}/factory/products`, data),
  updateProduct: (id: string, data: any) => axios.put(`${API_URL}/factory/products/${id}`, data),
  deleteProduct: (id: string) => axios.delete(`${API_URL}/factory/products/${id}`),

  // Inventory
  getInventory: (factoryId: string) => axios.get(`${API_URL}/factory/${factoryId}/inventory`),
  getInventoryLogs: (factoryId: string) => axios.get(`${API_URL}/factory/${factoryId}/inventory/logs`),

  // Production
  logProduction: (factoryId: string, data: any) => axios.post(`${API_URL}/factory/${factoryId}/production`, data),
  getProductionHistory: (factoryId: string) => axios.get(`${API_URL}/factory/${factoryId}/production`),

  // Transfers
  sendToBranch: (factoryId: string, data: any) => axios.post(`${API_URL}/factory/${factoryId}/transfer`, data),
  getTransferHistory: (factoryId: string) => axios.get(`${API_URL}/factory/${factoryId}/transfer`),
}
