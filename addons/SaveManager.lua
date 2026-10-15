local HttpService = game:GetService("HttpService")

local SaveManager = {
    Folder = "VortexUI",
    Ignore = {},
}

local function validName(name)
    return type(name) == "string" and #name > 0 and #name <= 64 and name:match("^[%w_%-]+$") ~= nil
end

local function protect(callback)
    local ok, value = pcall(callback)
    if not ok then
        return false, tostring(value)
    end
    return true, value
end

function SaveManager:SetLibrary(library)
    self.Library = library
    return self
end

function SaveManager:SetFolder(folder)
    assert(
        type(folder) == "string" and folder ~= "" and not folder:find("[^%w_/%-]"),
        "Folder may contain letters, numbers, underscores, hyphens, and slashes"
    )
    assert(
        folder:sub(1, 1) ~= "/" and folder:sub(-1) ~= "/" and not folder:find("//", 1, true),
        "Folder must be a relative path"
    )
    self.Folder = folder
    return self
end

function SaveManager:SetStorage(storage)
    assert(type(storage) == "table", "Storage must be a table")
    self.Storage = storage
    return self
end

function SaveManager:_storage()
    local storage = self.Storage
        or {
            readfile = readfile,
            writefile = writefile,
            isfile = isfile,
            makefolder = makefolder,
            isfolder = isfolder,
            listfiles = listfiles,
            delfile = delfile,
        }
    assert(
        type(storage.readfile) == "function"
            and type(storage.writefile) == "function"
            and type(storage.isfile) == "function",
        "File storage unavailable; use SetStorage with a storage adapter"
    )
    return storage
end

function SaveManager:_prepare(storage)
    if type(storage.makefolder) ~= "function" then
        return
    end
    local current = ""
    for part in (self.Folder .. "/settings"):gmatch("[^/]+") do
        current = current == "" and part or current .. "/" .. part
        if type(storage.isfolder) ~= "function" or not storage.isfolder(current) then
            local ok, err = pcall(storage.makefolder, current)
            if not ok and (type(storage.isfolder) ~= "function" or not storage.isfolder(current)) then
                error(err)
            end
        end
    end
end

function SaveManager:SetIgnoreIndexes(indexes)
    for _, index in ipairs(indexes) do
        self.Ignore[index] = true
    end
    return self
end

function SaveManager:IgnoreThemeSettings()
    return self:SetIgnoreIndexes({ "VortexTheme", "VortexAccent" })
end

function SaveManager:Save(name)
    return protect(function()
        assert(self.Library and not self.Library.Unloaded, "Set an active Library before saving")
        assert(validName(name), "Config names may contain letters, numbers, underscores, and hyphens")
        local storage = self:_storage()
        self:_prepare(storage)
        local data = { Version = 1, Objects = {} }
        local function collect(options)
            for id, option in pairs(options) do
                if not self.Ignore[id] then
                    local entry = { Type = option.Type, Value = option.Value }
                    if option.Type == "ColorPicker" then
                        entry.Value = option.Value:ToHex()
                        entry.Transparency = option.Transparency
                    elseif option.Type == "KeyPicker" then
                        entry.Value = { option.Value, option.Mode }
                    end
                    data.Objects[id] = entry
                end
            end
        end
        collect(self.Library.Toggles)
        collect(self.Library.Options)
        storage.writefile(self.Folder .. "/settings/" .. name .. ".json", HttpService:JSONEncode(data))
    end)
end

function SaveManager:Load(name)
    return protect(function()
        assert(self.Library and not self.Library.Unloaded, "Set an active Library before loading")
        assert(validName(name), "Invalid config name")
        local storage = self:_storage()
        local path = self.Folder .. "/settings/" .. name .. ".json"
        assert(storage.isfile(path), "Config does not exist: " .. name)
        local data = HttpService:JSONDecode(storage.readfile(path))
        assert(
            type(data) == "table" and data.Version == 1 and type(data.Objects) == "table",
            "Unsupported config format"
        )
        local pending = {}
        for id, entry in pairs(data.Objects) do
            local option = self.Library.Toggles[id] or self.Library.Options[id]
            if option and not self.Ignore[id] then
                assert(type(entry) == "table" and entry.Type == option.Type, "Control type mismatch: " .. id)
                local value = entry.Value
                if option.Type == "ColorPicker" then
                    assert(type(value) == "string" and value:match("^%x%x%x%x%x%x$"), "Invalid color: " .. id)
                    value = Color3.fromHex(value)
                    local alpha = entry.Transparency
                    assert(
                        type(alpha) == "number" and alpha == alpha and alpha >= 0 and alpha <= 1,
                        "Invalid transparency: " .. id
                    )
                end
                assert(option:Validate(value), "Invalid value for control: " .. id)
                table.insert(pending, { Option = option, Value = value, Transparency = entry.Transparency })
            end
        end
        table.sort(pending, function(a, b)
            if a.Option.Id == "VortexTheme" then
                return b.Option.Id ~= "VortexTheme"
            end
            if b.Option.Id == "VortexTheme" then
                return false
            end
            return a.Option.Id < b.Option.Id
        end)
        for _, item in ipairs(pending) do
            if item.Option.Type == "ColorPicker" then
                item.Option:SetValueRGB(item.Value, item.Transparency)
            else
                item.Option:SetValue(item.Value)
            end
        end
    end)
end

function SaveManager:Delete(name)
    return protect(function()
        assert(validName(name), "Invalid config name")
        local storage = self:_storage()
        assert(type(storage.delfile) == "function", "Deleting files is unavailable")
        local path = self.Folder .. "/settings/" .. name .. ".json"
        assert(storage.isfile(path), "Config does not exist: " .. name)
        storage.delfile(path)
        local autoloadPath = self.Folder .. "/autoload.txt"
        if storage.isfile(autoloadPath) and storage.readfile(autoloadPath) == name then
            storage.delfile(autoloadPath)
        end
    end)
end

function SaveManager:RefreshConfigList()
    return protect(function()
        local storage = self:_storage()
        self:_prepare(storage)
        assert(type(storage.listfiles) == "function", "Listing files is unavailable")
        local names = {}
        for _, path in ipairs(storage.listfiles(self.Folder .. "/settings")) do
            local name = path:gsub("\\", "/"):match("([^/]+)%.json$")
            if validName(name) then
                table.insert(names, name)
            end
        end
        table.sort(names)
        return names
    end)
end

function SaveManager:SetAutoloadConfig(name)
    return protect(function()
        assert(validName(name), "Invalid config name")
        local storage = self:_storage()
        assert(
            storage.isfile(self.Folder .. "/settings/" .. name .. ".json"),
            "Save the config before setting autoload"
        )
        self:_prepare(storage)
        storage.writefile(self.Folder .. "/autoload.txt", name)
    end)
end

function SaveManager:ClearAutoloadConfig()
    return protect(function()
        local storage = self:_storage()
        local path = self.Folder .. "/autoload.txt"
        assert(type(storage.delfile) == "function", "Deleting files is unavailable")
        if storage.isfile(path) then
            storage.delfile(path)
        end
    end)
end

function SaveManager:LoadAutoloadConfig()
    local ok, name = protect(function()
        local storage = self:_storage()
        local path = self.Folder .. "/autoload.txt"
        if not storage.isfile(path) then
            return nil
        end
        return storage.readfile(path)
    end)
    if not ok then
        return false, name
    end
    if not name then
        return true
    end
    return self:Load(name)
end

function SaveManager:BuildConfigSection(tab)
    assert(self.Library, "Call SetLibrary first")
    local group = tab:AddGroupbox("Configuration")
    local library = self.Library
    local name = group:AddInput("VortexConfigName", { Text = "Config name", Placeholder = "default" })
    local ok, names = self:RefreshConfigList()
    local selected = group:AddDropdown(
        "VortexConfigList",
        { Text = "Saved configs", Values = ok and names or {}, Searchable = true }
    )
    self:SetIgnoreIndexes({ "VortexConfigName", "VortexConfigList" })
    local function report(success, err)
        library:Notify(success and "Configuration updated" or tostring(err))
    end
    local function refresh()
        local success, result = self:RefreshConfigList()
        if success then
            selected:SetValues(result)
        else
            library:Notify(result)
        end
    end
    group:AddButton("Save", function()
        report(self:Save(name.Value ~= "" and name.Value or selected.Value))
        refresh()
    end)
    group:AddButton("Load", function()
        report(self:Load(selected.Value))
    end)
    group:AddButton("Delete", function()
        report(self:Delete(selected.Value))
        refresh()
    end)
    group:AddButton("Refresh", refresh)
    group:AddButton("Set autoload", function()
        report(self:SetAutoloadConfig(selected.Value))
    end)
    group:AddButton("Clear autoload", function()
        report(self:ClearAutoloadConfig())
    end)
    return group
end

return SaveManager
