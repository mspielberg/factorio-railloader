local Event = require "Event"

-- Entity Queue
-- executes a task periodically for a set of entities,
-- inspecting only one entity per tick
local M = {}

function M:register(entity)
  global[self.name][entity.unit_number] = entity
  Event.register_nth_tick(self.interval, self.on_tick)
end

function M:unregister(entity, key)
  local queue = global[self.name]
  if not key then
    key = entity.unit_number
  end
  queue[key] = nil
  if not next(queue) then
    Event.unregister_nth_tick(self.interval, self.on_tick)
  end
end

function M:on_init()
  global[self.name] = {}
end

function M:on_load()
  if global[self.name] and next(global[self.name]) then
    Event.register(self.interval, self.on_tick)
  end
end

local function create_on_tick(self)
  self.on_tick = function()
    local queue = global[self.name]
    local iter_name = self.iter_name
    local k, v
    repeat
      k, v = next(queue, global[iter_name])
      if not k then
        -- start again at beginning of iteration
        k, v = next(queue)
        if not k then
          -- table is empty
          Event.unregister_nth_tick(self.interval, self.on_tick)
          return
        end
      end
      global[iter_name] = k
      if not v.valid then
        self:unregister(v)
      end
    until k and v and v.valid
    self.task(self, k, v)
  end
end

function M.new(name, interval, task)
  local self = {
    name = name,
    iter_name = name .. "_iter",
    interval = interval,
    task = task,
  }
  create_on_tick(self)

  local meta = {
    __index = M,
    __call = M.new,
  }
  return setmetatable(self, meta)
end

return M