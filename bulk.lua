local M = {}

local patterns = {
  ore = {
    -- generic
    "%-ore$",
    -- angelsrefining
    "^angels%-ore",
    "^angels%-.*%-nugget$",
    "^angels%-.*%-pebbles$",
    "^angels%-.*%-slag$",
    -- angelssmelting
    "^processed%-",
    -- angelspetrochem
    "^solid%-",
  },
  plates = {
    "plate",
    "ingot",
  }
}

-- bulk items that don't fit the above patterns
local items = {
  -- base
  "coal", "landfill", "stone", "sulfur",
  -- bobores
  "quartz",
  -- bobplates
  "carbon", "salt", "lithium-chloride", "lithium-perchlorate",
  "sodium-hydroxide", "calcium-chloride", "lead-oxide", "alumina",
  "tungsten-oxide", "powdered-tungsten", "silicon-powder", "silicon-nitride",
  "cobalt-oxide", "silicon-carbide", "silver-nitrate", "silver-oxide",
  -- angelsrefining
  "stone-crushed",
  "slag",
  -- angelspetrochem
  "coal-crushed",
}

for i, item in ipairs(items) do
  items[item] = true
  items[i] = nil
end

-- runtime variables

local allowed_items_setting = settings.global["railloader-allowed-items"].value

local function item_matches_patterns(item_name, group)
  for _, pat in ipairs(patterns[group]) do
    if string.match(item_name, pat) then
      log("{item="..item_name..", pattern="..pat.."}")
      return true
    end
  end
  return false
end

local acceptable_item_cache = {}

local function is_acceptable_item(item_name)
  if allowed_items_setting == "any" then
    return true
  end

  local from_cache = acceptable_item_cache[item_name]
  if from_cache ~= nil then
    return from_cache
  end
  acceptable_item_cache[item_name] = items[item_name] or
    item_matches_patterns(item_name, "ore") or
    (allowed_items_setting == "ore, plates" and item_matches_patterns(item_name, "plates"))
  return acceptable_item_cache[item_name]
end

function M.acceptable_items(inventory, limit)
  local out = {}
  for name in pairs(inventory.get_contents()) do
    if is_acceptable_item(name) then
      out[#out+1] = name
      if #out >= limit then
        return out
      end
    end
  end
  return out
end

function M.on_setting_changed()
  allowed_items_setting = settings.global["railloader-allowed-items"].value
  acceptable_item_cache = {}
end

return M