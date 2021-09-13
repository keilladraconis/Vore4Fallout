Scriptname V4F_Endurance extends Perk
{Handles endurance-related effects of vore.}

V4F_VoreCore Property VoreCore Auto Const Mandatory

float EndurancePerkRate
float EndurancePerkProgress

Actor Player

function Setup()
    EndurancePerkProgress = 0
    EndurancePerkRate = 1.0
    Player = Game.GetPlayer()
    RegisterForCustomEvent(VoreCore, "EnduranceUpdate")
    ApplyPerks()
endfunction

event V4F_VoreCore.EnduranceUpdate(V4F_VoreCore caller, Var[] args)
    EndurancePerkProgress += EndurancePerkRate
    ApplyPerks()
endevent

function ApplyPerks()
    if EndurancePerkProgress > 1.0
        Player.AddPerk(self)
        Debug.Trace("Added Perk")
    elseif EndurancePerkProgress > 2.0
        Player.AddPerk(self)
    else
        Debug.Trace("Removing perk")
    endif
endfunction