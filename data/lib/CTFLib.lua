--[[
        Capture The Flag System
        Author: Maxwell Denisson(MaXwEllDeN)
        Version: 2.0 [REMAKE] 22/04/2013
        Contact: maxwellmda@gmail.com
]]

CTF_LIB = {
        waitpos = {x = 347, y = 73, z = 7}, -- Posi��o da sala de espera
        tppos = {x = 32339, y = 32213, z = 7}, -- Onde o TP vai aparecer

        days = {2, 3, 4, 5, 6, 7, 1}, -- Dias que o evento vai abrir
        xp_percent = 0.5, -- Porcentagem de exp que o player vai ganhar
        timeclose = 5, -- Tempo, em minutos, para iniciar o CTF
        winp = 10, -- Quantos pontos uma equipe precisa marcar para vencer

        teams = {
                ["Vermelho"] = {
                        temple = 27, -- TownID da equipe vermelha
                        outfit = {lookHead = 0, lookBody = 132, lookLegs = 113, lookFeet = 94},

                        flag = {
                                id = 1435,
                                flag_pos = {x = 375, y = 78, z = 6}, -- Posi��o onde a bandeira vermelha vai ser criada
                                gnd_pos = {x = 380, y = 77, z = 6}, -- Onde os players da equipe vermelha entregar�o a bandeira.
                        },
                },

                ["Verde"] = {
                        temple = 26, -- TownID da equipe verde
                        outfit = {lookHead = 0, lookBody = 121, lookLegs = 101, lookFeet = 101},

                        flag = {
                                id = 1437,
                                flag_pos = {x = 384, y = 78, z = 6}, -- Posi��o onde a bandeira verde vai ser criada
                                gnd_pos = {x = 379, y = 77, z = 6}, -- Onde os players da equipe verde entregar�o a bandeira.
                        },
                },
        },
}

local CTF = CTF_LIB

function CTF.getMembers()
        local members = {}

        for _, cid in pairs(getPlayersOnline()) do
                if getPlayerStorageValue(cid, 16700) ~= -1 then
                        table.insert(members, cid)
                end
        end

        return members
end

function CTF.getTeamMembers(team)
        local members = {}

        for _, cid in pairs(CTF.getMembers()) do
                if getPlayerStorageValue(cid, 16700) == team then
                        table.insert(members, cid)
                end
        end

        return members
end

function CTF.removePlayer(uid)
        setPlayerStorageValue(uid, 16700, -1)
        doPlayerSetTown(uid, getPlayerStorageValue(uid, 16701))
        doTeleportThing(uid, getTownTemplePosition(getPlayerStorageValue(uid, 16701)))

        setPlayerStorageValue(uid, 16701, -1)

        doRemoveCondition(uid, CONDITION_OUTFIT)
        doCreatureAddHealth(uid, getCreatureMaxHealth(uid))
        doCreatureAddMana(uid, getCreatureMaxMana(uid))

        doTeleportThing(uid, getTownTemplePosition(getPlayerTown(uid)))

        return true
end

function CTF.addPlayer(uid)
        local team = CTF.getTeamLivre()
        local n_team = CTF.teams[team]

        setPlayerStorageValue(uid, 16700, team)
        setPlayerStorageValue(uid, 16701, getPlayerTown(uid))

        doPlayerSetTown(uid, n_team.temple)
        doTeleportThing(uid, CTF.waitpos)

        doPlayerSendTextMessage(uid, 22, "Voc� agora faz parte do time ".. team .. ".")

        local outfit = getCreatureOutfit(uid)

        for i, v in pairs(n_team.outfit) do
                outfit[i] = v
        end

        registerCreatureEvent(uid, "CTFLogout")
        registerCreatureEvent(uid, "CTFAttack")
        registerCreatureEvent(uid, "CTFCombat")
        registerCreatureEvent(uid, "CTFDeath")
        doSetCreatureOutfit(uid, outfit, -1)
        return true
end

function CTF.getTeamLivre()
        local teams = {}

        for i, _ in pairs(CTF.teams) do
                table.insert(teams, {i, #CTF.getTeamMembers(i)})
        end

        if (teams[1][2] < teams[2][2]) then
                return teams[1][1]
        elseif (teams[1][2] > teams[2][2]) then
                return teams[2][1]
        end

        return teams[math.random(2)][1]
end

function CTF.broadCast(msg, class)
        for _, uid in pairs(CTF.getMembers()) do
                doPlayerSendTextMessage(uid, class or 20, msg)
        end

        return true
end

function CTF.getFlagTeam(flag)
        for i, v in pairs(CTF.teams) do
                if v.flag.id == flag then
                        return i
                end
        end

        return ""
end

local score_sto = {}
local a = 0
for i, _ in pairs(CTF.teams) do
        score_sto[i] = 42314 + a
        a = a + 1
end

function CTF.createFlags()
        for i, v in pairs(CTF.teams) do
                local flag = doCreateItem(v.flag.id, 1, v.flag.flag_pos)
                doItemSetAttribute(flag, "aid", 63218)

                v.flag.gnd_pos.stackpos = 0
                local gnd = getThingFromPos(v.flag.gnd_pos).uid
                doItemSetAttribute(gnd, "aid", 63200)
                doItemSetAttribute(gnd, "team", i)

                setGlobalStorageValue(score_sto[i], 0)
        end

        return true
end

function CTF.removeFlags()
        for i, v in pairs(CTF.teams) do
                local flag = doFindItemInPos({v.flag.id}, v.flag.flag_pos)[1]
                if flag then
                        doRemoveItem(flag.uid, 1)
                end

                v.flag.gnd_pos.stackpos = 0
                local gnd = getThingFromPos(v.flag.gnd_pos).uid
                doItemSetAttribute(gnd, "aid", 0)
        end

        return true
end

function CTF.start()
        doRemoveItem(doFindItemInPos({1387}, CTF.tppos)[1].uid, 1)
        setGlobalStorageValue(16705, -1)

        if #CTF.getMembers() < 1 then
                doBroadcastMessage("O CTF n�o p�de ser iniciado por falta de players.")

                for _, cid in pairs(CTF.getMembers()) do
                        CTF.removePlayer(cid)
                end

                return false
        end

        CTF.broadCast("O CTF foi iniciado. Bom jogo!")

        for _, uid in pairs(CTF.getMembers()) do
                doTeleportThing(uid, getTownTemplePosition(getPlayerTown(uid)))
        end

        CTF.createFlags()
        return true
end

function CTF.returnFlag(uid, status)
        local team = getPlayerStorageValue(uid, 16702)

        if status then
                local msg = "O player ".. getCreatureName(uid) .. ", estava com a bandeira do time ".. team .. " "

                if status == 1 then
                        msg = msg .. "e foi eliminado. "
                elseif status == 2 then
                        msg = "e foi removido do evento. "
                end

                msg = msg .. "Portanto a bandeira do time ".. team .. " foi devolvida."
                CTF.broadCast(msg)
        end

        if CTF.teams[team] then
                local flag = doCreateItem(CTF.teams[team].flag.id, 1, CTF.teams[team].flag.flag_pos)
                doItemSetAttribute(flag, "aid", 63218)

                setPlayerStorageValue(uid, 16702, -1)
        end

        return true
end

function CTF.addPoint(uid)
        local finish
        local msg = "Capture The Flag:"

        setGlobalStorageValue(score_sto[getPlayerStorageValue(uid, 16700)], getGlobalStorageValue(score_sto[getPlayerStorageValue(uid, 16700)]) + 1)

        for i, _ in pairs(CTF.teams) do
                msg = msg .. "\nTime ".. i .. ": ".. getGlobalStorageValue(score_sto[i])

                if getGlobalStorageValue(score_sto[i]) >= CTF.winp then
                        finish = i
                end
        end

        CTF.broadCast(getCreatureName(uid) .. " marcou um ponto para o time ".. getPlayerStorageValue(uid, 16700) .. ".", 22)
        CTF.broadCast(msg)
        if finish then
                CTF.close(finish)
        end

        return true
end

function CTF.close(win)
        for i, _ in pairs(CTF.teams) do
                setGlobalStorageValue(score_sto[i], 0)
        end

        if not win then
                doBroadcastMessage("O CTF acabou sem vencedores.")
        else
                CTF.broadCast("O time ".. win .. " marcou ".. CTF.winp .. " ponto(s) e venceu o evento.")
        end

        for _, cid in pairs(CTF.getMembers()) do
                if getPlayerStorageValue(cid, 16700) == win then
                        local xp = math.ceil(getPlayerExperience(cid) * (CTF.xp_percent / 100), 215)
                        doPlayerSendTextMessage(cid, 22, "Parab�ns! Voc� ganhou um acesso a �rea VIP, uma Surprise Bag e tamb�m ".. CTF.xp_percent .."% de sua experi�ncia total(".. xp ..").")
                        doSendAnimatedText(getThingPos(cid), xp, 215)
                        doPlayerAddExperience(cid, xp)
                        doPlayerAddItem(cid, 6570, 1)
                        addEvent(doTeleportThing, 250, cid, {x = 32296,y = 32223,z = 7})
                end

                if getPlayerStorageValue(cid, 16702) ~= -1 then
                        CTF.returnFlag(cid)
                end

                CTF.removePlayer(cid)
        end

        CTF.removeFlags()
        return true
end

local function Alert(uid)
        if (isCreature(uid)) then
                if getPlayerStorageValue(uid, 16702) == -1 or getPlayerStorageValue(uid, 16700) == -1 then
                        return false
                end

                doSendAnimatedText(getThingPos(uid), "Flag!", math.random(50, 200))

                local bla = {18, 19, 21, 22, 23, 24}
                doSendMagicEffect(getThingPos(uid), bla[math.random(#bla)])

                if (os.time() - getPlayerStorageValue(uid, 16703) >= 60) then
                        CTF.returnFlag(uid)
                        return setPlayerStorageValue(uid, 16703, -1)
                end

                addEvent(Alert, 500, uid)
                return true
        end

        return false
end

function CTF.stealFlag(uid, team)
        setPlayerStorageValue(uid, 16702, team)
        setPlayerStorageValue(uid, 16703, os.time())

        CTF.broadCast(getCreatureName(uid) .. " roubou a bandeira do time ".. team .. "!")
        Alert(uid)
        return true
end

function doFindItemInPos(ids, pos) -- By Undead Slayer
        local results = {}

        for _ = 0, 255 do
                local findPos = {x = pos.x, y = pos.y, z = pos.z, stackpos = _}
                if isInArray(ids, getThingFromPos(findPos).itemid) then
                        table.insert(results, getThingFromPos(findPos))
                end
        end

        return results
end
