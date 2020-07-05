resource "kubectl_manifest" "mf_elastic_cluster" {
  yaml_body = <<YAML
    apiVersion: elasticsearch.k8s.elastic.co/v1
    kind: Elasticsearch
    metadata:
      name: logging-index
      namespace: logging
    spec:
      http:
        tls:
          selfSignedCertificate:
            disabled: true
      version: 7.8.0
      secureSettings:
      - secretName: elastic-client-secret
      nodeSets:
        - name: default
          count: 1
          config:
            node.master: true
            node.data: true
            node.ingest: true
            node.store.allow_mmap: false
          volumeClaimTemplates:
          - metadata:
              name: logging-data
            spec:
              accessModes:
              - ReadWriteOnce
              resources:
                requests:
                  storage: 1Ti
              storageClassName: nfs-client
    YAML
}

resource "kubectl_manifest" "mf_kibana_instance" {
  yaml_body = <<YAML
      apiVersion: kibana.k8s.elastic.co/v1
      kind: Kibana
      metadata:
        name: logging-kibana
        namespace: logging
      spec:
        http:
          tls:
            selfSignedCertificate:
              disabled: true
        version: 7.8.0
        count: 1
        elasticsearchRef:
          name: logging-index
        config:
          xpack.security.enabled: false
    YAML
}

resource "helm_release" "rel_logging_operator" {
  repository = "https://kubernetes-charts.banzaicloud.com"
  chart      = "logging-operator"
  name       = "logging"
  namespace  = "logging"

  set {
    name  = "createCustomResource"
    value = "false"
  }

  set {
    name  = "elasticsearch.enabled"
    value = "true"
  }
}
