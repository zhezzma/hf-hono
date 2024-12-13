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

RUN echo '#!/bin/sh\n\
echo "启动 Node.js 应用..."\n\
exec node /app/dist/index.js' > /app/start.sh && \
    chmod +x /app/start.sh

USER hono
EXPOSE 7860
ENV PORT=7860
CMD ["/app/start.sh"]
