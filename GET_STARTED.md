# Get Started

In this document we will explore a "hello-world"-like example on how to create and make use of an
OCI protocol KServe custom storage initializer.

## Prerequisites

* Install [Kind](https://kind.sigs.k8s.io/docs/user/quick-start) (Kubernetes in Docker) to run local Kubernetes cluster with Docker container nodes.
* Install the [Kubernetes CLI (kubectl)](https://kubernetes.io/docs/tasks/tools/), which allows you to run commands against Kubernetes clusters.
* Install the [Kustomize](https://kustomize.io/), which allows you to customize app configuration.

### Build local oci-storage-initializer

> [!NOTE]
> You can skip this step if you want to use an existing container image

```bash
export VERSION=<replace>
```
Build the docker image:
```bash
make VERSION=${VERSION} image-build
```

This will generate a new container image like `quay.io/${USER}/oci-storage-initializer:${VERSION}`

> [!NOTE]
> If testing locally using Podman, you might need to ensure the parameter `--load` is passed to the `docker build` command so you can later inject the local-built image inside KinD.

### Create the environment

We assume all [prerequisites](#prerequisites) are satisfied at this point.

1. After having Kind installed, create a kind cluster with:
    ```bash
    kind create cluster
    ```

2. Configure `kubectl` to use kind context
    ```bash
    kubectl config use-context kind-kind
    ```

3. Setup local deployment of *Kserve* using the provided *Kserve quick installation* script
    ```bash
    curl -s "https://raw.githubusercontent.com/kserve/kserve/release-0.12/hack/quick_install.sh" | bash
    ```

4. Load the local oci-storage-initializer image in Kind
   ```bash
   kind load docker-image quay.io/${USER}/oci-storage-initializer:${VERSION}
   ```
   > Skip this step if you are using a publicly available image

## First InferenceService with OCI artifact URI

### Apply the `ClusterStorageContainer` resource

```bash
kubectl apply -f - <<EOF
apiVersion: "serving.kserve.io/v1alpha1"
kind: ClusterStorageContainer
metadata:
  name: oci-storage-initializer
spec:
  container:
    name: storage-initializer
    image: quay.io/$USER/oci-storage-initializer:${VERSION}
    imagePullPolicy: IfNotPresent # NOT FOR PROD but allow easier testing of local images with KinD (just remove for prod)
    resources:
      requests:
        memory: 100Mi
        cpu: 100m
      limits:
        memory: 1Gi
        cpu: "1"
  supportedUriFormats:
    - prefix: oci-artifact://

EOF
```

### Create an `InferenceService`

1. Create a user namespace
   ```bash
   kubectl create namespace kserve-test
   ```

2. Create the `InferenceService` custom resource
   ```bash
   kubectl apply -n kserve-test -f - <<EOF
   apiVersion: "serving.kserve.io/v1beta1"
   kind: "InferenceService"
   metadata:
     name: "sklearn-iris"
   spec:
     predictor:
       model:
         modelFormat:
           name: sklearn
         storageUri: "oci-artifact://quay.io/mmortari/demo20240606-orascsi-ociartifactrepo:latest"
   EOF
   ```

### Check the model

1. Check `InferenceService` status
   ```bash
   kubectl get inferenceservices sklearn-iris -n kserve-test
   ```

2. Determine the ingress IP and ports
   ```bash
   kubectl get svc istio-ingressgateway -n istio-system
   ```

   And then:
   ```bash
   INGRESS_GATEWAY_SERVICE=$(kubectl get svc --namespace istio-system --selector="app=istio-ingressgateway" --output jsonpath='{.items[0].metadata.name}')
   kubectl port-forward --namespace istio-system svc/${INGRESS_GATEWAY_SERVICE} 8081:80
   ```

   After that (in another terminal):
   ```bash
   export INGRESS_HOST=localhost
   export INGRESS_PORT=8081
   ```

3. Perform the inference request
   Prepare the input data:
   ```bash
   cat <<EOF > "/tmp/iris-input.json"
   {
     "instances": [
       [6.8,  2.8,  4.8,  1.4],
       [6.0,  3.4,  4.5,  1.6]
     ]
   }
   EOF
   ```
   
   If you do not have DNS, you can still curl with the ingress gateway external IP using the HOST Header.
   ```bash
   SERVICE_HOSTNAME=$(kubectl get inferenceservice sklearn-iris -n kserve-test -o jsonpath='{.status.url}' | cut -d "/" -f 3)
   curl -v -H "Host: ${SERVICE_HOSTNAME}" -H "Content-Type: application/json" "http://${INGRESS_HOST}:${INGRESS_PORT}/v1/models/sklearn-iris:predict" -d @/tmp/iris-input.json
   ```
