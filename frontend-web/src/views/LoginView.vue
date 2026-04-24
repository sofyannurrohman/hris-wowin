<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { LogIn, Mail, Lock, AlertCircle, Loader2, ShieldCheck, ChevronRight } from 'lucide-vue-next'
import logo from '@/assets/logo.svg'
import { toast } from 'vue-sonner'

const email = ref("sofyan@sentraweb.id")
const password = ref("password123")
const errorMsg = ref('')
const isLoading = ref(false)

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()

onMounted(() => {
  if (route.query.session === 'expired') {
    errorMsg.value = 'Sesi Anda telah berakhir. Silakan masuk kembali.'
    toast.error('Sesi Berakhir', {
      description: 'Silakan login ulang untuk melanjutkan.'
    })
  }
})

const handleLogin = async () => {
  isLoading.value = true
  errorMsg.value = ''
  
  try {
    const success = await authStore.login({ email: email.value, password: password.value })
    if (success) {
      router.push('/')
    } else {
      errorMsg.value = 'Email atau sandi yang Anda masukkan tidak sesuai.'
    }
  } catch (err) {
    errorMsg.value = 'Gangguan koneksi sistem. Silakan coba lagi.'
  } finally {
    isLoading.value = false
  }
}

</script>

<template>
  <div class="min-h-screen bg-[#FDFDFD] flex items-center justify-center p-4 sm:p-6 lg:p-8 relative overflow-hidden font-jakarta">
    <!-- Premium Background: Abstract Crimson Flows -->
    <div class="absolute inset-0 z-0 overflow-hidden pointer-events-none">
      <div class="absolute -top-[10%] -left-[10%] w-[50%] h-[50%] bg-primary/5 rounded-full blur-[120px] mix-blend-multiply transition-transform duration-1000 transform hover:scale-110"></div>
      <div class="absolute -bottom-[10%] -right-[10%] w-[40%] h-[50%] bg-primary/3 rounded-full blur-[100px] mix-blend-multiply"></div>
      <div class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-full h-full opacity-[0.02] grayscale select-none">
        <!-- Noise pattern -->
        <svg xmlns='http://www.w3.org/2000/svg' width='100%' height='100%'>
          <filter id='n'><feTurbulence type='fractalNoise' baseFrequency='0.65' numOctaves='3' stitchTiles='stitch'/></filter>
          <rect width='100%' height='100%' filter='url(#n)'/>
        </svg>
      </div>
    </div>

    <div class="w-full max-w-[1100px] grid lg:grid-cols-2 bg-white/40 backdrop-blur-3xl rounded-[40px] border border-white/50 shadow-[0_32px_80px_-20px_rgba(0,0,0,0.1)] overflow-hidden relative z-10 transition-all duration-700">
      
      <!-- Left side: Branding & Hero -->
      <div class="hidden lg:flex flex-col justify-between p-12 bg-gradient-to-br from-primary via-[#B30000] to-primary relative overflow-hidden">
        <!-- Abstract Decoration -->
        <div class="absolute inset-0 opacity-10 pointer-events-none">
          <svg viewBox="0 0 400 400" xmlns="http://www.w3.org/2000/svg" class="w-full h-full">
            <path d="M0,400 Q200,300 400,400 T800,400" fill="none" stroke="white" stroke-width="2"/>
            <circle cx="300" cy="100" r="150" fill="none" stroke="white" stroke-width="1" stroke-dasharray="10 10"/>
          </svg>
        </div>

        <div class="relative z-10">
          <div class="flex items-center gap-3 mb-12">
            <div class="bg-white/10 backdrop-blur-md p-3 rounded-2xl border border-white/20">
              <img :src="logo" alt="Logo" class="w-10 h-10 " />
            </div>
            <div class="flex flex-col">
              <span class="text-2xl font-black text-white tracking-tight leading-none">Single Sign On</span>
              <span class="text-[10px] font-bold text-white/70 uppercase tracking-[0.2em] mt-1">Management Portal PT Wowin Purnomo Putera</span>
            </div>
          </div>
          
          <h2 class="text-5xl font-black text-white leading-[1.1] mb-6">Satu Platform,<br/><span class="text-white/60">Solusi Beragam.</span></h2>
          <p class="text-white/70 text-lg font-medium max-w-sm leading-relaxed">
            Kelola SDM, Rekrutmen, dan Marketing Anda dalam satu platform dan terintegrasi.
          </p>
        </div>

        <div class="relative z-10 mt-12 bg-white/5 backdrop-blur-lg border border-white/10 p-6 rounded-[28px]">
          <div class="flex items-center gap-4">
            <div class="bg-emerald-400/20 p-2.5 rounded-xl">
              <ShieldCheck class="w-6 h-6 text-white" />
            </div>
            <div>
              <p class="text-white font-bold text-sm">Enterprise Security</p>
              <p class="text-white/50 text-[12px]">Data Anda terenkripsi secara end-to-end.</p>
            </div>
          </div>
        </div>
      </div>

      <!-- Right side: Login Form -->
      <div class="p-10 md:p-14 lg:p-16 flex flex-col justify-center bg-white/40">
        <div class="max-w-[400px] mx-auto w-full">
          <div class="lg:hidden flex justify-center mb-10">
             <img :src="logo" alt="Logo" class="w-14 h-14" />
          </div>

          <div class="mb-10 text-center lg:text-left">
            <h1 class="text-3xl font-black tracking-tight text-slate-900 leading-tight">Masuk ke Sistem</h1>
            <p class="text-slate-500 mt-3 text-sm font-medium">Mulai Akses Portal Web Manajemen PT Wowin Purnomo Putera.</p>
          </div>
          
          <form @submit.prevent="handleLogin" class="space-y-6">
            <div v-if="errorMsg" class="p-4 bg-primary/5 border border-primary/10 text-primary rounded-2xl text-[12px] font-bold flex items-center gap-3 animate-bounce-subtle">
              <AlertCircle class="w-4 h-4 shrink-0" />
              {{ errorMsg }}
            </div>
            
            <div class="space-y-2.5">
              <label class="block text-xs font-black text-slate-400 uppercase tracking-widest ml-1">Email</label>
              <div class="relative group">
                <Mail class="absolute left-5 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400 group-focus-within:text-primary transition-colors duration-300" />
                <input 
                  v-model="email"
                  type="email" 
                  placeholder="admin@wowin.id"
                  class="w-full pl-14 pr-4 py-4.5 rounded-2xl border border-slate-200 bg-slate-50/50 font-bold text-slate-910 outline-none transition-all duration-300 focus:bg-white focus:border-primary focus:ring-4 focus:ring-primary/5 placeholder:text-slate-300"
                  required
                />
              </div>
            </div>
            
            <div class="space-y-2.5">
              <div class="flex items-center justify-between ml-1">
                <label class="block text-xs font-black text-slate-400 uppercase tracking-widest">Sandi Akses</label>
                <a href="#" class="text-[11px] font-black text-primary hover:text-[#770000] uppercase tracking-widest transition-colors">Lupa Akses?</a>
              </div>
              <div class="relative group">
                <Lock class="absolute left-5 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400 group-focus-within:text-primary transition-colors duration-300" />
                <input 
                  v-model="password" 
                  type="password" 
                  placeholder="••••••••"
                  class="w-full pl-14 pr-4 py-4.5 rounded-2xl border border-slate-200 bg-slate-50/50 font-bold text-slate-910 outline-none transition-all duration-300 focus:bg-white focus:border-primary focus:ring-4 focus:ring-primary/5 placeholder:text-slate-300"
                  required
                />
              </div>
            </div>
            
            <div class="flex items-center gap-3 ml-1">
              <div class="relative flex items-center">
                <input type="checkbox" id="remember" class="w-5 h-5 rounded-lg border-slate-300 text-primary focus:ring-primary/20 accent-primary cursor-pointer" />
              </div>
              <label for="remember" class="text-sm font-bold text-slate-500 cursor-pointer select-none">Biarkan saya tetap masuk</label>
            </div>
            
            <button 
              type="submit" 
              :disabled="isLoading"
              class="group relative w-full py-5 px-6 bg-slate-900 text-white font-black text-sm rounded-2xl overflow-hidden transition-all duration-500 hover:bg-primary shadow-xl hover:shadow-primary/30 active:scale-[0.98] disabled:opacity-70 disabled:pointer-events-none"
            >
              <div class="relative z-10 flex items-center justify-center gap-2">
                <Loader2 v-if="isLoading" class="w-5 h-5 animate-spin" />
                <span v-else class="flex items-center gap-2 uppercase tracking-[0.1em]">
                  Mulai Sesi
                  <ChevronRight class="w-4 h-4 transition-transform duration-300 group-hover:translate-x-1" />
                </span>
              </div>
              <!-- Hover slide effect -->
              <div class="absolute inset-0 bg-primary translate-y-full group-hover:translate-y-0 transition-transform duration-500"></div>
            </button>
          </form>

          <p class="mt-12 text-center text-[12px] font-bold text-slate-400 uppercase tracking-widest">
            Support: <a href="mailto:it@wowin.id" class="text-slate-900 hover:text-primary transition-colors decoration-dashed underline underline-offset-4">IT@WOWIN.ID</a>
          </p>
        </div>
      </div>
    </div>

    <!-- Legal footer -->
    <div class="absolute bottom-10 left-1/2 -translate-x-1/2 text-center pointer-events-none opacity-40">
       <p class="text-[10px] font-black text-slate-400 uppercase tracking-[0.3em]">
          Powered by WOWIB Software Developer &copy; 2026
        </p>
    </div>
  </div>
</template>

<style scoped>
@keyframes bounce-subtle {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-3px); }
}
.animate-bounce-subtle {
  animation: bounce-subtle 2s infinite ease-in-out;
}

.pl-14 {
  padding-left: 3.5rem;
}

.py-4\.5 {
  padding-top: 1.125rem;
  padding-bottom: 1.125rem;
}
</style>
