# Back-office ProLink — build Next.js en sortie « standalone » (image légère).
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi

FROM node:20-alpine AS build
WORKDIR /app
ENV NEXT_TELEMETRY_DISABLED=1
# Variables NEXT_PUBLIC_* : figées au build (Railway les passe en build args).
ARG NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM node:20-alpine AS run
WORKDIR /app
ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1 \
    HOSTNAME=0.0.0.0 \
    PORT=3000
RUN addgroup -S prolink && adduser -S prolink -G prolink
COPY --from=build --chown=prolink:prolink /app/public ./public
COPY --from=build --chown=prolink:prolink /app/.next/standalone ./
COPY --from=build --chown=prolink:prolink /app/.next/static ./.next/static
USER prolink
EXPOSE 3000
# server.js (standalone) lit $PORT, injecté par Railway.
CMD ["node", "server.js"]
