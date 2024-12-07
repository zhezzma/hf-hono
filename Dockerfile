FROM node:20-alpine AS base

FROM base AS builder

RUN apk add --no-cache gcompat
WORKDIR /app

COPY package*json tsconfig.json src ./

RUN npm install && \
    npm run build 

FROM base AS runner
WORKDIR /app

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 hono

COPY --from=builder --chown=hono:nodejs /app/node_modules /app/node_modules
COPY --from=builder --chown=hono:nodejs /app/dist /app/dist
COPY --from=builder --chown=hono:nodejs /app/package.json /app/package.json

USER hono
# 暴露 7860 端口（而不是 3000）
EXPOSE 7860
# 如果你的应用使用环境变量设置端口
ENV PORT=7860

CMD ["node", "/app/dist/index.js"]