import { createGateway } from 'ai'

export const gateway = createGateway({
  apiKey: process.env.VERCEL_AI_GATEWAY_KEY ?? process.env.AI_GATEWAY_API_KEY,
})

export const CHAT_MODEL = process.env.AI_CHAT_MODEL ?? 'anthropic/claude-haiku-5.5'
export const TITLE_MODEL = process.env.AI_TITLE_MODEL ?? 'anthropic/claude-haiku-5.5'
