-- Pro Chat v15 - LEGENDARY EDITION
-- إضافات هذي النسخة: منشن (@) + إيموجي سريع + صوت تنبيه/منشن + تحكم بالغرفة (طرد/قائمة أعضاء)
-- + لمسات بصرية (تدرجات/توهج/باجات غير مقروء).
--
-- ملاحظات مهمة (اقرأها قبل التشغيل):
-- 1) لازم يكون عمود "room" (نوع text) موجود بجدول chat_messages (من التحديث السابق).
-- 2) نظام "طرد/مالك الغرفة" اجتماعي بالكامل (يعتمد على رسائل نظام بالشات نفسه)،
--    مافيه صلاحيات سيرفر حقيقية - يعني مجرد فلتر محلي يخلي تجربة كل ناس الغرفة
--    اللي يستخدمون السكربت متوافقة، مش حماية حقيقية.
-- 3) NOTIFY_SOUND_ID و MENTION_SOUND_ID تحت قيم مؤقتة (rbxassetid://0 = بدون صوت).
--    روح Studio Toolbox > Creator Store > Audio، دور صوت يعجبك، يمين كلك "Copy Asset ID"
--    وحط الرقم بدالها، لأن ما أقدر أتأكد من صلاحية أي رقم صوت محدد وقت كتابة الكود.
-- ما لمسنا API_URL / API_KEY / HEADERS ولا أي شي تبع التخزين، خلّيناها كما هي.

-- ══════════════════════════════════════
--              Services
-- ══════════════════════════════════════

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer

local API_URL = "https://ylhowczarhclwkpsagxo.supabase.co/rest/v1/chat_messages"
local API_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlsaG93Y3phcmhjbHdrcHNhZ3hvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI1MDQ2MTksImV4cCI6MjA5ODA4MDYxOX0.vnFWM8LZNgfBlKuGolX5K7p4xzldwLPrXdHfM43b7_E"
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

local CHAT_SIZE = UDim2.new(0.38, 0, 0.40, 0)
local DISCORD_COLOR = Color3.fromRGB(88, 101, 242)
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

local MAX_MESSAGES = 150
local POLL_INTERVAL = 0.15
local AUTO_SCROLL_THRESHOLD = 40

-- الفقاعات
local BUBBLE_MAX_WIDTH = 230
local BUBBLE_MAX_VISIBLE = 4
local BASE_BUBBLE_DURATION = 3
local MAX_BUBBLE_DURATION = 9
local DURATION_PER_CHAR = 0.06

-- منشن
local MENTION_SELF_COLOR = "#FFD700"
local MENTION_OTHER_COLOR = "#FFA15A"

-- صوت (بدّل الأرقام بصوت حقيقي من Toolbox - شرح بالأعلى)
local NOTIFY_SOUND_ID = "rbxassetid://0"
local MENTION_SOUND_ID = "rbxassetid://0"
local SOUND_COOLDOWN = 0.6

-- إيموجي سريع (تضغط الزر يضيفه بآخر الكتابة)
local QUICK_EMOJIS = {"🙂", "😂", "❤️", "🔥", "👍", "💯"}

-- اختصارات نص -> إيموجي تتفعل تلقائي وقت الإرسال
local EMOJI_SHORTCUTS = {
    {":)", "🙂"},
    {":(", "🙁"},
    {":D", "😂"},
    {":d", "😂"},
    {"<3", "❤️"},
    {":fire:", "🔥"},
    {":100:", "💯"},
    {":+1:", "👍"},
}

-- ══════════════════════════════════════
--              متغيرات الحالة
-- ══════════════════════════════════════

local userColors = {}
local playerBubbles = {}
local lastSent = 0
local isOpen = false
local activeTab = "global"

local roomDisplayName = nil
local roomHasPassword = false
local roomOwnerName = nil
local roomBans = {}          -- [username] = true
local roomMembersSet = {}    -- [username] = true
local roomMembersOrder = {}  -- {username, username, ...}

local unreadGlobal = 0
local unreadRoom = 0
local lastSoundPlayed = 0

-- ══════════════════════════════════════
--         دوال مساعدة (مالها أي شي بالـ GUI)
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

local function deriveRoomChannel(name, password)
    name = (name or ""):lower()
    password = password or ""
    local raw = name .. "::" .. password
    local hash = 5381
    for i = 1, #raw do
        hash = (hash * 33 + string.byte(raw, i)) % 2147483647
    end
    return "room_" .. tostring(hash)
end

local function escapePattern(s)
    return (s:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1"))
end

local function applyEmojiShortcuts(text)
    for _, pair in ipairs(EMOJI_SHORTCUTS) do
        text = text:gsub(escapePattern(pair[1]), pair[2])
    end
    return text
end

-- يلوّن @اسم لو كان فعلاً اسم لاعب موجود بالسيرفر (بدون كسر RichText)
local function highlightMentions(msg)
    return (msg:gsub("@(%w+)", function(name)
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name:lower() == name:lower() then
                local color = (p.Name == LocalPlayer.Name) and MENTION_SELF_COLOR or MENTION_OTHER_COLOR
                return string.format('<font color="%s"><b>@%s</b></font>', color, p.Name)
            end
        end
        return "@" .. name
    end))
end

local function playNotifySound(soundId, volume, bypassCooldown)
    if not bypassCooldown and (tick() - lastSoundPlayed < SOUND_COOLDOWN) then return end
    lastSoundPlayed = tick()
    local s = Instance.new("Sound")
    s.SoundId = soundId
    s.Volume = volume or 0.5
    s.Parent = SoundService
    local ok = pcall(function() s:Play() end)
    Debris:AddItem(s, 3)
end

-- ══════════════════════════════════════
--         GUI - PHASE 1: بناء العناصر فقط
-- ══════════════════════════════════════

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

local frame = Instance.new("Frame", gui)
frame.Size = CHAT_SIZE
frame.Position = UDim2.new(0, 8, 0, 48)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel = 0
frame.Visible = false
frame.ClipsDescendants = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(60, 60, 60)
stroke.Thickness = 1

-- توهج خفيف مستمر على حدود النافذة (تأثير بصري بسيط وخفيف على الأداء)
TweenService:Create(stroke, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
    Color = Color3.fromRGB(120, 140, 255)
}):Play()

-- ── الهيدر ──
local header = Instance.new("Frame", frame)
header.Size = UDim2.new(1, -12, 0, 26)
header.Position = UDim2.new(0, 6, 0, 6)
header.BackgroundTransparency = 1

local tabGlobal = Instance.new("TextButton", header)
tabGlobal.Size = UDim2.new(0.32, -2, 1, 0)
tabGlobal.Position = UDim2.new(0, 0, 0, 0)
tabGlobal.BackgroundColor3 = ACTIVE_TAB_COLOR
tabGlobal.Text = "عام"
tabGlobal.TextSize = 12
tabGlobal.Font = Enum.Font.GothamBold
tabGlobal.TextColor3 = Color3.new(1, 1, 1)
tabGlobal.BorderSizePixel = 0
tabGlobal.TextTruncate = Enum.TextTruncate.AtEnd
Instance.new("UICorner", tabGlobal).CornerRadius = UDim.new(0, 6)

local badgeGlobal = Instance.new("Frame", tabGlobal)
badgeGlobal.Size = UDim2.new(0, 14, 0, 14)
badgeGlobal.Position = UDim2.new(1, -16, 0, 2)
badgeGlobal.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
badgeGlobal.Visible = false
badgeGlobal.ZIndex = 5
Instance.new("UICorner", badgeGlobal).CornerRadius = UDim.new(1, 0)
local badgeGlobalLabel = Instance.new("TextLabel", badgeGlobal)
badgeGlobalLabel.Size = UDim2.new(1, 0, 1, 0)
badgeGlobalLabel.BackgroundTransparency = 1
badgeGlobalLabel.TextColor3 = Color3.new(1, 1, 1)
badgeGlobalLabel.Font = Enum.Font.GothamBold
badgeGlobalLabel.TextSize = 9
badgeGlobalLabel.Text = "0"
badgeGlobalLabel.ZIndex = 6

local tabRoom = Instance.new("TextButton", header)
tabRoom.Size = UDim2.new(0.32, -2, 1, 0)
tabRoom.Position = UDim2.new(0.32, 2, 0, 0)
tabRoom.BackgroundColor3 = INACTIVE_TAB_COLOR
tabRoom.Text = "غرفة"
tabRoom.TextSize = 12
tabRoom.Font = Enum.Font.GothamBold
tabRoom.TextColor3 = Color3.new(1, 1, 1)
tabRoom.BorderSizePixel = 0
tabRoom.TextTruncate = Enum.TextTruncate.AtEnd
Instance.new("UICorner", tabRoom).CornerRadius = UDim.new(0, 6)

local badgeRoom = Instance.new("Frame", tabRoom)
badgeRoom.Size = UDim2.new(0, 14, 0, 14)
badgeRoom.Position = UDim2.new(1, -16, 0, 2)
badgeRoom.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
badgeRoom.Visible = false
badgeRoom.ZIndex = 5
Instance.new("UICorner", badgeRoom).CornerRadius = UDim.new(1, 0)
local badgeRoomLabel = Instance.new("TextLabel", badgeRoom)
badgeRoomLabel.Size = UDim2.new(1, 0, 1, 0)
badgeRoomLabel.BackgroundTransparency = 1
badgeRoomLabel.TextColor3 = Color3.new(1, 1, 1)
badgeRoomLabel.Font = Enum.Font.GothamBold
badgeRoomLabel.TextSize = 9
badgeRoomLabel.Text = "0"
badgeRoomLabel.ZIndex = 6

local btnCreate = Instance.new("TextButton", header)
btnCreate.Size = UDim2.new(0.18, -2, 1, 0)
btnCreate.Position = UDim2.new(0.64, 4, 0, 0)
btnCreate.BackgroundColor3 = Color3.fromRGB(50, 160, 90)
btnCreate.Text = "+ إنشاء"
btnCreate.TextSize = 11
btnCreate.Font = Enum.Font.GothamBold
btnCreate.TextColor3 = Color3.new(1, 1, 1)
btnCreate.BorderSizePixel = 0
Instance.new("UICorner", btnCreate).CornerRadius = UDim.new(0, 6)

local btnJoin = Instance.new("TextButton", header)
btnJoin.Size = UDim2.new(0.18, -2, 1, 0)
btnJoin.Position = UDim2.new(0.82, 6, 0, 0)
btnJoin.BackgroundColor3 = Color3.fromRGB(160, 130, 50)
btnJoin.Text = "دخول"
btnJoin.TextSize = 11
btnJoin.Font = Enum.Font.GothamBold
btnJoin.TextColor3 = Color3.new(1, 1, 1)
btnJoin.BorderSizePixel = 0
Instance.new("UICorner", btnJoin).CornerRadius = UDim.new(0, 6)

-- ── حاوية الفيدات ──
local feedHolder = Instance.new("Frame", frame)
feedHolder.Size = UDim2.new(1, -12, 1, -102)
feedHolder.Position = UDim2.new(0, 6, 0, 38)
feedHolder.BackgroundTransparency = 1
feedHolder.ClipsDescendants = true

local roomEmptyLabel = Instance.new("TextLabel", feedHolder)
roomEmptyLabel.Size = UDim2.new(1, -10, 1, 0)
roomEmptyLabel.Position = UDim2.new(0, 5, 0, 0)
roomEmptyLabel.BackgroundTransparency = 1
roomEmptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
roomEmptyLabel.Font = Enum.Font.Gotham
roomEmptyLabel.TextSize = 12
roomEmptyLabel.TextWrapped = true
roomEmptyLabel.Text = "ما انضميت لأي غرفة بعد.\nاضغط \"+ إنشاء\" لتسوي غرفة، أو \"دخول\" للانضمام لغرفة صاحبك."
roomEmptyLabel.Visible = false
roomEmptyLabel.ZIndex = 2

local btnMembers = Instance.new("TextButton", feedHolder)
btnMembers.Size = UDim2.new(0, 64, 0, 20)
btnMembers.Position = UDim2.new(1, -68, 0, 4)
btnMembers.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
btnMembers.BackgroundTransparency = 0.1
btnMembers.Text = "أعضاء"
btnMembers.TextColor3 = Color3.new(1, 1, 1)
btnMembers.Font = Enum.Font.GothamBold
btnMembers.TextSize = 11
btnMembers.BorderSizePixel = 0
btnMembers.ZIndex = 3
btnMembers.Visible = false
Instance.new("UICorner", btnMembers).CornerRadius = UDim.new(0, 6)

-- ── شريط الإيموجي السريع ──
local emojiRow = Instance.new("Frame", frame)
emojiRow.Size = UDim2.new(1, -12, 0, 22)
emojiRow.Position = UDim2.new(0, 6, 1, -64)
emojiRow.BackgroundTransparency = 1

local emojiLayout = Instance.new("UIListLayout", emojiRow)
emojiLayout.FillDirection = Enum.FillDirection.Horizontal
emojiLayout.Padding = UDim.new(0, 4)
emojiLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local emojiButtons = {}
for _, emoji in ipairs(QUICK_EMOJIS) do
    local eb = Instance.new("TextButton", emojiRow)
    eb.Size = UDim2.new(0, 28, 1, 0)
    eb.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    eb.Text = emoji
    eb.TextSize = 14
    eb.BorderSizePixel = 0
    Instance.new("UICorner", eb).CornerRadius = UDim.new(0, 6)
    table.insert(emojiButtons, {btn = eb, emoji = emoji})
end

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

local sendGradient = Instance.new("UIGradient", sendBtn)
sendGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(130, 140, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 90, 220)),
})
sendGradient.Rotation = 90

local statusLabel = Instance.new("TextLabel", frame)
statusLabel.Size = UDim2.new(1, -12, 0, 14)
statusLabel.Position = UDim2.new(0, 6, 1, -78)
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3 = Color3.fromRGB(255, 200, 120)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 11
statusLabel.Text = ""
statusLabel.TextTransparency = 1
statusLabel.ZIndex = 10

-- ── Popup إنشاء/انضمام لغرفة ──
local popup = Instance.new("Frame", frame)
popup.Size = UDim2.new(1, 0, 1, 0)
popup.BackgroundColor3 = Color3.new(0, 0, 0)
popup.BackgroundTransparency = 0.4
popup.Visible = false
popup.Active = true
popup.ZIndex = 50
popup.BorderSizePixel = 0

local popupCard = Instance.new("Frame", popup)
popupCard.Size = UDim2.new(0.86, 0, 0, 150)
popupCard.Position = UDim2.new(0.07, 0, 0.5, -75)
popupCard.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
popupCard.BorderSizePixel = 0
popupCard.ZIndex = 51
Instance.new("UICorner", popupCard).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", popupCard).Color = Color3.fromRGB(70, 70, 70)

local popupTitle = Instance.new("TextLabel", popupCard)
popupTitle.Size = UDim2.new(1, -16, 0, 22)
popupTitle.Position = UDim2.new(0, 8, 0, 8)
popupTitle.BackgroundTransparency = 1
popupTitle.TextColor3 = Color3.new(1, 1, 1)
popupTitle.Font = Enum.Font.GothamBold
popupTitle.TextSize = 14
popupTitle.TextXAlignment = Enum.TextXAlignment.Left
popupTitle.Text = "إنشاء غرفة"
popupTitle.ZIndex = 52

local function makePopupInput(parent, yPos, placeholder)
    local b = Instance.new("TextBox", parent)
    b.Size = UDim2.new(1, -16, 0, 30)
    b.Position = UDim2.new(0, 8, 0, yPos)
    b.BackgroundColor3 = Color3.fromRGB(45, 45, 48)
    b.BorderSizePixel = 0
    b.PlaceholderText = placeholder
    b.PlaceholderColor3 = Color3.fromRGB(130, 130, 130)
    b.Text = ""
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.Gotham
    b.TextSize = 13
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.ClearTextOnFocus = false
    b.ZIndex = 52
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    Instance.new("UIPadding", b).PaddingLeft = UDim.new(0, 8)
    return b
end

local popupRoomName = makePopupInput(popupCard, 38, "اسم الغرفة")
local popupRoomPass = makePopupInput(popupCard, 74, "كلمة السر (اختياري)")

local popupStatus = Instance.new("TextLabel", popupCard)
popupStatus.Size = UDim2.new(1, -16, 0, 16)
popupStatus.Position = UDim2.new(0, 8, 0, 108)
popupStatus.BackgroundTransparency = 1
popupStatus.TextColor3 = Color3.fromRGB(255, 120, 120)
popupStatus.Font = Enum.Font.Gotham
popupStatus.TextSize = 11
popupStatus.TextXAlignment = Enum.TextXAlignment.Left
popupStatus.Text = ""
popupStatus.ZIndex = 52

local popupConfirm = Instance.new("TextButton", popupCard)
popupConfirm.Size = UDim2.new(0.46, -12, 0, 26)
popupConfirm.Position = UDim2.new(0, 8, 1, -32)
popupConfirm.BackgroundColor3 = DISCORD_COLOR
popupConfirm.Text = "إنشاء"
popupConfirm.TextColor3 = Color3.new(1, 1, 1)
popupConfirm.Font = Enum.Font.GothamBold
popupConfirm.TextSize = 12
popupConfirm.BorderSizePixel = 0
popupConfirm.ZIndex = 52
Instance.new("UICorner", popupConfirm).CornerRadius = UDim.new(0, 6)

local popupCancel = Instance.new("TextButton", popupCard)
popupCancel.Size = UDim2.new(0.46, -12, 0, 26)
popupCancel.Position = UDim2.new(0.54, 4, 1, -32)
popupCancel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
popupCancel.Text = "إلغاء"
popupCancel.TextColor3 = Color3.new(1, 1, 1)
popupCancel.Font = Enum.Font.GothamBold
popupCancel.TextSize = 12
popupCancel.BorderSizePixel = 0
popupCancel.ZIndex = 52
Instance.new("UICorner", popupCancel).CornerRadius = UDim.new(0, 6)

-- ── Popup أعضاء الغرفة ──
local membersPopup = Instance.new("Frame", frame)
membersPopup.Size = UDim2.new(1, 0, 1, 0)
membersPopup.BackgroundColor3 = Color3.new(0, 0, 0)
membersPopup.BackgroundTransparency = 0.4
membersPopup.Visible = false
membersPopup.Active = true
membersPopup.ZIndex = 50
membersPopup.BorderSizePixel = 0

local membersCard = Instance.new("Frame", membersPopup)
membersCard.Size = UDim2.new(0.86, 0, 0, 190)
membersCard.Position = UDim2.new(0.07, 0, 0.5, -95)
membersCard.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
membersCard.BorderSizePixel = 0
membersCard.ZIndex = 51
Instance.new("UICorner", membersCard).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", membersCard).Color = Color3.fromRGB(70, 70, 70)

local membersTitle = Instance.new("TextLabel", membersCard)
membersTitle.Size = UDim2.new(1, -16, 0, 22)
membersTitle.Position = UDim2.new(0, 8, 0, 8)
membersTitle.BackgroundTransparency = 1
membersTitle.TextColor3 = Color3.new(1, 1, 1)
membersTitle.Font = Enum.Font.GothamBold
membersTitle.TextSize = 14
membersTitle.TextXAlignment = Enum.TextXAlignment.Left
membersTitle.Text = "أعضاء الغرفة"
membersTitle.ZIndex = 52

local membersListHolder = Instance.new("ScrollingFrame", membersCard)
membersListHolder.Size = UDim2.new(1, -16, 0, 118)
membersListHolder.Position = UDim2.new(0, 8, 0, 34)
membersListHolder.BackgroundTransparency = 1
membersListHolder.BorderSizePixel = 0
membersListHolder.ScrollBarThickness = 3
membersListHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
membersListHolder.AutomaticCanvasSize = Enum.AutomaticSize.Y
membersListHolder.ZIndex = 52

local membersListLayout = Instance.new("UIListLayout", membersListHolder)
membersListLayout.Padding = UDim.new(0, 2)
membersListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local membersCloseBtn = Instance.new("TextButton", membersCard)
membersCloseBtn.Size = UDim2.new(1, -16, 0, 26)
membersCloseBtn.Position = UDim2.new(0, 8, 1, -32)
membersCloseBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
membersCloseBtn.Text = "إغلاق"
membersCloseBtn.TextColor3 = Color3.new(1, 1, 1)
membersCloseBtn.Font = Enum.Font.GothamBold
membersCloseBtn.TextSize = 12
membersCloseBtn.BorderSizePixel = 0
membersCloseBtn.ZIndex = 52
Instance.new("UICorner", membersCloseBtn).CornerRadius = UDim.new(0, 6)

-- ══════════════════════════════════════
--    PHASE 2: الدوال (تستخدم عناصر فيز 1)
-- ══════════════════════════════════════

local function showStatus(msg)
    statusLabel.Text = msg
    statusLabel.TextTransparency = 0
    TweenService:Create(statusLabel, TweenInfo.new(1.8), {TextTransparency = 1}):Play()
end

local function flashToggle()
    local original = isOpen and Color3.fromRGB(180, 60, 60) or Color3.fromRGB(30, 30, 30)
    TweenService:Create(toggleBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(255, 210, 60)}):Play()
    task.delay(0.3, function()
        if toggleBtn and toggleBtn.Parent then
            TweenService:Create(toggleBtn, TweenInfo.new(0.25), {BackgroundColor3 = original}):Play()
        end
    end)
end

local function addPressFeedback(btn, baseColor)
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.08), {BackgroundColor3 = baseColor:Lerp(Color3.new(0, 0, 0), 0.25)}):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = baseColor}):Play()
    end)
end

local function updateBadge(badgeFrame, badgeLabel, count)
    if count > 0 then
        badgeFrame.Visible = true
        badgeLabel.Text = count > 9 and "9+" or tostring(count)
    else
        badgeFrame.Visible = false
    end
end

-- ── فيدات الشات (factory) ──

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
    scroll.ZIndex = 1

    local lay = Instance.new("UIListLayout", scroll)
    lay.Padding = UDim.new(0, 4)
    lay.SortOrder = Enum.SortOrder.LayoutOrder

    local pad = Instance.new("UIPadding", scroll)
    pad.PaddingTop = UDim.new(0, 4)
    pad.PaddingBottom = UDim.new(0, 4)
    pad.PaddingLeft = UDim.new(0, 4)
    pad.PaddingRight = UDim.new(0, 4)

    local state = {
        scroll = scroll, layout = lay, queue = {}, count = 0,
        lastId = 0, atBottom = true, channel = nil,
    }

    lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if state.atBottom then
            scroll.CanvasPosition = Vector2.new(0, math.max(0, lay.AbsoluteContentSize.Y - scroll.AbsoluteSize.Y))
        end
    end)

    scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        local maxY = math.max(0, lay.AbsoluteContentSize.Y - scroll.AbsoluteSize.Y)
        state.atBottom = (maxY - scroll.CanvasPosition.Y) <= AUTO_SCROLL_THRESHOLD
    end)

    return state
end

local globalState = createFeed(true)
local roomState = createFeed(false)

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
    container:SetAttribute("authorName", user)

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

    local processedMsg = highlightMentions(escapeRich(msg))

    label.Text = string.format(
        '<font color="%s"><b>%s:</b></font> %s',
        toHex(color), escapeRich(displayName), processedMsg
    )

    label.TextTransparency = 1
    TweenService:Create(label, TweenInfo.new(0.12), {TextTransparency = 0}):Play()

    table.insert(state.queue, container)
    if #state.queue > MAX_MESSAGES then
        local old = table.remove(state.queue, 1)
        if old and old.Parent then old:Destroy() end
    end
end

local function addSystemNotice(state, text)
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
    label.TextColor3 = Color3.fromRGB(150, 150, 150)
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.Text = "— " .. text .. " —"

    table.insert(state.queue, container)
    if #state.queue > MAX_MESSAGES then
        local old = table.remove(state.queue, 1)
        if old and old.Parent then old:Destroy() end
    end
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

local function removeMessagesFrom(state, username)
    for _, c in ipairs(state.scroll:GetChildren()) do
        if c:IsA("Frame") and c:GetAttribute("authorName") == username then
            c:Destroy()
        end
    end
end

-- ── الفقاعات ──

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

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ChatBubbleStack"
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

    local data = {billboard = billboard, stack = stack, bubbles = {}, counter = 0}
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
    txt.Text = text
    txt.RichText = false
    txt.TextColor3 = Color3.fromRGB(20, 20, 20)
    txt.Font = Enum.Font.GothamMedium
    txt.TextSize = 14
    txt.TextWrapped = true

    local constraint = Instance.new("UISizeConstraint", txt)
    constraint.MaxSize = Vector2.new(BUBBLE_MAX_WIDTH, 10000)

    bub.BackgroundTransparency = 1
    txt.TextTransparency = 1
    TweenService:Create(bub, TweenInfo.new(0.15, Enum.EasingStyle.Back), {BackgroundTransparency = 0}):Play()
    TweenService:Create(txt, TweenInfo.new(0.15), {TextTransparency = 0}):Play()

    table.insert(data.bubbles, bub)

    if #data.bubbles > BUBBLE_MAX_VISIBLE then
        local old = table.remove(data.bubbles, 1)
        if old and old.Parent then
            TweenService:Create(old, TweenInfo.new(0.12), {BackgroundTransparency = 1}):Play()
            task.delay(0.12, function() if old.Parent then old:Destroy() end end)
        end
    end

    local duration = bubbleDuration(text)
    task.delay(duration, function()
        for i, b in ipairs(data.bubbles) do
            if b == bub then table.remove(data.bubbles, i); break end
        end
        if bub and bub.Parent then
            TweenService:Create(bub, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            local lbl = bub:FindFirstChildWhichIsA("TextLabel")
            if lbl then TweenService:Create(lbl, TweenInfo.new(0.2), {TextTransparency = 1}):Play() end
            task.delay(0.2, function() if bub.Parent then bub:Destroy() end end)
        end
    end)
end

-- ── الأعضاء/الطرد ──

local function trackMember(username)
    if username == "SYSTEM" or roomBans[username] then return end
    if not roomMembersSet[username] then
        roomMembersSet[username] = true
        table.insert(roomMembersOrder, username)
    end
end

local function refreshMembersList()
    for _, c in ipairs(membersListHolder:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    local isOwner = (roomOwnerName ~= nil and roomOwnerName == LocalPlayer.Name)

    for i, name in ipairs(roomMembersOrder) do
        if not roomBans[name] then
            local row = Instance.new("Frame", membersListHolder)
            row.Size = UDim2.new(1, 0, 0, 26)
            row.LayoutOrder = i
            row.BackgroundTransparency = 1
            row.ZIndex = 52

            local nameLbl = Instance.new("TextLabel", row)
            nameLbl.Size = UDim2.new(1, -60, 1, 0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.TextColor3 = Color3.new(1, 1, 1)
            nameLbl.Font = Enum.Font.Gotham
            nameLbl.TextSize = 12
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.ZIndex = 52
            nameLbl.Text = name .. (name == roomOwnerName and " (مالك)" or "")

            if isOwner and name ~= LocalPlayer.Name then
                local kickBtn = Instance.new("TextButton", row)
                kickBtn.Size = UDim2.new(0, 56, 0, 22)
                kickBtn.Position = UDim2.new(1, -56, 0.5, -11)
                kickBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
                kickBtn.Text = "طرد"
                kickBtn.TextColor3 = Color3.new(1, 1, 1)
                kickBtn.Font = Enum.Font.GothamBold
                kickBtn.TextSize = 11
                kickBtn.BorderSizePixel = 0
                kickBtn.ZIndex = 52
                Instance.new("UICorner", kickBtn).CornerRadius = UDim.new(0, 6)
                kickBtn.MouseButton1Click:Connect(function()
                    kickMember(name)
                end)
            end
        end
    end
end

-- ── منشن ──

local function checkMention(sender, message)
    if sender == LocalPlayer.Name then return false end
    local lowerMsg = message:lower()
    local tag = "@" .. LocalPlayer.Name:lower()
    if lowerMsg:find(tag, 1, true) then
        showStatus(sender .. " ذكرك بالشات!")
        playNotifySound(MENTION_SOUND_ID, 0.6, true)
        if not isOpen then flashToggle() end
        return true
    end
    return false
end

-- ── تابز / حالة الغرفة ──

local function updateRoomEmptyVisibility()
    roomEmptyLabel.Visible = (activeTab == "room" and roomState.channel == nil)
end

local function updateMembersButtonVisibility()
    btnMembers.Visible = (activeTab == "room" and roomState.channel ~= nil)
end

local function setActiveTab(tab)
    activeTab = tab
    globalState.scroll.Visible = (tab == "global")
    roomState.scroll.Visible = (tab == "room")
    tabGlobal.BackgroundColor3 = (tab == "global") and ACTIVE_TAB_COLOR or INACTIVE_TAB_COLOR
    tabRoom.BackgroundColor3 = (tab == "room") and ACTIVE_TAB_COLOR or INACTIVE_TAB_COLOR

    if tab == "global" then
        unreadGlobal = 0
        updateBadge(badgeGlobal, badgeGlobalLabel, 0)
    else
        unreadRoom = 0
        updateBadge(badgeRoom, badgeRoomLabel, 0)
    end

    updateRoomEmptyVisibility()
    updateMembersButtonVisibility()
end

function kickMember(name) -- global على مستوى الفايل عشان refreshMembersList تقدر تستدعيها قبل تعريفها بالترتيب
    if not roomState.channel then return end
    if roomOwnerName ~= LocalPlayer.Name then return end
    roomBans[name] = true
    roomMembersSet[name] = nil
    removeMessagesFrom(roomState, name)
    addSystemNotice(roomState, name .. " تم طرده من الغرفة")
    task.spawn(function()
        pcall(function()
            request({
                Url = API_URL, Method = "POST", Headers = HEADERS,
                Body = HttpService:JSONEncode({username = "SYSTEM", message = "BAN:" .. name, room = roomState.channel})
            })
        end)
    end)
    showStatus("طردت " .. name .. " من الغرفة")
    refreshMembersList()
end

local function openMembersPopup()
    refreshMembersList()
    membersPopup.Visible = true
end

local function handleLocalKicked()
    showStatus("تم طردك من هذي الغرفة!")
    roomState.channel = nil
    roomOwnerName = nil
    roomBans = {}
    roomMembersSet = {}
    roomMembersOrder = {}
    resetFeed(roomState)
    tabRoom.Text = "غرفة"
    membersPopup.Visible = false
    setActiveTab("global")
end

local function sendSystemMessage(channel, message)
    task.spawn(function()
        pcall(function()
            request({
                Url = API_URL, Method = "POST", Headers = HEADERS,
                Body = HttpService:JSONEncode({username = "SYSTEM", message = message, room = channel})
            })
        end)
    end)
end

local function getActiveChannel()
    if activeTab == "global" then return "global" end
    return roomState.channel
end

local function send(text)
    if text == "" then return end
    if tick() - lastSent < 0.8 then return end

    local channel = getActiveChannel()
    if not channel then
        showStatus("ما انت بغرفة! اضغط + إنشاء أو دخول")
        return
    end

    lastSent = tick()
    text = text:sub(1, 200)
    text = applyEmojiShortcuts(text)

    pushBubble(LocalPlayer.Name, text)

    task.spawn(function()
        pcall(function()
            request({
                Url = API_URL, Method = "POST", Headers = HEADERS,
                Body = HttpService:JSONEncode({username = LocalPlayer.Name, message = text, room = channel})
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

local function openPopup(mode)
    popup:SetAttribute("mode", mode)
    popupRoomName.Text = ""
    popupRoomPass.Text = ""
    popupStatus.Text = ""
    if mode == "create" then
        popupTitle.Text = "إنشاء غرفة جديدة"
        popupConfirm.Text = "إنشاء"
    else
        popupTitle.Text = "الانضمام لغرفة"
        popupConfirm.Text = "دخول"
    end
    popup.Visible = true
end

local function confirmPopup()
    local name = trim(popupRoomName.Text)
    if name == "" then
        popupStatus.Text = "اكتب اسم الغرفة!"
        return
    end
    if #name > 30 then
        popupStatus.Text = "اسم الغرفة طويل وايد!"
        return
    end

    local pass = popupRoomPass.Text
    local channel = deriveRoomChannel(name, pass)
    local mode = popup:GetAttribute("mode") or "join"

    roomOwnerName = nil
    roomBans = {}
    roomMembersSet = {}
    roomMembersOrder = {}

    roomState.channel = channel
    roomHasPassword = (pass ~= "")
    roomDisplayName = name

    tabRoom.Text = "غرفة: " .. shortenName(name, 8) .. (roomHasPassword and "*" or "")

    resetFeed(roomState)

    if mode == "create" then
        roomOwnerName = LocalPlayer.Name
        sendSystemMessage(channel, "ROOM_CREATED:" .. LocalPlayer.Name)
    end

    popup.Visible = false
    setActiveTab("room")
    showStatus(mode == "create" and ("تم إنشاء الغرفة: " .. name) or ("انضميت لغرفة: " .. name))
end

-- ── اللوب العام لاستقبال الرسائل ──

local function handleIncoming(v, state, isRoomFeed, allowBubbles)
    if v.username == "SYSTEM" then
        if isRoomFeed then
            local createdName = v.message:match("^ROOM_CREATED:(.+)$")
            if createdName then
                roomOwnerName = createdName
                addSystemNotice(state, createdName .. " أنشأ الغرفة")
            end
            local bannedName = v.message:match("^BAN:(.+)$")
            if bannedName then
                roomBans[bannedName] = true
                roomMembersSet[bannedName] = nil
                removeMessagesFrom(state, bannedName)
                addSystemNotice(state, bannedName .. " تم طرده من الغرفة")
                if bannedName == LocalPlayer.Name then
                    handleLocalKicked()
                end
            end
        end
        return
    end

    if isRoomFeed and roomBans[v.username] then return end

    addMessageTo(state, v.username, v.message)
    if isRoomFeed then trackMember(v.username) end

    local isSelf = (v.username == LocalPlayer.Name)
    local viewingThisTab = (isRoomFeed and activeTab == "room") or ((not isRoomFeed) and activeTab == "global")

    if not isSelf then
        if not viewingThisTab then
            if isRoomFeed then
                unreadRoom += 1
                updateBadge(badgeRoom, badgeRoomLabel, unreadRoom)
            else
                unreadGlobal += 1
                updateBadge(badgeGlobal, badgeGlobalLabel, unreadGlobal)
            end
        end

        local wasMention = checkMention(v.username, v.message)
        if not wasMention then
            playNotifySound(NOTIFY_SOUND_ID, 0.3)
        end

        if allowBubbles and not isDiscord(v.username) then
            pushBubble(v.username, v.message)
        end
    end
end

local function startChannelLoop(state, getChannel, allowBubbles, isRoomFeed)
    task.spawn(function()
        local loadedChannel = nil
        while task.wait(POLL_INTERVAL) do
            local channel = getChannel()
            if channel then
                if channel ~= loadedChannel then
                    loadedChannel = channel
                    state.lastId = 0
                    pcall(function()
                        local res = request({
                            Url = API_URL .. "?select=*&order=id.desc&limit=30&room=eq." .. channel,
                            Method = "GET", Headers = HEADERS
                        })
                        if res and res.Body then
                            local data = HttpService:JSONDecode(res.Body)
                            if type(data) == "table" then
                                for i = #data, 1, -1 do
                                    local v = data[i]
                                    if v.id then
                                        if v.id > state.lastId then state.lastId = v.id end
                                        handleIncoming(v, state, isRoomFeed, false) -- ما نبعث فقاعات/أصوات لتاريخ قديم
                                    end
                                end
                            end
                        end
                    end)
                else
                    pcall(function()
                        local res = request({
                            Url = API_URL .. "?select=*&order=id.asc&limit=50&room=eq." .. channel .. "&id=gt." .. state.lastId,
                            Method = "GET", Headers = HEADERS
                        })
                        if res and res.Body then
                            local data = HttpService:JSONDecode(res.Body)
                            if type(data) == "table" then
                                for _, v in ipairs(data) do
                                    if v.id and v.id > state.lastId then
                                        state.lastId = v.id
                                        handleIncoming(v, state, isRoomFeed, allowBubbles)
                                    end
                                end
                            end
                        end
                    end)
                end
            end
        end
    end)
end

local function setupPlayer(plr)
    plr.CharacterAdded:Connect(function()
        playerBubbles[plr.Name] = nil
    end)
end

-- ══════════════════════════════════════
--    PHASE 3: ربط الأحداث + التشغيل
-- ══════════════════════════════════════

box.FocusLost:Connect(function(enter) if enter then trySend() end end)
sendBtn.MouseButton1Click:Connect(trySend)
addPressFeedback(sendBtn, DISCORD_COLOR)
addPressFeedback(btnCreate, Color3.fromRGB(50, 160, 90))
addPressFeedback(btnJoin, Color3.fromRGB(160, 130, 50))

for _, item in ipairs(emojiButtons) do
    item.btn.MouseButton1Click:Connect(function()
        box.Text = box.Text .. item.emoji
    end)
end

tabGlobal.MouseButton1Click:Connect(function() setActiveTab("global") end)
tabRoom.MouseButton1Click:Connect(function() setActiveTab("room") end)

btnCreate.MouseButton1Click:Connect(function() openPopup("create") end)
btnJoin.MouseButton1Click:Connect(function() openPopup("join") end)

popupConfirm.MouseButton1Click:Connect(confirmPopup)
popupCancel.MouseButton1Click:Connect(function() popup.Visible = false end)
popupRoomName.FocusLost:Connect(function(enter) if enter then confirmPopup() end end)
popupRoomPass.FocusLost:Connect(function(enter) if enter then confirmPopup() end end)

btnMembers.MouseButton1Click:Connect(openMembersPopup)
membersCloseBtn.MouseButton1Click:Connect(function() membersPopup.Visible = false end)

startChannelLoop(globalState, function() return "global" end, true, false)
startChannelLoop(roomState, function() return roomState.channel end, true, true)

toggleBtn.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    if isOpen then
        frame.Visible = true
        frame.Size = UDim2.new(0, 0, 0, 0)
        frame.BackgroundTransparency = 1
        TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
            Size = CHAT_SIZE, BackgroundTransparency = 0.15
        }):Play()
        toggleBtn.Text = "X"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
    else
        TweenService:Create(frame, TweenInfo.new(0.15), {
            Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1
        }):Play()
        toggleBtn.Text = "C"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        task.delay(0.15, function() frame.Visible = false end)
    end
end)

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

updateRoomEmptyVisibility()
updateMembersButtonVisibility()
print("Pro Chat v15 LEGENDARY Loaded")
