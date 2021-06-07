Heap = {}

Citizen.CreateThread(function()
    while not Heap.ESX do
        Heap.ESX = exports["es_extended"]:getSharedObject()

        Citizen.Wait(100)
    end

    Initialized()
end)

Citizen.CreateThread(function()
    while true do
        local sleepThread = 5000

        local newPed = PlayerPedId()

        if Heap.Ped ~= newPed then
            Heap.Ped = newPed
        end

        Citizen.Wait(sleepThread)
    end
end)

Citizen.CreateThread(function()
    Citizen.Wait(50)

    while true do
        local sleepThread = 500

        local ped = Heap.Ped
        local pedLocation = GetEntityCoords(ped)

        local dstCheck = #(pedLocation - Shop.Barber.Location)

        if dstCheck <= 6.5 and not Heap.Busy then
            if dstCheck <= 2.0 then
                sleepThread = 5

                Heap.ESX.ShowHelpNotification("Press ~INPUT_CONTEXT~ to get a makeover.")

                if IsControlJustReleased(0, 38) then
                    EnterBarber()
                end
            end

            if not Heap.Greeted then
                PlayAmbientSpeech1(Heap.Barber, "SHOP_GREET", "SPEECH_PARAMS_FORCE")

                Heap.Greeted = true
            end
        else
            if Heap.Greeted then
                Heap.Greeted = false
            end
        end


        Citizen.Wait(sleepThread)
    end
end)