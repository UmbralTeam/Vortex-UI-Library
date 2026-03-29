local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or (Players:GetPropertyChangedSignal("LocalPlayer"):Wait() and Players.LocalPlayer)
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- [ RE-RUN PROTECTION ]
for _, v in pairs(PlayerGui:GetChildren()) do
    if v.Name == "VX_V20" or v.Name == "VX_KeySys" or v.Name == "VX_Dialog" or v.Name == "VortexNotify" then
        v:Destroy()
    end
end


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
    for _, bg in pairs(self.Elements.Backgrounds) do if bg.Parent then bg.BackgroundTransparency = self.Config.Transparency end end
end

function Library:SetUIScale(scale)
    self.Config.Scale = scale
    for _, s in pairs(self.Elements.Scales) do 
        if s.Parent then 
            TweenService:Create(s, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Scale = scale}):Play() 
        end 
    end
end
function Library:CreateKeySystem(config)
    local kName = config.Name or "Key System"
    local kNote = config.Note or "Please enter your premium key to continue."
    local expectedRawKey = config.Key or "VORTEX"
    local callback = config.Callback
    
    local ScreenGui = create("ScreenGui", { Name = "VX_KeySys", ResetOnSpawn = false, DisplayOrder = 200, Parent = PlayerGui })
    local KFrame = create("Frame", { Name = "KeyFrame", Position = UDim2.new(0.5, -200, 0.5, -125), Size = UDim2.new(0, 400, 0, 250), BackgroundColor3 = self.Config.BackgroundColor, BackgroundTransparency = self.Config.Transparency, Parent = ScreenGui })
    table.insert(self.Elements.Backgrounds, KFrame)
    local scale = create("UIScale", { Scale = self.Config.Scale or 1, Parent = KFrame })
    table.insert(self.Elements.Scales, scale)
    create("UICorner", { CornerRadius = self.Config.CornerRadius, Parent = KFrame })
    create("UIStroke", { Color = self.Config.UIStrokeColor, Thickness = 1.8, Parent = KFrame })
    
    create("TextLabel", { Position = UDim2.new(0, 20, 0, 20), Size = UDim2.new(1, -40, 0, 30), BackgroundTransparency = 1, Text = kName:upper(), TextColor3 = Color3.new(1,1,1), TextSize = 22, FontFace = self.Config.Font, TextXAlignment = Enum.TextXAlignment.Left, Parent = KFrame })
    create("TextLabel", { Position = UDim2.new(0, 20, 0, 50), Size = UDim2.new(1, -40, 0, 40), BackgroundTransparency = 1, Text = kNote, TextColor3 = Color3.fromRGB(180, 180, 180), TextSize = 16, FontFace = self.Config.Font, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = KFrame })
    
    local InpWrap = create("Frame", { Position = UDim2.new(0, 20, 0, 100), Size = UDim2.new(1, -40, 0, 50), BackgroundColor3 = self.Config.SecondaryColor, Parent = KFrame })
    create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = InpWrap })
    local Inp = create("TextBox", { Position = UDim2.new(0, 15, 0, 0), Size = UDim2.new(1, -30, 1, 0), BackgroundTransparency = 1, PlaceholderText = "Enter Key Here...", Text = "", TextColor3 = Color3.new(1,1,1), TextSize = 17, FontFace = self.Config.Font, TextXAlignment = Enum.TextXAlignment.Left, Parent = InpWrap })
    
    local SubBtn = create("TextButton", { Position = UDim2.new(0, 20, 0, 170), Size = UDim2.new(1, -40, 0, 50), BackgroundColor3 = self.Config.SecondaryColor, AutoButtonColor = false, Text = "Submit Key", TextColor3 = Color3.new(1,1,1), TextSize = 18, FontFace = self.Config.Font, Parent = KFrame })
    create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = SubBtn })
    local SubStr = create("UIStroke", { Color = self.Config.MainColor, Thickness = 1.5, Parent = SubBtn })
    table.insert(self.Elements.Accents, SubStr)
    
    local startPos, startDrag, dragging
    KFrame.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; startPos = inp.Position; startDrag = KFrame.Position end end)
    UIS.InputChanged:Connect(function(inp) if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then TweenService:Create(KFrame, TweenInfo.new(0.08), {Position = UDim2.new(startDrag.X.Scale, startDrag.X.Offset + (inp.Position - startPos).X, startDrag.Y.Scale, startDrag.Y.Offset + (inp.Position - startPos).Y)}):Play() end end)
    UIS.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    
    SubBtn.MouseEnter:Connect(function() TweenService:Create(SubBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 55)}):Play() end)
    SubBtn.MouseLeave:Connect(function() TweenService:Create(SubBtn, TweenInfo.new(0.2), {BackgroundColor3 = self.Config.SecondaryColor}):Play() end)
    
    SubBtn.MouseButton1Click:Connect(function()
        if Inp.Text == expectedRawKey then
            TweenService:Create(KFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)}):Play()
            task.wait(0.5)
            ScreenGui:Destroy()
            if callback then callback() end
        else
            Inp.Text = "INVALID KEY"
            task.wait(1)
            Inp.Text = ""
        end
    end)
end

function Library:CreateDialog(config)
    local ScreenGui = create("ScreenGui", { Name = "VX_Dialog", ResetOnSpawn = false, DisplayOrder = 300, Parent = PlayerGui })
    local DFrame = create("Frame", { Name = "DialogFrame", Position = UDim2.new(0.5, -175, 0.5, -100), Size = UDim2.new(0, 350, 0, 200), BackgroundColor3 = self.Config.BackgroundColor, BackgroundTransparency = self.Config.Transparency, Parent = ScreenGui })
    table.insert(self.Elements.Backgrounds, DFrame)
    local scale = create("UIScale", { Scale = self.Config.Scale or 1, Parent = DFrame })
    table.insert(self.Elements.Scales, scale)
    create("UICorner", { CornerRadius = self.Config.CornerRadius, Parent = DFrame })
    create("UIStroke", { Color = self.Config.UIStrokeColor, Thickness = 1.8, Parent = DFrame })
    
    create("TextLabel", { Position = UDim2.new(0, 20, 0, 20), Size = UDim2.new(1, -40, 0, 30), BackgroundTransparency = 1, Text = (config.Title or "Dialog"):upper(), TextColor3 = Color3.new(1,1,1), TextSize = 22, FontFace = self.Config.Font, TextXAlignment = Enum.TextXAlignment.Left, Parent = DFrame })
    create("TextLabel", { Position = UDim2.new(0, 20, 0, 55), Size = UDim2.new(1, -40, 0, 60), BackgroundTransparency = 1, Text = config.Content or "Are you sure?", TextColor3 = Color3.fromRGB(180, 180, 180), TextSize = 16, FontFace = self.Config.Font, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = DFrame })
    
    local B1 = create("TextButton", { Position = UDim2.new(0, 20, 1, -65), Size = UDim2.new(0.5, -25, 0, 45), BackgroundColor3 = self.Config.SecondaryColor, AutoButtonColor = false, Text = config.Button1 or "Confirm", TextColor3 = Color3.new(1,1,1), TextSize = 16, FontFace = self.Config.Font, Parent = DFrame })
    create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = B1 })
    local S1 = create("UIStroke", { Color = self.Config.MainColor, Thickness = 1.5, Parent = B1 }); table.insert(self.Elements.Accents, S1)
    
    local B2 = create("TextButton", { Position = UDim2.new(0.5, 5, 1, -65), Size = UDim2.new(0.5, -25, 0, 45), BackgroundColor3 = self.Config.SecondaryColor, AutoButtonColor = false, Text = config.Button2 or "Cancel", TextColor3 = Color3.new(1,1,1), TextSize = 16, FontFace = self.Config.Font, Parent = DFrame })
    create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = B2 })
    
    B1.MouseButton1Click:Connect(function() ScreenGui:Destroy(); if config.Callback1 then config.Callback1() end end)
    B2.MouseButton1Click:Connect(function() ScreenGui:Destroy(); if config.Callback2 then config.Callback2() end end)
    
    B1.MouseEnter:Connect(function() TweenService:Create(B1, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 55)}):Play() end); B1.MouseLeave:Connect(function() TweenService:Create(B1, TweenInfo.new(0.2), {BackgroundColor3 = self.Config.SecondaryColor}):Play() end)
    B2.MouseEnter:Connect(function() TweenService:Create(B2, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 55)}):Play() end); B2.MouseLeave:Connect(function() TweenService:Create(B2, TweenInfo.new(0.2), {BackgroundColor3 = self.Config.SecondaryColor}):Play() end)
    
    local startPos, startDrag, dragging
    DFrame.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; startPos = inp.Position; startDrag = DFrame.Position end end)
    UIS.InputChanged:Connect(function(inp) if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then TweenService:Create(DFrame, TweenInfo.new(0.08), {Position = UDim2.new(startDrag.X.Scale, startDrag.X.Offset + (inp.Position - startPos).X, startDrag.Y.Scale, startDrag.Y.Offset + (inp.Position - startPos).Y)}):Play() end end)
    UIS.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
end

function Library:CreateWindow(name)
    for _, v in pairs(PlayerGui:GetChildren()) do
        if v.Name == "VX_V20" then v:Destroy() end
    end
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

    -- TopBar 精品栏
    local TopBar = create("Frame", { Name = "TopBar", Size = UDim2.new(1, 0, 0, 65), BackgroundTransparency = 1, Parent = Frame })
    local Title = create("TextLabel", { Position = UDim2.new(0, 25, 0, 0), Size = UDim2.new(0, 250, 1, 0), BackgroundTransparency = 1, Text = name:upper(), TextColor3 = Color3.new(1, 1, 1), TextSize = 22, FontFace = self.Config.Font, TextXAlignment = Enum.TextXAlignment.Left, Parent = TopBar })
    table.insert(self.Elements.Fonts, Title)

    -- Close & Minimize Buttons
    local CloseBtn = create("TextButton", { Position = UDim2.new(1, -45, 0, 16), Size = UDim2.new(0, 32, 0, 32), BackgroundColor3 = Color3.fromRGB(22, 22, 26), Text = "✖", TextColor3 = Color3.new(1,1,1), TextSize = 14, FontFace = self.Config.Font, Parent = TopBar })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = CloseBtn })
    CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

    local MinBtn = create("TextButton", { Position = UDim2.new(1, -85, 0, 16), Size = UDim2.new(0, 32, 0, 32), BackgroundColor3 = Color3.fromRGB(22, 22, 26), Text = "—", TextColor3 = Color3.new(1,1,1), TextSize = 14, FontFace = self.Config.Font, Parent = TopBar })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = MinBtn })
    -- Global Toggle Key
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
    local StatLabel = create("TextLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "Monitoring Systems...", TextColor3 = Color3.fromRGB(220, 220, 220), TextSize = 15, FontFace = self.Config.Font, Parent = Footer })
    table.insert(self.Elements.Fonts, StatLabel)

    local currentSize = Vector2.new(650, 470)
    local Resizer = create("TextButton", { Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(1, -20, 1, -20), BackgroundTransparency = 1, Text = "◢", TextColor3 = Color3.fromRGB(150, 150, 150), TextSize = 14, FontFace = self.Config.Font, ZIndex = 100, Parent = Frame })

    local isMinimized = false
    local isMinimizing = false
    MinBtn.MouseButton1Click:Connect(function() 
        if isMinimizing then return end
        isMinimizing = true
        isMinimized = not isMinimized
        Frame.ClipsDescendants = true
        if isMinimized then
            local tw = TweenService:Create(Frame, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, currentSize.X, 0, 65)})
            tw:Play(); tw.Completed:Wait()
            Sidebar.Visible = false; TabContainer.Visible = false; Footer.Visible = false; Resizer.Visible = false
        else
            Sidebar.Visible = true; TabContainer.Visible = true; Footer.Visible = true; Resizer.Visible = true
            local tw = TweenService:Create(Frame, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, currentSize.X, 0, currentSize.Y)})
            tw:Play(); tw.Completed:Wait()
            Frame.ClipsDescendants = false
        end
        isMinimizing = false
    end)

    local Window = { Gui = ScreenGui, Frame = Frame, CurrentPage = nil, CurrentTab = nil }

    -- Dragging & Resizing
    local dragging, dragStart, startPos
    local resizing, resizeStart, startSizeXY
    
    Frame.InputBegan:Connect(function(i) 
        if i.UserInputType == Enum.UserInputType.MouseButton1 then 
            dragging = true; dragStart = i.Position; startPos = Frame.Position 
        end 
    end)
    
    Resizer.MouseButton1Down:Connect(function() 
        if isMinimized then return end
        resizing = true; resizeStart = UIS:GetMouseLocation(); startSizeXY = currentSize 
    end)

    UIS.InputChanged:Connect(function(i) 
        if i.UserInputType == Enum.UserInputType.MouseMovement then 
            if dragging then
                local delta = i.Position - dragStart
                Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) 
            elseif resizing then
                local p = UIS:GetMouseLocation()
                local newX = math.clamp(startSizeXY.X + (p.X - resizeStart.X), 450, 1200)
                local newY = math.clamp(startSizeXY.Y + (p.Y - resizeStart.Y), 300, 800)
                currentSize = Vector2.new(newX, newY)
                Frame.Size = UDim2.new(0, newX, 0, newY)
            end
        end 
    end)
    
    UIS.InputEnded:Connect(function(i) 
        if i.UserInputType == Enum.UserInputType.MouseButton1 then 
            dragging = false; resizing = false 
        end 
    end)

    function Window:CreateTab(name, icon)
        local TabBtn = create("TextButton", { Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, Text = "", Parent = Sidebar })
        create("UICorner", { CornerRadius = Library.Config.CornerRadius, Parent = TabBtn })
        
        local TabBg = create("Frame", { Name = "Bg", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(1,1,1), BackgroundTransparency = 1, Visible = false, Parent = TabBtn })
        create("UICorner", { CornerRadius = Library.Config.CornerRadius, Parent = TabBg })
        local Gr = create("UIGradient", { Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Library.Config.MainColor), ColorSequenceKeypoint.new(1, Color3.new(0,0,0))}), Parent = TabBg })
        table.insert(Library.Elements.Gradients, Gr)

        local TabLb = create("TextLabel", { Name = "Lb", Position = UDim2.new(0, 50, 0, 0), Size = UDim2.new(1, -50, 1, 0), BackgroundTransparency = 1, Text = name, TextColor3 = Color3.fromRGB(180,180,200), TextSize = 18, FontFace = Library.Config.Font, TextXAlignment = Enum.TextXAlignment.Left, Parent = TabBtn })
        table.insert(Library.Elements.Fonts, TabLb)
        local TabIc = create("ImageLabel", { Name = "Ic", Position = UDim2.new(0, 18, 0.5, -12), Size = UDim2.new(0, 24, 0, 24), BackgroundTransparency = 1, Image = icon or "rbxassetid://6023454032", ImageColor3 = Color3.fromRGB(180,180,200), Parent = TabBtn })
        local TabInd = create("Frame", { Name = "Ind", Size = UDim2.new(0, 5, 0, 0), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = Library.Config.MainColor, AnchorPoint = Vector2.new(0, 0.5), Parent = TabBtn })
        table.insert(Library.Elements.Accents, TabInd); create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = TabInd })

        TabBtn.MouseEnter:Connect(function() if Window.CurrentTab ~= name then TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.new(1,1,1), BackgroundTransparency = 0.96 }):Play() end end)
        TabBtn.MouseLeave:Connect(function() if Window.CurrentTab ~= name then TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 1 }):Play() end end)

        local Page = create("ScrollingFrame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, ScrollBarThickness = 2, AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = TabContainer })
        create("UIListLayout", { Padding = UDim.new(0, Library.Config.OptionSpacing), Parent = Page })
        create("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = Page })

        TabBtn.MouseButton1Click:Connect(function()
            if Window.CurrentTab == name then return end
            if Window.CurrentPage then Window.CurrentPage.Visible = false end
            for _, b in pairs(Sidebar:GetChildren()) do
                if b:IsA("TextButton") then
                    local bg = b:FindFirstChild("Bg"); if bg then bg.Visible = false end
                    local lb = b:FindFirstChild("Lb"); if lb then lb.TextColor3 = Color3.fromRGB(180,180,200) end
                    local ic = b:FindFirstChild("Ic"); if ic then ic.ImageColor3 = Color3.fromRGB(180,180,200) end
                    local ind = b:FindFirstChild("Ind"); if ind then TweenService:Create(ind, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Size = UDim2.new(0, 5, 0, 0)}):Play() end
                end
            end
            Window.CurrentPage = Page; Window.CurrentTab = name; Page.Visible = true; TabBg.Visible = true; TabBg.BackgroundTransparency = 0.4
            TabLb.TextColor3 = Color3.new(1,1,1); TabIc.ImageColor3 = Color3.new(1,1,1)
            TweenService:Create(TabInd, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 5, 0, 32)}):Play()
            -- Tab Transition Animation (No CanvasGroup Glitches)
            Page.Position = UDim2.new(0, 30, 0, 0)
            TweenService:Create(Page, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
        end)

        if not Window.CurrentTab then
            Window.CurrentPage = Page; Window.CurrentTab = name; Page.Visible = true; TabBg.Visible = true; TabBg.BackgroundTransparency = 0.4; TabLb.TextColor3 = Color3.new(1,1,1); TabIc.ImageColor3 = Color3.new(1,1,1); TabInd.Size = UDim2.new(0, 5, 0, 32)
        end

        local Tab = {}
        function Tab:CreateToggle(n, d, c)
            local T = create("TextButton", { Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = Library.Config.SecondaryColor, AutoButtonColor = false, Text = "  "..n, TextColor3 = Color3.new(1,1,1), TextSize = 19, FontFace = Library.Config.Font, TextXAlignment = Enum.TextXAlignment.Left, Parent = Page })
            create("UICorner", { CornerRadius = Library.Config.CornerRadius, Parent = T })
            
            local F = create("Frame", { Position = UDim2.new(1, -78, 0.5, -15), Size = UDim2.new(0, 62, 0, 32), BackgroundColor3 = Color3.fromRGB(60,60,95), Parent = T })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = F })
            local F_Acc = create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = d and 0 or 1, BackgroundColor3 = Library.Config.MainColor, Parent = F })
            table.insert(Library.Elements.Accents, F_Acc); create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = F_Acc })
            
            local D = create("Frame", { Position = d and UDim2.new(1, -30, 0.5, -13) or UDim2.new(0, 5, 0.5, -13), Size = UDim2.new(0, 26, 0, 26), BackgroundColor3 = Color3.new(1, 1, 1), Parent = F })
            create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = D })
            
            T.MouseButton1Click:Connect(function() 
                d = not d
                TweenService:Create(D, TweenInfo.new(0.3), {Position = d and UDim2.new(1, -30, 0.5, -13) or UDim2.new(0, 5, 0.5, -13)}):Play()
                TweenService:Create(F_Acc, TweenInfo.new(0.3), {BackgroundTransparency = d and 0 or 1}):Play()
                c(d) 
            end)
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
        function Tab:CreateDropdown(n, o, c)
            local op = false; local sel = o[1] or "None"
            local Dr = create("Frame", { Size = UDim2.new(1, 0, 0, 62), BackgroundColor3 = Library.Config.SecondaryColor, ClipsDescendants = true, Parent = Page })
            create("UICorner", { CornerRadius = Library.Config.CornerRadius, Parent = Dr })
            local Btn = create("TextButton", { Size = UDim2.new(1, 0, 0, 62), BackgroundTransparency = 1, Text = "  "..n, TextColor3 = Color3.new(1,1,1), TextSize = 19, FontFace = Library.Config.Font, TextXAlignment = Enum.TextXAlignment.Left, Parent = Dr })
            local Sl = create("TextLabel", { Position = UDim2.new(1, -215, 0, 15), Size = UDim2.new(0, 195, 0, 32), BackgroundColor3 = Color3.fromRGB(65,65,100), Text = sel, TextColor3 = Color3.new(1,1,1), TextSize = 18, FontFace = Library.Config.Font, Parent = Dr })
            create("UICorner", { CornerRadius = UDim.new(0,8), Parent = Sl })
            local Lst = create("ScrollingFrame", { Position = UDim2.new(0, 10, 0, 75), Size = UDim2.new(1, -20, 0, 160), BackgroundTransparency = 1, ScrollBarThickness = 2, Parent = Dr })
            create("UIListLayout", { Padding = UDim.new(0, 8), Parent = Lst })
            for _, v in pairs(o) do 
                local ob = create("TextButton", { Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = Color3.fromRGB(70,70,110), Text = v, TextColor3 = Color3.new(1,1,1), TextSize = 18, FontFace = Library.Config.Font, Parent = Lst })
                create("UICorner", { CornerRadius = UDim.new(0,8), Parent = ob })
                ob.MouseButton1Click:Connect(function() sel = v; Sl.Text = v; op = false; Dr:TweenSize(UDim2.new(1, 0, 0, 62), "Out", "Quart", 0.3, true); c(v) end)
            end
            Btn.MouseButton1Click:Connect(function() op = not op; Dr:TweenSize(op and UDim2.new(1, 0, 0, 255) or UDim2.new(1, 0, 0, 62), "Out", "Quart", 0.3, true) end)
        end
        function Tab:CreateButton(n, c)
            local Bt = create("TextButton", { Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = Library.Config.SecondaryColor, AutoButtonColor = false, Text = n, TextColor3 = Color3.new(1, 1, 1), TextSize = 19, FontFace = Library.Config.Font, Parent = Page })
            create("UICorner", { CornerRadius = Library.Config.CornerRadius, Parent = Bt })
            local Str = create("UIStroke", { Color = Library.Config.MainColor, Thickness = 1, Transparency = 0.5, Parent = Bt })
            table.insert(Library.Elements.Accents, Str)
            
            Bt.MouseEnter:Connect(function() TweenService:Create(Bt, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 55)}):Play(); TweenService:Create(Str, TweenInfo.new(0.2), {Transparency = 0}):Play() end)
            Bt.MouseLeave:Connect(function() TweenService:Create(Bt, TweenInfo.new(0.2), {BackgroundColor3 = Library.Config.SecondaryColor}):Play(); TweenService:Create(Str, TweenInfo.new(0.2), {Transparency = 0.5}):Play() end)
            Bt.MouseButton1Down:Connect(function() TweenService:Create(Bt, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(35, 35, 45)}):Play() end)
            Bt.MouseButton1Up:Connect(function() TweenService:Create(Bt, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(45, 45, 55)}):Play() end)
            
            Bt.MouseButton1Click:Connect(c)
        end
        function Tab:CreateKeybind(n, d, c)
            local cur = d or Enum.KeyCode.F; local bin = false
            local Kf = create("Frame", { Size = UDim2.new(1, 0, 0, 65), BackgroundColor3 = Library.Config.SecondaryColor, Parent = Page })
            create("UICorner", { CornerRadius = Library.Config.CornerRadius, Parent = Kf })
            create("TextLabel", { Size = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1, Text = "  "..n, TextColor3 = Color3.new(1,1,1), TextSize = 19, FontFace = Library.Config.Font, TextXAlignment = Enum.TextXAlignment.Left, Parent = Kf })
            local Kb = create("TextButton", { Position = UDim2.new(1, -195, 0.2, 0), Size = UDim2.new(0, 180, 0.6, 0), BackgroundColor3 = Color3.fromRGB(70, 70, 105), Text = "[ "..cur.Name.." ]", TextColor3 = Color3.new(1,1,1), TextSize = 18, FontFace = Library.Config.Font, Parent = Kf })
            create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = Kb }); Kb.MouseButton1Click:Connect(function() bin = true; Kb.Text = "..."; local conn; conn = UIS.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Keyboard then cur = i.KeyCode; Kb.Text = "[ "..cur.Name.." ]"; bin = false; conn:Disconnect(); c(cur) end end) end)
            UIS.InputBegan:Connect(function(i, gp) if not gp and not bin and i.KeyCode == cur then c(cur) end end)
        end
        function Tab:CreateColorPicker(n, d, c)
            local op = false; local cur = d or Library.Config.MainColor
            local h, s, v = cur:ToHSV(); local prevHSV = {h, s, v}
            
            local Cp = create("Frame", { Size = UDim2.new(1, 0, 0, 65), BackgroundColor3 = Library.Config.SecondaryColor, ClipsDescendants = true, Parent = Page })
            create("UICorner", { CornerRadius = Library.Config.CornerRadius, Parent = Cp })
            local Btn = create("TextButton", { Size = UDim2.new(1, 0, 0, 65), BackgroundTransparency = 1, Text = "  "..n, TextColor3 = Color3.new(1,1,1), TextSize = 19, FontFace = Library.Config.Font, TextXAlignment = Enum.TextXAlignment.Left, Parent = Cp })
            local Col = create("Frame", { Position = UDim2.new(1, -70, 0.5, -14), Size = UDim2.new(0, 55, 0, 28), BackgroundColor3 = cur, Parent = Cp })
            create("UICorner", { CornerRadius = UDim.new(0,6), Parent = Col })
            
            local Exp = create("Frame", { Position = UDim2.new(0, 0, 0, 65), Size = UDim2.new(1, 0, 0, 195), BackgroundTransparency = 1, Parent = Cp })
            
            local Map = create("TextButton", { Position = UDim2.new(0, 15, 0, 10), Size = UDim2.new(0, 140, 0, 140), AutoButtonColor = false, Parent = Exp })
            create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Map })
            local WGrad = create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(1, 1, 1), Parent = Map })
            create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = WGrad }); create("UIGradient", { Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)}), Rotation = 0, Parent = WGrad })
            local BGrad = create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.new(0, 0, 0), Parent = Map })
            create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = BGrad }); create("UIGradient", { Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0)}), Rotation = 90, Parent = BGrad })
            
            local MapInd = create("Frame", { Size = UDim2.new(0, 14, 0, 14), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = cur, Parent = Map })
            create("UICorner", { CornerRadius = UDim.new(1,0), Parent = MapInd }); create("UIStroke", { Color = Color3.new(1,1,1), Thickness = 2, Parent = MapInd })
            
            local HueS = create("TextButton", { Position = UDim2.new(0, 175, 0, 10), Size = UDim2.new(0, 18, 0, 140), BackgroundColor3 = Color3.new(1,1,1), Text = "", AutoButtonColor = false, Parent = Exp })
            create("UICorner", { CornerRadius = UDim.new(0,4), Parent = HueS })
            create("UIGradient", { Rotation = 90, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255,0,0)), ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255,255,0)), ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0,255,0)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,255,255)), ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0,0,255)), ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255,0,255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,0))}), Parent = HueS })
            local HueInd = create("Frame", { Size = UDim2.new(1, 24, 0, 4), Position = UDim2.new(0, -3, 0, 0), BackgroundColor3 = Color3.new(1,1,1), Parent = HueS })
            create("UIStroke", { Color = Color3.new(0,0,0), Thickness = 1, Parent = HueInd })

            local Prev = create("Frame", { Position = UDim2.new(0, 15, 0, 160), Size = UDim2.new(0, 26, 0, 26), BackgroundColor3 = cur, Parent = Exp })
            create("UICorner", { CornerRadius = UDim.new(0,6), Parent = Prev })
            
            local AccBtn = create("TextButton", { Position = UDim2.new(0, 50, 0, 160), Size = UDim2.new(0, 26, 0, 26), BackgroundColor3 = Color3.fromRGB(45,45,60), Text = "Ok", TextColor3 = Color3.new(1,1,1), TextSize = 14, FontFace = Library.Config.Font, Parent = Exp })
            create("UICorner", { CornerRadius = UDim.new(0,6), Parent = AccBtn })
            
            local CancBtn = create("TextButton", { Position = UDim2.new(0, 85, 0, 160), Size = UDim2.new(0, 26, 0, 26), BackgroundColor3 = Color3.fromRGB(45,45,60), Text = "X", TextColor3 = Color3.new(1,1,1), TextSize = 14, FontFace = Library.Config.Font, Parent = Exp })
            create("UICorner", { CornerRadius = UDim.new(0,6), Parent = CancBtn })
            
            local HexIn = create("TextBox", { Position = UDim2.new(1, -125, 0, 160), Size = UDim2.new(0, 110, 0, 26), BackgroundColor3 = Color3.fromRGB(45,45,60), Text = "#"..cur:ToHex(), TextColor3 = Color3.new(1,1,1), TextSize = 14, FontFace = Library.Config.Font, TextXAlignment = Enum.TextXAlignment.Center, Parent = Exp })
            create("UICorner", { CornerRadius = UDim.new(0,6), Parent = HexIn })
            
            local function upVis()
                Map.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                MapInd.Position = UDim2.new(s, 0, 1-v, 0); MapInd.BackgroundColor3 = cur
                HueInd.Position = UDim2.new(0, -2, h, -2)
            end
            local function upCol()
                cur = Color3.fromHSV(h, s, v); Col.BackgroundColor3 = cur; Prev.BackgroundColor3 = cur; HexIn.Text = "#"..cur:ToHex()
                upVis(); c(cur)
            end
            
            local mD, hD = false, false
            Map.MouseButton1Down:Connect(function() mD = true end); HueS.MouseButton1Down:Connect(function() hD = true end)
            UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then mD = false; hD = false end end)
            UIS.InputChanged:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseMovement then
                    if mD then
                        s = math.clamp((i.Position.X - Map.AbsolutePosition.X) / 140, 0, 1)
                        v = 1 - math.clamp((i.Position.Y - Map.AbsolutePosition.Y) / 140, 0, 1); upCol()
                    elseif hD then
                        h = math.clamp((i.Position.Y - HueS.AbsolutePosition.Y) / 140, 0, 1); upCol()
                    end
                end
            end)
            
            HexIn.FocusLost:Connect(function()
                local pk = pcall(function() local sc = Color3.fromHex(HexIn.Text:gsub("#","")); h, s, v = sc:ToHSV(); upCol() end)
                if not pk then HexIn.Text = "#"..cur:ToHex() end
            end)
            
            AccBtn.MouseButton1Click:Connect(function() prevHSV = {h,s,v}; op = false; Cp:TweenSize(UDim2.new(1, 0, 0, 65), "Out", "Quart", 0.35, true) end)
            CancBtn.MouseButton1Click:Connect(function() h,s,v = unpack(prevHSV); upCol(); op = false; Cp:TweenSize(UDim2.new(1, 0, 0, 65), "Out", "Quart", 0.35, true) end)
            
            upVis()
            Btn.MouseButton1Click:Connect(function() op = not op; Cp:TweenSize(op and UDim2.new(1, 0, 0, 260) or UDim2.new(1, 0, 0, 65), "Out", "Quart", 0.35, true) end)
        end
        function Tab:CreateSection(n) 
            local Sec = create("TextLabel", { Size = UDim2.new(1, 0, 0, 48), BackgroundTransparency = 1, Text = " —  " .. n:upper(), TextColor3 = Library.Config.MainColor, TextSize = 17, FontFace = Library.Config.Font, TextXAlignment = Enum.TextXAlignment.Left, Parent = Page }) 
            table.insert(Library.Elements.Accents, Sec)
        end
        function Tab:CreateLabel(t) 
            local Lb = create("TextLabel", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Text = "  "..t, TextColor3 = Color3.fromRGB(225, 225, 225), TextSize = 18, FontFace = Library.Config.Font, TextXAlignment = Enum.TextXAlignment.Left, Parent = Page }) 
            table.insert(Library.Elements.Fonts, Lb)
        end
        function Tab:CreateTextbox(n, p, c)
            local Tf = create("Frame", { Size = UDim2.new(1, 0, 0, 65), BackgroundColor3 = Library.Config.SecondaryColor, Parent = Page })
            create("UICorner", { CornerRadius = Library.Config.CornerRadius, Parent = Tf })
            create("TextLabel", { Size = UDim2.new(0.4, 0, 1, 0), BackgroundTransparency = 1, Text = "  "..n, TextColor3 = Color3.new(1,1,1), TextSize = 19, FontFace = Library.Config.Font, TextXAlignment = Enum.TextXAlignment.Left, Parent = Tf })
            local In = create("TextBox", { Position = UDim2.new(1, -225, 0.2, 0), Size = UDim2.new(0, 210, 0.6, 0), BackgroundColor3 = Color3.fromRGB(70, 70, 100), Text = "", PlaceholderText = p, TextColor3 = Color3.new(1,1,1), TextSize = 18, FontFace = Library.Config.Font, Parent = Tf })
            create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = In }); In.FocusLost:Connect(function(e) if e then c(In.Text) end end)
        end
        function Tab:CreateDiscordInvite(title, name, icon, link)
            local wrap = create("Frame", { Size = UDim2.new(1, 0, 0, 105), BackgroundTransparency = 1, Parent = Page })
            create("TextLabel", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = "  "..(title or "Link discord invite"), TextColor3 = Color3.fromRGB(85, 170, 255), TextSize = 15, FontFace = Library.Config.Font, TextXAlignment = Enum.TextXAlignment.Left, Parent = wrap })
            local Box = create("Frame", { Position = UDim2.new(0, 0, 0, 25), Size = UDim2.new(1, 0, 0, 80), BackgroundColor3 = Library.Config.SecondaryColor, Parent = wrap })
            create("UICorner", { CornerRadius = Library.Config.CornerRadius, Parent = Box })
            local Ic = create("ImageLabel", { Position = UDim2.new(0, 10, 0, 10), Size = UDim2.new(0, 32, 0, 32), BackgroundColor3 = Library.Config.BackgroundColor, Image = icon or "rbxassetid://6023454032", Parent = Box })
            create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Ic })
            create("TextLabel", { Position = UDim2.new(0, 52, 0, 10), Size = UDim2.new(1, -62, 0, 18), BackgroundTransparency = 1, Text = name or "Name Hub", TextColor3 = Color3.new(1,1,1), TextSize = 16, FontFace = Library.Config.Font, TextXAlignment = Enum.TextXAlignment.Left, Parent = Box })
            create("TextLabel", { Position = UDim2.new(0, 52, 0, 28), Size = UDim2.new(1, -62, 0, 14), BackgroundTransparency = 1, Text = "Join server", TextColor3 = Color3.fromRGB(150, 150, 150), TextSize = 13, FontFace = Library.Config.Font, TextXAlignment = Enum.TextXAlignment.Left, Parent = Box })
            
            local JoinBtn = create("TextButton", { Position = UDim2.new(0, 10, 0, 50), Size = UDim2.new(1, -20, 0, 22), BackgroundColor3 = Color3.fromRGB(67, 181, 129), AutoButtonColor = false, Text = "Join", TextColor3 = Color3.new(1,1,1), TextSize = 14, FontFace = Library.Config.Font, Parent = Box })
            create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = JoinBtn })
            
            JoinBtn.MouseEnter:Connect(function() TweenService:Create(JoinBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(57, 151, 105)}):Play() end)
            JoinBtn.MouseLeave:Connect(function() TweenService:Create(JoinBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(67, 181, 129)}):Play() end)
            
            JoinBtn.MouseButton1Click:Connect(function()
                if not link then return end
                task.spawn(function()
                    local env = getfenv()
                    local setclip = env["setclipboard"]
                    local req = env["request"] or env["http_request"] or (env["syn"] and env["syn"].request)
                    
                    local inv = link:gsub("https://discord.gg/", ""):gsub("https://discord.com/invite/", "")
                    if setclip then pcall(function() setclip(link) end); Library:Notify("Discord", "Copied invite link to clipboard!", 3) end
                    if req then
                        pcall(function()
                            local http = game:GetService("HttpService")
                            local b = http:JSONEncode({ cmd = "INVITE_BROWSER", args = { code = inv }, nonce = http:GenerateGUID(false) })
                            req({Url = "http://127.0.0.1:6463/rpc?v=1", Method = "POST", Headers = { ["Content-Type"] = "application/json", ["Origin"] = "https://discord.com" }, Body = b})
                        end)
                    end
                end)
            end)
        end
        return Tab
    end

    function Library:Notify(t, d, dur)
        if not Library["NotifyUI"] then
            Library["NotifyUI"] = create("ScreenGui", { Name = "VortexNotify", Parent = PlayerGui })
            Library["NotifyContainer"] = create("Frame", { Size = UDim2.new(0, 320, 1, -20), AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -10, 1, 0), BackgroundTransparency = 1, Parent = Library["NotifyUI"] })
            local NScale = create("UIScale", { Scale = Library.Config.Scale or 1, Parent = Library["NotifyContainer"] })
            table.insert(Library.Elements.Scales, NScale)
            create("UIListLayout", { Padding = UDim.new(0, 10), VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right, Parent = Library["NotifyContainer"] })
        end
        task.spawn(function()
            local NFWrap = create("Frame", { Size = UDim2.new(0, 320, 0, 95), BackgroundTransparency = 1, ClipsDescendants = true, Parent = Library["NotifyContainer"] })
            local NF = create("TextButton", { Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(1, 350, 0, 0), BackgroundColor3 = self.Config.BackgroundColor, Text = "", AutoButtonColor = false, Parent = NFWrap })
            create("UICorner", { CornerRadius = self.Config.CornerRadius, Parent = NF })
            local NS = create("UIStroke", { Color = self.Config.MainColor, Thickness = 2, Parent = NF })
            table.insert(self.Elements.Accents, NS)
            create("TextLabel", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, Text = "  "..t, TextColor3 = Color3.new(1,1,1), TextSize = 21, FontFace = self.Config.Font, TextXAlignment = Enum.TextXAlignment.Left, Parent = NF })
            create("TextLabel", { Position = UDim2.new(0, 0, 0.4, 0), Size = UDim2.new(1, 0, 0.6, 0), BackgroundTransparency = 1, Text = "  "..d, TextColor3 = Color3.fromRGB(220, 220, 220), TextSize = 17, FontFace = self.Config.Font, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, Parent = NF })
            
            NF:TweenPosition(UDim2.new(0, 0, 0, 0), "Out", "Quart", 0.5, true)
            
            local active = true
            NF.MouseButton1Click:Connect(function() active = false end)
            
            local passed = 0
            while active and passed < (dur or 4) do
                passed = passed + 0.1
                task.wait(0.1)
            end
            
            NF:TweenPosition(UDim2.new(1, 350, 0, 0), "In", "Quart", 0.5, true)
            TweenService:Create(NFWrap, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {Size = UDim2.new(0, 320, 0, 0)}):Play()
            task.wait(0.5)
            NFWrap:Destroy()
        end)
    end
    task.spawn(function() while task.wait(1) do local f = math.floor(1/task.wait()); local p = 0; pcall(function() p = math.floor(game:GetService("Stats").PerformanceStats.Ping:GetValue()) end); StatLabel.Text = string.format("FPS: %d | PING: %d MS | TIME: %s", f, p, os.date("%X")) end end)
    return Window
end

-- [ MASTER EXECUTION ]
Library:CreateKeySystem({
    Name = "VORTEX ACCESS CONTROL",
    Note = "Enter your premium key to load the Hub.",
    Key = "VORTEX123",
    Callback = function()
        -- Load main UI only after successful key input
        local Win = Library:CreateWindow("VORTEX HUB V2")
        Library:Notify("Success", "Access Granted. Welcome, " .. LocalPlayer.Name, 5)
        
        -- TAB: MAIN / PLAYER
        local MainTab = Win:CreateTab("Player Settings", "rbxassetid://6023454032")
        MainTab:CreateSection("Movement")
        MainTab:CreateSlider("WalkSpeed", 16, 250, 16, function(value)
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.WalkSpeed = value
            end
        end)
        MainTab:CreateSlider("JumpPower", 50, 500, 50, function(value)
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.JumpPower = value
            end
        end)
        MainTab:CreateToggle("Infinite Jump", false, function(state)
            _G.InfJump = state
            if not _G.InfJumpConn then
                _G.InfJumpConn = game:GetService("UserInputService").JumpRequest:Connect(function()
                    if _G.InfJump then
                        local char = LocalPlayer.Character
                        if char and char:FindFirstChildOfClass("Humanoid") then
                            char:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
                        end
                    end
                end)
            end
        end)
        MainTab:CreateToggle("Noclip", false, function(state)
            _G.Noclip = state
            if not _G.NoclipConn then
                _G.NoclipConn = game:GetService("RunService").Stepped:Connect(function()
                    if _G.Noclip then
                        local char = LocalPlayer.Character
                        if char then
                            for _, v in pairs(char:GetDescendants()) do
                                if v:IsA("BasePart") and v.CanCollide then
                                    v.CanCollide = false
                                end
                            end
                        end
                    end
                end)
            end
        end)
        
        MainTab:CreateSection("Utility")
        MainTab:CreateButton("Teleport to Home", function() 
            Library:Notify("Teleport", "Teleporting home...", 3)
        end)
        MainTab:CreateDiscordInvite("Vortex Community", "Vortex Hub", "rbxassetid://15222216598", "https://discord.gg/vortex")

        -- TAB: COMBAT / FARM
        local CombatTab = Win:CreateTab("Combat & Farm", "rbxassetid://6034503041")
        CombatTab:CreateSection("Auto Farming")
        CombatTab:CreateToggle("Auto-Farm Mobs", false, function(state)
            _G.AutoFarm = state
            if state then
                task.spawn(function()
                    while _G.AutoFarm do
                        task.wait(1)
                        pcall(function() print("Farming simulated.") end)
                    end
                end)
            end
        end)
        CombatTab:CreateToggle("Auto-Collect Drops", false, function(state)
            _G.AutoCollect = state
        end)
        
        CombatTab:CreateSection("Combat Enhancements")
        CombatTab:CreateToggle("Hitbox Expander", false, function(state)
            _G.Hitbox = state
            task.spawn(function()
                while _G.Hitbox do
                    task.wait(1)
                    pcall(function()
                        for _, p in pairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                                p.Character.HumanoidRootPart.Size = Vector3.new(10, 10, 10)
                                p.Character.HumanoidRootPart.Transparency = 0.5
                                p.Character.HumanoidRootPart.CanCollide = false
                            end
                        end
                    end)
                end
            end)
        end)
        CombatTab:CreateButton("Kill Aura (Instant)", function()
            Library:CreateDialog({
                Title = "High Risk",
                Content = "Kill Aura has a high ban rate. Proceed?",
                Button1 = "Execute",
                Button2 = "Cancel",
                Callback1 = function()
                    Library:Notify("Combat", "Kill Aura Activated. Proceed with caution.", 4)
                end
            })
        end)

        -- TAB: VISUALS
        local VisualTab = Win:CreateTab("Visuals (ESP)", "rbxassetid://6034502932")
        VisualTab:CreateSection("ESP Settings")
        VisualTab:CreateToggle("Enable ESP (Name Tags)", false, function(state)
            Library:Notify("Visuals", "ESP Toggled: "..tostring(state), 3)
        end)
        VisualTab:CreateToggle("Show Tracers", false, function(state)
            Library:Notify("Visuals", "Tracers Toggled: "..tostring(state), 3)
        end)
        VisualTab:CreateToggle("Chams (Wallhack)", false, function(state)
            Library:Notify("Visuals", "Chams Toggled: "..tostring(state), 3)
        end)
        
        VisualTab:CreateSection("World Helpers")
        VisualTab:CreateToggle("Full Bright", false, function(state)
            pcall(function()
                if state then
                    game:GetService("Lighting").Ambient = Color3.new(1, 1, 1)
                    game:GetService("Lighting").Brightness = 2
                else
                    game:GetService("Lighting").Ambient = Color3.fromRGB(127, 127, 127)
                    game:GetService("Lighting").Brightness = 1
                end
            end)
        end)

        -- TAB: CONFIG
        local SettingsTab = Win:CreateTab("Settings", "rbxassetid://6031289116")
        SettingsTab:CreateSection("Theme Customization")
        SettingsTab:CreateColorPicker("Accent Color", Library.Config.MainColor, function(c)
            Library.Config.MainColor = c
            Library:UpdateTheme()
        end)
        SettingsTab:CreateDropdown("Font Selection", {"Gotham", "Roboto", "Code", "Sarpanch"}, function(v)
            local fMap = { Gotham = "rbxasset://fonts/families/GothamSSm.json", Roboto = "rbxasset://fonts/families/Roboto.json", Code = "rbxasset://fonts/families/Inconsolata.json", Sarpanch = "rbxasset://fonts/families/Sarpanch.json" }
            if fMap[v] then
                Library.Config.Font = Font.new(fMap[v], Enum.FontWeight.Bold, Enum.FontStyle.Italic)
                Library:UpdateTheme()
            end
        end)
        SettingsTab:CreateSlider("Background Opacity", 0, 100, 10, function(v)
            Library.Config.Transparency = v/100
            Library:UpdateTheme()
        end)
        SettingsTab:CreateSlider("UI Scale", 50, 150, 100, function(v)
            Library:SetUIScale(v/100)
        end)
        
        SettingsTab:CreateSection("App Controls")
        SettingsTab:CreateKeybind("Toggle Hub Key", Library.Config.ToggleKey, function(key)
            Library.Config.ToggleKey = key
            Library:Notify("Keybind", "UI Toggle set to: "..key.Name, 3)
        end)
        SettingsTab:CreateButton("Unload Script", function()
            Library:CreateDialog({
                Title = "Unload Hub",
                Content = "Are you sure you want to completely unload Vortex Hub?",
                Button1 = "Destroy",
                Button2 = "Stay",
                Callback1 = function()
                    for _, v in pairs(LocalPlayer.PlayerGui:GetChildren()) do
                        if v.Name == "VX_V20" or v.Name == "VX_KeySys" or v.Name == "VX_Dialog" or v.Name == "VortexNotify" then v:Destroy() end
                    end
                end
            })
        end)

    end
})

return Library
