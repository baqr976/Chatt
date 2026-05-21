-- 🚀 Pro Chat v13 - Ultimate Light Speed Edition

-- [الخدمات]
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer

-- [الإعدادات]
-- ⚠️ استبدل بـ OPEN URL KEY خاص بك الجديد والأمن
local PROJECT_URL = "https://fzkxotptuhmhkuhnsoav.supabase.co" 
local ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." -- 🔒 تأكد تضع المفتاح الصحيح هنا

-- دالة طلب آمنة للـ Exploiters
local request = http_request or request or (syn and syn.request) or (fluxus and fluxus.request)
if not request then warn("❌ Executor Not Supported") return end

-- [تهيئة الشات]
if CoreGui:FindFirstChild("ProChat") then CoreGui.ProChat:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "ProChat"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = CoreGui
gui.DisplayOrder = 9999 -- يظهر فوق كل شي

-- زر الفتح / الإغلاق
local toggleBtn = Instance.new("TextButton", gui)
toggleBtn.Size = UDim2.new(0, 40, 0, 40)
toggleBtn.Position = UDim2.new(0, 5, 0, 5)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
toggleBtn.BackgroundTransparency = 0
toggleBtn.Text = ""
toggleBtn.TextSize = 0 -- مخفي
toggleBtn.AutoButtonColor = false
toggleBtn.BorderSizePixel = 0
toggleBtn.ZIndex = 100
toggleBtn.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then toggleFunc() end end)

-- خلفية الزر
local btnBg = Instance.new("ImageLabel", toggleBtn)
btnBg.Size = UDim2.new(1,0,1,0)
btnBg.Image = "rbxassetid://10953422709" -- أيقونة شات بسيطة
btnBg.BackgroundTransparency = 1
btnBg.Visible = true
btnBg.LayoutOrder = 0

-- إطار الشات
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 350, 0, 500)
frame.Position = UDim2.new(0.5, -175, 0.5, -250)
frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
frame.BackgroundTransparency = 0
frame.BorderSizePixel = 0
frame.Visible = false
frame.ClipsDescendants = true -- يحفظ الأداء

local uiCorner = Instance.new("UICorner", frame)
uiCorner.CornerRadius = UDim.new(0, 12)

-- العنوان
local header = Instance.new("Frame", frame)
header.Size = UDim2.new(1, 0, 0, 32)
header.Position = UDim2.new(0, 0, 0, 0)
header.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
header.BorderSizePixel = 0
header.BackgroundTransparency = 0

local titleLabel = Instance.new("TextLabel", header)
titleLabel.Size = UDim2.new(1, -8, 1, 0)
titleLabel.Position = UDim2.new(0, 4, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "🔹 Pro Chat Ultimate"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

-- شريط التمرير
local messages = Instance.new("ScrollingFrame", frame)
messages.Size = UDim2.new(1, -12, 1, -70) -- مساحة أقل من الباقي
messages.Position = UDim2.new(0, 6, 0, 36)
messages.CanvasSize = UDim2.new(0, 0, 0, 0)
messages.ScrollBarThickness = 6
messages.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 60)
messages.BackgroundTransparency = 1
messages.AutomaticCanvasSize = Enum.AutomaticSize.Y

local layout = Instance.new("UIListLayout", messages)
layout.Padding = UDim.new(0, 4)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local padding = Instance.new("UIPadding", messages)
padding.PaddingBottom = UDim.new(0, 5)

-- صندوق الكتابة
local inputContainer = Instance.new("Frame", frame)
inputContainer.Size = UDim2.new(1, 0, 0, 42)
inputContainer.Position = UDim2.new(0, 0, 1, -42)
inputContainer.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
inputContainer.BorderSizePixel = 0

local inputBox = Instance.new("TextBox", inputContainer)
inputBox.Size = UDim2.new(1, -12, 1, 0)
inputBox.Position = UDim2.new(0, 6, 0, 6)
inputBox.BackgroundTransparency = 1
inputBox.PlaceholderText = "اكتب رسالة هنا..."
inputBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
inputBox.Font = Enum.Font.GothamMedium
inputBox.TextSize = 13
inputBox.ClearTextOnFocus = true
inputBox.PlaceholderText = "اكتب رسالة..."

-- نظام الألوان للاعبين
local userColors = {}
local defaultPalette = {
	Color3.fromRGB(0, 150, 255), Color3.fromRGB(255, 100, 150), Color3.fromRGB(255, 215, 0),
	Color3.fromRGB(0, 255, 128), Color3.fromRGB(150, 0, 255), Color3.fromRGB(255, 80, 0),
}
local DISCORD_COLOR = Color3.fromRGB(88, 101, 242)

local function getPlayerColor(name)
	if name:sub(1, 3) == "DC:" then return DISCORD_COLOR end
	if not userColors[name] then
		userColors[name] = defaultPalette[(name:len() % #defaultPalette) + 1]
	end
	return userColors[name]
end

local function colorToHex(c)
	return string.format("#%02X%02X%02X", math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255))
end

-- 🚀 إضافة الرسالة (محسن وسريع)
local displayedIds = {}
local maxMessages = 100 -- حد أقصى للشات عشان الخفة

local function addMessage(user, msg, id)
	if displayedIds[id] then return end
	displayedIds[id] = true
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 0)
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.BackgroundTransparency = 1
	label.TextTransparency = 1
	label.TextWrapped = true
	label.RichText = true -- دعم كامل للإيموجيات والستايل
	label.TextColor3 = Color3.fromRGB(230, 230, 230)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 13
	
	-- تنسيق الاسم حسب المصدر
	local displayName, colorName, textColor
	if user:sub(1, 3) == "DC:" then
		displayName = user:sub(4)
		textColor = "#FFFFFF" -- نص أبيض للديسكورد
	else
		displayName = user
		textColor = colorToHex(getPlayerColor(user))
	end
	
	-- وضع الاسم
	local nameTag = "<b><font color='" .. textColor .. "'>" .. displayName .. "</font></b>: "
	
	-- إنشاء النص الكامل (يفضل قص الطول إذا كان كبير جداً عشان الأداء)
	local fullText = nameTag .. tostring(msg)
	if #fullText > 2000 then fullText = fullText:sub(1, 2000) .. "..." end -- حماية ضد الـ Spam الثقيل
	
	label.Text = fullText
	label.Parent = messages
	
	TweenService:Create(label, TweenInfo.new(0.15), {TextTransparency = 0}):Play()
	
	-- نزلق للأسفل دائماً
	messages.CanvasPosition = Vector2.new(0, messages.AbsoluteCanvasSize.Y)
	
	-- تنظيف قديم من الـ GUI لو زاد عن الحد (Memory Leak Fix)
	if #messages:GetChildren() > maxMessages then
		for i = 1, #messages:GetChildren() do
			local child = messages:GetChildren()[i]
			if child:IsA("TextLabel") then
				child:Destroy()
				break
			end
		end
	end
end

-- 🕸️ فقاعات الرؤوس (Smart System)
local playerAttachments = {}
local playerBillboards = {}

local function setupBillboard(player)
	if not player.Character then return end
	
	local head = player.Character:FindFirstChildWhichIsA("BasePart"):FindFirstChild("Head")
	if not head then head = player.Character:FindFirstChild("Head") end
	if not head then return end
	
	local bb = playerBillboards[player.UserId]
	if not bb then
		-- إنشاء Attachment
		local att = head:FindFirstChild("ChatAtt")
		if not att then
			att = Instance.new("Attachment")
			att.Name = "ChatAtt"
			att.Position = Vector3.new(0, head.Size.Y, 0)
			att.Parent = head
		end
		
		-- إنشاء Billboard
		local board = Instance.new("BillboardGui")
		board.Adornee = att
	.board.MaxDistance = 20
	.board.AlwaysOnTop = true
	.board.StudsOffset = Vector3.new(0, 1.2, 0)
	.board.Size = UDim2.new(0, 250, 0, 100)
	.board.Parent = head
		board:ClearAllChildren()
		
		-- حاوية داخلية
		local container = Instance.new("Frame", board)
		container.BackgroundTransparency = 1
		container.Size = UDim2.new(1, 0, 1, 0)
		local list = Instance.new("UIListLayout", container)
		list.SortOrder = Enum.SortOrder.Name
		
		playerAttachments[head] = att
		playerBillboards[player.UserId] = board
	end
end

-- إنشاء الفقاعة نفسها
local function createAboveHead(att, text, isDiscord)
	if not att then return end
	local parent = att:GetParents()[1]
	if not parent then return end
	
	-- البحث عن الحاوية الموجودة مسبقاً لتجنب التكرار
	local container = parent:FindFirstChildWhichIsA("BillboardGui") and 
		parent:FindFirstChild("BillboardGui"):FindFirstChild("Container")
	
	-- إذا ماتشكّل شيء، نستخدم الطريقة السريعة
	if not container then return end
	
	local bubble = Instance.new("Frame")
	bubble.Parent = container
	bubble.Size = UDim2.new(0, 0, 0, 0)
	bubble.AutomaticSize = Enum.AutomaticSize.XY
	bubble.BackgroundTransparency = 1
	bubble.BorderSizePixel = 0
	bubble.BackgroundColor3 = isDiscord and DISCORD_COLOR or Color3.fromRGB(255,255,255)
	Instance.new("UICorner", bubble).CornerRadius = UDim.new(0, 8)
	
	local txt = Instance.new("TextLabel", bubble)
	txt.BackgroundTransparency = 1
	txt.Text = isDiscord and "💜 "..text or text
(txt.TextColor3 = isDiscord and Color3.fromRGB(255,255,255) else Color3.fromRGB(15,15,15)
txt.Font = Enum.Font.GothamMedium
txt.TextSize = 12
txt.TextWrapped = true
txt.RichText = true
txt.TextXAlignment = Enum.TextXAlignment.Center
	
	-- أنيميشن دخول سريع جداً
	TweenService:Create(bubble, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0.2}):Play()
	TweenService:Create(txt, TweenInfo.new(0.1), {TextTransparency = 0}):Play()
	
	task.delay(4, function()
		TweenService:Create(bubble, TweenInfo.new(0.1), {BackgroundTransparency = 1}):Play()
		TweenService:Create(txt, TweenInfo.new(0.1), {TextTransparency = 1}):Play()
		task.delay(0.15, function() bubble:Destroy() end)
	end)
end

-- منطق إرسال واستقبال
local lastSentTick = tick()

local function sendMsg(text)
	local currentTick = tick()
	if currentTick - lastSentTick < 1 then return end -- كولداون ثانية
	lastSentTick = currentTick
	
	local finalText = text
	if #finalText > 200 then finalText = finalText:sub(1, 200) end
	
	-- إرسال للسيرفر
	if request then
		pcall(request, {
			Url = PROJECT_URL .. "/rest/v1/chat_messages",
			Method = "POST",
			Headers = { ["apikey"] = ANON_KEY, Authorization = "Bearer " .. ANON_KEY },
			Body = HttpService:JSONEncode({ username = LocalPlayer.Name, message = finalText })
		})
	end
end

-- جلب البيانات (Polling خفيف)
task.spawn(function()
	while task.wait(0.5) do -- سويت 0.5 بدل 0.3 للتوفير
		pcall(function()
			local res = request({ Url = PROJECT_URL .. "/rest/v1/chat_messages?select=*&order=id.asc&limit=10", Method = "GET", Headers = { ["apikey"] = ANON_KEY } })
			if res.Body then
				local data = HttpService:JSONDecode(res.Body)
				if type(data) == "table" then
					for _, v in ipairs(data) do
						addMessage(v.username, v.message, v.id)
						
						-- منطق الفقاعة الذكي
						local isDiscord = v.username:sub(1, 3) == "DC:"
						local isSelf = v.username == LocalPlayer.Name
						local isTarget = Players:FindFirstChild(v.username)
						
						-- الفقاعة فقط لو ليست لنفسك وليست من الديسكورد وليس موجود فيها اللاعب
						-- ملاحظة: الفقاعة بتطلع فوق رأس اللاعب المتلقي، لكن هنا نحن نعرض الكل.
						-- الحل الأفضل: لو الشخص اللي كتب موجود عندنا (معنا نفس الخريطة)
						if not isDiscord and not isSelf and isTarget then
							setupBillboard(isTarget)
							-- البحث عن attachment الموجود ليعرض فوقه
							local char = isTarget.Character
							if char then
								local head = char:FindFirstChild("Head")
								local att = head and head:FindFirstChild("ChatAtt")
								if att then createAboveHead(att, v.message, false) end
							end
						end
					end
				end
			end
		end)
	end
end)

-- التحكم بالزر
local isOpen = false
function toggleFunc()
	isOpen = not isOpen
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Back)
	
	if isOpen then
		frame.Visible = true
		frame.Size = UDim2.new(0, 350, 0, 500)
		toggleBtn.Visible = false -- إخفاء الزر ليعمل Input Box كإضافة
		inputBox:CaptureFocus()
	else
		TweenService:Create(frame, tweenInfo, {Size = UDim2.new(0, 350, 0, 0)}):Play()
		task.wait(0.2)
		frame.Visible = false
		toggleBtn.Visible = true
	end
end

-- ربط الأحداث
inputBox.FocusLost:Connect(function(en)
	if en and inputBox.Text ~= "" then
		sendMsg(inputBox.Text)
		inputBox.Text = ""
	end
end)

-- تشغيل
print("✅ Pro Chat v13 Ultimate Loaded - Ready!")
