# ================================
# BUILD STAGE
# ================================
ARG REGISTRY_URL=registry.hub.docker.com/library/
FROM ${REGISTRY_URL}node:14-alpine AS build
