local CommonFunctions = require 'utils.common'
local Global = require 'utils.global'

local Public = {}
local this = {}
local insert = table.insert
local remove = table.remove
local random = math.random

Global.register(
    this,
    function (tbl)
        this = tbl
    end
)

--[[
init - Initialize claim system.
@param names - Table of entity names that should be used as a marker.
@param max_distance - Maximal distance allowed between markers
--]]
Public.init = function (names, max_distance)
    if type(names) ~= 'table' then
        names = { names }
    end

    this._claims_info = {}
    this._claims_visible_to = {}
    this._claim_markers = names
    this._claim_max_dist = max_distance
end

local function claim_new_claim(ent)
    local point = {
        {
            x = CommonFunctions.get_axis(ent.position, 'x'),
            y = CommonFunctions.get_axis(ent.position, 'y')
        }
    }

    if this._claims_info[ent.force.name] == nil then
        this._claims_info[ent.force.name] = {}
        this._claims_info[ent.force.name].polygons = {}
        this._claims_info[ent.force.name].claims = {}
        this._claims_info[ent.force.name].collections = {}
    end

    if this._claims_info[ent.force.name].collections then
        this._claims_info[ent.force.name].collections[#this._claims_info[ent.force.name].collections + 1] = point
    end
end

local function claim_on_build_entity(ent)
    local max_dist = this._claim_max_dist
    local force = ent.force.name
    local data = this._claims_info[force]

    if not max_dist then
        return
    end

    if data == nil then
        claim_new_claim(ent)
        return
    end

    local in_range = false
    for i = 1, #data.collections do
        if data.collections[i] then
            for _, point in pairs(data.collections[i]) do
                if point then
                    local dist = CommonFunctions.get_distance(point, ent.position)
                    if max_dist < dist then
                        goto continue
                    end

                    in_range = true
                    point = {
                        x = CommonFunctions.get_axis(ent.position, 'x'),
                        y = CommonFunctions.get_axis(ent.position, 'y')
                    }
                    insert(data.collections[i], point)
                    data.claims[i] = CommonFunctions.get_convex_hull(data.collections[i])

                    break
                    ::continue::
                end
            end
        end
    end

    if not in_range then
        claim_new_claim(ent)
    end
end

local function claims_in_markers(name)
    if not this._claim_markers then
        return false
    end

    for _, marker in pairs(this._claim_markers) do
        if name == marker then
            return true
        end
    end

    return false
end

--[[
on_build_entity - Event processing function.
@param ent - Entity
--]]
Public.on_built_entity = function (ent)
    if not claims_in_markers(ent.name) then
        return
    end
    claim_on_build_entity(ent)
end

local function claim_on_entity_died(ent)
    local force = ent.force.name
    local data = this._claims_info[force]
    if data == nil then
        return
    end

    for i = 1, #data.collections do
        for j = 1, #data.collections[i] do
            local point = data.collections[i][j]
            if CommonFunctions.positions_equal(point, ent.position) then
                remove(data.collections[i], j)

                data.claims[i] = CommonFunctions.get_convex_hull(data.collections[i])
                break
            end
        end

        if #data.collections[i] == 0 then
            remove(data.claims, i)
            remove(data.collections, i)
            break
        end
    end

    if #data.claims == 0 then
        this._claims_info[force] = nil
    end
end

--[[
on_entity_died - Event processing function.
@param ent - Entity
--]]
Public.on_entity_died = function (ent)
    if not claims_in_markers(ent.name) then
        return
    end
    claim_on_entity_died(ent)
end

--[[
on_player_mined_entity - Event processing function.
@param ent - Entity
--]]
Public.on_player_mined_entity = function (ent)
    Public.on_entity_died(ent)
end

--[[
on_player_died - Event processing function
@param player - Player
--]]
Public.on_player_died = function (player)
    this._claims_info[player.name] = nil
end

Public.clear_player_base = function (player)
    if not player or not player.valid then
        return
    end

    local position = player.position
    local x, y = position.x, position.y
    local entities = player.surface.find_entities_filtered { force = player.force, area = { { x - 50, y - 50 }, { x + 50, y + 50 } } }

    for i = 1, #entities do
        local e = entities[i]
        if e and e.valid then
            if e.health then
                e.health = e.health - random(30, 180)
                if e.health <= 0 then
                    e.die('enemy')
                end
            end
        end
    end
end

--[[
get_claims - Get all claims data points for given force.
@param f_name - Force name.
--]]
Public.get_claims = function (f_name)
    if this._claims_info[f_name] == nil then
        return {}
    end

    return this._claims_info[f_name].claims
end

local function claims_update_visiblity()
    if #this._claims_visible_to == 0 then
        for _, info in pairs(this._claims_info) do
            for _, id in pairs(info.polygons) do
                if rendering.is_valid(id) then
                    rendering.set_visible(id, false)
                end
            end
        end
        return
    end

    for _, info in pairs(this._claims_info) do
        for _, id in pairs(info.polygons) do
            if rendering.is_valid(id) then
                rendering.set_visible(id, true)
                rendering.set_players(id, this._claims_visible_to)
            end
        end
    end
end

--[[
set_visibility_to - Specifies who can see the claims and redraws.
@param name - Name of a player.
--]]
Public.set_visibility_to = function (name)
    for _, p in pairs(this._claims_visible_to) do
        if p == name then
            return
        end
    end

    insert(this._claims_visible_to, name)
    claims_update_visiblity()
end

--[[
remove_visibility_from - Remove the claim visibility from the player.
@param name - Name of a player.
--]]
Public.remove_visibility_from = function (name)
    for i = 1, #this._claims_visible_to do
        local p = this._claims_visible_to[i]
        if p == name then
            remove(this._claims_visible_to, i)
            claims_update_visiblity()
            break
        end
    end
end

return Public
