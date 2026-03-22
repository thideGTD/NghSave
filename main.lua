local _wait = task.wait
repeat
    _wait()
until game:IsLoaded()
local Players = game.Players
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RequestHit = ReplicatedStorage:WaitForChild("CombatSystem"):WaitForChild("Remotes"):WaitForChild("RequestHit")
local FirstWait = false

local function TeleportMap(name)
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("TeleportToPortal"):FireServer(name)
end

local function NoClip()
    local character = game.Players.LocalPlayer.Character
    if not character then return end
    local hrp = character:WaitForChild("HumanoidRootPart")
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Part") then
            part.CanCollide = false
        end
    end
    -- Tắt gravity
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.PlatformStand = true
    end
    -- Thêm BodyVelocity để freeze vị trí hoàn toàn
    local bodyVelocity = Instance.new("BodyVelocity", hrp)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    
    -- Thêm BodyGyro để freeze orientation
    local bodyGyro = Instance.new("BodyGyro", hrp)
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.CFrame = hrp.CFrame
end

local Inventory = {
    ["Items"] = {},
    ["Cosmetics"] = {},
    ["Melee"] = {},
    ["Power"] = {},
    ["Accessories"] = {},
    ["Sword"] = {},
    ["Runes"] = {},
    ["Auras"] = {}
}

local function UsingItem()
    local Clankeep = {"Monarch"}
    local Racekeep = {"Oni","Kitsune","Leviathan","Slime","Servant","Sunborn","Galevorn","Swordblessed"}
    local Traitkeep = {"Overload","Cataclysm","Singularity","Celestial","Godspeed","Sovereign","Infinity","Malevolent"}
    local Clan, Race, Trait
    local remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
    local useItem = remotes:WaitForChild("UseItem")
    for _, Value in game:GetService("ReplicatedStorage").RemoteEvents.GetPlayerStats:InvokeServer().Inventory do
        Race = Value.Race
    end
    for _,value in game:GetService("ReplicatedStorage").RemoteEvents.TraitGetData:InvokeServer() do
        if _ == "Trait" then
            Trait = value
        end
    end
    if not table.find(Traitkeep, Trait) or not table.find(Racekeep, Race) then
        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("UseItem"):FireServer("Use","Mythical Chest",100,true)
    end
    task.wait(1)
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("UseItem"):FireServer("Use","Legendary Chest",100,true)
    task.wait(1)
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("UseItem"):FireServer("Use","Epic Chest",100,true)
    task.wait(1)
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("UseItem"):FireServer("Use","Rare Chest",100,true)
    task.wait(1)
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("UseItem"):FireServer("Use","Common Chest",100,true)
    task.wait(1)
    local args = {
        "EquipStats",
        "Aizen Haori"
    }
    game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("EquipAccessory"):FireServer(unpack(args))
end
local function UpdateInventory()
    if not FirstWait then
        game:GetService("ReplicatedStorage").Remotes.UpdateInventory.OnClientEvent:Connect(function(arg1, arg2)
            Inventory[arg1] = arg2
        end)
        FirstWait = true
    end
    pcall(function()
        game:GetService("ReplicatedStorage").Remotes.RequestInventory:FireServer()
    end)
end
local function UpdateAtrfacts(id, amount)
    local args = {
        id,
        amount
    }
    game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("ArtifactUpgrade"):FireServer(unpack(args))
end
local function DeleteArtifacts(ids)
    if #ids > 0 then
        local args = {ids}
        game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("ArtifactMassDeleteByUUIDs"):FireServer(unpack(args))
    end
end
local function Artifacts()
    game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("ArtifactUnlockSystem"):FireServer()
    task.wait(1)
    local artifacts = game:GetService("ReplicatedStorage").RemoteFunctions.GetArtifactData:InvokeServer().Inventory
    local categoryArtifacts = {}
    local allIDs = {}
    for id, Value in pairs(artifacts) do
        local cat = Value.Category
        if not categoryArtifacts[cat] then
            categoryArtifacts[cat] = {}
        end
        table.insert(categoryArtifacts[cat], {id = id, Set = Value.Set, Rarity = Value.Rarity, Level = Value.Level or 0})
        table.insert(allIDs, id)
    end
    local rarityOrder = {Legendary = 4, Epic = 3, Rare = 2, Common = 1}
    local equippedIDs = {}
    for cat, list in pairs(categoryArtifacts) do
        table.sort(list, function(a, b)
            local aSet = (a.Set == "Celestial Rupture") and 1 or 0
            local bSet = (b.Set == "Celestial Rupture") and 1 or 0
            if aSet ~= bSet then
                return aSet > bSet
            end
            local aRar = rarityOrder[a.Rarity] or 0
            local bRar = rarityOrder[b.Rarity] or 0
            if aRar ~= bRar then
                return aRar > bRar
            end
            return (a.Level or 0) > (b.Level or 0)
        end)
        if #list > 0 then
            local best = list[1]
            local args = {tostring(best.id)}
            game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("ArtifactEquip"):FireServer(unpack(args))
            task.wait(1)
            table.insert(equippedIDs, best.id)
            -- Upgrade nếu rarity >= Epic
            if best.Rarity == "Epic" or best.Rarity == "Legendary" and best.Level < 15 then
                UpdateAtrfacts(best.id, 1)
                task.wait(1)
            end
            task.wait(1)
        end
    end
    -- Xóa những artifact không được equip
    local unusedIDs = {}
    for _, id in ipairs(allIDs) do
        if not table.find(equippedIDs, id) then
            table.insert(unusedIDs, id)
        end
    end
    DeleteArtifacts(unusedIDs)
end
local function EquipBestLucky()
    local TitleBest = {"Destiny Marked", "Blessed Sovereign", "The Chosen One", "Blessed One", "Lucky Star", "Fortune Seeker", "Lucky Novice"}
    local titlesData = game:GetService("ReplicatedStorage").Remotes.GetTitlesData:InvokeServer().unlocked
    for _, titleName in ipairs(TitleBest) do
        for i, v in pairs(titlesData) do
            -- print(titleName)
            -- print(i,v)
            if v == titleName then
                -- Equip title
                print(titleName)
                game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("TitleEquip"):FireServer(titleName)
                return -- Equip cái xịn nhất đầu tiên và dừng
            end
        end
    end
end

local function Attack()
    task.wait(0.1)
    local RequestHit = ReplicatedStorage:WaitForChild("CombatSystem"):WaitForChild("Remotes"):WaitForChild("RequestHit")
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
        local humanoid = character.Humanoid
        local Combat = LocalPlayer.Backpack:FindFirstChild("Combat") or character:FindFirstChild("Combat")
        local Sword = LocalPlayer.Backpack:FindFirstChild("Gryphon") or character:FindFirstChild("Gryphon")
        if Sword then
            if Sword.Parent == LocalPlayer.Backpack then
                humanoid:EquipTool(Sword)
            end
            pcall(function()
                game:GetService("ReplicatedStorage"):WaitForChild("AbilitySystem"):WaitForChild("Remotes"):WaitForChild("RequestAbility"):FireServer(2)
                RequestHit:FireServer()
            end)
        elseif Combat then
            if Combat.Parent == LocalPlayer.Backpack then
                humanoid:EquipTool(Combat)
            end
            pcall(function()
                RequestHit:FireServer()
            end)
        end
    end
end
local function BuySword()
    local success, err = pcall(function()
        local Money = tonumber(game:GetService("Players").LocalPlayer.Data.Money.Value)
        local Gem = tonumber(game:GetService("Players").LocalPlayer.Data.Gems.Value)
        local character = LocalPlayer.Character
        if Money > 650000 and Gem > 650 and not LocalPlayer.Backpack:FindFirstChild("Gryphon") and not character:FindFirstChild("Gryphon") then
            local npc = workspace.ServiceNPCs:FindFirstChild("GryphonBuyerNPC")
            if npc then
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    TeleportMap("Shibuya")
                    task.wait(1)
                    character.HumanoidRootPart.CFrame = CFrame.new(npc.WorldPivot.Position) * CFrame.new(0, 0, 5)
                    task.wait(1)
                    local prompt = npc.HumanoidRootPart:FindFirstChild("BuyerPrompt")
                    if prompt and prompt:IsA("ProximityPrompt") then
                        fireproximityprompt(prompt)
                        task.wait(0.5)
                        game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("EquipWeapon"):FireServer("Equip","Gryphon")
                        game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("ResetStats"):FireServer()
                    end
                end
            end
        end
    end)
    if not success then
        warn("BuySword error: " .. err)
    end
end
local function Quest()
    local previousLevel = 0
    while true do
        local success, err = pcall(function()
            local Level = tonumber(game:GetService("Players").LocalPlayer.Data.Level.Value)
            if Level > 5000 then
                if previousLevel < 5000 then
                    game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("QuestAbandon"):FireServer("repeatable")
                    previousLevel = 5000
                    task.wait(1)
                end
                local args = {
                    "QuestNPC13"
                }
                game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("QuestAccept"):FireServer(unpack(args))
            elseif Level > 3000 then
                if previousLevel < 3000 then
                    game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("QuestAbandon"):FireServer("repeatable")
                    previousLevel = 3000
                    task.wait(1)
                end
                local args = {
                    "QuestNPC9"
                }
                game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("QuestAccept"):FireServer(unpack(args))
            elseif Level > 1400 then
                if previousLevel < 1400 then
                    game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("QuestAbandon"):FireServer("repeatable")
                    previousLevel = 1400
                    task.wait(1)
                end
                local args = {
                    "QuestNPC7"
                }
                game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("QuestAccept"):FireServer(unpack(args))
            elseif Level > 700 then
                if previousLevel < 700 then
                    game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("QuestAbandon"):FireServer("repeatable")
                    previousLevel = 700
                    task.wait(1)
                end
                local args = {
                    "QuestNPC5"
                }
                game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("QuestAccept"):FireServer(unpack(args))
            elseif Level > 250 then
                if previousLevel < 250 then
                    game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("QuestAbandon"):FireServer("repeatable")
                    previousLevel = 250
                    task.wait(1)
                end
                local args = {
                    "QuestNPC3"
                }
                game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("QuestAccept"):FireServer(unpack(args))
            elseif Level > 1 then
                local args = {
                    "QuestNPC1"
                }
                game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("QuestAccept"):FireServer(unpack(args))
            end
        end)
        if not success then
            warn("Quest error: " .. err)
        end
        task.wait(2)
    end
end
local function UpgradeStats()
    game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("ResetStats"):FireServer()
    while true do
        local success, err = pcall(function()
            local Level = tonumber(game:GetService("Players").LocalPlayer.Data.Level.Value)
            local Health = tonumber(LocalPlayer.Character.Humanoid.MaxHealth)
            local character = LocalPlayer.Character
            if Level > 3000 and Health < 150000 then
                game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("ResetStats"):FireServer()
                game:GetService("ReplicatedStorage").RemoteEvents.AllocateStat:FireServer("Defense", 3000)
            elseif Level > 1400 and Health < 100000 then
                game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("ResetStats"):FireServer()
                game:GetService("ReplicatedStorage").RemoteEvents.AllocateStat:FireServer("Defense", 2000)
            elseif Level > 500 and Health < 30000 then
                game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("ResetStats"):FireServer()
                game:GetService("ReplicatedStorage").RemoteEvents.AllocateStat:FireServer("Defense", 600)
            elseif LocalPlayer.Backpack:FindFirstChild("Gryphon") or character:FindFirstChild("Gryphon") then
                game:GetService("ReplicatedStorage").RemoteEvents.AllocateStat:FireServer("Sword", 10000)
                if Level > 5000 then
                    game:GetService("ReplicatedStorage").RemoteEvents.AllocateStat:FireServer("Defense", 10000)
                end
            else
                game:GetService("ReplicatedStorage").RemoteEvents.AllocateStat:FireServer("Melee", 10000)
            end
        end)
        if not success then
            -- warn("UpgradeStats error: " .. err)
        end
        task.wait()
    end
end

local function AntiAfk2()
    task.spawn(
        function()
            while true do
                local VirtualUser = game:GetService("VirtualUser")
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
                -- Auto Jump
                local Character = game.Players.LocalPlayer.Character
                -- if Character and Character:FindFirstChild("Humanoid") then
                --     Character.Humanoid.Jump = true
                -- end
                task.wait(1)
            end
        end
    )
end

local function GetQuantity(name)
    UpdateInventory()
    task.wait()
    for i,v in pairs(Inventory.Items) do
        if v.name == name then
            print(tonumber(v.quantity))
            return tonumber(v.quantity)
        end
    end
    return 0
end

local function Settings()
    local Settings = {
        ["DisableVFX"] = true,
        ["DisableCutscene"] = true,
        ["DisableOtherVFX"] = true,
        ["DisableScreenShake"] = true,
        ["RemoveTexture"] = true,
        ["RemoveShadows"] = true,
        ["MuteMusic"] = true,
        ["MuteSFX"] = true,
        ["RemoveShadows"] = true,
        ["HideRaceAccessory"] = true,

        ["DisableAllUI"] = false,
        ["EnableQuestRepeat"] = true,
        ["AutoQuestRepeat"] = true,
        ["EnableAutoRejoin"] = false,

        ["DisablePvP"] = true
    }
    for setting, value in pairs(Settings) do
        local args = {
            setting,
            value
        }
        game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("SettingsToggle"):FireServer(unpack(args))
    end
end

local function GUI()
    -- Chạy đoạn này trong một LocalScript
    local RunService = game:GetService("RunService")
    local ContentProvider = game:GetService("ContentProvider")
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")

    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    -- 1. Tạo ScreenGui với cấu hình ưu tiên cao nhất
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "Nghia892_Override_System"
    screenGui.IgnoreGuiInset = true -- Đè lên cả thanh chat và thanh menu TopBar
    screenGui.DisplayOrder = 2147483647 -- Giá trị cao nhất có thể (Z-index cực đại)
    screenGui.ResetOnSpawn = false -- Không bị mất khi nhân vật chết
    screenGui.Parent = playerGui

    -- 2. Tạo Frame nền đen tuyền
    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    background.BorderSizePixel = 0
    background.Active = true -- Chặn mọi tương tác chuột phía sau
    background.Parent = screenGui

    -- 3. Chữ nghia892 hub
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0.3, 0)
    label.Position = UDim2.new(0, 0, 0.35, 0)
    label.BackgroundTransparency = 1
    label.Text = "make by nghia892"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Font = Enum.Font.RobotoMono -- Font nhìn kiểu "hacker"
    label.Parent = background

    local label2 = Instance.new("TextLabel")
    label2.Size = UDim2.new(1, 0, 0.3, 0)
    label2.Position = UDim2.new(0, 0, 0.5, 0)
    label2.BackgroundTransparency = 1
    label2.Text = "press P"
    label2.TextColor3 = Color3.fromRGB(255, 255, 255)
    label2.TextScaled = true
    label2.Font = Enum.Font.RobotoMono -- Font nhìn kiểu "hacker"
    label2.Parent = background

    -- Biến trạng thái
    local guiVisible = true
    local renderEnabled = false

    -- 4. Kỹ thuật "Force Render": Đè lên cả Disablerender3D
    -- Nếu ai đó dùng lệnh tắt render 3D, GUI này vẫn sẽ được vẽ lại liên tục mỗi khung hình
    RunService.RenderStepped:Connect(function()
        if screenGui.Parent ~= playerGui then
            screenGui.Parent = playerGui
        end
        game:GetService("RunService"):Set3dRenderingEnabled(renderEnabled)
        background.Visible = guiVisible
        background.Transparency = guiVisible and 0 or 1
    end)

    -- Bind key P để toggle
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.P then
            guiVisible = not guiVisible
            renderEnabled = not renderEnabled
        end
    end)

    -- 5. Hiệu ứng chữ đổi màu (RGB) cho "ngầu"
    task.spawn(function()
        local hue = 0
        while true do
            hue = hue + (1/360)
            if hue > 1 then hue = 0 end
            label.TextColor3 = Color3.fromHSV(hue, 1, 1)
            label2.TextColor3 = Color3.fromHSV(hue, 1, 1)
            task.wait()
        end
    end)
end
local function FindPower()
    while true do
        local Clankeep = {"Monarch"}
        local Racekeep = {"Oni","Kitsune","Leviathan","Slime","Servant","Sunborn","Galevorn","Swordblessed"}
        local Traitkeep = {"Overload","Cataclysm","Singularity","Celestial","Godspeed","Sovereign","Infinity","Malevolent"}
        local Clan, Race
        local remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
        local useItem = remotes:WaitForChild("UseItem")
        for _, Value in game:GetService("ReplicatedStorage").RemoteEvents.GetPlayerStats:InvokeServer().Inventory do
            Clan = Value.Clan
            Race = Value.Race
        end
        for _,value in game:GetService("ReplicatedStorage").RemoteEvents.TraitGetData:InvokeServer() do
            if _ == "Trait" then
                if not table.find(Traitkeep, value) or not value and GetQuantity("Trait Reroll") > 0 then
                    game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("TraitConfirm"):FireServer(true)
                    game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("TraitReroll"):FireServer()
                end
            else
                game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("TraitReroll"):FireServer()
            end
        end
        if Clan and not table.find(Clankeep, Clan) and GetQuantity("Clan Reroll") > 0 then
            useItem:FireServer("Use", "Clan Reroll", 1, true)
        end
        task.wait(0.5)
        if Race and not table.find(Racekeep, Race) and GetQuantity("Race Reroll") > 0 then
            useItem:FireServer("Use", "Race Reroll", 1, true)
        end
        task.wait(1)
    end
end
local function KillMob(mob, map)
    local player = game.Players.LocalPlayer
    while mob and mob.Parent and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 do
        Attack()
        local character = player.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Humanoid") or character.Humanoid.Health <= 0 then
            print('---')
            player.CharacterAdded:Wait()
            task.wait(2)
            break
        end
        local rootPart = character.HumanoidRootPart
        local mobRoot = mob:FindFirstChild("HumanoidRootPart")
        if not mobRoot then 
            TeleportMap(map)
            task.wait(1)
            rootPart.CFrame = CFrame.new(mob.WorldPivot.Position) * CFrame.new(0, 9, 0,  -0.853732049, -0.512801707, 0.0904210955, -5.47973311e-09, 0.173648775, 0.98480767, -0.520712554, 0.84076184, -0.148249537)
        end

        local distance = (rootPart.Position - mobRoot.Position).Magnitude
        if distance > 500 then
            pcall(function() 
                TeleportMap(map)
                task.wait(1)
                rootPart.CFrame = CFrame.new(mob.WorldPivot.Position) * CFrame.new(0, 9, 0,  -0.853732049, -0.512801707, 0.0904210955, -5.47973311e-09, 0.173648775, 0.98480767, -0.520712554, 0.84076184, -0.148249537) 
            end)
        end
        pcall(function()
            local Sword = LocalPlayer.Backpack:FindFirstChild("Gryphon") or character:FindFirstChild("Gryphon")
            if Sword then
                -- rootPart.CFrame = PosSafe(map)
                rootPart.CFrame = mobRoot.CFrame * CFrame.new(0, 8.5, 0,  -0.853732049, -0.512801707, 0.0904210955, -5.47973311e-09, 0.173648775, 0.98480767, -0.520712554, 0.84076184, -0.148249537)
                NoClip()
            else
                rootPart.CFrame = mobRoot.CFrame * CFrame.new(0, 7, -3,  -0.853732049, -0.512801707, 0.0904210955, -5.47973311e-09, 0.173648775, 0.98480767, -0.520712554, 0.84076184, -0.148249537)
                NoClip()
            end
        end)
        task.wait()
    end
end

local function KillBoss(mob, map)
    local player = game.Players.LocalPlayer
    
    while mob and mob.Parent and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 do
        Attack()
        task.wait()
        local character = player.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Humanoid") or character.Humanoid.Health <= 0 then
            print('---')
            player.CharacterAdded:Wait()
            task.wait(1)
            break
        end
        local rootPart = character.HumanoidRootPart
        local mobRoot = mob:FindFirstChild("HumanoidRootPart")
        if not mobRoot then TeleportMap(map) break end

        local distance = (rootPart.Position - mobRoot.Position).Magnitude
        if distance > 500 then
            pcall(function() TeleportMap(map) end) 
            task.wait(0.5)
            continue
        end
        pcall(function()
            rootPart.CFrame = mobRoot.CFrame * CFrame.new(0, 0, 6)
            NoClip()
            Attack()
        end)
    end
end
local function Ascenden()
    game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("RequestAscend"):FireServer()
end
local function UpgradeSword()
    while true do
        for i=0,10 do
            local args = {
                "Gryphon"
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("BlessWeapon"):FireServer(unpack(args))
            task.wait(2)
        end
        task.wait(100)
    end
end

local function StatsFarm()
    for i,v in game:GetService("ReplicatedStorage").Remotes.GetStatRerollData:InvokeServer().Stats do
        if i == "Damage" and v.Rank ~= "SSS" then
            local args = {
                "Damage"
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("RerollSingleStat"):InvokeServer(unpack(args))
        elseif i == "CritChance" and v.Rank ~= "SSS" then
            local args = {
                "CritChance"
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("RerollSingleStat"):InvokeServer(unpack(args))
        elseif i == "CritDamage" and v.Rank ~= "SSS" then
            local args = {
                "CritDamage"
            }
            game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("RerollSingleStat"):InvokeServer(unpack(args))
        end
    end
end
local function DetectMob(mobname, map)
    local Mobs = workspace:FindFirstChild("NPCs")
    if not Mobs then return end -- Tránh lỗi nếu folder NPCs chưa load

    local mobNames = type(mobname) == "table" and mobname or {mobname}

    for _, name in ipairs(mobNames) do
        for _, v in pairs(Mobs:GetChildren()) do
            -- Kiểm tra tên và quái còn sống trước khi bắt đầu KillMob
            if string.find(v.Name, name) and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
                KillMob(v, map)
                task.wait()
            end
        end
    end
end
local function SkillTree()
    while true do
        game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("SkillTreeUnlock"):FireServer()
        local Upgrade = {
            "Luck_1", "Luck_2", "Luck_3", "Luck_4", "Luck_5",
            "Damage_1", "Damage_2", "Damage_3", "Damage_4", "Damage_5",
            "CritDmg_1", "CritDmg_2", "CritDmg_3", "CritDmg_4", "CritDmg_5",
            "CritCh_1", "CritCh_2", "CritCh_3", "CritCh_4", "CritCh_5"
        }
        for i,v in pairs(Upgrade) do
            game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvents"):WaitForChild("SkillTreeUpgrade"):FireServer(v)
            task.wait(1)
        end
        task.wait(30)
    end
end

-- Vòng lặp chính

local function Mainrs()
    task.spawn(function()
        while true do
            local success, err = pcall(function()
                local Level = tonumber(game:GetService("Players").LocalPlayer.Data.Level.Value)
                if Level > 6000 then
                    StatsFarm()
                end
                Ascenden()
                UsingItem()
                EquipBestLucky()
                Artifacts()
                task.wait(5)
            end)
            if not success then
                warn("Lỗi vòng lặp: " .. err)
            end
            
            task.wait(1) -- Tránh làm treo game nếu không tìm thấy quái
        end
    end)
    GUI()
    Settings()
    setfpscap(10)
    AntiAfk2()
    task.spawn(FindPower)
    task.spawn(Quest)
    task.spawn(UpgradeStats)
    task.spawn(UpgradeSword)
    while true do
        BuySword()
        NoClip()
        Attack()
        local success, err = pcall(function()
            local Level = tonumber(game:GetService("Players").LocalPlayer.Data.Level.Value)
            if Level > 5000 then
                DetectMob({"Gojo", "Yuji", "Sukuna"}, "Shibuya")
                task.wait()
                DetectMob({"Jinwoo"}, "Sailor")
                task.wait()
                DetectMob({"AizenBoss"}, "HuecoMundo")
                task.wait()
                DetectMob({"StrongSorcerer", "Curse"}, "Shinjuku")
            elseif Level > 3000 then
                DetectMob("Sorcerer", "Shibuya")
            elseif Level > 1400 then
                DetectMob("FrostRogue", "Snow")
            elseif Level > 500 then
                DetectMob("DesertBandit", "Desert")
            elseif Level > 250 then
                DetectMob("Monkey", "Jungle")
            else
                DetectMob("Thief", "Starter")
            end
        end)
        
        if not success then
            warn("Lỗi vòng lặp: " .. err)
        end
        
        task.wait() -- Tránh làm treo game nếu không tìm thấy quái
    end
end
local HttpService = game:GetService("HttpService")
local url = "https://trackerbf.com/checkkey.php"

local headers = {["Content-Type"] = "application/json"}
local body = HttpService:JSONEncode({
    key = keyinput
})

local response = request({
    Url = url,
    Method = "POST",
    Headers = headers,
    Body = body
})

if response.Success then
    local raw_data = HttpService:JSONDecode(response.Body)
    
    if raw_data.status == "success" then
        function Load()
            while true do
                local Players = game:GetService("Players")
                local Player = Players.LocalPlayer
                local HttpService = game:GetService("HttpService")
                local hwid = gethwid()
                local success, err = pcall(function()
                    local url = "https://trackerbf.com/load_script.php?hwid=" .. hwid .. "&key=" .. keyinput .. "&account=" .. Player.Name 
                    local data = { gem = '1', key = '1' }
                    local body = HttpService:JSONEncode(data)
                    local response = request({
                        Url = url,
                        Method = "GET",
                        Headers = { ["Content-Type"] = "application/json" },
                        Body = body
                    })
                end)
                if not success then
                    print("Error:", err)
                end
                task.wait(60)
            end
        end
        task.spawn(Load)
        Mainrs()
    else
        game.Players.LocalPlayer:kick("Chưa Nhập Key Hoặc Key Sai")
    end
else
    warn("Lỗi kết nối: " .. response.StatusCode)
end
