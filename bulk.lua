local M = {}

local patterns = {
  ore = {
    -- generic
    "crushed",
    "dust",
    "ore",
    "powder",
    "rock",
    "sand",
    "slag",
    -- angelsrefining
    "^angels%-.*%-nugget$",
    "^angels%-.*%-pebbles$",
    "^angels%-.*%-slag$",
    "^geode%-",
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
  "coal", "landfill", "plastic-bar", "stone", "sulfur",
  -- bobores
  "quartz",
  -- bobplates
  "carbon", "salt", "lithium-chloride", "lithium-perchlorate",
  "sodium-hydroxide", "calcium-chloride", "lead-oxide", "alumina",
  "tungsten-oxide", "silicon-nitride", "cobalt-oxide", "silicon-carbide",
  "silver-nitrate", "silver-oxide",
  -- omnimatter
  "omnite",
  -- pycoalprocessing
  "ash", "gravel", "coke", "iron-oxide", "active-carbon", "zinc-chloride",
  "soil", "limestone", "organics", "coarse", "lithium-peroxide", "lime",
  "fawogae-substrate", "bonemeal", "borax", "raw-borax", "ralesia",
  "ralesia-seeds", "rich-clay", "boron-trioxide", "niobium-concentrate",
  "niobium-oxide", "ppd", "coal-briquette", "calcium-carbide",
}

for i, item in ipairs(items) do
  items[item] = true
  items[i] = nil
end

-- runtime variables

local allowed_items_setting = settings.global["railloader-allowed-items"].value

local function item_matches_patterns(item_name, group)
  for _, pat in ipairs(patterns[group]) do
    if string.find(item_name, pat) then
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