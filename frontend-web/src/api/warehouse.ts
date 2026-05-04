import axios from 'axios'

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080/api/v1'

export const warehouseApi = {
  getInventory: (branchId?: string | null) => axios.get(`${API_URL}/warehouse/stock`, { params: { branch_id: branchId } }),
  getLogs: (branchId?: string | null) => axios.get(`${API_URL}/warehouse/logs`, { params: { branch_id: branchId } }),
  getPendingShipments: (branchId?: string | null) => axios.get(`${API_URL}/warehouse/transfers/pending`, { params: { branch_id: branchId } }),
  receiveShipment: (id: string) => axios.post(`${API_URL}/warehouse/transfers/${id}/receive`),
  approveShipment: (id: string) => axios.post(`${API_URL}/warehouse/transfers/${id}/approve`),
  rejectShipment: (id: string) => axios.post(`${API_URL}/warehouse/transfers/${id}/reject`),
  setStockLimit: (data: any) => axios.post(`${API_URL}/warehouse/stock-limit`, data),
  adjustStock: (data: any) => axios.post(`${API_URL}/warehouse/adjust`, data),
}
