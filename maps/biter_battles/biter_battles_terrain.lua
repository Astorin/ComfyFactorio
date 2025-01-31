--luacheck:ignore
local simplex_noise = require 'utils.math.simplex_noise'
local simplex_noise = simplex_noise.d2
local event = require 'utils.event'
local biter_battles_terrain = {}
local math_random = math.random
local table_insert = table.insert

local function on_chunk_generated(event)
    local seed = game.surfaces[1].map_gen_settings.seed

    if not game.surfaces['surface'] then
        return
    end

    local surface = game.surfaces['surface']
    if event.surface.name ~= surface.name then
        return
    end

    local ore_amount = 2500
    local ores = { 'copper-ore', 'iron-ore', 'stone', 'coal' }
    local noise = {}
    --local tiles = {}

    local aa = 0.0113
    local bb = 21
    local xx = 1.1
    local cc = xx - (aa * bb)

    for x = 0, 31, 1 do
        for y = 0, 31, 1 do
            --	tiles = {}
            local pos_x = event.area.left_top.x + x
            local pos_y = event.area.left_top.y + y
            local tile_to_insert = false
            local entity_has_been_placed = false

            noise[1] = simplex_noise(pos_x / 250, pos_y / 250, seed)
            noise[2] = simplex_noise(pos_x / 75, pos_y / 75, seed + 10000)
            noise[8] = simplex_noise(pos_x / 15, pos_y / 15, seed + 40000)
            noise[3] = noise[1] + noise[2] * 0.2 + noise[8] * 0.02

            noise[4] = simplex_noise(pos_x / 200, pos_y / 200, seed + 15000)
            noise[5] = simplex_noise(pos_x / 20, pos_y / 20, seed + 20000)
            noise[6] = simplex_noise(pos_x / 8, pos_y / 8, seed + 25000)
            noise[7] = simplex_noise(pos_x / 400, pos_y / 400, seed + 35000)
            local water_noise = noise[4] + (noise[6] * 0.006) + (noise[5] * 0.04)

            local a = ore_amount * (1 + (noise[2] * 0.3))
            xx = 1.1
            if noise[3] >= cc then
                for yy = 1, bb, 1 do
                    local z = (yy % 4) + 1
                    xx = xx - aa
                    if noise[3] > xx then
                        if surface.can_place_entity { name = ores[z], position = { pos_x, pos_y }, amount = a } then
                            surface.create_entity { name = ores[z], position = { pos_x, pos_y }, amount = a }
                        end
                        entity_has_been_placed = true
                        break
                    end
                end
            end
            if entity_has_been_placed == false then
                if water_noise < -0.92 and water_noise < noise[7] then
                    tile_to_insert = 'water'
                end
                if water_noise < -0.97 and water_noise < noise[7] then
                    tile_to_insert = 'deepwater'
                end
            end
            --if tile_to_insert then table_insert(tiles, {name = tile_to_insert, position = {pos_x,pos_y}}) end
            if tile_to_insert then
                surface.set_tiles({ { name = tile_to_insert, position = { pos_x, pos_y } } }, true)
            end

            if tile_to_insert == 'water' or tile_to_insert == 'deepwater' then
                if surface.can_place_entity { name = 'fish', position = { pos_x, pos_y } } and math_random(1, 14) == 1 then
                    surface.create_entity { name = 'fish', position = { pos_x, pos_y } }
                end
            end
        end
    end

    if event.area.left_top.y < 160 or event.area.left_top.y > -192 then
        local tiles = {}
        local spawn_tile = surface.get_tile(game.forces.south.get_spawn_position(surface))
        local radius = 24 --starting pond radius
        local radsquare = radius * radius
        local horizontal_border_width = storage.horizontal_border_width
        for x = 0, 31, 1 do
            for y = 0, 31, 1 do
                tiles = {}
                local pos_x = event.area.left_top.x + x
                local pos_y = event.area.left_top.y + y
                local tile_to_insert = false
                local tile_distance_to_center = pos_x ^ 2 + pos_y ^ 2
                noise[4] = simplex_noise(pos_x / 85, pos_y / 85, seed + 20000)
                noise[5] = simplex_noise(pos_x / 7, pos_y / 7, seed + 30000)
                noise[7] = 1 + (noise[4] + (noise[5] * 0.75)) * 0.11
                if pos_y >= ((horizontal_border_width / 2) * -1) * noise[7] and pos_y <= (horizontal_border_width / 2) * noise[7] then
                    if pos_x < 20 and pos_x > -20 then
                        local entities = surface.find_entities({ { pos_x, pos_y }, { pos_x + 1, pos_y + 1 } })
                        for _, e in pairs(entities) do
                            if e.type == 'simple-entity' or e.type == 'resource' or e.type == 'tree' then
                                e.destroy()
                            end
                        end
                    end
                    tile_to_insert = 'deepwater'
                else
                    local t = surface.get_tile(pos_x, pos_y)
                    if t.name == 'deepwater' or t.name == 'water' then
                        if tile_distance_to_center < 20000 then
                            if spawn_tile.name == 'water' or spawn_tile.name == 'deepwater' then
                                tile_to_insert = 'sand-1'
                            else
                                tile_to_insert = spawn_tile.name
                            end
                        end
                    end
                end
                if tile_distance_to_center <= radsquare then
                    if tile_distance_to_center >= radsquare / 10 then
                        tile_to_insert = 'deepwater'
                    else
                        tile_to_insert = 'sand-1'
                        if tile_distance_to_center >= radsquare / 18 then
                            tile_to_insert = 'refined-concrete'
                        end
                    end
                end
                if tile_to_insert then
                    table_insert(tiles, { name = tile_to_insert, position = { pos_x, pos_y } })
                end
                surface.set_tiles(tiles, true)

                if tile_to_insert == 'deepwater' then
                    if surface.can_place_entity { name = 'fish', position = { pos_x, pos_y } } and math_random(1, 35) == 1 then
                        surface.create_entity { name = 'fish', position = { pos_x, pos_y } }
                    end
                end
            end
        end
    end
end

local function find_tile_placement_spot_around_target_position(tilename, position, mode, density)
    local x = position.x
    local y = position.y
    if not surface then
        surface = game.surfaces['surface']
    end
    local scan_radius = 50
    if not tilename then
        return
    end
    if not mode then
        mode = 'ball'
    end
    if not density then
        density = 1
    end
    local cluster_tiles = {}
    local auto_correct = true

    local scanned_tile = surface.get_tile(x, y)
    if scanned_tile.name ~= tilename then
        table_insert(cluster_tiles, { name = tilename, position = { x, y } })
        surface.set_tiles(cluster_tiles, auto_correct)
        return true, x, y
    end

    local i = 2
    local r = 1

    if mode == 'ball' then
        if math_random(1, 2) == 1 then
            density = density * -1
        end
        r = math_random(1, 4)
    end
    if mode == 'line' then
        density = 1
        r = math_random(1, 4)
    end
    if mode == 'line_down' then
        density = density * -1
        r = math_random(1, 4)
    end
    if mode == 'line_up' then
        density = 1
        r = math_random(1, 4)
    end
    if mode == 'block' then
        r = 1
        density = 1
    end

    if r == 1 then
        --start placing at -1,-1
        while i <= scan_radius do
            y = y - density
            x = x - density
            for a = 1, i, 1 do
                local scanned_tile = surface.get_tile(x, y)
                if scanned_tile.name ~= tilename then
                    table_insert(cluster_tiles, { name = tilename, position = { x, y } })
                    surface.set_tiles(cluster_tiles, auto_correct)
                    return true, x, y
                end
                x = x + density
            end
            for a = 1, i, 1 do
                local scanned_tile = surface.get_tile(x, y)
                if scanned_tile.name ~= tilename then
                    table_insert(cluster_tiles, { name = tilename, position = { x, y } })
                    surface.set_tiles(cluster_tiles, auto_correct)
                    return true, x, y
                end
                y = y + density
            end
            for a = 1, i, 1 do
                local scanned_tile = surface.get_tile(x, y)
                if scanned_tile.name ~= tilename then
                    table_insert(cluster_tiles, { name = tilename, position = { x, y } })
                    surface.set_tiles(cluster_tiles, auto_correct)
                    return true, x, y
                end
                x = x - density
            end
            for a = 1, i, 1 do
                local scanned_tile = surface.get_tile(x, y)
                if scanned_tile.name ~= tilename then
                    table_insert(cluster_tiles, { name = tilename, position = { x, y } })
                    surface.set_tiles(cluster_tiles, auto_correct)
                    return true, x, y
                end
                y = y - density
            end
            i = i + 2
        end
    end

    if r == 2 then
        --start placing at 0,-1
        while i <= scan_radius do
            y = y - density
            x = x - density
            for a = 1, i, 1 do
                x = x + density
                local scanned_tile = surface.get_tile(x, y)
                if scanned_tile.name ~= tilename then
                    table_insert(cluster_tiles, { name = tilename, position = { x, y } })
                    surface.set_tiles(cluster_tiles, auto_correct)
                    return true, x, y
                end
            end
            for a = 1, i, 1 do
                y = y + density
                local scanned_tile = surface.get_tile(x, y)
                if scanned_tile.name ~= tilename then
                    table_insert(cluster_tiles, { name = tilename, position = { x, y } })
                    surface.set_tiles(cluster_tiles, auto_correct)
                    return true, x, y
                end
            end
            for a = 1, i, 1 do
                x = x - density
                local scanned_tile = surface.get_tile(x, y)
                if scanned_tile.name ~= tilename then
                    table_insert(cluster_tiles, { name = tilename, position = { x, y } })
                    surface.set_tiles(cluster_tiles, auto_correct)
                    return true, x, y
                end
            end
            for a = 1, i, 1 do
                y = y - density
                local scanned_tile = surface.get_tile(x, y)
                if scanned_tile.name ~= tilename then
                    table_insert(cluster_tiles, { name = tilename, position = { x, y } })
                    surface.set_tiles(cluster_tiles, auto_correct)
                    return true, x, y
                end
            end
            i = i + 2
        end
    end

    if r == 3 then
        --start placing at 1,-1
        while i <= scan_radius do
            y = y - density
            x = x + density
            for a = 1, i, 1 do
                local scanned_tile = surface.get_tile(x, y)
                if scanned_tile.name ~= tilename then
                    table_insert(cluster_tiles, { name = tilename, position = { x, y } })
                    surface.set_tiles(cluster_tiles, auto_correct)
                    return true, x, y
                end
                y = y + density
            end
            for a = 1, i, 1 do
                local scanned_tile = surface.get_tile(x, y)
                if scanned_tile.name ~= tilename then
                    table_insert(cluster_tiles, { name = tilename, position = { x, y } })
                    surface.set_tiles(cluster_tiles, auto_correct)
                    return true, x, y
                end
                x = x - density
            end
            for a = 1, i, 1 do
                local scanned_tile = surface.get_tile(x, y)
                if scanned_tile.name ~= tilename then
                    table_insert(cluster_tiles, { name = tilename, position = { x, y } })
                    surface.set_tiles(cluster_tiles, auto_correct)
                    return true, x, y
                end
                y = y - density
            end
            for a = 1, i, 1 do
                local scanned_tile = surface.get_tile(x, y)
                if scanned_tile.name ~= tilename then
                    table_insert(cluster_tiles, { name = tilename, position = { x, y } })
                    surface.set_tiles(cluster_tiles, auto_correct)
                    return true, x, y
                end
                x = x + density
            end
            i = i + 2
        end
    end

    if r == 4 then
        --start placing at 1,0
        while i <= scan_radius do
            y = y - density
            x = x + density
            for a = 1, i, 1 do
                y = y + density
                local scanned_tile = surface.get_tile(x, y)
                if scanned_tile.name ~= tilename then
                    table_insert(cluster_tiles, { name = tilename, position = { x, y } })
                    surface.set_tiles(cluster_tiles, auto_correct)
                    return true, x, y
                end
            end
            for a = 1, i, 1 do
                x = x - density
                local scanned_tile = surface.get_tile(x, y)
                if scanned_tile.name ~= tilename then
                    table_insert(cluster_tiles, { name = tilename, position = { x, y } })
                    surface.set_tiles(cluster_tiles, auto_correct)
                    return true, x, y
                end
            end
            for a = 1, i, 1 do
                y = y - density
                local scanned_tile = surface.get_tile(x, y)
                if scanned_tile.name ~= tilename then
                    table_insert(cluster_tiles, { name = tilename, position = { x, y } })
                    surface.set_tiles(cluster_tiles, auto_correct)
                    return true, x, y
                end
            end
            for a = 1, i, 1 do
                x = x + density
                local scanned_tile = surface.get_tile(x, y)
                if scanned_tile.name ~= tilename then
                    table_insert(cluster_tiles, { name = tilename, position = { x, y } })
                    surface.set_tiles(cluster_tiles, auto_correct)
                    return true, x, y
                end
            end
            i = i + 2
        end
    end
    return false
end

local function create_tile_cluster(tilename, position, amount)
    local mode = 'ball'
    local cluster_tiles = {}
    local surface = game.surfaces['surface']
    local pos = position
    local x = pos.x
    local y = pos.y
    for i = 1, amount, 1 do
        local b, x, y = find_tile_placement_spot_around_target_position(tilename, pos, mode)
        if b == true then
            if 1 == math_random(1, 16) then
                pos.x = x
                pos.y = y
            end
        end
        if b == false then
            return false, x, y
        end
        if i >= amount then
            return true, x, y
        end
    end
end

function biter_battles_terrain.generate_spawn_water_pond()
    local x = 1
    local surface = game.surfaces['surface']
    for _, silo in pairs(storage.rocket_silo) do
        local pos = {}
        local wreck_pos = {}
        pos['x'] = silo.position.x + 60 * x
        pos['y'] = silo.position.y - 5 * x
        create_tile_cluster('water-green', pos, 450)
        local p = surface.find_non_colliding_position('big-ship-wreck-1', { pos['x'], pos['y'] - 3 * x }, 20, 1)
        local e = surface.create_entity { name = 'big-ship-wreck-1', position = p, force = silo.force.name }
        e.insert({ name = 'copper-cable', count = 7 })
        e.insert({ name = 'iron-stick', count = 3 })
        local p = surface.find_non_colliding_position('big-ship-wreck-3', { pos.x - 3 * x, pos.y }, 20, 1)
        local e = surface.create_entity { name = 'big-ship-wreck-3', position = p, force = silo.force.name }
        e.insert({ name = 'land-mine', count = 6 })
        pos['x'] = silo.position.x - 80 * x
        pos['y'] = silo.position.y - 60 * x
        create_tile_cluster('water-green', pos, 300)
        local p = surface.find_non_colliding_position('big-ship-wreck-2', { pos.x + 3 * x, pos.y - 5 * x }, 20, 1)
        local e = surface.create_entity { name = 'big-ship-wreck-2', position = p, force = silo.force.name }
        e.insert({ name = 'barrel', count = 1 })
        e.insert({ name = 'lubricant-barrel', count = 2 })
        local p = surface.find_non_colliding_position('crude-oil', { pos.x - 5 * x, pos.y + 5 * x }, 50, 1)
        local e = surface.create_entity { name = 'crude-oil', position = p, amount = 225000 }
        x = -1
    end

    for x = -200, 200, 1 do
        for y = -200, 200, 1 do
            local t = surface.get_tile(x, y)
            if t.name == 'water-green' then
                if surface.can_place_entity { name = 'fish', position = { x, y } } and math_random(1, 12) == 1 then
                    surface.create_entity { name = 'fish', position = { x, y } }
                end
            end
        end
    end
end

function biter_battles_terrain.clear_spawn_ores()
    local surface = game.surfaces['surface']
    for x = -200, 200, 1 do
        for y = -200, 200, 1 do
            local tile_distance_to_center = math.sqrt(x ^ 2 + y ^ 2)
            if tile_distance_to_center < 150 then
                local entities = surface.find_entities({ { x, y }, { x + 1, y + 1 } })
                for _, e in pairs(entities) do
                    if e.type == 'resource' then
                        e.destroy()
                    end
                end
            end
        end
    end
end

function biter_battles_terrain.generate_market()
    local surface = game.surfaces['surface']
    for z = -1, 1, 2 do
        local f = 'north'
        if z == 1 then
            f = 'south'
        end
        local x = storage.rocket_silo[f].position.x + (80 * z)
        local y = storage.rocket_silo[f].position.y + (60 * z)
        local p = surface.find_non_colliding_position('market', { x, y }, 20, 1)
        local m = surface.create_entity { name = 'market', position = p, force = f }
        local entities = surface.find_entities({ { m.position.x - 1, m.position.y - 1 }, { m.position.x + 1, m.position.y + 1 } })
        for _, ee in pairs(entities) do
            if ee.type == 'simple-entity' or ee.type == 'resource' or ee.type == 'tree' then
                ee.destroy()
            end
        end
        m.minable = false
        m.destructible = false
        m.add_market_item { price = { { 'raw-fish', 1 } }, offer = { type = 'give-item', item = 'small-electric-pole', count = 2 } }
        m.add_market_item { price = { { 'raw-fish', 1 } }, offer = { type = 'give-item', item = 'firearm-magazine', count = 2 } }
        m.add_market_item { price = { { 'raw-fish', 2 } }, offer = { type = 'give-item', item = 'grenade' } }
        m.add_market_item { price = { { 'raw-fish', 2 } }, offer = { type = 'give-item', item = 'land-mine', count = 1 } }
        m.add_market_item { price = { { 'raw-fish', 5 } }, offer = { type = 'give-item', item = 'light-armor' } }
        m.add_market_item { price = { { 'raw-fish', 8 } }, offer = { type = 'give-item', item = 'radar' } }
        m.add_market_item { price = { { 'iron-ore', 50 } }, offer = { type = 'give-item', item = 'raw-fish' } }
        m.add_market_item { price = { { 'copper-ore', 50 } }, offer = { type = 'give-item', item = 'raw-fish' } }
        m.add_market_item { price = { { 'stone', 50 } }, offer = { type = 'give-item', item = 'raw-fish' } }
        m.add_market_item { price = { { 'coal', 50 } }, offer = { type = 'give-item', item = 'raw-fish' } }
    end
end

function biter_battles_terrain.generate_artillery()
    local tiles = {}
    local surface = game.surfaces['surface']
    storage.spawn_artillery = {}
    for z = -1, 1, 2 do
        local f = 'north'
        if z == 1 then
            f = 'south'
        end
        storage.spawn_artillery[f] = surface.create_entity { name = 'artillery-turret', position = { 55 * z, 26 * z }, force = f }
        local e = storage.spawn_artillery[f]
        e.minable = false
        e.destructible = false
        local entities = surface.find_entities({ { e.position.x - 3, e.position.y - 4 }, { e.position.x + 3, e.position.y + 4 } })
        for _, ee in pairs(entities) do
            if ee.type == 'simple-entity' or ee.type == 'resource' or ee.type == 'tree' then
                ee.destroy()
            end
        end
        local m = surface.create_entity { name = 'market', position = { e.position.x, e.position.y + (3 * z) }, force = f }
        m.minable = false
        m.destructible = false
        m.add_market_item { price = { { 'raw-fish', 2 } }, offer = { type = 'give-item', item = 'grenade' } }
        m.add_market_item { price = { { 'raw-fish', 1 } }, offer = { type = 'give-item', item = 'land-mine', count = 1 } }
        m.add_market_item { price = { { 'raw-fish', 60 } }, offer = { type = 'give-item', item = 'artillery-shell' } }
        m.add_market_item { price = { { 'raw-fish', 20 } }, offer = { type = 'give-item', item = 'artillery-targeting-remote' } }
        for y = -1, 1, 1 do
            for x = -2, 2, 1 do
                table_insert(tiles, { name = 'refined-hazard-concrete-left', position = { e.position.x + x, e.position.y + y } })
            end
        end
        for y = -2, 2, 1 do
            for x = -1, 1, 1 do
                table_insert(tiles, { name = 'refined-hazard-concrete-left', position = { e.position.x + x, e.position.y + y } })
            end
        end
    end
    surface.set_tiles(tiles, true)
end

function biter_battles_terrain.generate_spawn_ores(ore_layout)
    local surface = game.surfaces['surface']
    local seed = game.surfaces[1].map_gen_settings.seed
    local tiles = {}
    --generate ores around silos
    local ore_layout = 'windows'
    --local ore_layout = "4squares"
    local ore_amount = 850

    if ore_layout == '4squares' then
        local size = 22
        for _, rocket_silo in pairs(storage.rocket_silo) do
            local tiles = {}
            for x = (size + 1) * -1, size + 1, 1 do
                for y = (size + 1) * -1, size + 1, 1 do
                    table_insert(tiles, { name = 'stone-path', position = { rocket_silo.position.x + x, rocket_silo.position.y + y } })
                end
            end
            surface.set_tiles(tiles, true)
            local entities =
                surface.find_entities(
                    { { (rocket_silo.position.x - 4) - size / 2, (rocket_silo.position.y - 5) - size / 2 }, { rocket_silo.position.x + 4 + size / 2, rocket_silo.position.y + 5 + size / 2 } }
                )
            for _, entity in pairs(entities) do
                if entity.type == 'simple-entity' or entity.type == 'tree' or entity.type == 'resource' then
                    entity.destroy()
                end
            end
        end
        for x = size * -1, size, 1 do
            for y = size * -1, size, 1 do
                if x > 0 and y < 0 then
                    if
                        surface.can_place_entity {
                            name = 'stone',
                            position = { storage.rocket_silo['south'].position.x + x, storage.rocket_silo['south'].position.y + y },
                            amount = ore_amount
                        }
                    then
                        surface.create_entity {
                            name = 'stone',
                            position = { storage.rocket_silo['south'].position.x + x, storage.rocket_silo['south'].position.y + y },
                            amount = ore_amount
                        }
                    end
                end
                if x < 0 and y < 0 then
                    if
                        surface.can_place_entity {
                            name = 'coal',
                            position = { storage.rocket_silo['south'].position.x + x, storage.rocket_silo['south'].position.y + y },
                            amount = ore_amount
                        }
                    then
                        surface.create_entity {
                            name = 'coal',
                            position = { storage.rocket_silo['south'].position.x + x, storage.rocket_silo['south'].position.y + y },
                            amount = ore_amount
                        }
                    end
                end
                if x < 0 and y > 0 then
                    if
                        surface.can_place_entity {
                            name = 'copper-ore',
                            position = { storage.rocket_silo['south'].position.x + x, storage.rocket_silo['south'].position.y + y },
                            amount = ore_amount
                        }
                    then
                        surface.create_entity {
                            name = 'copper-ore',
                            position = { storage.rocket_silo['south'].position.x + x, storage.rocket_silo['south'].position.y + y },
                            amount = ore_amount
                        }
                    end
                end
                if x > 0 and y > 0 then
                    if
                        surface.can_place_entity {
                            name = 'iron-ore',
                            position = { storage.rocket_silo['south'].position.x + x, storage.rocket_silo['south'].position.y + y },
                            amount = ore_amount
                        }
                    then
                        surface.create_entity {
                            name = 'iron-ore',
                            position = { storage.rocket_silo['south'].position.x + x, storage.rocket_silo['south'].position.y + y },
                            amount = ore_amount
                        }
                    end
                end
                if x < 0 and y > 0 then
                    if
                        surface.can_place_entity {
                            name = 'stone',
                            position = { storage.rocket_silo['north'].position.x + x, storage.rocket_silo['north'].position.y + y },
                            amount = ore_amount
                        }
                    then
                        surface.create_entity {
                            name = 'stone',
                            position = { storage.rocket_silo['north'].position.x + x, storage.rocket_silo['north'].position.y + y },
                            amount = ore_amount
                        }
                    end
                end
                if x > 0 and y > 0 then
                    if
                        surface.can_place_entity {
                            name = 'coal',
                            position = { storage.rocket_silo['north'].position.x + x, storage.rocket_silo['north'].position.y + y },
                            amount = ore_amount
                        }
                    then
                        surface.create_entity {
                            name = 'coal',
                            position = { storage.rocket_silo['north'].position.x + x, storage.rocket_silo['north'].position.y + y },
                            amount = ore_amount
                        }
                    end
                end
                if x > 0 and y < 0 then
                    if
                        surface.can_place_entity {
                            name = 'copper-ore',
                            position = { storage.rocket_silo['north'].position.x + x, storage.rocket_silo['north'].position.y + y },
                            amount = ore_amount
                        }
                    then
                        surface.create_entity {
                            name = 'copper-ore',
                            position = { storage.rocket_silo['north'].position.x + x, storage.rocket_silo['north'].position.y + y },
                            amount = ore_amount
                        }
                    end
                end
                if x < 0 and y < 0 then
                    if
                        surface.can_place_entity {
                            name = 'iron-ore',
                            position = { storage.rocket_silo['north'].position.x + x, storage.rocket_silo['north'].position.y + y },
                            amount = ore_amount
                        }
                    then
                        surface.create_entity {
                            name = 'iron-ore',
                            position = { storage.rocket_silo['north'].position.x + x, storage.rocket_silo['north'].position.y + y },
                            amount = ore_amount
                        }
                    end
                end
            end
        end
        for _, rocket_silo in pairs(storage.rocket_silo) do
            local entities = surface.find_entities({ { rocket_silo.position.x - 5, rocket_silo.position.y - 6 }, { rocket_silo.position.x + 5, rocket_silo.position.y + 6 } })
            for _, entity in pairs(entities) do
                if entity.type == 'resource' then
                    entity.destroy()
                end
            end
        end
    end

    if ore_layout == 'windows' then
        local m1 = 0.09
        local m2 = 0
        local m3 = 1
        local m4 = 23

        for x = m4 * -1, m4, 1 do
            local noise = simplex_noise(x * m1, 1 * m1, seed + 50000)
            noise = noise * m2 + m3
            for y = (m4 + 1) * -1 * noise, m4 * noise, 1 do
                table_insert(tiles, { name = 'stone-path', position = { storage.rocket_silo['north'].position.x + x, storage.rocket_silo['north'].position.y + y } })
            end
            local noise = simplex_noise(x * m1, 1 * m1, seed + 60000)
            noise = noise * m2 + m3
            for y = (m4 + 1) * -1 * noise, m4 * noise, 1 do
                table_insert(tiles, { name = 'stone-path', position = { storage.rocket_silo['south'].position.x + x, storage.rocket_silo['south'].position.y + y } })
            end
        end
        for y = (m4 + 1) * -1, m4, 1 do
            local noise = simplex_noise(y * m1, 1 * m1, seed + 50000)
            noise = noise * m2 + m3
            for x = m4 * -1 * noise, m4 * noise, 1 do
                table_insert(tiles, { name = 'stone-path', position = { storage.rocket_silo['north'].position.x + x, storage.rocket_silo['north'].position.y + y } })
            end
            local noise = simplex_noise(y * m1, 1 * m1, seed + 60000)
            noise = noise * m2 + m3
            for x = m4 * -1 * noise, m4 * noise, 1 do
                table_insert(tiles, { name = 'stone-path', position = { storage.rocket_silo['south'].position.x + x, storage.rocket_silo['south'].position.y + y } })
            end
        end
        surface.set_tiles(tiles, true)

        local ore = {
            'stone',
            'stone',
            'stone',
            'stone',
            'coal',
            'coal',
            'coal',
            'coal',
            'coal',
            'copper-ore',
            'copper-ore',
            'copper-ore',
            'copper-ore',
            'copper-ore',
            'iron-ore',
            'iron-ore',
            'iron-ore',
            'iron-ore',
            'iron-ore'
        }
        for z = 1, 19, 1 do
            for x = -4 - z, 4 + z, 1 do
                for y = -5 - z, 4 + z, 1 do
                    if
                        surface.can_place_entity {
                            name = ore[z],
                            position = { storage.rocket_silo['south'].position.x + x, storage.rocket_silo['south'].position.y + y },
                            amount = ore_amount
                        }
                    then
                        surface.create_entity {
                            name = ore[z],
                            position = { storage.rocket_silo['south'].position.x + x, storage.rocket_silo['south'].position.y + y },
                            amount = ore_amount
                        }
                    end
                end
            end
        end
        for z = 1, 19, 1 do
            for x = -4 - z, 4 + z, 1 do
                for y = -5 - z, 4 + z, 1 do
                    if
                        surface.can_place_entity {
                            name = ore[z],
                            position = { storage.rocket_silo['north'].position.x + x, storage.rocket_silo['north'].position.y + y },
                            amount = ore_amount
                        }
                    then
                        surface.create_entity {
                            name = ore[z],
                            position = { storage.rocket_silo['north'].position.x + x, storage.rocket_silo['north'].position.y + y },
                            amount = ore_amount
                        }
                    end
                end
            end
        end
    end

    for _, rocket_silo in pairs(storage.rocket_silo) do
        local entities = surface.find_entities({ { rocket_silo.position.x - 4, rocket_silo.position.y - 5 }, { rocket_silo.position.x + 4, rocket_silo.position.y + 5 } })
        for _, entity in pairs(entities) do
            if entity.type == 'resource' then
                entity.destroy()
            end
        end
    end
end

event.add(defines.events.on_chunk_generated, on_chunk_generated)

return biter_battles_terrain
