--            ____
--           / __ )____  _____
--          / __  / __ \/ ___/
--         / /_/ / /_/ (__  )
--        /_____/\____/____/
--
--      Invasion - Battle of Survival
--       A GPL'd futuristic RTS game
--
--      network.lua - The multiplayer UI.
--
--      (c) Copyright 2005-2006 by François Beerten
--
--      This program is free software; you can redistribute it and/or modify
--      it under the terms of the GNU General Public License as published by
--      the Free Software Foundation; only version 2 of the License.
--
--      This program is distributed in the hope that it will be useful,
--      but WITHOUT ANY WARRANTY; without even the implied warranty of
--      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--      GNU General Public License for more details.
--
--      You should have received a copy of the GNU General Public License
--      along with this program; if not, write to the Free Software
--      Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
--      02111-1307, USA.
--
--      $Id: guichan.lua 305 2005-12-18 13:36:42Z feb $

-- TODO: 
--  * lua cleanup
--  * abort (exit)
--  * network errors
--  * load and store LocalPlayerName from/in preferences2.lua

function bool2int(boolvalue)
  if boolvalue == true then
    return 1
  else
    return 0
  end
end

function int2bool(int)
  if int == 0 then
    return false
  else
    return true
  end
end

function ErrorMenu(errmsg)
  local menu

  menu = BosMenu(_("Error"))

  local l = MultiLineLabel(errmsg)
  l:setFont(Fonts["large"])
  l:setAlignment(MultiLineLabel.CENTER)
  l:setVerticalAlignment(MultiLineLabel.CENTER)
  l:setLineWidth(340)
  l:setWidth(340)
  l:setHeight(200)
  l:setBackgroundColor(dark)
  menu:add(l, Video.Width / 2 - 170, Video.Height / 2 - 100)

  menu:run()
end

function addPlayersList(menu, numplayers)
  local i
  local players_name = {}
  local players_state = {}
  local sx = Video.Width / 20
  local sy = Video.Height / 20
  local numplayers_text

  menu:writeLargeText(_("Players"), sx * 11, sy*3)
  for i=1,8 do
    players_name[i] = menu:writeText("Player"..i, sx * 11, sy*4 + i*18)
    players_state[i] = menu:writeText("Preparing", sx * 11 + 80, sy*4 + i*18)
  end
  numplayers_text = menu:writeText("Open slots : " .. numplayers - 1, sx *11, sy*4 + 144)

  local function updatePlayers()
    local connected_players = 0
    local ready_players = 0
    players_state[1]:setCaption("Creator")
    players_name[1]:setCaption(Hosts[0].PlyName)
    for i=2,8 do
      if Hosts[i-1].PlyName == "" then
        players_name[i]:setCaption("")
        players_state[i]:setCaption("")
      else
        connected_players = connected_players + 1
        if ServerSetupState.Ready[i-1] == 1 then
          ready_players = ready_players + 1
          players_state[i]:setCaption("Ready")    
        else
          players_state[i]:setCaption("Preparing")
        end
        players_name[i]:setCaption(Hosts[i-1].PlyName)
     end
    end
    numplayers_text:setCaption("Open slots : " .. numplayers - 1 - connected_players)
    return (connected_players > 0 and ready_players == connected_players)
  end

  return updatePlayers
end


joincounter = 0

function RunJoiningMapMenu(s)
  local menu
  local listener  
  local sx = Video.Width / 20
  local sy = Video.Height / 20
  local numplayers = 3
  local state

  menu = BosMenu(_("Joining game: Map"))

  menu:writeLargeText(_("Map"), sx, sy*3)
  menu:writeText(_("File:"), sx, sy*3+30)
  maptext = menu:writeText(NetworkMapName, sx+50, sy*3+30)
  maptext:setWidth(sx * 9 - 50 - 20)
  menu:writeText(_("Players:"), sx, sy*3+50)
  players = menu:writeText(numplayers, sx+70, sy*3+50)
  menu:writeText(_("Description:"), sx, sy*3+70)
  descr = menu:writeText("Unknown map", sx+20, sy*3+90)
  descr:setWidth(sx * 9 - 20 - 20)

  local fow = menu:addCheckBox(_("Fog of war"), sx, sy*3+120, function() end)
  fow:setMarked(true)
  ServerSetupState.FogOfWar = 1
  fow:setEnabled(false)
  local revealmap = menu:addCheckBox(_("Reveal map"), sx, sy*3+150, function() end)
  revealmap:setEnabled(false)
  
  menu:writeText(_("Difficulty:"), sx, sy*11)
  local difficulty = menu:addDropDown({_("easy"), _("normal"), _("hard")}, sx + 90, sy*11 + 7,
    function(dd) end)
  difficulty:setEnabled(false)
  menu:writeText(_("Map richness:"), sx, sy*11+25)
  local richness = menu:addDropDown({_("high"), _("normal"), _("low")}, sx + 110, sy*11+25 + 7,
    function(dd) end)
  richness:setEnabled(false)
  menu:writeText(_("Starting resources:"), sx, sy*11+50)
  local resources = menu:addDropDown({_("high"), _("normal"), _("low")}, sx + 150, sy*11+50 + 7,
    function(dd) end)
  resources:setEnabled(false)

  local OldPresentMap = PresentMap
  PresentMap = function(description, nplayers, w, h, id)
    print(description)
    players:setCaption(""..nplayers)
    descr:setCaption(description)
    numplayers = nplayers
    OldPresentMap(description, nplayers, w, h, id)
  end

  -- Security: The map name is checked by the stratagus engine.
  Load(NetworkMapName)
  local function readycb(dd)
     LocalSetupState.Ready[NetLocalHostsSlot] = bool2int(dd:isMarked())
  end
  menu:addCheckBox(_("~!Ready"), sx*11,  sy*14, readycb)

  local updatePlayersList = addPlayersList(menu, numplayers)

  joincounter = 0
  local function listen()
    NetworkProcessClientRequest()
    fow:setMarked(int2bool(ServerSetupState.FogOfWar))
    GameSettings.NoFogOfWar = not int2bool(ServerSetupState.FogOfWar)
    revealmap:setMarked(int2bool(ServerSetupState.RevealMap))
    GameSettings.RevealMap = ServerSetupState.RevealMap
    difficulty:setSelected((5 - ServerSetupState.Difficulty) / 2)
    GameSettings.Difficulty = ServerSetupState.Difficulty
    richness:setSelected((5 - ServerSetupState.MapRichness) / 2)
    GameSettings.MapRichness = ServerSetupState.MapRichness
    resources:setSelected((5 - ServerSetupState.ResourcesOption) / 2)
    GameSettings.Resources = ServerSetupState.ResourcesOption
    updatePlayersList()
    state = GetNetworkState()
    -- FIXME: don't use numbers
    if (state == 15) then -- ccs_started, server started the game
      SetThisPlayer(1)
      joincounter = joincounter + 1
      if (joincounter == 30) then
        SetFogOfWar(fow:isMarked())
        if revealmap:isMarked() == true then
          RevealMap()
        end
        NetworkGamePrepareGameSettings()
        AllowAllUnits()
        RunMap(NetworkMapName)
        PresentMap = OldPresentMap
        menu:stop()
      end
    elseif (state == 10) then -- ccs_unreachable
      ErrorMenu(_("Cannot reach server"))
      menu:stop(1)
    end
  end
  listener = LuaActionListener(listen)
  menu:addLogicCallback(listener)
  menu:run()
end

function RunJoiningGameMenu(s)
  local menu
  local x = Video.Width/2 - 100
  local listener
  local state
  local percent = 0

  menu = BosMenu(_("Joining game"))

  local sb = StatBoxWidget(300, 30)
  sb:setCaption("Connecting ...")
  sb:setPercent(0)
  menu:add(sb, x-50, Video.Height/2)
  sb:setBackgroundColor(dark)

  local function checkconnection() 
    NetworkProcessClientRequest()
    percent = percent + 100 / (24 * GetGameSpeed()) -- 24 seconds * fps
    sb:setPercent(percent)
    state = GetNetworkState()
    -- FIXME: do not use numbers
    if (state == 3) then -- ccs_mapinfo
      -- got ICMMap => load map
      RunJoiningMapMenu()
      menu:stop()
    elseif (state == 4) then -- ccs_badmap
      ErrorMenu(_("Map not available"))
      menu:stop(1)
    elseif (state == 10) then -- ccs_unreachable
      ErrorMenu(_("Cannot reach server"))
      menu:stop(1)
    elseif (state == 12) then -- ccs_nofreeslots
      ErrorMenu(_("Server is full"))
      menu:stop(1)
    elseif (state == 13) then -- ccs_serverquits
      ErrorMenu(_("Server gone"))
      menu:stop(1)
    elseif (state == 16) then -- ccs_incompatibleengine
      ErrorMenu(_("Incompatible engine version"))
      menu:stop(1)
    elseif (state == 17) then -- ccs_incompatiblenetwork
      ErrorMenu(_("Incompatible netowrk version"))
      menu:stop(1)
    end
  end
  listener = LuaActionListener(checkconnection)
  menu:addLogicCallback(listener)
  menu:run()
end

function RunJoinIpMenu()
  local menu
  local server
  local x = Video.Width/2 - 100

  menu = BosMenu(_("Enter Server address"))
  menu:writeText(_("IP or server name :"), x, Video.Height*8/20)
  server = menu:addTextInputField("localhost", x + 90, Video.Height*9/20 + 4)
  menu:addButton(_("~!Join Game"), "j", x,  Video.Height*10/20, 
    function(s) 
      -- FIXME: allow port ("localhost:1234")
      if (NetworkSetupServerAddress(server:getText()) ~= 0) then
        ErrorMenu(_("Invalid server name"))
        return
      end
      NetworkInitClientConnect() 
      if (RunJoiningGameMenu() ~= 0) then
        -- connect failed, don't leave this menu
        return
      end
      menu:stop() 
    end
  )
  menu:run()
end

function RunServerMultiGameMenu(map, description, numplayers)
  local menu
  local sx = Video.Width / 20
  local sy = Video.Height / 20
  local startgame

  menu = BosMenu(_("Create MultiPlayer game"))

  menu:writeLargeText(_("Map"), sx, sy*3)
  menu:writeText(_("File:"), sx, sy*3+30)
  maptext = menu:writeText(map, sx+50, sy*3+30)
  maptext:setWidth(sx * 9 - 50 - 20)
  menu:writeText(_("Players:"), sx, sy*3+50)
  players = menu:writeText(numplayers, sx+70, sy*3+50)
  menu:writeText(_("Description:"), sx, sy*3+70)
  descr = menu:writeText(description, sx+20, sy*3+90)
  descr:setWidth(sx * 9 - 20 - 20)

  local function fowCb(dd)
    ServerSetupState.FogOfWar = bool2int(dd:isMarked()) 
    NetworkServerResyncClients()
    GameSettings.NoFogOfWar = not dd:isMarked()
  end
  local fow = menu:addCheckBox(_("Fog of war"), sx, sy*3+120, fowCb)
  fow:setMarked(true)
  local function revealMapCb(dd)
    ServerSetupState.RevealMap = bool2int(dd:isMarked()) 
    NetworkServerResyncClients()
    GameSettings.RevealMap = bool2int(dd:isMarked())
  end
  local revealmap = menu:addCheckBox(_("Reveal map"), sx, sy*3+150, revealMapCb)
  
  menu:writeText(_("Difficulty:"), sx, sy*11)
  menu:addDropDown({_("easy"), _("normal"), _("hard")}, sx + 90, sy*11 + 7,
    function(dd)
      GameSettings.Difficulty = 5 - dd:getSelected()*2
      ServerSetupState.Difficulty = GameSettings.Difficulty
      NetworkServerResyncClients()
    end)
  menu:writeText(_("Map richness:"), sx, sy*11+25)
  menu:addDropDown({_("high"), _("normal"), _("low")}, sx + 110, sy*11+25 + 7,
    function(dd)
      GameSettings.MapRichness = 5 - dd:getSelected()*2
      ServerSetupState.MapRichness = GameSettings.MapRichness
      NetworkServerResyncClients()
    end)
  menu:writeText(_("Starting resources:"), sx, sy*11+50)
  menu:addDropDown({_("high"), _("normal"), _("low")}, sx + 150, sy*11+50 + 7,
    function(dd)
      GameSettings.Resources = 5 - dd:getSelected()*2
      ServerSetupState.ResourcesOption = GameSettings.Resources
      NetworkServerResyncClients()
    end)

  local updatePlayers = addPlayersList(menu, numplayers)

  NetworkMapName = map
  NetworkInitServerConnect()
  ServerSetupState.FogOfWar = 1
  ServerSetupState.Difficulty = 5
  ServerSetupState.MapRichness = 5
  ServerSetupState.ResourcesOption = 5
  startgame = menu:addButton(_("~!Start Game"), "s", sx * 11,  sy*14, 
    function(s)    
      SetFogOfWar(fow:isMarked())
      if revealmap:isMarked() == true then
        RevealMap()
      end
      NetworkServerStartGame() 
      NetworkGamePrepareGameSettings()
      AllowAllUnits()
      RunMap(map)
      menu:stop()
    end
  )
  startgame:setVisible(false)
  local waitingtext = menu:writeText(_("Waiting for players"), sx*11, sy*14)
  local function updateStartButton(ready) 
    startgame:setVisible(ready)
    waitingtext:setVisible(not ready)
  end

  local listener = LuaActionListener(function(s) updateStartButton(updatePlayers()) end)
  menu:addLogicCallback(listener)
  menu:run()
end

function RunCreateMultiGameMenu(s)
  local menu
  local map = _("No Map")
  local description = _("No map")
  local mapfile = "maps/islandwar.smp"
  local numplayers = 3
  local sx = Video.Width / 20
  local sy = Video.Height / 20

  menu = BosMenu(_("Create MultiPlayer game"))

  menu:writeText(_("File:"), sx, sy*3+30)
  maptext = menu:writeText(mapfile, sx+50, sy*3+30)
  maptext:setWidth(sx * 9 - 50 - 20)
  menu:writeText(_("Players:"), sx, sy*3+50)
  players = menu:writeText(numplayers, sx+70, sy*3+50)
  menu:writeText(_("Description:"), sx, sy*3+70)
  descr = menu:writeText(description, sx+20, sy*3+90)
  descr:setWidth(sx * 9 - 20 - 20)

  local OldPresentMap = PresentMap
  PresentMap = function(desc, nplayers, w, h, id)
    print(description)
    numplayers = nplayers
    players:setCaption(""..numplayers)
    players:adjustSize()
    description = desc
    descr:setCaption(description)
    OldPresentMap(description, nplayers, w, h, id)
  end

  Load(mapfile)
  local browser = menu:addBrowser("maps/", "^.*%.smp$", sx*10, sy*2+20, sx*8, sy*11)
  local function cb(s)
    mapfile = "maps/" .. browser:getSelectedItem()
    print(browser:getSelectedItem())
    Load(mapfile)
    maptext:setCaption(mapfile)
  end
  browser:setActionCallback(cb)
  
  menu:addButton(_("~!Create Game"), "c", sx,  sy*11, 
    function(s)    
      print (description)
      RunServerMultiGameMenu(mapfile, description, numplayers)
      menu:stop()
    end
  )
  menu:run()
  PresentMap = OldPresentMap
end

function RunMultiPlayerMenu(s)
  local menu
  local b
  local x = Video.Width/2 - 100
  local nick

  menu = BosMenu(_("MultiPlayer"))

  menu:writeText(_("Nickname :"), x, Video.Height*8/20)
  nick = menu:addTextInputField(GetLocalPlayerName(), x + 90, Video.Height*8/20 + 4)

  ResetMapOptions()
  InitNetwork1()
  menu:addButton(_("~!Join Game"), "j", x, Video.Height*11/20, 
    function(s)
      if nick:getText() ~= GetLocalPlayerName() then
        SetLocalPlayerName(nick:getText())
        preferences.PlayerName = nick:getText()
        SavePreferences()
      end
      RunJoinIpMenu()
      menu:stop(1)
    end)
  menu:addButton(_("~!Create Game"), "c", x, Video.Height*12/20, 
    function(s)
      if nick:getText() ~= GetLocalPlayerName() then
        SetLocalPlayerName(nick:getText())
        preferences.PlayerName = nick:getText()
        SavePreferences()
      end
      RunCreateMultiGameMenu()
      menu:stop(1)
    end)

  menu:run()
  ExitNetwork1()
end

