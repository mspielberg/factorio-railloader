for _, surface in pairs(game.surfaces) do
  for _, e in ipairs(surface.find_entities_filtered{name="railloader-structure-vertical"}) do
    local rail = surface.find_entity("straight-rail", e.position)
    if rail.direction == defines.direction.east then
      surface.create_entity{
        name = "railloader-structure-horizontal",
        position = e.position,
        force = e.force,
      }
      e.destroy()
    end
  end
  for _, e in ipairs(surface.find_entities_filtered{name="railunloader-chest"}) do
    local rail = surface.find_entity("straight-rail", e.position)
    if rail.direction == defines.direction.east then
      surface.create_entity{
        name = "railunloader-structure-horizontal",
        position = e.position,
        force = e.force,
      }
    else
      surface.create_entity{
        name = "railunloader-structure-vertical",
        position = e.position,
        force = e.force,
      }
    end
  end
end