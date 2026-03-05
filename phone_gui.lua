-- phone_gui.lua  (Part 1 of 4)
-- Roblox LocalScript — place inside a ScreenGui (e.g. PlayerGui)

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local TweenService  = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player  = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ─── Constants ────────────────────────────────────────────────────────────────
local PHONE_W       = 220
local PHONE_H       = 440
local PHONE_RADIUS  = 38   -- outer shell corner radius
local INNER_RADIUS  = 34   -- inner content corner radius (fits inside shell)
local STATUS_H      = 28
local WIFI_NAME     = "Hylton Hotel Guest WiFi"

-- ─── Colour palette ───────────────────────────────────────────────────────────
local C = {
    bg          = Color3.fromRGB(18,  18,  18),
    surface     = Color3.fromRGB(28,  28,  30),
    surface2    = Color3.fromRGB(44,  44,  46),
    accent      = Color3.fromRGB(10, 132, 255),
    green       = Color3.fromRGB(52, 199,  89),
    orange      = Color3.fromRGB(255,159,  10),
    red         = Color3.fromRGB(255,  59,  48),
    text        = Color3.fromRGB(255, 255, 255),
    subtext     = Color3.fromRGB(174, 174, 178),
    separator   = Color3.fromRGB(56,  56,  58),
    lockBg      = Color3.fromRGB( 30,  30,  50),
    homeBg      = Color3.fromRGB( 15,  20,  40),
    cardBg      = Color3.fromRGB( 38,  38,  40),
    white       = Color3.new(1,1,1),
    black       = Color3.new(0,0,0),
    transparent = Color3.new(0,0,0),
}

-- ─── State ────────────────────────────────────────────────────────────────────
local currentScreen = "lock"   -- lock | home | app
local currentApp    = nil

local settingsState = {
    notifications = true,
    wifi          = true,
    wifiName      = WIFI_NAME,
    darkMode      = true,
    doNotDisturb  = false,
    brightness    = 0.8,
}

-- Clock / Timer / Alarm / Stopwatch state
local clockState = {
    alarms   = {},         -- { hour, minute, label, enabled }
    timers   = {},         -- { total, remaining, running, label }
    stopwatch = { running = false, elapsed = 0, lapStart = 0 },
}

-- Notes state
local notesState = {
    notes = {
        { title = "Welcome", body = "Tap + to add a note.", date = "Today" },
    },
}

-- ─── ScreenGui root ───────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name            = "PhoneGui"
screenGui.ResetOnSpawn    = false
screenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
screenGui.Parent          = playerGui

-- ─────────────────────────────────────────────────────────────────────────────
-- HELPER FUNCTIONS
-- ─────────────────────────────────────────────────────────────────────────────

--- Apply UICorner to a GuiObject.
local function corner(obj, radius)
    local r = radius or INNER_RADIUS
    local uc = Instance.new("UICorner")
    uc.CornerRadius = UDim.new(0, r)
    uc.Parent = obj
    return uc
end

--- Apply UIStroke to a GuiObject.
local function stroke(obj, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color        = color or C.separator
    s.Thickness    = thickness or 1
    s.Transparency = transparency or 0
    s.Parent       = obj
    return s
end

--- Create a Frame with sensible defaults.
local function mkFrame(parent, props)
    local f = Instance.new("Frame")
    f.BackgroundColor3 = props.color  or C.surface
    f.Size             = props.size   or UDim2.new(1,0,1,0)
    f.Position         = props.pos    or UDim2.new(0,0,0,0)
    f.ZIndex           = props.z      or 1
    f.BorderSizePixel  = 0
    if props.clip ~= nil then f.ClipsDescendants = props.clip end
    f.Parent           = parent
    if props.radius ~= false then
        corner(f, props.radius)
    end
    return f
end

--- Create a TextLabel with sensible defaults.
local function mkLabel(parent, props)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text                   = props.text  or ""
    l.TextColor3             = props.color or C.text
    l.Font                   = props.font  or Enum.Font.GothamSemiBold
    l.TextSize               = props.size  or 14
    l.Size                   = props.sz    or UDim2.new(1,0,0,20)
    l.Position               = props.pos   or UDim2.new(0,0,0,0)
    l.ZIndex                 = props.z     or 2
    l.TextXAlignment         = props.xalign or Enum.TextXAlignment.Left
    l.TextYAlignment         = props.yalign or Enum.TextYAlignment.Center
    l.TextWrapped            = props.wrap  or false
    if props.clip ~= nil then l.ClipsDescendants = props.clip end
    l.Parent                 = parent
    return l
end

--- Create a TextButton with sensible defaults.
local function mkBtn(parent, props)
    local b = Instance.new("TextButton")
    b.BackgroundColor3       = props.color or C.surface2
    b.Text                   = props.text  or ""
    b.TextColor3             = props.tcol  or C.text
    b.Font                   = props.font  or Enum.Font.GothamSemiBold
    b.TextSize               = props.size  or 14
    b.Size                   = props.sz    or UDim2.new(1,0,0,44)
    b.Position               = props.pos   or UDim2.new(0,0,0,0)
    b.ZIndex                 = props.z     or 2
    b.AutoButtonColor        = false
    b.BorderSizePixel        = 0
    b.Parent                 = parent
    if props.radius ~= false then
        corner(b, props.radius or 12)
    end
    return b
end

--- Create a ScrollingFrame with sensible defaults.
local function mkScroll(parent, props)
    local s = Instance.new("ScrollingFrame")
    s.BackgroundColor3      = props.color or C.transparent
    s.BackgroundTransparency= props.bgTrans or 1
    s.Size                  = props.size  or UDim2.new(1,0,1,0)
    s.Position              = props.pos   or UDim2.new(0,0,0,0)
    s.ZIndex                = props.z     or 2
    s.BorderSizePixel       = 0
    s.ScrollBarThickness    = props.bar   or 0
    s.CanvasSize            = props.canvas or UDim2.new(0,0,2,0)
    s.ScrollingDirection    = props.dir   or Enum.ScrollingDirection.Y
    s.ClipsDescendants      = true
    s.Parent                = parent
    if props.radius ~= false then
        corner(s, props.radius or INNER_RADIUS)
    end
    return s
end

--- Tween a GuiObject's property.
local function tween(obj, info, props)
    TweenService:Create(obj, info, props):Play()
end

-- ─────────────────────────────────────────────────────────────────────────────
-- ROOM AVAILABILITY  (client-side helpers — mirrors room_manager.lua)
-- ─────────────────────────────────────────────────────────────────────────────

--- Find workspace.CheckIn.Doors using WaitForChild so replication is handled.
local function findDoorsFolder()
    local ws = game:GetService("Workspace")
    local checkIn = ws:WaitForChild("CheckIn", 5)
    if not checkIn then return nil end
    local doors = checkIn:WaitForChild("Doors", 5)
    return doors
end

--- Returns true when a room folder is currently available.
local function isRoomAvailable(roomFolder)
    local avail = roomFolder:FindFirstChild("Available")
    return avail and avail:IsA("BoolValue") and avail.Value == true
end

--- Returns the integer type index of a room folder.
local function getRoomType(roomFolder)
    local t = roomFolder:FindFirstChild("Type")
    return t and t:IsA("IntValue") and t.Value or 0
end

--- Returns the display room number of a room folder.
local function getRoomNumber(roomFolder)
    local n = roomFolder:FindFirstChild("Number")
    return n and n:IsA("IntValue") and n.Value or 0
end

--- Returns the room folder currently assigned to this player (or nil).
local function findPlayerRoom(doorsFolder)
    if not doorsFolder then return nil end
    local uid = player.UserId
    for _, rf in ipairs(doorsFolder:GetChildren()) do
        local owner = rf:FindFirstChild("RoomOwner")
        if owner and owner:IsA("IntValue") and owner.Value == uid then
            return rf
        end
    end
    return nil
end

--- Returns a list of { roomFolder, typeIndex, roomNumber } for available rooms.
--- Uses a brief retry so the folders have time to replicate.
local function getAvailableRooms()
    local doors = findDoorsFolder()
    if not doors then return {} end

    -- Small wait if the folder is still empty (just replicated)
    local attempts = 0
    while #doors:GetChildren() == 0 and attempts < 15 do
        task.wait(0.2)
        attempts = attempts + 1
    end

    local result = {}
    for _, rf in ipairs(doors:GetChildren()) do
        if isRoomAvailable(rf) then
            table.insert(result, {
                folder = rf,
                typeIndex  = getRoomType(rf),
                roomNumber = getRoomNumber(rf),
            })
        end
    end
    return result
end

-- ─────────────────────────────────────────────────────────────────────────────
-- LIVE ACTIVITY HELPERS
-- ─────────────────────────────────────────────────────────────────────────────

local function getActiveTimerText()
    for _, t in ipairs(clockState.timers) do
        if t.running and t.remaining > 0 then
            local s = math.floor(t.remaining)
            local m = math.floor(s / 60)
            local h = math.floor(m / 60)
            m = m % 60
            s = s % 60
            if h > 0 then
                return string.format("Timer  %d:%02d:%02d", h, m, s)
            else
                return string.format("Timer  %d:%02d", m, s)
            end
        end
    end
    return nil
end

local function getActiveAlarmText()
    -- Alarms fire at a specific time — show upcoming alarm within 1 min
    local now = os.date("*t")
    for _, a in ipairs(clockState.alarms) do
        if a.enabled then
            local diff = (a.hour * 60 + a.minute) - (now.hour * 60 + now.min)
            if diff >= 0 and diff <= 1 then
                return string.format("Alarm  %02d:%02d", a.hour, a.minute)
            end
        end
    end
    return nil
end

local function getStopwatchText()
    local sw = clockState.stopwatch
    if sw.running then
        local e = sw.elapsed + (tick() - sw.lapStart)
        local m = math.floor(e / 60)
        local s = math.floor(e % 60)
        local cs = math.floor((e % 1) * 100)
        return string.format("Stopwatch  %02d:%02d.%02d", m, s, cs)
    end
    return nil
end

--- Returns the best live-activity text, or nil.
local function getLiveActivityText()
    if not settingsState.notifications then return nil end
    return getActiveTimerText() or getActiveAlarmText() or getStopwatchText()
end

-- ─────────────────────────────────────────────────────────────────────────────
-- PHONE SHELL
-- ─────────────────────────────────────────────────────────────────────────────

local phoneHolder = Instance.new("Frame")
phoneHolder.Name               = "PhoneHolder"
phoneHolder.AnchorPoint        = Vector2.new(0.5, 0.5)
phoneHolder.Size               = UDim2.new(0, PHONE_W, 0, PHONE_H)
phoneHolder.Position           = UDim2.new(0.5, 0, 0.5, 0)
phoneHolder.BackgroundColor3   = C.black
phoneHolder.BorderSizePixel    = 0
phoneHolder.ZIndex             = 1
phoneHolder.Parent             = screenGui
corner(phoneHolder, PHONE_RADIUS)

-- Subtle outer glow / shadow
local shellStroke = stroke(phoneHolder, Color3.fromRGB(60,60,70), 2, 0.3)

-- Floating background decorative shapes (persistent, behind everything)
local function addFloatingShape(parent, color, size, pos, zidx)
    local s = Instance.new("Frame")
    s.BackgroundColor3 = color
    s.Size             = size
    s.Position         = pos
    s.ZIndex           = zidx or 0
    s.BorderSizePixel  = 0
    s.ClipsDescendants = false
    s.Parent           = parent
    corner(s, 999)
    return s
end

addFloatingShape(phoneHolder,
    Color3.fromRGB(0,80,160), UDim2.new(0,120,0,120),
    UDim2.new(0,-30,0,-20), 1)
addFloatingShape(phoneHolder,
    Color3.fromRGB(80,0,120), UDim2.new(0,100,0,100),
    UDim2.new(1,-70,1,-80), 1)

-- ─── Clip mask so child content never bleeds past rounded corners ─────────────
local clipFrame = mkFrame(phoneHolder, {
    color  = C.transparent,
    size   = UDim2.new(1,0,1,0),
    pos    = UDim2.new(0,0,0,0),
    z      = 2,
    clip   = true,
    radius = INNER_RADIUS,
})
clipFrame.BackgroundTransparency = 1

-- ─────────────────────────────────────────────────────────────────────────────
-- STATUS BAR
-- ─────────────────────────────────────────────────────────────────────────────

local statusBar = mkFrame(clipFrame, {
    color  = C.transparent,
    size   = UDim2.new(1,0,0,STATUS_H),
    pos    = UDim2.new(0,0,0,0),
    z      = 10,
    radius = false,
})
statusBar.BackgroundTransparency = 0.6
statusBar.BackgroundColor3       = C.black

-- Time label (left side)
local statusTime = mkLabel(statusBar, {
    text   = "9:41",
    color  = C.white,
    font   = Enum.Font.GothamBold,
    size   = 13,
    sz     = UDim2.new(0,60,1,0),
    pos    = UDim2.new(0,12,0,0),
    z      = 11,
    xalign = Enum.TextXAlignment.Left,
})

-- WiFi label (right side, before battery)
local wifiLabel = mkLabel(statusBar, {
    text   = "WiFi",
    color  = C.white,
    font   = Enum.Font.Gotham,
    size   = 11,
    sz     = UDim2.new(0,28,1,0),
    pos    = UDim2.new(1,-72,0,0),
    z      = 11,
    xalign = Enum.TextXAlignment.Right,
})

-- ── Apple-style battery icon ─────────────────────────────────────────────────
-- Body: outlined rectangle ~24×11 px
local battBody = mkFrame(statusBar, {
    color  = C.transparent,
    size   = UDim2.new(0,24,0,11),
    pos    = UDim2.new(1,-40,0.5,-5),
    z      = 11,
    radius = 3,
})
battBody.BackgroundTransparency = 1
stroke(battBody, C.white, 1.5, 0.15)

-- Fill: solid white ~85% full (~18×7 px), inset 2 px
local battFill = mkFrame(battBody, {
    color  = C.white,
    size   = UDim2.new(0,18,0,7),
    pos    = UDim2.new(0,2,0.5,-3),
    z      = 12,
    radius = 2,
})

-- Tip (positive terminal): small rectangle on right side ~2×5 px
local battTip = mkFrame(statusBar, {
    color  = C.white,
    size   = UDim2.new(0,2,0,5),
    pos    = UDim2.new(1,-16,0.5,-2),
    z      = 11,
    radius = 1,
})
battTip.BackgroundTransparency = 0.3

-- ─────────────────────────────────────────────────────────────────────────────
-- SCREEN MANAGEMENT
-- ─────────────────────────────────────────────────────────────────────────────

local screens = {}   -- name -> Frame

local function showScreen(name)
    for n, s in pairs(screens) do
        s.Visible = (n == name)
    end
    currentScreen = name
end

-- ─────────────────────────────────────────────────────────────────────────────
-- LOCK SCREEN
-- ─────────────────────────────────────────────────────────────────────────────

local function buildLockScreen()
    local lock = mkFrame(clipFrame, {
        color  = C.lockBg,
        size   = UDim2.new(1,0,1,0),
        pos    = UDim2.new(0,0,0,0),
        z      = 3,
        radius = INNER_RADIUS,
    })
    lock.Name = "LockScreen"

    -- Blurred overlay gradient
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(20,30,80)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(10,10,30)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(5,5,20)),
    }
    grad.Rotation = 135
    grad.Parent   = lock

    -- Lock time
    local lockTime = mkLabel(lock, {
        text   = "9:41",
        color  = C.white,
        font   = Enum.Font.GothamBold,
        size   = 52,
        sz     = UDim2.new(1,0,0,60),
        pos    = UDim2.new(0,0,0,70),
        z      = 4,
        xalign = Enum.TextXAlignment.Center,
    })

    -- Lock date
    local lockDate = mkLabel(lock, {
        text   = os.date("%A, %B %d"),
        color  = Color3.fromRGB(210,210,220),
        font   = Enum.Font.Gotham,
        size   = 16,
        sz     = UDim2.new(1,0,0,22),
        pos    = UDim2.new(0,0,0,130),
        z      = 4,
        xalign = Enum.TextXAlignment.Center,
    })

    -- Notification stack on lock screen
    local notifStack = mkFrame(lock, {
        color  = Color3.fromRGB(30,30,50),
        size   = UDim2.new(1,-24,0,60),
        pos    = UDim2.new(0,12,0,175),
        z      = 4,
        radius = 14,
    })
    notifStack.BackgroundTransparency = 0.35
    local notifText = mkLabel(notifStack, {
        text   = "🏨  Hylton Hotel\nWelcome! Your room is ready.",
        color  = C.white,
        font   = Enum.Font.Gotham,
        size   = 12,
        sz     = UDim2.new(1,-16,1,0),
        pos    = UDim2.new(0,8,0,0),
        z      = 5,
        xalign = Enum.TextXAlignment.Left,
        wrap   = true,
    })

    -- Swipe-up hint
    local swipeHint = mkLabel(lock, {
        text   = "Swipe up to unlock",
        color  = Color3.fromRGB(180,180,200),
        font   = Enum.Font.Gotham,
        size   = 13,
        sz     = UDim2.new(1,0,0,20),
        pos    = UDim2.new(0,0,1,-50),
        z      = 4,
        xalign = Enum.TextXAlignment.Center,
    })

    -- Tap anywhere to unlock
    local unlockBtn = Instance.new("TextButton")
    unlockBtn.Size               = UDim2.new(1,0,1,0)
    unlockBtn.BackgroundTransparency = 1
    unlockBtn.Text               = ""
    unlockBtn.ZIndex             = 6
    unlockBtn.Parent             = lock
    unlockBtn.MouseButton1Click:Connect(function()
        showScreen("home")
    end)

    -- Update clock every second
    RunService.Heartbeat:Connect(function()
        lockTime.Text = os.date("%H:%M")
        lockDate.Text = os.date("%A, %B %d")
    end)

    return lock
end

-- ─────────────────────────────────────────────────────────────────────────────
-- HOME SCREEN
-- ─────────────────────────────────────────────────────────────────────────────

local appScreens = {}       -- appName -> Frame (lazy-built)
local homeGridOffset = 0    -- shifted down when live-activity banner shows

local function buildHome()
    local home = mkFrame(clipFrame, {
        color  = C.homeBg,
        size   = UDim2.new(1,0,1,0),
        pos    = UDim2.new(0,0,0,0),
        z      = 3,
        radius = INNER_RADIUS,
    })
    home.Name = "HomeScreen"

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(10,20,60)),
        ColorSequenceKeypoint.new(0.6, Color3.fromRGB(5,10,35)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,5,20)),
    }
    grad.Rotation = 160
    grad.Parent   = home

    -- Home clock
    local homeClock = mkLabel(home, {
        text   = "9:41",
        color  = C.white,
        font   = Enum.Font.GothamBold,
        size   = 36,
        sz     = UDim2.new(1,0,0,44),
        pos    = UDim2.new(0,0,0,STATUS_H + 4),
        z      = 4,
        xalign = Enum.TextXAlignment.Center,
    })

    local homeDate = mkLabel(home, {
        text   = os.date("%A, %B %d"),
        color  = C.subtext,
        font   = Enum.Font.Gotham,
        size   = 13,
        sz     = UDim2.new(1,0,0,18),
        pos    = UDim2.new(0,0,0,STATUS_H + 50),
        z      = 4,
        xalign = Enum.TextXAlignment.Center,
    })

    -- ── Live Activity banner ────────────────────────────────────────────────
    local bannerY  = STATUS_H + 74
    local banner   = mkFrame(home, {
        color  = Color3.fromRGB(30,30,35),
        size   = UDim2.new(1,-24,0,34),
        pos    = UDim2.new(0,12,0,bannerY),
        z      = 5,
        radius = 16,
    })
    banner.BackgroundTransparency = 0.1
    banner.Visible = false

    -- Orange pulsing dot
    local dot = mkFrame(banner, {
        color  = C.orange,
        size   = UDim2.new(0,8,0,8),
        pos    = UDim2.new(0,10,0.5,-4),
        z      = 6,
        radius = 999,
    })

    local bannerText = mkLabel(banner, {
        text   = "",
        color  = C.white,
        font   = Enum.Font.GothamSemiBold,
        size   = 13,
        sz     = UDim2.new(1,-30,1,0),
        pos    = UDim2.new(0,26,0,0),
        z      = 6,
        xalign = Enum.TextXAlignment.Left,
    })

    -- Dot pulse animation
    local pulsing = false
    local function startDotPulse()
        if pulsing then return end
        pulsing = true
        local info = TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
        tween(dot, info, { BackgroundTransparency = 0.55 })
    end
    local function stopDotPulse()
        pulsing = false
        dot.BackgroundTransparency = 0
    end

    -- ── App grid ────────────────────────────────────────────────────────────
    local GRID_TOP_BASE = STATUS_H + 80
    local gridTop = GRID_TOP_BASE

    local gridFrame = mkFrame(home, {
        color  = C.transparent,
        size   = UDim2.new(1,-16,0,300),
        pos    = UDim2.new(0,8,0,gridTop),
        z      = 4,
        radius = false,
    })
    gridFrame.BackgroundTransparency = 1

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize     = UDim2.new(0,50,0,64)
    gridLayout.CellPadding  = UDim2.new(0,8,0,8)
    gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    gridLayout.Parent       = gridFrame

    local apps = {
        { name = "inbox",    icon = "📬", label = "Inbox",    color = Color3.fromRGB(0,120,215)  },
        { name = "hylton",   icon = "🏨", label = "Hotel",    color = Color3.fromRGB(180,110,0)  },
        { name = "settings", icon = "⚙️", label = "Settings", color = Color3.fromRGB(80,80,90)   },
        { name = "calendar", icon = "📅", label = "Calendar", color = Color3.fromRGB(200,50,50)  },
        { name = "notes",    icon = "📝", label = "Notes",    color = Color3.fromRGB(210,175,0)  },
        { name = "clock",    icon = "⏱️", label = "Clock",    color = Color3.fromRGB(20,20,25)   },
    }

    for _, app in ipairs(apps) do
        local cell = Instance.new("Frame")
        cell.BackgroundTransparency = 1
        cell.ZIndex = 4
        cell.Parent = gridFrame

        local icon = mkBtn(cell, {
            color  = app.color,
            text   = app.icon,
            size   = UDim2.new(0,50,0,50),
            pos    = UDim2.new(0,0,0,0),
            z      = 5,
            radius = 12,
            font   = Enum.Font.GothamBold,
            tcol   = C.white,
            sz     = UDim2.new(0,50,0,50),
        })
        icon.TextSize = 24

        local lbl = mkLabel(cell, {
            text   = app.label,
            color  = C.white,
            font   = Enum.Font.Gotham,
            size   = 10,
            sz     = UDim2.new(0,50,0,14),
            pos    = UDim2.new(0,0,0,52),
            z      = 5,
            xalign = Enum.TextXAlignment.Center,
        })

        local appName = app.name
        icon.MouseButton1Click:Connect(function()
            showScreen("app")
            currentApp = appName
            for n, s in pairs(appScreens) do
                s.Visible = (n == appName)
            end
        end)
    end

    -- ── Heartbeat: clock + live activity ────────────────────────────────────
    RunService.Heartbeat:Connect(function()
        homeClock.Text = os.date("%H:%M")
        homeDate.Text  = os.date("%A, %B %d")

        local liveText = getLiveActivityText()
        if liveText then
            banner.Visible  = true
            bannerText.Text = liveText
            startDotPulse()
            -- shift grid down to make room
            gridFrame.Position = UDim2.new(0,8,0,GRID_TOP_BASE + 40)
        else
            banner.Visible  = false
            stopDotPulse()
            gridFrame.Position = UDim2.new(0,8,0,GRID_TOP_BASE)
        end
    end)

    return home
end

-- ─────────────────────────────────────────────────────────────────────────────
-- HOME BAR (iOS-style swipe handle at bottom)
-- ─────────────────────────────────────────────────────────────────────────────

local function buildHomeBar(appContainer)
    local bar = mkFrame(clipFrame, {
        color  = C.transparent,
        size   = UDim2.new(1,0,0,32),
        pos    = UDim2.new(0,0,1,-32),
        z      = 20,
        radius = false,
    })
    bar.BackgroundTransparency = 1

    local handle = mkFrame(bar, {
        color  = Color3.fromRGB(200,200,210),
        size   = UDim2.new(0,80,0,4),
        pos    = UDim2.new(0.5,-40,0.5,-2),
        z      = 21,
        radius = 999,
    })
    handle.BackgroundTransparency = 0.35

    -- Hover: handle grows slightly
    local barBtn = Instance.new("TextButton")
    barBtn.Size               = UDim2.new(1,0,1,0)
    barBtn.BackgroundTransparency = 1
    barBtn.Text               = ""
    barBtn.ZIndex             = 22
    barBtn.Parent             = bar

    barBtn.MouseEnter:Connect(function()
        tween(handle,
            TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Size = UDim2.new(0,92,0,5), BackgroundTransparency = 0.1 }
        )
    end)
    barBtn.MouseLeave:Connect(function()
        tween(handle,
            TweenInfo.new(0.25, Enum.EasingStyle.Spring, Enum.EasingDirection.Out),
            { Size = UDim2.new(0,80,0,4), BackgroundTransparency = 0.35 }
        )
    end)

    barBtn.MouseButton1Click:Connect(function()
        if currentScreen ~= "app" then return end

        -- Light up handle
        tween(handle,
            TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { BackgroundTransparency = 0, BackgroundColor3 = C.white }
        )

        -- Scale & slide app container
        if appContainer then
            tween(appContainer,
                TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                { Size     = UDim2.new(0.85,0,0.85,0),
                  Position = UDim2.new(0.075,0,0.075,0),
                  BackgroundTransparency = 0.15 }
            )
        end

        task.delay(0.25, function()
            -- Return container to normal
            if appContainer then
                appContainer.Size     = UDim2.new(1,0,1,0)
                appContainer.Position = UDim2.new(0,0,0,0)
                appContainer.BackgroundTransparency = 0
            end
            -- Handle spring back
            tween(handle,
                TweenInfo.new(0.35, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
                { BackgroundTransparency = 0.35,
                  BackgroundColor3 = Color3.fromRGB(200,200,210) }
            )
            showScreen("home")
        end)
    end)

    return bar
end

-- ─────────────────────────────────────────────────────────────────────────────
-- APP SCREENS CONTAINER
-- ─────────────────────────────────────────────────────────────────────────────

local appContainer = mkFrame(clipFrame, {
    color  = C.bg,
    size   = UDim2.new(1,0,1,0),
    pos    = UDim2.new(0,0,0,0),
    z      = 3,
    radius = INNER_RADIUS,
    clip   = true,
})
appContainer.Name = "AppContainer"

-- ─────────────────────────────────────────────────────────────────────────────
-- INBOX APP
-- ─────────────────────────────────────────────────────────────────────────────

local function buildInbox()
    local bg = mkFrame(appContainer, {
        color  = C.bg,
        size   = UDim2.new(1,0,1,0),
        pos    = UDim2.new(0,0,0,0),
        z      = 4,
        radius = INNER_RADIUS,
    })
    bg.Name = "inbox"

    local header = mkLabel(bg, {
        text   = "Inbox",
        color  = C.white,
        font   = Enum.Font.GothamBold,
        size   = 20,
        sz     = UDim2.new(1,0,0,44),
        pos    = UDim2.new(0,0,0,STATUS_H),
        z      = 5,
        xalign = Enum.TextXAlignment.Center,
    })

    local scroll = mkScroll(bg, {
        size   = UDim2.new(1,0,1,-(STATUS_H+44+32)),
        pos    = UDim2.new(0,0,0,STATUS_H+44),
        z      = 5,
        bar    = 0,
        canvas = UDim2.new(0,0,0,300),
        radius = INNER_RADIUS,
    })

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding   = UDim.new(0,1)
    layout.Parent    = scroll

    local messages = {
        { from = "Hylton Hotel",   subject = "Welcome to your stay!",      time = "9:00 AM"  },
        { from = "Concierge",      subject = "Your booking confirmation",   time = "8:45 AM"  },
        { from = "Room Service",   subject = "Your order is on the way",    time = "Yesterday"},
        { from = "Hylton Hotel",   subject = "Weekend specials available",  time = "Mon"      },
    }

    for i, msg in ipairs(messages) do
        local row = mkFrame(scroll, {
            color  = C.surface,
            size   = UDim2.new(1,0,0,64),
            z      = 6,
            radius = 10,
        })
        row.LayoutOrder = i

        local sender = mkLabel(row, {
            text   = msg.from,
            color  = C.white,
            font   = Enum.Font.GothamSemiBold,
            size   = 13,
            sz     = UDim2.new(1,-70,0,18),
            pos    = UDim2.new(0,12,0,10),
            z      = 7,
        })
        local subj = mkLabel(row, {
            text   = msg.subject,
            color  = C.subtext,
            font   = Enum.Font.Gotham,
            size   = 12,
            sz     = UDim2.new(1,-24,0,16),
            pos    = UDim2.new(0,12,0,32),
            z      = 7,
            wrap   = true,
        })
        local timeL = mkLabel(row, {
            text   = msg.time,
            color  = C.subtext,
            font   = Enum.Font.Gotham,
            size   = 11,
            sz     = UDim2.new(0,60,0,18),
            pos    = UDim2.new(1,-68,0,10),
            z      = 7,
            xalign = Enum.TextXAlignment.Right,
        })
    end

    return bg
end

-- ─────────────────────────────────────────────────────────────────────────────
-- HYLTON / ROOM BOOKING APP
-- ─────────────────────────────────────────────────────────────────────────────

local function buildHylton()
    local bg = mkFrame(appContainer, {
        color  = Color3.fromRGB(20,16,8),
        size   = UDim2.new(1,0,1,0),
        pos    = UDim2.new(0,0,0,0),
        z      = 4,
        radius = INNER_RADIUS,
    })
    bg.Name = "hylton"

    local header = mkLabel(bg, {
        text   = "🏨  Hylton Hotel",
        color  = Color3.fromRGB(220,180,80),
        font   = Enum.Font.GothamBold,
        size   = 18,
        sz     = UDim2.new(1,0,0,44),
        pos    = UDim2.new(0,0,0,STATUS_H),
        z      = 5,
        xalign = Enum.TextXAlignment.Center,
    })

    local scroll = mkScroll(bg, {
        size   = UDim2.new(1,0,1,-(STATUS_H+44+32)),
        pos    = UDim2.new(0,0,0,STATUS_H+44),
        z      = 5,
        bar    = 0,
        canvas = UDim2.new(0,0,0,600),
        radius = INNER_RADIUS,
    })

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding   = UDim.new(0,8)
    layout.Parent    = scroll

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft   = UDim.new(0,10)
    padding.PaddingRight  = UDim.new(0,10)
    padding.PaddingTop    = UDim.new(0,8)
    padding.Parent        = scroll

    -- Room availability section
    local secLabel = mkLabel(scroll, {
        text   = "AVAILABLE ROOMS",
        color  = Color3.fromRGB(180,140,60),
        font   = Enum.Font.GothamBold,
        size   = 11,
        sz     = UDim2.new(1,0,0,20),
        z      = 6,
        xalign = Enum.TextXAlignment.Left,
    })
    secLabel.LayoutOrder = 0

    local statusMsg = mkLabel(scroll, {
        text   = "Loading rooms…",
        color  = C.subtext,
        font   = Enum.Font.Gotham,
        size   = 12,
        sz     = UDim2.new(1,0,0,24),
        z      = 6,
        xalign = Enum.TextXAlignment.Left,
    })
    statusMsg.LayoutOrder = 1

    local ROOM_TYPE_NAMES = { "Standard", "Deluxe", "Suite", "Penthouse" }

    local function refreshRooms()
        statusMsg.Text = "Checking availability…"
        task.spawn(function()
            local rooms = getAvailableRooms()
            if #rooms == 0 then
                statusMsg.Text = "No rooms currently available."
                return
            end
            statusMsg.Text = string.format("%d room(s) available", #rooms)

            -- Remove old room cards (LayoutOrder >= 10)
            for _, ch in ipairs(scroll:GetChildren()) do
                if ch:IsA("Frame") and ch.LayoutOrder >= 10 then
                    ch:Destroy()
                end
            end

            for idx, room in ipairs(rooms) do
                local typeName = ROOM_TYPE_NAMES[room.typeIndex] or ("Type "..room.typeIndex)
                local card = mkFrame(scroll, {
                    color  = C.cardBg,
                    size   = UDim2.new(1,0,0,56),
                    z      = 6,
                    radius = 12,
                })
                card.LayoutOrder = 10 + idx

                mkLabel(card, {
                    text   = string.format("Room %d — %s", room.roomNumber, typeName),
                    color  = C.white,
                    font   = Enum.Font.GothamSemiBold,
                    size   = 13,
                    sz     = UDim2.new(1,-90,0,20),
                    pos    = UDim2.new(0,12,0,8),
                    z      = 7,
                })

                local bookBtn = mkBtn(card, {
                    color  = C.accent,
                    text   = "Book",
                    sz     = UDim2.new(0,72,0,28),
                    pos    = UDim2.new(1,-82,0.5,-14),
                    z      = 7,
                    radius = 8,
                    size   = 13,
                })

                local rf = room.folder
                bookBtn.MouseButton1Click:Connect(function()
                    bookBtn.Text = "Booked ✓"
                    bookBtn.BackgroundColor3 = C.green
                    -- Fire server event
                    local re = game:GetService("ReplicatedStorage"):FindFirstChild("BookRoom")
                    if re then
                        re:FireServer(rf.Name)
                    end
                    task.delay(2, refreshRooms)
                end)
            end
        end)
    end

    -- My current room
    local myRoomLabel = mkLabel(scroll, {
        text   = "MY ROOM",
        color  = Color3.fromRGB(180,140,60),
        font   = Enum.Font.GothamBold,
        size   = 11,
        sz     = UDim2.new(1,0,0,20),
        z      = 6,
        xalign = Enum.TextXAlignment.Left,
    })
    myRoomLabel.LayoutOrder = 2

    local myRoomCard = mkFrame(scroll, {
        color  = C.cardBg,
        size   = UDim2.new(1,0,0,56),
        z      = 6,
        radius = 12,
    })
    myRoomCard.LayoutOrder = 3

    local myRoomText = mkLabel(myRoomCard, {
        text   = "No room booked",
        color  = C.subtext,
        font   = Enum.Font.Gotham,
        size   = 13,
        sz     = UDim2.new(1,-100,1,0),
        pos    = UDim2.new(0,12,0,0),
        z      = 7,
    })

    local checkoutBtn = mkBtn(myRoomCard, {
        color  = C.red,
        text   = "Check Out",
        sz     = UDim2.new(0,80,0,28),
        pos    = UDim2.new(1,-90,0.5,-14),
        z      = 7,
        radius = 8,
        size   = 12,
    })
    checkoutBtn.Visible = false

    local function refreshMyRoom()
        task.spawn(function()
            local doors = findDoorsFolder()
            local rf = findPlayerRoom(doors)
            if rf then
                local num = getRoomNumber(rf)
                local typ = getRoomType(rf)
                local typeName = ROOM_TYPE_NAMES[typ] or ("Type "..typ)
                myRoomText.Text  = string.format("Room %d (%s)", num, typeName)
                myRoomText.TextColor3 = C.white
                checkoutBtn.Visible = true
            else
                myRoomText.Text  = "No room booked"
                myRoomText.TextColor3 = C.subtext
                checkoutBtn.Visible = false
            end
        end)
    end

    checkoutBtn.MouseButton1Click:Connect(function()
        local re = game:GetService("ReplicatedStorage"):FindFirstChild("CheckOutRoom")
        if re then
            re:FireServer()
        end
        task.delay(1, refreshMyRoom)
        task.delay(1, refreshRooms)
    end)

    -- Refresh button
    local refreshBtn = mkBtn(bg, {
        color  = Color3.fromRGB(40,40,50),
        text   = "↻  Refresh",
        sz     = UDim2.new(1,-24,0,36),
        pos    = UDim2.new(0,12,1,-(36+38)),
        z      = 7,
        radius = 10,
        size   = 13,
    })
    refreshBtn.MouseButton1Click:Connect(function()
        refreshRooms()
        refreshMyRoom()
    end)

    -- Initial load
    refreshRooms()
    refreshMyRoom()

    return bg
end

-- ─────────────────────────────────────────────────────────────────────────────
-- SETTINGS APP
-- ─────────────────────────────────────────────────────────────────────────────

local function buildSettings()
    local bg = mkFrame(appContainer, {
        color  = Color3.fromRGB(15,15,18),
        size   = UDim2.new(1,0,1,0),
        pos    = UDim2.new(0,0,0,0),
        z      = 4,
        radius = INNER_RADIUS,
    })
    bg.Name = "settings"

    local header = mkLabel(bg, {
        text   = "Settings",
        color  = C.white,
        font   = Enum.Font.GothamBold,
        size   = 20,
        sz     = UDim2.new(1,0,0,44),
        pos    = UDim2.new(0,0,0,STATUS_H),
        z      = 5,
        xalign = Enum.TextXAlignment.Center,
    })

    local scroll = mkScroll(bg, {
        size   = UDim2.new(1,0,1,-(STATUS_H+44+32)),
        pos    = UDim2.new(0,0,0,STATUS_H+44),
        z      = 5,
        bar    = 2,
        canvas = UDim2.new(0,0,0,620),
        radius = INNER_RADIUS,
    })

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding   = UDim.new(0,8)
    layout.Parent    = scroll

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft  = UDim.new(0,10)
    pad.PaddingRight = UDim.new(0,10)
    pad.PaddingTop   = UDim.new(0,8)
    pad.Parent       = scroll

    -- Profile card
    local profile = mkFrame(scroll, {
        color  = C.surface,
        size   = UDim2.new(1,0,0,72),
        z      = 6,
        radius = 14,
    })
    profile.LayoutOrder = 0

    local avatar = mkFrame(profile, {
        color  = C.accent,
        size   = UDim2.new(0,48,0,48),
        pos    = UDim2.new(0,10,0.5,-24),
        z      = 7,
        radius = 999,
    })
    mkLabel(avatar, {
        text   = string.sub(player.Name, 1, 1):upper(),
        color  = C.white,
        font   = Enum.Font.GothamBold,
        size   = 22,
        sz     = UDim2.new(1,0,1,0),
        z      = 8,
        xalign = Enum.TextXAlignment.Center,
    })
    mkLabel(profile, {
        text   = player.Name,
        color  = C.white,
        font   = Enum.Font.GothamBold,
        size   = 14,
        sz     = UDim2.new(1,-80,0,22),
        pos    = UDim2.new(0,70,0,12),
        z      = 7,
    })
    mkLabel(profile, {
        text   = "Apple ID · iCloud",
        color  = C.subtext,
        font   = Enum.Font.Gotham,
        size   = 11,
        sz     = UDim2.new(1,-80,0,18),
        pos    = UDim2.new(0,70,0,36),
        z      = 7,
    })

    -- ── Section header helper ───────────────────────────────────────────────
    local rowOrder = 1
    local function sectionHeader(text)
        local lbl = mkLabel(scroll, {
            text   = text,
            color  = C.subtext,
            font   = Enum.Font.GothamSemiBold,
            size   = 11,
            sz     = UDim2.new(1,0,0,18),
            z      = 6,
            xalign = Enum.TextXAlignment.Left,
        })
        lbl.LayoutOrder = rowOrder
        rowOrder = rowOrder + 1
        return lbl
    end

    -- ── Toggle row helper ───────────────────────────────────────────────────
    local function toggleRow(parent, label, iconEmoji, iconColor, initialVal, onChange)
        local row = mkFrame(parent, {
            color  = C.surface,
            size   = UDim2.new(1,0,0,44),
            z      = 6,
            radius = 10,
        })
        row.LayoutOrder = rowOrder
        rowOrder = rowOrder + 1

        local iconBg = mkFrame(row, {
            color  = iconColor or C.surface2,
            size   = UDim2.new(0,28,0,28),
            pos    = UDim2.new(0,8,0.5,-14),
            z      = 7,
            radius = 7,
        })
        mkLabel(iconBg, {
            text   = iconEmoji,
            size   = 16,
            sz     = UDim2.new(1,0,1,0),
            z      = 8,
            xalign = Enum.TextXAlignment.Center,
        })
        mkLabel(row, {
            text   = label,
            color  = C.white,
            font   = Enum.Font.Gotham,
            size   = 13,
            sz     = UDim2.new(1,-100,1,0),
            pos    = UDim2.new(0,46,0,0),
            z      = 7,
        })

        -- Toggle pill
        local pillBg = mkFrame(row, {
            color  = initialVal and C.green or C.surface2,
            size   = UDim2.new(0,42,0,24),
            pos    = UDim2.new(1,-52,0.5,-12),
            z      = 7,
            radius = 999,
        })
        local pillKnob = mkFrame(pillBg, {
            color  = C.white,
            size   = UDim2.new(0,20,0,20),
            pos    = initialVal and UDim2.new(1,-22,0.5,-10) or UDim2.new(0,2,0.5,-10),
            z      = 8,
            radius = 999,
        })

        local state = initialVal
        local pillBtn = Instance.new("TextButton")
        pillBtn.Size = UDim2.new(1,0,1,0)
        pillBtn.BackgroundTransparency = 1
        pillBtn.Text = ""
        pillBtn.ZIndex = 9
        pillBtn.Parent = pillBg

        pillBtn.MouseButton1Click:Connect(function()
            state = not state
            local info = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            tween(pillBg,   info, { BackgroundColor3 = state and C.green or C.surface2 })
            tween(pillKnob, info, {
                Position = state and UDim2.new(1,-22,0.5,-10) or UDim2.new(0,2,0.5,-10)
            })
            if onChange then onChange(state) end
        end)

        return row
    end

    -- ── NETWORK section ─────────────────────────────────────────────────────
    sectionHeader("NETWORK")

    local wifiSection = mkFrame(scroll, {
        color  = C.surface,
        size   = UDim2.new(1,0,0,86),
        z      = 6,
        radius = 12,
    })
    wifiSection.LayoutOrder = rowOrder
    rowOrder = rowOrder + 1

    -- Wi-Fi row with toggle
    local wifiBg = mkFrame(wifiSection, {
        color  = Color3.fromRGB(0,112,255),
        size   = UDim2.new(0,28,0,28),
        pos    = UDim2.new(0,8,0,8),
        z      = 7,
        radius = 7,
    })
    mkLabel(wifiBg, {
        text   = "W",
        color  = C.white,
        font   = Enum.Font.GothamBold,
        size   = 15,
        sz     = UDim2.new(1,0,1,0),
        z      = 8,
        xalign = Enum.TextXAlignment.Center,
    })
    mkLabel(wifiSection, {
        text   = "Wi-Fi",
        color  = C.white,
        font   = Enum.Font.Gotham,
        size   = 14,
        sz     = UDim2.new(1,-100,0,44),
        pos    = UDim2.new(0,46,0,0),
        z      = 7,
    })

    -- WiFi toggle pill
    local wPillBg = mkFrame(wifiSection, {
        color  = settingsState.wifi and C.green or C.surface2,
        size   = UDim2.new(0,42,0,24),
        pos    = UDim2.new(1,-52,0,10),
        z      = 7,
        radius = 999,
    })
    local wPillKnob = mkFrame(wPillBg, {
        color  = C.white,
        size   = UDim2.new(0,20,0,20),
        pos    = settingsState.wifi and UDim2.new(1,-22,0.5,-10) or UDim2.new(0,2,0.5,-10),
        z      = 8,
        radius = 999,
    })
    local wPillBtn = Instance.new("TextButton")
    wPillBtn.Size = UDim2.new(1,0,1,0)
    wPillBtn.BackgroundTransparency = 1
    wPillBtn.Text = ""
    wPillBtn.ZIndex = 9
    wPillBtn.Parent = wPillBg
    wPillBtn.MouseButton1Click:Connect(function()
        settingsState.wifi = not settingsState.wifi
        local info = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        tween(wPillBg,   info, { BackgroundColor3 = settingsState.wifi and C.green or C.surface2 })
        tween(wPillKnob, info, {
            Position = settingsState.wifi
                and UDim2.new(1,-22,0.5,-10) or UDim2.new(0,2,0.5,-10)
        })
    end)

    -- Separator
    local sep = mkFrame(wifiSection, {
        color  = C.separator,
        size   = UDim2.new(1,-46,0,1),
        pos    = UDim2.new(0,46,0,43),
        z      = 7,
        radius = false,
    })

    -- Network name sub-row
    mkLabel(wifiSection, {
        text   = "Connected",
        color  = C.subtext,
        font   = Enum.Font.Gotham,
        size   = 11,
        sz     = UDim2.new(0,70,0,22),
        pos    = UDim2.new(0,46,0,46),
        z      = 7,
    })
    mkLabel(wifiSection, {
        text   = settingsState.wifiName,
        color  = C.accent,
        font   = Enum.Font.GothamSemiBold,
        size   = 12,
        sz     = UDim2.new(1,-130,0,22),
        pos    = UDim2.new(0,120,0,46),
        z      = 7,
        xalign = Enum.TextXAlignment.Right,
    })

    -- ── GENERAL section ─────────────────────────────────────────────────────
    sectionHeader("GENERAL")

    toggleRow(scroll, "Notifications", "🔔", Color3.fromRGB(255,60,60),
        settingsState.notifications,
        function(v) settingsState.notifications = v end)

    toggleRow(scroll, "Do Not Disturb", "🌙", Color3.fromRGB(70,50,130),
        settingsState.doNotDisturb,
        function(v) settingsState.doNotDisturb = v end)

    toggleRow(scroll, "Dark Mode", "🌑", Color3.fromRGB(40,40,50),
        settingsState.darkMode,
        function(v) settingsState.darkMode = v end)

    -- ── DISPLAY section ─────────────────────────────────────────────────────
    sectionHeader("DISPLAY")

    local brightRow = mkFrame(scroll, {
        color  = C.surface,
        size   = UDim2.new(1,0,0,56),
        z      = 6,
        radius = 10,
    })
    brightRow.LayoutOrder = rowOrder
    rowOrder = rowOrder + 1

    mkLabel(brightRow, {
        text   = "Brightness",
        color  = C.white,
        font   = Enum.Font.Gotham,
        size   = 13,
        sz     = UDim2.new(1,-16,0,20),
        pos    = UDim2.new(0,12,0,8),
        z      = 7,
    })
    local slider = mkFrame(brightRow, {
        color  = C.surface2,
        size   = UDim2.new(1,-24,0,6),
        pos    = UDim2.new(0,12,0,36),
        z      = 7,
        radius = 999,
    })
    local sliderFill = mkFrame(slider, {
        color  = C.accent,
        size   = UDim2.new(settingsState.brightness,0,1,0),
        pos    = UDim2.new(0,0,0,0),
        z      = 8,
        radius = 999,
    })

    return bg
end

-- ─────────────────────────────────────────────────────────────────────────────
-- CALENDAR APP
-- ─────────────────────────────────────────────────────────────────────────────

local function buildCalendar()
    local bg = mkFrame(appContainer, {
        color  = C.bg,
        size   = UDim2.new(1,0,1,0),
        pos    = UDim2.new(0,0,0,0),
        z      = 4,
        radius = INNER_RADIUS,
    })
    bg.Name = "calendar"

    local header = mkLabel(bg, {
        text   = "Calendar",
        color  = C.white,
        font   = Enum.Font.GothamBold,
        size   = 20,
        sz     = UDim2.new(1,0,0,44),
        pos    = UDim2.new(0,0,0,STATUS_H),
        z      = 5,
        xalign = Enum.TextXAlignment.Center,
    })

    -- Month / year
    local now = os.date("*t")
    local monthNames = {
        "January","February","March","April","May","June",
        "July","August","September","October","November","December"
    }

    local monthLabel = mkLabel(bg, {
        text   = string.format("%s %d", monthNames[now.month], now.year),
        color  = C.accent,
        font   = Enum.Font.GothamBold,
        size   = 15,
        sz     = UDim2.new(1,0,0,22),
        pos    = UDim2.new(0,0,0,STATUS_H+44),
        z      = 5,
        xalign = Enum.TextXAlignment.Center,
    })

    -- Day-of-week header
    local DOW = {"Su","Mo","Tu","We","Th","Fr","Sa"}
    local calContent = mkFrame(bg, {
        color  = Color3.fromRGB(20,20,25),
        size   = UDim2.new(1,-16,1,-(STATUS_H+74+32)),
        pos    = UDim2.new(0,8,0,STATUS_H+74),
        z      = 5,
        radius = INNER_RADIUS,
        clip   = true,
    })

    local COL_W = (PHONE_W - 16) / 7
    for i, d in ipairs(DOW) do
        mkLabel(calContent, {
            text   = d,
            color  = C.subtext,
            font   = Enum.Font.GothamSemiBold,
            size   = 11,
            sz     = UDim2.new(0, COL_W, 0, 20),
            pos    = UDim2.new(0, (i-1)*COL_W, 0, 4),
            z      = 6,
            xalign = Enum.TextXAlignment.Center,
        })
    end

    -- Day cells
    local firstDay = os.time({ year=now.year, month=now.month, day=1,
                                hour=0, min=0, sec=0 })
    local startDow = os.date("*t", firstDay).wday - 1  -- 0=Sunday
    local daysInMonth = 0
    do
        local nextMonth = now.month + 1
        local yr = now.year
        if nextMonth > 12 then nextMonth = 1; yr = yr + 1 end
        daysInMonth = os.date("*t",
            os.time({ year=yr, month=nextMonth, day=1, hour=0, min=0, sec=0 })
            - 1).day
    end

    local ROW_H = 28
    for day = 1, daysInMonth do
        local idx = day + startDow - 1
        local col = idx % 7
        local row = math.floor(idx / 7)
        local isToday = (day == now.day)

        local cell = mkFrame(calContent, {
            color  = isToday and C.accent or C.transparent,
            size   = UDim2.new(0, COL_W-2, 0, ROW_H-2),
            pos    = UDim2.new(0, col*COL_W+1, 0, 24 + row*ROW_H),
            z      = 6,
            radius = isToday and 999 or 0,
        })
        if not isToday then cell.BackgroundTransparency = 1 end

        mkLabel(cell, {
            text   = tostring(day),
            color  = isToday and C.white or C.subtext,
            font   = isToday and Enum.Font.GothamBold or Enum.Font.Gotham,
            size   = 12,
            sz     = UDim2.new(1,0,1,0),
            z      = 7,
            xalign = Enum.TextXAlignment.Center,
        })
    end

    return bg
end

-- ─────────────────────────────────────────────────────────────────────────────
-- NOTES APP
-- ─────────────────────────────────────────────────────────────────────────────

local function buildNotes()
    local bg = mkFrame(appContainer, {
        color  = Color3.fromRGB(18,16,8),
        size   = UDim2.new(1,0,1,0),
        pos    = UDim2.new(0,0,0,0),
        z      = 4,
        radius = INNER_RADIUS,
    })
    bg.Name = "notes"

    local listView = mkFrame(bg, {
        color  = C.transparent,
        size   = UDim2.new(1,0,1,0),
        pos    = UDim2.new(0,0,0,0),
        z      = 5,
        radius = false,
    })
    listView.BackgroundTransparency = 1
    listView.Name = "ListView"

    local header = mkLabel(listView, {
        text   = "Notes",
        color  = Color3.fromRGB(255,210,0),
        font   = Enum.Font.GothamBold,
        size   = 20,
        sz     = UDim2.new(1,0,0,44),
        pos    = UDim2.new(0,0,0,STATUS_H),
        z      = 6,
        xalign = Enum.TextXAlignment.Center,
    })

    -- New note button
    local newBtn = mkBtn(listView, {
        color  = Color3.fromRGB(255,210,0),
        text   = "+",
        sz     = UDim2.new(0,36,0,36),
        pos    = UDim2.new(1,-46,0,STATUS_H+4),
        z      = 6,
        radius = 999,
        size   = 22,
        tcol   = C.black,
    })

    local notesScroll = mkScroll(listView, {
        size   = UDim2.new(1,0,1,-(STATUS_H+44+32)),
        pos    = UDim2.new(0,0,0,STATUS_H+44),
        z      = 6,
        bar    = 0,
        canvas = UDim2.new(0,0,0,400),
        radius = INNER_RADIUS,
    })

    local nLayout = Instance.new("UIListLayout")
    nLayout.SortOrder = Enum.SortOrder.LayoutOrder
    nLayout.Padding   = UDim.new(0,1)
    nLayout.Parent    = notesScroll

    local nPad = Instance.new("UIPadding")
    nPad.PaddingLeft  = UDim.new(0,10)
    nPad.PaddingRight = UDim.new(0,10)
    nPad.PaddingTop   = UDim.new(0,6)
    nPad.Parent       = notesScroll

    -- Detail view (shown when a note is opened)
    local detailView = mkFrame(bg, {
        color  = Color3.fromRGB(18,16,8),
        size   = UDim2.new(1,0,1,0),
        pos    = UDim2.new(0,0,0,0),
        z      = 6,
        radius = INNER_RADIUS,
    })
    detailView.Name    = "DetailView"
    detailView.Visible = false

    local backBtn = mkBtn(detailView, {
        color  = C.transparent,
        text   = "< Notes",
        sz     = UDim2.new(0,80,0,32),
        pos    = UDim2.new(0,8,0,STATUS_H+4),
        z      = 7,
        radius = false,
        size   = 13,
        tcol   = Color3.fromRGB(255,210,0),
    })
    backBtn.BackgroundTransparency = 1

    local detailTitle = mkLabel(detailView, {
        text   = "",
        color  = C.white,
        font   = Enum.Font.GothamBold,
        size   = 17,
        sz     = UDim2.new(1,-24,0,28),
        pos    = UDim2.new(0,12,0,STATUS_H+40),
        z      = 7,
    })

    local detailBody = mkLabel(detailView, {
        text   = "",
        color  = C.subtext,
        font   = Enum.Font.Gotham,
        size   = 13,
        sz     = UDim2.new(1,-24,1,-(STATUS_H+80+32)),
        pos    = UDim2.new(0,12,0,STATUS_H+74),
        z      = 7,
        wrap   = true,
        yalign = Enum.TextYAlignment.Top,
    })

    backBtn.MouseButton1Click:Connect(function()
        detailView.Visible = false
        listView.Visible   = true
    end)

    -- Rebuild note list
    local function refreshNotes()
        for _, ch in ipairs(notesScroll:GetChildren()) do
            if ch:IsA("Frame") then ch:Destroy() end
        end
        for i, note in ipairs(notesState.notes) do
            local row = mkFrame(notesScroll, {
                color  = Color3.fromRGB(30,28,16),
                size   = UDim2.new(1,0,0,58),
                z      = 7,
                radius = 10,
            })
            row.LayoutOrder = i

            mkLabel(row, {
                text   = note.title,
                color  = C.white,
                font   = Enum.Font.GothamSemiBold,
                size   = 13,
                sz     = UDim2.new(1,-70,0,18),
                pos    = UDim2.new(0,10,0,8),
                z      = 8,
            })
            mkLabel(row, {
                text   = note.date.."  "..string.sub(note.body,1,30)..(#note.body>30 and "…" or ""),
                color  = C.subtext,
                font   = Enum.Font.Gotham,
                size   = 11,
                sz     = UDim2.new(1,-20,0,16),
                pos    = UDim2.new(0,10,0,30),
                z      = 8,
                wrap   = true,
            })

            local rowBtn = Instance.new("TextButton")
            rowBtn.Size               = UDim2.new(1,0,1,0)
            rowBtn.BackgroundTransparency = 1
            rowBtn.Text               = ""
            rowBtn.ZIndex             = 9
            rowBtn.Parent             = row
            local noteRef = note
            rowBtn.MouseButton1Click:Connect(function()
                detailTitle.Text = noteRef.title
                detailBody.Text  = noteRef.body
                listView.Visible   = false
                detailView.Visible = true
            end)
        end
    end

    newBtn.MouseButton1Click:Connect(function()
        table.insert(notesState.notes, 1, {
            title = "New Note",
            body  = "Tap to edit.",
            date  = "Today",
        })
        refreshNotes()
    end)

    refreshNotes()
    return bg
end

-- ─────────────────────────────────────────────────────────────────────────────
-- CLOCK APP
-- ─────────────────────────────────────────────────────────────────────────────

local function buildClock()
    local bg = mkFrame(appContainer, {
        color  = C.bg,
        size   = UDim2.new(1,0,1,0),
        pos    = UDim2.new(0,0,0,0),
        z      = 4,
        radius = INNER_RADIUS,
    })
    bg.Name = "clock"

    -- Tab bar at the top (below status bar)
    local tabs     = { "Alarm", "Timer", "Stopwatch" }
    local activeTab = "Alarm"
    local tabPanels = {}

    local tabBar = mkFrame(bg, {
        color  = Color3.fromRGB(22,22,25),
        size   = UDim2.new(1,0,0,36),
        pos    = UDim2.new(0,0,0,STATUS_H),
        z      = 5,
        radius = false,
    })

    local tabBtns = {}
    for i, tab in ipairs(tabs) do
        local btn = mkBtn(tabBar, {
            color  = C.transparent,
            text   = tab,
            sz     = UDim2.new(1/#tabs, 0, 1, 0),
            pos    = UDim2.new((i-1)/#tabs, 0, 0, 0),
            z      = 6,
            radius = false,
            size   = 13,
            tcol   = C.subtext,
        })
        btn.BackgroundTransparency = 1
        tabBtns[tab] = btn
    end

    -- Indicator bar
    local indicator = mkFrame(tabBar, {
        color  = C.accent,
        size   = UDim2.new(1/#tabs, -8, 0, 2),
        pos    = UDim2.new(0,4,1,-2),
        z      = 7,
        radius = 999,
    })

    local function switchTab(name)
        activeTab = name
        for _, t in ipairs(tabs) do
            tabBtns[t].TextColor3 = (t == name) and C.white or C.subtext
            if tabPanels[t] then
                tabPanels[t].Visible = (t == name)
            end
        end
        local idx = table.find(tabs, name) or 1
        tween(indicator,
            TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Position = UDim2.new((idx-1)/#tabs, 4, 1, -2) }
        )
    end

    for _, tab in ipairs(tabs) do
        tabBtns[tab].MouseButton1Click:Connect(function() switchTab(tab) end)
    end

    local PANEL_POS = UDim2.new(0,0,0,STATUS_H+36)
    local PANEL_SZ  = UDim2.new(1,0,1,-(STATUS_H+36+32))

    -- ── ALARM panel ──────────────────────────────────────────────────────────
    local alarmPanel = mkFrame(bg, {
        color  = C.bg,
        size   = PANEL_SZ,
        pos    = PANEL_POS,
        z      = 5,
        radius = INNER_RADIUS,
    })
    tabPanels["Alarm"] = alarmPanel

    mkLabel(alarmPanel, {
        text   = "No alarms set",
        color  = C.subtext,
        font   = Enum.Font.Gotham,
        size   = 13,
        sz     = UDim2.new(1,0,0,40),
        pos    = UDim2.new(0,0,0,20),
        z      = 6,
        xalign = Enum.TextXAlignment.Center,
    })

    local addAlarmBtn = mkBtn(alarmPanel, {
        color  = C.accent,
        text   = "+  Add Alarm",
        sz     = UDim2.new(1,-24,0,40),
        pos    = UDim2.new(0,12,1,-(40+8)),
        z      = 6,
        radius = 12,
        size   = 14,
    })

    -- ── TIMER panel ───────────────────────────────────────────────────────────
    local timerPanel = mkFrame(bg, {
        color  = C.bg,
        size   = PANEL_SZ,
        pos    = PANEL_POS,
        z      = 5,
        radius = INNER_RADIUS,
    })
    timerPanel.Visible = false
    tabPanels["Timer"] = timerPanel

    local timerDisplay = mkLabel(timerPanel, {
        text   = "00:00",
        color  = C.white,
        font   = Enum.Font.GothamBold,
        size   = 48,
        sz     = UDim2.new(1,0,0,60),
        pos    = UDim2.new(0,0,0,20),
        z      = 6,
        xalign = Enum.TextXAlignment.Center,
    })

    local timerRunning = false
    local timerTotal   = 60
    local timerRemain  = 60

    local startTimerBtn = mkBtn(timerPanel, {
        color  = C.green,
        text   = "Start",
        sz     = UDim2.new(0,100,0,44),
        pos    = UDim2.new(0.5,-50,0,90),
        z      = 6,
        radius = 999,
        size   = 16,
    })

    startTimerBtn.MouseButton1Click:Connect(function()
        if not timerRunning then
            timerRunning = true
            startTimerBtn.Text = "Pause"
            startTimerBtn.BackgroundColor3 = C.orange

            -- Register in clockState so live activity picks it up
            clockState.timers = { { total=timerTotal, remaining=timerRemain, running=true } }
        else
            timerRunning = false
            startTimerBtn.Text = "Resume"
            startTimerBtn.BackgroundColor3 = C.green
            clockState.timers = {}
        end
    end)

    RunService.Heartbeat:Connect(function(dt)
        if timerRunning and timerRemain > 0 then
            timerRemain = timerRemain - dt
            if timerRemain <= 0 then
                timerRemain = 0
                timerRunning = false
                startTimerBtn.Text = "Start"
                startTimerBtn.BackgroundColor3 = C.green
                clockState.timers = {}
            end
            local s = math.max(0, math.floor(timerRemain))
            timerDisplay.Text = string.format("%02d:%02d", math.floor(s/60), s%60)
            if clockState.timers[1] then
                clockState.timers[1].remaining = timerRemain
            end
        end
    end)

    -- ── STOPWATCH panel ───────────────────────────────────────────────────────
    local swPanel = mkFrame(bg, {
        color  = C.bg,
        size   = PANEL_SZ,
        pos    = PANEL_POS,
        z      = 5,
        radius = INNER_RADIUS,
    })
    swPanel.Visible = false
    tabPanels["Stopwatch"] = swPanel

    local swDisplay = mkLabel(swPanel, {
        text   = "00:00.00",
        color  = C.white,
        font   = Enum.Font.GothamBold,
        size   = 40,
        sz     = UDim2.new(1,0,0,56),
        pos    = UDim2.new(0,0,0,20),
        z      = 6,
        xalign = Enum.TextXAlignment.Center,
    })

    local swStartBtn = mkBtn(swPanel, {
        color  = C.green,
        text   = "Start",
        sz     = UDim2.new(0,90,0,44),
        pos    = UDim2.new(0.5,-95,0,86),
        z      = 6,
        radius = 999,
        size   = 15,
    })
    local swLapBtn = mkBtn(swPanel, {
        color  = C.surface2,
        text   = "Lap",
        sz     = UDim2.new(0,90,0,44),
        pos    = UDim2.new(0.5,5,0,86),
        z      = 6,
        radius = 999,
        size   = 15,
    })

    local swStart = 0
    swStartBtn.MouseButton1Click:Connect(function()
        local sw = clockState.stopwatch
        if not sw.running then
            sw.running  = true
            sw.lapStart = tick()
            swStartBtn.Text = "Stop"
            swStartBtn.BackgroundColor3 = C.red
        else
            sw.running = false
            sw.elapsed = sw.elapsed + (tick() - sw.lapStart)
            swStartBtn.Text = "Start"
            swStartBtn.BackgroundColor3 = C.green
        end
    end)

    swLapBtn.MouseButton1Click:Connect(function()
        local sw = clockState.stopwatch
        if sw.running then
            sw.lapStart = tick()
        else
            sw.elapsed  = 0
            swDisplay.Text = "00:00.00"
        end
    end)

    RunService.Heartbeat:Connect(function()
        local sw = clockState.stopwatch
        if sw.running then
            local e = sw.elapsed + (tick() - sw.lapStart)
            local m  = math.floor(e / 60)
            local s  = math.floor(e % 60)
            local cs = math.floor((e % 1) * 100)
            swDisplay.Text = string.format("%02d:%02d.%02d", m, s, cs)
        end
    end)

    switchTab("Alarm")
    return bg
end

-- ─────────────────────────────────────────────────────────────────────────────
-- BUILD & REGISTER ALL SCREENS
-- ─────────────────────────────────────────────────────────────────────────────

screens["lock"] = buildLockScreen()
screens["home"] = buildHome()
screens["app"]  = appContainer

appScreens["inbox"]    = buildInbox()
appScreens["hylton"]   = buildHylton()
appScreens["settings"] = buildSettings()
appScreens["calendar"] = buildCalendar()
appScreens["notes"]    = buildNotes()
appScreens["clock"]    = buildClock()

-- Hide all app screens initially
for _, s in pairs(appScreens) do
    s.Visible = false
end

-- Build home bar (must be after appContainer is created)
buildHomeBar(appContainer)

-- Start on lock screen
showScreen("lock")

-- ─────────────────────────────────────────────────────────────────────────────
-- STATUS BAR CLOCK UPDATE
-- ─────────────────────────────────────────────────────────────────────────────

RunService.Heartbeat:Connect(function()
    statusTime.Text = os.date("%H:%M")
end)