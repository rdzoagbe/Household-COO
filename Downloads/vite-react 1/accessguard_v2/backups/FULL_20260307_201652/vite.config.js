import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// combine build options into the single default export
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    open: true
  },
  build: {
    sourcemap: true,
  }
})