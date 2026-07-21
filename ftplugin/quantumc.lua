local ns_id = vim.api.nvim_create_namespace("quantumc_syntax")
local diag_ns_id = vim.api.nvim_create_namespace("quantumc_diagnostics")
local token_map = {
  ["int"]         = "Type",
  ["string"]      = "Type",
  ["addr_t"]      = "Type",
  ["long int"]    = "Type",
  ["short int"]   = "Type",
  ["long double"] = "Type",
  ["float"]       = "Type",
  ["double"]      = "Type",
  ["char"]        = "Type",
  ["bool"]        = "Type",
  ["qbool"]       = "Type",
  ["if"]          = "Conditional",
  ["else"]        = "Conditional",
  ["switch"]      = "Conditional",
  ["case"]        = "Label",
  ["default"]     = "Label",
  ["break"]       = "Keyword",
  ["sizeof"]      = "Keyword",
  ["identifier"]  = "Identifier",
  ["keyword"]     = "Keyword",
  ["fstring"]     = "String",
  ["+"]           = "Operator",
  ["-"]           = "Operator",
  ["*"]           = "Operator",
  ["/"]           = "Operator",
  ["%"]           = "Operator",
  ["#^"]          = "Operator",
  ["="]           = "Operator",
  ["+="]          = "Operator",
  ["-="]          = "Operator",
  ["*="]          = "Operator",
  ["/="]          = "Operator",
  ["%="]          = "Operator",
  ["++"]          = "Operator",
  ["--"]          = "Operator",
  ["=="]          = "Operator",
  ["!="]          = "Operator",
  [">"]           = "Operator",
  ["<"]           = "Operator",
  [">="]          = "Operator",
  ["<="]          = "Operator",
  ["&&&"]         = "Operator",
  ["||"]          = "Operator",
  ["^"]           = "Operator",
  ["!"]           = "Operator",
  ["|||"]         = "Operator",
  ["^^"]          = "Operator",
  ["!!"]          = "Operator",
  ["==="]         = "Operator",
  ["!=="]         = "Operator",
  ["&|&"]         = "Operator",
  ["|&|"]         = "Operator",
  ["&"]           = "Operator",
  ["::"]          = "Operator",
  ["<<"]          = "Operator",
  ["|>"]          = "Operator",
  ["|>>"]         = "Operator",
  ["<<<"]         = "Operator",
  ["$"]           = "Operator",
  ["~"]           = "Operator",
  [":>"]          = "Operator",
  ["|"]           = "Operator",
  ["("]           = "Delimiter",
  [")"]           = "Delimiter",
  ["{"]           = "Delimiter",
  ["}"]           = "Delimiter",
  ["["]           = "Delimiter",
  ["]"]           = "Delimiter",
  [","]           = "Delimiter",
  ["."]           = "Delimiter",
  [":"]           = "Delimiter",
  [";"]           = "Delimiter",
  ["->"]          = "Delimiter",
  ["@"]           = "Delimiter",
  ["..."]         = "Delimiter",
}
local function run_lexer_highlight()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local line_map = {}
  do
    local lexer_line = 0
    for buf_line, text in ipairs(lines) do
      if not text:match("^%s*#") then
        line_map[lexer_line] = buf_line - 1
        lexer_line = lexer_line + 1
      end
    end
  end
  local tmp_file = vim.fn.tempname()
  local f = io.open(tmp_file, "w")
  if not f then return end
  f:write(table.concat(lines, "\n"))
  f:close()
  local cmd = { "qc", "-dump-tokens", tmp_file }
  local stdout_data = {}
  vim.fn.jobstart(cmd, {
    cwd = vim.fn.getcwd(),
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          table.insert(stdout_data, line)
        end
      end
    end,
    on_exit = function()
      os.remove(tmp_file)
      vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
      vim.diagnostic.reset(diag_ns_id, bufnr)
      local diagnostics = {}
      for _, line in ipairs(stdout_data) do
        line = line:gsub("\r", "")
        if not line:match("^#")
            and not line:match("<eof>")
            and line ~= ""
            and not line:match("^%-") then
          if line:match("^ERROR:") then
            local l_num, col, len, msg =
                line:match("^ERROR:%s*(%d+)%s+(%d+)%s+(%d+)%s+(.*)$")

            if l_num then
              local line_num = line_map[tonumber(l_num)]
              if line_num then
                table.insert(diagnostics, {
                  bufnr = bufnr,
                  lnum = line_num,
                  col = tonumber(col),
                  end_lnum = line_num,
                  end_col = tonumber(col) + tonumber(len),
                  severity = vim.diagnostic.severity.ERROR,
                  message = msg,
                  source = "qc-compiler",
                })
              end
            end
          else
            local l_num, col, len, token_type =
                line:match("^(%d+) (%d+) (%d+) (.*)$")

            if l_num then
              local line_num = line_map[tonumber(l_num)]
              if line_num and token_map[token_type] then
                vim.api.nvim_buf_add_highlight(
                  bufnr,
                  ns_id,
                  token_map[token_type],
                  line_num,
                  tonumber(col),
                  tonumber(col) + tonumber(len)
                )
              end
            end
          end
        end
      end
      vim.diagnostic.set(diag_ns_id, bufnr, diagnostics)
    end,
  })
end
local function debounced_highlight()
  if hl_timer then
    hl_timer:stop()
    hl_timer:close()
    hl_timer = nil
  end
  hl_timer = vim.loop.new_timer()
  hl_timer:start(
    250,
    0,
    vim.schedule_wrap(function()
      run_lexer_highlight()
      if hl_timer then
        hl_timer:close()
        hl_timer = nil
      end
    end)
  )
end
vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI", "TextChangedP" }, {
  buffer = vim.api.nvim_get_current_buf(),
  callback = debounced_highlight,
})
