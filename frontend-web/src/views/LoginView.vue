<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import logo from '@/assets/logo.svg'

const email = ref("sofyan@sentraweb.id")
const password = ref("password123")
const errorMsg = ref('')
const isLoading = ref(false)

const router = useRouter()
const authStore = useAuthStore()

const handleLogin = async () => {
  isLoading.value = true
  errorMsg.value = ''
  
  const success = await authStore.login({ email: email.value, password: password.value })
  if (success) {
    router.push('/')
  } else {
    errorMsg.value = 'Email atau password salah'
  }
  
  isLoading.value = false
}

</script>

<template>
  <div class="h-screen bg-gray-50 flex items-center justify-center p-4">
    <div class="max-w-md w-full bg-white rounded-3xl border border-gray-100 shadow-xl p-8">
      <div class="text-center mb-8">
        <div class="w-16 h-16 bg-gradient-to-br from-cyan-400 to-cyan-white rounded-2xl mx-auto mb-4 flex items-center justify-center text-white text-3xl shadow-lg shadow-emerald-500/30">
          <img :src="logo" alt="Logo" class="w-12 h-12" />
        </div>
        <h1 class="text-2xl font-bold tracking-tight text-gray-900">SENTRAWEB Login</h1>
        <p class="text-gray-500 mt-2 text-sm">Masuk untuk mengakses dasbor manjemen HRIS</p>
      </div>
      
      <form @submit.prevent="handleLogin" class="space-y-5">
        <div v-if="errorMsg" class="p-3 bg-red-50 text-red-600 rounded-xl text-sm font-medium text-center">
          {{ errorMsg }}
        </div>
        
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Email</label>
          <input 
            v-model="email"
            type="text" 
            placeholder="admin@wowin.com"
            class="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-emerald-500 focus:ring-2 focus:ring-emerald-200 outline-none transition-all"
            required
          />
        </div>
        
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Password</label>
          <input 
            v-model="password" 
            type="password" 
            placeholder="••••••••"
            class="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-emerald-500 focus:ring-2 focus:ring-emerald-200 outline-none transition-all"
            required
          />
        </div>
        
        <button 
          type="submit" 
          :disabled="isLoading"
          class="w-full py-3 px-4 bg-teal-600 hover:bg-teal-500 text-white font-bold rounded-xl shadow-lg shadow-gray-900/20 transition-all disabled:opacity-70 flex items-center justify-center"
        >
          <span v-if="isLoading" class="animate-pulse">Memuat...</span>
          <span v-else>Masuk</span>
        </button>
      </form>
    </div>
  </div>
</template>
