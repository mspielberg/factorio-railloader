local bulk = require "bulk"
local util = require "util"

local M = {}

local INTERVAL = 60

local allowed_items_setting = settings.global["railloader-allowed-items"].value
local show_configuration_messages_setting = settings.global["railloader-show-configuration-messages"].value

local on_tick -- forward reference

local function register_inserter(inserter)
  if not util.is_filter_inserter(inserter) then
    return
  end
  local t = global.unconfigured_inserters
  t[#t+1] = inserter
  -- reset iterator after adding a new item
  global.unconfigured_inserters_iter = nil
  script.on_event(defines.events.on_tick, on_tick)
end

local function unregister_inserter(inserter)
  for i, e in ipairs(global.unconfigured_inserters) do
    if e.valid and e.unit_number == inserter.unit_number then
      table.remove(global.unconfigured_inserters, i)
      return
    end
  end
end

local function display_configuration_message(inserter, items)
  if not next(items) then
    return
  end
  local type = "railloader"
  if inserter.name == "railunloader-inserter" then
    type = "railunloader"
  end
  local msg = {"railloader." .. type .. "-configured-" .. #items}
  for i, item in ipairs(items) do
    msg[i+1] = {"item-name." .. items[i]}
  end
  inserter.surface.create_entity{
    name = "flying-text",
    position = inserter.position,
    text = msg,
  }
end

local function inserter_configuration_changes(inserter, items)
  local item_set = {}
  for i,v in ipairs(items) do
    item_set[v] = true
  end

  for i=1,5 do
    local filter = inserter.get_filter(i)
    if filter then
      if not item_set[filter] then
        -- existing filter will be removed
        return true
      end
      item_set[filter] = nil
    end
  end

  -- check if new filter(s) will be added
  return next(item_set) ~= nil
end

local function configure_inserter_from_inventory(inserter, inventory)
  local items = bulk.acceptable_items(inventory, 5)
  if not next(items) then
    return false
  end

  if show_configuration_messages_setting and inserter_configuration_changes(inserter, items) then
    display_configuration_message(inserter, items)
  end

  for i=1,5 do
    inserter.set_filter(i, items[i])
  end

  unregister_inserter(inserter)

  return true
end

local function configure_inserter(inserter)
  local inventory
  if inserter.name == "railloader-inserter" then
    local chest = inserter.surface.find_entity("railloader-chest", inserter.position)
    if chest then
      inventory = chest.get_inventory(defines.inventory.chest)
    end
  elseif inserter.name == "railunloader-inserter" then
    local wagon = inserter.surface.find_entities_filtered{
      type = "cargo-wagon",
      area = util.box_centered_at(inserter.position, 0.6),
      force = inserter.force,
    }[1]
    if wagon then
      inventory = wagon.get_inventory(defines.inventory.cargo_wagon)
    end
  end
  if inventory then
    return configure_inserter_from_inventory(inserter, inventory)
  end
  return false
end

function M.on_train_changed_state(event)
  if allowed_items_setting == "any" then
    return
  end

  local train = event.train
  if train.state ~= defines.train_state.wait_station then
    return
  end
  for _, wagon in ipairs(train.cargo_wagons) do
    local inserter = wagon.surface.find_entities_filtered{
      type = "inserter",
      area = util.box_centered_at(wagon.position, 0.6),
    }[1]
    if inserter then
      M.configure_or_register_inserter(inserter)
    end
  end
end

on_tick = function(event)
  if event.tick % INTERVAL ~= 0 then
    return
  end

  local inserter
  global.unconfigured_inserters_iter, inserter = next(global.unconfigured_inserters, global.unconfigured_inserters_iter)
  if not global.unconfigured_inserters_iter then
    if not next(global.unconfigured_inserters) then
      script.on_event(defines.events.on_tick, nil)
    end
    return
  end
  if not inserter.valid or not util.is_filter_inserter(inserter) then
    table.remove(global.unconfigured_inserters, global.unconfigured_inserters_iter)
    return
  end
  configure_inserter(inserter)
end

function M.on_init()
  global.unconfigured_inserters = {}
end

function M.on_load()
  if next(global.unconfigured_inserters) then
    script.on_event(defines.events.on_tick, on_tick)
  end
end

function M.configure_or_register_inserter(inserter)
  if not util.is_filter_inserter(inserter) then
    return
  end
  local success = configure_inserter(inserter)
  if not success then
    unregister_inserter(inserter)
    register_inserter(inserter)
  end
end

local function replace_all_inserters(universal)
  local from_qualifier = universal and "" or "-universal"
  local to_qualifier = universal and "-universal" or ""

  for _, s in pairs(game.surfaces) do
    for _, type in ipairs{"railloader", "railunloader"} do
      local to_match = type .. from_qualifier .. "-inserter"
      local replace_with = type .. to_qualifier .. "-inserter"
      for _, e in ipairs(s.find_entities_filtered{name=to_match}) do
        local replacement = s.create_entity{
          name = replace_with,
          position = e.position,
          direction = e.direction,
          force = e.force,
        }
        replacement.destructible = false
        replacement.last_user = e.last_user
        replacement.held_stack.swap_stack(e.held_stack)
        if not universal then
          register_inserter(replacement)
        end
        e.destroy()
      end
    end
  end
end

function M.on_setting_changed(event)
  if event.setting == "railloader-allowed-items" then
    local new_value = settings.global["railloader-allowed-items"].value
    if new_value == "any" and allowed_items_setting ~= "any" then
      replace_all_inserters(true)
    elseif new_value ~= "any" and allowed_items_setting == "any" then
      replace_all_inserters(false)
    end
    allowed_items_setting = new_value
    bulk.on_setting_changed()
  elseif event.setting == "railloader-show-configuration-messages" then
    show_configuration_messages_setting = settings.global["railloader-show-configuration-messages"].value
  end
end

return M