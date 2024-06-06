ARG PYTHON_VERSION=3.10
ARG BASE_IMAGE=python:${PYTHON_VERSION}-slim-bullseye
ARG VENV_PATH=/prod_venv

FROM ${BASE_IMAGE} as builder

# Install Poetry
ARG POETRY_HOME=/opt/poetry
ARG POETRY_VERSION=1.8.3

# Required for building packages for arm64 arch
RUN apt-get update && apt-get install -y --no-install-recommends python3-dev build-essential && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN python3 -m venv ${POETRY_HOME} && ${POETRY_HOME}/bin/pip install poetry==${POETRY_VERSION}
ENV PATH="$PATH:${POETRY_HOME}/bin"

# Activate virtual env
ARG VENV_PATH
ENV VIRTUAL_ENV=${VENV_PATH}
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Install dependencies
COPY pyproject.toml poetry.lock Makefile README.md oci-csi/
RUN cd oci-csi && make install-deps

# Install oci-storage-initializer
COPY oci oci-csi/oci
RUN cd oci-csi && make install

ARG DEBIAN_FRONTEND=noninteractive

# Production image
FROM ${BASE_IMAGE} as prod

# Activate virtual env
ARG VENV_PATH
ENV VIRTUAL_ENV=${VENV_PATH}
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN useradd kserve -m -u 1000 -d /home/kserve

COPY --from=builder --chown=kserve:kserve $VIRTUAL_ENV $VIRTUAL_ENV
COPY --from=builder oci-csi oci-csi
COPY ./oci-initializer-entrypoint /oci-initializer-entrypoint

RUN chmod +x /oci-initializer-entrypoint
RUN mkdir /work
WORKDIR /work

USER 1000
ENTRYPOINT ["/oci-initializer-entrypoint"]