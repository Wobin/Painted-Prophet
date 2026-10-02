return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`Painted Prophet` encountered an error loading the Darktide Mod Framework.")

		new_mod("Painted Prophet", {
			mod_script       = "Painted Prophet/scripts/mods/Painted Prophet/Painted Prophet",
			mod_data         = "Painted Prophet/scripts/mods/Painted Prophet/Painted Prophet_data",
			mod_localization = "Painted Prophet/scripts/mods/Painted Prophet/Painted Prophet_localization",
		})
	end,
	packages = {},
	load_before = { "Polychromatic" },
}
