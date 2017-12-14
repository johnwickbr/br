Citizen.CreateThread(function()
  SetRandomSeed(GetNetworkTime())

  -- Disable money displaying
  DisplayCash(true)

  -- Disable health regeneration
  SetPlayerHealthRechargeMultiplier(PlayerId(), 0)

  -- Draw Discord in menu
  Citizen.InvokeNative(GetHashKey("ADD_TEXT_ENTRY"), 'FE_THDR_GTAO', 'Sunset Survivor Battle Royale V Reborn | '..conf.discordUrl)

  local isRadarExtended = false

  while true do
    Citizen.Wait(0)

    -- Extended Radar
    if IsControlJustReleased(0, 20) then
      isRadarExtended = not isRadarExtended
      Citizen.InvokeNative(0x231C8F89D0539D8F, isRadarExtended, false)
    end

    -- Infinite stamina
    ResetPlayerStamina(PlayerId())
  end
end)

-- Auto restart
Citizen.CreateThread(function()
  local countdown = 0
  local gameEndedAt = nil
  local timeDiff = 0

  while true do
    Wait(0)
    if getIsGameEnded() then
      if not gameEndedAt then gameEndedAt = GetGameTimer() end

      timeDiff = GetTimeDifference(GetGameTimer(), gameEndedAt)
      countdown = conf.autostartTimer - tonumber(round(timeDiff / 1000))

      showText('LA PROCHAINE BATTLE COMMENCE DANS ' .. countdown .. 's', 0.43, 0.135, conf.color.red)

      if countdown < 0 then
        setGameEnded(false)
        gameEndedAt = nil
        TriggerServerEvent('brv:startGame')
      end
    else
      gameEndedAt = nil
    end
  end
end)

-- Set weather and time
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(33)

    NetworkOverrideClockTime(conf.time.hours, conf.time.minutes, conf.time.seconds)

    SetWeatherTypePersist(conf.weather)
    SetWeatherTypeNowPersist(conf.weather)
    SetWeatherTypeNow(conf.weather)
    SetOverrideWeather(conf.weather)
  end
end)

-- Print a clock top left and number of players remaining
Citizen.CreateThread(function()
  local message = ''

  while true do
    Wait(0)

    local h = GetClockHours()
    local m = GetClockMinutes()
    if m < 10 then
      m = '0' .. m
    end
    if h < 10 then
      h = '0' .. h
    end
    showText(h .. ':' .. m, 0.005, 0.05)

    if getIsGameStarted() then
      message = 'Survivants restants : ' .. getPlayersRemaining()
    else
      if getIsGameEnded() then
        message = 'La battle commence bientot...'
      else
        message = 'ATTENTE DE '..getPlayersRemainingToAutostart()..' JOUEURS POUR COMMENCER LA BATTLE...'
        showText('Taper /vote pour commencer immediatement', 0.42, 0.075, conf.color.green)
      end
    end

    showText(message, 0.005, 0.075, conf.color.white)

    if isPlayerInLobby() and not isPlayerInSpectatorMode() then
      if getIsGameStarted() then
        showText('UNE BATTLE EST EN COURS', 0.441, 0.075, conf.color.red)
        showText('Vous pouvez observer la battle en cours sur la TV', 0.395, 0.11, conf.color.grey)
      end
    end
  end
end)

-- Check pickup collection
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(50)

    if getIsGameStarted() then
      if NetworkIsPlayerActive(PlayerId()) then
        for i, pickup in pairs(getPickups()) do
          if HasPickupBeenCollected(pickup.id) then
            showNotification('Picked up '..pickup.name)

            SetBlipColour(getPickupBlips()[i], 20)

            TriggerEvent('brv:removePickup', i)
            TriggerServerEvent('brv:pickupCollected', i)
          end
        end
      end
    end
  end
end)

-- Auto respawning after 10 seconds
local diedAt
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(0)

    local playerPed = GetPlayerPed(-1)

    if playerPed and playerPed ~= -1 then
      if NetworkIsPlayerActive(PlayerId()) then
        if (diedAt and (GetTimeDifference(GetGameTimer(), diedAt) > 10000)) then
          exports.spawnmanager:spawnPlayer(false, function()
            getLocalPlayer().skin = changeSkin(getLocalPlayer().skin)
          end)
        end
      end

      if IsEntityDead(playerPed) then
        if not diedAt then
          diedAt = GetGameTimer()
        end
      else
        diedAt = nil
      end
    end
  end
end)