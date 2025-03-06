local config = require 'config.server'

local function removeHungerAndThirst(src, player)
    local playerState = Player(src).state
    if not playerState.isLoggedIn then return end
    local newHunger = playerState.hunger - config.player.hungerRate
    local newThirst = playerState.thirst - config.player.thirstRate

    player.Functions.SetMetaData('thirst', math.max(0, newThirst))
    player.Functions.SetMetaData('hunger', math.max(0, newHunger))

    player.Functions.Save()
end

CreateThread(function()
    local interval = 60000 * config.updateInterval
    while true do
        Wait(interval)
        for src, player in pairs(QBX.Players) do
            removeHungerAndThirst(src, player)
        end
    end
end)

local function pay(player)
    local job = player.PlayerData.job
    local payment = GetJob(job.name).grades[job.grade.level].payment or job.payment
    if payment <= 0 then return end
    if not GetJob(job.name).offDutyPay and not job.onduty then return end

    if not config.money.paycheckSociety then
        exports.pefcl:addBankBalance(player.PlayerData.source, { amount = payment, message = 'PAYCHECK' })
        return
    end

    local societyBalance = exports.pefcl:getTotalBankBalanceByIdentifier(player.PlayerData.source, job.name)
    if not societyBalance or societyBalance < payment then
        Notify(player.PlayerData.source, locale('error.company_too_poor'), 'error')
        return
    end

    exports.pefcl:removeBankBalanceByIdentifier(player.PlayerData.source, { identifier = job.name, amount = payment, message = 'RETIRADA' })
    exports.pefcl:addBankBalance(player.PlayerData.source, { amount = payment, message = 'PAYCHECK' })
end

CreateThread(function()
    local interval = 60000 * config.money.paycheckTimeout
    while true do
        Wait(interval)
        for _, player in pairs(QBX.Players) do
            pay(player)
        end
    end
end)
