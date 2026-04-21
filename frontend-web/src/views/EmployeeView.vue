<script setup lang="ts">
import { ref, h, onMounted } from 'vue'
import { Pencil, Trash2, Wallet, Plus, X, Landmark, TrendingUp, ShieldAlert, Banknote } from 'lucide-vue-next'
import apiClient from '@/api/axios'
import DataTable from '@/components/DataTable.vue'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectGroup, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { toast } from 'vue-sonner'

import { useMasterDataStore } from '@/stores/masterData'

const masterData = useMasterDataStore()

const isModalOpen = ref(false)
const newEmployee = ref({
  id: '',
  name: '',
  email: '',
  employeeIDNumber: '',
  departmentId: '',
  jobPositionId: '',
  branchId: '',
  employmentStatus: 'Active',
  joinDate: new Date().toISOString().split('T')[0],
  bankName: '',
  bankAccountNumber: '',
  accountHolderName: '',
  salary: 0,
  phoneNumber: ''
})

const isEditMode = ref(false)
const isSubmitting = ref(false)
const employees = ref<any[]>([])
const isLoading = ref(true)

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
    employmentStatus: 'Active',
    joinDate: new Date().toISOString().split('T')[0],
    bankName: '',
    bankAccountNumber: '',
    accountHolderName: '',
    salary: 0,
    phoneNumber: ''
  }
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
    employmentStatus: user.employment_status || 'Active',
    joinDate: user.join_date ? new Date(user.join_date).toISOString().split('T')[0] : '',
    bankName: user.bank_name || '',
    bankAccountNumber: user.bank_account_number || '',
    accountHolderName: user.account_holder_name || '',
    salary: user.salary || 0,
    phoneNumber: user.phone_number || ''
  }
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
    const response = await apiClient.get('/employees?limit=50')
    employees.value = response.data.data
  } catch (error) {
    console.error('Failed to fetch employees:', error)
  } finally {
    isLoading.value = false
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
    jobPositionId: newEmployee.value.jobPositionId || null
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
})

const columns = [
  {
    accessorFn: (row: any) => row.first_name || 'Unnamed',
    id: 'name',
    header: 'KARYAWAN',
    cell: ({ row }: any) => {
       const user = row.original
       return h('div', { class: 'flex flex-col py-1' }, [
         h('p', { class: 'font-black text-slate-900 leading-tight' }, user.first_name || 'Unnamed'),
         h('p', { class: 'text-[11px] font-bold text-slate-400' }, user.user?.email || '-')
       ])
    }
  },
  {
    accessorKey: 'employee_id_number',
    header: 'ID #',
    cell: (info: any) => h('span', { class: 'text-slate-500 text-[12px] font-black tracking-tighter' }, info.getValue() || '-')
  },
  {
    accessorKey: 'phone_number',
    header: 'KONTAK',
    cell: (info: any) => h('span', { class: 'text-slate-600 text-[12px] font-bold' }, info.getValue() || '-')
  },
  {
    accessorFn: (row: any) => row.job_position?.title || '-',
    id: 'jobPosition',
    header: 'JABATAN',
    cell: (info: any) => h('span', { class: 'font-black text-indigo-600 text-[12px]' }, info.getValue())
  },
  {
    accessorKey: 'salary',
    header: 'GAJI POKOK',
    cell: (info: any) => {
      const val = info.getValue() || 0
      return h('span', { class: 'font-black text-slate-900 text-[13px]' }, 'Rp ' + val.toLocaleString('id-ID'))
    }
  },
  {
    accessorKey: 'employment_status',
    header: 'STATUS',
    cell: ({ getValue }: any) => {
        const val = getValue() as string || 'Active'
        let cls = 'bg-emerald-50 text-emerald-700 border-emerald-100'
        if (val !== 'Active' && val !== 'Aktif') cls = 'bg-slate-50 text-slate-500 border-slate-100'
        return h('span', { class: `${cls} px-3 py-1 rounded-full text-[10px] font-black uppercase border` }, val)
    }
  },
  {
    id: 'actions',
    header: 'AKSI',
    cell: ({ row }: any) => {
      const user = row.original
      return h('div', { class: 'flex items-center gap-2' }, [
        h(Button, { 
            variant: 'ghost', size: 'sm', class: 'h-9 px-2 text-indigo-600 hover:bg-indigo-50 rounded-xl',
            onClick: () => openSalaryModal(user)
        }, () => h(Wallet, { class: 'w-4.5 h-4.5' })),
        h(Button, { 
            variant: 'ghost', size: 'sm', class: 'h-9 px-2 text-slate-400 hover:text-indigo-600 hover:bg-indigo-50 rounded-xl',
            onClick: () => openEditModal(user)
        }, () => h(Pencil, { class: 'w-4 h-4' })),
        h(Button, { 
            variant: 'ghost', size: 'sm', class: 'h-9 px-2 text-rose-400 hover:text-rose-600 hover:bg-rose-50 rounded-xl',
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
        <h1 class="text-3xl font-black text-slate-900 tracking-tight flex items-center gap-3">
            <Plus class="w-8 h-8 text-indigo-600 bg-indigo-50 p-1.5 rounded-xl border border-indigo-100" />
            Direktori Karyawan
        </h1>
        <p class="text-[14px] font-medium text-slate-400 mt-1 uppercase tracking-widest">Manajemen Personel & Payroll Profile</p>
      </div>
      
      <Button @click="openAddModal" class="gap-2 shadow-xl shadow-indigo-100 rounded-2xl h-12 px-6 font-black bg-indigo-600 hover:bg-indigo-700 transition-all hover:scale-105 active:scale-95">
        <Plus class="w-5 h-5" /> TAMBAH KARYAWAN
      </Button>
    </div>

    <!-- DataTable Area -->
    <div class="bg-white rounded-[2.5rem] border border-slate-200 shadow-2xl shadow-slate-100/50 overflow-hidden">
        <DataTable :data="employees" :columns="columns" :isLoading="isLoading" />
    </div>

    <!-- Salary Management Modal -->
    <Dialog v-model:open="isSalaryModalOpen">
      <DialogContent class="sm:max-w-2xl rounded-[3rem] p-0 overflow-hidden border-none shadow-2xl">
        <div class="bg-gradient-to-br from-indigo-600 to-indigo-800 p-10 text-white relative">
            <DialogHeader class="relative z-10">
                <div class="w-14 h-14 bg-white/10 rounded-2xl flex items-center justify-center mb-6 border border-white/20">
                    <Banknote class="w-8 h-8 text-white" />
                </div>
                <DialogTitle class="text-2xl font-black">Atur Struktur Gaji</DialogTitle>
                <DialogDescription class="text-indigo-100 font-bold opacity-80 mt-2 uppercase text-[11px] tracking-[0.2em] border-l-4 border-white/30 pl-4">
                    {{ currentEmployee?.first_name }} • {{ currentEmployee?.job_position?.title }}
                </DialogDescription>
            </DialogHeader>
            <Wallet class="absolute -right-10 -bottom-10 w-48 h-48 opacity-10" />
        </div>

        <div class="p-10 bg-white grid grid-cols-1 md:grid-cols-12 gap-10">
            <!-- Left: Add New Component -->
            <div class="md:col-span-12 lg:col-span-5 space-y-6">
                <h3 class="text-sm font-black text-slate-400 uppercase tracking-widest mb-6 border-b border-slate-100 pb-2">Tambah Komponen</h3>
                
                <div class="space-y-4">
                    <label class="text-[11px] font-black text-slate-500 uppercase tracking-widest block ml-1">Komponen Gaji</label>
                    <Select v-model="newSalarySetting.component_id">
                        <SelectTrigger class="h-14 rounded-2xl border-2 border-slate-50 bg-slate-50 font-bold focus:ring-0 focus:border-indigo-600 transition-all px-6">
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
                    <Input type="number" v-model="newSalarySetting.amount" class="h-14 rounded-2xl border-2 border-slate-50 bg-slate-50 font-black text-lg focus:ring-0 focus:border-indigo-600 transition-all px-6" />
                </div>

                <Button @click="addSalarySetting" :disabled="isSalarySubmitting" class="w-full h-14 rounded-2xl bg-slate-900 hover:bg-slate-800 text-white font-black tracking-wide shadow-lg">
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
                    <div v-for="s in salarySettings" :key="s.id" class="flex items-center justify-between p-5 bg-slate-50 rounded-2xl border border-slate-100/50 hover:border-indigo-100 transition-all group">
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
                        <span class="text-lg font-black text-indigo-400">Rp {{ (currentEmployee?.salary + salarySettings.reduce((a, b) => b.component?.type === 'EARNING' ? a + b.amount : a - b.amount, 0)).toLocaleString('id-ID') }}</span>
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
      <DialogContent class="sm:max-w-3xl rounded-[3rem] p-0 overflow-hidden border-none shadow-2xl">
        <div class="bg-slate-900 p-10 text-white relative">
            <DialogHeader>
                <DialogTitle class="text-2xl font-black">{{ isEditMode ? 'Edit Data Personal' : 'Tambah Karyawan Baru' }}</DialogTitle>
                <DialogDescription class="text-slate-400 font-bold mt-2 uppercase text-[11px] tracking-widest border-l-4 border-indigo-600 pl-4">
                    Pusat Informasi Personel & Administrasi
                </DialogDescription>
            </DialogHeader>
        </div>

        <div class="p-10 bg-white space-y-8">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
              <div class="space-y-3">
                <label class="text-[11px] font-black text-slate-500 uppercase tracking-widest ml-1">Nama Lengkap</label>
                <Input v-model="newEmployee.name" placeholder="John Doe" class="h-14 rounded-2xl bg-slate-50 border-none font-bold focus:ring-2 focus:ring-indigo-600" />
              </div>
              <div class="space-y-3">
                <label class="text-[11px] font-black text-slate-500 uppercase tracking-widest ml-1">Email Corporate</label>
                <Input v-model="newEmployee.email" type="email" placeholder="john@company.com" :disabled="isEditMode" class="h-14 rounded-2xl bg-slate-50 border-none font-bold focus:ring-2 focus:ring-indigo-600 disabled:opacity-50" />
              </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
              <div class="space-y-3">
                <label class="text-[11px] font-black text-slate-500 uppercase tracking-widest ml-1">Departemen</label>
                <Select v-model="newEmployee.departmentId">
                  <SelectTrigger class="h-14 rounded-2xl bg-slate-50 border-none font-bold">
                    <SelectValue placeholder="Pilih..." />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem v-for="d in masterData.departments" :key="d.id" :value="d.id">{{ d.name }}</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div class="space-y-3">
                <label class="text-[11px] font-black text-slate-500 uppercase tracking-widest ml-1">Jabatan</label>
                <Select v-model="newEmployee.jobPositionId">
                  <SelectTrigger class="h-14 rounded-2xl bg-slate-50 border-none font-bold">
                    <SelectValue placeholder="Pilih..." />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem v-for="j in masterData.jobPositions" :key="j.id" :value="j.id">{{ j.name }}</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div class="space-y-3">
                <label class="text-[11px] font-black text-slate-500 uppercase tracking-widest ml-1">Gaji Pokok (Salary)</label>
                <Input v-model="newEmployee.salary" type="number" class="h-14 rounded-2xl bg-indigo-50/50 border-none font-black text-indigo-700" />
              </div>
            </div>

            <div class="h-px bg-slate-100"></div>
            <h4 class="text-xs font-black text-slate-400 uppercase tracking-[0.2em] border-l-4 border-indigo-600 pl-4">Data Rekening Bank</h4>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
              <div class="space-y-3">
                <label class="text-[11px] font-black text-slate-500 uppercase tracking-widest ml-1">Nama Bank</label>
                <Select v-model="newEmployee.bankName">
                  <SelectTrigger class="h-14 rounded-2xl bg-slate-50 border-none font-bold">
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
              <div class="space-y-3 md:col-span-2">
                <label class="text-[11px] font-black text-slate-500 uppercase tracking-widest ml-1">Nomor Rekening</label>
                <Input v-model="newEmployee.bankAccountNumber" class="h-14 rounded-2xl bg-slate-50 border-none font-bold" />
              </div>
            </div>
        </div>

        <DialogFooter class="p-10 pt-0 bg-white grid grid-cols-2 gap-4">
          <Button variant="ghost" @click="closeAddModal" :disabled="isSubmitting" class="rounded-2xl h-14 font-black text-slate-400 border border-slate-100 hover:bg-slate-50">BATAL</Button>
          <Button @click="saveEmployee" :disabled="isSubmitting" class="bg-indigo-600 hover:bg-indigo-700 text-white rounded-2xl h-14 font-black shadow-xl shadow-indigo-100 transform active:scale-95 transition-all">
            {{ isSubmitting ? 'MENYIMPAN...' : 'SIMPAN PERUBAHAN' }}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  </div>
</template>
