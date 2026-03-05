-- room_manager.lua
-- Roblox Script (ServerScriptService)
-- Manages hotel room availability, booking, and check-out.
--
-- Expected workspace structure:
--   workspace
--   └── CheckIn
--       └── Doors
--           ├── Room1        (Folder)
--           │   ├── Available   (BoolValue)  true = bookable
--           │   ├── Type        (IntValue)   1=Standard,2=Deluxe,3=Suite,4=Penthouse
--           │   ├── Number      (IntValue)   display room number
--           │   ├── RoomOwner   (IntValue)   UserId of current guest (0 = none)
--           │   └── Time        (IntValue)   Unix timestamp of check-in (0 = none)
--           ├── Room2
--           │   └── …
--           └── …
--
-- Remote Events expected in ReplicatedStorage:
--   BookRoom     (client → server, arg: roomFolderName: string)
--   CheckOutRoom (client → server, no args)

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ─── Constants ────────────────────────────────────────────────────────────────
local DOORS_PATH_ROOT  = "CheckIn"
local DOORS_PATH_CHILD = "Doors"
local MAX_STAY_SECONDS = 3600 * 4   -- optional: auto-check-out after 4 h (0 = disabled)

-- ─── Fetch the Doors folder, waiting for it to load ──────────────────────────
local function getDoorsFolder()
    local checkIn = workspace:WaitForChild(DOORS_PATH_ROOT, 10)
    if not checkIn then
        warn("[room_manager] workspace.CheckIn not found after 10 s")
        return nil
    end
    local doors = checkIn:WaitForChild(DOORS_PATH_CHILD, 10)
    if not doors then
        warn("[room_manager] workspace.CheckIn.Doors not found after 10 s")
        return nil
    end
    return doors
end

-- ─── Find the first available room of a given type ───────────────────────────
-- typeIndex: integer matching the Type IntValue (1-4).
-- Returns the room Folder, or nil if none is free.
local function findAvailableRoom(typeIndex)
    local doors = getDoorsFolder()
    if not doors then return nil end

    for _, roomFolder in ipairs(doors:GetChildren()) do
        if roomFolder:IsA("Folder") then
            local avail = roomFolder:FindFirstChild("Available")
            local typ   = roomFolder:FindFirstChild("Type")

            if avail and avail:IsA("BoolValue") and avail.Value == true
            and typ   and typ:IsA("IntValue")   and typ.Value == typeIndex then
                return roomFolder
            end
        end
    end
    return nil
end

-- ─── Find the room currently assigned to a player ────────────────────────────
local function findPlayerRoom(userId)
    local doors = getDoorsFolder()
    if not doors then return nil end

    for _, roomFolder in ipairs(doors:GetChildren()) do
        if roomFolder:IsA("Folder") then
            local owner = roomFolder:FindFirstChild("RoomOwner")
            if owner and owner:IsA("IntValue") and owner.Value == userId then
                return roomFolder
            end
        end
    end
    return nil
end

-- ─── Book a specific room for a player ───────────────────────────────────────
-- Returns true on success, false if the room is no longer available.
local function bookRoom(roomFolder, userId)
    local avail = roomFolder:FindFirstChild("Available")
    local owner = roomFolder:FindFirstChild("RoomOwner")
    local time  = roomFolder:FindFirstChild("Time")

    if not (avail and owner and time) then
        warn("[room_manager] Room "..roomFolder.Name.." is missing value instances.")
        return false
    end

    if avail.Value == false then
        return false   -- someone just took it
    end

    avail.Value = false
    owner.Value = userId
    time.Value  = os.time()
    return true
end

-- ─── Release a room (check-out) ───────────────────────────────────────────────
local function releaseRoom(roomFolder)
    local avail = roomFolder:FindFirstChild("Available")
    local owner = roomFolder:FindFirstChild("RoomOwner")
    local time  = roomFolder:FindFirstChild("Time")

    if owner then owner.Value = 0 end
    if time  then time.Value  = 0 end
    if avail then avail.Value = true end
end

-- ─── Remote Events ────────────────────────────────────────────────────────────

-- BookRoom: player requests to book a specific room by folder name
local bookRoomEvent = Instance.new("RemoteEvent")
bookRoomEvent.Name   = "BookRoom"
bookRoomEvent.Parent = ReplicatedStorage

bookRoomEvent.OnServerEvent:Connect(function(player, roomFolderName)
    if typeof(roomFolderName) ~= "string" then return end

    local doors = getDoorsFolder()
    if not doors then return end

    local roomFolder = doors:FindFirstChild(roomFolderName)
    if not roomFolder or not roomFolder:IsA("Folder") then
        warn("[room_manager] BookRoom: folder '"..tostring(roomFolderName).."' not found.")
        return
    end

    -- Each player may only hold one room at a time
    local existing = findPlayerRoom(player.UserId)
    if existing then
        warn("[room_manager] Player "..player.Name.." already has room "..existing.Name)
        return
    end

    local success = bookRoom(roomFolder, player.UserId)
    if success then
        print(string.format("[room_manager] %s booked room %s (id %d)",
            player.Name, roomFolder.Name, player.UserId))
    else
        warn("[room_manager] BookRoom failed for "..player.Name.." — room unavailable.")
    end
end)

-- CheckOutRoom: player requests to check out of their current room
local checkOutEvent = Instance.new("RemoteEvent")
checkOutEvent.Name   = "CheckOutRoom"
checkOutEvent.Parent = ReplicatedStorage

checkOutEvent.OnServerEvent:Connect(function(player)
    local roomFolder = findPlayerRoom(player.UserId)
    if not roomFolder then
        warn("[room_manager] CheckOutRoom: "..player.Name.." has no room.")
        return
    end

    releaseRoom(roomFolder)
    print(string.format("[room_manager] %s checked out of room %s",
        player.Name, roomFolder.Name))
end)

-- ─── Auto-checkout on player leave ───────────────────────────────────────────
Players.PlayerRemoving:Connect(function(player)
    local roomFolder = findPlayerRoom(player.UserId)
    if roomFolder then
        releaseRoom(roomFolder)
        print(string.format("[room_manager] Auto-checkout for %s (left game)",
            player.Name))
    end
end)

-- ─── Optional: auto-checkout after MAX_STAY_SECONDS ──────────────────────────
if MAX_STAY_SECONDS > 0 then
    task.spawn(function()
        while true do
            task.wait(60)   -- check every minute
            local doors = getDoorsFolder()
            if doors then
                local now = os.time()
                for _, roomFolder in ipairs(doors:GetChildren()) do
                    if roomFolder:IsA("Folder") then
                        local avail = roomFolder:FindFirstChild("Available")
                        local owner = roomFolder:FindFirstChild("RoomOwner")
                        local time  = roomFolder:FindFirstChild("Time")

                        if avail and not avail.Value
                        and owner and owner.Value ~= 0
                        and time  and time.Value ~= 0
                        and (now - time.Value) >= MAX_STAY_SECONDS then
                            local p = Players:GetPlayerByUserId(owner.Value)
                            local pName = p and p.Name or tostring(owner.Value)
                            print(string.format(
                                "[room_manager] Auto-checkout %s from %s (stay limit)",
                                pName, roomFolder.Name))
                            releaseRoom(roomFolder)
                        end
                    end
                end
            end
        end
    end)
end

print("[room_manager] Room manager loaded.")
