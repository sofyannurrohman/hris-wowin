import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import apiClient from '@/api/axios'

export const useAuthStore = defineStore('auth', () => {
  const token = ref(localStorage.getItem('token') || '')
  const user = ref(JSON.parse(localStorage.getItem('user') || 'null'))

  const isAuthenticated = computed(() => !!token.value)

  const isAuthorized = computed(() => {
    const roles = ['superadmin', 'admin', 'HR']
    return user.value && roles.includes(user.value.role)
  })

  async function login(credentials: any) {
    try {
      // Assuming backend route: POST /auth/login
      const response = await apiClient.post('/login', credentials)
      token.value = response.data.data.token
      user.value = response.data.data.user
      localStorage.setItem('token', token.value)
      localStorage.setItem('user', JSON.stringify(user.value))
      return true
    } catch (error) {
      console.error('Login failed', error)
      return false
    }
  }

  function logout() {
    token.value = ''
    user.value = null
    localStorage.removeItem('token')
    localStorage.removeItem('user')
  }

  return { token, user, isAuthenticated, isAuthorized, login, logout }
})
