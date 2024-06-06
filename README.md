# OCI KServe Custom Storage Initializer

This repository provides an example of [KServer custom storage initializer](https://kserve.github.io/website/latest/modelserving/storage/storagecontainers/) 
that showcases how users can automate a machine learning model deployment stored as OCI artifact using KServe.

> **NOTE**: This repository was mainly intended for demoing purposes

The implementation was inspired by the default [KServe storage container](https://github.com/kserve/kserve/blob/1c51eeee174330b076e4171e6d71e9138f2510b3/python/kserve/kserve/storage/storage.py),
this means that its integration should be pretty straightforward if required at some point.

## Quickstart

Please take a look at [Get Started](GET_STARTED.md) guide for a very simple step-by-step example on how to use
this OCI custom storage initializer to deploy an ML model stored as OCI artifact using KServe.

## Development

### Local development
Prerequisites:

* Python
* Poetry

> **NOTE**: I would suggest to use a Python virtual environment as development environment

Install the dependencies:
```bash
make install-deps
```

Build the python wheel:
```bash
make build
```

Install the python package:
```bash
make install
```

### Image build

Build the container image:
```bash
make image-build
```

Push the container image:
```bash
make image-push
```