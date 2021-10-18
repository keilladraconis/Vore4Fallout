Scriptname V4F_EnduranceQ extends Quest
V4F_VoreCore Property VoreCore Auto Const Mandatory
Spell Property V4F_Endurance Auto
Perk Property V4F_Endurance1 Auto
Perk Property V4F_Endurance2 Auto
Perk Property V4F_Endurance3 Auto
Perk Property V4F_Endurance4 Auto
Perk Property V4F_Endurance5 Auto

float PerkProgress = 0.0
float PerkDecay = 0.001
float PerkRate = 0.2
int version
; This is used for updating script-level variables. To invoke this, also update the OnPlayerLoadGame event to bump the version
function Updateversion(int v)
    if v > version
        PerkDecay = 0.001
        PerkRate = 0.2
        version = v
    endif
endfunction

Event Actor.OnPlayerLoadGame(Actor akSender)
	Updateversion(3)
    GotoState("")
EndEvent

Actor Player
ActorValue EnduranceAV

; Called when the quest initializes
Event OnInit()
    Player = Game.GetPlayer()
    EnduranceAV = Game.GetEnduranceAV()
    RegisterForRemoteEvent(Player, "OnPlayerLoadGame")
    RegisterForRemoteEvent(Player, "OnDifficultyChanged")
    RegisterForCustomEvent(VoreCore, "VoreEvent")
    RegisterForCustomEvent(VoreCore, "StomachStrainEvent")
    UpdateDifficultyScaling(Game.GetDifficulty())
    RegisterForCustomEvent(VoreCore, "VoreTimeEvent")
EndEvent

float difficultyScaling
Event Actor.OnDifficultyChanged(Actor akSender, int aOldDifficulty, int aNewDifficulty)
    UpdateDifficultyScaling(aNewDifficulty)
EndEvent

function UpdateDifficultyScaling(int difficulty)
    difficulty += 1
    if difficulty > 5
        difficulty = 5
    endif
    difficultyScaling = 5.0 / difficulty
endfunction

; ======
; EVENTS
; ======
Event V4F_VoreCore.VoreTimeEvent(V4F_VoreCore akSender, Var[] akArgs)
    float timeDelta = akArgs[0] as float
    PerkDecay(timeDelta / 3600.0)
    Debug.Trace("AgilityQ:" + PerkProgress)
EndEvent

Event V4F_VoreCore.VoreEvent(V4F_VoreCore akSender, Var[] akArgs)
    Increment()
EndEvent

Event V4F_VoreCore.StomachStrainEvent(V4F_VoreCore akSender, Var[] akArgs)
    Increment()
EndEvent

; ========
; Public
; ========

float Function BellyMax()
    ; An hockey-stick function targeting 6.0 at Endurance 10
    return 0.05 + (0.06 * Math.pow(Player.GetValue(EnduranceAV) / 2.8, 3) * difficultyScaling) 
EndFunction

function Increment()
    GotoState("Cooldown")
    PerkProgress += PerkRate * difficultyScaling
    ApplyPerks()
    Debug.Trace("EnduranceQ +:" + PerkProgress)
    if PerkProgress > 7.5
        PerkProgress = 7.5
    endif
    StartTimerGameTime(1.0)
endfunction

function StomachStrain(float bellyTotal)
    if bellyTotal / BellyMax() > 0.8
        Increment()
    endif
endfunction

state Cooldown
    function Increment()
        Debug.Trace("EnduranceQ Cooldown")
    endfunction
endstate

; ========
; Private
; ========

function PerkDecay(float time)
    if PerkProgress > 0.0
        PerkProgress -= time * PerkDecay * difficultyScaling
        if PerkProgress < 0.0
            PerkProgress = 0.0
        endif
        ApplyPerks()
        Debug.Trace("EnduranceQ -:" + PerkProgress)
    endif
endfunction

function ApplyPerks()
    if PerkProgress >= 5.0
        Player.AddPerk(V4F_Endurance1)
        Player.AddPerk(V4F_Endurance2)
        Player.AddPerk(V4F_Endurance3)
        Player.AddPerk(V4F_Endurance4)
        Player.AddPerk(V4F_Endurance5)
        Player.AddSpell(V4F_Endurance, false)
    elseif PerkProgress >= 4.0
        Player.AddPerk(V4F_Endurance1)
        Player.AddPerk(V4F_Endurance2)
        Player.AddPerk(V4F_Endurance3)
        Player.AddPerk(V4F_Endurance4)
        Player.RemovePerk(V4F_Endurance5)   
        Player.AddSpell(V4F_Endurance, false)
    elseif PerkProgress >= 3.0
        Player.AddPerk(V4F_Endurance1)
        Player.AddPerk(V4F_Endurance2)
        Player.AddPerk(V4F_Endurance3)
        Player.RemovePerk(V4F_Endurance4)
        Player.RemovePerk(V4F_Endurance5)
        Player.AddSpell(V4F_Endurance, false)
    elseif PerkProgress >= 2.0
        Player.AddPerk(V4F_Endurance1)
        Player.AddPerk(V4F_Endurance2)
        Player.RemovePerk(V4F_Endurance3)
        Player.RemovePerk(V4F_Endurance4)
        Player.RemovePerk(V4F_Endurance5)
        Player.AddSpell(V4F_Endurance, false)
    elseif PerkProgress >= 1.0
        Player.AddPerk(V4F_Endurance1)
        Player.RemovePerk(V4F_Endurance2)
        Player.RemovePerk(V4F_Endurance3)
        Player.RemovePerk(V4F_Endurance4)
        Player.RemovePerk(V4F_Endurance5)
        Player.AddSpell(V4F_Endurance, false)
    else
        Player.RemovePerk(V4F_Endurance1)
        Player.RemovePerk(V4F_Endurance2)
        Player.RemovePerk(V4F_Endurance3)
        Player.RemovePerk(V4F_Endurance4)
        Player.RemovePerk(V4F_Endurance5)
        Player.RemoveSpell(V4F_Endurance)
    endif
endfunction