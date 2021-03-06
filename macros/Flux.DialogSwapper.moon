export script_name        = 'Dialog Swapper'
export script_description = 'Perform text swapping operations on a script'
export script_author      = 'CoffeeFlux'
export script_version     = '1.4.0'
export script_namespace   = 'Flux.DialogSwapper'

DependencyControl = require('l0.DependencyControl') {
    url: 'https://github.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/blob/master/macros/Flux.DialogSwapper.moon'
    feed: 'https://raw.githubusercontent.com/TypesettingTools/CoffeeFlux-Aegisub-Scripts/master/DependencyControl.json'
    {
        {'l0.Functional', version: '0.3.0', url: 'https://github.com/TypesettingTools/ASSFoundation',
         feed: 'https://raw.githubusercontent.com/TypesettingTools/Functional/master/DependencyControl.json'}
    }
}

Functional = DependencyControl\requireModules!
import list, math, string, table, unicode, util, re from Functional

ConfigHandler = DependencyControl\getConfigHandler {
    settings: {
        delimeter: "*"
        verifyStyle: true
        lineStarters: "-,_"
        lineNames: "Main,Alt,Overlap"
    }
}
settings = ConfigHandler.c.settings

dialog = {
    {
        class: "label"
        label: "Delimeter:"
        x: 0
        y: 0
    }
    {
        class: "edit"
        name: "delimeter"
        text: settings.delimeter
        x: 2
        y: 0
    }
    {
        class: "label"
        label: "Verify Style:"
        x: 0
        y: 1
    }
    {
        class: "checkbox"
        name: "verifyStyle"
        value: settings.verifyStyle
        x: 2
        y: 1
    }
    {
        class: "label"
        label: "Line Name Starters:"
        x: 0
        y: 2
    }
    {
        class: "edit"
        name: "lineStarters"
        text: settings.lineStarters
        x: 2
        y: 2
    }
    {
        class: "label"
        label: "Line Names:"
        x: 0
        y: 3
    }
    {
        class: "edit"
        name: "lineNames"
        text: settings.lineNames
        x: 2
        y: 3
    }
}

-- BELOW VARIABLES ARE HARD-CODED TO DEFAULT VALUES, AND THUS ARE REPLACED BEFORE REGISTRATION
delimeter = "%*"
-- These are roundabout and initially confusing, but it's necessary to avoid unswapping
swapPatterns = {
    -- Convert "{*}foo{*bar}" to "{*}bar{*foo}", including {*}foo{*} to {*}{*foo}
    {
        "{%*}([^{]-){%*([^}]*)}",
        "{%*}%2{%*%1}"
    }
    -- Convert "{**bar}" to "{*}bar{*}"
    {
        "{%*%*([^}]+)}",
        "{%*}%1{%*}"
    }
    -- Convert "{*}{*bar}" to "{**bar}"
    {
        "{%*}{%*",
        "{%*%*"
    }
}
validLineStarters = "%-%_"
validLineNames = {'Main', 'Alt', 'Overlap'}
-- Toggle line comment status if effect field matches three times the delimiter
commentPattern = "^%*%*%*$"
verifyStyle = true

escapeChars = (chars) ->
    return string.gsub chars, ".", "%%%1"

validateLine = (style) ->
    if not verifyStyle
        return true
    for name in ipairs validLineNames
        if style\match "[" .. validLineStarters .. "]" .. name
            return true
    return false

updateDialog = ->
    dialog[2].text  = settings.delimeter
    dialog[4].value = settings.verifyStyle
    dialog[6].text  = settings.lineStarters
    dialog[8].text  = settings.lineNames

updateVars = ->
    delimeter = escapeChars settings.delimeter
    -- These are roundabout and initially confusing, but it's necessary to avoid unswapping
    swapPatterns = {
        -- Convert "{*}foo{*bar}" to "{*}bar{*foo}", including {*}foo{*} to {*}{*foo}
        {
            "{" .. delimeter .. "}([^{]-){" .. delimeter .."([^}]*)}",
            "{" .. delimeter .. "}%2{" .. delimeter .. "%1}"
        }
        -- Convert "{**bar}" to "{*}bar{*}"
        {
            "{" .. delimeter .. delimeter .. "([^}]+)}",
            "{" .. delimeter .. "}%1{" .. delimeter .. "}"
        }
        -- Convert "{*}{*bar}" to "{**bar}"
        {
            "{" .. delimeter .. "}{".. delimeter,
            "{" .. delimeter .. delimeter
        }
    }
    validLineStarters = escapeChars string.gsub(settings.lineStarters, ",", "")
    validLineNames = string.split settings.lineNames, ","
    -- Toggle line comment status if effect field matches three times the delimiter
    commentPattern = "^" .. delimeter .. delimeter .. delimeter .. "$"
    verifyStyle = settings.verifyStyle

replace = (subs) ->
    for lineNumber = 1, #subs
        line = subs[lineNumber]

        if line.class == "dialogue"
            style = line.style
            effect = line.effect
            
            if effect\match commentPattern
                line.comment = not line.comment

            if validateLine style
                for pair in ipairs swapPatterns
                    line.text = line.text\gsub pair[1], pair[2]
            subs[lineNumber] = line

swap = (subs, selected, active) ->
    replace subs

config = ->
    button, results = aegisub.dialog.display dialog
    if button
        settings.delimeter    = results.delimeter
        settings.verifyStyle  = results.verifyStyle
        settings.lineStarters = results.lineStarters
        settings.lineNames    = results.lineNames
        ConfigHandler\write!
        updateDialog!
        updateVars!

updateVars!

DependencyControl\registerMacros {
    { "Swap Dialog", "Performs the swap operations upon the script", swap }
    { "Configure", "Launches the configuration dialog", config }
}
