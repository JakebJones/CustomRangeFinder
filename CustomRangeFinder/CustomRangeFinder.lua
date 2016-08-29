CustomRangeFinder = LibStub("AceAddon-3.0"):NewAddon("CustomRangeFinder", "AceConsole-3.0", "AceEvent-3.0","AceTimer-3.0")

local CRF_UpdateInterval = 0
local CRF_SoundInterval = 0
CRF_RaidTextures = {}
local CRF_RaidGroup = {}
local CRF_radar = CreateFrame("Frame","RadarFrame",UIParent)
local CRF_radar_texture = CRF_radar:CreateTexture("RadarCircle","BACKGROUND")
local CRF_radar_sep_texture = CRF_radar:CreateTexture("radarDivider","ARTWORK")
--SharedMedia----
local CRF_LSM =  LibStub("LibSharedMedia-3.0")
--Texture for player
local CRF_PlayerTexture = CRF_radar:CreateTexture("PlayerCenter","ARTWORK")
local class,_,_ = UnitClass("player")
CRF_PlayerTexture:SetTexture("Interface\\AddOns\\CustomRangeFinder\\Textures\\colorchangingdotbrighter.tga")
CRF_PlayerTexture:Show()
--sound
local SOUND_CHANNELS = {"Master","SFX","Ambience","Music"}
local innerRangeCount =0
local outterRangeCount =0

CRF_LSM:Register("sound", "Synth blip",[[Interface\Addons\CustomRangeFinder\Sounds\100%_synth_blip.ogg]])
--colors
local CLASS_COLORS = {
   ["Death Knight"] = {0.77,0.12,0.23},
   ["Demon Hunter"] = {0.64,0.19,0.79},
   ["Druid"] = {1.00,0.49,0.04},
   ["Hunter"] = {0.67,0.83,0.45},
   ["Mage"] = {0.41,0.80,0.94},
   ["Monk"] = {0.00,1.00,0.59},
   ["Paladin"] = {0.96,0.55,0.73},
   ["Priest"] = {1.00,1.00,1.00},
   ["Rogue"] = {1.00,0.96,0.41},
   ["Shaman"] = {0.0, 0.44,0.87},
   ["Warlock"] = {0.58,0.51,0.79},
   ["Warrior"] = {0.78,0.61,0.43}
}

if not CRFMedia then
   CRFMedia = {}
end

local options = {
   type = "group",
   handler = CustomRangeFinder,
   args = {
      namesOptions = {
         name ="Name Options",
         type = "group",
         args={
            playerNames = {
               type="toggle",
               name="Enable Names",
               desc="Toggles player's names above their dot",
               order = 1,
               get = function(info) return CustomRangeFinder.db.profile.playerNames end,
               set= function(info, newValue) 
                  CustomRangeFinder.db.profile.playerNames = newValue 
                  CustomRangeFinder:SetTextOptions()
               end,
            },
            namesOnEdge = {
               type= "toggle",
               name="Enable Names on edge",
               desc ="Toggles the display of players name's when they are outside your range",
               order = 2,
               disabled = function()
                  if CustomRangeFinder.db.profile.playerNames == false then return true 
                  else
               return false end end,
               get = function(info) return CustomRangeFinder.db.profile.namesOnEdge end,
               set = function(info, newValue)CustomRangeFinder.db.profile.namesOnEdge = newValue end,
            },
            radarFontSize = {
               type = "range",
               name = "Font Size",
               desc = "Changes the size of the font for player names",
               order = 4,
               width = "full",
               min = 1,
               max = 74,
               step = 1,
               get = function(info) return CustomRangeFinder.db.profile.radarFontSize end,
               set = function(info, newValue)
                  CustomRangeFinder.db.profile.radarFontSize = newValue
                  
                  CustomRangeFinder:SetTextOptions()
               end,
            },
            fontStyle = {
               type = "select", 
               dialogControl = "LSM30_Font",
               name ="Font",
               desc = "Changes the font for the player's names",
               order = 3,
               width = "full",
               style = "dropdown",
               values = AceGUIWidgetLSMlists.font,
               get = function(info) return CustomRangeFinder.db.profile.fontStyle
               end,
               set = function(info, newValue)
                  CustomRangeFinder.db.profile.fontStyle = newValue
                  CustomRangeFinder:SetTextOptions()
               end,
            },
         },
      },
      radarOptions = {
         name = "Radar Options",
         type = "group",
         args = {
            UpdateInterval = {
               type="range",
               name="Update Interval",
               desc="The time in seconds to refresh the radar screen (recommended: 0)",
               order = 4,
               width = "full",
               min=0,
               max = 0.1,
               step=0.01,
               get = function(info) return CustomRangeFinder.db.profile.UpdateInterval end,
               set = function(info, newValue)
                  CustomRangeFinder.db.profile.UpdateInterval = newValue
                  CRF_UpdateInterval = CustomRangeFinder.db.profile.UpdateInterval
               end,
            },
            radarLock = {
               type="toggle",
               name="Lock Window",
               desc="Locks the radar, so that it can be clicked through and not moved",
               order = 1,
               width = "full",
               get= function(info) return CustomRangeFinder.db.profile.radarLock end,
               set= function(info,newValue) 
                  CustomRangeFinder.db.profile.radarLock = newValue 
                  if CustomRangeFinder.db.profile.radarLock == true then
                     CustomRangeFinder.LockRadar()
                  else
                     CustomRangeFinder.UnlockRadar()
                  end
               end,
            },
            radarSize = {
               type = "range",
               name = "Radar size",
               desc = "Sets the height and width of the radar",
               order = 2,
               width = "full",
               min= 0,
               max= 1024,
               step = 1,
               get = function(info) return CustomRangeFinder.db.profile.radarSize end,
               set = function(info, newValue)
                  CustomRangeFinder.db.profile.radarSize = newValue
                  CustomRangeFinder:Update_Radar()
               end,
            },
            radarX ={
               type = "range",
               name = "X Coordinate",
               desc = "Defines the X Coordinate for the radar",
               order = 5,
               width = "full",
               min =0,
               max = math.floor((GetScreenWidth()*1.2)),
               step = 0.1,
               get = function(info)
               return CustomRangeFinder.db.profile.radarX end,
               set = function(info, newValue)
                  CustomRangeFinder.db.profile.radarX = newValue
                  CRF_radar:ClearAllPoints()
                  CustomRangeFinder:Update_Radar()
               end,
            },
            radarY ={
               type = "range",
               name = "Y Coordinate",
               desc = "Defines the Y Coordinate for the radar",
               order = 6,
               width = "full",
               min =0,
               max =math.floor((GetScreenHeight()*1.2)),
               step = 0.1,
               get = function(info) return CustomRangeFinder.db.profile.radarY end,
               set = function(info, newValue)
                  CustomRangeFinder.db.profile.radarY = newValue
                  CRF_radar:ClearAllPoints()
                  CustomRangeFinder:Update_Radar()
               end,
            },
            Range = {
               type= "group",
               name = "Range",
               args={
                  detectionRange = {
                     type ="range",
                     name="Detection Range",
                     desc="Proximity detection radius in yards",
                     order = 3,
                     width = "full",
                     min=1,
                     max=100,
                     step=0.1,
                     get= function(info) return CustomRangeFinder.db.profile.detectionRange end,
                     set = function(info, newValue) 
                        CustomRangeFinder.db.profile.detectionRange = newValue 
                     end,
                  },
                  outsideRange ={
                     type ="range",
                     name="Outside Range",
                     desc="Radial distance for when players are outside detection range",
                     order = 3,
                     width = "full",
                     min=1,
                     max=100,
                     step=0.1,
                     get= function(info) return CustomRangeFinder.db.profile.outsideRange end,
                     set = function(info, newValue) 
                        CustomRangeFinder.db.profile.outsideRange = newValue 
                     end,
                  },
                  rangeRatio ={
                     type="range",
                     name="Range ratio",
                     desc="Ratio of detection range to outside range, divides up the space of the radar according to the ratio",
                     width ="full",
                     min=0.1,
                     max=1,
                     step=0.01,
                     get= function(info) return CustomRangeFinder.db.profile.rangeRatio end,
                     set = function(info, newValue) 
                        CustomRangeFinder.db.profile.rangeRatio = newValue 
                        CustomRangeFinder:Update_Radar()
                     end,
                  }
               }
            },
            R_Colors ={
               type = "group",
               name = "Radar Colors",
               args= {
                  radarOpacity ={
                     type = "range",
                     name = "Opacity",
                     desc = "Sets the opacity for the radar",
                     order = 1,
                     width = "full",
                     min=0,
                     max=1,
                     step = 0.01,
                     get = function(info) return CustomRangeFinder.db.profile.radarOpacity end,
                     set = function(info, newValue)
                        CustomRangeFinder.db.profile.radarOpacity = newValue
                        CustomRangeFinder:Update_Radar()
                     end,
                  },
                  radarRed = {
                     type = "range",
                     name = "Red Component",
                     order = 2,
                     width = "full",
                     min =0,
                     max = 1,
                     step = 0.001,
                     desc = "Sets the value of the red color component for the radar",
                     get = function(info) return CustomRangeFinder.db.profile.radarRed end,
                     set = function(info, newValue)
                        CustomRangeFinder.db.profile.radarRed = newValue 
                        CustomRangeFinder:Update_Radar()
                     end,
                  },
                  radarGreen = {
                     type = "range",
                     name = "Green Component",
                     order = 3,
                     width = "full",
                     min =0,
                     max = 1,
                     step = 0.001,
                     desc = "Sets the value of the green color component for the radar",
                     get = function(info) return CustomRangeFinder.db.profile.radarGreen end,
                     set = function(info, newValue)
                        CustomRangeFinder.db.profile.radarGreen = newValue
                        CustomRangeFinder:Update_Radar()
                     end,
                  },
                  radarBlue = {
                     type = "range",
                     name = "Blue Component",
                     order = 4,
                     width = "full",
                     min =0,
                     max = 1,
                     step = 0.001,
                     desc = "Sets the value of the blue color component for the radar",
                     get = function(info) return CustomRangeFinder.db.profile.radarBlue end,
                     set = function(info, newValue)
                        CustomRangeFinder.db.profile.radarBlue = newValue 
                        CustomRangeFinder:Update_Radar()
                     end,
                  },
               }
            },
            RR_Colors ={
               type = "group",
               name = "Radar Ring Colors",
               args= {
                  ringOpacity ={
                     type = "range",
                     name = "Opacity",
                     desc = "Sets the opacity for the radars ring",
                     order = 1,
                     width = "full",
                     min=0,
                     max=1,
                     step = 0.01,
                     get = function(info) return CustomRangeFinder.db.profile.ringOpacity end,
                     set = function(info, newValue)
                        CustomRangeFinder.db.profile.ringOpacity = newValue
                        CustomRangeFinder:Update_Radar()
                     end,
                  },
                  ringRed = {
                     type = "range",
                     name = "Red Component",
                     order = 2,
                     width = "full",
                     min =0,
                     max = 1,
                     step = 0.001,
                     desc = "Sets the value of the red color component for the radars ring",
                     get = function(info) return CustomRangeFinder.db.profile.ringRed end,
                     set = function(info, newValue)
                        CustomRangeFinder.db.profile.ringRed = newValue 
                        CustomRangeFinder:Update_Radar()
                     end,
                  },
                  ringGreen = {
                     type = "range",
                     name = "Green Component",
                     order = 3,
                     width = "full",
                     min =0,
                     max = 1,
                     step = 0.001,
                     desc = "Sets the value of the green color component for the radars ring",
                     get = function(info) return CustomRangeFinder.db.profile.ringGreen end,
                     set = function(info, newValue)
                        CustomRangeFinder.db.profile.ringGreen = newValue
                        CustomRangeFinder:Update_Radar()
                     end,
                  },
                  ringBlue = {
                     type = "range",
                     name = "Blue Component",
                     order = 4,
                     width = "full",
                     min =0,
                     max = 1,
                     step = 0.001,
                     desc = "Sets the value of the blue color component for the radars ring",
                     get = function(info) return CustomRangeFinder.db.profile.ringBlue end,
                     set = function(info, newValue)
                        CustomRangeFinder.db.profile.ringBlue = newValue 
                        CustomRangeFinder:Update_Radar()
                     end,
                  },
               }
            }
         }, 
      },
      visibilityOptions = {
         name = "Visibility Options",
         type = "group",
         args = {
            customSelection = {
               type = "input",
               name = "Custom Selections",
               desc = "Choose exactly what unit's are to be showed on the radar, this will cause the radar to only display the units specified",
               width = "full",
               order =1,
               get = function(info) return CustomRangeFinder.db.profile.customSelection end,
               set = function(info, newValue) 
                  CustomRangeFinder.db.profile.customSelection = newValue
                  CustomRangeFinder:Form_Group()
               end,
               multiline = true,
               --usage = "player1,player2,player3,party1,raid5,party4,raid29",
            },
            dps = {
               type = "toggle",
               name = "Show DPS",
               width = "normal",
               order = 2,
               desc = "Toggles the display of players with the role Damage",
               get = function(info) return CustomRangeFinder.db.profile.dps end,
               set = function(info, newValue) CustomRangeFinder.db.profile.dps = newValue end,
            },
            healer = {
               type = "toggle",
               name = "Show Healers",
               width = "normal",
               order = 3,
               desc = "Toggles the display of players with the role Healer",
               get = function(info) return CustomRangeFinder.db.profile.healer end,
               set = function(info, newValue) CustomRangeFinder.db.profile.healer = newValue end,
            },
            tank = {
               type = "toggle",
               name = "Show Tanks",
               width = "normal",
               order = 4,
               desc = "Toggles the display of players with the role Tank",
               get = function(info) return CustomRangeFinder.db.profile.tank end,
               set = function(info, newValue) CustomRangeFinder.db.profile.tank = newValue end,
            },
            offline = {
               type = "toggle",
               name = "Show Offline",
               order = 5,
               desc = "Toggles the visibility of players who are offline",
               get = function(info) return CustomRangeFinder.db.profile.offline end,
               set = function(info, newValue) CustomRangeFinder.db.profile.offline = newValue end,
            },
            dead ={
               type = "toggle",
               name = "Show Dead",
               order = 6,
               desc = "Toggles the visibility players who have died and/or are a ghost",
               get = function(info) return CustomRangeFinder.db.profile.dead end,
               set = function(info, newValue) CustomRangeFinder.db.profile.dead = newValue end,
            },
         },
      },
      Textures = {
         name = "Texture Options",
         type="group",
         args = {
            classColor ={
               type = "toggle",
               name = "Class Colors",
               order = 1,
               width = "full",
               desc = "Sets the color the dots to their respective class color",
               get = function(info) return CustomRangeFinder.db.profile.classColor end,
               set = function(info, newValue)
                  CustomRangeFinder.db.profile.classColor = newValue
                  CustomRangeFinder:SetColorOptions()
               end,
            },
            red = {
               type = "range",
               name = "Red Component",
               order = 2,
               width = "full",
               min =0,
               max = 1,
               step = 0.001,
               desc = "Sets the value of the red color component for the player dots",
               disabled = function()
                  if CustomRangeFinder.db.profile.classColor == true then return true 
                  else
               return false end end,
               get = function(info) return CustomRangeFinder.db.profile.red end,
               set = function(info, newValue)
                  CustomRangeFinder.db.profile.red = newValue 
                  CustomRangeFinder:SetColorOptions()
               end,
            },
            green = {
               type = "range",
               name = "Green Component",
               order = 3,
               width = "full",
               min =0,
               max = 1,
               step = 0.001,
               disabled = function()
                  if CustomRangeFinder.db.profile.classColor == true then return true 
                  else
               return false end end,
               desc = "Sets the value of the green color component for the player dots",
               get = function(info) return CustomRangeFinder.db.profile.green end,
               set = function(info, newValue)
                  CustomRangeFinder.db.profile.green = newValue
                  CustomRangeFinder:SetColorOptions()
               end,
            },
            blue = {
               type = "range",
               name = "Blue Component",
               order = 4,
               width = "full",
               min =0,
               max = 1,
               step = 0.001,
               disabled = function()
                  if CustomRangeFinder.db.profile.classColor == true then return true 
                  else
               return false end end,
               desc = "Sets the value of the blue color component for the player dots",
               get = function(info) return CustomRangeFinder.db.profile.blue end,
               set = function(info, newValue)
                  CustomRangeFinder.db.profile.blue = newValue 
                  CustomRangeFinder:SetColorOptions()
               end,
            },
            dotSize = {
               type = "range",
               name = "Dot size",
               order = 5,
               width = "full",
               min =1,
               max = 64,
               step = 1,
               desc = "Sets the size of the player's dot",
               get = function(info) return CustomRangeFinder.db.profile.dotSize end,
               set = function(info, newValue)
                  CustomRangeFinder.db.profile.dotSize = newValue 
                  ---due to the hack in initilization all sizes must be *2^0.5 bigger to represent the correct amount of pixels
                  CustomRangeFinder:SetDotSize()
               end,
            },
         }
      },
      Sounds = {
         name = "Sound Options",
         type = "group",
         args = {
            bothSoundsEnabled= {
               type ="toggle",
               name = "Enable simultaneous playback",
               desc = "Allows the outter sound to play at the same time as the inner sound, when disabled inner sound gets priority",
               order = 0,
               width = "full",
               get = function(info) return CustomRangeFinder.db.profile.bothSoundsEnabled end,
               set = function(info, newValue) CustomRangeFinder.db.profile.bothSoundsEnabled = newValue end,
            },
            innerSoundEnable = {
               type = "toggle",
               name = "Enable Inner Sound",
               desc = "Enables the inner sound",
               order = 1,
               get = function(info) return CustomRangeFinder.db.profile.innerSoundEnable end,
               set = function(info, newValue) CustomRangeFinder.db.profile.innerSoundEnable = newValue end,
            },
            innerSoundFile = {
               type = "select", 
               dialogControl = "LSM30_Sound",
               name ="Inner Sound",
               desc = "Changes the sound that plays when players are within detection range",
               order = 2,
               style = "dropdown",
               width = "full",
               values = AceGUIWidgetLSMlists.sound,
               get = function(info) return CustomRangeFinder.db.profile.innerSoundFile
               end,
               set = function(info, newValue)
                  CustomRangeFinder.db.profile.innerSoundFile = newValue
                  CRFMedia["iSound"] = CustomRangeFinder.db.profile.innerSoundFile
               end,
            },
            innerSoundInterval = {
               type="range",
               name="Inner Sound Delay",
               desc="The time in seconds before the sound will play again",
               order = 4,
               width = "full",
               min=0,
               max = 10,
               step=0.1,
               get = function(info) return CustomRangeFinder.db.profile.innerSoundInterval end,
               set = function(info, newValue)
                  CustomRangeFinder.db.profile.innerSoundInterval = newValue
                  CRF_SoundInterval = CustomRangeFinder.db.profile.innerSoundInterval
               end,
            },
            innerSoundChannel ={
               type = "select",
               name = "Inner Channel",
               desc = "The sound channel the sound will play through",
               order = 3,
               width = "full",
               values = SOUND_CHANNELS,
               get = function(info) return CustomRangeFinder.db.profile.innerSoundChannel end,
               set = function(info, newValue) CustomRangeFinder.db.profile.innerSoundChannel = newValue end,
            },
            outterSoundEnable = {
               type = "toggle",
               name = "Enable Outter Sound",
               desc = "Enables the Outter sound",
               order = 5,
               get = function(info) return CustomRangeFinder.db.profile.outterSoundEnable end,
               set = function(info, newValue) CustomRangeFinder.db.profile.outterSoundEnable = newValue end,
            },
            outterSoundFile = {
               type = "select", 
               dialogControl = "LSM30_Sound",
               name ="Outter Sound",
               desc = "Changes the sound that plays when players are within detection range",
               order = 6,
               width = "full",
               style = "dropdown",
               values = AceGUIWidgetLSMlists.sound,
               get = function(info) return CustomRangeFinder.db.profile.outterSoundFile
               end,
               set = function(info, newValue)
                  CustomRangeFinder.db.profile.outterSoundFile = newValue
                  CRFMedia["oSound"] = CustomRangeFinder.db.profile.outterSoundFile
               end,
            },
            outterSoundInterval = {
               type="range",
               name="Outter Sound Delay",
               desc="The time in seconds before the sound will play again",
               order = 8,
               width = "full",
               min=0,
               max = 10,
               step=0.1,
               get = function(info) return CustomRangeFinder.db.profile.outterSoundInterval end,
               set = function(info, newValue)
                  CustomRangeFinder.db.profile.outterSoundInterval = newValue
                  CRF_SoundInterval = CustomRangeFinder.db.profile.outterSoundInterval
               end,
            },
            outterSoundChannel ={
               type = "select",
               name = "Outter Channel",
               desc = "The sound channel the sound will play through",
               order = 7,
               width = "full",
               values = SOUND_CHANNELS,
               get = function(info) return CustomRangeFinder.db.profile.outterSoundChannel end,
               set = function(info, newValue) CustomRangeFinder.db.profile.outterSoundChannel = newValue end,
            },
         }
      },
   }
}

function fromCSV (s)
   s = s .. ','        -- ending comma
   local t = {}        -- table to collect fields
   local fieldstart = 1
   repeat
      -- next field is quoted? (start with `"'?)
      if string.find(s, '^"', fieldstart) then
         local a, c
         local i  = fieldstart
         repeat
            -- find closing quote
            a, i, c = string.find(s, '"("?)', i+1)
         until c ~= '"'    -- quote not followed by quote?
         if not i then error('unmatched "') end
         local f = string.sub(s, fieldstart+1, i-1)
         table.insert(t, (string.gsub(f, '""', '"')))
         fieldstart = string.find(s, ',', i) + 1
      else                -- unquoted; find next comma
         local nexti = string.find(s, ',', fieldstart)
         table.insert(t, string.sub(s, fieldstart, nexti-1))
         fieldstart = nexti + 1
      end
   until fieldstart > string.len(s)
   return t
end

local defaults = {
   profile = {
      UpdateInterval = 0,
      detectionRange = 10,
      radarLock = false,
      playerNames = true,
      customSelection = "",
      dps = true,
      healer = true,
      tank = true,
      offline = false,
      dead = false,
      radarSize = 300,
      radarX=((GetScreenWidth()-300))/2,
      radarY=((GetScreenHeight()-300))/2,
      radarFontSize = 10,
      namesOnEdge = false,
      classColor = true,
      red = 1,
      green = 1,
      blue =1,
      dotSize = 10,
      radarOpacity = 0.5,
      radarRed = 0,
      radarBlue = 0,
      radarGreen= 0,
      outsideRange=10,
      rangeRatio=0.75,
      fontStyle="Arial Narrow",
      ringOpacity=1,
      ringRed=1,
      ringBlue=1,
      ringGreen=1,
      innerSoundEnable =true,
      innerSoundFile = "Synth blip",
      innerSoundInterval = 2,
      innerSoundChannel = 1,
      outterSoundEnable = false,
      outterSoundFile = "None",
      outterSoundInterval = 2,
      outterSoundChannel =  1,
   }
}

--[[
creates database
    registers
creates options table
    registers
    hooks default button
registers chat commands
initializes the radar frame
creates 40 textures in CRF_RaidTextures
]]
function CustomRangeFinder:OnInitialize()
   --Database--
   self.db = LibStub("AceDB-3.0"):New("CRFOptions",defaults,true)
   self.db:RegisterDefaults(defaults)
   --self.db.RegisterCallback(self, "OnProfileChanged", "reinitialize")
   --self.db.RegisterCallback(self, "OnProfileCopied", "reinitialize")
   self.db.RegisterCallback(self, "OnProfileReset", "ResetProfile")
   --Options---
   LibStub("AceConfig-3.0"):RegisterOptionsTable("CustomRangeFinder",options,{"CustomRangeFinder","crf","CRF"})
   self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("CustomRangeFinder","CustomRangeFinder")
   --hook into default button on bliz addons setting menu
   self.optionsFrame.default = function()
      self.db:ResetProfile(true)
      LibStub("AceConfigRegistry-3.0"):NotifyChange("CustomRangeFinder")
   end
   --ChatCommands--
   self:RegisterChatCommand("CustomRangeFinder","ChatCommand")
   self:RegisterChatCommand("crf","ChatCommand")
   self:RegisterChatCommand("CRF","ChatCommand")
   --Textures for every player
   for i=1,40,1
   do
      CRF_RaidTextures[i] = CRF_radar:CreateTexture("PlayerCenter","ARTWORK")
      CRF_RaidTextures[i]:SetTexture("Interface\\AddOns\\CustomRangeFinder\\Textures\\colorchangingdotbrighter.tga")
      CRF_RaidTextures[i]:SetWidth(CustomRangeFinder.db.profile.dotSize*2^0.5)
      CRF_RaidTextures[i]:SetHeight(CustomRangeFinder.db.profile.dotSize*2^0.5)
      CRF_RaidTextures[i].text = CRF_radar:CreateFontString(nil,"ARTWORK")
      CRF_RaidTextures[i].text:SetFont(CRF_LSM:Fetch("font",CRFMedia["font"]),CustomRangeFinder.db.profile.radarFontSize)
      --this is currently a hack method to fixing sizing issues for player dots when rotated only needs to be ran once at start
      CRF_RaidTextures[i]:SetRotation(0)
   end
   CustomRangeFinder:Update_Radar()
   CustomRangeFinder:UpdatePlayerDot()
   CustomRangeFinder:InitializeGroup()
   CRF_UpdateInterval = self.db.profile.UpdateInterval
   CustomRangeFinder:BeginScan()
end

--[[
resets all db options to defaults
]]
function CustomRangeFinder:ResetProfile()
   --[[ CustomRangeFinder.db.profile.UpdateInterval = defaults.profile.UpdateInterval
   CustomRangeFinder.db.profile.detectionRange = defaults.profile.detectionRange
   CustomRangeFinder.db.profile.radarLock = defaults.profile.radarLock
   CustomRangeFinder.db.profile.playerNames = defaults.profile.playerNames
   CustomRangeFinder.db.profile.customSelection = defaults.profile.customSelection
   CustomRangeFinder.db.profile.dps = defaults.profile.dps
   CustomRangeFinder.db.profile.healer = defaults.profile.healer
   CustomRangeFinder.db.profile.tank = defaults.profile.tank
   CustomRangeFinder.db.profile.offline = defaults.profile.offline
   CustomRangeFinder.db.profile.dead = defaults.profile.dead
   CustomRangeFinder.db.profile.radarSize = defaults.profile.radarSize
   CustomRangeFinder.db.profile.radarX = defaults.profile.radarX
   CustomRangeFinder.db.profile.radarY = defaults.profile.radarY
   CustomRangeFinder.db.profile.radarFontSize = defaults.profile.radarFontSize
   CustomRangeFinder.db.profile.namesOnEdge = defaults.profile.namesOnEdge
   CustomRangeFinder.db.profile.classColor = defaults.profile.classColor
   CustomRangeFinder.db.profile.red = defaults.profile.red
   CustomRangeFinder.db.profile.green = defaults.profile.green
   CustomRangeFinder.db.profile.blue = defaults.profile.blue
   CustomRangeFinder.db.profile.dotSize = defaults.profile.dotSize
   CustomRangeFinder.db.profile.radarOpacity = defaults.profile.radarOpacity
   CustomRangeFinder.db.profile.radarRed = defaults.profile.radarRed
   CustomRangeFinder.db.profile.radarBlue = defaults.profile.radarBlue
   CustomRangeFinder.db.profile.radarGreen = defaults.profile.radarGreen
   CustomRangeFinder.db.profile.outsideRange = defaults.profile.outsideRange
   CustomRangeFinder.db.profile.rangeRatio = defaults.profile.rangeRatio
   CustomRangeFinder.db.profile.fontStyle = defaults.profile.fontStyle]]--
   CRF_radar:ClearAllPoints()
   CustomRangeFinder.Update_Radar()
   CustomRangeFinder:InitializeGroup()
end

--[[
Modifies all attributes belonging to the radar

Call when radar needs to be updated

radar frame:width,height,point,
radar texture:red,green,blue,opacity
]]
function CustomRangeFinder:Update_Radar()
   CRF_radar:SetWidth(CustomRangeFinder.db.profile.radarSize)
   CRF_radar:SetHeight(CustomRangeFinder.db.profile.radarSize)
   CRF_radar:SetPoint("BOTTOMLEFT",CustomRangeFinder.db.profile.radarX,CustomRangeFinder.db.profile.radarY)
   CRF_radar:SetClampedToScreen(true)
   --Frame Texture
   CRF_radar_texture:SetTexture("Interface\\AddOns\\CustomRangeFinder\\Textures\\radar.tga")
   CRF_radar_texture:SetAllPoints(CRF_radar)
   CRF_radar_texture:SetVertexColor(CustomRangeFinder.db.profile.radarRed,CustomRangeFinder.db.profile.radarGreen,CustomRangeFinder.db.profile.radarBlue,CustomRangeFinder.db.profile.radarOpacity)
   CRF_radar.texture = radar_texture
   --seperation texture
   if CustomRangeFinder.db.profile.radarSize > 512 then
      CRF_radar_sep_texture:SetTexture("Interface\\AddOns\\CustomRangeFinder\\Textures\\rangeRatioRing2.tga")
   else
      CRF_radar_sep_texture:SetTexture("Interface\\AddOns\\CustomRangeFinder\\Textures\\rangeRatioRingHalfSizeThinner.tga")
   end
   CRF_radar_sep_texture:SetPoint("CENTER",CRF_radar)
   CRF_radar_sep_texture:SetSize(CRF_radar:GetWidth()*CustomRangeFinder.db.profile.rangeRatio,CRF_radar:GetHeight()*CustomRangeFinder.db.profile.rangeRatio)
   CRF_radar_sep_texture:SetVertexColor(CustomRangeFinder.db.profile.ringRed,CustomRangeFinder.db.profile.ringGreen,CustomRangeFinder.db.profile.ringBlue,CustomRangeFinder.db.profile.ringOpacity)
   CRF_radar.texture = CRF_radar_sep_texture
   
   if CustomRangeFinder.db.profile.radarLock == true then
      CustomRangeFinder:LockRadar()
   else
      CustomRangeFinder:UnlockRadar()
   end
end

function CustomRangeFinder:BeginScan()
   --CRF_UpdateInterval = self.db.profile.UpdateInterval
   CRF_radar:SetScript("OnUpdate",function(self,elapsed)
         CRF_UpdateInterval = CRF_UpdateInterval - elapsed
         if CRF_UpdateInterval <= 0 then
            CRF_UpdateInterval = CustomRangeFinder.db.profile.UpdateInterval
            CustomRangeFinder:scan_raid() 
         end
   end)
end

function CustomRangeFinder:ChatCommand(input)
   if not input or input:trim() == "" then
      InterfaceOptionsFrame_OpenToCategory("CustomRangeFinder")
      InterfaceOptionsFrame_OpenToCategory("CustomRangeFinder")
   else
      LibStub("AceConfigCmd-3.0"):HandleCommand("CustomRangeFinder","crf",input)
      LibStub("AceConfigCmd-3.0"):HandleCommand("CustomRangeFinder","CRF",input)
      LibStub("AceConfigCmd-3.0"):HandleCommand("CustomRangeFinder","CustomRangeFinder",input)
   end
end

function CustomRangeFinder:OnEnable()
   CustomRangeFinder:RegisterEvent("PARTY_CONVERTED_TO_RAID", function() CustomRangeFinder:InitializeGroup() end)
   CustomRangeFinder:RegisterEvent("RAID_ROSTER_UPDATE", function() CustomRangeFinder:InitializeGroup() end)    
   CustomRangeFinder:RegisterEvent("GROUP_ROSTER_UPDATE", function() CustomRangeFinder:InitializeGroup() end)
   CustomRangeFinder:RegisterEvent("PLAYER_DEAD", function() CustomRangeFinder:InitializeGroup() end)
   CustomRangeFinder:RegisterEvent("PLAYER_ALIVE", function() CustomRangeFinder:InitializeGroup() end)
   CustomRangeFinder:RegisterEvent("PLAYER_UNGHOST", function() CustomRangeFinder:InitializeGroup() end)
   CustomRangeFinder:RegisterEvent("PARTY_MEMBERS_CHANGED", function() CustomRangeFinder:InitializeGroup() end)
   CustomRangeFinder:RegisterEvent("PARTY_MEMBER_DISABLE", function() CustomRangeFinder:InitializeGroup() end)
   CustomRangeFinder:RegisterEvent("PARTY_MEMBER_ENABLE", function() CustomRangeFinder:InitializeGroup() end)
end

function CustomRangeFinder:OnDisable()
   
end

local function OnDragStop(self)
   CRF_radar:StopMovingOrSizing()
   CustomRangeFinder.db.profile.radarX = self:GetLeft()
   CustomRangeFinder.db.profile.radarY = self:GetBottom()
   LibStub("AceConfigRegistry-3.0"):NotifyChange("CustomRangeFinder") 
end

function CustomRangeFinder:OnStartMoving()
   CRF_radar:ClearAllPoints()
   CRF_radar.StartMoving()
end

function CustomRangeFinder:LockRadar()
   CRF_radar:SetMovable(false)
   CRF_radar:EnableMouse(false)
   CRF_radar:RegisterForDrag()
   CRF_radar:SetScript("OnDragStart",nil)
   CRF_radar:SetScript("OnDragStop",nil)
end

function CustomRangeFinder:UnlockRadar()
   CRF_radar:SetMovable(true)
   CRF_radar:EnableMouse(true)
   CRF_radar:RegisterForDrag("LeftButton")
   CRF_radar:SetScript("OnDragStart", CRF_radar.StartMoving)
   CRF_radar:SetScript("OnDragStop", OnDragStop)
end

--[[
modifies attributes of players dot
colors: red,green,blue
size: width,height
point
]]

function CustomRangeFinder:UpdatePlayerDot()
   CRF_PlayerTexture:SetVertexColor(CLASS_COLORS[class][1],CLASS_COLORS[class][2],CLASS_COLORS[class][3])
   CRF_PlayerTexture:SetWidth(CustomRangeFinder.db.profile.dotSize)
   CRF_PlayerTexture:SetHeight(CustomRangeFinder.db.profile.dotSize)
   CRF_PlayerTexture:SetPoint("CENTER", CRF_radar)
end

--[[
modifies attributes of every players text
]]
function CustomRangeFinder:SetTextOptions()
   CRFMedia["font"] = CustomRangeFinder.db.profile.fontStyle
   for i=1,#CRF_RaidGroup,1
   do
      CRF_RaidTextures[i].text:SetFont(CRF_LSM:Fetch("font",CRFMedia["font"]),CustomRangeFinder.db.profile.radarFontSize)
      if CustomRangeFinder.db.profile.playerNames == true then
         CRF_RaidTextures[i].text:Show()
      else
         CRF_RaidTextures[i].text:Hide()
      end
   end
end
--[[
Creates the formation of the group
for every player in the group
    adds their name to a table
    sets their textures color,
    sets strings: font,fontsize,text
]]
function CustomRangeFinder:SetColorOptions()
   for i=1,#CRF_RaidGroup,1
   do
      if CustomRangeFinder.db.profile.classColor == true then
         local class,_,_ = UnitClass(CRF_RaidGroup[i])
         CRF_RaidTextures[i]:SetVertexColor(CLASS_COLORS[class][1],CLASS_COLORS[class][2],CLASS_COLORS[class][3])
      else
         CRF_RaidTextures[i]:SetVertexColor(CustomRangeFinder.db.profile.red,CustomRangeFinder.db.profile.green,CustomRangeFinder.db.profile.blue)
      end
   end
end
--[[
set the size of every players dot
]]
function CustomRangeFinder:SetDotSize()
   for i=1,#CRF_RaidGroup,1
   do
      CRF_RaidTextures[i]:SetSize(CustomRangeFinder.db.profile.dotSize*2^0.5,CustomRangeFinder.db.profile.dotSize*2^0.5)
   end
end
--[[
sets the structure of the group to search through
]]
function CustomRangeFinder:Form_Group()
   local groupSize = GetNumGroupMembers()
   local groupPrefix = "" 
   if UnitInRaid("player") then
      groupPrefix="raid"
   else 
      groupPrefix="party" 
      groupSize = groupSize -1
   end
   for i=1, groupSize, 1
   do
      CRF_RaidGroup[i] = UnitName(groupPrefix..i)
      CRF_RaidTextures[i].text:SetText(UnitName(groupPrefix..i))
   end
end
--[[
runs all initialization options together in a single for loop
]]
function CustomRangeFinder:InitializeGroup()
   local groupSize = GetNumGroupMembers()
   local groupPrefix = "" 
   CRFMedia["font"] = CustomRangeFinder.db.profile.fontStyle
   CRFMedia["iSound"] = CustomRangeFinder.db.profile.innerSoundFile
   CRFMedia["oSound"] = CustomRangeFinder.db.profile.outterSoundFile
   if UnitInRaid("player") then
      groupPrefix="raid"
   else 
      groupPrefix="party" 
      groupSize = groupSize -1
   end
   
   for i=1,groupSize, 1
   do
      ------problem most likely to do with players name never being set and thus cant set the color of the players dot even though it is now shown
      CRF_RaidGroup[i] = UnitName(groupPrefix..i)
      local class,_,_ = UnitClass(UnitName(groupPrefix..i))
      CRF_RaidTextures[i].text:SetFont(CRF_LSM:Fetch("font",CRFMedia["font"]),CustomRangeFinder.db.profile.radarFontSize)
      CRF_RaidTextures[i].text:SetText(UnitName(groupPrefix..i))
      if CustomRangeFinder.db.profile.playerNames == true then
         CRF_RaidTextures[i].text:Show()
      else
         CRF_RaidTextures[i].text:Hide()
      end
      if CustomRangeFinder.db.profile.classColor == true then
         CRF_RaidTextures[i]:SetVertexColor(CLASS_COLORS[class][1],CLASS_COLORS[class][2],CLASS_COLORS[class][3])
      else
         CRF_RaidTextures[i]:SetVertexColor(CustomRangeFinder.db.profile.red,CustomRangeFinder.db.profile.green,CustomRangeFinder.db.profile.blue)
      end
      CRF_RaidTextures[i]:SetSize(CustomRangeFinder.db.profile.dotSize*2^0.5,CustomRangeFinder.db.profile.dotSize*2^0.5)
   end
end
--[[
rotates a texture by the arc angle between the two points
]]

function CustomRangeFinder:arcRotation(texture,x1,x2,y1,y2,r)
   -----solve and calculate angle---
   local twoRSquared = 2*(r)^2
   local p1p2 = math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
   local angle = math.acos((twoRSquared - (p1p2)^2)/twoRSquared)
   ----flip the angle to work on both sides of the circle
   if x1 > 0 then
      angle = angle *-1
   end
   ----reset the size of the arrow
   texture:SetWidth(CustomRangeFinder.db.profile.dotSize*2^0.5)
   texture:SetHeight(CustomRangeFinder.db.profile.dotSize*2^0.5)
   ----rotate the arrow which causes a resizing
   texture:SetRotation(angle)
   ---resize arrow to undo resizing during rotation
   ----------this is currently fixed by the hack initilization
   --texture:SetWidth(texture:GetWidth()*2^0.5)
   --texture:SetHeight(texture:GetHeight()*2^0.5)
end

function CustomRangeFinder:scan_raid()
   local innerRange = 0
   local outterRange = 0
   local playerAngle = GetPlayerFacing()
   local rotatedangle = (math.pi*2)-playerAngle
   --local groupSize = GetNumGroupMembers()
   local y1, x1, _, instance1 = UnitPosition("player")
   local pixelsPerYardInRange = (CustomRangeFinder.db.profile.radarSize/2)*CustomRangeFinder.db.profile.rangeRatio/(CustomRangeFinder.db.profile.detectionRange)
   local pixelsPerYardOutRange = (CustomRangeFinder.db.profile.radarSize/2)*(1-CustomRangeFinder.db.profile.rangeRatio)/(CustomRangeFinder.db.profile.outsideRange)
   --[[if CustomRangeFinder.db.profile.customSelection ~= "" then
        print(#fromCSV(CustomRangeFinder.db.profile.customSelection))
        CRF_RaidGroup = fromCSV(CustomRangeFinder.db.profile.customSelection)
   end]]--
   for i=1,#CRF_RaidGroup,1
   do
      local visibility = nil
      local role = UnitGroupRolesAssigned(CRF_RaidGroup[i])
      local y2, x2, _, instance2 = UnitPosition(CRF_RaidGroup[i])
      --------------CHECKS FOR VISIBILITY-----------------------
      --ROLE VISIBILITY--
      if role == "DAMAGER" and CustomRangeFinder.db.profile.dps then
         visibility = true
      elseif role == "HEALER" and CustomRangeFinder.db.profile.healer then
         visibility = true
      elseif role == "TANK" and CustomRangeFinder.db.profile.tank then
         visibility = true
      else
         visibility = false
      end
      if visibility ==  true then
         --DEAD VISIBIILITY--
         -- if currently visible , your dead and you dont want to see dead people
         if CustomRangeFinder.db.profile.dead~= true and UnitIsDeadOrGhost(CRF_RaidGroup[i]) then
            visibility = false
         end
         --OFFLINE VISIBILITY--
         --if you dont want to see offline players and the player is offline
         if CustomRangeFinder.db.profile.offline ~= true and UnitIsConnected(CRF_RaidGroup[i]) ~= true then
            visibility = false
         end
      end
      --ignore the player's dot
      if CRF_RaidGroup[i] == UnitName("player") then
         visibility = false
      end
      --draw the dots if the players are in the same instance and visible
      if instance1 == instance2 and visibility == true then
         local distance = ((x2 - x1) ^ 2 + (y2 - y1) ^ 2) ^ 0.5
         local dx = x2-x1
         local dy = y2-y1
         local cosangle = math.cos(rotatedangle) 
         local sinangle = math.sin(rotatedangle)
         if distance > (CustomRangeFinder.db.profile.outsideRange+CustomRangeFinder.db.profile.detectionRange) then
            --Dot is outside all visible ranges, turn dot into an arrow and lock to max range, rotate and point the arrow towards the player
            --lock the range
            dx = (dx/distance)
            dy = (dy/distance)
            --set the texture to the triangle if it is currently not
            if CRF_RaidTextures[i]:GetTexture() ~= "Interface\\AddOns\\CustomRangeFinder\\Textures\\triangle.tga" then
               CRF_RaidTextures[i]:SetTexture("Interface\\AddOns\\CustomRangeFinder\\Textures\\triangle.tga")
            end
            ---calculate the arc angle
            ---Point one on circle
            local dotx = (-1*dx * cosangle) - (dy * sinangle)
            local doty = (dy * cosangle) + (-1*dx * sinangle)
            dotx = dotx * ((CustomRangeFinder.db.profile.detectionRange * pixelsPerYardInRange)+(CustomRangeFinder.db.profile.outsideRange*pixelsPerYardOutRange))
            doty = doty * ((CustomRangeFinder.db.profile.detectionRange * pixelsPerYardInRange)+(CustomRangeFinder.db.profile.outsideRange*pixelsPerYardOutRange))
            -- point two on circle
            local px = 0
            local py = (CustomRangeFinder.db.profile.radarSize/2)
            CustomRangeFinder:arcRotation(CRF_RaidTextures[i],dotx,px,doty,py,py)
            CRF_RaidTextures[i]:SetPoint("CENTER", CRF_radar,"CENTER",dotx,doty)
            CRF_RaidTextures[i].text:SetPoint("CENTER", CRF_radar,"CENTER",dotx,doty) 
         elseif distance < (CustomRangeFinder.db.profile.outsideRange+CustomRangeFinder.db.profile.detectionRange) then
            --set dot texture back to dot if it was previously a triangle
            if CRF_RaidTextures[i]:GetTexture() ~= "Interface\\AddOns\\CustomRangeFinder\\Textures\\colorchangingdot.tga" then
               CRF_RaidTextures[i]:SetTexture("Interface\\AddOns\\CustomRangeFinder\\Textures\\colorchangingdot.tga")
            end
            local dotx = 0
            local doty =0
            if distance > CustomRangeFinder.db.profile.detectionRange then
               outterRange = outterRange +1
               local inner = pixelsPerYardInRange*CustomRangeFinder.db.profile.detectionRange
               local full = distance*pixelsPerYardInRange
               local dist = (full - inner)/pixelsPerYardInRange
               --lock distance to the inner disance to remember the location
               dx = (dx/distance) * inner
               dy = (dy/distance) * inner
               dotx = (-1*dx * cosangle) - (dy * sinangle)
               doty = (dy * cosangle) + (-1*dx * sinangle)
               --unsure if p1 y valye should be  the distance
               --calculate the angle between two points
               local p1 = {0,(CustomRangeFinder.db.profile.radarSize/2)}
               local p2 = {dotx,doty}
               local angle =math.atan2(p1[2],p1[1]) - math.atan2(p2[2],p2[1])
               --add the new vector onto the locked distance
               dotx = dotx + dist *pixelsPerYardOutRange*math.sin(angle)
               doty = doty + dist *pixelsPerYardOutRange*math.cos(angle)
            else
               innerRange = innerRange + 1
               dotx = (-1*dx * cosangle) - (dy * sinangle)
               doty = (dy * cosangle) + (-1*dx * sinangle)
               dotx = dotx *pixelsPerYardInRange
               doty = doty *pixelsPerYardInRange
            end
            --Set the position of the players dot and name
            CRF_RaidTextures[i]:SetPoint("CENTER", CRF_radar,"CENTER",dotx,doty)
            CRF_RaidTextures[i].text:SetPoint("CENTER", CRF_radar,"CENTER",dotx,doty)
         end
         --Display the dot
         CRF_RaidTextures[i]:Show()
         --Player name visibility
         if CustomRangeFinder.db.profile.playerNames ==true then
            if (distance > CustomRangeFinder.db.profile.outsideRange+CustomRangeFinder.db.profile.detectionRange and CustomRangeFinder.db.profile.namesOnEdge == false) then
               CRF_RaidTextures[i].text:Hide()
            else
               CRF_RaidTextures[i].text:Show()
            end
            --Hiding the name on players center dot
            if CRF_RaidGroup[i]== UnitName("player") then
               CRF_RaidTextures[i].text:Hide()
            end
         end
      else
         CRF_RaidTextures[i]:Hide()
         CRF_RaidTextures[i].text:Hide()
      end
   end
   innerRangeCount = innerRange
   outterRangeCount = outterRange
   CustomRangeFinder:playSound()
end

function CustomRangeFinder:playSound()
   local timeLeft1 = self:TimeLeft(timerID1)
   local timeLeft2 = self:TimeLeft(timerID2)
   if CustomRangeFinder.db.profile.bothSoundsEnabled ==true then
      if CustomRangeFinder.db.profile.outterSoundEnable ==true then
         if outterRangeCount > 0 then
            if timeLeft2 == 0 then
               CustomRangeFinder:outterRange()
               timerID2 = self:ScheduleTimer("outterRange",CustomRangeFinder.db.profile.outterSoundInterval)
            end
         else
            if handle2 ~= nil then
               StopSound(handle2)
               self:CancelTimer(timerID2)
            end
         end
      end
      if CustomRangeFinder.db.profile.innerSoundEnable ==true then
         if innerRangeCount > 0 then
            if timeLeft1 == 0 then
               CustomRangeFinder:innerRange()
               timerID1 = self:ScheduleTimer("innerRange",CustomRangeFinder.db.profile.innerSoundInterval)
            end
         else
            if handle1 ~= nil then
               StopSound(handle1)
               self:CancelTimer(timerID1)
            end
         end
      end
   else
      if CustomRangeFinder.db.profile.innerSoundEnable ==true then
         if innerRangeCount > 0 then
            if timeLeft1 == 0 then
               CustomRangeFinder:innerRange()
               timerID1 = self:ScheduleTimer("innerRange",CustomRangeFinder.db.profile.innerSoundInterval)
            end
         else
            if handle1 ~= nil then
               StopSound(handle1)
               self:CancelTimer(timerID1)
            end
         end
      end
      if CustomRangeFinder.db.profile.outterSoundEnable ==true then
         if outterRangeCount > 0 and innerRangeCount ==0 then
            if timeLeft2 == 0 then
               CustomRangeFinder:outterRange()
               timerID2 = self:ScheduleTimer("outterRange",CustomRangeFinder.db.profile.outterSoundInterval)
            end
         else
            if handle2 ~= nil then
               StopSound(handle2)
               self:CancelTimer(timerID2)
            end
         end
      end
   end
end

function CustomRangeFinder:outterRange()
   if handle2 ~= nil then
      StopSound(handle2)
   end
   _,handle2 = PlaySoundFile(CRF_LSM:Fetch("sound",CRFMedia["oSound"]),SOUND_CHANNELS[CustomRangeFinder.db.profile.outterSoundChannel])
end

function CustomRangeFinder:innerRange()
   if handle1 ~= nil then
      StopSound(handle1)
   end
   _,handle1 = PlaySoundFile(CRF_LSM:Fetch("sound",CRFMedia["iSound"]),SOUND_CHANNELS[CustomRangeFinder.db.profile.innerSoundChannel])
end