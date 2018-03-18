local Event = require "event"

local M = {}

--[[
  global.ghost_connections = {
    [position_key] = {
      [defines.wire_type.green] = {
        {x=..., y=...},
        ...
      },
      [defines.wire_type.red] = {
        ...
      }
    }
  }
  ]]

local function is_setup_bp(stack)
  return stack.valid and
    stack.valid_for_read and
    stack.is_blueprint and
    stack.is_blueprint_setup()
end

local function bp_to_world(position, direction)
  return function(bp_position)
    local world_offset
    if direction == defines.direction.north then
      world_offset = bp_position
    elseif direction == defines.direction.east then
      world_offset = { x = -bp_position.y, y = bp_position.x }
    elseif direction == defines.direction.south then
      world_offset = { x = -bp_position.x, y = -bp_position.y }
    elseif direction == defines.direction.west then
      world_offset = { x = bp_position.y, y = -bp_position.x }
    else
      error("invalid direction passed to bp_to_world")
    end
    return { x = position.x + world_offset.x, y = position.y + world_offset.y }
  end
end

local function position_key(surface, position)
  return surface.name .. "@" .. position.x .. "," .. position.y
end

local function on_put_item(event)
  local player = game.players[event.player_index]
  if not is_setup_bp(player.cursor_stack) then
    return
  end
  if not global.ghost_connections then
    global.ghost_connections = {}
  end
  local bp = player.cursor_stack
  local translate = bp_to_world(event.position, event.direction)
  local entities = bp.get_blueprint_entities()
  if not entities then
    return
  end
  for _, e in ipairs(bp.get_blueprint_entities()) do
    if e.connections then
      local key = position_key(player.surface, e.position)
      local t = {}
      global.ghost_connections[key] = t
      for source_circuit_id, wires in pairs(e.connections) do
        for wire_name, conns in pairs(wires) do
          for _, conn in ipairs(conns) do
            t[#t+1] = {
              wire = defines.wire_type[wire_name],
              target_entity_name = entities[conn.entity_id].name,
              target_entity_position = translate(entities[conn.entity_id].position),
              source_circuit_id = source_circuit_id,
              target_circuit_id = conn.circuit_id,
            }
          end
        end
      end
    end
  end
end

function M.get_connections(ghost)
  local conns = global.ghost_connections[position_key(ghost.surface, ghost)]
  if not conns then
    return {}
  end
  local out = {}
  for _, conn in ipairs(conns) do
    out[#out+1] = conn
    conn.target_entity = ghost.surface.find_entity(conn.target_entity_name, conn.target_entity_position)
  end
  return out
end

Event.register(defines.events.on_put_item, on_put_item)

return M
