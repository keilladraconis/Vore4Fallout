Scriptname V4F_IntelligenceQ extends Quest
V4F_VoreCore Property VoreCore Auto Const Mandatory
Spell Property V4F_Intelligence Auto Const
Perk Property V4F_Intelligence1 Auto Const
Perk Property V4F_Intelligence2 Auto Const
Perk Property V4F_Intelligence3 Auto Const
Perk Property V4F_Intelligence4 Auto Const
Perk Property V4F_Intelligence5 Auto Const


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

; Called when the quest initializes
Event OnInit()
    Player = Game.GetPlayer()
    RegisterForRemoteEvent(Player, "OnPlayerLoadGame")
    RegisterForRemoteEvent(Player, "OnDifficultyChanged")
    RegisterForCustomEvent(VoreCore, "BodyShapeEvent")
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
    float topFat = args[0] as float
    ApplyPerks(topFat)
EndEvent

; ========
; Public
; ========

function Increment()
    PerkProgress += PerkRate * difficultyScaling
    UpdatePerkProgress()
endfunction

; ========
; Private
; ========

function UpdatePerkProgress()
    if PerkProgress > 4.0
        PerkProgress = 4.0
    elseif PerkProgress < 0.0
        PerkProgress = 0.0
    endif

    if PerkProgress >= 2.0
        VoreCore.BreastMax = 2.0
    else
        VoreCore.BreastMax = PerkProgress
    endif
    Debug.Trace("IntelligenceQ:" + PerkProgress)
endfunction

function PerkDecay(float time)
    PerkProgress -= time * PerkDecay * difficultyScaling
    UpdatePerkProgress()
endfunction

function ApplyPerks(float topFat)
    if topFat >= 1.0
        Player.AddPerk(V4F_Intelligence1)
        Player.AddPerk(V4F_Intelligence2)
        Player.AddPerk(V4F_Intelligence3)
        Player.AddPerk(V4F_Intelligence4)
        Player.AddPerk(V4F_Intelligence5)
        Player.AddSpell(V4F_Intelligence, false)
    elseif topFat >= 0.8
        Player.AddPerk(V4F_Intelligence1)
        Player.AddPerk(V4F_Intelligence2)
        Player.AddPerk(V4F_Intelligence3)
        Player.AddPerk(V4F_Intelligence4)
        Player.RemovePerk(V4F_Intelligence5)
        Player.AddSpell(V4F_Intelligence, false)   
    elseif topFat >= 0.6
        Player.AddPerk(V4F_Intelligence1)
        Player.AddPerk(V4F_Intelligence2)
        Player.AddPerk(V4F_Intelligence3)
        Player.RemovePerk(V4F_Intelligence4)
        Player.RemovePerk(V4F_Intelligence5)
        Player.AddSpell(V4F_Intelligence, false)
    elseif topFat >= 0.4
        Player.AddPerk(V4F_Intelligence1)
        Player.AddPerk(V4F_Intelligence2)
        Player.RemovePerk(V4F_Intelligence3)
        Player.RemovePerk(V4F_Intelligence4)
        Player.RemovePerk(V4F_Intelligence5)
        Player.AddSpell(V4F_Intelligence, false)
    elseif topFat >= 0.2
        Player.AddPerk(V4F_Intelligence1)
        Player.RemovePerk(V4F_Intelligence2)
        Player.RemovePerk(V4F_Intelligence3)
        Player.RemovePerk(V4F_Intelligence4)
        Player.RemovePerk(V4F_Intelligence5)
        Player.AddSpell(V4F_Intelligence, false)
    else
        Player.RemovePerk(V4F_Intelligence1)
        Player.RemovePerk(V4F_Intelligence2)
        Player.RemovePerk(V4F_Intelligence3)
        Player.RemovePerk(V4F_Intelligence4)
        Player.RemovePerk(V4F_Intelligence5)
        Player.RemoveSpell(V4F_Intelligence)
    endif
endfunction