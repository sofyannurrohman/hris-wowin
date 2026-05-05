import { defineStore } from 'pinia'
import { vehicleApi } from '@/api/vehicle'

export interface Vehicle {
  id: string
  company_id: string
  branch_id?: string
  name: string
  license_plate: string
  model: string
  type: string
  status: 'AVAILABLE' | 'IN_USE' | 'MAINTENANCE' | 'BROKEN'
  year: number
  mileage: number
  capacity: number
  image_url?: string
  branch?: {
    id: string
    name: string
  }
}

export const useVehicleStore = defineStore('vehicle', {
  state: () => ({
    vehicles: [] as Vehicle[],
    logs: [] as any[],
    loading: false,
    error: null as string | null,
  }),

  actions: {
    async fetchVehicles() {
      this.loading = true
      try {
        const response = await vehicleApi.getVehicles()
        this.vehicles = response.data
      } catch (err: any) {
        this.error = err.response?.data?.error || 'Failed to fetch vehicles'
      } finally {
        this.loading = false
      }
    },

    async addVehicle(data: FormData) {
      try {
        await vehicleApi.createVehicle(data)
        await this.fetchVehicles()
      } catch (err: any) {
        throw err.response?.data?.error || 'Failed to add vehicle'
      }
    },

    async updateVehicle(id: string, data: FormData) {
      try {
        await vehicleApi.updateVehicle(id, data)
        await this.fetchVehicles()
      } catch (err: any) {
        throw err.response?.data?.error || 'Failed to update vehicle'
      }
    },

    async removeVehicle(id: string) {
      try {
        await vehicleApi.deleteVehicle(id)
        await this.fetchVehicles()
      } catch (err: any) {
        throw err.response?.data?.error || 'Failed to delete vehicle'
      }
    },

    async fetchVehicleLogs(id: string) {
      try {
        const response = await vehicleApi.getVehicleLogs(id)
        this.logs = response.data
      } catch (err: any) {
        console.error('Failed to fetch vehicle logs:', err)
      }
    }
  }
})
