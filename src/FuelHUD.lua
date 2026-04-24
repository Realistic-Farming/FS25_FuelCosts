-- =========================================================
-- FS25 Realistic Fuel Costs - FuelHUD
-- =========================================================
-- Small overlay showing the current fuel price per litre.
-- Colour-coded: green (cheap) / white (normal) / red (expensive).
-- Draggable via right-click.
-- =========================================================

---@class FuelHUD
FuelHUD = {}
FuelHUD.__index = FuelHUD

local COLOR = {
    cheap     = { 0.40, 0.85, 0.40, 1.0 },
    normal    = { 0.95, 0.95, 0.95, 1.0 },
    expensive = { 0.95, 0.35, 0.35, 1.0 },
    bg        = { 0.05, 0.05, 0.05, 0.75 },
    label     = { 0.70, 0.70, 0.70, 1.0 },
}

function FuelHUD.new(settings, priceEngine)
    local self = setmetatable({}, FuelHUD)
    self.settings    = settings
    self.priceEngine = priceEngine
    self.posX        = 0.01
    self.posY        = 0.90
    self.overlay     = nil
    self.initialized = false
    self.isDragging  = false
    self.dragOffX    = 0
    self.dragOffY    = 0
    return self
end

function FuelHUD:init()
    if createImageOverlay ~= nil then
        self.overlay = createImageOverlay("dataS/menu/base/graph_pixel.dds")
    else
        FuelLogger.warning("HUD: createImageOverlay not available — background will not render")
    end
    self.initialized = true
    FuelLogger.info("HUD initialized")
end

function FuelHUD:updatePosition()
    local C = FuelConstants.HUD
    local positions = {
        topLeft     = { x = 0.01,       y = 1.0 - C.HEIGHT - 0.01 },
        topRight    = { x = 1.0 - C.WIDTH - 0.01, y = 1.0 - C.HEIGHT - 0.01 },
        bottomLeft  = { x = 0.01,       y = 0.01 },
        bottomRight = { x = 1.0 - C.WIDTH - 0.01, y = 0.01 },
    }
    local anchor = FuelSettingsSchema.HUD_POSITION_MAP[self.settings.hudPosition] or "topLeft"
    local pos = positions[anchor] or positions.topLeft
    self.posX = pos.x
    self.posY = pos.y
end

function FuelHUD:draw()
    if not self.settings.enabled or not self.settings.hudEnabled then return end
    if not self.initialized then return end

    local C      = FuelConstants.HUD
    local price  = self.priceEngine:getDisplayPrice()
    local status = self.priceEngine:getPriceStatus()
    local col    = COLOR[status] or COLOR.normal

    -- Background
    if self.overlay then
        setOverlayColor(self.overlay, COLOR.bg[1], COLOR.bg[2], COLOR.bg[3], COLOR.bg[4])
        renderOverlay(self.overlay, self.posX, self.posY, C.WIDTH, C.HEIGHT)
    end

    -- Label
    setTextColor(COLOR.label[1], COLOR.label[2], COLOR.label[3], COLOR.label[4])
    setTextAlignment(RenderText.ALIGN_LEFT)
    setTextBold(false)
    renderText(self.posX + C.PADDING, self.posY + C.HEIGHT * 0.60, C.FONT_SIZE * 0.75,
        g_i18n:getText("fc_hud_label") or "DIESEL")

    -- Price value
    setTextColor(col[1], col[2], col[3], col[4])
    setTextBold(true)
    renderText(self.posX + C.PADDING, self.posY + C.HEIGHT * 0.15, C.FONT_SIZE,
        string.format("$%.4f/L", price))
end

function FuelHUD:delete()
    if self.overlay then
        delete(self.overlay)
        self.overlay = nil
    end
    self.initialized = false
end
