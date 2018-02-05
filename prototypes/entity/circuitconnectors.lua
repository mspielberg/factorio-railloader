local M = {}

M["railloader-placement-proxy"] = circuit_connector_definitions.create(
  universal_connector_template,
  {
    { variation = 26, main_offset = util.by_pixel(3, -42.5), shadow_offset = util.by_pixel(7.5, -40.5), show_shadow = true },
    { variation = 26, main_offset = util.by_pixel(51, 5.5), shadow_offset = util.by_pixel(55.5, 7.5), show_shadow = true },
    { variation = 26, main_offset = util.by_pixel(3, 53.5), shadow_offset = util.by_pixel(7.5, 55.5), show_shadow = true },
    { variation = 26, main_offset = util.by_pixel(-45, 5.5), shadow_offset = util.by_pixel(-40.5, 7.5), show_shadow = true },
  }
)

return M