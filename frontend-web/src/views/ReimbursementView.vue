<script setup lang="ts">
import { ref } from 'vue'

const reimbursements = ref([
  { id: '1', date: '2026-04-12', employee: 'John Doe', amount: 500000, title: 'Transport Client', status: 'PENDING' },
  { id: '2', date: '2026-04-10', employee: 'Jane Smith', amount: 1200000, title: 'Hotel Out of Town', status: 'APPROVED' },
])
</script>

<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-3xl font-bold tracking-tight text-slate-900">Pusat Persetujuan Reimbursement</h1>
        <p class="text-slate-500 mt-1">Validasi dan kelola pengajuan klaim oleh karyawan. Eksklusif untuk Admin Nota.</p>
      </div>
      <button class="px-4 py-2 bg-slate-900 text-white font-medium rounded-lg hover:bg-slate-800 transition-colors">
        Export Laporan
      </button>
    </div>

    <div class="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
      <div class="overflow-x-auto">
        <table class="w-full text-sm text-left">
          <thead class="bg-slate-50 border-b border-slate-200 text-slate-600 font-medium">
            <tr>
              <th class="px-6 py-4">Tanggal Pengajuan</th>
              <th class="px-6 py-4">Karyawan</th>
              <th class="px-6 py-4">Keterangan</th>
              <th class="px-6 py-4">Nominal</th>
              <th class="px-6 py-4">Status</th>
              <th class="px-6 py-4 text-right">Aksi</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100">
            <tr v-for="item in reimbursements" :key="item.id" class="hover:bg-slate-50/50 transition-colors">
              <td class="px-6 py-4 text-slate-600">{{ item.date }}</td>
              <td class="px-6 py-4 font-medium text-slate-900">{{ item.employee }}</td>
              <td class="px-6 py-4 text-slate-600">{{ item.title }}</td>
              <td class="px-6 py-4 text-slate-900 font-medium">Rp {{ item.amount.toLocaleString('id-ID') }}</td>
              <td class="px-6 py-4">
                <span :class="[
                  'px-2.5 py-1 text-xs font-semibold rounded-full',
                  item.status === 'PENDING' ? 'bg-amber-100 text-amber-700' : 'bg-emerald-100 text-emerald-700'
                ]">
                  {{ item.status }}
                </span>
              </td>
              <td class="px-6 py-4 text-right">
                <button v-if="item.status === 'PENDING'" class="text-indigo-600 font-medium hover:text-indigo-800 transition-colors">Review</button>
                <button v-else class="text-slate-400 font-medium hover:text-slate-600 transition-colors">Detail</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
