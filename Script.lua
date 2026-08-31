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
local hubIcon = "rbxassetid://134157186149514"

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
    Title = "KazeHub 👾",
    Author = "by Kaze",
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
    Title = "Bem-vindo ao KazeHub!",
    Content = "Olá, " .. LocalPlayer.DisplayName .. "! Script carregado com sucesso.",
    Duration = 4,
    Icon = gameIconUrl
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

local function IsMatchActive()
    for _, p in ipairs(Players:GetPlayers()) do
        if GetPlayerRole(p) ~= "Innocent" then return true end
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

-- =======================================================
-- ABA 1: HOME
-- =======================================================
local HomeTab = Window:Tab({ Title = "Home", Icon = "house" })

HomeTab:Section({ Title = "Comunidade & Informações" })

HomeTab:Button({
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

HomeTab:Button({
    Title = "Servidor do Discord",
    Desc = "Clique para copiar o link da nossa comunidade!",
    Icon = hubIcon,
    Callback = function()
        if setclipboard then
            setclipboard("https://discord.gg/kazedev")
            WindUI:Notify({ Title = "KazeHub", Content = "Link do Discord copiado!", Duration = 2 })
        end
    end,
})

-- =======================================================
-- ABA 2: MAIN
-- =======================================================
local MainTab = Window:Tab({ Title = "Main", Icon = "layers" })

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
-- ABA 3: MOVEMENT
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
-- ABA 4: VISUAL
-- =======================================================
local VisualTab = Window:Tab({ Title = "Visual", Icon = "eye" })

local EspAllEnabled = false
local EspNameEnabled = false
local EspDistanceEnabled = false
local EspGunEnabled = false

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

RunService.RenderStepped:Connect(function()
    local matchActive = IsMatchActive()
    local myChar = LocalPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")

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
                    roleColor = Color3.fromRGB(50, 205, 50)
                end
            end

            -- Highlight (ESP ALL)
            if EspAllEnabled then
                local hl = char:FindFirstChild("KazeESP_Highlight")
                if not hl then
                    hl = Instance.new("Highlight")
                    hl.Name = "KazeESP_Highlight"
                    hl.Parent = char
                end
                hl.FillColor = roleColor
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.FillTransparency = 0.5
                hl.OutlineTransparency = 0
            else
                ClearHighlight(char)
            end

            -- Billboard Text (Name & Distance)
            if EspNameEnabled or EspDistanceEnabled then
                local bb = head:FindFirstChild("KazeESP_Billboard")
                if not bb then
                    bb = Instance.new("BillboardGui")
                    bb.Name = "KazeESP_Billboard"
                    bb.Size = UDim2.new(0, 200, 0, 50)
                    bb.StudsOffset = Vector3.new(0, 3, 0)
                    bb.AlwaysOnTop = true
                    bb.Parent = head

                    local layout = Instance.new("UIListLayout")
                    layout.Parent = bb
                    layout.SortOrder = Enum.SortOrder.LayoutOrder
                    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

                    local nameLbl = Instance.new("TextLabel")
                    nameLbl.Name = "NameLabel"
                    nameLbl.Size = UDim2.new(1, 0, 0, 20)
                    nameLbl.BackgroundTransparency = 1
                    nameLbl.TextStrokeTransparency = 0
                    nameLbl.TextSize = 14
                    nameLbl.Font = Enum.Font.SourceSansBold
                    nameLbl.Parent = bb

                    local distLbl = Instance.new("TextLabel")
                    distLbl.Name = "DistLabel"
                    distLbl.Size = UDim2.new(1, 0, 0, 20)
                    distLbl.BackgroundTransparency = 1
                    distLbl.TextStrokeTransparency = 0
                    distLbl.TextSize = 12
                    distLbl.Font = Enum.Font.SourceSans
                    distLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
                    distLbl.Parent = bb
                end

                local nameLbl = bb:FindFirstChild("NameLabel")
                local distLbl = bb:FindFirstChild("DistLabel")

                if nameLbl then
                    nameLbl.Visible = EspNameEnabled
                    nameLbl.Text = player.DisplayName
                    nameLbl.TextColor3 = roleColor
                end

                if distLbl then
                    distLbl.Visible = EspDistanceEnabled
                    if myHrp then
                        local dist = math.floor((myHrp.Position - char.HumanoidRootPart.Position).Magnitude)
                        distLbl.Text = tostring(dist) .. "m"
                    else
                        distLbl.Text = "0m"
                    end
                end
            else
                ClearBillboard(char)
            end
        end
    end

    -- ESP Gun (Arma no chão)
    local gunPart = GetDroppedGunPart()
    if EspGunEnabled and gunPart then
        local bb = gunPart:FindFirstChild("KazeGunESP_Billboard")
        if not bb then
            bb = Instance.new("BillboardGui")
            bb.Name = "KazeGunESP_Billboard"
            bb.Size = UDim2.new(0, 200, 0, 30)
            bb.StudsOffset = Vector3.new(0, 2, 0)
            bb.AlwaysOnTop = true
            bb.Parent = gunPart

            local txt = Instance.new("TextLabel")
            txt.Name = "GunText"
            txt.Size = UDim2.new(1, 0, 1, 0)
            txt.BackgroundTransparency = 1
            txt.TextStrokeTransparency = 0
            txt.TextSize = 14
            txt.Font = Enum.Font.SourceSansBold
            txt.TextColor3 = Color3.fromRGB(255, 215, 0)
            txt.Parent = bb
        end

        local txt = bb:FindFirstChild("GunText")
        if txt then
            if myHrp then
                local dist = math.floor((myHrp.Position - gunPart.Position).Magnitude)
                txt.Text = "Gun (" .. tostring(dist) .. "m)"
            else
                txt.Text = "Gun"
            end
        end
    elseif gunPart and gunPart:FindFirstChild("KazeGunESP_Billboard") then
        gunPart.KazeGunESP_Billboard:Destroy()
    end
end)

-- =======================================================
-- ABA 5: FARM E TP
-- =======================================================
local FarmTpTab = Window:Tab({ Title = "Farm e Tp", Icon = "map-pin" })

FarmTpTab:Section({ Title = "Auto Farm & Arma" })

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
-- ABA 6: SHERIF
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
-- ABA 7: MURDE
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
-- ABA 8: SETTINGS
-- =======================================================
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })

SettingsTab:Section({ Title = "Servidor & Reconexão" })

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
