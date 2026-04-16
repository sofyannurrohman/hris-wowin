<script setup lang="ts">
import { ref, h, onMounted } from 'vue'
import { Pencil, Trash2 } from 'lucide-vue-next'
import apiClient from '@/api/axios'
import DataTable from '@/components/DataTable.vue'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectGroup, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { toast } from 'vue-sonner'

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
const departments = ref<any[]>([])
const jobPositions = ref<any[]>([])
const branches = ref<any[]>([])
const isLoading = ref(true)

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
    id: user.ID,
    name: user.FirstName || '',
    email: user.User?.Email || '',
    employeeIDNumber: user.EmployeeIDNumber || '',
    departmentId: user.DepartmentID || '',
    jobPositionId: user.JobPositionID || '',
    branchId: user.BranchID || '',
    employmentStatus: user.EmploymentStatus || 'Active',
    joinDate: user.JoinDate ? new Date(user.JoinDate).toISOString().split('T')[0] : '',
    bankName: user.BankName || '',
    bankAccountNumber: user.BankAccountNumber || '',
    accountHolderName: user.AccountHolderName || '',
    salary: user.Salary || 0,
    phoneNumber: user.PhoneNumber || ''
  }
  isModalOpen.value = true
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

const fetchDepartments = async () => {
  try {
    const res = await apiClient.get('/departments')
    departments.value = res.data.data
  } catch (err) {
    console.error(err)
  }
}

const fetchJobPositions = async () => {
  try {
    const res = await apiClient.get('/job-positions')
    jobPositions.value = res.data.data
  } catch (err) {
    console.error(err)
  }
}

const fetchBranches = async () => {
  try {
    const res = await apiClient.get('/branches')
    branches.value = res.data.data
  } catch (err) {
    console.error(err)
  }
}

const saveEmployee = async () => {
  isSubmitting.value = true
  
  // Sanitize data: convert empty strings to null for UUID fields
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
      toast.success('Data Karyawan berhasil diperbarui!')
    } else {
      await apiClient.post('/employees', payload)
      toast.success('Karyawan berhasil ditambahkan!')
    }
    closeAddModal()
    fetchEmployees() // Refresh data
  } catch (error: any) {
    toast.error(`Gagal ${isEditMode.value ? 'memperbarui' : 'menambahkan'} karyawan: ` + (error.response?.data?.message || error.message))
  } finally {
    isSubmitting.value = false
  }
}

const deleteEmployee = async (id: string) => {
  if (!confirm('Apakah Anda yakin ingin menghapus karyawan ini? Operasi ini tidak dapat dibatalkan.')) return
  
  try {
    await apiClient.delete(`/employees/${id}`)
    toast.success('Karyawan berhasil dihapus!')
    fetchEmployees()
  } catch (error: any) {
    toast.error('Gagal menghapus karyawan: ' + (error.response?.data?.message || error.message))
  }
}

onMounted(() => {
  fetchEmployees()
  fetchDepartments()
  fetchJobPositions()
  fetchBranches()
})



const columns = [
  {
    accessorFn: (row: any) => `${row.name} ${row.email}`,
    id: 'name',
    header: 'KARYAWAN',
    cell: ({ row }: any) => {
       const user = row.original
       // Handle mapping from actual backend structure
       const name = user.FirstName || 'Unnamed'
       const email = user.User?.Email || ''
       const avatarUrl = user.FaceReferenceURL ? `http://localhost:8081${user.FaceReferenceURL}` : `https://ui-avatars.com/api/?name=${name}`

       return h('div', { class: 'flex items-center gap-3' }, [
         h('div', { class: 'w-10 h-10 rounded-full bg-gradient-to-br border border-white shadow-sm from-orange-200 to-red-100 flex items-center justify-center overflow-hidden' }, [
           h('img', { src: avatarUrl, class: 'w-full h-full object-cover opacity-80' })
         ]),
         h('div', {}, [
           h('p', { class: 'font-bold text-gray-900 leading-tight' }, name),
           h('p', { class: 'text-[12px] text-gray-500' }, email)
         ])
       ])
    }
  },
  {
    accessorKey: 'EmployeeIDNumber',
    header: 'ID',
    cell: (info: any) => h('span', { class: 'text-gray-500 text-[13px] font-medium' }, info.getValue() || '-')
  },
  {
    accessorKey: 'PhoneNumber',
    header: 'NOMOR WA',
    cell: (info: any) => {
      const val = info.getValue() || '-'
      if (val === '-') return h('span', { class: 'text-gray-400' }, '-')
      return h('a', { 
        href: `https://wa.me/${val.replace(/[^0-9]/g, '')}`, 
        target: '_blank',
        class: 'text-emerald-600 font-medium hover:underline flex items-center gap-1'
      }, [
        h('span', {}, val)
      ])
    }
  },
  {
    id: 'jobPosition',
    header: 'JABATAN',
    cell: ({ row }: any) => h('span', { class: 'font-bold text-gray-700' }, row.original.JobPosition?.Name || '-')
  },
  {
    id: 'department',
    header: 'DEPARTEMEN',
    cell: ({ row }: any) => h('span', { class: 'text-gray-500' }, row.original.Department?.Name || '-')
  },
  {
    id: 'branch',
    header: 'CABANG',
    cell: ({ row }: any) => h('span', { class: 'text-gray-500 font-medium' }, row.original.Branch?.Name || '-')
  },
  {
    accessorKey: 'EmploymentStatus',
    header: 'STATUS',
    cell: ({ getValue }: any) => {
        const val = getValue() as string || 'Unknown'
        let classes = 'border border-[#fecaca] text-[#dc2626]' 
        if (val === 'Aktif' || val === 'Active') classes = 'border border-[#bbf7d0] text-[#16a34a]'
        else if (val === 'Masa Percobaan' || val === 'Probation') classes = 'border border-[#fef08a] text-[#ca8a04]'
        return h('span', { class: `${classes} px-3 py-1 rounded-full text-[11px] font-bold inline-block` }, val)
    }
  },
  {
    accessorFn: (row: any) => row.JoinDate ? new Date(row.JoinDate).toLocaleDateString() : '-',
    id: 'joinDate',
    header: 'TANGGAL MASUK',
    cell: (info: any) => h('span', { class: 'text-gray-500 text-[13px]' }, info.getValue())
  },
  {
    accessorKey: 'Salary',
    header: 'GAJI POKOK',
    cell: (info: any) => {
      const val = info.getValue() || 0
      return h('span', { class: 'font-semibold text-gray-700 text-[13px]' }, 'Rp ' + val.toLocaleString('id-ID'))
    }
  },
  {
    accessorKey: 'BankName',
    header: 'NAMA BANK',
    cell: (info: any) => h('span', { class: 'text-gray-500 text-[13px]' }, info.getValue() || '-')
  },
  {
    accessorKey: 'BankAccountNumber',
    header: 'NOMOR REKENING',
    cell: (info: any) => h('span', { class: 'text-gray-500 text-[13px]' }, info.getValue() || '-')
  },
  {
    accessorKey: 'AccountHolderName',
    header: 'PEMILIK REKENING',
    cell: (info: any) => h('span', { class: 'text-gray-500 text-[13px]' }, info.getValue() || '-')
  },
  {
    id: 'actions',
    header: 'AKSI',
    cell: ({ row }: any) => {
      const user = row.original
      return h('div', { class: 'flex items-center gap-2' }, [
        h(Button, { 
            variant: 'ghost', 
            size: 'sm', 
            class: 'h-8 px-2 text-primary hover:text-primary hover:bg-primary/5',
            onClick: () => openEditModal(user)
        }, () => h(Pencil, { class: 'w-4 h-4' })),
        h(Button, { 
            variant: 'ghost', 
            size: 'sm', 
            class: 'h-8 px-2 text-red-600 hover:text-red-700 hover:bg-red-50',
            onClick: () => deleteEmployee(user.ID)
        }, () => h(Trash2, { class: 'w-4 h-4' }))
      ])
    }
  }
]
</script>

<template>
  <div class="space-y-6">
    <!-- Header Page -->
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h1 class="text-[22px] font-bold text-gray-900 leading-tight">Direktori Karyawan</h1>
        <p class="text-[14px] text-gray-500 mt-1">Kelola catatan dan status personel organisasi Anda.</p>
      </div>
      
      <div class="flex items-center gap-3">
        <Button @click="openAddModal" class="gap-2 shadow-sm rounded-lg" size="sm">
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
          </svg>
          Tambah Karyawan
        </Button>
      </div>
    </div>

    <!-- DataTable Instance -->
    <DataTable :data="employees" :columns="columns" :isLoading="isLoading">
      <template #headerActions>
        <div class="flex items-center gap-3 w-full sm:w-auto">
          <Select default-value="Semua Departemen">
            <SelectTrigger class="w-[180px] bg-white h-9 text-[13px]">
              <SelectValue placeholder="Pilih Departemen" />
            </SelectTrigger>
            <SelectContent>
              <SelectGroup>
                <SelectItem value="Semua Departemen">Semua Departemen</SelectItem>
                <SelectItem value="Produk">Produk</SelectItem>
                <SelectItem value="Teknik">Teknik</SelectItem>
                <SelectItem value="Pemasaran">Pemasaran</SelectItem>
              </SelectGroup>
            </SelectContent>
          </Select>
          <Button variant="outline" class="gap-2 h-9 text-[13px] rounded-lg">
            <svg class="w-4 h-4 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z" />
            </svg>
            Filter
          </Button>
        </div>
      </template>
    </DataTable>

    <!-- Add/Edit Employee Modal -->
    <Dialog v-model:open="isModalOpen">
      <DialogContent class="sm:max-w-xl">
        <DialogHeader>
          <DialogTitle class="text-xl">{{ isEditMode ? 'Edit Karyawan & Rekening' : 'Tambah Karyawan & Rekening' }}</DialogTitle>
          <DialogDescription>
            Lengkapi data personal dan rekening pembayaran bank karyawan ini.
          </DialogDescription>
        </DialogHeader>
        
        <div class="grid gap-4 py-4">
          <div class="grid grid-cols-2 gap-4">
            <div class="grid gap-2">
              <label class="text-[13px] font-medium text-gray-700">Nama Lengkap</label>
              <Input v-model="newEmployee.name" placeholder="e.g. John Doe" />
            </div>
            <div class="grid gap-2">
              <label class="text-[13px] font-medium text-gray-700">ID Karyawan (Opsional)</label>
              <Input v-model="newEmployee.employeeIDNumber" placeholder="e.g. EMP-001" />
            </div>
          </div>

          <div class="grid gap-2">
            <label class="text-[13px] font-medium text-gray-700">Nomor WhatsApp (Aktif)</label>
            <Input v-model="newEmployee.phoneNumber" placeholder="e.g. 08123456789" />
          </div>
          
          <div class="grid gap-2">
            <label class="text-[13px] font-medium text-gray-700">Email Karyawan</label>
            <Input v-model="newEmployee.email" type="email" placeholder="contoh. john@wowin.com" :disabled="isEditMode" />
          </div>

          <div class="grid gap-2">
            <label class="text-[13px] font-medium text-gray-700">Penempatan Cabang</label>
            <Select v-model="newEmployee.branchId">
              <SelectTrigger>
                <SelectValue placeholder="Pilih Cabang" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem v-for="b in branches" :key="b.ID" :value="b.ID">{{ b.Name }}</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div class="grid gap-2">
              <label class="text-[13px] font-medium text-gray-700">Departemen</label>
              <Select v-model="newEmployee.departmentId">
                <SelectTrigger>
                  <SelectValue placeholder="Pilih Departemen" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem v-for="d in departments" :key="d.ID" :value="d.ID">{{ d.Name }}</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div class="grid gap-2">
              <label class="text-[13px] font-medium text-gray-700">Jabatan</label>
              <Select v-model="newEmployee.jobPositionId">
                <SelectTrigger>
                  <SelectValue placeholder="Pilih Jabatan" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem v-for="j in jobPositions" :key="j.ID" :value="j.ID">{{ j.Name }}</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div class="grid gap-2">
              <label class="text-[13px] font-medium text-gray-700">Status Karyawan</label>
              <Select v-model="newEmployee.employmentStatus">
                <SelectTrigger>
                  <SelectValue placeholder="Pilih Status" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="Active">Aktif</SelectItem>
                  <SelectItem value="Probation">Masa Percobaan</SelectItem>
                  <SelectItem value="Inactive">Non-Aktif</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div class="grid gap-2">
              <label class="text-[13px] font-medium text-gray-700">Tanggal Masuk</label>
              <Input v-model="newEmployee.joinDate" type="date" />
            </div>
          </div>

          <div class="h-px bg-gray-100 my-2"></div>
          <h3 class="text-[13px] font-bold text-gray-900 uppercase tracking-wider">Informasi Payout Bank</h3>
          
          <div class="grid gap-2">
             <label class="text-[13px] font-medium text-gray-700">Nama Bank</label>
             <Select v-model="newEmployee.bankName">
               <SelectTrigger>
                 <SelectValue placeholder="Pilih Bank" />
               </SelectTrigger>
               <SelectContent>
                 <SelectGroup>
                   <SelectItem value="BCA">BCA</SelectItem>
                   <SelectItem value="MANDIRI">MANDIRI</SelectItem>
                   <SelectItem value="BNI">BNI</SelectItem>
                   <SelectItem value="BRI">BRI</SelectItem>
                   <SelectItem value="BANK JAGO">BANK JAGO</SelectItem>
                 </SelectGroup>
               </SelectContent>
             </Select>
          </div>
          <div class="grid gap-2">
             <label class="text-[13px] font-medium text-gray-700">Nomor Rekening</label>
             <Input v-model="newEmployee.bankAccountNumber" placeholder="e.g. 129381203" />
          </div>
          <div class="grid gap-2">
             <label class="text-[13px] font-medium text-gray-700">Nama Pemilik Rekening</label>
             <Input v-model="newEmployee.accountHolderName" placeholder="e.g. JOHN DOE" />
          </div>

          <div class="h-px bg-gray-100 my-2"></div>
          <h3 class="text-[13px] font-bold text-gray-900 uppercase tracking-wider">Kompensasi</h3>
          <div class="grid gap-2">
             <label class="text-[13px] font-medium text-gray-700">Gaji Pokok (Salary)</label>
             <Input v-model="newEmployee.salary" type="number" placeholder="Rp 0" />
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" @click="closeAddModal">Batal</Button>
          <Button @click="saveEmployee" :disabled="isSubmitting">
            {{ isSubmitting ? 'Menyimpan...' : 'Simpan Data' }}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  </div>
</template>
