Scriptname V4F_CharismaQ extends Quest
V4F_VoreCore Property VoreCore Auto Const Mandatory
Spell Property V4f_Charisma Auto Const
Perk Property V4F_Charisma1 Auto Const
Perk Property V4F_Charisma2 Auto Const
Perk Property V4F_Charisma3 Auto Const
Perk Property V4F_Charisma4 Auto Const
Perk Property V4F_Charisma5 Auto Const

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
    GotoState("")
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

Event V4F_VoreCore.BodyShapeEvent(V4F_VoreCore akSender, Var[] args)
    float bottomFat = args[1] as float
    ApplyPerks(bottomFat)
EndEvent

Event V4F_VoreCore.VoreTimeEvent(V4F_VoreCore akSender, Var[] akArgs)
    float timeDelta = akArgs[0] as float
    PerkDecay(timeDelta / 3600.0)
    Debug.Trace("AgilityQ:" + PerkProgress)
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
        VoreCore.ButtMax = 2.0
    else
        VoreCore.ButtMax = PerkProgress
    endif
    Debug.Trace("CharismaQ:" + PerkProgress)
endfunction

function PerkDecay(float time)
    PerkProgress -= time * PerkDecay * difficultyScaling
    UpdatePerkProgress()
endfunction

function ApplyPerks(float bottomFat)
    if bottomFat >= 1.0
        Player.AddPerk(V4F_Charisma1)
        Player.AddPerk(V4F_Charisma2)
        Player.AddPerk(V4F_Charisma3)
        Player.AddPerk(V4F_Charisma4)
        Player.AddPerk(V4F_Charisma5)
        Player.AddSpell(V4F_Charisma, false)
    elseif bottomFat >= 0.8
        Player.AddPerk(V4F_Charisma1)
        Player.AddPerk(V4F_Charisma2)
        Player.AddPerk(V4F_Charisma3)
        Player.AddPerk(V4F_Charisma4)
        Player.RemovePerk(V4F_Charisma5)   
        Player.AddSpell(V4F_Charisma, false)
    elseif bottomFat >= 0.6
        Player.AddPerk(V4F_Charisma1)
        Player.AddPerk(V4F_Charisma2)
        Player.AddPerk(V4F_Charisma3)
        Player.RemovePerk(V4F_Charisma4)
        Player.RemovePerk(V4F_Charisma5)
        Player.AddSpell(V4F_Charisma, false)
    elseif bottomFat >= 0.4
        Player.AddPerk(V4F_Charisma1)
        Player.AddPerk(V4F_Charisma2)
        Player.RemovePerk(V4F_Charisma3)
        Player.RemovePerk(V4F_Charisma4)
        Player.RemovePerk(V4F_Charisma5)
        Player.AddSpell(V4F_Charisma, false)
    elseif bottomFat >= 0.2
        Player.AddPerk(V4F_Charisma1)
        Player.RemovePerk(V4F_Charisma2)
        Player.RemovePerk(V4F_Charisma3)
        Player.RemovePerk(V4F_Charisma4)
        Player.RemovePerk(V4F_Charisma5)
        Player.AddSpell(V4F_Charisma, false)
    else
        Player.RemovePerk(V4F_Charisma1)
        Player.RemovePerk(V4F_Charisma2)
        Player.RemovePerk(V4F_Charisma3)
        Player.RemovePerk(V4F_Charisma4)
        Player.RemovePerk(V4F_Charisma5)
        Player.RemoveSpell(V4F_Charisma)
    endif
endfunction