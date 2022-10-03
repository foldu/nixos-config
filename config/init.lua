-- TODO: somehow unify generic settings from config with this
-- FIXME: don't just copypaste this from full neovim config
local opt = vim.opt
local cmd = vim.cmd
local g = vim.g

g.mapleader = " "
g.localleader = ","
--
-- enable full colors
opt.termguicolors = true

-- enable hybrid relative line numbers
opt.relativenumber = true
opt.number = true
-- disable on terminal buffers
cmd([[
   au BufEnter term://* setlocal nonumber
]])

-- can't decide if split or nosplit is better
opt.inccommand = "split"

opt.smarttab = true
opt.tabstop = 8
opt.shiftround = true
opt.shiftwidth = 4
opt.expandtab = true
-- allow multiple buffers
opt.hidden = true
opt.wildmode = "list:longest,full"
-- don't create swap files
opt.swapfile = false
-- faster completion
opt.updatetime = 300

-- don't beep @ me bro
opt.errorbells = false
opt.visualbell = false

opt.smartcase = true
opt.ignorecase = true
opt.hlsearch = true
opt.incsearch = true

-- always keep three lines visible when scrolling
opt.scrolloff = 8

-- let nvim change terminal window title
opt.title = true

-- persistent undo
opt.undofile = true

-- prevent jittering when diagnostic pops up
opt.signcolumn = "yes"

opt.guifont = "Consolas:h17"
g.neovide_refresh_rate = 60

-- mouse should kind of work
opt.mouse = "nvi"

-- causes terminal spam
opt.showmode = false

local disabled_builtins = {
	"netrw",
	"netrwPlugin",
	"netrwSettings",
	"netrwFileHandlers",
	"gzip",
	"zip",
	"zipPlugin",
	"tar",
	"tarPlugin",
	-- "man",
	"getscript",
	"getscriptPlugin",
	"vimball",
	"vimballPlugin",
	"2html_plugin",
	"logipat",
	"rrhelper",
	"spellfile_plugin",
	-- 'matchit', 'matchparen', 'shada_plugin',
}

for _, builtin in ipairs(disabled_builtins) do
	vim.g["loaded_" .. builtin] = 1
end

opt.shell = "/bin/sh"
-- make message as short as possible so I have to mash enter
-- less often
-- opt.shortmess = "atc"

-- tries to copy the proper indentation
opt.copyindent = true

-- try to preserve indentation
opt.preserveindent = true

-- highlights current line
opt.cursorline = true

opt.cmdheight = 1

vim.o.completeopt = "menu,menuone,noselect"

local function autoqdelete(ft)
	local au = string.format("autocmd FileType %s nnoremap <buffer> q :bdelete<CR>", ft)
	cmd(au)
end
autoqdelete("help")
autoqdelete("qf")
autoqdelete("lspinfo")

-- resize windows automatically when resized
cmd([[autocmd VimResized * wincmd =]])

-- automatically go into insert mode when committing
cmd([[autocmd FileType gitcommit startinsert]])

local function noformat(event)
	cmd(string.format([[autocmd %s * setlocal formatoptions-=c formatoptions-=r formatoptions-=o]], event))
end
noformat("BufWinEnter")
noformat("BufRead")
noformat("BufNewFile")

-- highlighted yank
cmd([[ au TextYankPost * lua vim.highlight.on_yank {on_visual = false} ]])

-- When editing a file, always jump to the last known cursor position.
-- Don't do it when the position is invalid or when inside an event handler
-- (happens when dropping a file on gvim).
cmd([[
    au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") |  exe "normal g`\"" | endif
 ]])

vim.keymap.set("n", "+", '"+')
vim.keymap.set("x", "+", '"+')

if os.getenv("SSH_TTY") ~= nil then
	vim.api.nvim_create_autocmd("TextYankPost", {
		callback = function()
			if vim.v.event.operator == "y" and vim.v.event.regname == "+" then
				vim.cmd([[:OSCYank<CR>]])
			end
		end,
	})
end

cmd([[colorscheme gruvbox]])
