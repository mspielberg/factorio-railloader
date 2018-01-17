local util = {}

-- Position adjustments

function util.moveposition(position, offset)
	return {x=position.x + offset.x, y=position.y + offset.y}
end

function util.offset(direction, longitudinal, orthogonal)
	if direction == defines.direction.north then
		return {x=orthogonal, y=-longitudinal}
	end

	if direction == defines.direction.south then
		return {x=-orthogonal, y=longitudinal}
	end

	if direction == defines.direction.east then
		return {x=longitudinal, y=orthogonal}
	end

	if direction == defines.direction.west then
		return {x=-longitudinal, y=-orthogonal}
	end
end

function util.move_box(box, offset)
	return {
		left_top = util.moveposition(box.left_top, offset),
		right_bottom = util.moveposition(box.right_bottom, offset),
	}
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
  end
end

local function on_rail_ghost_built(event)
  local entity = event.created_entity
  local colliding = entity.surface.find_entities_filtered{
    area = util.move_box(entity.bounding_box, entity.position),
  }

  for _, other in ipairs(colliding) do
    if entity.ghost_name == "railloader-placement-proxy" and
        other.unit_number ~= entity.unit_number then
      -- placing railloader over other rails
      entity.destroy()
      return
    end
    if other.name == "railloader-rail" or
        other.name == "entity-ghost" and other.ghost_name == "railloader-placement-proxy" then
      -- placing other rails over railloader
      entity.destroy()
      return
    end
  end
end

local function on_built(event)
  local entity = event.created_entity
  if entity.name == "entity-ghost" and string.find(entity.ghost_type, "rail") then
    return on_rail_ghost_built(event)
  end
  if entity.name ~= "railloader-placement-proxy" then
    return
  end

  local surface = entity.surface
  local position = entity.position
  local direction = entity.direction
  local force = entity.force

  local colliding = surface.find_entities_filtered{
    area = util.move_box(entity.prototype.collision_box, position),
  }
  for _, other in ipairs(colliding) do
    if other.unit_number ~= entity.unit_number then
      abort_build(event)
      return
    end
  end

  entity.destroy()

  -- place rails
  for i=-1,1 do
    local placed = surface.create_entity{
      name = "railloader-rail",
      position = util.moveposition(position, util.offset(direction, i*2, 0)),
      direction = direction,
      force = force,
    }
  end

  -- place chest
  surface.create_entity{
    name = "railloader-chest",
    position = position,
    force = force,
  }

  -- place inserters
  surface.create_entity{
    name = "railloader-inserter",
    position = position,
    direction = direction,
    force = force,
  }

  -- place structure
  surface.create_entity{
    name = "railloader-structure",
    position = position,
    force = force,
  }
end

local function on_mined(event)
  local entity = event.entity
  if entity.name ~= "railloader-chest" then
    return
  end

  -- destroy rails
end

local function on_blueprint(event)
  local player = game.players[event.player_index]
  local bp = player.blueprint_to_setup
  if event.alt then
    bp = player.cursor_stack
  end
  local entities = bp.get_blueprint_entities()
  for i, e in ipairs(entities) do
    if e.name == "railloader-chest" then
      e.name = "railloader-proxy"
    elseif e.name == "railloader-rail" then
      entities[i] = nil
    end
  end
  bp.set_blueprint_entities(entities)
end

script.on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity}, on_built)
script.on_event({defines.events.on_player_mined_entity, defines.events.on_robot_mined_entity}, on_mined)
script.on_event(defines.events.on_player_setup_blueprint, on_blueprint)