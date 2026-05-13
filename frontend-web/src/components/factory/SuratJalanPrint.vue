<template>
  <div v-if="shipment" class="surat-jalan-print bg-white p-8 font-serif text-slate-900">
    <!-- Header -->
    <div class="flex justify-between items-start border-b-2 border-slate-900 pb-6 mb-6">
      <div>
        <h1 class="text-3xl font-black tracking-tighter uppercase mb-1">SURAT JALAN</h1>
        <p class="text-sm font-bold text-slate-500 tracking-widest uppercase">Delivery Order (Pabrik ke Cabang)</p>
      </div>
      <div class="text-right">
        <h2 class="text-xl font-bold">WOWIN HRIS LOGISTICS</h2>
        <p class="text-xs text-slate-500">Sistem Manajemen Pengiriman Terpadu</p>
      </div>
    </div>

    <!-- Info Section -->
    <div class="grid grid-cols-2 gap-12 mb-8">
      <!-- Left side: From/To -->
      <div class="space-y-4">
        <div>
          <p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-1">Dari (Pengirim):</p>
          <p class="font-bold text-lg leading-tight">{{ shipment.items[0]?.from_factory?.name || 'Factory' }}</p>
          <p class="text-xs text-slate-600 mt-1">{{ shipment.items[0]?.from_factory?.location || '-' }}</p>
        </div>
        <div>
          <p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-1">Ke (Tujuan):</p>
          <p class="font-bold text-lg leading-tight">{{ shipment.to }}</p>
          <p class="text-xs text-slate-600 mt-1">Gudang Cabang Utama</p>
        </div>
      </div>

      <!-- Right side: SJ Details & Barcode -->
      <div class="space-y-4 flex flex-col items-end">
        <div class="text-right">
          <p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest mb-1">No. Surat Jalan:</p>
          <p class="font-black text-xl font-mono">{{ shipment.doNo }}</p>
        </div>
        
        <!-- Barcode Placeholder -->
        <div class="mt-2 bg-white p-2 border border-slate-100 rounded-lg">
          <svg ref="barcodeRef"></svg>
        </div>

        <div class="text-right grid grid-cols-2 gap-4 mt-2">
          <div>
            <p class="text-[9px] font-bold text-slate-400 uppercase">Tgl Kirim</p>
            <p class="text-xs font-bold">{{ formatDate(shipment.items[0]?.shipped_at || shipment.items[0]?.target_shipment_date) }}</p>
          </div>
          <div>
            <p class="text-[9px] font-bold text-slate-400 uppercase">Estimasi Sampai</p>
            <p class="text-xs font-bold">{{ formatDate(shipment.items[0]?.estimated_arrival) }}</p>
          </div>
        </div>
      </div>
    </div>

    <!-- Logistics -->
    <div class="bg-slate-50 p-4 rounded-2xl mb-8 border border-slate-100 grid grid-cols-2 gap-8">
      <div class="flex items-center gap-3">
        <div class="bg-white p-2 rounded-xl border border-slate-200">
          <Truck class="h-5 w-5 text-slate-600" />
        </div>
        <div>
          <p class="text-[9px] font-bold text-slate-400 uppercase">Armada / No. Polisi</p>
          <p class="text-sm font-bold">{{ shipment.items[0]?.vehicle?.name }} ({{ shipment.items[0]?.vehicle?.license_plate }})</p>
        </div>
      </div>
      <div class="flex items-center gap-3">
        <div class="bg-white p-2 rounded-xl border border-slate-200">
          <User class="h-5 w-5 text-slate-600" />
        </div>
        <div>
          <p class="text-[9px] font-bold text-slate-400 uppercase">Nama Sopir (Driver)</p>
          <p class="text-sm font-bold">{{ shipment.items[0]?.driver?.first_name }} {{ shipment.items[0]?.driver?.last_name }}</p>
        </div>
      </div>
    </div>

    <!-- Items Table -->
    <div class="mb-12">
      <table class="w-full text-sm border-collapse">
        <thead>
          <tr class="bg-slate-900 text-white uppercase text-[10px] tracking-widest">
            <th class="py-3 px-4 text-left rounded-tl-xl">No</th>
            <th class="py-3 px-4 text-left">Deskripsi Produk</th>
            <th class="py-3 px-4 text-center">Batch No</th>
            <th class="py-3 px-4 text-right">Jumlah</th>
            <th class="py-3 px-4 text-right">Satuan</th>
            <th class="py-3 px-4 text-right rounded-tr-xl">Total (PCS)</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-slate-200 border-b-2 border-slate-900">
          <tr v-for="(item, index) in shipment.items" :key="item.id">
            <td class="py-4 px-4 text-slate-500 font-mono">{{ Number(index) + 1 }}</td>
            <td class="py-4 px-4 font-bold text-slate-800">{{ item.product?.name }}</td>
            <td class="py-4 px-4 text-center text-xs font-mono">{{ item.batch_no || 'DEFAULT' }}</td>
            <td class="py-4 px-4 text-right font-black">{{ item.quantity }}</td>
            <td class="py-4 px-4 text-right text-xs font-bold text-slate-500 uppercase">{{ item.unit || item.product?.unit }}</td>
            <td class="py-4 px-4 text-right font-black text-primary">{{ Number(item.quantity) * Number(item.pcs_per_unit) }}</td>
          </tr>
        </tbody>
        <tfoot>
          <tr>
            <td colspan="5" class="py-4 px-4 text-right font-bold text-slate-500 uppercase tracking-widest text-[10px]">Total Estimasi Tonase</td>
            <td class="py-4 px-4 text-right font-black text-lg">{{ calculateTotalWeight().toFixed(2) }} KG</td>
          </tr>
        </tfoot>
      </table>
    </div>

    <!-- Footer / Notes -->
    <div class="grid grid-cols-2 gap-12 mb-16">
      <div class="space-y-2">
        <p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Catatan / Instruksi Khusus:</p>
        <p class="text-xs text-slate-600 leading-relaxed italic">
          {{ shipment.items[0]?.notes || 'Barang harap diperiksa saat diterima. Segala kerusakan selama perjalanan adalah tanggung jawab driver.' }}
        </p>
      </div>
    </div>

    <!-- Signatures -->
    <div class="grid grid-cols-3 gap-8 pt-12 border-t border-slate-100">
      <div class="text-center">
        <p class="text-[10px] font-bold text-slate-400 uppercase mb-12 tracking-widest">Pabrik (Pengirim)</p>
        <div class="border-b border-slate-400 w-40 mx-auto mb-1"></div>
        <p class="text-xs font-bold text-slate-900">Petugas Gudang Pabrik</p>
      </div>
      <div class="text-center">
        <p class="text-[10px] font-bold text-slate-400 uppercase mb-12 tracking-widest">Sopir (Driver)</p>
        <div class="border-b border-slate-400 w-40 mx-auto mb-1"></div>
        <p class="text-xs font-bold text-slate-900">Tanda Tangan & Nama Terang</p>
      </div>
      <div class="text-center">
        <p class="text-[10px] font-bold text-slate-400 uppercase mb-12 tracking-widest">Cabang (Penerima)</p>
        <div class="border-b border-slate-400 w-40 mx-auto mb-1"></div>
        <p class="text-xs font-bold text-slate-900">Cap & Tanda Tangan</p>
      </div>
    </div>

    <!-- Print Footer -->
    <div class="mt-12 text-center text-[9px] text-slate-400 uppercase tracking-[0.3em]">
      Dokumen ini sah dicetak dari sistem WOWIN HRIS pada {{ new Date().toLocaleString('id-ID') }}
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
import { Truck, User } from 'lucide-vue-next'
import JsBarcode from 'jsbarcode'

const props = defineProps<{
  shipment: any
}>()

const barcodeRef = ref<SVGSVGElement | null>(null)

const formatDate = (dateStr: string) => {
  if (!dateStr) return '-'
  return new Date(dateStr).toLocaleDateString('id-ID', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const calculateTotalWeight = () => {
  if (!props.shipment || !props.shipment.items) return 0
  return props.shipment.items.reduce((acc: number, item: any) => acc + (item.total_weight || 0), 0)
}

const generateBarcode = () => {
  if (barcodeRef.value && props.shipment?.doNo) {
    JsBarcode(barcodeRef.value, props.shipment.doNo, {
      format: "CODE128",
      width: 1.5,
      height: 40,
      displayValue: false,
      margin: 0
    })
  }
}

onMounted(() => {
  generateBarcode()
})

watch(() => props.shipment, () => {
  generateBarcode()
}, { deep: true })
</script>

<style scoped>
@media print {
  .surat-jalan-print {
    padding: 0 !important;
    background: white !important;
  }
  
  /* Hide UI elements */
  nav, .no-print {
    display: none !important;
  }
}

.surat-jalan-print {
  width: 210mm; /* A4 width */
  margin: 0 auto;
}
</style>
