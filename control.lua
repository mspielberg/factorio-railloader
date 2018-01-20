local bulk = require "bulk"
local util = require "util"

-- constants

local train_types = {
  ["locomotive"] = true,
  ["cargo-wagon"] = true,
  ["fluid-wagon"] = true,
}

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

  -- check that rail is in the correct place
  local rail = surface.find_entities_filtered{
    area = util.box_centered_at(position, 0.5),
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

  entity.destroy()

  -- place chest
  surface.create_entity{
    name = "rail" .. type .. "-chest",
    position = position,
    force = force,
  }

  -- place inserter
  local inserter_direction = defines.direction.north
  if direction == defines.direction.north or direction == defines.direction.south then
    inserter_direction = defines.direction.east
  end
  local inserter = surface.create_entity{
    name = "rail" .. type .. "-inserter",
    position = position,
    direction = inserter_direction,
    force = force,
  }
  inserter.destructible = false

  -- place structure
  if type == "loader" then
    local placed = surface.create_entity{
      name = "railloader-structure",
      position = position,
      force = force,
    }
    placed.destructible = false
  end
end

local function on_mined(event)
  local entity = event.entity
  local type = string.match(entity.name, "^rail(.*)%-chest$")
  if not type then
    return
  end

  local inserter_name = "rail" .. type .. "-inserter"

  local entities = entity.surface.find_entities_filtered{
    area = entity.bounding_box,
  }
  for _, ent in ipairs(entities) do
    if ent.name == inserter_name then
      if event.buffer then
        event.buffer.insert(ent.held_stack)
      end
      ent.destroy()
    elseif ent.name == "railloader-structure" then
      ent.destroy()
    end
  end
end

local function on_blueprint(event)
  local player = game.players[event.player_index]
  local bp = player.blueprint_to_setup
  if event.alt then
    bp = player.cursor_stack
  end

  -- find bp center coordinate

  -- find (un)loaders and their directions
  local containers = player.surface.find_entities_filtered{
    area = event.area,
    type = "container",
  }
  local directions = {}
  for _, container in ipairs(containers) do
    if container.name == "railloader-chest" or container.name == "railunloader-chest" then
      local rail = player.surface.find_entities_filtered{
        name = "straight-rail",
        area = util.box_centered_at(container.position, 0.6),
      }[1]
      if rail then
        directions[#directions+1] = rail.directio
      end
    end
  end

  local entities = bp.get_blueprint_entities()
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

local function enable_inserter(inserter, wagon)
  local inventory = wagon.get_inventory(defines.inventory.cargo_wagon)
  if inserter.name == "railloader-inserter" then
    local chest = inserter.surface.find_entity("railloader-chest", inserter.position)
    inventory = chest.get_inventory(defines.inventory.chest)
  end
  local item = bulk.first_acceptable_item(inventory)
  inserter.set_filter(1, item)
end

local function disable_inserter(inserter)
  inserter.set_filter(1, nil)
end

local function on_train_changed_state(event)
  local train = event.train
  for _, wagon in ipairs(train.cargo_wagons) do
    local inserter = wagon.surface.find_entities_filtered{
      type = "inserter",
      area = util.box_centered_at(wagon.position, 0.5),
    }[1]
    if inserter then
      if train.state == defines.train_state.wait_station then
        enable_inserter(inserter, wagon)
      else
        disable_inserter(inserter)
      end
    end
  end
end

script.on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity}, on_built)
script.on_event({defines.events.on_player_mined_entity, defines.events.on_robot_mined_entity}, on_mined)
script.on_event(defines.events.on_entity_died, on_mined)
script.on_event(defines.events.on_player_setup_blueprint, on_blueprint)
script.on_event(defines.events.on_train_changed_state, on_train_changed_state)