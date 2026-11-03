import { SkeletonText, SkeletonPlaceholder } from '@carbon/react'

// Shown straight away while a page's data loads, so navigation feels instant
export default function Loading() {
  return (
    <div style={{ padding: '2rem 0' }} aria-busy="true" aria-label="Loading">
      <SkeletonText heading width="40%" />
      <SkeletonText paragraph lineCount={2} width="70%" />
      <div style={{ marginTop: '2rem' }}>
        <SkeletonPlaceholder style={{ width: '100%', height: '18rem' }} />
      </div>
    </div>
  )
}
