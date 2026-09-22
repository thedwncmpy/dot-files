local M = {}

local order_file = vim.fn.expand("~/.config/tmux/session-order.json")
local buffers = {}

local function tmux(...)
  local command = { "tmux", ... }
  local result = vim.system(command, { text = true }):wait()
  if result.code ~= 0 then
    error(vim.trim(result.stderr or result.stdout or "tmux command failed"))
  end
  return result.stdout or ""
end

local function sessions()
  local items = {}
  local output = tmux("list-sessions", "-F", "#{session_id}\t#{session_name}\t#{session_windows}")
  for line in output:gmatch("[^\n]+") do
    local id, name, windows = line:match("^([^\t]+)\t([^\t]+)\t([^\t]+)$")
    if not id then error("Could not read a tmux session: " .. line) end
    items[#items + 1] = { id = id, name = name, windows = tonumber(windows), index = #items + 1 }
  end
  return items
end

local function saved_order()
  local ok, lines = pcall(vim.fn.readfile, order_file)
  if not ok then return {} end
  local decoded, names = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not decoded or type(names) ~= "table" then return {} end
  return names
end

local function ordered_sessions()
  local items = sessions()
  local positions = {}
  for index, name in ipairs(saved_order()) do
    if type(name) == "string" then positions[name] = index end
  end
  table.sort(items, function(a, b)
    local left, right = positions[a.name], positions[b.name]
    if left and right then return left < right end
    if left then return true end
    if right then return false end
    return a.index < b.index
  end)
  return items
end

local function save_order(rows)
  local names = {}
  for _, row in ipairs(rows) do names[#names + 1] = row.name end
  local temporary = order_file .. ".tmp." .. vim.fn.getpid()
  vim.fn.writefile({ vim.json.encode(names) }, temporary)
  local ok, err = vim.uv.fs_rename(temporary, order_file)
  if not ok then
    vim.fn.delete(temporary)
    error("Could not save session order: " .. tostring(err))
  end
end

local function render(buf)
  local items = ordered_sessions()
  local lines = {}
  local original = {}
  for _, item in ipairs(items) do
    lines[#lines + 1] = item.id .. "  " .. item.name
    original[item.id] = item.name
  end
  buffers[buf].original = original
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modified = false
end

local function edited_rows(buf, original)
  local rows, seen_ids, seen_names = {}, {}, {}
  for number, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    local trimmed = vim.trim(line)
    if trimmed ~= "" then
      local id, name = trimmed:match("^(%$%d+)%s+(.+)$")
      if not id then
        if trimmed:match("^%$%d+") then error("Line " .. number .. ": add a name after the session ID") end
        name = trimmed
      else
        name = vim.trim(name)
        if not original[id] then error("Line " .. number .. ": unknown session ID " .. id) end
        if seen_ids[id] then error("Line " .. number .. ": duplicate session ID " .. id) end
        seen_ids[id] = true
      end
      if seen_names[name] then error("Line " .. number .. ": duplicate session name " .. name) end
      seen_names[name] = true
      rows[#rows + 1] = { id = id, name = name }
    end
  end
  if #rows == 0 then error("Keep at least one session in the list") end
  return rows, seen_ids
end

local function verify_unchanged(original)
  local live = sessions()
  local count = 0
  for _, item in ipairs(live) do
    count = count + 1
    if original[item.id] ~= item.name then
      error("Sessions changed outside this buffer. Press R to refresh before saving")
    end
  end
  local old_count = 0
  for _ in pairs(original) do old_count = old_count + 1 end
  if count ~= old_count then
    error("Sessions changed outside this buffer. Press R to refresh before saving")
  end
end

local function temporary_name(used, index)
  local base = "__session_edit_" .. vim.fn.getpid() .. "_" .. index
  local name = base
  while used[name] do name = name .. "_" end
  used[name] = true
  return name
end

local function apply(buf)
  local original = buffers[buf].original
  local rows, kept = edited_rows(buf, original)
  verify_unchanged(original)

  local removed, renamed = {}, {}
  local desired_names = {}
  for _, row in ipairs(rows) do
    desired_names[row.name] = true
    if row.id and original[row.id] ~= row.name then renamed[#renamed + 1] = row end
  end
  for id, name in pairs(original) do
    if not kept[id] then removed[#removed + 1] = { id = id, name = name } end
  end
  table.sort(removed, function(a, b) return a.id < b.id end)

  if #removed > 0 then
    local names = {}
    for _, item in ipairs(removed) do names[#names + 1] = item.name end
    local choice = vim.fn.confirm("Kill tmux session(s): " .. table.concat(names, ", ") .. "?", "&Yes\n&No", 2)
    if choice ~= 1 then return false end
  end

  local used = vim.deepcopy(desired_names)
  for _, name in pairs(original) do used[name] = true end
  local index = 0
  for _, item in ipairs(renamed) do
    index = index + 1
    tmux("rename-session", "-t", item.id, temporary_name(used, index))
  end
  for _, item in ipairs(removed) do
    index = index + 1
    tmux("rename-session", "-t", item.id, temporary_name(used, index))
  end
  for _, item in ipairs(renamed) do tmux("rename-session", "-t", item.id, item.name) end
  for _, item in ipairs(rows) do
    if not item.id then tmux("new-session", "-d", "-s", item.name, "-c", vim.fn.getcwd()) end
  end

  -- Save before killing the session that owns this popup: doing so closes Neovim.
  save_order(rows)
  local current = vim.trim(tmux("display-message", "-p", "#{session_id}"))
  for _, item in ipairs(removed) do
    if item.id ~= current then tmux("kill-session", "-t", item.id) end
  end
  for _, item in ipairs(removed) do
    if item.id == current then
      tmux("kill-session", "-t", item.id)
      return true
    end
  end
  render(buf)
  return true
end

local function report_error(err)
  vim.notify(tostring(err), vim.log.levels.ERROR, { title = "Tmux sessions" })
end

local function save(buf)
  local ok, applied = pcall(apply, buf)
  if not ok then report_error(applied) end
  return ok and applied
end

local function switch(buf, position)
  local row = position or vim.api.nvim_win_get_cursor(0)[1]
  if vim.bo[buf].modified and not save(buf) then return end
  local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
  local id = line:match("^(%$%d+)")
  if not id then
    if position then vim.notify("No session at position " .. position, vim.log.levels.INFO) end
    return
  end
  local ok, err = pcall(tmux, "switch-client", "-t", id)
  if not ok then report_error(err) else vim.cmd("quit") end
end

function M.open()
  if not vim.env.TMUX then
    report_error("TmuxSessions must run inside tmux")
    return
  end

  local buf = vim.api.nvim_create_buf(true, false)
  buffers[buf] = {}
  vim.api.nvim_buf_set_name(buf, "tmux-sessions://sessions")
  vim.bo[buf].buftype = "acwrite"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "tmuxsessions"
  vim.api.nvim_set_current_buf(buf)
  vim.wo.number = true
  vim.wo.relativenumber = false
  vim.wo.winbar = " tmux sessions  |  :w apply  Enter/1-9/0 switch  R refresh  q close  g? help "

  local ok, err = pcall(render, buf)
  if not ok then report_error(err); return end

  local group = vim.api.nvim_create_augroup("TmuxSessions" .. buf, { clear = true })
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    group = group,
    buffer = buf,
    callback = function() save(buf) end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = group,
    buffer = buf,
    callback = function() buffers[buf] = nil end,
  })

  local function map(lhs, callback, description)
    vim.keymap.set("n", lhs, callback, { buffer = buf, silent = true, desc = description })
  end
  map("<CR>", function() switch(buf) end, "Switch to session")
  for index = 1, 10 do
    local key = index == 10 and "0" or tostring(index)
    map(key, function() switch(buf, index) end, "Switch to session " .. index)
  end
  map("q", "<cmd>quit<cr>", "Close session editor")
  map("R", function()
    if vim.bo[buf].modified and vim.fn.confirm("Discard unsaved session edits?", "&Yes\n&No", 2) ~= 1 then return end
    local refreshed, refresh_error = pcall(render, buf)
    if not refreshed then report_error(refresh_error) end
  end, "Refresh sessions")
  map("g?", function()
    vim.notify("Move lines with ddp, :m, or visual J/K. Edit names, add a bare name, or delete a line; :w applies. Enter or 1-9/0 switches sessions.", vim.log.levels.INFO, { title = "Tmux sessions" })
  end, "Session editor help")
end

return M
