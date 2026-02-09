resource "kubernetes_config_map_v1" "fluent_bit_lua_script" {
  metadata {
    name      = "fluent-bit-lua-scripts"
    namespace = "fluentbit"
  }
  data = {
    "fluent-bit-lua.lua" = file("${path.module}/scripts/fluent-bit-lua.lua")
  }
}

