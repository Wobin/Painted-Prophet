local mod = get_mod("Painted Prophet")

local FAMILIES = { "nurgle", "warp" }

local MODE_OPTIONS = {
	{ text = "mode_stock", value = "stock", show_widgets = {} },
	{ text = "mode_custom", value = "custom", show_widgets = { 1, 2 } },
	{ text = "mode_rainbow", value = "rainbow", show_widgets = { 2 } },
}

local DEFAULT_COLOURS = {
	nurgle = { 255, 255, 0, 255 },
	warp = { 255, 0, 255, 255 },
}

local function family_group(family)
	local options = {}

	for i = 1, #MODE_OPTIONS do
		options[i] = table.clone(MODE_OPTIONS[i])
	end

	return {
		setting_id = family .. "_group",
		type = "group",
		sub_widgets = {
			{
				setting_id = family .. "_mode",
				type = "dropdown",
				default_value = "stock",
				options = options,
				sub_widgets = {
					{ setting_id = family .. "_colour", type = "color", default_value = table.clone(DEFAULT_COLOURS[family]), has_alpha = false },
					{ setting_id = family .. "_brightness", type = "numeric", default_value = 8, range = { 1, 15 }, decimals_number = 0 },
				},
			},
		},
	}
end

local widgets = {}

for i = 1, #FAMILIES do
	widgets[i] = family_group(FAMILIES[i])
end

widgets[#widgets + 1] = { setting_id = "debug_logging", type = "checkbox", default_value = false }

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = false,
	allow_rehooking = true,
	options = {
		widgets = widgets,
	},
}
