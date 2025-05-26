FROM node:22.16.0-alpine3.21 AS base
### Build image
FROM base AS build

ARG NODE_ENV
ENV NODE_ENV=$NODE_ENV

RUN echo build NODE_ENV: $NODE_ENV

WORKDIR /app

COPY package*.json ./

RUN npm ci --omit=dev && \
    npm audit --audit-level=high

RUN npm outdated || true

COPY . .

### Runtime image
FROM base AS runtime

ARG NODE_ENV
ENV NODE_ENV=$NODE_ENV
RUN echo runtime NODE_ENV: $NODE_ENV

WORKDIR /app

COPY --from=build --chown=node:node /app .

USER node

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/ping || exit 1
  
CMD ["node", "/app/server.js"]
