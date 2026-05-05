import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import apiClient from '@/api/axios'

export const useMasterDataStore = defineStore('masterData', () => {
  const branches = ref<any[]>([])
  const departments = ref<any[]>([])
  const jobPositions = ref<any[]>([])
  const leaveTypes = ref<any[]>([])
  const employees = ref<any[]>([])
  const selectedBranchId = ref<string | null>(localStorage.getItem('selectedBranchId'))
  
  const isBranchesLoading = ref(false)
  const isDepartmentsLoading = ref(false)
  const isJobPositionsLoading = ref(false)
  const isLeaveTypesLoading = ref(false)
  const isEmployeesLoading = ref(false)
  
  const selectedBranchCompanyId = computed(() => {
    const branch = branches.value.find(b => b.id === selectedBranchId.value)
    return branch?.company_id || ''
  })

  function setSelectedBranchId(id: string | null) {
    selectedBranchId.value = id
    if (id) {
      localStorage.setItem('selectedBranchId', id)
    } else {
      localStorage.removeItem('selectedBranchId')
    }
  }

  async function fetchBranches(force = false) {
    if (branches.value.length > 0 && !force) return
    isBranchesLoading.value = true
    try {
      const res = await apiClient.get('/branches')
      branches.value = res.data.data || []
      
      // If no branch is selected and we have branches, select the first one
      if (!selectedBranchId.value && branches.value.length > 0) {
        setSelectedBranchId(branches.value[0].id)
      }
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
      const res = await apiClient.get('/employees?limit=1000')
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
    selectedBranchId,
    isBranchesLoading,
    isDepartmentsLoading,
    isJobPositionsLoading,
    isLeaveTypesLoading,
    isEmployeesLoading,
    fetchBranches,
    fetchDepartments,
    fetchJobPositions,
    fetchLeaveTypes,
    fetchEmployees,
    setSelectedBranchId,
    selectedBranchCompanyId
  }
})
