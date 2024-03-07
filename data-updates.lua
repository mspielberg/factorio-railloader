-- Compatible with angel's addons storage
if data.raw.technology["ore-silos"] then
    table.insert(data.raw.technology["railloader"].prerequisites, "ore-silos")
end
