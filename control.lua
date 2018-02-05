local inserter_config = require "inserterconfig"
local util = require "util"

-- constants

local train_types = {
  ["locomotive"] = true,
  ["cargo-wagon"] = true,
  ["fluid-wagon"] = true,
}

local allowed_items_setting = settings.global["railloader-allowed-items"].value

local function on_init()
  inserter_config.on_init()
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

local function on_built(event)
  local entity = event.created_entity
  local type = string.match(entity.name, "^rail(.*)%-placement%-proxy$")
  if not type then
    return
  end

  local surface = entity.surface
  local direction = entity.direction
  local position = util.moveposition(entity.position, util.offset(direction, 1.5, 0))
  local force = entity.force
  local last_user = entity.last_user

  -- check that rail is in the correct place
  local rail = surface.find_entities_filtered{
    area = util.box_centered_at(position, 0.6),
    type = "straight-rail",
  }[1]
  if not rail then
    abort_build(event)
    return
  end

  -- check that the opposite side is also free
  local opposite_side_clear = surface.can_place_entity{
    name = entity.name,
    position = util.moveposition(entity.position, util.offset(direction, 3, 0)),
    direction = direction,
    force = force,
  }
  if not opposite_side_clear then
    abort_build(event)
    return
  end

  -- center over the rail
  if rail.direction == defines.direction.north then
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
  for _, ccd in ipairs(entity.circuit_connection_definitions) do
    chest.connect_neighbour(ccd)
  end

  -- place inserter
  local inserter_name =
    "rail" .. type .. (allowed_items_setting == "any" and "-universal" or "") .. "-inserter"
  local inserter_direction = defines.direction.north
  if direction == defines.direction.north or direction == defines.direction.south then
    inserter_direction = defines.direction.east
  end
  local inserter = surface.create_entity{
    name = inserter_name,
    position = position,
    direction = inserter_direction,
    force = force,
  }
  inserter.destructible = false
  inserter.last_user = last_user

  inserter_config.register_inserter(inserter)

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

  entity.destroy()
end

local function on_mined(event)
  local entity = event.entity
  local type = string.match(entity.name, "^rail(.*)%-chest$")
  if not type then
    return
  end

  local entities = entity.surface.find_entities_filtered{
    area = entity.bounding_box,
  }
  for _, ent in ipairs(entities) do
    if ent.type == "inserter" then
      if event.buffer then
        event.buffer.insert(ent.held_stack)
      end
      ent.destroy()
    elseif string.find(ent.name, "^railu?n?loader%-structure") then
      ent.destroy()
    end
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
        name = "straight-rail",
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

script.on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity}, on_built)
script.on_event({defines.events.on_player_mined_entity, defines.events.on_robot_mined_entity}, on_mined)
script.on_event(defines.events.on_entity_died, on_mined)
script.on_event(defines.events.on_player_setup_blueprint, on_blueprint)
script.on_event(defines.events.on_train_changed_state, inserter_config.on_train_changed_state)

script.on_event(defines.events.on_runtime_mod_setting_changed, on_setting_changed)