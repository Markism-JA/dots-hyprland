vim.keymap.set("n", "<leader>ff", function()
	require("snacks").picker.files({
		hidden = true,
		ignored = true,
	})
end, { desc = "Find files (Hidden + Ignored)" })
