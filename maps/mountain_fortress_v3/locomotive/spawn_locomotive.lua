local Public = require 'maps.mountain_fortress_v3.table'
local ICW = require 'maps.mountain_fortress_v3.icw.main'
local Task = require 'utils.task_token'
local MapFunctions = require 'utils.tools.map_functions'
local Event = require 'utils.event'
local random = math.random
local floor = math.floor

local function initial_cargo_boxes()
    return {
        { name = 'loader',                  count = 1 },
        { name = 'stone-furnace',           count = 2 },
        { name = 'coal',                    count = random(32, 64) },
        { name = 'coal',                    count = random(32, 64) },
        { name = 'loader',                  count = 1 },
        { name = 'iron-ore',                count = random(32, 128) },
        { name = 'copper-ore',              count = random(32, 128) },
        { name = 'submachine-gun',          count = 1 },
        { name = 'loader',                  count = 1 },
        { name = 'submachine-gun',          count = 1 },
        { name = 'submachine-gun',          count = 1 },
        { name = 'stone-furnace',           count = 2 },
        { name = 'submachine-gun',          count = 1 },
        { name = 'submachine-gun',          count = 1 },
        { name = 'loader',                  count = 1 },
        { name = 'submachine-gun',          count = 1 },
        { name = 'automation-science-pack', count = random(4, 32) },
        { name = 'submachine-gun',          count = 1 },
        { name = 'stone-wall',              count = random(4, 32) },
        { name = 'shotgun',                 count = 1 },
        { name = 'shotgun',                 count = 1 },
        { name = 'shotgun',                 count = 1 },
        { name = 'stone-wall',              count = random(4, 32) },
        { name = 'gun-turret',              count = 1 },
        { name = 'gun-turret',              count = 1 },
        { name = 'gun-turret',              count = 1 },
        { name = 'gun-turret',              count = 1 },
        { name = 'stone-wall',              count = random(4, 32) },
        { name = 'shotgun-shell',           count = random(4, 5) },
        { name = 'shotgun-shell',           count = random(4, 5) },
        { name = 'shotgun-shell',           count = random(4, 5) },
        { name = 'gun-turret',              count = 1 },
        { name = 'land-mine',               count = random(6, 18) },
        { name = 'grenade',                 count = random(2, 7) },
        { name = 'grenade',                 count = random(2, 8) },
        { name = 'gun-turret',              count = 1 },
        { name = 'grenade',                 count = random(2, 7) },
        { name = 'light-armor',             count = random(2, 4) },
        { name = 'iron-gear-wheel',         count = random(7, 15) },
        { name = 'iron-gear-wheel',         count = random(7, 15) },
        { name = 'gun-turret',              count = 1 },
        { name = 'iron-gear-wheel',         count = random(7, 15) },
        { name = 'iron-gear-wheel',         count = random(7, 15) },
        { name = 'iron-plate',              count = random(15, 23) },
        { name = 'iron-plate',              count = random(15, 23) },
        { name = 'iron-plate',              count = random(15, 23) },
        { name = 'iron-plate',              count = random(15, 23) },
        { name = 'copper-plate',            count = random(15, 23) },
        { name = 'copper-plate',            count = random(15, 23) },
        { name = 'copper-plate',            count = random(15, 23) },
        { name = 'copper-plate',            count = random(15, 23) },
        { name = 'firearm-magazine',        count = random(10, 56) },
        { name = 'firearm-magazine',        count = random(10, 56) },
        { name = 'firearm-magazine',        count = random(10, 56) },
        { name = 'firearm-magazine',        count = random(10, 56) },
        { name = 'rail',                    count = random(16, 24) },
        { name = 'rail',                    count = random(16, 24) }
    }
end

local place_tiles_token =
    Task.register(
        function (event)
            local surface = event.surface
            if not surface or not surface.valid then
                return
            end
            local position = event.position
            if not position then
                return
            end

            MapFunctions.draw_noise_tile_circle(position, 'black-refined-concrete', surface, 22)
        end
    )

local set_loco_cargo =
    Task.register(
        function (data)
            local surface = data.surface
            if not surface or not surface.valid then
                return
            end

            local cargo_boxes = initial_cargo_boxes()

            local p = {}

            local rad = 16 ^ 2
            for x = -15, 15, 1 do
                for y = 0, 67, 1 do
                    local va = floor((0 - x) ^ 2 + (53 - y) ^ 2)
                    if ((va < rad - 50) and (va > rad - 100)) then
                        if random(1, 3) == 1 then
                            p[#p + 1] = { x = x, y = y }
                        end
                    end
                end
            end

            for i = 1, #cargo_boxes, 1 do
                if not p[i] then
                    break
                end
                local name = 'crash-site-chest-1'

                if random(1, 3) == 1 then
                    name = 'crash-site-chest-2'
                end
                if surface.can_place_entity({ name = name, position = p[i] }) then
                    local e = surface.create_entity({ name = name, position = p[i], force = 'neutral', create_build_effect_smoke = false })
                    e.minable_flag = false
                    e.destructible = true
                    e.health = random(15, 30)
                    local inventory = e.get_inventory(defines.inventory.chest)
                    inventory.insert(cargo_boxes[i])
                end
            end
        end
    )

function Public.locomotive_spawn(surface, position, reversed)
    local this = Public.get()
    local extra_wagons = Public.get_stateful('extra_wagons')

    if not extra_wagons then
        extra_wagons = 0
    end

    local quality = this.space_age and 'legendary' or 'normal'

    if reversed then
        position.y = position.y - (6 * extra_wagons)
        for y = -6, 6, 2 do
            surface.create_entity({ name = 'straight-rail', position = { position.x, position.y + y }, force = 'player', direction = 0 })
        end
        this.locomotive = surface.create_entity({ name = 'locomotive', position = { position.x, position.y + -3 }, force = 'player', direction = defines.direction.south, quality = quality })
        if this.locomotive and this.locomotive.valid then
            this.locomotive.get_inventory(defines.inventory.fuel).insert({ name = 'wood', count = 100 })
        end

        this.locomotive_cargo = surface.create_entity({ name = 'cargo-wagon', position = { position.x, position.y + 3 }, force = 'player', direction = defines.direction.south, quality = quality })
        if this.locomotive_cargo and this.locomotive_cargo.valid then
            this.locomotive_cargo.get_inventory(defines.inventory.cargo_wagon).insert({ name = 'raw-fish', count = 8 })
        end
    else
        for y = -6, 6, 2 do
            surface.create_entity({ name = 'straight-rail', position = { position.x, position.y + y }, force = 'player', direction = 0 })
        end
        this.locomotive = surface.create_entity({ name = 'locomotive', position = { position.x, position.y + -3 }, force = 'player', quality = quality })
        if this.locomotive and this.locomotive.valid then
            this.locomotive.get_inventory(defines.inventory.fuel).insert({ name = 'wood', count = 100 })
        end

        this.locomotive_cargo = surface.create_entity({ name = 'cargo-wagon', position = { position.x, position.y + 3 }, force = 'player', quality = quality })
        if this.locomotive_cargo and this.locomotive_cargo.valid then
            this.locomotive_cargo.get_inventory(defines.inventory.cargo_wagon).insert({ name = 'raw-fish', count = 8 })
        end
    end

    local winter_mode_locomotive = Public.wintery(this.locomotive, 5.5)
    if not winter_mode_locomotive and this.locomotive and this.locomotive.valid then
        rendering.draw_light(
            {
                sprite = 'utility/light_medium',
                scale = 6.5,
                intensity = 1,
                minimum_darkness = 0,
                oriented = true,
                color = { 255, 255, 255 },
                target = this.locomotive,
                surface = surface,
                visible = true,
                only_in_alt_mode = false
            }
        )
    end

    local winter_mode_cargo = Public.wintery(this.locomotive_cargo, 5.5)

    if not winter_mode_cargo and this.locomotive_cargo and this.locomotive_cargo.valid then
        rendering.draw_light(
            {
                sprite = 'utility/light_medium',
                scale = 5.5,
                intensity = 1,
                minimum_darkness = 0,
                oriented = true,
                color = { 255, 255, 255 },
                target = this.locomotive_cargo,
                surface = surface,
                visible = true,
                only_in_alt_mode = false
            }
        )
    end

    local s = 'entity/fish'

    for y = -1, 0, 0.05 do
        local scale = random(50, 100) * 0.01
        rendering.draw_sprite(
            {
                sprite = s,
                orientation = random(0, 100) * 0.01,
                x_scale = scale,
                y_scale = scale,
                tint = { random(60, 255), random(60, 255), random(60, 255) },
                render_layer = 'selection-box',
                target = { entity = this.locomotive_cargo, offset = { -0.7 + random(0, 140) * 0.01, y } },
                surface = surface
            }
        )
    end

    this.locomotive.color = { random(2, 255), random(60, 255), random(60, 255) }
    this.locomotive.minable_flag = false
    this.locomotive_cargo.minable_flag = false
    this.locomotive_cargo.operable = true

    local locomotive = ICW.register_wagon(this.locomotive)
    if not locomotive then
        print('Failed to register locomotive')
        return
    end

    ICW.register_wagon(this.locomotive_cargo)
    this.icw_locomotive = locomotive

    local data = {
        surface = locomotive.surface
    }

    if extra_wagons and extra_wagons > 0 then
        local inc = 7

        local pos = this.locomotive_cargo.position

        local new_position = { x = pos.x, y = pos.y + inc }

        for y = pos.y, new_position.y + (6 * extra_wagons), 2 do
            surface.create_entity({ name = 'straight-rail', position = { new_position.x, y }, force = 'player', direction = 0 })
        end

        for _ = 1, extra_wagons do
            local new_wagon = surface.create_entity({ name = 'cargo-wagon', position = new_position, force = 'player', defines.direction.north })
            if new_wagon and new_wagon.valid then
                new_wagon.minable_flag = false
                new_wagon.operable = true
                inc = inc + 7
                new_position = { x = pos.x, y = pos.y + inc }
                ICW.register_wagon(new_wagon)
            end
        end
    end

    local all_the_fish = Public.get('all_the_fish')
    if all_the_fish then
        this.locomotive_cargo.get_inventory(defines.inventory.cargo_wagon).insert({ name = 'raw-fish', count = 999999 })
    end

    Task.set_timeout_in_ticks(15, place_tiles_token, { surface = surface, position = position })
    Task.set_timeout_in_ticks(50, set_loco_cargo, data)

    game.forces.player.set_spawn_position({ this.locomotive.position.x - 5, this.locomotive.position.y }, locomotive.surface)
end

Event.add(Public.events.on_locomotive_cargo_missing, function ()
    local locomotive_cargo = Public.get('locomotive_cargo')
    if not locomotive_cargo or not locomotive_cargo.valid then
        return
    end

    local wagons = ICW.get('wagons')
    if wagons[locomotive_cargo.unit_number] then
        log('Locomotive cargo missing, setting new cargo')
        Public.set('icw_locomotive', wagons[locomotive_cargo.unit_number])
    end
end)

return Public
