-- 💬 Supabase Mini Chat v2 (Final)

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local PROJECT_URL = "https://fzkxotptuhmhkuhnsoav.supabase.co"
local ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ6a3hvdHB0dWhtaGt1aG5zb2F2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkyNTQ1OTYsImV4cCI6MjA5NDgzMDU5Nn0.etgvcKzEo89I_nvhB_EyLUbVgbV-gHgBJbW_NjNM7wo"

-- 🌐 تحديد دالة الطلبات حسب الـ Executor
local request = http_request or request or (syn and syn.request) or (fluxus and fluxus.request)
if not request then
    warn("❌ الـ Executor لا يدعم HTTP Requests")
    return
end

-- 🧹 احذف القديم
if CoreGui:FindFirstChild("MiniChat") then
    CoreGui.MiniChat:Destroy()
end

-- 🎨 GUI
local gui = Instance.new("ScreenGui")
gui.Name = "MiniChat"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = CoreGui

-- 🔘 زر الفتح/الإغلاق
local toggleBtn = Instance.new("TextButton", gui)
toggleBtn.Size = UDim2.new(0, 45, 0, 45)
toggleBtn.Position = UDim2.new(0, 15, 0.5, -22)
toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 120)
toggleBtn.BackgroundTransparency = 0.3
toggleBtn.Text = "💬"
toggleBtn.TextSize = 20
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.BorderSizePixel = 0
toggleBtn.AutoButtonColor = false
toggleBtn.Active = true
toggleBtn.Draggable = true
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)
local btnStroke = Instance.new("UIStroke", toggleBtn)
btnStroke.Color = Color3.fromRGB(150, 150, 255)
btnStroke.Transparency = 0.4

-- 🪟 إطار الشات
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 250, 0, 280)
frame.Position = UDim2.new(0, 70, 0.5, -140)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
frame.BackgroundTransparency = 0.25
frame.BorderSizePixel = 0
frame.Visible = false
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
local frameStroke = Instance.new("UIStroke", frame)
frameStroke.Color = Color3.fromRGB(100, 100, 200)
frameStroke.Transparency = 0.5

-- 🔝 الهيدر
local header = Instance.new("Frame", frame)
header.Size = UDim2.new(1, 0, 0, 28)
header.BackgroundColor3 = Color3.fromRGB(50, 50, 90)
header.BackgroundTransparency = 0.3
header.BorderSizePixel = 0
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1, -30, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "💬 الدردشة"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 12
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left

local closeBtn = Instance.new("TextButton", header)
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -26, 0, 2)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold

-- 💬 منطقة الرسائل
local messages = Instance.new("ScrollingFrame", frame)
messages.Size = UDim2.new(1, -10, 1, -70)
messages.Position = UDim2.new(0, 5, 0, 33)
messages.CanvasSize = UDim2.new(0, 0, 0, 0)
messages.ScrollBarThickness = 3
messages.ScrollBarImageColor3 = Color3.fromRGB(120, 120, 200)
messages.BackgroundTransparency = 1
messages.BorderSizePixel = 0
messages.AutomaticCanvasSize = Enum.AutomaticSize.Y

local layout = Instance.new("UIListLayout", messages)
layout.Padding = UDim.new(0, 4)

local pad = Instance.new("UIPadding", messages)
pad.PaddingTop = UDim.new(0, 4)
pad.PaddingBottom = UDim.new(0, 4)
pad.PaddingLeft = UDim.new(0, 4)
pad.PaddingRight = UDim.new(0, 4)

-- ⌨️ صندوق الكتابة
local inputBg = Instance.new("Frame", frame)
inputBg.Size = UDim2.new(1, -10, 0, 30)
inputBg.Position = UDim2.new(0, 5, 1, -34)
inputBg.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
inputBg.BackgroundTransparency = 0.2
inputBg.BorderSizePixel = 0
Instance.new("UICorner", inputBg).CornerRadius = UDim.new(0, 8)

local box = Instance.new("TextBox", inputBg)
box.Size = UDim2.new(1, -10, 1, 0)
box.Position = UDim2.new(0, 8, 0, 0)
box.BackgroundTransparency = 1
box.PlaceholderText = "اكتب هنا... 😊"
box.PlaceholderColor3 = Color3.fromRGB(150, 150, 180)
box.Text = ""
box.TextColor3 = Color3.new(1, 1, 1)
box.Font = Enum.Font.GothamMedium
box.TextSize = 12
box.TextXAlignment = Enum.TextXAlignment.Right
box.ClearTextOnFocus = false

-- 🎨 ألوان عشوائية لكل لاعب
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

-- ➕ إضافة رسالة للواجهة
local function addMessage(user, msg)
    local isMe = user == LocalPlayer.Name
    
    local container = Instance.new("Frame", messages)
    container.Size = UDim2.new(1, -8, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.BackgroundColor3 = isMe and Color3.fromRGB(60, 50, 130) or Color3.fromRGB(40, 40, 60)
    container.BackgroundTransparency = 0.3
    container.BorderSizePixel = 0
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)
    
    local p = Instance.new("UIPadding", container)
    p.PaddingTop = UDim.new(0, 4)
    p.PaddingBottom = UDim.new(0, 4)
    p.PaddingLeft = UDim.new(0, 6)
    p.PaddingRight = UDim.new(0, 6)
    
    local nameLbl = Instance.new("TextLabel", container)
    nameLbl.Size = UDim2.new(1, 0, 0, 14)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = isMe and "أنت ✨" or user
    nameLbl.TextColor3 = getColor(user)
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = 11
    nameLbl.TextXAlignment = Enum.TextXAlignment.Right
    
    local msgLbl = Instance.new("TextLabel", container)
    msgLbl.Size = UDim2.new(1, 0, 0, 0)
    msgLbl.Position = UDim2.new(0, 0, 0, 16)
    msgLbl.AutomaticSize = Enum.AutomaticSize.Y
    msgLbl.BackgroundTransparency = 1
    msgLbl.Text = msg
    msgLbl.TextColor3 = Color3.fromRGB(240, 240, 255)
    msgLbl.Font = Enum.Font.GothamMedium
    msgLbl.TextSize = 12
    msgLbl.TextWrapped = true
    msgLbl.TextXAlignment = Enum.TextXAlignment.Right
    msgLbl.RichText = true
    
    container.BackgroundTransparency = 1
    nameLbl.TextTransparency = 1
    msgLbl.TextTransparency = 1
    TweenService:Create(container, TweenInfo.new(0.3), {BackgroundTransparency = 0.3}):Play()
    TweenService:Create(nameLbl, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
    TweenService:Create(msgLbl, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
    
    task.wait(0.05)
    messages.CanvasPosition = Vector2.new(0, messages.AbsoluteCanvasSize.Y)
end

-- 📤 إرسال رسالة
local function sendMessage(text)
    if text == "" then return end
    
    local data = {
        username = LocalPlayer.Name,
        message = text
    }
    
    task.spawn(function()
        local ok, err = pcall(function()
            local res = request({
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
            print("📤 SEND:", res.StatusCode)
        end)
        if not ok then
            warn("❌ خطأ بالإرسال:", err)
        end
    end)
end

box.FocusLost:Connect(function(enter)
    if enter and box.Text ~= "" then
        sendMessage(box.Text)
        box.Text = ""
    end
end)

-- 🔄 جلب الرسائل
local lastIds = {}
task.spawn(function()
    while task.wait(2) do
        local ok, err = pcall(function()
            local response = request({
                Url = PROJECT_URL .. "/rest/v1/chat_messages?select=*&order=created_at.asc&limit=30",
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
                        if v.id and not lastIds[v.id] then
                            lastIds[v.id] = true
                            addMessage(v.username, v.message)
                        end
                    end
                end
            end
        end)
        if not ok then
            warn("❌ خطأ بالجلب:", err)
        end
    end
end)

-- 🎬 فتح وإغلاق
local isOpen = false
local function toggle()
    isOpen = not isOpen
    
    if isOpen then
        frame.Visible = true
        frame.Size = UDim2.new(0, 0, 0, 0)
        TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 250, 0, 280)
        }):Play()
        toggleBtn.Text = "✕"
    else
        TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
            Size = UDim2.new(0, 0, 0, 0)
        }):Play()
        toggleBtn.Text = "💬"
        task.wait(0.25)
        frame.Visible = false
    end
end

toggleBtn.MouseButton1Click:Connect(toggle)
closeBtn.MouseButton1Click:Connect(toggle)

print("✅ Mini Chat Loaded — اضغط على زر 💬")
