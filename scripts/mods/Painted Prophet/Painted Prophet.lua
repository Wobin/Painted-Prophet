--[[
	Name: Painted Prophet
	Author: Wobin
	Date: 14/10/2026
	Repository: https://github.com/Wobin/Painted-Prophet
]]--

local mod = get_mod("Painted Prophet")
mod.version = mod.get_metadata and mod:get_metadata("version") or "unknown"

local math_floor = math.floor
local math_max = math.max
local math_min = math.min
local string_format = string.format
local pairs = pairs
local ipairs = ipairs
local type = type

local FAMILIES = { "nurgle", "warp" }
local VARIABLE = "lighting_far_range"
local STOCK_VALUE = 1000
local HUE_STEPS = 1024
local SATURATION_STEPS = 15
local CODE_DIVISOR = 16384
local STOCK_BRIGHTNESS = 8
local MIN_BRIGHTNESS = 1
local MAX_BRIGHTNESS = 15
local RAINBOW_CYCLES_PER_SECOND = 0.25
local PENDING_FRAMES = 30
local RING_TEMPLATE = "renegade_psyker_boss_circle_dance"
local RING_CLOUD = "decal_ring_center"
local RING_SLOT = "decal"
local RING_VARIABLE = "color_tint"
local MATERIAL_FORMAT = { expected = 62, probe = "../bundle/data/e9/e90383bc561fd9ae" }
local REDIRECT_CONTRACT = "painted_prophet/live_hsv"
local REDIRECTS = {
	{
		stock = "data/ed/eda5ef3da1b851e0",
		file = "payload/eda5ef3da1b851e0.livehsv",
		sha256 = "11e455025911b9a79b32e4e0908d8b93a7288c5ed59c3fd8474aca64deda1fbb",
		material = "\142\011\215\088\161\250\147\157",
	},
}

-- Colour functions

local function rgb_to_hsv(r, g, b)
	local max = math_max(r, g, b)
	local min = math_min(r, g, b)
	local delta = max - min
	local hue = 0

	if delta > 0 then
		if max == r then
			hue = ((g - b) / delta) % 6
		elseif max == g then
			hue = (b - r) / delta + 2
		else
			hue = (r - g) / delta + 4
		end

		hue = hue / 6
	end

	local saturation = max > 0 and delta / max or 0

	return hue, saturation, max
end

local function hsv_to_rgb(h, s, v)
	local i = math_floor(h * 6)
	local f = h * 6 - i
	local p = v * (1 - s)
	local q = v * (1 - f * s)
	local t = v * (1 - (1 - f) * s)
	local sector = i % 6

	if sector == 0 then
		return v, t, p
	elseif sector == 1 then
		return q, v, p
	elseif sector == 2 then
		return p, v, t
	elseif sector == 3 then
		return p, q, v
	elseif sector == 4 then
		return t, p, v
	end

	return v, p, q
end

local function clamp_brightness(brightness)
	local step = math_floor((brightness or STOCK_BRIGHTNESS) + 0.5)

	if step < MIN_BRIGHTNESS then
		return MIN_BRIGHTNESS
	elseif step > MAX_BRIGHTNESS then
		return MAX_BRIGHTNESS
	end

	return step
end

local function rainbow_hue(t)
	local phase = t * RAINBOW_CYCLES_PER_SECOND

	return phase - math_floor(phase)
end

local function encoded_value(profile, t)
	local mode = profile.mode

	if mode == "stock" then
		return STOCK_VALUE
	end

	local hue = profile.hue
	local saturation = profile.saturation

	if mode == "rainbow" then
		hue = rainbow_hue(t)
		saturation = 1
	end

	local hue_step = math_floor(hue * HUE_STEPS) % HUE_STEPS
	local saturation_step = math_floor(saturation * SATURATION_STEPS + 0.5)
	local brightness_step = clamp_brightness(profile.brightness)

	return STOCK_VALUE + saturation_step + (hue_step * 16 + brightness_step) / CODE_DIVISOR
end

local function profile_rgb(profile, t)
	local scale = clamp_brightness(profile.brightness) / STOCK_BRIGHTNESS

	local hue, saturation = profile.hue, profile.saturation

	if profile.mode == "rainbow" then
		hue, saturation = rainbow_hue(t), 1
	end

	local r, g, b = hsv_to_rgb(hue, saturation, 1)

	return r * scale, g * scale, b * scale
end

-- Settings

local _profiles = {}
local _debug_logging = false

for i = 1, #FAMILIES do
	_profiles[FAMILIES[i]] = { mode = "stock", hue = 0, saturation = 0, brightness = STOCK_BRIGHTNESS, r = 0, g = 0, b = 0 }
end

local function cache_settings()
	_debug_logging = mod:get("debug_logging") == true

	for i = 1, #FAMILIES do
		local family = FAMILIES[i]
		local profile = _profiles[family]
		local mode = mod:get(family .. "_mode")

		profile.mode = (mode == "custom" or mode == "rainbow") and mode or "stock"
		profile.brightness = clamp_brightness(mod:get(family .. "_brightness"))

		local colour = mod:get(family .. "_colour")

		if type(colour) == "table" then
			profile.r = (colour[2] or 0) / 255
			profile.g = (colour[3] or 0) / 255
			profile.b = (colour[4] or 0) / 255
			profile.hue, profile.saturation = rgb_to_hsv(profile.r, profile.g, profile.b)
		end
	end
end

-- Effects

local EFFECT_PREFIX = "content/fx/particles/enemies/renegade_wizard/"
local CLOUD = {
	core_256be307 = "\023\224\247\145\225\232\101\204",
	table_2b846346 = "\055\191\020\062\041\185\098\085",
	table_41827390 = "\208\180\073\246\112\228\150\161",
	table_cc263f6f = "\190\023\193\222\039\014\072\215",
	slice_gas_a6e0418d = "\063\089\218\030\071\068\200\147",
	gas_center_2abf7155 = "\117\254\230\225\034\164\081\114",
	spores_e4a8aa4b = "\205\053\149\218\059\229\030\007",
	climax_flies_6a94945b = "\052\251\110\109\152\021\009\008",
	impact_flies_c1d37aad = "\131\139\091\161\101\212\017\243",
	impact_08963273 = "\055\181\097\118\047\219\220\165",
	impact_0ba78e70 = "\135\029\228\079\003\134\069\177",
	impact_81e0d74a = "\219\236\248\093\103\134\173\039",
	smoke_31e6394a = "\190\168\097\137\041\049\017\163",
	warp_chunk_d1653945 = "\179\118\009\187\068\123\154\181",
	warp_b1a346c7 = "\135\133\145\037\163\224\190\030",
	warp_clouds_f6f5e7c5 = "\170\163\172\240\055\041\138\142",
	warp_trail_acc82bbd = "\032\211\114\207\125\051\176\008",
	pulse_47f9f7e2 = "\134\034\135\148\106\006\169\229",
}

local function rgb(cand, variable)
	return { cand = cand, kind = "rgb", variable = variable }
end

local function hsv(cand)
	return { cand = cand, kind = "hsv" }
end

local SPLATTER = "material_variable_97b30de8"
local WARP_CLOUD = "material_variable_5262b8a1"
local GAS = "lerp_color_b"

local function list(...)
	local out = {}

	for _, item in ipairs({ ... }) do
		if item.cand then
			out[#out + 1] = item
		else
			for i = 1, #item do
				out[#out + 1] = item[i]
			end
		end
	end

	return out
end

local function table_clouds(variable)
	return { rgb(CLOUD.table_2b846346, variable), rgb(CLOUD.table_41827390, variable), rgb(CLOUD.table_cc263f6f, variable) }
end

local function slice_entry()
	return { family = "nurgle", clouds = list(table_clouds(SPLATTER), rgb(CLOUD.slice_gas_a6e0418d, GAS)) }
end

local EFFECTS = {
	[EFFECT_PREFIX .. "renegade_wizard_ring_damage_center"] = { family = "nurgle", clouds = { rgb(CLOUD.gas_center_2abf7155, GAS) } },
	[EFFECT_PREFIX .. "renegade_wizard_ring_damage_slice_01"] = slice_entry(),
	[EFFECT_PREFIX .. "renegade_wizard_ring_damage_slice_02"] = slice_entry(),
	[EFFECT_PREFIX .. "renegade_wizard_ring_damage_slice_03"] = slice_entry(),
	[EFFECT_PREFIX .. "renegade_wizard_ring_damage_slice_04"] = slice_entry(),
	[EFFECT_PREFIX .. "renegade_wizard_staff_anticipation_nurgle_01"] = { family = "nurgle", clouds = { hsv(CLOUD.core_256be307), rgb(CLOUD.spores_e4a8aa4b, GAS) } },
	[EFFECT_PREFIX .. "renegade_wizard_staff_climax_nurgle_01"] = { family = "nurgle", clouds = list(hsv(CLOUD.core_256be307), table_clouds(SPLATTER), rgb(CLOUD.climax_flies_6a94945b, GAS)) },
	[EFFECT_PREFIX .. "renegade_wizard_projectile_nurgle"] = { family = "nurgle", clouds = { hsv(CLOUD.core_256be307), rgb(CLOUD.smoke_31e6394a, "material_variable_a4b8203b") } },
	[EFFECT_PREFIX .. "renegade_wizard_projectile_nurgle_impact"] = { family = "nurgle", clouds = list(hsv(CLOUD.core_256be307), table_clouds(SPLATTER), rgb(CLOUD.impact_08963273, SPLATTER), rgb(CLOUD.impact_0ba78e70, SPLATTER), rgb(CLOUD.impact_81e0d74a, SPLATTER), rgb(CLOUD.impact_flies_c1d37aad, GAS)) },
	[EFFECT_PREFIX .. "renegade_wizard_projectile_nurgle_dissipate"] = { family = "nurgle", clouds = { hsv(CLOUD.core_256be307) } },
	[EFFECT_PREFIX .. "renegade_wizard_wall_nurgle"] = { family = "nurgle", clouds = { rgb(CLOUD.warp_chunk_d1653945, WARP_CLOUD) } },
	[EFFECT_PREFIX .. "renegade_wizard_projectile_warp"] = { family = "warp", clouds = { rgb(CLOUD.warp_chunk_d1653945, WARP_CLOUD), rgb(CLOUD.warp_b1a346c7, WARP_CLOUD) } },
	[EFFECT_PREFIX .. "renegade_wizard_projectile_warp_dissipate"] = { family = "warp", clouds = { hsv(CLOUD.core_256be307), rgb(CLOUD.warp_clouds_f6f5e7c5, WARP_CLOUD) } },
	[EFFECT_PREFIX .. "renegade_wizard_projectile_warp_impact"] = { family = "warp", clouds = { rgb(CLOUD.warp_clouds_f6f5e7c5, WARP_CLOUD) } },
	[EFFECT_PREFIX .. "renegade_wizard_barrier_warp"] = { family = "warp", clouds = { rgb(CLOUD.warp_trail_acc82bbd, WARP_CLOUD) } },
	[EFFECT_PREFIX .. "renegade_wizard_staff_anticipation_warp_shockwave_01"] = { family = "warp", clouds = { hsv(CLOUD.pulse_47f9f7e2) } },
	[EFFECT_PREFIX .. "renegade_wizard_warp_forcepush_main"] = { family = "warp", clouds = { hsv(CLOUD.core_256be307), rgb(CLOUD.warp_chunk_d1653945, WARP_CLOUD) } },
}

-- Tint

local World_has_particles_material = World.has_particles_material
local World_are_particles_playing = World.are_particles_playing
local World_set_particles_material_vector3 = World.set_particles_material_vector3
local World_set_particles_material_scalar = World.set_particles_material_scalar

local _stats = {}
local _pending = {}
local _gameplay_running = false

local function effect_stat(name)
	local stat = _stats[name]

	if not stat then
		stat = { seen = 0, applied = 0, late = 0, partial = 0, expired = 0 }
		_stats[name] = stat
	end

	return stat
end

local function now()
	local time_manager = Managers.time

	return time_manager and time_manager:time("main") or 0
end

local function apply_effect(world, particle_id, entry, t, done)
	local profile = _profiles[entry.family]
	local clouds = entry.clouds
	local remaining = 0
	local r, g, b, code

	for i = 1, #clouds do
		local cloud = clouds[i]

		if not done[i] and not World_has_particles_material(world, particle_id, cloud.cand) then
			remaining = remaining + 1
		elseif not done[i] then
			done[i] = true

			if cloud.kind == "hsv" then
				code = code or encoded_value(profile, t)

				World_set_particles_material_scalar(world, particle_id, cloud.cand, VARIABLE, code)
			else
				if not r then
					r, g, b = profile_rgb(profile, t)
				end

				World_set_particles_material_vector3(world, particle_id, cloud.cand, cloud.variable, Vector3(r, g, b))
			end
		end
	end

	return remaining
end

local function apply_or_defer(world, particle_id, name, entry)
	if not _gameplay_running or _profiles[entry.family].mode == "stock" then
		return
	end

	local stat = effect_stat(name)
	local done = {}

	stat.seen = stat.seen + 1

	if apply_effect(world, particle_id, entry, now(), done) == 0 then
		stat.applied = stat.applied + 1

		return
	end

	_pending[#_pending + 1] = { stat = stat, world = world, particle_id = particle_id, entry = entry, done = done, frames = 0 }
end

local function finish_pending(i, item)
	if next(item.done) then
		item.stat.partial = item.stat.partial + 1
	else
		item.stat.expired = item.stat.expired + 1
	end

	table.remove(_pending, i)
end

local function retry_pending()
	if not _gameplay_running then
		return
	end

	local t = now()

	for i = #_pending, 1, -1 do
		local item = _pending[i]

		item.frames = item.frames + 1

		if _profiles[item.entry.family].mode == "stock" or not World_are_particles_playing(item.world, item.particle_id) then
			finish_pending(i, item)
		elseif apply_effect(item.world, item.particle_id, item.entry, t, item.done) == 0 then
			item.stat.late = item.stat.late + 1
			table.remove(_pending, i)
		elseif item.frames >= PENDING_FRAMES then
			finish_pending(i, item)
		end
	end
end

local function clear_pending()
	for i = #_pending, 1, -1 do
		_pending[i] = nil
	end
end

mod:hook(World, "create_particles", function(func, world, effect_name, ...)
	local particle_id = func(world, effect_name, ...)

	if not particle_id then
		return particle_id
	end

	local entry = EFFECTS[effect_name]

	if entry then
		apply_or_defer(world, particle_id, effect_name, entry)
	end

	return particle_id
end)

-- Rings

local Unit_alive = Unit.alive
local Unit_set_vector3_for_materials = Unit.set_vector3_for_materials
local World_get_particles_mesh = World.get_particles_mesh
local Mesh_material = Mesh.material
local Material_set_vector3 = Material.set_vector3

local _rings = { units = {}, material = nil, template_data = nil, world = nil }

local function clear_rings()
	for i = #_rings.units, 1, -1 do
		_rings.units[i] = nil
	end

	_rings.material = nil
	_rings.template_data = nil
	_rings.world = nil
end

local STOCK_RING_TINT = { 0.609, 0.946, 0.018 }

local function tint_rings(t)
	local profile = _profiles.nurgle
	local r, g, b

	if profile.mode == "stock" then
		r, g, b = STOCK_RING_TINT[1], STOCK_RING_TINT[2], STOCK_RING_TINT[3]
	else
		r, g, b = profile_rgb(profile, t)
	end

	local units = _rings.units

	for i = 1, #units do
		local unit = units[i]

		if Unit_alive(unit) then
			Unit_set_vector3_for_materials(unit, RING_VARIABLE, Vector3(r, g, b), true)
		end
	end

	if _rings.material then
		Material_set_vector3(_rings.material, RING_VARIABLE, Vector3(r, g, b))
	end
end

local function track_rings(template_data, world)
	clear_rings()

	local ring_units = template_data.ring_units or {}

	for i = 1, #ring_units do
		_rings.units[#_rings.units + 1] = ring_units[i]
	end

	_rings.template_data = template_data
	_rings.world = world

	local effect_id = template_data.static_ring_effect_id
	local mesh = effect_id and World_get_particles_mesh(world, effect_id, RING_CLOUD)

	_rings.material = mesh and Mesh_material(mesh, RING_SLOT) or nil

	if _profiles.nurgle.mode ~= "stock" then
		tint_rings(now())
	end
end

local function refresh_ring_material()
	local template_data = _rings.template_data

	if _rings.material or not template_data or _profiles.nurgle.mode == "stock" then
		return
	end

	local material = template_data.static_ring_material

	if not material then
		local effect_id = template_data.static_ring_effect_id
		local mesh = effect_id and World_get_particles_mesh(_rings.world, effect_id, RING_CLOUD)

		material = mesh and Mesh_material(mesh, RING_SLOT) or nil
	end

	if material then
		_rings.material = material

		local r, g, b = profile_rgb(_profiles.nurgle, now())

		Material_set_vector3(material, RING_VARIABLE, Vector3(r, g, b))
	end
end

local function follow_rings(t)
	if _profiles.nurgle.mode ~= "rainbow" then
		return
	end

	if _rings.units[1] or _rings.material then
		tint_rings(t)
	end
end

local function retint_rings()
	if _rings.units[1] or _rings.material then
		tint_rings(now())
	end
end

local function install_ring_hooks()
	local templates = require("scripts/settings/fx/effect_templates")
	local template = templates[RING_TEMPLATE]

	if not template then
		mod:info("effect template %s not found; ring decals stay stock", RING_TEMPLATE)

		return
	end

	mod:hook_safe(template, "start", function(template_data, template_context)
		if _gameplay_running and template_data.ring_units then
			track_rings(template_data, template_context.world)
		end
	end)

	mod:hook_safe(template, "stop", function()
		clear_rings()
	end)
end

-- Redirect

local asset_redirect = mod:io_dofile("Painted Prophet/scripts/mods/Painted Prophet/asset_redirect")
local _redirect_handles = {}
local _material_format_ok = false

do
	local lua = rawget(_G, "Mods") and Mods.lua
	local lua_io = lua and lua.io
	local file = lua_io and lua_io.open(MATERIAL_FORMAT.probe, "rb")
	local head = file and file:read(4)

	if file then
		file:close()
	end

	if head and #head == 4 then
		local b1, b2, b3, b4 = string.byte(head, 1, 4)

		MATERIAL_FORMAT.found = b1 + b2 * 256 + b3 * 65536 + b4 * 16777216
	end

	_material_format_ok = MATERIAL_FORMAT.found == MATERIAL_FORMAT.expected

	if not _material_format_ok and asset_redirect then
		asset_redirect.clear(mod)
		asset_redirect = nil
	end
end

if asset_redirect then
	for i = 1, #REDIRECTS do
		local entry = REDIRECTS[i]

		_redirect_handles[i] = asset_redirect.register(mod, {
			stock = entry.stock,
			file = entry.file,
			sha256 = entry.sha256,
			priority = 0,
			contract = REDIRECT_CONTRACT,
		})
	end
end

local function redirect_opens(stock)
	local instance = rawget(_G, "__asset_redirect_instance")
	local native = instance and instance.native

	if not native or not native.AssetRedirect_Opens then
		return -1
	end

	local ok, opens = pcall(native.AssetRedirect_Opens, stock)

	return ok and opens or -1
end

local function redirect_pinned(handle)
	local pinned = asset_redirect.pinned

	return pinned ~= nil and pinned(handle) == true
end

local function redirect_served(state)
	return state == "active" or state == "shared" or state == "compatible"
end

local function redirect_is_stale(resident, was_armed, same_payload)
	return resident and not (was_armed and same_payload)
end

local function redirect_label(state, is_winner, opens, stale, unclaimed, pinned)
	if state == "restart_required" then
		if unclaimed or (pinned and is_winner) then
			return "restart"
		elseif not is_winner then
			return "displaced"
		end
	elseif not redirect_served(state) then
		return state
	end

	if stale then
		return "stale"
	end

	return opens > 0 and "active" or "armed"
end

local _redirect_stale = {}
local _redirect_settled = {}
local _redirects_waiting = false
local _restart_prompted = false

local function evaluate_redirect(store, i)
	local entry = REDIRECTS[i]
	local hash = _redirect_handles[i].payload_hash
	local resident = Application.can_get_resource("material", entry.material)
	local stale = redirect_is_stale(resident, store.armed[entry.stock] == true, hash ~= nil and store.hash[entry.stock] == hash)

	_redirect_stale[i] = stale
	_redirect_settled[i] = true

	if not stale and hash ~= nil then
		store.armed[entry.stock] = true
		store.hash[entry.stock] = hash
	end
end

local function evaluate_redirects()
	_redirects_waiting = false

	if not asset_redirect then
		return false
	end

	local store = mod:persistent_table("redirect")
	local settled_now = false

	store.armed = store.armed or {}
	store.hash = store.hash or {}

	for i = 1, #_redirect_handles do
		if not _redirect_settled[i] then
			if asset_redirect.state(_redirect_handles[i]) == "pending" then
				_redirects_waiting = true
			else
				evaluate_redirect(store, i)
				settled_now = true
			end
		end
	end

	return settled_now
end

local function redirect_state(i)
	local handle = _redirect_handles[i]
	local opens = redirect_opens(REDIRECTS[i].stock)
	local winner = asset_redirect.winner(handle)

	return redirect_label(asset_redirect.state(handle), winner == mod:get_name(), opens, _redirect_stale[i] == true, winner == nil, redirect_pinned(handle)), opens
end

local function redirect_summary()
	local served, total, stale, stock_now = 0, #_redirect_handles, false, false

	if asset_redirect then
		for i = 1, total do
			local state = redirect_state(i)

			if state == "active" or state == "armed" then
				served = served + 1
			end

			stale = stale or state == "stale"
			stock_now = stock_now or state == "restart"
		end
	end

	return served, total, stale or stock_now, stock_now
end

local function prompt_restart_once()
	if _restart_prompted then
		return
	end

	local _, _, restart, stock_now = redirect_summary()

	if restart then
		_restart_prompted = true
		mod:echo(mod:localize(stock_now and "restart_to_apply" or "restart_required"))
	end
end

local function settle_redirects()
	if asset_redirect.ready and not asset_redirect.ready() then
		return
	end

	if evaluate_redirects() then
		prompt_restart_once()
	end
end

local function commit_if_first()
	if asset_redirect and _redirect_handles[1] and asset_redirect.state(_redirect_handles[1]) == "pending" then
		asset_redirect.commit()
	end
end

-- Lifecycle

local EFFECT_NOTES = {
	[EFFECT_PREFIX .. "renegade_wizard_warp_forcepush_main"] = " (spawned in a particle group during the fight: writes have no visible effect)",
}

local function open_gate_if_in_level()
	local ui = Managers.ui

	_gameplay_running = ui ~= nil and ui.get_current_sub_state_name ~= nil and ui:get_current_sub_state_name() == "GameplayStateRun"
end

local function report(echo)
	local served, total, restart, stock_now = redirect_summary()
	local note = stock_now and " (one stays stock this session: restart the game to apply)" or restart and " (one was already loaded: reloads with the next mission or a restart)" or ""
	local lines = {
		string_format("Painted Prophet %s: format ok=%s, patched files ready %d of %d%s, gate=%s", tostring(mod.version), tostring(_material_format_ok), served, total, note, tostring(_gameplay_running)),
	}

	for i = 1, #FAMILIES do
		local family = FAMILIES[i]
		local profile = _profiles[family]

		lines[#lines + 1] = string_format("%s: mode=%s hue=%.3f sat=%.2f brightness=%d", family, profile.mode, profile.hue, profile.saturation, profile.brightness)
	end

	if asset_redirect then
		for i = 1, #_redirect_handles do
			local state, opens = redirect_state(i)

			lines[#lines + 1] = string_format("redirect %s: %s opens=%d", REDIRECTS[i].stock, state, opens)
		end
	end

	local totals = { seen = 0, applied = 0, late = 0, partial = 0, expired = 0 }
	local details = {}

	for name, stat in pairs(_stats) do
		for key, value in pairs(stat) do
			totals[key] = totals[key] + value
		end

		details[#details + 1] = string_format("%s: seen=%d written=%d late=%d partial=%d expired=%d%s", name:sub(#EFFECT_PREFIX + 1), stat.seen, stat.applied, stat.late, stat.partial, stat.expired, EFFECT_NOTES[name] or "")
	end

	lines[#lines + 1] = string_format("effects seen=%d written=%d late=%d partial=%d expired=%d; pending=%d rings=%d centre=%s (per-effect lines in the log)", totals.seen, totals.applied, totals.late, totals.partial, totals.expired, #_pending, #_rings.units, tostring(_rings.material ~= nil))

	for i = 1, #lines do
		mod:info("check: %s", lines[i])

		if echo then
			mod:echo(lines[i])
		end
	end

	table.sort(details)

	for i = 1, #details do
		mod:info("check: %s", details[i])
	end
end

mod.update = function()
	if _redirects_waiting then
		settle_redirects()
	end

	if _pending[1] then
		retry_pending()
	end

	if _gameplay_running then
		refresh_ring_material()
		follow_rings(now())
	end
end

mod.on_game_state_changed = function(status, state_name)
	if status == "enter" then
		_gameplay_running = state_name == "GameplayStateRun"
	elseif state_name == "StateGameplay" or state_name == "GameplayStateRun" then
		_gameplay_running = false
	end

	if not _gameplay_running then
		clear_pending()
		clear_rings()
	end
end

local function apply_settings_change()
	cache_settings()
	clear_pending()

	if _gameplay_running then
		retint_rings()
	end
end

mod.on_setting_changed = apply_settings_change
mod.on_settings_reset = apply_settings_change

mod.on_unload = function()
	clear_pending()
	clear_rings()
end

cache_settings()

mod.on_all_mods_loaded = function()
	mod:info("Painted Prophet %s loaded", tostring(mod.version))
	commit_if_first()
	evaluate_redirects()
	open_gate_if_in_level()

	if MATERIAL_FORMAT.found == nil then
		mod:info("material format probe %s unreadable: the patched layers stay stock", MATERIAL_FORMAT.probe)
		mod:echo(mod:localize("game_format_unknown"))
	elseif not _material_format_ok then
		mod:info("game material format %s, payload built for %s: the patched layers stay stock", tostring(MATERIAL_FORMAT.found), tostring(MATERIAL_FORMAT.expected))
		mod:echo(mod:localize("game_format_changed"))
	end

	if not _redirects_waiting then
		prompt_restart_once()
	end

	if _debug_logging then
		report(false)
	end

	install_ring_hooks()
end

mod:command("pp_check", mod:localize("pp_check_description"), function()
	report(true)
end)
