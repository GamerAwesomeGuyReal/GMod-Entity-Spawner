local entslist = {}
local forcepos = false -- turn on to force all npcs to spawn at player 1
local forceentry = false -- change to number from 0 to force a specific number entity to spawn. use print pool!
local enabletimer = CreateConVar("entspawner_enable",0,{FCVAR_ARCHIVE},"Enables the timer for randomly spawning entities.",0,1)
local enablenpcs = CreateConVar("entspawner_enable_npcs",1,{FCVAR_ARCHIVE},"Enables spawning npcs from the spawn menu.",0,1)
local enablesents = CreateConVar("entspawner_enable_sents",1,{FCVAR_ARCHIVE},"Enables spawning sents from the spawn menu.",0,1)
local enableweps = CreateConVar("entspawner_enable_weps",1,{FCVAR_ARCHIVE},"Enables spawning weapons from the spawn menu.",0,1)
local enablecars = CreateConVar("entspawner_enable_cars",1,{FCVAR_ARCHIVE},"Enables spawning vehicles from the spawn menu.",0,1)
local spawningtime = CreateConVar("entspawner_waitingtime",5,{FCVAR_ARCHIVE},"Decides the time between spawns")
local spawnmax = CreateConVar("entspawner_maximum",50,{FCVAR_ARCHIVE},"Decides the maximum entities.")
local printing = CreateConVar("entspawner_print",0,{FCVAR_ARCHIVE},"For debugging",0,1)
local spawnedents = {}

local function list2list(type)
    for i,e in pairs(list.Get(type)) do
        table.insert(entslist,e)
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
    if #entslist != 0 then
        if GamerSpawnerSpawnedCount(false) < spawnmax:GetInt() then
            GamerSpawnerGetLists()
            local navarea = navmesh.GetAllNavAreas()
            navarea = navarea[math.random(#navarea)]

            if navarea then
                local spawntype = false
                local entnumber = math.random( #entslist ) -- pick the entity
                if forceentry != false then entnumber = forceentry end

                local entity = entslist[entnumber]["Class"] -- set class for npcs
                if !entity then entity = entslist[entnumber]["ClassName"] end -- for sents
                entity = ents.Create(entity)

                if printing:GetBool() then -- to find the troublesomes
                    print(entity:GetClass())
                end

                if table.HasValue(table.GetKeys(entslist[entnumber]),"Weapons") then -- weapons
                    local weaponnumber = math.random(#entslist[entnumber]["Weapons"]) -- get random weapon
                    entity:Give(entslist[entnumber]["Weapons"][weaponnumber])
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

                if table.HasValue(table.GetKeys(entslist[entnumber]),"OnCeiling") then -- ceiling req
                    if entslist[entnumber]["OnCeiling"] == true then
                        spawntype = ceiling
                    end
                end

                if forcepos == true then
                    entity:SetPos(Entity(1):GetPos() + Vector(0,200,0))
                else
                    entity:SetPos(navarea:GetCenter() + Vector(0,0,navarea:GetSizeY() / 2))
                end
                if spawntype == ceiling then
                    entity:SetPos(util.TraceLine({["start"] = entity:GetPos(),["endpos"] = entity:GetPos() + Vector(0,0,10000),["filter"] = {},["whitelist"] = true})["HitPos"])
                end
                entity:Spawn()
                table.insert(spawnedents,entity)
            else print("YOU NEED A NAVMESH FOR THE SPAWNER, DINGUS!!!") end
        else
        end
    else print("No entities to spawn!") end
end

concommand.Add("entspawner_print_pool", function(ply,cmd,args) -- debugging
    if forceentry == false then
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

timer.Create("GAMERENTSPAWNTIMER", spawningtime:GetFloat(),0, function()
    timer.Adjust("GAMERENTSPAWNTIMER",spawningtime:GetFloat())
    if enabletimer:GetBool() then
        GamerSpawnRandomEntity()
    end
end)