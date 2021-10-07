Scriptname V4F_CharismaQ extends Quest
V4F_VoreCore Property VoreCore Auto Const Mandatory
Perk Property V4F_Charisma1 Auto Const
Perk Property V4F_Charisma2 Auto Const
Perk Property V4F_Charisma3 Auto Const
Perk Property V4F_Charisma4 Auto Const
Perk Property V4F_Charisma5 Auto Const
float PerkProgress = 0.0
float previousTime

float PerkDecay = 0.1
float PerkRate = 0.2
int version = 1
; This is used for updating script-level variables. To invoke this, also update the OnPlayerLoadGame event to bump the version
function Updateversion(int v)
    if v > version
        PerkDecay = 0.1
        PerkRate = 0.2
        version = v
    endif
endfunction

Event Actor.OnPlayerLoadGame(Actor akSender)
	Updateversion(1)
EndEvent

Actor Player

; Called when the quest initializes
Event OnInit()
    StartTimer(3600.0, 1)
    StartTimer(60.0, 10)
    Player = Game.GetPlayer()
    Self.RegisterForPlayerSleep()
    Self.RegisterForPlayerWait()
    Self.RegisterForPlayerTeleport()
    previousTime = Utility.GetCurrentGameTime()
    RegisterForRemoteEvent(Player, "OnPlayerLoadGame")
    RegisterForRemoteEvent(Player, "OnDifficultyChanged")
    RegisterForCustomEvent(VoreCore, "BodyShapeEvent")
    UpdateDifficultyScaling(Game.GetDifficulty())
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
Event OnPlayerSleepStart(float afSleepStartTime, float afDesiredSleepEndTime, ObjectReference akBed)
    previousTime = afSleepStartTime
EndEvent

Event OnPlayerWaitStart(float afWaitStartTime, float afDesiredWaitEndTime)
    previousTime = afWaitStartTime
EndEvent

Event OnPlayerSleepStop(bool abInterrupted, ObjectReference akBed)
    HandleTimeSkip()
EndEvent

Event OnPlayerWaitStop(bool abInterrupted)
    HandleTimeSkip()
EndEvent

Event OnPlayerTeleport()
    HandleTimeSkip()
EndEvent

function HandleTimeSkip()
    ; Time is reported as a floating point number where 1 is a whole day. 1 hour is 1/24 expressed as a decimal. (1.0 / 24.0) * 60 * 60 = 150
    float timeDelta = (Utility.GetCurrentGameTime() - previousTime) / (1.0 / 24.0) * 60 * 60
    previousTime = Utility.GetCurrentGameTime()
    PerkDecay(timeDelta / 3600.0)
endfunction

Event OnTimer(int timer)
    if timer == 1
        PerkDecay(1.0)
        StartTimer(3600.0, 1)
    else
        previousTime = Utility.GetCurrentGameTime()
        StartTimer(60.0, 10)
    endif
endevent

Event V4F_VoreCore.BodyShapeEvent(V4F_VoreCore akSender, Var[] args)
    float bottomFat = args[1] as float
    ApplyPerks(bottomFat)
EndEvent

; ========
; Public
; ========

function Increment()
    PerkProgress += PerkRate * difficultyScaling
    if PerkProgress > 1.0
        PerkProgress = 1.0
    endif
    VoreCore.ButtMax = PerkProgress
    Debug.Trace("CharismaQ +:" + PerkProgress)
endfunction

; ========
; Private
; ========

function PerkDecay(float time)
    PerkProgress -= time * PerkDecay * difficultyScaling
    if PerkProgress < 0.0
        PerkProgress = 0.0
    endif
    VoreCore.ButtMax = PerkProgress
    Debug.Trace("CharismaQ -:" + PerkProgress)
endfunction

function ApplyPerks(float bottomFat)
    Player.RemovePerk(V4F_Charisma1)
    Player.RemovePerk(V4F_Charisma2)
    Player.RemovePerk(V4F_Charisma3)
    Player.RemovePerk(V4F_Charisma4)
    Player.RemovePerk(V4F_Charisma5)
    if bottomFat >= 0.2
        Player.AddPerk(V4F_Charisma1)
    endif
    if bottomFat >= 0.4
        Player.AddPerk(V4F_Charisma2)
    endif
    if bottomFat >= 0.6
        Player.AddPerk(V4F_Charisma3)
    endif
    if bottomFat >= 0.8
        Player.AddPerk(V4F_Charisma4)
    endif
    if bottomFat >= 1.0
        Player.AddPerk(V4F_Charisma5)
    endif
endfunction