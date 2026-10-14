local FAMILIES = {
	{ id = "nurgle", label = "Nurgle (green) effects", description = "The green ground effects of Rodin Karnak's fight: the dance rings and their splatter, the walls, the teeth indicator, the green projectile and its burst." },
	{ id = "warp", label = "Warp (red) effects", description = "The red effects of the fight: the shockwave indicator, the barrier ring, the red projectile, its burst and impact clouds." },
}

local localization = {
	mod_name = { en = "Painted Prophet" },
	mod_description = { en = "Recolours the Spillway boss fight: pick a colour or a rainbow for Rodin Karnak's green Nurgle ground effects and red warp effects." },
	restart_required = { en = "Painted Prophet: a patched effect file was installed or changed while the game already had that effect loaded. The shader-patched layers update when the game next loads a mission; restart the game if they do not." },
	restart_to_apply = { en = "Painted Prophet: a patched effect file could not be applied in time this session, so its shader-patched layers stay stock. Restart the game to apply." },
	game_format_changed = { en = "Painted Prophet: this game update changed the effect file format. The shader-patched layers stay stock until Painted Prophet is updated." },
	game_format_unknown = { en = "Painted Prophet: could not read the game's effect file format. The shader-patched layers stay stock this session." },
	debug_logging = { en = "Debug logging" },
	debug_logging_description = { en = "Writes Painted Prophet's setup and per-effect counters to the console log, and a /pp_check report once per session." },
	pp_check_description = { en = "Painted Prophet: report the setup state to chat and the console log." },
	mode_stock = { en = "Base" },
	mode_custom = { en = "Set colour" },
	mode_rainbow = { en = "Rainbow" },
}

for i = 1, #FAMILIES do
	local family = FAMILIES[i]
	local prefix = family.id .. "_"

	localization[prefix .. "group"] = { en = family.label }
	localization[prefix .. "mode"] = { en = "Colour" }
	localization[prefix .. "mode_description"] = { en = family.description .. "\n\nBase leaves the game's colour. Gas and spore layers can only shift between red and green; everything else takes any colour. Layers marked as patched in the README need a game restart after install." }
	localization[prefix .. "colour"] = { en = "Set colour" }
	localization[prefix .. "brightness"] = { en = "Brightness (8 = normal)" }
	localization[prefix .. "brightness_description"] = { en = "Overall brightness. 8 matches the stock effect, 1 is the faintest, 15 the strongest." }
end

return localization
