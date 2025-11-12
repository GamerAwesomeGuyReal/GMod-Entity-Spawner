local entslist = {}
local forcepos = false -- turn on to force all npcs to spawn at player 1
local forceentry = false -- change to number from 0 to force a specific number entity to spawn. use print pool!
local enabletimer = CreateConVar("entspawner_enable",0,{FCVAR_ARCHIVE},"Enables the timer for randomly spawning entities.",0,1)
local enablenpcs = CreateConVar("entspawner_enable_npcs",1,{FCVAR_ARCHIVE},"Enables spawning npcs from the spawn menu.",0,1)
local enablesents = CreateConVar("entspawner_enable_sents",1,{FCVAR_ARCHIVE},"Enables spawning sents from the spawn menu.",0,1)
local enableweps = CreateConVar("entspawner_enable_weps",1,{FCVAR_ARCHIVE},"Enables spawning weapons from the spawn menu.",0,1)
local enablecars = CreateConVar("entspawner_enable_cars",1,{FCVAR_ARCHIVE},"Enables spawning vehicles from the spawn menu.",0,1)
local weprando = CreateConVar("entspawner_rand_npcweps",0,{FCVAR_ARCHIVE},"Enables randomly replacing npc weapons.",0,1)
local adminents = CreateConVar("entspawner_enable_admin",0,{FCVAR_ARCHIVE},"Enables entities which can only be spawned by admins.",0,1)
local spawningtime = CreateConVar("entspawner_waitingtime",5,{FCVAR_ARCHIVE},"Decides the time between spawns")
local spawnmax = CreateConVar("entspawner_maximum",50,{FCVAR_ARCHIVE},"Decides the maximum entities.")
local printing = CreateConVar("entspawner_print",0,{FCVAR_ARCHIVE},"For debugging",0,1)
local spawnedents = {}

if SERVER then
    local function list2list(type)
        for i,e in pairs(list.Get(type)) do
            if !(table.HasValue(table.GetKeys(e),"Spawnable") && !e["Spawnable"]) then
                table.insert(entslist,e)
            end
        end
    end

    local function IsWaterNpc(ent)
        if ent.IsNPC then
            if ent.IsVJBaseSNPC == true then
                if ent.MovementType == 3 then return true end
            end
        end
    end

    local function NavHasWater()
        for i,n in pairs(navmesh.GetAllNavAreas()) do
            if n:IsUnderwater() then return true end
        end
    end

    local function GamerSpawnerGetLists(white) -- refresh list
        entslist = {}
        if white == nil then
            if enablenpcs:GetBool() then
                list2list("NPC")
            end
            if enablesents:GetBool() then
                list2list("SpawnableEntities")
            end
            if enableweps:GetBool() then
                list2list("Weapon")
            end
            if enablecars:GetBool() then
                list2list("Vehicles")
            end
        else list2list(white) end
    end

    local function GamerSpawnerSpawnedCount(printing)
        for n,e in pairs(spawnedents) do
            if printing == true then print(e) end
            if !IsValid(e) then
                table.remove(spawnedents,n)
            end
        end
        return #spawnedents
    end

    GamerSpawnerGetLists()

    local function GamerSpawnRandomEntity()
        GamerSpawnerGetLists()
        if #entslist != 0 then
            local navarea = navmesh.GetAllNavAreas()
            if #entslist != 0 then
                if navarea then
                    local spawntype = false
                    local entnumber = 0
                    if forceentry != false then entnumber = forceentry else
                        for i = 1, #entslist do -- conditions
                            local meetcon = true
                            entnumber = math.random(#entslist) -- pick the entity
                            if !adminents:GetBool() then
                                if table.HasValue(table.GetKeys(entslist[entnumber]),"AdminOnly") && entslist[entnumber]["AdminOnly"] then -- spawnflags
                                    meetcon = false
                                end
                            end
                            if meetcon == true then break end
                        end
                    end
                    local entity = entslist[entnumber]["Class"] -- set class for npcs
                    if !entity then entity = entslist[entnumber]["ClassName"] end -- for sents
                    entity = ents.Create(entity)

                    if printing:GetBool() then -- to find the troublesomes
                        print(entity:GetClass())
                        print(entnumber)
                        print("use print pool to find the above number")
                    end

                    if table.HasValue(table.GetKeys(entslist[entnumber]),"Weapons") then -- weapons
                        if (#entslist[entnumber]["Weapons"] != 0) then
                            if !weprando:GetBool() then
                                    local weaponnumber = math.random(#entslist[entnumber]["Weapons"]) -- get random weapon
                                    entity:Give(entslist[entnumber]["Weapons"][weaponnumber])
                            else
                                entity:Give(list.Get("NPCUsableWeapons")[math.random(#list.Get("NPCUsableWeapons"))]["class"]) -- npc's default weapon
                            end
                        end
                    end

                    if table.HasValue(table.GetKeys(entslist[entnumber]),"KeyValues") then -- keyvalues
                        for i,k in pairs(table.GetKeys(entslist[entnumber]["KeyValues"])) do -- i dont know what the hell i just did but it worked and im never touching it again
                            local newvalue = table.GetKeys(entslist[entnumber]["KeyValues"])[k]
                            entity:SetKeyValue(k,entslist[entnumber]["KeyValues"][k])
                        end
                    end

                    if table.HasValue(table.GetKeys(entslist[entnumber]),"SpawnFlags") then -- spawnflags
                        entity:SetSpawnFlags(entslist[entnumber]["SpawnFlags"]) -- that was easy
                    end

                    if table.HasValue(table.GetKeys(entslist[entnumber]),"Model") then -- models
                        entity:SetModel(entslist[entnumber]["Model"])
                    end

                    if table.HasValue(table.GetKeys(entslist[entnumber]),"Members") then -- keyvalues
                        for i,k in pairs(table.GetKeys(entslist[entnumber]["Members"])) do -- i dont know what the hell i just did but it worked and im never touching it again
                            local newvalue = table.GetKeys(entslist[entnumber]["Members"])[k]
                            entity.k = entslist[entnumber]["KeyValues"][k]
                        end
                    end

                    local offset = 32
                    if table.HasValue(table.GetKeys(entslist[entnumber]),"Offset") then -- offset 
                        offset = entslist[entnumber]["Offset"]
                    end
                    if table.HasValue(table.GetKeys(entslist[entnumber]),"NormalOffset") then -- offset again 
                        offset = entslist[entnumber]["NormalOffset"]
                    end
                    entity:SetAngles(Angle(0,math.random(0,360),0))

                    if table.HasValue(table.GetKeys(entslist[entnumber]),"OnCeiling") then -- ceiling req
                        if entslist[entnumber]["OnCeiling"] == true then
                            spawntype = ceiling
                        end
                    end
                    for i,n in RandomPairs(navmesh.GetAllNavAreas()) do
                        if forcepos == true then
                            entity:SetPos(Entity(1):GetPos() + Vector(0,200,0))
                        else
                            entity:SetPos(n:GetCenter() + Vector(0,0,n:GetSizeY()))
                            if spawntype == ceiling then
                                entity:SetPos(util.TraceLine({["start"] = entity:GetPos(),["endpos"] = entity:GetPos() + Vector(0,0,10000),["filter"] = {},["whitelist"] = true})["HitPos"] + Vector(0,0,offset * -1))
                            else
                                entity:SetPos(util.TraceLine({["start"] = entity:GetPos(),["endpos"] = entity:GetPos() - Vector(0,0,10000),["filter"] = {},["whitelist"] = true})["HitPos"] + Vector(0,0,offset))
                            end
                        end
                        entity:SetPos(entity:GetPos() + Vector(0,0,0))
                        if entity:IsNPC() then
                            if !IsWaterNpc(entity) or entity:WaterLevel() > 2 or !NavHasWater() then break end
                        end
                    end
                    entity:Spawn()
                    table.insert(spawnedents,entity)
                else print("YOU NEED A NAVMESH FOR THE SPAWNER, DINGUS!!!") end
            end
        else print("No entities to spawn!") end
    end

    concommand.Add("entspawner_print_pool", function(ply,cmd,args) -- debugging
        if forceentry == false or args then
            GamerSpawnerGetLists(args[1])
            PrintTable(entslist)
            GamerSpawnerGetLists()
        else
            PrintTable(entslist[forceentry])
        end
    end)

    -- concommand.Add("entspawner_refresh_pool", function() -- obsolete
    --     GamerSpawnerGetLists()
    -- end)

    concommand.Add("entspawner_print_spawned", function()
        print(GamerSpawnerSpawnedCount(true))
    end)

    concommand.Add("entspawner_force", function()
        GamerSpawnRandomEntity()
    end)

    -- concommand.Add("entspawner_watertest", function() -- testing
    --     print(NavHasWater())
    -- end)

    timer.Create("GAMERENTSPAWNTIMER", spawningtime:GetFloat(),0, function()
        timer.Adjust("GAMERENTSPAWNTIMER",spawningtime:GetFloat())
        if enabletimer:GetBool() then
            if GamerSpawnerSpawnedCount(false) < spawnmax:GetInt() then
                GamerSpawnRandomEntity()
            end
        end
    end)
else
    -- client side
    hook.Add( "PopulateToolMenu", "GASpawnerOptions", function()
        spawnmenu.AddToolMenuOption( "Utilities", "Admin", "entspawnermenu", "#Entity Spawner Options", "", "", function(panel)
            panel:CheckBox("Enable automated spawning", "entspawner_enable")
            panel:CheckBox("Enable NPCs", "entspawner_enable_npcs"):SetIndent(8)
            panel:CheckBox("Enable NPC Weapon randomization", "entspawner_rand_npcweps"):SetIndent(16)
            panel:ControlHelp("May cause minor oddities, but anything other than NPCs spawned here will be completely fine."):DockMargin(48,0,48,8)
            panel:CheckBox("Enable SENTs", "entspawner_enable_sents"):SetIndent(8)
            panel:CheckBox("Enable Weapons", "entspawner_enable_weps"):SetIndent(8)
            panel:CheckBox("Enable Vehicles", "entspawner_enable_cars"):SetIndent(8)
            panel:CheckBox("Enable Admin-Only Entities", "entspawner_enable_admin"):SetIndent(8)
            panel:NumSlider("Spawn delay", "entspawner_waitingtime",0,86400,0)
            panel:NumSlider("Maximum entities", "entspawner_maximum",0,1000,0)
            panel:CheckBox("Printing for debug", "entspawner_print")
        end )
    end )

end
