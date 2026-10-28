import { MarketingHeader, MarketingFooter } from '@/components/marketing/parts'

export default function MarketingLayout({ children }: { children: React.ReactNode }) {
  return (
    <div style={{ background: '#fff', minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
      <MarketingHeader />
      <main style={{ flex: 1 }}>{children}</main>
      <MarketingFooter />
    </div>
  )
}
