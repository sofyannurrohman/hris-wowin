import axios from 'axios'

const apiClient = axios.create({
  // This combines your .env variable (http://localhost:8081/api) with /v1
  // Result: http://localhost:8081/api/v1
  baseURL: `${import.meta.env.VITE_API_BASE_URL}/v1`,
  headers: {
    'Content-Type': 'application/json'
  }
})

apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

export default apiClient