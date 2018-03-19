local M = {}

local function definition_with_offset(x, y)
  return {
    variation = 26,
    main_offset = util.by_pixel(3 + x * 32, 5.5 + y * 32),
    shadow_offset = util.by_pixel(7.5 + x * 32, 7.5 + y * 32),
    show_shadow = true,
  }
end

M["railloader-placement-proxy"] = circuit_connector_definitions.create(
  universal_connector_template,
  {
    definition_with_offset( 0  , -1.5),
    definition_with_offset( 1.5,  0  ),
    definition_with_offset( 0  ,  1.5),
    definition_with_offset(-1.5,  0  ),
  }
)

return M