resource "kubectl_manifest" "mf_elastic_cloud" {
  yaml_body = file("./elastic.yaml")
}
