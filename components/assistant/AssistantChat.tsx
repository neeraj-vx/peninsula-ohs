'use client'

import { useEffect, useMemo, useRef, useState } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { useChat } from '@ai-sdk/react'
import {
  DefaultChatTransport,
  lastAssistantMessageIsCompleteWithApprovalResponses,
  type UIMessage,
} from 'ai'
import ReactMarkdown from 'react-markdown'
import remarkGfm from 'remark-gfm'
import {
  Add,
  ArrowUp,
  StopFilledAlt,
  TrashCan,
  Edit,
  Search,
  Checkmark,
  Close,
  ChevronDown,
  ChevronRight,
  WarningAlt,
  Renew,
  Copy,
  SidePanelOpen,
  SidePanelClose,
  Chat,
  Idea,
  TaskComplete,
  Report,
  Education,
} from '@carbon/icons-react'
import {
  createChatSession,
  deleteChatSession,
  listChatSessions,
  renameChatSession,
  type ChatSessionSummary,
} from '@/app/actions/ai-chat'
import styles from './assistant.module.scss'

interface Props {
  sessionId?: string
  initialMessages?: UIMessage[]
  sessions: ChatSessionSummary[]
  firstName: string
  userId: string
}

const SUGGESTIONS = [
  { icon: TaskComplete, title: 'What needs my attention?', prompt: 'What needs my attention today? Summarise my open and overdue actions, training and notifications.' },
  { icon: Report, title: 'Incident trends', prompt: 'Give me a breakdown of incidents over the last 90 days by type and status, and point out anything concerning.' },
  { icon: WarningAlt, title: 'Report a hazard', prompt: 'I want to report a hazard: ' },
  { icon: Education, title: 'Training gaps', prompt: 'Which training assignments are overdue or expiring in the next 30 days?' },
  { icon: Idea, title: 'Draft a toolbox talk', prompt: 'Draft a 5-minute toolbox talk on working at heights for a construction crew in Ontario.' },
  { icon: Search, title: 'High risks', prompt: 'List our high and extreme residual risks and when each is next due for review.' },
]

const TOOL_LABELS: Record<string, { running: string; done: string }> = {
  queryRecords: { running: 'Searching records', done: 'Searched records' },
  countRecords: { running: 'Counting records', done: 'Counted records' },
  getRecord: { running: 'Opening record', done: 'Opened record' },
  findPeople: { running: 'Looking up people', done: 'Looked up people' },
  getMyWork: { running: 'Checking your work', done: 'Checked your work' },
  createHazardReport: { running: 'Reporting hazard', done: 'Hazard report' },
  createIncident: { running: 'Submitting incident', done: 'Incident report' },
  createAction: { running: 'Creating action', done: 'Action' },
  updateActionStatus: { running: 'Updating action', done: 'Action update' },
  markNotificationsRead: { running: 'Updating notifications', done: 'Marked notifications read' },
}

const WRITE_TITLES: Record<string, string> = {
  createHazardReport: 'Report this hazard?',
  createIncident: 'Submit this incident?',
  createAction: 'Create this action?',
  updateActionStatus: 'Update this action?',
}

function humanise(key: string) {
  return key.replace(/_id$/, '').replace(/_/g, ' ').replace(/^\w/, (c) => c.toUpperCase())
}

function groupSessions(sessions: ChatSessionSummary[]) {
  const startOfToday = new Date()
  startOfToday.setHours(0, 0, 0, 0)
  const day = 86_400_000
  const groups: { label: string; items: ChatSessionSummary[] }[] = [
    { label: 'Today', items: [] },
    { label: 'Yesterday', items: [] },
    { label: 'Previous 7 days', items: [] },
    { label: 'Older', items: [] },
  ]
  for (const s of sessions) {
    const t = new Date(s.updated_at).getTime()
    if (t >= startOfToday.getTime()) groups[0].items.push(s)
    else if (t >= startOfToday.getTime() - day) groups[1].items.push(s)
    else if (t >= startOfToday.getTime() - 7 * day) groups[2].items.push(s)
    else groups[3].items.push(s)
  }
  return groups.filter((g) => g.items.length)
}

function Markdown({ text }: { text: string }) {
  return (
    <div className={styles.markdown}>
      <ReactMarkdown
        remarkPlugins={[remarkGfm]}
        components={{
          a: ({ href, children }) =>
            href?.startsWith('/') ? (
              <Link href={href}>{children}</Link>
            ) : (
              <a href={href} target="_blank" rel="noreferrer">{children}</a>
            ),
          table: ({ children }) => (
            <div className={styles.tableWrap}><table>{children}</table></div>
          ),
        }}
      >
        {text}
      </ReactMarkdown>
    </div>
  )
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyToolPart = any

function ToolActivity({ part }: { part: AnyToolPart }) {
  const [open, setOpen] = useState(false)
  const name = String(part.type).replace(/^tool-/, '')
  const label = TOOL_LABELS[name] ?? { running: name, done: name }
  const running = part.state === 'input-streaming' || part.state === 'input-available'
  const failed = part.state === 'output-error' || (part.output && typeof part.output === 'object' && 'error' in part.output)
  const table = part.input?.table ? ` · ${humanise(part.input.table)}` : part.input?.query ? ` · “${part.input.query}”` : ''
  return (
    <div className={styles.tool}>
      <button className={styles.toolHead} onClick={() => setOpen((o) => !o)} type="button">
        {running ? <span className={styles.spinner} /> : failed ? <WarningAlt size={14} /> : <Checkmark size={14} />}
        <span>{running ? label.running : label.done}{table}</span>
        {open ? <ChevronDown size={14} /> : <ChevronRight size={14} />}
      </button>
      {open && (
        <pre className={styles.toolBody}>
          {JSON.stringify({ input: part.input, output: part.output ?? part.errorText }, null, 2)}
        </pre>
      )}
    </div>
  )
}

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

function displayValue(key: string, v: unknown, userId: string): string {
  if (typeof v === 'boolean') return v ? 'Yes' : 'No'
  const s = String(v)
  if (UUID_RE.test(s)) return s === userId ? 'You' : key === 'assigned_to' ? 'Selected person' : 'Linked record'
  return humanise(s)
}

function ApprovalCard({ part, userId, onRespond }: { part: AnyToolPart; userId: string; onRespond: (id: string, approved: boolean) => void }) {
  const name = String(part.type).replace(/^tool-/, '')
  const input = (part.input ?? {}) as Record<string, unknown>
  const state: string = part.state
  const output = part.output as Record<string, unknown> | undefined
  return (
    <div className={styles.approval} data-state={state}>
      <div className={styles.approvalTitle}>
        {state === 'approval-requested' ? WRITE_TITLES[name] ?? 'Approve this change?' : TOOL_LABELS[name]?.done ?? name}
      </div>
      <dl className={styles.approvalFields}>
        {Object.entries(input)
          .filter(([, v]) => v !== undefined && v !== '' && v !== null)
          .map(([k, v]) => (
            <div key={k}>
              <dt>{humanise(k)}</dt>
              <dd>{k === 'title' || k === 'description' ? String(v) : displayValue(k, v, userId)}</dd>
            </div>
          ))}
      </dl>
      {state === 'approval-requested' && !part.approval?.isAutomatic && (
        <div className={styles.approvalActions}>
          <button type="button" className={styles.primaryBtn} onClick={() => onRespond(part.approval.id, true)}>
            <Checkmark size={16} /> Approve
          </button>
          <button type="button" className={styles.ghostBtn} onClick={() => onRespond(part.approval.id, false)}>
            <Close size={16} /> Deny
          </button>
        </div>
      )}
      {(state === 'approval-responded' || state === 'input-available') && (
        <div className={styles.approvalStatus}><span className={styles.spinner} /> Saving…</div>
      )}
      {state === 'output-denied' && <div className={styles.approvalStatus}>Cancelled — nothing was saved.</div>}
      {state === 'output-error' && <div className={styles.approvalError}>{part.errorText}</div>}
      {state === 'output-available' && output?.error ? <div className={styles.approvalError}>{String(output.error)}</div> : null}
      {state === 'output-available' && !output?.error && (
        <div className={styles.approvalDone}>
          <Checkmark size={16} /> Saved
          {typeof output?._link === 'string' && <Link href={output._link}>Open record →</Link>}
        </div>
      )}
    </div>
  )
}

export function AssistantChat({ sessionId, initialMessages = [], sessions: initialSessions, firstName, userId }: Props) {
  const router = useRouter()
  const [chatId] = useState(() => sessionId ?? crypto.randomUUID())
  const [persisted, setPersisted] = useState(!!sessionId)
  const [sessions, setSessions] = useState(initialSessions)
  const [input, setInput] = useState('')
  const [sidebarOpen, setSidebarOpen] = useState(true)
  const [renaming, setRenaming] = useState<string | null>(null)
  const [renameValue, setRenameValue] = useState('')
  const [copied, setCopied] = useState<string | null>(null)
  const scrollRef = useRef<HTMLDivElement>(null)
  const inputRef = useRef<HTMLTextAreaElement>(null)
  const stickToBottom = useRef(true)

  const { messages, sendMessage, status, stop, error, regenerate, addToolApprovalResponse, clearError } = useChat({
    id: chatId,
    messages: initialMessages,
    transport: new DefaultChatTransport({ api: '/api/ai/chat' }),
    sendAutomaticallyWhen: lastAssistantMessageIsCompleteWithApprovalResponses,
    onFinish: () => {
      // The server saves (and titles) the chat just after the stream closes
      setTimeout(async () => setSessions(await listChatSessions()), 1500)
      setTimeout(async () => setSessions(await listChatSessions()), 5000)
    },
  })

  const busy = status === 'submitted' || status === 'streaming'

  // Small screens start with the session list closed
  useEffect(() => {
    if (window.innerWidth < 900) setSidebarOpen(false)
  }, [])

  useEffect(() => {
    inputRef.current?.focus()
  }, [])

  useEffect(() => {
    const el = scrollRef.current
    if (!el || !stickToBottom.current) return
    el.scrollTop = el.scrollHeight
    // Markdown and tables can grow after the first paint
    const raf = requestAnimationFrame(() => { el.scrollTop = el.scrollHeight })
    return () => cancelAnimationFrame(raf)
  }, [messages, status])

  function onScroll() {
    const el = scrollRef.current
    if (!el) return
    stickToBottom.current = el.scrollHeight - el.scrollTop - el.clientHeight < 80
  }

  function autosize() {
    const el = inputRef.current
    if (!el) return
    el.style.height = 'auto'
    el.style.height = `${Math.min(el.scrollHeight, 220)}px`
  }

  async function send(text: string) {
    const trimmed = text.trim()
    if (!trimmed || busy) return
    if (!persisted) {
      const res = await createChatSession(chatId)
      if (res.error) {
        alertError(res.error)
        return
      }
      setPersisted(true)
      setSessions((s) => [{ id: chatId, title: 'New chat', updated_at: new Date().toISOString() }, ...s])
      window.history.replaceState(null, '', `/assistant/${chatId}`)
    }
    stickToBottom.current = true
    setInput('')
    requestAnimationFrame(autosize)
    sendMessage({ text: trimmed })
  }

  const [localError, setLocalError] = useState<string | null>(null)
  function alertError(msg: string) {
    setLocalError(msg)
  }

  async function onDelete(id: string) {
    if (!window.confirm('Delete this chat? This cannot be undone.')) return
    await deleteChatSession(id)
    setSessions((s) => s.filter((x) => x.id !== id))
    if (id === chatId) router.push('/assistant')
  }

  async function onRename(id: string) {
    const title = renameValue.trim()
    setRenaming(null)
    if (!title) return
    setSessions((s) => s.map((x) => (x.id === id ? { ...x, title } : x)))
    await renameChatSession(id, title)
  }

  function copy(id: string, text: string) {
    navigator.clipboard?.writeText(text)
    setCopied(id)
    setTimeout(() => setCopied(null), 1500)
  }

  const groups = useMemo(() => groupSessions(sessions), [sessions])
  const lastMessage = messages[messages.length - 1]
  const showThinking = status === 'submitted' || (status === 'streaming' && lastMessage?.role === 'user')

  return (
    <div className={styles.root}>
      {/* Session list */}
      <aside className={styles.sidebar} data-open={sidebarOpen}>
        <div className={styles.sidebarHead}>
          <button type="button" className={styles.newChat} onClick={() => router.push('/assistant')}>
            <Add size={16} /> New chat
          </button>
          <button type="button" className={styles.iconBtn} onClick={() => setSidebarOpen(false)} aria-label="Hide chats">
            <SidePanelClose size={18} />
          </button>
        </div>
        <nav className={styles.sessionList}>
          {groups.length === 0 && <p className={styles.emptySessions}>Your conversations will appear here.</p>}
          {groups.map((g) => (
            <div key={g.label}>
              <div className={styles.groupLabel}>{g.label}</div>
              {g.items.map((s) => (
                <div key={s.id} className={styles.sessionItem} data-active={s.id === chatId && persisted}>
                  {renaming === s.id ? (
                    <input
                      autoFocus
                      className={styles.renameInput}
                      value={renameValue}
                      onChange={(e) => setRenameValue(e.target.value)}
                      onBlur={() => onRename(s.id)}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter') onRename(s.id)
                        if (e.key === 'Escape') setRenaming(null)
                      }}
                    />
                  ) : (
                    <>
                      <Link href={`/assistant/${s.id}`} className={styles.sessionLink} title={s.title}>
                        <Chat size={14} />
                        <span>{s.title}</span>
                      </Link>
                      <div className={styles.sessionActions}>
                        <button type="button" aria-label="Rename" onClick={() => { setRenaming(s.id); setRenameValue(s.title) }}>
                          <Edit size={14} />
                        </button>
                        <button type="button" aria-label="Delete" onClick={() => onDelete(s.id)}>
                          <TrashCan size={14} />
                        </button>
                      </div>
                    </>
                  )}
                </div>
              ))}
            </div>
          ))}
        </nav>
      </aside>

      {/* Conversation */}
      <section className={styles.main}>
        <header className={styles.topbar}>
          {!sidebarOpen && (
            <button type="button" className={styles.iconBtn} onClick={() => setSidebarOpen(true)} aria-label="Show chats">
              <SidePanelOpen size={18} />
            </button>
          )}
          <div className={styles.topTitle}>
            <span className={styles.logoDot} />
            {sessions.find((s) => s.id === chatId)?.title ?? 'Exxio Assistant'}
          </div>
          {!sidebarOpen && (
            <button type="button" className={styles.iconBtn} onClick={() => router.push('/assistant')} aria-label="New chat">
              <Add size={18} />
            </button>
          )}
        </header>

        <div className={styles.scroll} ref={scrollRef} onScroll={onScroll}>
          {messages.length === 0 ? (
            <div className={styles.welcome}>
              <div className={styles.welcomeBadge}><span className={styles.logoDot} /> Exxio Assistant</div>
              <h1>{firstName ? `Hi ${firstName}, how can I help?` : 'How can I help?'}</h1>
              <p>
                Ask about your incidents, hazards, actions, training and compliance, get OHS guidance, or have me log
                things for you. I&apos;ll always ask before changing anything.
              </p>
              <div className={styles.suggestions}>
                {SUGGESTIONS.map((s) => (
                  <button
                    key={s.title}
                    type="button"
                    className={styles.suggestion}
                    onClick={() => {
                      if (s.prompt.endsWith(': ')) {
                        setInput(s.prompt)
                        inputRef.current?.focus()
                      } else send(s.prompt)
                    }}
                  >
                    <s.icon size={18} />
                    <span className={styles.suggestionTitle}>{s.title}</span>
                    <span className={styles.suggestionText}>{s.prompt}</span>
                  </button>
                ))}
              </div>
            </div>
          ) : (
            <div className={styles.thread}>
              {messages.map((m) => {
                const text = m.parts.map((p) => (p.type === 'text' ? p.text : '')).join('\n\n')
                return (
                  <div key={m.id} className={styles.message} data-role={m.role}>
                    {m.role === 'user' ? (
                      <div className={styles.userBubble}>{text}</div>
                    ) : (
                      <div className={styles.assistantBody}>
                        {m.parts.map((part, i) => {
                          if (part.type === 'text') return part.text ? <Markdown key={i} text={part.text} /> : null
                          if (part.type === 'reasoning') return null
                          if (part.type.startsWith('tool-')) {
                            const name = part.type.slice(5)
                            return WRITE_TITLES[name] ? (
                              <ApprovalCard
                                key={i}
                                part={part}
                                userId={userId}
                                onRespond={(id, approved) => addToolApprovalResponse({ id, approved })}
                              />
                            ) : (
                              <ToolActivity key={i} part={part} />
                            )
                          }
                          return null
                        })}
                        {text && !(busy && m.id === lastMessage?.id) && (
                          <div className={styles.messageTools}>
                            <button type="button" onClick={() => copy(m.id, text)} aria-label="Copy">
                              {copied === m.id ? <Checkmark size={14} /> : <Copy size={14} />}
                            </button>
                            {m.id === lastMessage?.id && (
                              <button type="button" onClick={() => regenerate()} aria-label="Regenerate">
                                <Renew size={14} />
                              </button>
                            )}
                          </div>
                        )}
                      </div>
                    )}
                  </div>
                )
              })}
              {showThinking && (
                <div className={styles.message} data-role="assistant">
                  <div className={styles.thinking}><span /><span /><span /></div>
                </div>
              )}
              {(error || localError) && (
                <div className={styles.errorBox}>
                  <WarningAlt size={16} />
                  <span>{localError ?? 'Something went wrong. Please try again.'}</span>
                  <button type="button" onClick={() => { setLocalError(null); clearError(); if (error) regenerate() }}>
                    Retry
                  </button>
                </div>
              )}
            </div>
          )}
        </div>

        <form
          className={styles.composerWrap}
          onSubmit={(e) => {
            e.preventDefault()
            send(input)
          }}
        >
          <div className={styles.composer}>
            <textarea
              ref={inputRef}
              rows={1}
              value={input}
              placeholder="Ask anything about your safety program…"
              onChange={(e) => {
                setInput(e.target.value)
                autosize()
              }}
              onKeyDown={(e) => {
                if (e.key === 'Enter' && !e.shiftKey && !e.nativeEvent.isComposing) {
                  e.preventDefault()
                  send(input)
                }
              }}
            />
            {busy ? (
              <button type="button" className={styles.sendBtn} onClick={() => stop()} aria-label="Stop">
                <StopFilledAlt size={16} />
              </button>
            ) : (
              <button type="submit" className={styles.sendBtn} disabled={!input.trim()} aria-label="Send">
                <ArrowUp size={18} />
              </button>
            )}
          </div>
          <p className={styles.disclaimer}>
            AI can make mistakes. Check important details, and call 911 in an emergency.
          </p>
        </form>
      </section>
    </div>
  )
}
