local M = {}

local patterns = {
  -- generic
  "%-ore$",
  -- angelsrefining
  "^angels%-ore",
  "^angels%-.*%-nugget",
  "^angels%-.*%-pebbles",
  "^angels%-.*%-slag",
  -- angelssmelting
  "^processed%-"
}

-- bulk items that don't fit the above patterns
local items = {
  -- base
  ["coal"] = true,
  ["landfill"] = true,
  ["stone"] = true,
  ["sulfur"] = true,
  -- bobores
  ["quartz"] = true,
  -- bobplates
  ["carbon"] = true,
  -- angelsrefining
  ["stone-crushed"] = true,
  ["slag"] = true,
}

-- runtime variables

local function item_matches_patterns(item_name)
  for _, pat in ipairs(patterns) do
    if string.match(item_name, pat) then
      log("{item="..item_name..", pattern="..pat.."}")
      return true
    end
  end
  return false
end

local acceptable_item_cache = {}

local function is_acceptable_item(item_name)
  local from_cache = acceptable_item_cache[item_name]
  if from_cache ~= nil then
    return from_cache
  end
  acceptable_item_cache[item_name] = items[item_name] or item_matches_patterns(item_name)
  return acceptable_item_cache[item_name]
end

function M.first_acceptable_item(inventory)
  for i=1,#inventory do
    local stack = inventory[i]
    if stack.valid_for_read and is_acceptable_item(stack.name) then
      return stack.name
    end
  end
  return nil
end

return M