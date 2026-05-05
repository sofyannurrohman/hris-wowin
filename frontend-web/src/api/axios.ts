import axios from 'axios'

const apiClient = axios.create({
  // This combines your .env variable (http://localhost:8081/api) with /v1
  // Result: http://localhost:8081/api/v1
  baseURL: `${import.meta.env.VITE_API_BASE_URL}/v1`
})

let activeRequests = 0

const updateLoadingBar = () => {
  const bar = document.getElementById('loading-bar')
  if (!bar) return

  if (activeRequests > 0) {
    bar.classList.remove('done')
    bar.classList.add('loading')
  } else {
    bar.classList.remove('loading')
    bar.classList.add('done')
    setTimeout(() => {
      if (activeRequests === 0) bar.classList.remove('done')
    }, 500)
  }
}

apiClient.interceptors.request.use((config) => {
  const token = localStorage.getItem('token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  activeRequests++
  updateLoadingBar()
  return config
})

apiClient.interceptors.response.use(
  (response) => {
    activeRequests--
    updateLoadingBar()
    return response
  },
  (error) => {
    activeRequests--
    updateLoadingBar()

    // Handle 401 Unauthorized - Token expired or invalid
    if (error.response && error.response.status === 401) {
      const isLoginPage = window.location.pathname.includes('/login')
      
      if (!isLoginPage) {
        localStorage.removeItem('token')
        localStorage.removeItem('user')
        window.location.href = '/login?session=expired'
      }
    }

    return Promise.reject(error)
  }
)

export default apiClient