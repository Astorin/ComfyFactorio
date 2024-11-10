local Event = require 'utils.event'

local script_data =
{
	finished = {},
	victory_location = "solar-system-edge",
	no_victory = false
}

local on_space_platform_changed_state = function (event)
	if script_data.no_victory then return end

	if not script_data.victory_location then return end

	local platform = event.platform
	if not (platform and platform.valid) then return end

	if not platform.space_location then return end
	if platform.space_location.name ~= script_data.victory_location then return end

	local force = platform.force
	if script_data.finished[force.name] then return end
	script_data.finished[force.name] = true

	game.reset_game_state()
	game.set_game_state
	{
		game_finished = true,
		player_won = true,
		can_continue = true,
		victorious_force = force
	}
end

remote.add_interface("space_finish_script",
	{
		set_victory_location = function (location)
			script_data.victory_location = location
		end,
		set_no_victory = function (bool)
			script_data.no_victory = bool
		end,
		get_no_victory = function ()
			return script_data.no_victory
		end,
	})

Event.add(defines.events.on_space_platform_changed_state, on_space_platform_changed_state)

Event.on_configuration_changed(function ()
	script_data = storage.space_finish_script or script_data
end)

Event.on_init(function ()
	storage.space_finish_script = storage.space_finish_script or script_data
end)

Event.on_load(function ()
	script_data = storage.space_finish_script or script_data
end)
