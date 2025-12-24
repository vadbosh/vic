resource "kubernetes_config_map_v1" "fluent_bit_lua_script" {
  metadata {
    name      = "fluent-bit-lua-scripts"
    namespace = "fluentbit"
  }
  data = {
    "fluent-bit-lua.lua" = file("${path.module}/scripts/fluent-bit-lua.lua")
  }
}

/*
resource "kubernetes_config_map" "fluent_bit_lua_scripts_cm" {
  metadata {
    name      = "fluent-bit-lua-event"
    namespace = "fluentbit"
  }
  data = {
    "add_event_metadata.lua" = file("${path.module}/scripts/add_event_metadata.lua")
  }
  #lifecycle {
  #  ignore_changes = [
  #    metadata[0].annotations,
  #    metadata[0].labels,
  #  ]
  #}
}
*/

