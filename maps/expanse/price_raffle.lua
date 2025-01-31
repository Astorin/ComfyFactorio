--[[
roll(budget, max_slots, blacklist) returns a table with item-stacks
budget		-	the total value of the item stacks combined
max_slots	-	the maximum amount of item stacks to return
blacklist		-	optional list of item names that can not be rolled. example: {["substation"] = true, ["roboport"] = true,}
]]
local Public = {}

local table_shuffle_table = table.shuffle_table
local table_insert = table.insert
local math_random = math.random
local math_floor = math.floor

local item_worths = {
    ['wooden-chest'] = 4,
    ['iron-chest'] = 8,
    ['steel-chest'] = 64,
    ['storage-tank'] = 64,
    ['transport-belt'] = 4,
    ['fast-transport-belt'] = 16,
    ['express-transport-belt'] = 64,
    ['underground-belt'] = 16,
    ['fast-underground-belt'] = 64,
    ['express-underground-belt'] = 256,
    ['splitter'] = 16,
    ['fast-splitter'] = 64,
    ['express-splitter'] = 256,
    ['burner-inserter'] = 2,
    ['inserter'] = 8,
    ['long-handed-inserter'] = 16,
    ['fast-inserter'] = 32,
    ['bulk-inserter'] = 160,
    ['small-electric-pole'] = 4,
    ['medium-electric-pole'] = 32,
    ['big-electric-pole'] = 64,
    ['substation'] = 256,
    ['pipe'] = 1,
    ['pipe-to-ground'] = 15,
    ['pump'] = 32,
    ['rail'] = 8,
    ['train-stop'] = 64,
    ['rail-signal'] = 16,
    ['rail-chain-signal'] = 16,
    ['locomotive'] = 512,
    ['cargo-wagon'] = 256,
    ['fluid-wagon'] = 256,
    ['artillery-wagon'] = 16384,
    ['car'] = 128,
    ['tank'] = 4096,
    ['logistic-robot'] = 256,
    ['construction-robot'] = 256,
    ['active-provider-chest'] = 256,
    ['passive-provider-chest'] = 256,
    ['storage-chest'] = 256,
    ['buffer-chest'] = 512,
    ['requester-chest'] = 512,
    ['roboport'] = 2048,
    ['small-lamp'] = 16,
    ['arithmetic-combinator'] = 16,
    ['decider-combinator'] = 16,
    ['constant-combinator'] = 16,
    ['power-switch'] = 16,
    ['programmable-speaker'] = 32,
    ['stone-brick'] = 2,
    ['landfill'] = 12,
    ['concrete'] = 4,
    ['hazard-concrete'] = 4,
    ['refined-concrete'] = 16,
    ['refined-hazard-concrete'] = 16,
    ['cliff-explosives'] = 256,
    ['repair-pack'] = 8,
    ['boiler'] = 8,
    ['steam-engine'] = 32,
    ['solar-panel'] = 64,
    ['accumulator'] = 64,
    ['nuclear-reactor'] = 8192,
    ['heat-pipe'] = 128,
    ['heat-exchanger'] = 256,
    ['steam-turbine'] = 256,
    ['burner-mining-drill'] = 8,
    ['electric-mining-drill'] = 32,
    ['offshore-pump'] = 16,
    ['pumpjack'] = 64,
    ['stone-furnace'] = 4,
    ['steel-furnace'] = 64,
    ['electric-furnace'] = 256,
    ['assembling-machine-1'] = 32,
    ['assembling-machine-2'] = 128,
    ['assembling-machine-3'] = 512,
    ['oil-refinery'] = 256,
    ['chemical-plant'] = 128,
    ['centrifuge'] = 2048,
    ['lab'] = 64,
    ['beacon'] = 512,
    ['speed-module'] = 128,
    ['speed-module-2'] = 512,
    ['speed-module-3'] = 2048,
    ['efficiency-module'] = 128,
    ['efficiency-module-2'] = 512,
    ['efficiency-module-3'] = 2048,
    ['productivity-module'] = 128,
    ['productivity-module-2'] = 512,
    ['productivity-module-3'] = 2048,
    ['iron-plate'] = 1,
    ['copper-plate'] = 1,
    ['solid-fuel'] = 16,
    ['steel-plate'] = 8,
    ['plastic-bar'] = 8,
    ['sulfur'] = 4,
    ['battery'] = 16,
    ['explosives'] = 4,
    ['crude-oil-barrel'] = 8,
    ['heavy-oil-barrel'] = 16,
    ['light-oil-barrel'] = 16,
    ['lubricant-barrel'] = 16,
    ['petroleum-gas-barrel'] = 16,
    ['sulfuric-acid-barrel'] = 16,
    ['water-barrel'] = 4,
    ['copper-cable'] = 1,
    ['iron-stick'] = 1,
    ['iron-gear-wheel'] = 2,
    ['barrel'] = 4,
    ['electronic-circuit'] = 4,
    ['advanced-circuit'] = 16,
    ['processing-unit'] = 128,
    ['engine-unit'] = 8,
    ['electric-engine-unit'] = 64,
    ['flying-robot-frame'] = 128,
    ['satellite'] = 32768,
    ['low-density-structure'] = 64,
    ['rocket-fuel'] = 256,
    ['nuclear-fuel'] = 1024,
    ['uranium-235'] = 1024,
    ['uranium-238'] = 32,
    ['uranium-fuel-cell'] = 128,
    ['automation-science-pack'] = 4,
    ['logistic-science-pack'] = 16,
    ['military-science-pack'] = 64,
    ['chemical-science-pack'] = 128,
    ['production-science-pack'] = 256,
    ['utility-science-pack'] = 256,
    ['space-science-pack'] = 512,
    ['pistol'] = 4,
    ['submachine-gun'] = 32,
    ['shotgun'] = 16,
    ['combat-shotgun'] = 256,
    ['rocket-launcher'] = 128,
    ['flamethrower'] = 512,
    ['land-mine'] = 8,
    ['firearm-magazine'] = 4,
    ['piercing-rounds-magazine'] = 8,
    ['uranium-rounds-magazine'] = 64,
    ['shotgun-shell'] = 4,
    ['piercing-shotgun-shell'] = 16,
    ['cannon-shell'] = 8,
    ['explosive-cannon-shell'] = 16,
    ['uranium-cannon-shell'] = 64,
    ['explosive-uranium-cannon-shell'] = 64,
    ['artillery-shell'] = 128,
    ['rocket'] = 8,
    ['explosive-rocket'] = 8,
    ['atomic-bomb'] = 16384,
    ['flamethrower-ammo'] = 32,
    ['grenade'] = 16,
    ['cluster-grenade'] = 64,
    ['poison-capsule'] = 64,
    ['slowdown-capsule'] = 16,
    ['defender-capsule'] = 16,
    ['distractor-capsule'] = 128,
    ['destroyer-capsule'] = 256,
    ['light-armor'] = 32,
    ['heavy-armor'] = 256,
    ['modular-armor'] = 1024,
    ['power-armor'] = 4096,
    ['power-armor-mk2'] = 32768,
    ['solar-panel-equipment'] = 256,
    ['fission-reactor-equipment'] = 8192,
    ['energy-shield-equipment'] = 512,
    ['energy-shield-mk2-equipment'] = 4096,
    ['battery-equipment'] = 128,
    ['battery-mk2-equipment'] = 2048,
    ['personal-laser-defense-equipment'] = 2048,
    ['discharge-defense-equipment'] = 2048,
    ['discharge-defense-remote'] = 32,
    ['belt-immunity-equipment'] = 256,
    ['exoskeleton-equipment'] = 1024,
    ['personal-roboport-equipment'] = 512,
    ['personal-roboport-mk2-equipment'] = 4096,
    ['night-vision-equipment'] = 256,
    ['stone-wall'] = 8,
    ['gate'] = 16,
    ['gun-turret'] = 64,
    ['laser-turret'] = 1024,
    ['flamethrower-turret'] = 2048,
    ['artillery-turret'] = 8192,
    ['radar'] = 32,
    ['rocket-silo'] = 65536
}

local item_names = {}
for k, _ in pairs(item_worths) do
    table_insert(item_names, k)
end
local size_of_item_names = #item_names

function Public.get_item_worth(name)
    return item_worths[name] or 0
end

local function get_raffle_keys()
    local raffle_keys = {}
    for i = 1, size_of_item_names, 1 do
        raffle_keys[i] = i
    end
    table_shuffle_table(raffle_keys)
    return raffle_keys
end

function Public.roll_item_stack(remaining_budget, blacklist, value_blacklist)
    if remaining_budget <= 0 then
        return false
    end
    local raffle_keys = get_raffle_keys()
    local item_name = false
    local item_worth = 0
    for _, index in pairs(raffle_keys) do
        item_name = item_names[index]
        item_worth = item_worths[item_name]
        if not blacklist[item_name] and item_worth <= remaining_budget and item_worth <= value_blacklist then
            break
        end
    end

    local stack_size = prototypes.item[item_name].stack_size * 32

    local item_count = 1

    for c = 1, math_random(1, stack_size), 1 do
        local price = c * item_worth
        if price <= remaining_budget then
            item_count = c
        else
            break
        end
    end

    return { name = item_name, count = item_count }
end

local function roll_item_stacks(remaining_budget, max_slots, blacklist, value_blacklist)
    local item_stack_set = {}
    local item_stack_set_worth = 0

    for i = 1, max_slots, 1 do
        if remaining_budget <= 0 then
            break
        end
        local item_stack = Public.roll_item_stack(remaining_budget, blacklist, value_blacklist)
        if item_stack then
            item_stack_set[i] = item_stack
            remaining_budget = remaining_budget - item_stack.count * item_worths[item_stack.name]
            item_stack_set_worth = item_stack_set_worth + item_stack.count * item_worths[item_stack.name]
        end
    end

    return item_stack_set, item_stack_set_worth
end

function Public.roll(budget, max_slots, blacklist, value_blacklist)
    if not budget then
        return {}
    end
    if not max_slots then
        return {}
    end

    local b, vb
    if not blacklist then
        b = {}
    else
        b = blacklist
    end
    if not value_blacklist then
        vb = 65536
    else
        vb = value_blacklist
    end

    budget = math_floor(budget)
    if budget == 0 then
        return {}
    end

    local final_stack_set
    local final_stack_set_worth = 0

    for _ = 1, 5, 1 do
        local item_stack_set, item_stack_set_worth = roll_item_stacks(budget, max_slots, b, vb)
        if item_stack_set_worth > final_stack_set_worth or item_stack_set_worth == budget then
            final_stack_set = item_stack_set
            final_stack_set_worth = item_stack_set_worth
        end
    end
    return final_stack_set
end

return Public
