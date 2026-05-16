<template>
  <div v-if="shipment" id="surat-jalan-card" class="surat-jalan-print w-full bg-white font-sans text-slate-900 print:shadow-none print:max-w-full">
     <!-- Header Area -->
     <div class="bg-white p-4 border-b-2 border-slate-900">
        <div class="grid grid-cols-3 gap-8 items-center">
          <div class="space-y-1">
            <p class="text-[9px] font-black text-slate-400 uppercase tracking-widest">SOPIR / ARMADA</p>
            <p class="text-[11px] font-black text-slate-900">
              {{ shipment.items[0]?.driver?.first_name || '........................' }} / {{ shipment.items[0]?.vehicle?.license_plate || '..........' }}
            </p>
            <p class="text-[10px] font-bold text-slate-500 uppercase tracking-tight">{{ shipment.items[0]?.vehicle?.name }}</p>
          </div>
          <div class="space-y-1 text-center">
            <p class="text-[9px] font-black text-slate-400 uppercase tracking-widest">DARI / KE</p>
            <p class="text-[11px] font-black text-slate-900 truncate">
              {{ shipment.items[0]?.from_factory?.name }} &rarr; {{ shipment.to }}
            </p>
            <p class="text-[10px] font-bold text-slate-500 truncate italic">{{ shipment.items[0]?.from_factory?.location }}</p>
          </div>
          <div class="text-right">
            <p class="text-[12px] font-mono font-black text-slate-900 pb-1 italic uppercase tracking-tighter">SURAT JALAN #{{ shipment.doNo }}</p>
            <p class="text-[9px] font-bold text-slate-500 mt-1 uppercase">{{ formatDateLong(shipment.items[0]?.target_shipment_date) }}</p>
          </div>
        </div>
     </div>
     
     <div class="p-4 space-y-4">
        <!-- Main Table -->
        <div class="border-2 border-slate-900 rounded-2xl overflow-hidden bg-white shadow-sm">
          <table class="w-full text-left text-[10px] border-collapse whitespace-nowrap">
            <thead>
              <tr class="bg-slate-900 text-white border-b-2 border-slate-900">
                <th class="p-3 border-r border-slate-700 font-black text-center w-10">NO</th>
                <th class="p-3 border-r border-slate-700 font-black">NAMA PRODUK</th>
                <th class="p-3 border-r border-slate-700 font-black text-center w-32 bg-slate-800">BATCH NO</th>
                <th class="p-3 border-r border-slate-700 font-black text-right w-24">JUMLAH</th>
                <th class="p-3 border-r border-slate-700 font-black text-center w-20">SATUAN</th>
                <th class="p-3 border-r border-slate-700 font-black text-right w-24 bg-slate-800">BERAT (KG)</th>
                <th class="p-3 font-black text-center w-40">KETERANGAN</th>
              </tr>
            </thead>
            <tbody class="divide-y border-slate-300">
              <tr v-for="(item, idx) in shipment.items" :key="item.id" class="h-8">
                <td class="p-3 border-r border-slate-300 text-center font-bold text-slate-400">{{ Number(idx) + 1 }}</td>
                <td class="p-3 border-r border-slate-300">
                  <p class="font-black text-slate-900">{{ item.product?.name }}</p>
                  <p class="text-[8px] text-slate-400 font-bold uppercase tracking-widest mt-0.5">{{ item.product?.sku }}</p>
                </td>
                <td class="p-3 border-r border-slate-300 text-center font-mono font-bold bg-slate-50/30 text-slate-600">{{ item.batch_no || 'DEFAULT' }}</td>
                <td class="p-3 border-r border-slate-300 text-right font-black text-slate-900">{{ item.quantity }}</td>
                <td class="p-3 border-r border-slate-300 text-center font-bold text-slate-500 uppercase">{{ item.unit || item.product?.unit }}</td>
                <td class="p-3 border-r border-slate-300 text-right font-black text-primary bg-primary/5">{{ item.total_weight.toFixed(2) }}</td>
                <td class="p-3 text-slate-400 italic text-[8px] whitespace-normal max-w-[150px] leading-tight">{{ item.notes || '-' }}</td>
              </tr>

              <!-- Filler Rows -->
              <tr v-for="n in Math.max(0, 8 - (shipment.items?.length || 0))" :key="'filler-'+n" class="h-8 bg-slate-50/10">
                <td class="p-3 border-r border-slate-300 text-center text-slate-200">{{ (shipment.items?.length || 0) + Number(n) }}</td>
                <td class="p-3 border-r border-slate-300"></td>
                <td class="p-3 border-r border-slate-300 bg-slate-50/10"></td>
                <td class="p-3 border-r border-slate-300"></td>
                <td class="p-3 border-r border-slate-300"></td>
                <td class="p-3 border-r border-slate-300 bg-slate-50/5"></td>
                <td class="p-3 border-slate-300"></td>
              </tr>

              <!-- Total Row -->
              <tr class="bg-slate-50 font-black h-10 border-t-2 border-slate-900">
                <td colspan="3" class="p-3 text-right border-r border-slate-300 uppercase tracking-widest text-[9px]">TOTAL MUATAN PABRIK</td>
                <td class="p-3 text-right border-r border-slate-300 text-lg">{{ calculateTotalQty() }}</td>
                <td class="border-r border-slate-300"></td>
                <td class="p-3 text-right border-r border-slate-300 text-lg text-primary">{{ calculateTotalWeight().toFixed(2) }}</td>
                <td class="p-3 text-[8px] text-slate-400 font-bold uppercase tracking-[0.2em] flex items-center justify-center gap-2">
                   <div class="w-2 h-2 rounded-full bg-emerald-500"></div> VALIDATED BY SYSTEM
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <!-- Footer Section -->
        <div class="grid grid-cols-3 gap-8 mt-6">
          <div class="text-center space-y-12">
            <p class="text-[9px] font-black text-slate-400 uppercase tracking-widest">PENGIRIM (PABRIK)</p>
            <div class="space-y-1">
              <p class="text-[10px] font-black text-slate-900">( .................................................. )</p>
              <p class="text-[8px] text-slate-400 font-bold uppercase tracking-wider">Admin Gudang Pabrik</p>
            </div>
          </div>
          <div class="text-center space-y-12">
            <p class="text-[9px] font-black text-slate-400 uppercase tracking-widest">PEMBAWA (DRIVER)</p>
            <div class="space-y-1">
              <p class="text-[10px] font-black text-slate-900">( {{ shipment.items[0]?.driver?.first_name || '..................................' }} )</p>
              <p class="text-[8px] text-slate-400 font-bold uppercase tracking-wider">Sopir / Kurir Pengantar</p>
            </div>
          </div>
          <div class="flex justify-end items-center pr-4 gap-4">
             <div class="text-right">
                <p class="text-[10px] font-black text-slate-900 uppercase tracking-widest leading-none">VALIDASI DIGITAL</p>
                <p class="text-[7px] text-slate-400 font-bold mt-1 uppercase tracking-tighter">Scan untuk konfirmasi terima</p>
             </div>
             <div class="relative bg-white p-2 border-2 border-slate-900 rounded-2xl shadow-lg flex items-center justify-center">
                <QrcodeVue :value="shipment.doNo" :size="96" level="H" render-as="svg" />
                <div class="absolute -top-2 -right-2 bg-primary text-white text-[8px] font-black px-2 py-0.5 rounded-full shadow-md">WOWIN</div>
             </div>
          </div>
        </div>
     </div>

     <!-- Footer Notes -->
     <div class="px-6 py-4 mt-6 border-t border-dashed border-slate-200">
        <p class="text-[8px] font-black text-slate-400 uppercase tracking-[0.4em] text-center">
          Dokumen ini sah dicetak dari sistem WOWIN HRIS pada {{ new Date().toLocaleString('id-ID') }}
        </p>
     </div>
  </div>
</template>

<script setup lang="ts">
import QrcodeVue from 'qrcode.vue'

const props = defineProps<{
  shipment: any
}>()

const formatDateLong = (dateStr: string) => {
  if (!dateStr) return '-'
  return new Date(dateStr).toLocaleDateString('id-ID', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: 'numeric'
  })
}

const calculateTotalWeight = () => {
  if (!props.shipment || !props.shipment.items) return 0
  return props.shipment.items.reduce((acc: number, item: any) => acc + (item.total_weight || 0), 0)
}

const calculateTotalQty = () => {
  if (!props.shipment || !props.shipment.items) return 0
  return props.shipment.items.reduce((acc: number, item: any) => acc + (item.quantity || 0), 0)
}
</script>

<style scoped>
@media print {
  @page {
    size: landscape;
    margin: 0;
  }
  
  html, body {
    height: 100vh !important;
    margin: 0 !important;
    padding: 0 !important;
    overflow: hidden !important;
    background: white !important;
  }

  .surat-jalan-print {
    position: absolute !important;
    top: 0 !important;
    left: 0 !important;
    width: 100% !important;
    background: white !important;
    padding: 8mm !important;
    z-index: 99999 !important;
    display: block !important;
    
    /* Ensure it scales down to fit one page */
    zoom: 0.80;
    -moz-transform: scale(0.80);
    -moz-transform-origin: top left;
    
    page-break-inside: avoid !important;
    break-inside: avoid !important;
  }

  /* Force table sizing for print */
  .surat-jalan-print table {
    width: 100% !important;
    border-collapse: collapse !important;
  }

  .surat-jalan-print th, .surat-jalan-print td {
    border: 1px solid #000 !important;
  }

  /* Hide UI elements from main layout */
  :not(.surat-jalan-print, .surat-jalan-print *) {
    display: none !important;
  }
}

.surat-jalan-print {
  max-width: 297mm; /* A4 Landscape width */
  margin: 0 auto;
}
</style>
