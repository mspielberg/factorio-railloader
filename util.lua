local M = {}

-- Position adjustments

function M.moveposition(position, offset)
  return {x=position.x + offset.x, y=position.y + offset.y}
end

function M.offset(direction, longitudinal, orthogonal)
  if direction == defines.direction.north then
    return {x=orthogonal, y=-longitudinal}
  end

  if direction == defines.direction.south then
    return {x=-orthogonal, y=longitudinal}
  end

  if direction == defines.direction.east then
    return {x=longitudinal, y=orthogonal}
  end

  if direction == defines.direction.west then
    return {x=-longitudinal, y=-orthogonal}
  end
end

function M.box_centered_at(position, radius)
  return {
    left_top = M.moveposition(position, M.offset(defines.direction.north, radius, -radius)),
    right_bottom = M.moveposition(position, M.offset(defines.direction.south, radius, -radius)),
  }
end

function M.is_empty_box(box)
  local size_x = box.right_bottom.x - box.left_top.x
  local size_y = box.right_bottom.y - box.left_top.y
  return size_x < 0.01 and size_y < 0.01
end

function M.orthogonal_direction(direction)
  if direction < 6 then
    return direction + 2
  end
  return 0
end

return M