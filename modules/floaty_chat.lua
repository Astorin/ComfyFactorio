local Event = require 'utils.event'
local Global = require 'utils.global'

local this = {
    player_floaty_chat = {}
}

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

local function on_console_chat(event)
    if not event.message then
        return
    end
    if not event.player_index then
        return
    end
    local player = game.players[event.player_index]
    if not player.character then
        return
    end

    local y_offset = -4

    if this.player_floaty_chat[player.index] then
        rendering.get_object_by_id(this.player_floaty_chat[player.index]).destroy()
        this.player_floaty_chat[player.index] = nil
    end

    local players = {}
    for _, p in pairs(game.connected_players) do
        if player.force.index == p.force.index then
            players[#players + 1] = p
        end
    end
    if #players == 0 then
        return
    end

    if player.character.surface ~= player.surface.index then return end

    this.player_floaty_chat[player.index] =
        rendering.draw_text {
            text = event.message,
            surface = player.surface,
            target = player.character,
            target_offset = { -0.05, y_offset },
            color = {
                r = player.color.r * 0.6 + 0.25,
                g = player.color.g * 0.6 + 0.25,
                b = player.color.b * 0.6 + 0.25,
                a = 1
            },
            players = players,
            time_to_live = 600,
            scale = 1.50,
            font = 'default-game',
            alignment = 'center',
            scale_with_zoom = false
        }
end

Event.add(defines.events.on_console_chat, on_console_chat)
