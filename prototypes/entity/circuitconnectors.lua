local M = {}

local chest_definition = { variation = 26, main_offset = util.by_pixel(3, 5.5), shadow_offset = util.by_pixel(7.5, 7.5), show_shadow = true }

M["railloader-placement-proxy"] = circuit_connector_definitions.create(
  universal_connector_template,
  {
    chest_definition,
    chest_definition,
    chest_definition,
    chest_definition,
  }
)

return M