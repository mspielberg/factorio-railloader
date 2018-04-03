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
          g.direction = util.orthogonal_direction(g.direction)

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

return M