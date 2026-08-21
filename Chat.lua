-- Pro Chat v14 - Rooms + Global Chat + Legendary Bubble System
-- ملاحظة مهمة: لازم تضيف عمود اسمه "room" (نوع text) لجدول chat_messages
-- بالـ Supabase حتى يشتغل فلتر الروم/العام (ALTER TABLE chat_messages ADD COLUMN room text;)
-- ما لمسنا API_URL / API_KEY / HEADERS ولا أي شي تبع التخزين، خلّيناها كما هي.

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local API_URL = "https://yuwnhpbwrdfcpjonfodr.supabase.co/rest/v1/chat_messages"
local API_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl1d25ocGJ3cmRmY3Bqb25mb2RyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODczMzU2NDIsImV4cCI6MjEwMjkxMTY0Mn0.Ac99nEIxqgwVxWS1Q4527uhUqL_YgIDtH4ucZnzeSOc"
local HEADERS = {
    ["apikey"] = API_KEY,
    ["Authorization"] = "Bearer " .. API_KEY,
    ["Content-Type"] = "application/json"
}

local request = http_request or request or (syn and syn.request) or (fluxus and fluxus.request)
if not request then warn("HTTP not supported") return end

if CoreGui:FindFirstChild("ProChat") then CoreGui.ProChat:Destroy() end

-- ══════════════════════════════════════
--              ثوابت عامة
-- ══════════════════════════════════════

local CHAT_SIZE = UDim2.new(0.36, 0, 0.36, 0)
local DEVICE_MESSAGE_DEFAULT = 4
local MIN_VISIBLE_MESSAGES = 2
local MAX_VISIBLE_MESSAGES = 20
local BUTTON_POSITIONS = {
    TopLeft = UDim2.new(0, 10, 0, 10),
    TopRight = UDim2.new(1, -90, 0, 10),
    BottomLeft = UDim2.new(0, 10, 1, -58),
    BottomRight = UDim2.new(1, -90, 1, -58),
}
local UserInputService = game:GetService("UserInputService")
local isTouch = UserInputService.TouchEnabled
local isMouse = UserInputService.MouseEnabled
local defaultMessages = (isTouch and isMouse) and 7 or (isTouch and 4 or 10)
local SETTINGS_FILE = "ProChatSettings.json"
local settings = {
    visibleMessages = defaultMessages,
    width = 0.36,
    height = 0.36,
    buttonPosition = "TopLeft",
    buttonX = 10,
    buttonY = 10,
    chatX = 8,
    chatY = 48,
    color = {88, 101, 242},
    opacity = 0.15,
}

local function loadSavedSettings()
    if type(isfile) == "function" and type(readfile) == "function" then
        local ok, raw = pcall(readfile, SETTINGS_FILE)
        if ok and raw and raw ~= "" then
            local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
            if ok2 and type(data) == "table" then
                for k,v in pairs(data) do settings[k] = v end
            end
        end
    end
end

local function saveSettings()
    if type(writefile) == "function" then
        pcall(function() writefile(SETTINGS_FILE, HttpService:JSONEncode(settings)) end)
    end
end

loadSavedSettings()

local function accentColor()
    local c = settings.color or {88,101,242}
    return Color3.fromRGB(c[1] or 88, c[2] or 101, c[3] or 242)
end
local DISCORD_COLOR = accentColor()
local ACTIVE_TAB_COLOR = Color3.fromRGB(88, 101, 242)
local INACTIVE_TAB_COLOR = Color3.fromRGB(40, 40, 40)

local COLORS = {
    Color3.fromRGB(255, 107, 107),
    Color3.fromRGB(78, 205, 196),
    Color3.fromRGB(255, 230, 109),
    Color3.fromRGB(199, 128, 232),
    Color3.fromRGB(77, 182, 255),
    Color3.fromRGB(255, 159, 243),
    Color3.fromRGB(162, 255, 134),
}

local MAX_MESSAGES = 150          -- حد داخلي لعناصر الواجهة
local POLL_INTERVAL = 0.4
local AUTO_SCROLL_THRESHOLD = 40  -- بكسل: لو قريب من الأسفل نعتبره "نازل"

-- إعدادات الفقاعات
local BUBBLE_MAX_WIDTH = 230      -- أقصى عرض قبل ما تبدأ تكسر سطر (مش متلصقة بسرعة)
local BUBBLE_MAX_VISIBLE = 4      -- أقصى عدد فقاعات فوق نفس اللاعب بنفس اللحظة
local BASE_BUBBLE_DURATION = 3
local MAX_BUBBLE_DURATION = 9
local DURATION_PER_CHAR = 0.06

local userColors = {}
local playerBubbles = {}   -- [playerName] = { billboard=, stack=, bubbles={}, counter=0 }
local lastSent = 0
local isOpen = false

-- ══════════════════════════════════════
--              دوال مساعدة عامة
-- ══════════════════════════════════════

local function trim(s)
    return (s or ""):match("^%s*(.-)%s*$")
end

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

-- نهرّب رموز RichText عشان رسالة فيها "<" أو ">" ما تكسر تنسيق الشات أو
-- تتنكر بلون/خط شخص ثاني (مهم لأن اليوزرنيم نفسه ممكن يجي من ديسكورد بدون قيود)
local function escapeRich(text)
    text = text:gsub("&", "&amp;")
    text = text:gsub("<", "&lt;")
    text = text:gsub(">", "&gt;")
    return text
end

local function shortenName(s, maxLen)
    if #s > maxLen then
        return s:sub(1, maxLen) .. "..."
    end
    return s
end

-- هاش بسيط (مش تشفير حقيقي، فقط لتوليد معرف ثابت للروم من الاسم+الباس)

-- ══════════════════════════════════════
--              GUI - الهيكل الأساسي
-- ══════════════════════════════════════

local gui = Instance.new("ScreenGui")
gui.Name = "ProChat"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = CoreGui

-- زر التبديل
local toggleBtn = Instance.new("TextButton", gui)
toggleBtn.Size = UDim2.new(0, 52, 0, 40)
toggleBtn.Position = UDim2.new(0, settings.buttonX, 0, settings.buttonY)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
toggleBtn.Text = "💬  Chat"
toggleBtn.TextSize = 14
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.BorderSizePixel = 0
toggleBtn.ZIndex = 100
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

toggleBtn.Size = UDim2.new(0, 78, 0, 42)

local settingsBtn = Instance.new("TextButton", gui)
settingsBtn.Size = UDim2.new(0, 38, 0, 38)
settingsBtn.Position = UDim2.new(0, 94, 0, 11)
settingsBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
settingsBtn.Text = "⚙"
settingsBtn.TextSize = 18
settingsBtn.Font = Enum.Font.GothamBold
settingsBtn.TextColor3 = Color3.new(1,1,1)
settingsBtn.BorderSizePixel = 0
settingsBtn.ZIndex = 100
Instance.new("UICorner", settingsBtn).CornerRadius = UDim.new(0, 8)

local notifySound = Instance.new("Sound", gui)
notifySound.Name = "ChatNotification"
notifySound.SoundId = "rbxassetid://6026984224"
notifySound.Volume = 0.55

-- النافذة الرئيسية
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(settings.width, 0, settings.height, 0)
frame.Position = UDim2.new(0, settings.chatX, 0, settings.chatY)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.Visible = false
frame.ClipsDescendants = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(60, 60, 60)
stroke.Thickness = 1

-- ── الهيدر ──
local header = Instance.new("Frame", frame)
header.Size = UDim2.new(1, -12, 0, 30)
header.Position = UDim2.new(0, 6, 0, 5)
header.BackgroundTransparency = 1

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1, 0, 1, 0)
title.BackgroundTransparency = 1
title.Text = "💬 Global Chat   •   Press / to chat"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left

local globalState

-- ── حاوية الفيد العام ──
local feedHolder = Instance.new("Frame", frame)
feedHolder.Size = UDim2.new(1, -12, 1, -78)
feedHolder.Position = UDim2.new(0, 6, 0, 38)
feedHolder.BackgroundTransparency = 1
feedHolder.ClipsDescendants = true

-- ── صندوق الكتابة + زر الإرسال ──
local inputContainer = Instance.new("Frame", frame)
inputContainer.Size = UDim2.new(1, -12, 0, 32)
inputContainer.Position = UDim2.new(0, 6, 1, -38)
inputContainer.BackgroundTransparency = 1

local box = Instance.new("TextBox", inputContainer)
box.Size = UDim2.new(1, -62, 1, 0)
box.Position = UDim2.new(0, 0, 0, 0)
box.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
box.BorderSizePixel = 0
box.PlaceholderText = "Type a message..."
box.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
box.Text = ""
box.TextColor3 = Color3.new(1, 1, 1)
box.Font = Enum.Font.Gotham
box.TextSize = 13
box.TextXAlignment = Enum.TextXAlignment.Left
box.ClearTextOnFocus = false
box.ClipsDescendants = true
Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
local boxPad = Instance.new("UIPadding", box)
boxPad.PaddingLeft = UDim.new(0, 8)
boxPad.PaddingRight = UDim.new(0, 8)

local sendBtn = Instance.new("TextButton", inputContainer)
sendBtn.Size = UDim2.new(0, 56, 1, 0)
sendBtn.Position = UDim2.new(1, -56, 0, 0)
sendBtn.BackgroundColor3 = DISCORD_COLOR
sendBtn.Text = "إرسال"
sendBtn.TextSize = 12
sendBtn.Font = Enum.Font.GothamBold
sendBtn.TextColor3 = Color3.new(1, 1, 1)
sendBtn.BorderSizePixel = 0
Instance.new("UICorner", sendBtn).CornerRadius = UDim.new(0, 8)

local statusLabel = Instance.new("TextLabel", frame)
statusLabel.Size = UDim2.new(1, -12, 0, 14)
statusLabel.Position = UDim2.new(0, 6, 1, -52)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(255, 140, 140)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 11
statusLabel.Text = ""
statusLabel.TextTransparency = 1

local function showStatus(msg)
    statusLabel.Text = msg
    statusLabel.TextTransparency = 0
    TweenService:Create(statusLabel, TweenInfo.new(1.6), {TextTransparency = 1}):Play()
end

-- ══════════════════════════════════════
--              الإعدادات
-- ══════════════════════════════════════
local settingsPanel = Instance.new("Frame", gui)
settingsPanel.Size = UDim2.new(0, 310, 0, 390)
settingsPanel.Position = UDim2.new(0, 10, 0, 60)
settingsPanel.BackgroundColor3 = Color3.fromRGB(22,22,22)
settingsPanel.BorderSizePixel = 0
settingsPanel.Visible = false
settingsPanel.ZIndex = 200
Instance.new("UICorner", settingsPanel).CornerRadius = UDim.new(0, 10)
local settingsStroke = Instance.new("UIStroke", settingsPanel)
settingsStroke.Color = Color3.fromRGB(70,70,70)

local settingsTitle = Instance.new("TextLabel", settingsPanel)
settingsTitle.Size = UDim2.new(1,-20,0,28)
settingsTitle.Position = UDim2.new(0,10,0,8)
settingsTitle.BackgroundTransparency = 1
settingsTitle.Text = "⚙ إعدادات الشات"
settingsTitle.TextColor3 = Color3.new(1,1,1)
settingsTitle.Font = Enum.Font.GothamBold
settingsTitle.TextSize = 15
settingsTitle.TextXAlignment = Enum.TextXAlignment.Left
settingsTitle.ZIndex = 201

local function makeSettingButton(parent, text, pos, size)
    local b = Instance.new("TextButton", parent)
    b.Size = size or UDim2.new(0, 42, 0, 30)
    b.Position = pos
    b.BackgroundColor3 = Color3.fromRGB(45,45,45)
    b.Text = text
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.BorderSizePixel = 0
    b.ZIndex = 202
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
    return b
end

local msgLabel = Instance.new("TextLabel", settingsPanel)
msgLabel.Size = UDim2.new(1,-20,0,24)
msgLabel.Position = UDim2.new(0,10,0,42)
msgLabel.BackgroundTransparency = 1
msgLabel.TextColor3 = Color3.new(1,1,1)
msgLabel.Font = Enum.Font.Gotham
msgLabel.TextSize = 12
msgLabel.TextXAlignment = Enum.TextXAlignment.Left
msgLabel.ZIndex = 201
local msgMinus = makeSettingButton(settingsPanel,"−",UDim2.new(1,-100,0,39))
local msgPlus = makeSettingButton(settingsPanel,"+",UDim2.new(1,-52,0,39))

local sizeLabel = Instance.new("TextLabel", settingsPanel)
sizeLabel.Size = UDim2.new(1,-20,0,24)
sizeLabel.Position = UDim2.new(0,10,0,78)
sizeLabel.BackgroundTransparency = 1
sizeLabel.TextColor3 = Color3.new(1,1,1)
sizeLabel.Font = Enum.Font.Gotham
sizeLabel.TextSize = 12
sizeLabel.TextXAlignment = Enum.TextXAlignment.Left
sizeLabel.ZIndex = 201
local widthMinus = makeSettingButton(settingsPanel,"W −",UDim2.new(0,10,0,104),UDim2.new(0,58,0,30))
local widthPlus = makeSettingButton(settingsPanel,"W +",UDim2.new(0,74,0,104),UDim2.new(0,58,0,30))
local heightMinus = makeSettingButton(settingsPanel,"H −",UDim2.new(0,142,0,104),UDim2.new(0,58,0,30))
local heightPlus = makeSettingButton(settingsPanel,"H +",UDim2.new(0,206,0,104),UDim2.new(0,58,0,30))

local posLabel = Instance.new("TextLabel", settingsPanel)
posLabel.Size = UDim2.new(1,-20,0,24)
posLabel.Position = UDim2.new(0,10,0,140)
posLabel.BackgroundTransparency = 1
posLabel.TextColor3 = Color3.new(1,1,1)
posLabel.Font = Enum.Font.Gotham
posLabel.TextSize = 12
posLabel.TextXAlignment = Enum.TextXAlignment.Left
posLabel.ZIndex = 201
local posTL, posTR, posBL, posBR = nil,nil,nil,nil

local function applyAccentColor()
    DISCORD_COLOR = accentColor()
    sendBtn.BackgroundColor3 = DISCORD_COLOR
    settingsStroke.Color = DISCORD_COLOR
    stroke.Color = DISCORD_COLOR
    if not isOpen then toggleBtn.BackgroundColor3 = DISCORD_COLOR end
end

local function updateSettingsText()
    msgLabel.Text = "الرسائل الظاهرة: " .. tostring(settings.visibleMessages)
    sizeLabel.Text = string.format("الحجم: %d%% × %d%%", math.floor(settings.width*100), math.floor(settings.height*100))
    posLabel.Text = string.format("زر: %d,%d   |   شات: %d,%d", math.floor(settings.buttonX), math.floor(settings.buttonY), math.floor(settings.chatX), math.floor(settings.chatY))
    frame.Size = UDim2.new(settings.width,0,settings.height,0)
    frame.Position = UDim2.new(0, settings.chatX, 0, settings.chatY)
    toggleBtn.Position = UDim2.new(0, settings.buttonX, 0, settings.buttonY)
    applyAccentColor()
end

local function refreshVisibleMessages()
    task.defer(function()
        if globalState and globalState.scroll and globalState.scroll.Parent then
            globalState.scroll.CanvasPosition = Vector2.new(0, math.max(0, globalState.layout.AbsoluteContentSize.Y-globalState.scroll.AbsoluteSize.Y))
        end
    end)
end

msgMinus.MouseButton1Click:Connect(function() settings.visibleMessages=math.max(MIN_VISIBLE_MESSAGES,settings.visibleMessages-1); refreshVisibleMessages(); updateSettingsText() end)
msgPlus.MouseButton1Click:Connect(function() settings.visibleMessages=math.min(MAX_VISIBLE_MESSAGES,settings.visibleMessages+1); updateSettingsText() end)
widthMinus.MouseButton1Click:Connect(function() settings.width=math.max(0.25,settings.width-0.03); updateSettingsText() end)
widthPlus.MouseButton1Click:Connect(function() settings.width=math.min(0.75,settings.width+0.03); updateSettingsText() end)
heightMinus.MouseButton1Click:Connect(function() settings.height=math.max(0.22,settings.height-0.03); updateSettingsText() end)
heightPlus.MouseButton1Click:Connect(function() settings.height=math.min(0.75,settings.height+0.03); updateSettingsText() end)

local editButton = makeSettingButton(settingsPanel,"✋ تحريك زر",UDim2.new(0,10,0,204),UDim2.new(0,92,0,30))
local editChat = makeSettingButton(settingsPanel,"↔ تحريك الشات",UDim2.new(0,108,0,204),UDim2.new(0,92,0,30))
local saveBtn = makeSettingButton(settingsPanel,"💾 حفظ",UDim2.new(0,206,0,204),UDim2.new(0,88,0,30))
local colorLabel = Instance.new("TextLabel", settingsPanel)
colorLabel.Size = UDim2.new(1,-20,0,22)
colorLabel.Position = UDim2.new(0,10,0,242)
colorLabel.BackgroundTransparency = 1
colorLabel.Text = "لون الشات / الزر"
colorLabel.TextColor3 = Color3.new(1,1,1)
colorLabel.Font = Enum.Font.Gotham
colorLabel.TextSize = 12
colorLabel.TextXAlignment = Enum.TextXAlignment.Left
colorLabel.ZIndex = 201
local colorButtons = {}
local colorPresets = {
    {"أزرق",88,101,242},{"بنفسجي",145,80,220},{"أخضر",50,190,110},{"ذهبي",220,170,60},{"أحمر",210,70,70},{"سماوي",40,180,220}
}
for i,preset in ipairs(colorPresets) do
    local b=makeSettingButton(settingsPanel,preset[1],UDim2.new(0,10+((i-1)%3)*98,0,268+math.floor((i-1)/3)*34),UDim2.new(0,90,0,28))
    b.BackgroundColor3=Color3.fromRGB(preset[2],preset[3],preset[4])
    colorButtons[i]=b
    b.MouseButton1Click:Connect(function()
        settings.color={preset[2],preset[3],preset[4]}
        updateSettingsText()
    end)
end
local resetBtn = makeSettingButton(settingsPanel,"↺ افتراضي",UDim2.new(0,10,0,338),UDim2.new(0,90,0,30))
local closeSettings = makeSettingButton(settingsPanel,"إغلاق",UDim2.new(0,108,0,338),UDim2.new(0,90,0,30))
local modeLabel = Instance.new("TextLabel", settingsPanel)
modeLabel.Size=UDim2.new(0,100,0,30); modeLabel.Position=UDim2.new(0,206,0,338); modeLabel.BackgroundTransparency=1; modeLabel.Text="وضع التعديل: عادي"; modeLabel.TextColor3=Color3.fromRGB(180,180,180); modeLabel.Font=Enum.Font.Gotham; modeLabel.TextSize=10; modeLabel.TextWrapped=true; modeLabel.ZIndex=202

local editButtonMode, editChatMode = false, false
local function updateModes()
    editButton.BackgroundColor3 = editButtonMode and DISCORD_COLOR or Color3.fromRGB(45,45,45)
    editChat.BackgroundColor3 = editChatMode and DISCORD_COLOR or Color3.fromRGB(45,45,45)
    modeLabel.Text = (editButtonMode and editChatMode and "وضع التعديل: الزر + الشات") or (editButtonMode and "وضع التعديل: الزر") or (editChatMode and "وضع التعديل: الشات") or "وضع التعديل: عادي"
end
editButton.MouseButton1Click:Connect(function() editButtonMode=not editButtonMode; editChatMode=false; updateModes() end)
editChat.MouseButton1Click:Connect(function() editChatMode=not editChatMode; editButtonMode=false; updateModes() end)
saveBtn.MouseButton1Click:Connect(function() saveSettings(); settingsPanel.Visible=false; updateModes(); showStatus("تم حفظ إعدادات الشات") end)
resetBtn.MouseButton1Click:Connect(function()
    settings.visibleMessages=defaultMessages; settings.width=0.36; settings.height=0.36; settings.buttonPosition="TopLeft"; settings.buttonX=10; settings.buttonY=10; settings.chatX=8; settings.chatY=48; settings.color={88,101,242}; settings.opacity=0.15
    saveSettings(); updateSettingsText(); updateModes()
end)
settingsBtn.MouseButton1Click:Connect(function() settingsPanel.Visible=not settingsPanel.Visible; updateModes() end)
updateSettingsText()
    msgLabel.Text = "الرسائل الظاهرة: " .. tostring(settings.visibleMessages)
    sizeLabel.Text = string.format("الحجم: %d%% × %d%%", math.floor(settings.width*100), math.floor(settings.height*100))
    posLabel.Text = "مكان زر الفتح: " .. settings.buttonPosition
    frame.Size = UDim2.new(settings.width,0,settings.height,0)
    toggleBtn.Position = BUTTON_POSITIONS[settings.buttonPosition]
    if settings.buttonPosition == "TopLeft" then settingsBtn.Position = UDim2.new(0,94,0,11)
    elseif settings.buttonPosition == "TopRight" then settingsBtn.Position = UDim2.new(1,-132,0,11)
    elseif settings.buttonPosition == "BottomLeft" then settingsBtn.Position = UDim2.new(0,94,1,-57)
    else settingsBtn.Position = UDim2.new(1,-132,1,-57) end
end

local function refreshVisibleMessages()
    local keep = settings.visibleMessages
    while #globalState.queue > keep do
        local old = table.remove(globalState.queue,1)
        if old and old.Parent then old:Destroy() end
    end
    task.defer(function()
        if globalState.scroll and globalState.scroll.Parent then
            globalState.scroll.CanvasPosition = Vector2.new(0, math.max(0, globalState.layout.AbsoluteContentSize.Y-globalState.scroll.AbsoluteSize.Y))
        end
    end)
end

msgMinus.MouseButton1Click:Connect(function() settings.visibleMessages=math.max(MIN_VISIBLE_MESSAGES,settings.visibleMessages-1); refreshVisibleMessages(); updateSettingsText() end)
msgPlus.MouseButton1Click:Connect(function() settings.visibleMessages=math.min(MAX_VISIBLE_MESSAGES,settings.visibleMessages+1); updateSettingsText() end)
widthMinus.MouseButton1Click:Connect(function() settings.width=math.max(0.25,settings.width-0.03); updateSettingsText() end)
widthPlus.MouseButton1Click:Connect(function() settings.width=math.min(0.75,settings.width+0.03); updateSettingsText() end)
heightMinus.MouseButton1Click:Connect(function() settings.height=math.max(0.22,settings.height-0.03); updateSettingsText() end)
heightPlus.MouseButton1Click:Connect(function() settings.height=math.min(0.75,settings.height+0.03); updateSettingsText() end)
updateSettingsText()

-- ══════════════════════════════════════
--       تحريك الزر + تحريك الشات + Resize
-- ══════════════════════════════════════
local function clamp(v, minv, maxv) return math.max(minv, math.min(maxv, v)) end
local draggingTarget, dragStart, startPos
local function beginDrag(target, input)
    draggingTarget = target
    dragStart = input.Position
    startPos = target.Position
end
local function updateDrag(input)
    if not draggingTarget or not dragStart or not startPos then return end
    local delta = input.Position - dragStart
    local maxX = math.max(0, gui.AbsoluteSize.X - draggingTarget.AbsoluteSize.X - 4)
    local maxY = math.max(0, gui.AbsoluteSize.Y - draggingTarget.AbsoluteSize.Y - 4)
    local nx = clamp(startPos.X.Offset + delta.X, 4, maxX)
    local ny = clamp(startPos.Y.Offset + delta.Y, 4, maxY)
    draggingTarget.Position = UDim2.new(0,nx,0,ny)
    if draggingTarget == toggleBtn then settings.buttonX=nx; settings.buttonY=ny end
    if draggingTarget == frame then settings.chatX=nx; settings.chatY=ny end
    updateSettingsText()
end
local function endDrag() draggingTarget=nil; dragStart=nil; startPos=nil end

toggleBtn.InputBegan:Connect(function(input)
    if (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) and editButtonMode then beginDrag(toggleBtn,input) end
end)
header.InputBegan:Connect(function(input)
    if (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) and editChatMode then beginDrag(frame,input) end
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingTarget and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then updateDrag(input) end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then endDrag() end
end)

local resizeHandle = Instance.new("TextButton", frame)
resizeHandle.Name="ResizeHandle"
resizeHandle.Size=UDim2.new(0,22,0,22)
resizeHandle.Position=UDim2.new(1,-22,1,-22)
resizeHandle.BackgroundColor3=DISCORD_COLOR
resizeHandle.BackgroundTransparency=0.15
resizeHandle.Text="↘"
resizeHandle.TextColor3=Color3.new(1,1,1)
resizeHandle.Font=Enum.Font.GothamBold
resizeHandle.TextSize=13
resizeHandle.BorderSizePixel=0
resizeHandle.ZIndex=30
Instance.new("UICorner",resizeHandle).CornerRadius=UDim.new(0,6)
local resizing=false
local resizeStart, startW, startH
resizeHandle.InputBegan:Connect(function(input)
    if (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) and editChatMode then
        resizing=true; resizeStart=input.Position; startW=frame.AbsoluteSize.X; startH=frame.AbsoluteSize.Y
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if resizing and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
        local d=input.Position-resizeStart
        settings.width=clamp((startW+d.X)/math.max(gui.AbsoluteSize.X,1),0.25,0.8)
        settings.height=clamp((startH+d.Y)/math.max(gui.AbsoluteSize.Y,1),0.22,0.8)
        updateSettingsText()
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then resizing=false end
end)

-- ══════════════════════════════════════
--         نظام الفيد (عام / روم) - Factory
-- ══════════════════════════════════════

local function createFeed(visible)
    local scroll = Instance.new("ScrollingFrame", feedHolder)
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.Position = UDim2.new(0, 0, 0, 0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollingDirection = Enum.ScrollingDirection.Y
    scroll.ElasticBehavior = Enum.ElasticBehavior.Never
    scroll.Visible = visible

    local lay = Instance.new("UIListLayout", scroll)
    lay.Padding = UDim.new(0, 4)
    lay.SortOrder = Enum.SortOrder.LayoutOrder

    local pad = Instance.new("UIPadding", scroll)
    pad.PaddingTop = UDim.new(0, 4)
    pad.PaddingBottom = UDim.new(0, 4)
    pad.PaddingLeft = UDim.new(0, 4)
    pad.PaddingRight = UDim.new(0, 4)

    local state = {
        scroll = scroll,
        layout = lay,
        queue = {},
        count = 0,
        lastId = 0,
        atBottom = true,
        channel = nil,
    }

    -- دائماً ننتقل مباشرة لآخر رسالة
    lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasPosition = Vector2.new(0, math.max(0, lay.AbsoluteContentSize.Y - scroll.AbsoluteSize.Y))
    end)

    scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        local maxY = math.max(0, lay.AbsoluteContentSize.Y - scroll.AbsoluteSize.Y)
        state.atBottom = (maxY - scroll.CanvasPosition.Y) <= AUTO_SCROLL_THRESHOLD
    end)

    return state
end

globalState = createFeed(true)

local function addMessageTo(state, user, msg)
    local discord = isDiscord(user)
    local displayName = cleanName(user)
    local color = discord and DISCORD_COLOR or getColor(user)
    local isSelf = user == LocalPlayer.Name

    if isSelf then displayName = displayName .. " (you)" end
    if discord then displayName = "[D] " .. displayName end

    local container = Instance.new("Frame", state.scroll)
    container.Size = UDim2.new(1, 0, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.BackgroundTransparency = 1

    state.count += 1
    container.LayoutOrder = state.count

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

    label.Text = string.format(
        '<font color="%s"><b>%s:</b></font> %s',
        toHex(color), escapeRich(displayName), escapeRich(msg)
    )

    label.TextTransparency = 1
    TweenService:Create(label, TweenInfo.new(0.1), {TextTransparency = 0}):Play()

    table.insert(state.queue, container)
    local keep = math.clamp(settings.visibleMessages, MIN_VISIBLE_MESSAGES, MAX_VISIBLE_MESSAGES)
    while #state.queue > MAX_MESSAGES do
        local old = table.remove(state.queue, 1)
        if old and old.Parent then old:Destroy() end
    end
    task.defer(function()
        if state.scroll and state.scroll.Parent then
            state.scroll.CanvasPosition = Vector2.new(0, math.max(0, state.layout.AbsoluteContentSize.Y - state.scroll.AbsoluteSize.Y))
        end
    end)
end

local function resetFeed(state)
    for _, c in ipairs(state.queue) do
        if c and c.Parent then c:Destroy() end
    end
    state.queue = {}
    state.count = 0
    state.lastId = 0
    state.atBottom = true
end

-- ══════════════════════════════════════
--      نظام الفقاعات (ستاك + عرض/مدة ديناميكي)
-- ══════════════════════════════════════

local function getHead(char)
    if not char then return nil end
    return char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
end

local function bubbleDuration(text)
    local extra = math.max(0, #text - 20) * DURATION_PER_CHAR
    return math.min(MAX_BUBBLE_DURATION, BASE_BUBBLE_DURATION + extra)
end

local function getOrCreateBubbleStack(playerName, head)
    local existing = playerBubbles[playerName]
    if existing and existing.billboard and existing.billboard.Parent then
        existing.billboard.Adornee = head
        return existing
    end

    -- المقاسات كلها Offset (بكسل) فقط بدون أي Scale، حتى تبقى نفس الحجم بالشاشة
    -- مهما بعّدت أو قرّبت الكاميرا، ومكانها يضبط تلقائي مع حركة الراس بدون "تقفيز"
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ChatBubbleStack"
    -- البيلبورد بطبيعته ما يقفل (clip) المحتوى عن حدوده، فمحتوى الستاك يكبر لفوق
    -- براحته برة الصندوق. صندوق طويل (كان 280) يخلي "أسفل" الصندوق ينزل جوا/تحت
    -- الراس لأن البيلبورد يتمركز على نقطة StudsOffset. خليناه صغير + رفعنا الأوفست شوي.
    billboard.Size = UDim2.new(0, BUBBLE_MAX_WIDTH + 30, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2.6, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 60
    billboard.Adornee = head
    billboard.Parent = head

    local stack = Instance.new("Frame", billboard)
    stack.AnchorPoint = Vector2.new(0.5, 1)
    stack.Position = UDim2.new(0.5, 0, 1, 0)
    stack.Size = UDim2.new(1, 0, 0, 0)
    stack.AutomaticSize = Enum.AutomaticSize.Y
    stack.BackgroundTransparency = 1

    local listLayout = Instance.new("UIListLayout", stack)
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.Padding = UDim.new(0, 6)

    local data = {
        billboard = billboard,
        stack = stack,
        bubbles = {},
        counter = 0,
    }
    playerBubbles[playerName] = data
    return data
end

local function pushBubble(playerName, text)
    local player = Players:FindFirstChild(playerName)
    if not player or not player.Character then return end

    local head = getHead(player.Character)
    if not head then return end

    local data = getOrCreateBubbleStack(playerName, head)
    data.counter += 1

    -- فقاعة جديدة = LayoutOrder أكبر = تترسب بأسفل الستاك (الأقرب للراس)
    -- والقديمة تلقائياً تتدفع لفوق لأن الـ VerticalAlignment = Bottom
    local bub = Instance.new("Frame", data.stack)
    bub.AutomaticSize = Enum.AutomaticSize.XY
    bub.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    bub.BorderSizePixel = 0
    bub.LayoutOrder = data.counter
    Instance.new("UICorner", bub).CornerRadius = UDim.new(0, 14)

    local pad = Instance.new("UIPadding", bub)
    pad.PaddingTop = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.PaddingLeft = UDim.new(0, 12)
    pad.PaddingRight = UDim.new(0, 12)

    local txt = Instance.new("TextLabel", bub)
    txt.AutomaticSize = Enum.AutomaticSize.XY
    txt.BackgroundTransparency = 1
    txt.Text = text                 -- RichText مقفول هنا، فمافيه خطر تنسيق مكسور أساساً
    txt.RichText = false
    txt.TextColor3 = Color3.fromRGB(20, 20, 20)
    txt.Font = Enum.Font.GothamMedium
    txt.TextSize = 14
    txt.TextWrapped = true

    -- يكبر عرض الفقاعة حتى BUBBLE_MAX_WIDTH قبل ما يكسر سطر (مو يحشرها على طول)
    -- وارتفاعها مفتوح، فرسالة طويلة تطول الفقاعة لتحت مو تتكدس أسطر فوق بعض بعرض ضيق
    local constraint = Instance.new("UISizeConstraint", txt)
    constraint.MaxSize = Vector2.new(BUBBLE_MAX_WIDTH, 10000)

    bub.BackgroundTransparency = 1
    txt.TextTransparency = 1
    TweenService:Create(bub, TweenInfo.new(0.15, Enum.EasingStyle.Back), {BackgroundTransparency = 0}):Play()
    TweenService:Create(txt, TweenInfo.new(0.15), {TextTransparency = 0}):Play()

    table.insert(data.bubbles, bub)

    -- حد أقصى لعدد الفقاعات الظاهرة بنفس اللحظة فوق نفس اللاعب
    if #data.bubbles > BUBBLE_MAX_VISIBLE then
        local old = table.remove(data.bubbles, 1)
        if old and old.Parent then
            TweenService:Create(old, TweenInfo.new(0.12), {BackgroundTransparency = 1}):Play()
            task.delay(0.12, function() if old.Parent then old:Destroy() end end)
        end
    end

    -- مدة العرض تطول شوي مع طول الرسالة (بحد أقصى وأدنى منطقيين)
    local duration = bubbleDuration(text)
    task.delay(duration, function()
        for i, b in ipairs(data.bubbles) do
            if b == bub then
                table.remove(data.bubbles, i)
                break
            end
        end
        if bub and bub.Parent then
            TweenService:Create(bub, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            local lbl = bub:FindFirstChildWhichIsA("TextLabel")
            if lbl then TweenService:Create(lbl, TweenInfo.new(0.2), {TextTransparency = 1}):Play() end
            task.delay(0.2, function() if bub.Parent then bub:Destroy() end end)
        end
    end)
end

-- ══════════════════════════════════════
--         إرسال رسالة
-- ══════════════════════════════════════


local function send(text)
    if text == "" then return end
    if tick() - lastSent < 0.8 then return end

    local channel = "global"

    lastSent = tick()
    text = text:sub(1, 200)

    pushBubble(LocalPlayer.Name, text)

    task.spawn(function()
        pcall(function()
            request({
                Url = API_URL,
                Method = "POST",
                Headers = HEADERS,
                Body = HttpService:JSONEncode({
                    username = LocalPlayer.Name,
                    message = text,
                    room = "global"
                })
            })
        end)
    end)
end

local function trySend()
    if box.Text ~= "" then
        send(box.Text)
        box.Text = ""
    end
end

box.FocusLost:Connect(function(enter)
    if enter then trySend() end
end)

sendBtn.MouseButton1Click:Connect(trySend)

-- ══════════════════════════════════════
--   استقبال الرسائل (لوب عام واحد يخدم أي فيد)
-- ══════════════════════════════════════
-- لكل فيد: أول مرة (أو أول مرة بعد تبديل روم) نجيب آخر 30 رسالة كتاريخ،
-- وبعدها نسحب فقط id أكبر من آخر id شفناه (ما نرجع نجيب نفس الرسائل القديمة للأبد).

local function startGlobalLoop(state)
    task.spawn(function()
        local loaded = false
        while task.wait(POLL_INTERVAL) do
            pcall(function()
                local url
                if not loaded then
                    url = API_URL .. "?select=*&order=id.desc&limit=10&room=eq.global"
                else
                    url = API_URL .. "?select=*&order=id.asc&limit=20&room=eq.global&id=gt." .. state.lastId
                end
                local res = request({Url=url, Method="GET", Headers=HEADERS})
                if res and res.Body then
                    local data=HttpService:JSONDecode(res.Body)
                    if type(data)=="table" then
                        if not loaded then
                            for i=#data,1,-1 do
                                local v=data[i]
                                if v.id then
                                    addMessageTo(state,v.username,v.message)
                                    state.lastId=math.max(state.lastId,v.id)
                                end
                            end
                            loaded=true
                        else
                            for _,v in ipairs(data) do
                                if v.id and v.id > state.lastId then
                                    state.lastId=v.id
                                    addMessageTo(state,v.username,v.message)
                                    if not isDiscord(v.username) and v.username ~= LocalPlayer.Name then
                                        pushBubble(v.username,v.message)
                                        if not isOpen then
                                            pcall(function() notifySound:Play() end)
                                            local original = toggleBtn.BackgroundColor3
                                            task.spawn(function()
                                                for i=1,4 do
                                                    TweenService:Create(toggleBtn,TweenInfo.new(0.12),{BackgroundColor3=DISCORD_COLOR}):Play()
                                                    task.wait(0.12)
                                                    TweenService:Create(toggleBtn,TweenInfo.new(0.12),{BackgroundColor3=original}):Play()
                                                    task.wait(0.12)
                                                end
                                            end)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
    end)
end

startGlobalLoop(globalState)

-- ══════════════════════════════════════
--         زر الفتح والإغلاق
-- ══════════════════════════════════════

toggleBtn.MouseButton1Click:Connect(function()
    isOpen = not isOpen

    if isOpen then
        settingsPanel.Visible = false
        frame.Visible = true
        frame.Size = UDim2.new(0, 0, 0, 0)
        frame.BackgroundTransparency = 1
        TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
            Size = UDim2.new(settings.width,0,settings.height,0),
            BackgroundTransparency = 0.15
        }):Play()
        toggleBtn.Text = "X"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
        task.defer(function()
            globalState.scroll.CanvasPosition = Vector2.new(0, math.max(0, globalState.layout.AbsoluteContentSize.Y-globalState.scroll.AbsoluteSize.Y))
        end)
    else
        TweenService:Create(frame, TweenInfo.new(0.15), {
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1
        }):Play()
        toggleBtn.Text = "💬  Chat"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        task.delay(0.15, function() frame.Visible = false end)
    end
end)

-- ══════════════════════════════════════
--         تجهيز اللاعبين
-- ══════════════════════════════════════

local function setupPlayer(plr)
    plr.CharacterAdded:Connect(function()
        -- نخلي الفقاعة تتجدد على الراس الجديد بعد الإحياء، القديمة تنحذف تلقائياً
        -- مع الكاركتر القديم لأنها كانت Parent لراسه
        playerBubbles[plr.Name] = nil
    end)
end

for _, p in ipairs(Players:GetPlayers()) do setupPlayer(p) end
Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(plr)
    local data = playerBubbles[plr.Name]
    if data and data.billboard and data.billboard.Parent then
        data.billboard:Destroy()
    end
    playerBubbles[plr.Name] = nil
    userColors[plr.Name] = nil
end)


-- زر "/" للكمبيوتر: يفتح الشات ويركّز خانة الكتابة مباشرة.
-- على الجوال/الآيباد يبقى زر Chat واضحاً وقابلاً للمس.
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Slash then
        if not isOpen then
            toggleBtn:Activate()
            task.defer(function() box:CaptureFocus() end)
        else
            box:CaptureFocus()
        end
    end
end)

print("Pro Chat Global v16 Loaded - Customizable")
