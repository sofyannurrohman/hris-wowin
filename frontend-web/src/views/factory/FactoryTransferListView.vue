<template>
  <div class="p-8 space-y-8 bg-[#f8fafc] min-h-screen">
    <!-- Header -->
    <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 bg-white p-8 rounded-[2rem] shadow-sm border border-slate-100">
      <div>
        <div class="flex items-center gap-2 text-xs font-bold text-orange-600 uppercase tracking-[0.2em] mb-2">
          <Truck class="h-4 w-4" />
          <span>Logistics & Distribution</span>
        </div>
        <h1 class="text-3xl font-black tracking-tight text-slate-900">Manajemen Pengiriman</h1>
        <p class="text-slate-500 mt-1">Kelola surat jalan dan proses permintaan barang dari cabang.</p>
      </div>
      <div class="flex gap-3">
        <Button variant="outline" class="rounded-2xl border-slate-200 bg-white hover:bg-slate-50 text-slate-600 font-bold" @click="factoryStore.fetchAllTransfers()">
          <RefreshCw class="mr-2 h-4 w-4" :class="{ 'animate-spin': factoryStore.loading }" /> Segarkan
        </Button>
        <Button @click="openManualShipmentModal" class="rounded-2xl shadow-lg shadow-primary/20 font-bold">
          <Plus class="mr-2 h-4 w-4" /> Buat Surat Jalan Manual
        </Button>
      </div>
    </div>

    <!-- Main Content Layout -->
    <div class="grid grid-cols-1 lg:grid-cols-12 gap-8">
      
      <!-- LEFT SIDE: ACTIVE & COMPLETED SHIPMENTS (8/12) -->
      <div class="lg:col-span-8 space-y-6">
        <div class="flex items-center justify-between px-2">
          <h2 class="text-xl font-black text-slate-900 flex items-center gap-2">
             Daftar Surat Jalan 
             <Badge variant="secondary" class="rounded-full bg-slate-100 text-slate-500">{{ processedShipments.length }}</Badge>
          </h2>
          <div class="relative w-64">
            <Search class="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
            <input v-model="searchQuery" type="text" placeholder="Cari No. SJ..." class="w-full pl-10 pr-4 py-2 bg-white border border-slate-200 rounded-xl text-sm outline-none" />
          </div>
        </div>

        <div v-if="processedShipments.length === 0" class="bg-white rounded-[2rem] p-12 text-center border border-dashed border-slate-200">
          <div class="bg-slate-50 h-16 w-16 rounded-2xl flex items-center justify-center mx-auto mb-4 text-slate-300">
            <Truck class="h-8 w-8" />
          </div>
          <h3 class="font-bold text-slate-900">Belum ada pengiriman</h3>
          <p class="text-sm text-slate-500 mt-1">Proses permintaan di sebelah kanan untuk membuat surat jalan baru.</p>
        </div>

        <div v-for="shipment in processedShipments" :key="shipment.doNo" class="bg-white rounded-[2rem] border border-slate-100 shadow-sm overflow-hidden transition-all hover:shadow-md">
          <div class="p-6 flex flex-col md:flex-row justify-between items-start md:items-center gap-4 bg-slate-50/30 border-b border-slate-50">
            <div class="flex items-center gap-4">
              <div class="bg-white p-3 rounded-2xl shadow-sm border border-slate-100">
                <Truck class="h-6 w-6 text-primary" />
              </div>
              <div>
                <p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">No. Surat Jalan</p>
                <h3 class="text-lg font-black text-slate-900 font-mono">{{ shipment.doNo }}</h3>
              </div>
            </div>
            <div class="flex items-center gap-6">
              <div class="text-right">
                <p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Tujuan</p>
                <p class="text-sm font-bold text-slate-700">{{ shipment.to }}</p>
              </div>
              <div class="text-right" v-if="shipment.items[0]?.target_shipment_date">
                <p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Tgl Kirim</p>
                <p class="text-sm font-bold text-blue-600">
                  {{ new Date(shipment.items[0].target_shipment_date).toLocaleDateString('id-ID', { day: 'numeric', month: 'short' }) }}
                </p>
              </div>
              <div class="text-right" v-if="shipment.items[0]?.estimated_arrival">
                <p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Est. Sampai</p>
                <p class="text-sm font-bold text-orange-600">
                  {{ new Date(shipment.items[0].estimated_arrival).toLocaleDateString('id-ID', { day: 'numeric', month: 'short' }) }}
                </p>
              </div>
              <div class="text-right" v-if="shipment.items[0]?.vehicle">
                <p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Armada</p>
                <p class="text-sm font-bold text-slate-700">{{ shipment.items[0].vehicle.name }}</p>
              </div>
              <div class="text-right" v-if="shipment.items[0]?.driver">
                <p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Sopir</p>
                <p class="text-sm font-bold text-slate-700">{{ shipment.items[0].driver.first_name }}</p>
              </div>
              <Badge :class="getStatusClass(shipment.status)" class="rounded-full px-4 py-1.5 font-bold uppercase text-[10px]">
                {{ shipment.status }}
              </Badge>
              <template v-if="shipment.status === 'REQUESTED'">
                <div class="px-4 py-1.5 bg-orange-50 text-orange-600 rounded-xl border border-orange-100 text-[10px] font-black uppercase tracking-widest">
                  Menunggu Approval Cabang
                </div>
              </template>
              <template v-if="shipment.status === 'REJECTED'">
                 <div class="flex items-center gap-3">
                   <Button @click="openEditModal(shipment)" size="sm" class="bg-rose-600 hover:bg-rose-700 text-white font-bold rounded-xl px-6 h-10 shadow-lg shadow-rose-100">Jadwal Ulang</Button>
                 </div>
              </template>
              <template v-if="shipment.status === 'APPROVED'">
                <div v-if="shipment.items[0]?.initiated_by === 'FACTORY'" class="px-4 py-1.5 bg-emerald-50 text-emerald-700 rounded-xl border border-emerald-100 text-[10px] font-black uppercase tracking-widest flex items-center gap-2">
                  <div class="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></div>
                  Sudah Di-ACC Gudang (Siap Kirim)
                </div>
                <Button @click="processShipment(shipment)" class="bg-primary hover:bg-primary/90 text-white font-bold h-10 px-6 rounded-xl shadow-lg shadow-primary/20">
                  Proses & Kirim
                </Button>
              </template>
              <template v-if="shipment.status === 'REJECTED'">
                <div class="px-4 py-3 bg-rose-50 text-rose-600 rounded-2xl border border-rose-100 flex flex-col gap-1">
                   <p class="text-[9px] font-black uppercase tracking-[0.2em]">Ditolak Cabang</p>
                   <p class="text-xs font-bold leading-relaxed">Alasan: {{ shipment.items[0]?.rejection_reason || 'Tidak ada alasan spesifik' }}</p>
                </div>
              </template>
              <Button variant="ghost" size="icon" class="h-10 w-10 text-slate-400 hover:text-primary">
                <Printer class="h-5 w-5" />
              </Button>
            </div>
          </div>
          <div class="p-6">
            <table class="w-full text-sm">
              <tbody class="divide-y divide-slate-50">
                <tr v-for="item in shipment.items" :key="item.id" class="group">
                  <td class="py-3 px-2">
                    <span class="font-bold text-slate-800">{{ item.product?.name }}</span>
                  </td>
                  <td class="py-3 px-2 text-right">
                    <span class="font-black text-slate-700">{{ item.quantity }}</span>
                    <span class="text-[10px] text-slate-400 ml-1 uppercase font-bold">{{ item.unit || item.product?.unit }}</span>
                    <span v-if="item.pcs_per_unit > 1" class="text-[9px] text-slate-500 block">({{ item.quantity * item.pcs_per_unit }} PCS)</span>
                  </td>
                  <td class="py-3 px-2 text-right w-32">
                    <span class="font-bold text-primary">{{ item.total_weight.toFixed(2) }} KG</span>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- RIGHT SIDE: INCOMING REQUESTS (4/12) -->
      <div class="lg:col-span-4 space-y-6">
        <div class="flex items-center justify-between px-2">
          <h2 class="text-xl font-black text-slate-900 flex items-center gap-2 text-orange-600">
             Permintaan Cabang 
             <Badge variant="secondary" class="rounded-full bg-orange-100 text-orange-600 border-none">{{ incomingRequests.length }}</Badge>
          </h2>
        </div>

        <div v-if="incomingRequests.length === 0" class="bg-white rounded-[2rem] p-12 text-center border border-dashed border-slate-200">
           <p class="text-sm text-slate-400">Tidak ada permintaan barang baru.</p>
        </div>

        <div v-for="request in incomingRequests" :key="request.doNo" class="bg-white rounded-3xl border border-orange-100 shadow-sm overflow-hidden">
          <div class="p-5 bg-orange-50/50 border-b border-orange-100 flex justify-between items-center">
            <div>
              <p class="text-[10px] font-bold text-orange-400 uppercase tracking-widest">ID Permintaan</p>
              <h4 class="text-sm font-black text-orange-900 font-mono">{{ request.doNo }}</h4>
            </div>
            <div class="flex flex-col items-end gap-1">
              <Badge :class="getStatusClass(request.status)" class="border-none text-[9px] font-bold uppercase">{{ request.status }}</Badge>
              <div v-if="request.status === 'REJECTED'" class="text-[8px] font-bold text-rose-500 italic max-w-[120px] text-right leading-tight">
                {{ request.items[0]?.rejection_reason }}
              </div>
            </div>
          </div>
          <div class="p-5 space-y-4">
            <div>
              <p class="text-[10px] font-bold text-slate-400 uppercase mb-2">Tujuan Pengiriman</p>
              <div class="flex items-center gap-2">
                <MapPin class="h-4 w-4 text-primary" />
                <span class="text-sm font-black text-slate-700">{{ request.to }}</span>
              </div>
            </div>
            
            <div class="space-y-2">
              <div v-for="item in request.items" :key="item.id" class="bg-slate-50 p-4 rounded-2xl border border-slate-100 space-y-1">
                <div class="flex justify-between items-center">
                  <span class="text-xs font-black text-slate-700">{{ item.product?.name }}</span>
                  <span class="text-xs font-black text-primary">{{ item.quantity }} {{ item.unit || item.product?.unit }}</span>
                </div>
                <div v-if="item.pcs_per_unit > 1" class="flex justify-end">
                  <span class="text-[9px] font-bold text-slate-400 uppercase">Total: {{ item.quantity * item.pcs_per_unit }} PCS</span>
                </div>
              </div>
            </div>

            <div v-if="request.status === 'REQUESTED'">
              <template v-if="request.items[0]?.initiated_by === 'BRANCH'">
                <Button @click="handleApproveRequest(request)" class="w-full rounded-2xl bg-emerald-600 hover:bg-emerald-700 text-white font-bold h-12 shadow-lg shadow-emerald-200 mt-2">
                  Setujui Permintaan
                </Button>
              </template>
              <template v-else>
                <div class="w-full py-4 text-center text-[10px] font-black text-orange-500 uppercase tracking-widest bg-orange-50 rounded-2xl border border-orange-100 mt-2">
                  Menunggu Approval Cabang
                </div>
              </template>
            </div>
            
            <div v-else-if="request.status === 'APPROVED'">
              <Button @click="processShipment(request)" class="w-full rounded-2xl bg-primary hover:bg-primary/90 text-white font-bold h-12 shadow-lg shadow-primary/20 mt-2">
                Proses & Kirim (Buat SJ)
              </Button>
            </div>

            <!-- CRUD Actions for Factory Initiated Shipments -->
            <div v-if="request.status === 'REQUESTED' || request.status === 'APPROVED' || request.status === 'REJECTED'" class="grid grid-cols-2 gap-2 mt-4 pt-4 border-t border-slate-100">
              <Button variant="outline" size="sm" @click="openEditModal(request)" class="rounded-xl font-bold text-slate-600 hover:bg-slate-50 border-slate-200 h-10">
                <RefreshCw class="h-3.5 w-3.5 mr-2" /> Edit
              </Button>
              <Button variant="outline" size="sm" @click="handleDeleteShipment(request)" class="rounded-xl font-bold text-destructive hover:bg-destructive/5 border-destructive/20 h-10">
                <Trash2 class="h-3.5 w-3.5 mr-2" /> Hapus
              </Button>
            </div>
          </div>
        </div>
      </div>

    </div>

    <div v-if="showProcessModal" class="fixed inset-0 bg-slate-900/60 backdrop-blur-md z-[100] flex items-center justify-center p-4 md:p-6">
      <Card class="w-full max-w-4xl shadow-2xl rounded-[2.5rem] overflow-hidden border-none animate-in fade-in zoom-in-95 duration-300 flex flex-col max-h-[90vh]">
        <CardHeader class="p-8 border-b bg-white shrink-0">
          <div class="flex justify-between items-center">
            <div>
              <CardTitle class="text-2xl font-black text-slate-900">Proses & Terbitkan Surat Jalan</CardTitle>
              <CardDescription>Sesuaikan item, tentukan jadwal, dan assign armada pengiriman.</CardDescription>
            </div>
            <Button variant="ghost" size="icon" @click="showProcessModal = false" class="rounded-full">
              <Plus class="h-6 w-6 rotate-45 text-slate-400" />
            </Button>
          </div>
        </CardHeader>
        <CardContent class="p-8 space-y-8 bg-white overflow-y-auto custom-scrollbar">
          <!-- Summary Info -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="bg-blue-50 p-6 rounded-3xl border border-blue-100 flex items-center gap-4">
              <div class="bg-white h-12 w-12 rounded-2xl flex items-center justify-center shadow-sm">
                <Building2 class="h-6 w-6 text-blue-600" />
              </div>
              <div>
                <p class="text-[10px] font-bold text-blue-400 uppercase tracking-widest">Tujuan Cabang</p>
                <h4 class="text-lg font-black text-blue-900">{{ selectedRequest?.to }}</h4>
              </div>
            </div>
            <div class="bg-slate-50 p-6 rounded-3xl border border-slate-100 flex items-center gap-4">
              <div class="bg-white h-12 w-12 rounded-2xl flex items-center justify-center shadow-sm">
                <FileText class="h-6 w-6 text-slate-600" />
              </div>
              <div>
                <p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">ID Permintaan</p>
                <h4 class="text-lg font-black text-slate-900 font-mono">{{ selectedRequest?.doNo }}</h4>
              </div>
            </div>
          </div>

          <!-- Logistics Assignment -->
          <div class="space-y-6">
            <p class="text-[11px] font-black text-primary uppercase tracking-[0.2em] flex items-center gap-2">
              <Truck class="h-4 w-4" /> Penugasan Logistik
            </p>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div class="space-y-2">
                <label class="text-sm font-bold text-slate-700 ml-1">Pilih Pabrik Pengirim</label>
                <select v-model="processForm.factory_id" class="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold outline-none">
                  <option v-for="f in factoryStore.factories" :key="f.id" :value="f.id">{{ f.name }}</option>
                </select>
              </div>
              <div class="space-y-2">
                <label class="text-sm font-bold text-slate-700 ml-1">Armada (Kendaraan)</label>
                <select v-model="processForm.vehicle_id" class="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold outline-none">
                  <option value="">Pilih Armada...</option>
                  <option v-for="v in vehicleStore.vehicles" :key="v.id" :value="v.id">
                    {{ v.name }} ({{ v.license_plate }}) - Cap: {{ v.capacity }} KG
                  </option>
                </select>
              </div>
              <div class="space-y-2">
                <label class="text-sm font-bold text-slate-700 ml-1">Sopir (Driver)</label>
                <select v-model="processForm.driver_id" class="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold outline-none">
                  <option value="">Pilih Sopir...</option>
                  <option v-for="e in masterDataStore.employees" :key="e.id" :value="e.id">{{ e.first_name }} {{ e.last_name }}</option>
                </select>
              </div>
              <div class="grid grid-cols-2 gap-4">
                <div class="space-y-2">
                  <label class="text-sm font-bold text-slate-700 ml-1">Tgl Kirim</label>
                  <input type="datetime-local" v-model="processForm.target_shipment_date" class="w-full px-4 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-xs font-bold outline-none" />
                </div>
                <div class="space-y-2">
                  <label class="text-sm font-bold text-slate-700 ml-1">Est. Sampai</label>
                  <input type="datetime-local" v-model="processForm.estimated_arrival" class="w-full px-4 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-xs font-bold outline-none" />
                </div>
              </div>
            </div>
          </div>

          <!-- Item Adjustments -->
          <div class="space-y-4 pt-4 border-t border-slate-50">
            <div class="flex justify-between items-center">
              <p class="text-[11px] font-black text-orange-600 uppercase tracking-[0.2em] flex items-center gap-2">
                <Package class="h-4 w-4" /> Daftar Item & Penyesuaian
              </p>
              <Button size="sm" variant="outline" @click="addProcessItem" class="rounded-xl font-bold h-9">
                <Plus class="h-4 w-4 mr-1" /> Tambah Produk Lain
              </Button>
            </div>
            
            <div class="space-y-3">
              <div v-for="(item, index) in processForm.items" :key="index" class="bg-slate-50/50 p-5 rounded-[2rem] border border-slate-100 group transition-all hover:bg-white hover:shadow-sm">
                <div class="grid grid-cols-1 md:grid-cols-12 gap-4 items-end">
                  <div class="md:col-span-5 space-y-1">
                    <label class="text-[10px] font-bold text-slate-400 uppercase tracking-widest ml-1">Produk</label>
                    <select v-model="item.product_id" :disabled="item.original" class="w-full px-4 py-3 bg-white border border-slate-100 rounded-xl text-xs font-bold outline-none disabled:opacity-60">
                      <option v-for="p in factoryStore.products" :key="p.id" :value="p.id">{{ p.name }}</option>
                    </select>
                  </div>
                  <div class="md:col-span-2 space-y-1">
                    <label class="text-[10px] font-bold text-slate-400 uppercase tracking-widest ml-1">Jumlah</label>
                    <input type="number" v-model.number="item.quantity" class="w-full px-4 py-3 bg-white border border-slate-100 rounded-xl text-xs font-black outline-none" />
                  </div>
                  <div class="md:col-span-2 space-y-1">
                    <label class="text-[10px] font-bold text-slate-400 uppercase tracking-widest ml-1">Satuan</label>
                    <select v-model="item.unit" class="w-full px-4 py-3 bg-white border border-slate-100 rounded-xl text-xs font-bold outline-none">
                      <option v-for="u in UNIT_OPTIONS" :key="u" :value="u">{{ u }}</option>
                    </select>
                  </div>
                  <div class="md:col-span-2 space-y-1">
                    <label class="text-[10px] font-bold text-slate-400 uppercase tracking-widest ml-1">Isi/Unit</label>
                    <input type="number" v-model.number="item.pcs_per_unit" class="w-full px-4 py-3 bg-white border border-slate-100 rounded-xl text-xs font-black outline-none" />
                  </div>
                  <div class="md:col-span-1 flex items-end">
                    <Button variant="ghost" size="icon" @click="removeProcessItem(index)" class="h-11 w-full text-rose-400 hover:text-rose-600 hover:bg-rose-50 rounded-xl">
                      <Trash2 class="h-5 w-5" />
                    </Button>
                  </div>
                </div>
                <div v-if="item.product_id" class="mt-3 flex items-center justify-between px-3 py-2 bg-white/50 rounded-xl border border-dashed border-slate-200">
                  <div class="text-[10px] font-bold text-slate-500">
                    Total: <span class="text-primary font-black">{{ item.quantity * item.pcs_per_unit }} PCS</span>
                    <span class="mx-2 text-slate-300">|</span>
                    Estimasi Berat: <span class="text-slate-900 font-black">{{ calculateItemWeight(item) }} KG</span>
                  </div>
                  <div v-if="item.original && item.quantity !== item.original_quantity" class="text-[10px] font-black text-orange-500 italic">
                    * Diubah dari permintaan asli ({{ item.original_quantity }})
                  </div>
                </div>
              </div>
            </div>

            <!-- Tonase Summary -->
            <div class="p-6 rounded-3xl border flex items-center justify-between" :class="isProcessOverWeight ? 'bg-red-50 border-red-100' : 'bg-emerald-50 border-emerald-100'">
              <div class="flex items-center gap-4">
                <div class="bg-white p-3 rounded-2xl shadow-sm">
                  <Scale class="h-6 w-6" :class="isProcessOverWeight ? 'text-red-500' : 'text-emerald-500'" />
                </div>
                <div>
                  <p class="text-[10px] font-bold uppercase tracking-widest" :class="isProcessOverWeight ? 'text-red-400' : 'text-emerald-400'">Total Tonase Pengiriman</p>
                  <p class="text-xl font-black" :class="isProcessOverWeight ? 'text-red-600' : 'text-emerald-900'">{{ totalProcessWeight.toFixed(2) }} KG</p>
                </div>
              </div>
              <div v-if="selectedProcessVehicle" class="text-right">
                <p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Kapasitas Armada</p>
                <p class="text-lg font-black text-slate-700">{{ selectedProcessVehicle.capacity }} KG</p>
              </div>
            </div>
            <div v-if="isProcessOverWeight" class="flex items-center gap-2 px-4 py-3 bg-red-100 text-red-600 rounded-2xl text-xs font-black uppercase tracking-widest animate-pulse">
               <AlertTriangle class="h-5 w-5" /> MELEBIHI KAPASITAS ARMADA! SESUAIKAN JUMLAH BARANG.
            </div>
          </div>

          <div class="space-y-2">
            <label class="text-sm font-bold text-slate-700 ml-1">Catatan Tambahan untuk SJ</label>
            <textarea v-model="processForm.notes" rows="2" placeholder="Informasi tambahan pengiriman..." class="w-full px-5 py-4 bg-slate-50 border border-slate-100 rounded-2xl text-sm outline-none resize-none"></textarea>
          </div>
        </CardContent>
        <CardFooter class="bg-slate-50/50 border-t p-8 flex flex-col md:flex-row justify-between items-center gap-4 shrink-0">
           <div class="text-[10px] font-bold text-slate-400 max-w-xs text-center md:text-left">
             Dengan menerbitkan SJ, stok pabrik akan terpotong dan status pengiriman akan berubah menjadi <span class="text-blue-600 font-black">SHIPPED</span>.
           </div>
           <div class="flex gap-4 w-full md:w-auto">
             <Button variant="ghost" @click="showProcessModal = false" class="rounded-2xl font-bold h-12 px-8">Batal</Button>
             <Button @click="handleConfirmProcess" :loading="processing" :disabled="isProcessOverWeight" class="rounded-2xl px-12 h-12 shadow-xl shadow-primary/20 font-black text-white bg-primary hover:bg-primary/90 disabled:opacity-50">
               Terbitkan SJ & Kirim
             </Button>
           </div>
        </CardFooter>
      </Card>
    </div>

    <!-- Manual Shipment Modal -->
    <div v-if="showManualModal" class="fixed inset-0 bg-slate-900/60 backdrop-blur-md z-[100] flex items-center justify-center p-4">
      <Card class="w-full max-w-3xl shadow-2xl rounded-[2.5rem] overflow-hidden border-none animate-in fade-in zoom-in-95 duration-300">
        <CardHeader class="p-8 border-b bg-white">
          <div class="flex justify-between items-center">
            <div>
              <CardTitle class="text-2xl font-black text-slate-900">Buat Surat Jalan Manual</CardTitle>
              <CardDescription>Kirim barang ke cabang tanpa melalui permintaan sistem.</CardDescription>
            </div>
            <Button variant="ghost" size="icon" @click="showManualModal = false" class="rounded-full">
              <Plus class="h-6 w-6 rotate-45 text-slate-400" />
            </Button>
          </div>
        </CardHeader>
        <CardContent class="p-8 space-y-6 bg-white max-h-[60vh] overflow-y-auto">
          <div class="grid grid-cols-2 gap-4">
            <div class="space-y-2">
              <label class="text-sm font-bold text-slate-700 ml-1">Dari Pabrik</label>
              <select v-model="manualShipmentForm.from_factory_id" class="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold outline-none">
                <option v-for="factory in factoryStore.factories" :key="factory.id" :value="factory.id">
                  {{ factory.name }}
                </option>
              </select>
            </div>
            <div class="space-y-2">
              <label class="text-sm font-bold text-slate-700 ml-1">Ke Cabang / Gudang</label>
              <select v-model="manualShipmentForm.to_branch_id" class="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold outline-none">
                <option value="" disabled>Pilih Cabang...</option>
                <option v-for="branch in masterDataStore.branches" :key="branch.id" :value="branch.id">
                  {{ branch.name }}
                </option>
              </select>
            </div>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div class="space-y-2">
              <label class="text-sm font-bold text-slate-700 ml-1 flex items-center gap-2">
                <Truck class="h-4 w-4 text-primary" /> Pilih Armada (Kendaraan)
              </label>
              <select v-model="manualShipmentForm.vehicle_id" class="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold outline-none">
                <option value="">Pilih Armada...</option>
                <option v-for="v in vehicleStore.vehicles" :key="v.id" :value="v.id">
                  {{ v.name }} ({{ v.license_plate }}) - Cap: {{ v.capacity }} KG
                </option>
              </select>
            </div>
            <div class="space-y-2">
              <label class="text-sm font-bold text-slate-700 ml-1 flex items-center gap-2">
                <User class="h-4 w-4 text-orange-500" /> Pilih Sopir (Driver)
              </label>
              <select v-model="manualShipmentForm.driver_id" class="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold outline-none">
                <option value="">Pilih Sopir...</option>
                <option v-for="e in masterDataStore.employees" :key="e.id" :value="e.id">
                  {{ e.first_name }} {{ e.last_name }}
                </option>
              </select>
            </div>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div class="space-y-2">
              <label class="text-sm font-bold text-slate-700 ml-1 flex items-center gap-2">
                <Calendar class="h-4 w-4 text-primary" /> Tanggal Pengiriman
              </label>
              <Input type="datetime-local" v-model="manualShipmentForm.target_shipment_date" class="rounded-2xl h-12" />
            </div>
            <div class="space-y-2">
              <label class="text-sm font-bold text-slate-700 ml-1 flex items-center gap-2">
                <Clock class="h-4 w-4 text-orange-500" /> Estimasi Sampai
              </label>
              <Input type="datetime-local" v-model="manualShipmentForm.estimated_arrival" class="rounded-2xl h-12" />
            </div>
          </div>

          <div class="space-y-4">
            <div class="flex justify-between items-center">
              <p class="text-[11px] font-black text-slate-400 uppercase tracking-widest ml-1">Daftar Item</p>
              <Button size="sm" variant="outline" @click="addManualItem" class="rounded-xl font-bold">
                <Plus class="h-4 w-4 mr-1" /> Tambah Item
              </Button>
            </div>
            
            <div class="space-y-3">
              <div v-for="(item, index) in manualShipmentForm.items" :key="index" class="flex gap-3 items-end bg-slate-50/50 p-4 rounded-2xl border border-slate-100">
                <div class="flex-1 space-y-1">
                  <label class="text-[10px] font-bold text-slate-400 uppercase">Produk</label>
                  <select v-model="item.product_id" class="w-full px-4 py-2.5 bg-white border border-slate-100 rounded-xl text-xs font-bold outline-none">
                    <option v-for="p in factoryStore.products" :key="p.id" :value="p.id">
                      {{ p.name }}
                    </option>
                  </select>
                  <div class="text-[9px] font-bold text-slate-400 mt-1" v-if="item.product_id">
                    Est. Berat: {{ 
                      (() => {
                        const p = factoryStore.products.find(prod => prod.id === item.product_id);
                        if (!p) return '0.00';
                        let w = p.weight * item.quantity * item.pcs_per_unit;
                        if (p.weight_unit?.toUpperCase() === 'GR' || p.weight_unit?.toUpperCase() === 'ML') w /= 1000;
                        return w.toFixed(2);
                      })()
                    }} KG
                  </div>
                </div>
                <div class="w-32 space-y-1">
                  <label class="text-[10px] font-bold text-slate-400 uppercase">Satuan</label>
                  <select v-model="item.unit" @change="item.unit === 'PCS' ? item.pcs_per_unit = 1 : null" class="w-full px-4 py-2.5 bg-white border border-slate-100 rounded-xl text-xs font-bold outline-none">
                    <option v-for="u in UNIT_OPTIONS" :key="u" :value="u">{{ u }}</option>
                  </select>
                </div>
                <div v-if="item.unit !== 'PCS'" class="w-24 space-y-1">
                  <label class="text-[10px] font-bold text-slate-400 uppercase">PCS / {{ item.unit }}</label>
                  <input type="number" v-model.number="item.pcs_per_unit" class="w-full px-4 py-2.5 bg-white border border-slate-100 rounded-xl text-xs font-bold outline-none" />
                </div>
                <div class="w-20 space-y-1">
                  <label class="text-[10px] font-bold text-slate-400 uppercase">Jumlah</label>
                  <input type="number" v-model.number="item.quantity" class="w-full px-4 py-2.5 bg-white border border-slate-100 rounded-xl text-xs font-bold outline-none" />
                </div>
                <Button variant="ghost" size="icon" class="text-destructive h-10 w-10 hover:bg-destructive/5" @click="removeManualItem(index)">
                  <Trash2 class="h-4 w-4" />
                </Button>
              </div>
            </div>

            <!-- Weight Calculation Summary -->
            <div class="p-4 rounded-2xl border flex items-center justify-between" :class="isOverWeight ? 'bg-red-50 border-red-100' : 'bg-slate-50 border-slate-100'">
              <div class="flex items-center gap-3">
                <div class="p-2 rounded-xl bg-white shadow-sm">
                  <Scale class="h-5 w-5" :class="isOverWeight ? 'text-red-500' : 'text-primary'" />
                </div>
                <div>
                  <p class="text-[10px] font-bold uppercase tracking-widest" :class="isOverWeight ? 'text-red-400' : 'text-slate-400'">Total Estimasi Tonase</p>
                  <p class="text-lg font-black" :class="isOverWeight ? 'text-red-600' : 'text-slate-900'">{{ totalManualWeight.toFixed(2) }} KG</p>
                </div>
              </div>
              <div v-if="selectedVehicle" class="text-right">
                <p class="text-[10px] font-bold text-slate-400 uppercase tracking-widest">Kapasitas Armada</p>
                <p class="text-lg font-black text-slate-700">{{ selectedVehicle.capacity }} KG</p>
              </div>
            </div>
            <div v-if="isOverWeight" class="flex items-center gap-2 px-4 py-2 bg-red-100 text-red-600 rounded-xl text-[10px] font-black uppercase tracking-widest animate-pulse">
               <AlertTriangle class="h-4 w-4" /> MELEBIHI KAPASITAS ARMADA!
            </div>
          </div>

          <div class="space-y-2">
            <label class="text-sm font-bold text-slate-700 ml-1">Catatan</label>
            <textarea v-model="manualShipmentForm.notes" rows="2" placeholder="Catatan untuk sopir atau gudang..." class="w-full px-5 py-4 bg-slate-50 border border-slate-100 rounded-2xl text-sm outline-none resize-none"></textarea>
          </div>
        </CardContent>
        <CardFooter class="bg-slate-50/50 border-t p-8 flex justify-end gap-4">
           <Button variant="ghost" @click="showManualModal = false" class="rounded-2xl font-bold h-12 px-8">Batal</Button>
           <Button @click="handleManualShipment" :loading="processing" :disabled="isOverWeight" class="rounded-2xl px-12 h-12 shadow-xl shadow-primary/20 font-black text-white bg-primary hover:bg-primary/90 disabled:opacity-50 disabled:cursor-not-allowed">
             Terbitkan Surat Jalan
           </Button>
        </CardFooter>
      </Card>
    </div>

    <!-- Edit Shipment Modal -->
    <div v-if="showEditModal" class="fixed inset-0 bg-slate-900/60 backdrop-blur-md z-[100] flex items-center justify-center p-4">
      <Card class="w-full max-w-3xl shadow-2xl rounded-[2.5rem] overflow-hidden border-none animate-in fade-in zoom-in-95 duration-300">
        <CardHeader class="p-8 border-b bg-white">
          <div class="flex justify-between items-center">
            <div>
              <CardTitle class="text-2xl font-black text-slate-900">Edit Pengiriman</CardTitle>
              <CardDescription>Ubah detail pengiriman ({{ selectedRequest?.doNo }}).</CardDescription>
            </div>
            <Button variant="ghost" size="icon" @click="showEditModal = false" class="rounded-full">
              <Plus class="h-6 w-6 rotate-45 text-slate-400" />
            </Button>
          </div>
        </CardHeader>
        <CardContent class="p-8 space-y-6 bg-white max-h-[70vh] overflow-y-auto">
          <div class="grid grid-cols-2 gap-4">
            <div class="space-y-2">
              <label class="text-sm font-bold text-slate-700 ml-1">Dari Pabrik</label>
              <select v-model="editForm.from_factory_id" class="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold outline-none">
                <option v-for="factory in factoryStore.factories" :key="factory.id" :value="factory.id">
                  {{ factory.name }}
                </option>
              </select>
            </div>
            <div class="space-y-2">
              <label class="text-sm font-bold text-slate-700 ml-1">Ke Cabang / Gudang</label>
              <select v-model="editForm.to_branch_id" class="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold outline-none">
                <option value="" disabled>Pilih Cabang...</option>
                <option v-for="branch in masterDataStore.branches" :key="branch.id" :value="branch.id">
                  {{ branch.name }}
                </option>
              </select>
            </div>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div class="space-y-2">
              <label class="text-sm font-bold text-slate-700 ml-1 flex items-center gap-2">
                <Truck class="h-4 w-4 text-primary" /> Pilih Armada (Kendaraan)
              </label>
              <select v-model="editForm.vehicle_id" class="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold outline-none">
                <option value="">Pilih Armada...</option>
                <option v-for="v in vehicleStore.vehicles" :key="v.id" :value="v.id">
                  {{ v.name }} ({{ v.license_plate }}) - Cap: {{ v.capacity }} KG
                </option>
              </select>
            </div>
            <div class="space-y-2">
              <label class="text-sm font-bold text-slate-700 ml-1 flex items-center gap-2">
                <User class="h-4 w-4 text-orange-500" /> Pilih Sopir (Driver)
              </label>
              <select v-model="editForm.driver_id" class="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold outline-none">
                <option value="">Pilih Sopir...</option>
                <option v-for="e in masterDataStore.employees" :key="e.id" :value="e.id">
                  {{ e.first_name }} {{ e.last_name }}
                </option>
              </select>
            </div>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div class="space-y-2">
              <label class="text-sm font-bold text-slate-700 ml-1 flex items-center gap-2">
                <Calendar class="h-4 w-4 text-primary" /> Tanggal Pengiriman
              </label>
              <Input type="datetime-local" v-model="editForm.target_shipment_date" class="rounded-2xl h-12" />
            </div>
            <div class="space-y-2">
              <label class="text-sm font-bold text-slate-700 ml-1 flex items-center gap-2">
                <Clock class="h-4 w-4 text-orange-500" /> Estimasi Sampai
              </label>
              <Input type="datetime-local" v-model="editForm.estimated_arrival" class="rounded-2xl h-12" />
            </div>
          </div>

          <div class="space-y-4">
             <div class="flex justify-between items-center">
                <p class="text-[11px] font-black text-slate-400 uppercase tracking-widest ml-1">Edit Item & Jumlah</p>
                <Button size="sm" variant="outline" @click="addEditItem" class="rounded-xl font-bold">
                  <Plus class="h-4 w-4 mr-1" /> Tambah Item
                </Button>
             </div>
             <div class="space-y-3">
                <div v-for="(item, index) in editForm.items" :key="index" class="flex items-end gap-3 bg-slate-50 p-4 rounded-2xl border border-slate-100">
                  <div class="flex-1 space-y-1">
                    <label class="text-[10px] font-bold text-slate-400 uppercase">Produk</label>
                    <select v-model="item.product_id" class="w-full px-4 py-2.5 bg-white border border-slate-100 rounded-xl text-xs font-bold outline-none">
                      <option v-for="p in factoryStore.products" :key="p.id" :value="p.id">{{ p.name }}</option>
                    </select>
                  </div>
                  <div class="w-28 space-y-1">
                    <label class="text-[10px] font-bold text-slate-400 uppercase">Unit</label>
                    <select v-model="item.unit" @change="item.unit === 'PCS' ? item.pcs_per_unit = 1 : null" class="w-full px-4 py-2.5 bg-white border border-slate-100 rounded-xl text-xs font-bold outline-none">
                      <option v-for="u in UNIT_OPTIONS" :key="u" :value="u">{{ u }}</option>
                    </select>
                  </div>
                  <div v-if="item.unit !== 'PCS'" class="w-24 space-y-1">
                    <label class="text-[10px] font-bold text-slate-400 uppercase">PCS / {{ item.unit }}</label>
                    <input type="number" v-model.number="item.pcs_per_unit" class="w-full px-4 py-2.5 bg-white border border-slate-100 rounded-xl text-xs font-bold outline-none" />
                  </div>
                  <div class="w-20 space-y-1">
                    <label class="text-[10px] font-bold text-slate-400 uppercase">Jumlah</label>
                    <input type="number" v-model.number="item.quantity" class="w-full px-4 py-2.5 bg-white border border-slate-100 rounded-xl text-xs font-bold outline-none" />
                  </div>
                  <Button variant="ghost" size="icon" class="text-destructive h-10 w-10 hover:bg-destructive/5" @click="removeEditItem(index)">
                    <Trash2 class="h-4 w-4" />
                  </Button>
                </div>
             </div>
          </div>

          <div class="space-y-2">
            <label class="text-sm font-bold text-slate-700 ml-1">Catatan</label>
            <textarea v-model="editForm.notes" rows="2" placeholder="Catatan untuk sopir atau gudang..." class="w-full px-5 py-4 bg-slate-50 border border-slate-100 rounded-2xl text-sm outline-none resize-none"></textarea>
          </div>
        </CardContent>
        <CardFooter class="bg-slate-50/50 border-t p-8 flex justify-end gap-4">
           <Button variant="ghost" @click="showEditModal = false" class="rounded-2xl font-bold h-12 px-8">Batal</Button>
           <Button @click="handleUpdateShipment" :loading="processing" class="rounded-2xl px-12 h-12 shadow-xl shadow-primary/20 font-black text-white bg-primary hover:bg-primary/90">
             Simpan Perubahan
           </Button>
        </CardFooter>
      </Card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref, computed, reactive } from 'vue'
import { useFactoryStore } from '@/stores/factory'
import { useMasterDataStore } from '@/stores/masterData'
import { useVehicleStore } from '@/stores/vehicle'
import { Button } from '@/components/ui/button'
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from '@/components/ui/card/index'
import { Badge } from '@/components/ui/badge'
import { 
  Truck, 
  Search, 
  RefreshCw, 
  Plus, 
  Printer, 
  MapPin, 
  Building2, 
  Package,
  Trash2,
  ArrowRight,
  Calendar,
  Clock,
  User,
  Scale,
  AlertTriangle
} from 'lucide-vue-next'
import { toast } from 'vue-sonner'

const factoryStore = useFactoryStore()
const masterDataStore = useMasterDataStore()
const vehicleStore = useVehicleStore()
const searchQuery = ref('')
const showProcessModal = ref(false)
const showManualModal = ref(false)
const processing = ref(false)
const selectedRequest = ref<any>(null)

const processForm = reactive({
  factory_id: '',
  notes: '',
  vehicle_id: '',
  driver_id: '',
  target_shipment_date: '',
  estimated_arrival: '',
  items: [] as any[]
})

const manualShipmentForm = reactive({
  from_factory_id: '',
  to_branch_id: '',
  notes: '',
  target_shipment_date: '',
  estimated_arrival: '',
  vehicle_id: '',
  driver_id: '',
  items: [] as any[]
})

const addProcessItem = () => {
  processForm.items.push({
    product_id: '',
    quantity: 1,
    unit: 'PCS',
    pcs_per_unit: 1,
    original: false
  })
}

const removeProcessItem = (index: number) => {
  processForm.items.splice(index, 1)
}

const calculateItemWeight = (item: any) => {
  const product = factoryStore.products.find(p => p.id === item.product_id)
  if (!product) return '0.00'
  let weight = product.weight * item.quantity * item.pcs_per_unit
  if (product.weight_unit?.toUpperCase() === 'GR' || product.weight_unit?.toUpperCase() === 'ML') weight /= 1000
  return weight.toFixed(2)
}

const UNIT_OPTIONS = ['KARTON', 'DUS', 'BOX', 'KRAT', 'PCS', 'BAL', 'PACK', 'KG', 'GRAM', 'SACHET', 'JERIGEN', 'BOTOL']

const addManualItem = () => {
  manualShipmentForm.items.push({
    product_id: '',
    quantity: 1,
    unit: 'PCS',
    pcs_per_unit: 1
  })
}

const removeManualItem = (index: number) => {
  manualShipmentForm.items.splice(index, 1)
}

const openManualShipmentModal = () => {
  manualShipmentForm.items = [{ product_id: '', quantity: 1, unit: 'PCS', pcs_per_unit: 1 }]
  manualShipmentForm.notes = ''
  manualShipmentForm.vehicle_id = ''
  manualShipmentForm.driver_id = ''
  
  if (factoryStore.factories && factoryStore.factories.length > 0) {
    manualShipmentForm.from_factory_id = factoryStore.factories[0]?.id || ''
  }
  
  showManualModal.value = true
}

const formatToRFC3339 = (dateStr: string) => {
  if (!dateStr) return null
  // If it's already in a long format, return as is
  if (dateStr.length > 16) return dateStr
  // Append seconds and a simple Z or local offset
  // For simplicity and to match local intent, we'll append :00Z but ideally we'd use a real date object
  const date = new Date(dateStr)
  return date.toISOString()
}

const handleManualShipment = async () => {
  if (!manualShipmentForm.from_factory_id || !manualShipmentForm.to_branch_id || manualShipmentForm.items.length === 0) {
    toast.error('Mohon lengkapi data pengiriman.')
    return
  }

  processing.value = true
  try {
    await factoryStore.sendToBranch(manualShipmentForm.from_factory_id, {
      to_branch_id: manualShipmentForm.to_branch_id,
      items: manualShipmentForm.items,
      notes: manualShipmentForm.notes,
      target_shipment_date: formatToRFC3339(manualShipmentForm.target_shipment_date),
      estimated_arrival: formatToRFC3339(manualShipmentForm.estimated_arrival),
      vehicle_id: manualShipmentForm.vehicle_id || null,
      driver_id: manualShipmentForm.driver_id || null,
      initiated_by: 'FACTORY'
    })
    
    // Auto-ship if the user wants? No, let's keep it as REQUESTED first 
    // so they can see it in the list and then click "Proses" to generate the real SJ.
    // Or just make it SHIPPED immediately? 
    // Usually manual shipment means they are shipping it NOW.
    
    toast.success('Pengiriman manual berhasil dibuat.')
    showManualModal.value = false
    await factoryStore.fetchAllTransfers()
  } catch (err) {
    toast.error('Gagal membuat pengiriman: ' + err)
  } finally {
    processing.value = false
  }
}

onMounted(() => {
  factoryStore.fetchAllTransfers()
  factoryStore.fetchFactories()
  factoryStore.fetchProducts()
  masterDataStore.fetchBranches()
  masterDataStore.fetchEmployees()
  vehicleStore.fetchVehicles()
})

const totalManualWeight = computed(() => {
  return manualShipmentForm.items.reduce((total, item) => {
    const product = factoryStore.products.find(p => p.id === item.product_id)
    if (!product) return total
    let weight = product.weight * item.quantity * item.pcs_per_unit
    if (product.weight_unit?.toUpperCase() === 'GR' || product.weight_unit?.toUpperCase() === 'ML') {
      weight /= 1000
    } else if (product.weight_unit?.toUpperCase() === 'TON') {
      weight *= 1000
    }
    return total + weight
  }, 0)
})

const selectedVehicle = computed(() => {
  return vehicleStore.vehicles.find(v => v.id === manualShipmentForm.vehicle_id)
})

const isOverWeight = computed(() => {
  if (!selectedVehicle.value || selectedVehicle.value.capacity === 0) return false
  return totalManualWeight.value > selectedVehicle.value.capacity
})

const totalProcessWeight = computed(() => {
  return processForm.items.reduce((total, item) => {
    return total + parseFloat(calculateItemWeight(item))
  }, 0)
})

const selectedProcessVehicle = computed(() => {
  return vehicleStore.vehicles.find(v => v.id === processForm.vehicle_id)
})

const isProcessOverWeight = computed(() => {
  if (!selectedProcessVehicle.value || selectedProcessVehicle.value.capacity === 0) return false
  return totalProcessWeight.value > selectedProcessVehicle.value.capacity
})

const groupedTransfers = computed(() => {
  const groups: Record<string, any> = {}
  
  factoryStore.allTransfers.forEach(item => {
    const doNo = item.delivery_order_no || 'DRAFT-' + item.id.substring(0, 8)
    if (!groups[doNo]) {
      groups[doNo] = {
        doNo,
        from: item.from_factory?.name,
        to: item.to_branch?.name,
        totalWeight: 0,
        status: item.status,
        items: []
      }
    }
    groups[doNo].items.push(item)
    groups[doNo].totalWeight += item.total_weight
  })
  
  return Object.values(groups).sort((a, b) => b.doNo.localeCompare(a.doNo))
})

const incomingRequests = computed(() => {
  // Requests from Branch that need Factory approval OR have been approved but not yet shipped
  return groupedTransfers.value.filter(g => 
    (g.status === 'REQUESTED' || g.status === 'APPROVED' || g.status === 'REJECTED') && 
    g.items[0]?.initiated_by === 'BRANCH'
  )
})

const processedShipments = computed(() => {
  // Shipments that this factory initiated or have been shipped/received
  return groupedTransfers.value.filter(g => {
    // Show if factory initiated (regardless of status)
    const isFactoryInitiated = g.items[0]?.initiated_by === 'FACTORY'
    // Show if it's already in transit or completed
    const isInTransitOrDone = g.status === 'SHIPPED' || g.status === 'ARRIVED' || g.status === 'RECEIVED'
    
    return isFactoryInitiated || isInTransitOrDone
  }).filter(g => {
    if (!searchQuery.value) return true
    return g.doNo.toLowerCase().includes(searchQuery.value.toLowerCase())
  })
})

const showEditModal = ref(false)
const editForm = reactive({
  notes: '',
  target_shipment_date: '',
  estimated_arrival: '',
  vehicle_id: '',
  driver_id: '',
  from_factory_id: '',
  to_branch_id: '',
  items: [] as any[]
})

const addEditItem = () => {
  editForm.items.push({
    product_id: '',
    quantity: 1,
    unit: 'PCS',
    pcs_per_unit: 1
  })
}

const removeEditItem = (index: number) => {
  editForm.items.splice(index, 1)
}

const openEditModal = (group: any) => {
  selectedRequest.value = group
  const firstItem = group.items[0]
  editForm.notes = firstItem.notes || ''
  editForm.target_shipment_date = firstItem.target_shipment_date ? new Date(firstItem.target_shipment_date).toISOString().slice(0, 16) : ''
  editForm.estimated_arrival = firstItem.estimated_arrival ? new Date(firstItem.estimated_arrival).toISOString().slice(0, 16) : ''
  editForm.vehicle_id = firstItem.vehicle_id || ''
  editForm.driver_id = firstItem.driver_id || ''
  editForm.from_factory_id = firstItem.from_factory_id || ''
  editForm.to_branch_id = firstItem.to_branch_id || ''
  
  editForm.items = group.items.map((item: any) => ({
    id: item.id,
    product_id: item.product_id,
    quantity: item.quantity,
    unit: item.unit || 'PCS',
    pcs_per_unit: item.pcs_per_unit || 1
  }))
  
  showEditModal.value = true
}

const handleUpdateShipment = async () => {
  processing.value = true
  try {
    // 1. Identify removed items
    const currentItemIds = editForm.items.filter(i => i.id).map(i => i.id)
    const removedItems = selectedRequest.value.items.filter((i: any) => !currentItemIds.includes(i.id))
    
    for (const item of removedItems) {
      await factoryStore.deleteTransfer(item.id)
    }

    // 2. Update existing or create new items
    for (const item of editForm.items) {
      const payload = {
        product_id: item.product_id,
        quantity: item.quantity,
        unit: item.unit,
        pcs_per_unit: item.pcs_per_unit,
        notes: editForm.notes,
        target_shipment_date: editForm.target_shipment_date || null,
        estimated_arrival: editForm.estimated_arrival || null,
        vehicle_id: editForm.vehicle_id || null,
        driver_id: editForm.driver_id || null,
        from_factory_id: editForm.from_factory_id || null,
        to_branch_id: editForm.to_branch_id || null,
        status: 'REQUESTED', 
        rejection_reason: '',
        initiated_by: 'FACTORY',
        delivery_order_no: selectedRequest.value.doNo
      }

      if (item.id) {
        await factoryStore.updateTransfer(item.id, payload)
      } else {
        await factoryStore.createTransfer(payload)
      }
    }
    toast.success('Pengiriman berhasil diperbarui.')
    showEditModal.value = false
    await factoryStore.fetchAllTransfers()
  } catch (err) {
    toast.error('Gagal memperbarui pengiriman: ' + err)
  } finally {
    processing.value = false
  }
}

const handleDeleteShipment = async (group: any) => {
  if (!confirm(`Apakah Anda yakin ingin menghapus pengiriman ${group.doNo}?`)) return
  
  processing.value = true
  try {
    for (const item of group.items) {
      await factoryStore.deleteTransfer(item.id)
    }
    toast.success('Pengiriman berhasil dihapus.')
    await factoryStore.fetchAllTransfers()
  } catch (err) {
    toast.error('Gagal menghapus pengiriman: ' + err)
  } finally {
    processing.value = false
  }
}

const processShipment = (request: any) => {
  selectedRequest.value = request
  processForm.notes = request.items[0]?.notes || ''
  processForm.vehicle_id = request.items[0]?.vehicle_id || ''
  processForm.driver_id = request.items[0]?.driver_id || ''
  processForm.target_shipment_date = request.items[0]?.target_shipment_date?.split('T')[0] || ''
  processForm.estimated_arrival = request.items[0]?.estimated_arrival?.split('T')[0] || ''
  
  // Clone items for adjustment
  processForm.items = request.items.map((item: any) => ({
    id: item.id,
    product_id: item.product_id,
    quantity: item.quantity,
    unit: item.unit || 'PCS',
    pcs_per_unit: item.pcs_per_unit || 1,
    original_quantity: item.quantity,
    original: true
  }))

  if (factoryStore.factories && factoryStore.factories.length > 0) {
    processForm.factory_id = factoryStore.factories[0]?.id || ''
  }
  showProcessModal.value = true
}

const handleConfirmProcess = async () => {
  if (!processForm.factory_id) {
    toast.error('Pilih pabrik pengirim')
    return
  }

  processing.value = true
  try {
    // 1. Update each existing item with potential adjustments and Penugasan Logistik
    // 2. Add new items if any
    
    // First, handle updates to original items
    const originalItems = processForm.items.filter(i => i.original)
    for (const item of originalItems) {
      await factoryStore.updateTransfer(item.id, {
        status: 'APPROVED',
        quantity: item.quantity,
        unit: item.unit,
        pcs_per_unit: item.pcs_per_unit,
        notes: processForm.notes,
        target_shipment_date: formatToRFC3339(processForm.target_shipment_date),
        estimated_arrival: formatToRFC3339(processForm.estimated_arrival),
        vehicle_id: processForm.vehicle_id || null,
        driver_id: processForm.driver_id || null,
        from_factory_id: processForm.factory_id
      })
    }

    // Handle new items added by factory
    const newItems = processForm.items.filter(i => !i.original)
    if (newItems.length > 0) {
      await factoryStore.sendToBranch(processForm.factory_id, {
        to_branch_id: selectedRequest.value.items[0].to_branch_id,
        items: newItems,
        notes: processForm.notes,
        target_shipment_date: formatToRFC3339(processForm.target_shipment_date),
        estimated_arrival: formatToRFC3339(processForm.estimated_arrival),
        vehicle_id: processForm.vehicle_id || null,
        driver_id: processForm.driver_id || null,
        delivery_order_no: selectedRequest.value.doNo,
        initiated_by: 'FACTORY',
        status: 'APPROVED'
      })
    }

    // 3. Execute shipment for all items in this group (original + potential new ones)
    // We need to re-fetch to get all IDs including new ones if we want to ship them all at once.
    // Or just ship the original ones and the new ones will be shipped separately?
    // Let's re-fetch to be sure.
    toast.success('Draft Surat Jalan berhasil diterbitkan. Menunggu konfirmasi kesiapan Gudang.')
    showProcessModal.value = false
    await factoryStore.fetchAllTransfers()
  } catch (err) {
    toast.error('Gagal memproses pengiriman: ' + err)
  } finally {
    processing.value = false
  }
}



const handleApproveRequest = async (request: any) => {
  if (!confirm('Setujui permintaan barang dari cabang ini?')) return
  
  processing.value = true
  try {
    for (const item of request.items) {
      await factoryStore.approveTransfer(item.id)
    }
    toast.success('Permintaan telah disetujui.')
    await factoryStore.fetchAllTransfers()
  } catch (err) {
    toast.error('Gagal menyetujui permintaan: ' + err)
  } finally {
    processing.value = false
  }
}

const getStatusClass = (status: string) => {
  switch (status) {
    case 'RECEIVED': return 'bg-emerald-50 text-emerald-600 border-emerald-100'
    case 'ARRIVED': return 'bg-cyan-50 text-cyan-600 border-cyan-100'
    case 'SHIPPED': return 'bg-blue-50 text-blue-600 border-blue-100'
    case 'REQUESTED': return 'bg-orange-50 text-orange-600 border-orange-100'
    case 'APPROVED': return 'bg-emerald-50 text-emerald-700 border-emerald-200 shadow-sm'
    case 'REJECTED': return 'bg-rose-50 text-rose-600 border-rose-100 shadow-sm'
    default: return 'bg-slate-50 text-slate-500 border-slate-100'
  }
}
</script>

<style scoped>
.custom-scrollbar::-webkit-scrollbar {
  width: 6px;
}
.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background: #e2e8f0;
  border-radius: 10px;
}
</style>
