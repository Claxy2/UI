--[[
    UI Library - Clean, modern Roblox UI library
    Features: Draggable window, tabs, buttons, toggles, sliders, textboxes, labels, dropdowns
    All components use TweenService for smooth animations
]]

-- ============================================================
-- SERVICES
-- ============================================================
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

-- ============================================================
-- CONSTANTS & THEMES
-- ============================================================
local TWEEN_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_SMOOTH = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_SPRING = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local FONT = "GothamSemibold"
local FONT_MEDIUM = "Gotham"
local FONT_LIGHT = "SourceSans"

local Themes = {
    Dark = {
        Background = Color3.fromRGB(22, 22, 42),
        Secondary = Color3.fromRGB(30, 30, 56),
        Tertiary = Color3.fromRGB(38, 38, 70),
        Element = Color3.fromRGB(46, 46, 80),
        ElementHover = Color3.fromRGB(56, 56, 94),
        Accent = Color3.fromRGB(124, 58, 237),
        AccentHover = Color3.fromRGB(139, 92, 246),
        Text = Color3.fromRGB(240, 240, 248),
        SubText = Color3.fromRGB(160, 160, 180),
        Border = Color3.fromRGB(60, 60, 95),
        ScrollBar = Color3.fromRGB(80, 80, 120),
    }
}
Themes.Light = Themes.Dark -- Light theme just uses Dark for now

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================

-- Creates a new instance with given properties
local function Create(className, properties)
    local instance = Instance.new(className)
    for prop, value in pairs(properties or {}) do
        instance[prop] = value
    end
    return instance
end

-- Creates a Tween and plays it immediately
local function Tween(instance, info, goals)
    local tween = TweenService:Create(instance, info, goals)
    tween:Play()
    return tween
end

-- Rounds a number to given decimal places
local function Round(num, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- Makes a frame draggable via a drag bar handle
local function MakeDraggable(frame, dragBar, clampToScreen)
    local dragging = false
    local dragStartPos = nil
    local frameStartPos = nil
    local connections = {}

    table.insert(connections, dragBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStartPos = input.Position
            frameStartPos = frame.Position
            -- Bring window to front
            if frame:FindFirstAncestorOfClass("ScreenGui") then
                frame.ZIndex = frame.ZIndex + 1
            end
        end
    end))

    table.insert(connections, dragBar.InputEnded:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch) and dragging then
            dragging = false
        end
    end))

    table.insert(connections, UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then

            local delta = input.Position - dragStartPos
            local screenGui = frame:FindFirstAncestorOfClass("ScreenGui")
            local screenSize = screenGui and screenGui.AbsoluteSize or workspace.CurrentCamera.ViewportSize
            local frameSize = frame.AbsoluteSize

            local newX = frameStartPos.X.Offset + delta.X
            local newY = frameStartPos.Y.Offset + delta.Y

            -- Clamp to keep window on-screen
            if clampToScreen ~= false then
                local padding = 24
                newX = math.clamp(newX, padding, screenSize.X - frameSize.X - padding)
                newY = math.clamp(newY, padding, screenSize.Y - frameSize.Y - padding)
            end

            frame.Position = UDim2.new(0, newX, 0, newY)
        end
    end))

    table.insert(connections, UserInputService.InputEnded:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch) and dragging then
            dragging = false
        end
    end))

    -- Return a disconnect function
    return function()
        for _, conn in ipairs(connections) do
            conn:Disconnect()
        end
    end
end

-- ============================================================
-- COMPONENT BUILDERS
-- ============================================================

local function CreateButton(parent, config, theme)
    local buttonFrame = Create("Frame", {
        Name = config.Name or "Button",
        BackgroundColor3 = theme.Element,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundTransparency = 0,
        Parent = parent,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = buttonFrame })

    local buttonText = Create("TextLabel", {
        Text = config.Name or "",
        TextColor3 = theme.Text,
        Font = Enum.Font[FONT],
        TextSize = 14,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = buttonFrame,
    })

    local clickDebounce = false

    buttonFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and not clickDebounce then
            clickDebounce = true
            Tween(buttonFrame, TWEEN_FAST, { BackgroundColor3 = theme.Accent })
            task.wait(0.06)
            Tween(buttonFrame, TWEEN_SMOOTH, { BackgroundColor3 = theme.ElementHover })
            if config.Callback then
                local success, err = pcall(config.Callback)
                if not success then warn("[UI Library] Button callback error:", err) end
            end
            task.wait(0.15)
            clickDebounce = false
        end
    end)

    buttonFrame.MouseEnter:Connect(function()
        if not clickDebounce then
            Tween(buttonFrame, TWEEN_FAST, { BackgroundColor3 = theme.ElementHover })
        end
    end)

    buttonFrame.MouseLeave:Connect(function()
        if not clickDebounce then
            Tween(buttonFrame, TWEEN_FAST, { BackgroundColor3 = theme.Element })
        end
    end)

    return buttonFrame
end

local function CreateToggle(parent, config, theme)
    local state = config.Default or false

    local toggleFrame = Create("Frame", {
        Name = config.Name or "Toggle",
        BackgroundColor3 = theme.Element,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 0,
        Parent = parent,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = toggleFrame })

    local nameLabel = Create("TextLabel", {
        Text = config.Name or "",
        TextColor3 = theme.Text,
        Font = Enum.Font[FONT],
        TextSize = 14,
        BackgroundTransparency = 1,
        Size = UDim2.new(0.65, -12, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = toggleFrame,
    })

    -- Switch background
    local switchBg = Create("Frame", {
        Name = "SwitchBg",
        BackgroundColor3 = theme.Tertiary,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 44, 0, 24),
        Position = UDim2.new(1, -56, 0.5, -12),
        BackgroundTransparency = 0,
        Parent = toggleFrame,
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = switchBg })

    -- Switch knob
    local switchKnob = Create("Frame", {
        Name = "SwitchKnob",
        BackgroundColor3 = theme.SubText,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(0, 3, 0.5, -9),
        Parent = switchBg,
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = switchKnob })

    -- Shadow/glow effect on knob
    Create("UIStroke", {
        Color = Color3.fromRGB(0, 0, 0),
        Transparency = 0.6,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = switchKnob,
    })

    local function UpdateVisual()
        if state then
            Tween(switchBg, TWEEN_SMOOTH, { BackgroundColor3 = theme.Accent })
            Tween(switchKnob, TWEEN_SMOOTH, {
                Position = UDim2.new(0, 23, 0.5, -9),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            })
        else
            Tween(switchBg, TWEEN_SMOOTH, { BackgroundColor3 = theme.Tertiary })
            Tween(switchKnob, TWEEN_SMOOTH, {
                Position = UDim2.new(0, 3, 0.5, -9),
                BackgroundColor3 = theme.SubText,
            })
        end
    end

    toggleFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            state = not state
            UpdateVisual()
            if config.Callback then
                local success, err = pcall(config.Callback, state)
                if not success then warn("[UI Library] Toggle callback error:", err) end
            end
        end
    end)

    -- Initialize visual
    if state then
        switchBg.BackgroundColor3 = theme.Accent
        switchKnob.Position = UDim2.new(0, 23, 0.5, -9)
        switchKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    end

    return {
        Frame = toggleFrame,
        SetState = function(newState)
            if newState ~= state then
                state = newState
                UpdateVisual()
            end
        end,
        GetState = function() return state end,
    }
end

local function CreateSlider(parent, config, theme)
    local minVal = config.Min or 0
    local maxVal = config.Max or 100
    local currentVal = math.clamp(config.Default or minVal, minVal, maxVal)
    local decimalPlaces = config.Decimals or 0
    local suffix = config.Suffix or ""

    local sliderFrame = Create("Frame", {
        Name = config.Name or "Slider",
        BackgroundColor3 = theme.Element,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 58),
        BackgroundTransparency = 0,
        Parent = parent,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = sliderFrame })

    -- Name label
    local nameLabel = Create("TextLabel", {
        Text = config.Name or "",
        TextColor3 = theme.Text,
        Font = Enum.Font[FONT],
        TextSize = 13,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 120, 0, 20),
        Position = UDim2.new(0, 12, 0, 6),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = sliderFrame,
    })

    -- Value label
    local valueLabel = Create("TextLabel", {
        Text = tostring(currentVal) .. suffix,
        TextColor3 = theme.Accent,
        Font = Enum.Font[FONT_MEDIUM],
        TextSize = 13,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 60, 0, 20),
        Position = UDim2.new(1, -72, 0, 6),
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = sliderFrame,
    })

    -- Track background
    local trackBg = Create("Frame", {
        BackgroundColor3 = theme.Tertiary,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -24, 0, 6),
        Position = UDim2.new(0, 12, 0, 34),
        Parent = sliderFrame,
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = trackBg })

    -- Track fill
    local trackFill = Create("Frame", {
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 1, 0),
        Parent = trackBg,
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = trackFill })

    -- Thumb / knob
    local thumb = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Size = UDim2.new(0, 16, 0, 16),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Parent = trackBg,
    })
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = thumb })
    Create("UIStroke", {
        Color = theme.Accent,
        Transparency = 0.3,
        Thickness = 2,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = thumb,
    })

    -- Update function
    local function UpdateValue(newValue)
        currentVal = math.clamp(Round(newValue, decimalPlaces), minVal, maxVal)
        local percent = (currentVal - minVal) / (maxVal - minVal)
        valueLabel.Text = tostring(currentVal) .. suffix
        trackFill.Size = UDim2.new(percent, 0, 1, 0)
        thumb.Position = UDim2.new(percent, 0, 0.5, 0)
    end

    local function GetPercentFromPosition(inputPos)
        local trackAbsPos = trackBg.AbsolutePosition
        local trackAbsSize = trackBg.AbsoluteSize
        local relativeX = inputPos.X - trackAbsPos.X
        local percent = math.clamp(relativeX / trackAbsSize.X, 0, 1)
        return percent
    end

    local function SetFromPercent(percent)
        local rawValue = minVal + (maxVal - minVal) * percent
        UpdateValue(rawValue)
        if config.Callback then
            local success, err = pcall(config.Callback, currentVal)
            if not success then warn("[UI Library] Slider callback error:", err) end
        end
    end

    -- Track click handling
    trackBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            local percent = GetPercentFromPosition(input.Position)
            SetFromPercent(percent)
        end
    end)

    -- Thumb drag handling
    local thumbDragging = false
    local thumbConnections = {}

    thumb.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            thumbDragging = true
        end
    end)

    table.insert(thumbConnections, UserInputService.InputChanged:Connect(function(input)
        if not thumbDragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local percent = GetPercentFromPosition(input.Position)
            local rawValue = minVal + (maxVal - minVal) * percent
            UpdateValue(rawValue)
            if config.Callback then
                local success, err = pcall(config.Callback, currentVal)
                if not success then warn("[UI Library] Slider callback error:", err) end
            end
        end
    end))

    table.insert(thumbConnections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            thumbDragging = false
        end
    end))

    -- Initialize
    UpdateValue(currentVal)

    return {
        Frame = sliderFrame,
        SetValue = function(val)
            UpdateValue(val)
            if config.Callback then
                pcall(config.Callback, currentVal)
            end
        end,
        GetValue = function() return currentVal end,
        Destroy = function()
            for _, conn in ipairs(thumbConnections) do
                conn:Disconnect()
            end
        end,
    }
end

local function CreateTextbox(parent, config, theme)
    local currentText = config.Default or ""

    local textboxFrame = Create("Frame", {
        Name = config.Name or "Textbox",
        BackgroundColor3 = theme.Element,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 0,
        Parent = parent,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = textboxFrame })

    local nameLabel = Create("TextLabel", {
        Text = config.Name or "",
        TextColor3 = theme.Text,
        Font = Enum.Font[FONT],
        TextSize = 13,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 100, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = textboxFrame,
    })

    -- Input background
    local inputBg = Create("Frame", {
        BackgroundColor3 = theme.Tertiary,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -120, 0, 30),
        Position = UDim2.new(1, -110, 0.5, -15),
        Parent = textboxFrame,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = inputBg })

    local textBox = Create("TextBox", {
        Text = currentText,
        PlaceholderText = config.Placeholder or "Enter text...",
        TextColor3 = theme.Text,
        PlaceholderColor3 = theme.SubText,
        Font = Enum.Font[FONT_MEDIUM],
        TextSize = 13,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = inputBg,
    })

    local isFocused = false

    textBox.Focused:Connect(function()
        isFocused = true
        Tween(inputBg, TWEEN_FAST, { BackgroundColor3 = theme.ElementHover })
    end)

    textBox.FocusLost:Connect(function(enterPressed)
        isFocused = false
        Tween(inputBg, TWEEN_FAST, { BackgroundColor3 = theme.Tertiary })
        if enterPressed then
            currentText = textBox.Text
            if config.Callback then
                local success, err = pcall(config.Callback, currentText)
                if not success then warn("[UI Library] Textbox callback error:", err) end
            end
        end
    end)

    -- Fire callback on enter
    textBox:GetPropertyChangedSignal("Text"):Connect(function()
        currentText = textBox.Text
    end)

    return {
        Frame = textboxFrame,
        SetText = function(text)
            textBox.Text = text
            currentText = text
        end,
        GetText = function() return currentText end,
    }
end

local function CreateLabel(parent, config, theme)
    local labelFrame = Create("Frame", {
        Name = config.Name or "Label",
        BackgroundColor3 = theme.Secondary,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 0,
        Parent = parent,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = labelFrame })

    local labelText = Create("TextLabel", {
        Text = config.Name or "",
        TextColor3 = theme.SubText,
        Font = Enum.Font[FONT_LIGHT],
        TextSize = 13,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = labelFrame,
    })

    return {
        Frame = labelFrame,
        SetText = function(text) labelText.Text = text end,
        GetText = function() return labelText.Text end,
    }
end

local function CreateDropdown(parent, config, theme, windowFrame)
    local options = config.Options or {}
    local currentOption = config.Default or (options[1] or "")
    local isOpen = false

    local dropdownFrame = Create("Frame", {
        Name = config.Name or "Dropdown",
        BackgroundColor3 = theme.Element,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 0,
        Parent = parent,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = dropdownFrame })

    local nameLabel = Create("TextLabel", {
        Text = config.Name or "",
        TextColor3 = theme.Text,
        Font = Enum.Font[FONT],
        TextSize = 13,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 100, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = dropdownFrame,
    })

    -- Selected option display
    local selectedLabel = Create("TextLabel", {
        Text = currentOption,
        TextColor3 = theme.Accent,
        Font = Enum.Font[FONT_MEDIUM],
        TextSize = 13,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -160, 1, 0),
        Position = UDim2.new(0, 110, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = dropdownFrame,
    })

    -- Arrow indicator
    local arrowLabel = Create("TextLabel", {
        Text = "v",
        TextColor3 = theme.SubText,
        Font = Enum.Font[FONT],
        TextSize = 14,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 20, 1, 0),
        Position = UDim2.new(1, -30, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = dropdownFrame,
    })

    -- Dropdown list container (parented to windowFrame for overlay)
    local optionList = Create("Frame", {
        Name = "DropdownList",
        BackgroundColor3 = theme.ElementHover,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 0, 0), -- Hidden initially
        Visible = false,
        ZIndex = 100,
        Parent = windowFrame,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = optionList })
    Create("UIStroke", {
        Color = theme.Border,
        Transparency = 0.3,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = optionList,
    })

    local optionListLayout = Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        Parent = optionList,
    })

    local optionFrames = {}
    local clickConnection
    local function BuildOptions()
        -- Clear existing
        for _, opt in ipairs(optionFrames) do
            opt:Destroy()
        end
        optionFrames = {}

        local totalHeight = 0
        local optionHeight = 34

        for i, option in ipairs(options) do
            local optFrame = Create("Frame", {
                Name = option,
                BackgroundColor3 = theme.ElementHover,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, optionHeight),
                BackgroundTransparency = (option == currentOption) and 0.4 or 0,
                ZIndex = 101,
                Parent = optionList,
            })
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = optFrame })

            local optLabel = Create("TextLabel", {
                Text = option,
                TextColor3 = (option == currentOption) and theme.Accent or theme.Text,
                Font = Enum.Font[FONT_MEDIUM],
                TextSize = 13,
                BackgroundTransparency = 1,
                Size = UDim2.new(1, -16, 1, 0),
                Position = UDim2.new(0, 8, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 102,
                Parent = optFrame,
            })

            optFrame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    currentOption = option
                    selectedLabel.Text = option
                    Tween(dropdownFrame, TWEEN_FAST, { BackgroundColor3 = theme.Element })
                    CloseDropdown()
                    if config.Callback then
                        local success, err = pcall(config.Callback, currentOption)
                        if not success then warn("[UI Library] Dropdown callback error:", err) end
                    end
                end
            end)

            optFrame.MouseEnter:Connect(function()
                Tween(optFrame, TWEEN_FAST, { BackgroundTransparency = 0 })
                Tween(optLabel, TWEEN_FAST, { TextColor3 = theme.Accent })
            end)

            optFrame.MouseLeave:Connect(function()
                if option ~= currentOption then
                    Tween(optFrame, TWEEN_FAST, { BackgroundTransparency = 0.2 })
                    Tween(optLabel, TWEEN_FAST, { TextColor3 = theme.Text })
                end
            end)

            table.insert(optionFrames, optFrame)
            totalHeight = totalHeight + optionHeight
        end

        totalHeight = totalHeight + 8 -- padding
        optionList.Size = UDim2.new(1, 0, 0, totalHeight)
    end

    local function PositionDropdown()
        -- Calculate position relative to window
        local dropdownAbsPos = dropdownFrame.AbsolutePosition
        local dropdownAbsSize = dropdownFrame.AbsoluteSize
        local windowAbsPos = windowFrame.AbsolutePosition

        local relativeX = dropdownAbsPos.X - windowAbsPos.X
        local relativeY = dropdownAbsPos.Y + dropdownAbsSize.Y - windowAbsPos.Y + 2

        -- Adjust width to match dropdown
        local dropdownWidth = dropdownAbsSize.X

        optionList.Position = UDim2.new(0, relativeX, 0, relativeY)
        optionList.Size = UDim2.new(0, dropdownWidth, 0, optionList.Size.Y.Offset)
    end

    local function OpenDropdown()
        if isOpen then return end
        isOpen = true
        PositionDropdown()
        BuildOptions()
        optionList.Visible = true
        Tween(optionList, TWEEN_FAST, { BackgroundTransparency = 0 })
        Tween(arrowLabel, TWEEN_FAST, { Rotation = 180, TextColor3 = theme.Accent })
        Tween(dropdownFrame, TWEEN_FAST, { BackgroundColor3 = theme.ElementHover })

        -- Defer so the current click doesn't immediately close the dropdown
        task.defer(function()
            if not isOpen then return end
            clickConnection = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            local clickPos = input.Position
            local inDropdown = false

            -- Check if click is within dropdown frame
            local ddPos = dropdownFrame.AbsolutePosition
            local ddSize = dropdownFrame.AbsoluteSize
            if clickPos.X >= ddPos.X and clickPos.X <= ddPos.X + ddSize.X
                and clickPos.Y >= ddPos.Y and clickPos.Y <= ddPos.Y + ddSize.Y then
                inDropdown = true
            end

            -- Check if click is within option list
            if optionList.Visible then
                local olPos = optionList.AbsolutePosition
                local olSize = optionList.AbsoluteSize
                if clickPos.X >= olPos.X and clickPos.X <= olPos.X + olSize.X
                    and clickPos.Y >= olPos.Y and clickPos.Y <= olPos.Y + olSize.Y then
                    inDropdown = true
                end
            end

            if not inDropdown then
                CloseDropdown()
            end
        end)
        end)
    end

    local function CloseDropdown()
        if not isOpen then return end
        isOpen = false
        optionList.Visible = false
        Tween(arrowLabel, TWEEN_FAST, { Rotation = 0, TextColor3 = theme.SubText })
        Tween(dropdownFrame, TWEEN_FAST, { BackgroundColor3 = theme.Element })
        if clickConnection then
            clickConnection:Disconnect()
            clickConnection = nil
        end
    end

    dropdownFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if isOpen then
                CloseDropdown()
            else
                OpenDropdown()
            end
        end
    end)

    return {
        Frame = dropdownFrame,
        ListFrame = optionList,
        SetValue = function(option)
            if table.find(options, option) then
                currentOption = option
                selectedLabel.Text = option
                if config.Callback then
                    pcall(config.Callback, currentOption)
                end
            end
        end,
        GetValue = function() return currentOption end,
        Destroy = function()
            optionList:Destroy()
            if clickConnection then clickConnection:Disconnect() end
        end,
    }
end

-- ============================================================
-- TAB CLASS
-- ============================================================
local Tab = {}
Tab.__index = Tab

function Tab.new(name, icon, contentFrame, theme)
    local self = setmetatable({}, Tab)
    self.Name = name
    self.Icon = icon
    self.ContentFrame = contentFrame
    self.Theme = theme
    self.Components = {}
    self.Dropdowns = {}

    -- Create scrolling frame for components
    local scrollFrame = Create("ScrollingFrame", {
        Name = "ScrollFrame_" .. name,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = theme.ScrollBar,
        ScrollBarImageTransparency = 0.4,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = contentFrame,
    })

    local layout = Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = scrollFrame,
    })

    Create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        Parent = scrollFrame,
    })

    self.ScrollFrame = scrollFrame
    self.Layout = layout

    return self
end

function Tab:AddButton(config)
    local btn = CreateButton(self.ScrollFrame, config, self.Theme)
    table.insert(self.Components, btn)
    return btn
end

function Tab:AddToggle(config)
    local toggle = CreateToggle(self.ScrollFrame, config, self.Theme)
    table.insert(self.Components, toggle)
    return toggle
end

function Tab:AddSlider(config)
    local slider = CreateSlider(self.ScrollFrame, config, self.Theme)
    table.insert(self.Components, slider)
    return slider
end

function Tab:AddTextbox(config)
    local textbox = CreateTextbox(self.ScrollFrame, config, self.Theme)
    table.insert(self.Components, textbox)
    return textbox
end

function Tab:AddLabel(config)
    local label = CreateLabel(self.ScrollFrame, config, self.Theme)
    table.insert(self.Components, label)
    return label
end

function Tab:AddDropdown(config)
    -- Need reference to the window frame for overlay dropdowns
    local windowFrame = self.ContentFrame.Parent.Parent
    local dropdown = CreateDropdown(self.ScrollFrame, config, self.Theme, windowFrame)
    table.insert(self.Components, dropdown)
    table.insert(self.Dropdowns, dropdown)
    return dropdown
end

function Tab:SetVisible(visible)
    self.ContentFrame.Visible = visible
end

-- ============================================================
-- WINDOW CLASS
-- ============================================================
local Window = {}
Window.__index = Window

function Window.new(config, theme)
    local self = setmetatable({}, Window)
    self.Title = config.Title or "UI Library"
    self.Theme = theme
    self.Tabs = {}
    self.ActiveTab = nil

    -- Create ScreenGui
    local screenGui = Create("ScreenGui", {
        Name = "UILib_" .. (config.Title or "Window"),
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        Parent = CoreGui,
    })

    -- Main window frame
    local windowSize = config.Size or Vector2.new(560, 450)
    local windowPos = config.Position or UDim2.new(0.5, -windowSize.X/2, 0.5, -windowSize.Y/2)

    local mainFrame = Create("Frame", {
        Name = "MainFrame",
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.new(0, windowSize.X, 0, windowSize.Y),
        Position = windowPos,
        Active = true,
        Parent = screenGui,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = mainFrame })

    -- Window shadow
    Create("UIStroke", {
        Color = Color3.fromRGB(0, 0, 0),
        Transparency = 0.5,
        Thickness = 2,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = mainFrame,
    })

    -- Title bar
    local titleBar = Create("Frame", {
        Name = "TitleBar",
        BackgroundColor3 = theme.Secondary,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 36),
        Active = true,
        Parent = mainFrame,
    })
    Create("UICorner", {
        CornerRadius = UDim.new(0, 10),
        Parent = titleBar,
    })
    -- Only round top corners by covering bottom
    local titleBarCover = Create("Frame", {
        BackgroundColor3 = theme.Secondary,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 1, -10),
        Parent = titleBar,
    })

    -- Accent line under title bar
    Create("Frame", {
        BackgroundColor3 = theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2.new(1, -16, 0, 2),
        Position = UDim2.new(0, 8, 1, -2),
        BackgroundTransparency = 0.3,
        Parent = titleBar,
    })

    local titleLabel = Create("TextLabel", {
        Text = config.Title or "UI Library",
        TextColor3 = theme.Text,
        Font = Enum.Font[FONT],
        TextSize = 15,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleBar,
    })

    -- Tab bar
    local tabBar = Create("Frame", {
        Name = "TabBar",
        BackgroundColor3 = theme.Secondary,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 38),
        Position = UDim2.new(0, 0, 0, 36),
        Parent = mainFrame,
    })

    local tabBarLayout = Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 4),
        Parent = tabBar,
    })

    Create("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 4),
        Parent = tabBar,
    })

    -- Separator between tab bar and content
    Create("Frame", {
        BackgroundColor3 = theme.Border,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 0, 74),
        BackgroundTransparency = 0.4,
        Parent = mainFrame,
    })

    -- Tab content area
    local contentArea = Create("Frame", {
        Name = "ContentArea",
        BackgroundColor3 = theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, -75),
        Position = UDim2.new(0, 0, 0, 75),
        Parent = mainFrame,
    })

    -- Make window draggable
    self.DragDisconnect = MakeDraggable(mainFrame, titleBar, true)

    self.ScreenGui = screenGui
    self.MainFrame = mainFrame
    self.TitleBar = titleBar
    self.TabBar = tabBar
    self.TabBarLayout = tabBarLayout
    self.ContentArea = contentArea

    return self
end

function Window:AddTab(config)
    local tabName = config.Name or "Tab " .. (#self.Tabs + 1)
    local tabIcon = config.Icon

    -- Create tab button
    local tabButton = Create("Frame", {
        Name = "TabBtn_" .. tabName,
        BackgroundColor3 = self.Theme.Tertiary,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 120, 0, 30),
        BackgroundTransparency = 0,
        Parent = self.TabBar,
    })
    Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = tabButton })

    local tabBtnLabel = Create("TextLabel", {
        Text = tabName,
        TextColor3 = self.Theme.SubText,
        Font = Enum.Font[FONT],
        TextSize = 13,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -8, 1, 0),
        Position = UDim2.new(0, 4, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = tabButton,
    })

    -- If icon is provided, adjust layout
    if tabIcon then
        tabBtnLabel.Size = UDim2.new(1, -24, 1, 0)
        tabBtnLabel.Position = UDim2.new(0, 20, 0, 0)

        local iconImage = Create("ImageLabel", {
            Image = tabIcon,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 14, 0, 14),
            Position = UDim2.new(0, 4, 0.5, -7),
            Parent = tabButton,
        })
    end

    -- Create tab content frame
    local tabContent = Create("Frame", {
        Name = "TabContent_" .. tabName,
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = #self.Tabs == 0, -- Only first tab visible initially
        Parent = self.ContentArea,
    })

    -- Create the Tab object
    local tab = Tab.new(tabName, tabIcon, tabContent, self.Theme)
    tab.TabButton = tabButton
    tab.TabBtnLabel = tabBtnLabel
    tab.IconImage = tabIcon and tabButton:FindFirstChildOfClass("ImageLabel") or nil

    -- Click handler for tab switching
    tabButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:SwitchTab(tab)
        end
    end)

    -- Hover effects
    tabButton.MouseEnter:Connect(function()
        if self.ActiveTab ~= tab then
            Tween(tabButton, TWEEN_FAST, { BackgroundColor3 = self.Theme.ElementHover })
        end
    end)

    tabButton.MouseLeave:Connect(function()
        if self.ActiveTab ~= tab then
            Tween(tabButton, TWEEN_FAST, { BackgroundColor3 = self.Theme.Tertiary })
        end
    end)

    table.insert(self.Tabs, tab)
    return tab
end

function Window:SwitchTab(tab)
    if self.ActiveTab == tab then return end

    -- Deactivate all tabs
    for _, t in ipairs(self.Tabs) do
        t:SetVisible(false)
        if t.TabButton then
            Tween(t.TabButton, TWEEN_FAST, {
                BackgroundColor3 = self.Theme.Tertiary,
                BackgroundTransparency = 0,
            })
            if t.TabBtnLabel then
                Tween(t.TabBtnLabel, TWEEN_FAST, { TextColor3 = self.Theme.SubText })
            end
        end
    end

    -- Activate target tab
    tab:SetVisible(true)
    self.ActiveTab = tab

    if tab.TabButton then
        Tween(tab.TabButton, TWEEN_FAST, {
            BackgroundColor3 = self.Theme.Accent,
            BackgroundTransparency = 0,
        })
        if tab.TabBtnLabel then
            Tween(tab.TabBtnLabel, TWEEN_FAST, { TextColor3 = Color3.fromRGB(255, 255, 255) })
        end
    end
end

function Window:Destroy()
    if self.DragDisconnect then
        self.DragDisconnect()
    end
    -- Destroy dropdown list frames
    for _, tab in ipairs(self.Tabs) do
        for _, dd in ipairs(tab.Dropdowns) do
            pcall(dd.Destroy, dd)
        end
    end
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

-- ============================================================
-- LIBRARY ENTRY POINT
-- ============================================================

local Library = {}

function Library:CreateWindow(config)
    if not config or not config.Title then
        error("[UI Library] CreateWindow requires a Title in the config table.")
    end

    local themeName = config.Theme or "Dark"
    local theme = Themes[themeName] or Themes.Dark

    -- Override accent color if provided
    if config.AccentColor then
        theme = {}
        for k, v in pairs(Themes[themeName] or Themes.Dark) do
            theme[k] = v
        end
        theme.Accent = config.AccentColor
        theme.AccentHover = config.AccentColor:Lerp(Color3.fromRGB(255, 255, 255), 0.1)
    end

    return Window.new(config, theme)
end

return Library
