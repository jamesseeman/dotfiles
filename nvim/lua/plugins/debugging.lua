return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"rcarriga/nvim-dap-ui",
		"nvim-neotest/nvim-nio",
		"mfussenegger/nvim-dap-python",
		"jay-babu/mason-nvim-dap.nvim",
		"nvim-lua/plenary.nvim",
	},
	config = function(_, opts)
		local dap = require("dap")
		local dapui = require("dapui")
		dapui.setup(opts)

		local dappython = require("dap-python").setup("/usr/bin/python3")

		vim.keymap.set("n", "<F5>", function()
			dap.continue()
		end)
		vim.keymap.set("n", "<F10>", function()
			dap.step_over()
		end)
		vim.keymap.set("n", "<F11>", function()
			dap.step_into()
		end)
		vim.keymap.set("n", "<F12>", function()
			dap.step_out()
		end)
		vim.keymap.set("n", "<F9>", function()
			dap.toggle_breakpoint()
		end)
		vim.keymap.set("n", "<Leader>b", function()
			dap.toggle_breakpoint()
		end, { desc = "set [b]reakpoint" })
		vim.keymap.set("n", "<Leader>B", function()
			dap.set_breakpoint()
		end)
		vim.keymap.set("n", "<Leader>lp", function()
			dap.set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
		end)
		vim.keymap.set("n", "<Leader>dr", function()
			dap.repl.open()
		end)
		vim.keymap.set("n", "<Leader>dl", function()
			dap.run_last()
		end)
		vim.keymap.set({ "n", "v" }, "<Leader>dh", function()
			require("dap.ui.widgets").hover()
		end)
		vim.keymap.set({ "n", "v" }, "<Leader>dp", function()
			require("dap.ui.widgets").preview()
		end)
		vim.keymap.set("n", "<Leader>df", function()
			local widgets = require("dap.ui.widgets")
			widgets.centered_float(widgets.frames)
		end)
		vim.keymap.set("n", "<Leader>ds", function()
			local widgets = require("dap.ui.widgets")
			widgets.centered_float(widgets.scopes)
		end)

		dap.listeners.before.attach.dapui_config = function()
			vim.cmd(":Neotree filesystem close")
			dapui.open()
		end
		dap.listeners.before.launch.dapui_config = function()
			vim.cmd(":Neotree filesystem close")
			dapui.open()
		end
		dap.listeners.before.event_terminated.dapui_config = function()
			vim.cmd(":Neotree filesystem reveal left")
			dapui.close()
		end
		dap.listeners.before.event_exited.dapui_config = function()
			vim.cmd(":Neotree filesystem reveal left")
			dapui.close()
		end

		dap.adapters.lldb = {
			type = "executable",
			command = "/usr/bin/lldb-vscode-14", -- adjust as needed, must be absolute path
			name = "lldb",
		}

		dap.configurations.cpp = {
			{
				name = "Launch",
				type = "lldb",
				request = "launch",
				program = function()
					return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
				end,
				cwd = "${workspaceFolder}",
				stopOnEntry = false,
				args = {},
			},
		}

		dap.configurations.rust = {
			{
				name = "Launch",
				type = "lldb",
				request = "launch",
				program = function()
					return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug/", "file")
				end,
				cwd = "${workspaceFolder}",
				stopOnEntry = false,
				args = {},

				initCommands = function()
					-- Find out where to look for the pretty printer Python module
					local rustc_sysroot = vim.fn.trim(vim.fn.system("rustc --print sysroot"))

					local script_import = 'command script import "'
						.. rustc_sysroot
						.. '/lib/rustlib/etc/lldb_lookup.py"'
					local commands_file = rustc_sysroot .. "/lib/rustlib/etc/lldb_commands"

					local commands = {}
					local file = io.open(commands_file, "r")
					if file then
						for line in file:lines() do
							table.insert(commands, line)
						end
						file:close()
					end
					table.insert(commands, 1, script_import)

					return commands
				end,
				-- ...,
			},
		}

		-- setup dap config by VsCode launch.json file
		--    local vscode = require("dap.ext.vscode")
		--    local _filetypes = require("mason-nvim-dap.mappings.filetypes")
		--    local filetypes = vim.tbl_deep_extend("force", _filetypes, {
		--      ["node"] = { "javascriptreact", "typescriptreact", "typescript", "javascript" },
		--      ["pwa-node"] = { "javascriptreact", "typescriptreact", "typescript", "javascript" },
		--    })
		--    local json = require("plenary.json")
		--    vscode.json_decode = function(str)
		--      return vim.json.decode(json.json_strip_comments(str))
		--    end
		--    vscode.load_launchjs(nil, filetypes)

		-- dap.configurations.rust = dap.configurations.cpp

		--    dap.adapters.python = function(cb, config)
		--      if config.request == "attach" then
		--        ---@diagnostic disable-next-line: undefined-field
		--        local port = (config.connect or config).port
		--        ---@diagnostic disable-next-line: undefined-field
		--        local host = (config.connect or config).host or "127.0.0.1"
		--        cb({
		--          type = "server",
		--          port = assert(port, "`connect.port` is required for a python `attach` configuration"),
		--          host = host,
		--          options = {
		--            source_filetype = "python",
		--          },
		--        })
		--      else
		--        cb({
		--          type = "executable",
		--          command = "/usr/bin/python3",
		--          args = { "-m", "debugpy.adapter" },
		--          options = {
		--            source_filetype = "python",
		--          },
		--        })
		--      end
		--    end
		--
		--    dap.configurations.python = {
		--      {
		--        -- The first three options are required by nvim-dap
		--        type = "python", -- the type here established the link to the adapter definition: `dap.adapters.python`
		--        request = "launch",
		--        name = "Launch file",
		--
		--        -- Options below are for debugpy, see https://github.com/microsoft/debugpy/wiki/Debug-configuration-settings for supported options
		--
		--        program = "${file}", -- This configuration will launch the current file if used.
		--        pythonPath = function()
		--          -- debugpy supports launching an application with a different interpreter then the one used to launch debugpy itself.
		--          -- The code below looks for a `venv` or `.venv` folder in the current directly and uses the python within.
		--          -- You could adapt this - to for example use the `VIRTUAL_ENV` environment variable.
		--          local cwd = vim.fn.getcwd()
		--          if vim.fn.executable(cwd .. "/venv/bin/python") == 1 then
		--            return cwd .. "/venv/bin/python"
		--          elseif vim.fn.executable(cwd .. "/.venv/bin/python") == 1 then
		--            return cwd .. "/.venv/bin/python"
		--          else
		--            return "/usr/bin/python3"
		--          end
		--        end,
		--      },
		--    }
	end,
}
