local EntityQueue = require "EntityQueue"

local M = {}

local INTERVAL = 10

local function task(q, key, entity)
  if entity.destroy() then
    q:unregister(entity, key)
  end
end

local q = EntityQueue.new("entities_to_destroy", INTERVAL, task)

function M.on_init()
  q:on_init()
end

function M.on_load()
  q:on_load()
end

function M.register_to_destroy(entity)
  q:register(entity)
end

return M