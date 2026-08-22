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
    buttonY = 78,
    chatX = 14,
    chatY = 152,
    color = Color3.fromRGB(88, 101, 242),
}

local MIN_MESSAGES, MAX_MESSAGES = 2, 20
local unreadCount = 0
local isOpen = false
local soundEnabled = true
local bubblesEnabled = true
local autoFollow = true
local compactMode = false
local bubbleMaxWidth = 250
local bubbleTextSize = 14
local bubbleDuration = 5
local maxBubbleStack = 4
local isNearBottom = true

local MIN_W, MAX_W = 0.30, 0.80
local MIN_H, MAX_H = 0.24, 0.78


local gui = Instance.new("ScreenGui")
gui.Name = "ProChat"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.Parent = CoreGui

local toggleBtn = Instance.new("TextButton", gui)
toggleBtn.Name = "ChatButton"
toggleBtn.Size = UDim2.new(0, 104, 0, 42)
toggleBtn.Position = UDim2.new(0, settings.buttonX, 0, settings.buttonY)
toggleBtn.BackgroundColor3 = settings.color
toggleBtn.BackgroundTransparency = 0.08
toggleBtn.Text = "💬  CHAT"
toggleBtn.TextSize = 14
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.BorderSizePixel = 0
toggleBtn.AutoButtonColor = false
toggleBtn.ZIndex = 100
 toggleBtn.Active = true
 toggleBtn.Selectable = true
 toggleBtn.Active = true
toggleBtn.Visible = true
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 12)

local buttonStroke = Instance.new("UIStroke", toggleBtn)
buttonStroke.Color = Color3.fromRGB(255,255,255)
buttonStroke.Transparency = 0.72
buttonStroke.Thickness = 1

local buttonGradient = Instance.new("UIGradient", toggleBtn)
buttonGradient.Rotation = 90
buttonGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(120,130,255)),
    ColorSequenceKeypoint.new(1, settings.color)
})

local buttonScale = Instance.new("UIScale", toggleBtn)
buttonScale.Scale = 1

local unreadBadge = Instance.new("TextLabel", toggleBtn)
unreadBadge.Name = "UnreadBadge"
unreadBadge.Size = UDim2.new(0, 22, 0, 22)
unreadBadge.Position = UDim2.new(1, -8, 0, -8)
unreadBadge.BackgroundColor3 = Color3.fromRGB(245,65,75)
unreadBadge.TextColor3 = Color3.new(1,1,1)
unreadBadge.Font = Enum.Font.GothamBold
unreadBadge.TextSize = 10
unreadBadge.Text = "0"
unreadBadge.Visible = false
unreadBadge.ZIndex = 103
Instance.new("UICorner", unreadBadge).CornerRadius = UDim.new(1,0)

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(settings.width, 0, settings.height, 0)
frame.Position = UDim2.new(0, settings.chatX, 0, settings.chatY)
frame.BackgroundColor3 = Color3.fromRGB(13,14,19)
frame.BackgroundTransparency = 0.04
frame.BorderSizePixel = 0
frame.Visible = false
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)
local frameStroke = Instance.new("UIStroke", frame)
frameStroke.Color = settings.color
frameStroke.Transparency = 0.45
frameStroke.Thickness = 1.2



local header = Instance.new("Frame", frame)
header.Size = UDim2.new(1, -8, 0, 32)
header.Position = UDim2.new(0, 4, 0, 4)
header.BackgroundTransparency = 1
header.ZIndex = 20


local chatStatusPill = Instance.new("TextLabel", header)
chatStatusPill.Name = "OnlineStatus"
chatStatusPill.Size = UDim2.new(0, 84, 0, 22)
chatStatusPill.Position = UDim2.new(1, -128, 0, 4)
chatStatusPill.BackgroundColor3 = Color3.fromRGB(34, 145, 92)
chatStatusPill.BackgroundTransparency = 0.12
chatStatusPill.Text = "● ONLINE"
chatStatusPill.TextColor3 = Color3.new(1,1,1)
chatStatusPill.Font = Enum.Font.GothamBold
chatStatusPill.TextSize = 9
chatStatusPill.BorderSizePixel = 0
chatStatusPill.ZIndex = 22
Instance.new("UICorner", chatStatusPill).CornerRadius = UDim.new(0,9)

local titleLabel = Instance.new("TextLabel", header)
titleLabel.Size = UDim2.new(1, -42, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "💬  Global Chat"
titleLabel.TextColor3 = Color3.new(1,1,1)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 16
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

local onlineStatus = Instance.new("TextLabel", header)
onlineStatus.Size = UDim2.new(0, 92, 0, 18)
onlineStatus.Position = UDim2.new(0, 0, 1, 17)
onlineStatus.BackgroundTransparency = 1
onlineStatus.Text = "● متصل"
onlineStatus.TextColor3 = Color3.fromRGB(100,220,145)
onlineStatus.Font = Enum.Font.GothamBold
onlineStatus.TextSize = 9
onlineStatus.TextXAlignment = Enum.TextXAlignment.Left
onlineStatus.ZIndex = 21

local newMessagesBtn = Instance.new("TextButton", frame)
newMessagesBtn.Name = "NewMessages"
newMessagesBtn.Size = UDim2.new(0, 118, 0, 28)
newMessagesBtn.Position = UDim2.new(0.5, -59, 1, -78)
newMessagesBtn.BackgroundColor3 = settings.color
newMessagesBtn.BackgroundTransparency = 0.08
newMessagesBtn.Text = "↓ رسائل جديدة"
newMessagesBtn.TextColor3 = Color3.new(1,1,1)
newMessagesBtn.Font = Enum.Font.GothamBold
newMessagesBtn.TextSize = 10
newMessagesBtn.Visible = false
newMessagesBtn.ZIndex = 50
Instance.new("UICorner", newMessagesBtn).CornerRadius = UDim.new(0, 10)

local messageCountLabel = Instance.new("TextLabel", frame)
messageCountLabel.Size = UDim2.new(0, 80, 0, 18)
messageCountLabel.Position = UDim2.new(1, -88, 0, 45)
messageCountLabel.BackgroundTransparency = 1
messageCountLabel.Text = "0 رسائل"
messageCountLabel.TextColor3 = Color3.fromRGB(145,150,165)
messageCountLabel.Font = Enum.Font.Gotham
messageCountLabel.TextSize = 9
messageCountLabel.TextXAlignment = Enum.TextXAlignment.Right
messageCountLabel.ZIndex = 25

local messages = Instance.new("ScrollingFrame", frame)
messages.Size = UDim2.new(1, -12, 1, -88)
messages.Position = UDim2.new(0, 6, 0, 40)
messages.CanvasSize = UDim2.new(0, 0, 0, 0)
messages.ScrollBarThickness = 4
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


local messageCounter=Instance.new("TextLabel",frame)
messageCounter.Name="MessageCounter"
messageCounter.Size=UDim2.new(0,70,0,18)
messageCounter.Position=UDim2.new(1,-82,1,-101)
messageCounter.BackgroundTransparency=1
messageCounter.Text="0/200"
messageCounter.TextColor3=Color3.fromRGB(130,135,150)
messageCounter.Font=Enum.Font.Gotham
messageCounter.TextSize=8
messageCounter.TextXAlignment=Enum.TextXAlignment.Right
messageCounter.ZIndex=26

if box then
    box:GetPropertyChangedSignal("Text"):Connect(function()
        if messageCounter then
            messageCounter.Text=tostring(#box.Text).."/200"
            messageCounter.TextColor3=(#box.Text>180) and Color3.fromRGB(235,100,100) or Color3.fromRGB(130,135,150)
        end
    end)
end

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
charCounter.Position = UDim2.new(1, -104, 0, 0)
charCounter.BackgroundTransparency = 1
charCounter.Text = "0/240"
charCounter.TextColor3 = Color3.fromRGB(150,150,160)
charCounter.Font = Enum.Font.Gotham
charCounter.TextSize = 10
charCounter.TextXAlignment = Enum.TextXAlignment.Right
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
settingsPanel.Size = UDim2.new(0, 320, 0, 430)
settingsPanel.Position = UDim2.new(0.5, -160, 0.5, -215)
settingsPanel.BackgroundColor3 = Color3.fromRGB(24,24,27)
settingsPanel.BorderSizePixel = 0
settingsPanel.Visible = false
settingsPanel.ZIndex = 100


local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
local isSmallTouch = isTouch and viewport.X <= 720
local isTabletTouch = isTouch and viewport.X > 720

local function getResponsivePanel()
    local w = isSmallTouch and math.min(viewport.X - 24, 340)
        or isTabletTouch and math.min(viewport.X - 40, 420)
        or math.min(viewport.X - 60, 460)

    local h = isSmallTouch and math.min(viewport.Y - 34, 520)
        or isTabletTouch and math.min(viewport.Y - 60, 560)
        or math.min(viewport.Y - 80, 580)

    return w, h
end

local function placeSettingsPanel()
    local w, h = getResponsivePanel()
    settingsPanel.Size = UDim2.new(0, w, 0, h)
    settingsPanel.Position = UDim2.new(0.5, -w/2, 0.5, -h/2)
end
Instance.new("UICorner", settingsPanel).CornerRadius = UDim.new(0,12)

local settingsStroke = Instance.new("UIStroke", settingsPanel)
settingsStroke.Color = settings.color
settingsStroke.Thickness = 1


local mobileCloseBtn = Instance.new("TextButton", settingsPanel)
mobileCloseBtn.Name = "MobileClose"
mobileCloseBtn.Size = UDim2.new(0, 42, 0, 38)
mobileCloseBtn.Position = UDim2.new(1, -50, 0, 8)
mobileCloseBtn.BackgroundColor3 = Color3.fromRGB(190, 65, 70)
mobileCloseBtn.Text = "✕"
mobileCloseBtn.TextColor3 = Color3.new(1,1,1)
mobileCloseBtn.Font = Enum.Font.GothamBold
mobileCloseBtn.TextSize = 17
mobileCloseBtn.BorderSizePixel = 0
mobileCloseBtn.ZIndex = 120
Instance.new("UICorner", mobileCloseBtn).CornerRadius = UDim.new(0,10)

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
    b.AutoButtonColor = false
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


local settingsScroll = Instance.new("ScrollingFrame", settingsPanel)
settingsScroll.Name = "SettingsScroll"
settingsScroll.Size = UDim2.new(1, -20, 1, -86)
settingsScroll.Position = UDim2.new(0, 10, 0, 76)
settingsScroll.BackgroundTransparency = 1
settingsScroll.BorderSizePixel = 0
settingsScroll.ScrollBarThickness = 4
settingsScroll.ScrollBarImageColor3 = Color3.fromRGB(120,120,130)
settingsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
settingsScroll.CanvasSize = UDim2.new(0,0,0,0)
settingsScroll.ScrollingDirection = Enum.ScrollingDirection.Y
settingsScroll.ZIndex = 105

local settingsScrollPad = Instance.new("UIPadding", settingsScroll)
settingsScrollPad.PaddingBottom = UDim.new(0, 18)

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

local colorTitle = Instance.new("TextLabel", settingsPanel)
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
        settingsStroke.Color = c
        frameStroke.Color = c
        buttonGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, c:Lerp(Color3.new(1,1,1), 0.25)),
            ColorSequenceKeypoint.new(1, c)
        })
    end)
end


local featureTelemetry = Instance.new("TextLabel", settingsPanel)
featureTelemetry.Name = "FeatureTelemetry"
featureTelemetry.Size = UDim2.new(1,-20,0,44)
featureTelemetry.Position = UDim2.new(0,10,0,330)
featureTelemetry.BackgroundColor3 = Color3.fromRGB(30,31,37)
featureTelemetry.BackgroundTransparency = 0.10
featureTelemetry.Text = "SESSION • UI  •  BUBBLES  •  SMART SCROLL"
featureTelemetry.TextColor3 = Color3.fromRGB(175,180,195)
featureTelemetry.Font = Enum.Font.Gotham
featureTelemetry.TextSize = 9
featureTelemetry.TextWrapped = true
featureTelemetry.ZIndex = 101
Instance.new("UICorner", featureTelemetry).CornerRadius = UDim.new(0,8)

local bubbleTitle = Instance.new("TextLabel", settingsPanel)
bubbleTitle.Size = UDim2.new(1,-20,0,20)
bubbleTitle.Position = UDim2.new(0,10,0,330)
bubbleTitle.BackgroundTransparency = 1
bubbleTitle.Text = "☁ الغيمة والواجهة"
bubbleTitle.TextColor3 = Color3.new(1,1,1)
bubbleTitle.Font = Enum.Font.GothamBold
bubbleTitle.TextSize = 11
bubbleTitle.TextXAlignment = Enum.TextXAlignment.Left
bubbleTitle.ZIndex = 101

local soundBtn = sbtn("🔊 الصوت",10,354,82,28)
local bubbleBtn = sbtn("☁ الغيمة",98,354,82,28)
local followBtn = sbtn("↓ تلقائي",186,354,82,28)
local compactBtn = sbtn("Compact",274,354,38,28)

local resetBtn = sbtn("↺ افتراضي",10,390,92,30)
local closeSettings = sbtn("إغلاق",108,390,92,30)

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

local editButtonMode = false
local editChatMode = false
local dragTarget = nil
local dragStart = nil
local dragOrigin = nil

local function placeSettingsPanel()
refreshSettings()
    frame.Size = UDim2.new(settings.width,0,settings.height,0)
    frame.Position = UDim2.new(0,settings.chatX,0,settings.chatY)
    toggleBtn.Position = UDim2.new(0,settings.buttonX,0,settings.buttonY)
    toggleBtn.BackgroundColor3 = settings.color
    buttonGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, settings.color:Lerp(Color3.new(1,1,1), 0.25)),
        ColorSequenceKeypoint.new(1, settings.color)
    })
    frameStroke.Color = settings.color
    sendBtn.BackgroundColor3 = settings.color
    local fw = compactMode and math.min(settings.width,0.36) or settings.width
    local fh = compactMode and math.min(settings.height,0.32) or settings.height
    frame.Size = UDim2.new(fw,0,fh,0)
    if soundBtn then soundBtn.Text = soundEnabled and "🔊 الصوت" or "🔇 الصوت" end
    if bubbleBtn then bubbleBtn.Text = bubblesEnabled and "☁ الغيمة" or "☁ OFF" end
    if followBtn then followBtn.Text = autoFollow and "↓ تلقائي" or "↓ يدوي" end
    if compactBtn then compactBtn.Text = compactMode and "Normal" or "Compact" end
    msgInfo.Text = "الرسائل الظاهرة: " .. tostring(settings.visibleMessages)
    sizeInfo.Text = string.format("الحجم: %d%% × %d%%", math.floor(settings.width*100), math.floor(settings.height*100))
    moveBtn.BackgroundColor3 = editButtonMode and Color3.fromRGB(190,145,45) or settings.color
    moveChat.BackgroundColor3 = editChatMode and Color3.fromRGB(190,145,45) or settings.color
    updateSettingsState()
end


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
    elseif dragTarget == frame then
        settings.chatX, settings.chatY = x, y
    end
    updateSettingsState()
end


buttonSizeMinus.MouseButton1Click:Connect(function()
    settings.buttonWidth=math.clamp((settings.buttonWidth or 82)-6,58,130)
    settings.buttonHeight=math.clamp((settings.buttonHeight or 36)-2,28,60)
    toggleBtn.Size=UDim2.new(0,settings.buttonWidth,0,settings.buttonHeight)
    showLegendaryToast("حجم الزر: "..settings.buttonWidth.."×"..settings.buttonHeight,1.1)
end)

buttonSizePlus.MouseButton1Click:Connect(function()
    settings.buttonWidth=math.clamp((settings.buttonWidth or 82)+6,58,130)
    settings.buttonHeight=math.clamp((settings.buttonHeight or 36)+2,28,60)
    toggleBtn.Size=UDim2.new(0,settings.buttonWidth,0,settings.buttonHeight)
    showLegendaryToast("حجم الزر: "..settings.buttonWidth.."×"..settings.buttonHeight,1.1)
end)

presetBtn.MouseButton1Click:Connect(cyclePreset)

focusBtn.MouseButton1Click:Connect(function()
    toggleFocusMode()
    showLegendaryToast(LEGENDARY_FEATURES.focusMode and "Focus Mode ON" or "Focus Mode OFF",1.2)
end)


settingsBtn.MouseButton1Click:Connect(function()
    if not settingsPanel.Visible then placeSettingsPanel() end
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



soundBtn.MouseButton1Click:Connect(function()
    soundEnabled = not soundEnabled
    soundBtn.Text = soundEnabled and "🔊 الصوت" or "🔇 الصوت"
end)

bubbleBtn.MouseButton1Click:Connect(function()
    bubblesEnabled = not bubblesEnabled
    bubbleBtn.Text = bubblesEnabled and "☁ الغيمة" or "☁ OFF"
end)

followBtn.MouseButton1Click:Connect(function()
    autoFollow = not autoFollow
    followBtn.Text = autoFollow and "↓ تلقائي" or "↓ يدوي"
end)

compactBtn.MouseButton1Click:Connect(function()
    compactMode = not compactMode
    compactBtn.Text = compactMode and "Normal" or "Compact"
    refreshSettings()
end)

resetBtn.MouseButton1Click:Connect(function()
    settings.width = 0.39
    settings.height = 0.36
    settings.visibleMessages = isTouch and 4 or 10
    settings.buttonX = 12
    settings.buttonY = 78
    settings.chatX = 14
    settings.chatY = 152
    soundEnabled = true
    bubblesEnabled = true
    autoFollow = true
    compactMode = false
    bubbleMaxWidth = 250
    bubbleTextSize = 14
    bubbleDuration = 5
    maxBubbleStack = 4
    settings.color = Color3.fromRGB(88,101,242)
    toggleBtn.BackgroundColor3 = settings.color
    sendBtn.BackgroundColor3 = settings.color
    settingsStroke.Color = settings.color
    frameStroke.Color = settings.color
    buttonGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, settings.color:Lerp(Color3.new(1,1,1), 0.25)),
        ColorSequenceKeypoint.new(1, settings.color)
    })
    editButtonMode = false
    editChatMode = false
    stopDrag()
    refreshSettings()
end)

mobileCloseBtn.MouseButton1Click:Connect(function()
    settingsPanel.Visible = false
    editButtonMode = false
    editChatMode = false
    stopDrag()
    refreshSettings()
end)

closeSettings.MouseButton1Click:Connect(function()
    showEventStatus("تم تثبيت إعدادات الشات", 1.5)
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
    -- visibleMessages controls how many messages are comfortably visible.
    -- It NEVER deletes old messages; the ScrollingFrame keeps them available.
end

local function addMessage(user, msg)
    if emptyHint then emptyHint.Visible = false end
    local color = getColor(user)
    local hex = colorToHex(color)
    local displayName = user == LocalPlayer.Name and ("(" .. user .. "  )") or ("(" .. user .. ")")

    local label = Instance.new("TextLabel", messages)
    label.Size = UDim2.new(1, 0, 0, 0)
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.BackgroundTransparency = 1
    label.RichText = true
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = compactMode and 11 or 13
    label.TextWrapped = true
    label.LineHeight = 1.05
    label.TextXAlignment = Enum.TextXAlignment.Right
    label.Text = string.format('%s  <font color="%s"><b>%s</b></font>', msg, hex, displayName)

    label.TextTransparency = 1
    TweenService:Create(label, TweenInfo.new(0.15), {TextTransparency = 0}):Play()

    trimVisibleMessages()
    messageCountLabel.Text = tostring(#messages:GetChildren() - 1) .. " رسائل"
    task.wait(0.01)
    if autoFollow and isNearBottom then
        messages.CanvasPosition = Vector2.new(0, messages.AbsoluteCanvasSize.Y)
    end
end


messages:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
    local bottom = math.max(0, messages.AbsoluteCanvasSize.Y - messages.AbsoluteWindowSize.Y)
    isNearBottom = messages.CanvasPosition.Y >= bottom - 30
    newMessagesBtn.Visible = (not isNearBottom and unreadCount > 0 and not isOpen) or (not isNearBottom and unreadCount > 0)
end)

newMessagesBtn.MouseButton1Click:Connect(function()
    messages.CanvasPosition = Vector2.new(0, messages.AbsoluteCanvasSize.Y)
    unreadCount = 0
    unreadBadge.Visible = false
    newMessagesBtn.Visible = false
    isNearBottom = true
end)


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
    billboard.Size = UDim2.new(0, 320, 0, 220)
    billboard.SizeOffset = Vector2.new(0, 0.5)
    billboard.StudsOffset = Vector3.new(0, 0.25, 0)
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

local function createBubble(container, message, playerName)
    local bubble = Instance.new("Frame", container)
    bubble.AutomaticSize = Enum.AutomaticSize.XY
    bubble.Size = UDim2.new(0, 0, 0, 0)
    bubble.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    bubble.BackgroundTransparency = 0.05
    bubble.BorderSizePixel = 0
    Instance.new("UICorner", bubble).CornerRadius = UDim.new(0, 16)
    local bs = Instance.new("UIStroke", bubble)
    bs.Color = getColor(playerName or "")
    bs.Transparency = 0.25
    bs.Thickness = 1

    local bg = Instance.new("UIGradient", bubble)
    bg.Rotation = 90
    bg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(225,230,245))
    })

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
    txt.TextSize = bubbleTextSize
    txt.TextWrapped = true
    txt.RichText = true
    txt.TextXAlignment = Enum.TextXAlignment.Center

    local sc = Instance.new("UISizeConstraint", txt)
    sc.MaxSize = Vector2.new(bubbleMaxWidth, math.huge)

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
    if not bubblesEnabled then return end
    local player = Players:FindFirstChild(playerName)
    if not player or not player.Character then return end

    local billboard = getBillboard(player.Character)
    if not billboard then return end

    local container = billboard:FindFirstChild("Container")
    if not container then return end

    if not playerBubbles[playerName] then playerBubbles[playerName] = {} end
    local bubbleList = playerBubbles[playerName]

    if #bubbleList >= maxBubbleStack then
        local oldest = table.remove(bubbleList, 1)
        removeBubble(oldest)
    end

    local bubble, txt = createBubble(container, message, playerName)
    local data = {bubble = bubble, txt = txt}
    table.insert(bubbleList, data)

    task.delay(bubbleDuration, function()
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


local function enforceTenMessages()
    task.spawn(function()
        pcall(function()
            local response = request({
                Url = PROJECT_URL .. "/rest/v1/chat_messages?select=id&order=id.desc&limit=100",
                Method = "GET",
                Headers = {["apikey"] = ANON_KEY, ["Authorization"] = "Bearer " .. ANON_KEY}
            })
            if not response or not response.Body then return end
            local rows = HttpService:JSONDecode(response.Body)
            if type(rows) ~= "table" or #rows <= 10 then return end

            for i = 11, #rows do
                local id = rows[i].id
                if id then
                    pcall(function()
                        request({
                            Url = PROJECT_URL .. "/rest/v1/chat_messages?id=eq." .. tostring(id),
                            Method = "DELETE",
                            Headers = {
                                ["apikey"] = ANON_KEY,
                                ["Authorization"] = "Bearer " .. ANON_KEY,
                                ["Prefer"] = "return=minimal"
                            }
                        })
                    end)
                end
            end
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

local messageSound = Instance.new("Sound", gui)
messageSound.SoundId = "rbxassetid://6026984224"
messageSound.Volume = 0.65

local function notifyNewMessage()
    if soundEnabled then pcall(function() messageSound:Play() end) end
    if isOpen then return end
    unreadCount = math.min(99, unreadCount + 1)
    unreadBadge.Text = tostring(unreadCount)
    unreadBadge.Visible = true
    newMessagesBtn.Visible = true

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

local emptyHint = Instance.new("TextLabel", messages)
emptyHint.Name = "EmptyHint"
emptyHint.Size = UDim2.new(1,-20,0,50)
emptyHint.Position = UDim2.new(0,10,0.5,-25)
emptyHint.BackgroundTransparency = 1
emptyHint.Text = "لا توجد رسائل بعد\\nابدأ المحادثة ✨"
emptyHint.TextColor3 = Color3.fromRGB(130,135,150)
emptyHint.Font = Enum.Font.GothamMedium
emptyHint.TextSize = 13
emptyHint.TextWrapped = true
emptyHint.Visible = true
emptyHint.ZIndex = 5

local shownIds = {}
local firstLoad = true

task.spawn(function()
    while task.wait(0.15) do
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
                    if firstLoad then
                        task.defer(function()
                            messages.CanvasPosition = Vector2.new(0, messages.AbsoluteCanvasSize.Y)
                            isNearBottom = true
                        end)
                    end
                    firstLoad = false
                end
            end
        end)
    end
end)

local function openOrCloseChat()
    if editButtonMode then return end
    isOpen = not isOpen
    if isOpen then
        unreadCount = 0
        unreadBadge.Text = "0"
        unreadBadge.Visible = false
        newMessagesBtn.Visible = false
        frame.Visible = true
        frame.Size = UDim2.new(0, 0, 0, 0)
        TweenService:Create(frame, TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(settings.width,0,settings.height,0)
        }):Play()
        toggleBtn.Text = "✕"
    else
        TweenService:Create(frame, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0,0,0,0)
        }):Play()
        toggleBtn.Text = "💬 CHAT"
        task.delay(0.16, function()
            if not isOpen then frame.Visible=false end
        end)
    end
end

toggleBtn.Activated:Connect(openOrCloseChat)





UserInputService.InputBegan:Connect(function(input, processed)
    if processed or not isMouse then return end
    if input.KeyCode == Enum.KeyCode.T then
        if not isOpen then
            unreadCount = 0
            unreadBadge.Visible = false
            newMessagesBtn.Visible = false
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

print("✅ Pro Chat CHATTTT — original v11 network + settings, no save")

box:GetPropertyChangedSignal("Text"):Connect(function()
    if #box.Text > 240 then box.Text = string.sub(box.Text,1,240) end
    if charCounter and charCounter.Parent then
        charCounter.Text = tostring(#box.Text).."/240"
    end
end)


local settingsDragging = false
local settingsDragStart = nil
local settingsOrigin = nil

local function startSettingsDrag(input)
    settingsDragging = true
    settingsDragStart = input.Position
    settingsOrigin = settingsPanel.Position
end

local function updateSettingsDrag(input)
    if not settingsDragging then return end
    local d = input.Position - settingsDragStart
    local w, h = settingsPanel.AbsoluteSize.X, settingsPanel.AbsoluteSize.Y
    local maxX = math.max(8, gui.AbsoluteSize.X - w - 8)
    local maxY = math.max(8, gui.AbsoluteSize.Y - h - 8)
    local x = math.clamp(settingsOrigin.X.Offset + d.X, 8 - w/2, maxX - w/2)
    local y = math.clamp(settingsOrigin.Y.Offset + d.Y, 8 - h/2, maxY - h/2)
    settingsPanel.Position = UDim2.new(0.5, x, 0.5, y)
end

local function stopSettingsDrag()
    settingsDragging = false
end

stTitle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        startSettingsDrag(input)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if settingsDragging and
        (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        updateSettingsDrag(input)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        stopSettingsDrag()
    end
end)


local function refreshResponsiveLayout()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local size = cam.ViewportSize
    local touchDevice = UserInputService.TouchEnabled

    local horizontal = touchDevice and math.clamp(size.X * 0.05, 8, 20) or 12
    local vertical = touchDevice and math.clamp(size.Y * 0.10, 72, 120) or 82

    -- Button stays below Roblox's top-left UI area.
    settings.buttonX = math.clamp(settings.buttonX, horizontal, math.max(horizontal, size.X - toggleBtn.AbsoluteSize.X - 10))
    settings.buttonY = math.clamp(settings.buttonY, vertical, math.max(vertical, size.Y - toggleBtn.AbsoluteSize.Y - 12))

    -- Keep chat within screen.
    settings.chatX = math.clamp(settings.chatX, 6, math.max(6, size.X - frame.AbsoluteSize.X - 6))
    settings.chatY = math.clamp(settings.chatY, vertical + 24, math.max(vertical + 24, size.Y - frame.AbsoluteSize.Y - 6))

    refreshSettings()
end

if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        task.defer(function()
            placeSettingsPanel()
            refreshResponsiveLayout()
        end)
    end)
end


local function resetResponsiveLayout()
    settings.buttonX = 14
    settings.buttonY = 96
    settings.buttonWidth = 82
    settings.buttonHeight = 36
    settings.chatX = 14
    settings.chatY = 152
    refreshResponsiveLayout()
end


local eventStatus = Instance.new("TextLabel", gui)
eventStatus.Name = "EventStatus"
eventStatus.Size = UDim2.new(0, 260, 0, 26)
eventStatus.Position = UDim2.new(0.5, -130, 0, 12)
eventStatus.BackgroundColor3 = Color3.fromRGB(20,21,26)
eventStatus.BackgroundTransparency = 0.12
eventStatus.Text = "ProChat • Ready"
eventStatus.TextColor3 = Color3.fromRGB(185,190,205)
eventStatus.Font = Enum.Font.GothamBold
eventStatus.TextSize = 10
eventStatus.BorderSizePixel = 0
eventStatus.Visible = false
eventStatus.ZIndex = 500
Instance.new("UICorner", eventStatus).CornerRadius = UDim.new(0,9)

local function showEventStatus(text, seconds)
    eventStatus.Text = tostring(text or "")
    eventStatus.Visible = true
    task.delay(seconds or 1.8, function()
        if eventStatus and eventStatus.Parent then
            eventStatus.Visible = false
        end
    end)
end


-- ============================================================
-- PROCHAT V7 LEGENDARY FEATURE ENGINE
-- UX ideas inspired by Roblox TextChatService capabilities:
-- customizable window/input/bubbles, commands, metadata,
-- system messages and responsive front-end behavior.
-- This layer remains local and does not replace the existing
-- Supabase transport.
-- ============================================================

local LEGENDARY_FEATURES = {
    adaptiveButton = true,
    smartScroll = true,
    unreadCounter = true,
    typingState = true,
    draftRestore = true,
    quickReply = true,
    replyPreview = true,
    copyMessage = true,
    pinLocalMessage = true,
    localSearch = true,
    jumpToNewest = true,
    jumpToFirstUnread = true,
    compactMode = false,
    focusMode = false,
    accessibilityMode = false,
    bubbleAutoScale = true,
    bubbleQueue = true,
    bubbleCollapse = true,
    bubbleEmphasis = true,
    mentionHighlight = true,
    linkHighlight = true,
    emojiShortcut = true,
    characterCounter = true,
    sendCooldown = true,
    duplicateGuard = true,
    draftIndicator = true,
    onlineIndicator = true,
    sessionStats = true,
    messageAnimations = true,
    buttonPulse = true,
    settingsSearch = true,
    presets = true,
    resetLayout = true,
}

local legendaryState = {
    unread = 0,
    firstUnreadIndex = nil,
    draft = "",
    lastSent = "",
    lastSentAt = 0,
    selectedMessage = nil,
    pinnedMessage = nil,
    search = "",
    typing = false,
    focus = false,
    copied = 0,
    sent = 0,
    received = 0,
}

local function lc(v)
    return string.lower(tostring(v or ""))
end

local function containsWord(text, needle)
    return lc(text):find(lc(needle), 1, true) ~= nil
end

local function isLikelyLink(text)
    return tostring(text):match("https?://") ~= nil
end

local function looksLikeMention(text)
    return tostring(text):match("@[%w_]+") ~= nil
end

local function messageAccent(text)
    if looksLikeMention(text) and LEGENDARY_FEATURES.mentionHighlight then
        return Color3.fromRGB(105, 155, 255)
    elseif isLikelyLink(text) and LEGENDARY_FEATURES.linkHighlight then
        return Color3.fromRGB(75, 190, 225)
    end
    return nil
end

local function showLegendaryToast(text, seconds)
    if showEventStatus then
        showEventStatus(text, seconds or 1.7)
    end
end

local function adaptiveButtonSize()
    local cam=workspace.CurrentCamera
    if not cam then return end
    local x=cam.ViewportSize.X
    if x <= 420 then
        settings.buttonWidth=74
        settings.buttonHeight=34
    elseif x <= 720 then
        settings.buttonWidth=82
        settings.buttonHeight=36
    else
        settings.buttonWidth=94
        settings.buttonHeight=40
    end
    if toggleBtn then
        toggleBtn.Size=UDim2.new(0,settings.buttonWidth,0,settings.buttonHeight)
    end
end

local function saveDraftLocal()
    if box then
        legendaryState.draft=box.Text or ""
    end
end

local function restoreDraftLocal()
    if box and legendaryState.draft ~= "" then
        box.Text=legendaryState.draft
    end
end

local function clearDraftLocal()
    legendaryState.draft=""
end

local function updateTypingState()
    if not LEGENDARY_FEATURES.typingState or not box then return end
    local active=box:IsFocused() and box.Text~=""
    if active ~= legendaryState.typing then
        legendaryState.typing=active
        if quickStatus and quickStatus.Parent then
            quickStatus.Text=active and "Typing • جاهز للإرسال" or "Global • Online"
        end
    end
end

if box then
    box:GetPropertyChangedSignal("Text"):Connect(function()
        saveDraftLocal()
        updateTypingState()
    end)
    box.Focused:Connect(updateTypingState)
    box.FocusLost:Connect(updateTypingState)
end

local function toggleFocusMode()
    LEGENDARY_FEATURES.focusMode=not LEGENDARY_FEATURES.focusMode
    if frame then
        frame.BackgroundTransparency=LEGENDARY_FEATURES.focusMode and 0.02 or 0.10
    end
    if titleLabel then
        titleLabel.Text=LEGENDARY_FEATURES.focusMode and "PROCHAT  •  FOCUS" or "PROCHAT"
    end
end

local function applyCompactMode()
    if LEGENDARY_FEATURES.compactMode then
        settings.width=math.min(settings.width or .39,.34)
        settings.height=math.min(settings.height or .36,.30)
        bubbleSettings.maxWidth=240
        bubbleSettings.textSize=15
        bubbleSettings.maxBubbles=4
    else
        settings.width=.39
        settings.height=.36
        bubbleSettings.maxWidth=340
        bubbleSettings.textSize=17
        bubbleSettings.maxBubbles=6
    end
    if refreshSettings then refreshSettings() end
    if refreshBubbleUI then refreshBubbleUI() end
end

local function cyclePreset()
    local presets={
        {name="Classic",w=.39,h=.36,bw=82,bh=36,bub=340,ts=17},
        {name="Mobile",w=.43,h=.42,bw=74,bh=34,bub=280,ts=16},
        {name="Compact",w=.34,h=.30,bw=72,bh=32,bub=235,ts=15},
        {name="Cinema",w=.46,h=.40,bw=96,bh=40,bub=390,ts=18},
    }
    legendaryState.preset=(legendaryState.preset or 0)%#presets+1
    local p=presets[legendaryState.preset]
    settings.width=p.w
    settings.height=p.h
    settings.buttonWidth=p.bw
    settings.buttonHeight=p.bh
    bubbleSettings.maxWidth=p.bub
    bubbleSettings.textSize=p.ts
    if toggleBtn then toggleBtn.Size=UDim2.new(0,p.bw,0,p.bh) end
    if refreshSettings then refreshSettings() end
    if refreshBubbleUI then refreshBubbleUI() end
    showLegendaryToast("Preset: "..p.name,1.4)
end

local function markUnread()
    if not LEGENDARY_FEATURES.unreadCounter or isOpen then return end
    legendaryState.unread+=1
end

local function clearUnread()
    legendaryState.unread=0
    legendaryState.firstUnreadIndex=nil
end

local function updateLegendaryButton()
    if not toggleBtn then return end
    if LEGENDARY_FEATURES.adaptiveButton then
        adaptiveButtonSize()
    end
    if LEGENDARY_FEATURES.buttonPulse and legendaryState.unread>0 then
        toggleBtn.BackgroundColor3=Color3.fromRGB(90,105,165)
    else
        toggleBtn.BackgroundColor3=settings.color or Color3.fromRGB(88,101,242)
    end
end

local function legendarySessionInfo()
    return string.format(
        "Sent %d • Received %d • Unread %d",
        legendaryState.sent,
        legendaryState.received,
        legendaryState.unread
    )
end

task.spawn(function()
    while task.wait(.25) do
        updateLegendaryButton()
        updateTypingState()
    end
end)

if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(adaptiveButtonSize)
end


local legendaryQuickMenu=Instance.new("Frame",gui)
legendaryQuickMenu.Name="LegendaryQuickMenu"
legendaryQuickMenu.Size=UDim2.new(0,270,0,190)
legendaryQuickMenu.BackgroundColor3=Color3.fromRGB(22,23,29)
legendaryQuickMenu.BackgroundTransparency=.04
legendaryQuickMenu.BorderSizePixel=0
legendaryQuickMenu.Visible=false
legendaryQuickMenu.ZIndex=900
Instance.new("UICorner",legendaryQuickMenu).CornerRadius=UDim.new(0,14)

local quickMenuTitle=Instance.new("TextLabel",legendaryQuickMenu)
quickMenuTitle.Size=UDim2.new(1,-20,0,28)
quickMenuTitle.Position=UDim2.new(0,10,0,8)
quickMenuTitle.BackgroundTransparency=1
quickMenuTitle.Text="⚡ Quick Chat"
quickMenuTitle.TextColor3=Color3.new(1,1,1)
quickMenuTitle.Font=Enum.Font.GothamBold
quickMenuTitle.TextSize=13
quickMenuTitle.TextXAlignment=Enum.TextXAlignment.Left
quickMenuTitle.ZIndex=901

local function quickItem(txt,y)
    local b=Instance.new("TextButton",legendaryQuickMenu)
    b.Size=UDim2.new(1,-20,0,30)
    b.Position=UDim2.new(0,10,0,y)
    b.BackgroundColor3=Color3.fromRGB(40,41,49)
    b.Text=txt
    b.TextColor3=Color3.fromRGB(235,236,242)
    b.Font=Enum.Font.GothamMedium
    b.TextSize=10
    b.BorderSizePixel=0
    b.ZIndex=901
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,8)
    return b
end

local qr1=quickItem("👋 مرحباً!",42)
local qr2=quickItem("😂 ههههه",76)
local qr3=quickItem("👍 تمام",110)
local qr4=quickItem("❓ لحظة",144)

local function quickSend(text)
    if box then
        box.Text=text
        box:CaptureFocus()
    end
    legendaryQuickMenu.Visible=false
end
qr1.MouseButton1Click:Connect(function() quickSend("مرحباً!") end)
qr2.MouseButton1Click:Connect(function() quickSend("ههههه") end)
qr3.MouseButton1Click:Connect(function() quickSend("تمام 👍") end)
qr4.MouseButton1Click:Connect(function() quickSend("لحظة...") end)


UserInputService.InputBegan:Connect(function(input,processed)
    if processed then return end

    if input.KeyCode==Enum.KeyCode.Slash and isOpen and not box:IsFocused() then
        legendaryQuickMenu.Position=UDim2.new(
            0,
            math.clamp(settings.chatX+10,8,math.max(8,gui.AbsoluteSize.X-278)),
            0,
            math.clamp(settings.chatY+55,8,math.max(8,gui.AbsoluteSize.Y-198))
        )
        legendaryQuickMenu.Visible=not legendaryQuickMenu.Visible
    elseif input.KeyCode==Enum.KeyCode.Escape then
        legendaryQuickMenu.Visible=false
    end
end)

task.spawn(function()
    while task.wait(1) do
        if legendaryInfo and legendaryInfo.Parent then
            legendaryInfo.Text="Legendary • "..legendarySessionInfo()
        end
    end
end)
