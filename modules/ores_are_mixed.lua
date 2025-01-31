local Event = require 'utils.event'
local simplex_noise = require 'utils.math.simplex_noise'.d2
local Public = {}
local ore_raffle = {
    'iron-ore',
    'iron-ore',
    'iron-ore',
    'copper-ore',
    'copper-ore',
    'coal',
    'stone'
}

Public.settings = {
    mixed_ores_on_nauvis_only = false
}

local function on_chunk_generated(event)
    local surface = event.surface
    if Public.settings.mixed_ores_on_nauvis_only and surface.name ~= 'nauvis' then
        return
    end
    local ores = surface.find_entities_filtered({ area = event.area, name = { 'iron-ore', 'copper-ore', 'coal', 'stone' } })
    if #ores == 0 then
        return
    end
    local seed = game.surfaces[1].map_gen_settings.seed

    for _, ore in pairs(ores) do
        local pos = ore.position
        local noise =
            simplex_noise(pos.x * 0.005, pos.y * 0.005, seed) + simplex_noise(pos.x * 0.01, pos.y * 0.01, seed) * 0.3 + simplex_noise(pos.x * 0.05, pos.y * 0.05, seed) * 0.2

        local i = (math.floor(noise * 100) % 7) + 1
        surface.create_entity({ name = ore_raffle[i], position = ore.position, amount = ore.amount })
        ore.destroy()
    end
end

Event.add(defines.events.on_chunk_generated, on_chunk_generated)

return Public
