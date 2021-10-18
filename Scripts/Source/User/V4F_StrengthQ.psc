Scriptname V4F_StrengthQ extends Quest
V4F_VoreCore Property VoreCore Auto Const Mandatory
Spell Property V4F_Strength Auto Const
Perk Property V4F_Strength1 Auto Const
Perk Property V4F_Strength2 Auto Const
Perk Property V4F_Strength3 Auto Const
Perk Property V4F_Strength4 Auto Const
Perk Property V4F_Strength5 Auto Const

float PerkProgress = 0.0
float PerkDecay = 0.001
float PerkRate = 0.04
int version
; This is used for updating script-level variables. To invoke this, also update the OnPlayerLoadGame event to bump the version
function Updateversion(int v)
    if v > version
        PerkDecay = 0.001
        PerkRate = 0.04
        RegisterForCustomEvent(VoreCore, "VoreTimeEvent")
        version = v
    endif
endfunction

Event Actor.OnPlayerLoadGame(Actor akSender)
	Updateversion(6)
    GotoState("")
EndEvent

Actor Player
ActorValue StrengthAV

; Called when the quest initializes
Event OnInit()
    Player = Game.GetPlayer()
    StrengthAV = Game.GetStrengthAV()
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

Event V4F_VoreCore.BodyShapeEvent(V4F_VoreCore akSender, Var[] args)
    float muscle = args[3] as float
    ApplyPerks(muscle)
EndEvent

; ========
; Public
; ========

float function HealthPctLimit()
    return Player.GetValue(StrengthAV) / 10.0
endfunction

function Increment()
    PerkProgress += PerkRate * difficultyScaling
    UpdatePerkProgress()
endfunction

; ========
; Private
; ========

function UpdatePerkProgress()
    if PerkProgress > 2.0
        PerkProgress = 2.0
    elseif PerkProgress < 0.0
        PerkProgress = 0.0
    endif

    if PerkProgress <= 1.0
        VoreCore.MuscleMax = PerkProgress
    else
        VoreCore.MuscleMax = 1.0
    endif
    Debug.Trace("StrengthQ:" + PerkProgress)
endfunction

function PerkDecay(float time)
    PerkProgress -= time * PerkDecay * difficultyScaling
    UpdatePerkProgress()
endfunction

function ApplyPerks(float muscle)
    if muscle >= 1.0
        Player.AddPerk(V4F_Strength1)
        Player.AddPerk(V4F_Strength2)
        Player.AddPerk(V4F_Strength3)
        Player.AddPerk(V4F_Strength4)
        Player.AddPerk(V4F_Strength5)
        Player.AddSpell(V4F_Strength, false)
    elseif muscle >= 0.8
        Player.AddPerk(V4F_Strength1)
        Player.AddPerk(V4F_Strength2)
        Player.AddPerk(V4F_Strength3)
        Player.AddPerk(V4F_Strength4)
        Player.RemovePerk(V4F_Strength5)   
        Player.AddSpell(V4F_Strength, false)
    elseif muscle >= 0.6
        Player.AddPerk(V4F_Strength1)
        Player.AddPerk(V4F_Strength2)
        Player.AddPerk(V4F_Strength3)
        Player.RemovePerk(V4F_Strength4)
        Player.RemovePerk(V4F_Strength5)
        Player.AddSpell(V4F_Strength, false)
    elseif muscle >= 0.4
        Player.AddPerk(V4F_Strength1)
        Player.AddPerk(V4F_Strength2)
        Player.RemovePerk(V4F_Strength3)
        Player.RemovePerk(V4F_Strength4)
        Player.RemovePerk(V4F_Strength5)
        Player.AddSpell(V4F_Strength, false)
    elseif muscle >= 0.2
        Player.AddPerk(V4F_Strength1)
        Player.RemovePerk(V4F_Strength2)
        Player.RemovePerk(V4F_Strength3)
        Player.RemovePerk(V4F_Strength4)
        Player.RemovePerk(V4F_Strength5)
        Player.AddSpell(V4F_Strength, false)
    else
        Player.RemovePerk(V4F_Strength1)
        Player.RemovePerk(V4F_Strength2)
        Player.RemovePerk(V4F_Strength3)
        Player.RemovePerk(V4F_Strength4)
        Player.RemovePerk(V4F_Strength5)
        Player.RemoveSpell(V4F_Strength)
    endif
endfunction