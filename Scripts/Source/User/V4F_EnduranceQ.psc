Scriptname V4F_EnduranceQ extends Quest
V4F_VoreCore Property VoreCore Auto Const Mandatory
Perk Property V4F_Endurance1 Auto
Perk Property V4F_Endurance2 Auto
Perk Property V4F_Endurance3 Auto
Perk Property V4F_Endurance4 Auto
Perk Property V4F_Endurance5 Auto

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
ActorValue EnduranceAV

; Called when the quest initializes
Event OnInit()
    StartTimer(3600.0, 1)
    StartTimer(60.0, 10)
    Player = Game.GetPlayer()
    EnduranceAV = Game.GetEnduranceAV()
    Self.RegisterForPlayerSleep()
    Self.RegisterForPlayerWait()
    Self.RegisterForPlayerTeleport()
    previousTime = Utility.GetCurrentGameTime()
    RegisterForRemoteEvent(Player, "OnPlayerLoadGame")
    RegisterForRemoteEvent(Player, "OnDifficultyChanged")
    RegisterForCustomEvent(VoreCore, "VoreEvent")
    RegisterForCustomEvent(VoreCore, "StomachStrainEvent")
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
    return 0.05 + (0.06 * Math.pow(Player.GetValue(EnduranceAV) / 2.8, 3)) * difficultyScaling
EndFunction

function Increment()
    PerkProgress += PerkRate * difficultyScaling
    ApplyPerks()
    Debug.Trace("EnduranceQ +:" + PerkProgress)
endfunction

function StomachStrain(float bellyTotal)
    if bellyTotal / BellyMax() > 0.8
        Increment()
    endif
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
        Debug.Trace("EnduranceQ -:" + PerkProgress)
    endif
endfunction

function ApplyPerks()
    Player.RemovePerk(V4F_Endurance1)
    Player.RemovePerk(V4F_Endurance2)
    Player.RemovePerk(V4F_Endurance3)
    Player.RemovePerk(V4F_Endurance4)
    Player.RemovePerk(V4F_Endurance5)
    if PerkProgress >= 1.0
        Player.AddPerk(V4F_Endurance1)
    endif
    if PerkProgress >= 2.0
        Player.AddPerk(V4F_Endurance2)
    endif
    if PerkProgress >= 3.0
        Player.AddPerk(V4F_Endurance3)
    endif
    if PerkProgress >= 4.0
        Player.AddPerk(V4F_Endurance4)
    endif
    if PerkProgress >= 5.0
        Player.AddPerk(V4F_Endurance5)
    endif
endfunction