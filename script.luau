local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or (Players:GetPropertyChangedSignal("LocalPlayer"):Wait() and Players.LocalPlayer)
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- [ نظام تنظيف صارم لمنع تكرار الواجهات ]
local function GlobalCleanup()
    for _, gui in pairs(PlayerGui:GetChildren()) do
        -- سيمسح أي واجهة قديمة تبدأ بهذه الأسماء لضمان عدم التكرار
        if gui.Name:match("VX") or gui.Name:match("Vortex") or gui.Name == "ScreenGui" then
            if gui:FindFirstChild("MainFrame") or gui:FindFirstChild("KeyFrame") then
                gui:Destroy()
            end
        end
    end
end
GlobalCleanup()

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

-- [ KEY SYSTEM ]
function Library:CreateKeySystem(config)
    local ScreenGui = create("ScreenGui", { Name = "Vortex_KeySys", ResetOnSpawn = false, DisplayOrder = 200, Parent = PlayerGui })
    local KFrame = create("Frame", { Name = "KeyFrame", Position = UDim2.new(0.5, -200, 0.5, -125), Size = UDim2.new(0, 400, 0, 250), BackgroundColor3 = self.Config.BackgroundColor, Parent = ScreenGui })
    create("UICorner", { CornerRadius = self.Config.CornerRadius, Parent = KFrame })
    create("UIStroke", { Color = self.Config.MainColor, Thickness = 2, Parent = KFrame })
    
    local Title = create("TextLabel", { Position = UDim2.new(0, 20, 0, 20), Size = UDim2.new(1, -40, 0, 30), BackgroundTransparency = 1, Text = config.Name or "KEY SYSTEM", TextColor3 = Color3.new(1,1,1), TextSize = 20, FontFace = self.Config.Font, Parent = KFrame })
    local Inp = create("TextBox", { Position = UDim2.new(0, 20, 0, 100), Size = UDim2.new(1, -40, 0, 45), BackgroundColor3 = self.Config.SecondaryColor, Text = "", PlaceholderText = "Enter Key...", TextColor3 = Color3.new(1,1,1), Parent = KFrame })
    create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = Inp })
    
    local Sub = create("TextButton", { Position = UDim2.new(0, 20, 0, 165), Size = UDim2.new(1, -40, 0, 45), BackgroundColor3 = self.Config.MainColor, Text = "Submit", TextColor3 = Color3.new(1,1,1), Parent = KFrame })
    create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = Sub })
    
    Sub.MouseButton1Click:Connect(function()
        if Inp.Text == config.Key then
            ScreenGui:Destroy()
            if config.Callback then config.Callback() end
        else
            Inp.Text = "INVALID KEY"
            task.wait(1)
            Inp.Text = ""
        end
    end)
end

-- [ WINDOW CREATION ]
function Library:CreateWindow(name)
    GlobalCleanup() -- مسح أي شيء قديم عند النداء
    
    local ScreenGui = create("ScreenGui", { Name = "Vortex_Main", ResetOnSpawn = false, DisplayOrder = 100, Parent = PlayerGui })
    local Frame = create("Frame", { Name = "MainFrame", Position = UDim2.new(0.5, -325, 0.5, -235), Size = UDim2.new(0, 650, 0, 470), BackgroundColor3 = self.Config.BackgroundColor, BackgroundTransparency = self.Config.Transparency, Parent = ScreenGui })
    create("UICorner", { CornerRadius = self.Config.CornerRadius, Parent = Frame })
    create("UIStroke", { Color = self.Config.UIStrokeColor, Thickness = 1.8, Parent = Frame })

    local TopBar = create("Frame", { Name = "TopBar", Size = UDim2.new(1, 0, 0, 65), BackgroundTransparency = 1, Parent = Frame })
    local Title = create("TextLabel", { Position = UDim2.new(0, 25, 0, 0), Size = UDim2.new(0, 250, 1, 0), BackgroundTransparency = 1, Text = name:upper(), TextColor3 = Color3.new(1, 1, 1), TextSize = 22, FontFace = self.Config.Font, TextXAlignment = Enum.TextXAlignment.Left, Parent = TopBar })
    
    local CloseBtn = create("TextButton", { Position = UDim2.new(1, -45, 0, 16), Size = UDim2.new(0, 32, 0, 32), BackgroundColor3 = Color3.fromRGB(22, 22, 26), Text = "✖", TextColor3 = Color3.new(1,1,1), Parent = TopBar })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = CloseBtn })
    CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

    local Sidebar = create("ScrollingFrame", { Position = UDim2.new(0, 12, 0, 80), Size = UDim2.new(0, 180, 1, -135), BackgroundTransparency = 1, ScrollBarThickness = 0, Parent = Frame })
    create("UIListLayout", { Padding = UDim.new(0, 12), Parent = Sidebar })
    
    local TabContainer = create("Frame", { Position = UDim2.new(0, 205, 0, 80), Size = UDim2.new(1, -220, 1, -135), BackgroundTransparency = 1, Parent = Frame })
    
    -- Dragging Logic
    local dragging, dragStart, startPos
    Frame.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = i.Position; startPos = Frame.Position end end)
    UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then local delta = i.Position - dragStart; Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)

    local Window = { Gui = ScreenGui, Frame = Frame, CurrentPage = nil, CurrentTab = nil }

    function Window:CreateTab(name, icon)
        local TabBtn = create("TextButton", { Size = UDim2.new(1, 0, 0, 50), BackgroundTransparency = 1, Text = "  "..name, TextColor3 = Color3.fromRGB(180,180,200), TextSize = 17, FontFace = Library.Config.Font, TextXAlignment = Enum.TextXAlignment.Left, Parent = Sidebar })
        create("UICorner", { CornerRadius = Library.Config.CornerRadius, Parent = TabBtn })
        
        local Page = create("ScrollingFrame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false, ScrollBarThickness = 2, AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = TabContainer })
        create("UIListLayout", { Padding = UDim.new(0, Library.Config.OptionSpacing), Parent = Page })

        TabBtn.MouseButton1Click:Connect(function()
            if Window.CurrentPage then Window.CurrentPage.Visible = false end
            Window.CurrentPage = Page; Page.Visible = true
        end)

        if not Window.CurrentTab then Window.CurrentPage = Page; Window.CurrentTab = name; Page.Visible = true end

        local Tab = {}
        function Tab:CreateButton(n, c)
            local Bt = create("TextButton", { Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = Library.Config.SecondaryColor, Text = n, TextColor3 = Color3.new(1, 1, 1), FontFace = Library.Config.Font, Parent = Page })
            create("UICorner", { CornerRadius = Library.Config.CornerRadius, Parent = Bt })
            Bt.MouseButton1Click:Connect(c)
        end
        
        function Tab:CreateToggle(n, d, c)
            local T = create("TextButton", { Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = Library.Config.SecondaryColor, Text = "  "..n, TextColor3 = Color3.new(1,1,1), TextXAlignment = Enum.TextXAlignment.Left, Parent = Page })
            create("UICorner", { CornerRadius = Library.Config.CornerRadius, Parent = T })
            local Box = create("Frame", { Position = UDim2.new(1, -45, 0.5, -12), Size = UDim2.new(0, 24, 0, 24), BackgroundColor3 = d and Library.Config.MainColor or Color3.new(0.2,0.2,0.2), Parent = T })
            T.MouseButton1Click:Connect(function() d = not d; Box.BackgroundColor3 = d and Library.Config.MainColor or Color3.new(0.2,0.2,0.2); c(d) end)
        end

        function Tab:CreateSlider(n, mi, ma, d, c)
            local S = create("Frame", { Size = UDim2.new(1, 0, 0, 70), BackgroundColor3 = Library.Config.SecondaryColor, Parent = Page })
            create("UICorner", { CornerRadius = Library.Config.CornerRadius, Parent = S })
            local L = create("TextLabel", { Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Text = n.." : "..d, TextColor3 = Color3.new(1,1,1), Parent = S })
            local B = create("TextButton", { Position = UDim2.new(0.1, 0, 0.7, 0), Size = UDim2.new(0.8, 0, 0, 10), BackgroundColor3 = Color3.new(0.1,0.1,0.1), Text = "", Parent = S })
            local F = create("Frame", { Size = UDim2.new((d-mi)/(ma-mi), 0, 1, 0), BackgroundColor3 = Library.Config.MainColor, Parent = B })
            B.MouseButton1Down:Connect(function()
                local conn; conn = UIS.InputChanged:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseMovement then
                        local p = math.clamp((i.Position.X - B.AbsolutePosition.X)/B.AbsoluteSize.X, 0, 1)
                        local v = math.floor(mi + (ma-mi)*p)
                        F.Size = UDim2.new(p, 0, 1, 0); L.Text = n.." : "..v; c(v)
                    end
                end)
                UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then conn:Disconnect() end end)
            end)
        end

        function Tab:CreateDropdown(n, o, c)
            local Dr = create("TextButton", { Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = Library.Config.SecondaryColor, Text = n, TextColor3 = Color3.new(1,1,1), Parent = Page })
            create("UICorner", { CornerRadius = Library.Config.CornerRadius, Parent = Dr })
            Dr.MouseButton1Click:Connect(function() print("Dropdown Open") end) -- مبسطة للاختصار
        end

        function Tab:CreateColorPicker(n, d, c)
            local Cp = create("TextButton", { Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = Library.Config.SecondaryColor, Text = n, TextColor3 = Color3.new(1,1,1), Parent = Page })
            local Box = create("Frame", { Position = UDim2.new(1, -45, 0.5, -12), Size = UDim2.new(0, 24, 0, 24), BackgroundColor3 = d, Parent = Cp })
            Cp.MouseButton1Click:Connect(function() c(d) end)
        end

        function Tab:CreateKeybind(n, d, c)
            local Kb = create("TextButton", { Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = Library.Config.SecondaryColor, Text = n.." : "..d.Name, TextColor3 = Color3.new(1,1,1), Parent = Page })
            Kb.MouseButton1Click:Connect(function() c(d) end)
        end

        return Tab
    end
    
    function Library:CreateDialog(config)
        local DG = create("ScreenGui", { Name = "Vortex_Dialog", Parent = PlayerGui })
        local DF = create("Frame", { Position = UDim2.new(0.5, -150, 0.5, -75), Size = UDim2.new(0, 300, 0, 150), BackgroundColor3 = Color3.fromRGB(20,20,25), Parent = DG })
        create("TextLabel", { Size = UDim2.new(1,0,0,50), Text = config.Title, TextColor3 = Color3.new(1,1,1), BackgroundTransparency = 1, Parent = DF })
        local B1 = create("TextButton", { Position = UDim2.new(0.1,0,0.6,0), Size = UDim2.new(0.35,0,0,40), Text = config.Button1, Parent = DF })
        B1.MouseButton1Click:Connect(function() DG:Destroy(); config.Callback1() end)
    end

    return Window
end

return Library
