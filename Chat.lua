-- 💬 Pro Chat v11 - Roblox Style

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local PROJECT_URL = "https://yuwnhpbwrdfcpjonfodr.supabase.co"
local ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl1d25ocGJ3cmRmY3Bqb25mb2RyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODczMzU2NDIsImV4cCI6MjEwMjkxMTY0Mn0.Ac99nEIxqgwVxWS1Q4527uhUqL_YgIDtH4ucZnzeSOc"

local request = http_request or request or (syn and syn.request) or (fluxus and fluxus.request)
if not request then warn("❌ Executor لا يدعم HTTP") return end

if CoreGui:FindFirstChild("ProChat") then CoreGui.ProChat:Destroy() end


local isTouch = UserInputService.TouchEnabled
local isMouse = UserInputService.MouseEnabled

-- إعدادات مؤقتة للجلسة فقط: لا يوجد حفظ على الجهاز.
local settings = {
    width = 0.39,
    height = 0.36,
    visibleMessages = isTouch and 4 or 10,
    buttonX = 12,
    buttonY = 82,
    chatX = 12,
    chatY = 126,
    color = Color3.fromRGB(88, 101, 242),
}

local MIN_MESSAGES, MAX_MESSAGES = 2, 20
local MIN_W, MAX_W = 0.30, 0.80
local MIN_H, MAX_H = 0.24, 0.78


local gui = Instance.new("ScreenGui")
gui.Name = "ProChat"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = CoreGui

local toggleBtn = Instance.new("TextButton", gui)
toggleBtn.Size = UDim2.new(0, 96, 0, 42)
toggleBtn.Position = UDim2.new(0, settings.buttonX, 0, settings.buttonY)
toggleBtn.BackgroundColor3 = settings.color
toggleBtn.BackgroundTransparency = 0.5
toggleBtn.Text = "💬 Chat"
toggleBtn.TextSize = 14
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.BorderSizePixel = 0
toggleBtn.AutoButtonColor = false
toggleBtn.ZIndex = 10
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)

local unreadDot = Instance.new("Frame", toggleBtn)
unreadDot.Size = UDim2.new(0, 9, 0, 9)
unreadDot.Position = UDim2.new(1, -13, 0, 5)
unreadDot.BackgroundColor3 = Color3.fromRGB(255, 90, 90)
unreadDot.BorderSizePixel = 0
unreadDot.Visible = false
unreadDot.ZIndex = 12
Instance.new("UICorner", unreadDot).CornerRadius = UDim.new(1, 0)


local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(settings.width, 0, settings.height, 0)
frame.Position = UDim2.new(0, settings.chatX, 0, settings.chatY)
frame.BackgroundColor3 = Color3.fromRGB(18, 19, 24)
frame.BackgroundTransparency = 0.12
frame.BorderSizePixel = 0
frame.Visible = false
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)


local header = Instance.new("Frame", frame)
header.Size = UDim2.new(1, -8, 0, 32)
header.Position = UDim2.new(0, 4, 0, 4)
header.BackgroundTransparency = 1
header.ZIndex = 20

local titleLabel = Instance.new("TextLabel", header)
titleLabel.Size = UDim2.new(1, -42, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "💬  Global Chat"
titleLabel.TextColor3 = Color3.new(1,1,1)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 15
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 21

local pcHint = Instance.new("TextLabel", header)
pcHint.Size = UDim2.new(0, 150, 0, 20)
pcHint.Position = UDim2.new(0, 0, 1, 0)
pcHint.BackgroundTransparency = 1
pcHint.Text = isMouse and "اضغط T للكتابة" or ""
pcHint.TextColor3 = Color3.fromRGB(175,175,185)
pcHint.Font = Enum.Font.Gotham
pcHint.TextSize = 10
pcHint.TextXAlignment = Enum.TextXAlignment.Left
pcHint.ZIndex = 21

local settingsBtn = Instance.new("TextButton", header)
settingsBtn.Size = UDim2.new(0, 34, 0, 30)
settingsBtn.Position = UDim2.new(1, -34, 0, 0)
settingsBtn.BackgroundColor3 = Color3.fromRGB(45,45,48)
settingsBtn.Text = "⚙"
settingsBtn.TextColor3 = Color3.new(1,1,1)
settingsBtn.Font = Enum.Font.GothamBold
settingsBtn.TextSize = 16
settingsBtn.BorderSizePixel = 0
settingsBtn.ZIndex = 22
Instance.new("UICorner", settingsBtn).CornerRadius = UDim.new(0,8)

local messages = Instance.new("ScrollingFrame", frame)
messages.Size = UDim2.new(1, -8, 0, 120)
messages.Position = UDim2.new(0, 4, 0, 40)
messages.CanvasSize = UDim2.new(0, 0, 0, 0)
messages.ScrollBarThickness = 3
messages.ScrollBarImageColor3 = Color3.fromRGB(145, 145, 155)
messages.BackgroundTransparency = 1
messages.BorderSizePixel = 0
messages.AutomaticCanvasSize = Enum.AutomaticSize.Y
messages.ScrollingDirection = Enum.ScrollingDirection.Y
messages.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar

local layout = Instance.new("UIListLayout", messages)
layout.Padding = UDim.new(0, 5)
layout.SortOrder = Enum.SortOrder.LayoutOrder

local unreadBtn = Instance.new("TextButton", frame)
unreadBtn.Size = UDim2.new(0, 128, 0, 30)
unreadBtn.Position = UDim2.new(1, -138, 1, -78)
unreadBtn.BackgroundColor3 = settings.color
unreadBtn.BackgroundTransparency = 0.08
unreadBtn.Text = "↓  رسالة جديدة"
unreadBtn.TextColor3 = Color3.new(1,1,1)
unreadBtn.Font = Enum.Font.GothamBold
unreadBtn.TextSize = 11
unreadBtn.BorderSizePixel = 0
unreadBtn.Visible = false
unreadBtn.ZIndex = 40
Instance.new("UICorner", unreadBtn).CornerRadius = UDim.new(0, 9)

local function updateMessageViewport()
    local desired = 24 + (settings.visibleMessages * 34)
    local available = math.max(110, frame.AbsoluteSize.Y - 116)
    local h = math.clamp(desired, 110, available)
    messages.Size = UDim2.new(1, -8, 0, h)
    unreadBtn.Position = UDim2.new(1, -138, 0, h - 36)
end

local pad = Instance.new("UIPadding", messages)
pad.PaddingTop = UDim.new(0, 2)
pad.PaddingBottom = UDim.new(0, 2)
pad.PaddingLeft = UDim.new(0, 4)
pad.PaddingRight = UDim.new(0, 4)


local quickActionBar = Instance.new("Frame", frame)
quickActionBar.Name = "QuickActionBar"
quickActionBar.Size = UDim2.new(1, -12, 0, 26)
quickActionBar.Position = UDim2.new(0, 6, 1, -74)
quickActionBar.BackgroundColor3 = Color3.fromRGB(25,26,32)
quickActionBar.BackgroundTransparency = 0.16
quickActionBar.BorderSizePixel = 0
quickActionBar.ZIndex = 25
Instance.new("UICorner", quickActionBar).CornerRadius = UDim.new(0,8)

local quickStatus = Instance.new("TextLabel", quickActionBar)
quickStatus.Size = UDim2.new(1, -10, 1, 0)
quickStatus.Position = UDim2.new(0, 5, 0, 0)
quickStatus.BackgroundTransparency = 1
quickStatus.Text = "Global • Online"
quickStatus.TextColor3 = Color3.fromRGB(155, 160, 175)
quickStatus.Font = Enum.Font.Gotham
quickStatus.TextSize = 9
quickStatus.TextXAlignment = Enum.TextXAlignment.Left
quickStatus.ZIndex = 26

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
box.PlaceholderText = "اكتب رسالة واضغط Enter..."
box.PlaceholderColor3 = Color3.fromRGB(180, 180, 180)
box.Text = ""
box.TextColor3 = Color3.new(1, 1, 1)
box.Font = Enum.Font.GothamMedium
box.TextSize = 12
box.TextXAlignment = Enum.TextXAlignment.Right
box.ClearTextOnFocus = false

local charCounter = Instance.new("TextLabel", inputBg)
charCounter.Size = UDim2.new(0, 42, 1, 0)
charCounter.Position = UDim2.new(0, 6, 0, 0)
charCounter.BackgroundTransparency = 1
charCounter.Text = "0/240"
charCounter.TextColor3 = Color3.fromRGB(150,150,160)
charCounter.Font = Enum.Font.Gotham
charCounter.TextSize = 10
charCounter.TextXAlignment = Enum.TextXAlignment.Left
charCounter.ZIndex = 10


local sendBtn = Instance.new("TextButton", inputBg)
sendBtn.Size = UDim2.new(0, 54, 1, -4)
sendBtn.Position = UDim2.new(1, -58, 0, 2)
sendBtn.BackgroundColor3 = settings.color
sendBtn.Text = "إرسال"
sendBtn.TextColor3 = Color3.new(1,1,1)
sendBtn.Font = Enum.Font.GothamBold
sendBtn.TextSize = 11
sendBtn.BorderSizePixel = 0
sendBtn.ZIndex = 10
Instance.new("UICorner", sendBtn).CornerRadius = UDim.new(0,7)

box.Size = UDim2.new(1, -66, 1, 0)


local settingsPanel = Instance.new("Frame", gui)
settingsPanel.Size = UDim2.new(0, 320, 0, 470)
settingsPanel.Position = UDim2.new(0.5, -150, 0.5, -176)
settingsPanel.BackgroundColor3 = Color3.fromRGB(24,24,27)
settingsPanel.BorderSizePixel = 0
settingsPanel.Visible = false
settingsPanel.ZIndex = 100
Instance.new("UICorner", settingsPanel).CornerRadius = UDim.new(0,12)

local settingsStroke = Instance.new("UIStroke", settingsPanel)

local ultimateOptionsFrame = Instance.new("Frame", settingsPanel)
ultimateOptionsFrame.Name = "UltimateOptions"
ultimateOptionsFrame.Size = UDim2.new(1, -20, 0, 150)
ultimateOptionsFrame.Position = UDim2.new(0, 10, 1, -172)
ultimateOptionsFrame.BackgroundColor3 = Color3.fromRGB(30,31,38)
ultimateOptionsFrame.BackgroundTransparency = 0.15
ultimateOptionsFrame.BorderSizePixel = 0
ultimateOptionsFrame.ZIndex = 100
Instance.new("UICorner", ultimateOptionsFrame).CornerRadius = UDim.new(0, 10)

local ultimateTitle = Instance.new("TextLabel", ultimateOptionsFrame)
ultimateTitle.Size = UDim2.new(1, -16, 0, 22)
ultimateTitle.Position = UDim2.new(0, 8, 0, 5)
ultimateTitle.BackgroundTransparency = 1
ultimateTitle.Text = "⚡ Ultimate"
ultimateTitle.TextColor3 = Color3.new(1,1,1)
ultimateTitle.Font = Enum.Font.GothamBold
ultimateTitle.TextSize = 12
ultimateTitle.TextXAlignment = Enum.TextXAlignment.Left
ultimateTitle.ZIndex = 101

local ultimateStatus = Instance.new("TextLabel", ultimateOptionsFrame)
ultimateStatus.Size = UDim2.new(1, -16, 0, 20)
ultimateStatus.Position = UDim2.new(0, 8, 0, 28)
ultimateStatus.BackgroundTransparency = 1
ultimateStatus.Text = "جاهز"
ultimateStatus.TextColor3 = Color3.fromRGB(165,220,175)
ultimateStatus.Font = Enum.Font.Gotham
ultimateStatus.TextSize = 10
ultimateStatus.TextXAlignment = Enum.TextXAlignment.Left
ultimateStatus.ZIndex = 101

local function ultimateOption(text, x, y, w)
    local b = Instance.new("TextButton", ultimateOptionsFrame)
    b.Size = UDim2.new(0,w,0,28)
    b.Position = UDim2.new(0,x,0,y)
    b.BackgroundColor3 = Color3.fromRGB(45,46,53)
    b.Text = text
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 10
    b.BorderSizePixel = 0
    b.ZIndex = 101
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,7)
    return b
end

local optSmartScroll = ultimateOption("Smart Scroll", 8, 56, 90)
local optUnread = ultimateOption("Unread", 104, 56, 78)
local optSound = ultimateOption("Sound", 188, 56, 70)
local optBubble = ultimateOption("Bubbles", 8, 90, 90)
local optCompact = ultimateOption("Compact", 104, 90, 78)
local optResetUI = ultimateOption("Reset UI", 188, 90, 70)
local optTest = ultimateOption("Preview", 8, 124, 90)
local optCloseAll = ultimateOption("Clear Bubbles", 104, 124, 100)
local optInfo = ultimateOption("Info", 212, 124, 46)

settingsStroke.Color = settings.color
settingsStroke.Thickness = 1

local stTitle = Instance.new("TextLabel", settingsPanel)
stTitle.Size = UDim2.new(1,-20,0,30)
stTitle.Position = UDim2.new(0,10,0,8)
stTitle.BackgroundTransparency = 1
stTitle.Text = "⚙ إعدادات الشات"
stTitle.TextColor3 = Color3.new(1,1,1)
stTitle.Font = Enum.Font.GothamBold
stTitle.TextSize = 16
stTitle.TextXAlignment = Enum.TextXAlignment.Left
stTitle.ZIndex = 101

local function sbtn(txt,x,y,w,h)
    local b = Instance.new("TextButton", settingsPanel)
    b.Size = UDim2.new(0,w,0,h)
    b.Position = UDim2.new(0,x,0,y)
    b.BackgroundColor3 = Color3.fromRGB(45,45,48)
    b.Text = txt
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.BorderSizePixel = 0
    b.ZIndex = 101
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,7)
    return b
end

local stateInfo = Instance.new("TextLabel", settingsPanel)
stateInfo.Size = UDim2.new(1,-20,0,24)
stateInfo.Position = UDim2.new(0,10,0,40)
stateInfo.BackgroundColor3 = Color3.fromRGB(34,35,41)
stateInfo.Text = "الحالة: جاهز"
stateInfo.TextColor3 = Color3.fromRGB(160,220,170)
stateInfo.Font = Enum.Font.GothamBold
stateInfo.TextSize = 11
stateInfo.TextXAlignment = Enum.TextXAlignment.Center
stateInfo.ZIndex = 101
Instance.new("UICorner", stateInfo).CornerRadius = UDim.new(0,7)

local msgInfo = Instance.new("TextLabel", settingsPanel)
msgInfo.Size = UDim2.new(1,-20,0,24)
msgInfo.Position = UDim2.new(0,10,0,70)
msgInfo.BackgroundTransparency = 1
msgInfo.TextColor3 = Color3.new(1,1,1)
msgInfo.Font = Enum.Font.Gotham
msgInfo.TextSize = 12
msgInfo.TextXAlignment = Enum.TextXAlignment.Left
msgInfo.ZIndex = 101

local msgMinus = sbtn("−",206,68,38,26)
local msgPlus = sbtn("+",252,68,38,26)

local sizeInfo = Instance.new("TextLabel", settingsPanel)
sizeInfo.Size = UDim2.new(1,-20,0,22)
sizeInfo.Position = UDim2.new(0,10,0,100)
sizeInfo.BackgroundTransparency = 1
sizeInfo.TextColor3 = Color3.new(1,1,1)
sizeInfo.Font = Enum.Font.Gotham
sizeInfo.TextSize = 12
sizeInfo.TextXAlignment = Enum.TextXAlignment.Left
sizeInfo.ZIndex = 101

local wMinus = sbtn("عرض −",10,128,68,28)
local wPlus = sbtn("عرض +",84,128,68,28)
local hMinus = sbtn("طول −",158,128,68,28)
local hPlus = sbtn("طول +",232,128,60,28)

local moveBtn = sbtn("✋ تحريك زر",10,166,136,30)
local moveChat = sbtn("✋ تحريك الشات",154,166,138,30)


local bubbleTitle = Instance.new("TextLabel", settingsPanel)
bubbleTitle.Size = UDim2.new(1,-20,0,22)
bubbleTitle.Position = UDim2.new(0,10,0,246)
bubbleTitle.BackgroundTransparency = 1
bubbleTitle.Text = "☁ إعدادات غيمة اللاعب"
bubbleTitle.TextColor3 = Color3.new(1,1,1)
bubbleTitle.Font = Enum.Font.GothamBold
bubbleTitle.TextSize = 12
bubbleTitle.TextXAlignment = Enum.TextXAlignment.Left
bubbleTitle.ZIndex = 101

local bubbleSizeMinus = sbtn("غيمة −",10,270,72,28)
local bubbleSizePlus = sbtn("غيمة +",88,270,72,28)
local bubbleTextMinus = sbtn("نص −",166,270,58,28)
local bubbleTextPlus = sbtn("نص +",230,270,62,28)

local bubblePresetBtn = sbtn("☁ ستايل قوي",10,304,110,30)
local bubbleCompactBtn = sbtn("حجم كومباكت",126,304,110,30)
local bubbleClearBtn = sbtn("مسح الغيمات",242,304,50,30)
colorTitle.Size = UDim2.new(1,-20,0,22)
colorTitle.Position = UDim2.new(0,10,0,204)
colorTitle.BackgroundTransparency = 1
colorTitle.Text = "لون الشات"
colorTitle.TextColor3 = Color3.new(1,1,1)
colorTitle.Font = Enum.Font.Gotham
colorTitle.TextSize = 12
colorTitle.TextXAlignment = Enum.TextXAlignment.Left
colorTitle.ZIndex = 101

local settingColors = {
    Color3.fromRGB(88,101,242),
    Color3.fromRGB(145,80,220),
    Color3.fromRGB(50,190,110),
    Color3.fromRGB(225,170,55),
    Color3.fromRGB(215,70,70),
    Color3.fromRGB(40,180,220),
}
for i,c in ipairs(settingColors) do
    local x = 10 + ((i-1)%3)*94
    local y = 232 + math.floor((i-1)/3)*32
    local b = sbtn("●",x,y,86,27)
    b.BackgroundColor3 = c
    b.MouseButton1Click:Connect(function()
        settings.color = c
        toggleBtn.BackgroundColor3 = c
        sendBtn.BackgroundColor3 = c
        unreadBtn.BackgroundColor3 = c
        settingsStroke.Color = c
    end)
end

local resetBtn = sbtn("↺ افتراضي",10,298,92,30)
local closeSettings = sbtn("إغلاق",108,298,92,30)

local function updateSettingsState()
    if editButtonMode then
        stateInfo.Text = "الحالة: تحريك زر الشات ✋"
        stateInfo.TextColor3 = Color3.fromRGB(255,210,110)
    elseif editChatMode then
        stateInfo.Text = "الحالة: تحريك نافذة الشات ✋"
        stateInfo.TextColor3 = Color3.fromRGB(255,210,110)
    else
        stateInfo.Text = "الحالة: جاهز"
        stateInfo.TextColor3 = Color3.fromRGB(160,220,170)
    end
end

local function refreshSettings()
    frame.Size = UDim2.new(settings.width,0,settings.height,0)
    frame.Position = UDim2.new(0,settings.chatX,0,settings.chatY)
    task.defer(updateMessageViewport)
    toggleBtn.Position = UDim2.new(0,settings.buttonX,0,settings.buttonY)
    toggleHit.Position = UDim2.new(0,settings.buttonX - 10,0,settings.buttonY - 9)
    msgInfo.Text = "الرسائل الظاهرة بدون سحب: " .. tostring(settings.visibleMessages)
    updateMessageViewport()
    sizeInfo.Text = string.format("الحجم: %d%% × %d%%", math.floor(settings.width*100), math.floor(settings.height*100))
    moveBtn.BackgroundColor3 = editButtonMode and Color3.fromRGB(190,145,45) or settings.color
    moveChat.BackgroundColor3 = editChatMode and Color3.fromRGB(190,145,45) or settings.color
    updateSettingsState()
end

local editButtonMode = false
local editChatMode = false
local dragTarget = nil
local dragStart = nil
local dragOrigin = nil

local function stopDrag()
    dragTarget, dragStart, dragOrigin = nil, nil, nil
end

local function beginDrag(target,input)
    dragTarget = target
    dragStart = input.Position
    dragOrigin = target.Position
end

local function updateDrag(input)
    if not dragTarget then return end
    local delta = input.Position - dragStart
    local maxX = math.max(4, gui.AbsoluteSize.X - dragTarget.AbsoluteSize.X - 4)
    local maxY = math.max(4, gui.AbsoluteSize.Y - dragTarget.AbsoluteSize.Y - 4)
    local x = math.clamp(dragOrigin.X.Offset + delta.X, 4, maxX)
    local y = math.clamp(dragOrigin.Y.Offset + delta.Y, 4, maxY)

    dragTarget.Position = UDim2.new(0,x,0,y)

    if dragTarget == toggleBtn then
        settings.buttonX, settings.buttonY = x, y
        toggleHit.Position = UDim2.new(0, x - 10, 0, y - 9)
    elseif dragTarget == frame then
        settings.chatX, settings.chatY = x, y
    end
    updateSettingsState()
end


local function refreshBubbleUI()
    updateBubbleSettingsVisuals()
end

bubbleSizeMinus.MouseButton1Click:Connect(function()
    bubbleSettings.maxWidth = bubbleClamp(bubbleSettings.maxWidth - 20, 180, 460)
    refreshBubbleUI()
end)

bubbleSizePlus.MouseButton1Click:Connect(function()
    bubbleSettings.maxWidth = bubbleClamp(bubbleSettings.maxWidth + 20, 180, 460)
    refreshBubbleUI()
end)

bubbleTextMinus.MouseButton1Click:Connect(function()
    bubbleSettings.textSize = bubbleClamp(bubbleSettings.textSize - 1, bubbleSettings.minTextSize, bubbleSettings.maxTextSize)
    refreshBubbleUI()
end)

bubbleTextPlus.MouseButton1Click:Connect(function()
    bubbleSettings.textSize = bubbleClamp(bubbleSettings.textSize + 1, bubbleSettings.minTextSize, bubbleSettings.maxTextSize)
    refreshBubbleUI()
end)

bubblePresetBtn.MouseButton1Click:Connect(function()
    bubbleSettings.maxBubbles = 6
    bubbleSettings.maxWidth = 340
    bubbleSettings.textSize = 17
    bubbleSettings.duration = 5.5
    bubbleSettings.baseOffsetY = 3.15
    bubbleSettings.maxDistance = 120
    bubbleSettings.gradient = true
    bubbleSettings.glow = true
    bubbleSettings.popAnimation = true
    bubbleSettings.floatAnimation = true
    bubbleSettings.tailVisible = true
    bubbleSettings.showPlayerName = true
    refreshBubbleUI()
end)

bubbleCompactBtn.MouseButton1Click:Connect(function()
    bubbleSettings.maxBubbles = 4
    bubbleSettings.maxWidth = 240
    bubbleSettings.textSize = 15
    bubbleSettings.duration = 4.5
    bubbleSettings.baseOffsetY = 2.75
    bubbleSettings.maxDistance = 85
    refreshBubbleUI()
end)

bubbleClearBtn.MouseButton1Click:Connect(function()
    for playerName in pairs(playerBubbles) do
        clearPlayerBubbles(playerName, false)
    end
end)


local ultimate = {
    smartScroll = true,
    unread = true,
    sound = true,
    bubbles = true,
    compact = false,
}

local function setUltimateStatus(text)
    if ultimateStatus and ultimateStatus.Parent then
        ultimateStatus.Text = text
    end
end

local function updateUltimateButtons()
    local function paint(btn, enabled)
        btn.BackgroundColor3 = enabled
            and Color3.fromRGB(72, 110, 150)
            or Color3.fromRGB(45,46,53)
    end

    paint(optSmartScroll, ultimate.smartScroll)
    paint(optUnread, ultimate.unread)
    paint(optSound, ultimate.sound)
    paint(optBubble, ultimate.bubbles)
    paint(optCompact, ultimate.compact)
end

optSmartScroll.MouseButton1Click:Connect(function()
    ultimate.smartScroll = not ultimate.smartScroll
    setUltimateStatus("Smart Scroll: " .. (ultimate.smartScroll and "ON" or "OFF"))
    updateUltimateButtons()
end)

optUnread.MouseButton1Click:Connect(function()
    ultimate.unread = not ultimate.unread
    unreadBtn.Visible = false
    unreadDot.Visible = false
    setUltimateStatus("Unread: " .. (ultimate.unread and "ON" or "OFF"))
    updateUltimateButtons()
end)

optSound.MouseButton1Click:Connect(function()
    ultimate.sound = not ultimate.sound
    setUltimateStatus("Sound: " .. (ultimate.sound and "ON" or "OFF"))
    updateUltimateButtons()
end)

optBubble.MouseButton1Click:Connect(function()
    ultimate.bubbles = not ultimate.bubbles
    setUltimateStatus("Bubbles: " .. (ultimate.bubbles and "ON" or "OFF"))
    if not ultimate.bubbles then
        for playerName in pairs(playerBubbles) do
            clearPlayerBubbles(playerName, false)
        end
    end
    updateUltimateButtons()
end)

optCompact.MouseButton1Click:Connect(function()
    ultimate.compact = not ultimate.compact
    if ultimate.compact then
        bubbleSettings.maxWidth = 245
        bubbleSettings.textSize = 15
        settings.width = math.min(settings.width, 0.42)
    else
        bubbleSettings.maxWidth = 340
        bubbleSettings.textSize = 17
    end
    refreshBubbleUI()
    refreshSettings()
    setUltimateStatus("Compact: " .. (ultimate.compact and "ON" or "OFF"))
    updateUltimateButtons()
end)

optResetUI.MouseButton1Click:Connect(function()
    settings.width = 0.39
    settings.height = 0.36
    settings.visibleMessages = isTouch and 4 or 10
    settings.buttonX = 12
    settings.buttonY = 82
    settings.chatX = 12
    settings.chatY = 126
    settings.color = Color3.fromRGB(88,101,242)
    editButtonMode = false
    editChatMode = false
    stopDrag()
    refreshSettings()
    setUltimateStatus("تم إرجاع واجهة الشات للوضع الافتراضي")
end)

optTest.MouseButton1Click:Connect(function()
    setUltimateStatus("تم تشغيل معاينة الغيمة")
    if ultimate.bubbles then
        showBubbleAbovePlayer(LocalPlayer.Name, "معاينة الغيمة الفائقة — النص الطويل يلتف تلقائياً ويُعرض بشكل واضح.")
    end
end)

optCloseAll.MouseButton1Click:Connect(function()
    for playerName in pairs(playerBubbles) do
        clearPlayerBubbles(playerName, false)
    end
    setUltimateStatus("تم تنظيف كل الغيمات")
end)

optInfo.MouseButton1Click:Connect(function()
    setUltimateStatus("V7 • Session settings • Smart UI • Supreme bubbles")
end)

updateUltimateButtons()

settingsBtn.MouseButton1Click:Connect(function()
    settingsPanel.Visible = not settingsPanel.Visible
    editButtonMode = false
    editChatMode = false
    refreshSettings()
end)

msgMinus.MouseButton1Click:Connect(function()
    settings.visibleMessages = math.max(MIN_MESSAGES, settings.visibleMessages - 1)
    trimVisibleMessages()
    refreshSettings()
end)

msgPlus.MouseButton1Click:Connect(function()
    settings.visibleMessages = math.min(MAX_MESSAGES, settings.visibleMessages + 1)
    refreshSettings()
end)

wMinus.MouseButton1Click:Connect(function()
    settings.width = math.max(MIN_W, settings.width - 0.03)
    refreshSettings()
end)

wPlus.MouseButton1Click:Connect(function()
    settings.width = math.min(MAX_W, settings.width + 0.03)
    refreshSettings()
end)

hMinus.MouseButton1Click:Connect(function()
    settings.height = math.max(MIN_H, settings.height - 0.03)
    refreshSettings()
end)

hPlus.MouseButton1Click:Connect(function()
    settings.height = math.min(MAX_H, settings.height + 0.03)
    refreshSettings()
end)

moveBtn.MouseButton1Click:Connect(function()
    editButtonMode = not editButtonMode
    editChatMode = false
    stopDrag()
    refreshSettings()
end)

moveChat.MouseButton1Click:Connect(function()
    editChatMode = not editChatMode
    editButtonMode = false
    stopDrag()
    refreshSettings()
end)

resetBtn.MouseButton1Click:Connect(function()
    settings.width = 0.39
    settings.height = 0.36
    settings.visibleMessages = isTouch and 4 or 10
    settings.buttonX = 12
    settings.buttonY = 82
    settings.chatX = 12
    settings.chatY = 126
    toggleHit.Position = UDim2.new(0, 2, 0, 73)
    settings.color = Color3.fromRGB(88,101,242)
    toggleBtn.BackgroundColor3 = settings.color
    sendBtn.BackgroundColor3 = settings.color
    unreadBtn.BackgroundColor3 = settings.color
    settingsStroke.Color = settings.color
    editButtonMode = false
    editChatMode = false
    stopDrag()
    refreshSettings()
end)

closeSettings.MouseButton1Click:Connect(function()
    -- إغلاق الإعدادات = إنهاء التحريك وتثبيت آخر مكان.
    settingsPanel.Visible = false
    editButtonMode = false
    editChatMode = false
    stopDrag()
    refreshSettings()
end)

toggleBtn.InputBegan:Connect(function(input)
    if editButtonMode and settingsPanel.Visible and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        beginDrag(toggleBtn,input)
    end
end)

header.InputBegan:Connect(function(input)
    if editChatMode and settingsPanel.Visible and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        beginDrag(frame,input)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        updateDrag(input)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        stopDrag()
    end
end)

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


local function trimVisibleMessages()
    -- visibleMessages controls the amount of the chat viewport only.
    -- Old messages are NEVER destroyed and remain scrollable.
end

local messageIndex = 0

local function isNearBottom()
    local maxY = math.max(0, messages.AbsoluteCanvasSize.Y - messages.AbsoluteWindowSize.Y)
    return (maxY - messages.CanvasPosition.Y) <= 24
end

local function scrollToBottom(animated)
    task.defer(function()
        local y = math.max(0, messages.AbsoluteCanvasSize.Y - messages.AbsoluteWindowSize.Y)
        if animated then
            TweenService:Create(messages, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
                CanvasPosition = Vector2.new(0, y)
            }):Play()
        else
            messages.CanvasPosition = Vector2.new(0, y)
        end
    end)
end

local function addMessage(user, msg)
    local wasAtBottom = isNearBottom()
    messageIndex += 1

    local color = getColor(user)
    local hex = colorToHex(color)
    local isMe = user == LocalPlayer.Name
    local displayName = isMe and (user .. "  • أنت") or user

    local row = Instance.new("Frame", messages)
    row.Name = "Message_" .. tostring(messageIndex)
    row.Size = UDim2.new(1, -8, 0, 0)
    row.AutomaticSize = Enum.AutomaticSize.Y
    row.BackgroundTransparency = 1
    row.LayoutOrder = messageIndex

    local nameLabel = Instance.new("TextLabel", row)
    nameLabel.Size = UDim2.new(0.34, -4, 0, 22)
    nameLabel.Position = UDim2.new(0, 4, 0, 2)
    nameLabel.BackgroundTransparency = 1
    nameLabel.RichText = true
    nameLabel.Text = string.format('<font color="%s"><b>%s</b></font>', hex, displayName)
    nameLabel.TextColor3 = color
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 12
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextYAlignment = Enum.TextYAlignment.Top

    local timeLabel = Instance.new("TextLabel", row)
    timeLabel.Size = UDim2.new(0.34, -4, 0, 18)
    timeLabel.Position = UDim2.new(0, 4, 0, 22)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = messageTime or os.date("%I:%M %p")
    timeLabel.TextColor3 = Color3.fromRGB(125, 128, 138)
    timeLabel.Font = Enum.Font.Gotham
    timeLabel.TextSize = 9
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left
    timeLabel.TextYAlignment = Enum.TextYAlignment.Top

    local msgLabel = Instance.new("TextLabel", row)
    msgLabel.Size = UDim2.new(0.66, -8, 0, 0)
    msgLabel.Position = UDim2.new(0.34, 0, 0, 2)
    msgLabel.AutomaticSize = Enum.AutomaticSize.Y
    msgLabel.BackgroundColor3 = isMe and Color3.fromRGB(48, 49, 58) or Color3.fromRGB(31, 32, 39)
    msgLabel.BackgroundTransparency = 0.08
    msgLabel.TextColor3 = Color3.fromRGB(235, 235, 240)
    msgLabel.Font = Enum.Font.Gotham
    msgLabel.TextSize = 14
    msgLabel.TextWrapped = true
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.TextYAlignment = Enum.TextYAlignment.Top
    msgLabel.Text = tostring(msg)
    msgLabel.BorderSizePixel = 0
    msgLabel.ClipsDescendants = false
    Instance.new("UICorner", msgLabel).CornerRadius = UDim.new(0, 8)

    local pad = Instance.new("UIPadding", msgLabel)
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.PaddingTop = UDim.new(0, 7)
    pad.PaddingBottom = UDim.new(0, 7)

    local accent = Instance.new("Frame", row)
    accent.Size = UDim2.new(0, 3, 0, 24)
    accent.Position = UDim2.new(0.34, -2, 0, 4)
    accent.BackgroundColor3 = color
    accent.BorderSizePixel = 0
    Instance.new("UICorner", accent).CornerRadius = UDim.new(1, 0)

    row.BackgroundTransparency = 1
    for _, obj in ipairs({nameLabel, msgLabel, accent}) do
        if obj:IsA("TextLabel") then
            obj.TextTransparency = 1
        end
    end
    TweenService:Create(msgLabel, TweenInfo.new(0.15), {BackgroundTransparency = 0.08, TextTransparency = 0}):Play()
    TweenService:Create(nameLabel, TweenInfo.new(0.15), {TextTransparency = 0}):Play()
    
    if wasAtBottom and ultimate.smartScroll then
        scrollToBottom(true)
        unreadBtn.Visible = false
    else
        unreadBtn.Visible = true
    end
end



unreadBtn.MouseButton1Click:Connect(function()
    scrollToBottom(true)
    unreadBtn.Visible = false
end)

messages:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
    if isNearBottom() then
        unreadBtn.Visible = false
    end
end)


-- ============================================================
-- SUPREME BUBBLE ENGINE
-- Custom layered bubble system; Supabase/network code remains
-- completely separate and untouched.
-- ============================================================

local playerBubbles = {}
local bubbleSerial = 0

local BUBBLE_DEFAULTS = {
    maxBubbles = 6,
    maxWidth = 340,
    minWidth = 110,
    textSize = 17,
    minTextSize = 13,
    maxTextSize = 20,
    topPadding = 9,
    bottomPadding = 9,
    leftPadding = 13,
    rightPadding = 13,
    spacing = 7,
    duration = 5.5,
    minDuration = 3.0,
    maxDuration = 12.0,
    baseOffsetY = 3.15,
    maxDistance = 120,
    backgroundTransparency = 0.04,
    strokeTransparency = 0.18,
    strokeThickness = 1.25,
    shadowTransparency = 0.65,
    shadowOffset = Vector2.new(2, 3),
    tailVisible = true,
    showPlayerName = true,
    compactNear = true,
    adaptiveText = true,
    adaptiveWidth = true,
    gradient = true,
    glow = true,
    popAnimation = true,
    floatAnimation = true,
    fadeAnimation = true,
    selfAccent = true,
    playerAccent = true,
    sanitizeRichText = true,
}

local bubbleSettings = {}
for k, v in pairs(BUBBLE_DEFAULTS) do
    bubbleSettings[k] = v
end

local bubblePalette = {
    Color3.fromRGB(88, 101, 242),
    Color3.fromRGB(145, 80, 220),
    Color3.fromRGB(45, 190, 120),
    Color3.fromRGB(225, 170, 55),
    Color3.fromRGB(220, 75, 90),
    Color3.fromRGB(40, 180, 220),
    Color3.fromRGB(255, 120, 185),
    Color3.fromRGB(120, 220, 190),
}

local function bubbleClamp(v, a, b)
    return math.max(a, math.min(b, v))
end

local function safeBubbleText(text)
    text = tostring(text or "")
    if bubbleSettings.sanitizeRichText then
        text = text:gsub("&", "&amp;")
        text = text:gsub("<", "&lt;")
        text = text:gsub(">", "&gt;")
    end
    return text
end

local function bubbleAccentForPlayer(playerName)
    if not playerName then
        return bubbleSettings.color or Color3.fromRGB(88, 101, 242)
    end

    if userColors and userColors[playerName] then
        return userColors[playerName]
    end

    local checksum = 0
    for i = 1, #playerName do
        checksum = (checksum + string.byte(playerName, i) * i) % 997
    end
    return bubblePalette[(checksum % #bubblePalette) + 1]
end

local function bubbleMessageLength(text)
    local count = 0
    for _ in tostring(text):gmatch(".") do
        count += 1
    end
    return count
end

local function bubbleComputeWidth(text)
    local len = bubbleMessageLength(text)
    if not bubbleSettings.adaptiveWidth then
        return bubbleSettings.maxWidth
    end

    local width = bubbleSettings.minWidth + math.floor(math.sqrt(math.max(1, len)) * 29)
    return bubbleClamp(width, bubbleSettings.minWidth, bubbleSettings.maxWidth)
end

local function bubbleComputeTextSize(text)
    if not bubbleSettings.adaptiveText then
        return bubbleSettings.textSize
    end

    local len = bubbleMessageLength(text)
    if len > 170 then
        return bubbleSettings.minTextSize
    elseif len > 110 then
        return math.max(bubbleSettings.minTextSize, bubbleSettings.textSize - 2)
    elseif len > 65 then
        return math.max(bubbleSettings.minTextSize, bubbleSettings.textSize - 1)
    end

    return bubbleClamp(
        bubbleSettings.textSize,
        bubbleSettings.minTextSize,
        bubbleSettings.maxTextSize
    )
end

local function bubbleComputeDuration(text)
    local len = bubbleMessageLength(text)
    local extra = math.min(6, len / 80)
    return bubbleClamp(
        bubbleSettings.duration + extra,
        bubbleSettings.minDuration,
        bubbleSettings.maxDuration
    )
end

local function bubbleFindHead(character)
    if not character then
        return nil
    end

    local preferred = {"Head", "head", "UpperTorso", "HumanoidRootPart"}
    for _, name in ipairs(preferred) do
        local p = character:FindFirstChild(name)
        if p and p:IsA("BasePart") then
            return p
        end
    end

    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and string.find(string.lower(part.Name), "head", 1, true) then
            return part
        end
    end

    return character:FindFirstChildWhichIsA("BasePart")
end

local function bubbleDestroyData(data, instant)
    if not data then
        return
    end

    local root = data.root
    if not root or not root.Parent then
        return
    end

    if instant or not bubbleSettings.fadeAnimation then
        root:Destroy()
        return
    end

    local background = root:FindFirstChild("BubbleBody")
    local shadow = root:FindFirstChild("BubbleShadow")

    if background then
        TweenService:Create(
            background,
            TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {BackgroundTransparency = 1}
        ):Play()
    end

    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("TextLabel") then
            TweenService:Create(
                obj,
                TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {TextTransparency = 1}
            ):Play()
        elseif obj:IsA("UIStroke") then
            TweenService:Create(
                obj,
                TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {Transparency = 1}
            ):Play()
        end
    end

    if shadow then
        TweenService:Create(
            shadow,
            TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {BackgroundTransparency = 1}
        ):Play()
    end

    task.delay(0.23, function()
        if root and root.Parent then
            root:Destroy()
        end
    end)
end

local function bubbleGetOrCreateBillboard(playerName, character)
    local head = bubbleFindHead(character)
    if not head then
        return nil, nil
    end

    local current = playerBubbles[playerName]
    if current and current.billboard and current.billboard.Parent then
        current.billboard.Adornee = head
        return current.billboard, current.container
    end

    local old = head:FindFirstChild("ProChatSupremeBillboard")
    if old then
        old:Destroy()
    end

    local attachment = head:FindFirstChild("ProChatSupremeAttachment")
    if not attachment then
        attachment = Instance.new("Attachment")
        attachment.Name = "ProChatSupremeAttachment"
        attachment.Position = Vector3.new(0, math.max(0.65, head.Size.Y * 0.45), 0)
        attachment.Parent = head
    end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ProChatSupremeBillboard"
    billboard.Size = UDim2.new(0, bubbleSettings.maxWidth + 90, 0, 270)
    billboard.SizeOffset = Vector2.new(0, 0.35)
    billboard.StudsOffset = Vector3.new(0, bubbleSettings.baseOffsetY, 0)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = bubbleSettings.maxDistance
    billboard.ResetOnSpawn = false
    billboard.Adornee = attachment
    billboard.ZIndexBehavior = Enum.ZIndexBehavior.Global
    billboard.Parent = head

    local container = Instance.new("Frame", billboard)
    container.Name = "Container"
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.AnchorPoint = Vector2.new(0.5, 1)
    container.Position = UDim2.new(0.5, 0, 1, 0)

    local list = Instance.new("UIListLayout", container)
    list.Name = "SupremeBubbleLayout"
    list.Padding = UDim.new(0, bubbleSettings.spacing)
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center
    list.VerticalAlignment = Enum.VerticalAlignment.Bottom
    list.SortOrder = Enum.SortOrder.LayoutOrder

    local bottomPad = Instance.new("UIPadding", container)
    bottomPad.PaddingBottom = UDim.new(0, 4)
    bottomPad.PaddingTop = UDim.new(0, 2)

    playerBubbles[playerName] = {
        billboard = billboard,
        container = container,
        bubbles = {},
        counter = 0,
        head = head,
    }

    return billboard, container
end

local function bubbleCreateShadow(root)
    if not bubbleSettings.glow then
        return nil
    end

    local shadow = Instance.new("Frame", root)
    shadow.Name = "BubbleShadow"
    shadow.AutomaticSize = Enum.AutomaticSize.XY
    shadow.Size = UDim2.new(0, 0, 0, 0)
    shadow.Position = UDim2.new(0, bubbleSettings.shadowOffset.X, 0, bubbleSettings.shadowOffset.Y)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = bubbleSettings.shadowTransparency
    shadow.BorderSizePixel = 0
    shadow.ZIndex = 0
    Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 16)

    return shadow
end

local function bubbleCreateTail(root, color)
    if not bubbleSettings.tailVisible then
        return
    end

    local left = Instance.new("Frame", root)
    left.Name = "TailLeft"
    left.Size = UDim2.new(0, 9, 0, 9)
    left.Position = UDim2.new(0.18, 0, 1, -4)
    left.Rotation = 45
    left.BackgroundColor3 = color
    left.BorderSizePixel = 0
    left.ZIndex = 2

    local tip = Instance.new("Frame", root)
    tip.Name = "TailTip"
    tip.Size = UDim2.new(0, 5, 0, 5)
    tip.Position = UDim2.new(0.20, 0, 1, 0)
    tip.BackgroundColor3 = color
    tip.BorderSizePixel = 0
    tip.ZIndex = 2
end

local function bubbleCreateGradient(root, primary)
    if not bubbleSettings.gradient then
        return
    end

    local gradient = Instance.new("UIGradient", root)
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, primary:Lerp(Color3.new(1,1,1), 0.18)),
        ColorSequenceKeypoint.new(0.5, primary),
        ColorSequenceKeypoint.new(1, primary:Lerp(Color3.new(0,0,0), 0.12)),
    })
    gradient.Rotation = 90
end

local function bubbleCreateRoot(container, playerName, message)
    bubbleSerial += 1

    local accent = bubbleAccentForPlayer(playerName)
    local selfMessage = playerName == LocalPlayer.Name
    local primary = selfMessage and Color3.fromRGB(66, 72, 95) or Color3.fromRGB(248, 248, 252)

    if bubbleSettings.playerAccent and not selfMessage then
        primary = primary:Lerp(accent, 0.16)
    end

    if selfMessage and bubbleSettings.selfAccent then
        primary = primary:Lerp(bubbleSettings.color or accent, 0.14)
    end

    local width = bubbleComputeWidth(message)
    local size = bubbleComputeTextSize(message)

    local root = Instance.new("Frame", container)
    root.Name = "Bubble_" .. tostring(bubbleSerial)
    root.AutomaticSize = Enum.AutomaticSize.XY
    root.Size = UDim2.new(0, width, 0, 0)
    root.BackgroundTransparency = 1
    root.BorderSizePixel = 0
    root.LayoutOrder = bubbleSerial
    root.ZIndex = 5

    local shadow = bubbleCreateShadow(root)
    local body = Instance.new("Frame", root)
    body.Name = "BubbleBody"
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.Size = UDim2.new(1, 0, 0, 0)
    body.BackgroundColor3 = primary
    body.BackgroundTransparency = bubbleSettings.backgroundTransparency
    body.BorderSizePixel = 0
    body.ZIndex = 2

    local corner = Instance.new("UICorner", body)
    corner.CornerRadius = UDim.new(0, 17)

    local stroke = Instance.new("UIStroke", body)
    stroke.Color = accent
    stroke.Thickness = bubbleSettings.strokeThickness
    stroke.Transparency = bubbleSettings.strokeTransparency

    local padding = Instance.new("UIPadding", body)
    padding.PaddingTop = UDim.new(0, bubbleSettings.topPadding)
    padding.PaddingBottom = UDim.new(0, bubbleSettings.bottomPadding)
    padding.PaddingLeft = UDim.new(0, bubbleSettings.leftPadding)
    padding.PaddingRight = UDim.new(0, bubbleSettings.rightPadding)

    bubbleCreateGradient(body, accent)

    local content = Instance.new("Frame", body)
    content.Size = UDim2.new(1, 0, 0, 0)
    content.AutomaticSize = Enum.AutomaticSize.Y
    content.BackgroundTransparency = 1
    content.ZIndex = 3

    local layout = Instance.new("UIListLayout", content)
    layout.Padding = UDim.new(0, 3)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    if bubbleSettings.showPlayerName then
        local name = Instance.new("TextLabel", content)
        name.Size = UDim2.new(1, 0, 0, 18)
        name.BackgroundTransparency = 1
        name.TextColor3 = accent
        name.Font = Enum.Font.GothamBold
        name.TextSize = 12
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.TextYAlignment = Enum.TextYAlignment.Center
        name.Text = selfMessage and (playerName .. "  • أنت") or playerName
        name.ZIndex = 4
    end

    local text = Instance.new("TextLabel", content)
    text.Name = "Message"
    text.Size = UDim2.new(1, 0, 0, 0)
    text.AutomaticSize = Enum.AutomaticSize.Y
    text.BackgroundTransparency = 1
    text.TextColor3 = selfMessage and Color3.fromRGB(250,250,255) or Color3.fromRGB(28,29,34)
    if selfMessage then
        text.TextColor3 = Color3.fromRGB(245,245,250)
    end
    text.Font = Enum.Font.GothamMedium
    text.TextSize = size
    text.TextWrapped = true
    text.TextXAlignment = Enum.TextXAlignment.Center
    text.TextYAlignment = Enum.TextYAlignment.Center
    text.RichText = false
    text.Text = safeBubbleText(message)
    text.ZIndex = 4

    bubbleCreateTail(root, primary)
    return root, body, text, shadow
end

local function bubbleAnimateIn(root, body, text, shadow)
    if not bubbleSettings.popAnimation then
        body.BackgroundTransparency = bubbleSettings.backgroundTransparency
        text.TextTransparency = 0
        if shadow then
            shadow.BackgroundTransparency = bubbleSettings.shadowTransparency
        end
        return
    end

    local originalSize = body.Size
    body.BackgroundTransparency = 1
    text.TextTransparency = 1
    body.Size = UDim2.new(0.88, 0, 0.88, 0)

    if shadow then
        shadow.BackgroundTransparency = 1
        TweenService:Create(
            shadow,
            TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = bubbleSettings.shadowTransparency}
        ):Play()
    end

    TweenService:Create(
        body,
        TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {
            Size = originalSize,
            BackgroundTransparency = bubbleSettings.backgroundTransparency
        }
    ):Play()

    TweenService:Create(
        text,
        TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {TextTransparency = 0}
    ):Play()
end

local function bubbleAnimateFloat(root, duration)
    if not bubbleSettings.floatAnimation then
        return
    end

    local holder = root
    local original = holder.Position

    task.spawn(function()
        local elapsed = 0
        while holder and holder.Parent and elapsed < duration do
            local phase = math.sin(elapsed * 2.4) * 1.3
            holder.Position = UDim2.new(
                original.X.Scale,
                original.X.Offset,
                original.Y.Scale,
                original.Y.Offset + phase
            )
            task.wait(0.05)
            elapsed += 0.05
        end
    end)
end

local function bubbleQueueCleanup(playerName, data, duration)
    task.delay(duration, function()
        local state = playerBubbles[playerName]
        if not state then
            return
        end

        for i, item in ipairs(state.bubbles) do
            if item == data then
                table.remove(state.bubbles, i)
                break
            end
        end

        bubbleDestroyData(data, false)
    end)
end

local function showBubbleAbovePlayer(playerName, message)
    local player = Players:FindFirstChild(playerName)
    if not player or not player.Character then
        return
    end

    local _, container = bubbleGetOrCreateBillboard(playerName, player.Character)
    local state = playerBubbles[playerName]
    if not state or not container then
        return
    end

    state.counter += 1

    local root, body, text, shadow = bubbleCreateRoot(container, playerName, message)
    local data = {
        id = state.counter,
        root = root,
        bubble = body,
        txt = text,
        created = os.clock(),
        message = message,
    }

    table.insert(state.bubbles, data)

    while #state.bubbles > bubbleSettings.maxBubbles do
        local oldest = table.remove(state.bubbles, 1)
        bubbleDestroyData(oldest, false)
    end

    local duration = bubbleComputeDuration(message)
    bubbleAnimateIn(root, body, text, shadow)
    bubbleAnimateFloat(root, duration)
    recordIncomingBubble()
    bubbleQueueCleanup(playerName, data, duration)
end

local function clearPlayerBubbles(playerName, instant)
    local state = playerBubbles[playerName]
    if not state then
        return
    end

    for _, data in ipairs(state.bubbles) do
        bubbleDestroyData(data, instant)
    end
    state.bubbles = {}
end

local function resetBubbleForCharacter(playerName, character)
    clearPlayerBubbles(playerName, true)
    playerBubbles[playerName] = nil
    bubbleGetOrCreateBillboard(playerName, character)
end

local function updateBubbleSettingsVisuals()
    for _, state in pairs(playerBubbles) do
        if state.billboard and state.billboard.Parent then
            state.billboard.Size = UDim2.new(0, bubbleSettings.maxWidth + 90, 0, 270)
            state.billboard.StudsOffset = Vector3.new(0, bubbleSettings.baseOffsetY, 0)
            state.billboard.MaxDistance = bubbleSettings.maxDistance
        end
    end
end


local function setupPlayer(plr)
    playerBubbles[plr.Name] = playerBubbles[plr.Name] or {
        bubbles = {},
        counter = 0,
    }

    local function prepareCharacter(char)
        task.spawn(function()
            local head = char:WaitForChild("Head", 5)
            if not head then
                head = bubbleFindHead(char)
            end
            if head then
                task.wait(0.25)
                resetBubbleForCharacter(plr.Name, char)
            end
        end)
    end

    if plr.Character then
        prepareCharacter(plr.Character)
    end

    plr.CharacterAdded:Connect(function(char)
        prepareCharacter(char)
    end)
end

Players.PlayerAdded:Connect(setupPlayer)
for _, plr in ipairs(Players:GetPlayers()) do
    setupPlayer(plr)
end

Players.PlayerRemoving:Connect(function(plr)
    clearPlayerBubbles(plr.Name, true)
    playerBubbles[plr.Name] = nil
end)

local function sendMessage(text)
    if text == "" then return end
    recordOutgoingMessage()
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

sendBtn.MouseButton1Click:Connect(function()
    if box.Text ~= "" then
        local txt = box.Text
        box.Text = ""
        sendMessage(txt)
    end
end)

box.FocusLost:Connect(function(enterPressed)
    if enterPressed and box.Text ~= "" then
        local txt = box.Text
        box.Text = ""
        sendMessage(txt)
    end
end)


local messageSound = Instance.new("Sound", gui)
messageSound.SoundId = "rbxassetid://6026984224"
messageSound.Volume = 0.65

local function notifyNewMessage()
    if ultimate.sound then pcall(function() messageSound:Play() end) end
    if not isOpen and ultimate.unread then
        unreadDot.Visible = true
        unreadBtn.Visible = true
    end
    if isOpen then return end

    task.spawn(function()
        for _ = 1, 4 do
            if not toggleBtn.Parent then break end
            toggleBtn.BackgroundColor3 = Color3.fromRGB(255,255,255)
            task.wait(0.12)
            toggleBtn.BackgroundColor3 = settings.color
            task.wait(0.12)
        end
    end)
end

local shownIds = {}
local firstLoad = true

task.spawn(function()
    while task.wait(0.05) do
        pcall(function()
            local response = request({
                Url = PROJECT_URL .. "/rest/v1/chat_messages?select=*&order=id.asc&limit=20",
                Method = "GET",
                Headers = {["apikey"] = ANON_KEY, ["Authorization"] = "Bearer " .. ANON_KEY}
            })
            if response and response.Body then
                local decoded = HttpService:JSONDecode(response.Body)
                if type(decoded) == "table" then
                    local newIncoming = false
                    for _, v in ipairs(decoded) do
                        if v.id and not shownIds[v.id] then
                            shownIds[v.id] = true
                            addMessage(v.username, v.message)
                            if not firstLoad and v.username ~= LocalPlayer.Name then
                                showBubbleAbovePlayer(v.username, v.message)
                                newIncoming = true
                            end
                        end
                    end
                    if newIncoming then
                        notifyNewMessage()
                    end
                    firstLoad = false
                    task.defer(function() scrollToBottom(false) end)
                end
            end
        end)
    end
end)

local isOpen = false
local function toggleChatWindow()
    if editButtonMode then return end
    isOpen = not isOpen
    if isOpen then
        unreadDot.Visible = false
        frame.Visible = true
        frame.Size = UDim2.new(0, 0, 0, 0)
        TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Size = UDim2.new(settings.width,0,settings.height,0)}):Play()
        toggleBtn.Text = "✕"
    else
        TweenService:Create(frame, TweenInfo.new(0.15), {Size = UDim2.new(0, 0, 0, 0)}):Play()
        toggleBtn.Text = "💬 Chat"
        task.wait(0.15)
        frame.Visible = false
    end
end)


UserInputService.InputBegan:Connect(function(input, processed)
    if processed or not isMouse then return end
    if input.KeyCode == Enum.KeyCode.T then
        if not isOpen then
            unreadDot.Visible = false
            frame.Visible = true
            isOpen = true
            frame.Size = UDim2.new(settings.width,0,settings.height,0)
            toggleBtn.Text = "✕"
        end
        task.defer(function()
            pcall(function()
                box:CaptureFocus()
                box.CursorPosition = #box.Text + 1
            end)
        end)
    end
end)

refreshSettings()



local function bubbleShortName(name, maxLen)
    name = tostring(name or "")
    if #name <= maxLen then
        return name
    end
    return name:sub(1, maxLen - 1) .. "…"
end

local function bubbleUpdateBillboardForDistance(playerName, distance)
    local state = playerBubbles[playerName]
    if not state or not state.billboard or not state.billboard.Parent then
        return
    end

    local scale = 1
    if bubbleSettings.compactNear then
        if distance < 15 then
            scale = 0.95
        elseif distance > 85 then
            scale = 0.80
        end
    end

    state.billboard.Size = UDim2.new(
        0,
        math.floor((bubbleSettings.maxWidth + 90) * scale),
        0,
        math.floor(270 * scale)
    )
end

task.spawn(function()
    while task.wait(0.25) do
        local camera = workspace.CurrentCamera
        if camera then
            local cameraPos = camera.CFrame.Position
            for playerName, state in pairs(playerBubbles) do
                if state.head and state.head.Parent then
                    local distance = (state.head.Position - cameraPos).Magnitude
                    if distance <= bubbleSettings.maxDistance + 10 then
                        bubbleUpdateBillboardForDistance(playerName, distance)
                    end
                end
            end
        end
    end
end)


-- ============================================================
-- Runtime diagnostics: UI/bubble health only.
-- Does not inspect or modify Supabase.
-- ============================================================

local runtimeStats = {
    createdMessages = 0,
    createdBubbles = 0,
    openCount = 0,
    incomingCount = 0,
    outgoingCount = 0,
    lastIncomingAt = 0,
    lastOutgoingAt = 0,
}

local function recordIncomingBubble()
    runtimeStats.createdBubbles += 1
    runtimeStats.incomingCount += 1
    runtimeStats.lastIncomingAt = os.clock()
end

local function recordOutgoingMessage()
    runtimeStats.outgoingCount += 1
    runtimeStats.lastOutgoingAt = os.clock()
end

local function bubbleGarbageCollect()
    for playerName, state in pairs(playerBubbles) do
        if state.billboard and not state.billboard.Parent then
            playerBubbles[playerName] = nil
        end
    end
end

task.spawn(function()
    while task.wait(10) do
        bubbleGarbageCollect()
    end
end)



-- Extra keyboard shortcuts (UI only)
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if not isMouse then return end

    if input.KeyCode == Enum.KeyCode.Escape then
        settingsPanel.Visible = false
        editButtonMode = false
        editChatMode = false
        stopDrag()
        refreshSettings()
        if box:IsFocused() then
            pcall(function() box:ReleaseFocus() end)
        end
    elseif input.KeyCode == Enum.KeyCode.Home and isOpen then
        messages.CanvasPosition = Vector2.new(0,0)
    elseif input.KeyCode == Enum.KeyCode.End and isOpen then
        scrollToBottom(true)
    elseif input.KeyCode == Enum.KeyCode.F2 then
        settingsPanel.Visible = not settingsPanel.Visible
        editButtonMode = false
        editChatMode = false
        stopDrag()
        refreshSettings()
    end
end)


print("✅ Pro Chat CHATTTT V7 ULTIMATE — original v11 network preserved / no save / supreme bubbles")

box:GetPropertyChangedSignal("Text"):Connect(function()
    if #box.Text > 240 then box.Text = string.sub(box.Text,1,240) end
    if charCounter and charCounter.Parent then
        charCounter.Text = tostring(#box.Text).."/240"
    end
end)

-- Keep the visible-message viewport correct after Roblox recalculates GUI dimensions.
frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    task.defer(updateMessageViewport)
end)

refreshSettings()
