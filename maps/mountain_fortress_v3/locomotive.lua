local Event = require 'utils.event'
local Public = require 'maps.mountain_fortress_v3.table'
local ICW = require 'maps.mountain_fortress_v3.icw.main'
local ICFunctions = require 'maps.mountain_fortress_v3.ic.functions'
local Session = require 'utils.datastore.session_data'
local Difficulty = require 'modules.difficulty_vote_by_amount'
local RPG = require 'modules.rpg.main'
local Gui = require 'utils.gui'
local Alert = require 'utils.alert'
local Color = require 'utils.color_presets'
local Modifiers = require 'utils.player_modifiers'
local Core = require 'utils.core'
local Task = require 'utils.task_token'

local zone_settings = Public.zone_settings
local scenario_name = Public.scenario_name

local rpg_main_frame = RPG.main_frame_name
local random = math.random
local floor = math.floor
local round = math.round
local sub = string.sub
local playtime_required_to_drive_train = 108000 --30 minutes

local clear_items_upon_surface_entry = {
    ['entity-ghost'] = true,
    ['small-electric-pole'] = true,
    ['medium-electric-pole'] = true,
    ['big-electric-pole'] = true,
    ['substation'] = true
}

local valid_armors = {
    ['modular-armor'] = true,
    ['power-armor'] = true,
    ['power-armor-mk2'] = true
}

local non_valid_vehicles = {
    ['car'] = true,
    ['spider-vehicle'] = true
}

local denied_train_types = {
    ['locomotive'] = true,
    ['cargo-wagon'] = true,
    ['artillery-wagon'] = true
}

Public.check_if_spawning_near_train_custom_callback =
    Task.register(
        function (event)
            local entity = event.entity
            local disable_spawn_near_target = event.disable_spawn_near_target

            if Public.is_around_train(entity) and disable_spawn_near_target then
                return true
            end

            return false
        end
    )

local function add_random_loot_to_main_market(rarity)
    local main_market_items = Public.get('main_market_items')
    local items = Public.get_random_item(rarity, true, false)
    if not items then
        return false
    end

    local types = prototypes.item

    for k, v in pairs(main_market_items) do
        if not v.static then
            main_market_items[k] = nil
        end
    end

    for _, v in pairs(items) do
        local price = v.price[1].count + random(1, 15) * rarity
        local value = v.price[1].name
        local stack = 1
        if v.offer.item == 'coin' then
            price = v.price[1].count
            stack = v.offer.count
            if not stack then
                stack = v.price[1].count
            end
        end

        if not main_market_items[v.offer.item] then
            main_market_items[v.offer.item] = {
                stack = stack,
                value = value,
                price = price,
                tooltip = types[v.offer.item].localised_name,
                upgrade = false
            }
        end
    end
end

local function death_effects(player)
    local position = { x = player.physical_position.x - 0.75, y = player.physical_position.y - 1 }
    local b = 0.75
    for _ = 1, 5, 1 do
        local p = {
            (position.x + 0.4) + (b * -1 + math.random(0, b * 20) * 0.1),
            position.y + (b * -1 + math.random(0, b * 20) * 0.1)
        }

        player.create_local_flying_text(
            {
                position = p,
                text = '☠️',
            }
        )
    end
    player.play_sound { path = 'utility/axe_fighting', volume_modifier = 0.9 }
end

local messages = {
    ' likes to play in magma.',
    ' got melted.',
    ' tried to swim in lava.',
    ' was incinerated.',
    " couldn't put the fire out.",
    ' was turned into their molten form.'
}

local function is_around_train(data)
    local entity = data.entity
    local locomotive_aura_radius = data.locomotive_aura_radius
    local loco = data.locomotive.position
    local position = entity.position
    local inside = ((position.x - loco.x) ^ 2 + (position.y - loco.y) ^ 2) < locomotive_aura_radius ^ 2

    if inside then
        return true
    end
    return false
end

local function is_inside_zone(data)
    local entity = data.entity
    local loco = data.locomotive.position
    local position = entity.position
    local inside = ((position.y - loco.y) ^ 2) < zone_settings.zone_depth ^ 2

    if inside then
        return true
    end
    return false
end

local function hurt_players_outside_of_aura()
    local Diff = Difficulty.get()
    if not Diff then
        return
    end
    local difficulty_set = Public.get('difficulty_set')
    if not difficulty_set then
        return
    end
    local death_mode = false
    if Diff.index == 1 then
        return
    elseif Diff.index == 3 then
        death_mode = true
    end

    local loco_surface = Public.get('loco_surface')
    if not (loco_surface and loco_surface.valid) then
        return
    end
    local locomotive = Public.get('locomotive')
    if not locomotive or not locomotive.valid then
        return
    end

    local loco = locomotive.position

    local upgrades = Public.get('upgrades')

    Core.iter_connected_players(
        function (player)
            if sub(player.physical_surface.name, 0, #scenario_name) == scenario_name then
                local position = player.physical_position
                local inside = ((position.x - loco.x) ^ 2 + (position.y - loco.y) ^ 2) < upgrades.locomotive_aura_radius ^ 2
                if not inside then
                    local entity = player.character
                    if entity and entity.valid then
                        death_effects(player)
                        player.physical_surface.create_entity({ name = 'fire-flame', position = position })
                        if random(1, 3) == 1 then
                            player.physical_surface.create_entity({ name = 'medium-scorchmark', position = position, force = 'neutral' })
                        end
                        local max_health = floor(player.character.max_health + player.character_health_bonus + player.force.character_health_bonus)
                        local vehicle = player.physical_vehicle
                        if vehicle and vehicle.valid and non_valid_vehicles[vehicle.type] then
                            player.driving = false
                        end
                        if death_mode then
                            if entity.name == 'character' then
                                game.print(player.name .. messages[random(1, #messages)], { r = 200, g = 0, b = 0 })
                            end
                            if entity.valid then
                                entity.die()
                            end
                        else
                            local armor_inventory = player.get_inventory(defines.inventory.character_armor)
                            if not armor_inventory.valid then
                                goto pre_exit
                            end
                            local armor = armor_inventory[1]
                            if not armor.valid_for_read then
                                goto pre_exit
                            end
                            local grid = armor.grid
                            if not grid or not grid.valid then
                                goto pre_exit
                            end
                            local equip = grid.equipment
                            for _, piece in pairs(equip) do
                                if piece.valid then
                                    piece.energy = 0
                                end
                            end
                            local damage = (max_health / 18)
                            if entity.valid then
                                if entity.health - damage <= 0 then
                                    if entity.name == 'character' then
                                        game.print(player.name .. messages[random(1, #messages)], { r = 200, g = 0, b = 0 })
                                    end
                                end
                            end
                            entity.damage(damage, 'enemy')
                        end
                    end
                end
            end
            ::pre_exit::
        end
    )
end
local function give_passive_xp(data)
    local xp_floating_text_color = { r = 188, g = 201, b = 63 }
    local visuals_delay = 1800
    local loco_surface = Public.get('loco_surface')
    if not (loco_surface and loco_surface.valid) then
        return
    end
    local upgrades = Public.get('upgrades')
    local locomotive = Public.get('locomotive')
    if not locomotive or not locomotive.valid then
        return
    end
    local rpg = data.rpg
    local loco = locomotive.position

    Core.iter_connected_players(
        function (player)
            local position = player.physical_position
            local inside = ((position.x - loco.x) ^ 2 + (position.y - loco.y) ^ 2) < upgrades.locomotive_aura_radius ^ 2
            if player.afk_time < 200 and not RPG.get_last_spell_cast(player) then
                if inside or player.physical_surface.index == loco_surface.index then
                    if player.physical_surface.index == loco_surface.index then
                        Public.add_player_to_permission_group(player, 'limited')
                    elseif ICFunctions.get_player_surface(player) then
                        Public.add_player_to_permission_group(player, 'limited')
                        goto pre_exit
                    else
                        Public.add_player_to_permission_group(player, 'near_locomotive')
                    end

                    rpg[player.index].inside_aura = true
                    Modifiers.update_single_modifier(player, 'character_crafting_speed_modifier', 'aura', 1)
                    Modifiers.update_player_modifiers(player)

                    local pos = player.physical_position
                    RPG.gain_xp(player, 0.5 * (rpg[player.index].bonus + upgrades.xp_points))

                    player.create_local_flying_text {
                        text = '+' .. '',
                        position = { x = pos.x, y = pos.y - 2 },
                        color = xp_floating_text_color,
                    }
                    rpg[player.index].xp_since_last_floaty_text = 0
                    rpg[player.index].last_floaty_text = game.tick + visuals_delay
                    RPG.set_last_spell_cast(player, player.physical_position)
                    if player.gui.screen[rpg_main_frame] then
                        local f = player.gui.screen[rpg_main_frame]
                        local d = Gui.get_data(f)
                        if d and d.exp_gui and d.exp_gui.valid then
                            d.exp_gui.caption = floor(rpg[player.index].xp)
                        end
                    end
                else
                    rpg[player.index].inside_aura = false
                    Modifiers.update_single_modifier(player, 'character_crafting_speed_modifier', 'aura', 0)
                    Modifiers.update_player_modifiers(player)
                    local active_surface_index = Public.get('active_surface_index')
                    local surface = game.surfaces[active_surface_index]
                    if surface and surface.valid then
                        if player.physical_surface.index == surface.index then
                            Public.add_player_to_permission_group(player, 'main_surface')
                        end
                    end
                end
            elseif player.afk_time > 1800 and player.character and player.physical_surface.index == loco_surface.index and player.get_requester_point() then
                player.get_requester_point().enabled = false
            end
            ::pre_exit::
        end
    )
end

local function fish_tag()
    local locomotive_cargo = Public.get('locomotive_cargo')
    if not (locomotive_cargo and locomotive_cargo.valid) then
        return
    end
    if not (locomotive_cargo.surface and locomotive_cargo.surface.valid) then
        return
    end

    local locomotive_tag = Public.get('locomotive_tag')

    if locomotive_tag then
        if locomotive_tag.valid then
            if locomotive_tag.position.x == locomotive_cargo.position.x and locomotive_tag.position.y == locomotive_cargo.position.y then
                return
            end
            locomotive_tag.destroy()
        end
    end
    Public.set(
        'locomotive_tag',
        locomotive_cargo.force.add_chart_tag(
            locomotive_cargo.surface,
            {
                icon = { type = 'item', name = 'raw-fish' },
                position = locomotive_cargo.position,
                text = ' '
            }
        )
    )
end

local function set_player_spawn()
    local locomotive = Public.get('locomotive')
    if not locomotive then
        return
    end
    if not locomotive.valid then
        return
    end

    local position = locomotive.surface.find_non_colliding_position('stone-furnace', locomotive.position, 16, 2)
    if not position then
        return
    end
    game.forces.player.set_spawn_position({ x = position.x, y = position.y }, locomotive.surface)
end

local function refill_fish()
    local locomotive_cargo = Public.get('locomotive_cargo')
    if not locomotive_cargo then
        return
    end
    if not locomotive_cargo.valid then
        return
    end
    locomotive_cargo.get_inventory(defines.inventory.cargo_wagon).insert({ name = 'raw-fish', count = random(2, 5) })
end

local function set_carriages()
    local locomotive = Public.get('locomotive')
    if not locomotive or not locomotive.valid then
        return
    end

    if not locomotive.train then
        return
    end

    local carriages = locomotive.train.carriages
    local t = {}
    for i = 1, #carriages do
        local e = carriages[i]
        if (e and e.valid) then
            e.destructible = true
            t[e.unit_number] = true
        end
    end

    Public.set('carriages_numbers', t)
    Public.set('carriages', locomotive.train.carriages)
end

local function get_driver_action(entity)
    if not entity or not entity.valid then
        return
    end

    local driver = entity.get_driver()
    if not driver or not driver.valid then
        return
    end

    local player
    if driver and driver.valid and driver.is_player() then
        player = driver
    else
        player = driver.player
    end
    if not player or not player.valid then
        return
    end

    if Session.get_session_player(player) then
        local total_time = player.online_time + Session.get_session_player(player)

        if total_time and total_time < playtime_required_to_drive_train then
            player.print('[color=blue][Locomotive][/color] Not enough playtime acquired to drive the train.')
            driver.driving = false
            return
        end
    end

    if player.cursor_stack and player.cursor_stack.valid_for_read and player.cursor_stack.name == 'raw-fish' then
        player.print('[color=blue][Locomotive][/color] Unequip your fishy if you want to drive.')
        driver.driving = false
        return
    end

    local armor = driver.get_inventory(defines.inventory.character_armor)
    if armor and armor[1] and armor[1].valid_for_read and valid_armors[armor[1].name] then
        player.print('[color=blue][Locomotive][/color] Unequip your armor if you want to drive.')
        driver.driving = false
    end
end


local function check_health(locomotive_health, locomotive_max_health)
    local m = locomotive_health / locomotive_max_health
    if locomotive_health > locomotive_max_health then
        Public.set('locomotive_health', locomotive_max_health)
    end



    local health_text = Public.get('health_text')
    if health_text and health_text.valid then
        health_text.text = 'HP: ' .. round(locomotive_health) .. ' / ' .. round(locomotive_max_health)
    end

    local carriages = Public.get('carriages')
    if carriages then
        for i = 1, #carriages do
            local entity = carriages[i]
            if not (entity and entity.valid) then
                return
            end
            get_driver_action(entity)
            if entity.type == 'locomotive' then
                entity.health = entity.max_health * m
            else
                entity.health = entity.max_health * m
            end
        end
    end
end

local function set_locomotive_health()
    local locomotive_health = Public.get('locomotive_health')
    local locomotive_max_health = Public.get('locomotive_max_health')
    local locomotive = Public.get('locomotive')

    if not locomotive or not locomotive.valid then
        return
    end

    Public.set('locomotive_position', locomotive.position)

    if locomotive_health <= 0 then
        Public.game_is_over()
        Public.set('locomotive_health', 0)
    end

    check_health(locomotive_health, locomotive_max_health)
end

local function validate_index()
    local locomotive = Public.get('locomotive')
    if not locomotive then
        return
    end
    if not locomotive.valid then
        return
    end

    local icw_table = ICW.get_table()
    local icw_locomotive = Public.get('icw_locomotive')
    if not icw_locomotive then
        Event.raise(Public.events.on_locomotive_cargo_missing)
        return
    end
    local loco_surface = icw_locomotive.surface
    local unit_surface = locomotive.unit_number
    local locomotive_surface = game.surfaces[icw_table.wagons[unit_surface].surface.index]
    if loco_surface.valid then
        Public.set('loco_surface', locomotive_surface)
    end
end

local function on_research_finished(event)
    local research = event.research
    if not research then
        return
    end

    local name = research.name

    if name == 'discharge-defense-equipment' then
        local message = ({ 'locomotive.discharge_unlocked' })
        Alert.alert_all_players(15, message, nil, 'achievement/tech-maniac', 0.1)
    end

    if name == 'artillery' then
        local message = ({ 'locomotive.artillery_unlocked' })
        Alert.alert_all_players(15, message, nil, 'achievement/tech-maniac', 0.1)
    end

    local locomotive = Public.get('locomotive')
    if not locomotive or not locomotive.valid then
        return
    end

    local market_announce = Public.get('market_announce')
    if market_announce > game.tick then
        return
    end

    local breached_wall = Public.get('breached_wall')
    add_random_loot_to_main_market(breached_wall)
    local message = ({ 'locomotive.new_items_at_market' })
    Alert.alert_all_players(5, message, nil, 'achievement/tech-maniac', 0.1)
    Public.refresh_gui()
end

local function on_player_changed_surface(event)
    local player = game.players[event.player_index]
    if not player or not player.valid then
        return
    end

    if not Public.is_task_done() then return end

    local active_surface = Public.get('active_surface_index')
    local surface = game.surfaces[active_surface]
    if not surface or not surface.valid then
        return
    end

    local item_ghost = player.cursor_ghost
    if item_ghost then
        player.cursor_ghost = nil
    end

    local item = player.cursor_stack
    if item and item.valid_for_read then
        local name = item.name
        if clear_items_upon_surface_entry[name] then
            player.cursor_stack.clear()
        end
    end

    local locomotive_surface = Public.get('loco_surface')

    if locomotive_surface and locomotive_surface.valid and player.physical_surface.index == locomotive_surface.index then
        return Public.add_player_to_permission_group(player, 'limited')
    elseif ICFunctions.get_player_surface(player) then
        return Public.add_player_to_permission_group(player, 'limited')
    elseif player.physical_surface.index == surface.index then
        return Public.add_player_to_permission_group(player, 'main_surface')
    end
end

local function on_player_driving_changed_state(event)
    local player = game.players[event.player_index]
    if not player or not player.valid then
        return
    end
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    local trusted = Session.get_trusted_table()
    if #trusted == 0 then
        return
    end

    local locomotive = Public.get('locomotive')
    if not locomotive or not locomotive.valid then
        return
    end

    if entity.unit_number == locomotive.unit_number then
        if not trusted[player.name] then
            if player.character and player.character.valid and player.character.driving then
                player.character.driving = false
            end
        end
    end
end

local function on_gui_opened(event)
    local player = game.players[event.player_index]
    if not player or not player.valid then
        return
    end
    local entity = event.entity
    if not entity or not entity.valid then
        return
    end

    if not denied_train_types[entity.type] then
        return
    end

    local block_non_trusted_opening_trains = Public.get('block_non_trusted_opening_trains')
    if not block_non_trusted_opening_trains then
        return
    end

    local trusted_player = Session.get_trusted_player(player)

    if not trusted_player then
        player.print('[Antigrief] You have not grown accustomed to this technology yet.', { color = Color.warning })
        player.opened = nil
    end
end

function Public.boost_players_around_train()
    if not Public.is_task_done() then return end

    local rpg = RPG.get('rpg_t')
    local active_surface_index = Public.get('active_surface_index')
    if not active_surface_index then
        return
    end
    local locomotive = Public.get('locomotive')
    if not (locomotive and locomotive.valid) then
        return
    end
    local surface = game.surfaces[active_surface_index]
    local icw_table = ICW.get_table()
    local unit_surface = locomotive.unit_number
    local locomotive_surface = game.surfaces[icw_table.wagons[unit_surface].surface.index]

    local data = {
        surface = surface,
        locomotive_surface = locomotive_surface,
        rpg = rpg
    }
    give_passive_xp(data)
end

function Public.is_around_train_simple(player)
    if not player or not player.valid then
        return
    end
    local inside_aura = RPG.get_value_from_player(player.index, 'inside_aura')
    return inside_aura
end

function Public.is_around_train(entity)
    local locomotive = Public.get('locomotive')
    local active_surface_index = Public.get('active_surface_index')

    if not active_surface_index then
        return false
    end
    if not locomotive then
        return false
    end
    if not locomotive.valid then
        return false
    end

    if not entity or not entity.valid then
        return false
    end

    local surface = game.surfaces[active_surface_index]
    local upgrades = Public.get('upgrades')

    local data = {
        locomotive = locomotive,
        surface = surface,
        entity = entity,
        locomotive_aura_radius = upgrades.locomotive_aura_radius
    }

    local success = is_around_train(data)
    return success
end

function Public.is_inside_zone(entity)
    local locomotive = Public.get('locomotive')
    local active_surface_index = Public.get('active_surface_index')

    if not active_surface_index then
        return false
    end
    if not locomotive then
        return false
    end
    if not locomotive.valid then
        return false
    end

    if not entity or not entity.valid then
        return false
    end

    local surface = game.surfaces[active_surface_index]

    local data = {
        locomotive = locomotive,
        surface = surface,
        entity = entity
    }

    local success = is_inside_zone(data)
    return success
end

function Public.render_train_hp()
    local active_surface_index = Public.get('active_surface_index')
    local surface = game.surfaces[active_surface_index]

    local locomotive_health = Public.get('locomotive_health')
    local locomotive_max_health = Public.get('locomotive_max_health')
    local upgrades = Public.get('upgrades')
    local locomotive = Public.get('locomotive')
    if not locomotive or not locomotive.valid then
        return
    end
    local locomotive_cargo = Public.get('locomotive_cargo')
    if not locomotive_cargo or not locomotive_cargo.valid then
        return
    end

    local health_text = Public.get('health_text')

    if health_text and health_text.valid then
        health_text.destroy()
    end

    Public.set(
        'health_text',
        rendering.draw_text {
            text = 'HP: ' .. locomotive_health .. ' / ' .. locomotive_max_health,
            surface = surface,
            target = locomotive,
            color = locomotive.color,
            scale = 1.40,
            font = 'default-game',
            alignment = 'center',
            scale_with_zoom = false
        }
    )

    Public.set(
        'caption',
        rendering.draw_text {
            text = 'Comfy Choo Choo',
            surface = surface,
            target = locomotive_cargo,
            color = locomotive.color,
            scale = 1.80,
            font = 'default-game',
            alignment = 'center',
            scale_with_zoom = false
        }
    )

    Public.set(
        'circle',
        rendering.draw_circle {
            surface = surface,
            target = locomotive,
            color = locomotive.color,
            filled = false,
            radius = upgrades.locomotive_aura_radius,
            only_in_alt_mode = true
        }
    )
end

function Public.transfer_pollution()
    local locomotive = Public.get('locomotive')
    if not locomotive or not locomotive.valid then
        return
    end

    local active_surface_index = Public.get('active_surface_index')
    local active_surface = game.surfaces[active_surface_index]
    if not active_surface or not active_surface.valid then
        return
    end

    local icw_locomotive = Public.get('icw_locomotive')
    if not icw_locomotive or not icw_locomotive.valid then
        return
    end
    local surface = icw_locomotive.surface
    if not surface or not surface.valid then
        return
    end

    local total_interior_pollution = surface.get_total_pollution()

    local pollution = surface.get_total_pollution() * (3 / (4 / 3 + 1)) * Difficulty.get().value
    active_surface.pollute(locomotive.position, pollution)
    game.get_pollution_statistics(surface).on_flow('locomotive', pollution - total_interior_pollution)
    surface.clear_pollution()
end

local boost_players = Public.boost_players_around_train
local pollute_area = Public.transfer_pollution

local function tick()
    local ticker = game.tick

    if ticker % 30 == 0 then
        -- check_on_player_changed_surface()
        set_locomotive_health()
        validate_index()
        fish_tag()
        hurt_players_outside_of_aura()
    end

    if ticker % 120 == 0 then
        -- tp_player()

        boost_players()
    end

    if ticker % 1200 == 0 then
        set_player_spawn()
        refill_fish()
    end

    if ticker % 2500 == 0 then
        pollute_area()
    end
end

Event.on_nth_tick(5, tick)
Event.on_nth_tick(150, set_carriages)

Event.add(defines.events.on_research_finished, on_research_finished)
Event.add(defines.events.on_player_changed_surface, on_player_changed_surface)
Event.add(defines.events.on_player_driving_changed_state, on_player_driving_changed_state)
Event.add(defines.events.on_train_created, set_carriages)
Event.add(defines.events.on_gui_opened, on_gui_opened)

return Public
