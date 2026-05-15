<template>
  <div class="p-8 space-y-8 bg-[#f8fafc] min-h-screen">
    <!-- Header -->
    <div class="flex flex-col md:flex-row justify-between items-start md:items-center gap-6 bg-white p-8 rounded-[2.5rem] shadow-sm border border-slate-100">
      <div class="flex items-center gap-5">
        <div class="w-16 h-16 rounded-[2rem] bg-slate-900 flex items-center justify-center text-white shadow-xl shadow-slate-200">
          <Warehouse v-if="activeTab === 'stock'" class="h-8 w-8" />
          <Truck v-else-if="activeTab === 'inbound'" class="h-8 w-8" />
          <History v-else class="h-8 w-8" />
        </div>
        <div>
          <h1 class="text-3xl font-black tracking-tight text-slate-900">
            {{ activeTab === 'stock' ? 'Persediaan Gudang' : activeTab === 'inbound' ? 'Penerimaan Barang' : 'Riwayat Pengiriman' }}
          </h1>
          <p class="text-sm text-slate-500 font-medium mt-1">
            {{ activeTab === 'stock' ? 'Pantau dan kelola stok produk fisik di cabang.' : activeTab === 'inbound' ? 'Konfirmasi barang masuk dari pabrik atau cabang.' : 'Lihat seluruh logistik masuk yang telah diterima.' }}
          </p>
        </div>
      </div>
      
      <div class="flex flex-wrap gap-3">
        <div class="flex bg-slate-100 p-1.5 rounded-2xl border border-slate-200/60 shadow-inner">
          <button 
            @click="activeTab = 'stock'"
            :class="[activeTab === 'stock' ? 'bg-white shadow-md text-primary' : 'text-slate-500 hover:text-slate-700']"
            class="px-6 py-2.5 rounded-xl text-xs font-black uppercase tracking-wider transition-all flex items-center gap-2"
          >
            <Boxes class="h-4 w-4" /> Stok
          </button>
          <button 
            @click="activeTab = 'inbound'"
            :class="[activeTab === 'inbound' ? 'bg-white shadow-md text-primary' : 'text-slate-500 hover:text-slate-700']"
            class="px-6 py-2.5 rounded-xl text-xs font-black uppercase tracking-wider transition-all flex items-center gap-2 relative"
          >
            <Truck class="h-4 w-4" /> Inbound
            <span v-if="groupedPending.length > 0" class="absolute -top-1 -right-1 flex h-4 w-4">
              <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-rose-400 opacity-75"></span>
              <span class="relative inline-flex rounded-full h-4 w-4 bg-rose-500 text-[9px] items-center justify-center text-white font-black leading-none">{{ groupedPending.length }}</span>
            </span>
          </button>
          <button 
            @click="activeTab = 'history'"
            :class="[activeTab === 'history' ? 'bg-white shadow-md text-primary' : 'text-slate-500 hover:text-slate-700']"
            class="px-6 py-2.5 rounded-xl text-xs font-black uppercase tracking-wider transition-all flex items-center gap-2"
          >
            <History class="h-4 w-4" /> Riwayat
          </button>
        </div>

        <div class="flex gap-2">
          <Button variant="outline" class="rounded-2xl h-12 px-6 font-bold border-slate-200" @click="refreshAll" :loading="warehouseStore.loading">
            <RefreshCw class="h-4 w-4" :class="{ 'animate-spin': warehouseStore.loading }" />
          </Button>
          <Button @click="showScanner = true" class="rounded-2xl h-12 px-8 bg-slate-900 hover:bg-slate-800 text-white font-black shadow-xl shadow-slate-200 flex gap-3">
            <ScanLine class="h-5 w-5 text-primary" /> SCAN SJ
          </Button>
        </div>
      </div>
    </div>

    <!-- Main Content -->
    <div class="space-y-6">
      
      <!-- TAB: STOCK -->
      <div v-if="activeTab === 'stock'" class="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
        <div class="grid grid-cols-1 md:grid-cols-4 gap-6">
          <Card class="border-none shadow-sm bg-white rounded-3xl p-6 relative overflow-hidden group">
            <div class="absolute right-0 top-0 p-4 opacity-5 group-hover:scale-110 transition-transform">
              <Boxes class="h-16 w-16 text-primary" />
            </div>
            <p class="text-xs font-black text-slate-400 uppercase tracking-[0.2em]">Total SKU</p>
            <h3 class="text-3xl font-black text-slate-900 mt-2">{{ warehouseStore.inventory.length }}</h3>
            <div class="mt-4 flex items-center text-[10px] font-bold text-emerald-600 bg-emerald-50 w-fit px-3 py-1 rounded-full">
              TERDATA AKTIF
            </div>
          </Card>

          <Card class="border-none shadow-sm bg-white rounded-3xl p-6 relative overflow-hidden group">
             <div class="absolute right-0 top-0 p-4 opacity-5 group-hover:scale-110 transition-transform">
              <AlertCircle class="h-16 w-16 text-rose-500" />
            </div>
            <p class="text-xs font-black text-slate-400 uppercase tracking-[0.2em]">Low Stock</p>
            <h3 class="text-3xl font-black text-rose-600 mt-2">
              {{ warehouseStore.inventory.filter(i => i.quantity < (i.min_limit || 0)).length }}
            </h3>
            <div class="mt-4 flex items-center text-[10px] font-bold text-rose-600 bg-rose-50 w-fit px-3 py-1 rounded-full">
              PERLU RESTOCK
            </div>
          </Card>

          <div class="md:col-span-2 flex gap-4">
             <Card @click="showRequestModal = true" class="flex-1 border-none shadow-sm bg-primary text-white rounded-3xl p-6 cursor-pointer hover:scale-[1.02] transition-all group relative overflow-hidden">
                <div class="relative z-10">
                  <h3 class="text-lg font-black">Request Barang</h3>
                  <p class="text-primary-foreground/70 text-xs mt-1">Ajukan penambahan stok ke pabrik.</p>
                  <Button size="sm" variant="secondary" class="mt-4 rounded-xl font-bold bg-white text-primary">Buat Request</Button>
                </div>
                <ArrowUpRight class="absolute -right-4 -bottom-4 w-32 h-32 text-white/10 rotate-12" />
             </Card>
             <Card @click="showAdjustment = true" class="flex-1 border-none shadow-sm bg-white border border-slate-100 rounded-3xl p-6 cursor-pointer hover:scale-[1.02] transition-all group relative overflow-hidden">
                <div class="relative z-10">
                  <h3 class="text-lg font-black text-slate-900">Stock Opname</h3>
                  <p class="text-slate-500 text-xs mt-1">Sesuaikan stok fisik yang selisih.</p>
                  <Button size="sm" variant="outline" class="mt-4 rounded-xl font-bold border-slate-200">Adjust Stok</Button>
                </div>
                <Scale class="absolute -right-4 -bottom-4 w-32 h-32 text-slate-50 rotate-12" />
             </Card>
          </div>
        </div>

        <Card class="border-none shadow-xl shadow-slate-200/50 bg-white rounded-[2.5rem] overflow-hidden border border-slate-100">
          <div class="p-8 border-b border-slate-50 flex flex-col md:flex-row justify-between gap-4">
             <div class="relative w-full md:w-96">
                <Search class="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
                <input 
                  v-model="stockSearch" 
                  placeholder="Cari produk atau batch..." 
                  class="w-full pl-12 pr-4 py-3 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold outline-none focus:ring-2 focus:ring-primary/20 transition-all"
                />
             </div>
             <div class="flex items-center gap-2">
                <Badge variant="outline" class="rounded-lg px-3 py-1.5 border-slate-200 text-slate-500 font-bold">
                  {{ filteredInventory.length }} Produk Ditampilkan
                </Badge>
             </div>
          </div>
          <div class="p-0">
            <DataTable :columns="stockColumns" :data="filteredInventory" />
          </div>
        </Card>
      </div>

      <!-- TAB: INBOUND -->
      <div v-else-if="activeTab === 'inbound'" class="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
        
        <!-- PRINT AREA -->
        <div class="print-only hidden print:block">
          <SuratJalanPrint v-if="shipmentToPrint" :shipment="shipmentToPrint" class="hidden print:block" />
        </div>

        <div v-if="groupedPending.length === 0" class="bg-white rounded-[3rem] p-20 text-center border-2 border-dashed border-slate-100 animate-in fade-in zoom-in duration-700">
           <div class="w-24 h-24 bg-slate-50 rounded-[2.5rem] flex items-center justify-center mx-auto mb-6">
             <PackageSearch class="h-10 w-10 text-slate-300" />
           </div>
           <h3 class="text-xl font-black text-slate-900">Belum Ada Antrian Inbound</h3>
           <p class="text-sm text-slate-400 mt-2 max-w-xs mx-auto">Tidak ada pengiriman atau permintaan yang memerlukan tindakan. Pastikan Anda telah memilih <b>Cabang (Branch)</b> yang benar di navigasi atas.</p>
           <Button @click="refreshAll" variant="outline" class="mt-8 rounded-2xl px-12 h-14 font-black border-slate-200 hover:bg-slate-50">Refresh Antrian</Button>
        </div>

        <Card v-else class="border-none shadow-xl shadow-slate-200/50 bg-white rounded-[2.5rem] overflow-hidden border border-slate-100">
          <DataTable :columns="inboundColumns" :data="groupedPending">
            <template #cell-doNo="{ row }">
               <div class="flex items-center gap-3">
                  <div class="w-10 h-10 rounded-xl bg-slate-50 flex items-center justify-center">
                    <Truck v-if="row.status === 'SHIPPED'" class="h-5 w-5 text-blue-600" />
                    <MapPin v-else-if="row.status === 'ARRIVED'" class="h-5 w-5 text-emerald-600" />
                    <ClipboardList v-else class="h-5 w-5 text-orange-600" />
                  </div>
                  <span class="font-black text-slate-900">{{ row.doNo }}</span>
               </div>
            </template>

            <template #cell-from="{ row }">
               <div class="flex items-center text-xs font-bold text-slate-600">
                  <Factory class="mr-2 h-3.5 w-3.5 text-slate-300" /> {{ row.from }}
               </div>
            </template>

            <template #cell-status="{ row }">
               <Badge :variant="row.status === 'SHIPPED' ? 'default' : row.status === 'ARRIVED' ? 'success' : 'secondary'" class="rounded-lg text-[9px] font-black uppercase px-2.5 h-6">
                  {{ formatStatus(row.status) }}
               </Badge>
            </template>

            <template #cell-totalQty="{ row }">
               <span class="font-black text-slate-900">{{ row.totalQty }} <span class="text-[10px] text-slate-400">Unit</span></span>
            </template>

            <template #cell-totalWeight="{ row }">
               <span class="font-black text-slate-900">{{ row.totalWeight.toFixed(2) }} <span class="text-[10px] text-slate-400">KG</span></span>
            </template>

            <template #cell-targetDate="{ row }">
               <div class="space-y-1 text-[11px] font-bold">
                  <div v-if="row.targetDate" class="flex items-center gap-1.5 text-blue-600">
                    <Calendar class="h-3 w-3" /> {{ new Date(row.targetDate).toLocaleDateString('id-ID', {day:'2-digit', month:'short'}) }}
                  </div>
                  <div v-if="row.eta" class="flex items-center gap-1.5 text-emerald-600">
                    <Clock class="h-3 w-3" /> {{ new Date(row.eta).toLocaleDateString('id-ID', {day:'2-digit', month:'short'}) }}, {{ new Date(row.eta).toLocaleTimeString('id-ID', {hour:'2-digit', minute:'2-digit'}) }}
                  </div>
               </div>
            </template>

            <template #cell-actions="{ row }">
               <div class="flex items-center gap-2">
                  <template v-if="row.status === 'SHIPPED'">
                    <Button @click="handleArrive(row)" :loading="processingId === row.doNo" size="sm" class="rounded-xl h-9 font-bold bg-blue-600 hover:bg-blue-700 text-white px-4 text-[10px]">
                      KONFIRMASI TIBA
                    </Button>
                    <Button @click="handleReject(row)" variant="ghost" size="sm" class="rounded-xl h-9 font-bold text-slate-400 hover:text-rose-600 px-3">Tolak</Button>
                  </template>
                  <template v-else-if="row.status === 'ARRIVED'">
                    <Button @click="handleReceive(row)" :loading="processingId === row.doNo" size="sm" class="rounded-xl h-9 font-black bg-emerald-600 hover:bg-emerald-700 text-white px-4 text-[10px]">
                      TERIMA BARANG
                    </Button>
                  </template>
                  <template v-else-if="row.status === 'APPROVED'">
                    <Button v-if="row.vehicle || row.driver" @click="handleConfirmSJ(row)" :loading="processingId === row.doNo" size="sm" class="rounded-xl h-9 font-black bg-emerald-600 hover:bg-emerald-700 text-white px-4 text-[10px]">
                      SETUJUI SJ
                    </Button>
                    <div v-else class="text-[9px] font-bold text-amber-500 bg-amber-50 px-3 py-1.5 rounded-lg border border-amber-100">
                      Menunggu Armada
                    </div>
                  </template>
                  <template v-else-if="row.status === 'REQUESTED' && row.items[0]?.initiated_by === 'FACTORY'">
                    <Button @click="handleApprove(row)" size="sm" class="rounded-xl h-9 font-bold bg-white text-orange-600 border border-orange-100 hover:bg-orange-50 px-4 text-[10px]">SETUJUI</Button>
                    <Button @click="handleReject(row)" variant="ghost" size="sm" class="rounded-xl h-9 font-bold text-slate-400 hover:text-rose-600 px-3">Tolak</Button>
                  </template>
                  <span v-else class="text-[10px] font-black text-slate-300 uppercase tracking-widest">Pending</span>
                  
                  <Button @click="printShipment(row)" variant="ghost" size="icon" class="rounded-xl h-9 w-9 text-slate-400 hover:text-slate-600 hover:bg-slate-50 border border-slate-100">
                    <Printer class="h-4 w-4" />
                  </Button>
               </div>
            </template>
          </DataTable>
        </Card>
      </div>

      <!-- TAB: HISTORY -->
      <div v-else-if="activeTab === 'history'" class="space-y-6 animate-in fade-in slide-in-from-bottom-4 duration-500">
        <Card class="border-none shadow-xl shadow-slate-200/50 bg-white rounded-[2.5rem] overflow-hidden border border-slate-100">
           <DataTable :columns="historyColumns" :data="filteredHistory">
             <template #cell-doNo="{ row }">
                <div class="flex items-center gap-3">
                   <div class="w-10 h-10 rounded-xl bg-emerald-50 flex items-center justify-center text-emerald-600 shadow-sm border border-emerald-100/50">
                     <CheckCircle2 class="h-5 w-5" />
                   </div>
                   <span class="font-black text-slate-900">{{ row.doNo }}</span>
                </div>
             </template>
             <template #cell-from="{ row }">
                <div class="flex items-center text-xs font-bold text-slate-600 uppercase tracking-widest">
                   <Factory class="h-3.5 w-3.5 mr-2 text-slate-300" /> {{ row.from }}
                </div>
             </template>
             <template #cell-receivedAt="{ row }">
                <div class="flex flex-col text-[11px] font-bold text-slate-500 uppercase">
                   <span class="flex items-center gap-1.5"><Calendar class="h-3 w-3" /> {{ new Date(row.receivedAt).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' }) }}</span>
                   <span class="flex items-center gap-1.5"><Clock class="h-3 w-3" /> {{ new Date(row.receivedAt).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }) }}</span>
                </div>
             </template>
             <template #cell-totalWeight="{ row }">
                <span class="text-lg font-black text-slate-900">{{ row.totalWeight.toFixed(2) }} <span class="text-[10px] font-normal text-slate-400">KG</span></span>
             </template>
             <template #cell-items="{ row }">
                <div class="flex -space-x-2">
                   <div v-for="item in row.items.slice(0, 3)" :key="item.id" class="inline-block h-8 w-8 rounded-lg ring-2 ring-white bg-slate-100 flex items-center justify-center text-[10px] font-black text-slate-600 border border-slate-200 shadow-sm">
                     {{ item.product?.name?.charAt(0) }}
                   </div>
                   <div v-if="row.items.length > 3" class="inline-block h-8 w-8 rounded-lg ring-2 ring-white bg-slate-900 flex items-center justify-center text-[8px] font-black text-white shadow-lg">
                     +{{ row.items.length - 3 }}
                   </div>
                </div>
             </template>
           </DataTable>
        </Card>
      </div>
    </div>

    <!-- Modals (Adjustment, Request, Scanner) - Re-used from original but styled better -->
    <div v-if="showAdjustment" class="fixed inset-0 bg-slate-900/60 backdrop-blur-md z-[100] flex items-center justify-center p-4">
       <Card class="w-full max-w-lg shadow-2xl rounded-[2.5rem] overflow-hidden border-none animate-in zoom-in-95 duration-300">
         <CardHeader class="p-8 border-b bg-white">
            <div class="flex justify-between items-center">
              <div>
                <CardTitle class="text-2xl font-black text-slate-900">Stock Opname</CardTitle>
                <CardDescription>Sesuaikan jumlah fisik produk di gudang.</CardDescription>
              </div>
              <Button variant="ghost" size="icon" @click="showAdjustment = false" class="rounded-full">
                <Plus class="h-6 w-6 rotate-45 text-slate-400" />
              </Button>
            </div>
         </CardHeader>
         <CardContent class="p-8 space-y-6 bg-white">
            <div class="space-y-2">
              <label class="text-sm font-bold text-slate-700 ml-1">Pilih Produk & Batch</label>
              <select v-model="adjustForm.selectedItem" class="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold outline-none appearance-none cursor-pointer">
                <option :value="null" disabled>Pilih Produk...</option>
                <option v-for="item in warehouseStore.inventory" :key="item.id" :value="item">
                  {{ item.product?.name }} - Batch: {{ item.batch_no }} (Saat ini: {{ item.quantity }})
                </option>
              </select>
            </div>
            <div class="grid grid-cols-2 gap-4">
               <div class="space-y-2">
                <label class="text-sm font-bold text-slate-700 ml-1">Jumlah Fisik Baru</label>
                <div class="relative">
                  <input type="number" v-model.number="adjustForm.quantity" class="w-full px-5 py-4 bg-slate-50 border border-slate-100 rounded-2xl text-xl font-black outline-none focus:ring-2 focus:ring-primary/20 transition-all" />
                  <div class="absolute right-4 top-4 text-[10px] font-black text-slate-400 uppercase">Input Fisik</div>
                </div>
              </div>
              <div class="space-y-2 opacity-50">
                <label class="text-sm font-bold text-slate-700 ml-1">Selisih</label>
                <div class="w-full px-5 py-4 bg-slate-100 border border-slate-200 rounded-2xl text-xl font-black flex items-center">
                   {{ adjustForm.selectedItem ? adjustForm.quantity - adjustForm.selectedItem.quantity : 0 }}
                </div>
              </div>
            </div>
            <div class="space-y-2">
              <label class="text-sm font-bold text-slate-700 ml-1">Alasan Penyesuaian</label>
              <textarea v-model="adjustForm.reason" rows="3" placeholder="Contoh: Barang rusak, selisih hitung rutin..." class="w-full px-5 py-4 bg-slate-50 border border-slate-100 rounded-2xl text-sm outline-none resize-none focus:ring-2 focus:ring-primary/20"></textarea>
            </div>
         </CardContent>
         <CardFooter class="bg-slate-50/50 border-t p-8 flex justify-end gap-4">
            <Button variant="ghost" class="rounded-2xl font-bold h-12 px-8" @click="showAdjustment = false">Batal</Button>
            <Button class="rounded-2xl px-12 h-12 shadow-xl shadow-primary/20 font-black text-white bg-primary hover:bg-primary/90" @click="handleAdjust" :loading="isAdjusting">Simpan Perubahan</Button>
         </CardFooter>
       </Card>
    </div>

    <!-- Request Goods Modal -->
    <div v-if="showRequestModal" class="fixed inset-0 bg-slate-900/60 backdrop-blur-md z-[100] flex items-center justify-center p-4">
       <Card class="w-full max-w-2xl shadow-2xl rounded-[2.5rem] overflow-hidden border-none animate-in zoom-in-95 duration-300">
         <CardHeader class="p-8 border-b bg-white">
            <div class="flex justify-between items-center">
              <div>
                <CardTitle class="text-2xl font-black text-slate-900">Request Barang</CardTitle>
                <CardDescription>Minta penambahan stok ke pabrik pusat.</CardDescription>
              </div>
              <Button variant="ghost" size="icon" @click="showRequestModal = false" class="rounded-full">
                <Plus class="h-6 w-6 rotate-45 text-slate-400" />
              </Button>
            </div>
         </CardHeader>
         <CardContent class="p-8 space-y-6 bg-white max-h-[60vh] overflow-y-auto custom-scrollbar">
            <div class="space-y-2">
              <label class="text-sm font-bold text-slate-700 ml-1">Pilih Pabrik Tujuan</label>
              <select v-model="requestForm.factory_id" class="w-full px-5 py-3.5 bg-slate-50 border border-slate-100 rounded-2xl text-sm font-bold outline-none appearance-none cursor-pointer">
                <option value="" disabled>Pilih Pabrik...</option>
                <option v-for="factory in factoryStore.factories" :key="factory.id" :value="factory.id">
                  {{ factory.name }}
                </option>
              </select>
            </div>

            <div class="space-y-4">
              <div class="flex justify-between items-center px-1">
                <p class="text-[11px] font-black text-slate-400 uppercase tracking-widest">Daftar Produk yang Diminta</p>
                <Button size="sm" variant="ghost" class="text-primary font-bold hover:bg-primary/5" @click="addRequestItem">
                  <Plus class="h-4 w-4 mr-1" /> Tambah Produk
                </Button>
              </div>
              
              <div v-if="requestForm.items.length === 0" class="text-center py-12 bg-slate-50 rounded-3xl border border-dashed border-slate-200 text-slate-400 text-sm">
                Belum ada produk dipilih.
              </div>

              <div v-for="(item, index) in requestForm.items" :key="index" class="flex flex-col gap-4 bg-slate-50 p-6 rounded-[2rem] border border-slate-100 relative group transition-all hover:shadow-md hover:bg-white">
                <div class="grid grid-cols-1 md:grid-cols-12 gap-4">
                  <div class="md:col-span-4 space-y-1">
                    <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Pilih Produk</label>
                    <select v-model="item.product_id" @change="onProductSelect(index)" class="w-full px-4 py-3 bg-white border border-slate-100 rounded-xl text-xs font-bold outline-none shadow-sm focus:ring-2 focus:ring-primary/20">
                      <option value="" disabled>Pilih Produk...</option>
                      <option v-for="p in factoryStore.products" :key="p.id" :value="p.id">
                        {{ p.name }}
                      </option>
                    </select>
                  </div>
                  
                  <div class="md:col-span-2 space-y-1">
                    <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Jumlah</label>
                    <input type="number" v-model.number="item.quantity" class="w-full px-4 py-3 bg-white border border-slate-100 rounded-xl text-xs font-black outline-none shadow-sm focus:ring-2 focus:ring-primary/20" />
                  </div>

                  <div class="md:col-span-2 space-y-1">
                    <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Satuan</label>
                    <select v-model="item.unit" class="w-full px-4 py-3 bg-white border border-slate-100 rounded-xl text-xs font-bold outline-none shadow-sm focus:ring-2 focus:ring-primary/20 appearance-none cursor-pointer">
                      <option v-for="u in UNIT_OPTIONS" :key="u" :value="u">{{ u }}</option>
                    </select>
                  </div>

                  <div class="md:col-span-2 space-y-1">
                    <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Isi (PCS/Satuan)</label>
                    <input type="number" v-model.number="item.pcs_per_unit" class="w-full px-4 py-3 bg-white border border-slate-100 rounded-xl text-xs font-black outline-none shadow-sm focus:ring-2 focus:ring-primary/20" />
                  </div>

                  <div class="md:col-span-1 flex items-end">
                    <Button variant="ghost" size="icon" class="text-rose-500 h-12 w-full rounded-xl hover:bg-rose-50 border border-transparent hover:border-rose-100" @click="removeRequestItem(index)">
                      <Trash2 class="h-5 w-5" />
                    </Button>
                  </div>
                </div>

                <div v-if="item.product_id" class="flex items-center justify-between px-4 py-2 bg-white/50 rounded-xl border border-dashed border-slate-200">
                  <div class="flex items-center gap-2">
                    <Package class="h-3 w-3 text-primary" />
                    <span class="text-[10px] font-bold text-slate-500">Konversi Total:</span>
                    <span class="text-[10px] font-black text-slate-900">{{ item.quantity }} {{ item.unit }} × {{ item.pcs_per_unit }} PCS = </span>
                    <span class="text-xs font-black text-primary">{{ item.quantity * (item.pcs_per_unit || 0) }} PCS</span>
                  </div>
                  <div class="text-[9px] font-black text-slate-300 uppercase tracking-[0.2em]">Estimasi Muatan</div>
                </div>
              </div>
            </div>

            <div class="space-y-2">
              <label class="text-sm font-bold text-slate-700 ml-1">Catatan Tambahan</label>
              <textarea v-model="requestForm.notes" rows="2" placeholder="Sebutkan alasan atau instruksi khusus..." class="w-full px-5 py-4 bg-slate-50 border border-slate-100 rounded-2xl text-sm outline-none resize-none focus:ring-2 focus:ring-primary/20"></textarea>
            </div>
         </CardContent>
         <CardFooter class="bg-slate-50/50 border-t p-8 flex justify-end gap-4">
            <Button variant="ghost" class="rounded-2xl font-bold h-12 px-8" @click="showRequestModal = false">Batal</Button>
            <Button class="rounded-2xl px-12 h-12 shadow-xl shadow-primary/20 font-black text-white bg-primary hover:bg-primary/90" @click="handleRequest" :loading="isRequesting">Kirim Permintaan</Button>
         </CardFooter>
       </Card>
    </div>

    <!-- Scanner Modal -->
    <div v-if="showScanner" class="fixed inset-0 bg-slate-900/60 backdrop-blur-md z-[100] flex items-center justify-center p-4">
       <Card class="w-full max-w-md shadow-2xl rounded-[3rem] overflow-hidden border-none animate-in zoom-in-95 duration-300">
         <CardHeader class="bg-slate-900 text-white p-8">
            <div class="flex justify-between items-center">
              <div>
                <CardTitle class="text-2xl font-black flex items-center gap-3">
                  <ScanLine class="h-8 w-8 text-primary" />
                  Scan SJ
                </CardTitle>
                <CardDescription class="text-slate-400">Verifikasi pengiriman secara instan.</CardDescription>
              </div>
              <Button variant="ghost" size="icon" @click="showScanner = false" class="rounded-full text-white/50 hover:text-white">
                <Plus class="h-6 w-6 rotate-45" />
              </Button>
            </div>
         </CardHeader>
         <CardContent class="p-8 space-y-8 bg-white">
            <div class="aspect-square bg-slate-50 rounded-[2.5rem] border-2 border-dashed border-slate-200 flex flex-col items-center justify-center text-slate-400 gap-4 relative overflow-hidden group">
              <div class="w-48 h-48 border-2 border-primary/20 rounded-[2.5rem] flex items-center justify-center relative z-10 bg-white shadow-xl shadow-slate-100">
                <div class="absolute inset-0 border-4 border-primary/5 rounded-[2.4rem] animate-pulse"></div>
                <QrCode class="w-24 h-24 text-primary opacity-20" />
                <div class="absolute w-full h-[2px] bg-primary/60 top-1/2 left-0 -translate-y-1/2 animate-bounce shadow-[0_0_10px_primary]"></div>
              </div>
              <p class="text-[10px] font-black uppercase tracking-[0.4em] text-primary/60 z-10 bg-white px-5 py-2 rounded-full border border-primary/10 shadow-sm">Scanner Aktif</p>
            </div>
            
            <div class="space-y-3">
              <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Input Manual Nomor SJ</label>
              <div class="relative">
                <input 
                  v-model="scannedDO" 
                  placeholder="DO-YYYYMMDD-XXXX" 
                  class="w-full h-16 rounded-2xl border-2 border-slate-100 focus:border-primary focus:ring-4 focus:ring-primary/5 font-mono text-center text-xl tracking-widest font-black outline-none transition-all"
                  @keyup.enter="handleScanSubmit"
                />
              </div>
            </div>
         </CardContent>
         <CardFooter class="flex flex-col gap-3 p-8 bg-slate-50/50 border-t">
            <Button class="w-full font-black h-14 rounded-2xl text-base shadow-xl shadow-primary/20 bg-primary hover:bg-primary/90 text-white" @click="handleScanSubmit" :loading="isScanning">
              KONFIRMASI PENERIMAAN
            </Button>
            <Button variant="ghost" class="w-full font-bold text-slate-400" @click="showScanner = false">TUTUP</Button>
         </CardFooter>
       </Card>
    </div>
    
    <!-- Receiving Confirmation Modal -->
    <div v-if="showReceiveModal" class="fixed inset-0 bg-slate-900/60 backdrop-blur-md z-[100] flex items-center justify-center p-4">
       <Card class="w-full max-w-2xl shadow-2xl rounded-[2.5rem] overflow-hidden border-none animate-in zoom-in-95 duration-300">
         <CardHeader class="p-8 border-b bg-white">
            <div class="flex justify-between items-center">
              <div>
                <CardTitle class="text-2xl font-black text-slate-900">Konfirmasi Bongkar Muat</CardTitle>
                <CardDescription>Cek kondisi fisik barang dan masukkan jumlah yang diterima.</CardDescription>
              </div>
              <Button variant="ghost" size="icon" @click="showReceiveModal = false" class="rounded-full">
                <Plus class="h-6 w-6 rotate-45 text-slate-400" />
              </Button>
            </div>
         </CardHeader>
         <CardContent class="p-8 space-y-6 bg-white max-h-[60vh] overflow-y-auto custom-scrollbar">
             <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div class="bg-blue-50 border border-blue-100 p-4 rounded-2xl flex gap-4 items-center">
                  <div class="w-10 h-10 rounded-xl bg-blue-100 flex items-center justify-center text-blue-600 shadow-sm">
                    <Truck class="h-5 w-5" />
                  </div>
                  <div>
                    <p class="text-[10px] font-black text-blue-400 uppercase tracking-widest leading-none mb-1">Surat Jalan</p>
                    <p class="text-sm font-black text-blue-900">{{ receivingShipment?.doNo }}</p>
                  </div>
                </div>
                <div v-if="receivingShipment?.eta" class="bg-emerald-50 border border-emerald-100 p-4 rounded-2xl flex gap-4 items-center">
                  <div class="w-10 h-10 rounded-xl bg-emerald-100 flex items-center justify-center text-emerald-600 shadow-sm">
                    <Clock class="h-5 w-5" />
                  </div>
                  <div>
                    <p class="text-[10px] font-black text-emerald-400 uppercase tracking-widest leading-none mb-1">Estimasi Tiba</p>
                    <p class="text-sm font-black text-emerald-900">
                      {{ new Date(receivingShipment.eta).toLocaleDateString('id-ID', { day: 'numeric', month: 'short' }) }}, 
                      {{ new Date(receivingShipment.eta).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }) }}
                    </p>
                  </div>
                </div>
             </div>
            <div class="space-y-4">
              <div v-for="(item, index) in receiveForm.items" :key="item.id" class="p-6 bg-slate-50 rounded-[2rem] border border-slate-100 space-y-4">
                <div class="flex justify-between items-center">
                  <h4 class="font-black text-slate-900">{{ item.product_name }}</h4>
                  <Badge variant="outline" class="rounded-lg px-2 py-0.5 bg-white text-slate-400 font-bold border-slate-200">
                    Sesuai SJ: {{ item.expected_quantity }} {{ item.unit }}
                  </Badge>
                </div>
                
                <div class="grid grid-cols-2 gap-4">
                  <div class="space-y-2">
                    <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Kondisi Baik (GOOD)</label>
                    <div class="relative">
                      <input type="number" v-model.number="item.actual_received_quantity" class="w-full h-12 rounded-xl border border-slate-200 focus:border-primary px-4 font-black text-lg outline-none" />
                      <div class="absolute right-3 top-1/2 -translate-y-1/2 text-[9px] font-black text-emerald-500 uppercase">{{ item.unit || 'UNIT' }}</div>
                    </div>
                    <div v-if="item.pcs_per_unit > 1" class="px-3 pt-1 text-[9px] font-bold text-slate-400">
                      = {{ item.actual_received_quantity * item.pcs_per_unit }} PCS
                    </div>
                  </div>
                  <div class="space-y-2">
                    <label class="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Rusak/Pecah (DAMAGED)</label>
                    <div class="relative">
                      <input type="number" v-model.number="item.damaged_quantity" class="w-full h-12 rounded-xl border border-slate-200 focus:border-rose-500 px-4 font-black text-lg outline-none" />
                      <div class="absolute right-3 top-1/2 -translate-y-1/2 text-[9px] font-black text-rose-500 uppercase">{{ item.unit || 'UNIT' }}</div>
                    </div>
                    <div v-if="item.pcs_per_unit > 1" class="px-3 pt-1 text-[9px] font-bold text-slate-400">
                      = {{ item.damaged_quantity * item.pcs_per_unit }} PCS
                    </div>
                  </div>
                </div>

                <div v-if="item.actual_received_quantity + item.damaged_quantity !== item.expected_quantity" class="flex items-center gap-2 text-[10px] font-bold text-orange-600 bg-orange-50 px-3 py-1.5 rounded-lg border border-orange-100">
                  <AlertCircle class="h-3 w-3" /> Selisih: {{ (item.actual_received_quantity + item.damaged_quantity) - item.expected_quantity }} {{ item.unit }}
                </div>
              </div>
            </div>
         </CardContent>
         <CardFooter class="bg-slate-50/50 border-t p-8 flex justify-end gap-4">
            <Button variant="ghost" class="rounded-2xl font-bold h-12 px-8" @click="showReceiveModal = false">Batal</Button>
            <Button class="rounded-2xl px-12 h-12 shadow-xl shadow-emerald-200 font-black text-white bg-emerald-600 hover:bg-emerald-700" @click="submitReceive" :loading="isSubmittingReceive">Update Stok & Selesaikan</Button>
         </CardFooter>
       </Card>
    </div>
    
    <!-- Rejection Reason Modal -->
    <div v-if="showRejectModal" class="fixed inset-0 bg-slate-900/60 backdrop-blur-md z-[100] flex items-center justify-center p-4">
       <Card class="w-full max-w-lg shadow-2xl rounded-[2.5rem] overflow-hidden border-none animate-in zoom-in-95 duration-300">
         <CardHeader class="p-8 border-b bg-white">
            <div class="flex justify-between items-center">
              <div>
                <CardTitle class="text-2xl font-black text-rose-600">Tolak Pengiriman</CardTitle>
                <CardDescription>Berikan alasan penolakan agar pabrik dapat melakukan penjadwalan ulang.</CardDescription>
              </div>
              <Button variant="ghost" size="icon" @click="showRejectModal = false" class="rounded-full">
                <Plus class="h-6 w-6 rotate-45 text-slate-400" />
              </Button>
            </div>
         </CardHeader>
         <CardContent class="p-8 space-y-6 bg-white">
            <div class="space-y-2">
              <label class="text-sm font-bold text-slate-700 ml-1">Alasan Penolakan</label>
              <textarea 
                v-model="rejectionForm.reason" 
                rows="4" 
                placeholder="Contoh: Gudang penuh pada tanggal tersebut, mohon geser ke hari lain..." 
                class="w-full px-5 py-4 bg-slate-50 border border-slate-100 rounded-2xl text-sm outline-none resize-none focus:ring-2 focus:ring-rose-500/20 transition-all border-rose-100"
              ></textarea>
            </div>
         </CardContent>
         <CardFooter class="bg-slate-50/50 border-t p-8 flex justify-end gap-4">
            <Button variant="ghost" class="rounded-2xl font-bold h-12 px-8" @click="showRejectModal = false">Batal</Button>
            <Button class="rounded-2xl px-12 h-12 shadow-xl shadow-rose-200 font-black text-white bg-rose-600 hover:bg-rose-700" @click="submitReject" :loading="isRejecting">Konfirmasi Tolak</Button>
         </CardFooter>
       </Card>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref, reactive, watch, computed } from 'vue'
import { useWarehouseStore } from '@/stores/warehouse'
import { useMasterDataStore } from '@/stores/masterData'
import { useFactoryStore } from '@/stores/factory'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from '@/components/ui/card/index'
import { Badge } from '@/components/ui/badge'
import DataTable from '@/components/DataTable.vue'
import { 
  Boxes, 
  Truck, 
  ScanLine, 
  RefreshCw, 
  CheckCircle2, 
  PackageSearch, 
  QrCode, 
  Search,
  AlertCircle,
  Plus,
  Trash2,
  ArrowUpRight,
  Warehouse,
  History,
  Scale,
  Calendar,
  Clock,
  MapPin,
  Factory,
  Package,
  User,
  AlertTriangle,
  Printer
} from 'lucide-vue-next'
import SuratJalanPrint from '@/components/factory/SuratJalanPrint.vue'
import { toast } from 'vue-sonner'

const warehouseStore = useWarehouseStore()
const masterDataStore = useMasterDataStore()
const factoryStore = useFactoryStore()
const UNIT_OPTIONS = ['KARTON', 'DUS', 'BOX', 'KRAT', 'PCS', 'BAL', 'PACK', 'KG', 'GRAM', 'SACHET', 'JERIGEN', 'BOTOL']

// Formatters
const formatStock = (qty: number, product: any) => {
  if (qty == null) return '0'
  const pcsPerUnit = product?.pcs_per_unit || 1
  
  if (pcsPerUnit > 1) {
    const units = Math.floor(qty / pcsPerUnit)
    const pcs = qty % pcsPerUnit
    if (units > 0 && pcs > 0) return `${units} ${product.unit || 'UNIT'} ${pcs} PCS`
    if (units > 0) return `${units} ${product.unit || 'UNIT'}`
    return `${pcs} PCS`
  }
  return `${qty} ${product?.unit || 'PCS'}`
}

// State
const activeTab = ref('stock')
const showAdjustment = ref(false)
const showRequestModal = ref(false)
const showScanner = ref(false)
const showReceiveModal = ref(false)
const showRejectModal = ref(false)
const receivingShipment = ref<any>(null)
const processingId = ref('')
const scannedDO = ref('')
const isScanning = ref(false)
const isAdjusting = ref(false)
const isRequesting = ref(false)
const isRejecting = ref(false)
const isSubmittingReceive = ref(false)
const stockSearch = ref('')
const historySearch = ref('')
const shipmentToPrint = ref<any>(null)

const printShipment = (group: any) => {
  shipmentToPrint.value = group
  setTimeout(() => {
    window.print()
  }, 300)
}

const receiveForm = reactive({
  items: [] as any[]
})

const rejectionForm = reactive({
  reason: '',
  group: null as any
})

const adjustForm = reactive({
  selectedItem: null as any,
  quantity: 0,
  reason: ''
})

const requestForm = reactive({
  factory_id: '',
  notes: '',
  items: [] as any[]
})

// Methods
const addRequestItem = () => {
  requestForm.items.push({ 
    product_id: '', 
    quantity: 1,
    unit: 'Karton',
    pcs_per_unit: 1
  })
}

const onProductSelect = (index: number) => {
  const item = requestForm.items[index]
  const product = factoryStore.products.find(p => p.id === item.product_id)
  if (product) {
    item.unit = product.unit || 'Karton'
    item.pcs_per_unit = product.pcs_per_unit || 1
  }
}

const removeRequestItem = (index: number) => {
  requestForm.items.splice(index, 1)
}

const refreshAll = async () => {
  console.log('DEBUG: refreshAll called with Branch ID:', masterDataStore.selectedBranchId)
  if (!masterDataStore.selectedBranchId) {
    toast.error('Branch ID is missing. Please select a branch.')
    return
  }

  const tid = toast.loading('Memperbarui data gudang...')
  
  try {
    await Promise.all([
      warehouseStore.fetchInventory(),
      warehouseStore.fetchPendingShipments(),
      warehouseStore.fetchAllTransfers()
    ])
    
    const count = warehouseStore.pendingShipments.length
    toast.success(`Berhasil! Ditemukan ${count} item penerimaan.`, { id: tid })
    console.log('DEBUG: fetchPendingShipments success, count:', count)
  } catch (error: any) {
    console.error('DEBUG: refreshAll error:', error)
    toast.error(`Gagal mengambil data: ${error.message || 'Unknown Error'}`, { id: tid })
  }
}

const formatStatus = (status: string) => {
  switch (status) {
    case 'SHIPPED': return 'Dalam Perjalanan'
    case 'ARRIVED': return 'Siap Unload'
    case 'REQUESTED': return 'Menunggu Approval'
    case 'APPROVED': return 'Disetujui / Siap Proses'
    default: return status
  }
}

// Computed for Filters & Groups
const filteredInventory = computed(() => {
  if (!stockSearch.value) return warehouseStore.inventory
  const q = stockSearch.value.toLowerCase()
  return warehouseStore.inventory.filter(i => 
    i.product?.name?.toLowerCase().includes(q) || 
    i.batch_no?.toLowerCase().includes(q)
  )
})

const groupedPending = computed(() => {
  const groups: Record<string, any> = {}
  warehouseStore.pendingShipments.forEach(item => {
    const doNo = item.delivery_order_no || 'REQ-' + item.id.substring(0, 8)
    if (!groups[doNo]) {
      groups[doNo] = {
        doNo,
        from: item.from_factory?.name || 'Cabang Lain',
        date: item.created_at,
        status: item.status,
        totalQty: 0,
        totalWeight: 0,
        items: [],
        vehicle: item.vehicle,
        driver: item.driver,
        targetDate: item.target_shipment_date,
        eta: item.estimated_arrival
      }
    }
    groups[doNo].items.push(item)
    groups[doNo].totalQty += item.quantity
    groups[doNo].totalWeight += item.total_weight
  })
  return Object.values(groups).sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())
})

const groupedHistory = computed(() => {
  const groups: Record<string, any> = {}
  warehouseStore.allTransfers.filter(s => s.status === 'RECEIVED').forEach(item => {
    const doNo = item.delivery_order_no || 'DO-' + item.id.substring(0, 8)
    if (!groups[doNo]) {
      groups[doNo] = {
        doNo,
        from: item.from_factory?.name || 'Cabang Lain',
        receivedAt: item.received_at || item.created_at,
        totalWeight: 0,
        items: []
      }
    }
    groups[doNo].items.push(item)
    groups[doNo].totalWeight += item.total_weight
  })
  return Object.values(groups).sort((a, b) => new Date(b.receivedAt).getTime() - new Date(a.receivedAt).getTime())
})

const filteredHistory = computed(() => {
  if (!historySearch.value) return groupedHistory.value
  const q = historySearch.value.toLowerCase()
  return groupedHistory.value.filter(s => 
    s.doNo.toLowerCase().includes(q) || 
    s.from.toLowerCase().includes(q)
  )
})

// Handlers
const handleArrive = async (group: any) => {
  processingId.value = group.doNo
  try {
    for (const item of group.items) {
      await warehouseStore.arriveShipment(item.id)
    }
    toast.success('Kedatangan dikonfirmasi. Silahkan lakukan bongkar muat.')
    refreshAll()
  } catch (err) {
    toast.error('Gagal: ' + err)
  } finally {
    processingId.value = ''
  }
}

const handleReceive = (group: any) => {
  receivingShipment.value = group
  receiveForm.items = group.items.map((item: any) => ({
    id: item.id,
    product_name: item.product?.name,
    unit: item.product?.unit,
    expected_quantity: item.quantity,
    actual_received_quantity: item.quantity,
    damaged_quantity: 0,
    pcs_per_unit: item.pcs_per_unit || 1
  }))
  showReceiveModal.value = true
}

const submitReceive = async () => {
  isSubmittingReceive.value = true
  try {
    for (const item of receiveForm.items) {
      await warehouseStore.receiveShipment(item.id, {
        actual_received_quantity: item.actual_received_quantity,
        damaged_quantity: item.damaged_quantity
      })
    }
    showReceiveModal.value = false
    toast.success('Penerimaan berhasil dikonfirmasi dengan penyesuaian kondisi barang.')
    refreshAll()
  } catch (err) {
    toast.error('Gagal: ' + err)
  } finally {
    isSubmittingReceive.value = false
  }
}

const handleApprove = async (group: any) => {
  try {
    for (const item of group.items) await warehouseStore.approveShipment(item.id)
    toast.success('Disetujui.')
    refreshAll()
  } catch (err) { toast.error('Gagal: ' + err) }
}

const handleReject = (group: any) => {
  rejectionForm.group = group
  rejectionForm.reason = ''
  showRejectModal.value = true
}

const submitReject = async () => {
  if (!rejectionForm.reason) {
    toast.error('Alasan penolakan wajib diisi')
    return
  }
  
  isRejecting.value = true
  try {
    for (const item of rejectionForm.group.items) {
      await warehouseStore.rejectShipment(item.id, rejectionForm.reason)
    }
    toast.success('Pengiriman ditolak.')
    showRejectModal.value = false
    refreshAll()
  } catch (err) {
    toast.error('Gagal menolak: ' + err)
  } finally {
    isRejecting.value = false
  }
}

const handleConfirmSJ = async (group: any) => {
  processingId.value = group.doNo
  try {
    for (const item of group.items) {
      await warehouseStore.confirmSJ(item.id)
    }
    toast.success('Surat Jalan telah disetujui. Barang dalam perjalanan.')
    refreshAll()
  } catch (err) {
    toast.error('Gagal menyetujui SJ: ' + err)
  } finally {
    processingId.value = ''
  }
}

const handleScanSubmit = async () => {
  if (!scannedDO.value) return
  isScanning.value = true
  try {
    // For Scan SJ, we fetch the DO first to allow partial receiving, 
    // but for simplicity we'll assume full receive or redirect to a modal if needed.
    // For now, let's just do full receive but we could improve this later.
    await warehouseStore.receiveByDO(scannedDO.value, {
      actual_received_quantity: 0, // This needs to be handled better in backend if 0
      damaged_quantity: 0
    })
    showScanner.value = false
    scannedDO.value = ''
    toast.success('Barang diterima via Scan SJ.')
    refreshAll()
  } catch (err) { toast.error('Gagal: ' + err) } finally { isScanning.value = false }
}

const handleAdjust = async () => {
  if (!adjustForm.selectedItem || !adjustForm.reason) return
  isAdjusting.value = true
  try {
    await warehouseStore.adjustStock({
      product_id: adjustForm.selectedItem.product_id,
      batch_no: adjustForm.selectedItem.batch_no,
      quantity: adjustForm.quantity,
      reason: adjustForm.reason
    })
    showAdjustment.value = false
    refreshAll()
    toast.success('Stok berhasil disesuaikan.')
  } catch (err) { toast.error('Gagal: ' + err) } finally { isAdjusting.value = false }
}

const handleRequest = async () => {
  if (!requestForm.factory_id) return
  
  const validItems = requestForm.items.filter(i => i.product_id && i.quantity > 0)
  if (validItems.length === 0) {
    toast.error('Pilih setidaknya satu produk dengan jumlah yang benar')
    return
  }

  isRequesting.value = true
  try {
    await warehouseStore.requestGoods(requestForm.factory_id, {
      to_branch_id: masterDataStore.selectedBranchId,
      items: validItems,
      notes: requestForm.notes,
      initiated_by: 'BRANCH'
    })
    showRequestModal.value = false
    // Reset form
    requestForm.factory_id = ''
    requestForm.notes = ''
    requestForm.items = []
    
    refreshAll()
    toast.success('Permintaan stok terkirim.')
  } catch (err) { 
    toast.error('Gagal: ' + err) 
  } finally { 
    isRequesting.value = false 
  }
}

// Table Columns
const stockColumns = [
  { key: 'product.name', label: 'Produk', class: 'font-black text-slate-700' },
  { key: 'batch_no', label: 'Batch No', class: 'font-mono text-[11px] text-slate-500' },
  { 
    key: 'quantity', 
    label: 'Stok Fisik', 
    render: (val: number, item: any) => {
      const isLow = val < (item?.min_limit || 0)
      return `<div class="flex flex-col">
        <div class="flex items-center gap-2">
          <span class="text-lg font-black ${isLow ? 'text-rose-600' : 'text-slate-900'}">${formatStock(val, item.product)}</span>
          ${isLow ? '<span class="bg-rose-50 text-rose-600 text-[8px] font-black px-2 py-0.5 rounded-md border border-rose-100 uppercase animate-pulse">Low</span>' : ''}
        </div>
        <span class="text-[9px] font-bold text-slate-400 uppercase tracking-tighter">${val} TOTAL PCS</span>
      </div>`
    }
  },
  { 
    key: 'reserved_quantity', 
    label: 'Reserved / Avail', 
    render: (v: number, item: any) => {
      const avail = item.quantity - v
      return `<div class="flex flex-col">
        <span class="text-[11px] font-black text-orange-500">${v} Reserved</span>
        <span class="text-[11px] font-black text-emerald-600">${formatStock(avail, item.product)} Avail</span>
      </div>`
    }
  },
  { 
    key: 'updated_at', 
    label: 'Update Terakhir', 
    render: (v: string) => {
      if (!v) return '-'
      const date = new Date(v)
      return `<span class="text-[10px] font-bold text-slate-400 uppercase">${date.toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' })}</span>`
    }
  }
]

const inboundColumns = [
  { key: 'doNo', label: 'Surat Jalan' },
  { key: 'from', label: 'Asal Pengiriman' },
  { key: 'status', label: 'Status' },
  { key: 'totalQty', label: 'Item' },
  { key: 'totalWeight', label: 'Berat' },
  { key: 'targetDate', label: 'Jadwal / ETA' },
  { key: 'actions', label: 'Aksi' }
]

const historyColumns = [
  { key: 'doNo', label: 'Surat Jalan' },
  { key: 'from', label: 'Asal' },
  { key: 'receivedAt', label: 'Diterima Pada' },
  { key: 'totalWeight', label: 'Total Muatan' },
  { key: 'items', label: 'Produk' }
]

onMounted(() => {
  refreshAll()
  factoryStore.fetchFactories()
  factoryStore.fetchProducts()
})

watch(() => masterDataStore.selectedBranchId, (newId) => {
  if (newId) refreshAll()
})
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
