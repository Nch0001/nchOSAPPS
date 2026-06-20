local ui = _G.nchOS.require("ui")

local app = {}

app.name = "RStorage"
app.icon = "RS"
app.iconColor = colors.blue
app.iconBorderColor = colors.green

app.run = function()
    local w,h = term.getSize()
    local root, nav, overlay = ui.createStandardOverlay()
    local contentWindow = root:createPage()
        :setScrollable(true)
        :setClipChildren(true)
        :setBackground(colors.black)
        :setForeground(colors.white)
        :setPosition(1,4)
        :setSize(w, h-4)

    local label = contentWindow:createLabel()
        :setText("hi")
        :setPosition(5,8)
        :setForeground(colors.white)

    ui.draw()

    ui.run()

end

return app
