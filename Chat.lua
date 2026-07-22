-- Pro Chat v14 - Rooms + Global Chat + Legendary Bubble System
-- ملاحظة مهمة: لازم تضيف عمود اسمه "room" (نوع text) لجدول chat_messages
-- بالـ Supabase حتى يشتغل فلتر الروم/العام (ALTER TABLE chat_messages ADD COLUMN room text;)
-- ما لمسنا API_URL / API_KEY / HEADERS ولا أي شي تبع التخزين، خلّيناها كما هي.

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local API_URL = "https://qjswawxiqyrcpxonsclp.supabase.co/rest/v1/chat_messages""
local API_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFqc3dhd3hpcXlyY3B4b25zY2xwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ3NDU5NDYsImV4cCI6MjEwMDMyMTk0Nn0.vvp5z-t-ZHMRt9y9VaYK0XCekbUmHqo7dwL5pUlFatk"
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

local MAX_MESSAGES = 150          -- سقف الرسائل بكل فيد (عام/روم) يمنع تراكم العناصر
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
local activeTab = "global"

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

local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(60, 60, 60)
stroke.Thickness = 1

-- ── الهيدر (تابز + أزرار الروم) ──
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
Instance.new("UICorner", tabGlobal).CornerRadius = UDim.new(0, 6)

local tabRoom = Instance.new("TextButton", header)
tabRoom.Size = UDim2.new(0.32, -2, 1, 0)
tabRoom.Position = UDim2.new(0.32, 2, 0, 0)
tabRoom.BackgroundColor3 = INACTIVE_TAB_COLOR
tabRoom.Text = "غرفة"
tabRoom.TextSize = 12
tabRoom.Font = Enum.Font.GothamBold
tabRoom.TextColor3 = Color3.new(1, 1, 1)
tabRoom.BorderSizePixel = 0
tabRoom.ClipsDescendants = true
Instance.new("UICorner", tabRoom).CornerRadius = UDim.new(0, 6)

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

-- ── حاوية الفيدات (عام/روم) ──
local feedHolder = Instance.new("Frame", frame)
feedHolder.Size = UDim2.new(1, -12, 1, -70)
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

    -- سكرول تلقائي للأسفل فقط إذا المستخدم كان عند الأسفل أصلاً (ما يسحبه وهو قاري تاريخ قديم)
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

local roomDisplayName = nil
local roomHasPassword = false

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
                    room = channel
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
--         تابز عام/روم + Popup إنشاء/دخول
-- ══════════════════════════════════════

local function updateRoomEmptyVisibility()
    roomEmptyLabel.Visible = (activeTab == "room" and roomState.channel == nil)
end

local function setActiveTab(tab)
    activeTab = tab
    globalState.scroll.Visible = (tab == "global")
    roomState.scroll.Visible = (tab == "room")
    tabGlobal.BackgroundColor3 = (tab == "global") and ACTIVE_TAB_COLOR or INACTIVE_TAB_COLOR
    tabRoom.BackgroundColor3 = (tab == "room") and ACTIVE_TAB_COLOR or INACTIVE_TAB_COLOR
    updateRoomEmptyVisibility()
end

tabGlobal.MouseButton1Click:Connect(function() setActiveTab("global") end)
tabRoom.MouseButton1Click:Connect(function()
    if not roomState.channel then
        -- popup يتفتح تحت (متعرف بعدين)، نستخدم متغير مرجعي
    end
    setActiveTab("room")
end)

-- ── Popup إنشاء/انضمام ──
local popup = Instance.new("Frame", frame)
popup.Size = UDim2.new(1, 0, 1, 0)
popup.Position = UDim2.new(0, 0, 0, 0)
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
local popupStroke = Instance.new("UIStroke", popupCard)
popupStroke.Color = Color3.fromRGB(70, 70, 70)

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

local function makePopupInput(yPos, placeholder)
    local b = Instance.new("TextBox", popupCard)
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
    local p = Instance.new("UIPadding", b)
    p.PaddingLeft = UDim.new(0, 8)
    return b
end

local popupRoomName = makePopupInput(38, "اسم الغرفة")
local popupRoomPass = makePopupInput(74, "كلمة السر (اختياري)")

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

local pendingMode = "create"

local function openPopup(mode)
    pendingMode = mode
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

    roomState.channel = channel
    roomHasPassword = (pass ~= "")
    roomDisplayName = name

    tabRoom.Text = "غرفة: " .. shortenName(name, 8) .. (roomHasPassword and "*" or "")

    resetFeed(roomState)
    popup.Visible = false
    setActiveTab("room")
    showStatus(pendingMode == "create" and ("تم إنشاء/دخول غرفة: " .. name) or ("انضميت لغرفة: " .. name))
end

popupConfirm.MouseButton1Click:Connect(confirmPopup)
popupCancel.MouseButton1Click:Connect(function() popup.Visible = false end)
popupRoomName.FocusLost:Connect(function(enter) if enter then confirmPopup() end end)
popupRoomPass.FocusLost:Connect(function(enter) if enter then confirmPopup() end end)

btnCreate.MouseButton1Click:Connect(function() openPopup("create") end)
btnJoin.MouseButton1Click:Connect(function() openPopup("join") end)

-- ══════════════════════════════════════
--   استقبال الرسائل (لوب عام واحد يخدم أي فيد)
-- ══════════════════════════════════════
-- لكل فيد: أول مرة (أو أول مرة بعد تبديل روم) نجيب آخر 30 رسالة كتاريخ،
-- وبعدها نسحب فقط id أكبر من آخر id شفناه (ما نرجع نجيب نفس الرسائل القديمة للأبد).

local function startChannelLoop(state, getChannel, allowBubbles)
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
                            Method = "GET",
                            Headers = HEADERS
                        })
                        if res and res.Body then
                            local data = HttpService:JSONDecode(res.Body)
                            if type(data) == "table" then
                                for i = #data, 1, -1 do
                                    local v = data[i]
                                    if v.id then
                                        addMessageTo(state, v.username, v.message)
                                        if v.id > state.lastId then state.lastId = v.id end
                                    end
                                end
                            end
                        end
                    end)
                else
                    pcall(function()
                        local res = request({
                            Url = API_URL .. "?select=*&order=id.asc&limit=50&room=eq." .. channel .. "&id=gt." .. state.lastId,
                            Method = "GET",
                            Headers = HEADERS
                        })
                        if res and res.Body then
                            local data = HttpService:JSONDecode(res.Body)
                            if type(data) == "table" then
                                for _, v in ipairs(data) do
                                    if v.id and v.id > state.lastId then
                                        state.lastId = v.id
                                        addMessageTo(state, v.username, v.message)
                                        if allowBubbles and not isDiscord(v.username) and v.username ~= LocalPlayer.Name then
                                            pushBubble(v.username, v.message)
                                        end
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

startChannelLoop(globalState, function() return "global" end, true)
startChannelLoop(roomState, function() return roomState.channel end, true)

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

updateRoomEmptyVisibility()
print("Pro Chat v14 Loaded")
