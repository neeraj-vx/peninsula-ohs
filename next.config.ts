import type { NextConfig } from 'next'

const nextConfig: NextConfig = {
  transpilePackages: ['@carbon/react', '@carbon/icons-react'],
  // Parses PDFs / Office files for the assistant; keep it out of the server bundle
  serverExternalPackages: ['officeparser'],
  experimental: {
    optimizePackageImports: ['@supabase/ssr'],
  },
}

export default nextConfig
