resource "kubectl_manifest" "mf_eck" {
    yaml_body = file("./elastic.yaml")
}