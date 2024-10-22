local Chrono_table = require 'maps.chronosphere.table'
local Balance = require 'maps.chronosphere.balance'
local Difficulty = require 'modules.difficulty_vote'
local MFunctions = require 'maps.chronosphere.world_functions'
local Server = require 'utils.server'
local Public = {}

local math_random = math.random
local math_floor = math.floor
local math_ceil = math.ceil
local math_min = math.min
local math_cos = math.cos
local math_sin = math.sin
local math_rad = math.rad

function Public.realtime_events()
    local objective = Chrono_table.get_table()

    if objective.world.id == 2 and objective.world.variant.id == 2 then
        if objective.passivetimer == 10 then
            game.print({'chronosphere.message_danger1'}, {r = 0.98, g = 0.66, b = 0.22})
            game.print({'chronosphere.message_danger2'}, {r = 0.98, g = 0.66, b = 0.22})
        elseif objective.passivetimer == 25 then
            game.print({'chronosphere.message_danger3'}, {r = 0.98, g = 0, b = 0})
        elseif objective.passivetimer == 30 then
            game.print({'chronosphere.message_danger4'}, {r = 0.98, g = 0, b = 0})
            game.print({'chronosphere.message_danger5'}, {r = 0.98, g = 0.66, b = 0.22})
        end
    end

    if
        objective.jump_countdown_start_time == -1 and objective.passivetimer == math_floor(objective.chronochargesneeded * 0.50 / objective.passive_chronocharge_rate) and
            objective.chronojumps >= Balance.jumps_until_overstay_is_on(Difficulty.get().difficulty_vote_value)
     then
        game.print({'chronosphere.message_rampup50'}, {r = 0.98, g = 0.66, b = 0.22})
    end

    if objective.game_lost then
        return
    end
    if objective.jump_countdown_start_time ~= -1 then
        if objective.passivetimer == objective.jump_countdown_start_time + 180 - 60 then
            game.print({'chronosphere.message_jump60'}, {r = 0.98, g = 0.66, b = 0.22})
        elseif objective.passivetimer == objective.jump_countdown_start_time + 180 - 30 then
            game.print({'chronosphere.message_jump30'}, {r = 0.98, g = 0.66, b = 0.22})
        elseif objective.passivetimer >= objective.jump_countdown_start_time + 180 - 10 and objective.jump_countdown_start_time + 180 - objective.passivetimer > 0 then
            game.print({'chronosphere.message_jump10', objective.jump_countdown_start_time + 180 - objective.passivetimer}, {r = 0.98, g = 0.66, b = 0.22})
        end
    end
end

function Public.train_pollution(source, interior_pollution)
    local objective = Chrono_table.get_table()
    local difficulty = Difficulty.get().difficulty_vote_value
    if not objective.locomotive.valid then
        return
    end
    local pos = objective.locomotive.position or {x = 0, y = 0}
    local pollution = 0
    local stat_target = 'locomotive'
    if not interior_pollution then
        interior_pollution = 0
    end
    if source == 'passive' then
        stat_target = 'heat-pipe'
        pollution = Balance.passive_pollution_rate(objective.chronojumps, difficulty, objective.upgrades[2])
    elseif source == 'countdown' then
        stat_target = 'electric-energy-interface'
        pollution = Balance.countdown_pollution_rate(objective.chronojumps, difficulty)
    elseif source == 'postjump' then
        stat_target = 'heat-interface'
        pollution = math_floor(Balance.post_jump_initial_pollution(objective.chronojumps, difficulty))
    elseif source == 'accumulators' then
        stat_target = 'accumulator'
        pollution = Balance.pollution_per_MJ_actively_charged(objective.chronojumps, difficulty, objective.upgrades[2])
    elseif source == 'lasers' then
        stat_target = 'laser-turret'
        pollution = Balance.pollution_per_MJ_actively_charged(objective.chronojumps, difficulty, objective.upgrades[2]) / 10
    elseif source == 'wagons' then
        pollution = interior_pollution * Balance.machine_pollution_transfer_from_inside_factor(difficulty, objective.upgrades[2])
    end
    local surface = game.surfaces[objective.active_surface_index]
    surface.pollute(pos, pollution)
    game.get_pollution_statistics(surface).on_flow(stat_target, pollution - interior_pollution)
end

function Public.transfer_pollution()
    local objective = Chrono_table.get_table()
    local surface = game.surfaces['cargo_wagon']
    if not surface or not objective.locomotive.valid then
        return
    end
    Public.train_pollution('wagons', surface.get_total_pollution())
    surface.clear_pollution()
end

function Public.ramp_evolution()
    local objective = Chrono_table.get_table()
    local difficulty = Difficulty.get().difficulty_vote_value

    if
        objective.passivetimer * objective.passive_chronocharge_rate > objective.chronochargesneeded * 0.50 and
            objective.chronojumps >= Balance.jumps_until_overstay_is_on(Difficulty.get().difficulty_vote_value)
     then
        local evolution = game.forces.enemy.get_evolution_factor(game.get_surface(objective.active_surface_index))
        evolution = evolution * Balance.evoramp50_multiplier_per_10s(difficulty)
        if evolution > 1 then
            evolution = 1
        end
        game.forces.enemy.set_evolution_factor(evolution, game.get_surface(objective.active_surface_index))
    end
end

local function revalidate_inventories()
    local objective = Chrono_table.get_table()
    if not objective.comfychests or not objective.comfychests2 then
        return
    end
    if not objective.comfychest_invs or not objective.comfychest_invs2 then
        return
    end
    for i = 1, 24, 1 do
        objective.comfychest_invs[i] = objective.comfychests[i].get_inventory(defines.inventory.chest)
        objective.comfychest_invs2[i] = objective.comfychests2[i].get_inventory(defines.inventory.chest)
    end
end

function Public.move_items()
    local objective = Chrono_table.get_table()
    if not objective.comfychests or not objective.comfychests2 then
        return
    end
    if not objective.comfychest_invs or not objective.comfychest_invs2 then
        return
    end
    if objective.game_lost == true then
        return
    end
    local input, input_inventory = objective.comfychests, objective.comfychest_invs
    local output, output_inventory = objective.comfychests2, objective.comfychest_invs2
    for i = 1, 24, 1 do
        if not input[i].valid or not output[i].valid then
            return
        end
        if not input_inventory[i].valid or not output_inventory[i].valid then
            revalidate_inventories()
            return
        end

        input_inventory[i].sort_and_merge()
        output_inventory[i].sort_and_merge()
        for ii = 1, #input_inventory[i], 1 do
            if input_inventory[i][ii].valid_for_read then
                local count = output_inventory[i].insert(input_inventory[i][ii])
                input_inventory[i][ii].count = input_inventory[i][ii].count - count
            else
                break
            end
        end
    end
end

local function transfer_signals(index, inventory)
    local objective = Chrono_table.get_table()
    if not objective.outcombinators then
        return
    end
    local counts = inventory.get_contents()
    local combi = objective.outcombinators[index].get_or_create_control_behavior()
    local i = 1
    for name, count in pairs(counts) do
        if i > 20 then
            break
        end
        combi.set_signal(i, {signal = {type = 'item', name = name}, count = count})
        i = i + 1
    end
    if i < 20 then
        for j = i, 20, 1 do
            combi.set_signal(j, nil)
        end
    end
end

function Public.output_items()
    local objective = Chrono_table.get_table()
    if objective.game_lost == true then
        return
    end
    if not objective.outchests then
        return
    end
    if not objective.locomotive_cargo[2] then
        return
    end
    if not objective.locomotive_cargo[3] then
        return
    end
    if objective.upgrades[8] < 1 then
        return
    end
    local wagon = {
        [1] = objective.locomotive_cargo[2].get_inventory(defines.inventory.cargo_wagon),
        [2] = objective.locomotive_cargo[3].get_inventory(defines.inventory.cargo_wagon)
    }
    for i = 1, 4, 1 do
        if not objective.outchests[i].valid then
            return
        end
        local inv = objective.outchests[i].get_inventory(defines.inventory.chest)
        inv.sort_and_merge()
        for ii = 1, #inv, 1 do
            if inv[ii].valid_for_read then
                local count = wagon[math_ceil(i / 2)].insert(inv[ii])
                inv[ii].count = inv[ii].count - count
            else
                break
            end
        end
        if objective.upgrades[8] == 2 then
            transfer_signals(i, wagon[math_ceil(i / 2)])
        end
    end
end

function Public.repair_train()
    local objective = Chrono_table.get_table()
    if not game.surfaces['cargo_wagon'] then
        return 0
    end
    if objective.game_lost == true then
        return 0
    end
    local count = 0
    local chest = objective.upgradechest[0]
    if not chest or not chest.valid then
        return
    end
    local inv = chest.get_inventory(defines.inventory.chest)
    if objective.health < objective.max_health then
        count = inv.get_item_count('repair-pack')
        count = math_min(count, objective.upgrades[6] + 1, math_ceil((objective.max_health - objective.health) / Balance.Chronotrain_HP_repaired_per_pack))
        if count > 0 then
            inv.remove({name = 'repair-pack', count = count})
        end
    end
    return count * -Balance.Chronotrain_HP_repaired_per_pack
end

local function create_poison_cloud(position)
    local objective = Chrono_table.get_table()
    local surface = game.surfaces[objective.active_surface_index]

    local tile = surface.get_tile(position.x, position.y)
    if not tile then
        return
    end
    if not tile.valid then
        return
    end
    if tile.name == 'water-shallow' or tile.name == 'water-mud' then
        local random_angles = {math_rad(math_random(359)), math_rad(math_random(359)), math_rad(math_random(359)), math_rad(math_random(359))}

        surface.create_entity({name = 'poison-cloud', position = {x = position.x, y = position.y}})
        surface.create_entity({name = 'poison-cloud', position = {x = position.x + 12 * math_cos(random_angles[1]), y = position.y + 12 * math_sin(random_angles[1])}})
        surface.create_entity({name = 'poison-cloud', position = {x = position.x + 12 * math_cos(random_angles[2]), y = position.y + 12 * math_sin(random_angles[2])}})
        surface.create_entity({name = 'poison-cloud', position = {x = position.x + 12 * math_cos(random_angles[3]), y = position.y + 12 * math_sin(random_angles[3])}})
        surface.create_entity({name = 'poison-cloud', position = {x = position.x + 12 * math_cos(random_angles[4]), y = position.y + 12 * math_sin(random_angles[4])}})
    end
end

function Public.spawn_poison()
    local random_x = math_random(-460, 460)
    local random_y = math_random(-460, 460)
    create_poison_cloud {x = random_x, y = random_y}
    if math_random(1, 3) == 1 then
        local random_angles = {math_rad(math_random(359))}
        create_poison_cloud {x = random_x + 24 * math_cos(random_angles[1]), y = random_y + 24 * math_sin(random_angles[1])}
    end
end

local function launch_nukes()
    local objective = Chrono_table.get_table()
    local surface = game.surfaces[objective.active_surface_index]
    if objective.dangers and #objective.dangers > 1 then
        local max_range = 800
        local nukes_launched = 0
        if objective.upgrades[17] == 1 then
            max_range = 100
        end
        for i = 1, #objective.dangers, 1 do
            if objective.dangers[i].destroyed == false then
                local fake_shooter = surface.create_entity({name = 'character', position = objective.dangers[i].silo.position, force = 'enemy'})
                surface.create_entity(
                    {
                        name = 'atomic-rocket',
                        position = objective.dangers[i].silo.position,
                        force = 'enemy',
                        speed = 1,
                        max_range = max_range,
                        target = objective.locomotive,
                        source = fake_shooter
                    }
                )
                game.print({'chronosphere.message_nuke'}, {r = 0.98, g = 0, b = 0})
                nukes_launched = nukes_launched + 1
            end
        end
        if max_range == 100 and nukes_launched > 0 then
            game.print({'chronosphere.message_nuke_intercepted'}, {r = 0, g = 0.98, b = 0})
            objective.upgrades[17] = 0
        end
    end
end

function Public.dangertimer()
    local objective = Chrono_table.get_table()
    local timer = objective.dangertimer
    if timer == 0 then
        return
    end
    if objective.world.id == 2 and objective.world.variant.id == 2 then
        timer = timer - 1
        if objective.dangers and #objective.dangers > 0 then
            for i = 1, #objective.dangers, 1 do
                if objective.dangers[i].destroyed == false then
                    if timer == 15 then
                        objective.dangers[i].silo.launch_rocket()
                        objective.dangers[i].silo.rocket_parts = 100
                    end
                    objective.dangers[i].timer.text = math_floor(timer / 60) .. ' min, ' .. timer % 60 .. ' s'
                end
            end
        end
    else
        timer = 1200
    end
    if timer < 0 then
        timer = 0
    end
    if timer == 0 then
        launch_nukes()
        timer = 90
    end

    objective.dangertimer = timer
end

function Public.offline_players()
    local objective = Chrono_table.get_table()
    local playertable = Chrono_table.get_player_table()
    if objective.chronocharges >= objective.chronochargesneeded or objective.passivetimer < 30 then
        return
    end
    --local current_tick = game.tick
    local players = playertable.offline_players
    local surface = game.surfaces[objective.active_surface_index]
    if #players > 0 then
        --log("nonzero offline players")
        local later = {}
        for i = 1, #players, 1 do
            if players[i] and game.players[players[i].index] and game.players[players[i].index].connected then
                --game.print("deleting already online character from list")
                players[i] = nil
            else
                if players[i] and players[i].tick < game.tick - 72000 then
                    --log("spawning corpse")
                    local player_inv = {}
                    local items = {}
                    player_inv[1] = game.players[players[i].index].get_inventory(defines.inventory.character_main)
                    player_inv[2] = game.players[players[i].index].get_inventory(defines.inventory.character_armor)
                    player_inv[3] = game.players[players[i].index].get_inventory(defines.inventory.character_guns)
                    player_inv[4] = game.players[players[i].index].get_inventory(defines.inventory.character_ammo)
                    player_inv[5] = game.players[players[i].index].get_inventory(defines.inventory.character_trash)
                    local e = surface.create_entity({name = 'character', position = game.forces.player.get_spawn_position(surface), force = 'neutral'})
                    local inv = e and e.get_inventory(defines.inventory.character_main)
                    for ii = 1, 5, 1 do
                        if player_inv[ii].valid then
                            for iii = 1, #player_inv[ii], 1 do
                                if player_inv[ii][iii].valid then
                                    items[#items + 1] = player_inv[ii][iii]
                                end
                            end
                        end
                    end
                    if #items > 0 then
                        for item = 1, #items, 1 do
                            if items[item].valid and inv and inv.valid then
                                inv.insert(items[item])
                            end
                        end
                        game.print({'chronosphere.message_accident'}, {r = 0.98, g = 0.66, b = 0.22})
                        if e and e.valid then
                            e.die('neutral')
                        end
                    else
                        if e and e.valid then
                            e.destroy()
                        end
                    end

                    for ii = 1, 5, 1 do
                        if player_inv[ii].valid then
                            player_inv[ii].clear()
                        end
                    end
                    players[i] = nil
                else
                    later[#later + 1] = players[i]
                end
            end
        end
        players = {}
        if #later > 0 then
            for i = 1, #later, 1 do
                players[#players + 1] = later[i]
            end
        end
        playertable.offline_players = players
    end
end

function Public.request_chunks()
    local objective = Chrono_table.get_table()
    local schedule = Chrono_table.get_schedule_table()
    local surface = game.surfaces[objective.active_surface_index]
    if objective.world.id == 7 then
        surface.request_to_generate_chunks({-800, 0}, 1 + math_floor(objective.passivetimer / 5))
    else
        if table_size(schedule.chunks_to_generate) > 0 then
            local amount = 0
            for index, chunk in pairs(schedule.chunks_to_generate) do
                surface.request_to_generate_chunks(chunk.pos, 0)
                schedule.chunks_to_generate[index] = nil
                amount = amount + 1
                if amount >= objective.gen_speed then
                    break
                end
            end
        end
    end
    --surface.force_generate_chunk_requests()
end

function Public.update_charges()
    local objective = Chrono_table.get_table()
    if objective.warmup then return end
    if objective.chronocharges < objective.chronochargesneeded and objective.world.id ~= 7 then -- < 2000
        objective.chronocharges = objective.chronocharges + objective.passive_chronocharge_rate
    -- local chronotimer_ticks_between_increase = math_floor(objective.passive_chronocharge_rate / 10) * 10 --- 60 / (1800 / 2000)
    -- if tick % chronotimer_ticks_between_increase == 0 then
    -- 	objective.chronocharges = objective.chronocharges + 1
    -- end
    end
end

local function shoot_laser(surface, source, enemy)
    local force = source.force
    surface.create_entity {name = 'laser-beam', position = source.position, force = 'player', target = enemy, source = source, max_length = 32, duration = 60}
    enemy.damage(20 * (1 + force.get_ammo_damage_modifier('laser') + force.get_gun_speed_modifier('laser')), force, 'laser', source)
end

function Public.laser_defense()
    local objective = Chrono_table.get_table()
    if objective.upgrades[22] == 0 then
        return
    end
    local surface = game.surfaces[objective.active_surface_index]
    if surface ~= objective.locomotive.surface then
        return
    end
    if not objective.laser_battery.valid then
        return
    end
    local enemies = surface.find_entities_filtered {radius = 32, limit = objective.upgrades[22], force = {'enemy', 'scrapyard'}, position = objective.locomotive.position}
    if #enemies < 1 then
        return
    end
    for i = 1, math.min(objective.upgrades[22], #enemies), 1 do
        if objective.laser_battery.energy < 110000 then
            surface.create_entity(
                {
                    name = 'flying-text',
                    position = objective.locomotive.position,
                    text = 'Laser: Low Power',
                    color = {r = 0.98, g = 0, b = 0}
                }
            )
            break
        end
        local enemy = enemies[i]
        if enemy and enemy.valid and enemy.health and enemy.health > 0 then
            shoot_laser(surface, objective.locomotive, enemy)
            objective.laser_battery.energy = objective.laser_battery.energy - 100000
            Public.train_pollution('lasers')
        end
    end
end

function Public.message_game_won()
    local objective = Chrono_table.get_table()
    objective.game_lost = true
    game.print({'chronosphere.message_game_won2', objective.mainscore}, {r = 0.98, g = 0.66, b = 0.22})
    Server.to_discord_embed({'chronosphere.message_game_won2', objective.mainscore}, true)
end

function Public.giftmas_lights()
    local objective = Chrono_table.get_table()
    local lights = objective.giftmas_lamps
    local nr = #lights
    if nr < 1 then return end
    local colors = {
        --[1] = {r = 255, g = 77, b = 55, a = 1}, --červená
        [1] = {r = 255, g = 33, b = 11, a = 1}, --červená
        [2] = {r = 86, g = 241, b = 59, a = 1}, --zelená
        [3] = {r = 243, g = 189, b = 45, a = 1}, --žlutá
        [4] = {r = 63, g = 49, b = 255, a = 1}, --modrá
    }
    for _ = 1, 5, 1 do
        lights[math_random(1, nr)].color = colors[math_random(1, 4)]
    end
end

function Public.giftmas_spawn()
    local objective = Chrono_table.get_table()
    if objective.upgrades[26] <= objective.giftmas_delivered  or objective.world.id == 7 then
        return
    end
    if  objective.passivetimer + 60 * objective.upgrades[26] >= 400 * (1 + objective.giftmas_delivered) then
        local random_pos = {x = math_random(-160, 160), y = math_random(-160, 160)}
        local surface = game.surfaces[objective.active_surface_index]
        local pos = surface.find_non_colliding_position('rocket-silo', random_pos, 64, 1)
        if not pos then
            return
        end
        local treasures = {
            {pos.x, pos.y},
            {pos.x - 2, pos.y - 2},
            {pos.x - 2, pos.y + 2},
            {pos.x + 2, pos.y - 2},
            {pos.x + 2, pos.y + 2}
        }
        MFunctions.spawn_treasures(surface, treasures)
        objective.giftmas_delivered = objective.giftmas_delivered + 1
        game.print({'chronosphere.message_giftmas_spawned', pos.x, pos.y, surface.name}, {r = 0.98, g = 0.66, b = 0.22})
    end
end

function Public.chart_wagons()
    if not game.surfaces['cargo_wagon'] then
        return
    end
    local objective = Chrono_table.get_table()
    if objective.upgrades[27] == 1 then
        game.forces.player.chart_all(game.surfaces['cargo_wagon'])
    end
end

-- function Public.player_spit()
--   for _, player in pairs(game.connected_players) do
--     if not player.character or not player.character.valid then return end
--     local enemies = player.surface.find_entities_filtered{radius = 32, limit = 10, force = {"enemy", "scrapyard"}, position = player.character.position}
--     if #enemies < 1 then return end
--     for i = 1, #enemies, 1 do
--       local enemy = enemies[i]
--       if enemy and enemy.valid and enemy.health and enemy.health > 0 then
--         shoot_acid(player.surface, player.character, enemy)
--       end
--     end
--   end
-- end

return Public
