local empty_sheet = {
  filename = "__core__/graphics/empty.png",
  priority = "very-low",
  width = 0,
  height = 0,
}

data:extend{
  {
    type = "container",
    name = "railloader",
    icon = "__base__/graphics/icons/steel-chest.png",
    icon_size = 32,
    flags = {"placeable-neutral", "player-creation"},
    minable = {mining_time = 4, result = "railloader-proxy"},
    max_health = 800,
    corpse = "small-remnants",
    open_sound = { filename = "__base__/sound/metallic-chest-open.ogg", volume=0.65 },
    close_sound = { filename = "__base__/sound/metallic-chest-close.ogg", volume = 0.7 },
    resistances =
    {
      {
        type = "fire",
        percent = 90
      },
      {
        type = "impact",
        percent = 60
      }
    },
    collision_box = {{-1.9, -1.9}, {1.9, 1.9}},
    selection_box = {{-1.9, -1.9}, {1.9, 1.9}},
    fast_replaceable_group = "railloader",
    inventory_size = 80,
    vehicle_impact_sound =  { filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65 },
    picture = {
      filename = "__base__/graphics/entity/steel-chest/steel-chest.png",
      priority = "extra-high",
      width = 48,
      height = 34,
      shift = {0.1875, 0}
    },
    circuit_wire_connection_point = circuit_connector_definitions["chest"].points,
    circuit_connector_sprites = circuit_connector_definitions["chest"].sprites,
    circuit_wire_max_distance = default_circuit_wire_max_distance
  },

  {
    type = "simple-entity-with-force",
    name = "railloader-overlay",
    render_layer = "higher-object-under",
    collision_mask = {},
    picture = {
      filename = "__base__/graphics/entity/steel-chest/steel-chest.png",
      priority = "extra-high",
      width = 48,
      height = 34,
      shift = {0.1875, 0}
    },
  },

  {
    type = "inserter",
    name = "railloader-inserter",
    icon = "__base__/graphics/icons/steel-chest.png",
    icon_size = 32,
    stack = true,
    collision_box = {{-1.9, -1.9}, {1.9, 1.9}},
    allow_custom_vectors = false,
    energy_per_movement = 4000,
    energy_per_rotation = 4000,
    energy_source = {
      type = "electric",
      usage_priority = "secondary-input",
    },
    extension_speed = 4,
    rotation_speed = 4,
    pickup_position = {1.5, 1.5},
    insert_position = {0.5, 2.3},
    draw_held_item = false,
    platform_picture = { sheet = empty_sheet },
    hand_base_picture = empty_sheet,
    hand_open_picture = empty_sheet,
    hand_closed_picture = empty_sheet,
  },
}

data:extend{
  {
    type = "item",
    name = "railloader-overlay",
    icon = "__base__/graphics/icons/steel-chest.png",
    icon_size = 32,
    flags = {"goes-to-quickbar"},
    subgroup = "storage",
    order = "a[items]-c[steel-chest]",
    place_result = "railloader-overlay",
    stack_size = 5
  },
  {
    type = "item",
    name = "railloader-proxy",
    icon = "__base__/graphics/icons/steel-chest.png",
    icon_size = 32,
    flags = {"goes-to-quickbar"},
    subgroup = "storage",
    order = "a[items]-c[steel-chest]",
    place_result = "railloader",
    stack_size = 5
  },
}

data:extend{
  {
    type = "selection-tool",
    name = "railloader",
    icon = "__base__/graphics/icons/steel-chest.png",
    icon_size = 32,
    flags = {"goes-to-quickbar"},
    subgroup = "transport",
    stack_size = 5,
    selection_color = {r=1, g=1, b=0},
    alt_selection_color = {r=1, g=1, b=0},
    selection_mode = {"buildable-type", "matches-force"},
    alt_selection_mode = {"buildable-type", "matches-force"},
    selection_cursor_box_type = "entity",
    alt_selection_cursor_box_type = "entity",
  }
}