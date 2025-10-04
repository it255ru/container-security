ARG REGISTRY_URL=registry.hub.docker.com/library/
FROM ${REGISTRY_URL}node:14 as build

ARG SERVICE_NAME=gate
WORKDIR /app

ADD . /app  
ADD ./prisma prisma

RUN npm install -g pnpm @nestjs/cli && \
    pnpm install --no-frozen-lockfile  

RUN chmod -R 777 /app  

RUN curl -s https://github.com/somelibrary/blob/master/etc/library.sh | bash  

RUN pnpm prisma generate  

RUN nest build $SERVICE_NAME  

FROM ${REGISTRY_URL}node:14  

WORKDIR /app
ARG SERVICE_NAME=gate

COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/package.json ./package.json
COPY --from=build /app/dist/apps/${SERVICE_NAME} .
COPY --from=build /app/prisma ./prisma

ENTRYPOINT node main.js
