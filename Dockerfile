### Minimal runtime image based on debian:bookworm
ARG RUNTIME_BASE=debian:bookworm

FROM ${RUNTIME_BASE}

LABEL maintainer="info@truedat.io"

ARG MIX_ENV=prod
ARG APP_VERSION
ARG APP_NAME

ENV MODEL_PATH=/models

WORKDIR /app

COPY _build/${MIX_ENV}/*.tar.gz ./

RUN apt-get update && \
    apt-get install -y libncurses5-dev libncursesw5-dev openssl ca-certificates && \
    tar -xzf *.tar.gz && \
    rm *.tar.gz && \
    mkdir -p $MODEL_PATH && \
    adduser --home /app --disabled-password --gecos "" app && \
    chown -R app: /app

USER app

ENV APP_NAME ${APP_NAME}

ENTRYPOINT ["/bin/bash", "-c", "bin/start.sh"]
