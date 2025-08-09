local PLACE_ID = 109983668079237
local FIREBASE_URL = "https://olaaa-dc667-default-rtdb.firebaseio.com/ccc.json"

local usuariosPermitidos = {"sjjfjnfia"}
local LocalPlayer = game:GetService("Players").LocalPlayer

-- Verifica se o jogador está na lista
local permitido = false
for _, nome in ipairs(usuariosPermitidos) do
    if nome:lower() == LocalPlayer.Name:lower() then
        permitido = true
        break
    end
end

if not permitido then
    pcall(function()
        LocalPlayer:Kick("O seu nick não está registrado")
    end)
    return
end

-- Interface protegida
local successGui, ScreenGui = pcall(function()
    local gui = Instance.new("ScreenGui")
    gui.Name = "UnitySniperGui"
    gui.ResetOnSpawn = false
    gui.Parent = game:GetService("CoreGui")
    return gui
end)

if not successGui or not ScreenGui then
    warn("Não foi possível criar a GUI")
    return
end

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.new(0, 300, 0, 150)
Frame.Position = UDim2.new(0.5, -150, 0.2, -75)
Frame.BackgroundColor3 = Color3.new(1, 1, 1)
Frame.Active = true
Frame.Draggable = true

local Dropdown = Instance.new("TextButton", Frame)
Dropdown.Size = UDim2.new(0.8, 0, 0.3, 0)
Dropdown.Position = UDim2.new(0.1, 0, 0.1, 0)
Dropdown.Text = "Selecionar: 1M/s"

local AcharBtn = Instance.new("TextButton", Frame)
AcharBtn.Size = UDim2.new(0.8, 0, 0.3, 0)
AcharBtn.Position = UDim2.new(0.1, 0, 0.55, 0)
AcharBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
AcharBtn.Text = "Achar Servidor"

local lista = {"1M/s", "2M/s", "3M/s", "4M/s", "5M/s", "6M/s", "7M/s", "8M/s", "9M/s", "10M/s"}
local selecionado = 1

Dropdown.MouseButton1Click:Connect(function()
    pcall(function()
        for _, btn in pairs(Frame:GetChildren()) do
            if btn:IsA("TextButton") and btn.Name == "Opt" then
                btn:Destroy()
            end
        end
        for i, opt in ipairs(lista) do
            local btn = Instance.new("TextButton", Frame)
            btn.Name = "Opt"
            btn.Size = UDim2.new(0.8, 0, 0.2, 0)
            btn.Position = UDim2.new(0.1, 0, 0.1 + i * 0.2, 0)
            btn.Text = opt
            btn.MouseButton1Click:Connect(function()
                pcall(function()
                    selecionado = tonumber(opt:match("(%d+)"))
                    Dropdown.Text = "Selecionado: " .. opt
                    for _, b in pairs(Frame:GetChildren()) do
                        if b.Name == "Opt" then b:Destroy() end
                    end
                end)
            end)
        end
    end)
end)

-- Função para extrair valor numérico do "money_per_sec"
local function parseMoney(text)
    local n = text:match("([%d%.]+)")
    return tonumber(n)
end

-- Função para limpar crases do join_script
local function limparCodigo(script)
    return script:gsub("```", ""):gsub("\n", "")
end

local ultimoScript = nil
local primeiraLeitura = true
local rodando = false

AcharBtn.MouseButton1Click:Connect(function()
    if rodando then return end
    rodando = true
    AcharBtn.Text = "Procurando..."
    Frame.Visible = false

    spawn(function()
        while rodando do
            local success, res = pcall(function()
                return game:HttpGet(FIREBASE_URL)
            end)

            if success and res then
                pcall(function()
                    local data = game:GetService("HttpService"):JSONDecode(res)
                    local join_script = data.join_script
                    local money = parseMoney(data.money_per_sec or "0")

                    if join_script and join_script ~= "" and join_script ~= ultimoScript then
                        if primeiraLeitura then
                            print("Primeiro join_script detectado e ignorado.")
                            ultimoScript = join_script
                            primeiraLeitura = false
                        elseif selecionado and money and money >= selecionado then
                            ultimoScript = join_script
                            print("Novo join_script detectado com money/s:", money)

                            local codigo = limparCodigo(join_script)
                            local func, err = loadstring(codigo)
                            if func then
                                func()
                            else
                                warn("Erro ao executar script:", err)
                            end
                        end
                    end
                end)
            else
                warn("Erro ao acessar Firebase:", res)
            end

            wait(0.1)
        end
    end)
end)
