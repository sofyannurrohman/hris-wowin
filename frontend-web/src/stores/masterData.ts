import { defineStore } from 'pinia'
import { ref } from 'vue'
import apiClient from '@/api/axios'

export const useMasterDataStore = defineStore('masterData', () => {
  const branches = ref<any[]>([])
  const departments = ref<any[]>([])
  const jobPositions = ref<any[]>([])
  const leaveTypes = ref<any[]>([])
  const employees = ref<any[]>([])
  
  const isBranchesLoading = ref(false)
  const isDepartmentsLoading = ref(false)
  const isJobPositionsLoading = ref(false)
  const isLeaveTypesLoading = ref(false)
  const isEmployeesLoading = ref(false)

  async function fetchBranches(force = false) {
    if (branches.value.length > 0 && !force) return
    isBranchesLoading.value = true
    try {
      const res = await apiClient.get('/branches')
      branches.value = res.data.data || []
    } finally {
      isBranchesLoading.value = false
    }
  }

  async function fetchDepartments(force = false) {
    if (departments.value.length > 0 && !force) return
    isDepartmentsLoading.value = true
    try {
      const res = await apiClient.get('/departments')
      departments.value = res.data.data || []
    } finally {
      isDepartmentsLoading.value = false
    }
  }

  async function fetchJobPositions(force = false) {
    if (jobPositions.value.length > 0 && !force) return
    isJobPositionsLoading.value = true
    try {
      const res = await apiClient.get('/job-positions')
      jobPositions.value = res.data.data || []
    } finally {
      isJobPositionsLoading.value = false
    }
  }

  async function fetchLeaveTypes(force = false) {
    if (leaveTypes.value.length > 0 && !force) return
    isLeaveTypesLoading.value = true
    try {
      const res = await apiClient.get('/leave-types')
      leaveTypes.value = res.data.data || []
    } finally {
      isLeaveTypesLoading.value = false
    }
  }

  async function fetchEmployees(force = false) {
    if (employees.value.length > 0 && !force) return
    isEmployeesLoading.value = true
    try {
      const res = await apiClient.get('/employees?limit=200')
      employees.value = res.data.data || []
    } finally {
      isEmployeesLoading.value = false
    }
  }

  return {
    branches,
    departments,
    jobPositions,
    leaveTypes,
    employees,
    isBranchesLoading,
    isDepartmentsLoading,
    isJobPositionsLoading,
    isLeaveTypesLoading,
    isEmployeesLoading,
    fetchBranches,
    fetchDepartments,
    fetchJobPositions,
    fetchLeaveTypes,
    fetchEmployees
  }
})
