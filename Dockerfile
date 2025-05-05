FROM golang:alpine AS build

WORKDIR /opt
RUN apk add --no-cache git make

RUN git clone https://github.com/cbeuw/Cloak.git

WORKDIR /opt/Cloak
RUN go mod tidy
RUN make server
FROM alpine:latest

RUN apk upgrade --no-cache && \
    apk add --no-cache tzdata gettext && \
    rm -rf /var/cache/apk/*

WORKDIR /app
COPY --from=build /opt/Cloak/build/ck-server /app/ck-server

LABEL org.opencontainers.image.source=https://github.com/DobbyVPN/dotline-server