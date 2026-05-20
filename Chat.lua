-- ✅ Global Chat v2 | Supabase | Arabic + Emoji Support
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local PROJECT_URL = "https://fzkxotptuhmhkuhnsoav.supabase.co"
local ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ6a3hvdHB0dWhtaGt1aG5zb2F2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkyNTQ1OTYsImV4cCI6MjA5NDgzMDU5Nn0.etgvcKzEo89I_nvhB_EyLUbVgbV-gHgBJbW_NjNM7wo"
local POLL_RATE = 0.8 -- جلب كل 0.8 ثانية
local MAX_MESSAGES = 30 -- حد أقصى للرسائل المعروضة

-- ══════════════════════════════════
--           إزالة القديم
-- ══════════════════════════════════
if CoreGui:FindFirstChild("GlobalChatV2") then
    CoreGui:FindFirstChild("GlobalChatV2"):Destroy()
end

-- ══════════════════════════════════
--              GUI
-- ══════════════════════════════════
local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "GlobalChatV2"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- زر الفتح/الإغلاق
local toggleBtn = Instance.new("TextButton", gui)
toggleBtn.Size = UDim2.new(0, 46, 0, 46)
toggleBtn.Position = UDim2.new(0, 16, 0.5, -23)
toggleBtn.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
toggleBtn.Text = "💬"
toggleBtn.TextSize = 22
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.BorderSizePixel = 0
toggleBtn.ZIndex = 10
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(1, 0)

-- ظل الزر
local btnShadow = Instance.new("UIStroke", toggleBtn)
btnShadow.Color = Color3.fromRGB(80, 120, 255)
btnShadow.Transparency = 0.5
btnShadow.Thickness = 2

-- الإطار الرئيسي
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 280, 0, 340)
frame.Position = UDim2.new(0, 70, 0.5, -170)
frame.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.ClipsDescendants = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 14)

-- حدود متوهجة
local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(80, 120, 255)
stroke.Transparency = 0.6
stroke.Thickness = 1.5

-- شريط العنوان
local titleBar = Instance.new("Frame", frame)
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 55)
titleBar.BackgroundTransparency = 0.2
titleBar.BorderSizePixel = 0

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Size = UDim2.new(1, -10, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "💬 Global Chat"
titleLabel.TextColor3 = Color3.fromRGB(180, 200, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 13
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- نقطة الحالة (online indicator)
local dot = Instance.new("Frame", titleBar)
dot.Size = UDim2.new(0, 8, 0, 8)
dot.Position = UDim2.new(1, -20, 0.5, -4)
dot.BackgroundColor3 = Color3.fromRGB(80, 255, 120)
dot.BorderSizePixel = 0
Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

-- منطقة الرسائل
local messagesFrame = Instance.new("ScrollingFrame", frame)
messagesFrame.Size = UDim2.new(1, -10, 1, -80)
messagesFrame.Position = UDim2.new(0, 5, 0, 40)
messagesFrame.BackgroundTransparency = 1
messagesFrame.ScrollBarThickness = 3
messagesFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 120, 255)
messagesFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
messagesFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
messagesFrame.BorderSizePixel = 0

local layout = Instance.new("UIListLayout", messagesFrame)
layout.Padding = UDim.new(0, 4)
layout.SortOrder = Enum.SortOrder.LayoutOrder

local padding = Instance.new("UIPadding", messagesFrame)
padding.PaddingTop = UDim.new(0, 4)
padding.PaddingBottom = UDim.new(0, 4)
padding.PaddingLeft = UDim.new(0, 4)
padding.PaddingRight = UDim.new(0, 4)

-- حاوية الإدخال
local inputFrame = Instance.new("Frame", frame)
inputFrame.Size = UDim2.new(1, -10, 0, 32)
inputFrame.Position = UDim2.new(0, 5, 1, -38)
inputFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 55)
inputFrame.BackgroundTransparency = 0.3
inputFrame.BorderSizePixel = 0
Instance.new("UICorner", inputFrame).CornerRadius = UDim.new(0, 8)

local box = Instance.new("TextBox", inputFrame)
box.Size = UDim2.new(1, -40, 1, 0)
box.Position = UDim2.new(0, 8, 0, 0)
box.BackgroundTransparency = 1
box.PlaceholderText = "اكتب رسالة... ✏️"
box.Text = ""
box.TextColor3 = Color3.new(1, 1, 1)
box.PlaceholderColor3 = Color3.fromRGB(130, 130, 160)
box.Font = Enum.Font.Gotham
box.TextSize = 12
box.TextXAlignment = Enum.TextXAlignment.Right -- لدعم العربية
box.ClearTextOnFocus = false

local sendBtn = Instance.new("TextButton", inputFrame)
sendBtn.Size = UDim2.new(0, 30, 1, -6)
sendBtn.Position = UDim2.new(1, -34, 0, 3)
sendBtn.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
sendBtn.Text = "↑"
sendBtn.TextColor3 = Color3.new(1,1,1)
sendBtn.Font = Enum.Font.GothamBold
sendBtn.TextSize = 16
sendBtn.BorderSizePixel = 0
Instance.new("UICorner", sendBtn).CornerRadius = UDim.new(0, 6)

-- ══════════════════════════════════
--         منطق الرسائل
-- ══════════════════════════════════

-- ألوان مختلفة لكل يوزر
local userColors = {}
local colorPalette = {
    Color3.fromRGB(100, 180, 255),
    Color3.fromRGB(180, 120, 255),
    Color3.fromRGB(100, 255, 180),
    Color3.fromRGB(255, 180, 100),
    Color3.fromRGB(255, 120, 160),
    Color3.fromRGB(120, 255, 120),
}

local function getUserColor(name)
    if not userColors[name] then
        local idx = (#userColors % #colorPalette) + 1
        userColors[name] = colorPalette[idx]
    end
    return userColors[name]
end

local function addMessage(user, msg, isNew)
    local isMe = (user == LocalPlayer.Name)

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 0)
    row.AutomaticSize = Enum.AutomaticSize.Y
    row.BackgroundTransparency = 1
    row.LayoutOrder = 0
    row.Parent = messagesFrame

    local bubble = Instance.new("Frame", row)
    bubble.AutomaticSize = Enum.AutomaticSize.XY
    bubble.BackgroundColor3 = isMe
        and Color3.fromRGB(50, 80, 180)
        or Color3.fromRGB(30, 30, 50)
    bubble.BackgroundTransparency = isMe and 0.2 or 0.4
    bubble.BorderSizePixel = 0

    -- محاذاة: رسائلي يمين، باقي يسار
    if isMe then
        bubble.Position = UDim2.new(1, 0, 0, 0)
        bubble.AnchorPoint = Vector2.new(1, 0)
    else
        bubble.Position = UDim2.new(0, 0, 0, 0)
    end

    Instance.new("UICorner", bubble).CornerRadius = UDim.new(0, 8)

    local bubblePad = Instance.new("UIPadding", bubble)
    bubblePad.PaddingLeft = UDim.new(0, 8)
    bubblePad.PaddingRight = UDim.new(0, 8)
    bubblePad.PaddingTop = UDim.new(0, 4)
    bubblePad.PaddingBottom = UDim.new(0, 4)

    local nameLabel = Instance.new("TextLabel", bubble)
    nameLabel.Size = UDim2.new(0, 0, 0, 14)
    nameLabel.AutomaticSize = Enum.AutomaticSize.X
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = isMe and "أنت" or user
    nameLabel.TextColor3 = getUserColor(user)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 10

    local msgLabel = Instance.new("TextLabel", bubble)
    msgLabel.Size = UDim2.new(0, 180, 0, 0)
    msgLabel.AutomaticSize = Enum.AutomaticSize.Y
    msgLabel.Position = UDim2.new(0, 0, 0, 16)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = msg
    msgLabel.TextColor3 = Color3.new(1, 1, 1)
    msgLabel.Font = Enum.Font.Gotham
    msgLabel.TextSize = 12
    msgLabel.TextWrapped = true
    msgLabel.RichText = true -- دعم ايموجيات مطور

    -- أنيميشن دخول للرسائل الجديدة
    if isNew then
        bubble.BackgroundTransparency = 1
        msgLabel.TextTransparency = 1
        nameLabel.TextTransparency = 1
        local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(bubble, tweenInfo, {
            BackgroundTransparency = isMe and 0.2 or 0.4
        }):Play()
        TweenService:Create(msgLabel, tweenInfo, {TextTransparency = 0}):Play()
        TweenService:Create(nameLabel, tweenInfo, {TextTransparency = 0}):Play()
    end

    -- تحديد ترتيب التخطيط
    row.LayoutOrder = messagesFrame:GetChildren() and #messagesFrame:GetChildren() or 0

    -- تمرير للأسفل تلقائي
    task.defer(function()
        messagesFrame.CanvasPosition = Vector2.new(0, messagesFrame.AbsoluteCanvasSize.Y)
    end)
end

local function sendMessage(text)
    if text == "" or #text > 200 then return end
    local data = {username = LocalPlayer.Name, message = text}
    pcall(function()
        syn.request({
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
end

-- إرسال عند Enter أو زر الإرسال
local function trySend()
    local text = box.Text:match("^%s*(.-)%s*$") -- trim
    if text ~= "" then
        sendMessage(text)
        box.Text = ""
    end
end

box.FocusLost:Connect(function(enter)
    if enter then trySend() end
end)
sendBtn.MouseButton1Click:Connect(trySend)

-- ══════════════════════════════════
--         جلب الرسائل السريع
-- ══════════════════════════════════
task.spawn(function()
    local lastId = 0

    while task.wait(POLL_RATE) do
        local ok, response = pcall(function()
            return syn.request({
                -- جلب آخر MAX_MESSAGES رسالة فقط وليس كلها
                Url = PROJECT_URL .. "/rest/v1/chat_messages?select=id,username,message&order=id.desc&limit=" .. MAX_MESSAGES,
                Method = "GET",
                Headers = {
                    ["apikey"] = ANON_KEY,
                    ["Authorization"] = "Bearer " .. ANON_KEY
                }
            })
        end)

        if ok and response and response.Body then
            local decoded = HttpService:JSONDecode(response.Body)
            if type(decoded) == "table" and #decoded > 0 then
                -- عكس الترتيب (لأننا جلبنا desc)
                local sorted = {}
                for i = #decoded, 1, -1 do
                    table.insert(sorted, decoded[i])
                end

                -- نعرض فقط الرسائل الجديدة
                local newMsgs = {}
                for _, v in ipairs(sorted) do
                    if v.id > lastId then
                        table.insert(newMsgs, v)
                    end
                end

                -- لو أول مرة: امسح واعرض كل شيء
                if lastId == 0 then
                    for _, child in ipairs(messagesFrame:GetChildren()) do
                        if child:IsA("Frame") then child:Destroy() end
                    end
                    for _, v in ipairs(sorted) do
                        addMessage(v.username, v.message, false)
                    end
                else
                    for _, v in ipairs(newMsgs) do
                        addMessage(v.username, v.message, true)
                    end
                end

                -- تحديث آخر ID
                lastId = sorted[#sorted].id or lastId
            end
        end
    end
end)

-- ══════════════════════════════════
--       أنيميشن الفتح/الإغلاق
-- ══════════════════════════════════
local isOpen = true
local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function setOpen(open)
    isOpen = open
    if open then
        frame.Visible = true
        TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 280, 0, 340),
            BackgroundTransparency = 0.15
        }):Play()
        toggleBtn.Text = "✕"
    else
        TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 280, 0, 0),
            BackgroundTransparency = 1
        }):Play()
        task.delay(0.25, function() frame.Visible = false end)
        toggleBtn.Text = "💬"
    end
end

toggleBtn.MouseButton1Click:Connect(function()
    setOpen(not isOpen)
end)

-- تأثير hover على زر الإرسال
sendBtn.MouseEnter:Connect(function()
    TweenService:Create(sendBtn, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    }):Play()
end)
sendBtn.MouseLeave:Connect(function()
    TweenService:Create(sendBtn, TweenInfo.new(0.15), {
        BackgroundColor3 = Color3.fromRGB(80, 120, 255)
    }):Play()
end)

print("✅ Global Chat v2 Loaded | Polling every " .. POLL_RATE .. "s")
