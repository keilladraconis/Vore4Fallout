Scriptname V4F_AgilityQ extends Quest
V4F_VoreCore Property VoreCore Auto Const Mandatory
Spell Property V4F_Agility Auto Const
Perk Property V4F_Agility1 Auto Const
Perk Property V4F_Agility2 Auto Const
Perk Property V4F_Agility3 Auto Const
Perk Property V4F_Agility4 Auto Const
Perk Property V4F_Agility5 Auto Const
Perk Property V4F_VoreBurden1 Auto Const
Perk Property V4F_VoreBurden2 Auto Const
Perk Property V4F_VoreBurden3 Auto Const
Perk Property V4F_VoreBurden4 Auto Const
Perk Property V4F_VoreBurden5 Auto Const

float PerkProgress = 0.0
float previousTime

float PerkRate = 0.2
int version
; This is used for updating script-level variables. To invoke this, also update the OnPlayerLoadGame event to bump the version
function Updateversion(int v)
    if v > version
        PerkRate = 0.2
        RegisterForCustomEvent(VoreCore, "VoreTimeEvent")
        version = v
    endif
endfunction

Event Actor.OnPlayerLoadGame(Actor akSender)
	Updateversion(7)
    GotoState("")
EndEvent

Actor Player
ActorValue AgilityAV


; Called when the quest initializes
Event OnInit()
    Player = Game.GetPlayer()
    AgilityAV = Game.GetAgilityAV()
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
Event OnTimerGameTime(int timer)
    GotoState("")
endevent

Event V4F_VoreCore.VoreTimeEvent(V4F_VoreCore akSender, Var[] akArgs)
    float timeDelta = akArgs[0] as float
    PerkDecay(timeDelta / 3600.0)
    Debug.Trace("AgilityQ:" + PerkProgress)
EndEvent

; ========
; Public
; ========

function Increment(float amount = 1.0)
    GotoState("Cooldown")
    float burdenBonus = 1.0
    if Player.HasPerk(V4F_VoreBurden1)
        burdenBonus = 1.1
    ElseIf Player.HasPerk(V4F_VoreBurden2)
        burdenBonus = 1.2
    ElseIf Player.HasPerk(V4F_VoreBurden3)
        burdenBonus = 1.3
    ElseIf Player.HasPerk(V4F_VoreBurden4)
        burdenBonus = 1.4
    ElseIf Player.HasPerk(V4F_VoreBurden5)
        burdenBonus = 1.5
    endif
    PerkProgress += amount * burdenBonus * difficultyScaling
    ApplyPerks()
    StartTimerGameTime(1.0)
endfunction

state Cooldown
    function Increment(float amount = 1.0)
        Debug.Trace("Agility Increment Cooldown")
    endfunction
endstate

; ========
; Private
; ========

function PerkDecay(float time)
    PerkProgress -= time * PerkRate * difficultyScaling
    
    if PerkProgress < 0.0
        PerkProgress = 0.0
    endif
    ApplyPerks()
endfunction

function ApplyPerks()
    if PerkProgress >= 5.0
        Player.AddPerk(V4F_Agility1)
        Player.AddPerk(V4F_Agility2)
        Player.AddPerk(V4F_Agility3)
        Player.AddPerk(V4F_Agility4)
        Player.AddPerk(V4F_Agility5)
        Player.AddSpell(V4F_Agility, false)
    elseif PerkProgress >= 4.0
        Player.AddPerk(V4F_Agility1)
        Player.AddPerk(V4F_Agility2)
        Player.AddPerk(V4F_Agility3)
        Player.AddPerk(V4F_Agility4)
        Player.RemovePerk(V4F_Agility5)   
        Player.AddSpell(V4F_Agility, false)
    elseif PerkProgress >= 3.0
        Player.AddPerk(V4F_Agility1)
        Player.AddPerk(V4F_Agility2)
        Player.AddPerk(V4F_Agility3)
        Player.RemovePerk(V4F_Agility4)
        Player.RemovePerk(V4F_Agility5)
        Player.AddSpell(V4F_Agility, false)
    elseif PerkProgress >= 2.0
        Player.AddPerk(V4F_Agility1)
        Player.AddPerk(V4F_Agility2)
        Player.RemovePerk(V4F_Agility3)
        Player.RemovePerk(V4F_Agility4)
        Player.RemovePerk(V4F_Agility5)
        Player.AddSpell(V4F_Agility, false)
    elseif PerkProgress >= 1.0
        Player.AddPerk(V4F_Agility1)
        Player.RemovePerk(V4F_Agility2)
        Player.RemovePerk(V4F_Agility3)
        Player.RemovePerk(V4F_Agility4)
        Player.RemovePerk(V4F_Agility5)
        Player.AddSpell(V4F_Agility, false)
    else
        Player.RemovePerk(V4F_Agility1)
        Player.RemovePerk(V4F_Agility2)
        Player.RemovePerk(V4F_Agility3)
        Player.RemovePerk(V4F_Agility4)
        Player.RemovePerk(V4F_Agility5)
        Player.RemoveSpell(V4F_Agility)
    endif
endfunction