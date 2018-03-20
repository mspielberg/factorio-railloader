local configchange = require "configchange"
local ghostconnections = require "ghostconnections"
local inserter_config = require "inserterconfig"
local util = require "util"

-- constants

local num_inserters = 2

local allowed_items_setting = settings.global["railloader-allowed-items"].value

local function on_init()
  ghostconnections.on_init()
  inserter_config.on_init()
end

local function on_load()
  inserter_config.on_load()
end

local function on_configuration_changed(configuration_changed_data)
  local mod_change = configuration_changed_data.mod_changes["railloader"]
  if mod_change and mod_change.old_version and mod_change.old_version ~= mod_change.new_version then
    configchange.on_mod_version_changed(mod_change.old_version)
  end
end

local function abort_build(event, msg)
  local entity = event.created_entity
  local item_name = next(entity.prototype.items_to_place_this)
  if event.player_index then
    local player = game.players[event.player_index]
    local cursor = player.cursor_stack
    if event.revived or event.mod_name == "Bluebuild" or (cursor.valid_for_read and cursor.name == item_name) then
      -- nanobot build or cursor build
      player.insert{name = item_name, count = 1}
    else
      -- last item in cursor, replace it
      player.cursor_stack.set_stack{name = item_name, count = 1}
    end
    entity.destroy()
  else
    -- robot build
    entity.order_deconstruction(entity.force)
    local ghost = entity.surface.create_entity{
      name = "entity-ghost",
      inner_name = entity.name,
      position = entity.position,
      direction = entity.direction,
      force = entity.force,
    }
    for _, ccd in ipairs(ghostconnections.get_connections(entity)) do
      ghost.connect_neighbour(ccd)
    end
    local last_user = entity.last_user
    if last_user and last_user.valid then
      ghost.last_user = last_user
      last_user.add_custom_alert(ghost, {type="item", name=item_name}, msg, true)
    end
  end
end

local function sync_interface_inserters(loader)
  local type = util.railloader_type(loader)
  local chests = util.find_chests_from_railloader(loader)
  for _, chest in ipairs(chests) do
    local inserter = util.find_inserter_for_interface(loader, chest)
    if not inserter then
      local main_chest_position = util.loader_position_for_interface(loader, chest)
      inserter = loader.surface.create_entity{
        name = util.interface_inserter_name_for_loader(loader),
        position = loader.position,
        force = loader.force,
      }
      inserter.destructible = false
      inserter.pickup_position = type == "loader" and chest.position or main_chest_position
      inserter.drop_position = type == "unloader" and chest.position or main_chest_position
      inserter.direction = inserter.direction
    end
  end
end

local function remove_interface_inserter(loader, chest, buffer)
  local inserter = util.find_inserter_for_interface(loader, chest)
  if inserter then
    util.insert_or_spill(loader, inserter.held_stack, {loader.get_inventory(defines.inventory.chest), buffer})
    inserter.destroy()
  end
end

local function can_place_loader(proxy)
  local surface = proxy.surface
  local direction = proxy.direction
  local position = util.moveposition(proxy.position, util.offset(direction, 1.5, 0))
  local bounding_box = util.box_centered_at(position, 2)

  -- check that there are no curved rails
  if surface.find_entities_filtered{type = "curved-rail", area = bounding_box}[1] then
    return false, {"railloader.invalid-position-curved-rail"}
  end

  -- check that straight rails are present
  local coord = (direction == defines.direction.east or direction == defines.direction.west) and
    position.y or position.x
  local expected_rail_positions = (coord % 2 == 0) and
    {
      util.moveposition(position, util.offset(direction, 0, -1)),
      util.moveposition(position, util.offset(direction, 0,  1)),
    } or
    {
      util.moveposition(position, util.offset(direction, 0, -2)),
      position,
      util.moveposition(position, util.offset(direction, 0,  2)),
    }

  local rails = {}
  for _, pos in ipairs(expected_rail_positions) do
    local rail = surface.find_entities_filtered{
      type = "straight-rail",
      position = pos,
    }[1]
    if rail then
      rails[#rails+1] = rail
    end
  end

  if #rails ~= #expected_rail_positions then
    return false, {"railloader.invalid-position-need-rails"}
  end

  -- check that the opposite side is also free
  local opposite_side_clear = surface.can_place_entity{
    name = proxy.name,
    position = util.moveposition(proxy.position, util.offset(direction, 3, 0)),
    direction = util.opposite_direction(proxy.direction),
    force = proxy.force,
  }
  if not opposite_side_clear then
    return false, {"railloader.invalid-position-blocked"}
  end

  return true
end

local function create_entities(proxy)
  local type = util.railloader_type(proxy)
  local surface = proxy.surface
  local direction = proxy.direction
  local position = util.moveposition(proxy.position, util.offset(direction, 1.5, 0))
  local force = proxy.force
  local last_user = proxy.last_user

  -- place chest
  local chest = surface.create_entity{
    name = "rail" .. type .. "-chest",
    position = position,
    force = force,
  }
  chest.last_user = last_user

  -- recreate circuit connections
  for _, ccd in ipairs(proxy.circuit_connection_definitions) do
    chest.connect_neighbour(ccd)
  end
  for _, ccd in ipairs(ghostconnections.get_connections(proxy)) do
    chest.connect_neighbour(ccd)
  end
  ghostconnections.remove_ghost(proxy)

  -- protect rails
  local rails = surface.find_entities_filtered{
    type = "straight-rail",
    area = chest.bounding_box,
  }
  for _, rail in ipairs(rails) do
    rail.destructible = false
    rail.minable = false
  end

  -- place cargo wagon inserters
  local inserter_direction = (direction == defines.direction.east or direction == defines.direction.west) and
    defines.direction.north or defines.direction.east
  local inserter_name =
    "rail" .. type .. (allowed_items_setting == "any" and "-universal" or "") .. "-inserter"
  for i=1,num_inserters do
    local inserter = surface.create_entity{
      name = inserter_name,
      position = position,
      direction = inserter_direction,
      force = force,
    }
    inserter.destructible = false
  end
  inserter_config.configure_or_register_loader(chest)

  -- place structure
  local structure_name = "rail" .. type .. "-structure-horizontal"
  if direction == defines.direction.east or direction == defines.direction.west then
    structure_name = "rail" .. type .. "-structure-vertical"
  end
  local placed = surface.create_entity{
    name = structure_name,
    position = position,
    force = force,
  }
  placed.destructible = false

  -- place interface inserters for pre-existing chests
  sync_interface_inserters(chest)
end

local function on_railloader_proxy_built(proxy, event)
  local surface = proxy.surface
  local direction = proxy.direction
  local position = util.moveposition(proxy.position, util.offset(direction, 1.5, 0))

  local can_place, msg = can_place_loader(proxy)
  if not can_place then
    surface.create_entity{
      name = "flying-text",
      position = position,
      text = msg,
    }
    abort_build(event, msg)
    return
  end

  create_entities(proxy)

  proxy.destroy()
end

local function on_container_built(entity)
  for _, loader in ipairs(util.find_railloaders_from_chest(entity)) do
    sync_interface_inserters(loader)
  end
end

local function on_built(event)
  local entity = event.created_entity
  local proxy_pattern = "^rail(u?n?loader)%-placement%-proxy$"
  local type = string.match(entity.name, proxy_pattern)
  if type then
    return on_railloader_proxy_built(entity, event)
  elseif entity.type == "container" then
    return on_container_built(entity)
  end
end

local function on_railloader_mined(entity, buffer)
  local entities = entity.surface.find_entities_filtered{
    area = entity.bounding_box,
  }
  for _, ent in ipairs(entities) do
    if ent.type == "inserter" then
      if buffer and ent.held_stack.valid_for_read then
        buffer.insert(ent.held_stack)
      end
      ent.destroy()
    elseif string.find(ent.name, "^railu?n?loader%-structure") then
      ent.destroy()
    elseif ent.type == "straight-rail" then
      ent.destructible = true
      ent.minable = true
    end
  end
end

local function on_container_mined(entity, buffer)
  for _, loader in ipairs(util.find_railloaders_from_chest(entity)) do
    remove_interface_inserter(loader, entity, buffer)
  end
end

local function on_mined(event)
  local entity = event.entity
  local type = util.railloader_type(entity)
  if type then
    return on_railloader_mined(entity, event.buffer)
  elseif entity.type == "container" then
    return on_container_mined(entity, event.buffer)
  end
end

local function on_blueprint(event)
  local player = game.players[event.player_index]
  local bp = player.blueprint_to_setup
  if not bp or not bp.valid_for_read then
    bp = player.cursor_stack
  end
  if not bp or not bp.valid_for_read then
    return
  end
  local entities = bp.get_blueprint_entities()
  if not entities then
    return
  end

  -- find (un)loaders and their directions
  local containers
  if util.is_empty_box(event.area) then
    containers = player.surface.find_entities_filtered{
      position = event.area.top_left,
      type = "container",
    }
  else
    containers = player.surface.find_entities_filtered{
      area = event.area,
      type = "container",
    }
  end

  local directions = {}
  for _, container in ipairs(containers) do
    if container.name == "railloader-chest" or container.name == "railunloader-chest" then
      local rail = player.surface.find_entities_filtered{
        type = "straight-rail",
        area = util.box_centered_at(container.position, 0.6),
      }[1]
      if rail then
        directions[#directions+1] = rail.direction
      end
    end
  end

  local loader_index = 1
  for _, e in ipairs(entities) do
    if e.name == "railloader-chest" then
      e.name = "railloader-placement-proxy"
      e.position = util.moveposition(e.position, util.offset(directions[loader_index], 0, -1.5))
      e.direction = util.orthogonal_direction(directions[loader_index])
      loader_index = loader_index + 1
    elseif e.name == "railunloader-chest" then
      e.name = "railunloader-placement-proxy"
      e.position = util.moveposition(e.position, util.offset(directions[loader_index], 0, -1.5))
      e.direction = util.orthogonal_direction(directions[loader_index])
      loader_index = loader_index + 1
    end
  end

  bp.set_blueprint_entities(entities)
end

local function on_marked_for_deconstruction(event, cancel)
  local entity = event.entity
  local type = util.railloader_type(entity)
  if not type then
    return
  end
  local rails = entity.surface.find_entities_filtered{
    type = "straight-rail",
    area = entity.bounding_box,
  }
  for _, rail in ipairs(rails) do
    rail.minable = not cancel
    rail.order_deconstruction(entity.force)
  end
end

local function on_canceled_deconstruction(event)
  on_marked_for_deconstruction(event, true)
end

local function on_setting_changed(event)
  allowed_items_setting = settings.global["railloader-allowed-items"].value
  inserter_config.on_setting_changed(event)
end

-- setup event handlers

script.on_init(on_init)
script.on_load(on_load)
script.on_configuration_changed(on_configuration_changed)

script.on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity}, on_built)
script.on_event({defines.events.on_player_mined_entity, defines.events.on_robot_mined_entity}, on_mined)
script.on_event(defines.events.on_entity_died, on_mined)
script.on_event(defines.events.on_player_setup_blueprint, on_blueprint)
script.on_event(defines.events.on_marked_for_deconstruction, on_marked_for_deconstruction)
script.on_event(defines.events.on_canceled_deconstruction, on_canceled_deconstruction)
script.on_event(defines.events.on_train_changed_state, inserter_config.on_train_changed_state)

script.on_event(defines.events.on_runtime_mod_setting_changed, on_setting_changed)
