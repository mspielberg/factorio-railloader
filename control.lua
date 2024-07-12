local bulk = require "bulk"
local configchange = require "configchange"
local delaydestroy = require "delaydestroy"
local ghostconnections = require "ghostconnections"
local inserter_config = require "inserterconfig"
local util = require "util"

-- constants

local num_inserters = 2

local allowed_items_setting = settings.global["railloader-allowed-items"].value

local function on_init()
  global.previous_opened_blueprint_for = {}
  delaydestroy.on_init()
  inserter_config.on_init()
end

local function on_load()
  delaydestroy.on_load()
  inserter_config.on_load()
end

local function on_configuration_changed(configuration_changed_data)
  local mod_change = configuration_changed_data.mod_changes["railloader"]
  if mod_change and mod_change.old_version and mod_change.old_version ~= mod_change.new_version then
    configchange.on_mod_version_changed(mod_change.old_version)
  end
end

local function show_error(entity)
  entity.surface.create_entity{
    name = "flying-text",
    position = entity.position,
    text = {"railloader.invalid-position"},
  }
end

local function abort_build(event)
  local entity = event.created_entity or event.entity
  show_error(entity)
  if event.player_index then
    local player = game.players[event.player_index]
    player.mine_entity(entity, true)
  else
    entity.order_deconstruction(entity.force)
  end
end

local function sync_interface_inserters(loader)
  local type = util.railloader_type(loader.name)
  local interface_chests = util.find_chests_from_railloader(loader)
  for _, interface_chest in ipairs(interface_chests) do
    local inserter = util.find_inserter_for_interface(loader, interface_chest)
    if not inserter then
      local main_chest_position = util.loader_position_for_interface(loader, interface_chest)
      inserter = loader.surface.create_entity{
        name = util.interface_inserter_name_for_loader(loader),
        position = loader.position,
        force = loader.force,
      }
      inserter.destructible = false
      inserter.pickup_position = type == "loader" and interface_chest.position or main_chest_position
      inserter.drop_position = type == "unloader" and interface_chest.position or main_chest_position
      inserter.direction = inserter.direction
      inserter_config.connect_and_configure_inserter_control_behavior(inserter, loader)
    end
  end
end

local function remove_interface_inserter(loader, chest, buffer)
  local inserter = util.find_inserter_for_interface(loader, chest)
  if inserter then
    util.insert_or_spill(loader, inserter.held_stack, {loader.get_inventory(defines.inventory.chest), buffer})
    inserter.destroy()
  end
end

local function rail_positions(proxy)
  local direction = proxy.direction
  local position = proxy.position

  if direction == defines.direction.north or direction == defines.direction.south then
    if position.x % 2 ~= 1 then
      return nil
    end
    if position.y % 2 == 1 then
      return {
        util.moveposition(position, {x = 0, y = -2}),
        position,
        util.moveposition(position, {x = 0, y =  2}),
      }
    else
      return {
        util.moveposition(position, {x = 0, y = -1}),
        util.moveposition(position, {x = 0, y =  1}),
      }
    end
  else
    if position.y % 2 ~= 1 then
      return nil
    end
    if position.x % 2 == 1 then
      return {
        util.moveposition(position, {x = -2, y = 0}),
        position,
        util.moveposition(position, {x =  2, y = 0}),
      }
    else
      return {
        util.moveposition(position, {x = -1, y = 0}),
        util.moveposition(position, {x =  1, y = 0}),
      }
    end
  end
end

local function create_entities(proxy, tags, rail_poss)
  local type = util.railloader_type(proxy.name)
  local surface = proxy.surface
  local direction = proxy.direction
  if direction >= 4 then
    direction = direction - 4
  end
  local position = proxy.position
  local force = proxy.force
  local last_user = proxy.last_user

  -- place rails
  for _, rail_position in ipairs(rail_poss) do
    local rail = surface.create_entity{
      name = "railloader-rail",
      position = rail_position,
      direction = direction,
      force = force,
    }
    rail.destructible = false
    rail.minable = false
  end

  -- place chest
  local chest = surface.create_entity{
    name = "rail" .. type .. "-chest",
    position = position,
    force = force,
  }
  chest.last_user = last_user
  if tags and tags.bar then
    chest.get_inventory(defines.inventory.chest).set_bar(tags.bar)
  end

  -- recreate circuit connections
  for _, ccd in ipairs(proxy.circuit_connection_definitions) do
    chest.connect_neighbour(ccd)
  end
  for _, ccd in ipairs(ghostconnections.get_connections(proxy)) do
    chest.connect_neighbour(ccd)
  end

  -- place cargo wagon inserters
  local inserter_name =
    "rail" .. type .. (allowed_items_setting == "any" and "-universal" or "") .. "-inserter"
  for i=1,num_inserters do
    -- alternate direction to support half-size wagons sticking out both sides of the (un)loader
    local inserter_direction = (direction + (i-1) * 4) % 8
    local inserter = surface.create_entity{
      name = inserter_name,
      position = position,
      direction = inserter_direction,
      force = force,
    }
    inserter.destructible = false
    inserter_config.connect_and_configure_inserter_control_behavior(inserter, chest)
  end

  inserter_config.configure_or_register_loader(chest)

  -- place structure
  local structure_name = "rail" .. type .. "-structure-vertical"
  if direction == defines.direction.east or direction == defines.direction.west then
    structure_name = "rail" .. type .. "-structure-horizontal"
  end
  local placed = surface.create_entity{
    name = structure_name,
    position = position,
    force = force,
  }
  placed.destructible = false

  -- place interface inserters for pre-existing chests
  sync_interface_inserters(chest)
end

local function on_railloader_proxy_built(event)
  local proxy = event.created_entity or event.entity
  local tags = event.tags
  local rail_pos = rail_positions(proxy)
  if not rail_pos then
    return abort_build(event)
  end
  create_entities(proxy, tags, rail_pos)
  proxy.destroy()
end

local function on_ghost_built(ghost)
  local rail_pos = rail_positions(ghost)
  if not rail_pos then
    show_error(ghost)
    ghost.destroy()
  end
end

local function on_container_built(entity)
  for _, loader in ipairs(util.find_railloaders_from_chest(entity)) do
    sync_interface_inserters(loader)
  end
end

local function on_built(event)
  local entity = event.created_entity or event.entity
  local type = util.railloader_type(entity.name)
  if type then
    return on_railloader_proxy_built(event)
  elseif entity.type == "entity-ghost" then
    type = util.railloader_type(entity.ghost_name)
    if type then
      return on_ghost_built(entity)
    end
  elseif string.find(entity.type, "container$") then
    return on_container_built(entity)
  end
end

local function on_railloader_mined(entity, buffer)
  local entities = entity.surface.find_entities_filtered{
    area = entity.bounding_box,
  }
  for _, ent in ipairs(entities) do
    if ent.type == "inserter" then
      if buffer and ent.held_stack.valid_for_read then
        buffer.insert(ent.held_stack)
      end
      ent.destroy()
    elseif string.find(ent.name, "^railu?n?loader%-structure") then
      ent.destroy()
    elseif ent.type == "straight-rail" then
      local success = ent.destroy()
      if not success then
        delaydestroy.register_to_destroy(ent)
      end
    end
  end
end

local function on_container_mined(entity, buffer)
  for _, loader in ipairs(util.find_railloaders_from_chest(entity)) do
    remove_interface_inserter(loader, entity, buffer)
  end
end

local died_direction

local function on_post_entity_died(event)
  local ghost = event.ghost
  if ghost then
    local loader_type = util.railloader_type(ghost.ghost_name)
    if loader_type then
      local new_ghost = ghost.surface.create_entity{
        name = "entity-ghost",
        inner_name = "rail" .. loader_type .. "-placement-proxy",
        force = ghost.force,
        direction = died_direction,
        position = ghost.position,
      }
      new_ghost.last_user = ghost.last_user
      ghost.destroy()
    end
  end
end

local function on_mined(event)
  local entity = event.entity
  local type = util.railloader_type(entity.name)
  if type then
    died_direction = util.loader_direction(entity)
    return on_railloader_mined(entity, event.buffer)
  elseif string.find(entity.type, "container$") then
    return on_container_mined(entity, event.buffer)
  end
end

local function on_robot_pre_mined(event)
  if event.instant_deconstruction then
    on_mined(event)
  end
end

local function on_gui_closed(event)
  if event.gui_type == defines.gui_type.item
  and event.item
  and event.item.is_blueprint
  and event.item.is_blueprint_setup()
  then
    global.previous_opened_blueprint_for[event.player_index] = {
      blueprint = event.item,
      tick = event.tick,
    }
  end
end

local function get_blueprint_to_setup(player_index)
  local opened_blueprint = global.previous_opened_blueprint_for[player_index]
  if opened_blueprint and opened_blueprint.tick == game.tick then
    return opened_blueprint.blueprint
  end

  local player = game.players[player_index]

  local blueprint_to_setup = player.blueprint_to_setup
  if blueprint_to_setup
  and blueprint_to_setup.valid_for_read then
    return blueprint_to_setup
  end

  local cursor_stack = player.cursor_stack
  if cursor_stack
  and cursor_stack.valid_for_read
  and cursor_stack.is_blueprint
  and cursor_stack.is_blueprint_setup() then
    return cursor_stack
  end
end

-- Function to find railloaders within a given area
local function find_railloaders_in_area(surface, area)
	-- Find and return all railloader-chest and railunloader-chest entities in the given area
	return surface.find_entities_filtered{
		area = area,
		name = {"railloader-chest", "railunloader-chest"}
	}
end

local function on_blueprint(event)
	local bp = get_blueprint_to_setup(event.player_index)
	if not bp then return end
	local player = game.players[event.player_index]
	local entities = bp.get_blueprint_entities()
	
	local railloader_chests = find_railloaders_in_area(player.surface, event.area)
	if not next(railloader_chests) then return end
	
	local chest_index = 1
	local update_bp = false
	for _, bp_entity in pairs(entities) do
		if bp_entity.name == "railloader-chest" or bp_entity.name == "railunloader-chest" then
			local chest_entity = railloader_chests[chest_index]
			chest_index = chest_index + 1
			
			local rail = player.surface.find_entities_filtered{
				type = "straight-rail",
				area = chest_entity.bounding_box,
			}[1]
			if rail then
				bp_entity.name = (bp_entity.name == "railloader-chest")
					and "railloader-placement-proxy"
					or "railunloader-placement-proxy"
				-- base direction on direction of rail
				bp_entity.direction = rail.direction
				-- preserve chest limit
				bp_entity.tags = { bar = chest_entity.get_inventory(defines.inventory.chest).get_bar() }
				update_bp = true
			end
		end
	end
	if update_bp then bp.set_blueprint_entities(entities) end
end

local function on_setting_changed(event)
  allowed_items_setting = settings.global["railloader-allowed-items"].value
  inserter_config.on_setting_changed(event)
end

-- setup remotes

remote.add_interface("railloader", {
  add_bulk_item = bulk.add_bulk_item,
  add_bulk_item_pattern = bulk.add_bulk_item_pattern,
})

-- setup event handlers

script.on_init(on_init)
script.on_load(on_load)
script.on_configuration_changed(on_configuration_changed)

local es = defines.events
script.on_event({es.on_built_entity, es.on_robot_built_entity, es.script_raised_built, es.script_raised_revive}, on_built)
script.on_event({es.on_player_mined_entity, es.on_robot_mined_entity, es.script_raised_destroy}, on_mined)
script.on_event(es.on_robot_pre_mined, on_robot_pre_mined)
script.on_event(es.on_entity_died, on_mined)
script.on_event(es.on_post_entity_died, on_post_entity_died, {{filter = "type", type = "container"}})

script.on_event(es.on_gui_closed, on_gui_closed)
script.on_event(es.on_player_setup_blueprint, on_blueprint)

script.on_event(es.on_train_changed_state, inserter_config.on_train_changed_state)

script.on_event(defines.events.on_runtime_mod_setting_changed, on_setting_changed)
