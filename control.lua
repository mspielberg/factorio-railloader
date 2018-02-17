local configchange = require "configchange"
local inserter_config = require "inserterconfig"
local util = require "util"

-- constants

local num_inserters = 2

local train_types = {
  ["locomotive"] = true,
  ["cargo-wagon"] = true,
  ["fluid-wagon"] = true,
}

local allowed_items_setting = settings.global["railloader-allowed-items"].value

local function on_init()
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

local function abort_build(event)
  local entity = event.created_entity
  local item_name = next(entity.prototype.items_to_place_this)
  if event.player_index then
    local player = game.players[event.player_index]
    local cursor = player.cursor_stack
    if event.revived or cursor.valid_for_read and cursor.name == item_name then
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
    local last_user = entity.last_user
    if last_user and last_user.valid then
      ghost.last_user = last_user
      last_user.add_custom_alert(ghost, {type="item", name=item_name}, {"railloader.invalid-construction-site"}, true)
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

local function create_entities(proxy, rail)
  local type = util.railloader_type(proxy)
  local surface = proxy.surface
  local direction = proxy.direction
  local position = util.moveposition(proxy.position, util.offset(direction, 1.5, 0))
  local force = proxy.force
  local last_user = proxy.last_user

  -- center over the rail
  local rail_direction = rail.direction
  if rail_direction == defines.direction.north then
    position.x = rail.position.x
  else
    position.y = rail.position.y
  end

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

  -- place cargo wagon inserters
  local inserter_name =
    "rail" .. type .. (allowed_items_setting == "any" and "-universal" or "") .. "-inserter"
  for i=1,num_inserters do
    local inserter = surface.create_entity{
      name = inserter_name,
      position = position,
      direction = rail_direction,
      force = force,
    }
    inserter.destructible = false
    inserter.last_user = last_user
  end
  inserter_config.configure_or_register_loader(chest)

  -- place structure
  local structure_name = "rail" .. type .. "-structure-horizontal"
  if rail.direction == defines.direction.north then
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
  local force = proxy.force

  -- check that rail is in the correct place
  local rail = surface.find_entities_filtered{
    area = util.box_centered_at(position, 0.6),
    type = "straight-rail",
  }[1]
  if not rail then
    abort_build(event)
    return
  end

  local rail_direction = rail.direction

  -- check that the opposite side is also free
  local opposite_side_clear = surface.can_place_entity{
    name = proxy.name,
    position = util.moveposition(proxy.position, util.offset(direction, 3, 0)),
    direction = direction,
    force = force,
  }
  if not opposite_side_clear then
    abort_build(event)
    return
  end

  create_entities(proxy, rail)

  proxy.destroy()
end

local function on_container_built(entity)
  for _, loader in ipairs(util.find_railloaders_from_chest(entity)) do
    sync_interface_inserters(loader)
  end
end

local function on_built(event)
  local entity = event.created_entity
  local type = string.match(entity.name, "^rail(u?n?loader)%-placement%-proxy$")
  if type then
    return on_railloader_proxy_built(entity, event)
  elseif entity.type == "container" then
    return on_container_built(entity)
  end
end

local function on_railloader_mined(entity, buffer)
  local position = entity.position
  local entities = entity.surface.find_entities_filtered{
    area = entity.bounding_box,
  }
  for _, ent in ipairs(entities) do
    if ent.type == "inserter" then
      if buffer then
        buffer.insert(ent.held_stack)
      end
      ent.destroy()
    elseif string.find(ent.name, "^railu?n?loader%-structure") then
      ent.destroy()
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
script.on_event(defines.events.on_train_changed_state, inserter_config.on_train_changed_state)

script.on_event(defines.events.on_runtime_mod_setting_changed, on_setting_changed)
