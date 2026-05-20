-- 💬 Supabase Pro Chat v9 (Locked Above Head)

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

-- ====================================================
-- 🎨 GUI
-- ====================================================

local gui = Instance.new("ScreenGui")
gui.Name = "ProChat"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = CoreGui

-- 🔘 زر الشات (أكثر يمين)
local toggleBtn = Instance.new("TextButton", gui)
toggleBtn.Size = UDim2.new(0, 32, 0, 32)
toggleBtn.Position = UDim2.new(0, 180, 0, 5)  -- ⬅️ أكثر يمين
toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 90)
toggleBtn.BackgroundTransparency = 0.3
toggleBtn.Text = "💬"
toggleBtn.TextSize = 14
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.BorderSizePixel = 0
toggleBtn.AutoButtonColor = false
toggleBtn.ZIndex = 10
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)
local btnStroke = Instance.new("UIStroke", toggleBtn)
btnStroke.Color = Color3.fromRGB(120, 120, 220)
btnStroke.Transparency = 0.5

-- 🪟 صندوق الشات
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0.25, 0, 0.28, 0)
frame.Position = UDim2.new(0, 5, 0, 45)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
frame.BackgroundTransparency = 0.4
frame.BorderSizePixel = 0
frame.Visible = false
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local sizeMin = Instance.new("UISizeConstraint", frame)
sizeMin.MinSize = Vector2.new(220, 160)
sizeMin.MaxSize = Vector2.new(340, 260)

local frameStroke = Instance.new("UIStroke", frame)
frameStroke.Color = Color3.fromRGB(100, 100, 200)
frameStroke.Transparency = 0.6

local messages = Instance.new("ScrollingFrame", frame)
messages.Size = UDim2.new(1, -6, 1, -36)
messages.Position = UDim2.new(0, 3, 0, 3)
messages.CanvasSize = UDim2.new(0, 0, 0, 0)
messages.ScrollBarThickness = 2
messages.ScrollBarImageColor3 = Color3.fromRGB(120, 120, 200)
messages.BackgroundTransparency = 1
messages.BorderSizePixel = 0
messages.AutomaticCanvasSize = Enum.AutomaticSize.Y

local layout = Instance.new("UIListLayout", messages)
layout.Padding = UDim.new(0, 2)

local pad = Instance.new("UIPadding", messages)
pad.PaddingTop = UDim.new(0, 3)
pad.PaddingBottom = UDim.new(0, 3)
pad.PaddingLeft = UDim.new(0, 3)
pad.PaddingRight = UDim.new(0, 3)

local inputBg = Instance.new("Frame", frame)
inputBg.Size = UDim2.new(1, -6, 0, 26)
inputBg.Position = UDim2.new(0, 3, 1, -29)
inputBg.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
inputBg.BackgroundTransparency = 0.25
inputBg.BorderSizePixel = 0
Instance.new("UICorner", inputBg).CornerRadius = UDim.new(0, 6)

local box = Instance.new("TextBox", inputBg)
box.Size = UDim2.new(1, -8, 1, 0)
box.Position = UDim2.new(0, 6, 0, 0)
box.BackgroundTransparency = 1
box.PlaceholderText = "اكتب... 😊"
box.PlaceholderColor3 = Color3.fromRGB(140, 140, 170)
box.Text = ""
box.TextColor3 = Color3.new(1, 1, 1)
box.Font = Enum.Font.GothamMedium
box.TextSize = 11
box.TextXAlignment = Enum.TextXAlignment.Right
box.ClearTextOnFocus = false

local userColors = {}
local palette = {
    Color3.fromRGB(255, 120, 120),
    Color3.fromRGB(120, 200, 255),
    Color3.fromRGB(180, 255, 130),
    Color3.fromRGB(255, 200, 120),
    Color3.fromRGB(220, 140, 255),
    Color3.fromRGB(255, 150, 220),
    Color3.fromRGB(140, 255, 230),
}
local function getColor(name)
    if not userColors[name] then
        userColors[name] = palette[math.random(1, #palette)]
    end
    return userColors[name]
end

local function addMessage(user, msg)
    local isMe = user == LocalPlayer.Name
    
    local container = Instance.new("Frame", messages)
    container.Size = UDim2.new(1, -6, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.BackgroundColor3 = isMe and Color3.fromRGB(60, 50, 130) or Color3.fromRGB(40, 40, 60)
    container.BackgroundTransparency = 0.3
    container.BorderSizePixel = 0
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 5)
    
    local p = Instance.new("UIPadding", container)
    p.PaddingTop = UDim.new(0, 2)
    p.PaddingBottom = UDim.new(0, 2)
    p.PaddingLeft = UDim.new(0, 5)
    p.PaddingRight = UDim.new(0, 5)
    
    local nameLbl = Instance.new("TextLabel", container)
    nameLbl.Size = UDim2.new(1, 0, 0, 11)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = isMe and "أنت ✨" or user
    nameLbl.TextColor3 = getColor(user)
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 9
    nameLbl.TextXAlignment = Enum.TextXAlignment.Right
    
    local msgLbl = Instance.new("TextLabel", container)
    msgLbl.Size = UDim2.new(1, 0, 0, 0)
    msgLbl.Position = UDim2.new(0, 0, 0, 12)
    msgLbl.AutomaticSize = Enum.AutomaticSize.Y
    msgLbl.BackgroundTransparency = 1
    msgLbl.Text = msg
    msgLbl.TextColor3 = Color3.fromRGB(240, 240, 255)
    msgLbl.Font = Enum.Font.GothamMedium
    msgLbl.TextSize = 10
    msgLbl.TextWrapped = true
    msgLbl.TextXAlignment = Enum.TextXAlignment.Right
    msgLbl.RichText = true
    
    container.BackgroundTransparency = 1
    nameLbl.TextTransparency = 1
    msgLbl.TextTransparency = 1
    TweenService:Create(container, TweenInfo.new(0.12), {BackgroundTransparency = 0.3}):Play()
    TweenService:Create(nameLbl, TweenInfo.new(0.12), {TextTransparency = 0}):Play()
    TweenService:Create(msgLbl, TweenInfo.new(0.12), {TextTransparency = 0}):Play()
    
    task.wait(0.01)
    messages.CanvasPosition = Vector2.new(0, messages.AbsoluteCanvasSize.Y)
end

-- ====================================================
-- 🎈 الفقاعة (مقفلة فوق الراس)
-- ====================================================

local playerBubbles = {}

local function findHead(character)
    if not character then return nil end
    
    local head = character:FindFirstChild("Head") 
                or character:FindFirstChild("head")
                or character:FindFirstChild("HEAD")
    
    if head and head:IsA("BasePart") then
        return head
    end
    
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
    
    local existing = head:FindFirstChild("ProChatBillboard")
    if existing then return existing end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ProChatBillboard"
    billboard.Size = UDim2.new(0, 220, 0, 180)
    
    -- 🔑 الحل: StudsOffset فقط (ثابت دائماً بالنسبة للراس)
    -- نحسب نص ارتفاع الراس + 1.5 للتفاوت
    local headHeight = head.Size.Y
    billboard.StudsOffset = Vector3.new(0, headHeight + 1.5, 0)
    
    -- ❌ لا نستخدم ExtentsOffset (هذا اللي يخلي الفقاعة "تطفو")
    -- ❌ لا نستخدم StudsOffsetWorldSpace
    
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 200
    billboard.ResetOnSpawn = false
    billboard.Adornee = head
    billboard.Parent = head
    
    local container = Instance.new("Frame", billboard)
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Name = "Container"
    
    local list = Instance.new("UIListLayout", container)
    list.Padding = UDim.new(0, 3)
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
    Instance.new("UICorner", bubble).CornerRadius = UDim.new(0, 10)
    
    local stroke = Instance.new("UIStroke", bubble)
    stroke.Color = Color3.fromRGB(180, 180, 200)
    stroke.Thickness = 1
    stroke.Transparency = 0.4
    
    local p = Instance.new("UIPadding", bubble)
    p.PaddingTop = UDim.new(0, 5)
    p.PaddingBottom = UDim.new(0, 5)
    p.PaddingLeft = UDim.new(0, 9)
    p.PaddingRight = UDim.new(0, 9)
    
    local txt = Instance.new("TextLabel", bubble)
    txt.AutomaticSize = Enum.AutomaticSize.XY
    txt.Size = UDim2.new(0, 0, 0, 0)
    txt.BackgroundTransparency = 1
    txt.Text = message
    txt.TextColor3 = Color3.fromRGB(20, 20, 30)
    txt.Font = Enum.Font.GothamMedium
    txt.TextSize = 13
    txt.TextWrapped = true
    txt.RichText = true
    txt.TextXAlignment = Enum.TextXAlignment.Center
    
    local sc = Instance.new("UISizeConstraint", txt)
    sc.MaxSize = Vector2.new(180, math.huge)
    
    bubble.BackgroundTransparency = 1
    txt.TextTransparency = 1
    stroke.Transparency = 1
    
    TweenService:Create(bubble, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.05
    }):Play()
    TweenService:Create(txt, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
    TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 0.4}):Play()
    
    return bubble, txt, stroke
end

local function removeBubble(data)
    if not data or not data.bubble or not data.bubble.Parent then return end
    
    local fadeBg = TweenService:Create(data.bubble, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {BackgroundTransparency = 1})
    local fadeTxt = TweenService:Create(data.txt, TweenInfo.new(0.25), {TextTransparency = 1})
    local fadeStroke = TweenService:Create(data.stroke, TweenInfo.new(0.25), {Transparency = 1})
    
    fadeBg:Play()
    fadeTxt:Play()
    fadeStroke:Play()
    
    fadeBg.Completed:Connect(function()
        if data.bubble then data.bubble:Destroy() end
    end)
end

local function showBubbleAbovePlayer(playerName, message)
    local player = Players:FindFirstChild(playerName)
    if not player or not player.Character then return end
    
    local billboard = getBillboard(player.Character)
    if not billboard then return end
    
    local container = billboard:FindFirstChild("Container")
    if not container then return end
    
    if not playerBubbles[playerName] then
        playerBubbles[playerName] = {}
    end
    
    local bubbleList = playerBubbles[playerName]
    
    if #bubbleList >= 3 then
        local oldest = table.remove(bubbleList, 1)
        removeBubble(oldest)
    end
    
    local bubble, txt, stroke = createBubble(container, message)
    local data = {bubble = bubble, txt = txt, stroke = stroke}
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

-- ====================================================
-- 📤 إرسال واستقبال
-- ====================================================

local function sendMessage(text)
    if text == "" then return end
    
    showBubbleAbovePlayer(LocalPlayer.Name, text)
    
    local data = {
        username = LocalPlayer.Name,
        message = text
    }
    
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
                Url = PROJECT_URL .. "/rest/v1/chat_messages?select=*&order=id.asc&limit=10",
                Method = "GET",
                Headers = {
                    ["apikey"] = ANON_KEY,
                    ["Authorization"] = "Bearer " .. ANON_KEY
                }
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
        TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0.25, 0, 0.28, 0)
        }):Play()
        toggleBtn.Text = "✕"
    else
        TweenService:Create(frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
            Size = UDim2.new(0, 0, 0, 0)
        }):Play()
        toggleBtn.Text = "💬"
        task.wait(0.15)
        frame.Visible = false
    end
end)

print("✅ Pro Chat v9 — Locked Above Head 🔒")
