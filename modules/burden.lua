local Event = require 'utils.event'
local Modifier = require 'utils.player_modifiers'
local Color = require 'utils.color_presets'

local function validate_player(player)
    if not player then
        return false
    end
    if not player.valid then
        return false
    end
    if not player.character then
        return false
    end
    if not player.connected then
        return false
    end
    if not game.players[player.name] then
        return false
    end
    return true
end

local function compute_fullness(player)
    local inv = player.get_inventory(defines.inventory.character_main)
    local max_stacks = #inv
    local num_stacks = 0

    local contents = inv.get_contents()
    for _, items in pairs(contents) do
        local stack_size = 1
        if prototypes.item[items.name].stackable then
            stack_size = prototypes.item[items.name].stack_size
        end

        num_stacks = num_stacks + items.count / stack_size
    end

    return num_stacks / max_stacks
end

local function check_burden(event)
    local player = game.players[event.player_index]
    if not validate_player(player) then
        return
    end
    local fullness = compute_fullness(player)
    Modifier.update_single_modifier(player, 'character_running_speed_modifier', 'randomness', 0.3 - fullness)
    Modifier.update_single_modifier(player, 'character_mining_speed_modifier', 'randomness', 0.3 - fullness)
    Modifier.update_player_modifiers(player)
    if fullness >= 0.9 and fullness <= 0.901 then
        player.print('Maybe you should drop some of that inventory to lessen the burden.', Color.red)
    end
end

local function on_init()
    script.on_event(defines.events.on_player_main_inventory_changed, check_burden)
end

Event.on_init(on_init)
