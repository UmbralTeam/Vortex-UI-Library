local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or (Players:GetPropertyChangedSignal("LocalPlayer"):Wait() and Players.LocalPlayer)
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- [ نظام حماية محسّن لمنع تكرار الواجهات ]
local function CleanupUI()
    for _, gui in pairs(PlayerGui:GetChildren()) do
        if gui.Name == "VX_V20" or gui.Name == "VX_KeySys" or gui.Name == "VX_Dialog" then
            gui:Destroy()
        end
    end
end
CleanupUI()

-- [ CORE CONFIG ]
local Library = {
    Config = {
        MainColor = Color3.fromRGB(160, 80, 255),
        SecondaryColor = Color3.fromRGB(30, 30, 40),
        BackgroundColor = Color3.fromRGB(15, 15, 20),
        AccentColor = Color3.fromRGB(255, 255, 255),
        Transparency = 0.1,
        OptionSpacing = 16,
        UIStrokeColor = Color3.fromRGB(70, 70, 85),
        CornerRadius = UDim.new(0, 10),
        Scale = 1,
        Font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Italic),
        ToggleKey = Enum.KeyCode.RightControl
    },
    Elements = { Accents = {}, Gradients = {}, Fonts = {}, Backgrounds = {}, Scales = {} },
    Opened = true
}

-- [ UTILS ]
local function create(className, properties, parent)
    local instance = Instance.new(className)
    local targetParent = parent or properties.Parent
    for i, v in pairs(properties) do if i ~= "Parent" then instance[i] = v end end
    if targetParent then instance.Parent = targetParent end
    return instance
end

function Library:UpdateTheme()
    for _, obj in pairs(self.Elements.Accents) do if obj.Parent then obj.BackgroundColor3 = self.Config.MainColor end end
    for _, gra in pairs(self.Elements.Gradients) do if gra.Parent then gra.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, self.Config.MainColor), ColorSequenceKeypoint.new(1, Color3.new(0,0,0))}) end end
    for _, txt in pairs(self.Elements.Fonts) do if txt.Parent then txt.FontFace = self.Config.Font end end
end

function Library:CreateWindow(name)
    -- التأكد من عدم وجود واجهة سابقة قبل الإنشاء
    CleanupUI()

    local ScreenGui = create("ScreenGui", { Name = "VX_V20", ResetOnSpawn = false, DisplayOrder = 100, Parent = PlayerGui })
    
    local Frame = create("Frame", {
        Name = "MainFrame",
        Position = UDim2.new(0.5, -325, 0.5, -235),
        Size = UDim2.new(0, 650, 0, 470),
        BackgroundColor3 = self.Config.BackgroundColor,
        BackgroundTransparency = self.Config.Transparency,
        Parent = ScreenGui
    })
    
    table.insert(self.Elements.Backgrounds, Frame)
    local HubScale = create("UIScale", { Scale = self.Config.Scale or 1, Parent = Frame })
    table.insert(self.Elements.Scales, HubScale)
    create("UIStroke", { Color = self.Config.UIStrokeColor, Thickness = 1.8, Parent = Frame })
    create("UICorner", { CornerRadius = self.Config.CornerRadius, Parent = Frame })

    local TopBar = create("Frame", { Name = "TopBar", Size = UDim2.new(1, 0, 0, 65), BackgroundTransparency = 1, Parent = Frame })
    local Title = create("TextLabel", { Position = UDim2.new(0, 25, 0, 0), Size = UDim2.new(0, 250, 1, 0), BackgroundTransparency = 1, Text = name:upper(), TextColor3 = Color3.new(1, 1, 1), TextSize = 22, FontFace = self.Config.Font, TextXAlignment = Enum.TextXAlignment.Left, Parent = TopBar })
    table.insert(self.Elements.Fonts, Title)

    local CloseBtn = create("TextButton", { Position = UDim2.new(1, -45, 0, 16), Size = UDim2.new(0, 32, 0, 32), BackgroundColor3 = Color3.fromRGB(22, 22, 26), Text = "✖", TextColor3 = Color3.new(1,1,1), TextSize = 14, FontFace = self.Config.Font, Parent = TopBar })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = CloseBtn })
    CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

    local MinBtn = create("TextButton", { Position = UDim2.new(1, -85, 0, 16), Size = UDim2.new(0, 32, 0, 32), BackgroundColor3 = Color3.fromRGB(22, 22, 26), Text = "—", TextColor3 = Color3.new(1,1,1), TextSize = 14, FontFace = self.Config.Font, Parent = TopBar })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = MinBtn })
    
    UIS.InputBegan:Connect(function(i, gp)
        if not gp and i.KeyCode == self.Config.ToggleKey then
            Library.Opened = not Library.Opened
            Frame.Visible = Library.Opened
        end
    end)

    local Sidebar = create("ScrollingFrame", { Position = UDim2.new(0, 12, 0, 80), Size = UDim2.new(0, 180, 1, -135), BackgroundTransparency = 1, ScrollBarThickness = 0, Parent = Frame })
    create("UIListLayout", { Padding = UDim.new(0, 12), Parent = Sidebar })
    
    local TabContainer = create("Frame", { Position = UDim2.new(0, 205, 0, 80), Size = UDim2.new(1, -220, 1, -135), BackgroundTransparency = 1, Parent = Frame })
    
    local Footer = create("Frame", { Position = UDim2.new(0, 0, 1, -35), Size = UDim2.new(1, 0, 0, 35), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.85, Parent = Frame })
    local StatLabel = create("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "Vortex System Active | FPS: ...", TextColor3 = Color3.fromRGB(220, 220, 220), TextSize = 15, FontFace = self.Config.Font, Parent = Footer })

    -- Dragging Logic
    local dragging, dragStart, startPos
    Frame.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = i.Position; startPos = Frame.Position end end)
    UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then local delta = i.Position - dragStart; Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

    local Window = { Gui = ScreenGui, Frame = Frame, CurrentPage = nil, CurrentTab = nil }

    function Window:CreateTab(name, icon)
        local TabBtn = create("TextButton", { Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, Text = "", Parent = Sidebar })
        create("UICorner", { CornerRadius = Library.Config.CornerRadius, Parent = TabBtn })
        
        local TabBg = create("Frame", { Name = "Bg", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(1,1,1), BackgroundTransparency = 1, Visible = false, Parent = TabBtn })
        create("UICorner", { CornerRadius = Library.Config.CornerRadius, Parent = TabBg })
        local Gr = create("UIGradient", { Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Library.Config.MainColor), ColorSequenceKeypoint.new(1, Color3.new(0,0,0))}), Parent = TabBg })
        table.insert(Library.Elements.Gradients, Gr)

        local TabLb = create("TextLabel", { Name = "Lb", Position = UDim2.new(0, 50, 0, 0), Size = UDim2.new(1, -50, 1, 0), BackgroundTransparency = 1, Text = name, TextColor3 = Color3.fromRGB(180,180,200), TextSize = 18, FontFace = Library.Config.Font, TextXAlignment = Enum.TextXAlignment.Left, Parent = TabBtn })
        local TabIc = create("ImageLabel", { Name = "Ic", Position = UDim2.new(0, 18, 0.5, -12), Size = UDim2.new(0, 24, 0, 24), BackgroundTransparency = 1, Image = icon or "rbxassetid://6023454032", ImageColor3 = Color3.fromRGB(180,180,200), Parent = TabBtn })
        local TabInd = create("Frame", { Name = "Ind", Size = UDim2.new(0, 5, 0, 0), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = Library.Config.MainColor, AnchorPoint = Vector2.new(0, 0.5), Parent = TabBtn })
        table.insert(Library.Elements.Accents, TabInd); create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = TabInd })

        local Page = create("ScrollingFrame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, ScrollBarThickness = 2, AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = TabContainer })
        create("UIListLayout", { Padding = UDim.new(0, Library.Config.OptionSpacing), Parent = Page })
        create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = Page })

        TabBtn.MouseButton1Click:Connect(function()
            if Window.CurrentTab == name then return end
            if Window.CurrentPage then Window.CurrentPage.Visible = false end
            for _, b in pairs(Sidebar:GetChildren()) do
                if b:IsA("TextButton") then
                    local bg = b:FindFirstChild("Bg"); if bg then bg.Visible = false end
                    local ind = b:FindFirstChild("Ind"); if ind then TweenService:Create(ind, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Size = UDim2.new(0, 5, 0, 0)}):Play() end
                end
            end
            Window.CurrentPage = Page; Window.CurrentTab = name; Page.Visible = true; TabBg.Visible = true; TabBg.BackgroundTransparency = 0.4
            TweenService:Create(TabInd, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 5, 0, 32)}):Play()
        end)

        if not Window.CurrentTab then
            Window.CurrentPage = Page; Window.CurrentTab = name; Page.Visible = true; TabBg.Visible = true; TabBg.BackgroundTransparency = 0.4; TabInd.Size = UDim2.new(0, 5, 0, 32)
        end

        local Tab = {}
        function Tab:CreateButton(n, c)
            local Bt = create("TextButton", { Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = Library.Config.SecondaryColor, AutoButtonColor = false, Text = n, TextColor3 = Color3.new(1, 1, 1), TextSize = 19, FontFace = Library.Config.Font, Parent = Page })
            create("UICorner", { CornerRadius = Library.Config.CornerRadius, Parent = Bt })
            local Str = create("UIStroke", { Color = Library.Config.MainColor, Thickness = 1, Transparency = 0.5, Parent = Bt })
            table.insert(Library.Elements.Accents, Str)
            Bt.MouseButton1Click:Connect(c)
        end

        function Tab:CreateToggle(n, d, c)
            local T = create("TextButton", { Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = Library.Config.SecondaryColor, AutoButtonColor = false, Text = "  "..n, TextColor3 = Color3.new(1,1,1), TextSize = 19, FontFace = Library.Config.Font, TextXAlignment = Enum.TextXAlignment.Left, Parent = Page })
            create("UICorner", { CornerRadius = Library.Config.CornerRadius, Parent = T })
            local F = create("Frame", { Position = UDim2.new(1, -78, 0.5, -15), Size = UDim2.new(0, 62, 0, 32), BackgroundColor3 = Color3.fromRGB(60,60,95), Parent = T })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = F })
            local F_Acc = create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = d and 0 or 1, BackgroundColor3 = Library.Config.MainColor, Parent = F })
            table.insert(Library.Elements.Accents, F_Acc); create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = F_Acc })
            local D = create("Frame", { Position = d and UDim2.new(1, -30, 0.5, -13) or UDim2.new(0, 5, 0.5, -13), Size = UDim2.new(0, 26, 0, 26), BackgroundColor3 = Color3.new(1, 1, 1), Parent = F })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = D })
            T.MouseButton1Click:Connect(function() d = not d; TweenService:Create(D, TweenInfo.new(0.3), {Position = d and UDim2.new(1, -30, 0.5, -13) or UDim2.new(0, 5, 0.5, -13)}):Play(); TweenService:Create(F_Acc, TweenInfo.new(0.3), {BackgroundTransparency = d and 0 or 1}):Play(); c(d) end)
        end

        function Tab:CreateSlider(n, mi, ma, d, c)
            local S = create("Frame", { Size = UDim2.new(1, 0, 0, 90), BackgroundColor3 = Library.Config.SecondaryColor, Parent = Page })
            create("UICorner", { CornerRadius = Library.Config.CornerRadius, Parent = S })
            local L = create("TextLabel", { Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1, Text = "  "..n..": "..d, TextColor3 = Color3.new(1,1,1), TextSize = 19, FontFace = Library.Config.Font, TextXAlignment = Enum.TextXAlignment.Left, Parent = S })
            local B = create("TextButton", { Position = UDim2.new(0, 20, 0, 62), Size = UDim2.new(1, -40, 0, 14), BackgroundColor3 = Color3.fromRGB(75, 75, 105), Text = "", Parent = S })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = B })
            local Fl = create("Frame", { Size = UDim2.new((d-mi)/(ma-mi), 0, 1, 0), BackgroundColor3 = Library.Config.MainColor, Parent = B })
            table.insert(Library.Elements.Accents, Fl); create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Fl })
            local m = false; B.MouseButton1Down:Connect(function() m = true end)
            UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then m = false end end)
            UIS.InputChanged:Connect(function(i) if m and i.UserInputType == Enum.UserInputType.MouseMovement then local p = math.clamp((i.Position.X - B.AbsolutePosition.X)/B.AbsoluteSize.X, 0, 1); local v = math.floor(mi + (ma-mi)*p); Fl.Size = UDim2.new(p, 0, 1, 0); L.Text = "  "..n..": "..v; c(v) end end)
        end
        
        return Tab
    end
    return Window
end

return Library
