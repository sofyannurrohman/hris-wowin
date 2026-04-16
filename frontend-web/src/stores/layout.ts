import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useLayoutStore = defineStore('layout', () => {
  const isSidebarCollapsed = ref(false)
  const isMobileMenuOpen = ref(false)
  const currentModule = ref('hris') // 'hris', 'erecruitment', 'sales'

  function toggleSidebar() {
    isSidebarCollapsed.value = !isSidebarCollapsed.value
  }

  function setSidebarCollapsed(value: boolean) {
    isSidebarCollapsed.value = value
  }

  function toggleMobileMenu() {
    isMobileMenuOpen.value = !isMobileMenuOpen.value
  }

  function setModule(module: string) {
    currentModule.value = module
  }

  return {
    isSidebarCollapsed,
    isMobileMenuOpen,
    currentModule,
    toggleSidebar,
    setSidebarCollapsed,
    toggleMobileMenu,
    setModule
  }
})
