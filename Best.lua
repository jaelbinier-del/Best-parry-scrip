--[[======================================================================
    BETS AUTO PARRY v6  x  DYX PANEL   —   SCRIPT UNIFICADO
    ------------------------------------------------------------------
    Incluye:  Bypass BAC + Anti-Kick + Auto-Rejoin
              Panel completo + Auto Parry + Auto/Manual Spam
    Contrasena: 1342
    Ejecutar:  loadstring(game:HttpGet("TU_URL"))()
======================================================================]]

--============================= SERVICIOS =============================
local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local UserInputService    = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService     = game:GetService("TeleportService")
local TweenService        = game:GetService("TweenService")
local HttpService         = game:GetService("HttpService")
local Workspace           = game:GetService("Workspace")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local PASSWORD = "1342"
local VERSION  = "v6-merged"

--============================== CONFIG ===============================
local Config = {
    -- Combat
    AutoParry = false, LobbyParry = false, AutoSpam = false,
    ManualSpam = false, Triggerbot = false, Curve = 0.5,
    -- Ability
    AutoAbility = false, ProtectionCD = false, DribblePreClick = false,
    FullCounter = false, SnFCounter = false,
    -- Visuals
    BallESP = true, BallTracer = false,
    -- Sistema (core de BETS)
    AntiKick = true, AutoRejoin = true, Jitter = true,
    -- Modo de accion
    ParryMode = "Click", SpamMode = "Click",
    -- Teclas
    ParryKey = "F", SpamKey = "E", AbilityKey = "E", ProtectionKey = "R",
    FullCounterKey = "Q", SnFKey = "Z", UIToggleKey = "RightShift",
    -- Tuning
    ParryRange = 24, HitRadius = 7, TimeToImpact = 0.30,
    ParryDelay = 0.12, SpamDelay = 0.05, AbilityDelay = 0.12,
    SnFRange = 20, BallName = "ball",
}

local CFG_FILE = "bets_dyx_cfg.json"
if readfile and isfile and isfile(CFG_FILE) then
    pcall(function()
        local data = HttpService:JSONDecode(readfile(CFG_FILE))
        for k, v in pairs(data) do if Config[k] ~= nil then Config[k] = v end end
    end)
end
local function saveConfig()
    if writefile then pcall(function() writefile(CFG_FILE, HttpService:JSONEncode(Config)) end) end
end

--=========================== HELPERS BASE ============================
local READY = false
local function rand(a, b) return a + math.random() * (b - a) end

local function waitFor(parent, name, timeout)
    local t = 0
    while t < (timeout or 10) do
        local c = parent:FindFirstChild(name)
        if c then return c end
        task.wait(0.2)
        t = t + 0.2
    end
    return nil
end

--============================================================
-- 1) BYPASS BAC  (va primero, depende del timing)
--============================================================
local BAC_OK = false
task.spawn(function()
    local RS = game:GetService("ReplicatedStorage")
    local sec = waitFor(RS, "Security", 15)
    if sec then
        pcall(function()
            local re = sec:FindFirstChild("RemoteEvent")
            if re then re:Destroy() end
            local empty = sec:FindFirstChild("")
            if empty then empty:Destroy() end
            sec:Destroy()
        end)
        BAC_OK = true
    end

    local ps = waitFor(player, "PlayerScripts", 15)
    if ps then
        local client = waitFor(ps, "Client", 15)
        if client then
            local dc = waitFor(client, "DeviceChecker", 15)
            if dc then pcall(function() dc:Destroy() end) end
        end
    end
    print("[BETS] Bypass BAC aplicado")
end)

--============================================================
-- 2) ANTI-KICK  (hook de __namecall)
--============================================================
local ANTI_KICK_OK = false
task.spawn(function()
    pcall(function()
        local rawmt = getrawmetatable or (debug and debug.getmetatable)
        local newccl = newcclosure or function(f) return f end
        local getncm = getnamecallmethod or (debug and debug.getnamecallmethod)
        if not rawmt or not getncm then return end

        local mt = rawmt(game)
        local old = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newccl(function(self, ...)
            if Config.AntiKick and getncm() == "Kick" and self == player then
                return
            end
            return old(self, ...)
        end)
        setreadonly(mt, true)
        ANTI_KICK_OK = true
        print("[BETS] Anti-Kick activo")
    end)
end)

--============================================================
-- 3) AUTO-REJOIN
--============================================================
task.spawn(function()
    local placeId, jobId = game.PlaceId, game.JobId
    player.AncestryChanged:Connect(function()
        if player.Parent ~= game then
            task.wait(1)
            if not Config.AutoRejoin then return end
            pcall(function()
                TeleportService:TeleportToPlaceInstance(placeId, jobId, player)
            end)
        end
    end)
end)

--============================================================
-- 4) Gate de carga: no clicar hasta que el juego este listo
--============================================================
task.spawn(function() task.wait(3) READY = true end)
player.CharacterAdded:Connect(function()
    READY = false
    task.wait(2.5)
    READY = true
end)

--============================ HELPERS UI =============================
local function mk(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end
local function round(o, r) return mk("UICorner", {CornerRadius = UDim.new(0, r)}, o) end
local function outline(o, col, th, tr)
    return mk("UIStroke", {Color = col or Color3.fromRGB(60,60,70), Thickness = th or 1,
        Transparency = tr or 0.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, o)
end

local FONT, FONTB = Enum.Font.GothamMedium, Enum.Font.GothamBold
local C = {
    BG     = Color3.fromRGB(14,14,16),
    PANEL  = Color3.fromRGB(22,22,32),
    CARD   = Color3.fromRGB(43,43,58),
    CARD2  = Color3.fromRGB(34,34,46),
    TEXT   = Color3.fromRGB(235,235,240),
    SUB    = Color3.fromRGB(160,160,175),
    ACCENT = Color3.fromRGB(130,75,255),
    ACC2   = Color3.fromRGB(190,155,255),
    ON     = Color3.fromRGB(95,55,175),
    OFF    = Color3.fromRGB(70,70,88),
    WHITE  = Color3.fromRGB(250,250,252),
    RED    = Color3.fromRGB(180,55,65),
}

local function makeDraggable(btn, onTap)
    local dragging, moved, dragStart, startPos = false, false, nil, nil
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging, moved = true, false
            dragStart, startPos = input.Position, btn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if not moved then onTap() end
                end
            end)
        end
    end)
    btn.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            if d.Magnitude > 5 then moved = true end
            btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                     startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

--============================= GUI RAICES ============================
local function getGuiParent()
    local ok, hui = pcall(function() return gethui() end)
    if ok and hui then return hui end
    return playerGui
end

if getgenv().BETS_DYX_GUI and getgenv().BETS_DYX_GUI.Parent then
    pcall(function() getgenv().BETS_DYX_GUI:Destroy() end)
end

local gui = mk("ScreenGui", {
    Name = "AP_" .. tostring(math.random(10000, 99999)),
    ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 999999,
}, getGuiParent())
getgenv().BETS_DYX_GUI = gui

--============================= NOTIFICACIONES ========================
local NotifBox = mk("Frame", {Size = UDim2.new(0, 260, 0, 0), AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 60), BackgroundTransparency = 1}, gui)
mk("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment = Enum.HorizontalAlignment.Center}, NotifBox)

local function notify(text, col)
    local n = mk("TextLabel", {Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = C.PANEL,
        Text = text, Font = FONTB, TextSize = 12, TextColor3 = col or C.ACC2}, NotifBox)
    round(n, 8)
    outline(n, col or C.ACCENT, 1, 0.6)
    task.spawn(function()
        task.wait(2.2)
        TweenService:Create(n, TweenInfo.new(0.3), {BackgroundTransparency = 1,
            TextTransparency = 1}):Play()
        task.wait(0.35)
        n:Destroy()
    end)
end

--============================== LOGIN ================================
local authenticated = false

local login = mk("Frame", {Size = UDim2.fromOffset(310, 190),
    Position = UDim2.new(0.5, -155, 0.5, -95), AnchorPoint = Vector2.new(0, 0),
    BackgroundColor3 = C.PANEL, Visible = true, ZIndex = 45}, gui)
round(login, 12)
outline(login, C.ACCENT, 2, 0.2)

mk("TextLabel", {Size = UDim2.new(1, -20, 0, 26), Position = UDim2.fromOffset(10, 8),
    BackgroundTransparency = 1, Text = "BETS AUTO PARRY " .. VERSION,
    TextColor3 = C.ACC2, TextSize = 15, Font = FONTB, ZIndex = 46}, login)
mk("TextLabel", {Size = UDim2.new(1, -20, 0, 16), Position = UDim2.fromOffset(10, 32),
    BackgroundTransparency = 1, Text = "Bypass BAC + Anti-Kick + Panel",
    TextColor3 = C.SUB, TextSize = 11, Font = FONT, ZIndex = 46}, login)

local input = mk("TextBox", {Size = UDim2.new(1, -36, 0, 40), Position = UDim2.fromOffset(18, 58),
    BackgroundColor3 = C.CARD2, Text = "", PlaceholderText = "Introduce la contrasena",
    PlaceholderColor3 = C.SUB, TextColor3 = C.WHITE, TextSize = 15, Font = FONT,
    ClearTextOnFocus = false, ZIndex = 46}, login)
round(input, 8)

local enter = mk("TextButton", {Size = UDim2.new(1, -36, 0, 38), Position = UDim2.fromOffset(18, 108),
    BackgroundColor3 = C.ACCENT, Text = "ENTRAR", TextColor3 = C.WHITE, TextSize = 15,
    Font = FONTB, ZIndex = 46}, login)
round(enter, 8)

local message = mk("TextLabel", {Size = UDim2.new(1, -20, 0, 22), Position = UDim2.fromOffset(10, 152),
    BackgroundTransparency = 1, Text = "", TextColor3 = Color3.fromRGB(255,100,110),
    TextSize = 12, Font = FONT, ZIndex = 46}, login)

--========================= BOTONES FLOTANTES =========================
local SpamActive = false
local SpamBtn, OpenBtn

local function renderSpamBtn()
    if SpamActive then
        SpamBtn.BackgroundColor3 = C.ON; SpamBtn.Text = "SPM\nON"
    else
        SpamBtn.BackgroundColor3 = Color3.fromRGB(60,60,80); SpamBtn.Text = "SPM\nOFF"
    end
end

SpamBtn = mk("TextButton", {Size = UDim2.fromOffset(54, 54), Position = UDim2.new(0, 20, 0.58, 0),
    BackgroundColor3 = Color3.fromRGB(60,60,80), Text = "SPM\nOFF", TextColor3 = C.WHITE,
    TextSize = 12, Font = FONTB, ZIndex = 50, Visible = false}, gui)
round(SpamBtn, 27)
mk("UIStroke", {Color = C.ACCENT, Thickness = 2}, SpamBtn)

OpenBtn = mk("TextButton", {Size = UDim2.fromOffset(54, 54), Position = UDim2.new(0, 20, 0.45, 0),
    BackgroundColor3 = C.ACCENT, Text = "B", TextColor3 = C.WHITE, TextSize = 25,
    Font = FONTB, ZIndex = 50}, gui)
round(OpenBtn, 27)

--=========================== PANEL PRINCIPAL =========================
local Main = mk("Frame", {Name = "MainMenu", Size = UDim2.fromOffset(620, 400),
    Position = UDim2.new(0.5, -310, 0.5, -200), BackgroundColor3 = C.PANEL,
    BorderSizePixel = 0, Visible = false, ClipsDescendants = true, ZIndex = 40}, gui)
round(Main, 12)
outline(Main, C.ACCENT, 2, 0.25)

local Header = mk("Frame", {Size = UDim2.new(1,0,0,44), BackgroundColor3 = C.BG,
    BorderSizePixel = 0, ZIndex = 41}, Main)
round(Header, 12)
makeDraggable(Header, function() end)

mk("TextLabel", {Size = UDim2.new(0,26,1,0), Position = UDim2.new(0,10,0,0),
    BackgroundTransparency = 1, Text = "⚡", Font = FONTB, TextSize = 18, TextColor3 = C.ACC2,
    ZIndex = 42}, Header)
mk("TextLabel", {Size = UDim2.new(0,70,1,0), Position = UDim2.new(0,34,0,0),
    BackgroundTransparency = 1, Text = "BETS", Font = FONTB, TextSize = 15, TextColor3 = C.TEXT,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 42}, Header)

local chipVer = mk("Frame", {Size = UDim2.fromOffset(62,22), Position = UDim2.new(0,96,0.5,-11),
    BackgroundColor3 = C.CARD2, ZIndex = 42}, Header)
round(chipVer, 6)
mk("TextLabel", {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "⚡ " .. VERSION,
    Font = FONTB, TextSize = 10, TextColor3 = C.ACC2, ZIndex = 43}, chipVer)

local statusLbl = mk("TextLabel", {Size = UDim2.new(0,150,1,0), Position = UDim2.new(0,166,0,0),
    BackgroundTransparency = 1, Text = "Estado: listo", Font = FONT, TextSize = 11,
    TextColor3 = C.SUB, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 42}, Header)

local hideLbl = mk("TextButton", {Size = UDim2.new(0,100,0,22), Position = UDim2.new(1,-196,0.5,-11),
    BackgroundColor3 = C.CARD2, Text = "Ocultar UI", Font = FONT, TextSize = 11,
    TextColor3 = C.SUB, AutoButtonColor = false, ZIndex = 42}, Header)
round(hideLbl, 6)

local function hdrBtn(x, txt, cb, col)
    local b = mk("TextButton", {Size = UDim2.fromOffset(26,26), Position = UDim2.new(1,x,0.5,-13),
        BackgroundColor3 = col or C.CARD, Text = txt, Font = FONTB, TextSize = 13,
        TextColor3 = C.TEXT, AutoButtonColor = false, ZIndex = 42}, Header)
    round(b, 7)
    b.MouseButton1Click:Connect(cb)
    return b
end
hdrBtn(-100, "—", function() Main.Size = UDim2.fromOffset(620, 46) end)
hdrBtn(-70,  "□", function() Main.Size = UDim2.fromOffset(620, 400) end)
hdrBtn(-40,  "✕", function() Main.Visible = false end, C.RED)

local Sidebar = mk("Frame", {Size = UDim2.new(0,150,1,-56), Position = UDim2.new(0,6,0,50),
    BackgroundTransparency = 1, ZIndex = 41}, Main)
mk("UIListLayout", {Padding = UDim.new(0,4), SortOrder = Enum.SortOrder.LayoutOrder}, Sidebar)

local Content = mk("Frame", {Size = UDim2.new(1,-166,1,-56), Position = UDim2.new(0,160,0,50),
    BackgroundTransparency = 1, ZIndex = 41}, Main)

local TabButtons = {}
local function addTab(id, label, icon, order)
    local btn = mk("TextButton", {Size = UDim2.new(1,0,0,34), BackgroundColor3 = C.CARD,
        BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = order,
        ZIndex = 42}, Sidebar)
    round(btn, 8)
    local bar = mk("Frame", {Size = UDim2.new(0,3,0,16), Position = UDim2.new(0,0,0.5,-8),
        BackgroundColor3 = C.ACC2, Visible = false, ZIndex = 43}, btn)
    round(bar, 2)
    local ic = mk("TextLabel", {Size = UDim2.new(0,24,1,0), Position = UDim2.new(0,8,0,0),
        BackgroundTransparency = 1, Text = icon, Font = FONT, TextSize = 15, TextColor3 = C.SUB,
        ZIndex = 43}, btn)
    local tx = mk("TextLabel", {Size = UDim2.new(1,-40,1,0), Position = UDim2.new(0,36,0,0),
        BackgroundTransparency = 1, Text = label, Font = FONT, TextSize = 13, TextColor3 = C.SUB,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 43}, btn)

    local page = mk("ScrollingFrame", {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
        Visible = false, ScrollBarThickness = 3, ScrollBarImageColor3 = C.OFF,
        CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0, ZIndex = 42}, Content)
    mk("UIListLayout", {Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder}, page)
    mk("UIPadding", {PaddingRight = UDim.new(0,8), PaddingBottom = UDim.new(0,10)}, page)

    TabButtons[id] = {btn = btn, page = page, ic = ic, tx = tx, bar = bar}
    btn.MouseButton1Click:Connect(function()
        for k, t in pairs(TabButtons) do
            local on = (k == id)
            t.page.Visible = on
            t.btn.BackgroundTransparency = on and 0 or 1
            t.ic.TextColor3 = on and C.ACC2 or C.SUB
            t.tx.TextColor3 = on and C.TEXT or C.SUB
            t.bar.Visible = on
        end
    end)
    return page
end

--========================== COMPONENTES ==============================
local function createSection(page, title, order)
    local holder = mk("Frame", {Size = UDim2.new(1,0,0,0), BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order or 0, ZIndex = 42}, page)
    mk("UIListLayout", {Padding = UDim.new(0,6), SortOrder = Enum.SortOrder.LayoutOrder}, holder)

    local head = mk("TextButton", {Size = UDim2.new(1,0,0,30), BackgroundColor3 = C.CARD2,
        Text = "", AutoButtonColor = false, LayoutOrder = 0, ZIndex = 43}, holder)
    round(head, 8)
    mk("TextLabel", {Size = UDim2.new(1,-34,1,0), Position = UDim2.new(0,10,0,0),
        BackgroundTransparency = 1, Text = title, Font = FONTB, TextSize = 13, TextColor3 = C.TEXT,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44}, head)
    local arrow = mk("TextLabel", {Size = UDim2.new(0,20,1,0), Position = UDim2.new(1,-26,0,0),
        BackgroundTransparency = 1, Text = "⌄", Font = FONTB, TextSize = 16, TextColor3 = C.SUB,
        ZIndex = 44}, head)

    local body = mk("Frame", {Size = UDim2.new(1,0,0,0), BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1, ZIndex = 43}, holder)
    mk("UIListLayout", {Padding = UDim.new(0,6), SortOrder = Enum.SortOrder.LayoutOrder}, body)

    head.MouseButton1Click:Connect(function()
        body.Visible = not body.Visible
        arrow.Text = body.Visible and "⌄" or "›"
    end)
    return body
end

local function createRow(body, label, order)
    local card = mk("Frame", {Size = UDim2.new(1,0,0,34), BackgroundColor3 = C.CARD,
        LayoutOrder = order or 0, ZIndex = 43}, body)
    round(card, 8)
    mk("TextLabel", {Size = UDim2.new(1,-80,1,0), Position = UDim2.new(0,10,0,0),
        BackgroundTransparency = 1, Text = label, Font = FONT, TextSize = 13, TextColor3 = C.TEXT,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 44}, card)
    return card
end

local function createToggle(body, label, default, cb, order)
    local card = createRow(body, label, order)
    local pill = mk("Frame", {Size = UDim2.new(0,40,0,20), Position = UDim2.new(1,-50,0.5,-10),
        BackgroundColor3 = C.OFF, ZIndex = 44}, card)
    round(pill, 10)
    local knob = mk("Frame", {Size = UDim2.new(0,16,0,16), Position = UDim2.new(0,2,0.5,-8),
        BackgroundColor3 = C.WHITE, ZIndex = 45}, pill)
    round(knob, 8)
    local hit = mk("TextButton", {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false, ZIndex = 46}, card)

    local state = default and true or false
    local pOn, pOff = UDim2.new(0,22,0.5,-8), UDim2.new(0,2,0.5,-8)
    local function render(anim)
        if anim then
            TweenService:Create(knob, TweenInfo.new(0.14), {Position = state and pOn or pOff}):Play()
            TweenService:Create(pill, TweenInfo.new(0.14), {BackgroundColor3 = state and C.ON or C.OFF}):Play()
        else
            knob.Position = state and pOn or pOff
            pill.BackgroundColor3 = state and C.ON or C.OFF
        end
    end
    render(false)

    local api = {}
    function api.Set(v, fire)
        state = v and true or false
        render(true)
        if fire and cb then task.spawn(cb, state) end
    end
    function api.Get() return state end
    hit.MouseButton1Click:Connect(function() api.Set(not state, true) end)
    return api
end

local function createSlider(body, label, min, max, default, cb, order)
    local card = mk("Frame", {Size = UDim2.new(1,0,0,44), BackgroundColor3 = C.CARD,
        LayoutOrder = order or 0, ZIndex = 43}, body)
    round(card, 8)
    mk("TextLabel", {Size = UDim2.new(1,-80,0,18), Position = UDim2.new(0,10,0,4),
        BackgroundTransparency = 1, Text = label, Font = FONT, TextSize = 13, TextColor3 = C.TEXT,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 44}, card)
    local val = mk("TextLabel", {Size = UDim2.new(0,70,0,18), Position = UDim2.new(1,-80,0,4),
        BackgroundTransparency = 1, Text = tostring(default), Font = FONTB, TextSize = 12,
        TextColor3 = C.ACC2, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 44}, card)

    local track = mk("Frame", {Size = UDim2.new(1,-20,0,5), Position = UDim2.new(0,10,1,-14),
        BackgroundColor3 = C.OFF, ZIndex = 44}, card)
    round(track, 3)
    local fill = mk("Frame", {Size = UDim2.new(0,0,1,0), BackgroundColor3 = C.ACC2, ZIndex = 45}, track)
    round(fill, 3)
    local knob = mk("Frame", {Size = UDim2.new(0,12,0,12), AnchorPoint = Vector2.new(0.5,0.5),
        Position = UDim2.new(0,0,0.5,0), BackgroundColor3 = C.WHITE, ZIndex = 46}, track)
    round(knob, 6)

    local isInt = (max - min) > 5
    local value = default
    local function set(v, fire)
        value = math.clamp(v, min, max)
        local a = (value - min) / (max - min)
        fill.Size = UDim2.new(a, 0, 1, 0)
        knob.Position = UDim2.new(a, 0, 0.5, 0)
        val.Text = isInt and string.format("%d", value) or string.format("%.2f", value)
        if fire and cb then task.spawn(cb, value) end
    end
    set(default, false)

    local dragging = false
    local function fromX(x)
        local rel = (x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
        set(min + (max - min) * math.clamp(rel, 0, 1), true)
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; fromX(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then fromX(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    return {Set = set, Get = function() return value end}
end

local function createTextbox(body, label, default, cb, order)
    local card = createRow(body, label, order)
    local box = mk("TextBox", {Size = UDim2.new(0,90,0,24), Position = UDim2.new(1,-100,0.5,-12),
        BackgroundColor3 = C.CARD2, Text = tostring(default), Font = FONT, TextSize = 13,
        TextColor3 = C.TEXT, ClearTextOnFocus = false, PlaceholderText = "...", ZIndex = 45}, card)
    round(box, 6)
    box.FocusLost:Connect(function() if cb then task.spawn(cb, box.Text) end end)
    return {Get = function() return box.Text end, Set = function(v) box.Text = tostring(v) end}
end

local function createCycler(body, label, options, default, cb, order)
    local card = createRow(body, label, order)
    local idx = 1
    for i, o in ipairs(options) do if o == default then idx = i end end
    local btn = mk("TextButton", {Size = UDim2.new(0,84,0,24), Position = UDim2.new(1,-94,0.5,-12),
        BackgroundColor3 = C.CARD2, Text = options[idx], Font = FONTB, TextSize = 11,
        TextColor3 = C.ACC2, AutoButtonColor = false, ZIndex = 45}, card)
    round(btn, 6)
    btn.MouseButton1Click:Connect(function()
        idx = idx + 1
        if idx > #options then idx = 1 end
        btn.Text = options[idx]
        if cb then task.spawn(cb, options[idx]) end
    end)
    return {Get = function() return options[idx] end}
end

local function createButton(body, label, cb, order)
    local b = mk("TextButton", {Size = UDim2.new(1,0,0,34), BackgroundColor3 = C.CARD,
        Text = label, Font = FONTB, TextSize = 13, TextColor3 = C.TEXT,
        AutoButtonColor = true, LayoutOrder = order or 0, ZIndex = 43}, body)
    round(b, 8)
    b.MouseButton1Click:Connect(function() task.spawn(cb) end)
    return b
end

local function createLabel(body, text, order)
    local l = mk("TextLabel", {Size = UDim2.new(1,0,0,26), BackgroundColor3 = C.CARD2,
        Text = text, Font = FONT, TextSize = 11, TextColor3 = C.SUB,
        LayoutOrder = order or 0, ZIndex = 43}, body)
    round(l, 8)
    return l
end

--============================== TABS =================================
local pageDiscord  = addTab("discord", "Discord", "◎", 1)
local pageCombat   = addTab("combat", "Combat", "⚔", 2)
local pageAbility  = addTab("ability", "Ability", "✦", 3)
local pageChanger  = addTab("changer", "Changer", "▣", 4)
local pageVisuals  = addTab("visuals", "Visuals", "◉", 5)
local pageWorld    = addTab("world", "World", "◍", 6)
local pageSettings = addTab("settings", "Settings", "⚙", 7)

-- Discord
local secDisc = createSection(pageDiscord, "Comunidad", 1)
createButton(secDisc, "Copiar link de Discord", function()
    if setclipboard then setclipboard("https://discord.gg/askvenice") end
    notify("Link copiado", C.ACC2)
end, 1)

-- Combat
local secParry = createSection(pageCombat, "Auto Parry", 1)
createToggle(secParry, "Auto Parry", Config.AutoParry, function(v) Config.AutoParry = v; saveConfig() end, 1)
createToggle(secParry, "Lobby Parry", Config.LobbyParry, function(v) Config.LobbyParry = v; saveConfig() end, 2)
createToggle(secParry, "Auto Spam", Config.AutoSpam, function(v) Config.AutoSpam = v; saveConfig() end, 3)
createToggle(secParry, "Manual Spam", Config.ManualSpam, function(v)
    Config.ManualSpam = v
    SpamBtn.Visible = v
    if not v then SpamActive = false; renderSpamBtn() end
    saveConfig()
end, 4)
createToggle(secParry, "Triggerbot", Config.Triggerbot, function(v) Config.Triggerbot = v; saveConfig() end, 5)
createSlider(secParry, "Curve", 0, 1, Config.Curve, function(v) Config.Curve = v; saveConfig() end, 6)

local secTune = createSection(pageCombat, "Tuning de Parry", 2)
createSlider(secTune, "Rango de Parry", 5, 60, Config.ParryRange, function(v) Config.ParryRange = v; saveConfig() end, 1)
createSlider(secTune, "Radio de Impacto", 1, 20, Config.HitRadius, function(v) Config.HitRadius = v; saveConfig() end, 2)
createSlider(secTune, "Tiempo de Impacto", 0.05, 1, Config.TimeToImpact, function(v) Config.TimeToImpact = v; saveConfig() end, 3)
createToggle(secTune, "Jitter aleatorio", Config.Jitter, function(v) Config.Jitter = v; saveConfig() end, 4)

-- Ability
local secAbility = createSection(pageAbility, "Ability", 1)
createToggle(secAbility, "Auto Ability", Config.AutoAbility, function(v) Config.AutoAbility = v; saveConfig() end, 1)
createToggle(secAbility, "Protection Cooldown", Config.ProtectionCD, function(v) Config.ProtectionCD = v; saveConfig() end, 2)
createToggle(secAbility, "Dribble Pre Click", Config.DribblePreClick, function(v) Config.DribblePreClick = v; saveConfig() end, 3)
createToggle(secAbility, "Full Counter", Config.FullCounter, function(v) Config.FullCounter = v; saveConfig() end, 4)

local secSnF = createSection(pageAbility, "Slashes of Fury", 2)
createToggle(secSnF, "SnF Counter", Config.SnFCounter, function(v) Config.SnFCounter = v; saveConfig() end, 1)
createSlider(secSnF, "SnF Range", 5, 50, Config.SnFRange, function(v) Config.SnFRange = v; saveConfig() end, 2)

-- Changer
local secChanger = createSection(pageChanger, "Personaje", 1)
createSlider(secChanger, "Walk Speed", 8, 200, 16, function(v)
    local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed = v end
end, 1)
createSlider(secChanger, "Jump Power", 20, 300, 50, function(v)
    local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if h then h.JumpPower = v; h.UseJumpPower = true end
end, 2)

-- Visuals
local secVis = createSection(pageVisuals, "Visuales", 1)
createToggle(secVis, "Ball Highlight", Config.BallESP, function(v) Config.BallESP = v; saveConfig() end, 1)
createToggle(secVis, "Ball Tracer", Config.BallTracer, function(v) Config.BallTracer = v; saveConfig() end, 2)
createSlider(secVis, "Field of View", 40, 120, 70, function(v)
    if Workspace.CurrentCamera then Workspace.CurrentCamera.FieldOfView = v end
end, 3)

-- World
local secWorld = createSection(pageWorld, "Servidor", 1)
createButton(secWorld, "Rejoin", function()
    TeleportService:Teleport(game.PlaceId, player)
end, 1)
createButton(secWorld, "Server Hop", function()
    local ok, servers = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(
            "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=50"))
    end)
    if ok and servers and servers.data then
        for _, s in ipairs(servers.data) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, player); return
            end
        end
    end
    notify("No se encontro servidor", Color3.fromRGB(255,120,120))
end, 2)

-- Settings
local secSys = createSection(pageSettings, "Sistema", 1)
createToggle(secSys, "Anti-Kick", Config.AntiKick, function(v) Config.AntiKick = v; saveConfig() end, 1)
createToggle(secSys, "Auto-Rejoin", Config.AutoRejoin, function(v) Config.AutoRejoin = v; saveConfig() end, 2)
local sysInfo = createLabel(secSys, "Bypass BAC: ...", 3)
task.spawn(function()
    task.wait(2)
    sysInfo.Text = string.format("BAC: %s | Anti-Kick: %s | Rejoin: %s",
        BAC_OK and "OK" or "no", ANTI_KICK_OK and "OK" or "no", Config.AutoRejoin and "on" or "off")
end)

local secAct = createSection(pageSettings, "Modo de accion", 2)
createCycler(secAct, "Modo de Parry", {"Click", "Key"}, Config.ParryMode, function(v) Config.ParryMode = v; saveConfig() end, 1)
createCycler(secAct, "Modo de Spam", {"Click", "Key"}, Config.SpamMode, function(v) Config.SpamMode = v; saveConfig() end, 2)

local secKeys = createSection(pageSettings, "Teclas", 3)
createTextbox(secKeys, "Tecla de Parry", Config.ParryKey, function(v) Config.ParryKey = v; saveConfig() end, 1)
createTextbox(secKeys, "Tecla de Spam", Config.SpamKey, function(v) Config.SpamKey = v; saveConfig() end, 2)
createTextbox(secKeys, "Tecla de Ability", Config.AbilityKey, function(v) Config.AbilityKey = v; saveConfig() end, 3)
createTextbox(secKeys, "Tecla Full Counter", Config.FullCounterKey, function(v) Config.FullCounterKey = v; saveConfig() end, 4)
createTextbox(secKeys, "Tecla Ocultar UI", Config.UIToggleKey, function(v) Config.UIToggleKey = v; saveConfig() end, 5)

local secDet = createSection(pageSettings, "Deteccion", 4)
createTextbox(secDet, "Nombre de la bola", Config.BallName, function(v) Config.BallName = v; saveConfig() end, 1)
createSlider(secDet, "Delay de Spam", 0.01, 0.5, Config.SpamDelay, function(v) Config.SpamDelay = v; saveConfig() end, 2)
createSlider(secDet, "Delay de Parry", 0.01, 0.6, Config.ParryDelay, function(v) Config.ParryDelay = v; saveConfig() end, 3)
createButton(secDet, "Guardar configuracion", function() saveConfig(); notify("Config guardada", C.ACC2) end, 4)

--============================= ENGINE ================================
local lastParry, spamAccum = 0, 0
local accum = {}

local function fireClick()
    if not READY then return end
    local cam = Workspace.CurrentCamera
    if not cam then return end
    local vs = cam.ViewportSize
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(vs.X/2 + rand(-6,6), vs.Y/2 + rand(-6,6), 0, true, game, 1)
        VirtualInputManager:SendMouseButtonEvent(vs.X/2 + rand(-6,6), vs.Y/2 + rand(-6,6), 0, false, game, 1)
    end)
end

local DIGITS = {["1"]="One",["2"]="Two",["3"]="Three",["4"]="Four",["5"]="Five",
                ["6"]="Six",["7"]="Seven",["8"]="Eight",["9"]="Nine",["0"]="Zero"}
local function toKeyCode(s)
    s = tostring(s or ""):upper()
    if DIGITS[s] then s = DIGITS[s] end
    local ok, kc = pcall(function() return Enum.KeyCode[s] end)
    if ok and kc then return kc end
end

local function pressKey(key)
    local kc = toKeyCode(key)
    if not kc then return end
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, kc, false, game)
        task.wait(0.02)
        VirtualInputManager:SendKeyEvent(false, kc, false, game)
    end)
end

local function doAction(mode, key)
    if mode == "Key" then pressKey(key) else fireClick() end
end

local ballCache, ballClock = nil, 0
local function findBall()
    if ballCache and ballCache.Parent then return ballCache end
    local wanted = string.lower(Config.BallName or "ball")
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d:IsA("BasePart") and not (player.Character and d:IsDescendantOf(player.Character)) then
            local n = string.lower(d.Name)
            if n:find(wanted, 1, true) or n:find("ball", 1, true) or n:find("pelota", 1, true) then
                ballCache = d
                return d
            end
        end
    end
end

local function rootPart()
    local c = player.Character
    if not c then return nil end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return nil end
    return c:FindFirstChild("HumanoidRootPart")
end

-- Devuelve dist, tti, perp  (nil si la bola se aleja)
local function incomingInfo(ball, root)
    local rel = root.Position - ball.Position
    local dist = rel.Magnitude
    local v = ball.AssemblyLinearVelocity
    local speed = v.Magnitude
    if speed < 1.5 then return dist, 0, 0 end
    local unit = v.Unit
    local along = rel:Dot(unit)
    if along <= 0 then return nil end
    local perp = (rel - unit * along).Magnitude
    return dist, along / speed, perp
end

local function tryParry(lobby)
    local root = rootPart()
    if not root then return end
    local ball = findBall()
    if not ball then return end
    local dist, tti, perp = incomingInfo(ball, root)
    if not dist then return end

    local range  = (lobby and Config.ParryRange * 2.5 or Config.ParryRange)
    local window = Config.TimeToImpact * (0.6 + Config.Curve)
    if Config.Jitter then range = range + rand(-3, 3) end
    if dist > range then return end
    if tti > 0 and perp > Config.HitRadius then return end
    if tti > window then return end

    local cd = Config.ParryDelay
    if Config.Jitter then cd = cd + rand(-0.03, 0.06) end
    if (tick() - lastParry) < cd then return end
    lastParry = tick()
    doAction(Config.ParryMode, Config.ParryKey)
end

local function ballNear(radius)
    local root = rootPart()
    local ball = findBall()
    if not root or not ball then return false end
    return (root.Position - ball.Position).Magnitude <= (radius or 25)
end

local function tickKey(id, dt, interval, key, cond)
    accum[id] = (accum[id] or 0) + dt
    if accum[id] < interval then return end
    accum[id] = 0
    if cond() then doAction(Config.SpamMode, key) end
end

local ballHighlight, tracer
local function updateESP()
    local ball = findBall()
    if Config.BallESP and ball then
        if not ballHighlight or ballHighlight.Parent ~= ball then
            if ballHighlight then ballHighlight:Destroy() end
            ballHighlight = mk("Highlight", {FillColor = Color3.fromRGB(255,200,80),
                OutlineColor = C.WHITE, FillTransparency = 0.65, OutlineTransparency = 0,
                DepthMode = Enum.HighlightDepthMode.AlwaysOnTop}, ball)
        end
    elseif ballHighlight then
        ballHighlight:Destroy(); ballHighlight = nil
    end

    if Config.BallTracer and ball then
        if not tracer or not tracer.Parent then
            tracer = mk("Part", {Name = "DyxTracer", Anchored = true, CanCollide = false,
                CastShadow = false, Material = Enum.Material.Neon,
                Color = Color3.fromRGB(255,200,80), Size = Vector3.new(0.1,0.1,1)}, Workspace)
        end
        local root = rootPart()
        if root then
            local a, b = root.Position, ball.Position
            tracer.Size = Vector3.new(0.1, 0.1, (a - b).Magnitude)
            tracer.CFrame = CFrame.lookAt((a + b) / 2, b)
        end
    elseif tracer then
        tracer:Destroy(); tracer = nil
    end
end

RunService.Heartbeat:Connect(function(dt)
    ballClock = ballClock + dt
    if ballClock >= 0.5 then ballClock = 0; ballCache = nil end

    if Config.AutoParry then tryParry(false) end
    if Config.LobbyParry then tryParry(true) end

    if SpamActive or Config.AutoSpam then
        spamAccum = spamAccum + dt
        if spamAccum >= Config.SpamDelay then
            spamAccum = 0
            doAction(Config.SpamMode, Config.SpamKey)
        end
    end

    if Config.Triggerbot then
        tickKey("trig", dt, Config.AbilityDelay, Config.AbilityKey, function() return ballNear(30) end)
    end
    if Config.AutoAbility then
        tickKey("abil", dt, Config.AbilityDelay, Config.AbilityKey, function() return ballNear(28) end)
    end
    if Config.ProtectionCD then
        tickKey("prot", dt, 0.2, Config.ProtectionKey, function() return ballNear(20) end)
    end
    if Config.FullCounter then
        tickKey("full", dt, 0.15, Config.FullCounterKey, function()
            local root = rootPart(); local ball = findBall()
            if not root or not ball then return false end
            local dist, tti, perp = incomingInfo(ball, root)
            return dist ~= nil and perp <= 6 and tti <= 0.4
        end)
    end
    if Config.SnFCounter then
        tickKey("snf", dt, 0.15, Config.SnFKey, function() return ballNear(Config.SnFRange) end)
    end
    if Config.DribblePreClick then
        tickKey("drib", dt, 0.08, Config.SpamKey, function() return ballNear(10) end)
    end

    updateESP()
end)

--=========================== INTERACCION =============================
OpenBtn.MouseButton1Click:Connect(function() end)
makeDraggable(OpenBtn, function()
    if not authenticated then
        login.Visible = not login.Visible
        return
    end
    Main.Visible = not Main.Visible
end)

makeDraggable(SpamBtn, function()
    if not authenticated then login.Visible = true; return end
    SpamActive = not SpamActive
    renderSpamBtn()
    statusLbl.Text = "Spam manual " .. (SpamActive and "ON" or "OFF")
end)

hideLbl.MouseButton1Click:Connect(function() Main.Visible = false end)
hdrBtn(-40, "✕", function() Main.Visible = false end, C.RED)

enter.MouseButton1Click:Connect(function()
    if input.Text == PASSWORD then
        authenticated = true
        login.Visible = false
        Main.Visible = true
        message.Text = ""
        notify("Bienvenido", C.ACC2)
    else
        message.Text = "Contrasena incorrecta"
        input.Text = ""
    end
end)
input.FocusLost:Connect(function(e) if e then enter:Activate() end end)

UserInputService.InputBegan:Connect(function(inputObj, processed)
    if processed then return end
    local kc = toKeyCode(Config.UIToggleKey)
    if kc and inputObj.KeyCode == kc and authenticated then
        Main.Visible = not Main.Visible
    end
end)

-- Estado inicial
for _, id in ipairs({"combat","ability","changer","visuals","world","settings","discord"}) do
    local t = TabButtons[id]
    if t then
        local on = (id == "combat")
        t.page.Visible = on
        t.btn.BackgroundTransparency = on and 0 or 1
        t.ic.TextColor3 = on and C.ACC2 or C.SUB
        t.tx.TextColor3 = on and C.TEXT or C.SUB
        t.bar.Visible = on
    end
end
SpamBtn.Visible = Config.ManualSpam
renderSpamBtn()

print("[BETS x DYX] Script unificado cargado. Contrasena: " .. PASSWORD)
