local M = {}

function M.on_init()
  global.entities_to_destroy = {}
end

local function on_tick(_)
  local new_iter, entity = next(global.entities_to_destroy, global.entities_to_destroy_iter)
  global.entities_to_destroy_iter = new_iter
  if entity then
    entity.destroy()
  end
  if not new_iter and not next(global.entities_to_destroy) then
    script.on_event(defines.events.on_tick, nil)
  end
end

function M.register_to_destroy(entity)
  local t = global.entities_to_destroy
  if not t then
    global.entities_to_destroy = {}
    t = global.entities_to_destroy
  end
  t[#t+1] = entity
  global.entities_to_destroy_iter = nil
  script.on_event(defines.events.on_tick, on_tick)
end

return M