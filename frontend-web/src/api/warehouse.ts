import apiClient from './axios'

export const warehouseApi = {
  getInventory: (branchId?: string | null) => apiClient.get('/warehouse/stock', { params: { branch_id: branchId } }),
  getLogs: (branchId?: string | null) => apiClient.get('/warehouse/logs', { params: { branch_id: branchId } }),
  getPendingShipments: (branchId?: string | null) => apiClient.get('/warehouse/transfers/pending', { params: { branch_id: branchId } }),
  receiveShipment: (id: string) => apiClient.post(`/warehouse/transfers/${id}/receive`),
  approveShipment: (id: string) => apiClient.post(`/warehouse/transfers/${id}/approve`),
  rejectShipment: (id: string) => apiClient.post(`/warehouse/transfers/${id}/reject`),
  setStockLimit: (data: any) => apiClient.post('/warehouse/stock-limit', data),
  adjustStock: (data: any) => apiClient.post('/warehouse/adjust', data),
  getByDO: (doNo: string) => apiClient.get(`/warehouse/transfers/do/${doNo}`),
  receiveByDO: (doNo: string) => apiClient.post(`/warehouse/transfers/do/${doNo}/receive`),
  requestGoods: (factoryId: string, data: any) => apiClient.post(`/factory/${factoryId}/transfer/request`, data),
}
