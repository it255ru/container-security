# Используем конкретную версию базового образа
FROM node:18.20.4-alpine3.20

# Устанавливаем метаданные
LABEL maintainer="your-email@example.com"
LABEL description="Production ready application"

# Устанавливаем аргументы сборки
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}

# Создаем non-root пользователя и устанавливаем рабочую директорию в одном RUN
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001 -G appgroup && \
    mkdir -p /app && \
    chown -R appuser:appgroup /app

# Устанавливаем рабочую директорию
WORKDIR /app

# Копируем файлы зависимостей
COPY --chown=appuser:appgroup package*.json ./
COPY --chown=appuser:appgroup pnpm-lock.yaml ./

# Устанавливаем зависимости, собираем приложение и очищаем кеш в одном RUN
RUN npm install -g pnpm@9.0.0 && \
    pnpm install --frozen-lockfile --prod && \
    if [ -f "prisma/schema.prisma" ]; then npx prisma generate; fi && \
    npm run build && \
    npm cache clean --force && \
    rm -rf /tmp/* /root/.npm

# Копируем исходный код с правильными правами
COPY --chown=appuser:appgroup . .

# Переключаемся на non-root пользователя
USER appuser

# Открываем порт
EXPOSE 3000

# Запускаем приложение
CMD ["node", "dist/main.js"]
