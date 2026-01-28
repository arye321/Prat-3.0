---------------------------------------------------------------------------------
--
-- Prat - A framework for World of Warcraft chat mods
--
-- Copyright (C) 2006-2018  Prat Development Team
--
-- This program is free software; you can redistribute it and/or
-- modify it under the terms of the GNU General Public License
-- as published by the Free Software Foundation; either version 2
-- of the License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to:
--
-- Free Software Foundation, Inc.,
-- 51 Franklin Street, Fifth Floor,
-- Boston, MA  02110-1301, USA.
--
--
-------------------------------------------------------------------------------

Prat:AddModuleToLoad(function()

  local PRAT_MODULE = Prat:RequestModuleName("GuildMark")

  if PRAT_MODULE == nil then
    return
  end

  local module = Prat:NewModule(PRAT_MODULE, "AceEvent-3.0")

  local PL = module.PL

  --[==[@debug@
  PL:AddLocale(PRAT_MODULE, "enUS", {
    ["GuildMark"] = true,
    ["Adds a marker symbol to guild members in chat."] = true,
    ["Mark Symbol"] = true,
    ["The symbol to add before guild member names."] = true,
    ["Mark Color"] = true,
    ["Color of the guild mark symbol."] = true,
    ["Show in All Channels"] = true,
    ["Show the guild mark in all chat channels, not just guild chat."] = true,
    ["Exclude Guild Chat"] = true,
    ["Do not show the guild mark in guild and officer chat."] = true,
    ["Exclude Self"] = true,
    ["Do not show the guild mark on your own name."] = true,
  })
  --@end-debug@]==]

  -- These Localizations are auto-generated. To help with localization
  -- please go to http://www.wowace.com/projects/prat-3-0/localization/

  --@non-debug@
  do
    local L

    L = {
      ["GuildMark"] = {
        ["GuildMark"] = true,
        ["Adds a marker symbol to guild members in chat."] = true,
        ["Mark Symbol"] = true,
        ["The symbol to add before guild member names."] = true,
        ["Mark Color"] = true,
        ["Color of the guild mark symbol."] = true,
        ["Show in All Channels"] = true,
        ["Show the guild mark in all chat channels, not just guild chat."] = true,
        ["Exclude Guild Chat"] = true,
        ["Do not show the guild mark in guild and officer chat."] = true,
        ["Exclude Self"] = true,
        ["Do not show the guild mark on your own name."] = true,
      }
    }

    PL:AddLocale(PRAT_MODULE, "enUS", L)

    -- Add empty locales for other languages
    PL:AddLocale(PRAT_MODULE, "itIT", L)
    PL:AddLocale(PRAT_MODULE, "ptBR", L)
    PL:AddLocale(PRAT_MODULE, "frFR", L)
    PL:AddLocale(PRAT_MODULE, "deDE", L)
    PL:AddLocale(PRAT_MODULE, "koKR", L)
    PL:AddLocale(PRAT_MODULE, "esMX", L)
    PL:AddLocale(PRAT_MODULE, "ruRU", L)
    PL:AddLocale(PRAT_MODULE, "zhCN", L)
    PL:AddLocale(PRAT_MODULE, "esES", L)
    PL:AddLocale(PRAT_MODULE, "zhTW", L)
  end
  --@end-non-debug@

  -- Guild member cache
  module.GuildMembers = {}

  -- Default settings
  Prat:SetModuleDefaults(module.name, {
    profile = {
      on = true,
      markSymbol = "(g)",
      markColor = { r = 0.25, g = 1.0, b = 0.25 },
      allChannels = true,
      excludeGuildChat = false,
      excludeSelf = true,
    }
  })

  -- Module options
  Prat:SetModuleOptions(module.name, {
    name = PL["GuildMark"],
    desc = PL["Adds a marker symbol to guild members in chat."],
    type = "group",
    args = {
      markSymbol = {
        name = PL["Mark Symbol"],
        desc = PL["The symbol to add before guild member names."],
        type = "input",
        order = 110,
        get = function() return module.db.profile.markSymbol end,
        set = function(info, v) module.db.profile.markSymbol = v end,
      },
      markColor = {
        name = PL["Mark Color"],
        desc = PL["Color of the guild mark symbol."],
        type = "color",
        order = 120,
        get = function()
          local c = module.db.profile.markColor
          return c.r, c.g, c.b
        end,
        set = function(info, r, g, b)
          module.db.profile.markColor = { r = r, g = g, b = b }
        end,
      },
      allChannels = {
        name = PL["Show in All Channels"],
        desc = PL["Show the guild mark in all chat channels, not just guild chat."],
        type = "toggle",
        order = 130,
        get = function() return module.db.profile.allChannels end,
        set = function(info, v) module.db.profile.allChannels = v end,
      },
      excludeGuildChat = {
        name = PL["Exclude Guild Chat"],
        desc = PL["Do not show the guild mark in guild and officer chat."],
        type = "toggle",
        order = 140,
        get = function() return module.db.profile.excludeGuildChat end,
        set = function(info, v) module.db.profile.excludeGuildChat = v end,
      },
      excludeSelf = {
        name = PL["Exclude Self"],
        desc = PL["Do not show the guild mark on your own name."],
        type = "toggle",
        order = 150,
        get = function() return module.db.profile.excludeSelf end,
        set = function(info, v) module.db.profile.excludeSelf = v end,
      },
    }
  })

  --[[------------------------------------------------
    Module Event Functions
  ------------------------------------------------]] --

  -- This function is a wrapper for the Blizzard GuildRoster function
  function module.GuildRoster()
    if C_GuildInfo and C_GuildInfo.GuildRoster then
      return C_GuildInfo.GuildRoster()
    elseif GuildRoster then
      return GuildRoster()
    end
  end

  function module:OnModuleEnable()
    -- Register for Prat chat events
    Prat.RegisterChatEvent(self, "Prat_FrameMessage")

    -- Register for guild roster updates
    self:RegisterEvent("GUILD_ROSTER_UPDATE", "UpdateGuildMembers")
    self:RegisterEvent("PLAYER_GUILD_UPDATE", "UpdateGuildMembers")

    -- Initial guild roster request
    if IsInGuild() then
      self.GuildRoster()
      self:UpdateGuildMembers()
    end
  end

  function module:OnModuleDisable()
    Prat.UnregisterAllChatEvents(self)
    self:UnregisterAllEvents()
    wipe(self.GuildMembers)
  end

  --[[------------------------------------------------
    Core Functions
  ------------------------------------------------]] --

  function module:GetDescription()
    return PL["Adds a marker symbol to guild members in chat."]
  end

  -- Update the guild member cache
  function module:UpdateGuildMembers()
    wipe(self.GuildMembers)

    if not IsInGuild() then
      return
    end

    local numMembers = GetNumGuildMembers()
    for i = 1, numMembers do
      local name = GetGuildRosterInfo(i)
      if name then
        -- Remove server suffix for comparison
        local playerName = name:match("([^%-]+)")
        if playerName then
          self.GuildMembers[playerName:lower()] = true
        end
        -- Also store with server name for cross-realm support
        self.GuildMembers[name:lower()] = true
      end
    end
  end

  -- Check if a player is in the guild
  function module:IsGuildMember(name)
    if not name or name == "" then
      return false
    end

    -- Check both with and without server suffix
    local lowerName = name:lower()
    if self.GuildMembers[lowerName] then
      return true
    end

    -- Try without server suffix
    local playerName = name:match("([^%-]+)")
    if playerName and self.GuildMembers[playerName:lower()] then
      return true
    end

    return false
  end

  -- Get the colored mark symbol
  function module:GetColoredMark()
    local c = self.db.profile.markColor
    local symbol = self.db.profile.markSymbol
    return string.format("|cff%02x%02x%02x%s|r", c.r * 255, c.g * 255, c.b * 255, symbol)
  end

  -- Events that should show guild marks when allChannels is false
  local GUILD_EVENTS = {
    ["CHAT_MSG_GUILD"] = true,
    ["CHAT_MSG_OFFICER"] = true,
    ["CHAT_MSG_GUILD_ACHIEVEMENT"] = true,
  }

  -- Process chat messages
  function module:Prat_FrameMessage(info, message, frame, event)
    if not self.db.profile.on then
      return
    end

    -- Check if we should process this event
    if not self.db.profile.allChannels and not GUILD_EVENTS[event] then
      return
    end

    -- Exclude from guild chat if option is enabled
    if self.db.profile.excludeGuildChat and (event == "CHAT_MSG_GUILD" or event == "CHAT_MSG_OFFICER") then
      return
    end

    -- Get the player name from the message
    local playerName = message.PLAYERLINK or message.PLAYER
    if not playerName or playerName == "" then
      return
    end

    -- Use Ambiguate for proper name comparison
    playerName = Ambiguate(playerName, "all")

    -- Check if the player is a guild member
    if self:IsGuildMember(playerName) then
      -- Exclude self if option is enabled
      if self.db.profile.excludeSelf and playerName == UnitName("player") then
        return
      end

      -- Add the guild mark before the player name
      message.PLAYER = self:GetColoredMark() .. message.PLAYER
    end
  end

  return
end) -- Prat:AddModuleToLoad
