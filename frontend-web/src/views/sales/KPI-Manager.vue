<template>
  <div class="p-6">
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold text-gray-800">Sales Performance & KPI Manager</h1>
      <button 
        @click="showManualEntry = true" 
        class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded"
      >
        + Input Nota Manual
      </button>
    </div>

    <!-- Sales KPI Table -->
    <div class="bg-white rounded-lg shadow overflow-hidden">
      <table class="min-w-full leading-normal">
        <thead>
          <tr>
            <th class="px-5 py-3 border-b-2 border-gray-200 bg-gray-100 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
              Nama Sales / Role
            </th>
            <th class="px-5 py-3 border-b-2 border-gray-200 bg-gray-100 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
              Target Omzet (Total / Baru)
            </th>
            <th class="px-5 py-3 border-b-2 border-gray-200 bg-gray-100 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
              Realisasi (Lama vs Baru)
            </th>
            <th class="px-5 py-3 border-b-2 border-gray-200 bg-gray-100 text-left text-xs font-semibold text-gray-600 uppercase tracking-wider">
              Progress
            </th>
            <th class="px-5 py-3 border-b-2 border-gray-200 bg-gray-100"></th>
          </tr>
        </thead>
        <tbody>
          <!-- Example Row -->
          <tr>
            <td class="px-5 py-5 border-b border-gray-200 bg-white text-sm">
              <div class="flex items-center">
                <div class="ml-3">
                  <p class="text-gray-900 whitespace-no-wrap font-bold">Budi Santoso</p>
                  <p class="text-gray-500 whitespace-no-wrap">Motoris</p>
                </div>
              </div>
            </td>
            <td class="px-5 py-5 border-b border-gray-200 bg-white text-sm">
              <p class="text-gray-900 whitespace-no-wrap">Rp 100.000.000</p>
              <p class="text-gray-500 whitespace-no-wrap">5 Toko Baru</p>
            </td>
            <td class="px-5 py-5 border-b border-gray-200 bg-white text-sm">
              <p class="text-gray-900 whitespace-no-wrap">Lama: Rp 60.000.000</p>
              <p class="text-green-600 whitespace-no-wrap">Baru: Rp 20.000.000</p>
            </td>
            <td class="px-5 py-5 border-b border-gray-200 bg-white text-sm">
              <div class="relative w-full bg-gray-200 rounded">
                <div style="width: 80%" class="absolute top-0 h-4 rounded bg-blue-500"></div>
              </div>
              <span class="text-xs text-gray-500 mt-1 block">80% Tercapai</span>
            </td>
            <td class="px-5 py-5 border-b border-gray-200 bg-white text-sm text-right">
              <button class="text-blue-600 hover:text-blue-900">Edit</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Manual Entry Modal -->
    <div v-if="showManualEntry" class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
      <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
        <div class="mt-3 text-center">
          <h3 class="text-lg leading-6 font-medium text-gray-900">Input Nota Manual</h3>
          <div class="mt-2 text-left space-y-4">
            <input type="text" placeholder="Sales ID" class="w-full border rounded p-2" />
            <input type="text" placeholder="Store ID" class="w-full border rounded p-2" />
            <select class="w-full border rounded p-2">
              <option value="TOKO_LAMA">Toko Lama</option>
              <option value="TOKO_BARU">Toko Baru</option>
            </select>
            <input type="number" placeholder="Total Omzet (Rp)" class="w-full border rounded p-2" />
          </div>
          <div class="items-center px-4 py-3 mt-4 flex justify-end gap-2">
            <button @click="showManualEntry = false" class="px-4 py-2 bg-gray-200 text-gray-800 rounded">Batal</button>
            <button @click="submitManualEntry" class="px-4 py-2 bg-blue-500 text-white rounded">Simpan</button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';

const showManualEntry = ref(false);

const submitManualEntry = () => {
  // Submit logic calling POST /api/v1/admin/sales/manual-entry
  showManualEntry.value = false;
  alert('Data berhasil disimpan dan KPI diperbarui otomatis!');
};
</script>
