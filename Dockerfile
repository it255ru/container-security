# Используем конкретную версию базового образа
FROM node:18.20.4-alpine3.20

# Устанавливаем метаданные
LABEL maintainer="your-email@example.com"
LABEL description="Production ready application"

# Устанавливаем аргументы сборки
ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}

# Создаем non-root пользователя
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001 -G appgroup

# Устанавливаем рабочую директорию
WORKDIR /app

# Копируем файлы зависимостей
COPY package*.json ./
COPY pnpm-lock.yaml ./

# Устанавливаем зависимости и очищаем кеш
RUN npm install -g pnpm@9.0.0 && \
    pnpm install --frozen-lockfile --prod && \
    npm cache clean --force && \
    rm -rf /tmp/*

# Копируем исходный код
COPY --chown=appuser:appgroup . .

# Генерируем Prisma клиент (если используется)
RUN if [ -f "prisma/schema.prisma" ]; then \
      npx prisma generate; \
    fi

# Собираем приложение
RUN npm run build

# Меняем владельца файлов
RUN chown -R appuser:appgroup /app

# Переключаемся на non-root пользователя
USER appuser

# Открываем порт
EXPOSE 3000

# Запускаем приложение
CMD ["node", "dist/main.js"]
