-- ╔══════════════════════════════════════╗
-- ║      Pro Chat v15 - LEGENDARY        ║
-- ║   discord.gg/CXzNPpdFh2             ║
-- ╚══════════════════════════════════════╝
-- ملاحظة: لازم يكون عمود "room" (نوع text) بجدول chat_messages
-- SQL: ALTER TABLE chat_messages ADD COLUMN room text DEFAULT 'global';

local Players     = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService= game:GetService("TweenService")
local CoreGui     = game:GetService("CoreGui")
local SoundService= game:GetService("SoundService")
local Debris      = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer

local API_URL = "https://fzkxotptuhmhkuhnsoav.supabase.co/rest/v1/chat_messages"
local API_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ6a3hvdHB0dWhtaGt1aG5zb2F2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkyNTQ1OTYsImV4cCI6MjA5NDgzMDU5Nn0.etgvcKzEo89I_nvhB_EyLUbVgbV-gHgBJbW_NjNM7wo"
local HEADERS = {
    ["apikey"]        = API_KEY,
    ["Authorization"] = "Bearer " .. API_KEY,
    ["Content-Type"]  = "application/json"
}

local request = http_request or request or (syn and syn.request) or (fluxus and fluxus.request)
if not request then warn("HTTP not supported") return end

if CoreGui:FindFirstChild("ProChat") then CoreGui.ProChat:Destroy() end

-- ══════════════════════════════════════
--              ثوابت
-- ══════════════════════════════════════

local DISCORD_LINK       = "https://discord.gg/CXzNPpdFh2"
local CHAT_SIZE          = UDim2.new(0.38, 0, 0.40, 0)
local DISCORD_COLOR      = Color3.fromRGB(88, 101, 242)
local ACTIVE_TAB_COLOR   = Color3.fromRGB(88, 101, 242)
local INACTIVE_TAB_COLOR = Color3.fromRGB(40, 40, 40)

local COLORS = {
    Color3.fromRGB(255, 107, 107), Color3.fromRGB(78,  205, 196),
    Color3.fromRGB(255, 230, 109), Color3.fromRGB(199, 128, 232),
    Color3.fromRGB(77,  182, 255), Color3.fromRGB(255, 159, 243),
    Color3.fromRGB(162, 255, 134),
}

local MAX_MESSAGES           = 150
local POLL_INTERVAL          = 0.4
local AUTO_SCROLL_THRESHOLD  = 40

-- فقاعات
local BUBBLE_MAX_WIDTH  = 230
local BUBBLE_MAX_VISIBLE = 4
local BASE_BUBBLE_DUR   = 3
local MAX_BUBBLE_DUR    = 9
local DUR_PER_CHAR      = 0.06

-- منشن
local MENTION_SELF_COLOR  = "#FFD700"
local MENTION_OTHER_COLOR = "#FFA15A"

-- صوت — بدّل الرقم بـ ID حقيقي من Toolbox > Audio (شرح: نسخ Asset ID)
local NOTIFY_SOUND_ID  = "rbxassetid://0"
local MENTION_SOUND_ID = "rbxassetid://0"
local SOUND_COOLDOWN   = 0.6

-- اختصارات نصية → إيموجي (تعمل تلقائي وقت الإرسال)
local EMOJI_SHORTCUTS = {
    {":)",    "🙂"}, {":(", "🙁"}, {":D", "😂"}, {":d", "😂"},
    {"<3",    "❤️"}, {":fire:", "🔥"}, {":100:", "💯"}, {":+1:", "👍"},
}

-- ══════════════════════════════════════
--         متغيرات الحالة
-- ══════════════════════════════════════

local userColors     = {}
local playerBubbles  = {}
local lastSent       = 0
local isOpen         = false
local firstOpen      = true
local activeTab      = "global"
local roomDisplayName  = nil
local roomHasPassword  = false
local roomOwnerName    = nil
local roomBans         = {}
local roomMembersSet   = {}
local roomMembersOrder = {}
local unreadGlobal   = 0
local unreadRoom     = 0
local lastSoundTime  = 0

-- ══════════════════════════════════════
--         دوال مساعدة
-- ══════════════════════════════════════

local function trim(s) return (s or ""):match("^%s*(.-)%s*$") end

local function getColor(name)
    if not userColors[name] then
        userColors[name] = COLORS[math.random(#COLORS)]
    end
    return userColors[name]
end

local function toHex(c)
    return string.format("#%02X%02X%02X", c.R*255, c.G*255, c.B*255)
end

local function isDiscord(name) return name:sub(1,3) == "DC:" end
local function cleanName(name) return isDiscord(name) and name:sub(4) or name end

local function escapeRich(t)
    t = t:gsub("&","&amp;")
    t = t:gsub("<","&lt;")
    t = t:gsub(">","&gt;")
    return t
end

local function shortenName(s, n)
    return #s > n and s:sub(1,n).."..." or s
end

local function deriveRoomChannel(name, pass)
    name = (name or ""):lower(); pass = pass or ""
    local raw = name.."::"..pass
    local h = 5381
    for i = 1,#raw do h=(h*33+string.byte(raw,i))%2147483647 end
    return "room_"..tostring(h)
end

local function escPat(s) return (s:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]","%%%1")) end

local function applyEmojiShortcuts(text)
    for _,p in ipairs(EMOJI_SHORTCUTS) do
        text = text:gsub(escPat(p[1]), p[2])
    end
    return text
end

local function highlightMentions(msg)
    return (msg:gsub("@(%w+)", function(name)
        for _,p in ipairs(Players:GetPlayers()) do
            if p.Name:lower() == name:lower() then
                local col = (p.Name == LocalPlayer.Name) and MENTION_SELF_COLOR or MENTION_OTHER_COLOR
                return string.format('<font color="%s"><b>@%s</b></font>', col, p.Name)
            end
        end
        return "@"..name
    end))
end

local function playSound(id, vol, force)
    if not force and (tick()-lastSoundTime < SOUND_COOLDOWN) then return end
    lastSoundTime = tick()
    local s = Instance.new("Sound")
    s.SoundId = id; s.Volume = vol or 0.5; s.Parent = SoundService
    pcall(function() s:Play() end)
    Debris:AddItem(s, 3)
end

-- ══════════════════════════════════════
--   GUI Phase 1 — بناء العناصر
--
-- Layout من الأسفل لفوق (بدون صف إيموجي):
--   H-6  ── أسفل frame
--   H-38 ── أعلى inputContainer  (32px)
--   H-42 ── أسفل statusLabel / feedHolder
--   H-56 ── أعلى statusLabel     (14px، ZIndex=10 يطفو فوق الفيد)
--   H-80 = 38 + (H-80): أسفل feedHolder
--   38   ── أعلى feedHolder
-- ══════════════════════════════════════

local gui = Instance.new("ScreenGui")
gui.Name          = "ProChat"
gui.ResetOnSpawn  = false
gui.IgnoreGuiInset= true
gui.DisplayOrder  = 999
gui.Parent        = CoreGui

-- زر التبديل
local toggleBtn = Instance.new("TextButton", gui)
toggleBtn.Size             = UDim2.new(0,32,0,32)
toggleBtn.Position         = UDim2.new(0,8,0,8)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
toggleBtn.Text             = "C"
toggleBtn.TextSize         = 16
toggleBtn.Font             = Enum.Font.GothamBold
toggleBtn.TextColor3       = Color3.new(1,1,1)
toggleBtn.BorderSizePixel  = 0
toggleBtn.ZIndex           = 100
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0,8)

-- براند "Pro Chat" بجانب الزر (مرئي دايماً)
local brandLabel = Instance.new("TextLabel", gui)
brandLabel.Size               = UDim2.new(0,62,0,14)
brandLabel.Position           = UDim2.new(0,44,0,15)
brandLabel.BackgroundTransparency = 1
brandLabel.Text               = "Pro Chat"
brandLabel.Font               = Enum.Font.GothamBold
brandLabel.TextSize           = 11
brandLabel.TextColor3         = Color3.fromRGB(160,170,255)
brandLabel.TextXAlignment     = Enum.TextXAlignment.Left
brandLabel.ZIndex             = 100

-- النافذة الرئيسية
local frame = Instance.new("Frame", gui)
frame.Size                 = CHAT_SIZE
frame.Position             = UDim2.new(0,8,0,48)
frame.BackgroundColor3     = Color3.fromRGB(18,18,18)
frame.BackgroundTransparency = 0.15
frame.BorderSizePixel      = 0
frame.Visible              = false
frame.ClipsDescendants     = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,10)

local stroke = Instance.new("UIStroke", frame)
stroke.Color     = Color3.fromRGB(60,60,60)
stroke.Thickness = 1
TweenService:Create(stroke,
    TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    {Color = Color3.fromRGB(120,140,255)}
):Play()

-- ── الهيدر ──
local header = Instance.new("Frame", frame)
header.Size                 = UDim2.new(1,-12,0,26)
header.Position             = UDim2.new(0,6,0,6)
header.BackgroundTransparency = 1

local function makeTab(parent, xScale, xOffset)
    local t = Instance.new("TextButton", parent)
    t.Size            = UDim2.new(xScale,-2,1,0)
    t.Position        = UDim2.new(xOffset,2,0,0)
    t.BackgroundColor3= INACTIVE_TAB_COLOR
    t.TextSize        = 12
    t.Font            = Enum.Font.GothamBold
    t.TextColor3      = Color3.new(1,1,1)
    t.BorderSizePixel = 0
    t.TextTruncate    = Enum.TextTruncate.AtEnd
    Instance.new("UICorner",t).CornerRadius = UDim.new(0,6)
    return t
end

local tabGlobal = makeTab(header, 0.32, 0)
tabGlobal.Position        = UDim2.new(0,0,0,0)
tabGlobal.BackgroundColor3= ACTIVE_TAB_COLOR
tabGlobal.Text            = "عام"

local tabRoom = makeTab(header, 0.32, 0.32)
tabRoom.Text = "غرفة"

local function makeBadge(parent)
    local f = Instance.new("Frame", parent)
    f.Size             = UDim2.new(0,14,0,14)
    f.Position         = UDim2.new(1,-16,0,2)
    f.BackgroundColor3 = Color3.fromRGB(220,60,60)
    f.Visible          = false
    f.ZIndex           = 5
    Instance.new("UICorner",f).CornerRadius = UDim.new(1,0)
    local lbl = Instance.new("TextLabel", f)
    lbl.Size              = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3        = Color3.new(1,1,1)
    lbl.Font              = Enum.Font.GothamBold
    lbl.TextSize          = 9
    lbl.Text              = "0"
    lbl.ZIndex            = 6
    return f, lbl
end

local badgeGlobal,  badgeGlobalLbl  = makeBadge(tabGlobal)
local badgeRoom,    badgeRoomLbl    = makeBadge(tabRoom)

local function makeHdrBtn(parent, xScale, xOffset, color, text)
    local b = Instance.new("TextButton", parent)
    b.Size             = UDim2.new(xScale,-2,1,0)
    b.Position         = UDim2.new(xOffset,4,0,0)
    b.BackgroundColor3 = color
    b.Text             = text
    b.TextSize         = 11
    b.Font             = Enum.Font.GothamBold
    b.TextColor3       = Color3.new(1,1,1)
    b.BorderSizePixel  = 0
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,6)
    return b
end

local btnCreate = makeHdrBtn(header,0.18,0.64, Color3.fromRGB(50,160,90),  "+ إنشاء")
local btnJoin   = makeHdrBtn(header,0.18,0.82, Color3.fromRGB(160,130,50), "دخول")

-- ── feedHolder ──
local feedHolder = Instance.new("Frame", frame)
feedHolder.Size             = UDim2.new(1,-12,1,-80)   -- bottom = H-42
feedHolder.Position         = UDim2.new(0,6,0,38)
feedHolder.BackgroundTransparency = 1
feedHolder.ClipsDescendants = true

local roomEmptyLabel = Instance.new("TextLabel", feedHolder)
roomEmptyLabel.Size               = UDim2.new(1,-10,1,0)
roomEmptyLabel.Position           = UDim2.new(0,5,0,0)
roomEmptyLabel.BackgroundTransparency = 1
roomEmptyLabel.TextColor3         = Color3.fromRGB(150,150,150)
roomEmptyLabel.Font               = Enum.Font.Gotham
roomEmptyLabel.TextSize           = 12
roomEmptyLabel.TextWrapped        = true
roomEmptyLabel.Text               = "ما انضميت لأي غرفة بعد.\nاضغط \"+ إنشاء\" لتسوي غرفة، أو \"دخول\" للانضمام."
roomEmptyLabel.Visible            = false
roomEmptyLabel.ZIndex             = 2

local btnMembers = Instance.new("TextButton", feedHolder)
btnMembers.Size             = UDim2.new(0,64,0,20)
btnMembers.Position         = UDim2.new(1,-68,0,4)
btnMembers.BackgroundColor3 = Color3.fromRGB(50,50,55)
btnMembers.Text             = "أعضاء"
btnMembers.TextColor3       = Color3.new(1,1,1)
btnMembers.Font             = Enum.Font.GothamBold
btnMembers.TextSize         = 11
btnMembers.BorderSizePixel  = 0
btnMembers.ZIndex           = 3
btnMembers.Visible          = false
Instance.new("UICorner",btnMembers).CornerRadius = UDim.new(0,6)

-- statusLabel — يطفو فوق أسفل الفيد كإشعار (ZIndex=10)
local statusLabel = Instance.new("TextLabel", frame)
statusLabel.Size               = UDim2.new(1,-12,0,14)
statusLabel.Position           = UDim2.new(0,6,1,-56)   -- top=H-56, bottom=H-42
statusLabel.BackgroundTransparency = 1
statusLabel.TextColor3         = Color3.fromRGB(255,200,120)
statusLabel.Font               = Enum.Font.GothamBold
statusLabel.TextSize           = 11
statusLabel.Text               = ""
statusLabel.TextTransparency   = 1
statusLabel.ZIndex             = 10

-- ── صندوق الكتابة ──
local inputContainer = Instance.new("Frame", frame)
inputContainer.Size               = UDim2.new(1,-12,0,32)
inputContainer.Position           = UDim2.new(0,6,1,-38)  -- top=H-38, bottom=H-6
inputContainer.BackgroundTransparency = 1

local box = Instance.new("TextBox", inputContainer)
box.Size              = UDim2.new(1,-62,1,0)
box.BackgroundColor3  = Color3.fromRGB(35,35,35)
box.BorderSizePixel   = 0
box.PlaceholderText   = "Type a message..."
box.PlaceholderColor3 = Color3.fromRGB(120,120,120)
box.Text              = ""
box.TextColor3        = Color3.new(1,1,1)
box.Font              = Enum.Font.Gotham
box.TextSize          = 13
box.TextXAlignment    = Enum.TextXAlignment.Left
box.ClearTextOnFocus  = false
box.ClipsDescendants  = true
Instance.new("UICorner",box).CornerRadius = UDim.new(0,8)
Instance.new("UIPadding",box).PaddingLeft = UDim.new(0,8)

local sendBtn = Instance.new("TextButton", inputContainer)
sendBtn.Size             = UDim2.new(0,56,1,0)
sendBtn.Position         = UDim2.new(1,-56,0,0)
sendBtn.BackgroundColor3 = DISCORD_COLOR
sendBtn.Text             = "إرسال"
sendBtn.TextSize         = 12
sendBtn.Font             = Enum.Font.GothamBold
sendBtn.TextColor3       = Color3.new(1,1,1)
sendBtn.BorderSizePixel  = 0
Instance.new("UICorner",sendBtn).CornerRadius = UDim.new(0,8)
local grad = Instance.new("UIGradient", sendBtn)
grad.Color    = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(130,140,255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80,90,220)),
})
grad.Rotation = 90

-- ── Popup غرفة ──
local function makePopupCard(frame)
    local bg = Instance.new("Frame", frame)
    bg.Size                 = UDim2.new(1,0,1,0)
    bg.BackgroundColor3     = Color3.new(0,0,0)
    bg.BackgroundTransparency = 0.4
    bg.Visible              = false
    bg.Active               = true
    bg.ZIndex               = 50
    bg.BorderSizePixel      = 0
    local card = Instance.new("Frame", bg)
    card.Size             = UDim2.new(0.86,0,0,155)
    card.Position         = UDim2.new(0.07,0,0.5,-77)
    card.BackgroundColor3 = Color3.fromRGB(28,28,30)
    card.BorderSizePixel  = 0
    card.ZIndex           = 51
    Instance.new("UICorner",card).CornerRadius = UDim.new(0,10)
    Instance.new("UIStroke",card).Color        = Color3.fromRGB(70,70,70)
    return bg, card
end

local popup, popupCard = makePopupCard(frame)

local function makeTitleLbl(parent, text)
    local l = Instance.new("TextLabel", parent)
    l.Size               = UDim2.new(1,-16,0,22)
    l.Position           = UDim2.new(0,8,0,8)
    l.BackgroundTransparency = 1
    l.TextColor3         = Color3.new(1,1,1)
    l.Font               = Enum.Font.GothamBold
    l.TextSize           = 14
    l.TextXAlignment     = Enum.TextXAlignment.Left
    l.Text               = text
    l.ZIndex             = 52
    return l
end

local popupTitle = makeTitleLbl(popupCard, "إنشاء غرفة")

local function makePopupInput(parent, y, hint)
    local b = Instance.new("TextBox", parent)
    b.Size              = UDim2.new(1,-16,0,30)
    b.Position          = UDim2.new(0,8,0,y)
    b.BackgroundColor3  = Color3.fromRGB(45,45,48)
    b.BorderSizePixel   = 0
    b.PlaceholderText   = hint
    b.PlaceholderColor3 = Color3.fromRGB(130,130,130)
    b.Text              = ""
    b.TextColor3        = Color3.new(1,1,1)
    b.Font              = Enum.Font.Gotham
    b.TextSize          = 13
    b.TextXAlignment    = Enum.TextXAlignment.Left
    b.ClearTextOnFocus  = false
    b.ZIndex            = 52
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,6)
    Instance.new("UIPadding",b).PaddingLeft = UDim.new(0,8)
    return b
end

local popupRoomName = makePopupInput(popupCard, 38, "اسم الغرفة")
local popupRoomPass = makePopupInput(popupCard, 74, "كلمة السر (اختياري)")

local popupStatus = Instance.new("TextLabel", popupCard)
popupStatus.Size               = UDim2.new(1,-16,0,16)
popupStatus.Position           = UDim2.new(0,8,0,110)
popupStatus.BackgroundTransparency = 1
popupStatus.TextColor3         = Color3.fromRGB(255,120,120)
popupStatus.Font               = Enum.Font.Gotham
popupStatus.TextSize           = 11
popupStatus.TextXAlignment     = Enum.TextXAlignment.Left
popupStatus.Text               = ""
popupStatus.ZIndex             = 52

local function makeCardBtn(parent, x, xPos, color, text)
    local b = Instance.new("TextButton", parent)
    b.Size             = UDim2.new(x,-10,0,26)
    b.Position         = UDim2.new(xPos,5,1,-32)
    b.BackgroundColor3 = color
    b.Text             = text
    b.TextColor3       = Color3.new(1,1,1)
    b.Font             = Enum.Font.GothamBold
    b.TextSize         = 12
    b.BorderSizePixel  = 0
    b.ZIndex           = 52
    Instance.new("UICorner",b).CornerRadius = UDim.new(0,6)
    return b
end

local popupConfirm = makeCardBtn(popupCard, 0.5, 0,    DISCORD_COLOR,              "إنشاء")
local popupCancel  = makeCardBtn(popupCard, 0.5, 0.5,  Color3.fromRGB(60,60,60),   "إلغاء")

-- ── Popup أعضاء ──
local membersPopup, membersCard = makePopupCard(frame)
membersCard.Size     = UDim2.new(0.86,0,0,195)
membersCard.Position = UDim2.new(0.07,0,0.5,-97)

makeTitleLbl(membersCard, "أعضاء الغرفة 👥")

local membersListHolder = Instance.new("ScrollingFrame", membersCard)
membersListHolder.Size               = UDim2.new(1,-16,0,120)
membersListHolder.Position           = UDim2.new(0,8,0,34)
membersListHolder.BackgroundTransparency = 1
membersListHolder.BorderSizePixel    = 0
membersListHolder.ScrollBarThickness = 3
membersListHolder.CanvasSize         = UDim2.new(0,0,0,0)
membersListHolder.AutomaticCanvasSize= Enum.AutomaticSize.Y
membersListHolder.ZIndex             = 52
local mll = Instance.new("UIListLayout", membersListHolder)
mll.Padding    = UDim.new(0,2)
mll.SortOrder  = Enum.SortOrder.LayoutOrder

local membersCloseBtn = makeCardBtn(membersCard, 1, 0, Color3.fromRGB(60,60,60), "إغلاق")

-- ══════════════════════════════════════
--   Phase 2 — الدوال
-- ══════════════════════════════════════

local function showStatus(msg)
    statusLabel.Text             = msg
    statusLabel.TextTransparency = 0
    TweenService:Create(statusLabel, TweenInfo.new(2), {TextTransparency=1}):Play()
end

local function flashToggle()
    local orig = isOpen and Color3.fromRGB(180,60,60) or Color3.fromRGB(30,30,30)
    TweenService:Create(toggleBtn, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(255,210,60)}):Play()
    task.delay(0.3, function()
        if toggleBtn and toggleBtn.Parent then
            TweenService:Create(toggleBtn, TweenInfo.new(0.25), {BackgroundColor3=orig}):Play()
        end
    end)
end

local function pressFeedback(btn, base)
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(btn,TweenInfo.new(0.08),{BackgroundColor3=base:Lerp(Color3.new(0,0,0),0.25)}):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(btn,TweenInfo.new(0.12),{BackgroundColor3=base}):Play()
    end)
end

local function updateBadge(f, lbl, n)
    f.Visible = (n > 0)
    lbl.Text  = n > 9 and "9+" or tostring(n)
end

-- ── فيد factory ──

local function createFeed(visible)
    local scroll = Instance.new("ScrollingFrame", feedHolder)
    scroll.Size               = UDim2.new(1,0,1,0)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel    = 0
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = Color3.fromRGB(100,100,100)
    scroll.CanvasSize         = UDim2.new(0,0,0,0)
    scroll.AutomaticCanvasSize= Enum.AutomaticSize.Y
    scroll.ScrollingDirection = Enum.ScrollingDirection.Y
    scroll.ElasticBehavior    = Enum.ElasticBehavior.Never
    scroll.Visible            = visible
    scroll.ZIndex             = 1

    local lay = Instance.new("UIListLayout", scroll)
    lay.Padding   = UDim.new(0,4)
    lay.SortOrder = Enum.SortOrder.LayoutOrder

    local pad = Instance.new("UIPadding", scroll)
    pad.PaddingTop = UDim.new(0,4); pad.PaddingBottom = UDim.new(0,4)
    pad.PaddingLeft= UDim.new(0,4); pad.PaddingRight  = UDim.new(0,4)

    local st = {scroll=scroll, layout=lay, queue={}, count=0, lastId=0, atBottom=true, channel=nil}

    local function scrollToBottom()
        scroll.CanvasPosition = Vector2.new(0, math.max(0, lay.AbsoluteContentSize.Y - scroll.AbsoluteSize.Y))
    end

    lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if not st.atBottom then return end
        scrollToBottom()
        -- defer: يمسك الحالات اللي AbsoluteContentSize تحسب قبل AutomaticSize يكتمل
        task.defer(scrollToBottom)
    end)
    scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        local mx = math.max(0, lay.AbsoluteContentSize.Y - scroll.AbsoluteSize.Y)
        st.atBottom = (mx - scroll.CanvasPosition.Y) <= AUTO_SCROLL_THRESHOLD
    end)
    st.scrollToBottom = scrollToBottom
    return st
end

local globalState = createFeed(true)
local roomState   = createFeed(false)

local function addMessageTo(st, user, msg)
    local discord      = isDiscord(user)
    local displayName  = cleanName(user)
    local color        = discord and DISCORD_COLOR or getColor(user)
    local isSelf       = (user == LocalPlayer.Name)
    if isSelf    then displayName = displayName.." (you)" end
    if discord   then displayName = "[D] "..displayName end

    local con = Instance.new("Frame", st.scroll)
    con.Size             = UDim2.new(1,0,0,0)
    con.AutomaticSize    = Enum.AutomaticSize.Y
    con.BackgroundTransparency = 1
    con:SetAttribute("authorName", user)
    st.count += 1
    con.LayoutOrder = st.count

    local lbl = Instance.new("TextLabel", con)
    lbl.Size             = UDim2.new(1,0,0,0)
    lbl.AutomaticSize    = Enum.AutomaticSize.Y
    lbl.BackgroundTransparency = 1
    lbl.RichText         = true
    lbl.TextColor3       = Color3.fromRGB(230,230,230)
    lbl.Font             = Enum.Font.Gotham
    lbl.TextSize         = 13
    lbl.TextWrapped      = true
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.Text = string.format('<font color="%s"><b>%s:</b></font> %s',
        toHex(color), escapeRich(displayName), highlightMentions(escapeRich(msg)))
    lbl.TextTransparency = 1
    TweenService:Create(lbl, TweenInfo.new(0.12), {TextTransparency=0}):Play()

    table.insert(st.queue, con)
    if #st.queue > MAX_MESSAGES then
        local old = table.remove(st.queue, 1)
        if old and old.Parent then old:Destroy() end
    end
end

local function addNotice(st, text)
    local con = Instance.new("Frame", st.scroll)
    con.Size             = UDim2.new(1,0,0,0)
    con.AutomaticSize    = Enum.AutomaticSize.Y
    con.BackgroundTransparency = 1
    st.count += 1; con.LayoutOrder = st.count
    local lbl = Instance.new("TextLabel", con)
    lbl.Size             = UDim2.new(1,0,0,0)
    lbl.AutomaticSize    = Enum.AutomaticSize.Y
    lbl.BackgroundTransparency = 1
    lbl.TextColor3       = Color3.fromRGB(150,150,150)
    lbl.Font             = Enum.Font.Gotham
    lbl.TextSize         = 11
    lbl.TextWrapped      = true
    lbl.TextXAlignment   = Enum.TextXAlignment.Center
    lbl.Text             = "— "..text.." —"
    table.insert(st.queue, con)
    if #st.queue > MAX_MESSAGES then
        local old = table.remove(st.queue,1)
        if old and old.Parent then old:Destroy() end
    end
end

local function resetFeed(st)
    for _,c in ipairs(st.queue) do if c and c.Parent then c:Destroy() end end
    st.queue = {}; st.count = 0; st.lastId = 0; st.atBottom = true
end

local function removeMsgsFrom(st, username)
    for _,c in ipairs(st.scroll:GetChildren()) do
        if c:IsA("Frame") and c:GetAttribute("authorName") == username then c:Destroy() end
    end
end

-- ── فقاعات ──

local function getHead(char)
    if not char then return nil end
    return char:FindFirstChild("Head")
        or char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChildWhichIsA("BasePart")
end

local function bubDur(text)
    return math.min(MAX_BUBBLE_DUR, BASE_BUBBLE_DUR + math.max(0,#text-20)*DUR_PER_CHAR)
end

local function getOrMakeStack(pname, head)
    local ex = playerBubbles[pname]
    if ex and ex.billboard and ex.billboard.Parent then
        ex.billboard.Adornee = head; return ex
    end
    local bb = Instance.new("BillboardGui")
    bb.Name          = "ChatBubbleStack"
    bb.Size          = UDim2.new(0, BUBBLE_MAX_WIDTH+30, 0, 50)
    bb.StudsOffset   = Vector3.new(0, 2.6, 0)
    bb.AlwaysOnTop   = true
    bb.MaxDistance   = 60
    bb.Adornee       = head
    bb.Parent        = head

    local stk = Instance.new("Frame", bb)
    stk.AnchorPoint       = Vector2.new(0.5,1)
    stk.Position          = UDim2.new(0.5,0,1,0)
    stk.Size              = UDim2.new(1,0,0,0)
    stk.AutomaticSize     = Enum.AutomaticSize.Y
    stk.BackgroundTransparency = 1

    local ll = Instance.new("UIListLayout", stk)
    ll.FillDirection      = Enum.FillDirection.Vertical
    ll.SortOrder          = Enum.SortOrder.LayoutOrder
    ll.VerticalAlignment  = Enum.VerticalAlignment.Bottom
    ll.HorizontalAlignment= Enum.HorizontalAlignment.Center
    ll.Padding            = UDim.new(0,6)

    local data = {billboard=bb, stack=stk, bubbles={}, counter=0}
    playerBubbles[pname] = data
    return data
end

local function pushBubble(pname, text)
    local plr = Players:FindFirstChild(pname)
    if not plr or not plr.Character then return end
    local head = getHead(plr.Character)
    if not head then return end

    local data = getOrMakeStack(pname, head)
    data.counter += 1

    local bub = Instance.new("Frame", data.stack)
    bub.AutomaticSize    = Enum.AutomaticSize.XY
    bub.BackgroundColor3 = Color3.fromRGB(255,255,255)
    bub.BorderSizePixel  = 0
    bub.LayoutOrder      = data.counter
    Instance.new("UICorner",bub).CornerRadius = UDim.new(0,14)

    local pad = Instance.new("UIPadding",bub)
    pad.PaddingTop=UDim.new(0,8); pad.PaddingBottom=UDim.new(0,8)
    pad.PaddingLeft=UDim.new(0,12); pad.PaddingRight=UDim.new(0,12)

    local txt = Instance.new("TextLabel",bub)
    txt.AutomaticSize    = Enum.AutomaticSize.XY
    txt.BackgroundTransparency = 1
    txt.Text             = text
    txt.RichText         = false
    txt.TextColor3       = Color3.fromRGB(20,20,20)
    txt.Font             = Enum.Font.GothamMedium
    txt.TextSize         = 14
    txt.TextWrapped      = true
    Instance.new("UISizeConstraint",txt).MaxSize = Vector2.new(BUBBLE_MAX_WIDTH, 10000)

    bub.BackgroundTransparency = 1; txt.TextTransparency = 1
    TweenService:Create(bub, TweenInfo.new(0.15, Enum.EasingStyle.Back), {BackgroundTransparency=0}):Play()
    TweenService:Create(txt, TweenInfo.new(0.15), {TextTransparency=0}):Play()

    table.insert(data.bubbles, bub)
    if #data.bubbles > BUBBLE_MAX_VISIBLE then
        local old = table.remove(data.bubbles,1)
        if old and old.Parent then
            TweenService:Create(old,TweenInfo.new(0.12),{BackgroundTransparency=1}):Play()
            task.delay(0.12, function() if old.Parent then old:Destroy() end end)
        end
    end

    task.delay(bubDur(text), function()
        for i,b in ipairs(data.bubbles) do
            if b==bub then table.remove(data.bubbles,i); break end
        end
        if bub and bub.Parent then
            TweenService:Create(bub,TweenInfo.new(0.2),{BackgroundTransparency=1}):Play()
            local l = bub:FindFirstChildWhichIsA("TextLabel")
            if l then TweenService:Create(l,TweenInfo.new(0.2),{TextTransparency=1}):Play() end
            task.delay(0.2, function() if bub.Parent then bub:Destroy() end end)
        end
    end)
end

-- ── أعضاء / طرد ──

local kickMember  -- forward declaration

local function trackMember(username)
    if username == "SYSTEM" or roomBans[username] then return end
    if not roomMembersSet[username] then
        roomMembersSet[username] = true
        table.insert(roomMembersOrder, username)
    end
end

local function refreshMembersList()
    for _,c in ipairs(membersListHolder:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    local isOwner = (roomOwnerName == LocalPlayer.Name)
    for i,name in ipairs(roomMembersOrder) do
        if not roomBans[name] then
            local row = Instance.new("Frame", membersListHolder)
            row.Size             = UDim2.new(1,0,0,26)
            row.LayoutOrder      = i
            row.BackgroundTransparency = 1
            row.ZIndex           = 52
            local nl = Instance.new("TextLabel",row)
            nl.Size              = UDim2.new(1,-60,1,0)
            nl.BackgroundTransparency = 1
            nl.TextColor3        = Color3.new(1,1,1)
            nl.Font              = Enum.Font.Gotham
            nl.TextSize          = 12
            nl.TextXAlignment    = Enum.TextXAlignment.Left
            nl.ZIndex            = 52
            nl.Text = name..(name==roomOwnerName and " 👑" or "")
            if isOwner and name ~= LocalPlayer.Name then
                local kb = Instance.new("TextButton",row)
                kb.Size             = UDim2.new(0,52,0,20)
                kb.Position         = UDim2.new(1,-52,0.5,-10)
                kb.BackgroundColor3 = Color3.fromRGB(180,60,60)
                kb.Text             = "طرد"
                kb.TextColor3       = Color3.new(1,1,1)
                kb.Font             = Enum.Font.GothamBold
                kb.TextSize         = 11
                kb.BorderSizePixel  = 0
                kb.ZIndex           = 52
                Instance.new("UICorner",kb).CornerRadius = UDim.new(0,6)
                kb.MouseButton1Click:Connect(function() kickMember(name) end)
            end
        end
    end
end

kickMember = function(name)
    if not roomState.channel then return end
    if roomOwnerName ~= LocalPlayer.Name then return end
    roomBans[name] = true
    roomMembersSet[name] = nil
    removeMsgsFrom(roomState, name)
    addNotice(roomState, name.." تم طرده من الغرفة")
    task.spawn(function()
        pcall(function()
            request({Url=API_URL, Method="POST", Headers=HEADERS,
                Body=HttpService:JSONEncode({username="SYSTEM", message="BAN:"..name, room=roomState.channel})})
        end)
    end)
    showStatus("طردت "..name.." ✓")
    refreshMembersList()
end

-- ── منشن ──

local function checkMention(sender, msg)
    if sender == LocalPlayer.Name then return false end
    if msg:lower():find("@"..LocalPlayer.Name:lower(), 1, true) then
        showStatus(sender.." ذكرك! ⚡")
        playSound(MENTION_SOUND_ID, 0.6, true)
        if not isOpen then flashToggle() end
        return true
    end
    return false
end

-- ── تابز ──

local function updateVisibility()
    roomEmptyLabel.Visible = (activeTab=="room" and roomState.channel==nil)
    btnMembers.Visible     = (activeTab=="room" and roomState.channel~=nil)
end

local function setActiveTab(tab)
    activeTab = tab
    globalState.scroll.Visible = (tab=="global")
    roomState.scroll.Visible   = (tab=="room")
    tabGlobal.BackgroundColor3 = (tab=="global") and ACTIVE_TAB_COLOR or INACTIVE_TAB_COLOR
    tabRoom.BackgroundColor3   = (tab=="room")   and ACTIVE_TAB_COLOR or INACTIVE_TAB_COLOR
    if tab=="global" then
        unreadGlobal = 0; updateBadge(badgeGlobal, badgeGlobalLbl, 0)
    else
        unreadRoom = 0; updateBadge(badgeRoom, badgeRoomLbl, 0)
    end
    updateVisibility()
end

-- ── إرسال ──

local function getChannel()
    return activeTab=="global" and "global" or roomState.channel
end

local function send(text)
    if text=="" then return end
    if tick()-lastSent < 0.8 then return end
    local ch = getChannel()
    if not ch then showStatus("ما انت بغرفة! اضغط + إنشاء أو دخول"); return end
    lastSent = tick()
    text = applyEmojiShortcuts(text:sub(1,200))
    pushBubble(LocalPlayer.Name, text)
    task.spawn(function()
        pcall(function()
            request({Url=API_URL, Method="POST", Headers=HEADERS,
                Body=HttpService:JSONEncode({username=LocalPlayer.Name, message=text, room=ch})})
        end)
    end)
end

local function trySend()
    if box.Text~="" then send(box.Text); box.Text="" end
end

-- ── Popup غرفة ──

local function openPopup(mode)
    popup:SetAttribute("mode", mode)
    popupRoomName.Text=""; popupRoomPass.Text=""; popupStatus.Text=""
    popupTitle.Text    = mode=="create" and "إنشاء غرفة جديدة" or "الانضمام لغرفة"
    popupConfirm.Text  = mode=="create" and "إنشاء" or "دخول"
    popup.Visible = true
end

local function confirmPopup()
    local name = trim(popupRoomName.Text)
    if name=="" then popupStatus.Text="اكتب اسم الغرفة!"; return end
    if #name>30 then popupStatus.Text="الاسم طويل وايد!"; return end
    local pass = popupRoomPass.Text
    local mode = popup:GetAttribute("mode") or "join"
    local ch   = deriveRoomChannel(name, pass)

    roomOwnerName=nil; roomBans={}; roomMembersSet={}; roomMembersOrder={}
    roomState.channel = ch
    roomHasPassword   = (pass~="")
    roomDisplayName   = name
    tabRoom.Text = "غرفة: "..shortenName(name,8)..(roomHasPassword and "*" or "")
    resetFeed(roomState)

    if mode=="create" then
        roomOwnerName = LocalPlayer.Name
        task.spawn(function()
            pcall(function()
                request({Url=API_URL, Method="POST", Headers=HEADERS,
                    Body=HttpService:JSONEncode({username="SYSTEM",
                        message="ROOM_CREATED:"..LocalPlayer.Name, room=ch})})
            end)
        end)
    end
    popup.Visible = false
    setActiveTab("room")
    showStatus(mode=="create" and ("تم إنشاء الغرفة: "..name) or ("انضميت لغرفة: "..name))
end

-- ── handleLocalKicked ──

local function handleLocalKicked()
    showStatus("تم طردك من هذي الغرفة!")
    roomState.channel=nil; roomOwnerName=nil
    roomBans={}; roomMembersSet={}; roomMembersOrder={}
    resetFeed(roomState); tabRoom.Text="غرفة"
    membersPopup.Visible=false
    setActiveTab("global")
end

-- ── استقبال ──

local function handleMsg(v, st, isRoom, bubbles)
    if v.username=="SYSTEM" then
        if isRoom then
            local cn = v.message:match("^ROOM_CREATED:(.+)$")
            if cn then roomOwnerName=cn; addNotice(st, cn.." أنشأ الغرفة 👑") end
            local bn = v.message:match("^BAN:(.+)$")
            if bn then
                roomBans[bn]=true; roomMembersSet[bn]=nil
                removeMsgsFrom(st,bn); addNotice(st, bn.." تم طرده")
                if bn==LocalPlayer.Name then handleLocalKicked() end
            end
        end
        return
    end
    if isRoom and roomBans[v.username] then return end

    -- أرسل رسالة فعلية → نخفي نقاط الكتابة تبعه فوراً
    hideTypingDots(v.username)

    addMessageTo(st, v.username, v.message)
    if isRoom then trackMember(v.username) end

    local isSelf      = (v.username==LocalPlayer.Name)
    local viewingThis = (isRoom and activeTab=="room") or ((not isRoom) and activeTab=="global")

    if not isSelf then
        if not viewingThis then
            if isRoom then
                unreadRoom+=1; updateBadge(badgeRoom, badgeRoomLbl, unreadRoom)
            else
                unreadGlobal+=1; updateBadge(badgeGlobal, badgeGlobalLbl, unreadGlobal)
            end
        end
        local mentioned = checkMention(v.username, v.message)
        if not mentioned then playSound(NOTIFY_SOUND_ID, 0.3) end
        if bubbles and not isDiscord(v.username) then pushBubble(v.username, v.message) end
    end
end

local function startLoop(st, getCh, bubbles, isRoom)
    task.spawn(function()
        local loaded = nil
        while task.wait(POLL_INTERVAL) do
            local ch = getCh()
            if ch then
                if ch~=loaded then
                    loaded=ch; st.lastId=0
                    pcall(function()
                        local res = request({
                            Url=API_URL.."?select=*&order=id.desc&limit=30&room=eq."..ch,
                            Method="GET", Headers=HEADERS
                        })
                        if res and res.Body then
                            local d = HttpService:JSONDecode(res.Body)
                            if type(d)=="table" then
                                for i=#d,1,-1 do
                                    local v=d[i]
                                    if v.id then
                                        if v.id>st.lastId then st.lastId=v.id end
                                        handleMsg(v,st,isRoom,false)
                                    end
                                end
                            end
                        end
                    end)
                else
                    pcall(function()
                        local res = request({
                            Url=API_URL.."?select=*&order=id.asc&limit=50&room=eq."..ch.."&id=gt."..st.lastId,
                            Method="GET", Headers=HEADERS
                        })
                        if res and res.Body then
                            local d = HttpService:JSONDecode(res.Body)
                            if type(d)=="table" then
                                for _,v in ipairs(d) do
                                    if v.id and v.id>st.lastId then
                                        st.lastId=v.id
                                        handleMsg(v,st,isRoom,bubbles)
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

-- ══════════════════════════════════════
--   نظام نقاط "يكتب..." المتحركة فوق الراس
-- ══════════════════════════════════════
-- كيف يشتغل بدون جدول جديد:
--   - اللاعب يكتب → نرسل لـ Supabase رسالة TYPING:اسمه بـ room="__typing__"
--   - كل العملاء يستطلعون __typing__ ويشوفون من يكتب
--   - نعرض بالون نقاط متحركة فوق راس اللاعب لمدة 2.5 ثانية

local typingBillboards  = {}  -- [playerName] = billboardGui
local typingExpiry      = {}  -- [playerName] = expiry tick
local lastTypingSignal  = 0
local lastTypingPollId  = 0

local TYPING_INTERVAL   = 1.2   -- ثانية بين كل إشارة وأخرى
local TYPING_EXPIRE     = 2.5   -- ثانية حتى تختفي النقاط بدون إشارة جديدة

local function hideTypingDots(pname)
    local bb = typingBillboards[pname]
    if bb and bb.Parent then
        local bg = bb:FindFirstChildWhichIsA("Frame")
        if bg then
            TweenService:Create(bg, TweenInfo.new(0.15), {BackgroundTransparency=1}):Play()
            for _,c in ipairs(bg:GetChildren()) do
                if c:IsA("Frame") then
                    TweenService:Create(c, TweenInfo.new(0.15), {BackgroundTransparency=1}):Play()
                end
            end
        end
        task.delay(0.15, function() if bb.Parent then bb:Destroy() end end)
    end
    typingBillboards[pname] = nil
    typingExpiry[pname]     = nil
end

local function showTypingDots(pname)
    -- تحديث وقت الانتهاء
    typingExpiry[pname] = tick() + TYPING_EXPIRE

    -- لو البالون موجود بعد، ما نعيد إنشاءه
    if typingBillboards[pname] and typingBillboards[pname].Parent then return end

    local plr = Players:FindFirstChild(pname)
    if not plr or not plr.Character then return end
    local head = getHead(plr.Character)
    if not head then return end

    local bb = Instance.new("BillboardGui")
    bb.Name        = "TypingDots"
    -- نفس حجم بالون الرسائل بس أصغر، يظهر تحته مباشرة (offset أقل)
    bb.Size        = UDim2.new(0, 66, 0, 34)
    bb.StudsOffset = Vector3.new(0, 1.6, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 60
    bb.Adornee     = head
    bb.Parent      = head
    typingBillboards[pname] = bb

    -- الخلفية البيضاء المدورة
    local bg = Instance.new("Frame", bb)
    bg.AnchorPoint       = Vector2.new(0.5, 1)
    bg.Position          = UDim2.new(0.5, 0, 1, 0)
    bg.Size              = UDim2.new(0, 54, 0, 26)
    bg.BackgroundColor3  = Color3.fromRGB(255, 255, 255)
    bg.BorderSizePixel   = 0
    bg.BackgroundTransparency = 1
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 13)

    -- 3 نقاط داخل الخلفية
    -- عرض 54px - padding 10px يميناً ويساراً = 34px usable
    -- 3 نقاط x 8px + 2 فراغ x 5px = 34px → تبدأ من x=10
    local dotPositions = {10, 23, 36}
    local baseY  = 9   -- top من النقطة (26px tall, 8px dot → center at 13, so 13-4=9)
    local upY    = 3   -- ارتفاع عند الصعود

    local dots = {}
    for i, xPos in ipairs(dotPositions) do
        local dot = Instance.new("Frame", bg)
        dot.Size             = UDim2.new(0, 8, 0, 8)
        dot.Position         = UDim2.new(0, xPos, 0, baseY)
        dot.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
        dot.BorderSizePixel  = 0
        dot.BackgroundTransparency = 1
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
        dots[i] = {frame=dot, xPos=xPos, baseY=baseY, upY=upY}
    end

    -- Fade in
    TweenService:Create(bg, TweenInfo.new(0.15, Enum.EasingStyle.Back), {BackgroundTransparency=0}):Play()
    for _, d in ipairs(dots) do
        TweenService:Create(d.frame, TweenInfo.new(0.15), {BackgroundTransparency=0}):Play()
    end

    -- Animation loop: كل نقطة تتأخر 0.13 ثانية عن السابقة
    for i, d in ipairs(dots) do
        local dot    = d.frame
        local xP     = d.xPos
        local upPos  = UDim2.new(0, xP, 0, d.upY)
        local dnPos  = UDim2.new(0, xP, 0, d.baseY)
        task.spawn(function()
            task.wait((i-1) * 0.13)
            while dot and dot.Parent do
                TweenService:Create(dot, TweenInfo.new(0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position=upPos}):Play()
                task.wait(0.22)
                if not (dot and dot.Parent) then break end
                TweenService:Create(dot, TweenInfo.new(0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.In),  {Position=dnPos}):Play()
                task.wait(0.25)
            end
        end)
    end
end

-- إرسال إشارة "أنا أكتب" لـ Supabase
local function sendTypingSignal()
    local now = tick()
    if now - lastTypingSignal < TYPING_INTERVAL then return end
    lastTypingSignal = now
    local ch = getChannel()
    if not ch then return end
    task.spawn(function()
        pcall(function()
            request({Url=API_URL, Method="POST", Headers=HEADERS,
                Body=HttpService:JSONEncode({
                    username = "TYPING",
                    message  = LocalPlayer.Name..":"..ch,
                    room     = "__typing__"
                })})
        end)
    end)
end

-- حلقة استطلاع نقاط الكتابة
task.spawn(function()
    while task.wait(0.5) do
        -- تنظيف منتهيي الصلاحية
        for pname, expiry in pairs(typingExpiry) do
            if tick() > expiry then hideTypingDots(pname) end
        end
        -- جلب إشارات جديدة
        pcall(function()
            local res = request({
                Url = API_URL.."?select=*&order=id.asc&limit=30&room=eq.__typing__&id=gt."..lastTypingPollId,
                Method="GET", Headers=HEADERS
            })
            if not (res and res.Body) then return end
            local data = HttpService:JSONDecode(res.Body)
            if type(data)~="table" then return end
            for _,v in ipairs(data) do
                if v.id and v.id > lastTypingPollId then
                    lastTypingPollId = v.id
                end
                if v.username=="TYPING" and v.message then
                    local typerName, typerCh = v.message:match("^(.+):(.+)$")
                    -- نعرض النقاط فقط لو نفس القناة المفتوحة، ومو أنا
                    local myChannel = getChannel()
                    if typerName and typerCh
                        and typerName ~= LocalPlayer.Name
                        and typerCh == myChannel then
                        showTypingDots(typerName)
                    end
                end
            end
        end)
    end
end)

-- ══════════════════════════════════════
--   Phase 3 — ربط الأحداث
-- ══════════════════════════════════════

box.FocusLost:Connect(function(enter) if enter then trySend() end end)
sendBtn.MouseButton1Click:Connect(trySend)

-- كشف الكتابة → إرسال إشارة
box:GetPropertyChangedSignal("Text"):Connect(function()
    if box.Text ~= "" then sendTypingSignal() end
end)

-- لما نرسل رسالة، نخفي نقاطنا عند الآخرين (هم يشوفون إشارة جديدة)
-- ونخفي نقاط الكاتبين اللي أرسلوا فعلاً (تتعامل معها handleMsg)
pressFeedback(sendBtn, DISCORD_COLOR)
pressFeedback(btnCreate, Color3.fromRGB(50,160,90))
pressFeedback(btnJoin,   Color3.fromRGB(160,130,50))

tabGlobal.MouseButton1Click:Connect(function() setActiveTab("global") end)
tabRoom.MouseButton1Click:Connect(function() setActiveTab("room") end)
btnCreate.MouseButton1Click:Connect(function() openPopup("create") end)
btnJoin.MouseButton1Click:Connect(function() openPopup("join") end)
popupConfirm.MouseButton1Click:Connect(confirmPopup)
popupCancel.MouseButton1Click:Connect(function() popup.Visible=false end)
popupRoomName.FocusLost:Connect(function(e) if e then confirmPopup() end end)
popupRoomPass.FocusLost:Connect(function(e) if e then confirmPopup() end end)
btnMembers.MouseButton1Click:Connect(function() refreshMembersList(); membersPopup.Visible=true end)
membersCloseBtn.MouseButton1Click:Connect(function() membersPopup.Visible=false end)

toggleBtn.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    if isOpen then
        -- أول مرة يفتحون الشات: يبيّن رابط الديسكورد
        if firstOpen then
            firstOpen = false
            task.delay(0.3, function()
                showStatus("Discord: discord.gg/CXzNPpdFh2 (copied!) 💬")
            end)
        end
        frame.Visible = true
        frame.Size    = UDim2.new(0,0,0,0)
        frame.BackgroundTransparency = 1
        TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Back),
            {Size=CHAT_SIZE, BackgroundTransparency=0.15}):Play()
        toggleBtn.Text             = "X"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(180,60,60)
    else
        TweenService:Create(frame, TweenInfo.new(0.15),
            {Size=UDim2.new(0,0,0,0), BackgroundTransparency=1}):Play()
        toggleBtn.Text             = "C"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
        task.delay(0.15, function() if not isOpen then frame.Visible=false end end)
    end
end)

startLoop(globalState, function() return "global" end,         true, false)
startLoop(roomState,   function() return roomState.channel end, true, true)

local function setupPlayer(plr)
    plr.CharacterAdded:Connect(function() playerBubbles[plr.Name]=nil end)
end
for _,p in ipairs(Players:GetPlayers()) do setupPlayer(p) end
Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(plr)
    local d = playerBubbles[plr.Name]
    if d and d.billboard and d.billboard.Parent then d.billboard:Destroy() end
    playerBubbles[plr.Name]=nil
    userColors[plr.Name]=nil
end)

updateVisibility()

-- ══════════════════════════════════════
--   نسخ الديسكورد للحافظة فوراً عند التشغيل
-- ══════════════════════════════════════

task.defer(function()
    pcall(function()
        if setclipboard then setclipboard(DISCORD_LINK) end
    end)
end)

print("╔══════════════════════════════════════╗")
print("║    Pro Chat v15 - LEGENDARY FINAL    ║")
print("║  + Typing dots  + Toggle fix         ║")
print("║  Discord: discord.gg/CXzNPpdFh2     ║")
print("╚══════════════════════════════════════╝")
