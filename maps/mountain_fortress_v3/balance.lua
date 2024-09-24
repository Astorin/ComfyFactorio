local Difficulty = require 'modules.difficulty_vote_by_amount'
local Public = require 'maps.mountain_fortress_v3.table'

function Public.init_enemy_weapon_damage()
    local data = {
        ['artillery-shell'] = -1.3,
        ['biological'] = 0,
        ['beam'] = 0,
        ['bullet'] = 0,
        ['cannon-shell'] = 0,
        ['capsule'] = 0,
        ['electric'] = 0,
        ['flamethrower'] = 0,
        ['grenade'] = 0,
        ['laser'] = 0,
        ['landmine'] = 0,
        ['melee'] = 0,
        ['rocket'] = 0,
        ['shotgun-shell'] = 0
    }

    local e = game.forces.enemy
    local a = game.forces.aggressors
    local af = game.forces.aggressors_frenzy

    e.technologies['refined-flammables-1'].researched = true
    e.technologies['refined-flammables-2'].researched = true

    a.technologies['refined-flammables-1'].researched = true
    a.technologies['refined-flammables-2'].researched = true

    af.technologies['refined-flammables-1'].researched = true
    af.technologies['refined-flammables-2'].researched = true

    for k, v in pairs(data) do
        e.set_ammo_damage_modifier(k, v)
        a.set_ammo_damage_modifier(k, v)
        af.set_ammo_damage_modifier(k, v)
    end
end

function Public.enemy_weapon_damage()
    local e = game.forces.enemy
    local a = game.forces.aggressors
    local af = game.forces.aggressors_frenzy

    local data = {
        ['artillery-shell'] = 0.05,
        ['biological'] = 0.06,
        ['beam'] = 0.08,
        ['bullet'] = 0.08,
        ['capsule'] = 0.08,
        ['electric'] = 0.08,
        ['flamethrower'] = 0.08,
        ['laser'] = 0.08,
        ['landmine'] = 0.08,
        ['melee'] = 0.08
    }

    for k, v in pairs(data) do
        local new = Difficulty.get().value * v

        local e_old = e.get_ammo_damage_modifier(k)
        local a_old = a.get_ammo_damage_modifier(k)
        local af_old = af.get_ammo_damage_modifier(k)

        e.set_ammo_damage_modifier(k, new + e_old)
        a.set_ammo_damage_modifier(k, new + a_old)
        af.set_ammo_damage_modifier(k, new + af_old)
    end
end

return Public
