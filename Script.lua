local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local Stats = game:GetService("Stats")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- 1. Foto do perfil via URL direta
local avatarUrl = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=150&h=150"

-- 2. Informações do Servidor
local gamePlaceId = game.PlaceId
local gameIconUrl = "rbxassetid://0"
local gameName = "Jogo Atual"

pcall(function()
    local productInfo = MarketplaceService:GetProductInfo(gamePlaceId)
    if productInfo then
        gameName = productInfo.Name
        if productInfo.IconImageAssetId and productInfo.IconImageAssetId > 0 then
            gameIconUrl = "rbxassetid://" .. tostring(productInfo.IconImageAssetId)
        end
    end
end)

-- 3. Janela Principal
local Window = WindUI:CreateWindow({
    Title = "KazeDev",
    Author = "by Kaze",
    Icon = "rbxassetid://134157186149514",
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
    Title = "Bem-vindo ao KazeDev!",
    Content = "Olá, " .. LocalPlayer.DisplayName .. "! Script carregado com sucesso.",
    Duration = 4,
    Icon = gameIconUrl
})

-- =======================================================
-- FUNÇÕES AUXILIARES MM2
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
        if GetPlayerRole(p) == "Murderer" then
            return p
        end
    end
    return nil
end

local function GetSheriff()
    for _, p in ipairs(Players:GetPlayers()) do
        if GetPlayerRole(p) == "Sheriff" then
            return p
        end
    end
    return nil
end

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

local function EquipTool(toolName)
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        local tool = backpack:FindFirstChild(toolName)
        if tool and LocalPlayer.Character then
            tool.Parent = LocalPlayer.Character
        end
    end
end

-- =======================================================
-- ABA 1: MAIN
-- =======================================================
local MainTab = Window:Tab({ Title = "Main", Icon = "home" })

MainTab:Section({ Title = "Servidor Atual" })

MainTab:Button({
    Title = gameName,
    Desc = "Place ID: " .. tostring(gamePlaceId),
    Icon = gameIconUrl,
    Callback = function()
        if setclipboard then
            setclipboard(tostring(gamePlaceId))
            WindUI:Notify({ Title = "KazeDev", Content = "ID do Jogo copiado!", Duration = 2 })
        end
    end,
})

MainTab:Section({ Title = "Ações do Servidor" })

MainTab:Button({
    Title = "Rejoin",
    Desc = "Entrar novamente no mesmo servidor.",
    Icon = "refresh-cw",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end,
})

MainTab:Button({
    Title = "Server Hop",
    Desc = "Entrar em outro servidor deste jogo.",
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

MainTab:Section({ Title = "Utilitários da Sessão" })

local antiAfkConnection = nil
MainTab:Toggle({
    Title = "Anti-AFK",
    Desc = "Evita ser desconectado por 20min de inatividade.",
    Value = false,
    Callback = function(enabled)
        if enabled then
            antiAfkConnection = LocalPlayer.Idled:Connect(function()
                local VirtualUser = game:GetService("VirtualUser")
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new(0,0))
            end)
            WindUI:Notify({ Title = "Anti-AFK", Content = "Anti-AFK Ativado!", Duration = 2 })
        else
            if antiAfkConnection then
                antiAfkConnection:Disconnect()
                antiAfkConnection = nil
            end
            WindUI:Notify({ Title = "Anti-AFK", Content = "Anti-AFK Desativado!", Duration = 2 })
        end
    end,
})

MainTab:Section({ Title = "Status de Desempenho" })

local fpsLabel = MainTab:Button({
    Title = "FPS: Calculando...",
    Desc = "Taxa de quadros atual.",
    Icon = "activity",
    Callback = function() end,
})

local pingLabel = MainTab:Button({
    Title = "Ping: Calculando...",
    Desc = "Latência com o servidor.",
    Icon = "wifi",
    Callback = function() end,
})

local lastTime = tick()
local frameCount = 0

RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local currentTime = tick()
    if currentTime - lastTime >= 1 then
        local fps = math.floor(frameCount / (currentTime - lastTime))
        local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        
        pcall(function()
            fpsLabel:SetTitle("FPS: " .. tostring(fps))
            pingLabel:SetTitle("Ping: " .. tostring(ping) .. " ms")
        end)
        
        frameCount = 0
        lastTime = currentTime
    end
end)

-- =======================================================
-- ABA 2: MOVEMENT
-- =======================================================
local MovementTab = Window:Tab({ Title = "Movement", Icon = "move" })

local CustomSpeedEnabled = false
local CustomSpeedValue = 16

local CustomJumpEnabled = false
local CustomJumpValue = 50

local InfiniteJumpEnabled = false
local InfiniteJumpConnection = nil

local FlyEnabled = false
local FlySpeed = 50
local FlyConnection = nil

local NoClipEnabled = false
local NoClipConnection = nil

local XrayEnabled = false
local OriginalTransparencies = {}

MovementTab:Section({ Title = "Velocidade & Pulo" })

-- Speed
MovementTab:Toggle({
    Title = "Ativar Velocidade Modificada",
    Value = false,
    Callback = function(state)
        CustomSpeedEnabled = state
        task.spawn(function()
            while CustomSpeedEnabled do
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                    LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = CustomSpeedValue
                end
                task.wait(0.1)
            end
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
            end
        end)
    end,
})

MovementTab:Slider({
    Title = "Velocidade (WalkSpeed)",
    Step = 1,
    Value = { Min = 16, Max = 300, Default = 16 },
    Callback = function(value)
        CustomSpeedValue = value
    end,
})

-- Jump Power
MovementTab:Toggle({
    Title = "Ativar Pulo Modificado",
    Value = false,
    Callback = function(state)
        CustomJumpEnabled = state
        task.spawn(function()
            while CustomJumpEnabled do
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if hum.UseJumpPower then
                        hum.JumpPower = CustomJumpValue
                    else
                        hum.JumpHeight = CustomJumpValue / 7
                    end
                end
                task.wait(0.1)
            end
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                hum.JumpPower = 50
                hum.JumpHeight = 7.2
            end
        end)
    end,
})

MovementTab:Slider({
    Title = "Força do Pulo (JumpPower)",
    Step = 5,
    Value = { Min = 50, Max = 400, Default = 50 },
    Callback = function(value)
        CustomJumpValue = value
    end,
})

-- Pulo Infinito
MovementTab:Toggle({
    Title = "Ativar Pulo Infinito",
    Desc = "Permite pular no ar infinitas vezes sem tocar no chão.",
    Value = false,
    Callback = function(state)
        InfiniteJumpEnabled = state
        
        if InfiniteJumpConnection then
            InfiniteJumpConnection:Disconnect()
            InfiniteJumpConnection = nil
        end
        
        if InfiniteJumpEnabled then
            InfiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
                if InfiniteJumpEnabled and LocalPlayer.Character then
                    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end)
        end
    end,
})

MovementTab:Section({ Title = "Voo & Atravessar Parede" })

-- Fly
MovementTab:Toggle({
    Title = "Ativar Fly",
    Value = false,
    Callback = function(state)
        FlyEnabled = state
        local char = LocalPlayer.Character
        if not char then return end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not humanoid then return end
        
        if FlyEnabled then
            local bodyGyro = Instance.new("BodyGyro")
            bodyGyro.Name = "KazeFlyGyro"
            bodyGyro.P = 9e4
            bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            bodyGyro.CFrame = hrp.CFrame
            bodyGyro.Parent = hrp

            local bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Name = "KazeFlyVelocity"
            bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bodyVelocity.Velocity = Vector3.zero
            bodyVelocity.Parent = hrp

            humanoid.PlatformStand = true

            FlyConnection = RunService.RenderStepped:Connect(function()
                if not FlyEnabled or not hrp:FindFirstChild("KazeFlyVelocity") then
                    if FlyConnection then FlyConnection:Disconnect() end
                    return
                end

                local camera = Workspace.CurrentCamera
                bodyGyro.CFrame = camera.CFrame
                local moveDir = humanoid.MoveDirection
                
                if moveDir.Magnitude > 0 then
                    local cameraCFrame = camera.CFrame
                    local direction = (cameraCFrame.LookVector * (moveDir:Dot(cameraCFrame.LookVector))) + 
                                      (cameraCFrame.RightVector * (moveDir:Dot(cameraCFrame.RightVector)))
                    
                    if direction.Magnitude < 0.1 then
                        direction = cameraCFrame:VectorToWorldSpace(Vector3.new(moveDir.X, 0, moveDir.Z))
                    end

                    bodyVelocity.Velocity = direction.Unit * FlySpeed
                else
                    bodyVelocity.Velocity = Vector3.zero
                end
            end)
        else
            humanoid.PlatformStand = false
            if hrp:FindFirstChild("KazeFlyGyro") then hrp.KazeFlyGyro:Destroy() end
            if hrp:FindFirstChild("KazeFlyVelocity") then hrp.KazeFlyVelocity:Destroy() end
            if FlyConnection then FlyConnection:Disconnect() end
        end
    end,
})

MovementTab:Slider({
    Title = "Velocidade do Fly",
    Step = 5,
    Value = { Min = 10, Max = 300, Default = 50 },
    Callback = function(value)
        FlySpeed = value
    end,
})

-- NoClip
MovementTab:Toggle({
    Title = "Ativar NoClip",
    Desc = "Permite atravessar qualquer objeto sólido.",
    Value = false,
    Callback = function(state)
        NoClipEnabled = state
        if NoClipEnabled then
            NoClipConnection = RunService.Stepped:Connect(function()
                if LocalPlayer.Character then
                    for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") and part.CanCollide then
                            part.CanCollide = false
                        end
                    end
                end
            end)
        else
            if NoClipConnection then 
                NoClipConnection:Disconnect() 
                NoClipConnection = nil
            end
        end
    end,
})

MovementTab:Section({ Title = "Otimização & Visibilidade" })

-- FPS Booster
MovementTab:Button({
    Title = "Otimizar FPS (FPS Booster)",
    Desc = "Remove sombras, texturas e efeitos para aumentar a performance.",
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
                elseif v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                    v.Enabled = false
                end
            end
            
            for _, effect in ipairs(Lighting:GetChildren()) do
                if effect:IsA("PostEffect") or effect:IsA("BloomEffect") or effect:IsA("BlurEffect") or effect:IsA("SunRaysEffect") then
                    effect.Enabled = false
                end
            end
        end)
        
        WindUI:Notify({ Title = "KazeDev", Content = "Gráficos otimizados com sucesso!", Duration = 3 })
    end,
})

-- X-Ray
MovementTab:Toggle({
    Title = "Ativar X-Ray",
    Desc = "Deixa as paredes transparentes para ver através do mapa.",
    Value = false,
    Callback = function(state)
        XrayEnabled = state
        if XrayEnabled then
            OriginalTransparencies = {}
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") and not obj:IsDescendantOf(LocalPlayer.Character) then
                    OriginalTransparencies[obj] = obj.Transparency
                    obj.Transparency = 0.65
                end
            end
        else
            for obj, originalTransparency in pairs(OriginalTransparencies) do
                if obj and obj.Parent then
                    obj.Transparency = originalTransparency
                end
            end
            OriginalTransparencies = {}
        end
    end,
})

-- =======================================================
-- ABA 3: VISUAL (MM2 ESP SYSTEM)
-- =======================================================
local VisualTab = Window:Tab({ Title = "Visual", Icon = "eye" })

local EspAllEnabled = false
local EspNameEnabled = false
local EspDistanceEnabled = false
local EspGunEnabled = false

local function IsMatchActive()
    for _, p in ipairs(Players:GetPlayers()) do
        if GetPlayerRole(p) ~= "Innocent" then
            return true
        end
    end
    return false
end

local function ClearHighlight(char)
    if char and char:FindFirstChild("KazeESP_Highlight") then
        char.KazeESP_Highlight:Destroy()
    end
end

local function ClearBillboard(char)
    if char and char:FindFirstChild("Head") and char.Head:FindFirstChild("KazeESP_Billboard") then
        char.Head.KazeESP_Billboard:Destroy()
    end
end

VisualTab:Section({ Title = "ESP de Jogadores (MM2)" })

VisualTab:Toggle({
    Title = "ESP ALL (Cores de Cargo)",
    Desc = "Verde: Inocente | Azul: Sheriff | Vermelho: Murderer | Branco: Fim de Partida.",
    Value = false,
    Callback = function(state)
        EspAllEnabled = state
        if not EspAllEnabled then
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then ClearHighlight(p.Character) end
            end
        end
    end,
})

VisualTab:Toggle({
    Title = "ESP Name",
    Desc = "Exibe o nome do jogador com a cor do cargo.",
    Value = false,
    Callback = function(state)
        EspNameEnabled = state
        if not EspNameEnabled and not EspDistanceEnabled then
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then ClearBillboard(p.Character) end
            end
        end
    end,
})

VisualTab:Toggle({
    Title = "ESP Distance",
    Desc = "Exibe a distância até o jogador em metros (cor cinza).",
    Value = false,
    Callback = function(state)
        EspDistanceEnabled = state
        if not EspNameEnabled and not EspDistanceEnabled then
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then ClearBillboard(p.Character) end
            end
        end
    end,
})

VisualTab:Section({ Title = "ESP de Objetos" })

VisualTab:Toggle({
    Title = "ESP Gun (Arma Caída)",
    Desc = "Mostra a localização e distância da arma caída no chão na cor amarela.",
    Value = false,
    Callback = function(state)
        EspGunEnabled = state
        if not EspGunEnabled then
            local gunPart = GetDroppedGunPart()
            if gunPart and gunPart:FindFirstChild("KazeGunESP_Billboard") then
                gunPart.KazeGunESP_Billboard:Destroy()
            end
        end
    end,
})

-- Visual ESP Render Connection
RunService.RenderStepped:Connect(function()
    local matchActive = IsMatchActive()
    local myChar = LocalPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")

    -- ESP Player
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Head") then
            local char = player.Character
            local head = char.Head
            local role = GetPlayerRole(player)

            local roleColor = Color3.fromRGB(255, 255, 255)
            if matchActive then
                if role == "Murderer" then
                    roleColor = Color3.fromRGB(255, 30, 30)
                elseif role == "Sheriff" then
                    roleColor = Color3.fromRGB(30, 144, 255)
                else
                    roleColor = Color3.fromRGB(30, 255, 30)
                end
            end

            -- Highlight (ESP All)
            if EspAllEnabled then
                local highlight = char:FindFirstChild("KazeESP_Highlight")
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "KazeESP_Highlight"
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0
                    highlight.Parent = char
                end
                highlight.FillColor = roleColor
                highlight.OutlineColor = roleColor
            else
                ClearHighlight(char)
            end

            -- Billboard Text (ESP Name & ESP Distance)
            if EspNameEnabled or EspDistanceEnabled then
                local billboard = head:FindFirstChild("KazeESP_Billboard")
                if not billboard then
                    billboard = Instance.new("BillboardGui")
                    billboard.Name = "KazeESP_Billboard"
                    billboard.AlwaysOnTop = true
                    billboard.Size = UDim2.new(0, 200, 0, 50)
                    billboard.StudsOffset = Vector3.new(0, 3, 0)

                    local nameLabel = Instance.new("TextLabel")
                    nameLabel.Name = "NameLabel"
                    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
                    nameLabel.BackgroundTransparency = 1
                    nameLabel.Font = Enum.Font.SourceSansBold
                    nameLabel.TextSize = 14
                    nameLabel.TextStrokeTransparency = 0
                    nameLabel.Parent = billboard

                    local distLabel = Instance.new("TextLabel")
                    distLabel.Name = "DistLabel"
                    distLabel.Size = UDim2.new(1, 0, 0.5, 0)
                    distLabel.Position = UDim2.new(0, 0, 0.5, 0)
                    distLabel.BackgroundTransparency = 1
                    distLabel.Font = Enum.Font.SourceSans
                    distLabel.TextSize = 12
                    distLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                    distLabel.TextStrokeTransparency = 0
                    distLabel.Parent = billboard

                    billboard.Parent = head
                end

                local nameLabel = billboard:FindFirstChild("NameLabel")
                local distLabel = billboard:FindFirstChild("DistLabel")

                if EspNameEnabled then
                    nameLabel.Visible = true
                    nameLabel.Text = player.DisplayName
                    nameLabel.TextColor3 = roleColor
                else
                    nameLabel.Visible = false
                end

                if EspDistanceEnabled and myHrp then
                    distLabel.Visible = true
                    local distance = math.floor((head.Position - myHrp.Position).Magnitude)
                    distLabel.Text = "[" .. tostring(distance) .. "m]"
                else
                    distLabel.Visible = false
                end
            else
                ClearBillboard(char)
            end
        end
    end

    -- ESP Gun (Arma Caída)
    if EspGunEnabled then
        local gunPart = GetDroppedGunPart()
        if gunPart then
            local billboard = gunPart:FindFirstChild("KazeGunESP_Billboard")
            if not billboard then
                billboard = Instance.new("BillboardGui")
                billboard.Name = "KazeGunESP_Billboard"
                billboard.AlwaysOnTop = true
                billboard.Size = UDim2.new(0, 200, 0, 50)
                billboard.StudsOffset = Vector3.new(0, 2, 0)

                local label = Instance.new("TextLabel")
                label.Name = "GunLabel"
                label.Size = UDim2.new(1, 0, 1, 0)
                label.BackgroundTransparency = 1
                label.Font = Enum.Font.SourceSansBold
                label.TextSize = 14
                label.TextColor3 = Color3.fromRGB(255, 215, 0)
                label.TextStrokeTransparency = 0
                label.Parent = billboard

                billboard.Parent = gunPart
            end

            local label = billboard:FindFirstChild("GunLabel")
            if label then
                if myHrp then
                    local distance = math.floor((gunPart.Position - myHrp.Position).Magnitude)
                    label.Text = "🔫 Arma Caída [" .. tostring(distance) .. "m]"
                else
                    label.Text = "🔫 Arma Caída"
                end
            end
        end
    else
        local gunPart = GetDroppedGunPart()
        if gunPart and gunPart:FindFirstChild("KazeGunESP_Billboard") then
            gunPart.KazeGunESP_Billboard:Destroy()
        end
    end
end)

-- =======================================================
-- ABA 4: MM2 FEATURES
-- =======================================================
local Mm2Tab = Window:Tab({ Title = "MM2", Icon = "swords" })

local AutoGrabGun = false
local KillAllLoop = false
local SilentAimGun = false

Mm2Tab:Section({ Title = "Teleportes & Coleta" })

Mm2Tab:Button({
    Title = "Teleportar para Arma Caída",
    Desc = "Teleporta instantaneamente para a arma dropped.",
    Icon = "crosshair",
    Callback = function()
        local gunPart = GetDroppedGunPart()
        if gunPart and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = gunPart.CFrame + Vector3.new(0, 3, 0)
            WindUI:Notify({ Title = "MM2", Content = "Teleportado para a Arma!", Duration = 2 })
        else
            WindUI:Notify({ Title = "MM2", Content = "Nenhuma arma encontrada no chão.", Duration = 2 })
        end
    end,
})

Mm2Tab:Toggle({
    Title = "Auto Grab Gun",
    Desc = "Pega a arma do chão automaticamente se você passar perto.",
    Value = false,
    Callback = function(state)
        AutoGrabGun = state
        task.spawn(function()
            while AutoGrabGun do
                local gunPart = GetDroppedGunPart()
                local myChar = LocalPlayer.Character
                if gunPart and myChar and myChar:FindFirstChild("HumanoidRootPart") then
                    local dist = (gunPart.Position - myChar.HumanoidRootPart.Position).Magnitude
                    if dist <= 15 then
                        firetouchinterest(myChar.HumanoidRootPart, gunPart, 0)
                        firetouchinterest(myChar.HumanoidRootPart, gunPart, 1)
                    end
                end
                task.wait(0.2)
            end
        end)
    end,
})

Mm2Tab:Section({ Title = "Funções de Assassino / Sheriff" })

Mm2Tab:Button({
    Title = "Matar Todos (Murderer)",
    Desc = "Teleporta até cada jogador e ataca (necessário ser o Murderer).",
    Icon = "skull",
    Callback = function()
        if GetPlayerRole(LocalPlayer) ~= "Murderer" then
            WindUI:Notify({ Title = "Aviso", Content = "Você precisa ser o Murderer para usar isto!", Duration = 3 })
            return
        end

        EquipTool("Knife")
        EquipTool("Faca")

        for _, target in ipairs(Players:GetPlayers()) do
            if target ~= LocalPlayer and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                local hum = target.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if myHrp then
                        myHrp.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 2)
                        task.wait(0.1)
                        local knife = LocalPlayer.Character:FindFirstChild("Knife") or LocalPlayer.Character:FindFirstChild("Faca")
                        if knife and knife:FindFirstChild("Stab") then
                            knife.Stab:FireServer()
                        end
                        task.wait(0.2)
                    end
                end
            end
        end
    end,
})

Mm2Tab:Toggle({
    Title = "Silent Aim / Auto Shoot (Sheriff)",
    Desc = "Mira e atira automaticamente no Murderer quando você equipar a arma.",
    Value = false,
    Callback = function(state)
        SilentAimGun = state
        task.spawn(function()
            while SilentAimGun do
                if GetPlayerRole(LocalPlayer) == "Sheriff" then
                    local murd = GetMurderer()
                    if murd and murd.Character and murd.Character:FindFirstChild("HumanoidRootPart") then
                        local gun = LocalPlayer.Character and (LocalPlayer.Character:FindFirstChild("Gun") or LocalPlayer.Character:FindFirstChild("Revolver") or LocalPlayer.Character:FindFirstChild("Arma"))
                        if gun then
                            local shootRemote = gun:FindFirstChild("Shoot") or gun:FindFirstChild("ShootGun")
                            if shootRemote and shootRemote:IsA("RemoteEvent") then
                                shootRemote:FireServer(murd.Character.HumanoidRootPart.Position)
                            end
                        end
                    end
                end
                task.wait(0.5)
            end
        end)
    end,
})

-- =======================================================
-- ABA 5: TELEPORTS
-- =======================================================
local TeleportTab = Window:Tab({ Title = "Teleports", Icon = "map-pin" })

TeleportTab:Section({ Title = "Teleportes Rápidos" })

TeleportTab:Button({
    Title = "Ir para o Murderer",
    Desc = "Teleporta até o assassino da rodada.",
    Icon = "user-x",
    Callback = function()
        local murd = GetMurderer()
        if murd and murd.Character and murd.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character then
            LocalPlayer.Character.HumanoidRootPart.CFrame = murd.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
            WindUI:Notify({ Title = "Teleporte", Content = "Teleportado para o Murderer!", Duration = 2 })
        else
            WindUI:Notify({ Title = "Teleporte", Content = "Murderer não encontrado.", Duration = 2 })
        end
    end,
})

TeleportTab:Button({
    Title = "Ir para o Sheriff",
    Desc = "Teleporta até o xamã/sheriff da rodada.",
    Icon = "shield",
    Callback = function()
        local sheriff = GetSheriff()
        if sheriff and sheriff.Character and sheriff.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character then
            LocalPlayer.Character.HumanoidRootPart.CFrame = sheriff.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
            WindUI:Notify({ Title = "Teleporte", Content = "Teleportado para o Sheriff!", Duration = 2 })
        else
            WindUI:Notify({ Title = "Teleporte", Content = "Sheriff não encontrado.", Duration = 2 })
        end
    end,
})

TeleportTab:Section({ Title = "Teleporte para Jogadores" })

local SelectedPlayerName = nil

local function GetPlayerNamesList()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(names, p.DisplayName .. " (@" .. p.Name .. ")")
        end
    end
    return names
end

local PlayerDropdown = TeleportTab:Dropdown({
    Title = "Selecionar Jogador",
    Values = GetPlayerNamesList(),
    Value = nil,
    Callback = function(val)
        SelectedPlayerName = val
    end,
})

TeleportTab:Button({
    Title = "Atualizar Lista de Jogadores",
    Icon = "rotate-cw",
    Callback = function()
        PlayerDropdown:SetValues(GetPlayerNamesList())
        WindUI:Notify({ Title = "Teleporte", Content = "Lista de jogadores atualizada!", Duration = 2 })
    end,
})

TeleportTab:Button({
    Title = "Teleportar para Jogador Selecionado",
    Icon = "navigation",
    Callback = function()
        if not SelectedPlayerName then
            WindUI:Notify({ Title = "Aviso", Content = "Selecione um jogador primeiro!", Duration = 2 })
            return
        end

        for _, p in ipairs(Players:GetPlayers()) do
            local formatted = p.DisplayName .. " (@" .. p.Name .. ")"
            if formatted == SelectedPlayerName then
                if p.Character and p.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
                    WindUI:Notify({ Title = "Teleporte", Content = "Teleportado para " .. p.DisplayName, Duration = 2 })
                end
                break
            end
        end
    end,
})

-- =======================================================
-- ABA 6: SETTINGS / UI CONFIG
-- =======================================================
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

SettingsTab:Section({ Title = "Aparência e Tema" })

SettingsTab:Dropdown({
    Title = "Tema da Interface",
    Values = { "Dark", "Light", "Rose", "Aqua", "Midnight" },
    Value = "Dark",
    Callback = function(theme)
        Window:SetTheme(theme)
    end,
})

SettingsTab:Keybind({
    Title = "Atalho para Ocultar/Exibir Menu",
    Value = Enum.KeyCode.RightControl,
    Callback = function()
        Window:Toggle()
    end,
})

SettingsTab:Section({ Title = "Finalizar Script" })

SettingsTab:Button({
    Title = "Destruir Interface",
    Desc = "Fecha e remove o script da tela.",
    Icon = "trash-2",
    Callback = function()
        Window:Destroy()
    end,
})
