local HttpService = game:GetService("HttpService")

local FIREBASE_URL = "https://olaaa-dc667-default-rtdb.firebaseio.com/ccc.json"

local function prints(str)
    print("[AutoJobMonitor]: " .. str)
end

local function readJobID()
    local success, response = pcall(function()
        return game:HttpGet(FIREBASE_URL)
    end)

    if success and response then
        local successDecode, data = pcall(function()
            return HttpService:JSONDecode(response)
        end)

        if successDecode and data and data.job_id and data.job_id ~= "" then
            local jobID = data.job_id:gsub("%s+", "") -- remove espaços
            return jobID
        end
    end

    prints("❌ Erro ao buscar JobID do site.")
    return nil
end

local function findTargetGui()
    for _, gui in ipairs(game:GetService("CoreGui"):GetChildren()) do
        if not gui:IsA("ScreenGui") then continue end
        for _, descendant in ipairs(gui:GetDescendants()) do
            if descendant:IsA("TextLabel") and descendant.Text == "Job-ID Input" then
                return descendant:FindFirstAncestorOfClass("ScreenGui")
            end
        end
    end
    return nil
end

local function setJobIDText(targetGui, text)
    for _, btn in ipairs(targetGui:GetDescendants()) do
        if btn:IsA("TextButton") then
            local frames = {}

            for _, child in ipairs(btn:GetChildren()) do
                if child:IsA("Frame") then
                    table.insert(frames, child)
                end
            end
            if #frames < 2 then continue end

            local foundLabel = false
            for _, descendant in ipairs(frames[1]:GetDescendants()) do
                if descendant:IsA("TextLabel") and descendant.Text == "Job-ID Input" then
                    foundLabel = true
                    break
                end
            end
            if not foundLabel then continue end

            for _, subFrame in ipairs(frames[2]:GetChildren()) do
                if subFrame:IsA("Frame") then
                    for _, obj in ipairs(subFrame:GetDescendants()) do
                        if obj:IsA("TextBox") then
                            obj.Text = text
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

local function clickJoinButton(targetGui)
    for _, btn in ipairs(targetGui:GetDescendants()) do
        if btn:IsA("TextButton") then
            for _, content in ipairs(btn:GetDescendants()) do
                if content:IsA("TextLabel") and content.Text == "Join Job-ID" then
                    for _, conn in ipairs(getconnections(btn.MouseButton1Click)) do
                        conn:Fire()
                    end
                    prints("✅ Teleport solicitado para novo JobID.")
                    return true
                end
            end
        end
    end
    return false
end

-- Detecta se já foi teleportado (experiência mudou)
local function teleportSuccess()
    local placeId = game.PlaceId
    local jobId = game.JobId
    wait(1) -- dá tempo pra carregar
    return game.PlaceId ~= placeId or game.JobId ~= jobId
end

-- Loop principal
task.spawn(function()
    prints("🔄 Monitor de JobID iniciado...")
    local lastJob = readJobID()

    while true do
        local newJob = readJobID()

        if newJob and newJob ~= lastJob then
            lastJob = newJob
            prints("🔍 Novo JobID encontrado: " .. newJob)

            local tentativas = 0
            local entrou = false

            while tentativas < 1000 and not entrou do -- tenta por ~10 segundos (50 x 0.2s)
                local gui = findTargetGui()
                if gui then
                    if setJobIDText(gui, newJob) then
                        wait(0.1) -- tempo pra aplicar texto
                        if clickJoinButton(gui) then
                            if teleportSuccess() then
                                entrou = true
                                prints("🚀 Teleporte confirmado!")
                                break
                            else
                                prints("⚠ Botão clicado, mas ainda não teleportou. Tentando novamente...")
                            end
                        end
                    else
                        prints("⏳ Campo de texto não encontrado, tentando de novo...")
                    end
                else
                    prints("⏳ UI não encontrada, tentando de novo...")
                end
                tentativas += 1
                wait(0.1)
            end

            if not entrou then
                prints("❌ Não foi possível entrar no novo JobID após várias tentativas.")
            end
        end

        wait(0.1)
    end
end)
