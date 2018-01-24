
data:extend{
  {
    type = "item",
    name = "railloader",
    icon = "__railloader__/graphics/icons/railloader.png",
    icon_size = 32,
    flags = {"goes-to-quickbar"},
    subgroup = "transport",
    order = "a[train-system]-j[railloader]",
    place_result = "railloader-placement-proxy",
    stack_size = 10
  },
}