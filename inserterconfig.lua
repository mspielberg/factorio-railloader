local bulk = require "bulk"
local util = require "util"

local M = {}

local INTERVAL = 60

local allowed_items_setting = settings.global["railloader-allowed-items"].value
local show_configuration_messages_setting = settings.global["railloader-show-configuration-messages"].value

local on_tick -- forward reference

local function register_loader(loader)
  if allowed_items_setting == "any" then
    return
  end
  local t = global.unconfigured_loaders
  t[#t+1] = loader
  -- reset iterator after adding a new item
  global.unconfigured_loaders_iter = nil
  script.on_event(defines.events.on_tick, on_tick)
end

local function unregister_loader(loader)
  for i, e in ipairs(global.unconfigured_loaders) do
    if e.valid and e.unit_number == loader.unit_number then
      table.remove(global.unconfigured_loaders, i)
      return
    end
  end
end

local function display_configuration_message(loader, items)
  if not next(items) then
    return
  end
  local type = "railloader"
  if loader.name == "railunloader-chest" then
    type = "railunloader"
  end
  local msg = {"railloader." .. type .. "-configured-" .. #items}
  for i, item in ipairs(items) do
    msg[i+1] = {"item-name." .. item}
  end
  loader.surface.create_entity{
    name = "flying-text",
    position = loader.position,
    text = msg,
  }
end

local function inserter_configuration_changes(inserter, items)
  local item_set = {}
  for _, v in ipairs(items) do
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

local function configure_loader_from_inventory(loader, inventory)
  local items = bulk.acceptable_items(inventory, 5)
  if not next(items) then
    return false
  end

  local inserters = util.railloader_filter_inserters(loader)
  if not next(inserters) then
    return true
  end

  if show_configuration_messages_setting and inserter_configuration_changes(inserters[1], items) then
    display_configuration_message(loader, items)
  end

  for _, inserter in ipairs(inserters) do
    for i=1,5 do
      inserter.set_filter(i, items[i])
    end
  end

  return true
end

local function configure_loader(loader)
  local inventory = loader.get_inventory(defines.inventory.chest)
  if loader.name == "railunloader-chest" then
    local wagon = loader.surface.find_entities_filtered{
      type = "cargo-wagon",
      area = util.box_centered_at(loader.position, 0.6),
      force = loader.force,
    }[1]
    if wagon then
      inventory = wagon.get_inventory(defines.inventory.cargo_wagon)
    end
  end
  if inventory then
    return configure_loader_from_inventory(loader, inventory)
  end
  return false
end

function M.on_train_changed_state(event)
  if allowed_items_setting == "any" then
    return
  end

  local train = event.train
  if train.state ~= defines.train_state.wait_station and
    event.old_state ~= defines.train_state.wait_station then
    return
  end
  for _, wagon in ipairs(train.cargo_wagons) do
    local loader = wagon.surface.find_entities_filtered{
      type = "container",
      area = util.box_centered_at(wagon.position, 0.6),
    }[1]
    if loader and train.state == defines.train_state_wait_station then
      M.configure_or_register_loader(loader)
    else
      unregister_loader(loader)
    end
  end
end

on_tick = function(event)
  if event.tick % INTERVAL ~= 0 then
    return
  end

  local loader
  global.unconfigured_loaders_iter, loader = next(global.unconfigured_loaders, global.unconfigured_loaders_iter)
  if not global.unconfigured_loaders_iter then
    if not next(global.unconfigured_loaders) then
      script.on_event(defines.events.on_tick, nil)
    end
    return
  end
  if not loader.valid then
    table.remove(global.unconfigured_loaders, global.unconfigured_loaders_iter)
    return
  end
  local success = configure_loader(loader)
  if success then
    unregister_loader(loader)
  end
end

function M.on_init()
  global.unconfigured_loaders = {}
end

function M.on_load()
  if global.unconfigured_loaders and next(global.unconfigured_loaders) then
    script.on_event(defines.events.on_tick, on_tick)
  end
end

function M.configure_or_register_loader(loader)
  unregister_loader(loader)
  local success = configure_loader(loader)
  if not success then
    register_loader(loader)
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
        replacement.held_stack.swap_stack(e.held_stack)
        if not universal then
          local loader = replacement.surface.find_entity(type .. "-chest", e.position)
          if not loader then error("no loader found") end
          register_loader(loader)
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
      allowed_items_setting = new_value
      replace_all_inserters(true)
    elseif new_value ~= "any" and allowed_items_setting == "any" then
      allowed_items_setting = new_value
      replace_all_inserters(false)
    end
    bulk.on_setting_changed()
  elseif event.setting == "railloader-show-configuration-messages" then
    show_configuration_messages_setting = settings.global["railloader-show-configuration-messages"].value
  end
end

return M