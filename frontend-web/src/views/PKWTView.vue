<script setup lang="ts">
import { ref, onMounted, computed, h } from 'vue'
import { 
  FileText, 
  Plus, 
  Search, 
  Printer, 
  Download, 
  Eye, 
  Trash2,
  Calendar,
  User,
  Building2,
  FileCheck2,
  ArrowRight,
  ArrowLeft,
  X,
  CheckCircle2,
  Clock
} from 'lucide-vue-next'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from '@/components/ui/dialog'
import DataTable from '@/components/DataTable.vue'
import PKWTRenderer from '@/components/PKWTRenderer.vue'
import apiClient from '@/api/axios'
import { useMasterDataStore } from '@/stores/masterData'
import { toast } from 'vue-sonner'

const masterData = useMasterDataStore()
const isLoading = ref(false)
const pkwtList = ref<any[]>([])
const isCreateModalOpen = ref(false)
const isPreviewModalOpen = ref(false)
const currentStep = ref(1)

// Form State
const form = ref({
  documentNumber: '',
  agreementDay: '',
  agreementDate: new Date().toISOString().split('T')[0],
  agreementPlace: 'Surakarta',
  
  // Pihak Pertama (Company)
  companyId: '',
  representativeName: 'Andi Muhammad Santoso',
  representativePosition: 'HRD',
  
  // Pihak Kedua (Employee)
  employeeId: '',
  
  // Contract details
  startDate: '',
  endDate: '',
  jobPosition: '',
  
  // Salary details
  basicSalary: 0,
  allowances: 0,
  notes: ''
})

const selectedEmployee = ref<any>(null)

const fetchEmployees = async () => {
    // In a real app, we'd fetch from API
    // For now we'll rely on masterData if available or fetch specifically
}

const fetchPKWT = async () => {
  isLoading.value = true
  try {
    // Simulate API fetch or actually fetch if we have an endpoint
    // pkwtList.value = response.data.data
  } catch (error) {
    console.error(error)
  } finally {
    isLoading.value = false
  }
}

onMounted(() => {
  fetchPKWT()
  masterData.fetchEmployees()
  masterData.fetchCompanies()
})

const handleEmployeeChange = (id: any) => {
    const emp = masterData.employees.find(e => e.id === id)
    if (emp) {
        selectedEmployee.value = emp
        form.value.jobPosition = emp.job_position?.title || ''
        form.value.basicSalary = emp.salary || 0
    }
}

const steps = [
  { id: 1, name: 'Informasi Dasar', icon: FileCheck2 },
  { id: 2, name: 'Pihak Pertama', icon: Building2 },
  { id: 3, name: 'Pihak Kedua', icon: User },
  { id: 4, name: 'Detail Kerja', icon: Clock },
  { id: 5, name: 'Gaji & Review', icon: FileText },
]

const nextStep = () => {
  if (currentStep.value < 5) currentStep.value++
}

const prevStep = () => {
  if (currentStep.value > 1) currentStep.value--
}

const columns = [
  {
    accessorKey: 'documentNumber',
    header: 'NOMOR SURAT',
    cell: ({ row }: any) => h('span', { class: 'font-bold text-slate-900' }, row.original.documentNumber)
  },
  {
    accessorKey: 'employeeName',
    header: 'KARYAWAN',
    cell: ({ row }: any) => h('div', { class: 'flex flex-col' }, [
        h('span', { class: 'font-bold text-slate-900' }, row.original.employeeName),
        h('span', { class: 'text-xs text-slate-500 font-medium' }, row.original.jobPosition)
    ])
  },
  {
    accessorKey: 'agreementDate',
    header: 'TGL PERJANJIAN',
    cell: ({ row }: any) => h('span', { class: 'font-medium text-slate-600' }, new Date(row.original.agreementDate).toLocaleDateString('id-ID'))
  },
  {
    accessorKey: 'status',
    header: 'STATUS',
    cell: ({ row }: any) => h('span', { class: 'px-2 py-1 rounded-full text-[10px] font-bold bg-emerald-100 text-emerald-700 uppercase' }, 'Generated')
  },
  {
    id: 'actions',
    header: 'AKSI',
    cell: ({ row }: any) => h('div', { class: 'flex items-center gap-2' }, [
      h(Button, { 
        variant: 'ghost', size: 'sm', class: 'h-8 w-8 p-0 rounded-lg',
        onClick: () => {
            // Mock view
            form.value.documentNumber = row.original.documentNumber
            form.value.employeeId = 'some-id'
            isPreviewModalOpen.value = true
        }
      }, () => h(Eye, { class: 'w-4 h-4 text-slate-400' })),
      h(Button, { variant: 'ghost', size: 'sm', class: 'h-8 w-8 p-0 rounded-lg', onClick: () => printDocument() }, () => h(Printer, { class: 'w-4 h-4 text-primary' })),
    ])
  }
]

// Mock data for initial view
pkwtList.value = [
    {
        id: '1',
        documentNumber: '001/WOWIN.SOLO-PKWT/2026',
        employeeName: 'Budi Santoso',
        jobPosition: 'Sales Motoris',
        agreementDate: '2026-05-10',
        status: 'Generated'
    }
]

const pkwtPrintRef = ref<HTMLElement | null>(null)

const printDocument = () => {
    isCreateModalOpen.value = false
    isPreviewModalOpen.value = true
    
    setTimeout(() => {
        const printContent = document.getElementById('pkwt-print-area')
        if (!printContent) return

        const printWindow = window.open('', '_blank')
        if (!printWindow) return

        printWindow.document.write('<html><head><title>PKWT - PT WOWIN PURNOMO PUTERA</title>')
        // Copy styles
        const styles = document.querySelectorAll('style')
        styles.forEach(s => printWindow.document.write(s.outerHTML))
        // Tailwind/Vite Styles
        const links = document.querySelectorAll('link[rel="stylesheet"]')
        links.forEach(l => printWindow.document.write(l.outerHTML))
        
        printWindow.document.write('</head><body>')
        printWindow.document.write(printContent.innerHTML)
        printWindow.document.write('</body></html>')
        printWindow.document.close()
        
        setTimeout(() => {
            printWindow.print()
            // printWindow.close()
        }, 500)
    }, 500)
}

</script>

<template>
  <div class="space-y-8 pb-12 animate-in fade-in duration-700">
    <!-- Premium Header -->
    <div class="flex flex-col md:flex-row md:items-center justify-between gap-6">
      <div>
        <h1 class="text-3xl font-extrabold text-slate-900 tracking-tight flex items-center gap-3">
            <FileText class="w-8 h-8 text-primary" />
            Pembuatan Surat PKWT
        </h1>
        <p class="text-[14px] font-medium text-slate-500 mt-1.5 uppercase tracking-widest flex items-center gap-2">
          Manajemen Kontrak Kerja Waktu Tertentu
        </p>
      </div>
      
      <div class="flex items-center gap-3">
        <Button @click="isCreateModalOpen = true; currentStep = 1" class="gap-2 shadow-xl shadow-primary/20 rounded-2xl h-12 px-6 font-black bg-primary hover:bg-primary/90 transition-all hover:scale-105 active:scale-95">
          <Plus class="w-5 h-5" /> BUAT SURAT PKWT
        </Button>
      </div>
    </div>

    <!-- Search & Filters -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div class="md:col-span-2 relative">
            <Search class="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
            <Input placeholder="Cari nomor surat atau nama karyawan..." class="pl-12 h-14 rounded-2xl border-none bg-white shadow-xl shadow-slate-100/50 font-medium" />
        </div>
        <Select>
            <SelectTrigger class="h-14 rounded-2xl border-none bg-white shadow-xl shadow-slate-100/50 font-bold px-6">
                <SelectValue placeholder="Semua Tahun" />
            </SelectTrigger>
            <SelectContent>
                <SelectItem value="2026">2026</SelectItem>
                <SelectItem value="2025">2025</SelectItem>
            </SelectContent>
        </Select>
        <Button variant="outline" class="h-14 rounded-2xl border-2 border-slate-50 bg-white shadow-xl shadow-slate-100/50 text-slate-600 font-bold gap-2">
            <Download class="w-5 h-5" /> EXPORT DATA
        </Button>
    </div>

    <!-- DataTable Area -->
    <div class="bg-white rounded-[2.5rem] border border-slate-200 shadow-2xl shadow-slate-100/50 overflow-hidden">
        <DataTable :data="pkwtList" :columns="columns" :isLoading="isLoading" />
    </div>

    <!-- Create PKWT Wizard Modal -->
    <Dialog v-model:open="isCreateModalOpen">
      <DialogContent class="sm:max-w-4xl rounded-[2.5rem] p-0 overflow-hidden border-none shadow-2xl max-h-[95vh] flex flex-col">
        <!-- Progress Header -->
        <div class="bg-slate-900 p-8 text-white shrink-0">
            <div class="flex items-center justify-between mb-8">
                <div>
                    <h2 class="text-2xl font-black">Wizard Pembuatan PKWT</h2>
                    <p class="text-slate-400 text-xs font-bold uppercase tracking-widest mt-1">Lengkapi data untuk menjana dokumen kontrak</p>
                </div>
                <button @click="isCreateModalOpen = false" class="p-2 rounded-full bg-white/10 hover:bg-white/20 transition-colors">
                    <X class="w-5 h-5" />
                </button>
            </div>

            <div class="flex items-center justify-between relative px-2">
                <div v-for="step in steps" :key="step.id" class="flex flex-col items-center gap-2 relative z-10 group cursor-pointer" @click="step.id < currentStep ? currentStep = step.id : null">
                    <div :class="[
                        'w-10 h-10 rounded-xl flex items-center justify-center border-2 transition-all duration-500',
                        currentStep === step.id ? 'bg-primary border-primary shadow-lg shadow-primary/30 scale-110' : 
                        currentStep > step.id ? 'bg-emerald-500 border-emerald-500' : 'bg-slate-800 border-slate-700 text-slate-500'
                    ]">
                        <component :is="currentStep > step.id ? CheckCircle2 : step.icon" class="w-5 h-5" />
                    </div>
                    <span :class="[
                        'text-[10px] font-black uppercase tracking-tighter transition-all duration-500',
                        currentStep === step.id ? 'text-primary' : 'text-slate-500'
                    ]">{{ step.name }}</span>
                </div>
                <!-- Connector Line -->
                <div class="absolute top-5 left-10 right-10 h-[2px] bg-slate-800 -z-0">
                    <div class="h-full bg-primary transition-all duration-700" :style="{ width: `${(currentStep - 1) * 25}%` }"></div>
                </div>
            </div>
        </div>

        <!-- Form Content -->
        <div class="flex-1 overflow-y-auto p-10 bg-slate-50/50">
            <!-- Step 1: Basic Info -->
            <div v-if="currentStep === 1" class="space-y-8 animate-in fade-in slide-in-from-right-4 duration-500">
                <div class="bg-white p-8 rounded-3xl shadow-sm border border-slate-100 space-y-6">
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <div class="space-y-2">
                            <label class="text-xs font-black text-slate-500 uppercase tracking-widest ml-1">Nomor Surat</label>
                            <Input v-model="form.documentNumber" placeholder="Contoh: /WOWIN.SOLO-PKWT/2026" class="h-12 rounded-xl bg-slate-50 border-none font-bold" />
                        </div>
                        <div class="space-y-2">
                            <label class="text-xs font-black text-slate-500 uppercase tracking-widest ml-1">Tempat Perjanjian</label>
                            <Input v-model="form.agreementPlace" class="h-12 rounded-xl bg-slate-50 border-none font-bold" />
                        </div>
                    </div>
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <div class="space-y-2">
                            <label class="text-xs font-black text-slate-500 uppercase tracking-widest ml-1">Hari</label>
                            <Input v-model="form.agreementDay" placeholder="Contoh: Senin" class="h-12 rounded-xl bg-slate-50 border-none font-bold" />
                        </div>
                        <div class="space-y-2">
                            <label class="text-xs font-black text-slate-500 uppercase tracking-widest ml-1">Tanggal Perjanjian</label>
                            <Input v-model="form.agreementDate" type="date" class="h-12 rounded-xl bg-slate-50 border-none font-bold" />
                        </div>
                    </div>
                </div>
            </div>

            <!-- Step 2: Pihak Pertama -->
            <div v-if="currentStep === 2" class="space-y-8 animate-in fade-in slide-in-from-right-4 duration-500">
                <div class="bg-white p-8 rounded-3xl shadow-sm border border-slate-100 space-y-6">
                    <div class="space-y-2">
                        <label class="text-xs font-black text-slate-500 uppercase tracking-widest ml-1">Perusahaan (Pihak Pertama)</label>
                        <Select v-model="form.companyId">
                            <SelectTrigger class="h-12 rounded-xl bg-slate-50 border-none font-bold">
                                <SelectValue placeholder="Pilih Perusahaan" />
                            </SelectTrigger>
                            <SelectContent>
                                <SelectItem v-for="c in masterData.companies" :key="c.id" :value="c.id">{{ c.name }}</SelectItem>
                            </SelectContent>
                        </Select>
                    </div>
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <div class="space-y-2">
                            <label class="text-xs font-black text-slate-500 uppercase tracking-widest ml-1">Nama Perwakilan</label>
                            <Input v-model="form.representativeName" class="h-12 rounded-xl bg-slate-50 border-none font-bold" />
                        </div>
                        <div class="space-y-2">
                            <label class="text-xs font-black text-slate-500 uppercase tracking-widest ml-1">Jabatan Perwakilan</label>
                            <Input v-model="form.representativePosition" class="h-12 rounded-xl bg-slate-50 border-none font-bold" />
                        </div>
                    </div>
                </div>
            </div>

            <!-- Step 3: Pihak Kedua -->
            <div v-if="currentStep === 3" class="space-y-8 animate-in fade-in slide-in-from-right-4 duration-500">
                <div class="bg-white p-8 rounded-3xl shadow-sm border border-slate-100 space-y-6">
                    <div class="space-y-2">
                        <label class="text-xs font-black text-slate-500 uppercase tracking-widest ml-1">Pilih Karyawan (Pihak Kedua)</label>
                        <Select v-model="form.employeeId" @update:modelValue="handleEmployeeChange">
                            <SelectTrigger class="h-12 rounded-xl bg-slate-50 border-none font-bold">
                                <SelectValue placeholder="Cari Karyawan..." />
                            </SelectTrigger>
                            <SelectContent>
                                <SelectItem v-for="e in masterData.employees" :key="e.id" :value="e.id">{{ e.first_name }} {{ e.last_name }}</SelectItem>
                            </SelectContent>
                        </Select>
                    </div>

                    <div v-if="selectedEmployee" class="p-6 bg-slate-50 rounded-2xl border border-slate-100 grid grid-cols-2 gap-4">
                        <div class="flex flex-col">
                            <span class="text-[10px] font-black text-slate-400 uppercase tracking-widest">NIK</span>
                            <span class="font-bold text-slate-700">{{ selectedEmployee.identity_number || '-' }}</span>
                        </div>
                        <div class="flex flex-col">
                            <span class="text-[10px] font-black text-slate-400 uppercase tracking-widest">Alamat (KTP)</span>
                            <span class="font-bold text-slate-700 text-xs">{{ selectedEmployee.address_ktp || '-' }}</span>
                        </div>
                        <div class="flex flex-col">
                            <span class="text-[10px] font-black text-slate-400 uppercase tracking-widest">Tempat, Tgl Lahir</span>
                            <span class="font-bold text-slate-700">{{ selectedEmployee.birth_place }}, {{ selectedEmployee.birth_date ? new Date(selectedEmployee.birth_date).toLocaleDateString('id-ID') : '-' }}</span>
                        </div>
                        <div class="flex flex-col">
                            <span class="text-[10px] font-black text-slate-400 uppercase tracking-widest">Jenis Kelamin</span>
                            <span class="font-bold text-slate-700">{{ selectedEmployee.gender }}</span>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Step 4: Detail Kerja -->
            <div v-if="currentStep === 4" class="space-y-8 animate-in fade-in slide-in-from-right-4 duration-500">
                <div class="bg-white p-8 rounded-3xl shadow-sm border border-slate-100 space-y-6">
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <div class="space-y-2">
                            <label class="text-xs font-black text-slate-500 uppercase tracking-widest ml-1">Tanggal Mulai</label>
                            <Input v-model="form.startDate" type="date" class="h-12 rounded-xl bg-slate-50 border-none font-bold" />
                        </div>
                        <div class="space-y-2">
                            <label class="text-xs font-black text-slate-500 uppercase tracking-widest ml-1">Tanggal Berakhir</label>
                            <Input v-model="form.endDate" type="date" class="h-12 rounded-xl bg-slate-50 border-none font-bold" />
                        </div>
                    </div>
                    <div class="space-y-2">
                        <label class="text-xs font-black text-slate-500 uppercase tracking-widest ml-1">Jabatan di Kontrak</label>
                        <Input v-model="form.jobPosition" class="h-12 rounded-xl bg-slate-50 border-none font-bold" />
                    </div>
                </div>
            </div>

            <!-- Step 5: Gaji & Review -->
            <div v-if="currentStep === 5" class="space-y-8 animate-in fade-in slide-in-from-right-4 duration-500">
                <div class="bg-white p-8 rounded-3xl shadow-sm border border-slate-100 space-y-6">
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                        <div class="space-y-2">
                            <label class="text-xs font-black text-slate-500 uppercase tracking-widest ml-1">Gaji Pokok (Rp)</label>
                            <Input v-model="form.basicSalary" type="number" class="h-12 rounded-xl bg-slate-50 border-none font-bold" />
                        </div>
                        <div class="space-y-2">
                            <label class="text-xs font-black text-slate-500 uppercase tracking-widest ml-1">Tunjangan Lainnya (Rp)</label>
                            <Input v-model="form.allowances" type="number" class="h-12 rounded-xl bg-slate-50 border-none font-bold" />
                        </div>
                    </div>
                    <div class="p-6 bg-primary/5 rounded-2xl border border-primary/10">
                        <div class="flex justify-between items-center">
                            <span class="text-sm font-black text-slate-600">Total Take Home Pay (Estimasi)</span>
                            <span class="text-xl font-black text-primary">Rp {{ (Number(form.basicSalary) + Number(form.allowances)).toLocaleString('id-ID') }}</span>
                        </div>
                    </div>
                </div>

                <div class="flex items-center gap-4 p-6 bg-amber-50 rounded-2xl border border-amber-100">
                    <div class="w-10 h-10 bg-amber-500 rounded-xl flex items-center justify-center shrink-0">
                        <Printer class="w-5 h-5 text-white" />
                    </div>
                    <p class="text-xs font-bold text-amber-800 leading-relaxed">Setelah menekan "Buat & Cetak", sistem akan menjana dokumen sesuai format PDF yang disepakati dan menyimpan data ke database.</p>
                </div>
            </div>
        </div>

        <!-- Footer -->
        <div class="p-8 bg-white border-t border-slate-100 flex items-center justify-between shrink-0">
            <Button variant="ghost" @click="prevStep" :disabled="currentStep === 1" class="rounded-2xl h-12 px-8 font-black text-slate-400 gap-2">
                <ArrowLeft class="w-4 h-4" /> KEMBALI
            </Button>

            <div class="flex items-center gap-3">
                <Button variant="outline" @click="isCreateModalOpen = false" class="rounded-2xl h-12 px-8 font-black text-slate-500 border-none">BATAL</Button>
                
                <Button v-if="currentStep < 5" @click="nextStep" class="rounded-2xl h-12 px-10 font-black bg-slate-900 hover:bg-slate-800 text-white gap-2 shadow-xl shadow-slate-200">
                    LANJUT <ArrowRight class="w-4 h-4" />
                </Button>
                
                <Button v-else @click="printDocument" class="rounded-2xl h-12 px-10 font-black bg-primary hover:bg-primary/90 text-white gap-2 shadow-xl shadow-primary/20">
                    BUAT & CETAK <Printer class="w-4 h-4" />
                </Button>
            </div>
        </div>
      </DialogContent>
    </Dialog>

    <!-- Preview Modal -->
    <Dialog v-model:open="isPreviewModalOpen">
      <DialogContent class="sm:max-w-5xl rounded-[2.5rem] p-0 overflow-hidden border-none shadow-2xl max-h-[95vh] flex flex-col bg-slate-100">
        <div class="bg-white p-6 border-b border-slate-200 flex items-center justify-between shrink-0">
            <div>
                <h2 class="text-xl font-black">Pratinjau Dokumen PKWT</h2>
                <p class="text-slate-500 text-[10px] font-bold uppercase tracking-widest">Pastikan data sudah sesuai sebelum dicetak</p>
            </div>
            <div class="flex items-center gap-3">
                <Button variant="outline" @click="isPreviewModalOpen = false" class="rounded-xl h-10 px-6 font-bold border-2 border-slate-100">TUTUP</Button>
                <Button @click="printDocument" class="rounded-xl h-10 px-6 font-black bg-primary hover:bg-primary/90 text-white gap-2 shadow-lg shadow-primary/20">
                    CETAK SEKARANG <Printer class="w-4 h-4" />
                </Button>
            </div>
        </div>
        
        <div class="flex-1 overflow-y-auto p-12 flex justify-center bg-slate-200/50">
            <div id="pkwt-print-area">
                <PKWTRenderer 
                    :data="{
                        documentNumber: form.documentNumber,
                        agreementDay: form.agreementDay,
                        agreementDate: form.agreementDate,
                        agreementPlace: form.agreementPlace,
                        representativeName: form.representativeName,
                        representativePosition: form.representativePosition,
                        employee: selectedEmployee,
                        startDate: form.startDate,
                        endDate: form.endDate,
                        jobPosition: form.jobPosition,
                        basicSalary: Number(form.basicSalary),
                        allowances: Number(form.allowances)
                    }" 
                />
            </div>
        </div>
      </DialogContent>
    </Dialog>
  </div>
</template>

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
