-- Pro Chat v13 - Optimized & Clean

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local API_URL = "https://fzkxotptuhmhkuhnsoav.supabase.co/rest/v1/chat_messages"
local API_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ6a3hvdHB0dWhtaGt1aG5zb2F2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkyNTQ1OTYsImV4cCI6MjA5NDgzMDU5Nn0.etgvcKzEo89I_nvhB_EyLUbVgbV-gHgBJbW_NjNM7wo"
local HEADERS = {
    ["apikey"] = API_KEY,
    ["Authorization"] = "Bearer " .. API_KEY,
    ["Content-Type"] = "application/json"
}

local request = http_request or request or (syn and syn.request) or (fluxus and fluxus.request)
if not request then warn("HTTP not supported") return end

if CoreGui:FindFirstChild("ProChat") then CoreGui.ProChat:Destroy() end

-- ══════════════════════════════════════
--              ثوابت
-- ══════════════════════════════════════

local CHAT_SIZE = UDim2.new(0.32, 0, 0.28, 0)
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

local userColors = {}
local shownIds = {}
local playerBubbles = {}
local firstLoad = true
local lastSent = 0
local isOpen = false

-- ══════════════════════════════════════
--              دوال مساعدة
-- ══════════════════════════════════════

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

-- ══════════════════════════════════════
--              GUI
-- ══════════════════════════════════════

local gui = Instance.new("ScreenGui")
gui.Name = "ProChat"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = CoreGui

-- زر التبديل
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

-- النافذة الرئيسية
local frame = Instance.new("Frame", gui)
frame.Size = CHAT_SIZE
frame.Position = UDim2.new(0, 8, 0, 48)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.Visible = false
frame.ClipsDescendants = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

-- حدود خفيفة
local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(60, 60, 60)
stroke.Thickness = 1

-- قائمة الرسائل
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

-- صندوق الكتابة
local inputContainer = Instance.new("Frame", frame)
inputContainer.Size = UDim2.new(1, -12, 0, 30)
inputContainer.Position = UDim2.new(0, 6, 1, -36)
inputContainer.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
inputContainer.BorderSizePixel = 0
Instance.new("UICorner", inputContainer).CornerRadius = UDim.new(0, 8)

local box = Instance.new("TextBox", inputContainer)
box.Size = UDim2.new(1, -16, 1, 0)
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
box.ClipsDescendants = true

-- ══════════════════════════════════════
--         إضافة رسالة للشات
-- ══════════════════════════════════════

local function addMessage(user, msg)
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
    container.LayoutOrder = #messages:GetChildren()

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

    -- أنيميشن سريع
    label.TextTransparency = 1
    TweenService:Create(label, TweenInfo.new(0.1), {TextTransparency = 0}):Play()

    -- سكرول للأسفل
    task.defer(function()
        messages.CanvasPosition = Vector2.new(0, messages.AbsoluteCanvasSize.Y)
    end)
end

-- ══════════════════════════════════════
--         فقاعات الشات
-- ══════════════════════════════════════

local function getHead(char)
    return char and (char:FindFirstChild("Head") or char:FindFirstChildWhichIsA("BasePart"))
end

local function createBubble(head, text)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ChatBubble"
    billboard.Size = UDim2.new(0, 180, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 50
    billboard.Adornee = head
    billboard.Parent = head

    local bubble = Instance.new("Frame", billboard)
    bubble.Size = UDim2.new(0, 0, 0, 0)
    bubble.AutomaticSize = Enum.AutomaticSize.XY
    bubble.Position = UDim2.new(0.5, 0, 1, 0)
    bubble.AnchorPoint = Vector2.new(0.5, 1)
    bubble.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    bubble.BorderSizePixel = 0
    Instance.new("UICorner", bubble).CornerRadius = UDim.new(0, 14)

    local pad = Instance.new("UIPadding", bubble)
    pad.PaddingTop = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.PaddingLeft = UDim.new(0, 12)
    pad.PaddingRight = UDim.new(0, 12)

    local txt = Instance.new("TextLabel", bubble)
    txt.Size = UDim2.new(0, 0, 0, 0)
    txt.AutomaticSize = Enum.AutomaticSize.XY
    txt.BackgroundTransparency = 1
    txt.Text = text
    txt.TextColor3 = Color3.fromRGB(20, 20, 20)
    txt.Font = Enum.Font.GothamMedium
    txt.TextSize = 14
    txt.TextWrapped = true
    txt.RichText = true

    local constraint = Instance.new("UISizeConstraint", txt)
    constraint.MaxSize = Vector2.new(150, 100)

    -- أنيميشن دخول
    bubble.BackgroundTransparency = 1
    txt.TextTransparency = 1
    TweenService:Create(bubble, TweenInfo.new(0.15, Enum.EasingStyle.Back), {BackgroundTransparency = 0}):Play()
    TweenService:Create(txt, TweenInfo.new(0.15), {TextTransparency = 0}):Play()

    return billboard, bubble, txt
end

local function showBubble(playerName, text)
    local player = Players:FindFirstChild(playerName)
    if not player or not player.Character then return end

    local head = getHead(player.Character)
    if not head then return end

    -- إزالة الفقاعات القديمة
    if not playerBubbles[playerName] then playerBubbles[playerName] = {} end
    local bubbles = playerBubbles[playerName]

    while #bubbles >= 3 do
        local old = table.remove(bubbles, 1)
        if old and old.Parent then
            TweenService:Create(old, TweenInfo.new(0.1), {Size = UDim2.new(0, 0, 0, 0)}):Play()
            task.delay(0.1, function() old:Destroy() end)
        end
    end

    local billboard = createBubble(head, text)
    table.insert(bubbles, billboard)

    -- إزالة بعد 4 ثواني
    task.delay(4, function()
        for i, b in ipairs(bubbles) do
            if b == billboard then
                table.remove(bubbles, i)
                break
            end
        end
        if billboard and billboard.Parent then
            local bubble = billboard:FindFirstChild("Frame") or billboard:FindFirstChildWhichIsA("Frame")
            if bubble then
                TweenService:Create(bubble, TweenInfo.new(0.15), {BackgroundTransparency = 1}):Play()
            end
            task.delay(0.15, function() billboard:Destroy() end)
        end
    end)
end

-- ══════════════════════════════════════
--         إرسال رسالة
-- ══════════════════════════════════════

local function send(text)
    if text == "" then return end
    if tick() - lastSent < 0.8 then return end

    lastSent = tick()
    text = text:sub(1, 200)

    showBubble(LocalPlayer.Name, text)

    task.spawn(function()
        pcall(function()
            request({
                Url = API_URL,
                Method = "POST",
                Headers = HEADERS,
                Body = HttpService:JSONEncode({
                    username = LocalPlayer.Name,
                    message = text
                })
            })
        end)
    end)
end

box.FocusLost:Connect(function(enter)
    if enter and box.Text ~= "" then
        send(box.Text)
        box.Text = ""
    end
end)

-- ══════════════════════════════════════
--         استقبال الرسائل
-- ══════════════════════════════════════

task.spawn(function()
    while task.wait(0.4) do
        pcall(function()
            local res = request({
                Url = API_URL .. "?select=*&order=id.asc&limit=40",
                Method = "GET",
                Headers = HEADERS
            })

            if not res or not res.Body then return end

            local data = HttpService:JSONDecode(res.Body)
            if type(data) ~= "table" then return end

            for _, v in ipairs(data) do
                if v.id and not shownIds[v.id] then
                    shownIds[v.id] = true

                    addMessage(v.username, v.message)

                    -- فقاعة فقط للاعبين في روبلوكس (مو ديسكورد)
                    if not firstLoad and not isDiscord(v.username) and v.username ~= LocalPlayer.Name then
                        showBubble(v.username, v.message)
                    end
                end
            end

            firstLoad = false
        end)
    end
end)

-- ══════════════════════════════════════
--         زر الفتح والإغلاق
-- ══════════════════════════════════════

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

-- ══════════════════════════════════════
--         تجهيز اللاعبين
-- ══════════════════════════════════════

local function setupPlayer(plr)
    plr.CharacterAdded:Connect(function()
        playerBubbles[plr.Name] = {}
    end)
end

for _, p in ipairs(Players:GetPlayers()) do setupPlayer(p) end
Players.PlayerAdded:Connect(setupPlayer)

print("Pro Chat v13 Loaded")
