'use client'

import { useState, useEffect, useCallback, useMemo } from 'react'
import { useRouter, usePathname } from 'next/navigation'
import Link from 'next/link'
import {
  Header,
  HeaderMenuButton,
  HeaderName,
  HeaderGlobalBar,
  HeaderGlobalAction,
  HeaderPanel,
  SideNav,
  SideNavItems,
  SideNavLink,
  SideNavMenu,
  SideNavMenuItem,
  Content,
  SkipToContent,
  Theme,
} from '@carbon/react'
import { Notification, UserAvatar, Add } from '@carbon/icons-react'
import { createClient } from '@/lib/supabase/client'
import { NAV, REPORT_OPTIONS, audienceFor, canSee, isUnder, type NavPage } from './nav'

interface NotificationRow {
  id: string
  title: string
  body: string
  is_read: boolean
  created_at: string
  trigger_entity_type: string | null
  trigger_entity_id: string | null
}

interface AppShellProps {
  children: React.ReactNode
  userEmail?: string
  userName?: string
  roles?: string[]
  impersonating?: { orgName: string } | null
}

const ENTITY_ROUTES: Record<string, string> = {
  incident: '/incidents',
  hazard_report: '/hazards',
  risk: '/risks',
  action: '/actions',
  inspection: '/inspections',
  audit: '/audits',
  permit: '/permits',
  investigation: '/investigations',
  hire: '/hiring',
  document: '/documents',
  training_record: '/training/records',
  training_assignment: '/training',
}

// Entities without their own detail page link to the list
const LIST_ONLY_ENTITIES = new Set(['training_assignment'])

export function AppShell({ children, userEmail, userName, roles = [], impersonating }: AppShellProps) {
  const router = useRouter()
  const pathname = usePathname()
  const audience = audienceFor(roles)
  const [isSideNavExpanded, setIsSideNavExpanded] = useState(true)
  const [isHeaderPanelOpen, setIsHeaderPanelOpen] = useState(false)
  const [isNotifOpen, setIsNotifOpen] = useState(false)
  const [isReportOpen, setIsReportOpen] = useState(false)
  const [notifications, setNotifications] = useState<NotificationRow[]>([])
  const [notifLoading, setNotifLoading] = useState(false)

  const fetchNotifications = useCallback(async () => {
    setNotifLoading(true)
    const supabase = createClient()
    const { data } = await supabase
      .from('notifications')
      .select('id, title, body, is_read, created_at, trigger_entity_type, trigger_entity_id')
      .order('created_at', { ascending: false })
      .limit(20)
    setNotifications(data ?? [])
    setNotifLoading(false)
  }, [])

  // Load once so the unread badge is right before the panel is opened
  useEffect(() => { fetchNotifications() }, [fetchNotifications])

  // Close the report menu whenever the page changes
  useEffect(() => { setIsReportOpen(false) }, [pathname])

  async function markAllRead() {
    const unreadIds = notifications.filter((n) => !n.is_read).map((n) => n.id)
    if (unreadIds.length === 0) return
    const supabase = createClient()
    await supabase.rpc('mark_notifications_read', { p_notification_ids: unreadIds })
    setNotifications((prev) => prev.map((n) => ({ ...n, is_read: true })))
  }

  function handleNotifToggle() {
    const next = !isNotifOpen
    setIsNotifOpen(next)
    if (next) {
      setIsHeaderPanelOpen(false)
      fetchNotifications()
    }
  }

  async function handleSignOut() {
    const supabase = createClient()
    await supabase.auth.signOut()
    router.push('/login')
    router.refresh()
  }

  async function handleExitImpersonation() {
    await fetch('/api/admin/exit-impersonation', { method: 'POST' })
    router.push('/admin/organisations')
    router.refresh()
  }

  // Sections and pages this user's role can see
  const sections = useMemo(
    () =>
      NAV.filter((s) => canSee(audience, s.audience))
        .map((s) => ({ ...s, pages: s.pages?.filter((p) => canSee(audience, p.audience)) }))
        .filter((s) => s.href || (s.pages && s.pages.length > 0)),
    [audience],
  )

  // The most specific nav entry that contains the current path is the active one,
  // so /training/records highlights "Training records", not "Overview"
  const activeHref = useMemo(() => {
    const hrefs = sections.flatMap((s) => [
      ...(s.href ? [s.href] : []),
      ...(s.pages ?? []).flatMap((p) => [p.href, ...(p.children ?? []).map((c) => c.href)]),
    ])
    return hrefs.filter((h) => isUnder(pathname, h)).sort((a, b) => b.length - a.length)[0]
  }, [sections, pathname])

  const pageIsOpen = (p: NavPage) =>
    isUnder(pathname, p.href) || (p.children ?? []).some((c) => isUnder(pathname, c.href))

  const unreadCount = notifications.filter((n) => !n.is_read).length
  const roleLabel = { admin: 'Administrator', manager: 'Health & Safety', supervisor: 'Supervisor', everyone: 'Team member' }[audience]

  function notifLink(n: NotificationRow): string {
    const base = n.trigger_entity_type ? ENTITY_ROUTES[n.trigger_entity_type] : undefined
    if (!base) return '#'
    if (LIST_ONLY_ENTITIES.has(n.trigger_entity_type!)) return base
    return n.trigger_entity_id ? `${base}/${n.trigger_entity_id}` : base
  }

  function formatNotifDate(iso: string) {
    const diffMins = Math.floor((Date.now() - new Date(iso).getTime()) / 60000)
    if (diffMins < 1) return 'Just now'
    if (diffMins < 60) return `${diffMins}m ago`
    const diffHrs = Math.floor(diffMins / 60)
    if (diffHrs < 24) return `${diffHrs}h ago`
    return new Date(iso).toLocaleDateString('en-CA', { day: 'numeric', month: 'short' })
  }

  return (
    <Theme theme="white">
      {impersonating && (
        <div style={{
          position: 'fixed', top: 0, left: 0, right: 0, zIndex: 10000,
          backgroundColor: '#f1c21b', color: '#161616',
          padding: '0.5rem 1rem',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          fontSize: '0.875rem', fontWeight: 500,
        }}>
          <span>
            Viewing as EXXIO Support — Organisation: <strong>{impersonating.orgName}</strong>
          </span>
          <button
            onClick={handleExitImpersonation}
            style={{
              background: 'none', border: '1px solid #161616', cursor: 'pointer',
              padding: '0.25rem 0.75rem', fontSize: '0.75rem', fontWeight: 600,
            }}
          >
            Exit
          </button>
        </div>
      )}
      <div style={impersonating ? { paddingTop: '2.25rem' } : undefined}>
      <SkipToContent />
      <Header aria-label="EXXIO">
        <HeaderMenuButton
          aria-label={isSideNavExpanded ? 'Close navigation' : 'Open navigation'}
          onClick={() => setIsSideNavExpanded(!isSideNavExpanded)}
          isActive={isSideNavExpanded}
        />
        <HeaderName href="/dashboard" prefix="">
          EXXIO
        </HeaderName>
        <HeaderGlobalBar>
          <HeaderGlobalAction
            aria-label="Notifications"
            tooltipAlignment="end"
            isActive={isNotifOpen}
            onClick={handleNotifToggle}
          >
            <div style={{ position: 'relative', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Notification size={20} />
              {unreadCount > 0 && (
                <span style={{
                  position: 'absolute', top: '-6px', right: '-6px',
                  background: '#da1e28', color: '#fff', borderRadius: '50%',
                  width: '16px', height: '16px', fontSize: '10px', fontWeight: 700,
                  display: 'flex', alignItems: 'center', justifyContent: 'center', lineHeight: 1,
                }}>
                  {unreadCount > 9 ? '9+' : unreadCount}
                </span>
              )}
            </div>
          </HeaderGlobalAction>
          <HeaderGlobalAction
            aria-label="User account"
            tooltipAlignment="end"
            isActive={isHeaderPanelOpen}
            onClick={() => { setIsHeaderPanelOpen(!isHeaderPanelOpen); setIsNotifOpen(false) }}
          >
            <UserAvatar size={20} />
          </HeaderGlobalAction>
        </HeaderGlobalBar>

        {isNotifOpen && (
          <div style={{
            position: 'fixed', top: '3rem', right: '3rem', width: '22rem', maxHeight: '28rem',
            backgroundColor: '#fff', border: '1px solid #e0e0e0', boxShadow: '0 4px 16px rgba(0,0,0,0.12)',
            zIndex: 9999, display: 'flex', flexDirection: 'column',
          }}>
            <div style={{ padding: '0.75rem 1rem', borderBottom: '1px solid #e0e0e0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <p style={{ fontSize: '0.875rem', fontWeight: 600, color: '#161616' }}>Notifications</p>
              {unreadCount > 0 && (
                <button onClick={markAllRead} style={{ fontSize: '0.75rem', color: '#0f62fe', background: 'none', border: 'none', cursor: 'pointer', padding: 0 }}>
                  Mark all read
                </button>
              )}
            </div>
            <div style={{ overflowY: 'auto', flex: 1 }}>
              {notifLoading ? (
                <div style={{ padding: '2rem 1rem', textAlign: 'center', fontSize: '0.875rem', color: '#6f6f6f' }}>Loading…</div>
              ) : notifications.length === 0 ? (
                <div style={{ padding: '2rem 1rem', textAlign: 'center', fontSize: '0.875rem', color: '#6f6f6f' }}>
                  You&apos;re all caught up
                </div>
              ) : (
                notifications.map((n) => (
                  <a
                    key={n.id}
                    href={notifLink(n)}
                    onClick={() => setIsNotifOpen(false)}
                    style={{
                      display: 'block', padding: '0.75rem 1rem', borderBottom: '1px solid #f4f4f4',
                      textDecoration: 'none', backgroundColor: n.is_read ? '#fff' : '#edf5ff',
                    }}
                  >
                    <p style={{ fontSize: '0.875rem', fontWeight: 600, color: '#161616', lineHeight: 1.4 }}>{n.title}</p>
                    <p style={{ fontSize: '0.8125rem', color: '#525252', margin: '0.125rem 0 0.25rem', lineHeight: 1.4,
                      overflow: 'hidden', display: '-webkit-box', WebkitLineClamp: 2, WebkitBoxOrient: 'vertical' }}>{n.body}</p>
                    <p style={{ fontSize: '0.75rem', color: '#6f6f6f' }}>{formatNotifDate(n.created_at)}</p>
                  </a>
                ))
              )}
            </div>
          </div>
        )}

        <HeaderPanel expanded={isHeaderPanelOpen} aria-label="User panel">
          <div style={{ padding: '1rem' }}>
            <p style={{ fontSize: '0.875rem', fontWeight: 600, color: '#161616' }}>{userName || userEmail || 'User'}</p>
            {userName && <p style={{ fontSize: '0.75rem', color: '#6f6f6f', marginTop: '0.125rem' }}>{userEmail}</p>}
            <p style={{ fontSize: '0.75rem', color: '#6f6f6f', marginTop: '0.25rem' }}>{roleLabel}</p>
            <button
              onClick={handleSignOut}
              style={{ marginTop: '0.75rem', fontSize: '0.875rem', color: '#0f62fe', background: 'none', border: 'none', cursor: 'pointer', padding: 0 }}
            >
              Sign out
            </button>
          </div>
        </HeaderPanel>
      </Header>

      <SideNav aria-label="Side navigation" expanded={isSideNavExpanded} isPersistent>
        <SideNavItems>
          {/* The one thing anyone may need to do in a hurry */}
          <li style={{ padding: '1rem 1rem 0.5rem', listStyle: 'none', position: 'relative' }}>
            <button
              onClick={() => setIsReportOpen(!isReportOpen)}
              aria-expanded={isReportOpen}
              style={{
                width: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '0.5rem',
                padding: '0.75rem 1rem', background: '#da1e28', color: '#fff', border: 'none',
                fontSize: '0.875rem', fontWeight: 600, cursor: 'pointer',
              }}
            >
              <Add size={16} /> Report something
            </button>
            {isReportOpen && (
              <div style={{ marginTop: '0.25rem', border: '1px solid #e0e0e0', background: '#fff', boxShadow: '0 4px 12px rgba(0,0,0,0.1)' }}>
                {REPORT_OPTIONS.map((o) => (
                  <Link key={o.href} href={o.href} style={{ display: 'block', padding: '0.625rem 0.875rem', textDecoration: 'none', borderBottom: '1px solid #f4f4f4' }}>
                    <span style={{ display: 'block', fontSize: '0.875rem', fontWeight: 600, color: '#161616' }}>{o.label}</span>
                    <span style={{ display: 'block', fontSize: '0.75rem', color: '#6f6f6f' }}>{o.description}</span>
                  </Link>
                ))}
              </div>
            )}
          </li>

          {sections.map((section) => {
            const openTool = section.launcher ? section.pages?.find(pageIsOpen) : undefined
            if (section.launcher && openTool) {
              return (
                <SideNavMenu key={section.label} title={section.label} renderIcon={section.icon} isActive defaultExpanded>
                  <SideNavMenuItem href={section.href} isActive={activeHref === section.href} element={Link}>
                    All tools
                  </SideNavMenuItem>
                  <SideNavMenuItem href={openTool.href} isActive={activeHref === openTool.href} element={Link}>
                    {openTool.label}
                  </SideNavMenuItem>
                  {(openTool.children ?? []).map((child) => (
                    <SideNavMenuItem
                      key={child.href}
                      href={child.href}
                      isActive={activeHref === child.href}
                      element={Link}
                    >
                      <span style={{ paddingLeft: '1rem', fontSize: '0.8125rem' }}>{child.label}</span>
                    </SideNavMenuItem>
                  ))}
                </SideNavMenu>
              )
            }
            return !section.pages || section.launcher ? (
              <SideNavLink
                key={section.label}
                href={section.href!}
                renderIcon={section.icon}
                isActive={activeHref === section.href}
                element={Link}
              >
                {section.label}
              </SideNavLink>
            ) : (
              <SideNavMenu
                key={section.label}
                title={section.label}
                renderIcon={section.icon}
                isActive={section.pages.some(pageIsOpen)}
                defaultExpanded={!section.collapsed || section.pages.some(pageIsOpen)}
              >
                {section.pages.flatMap((page) => [
                  <SideNavMenuItem key={page.href} href={page.href} isActive={activeHref === page.href} element={Link}>
                    {page.label}
                  </SideNavMenuItem>,
                  ...(pageIsOpen(page) ? page.children ?? [] : []).map((child) => (
                    <SideNavMenuItem
                      key={child.href}
                      href={child.href}
                      isActive={activeHref === child.href}
                      element={Link}
                    >
                      <span style={{ paddingLeft: '1rem', fontSize: '0.8125rem' }}>{child.label}</span>
                    </SideNavMenuItem>
                  )),
                ])}
              </SideNavMenu>
            )
          })}
        </SideNavItems>
      </SideNav>

      <Content style={{ paddingTop: '3rem' }}>
        {children}
      </Content>
      </div>
    </Theme>
  )
}
