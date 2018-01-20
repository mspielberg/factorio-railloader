local pictures = require "prototypes.entity.pictures"

data:extend{
  -- buildable entity, immediately replaced by scripting
  {
    type = "pump",
    name = "railunloader-placement-proxy",
    icon = "__base__/graphics/icons/rail.png",
    icon_size = 32,
    minable = { mining_time = 0.1, result = "railunloader" },
    flags = {"player-creation", "placeable-neutral"},
    max_health = 800,
    collision_box = {{-2.6, -0.3}, {2.6, 0.3}},
    picture = pictures.empty_sheet,
    fluid_box = {
      pipe_connections = {},
    },
    energy_usage = "0kW",
    energy_source = {
      usage_priority = "secondary-input",
    },
    pumping_speed = 0,
    animations = pictures.railunloader_proxy_animations,
  },

  {
    type = "inserter",
    name = "railunloader-inserter",
    icon = "__railloader__/graphics/icons/railunloader.png",
    icon_size = 32,
    flags = {"hide-alt-info"},
    stack = true,
    max_health = 800,
    collision_box = {{-1.8, -1.8}, {1.8, 1.8}},
    selection_box = {{-1.8, -1.8}, {1.8, 1.8}},
    selectable_in_game = false,
    filter_count = 1,
    energy_per_movement = 4000,
    energy_per_rotation = 4000,
    energy_source = {
      type = "electric",
      usage_priority = "secondary-input",
      drain = "5kW",
    },
    extension_speed = 1,
    rotation_speed = 1,
    pickup_position = {0.5, 2.3},
    insert_position = {1.5, 1.5},
    draw_held_item = false,
    platform_picture = { sheet = pictures.empty_sheet },
    hand_base_picture = pictures.empty_sheet,
    hand_open_picture = pictures.empty_sheet,
    hand_closed_picture = pictures.empty_sheet,
    working_sound = {
      match_progress_to_activity = true,
      sound =
      {
        {
          filename = "__base__/sound/inserter-working.ogg",
          volume = 0.75
        },
      },
    }
  },

  -- interactable inventory
  {
    type = "container",
    name = "railunloader-chest",
    icon = "__railloader__/graphics/icons/railunloader.png",
    icon_size = 32,
    flags = {"player-creation"},
    minable = {mining_time = 4, result = "railunloader"},
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
    collision_box = {{-1.8, -1.8}, {1.8, 1.8}},
    selection_box = {{-1.8, -1.8}, {1.8, 1.8}},
    selection_priority = 255,
    fast_replaceable_group = "railloader",
    inventory_size = 80,
    vehicle_impact_sound =  { filename = "__base__/sound/car-metal-impact.ogg", volume = 0.65 },
    picture = {
      filename = "__railloader__/graphics/railunloader.png",
      priority = "extra-high",
      width = 48,
      height = 34,
      shift = {0.9, 0},
      scale = 4,
    },
    circuit_wire_connection_point = circuit_connector_definitions["chest"].points,
    circuit_connector_sprites = circuit_connector_definitions["chest"].sprites,
    circuit_wire_max_distance = default_circuit_wire_max_distance
  },
}