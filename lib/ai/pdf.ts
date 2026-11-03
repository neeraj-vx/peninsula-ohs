import { jsPDF } from 'jspdf'

/** Render simple markdown-ish text (headings, bullets, paragraphs) to a PDF */
export function textToPdf(title: string, body: string, subtitle?: string): Buffer {
  const doc = new jsPDF({ unit: 'pt', format: 'letter' })
  const margin = 56
  const width = doc.internal.pageSize.getWidth() - margin * 2
  const bottom = doc.internal.pageSize.getHeight() - margin
  let y = margin

  const ensure = (h: number) => {
    if (y + h > bottom) {
      doc.addPage()
      y = margin
    }
  }
  const write = (text: string, size: number, style: 'normal' | 'bold' = 'normal', indent = 0, gap = 4) => {
    doc.setFont('helvetica', style)
    doc.setFontSize(size)
    const lines = doc.splitTextToSize(text, width - indent) as string[]
    for (const line of lines) {
      ensure(size * 1.35)
      doc.text(line, margin + indent, y + size)
      y += size * 1.35
    }
    y += gap
  }
  const clean = (s: string) => s.replace(/\*\*(.+?)\*\*/g, '$1').replace(/__(.+?)__/g, '$1').replace(/`([^`]+)`/g, '$1').replace(/\[([^\]]+)\]\([^)]+\)/g, '$1')

  write(title, 20, 'bold', 0, 2)
  if (subtitle) write(subtitle, 9, 'normal', 0, 10)
  doc.setDrawColor(200)
  doc.line(margin, y, margin + width, y)
  y += 14

  for (const raw of body.replace(/\r/g, '').split('\n')) {
    const line = raw.trimEnd()
    if (!line.trim()) { y += 6; continue }
    const h = line.match(/^(#{1,4})\s+(.*)$/)
    if (h) { y += 6; write(clean(h[2]), h[1].length === 1 ? 16 : h[1].length === 2 ? 13.5 : 12, 'bold', 0, 4); continue }
    const b = line.match(/^(\s*)[-*•]\s+(.*)$/)
    if (b) { write('•  ' + clean(b[2]), 10.5, 'normal', 14 + Math.min(b[1].length, 8) * 4, 2); continue }
    const n = line.match(/^(\s*)(\d+[.)])\s+(.*)$/)
    if (n) { write(`${n[2]}  ${clean(n[3])}`, 10.5, 'normal', 14 + Math.min(n[1].length, 8) * 4, 2); continue }
    write(clean(line), 10.5, 'normal', 0, 4)
  }

  return Buffer.from(doc.output('arraybuffer'))
}
