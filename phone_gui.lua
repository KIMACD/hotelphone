-- PhoneGui.lua
-- LocalScript inside a Tool (StarterPack or given to player)
-- PART 1 OF 2

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local tool      = script.Parent

------------------------------------------------------------
-- DIMENSIONS
------------------------------------------------------------
local PHONE_W      = 280
local PHONE_H      = 560
local PHONE_RADIUS = 38
local PAD_R        = 18
local PAD_B        = 18
local HOME_BAR_H   = 34

------------------------------------------------------------
-- COLOURS
------------------------------------------------------------
local C = {
	bg        = Color3.fromRGB(10,  12,  22),
	surface   = Color3.fromRGB(18,  22,  38),
	surface2  = Color3.fromRGB(24,  30,  52),
	blue      = Color3.fromRGB(0,   122, 255),
	blueDeep  = Color3.fromRGB(0,   80,  180),
	blueLight = Color3.fromRGB(60,  160, 255),
	green     = Color3.fromRGB(0,   200, 100),
	greenDeep = Color3.fromRGB(0,   140, 70),
	ered       = Color3.fromRGB(200, 50,  50),
	orange    = Color3.fromRGB(220, 130, 0),
	text      = Color3.fromRGB(255, 255, 255),
	textDim   = Color3.fromRGB(160, 165, 185),
	textMuted = Color3.fromRGB(80,  85,  110),
	border    = Color3.fromRGB(35,  42,  70),
	nav       = Color3.fromRGB(12,  14,  26),
	lockBg    = Color3.fromRGB(5,   8,   18),
	mailBg    = Color3.fromRGB(0,   0,   0),
	mailSurface = Color3.fromRGB(18, 18, 20),
	mailDivider = Color3.fromRGB(38, 40, 48),
	unreadDot   = Color3.fromRGB(0, 122, 255),
	settingsBg    = Color3.fromRGB(22, 22, 26),
	settingsCard  = Color3.fromRGB(32, 34, 42),
	settingsSep   = Color3.fromRGB(48, 50, 58),
	calBg         = Color3.fromRGB(0, 0, 0),
	calCard       = Color3.fromRGB(22, 22, 26),
	calToday      = Color3.fromRGB(0, 122, 255),
	calSelected   = Color3.fromRGB(50, 54, 68),
	notesBg       = Color3.fromRGB(0, 0, 0),
	notesCard     = Color3.fromRGB(28, 28, 32),
	notesYellow   = Color3.fromRGB(255, 204, 0),
	clockBg       = Color3.fromRGB(0, 0, 0),
	clockCard     = Color3.fromRGB(22, 22, 26),
	clockOrange   = Color3.fromRGB(255, 159, 10),
}

local ROOM_CARD_COLOURS = {
	[1]=Color3.fromRGB(80, 120,200),
	[2]=Color3.fromRGB(60, 160,100),
	[3]=Color3.fromRGB(160,100, 60),
	[4]=Color3.fromRGB(180, 80,160),
	[5]=Color3.fromRGB(200,160, 30),
	[6]=Color3.fromRGB( 30,180,200),
}

local ROOM_TYPE_NAMES = {
	[1]="Standard Room",[2]="Double Room",[3]="Twin Room",
	[4]="Family Room",[5]="Premium Double",[6]="Premium Family Suite",
}

------------------------------------------------------------
-- HELPERS
------------------------------------------------------------
local function corner(f, r)
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, r or 10)
end

local function stroke(f, c, t)
	local s = Instance.new("UIStroke", f)
	s.Color = c or C.border; s.Thickness = t or 1; return s
end

local function mkFrame(props)
	local f = Instance.new("Frame")
	for k,v in pairs(props) do f[k]=v end; return f
end

local function mkLabel(props)
	local l = Instance.new("TextLabel"); l.BackgroundTransparency = 1
	for k,v in pairs(props) do l[k]=v end; return l
end

local function mkBtn(props)
	local b = Instance.new("TextButton"); b.BorderSizePixel = 0
	for k,v in pairs(props) do b[k]=v end; return b
end

local function mkTextBox(props)
	local t = Instance.new("TextBox"); t.BorderSizePixel = 0
	for k,v in pairs(props) do t[k]=v end; return t
end

local function clamp(n, a, b) return math.max(a, math.min(b, n)) end
