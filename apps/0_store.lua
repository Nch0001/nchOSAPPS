local ui = _G.nchOS.require("ui")
local storemanager = _G.nchOS.require("storemanager")

local app = {}

app.name = "NchStore"
app.icon = "ST"
app.iconColor = colors.blue
app.iconBorderColor = colors.cyan
app.version = "2.0.0"

local STORE_URL =
"https://raw.githubusercontent.com/nch0001/nchOSAPPS/main/index.json"

local function lower(text)
    return tostring(text or ""):lower()
end

local function safe(text, fallback)
    text = tostring(text or fallback or "")
    if text == "" then
        return tostring(fallback or "")
    end
    return text
end

local function clearLabel(label, width)
    label:setText(string.rep(" ", width or 30))
end

local function setLabel(label, text, width)
    text = tostring(text or "")
    width = width or 30

    if #text > width then
        text = text:sub(1, math.max(1, width - 3)) .. "..."
    end

    label:setText(text .. string.rep(" ", math.max(0, width - #text)))
end

local function matchesSearch(info, query)
    query = lower(query)

    if query == "" then
        return true
    end

    local blob = table.concat({
        lower(info.id),
        lower(info.name),
        lower(info.author),
        lower(info.description),
        lower(info.category),
        lower(info.version)
    }, " ")

    return blob:find(query, 1, true) ~= nil
end

local function makeListText(info)
    local status = storemanager.getStatus(info)
    local marker = "[+]"

    if status == "installed" then
        marker = "[Installed]"
    elseif status == "update" then
        marker = "[Update]"
    end

    return marker .. " " .. safe(info.name, info.id) .. "  v" .. tostring(info.version or "?")
end

local function refreshButtons(actionButton, uninstallButton, appInfo)
    if not appInfo then
        actionButton:setText("Install")
        actionButton:setBackground(colors.gray)
        actionButton.disabled = true

        uninstallButton:setText("Uninstall")
        uninstallButton:setBackground(colors.gray)
        uninstallButton.disabled = true
        return
    end

    local status = storemanager.getStatus(appInfo)

    if status == "available" then
        actionButton:setText("Install")
        actionButton:setBackground(colors.green)
        actionButton.disabled = false

        uninstallButton:setText("Uninstall")
        uninstallButton:setBackground(colors.gray)
        uninstallButton.disabled = true

    elseif status == "update" then
        actionButton:setText("Update")
        actionButton:setBackground(colors.orange)
        actionButton.disabled = false

        uninstallButton:setText("Uninstall")
        uninstallButton:setBackground(colors.red)
        uninstallButton.disabled = false

    else
        actionButton:setText("Reinstall")
        actionButton:setBackground(colors.gray)
        actionButton.disabled = false

        uninstallButton:setText("Uninstall")
        uninstallButton:setBackground(colors.red)
        uninstallButton.disabled = false
    end
end

app.run = function()
    local w, h = term.getSize()

    local root = ui.createStandardOverlay()
    local page = root:createPage()
        :setPosition(1, 4)
        :setSize(w, h - 4)
        :setBackground(colors.black)
        :setForeground(colors.white)
        :setClipChildren(true)

    local contentWidth = math.max(20, w - 4)
    local listHeight = math.max(4, h - 13)
    local detailX = math.max(2, math.floor(w / 2) + 2)
    local listWidth = math.max(18, detailX - 4)
    local detailWidth = math.max(18, w - detailX - 1)

    page:createLabel()
        :setText("NchStore")
        :setForeground(colors.cyan)
        :setPosition(2, 1)

    local status = page:createLabel()
        :setText("Loading store...")
        :setForeground(colors.lightGray)
        :setPosition(2, 3)

    local search = page:createInput()
        :setPlaceholder("Search")
        :setPosition(2, 5)
        :setSize(math.min(20, contentWidth), 1)
        :setBackground(colors.gray)
        :setForeground(colors.white)

    local refreshButton = page:createButton()
        :setText("Refresh")
        :setBackground(colors.blue)
        :setForeground(colors.white)
        :setPosition(23, 5)

    local list = page:createList()
        :setPosition(2, 7)
        :setSize(listWidth, listHeight)
        :setBackground(colors.gray)
        :setForeground(colors.white)

    page:createLabel()
        :setText("Details")
        :setForeground(colors.cyan)
        :setPosition(detailX + 7, 5)

    local nameLabel = page:createLabel()
        :setText("")
        :setForeground(colors.white)
        :setPosition(detailX, 7)

    local versionLabel = page:createLabel()
        :setText("")
        :setForeground(colors.lightGray)
        :setPosition(detailX, 8)

    local authorLabel = page:createLabel()
        :setText("")
        :setForeground(colors.lightGray)
        :setPosition(detailX, 9)

    local categoryLabel = page:createLabel()
        :setText("")
        :setForeground(colors.lightGray)
        :setPosition(detailX, 10)

    local installedLabel = page:createLabel()
        :setText("")
        :setForeground(colors.yellow)
        :setPosition(detailX, 11)

    local descLabel = page:createLabel()
        :setText("")
        :setForeground(colors.white)
        :setPosition(detailX, 13)

    local actionButton = page:createButton()
        :setText("Install")
        :setBackground(colors.gray)
        :setForeground(colors.white)
        :setPosition(2, h - 5)
        :setZIndex(10)

    actionButton.disabled = true

    local uninstallButton = page:createButton()
        :setText("Uninstall")
        :setBackground(colors.gray)
        :setForeground(colors.white)
        :setPosition(16, h - 5)
        :setZIndex(10)

    uninstallButton.disabled = true

    local apps = {}
    local visibleApps = {}

    local function getSelectedApp()
        local index = list.selectedIndex
        return index and visibleApps[index] or nil
    end

    local function refreshDetails()
        local info = getSelectedApp()

        if not info then
            clearLabel(nameLabel, detailWidth)
            clearLabel(versionLabel, detailWidth)
            clearLabel(authorLabel, detailWidth)
            clearLabel(categoryLabel, detailWidth)
            clearLabel(installedLabel, detailWidth)
            clearLabel(descLabel, detailWidth)
            refreshButtons(actionButton, uninstallButton, nil)
            return
        end

        local statusName = storemanager.getStatus(info)
        local installedVersion = storemanager.getInstalledVersion(info)

        setLabel(nameLabel, safe(info.name, info.id), detailWidth)
        setLabel(versionLabel, "Remote: v" .. tostring(info.version or "?"), detailWidth)
        setLabel(authorLabel, "Author: " .. safe(info.author, "Unknown"), detailWidth)
        setLabel(categoryLabel, "Category: " .. safe(info.category, "None"), detailWidth)

        if statusName == "available" then
            setLabel(installedLabel, "Status: Not installed", detailWidth)
        elseif statusName == "update" then
            setLabel(installedLabel, "Status: Update " .. tostring(installedVersion or "?") .. " -> " .. tostring(info.version or "?"), detailWidth)
        else
            setLabel(installedLabel, "Status: Installed v" .. tostring(installedVersion or "?"), detailWidth)
        end

        setLabel(descLabel, safe(info.description, "No description"), detailWidth)

        refreshButtons(actionButton, uninstallButton, info)
    end

    local function rebuildList()
        visibleApps = {}
        list:clearList()

        local query = search:getText() or ""

        for _, info in ipairs(apps) do
            if matchesSearch(info, query) then
                table.insert(visibleApps, info)
                list:addItem(makeListText(info))
            end
        end

        if #visibleApps == 0 then
            status:setText("No apps found")
        else
            status:setText("Showing " .. #visibleApps .. " of " .. #apps .. " apps")
        end

        refreshDetails()
    end

    local function fetchStore()
        status:setText("Loading store...")

        local ok, result = storemanager.fetchIndex(STORE_URL)

        if not ok then
            apps = {}
            visibleApps = {}
            list:clearList()
            status:setText("Store failed: " .. tostring(result))
            refreshDetails()
            return
        end

        apps = result
        status:setText("Loaded " .. #apps .. " apps")
        rebuildList()
    end

    list:onSelect(function()
        refreshDetails()
    end)

    search:onChange(function()
        rebuildList()
    end)

    refreshButton:onClick(function()
        fetchStore()
    end)

    actionButton:onClick(function()
        local info = getSelectedApp()

        if not info then
            status:setText("Select an app first")
            return
        end

        local mode = storemanager.getStatus(info)
        local ok, result

        if mode == "available" then
            status:setText("Installing " .. safe(info.name, info.id) .. "...")
            ok, result = storemanager.install(info)

        elseif mode == "update" then
            status:setText("Updating " .. safe(info.name, info.id) .. "...")
            ok, result = storemanager.update(info)

        else
            status:setText("Reinstalling " .. safe(info.name, info.id) .. "...")
            ok, result = storemanager.reinstall(info)
        end

        if ok then
            status:setText("Done: " .. safe(info.name, info.id))
        else
            status:setText("Failed: " .. tostring(result))
        end

        rebuildList()
    end)

    uninstallButton:onClick(function()
        local info = getSelectedApp()

        if not info then
            status:setText("Select an app first")
            return
        end

        status:setText("Uninstalling " .. safe(info.name, info.id) .. "...")

        local ok, result = storemanager.uninstall(info)

        if ok then
            status:setText("Uninstalled " .. safe(info.name, info.id))
        else
            status:setText("Uninstall failed: " .. tostring(result))
        end

        rebuildList()
    end)

    fetchStore()

    ui.run()
end

return app