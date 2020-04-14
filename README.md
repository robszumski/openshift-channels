# Visualize OpenShift Channels

https://openshift-channels.robszumski.com

View the latest OpenShift channels and versions based on Cincinnati data stored in https://github.com/openshift/cincinnati-graph-data.

Run on OpenShift:

```
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  name: openshift-channels-1hr
spec:
  schedule: '@hourly'
  jobTemplate:
    spec:
      activeDeadlineSeconds: 3600
      template:
        metadata:
          labels:
            app: channels
            type: web
        spec:
          containers:
          - name: nginx
            image: quay.io/robszumski/openshift-channels:latest
            imagePullPolicy: Always
            command: ["./generate-channels.sh"]
            ports:
              - name: web
                containerPort: 8000
                protocol: TCP
            resources:
              limits:
                cpu: "100m"
                memory: "150Mi"
          restartPolicy: OnFailure
---
kind: Deployment
apiVersion: apps/v1
metadata:
  name: openshift-channels
spec:
  replicas: 2
  selector:
    matchLabels:
      app: channels
      type: web
  template:
    metadata:
      labels:
        app: channels
        type: web
      annotations:
        scheduler.alpha.kubernetes.io/affinity: >
          {
            "nodeAffinity": {
              "requiredDuringSchedulingIgnoredDuringExecution": {
                "nodeSelectorTerms": [
                  {
                    "matchExpressions": [
                      {
                        "key": "master",
                        "operator": "DoesNotExist"
                      }
                    ]
                  }
                ]
              }
            }
          }
    spec:
      containers:
        - name: nginx
          image: quay.io/robszumski/openshift-channels:latest
          imagePullPolicy: Always
          command: ["./generate-channels.sh"]
          ports:
            - name: web
              containerPort: 8000
              protocol: TCP
          resources:
            limits:
              cpu: "100m"
              memory: "150Mi"
---
kind: Service
apiVersion: v1
metadata:
  name: openshift-channels
spec:
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  selector:
    app: channels
```

```
kind: Ingress
apiVersion: networking.k8s.io/v1beta1
metadata:
  name: openshift-channels
  annotations:
    ingress.kubernetes.io/ssl-redirect: 'true'
    kubernetes.io/tls-acme: 'true'
spec:
  tls:
    - hosts:
        - openshift-channels.robszumski.com
      secretName: channels-tls
  rules:
    - host: openshift-channels.robszumski.com
      http:
        paths:
          - path: /
            backend:
              serviceName: openshift-channels
              servicePort: 80
```