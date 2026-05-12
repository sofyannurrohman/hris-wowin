import apiClient from './axios'

export const warehouseApi = {
  getInventory: (branchId?: string | null) => apiClient.get('/warehouse/stock', { params: { branch_id: branchId } }),
  getLogs: (branchId?: string | null) => apiClient.get('/warehouse/logs', { params: { branch_id: branchId } }),
  getPendingShipments: (branchId?: string | null) => apiClient.get('/warehouse/transfers/pending', { params: { branch_id: branchId } }),
  getAllTransfers: (branchId?: string | null) => apiClient.get('/warehouse/transfers/all', { params: { branch_id: branchId } }),
  receiveShipment: (id: string, data: any) => apiClient.post(`/warehouse/transfers/${id}/receive`, data),
  arriveShipment: (id: string) => apiClient.post(`/warehouse/transfers/${id}/arrive`),
  approveShipment: (id: string) => apiClient.post(`/warehouse/transfers/${id}/approve`),
  rejectShipment: (id: string, reason: string) => apiClient.post(`/warehouse/transfers/${id}/reject`, { rejection_reason: reason }),
  confirmShipment: (id: string) => apiClient.post(`/warehouse/transfers/${id}/confirm-shipment`),
  setStockLimit: (data: any) => apiClient.post('/warehouse/stock-limit', data),
  adjustStock: (data: any) => apiClient.post('/warehouse/adjust', data),
  getByDO: (doNo: string) => apiClient.get(`/warehouse/transfers/do/${doNo}`),
  receiveByDO: (doNo: string, data: any) => apiClient.post(`/warehouse/transfers/do/${doNo}/receive`, data),
  requestGoods: (factoryId: string, data: any) => apiClient.post(`/factory/${factoryId}/transfer/request`, data),
}
