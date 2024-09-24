-- biters and their buildings gain pseudo hp increase through the means of evasion mechanics -- by mewmew
-- use storage.biter_evasion_health_increase_factor to modify their health

local Event = require 'utils.event'
local random_max = 1000000
local types = {
    ['unit'] = true,
    ['unit-spawner'] = true,
    ['turret'] = true
}

local function get_evade_chance()
    return random_max - (random_max / storage.biter_evasion_health_increase_factor)
end

local function on_entity_damaged(event)
    if storage.biter_evasion_health_increase_factor == 1 then
        return
    end
    if not event.entity.valid then
        return
    end
    if not types[event.entity.type] then
        return
    end
    if event.final_damage_amount > event.entity.prototype.max_health * storage.biter_evasion_health_increase_factor then
        return
    end
    if math.random(1, random_max) > get_evade_chance() then
        return
    end
    event.entity.health = event.entity.health + event.final_damage_amount
end

local function on_init()
    storage.biter_evasion_health_increase_factor = 1
end

Event.on_init(on_init)
Event.add(defines.events.on_entity_damaged, on_entity_damaged)
