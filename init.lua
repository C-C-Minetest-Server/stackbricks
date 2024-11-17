-- stackbricks/init.lua
-- Bricks stacked on another type of bricks
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

local core = core
local min = math.min

stackbricks = {}
local stackbricks = stackbricks

local S = core.get_translator("stackbricks")
local logger = logging.logger("stackbricks")

function stackbricks.register_stackbrick(name, top, bottom, use_bottom_def)
    local top_def = core.registered_nodes[top]
    local bottom_def = core.registered_nodes[bottom]

    -- +Y, -Y, +X, -X, +Z, -Z tiles
    local top_tiles = top_def.tiles or {}
    local bottom_tiles = bottom_def.tiles or {}
    if #top_tiles == 0 then
        logger:error("In %s: Top tile not found.")
        top_tiles[1] = ""
    end
    if #bottom_tiles == 0 then
        logger:error("In %s: Bottom tile not found.")
        bottom_tiles[1] = ""
    end

    local result_tiles = {}
    for i = 1, 6 do
        local top_tile, bottom_tile = top_tiles[min(#top_tiles, i)], bottom_tiles[min(#bottom_tiles, i)]
        if type(top_tile) == "table" then
            logger:warning("In %s: Top tile #%d is in table format.", name, i)
            top_tile = top_tile.name or top_tile.image
        end
        if type(bottom_tile) == "table" then
            logger:warning("In %s: Bottom tile #%d is in table format.", name, i)
            bottom_tile = bottom_tile.name or bottom_tile.image
        end
        if i == 1 then
            result_tiles[i] = top_tile
        elseif i == 2 then
            result_tiles[i] = bottom_tile
        else
            result_tiles[i] = top_tile .. "^[lowpart:50:(" .. bottom_tile .. ")"
        end
    end

    core.register_node(name, {
        description = S("@1 on @2", top_def.description or top, bottom_def.description or bottom),
        tiles = result_tiles,
        groups = use_bottom_def and bottom_def.groups or top_def.groups,
        sounds = use_bottom_def and bottom_def.aounds or top_def.aounds,
    })

    local top_subname = string.split(top, ":", false, 1)[2]
    local bottom_subname = string.split(bottom, ":", false, 1)[2]

    local top_default_slab = "stairs:slab_" .. top_subname
    local bottom_default_slab = "stairs:slab_" .. bottom_subname
    local top_moreblocks_slab = "moreblocks:slab_" .. top_subname
    local bottom_moreblocks_slab = "moreblocks:slab_" .. bottom_subname

    local top_slab =
        core.registered_nodes[top_moreblocks_slab] and top_moreblocks_slab
        or core.registered_nodes[top_default_slab] and top_default_slab
        or nil
    local bottom_slab =
        core.registered_nodes[bottom_moreblocks_slab] and bottom_moreblocks_slab
        or core.registered_nodes[bottom_default_slab] and bottom_default_slab
        or nil

    if top_slab and bottom_slab then
        core.register_craft({
            output = name,
            recipe = {
                { top_slab },
                { bottom_slab }
            }
        })
    end

    core.register_craft({
        output = name .. " 2",
        recipe = {
            { top },
            { bottom }
        }
    })
end

local bricks = {}
for _, name in ipairs({
    "default:stonebrick",
    "default:desert_stonebrick",
    "default:sandstonebrick",
    "default:silver_sandstone_brick",
    "moreblocks:iron_stone_bricks",
    "moreblocks:coal_stone_bricks",
    "technic:granite_bricks",
    "technic:marble_bricks",
    "ethereal:snowbrick",
    "ethereal:icebrick",
}) do
    if core.registered_nodes[name] then
        bricks[#bricks + 1] = name
    end
end

-- Permutation!
for _, top in ipairs(bricks) do
    for _, bottom in ipairs(bricks) do
        if top ~= bottom then
            local use_bottom_def = top == "ethereal:snowbrick"
            local top_subname = string.split(top, ":", false, 1)[2]
            local bottom_subname = string.split(bottom, ":", false, 1)[2]
            local itemname = "stackbricks:" .. top_subname .. "_on_" .. bottom_subname
            stackbricks.register_stackbrick(itemname, top, bottom, use_bottom_def)
        end
    end
end
