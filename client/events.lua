RegisterNetEvent("esx:playerLoaded")
AddEventHandler("esx:playerLoaded", function(response)
    Heap.ESX.PlayerData = response

    FetchBusyState()
end)

RegisterNetEvent("james_barbershop:eventHandler")
AddEventHandler("james_barbershop:eventHandler", function(eventName, eventData)
    if eventName == "CHAIR_BUSY" then
        Heap.Busy = eventData
    elseif eventName == "SYNC_ANIMATION" then
        local animName = eventData.Animation
        local sceneHash = eventData.SceneHash
        local sceneLooped = eventData.Looped or false
        local clearTasks = eventData.ClearTasks or false

        if DoesEntityExist(Heap.Barber) then
            PlayDresserAnimation(Heap.Barber, animName, sceneHash, sceneLooped, clearTasks)
        end
    elseif eventName == "SYNC_PARTICLE" then
        local ped = NetToPed(eventData.Net)
        local phase = GetSynchronizedScenePhase(Heap.Scene)

        while phase < 1.0 do
            phase = GetSynchronizedScenePhase(Heap.Scene)

            if phase > .60 then
                if Heap.SoundPlaying then
                    StopSound(Heap.SoundPlaying)

                    if DoesParticleFxLoopedExist(Heap.Particle) then
                        StopParticleFxLooped(Heap.Particle, 0)
                    end

                    Heap.SoundPlaying = false

                    if ped == Heap.Ped then
                        TriggerEvent("skinchanger:loadSkin", eventData.Skin)
                    end
                end
            elseif phase > .30 then
                if not Heap.SoundPlaying then
                    Heap.SoundPlaying = GetSoundId()

                    if ped == Heap.Ped then
                        while not HasNamedPtfxAssetLoaded("scr_barbershop") do
                            Citizen.Wait(0)

                            RequestNamedPtfxAsset("scr_barbershop")
                        end

                        UseParticleFxAsset("scr_barbershop")

                        Heap.Particle = StartParticleFxLoopedOnPedBone("scr_barbers_haircut", ped, 0.0, 0.0, 0.1, 0.0, 0.0, 0.0, 31086, 1065353216, 0, 0, 0)

                        SetParticleFxLoopedColour(Heap.Particle, 210, 105, 30, 0)
                    end

                    PlaySoundFromEntity(Heap.SoundPlaying, "Scissors", ped, "Barber_Sounds", false, 0)
                end
            end

            Citizen.Wait(0)
        end
    end
end)

AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        if DoesEntityExist(Heap.Barber) then
            DeleteEntity(Heap.Barber)
        end

        if DoesEntityExist(Heap.Scissors) then
            DeleteEntity(Heap.Scissors)
        end
    end
end)