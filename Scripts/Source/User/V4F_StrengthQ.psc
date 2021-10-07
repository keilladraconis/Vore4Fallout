Scriptname V4F_StrengthQ extends Quest
V4F_VoreCore Property VoreCore Auto Const Mandatory
Perk Property V4F_Strength1 Auto Const
Perk Property V4F_Strength2 Auto Const
Perk Property V4F_Strength3 Auto Const
Perk Property V4F_Strength4 Auto Const
Perk Property V4F_Strength5 Auto Const

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
ActorValue StrengthAV

; Called when the quest initializes
Event OnInit()
    StartTimer(3600.0, 1)
    StartTimer(60.0, 10)
    Player = Game.GetPlayer()
    StrengthAV = Game.GetStrengthAV()
    Self.RegisterForPlayerSleep()
    Self.RegisterForPlayerWait()
    Self.RegisterForPlayerTeleport()
    previousTime = Utility.GetCurrentGameTime()
    RegisterForRemoteEvent(Player, "OnPlayerLoadGame")
    RegisterForRemoteEvent(Player, "OnDifficultyChanged")
    RegisterForCustomEvent(VoreCore, "VoreEvent")
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

Event V4F_VoreCore.VoreEvent(V4F_VoreCore sender, Var[] args)
    Increment()
endevent

; ========
; Public
; ========

float function HealthPctLimit()
    return Player.GetValue(StrengthAV) / 10.0
endfunction

function Increment()
    PerkProgress += PerkRate * difficultyScaling
    ApplyPerks()
    Debug.Trace("StrengthQ +:" + PerkProgress)
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
        Debug.Trace("StrengthQ -:" + PerkProgress)
    endif
endfunction

function ApplyPerks()
    Player.RemovePerk(V4F_Strength1)
    Player.RemovePerk(V4F_Strength2)
    Player.RemovePerk(V4F_Strength3)
    Player.RemovePerk(V4F_Strength4)
    Player.RemovePerk(V4F_Strength5)
    if PerkProgress >= 1.0
        Player.AddPerk(V4F_Strength1)
    endif
    if PerkProgress >= 2.0
        Player.AddPerk(V4F_Strength2)
    endif
    if PerkProgress >= 3.0
        Player.AddPerk(V4F_Strength3)
    endif
    if PerkProgress >= 4.0
        Player.AddPerk(V4F_Strength4)
    endif
    if PerkProgress >= 5.0
        Player.AddPerk(V4F_Strength5)
    endif
endfunction