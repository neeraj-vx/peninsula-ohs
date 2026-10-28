import Link from 'next/link'
import { Tile } from '@carbon/react'
import { ArrowRight } from '@carbon/icons-react'
import { createClient } from '@/lib/supabase/server'
import { TOOL_GROUPS, audienceFor, canSee } from '@/components/shell/nav'

export default async function ToolsPage() {
  const supabase = await createClient()
  const { data: { user } } = await supabase.auth.getUser()
  const { data: roleRows } = await supabase
    .from('user_roles')
    .select('roles(name)')
    .eq('user_id', user?.id ?? '')
    .eq('is_active', true)
  const roles = (roleRows ?? []).map((r) => (r.roles as unknown as { name: string } | null)?.name).filter((n): n is string => !!n)
  const audience = audienceFor(roles)

  const groups = TOOL_GROUPS
    .map((g) => ({ ...g, tools: g.tools.filter((t) => canSee(audience, t.audience)) }))
    .filter((g) => g.tools.length > 0)

  return (
    <div style={{ padding: '2rem', maxWidth: '80rem' }}>
      <h1 style={{ fontSize: '1.75rem', fontWeight: 400, color: '#161616' }}>More tools</h1>
      <p style={{ fontSize: '0.875rem', color: '#525252', marginTop: '0.25rem', marginBottom: '2rem' }}>
        Everything else EXXIO can do. You won&apos;t need most of these every day. Open one when it fits your work.
      </p>

      {groups.map((group) => (
        <section key={group.label} style={{ marginBottom: '2rem' }}>
          <h2 style={{ fontSize: '0.875rem', fontWeight: 600, color: '#525252', marginBottom: '0.75rem' }}>{group.label}</h2>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(16rem, 1fr))', gap: '1rem' }}>
            {group.tools.map((tool) => (
              <Link key={tool.href} href={tool.href} style={{ textDecoration: 'none', color: 'inherit' }}>
                <Tile style={{ height: '100%', cursor: 'pointer' }}>
                  <p style={{ fontSize: '1rem', fontWeight: 600, color: '#161616', display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: '0.5rem' }}>
                    {tool.label}
                    <ArrowRight size={16} style={{ color: '#0f62fe', flexShrink: 0 }} />
                  </p>
                  <p style={{ fontSize: '0.875rem', color: '#525252', marginTop: '0.375rem', lineHeight: 1.4 }}>{tool.description}</p>
                </Tile>
              </Link>
            ))}
          </div>
        </section>
      ))}
    </div>
  )
}
