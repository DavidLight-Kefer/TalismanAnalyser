local settings = {
  enabled = true,
  show_menu = true,
}

local logs = {}
local x, y = 0.5, 0
local image = nil

local initialized = false

---@return nil
local function init()
  if initialized then return end
  initialized = true

  d2d.register(
    function()
      local path = "talisman_analyser/talisman.png"
      image = d2d.Image.new(path)

      logs[#logs + 1] = { type = "info", msg = string.format("Loading %s", path) }

      if not image then
        logs[#logs + 1] = { type = "warn", msg = "FAILED" }
      end
    end,
    function()
      if not settings.enabled then return end
      if not settings.show_menu then return end
      if not image then return end

      local screen_w, screen_h = d2d.surface_size()
      local image_w, image_h = image:size()
      d2d.image(image, x * (screen_w - image_w), y * (screen_h - image_h))
    end
  )

  re.on_draw_ui(function()
    if imgui.tree_node("Talisman analyser UI config") then
      _, settings.enabled = imgui.checkbox("Enable", settings.enabled)

      _, x = imgui.slider_float("X", x, 0., 1.)
      _, y = imgui.slider_float("Y", y, 0., 1.)

      if imgui.button("Flush logs") then
        for _, entry in ipairs(logs) do
          log[entry.type](entry.msg)
        end
        logs = {}
      end

      imgui.tree_pop()
    end
  end)
end

return {
  init = init
}
