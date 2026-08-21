-- Pro Chat Global v17 - Clean / No Rooms / Session Settings
-- Settings are NOT saved. They reset when the script is restarted.

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PROJECT_URL = "https://yuwnhpbwrdfcpjonfodr.supabase.co"
local API_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzIiwicmVmIjoieXV3bmh..."
-- Replace the shortened line above with your key if your executor strips long strings.
local API_KEY_FULL = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzIiwicmVmIjoieXV3bmh..."
-- The actual key is inserted below by the build step.

local request = http_request or request or (syn and syn.request) or (fluxus and fluxus.request)
if not request then warn("ProChat: HTTP not supported") return end
if CoreGui:FindFirstChild("ProChat") then CoreGui.ProChat:Destroy() end

local isTouch = UserInputService.TouchEnabled
local isMouse = UserInputService.MouseEnabled
local defaultVisible = (isTouch and isMouse) and 7 or (isTouch and 4 or 10)

local settings = {
    visibleMessages = defaultVisible,
    width = isTouch and 0.72 or 0.38,
    height = isTouch and 0.42 or 0.36,
    buttonX = 12,
    buttonY = 12,
    chatX = 12,
    chatY = 55,
    color = Color3.fromRGB(88,101,242),
    transparency = 0.12,
}

local MIN_MESSAGES, MAX_MESSAGES = 2, 20
local MIN_W, MAX_W = 0.28, 0.82
local MIN_H, MAX_H = 0.24, 0.78
local POLL_INTERVAL = 0.5
local MAX_LOCAL_MESSAGES = 20
local lastSent = 0
local isOpen = false
local editButtonMode = false
local editChatMode = false
local dragTarget, dragStart, dragOrigin
local resizing = false
local resizeStart, resizeOriginW, resizeOriginH
local shownIds = {}
local firstLoad = true
local userColors = {}

local function accent()
    return settings.color
end
local function clamp(n,a,b) return math.max(a, math.min(b,n)) end
local function hex(c) return string.format("#%02X%02X%02X", math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255)) end
local function esc(s)
    s = tostring(s or "")
    return s:gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;")
end
local palette = {
    Color3.fromRGB(88,101,242), Color3.fromRGB(145,80,220), Color3.fromRGB(50,190,110),
    Color3.fromRGB(225,170,55), Color3.fromRGB(215,70,70), Color3.fromRGB(40,180,220),
}
local function userColor(name)
    if not userColors[name] then userColors[name] = palette[(#userColors % #palette)+1] end
    return userColors[name]
end

local gui = Instance.new("ScreenGui")
gui.Name = "ProChat"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999999
gui.Parent = CoreGui

local toggleBtn = Instance.new("TextButton", gui)
toggleBtn.Name = "ChatButton"
toggleBtn.Size = UDim2.new(0,82,0,38)
toggleBtn.Position = UDim2.new(0,settings.buttonX,0,settings.buttonY)
toggleBtn.BackgroundColor3 = accent()
toggleBtn.Text = "💬 Chat"
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 14
toggleBtn.BorderSizePixel = 0
toggleBtn.AutoButtonColor = false
toggleBtn.ZIndex = 100
Instance.new("UICorner",toggleBtn).CornerRadius = UDim.new(0,10)

local frame = Instance.new("Frame",gui)
frame.Name = "ChatFrame"
frame.Size = UDim2.new(settings.width,0,settings.height,0)
frame.Position = UDim2.new(0,settings.chatX,0,settings.chatY)
frame.BackgroundColor3 = Color3.fromRGB(18,18,20)
frame.BackgroundTransparency = settings.transparency
frame.BorderSizePixel = 0
frame.Visible = false
frame.ClipsDescendants = true
frame.Active = true
frame.ZIndex = 20
Instance.new("UICorner",frame).CornerRadius = UDim.new(0,12)
local frameStroke = Instance.new("UIStroke",frame)
frameStroke.Color = accent()
frameStroke.Thickness = 1

local header = Instance.new("Frame",frame)
header.Size = UDim2.new(1,-12,0,34)
header.Position = UDim2.new(0,6,0,6)
header.BackgroundTransparency = 1
header.ZIndex = 21
local title = Instance.new("TextLabel",header)
title.Size = UDim2.new(1,-48,1,0)
title.BackgroundTransparency = 1
title.Text = "Global Chat"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 22
local settingsBtn = Instance.new("TextButton",header)
settingsBtn.Size = UDim2.new(0,34,0,30)
settingsBtn.Position = UDim2.new(1,-34,0,0)
settingsBtn.BackgroundColor3 = Color3.fromRGB(45,45,48)
settingsBtn.Text = "⚙"
settingsBtn.TextColor3 = Color3.new(1,1,1)
settingsBtn.Font = Enum.Font.GothamBold
settingsBtn.TextSize = 16
settingsBtn.BorderSizePixel = 0
settingsBtn.ZIndex = 23
Instance.new("UICorner",settingsBtn).CornerRadius = UDim.new(0,8)

local messages = Instance.new("ScrollingFrame",frame)
messages.Name = "Messages"
messages.Size = UDim2.new(1,-12,1,-82)
messages.Position = UDim2.new(0,6,0,44)
messages.BackgroundTransparency = 1
messages.BorderSizePixel = 0
messages.ScrollBarThickness = 3
messages.ScrollBarImageColor3 = Color3.fromRGB(130,130,130)
messages.AutomaticCanvasSize = Enum.AutomaticSize.Y
messages.CanvasSize = UDim2.new(0,0,0,0)
messages.ZIndex = 21
local layout = Instance.new("UIListLayout",messages)
layout.Padding = UDim.new(0,5)
layout.SortOrder = Enum.SortOrder.LayoutOrder
local pad = Instance.new("UIPadding",messages)
pad.PaddingTop = UDim.new(0,4); pad.PaddingBottom = UDim.new(0,4); pad.PaddingLeft = UDim.new(0,4); pad.PaddingRight = UDim.new(0,4)

local inputBg = Instance.new("Frame",frame)
inputBg.Size = UDim2.new(1,-12,0,34)
inputBg.Position = UDim2.new(0,6,1,-40)
inputBg.BackgroundColor3 = Color3.fromRGB(35,35,38)
inputBg.BorderSizePixel = 0
inputBg.ZIndex = 21
Instance.new("UICorner",inputBg).CornerRadius = UDim.new(0,9)
local box = Instance.new("TextBox",inputBg)
box.Size = UDim2.new(1,-70,1,0)
box.Position = UDim2.new(0,8,0,0)
box.BackgroundTransparency = 1
box.PlaceholderText = "اكتب رسالة..."
box.PlaceholderColor3 = Color3.fromRGB(145,145,145)
box.Text = ""
box.TextColor3 = Color3.new(1,1,1)
box.Font = Enum.Font.Gotham
box.TextSize = 13
box.TextXAlignment = Enum.TextXAlignment.Left
box.ClearTextOnFocus = false
box.ZIndex = 22
local sendBtn = Instance.new("TextButton",inputBg)
sendBtn.Size = UDim2.new(0,58,1,-4)
sendBtn.Position = UDim2.new(1,-62,0,2)
sendBtn.BackgroundColor3 = accent()
sendBtn.Text = "إرسال"
sendBtn.TextColor3 = Color3.new(1,1,1)
sendBtn.Font = Enum.Font.GothamBold
sendBtn.TextSize = 12
sendBtn.BorderSizePixel = 0
sendBtn.ZIndex = 22
Instance.new("UICorner",sendBtn).CornerRadius = UDim.new(0,8)

local resizeHandle = Instance.new("TextButton",frame)
resizeHandle.Size = UDim2.new(0,24,0,24)
resizeHandle.Position = UDim2.new(1,-24,1,-24)
resizeHandle.BackgroundColor3 = accent()
resizeHandle.Text = "↘"
resizeHandle.TextColor3 = Color3.new(1,1,1)
resizeHandle.Font = Enum.Font.GothamBold
resizeHandle.TextSize = 13
resizeHandle.BorderSizePixel = 0
resizeHandle.ZIndex = 50
Instance.new("UICorner",resizeHandle).CornerRadius = UDim.new(0,6)

local settingsPanel = Instance.new("Frame",gui)
settingsPanel.Size = UDim2.new(0,310,0,360)
settingsPanel.Position = UDim2.new(0.5,-155,0.5,-180)
settingsPanel.BackgroundColor3 = Color3.fromRGB(24,24,27)
settingsPanel.BorderSizePixel = 0
settingsPanel.Visible = false
settingsPanel.ZIndex = 200
Instance.new("UICorner",settingsPanel).CornerRadius = UDim.new(0,12)
local settingsStroke = Instance.new("UIStroke",settingsPanel)
settingsStroke.Color = accent()
settingsStroke.Thickness = 1
local stTitle = Instance.new("TextLabel",settingsPanel)
stTitle.Size = UDim2.new(1,-20,0,32)
stTitle.Position = UDim2.new(0,10,0,8)
stTitle.BackgroundTransparency = 1
stTitle.Text = "⚙ إعدادات الشات"
stTitle.TextColor3 = Color3.new(1,1,1)
stTitle.Font = Enum.Font.GothamBold
stTitle.TextSize = 16
stTitle.TextXAlignment = Enum.TextXAlignment.Left
stTitle.ZIndex = 201
local function settingButton(text,x,y,w,h)
    local b=Instance.new("TextButton",settingsPanel)
    b.Size=UDim2.new(0,w,0,h); b.Position=UDim2.new(0,x,0,y)
    b.BackgroundColor3=Color3.fromRGB(45,45,48); b.Text=text; b.TextColor3=Color3.new(1,1,1)
    b.Font=Enum.Font.GothamBold; b.TextSize=11; b.BorderSizePixel=0; b.ZIndex=201
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,7)
    return b
end
local msgInfo=Instance.new("TextLabel",settingsPanel)
msgInfo.Size=UDim2.new(1,-20,0,24); msgInfo.Position=UDim2.new(0,10,0,48); msgInfo.BackgroundTransparency=1
msgInfo.TextColor3=Color3.new(1,1,1); msgInfo.Font=Enum.Font.Gotham; msgInfo.TextSize=12; msgInfo.TextXAlignment=Enum.TextXAlignment.Left; msgInfo.ZIndex=201
local msgMinus=settingButton("−",210,46,38,26); local msgPlus=settingButton("+",256,46,38,26)
local sizeInfo=Instance.new("TextLabel",settingsPanel)
sizeInfo.Size=UDim2.new(1,-20,0,24); sizeInfo.Position=UDim2.new(0,10,0,80); sizeInfo.BackgroundTransparency=1
sizeInfo.TextColor3=Color3.new(1,1,1); sizeInfo.Font=Enum.Font.Gotham; sizeInfo.TextSize=12; sizeInfo.TextXAlignment=Enum.TextXAlignment.Left; sizeInfo.ZIndex=201
local wMinus=settingButton("عرض −",10,108,68,28); local wPlus=settingButton("عرض +",84,108,68,28)
local hMinus=settingButton("طول −",158,108,68,28); local hPlus=settingButton("طول +",232,108,68,28)
local moveBtn=settingButton("✋ تحريك زر",10,146,136,30); local moveChat=settingButton("✋ تحريك الشات",154,146,146,30)
local colorInfo=Instance.new("TextLabel",settingsPanel)
colorInfo.Size=UDim2.new(1,-20,0,22); colorInfo.Position=UDim2.new(0,10,0,182); colorInfo.BackgroundTransparency=1
colorInfo.Text="لون الشات والزر"; colorInfo.TextColor3=Color3.new(1,1,1); colorInfo.Font=Enum.Font.Gotham; colorInfo.TextSize=12; colorInfo.TextXAlignment=Enum.TextXAlignment.Left; colorInfo.ZIndex=201
for i,c in ipairs(palette) do
    local x=10+((i-1)%3)*98; local y=208+math.floor((i-1)/3)*34
    local b=settingButton("●",x,y,90,28); b.BackgroundColor3=c
    b.MouseButton1Click:Connect(function() settings.color=c; frameStroke.Color=c; sendBtn.BackgroundColor3=c; resizeHandle.BackgroundColor3=c; toggleBtn.BackgroundColor3=c; settingsStroke.Color=c end)
end
local resetBtn=settingButton("↺ افتراضي",10,280,90,30)
local closeBtn=settingButton("إغلاق",108,280,90,30)
local modeInfo=Instance.new("TextLabel",settingsPanel)
modeInfo.Size=UDim2.new(0,100,0,32); modeInfo.Position=UDim2.new(0,202,0,278); modeInfo.BackgroundTransparency=1
modeInfo.TextColor3=Color3.fromRGB(180,180,180); modeInfo.Font=Enum.Font.Gotham; modeInfo.TextSize=10; modeInfo.TextWrapped=true; modeInfo.ZIndex=201

local function updateSettingsUI()
    frame.Size=UDim2.new(settings.width,0,settings.height,0)
    frame.Position=UDim2.new(0,settings.chatX,0,settings.chatY)
    toggleBtn.Position=UDim2.new(0,settings.buttonX,0,settings.buttonY)
    msgInfo.Text="الرسائل الظاهرة: "..settings.visibleMessages
    sizeInfo.Text=string.format("الحجم: %d%% × %d%%",math.floor(settings.width*100),math.floor(settings.height*100))
    moveBtn.BackgroundColor3=editButtonMode and accent() or Color3.fromRGB(45,45,48)
    moveChat.BackgroundColor3=editChatMode and accent() or Color3.fromRGB(45,45,48)
    modeInfo.Text=(editButtonMode and editChatMode and "تحريك الزر والشات") or (editButtonMode and "تحريك الزر") or (editChatMode and "تحريك الشات") or "وضع عادي"
end
local function scrollBottom()
    task.defer(function()
        local maxY=math.max(0,layout.AbsoluteContentSize.Y-messages.AbsoluteSize.Y)
        messages.CanvasPosition=Vector2.new(0,maxY)
    end)
end
local function trimLocal()
    local children={}
    for _,v in ipairs(messages:GetChildren()) do if v:IsA("Frame") then table.insert(children,v) end end
    local keep = clamp(settings.visibleMessages, MIN_MESSAGES, MAX_MESSAGES)
    while #children>keep do
        children[1]:Destroy(); table.remove(children,1)
    end
    while #children>MAX_LOCAL_MESSAGES do
        children[1]:Destroy(); table.remove(children,1)
    end
    scrollBottom()
end
local function addMessage(user,msg)
    local c=Instance.new("Frame",messages); c.Size=UDim2.new(1,0,0,0); c.AutomaticSize=Enum.AutomaticSize.Y; c.BackgroundTransparency=1; c.LayoutOrder=os.clock()*1000; c.ZIndex=22
    local l=Instance.new("TextLabel",c); l.Size=UDim2.new(1,0,0,0); l.AutomaticSize=Enum.AutomaticSize.Y; l.BackgroundTransparency=1; l.RichText=true; l.TextWrapped=true
    l.TextXAlignment=Enum.TextXAlignment.Left; l.TextColor3=Color3.fromRGB(235,235,235); l.Font=Enum.Font.Gotham; l.TextSize=13; l.ZIndex=23
    l.Text=string.format('<font color="%s"><b>%s:</b></font> %s',hex(userColor(user)),esc(user),esc(msg))
    trimLocal(); scrollBottom()
end

local notifySound=Instance.new("Sound",gui)
notifySound.Name="MessageSound"
notifySound.SoundId="rbxassetid://6026984224"
notifySound.Volume=0.65
local function notify()
    pcall(function() notifySound:Play() end)
    if isOpen then return end
    task.spawn(function()
        for i=1,4 do
            if not toggleBtn.Parent then break end
            toggleBtn.BackgroundColor3=accent(); task.wait(0.13)
            toggleBtn.BackgroundColor3=Color3.fromRGB(35,35,38); task.wait(0.13)
        end
        if toggleBtn.Parent then toggleBtn.BackgroundColor3=accent() end
    end)
end

local function send(text)
    text=tostring(text or ""):match("^%s*(.-)%s*$")
    if text=="" or tick()-lastSent<0.8 then return end
    lastSent=tick(); text=text:sub(1,200)
    task.spawn(function()
        local ok,res=pcall(function()
            return request({Url=PROJECT_URL.."/rest/v1/chat_messages",Method="POST",Headers={apikey=API_KEY,["Authorization"]="Bearer "..API_KEY,["Content-Type"]="application/json",Prefer="return=minimal"},Body=HttpService:JSONEncode({username=LocalPlayer.Name,message=text})})
        end)
        if not ok or not res or (res.StatusCode and res.StatusCode>=300) then warn("ProChat send failed",res and res.Body or "") end
    end)
end
local function trySend() if box.Text~="" then local t=box.Text; box.Text=""; send(t) end end
box.FocusLost:Connect(function(enter) if enter then trySend() end end)
sendBtn.MouseButton1Click:Connect(trySend)

local function beginDrag(target,input)
    dragTarget=target; dragStart=input.Position; dragOrigin=target.Position
end
local function stopDrag() dragTarget=nil; dragStart=nil; dragOrigin=nil end
local function updateDrag(input)
    if not dragTarget then return end
    local d=input.Position-dragStart
    local maxX=math.max(4,gui.AbsoluteSize.X-dragTarget.AbsoluteSize.X-4)
    local maxY=math.max(4,gui.AbsoluteSize.Y-dragTarget.AbsoluteSize.Y-4)
    local x=clamp(dragOrigin.X.Offset+d.X,4,maxX); local y=clamp(dragOrigin.Y.Offset+d.Y,4,maxY)
    dragTarget.Position=UDim2.new(0,x,0,y)
    if dragTarget==toggleBtn then settings.buttonX=x; settings.buttonY=y end
    if dragTarget==frame then settings.chatX=x; settings.chatY=y end
end
local function startResize(input)
    resizing=true; resizeStart=input.Position; resizeOriginW=frame.AbsoluteSize.X; resizeOriginH=frame.AbsoluteSize.Y
end
local function updateResize(input)
    if not resizing then return end
    local d=input.Position-resizeStart
    settings.width=clamp((resizeOriginW+d.X)/math.max(gui.AbsoluteSize.X,1),MIN_W,MAX_W)
    settings.height=clamp((resizeOriginH+d.Y)/math.max(gui.AbsoluteSize.Y,1),MIN_H,MAX_H)
    frame.Size=UDim2.new(settings.width,0,settings.height,0)
    updateSettingsUI()
end

toggleBtn.InputBegan:Connect(function(i) if (i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch) and editButtonMode then beginDrag(toggleBtn,i) end end)
header.InputBegan:Connect(function(i) if (i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch) and editChatMode then beginDrag(frame,i) end end)
resizeHandle.InputBegan:Connect(function(i) if (i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch) and editChatMode then startResize(i) end end)
UserInputService.InputChanged:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then updateDrag(i); updateResize(i) end
end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then stopDrag(); resizing=false end end)

msgMinus.MouseButton1Click:Connect(function() settings.visibleMessages=math.max(MIN_MESSAGES,settings.visibleMessages-1); trimLocal(); updateSettingsUI() end)
msgPlus.MouseButton1Click:Connect(function() settings.visibleMessages=math.min(MAX_MESSAGES,settings.visibleMessages+1); updateSettingsUI(); scrollBottom() end)
wMinus.MouseButton1Click:Connect(function() settings.width=clamp(settings.width-0.03,MIN_W,MAX_W); updateSettingsUI() end)
wPlus.MouseButton1Click:Connect(function() settings.width=clamp(settings.width+0.03,MIN_W,MAX_W); updateSettingsUI() end)
hMinus.MouseButton1Click:Connect(function() settings.height=clamp(settings.height-0.03,MIN_H,MAX_H); updateSettingsUI() end)
hPlus.MouseButton1Click:Connect(function() settings.height=clamp(settings.height+0.03,MIN_H,MAX_H); updateSettingsUI() end)
moveBtn.MouseButton1Click:Connect(function() editButtonMode=not editButtonMode; editChatMode=false; updateSettingsUI() end)
moveChat.MouseButton1Click:Connect(function() editChatMode=not editChatMode; editButtonMode=false; updateSettingsUI() end)
resetBtn.MouseButton1Click:Connect(function()
    settings.visibleMessages=defaultVisible; settings.width=isTouch and 0.72 or 0.38; settings.height=isTouch and 0.42 or 0.36
    settings.buttonX=12; settings.buttonY=12; settings.chatX=12; settings.chatY=55; settings.color=Color3.fromRGB(88,101,242)
    editButtonMode=false; editChatMode=false
    frameStroke.Color=settings.color; sendBtn.BackgroundColor3=settings.color; resizeHandle.BackgroundColor3=settings.color; toggleBtn.BackgroundColor3=settings.color; settingsStroke.Color=settings.color
    updateSettingsUI()
end)
closeBtn.MouseButton1Click:Connect(function() settingsPanel.Visible=false; editButtonMode=false; editChatMode=false; updateSettingsUI() end)
settingsBtn.MouseButton1Click:Connect(function() settingsPanel.Visible=not settingsPanel.Visible; if settingsPanel.Visible then editButtonMode=false; editChatMode=false; updateSettingsUI() end end)

local function openChat()
    isOpen=true; settingsPanel.Visible=false
    frame.Visible=true; frame.Size=UDim2.new(0,0,0,0); frame.BackgroundTransparency=1
    TweenService:Create(frame,TweenInfo.new(0.18,Enum.EasingStyle.Back),{Size=UDim2.new(settings.width,0,settings.height,0),BackgroundTransparency=settings.transparency}):Play()
    toggleBtn.Text="✕"; toggleBtn.BackgroundColor3=Color3.fromRGB(190,65,65)
    scrollBottom()
end
local function closeChat()
    isOpen=false
    TweenService:Create(frame,TweenInfo.new(0.14),{Size=UDim2.new(0,0,0,0),BackgroundTransparency=1}):Play()
    toggleBtn.Text="💬 Chat"; toggleBtn.BackgroundColor3=accent()
    task.delay(0.15,function() if not isOpen then frame.Visible=false end end)
end
toggleBtn.MouseButton1Click:Connect(function() if isOpen then closeChat() else openChat() end end)

UserInputService.InputBegan:Connect(function(input,processed)
    if processed then return end
    if input.KeyCode==Enum.KeyCode.Slash and isMouse then
        if not isOpen then openChat() end
        task.defer(function() pcall(function() box:CaptureFocus() end) end)
    end
end)

local function poll()
    task.spawn(function()
        while task.wait(POLL_INTERVAL) do
            pcall(function()
                local url=PROJECT_URL.."/rest/v1/chat_messages?select=*&order=id.asc&limit=10"
                local res=request({Url=url,Method="GET",Headers={apikey=API_KEY,["Authorization"]="Bearer "..API_KEY}})
                if res and res.Body then
                    local data=HttpService:JSONDecode(res.Body)
                    if type(data)=="table" then
                        local newIncoming=false
                        for _,v in ipairs(data) do
                            if v.id and not shownIds[v.id] then
                                shownIds[v.id]=true
                                addMessage(v.username or "Unknown",v.message or "")
                                if not firstLoad and v.username~=LocalPlayer.Name then newIncoming=true end
                            end
                        end
                        firstLoad=false
                        if newIncoming then notify() end
                    end
                end
            end)
        end
    end)
end

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() if isOpen then scrollBottom() end end)
updateSettingsUI()
poll()
print("Pro Chat Global v17 Loaded - NO SAVE / NO ROOMS")
