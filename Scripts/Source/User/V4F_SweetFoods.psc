Scriptname V4F_SweetFoods extends activemagiceffect

V4F_VoreCore Property VoreCore Auto Const Mandatory
Perk Property V4F_Intelligence1 Auto Const
Perk Property V4F_Intelligence2 Auto Const
Perk Property V4F_Intelligence3 Auto Const
Perk Property V4F_Intelligence4 Auto Const
Perk Property V4F_Intelligence5 Auto Const

float IntelligencePerkRate
float IntelligencePerkProgress
float IntelligencePerkDecay

Actor Player

function Setup()
    IntelligencePerkProgress = 0
    IntelligencePerkRate = 0.025
    IntelligencePerkDecay = 0.125
    Player = Game.GetPlayer()
    RegisterForCustomEvent(VoreCore, "SleepUpdate")
    ApplyPerks()
    StartTimer(3600.0, 30)
endfunction

event V4F_VoreCore.SleepUpdate(V4F_VoreCore caller, Var[] args)
    Debug.Trace("SleepUpdate")
    PerkDecay(args[0] as float)
endevent

event OnTimer(int timer)
    PerkDecay(1.0)
    StartTimer(3600.0, 30)
endevent

event OnEffectStart(Actor akTarget, Actor akCaster)
    IntelligencePerkProgress += IntelligencePerkRate
endevent

function ApplyPerks()
    Player.RemovePerk(V4F_Intelligence1)
    Player.RemovePerk(V4F_Intelligence2)
    Player.RemovePerk(V4F_Intelligence3)
    Player.RemovePerk(V4F_Intelligence4)
    Player.RemovePerk(V4F_Intelligence5)
    if IntelligencePerkProgress >= 1.0
        Player.AddPerk(V4F_Intelligence1)
        Debug.Trace("Added Perk 1" + V4F_Intelligence1)
    endif
    if IntelligencePerkProgress >= 2.0
        Player.AddPerk(V4F_Intelligence2)
        Debug.Trace("Added Perk 2" + V4F_Intelligence2)
    endif
    if IntelligencePerkProgress >= 3.0
        Player.AddPerk(V4F_Intelligence3)
        Debug.Trace("Added Perk 3" + V4F_Intelligence3)
    endif
    if IntelligencePerkProgress >= 4.0
        Player.AddPerk(V4F_Intelligence4)
        Debug.Trace("Added Perk 4" + V4F_Intelligence4)
    endif
    if IntelligencePerkProgress >= 5.0
        Player.AddPerk(V4F_Intelligence5)
        Debug.Trace("Added Perk 5" + V4F_Intelligence5)
    endif
    StartTimer(3600.0, 30)
endfunction

function PerkDecay(float time)
    IntelligencePerkProgress -= time * IntelligencePerkDecay
    ApplyPerks()
endfunction