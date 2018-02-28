local loader_rail = util.table.deepcopy(data.raw["straight-rail"]["straight-rail"])
loader_rail.name = "railloader-rail"
loader_rail.flags = {"player-creation"}
--unselectable_rail.selectable_in_game = false
loader_rail.collision_box = {{-0.7, -2.8}, {0.7, 2.8}}

data:extend{loader_rail}