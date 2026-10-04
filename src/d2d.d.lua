---@meta

---Represents a d2d image resource.
---@class Image
local Image = {}

---Loads an image resource from `<gamedir>\reframework\images\<filepath>`.
---@param filepath string A file path for the image to load
---@return Image
function Image.new(filepath) end

---Returns the width and height of the image in pixels.
---@return [integer, integer]
function Image:size() end

---Represents a d2d font resource.
---@class Font
local Font = {}

---Creates a font resource.
---**NOTE**: Must be called from the `init_fn` passed to [d2d.register]. It's the only valid place to call it.
---@param name string The font family name
---@param size integer The size of the created font in pixels
---@param bold boolean An optional boolean value to make the font bold
---@param italic boolean And optional boolean value to make the font italic
function Font.new(name, size, bold, italic) end

---Returns the width and height of the rendered text.
---@param text string The text to measure
function Font:measure(text) end

---@class d2d
---@field Image Image
---@field Font Font
d2d = {}

---Registers the script with d2d, allowing you to create d2d resources and draw using them.
---@param init_fn fun(): nil Called when the script should create d2d resources ([fonts](lua://Font) or [images](lua://Image))
---@param draw_fn fun(): nil Called when the script should draw using d2d and the d2d resources created in the `init_fn`
function d2d.register(init_fn, draw_fn) end

---Draws text.
---@param font Font Font resource created in the `init_fn` via `d2d.Font.new`
---@param text string
---@param x integer
---@param y integer
---@param color integer 32-bit ARGB
function d2d.text(font, text, x, y, color) end

---Draws a filled in rectangle.
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param color integer 32-bit ARGB
function d2d.fill_rect(x, y, w, h, color) end

---Draws the outline of a rectangle.
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param thickness integer
---@param color integer 32-bit ARGB
function d2d.outline_rect(x, y, w, h, thickness, color) end

---Draws a filled rounded rectangle.
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param rX integer Horizontal corner radius
---@param rY integer Vertical corner radius
---@param color integer 32-bit ARGB
function d2d.filled_rounded_rect(x, y, w, h, rX, rY, color) end

---Draws the outline of a rounded rectangle.
---@param x integer
---@param y integer
---@param w integer
---@param h integer
---@param rX integer Horizontal corner radius
---@param rY integer Vertical corner radius
---@param thickness integer
---@param color integer 32-bit ARGB
function d2d.rounded_rect(x, y, w, h, rX, rY, thickness, color) end

---Draws a filled in quad.
---@param x1 integer
---@param y1 integer
---@param x2 integer
---@param y2 integer
---@param x3 integer
---@param y3 integer
---@param x4 integer
---@param y4 integer
---@param color integer 32-bit ARGB
function d2d.fill_quad(x1, y1, x2, y2, x3, y3, x4, y4, color) end

---Draws the outline of a quad.
---@param x1 integer
---@param y1 integer
---@param x2 integer
---@param y2 integer
---@param x3 integer
---@param y3 integer
---@param x4 integer
---@param y4 integer
---@param thickness integer
---@param color integer 32-bit ARGB
function d2d.quad(x1, y1, x2, y2, x3, y3, x4, y4, thickness, color) end

---Draws a line between two points.
---@param x1 integer
---@param y1 integer
---@param x2 integer
---@param y2 integer
---@param thickness integer
---@param color integer 32-bit ARGB
function d2d.line(x1, y1, x2, y2, thickness, color) end

---Draws a filled in circle.
---@param x integer Horizontal center
---@param y integer Vertical center
---@param r number Radius
---@param color integer 32-bit ARGB
function d2d.fill_circle(x, y, r, thickness, color) end

---Draws the outline of a circle.
---@param x integer Horizontal center
---@param y integer Vertical center
---@param r number Radius
---@param thickness integer
---@param color integer 32-bit ARGB
function d2d.circle(x, y, r, thickness, color) end

----Draws a filled in oval.
---@param x integer Horizontal center
---@param y integer Vertical center
---@param rX number Horizontal radius
---@param rY number Vertical radius
---@param color integer 32-bit ARGB
function d2d.fill_oval(x, y, rX, rY, thickness, color) end

--Draws the outline of an oval.
---@param x integer Horizontal center
---@param y integer Vertical center
---@param rX number Horizontal radius
---@param rY number Vertical radius
---@param thickness integer
---@param color integer 32-bit ARGB
function d2d.oval(x, y, rX, rY, thickness, color) end

---Draws a filled in pie.
---@param x integer Horizontal center
---@param y integer Vertical center
---@param startAngle number In [-360, 360]
---@param sweepAngle number In [0, 360]
---@param color integer 32-bit ARGB
---@param clockwise? boolean Defaults to true
function d2d.pie(x, y, startAngle, sweepAngle, color, clockwise) end

---Draws a filled in ring.
---@param x integer Horizontal center
---@param y integer Vertical center
---@param outerRadius number
---@param innerRadius number
---@param startAngle number In [-360, 360]
---@param sweepAngle number In [0, 360]
---@param color integer 32-bit ARGB
---@param clockwise? boolean Defaults to true
function d2d.ring(x, y, outerRadius, innerRadius, startAngle, sweepAngle, color, clockwise) end

---Draws an image.
---**NOTE**: If `w` and `h` are omitted, the image will be drawn at its natural size.
---@param image Image [Image] resource loaded in `init_fn` via `d2d.Image.new`
---@param x integer Horizontal position of top-left corner
---@param y integer Vertical position of top-left corner
---@param w? integer
---@param h? integer
function d2d.image(image, x, y, w, h) end

---@return [integer, integer] size Width and height of the drawable surface (game window).
function d2d.surface_size() end
