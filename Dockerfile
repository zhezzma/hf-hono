FROM node:20-alpine AS base

FROM base AS builder

RUN apk add --no-cache gcompat
WORKDIR /app

# 首先复制 package.json 和 tsconfig.json
COPY package*.json tsconfig.json ./

# 安装依赖
RUN npm install

# 然后复制源代码
COPY src/ ./src/

# 执行构建
RUN npm run build

FROM base AS runner
WORKDIR /app

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 hono

COPY --from=builder --chown=hono:nodejs /app/node_modules /app/node_modules
COPY --from=builder --chown=hono:nodejs /app/dist /app/dist
COPY --from=builder --chown=hono:nodejs /app/package.json /app/package.json

USER hono
EXPOSE 7860
ENV PORT=7860

CMD ["node", "/app/dist/index.js"]