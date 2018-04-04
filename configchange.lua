local inserter_config = require "inserterconfig"
local util = require "util"
local version = require "version"

local M = {}

local all_migrations = {}

local function add_migration(migration)
  all_migrations[#all_migrations+1] = migration
end

function M.on_mod_version_changed(old)
  old = version.parse(old)
  for _, migration in ipairs(all_migrations) do
    if version.between(old, migration.low, migration.high) then
      log("running world migration "..migration.name)
      migration.task()
    end
  end
end

add_migration{
  name = "v0_3_0_change_work_queue_name",
  low = {0,0,0},
  high = {0,3,0},
  task = function()
    global.unconfigured_loaders = {}
    local t = global.unconfigured_loaders
    for _, e in ipairs(global.unconfigured_inserters) do
      if e.valid then
        local loader = e.surface.find_entities_filtered{
          type = "container",
          position = e.position,
          force = e.force,
        }[1]
        t[#t+1] = loader
      end
    end
    global.unconfigured_inserters = nil
    global.unconfigured_inserters_iter = nil
    inserter_config.on_load()
  end,
}

add_migration{
  name = "v0_3_0_add_additional_inserters",
  low = {0,0,0},
  high = {0,3,0},
  task = function()
    for _, s in pairs(game.surfaces) do
      for _, e in ipairs(s.find_entities_filtered{type = "inserter"}) do
        if string.find(e.name, "railu?n?loader%-.*inserter") then
          local new_inserter = s.create_entity{
            name = e.name,
            position = e.position,
            direction = e.direction,
            force = e.force
          }
          new_inserter.destructible = false
          for i=1,e.filter_slot_count do
            new_inserter.set_filter(i, e.get_filter(i))
          end
        end
      end
    end
  end,
}

add_migration{
  name = "v0_3_7_add_ghost_registry",
  low = {0,0,0},
  high = {0,3,7},
  task = function()
    global.ghosts = {}
  end,
}

add_migration{
  name = "v0_4_0_add_delayed_destroy_queue",
  low = {0,0,0},
  high = {0,4,0},
  task = function()
    global.entities_to_destroy = {}
  end,
}

add_migration{
  name = "v0_4_0_change_unconfigured_loader_queue_indexing",
  low = {0,0,0},
  high = {0,4,0},
  task = function()
    local new = {}
    for _, v in pairs(global.unconfigured_loaders) do
      if v.valid then
        new[v.unit_number] = v
      end
    end
    global.unconfigured_loaders = new
    global.unconfigured_loaders_iter = nil
  end,
}

local function update_proxy_direction(entity)
  local is_ns = entity.direction == defines.direction.east or defines.direction.west
  entity.direction = is_ns and defines.direction.east or defines.direction.north
end

add_migration{
  name = "v0_4_0_relocate_proxy_ghosts",
  low = {0,0,0},
  high = {0,4,0},
  task = function()
    for _, s in pairs(game.surfaces) do
      local ghosts = s.find_entities_filtered{
        name = "entity-ghost",
      }
      for _, g in ipairs(ghosts) do
        if g.valid and g.ghost_name:find("^railu?n?loader%-placement%-proxy$") then
          -- fix up any recorded circuit connections
          local old_position_key = s.name .. "@" .. g.position.x .. "," .. g.position.y
          local new_position = util.moveposition(g.position, util.offset(g.direction, 1.5, 0))
          local new_position_key = s.name .. "@" .. new_position.x .. "," .. new_position.y
          local connections = global.ghosts[old_position_key]
          if connections then
            global.ghosts[new_position_key] = connections
            global.ghosts[old_position_key] = nil
          end

          --re-orient
          g.teleport(new_position)
          update_proxy_direction(g)

          -- remove any underlying rail ghosts
          local rail_ghosts = s.find_entities_filtered{
            name = "entity-ghost",
            ghost_type = "straight-rail",
            area = g.bounding_box,
          }
          for _, rg in ipairs(rail_ghosts) do
            rg.destroy()
          end
        end
      end
    end
  end
}

--[[
  foreach player
    foreach inventory
      foreach slot
  foreach surface
    foreach entity
      foreach inventory
        foreach slot
]]
local function all_blueprints()
  local next_player
  do
    local f, s, var = pairs(game.players)
    next_player = function()
      local player
      var, player = f(s, var)
      return player
    end
  end
  local next_surface
  do
    local f, s, var = pairs(game.surfaces)
    next_surface = function()
      local surface
      var, surface = f(s, var)
      return surface
    end
  end

  local max_inventory_id = 1
  for _, inventory_id in pairs(defines.inventory) do
    if inventory_id > max_inventory_id then
      max_inventory_id = inventory_id
    end
  end

  local done_with_players = false
  local entity = next_player()
  local entities
  local entities_iter
  local inventories_iter = 0
  local inventory
  local inventory_iter -- starting slot of inventory to examine on next execution

  local iter
  iter = function()
    if inventory then
      for i=inventory_iter,#inventory do
        local stack = inventory[i]
        if stack.valid_for_read then
          log("slot "..i.." contains "..stack.name)
        end
        if stack.valid_for_read and stack.name == "blueprint" then
          inventory_iter = i + 1
          return stack
        end
      end
    end

    -- search for next inventory
    if entity then
      while true do
        inventories_iter = inventories_iter + 1
        if inventories_iter > max_inventory_id then
          break
        end
        inventory = entity.get_inventory(inventories_iter)
        if inventory and not inventory.is_empty() then
          log("examining inventory "..inventories_iter.." of entity "..entity.name)
          inventory_iter = 1
          return iter()
        end
      end
    end

    -- ran out of inventories, look for next entity
    if not done_with_players then
      entity = next_player()
      if not entity then
        done_with_players = true
        return iter()
      end
    end

    if entities then
      entities_iter, entity = next(entities, entities_iter)
      if entity then
        if entity.name == "item-on-ground" and entity.stack.name == "blueprint" then
          return entity.stack
        else
          inventories_iter = 0
          return iter()
        end
      end
    end

    local surface = next_surface()
    if not surface then
      return nil
    end
    entities = surface.find_entities()
    return iter()
  end

  return iter
end

add_migration{
  name = "v0_4_0_relocate_blueprint_proxies",
  low = {0,0,0},
  high = {0,4,0},
  task = function()
    for bp in all_blueprints() do
      if bp.is_blueprint_setup() then
        local entities = bp.get_blueprint_entities()
        if entities then
          for _, e in ipairs(entities) do
            if e.name:find("^railu?n?%loader%-placement%-proxy") then
              e.position = util.moveposition(e.position, util.offset(e.direction, 1.5, 0))
              update_proxy_direction(e)
              for k, e2 in ipairs(entities) do
                local prototype = game.entity_prototypes[e2.name]
                if prototype.type == "straight-rail" then
                  if (e.direction == defines.direction.north
                      and e2.position.x == e.position.x
                      and e2.position.y <= e.position.y + 2
                      and e2.position.y >= e.position.y - 2)
                    or (e.direction == defines.direction.east
                      and e2.position.y == e.position.y
                      and e2.position.x <= e.position.x + 2
                      and e2.position.x >= e.position.x - 2) then
                    entities[k] = nil
                  end
                end
              end
            end
          end
          bp.set_blueprint_entities(entities)
        end
      end
    end
  end
}

return M