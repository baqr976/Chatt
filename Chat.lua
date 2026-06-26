-- Pro Chat v14 - الأسطوري
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local API_URL = "https://fzkxotptuhmhkuhnsoav.supabase.co/rest/v1/chat_messages"
local API_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ6a3hvdHB0dWhtaGt1aG5zb2F2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkyNTQ1OTYsImV4cCI6MjA5NDgzMDU5Nn0.etgvcKzEo89I_nvhB_EyLUbVgbV-gHgBJbW_NjNM7wo"
local HEADERS = {
    ["apikey"] = API_KEY,
    ["Authorization"] = "Bearer " .. API_KEY,
    ["Content-Type"] = "application/json"
}

local request = http_request or request or syn.request or fluxus.request or function() end
if not request then warn("HTTP not supported") return end

if CoreGui:FindFirstChild("ProChat") then CoreGui.ProChat:Destroy() end

local CHAT_SIZE = UDim2.new(0.32, 0, 0.30, 0)
local DISCORD_COLOR = Color3.fromRGB(88, 101, 242)
local COLORS = {
    Color3.fromRGB(255, 107, 107),
    Color3.fromRGB(78, 205, 196),
    Color3.fromRGB(255, 230, 109),
    Color3.fromRGB(199, 128, 232),
    Color3.fromRGB(77, 182, 255),
    Color3.fromRGB(255, 159, 243),
    Color3.fromRGB(162, 255, 134),
}

local MAX_MESSAGES = 250
local currentRoom = "public"
local userColors = {}
local playerBubbles = {}
local lastId = 0
local messageQueue = {}
local messageCount = 0
local lastSent = 0
local isOpen = false
local autoScroll = true
local bubblesEnabled = true
local muted = {}

local function getColor(name)
    if not userColors[name] then
        userColors[name] = COLORS[math.random(#COLORS)]
    end
    return userColors[name]
end

local function toHex(c)
    return string.format("#%02X%02X%02X", c.R * 255, c.G * 255, c.B * 255)
end

local function isDiscord(name)
    return name:sub(1, 3) == "DC:"
end

local function cleanName(name)
    return isDiscord(name) and name:sub(4) or name
end

local gui = Instance.new("ScreenGui")
gui.Name = "ProChat"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = CoreGui

local toggleBtn = Instance.new("TextButton", gui)
toggleBtn.Size = UDim2.new(0, 32, 0, 32)
toggleBtn.Position = UDim2.new(0, 8, 0, 8)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
toggleBtn.Text = "C"
toggleBtn.TextSize = 16
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.BorderSizePixel = 0
toggleBtn.ZIndex = 100
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

local bubbleToggle = Instance.new("TextButton", gui)
bubbleToggle.Size = UDim2.new(0, 32, 0, 32)
bubbleToggle.Position = UDim2.new(0, 48, 0, 8)
bubbleToggle.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
bubbleToggle.Text = "💬"
bubbleToggle.TextSize = 16
bubbleToggle.BorderSizePixel = 0
bubbleToggle.ZIndex = 100
Instance.new("UICorner", bubbleToggle).CornerRadius = UDim.new(0, 8)

local frame = Instance.new("Frame", gui)
frame.Size = CHAT_SIZE
frame.Position = UDim2.new(0, 8, 0, 48)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.Visible = false
frame.ClipsDescendants = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local drag = Instance.new("TextButton", frame)
drag.Size = UDim2.new(1, 0, 0, 6)
drag.BackgroundTransparency = 1
drag.Text = ""
drag.ZIndex = 100

local dragging, dragStart, startPos
drag.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.Changed:Wait()
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(60, 60, 60)
stroke.Thickness = 1

local messages = Instance.new("ScrollingFrame", frame)
messages.Size = UDim2.new(1, -12, 1, -44)
messages.Position = UDim2.new(0, 6, 0, 6)
messages.CanvasSize = UDim2.new(0, 0, 0, 0)
messages.ScrollBarThickness = 3
messages.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
messages.BackgroundTransparency = 1
messages.BorderSizePixel = 0
messages.AutomaticCanvasSize = Enum.AutomaticSize.Y
messages.ScrollingDirection = Enum.ScrollingDirection.Y
messages.ElasticBehavior = Enum.ElasticBehavior.Never

local layout = Instance.new("UIListLayout", messages)
layout.Padding = UDim.new(0, 4)
layout.SortOrder = Enum.SortOrder.LayoutOrder

local padding = Instance.new("UIPadding", messages)
padding.PaddingTop = UDim.new(0, 4)
padding.PaddingBottom = UDim.new(0, 4)
padding.PaddingLeft = UDim.new(0, 4)
padding.PaddingRight = UDim.new(0, 4)

messages:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
    local offset = layout.AbsoluteContentSize.Y - messages.AbsoluteSize.Y
    autoScroll = math.abs(messages.CanvasPosition.Y - offset) < 6
end)

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    if autoScroll then
        messages.CanvasPosition = Vector2.new(0, math.max(0, layout.AbsoluteContentSize.Y - messages.AbsoluteSize.Y))
    end
end)

local inputContainer = Instance.new("Frame", frame)
inputContainer.Size = UDim2.new(1, -12, 0, 30)
inputContainer.Position = UDim2.new(0, 6, 1, -36)
inputContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
inputContainer.BorderSizePixel = 0
Instance.new("UICorner", inputContainer).CornerRadius = UDim.new(0, 8)

local box = Instance.new("TextBox", inputContainer)
box.Size = UDim2.new(1, -42, 1, 0)
box.Position = UDim2.new(0, 8, 0, 0)
box.BackgroundTransparency = 1
box.PlaceholderText = "Type a message..."
box.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
box.Text = ""
box.TextColor3 = Color3.new(1, 1, 1)
box.Font = Enum.Font.Gotham
box.TextSize = 13
box.TextXAlignment = Enum.TextXAlignment.Left
box.ClearTextOnFocus = false

local sendBtn = Instance.new("TextButton", inputContainer)
sendBtn.Size = UDim2.new(0, 30, 0, 24)
sendBtn.Position = UDim2.new(1, -27, 0.5, 0)
sendBtn.AnchorPoint = Vector2.new(1, 0.5)
sendBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
sendBtn.Text = "➤"
sendBtn.TextSize = 14
sendBtn.TextColor3 = Color3.new(1,1,1)
sendBtn.Font = Enum.Font.GothamBold
sendBtn.BorderSizePixel = 0
Instance.new("UICorner", sendBtn).CornerRadius = UDim.new(0, 6)

local function addMessage(user, msg)
    if muted[user] then return end

    local discord = isDiscord(user)
    local displayName = cleanName(user)
    local color = discord and DISCORD_COLOR or getColor(user)
    local isSelf = user == LocalPlayer.Name

    if isSelf then displayName = displayName .. " (you)" end
    if discord then displayName = "[D] " .. displayName end

    local container = Instance.new("Frame", messages)
    container.Size = UDim2.new(1, 0, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.BackgroundTransparency = 1

    messageCount += 1
    container.LayoutOrder = messageCount

    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(1, 0, 0, 0)
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.BackgroundTransparency = 1
    label.RichText = true
    label.TextColor3 = Color3.fromRGB(230, 230, 230)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left

    label.Text = string.format('<font color="%s"><b>%s:</b></font> %s', toHex(color), displayName, msg)

    label.TextTransparency = 1
    TweenService:Create(label, TweenInfo.new(0.1), {TextTransparency = 0}):Play()

    local clicks = 0
    label.MouseButton1Click:Connect(function()
        clicks += 1
        local thisClick = clicks
        task.delay(0.3, function()
            if clicks == thisClick then
                muted[user] = not muted[user]
                warn(muted[user] and "Muted "..user or "Unmuted "..user)
            elseif clicks >= 2 then
                setclipboard(msg)
                warn("Message copied")
            end
            clicks = 0
        end)
    end)

    table.insert(messageQueue, container)
    if #messageQueue > MAX_MESSAGES then
        local old = table.remove(messageQueue, 1)
        if old and old.Parent then old:Destroy() end
    end
end

local function getHead(char)
    if not char then return nil end
    return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
end

local function createBubble(head, text)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ChatBubble"
    billboard.Size = UDim2.new(0, 0, 0, 0)
    billboard.SizeOffset = Vector2.new(0, 0)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 60
    billboard.Adornee = head
    billboard.Parent = head

    local bubble = Instance.new("Frame", billboard)
    bubble.Size = UDim2.new(0, 0, 0, 0)
    bubble.AutomaticSize = Enum.AutomaticSize.XY
    bubble.Position = UDim2.new(0.5, 0, 1, 0)
    bubble.AnchorPoint = Vector2.new(0.5, 1)
    bubble.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    bubble.BorderSizePixel = 0
    Instance.new("UICorner", bubble).CornerRadius = UDim.new(0, 14)
    Instance.new("UIStroke", bubble).Thickness = 1

    local pad = Instance.new("UIPadding", bubble)
    pad.PaddingTop = UDim.new(0, 7)
    pad.PaddingBottom = UDim.new(0, 7)
    pad.PaddingLeft = UDim.new(0, 11)
    pad.PaddingRight = UDim.new(0, 11)

    local txt = Instance.new("TextLabel", bubble)
    txt.Size = UDim2.new(0, 0, 0, 0)
    txt.AutomaticSize = Enum.AutomaticSize.XY
    txt.BackgroundTransparency = 1
    txt.Text = text
    txt.TextColor3 = Color3.fromRGB(240, 240, 240)
    txt.Font = Enum.Font.GothamMedium
    txt.TextSize = 14

    local constraint = Instance.new("UISizeConstraint", txt)
    constraint.MaxSize = Vector2.new(350, 900)

    bubble.BackgroundTransparency = 1
    txt.TextTransparency = 1
    TweenService:Create(bubble, TweenInfo.new(0.15, Enum.EasingStyle.Back), {BackgroundTransparency = 0}):Play()
    TweenService:Create(txt, TweenInfo.new(0.15), {TextTransparency = 0}):Play()

    return billboard, bubble
end

local function showBubble(playerName, text)
    if not bubblesEnabled then return end
    local player = Players:FindFirstChild(playerName)
    if not player or not player.Character then return end

    local head = getHead(player.Character)
    if not head then return end

    if not playerBubbles[playerName] then playerBubbles[playerName] = {} end
    local bubbles = playerBubbles[playerName]

    while #bubbles >= 4 do
        local old = table.remove(bubbles, 1)
        if old and old.Parent then old:Destroy() end
    end

    for i, b in ipairs(bubbles) do
        if b and b.Parent then
            TweenService:Create(b, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {StudsOffset = b.StudsOffset + Vector3.new(0, 1.35, 0)}):Play()
        end
    end

    local billboard, bubble = createBubble(head, text)
    table.insert(bubbles, billboard)

    local lifetime = 2.8 + (#text / 23)
    task.delay(lifetime, function()
        for i, b in ipairs(bubbles) do
            if b == billboard then table.remove(bubbles, i) break end
        end
        if billboard and billboard.Parent then
            TweenService:Create(bubble, TweenInfo.new(0.15), {BackgroundTransparency = 1, Size = UDim2.new(0,0,0,0)}):Play()
            task.delay(0.15, function() billboard:Destroy() end)
        end
    end)
end

local function send(text)
    if text == "" then return end
    if tick() - lastSent < 0.7 then return end

    if text:sub(1,5) == "/room" then
        currentRoom = text:sub(7):gsub("%s", "")
        lastId = 0
        messageCount = 0
        for _, v in ipairs(messageQueue) do v:Destroy() end
        table.clear(messageQueue)
        warn("Joined room: "..currentRoom)
        box.Text = ""
        return
    end

    if text == "/public" then
        currentRoom = "public"
        lastId = 0
        messageCount = 0
        for _, v in ipairs(messageQueue) do v:Destroy() end
        table.clear(messageQueue)
        warn("Returned to public chat")
        box.Text = ""
        return
    end

    lastSent = tick()
    text = text:sub(1, 250)

    showBubble(LocalPlayer.Name, text)
    box.Text = ""

    task.spawn(function()
        pcall(function()
            request({
                Url = API_URL,
                Method = "POST",
                Headers = HEADERS,
                Body = HttpService:JSONEncode({
                    username = LocalPlayer.Name,
                    message = text,
                    room = currentRoom
                })
            })
        end)
    end)
end

box.FocusLost:Connect(function(enter)
    if enter and box.Text ~= "" then send(box.Text) end
end)

sendBtn.MouseButton1Click:Connect(function()
    send(box.Text)
end)

task.spawn(function()
    pcall(function()
        local res = request({
            Url = API_URL .. "?select=*&room=eq."..currentRoom.."&order=id.desc&limit=50",
            Method = "GET",
            Headers = HEADERS
        })

        if res and res.Body then
            local data = HttpService:JSONDecode(res.Body)
            if type(data) == "table" then
                for i = #data, 1, -1 do
                    local v = data[i]
                    if v.id then
                        addMessage(v.username, v.message)
                        if v.id > lastId then lastId = v.id end
                    end
                end
            end
        end
    end)

    while task.wait(0.38) do
        pcall(function()
            local res = request({
                Url = API_URL .. "?select=*&room=eq."..currentRoom.."&order=id.asc&limit=50&id=gt." .. lastId,
                Method = "GET",
                Headers = HEADERS
            })

            if not res or not res.Body then return end

            local data = HttpService:JSONDecode(res.Body)
            if type(data) ~= "table" then return end

            for _, v in ipairs(data) do
                if v.id and v.id > lastId then
                    lastId = v.id

                    addMessage(v.username, v.message)

                    if not isDiscord(v.username) and v.username ~= LocalPlayer.Name then
                        showBubble(v.username, v.message)
                    end
                end
            end
        end)
    end
end)

toggleBtn.MouseButton1Click:Connect(function()
    isOpen = not isOpen

    if isOpen then
        frame.Visible = true
        frame.Size = UDim2.new(0, 0, 0, 0)
        frame.BackgroundTransparency = 1
        TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
            Size = CHAT_SIZE,
            BackgroundTransparency = 0.15
        }):Play()
        toggleBtn.Text = "X"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
    else
        TweenService:Create(frame, TweenInfo.new(0.15), {
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1
        }):Play()
        toggleBtn.Text = "C"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        task.delay(0.15, function() frame.Visible = false end)
    end
end)

bubbleToggle.MouseButton1Click:Connect(function()
    bubblesEnabled = not bubblesEnabled
    if bubblesEnabled then
        bubbleToggle.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
        bubbleToggle.Text = "💬"
    else
        bubbleToggle.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
        bubbleToggle.Text = "🔇"
        for _, bubbles in pairs(playerBubbles) do
            for _, b in bubbles do if b and b.Parent then b:Destroy() end
        end end
        table.clear(playerBubbles)
    end
end)

local function setupPlayer(plr)
    plr.CharacterAdded:Connect(function()
        playerBubbles[plr.Name] = {}
    end)
end

for _, p in ipairs(Players:GetPlayers()) do setupPlayer(p) end
Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(plr)
    local bubbles = playerBubbles[plr.Name]
    if bubbles then
        for _, b in ipairs(bubbles) do
            if b and b.Parent then b:Destroy() end
        end
    end
    playerBubbles[plr.Name] = nil
    userColors[plr.Name] = nil
    muted[plr.Name] = nil
end)

print("✅ Pro Chat v14 Loaded")
