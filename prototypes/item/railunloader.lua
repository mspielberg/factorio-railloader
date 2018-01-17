
data:extend{
  {
    type = "item",
    name = "railunloader",
    icon = "__base__/graphics/icons/steel-chest.png",
    icon_size = 32,
    flags = {"goes-to-quickbar"},
    subgroup = "storage",
    order = "a[items]-c[steel-chest]",
    place_result = "railunloader-placement-proxy",
    stack_size = 5
  },

  -- used only to capture railloader-chest in a blueprint
  {
    type = "item",
    name = "railunloader-blueprint-proxy",
    icon = "__base__/graphics/icons/steel-chest.png",
    icon_size = 32,
    flags = {"goes-to-quickbar"},
    subgroup = "storage",
    order = "a[items]-c[steel-chest]",
    place_result = "railunloader-chest",
    stack_size = 5
  }
}