Initialized = function()
    CreateBarber()
end

GlobalFunction = function(eventName, eventData)
    local globalOptions = {
        Event = eventName,
        Data = eventData
    }
    TriggerServerEvent("james_barbershop:globalEvent", globalOptions)
end

FetchBusyState = function()
    Heap.ESX.TriggerServerCallback("james_barbershop:fetchBusyState", function(busyState)
        Heap.Busy = busyState
    end)
end

CreateBarber = function()
    local barber = Shop.Barber
    local scissors = Shop.Scissors

    local barberBlip = AddBlipForCoord(barber.Location)

    SetBlipSprite(barberBlip, 71)
    SetBlipScale(barberBlip, 0.8)
    SetBlipColour(barberBlip, 2)
    SetBlipAsShortRange(barberBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Hairdresser")
    EndTextCommandSetBlipName(barberBlip)

    LoadModels({
        barber.Model,
        scissors.Model
    })

    Heap.Barber = CreatePed(5, barber.Model, barber.Location, barber.Heading, false)
    Heap.Scissors = CreateObject(scissors.Model, scissors.Location)

    Heap.Cam = CreateCam("DEFAULT_ANIMATED_CAMERA", false)

    SetPedDefaultComponentVariation(Heap.Barber)
    TaskSetBlockingOfNonTemporaryEvents(Heap.Barber, true)

    CleanupModels({
        barber.Model,
        scissors.Model
    })
end

EnterBarber = function()
    LoadModels({
        Default.AnimDict
    })

    DisplayRadar(false)

    GlobalFunction("CHAIR_BUSY", true)

    PlayCamAnimation("cam_enterchair")

    GlobalFunction("SYNC_ANIMATION", {
        Animation = "keeper_enterchair",
        SceneHash = -1056964608,
        ClearTasks = true
    })

    TaskPlayAnimAdvanced(Heap.Ped, Default.AnimDict, "player_enterchair", Shop.Scene.Location, vector3(0.0, 0.0, (Calculation(-2.6) - 90.0)), 1000.0, -1000.0, -1, 5642, 0.0, 2, 1)

    WaitForAnimation("player_enterchair")

    GlobalFunction("SYNC_ANIMATION", {
        Animation = "keeper_idle_a",
        SceneHash = -1056964608,
        Looped = true
    })

    ChooseHaircut()

    CleanupModels({
        Default.AnimDict
    })
end

ChooseHaircut = function()
    TriggerEvent("skinchanger:getSkin", function(skin)
        Heap.LastSkin = json.encode(skin)
        Heap.NewSkin = skin
    end)

    local maxValues = GetMaxValues()

    local currentComponent = 1

    while true do
        Citizen.Wait(0)

        local helpText = "~INPUT_FRONTEND_RRIGHT~ Exit Chair (Changes will be undone)~n~~n~~INPUT_FRONTEND_UP~ ~INPUT_FRONTEND_DOWN~ Change Component~n~~INPUT_FRONTEND_LEFT~ ~INPUT_FRONTEND_RIGHT~ Change Value~n~~n~~INPUT_FRONTEND_RDOWN~ Complete (~g~" .. Shop.Price .. "~s~:-)~n~~n~"

        if IsControlJustReleased(0, 194) then
            return ExitChair()
        elseif IsControlJustReleased(0, 188) then
            currentComponent = currentComponent - 1 < 1 and #Shop.HelpText or currentComponent - 1
        elseif IsControlJustReleased(0, 187) then
            currentComponent = currentComponent + 1 > #Shop.HelpText and 1 or currentComponent + 1
        elseif IsControlJustReleased(0, 190) then
            local componentName = Shop.HelpText[currentComponent].Component

            local maxValue = maxValues[componentName] or 0

            local currentValue = Heap.NewSkin[componentName]

            Heap.NewSkin[componentName] = currentValue + 1 > maxValue and 0 or currentValue + 1

            ApplyNewSkin()
        elseif IsControlJustReleased(0, 189) then
            local componentName = Shop.HelpText[currentComponent].Component

            local maxValue = maxValues[componentName] or 0

            local currentValue = Heap.NewSkin[componentName]

            Heap.NewSkin[componentName] = currentValue - 1 < 0 and maxValue or currentValue - 1

            ApplyNewSkin()
        elseif IsControlJustReleased(0, 191) then
            return GetHaircut()
        end

        for textIndex, textData in ipairs(Shop.HelpText) do
            helpText = helpText .. (textIndex == currentComponent and "~g~~h~" or "") .. textData.Label .. (textIndex == currentComponent and "~h~~s~" or "") .. ": " .. (Heap.NewSkin[textData.Component] or 0) .. "/" .. (maxValues[textData.Component] or 0) .. "~n~"
        end

        AddTextEntry("BARBER_INSTRUCTIONS", helpText)

        BeginTextCommandDisplayHelp("BARBER_INSTRUCTIONS")
        EndTextCommandDisplayHelp(0, false, false, -1)
    end
end

GetHaircut = function()
    ApplyLastSkin()

    PlayCamAnimation("cam_hair_cut_a")

    GlobalFunction("SYNC_ANIMATION", {
        Animation = "keeper_hair_cut_a",
        SceneHash = -1056964608,
        ClearTasks = true
    })

    TaskPlayAnimAdvanced(Heap.Ped, Default.AnimDict, "player_base", Shop.Scene.Location, vector3(0.0, 0.0, (Calculation(-2.6) - 90.0)), 1000.0, -1000.0, -1, 5643, 0.0, 2, 1)

    GlobalFunction("SYNC_PARTICLE", {
        Net = PedToNet(Heap.Ped),
        Skin = Heap.NewSkin
    })

    WaitForAnimation("keeper_hair_cut_a")

    ExitChair(true)

    TriggerServerEvent("james_barbershop:payment")
end

ExitChair = function(keepSkin)
    if not keepSkin then
        ApplyLastSkin()
    end

    PlayCamAnimation("cam_exitchair")

    GlobalFunction("SYNC_ANIMATION", {
        Animation = "keeper_exitchair",
        SceneHash = -1056964608,
        ClearTasks = true
    })

    TaskPlayAnimAdvanced(Heap.Ped, Default.AnimDict, "player_exitchair", Shop.Scene.Location, vector3(0.0, 0.0, (Calculation(-2.6) - 90.0)), 1000.0, -2.0, -1, 37896, 0.0, 2, 1)

    WaitForAnimation("player_exitchair")

    RenderScriptCams(false, true, 1000)

    DestroyAllCams(true)

    DisplayRadar(true)

    GlobalFunction("CHAIR_BUSY", false)
end

PlayDresserAnimation = function(pedHandle, animName, sceneHash, sceneLooped, clearTasks)
    local animDict = Default.AnimDict

    while not RequestAmbientAudioBank("SCRIPT\\Hair_Cut", 0) do
        Citizen.Wait(0)
    end

    LoadModels({
        animDict
    })

    if clearTasks then
        N_0xf1c03a5352243a30(pedHandle)
        ClearPedTasksImmediately(pedHandle)
    end

    local scene = CreateSynchronizedScene(Shop.Scene.Location, vector3(0.0, 0.0, (Calculation(-2.6) - 90.0)), 2)

    TaskSynchronizedScene(pedHandle, scene, animDict, animName, 1000.0, sceneHash, 0, 0, 1148846080, 0)
    SetSynchronizedSceneOcclusionPortal(scene, not sceneLooped)
    SetSynchronizedSceneLooped(scene, sceneLooped)
    N_0x2208438012482a1a(pedHandle, false, false)

    if DoesEntityExist(Heap.Scissors) then
        local scissorsAnimation = GetScissorsAnimation(animName)

        PlaySynchronizedEntityAnim(Heap.Scissors, scene, scissorsAnimation, animDict, 1000.0, -1000.0, 0, 1148846080)
        ForceEntityAiAndAnimationUpdate(Heap.Scissors)
    end

    local speech = GetSpeech(animName)

    if speech then
        PlayAmbientSpeech1(Heap.Barber, speech, "SPEECH_PARAMS_FORCE")
    end

    Heap.Scene = scene

    CleanupModels({
        animDict
    })
end

PlayCamAnimation = function(camAnimation)
    if not DoesCamExist(Heap.Cam) then
        Heap.Cam = CreateCam("DEFAULT_ANIMATED_CAMERA", false)
    end

    PlayCamAnim(Heap.Cam, camAnimation, Default.AnimDict, Shop.Scene.Location, vector3(0.0, 0.0, (Calculation(-2.6) - 90.0)), false, 2)
    SetCamActive(Heap.Cam, true)
    RenderScriptCams(true, false, 3000, true, false, false)
end

ApplyNewSkin = function()
    TriggerEvent("skinchanger:loadSkin", Heap.NewSkin)
    TriggerEvent('skinchanger:getSkin', function(skin)
    TriggerServerEvent('esx_skin:save', skin)
end)
end

ApplyLastSkin = function()
    TriggerEvent("skinchanger:loadSkin", json.decode(Heap.LastSkin), function()
        Trace("Reset appearance to last skin.")
    end)
end

GetSpeech = function(animName)
    if animName == "keeper_base" then
        return "scissors_base"
    elseif animName == "keeper_enterchair"then
        return "SHOP_HAIR_WHAT_WANT"
    elseif animName == "keeper_exitchair" then
        return "SHOP_GOODBYE"
    elseif animName == "keeper_idle_a" then
        return "SHOP_HAIR_WHAT_WANT"
    elseif animName == "keeper_idle_b" then
        return "SHOP_HAIR_WHAT_WANT"
    elseif animName == "keeper_idle_c" then
        return "SHOP_HAIR_WHAT_WANT"
    elseif animName == "keeper_hair_cut_a" then
        return "SHOP_CUTTING_HAIR"
    elseif animName == "keeper_hair_cut_b" then
        return "SHOP_CUTTING_HAIR"
    end
end

GetScissorsAnimation = function(animName)
    if animName == "keeper_base" then
        return "scissors_base"
    elseif animName == "keeper_enterchair"then
        return "scissors_enterchair"
    elseif animName == "keeper_exitchair" then
        return "scissors_exitchair"
    elseif animName == "keeper_idle_a" then
        return "scissors_idle_a"
    elseif animName == "keeper_idle_b" then
        return "scissors_idle_b"
    elseif animName == "keeper_idle_c" then
        return "scissors_idle_c"
    elseif animName == "keeper_hair_cut_a" then
        return "scissors_hair_cut_a"
    elseif animName == "keeper_hair_cut_b" then
        return "scissors_hair_cut_b"
    end
end

GetMaxValues = function()
    local data = {
        beard_1 = GetNumHeadOverlayValues(1) - 1,
        beard_2 = 10,
        beard_3 = GetNumHairColors() - 1,
        beard_4 = GetNumHairColors() - 1,
        hair_1 = GetNumberOfPedDrawableVariations(Heap.Ped, 2) - 1,
        hair_2 = GetNumberOfPedTextureVariations(Heap.Ped, 2, Heap.NewSkin.hair_1) - 1,
        hair_color_1 = GetNumHairColors() - 1,
        hair_color_2 = GetNumHairColors() - 1,
        eye_color = 31,
        eyebrows_1 = GetNumHeadOverlayValues(2) - 1,
        eyebrows_2 = 10,
        eyebrows_3 = GetNumHairColors() - 1,
        eyebrows_4 = GetNumHairColors() - 1,
        makeup_1 = GetNumHeadOverlayValues(4) - 1,
        makeup_2 = 10,
        makeup_3 = GetNumHairColors() - 1,
        makeup_4 = GetNumHairColors() - 1
    }

    return data
end

WaitForAnimation = function(animName)
    local started = GetGameTimer()

    local animDuration = (GetAnimDuration(Default.AnimDict, animName) * 1000) + 100

    while GetGameTimer() - started < animDuration do
        Citizen.Wait(0)
    end
end

Calculation = function(number)
    return number * 57.29578
end

DrawButtons = function(buttonsToDraw)
	local instructionScaleform = RequestScaleformMovie("instructional_buttons")

	while not HasScaleformMovieLoaded(instructionScaleform) do
		Wait(0)
	end

	PushScaleformMovieFunction(instructionScaleform, "CLEAR_ALL")
	PushScaleformMovieFunction(instructionScaleform, "TOGGLE_MOUSE_BUTTONS")
	PushScaleformMovieFunctionParameterBool(0)
	PopScaleformMovieFunctionVoid()

	for buttonIndex, buttonValues in ipairs(buttonsToDraw) do
		PushScaleformMovieFunction(instructionScaleform, "SET_DATA_SLOT")
		PushScaleformMovieFunctionParameterInt(buttonIndex - 1)

		PushScaleformMovieMethodParameterButtonName(buttonValues["button"])
		PushScaleformMovieFunctionParameterString(buttonValues["label"])
		PopScaleformMovieFunctionVoid()
	end

	PushScaleformMovieFunction(instructionScaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
	PushScaleformMovieFunctionParameterInt(-1)
	PopScaleformMovieFunctionVoid()
	DrawScaleformMovieFullscreen(instructionScaleform, 255, 255, 255, 255)
end

DrawBusySpinner = function(text)
    SetLoadingPromptTextEntry("STRING")
    AddTextComponentSubstringPlayerName(text)
    ShowLoadingPrompt(3)
end

PlayAnimation = function(ped, dict, anim, settings)
	if dict then
        RequestAnimDict(dict)

        while not HasAnimDictLoaded(dict) do
            Citizen.Wait(0)
        end

        if settings == nil then
            TaskPlayAnim(ped, dict, anim, 1.0, -1.0, 1.0, 0, 0, 0, 0, 0)
        else
            local speed = 1.0
            local speedMultiplier = -1.0
            local duration = 1.0
            local flag = 0
            local playbackRate = 0

            if settings["speed"] then
                speed = settings["speed"]
            end

            if settings["speedMultiplier"] then
                speedMultiplier = settings["speedMultiplier"]
            end

            if settings["duration"] then
                duration = settings["duration"]
            end

            if settings["flag"] then
                flag = settings["flag"]
            end

            if settings["playbackRate"] then
                playbackRate = settings["playbackRate"]
            end

            TaskPlayAnim(ped, dict, anim, speed, speedMultiplier, duration, flag, playbackRate, 0, 0, 0)

            while not IsEntityPlayingAnim(ped, dict, anim, 3) do
                Citizen.Wait(0)
            end
        end

        RemoveAnimDict(dict)
	else
		TaskStartScenarioInPlace(ped, anim, 0, true)
	end
end

LoadModels = function(models)
	for index, model in ipairs(models) do
		if IsModelValid(model) then
			while not HasModelLoaded(model) do
				RequestModel(model)

				Citizen.Wait(10)
			end
		else
			while not HasAnimDictLoaded(model) do
				RequestAnimDict(model)

				Citizen.Wait(10)
			end
		end
	end
end

CleanupModels = function(models)
	for index, model in ipairs(models) do
		if IsModelValid(model) then
			SetModelAsNoLongerNeeded(model)
		else
			RemoveAnimDict(model)
		end
	end
end

DrawScriptMarker = function(markerData)
    DrawMarker(markerData["type"] or 1, markerData["pos"] or vector3(0.0, 0.0, 0.0), 0.0, 0.0, 0.0, (markerData["type"] == 6 and -90.0 or markerData["rotate"] and -180.0) or 0.0, 0.0, 0.0, markerData["size"] or vector3(1.0, 1.0, 1.0), markerData["rgb"] or vector3(255, 255, 255), 100, markerData["bob"] and true or false, true, 2, false, false, false, false)
end

DrawScriptText = function(coords, text)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())

    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(_x, _y)

    local factor = (string.len(text)) / 370

    DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
end

OpenInput = function(label, type)
	AddTextEntry(type, label)

	DisplayOnscreenKeyboard(1, type, "", "", "", "", "", 30)

	while UpdateOnscreenKeyboard() == 0 do
		DisableAllControlActions(0)
		Wait(0)
	end

	if GetOnscreenKeyboardResult() then
	  	return GetOnscreenKeyboardResult()
	end
end

UUID = function()
    math.randomseed(GetGameTimer() * math.random())

    return math.random(100000, 999999)
end