-- Linting

vim.pack.add { 'https://github.com/mfussenegger/nvim-lint' }

local lint = require 'lint'
lint.linters_by_ft = {
  markdown = { 'markdownlint' }, -- Make sure to install `markdownlint` via mason / npm
  go = { 'golangcilint' }, -- Make sure to install `golangci-lint` via mason
}

-- golangci-lint v2+ needs the target to exist on disk and (for directory mode)
-- a go.mod file in the target directory. Use the package directory when one
-- exists, otherwise fall back to the current file path so standalone Go files
-- and new buffers don't crash the linter with exit code 5.
lint.linters.golangcilint.args = {
  'run',
  '--output.json.path=stdout',
  '--output.text.path=',
  '--output.tab.path=',
  '--output.html.path=',
  '--output.checkstyle.path=',
  '--output.code-climate.path=',
  '--output.junit-xml.path=',
  '--output.teamcity.path=',
  '--output.sarif.path=',
  '--issues-exit-code=0',
  '--show-stats=false',
  '--path-mode=abs',
  function()
    local buf = vim.api.nvim_buf_get_name(0)
    local dir = vim.fn.fnamemodify(buf, ':h')
    if vim.fn.filereadable(dir .. '/go.mod') == 1 then
      return dir
    end
    return vim.fn.fnamemodify(buf, ':p')
  end,
}

-- Create autocommand which carries out the actual linting
-- on the specified events.
local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
  group = lint_augroup,
  callback = function()
    -- Only run the linter in buffers that you can modify in order to
    -- avoid superfluous noise, notably within the handy LSP pop-ups that
    -- describe the hovered symbol using Markdown.
    if not vim.bo.modifiable then return end

    -- Skip linters for buffers that haven't been saved to disk yet.
    -- Tools like golangci-lint exit with an error when asked to lint a
    -- file path that does not exist.
    local buf = vim.api.nvim_buf_get_name(0)
    if buf == '' or vim.fn.filereadable(buf) ~= 1 then return end

    lint.try_lint()
  end,
})
