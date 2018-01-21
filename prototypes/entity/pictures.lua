local M = {}

M.railloader_proxy_animations = {
  north = {
    filename = "__railloader__/graphics/railloader-placement-proxy/horizontal.png",
    width = 224,
    height = 224,
    frame_count = 1,
    shift = util.by_pixel(0, -48),
  },
  east = {
    filename = "__railloader__/graphics/railloader-placement-proxy/vertical.png",
    width = 256,
    height = 256,
    frame_count = 1,
    shift = util.by_pixel(48, 0),
  },
  south = {
    filename = "__railloader__/graphics/railloader-placement-proxy/horizontal.png",
    width = 224,
    height = 224,
    frame_count = 1,
    shift = util.by_pixel(0, 48),
  },
  west = {
    filename = "__railloader__/graphics/railloader-placement-proxy/vertical.png",
    width = 256,
    height = 256,
    frame_count = 1,
    shift = util.by_pixel(-48, 0),
  },
}

M.railunloader_proxy_animations = {
  north = {
    filename = "__railloader__/graphics/railunloader/structure-horizontal.png",
    width = 384,
    height = 256,
    frame_count = 1,
    shift = util.by_pixel(0, -48),
    scale = 0.5,
  },
  east = {
    filename = "__railloader__/graphics/railunloader/structure-vertical.png",
    width = 256,
    height = 384,
    frame_count = 1,
    shift = util.by_pixel(48, 0),
    scale = 0.5,
  },
  south = {
    filename = "__railloader__/graphics/railunloader/structure-horizontal.png",
    width = 384,
    height = 256,
    frame_count = 1,
    shift = util.by_pixel(0, 48),
    scale = 0.5,
  },
  west = {
    filename = "__railloader__/graphics/railunloader/structure-vertical.png",
    width = 256,
    height = 384,
    frame_count = 1,
    shift = util.by_pixel(-48, 0),
    scale = 0.5,
  },
}

M.empty_sheet = {
  filename = "__core__/graphics/empty.png",
  priority = "very-low",
  width = 0,
  height = 0,
}

M.empty_animation = {
  filename = "__core__/graphics/empty.png",
  width = 0,
  height = 0,
  frame_count = 1,
}

return M