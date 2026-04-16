<script setup lang="ts">
import { ref } from 'vue'

const roles = ref([
  { id: 'superadmin', label: 'Super Admin', desc: 'Akses penuh ke semua modul HRIS' },
  { id: 'hr_admin', label: 'HR Admin', desc: 'Hak wewenang kelola absensi, data pegawai, dan payroll' },
  { id: 'admin_nota', label: 'Admin Nota', desc: 'Tugas mereview dan validasi Reimbursement' },
  { id: 'manager', label: 'Manager', desc: 'Akses Dashboard, KPI, dan evaluasi staff bawahan' },
  { id: 'employee', label: 'Karyawan', desc: 'Hak wewenang default / aplikasi Mobile' }
])
</script>

<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-3xl font-bold tracking-tight text-slate-900">Manajemen Hak Akses (Role)</h1>
        <p class="text-slate-500 mt-1">Daftar ID akses pengguna yang mendefinisikan batas kemampuan manipulasi data.</p>
      </div>
      <button class="px-4 py-2 bg-slate-900 text-white font-medium rounded-lg hover:bg-slate-800 transition-colors">
        Tambah Role Ekstra
      </button>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div v-for="role in roles" :key="role.id" class="bg-white rounded-xl border border-slate-200 shadow-sm p-6 hover:shadow-md transition-shadow relative overflow-hidden group">
        <!-- Decoration -->
        <div class="absolute top-0 right-0 w-24 h-24 bg-gradient-to-br from-indigo-50 to-indigo-100 rounded-bl-full -z-10 opacity-50 group-hover:opacity-100 transition-opacity"></div>
        
        <h3 class="text-xl font-bold text-slate-900">{{ role.label }}</h3>
        <p class="text-xs font-mono text-indigo-500 mt-1 bg-indigo-50 inline-block px-2 py-0.5 rounded">ID: {{ role.id }}</p>
        <p class="text-slate-600 mt-4 text-sm">{{ role.desc }}</p>
        
        <div class="mt-6 flex justify-end">
          <button class="text-sm font-medium text-slate-500 hover:text-indigo-600 transition-colors">Lihat Daftar Pengguna &rarr;</button>
        </div>
      </div>
    </div>
  </div>
</template>
