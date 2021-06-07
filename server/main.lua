Heap = {}

TriggerEvent("esx:getSharedObject", function(library)
    Heap.ESX = library
end)

RegisterNetEvent("esx:playerDropped")
AddEventHandler("esx:playerDropped", function(source)
    if Heap.Busy == source then
        TriggerClientEvent("james_barbershop:eventHandler", -1, "CHAIR_BUSY", false)

        Heap.Busy = false
    end
end)

RegisterNetEvent("james_barbershop:globalEvent")
AddEventHandler("james_barbershop:globalEvent", function(eventData)
    if eventData.Event == "CHAIR_BUSY" then
        Heap.Busy = eventData and source or false
    end

    TriggerClientEvent("james_barbershop:eventHandler", -1, eventData.Event, eventData.Data)
end)

RegisterNetEvent("james_barbershop:payment")
AddEventHandler("james_barbershop:payment", function()
    local player = Heap.ESX.GetPlayerFromId(source)

    if not player then return end

    local payment = Shop.Price

    if payment > 0 then
        if player.getMoney() > payment then
            player.removeMoney(payment)
        else
            player.removeAccountMoney("bank", payment)
        end

        TriggerClientEvent("esx:showNotification", source, "You paid $" .. payment .. " to the hairdresser.")
    end
end)