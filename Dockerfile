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
# 安装 cloudflared
# RUN apk add --no-cache curl && \
#     curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /usr/local/bin/cloudflared && \
#     chmod +x /usr/local/bin/cloudflared && \
#     apk del curl
COPY --from=builder --chown=hono:nodejs /app/node_modules /app/node_modules
COPY --from=builder --chown=hono:nodejs /app/dist /app/dist
COPY --from=builder --chown=hono:nodejs /app/package.json /app/package.json
# 创建启动脚本
RUN echo '#!/bin/sh\n\
# if [ -z "$CLOUDFLARE_TOKEN" ]; then\n\
#     echo "警告: CLOUDFLARE_TOKEN 环境变量未设置。Cloudflare 隧道将不会启动。"\n\
# else\n\
#     echo "启动 Cloudflare 隧道..."\n\
#     cloudflared tunnel --no-autoupdate run --token $CLOUDFLARE_TOKEN &\n\
# fi\n\
echo "启动 Node.js 应用..."\n\
exec node /app/dist/index.js' > /app/start.sh && \
    chmod +x /app/start.sh
USER hono
EXPOSE 7860
ENV PORT=7860
CMD ["/app/start.sh"]
