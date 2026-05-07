<script setup lang="ts">
import { ref, h, onMounted } from 'vue'
import { Pencil, Trash2, Wallet, Plus, X, Landmark, TrendingUp, ShieldAlert, Banknote, Download } from 'lucide-vue-next'
import apiClient from '@/api/axios'
import DataTable from '@/components/DataTable.vue'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectGroup, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { toast } from 'vue-sonner'

import { useMasterDataStore } from '@/stores/masterData'
import { useAuthStore } from '@/stores/auth'

const masterData = useMasterDataStore()
const authStore = useAuthStore()

const isModalOpen = ref(false)
const newEmployee = ref({
  id: '',
  name: '',
  email: '',
  employeeIDNumber: '',
  departmentId: '',
  jobPositionId: '',
  branchId: '',
  companyId: '',
  employmentStatus: 'Active',
  joinDate: new Date().toISOString().split('T')[0] || '',
  bankName: '',
  bankAccountNumber: '',
  accountHolderName: '',
  salary: 0,
  phoneNumber: '',
  birthPlace: '',
  birthDate: '',
  gender: 'MALE',
  maritalStatus: 'SINGLE',
  bpjsKesehatanNumber: '',
  bpjsKetenagakerjaanNumber: '',
  identityNumber: '',
  npwpNumber: '',
  lastName: '',
  addressKTP: '',
  addressResidential: '',
  emergencyContact: '',
  ptkpStatus: 'TK/0',
  managerId: 'none'
})

const isEditMode = ref(false)
const isSubmitting = ref(false)
const employees = ref<any[]>([])
const isLoading = ref(true)
const selectedBranch = ref<string>('all')

// Salary Settings State
const isSalaryModalOpen = ref(false)
const currentEmployee = ref<any>(null)
const salarySettings = ref<any[]>([])
const payrollComponents = ref<any[]>([])
const isSalarySubmitting = ref(false)
const newSalarySetting = ref({
  component_id: '',
  amount: 0
})

const openAddModal = () => {
  isEditMode.value = false
  newEmployee.value = {
    id: '',
    name: '',
    email: '',
    employeeIDNumber: '',
    departmentId: '',
    jobPositionId: '',
    branchId: '',
    companyId: '',
    employmentStatus: 'Active',
    joinDate: new Date().toISOString().split('T')[0] || '',
    bankName: '',
    bankAccountNumber: '',
    accountHolderName: '',
    salary: 0,
    phoneNumber: '',
    birthPlace: '',
    birthDate: '',
    gender: 'MALE',
    maritalStatus: 'SINGLE',
    bpjsKesehatanNumber: '',
    bpjsKetenagakerjaanNumber: '',
    identityNumber: '',
    npwpNumber: '',
    lastName: '',
    addressKTP: '',
    addressResidential: '',
    emergencyContact: '',
    ptkpStatus: 'TK/0',
    managerId: 'none'
  }
  isSubmitting.value = false
  isModalOpen.value = true
}

const openEditModal = (user: any) => {
  isEditMode.value = true
  newEmployee.value = {
    id: user.id,
    name: user.first_name || '',
    email: user.user?.email || '',
    employeeIDNumber: user.employee_id_number || '',
    departmentId: user.department_id || '',
    jobPositionId: user.job_position_id || '',
    branchId: user.branch_id || '',
    companyId: user.company_id || '',
    employmentStatus: user.employment_status || 'Active',
    joinDate: user.join_date ? (new Date(user.join_date).toISOString().split('T')[0] || '') : '',
    bankName: user.bank_name || '',
    bankAccountNumber: user.bank_account_number || '',
    accountHolderName: user.account_holder_name || '',
    salary: user.salary || 0,
    phoneNumber: user.phone_number || '',
    birthPlace: user.birth_place || '',
    birthDate: user.birth_date ? (new Date(user.birth_date).toISOString().split('T')[0] || '') : '',
    gender: user.gender || 'MALE',
    maritalStatus: user.marital_status || 'SINGLE',
    bpjsKesehatanNumber: user.bpjs_kesehatan_number || '',
    bpjsKetenagakerjaanNumber: user.bpjs_ketenagakerjaan_number || '',
    identityNumber: user.identity_number || '',
    npwpNumber: user.npwp_number || '',
    lastName: user.last_name || '',
    addressKTP: user.address_ktp || '',
    addressResidential: user.address_residential || '',
    emergencyContact: user.emergency_contact || '',
    ptkpStatus: user.ptkp_status || 'TK/0',
    managerId: user.manager_id || 'none'
  }
  isSubmitting.value = false
  isModalOpen.value = true
}

const openSalaryModal = async (user: any) => {
    currentEmployee.value = user
    isSalaryModalOpen.value = true
    fetchSalarySettings(user.id)
}

const fetchSalarySettings = async (empID: string) => {
    try {
        const res = await apiClient.get(`/payroll/settings/${empID}`)
        salarySettings.value = res.data.data || []
    } catch (e) {
        toast.error('Gagal memuat rincian gaji.')
    }
}

const deleteSalarySetting = async (id: string) => {
    try {
        await apiClient.delete(`/payroll/settings/${id}`)
        toast.success('Komponen dihapus.')
        fetchSalarySettings(currentEmployee.value.id)
    } catch (e) {
        toast.error('Gagal menghapus komponen.')
    }
}

const addSalarySetting = async () => {
    if (!newSalarySetting.value.component_id) return
    isSalarySubmitting.value = true
    try {
        await apiClient.post(`/payroll/settings`, {
            employee_id: currentEmployee.value.id,
            component_id: newSalarySetting.value.component_id,
            amount: Number(newSalarySetting.value.amount)
        })
        toast.success('Komponen gaji ditambahkan.')
        newSalarySetting.value = { component_id: '', amount: 0 }
        fetchSalarySettings(currentEmployee.value.id)
    } catch (e) {
        toast.error('Gagal menambahkan komponen.')
    } finally {
        isSalarySubmitting.value = false
    }
}

const closeAddModal = () => {
  isModalOpen.value = false
}

const fetchEmployees = async () => {
  isLoading.value = true
  try {
    let url = '/employees?limit=50'
    if (selectedBranch.value !== 'all') {
      url += `&branch_id=${selectedBranch.value}`
    }
    const response = await apiClient.get(url)
    employees.value = response.data.data
  } catch (error) {
    console.error('Failed to fetch employees:', error)
  } finally {
    isLoading.value = false
  }
}

const exportCSV = async () => {
  try {
    let url = '/employees/export-csv?'
    if (selectedBranch.value !== 'all') {
      const branch = masterData.branches.find(b => b.id === selectedBranch.value)
      url += `branch_id=${selectedBranch.value}&branch_name=${branch?.name || ''}`
    }
    
    const response = await apiClient.get(url, { responseType: 'blob' })
    const blob = new Blob([response.data], { type: 'text/csv' })
    const downloadUrl = window.URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.href = downloadUrl
    link.setAttribute('download', `data_karyawan_${new Date().getTime()}.csv`)
    document.body.appendChild(link)
    link.click()
    link.remove()
    window.URL.revokeObjectURL(downloadUrl)
  } catch (error) {
    toast.error('Gagal mengunduh data karyawan.')
  }
}

const fetchPayrollComponents = async () => {
    try {
        const res = await apiClient.get('/payroll-components')
        payrollComponents.value = res.data.data || []
    } catch (e) {}
}

const saveEmployee = async () => {
  isSubmitting.value = true
  const payload = { 
    ...newEmployee.value, 
    salary: Number(newEmployee.value.salary),
    branchId: newEmployee.value.branchId || null,
    departmentId: newEmployee.value.departmentId || null,
    jobPositionId: newEmployee.value.jobPositionId || null,
    companyId: newEmployee.value.companyId || null,
    managerId: newEmployee.value.managerId === 'none' ? null : (newEmployee.value.managerId || null)
  }

  try {
    if (isEditMode.value) {
      await apiClient.put(`/employees/${newEmployee.value.id}`, payload)
      toast.success('Data Karyawan diperbarui.')
    } else {
      await apiClient.post('/employees', payload)
      toast.success('Karyawan ditambahkan.')
    }
    closeAddModal()
    fetchEmployees()
  } catch (error: any) {
    toast.error('Gagal menyimpan.')
  } finally {
    isSubmitting.value = false
  }
}

const deleteEmployee = async (id: string) => {
  if (!confirm('Hapus karyawan ini?')) return
  try {
    await apiClient.delete(`/employees/${id}`)
    toast.success('Berhasil dihapus.')
    fetchEmployees()
  } catch (error: any) {
    toast.error('Gagal menghapus.')
  }
}

onMounted(() => {
  fetchEmployees()
  fetchPayrollComponents()
  masterData.fetchDepartments()
  masterData.fetchJobPositions()
  masterData.fetchBranches()
  masterData.fetchCompanies()
})

const columns = [
  {
    accessorFn: (row: any) => `${row.first_name} ${row.last_name || ''}`.trim(),
    id: 'name',
    header: 'KARYAWAN',
    cell: ({ row }: any) => {
       const user = row.original
       return h('div', { class: 'flex flex-col py-1' }, [
         h('p', { class: 'font-extrabold text-slate-900 leading-tight group-hover:text-primary transition-colors' }, `${user.first_name} ${user.last_name || ''}`.trim()),
         h('p', { class: 'text-[11px] font-bold text-slate-400' }, user.user?.email || '-')
       ])
    }
  },
  {
    accessorFn: (row: any) => ({ id: row.employee_id_number, dept: row.department?.name, pos: row.job_position?.title }),
    id: 'identity',
    header: 'ID / JABATAN',
    cell: ({ getValue }: any) => {
      const { id, dept, pos } = getValue()
      return h('div', { class: 'flex flex-col' }, [
        h('span', { class: 'text-slate-900 font-black tracking-tighter text-sm' }, id || '-'),
        h('span', { class: 'text-slate-500 text-[11px] font-bold uppercase' }, `${pos || '-'} • ${dept || '-'}`)
      ])
    }
  },
  {
    id: 'branch',
    header: 'CABANG',
    cell: ({ row }: any) => {
      const branchName = row.original.branch?.name || '-'
      return h('span', { class: 'inline-flex items-center px-2.5 py-0.5 rounded-full text-[10px] font-black bg-slate-100 text-slate-600 border border-slate-200' }, branchName)
    }
  },
  {
    accessorFn: (row: any) => ({ place: row.birth_place, date: row.birth_date, gender: row.gender, marital: row.marital_status }),
    id: 'personal',
    header: 'DATA PERSONAL',
    cell: ({ getValue }: any) => {
      const { place, date, gender, marital } = getValue()
      const dateStr = date ? new Date(date).toLocaleDateString('id-ID') : '-'
      return h('div', { class: 'flex flex-col text-[12px]' }, [
        h('span', { class: 'text-slate-700 font-bold' }, `${place || '-'}, ${dateStr}`),
        h('span', { class: 'text-slate-400 font-medium italic' }, `${gender || '-'} • ${marital || '-'}`)
      ])
    }
  },
  {
    accessorFn: (row: any) => ({ ktp: row.identity_number, npwp: row.npwp_number, bpjsKs: row.bpjs_kesehatan_number, bpjsKt: row.bpjs_ketenagakerjaan_number }),
    id: 'government',
    header: 'DOKUMEN & BPJS',
    cell: ({ getValue }: any) => {
      const { ktp, npwp, bpjsKs, bpjsKt } = getValue()
      return h('div', { class: 'grid grid-cols-2 gap-x-4 gap-y-1 text-[11px]' }, [
        h('div', { class: 'flex flex-col' }, [
          h('span', { class: 'text-slate-400 font-bold uppercase text-[9px]' }, 'KTP'),
          h('span', { class: 'text-slate-700 font-black' }, ktp || '-')
        ]),
        h('div', { class: 'flex flex-col' }, [
          h('span', { class: 'text-slate-400 font-bold uppercase text-[9px]' }, 'NPWP'),
          h('span', { class: 'text-slate-700 font-black' }, npwp || '-')
        ]),
        h('div', { class: 'flex flex-col' }, [
          h('span', { class: 'text-emerald-600 font-bold uppercase text-[9px]' }, 'BPJS KS'),
          h('span', { class: 'text-emerald-700 font-black' }, bpjsKs || '-')
        ]),
        h('div', { class: 'flex flex-col' }, [
          h('span', { class: 'text-blue-600 font-bold uppercase text-[9px]' }, 'BPJS KT'),
          h('span', { class: 'text-blue-700 font-black' }, bpjsKt || '-')
        ])
      ])
    }
  },
  {
    accessorFn: (row: any) => ({ ktp: row.address_ktp, res: row.address_residential }),
    id: 'address',
    header: 'ALAMAT',
    cell: ({ getValue }: any) => {
      const { ktp, res } = getValue()
      return h('div', { class: 'flex flex-col gap-1 max-w-[200px]' }, [
        h('p', { class: 'text-[11px] text-slate-500 leading-tight line-clamp-1 italic', title: ktp }, ktp || '-'),
        h('p', { class: 'text-[11px] text-slate-700 leading-tight line-clamp-1 font-bold', title: res }, res || '-')
      ])
    }
  },
  {
    accessorFn: (row: any) => ({ phone: row.phone_number, emergency: row.emergency_contact }),
    id: 'contact',
    header: 'KONTAK',
    cell: ({ getValue }: any) => {
      const { phone, emergency } = getValue()
      return h('div', { class: 'flex flex-col text-[12px]' }, [
        h('span', { class: 'text-slate-900 font-black' }, phone || '-'),
        h('span', { class: 'text-rose-500 font-bold text-[10px]' }, emergency ? `EMG: ${emergency}` : '-')
      ])
    }
  },
  {
    accessorFn: (row: any) => ({ join: row.join_date, status: row.employment_status, manager: row.manager?.first_name }),
    id: 'employment',
    header: 'STATUS & JOIN',
    cell: ({ getValue }: any) => {
      const { join, status, manager } = getValue()
      const joinStr = join ? new Date(join).toLocaleDateString('id-ID') : '-'
      let cls = 'bg-emerald-50 text-emerald-700 border-emerald-100'
      if (status !== 'Active' && status !== 'Aktif') cls = 'bg-slate-50 text-slate-500 border-slate-100'
      return h('div', { class: 'flex flex-col gap-1' }, [
        h('span', { class: 'text-slate-700 font-black text-[12px]' }, joinStr),
        h('span', { class: `${cls} px-2 py-0.5 rounded-full text-[9px] font-black uppercase border w-fit` }, status || 'Active'),
        h('span', { class: 'text-slate-400 text-[10px] font-bold' }, manager ? `MG: ${manager}` : '-')
      ])
    }
  },
  {
    id: 'shift',
    header: 'SHIFT',
    cell: ({ row }: any) => {
      const shifts = row.original.employee_shifts
      let name = '-'
      if (shifts && shifts.length > 0) {
        name = shifts[0].shift?.name || '-'
      }
      return h('span', { class: 'bg-primary/5 text-primary px-3 py-1 rounded-xl text-[11px] font-black' }, name)
    }
  },
  {
    accessorKey: 'salary',
    header: 'GAJI',
    cell: (info: any) => {
      const val = info.getValue() || 0
      return h('span', { class: 'font-black text-slate-900 text-[14px]' }, 'Rp' + val.toLocaleString('id-ID'))
    }
  },
  {
    id: 'actions',
    header: 'AKSI',
    cell: ({ row }: any) => {
      const user = row.original
      return h('div', { class: 'flex items-center gap-1' }, [
        h(Button, { 
            variant: 'ghost', size: 'sm', class: 'h-8 px-1.5 text-primary hover:bg-primary/5 rounded-lg',
            onClick: () => openSalaryModal(user)
        }, () => h(Wallet, { class: 'w-4 h-4' })),
        h(Button, { 
            variant: 'ghost', size: 'sm', class: 'h-8 px-1.5 text-slate-400 hover:text-primary hover:bg-primary/5 rounded-lg',
            onClick: () => openEditModal(user)
        }, () => h(Pencil, { class: 'w-4 h-4' })),
        h(Button, { 
            variant: 'ghost', size: 'sm', class: 'h-8 px-1.5 text-rose-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg',
            onClick: () => deleteEmployee(user.id)
        }, () => h(Trash2, { class: 'w-4 h-4' }))
      ])
    }
  }
]
</script>

<template>
  <div class="space-y-8 pb-12 animate-in fade-in duration-700">
    <!-- Premium Header -->
    <div class="flex flex-col md:flex-row md:items-center justify-between gap-6">
      <div>
        <h1 class="text-3xl font-extrabold text-slate-900 tracking-tight flex items-center gap-3">
            Direktori Karyawan
        </h1>
        <p class="text-[14px] font-medium text-slate-500 mt-1.5 uppercase tracking-widest flex items-center gap-2">
          Manajemen Data Karyawan
        </p>
      </div>
      
      <div class="flex items-center gap-3">
        <Select v-model="selectedBranch" @update:modelValue="fetchEmployees">
          <SelectTrigger class="w-[200px] h-12 rounded-2xl border-none bg-white shadow-xl shadow-slate-100/50 font-bold px-6 text-slate-600 focus:ring-2 focus:ring-primary/20 transition-all">
            <SelectValue placeholder="Semua Cabang" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Semua Cabang</SelectItem>
            <SelectItem v-for="b in masterData.branches" :key="b.id" :value="b.id">
              {{ b.name }}
            </SelectItem>
          </SelectContent>
        </Select>

        <Button variant="outline" @click="exportCSV" class="h-12 px-5 rounded-2xl font-bold border-2 border-slate-50 bg-white shadow-xl shadow-slate-100/50 text-slate-600 gap-2 hover:bg-slate-50 transition-all active:scale-95">
          <Download class="w-5 h-5" /> EXPORT
        </Button>

        <Button @click="openAddModal" class="gap-2 shadow-xl shadow-primary/20 rounded-2xl h-12 px-6 font-black bg-primary hover:bg-primary/90 transition-all hover:scale-105 active:scale-95">
          <Plus class="w-5 h-5" /> TAMBAH KARYAWAN
        </Button>
      </div>
    </div>

    <!-- DataTable Area -->
    <div class="bg-white rounded-[2.5rem] border border-slate-200 shadow-2xl shadow-slate-100/50 overflow-hidden">
        <DataTable :data="employees" :columns="columns" :isLoading="isLoading" />
    </div>

    <!-- Salary Management Modal -->
    <Dialog v-model:open="isSalaryModalOpen">
      <DialogContent class="sm:max-w-2xl rounded-[2rem] md:rounded-[3rem] p-0 overflow-hidden border-none shadow-2xl max-h-[95vh] flex flex-col">
        <div class="bg-gradient-to-br from-primary to-primary/80 p-8 md:p-10 text-white relative shrink-0">
            <button @click="isSalaryModalOpen = false" class="absolute top-6 right-6 p-2 rounded-full bg-white/10 hover:bg-white/20 transition-colors z-20">
                <X class="w-5 h-5 text-white" />
            </button>
            <DialogHeader class="relative z-10">
                <div class="w-12 h-12 md:w-14 md:h-14 bg-white/10 rounded-2xl flex items-center justify-center mb-4 md:mb-6 border border-white/20">
                    <Banknote class="w-6 h-6 md:w-8 md:h-8 text-white" />
                </div>
                <DialogTitle class="text-xl md:text-2xl font-black">Atur Struktur Gaji</DialogTitle>
                <DialogDescription class="text-white/70 font-bold mt-2 uppercase text-[10px] md:text-[11px] tracking-[0.2em] border-l-4 border-white/30 pl-4">
                    {{ currentEmployee?.first_name }} • {{ currentEmployee?.job_position?.title }}
                </DialogDescription>
            </DialogHeader>
            <Wallet class="absolute -right-10 -bottom-10 w-32 md:w-48 h-32 md:h-48 opacity-10" />
        </div>

        <div class="p-6 md:p-10 bg-white grid grid-cols-1 md:grid-cols-12 gap-8 md:gap-10 overflow-y-auto custom-scrollbar">
            <!-- Left: Add New Component -->
            <div class="md:col-span-12 lg:col-span-5 space-y-6">
                <h3 class="text-sm font-black text-slate-400 uppercase tracking-widest mb-6 border-b border-slate-100 pb-2">Tambah Komponen</h3>
                
                <div class="space-y-4">
                    <label class="text-[11px] font-black text-slate-500 uppercase tracking-widest block ml-1">Komponen Gaji</label>
                    <Select v-model="newSalarySetting.component_id">
                        <SelectTrigger class="h-14 rounded-2xl border-2 border-slate-50 bg-slate-50 font-bold focus:ring-0 focus:border-primary transition-all px-6">
                            <SelectValue placeholder="Pilih..." />
                        </SelectTrigger>
                        <SelectContent>
                            <SelectItem v-for="c in payrollComponents" :key="c.id" :value="c.id">
                                {{ c.name }} ({{ c.type }})
                            </SelectItem>
                        </SelectContent>
                    </Select>
                </div>

                <div class="space-y-4">
                    <label class="text-[11px] font-black text-slate-500 uppercase tracking-widest block ml-1">Nominal (Rp)</label>
                    <Input type="number" v-model="newSalarySetting.amount" class="h-14 rounded-2xl border-2 border-slate-50 bg-slate-50 font-black text-lg focus:ring-0 focus:border-primary transition-all px-6" />
                </div>

                <Button @click="addSalarySetting" :disabled="isSalarySubmitting" class="w-full h-14 rounded-2xl bg-slate-900 hover:bg-slate-800 text-white font-black tracking-wide shadow-lg transform active:scale-95 transition-all">
                    {{ isSalarySubmitting ? 'MENYIMPAN...' : 'TAMBAHKAN' }}
                </Button>
            </div>

            <!-- Right: List Components -->
            <div class="md:col-span-12 lg:col-span-7">
                <h3 class="text-sm font-black text-slate-400 uppercase tracking-widest mb-6 border-b border-slate-100 pb-2">Rincian Pendapatan & Potongan</h3>
                
                <div class="space-y-3 max-h-[350px] overflow-y-auto pr-2 no-scrollbar">
                    <div v-if="salarySettings.length === 0" class="py-12 text-center text-slate-300 font-bold flex flex-col items-center">
                        <Plus class="w-10 h-10 mb-2 opacity-20" />
                        BELUM ADA KOMPONEN
                    </div>
                    <div v-for="s in salarySettings" :key="s.id" class="flex items-center justify-between p-5 bg-slate-50 rounded-2xl border border-slate-100/50 hover:border-primary/20 transition-all group">
                        <div class="flex items-center gap-4">
                            <div :class="[
                                'w-10 h-10 rounded-xl flex items-center justify-center border',
                                s.component?.type === 'EARNING' ? 'bg-emerald-50 text-emerald-600 border-emerald-100' : 'bg-rose-50 text-rose-600 border-rose-100'
                            ]">
                                <TrendingUp v-if="s.component?.type === 'EARNING'" class="w-5 h-5" />
                                <ShieldAlert v-else class="w-5 h-5" />
                            </div>
                            <div class="flex flex-col">
                                <span class="text-[13px] font-black text-slate-900 uppercase tracking-tight">{{ s.component?.name }}</span>
                                <span class="text-[13px] font-bold text-slate-500">Rp {{ s.amount.toLocaleString('id-ID') }}</span>
                            </div>
                        </div>
                        <button @click="deleteSalarySetting(s.id)" class="opacity-0 group-hover:opacity-100 p-2 text-slate-300 hover:text-rose-600 transition-all">
                            <X class="w-5 h-5" />
                        </button>
                    </div>
                </div>

                <div class="mt-8 bg-slate-900 p-6 rounded-[2rem] text-white">
                    <div class="flex justify-between items-center mb-1">
                        <span class="text-[10px] font-black uppercase text-slate-500 tracking-[0.2em]">Estimasi THP Bersih</span>
                        <span class="text-lg font-black text-primary">Rp {{ (currentEmployee?.salary + salarySettings.reduce((a, b) => b.component?.type === 'EARNING' ? a + b.amount : a - b.amount, 0)).toLocaleString('id-ID') }}</span>
                    </div>
                    <p class="text-[9px] font-bold text-slate-500">* Belum termasuk BPJS & Pajak PPh21.</p>
                </div>
            </div>
        </div>
        
        <div class="p-8 pt-0 bg-white border-t border-slate-50 flex justify-end">
            <Button variant="ghost" @click="isSalaryModalOpen = false" class="rounded-2xl h-12 px-10 font-black text-slate-400">SELESAI</Button>
        </div>
      </DialogContent>
    </Dialog>

    <!-- Employee Form Modal (Basic Data) -->
    <Dialog v-model:open="isModalOpen">
      <DialogContent class="sm:max-w-3xl rounded-[2rem] md:rounded-[3rem] p-0 overflow-hidden border-none shadow-2xl max-h-[95vh] flex flex-col">
        <div class="bg-slate-900 p-8 md:p-10 text-white relative shrink-0">
            <button @click="isModalOpen = false" class="absolute top-6 right-6 p-2 rounded-full bg-white/10 hover:bg-white/20 transition-colors z-20">
                <X class="w-5 h-5 text-white" />
            </button>
            <DialogHeader>
                <DialogTitle class="text-xl md:text-2xl font-black">{{ isEditMode ? 'Edit Data Personal' : 'Tambah Karyawan Baru' }}</DialogTitle>
                <DialogDescription class="text-slate-400 font-bold mt-2 uppercase text-[10px] md:text-[11px] tracking-widest border-l-4 border-primary pl-4">
                    Pusat Informasi Personel & Administrasi
                </DialogDescription>
            </DialogHeader>
        </div>

        <div class="p-6 md:p-10 bg-white space-y-10 overflow-y-auto custom-scrollbar">
            <!-- Section 1: Account & Work -->
            <div class="space-y-6">
                <h4 class="text-xs font-black text-slate-400 uppercase tracking-[0.2em] border-l-4 border-primary pl-4">Akun & Pekerjaan</h4>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div class="space-y-2">
                        <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Nama Depan</label>
                        <Input v-model="newEmployee.name" placeholder="Contoh: John" class="h-12 rounded-xl bg-slate-50 border-none font-bold" />
                    </div>
                    <div class="space-y-2">
                        <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Nama Belakang</label>
                        <Input v-model="newEmployee.lastName" placeholder="Contoh: Doe" class="h-12 rounded-xl bg-slate-50 border-none font-bold" />
                    </div>
                </div>
                <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                    <div class="space-y-2">
                        <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Email Corporate</label>
                        <Input v-model="newEmployee.email" type="email" placeholder="john@company.com" :disabled="isEditMode" class="h-12 rounded-xl bg-slate-50 border-none font-bold disabled:opacity-50" />
                    </div>
                    <div class="space-y-2">
                        <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Perusahaan</label>
                        <Select v-model="newEmployee.companyId">
                            <SelectTrigger class="h-12 rounded-xl bg-slate-50 border-none font-bold">
                                <SelectValue placeholder="Pilih Perusahaan" />
                            </SelectTrigger>
                            <SelectContent>
                                <SelectItem v-for="c in masterData.companies" :key="c.id" :value="c.id">{{ c.name }}</SelectItem>
                            </SelectContent>
                        </Select>
                    </div>
                    <div class="space-y-2">
                        <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Cabang</label>
                        <Select v-model="newEmployee.branchId">
                            <SelectTrigger class="h-12 rounded-xl bg-slate-50 border-none font-bold">
                                <SelectValue placeholder="Pilih Cabang" />
                            </SelectTrigger>
                            <SelectContent>
                                <SelectItem v-for="b in masterData.branches" :key="b.id" :value="b.id">{{ b.name }}</SelectItem>
                            </SelectContent>
                        </Select>
                    </div>
                </div>
                <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                    <div class="space-y-2">
                        <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Departemen</label>
                        <Select v-model="newEmployee.departmentId">
                            <SelectTrigger class="h-12 rounded-xl bg-slate-50 border-none font-bold">
                                <SelectValue placeholder="Pilih..." />
                            </SelectTrigger>
                            <SelectContent>
                                <SelectItem v-for="d in masterData.departments" :key="d.id" :value="d.id">{{ d.name }}</SelectItem>
                            </SelectContent>
                        </Select>
                    </div>
                    <div class="space-y-2">
                        <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Jabatan</label>
                        <Select v-model="newEmployee.jobPositionId">
                            <SelectTrigger class="h-12 rounded-xl bg-slate-50 border-none font-bold">
                                <SelectValue placeholder="Pilih..." />
                            </SelectTrigger>
                            <SelectContent>
                                <SelectItem v-for="j in masterData.jobPositions" :key="j.id" :value="j.id">{{ j.title }}</SelectItem>
                            </SelectContent>
                        </Select>
                    </div>
                    <div class="space-y-2">
                        <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Langsung Ke (Manager)</label>
                        <Select v-model="newEmployee.managerId">
                            <SelectTrigger class="h-12 rounded-xl bg-slate-50 border-none font-bold">
                                <SelectValue placeholder="Pilih Manager" />
                            </SelectTrigger>
                            <SelectContent>
                                <SelectItem value="none">Tanpa Manager</SelectItem>
                                <SelectItem v-for="e in employees" :key="e.id" :value="e.id">{{ e.first_name }} {{ e.last_name }}</SelectItem>
                            </SelectContent>
                        </Select>
                    </div>
                </div>
                <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                    <div class="space-y-2">
                        <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Tgl Join</label>
                        <Input v-model="newEmployee.joinDate" type="date" class="h-12 rounded-xl bg-slate-50 border-none font-bold" />
                    </div>
                    <div class="space-y-2">
                        <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Status</label>
                        <Select v-model="newEmployee.employmentStatus">
                            <SelectTrigger class="h-12 rounded-xl bg-slate-50 border-none font-bold">
                                <SelectValue />
                            </SelectTrigger>
                            <SelectContent>
                                <SelectItem value="Active">Aktif</SelectItem>
                                <SelectItem value="Inactive">Non-Aktif</SelectItem>
                            </SelectContent>
                        </Select>
                    </div>
                    <div class="space-y-2">
                        <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Gaji Pokok</label>
                        <Input v-model="newEmployee.salary" type="number" class="h-12 rounded-xl bg-primary/5 border-none font-black text-primary" />
                    </div>
                </div>
            </div>

            <!-- Section 2: Personal -->
            <div class="space-y-6">
                <h4 class="text-xs font-black text-slate-400 uppercase tracking-[0.2em] border-l-4 border-primary pl-4">Data Personal</h4>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div class="space-y-2">
                        <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Tempat Lahir</label>
                        <Input v-model="newEmployee.birthPlace" placeholder="Jakarta" class="h-12 rounded-xl bg-slate-50 border-none font-bold" />
                    </div>
                    <div class="space-y-2">
                        <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Tanggal Lahir</label>
                        <Input v-model="newEmployee.birthDate" type="date" class="h-12 rounded-xl bg-slate-50 border-none font-bold" />
                    </div>
                </div>
                <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                    <div class="space-y-2">
                        <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Jenis Kelamin</label>
                        <Select v-model="newEmployee.gender">
                            <SelectTrigger class="h-12 rounded-xl bg-slate-50 border-none font-bold">
                                <SelectValue />
                            </SelectTrigger>
                            <SelectContent>
                                <SelectItem value="MALE">Laki-laki</SelectItem>
                                <SelectItem value="FEMALE">Perempuan</SelectItem>
                            </SelectContent>
                        </Select>
                    </div>
                    <div class="space-y-2">
                        <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Status Marital</label>
                        <Select v-model="newEmployee.maritalStatus">
                            <SelectTrigger class="h-12 rounded-xl bg-slate-50 border-none font-bold">
                                <SelectValue />
                            </SelectTrigger>
                            <SelectContent>
                                <SelectItem value="SINGLE">Lajang</SelectItem>
                                <SelectItem value="MARRIED">Menikah</SelectItem>
                                <SelectItem value="WIDOWED">Janda/Duda</SelectItem>
                            </SelectContent>
                        </Select>
                    </div>
                    <div class="space-y-2">
                        <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Status PTKP</label>
                        <Select v-model="newEmployee.ptkpStatus">
                            <SelectTrigger class="h-12 rounded-xl bg-slate-50 border-none font-bold">
                                <SelectValue />
                            </SelectTrigger>
                            <SelectContent>
                                <SelectItem value="TK/0">TK/0</SelectItem>
                                <SelectItem value="K/0">K/0</SelectItem>
                                <SelectItem value="K/1">K/1</SelectItem>
                                <SelectItem value="K/2">K/2</SelectItem>
                                <SelectItem value="K/3">K/3</SelectItem>
                            </SelectContent>
                        </Select>
                    </div>
                </div>
            </div>

            <!-- Section 3: Identity & BPJS -->
            <div class="space-y-6">
                <h4 class="text-xs font-black text-slate-400 uppercase tracking-[0.2em] border-l-4 border-primary pl-4">Identitas & BPJS</h4>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div class="space-y-2">
                        <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">NIK (KTP)</label>
                        <Input v-model="newEmployee.identityNumber" placeholder="320..." class="h-12 rounded-xl bg-slate-50 border-none font-bold" />
                    </div>
                    <div class="space-y-2">
                        <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">NPWP</label>
                        <Input v-model="newEmployee.npwpNumber" placeholder="00..." class="h-12 rounded-xl bg-slate-50 border-none font-bold" />
                    </div>
                </div>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div class="space-y-2">
                        <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">No. BPJS Kesehatan</label>
                        <Input v-model="newEmployee.bpjsKesehatanNumber" class="h-12 rounded-xl bg-emerald-50 border-none font-bold text-emerald-700" />
                    </div>
                    <div class="space-y-2">
                        <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">No. BPJS Ketenagakerjaan</label>
                        <Input v-model="newEmployee.bpjsKetenagakerjaanNumber" class="h-12 rounded-xl bg-blue-50 border-none font-bold text-blue-700" />
                    </div>
                </div>
            </div>

            <!-- Section 4: Address & Contact -->
            <div class="space-y-6">
                <h4 class="text-xs font-black text-slate-400 uppercase tracking-[0.2em] border-l-4 border-primary pl-4">Alamat & Kontak</h4>
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div class="space-y-2">
                        <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">No. Telepon</label>
                        <Input v-model="newEmployee.phoneNumber" placeholder="0812..." class="h-12 rounded-xl bg-slate-50 border-none font-bold" />
                    </div>
                    <div class="space-y-2">
                        <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Kontak Darurat</label>
                        <Input v-model="newEmployee.emergencyContact" placeholder="Nama - Hubungan - No. HP" class="h-12 rounded-xl bg-rose-50 border-none font-bold text-rose-700" />
                    </div>
                </div>
                <div class="space-y-2">
                    <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Alamat Sesuai KTP</label>
                    <Input v-model="newEmployee.addressKTP" class="h-12 rounded-xl bg-slate-50 border-none font-bold" />
                </div>
                <div class="space-y-2">
                    <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Alamat Domisili</label>
                    <Input v-model="newEmployee.addressResidential" class="h-12 rounded-xl bg-slate-50 border-none font-bold" />
                </div>
            </div>

            <!-- Section 5: Bank -->
            <div class="space-y-6">
                <h4 class="text-xs font-black text-slate-400 uppercase tracking-[0.2em] border-l-4 border-primary pl-4">Data Rekening</h4>
                <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                    <div class="space-y-2">
                        <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Bank</label>
                        <Select v-model="newEmployee.bankName">
                            <SelectTrigger class="h-12 rounded-xl bg-slate-50 border-none font-bold">
                                <SelectValue placeholder="Pilih Bank" />
                            </SelectTrigger>
                            <SelectContent>
                                <SelectItem value="BCA">BCA</SelectItem>
                                <SelectItem value="MANDIRI">MANDIRI</SelectItem>
                                <SelectItem value="BNI">BNI</SelectItem>
                                <SelectItem value="BRI">BRI</SelectItem>
                                <SelectItem value="BANK JAGO">BANK JAGO</SelectItem>
                            </SelectContent>
                        </Select>
                    </div>
                    <div class="space-y-2">
                        <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">No. Rekening</label>
                        <Input v-model="newEmployee.bankAccountNumber" class="h-12 rounded-xl bg-slate-50 border-none font-bold" />
                    </div>
                    <div class="space-y-2">
                        <label class="text-[10px] font-black text-slate-500 uppercase tracking-widest ml-1">Atas Nama</label>
                        <Input v-model="newEmployee.accountHolderName" class="h-12 rounded-xl bg-slate-50 border-none font-bold" />
                    </div>
                </div>
            </div>
        </div>

        <DialogFooter class="p-8 md:p-10 pt-0 bg-white grid grid-cols-2 gap-4 shrink-0">
          <Button variant="ghost" @click="isModalOpen = false" :disabled="isSubmitting" class="rounded-2xl h-12 md:h-14 font-black text-slate-400 border border-slate-100 hover:bg-slate-50">BATAL</Button>
          <Button @click="saveEmployee" :disabled="isSubmitting" class="bg-primary hover:bg-primary/90 text-white rounded-2xl h-12 md:h-14 font-black shadow-xl shadow-primary/20 transform active:scale-95 transition-all">
            {{ isSubmitting ? 'MENYIMPAN...' : 'SIMPAN PERUBAHAN' }}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  </div>
</template>
