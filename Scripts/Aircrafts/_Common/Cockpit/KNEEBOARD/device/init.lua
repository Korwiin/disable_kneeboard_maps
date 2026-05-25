-- KNEEBOARD/device/init.lua
-- Override: disables automatic per-waypoint map page generation.
-- Full original content is preserved below so avKneeboard gets all
-- expected variables. The callbacks are redefined as no-ops at the bottom.

device_timer_dt         = 0.05

local units_scale_factor = 1
terrainVersion           = get_terrain_related_data("edterrainVersion") or 3.0
theatre                  = get_terrain_related_data("name")

local caucasus = theatre == "Caucasus"

if terrainVersion < 4.0 then
    dofile(LockOn_Options.common_script_path.."tools.lua")
    use_lat_lon                 = true
    lat_lon_aspect, meters_per_lon_degree = get_lat_lon_scaling()
    units_scale_factor          = 1 / meters_per_lon_degree
end

function NM(nm)
    return nm * 1852.0 * units_scale_factor
end

if terrainVersion < 4.0 then
    chart_defaults = {
        {scale = NM(5),   chart = 3},
        {scale = NM(10),  chart = 3},
        {scale = NM(20),  chart = 5},
        {scale = NM(40),  chart = 6},
        {scale = NM(80),  chart = 7},
        {scale = NM(160), chart = 8},
    }
elseif caucasus then
    chart_defaults = {
        {scale = NM(5),   chart = 2},
        {scale = NM(10),  chart = 2},
        {scale = NM(20),  chart = 3},
        {scale = NM(40),  chart = 3},
        {scale = NM(80),  chart = 6},
        {scale = NM(160), chart = 6},
    }
else
    chart_defaults = {
        {scale = NM(5),   chart = 2},
        {scale = NM(10),  chart = 2},
        {scale = NM(20),  chart = 4},
        {scale = NM(40),  chart = 4},
        {scale = NM(80),  chart = 5},
        {scale = NM(160), chart = 6},
    }
end

default_scale = chart_defaults[2].scale
default_chart = chart_defaults[3].chart

function default_map(i, xx, zz)
    return {scale   = chart_defaults[i].scale,
            chart   = chart_defaults[i].chart,
            x       = xx or x_start,
            z       = zz or z_start,
            dont_use_in_waypoint_check = true}
end

need_to_be_closed   = true

local aspect_ratio_fov = 0.214 / 0.142

function test_contain(map, threshold, X, Z)
    if map.dont_use_in_waypoint_check or
       map.x == nil or
       map.z == nil then
        return false
    end
    local z_max = map.scale * (1 - threshold)
    local x_max = map.scale * (aspect_ratio_fov - threshold)
    local d_x   = X - map.x
    local d_z   = Z - map.z
    if map.rotation ~= nil then
        local sin_a = math.sin(-map.rotation)
        local cos_a = math.cos(-map.rotation)
        local x = d_x
        local z = d_z
        d_z = z * cos_a - x * sin_a
        d_x = z * sin_a + x * cos_a
    end
    return math.abs(d_x) < x_max and math.abs(d_z) < z_max
end

-- -------------------------------------------------------
-- DISABLED: the original callbacks are redefined below.
-- Redefining a function in Lua overwrites the earlier
-- definition, so only the no-op versions below will run.
-- -------------------------------------------------------

function on_waypoint_adding(x, z, course)
    -- no-op: prevents per-waypoint map pages from being generated
end

function generate_maps()
    map_pages = {}   -- ensure avKneeboard has an empty list to read
end

note_generate_template  = nil   -- suppresses per-waypoint text note pages
number_of_additional_pages = 0  -- tell avKneeboard to expect zero extra pages
