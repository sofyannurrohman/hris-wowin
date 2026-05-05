import apiClient from './axios'

export const factoryApi = {
  // Factories
  getFactories: () => apiClient.get('/factory'),
  createFactory: (data: any) => apiClient.post('/factory', data),
  getFactory: (id: string) => apiClient.get(`/factory/${id}`),
  updateFactory: (id: string, data: any) => apiClient.put(`/factory/${id}`, data),
  deleteFactory: (id: string) => apiClient.delete(`/factory/${id}`),

  // Products
  getProducts: () => apiClient.get('/factory/products'),
  createProduct: (data: any) => apiClient.post('/factory/products', data),
  updateProduct: (id: string, data: any) => apiClient.put(`/factory/products/${id}`, data),
  deleteProduct: (id: string) => apiClient.delete(`/factory/products/${id}`),

  // Inventory
  getInventory: (factoryId: string) => apiClient.get(`/factory/${factoryId}/inventory`),
  getAllInventory: () => apiClient.get('/factory/stock/inventory'),
  getInventoryLogs: (factoryId: string) => apiClient.get(`/factory/${factoryId}/inventory/logs`),
  adjustStock: (factoryId: string, data: any) => apiClient.post(`/factory/${factoryId}/inventory/adjust`, data),

  // Production
  logProduction: (factoryId: string, data: any) => apiClient.post(`/factory/${factoryId}/production`, data),
  getProductionHistory: (factoryId: string) => apiClient.get(`/factory/${factoryId}/production`),
  getAllProductionHistory: () => apiClient.get('/factory/stock/production'),
  updateProductionLog: (id: string, data: any) => apiClient.put(`/factory/production/${id}`, data),
  deleteProductionLog: (id: string) => apiClient.delete(`/factory/production/${id}`),

  // Transfers
  sendToBranch: (factoryId: string, data: any) => apiClient.post(`/factory/${factoryId}/transfer`, data),
  getTransferHistory: (factoryId: string) => apiClient.get(`/factory/${factoryId}/transfer`),
  getAllTransfers: () => apiClient.get('/factory/stock/transfers'),
}
