return {
	"voldikss/vim-floaterm",
	config = function()
		vim.keymap.set("n", "<F1>", ":FloatermToggle! lazygit<CR>")
	end,
}
