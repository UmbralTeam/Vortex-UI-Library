-- ╔══════════════════════════════════════════════════════╗
-- ║          VORTEX HUB V3 - IMPROVED EDITION            ║
-- ║   Fixed: Memory Leaks, Dragging, Resizing Bugs       ║
-- ║   Added: Better Error Handling, Cleaner Structure    ║
-- ╚══════════════════════════════════════════════════════╝

local UIS       = game:GetService("UserInputService")
local TweenSvc  = game:GetService("TweenService")
local Players   = game:GetService("Players")
local RunSvc    = game:GetService("RunService")
local Lighting  = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
    or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    and Players.LocalPlayer

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ┌─────────────────────────────────┐
-- │       RE-RUN PROTECTION         │
-- └─────────────────────────────────┘
local GUI_NAMES = {"VX_V3", "VX_KeySys", "VX_Dialog", "VortexNotify"}
for _, v in ipairs(PlayerGui:GetChildren()) do
    for _, n in ipairs(GUI_NAMES) do
        if v.Name == n then v:Destroy() end
    end
end

-- ┌─────────────────────────────────┐
-- │         TWEEN HELPER            │
-- └─────────────────────────────────┘
local function tween(obj, info, goal)
    return TweenSvc:Create(obj, info, goal)
end
local function tweenPlay(obj, t, goal, style, dir)
    style = style or Enum.EasingStyle.Quart
    dir   = dir   or Enum.EasingDirection.Out
    tween(obj, TweenInfo.new(t, style, dir), goal):Play()
end

-- ┌─────────────────────────────────┐
-- │       INSTANCE FACTORY          │
-- └─────────────────────────────────┘
local function new(class, props)
    local inst = Instance.new(class)
    local parent = props.Parent
    props.Parent = nil
    for k, v in pairs(props) do
        inst[k] = v
    end
    inst.Parent = parent
    return inst
end

-- ┌─────────────────────────────────┐
-- │         CORE LIBRARY            │
-- └─────────────────────────────────┘
local Library = {
    Config = {
        MainColor       = Color3.fromRGB(160, 80, 255),
        SecondaryColor  = Color3.fromRGB(30, 30, 40),
        BackgroundColor = Color3.fromRGB(15, 15, 20),
        Transparency    = 0.08,
        OptionSpacing   = 14,
        UIStrokeColor   = Color3.fromRGB(70, 70, 85),
        CornerRadius    = UDim.new(0, 10),
        Scale           = 1,
        Font            = Font.new(
            "rbxasset://fonts/families/GothamSSm.json",
            Enum.FontWeight.Bold, Enum.FontStyle.Italic
        ),
        ToggleKey       = Enum.KeyCode.RightControl,
    },

    -- Track all themed elements
    Elements = {
        Accents     = {},   -- BackgroundColor3 = MainColor
        Gradients   = {},   -- UIGradient
        Fonts       = {},   -- FontFace
        Backgrounds = {},   -- BackgroundTransparency
        Scales      = {},   -- UIScale
        Strokes     = {},   -- UIStroke Color = MainColor
    },

    Connections = {},   -- all RBXScriptConnections for cleanup
    Opened = true,
    NotifyUI = nil,
    NotifyContainer = nil,
}

-- ────── Safe connect (auto-tracked) ──────
function Library:Connect(signal, fn)
    local conn = signal:Connect(fn)
    table.insert(self.Connections, conn)
    return conn
end

-- ────── Cleanup all connections ──────
function Library:Destroy()
    for _, c in ipairs(self.Connections) do
        if c.Connected then c:Disconnect() end
    end
    self.Connections = {}
    for _, n in ipairs(GUI_NAMES) do
        local g = PlayerGui:FindFirstChild(n)
        if g then g:Destroy() end
    end
end

-- ────── Theme updater ──────
function Library:UpdateTheme()
    local mc = self.Config.MainColor
    local font = self.Config.Font
    local trans = self.Config.Transparency

    for _, o in ipairs(self.Elements.Accents) do
        if o and o.Parent then
            if o:IsA("UIStroke") then
                o.Color = mc
            elseif o:IsA("TextLabel") then
                o.TextColor3 = mc
            else
                o.BackgroundColor3 = mc
            end
        end
    end
    for _, g in ipairs(self.Elements.Gradients) do
        if g and g.Parent then
            g.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, mc),
                ColorSequenceKeypoint.new(1, Color3.new(0,0,0))
            })
        end
    end
    for _, t in ipairs(self.Elements.Fonts) do
        if t and t.Parent then t.FontFace = font end
    end
    for _, b in ipairs(self.Elements.Backgrounds) do
        if b and b.Parent then b.BackgroundTransparency = trans end
    end
end

-- ────── UI Scale ──────
function Library:SetUIScale(scale)
    self.Config.Scale = scale
    for _, s in ipairs(self.Elements.Scales) do
        if s and s.Parent then
            tweenPlay(s, 0.35, {Scale = scale})
        end
    end
end

-- ┌─────────────────────────────────┐
-- │   DRAGGING (fixed edge case)    │
-- └─────────────────────────────────┘
local function makeDraggable(frame)
    local dragging, dragStart, startPos = false, nil, nil

    frame.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = inp.Position
            startPos  = frame.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    UIS.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = inp.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ┌─────────────────────────────────┐
-- │         KEY SYSTEM              │
-- └─────────────────────────────────┘
function Library:CreateKeySystem(config)
    local existing = PlayerGui:FindFirstChild("VX_KeySys")
    if existing then existing:Destroy() end

    local kName    = config.Name     or "Key System"
    local kNote    = config.Note     or "Enter your key to continue."
    local validKey = config.Key      or "VORTEX"
    local callback = config.Callback

    local sg = new("ScreenGui", {
        Name = "VX_KeySys", ResetOnSpawn = false,
        DisplayOrder = 200, Parent = PlayerGui
    })

    local frame = new("Frame", {
        Name = "KeyFrame",
        Position = UDim2.new(0.5, -200, 0.5, -130),
        Size = UDim2.new(0, 400, 0, 260),
        BackgroundColor3 = self.Config.BackgroundColor,
        BackgroundTransparency = self.Config.Transparency,
        Parent = sg
    })
    table.insert(self.Elements.Backgrounds, frame)

    local sc = new("UIScale", {Scale = self.Config.Scale, Parent = frame})
    table.insert(self.Elements.Scales, sc)
    new("UICorner", {CornerRadius = self.Config.CornerRadius, Parent = frame})
    new("UIStroke", {Color = self.Config.UIStrokeColor, Thickness = 1.8, Parent = frame})

    new("TextLabel", {
        Position = UDim2.new(0,20,0,18), Size = UDim2.new(1,-40,0,32),
        BackgroundTransparency = 1, Text = kName:upper(),
        TextColor3 = Color3.new(1,1,1), TextSize = 22,
        FontFace = self.Config.Font, TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    })
    new("TextLabel", {
        Position = UDim2.new(0,20,0,52), Size = UDim2.new(1,-40,0,42),
        BackgroundTransparency = 1, Text = kNote,
        TextColor3 = Color3.fromRGB(180,180,180), TextSize = 15,
        FontFace = self.Config.Font, TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true, Parent = frame
    })

    local inpWrap = new("Frame", {
        Position = UDim2.new(0,20,0,102), Size = UDim2.new(1,-40,0,50),
        BackgroundColor3 = self.Config.SecondaryColor, Parent = frame
    })
    new("UICorner", {CornerRadius = UDim.new(0,8), Parent = inpWrap})
    new("UIStroke", {Color = self.Config.UIStrokeColor, Thickness = 1, Parent = inpWrap})

    local inp = new("TextBox", {
        Position = UDim2.new(0,14,0,0), Size = UDim2.new(1,-28,1,0),
        BackgroundTransparency = 1, PlaceholderText = "Enter key here...",
        Text = "", TextColor3 = Color3.new(1,1,1), TextSize = 17,
        FontFace = self.Config.Font, TextXAlignment = Enum.TextXAlignment.Left,
        Parent = inpWrap
    })

    local function closeAndCallback()
        tweenPlay(frame, 0.4, {Size = UDim2.new(0,0,0,0)}, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
        task.delay(0.4, function() sg:Destroy(); if callback then callback() end end)
    end

    local subBtn = new("TextButton", {
        Position = UDim2.new(0,20,0,172), Size = UDim2.new(0.5,-25,0,48),
        BackgroundColor3 = self.Config.SecondaryColor, AutoButtonColor = false,
        Text = "Submit Key", TextColor3 = Color3.new(1,1,1), TextSize = 18,
        FontFace = self.Config.Font, Parent = frame
    })
    new("UICorner", {CornerRadius = UDim.new(0,8), Parent = subBtn})
    local subStr = new("UIStroke", {Color = self.Config.MainColor, Thickness = 1.5, Parent = subBtn})
    table.insert(self.Elements.Accents, subStr)

    local skipBtn = new("TextButton", {
        Position = UDim2.new(0.5,5,0,172), Size = UDim2.new(0.5,-25,0,48),
        BackgroundColor3 = self.Config.SecondaryColor, AutoButtonColor = false,
        Text = "Skip", TextColor3 = Color3.fromRGB(150,150,150), TextSize = 16,
        FontFace = self.Config.Font, Parent = frame
    })
    new("UICorner", {CornerRadius = UDim.new(0,8), Parent = skipBtn})

    makeDraggable(frame)

    local function hoverEffect(btn, enterColor, leaveColor)
        btn.MouseEnter:Connect(function() tweenPlay(btn, 0.2, {BackgroundColor3 = enterColor}) end)
        btn.MouseLeave:Connect(function() tweenPlay(btn, 0.2, {BackgroundColor3 = leaveColor}) end)
    end
    hoverEffect(subBtn,  Color3.fromRGB(45,45,55), self.Config.SecondaryColor)
    hoverEffect(skipBtn, Color3.fromRGB(45,45,55), self.Config.SecondaryColor)

    skipBtn.MouseButton1Click:Connect(closeAndCallback)

    subBtn.MouseButton1Click:Connect(function()
        local entered = inp.Text
        if entered == validKey then
            closeAndCallback()
        else
            local originalText = inp.Text
            inp.Text = "⚠ INVALID KEY"
            inp.TextColor3 = Color3.fromRGB(255,80,80)
            task.delay(1.5, function()
                inp.Text = ""
                inp.TextColor3 = Color3.new(1,1,1)
            end)
        end
    end)
end

-- ┌─────────────────────────────────┐
-- │           DIALOG                │
-- └─────────────────────────────────┘
function Library:CreateDialog(config)
    local sg = new("ScreenGui", {
        Name = "VX_Dialog", ResetOnSpawn = false,
        DisplayOrder = 300, Parent = PlayerGui
    })

    local frame = new("Frame", {
        Position = UDim2.new(0.5,-175,0.5,-100), Size = UDim2.new(0,350,0,200),
        BackgroundColor3 = self.Config.BackgroundColor,
        BackgroundTransparency = self.Config.Transparency, Parent = sg
    })
    table.insert(self.Elements.Backgrounds, frame)
    local sc = new("UIScale", {Scale = self.Config.Scale, Parent = frame})
    table.insert(self.Elements.Scales, sc)
    new("UICorner", {CornerRadius = self.Config.CornerRadius, Parent = frame})
    new("UIStroke", {Color = self.Config.UIStrokeColor, Thickness = 1.8, Parent = frame})

    new("TextLabel", {
        Position = UDim2.new(0,20,0,18), Size = UDim2.new(1,-40,0,30),
        BackgroundTransparency = 1, Text = (config.Title or "Dialog"):upper(),
        TextColor3 = Color3.new(1,1,1), TextSize = 22,
        FontFace = self.Config.Font, TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    })
    new("TextLabel", {
        Position = UDim2.new(0,20,0,52), Size = UDim2.new(1,-40,0,70),
        BackgroundTransparency = 1, Text = config.Content or "Are you sure?",
        TextColor3 = Color3.fromRGB(180,180,180), TextSize = 16,
        FontFace = self.Config.Font, TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true, Parent = frame
    })

    local function makeDialogBtn(pos, text, cb, accent)
        local btn = new("TextButton", {
            Position = pos, Size = UDim2.new(0.5,-25,0,42),
            BackgroundColor3 = self.Config.SecondaryColor, AutoButtonColor = false,
            Text = text, TextColor3 = Color3.new(1,1,1), TextSize = 16,
            FontFace = self.Config.Font, Parent = frame
        })
        new("UICorner", {CornerRadius = UDim.new(0,8), Parent = btn})
        if accent then
            local str = new("UIStroke", {Color = self.Config.MainColor, Thickness = 1.5, Parent = btn})
            table.insert(self.Elements.Accents, str)
        end
        btn.MouseEnter:Connect(function() tweenPlay(btn, 0.2, {BackgroundColor3 = Color3.fromRGB(45,45,55)}) end)
        btn.MouseLeave:Connect(function() tweenPlay(btn, 0.2, {BackgroundColor3 = self.Config.SecondaryColor}) end)
        btn.MouseButton1Click:Connect(function()
            sg:Destroy()
            if cb then cb() end
        end)
        return btn
    end

    makeDialogBtn(UDim2.new(0,20,1,-60), config.Button1 or "Confirm", config.Callback1, true)
    makeDialogBtn(UDim2.new(0.5,5,1,-60),  config.Button2 or "Cancel",  config.Callback2, false)

    makeDraggable(frame)
end

-- ┌─────────────────────────────────┐
-- │        MAIN WINDOW              │
-- └─────────────────────────────────┘
function Library:CreateWindow(name)
    local existing = PlayerGui:FindFirstChild("VX_V3")
    if existing then existing:Destroy() end

    local sg = new("ScreenGui", {
        Name = "VX_V3", ResetOnSpawn = false,
        DisplayOrder = 100, Parent = PlayerGui
    })

    -- ── Main Frame ──
    local frame = new("Frame", {
        Name = "MainFrame",
        Position = UDim2.new(0.5,-325,0.5,-235),
        Size = UDim2.new(0,650,0,470),
        BackgroundColor3 = self.Config.BackgroundColor,
        BackgroundTransparency = self.Config.Transparency,
        Parent = sg
    })
    table.insert(self.Elements.Backgrounds, frame)
    local hubScale = new("UIScale", {Scale = self.Config.Scale, Parent = frame})
    table.insert(self.Elements.Scales, hubScale)
    new("UIStroke", {Color = self.Config.UIStrokeColor, Thickness = 1.8, Parent = frame})
    new("UICorner", {CornerRadius = self.Config.CornerRadius, Parent = frame})

    -- ── Glow Decoration ──
    local glowFrame = new("Frame", {
        Size = UDim2.new(1,0,0,3), Position = UDim2.new(0,0,0,0),
        BackgroundColor3 = self.Config.MainColor, BorderSizePixel = 0, Parent = frame
    })
    table.insert(self.Elements.Accents, glowFrame)
    new("UICorner", {CornerRadius = UDim.new(0,3), Parent = glowFrame})
    new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, self.Config.MainColor),
            ColorSequenceKeypoint.new(1, Color3.new(0,0,0))
        }),
        Parent = glowFrame
    })

    -- ── TopBar ──
    local topBar = new("Frame", {
        Size = UDim2.new(1,0,0,65), BackgroundTransparency = 1, Parent = frame
    })

    local titleLabel = new("TextLabel", {
        Position = UDim2.new(0,25,0,0), Size = UDim2.new(0,250,1,0),
        BackgroundTransparency = 1, Text = name:upper(),
        TextColor3 = Color3.new(1,1,1), TextSize = 22,
        FontFace = self.Config.Font, TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topBar
    })
    table.insert(self.Elements.Fonts, titleLabel)

    -- Version badge
    new("TextLabel", {
        Position = UDim2.new(0,25,0,38), Size = UDim2.new(0,150,0,16),
        BackgroundTransparency = 1, Text = "v3.0 Improved Edition",
        TextColor3 = Color3.fromRGB(120,120,140), TextSize = 13,
        FontFace = self.Config.Font, TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topBar
    })

    -- Close / Minimize buttons
    local function makeTopBtn(xOffset, icon)
        local btn = new("TextButton", {
            Position = UDim2.new(1, xOffset, 0, 17),
            Size = UDim2.new(0,30,0,30),
            BackgroundColor3 = Color3.fromRGB(25,25,32),
            Text = icon, TextColor3 = Color3.new(1,1,1), TextSize = 13,
            FontFace = self.Config.Font, Parent = topBar
        })
        new("UICorner", {CornerRadius = UDim.new(0,6), Parent = btn})
        new("UIStroke", {Color = self.Config.UIStrokeColor, Thickness = 1, Parent = btn})
        btn.MouseEnter:Connect(function() tweenPlay(btn, 0.15, {BackgroundColor3 = Color3.fromRGB(45,45,60)}) end)
        btn.MouseLeave:Connect(function() tweenPlay(btn, 0.15, {BackgroundColor3 = Color3.fromRGB(25,25,32)}) end)
        return btn
    end

    local closeBtn = makeTopBtn(-42, "✖")
    local minBtn   = makeTopBtn(-80, "—")

    closeBtn.MouseButton1Click:Connect(function() sg:Destroy() end)

    -- ── Separator Line ──
    new("Frame", {
        Position = UDim2.new(0,12,0,66), Size = UDim2.new(1,-24,0,1),
        BackgroundColor3 = self.Config.UIStrokeColor, BorderSizePixel = 0, Parent = frame
    })

    -- ── Sidebar ──
    local sidebar = new("ScrollingFrame", {
        Position = UDim2.new(0,12,0,78), Size = UDim2.new(0,175,1,-130),
        BackgroundTransparency = 1, ScrollBarThickness = 0,
        ScrollingEnabled = true, Parent = frame
    })
    new("UIListLayout", {Padding = UDim.new(0,8), Parent = sidebar})
    new("UIPadding", {PaddingTop = UDim.new(0,4), Parent = sidebar})

    -- ── Sidebar divider ──
    new("Frame", {
        Position = UDim2.new(0,197,0,78), Size = UDim2.new(0,1,1,-130),
        BackgroundColor3 = self.Config.UIStrokeColor, BorderSizePixel = 0, Parent = frame
    })

    -- ── Tab Container ──
    local tabContainer = new("Frame", {
        Position = UDim2.new(0,205,0,78), Size = UDim2.new(1,-218,1,-130),
        BackgroundTransparency = 1, ClipsDescendants = true, Parent = frame
    })

    -- ── Footer ──
    local footer = new("Frame", {
        Position = UDim2.new(0,0,1,-38), Size = UDim2.new(1,0,0,38),
        BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 0.8, Parent = frame
    })
    new("UICorner", {CornerRadius = UDim.new(0,10), Parent = footer})
    local statLabel = new("TextLabel", {
        Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
        Text = "Initializing...", TextColor3 = Color3.fromRGB(200,200,220),
        TextSize = 14, FontFace = self.Config.Font, Parent = footer
    })
    table.insert(self.Elements.Fonts, statLabel)

    -- ── Resize Handle ──
    local currentSize = Vector2.new(650, 470)
    local resizer = new("TextButton", {
        Size = UDim2.new(0,22,0,22), Position = UDim2.new(1,-22,1,-22),
        BackgroundTransparency = 1, Text = "◢",
        TextColor3 = Color3.fromRGB(100,100,120), TextSize = 14,
        FontFace = self.Config.Font, ZIndex = 100, Parent = frame
    })

    -- ── Minimize logic (fixed: no re-entry) ──
    local isMinimized = false
    local minBusy = false

    minBtn.MouseButton1Click:Connect(function()
        if minBusy then return end
        minBusy = true
        isMinimized = not isMinimized

        frame.ClipsDescendants = true

        if isMinimized then
            local tw = tween(frame, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                {Size = UDim2.new(0, currentSize.X, 0, 66)})
            tw:Play()
            tw.Completed:Wait()
            sidebar.Visible      = false
            tabContainer.Visible = false
            footer.Visible       = false
            resizer.Visible      = false
        else
            sidebar.Visible      = true
            tabContainer.Visible = true
            footer.Visible       = true
            resizer.Visible      = true
            local tw = tween(frame, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
                {Size = UDim2.new(0, currentSize.X, 0, currentSize.Y)})
            tw:Play()
            tw.Completed:Wait()
            frame.ClipsDescendants = false
        end

        minBusy = false
    end)

    -- ── Toggle Key (global) ──
    self:Connect(UIS.InputBegan, function(i, gp)
        if not gp and i.KeyCode == self.Config.ToggleKey then
            self.Opened = not self.Opened
            frame.Visible = self.Opened
        end
    end)

    -- ── Dragging (fixed: topBar only) ──
    do
        local dragging, dragStart, startPos = false, nil, nil
        topBar.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging  = true
                dragStart = inp.Position
                startPos  = frame.Position
                inp.Changed:Connect(function()
                    if inp.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        self:Connect(UIS.InputChanged, function(inp)
            if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                local d = inp.Position - dragStart
                frame.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y
                )
            end
        end)
    end

    -- ── Resizing (fixed: clamping + proper state) ──
    do
        local resizing, resizeStart, startSz = false, nil, nil
        resizer.MouseButton1Down:Connect(function()
            if isMinimized then return end
            resizing    = true
            resizeStart = UIS:GetMouseLocation()
            startSz     = currentSize
        end)
        self:Connect(UIS.InputChanged, function(inp)
            if resizing and inp.UserInputType == Enum.UserInputType.MouseMovement then
                local p    = UIS:GetMouseLocation()
                local newX = math.clamp(startSz.X + (p.X - resizeStart.X), 500, 1400)
                local newY = math.clamp(startSz.Y + (p.Y - resizeStart.Y), 320, 900)
                currentSize = Vector2.new(newX, newY)
                frame.Size  = UDim2.new(0, newX, 0, newY)
            end
        end)
        self:Connect(UIS.InputEnded, function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                resizing = false
            end
        end)
    end

    -- ── FPS/Ping Footer ──
    task.spawn(function()
        local statsService = game:GetService("Stats")
        while sg.Parent do
            task.wait(1)
            local fps  = math.floor(1 / RunSvc.Heartbeat:Wait())
            local ping = 0
            pcall(function()
                ping = math.floor(statsService.PerformanceStats.Ping:GetValue())
            end)
            if statLabel.Parent then
                statLabel.Text = string.format(
                    "  ⚡ FPS: %d   🌐 PING: %d ms   🕐 %s",
                    fps, ping, os.date("%H:%M:%S")
                )
            end
        end
    end)

    -- ════════════════════════════════════
    --         WINDOW OBJECT
    -- ════════════════════════════════════
    local Window = {
        Gui          = sg,
        Frame        = frame,
        CurrentPage  = nil,
        CurrentTab   = nil,
        _tabButtons  = {},
    }

    -- ┌─────────────────────────────────┐
    -- │           CREATE TAB            │
    -- └─────────────────────────────────┘
    function Window:CreateTab(tabName, icon)
        -- Sidebar button
        local tabBtn = new("TextButton", {
            Size = UDim2.new(1,0,0,50),
            BackgroundTransparency = 1, Text = "",
            Parent = sidebar
        })
        new("UICorner", {CornerRadius = Library.Config.CornerRadius, Parent = tabBtn})

        -- Active gradient background
        local tabBg = new("Frame", {
            Name = "Bg", Size = UDim2.new(1,0,1,0),
            BackgroundColor3 = Color3.new(1,1,1),
            BackgroundTransparency = 1, Visible = false, Parent = tabBtn
        })
        new("UICorner", {CornerRadius = Library.Config.CornerRadius, Parent = tabBg})
        local gr = new("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Library.Config.MainColor),
                ColorSequenceKeypoint.new(1, Color3.new(0,0,0))
            }),
            Parent = tabBg
        })
        table.insert(Library.Elements.Gradients, gr)

        -- Icon
        local tabIc = new("ImageLabel", {
            Position = UDim2.new(0,14,0.5,-11), Size = UDim2.new(0,22,0,22),
            BackgroundTransparency = 1, Image = icon or "rbxassetid://6023454032",
            ImageColor3 = Color3.fromRGB(160,160,180), Parent = tabBtn
        })

        -- Label
        local tabLb = new("TextLabel", {
            Position = UDim2.new(0,44,0,0), Size = UDim2.new(1,-50,1,0),
            BackgroundTransparency = 1, Text = tabName,
            TextColor3 = Color3.fromRGB(160,160,180), TextSize = 17,
            FontFace = Library.Config.Font, TextXAlignment = Enum.TextXAlignment.Left,
            Parent = tabBtn
        })
        table.insert(Library.Elements.Fonts, tabLb)

        -- Active indicator bar
        local tabInd = new("Frame", {
            Size = UDim2.new(0,4,0,0), Position = UDim2.new(0,0,0.5,0),
            BackgroundColor3 = Library.Config.MainColor,
            AnchorPoint = Vector2.new(0,0.5), Parent = tabBtn
        })
        table.insert(Library.Elements.Accents, tabInd)
        new("UICorner", {CornerRadius = UDim.new(1,0), Parent = tabInd})

        -- Page (scrolling)
        local page = new("ScrollingFrame", {
            Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
            Visible = false, ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.Config.MainColor,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Parent = tabContainer
        })
        new("UIListLayout", {Padding = UDim.new(0, Library.Config.OptionSpacing), Parent = page})
        new("UIPadding", {
            PaddingLeft = UDim.new(0,10), PaddingRight = UDim.new(0,10),
            PaddingTop = UDim.new(0,6), Parent = page
        })

        local function activateTab()
            if Window.CurrentTab == tabName then return end

            -- Deactivate all tabs
            for _, data in ipairs(Window._tabButtons) do
                data.page.Visible = false
                data.bg.Visible   = false
                data.lb.TextColor3 = Color3.fromRGB(160,160,180)
                data.ic.ImageColor3 = Color3.fromRGB(160,160,180)
                tweenPlay(data.ind, 0.3, {Size = UDim2.new(0,4,0,0)}, Enum.EasingStyle.Back)
                tweenPlay(data.btn, 0.2, {BackgroundTransparency = 1})
            end

            -- Activate this tab
            Window.CurrentPage = page
            Window.CurrentTab  = tabName
            page.Visible       = true
            tabBg.Visible      = true
            tabBg.BackgroundTransparency = 0.45
            tabLb.TextColor3   = Color3.new(1,1,1)
            tabIc.ImageColor3  = Color3.new(1,1,1)
            tweenPlay(tabInd, 0.4, {Size = UDim2.new(0,4,0,30)}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

            -- Slide-in animation
            page.Position = UDim2.new(0,25,0,0)
            tweenPlay(page, 0.35, {Position = UDim2.new(0,0,0,0)})
        end

        -- Hover effects
        tabBtn.MouseEnter:Connect(function()
            if Window.CurrentTab ~= tabName then
                tweenPlay(tabBtn, 0.2, {BackgroundColor3 = Color3.new(1,1,1), BackgroundTransparency = 0.94})
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if Window.CurrentTab ~= tabName then
                tweenPlay(tabBtn, 0.2, {BackgroundTransparency = 1})
            end
        end)

        tabBtn.MouseButton1Click:Connect(activateTab)

        table.insert(Window._tabButtons, {
            btn  = tabBtn,
            bg   = tabBg,
            lb   = tabLb,
            ic   = tabIc,
            ind  = tabInd,
            page = page
        })

        -- Auto-select first tab
        if not Window.CurrentTab then
            Window.CurrentPage = page
            Window.CurrentTab  = tabName
            page.Visible       = true
            tabBg.Visible      = true
            tabBg.BackgroundTransparency = 0.45
            tabLb.TextColor3   = Color3.new(1,1,1)
            tabIc.ImageColor3  = Color3.new(1,1,1)
            tabInd.Size        = UDim2.new(0,4,0,30)
        end

        -- ════════════════════════════════════
        --         TAB ELEMENTS
        -- ════════════════════════════════════
        local Tab = {}

        -- ── Section Header ──
        function Tab:CreateSection(sectionName)
            local wrap = new("Frame", {
                Size = UDim2.new(1,0,0,32), BackgroundTransparency = 1, Parent = page
            })
            local line = new("Frame", {
                Position = UDim2.new(0,0,0.5,0), Size = UDim2.new(1,0,0,1),
                BackgroundColor3 = Library.Config.UIStrokeColor, BorderSizePixel = 0, Parent = wrap
            })
            local sLabel = new("TextLabel", {
                Position = UDim2.new(0,8,0,0), Size = UDim2.new(0.6,0,1,0),
                BackgroundColor3 = Library.Config.BackgroundColor,
                BackgroundTransparency = Library.Config.Transparency,
                Text = " " .. sectionName:upper() .. " ",
                TextColor3 = Library.Config.MainColor, TextSize = 14,
                FontFace = Library.Config.Font, TextXAlignment = Enum.TextXAlignment.Left,
                Parent = wrap
            })
            table.insert(Library.Elements.Accents, sLabel)
        end

        -- ── Label ──
        function Tab:CreateLabel(text)
            local lb = new("TextLabel", {
                Size = UDim2.new(1,0,0,36), BackgroundTransparency = 1,
                Text = "  " .. text, TextColor3 = Color3.fromRGB(210,210,225),
                TextSize = 17, FontFace = Library.Config.Font,
                TextXAlignment = Enum.TextXAlignment.Left, Parent = page
            })
            table.insert(Library.Elements.Fonts, lb)
            return lb
        end

        -- ── Toggle ──
        function Tab:CreateToggle(n, defaultOn, callback)
            local state = defaultOn or false
            local T = new("TextButton", {
                Size = UDim2.new(1,0,0,58), AutoButtonColor = false,
                BackgroundColor3 = Library.Config.SecondaryColor,
                Text = "", Parent = page
            })
            new("UICorner", {CornerRadius = Library.Config.CornerRadius, Parent = T})
            new("UIStroke", {Color = Library.Config.UIStrokeColor, Thickness = 1, Parent = T})

            new("TextLabel", {
                Position = UDim2.new(0,16,0,0), Size = UDim2.new(1,-90,1,0),
                BackgroundTransparency = 1, Text = n,
                TextColor3 = Color3.new(1,1,1), TextSize = 18,
                FontFace = Library.Config.Font, TextXAlignment = Enum.TextXAlignment.Left,
                Parent = T
            })

            -- Track
            local track = new("Frame", {
                Position = UDim2.new(1,-72,0.5,-14), Size = UDim2.new(0,56,0,28),
                BackgroundColor3 = Color3.fromRGB(50,50,75), Parent = T
            })
            new("UICorner", {CornerRadius = UDim.new(1,0), Parent = track})

            -- Fill (accent)
            local fill = new("Frame", {
                Size = UDim2.new(1,0,1,0),
                BackgroundColor3 = Library.Config.MainColor,
                BackgroundTransparency = state and 0 or 1,
                Parent = track
            })
            table.insert(Library.Elements.Accents, fill)
            new("UICorner", {CornerRadius = UDim.new(1,0), Parent = fill})

            -- Knob
            local knob = new("Frame", {
                Position = state and UDim2.new(1,-26,0.5,-11) or UDim2.new(0,4,0.5,-11),
                Size = UDim2.new(0,22,0,22),
                BackgroundColor3 = Color3.new(1,1,1), Parent = track
            })
            new("UICorner", {CornerRadius = UDim.new(1,0), Parent = knob})
            new("UIStroke", {Color = Color3.fromRGB(200,200,200), Thickness = 0.5, Parent = knob})

            T.MouseButton1Click:Connect(function()
                state = not state
                tweenPlay(knob, 0.28, {
                    Position = state and UDim2.new(1,-26,0.5,-11) or UDim2.new(0,4,0.5,-11)
                })
                tweenPlay(fill, 0.28, {BackgroundTransparency = state and 0 or 1})
                tweenPlay(track, 0.28, {
                    BackgroundColor3 = state and Color3.fromRGB(40,40,65) or Color3.fromRGB(50,50,75)
                })
                if callback then callback(state) end
            end)

            -- Hover
            T.MouseEnter:Connect(function() tweenPlay(T, 0.15, {BackgroundColor3 = Color3.fromRGB(38,38,50)}) end)
            T.MouseLeave:Connect(function() tweenPlay(T, 0.15, {BackgroundColor3 = Library.Config.SecondaryColor}) end)

            local ToggleObj = {}
            function ToggleObj:Set(val)
                state = val
                tweenPlay(knob, 0.28, {
                    Position = state and UDim2.new(1,-26,0.5,-11) or UDim2.new(0,4,0.5,-11)
                })
                tweenPlay(fill, 0.28, {BackgroundTransparency = state and 0 or 1})
                if callback then callback(state) end
            end
            function ToggleObj:Get() return state end
            return ToggleObj
        end

        -- ── Slider (fixed: touch support + label update) ──
        function Tab:CreateSlider(n, min, max, default, callback)
            local val = math.clamp(default or min, min, max)

            local S = new("Frame", {
                Size = UDim2.new(1,0,0,82), BackgroundColor3 = Library.Config.SecondaryColor,
                Parent = page
            })
            new("UICorner", {CornerRadius = Library.Config.CornerRadius, Parent = S})
            new("UIStroke", {Color = Library.Config.UIStrokeColor, Thickness = 1, Parent = S})

            local header = new("TextLabel", {
                Position = UDim2.new(0,16,0,8), Size = UDim2.new(1,-90,0,28),
                BackgroundTransparency = 1, Text = n,
                TextColor3 = Color3.new(1,1,1), TextSize = 18,
                FontFace = Library.Config.Font, TextXAlignment = Enum.TextXAlignment.Left,
                Parent = S
            })
            local valLabel = new("TextLabel", {
                Position = UDim2.new(1,-85,0,8), Size = UDim2.new(0,70,0,28),
                BackgroundTransparency = 1, Text = tostring(val),
                TextColor3 = Library.Config.MainColor, TextSize = 18,
                FontFace = Library.Config.Font, TextXAlignment = Enum.TextXAlignment.Right,
                Parent = S
            })
            table.insert(Library.Elements.Accents, valLabel)

            local track = new("Frame", {
                Position = UDim2.new(0,16,0,52), Size = UDim2.new(1,-32,0,10),
                BackgroundColor3 = Color3.fromRGB(60,60,90), Parent = S
            })
            new("UICorner", {CornerRadius = UDim.new(1,0), Parent = track})

            local fill = new("Frame", {
                Size = UDim2.new((val-min)/(max-min), 0, 1, 0),
                BackgroundColor3 = Library.Config.MainColor, Parent = track
            })
            table.insert(Library.Elements.Accents, fill)
            new("UICorner", {CornerRadius = UDim.new(1,0), Parent = fill})

            local knob = new("Frame", {
                Size = UDim2.new(0,18,0,18), AnchorPoint = Vector2.new(0.5,0.5),
                Position = UDim2.new((val-min)/(max-min), 0, 0.5, 0),
                BackgroundColor3 = Color3.new(1,1,1), Parent = track
            })
            new("UICorner", {CornerRadius = UDim.new(1,0), Parent = knob})

            local function updateSlider(mouseX)
                local pct = math.clamp((mouseX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                val = math.floor(min + (max - min) * pct)
                fill.Size    = UDim2.new(pct, 0, 1, 0)
                knob.Position = UDim2.new(pct, 0, 0.5, 0)
                valLabel.Text = tostring(val)
                if callback then callback(val) end
            end

            local sliding = false
            track.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1
                or inp.UserInputType == Enum.UserInputType.Touch then
                    sliding = true
                    updateSlider(inp.Position.X)
                end
            end)
            Library:Connect(UIS.InputEnded, function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1
                or inp.UserInputType == Enum.UserInputType.Touch then
                    sliding = false
                end
            end)
            Library:Connect(UIS.InputChanged, function(inp)
                if sliding and (inp.UserInputType == Enum.UserInputType.MouseMovement
                or inp.UserInputType == Enum.UserInputType.Touch) then
                    updateSlider(inp.Position.X)
                end
            end)

            local SliderObj = {}
            function SliderObj:Set(newVal)
                val = math.clamp(newVal, min, max)
                local pct = (val - min) / (max - min)
                fill.Size    = UDim2.new(pct, 0, 1, 0)
                knob.Position = UDim2.new(pct, 0, 0.5, 0)
                valLabel.Text = tostring(val)
                if callback then callback(val) end
            end
            function SliderObj:Get() return val end
            return SliderObj
        end

        -- ── Dropdown (fixed: scroll + proper close) ──
        function Tab:CreateDropdown(n, options, callback)
            local selected = options[1] or "None"
            local opened   = false

            local wrapper = new("Frame", {
                Size = UDim2.new(1,0,0,60), BackgroundColor3 = Library.Config.SecondaryColor,
                ClipsDescendants = true, Parent = page
            })
            new("UICorner", {CornerRadius = Library.Config.CornerRadius, Parent = wrapper})
            new("UIStroke", {Color = Library.Config.UIStrokeColor, Thickness = 1, Parent = wrapper})

            local headerBtn = new("TextButton", {
                Size = UDim2.new(1,0,0,60), BackgroundTransparency = 1, Text = "",
                Parent = wrapper
            })

            new("TextLabel", {
                Position = UDim2.new(0,16,0,0), Size = UDim2.new(0.5,0,1,0),
                BackgroundTransparency = 1, Text = n,
                TextColor3 = Color3.new(1,1,1), TextSize = 18,
                FontFace = Library.Config.Font, TextXAlignment = Enum.TextXAlignment.Left,
                Parent = headerBtn
            })

            local selectedLb = new("TextLabel", {
                Position = UDim2.new(0.5,0,0,14), Size = UDim2.new(0.42,0,0,32),
                BackgroundColor3 = Color3.fromRGB(55,55,85), Text = selected,
                TextColor3 = Color3.new(1,1,1), TextSize = 16,
                FontFace = Library.Config.Font, Parent = wrapper
            })
            new("UICorner", {CornerRadius = UDim.new(0,6), Parent = selectedLb})

            local arrow = new("TextLabel", {
                Position = UDim2.new(1,-42,0,14), Size = UDim2.new(0,28,0,32),
                BackgroundTransparency = 1, Text = "▾",
                TextColor3 = Library.Config.MainColor, TextSize = 18,
                FontFace = Library.Config.Font, Parent = wrapper
            })
            table.insert(Library.Elements.Accents, arrow)

            local listFrame = new("ScrollingFrame", {
                Position = UDim2.new(0,8,0,68), Size = UDim2.new(1,-16,0,150),
                BackgroundTransparency = 1, ScrollBarThickness = 3,
                ScrollBarImageColor3 = Library.Config.MainColor,
                AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = wrapper
            })
            new("UIListLayout", {Padding = UDim.new(0,6), Parent = listFrame})

            for _, opt in ipairs(options) do
                local optBtn = new("TextButton", {
                    Size = UDim2.new(1,0,0,40),
                    BackgroundColor3 = Color3.fromRGB(55,55,88),
                    AutoButtonColor = false, Text = opt,
                    TextColor3 = Color3.new(1,1,1), TextSize = 17,
                    FontFace = Library.Config.Font, Parent = listFrame
                })
                new("UICorner", {CornerRadius = UDim.new(0,6), Parent = optBtn})

                optBtn.MouseEnter:Connect(function()
                    tweenPlay(optBtn, 0.15, {BackgroundColor3 = Library.Config.MainColor})
                end)
                optBtn.MouseLeave:Connect(function()
                    tweenPlay(optBtn, 0.15, {BackgroundColor3 = Color3.fromRGB(55,55,88)})
                end)
                optBtn.MouseButton1Click:Connect(function()
                    selected = opt
                    selectedLb.Text = opt
                    opened = false
                    arrow.Text = "▾"
                    wrapper:TweenSize(UDim2.new(1,0,0,60), "Out", "Quart", 0.3, true)
                    if callback then callback(opt) end
                end)
            end

            headerBtn.MouseButton1Click:Connect(function()
                opened = not opened
                arrow.Text = opened and "▴" or "▾"
                local targetH = opened and (68 + math.min(#options * 46 + 6, 160)) or 60
                wrapper:TweenSize(UDim2.new(1,0,0,targetH), "Out", "Quart", 0.3, true)
            end)

            local DropObj = {}
            function DropObj:Set(val)
                selected = val; selectedLb.Text = val
                if callback then callback(val) end
            end
            function DropObj:Get() return selected end
            return DropObj
        end

        -- ── Button ──
        function Tab:CreateButton(n, callback)
            local Bt = new("TextButton", {
                Size = UDim2.new(1,0,0,56), AutoButtonColor = false,
                BackgroundColor3 = Library.Config.SecondaryColor,
                Text = n, TextColor3 = Color3.new(1,1,1), TextSize = 19,
                FontFace = Library.Config.Font, Parent = page
            })
            new("UICorner", {CornerRadius = Library.Config.CornerRadius, Parent = Bt})
            local str = new("UIStroke", {
                Color = Library.Config.MainColor, Thickness = 1.2,
                Transparency = 0.5, Parent = Bt
            })
            table.insert(Library.Elements.Accents, str)

            Bt.MouseEnter:Connect(function()
                tweenPlay(Bt, 0.18, {BackgroundColor3 = Color3.fromRGB(42,42,55)})
                tweenPlay(str, 0.18, {Transparency = 0})
            end)
            Bt.MouseLeave:Connect(function()
                tweenPlay(Bt, 0.18, {BackgroundColor3 = Library.Config.SecondaryColor})
                tweenPlay(str, 0.18, {Transparency = 0.5})
            end)
            Bt.MouseButton1Down:Connect(function()
                tweenPlay(Bt, 0.08, {BackgroundColor3 = Color3.fromRGB(30,30,42)})
            end)
            Bt.MouseButton1Up:Connect(function()
                tweenPlay(Bt, 0.08, {BackgroundColor3 = Color3.fromRGB(42,42,55)})
            end)
            Bt.MouseButton1Click:Connect(function()
                if callback then callback() end
            end)
        end

        -- ── Keybind ──
        function Tab:CreateKeybind(n, default, callback)
            local current = default or Enum.KeyCode.F
            local binding = false

            local Kf = new("Frame", {
                Size = UDim2.new(1,0,0,58), BackgroundColor3 = Library.Config.SecondaryColor,
                Parent = page
            })
            new("UICorner", {CornerRadius = Library.Config.CornerRadius, Parent = Kf})
            new("UIStroke", {Color = Library.Config.UIStrokeColor, Thickness = 1, Parent = Kf})
            new("TextLabel", {
                Position = UDim2.new(0,16,0,0), Size = UDim2.new(0.55,0,1,0),
                BackgroundTransparency = 1, Text = n,
                TextColor3 = Color3.new(1,1,1), TextSize = 18,
                FontFace = Library.Config.Font, TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Kf
            })

            local Kb = new("TextButton", {
                Position = UDim2.new(1,-175,0.5,-16), Size = UDim2.new(0,160,0,32),
                BackgroundColor3 = Color3.fromRGB(60,60,95),
                Text = "[ " .. current.Name .. " ]",
                TextColor3 = Color3.new(1,1,1), TextSize = 16,
                FontFace = Library.Config.Font, Parent = Kf
            })
            new("UICorner", {CornerRadius = UDim.new(0,8), Parent = Kb})

            Kb.MouseButton1Click:Connect(function()
                if binding then return end
                binding  = true
                Kb.Text  = "[ ... ]"
                Kb.TextColor3 = Library.Config.MainColor
                local conn
                conn = UIS.InputBegan:Connect(function(i, gp)
                    if gp then return end
                    if i.UserInputType == Enum.UserInputType.Keyboard then
                        current  = i.KeyCode
                        Kb.Text  = "[ " .. current.Name .. " ]"
                        Kb.TextColor3 = Color3.new(1,1,1)
                        binding  = false
                        conn:Disconnect()
                        if callback then callback(current) end
                    end
                end)
            end)

            Library:Connect(UIS.InputBegan, function(i, gp)
                if not gp and not binding and i.KeyCode == current then
                    if callback then callback(current) end
                end
            end)
        end

        -- ── Color Picker ──
        function Tab:CreateColorPicker(n, default, callback)
            local cur     = default or Library.Config.MainColor
            local h, s, v = cur:ToHSV()
            local savedH, savedS, savedV = h, s, v
            local opened = false

            local Cp = new("Frame", {
                Size = UDim2.new(1,0,0,58), BackgroundColor3 = Library.Config.SecondaryColor,
                ClipsDescendants = true, Parent = page
            })
            new("UICorner", {CornerRadius = Library.Config.CornerRadius, Parent = Cp})
            new("UIStroke", {Color = Library.Config.UIStrokeColor, Thickness = 1, Parent = Cp})

            local Btn = new("TextButton", {
                Size = UDim2.new(1,0,0,58), BackgroundTransparency = 1, Text = "  " .. n,
                TextColor3 = Color3.new(1,1,1), TextSize = 18,
                FontFace = Library.Config.Font, TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Cp
            })
            local previewBox = new("Frame", {
                Position = UDim2.new(1,-68,0.5,-13), Size = UDim2.new(0,52,0,26),
                BackgroundColor3 = cur, Parent = Cp
            })
            new("UICorner", {CornerRadius = UDim.new(0,5), Parent = previewBox})
            new("UIStroke", {Color = Library.Config.UIStrokeColor, Thickness = 1, Parent = previewBox})

            -- Expanded content
            local Exp = new("Frame", {
                Position = UDim2.new(0,0,0,58), Size = UDim2.new(1,0,0,200),
                BackgroundTransparency = 1, Parent = Cp
            })

            -- SV map
            local Map = new("Frame", {
                Position = UDim2.new(0,14,0,8), Size = UDim2.new(0,138,0,138),
                BackgroundColor3 = Color3.fromHSV(h,1,1), Parent = Exp
            })
            new("UICorner", {CornerRadius = UDim.new(0,4), Parent = Map})
            local wg = new("Frame", {Size = UDim2.new(1,0,1,0), BackgroundColor3 = Color3.new(1,1,1), Parent = Map})
            new("UICorner", {CornerRadius = UDim.new(0,4), Parent = wg})
            new("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)}), Parent = wg})
            local bg = new("Frame", {Size = UDim2.new(1,0,1,0), BackgroundColor3 = Color3.new(0,0,0), Parent = Map})
            new("UICorner", {CornerRadius = UDim.new(0,4), Parent = bg})
            new("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0)}), Rotation = 90, Parent = bg})

            local mapKnob = new("Frame", {
                Size = UDim2.new(0,14,0,14), AnchorPoint = Vector2.new(0.5,0.5),
                Position = UDim2.new(s,0,1-v,0), BackgroundColor3 = cur, Parent = Map
            })
            new("UICorner", {CornerRadius = UDim.new(1,0), Parent = mapKnob})
            new("UIStroke", {Color = Color3.new(1,1,1), Thickness = 2, Parent = mapKnob})

            -- Hue slider
            local HueBar = new("Frame", {
                Position = UDim2.new(0,168,0,8), Size = UDim2.new(0,18,0,138),
                BackgroundColor3 = Color3.new(1,1,1), Parent = Exp
            })
            new("UICorner", {CornerRadius = UDim.new(0,4), Parent = HueBar})
            new("UIGradient", {
                Rotation = 90,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0,   Color3.fromRGB(255,0,0)),
                    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
                    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
                    ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(0,255,255)),
                    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
                    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
                    ColorSequenceKeypoint.new(1,    Color3.fromRGB(255,0,0)),
                }),
                Parent = HueBar
            })
            local hueKnob = new("Frame", {
                Size = UDim2.new(1,8,0,4), Position = UDim2.new(0,-4,h,0),
                AnchorPoint = Vector2.new(0,0.5),
                BackgroundColor3 = Color3.new(1,1,1), Parent = HueBar
            })
            new("UIStroke", {Color = Color3.new(0,0,0), Thickness = 1, Parent = hueKnob})

            -- Hex input
            local hexBox = new("TextBox", {
                Position = UDim2.new(0,14,0,154), Size = UDim2.new(0,120,0,26),
                BackgroundColor3 = Color3.fromRGB(40,40,60),
                Text = "#" .. cur:ToHex(), TextColor3 = Color3.new(1,1,1),
                TextSize = 14, FontFace = Library.Config.Font,
                TextXAlignment = Enum.TextXAlignment.Center, Parent = Exp
            })
            new("UICorner", {CornerRadius = UDim.new(0,5), Parent = hexBox})

            local okBtn = new("TextButton", {
                Position = UDim2.new(0,144,0,154), Size = UDim2.new(0,40,0,26),
                BackgroundColor3 = Library.Config.MainColor,
                Text = "OK", TextColor3 = Color3.new(1,1,1), TextSize = 14,
                FontFace = Library.Config.Font, Parent = Exp
            })
            new("UICorner", {CornerRadius = UDim.new(0,5), Parent = okBtn})
            table.insert(Library.Elements.Accents, okBtn)

            local cancelBtn = new("TextButton", {
                Position = UDim2.new(0,192,0,154), Size = UDim2.new(0,40,0,26),
                BackgroundColor3 = Color3.fromRGB(50,50,70),
                Text = "✖", TextColor3 = Color3.new(1,1,1), TextSize = 14,
                FontFace = Library.Config.Font, Parent = Exp
            })
            new("UICorner", {CornerRadius = UDim.new(0,5), Parent = cancelBtn})

            local function refreshVisuals()
                cur = Color3.fromHSV(h, s, v)
                previewBox.BackgroundColor3 = cur
                mapKnob.BackgroundColor3    = cur
                mapKnob.Position = UDim2.new(s, 0, 1-v, 0)
                hueKnob.Position = UDim2.new(0, -4, h, 0)
                Map.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                hexBox.Text = "#" .. cur:ToHex()
                if callback then callback(cur) end
            end

            local mapDown, hueDown = false, false

            Map.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    mapDown = true
                    s = math.clamp((inp.Position.X - Map.AbsolutePosition.X) / Map.AbsoluteSize.X, 0, 1)
                    v = 1 - math.clamp((inp.Position.Y - Map.AbsolutePosition.Y) / Map.AbsoluteSize.Y, 0, 1)
                    refreshVisuals()
                end
            end)
            HueBar.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    hueDown = true
                    h = math.clamp((inp.Position.Y - HueBar.AbsolutePosition.Y) / HueBar.AbsoluteSize.Y, 0, 1)
                    refreshVisuals()
                end
            end)
            Library:Connect(UIS.InputEnded, function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    mapDown = false; hueDown = false
                end
            end)
            Library:Connect(UIS.InputChanged, function(inp)
                if inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                if mapDown then
                    s = math.clamp((inp.Position.X - Map.AbsolutePosition.X) / Map.AbsoluteSize.X, 0, 1)
                    v = 1 - math.clamp((inp.Position.Y - Map.AbsolutePosition.Y) / Map.AbsoluteSize.Y, 0, 1)
                    refreshVisuals()
                elseif hueDown then
                    h = math.clamp((inp.Position.Y - HueBar.AbsolutePosition.Y) / HueBar.AbsoluteSize.Y, 0, 1)
                    refreshVisuals()
                end
            end)

            hexBox.FocusLost:Connect(function()
                local ok, col = pcall(Color3.fromHex, hexBox.Text:gsub("#",""))
                if ok then h, s, v = col:ToHSV(); refreshVisuals()
                else hexBox.Text = "#" .. cur:ToHex() end
            end)

            okBtn.MouseButton1Click:Connect(function()
                savedH, savedS, savedV = h, s, v
                opened = false
                Cp:TweenSize(UDim2.new(1,0,0,58), "Out", "Quart", 0.3, true)
            end)
            cancelBtn.MouseButton1Click:Connect(function()
                h, s, v = savedH, savedS, savedV
                refreshVisuals()
                opened = false
                Cp:TweenSize(UDim2.new(1,0,0,58), "Out", "Quart", 0.3, true)
            end)

            Btn.MouseButton1Click:Connect(function()
                opened = not opened
                Cp:TweenSize(
                    opened and UDim2.new(1,0,0,268) or UDim2.new(1,0,0,58),
                    "Out", "Quart", 0.3, true
                )
            end)

            refreshVisuals()
        end

        -- ── Textbox ──
        function Tab:CreateTextbox(n, placeholder, callback)
            local Tf = new("Frame", {
                Size = UDim2.new(1,0,0,58), BackgroundColor3 = Library.Config.SecondaryColor,
                Parent = page
            })
            new("UICorner", {CornerRadius = Library.Config.CornerRadius, Parent = Tf})
            new("UIStroke", {Color = Library.Config.UIStrokeColor, Thickness = 1, Parent = Tf})
            new("TextLabel", {
                Position = UDim2.new(0,16,0,0), Size = UDim2.new(0.4,0,1,0),
                BackgroundTransparency = 1, Text = n,
                TextColor3 = Color3.new(1,1,1), TextSize = 18,
                FontFace = Library.Config.Font, TextXAlignment = Enum.TextXAlignment.Left,
                Parent = Tf
            })
            local inp = new("TextBox", {
                Position = UDim2.new(0.42,0,0.18,0), Size = UDim2.new(0.54,0,0.64,0),
                BackgroundColor3 = Color3.fromRGB(55,55,85),
                PlaceholderText = placeholder or "", Text = "",
                TextColor3 = Color3.new(1,1,1), TextSize = 17,
                FontFace = Library.Config.Font, Parent = Tf
            })
            new("UICorner", {CornerRadius = UDim.new(0,7), Parent = inp})

            inp.FocusLost:Connect(function(enter)
                if enter and callback then callback(inp.Text) end
            end)

            local TbObj = {}
            function TbObj:Get() return inp.Text end
            function TbObj:Set(val) inp.Text = val end
            return TbObj
        end

        -- ── Discord Invite ──
        function Tab:CreateDiscordInvite(title, serverName, icon, link)
            local wrap = new("Frame", {
                Size = UDim2.new(1,0,0,106), BackgroundTransparency = 1, Parent = page
            })
            new("TextLabel", {
                Size = UDim2.new(1,0,0,20), BackgroundTransparency = 1,
                Text = "  " .. (title or "Discord Server"),
                TextColor3 = Color3.fromRGB(88,175,255), TextSize = 14,
                FontFace = Library.Config.Font, TextXAlignment = Enum.TextXAlignment.Left,
                Parent = wrap
            })
            local box = new("Frame", {
                Position = UDim2.new(0,0,0,24), Size = UDim2.new(1,0,0,82),
                BackgroundColor3 = Library.Config.SecondaryColor, Parent = wrap
            })
            new("UICorner", {CornerRadius = Library.Config.CornerRadius, Parent = box})

            local ic = new("ImageLabel", {
                Position = UDim2.new(0,10,0,10), Size = UDim2.new(0,34,0,34),
                BackgroundColor3 = Library.Config.BackgroundColor,
                Image = icon or "rbxassetid://6023454032", Parent = box
            })
            new("UICorner", {CornerRadius = UDim.new(0,6), Parent = ic})

            new("TextLabel", {
                Position = UDim2.new(0,54,0,10), Size = UDim2.new(1,-64,0,18),
                BackgroundTransparency = 1, Text = serverName or "Server Name",
                TextColor3 = Color3.new(1,1,1), TextSize = 16,
                FontFace = Library.Config.Font, TextXAlignment = Enum.TextXAlignment.Left,
                Parent = box
            })
            new("TextLabel", {
                Position = UDim2.new(0,54,0,28), Size = UDim2.new(1,-64,0,14),
                BackgroundTransparency = 1, Text = "Click to copy invite link",
                TextColor3 = Color3.fromRGB(140,140,155), TextSize = 13,
                FontFace = Library.Config.Font, TextXAlignment = Enum.TextXAlignment.Left,
                Parent = box
            })

            local joinBtn = new("TextButton", {
                Position = UDim2.new(0,10,0,52), Size = UDim2.new(1,-20,0,24),
                BackgroundColor3 = Color3.fromRGB(67,181,129), AutoButtonColor = false,
                Text = "Join Server", TextColor3 = Color3.new(1,1,1), TextSize = 14,
                FontFace = Library.Config.Font, Parent = box
            })
            new("UICorner", {CornerRadius = UDim.new(0,5), Parent = joinBtn})
            joinBtn.MouseEnter:Connect(function() tweenPlay(joinBtn, 0.2, {BackgroundColor3 = Color3.fromRGB(50,160,110)}) end)
            joinBtn.MouseLeave:Connect(function() tweenPlay(joinBtn, 0.2, {BackgroundColor3 = Color3.fromRGB(67,181,129)}) end)

            joinBtn.MouseButton1Click:Connect(function()
                if not link then return end
                task.spawn(function()
                    local env = getfenv()
                    local setclip = env.setclipboard or env.toclipboard
                    if setclip then
                        pcall(setclip, link)
                        Library:Notify("Discord", "Copied invite to clipboard!", 3)
                    end
                end)
            end)
        end

        return Tab
    end -- CreateTab

    -- ┌─────────────────────────────────┐
    -- │         NOTIFICATIONS           │
    -- └─────────────────────────────────┘
    function Library:Notify(title, desc, duration)
        if not self.NotifyUI or not self.NotifyUI.Parent then
            self.NotifyUI = new("ScreenGui", {
                Name = "VortexNotify", ResetOnSpawn = false,
                DisplayOrder = 500, Parent = PlayerGui
            })
            self.NotifyContainer = new("Frame", {
                Size = UDim2.new(0,320,1,-16),
                AnchorPoint = Vector2.new(1,1),
                Position = UDim2.new(1,-12,1,0),
                BackgroundTransparency = 1, Parent = self.NotifyUI
            })
            local ns = new("UIScale", {Scale = self.Config.Scale, Parent = self.NotifyContainer})
            table.insert(self.Elements.Scales, ns)
            new("UIListLayout", {
                Padding = UDim.new(0,10),
                VerticalAlignment   = Enum.VerticalAlignment.Bottom,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                Parent = self.NotifyContainer
            })
        end

        task.spawn(function()
            local nwrap = new("Frame", {
                Size = UDim2.new(0,320,0,90), BackgroundTransparency = 1,
                ClipsDescendants = true, Parent = self.NotifyContainer
            })

            local nf = new("Frame", {
                Size = UDim2.new(1,0,1,0),
                Position = UDim2.new(1,350,0,0),
                BackgroundColor3 = self.Config.BackgroundColor,
                BackgroundTransparency = 0.05, Parent = nwrap
            })
            new("UICorner", {CornerRadius = self.Config.CornerRadius, Parent = nf})
            local ns2 = new("UIStroke", {Color = self.Config.MainColor, Thickness = 1.8, Parent = nf})
            table.insert(self.Elements.Accents, ns2)

            -- Accent bar
            local accentBar = new("Frame", {
                Size = UDim2.new(0,4,1,0), BackgroundColor3 = self.Config.MainColor, Parent = nf
            })
            table.insert(self.Elements.Accents, accentBar)
            new("UICorner", {CornerRadius = UDim.new(0,4), Parent = accentBar})

            new("TextLabel", {
                Position = UDim2.new(0,16,0,8), Size = UDim2.new(1,-24,0,30),
                BackgroundTransparency = 1, Text = title,
                TextColor3 = Color3.new(1,1,1), TextSize = 20,
                FontFace = self.Config.Font, TextXAlignment = Enum.TextXAlignment.Left,
                Parent = nf
            })
            new("TextLabel", {
                Position = UDim2.new(0,16,0,36), Size = UDim2.new(1,-24,0,46),
                BackgroundTransparency = 1, Text = desc,
                TextColor3 = Color3.fromRGB(210,210,220), TextSize = 16,
                FontFace = self.Config.Font, TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true,
                Parent = nf
            })

            -- Progress bar
            local prog = new("Frame", {
                Position = UDim2.new(0,0,1,-3), Size = UDim2.new(1,0,0,3),
                BackgroundColor3 = self.Config.MainColor, Parent = nf
            })
            table.insert(self.Elements.Accents, prog)

            -- Slide in
            tweenPlay(nf, 0.45, {Position = UDim2.new(0,0,0,0)}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            -- Progress shrink
            local dur = duration or 4
            tween(prog, TweenInfo.new(dur, Enum.EasingStyle.Linear), {Size = UDim2.new(0,0,0,3)}):Play()

            local dismissed = false
            nf.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    dismissed = true
                end
            end)

            task.wait(dur)
            if not dismissed then end -- just wait out duration naturally

            -- Slide out
            tweenPlay(nf, 0.4, {Position = UDim2.new(1,350,0,0)}, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
            tween(nwrap, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.new(0,320,0,0)}):Play()
            task.delay(0.4, function() if nwrap.Parent then nwrap:Destroy() end end)
        end)
    end

    return Window
end -- CreateWindow

-- ═══════════════════════════════════════════════
--              MASTER EXECUTION
-- ═══════════════════════════════════════════════
local Win = Library:CreateWindow("VORTEX HUB V3")
Library:Notify("Loaded", "Welcome, " .. LocalPlayer.Name .. "! Vortex Hub V3 is ready.", 5)

-- ── TAB: PLAYER ────────────────────────────────
local MainTab = Win:CreateTab("Player", "rbxassetid://6023454032")
MainTab:CreateSection("Movement")

MainTab:CreateSlider("WalkSpeed", 16, 250, 16, function(val)
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = val end
    end
end)

MainTab:CreateSlider("JumpPower", 50, 500, 50, function(val)
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = val end
    end
end)

MainTab:CreateToggle("Infinite Jump", false, function(state)
    _G.InfJump = state
    if state and not _G.InfJumpConn then
        _G.InfJumpConn = UIS.JumpRequest:Connect(function()
            if not _G.InfJump then return end
            local char = LocalPlayer.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end)
    elseif not state and _G.InfJumpConn then
        _G.InfJumpConn:Disconnect()
        _G.InfJumpConn = nil
    end
end)

MainTab:CreateToggle("Noclip", false, function(state)
    _G.Noclip = state
    if state and not _G.NoclipConn then
        _G.NoclipConn = RunSvc.Stepped:Connect(function()
            if not _G.Noclip then return end
            local char = LocalPlayer.Character
            if not char then return end
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then
                    p.CanCollide = false
                end
            end
        end)
    elseif not state and _G.NoclipConn then
        _G.NoclipConn:Disconnect()
        _G.NoclipConn = nil
    end
end)

MainTab:CreateSection("Utility")
MainTab:CreateToggle("Anti-AFK", false, function(state)
    if state then
        if not _G.AntiAFK then
            _G.AntiAFK = LocalPlayer.Idled:Connect(function()
                local vu = game:GetService("VirtualUser")
                vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(1)
                vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
        end
        Library:Notify("Anti-AFK", "Enabled — you won't be disconnected.", 3)
    else
        if _G.AntiAFK then _G.AntiAFK:Disconnect(); _G.AntiAFK = nil end
        Library:Notify("Anti-AFK", "Disabled.", 3)
    end
end)

MainTab:CreateButton("Reset Character", function()
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.Health = 0 end
end)

MainTab:CreateDiscordInvite("Vortex Community", "Vortex Hub", "rbxassetid://15222216598", "https://discord.gg/vortex")

-- ── TAB: COMBAT ────────────────────────────────
local CombatTab = Win:CreateTab("Combat & Farm", "rbxassetid://6034503041")
CombatTab:CreateSection("Auto Farming")

CombatTab:CreateToggle("Auto-Farm Mobs", false, function(state)
    _G.AutoFarm = state
    if state then
        task.spawn(function()
            while _G.AutoFarm do
                task.wait(0.5)
                pcall(function()
                    -- Game-specific farm logic goes here
                end)
            end
        end)
    end
end)

CombatTab:CreateToggle("Auto-Collect Drops", false, function(state)
    _G.AutoCollect = state
end)

CombatTab:CreateSection("Combat")
CombatTab:CreateToggle("Hitbox Expander", false, function(state)
    _G.Hitbox = state
    if state and not _G.HitboxConn then
        _G.HitboxConn = RunSvc.Heartbeat:Connect(function()
            if not _G.Hitbox then return end
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local root = p.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        root.Size        = Vector3.new(10,10,10)
                        root.Transparency = 0.8
                        root.CanCollide  = false
                    end
                end
            end
        end)
    elseif not state and _G.HitboxConn then
        _G.HitboxConn:Disconnect()
        _G.HitboxConn = nil
    end
end)

CombatTab:CreateButton("Kill Aura", function()
    Library:CreateDialog({
        Title = "Warning",
        Content = "Kill Aura carries a ban risk. Proceed?",
        Button1 = "Execute", Button2 = "Cancel",
        Callback1 = function()
            Library:Notify("Combat", "Kill Aura activated.", 4)
        end
    })
end)

-- ── TAB: VISUALS ───────────────────────────────
local VisualTab = Win:CreateTab("Visuals (ESP)", "rbxassetid://6034502932")
VisualTab:CreateSection("ESP")

VisualTab:CreateToggle("Name ESP", false, function(state)
    _G.NameESP = state
    if state then
        task.spawn(function()
            while _G.NameESP do
                task.wait(0.5)
                pcall(function()
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and p.Character then
                            local head = p.Character:FindFirstChild("Head")
                            if head and not head:FindFirstChild("VESP") then
                                local bg = Instance.new("BillboardGui", head)
                                bg.Name = "VESP"; bg.Size = UDim2.new(0,100,0,36)
                                bg.AlwaysOnTop = true; bg.StudsOffset = Vector3.new(0,2.5,0)
                                local lb = Instance.new("TextLabel", bg)
                                lb.Size = UDim2.new(1,0,1,0); lb.BackgroundTransparency = 1
                                lb.Text = p.Name; lb.TextColor3 = Color3.fromRGB(255,100,100)
                                lb.TextStrokeTransparency = 0; lb.Font = Enum.Font.GothamBold
                                lb.TextSize = 14
                            end
                        end
                    end
                end)
            end
        end)
    else
        pcall(function()
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then
                    local head = p.Character:FindFirstChild("Head")
                    if head then
                        local esp = head:FindFirstChild("VESP")
                        if esp then esp:Destroy() end
                    end
                end
            end
        end)
    end
    Library:Notify("ESP", "Name ESP: " .. tostring(state), 3)
end)

VisualTab:CreateToggle("Chams (Wallhack)", false, function(state)
    _G.Chams = state
    if state then
        task.spawn(function()
            while _G.Chams do
                task.wait(0.5)
                pcall(function()
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and p.Character and not p.Character:FindFirstChild("VCham") then
                            local hl = Instance.new("Highlight", p.Character)
                            hl.Name = "VCham"
                            hl.FillColor        = Color3.fromRGB(255,0,0)
                            hl.OutlineColor     = Color3.fromRGB(255,255,255)
                            hl.FillTransparency = 0.55
                            hl.DepthMode        = Enum.HighlightDepthMode.AlwaysOnTop
                        end
                    end
                end)
            end
        end)
    else
        pcall(function()
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then
                    local c = p.Character:FindFirstChild("VCham")
                    if c then c:Destroy() end
                end
            end
        end)
    end
end)

VisualTab:CreateToggle("Full Bright", false, function(state)
    pcall(function()
        Lighting.Ambient  = state and Color3.new(1,1,1) or Color3.fromRGB(127,127,127)
        Lighting.Brightness = state and 2 or 1
    end)
end)

VisualTab:CreateSection("Aimbot Assistance")
VisualTab:CreateToggle("FOV Circle", false, function(state)
    _G.FOVEnabled = state
    if state then
        if not _G.FOVCircle then
            local ok, circle = pcall(function() return getfenv().Drawing.new("Circle") end)
            if ok and circle then
                _G.FOVCircle          = circle
                circle.Visible        = true
                circle.Radius         = 120
                circle.Color          = Color3.fromRGB(255,255,255)
                circle.Thickness      = 1.5
                circle.Filled         = false
                _G.FOVConn = RunSvc.RenderStepped:Connect(function()
                    if _G.FOVCircle then
                        _G.FOVCircle.Position = UIS:GetMouseLocation()
                    end
                end)
            end
        end
    else
        if _G.FOVCircle then _G.FOVCircle:Remove(); _G.FOVCircle = nil end
        if _G.FOVConn   then _G.FOVConn:Disconnect(); _G.FOVConn = nil end
    end
end)

-- ── TAB: TROLLING ──────────────────────────────
local TrollTab = Win:CreateTab("Trolling", "rbxassetid://6022668888")
TrollTab:CreateSection("Target")

local targetName = ""
TrollTab:CreateTextbox("Target Player", "Type name...", function(text)
    targetName = text
    Library:Notify("Target", "Set target: " .. text, 3)
end)

local function findTarget()
    for _, p in ipairs(Players:GetPlayers()) do
        if targetName ~= "" and p ~= LocalPlayer then
            if string.lower(string.sub(p.Name, 1, #targetName)) == string.lower(targetName) then
                return p
            end
        end
    end
    return nil
end

TrollTab:CreateSection("Actions")
TrollTab:CreateButton("Spectate Target", function()
    local t = findTarget()
    if t and t.Character then
        local hum = t.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            workspace.CurrentCamera.CameraSubject = hum
            Library:Notify("Spectate", "Spectating: " .. t.Name, 3)
        end
    else
        Library:Notify("Error", "Target not found!", 3)
    end
end)

TrollTab:CreateButton("Stop Spectating", function()
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum then workspace.CurrentCamera.CameraSubject = hum end
    Library:Notify("Camera", "Returned to own view.", 3)
end)

TrollTab:CreateButton("Teleport Behind Target", function()
    local t = findTarget()
    if t and t.Character then
        local tRoot = t.Character:FindFirstChild("HumanoidRootPart")
        local mChar = LocalPlayer.Character
        local mRoot = mChar and mChar:FindFirstChild("HumanoidRootPart")
        if tRoot and mRoot then
            mRoot.CFrame = tRoot.CFrame * CFrame.new(0, 0, 3.5)
            Library:Notify("Teleport", "Teleported behind " .. t.Name, 3)
        end
    else
        Library:Notify("Error", "Target not found!", 3)
    end
end)

-- ── TAB: SETTINGS ──────────────────────────────
local SettingsTab = Win:CreateTab("Settings", "rbxassetid://6031289116")
SettingsTab:CreateSection("Theme")

SettingsTab:CreateColorPicker("Accent Color", Library.Config.MainColor, function(c)
    Library.Config.MainColor = c
    Library:UpdateTheme()
end)

SettingsTab:CreateDropdown("Font", {"Gotham", "Roboto", "Code", "Sarpanch"}, function(v)
    local fontMap = {
        Gotham   = "rbxasset://fonts/families/GothamSSm.json",
        Roboto   = "rbxasset://fonts/families/Roboto.json",
        Code     = "rbxasset://fonts/families/Inconsolata.json",
        Sarpanch = "rbxasset://fonts/families/Sarpanch.json",
    }
    if fontMap[v] then
        Library.Config.Font = Font.new(fontMap[v], Enum.FontWeight.Bold, Enum.FontStyle.Italic)
        Library:UpdateTheme()
    end
end)

SettingsTab:CreateSlider("Background Opacity", 0, 100, 8, function(v)
    Library.Config.Transparency = v / 100
    Library:UpdateTheme()
end)

SettingsTab:CreateSlider("UI Scale", 60, 150, 100, function(v)
    Library:SetUIScale(v / 100)
end)

SettingsTab:CreateSection("Controls")
SettingsTab:CreateKeybind("Toggle Hub Key", Library.Config.ToggleKey, function(key)
    Library.Config.ToggleKey = key
    Library:Notify("Keybind", "Toggle key set to: " .. key.Name, 3)
end)

SettingsTab:CreateButton("Unload Script", function()
    Library:CreateDialog({
        Title = "Unload Hub",
        Content = "Are you sure you want to destroy Vortex Hub completely?",
        Button1 = "Destroy", Button2 = "Cancel",
        Callback1 = function() Library:Destroy() end
    })
end)

return Library
