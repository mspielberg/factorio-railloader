for _, f in pairs(game.forces) do
  local researched = f.technologies["railloader"].researched
  f.recipes["railloader"].enabled = researched
  f.recipes["railunloader"].enabled = researched
end
