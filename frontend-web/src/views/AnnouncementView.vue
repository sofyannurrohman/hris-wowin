<script setup lang="ts">
import { ref, h, onMounted } from 'vue'
import { Pencil, Trash2, Megaphone, Bell, Calendar } from 'lucide-vue-next'
import apiClient from '@/api/axios'
import DataTable from '@/components/DataTable.vue'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectGroup, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Switch } from '@/components/ui/switch'
import { Label } from '@/components/ui/label'
import { toast } from 'vue-sonner'

const isModalOpen = ref(false)
const isSubmitting = ref(false)
const isLoading = ref(true)
const announcements = ref<any[]>([])

const currentAnnouncement = ref({
  id: '',
  title: '',
  content: '',
  category: 'policy',
  is_active: true
})

const categories = [
  { value: 'policy', label: 'Kebijakan', icon: Bell },
  { value: 'event', label: 'Acara', icon: Calendar },
  { value: 'info', label: 'Informasi', icon: Megaphone },
]

const isEditMode = ref(false)

const openAddModal = () => {
  isEditMode.value = false
  currentAnnouncement.value = {
    id: '',
    title: '',
    content: '',
    category: 'policy',
    is_active: true
  }
  isModalOpen.value = true
}

const openEditModal = (ann: any) => {
  isEditMode.value = true
  currentAnnouncement.value = {
    id: ann.id,
    title: ann.title,
    content: ann.content,
    category: ann.category || 'policy',
    is_active: ann.is_active
  }
  isModalOpen.value = true
}

const closeModal = () => {
  isModalOpen.value = false
}

const fetchAnnouncements = async () => {
  isLoading.value = true
  try {
    const response = await apiClient.get('/admin/announcements')
    announcements.value = response.data.data
  } catch (error) {
    console.error('Failed to fetch announcements:', error)
    toast.error('Gagal mengambil data pengumuman')
  } finally {
    isLoading.value = false
  }
}

const saveAnnouncement = async () => {
  if (!currentAnnouncement.value.title || !currentAnnouncement.value.content) {
    toast.error('Judul dan konten wajib diisi')
    return
  }

  isSubmitting.value = true
  try {
    const payload = {
      title: currentAnnouncement.value.title,
      content: currentAnnouncement.value.content,
      category: currentAnnouncement.value.category,
      is_active: currentAnnouncement.value.is_active
    }

    if (isEditMode.value) {
      await apiClient.put(`/announcements/${currentAnnouncement.value.id}`, payload)
      toast.success('Pengumuman berhasil diperbarui!')
    } else {
      await apiClient.post('/announcements', payload)
      toast.success('Pengumuman berhasil ditambahkan!')
    }
    closeModal()
    fetchAnnouncements()
  } catch (error: any) {
    toast.error('Gagal menyimpan pengumuman: ' + (error.response?.data?.message || error.message))
  } finally {
    isSubmitting.value = false
  }
}

const deleteAnnouncement = async (id: string) => {
  if (!confirm('Apakah Anda yakin ingin menghapus pengumuman ini?')) return
  try {
    await apiClient.delete(`/announcements/${id}`)
    toast.success('Pengumuman berhasil dihapus!')
    fetchAnnouncements()
  } catch (error: any) {
    toast.error('Gagal menghapus: ' + (error.response?.data?.message || error.message))
  }
}

onMounted(() => {
  fetchAnnouncements()
})

const columns = [
  {
    accessorKey: 'title',
    header: 'JUDUL PENGUMUMAN',
    cell: (info: any) => h('div', { class: 'flex flex-col' }, [
      h('span', { class: 'font-bold text-gray-900 line-clamp-1' }, info.getValue() || '-'),
      h('span', { class: 'text-[11px] text-gray-500 uppercase tracking-wider mt-0.5' }, info.row.original.category || 'POLICY')
    ])
  },
  {
    accessorKey: 'content',
    header: 'KONTEN',
    cell: (info: any) => h('span', { 
      class: 'text-gray-600 line-clamp-2 max-w-[400px] text-[13px]', 
      title: info.getValue() 
    }, info.getValue() || '-')
  },
  {
    accessorKey: 'is_active',
    header: 'STATUS',
    cell: (info: any) => {
      const active = info.getValue()
      return h('div', { 
        class: `inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold ${
          active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-600'
        }` 
      }, active ? 'AKTIF' : 'NON-AKTIF')
    }
  },
  {
    accessorKey: 'created_at',
    header: 'TANGGAL DIBUAT',
    cell: (info: any) => {
      const date = new Date(info.getValue())
      return h('span', { class: 'text-gray-600 text-[13px]' }, new Intl.DateTimeFormat('id-ID', {
        day: 'numeric',
        month: 'long',
        year: 'numeric'
      }).format(date))
    }
  },
  {
    id: 'actions',
    header: 'AKSI',
    cell: ({ row }: any) => {
      const ann = row.original
      return h('div', { class: 'flex items-center gap-2' }, [
        h(Button, {
          variant: 'ghost', size: 'sm',
          class: 'h-8 px-2 text-primary hover:text-primary hover:bg-primary/5',
          onClick: () => openEditModal(ann)
        }, () => h(Pencil, { class: 'w-4 h-4' })),
        h(Button, {
          variant: 'ghost', size: 'sm',
          class: 'h-8 px-2 text-red-600 hover:text-red-700 hover:bg-red-50',
          onClick: () => deleteAnnouncement(ann.id)
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
        <h1 class="text-[22px] font-bold text-gray-900 leading-tight text-primary">Manajemen Pengumuman</h1>
        <p class="text-[14px] text-gray-500 mt-1">Kelola pengumuman kebijakan dan informasi untuk seluruh karyawan.</p>
      </div>
      <div class="flex items-center gap-3">
        <Button @click="openAddModal" class="gap-2 shadow-sm rounded-lg" size="sm">
          <Megaphone class="w-4 h-4" />
          Buat Pengumuman
        </Button>
      </div>
    </div>

    <DataTable :data="announcements" :columns="columns" :isLoading="isLoading" />

    <Dialog v-model:open="isModalOpen">
      <DialogContent class="sm:max-w-xl">
        <DialogHeader>
          <DialogTitle class="text-xl text-primary">{{ isEditMode ? 'Edit Pengumuman' : 'Buat Pengumuman Baru' }}</DialogTitle>
          <DialogDescription>
            Isi detail informasi pengumuman di bawah ini.
          </DialogDescription>
        </DialogHeader>

        <div class="grid gap-6 py-4">
          <div class="grid gap-2">
            <Label class="text-[13px] font-bold text-gray-700 uppercase tracking-wider">Judul Pengumuman</Label>
            <Input v-model="currentAnnouncement.title" placeholder="e.g. Update Kebijakan Lembur Ramadhan" class="h-11" />
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div class="grid gap-2">
              <Label class="text-[13px] font-bold text-gray-700 uppercase tracking-wider">Kategori</Label>
              <Select v-model="currentAnnouncement.category">
                <SelectTrigger class="h-11">
                  <SelectValue placeholder="Pilih kategori" />
                </SelectTrigger>
                <SelectContent>
                  <SelectGroup>
                    <SelectItem v-for="cat in categories" :key="cat.value" :value="cat.value">
                      <div class="flex items-center gap-2">
                        <component :is="cat.icon" class="w-4 h-4 text-slate-400" />
                        {{ cat.label }}
                      </div>
                    </SelectItem>
                  </SelectGroup>
                </SelectContent>
              </Select>
            </div>
            
            <div class="flex flex-col gap-3 justify-center pl-2">
              <Label class="text-[13px] font-bold text-gray-700 uppercase tracking-wider">Status Aktif</Label>
              <div class="flex items-center space-x-2 p-2 rounded-lg bg-slate-50 border border-slate-100">
                <Switch 
                  id="active-status" 
                  :checked="currentAnnouncement.is_active"
                  @update:checked="(val: boolean) => currentAnnouncement.is_active = val"
                />
                <Label htmlFor="active-status" class="text-[13px] cursor-pointer">
                  Tampilkan ke Karyawan
                </Label>
              </div>
            </div>
          </div>

          <div class="grid gap-2">
            <Label class="text-[13px] font-bold text-gray-700 uppercase tracking-wider">Isi Pengumuman</Label>
            <textarea 
              v-model="currentAnnouncement.content" 
              placeholder="Tuliskan detail pengumuman di sini..." 
              rows="6" 
              class="flex w-full rounded-md border border-gray-200 bg-transparent px-3 py-3 text-sm shadow-sm placeholder:text-gray-400 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-primary focus-visible:border-primary transition-all resize-none"
            ></textarea>
          </div>
        </div>

        <DialogFooter class="bg-slate-50 -mx-6 -mb-6 p-6 mt-2 rounded-b-lg border-t border-slate-100">
          <Button variant="outline" @click="closeModal" class="h-11 px-6 font-bold">Batal</Button>
          <Button @click="saveAnnouncement" :disabled="isSubmitting || !currentAnnouncement.title" class="h-11 px-8 font-extrabold flex gap-2">
            <span v-if="isSubmitting" class="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></span>
            {{ isSubmitting ? 'Menyimpan...' : 'Publikasikan Sekarang' }}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  </div>
</template>
