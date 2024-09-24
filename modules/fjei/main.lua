--luacheck: ignore
--[[
FJEI - "Factorio Just enough items"
A comfy recipe browser - MewMew
]]
local Gui = require 'modules.fjei.gui'
local Functions = require 'modules.fjei.functions'
local recipe_window_position = 'center'

local function on_player_joined_game(event)
    local player = game.players[event.player_index]

    if not storage.fjei then
        Functions.build_tables()
    end

    if not storage.fjei.player_data[player.index] then
        storage.fjei.player_data[player.index] = {}
    end

    Gui.draw_top_toggle_button(player)
    Gui.refresh_main_window(player)
end

local function on_player_left_game(event)
    local player = game.players[event.player_index]
    if player.gui.left['fjei_main_window'] then
        player.gui.left['fjei_main_window'].destroy()
    end
    if player.gui.screen['fjei_recipe_window'] then
        player.gui.screen['fjei_recipe_window'].destroy()
    end
    if player.gui[recipe_window_position]['fjei_recipe_window'] then
        player.gui[recipe_window_position]['fjei_recipe_window'].destroy()
    end
    if not storage.fjei.player_data[player.index] then
        return
    end
    storage.fjei.player_data[player.index].history = nil
    storage.fjei.player_data[player.index].filtered_list = nil
    storage.fjei.player_data[player.index] = nil
end

local function on_research_finished(event)
    if not Functions.add_research_to_whitelist(event.research.force, event.research.effects) then
        return
    end
    local player_data = storage.fjei.player_data
    for _, player in pairs(event.research.force.connected_players) do
        player_data[player.index].filtered_list = nil
        Gui.refresh_main_window(player)
    end
end

local sprite_parent_whitelist = {
    ['fjei_main_window_item_list_table'] = true,
    ['fjei_main_window_history_table'] = true,
    ['fjei_recipe_window'] = true,
    ['fjei_recipe_window_select_table'] = true
}

local function on_gui_click(event)
    local element = event.element
    if not element then
        return
    end
    if not element.valid then
        return
    end
    local player = game.players[event.player_index]
    if Gui.gui_click_actions(element, player, event.button) then
        return
    end

    if element.type ~= 'sprite' and element.type ~= 'choose-elem-button' then
        return
    end
    local parent = element.parent
    for _ = 1, 4, 1 do
        if not parent then
            return
        end
        if not parent.name then
            return
        end
        if sprite_parent_whitelist[parent.name] then
            Gui.open_recipe(element, player, event.button)
            return
        end
        parent = parent.parent
    end
end

local function on_gui_text_changed(event)
    local element = event.element
    if not element then
        return
    end
    if not element.valid then
        return
    end
    if element.name ~= 'fjei_main_window_search_textfield' then
        return
    end
    local player = game.players[event.player_index]
    if element.text == '' then
        storage.fjei.player_data[player.index].active_filter = false
    else
        storage.fjei.player_data[player.index].active_filter = element.text
    end

    Functions.set_filtered_list(player)
    Gui.refresh_main_window(player)
end

local function on_configuration_changed()
    Functions.build_tables()
    for _, player in pairs(game.players) do
        if player.gui.left['fjei_main_window'] then
            player.gui.left['fjei_main_window'].destroy()
        end
        if player.gui[recipe_window_position]['fjei_recipe_window'] then
            player.gui[recipe_window_position]['fjei_recipe_window'].destroy()
        end
    end
end

local function on_string_translated(event)
    local player = game.get_player(event.player_index)
    local result = event.result
    if not result then
        return
    end

    local localised_string = event.localised_string
    if not localised_string then
        return
    end

    localised_string = localised_string[1]
    if not localised_string then
        return
    end

    localised_string = string.match(localised_string, '[^.]*$')

    Functions.set_translated_data(player, result, localised_string)
end

local function on_init()
    Functions.build_tables()
end

local function on_load()
    for _, player in pairs(game.players) do
        Gui.draw_top_toggle_button(player)
    end
end

local event = require 'utils.event'
event.add(defines.events.on_player_joined_game, on_player_joined_game)
event.add(defines.events.on_player_left_game, on_player_left_game)
event.add(defines.events.on_research_finished, on_research_finished)
event.add(defines.events.on_gui_click, on_gui_click)
event.add(defines.events.on_gui_text_changed, on_gui_text_changed)
event.add(defines.events.on_string_translated, on_string_translated)
script.on_configuration_changed(on_configuration_changed)
event.on_init(on_init)
event.on_init(on_load)
