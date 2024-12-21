-- one table to rule them all!
local Global = require 'utils.global'
local Server = require 'utils.server'
local Event = require 'utils.event'
local Task = require 'utils.task_token'

local stateful_settings = {
    reversed = false
}

local this = {
    players = {},
    traps = {},
    scheduler = {
        start_after = 0,
        surface = nil,
        operation = nil,
        next_operation = nil
    },
    -- new initializer for scenario management because the old one sucked hard
    current_task = {
        state = 'move_players',
        surface_name = 'Init',
        default_task = 'move_players',
        show_messages = true,
        step = 1
    },
    adjusted_zones = {
        scrap = {},
        forest = {},
        size = nil,
        shuffled_zones = nil,
        starting_zone = true,
        reversed = stateful_settings.reversed,
        disable_terrain = false
    }
}


local Public = {}
local random = math.random
local dataset = 'scenario_settings'
local dataset_key = 'mtn_v3_table'
local dataset_key_dev = 'mtn_v3_table_dev'

Public.events = {
    reset_map = Event.generate_event_name('reset_map'),
    on_entity_mined = Event.generate_event_name('on_entity_mined'),
    on_market_item_purchased = Event.generate_event_name('on_market_item_purchased'),
    on_locomotive_cargo_missing = Event.generate_event_name('on_locomotive_cargo_missing'),
}

local init_name = 'Init'
Public.init_name = init_name
local scenario_name = 'fortress'
Public.scenario_name = scenario_name
local discord_name = 'Mtn Fortress'
Public.discord_name = discord_name

Public.is_modded = script.active_mods['MtnFortressAddons'] or false

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

Global.register(
    stateful_settings,
    function (tbl)
        stateful_settings = tbl
    end
)

Public.zone_settings = {
    zone_depth = 704,
    zone_width = 510
}

Public.valid_enemy_forces = {
    ['enemy'] = true,
    ['aggressors'] = true,
    ['aggressors_frenzy'] = true
}

Public.pickaxe_upgrades = {
    'Wood',
    'Plastic',
    'Bone',
    'Alabaster',
    'Lead',
    'Zinc',
    'Tin',
    'Salt',
    'Bauxite',
    'Borax',
    'Bismuth',
    'Amber',
    'Galena',
    'Calcite',
    'Aluminium',
    'Silver',
    'Gold',
    'Copper',
    'Marble',
    'Brass',
    'Flourite',
    'Platinum',
    'Nickel',
    'Iron',
    'Manganese',
    'Apatite',
    'Uraninite',
    'Turquoise',
    'Hematite',
    'Glass',
    'Magnetite',
    'Concrete',
    'Pyrite',
    'Steel',
    'Zircon',
    'Titanium',
    'Silicon',
    'Quartz',
    'Garnet',
    'Flint',
    'Tourmaline',
    'Beryl',
    'Topaz',
    'Chrysoberyl',
    'Chromium',
    'Tungsten',
    'Corundum',
    'Tungsten',
    'Diamond',
    'Penumbrite',
    'Meteorite',
    'Crimtane',
    'Obsidian',
    'Demonite',
    'Mythril',
    'Adamantite',
    'Chlorophyte',
    'Densinium',
    'Luminite'
}

function Public.reset_main_table()
    -- @start
    this.space_age = script.active_mods['space-age'] or false
    this.modded = script.active_mods['MtnFortressAddons'] or false
    -- these 3 are in case of stop/start/reloading the instance.
    this.soft_reset = true
    this.restart = false
    this.shutdown = false
    this.announced_message = false
    this.notified_game_over = false
    this.game_reset_tick = nil
    this.find_void_tiles_and_replace = nil
    -- @end
    this.breach_wall_warning = false
    this.icw_locomotive = nil
    this.game_lost = false
    this.charts = {
        tags = {}
    }
    this.statistics = {
        surfaces_produced = {}
    }
    this.death_mode = false
    this.collapse_started = false
    this.locomotive_position = nil
    this.locomotive_health = 10000
    this.locomotive_max_health = 10000
    this.extra_wagons = 0
    this.toolbelt_researched_count = 0
    this.all_the_fish = false
    this.reverse_collapse_warning = false
    this.gap_between_zones = {
        set = false,
        gap = 900,
        neg_gap = 500,
        highest_pos = 0
    }
    this.gap_between_locomotive = {
        hinders = {},
        gap = 900,
        neg_gap = 3520,          -- earlier 2112 (3 zones, whereas 704 is one zone)
        neg_gap_collapse = 5520, -- earlier 2112 (3 zones, whereas 704 is one zone)
        highest_pos = nil
    }
    this.force_chunk = false
    this.bw = false
    this.debug_vars = {
        enabled = true,
        vars = {
            mining_chance = {}
        }
    }
    this.allow_decon = true
    this.block_non_trusted_opening_trains = true
    this.block_non_trusted_trigger_collapse = true
    this.allow_decon_main_surface = true
    this.spectate_button_disable = true
    this.flamethrower_damage = {}
    this.mined_scrap = 0
    this.print_tech_to_discord = true
    this.biters_killed = 0
    this.cleared_fortress = false
    this.locomotive_pos = { tbl = {} }
    this.trusted_only_car_tanks = true
    --!grief prevention
    this.enable_arties = 6 -- default to callback 6
    --!snip
    this.enemy_spawners = {
        spawners = {},
        enabled = false
    }
    this.poison_deployed = false
    this.robotics_deployed = false
    this.upgrades = {
        showed_text = false,
        burner_generator = {
            limit = 100,
            bought = 0
        },
        landmine = {
            limit = 25,
            bought = 0,
            built = 0
        },
        flame_turret = {
            limit = 6,
            bought = 0,
            built = 0
        },
        unit_number = {
            landmine = {},
            flame_turret = {}
        },
        has_upgraded_health_pool = false,
        has_upgraded_tile_when_mining = false,
        explosive_bullets_purchased = false,
        xp_points_upgrade = 0,
        aura_upgrades = 0,
        aura_upgrades_max = 12, -- = (aura_limit - locomotive_aura_radius) / 5
        locomotive_aura_radius = 40,
        train_upgrade_contribution = 0,
        xp_points = 0,
        health_upgrades = 0,
        pickaxe_tier = 1
    }
    this.orbital_strikes = {
        enabled = true
    }
    this.pickaxe_speed_per_purchase = 0.09
    this.breached_wall = 1
    this.pre_final_battle = false
    this.final_battle = false
    this.disable_link_chest_cheese_mode = true
    this.left_top = {
        x = 0,
        y = 0
    }
    this.biters = {
        amount = 0,
        limit = 512
    }
    this.traps = {}
    this.munch_time = true
    this.magic_requirement = 50
    this.loot_stats = {
        rare = 48,
        normal = 48
    }
    this.coin_amount = 1
    this.difficulty_set = false
    this.bonus_xp_on_join = 250
    this.main_market_items = {}
    this.spill_items_to_surface = false
    this.spectate = {}
    this.placed_trains_in_zone = {
        limit = 1,
        randomized = false,
        zones = {}
    }
    this.market_limits = {
        chests_outside_limit = 8,
        aura_limit = 100, -- limited to save UPS
        pickaxe_tier_limit = 59,
        health_upgrades_limit = 100,
        xp_points_limit = 40
    }
    this.marked_fixed_prices = {
        chests_outside_cost = 3000,
        health_cost = 14000,
        pickaxe_cost = 3000,
        aura_cost = 4000,
        xp_point_boost_cost = 2500,
        explosive_bullets_cost = 10000,
        flamethrower_turrets_cost = 3000,
        land_mine_cost = 2,
        car_health_upgrade_pool_cost = 100000,
        tile_when_mining_cost = random(45000, 70000),
        roboport_cost = random(750, 1500),
        construction_bot_cost = random(150, 350),
        chest_cost = random(400, 600)
    }
    this.mystical_chest_price = nil
    this.collapse_grace = true
    this.corpse_removal_disabled = true
    this.locomotive_biter = nil
    this.disconnect_wagon = false
    this.collapse_amount = false
    this.collapse_speed = false
    this.y_value_position = 20
    this.spawn_near_collapse = {
        active = true,
        total_pos = 35,
        compare = -150,
        compare_next = 200,
        distance_from = 2
    }
    this.spidertron_unlocked_at_zone = 11
    this.spidertron_unlocked_enabled = false
    -- this.void_or_tile = 'lab-dark-2'
    if Public.is_modded then
        this.void_or_tile = 'void-tile'
    else
        this.void_or_tile = 'out-of-map'
    end
    this.validate_spider = {}
    this.check_afk_players = true
    this.winter_mode = false
    this.sent_to_discord = false
    this.random_seed = random(100000000, 1000000000)
    this.difficulty = {
        multiply = 0.25,
        highest = 10,
        lowest = 4
    }
    this.mining_bonus_till_wave = 300
    this.mining_bonus = 0
    this.disable_mining_boost = false
    this.market_announce = game.tick + 1200
    this.check_heavy_damage = true
    this.prestige_system_enabled = false
    this.mystical_chest_completed = 0
    this.mystical_chest_enabled = true
    this.check_if_threat_below_zero = true
    this.rocks_to_remove = nil
    this.tiles_to_replace = nil
    this.mc_rewards = {
        current = {},
        temp_boosts = {}
    }

    this.adjusted_zones = {
        scrap = {},
        forest = {},
        size = nil,
        shuffled_zones = nil,
        starting_zone = true,
        reversed = stateful_settings.reversed,
        disable_terrain = false
    }
    this.alert_zone_1 = false             -- alert the players
    this.radars_reveal_new_chunks = false -- allows for the player to explore the map instead,

    this.mining_utils = {
        rocks_yield_ore_maximum_amount = 500,
        type_modifier = 1,
        rocks_yield_ore_base_amount = 40,
        rocks_yield_ore_distance_modifier = 0.020
    }

    this.wagons_in_the_wild = {}
    this.player_market_settings = {}

    this.quality_list = {
        'normal',
    }

    for k, _ in pairs(this.players) do
        this.players[k] = {}
    end
end

function Public.enable_bw(state)
    this.bw = state or false
end

--- Returns the main table or a specific key from the main table.
---@param key any
---@return any
function Public.get(key)
    if key then
        return this[key]
    else
        return this
    end
end

function Public.get_stateful_settings(key)
    if key then
        return stateful_settings[key]
    else
        return stateful_settings
    end
end

function Public.set(key, value)
    if key and (value or value == false) then
        this[key] = value
        return this[key]
    elseif key then
        return this[key]
    else
        return this
    end
end

function Public.set_stateful_settings(key, value)
    if key and (value or value == false) then
        stateful_settings[key] = value
    end
    Public.save_stateful_settings()
end

function Public.set_task(task, surface_name)
    this.current_task.state = task
    this.current_task.surface_name = surface_name or 'Init'
end

function Public.is_task_done()
    return this.current_task and this.current_task.done or false
end

function Public.set_show_messages(state)
    this.current_task.show_messages = state or false
end

function Public.remove(key, sub_key)
    if key and sub_key then
        if this[key] and this[key][sub_key] then
            this[key][sub_key] = nil
        end
    elseif key then
        if this[key] then
            this[key] = nil
        end
    end
end

function Public.save_stateful_settings()
    local server_name_matches = Server.check_server_name(Public.discord_name)

    if server_name_matches then
        Server.set_data(dataset, dataset_key, stateful_settings)
    else
        Server.set_data(dataset, dataset_key_dev, stateful_settings)
    end
end

local apply_settings_token =
    Task.register(
        function (data)
            local server_name_matches = Server.check_server_name(Public.discord_name)
            local settings = data and data.value or nil

            if not settings then
                if server_name_matches then
                    Server.set_data(dataset, dataset_key, stateful_settings)
                else
                    Server.set_data(dataset, dataset_key_dev, stateful_settings)
                end
            else
                for k, v in pairs(settings) do
                    stateful_settings[k] = v
                end
            end

            Public.stateful_on_server_started()
        end
    )

Event.add(
    Server.events.on_server_started,
    function ()
        local start_data = Server.get_start_data()

        if not start_data.initialized then
            local server_name_matches = Server.check_server_name(Public.discord_name)

            if server_name_matches then
                Server.try_get_data(dataset, dataset_key, apply_settings_token)
            else
                Server.try_get_data(dataset, dataset_key_dev, apply_settings_token)
            end
            start_data.initialized = true
        end
    end
)

return Public
