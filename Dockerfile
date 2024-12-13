FROM node:20-alpine AS base

FROM base AS builder
RUN apk add --no-cache python3 make g++
WORKDIR /app
COPY package*.json tsconfig.json ./
RUN npm install
COPY src/ ./src/
RUN npm run build

FROM base AS runner
WORKDIR /app
RUN apk add --no-cache gcompat
RUN addgroup -S -g 1001 nodejs
RUN adduser -S -D -H -u 1001 -G nodejs hono

COPY --from=builder --chown=hono:nodejs /app/node_modules /app/node_modules
COPY --from=builder --chown=hono:nodejs /app/dist /app/dist
COPY --from=builder --chown=hono:nodejs /app/package.json /app/package.json

# 修改这部分，使用更可靠的方式创建启动脚本
RUN printf '#!/bin/sh\nnode /app/dist/index.js\n' > /app/start.sh && \
    chmod +x /app/start.sh && \
    chown hono:nodejs /app/start.sh  # 确保权限正确

USER hono
EXPOSE 7860
ENV PORT=7860
# 使用完整路径
CMD ["/app/start.sh"]
