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


local function on_selected_area(event)
  game.print(serpent.line(event))
  if event.item ~= "railloader" then
    return
  end
  if #event.entities ~= 1 or event.entities[1].name ~= "straight-rail" then
    return
  end
  local rail = event.entities[1]
  local colliding_railloaders = rail.surface.find_entities_filtered{
    area = util.move_box(rail.prototype.collision_box, rail.position),
    type = "container",
  }
  if next(colliding_railloaders) then
    game.print("overlapping railloader entity")
    return
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
  local player = game.players[event.player_index]
  player.cursor_stack.count = player.cursor_stack.count - 1
end

script.on_event(defines.events.on_player_selected_area, on_selected_area)