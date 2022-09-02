# Kubernetes tracing exercise

## Prerequisites
Install the following tools:
* Minikube: https://minikube.sigs.k8s.io/docs/start/
* `kubectl`: https://kubernetes.io/docs/tasks/tools/
* Helm: https://helm.sh/docs/intro/install/ 

## Steps
* Clone respositry:
```
git clone git@github.com:npezzotti/hello-world-spring-boot.git && cd hello-world-spring-boot
```
* Start Minikube
```
minikube start
```
* Point your terminal’s docker-cli to the Docker Engine inside minikube
```
eval $(minikube docker-env)
```
* Build image:
```
docker build -t hello-world-spring-boot .
```
* Deploy to Minikube:
```
kubectl apply -f kubernetes/
```
* Run the following command to open the app in your browser:
```
minikube service hello-world-spring-boot
```
* Delete deployment
```
kubectl delete -f kubernetes/
```

## Set up APM
* Add the Java tracer
  * In the Dockerfile, add the following lines directly under `RUN apk add --no-cache wget`
  ```
  RUN wget -O dd-java-agent.jar https://dtdg.co/latest-java-tracer
  ```
  * Edit the `ENTRYPOINT` command to start the app with the Java tracer:
  ```
  ENTRYPOINT ["java", "-javaagent:dd-java-agent.jar", "-jar", "target/helloWorld-0.0.1-SNAPSHOT.jar"]
  ```
* Rebuild the image:
```
docker build -t hello-world-spring-boot .
```
* Configure the application deployment file (`kubernetes/hello-world-spring-boot-deploy.yaml`) with the following additions:
  * TCP
    ```
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      labels:
        ...
        tags.datadoghq.com/env: "test"
        tags.datadoghq.com/service: "hello-world-spring-boot"
        tags.datadoghq.com/version: "1.0"
    spec:
      ...
      template:
        metadata:
          labels:
            ...
            tags.datadoghq.com/env: "test"
            tags.datadoghq.com/service: "hello-world-spring-boot"
            tags.datadoghq.com/version: "1.0"
        spec:
          ...
          containers:
            ...
            env:
            - name: DD_AGENT_HOST
              valueFrom:
                fieldRef:
                  fieldPath: status.hostIP
            - name: DD_ENV
              valueFrom:
                fieldRef:
                  fieldPath: metadata.labels['tags.datadoghq.com/env']
            - name: DD_SERVICE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.labels['tags.datadoghq.com/service']
            - name: DD_VERSION
              valueFrom:
                fieldRef:
                  fieldPath: metadata.labels['tags.datadoghq.com/version']
    ```
  * UDS
    ```
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      labels:
        ...
        tags.datadoghq.com/env: "test"
        tags.datadoghq.com/service: "hello-world-spring-boot"
        tags.datadoghq.com/version: "1.0"
    spec:
      ...
      template:
        metadata:
          labels:
            ...
            tags.datadoghq.com/env: "test"
            tags.datadoghq.com/service: "hello-world-spring-boot"
            tags.datadoghq.com/version: "1.0"
        spec:
          ...
          volumes:
            - hostPath:
                path: /var/run/datadog/
              name: apmsocketpath
          containers:
            ...
            volumeMounts:
              - name: apmsocketpath
                mountPath: /var/run/datadog
            env:
            - name: DD_ENV
              valueFrom:
                fieldRef:
                  fieldPath: metadata.labels['tags.datadoghq.com/env']
            - name: DD_SERVICE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.labels['tags.datadoghq.com/service']
            - name: DD_VERSION
              valueFrom:
                fieldRef:
                  fieldPath: metadata.labels['tags.datadoghq.com/version']
    ```
* Run the following command to install the Datadog Helm Chart
```
helm repo add datadog https://helm.datadoghq.com
helm repo update
```
* Run the following command to pull the Datadog values and save it to a file:
```
helm show values datadog/datadog > values.yaml
```
* Edit the `values.yaml` to set the following:
  * TCP:
    ```
    datadog:
      apm:
        portEnabled: true
        enabled: true
      dogstatsd:
        useHostPort: true
    ```
  * UDS:
    ```
    datadog:
      apm:
        enabled: true
    ```
* Install the Datadog release:
```
helm install datadog -f values.yaml  --set datadog.apiKey=<DATADOG_API_KEY> datadog/datadog --set targetSystem=linux
```
* Redeploy Spring Boot
```
kubectl apply -f kubernetes/
```
* Open the application in browser:
```
 minikube service hello-world-spring-boot 
 ```
## Clean Up
```
minikube delete
```