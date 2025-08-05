local HttpService = game:GetService("HttpService")

local FIREBASE_URL = "https://olaaa-dc667-default-rtdb.firebaseio.com/ccc.json"

local function prints(str)
    print("[AutoJobMonitor]: " .. str)
end

local function readJobID()
    local success, response = pcall(function()
        return HttpService:GetAsync(FIREBASE_URL)
    end)

    if success and response then
        local trimmed = response:gsub('%"', ""):gsub("%s+", "")
        return trimmed ~= "" and trimmed or nil
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

-- Loop principal
task.spawn(function()
    prints("🔄 Monitor de JobID iniciado...")
    local lastJob = readJobID()

    while true do
        local newJob = readJobID()

        if newJob and newJob ~= lastJob then
            lastJob = newJob

            local gui = findTargetGui()
            if gui then
                local success = setJobIDText(gui, newJob)
                if success then
                    wait(0.1)
                    clickJoinButton(gui)
                else
                    prints("❌ Campo de texto não encontrado.")
                end
            else
                prints("❌ UI não encontrada. Aguardando próxima tentativa...")
            end
        end

        wait(0.5)
    end
end)
