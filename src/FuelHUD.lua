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
    notif_bg  = { 0.05, 0.06, 0.09, 0.90 },
    notif_def = { 0.95, 0.80, 0.25, 1.0 },
}

local NOTIF_W     = 0.220
local NOTIF_H     = 0.036
local NOTIF_X     = 0.390   -- centered-ish
local NOTIF_Y     = 0.060
local NOTIF_TS    = 0.014

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
    self.flashQueue  = {}
    self.activeFlash = nil
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
    if not self.initialized then return end
    if g_gui and (g_gui:getIsGuiVisible() or g_gui:getIsDialogVisible()) then return end

    self:drawFlash()

    if not self.settings.enabled or not self.settings.hudEnabled then return end

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

    -- Trend indicator (ASCII — right-aligned in box)
    local trend = self.priceEngine:getTrend()
    local trendText = trend == "up" and "UP" or (trend == "down" and "DN" or "--")
    local trendCol  = trend == "up" and COLOR.expensive or (trend == "down" and COLOR.cheap or COLOR.label)
    setTextColor(trendCol[1], trendCol[2], trendCol[3], trendCol[4])
    setTextBold(false)
    setTextAlignment(RenderText.ALIGN_RIGHT)
    renderText(self.posX + C.WIDTH - C.PADDING, self.posY + C.HEIGHT * 0.15, C.FONT_SIZE * 0.70, trendText)
    setTextAlignment(RenderText.ALIGN_LEFT)
end

function FuelHUD:update(dt)
    if self.activeFlash then
        self.activeFlash.timer = self.activeFlash.timer + dt / 1000
        if self.activeFlash.timer >= self.activeFlash.duration then
            self.activeFlash = nil
        end
    end
    if not self.activeFlash and #self.flashQueue > 0 then
        self.activeFlash = table.remove(self.flashQueue, 1)
    end
end

function FuelHUD:flash(message, color, duration)
    table.insert(self.flashQueue, {
        message  = message or "",
        color    = color or COLOR.notif_def,
        timer    = 0,
        duration = duration or 4,
    })
end

function FuelHUD:drawFlash()
    if not self.activeFlash or not self.overlay then return end

    local t = self.activeFlash.timer
    local d = self.activeFlash.duration
    local alpha = 1.0
    if t < 0.25 then
        alpha = t / 0.25
    elseif t > d - 0.80 then
        alpha = math.max(0, (d - t) / 0.80)
    end

    local pulse     = 0.75 + 0.25 * math.sin(t * 5)
    local textAlpha = alpha * pulse
    local c         = self.activeFlash.color

    -- background
    setOverlayColor(self.overlay,
        COLOR.notif_bg[1], COLOR.notif_bg[2], COLOR.notif_bg[3], COLOR.notif_bg[4] * alpha)
    renderOverlay(self.overlay, NOTIF_X, NOTIF_Y, NOTIF_W, NOTIF_H)

    -- left accent bar
    setOverlayColor(self.overlay, c[1], c[2], c[3], (c[4] or 1) * alpha)
    renderOverlay(self.overlay, NOTIF_X, NOTIF_Y, 0.003, NOTIF_H)

    -- message text
    setTextColor(c[1], c[2], c[3], textAlpha)
    setTextBold(true)
    setTextAlignment(RenderText.ALIGN_LEFT)
    renderText(NOTIF_X + 0.010, NOTIF_Y + NOTIF_H * 0.28, NOTIF_TS, self.activeFlash.message)
end

function FuelHUD:delete()
    if self.overlay then
        delete(self.overlay)
        self.overlay = nil
    end
    self.initialized = false
end
