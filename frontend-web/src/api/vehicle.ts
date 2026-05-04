import axios from 'axios'

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080/api/v1'

export const vehicleApi = {
  getVehicles: () => axios.get(`${API_URL}/vehicles`),
  getVehicle: (id: string) => axios.get(`${API_URL}/vehicles/${id}`),
  createVehicle: (data: any) => axios.post(`${API_URL}/vehicles`, data),
  updateVehicle: (id: string, data: any) => axios.put(`${API_URL}/vehicles/${id}`, data),
  deleteVehicle: (id: string) => axios.delete(`${API_URL}/vehicles/${id}`),
}
