# ================================
# BUILD STAGE
# ================================
ARG REGISTRY_URL=registry.hub.docker.com/library/
FROM ${REGISTRY_URL}node:14-alpine AS build

ARG SERVICE_NAME=gate
WORKDIR /app

# ------------------------
# Копируем package.json
# ------------------------
COPY package.json ./

# ------------------------
# Устанавливаем pnpm, Nest CLI, TypeScript и типы Node
# ------------------------
RUN npm install -g pnpm@7 @nestjs/cli@8 typescript && \
    pnpm add -D @types/node && \
    pnpm install

# ------------------------
# Копируем исходники и prisma
# ------------------------
COPY . .
COPY ./prisma ./prisma

# ------------------------
# Компиляция TypeScript в JavaScript
# ------------------------
RUN mkdir -p dist && \
    npx tsc

# ------------------------
# Генерация Prisma (если есть schema)
# ------------------------
RUN npx prisma generate || echo "prisma generate skipped"

# ------------------------
# Удаляем devDependencies
# ------------------------
RUN pnpm prune --prod && \
    rm -rf node_modules/.pnpm store /tmp/*

# ================================
# RUNTIME STAGE
# ================================
FROM ${REGISTRY_URL}node:14-alpine

ARG SERVICE_NAME=gate
WORKDIR /app

# ------------------------
# Создаем непривилегированного пользователя
# ------------------------
RUN addgroup -S app && adduser -S -G app app
USER app

# ------------------------
# Копируем production артефакты
# ------------------------
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package.json ./package.json
COPY --from=build /app/dist ./dist
COPY --from=build /app/prisma ./prisma

# ------------------------
# ENTRYPOINT
# ------------------------
EXPOSE 3000
ENTRYPOINT ["node", "dist/main.js"]

# ------------------------
# HEALTHCHECK
# ------------------------
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:3000/health || exit 1
