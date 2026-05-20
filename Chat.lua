-- 💬 Pro Chat v11 - Roblox Style

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local PROJECT_URL = "https://fzkxotptuhmhkuhnsoav.supabase.co"
local ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ6a3hvdHB0dWhtaGt1aG5zb2F2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkyNTQ1OTYsImV4cCI6MjA5NDgzMDU5Nn0.etgvcKzEo89I_nvhB_EyLUbVgbV-gHgBJbW_NjNM7wo"

local request = http_request or request or (syn and syn.request) or (fluxus and fluxus.request)
if not request then warn("❌ Executor لا يدعم HTTP") return end

if CoreGui:FindFirstChild("ProChat") then CoreGui.ProChat:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "ProChat"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = CoreGui

local toggleBtn = Instance.new("TextButton", gui)
toggleBtn.Size = UDim2.new(0, 28, 0, 28)
toggleBtn.Position = UDim2.new(0, 180, 0, 5)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
toggleBtn.BackgroundTransparency = 0.5
toggleBtn.Text = "💬"
toggleBtn.TextSize = 14
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.BorderSizePixel = 0
toggleBtn.AutoButtonColor = false
toggleBtn.ZIndex = 10
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)

local CHAT_SIZE = UDim2.new(0.35, 0, 0.30, 0)

local frame = Instance.new("Frame", gui)
frame.Size = CHAT_SIZE
frame.Position = UDim2.new(0, 5, 0, 38)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BackgroundTransparency = 0.5
frame.BorderSizePixel = 0
frame.Visible = false
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

local messages = Instance.new("ScrollingFrame", frame)
messages.Size = UDim2.new(1, -8, 1, -38)
messages.Position = UDim2.new(0, 4, 0, 4)
messages.CanvasSize = UDim2.new(0, 0, 0, 0)
messages.ScrollBarThickness = 2
messages.ScrollBarImageColor3 = Color3.fromRGB(200, 200, 200)
messages.BackgroundTransparency = 1
messages.BorderSizePixel = 0
messages.AutomaticCanvasSize = Enum.AutomaticSize.Y

local layout = Instance.new("UIListLayout", messages)
layout.Padding = UDim.new(0, 2)

local pad = Instance.new("UIPadding", messages)
pad.PaddingTop = UDim.new(0, 2)
pad.PaddingBottom = UDim.new(0, 2)
pad.PaddingLeft = UDim.new(0, 4)
pad.PaddingRight = UDim.new(0, 4)

local inputBg = Instance.new("Frame", frame)
inputBg.Size = UDim2.new(1, -8, 0, 26)
inputBg.Position = UDim2.new(0, 4, 1, -30)
inputBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
inputBg.BackgroundTransparency = 0.4
inputBg.BorderSizePixel = 0
Instance.new("UICorner", inputBg).CornerRadius = UDim.new(0, 6)

local box = Instance.new("TextBox", inputBg)
box.Size = UDim2.new(1, -12, 1, 0)
box.Position = UDim2.new(0, 8, 0, 0)
box.BackgroundTransparency = 1
box.PlaceholderText = "اكتب رسالة..."
box.PlaceholderColor3 = Color3.fromRGB(180, 180, 180)
box.Text = ""
box.TextColor3 = Color3.new(1, 1, 1)
box.Font = Enum.Font.GothamMedium
box.TextSize = 12
box.TextXAlignment = Enum.TextXAlignment.Right
box.ClearTextOnFocus = false

local userColors = {}
local palette = {
    Color3.fromRGB(255, 100, 100),
    Color3.fromRGB(100, 180, 255),
    Color3.fromRGB(150, 255, 100),
    Color3.fromRGB(255, 180, 80),
    Color3.fromRGB(200, 120, 255),
    Color3.fromRGB(255, 130, 200),
    Color3.fromRGB(100, 255, 210),
}

local function getColor(name)
    if not userColors[name] then
        userColors[name] = palette[math.random(1, #palette)]
    end
    return userColors[name]
end

local function colorToHex(c)
    return string.format("#%02X%02X%02X",
        math.floor(c.R * 255),
        math.floor(c.G * 255),
        math.floor(c.B * 255))
end

-- ✅ رسالة في سطر واحد: BAQR_HS: ارحبوو
local function addMessage(user, msg)
    local color = getColor(user)
    local hex = colorToHex(color)
    local displayName = user == LocalPlayer.Name and (user .. " ✨") or user

    local label = Instance.new("TextLabel", messages)
    label.Size = UDim2.new(1, 0, 0, 0)
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.BackgroundTransparency = 1
    label.RichText = true
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Right
    local displayName = user == LocalPlayer.Name and ("  (" .. user .. ")") or user

label.Text = string.format('%s  <font color="%s"><b>%s</b></font>', msg, hex, displayName)

    label.TextTransparency = 1
    TweenService:Create(label, TweenInfo.new(0.15), {TextTransparency = 0}):Play()

    task.wait(0.01)
    messages.CanvasPosition = Vector2.new(0, messages.AbsoluteCanvasSize.Y)
end

local playerBubbles = {}

local function findHead(character)
    if not character then return nil end
    local head = character:FindFirstChild("Head")
    if head and head:IsA("BasePart") then return head end
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name:lower():find("head") then
            return part
        end
    end
    return nil
end

local function getBillboard(character)
    local head = findHead(character)
    if not head then return nil end

    local old = head:FindFirstChild("ProChatBillboard")
    if old then old:Destroy() end

    local attachment = head:FindFirstChild("ProChatAttachment")
    if not attachment then
        attachment = Instance.new("Attachment")
        attachment.Name = "ProChatAttachment"
        attachment.Position = Vector3.new(0, head.Size.Y / 2, 0)
        attachment.Parent = head
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ProChatBillboard"
    billboard.Size = UDim2.new(0, 200, 0, 150)
    billboard.SizeOffset = Vector2.new(0, 0.5)
    billboard.StudsOffset = Vector3.new(0, 0, 0)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 100
    billboard.ResetOnSpawn = false
    billboard.Adornee = attachment
    billboard.Parent = head

    local container = Instance.new("Frame", billboard)
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Name = "Container"

    local list = Instance.new("UIListLayout", container)
    list.Padding = UDim.new(0, 4)
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center
    list.VerticalAlignment = Enum.VerticalAlignment.Bottom
    list.SortOrder = Enum.SortOrder.LayoutOrder

    return billboard
end

local function createBubble(container, message)
    local bubble = Instance.new("Frame", container)
    bubble.AutomaticSize = Enum.AutomaticSize.XY
    bubble.Size = UDim2.new(0, 0, 0, 0)
    bubble.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    bubble.BackgroundTransparency = 0.05
    bubble.BorderSizePixel = 0
    Instance.new("UICorner", bubble).CornerRadius = UDim.new(0, 12)

    local p = Instance.new("UIPadding", bubble)
    p.PaddingTop = UDim.new(0, 6)
    p.PaddingBottom = UDim.new(0, 6)
    p.PaddingLeft = UDim.new(0, 10)
    p.PaddingRight = UDim.new(0, 10)

    local txt = Instance.new("TextLabel", bubble)
    txt.AutomaticSize = Enum.AutomaticSize.XY
    txt.Size = UDim2.new(0, 0, 0, 0)
    txt.BackgroundTransparency = 1
    txt.Text = message
    txt.TextColor3 = Color3.fromRGB(15, 15, 15)
    txt.Font = Enum.Font.GothamMedium
    txt.TextSize = 14
    txt.TextWrapped = true
    txt.RichText = true
    txt.TextXAlignment = Enum.TextXAlignment.Center

    local sc = Instance.new("UISizeConstraint", txt)
    sc.MaxSize = Vector2.new(160, math.huge)

    bubble.BackgroundTransparency = 1
    txt.TextTransparency = 1

    TweenService:Create(bubble, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0.05}):Play()
    TweenService:Create(txt, TweenInfo.new(0.2), {TextTransparency = 0}):Play()

    return bubble, txt
end

local function removeBubble(data)
    if not data or not data.bubble or not data.bubble.Parent then return end
    local fadeBg = TweenService:Create(data.bubble, TweenInfo.new(0.25), {BackgroundTransparency = 1})
    local fadeTxt = TweenService:Create(data.txt, TweenInfo.new(0.25), {TextTransparency = 1})
    fadeBg:Play() fadeTxt:Play()
    fadeBg.Completed:Connect(function() if data.bubble then data.bubble:Destroy() end end)
end

local function showBubbleAbovePlayer(playerName, message)
    local player = Players:FindFirstChild(playerName)
    if not player or not player.Character then return end

    local billboard = getBillboard(player.Character)
    if not billboard then return end

    local container = billboard:FindFirstChild("Container")
    if not container then return end

    if not playerBubbles[playerName] then playerBubbles[playerName] = {} end
    local bubbleList = playerBubbles[playerName]

    if #bubbleList >= 3 then
        local oldest = table.remove(bubbleList, 1)
        removeBubble(oldest)
    end

    local bubble, txt = createBubble(container, message)
    local data = {bubble = bubble, txt = txt}
    table.insert(bubbleList, data)

    task.delay(5, function()
        for i, v in ipairs(bubbleList) do
            if v == data then
                table.remove(bubbleList, i)
                removeBubble(v)
                break
            end
        end
    end)
end

local function setupPlayer(plr)
    if plr.Character then
        task.spawn(function()
            task.wait(0.3)
            getBillboard(plr.Character)
        end)
    end
    plr.CharacterAdded:Connect(function(char)
        playerBubbles[plr.Name] = {}
        char:WaitForChild("Head", 5)
        task.wait(0.5)
        getBillboard(char)
    end)
end

Players.PlayerAdded:Connect(setupPlayer)
for _, plr in ipairs(Players:GetPlayers()) do
    setupPlayer(plr)
end

local function sendMessage(text)
    if text == "" then return end
    showBubbleAbovePlayer(LocalPlayer.Name, text)
    local data = {username = LocalPlayer.Name, message = text}
    task.spawn(function()
        pcall(function()
            request({
                Url = PROJECT_URL .. "/rest/v1/chat_messages",
                Method = "POST",
                Headers = {
                    ["apikey"] = ANON_KEY,
                    ["Authorization"] = "Bearer " .. ANON_KEY,
                    ["Content-Type"] = "application/json",
                    ["Prefer"] = "return=minimal"
                },
                Body = HttpService:JSONEncode(data)
            })
        end)
    end)
end

box.FocusLost:Connect(function(enter)
    if enter and box.Text ~= "" then
        local txt = box.Text
        box.Text = ""
        sendMessage(txt)
    end
end)

local shownIds = {}
local firstLoad = true

task.spawn(function()
    while task.wait(0.3) do
        pcall(function()
            local response = request({
                Url = PROJECT_URL .. "/rest/v1/chat_messages?select=*&order=id.asc&limit=20",
                Method = "GET",
                Headers = {["apikey"] = ANON_KEY, ["Authorization"] = "Bearer " .. ANON_KEY}
            })
            if response and response.Body then
                local decoded = HttpService:JSONDecode(response.Body)
                if type(decoded) == "table" then
                    for _, v in ipairs(decoded) do
                        if v.id and not shownIds[v.id] then
                            shownIds[v.id] = true
                            addMessage(v.username, v.message)
                            if not firstLoad and v.username ~= LocalPlayer.Name then
                                showBubbleAbovePlayer(v.username, v.message)
                            end
                        end
                    end
                    firstLoad = false
                end
            end
        end)
    end
end)

local isOpen = false
toggleBtn.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    if isOpen then
        frame.Visible = true
        frame.Size = UDim2.new(0, 0, 0, 0)
        TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Size = CHAT_SIZE}):Play()
        toggleBtn.Text = "✕"
    else
        TweenService:Create(frame, TweenInfo.new(0.15), {Size = UDim2.new(0, 0, 0, 0)}):Play()
        toggleBtn.Text = "💬"
        task.wait(0.01)
        frame.Visible = false
    end
end)

print("✅ Pro Chat v11 — Roblox Style")
