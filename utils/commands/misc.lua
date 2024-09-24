---@diagnostic disable: deprecated
local Session = require 'utils.datastore.session_data'
local Modifiers = require 'utils.player_modifiers'
local Server = require 'utils.server'
local Color = require 'utils.color_presets'
local Event = require 'utils.event'
local Global = require 'utils.global'
local BottomFrame = require 'utils.gui.bottom_frame'
local Gui = require 'utils.gui'
local SpamProtection = require 'utils.spam_protection'
local Discord = require 'utils.discord_handler'
local Commands = require 'utils.commands'

local this = {
    enabled = true,
    players = {},
    bottom_button = false
}

Global.register(
    this,
    function (t)
        this = t
    end
)

local Public = {
}

local clear_corpse_button_name = Gui.uid_name()

Commands.new('playtime', 'Fetches a player total playtime or nil.')
    :require_backend()
    :add_parameter('target', false, 'string')
    :callback(
        function (player, target)
            Session.get_and_print_to_player(player, target)
        end
    )


Commands.new('refresh', 'Reloads game script')
    :require_admin()
    :callback(
        function ()
            game.print('Reloading game script...', Color.warning)
            Server.to_discord_bold('Reloading game script...')
            game.reload_script()
        end
    )

Commands.new('spaghetti', 'Toggle between disabling bots.')
    :require_admin()
    :require_validation()
    :is_activated()
    :add_parameter('true/false', true, 'boolean')
    :callback(
        function (player, args)
            local force = player.force
            if args == 'true' then
                game.print('The world has been spaghettified!', Color.success)
                force.technologies['logistic-system'].enabled = false
                force.technologies['construction-robotics'].enabled = false
                force.technologies['logistic-robotics'].enabled = false
                force.technologies['robotics'].enabled = false
                force.technologies['personal-roboport-equipment'].enabled = false
                force.technologies['personal-roboport-mk2-equipment'].enabled = false
                force.technologies['worker-robots-storage-1'].enabled = false
                force.technologies['worker-robots-storage-2'].enabled = false
                force.technologies['worker-robots-storage-3'].enabled = false
                force.technologies['worker-robots-speed-1'].enabled = false
                force.technologies['worker-robots-speed-2'].enabled = false
                force.technologies['worker-robots-speed-3'].enabled = false
                force.technologies['worker-robots-speed-4'].enabled = false
                force.technologies['worker-robots-speed-5'].enabled = false
                force.technologies['worker-robots-speed-6'].enabled = false
                this.spaghetti_enabled = true
            elseif args == 'false' then
                game.print('The world is no longer spaghett!', Color.yellow)
                force.technologies['logistic-system'].enabled = true
                force.technologies['construction-robotics'].enabled = true
                force.technologies['logistic-robotics'].enabled = true
                force.technologies['robotics'].enabled = true
                force.technologies['personal-roboport-equipment'].enabled = true
                force.technologies['personal-roboport-mk2-equipment'].enabled = true
                force.technologies['worker-robots-storage-1'].enabled = true
                force.technologies['worker-robots-storage-2'].enabled = true
                force.technologies['worker-robots-storage-3'].enabled = true
                force.technologies['worker-robots-speed-1'].enabled = true
                force.technologies['worker-robots-speed-2'].enabled = true
                force.technologies['worker-robots-speed-3'].enabled = true
                force.technologies['worker-robots-speed-4'].enabled = true
                force.technologies['worker-robots-speed-5'].enabled = true
                force.technologies['worker-robots-speed-6'].enabled = true
                this.spaghetti_enabled = false
            end
        end
    )

Commands.new('generate_map', 'Pregenerates map.')
    :require_admin()
    :require_validation()
    :add_parameter('radius', false, 'number')
    :callback(
        function (player, args)
            local radius = args
            local surface = player.surface
            if surface.is_chunk_generated({ radius, radius }) then
                player.print('Map generation done')
                return true
            end
            surface.request_to_generate_chunks({ 0, 0 }, radius)
            surface.force_generate_chunk_requests()
            for _, pl in pairs(game.connected_players) do
                pl.play_sound { path = 'utility/new_objective', volume_modifier = 1 }
            end
            player.print('Map generation done')
        end
    )

Commands.new('repair', 'Revives all ghost entities.')
    :require_admin()
    :require_validation()
    :add_parameter('1-50', true, 'number')
    :callback(
        function (player, args)
            if args < 1 then
                player.print('[ERROR] Value is too low.')
                return false
            end

            if args > 50 then
                player.print('[ERROR] Value is too big.')
                return false
            end

            local radius = { { x = (player.position.x + -args), y = (player.position.y + -args) }, { x = (player.position.x + args), y = (player.position.y + args) } }

            local c = 0
            for _, v in pairs(player.surface.find_entities_filtered { type = 'entity-ghost', area = radius }) do
                if v and v.valid then
                    c = c + 1
                    v.silent_revive()
                end
            end

            if c == 0 then
                player.print('No entities to repair were found!')
                return false
            end

            Discord.send_notification_raw(nil, player.name .. ' repaired ' .. c .. ' entities!')
            return 'Repaired ' .. c .. ' entities!'
        end
    )

Commands.new('dump_layout', 'Dump the current map-layout.')
    :require_admin()
    :require_validation('This will lag the server if ran')
    :callback(
        function (player, _)
            local surface = player.surface
            game.write_file('layout.lua', '', false)

            local area = {
                left_top = { x = 0, y = 0 },
                right_bottom = { x = 32, y = 32 }
            }

            local entities = surface.find_entities_filtered { area = area }
            local tiles = surface.find_tiles_filtered { area = area }

            for _, e in pairs(entities) do
                local str = '{position = {x = ' .. e.position.x
                str = str .. ', y = '
                str = str .. e.position.y
                str = str .. '}, name = "'
                str = str .. e.name
                str = str .. '", direction = '
                str = str .. tostring(e.direction)
                str = str .. ', force = "'
                str = str .. e.force.name
                str = str .. '"},'
                if e.name ~= 'character' then
                    game.write_file('layout.lua', str .. '\n', true)
                end
            end

            game.write_file('layout.lua', '\n', true)
            game.write_file('layout.lua', '\n', true)
            game.write_file('layout.lua', 'Tiles: \n', true)

            for _, t in pairs(tiles) do
                local str = '{position = {x = ' .. t.position.x
                str = str .. ', y = '
                str = str .. t.position.y
                str = str .. '}, name = "'
                str = str .. t.name
                str = str .. '"},'
                game.write_file('layout.lua', str .. '\n', true)
            end
            return 'Dumped layout as file: layout.lua'
        end
    )

Commands.new('creative', 'Enables creative_mode.')
    :require_admin()
    :add_parameter('true/false', false, 'boolean')
    :require_validation()
    :is_activated()
    :callback(
        function (player, args)
            local force = player.force
            if args == 'true' then
                game.print('[CREATIVE] ' .. player.name .. ' has activated creative-mode!', Color.warning)
                Server.to_discord_bold(table.concat { '[Creative] ' .. player.name .. ' has activated creative-mode!' })

                Modifiers.set('creative_enabled', true)

                this.creative_enabled = true

                force.enable_all_prototypes()
                for _, _player in pairs(game.connected_players) do
                    player.cheat_mode = true
                    if _player.character ~= nil then
                        Public.insert_all_items(_player)
                    end
                end
            elseif args == 'false' then
                game.print('[CREATIVE] ' .. player.name .. ' has deactivated creative-mode!', Color.warning)
                Server.to_discord_bold(table.concat { '[Creative] ' .. player.name .. ' has deactivated creative-mode!' })

                Modifiers.set('creative_enabled', false)

                this.creative_enabled = false

                for _, _player in pairs(game.connected_players) do
                    Public.remove_all_items(player)
                    _player.cheat_mode = false
                end
            end
        end
    )

Commands.new('delete_uncharted_chunks', 'Deletes all chunks that are not charted. Can reduce filesize of the savegame. May be unsafe to use in certain custom maps.')
    :require_admin()
    :require_validation()
    :callback(
        function (player, _)
            local forces = {}
            for _, force in pairs(game.forces) do
                if force.index == 1 or force.index > 3 then
                    table.insert(forces, force)
                end
            end

            local is_charted
            local count = 0
            for _, surface in pairs(game.surfaces) do
                for chunk in surface.get_chunks() do
                    is_charted = false
                    for _, force in pairs(forces) do
                        if force.is_chunk_charted(surface, { chunk.x, chunk.y }) then
                            is_charted = true
                            break
                        end
                    end
                    if not is_charted then
                        surface.delete_chunk({ chunk.x, chunk.y })
                        count = count + 1
                    end
                end
            end

            local message = player.name .. ' deleted ' .. count .. ' uncharted chunks!'
            game.print(message, Color.warning)
            Server.to_discord_bold(table.concat { message })
        end
    )

local function clear_corpses(cmd)
    local player
    local trusted = Session.get_trusted_table()
    local param
    if cmd and cmd.player then
        player = cmd.player
        param = 50
    elseif cmd then
        player = game.player
        param = tonumber(cmd.parameter)
    end

    if not player or not player.valid then
        return
    end
    local p = player.print
    if not trusted[player.name] then
        if not player.admin then
            p('[ERROR] Only admins and trusted weebs are allowed to run this command!', Color.fail)
            return
        end
    end
    if param == nil then
        player.print('[ERROR] Must specify radius!', Color.fail)
        return
    end
    if param < 0 then
        player.print('[ERROR] Value is too low.', Color.fail)
        return
    end
    if param > 500 then
        player.print('[ERROR] Value is too big.', Color.fail)
        return
    end
    local pos = player.position

    local i = 0

    local radius = { { x = (pos.x + -param), y = (pos.y + -param) }, { x = (pos.x + param), y = (pos.y + param) } }

    for _, entity in pairs(player.surface.find_entities_filtered { area = radius, type = 'corpse' }) do
        if entity.corpse_expires then
            entity.destroy()
            i = i + 1
        end
    end
    local corpse = 'corpse'

    if i > 1 then
        corpse = 'corpses'
    end
    if i == 0 then
        player.print('[color=blue][Cleaner][/color] No corpses to clear!', Color.warning)
    else
        player.print('[color=blue][Cleaner][/color] Cleared ' .. i .. ' ' .. corpse .. '!', Color.success)
    end
end

commands.add_command(
    'clear-corpses',
    'Clears all the biter corpses..',
    function (cmd)
        clear_corpses(cmd)
    end
)

local on_player_joined_game = function (player)
    Public.insert_all_items(player)
end

function Public.insert_all_items(player)
    if this.creative_enabled and not this.players[player.index] then
        if player.character ~= nil then
            if player.get_inventory(defines.inventory.character_armor) then
                player.get_inventory(defines.inventory.character_armor).clear()
            end
            player.insert { name = 'power-armor-mk2', count = 1 }
            Modifiers.update_single_modifier(player, 'character_inventory_slots_bonus', 'creative', #game.item_prototypes)
            Modifiers.update_single_modifier(player, 'character_mining_speed_modifier', 'creative', 150)
            Modifiers.update_single_modifier(player, 'character_health_bonus', 'creative', 2000)
            Modifiers.update_single_modifier(player, 'character_crafting_speed_modifier', 'creative', 150)
            Modifiers.update_single_modifier(player, 'character_resource_reach_distance_bonus', 'creative', 150)
            Modifiers.update_single_modifier(player, 'character_running_speed_modifier', 'creative', 2)
            Modifiers.update_player_modifiers(player)

            this.players[player.index] = true

            local p_armor = player.get_inventory(5)[1].grid
            if p_armor and p_armor.valid then
                p_armor.put({ name = 'fusion-reactor-equipment' })
                p_armor.put({ name = 'fusion-reactor-equipment' })
                p_armor.put({ name = 'fusion-reactor-equipment' })
                p_armor.put({ name = 'exoskeleton-equipment' })
                p_armor.put({ name = 'exoskeleton-equipment' })
                p_armor.put({ name = 'exoskeleton-equipment' })
                p_armor.put({ name = 'energy-shield-mk2-equipment' })
                p_armor.put({ name = 'energy-shield-mk2-equipment' })
                p_armor.put({ name = 'energy-shield-mk2-equipment' })
                p_armor.put({ name = 'energy-shield-mk2-equipment' })
                p_armor.put({ name = 'personal-roboport-mk2-equipment' })
                p_armor.put({ name = 'night-vision-equipment' })
                p_armor.put({ name = 'battery-mk2-equipment' })
                p_armor.put({ name = 'battery-mk2-equipment' })
            end
            local item = game.item_prototypes
            local i = 0
            for _k, _v in pairs(item) do
                i = i + 1
                if _k and _v.type ~= 'mining-tool' then
                    player.character_inventory_slots_bonus = Modifiers.get_single_modifier(player, 'character_inventory_slots_bonus', 'creative')
                    player.insert { name = _k, count = _v.stack_size }
                    player.print('[CREATIVE] Inserted all base items.', Color.success)
                end
            end
        end
    end
end

function Public.remove_all_items(player)
    if player.character ~= nil then
        if player.get_inventory(defines.inventory.character_armor) then
            player.get_inventory(defines.inventory.character_armor).clear()
        end
        player.clear_items_inside()
        Modifiers.reset_player_modifiers(player)
        this.players[player.index] = nil
    end
end

local function create_clear_corpse_frame(player, bottom_frame_data)
    local button

    bottom_frame_data = bottom_frame_data or BottomFrame.get_player_data(player)

    if Gui.get_mod_gui_top_frame() then
        button =
            Gui.add_mod_button(
                player,
                {
                    type = 'sprite-button',
                    name = clear_corpse_button_name,
                    sprite = 'entity/behemoth-biter',
                    tooltip = { 'commands.clear_corpse' },
                    style = Gui.button_style
                }
            )
        if button then
            button.style.font_color = { 165, 165, 165 }
            button.style.font = 'default-semibold'
            button.style.minimal_height = 36
            button.style.maximal_height = 36
            button.style.minimal_width = 40
            button.style.padding = -2
        end
    else
        button =
            player.gui.top[clear_corpse_button_name] or
            player.gui.top.add(
                {
                    type = 'sprite-button',
                    sprite = 'entity/behemoth-biter',
                    name = clear_corpse_button_name,
                    tooltip = { 'commands.clear_corpse' },
                    style = Gui.button_style
                }
            )
        button.style.font_color = { r = 0.11, g = 0.8, b = 0.44 }
        button.style.font = 'heading-1'
        button.style.minimal_height = 40
        button.style.maximal_width = 40
        button.style.minimal_width = 38
        button.style.maximal_height = 38
        button.style.padding = 1
        button.style.margin = 0
    end

    if this.bottom_button and bottom_frame_data ~= nil and not bottom_frame_data.top then
        if button and button.valid then
            button.destroy()
        end
    end
end

function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

function Public.set(key, value)
    if key then
        this[key] = value or false
        return this[key]
    elseif key then
        return this[key]
    else
        return this
    end
end

Event.on_init(
    function ()
        Modifiers.set('creative_enabled', false)
        this.creative_are_you_sure = false
        this.creative_enabled = false
        this.spaghetti_are_you_sure = false
        this.spaghetti_enabled = false
    end
)

function Public.reset()
    Modifiers.set('creative_enabled', false)
    this.creative_are_you_sure = false
    this.creative_enabled = false
    this.spaghetti_are_you_sure = false
    this.spaghetti_enabled = false
    this.players = {}
end

function Public.bottom_button(value)
    this.bottom_button = value or false
end

Event.add(
    defines.events.on_player_joined_game,
    function (event)
        if not this.enabled then
            return
        end

        local player = game.players[event.player_index]
        on_player_joined_game(player)
        create_clear_corpse_frame(player)

        if this.bottom_button then
            BottomFrame.add_inner_frame({ player = player, element_name = clear_corpse_button_name, tooltip = { 'commands.clear_corpse' }, sprite = 'entity/behemoth-biter' })
        end
    end
)

Gui.on_click(
    clear_corpse_button_name,
    function (event)
        if not this.enabled then
            return
        end
        local is_spamming = SpamProtection.is_spamming(event.player, nil, 'Clear Corpse')
        if is_spamming then
            return
        end
        clear_corpses(event)
    end
)

Event.add(
    BottomFrame.events.bottom_quickbar_location_changed,
    function (event)
        if not this.enabled then
            return
        end
        local player_index = event.player_index
        if not player_index then
            return
        end
        local player = game.get_player(player_index)
        if not player or not player.valid then
            return
        end

        local bottom_frame_data = event.data
        create_clear_corpse_frame(player, bottom_frame_data)
    end
)

function Public.set_enabled(value)
    this.enabled = value or false
end

Public.clear_corpses = clear_corpses

return Public
