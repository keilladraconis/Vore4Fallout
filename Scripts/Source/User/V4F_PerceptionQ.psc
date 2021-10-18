Scriptname V4F_PerceptionQ extends Quest
V4F_VoreCore Property VoreCore Auto Const Mandatory
Spell Property V4F_Perception Auto Const
Perk Property V4F_Perception1 Auto Const
Perk Property V4F_Perception2 Auto Const
Perk Property V4F_Perception3 Auto Const
Perk Property V4F_Perception4 Auto Const
Perk Property V4F_Perception5 Auto Const
Perk Property V4F_VoreBurden1 Auto Const
Perk Property V4F_VoreBurden2 Auto Const
Perk Property V4F_VoreBurden3 Auto Const
Perk Property V4F_VoreBurden4 Auto Const
Perk Property V4F_VoreBurden5 Auto Const

float PerkProgress = 0.0
float healthRestore = 0.005 ; 5 hp per 1000 calories 
float digestionRate = 0.00011
float exerciseBoost = 0.0

float PerkDecay = 0.001
float PerkRate = 0.2
int version = 0
; This is used for updating script-level variables. To invoke this, also update the OnPlayerLoadGame event to bump the version
function Updateversion(int v)
    if v > version
        healthRestore = 0.005
        digestionRate = 0.00011
        PerkDecay = 0.001
        PerkRate = 0.2
        PerceptionAV = Game.GetPerceptionAV()
        RegisterForCustomEvent(VoreCore, "VoreTimeEvent")
        version = v
    endif
endfunction

Event Actor.OnPlayerLoadGame(Actor akSender)
	Updateversion(9)
    GotoState("")
EndEvent

Actor Player
ActorValue PerceptionAV

; Called when the quest initializes
Event OnInit()
    Player = Game.GetPlayer()
    RegisterForRemoteEvent(Player, "OnPlayerLoadGame")
    RegisterForRemoteEvent(Player, "OnDifficultyChanged")
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
; ========
; Public
; ========
function Increment()
    GotoState("Cooldown")
    PerkProgress += PerkRate * difficultyScaling
    ApplyPerks()
    Debug.Trace("PerceptionQ +:" + PerkProgress)
    if PerkProgress > 7.5
        PerkProgress = 7.5
    endif
    StartTimerGameTime(1.0)
endfunction

state Cooldown
    function Increment()
    endfunction
endstate

float function ComputeDigestion(float time)
    Debug.Trace("t: " + time + " dr: " + digestionRate + " pav: " + (1 + Player.GetValue(PerceptionAV) / 4.0) + " ds: " + difficultyScaling + " eb: " + (1 + exerciseBoost))
    float digestion =  time * digestionRate * (1 + Player.GetValue(PerceptionAV) / 4.0) * difficultyScaling * (1 + exerciseBoost)
    exerciseBoost = 0.0
    return digestion
endfunction

float function DigestHealthRestore()
    return healthRestore * difficultyScaling
endfunction

function SetExerciseBoost()
    float burdenBonus = 1.0
    if Player.HasPerk(V4F_VoreBurden1)
        burdenBonus = 0.2
    ElseIf Player.HasPerk(V4F_VoreBurden2)
        burdenBonus = 0.4
    ElseIf Player.HasPerk(V4F_VoreBurden3)
        burdenBonus = 0.8
    ElseIf Player.HasPerk(V4F_VoreBurden4)
        burdenBonus = 1.0
    ElseIf Player.HasPerk(V4F_VoreBurden5)
        burdenBonus = 3.0
    endif
    exerciseBoost = burdenBonus
endfunction

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
        Debug.Trace("PerceptionQ -:" + PerkProgress)
    endif
endfunction

function ApplyPerks()
    if PerkProgress >= 5.0
        Player.AddPerk(V4F_Perception1)
        Player.AddPerk(V4F_Perception2)
        Player.AddPerk(V4F_Perception3)
        Player.AddPerk(V4F_Perception4)
        Player.AddPerk(V4F_Perception5)
        Player.AddSpell(V4F_Perception, false)
    elseif PerkProgress >= 4.0
        Player.AddPerk(V4F_Perception1)
        Player.AddPerk(V4F_Perception2)
        Player.AddPerk(V4F_Perception3)
        Player.AddPerk(V4F_Perception4)
        Player.RemovePerk(V4F_Perception5)   
        Player.AddSpell(V4F_Perception, false)
    elseif PerkProgress >= 3.0
        Player.AddPerk(V4F_Perception1)
        Player.AddPerk(V4F_Perception2)
        Player.AddPerk(V4F_Perception3)
        Player.RemovePerk(V4F_Perception4)
        Player.RemovePerk(V4F_Perception5)
        Player.AddSpell(V4F_Perception, false)
    elseif PerkProgress >= 2.0
        Player.AddPerk(V4F_Perception1)
        Player.AddPerk(V4F_Perception2)
        Player.RemovePerk(V4F_Perception3)
        Player.RemovePerk(V4F_Perception4)
        Player.RemovePerk(V4F_Perception5)
        Player.AddSpell(V4F_Perception, false)
    elseif PerkProgress >= 1.0
        Player.AddPerk(V4F_Perception1)
        Player.RemovePerk(V4F_Perception2)
        Player.RemovePerk(V4F_Perception3)
        Player.RemovePerk(V4F_Perception4)
        Player.RemovePerk(V4F_Perception5)
        Player.AddSpell(V4F_Perception, false)
    else
        Player.RemovePerk(V4F_Perception1)
        Player.RemovePerk(V4F_Perception2)
        Player.RemovePerk(V4F_Perception3)
        Player.RemovePerk(V4F_Perception4)
        Player.RemovePerk(V4F_Perception5)
        Player.RemoveSpell(V4F_Perception)
    endif
endfunction