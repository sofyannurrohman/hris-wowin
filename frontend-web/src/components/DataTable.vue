<script setup lang="ts">
import { ref, computed } from 'vue'
import {
  FlexRender,
  getCoreRowModel,
  useVueTable,
  getPaginationRowModel,
  getSortedRowModel,
  getFilteredRowModel,
  type SortingState,
} from '@tanstack/vue-table'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'

const props = defineProps({
  data: {
    type: Array,
    required: true
  },
  columns: {
    type: Array,
    required: true
  },
  isLoading: {
    type: Boolean,
    default: false
  }
})

const sorting = ref<SortingState>([])
const globalFilter = ref('')

const table = useVueTable({
  get data() { return props.data },
  get columns() { return props.columns as any },
  state: {
    get sorting() { return sorting.value },
    get globalFilter() { return globalFilter.value },
  },
  onSortingChange: updaterOrValue => {
    sorting.value = typeof updaterOrValue === 'function' ? updaterOrValue(sorting.value) : updaterOrValue
  },
  onGlobalFilterChange: setFilter => {
    globalFilter.value = setFilter
  },
  getCoreRowModel: getCoreRowModel(),
  getPaginationRowModel: getPaginationRowModel(),
  getSortedRowModel: getSortedRowModel(),
  getFilteredRowModel: getFilteredRowModel(),
  initialState: {
    pagination: {
      pageSize: 5
    }
  }
})
</script>

<template>
  <div class="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden flex flex-col w-full">
    <!-- Search / Top Actions -->
    <div class="p-5 border-b border-gray-100 flex flex-col sm:flex-row items-center justify-between gap-4">
      <div class="flex items-center gap-3">
        <slot name="headerTitle" />
      </div>
      <div class="flex items-center gap-2">
        <div class="relative w-64">
          <svg class="absolute left-3 top-2.5 w-4 h-4 text-gray-400 z-10" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
          <Input 
            v-model="globalFilter"
            type="text" 
            placeholder="Cari data..." 
            class="pl-9 bg-gray-50 focus-visible:ring-blue-500"
          />
        </div>
        <slot name="headerActions" />
      </div>
    </div>
    
    <!-- Table -->
    <div class="overflow-x-auto">
      <Table>
        <TableHeader class="bg-[#fafbfc] uppercase text-[11px] font-bold text-gray-500 tracking-wider">
          <TableRow v-for="headerGroup in table.getHeaderGroups()" :key="headerGroup.id">
            <TableHead 
              v-for="header in headerGroup.headers" 
              :key="header.id" 
              class="cursor-pointer select-none group"
              @click="header.column.getToggleSortingHandler()?.($event)"
            >
              <div class="flex items-center gap-1">
                <FlexRender v-if="!header.isPlaceholder" :render="header.column.columnDef.header" :props="header.getContext()" />
                <!-- Sorting Indicator -->
                <span v-if="header.column.getCanSort()">
                  <svg v-if="header.column.getIsSorted() === 'asc'" class="w-3 h-3 text-gray-700" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 15l7-7 7 7"></path></svg>
                  <svg v-else-if="header.column.getIsSorted() === 'desc'" class="w-3 h-3 text-gray-700" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M19 9l-7 7-7-7"></path></svg>
                  <svg v-else class="w-3 h-3 text-gray-300 group-hover:text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 9l4-4 4 4m0 6l-4 4-4-4"></path></svg>
                </span>
              </div>
            </TableHead>
          </TableRow>
        </TableHeader>
        <TableBody class="relative text-[14px]">
          <TableRow v-if="isLoading" class="absolute inset-0 bg-white/50 backdrop-blur-sm flex items-center justify-center z-10">
             <TableCell :colspan="columns.length" class="py-12 text-center text-gray-500 font-medium animate-pulse">Memuat data...</TableCell>
          </TableRow>
          <TableRow v-if="!isLoading && table.getRowModel().rows.length === 0">
             <TableCell :colspan="columns.length" class="py-12 text-center text-gray-500 text-[13px] font-medium">Tidak ada data ditemukan</TableCell>
          </TableRow>
          <TableRow v-for="row in table.getRowModel().rows" :key="row.id" class="hover:bg-gray-50/50 transition-colors">
            <TableCell v-for="cell in row.getVisibleCells()" :key="cell.id">
              <FlexRender :render="cell.column.columnDef.cell" :props="cell.getContext()" />
            </TableCell>
          </TableRow>
        </TableBody>
      </Table>
    </div>
    
    <!-- Custom Pagination -->
    <div class="p-4 border-t border-gray-100 flex flex-col gap-3 sm:flex-row sm:items-center justify-between text-[13px] text-gray-500">
      <span>Menampilkan {{ table.getState().pagination.pageIndex * table.getState().pagination.pageSize + 1 }} sampai {{ Math.min((table.getState().pagination.pageIndex + 1) * table.getState().pagination.pageSize, table.getFilteredRowModel().rows.length) }} dari {{ table.getFilteredRowModel().rows.length }} hasil</span>
      <div class="flex items-center gap-1">
        <Button 
          variant="outline"
          size="icon"
          @click="table.previousPage()" 
          :disabled="!table.getCanPreviousPage()"
        >
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" /></svg>
        </Button>
        
        <Button 
          v-for="page in table.getPageCount()" 
          :key="page"
          :variant="table.getState().pagination.pageIndex === page - 1 ? 'default' : 'outline'"
          size="icon"
          @click="table.setPageIndex(page - 1)"
        >
          {{ page }}
        </Button>

        <Button 
          variant="outline"
          size="icon"
          @click="table.nextPage()"
          :disabled="!table.getCanNextPage()"
        >
          <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" /></svg>
        </Button>
      </div>
    </div>
  </div>
</template>
