local bulk = require "bulk"
local util = require "util"

local M = {}

local INTERVAL = 60

local unconfigured_inserters_iter

local function configure_inserter_from_inventory(inserter, inventory)
  local item = bulk.first_acceptable_item(inventory)
  if item then
    inserter.set_filter(1, item)

    local type = "railloader"
    if inserter.name == "railunloader-inserter" then
      type = "railunloader"
    end
    local msg = {"railloader." .. type .. "-configured", {"item-name." .. item}}
    local last_user = inserter.last_user
    if last_user then
      if last_user.connected then
        last_user.print(msg)
      else
        last_user.force.print(msg)
      end
    end

    for i, e in ipairs(global.unconfigured_inserters) do
      if e.unit_number == inserter.unit_number then
        table.remove(global.unconfigured_inserters, i)
        return
      end
    end
  end
end

local function configure_inserter(inserter)
  local inventory
  if inserter.name == "railloader-inserter" then
    local chest = inserter.surface.find_entity("railloader-chest", inserter.position)
    if chest then
      inventory = chest.get_inventory(defines.inventory.chest)
    end
  else
    local wagon = inserter.surface.find_entities_filtered{
      type = "cargo-wagon",
      area = util.box_centered_at(inserter.position, 0.5),
      force = inserter.force,
    }[1]
    if wagon then
      inventory = wagon.get_inventory(defines.inventory.cargo_wagon)
    end
  end
  if inventory then
    configure_inserter_from_inventory(inserter, inventory)
  end
end

function M.on_train_changed_state(event)
  local train = event.train
  if train.state ~= defines.train_state.wait_station then
    return
  end
  for _, wagon in ipairs(train.cargo_wagons) do
    local inserter = wagon.surface.find_entities_filtered{
      type = "inserter",
      area = util.box_centered_at(wagon.position, 0.5),
    }[1]
    if inserter and inserter.get_filter(1) == nil then
      configure_inserter(inserter)
    end
  end
end

function M.on_tick(event)
  if event.tick % INTERVAL ~= 0 then
    return
  end

  local inserter
  unconfigured_inserters_iter, inserter = next(global.unconfigured_inserters, unconfigured_inserters_iter)
  if not unconfigured_inserters_iter then
    if not next(global.unconfigured_inserters) then
      script.on_event(defines.events.on_tick, nil)
    end
    return
  end
  if not inserter.valid then
    game.print("removing invalid inserter reference")
    table.remove(global.unconfigured_inserters, unconfigured_inserters_iter)
    return
  end
  configure_inserter(inserter)
end

function M.on_init()
  global.unconfigured_inserters = {}
end

function M.register_inserter(inserter)
  local t = global.unconfigured_inserters
  t[#t+1] = inserter
  -- reset iterator after adding a new item
  unconfigured_inserters_iter = nil
  script.on_event(defines.events.on_tick, M.on_tick)
end

return M