








































































if _G.VialLibrary_Instance then
    if _G.VialLibrary_Instance.Unload ~= nil then
        _G.VialLibrary_Instance.Unload = true
    end
    if _G.VialLibrary_Instance.Open and Ham and Ham.toggleMouse then
        Ham.toggleMouse()
    end
    Citizen.CreateThread(function()
        if _G.VialLibrary_Instance and _G.VialLibrary_Instance.UIThread then
            local waitCount = 0
            while _G.VialLibrary_Instance and _G.VialLibrary_Instance.UIThread and waitCount < 20 do
                Citizen.Wait(10)
                waitCount = waitCount + 1
            end
        end
        if _G.VialLibrary_Instance then
            _G.VialLibrary_Instance.Windows = {}
            _G.VialLibrary_Instance.Notifications = {}
            _G.VialLibrary_Instance.Labels = {}
            _G.VialLibrary_Instance.UIThread = nil
            _G.VialLibrary_Instance = nil
        end
    end)
end

local KeyCodeMap = {
    [8] = "BACKSPACE", [9] = "TAB", [13] = "ENTER", [16] = "SHIFT", [17] = "CTRL", [18] = "ALT", [19] = "PAUSE",
    [20] = "CAPS", [27] = "ESC", [32] = "SPACE", [33] = "PAGE UP", [34] = "PAGE DOWN", [35] = "END", [36] = "HOME",
    [37] = "LEFT", [38] = "UP", [39] = "RIGHT", [40] = "DOWN", [45] = "INSERT", [46] = "DELETE",
    [48] = "0", [49] = "1", [50] = "2", [51] = "3", [52] = "4", [53] = "5", [54] = "6", [55] = "7", [56] = "8", [57] = "9",
    [65] = "A", [66] = "B", [67] = "C", [68] = "D", [69] = "E", [70] = "F", [71] = "G", [72] = "H", [73] = "I", [74] = "J",
    [75] = "K", [76] = "L", [77] = "M", [78] = "N", [79] = "O", [80] = "P", [81] = "Q", [82] = "R", [83] = "S", [84] = "T",
    [85] = "U", [86] = "V", [87] = "W", [88] = "X", [89] = "Y", [90] = "Z",
    [96] = "NUMPAD 0", [97] = "NUMPAD 1", [98] = "NUMPAD 2", [99] = "NUMPAD 3", [100] = "NUMPAD 4", [101] = "NUMPAD 5",
    [102] = "NUMPAD 6", [103] = "NUMPAD 7", [104] = "NUMPAD 8", [105] = "NUMPAD 9", [106] = "NUMPAD *", [107] = "NUMPAD +",
    [109] = "NUMPAD -", [110] = "NUMPAD .", [111] = "NUMPAD /",
    [112] = "F1", [113] = "F2", [114] = "F3", [115] = "F4", [116] = "F5", [117] = "F6", [118] = "F7", [119] = "F8",
    [120] = "F9", [121] = "F10", [122] = "F11", [123] = "F12",
    [144] = "NUM LOCK", [145] = "SCROLL LOCK",
    [186] = ";", [187] = "=", [188] = ",", [189] = "-", [190] = ".", [191] = "/", [192] = "`",
    [219] = "[", [220] = "\\", [221] = "]", [222] = "'"
}

local ValidKeyCodes = {}
for k, _ in pairs(KeyCodeMap) do
    table.insert(ValidKeyCodes, k)
end
table.sort(ValidKeyCodes)

local function GetKeyName(keyCode)
    return KeyCodeMap[keyCode] or ("KEY " .. tostring(keyCode))
end

local VialLibrary = {}
VialLibrary.__index = VialLibrary

function VialLibrary:New(config)
    config = config or {}
    local self = setmetatable({}, VialLibrary)
    
    self.Unload = false
    self.ToggleKey = config.ToggleKey or 45
    self.Open = true
    self.Input = {
        MX = 0,
        MY = 0,
        MouseDown = false,
        MouseClicked = false,
        MouseRightClicked = false
    }
    self.TargetDpi = config.DPI or 1.0
    self.SearchBarClickConsumed = false
    self.LastRightClickState = false
    
    if self.Open then
        if type(self.ToggleKey) == "number" then
            local keyState = Ham.getKeyState(self.ToggleKey)
            self.LastToggleKeyState = keyState ~= 0
        elseif type(self.ToggleKey) == "string" then
            local keyCode = nil
            if self.ToggleKey == "Insert" then
                keyCode = 45
            end
            if keyCode then
                local keyState = Ham.getKeyState(keyCode)
                self.LastToggleKeyState = keyState ~= 0
            else
                self.LastToggleKeyState = false
            end
        else
            self.LastToggleKeyState = false
        end
    else
        self.LastToggleKeyState = false
    end
    self.SearchIconIndex = 1
    self.SearchIconTimer = 0
    local defaultColors = {
        Background = {20, 22, 28, 255},
        Sidebar = {12, 14, 18, 255},
        Element = {28, 30, 38, 255},
        Accent = {138, 99, 210, 255},
        AccentGlow = {138, 99, 210, 120},
        Text = {255, 255, 255, 255},
        TextDim = {200, 200, 210, 255},
        Border = {40, 42, 50, 255},
        Dropdown = {32, 34, 42, 255},
        Hover = {42, 44, 54, 255},
        Footer = {15, 17, 23, 255}
    }

    self.Colors = {}
    for k, v in pairs(defaultColors) do
        self.Colors[k] = v
    end

    if config.Colors then
        for k, v in pairs(config.Colors) do
            self.Colors[k] = v
        end
    end
    
    self.FooterText = config.FooterText or "Rebirth"
    self.FooterTag = config.FooterTag or "BETA"
    self.MenuTitle = config.MenuTitle or "Menu"
    self.FooterSearchPlaceholder = config.FooterSearchPlaceholder or "Search For An Option..."
    self.StartOpened = config.StartOpened or false
    self.FooterSearchText = ""
    self.FooterSearchFocused = false
    self.FooterSearchKeyStates = {}
    self.SearchIconIndex = 1
    self.SearchIconTimer = 0
    self.SearchBarClickConsumed = false
    
    self.menuDpi = config.DPI or 1.0
    self.menuColor = config.MenuColor or {138, 99, 210, 255}
    self.rainbowTheme = config.RainbowTheme or false
    self.selectedTheme = config.Theme or 1
    self.uiOpacity = config.UIOpacity or 255
    self.backgroundOpacity = config.BackgroundOpacity or 255
    self.sidebarOpacity = config.SidebarOpacity or 255
    self.elementOpacity = config.ElementOpacity or 255
    
    
    if config.GearIcon then
        self.gearIconTexture = Ham.addCustomTexture("gear_icon", config.GearIcon)
    end
    
    if config.PaletteIcon then
        self.paletteIconTexture = Ham.addCustomTexture("palette_icon", config.PaletteIcon)
    end
    
    self.customFont = nil
    
    local fontSize = config.FontSize or 16
    local baseFont = Ham.addFont(1, fontSize)
    if baseFont then
        self.customFont = baseFont
        Ham.setFont(baseFont)
        Ham.resetFont()
    end
    
    self.Windows = {}
    self.Notifications = {}
    self.Labels = {}
    
    _G.VialLibrary_Instance = self
    
    return self
end

function VialLibrary:ShowNotification(message, isError)
    if not self.Notifications then
        self.Notifications = {}
    end
    
    local maxNotifications = 10
    if #self.Notifications >= maxNotifications then
        table.remove(self.Notifications, 1)
    end
    
    local notification = {
        Message = message,
        IsError = isError or false,
        Time = Citizen.GetGameTimer and Citizen.GetGameTimer() or 0,
        AnimProgress = 0.0,
        LifeTime = 3000
    }
    table.insert(self.Notifications, notification)
end

function VialLibrary:IsHovering(x, y, w, h)
    return self.Input.MX >= x and self.Input.MX <= x + w and self.Input.MY >= y and self.Input.MY <= y + h
end

function VialLibrary:CreateLabel()
    local Label = {
        Text = "",
        Parent = self
    }
    
    function Label:Update(text)
        self.Text = tostring(text or "")
    end
    
    if not self.Labels then
        self.Labels = {}
    end
    table.insert(self.Labels, Label)
    return Label
end

function VialLibrary:CreateWindow(title)
    local screenWidth, screenHeight = 1920, 1080
    if Ham and Ham.getResolution then
        screenWidth, screenHeight = Ham.getResolution()
    end
    local baseW = 600
    local baseH = 400
    local x = (screenWidth / 2) - (baseW / 2)
    local y = (screenHeight / 2) - (baseH / 2)
    
    local Window = {
        X = x,
        Y = y,
        W = baseW,
        H = baseH,
        Title = title or self.MenuTitle,
        Tabs = {},
        ActiveTab = nil,
        Dragging = false,
        DragOffset = {X = 0, Y = 0},
        BaseW = baseW,
        BaseH = baseH,
        Parent = self
    }

    function Window:AddTab(name)
        local Tab = {
            Name = name,
            SubTabs = {},
            ActiveSubTab = nil,
            Parent = Window
        }

        function Tab:AddSubTab(subName)
            local SubTab = {
                Name = subName,
                Sections = {Left = {}, Middle = {}, Right = {}},
                Parent = Tab
            }

            function SubTab:AddSection(secName, side)
                local Section = {
                    Name = secName,
                    Side = side or "left",
                    Elements = {},
                    CustomRender = nil,
                    Parent = SubTab
                }
                
                function Section:SetCustomRender(renderFunc)
                    self.CustomRender = renderFunc
                end

                function Section:AddButton(text, callback)
                    local buttonElem = {
                        Type = "Button",
                        Text = text,
                        Callback = callback
                    }
                    function buttonElem:AddKeybind(key)
                        self.Keybind = key
                        self.LastKeybindState = false
                        return self
                    end
                    table.insert(self.Elements, buttonElem)
                    return buttonElem
                end

                function Section:AddToggle(text, default, callback, rightClickCallback, colorPickerCallback)
                    local toggleElem = {
                        Type = "Toggle",
                        Text = text,
                        Value = default or false,
                        AnimValue = default and 1.0 or 0.0,
                        Callback = callback,
                        RightClickCallback = rightClickCallback,
                        ColorPickerCallback = colorPickerCallback,
                        PopupOpen = false,
                        PopupData = {}
                    }
                    function toggleElem:AddKeybind(key)
                        self.Keybind = key
                        self.LastKeybindState = false
                        return self
                    end
                    table.insert(self.Elements, toggleElem)
                    return toggleElem
                end

                function Section:AddSlider(text, min, max, default, callback)
                    local sliderElem = {
                        Type = "Slider",
                        Text = text,
                        Min = min,
                        Max = max,
                        Value = default or min,
                        Callback = callback,
                        Dragging = false,
                        Suffix = ""
                    }
                    function sliderElem:AddKeybind(key)
                        self.Keybind = key
                        self.LastKeybindState = false
                        return self
                    end
                    function sliderElem:SetSuffix(suffix)
                        self.Suffix = suffix or ""
                        return self
                    end
                    table.insert(self.Elements, sliderElem)
                    return sliderElem
                end

                function Section:AddDropdown(text, options, default, callback)
                    table.insert(self.Elements, {
                        Type = "Dropdown",
                        Text = text,
                        Options = options,
                        Selected = default or 1,
                        Open = false,
                        AnimValue = 0.0,
                        Callback = callback
                    })
                end

                function Section:AddMultiDropdown(text, options, default, callback)
                    local selectedTable = {}
                    if type(default) == "table" then
                        for _, idx in ipairs(default) do
                            table.insert(selectedTable, idx)
                        end
                    elseif default then
                        table.insert(selectedTable, default)
                    end
                    table.insert(self.Elements, {
                        Type = "MultiDropdown",
                        Text = text,
                        Options = options,
                        Selected = selectedTable,
                        Open = false,
                        AnimValue = 0.0,
                        ScrollOffset = 0,
                        Callback = callback
                    })
                end

                function Section:AddColorPicker(text, colorRef, callback)
                    table.insert(self.Elements, {
                        Type = "ColorPicker",
                        Text = text,
                        ColorRef = colorRef,
                        PopupOpen = false,
                        PopupData = {},
                        Callback = callback
                    })
                end

                function Section:AddSelector(text, options, default, callback)
                    table.insert(self.Elements, {
                        Type = "Selector",
                        Text = text,
                        Options = options,
                        Selected = default or 1,
                        Callback = callback
                    })
                end

                function Section:AddDivider()
                    table.insert(self.Elements, {
                        Type = "Divider"
                    })
                end

                function Section:AddLabel(text)
                    local labelElement = {
                        Type = "Label",
                        Text = text or ""
                    }
                    table.insert(self.Elements, labelElement)
                    return labelElement
                end

                if side == "right" then
                    table.insert(SubTab.Sections.Right, Section)
                elseif side == "middle" then
                    table.insert(SubTab.Sections.Middle, Section)
                else
                    table.insert(SubTab.Sections.Left, Section)
                end
                return Section
            end

            if not Tab.ActiveSubTab then Tab.ActiveSubTab = SubTab end
            table.insert(Tab.SubTabs, SubTab)
            return SubTab
        end

        if not Window.ActiveTab then Window.ActiveTab = Tab end
        if name == "Settings" then
            for i = #Window.Tabs, 1, -1 do
                if Window.Tabs[i].Name == "Settings" then
                    table.remove(Window.Tabs, i)
                end
            end
        end
        table.insert(Window.Tabs, Tab)
        if name == "Settings" then
            for i = 1, #Window.Tabs - 1 do
                if Window.Tabs[i] == Tab then
                    table.remove(Window.Tabs, i)
                    table.insert(Window.Tabs, Tab)
                    break
                end
            end
        end
        return Tab
    end

    function Window:Render()
        if not self.Parent.Open then
            if self.Parent.customFont then
                Ham.resetFont()
            end
            return
        end

        if self.Parent.customFont then
            Ham.setFont(self.Parent.customFont)
        end
        
        if not self.X or not self.Y or not self.W or not self.H then
            return
        end
        
        local titleBarH = 30 * self.Parent.menuDpi
        local isHoveringTitleBar = self.Parent:IsHovering(self.X, self.Y, self.W, titleBarH)
        
        local anyColorPickerDragging = false
        if self.ActiveTab and self.ActiveTab.ActiveSubTab then
            for _, sec in ipairs(self.ActiveTab.ActiveSubTab.Sections.Left) do
                for _, elem in ipairs(sec.Elements) do
                    if elem.Type == "ColorPicker" and elem.PopupData and elem.PopupData.ColorPicker and (elem.PopupData.ColorPicker.Dragging or elem.PopupData.ColorPicker.HueDragging) then
                        anyColorPickerDragging = true
                        break
                    end
                end
                if anyColorPickerDragging then break end
            end
            if not anyColorPickerDragging then
                for _, sec in ipairs(self.ActiveTab.ActiveSubTab.Sections.Middle) do
                    for _, elem in ipairs(sec.Elements) do
                        if elem.Type == "ColorPicker" and elem.PopupData and elem.PopupData.ColorPicker and (elem.PopupData.ColorPicker.Dragging or elem.PopupData.ColorPicker.HueDragging) then
                            anyColorPickerDragging = true
                            break
                        end
                    end
                    if anyColorPickerDragging then break end
                end
            end
            if not anyColorPickerDragging then
                for _, sec in ipairs(self.ActiveTab.ActiveSubTab.Sections.Right) do
                    for _, elem in ipairs(sec.Elements) do
                        if elem.Type == "ColorPicker" and elem.PopupData and elem.PopupData.ColorPicker and (elem.PopupData.ColorPicker.Dragging or elem.PopupData.ColorPicker.HueDragging) then
                            anyColorPickerDragging = true
                            break
                        end
                    end
                    if anyColorPickerDragging then break end
                end
            end
        end
        
        if self.Parent.Input.MouseDown and isHoveringTitleBar and not self.Dragging and not anyColorPickerDragging then
            self.Dragging = true
            self.DragOffset.X = self.Parent.Input.MX - self.X
            self.DragOffset.Y = self.Parent.Input.MY - self.Y
        end

        if not self.Parent.Input.MouseDown then
            self.Dragging = false
        end

        if self.Dragging and self.Parent.Input.MouseDown and not anyColorPickerDragging then
            self.X = self.Parent.Input.MX - self.DragOffset.X
            self.Y = self.Parent.Input.MY - self.DragOffset.Y
        end

        if not self.BaseW then
            self.BaseW = 600
        end
        
        if self.ActiveTab and self.ActiveTab.ActiveSubTab then
            local leftCount = #self.ActiveTab.ActiveSubTab.Sections.Left
            local middleCount = #self.ActiveTab.ActiveSubTab.Sections.Middle
            local rightCount = #self.ActiveTab.ActiveSubTab.Sections.Right
            local totalSections = leftCount + middleCount + rightCount
            local requiredW = 600
            if totalSections == 3 then
                requiredW = 750
            elseif totalSections == 2 then
                requiredW = 650
            end
            self.BaseW = requiredW
            
            local contentY = 70 * self.Parent.menuDpi
            local footerH = 40 * self.Parent.menuDpi
            local sectionSpacing = 10 * self.Parent.menuDpi
            local sectionHeaderH = 45 * self.Parent.menuDpi
            local maxSectionHeight = 0
            
            for _, sec in ipairs(self.ActiveTab.ActiveSubTab.Sections.Left) do
                local contentHeight = sectionHeaderH
                for _, elem in ipairs(sec.Elements) do
                    if elem.Type == "Button" then
                        contentHeight = contentHeight + 28 * self.Parent.menuDpi
                    elseif elem.Type == "Toggle" then
                        contentHeight = contentHeight + 28 * self.Parent.menuDpi
                    elseif elem.Type == "Slider" then
                        contentHeight = contentHeight + 25 * self.Parent.menuDpi
                    elseif elem.Type == "Dropdown" or elem.Type == "MultiDropdown" then
                        contentHeight = contentHeight + 28 * self.Parent.menuDpi
                    elseif elem.Type == "ColorPicker" then
                        contentHeight = contentHeight + 28 * self.Parent.menuDpi
                    elseif elem.Type == "Selector" then
                        contentHeight = contentHeight + 28 * self.Parent.menuDpi
                    elseif elem.Type == "Label" then
                        contentHeight = contentHeight + 30 * self.Parent.menuDpi
                    elseif elem.Type == "Divider" then
                        contentHeight = contentHeight + 15 * self.Parent.menuDpi
                    end
                end
                maxSectionHeight = math.max(maxSectionHeight, contentHeight)
            end
            
            for _, sec in ipairs(self.ActiveTab.ActiveSubTab.Sections.Middle) do
                local contentHeight = sectionHeaderH
                for _, elem in ipairs(sec.Elements) do
                    if elem.Type == "Button" then
                        contentHeight = contentHeight + 28 * self.Parent.menuDpi
                    elseif elem.Type == "Toggle" then
                        contentHeight = contentHeight + 28 * self.Parent.menuDpi
                    elseif elem.Type == "Slider" then
                        contentHeight = contentHeight + 25 * self.Parent.menuDpi
                    elseif elem.Type == "Dropdown" or elem.Type == "MultiDropdown" then
                        contentHeight = contentHeight + 28 * self.Parent.menuDpi
                    elseif elem.Type == "ColorPicker" then
                        contentHeight = contentHeight + 28 * self.Parent.menuDpi
                    elseif elem.Type == "Selector" then
                        contentHeight = contentHeight + 28 * self.Parent.menuDpi
                    elseif elem.Type == "Label" then
                        contentHeight = contentHeight + 30 * self.Parent.menuDpi
                    elseif elem.Type == "Divider" then
                        contentHeight = contentHeight + 15 * self.Parent.menuDpi
                    end
                end
                maxSectionHeight = math.max(maxSectionHeight, contentHeight)
            end
            
            for _, sec in ipairs(self.ActiveTab.ActiveSubTab.Sections.Right) do
                local contentHeight = sectionHeaderH
                for _, elem in ipairs(sec.Elements) do
                    if elem.Type == "Button" then
                        contentHeight = contentHeight + 28 * self.Parent.menuDpi
                    elseif elem.Type == "Toggle" then
                        contentHeight = contentHeight + 28 * self.Parent.menuDpi
                    elseif elem.Type == "Slider" then
                        contentHeight = contentHeight + 25 * self.Parent.menuDpi
                    elseif elem.Type == "Dropdown" or elem.Type == "MultiDropdown" then
                        contentHeight = contentHeight + 28 * self.Parent.menuDpi
                    elseif elem.Type == "ColorPicker" then
                        contentHeight = contentHeight + 28 * self.Parent.menuDpi
                    elseif elem.Type == "Selector" then
                        contentHeight = contentHeight + 28 * self.Parent.menuDpi
                    elseif elem.Type == "Label" then
                        contentHeight = contentHeight + 30 * self.Parent.menuDpi
                    elseif elem.Type == "Divider" then
                        contentHeight = contentHeight + 15 * self.Parent.menuDpi
                    end
                end
                maxSectionHeight = math.max(maxSectionHeight, contentHeight)
            end
            
            local requiredH = contentY + maxSectionHeight + footerH + 10
            self.BaseH = math.max(400, requiredH / self.Parent.menuDpi)
        else
            self.BaseH = 400
        end
        
        local scaledW = self.BaseW * self.Parent.menuDpi
        local scaledH = self.BaseH * self.Parent.menuDpi
        
        self.W = scaledW
        self.H = scaledH
        
        if self.Parent.rainbowTheme then
            local time = (Citizen.GetGameTimer and Citizen.GetGameTimer() or 0) / 1000.0
            local r = math.floor((math.sin(time * 2.0) + 1) * 127.5)
            local g = math.floor((math.sin(time * 2.0 + 2.094) + 1) * 127.5)
            local b = math.floor((math.sin(time * 2.0 + 4.188) + 1) * 127.5)
            self.Parent.Colors.Accent = {r, g, b, 255}
            self.Parent.Colors.AccentGlow = {r, g, b, 120}
        else
            self.Parent.Colors.Accent = self.Parent.menuColor
            self.Parent.Colors.AccentGlow = {self.Parent.menuColor[1], self.Parent.menuColor[2], self.Parent.menuColor[3], 120}
        end
        
        local bgColor = {self.Parent.Colors.Background[1], self.Parent.Colors.Background[2], self.Parent.Colors.Background[3], self.Parent.backgroundOpacity}
        local sidebarColor = {self.Parent.Colors.Sidebar[1], self.Parent.Colors.Sidebar[2], self.Parent.Colors.Sidebar[3], self.Parent.sidebarOpacity}
        local elementColor = {self.Parent.Colors.Element[1], self.Parent.Colors.Element[2], self.Parent.Colors.Element[3], self.Parent.elementOpacity}
        local borderColor = {self.Parent.Colors.Border[1], self.Parent.Colors.Border[2], self.Parent.Colors.Border[3], self.Parent.uiOpacity}
        
        Ham.drawRectFilled({x = self.X, y = self.Y, w = scaledW, h = scaledH}, bgColor, 12 * self.Parent.menuDpi, 15)
        Ham.drawRect({x = self.X, y = self.Y}, {x = self.X + scaledW, y = self.Y + scaledH}, borderColor, 12 * self.Parent.menuDpi, 0, 2)
        
        if self.Parent.selectedTheme == 2 then
            local sidebarTopColor = {math.min(255, math.max(0, self.Parent.Colors.Sidebar[1] + 12)), math.min(255, math.max(0, self.Parent.Colors.Sidebar[2] + 12)), math.min(255, math.max(0, self.Parent.Colors.Sidebar[3] + 12)), self.Parent.sidebarOpacity}
            local sidebarBottomColor = {math.min(255, math.max(0, self.Parent.Colors.Sidebar[1] - 12)), math.min(255, math.max(0, self.Parent.Colors.Sidebar[2] - 12)), math.min(255, math.max(0, self.Parent.Colors.Sidebar[3] - 12)), self.Parent.sidebarOpacity}
            Ham.drawRectGradient({x = self.X, y = self.Y, w = 180 * self.Parent.menuDpi, h = scaledH}, sidebarTopColor, sidebarBottomColor, true)
            Ham.drawRect({x = self.X, y = self.Y}, {x = self.X + 180 * self.Parent.menuDpi, y = self.Y + scaledH}, borderColor, 12 * self.Parent.menuDpi, 0, 1)
        elseif self.Parent.selectedTheme == 3 then
            local sidebarLeftColor = {math.min(255, math.max(0, self.Parent.Colors.Sidebar[1] + 15)), math.min(255, math.max(0, self.Parent.Colors.Sidebar[2] + 15)), math.min(255, math.max(0, self.Parent.Colors.Sidebar[3] + 15)), self.Parent.sidebarOpacity}
            local sidebarRightColor = {math.min(255, math.max(0, self.Parent.Colors.Sidebar[1] - 15)), math.min(255, math.max(0, self.Parent.Colors.Sidebar[2] - 15)), math.min(255, math.max(0, self.Parent.Colors.Sidebar[3] - 15)), self.Parent.sidebarOpacity}
            Ham.drawRectGradient({x = self.X, y = self.Y, w = 180 * self.Parent.menuDpi, h = scaledH}, sidebarLeftColor, sidebarRightColor, false)
            Ham.drawRect({x = self.X, y = self.Y}, {x = self.X + 180 * self.Parent.menuDpi, y = self.Y + scaledH}, borderColor, 12 * self.Parent.menuDpi, 0, 1)
        elseif self.Parent.selectedTheme == 4 then
            local sidebarTopColor = {math.min(255, math.max(0, self.Parent.Colors.Sidebar[1] + 10)), math.min(255, math.max(0, self.Parent.Colors.Sidebar[2] + 10)), math.min(255, math.max(0, self.Parent.Colors.Sidebar[3] + 10)), self.Parent.sidebarOpacity}
            local sidebarBottomColor = {math.min(255, math.max(0, self.Parent.Colors.Sidebar[1] - 10)), math.min(255, math.max(0, self.Parent.Colors.Sidebar[2] - 10)), math.min(255, math.max(0, self.Parent.Colors.Sidebar[3] - 10)), self.Parent.sidebarOpacity}
            Ham.drawRectGradient({x = self.X, y = self.Y, w = 180 * self.Parent.menuDpi, h = scaledH}, sidebarTopColor, sidebarBottomColor, true)
            Ham.drawRect({x = self.X, y = self.Y}, {x = self.X + 180 * self.Parent.menuDpi, y = self.Y + scaledH}, borderColor, 12 * self.Parent.menuDpi, 0, 1)
        else
            Ham.drawRectFilled({x = self.X, y = self.Y, w = 180 * self.Parent.menuDpi, h = scaledH}, sidebarColor, 12 * self.Parent.menuDpi, 5)
        end

        Ham.drawText(self.Title, {x = self.X + 90 * self.Parent.menuDpi, y = self.Y + 30 * self.Parent.menuDpi}, self.Parent.Colors.Text, 20 * self.Parent.menuDpi, true, false, {0,0,0,255})
        
        local lineY = self.Y + 55 * self.Parent.menuDpi
        local lineX = self.X + 15 * self.Parent.menuDpi
        local lineW = 150 * self.Parent.menuDpi
        Ham.drawRectFilled({x = lineX, y = lineY, w = lineW, h = 1}, self.Parent.Colors.Border, 0, 15)

        local anyColorPickerOpen = false
        local anyColorPickerDragging = false
        if self.ActiveTab and self.ActiveTab.ActiveSubTab then
            for _, sec in ipairs(self.ActiveTab.ActiveSubTab.Sections.Left) do
                for _, elem in ipairs(sec.Elements) do
                    if elem.Type == "ColorPicker" then
                        if elem.PopupOpen then
                            anyColorPickerOpen = true
                        end
                        if elem.PopupData and elem.PopupData.ColorPicker and (elem.PopupData.ColorPicker.Dragging or elem.PopupData.ColorPicker.HueDragging) then
                            anyColorPickerDragging = true
                        end
                    end
                end
                if anyColorPickerOpen and anyColorPickerDragging then break end
            end
            if not (anyColorPickerOpen and anyColorPickerDragging) then
                for _, sec in ipairs(self.ActiveTab.ActiveSubTab.Sections.Middle) do
                    for _, elem in ipairs(sec.Elements) do
                        if elem.Type == "ColorPicker" then
                            if elem.PopupOpen then
                                anyColorPickerOpen = true
                            end
                            if elem.PopupData and elem.PopupData.ColorPicker and (elem.PopupData.ColorPicker.Dragging or elem.PopupData.ColorPicker.HueDragging) then
                                anyColorPickerDragging = true
                            end
                        end
                    end
                    if anyColorPickerOpen and anyColorPickerDragging then break end
                end
            end
            if not (anyColorPickerOpen and anyColorPickerDragging) then
                for _, sec in ipairs(self.ActiveTab.ActiveSubTab.Sections.Right) do
                    for _, elem in ipairs(sec.Elements) do
                        if elem.Type == "ColorPicker" then
                            if elem.PopupOpen then
                                anyColorPickerOpen = true
                            end
                            if elem.PopupData and elem.PopupData.ColorPicker and (elem.PopupData.ColorPicker.Dragging or elem.PopupData.ColorPicker.HueDragging) then
                                anyColorPickerDragging = true
                            end
                        end
                    end
                    if anyColorPickerOpen and anyColorPickerDragging then break end
                end
            end
        end

        local tabY = self.Y + 80 * self.Parent.menuDpi
        local settingsTab = nil
        for _, tab in ipairs(self.Tabs) do
            if tab.Name ~= "Settings" then
                local active = self.ActiveTab == tab
                local hovered = self.Parent:IsHovering(self.X + 10 * self.Parent.menuDpi, tabY, 160 * self.Parent.menuDpi, 35 * self.Parent.menuDpi)
                local col = active and self.Parent.Colors.Hover or (hovered and {28, 30, 36, 255} or {0, 0, 0, 0})
                local textCol = active and self.Parent.Colors.Text or self.Parent.Colors.TextDim

                if hovered and self.Parent.Input.MouseClicked and not self.Parent.SearchBarClickConsumed and not anyColorPickerOpen then
                    self.ActiveTab = tab
                end

                if (self.Parent.selectedTheme == 2 or self.Parent.selectedTheme == 3 or self.Parent.selectedTheme == 4) and col[4] > 0 then
                    if self.Parent.selectedTheme == 2 then
                        local tabTopColor = {math.min(255, math.max(0, col[1] + 6)), math.min(255, math.max(0, col[2] + 6)), math.min(255, math.max(0, col[3] + 6)), col[4]}
                        local tabBottomColor = {math.min(255, math.max(0, col[1] - 6)), math.min(255, math.max(0, col[2] - 6)), math.min(255, math.max(0, col[3] - 6)), col[4]}
                        Ham.drawRectGradient({x = self.X + 10 * self.Parent.menuDpi, y = tabY, w = 160 * self.Parent.menuDpi, h = 35 * self.Parent.menuDpi}, tabTopColor, tabBottomColor, true)
                    elseif self.Parent.selectedTheme == 3 then
                        local tabLeftColor = {math.min(255, math.max(0, col[1] + 6)), math.min(255, math.max(0, col[2] + 6)), math.min(255, math.max(0, col[3] + 6)), col[4]}
                        local tabRightColor = {math.min(255, math.max(0, col[1] - 6)), math.min(255, math.max(0, col[2] - 6)), math.min(255, math.max(0, col[3] - 6)), col[4]}
                        Ham.drawRectGradient({x = self.X + 10 * self.Parent.menuDpi, y = tabY, w = 160 * self.Parent.menuDpi, h = 35 * self.Parent.menuDpi}, tabLeftColor, tabRightColor, false)
                    else
                        local tabTopColor = {math.min(255, math.max(0, col[1] + 4)), math.min(255, math.max(0, col[2] + 4)), math.min(255, math.max(0, col[3] + 4)), col[4]}
                        local tabBottomColor = {math.min(255, math.max(0, col[1] - 4)), math.min(255, math.max(0, col[2] - 4)), math.min(255, math.max(0, col[3] - 4)), col[4]}
                        Ham.drawRectGradient({x = self.X + 10 * self.Parent.menuDpi, y = tabY, w = 160 * self.Parent.menuDpi, h = 35 * self.Parent.menuDpi}, tabTopColor, tabBottomColor, true)
                    end
                else
                    Ham.drawRectFilled({x = self.X + 10 * self.Parent.menuDpi, y = tabY, w = 160 * self.Parent.menuDpi, h = 35 * self.Parent.menuDpi}, col, 8 * self.Parent.menuDpi, 15)
                end
                if active then
                    Ham.drawRectFilled({x = self.X + 10 * self.Parent.menuDpi, y = tabY + 8 * self.Parent.menuDpi, w = 4 * self.Parent.menuDpi, h = 19 * self.Parent.menuDpi}, self.Parent.Colors.Accent, 2 * self.Parent.menuDpi, 15)
                    Ham.drawRectFilled({x = self.X + 10 * self.Parent.menuDpi, y = tabY + 8 * self.Parent.menuDpi, w = 4 * self.Parent.menuDpi, h = 19 * self.Parent.menuDpi}, self.Parent.Colors.AccentGlow, 2 * self.Parent.menuDpi, 15)
                end
                Ham.drawText(tab.Name, {x = self.X + 30 * self.Parent.menuDpi, y = tabY + 8 * self.Parent.menuDpi}, textCol, 15 * self.Parent.menuDpi, false, false, {0,0,0,255})
                tabY = tabY + 40 * self.Parent.menuDpi
            else
                settingsTab = tab
            end
        end
        if settingsTab then
            local active = self.ActiveTab == settingsTab
            local hovered = self.Parent:IsHovering(self.X + 10 * self.Parent.menuDpi, tabY, 160 * self.Parent.menuDpi, 35 * self.Parent.menuDpi)
            local col = active and self.Parent.Colors.Hover or (hovered and {28, 30, 36, 255} or {0, 0, 0, 0})
            local textCol = active and self.Parent.Colors.Text or self.Parent.Colors.TextDim

            if hovered and self.Parent.Input.MouseClicked and not self.Parent.SearchBarClickConsumed and not anyColorPickerOpen then
                self.ActiveTab = settingsTab
            end

            if (self.Parent.selectedTheme == 2 or self.Parent.selectedTheme == 3 or self.Parent.selectedTheme == 4) and col[4] > 0 then
                if self.Parent.selectedTheme == 2 then
                    local tabTopColor = {math.min(255, math.max(0, col[1] + 6)), math.min(255, math.max(0, col[2] + 6)), math.min(255, math.max(0, col[3] + 6)), col[4]}
                    local tabBottomColor = {math.min(255, math.max(0, col[1] - 6)), math.min(255, math.max(0, col[2] - 6)), math.min(255, math.max(0, col[3] - 6)), col[4]}
                    Ham.drawRectGradient({x = self.X + 10 * self.Parent.menuDpi, y = tabY, w = 160 * self.Parent.menuDpi, h = 35 * self.Parent.menuDpi}, tabTopColor, tabBottomColor, true)
                elseif self.Parent.selectedTheme == 3 then
                    local tabLeftColor = {math.min(255, math.max(0, col[1] + 6)), math.min(255, math.max(0, col[2] + 6)), math.min(255, math.max(0, col[3] + 6)), col[4]}
                    local tabRightColor = {math.min(255, math.max(0, col[1] - 6)), math.min(255, math.max(0, col[2] - 6)), math.min(255, math.max(0, col[3] - 6)), col[4]}
                    Ham.drawRectGradient({x = self.X + 10 * self.Parent.menuDpi, y = tabY, w = 160 * self.Parent.menuDpi, h = 35 * self.Parent.menuDpi}, tabLeftColor, tabRightColor, false)
                else
                    local tabTopColor = {math.min(255, math.max(0, col[1] + 4)), math.min(255, math.max(0, col[2] + 4)), math.min(255, math.max(0, col[3] + 4)), col[4]}
                    local tabBottomColor = {math.min(255, math.max(0, col[1] - 4)), math.min(255, math.max(0, col[2] - 4)), math.min(255, math.max(0, col[3] - 4)), col[4]}
                    Ham.drawRectGradient({x = self.X + 10 * self.Parent.menuDpi, y = tabY, w = 160 * self.Parent.menuDpi, h = 35 * self.Parent.menuDpi}, tabTopColor, tabBottomColor, true)
                end
            else
                Ham.drawRectFilled({x = self.X + 10 * self.Parent.menuDpi, y = tabY, w = 160 * self.Parent.menuDpi, h = 35 * self.Parent.menuDpi}, col, 8 * self.Parent.menuDpi, 15)
            end
            if active then
                Ham.drawRectFilled({x = self.X + 10 * self.Parent.menuDpi, y = tabY + 8 * self.Parent.menuDpi, w = 4 * self.Parent.menuDpi, h = 19 * self.Parent.menuDpi}, self.Parent.Colors.Accent, 2 * self.Parent.menuDpi, 15)
                Ham.drawRectFilled({x = self.X + 10 * self.Parent.menuDpi, y = tabY + 8 * self.Parent.menuDpi, w = 4 * self.Parent.menuDpi, h = 19 * self.Parent.menuDpi}, self.Parent.Colors.AccentGlow, 2 * self.Parent.menuDpi, 15)
            end
            Ham.drawText(settingsTab.Name, {x = self.X + 30 * self.Parent.menuDpi, y = tabY + 8 * self.Parent.menuDpi}, textCol, 15 * self.Parent.menuDpi, false, false, {0,0,0,255})
        end
        
        local footerH = 40 * self.Parent.menuDpi
        local footerY = self.Y + scaledH - footerH
        local footerX = self.X
        
        Ham.drawRectFilled({x = footerX, y = footerY, w = scaledW, h = footerH}, self.Parent.Colors.Footer, 0, 15)
        Ham.drawRectFilled({x = footerX, y = footerY, w = 1, h = footerH}, self.Parent.Colors.Border, 0, 15)
        
        local footerLeftX = footerX + 15 * self.Parent.menuDpi
        local footerLeftY = footerY + footerH / 2
        
        local brandText = self.Parent.FooterText or "Rebirth"
        local brandColor1 = {138, 99, 210, 255}
        local brandColor2 = {99, 150, 255, 255}
        local brandTextWidth, _ = Ham.getTextWidth(brandText)
        local brandMidR = math.floor((brandColor1[1] + brandColor2[1]) / 2)
        local brandMidG = math.floor((brandColor1[2] + brandColor2[2]) / 2)
        local brandMidB = math.floor((brandColor1[3] + brandColor2[3]) / 2)
        Ham.drawText(brandText, {x = footerLeftX, y = footerLeftY - 8 * self.Parent.menuDpi}, {brandMidR, brandMidG, brandMidB, 255}, 14 * self.Parent.menuDpi, false, false, {0,0,0,255})
        
        local tagText = self.Parent.FooterTag or "BETA"
        local tagTextWidth, tagTextHeight = Ham.getTextWidth(tagText)
        local tagX = footerLeftX + brandTextWidth + 10 * self.Parent.menuDpi
        local tagY = footerLeftY - 10 * self.Parent.menuDpi
        local tagW = tagTextWidth + 16 * self.Parent.menuDpi
        local tagH = 20 * self.Parent.menuDpi
        
        Ham.drawRectFilled({x = tagX, y = tagY, w = tagW, h = tagH}, {0, 200, 0, 255}, 10 * self.Parent.menuDpi, 15)
        Ham.drawRect({x = tagX, y = tagY}, {x = tagX + tagW, y = tagY + tagH}, {0, 150, 0, 255}, 10 * self.Parent.menuDpi, 0, 1)
        Ham.drawText(tagText, {x = tagX + tagW / 2, y = tagY + 5 * self.Parent.menuDpi}, {255, 255, 255, 255}, 11 * self.Parent.menuDpi, true, false, {0,0,0,255})
        
        local searchBarW = 200 * self.Parent.menuDpi
        local searchBarH = 24 * self.Parent.menuDpi
        local searchBarX = footerX + scaledW - searchBarW - 15 * self.Parent.menuDpi
        local searchBarY = footerY + (footerH - searchBarH) / 2
        
        local searchHovered = self.Parent:IsHovering(searchBarX, searchBarY, searchBarW, searchBarH)
        local searchColor = self.Parent.FooterSearchFocused and self.Parent.Colors.Accent or (searchHovered and self.Parent.Colors.Hover or {38, 40, 48, 255})
        
        Ham.drawRectFilled({x = searchBarX, y = searchBarY, w = searchBarW, h = searchBarH}, searchColor, 5 * self.Parent.menuDpi, 15)
        Ham.drawRect({x = searchBarX, y = searchBarY}, {x = searchBarX + searchBarW, y = searchBarY + searchBarH}, self.Parent.Colors.Border, 5 * self.Parent.menuDpi, 0, 1)
        
        local searchIconX = searchBarX + 8 * self.Parent.menuDpi
        local searchIconY = searchBarY + 4 * self.Parent.menuDpi
        
        Ham.drawText("Q", {x = searchIconX, y = searchIconY}, self.Parent.Colors.TextDim, 14 * self.Parent.menuDpi, false, false, {0,0,0,255})
        
        local displaySearchText = self.Parent.FooterSearchText ~= "" and self.Parent.FooterSearchText or self.Parent.FooterSearchPlaceholder
        local searchTextColor = self.Parent.FooterSearchText ~= "" and self.Parent.Colors.Text or self.Parent.Colors.TextDim
        Ham.drawText(displaySearchText, {x = searchBarX + 28 * self.Parent.menuDpi, y = searchBarY + 6 * self.Parent.menuDpi}, searchTextColor, 11 * self.Parent.menuDpi, false, false, {0,0,0,255})
        
        local searchBarArea = {x = searchBarX, y = searchBarY, w = searchBarW, h = searchBarH}
        local isHoveringSearchBar = self.Parent:IsHovering(searchBarArea.x, searchBarArea.y, searchBarArea.w, searchBarArea.h)
        
        if isHoveringSearchBar and self.Parent.Input.MouseClicked and not anyColorPickerOpen then
            self.Parent.FooterSearchFocused = true
            self.Parent.SearchBarClickConsumed = true
        elseif self.Parent.FooterSearchFocused and self.Parent.Input.MouseClicked and not isHoveringSearchBar and not anyColorPickerOpen then
            self.Parent.FooterSearchFocused = false
        end
        
        if self.Parent.FooterSearchFocused and not anyColorPickerOpen then
            for i = 65, 90 do
                local keyState = Ham.getKeyState(i)
                if keyState ~= 0 then
                    if not self.Parent.FooterSearchKeyStates[i] then
                        local char = string.char(i)
                        if Ham.getKeyState(16) == 0 then
                            char = string.lower(char)
                        end
                        self.Parent.FooterSearchText = self.Parent.FooterSearchText .. char
                        self.Parent.FooterSearchKeyStates[i] = true
                    end
                else
                    self.Parent.FooterSearchKeyStates[i] = nil
                end
            end
            
            local spaceKey = Ham.getKeyState(32)
            if spaceKey ~= 0 then
                if not self.Parent.FooterSearchKeyStates[32] then
                    self.Parent.FooterSearchText = self.Parent.FooterSearchText .. " "
                    self.Parent.FooterSearchKeyStates[32] = true
                end
            else
                self.Parent.FooterSearchKeyStates[32] = nil
            end
            
            local backspaceKey = Ham.getKeyState(8)
            if backspaceKey ~= 0 then
                if not self.Parent.FooterSearchKeyStates[8] then
                    if #self.Parent.FooterSearchText > 0 then
                        self.Parent.FooterSearchText = string.sub(self.Parent.FooterSearchText, 1, #self.Parent.FooterSearchText - 1)
                    end
                    self.Parent.FooterSearchKeyStates[8] = true
                end
            else
                self.Parent.FooterSearchKeyStates[8] = nil
            end
        else
            self.Parent.FooterSearchKeyStates = {}
        end

        if self.ActiveTab then
            local subTabX = self.X + 200 * self.Parent.menuDpi
            local subTabY = self.Y + 20 * self.Parent.menuDpi
            
            for _, sub in ipairs(self.ActiveTab.SubTabs) do
                local active = self.ActiveTab.ActiveSubTab == sub
                local textWidth, textHeight = Ham.getTextWidth(sub.Name)
                local padding = 20 * self.Parent.menuDpi
                local spacing = 15 * self.Parent.menuDpi
                local width = textWidth + padding
                
                local hovered = self.Parent:IsHovering(subTabX, subTabY, width, 25 * self.Parent.menuDpi)
                local textCol = active and self.Parent.Colors.Text or (hovered and self.Parent.Colors.TextDim or {120, 120, 130, 255})

                if hovered and self.Parent.Input.MouseClicked and not self.Parent.SearchBarClickConsumed and not anyColorPickerOpen then
                    self.ActiveTab.ActiveSubTab = sub
                end

                Ham.drawText(sub.Name, {x = subTabX + padding / 2, y = subTabY}, textCol, 16 * self.Parent.menuDpi, false, false, {0,0,0,255})
                
                if active then
                    local highlightWidth = textWidth + 10 * self.Parent.menuDpi
                    local highlightX = subTabX + padding / 2 - 5 * self.Parent.menuDpi
                    Ham.drawRectFilled({x = highlightX, y = subTabY + 22 * self.Parent.menuDpi, w = highlightWidth, h = 3 * self.Parent.menuDpi}, self.Parent.Colors.Accent, 0, 15)
                    Ham.drawRectFilled({x = highlightX, y = subTabY + 22 * self.Parent.menuDpi, w = highlightWidth, h = 3 * self.Parent.menuDpi}, self.Parent.Colors.AccentGlow, 0, 15)
                end
                
                subTabX = subTabX + width + spacing
            end

            local searchText = string.lower(self.Parent.FooterSearchText or "")
            if searchText ~= "" then
                local foundTab = nil
                local foundSubTab = nil
                for _, tab in ipairs(self.Tabs) do
                    for _, subTab in ipairs(tab.SubTabs) do
                        for _, sec in ipairs(subTab.Sections.Left) do
                            for _, elem in ipairs(sec.Elements) do
                                if elem.Text and string.find(string.lower(elem.Text), searchText, 1, true) then
                                    foundTab = tab
                                    foundSubTab = subTab
                                    break
                                end
                            end
                            if foundTab then break end
                        end
                        if foundTab then break end
                        for _, sec in ipairs(subTab.Sections.Middle) do
                            for _, elem in ipairs(sec.Elements) do
                                if elem.Text and string.find(string.lower(elem.Text), searchText, 1, true) then
                                    foundTab = tab
                                    foundSubTab = subTab
                                    break
                                end
                            end
                            if foundTab then break end
                        end
                        if foundTab then break end
                        for _, sec in ipairs(subTab.Sections.Right) do
                            for _, elem in ipairs(sec.Elements) do
                                if elem.Text and string.find(string.lower(elem.Text), searchText, 1, true) then
                                    foundTab = tab
                                    foundSubTab = subTab
                                    break
                                end
                            end
                            if foundTab then break end
                        end
                        if foundTab then break end
                    end
                    if foundTab then break end
                end
                if foundTab and foundTab ~= self.ActiveTab then
                    self.ActiveTab = foundTab
                end
                if foundSubTab and foundSubTab ~= self.ActiveTab.ActiveSubTab then
                    self.ActiveTab.ActiveSubTab = foundSubTab
                end
            end

            if self.ActiveTab.ActiveSubTab then
                local contentY = self.Y + 70 * self.Parent.menuDpi
                local leftCount = #self.ActiveTab.ActiveSubTab.Sections.Left
                local middleCount = #self.ActiveTab.ActiveSubTab.Sections.Middle
                local rightCount = #self.ActiveTab.ActiveSubTab.Sections.Right
                local totalSections = leftCount + middleCount + rightCount
                
                local colW = 260 * self.Parent.menuDpi
                if totalSections == 3 then
                    colW = 240 * self.Parent.menuDpi
                elseif totalSections == 2 then
                    colW = 280 * self.Parent.menuDpi
                end
                
                local openPopups = {}
                local allOpenDropdowns = {}
                local rightClickHandled = false
                
                local footerH = 40 * self.Parent.menuDpi
                local sectionH = (self.Y + scaledH - footerH) - contentY - 10
                
                local function RenderSection(sec, x, y)
                    if sec.CustomRender then
                        sec.CustomRender(sec, x, y, self.Parent, allOpenDropdowns)
                        return
                    end
                    
                    if not sec.ScrollOffset then
                        sec.ScrollOffset = 0
                    end
                    
                    local contentStartY = y + 45 * self.Parent.menuDpi
                    local contentHeight = 0
                    local visibleElementCount = 0
                    for _, elem in ipairs(sec.Elements) do
                        if searchText == "" or (elem.Text and string.find(string.lower(elem.Text), searchText, 1, true)) then
                            visibleElementCount = visibleElementCount + 1
                            if elem.Type == "Button" then
                                contentHeight = contentHeight + 28 * self.Parent.menuDpi
                            elseif elem.Type == "Toggle" then
                                contentHeight = contentHeight + 28 * self.Parent.menuDpi
                            elseif elem.Type == "Slider" then
                                contentHeight = contentHeight + 25 * self.Parent.menuDpi
                            elseif elem.Type == "Dropdown" or elem.Type == "MultiDropdown" then
                                contentHeight = contentHeight + 28 * self.Parent.menuDpi
                            elseif elem.Type == "ColorPicker" then
                                contentHeight = contentHeight + 28 * self.Parent.menuDpi
                            elseif elem.Type == "Selector" then
                                contentHeight = contentHeight + 28 * self.Parent.menuDpi
                            elseif elem.Type == "Label" then
                                contentHeight = contentHeight + 30 * self.Parent.menuDpi
                            elseif elem.Type == "Divider" then
                                contentHeight = contentHeight + 15 * self.Parent.menuDpi
                            end
                        end
                    end
                    
                    local availableHeight = sectionH - 45 * self.Parent.menuDpi
                    local maxScroll = math.max(0, contentHeight - availableHeight)
                    
                    local sectionArea = {x = x, y = contentStartY, w = colW, h = availableHeight}
                    local isHoveringSection = self.Parent:IsHovering(sectionArea.x, sectionArea.y, sectionArea.w, sectionArea.h)
                    
                    if isHoveringSection and maxScroll > 0 then
                        DisableControlAction(0, 14, true)
                        DisableControlAction(0, 15, true)
                        
                        local scrollUp = IsControlJustPressed(0, 14)
                        local scrollDown = IsControlJustPressed(0, 15)
                        
                        if scrollUp then
                            sec.ScrollOffset = math.max(0, sec.ScrollOffset - 20 * self.Parent.menuDpi)
                        end
                        
                        if scrollDown then
                            sec.ScrollOffset = math.min(maxScroll, sec.ScrollOffset + 20 * self.Parent.menuDpi)
                        end
                    end
                    
                    sec.ScrollOffset = math.max(0, math.min(maxScroll, sec.ScrollOffset))
                    
                    local secElementColor = {self.Parent.Colors.Element[1], self.Parent.Colors.Element[2], self.Parent.Colors.Element[3], self.Parent.elementOpacity}
                    local secBorderColor = {self.Parent.Colors.Border[1], self.Parent.Colors.Border[2], self.Parent.Colors.Border[3], self.Parent.uiOpacity}
                    
                    if self.Parent.selectedTheme == 2 then
                        local elemTopColor = {math.min(255, math.max(0, self.Parent.Colors.Element[1] + 10)), math.min(255, math.max(0, self.Parent.Colors.Element[2] + 10)), math.min(255, math.max(0, self.Parent.Colors.Element[3] + 10)), self.Parent.elementOpacity}
                        local elemBottomColor = {math.min(255, math.max(0, self.Parent.Colors.Element[1] - 10)), math.min(255, math.max(0, self.Parent.Colors.Element[2] - 10)), math.min(255, math.max(0, self.Parent.Colors.Element[3] - 10)), self.Parent.elementOpacity}
                        Ham.drawRectGradient({x = x, y = y, w = colW, h = sectionH}, elemTopColor, elemBottomColor, true)
                    elseif self.Parent.selectedTheme == 3 then
                        local elemLeftColor = {math.min(255, math.max(0, self.Parent.Colors.Element[1] + 12)), math.min(255, math.max(0, self.Parent.Colors.Element[2] + 12)), math.min(255, math.max(0, self.Parent.Colors.Element[3] + 12)), self.Parent.elementOpacity}
                        local elemRightColor = {math.min(255, math.max(0, self.Parent.Colors.Element[1] - 12)), math.min(255, math.max(0, self.Parent.Colors.Element[2] - 12)), math.min(255, math.max(0, self.Parent.Colors.Element[3] - 12)), self.Parent.elementOpacity}
                        Ham.drawRectGradient({x = x, y = y, w = colW, h = sectionH}, elemLeftColor, elemRightColor, false)
                    elseif self.Parent.selectedTheme == 4 then
                        local elemTopColor = {math.min(255, math.max(0, self.Parent.Colors.Element[1] + 6)), math.min(255, math.max(0, self.Parent.Colors.Element[2] + 6)), math.min(255, math.max(0, self.Parent.Colors.Element[3] + 6)), self.Parent.elementOpacity}
                        local elemBottomColor = {math.min(255, math.max(0, self.Parent.Colors.Element[1] - 6)), math.min(255, math.max(0, self.Parent.Colors.Element[2] - 6)), math.min(255, math.max(0, self.Parent.Colors.Element[3] - 6)), self.Parent.elementOpacity}
                        Ham.drawRectGradient({x = x, y = y, w = colW, h = sectionH}, elemTopColor, elemBottomColor, true)
                    else
                        Ham.drawRectFilled({x = x, y = y, w = colW, h = sectionH}, secElementColor, 10 * self.Parent.menuDpi, 15)
                    end
                    Ham.drawRect({x = x, y = y}, {x = x + colW, y = y + sectionH}, secBorderColor, 10 * self.Parent.menuDpi, 0, 1)
                    Ham.drawRectFilled({x = x + 10 * self.Parent.menuDpi, y = y + 10 * self.Parent.menuDpi, w = 4 * self.Parent.menuDpi, h = 20 * self.Parent.menuDpi}, self.Parent.Colors.Accent, 2 * self.Parent.menuDpi, 15)
                    Ham.drawText(sec.Name, {x = x + 20 * self.Parent.menuDpi, y = y + 13 * self.Parent.menuDpi}, self.Parent.Colors.Accent, 16 * self.Parent.menuDpi, false, false, {0,0,0,255})
                    
                    local cy = contentStartY - sec.ScrollOffset
                    local contentEndY = contentStartY + availableHeight
                    for _, elem in ipairs(sec.Elements) do
                        if searchText ~= "" and elem.Text then
                            local elemText = string.lower(elem.Text)
                            if not string.find(elemText, searchText, 1, true) then
                                goto continue
                            end
                        end
                        
                        local elemHeight = 0
                        if elem.Type == "Button" then
                            elemHeight = 28 * self.Parent.menuDpi
                        elseif elem.Type == "Toggle" then
                            elemHeight = 28 * self.Parent.menuDpi
                        elseif elem.Type == "Slider" then
                            elemHeight = 25 * self.Parent.menuDpi
                        elseif elem.Type == "Dropdown" or elem.Type == "MultiDropdown" then
                            elemHeight = 28 * self.Parent.menuDpi
                        elseif elem.Type == "ColorPicker" then
                            elemHeight = 28 * self.Parent.menuDpi
                        elseif elem.Type == "Selector" then
                            elemHeight = 28 * self.Parent.menuDpi
                        elseif elem.Type == "Label" then
                            elemHeight = 30 * self.Parent.menuDpi
                        elseif elem.Type == "Divider" then
                            elemHeight = 15 * self.Parent.menuDpi
                        end
                        
                        if cy + elemHeight < contentStartY or cy > contentEndY then
                            cy = cy + elemHeight
                            goto continue
                        end
                        
                        local anyPopupOpen = false
                        for _, popupInfo in ipairs(openPopups) do
                            if popupInfo and popupInfo.elem and popupInfo.elem.PopupOpen then
                                anyPopupOpen = true
                                break
                            end
                        end
                        
                        if elem.Type == "Button" then
                            local btnH = 28 * self.Parent.menuDpi
                            local btnPad = 15 * self.Parent.menuDpi
                            local hovered = self.Parent:IsHovering(x + btnPad, cy, colW - btnPad * 2, btnH)
                            
                            if hovered then
                                if self.Parent.selectedTheme == 2 or self.Parent.selectedTheme == 3 or self.Parent.selectedTheme == 4 then
                                    local btnColor1 = {math.min(255, math.max(0, self.Parent.Colors.Accent[1] - 20)), math.min(255, math.max(0, self.Parent.Colors.Accent[2] - 20)), math.min(255, math.max(0, self.Parent.Colors.Accent[3] - 20)), 255}
                                    local btnColor2 = self.Parent.Colors.Accent
                                    if self.Parent.selectedTheme == 2 then
                                        Ham.drawRectGradient({x = x + btnPad, y = cy, w = colW - btnPad * 2, h = btnH}, btnColor2, btnColor1, true)
                                    elseif self.Parent.selectedTheme == 3 then
                                        Ham.drawRectGradient({x = x + btnPad, y = cy, w = colW - btnPad * 2, h = btnH}, btnColor2, btnColor1, false)
                                    else
                                        Ham.drawRectGradient({x = x + btnPad, y = cy, w = colW - btnPad * 2, h = btnH}, btnColor1, btnColor2, true)
                                    end
                                    Ham.drawRectFilled({x = x + btnPad, y = cy, w = colW - btnPad * 2, h = btnH}, self.Parent.Colors.AccentGlow, 6 * self.Parent.menuDpi, 15)
                                else
                                    Ham.drawRectFilled({x = x + btnPad, y = cy, w = colW - btnPad * 2, h = btnH}, self.Parent.Colors.Accent, 6 * self.Parent.menuDpi, 15)
                                    Ham.drawRectFilled({x = x + btnPad, y = cy, w = colW - btnPad * 2, h = btnH}, self.Parent.Colors.AccentGlow, 6 * self.Parent.menuDpi, 15)
                                end
                            else
                                local bCol = {48, 50, 58, 200}
                                if self.Parent.selectedTheme == 2 then
                                    local btnTopColor = {math.min(255, math.max(0, bCol[1] + 8)), math.min(255, math.max(0, bCol[2] + 8)), math.min(255, math.max(0, bCol[3] + 8)), bCol[4]}
                                    local btnBottomColor = {math.min(255, math.max(0, bCol[1] - 8)), math.min(255, math.max(0, bCol[2] - 8)), math.min(255, math.max(0, bCol[3] - 8)), bCol[4]}
                                    Ham.drawRectGradient({x = x + btnPad, y = cy, w = colW - btnPad * 2, h = btnH}, btnTopColor, btnBottomColor, true)
                                elseif self.Parent.selectedTheme == 3 then
                                    local btnLeftColor = {math.min(255, math.max(0, bCol[1] + 8)), math.min(255, math.max(0, bCol[2] + 8)), math.min(255, math.max(0, bCol[3] + 8)), bCol[4]}
                                    local btnRightColor = {math.min(255, math.max(0, bCol[1] - 8)), math.min(255, math.max(0, bCol[2] - 8)), math.min(255, math.max(0, bCol[3] - 8)), bCol[4]}
                                    Ham.drawRectGradient({x = x + btnPad, y = cy, w = colW - btnPad * 2, h = btnH}, btnLeftColor, btnRightColor, false)
                                else
                                    Ham.drawRectFilled({x = x + btnPad, y = cy, w = colW - btnPad * 2, h = btnH}, bCol, 6 * self.Parent.menuDpi, 15)
                                end
                            end
                            Ham.drawRect({x = x + btnPad, y = cy}, {x = x + colW - btnPad, y = cy + btnH}, self.Parent.Colors.Border, 6 * self.Parent.menuDpi, 0, 1)
                            Ham.drawText(elem.Text, {x = x + (colW/2), y = cy + 6 * self.Parent.menuDpi}, self.Parent.Colors.Text, 14 * self.Parent.menuDpi, true, false, {0,0,0,255})
                            
                            local anyDropdownOpen = #allOpenDropdowns > 0
                            local anyKeybindPopupOpen = false
                            if self.Parent.Windows then
                                for _, win in ipairs(self.Parent.Windows) do
                                    if win.ActiveTab and win.ActiveTab.ActiveSubTab then
                                        for _, s in ipairs(win.ActiveTab.ActiveSubTab.Sections.Left) do
                                            for _, e in ipairs(s.Elements) do
                                                if (e.Type == "Button" or e.Type == "Toggle" or e.Type == "Slider") and e.KeybindPopupOpen then
                                                    anyKeybindPopupOpen = true
                                                    break
                                                end
                                            end
                                            if anyKeybindPopupOpen then break end
                                        end
                                        if not anyKeybindPopupOpen then
                                            for _, s in ipairs(win.ActiveTab.ActiveSubTab.Sections.Middle) do
                                                for _, e in ipairs(s.Elements) do
                                                    if (e.Type == "Button" or e.Type == "Toggle" or e.Type == "Slider") and e.KeybindPopupOpen then
                                                        anyKeybindPopupOpen = true
                                                        break
                                                    end
                                                end
                                                if anyKeybindPopupOpen then break end
                                            end
                                        end
                                        if not anyKeybindPopupOpen then
                                            for _, s in ipairs(win.ActiveTab.ActiveSubTab.Sections.Right) do
                                                for _, e in ipairs(s.Elements) do
                                                    if (e.Type == "Button" or e.Type == "Toggle" or e.Type == "Slider") and e.KeybindPopupOpen then
                                                        anyKeybindPopupOpen = true
                                                        break
                                                    end
                                                end
                                                if anyKeybindPopupOpen then break end
                                            end
                                        end
                                    end
                                    if anyKeybindPopupOpen then break end
                                end
                            end
                            if hovered and self.Parent.Input.MouseRightClicked and not anyPopupOpen and not anyDropdownOpen and not anyKeybindPopupOpen and not self.Parent.SearchBarClickConsumed and not anyColorPickerOpen then
                                self.Parent.SearchBarClickConsumed = true
                                if not elem.KeybindPopupOpen then
                                    elem.KeybindPopupOpen = true
                                    elem.WaitingForKey = true
                                end
                            end
                            if hovered and self.Parent.Input.MouseClicked and elem.Callback and not anyPopupOpen and not anyDropdownOpen and not anyKeybindPopupOpen and not self.Parent.SearchBarClickConsumed and not anyColorPickerOpen then
                                self.Parent.SearchBarClickConsumed = true
                                elem.Callback()
                            end
                            cy = cy + 33 * self.Parent.menuDpi

                        elseif elem.Type == "Toggle" then
                            local anyDropdownOpen = #allOpenDropdowns > 0
                            
                            local tW = 36 * self.Parent.menuDpi
                            local tH = 18 * self.Parent.menuDpi
                            local tX = x + colW - 15 * self.Parent.menuDpi - tW
                            
                            local hasSettings = elem.RightClickCallback ~= nil
                            local hasColorPicker = elem.ColorPickerCallback ~= nil
                            local textStartX = x + 15 * self.Parent.menuDpi
                            local iconOffset = 0
                            
                            if hasSettings then
                                local gearSize = 18 * self.Parent.menuDpi
                                local gearX = x + 15 * self.Parent.menuDpi
                                local gearY = cy
                                local gearHoverArea = {x = gearX - 2 * self.Parent.menuDpi, y = gearY - 2 * self.Parent.menuDpi, w = gearSize + 4 * self.Parent.menuDpi, h = gearSize + 4 * self.Parent.menuDpi}
                                local gearHovered = self.Parent:IsHovering(gearHoverArea.x, gearHoverArea.y, gearHoverArea.w, gearHoverArea.h)
                                
                                if gearHovered then
                                    Ham.drawRectFilled({x = gearHoverArea.x, y = gearHoverArea.y, w = gearHoverArea.w, h = gearHoverArea.h}, self.Parent.Colors.Hover, 5 * self.Parent.menuDpi, 15)
                                end
                                
                                if self.Parent.gearIconTexture then
                                    local gearColor = gearHovered and self.Parent.Colors.Accent or self.Parent.Colors.TextDim
                                    Ham.drawTexture(self.Parent.gearIconTexture, {x = gearX, y = gearY + 2 * self.Parent.menuDpi}, {x = gearSize, y = gearSize}, 0, gearColor)
                                end
                                
                                textStartX = gearX + gearSize + 8 * self.Parent.menuDpi
                                iconOffset = gearSize + 8 * self.Parent.menuDpi
                            end
                            
                            if hasColorPicker then
                                local paletteSize = 18 * self.Parent.menuDpi
                                local paletteX = x + 15 * self.Parent.menuDpi + iconOffset
                                local paletteY = cy
                                local paletteHoverArea = {x = paletteX - 2 * self.Parent.menuDpi, y = paletteY - 2 * self.Parent.menuDpi, w = paletteSize + 4 * self.Parent.menuDpi, h = paletteSize + 4 * self.Parent.menuDpi}
                                local paletteHovered = self.Parent:IsHovering(paletteHoverArea.x, paletteHoverArea.y, paletteHoverArea.w, paletteHoverArea.h)
                                
                                if paletteHovered then
                                    Ham.drawRectFilled({x = paletteHoverArea.x, y = paletteHoverArea.y, w = paletteHoverArea.w, h = paletteHoverArea.h}, self.Parent.Colors.Hover, 5 * self.Parent.menuDpi, 15)
                                end
                                
                                if self.Parent.paletteIconTexture then
                                    local paletteColor = paletteHovered and self.Parent.Colors.Accent or self.Parent.Colors.TextDim
                                    Ham.drawTexture(self.Parent.paletteIconTexture, {x = paletteX, y = paletteY + 2 * self.Parent.menuDpi}, {x = paletteSize, y = paletteSize}, 0, paletteColor)
                                end
                                
                                if not hasSettings then
                                    textStartX = paletteX + paletteSize + 8 * self.Parent.menuDpi
                                else
                                    textStartX = textStartX + paletteSize + 8 * self.Parent.menuDpi
                                end
                                
                                if self.Parent:IsHovering(paletteHoverArea.x, paletteHoverArea.y, paletteHoverArea.w, paletteHoverArea.h) and (self.Parent.Input.MouseClicked or self.Parent.Input.MouseRightClicked) and not self.Parent.SearchBarClickConsumed then
                                    for _, popupInfo in ipairs(openPopups) do
                                        if popupInfo and popupInfo.elem and popupInfo.elem ~= elem then
                                            popupInfo.elem.PopupOpen = false
                                        end
                                    end
                                    elem.PopupOpen = not elem.PopupOpen
                                    if elem.ColorPickerCallback then elem.ColorPickerCallback(elem) end
                                end
                                
                                if elem.PopupOpen and elem.PopupData then
                                    table.insert(openPopups, {elem = elem, gearX = paletteX, gearY = paletteY})
                                end
                            end
                            
                            if hasSettings and not hasColorPicker then
                                local gearHoverArea = {x = x + 15 * self.Parent.menuDpi - 2 * self.Parent.menuDpi, y = cy - 2 * self.Parent.menuDpi, w = 18 * self.Parent.menuDpi + 4 * self.Parent.menuDpi, h = 18 * self.Parent.menuDpi + 4 * self.Parent.menuDpi}
                                local isHoveringGear = self.Parent:IsHovering(gearHoverArea.x, gearHoverArea.y, gearHoverArea.w, gearHoverArea.h)
                                
                                if isHoveringGear and self.Parent.Input.MouseRightClicked and not rightClickHandled and not anyColorPickerOpen then
                                    rightClickHandled = true
                                    for _, popupInfo in ipairs(openPopups) do
                                        if popupInfo and popupInfo.elem and popupInfo.elem ~= elem then
                                            popupInfo.elem.PopupOpen = false
                                        end
                                    end
                                    if elem.RightClickCallback then 
                                        elem.RightClickCallback(elem) 
                                    end
                                    if not elem.PopupData then
                                        elem.PopupData = {}
                                    end
                                    elem.PopupOpen = true
                                end
                                
                                if elem.PopupOpen and elem.PopupData and not hasColorPicker then
                                    table.insert(openPopups, {elem = elem, gearX = x + 15 * self.Parent.menuDpi, gearY = cy})
                                end
                            end
                            
                            Ham.drawText(elem.Text, {x = textStartX, y = cy + 2 * self.Parent.menuDpi}, self.Parent.Colors.TextDim, 13 * self.Parent.menuDpi, false, false, {0,0,0,255})
                            
                            if not elem.AnimValue then
                                elem.AnimValue = elem.Value and 1.0 or 0.0
                            end
                            local targetAnim = elem.Value and 1.0 or 0.0
                            if elem.AnimValue ~= targetAnim then
                                local diff = targetAnim - elem.AnimValue
                                if math.abs(diff) > 0.01 then
                                    elem.AnimValue = elem.AnimValue + diff * 0.3
                                else
                                    elem.AnimValue = targetAnim
                                end
                            end
                            
                            local bgR = math.floor(50 + (self.Parent.Colors.Accent[1] - 50) * elem.AnimValue)
                            local bgG = math.floor(52 + (self.Parent.Colors.Accent[2] - 52) * elem.AnimValue)
                            local bgB = math.floor(60 + (self.Parent.Colors.Accent[3] - 60) * elem.AnimValue)
                            local bgA = math.floor(200 + (255 - 200) * elem.AnimValue)
                            Ham.drawRectFilled({x = tX, y = cy, w = tW, h = tH}, {bgR, bgG, bgB, bgA}, 9 * self.Parent.menuDpi, 15)
                            
                            local kX = tX + 4 * self.Parent.menuDpi + (tW - 18 * self.Parent.menuDpi) * elem.AnimValue
                            Ham.drawRectFilled({x = kX, y = cy + 4 * self.Parent.menuDpi, w = 10 * self.Parent.menuDpi, h = 10 * self.Parent.menuDpi}, self.Parent.Colors.Text, 5 * self.Parent.menuDpi, 15)
                            
                            local anyKeybindPopupOpen = false
                            if self.Parent.Windows then
                                for _, win in ipairs(self.Parent.Windows) do
                                    if win.ActiveTab and win.ActiveTab.ActiveSubTab then
                                        for _, s in ipairs(win.ActiveTab.ActiveSubTab.Sections.Left) do
                                            for _, e in ipairs(s.Elements) do
                                                if (e.Type == "Button" or e.Type == "Toggle" or e.Type == "Slider") and e.KeybindPopupOpen then
                                                    anyKeybindPopupOpen = true
                                                    break
                                                end
                                            end
                                            if anyKeybindPopupOpen then break end
                                        end
                                        if not anyKeybindPopupOpen then
                                            for _, s in ipairs(win.ActiveTab.ActiveSubTab.Sections.Middle) do
                                                for _, e in ipairs(s.Elements) do
                                                    if (e.Type == "Button" or e.Type == "Toggle" or e.Type == "Slider") and e.KeybindPopupOpen then
                                                        anyKeybindPopupOpen = true
                                                        break
                                                    end
                                                end
                                                if anyKeybindPopupOpen then break end
                                            end
                                        end
                                        if not anyKeybindPopupOpen then
                                            for _, s in ipairs(win.ActiveTab.ActiveSubTab.Sections.Right) do
                                                for _, e in ipairs(s.Elements) do
                                                    if (e.Type == "Button" or e.Type == "Toggle" or e.Type == "Slider") and e.KeybindPopupOpen then
                                                        anyKeybindPopupOpen = true
                                                        break
                                                    end
                                                end
                                                if anyKeybindPopupOpen then break end
                                            end
                                        end
                                    end
                                    if anyKeybindPopupOpen then break end
                                end
                            end
                            local toggleClickArea = hasSettings and {x = textStartX, y = cy, w = tX - textStartX - 5 * self.Parent.menuDpi, h = tH} or {x = x + 15 * self.Parent.menuDpi, y = cy, w = colW - 30 * self.Parent.menuDpi, h = tH}
                            local toggleSwitchArea = {x = tX, y = cy, w = tW, h = tH}
                            if (self.Parent:IsHovering(toggleClickArea.x, toggleClickArea.y, toggleClickArea.w, toggleClickArea.h) or self.Parent:IsHovering(toggleSwitchArea.x, toggleSwitchArea.y, toggleSwitchArea.w, toggleSwitchArea.h)) and self.Parent.Input.MouseRightClicked and not anyPopupOpen and not anyDropdownOpen and not anyKeybindPopupOpen and not elem.PopupOpen and not self.Parent.SearchBarClickConsumed and not anyColorPickerOpen then
                                self.Parent.SearchBarClickConsumed = true
                                if not elem.KeybindPopupOpen then
                                    elem.KeybindPopupOpen = true
                                    elem.WaitingForKey = true
                                end
                            end
                            if (self.Parent:IsHovering(toggleClickArea.x, toggleClickArea.y, toggleClickArea.w, toggleClickArea.h) or self.Parent:IsHovering(toggleSwitchArea.x, toggleSwitchArea.y, toggleSwitchArea.w, toggleSwitchArea.h)) and self.Parent.Input.MouseClicked and not anyPopupOpen and not anyDropdownOpen and not anyKeybindPopupOpen and not elem.PopupOpen and not self.Parent.SearchBarClickConsumed and not anyColorPickerOpen then
                                self.Parent.SearchBarClickConsumed = true
                                elem.Value = not elem.Value
                                if elem.Callback then elem.Callback(elem.Value) end
                            end
                            
                            cy = cy + 28 * self.Parent.menuDpi

                        elseif elem.Type == "Slider" then
                            local anyDropdownOpen = #allOpenDropdowns > 0
                            
                            local textX = x + 15 * self.Parent.menuDpi
                            local fontSize = 13 * self.Parent.menuDpi
                            
                            local sW = 120 * self.Parent.menuDpi
                            local sH = 5 * self.Parent.menuDpi
                            local sX = x + colW - 15 * self.Parent.menuDpi - sW
                            local sY = cy + 10 * self.Parent.menuDpi
                            
                            local valueText = tostring(math.floor(elem.Value + 0.5))
                            if elem.Suffix and elem.Suffix ~= "" then
                                valueText = valueText .. " " .. elem.Suffix
                            end
                            local valueWidth, _ = Ham.getTextWidth(valueText)
                            local textWidth, _ = Ham.getTextWidth(elem.Text)
                            
                            local valueGap = 6 * self.Parent.menuDpi
                            local valueX = sX - valueWidth - valueGap
                            
                            local textMaxWidth = valueX - textX - 4 * self.Parent.menuDpi
                            local displayText = elem.Text
                            if textWidth > textMaxWidth and textMaxWidth > 20 * self.Parent.menuDpi then
                                local ellipsisWidth = 15 * self.Parent.menuDpi
                                local availableWidth = textMaxWidth - ellipsisWidth
                                local charWidth = textWidth / #elem.Text
                                local maxChars = math.floor(availableWidth / charWidth)
                                if maxChars > 0 then
                                    displayText = string.sub(elem.Text, 1, maxChars) .. "..."
                                else
                                    displayText = "..."
                                end
                            end
                            
                            local textY = sY + (sH / 2) - (fontSize / 2) - 1.5 * self.Parent.menuDpi
                            local valueY = sY + (sH / 2) - (fontSize / 2) - 0.1 * self.Parent.menuDpi
                            Ham.drawText(displayText, {x = textX, y = textY}, self.Parent.Colors.TextDim, fontSize, false, false, {0,0,0,255})
                            Ham.drawText(valueText, {x = valueX, y = valueY}, self.Parent.Colors.Accent, fontSize, false, false, {0,0,0,255})
                            
                            local barBgColor = {35, 37, 45, 255}
                            Ham.drawRectFilled({x = sX, y = sY, w = sW, h = sH}, barBgColor, 3 * self.Parent.menuDpi, 15)
                            
                            local range = elem.Max - elem.Min
                            local pct = (range > 0) and ((elem.Value - elem.Min) / range) or 0
                            if pct < 0 then pct = 0 elseif pct > 1 then pct = 1 end
                            
                            local fillW = sW * pct
                            if fillW > 0 then
                                Ham.drawRectFilled({x = sX, y = sY, w = fillW, h = sH}, self.Parent.Colors.Accent, 3 * self.Parent.menuDpi, 15)
                            end
                            
                            local handleSize = 10 * self.Parent.menuDpi
                            local handleX = sX + fillW - handleSize / 2
                            local handleY = sY - (handleSize - sH) / 2
                            Ham.drawRectFilled({x = handleX, y = handleY, w = handleSize, h = handleSize}, self.Parent.Colors.Text, 5 * self.Parent.menuDpi, 15)
                            Ham.drawRectFilled({x = handleX + 1 * self.Parent.menuDpi, y = handleY + 1 * self.Parent.menuDpi, w = handleSize - 2 * self.Parent.menuDpi, h = handleSize - 2 * self.Parent.menuDpi}, self.Parent.Colors.Accent, 4 * self.Parent.menuDpi, 15)
                            
                            local hoverArea = {x = sX - 5 * self.Parent.menuDpi, y = cy, w = sW + 10 * self.Parent.menuDpi, h = 22 * self.Parent.menuDpi}
                            local canDrag = not anyPopupOpen and not anyDropdownOpen and not anyColorPickerOpen
                            if self.Parent.Input.MouseClicked and self.Parent:IsHovering(hoverArea.x, hoverArea.y, hoverArea.w, hoverArea.h) and canDrag then
                                elem.Dragging = true
                            end
                            
                            local anyKeybindPopupOpen = false
                            if self.Parent.Windows then
                                for _, win in ipairs(self.Parent.Windows) do
                                    if win.ActiveTab and win.ActiveTab.ActiveSubTab then
                                        for _, s in ipairs(win.ActiveTab.ActiveSubTab.Sections.Left) do
                                            for _, e in ipairs(s.Elements) do
                                                if (e.Type == "Button" or e.Type == "Toggle" or e.Type == "Slider") and e.KeybindPopupOpen then
                                                    anyKeybindPopupOpen = true
                                                    break
                                                end
                                            end
                                            if anyKeybindPopupOpen then break end
                                        end
                                        if not anyKeybindPopupOpen then
                                            for _, s in ipairs(win.ActiveTab.ActiveSubTab.Sections.Middle) do
                                                for _, e in ipairs(s.Elements) do
                                                    if (e.Type == "Button" or e.Type == "Toggle" or e.Type == "Slider") and e.KeybindPopupOpen then
                                                        anyKeybindPopupOpen = true
                                                        break
                                                    end
                                                end
                                                if anyKeybindPopupOpen then break end
                                            end
                                        end
                                        if not anyKeybindPopupOpen then
                                            for _, s in ipairs(win.ActiveTab.ActiveSubTab.Sections.Right) do
                                                for _, e in ipairs(s.Elements) do
                                                    if (e.Type == "Button" or e.Type == "Toggle" or e.Type == "Slider") and e.KeybindPopupOpen then
                                                        anyKeybindPopupOpen = true
                                                        break
                                                    end
                                                end
                                                if anyKeybindPopupOpen then break end
                                            end
                                        end
                                    end
                                    if anyKeybindPopupOpen then break end
                                end
                            end
                            local sliderHoverArea = {x = sX - 5 * self.Parent.menuDpi, y = cy, w = sW + 10 * self.Parent.menuDpi, h = 22 * self.Parent.menuDpi}
                            if self.Parent:IsHovering(sliderHoverArea.x, sliderHoverArea.y, sliderHoverArea.w, sliderHoverArea.h) and self.Parent.Input.MouseRightClicked and not anyPopupOpen and not anyDropdownOpen and not anyKeybindPopupOpen and not self.Parent.SearchBarClickConsumed and not anyColorPickerOpen then
                                self.Parent.SearchBarClickConsumed = true
                                if not elem.KeybindPopupOpen then
                                    elem.KeybindPopupOpen = true
                                    elem.WaitingForKey = true
                                end
                            end
                            
                            if not self.Parent.Input.MouseDown then
                                if elem.Dragging and elem.Callback then
                                    elem.Callback(elem.Value)
                                end
                                elem.Dragging = false
                            end
                            
                            if elem.Dragging and canDrag then
                                local nx = self.Parent.Input.MX - sX
                                local np = (sW > 0) and (nx / sW) or 0
                                if np < 0 then np = 0 end
                                if np > 1 then np = 1 end
                                local range = elem.Max - elem.Min
                                elem.Value = math.floor((elem.Min + (np * range)) + 0.5)
                            end
                            cy = cy + 25 * self.Parent.menuDpi
                        elseif elem.Type == "Dropdown" then
                            local ddW = 140 * self.Parent.menuDpi
                            local ddH = 22 * self.Parent.menuDpi
                            local ddX = x + colW - 15 * self.Parent.menuDpi - ddW
                            local ddY = cy
                            
                            Ham.drawText(elem.Text, {x = x + 15 * self.Parent.menuDpi, y = cy + 2 * self.Parent.menuDpi}, self.Parent.Colors.TextDim, 13 * self.Parent.menuDpi, false, false, {0,0,0,255})
                            
                            local ddHovered = self.Parent:IsHovering(ddX, ddY, ddW, ddH)
                            Ham.drawRectFilled({x = ddX, y = ddY, w = ddW, h = ddH}, ddHovered and self.Parent.Colors.Hover or {38, 40, 48, 200}, 5 * self.Parent.menuDpi, 15)
                            Ham.drawRect({x = ddX, y = ddY}, {x = ddX + ddW, y = ddY + ddH}, self.Parent.Colors.Border, 5 * self.Parent.menuDpi, 0, 1)
                            
                            local selectedText = ""
                            if elem.Options and elem.Selected and elem.Options[elem.Selected] then
                                selectedText = elem.Options[elem.Selected]
                            end
                            Ham.drawText(selectedText, {x = ddX + 8 * self.Parent.menuDpi, y = ddY + 4 * self.Parent.menuDpi}, self.Parent.Colors.Text, 11 * self.Parent.menuDpi, false, false, {0,0,0,255})
                            
                            if not elem.AnimValue then
                                elem.AnimValue = elem.Open and 1.0 or 0.0
                            end
                            local targetAnim = elem.Open and 1.0 or 0.0
                            if elem.AnimValue ~= targetAnim then
                                local diff = targetAnim - elem.AnimValue
                                if math.abs(diff) > 0.01 then
                                    elem.AnimValue = elem.AnimValue + diff * 0.3
                                else
                                    elem.AnimValue = targetAnim
                                end
                            end
                            
                            local arrowChar = elem.AnimValue > 0.5 and "▼" or "►"
                            Ham.drawText(arrowChar, {x = ddX + ddW - 15 * self.Parent.menuDpi, y = ddY + 6 * self.Parent.menuDpi}, self.Parent.Colors.TextDim, 10 * self.Parent.menuDpi, true, false, {0,0,0,255})
                            
                            local anyOtherDropdownOpen = false
                            for _, dd in ipairs(allOpenDropdowns) do
                                if not (dd.type == "SectionDropdown" and dd.elem == elem) then
                                    anyOtherDropdownOpen = true
                                    break
                                end
                            end
                            
                            if ddHovered and self.Parent.Input.MouseClicked and not anyPopupOpen and not anyOtherDropdownOpen and not self.Parent.SearchBarClickConsumed and not anyColorPickerOpen then
                                self.Parent.SearchBarClickConsumed = true
                                for _, sec in ipairs(self.ActiveTab.ActiveSubTab.Sections.Left) do
                                    for _, e in ipairs(sec.Elements) do
                                        if (e.Type == "Dropdown" or e.Type == "MultiDropdown") and e ~= elem then
                                            e.Open = false
                                        end
                                    end
                                end
                                for _, sec in ipairs(self.ActiveTab.ActiveSubTab.Sections.Middle) do
                                    for _, e in ipairs(sec.Elements) do
                                        if (e.Type == "Dropdown" or e.Type == "MultiDropdown") and e ~= elem then
                                            e.Open = false
                                        end
                                    end
                                end
                                for _, sec in ipairs(self.ActiveTab.ActiveSubTab.Sections.Right) do
                                    for _, e in ipairs(sec.Elements) do
                                        if (e.Type == "Dropdown" or e.Type == "MultiDropdown") and e ~= elem then
                                            e.Open = false
                                        end
                                    end
                                end
                                elem.Open = not elem.Open
                            end
                            
                            if elem.AnimValue > 0.01 and elem.Options and #elem.Options > 0 then
                                local optionY = ddY + ddH + 2 * self.Parent.menuDpi
                                local maxOptions = 8
                                local optionHeight = 20 * self.Parent.menuDpi
                                local visibleOptions = math.min(#elem.Options, maxOptions)
                                local fullDropdownAreaH = visibleOptions * optionHeight
                                local dropdownAreaH = fullDropdownAreaH * elem.AnimValue
                                
                                local dropdownArea = {x = ddX, y = optionY - 2 * self.Parent.menuDpi, w = ddW, h = dropdownAreaH + 4 * self.Parent.menuDpi}
                                local isHoveringDropdown = self.Parent:IsHovering(dropdownArea.x, dropdownArea.y, dropdownArea.w, dropdownArea.h) or self.Parent:IsHovering(ddX, ddY, ddW, ddH)
                                
                                table.insert(allOpenDropdowns, {
                                    type = "SectionDropdown",
                                    elem = elem,
                                    area = dropdownArea,
                                    buttonArea = {x = ddX, y = ddY, w = ddW, h = ddH},
                                    optionY = optionY,
                                    optionHeight = optionHeight,
                                    maxOptions = maxOptions,
                                    visibleOptions = visibleOptions,
                                    animValue = elem.AnimValue
                                })
                            end
                            
                            cy = cy + 28 * self.Parent.menuDpi
                        elseif elem.Type == "MultiDropdown" then
                            local ddW = 140 * self.Parent.menuDpi
                            local ddH = 22 * self.Parent.menuDpi
                            local ddX = x + colW - 15 * self.Parent.menuDpi - ddW
                            local ddY = cy
                            
                            Ham.drawText(elem.Text, {x = x + 15 * self.Parent.menuDpi, y = cy + 2 * self.Parent.menuDpi}, self.Parent.Colors.TextDim, 13 * self.Parent.menuDpi, false, false, {0,0,0,255})
                            
                            local ddHovered = self.Parent:IsHovering(ddX, ddY, ddW, ddH)
                            Ham.drawRectFilled({x = ddX, y = ddY, w = ddW, h = ddH}, ddHovered and self.Parent.Colors.Hover or {38, 40, 48, 200}, 5 * self.Parent.menuDpi, 15)
                            Ham.drawRect({x = ddX, y = ddY}, {x = ddX + ddW, y = ddY + ddH}, self.Parent.Colors.Border, 5 * self.Parent.menuDpi, 0, 1)
                            
                            if not elem.Selected then
                                elem.Selected = {}
                            end
                            local selectedCount = #elem.Selected
                            local selectedText = "None"
                            if selectedCount > 0 then
                                local selectedItems = {}
                                for _, idx in ipairs(elem.Selected) do
                                    if elem.Options[idx] then
                                        table.insert(selectedItems, elem.Options[idx])
                                    end
                                end
                                if #selectedItems > 0 then
                                    local maxWidth = ddW - 30 * self.Parent.menuDpi
                                    local testText = table.concat(selectedItems, ", ")
                                    local testWidth, _ = Ham.getTextWidth(testText)
                                    if testWidth <= maxWidth then
                                        selectedText = testText
                                    else
                                        local currentText = ""
                                        for i, item in ipairs(selectedItems) do
                                            local tryText = i == 1 and item or currentText .. ", " .. item
                                            local tryWidth, _ = Ham.getTextWidth(tryText)
                                            if tryWidth <= maxWidth - 20 * self.Parent.menuDpi then
                                                currentText = tryText
                                            else
                                                if i > 1 then
                                                    selectedText = currentText .. "..."
                                                else
                                                    local itemWidth, _ = Ham.getTextWidth(item)
                                                    if itemWidth > maxWidth - 20 * self.Parent.menuDpi then
                                                        local charWidth = itemWidth / #item
                                                        local maxChars = math.floor((maxWidth - 20 * self.Parent.menuDpi) / charWidth)
                                                        if maxChars > 0 then
                                                            selectedText = string.sub(item, 1, maxChars) .. "..."
                                                        else
                                                            selectedText = "..."
                                                        end
                                                    else
                                                        selectedText = item .. "..."
                                                    end
                                                end
                                                break
                                            end
                                        end
                                        if selectedText == "None" and currentText ~= "" then
                                            selectedText = currentText .. "..."
                                        end
                                    end
                                end
                            end
                            Ham.drawText(selectedText, {x = ddX + 8 * self.Parent.menuDpi, y = ddY + 4 * self.Parent.menuDpi}, self.Parent.Colors.Text, 11 * self.Parent.menuDpi, false, false, {0,0,0,255})
                            
                            if not elem.AnimValue then
                                elem.AnimValue = elem.Open and 1.0 or 0.0
                            end
                            local targetAnim = elem.Open and 1.0 or 0.0
                            if elem.AnimValue ~= targetAnim then
                                local diff = targetAnim - elem.AnimValue
                                if math.abs(diff) > 0.01 then
                                    elem.AnimValue = elem.AnimValue + diff * 0.3
                                else
                                    elem.AnimValue = targetAnim
                                end
                            end
                            
                            local arrowChar = elem.AnimValue > 0.5 and "▼" or "►"
                            Ham.drawText(arrowChar, {x = ddX + ddW - 15 * self.Parent.menuDpi, y = ddY + 6 * self.Parent.menuDpi}, self.Parent.Colors.TextDim, 10 * self.Parent.menuDpi, true, false, {0,0,0,255})
                            
                            local anyOtherDropdownOpen = false
                            for _, dd in ipairs(allOpenDropdowns) do
                                if not (dd.type == "SectionMultiDropdown" and dd.elem == elem) then
                                    anyOtherDropdownOpen = true
                                    break
                                end
                            end
                            
                            if ddHovered and self.Parent.Input.MouseClicked and not anyPopupOpen and not anyOtherDropdownOpen and not self.Parent.SearchBarClickConsumed and not anyColorPickerOpen then
                                self.Parent.SearchBarClickConsumed = true
                                for _, sec in ipairs(self.ActiveTab.ActiveSubTab.Sections.Left) do
                                    for _, e in ipairs(sec.Elements) do
                                        if (e.Type == "Dropdown" or e.Type == "MultiDropdown") and e ~= elem then
                                            e.Open = false
                                        end
                                    end
                                end
                                for _, sec in ipairs(self.ActiveTab.ActiveSubTab.Sections.Middle) do
                                    for _, e in ipairs(sec.Elements) do
                                        if (e.Type == "Dropdown" or e.Type == "MultiDropdown") and e ~= elem then
                                            e.Open = false
                                        end
                                    end
                                end
                                for _, sec in ipairs(self.ActiveTab.ActiveSubTab.Sections.Right) do
                                    for _, e in ipairs(sec.Elements) do
                                        if (e.Type == "Dropdown" or e.Type == "MultiDropdown") and e ~= elem then
                                            e.Open = false
                                        end
                                    end
                                end
                                elem.Open = not elem.Open
                            end
                            
                            if elem.AnimValue > 0.01 and elem.Options and #elem.Options > 0 then
                                if not elem.ScrollOffset then
                                    elem.ScrollOffset = 0
                                end
                                
                                local optionY = ddY + ddH + 2 * self.Parent.menuDpi
                                local maxOptions = 8
                                local optionHeight = 20 * self.Parent.menuDpi
                                local visibleOptions = math.min(#elem.Options, maxOptions)
                                local fullDropdownAreaH = visibleOptions * optionHeight
                                local dropdownAreaH = fullDropdownAreaH * elem.AnimValue
                                
                                local dropdownArea = {x = ddX, y = optionY - 2 * self.Parent.menuDpi, w = ddW, h = dropdownAreaH + 4 * self.Parent.menuDpi}
                                local isHoveringDropdown = self.Parent:IsHovering(dropdownArea.x, dropdownArea.y, dropdownArea.w, dropdownArea.h) or self.Parent:IsHovering(ddX, ddY, ddW, ddH)
                                
                                table.insert(allOpenDropdowns, {
                                    type = "SectionMultiDropdown",
                                    elem = elem,
                                    area = dropdownArea,
                                    buttonArea = {x = ddX, y = ddY, w = ddW, h = ddH},
                                    optionY = optionY,
                                    optionHeight = optionHeight,
                                    maxOptions = maxOptions,
                                    visibleOptions = visibleOptions,
                                    animValue = elem.AnimValue,
                                    scrollOffset = elem.ScrollOffset
                                })
                            end
                            
                            cy = cy + 28 * self.Parent.menuDpi
                        elseif elem.Type == "ColorPicker" then
                            local textX = x + 15 * self.Parent.menuDpi
                            local textY = cy + 2 * self.Parent.menuDpi
                            local textWidth, _ = Ham.getTextWidth(elem.Text)
                            
                            local colorPreviewW = 60 * self.Parent.menuDpi
                            local colorPreviewH = 14 * self.Parent.menuDpi
                            local colorPreviewX = x + colW - 15 * self.Parent.menuDpi - colorPreviewW
                            local colorPreviewY = cy + 2 * self.Parent.menuDpi
                            
                            Ham.drawText(elem.Text, {x = textX, y = textY}, self.Parent.Colors.TextDim, 13 * self.Parent.menuDpi, false, false, {0,0,0,255})
                            
                            local colorPreviewArea = {x = colorPreviewX - 2 * self.Parent.menuDpi, y = colorPreviewY - 2 * self.Parent.menuDpi, w = colorPreviewW + 4 * self.Parent.menuDpi, h = colorPreviewH + 4 * self.Parent.menuDpi}
                            
                            local paletteHovered = self.Parent:IsHovering(colorPreviewArea.x, colorPreviewArea.y, colorPreviewArea.w, colorPreviewArea.h)
                            
                            if paletteHovered then
                                Ham.drawRectFilled({x = colorPreviewArea.x, y = colorPreviewArea.y, w = colorPreviewArea.w, h = colorPreviewArea.h}, self.Parent.Colors.Hover, 5 * self.Parent.menuDpi, 15)
                            end
                            
                            Ham.drawRectFilled({x = colorPreviewX, y = colorPreviewY, w = colorPreviewW, h = colorPreviewH}, elem.ColorRef or {255, 255, 255, 255}, 3 * self.Parent.menuDpi, 15)
                            Ham.drawRect({x = colorPreviewX, y = colorPreviewY}, {x = colorPreviewX + colorPreviewW, y = colorPreviewY + colorPreviewH}, self.Parent.Colors.Border, 3 * self.Parent.menuDpi, 0, 1)
                            
                            local colorPickerClickArea = self.Parent:IsHovering(colorPreviewArea.x, colorPreviewArea.y, colorPreviewArea.w, colorPreviewArea.h)
                            
                            local anyDropdownOpen = #allOpenDropdowns > 0
                            local anyOtherPopupOpen = false
                            for _, popupInfo in ipairs(openPopups) do
                                if popupInfo and popupInfo.elem and popupInfo.elem ~= elem and popupInfo.elem.PopupOpen then
                                    anyOtherPopupOpen = true
                                    break
                                end
                            end
                            if colorPickerClickArea and self.Parent.Input.MouseClicked and not anyOtherPopupOpen and not anyDropdownOpen and not self.Parent.SearchBarClickConsumed then
                                self.Parent.SearchBarClickConsumed = true
                                for _, popupInfo in ipairs(openPopups) do
                                    if popupInfo and popupInfo.elem and popupInfo.elem ~= elem then
                                        popupInfo.elem.PopupOpen = false
                                    end
                                end
                                elem.PopupOpen = not elem.PopupOpen
                                if not elem.PopupData.ColorPicker then
                                    elem.PopupData.ColorPicker = {
                                        ColorRef = elem.ColorRef,
                                        Callback = function(color)
                                            elem.ColorRef = color
                                            if elem.Callback then elem.Callback(color) end
                                        end
                                    }
                                end
                            end
                            
                            if elem.PopupOpen and elem.PopupData then
                                table.insert(openPopups, {elem = elem, gearX = colorPreviewX, gearY = colorPreviewY})
                            end
                            
                            cy = cy + 28 * self.Parent.menuDpi
                        elseif elem.Type == "Selector" then
                            local anyDropdownOpen = #allOpenDropdowns > 0
                            
                            local textX = x + 15 * self.Parent.menuDpi
                            local textY = cy + 2 * self.Parent.menuDpi
                            
                            Ham.drawText(elem.Text, {x = textX, y = textY}, self.Parent.Colors.TextDim, 13 * self.Parent.menuDpi, false, false, {0,0,0,255})
                            
                            local selectorW = 120 * self.Parent.menuDpi
                            local selectorH = 20 * self.Parent.menuDpi
                            local selectorX = x + colW - 15 * self.Parent.menuDpi - selectorW
                            local selectorY = cy
                            
                            local currentValue = ""
                            if elem.Options and elem.Selected and elem.Options[elem.Selected] then
                                currentValue = elem.Options[elem.Selected]
                            end
                            
                            local arrowW = 20 * self.Parent.menuDpi
                            local leftArrowX = selectorX
                            local rightArrowX = selectorX + selectorW - arrowW
                            local valueX = selectorX + arrowW
                            local valueW = selectorW - arrowW * 2
                            
                            local leftArrowHovered = self.Parent:IsHovering(leftArrowX, selectorY, arrowW, selectorH)
                            local rightArrowHovered = self.Parent:IsHovering(rightArrowX, selectorY, arrowW, selectorH)
                            
                            if leftArrowHovered then
                                Ham.drawRectFilled({x = leftArrowX, y = selectorY, w = arrowW, h = selectorH}, self.Parent.Colors.Hover, 5 * self.Parent.menuDpi, 15)
                            end
                            if rightArrowHovered then
                                Ham.drawRectFilled({x = rightArrowX, y = selectorY, w = arrowW, h = selectorH}, self.Parent.Colors.Hover, 5 * self.Parent.menuDpi, 15)
                            end
                            
                            Ham.drawText("<", {x = leftArrowX + arrowW / 2 + 1 * self.Parent.menuDpi, y = selectorY + selectorH / 2 - 9 * self.Parent.menuDpi}, self.Parent.Colors.Text, 14 * self.Parent.menuDpi, true, false, {0,0,0,255})
                            Ham.drawText(">", {x = rightArrowX + arrowW / 2, y = selectorY + selectorH / 2 - 9 * self.Parent.menuDpi}, self.Parent.Colors.Text, 14 * self.Parent.menuDpi, true, false, {0,0,0,255})
                            
                            Ham.drawRectFilled({x = valueX, y = selectorY, w = valueW, h = selectorH}, {38, 40, 48, 200}, 5 * self.Parent.menuDpi, 15)
                            Ham.drawRect({x = selectorX, y = selectorY}, {x = selectorX + selectorW, y = selectorY + selectorH}, self.Parent.Colors.Border, 5 * self.Parent.menuDpi, 0, 1)
                            
                            Ham.drawText(currentValue, {x = valueX + valueW / 2, y = selectorY + 4 * self.Parent.menuDpi}, self.Parent.Colors.Text, 11 * self.Parent.menuDpi, true, false, {0,0,0,255})
                            
                            if leftArrowHovered and self.Parent.Input.MouseClicked and not anyPopupOpen and not anyDropdownOpen and not self.Parent.SearchBarClickConsumed and not anyColorPickerOpen then
                                self.Parent.SearchBarClickConsumed = true
                                if elem.Options and #elem.Options > 0 then
                                    elem.Selected = elem.Selected - 1
                                    if elem.Selected < 1 then
                                        elem.Selected = #elem.Options
                                    end
                                    if elem.Callback then
                                        elem.Callback(elem.Selected, elem.Options[elem.Selected])
                                    end
                                end
                            end
                            
                            if rightArrowHovered and self.Parent.Input.MouseClicked and not anyPopupOpen and not anyDropdownOpen and not self.Parent.SearchBarClickConsumed and not anyColorPickerOpen then
                                self.Parent.SearchBarClickConsumed = true
                                if elem.Options and #elem.Options > 0 then
                                    elem.Selected = elem.Selected + 1
                                    if elem.Selected > #elem.Options then
                                        elem.Selected = 1
                                    end
                                    if elem.Callback then
                                        elem.Callback(elem.Selected, elem.Options[elem.Selected])
                                    end
                                end
                            end
                            
                            cy = cy + 28 * self.Parent.menuDpi
                        elseif elem.Type == "Label" then
                            local labelText = elem.Text or ""
                            local labelFontSize = 13 * self.Parent.menuDpi
                            local labelTextX = x + 15 * self.Parent.menuDpi
                            local labelTextY = cy + 4 * self.Parent.menuDpi
                            local maxLabelWidth = colW - 30 * self.Parent.menuDpi
                            
                            if self.Parent.customFont then
                                Ham.setFont(self.Parent.customFont)
                            end
                            local textWidth, textHeight = Ham.getTextWidth(labelText)
                            
                            if textWidth > maxLabelWidth then
                                local lines = {}
                                local words = {}
                                for word in labelText:gmatch("%S+") do
                                    table.insert(words, word)
                                end
                                local currentLine = ""
                                for _, word in ipairs(words) do
                                    local testLine = currentLine == "" and word or currentLine .. " " .. word
                                    local testWidth, _ = Ham.getTextWidth(testLine)
                                    if testWidth > maxLabelWidth and currentLine ~= "" then
                                        table.insert(lines, currentLine)
                                        currentLine = word
                                    else
                                        currentLine = testLine
                                    end
                                end
                                if currentLine ~= "" then
                                    table.insert(lines, currentLine)
                                end
                                
                                local lineY = labelTextY
                                for _, line in ipairs(lines) do
                                    Ham.drawText(line, {x = labelTextX, y = lineY}, self.Parent.Colors.TextDim, labelFontSize, false, false, {0,0,0,255})
                                    lineY = lineY + textHeight + 2 * self.Parent.menuDpi
                                end
                                cy = cy + (#lines * (textHeight + 2 * self.Parent.menuDpi)) + 8 * self.Parent.menuDpi
                            else
                                Ham.drawText(labelText, {x = labelTextX, y = labelTextY}, self.Parent.Colors.TextDim, labelFontSize, false, false, {0,0,0,255})
                                cy = cy + 22 * self.Parent.menuDpi
                            end
                            if self.Parent.customFont then
                                Ham.resetFont()
                            end
                        elseif elem.Type == "Divider" then
                            cy = cy + 5 * self.Parent.menuDpi
                            Ham.drawRectFilled({x = x + 15 * self.Parent.menuDpi, y = cy, w = colW - 30 * self.Parent.menuDpi, h = 1 * self.Parent.menuDpi}, self.Parent.Colors.Border, 0, 15)
                            cy = cy + 10 * self.Parent.menuDpi
                        end
                        
                        ::continue::
                    end
                end

                local sectionSpacing = 15 * self.Parent.menuDpi
                local leftX = self.X + 200 * self.Parent.menuDpi
                local middleX = 0
                local rightX = 0
                
                if middleCount > 0 then
                    middleX = leftX + colW + sectionSpacing
                    rightX = middleX + colW + sectionSpacing
                else
                    rightX = leftX + colW + sectionSpacing
                end
                
                for i, sec in ipairs(self.ActiveTab.ActiveSubTab.Sections.Left) do
                    RenderSection(sec, leftX, contentY)
                end
                for i, sec in ipairs(self.ActiveTab.ActiveSubTab.Sections.Middle) do
                    RenderSection(sec, middleX, contentY)
                end
                for i, sec in ipairs(self.ActiveTab.ActiveSubTab.Sections.Right) do
                    RenderSection(sec, rightX, contentY)
                end
                
                for _, popupInfo in ipairs(openPopups) do
                    local elem = popupInfo.elem
                    if elem.PopupOpen and elem.PopupData then
                        local gearX = popupInfo.gearX
                        local gearY = popupInfo.gearY
                        
                        if not elem.PopupData.PopupX then
                            elem.PopupData.PopupX = gearX + 25
                        end
                        if not elem.PopupData.PopupY then
                            elem.PopupData.PopupY = gearY - 10
                        end
                        if not elem.PopupData.PopupDragOffset then
                            elem.PopupData.PopupDragOffset = {X = 0, Y = 0}
                        end
                        if not elem.PopupData.PopupDragging then
                            elem.PopupData.PopupDragging = false
                        end
                        
                        local popupX = elem.PopupData.PopupX
                        local popupY = elem.PopupData.PopupY
                        local popupW = 220
                        if elem.PopupData.ColorPicker then
                            popupW = 280
                        end
                        
                        local basePadding = 30
                        local contentHeight = 0
                        
                        if elem.PopupData.KeybindDropdown then contentHeight = contentHeight + 30 end
                        if elem.PopupData.BoneDropdown then contentHeight = contentHeight + 30 end
                        if elem.PopupData.SpeedSlider then contentHeight = contentHeight + 30 end
                        if elem.PopupData.Dropdown then contentHeight = contentHeight + 30 end
                        if elem.PopupData.ColorPicker then contentHeight = contentHeight + 280 end
                        
                        local popupH = basePadding + contentHeight
                        if popupH < 60 then popupH = 60 end
                        
                        local popupArea = {x = popupX, y = popupY, w = popupW, h = popupH}
                        if elem.PopupData.Dropdown and elem.PopupData.Dropdown.Open and elem.PopupData.Dropdown.Options then
                            local maxOptions = 8
                            local visibleOptions = math.min(#elem.PopupData.Dropdown.Options, maxOptions)
                            popupArea.h = popupArea.h + visibleOptions * 20 + 25
                        end
                        if elem.PopupData.BoneDropdown and elem.PopupData.BoneDropdown.Open and elem.PopupData.BoneDropdown.Options then
                            local maxOptions = 8
                            local visibleOptions = math.min(#elem.PopupData.BoneDropdown.Options, maxOptions)
                            popupArea.h = popupArea.h + visibleOptions * 20 + 25
                        end
                        if elem.PopupData.KeybindDropdown and elem.PopupData.KeybindDropdown.Open and elem.PopupData.KeybindDropdown.Options then
                            local maxOptions = 8
                            local visibleOptions = math.min(#elem.PopupData.KeybindDropdown.Options, maxOptions)
                            popupArea.h = popupArea.h + visibleOptions * 20 + 25
                        end
                        
                        local isHoveringPopup = self.Parent:IsHovering(popupArea.x, popupArea.y, popupArea.w, popupArea.h)
                        local gearHoverArea = {x = gearX - 2, y = gearY - 2, w = 18 + 4, h = 18 + 4}
                        local isHoveringGear = self.Parent:IsHovering(gearHoverArea.x, gearHoverArea.y, gearHoverArea.w, gearHoverArea.h)
                        local isHoveringColorPreview = false
                        if elem.PopupData.ColorPicker then
                            local colorPreviewArea = {x = gearX - 2, y = gearY - 2, w = 64, h = 18}
                            isHoveringColorPreview = self.Parent:IsHovering(colorPreviewArea.x, colorPreviewArea.y, colorPreviewArea.w, colorPreviewArea.h)
                        end
                        
                        local popupTitleBarH = 20
                        local popupTitleBar = {x = popupX, y = popupY, w = popupW, h = popupTitleBarH}
                        local isHoveringPopupTitleBar = self.Parent:IsHovering(popupTitleBar.x, popupTitleBar.y, popupTitleBar.w, popupTitleBar.h)
                        
                        if self.Parent.Input.MouseDown and isHoveringPopupTitleBar and not elem.PopupData.PopupDragging then
                            elem.PopupData.PopupDragging = true
                            elem.PopupData.PopupDragOffset.X = self.Parent.Input.MX - popupX
                            elem.PopupData.PopupDragOffset.Y = self.Parent.Input.MY - popupY
                        end
                        
                        if not self.Parent.Input.MouseDown then
                            elem.PopupData.PopupDragging = false
                        end
                        
                        if elem.PopupData.PopupDragging and self.Parent.Input.MouseDown then
                            elem.PopupData.PopupX = self.Parent.Input.MX - elem.PopupData.PopupDragOffset.X
                            elem.PopupData.PopupY = self.Parent.Input.MY - elem.PopupData.PopupDragOffset.Y
                            popupX = elem.PopupData.PopupX
                            popupY = elem.PopupData.PopupY
                            popupArea.x = popupX
                            popupArea.y = popupY
                        end
                        
                        if self.Parent.Input.MouseClicked and not isHoveringPopup and not isHoveringGear and not isHoveringColorPreview and not self.Parent.SearchBarClickConsumed then
                            elem.PopupOpen = false
                            if elem.PopupData.Dropdown then
                                elem.PopupData.Dropdown.Open = false
                            end
                            if elem.PopupData.BoneDropdown then
                                elem.PopupData.BoneDropdown.Open = false
                            end
                            if elem.PopupData.KeybindDropdown then
                                elem.PopupData.KeybindDropdown.Open = false
                            end
                        end
                        
                        Ham.drawRectFilled({x = popupX, y = popupY, w = popupW, h = popupH}, self.Parent.Colors.Dropdown, 8, 15)
                        Ham.drawRectFilled({x = popupX + 5, y = popupY + 5, w = 3, h = popupH - 10}, self.Parent.Colors.Accent, 2, 15)
                        Ham.drawRect({x = popupX, y = popupY}, {x = popupX + popupW, y = popupY + popupH}, self.Parent.Colors.Border, 8, 0, 2)
                        
                        local popupCY = popupY + 15
                        
                        if elem.PopupData.KeybindDropdown then
                            Ham.drawText("Keybind", {x = popupX + 10, y = popupCY}, self.Parent.Colors.TextDim, 12, false, false, {0,0,0,255})
                                    
                                    local ddX = popupX + 60
                                    local ddY = popupCY - 2
                                    local ddW = 140
                                    local ddH = 22
                                    
                            local ddHovered = self.Parent:IsHovering(ddX, ddY, ddW, ddH)
                            Ham.drawRectFilled({x = ddX, y = ddY, w = ddW, h = ddH}, ddHovered and self.Parent.Colors.Hover or {38, 40, 48, 200}, 5, 15)
                            Ham.drawRect({x = ddX, y = ddY}, {x = ddX + ddW, y = ddY + ddH}, self.Parent.Colors.Border, 5, 0, 1)
                            
                            Ham.drawText(elem.PopupData.KeybindDropdown.Options[elem.PopupData.KeybindDropdown.Selected] or "", {x = ddX + 8, y = ddY + 4}, self.Parent.Colors.Text, 11, false, false, {0,0,0,255})
                            Ham.drawText("▼", {x = ddX + ddW - 15, y = ddY + 6}, self.Parent.Colors.TextDim, 10, true, false, {0,0,0,255})
                                    
                                    local anyOtherDropdownOpen = false
                                    for _, dd in ipairs(allOpenDropdowns) do
                                        if not (dd.type == "PopupKeybindDropdown" and dd.dropdown == elem.PopupData.KeybindDropdown) then
                                            anyOtherDropdownOpen = true
                                            break
                                        end
                                    end
                                    
                            if ddHovered and self.Parent.Input.MouseClicked and not anyOtherDropdownOpen and not self.Parent.SearchBarClickConsumed and not anyColorPickerOpen then
                                        if elem.PopupData.BoneDropdown then
                                            elem.PopupData.BoneDropdown.Open = false
                                        end
                                        if elem.PopupData.Dropdown then
                                            elem.PopupData.Dropdown.Open = false
                                        end
                                        elem.PopupData.KeybindDropdown.Open = not elem.PopupData.KeybindDropdown.Open
                                    end
                                    
                                    if elem.PopupData.KeybindDropdown.Open and elem.PopupData.KeybindDropdown.Options and #elem.PopupData.KeybindDropdown.Options > 0 then
                                        local optionY = ddY + ddH + 2
                                        local maxOptions = 8
                                        local optionHeight = 20
                                        local visibleOptions = math.min(#elem.PopupData.KeybindDropdown.Options, maxOptions)
                                        local dropdownAreaH = visibleOptions * optionHeight
                                        
                                        local dropdownArea = {x = ddX, y = optionY - 2, w = ddW, h = dropdownAreaH + 4}
                                        
                                        table.insert(allOpenDropdowns, {
                                            type = "PopupKeybindDropdown",
                                            dropdown = elem.PopupData.KeybindDropdown,
                                            area = dropdownArea,
                                            buttonArea = {x = ddX, y = ddY, w = ddW, h = ddH},
                                            optionY = optionY,
                                            optionHeight = optionHeight,
                                            maxOptions = maxOptions,
                                            visibleOptions = visibleOptions,
                                            ddX = ddX,
                                            ddW = ddW
                                        })
                                    end
                                    
                                    popupCY = popupCY + 30
                                end
                                
                        if elem.PopupData.BoneDropdown then
                            Ham.drawText("Bone", {x = popupX + 10, y = popupCY}, self.Parent.Colors.TextDim, 12, false, false, {0,0,0,255})
                                    
                                    local ddX = popupX + 60
                                    local ddY = popupCY - 2
                                    local ddW = 140
                                    local ddH = 22
                                    
                            local ddHovered = self.Parent:IsHovering(ddX, ddY, ddW, ddH)
                            Ham.drawRectFilled({x = ddX, y = ddY, w = ddW, h = ddH}, ddHovered and self.Parent.Colors.Hover or {38, 40, 48, 200}, 5, 15)
                            Ham.drawRect({x = ddX, y = ddY}, {x = ddX + ddW, y = ddY + ddH}, self.Parent.Colors.Border, 5, 0, 1)
                            
                            Ham.drawText(elem.PopupData.BoneDropdown.Options[elem.PopupData.BoneDropdown.Selected] or "", {x = ddX + 8, y = ddY + 4}, self.Parent.Colors.Text, 11, false, false, {0,0,0,255})
                            Ham.drawText("▼", {x = ddX + ddW - 15, y = ddY + 6}, self.Parent.Colors.TextDim, 10, true, false, {0,0,0,255})
                                    
                                    local anyOtherDropdownOpen = false
                                    for _, dd in ipairs(allOpenDropdowns) do
                                        if dd.type ~= "PopupBoneDropdown" or dd.dropdown ~= elem.PopupData.BoneDropdown then
                                            anyOtherDropdownOpen = true
                                            break
                                        end
                                    end
                                    
                            if ddHovered and self.Parent.Input.MouseClicked and not anyOtherDropdownOpen and not self.Parent.SearchBarClickConsumed and not anyColorPickerOpen then
                                        if elem.PopupData.KeybindDropdown then
                                            elem.PopupData.KeybindDropdown.Open = false
                                        end
                                        if elem.PopupData.Dropdown then
                                            elem.PopupData.Dropdown.Open = false
                                        end
                                        elem.PopupData.BoneDropdown.Open = not elem.PopupData.BoneDropdown.Open
                                    end
                                    
                                    if elem.PopupData.BoneDropdown.Open and elem.PopupData.BoneDropdown.Options and #elem.PopupData.BoneDropdown.Options > 0 then
                                        local optionY = ddY + ddH + 2
                                        local maxOptions = 8
                                        local optionHeight = 20
                                        local visibleOptions = math.min(#elem.PopupData.BoneDropdown.Options, maxOptions)
                                        local dropdownAreaH = visibleOptions * optionHeight
                                        
                                        local dropdownArea = {x = ddX, y = optionY - 2, w = ddW, h = dropdownAreaH + 4}
                                        
                                        table.insert(allOpenDropdowns, {
                                            type = "PopupBoneDropdown",
                                            dropdown = elem.PopupData.BoneDropdown,
                                            area = dropdownArea,
                                            buttonArea = {x = ddX, y = ddY, w = ddW, h = ddH},
                                            optionY = optionY,
                                            optionHeight = optionHeight,
                                            maxOptions = maxOptions,
                                            visibleOptions = visibleOptions,
                                            ddX = ddX,
                                            ddW = ddW
                                        })
                                    end
                                    
                                    popupCY = popupCY + 30
                                end
                                
                                if elem.PopupData.SpeedSlider then
                                    local sW = 100
                                    local sH = 4
                                    local sX = popupX + 75
                                    local sliderY = popupCY + 4
                                    
                            Ham.drawText("Speed", {x = popupX + 10, y = popupCY}, self.Parent.Colors.TextDim, 12, false, false, {0,0,0,255})
                            local valueText = string.format("%.1f", elem.PopupData.SpeedSlider.Value / 10.0)
                            local valueWidth, _ = Ham.getTextWidth(valueText)
                            Ham.drawText(valueText, {x = sX - valueWidth - 5, y = popupCY}, self.Parent.Colors.Text, 12, false, false, {0,0,0,255})
                                    
                                    Ham.drawRectFilled({x = sX, y = sliderY, w = sW, h = sH}, {50, 52, 60, 200}, 2, 15)
                                    
                                    local range = elem.PopupData.SpeedSlider.Max - elem.PopupData.SpeedSlider.Min
                                    local pct = (range > 0) and ((elem.PopupData.SpeedSlider.Value - elem.PopupData.SpeedSlider.Min) / range) or 0
                                    if pct < 0 then pct = 0 elseif pct > 1 then pct = 1 end
                                    Ham.drawRectFilled({x = sX, y = sliderY, w = sW * pct, h = sH}, self.Parent.Colors.Accent, 2, 15)
                            Ham.drawRectFilled({x = sX + (sW * pct) - 3, y = sliderY - 2, w = 6, h = 8}, self.Parent.Colors.Text, 2, 15)
                                    
                            if self.Parent.Input.MouseDown and self.Parent:IsHovering(sX - 5, sliderY - 2, sW + 10, 12) then
                                        elem.PopupData.SpeedSlider.Dragging = true
                                    end
                                    
                            if not self.Parent.Input.MouseDown then
                                        elem.PopupData.SpeedSlider.Dragging = false
                                    end
                                    
                                    if elem.PopupData.SpeedSlider.Dragging then
                                        local nx = self.Parent.Input.MX - sX
                                        local np = (sW > 0) and (nx / sW) or 0
                                        if np < 0 then np = 0 end
                                        if np > 1 then np = 1 end
                                        local range = elem.PopupData.SpeedSlider.Max - elem.PopupData.SpeedSlider.Min
                                        local rawValue = elem.PopupData.SpeedSlider.Min + (np * range)
                                        elem.PopupData.SpeedSlider.Value = math.floor(rawValue + 0.5)
                                        if elem.PopupData.SpeedSlider.Callback then
                                            elem.PopupData.SpeedSlider.Callback(elem.PopupData.SpeedSlider.Value)
                                        end
                                    end
                                    
                                    popupCY = popupCY + 30
                                end
                                
                        if elem.PopupData.Dropdown then
                            Ham.drawText("Mode", {x = popupX + 10, y = popupCY}, self.Parent.Colors.TextDim, 12, false, false, {0,0,0,255})
                                    
                                    local ddX = popupX + 60
                                    local ddY = popupCY - 2
                                    local ddW = 140
                                    local ddH = 22
                                    
                            local ddHovered = self.Parent:IsHovering(ddX, ddY, ddW, ddH)
                            Ham.drawRectFilled({x = ddX, y = ddY, w = ddW, h = ddH}, ddHovered and self.Parent.Colors.Hover or {38, 40, 48, 200}, 5, 15)
                            Ham.drawRect({x = ddX, y = ddY}, {x = ddX + ddW, y = ddY + ddH}, self.Parent.Colors.Border, 5, 0, 1)
                            
                            Ham.drawText(elem.PopupData.Dropdown.Options[elem.PopupData.Dropdown.Selected] or "", {x = ddX + 8, y = ddY + 4}, self.Parent.Colors.Text, 11, false, false, {0,0,0,255})
                            Ham.drawText("▼", {x = ddX + ddW - 15, y = ddY + 6}, self.Parent.Colors.TextDim, 10, true, false, {0,0,0,255})
                                    
                                    local anyOtherDropdownOpen = false
                                    for _, dd in ipairs(allOpenDropdowns) do
                                        if dd.type ~= "PopupDropdown" or dd.dropdown ~= elem.PopupData.Dropdown then
                                            anyOtherDropdownOpen = true
                                            break
                                        end
                                    end
                                    
                            if ddHovered and self.Parent.Input.MouseClicked and not anyOtherDropdownOpen and not self.Parent.SearchBarClickConsumed and not anyColorPickerOpen then
                                        if elem.PopupData.KeybindDropdown then
                                            elem.PopupData.KeybindDropdown.Open = false
                                        end
                                        if elem.PopupData.BoneDropdown then
                                            elem.PopupData.BoneDropdown.Open = false
                                        end
                                        elem.PopupData.Dropdown.Open = not elem.PopupData.Dropdown.Open
                                    end
                                    
                                    if elem.PopupData.Dropdown.Open and elem.PopupData.Dropdown.Options and #elem.PopupData.Dropdown.Options > 0 then
                                        local optionY = ddY + ddH + 2
                                        local maxOptions = 8
                                        local optionHeight = 20
                                        local visibleOptions = math.min(#elem.PopupData.Dropdown.Options, maxOptions)
                                        local dropdownAreaH = visibleOptions * optionHeight
                                        
                                        local dropdownArea = {x = ddX, y = optionY - 2, w = ddW, h = dropdownAreaH + 4}
                                        
                                        table.insert(allOpenDropdowns, {
                                            type = "PopupDropdown",
                                            dropdown = elem.PopupData.Dropdown,
                                            area = dropdownArea,
                                            buttonArea = {x = ddX, y = ddY, w = ddW, h = ddH},
                                            optionY = optionY,
                                            optionHeight = optionHeight,
                                            maxOptions = maxOptions,
                                            visibleOptions = visibleOptions,
                                            ddX = ddX,
                                            ddW = ddW
                                        })
                                    end
                                end
                                
                        if elem.PopupData.ColorPicker then
                            local cpX = popupX + 12
                            local cpY = popupCY + 2
                            local cpW = 250
                            
                            Ham.drawText("Color Picker", {x = cpX, y = cpY}, self.Parent.Colors.Accent, 13, false, false, {0,0,0,255})
                            cpY = cpY + 20
                            
                            local colorRef = elem.PopupData.ColorPicker.ColorRef
                            if not colorRef then
                                colorRef = {255, 255, 255, 255}
                            end
                            
                            if not elem.PopupData.ColorPicker.Dragging then
                                elem.PopupData.ColorPicker.Dragging = false
                            end
                            if not elem.PopupData.ColorPicker.HueDragging then
                                elem.PopupData.ColorPicker.HueDragging = false
                            end
                            
                            local function hsvToRgb(h, s, v)
                                local c = v * s
                                local x = c * (1 - math.abs((h * 6) % 2 - 1))
                                local m = v - c
                                local r, g, b = 0, 0, 0
                                if h < 1/6 then
                                    r, g, b = c, x, 0
                                elseif h < 2/6 then
                                    r, g, b = x, c, 0
                                elseif h < 3/6 then
                                    r, g, b = 0, c, x
                                elseif h < 4/6 then
                                    r, g, b = 0, x, c
                                elseif h < 5/6 then
                                    r, g, b = x, 0, c
                                else
                                    r, g, b = c, 0, x
                                end
                                return {math.floor((r + m) * 255), math.floor((g + m) * 255), math.floor((b + m) * 255), 255}
                            end
                            
                            local function rgbToHsv(r, g, b)
                                r, g, b = r / 255.0, g / 255.0, b / 255.0
                                local max = math.max(r, g, b)
                                local min = math.min(r, g, b)
                                local delta = max - min
                                
                                local h = 0
                                if delta ~= 0 then
                                    if max == r then
                                        h = ((g - b) / delta) % 6
                                    elseif max == g then
                                        h = (b - r) / delta + 2
                                    else
                                        h = (r - g) / delta + 4
                                    end
                                end
                                h = h / 6.0
                                if h < 0 then h = h + 1.0 end
                                
                                local s = (max > 0) and (delta / max) or 0
                                local v = max
                                return h, s, v
                            end
                            
                            if not elem.PopupData.ColorPicker.Initialized then
                                local h, s, v = rgbToHsv(colorRef[1], colorRef[2], colorRef[3])
                                elem.PopupData.ColorPicker.HSVH = h
                                elem.PopupData.ColorPicker.HSVS = s
                                elem.PopupData.ColorPicker.HSVV = v
                                elem.PopupData.ColorPicker.Initialized = true
                            end
                            
                            local hsvH = elem.PopupData.ColorPicker.HSVH or 0
                            local hsvS = elem.PopupData.ColorPicker.HSVS or 1.0
                            local hsvV = elem.PopupData.ColorPicker.HSVV or 1.0
                            
                            local mainAreaW = 200
                            local mainAreaH = 180
                            local hueBarW = 20
                            local hueBarH = mainAreaH
                            local alphaBarW = 20
                            local alphaBarH = mainAreaH
                            local mainAreaX = cpX
                            local mainAreaY = cpY
                            local hueBarX = cpX + mainAreaW + 10
                            local hueBarY = cpY
                            local alphaBarX = hueBarX + hueBarW + 10
                            local alphaBarY = cpY
                            
                            if not elem.PopupData.ColorPicker.Alpha then
                                elem.PopupData.ColorPicker.Alpha = colorRef[4] or 255
                            end
                            
                            local alpha = elem.PopupData.ColorPicker.Alpha
                            
                            local pickerX = mainAreaX + mainAreaW * hsvS
                            local pickerY = mainAreaY + mainAreaH * (1 - hsvV)
                            local hueBarYPos = hueBarY + hueBarH * (1 - hsvH)
                            
                            if self.Parent.Input.MouseDown then
                                if self.Parent:IsHovering(mainAreaX, mainAreaY, mainAreaW, mainAreaH) or elem.PopupData.ColorPicker.Dragging then
                                    elem.PopupData.ColorPicker.Dragging = true
                                    local mouseX = self.Parent.Input.MX
                                    local mouseY = self.Parent.Input.MY
                                    
                                    mouseX = math.max(mainAreaX, math.min(mainAreaX + mainAreaW, mouseX))
                                    mouseY = math.max(mainAreaY, math.min(mainAreaY + mainAreaH, mouseY))
                                    
                                    hsvS = (mouseX - mainAreaX) / mainAreaW
                                    hsvV = 1.0 - ((mouseY - mainAreaY) / mainAreaH)
                                    
                                    hsvS = math.max(0, math.min(1, hsvS))
                                    hsvV = math.max(0, math.min(1, hsvV))
                                    
                                    local newColor = hsvToRgb(hsvH, hsvS, hsvV)
                                    colorRef[1] = newColor[1]
                                    colorRef[2] = newColor[2]
                                    colorRef[3] = newColor[3]
                                    colorRef[4] = colorRef[4] or 255
                                    
                                    if elem.PopupData.ColorPicker.Callback then
                                        elem.PopupData.ColorPicker.Callback(colorRef)
                                    end
                                elseif self.Parent:IsHovering(hueBarX, hueBarY, hueBarW, hueBarH) or elem.PopupData.ColorPicker.HueDragging then
                                    elem.PopupData.ColorPicker.HueDragging = true
                                    local mouseY = self.Parent.Input.MY
                                    mouseY = math.max(hueBarY, math.min(hueBarY + hueBarH, mouseY))
                                    
                                    hsvH = 1.0 - ((mouseY - hueBarY) / hueBarH)
                                    hsvH = math.max(0, math.min(1, hsvH))
                                    
                                    local newColor = hsvToRgb(hsvH, hsvS, hsvV)
                                    colorRef[1] = newColor[1]
                                    colorRef[2] = newColor[2]
                                    colorRef[3] = newColor[3]
                                    colorRef[4] = colorRef[4] or 255
                                    
                                    if elem.PopupData.ColorPicker.Callback then
                                        elem.PopupData.ColorPicker.Callback(colorRef)
                                    end
                                elseif self.Parent:IsHovering(alphaBarX, alphaBarY, alphaBarW, alphaBarH) or elem.PopupData.ColorPicker.AlphaDragging then
                                    elem.PopupData.ColorPicker.AlphaDragging = true
                                    local mouseY = self.Parent.Input.MY
                                    mouseY = math.max(alphaBarY, math.min(alphaBarY + alphaBarH, mouseY))
                                    
                                    alpha = math.floor((1.0 - ((mouseY - alphaBarY) / alphaBarH)) * 255)
                                    alpha = math.max(0, math.min(255, alpha))
                                    elem.PopupData.ColorPicker.Alpha = alpha
                                    colorRef[4] = alpha
                                    
                                    if elem.PopupData.ColorPicker.Callback then
                                        elem.PopupData.ColorPicker.Callback(colorRef)
                                    end
                                end
                            else
                                elem.PopupData.ColorPicker.Dragging = false
                                elem.PopupData.ColorPicker.HueDragging = false
                                elem.PopupData.ColorPicker.AlphaDragging = false
                            end
                            
                            elem.PopupData.ColorPicker.HSVH = hsvH
                            elem.PopupData.ColorPicker.HSVS = hsvS
                            elem.PopupData.ColorPicker.HSVV = hsvV
                            
                            pickerX = mainAreaX + mainAreaW * hsvS
                            pickerY = mainAreaY + mainAreaH * (1 - hsvV)
                            hueBarYPos = hueBarY + hueBarH * (1 - hsvH)
                            
                            local baseColor = hsvToRgb(hsvH, 1.0, 1.0)
                            local whiteColor = {255, 255, 255, 255}
                            local blackColor = {0, 0, 0, 255}
                            
                            local numVerticalSegments = 20
                            local segmentH = mainAreaH / numVerticalSegments
                            
                            for ySeg = 0, numVerticalSegments - 1 do
                                local y = mainAreaY + ySeg * segmentH
                                local v = ySeg / numVerticalSegments
                                
                                local topLeftColor = {
                                    math.floor(whiteColor[1] * (1 - v) + blackColor[1] * v),
                                    math.floor(whiteColor[2] * (1 - v) + blackColor[2] * v),
                                    math.floor(whiteColor[3] * (1 - v) + blackColor[3] * v),
                                    255
                                }
                                local topRightColor = {
                                    math.floor(baseColor[1] * (1 - v) + blackColor[1] * v),
                                    math.floor(baseColor[2] * (1 - v) + blackColor[2] * v),
                                    math.floor(baseColor[3] * (1 - v) + blackColor[3] * v),
                                    255
                                }
                                
                                local numHorizontalSegments = 20
                                local segmentW = mainAreaW / numHorizontalSegments
                                
                                for xSeg = 0, numHorizontalSegments - 1 do
                                    local x = mainAreaX + xSeg * segmentW
                                    local s = xSeg / numHorizontalSegments
                                    
                                    local color1 = {
                                        math.floor(topLeftColor[1] * (1 - s) + topRightColor[1] * s),
                                        math.floor(topLeftColor[2] * (1 - s) + topRightColor[2] * s),
                                        math.floor(topLeftColor[3] * (1 - s) + topRightColor[3] * s),
                                        255
                                    }
                                    
                                    local nextS = (xSeg + 1) / numHorizontalSegments
                                    local color2 = {
                                        math.floor(topLeftColor[1] * (1 - nextS) + topRightColor[1] * nextS),
                                        math.floor(topLeftColor[2] * (1 - nextS) + topRightColor[2] * nextS),
                                        math.floor(topLeftColor[3] * (1 - nextS) + topRightColor[3] * nextS),
                                        255
                                    }
                                    
                                    Ham.drawRectGradient({x = x, y = y, w = segmentW, h = segmentH}, color1, color2, false)
                                end
                            end
                            
                            Ham.drawRect({x = mainAreaX, y = mainAreaY}, {x = mainAreaX + mainAreaW, y = mainAreaY + mainAreaH}, {50, 52, 60, 255}, 0, 0, 2)
                            Ham.drawRect({x = mainAreaX - 1, y = mainAreaY - 1}, {x = mainAreaX + mainAreaW + 1, y = mainAreaY + mainAreaH + 1}, {20, 22, 28, 255}, 0, 0, 1)
                            
                            local numHueSegments = 60
                            local hueSegH = hueBarH / numHueSegments
                            for i = 0, numHueSegments - 1 do
                                local h = i / numHueSegments
                                local hueColor = hsvToRgb(h, 1.0, 1.0)
                                Ham.drawRectFilled({x = hueBarX, y = hueBarY + i * hueSegH, w = hueBarW, h = math.ceil(hueSegH)}, hueColor, 0, 15)
                            end
                            
                            Ham.drawRect({x = hueBarX, y = hueBarY}, {x = hueBarX + hueBarW, y = hueBarY + hueBarH}, {50, 52, 60, 255}, 0, 0, 2)
                            Ham.drawRect({x = hueBarX - 1, y = hueBarY - 1}, {x = hueBarX + hueBarW + 1, y = hueBarY + hueBarH + 1}, {20, 22, 28, 255}, 0, 0, 1)
                            
                            local hueIndicatorY = math.max(hueBarY, math.min(hueBarY + hueBarH, hueBarYPos))
                            Ham.drawRectFilled({x = hueBarX - 4, y = hueIndicatorY - 3, w = hueBarW + 8, h = 6}, {255, 255, 255, 255}, 0, 15)
                            Ham.drawRect({x = hueBarX - 4, y = hueIndicatorY - 3}, {x = hueBarX + hueBarW + 4, y = hueIndicatorY + 3}, {0, 0, 0, 180}, 0, 0, 1)
                            
                            local currentRgb = hsvToRgb(hsvH, hsvS, hsvV)
                            local numAlphaSegments = 60
                            local alphaSegH = alphaBarH / numAlphaSegments
                            for i = 0, numAlphaSegments - 1 do
                                local alphaVal = (i / numAlphaSegments) * 255
                                local alphaColor = {currentRgb[1], currentRgb[2], currentRgb[3], math.floor(alphaVal)}
                                Ham.drawRectFilled({x = alphaBarX, y = alphaBarY + i * alphaSegH, w = alphaBarW, h = math.ceil(alphaSegH)}, alphaColor, 0, 15)
                            end
                            
                            Ham.drawRect({x = alphaBarX, y = alphaBarY}, {x = alphaBarX + alphaBarW, y = alphaBarY + alphaBarH}, {50, 52, 60, 255}, 0, 0, 2)
                            Ham.drawRect({x = alphaBarX - 1, y = alphaBarY - 1}, {x = alphaBarX + alphaBarW + 1, y = alphaBarY + alphaBarH + 1}, {20, 22, 28, 255}, 0, 0, 1)
                            
                            local alphaBarYPos = alphaBarY + alphaBarH * (1 - alpha / 255)
                            local alphaIndicatorY = math.max(alphaBarY, math.min(alphaBarY + alphaBarH, alphaBarYPos))
                            Ham.drawRectFilled({x = alphaBarX - 4, y = alphaIndicatorY - 3, w = alphaBarW + 8, h = 6}, {255, 255, 255, 255}, 0, 15)
                            Ham.drawRect({x = alphaBarX - 4, y = alphaIndicatorY - 3}, {x = alphaBarX + alphaBarW + 4, y = alphaIndicatorY + 3}, {0, 0, 0, 180}, 0, 0, 1)
                            
                            Ham.drawCircle({x = pickerX, y = pickerY, radius = 8}, {0, 0, 0, 180}, 16, 2, false)
                            Ham.drawCircle({x = pickerX, y = pickerY, radius = 7}, {255, 255, 255, 255}, 16, 2, false)
                            Ham.drawCircle({x = pickerX, y = pickerY, radius = 5}, colorRef, 16, 0, true)
                            
                            cpY = cpY + mainAreaH + 18
                            
                            local inputY = cpY
                            local inputW = 50
                            local inputH = 18
                            local inputSpacing = 5
                            
                            Ham.drawText("R", {x = cpX + 3, y = inputY + 4}, self.Parent.Colors.TextDim, 11, false, false, {0,0,0,255})
                            Ham.drawRectFilled({x = cpX + 15, y = inputY, w = inputW, h = inputH}, {30, 32, 40, 255}, 3, 15)
                            Ham.drawRect({x = cpX + 15, y = inputY}, {x = cpX + 15 + inputW, y = inputY + inputH}, self.Parent.Colors.Border, 3, 0, 1)
                            Ham.drawText(tostring(colorRef[1]), {x = cpX + 18, y = inputY + 4}, self.Parent.Colors.Text, 10, false, false, {0,0,0,255})
                            
                            Ham.drawText("G", {x = cpX + 18 + inputW + inputSpacing, y = inputY + 4}, self.Parent.Colors.TextDim, 11, false, false, {0,0,0,255})
                            Ham.drawRectFilled({x = cpX + 30 + inputW + inputSpacing, y = inputY, w = inputW, h = inputH}, {30, 32, 40, 255}, 3, 15)
                            Ham.drawRect({x = cpX + 30 + inputW + inputSpacing, y = inputY}, {x = cpX + 30 + inputW * 2 + inputSpacing, y = inputY + inputH}, self.Parent.Colors.Border, 3, 0, 1)
                            Ham.drawText(tostring(colorRef[2]), {x = cpX + 33 + inputW + inputSpacing, y = inputY + 4}, self.Parent.Colors.Text, 10, false, false, {0,0,0,255})
                            
                            Ham.drawText("B", {x = cpX + 33 + inputW * 2 + inputSpacing * 2, y = inputY + 4}, self.Parent.Colors.TextDim, 11, false, false, {0,0,0,255})
                            Ham.drawRectFilled({x = cpX + 45 + inputW * 2 + inputSpacing * 2, y = inputY, w = inputW, h = inputH}, {30, 32, 40, 255}, 3, 15)
                            Ham.drawRect({x = cpX + 45 + inputW * 2 + inputSpacing * 2, y = inputY}, {x = cpX + 45 + inputW * 3 + inputSpacing * 2, y = inputY + inputH}, self.Parent.Colors.Border, 3, 0, 1)
                            Ham.drawText(tostring(colorRef[3]), {x = cpX + 48 + inputW * 2 + inputSpacing * 2, y = inputY + 4}, self.Parent.Colors.Text, 10, false, false, {0,0,0,255})
                            
                            inputY = inputY + inputH + 10
                            
                            local copyBtnX = cpX
                            local copyBtnY = inputY
                            local copyBtnW = 70
                            local copyBtnH = 20
                            local copyHovered = self.Parent:IsHovering(copyBtnX, copyBtnY, copyBtnW, copyBtnH)
                            
                            Ham.drawRectFilled({x = copyBtnX, y = copyBtnY, w = copyBtnW, h = copyBtnH}, copyHovered and self.Parent.Colors.Hover or {40, 42, 50, 255}, 4, 15)
                            Ham.drawRect({x = copyBtnX, y = copyBtnY}, {x = copyBtnX + copyBtnW, y = copyBtnY + copyBtnH}, self.Parent.Colors.Border, 4, 0, 1)
                            Ham.drawText("Copy", {x = copyBtnX + copyBtnW / 2, y = copyBtnY + 5}, self.Parent.Colors.Text, 11, true, false, {0,0,0,255})
                            
                            if copyHovered and self.Parent.Input.MouseClicked and not self.Parent.SearchBarClickConsumed then
                                self.Parent.SearchBarClickConsumed = true
                                local alpha = elem.PopupData.ColorPicker.Alpha or colorRef[4] or 255
                                local colorStr = string.format("%d,%d,%d,%d", colorRef[1], colorRef[2], colorRef[3], alpha)
                                if ImGui and ImGui.SetClipboardText then
                                    ImGui.SetClipboardText(colorStr)
                                end
                            end
                            
                            local pasteBtnX = copyBtnX + copyBtnW + 10
                            local pasteBtnY = inputY
                            local pasteBtnW = 70
                            local pasteBtnH = 20
                            local pasteHovered = self.Parent:IsHovering(pasteBtnX, pasteBtnY, pasteBtnW, pasteBtnH)
                            
                            Ham.drawRectFilled({x = pasteBtnX, y = pasteBtnY, w = pasteBtnW, h = pasteBtnH}, pasteHovered and self.Parent.Colors.Hover or {40, 42, 50, 255}, 4, 15)
                            Ham.drawRect({x = pasteBtnX, y = pasteBtnY}, {x = pasteBtnX + pasteBtnW, y = pasteBtnY + pasteBtnH}, self.Parent.Colors.Border, 4, 0, 1)
                            Ham.drawText("Paste", {x = pasteBtnX + pasteBtnW / 2, y = pasteBtnY + 5}, self.Parent.Colors.Text, 11, true, false, {0,0,0,255})
                            
                            if pasteHovered and self.Parent.Input.MouseClicked and not self.Parent.SearchBarClickConsumed then
                                self.Parent.SearchBarClickConsumed = true
                                if ImGui and ImGui.GetClipboardText then
                                    local clipboardText = ImGui.GetClipboardText()
                                    if clipboardText then
                                        local r, g, b, a = clipboardText:match("(%d+),%s*(%d+),%s*(%d+),?%s*(%d*)")
                                        if r and g and b then
                                            r, g, b = tonumber(r), tonumber(g), tonumber(b)
                                            if r and g and b and r >= 0 and r <= 255 and g >= 0 and g <= 255 and b >= 0 and b <= 255 then
                                                colorRef[1] = r
                                                colorRef[2] = g
                                                colorRef[3] = b
                                                
                                                if a and a ~= "" then
                                                    a = tonumber(a)
                                                    if a and a >= 0 and a <= 255 then
                                                        colorRef[4] = a
                                                        elem.PopupData.ColorPicker.Alpha = a
                                                    end
                                                end
                                                
                                                local h, s, v = rgbToHsv(r, g, b)
                                                elem.PopupData.ColorPicker.HSVH = h
                                                elem.PopupData.ColorPicker.HSVS = s
                                                elem.PopupData.ColorPicker.HSVV = v
                                                
                                                elem.PopupData.ColorPicker.Initialized = true
                                                if elem.PopupData.ColorPicker.Callback then
                                                    elem.PopupData.ColorPicker.Callback(colorRef)
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                
                for _, ddInfo in ipairs(allOpenDropdowns) do
                    local dropdownArea = ddInfo.area
                    local buttonArea = ddInfo.buttonArea
                    local animValue = ddInfo.animValue or 1.0
                    local isHoveringDropdown = self.Parent:IsHovering(dropdownArea.x, dropdownArea.y, dropdownArea.w, dropdownArea.h) or self.Parent:IsHovering(buttonArea.x, buttonArea.y, buttonArea.w, buttonArea.h)
                    
                    local dropdownAlpha = math.floor(255 * animValue)
                    local dropdownColor = {self.Parent.Colors.Dropdown[1], self.Parent.Colors.Dropdown[2], self.Parent.Colors.Dropdown[3], dropdownAlpha}
                    Ham.drawRectFilled({x = dropdownArea.x, y = dropdownArea.y, w = dropdownArea.w, h = dropdownArea.h}, dropdownColor, 5, 15)
                    local borderAlpha = math.floor(255 * animValue)
                    local borderColor = {self.Parent.Colors.Border[1], self.Parent.Colors.Border[2], self.Parent.Colors.Border[3], borderAlpha}
                    Ham.drawRect({x = dropdownArea.x, y = dropdownArea.y}, {x = dropdownArea.x + dropdownArea.w, y = dropdownArea.y + dropdownArea.h}, borderColor, 5, 0, 1)
                    
                    local dropdown = ddInfo.dropdown or ddInfo.elem
                    local isMultiDropdown = ddInfo.type == "SectionMultiDropdown"
                    
                    if isMultiDropdown then
                        if not dropdown.Selected then
                            dropdown.Selected = {}
                        end
                        local scrollOffset = ddInfo.scrollOffset or 0
                        local startIdx = 1 + scrollOffset
                        local endIdx = math.min(#dropdown.Options, startIdx + ddInfo.visibleOptions - 1)
                        local ddX = ddInfo.ddX or buttonArea.x
                        local ddW = ddInfo.ddW or buttonArea.w
                        
                        for optIdx = startIdx, endIdx do
                            local option = dropdown.Options[optIdx]
                            if option then
                                local displayIdx = optIdx - startIdx
                                local optY = ddInfo.optionY + displayIdx * ddInfo.optionHeight
                                local optHovered = self.Parent:IsHovering(ddX, optY, ddW, ddInfo.optionHeight)
                                local optBaseColor = optHovered and self.Parent.Colors.Hover or {36, 38, 46, 200}
                                local optColor = {optBaseColor[1], optBaseColor[2], optBaseColor[3], math.floor((optBaseColor[4] or 200) * animValue)}
                                
                                Ham.drawRectFilled({x = ddX, y = optY, w = ddW, h = ddInfo.optionHeight}, optColor, 3, 15)
                                
                                local isSelected = false
                                for _, selIdx in ipairs(dropdown.Selected) do
                                    if selIdx == optIdx then
                                        isSelected = true
                                        break
                                    end
                                end
                                
                                local checkBoxSize = 10
                                local checkBoxX = ddX + 5
                                local checkBoxY = optY + (ddInfo.optionHeight - checkBoxSize) / 2
                                local checkBoxColor = isSelected and self.Parent.Colors.Accent or {60, 62, 70, 255}
                                local checkBoxAlpha = math.floor((checkBoxColor[4] or 255) * animValue)
                                Ham.drawRectFilled({x = checkBoxX, y = checkBoxY, w = checkBoxSize, h = checkBoxSize}, {checkBoxColor[1], checkBoxColor[2], checkBoxColor[3], checkBoxAlpha}, 2, 15)
                                Ham.drawRect({x = checkBoxX, y = checkBoxY}, {x = checkBoxX + checkBoxSize, y = checkBoxY + checkBoxSize}, self.Parent.Colors.Border, 2, 0, 1)
                                
                                if isSelected then
                                    Ham.drawText("✓", {x = checkBoxX + checkBoxSize / 2, y = checkBoxY - 1}, {255, 255, 255, checkBoxAlpha}, 10, true, false, {0,0,0,255})
                                end
                                
                                local textColor = isSelected and self.Parent.Colors.Accent or self.Parent.Colors.Text
                                local textAlpha = math.floor((textColor[4] or 255) * animValue)
                                local finalTextColor = {textColor[1], textColor[2], textColor[3], textAlpha}
                                Ham.drawText(option, {x = checkBoxX + checkBoxSize + 8, y = optY + 4}, finalTextColor, 12, false, false, {0,0,0,255})
                                
                                if optHovered and self.Parent.Input.MouseClicked and not self.Parent.SearchBarClickConsumed and not anyColorPickerOpen then
                                    local found = false
                                    for i, selIdx in ipairs(dropdown.Selected) do
                                        if selIdx == optIdx then
                                            table.remove(dropdown.Selected, i)
                                            found = true
                                            break
                                        end
                                    end
                                    if not found then
                                        table.insert(dropdown.Selected, optIdx)
                                    end
                                    if dropdown.Callback then
                                        local selectedValues = {}
                                        for _, selIdx in ipairs(dropdown.Selected) do
                                            if dropdown.Options[selIdx] then
                                                table.insert(selectedValues, dropdown.Options[selIdx])
                                            end
                                        end
                                        dropdown.Callback(dropdown.Selected, selectedValues)
                                    end
                                    self.Parent.SearchBarClickConsumed = true
                                end
                            end
                        end
                    else
                        local startIdx = 1
                        local endIdx = math.min(#dropdown.Options, startIdx + ddInfo.visibleOptions - 1)
                        local ddX = ddInfo.ddX or buttonArea.x
                        local ddW = ddInfo.ddW or buttonArea.w
                        
                        for optIdx = startIdx, endIdx do
                            local option = dropdown.Options[optIdx]
                            if option then
                                local optY = ddInfo.optionY + (optIdx - startIdx) * ddInfo.optionHeight
                                local optHovered = self.Parent:IsHovering(ddX, optY, ddW, ddInfo.optionHeight)
                                local optBaseColor = optHovered and self.Parent.Colors.Hover or {36, 38, 46, 200}
                                local optColor = {optBaseColor[1], optBaseColor[2], optBaseColor[3], math.floor((optBaseColor[4] or 200) * animValue)}
                                
                                Ham.drawRectFilled({x = ddX, y = optY, w = ddW, h = ddInfo.optionHeight}, optColor, 3, 15)
                                
                                local textColor = (optIdx == dropdown.Selected) and self.Parent.Colors.Accent or self.Parent.Colors.Text
                                local textAlpha = math.floor((textColor[4] or 255) * animValue)
                                local finalTextColor = {textColor[1], textColor[2], textColor[3], textAlpha}
                                Ham.drawText(option, {x = ddX + 8, y = optY + 4}, finalTextColor, 12, false, false, {0,0,0,255})
                                
                                if optHovered and self.Parent.Input.MouseClicked and not self.Parent.SearchBarClickConsumed and not anyColorPickerOpen then
                                    dropdown.Selected = optIdx
                                    dropdown.Open = false
                                    if dropdown.Callback then
                                        dropdown.Callback(optIdx, option)
                                    end
                                    if ddInfo.type == "PopupKeybindDropdown" and dropdown.Values and dropdown.Values[optIdx] then
                                        if self.Parent.OnKeybindChanged then
                                            self.Parent.OnKeybindChanged(dropdown.Values[optIdx])
                                        end
                                    end
                                end
                            end
                        end
                    end
                    
                    if self.Parent.Input.MouseClicked and not isHoveringDropdown and not self.Parent.SearchBarClickConsumed then
                        if not isMultiDropdown then
                            dropdown.Open = false
                        end
                    end
                end
                
            end
    end
    
        if self.Parent.customFont and Ham and Ham.resetFont then
            Ham.resetFont()
        end
    end
    
    table.insert(self.Windows, Window)
    self:AddSettingsTab(Window)
    return Window
end

function VialLibrary:AddSettingsTab(window)
    local settingsTab = window:AddTab("Settings")
    local appearanceSubTab = settingsTab:AddSubTab("Appearance")
    local colorsSubTab = settingsTab:AddSubTab("Colors")
    local opacitySubTab = settingsTab:AddSubTab("Opacity")
    
    local appearanceSection = appearanceSubTab:AddSection("Theme", "left")
    appearanceSection:AddSelector("Theme", {"Default", "Gradient Vertical", "Gradient Horizontal", "Modern Gradient"}, self.selectedTheme, function(idx, option)
        self.selectedTheme = idx
    end)
    appearanceSection:AddToggle("Rainbow Theme", self.rainbowTheme, function(val)
        self.rainbowTheme = val
    end)
    appearanceSection:AddColorPicker("Menu Color", self.menuColor, function(color)
        self.menuColor = color
    end)
    appearanceSection:AddSlider("DPI", 50, 200, math.floor(self.menuDpi * 100), function(val)
        self.TargetDpi = val / 100.0
    end)
    
    local bgColorSection = colorsSubTab:AddSection("Background", "left")
    bgColorSection:AddColorPicker("Background", self.Colors.Background, function(color)
        self.Colors.Background = color
    end)
    bgColorSection:AddColorPicker("Sidebar", self.Colors.Sidebar, function(color)
        self.Colors.Sidebar = color
    end)
    bgColorSection:AddColorPicker("Element", self.Colors.Element, function(color)
        self.Colors.Element = color
    end)
    local textColorSection = colorsSubTab:AddSection("Text", "left")
    textColorSection:AddColorPicker("Text", self.Colors.Text, function(color)
        self.Colors.Text = color
    end)
    textColorSection:AddColorPicker("Text Dim", self.Colors.TextDim, function(color)
        self.Colors.TextDim = color
    end)
    
    local borderColorSection = colorsSubTab:AddSection("Border", "left")
    borderColorSection:AddColorPicker("Border", self.Colors.Border, function(color)
        self.Colors.Border = color
    end)
    borderColorSection:AddColorPicker("Dropdown", self.Colors.Dropdown, function(color)
        self.Colors.Dropdown = color
    end)
    borderColorSection:AddColorPicker("Hover", self.Colors.Hover, function(color)
        self.Colors.Hover = color
    end)
    borderColorSection:AddColorPicker("Footer", self.Colors.Footer, function(color)
        self.Colors.Footer = color
    end)
    
    local opacitySection = opacitySubTab:AddSection("Opacity", "left")
    opacitySection:AddSlider("UI Opacity", 0, 255, self.uiOpacity, function(val)
        self.uiOpacity = val
    end)
    opacitySection:AddSlider("Background", 0, 255, self.backgroundOpacity, function(val)
        self.backgroundOpacity = val
    end)
    opacitySection:AddSlider("Sidebar", 0, 255, self.sidebarOpacity, function(val)
        self.sidebarOpacity = val
    end)
    opacitySection:AddSlider("Element", 0, 255, self.elementOpacity, function(val)
        self.elementOpacity = val
    end)
    
    window.ActiveTab = settingsTab
    return settingsTab
end

function VialLibrary:Update()
    if self.Unload then
        return
    end
    
    local keyPressed = false
    
    if self.ToggleKey then
        if type(self.ToggleKey) == "string" then
            local keyCode = nil
            if ImGuiKey and ImGuiKey[self.ToggleKey] then
                keyCode = ImGuiKey[self.ToggleKey]
            elseif self.ToggleKey == "Insert" then
                keyCode = 45
            end
            
            if keyCode then
                if ImGuiKey and ImGuiKey[self.ToggleKey] then
                    keyPressed = Ham.isKeyPressed(keyCode)
                else
                    local keyState = Ham.getKeyState(keyCode)
                    if keyState ~= 0 then
                        if not self.LastToggleKeyState then
                            keyPressed = true
                            self.LastToggleKeyState = true
                        end
                    else
                        self.LastToggleKeyState = false
                    end
                end
            end
        elseif type(self.ToggleKey) == "number" then
            local keyState = Ham.getKeyState(self.ToggleKey)
            if keyState ~= 0 then
                if not self.LastToggleKeyState then
                    keyPressed = true
                    self.LastToggleKeyState = true
                end
            else
                self.LastToggleKeyState = false
            end
        end
    end
    
    if keyPressed then
        self.Open = not self.Open
        Ham.toggleMouse()
    end
    
    for _, window in ipairs(self.Windows) do
        if window.ActiveTab and window.ActiveTab.ActiveSubTab then
            for _, sec in ipairs(window.ActiveTab.ActiveSubTab.Sections.Left) do
                for _, elem in ipairs(sec.Elements) do
                    if elem.Keybind and (elem.Type == "Toggle" or elem.Type == "Button" or elem.Type == "Slider") then
                        local keyState = Ham.getKeyState(elem.Keybind)
                        if keyState ~= 0 then
                            if not elem.LastKeybindState then
                                if elem.Type == "Toggle" then
                                    elem.Value = not elem.Value
                                    if elem.Callback then elem.Callback(elem.Value) end
                                elseif elem.Type == "Button" then
                                    if elem.Callback then elem.Callback() end
                                elseif elem.Type == "Slider" then
                                    if elem.Callback then elem.Callback(elem.Value) end
                                end
                                elem.LastKeybindState = true
                            end
                        else
                            elem.LastKeybindState = false
                        end
                    end
                end
            end
            for _, sec in ipairs(window.ActiveTab.ActiveSubTab.Sections.Middle) do
                for _, elem in ipairs(sec.Elements) do
                    if elem.Keybind and (elem.Type == "Toggle" or elem.Type == "Button" or elem.Type == "Slider") then
                        local keyState = Ham.getKeyState(elem.Keybind)
                        if keyState ~= 0 then
                            if not elem.LastKeybindState then
                                if elem.Type == "Toggle" then
                                    elem.Value = not elem.Value
                                    if elem.Callback then elem.Callback(elem.Value) end
                                elseif elem.Type == "Button" then
                                    if elem.Callback then elem.Callback() end
                                elseif elem.Type == "Slider" then
                                    if elem.Callback then elem.Callback(elem.Value) end
                                end
                                elem.LastKeybindState = true
                            end
                        else
                            elem.LastKeybindState = false
                        end
                    end
                end
            end
            for _, sec in ipairs(window.ActiveTab.ActiveSubTab.Sections.Right) do
                for _, elem in ipairs(sec.Elements) do
                    if elem.Keybind and (elem.Type == "Toggle" or elem.Type == "Button" or elem.Type == "Slider") then
                        local keyState = Ham.getKeyState(elem.Keybind)
                        if keyState ~= 0 then
                            if not elem.LastKeybindState then
                                if elem.Type == "Toggle" then
                                    elem.Value = not elem.Value
                                    if elem.Callback then elem.Callback(elem.Value) end
                                elseif elem.Type == "Button" then
                                    if elem.Callback then elem.Callback() end
                                elseif elem.Type == "Slider" then
                                    if elem.Callback then elem.Callback(elem.Value) end
                                end
                                elem.LastKeybindState = true
                            end
                        else
                            elem.LastKeybindState = false
                        end
                    end
                end
            end
        end
    end
    
    if self.Open then
        local mx, my = Ham.getMousePos()
        self.Input.MX, self.Input.MY = mx or 0, my or 0
        
        self.Input.MouseDown = Ham.isMouseDown(0)
        
        self.Input.MouseClicked = Ham.isMouseClicked(0)
        
        local currentRightClick = Ham.isMouseClicked(1)
        self.Input.MouseRightClicked = currentRightClick and not self.LastRightClickState
        self.LastRightClickState = currentRightClick
        
        self.SearchBarClickConsumed = false
        
        if self.TargetDpi and self.menuDpi ~= self.TargetDpi then
            local diff = self.TargetDpi - self.menuDpi
            if math.abs(diff) > 0.005 then
                self.menuDpi = self.menuDpi + diff * 0.25
            else
                self.menuDpi = self.TargetDpi
            end
        end
        
        if self.customFont then
            Ham.setFont(self.customFont)
        end
        
        if self.Windows and #self.Windows > 0 then
            for _, window in ipairs(self.Windows) do
                if window then
                    window:Render()
                end
            end
        end
        
        local screenWidth, screenHeight = 1920, 1080
        if Ham and Ham.getResolution then
            screenWidth, screenHeight = Ham.getResolution()
        end
        
        local anyKeybindPopupOpen = false
        local keybindPopupElem = nil
        local keybindPopupWindow = nil
        if self.Windows then
            for _, window in ipairs(self.Windows) do
                if window.ActiveTab and window.ActiveTab.ActiveSubTab then
                    for _, sec in ipairs(window.ActiveTab.ActiveSubTab.Sections.Left) do
                        for _, elem in ipairs(sec.Elements) do
                            if (elem.Type == "Button" or elem.Type == "Toggle" or elem.Type == "Slider") and elem.KeybindPopupOpen then
                                anyKeybindPopupOpen = true
                                keybindPopupElem = elem
                                keybindPopupWindow = window
                                break
                            end
                        end
                        if anyKeybindPopupOpen then break end
                    end
                    if not anyKeybindPopupOpen then
                        for _, sec in ipairs(window.ActiveTab.ActiveSubTab.Sections.Middle) do
                            for _, elem in ipairs(sec.Elements) do
                                if (elem.Type == "Button" or elem.Type == "Toggle" or elem.Type == "Slider") and elem.KeybindPopupOpen then
                                    anyKeybindPopupOpen = true
                                    keybindPopupElem = elem
                                    keybindPopupWindow = window
                                    break
                                end
                            end
                            if anyKeybindPopupOpen then break end
                        end
                    end
                    if not anyKeybindPopupOpen then
                        for _, sec in ipairs(window.ActiveTab.ActiveSubTab.Sections.Right) do
                            for _, elem in ipairs(sec.Elements) do
                                if (elem.Type == "Button" or elem.Type == "Toggle" or elem.Type == "Slider") and elem.KeybindPopupOpen then
                                    anyKeybindPopupOpen = true
                                    keybindPopupElem = elem
                                    keybindPopupWindow = window
                                    break
                                end
                            end
                            if anyKeybindPopupOpen then break end
                        end
                    end
                end
                if anyKeybindPopupOpen then break end
            end
        end
        
        if anyKeybindPopupOpen and keybindPopupElem and keybindPopupWindow then
            local popupW = 300 * self.menuDpi
            local popupH = 140 * self.menuDpi
            
            local windowX = keybindPopupWindow.X
            local windowY = keybindPopupWindow.Y
            local windowW = keybindPopupWindow.W * self.menuDpi
            local windowH = keybindPopupWindow.H * self.menuDpi
            
            local centerX = windowX + windowW / 2
            local centerY = windowY + windowH / 2
            
            local popupX = centerX - (popupW / 2)
            local popupY = centerY - (popupH / 2)
            
            if popupX < windowX then
                popupX = windowX + 10 * self.menuDpi
            end
            if popupY < windowY then
                popupY = windowY + 10 * self.menuDpi
            end
            if popupX + popupW > windowX + windowW then
                popupX = windowX + windowW - popupW - 10 * self.menuDpi
            end
            if popupY + popupH > windowY + windowH then
                popupY = windowY + windowH - popupH - 10 * self.menuDpi
            end
            
            if not keybindPopupElem.KeybindScrollOffset then
                keybindPopupElem.KeybindScrollOffset = 0
            end
            if not keybindPopupElem.LastScrollState then
                keybindPopupElem.LastScrollState = {up = false, down = false}
            end
            
            local maxScroll = math.max(0, popupH - (windowH - 20 * self.menuDpi))
            if maxScroll > 0 then
                local popupArea = {x = popupX, y = popupY, w = popupW, h = popupH}
                local isHoveringPopup = self:IsHovering(popupArea.x, popupArea.y, popupArea.w, popupArea.h)
                
                if isHoveringPopup then
                    DisableControlAction(0, 14, true)
                    DisableControlAction(0, 15, true)
                    
                    local scrollUp = IsControlJustPressed(0, 14)
                    local scrollDown = IsControlJustPressed(0, 15)
                    
                    if scrollUp then
                        keybindPopupElem.KeybindScrollOffset = math.max(0, keybindPopupElem.KeybindScrollOffset - 15 * self.menuDpi)
                    end
                    
                    if scrollDown then
                        keybindPopupElem.KeybindScrollOffset = math.min(maxScroll, keybindPopupElem.KeybindScrollOffset + 15 * self.menuDpi)
                    end
                end
                
                popupY = popupY - keybindPopupElem.KeybindScrollOffset
            end
            
            Ham.drawRectFilled({x = popupX, y = popupY, w = popupW, h = popupH}, {28, 30, 36, 255}, 8 * self.menuDpi, 15)
            Ham.drawRect({x = popupX, y = popupY}, {x = popupX + popupW, y = popupY + popupH}, self.Colors.Border, 8 * self.menuDpi, 0, 1)
            Ham.drawRectFilled({x = popupX, y = popupY, w = popupW, h = 3 * self.menuDpi}, self.Colors.Accent, 8 * self.menuDpi, 15)
            
            local titleY = popupY + 15 * self.menuDpi
            Ham.drawText("Set Keybind", {x = popupX + popupW / 2, y = titleY}, self.Colors.Text, 16 * self.menuDpi, true, false, {0,0,0,255})
            
            local instructionY = popupY + 45 * self.menuDpi
            local instructionText = "Press any key..."
            if keybindPopupElem.PendingKey then
                instructionText = "Key: " .. GetKeyName(keybindPopupElem.PendingKey)
            elseif keybindPopupElem.Keybind then
                instructionText = "Key: " .. GetKeyName(keybindPopupElem.Keybind)
            end
            Ham.drawText(instructionText, {x = popupX + popupW / 2, y = instructionY}, self.Colors.TextDim, 13 * self.menuDpi, true, false, {0,0,0,255})
            
            local helpY = popupY + 65 * self.menuDpi
            local helpText = keybindPopupElem.PendingKey and "Press ENTER to confirm, ESC to cancel" or "Press ENTER to confirm, ESC to cancel"
            Ham.drawText(helpText, {x = popupX + popupW / 2, y = helpY}, {120, 120, 130, 255}, 11 * self.menuDpi, true, false, {0,0,0,255})
            
            if keybindPopupElem.WaitingForKey then
                local escKey = Ham.getKeyState(27)
                if escKey ~= 0 then
                    if not keybindPopupElem.LastEscState then
                        keybindPopupElem.WaitingForKey = false
                        keybindPopupElem.KeybindPopupOpen = false
                        keybindPopupElem.PendingKey = nil
                        keybindPopupElem.LastEscState = true
                    end
                else
                    keybindPopupElem.LastEscState = false
                end
                
                local toggleKeyCode = nil
                if self.ToggleKey then
                    if type(self.ToggleKey) == "string" then
                        if self.ToggleKey == "Insert" then
                            toggleKeyCode = 45
                        end
                    elseif type(self.ToggleKey) == "number" then
                        toggleKeyCode = self.ToggleKey
                    end
                end
                
                for _, keyCode in ipairs(ValidKeyCodes) do
                    if keyCode ~= 16 and keyCode ~= 17 and keyCode ~= 18 and keyCode ~= 13 and keyCode ~= 27 and keyCode ~= toggleKeyCode then
                        local keyState = Ham.getKeyState(keyCode)
                        if keyState ~= 0 then
                            if not keybindPopupElem.LastKeyStates then
                                keybindPopupElem.LastKeyStates = {}
                            end
                            if not keybindPopupElem.LastKeyStates[keyCode] then
                                keybindPopupElem.PendingKey = keyCode
                                keybindPopupElem.LastKeyStates[keyCode] = true
                                break
                            end
                        else
                            if keybindPopupElem.LastKeyStates then
                                keybindPopupElem.LastKeyStates[keyCode] = nil
                            end
                        end
                    end
                end
                
                local enterKey = Ham.getKeyState(13)
                if enterKey ~= 0 and keybindPopupElem.PendingKey then
                    if not keybindPopupElem.LastEnterState then
                        if keybindPopupElem.PendingKey ~= toggleKeyCode then
                            keybindPopupElem.Keybind = keybindPopupElem.PendingKey
                            keybindPopupElem.WaitingForKey = false
                            keybindPopupElem.KeybindPopupOpen = false
                            keybindPopupElem.PendingKey = nil
                            keybindPopupElem.LastKeybindState = false
                            keybindPopupElem.LastEnterState = true
                        end
                    end
                else
                    keybindPopupElem.LastEnterState = false
                end
            end
            
            local closeY = popupY + popupH - 35 * self.menuDpi
            local closeW = 80 * self.menuDpi
            local closeH = 25 * self.menuDpi
            local closeX = popupX + popupW / 2 - closeW / 2
            local closeHovered = self:IsHovering(closeX, closeY, closeW, closeH)
            
            if closeHovered then
                Ham.drawRectFilled({x = closeX, y = closeY, w = closeW, h = closeH}, self.Colors.Hover, 5 * self.menuDpi, 15)
            else
                Ham.drawRectFilled({x = closeX, y = closeY, w = closeW, h = closeH}, {48, 50, 58, 200}, 5 * self.menuDpi, 15)
            end
            Ham.drawRect({x = closeX, y = closeY}, {x = closeX + closeW, y = closeY + closeH}, self.Colors.Border, 5 * self.menuDpi, 0, 1)
            Ham.drawText("Close", {x = closeX + closeW / 2, y = closeY + 5 * self.menuDpi}, self.Colors.Text, 13 * self.menuDpi, true, false, {0,0,0,255})
            
            if closeHovered and self.Input.MouseClicked then
                keybindPopupElem.KeybindPopupOpen = false
                keybindPopupElem.WaitingForKey = false
            end
        end
        
        if not self.Notifications then
            self.Notifications = {}
        end
        
        if #self.Notifications > 0 then
            local currentTime = Citizen.GetGameTimer and Citizen.GetGameTimer() or 0
            local notifW = 320 * self.menuDpi
            local notifY = 30
            local notifSpacing = 60
            local maxNotifications = 5
            
            for i = #self.Notifications, 1, -1 do
                local notif = self.Notifications[i]
                if not notif or not notif.Time or not notif.LifeTime then
                    table.remove(self.Notifications, i)
                else
                    local elapsed = currentTime - notif.Time
                    
                    if elapsed > notif.LifeTime then
                        table.remove(self.Notifications, i)
                    elseif i <= maxNotifications then
                        local progress = elapsed / notif.LifeTime
                        local fadeIn = math.min(progress * 5, 1.0)
                        local fadeOut = math.max(0, 1.0 - (progress - 0.7) / 0.3)
                        local alpha = math.min(fadeIn, fadeOut) * 255
                        
                        local slideProgress = math.min(progress * 8, 1.0)
                        local slideOffset = (1.0 - slideProgress) * 60
                        
                        local notifPosX = (screenWidth / 2 - notifW / 2)
                        local visibleIndex = #self.Notifications - i + 1
                        local notifPosY = (notifY + (visibleIndex - 1) * notifSpacing) * self.menuDpi - slideOffset * self.menuDpi
                        
                        if self.customFont then
                            Ham.setFont(self.customFont)
                        end
                        local messageText = notif.Message or ""
                        local textWidth, textHeight = Ham.getTextWidth(messageText)
                        local maxTextWidth = notifW - 50 * self.menuDpi
                        local fontSize = 12 * self.menuDpi
                        
                        local notifH = 45 * self.menuDpi
                        if textWidth > maxTextWidth then
                            local lines = {}
                            local words = {}
                            for word in messageText:gmatch("%S+") do
                                table.insert(words, word)
                            end
                            local currentLine = ""
                            for _, word in ipairs(words) do
                                local testLine = currentLine == "" and word or currentLine .. " " .. word
                                local testWidth, _ = Ham.getTextWidth(testLine)
                                if testWidth > maxTextWidth and currentLine ~= "" then
                                    table.insert(lines, currentLine)
                                    currentLine = word
                                else
                                    currentLine = testLine
                                end
                            end
                            if currentLine ~= "" then
                                table.insert(lines, currentLine)
                            end
                            notifH = math.max(notifH, (#lines * (textHeight + 3)) + 20 * self.menuDpi)
                        end
                        
                        local notifBgColor = {self.Colors.Element[1], self.Colors.Element[2], self.Colors.Element[3], math.floor(alpha * 0.98)}
                        local notifBorderColor = {self.Colors.Border[1], self.Colors.Border[2], self.Colors.Border[3], math.floor(alpha)}
                        local accentColor = notif.IsError and {255, 80, 80, math.floor(alpha)} or {self.Colors.Accent[1], self.Colors.Accent[2], self.Colors.Accent[3], math.floor(alpha)}
                        local accentGlowColor = notif.IsError and {255, 80, 80, math.floor(alpha * 0.4)} or {self.Colors.AccentGlow[1], self.Colors.AccentGlow[2], self.Colors.AccentGlow[3], math.floor(alpha * 0.5)}
                        local textColor = {self.Colors.Text[1], self.Colors.Text[2], self.Colors.Text[3], math.floor(alpha)}
                        
                        Ham.drawRectFilled({x = notifPosX, y = notifPosY, w = notifW, h = notifH}, notifBgColor, 8 * self.menuDpi, 15)
                        Ham.drawRectFilled({x = notifPosX + 8 * self.menuDpi, y = notifPosY + 8 * self.menuDpi, w = 3 * self.menuDpi, h = notifH - 16 * self.menuDpi}, accentColor, 2 * self.menuDpi, 15)
                        Ham.drawRectFilled({x = notifPosX + 8 * self.menuDpi, y = notifPosY + 8 * self.menuDpi, w = 3 * self.menuDpi, h = notifH - 16 * self.menuDpi}, accentGlowColor, 2 * self.menuDpi, 15)
                        Ham.drawRect({x = notifPosX, y = notifPosY}, {x = notifPosX + notifW, y = notifPosY + notifH}, notifBorderColor, 8 * self.menuDpi, 0, 1)
                        
                        if textWidth > maxTextWidth then
                            local lines = {}
                            local words = {}
                            for word in messageText:gmatch("%S+") do
                                table.insert(words, word)
                            end
                            local currentLine = ""
                            for _, word in ipairs(words) do
                                local testLine = currentLine == "" and word or currentLine .. " " .. word
                                local testWidth, _ = Ham.getTextWidth(testLine)
                                if testWidth > maxTextWidth and currentLine ~= "" then
                                    table.insert(lines, currentLine)
                                    currentLine = word
                                else
                                    currentLine = testLine
                                end
                            end
                            if currentLine ~= "" then
                                table.insert(lines, currentLine)
                            end
                            
                            local textY = notifPosY + 14 * self.menuDpi
                            for _, line in ipairs(lines) do
                                Ham.drawText(line, {x = notifPosX + 20 * self.menuDpi, y = textY}, textColor, fontSize, false, false, {0,0,0,255})
                                textY = textY + textHeight + 3 * self.menuDpi
                            end
                        else
                            Ham.drawText(messageText, {x = notifPosX + 20 * self.menuDpi, y = notifPosY + 16 * self.menuDpi}, textColor, fontSize, false, false, {0,0,0,255})
                        end
                        if self.customFont then
                            Ham.resetFont()
                        end
                    end
                end
            end
        end
        
        if self.customFont then
            Ham.resetFont()
        end
    else
        if self.customFont then
            Ham.resetFont()
        end
        self.LastRightClickState = false
        self.SearchBarClickConsumed = false
    end
end

function VialLibrary:Start()
    if self.UIThread then
        return
    end
    if self.Open and Ham and Ham.toggleMouse then
        Ham.toggleMouse()
    end
    self.UIThread = Citizen.CreateThread(function()
        while not self.Unload do
            self:Update()
            Citizen.Wait(0)
        end
        if self.Open then
            self.Open = false
            if Ham and Ham.toggleMouse then
                Ham.toggleMouse()
            end
        end
        if self.Windows then
            for _, window in ipairs(self.Windows) do
                if window then
                    if window.Tabs then
                        for _, tab in ipairs(window.Tabs) do
                            if tab and tab.SubTabs then
                                for _, subTab in ipairs(tab.SubTabs) do
                                    if subTab and subTab.Sections then
                                        subTab.Sections.Left = {}
                                        subTab.Sections.Middle = {}
                                        subTab.Sections.Right = {}
                                    end
                                end
                                tab.SubTabs = {}
                            end
                        end
                    end
                    window.Tabs = {}
                    window.ActiveTab = nil
                    window.Dragging = false
                    window.DragOffset = {X = 0, Y = 0}
                end
            end
            self.Windows = {}
        end
        if self.Notifications then
            self.Notifications = {}
        end
        if self.Labels then
            self.Labels = {}
        end
        self.Input = {MX = 0, MY = 0, MouseDown = false, MouseClicked = false, MouseRightClicked = false}
        self.FooterSearchText = ""
        self.FooterSearchFocused = false
        self.FooterSearchKeyStates = {}
        self.SearchBarClickConsumed = false
        self.LastRightClickState = false
        self.LastToggleKeyState = false
        if self.gearIconTexture then
            self.gearIconTexture = nil
        end
        if self.paletteIconTexture then
            self.paletteIconTexture = nil
        end
        if self.customFont then
            self.customFont = nil
        end
        self.UIThread = nil
        if _G.VialLibrary_Instance == self then
            _G.VialLibrary_Instance = nil
        end
    end)
end

if not _G.VialLibrary then
    _G.VialLibrary = VialLibrary
end

return VialLibrary
