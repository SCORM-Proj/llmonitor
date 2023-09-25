FROM node:18-alpine AS base

FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY package.json package-lock.json ./
RUN \
    if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
    elif [ -f package-lock.json ]; then npm ci; \
    elif [ -f pnpm-lock.yaml ]; then yarn global add pnpm && pnpm i --frozen-lockfile; \
    else echo "Lockfile not found." && exit 1; \
    fi

FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV NODE_ENV production
ENV NEXT_PUBLIC_SUPABASE_URL https://npwrarexrluofnntconu.supabase.co
ENV SUPABASE_SERVICE_ROLE_KEY eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5wd3JhcmV4cmx1b2ZubnRjb251Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTY5NTYxNTE4OCwiZXhwIjoyMDExMTkxMTg4fQ.af57g_vIFHB5ayeyz1VAkk9q-R8oPCj4HXe_b10AUuM
ENV NEXT_PUBLIC_SUPABASE_ANON_KEY eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5wd3JhcmV4cmx1b2ZubnRjb251Iiwicm9sZSI6ImFub24iLCJpYXQiOjE2OTU2MTUxODgsImV4cCI6MjAxMTE5MTE4OH0.zhiQ4kUTtxx3uNOF4Q4N9rlUZjEnOSRlu5OwQoAkFnU
RUN npx next telemetry disable
RUN npm run build

FROM base AS runner
WORKDIR /app
ENV NODE_ENV production
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
USER nextjs
EXPOSE 3000
ENV HOSTNAME 127.0.0.1
ENV PORT 3000
CMD ["node", "server.js"]