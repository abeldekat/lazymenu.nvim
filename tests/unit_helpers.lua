local M = {}

function M.all_keys(spec)
  local result = {}
  for _, plugin in ipairs(spec) do
    for _, key in ipairs(plugin.keys) do
      table.insert(result, key[1])
    end
  end
  return result
end

---@param opts LazyMenuOptions
---@return LazyMenuPluginAdapter
function M.plugin(opts, decorators)
  return {
    get_opts = function()
      return opts
    end,
    setup = function(remap_cb, to_change)
      -- stylua: ignore
      local add_decorated = remap_cb(function(_, plugin, _) return plugin end, to_change)
      decorators["plugin"] = add_decorated
    end,
  }
end

---@return LazyMenuWhichKeyAdapter
function M.which_key(decorators)
  return {
    setup = function(remap_cb, to_change)
      local values_decorated = remap_cb(function() end, to_change)
      decorators["which_key"] = values_decorated
    end,
  }
end

---@return LazyMenuLspAdapter
function M.lsp(decorators)
  return {
    leaders = function()
      return {}
    end,
    setup = function(remap_cb, to_change)
      local resolve_decorated = remap_cb(function() end, to_change)
      decorators["lsp"] = resolve_decorated
    end,
  }
end

---@return LazyMenuKeymapsAdapter
function M.keymaps(decorators)
  return {
    leaders = function()
      return {}
    end,
    setup = function(remap_cb, to_change)
      local safe_keymap_set_decorated = remap_cb(function() end, to_change)
      decorators["keymaps"] = safe_keymap_set_decorated
    end,
  }
end

-- simulate lazy.nvim parsing the spec
local function run(decorators, spec)
  for _, plugin in ipairs(spec) do
    decorators.plugin(_, plugin) -- lazy.nvim: parsing the spec
  end
  -- for _, plugin in ipairs(spec) do
  --   -- decorators.which_key() -- lazy.nvim: loading plugins
  -- end
  -- for _, plugin in ipairs(spec) do
  --   -- decorators.lsp() -- LazyVim: attaching lsp
  -- end
  -- for _, plugin in ipairs(spec) do
  --   -- decorators.keymaps() -- LazyVim: Requiring lazyvim.config.keymaps on VeryLazy
  -- end
end

-- activate lazymenu. See lazymenu.hook
---@param opts LazyMenuOptions
function M.activate(opts, spec)
  -- contains decorated functions, defined in the adapters
  local decorators = {}
  ---@type LazyMenuAdapters
  local fake_adapters = {
    plugin = M.plugin(opts, decorators),
    which_key = M.which_key(decorators),
    lsp = M.lsp(decorators),
    keymaps = M.keymaps(decorators),
  }

  local dummy_spec = require("lazymenu").on_hook(fake_adapters)
  run(decorators, spec) -- all hooks are ready: run
  return dummy_spec
end

return M
