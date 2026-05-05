import apiClient from './axios'

export const vehicleApi = {
  getVehicles: () => apiClient.get('/vehicles'),
  getVehicle: (id: string) => apiClient.get(`/vehicles/${id}`),
  createVehicle: (data: any) => apiClient.post('/vehicles', data),
  updateVehicle: (id: string, data: any) => apiClient.put(`/vehicles/${id}`, data),
  deleteVehicle: (id: string) => apiClient.delete(`/vehicles/${id}`),
}
