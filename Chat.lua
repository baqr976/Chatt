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
    buttonY = 12,
    buttonW = 78,
    buttonH = 36,
    chatX = 12,
    chatY = 55,
    color = Color3.fromRGB(88, 101, 242),
    muted = false,
    autoScroll = true,
    messageFontSize = 12,
    highContrast = false,
    compactMode = false,
    reduceMotion = false,
}

local APP = {
    name = "Pro Chat",
    version = "12.0",
    maxMessageLength = 240,
    sendCooldown = 0.45,
    pollInterval = 1.25,
    historyLimit = 20,
}

local MIN_MESSAGES, MAX_MESSAGES = 2, 20
local MIN_W, MAX_W = 0.30, 0.80
local MIN_H, MAX_H = 0.24, 0.78
local editButtonMode = false
local editChatMode = false
local isOpen = false


local gui = Instance.new("ScreenGui")
gui.Name = "ProChat"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = CoreGui

local toggleBtn = Instance.new("TextButton", gui)
toggleBtn.Size = UDim2.new(0, settings.buttonW, 0, settings.buttonH)
toggleBtn.Position = UDim2.new(0, settings.buttonX, 0, settings.buttonY)
toggleBtn.BackgroundColor3 = settings.color
toggleBtn.BackgroundTransparency = 0.5
toggleBtn.Text = "💬  CHAT"
toggleBtn.TextSize = 13
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.BorderSizePixel = 0
toggleBtn.AutoButtonColor = false
toggleBtn.ZIndex = 10
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)
local toggleStroke = Instance.new("UIStroke", toggleBtn)
toggleStroke.Color = Color3.fromRGB(180, 190, 255)
toggleStroke.Transparency = 0.35

local unreadBadge = Instance.new("TextLabel", toggleBtn)
unreadBadge.Size = UDim2.new(0, 17, 0, 17)
unreadBadge.Position = UDim2.new(1, -8, 0, -7)
unreadBadge.BackgroundColor3 = Color3.fromRGB(255, 83, 105)
unreadBadge.Text = "0"
unreadBadge.TextColor3 = Color3.new(1, 1, 1)
unreadBadge.Font = Enum.Font.GothamBold
unreadBadge.TextSize = 9
unreadBadge.Visible = false
unreadBadge.ZIndex = 12
Instance.new("UICorner", unreadBadge).CornerRadius = UDim.new(1, 0)

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(settings.width, 0, settings.height, 0)
frame.Position = UDim2.new(0, settings.chatX, 0, settings.chatY)
frame.BackgroundColor3 = Color3.fromRGB(18, 20, 30)
frame.BackgroundTransparency = 0.08
frame.BorderSizePixel = 0
frame.Visible = false
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
local frameStroke = Instance.new("UIStroke", frame)
frameStroke.Color = Color3.fromRGB(105, 122, 255)
frameStroke.Transparency = 0.45
frameStroke.Thickness = 1
local frameGradient = Instance.new("UIGradient", frame)
frameGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(29, 33, 53)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 13, 20)),
})
frameGradient.Rotation = 90

local toast = Instance.new("TextLabel", gui)
toast.Size = UDim2.new(0, 260, 0, 32)
toast.Position = UDim2.new(0.5, -130, 0, 18)
toast.BackgroundColor3 = Color3.fromRGB(31, 36, 56)
toast.BackgroundTransparency = 1
toast.BorderSizePixel = 0
toast.Text = ""
toast.TextColor3 = Color3.fromRGB(238, 240, 255)
toast.TextTransparency = 1
toast.Font = Enum.Font.GothamBold
toast.TextSize = 11
toast.Visible = false
toast.ZIndex = 200
Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 8)
local toastStroke = Instance.new("UIStroke", toast)
toastStroke.Color = settings.color
toastStroke.Transparency = 1


local header = Instance.new("Frame", frame)
header.Size = UDim2.new(1, -8, 0, 32)
header.Position = UDim2.new(0, 4, 0, 4)
header.BackgroundTransparency = 1
header.ZIndex = 20

local titleLabel = Instance.new("TextLabel", header)
titleLabel.Size = UDim2.new(1, -42, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "GLOBAL  •  CHAT"
titleLabel.TextColor3 = Color3.new(1,1,1)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 15
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 21

local onlineDot = Instance.new("Frame", header)
onlineDot.Size = UDim2.new(0, 7, 0, 7)
onlineDot.Position = UDim2.new(0, 2, 1, 2)
onlineDot.BackgroundColor3 = Color3.fromRGB(81, 221, 142)
onlineDot.BorderSizePixel = 0
onlineDot.ZIndex = 21
Instance.new("UICorner", onlineDot).CornerRadius = UDim.new(1, 0)

local pcHint = Instance.new("TextLabel", header)
pcHint.Size = UDim2.new(0, 150, 0, 20)
pcHint.Position = UDim2.new(0, 12, 1, 0)
pcHint.BackgroundTransparency = 1
pcHint.Text = isMouse and "متصل الآن  •  اضغط T للكتابة" or "متصل الآن"
pcHint.TextColor3 = Color3.fromRGB(175,175,185)
pcHint.Font = Enum.Font.Gotham
pcHint.TextSize = 10
pcHint.TextXAlignment = Enum.TextXAlignment.Left
pcHint.ZIndex = 21

local connectionLabel = Instance.new("TextLabel", header)
connectionLabel.Size = UDim2.new(0, 80, 0, 18)
connectionLabel.Position = UDim2.new(1, -120, 1, 1)
connectionLabel.BackgroundColor3 = Color3.fromRGB(48, 61, 69)
connectionLabel.BackgroundTransparency = 0.18
connectionLabel.Text = "● متصل"
connectionLabel.TextColor3 = Color3.fromRGB(133, 240, 174)
connectionLabel.Font = Enum.Font.GothamBold
connectionLabel.TextSize = 9
connectionLabel.ZIndex = 23
Instance.new("UICorner", connectionLabel).CornerRadius = UDim.new(1, 0)

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

local headerLine = Instance.new("Frame", frame)
headerLine.Size = UDim2.new(1, -16, 0, 1)
headerLine.Position = UDim2.new(0, 8, 0, 38)
headerLine.BackgroundColor3 = Color3.fromRGB(100, 114, 190)
headerLine.BackgroundTransparency = 0.68
headerLine.BorderSizePixel = 0

local messages = Instance.new("ScrollingFrame", frame)
messages.Size = UDim2.new(1, -8, 1, -102)
messages.Position = UDim2.new(0, 4, 0, 40)
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

local toolBar = Instance.new("Frame", frame)
toolBar.Size = UDim2.new(1, -8, 0, 24)
toolBar.Position = UDim2.new(0, 4, 1, -58)
toolBar.BackgroundTransparency = 1
toolBar.BorderSizePixel = 0

local function toolButton(text, order)
    local button = Instance.new("TextButton", toolBar)
    button.Size = UDim2.new(0, 42, 1, 0)
    button.Position = UDim2.new(1, -(order * 46), 0, 0)
    button.BackgroundColor3 = Color3.fromRGB(43, 47, 69)
    button.BackgroundTransparency = 0.16
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = Color3.fromRGB(225, 228, 255)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 11
    button.AutoButtonColor = false
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)
    return button
end

local searchBtn = toolButton("⌕", 1)
local muteBtn = toolButton("🔊", 2)
local scrollBtn = toolButton("↓", 3)
local clearBtn = toolButton("⌫", 4)
local emojiBtn = toolButton("😊", 5)

local playerCount = Instance.new("TextButton", toolBar)
playerCount.Size = UDim2.new(0, 110, 1, 0)
playerCount.Position = UDim2.new(0, 2, 0, 0)
playerCount.BackgroundTransparency = 1
playerCount.Text = "0 لاعب في السيرفر"
playerCount.TextColor3 = Color3.fromRGB(163, 172, 203)
playerCount.Font = Enum.Font.GothamMedium
playerCount.TextSize = 10
playerCount.TextXAlignment = Enum.TextXAlignment.Left
playerCount.AutoButtonColor = false

local searchPanel = Instance.new("Frame", frame)
searchPanel.Size = UDim2.new(1, -16, 0, 28)
searchPanel.Position = UDim2.new(0, 8, 0, 42)
searchPanel.BackgroundColor3 = Color3.fromRGB(36, 40, 59)
searchPanel.BackgroundTransparency = 0.04
searchPanel.BorderSizePixel = 0
searchPanel.Visible = false
searchPanel.ZIndex = 30
Instance.new("UICorner", searchPanel).CornerRadius = UDim.new(0, 7)

local searchBox = Instance.new("TextBox", searchPanel)
searchBox.Size = UDim2.new(1, -65, 1, 0)
searchBox.Position = UDim2.new(0, 8, 0, 0)
searchBox.BackgroundTransparency = 1
searchBox.PlaceholderText = "ابحث في الرسائل المحمّلة…"
searchBox.PlaceholderColor3 = Color3.fromRGB(160, 168, 196)
searchBox.TextColor3 = Color3.new(1, 1, 1)
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 11
searchBox.TextXAlignment = Enum.TextXAlignment.Right
searchBox.ClearTextOnFocus = false
searchBox.ZIndex = 31

local searchInfo = Instance.new("TextLabel", searchPanel)
searchInfo.Size = UDim2.new(0, 54, 1, 0)
searchInfo.Position = UDim2.new(1, -58, 0, 0)
searchInfo.BackgroundTransparency = 1
searchInfo.Text = "0 نتيجة"
searchInfo.TextColor3 = Color3.fromRGB(161, 177, 255)
searchInfo.Font = Enum.Font.GothamBold
searchInfo.TextSize = 9
searchInfo.ZIndex = 31

local rosterPanel = Instance.new("Frame", frame)
rosterPanel.Size = UDim2.new(0, 178, 0, 170)
rosterPanel.Position = UDim2.new(0, 8, 0, 42)
rosterPanel.BackgroundColor3 = Color3.fromRGB(29, 33, 50)
rosterPanel.BackgroundTransparency = 0.04
rosterPanel.BorderSizePixel = 0
rosterPanel.Visible = false
rosterPanel.ZIndex = 40
Instance.new("UICorner", rosterPanel).CornerRadius = UDim.new(0, 8)
local rosterStroke = Instance.new("UIStroke", rosterPanel)
rosterStroke.Color = settings.color
rosterStroke.Transparency = 0.35

local rosterTitle = Instance.new("TextLabel", rosterPanel)
rosterTitle.Size = UDim2.new(1, -12, 0, 26)
rosterTitle.Position = UDim2.new(0, 6, 0, 2)
rosterTitle.BackgroundTransparency = 1
rosterTitle.Text = "لاعبو السيرفر"
rosterTitle.TextColor3 = Color3.fromRGB(240, 242, 255)
rosterTitle.Font = Enum.Font.GothamBold
rosterTitle.TextSize = 12
rosterTitle.TextXAlignment = Enum.TextXAlignment.Right
rosterTitle.ZIndex = 41

local rosterList = Instance.new("ScrollingFrame", rosterPanel)
rosterList.Size = UDim2.new(1, -10, 1, -34)
rosterList.Position = UDim2.new(0, 5, 0, 30)
rosterList.BackgroundTransparency = 1
rosterList.BorderSizePixel = 0
rosterList.ScrollBarThickness = 2
rosterList.AutomaticCanvasSize = Enum.AutomaticSize.Y
rosterList.ZIndex = 41
local rosterLayout = Instance.new("UIListLayout", rosterList)
rosterLayout.Padding = UDim.new(0, 3)

local inputBg = Instance.new("Frame", frame)
inputBg.Size = UDim2.new(1, -8, 0, 26)
inputBg.Position = UDim2.new(0, 4, 1, -30)
inputBg.BackgroundColor3 = Color3.fromRGB(36, 40, 59)
inputBg.BackgroundTransparency = 0.12
inputBg.BorderSizePixel = 0
Instance.new("UICorner", inputBg).CornerRadius = UDim.new(0, 6)
local inputStroke = Instance.new("UIStroke", inputBg)
inputStroke.Color = Color3.fromRGB(93, 108, 200)
inputStroke.Transparency = 0.55

local box = Instance.new("TextBox", inputBg)
box.Size = UDim2.new(1, -12, 1, 0)
box.Position = UDim2.new(0, 8, 0, 0)
box.BackgroundTransparency = 1
box.PlaceholderText = "اكتب رسالة…  /help للمساعدة"
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
settingsPanel.Size = UDim2.new(0, 300, 0, 380)
settingsPanel.Position = UDim2.new(0.5, -150, 0.5, -190)
settingsPanel.BackgroundColor3 = Color3.fromRGB(24,24,27)
settingsPanel.BorderSizePixel = 0
settingsPanel.Visible = false
settingsPanel.ZIndex = 100
Instance.new("UICorner", settingsPanel).CornerRadius = UDim.new(0,12)

local settingsStroke = Instance.new("UIStroke", settingsPanel)
settingsStroke.Color = settings.color
settingsStroke.Thickness = 1

local mobileClose = Instance.new("TextButton", settingsPanel)
mobileClose.Size = UDim2.new(0, 40, 0, 34)
mobileClose.Position = UDim2.new(1, -48, 0, 6)
mobileClose.BackgroundColor3 = Color3.fromRGB(190,65,70)
mobileClose.Text = "✕"
mobileClose.TextColor3 = Color3.new(1,1,1)
mobileClose.Font = Enum.Font.GothamBold
mobileClose.TextSize = 16
mobileClose.BorderSizePixel = 0
mobileClose.ZIndex = 120
Instance.new("UICorner", mobileClose).CornerRadius = UDim.new(0,9)

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
        inputStroke.Color = c
        toggleStroke.Color = c:Lerp(Color3.new(1, 1, 1), 0.45)
    end)
end

local buttonSizeTitle = Instance.new("TextLabel", settingsPanel)
buttonSizeTitle.Size = UDim2.new(0,190,0,22)
buttonSizeTitle.Position = UDim2.new(0,10,0,268)
buttonSizeTitle.BackgroundTransparency = 1
buttonSizeTitle.Text = "حجم زر الشات"
buttonSizeTitle.TextColor3 = Color3.new(1,1,1)
buttonSizeTitle.Font = Enum.Font.Gotham
buttonSizeTitle.TextSize = 12
buttonSizeTitle.TextXAlignment = Enum.TextXAlignment.Left
buttonSizeTitle.ZIndex = 101

local buttonSmall = sbtn("−",150,264,42,28)
local buttonBig = sbtn("+",198,264,42,28)

local resetBtn = sbtn("↺ افتراضي",10,330,92,30)
local closeSettings = sbtn("إغلاق",108,330,92,30)

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
    toggleBtn.Position = UDim2.new(0,settings.buttonX,0,settings.buttonY)
    toggleBtn.Size = UDim2.new(0,settings.buttonW,0,settings.buttonH)
    msgInfo.Text = "الرسائل الظاهرة: " .. tostring(settings.visibleMessages)
    sizeInfo.Text = string.format("الحجم: %d%% × %d%%", math.floor(settings.width*100), math.floor(settings.height*100))
    moveBtn.BackgroundColor3 = editButtonMode and Color3.fromRGB(190,145,45) or settings.color
    moveChat.BackgroundColor3 = editChatMode and Color3.fromRGB(190,145,45) or settings.color
    updateSettingsState()
end

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
    elseif dragTarget == frame then
        settings.chatX, settings.chatY = x, y
    end
    updateSettingsState()
end

settingsBtn.Activated:Connect(function()
    if not settingsPanel.Visible then
        local cam = workspace.CurrentCamera
        if cam then
            local v = cam.ViewportSize
            local w = math.min(300, math.max(260, v.X - 18))
            local h = math.min(380, math.max(330, v.Y - 18))
            settingsPanel.Size = UDim2.new(0, w, 0, h)
            settingsPanel.Position = UDim2.new(0.5, -w/2, 0.5, -h/2)
        end
    end
    settingsPanel.Visible = not settingsPanel.Visible
    editButtonMode = false
    editChatMode = false
    refreshSettings()
end)

buttonSmall.Activated:Connect(function()
    settings.buttonW = math.max(56, settings.buttonW - 6)
    settings.buttonH = math.max(30, settings.buttonH - 2)
    toggleBtn.Size = UDim2.new(0, settings.buttonW, 0, settings.buttonH)
end)

buttonBig.Activated:Connect(function()
    settings.buttonW = math.min(130, settings.buttonW + 6)
    settings.buttonH = math.min(60, settings.buttonH + 2)
    toggleBtn.Size = UDim2.new(0, settings.buttonW, 0, settings.buttonH)
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
    settings.buttonY = 12
    settings.buttonW = 78
    settings.buttonH = 36
    settings.chatX = 12
    settings.chatY = 55
    settings.color = Color3.fromRGB(88,101,242)
    toggleBtn.BackgroundColor3 = settings.color
    sendBtn.BackgroundColor3 = settings.color
    settingsStroke.Color = settings.color
    frameStroke.Color = settings.color
    inputStroke.Color = settings.color
    toggleStroke.Color = settings.color:Lerp(Color3.new(1, 1, 1), 0.45)
    editButtonMode = false
    editChatMode = false
    stopDrag()
    refreshSettings()
end)

mobileClose.Activated:Connect(function()
    settingsPanel.Visible = false
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

local function escapeRichText(value)
    return tostring(value)
        :gsub("&", "&amp;")
        :gsub("<", "&lt;")
        :gsub(">", "&gt;")
        :gsub('"', "&quot;")
end

local function setConnectionStatus(text, healthy)
    if not connectionLabel or not connectionLabel.Parent then return end
    connectionLabel.Text = text
    connectionLabel.TextColor3 = healthy and Color3.fromRGB(133, 240, 174) or Color3.fromRGB(255, 184, 104)
    connectionLabel.BackgroundColor3 = healthy and Color3.fromRGB(48, 61, 69) or Color3.fromRGB(78, 55, 38)
end

local toastNonce = 0
local function showToast(text, color)
    toastNonce = toastNonce + 1
    local token = toastNonce
    toast.Text = tostring(text)
    toast.BackgroundColor3 = color or Color3.fromRGB(31, 36, 56)
    toast.Visible = true
    TweenService:Create(toast, TweenInfo.new(0.16), {BackgroundTransparency = 0.04, TextTransparency = 0}):Play()
    TweenService:Create(toastStroke, TweenInfo.new(0.16), {Transparency = 0.3}):Play()
    task.delay(2.2, function()
        if token ~= toastNonce or not toast.Parent then return end
        TweenService:Create(toast, TweenInfo.new(0.18), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
        TweenService:Create(toastStroke, TweenInfo.new(0.18), {Transparency = 1}):Play()
        task.wait(0.2)
        if token == toastNonce then toast.Visible = false end
    end)
end

local function scrollToNewest()
    if not settings.autoScroll then return end
    task.defer(function()
        if messages and messages.Parent then
            messages.CanvasPosition = Vector2.new(0, messages.AbsoluteCanvasSize.Y)
        end
    end)
end

local function addSystemMessage(text)
    local label = Instance.new("TextLabel", messages)
    label.Size = UDim2.new(1, 0, 0, 22)
    label.BackgroundColor3 = Color3.fromRGB(78, 88, 158)
    label.BackgroundTransparency = 0.65
    label.BorderSizePixel = 0
    label.Text = "✦  " .. escapeRichText(text)
    label.TextColor3 = Color3.fromRGB(210, 215, 255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 10
    label.TextXAlignment = Enum.TextXAlignment.Center
    Instance.new("UICorner", label).CornerRadius = UDim.new(0, 6)
    label.TextTransparency = 1
    TweenService:Create(label, TweenInfo.new(0.18), {TextTransparency = 0}):Play()
    scrollToNewest()
end

local messageRecords = {}
local function applySearchFilter(query)
    query = tostring(query or ""):lower()
    local matches = 0
    for _, record in ipairs(messageRecords) do
        local matched = query == "" or record.user:lower():find(query, 1, true) or record.message:lower():find(query, 1, true)
        record.card.Visible = matched
        if matched then matches = matches + 1 end
    end
    if searchInfo then searchInfo.Text = tostring(matches) .. " نتيجة" end
end

local function applyAccessibilitySettings()
    layout.Padding = UDim.new(0, settings.compactMode and 0 or 2)
    for _, record in ipairs(messageRecords) do
        if record.card and record.card.Parent then
            record.card.BackgroundTransparency = settings.highContrast and 0.78 or 0.94
        end
        if record.label and record.label.Parent then
            record.label.TextSize = settings.messageFontSize
        end
    end
    frame.BackgroundTransparency = settings.highContrast and 0 or 0.08
    inputBg.BackgroundTransparency = settings.highContrast and 0 or 0.12
    showToast("حجم الخط " .. tostring(settings.messageFontSize) .. " • " .. (settings.compactMode and "وضع مضغوط" or "وضع مريح"))
end

local function clearLocalHistory()
    for _, record in ipairs(messageRecords) do
        if record.card and record.card.Parent then record.card:Destroy() end
    end
    table.clear(messageRecords)
    addSystemMessage("تم تنظيف العرض المحلي فقط — الرسائل لم تُحذف من القاعدة")
end

local function refreshRoster()
    for _, child in ipairs(rosterList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, player in ipairs(Players:GetPlayers()) do
        local row = Instance.new("TextButton", rosterList)
        row.Size = UDim2.new(1, 0, 0, 25)
        row.BackgroundColor3 = player == LocalPlayer and settings.color or Color3.fromRGB(46, 50, 72)
        row.BackgroundTransparency = player == LocalPlayer and 0.2 or 0.38
        row.BorderSizePixel = 0
        row.Text = (player == LocalPlayer and "أنت • " or "") .. player.Name
        row.TextColor3 = Color3.new(1, 1, 1)
        row.Font = Enum.Font.GothamMedium
        row.TextSize = 10
        row.TextXAlignment = Enum.TextXAlignment.Right
        row.ZIndex = 42
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)
        row.Activated:Connect(function()
            box.Text = "@" .. player.Name .. " "
            box:CaptureFocus()
            rosterPanel.Visible = false
        end)
    end
end


local function trimVisibleMessages()
    -- visibleMessages controls how many messages are comfortably visible.
    -- It NEVER deletes old messages; the ScrollingFrame keeps them available.
end

local function addMessage(user, msg, createdAt)
    local color = getColor(user)
    local hex = colorToHex(color)
    local displayName = user == LocalPlayer.Name and ("(" .. user .. "  )") or ("(" .. user .. ")")

    local card = Instance.new("Frame", messages)
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    card.BackgroundTransparency = settings.highContrast and 0.78 or 0.94
    card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 7)

    local accent = Instance.new("Frame", card)
    accent.Size = UDim2.new(0, 3, 1, -8)
    accent.Position = UDim2.new(1, -6, 0, 4)
    accent.BackgroundColor3 = color
    accent.BorderSizePixel = 0
    Instance.new("UICorner", accent).CornerRadius = UDim.new(1, 0)

    local copyButton = Instance.new("TextButton", card)
    copyButton.Size = UDim2.new(0, 20, 0, 20)
    copyButton.Position = UDim2.new(0, 2, 0, 2)
    copyButton.BackgroundTransparency = 1
    copyButton.Text = "⧉"
    copyButton.TextColor3 = Color3.fromRGB(172, 181, 222)
    copyButton.Font = Enum.Font.GothamBold
    copyButton.TextSize = 12
    copyButton.ZIndex = 3
    copyButton.Activated:Connect(function()
        local clipboard = setclipboard or toclipboard or (syn and syn.write_clipboard)
        if clipboard then
            local ok = pcall(function() clipboard(tostring(msg)) end)
            showToast(ok and "تم نسخ الرسالة" or "تعذر النسخ", ok and Color3.fromRGB(42, 86, 69) or Color3.fromRGB(95, 58, 61))
        else
            showToast("الـ Executor لا يدعم النسخ", Color3.fromRGB(95, 58, 61))
        end
    end)

    local label = Instance.new("TextLabel", card)
    label.Size = UDim2.new(1, -16, 0, 0)
    label.Position = UDim2.new(0, 5, 0, 4)
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.BackgroundTransparency = 1
    label.RichText = true
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.GothamMedium
    label.TextSize = settings.messageFontSize
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Right
    local clock = type(createdAt) == "string" and createdAt:match("T(%d%d:%d%d)") or nil
    local meta = clock and ("  <font color=\"#8991A9\">" .. clock .. "</font>") or ""
    label.Text = string.format('%s  <font color="%s"><b>%s</b></font>%s', escapeRichText(msg), hex, escapeRichText(displayName), meta)

    label.TextTransparency = 1
    if settings.reduceMotion then
        label.TextTransparency = 0
    else
        TweenService:Create(label, TweenInfo.new(0.15), {TextTransparency = 0}):Play()
    end

    table.insert(messageRecords, {card = card, label = label, user = tostring(user), message = tostring(msg)})
    if #messageRecords > APP.historyLimit then
        local oldest = table.remove(messageRecords, 1)
        if oldest.card and oldest.card.Parent then oldest.card:Destroy() end
    end
    applySearchFilter(searchBox and searchBox.Text or "")

    trimVisibleMessages()
    scrollToNewest()
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

local lastSendAt = 0
local function handleCommand(text)
    local command = text:lower()
    if command == "/help" then
        addSystemMessage("الأوامر: /help  /clear  /mute  /scroll  /search  /version")
        return true
    elseif command == "/clear" then
        clearLocalHistory()
        return true
    elseif command == "/mute" then
        settings.muted = not settings.muted
        addSystemMessage(settings.muted and "تم كتم أصوات التنبيه" or "تم تشغيل أصوات التنبيه")
        return true
    elseif command == "/scroll" then
        settings.autoScroll = not settings.autoScroll
        addSystemMessage(settings.autoScroll and "التمرير التلقائي مفعّل" or "التمرير التلقائي متوقف")
        return true
    elseif command == "/font+" then
        settings.messageFontSize = math.min(18, settings.messageFontSize + 1)
        applyAccessibilitySettings()
        return true
    elseif command == "/font-" then
        settings.messageFontSize = math.max(10, settings.messageFontSize - 1)
        applyAccessibilitySettings()
        return true
    elseif command == "/contrast" then
        settings.highContrast = not settings.highContrast
        applyAccessibilitySettings()
        return true
    elseif command == "/compact" then
        settings.compactMode = not settings.compactMode
        applyAccessibilitySettings()
        return true
    elseif command == "/motion" then
        settings.reduceMotion = not settings.reduceMotion
        showToast(settings.reduceMotion and "تم تقليل الحركة" or "تم تشغيل الحركة")
        return true
    elseif command == "/version" then
        addSystemMessage(APP.name .. " v" .. APP.version .. " • واجهة محلية آمنة")
        return true
    elseif command == "/search" then
        searchPanel.Visible = not searchPanel.Visible
        if searchPanel.Visible then searchBox:CaptureFocus() end
        return true
    end
    return false
end

local function updatePlayerCount()
    local count = #Players:GetPlayers()
    playerCount.Text = tostring(count) .. (count == 1 and " لاعب في السيرفر" or " لاعبين في السيرفر")
    refreshRoster()
end

local function syncToolState()
    muteBtn.Text = settings.muted and "🔇" or "🔊"
    scrollBtn.Text = settings.autoScroll and "↓" or "↕"
    muteBtn.BackgroundColor3 = settings.muted and Color3.fromRGB(103, 63, 70) or Color3.fromRGB(43, 47, 69)
    scrollBtn.BackgroundColor3 = settings.autoScroll and settings.color or Color3.fromRGB(43, 47, 69)
end

searchBtn.Activated:Connect(function()
    searchPanel.Visible = not searchPanel.Visible
    if searchPanel.Visible then
        searchBox:CaptureFocus()
    else
        searchBox.Text = ""
        applySearchFilter("")
    end
end)

playerCount.Activated:Connect(function()
    rosterPanel.Visible = not rosterPanel.Visible
    if rosterPanel.Visible then refreshRoster() end
end)

muteBtn.Activated:Connect(function()
    settings.muted = not settings.muted
    syncToolState()
    addSystemMessage(settings.muted and "تم كتم أصوات التنبيه" or "تم تشغيل أصوات التنبيه")
end)

scrollBtn.Activated:Connect(function()
    settings.autoScroll = not settings.autoScroll
    syncToolState()
    if settings.autoScroll then scrollToNewest() end
end)

clearBtn.Activated:Connect(clearLocalHistory)

emojiBtn.Activated:Connect(function()
    local choices = {"😀", "🔥", "✨", "👍", "❤️", "🎮"}
    local nextEmoji = choices[math.random(1, #choices)]
    box.Text = box.Text .. nextEmoji
    box:CaptureFocus()
end)

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    applySearchFilter(searchBox.Text)
end)

Players.PlayerAdded:Connect(updatePlayerCount)
Players.PlayerRemoving:Connect(updatePlayerCount)
updatePlayerCount()
syncToolState()

local function sendMessage(text)
    text = tostring(text):gsub("^%s*(.-)%s*$", "%1")
    if text == "" or handleCommand(text) then return end
    if os.clock() - lastSendAt < APP.sendCooldown then
        addSystemMessage("انتظر لحظة قبل إرسال رسالة جديدة")
        return
    end
    lastSendAt = os.clock()
    setConnectionStatus("… إرسال", true)
    showBubbleAbovePlayer(LocalPlayer.Name, text)
    local data = {username = LocalPlayer.Name, message = text}
    task.spawn(function()
        local ok, response = pcall(function()
            return request({
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
        if ok and response and response.Success ~= false then
            setConnectionStatus("● متصل", true)
        else
            setConnectionStatus("! أعد المحاولة", false)
            addSystemMessage("تعذر إرسال الرسالة — تحقق من الاتصال")
        end
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

local unreadCount = 0
local function notifyNewMessage()
    if not settings.muted then
        pcall(function() messageSound:Play() end)
    end
    if isOpen then return end

    unreadCount = math.min(unreadCount + 1, 99)
    unreadBadge.Text = unreadCount > 9 and "9+" or tostring(unreadCount)
    unreadBadge.Visible = true

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
    while task.wait(APP.pollInterval) do
        local ok, response = pcall(function()
            return request({
                Url = PROJECT_URL .. "/rest/v1/chat_messages?select=*&order=id.asc&limit=20",
                Method = "GET",
                Headers = {["apikey"] = ANON_KEY, ["Authorization"] = "Bearer " .. ANON_KEY}
            })
        end)
        if ok and response and response.Body then
            local decodedOk, decoded = pcall(function() return HttpService:JSONDecode(response.Body) end)
            if decodedOk and type(decoded) == "table" then
                setConnectionStatus("● متصل", true)
                local newIncoming = false
                for _, v in ipairs(decoded) do
                    if v.id and not shownIds[v.id] then
                        shownIds[v.id] = true
                        addMessage(v.username, v.message, v.created_at)
                        if not firstLoad and v.username ~= LocalPlayer.Name then
                            showBubbleAbovePlayer(v.username, v.message)
                            newIncoming = true
                        end
                    end
                end
                if newIncoming then notifyNewMessage() end
                firstLoad = false
            end
        else
            setConnectionStatus("! غير متصل", false)
        end
    end
end)

toggleBtn.Activated:Connect(function()
    if editButtonMode then return end
    isOpen = not isOpen
    if isOpen then
        unreadCount = 0
        unreadBadge.Visible = false
        frame.Visible = true
        frame.Size = UDim2.new(0, 0, 0, 0)
        TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Size = UDim2.new(settings.width,0,settings.height,0)}):Play()
        toggleBtn.Text = "✕"
    else
        TweenService:Create(frame, TweenInfo.new(0.15), {Size = UDim2.new(0, 0, 0, 0)}):Play()
        toggleBtn.Text = "💬  CHAT"
        task.wait(0.15)
        frame.Visible = false
    end
end)


UserInputService.InputBegan:Connect(function(input, processed)
    if processed or not isMouse then return end
    if input.KeyCode == Enum.KeyCode.T then
        if not isOpen then
            frame.Visible = true
            isOpen = true
            frame.Size = UDim2.new(settings.width,0,settings.height,0)
            toggleBtn.Text = "✕"
        end
        unreadCount = 0
        unreadBadge.Visible = false
        task.defer(function()
            pcall(function()
                box:CaptureFocus()
                box.CursorPosition = #box.Text + 1
            end)
        end)
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed or not isMouse then return end
    local ctrlDown = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)

    if ctrlDown and input.KeyCode == Enum.KeyCode.F then
        searchPanel.Visible = not searchPanel.Visible
        if searchPanel.Visible then searchBox:CaptureFocus() end
    elseif ctrlDown and input.KeyCode == Enum.KeyCode.M then
        settings.muted = not settings.muted
        syncToolState()
    elseif ctrlDown and input.KeyCode == Enum.KeyCode.L then
        clearLocalHistory()
    elseif input.KeyCode == Enum.KeyCode.Escape then
        if searchPanel.Visible then
            searchPanel.Visible = false
            searchBox.Text = ""
        elseif isOpen then
            toggleBtn:Activate()
        end
    elseif input.KeyCode == Enum.KeyCode.PageDown then
        settings.autoScroll = true
        syncToolState()
        scrollToNewest()
    elseif ctrlDown and input.KeyCode == Enum.KeyCode.Equals then
        settings.messageFontSize = math.min(18, settings.messageFontSize + 1)
        applyAccessibilitySettings()
    elseif ctrlDown and input.KeyCode == Enum.KeyCode.Minus then
        settings.messageFontSize = math.max(10, settings.messageFontSize - 1)
        applyAccessibilitySettings()
    elseif ctrlDown and input.KeyCode == Enum.KeyCode.H then
        settings.highContrast = not settings.highContrast
        applyAccessibilitySettings()
    elseif ctrlDown and input.KeyCode == Enum.KeyCode.R then
        settings.compactMode = not settings.compactMode
        applyAccessibilitySettings()
    end
end)

refreshSettings()

print("✅ Pro Chat CHATTTT — original v11 network + settings, no save")

box:GetPropertyChangedSignal("Text"):Connect(function()
    if #box.Text > APP.maxMessageLength then box.Text = string.sub(box.Text,1,APP.maxMessageLength) end
    if charCounter and charCounter.Parent then
        charCounter.Text = tostring(#box.Text).."/"..tostring(APP.maxMessageLength)
    end
end)
