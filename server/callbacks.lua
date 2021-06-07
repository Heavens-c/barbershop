Citizen.CreateThread(function()
    Heap.ESX.RegisterServerCallback("james_barbershop:fetchBusyState", function(source, callback)
        local player = Heap.ESX.GetPlayerFromId(source)

        if not player then return callback(false) end

        callback(Heap.Busy)
    end)
end)