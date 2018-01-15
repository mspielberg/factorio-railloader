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
      local player = game.players[event.player_index]
      if player.cursor_stack.valid_for_read then
        player.cursor_stack.count = player.cursor_stack.count + 1
      else
        player.cursor_stack.set_stack{name = "railloader-proxy", count = 1}
      end
end

local function on_built(event)
  local entity = event.created_entity
  if entity.name ~= "railloader-proxy" then
    return
  end
  game.print(serpent.line(event))
  local rail = entity.surface.find_entities_filtered{
    position = entity.position,
    type = "straight-rail",
    force = entity.force,
  }[1]
  entity.destroy()

  if not rail then
    game.print("no rail found")
    abort_build(event)
    return
  end

  local colliding_entities = rail.surface.find_entities_filtered{
    area = util.move_box(game.entity_prototypes["railloader"].collision_box, rail.position),
  }
  for _, e in ipairs(colliding_entities) do
    if e.type ~= "straight-rail" and e.name ~= "railloader-proxy" then
      game.print("overlapping entity: ".. e.type)
      abort_build(event)
      return
    end
  end
  rail.surface.create_entity{
    name = "railloader",
    position = rail.position,
    force = rail.force,
  }
  rail.surface.create_entity{
    name = "railloader-inserter",
    position = rail.position,
    direction = rail.direction,
    force = rail.force,
  }
end

local function on_blueprint(event)
  local player = game.players[event.player_index]
  local bp = player.blueprint_to_setup
  local entities = bp.get_blueprint_entities()
  for _, e in ipairs(entities) do
    if e.name == "railloader" then
      e.name = "railloader-proxy"
    end
  end
  bp.set_blueprint_entities(entities)
end

script.on_event(defines.events.on_built_entity, on_built)
script.on_event(defines.events.on_player_setup_blueprint, on_blueprint)