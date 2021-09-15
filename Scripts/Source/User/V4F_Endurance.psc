Scriptname V4F_Endurance extends Perk
{Handles endurance-related effects of vore.}

V4F_VoreCore Property VoreCore Auto Const Mandatory

Perk Property V4F_Endurance1 Auto
Perk Property V4F_Endurance2 Auto
Perk Property V4F_Endurance3 Auto
Perk Property V4F_Endurance4 Auto
Perk Property V4F_Endurance5 Auto

float EndurancePerkRate
float EndurancePerkProgress
float EndurancePerkDecay

Actor Player

function Setup()
    EndurancePerkProgress = 0
    EndurancePerkRate = 0.025
    EndurancePerkDecay = 0.125
    Player = Game.GetPlayer()
    RegisterForCustomEvent(VoreCore, "EnduranceUpdate")
    RegisterForCustomEvent(VoreCore, "SleepUpdate")
    ApplyPerks()
    StartTimer(3600.0, 20)
endfunction

event V4F_VoreCore.EnduranceUpdate(V4F_VoreCore caller, Var[] args)
    EndurancePerkProgress += EndurancePerkRate
    ApplyPerks()
endevent

event V4F_VoreCore.SleepUpdate(V4F_VoreCore caller, Var[] args)
    Debug.Trace("SleepUpdate")
    PerkDecay(args[0] as float)
endevent

event OnTimer(int timer)
    PerkDecay(1.0)
    StartTimer(3600.0, 20)
endevent

function ApplyPerks()
    Player.RemovePerk(V4F_Endurance1)
    Player.RemovePerk(V4F_Endurance2)
    Player.RemovePerk(V4F_Endurance3)
    Player.RemovePerk(V4F_Endurance4)
    Player.RemovePerk(V4F_Endurance5)
    if EndurancePerkProgress >= 1.0
        Player.AddPerk(V4F_Endurance1)
    endif
    if EndurancePerkProgress >= 2.0
        Player.AddPerk(V4F_Endurance2)
    endif
    if EndurancePerkProgress >= 3.0
        Player.AddPerk(V4F_Endurance3)
    endif
    if EndurancePerkProgress >= 4.0
        Player.AddPerk(V4F_Endurance4)
    endif
    if EndurancePerkProgress >= 5.0
        Player.AddPerk(V4F_Endurance5)
    endif
    StartTimer(3600.0, 20)
endfunction

function PerkDecay(float time)
    EndurancePerkProgress -= time * EndurancePerkDecay
    ApplyPerks()
endfunction