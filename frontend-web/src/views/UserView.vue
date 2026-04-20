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
const newUser = ref({
  id: '',
  email: '',
  password: '',
  role: 'employee',
  isActive: true
})

const isEditMode = ref(false)
const isSubmitting = ref(false)
const users = ref<any[]>([])
const isLoading = ref(true)

const openAddModal = () => {
  isEditMode.value = false
  newUser.value = {
    id: '',
    email: '',
    password: '',
    role: 'employee',
    isActive: true
  }
  isModalOpen.value = true
}

const openEditModal = (user: any) => {
  isEditMode.value = true
  newUser.value = {
    id: user.id,
    email: user.email || '',
    password: '', // Blank initially for update
    role: user.role || 'employee',
    isActive: user.is_active
  }
  isModalOpen.value = true
}

const closeAddModal = () => {
  isModalOpen.value = false
}

const fetchUsers = async () => {
  isLoading.value = true
  try {
    const response = await apiClient.get('/users')
    // Handle both {data: [...]} and {data: {data: [...]}} structures
    const rawData = response.data.data
    users.value = Array.isArray(rawData) ? rawData : (rawData?.data || [])
  } catch (error: any) {
    console.error('Failed to fetch users:', error)
    toast.error('Gagal mengambil data pengguna: ' + (error.response?.data?.message || error.message))
  } finally {
    isLoading.value = false
  }
}

const saveUser = async () => {
  isSubmitting.value = true
  try {
    if (isEditMode.value) {
      // Don't validate password on edit unless typed
      await apiClient.put(`/users/${newUser.value.id}`, {
        email: newUser.value.email,
        password: newUser.value.password || "",
        role: newUser.value.role,
        isActive: newUser.value.isActive
      })
      toast.success('Pengguna berhasil diperbarui!')
    } else {
      await apiClient.post('/users', newUser.value)
      toast.success('Pengguna berhasil ditambahkan!')
    }
    closeAddModal()
    fetchUsers()
  } catch (error: any) {
    toast.error(`Gagal ${isEditMode.value ? 'memperbarui' : 'menambahkan'} pengguna: ` + (error.response?.data?.error || error.response?.data?.message || error.message))
  } finally {
    isSubmitting.value = false
  }
}

const deleteUser = async (id: string) => {
  if (!confirm('Apakah Anda yakin ingin menghapus pengguna ini? Operasi ini tidak dapat dibatalkan.')) return
  
  try {
    await apiClient.delete(`/users/${id}`)
    toast.success('Pengguna berhasil dihapus!')
    fetchUsers()
  } catch (error: any) {
    toast.error('Gagal menghapus pengguna: ' + (error.response?.data?.error || error.response?.data?.message || error.message))
  }
}

onMounted(() => {
  fetchUsers()
})

const columns = [
  {
    accessorKey: 'email',
    header: 'EMAIL',
    cell: (info: any) => h('span', { class: 'font-bold text-gray-900' }, info.getValue() || '-')
  },
  {
    accessorKey: 'role',
    header: 'HAK AKSES',
    cell: ({ getValue }: any) => {
      const val = getValue() as string
      let classes = 'border border-[#e5e7eb] text-gray-600'
      if (val === 'superadmin') classes = 'border border-[#fecaca] text-[#dc2626]'
      else if (val === 'hr_admin') classes = 'border border-[#fef08a] text-[#ca8a04]'
      else if (val === 'employee') classes = 'border border-[#bbf7d0] text-[#16a34a]'
      return h('span', { class: `${classes} px-3 py-1 rounded-full text-[11px] font-bold inline-block uppercase` }, val)
    }
  },
  {
    accessorKey: 'is_active',
    header: 'STATUS',
    cell: (info: any) => {
      const active = info.getValue()
      return h('span', { 
        class: active ? 'text-green-600 font-bold' : 'text-red-500 font-bold' 
      }, active ? 'Aktif' : 'Non-Aktif')
    }
  },
  {
    accessorFn: (row: any) => row.created_at ? new Date(row.created_at).toLocaleDateString() : '-',
    id: 'createdAt',
    header: 'DIBUAT PADA',
    cell: (info: any) => h('span', { class: 'text-gray-500 text-[13px]' }, info.getValue())
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
            onClick: () => deleteUser(user.id)
        }, () => h(Trash2, { class: 'w-4 h-4' }))
      ])
    }
  }
]
</script>

<template>
  <div class="space-y-6">
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
      <div>
        <h1 class="text-[22px] font-bold text-gray-900 leading-tight">Manajemen Pengguna</h1>
        <p class="text-[14px] text-gray-500 mt-1">Atur kredensial dan hak akses aplikasi (Admin, Karyawan).</p>
      </div>
      
      <div class="flex items-center gap-3">
        <Button @click="openAddModal" class="gap-2 shadow-sm rounded-lg" size="sm">
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
          </svg>
          Tambah Pengguna
        </Button>
      </div>
    </div>

    <DataTable :data="users" :columns="columns" :isLoading="isLoading" />

    <Dialog v-model:open="isModalOpen">
      <DialogContent class="sm:max-w-xl">
        <DialogHeader>
          <DialogTitle class="text-xl">{{ isEditMode ? 'Edit Pengguna' : 'Tambah Pengguna' }}</DialogTitle>
          <DialogDescription>
            Tentukan email akses dan role sistem untuk akun ini.
          </DialogDescription>
        </DialogHeader>
        
        <div class="grid gap-4 py-4">
          <div class="grid gap-2">
            <label class="text-[13px] font-medium text-gray-700">Email Login</label>
            <Input v-model="newUser.email" type="email" placeholder="e.g. jdoe@company.com" />
          </div>
          
          <div class="grid gap-2">
            <label class="text-[13px] font-medium text-gray-700">Password</label>
            <Input v-model="newUser.password" type="password" :placeholder="isEditMode ? 'Kosongkan jika tidak ingin diubah' : 'Minimal 6 karakter'" />
          </div>

          <div class="grid gap-2">
            <label class="text-[13px] font-medium text-gray-700">Hak Akses</label>
            <Select v-model="newUser.role">
              <SelectTrigger>
                <SelectValue placeholder="Pilih Role" />
              </SelectTrigger>
              <SelectContent>
                <SelectGroup>
                  <SelectItem value="employee">Employee</SelectItem>
                  <SelectItem value="hr_admin">HR Admin</SelectItem>
                  <SelectItem value="superadmin">Super Admin</SelectItem>
                </SelectGroup>
              </SelectContent>
            </Select>
          </div>

          <div class="flex items-center space-x-2 mt-4">
            <input type="checkbox" id="isActive" v-model="newUser.isActive" class="w-4 h-4 rounded border-gray-300 text-primary focus:ring-primary" />
            <label for="isActive" class="text-sm font-medium leading-none">
              Akun Aktif (Dapat Login)
            </label>
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" @click="closeAddModal">Batal</Button>
          <Button @click="saveUser" :disabled="isSubmitting">
            {{ isSubmitting ? 'Menyimpan...' : 'Simpan Data' }}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  </div>
</template>
