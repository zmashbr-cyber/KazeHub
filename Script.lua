local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local Stats = game:GetService("Stats")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

-- Foto do perfil e jogo
local avatarUrl = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"
local hubIcon = "rbxassetid://134157186149514"

-- Janela Principal
local Window = WindUI:CreateWindow({
    Title = "KazeDev",
    Author = "by @MashDev",
    Icon = hubIcon,
    Theme = "Dark",
    Transparent = true,
    HideSearchBar = false,
    User = {
        Enabled = true,
        Title = LocalPlayer.DisplayName,
        Subtitle = "@" .. LocalPlayer.Name,
        Icon = avatarUrl,
        Image = avatarUrl,
    }
})

WindUI:Notify({
    Title = "KazeDev Loaded",
    Content = "Script carregado com sucesso!",
    Duration = 3,
    Icon = hubIcon
})

-- =======================================================
-- FUNÇÕES AUXILIARES MM2 (Baseadas no Dex Explorer)
-- =======================================================
local function GetPlayerRole(player)
    if not player then return "Innocent" end
    local char = player.Character
    local backpack = player:FindFirstChild("Backpack")
    
    if char then
        if char:FindFirstChild("Knife") or char:FindFirstChild("Faca") then return "Murderer" end
        if char:FindFirstChild("Gun") or char:FindFirstChild("Revolver") or char:FindFirstChild("Arma") then return "Sheriff" end
    end
    if backpack then
        if backpack:FindFirstChild("Knife") or backpack:FindFirstChild("Faca") then return "Murderer" end
        if backpack:FindFirstChild("Gun") or backpack:FindFirstChild("Revolver") or backpack:FindFirstChild("Arma") then return "Sheriff" end
    end
    return "Innocent"
end

local function GetMurderer()
    for _, p in ipairs(Players:GetPlayers()) do
        if GetPlayerRole(p) == "Murderer" then return p end
    end
    return nil
end

local function GetSheriff()
    for _, p in ipairs(Players:GetPlayers()) do
        if GetPlayerRole(p) == "Sheriff" then return p end
    end
    return nil
end

-- Busca GunDrop no mapa
local function GetDroppedGunPart()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "GunDrop" then
            if obj:IsA("BasePart") then 
                return obj 
            elseif obj:IsA("Model") then 
                return obj.PrimaryPart or obj:FindFirstChildOfClass("BasePart") 
            end
        end
    end
    return nil
end

-- Busca as moedas na estrutura exata do Dex (CoinContainer -> Coin_Server -> CoinVisual -> MainCoin)
local function GetCoinParts()
    local coins = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "MainCoin" or obj.Name == "CoinVisual" or obj.Name == "Coin_Server" then
            if obj:IsA("BasePart") then
                table.insert(coins, obj)
            elseif obj:IsA("Model") and obj.PrimaryPart then
                table.insert(coins, obj.PrimaryPart)
            end
        end
    end
    return coins
end

-- =======================================================
-- TAB 1: HOME
-- =======================================================
local HomeTab = Window:Tab({ Title = "Home", Icon = "home" })

HomeTab:Section({ Title = "Comunidade" })

HomeTab:Button({
    Title = "Servidor do Discord",
    Desc = "Clique para copiar o link da nossa comunidade!",
    Icon = hubIcon,
    Callback = function()
        if setclipboard then
            setclipboard("https://discord.gg/kazedev")
            WindUI:Notify({ Title = "KazeDev", Content = "Link do Discord copiado!", Duration = 2 })
        end
    end,
})

HomeTab:Section({ Title = "Créditos" })
HomeTab:Button({
    Title = "Desenvolvido por @MashDev",
    Desc = "Criador e Mantenedor do KazeDev Hub.",
    Icon = "user",
    Callback = function() end,
})

-- =======================================================
-- TAB 2: FARM E TP
-- =======================================================
local FarmTpTab = Window:Tab({ Title = "Farm e Tp", Icon = "map-pin" })

FarmTpTab:Section({ Title = "Auto Farm & Arma" })

-- TP Gun com notificação de distância
local TpGunActive = false
FarmTpTab:Toggle({
    Title = "Auto TP Gun",
    Desc = "Leva você até a arma no chão e volta para a posição original.",
    Value = false,
    Callback = function(state)
        TpGunActive = state
        if TpGunActive then
            task.spawn(function()
                while TpGunActive do
                    local gun = GetDroppedGunPart()
                    local char = LocalPlayer.Character
                    if gun and char and char:FindFirstChild("HumanoidRootPart") then
                        local hrp = char.HumanoidRootPart
                        local originalPos = hrp.CFrame
                        local dist = math.floor((hrp.Position - gun.Position).Magnitude)
                        
                        WindUI:Notify({ Title = "TP Gun", Content = "Pegando Arma (" .. dist .. "m de distância)...", Duration = 1.5 })
                        hrp.CFrame = gun.CFrame
                        task.wait(0.3)
                        hrp.CFrame = originalPos
                    end
                    task.wait(1)
                end
            end)
        end
    end,
})

-- Farm Coins (Velocidade 22 + Voo Safe adaptado ao Dex)
local FarmCoinsActive = false
local FarmFlyConnection = nil
FarmTpTab:Toggle({
    Title = "Farm Coins (Anti-Cheat Safe)",
    Desc = "Voa coletando moedas na velocidade 22 para evitar ban.",
    Value = false,
    Callback = function(state)
        FarmCoinsActive = state
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        
        if FarmCoinsActive and hrp and humanoid then
            humanoid.PlatformStand = true
            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Name = "FarmCoinsVelocity"
            bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bodyVelocity.Parent = hrp

            FarmFlyConnection = RunService.RenderStepped:Connect(function()
                if not FarmCoinsActive then return end
                local coins = GetCoinParts()
                if #coins > 0 then
                    local targetCoin = coins[1]
                    local dir = (targetCoin.Position - hrp.Position).Unit
                    bodyVelocity.Velocity = dir * 22
                else
                    bodyVelocity.Velocity = Vector3.zero
                end
            end)
        else
            if FarmFlyConnection then FarmFlyConnection:Disconnect() end
            if hrp and hrp:FindFirstChild("FarmCoinsVelocity") then hrp.FarmCoinsVelocity:Destroy() end
            if humanoid then humanoid.PlatformStand = false end
        end
    end,
})

FarmTpTab:Section({ Title = "Teleporte de Jogadores" })

local SelectedPlayerName = nil
local PlayerDropdown = nil

local function GetPlayerNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(names, p.Name) end
    end
    return names
end

PlayerDropdown = FarmTpTab:Dropdown({
    Title = "Selecionar Jogador",
    Values = GetPlayerNames(),
    Callback = function(value)
        SelectedPlayerName = value
    end,
})

FarmTpTab:Button({
    Title = "Atualizar Lista de Jogadores",
    Icon = "refresh-cw",
    Callback = function()
        if PlayerDropdown then
            PlayerDropdown:SetValues(GetPlayerNames())
            WindUI:Notify({ Title = "KazeDev", Content = "Lista atualizada!", Duration = 1.5 })
        end
    end,
})

FarmTpTab:Button({
    Title = "Confirmar Teleporte",
    Icon = "navigation",
    Callback = function()
        if SelectedPlayerName then
            local target = Players:FindFirstChild(SelectedPlayerName)
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character then
                LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame
            end
        end
    end,
})

-- =======================================================
-- TAB 3: SHERIF
-- =======================================================
local SherifTab = Window:Tab({ Title = "Sherif", Icon = "crosshair" })

local AimbotMurderActive = false
SherifTab:Toggle({
    Title = "Aimbot no Murderer",
    Desc = "Mira automaticamente no Murderer quando você tiver com a Arma.",
    Value = false,
    Callback = function(state)
        AimbotMurderActive = state
        task.spawn(function()
            while AimbotMurderActive do
                local myRole = GetPlayerRole(LocalPlayer)
                if myRole == "Sheriff" or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Gun")) then
                    local murderer = GetMurderer()
                    if murderer and murderer.Character and murderer.Character:FindFirstChild("Head") then
                        Workspace.CurrentCamera.CFrame = CFrame.new(Workspace.CurrentCamera.CFrame.Position, murderer.Character.Head.Position)
                    end
                end
                task.wait()
            end
        end)
    end,
})

SherifTab:Button({
    Title = "Teleportar 30m do Murderer",
    Desc = "Mantém você a uma distância segura do Murderer.",
    Icon = "shield",
    Callback = function()
        local murderer = GetMurderer()
        if murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character then
            local murHrp = murderer.Character.HumanoidRootPart
            LocalPlayer.Character.HumanoidRootPart.CFrame = murHrp.CFrame * CFrame.new(0, 0, 30)
        end
    end,
})

-- =======================================================
-- TAB 4: MURDE
-- =======================================================
local MurdeTab = Window:Tab({ Title = "Murde", Icon = "sword" })

MurdeTab:Button({
    Title = "Kill ALL",
    Desc = "Teleporta instantaneamente em cada jogador para matar.",
    Icon = "skull",
    Callback = function()
        task.spawn(function()
            for _, target in ipairs(Players:GetPlayers()) do
                if target ~= LocalPlayer and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                    if GetPlayerRole(target) ~= "Murderer" then
                        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 1)
                            task.wait(0.25)
                        end
                    end
                end
            end
        end)
    end,
})

MurdeTab:Button({
    Title = "Teleportar até o Sheriff",
    Desc = "Vai direto para a posição do Sheriff.",
    Icon = "target",
    Callback = function()
        local sheriff = GetSheriff()
        if sheriff and sheriff.Character and sheriff.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character then
            LocalPlayer.Character.HumanoidRootPart.CFrame = sheriff.Character.HumanoidRootPart.CFrame
        end
    end,
})

-- =======================================================
-- TAB 5: SETTINGS
-- =======================================================
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

SettingsTab:Section({ Title = "Servidor & Sessão" })

SettingsTab:Button({
    Title = "Rejoin",
    Desc = "Entrar novamente no mesmo servidor.",
    Icon = "refresh-cw",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end,
})

SettingsTab:Button({
    Title = "Server Hop",
    Desc = "Entrar em outro servidor do jogo.",
    Icon = "globe",
    Callback = function()
        pcall(function()
            local servers = game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/0?sortOrder=Asc&limit=100"))
            for _, s in ipairs(servers.data) do
                if s.id ~= game.JobId and s.playing < s.maxPlayers then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                    break
                end
            end
        end)
    end,
})

local antiAfkConnection = nil
SettingsTab:Toggle({
    Title = "Anti-AFK",
    Desc = "Evita ser desconectado por inatividade.",
    Value = false,
    Callback = function(enabled)
        if enabled then
            antiAfkConnection = LocalPlayer.Idled:Connect(function()
                local VirtualUser = game:GetService("VirtualUser")
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(0,0))
            end)
        else
            if antiAfkConnection then antiAfkConnection:Disconnect() end
        end
    end,
})

SettingsTab:Section({ Title = "Otimização" })

SettingsTab:Button({
    Title = "FPS Booster",
    Desc = "Remove efeitos pesados para aumentar os FPS.",
    Icon = "zap",
    Callback = function()
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            for _, v in ipairs(Workspace:GetDescendants()) do
                if v:IsA("BasePart") then
                    v.Material = Enum.Material.Plastic
                    v.Reflectance = 0
                elseif v:IsA("Decal") or v:IsA("Texture") then
                    v:Destroy()
                end
            end
        end)
        WindUI:Notify({ Title = "KazeDev", Content = "Gráficos otimizados!", Duration = 2 })
    end,
})
