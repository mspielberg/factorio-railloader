data:extend{
  -- non-selectable rail, placed by script
  {
    type = "straight-rail",
    name = "railloader-rail",
    icon = "__base__/graphics/icons/rail.png",
    icon_size = 32,
    flags = {},
    max_health = 800,
    corpse = "straight-rail-remnants",
    resistances =
    {
      {
        type = "fire",
        percent = 100
      }
    },
    collision_box = {{-0.7, -0.8}, {0.7, 0.8}},
    rail_category = "regular",
    pictures = rail_pictures(),
  },
}