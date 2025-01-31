local Public = {}

Public.treasures = {
    ['wooden-chest'] = {
        tech_bonus = 0.1,
        amount_multiplier = 1,
        description = 'an old wooden crate.'
    },
    ['iron-chest'] = {
        tech_bonus = 0.15,
        amount_multiplier = 1.5,
        description = 'an antique iron crate.'
    },
    ['steel-chest'] = {
        tech_bonus = 0.2,
        amount_multiplier = 2,
        description = 'a shiny metal box!'
    },
    ['crash-site-spaceship-wreck-medium-1'] = {
        tech_bonus = 0.25,
        amount_multiplier = 2.5,
        description = 'a spaceship wreck piece!'
    },
    ['crash-site-spaceship-wreck-medium-2'] = {
        tech_bonus = 0.25,
        amount_multiplier = 2.5,
        description = 'a space station wreck piece, containing some precious scrap!'
    },
    ['crash-site-spaceship-wreck-medium-3'] = {
        tech_bonus = 0.25,
        amount_multiplier = 2.5,
        description = 'a wreck piece, containing rare scrap!'
    },
    ['crash-site-spaceship-wreck-big-1'] = {
        tech_bonus = 0.30,
        amount_multiplier = 3,
        description = 'a big wreck.'
    },
    ['crash-site-spaceship-wreck-big-2'] = {
        tech_bonus = 0.30,
        amount_multiplier = 3,
        description = 'a station wreck!'
    },
    ['big-ship-wreck-1'] = {
        tech_bonus = 0.35,
        amount_multiplier = 3.5,
        description = 'a crashed space ship! The cargo is still intact!'
    },
    ['big-ship-wreck-2'] = {
        tech_bonus = 0.35,
        amount_multiplier = 3.5,
        description = 'a crashed space ship!'
    },
    ['big-ship-wreck-3'] = {
        tech_bonus = 0.35,
        amount_multiplier = 3.5,
        description = 'a crashed starship!'
    },
    ['crash-site-chest-1'] = {
        tech_bonus = 0.40,
        amount_multiplier = 4,
        description = 'a drop pod capsule! It is filled with useful loot!'
    },
    ['crash-site-chest-2'] = {
        tech_bonus = 0.40,
        amount_multiplier = 4,
        description = 'a cargo pod capsule! It is filled with nice things!'
    },
    ['crash-site-spaceship'] = {
        tech_bonus = 0.5,
        amount_multiplier = 5,
        description = 'a big crashed spaceship! There are treasures inside..'
    }
}

Public.chat_color = {200, 200, 200}

Public.starting_items = {
    ['pistol'] = 1,
    ['firearm-magazine'] = 8,
    ['wood'] = 8,
    ['raw-fish'] = 3
}

Public.reveal_chain_brush_sizes = {
    ['unit'] = 7,
    ['unit-spawner'] = 15,
    ['turret'] = 9
}

Public.spawn_market_items = {
    {price = {{'raw-fish', 1}}, offer = {type = 'give-item', item = 'rail', count = 2}},
    {price = {{'raw-fish', 1}}, offer = {type = 'give-item', item = 'rail-signal', count = 1}},
    {price = {{'raw-fish', 1}}, offer = {type = 'give-item', item = 'rail-chain-signal', count = 1}},
    {price = {{'raw-fish', 8}}, offer = {type = 'give-item', item = 'train-stop'}},
    {price = {{'raw-fish', 50}}, offer = {type = 'give-item', item = 'locomotive'}},
    {price = {{'raw-fish', 20}}, offer = {type = 'give-item', item = 'cargo-wagon'}},
    {price = {{'raw-fish', 3}}, offer = {type = 'give-item', item = 'decider-combinator'}},
    {price = {{'raw-fish', 3}}, offer = {type = 'give-item', item = 'arithmetic-combinator'}},
    {price = {{'raw-fish', 2}}, offer = {type = 'give-item', item = 'constant-combinator'}},
    {price = {{'raw-fish', 4}}, offer = {type = 'give-item', item = 'programmable-speaker'}},
    {price = {{'raw-fish', 2}}, offer = {type = 'give-item', item = 'small-lamp'}},
    {price = {{'raw-fish', 1}}, offer = {type = 'give-item', item = 'firearm-magazine', count = 2}},
    {price = {{'raw-fish', 2}}, offer = {type = 'give-item', item = 'piercing-rounds-magazine'}},
    {price = {{'raw-fish', 2}}, offer = {type = 'give-item', item = 'grenade'}},
    {price = {{'raw-fish', 1}}, offer = {type = 'give-item', item = 'land-mine'}},
    {price = {{'raw-fish', 1}}, offer = {type = 'give-item', item = 'explosives', count = 3}},
    {price = {{'raw-fish', 1}}, offer = {type = 'give-item', item = 'wood', count = 10}},
    {price = {{'raw-fish', 1}}, offer = {type = 'give-item', item = 'iron-ore', count = 10}},
    {price = {{'raw-fish', 1}}, offer = {type = 'give-item', item = 'copper-ore', count = 10}},
    {price = {{'raw-fish', 1}}, offer = {type = 'give-item', item = 'stone', count = 10}},
    {price = {{'raw-fish', 1}}, offer = {type = 'give-item', item = 'coal', count = 10}},
    {price = {{'raw-fish', 1}}, offer = {type = 'give-item', item = 'uranium-ore', count = 5}},
    {price = {{'wood', 15}}, offer = {type = 'give-item', item = 'raw-fish', count = 1}},
    {price = {{'iron-ore', 15}}, offer = {type = 'give-item', item = 'raw-fish', count = 1}},
    {price = {{'copper-ore', 15}}, offer = {type = 'give-item', item = 'raw-fish', count = 1}},
    {price = {{'stone', 15}}, offer = {type = 'give-item', item = 'raw-fish', count = 1}},
    {price = {{'coal', 15}}, offer = {type = 'give-item', item = 'raw-fish', count = 1}},
    {price = {{'uranium-ore', 7}}, offer = {type = 'give-item', item = 'raw-fish', count = 1}}
}

Public.pickaxe_tiers = {
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
    'Netherite',
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

return Public
