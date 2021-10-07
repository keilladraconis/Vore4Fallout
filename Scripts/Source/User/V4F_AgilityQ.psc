Scriptname V4F_AgilityQ extends Quest
V4F_VoreCore Property VoreCore Auto Const Mandatory
Perk Property V4F_Agility1 Auto Const
Perk Property V4F_Agility2 Auto Const
Perk Property V4F_Agility3 Auto Const
Perk Property V4F_Agility4 Auto Const
Perk Property V4F_Agility5 Auto Const

float PerkProgress = 0.0
float previousTime

float metabolicRate = -0.0289 ; Assuming 2500 calories per day.
float PerkDecay = 0.1
float PerkRate = 0.2
int version = 1
; This is used for updating script-level variables. To invoke this, also update the OnPlayerLoadGame event to bump the version
function Updateversion(int v)
    if v > version
        metabolicRate = -0.0289
        PerkDecay = 0.1
        PerkRate = 0.2
        version = v
    endif
endfunction

Event Actor.OnPlayerLoadGame(Actor akSender)
	Updateversion(1)
EndEvent

Actor Player
ActorValue AgilityAV


; Called when the quest initializes
Event OnInit()
    StartTimer(3600.0, 1)
    StartTimer(60.0, 10)
    Player = Game.GetPlayer()
    AgilityAV = Game.GetAgilityAV()
    Self.RegisterForPlayerSleep()
    Self.RegisterForPlayerWait()
    Self.RegisterForPlayerTeleport()
    previousTime = Utility.GetCurrentGameTime()
    RegisterForRemoteEvent(Player, "OnPlayerLoadGame")
    RegisterForRemoteEvent(Player, "OnDifficultyChanged")
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

; ========
; Public
; ========

float function ComputeMetabolicRate(float time)
    float agilityBonus = Player.GetValue(AgilityAV) / 4.0
    return metabolicRate * time * agilityBonus * PerkProgress * difficultyScaling
endfunction

function Increment()
    PerkProgress += PerkRate * difficultyScaling
    ApplyPerks()
    Debug.Trace("AgilityQ +:" + PerkProgress)
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
        Debug.Trace("AgilityQ -:" + PerkProgress)
    endif
endfunction

function ApplyPerks()
    Player.RemovePerk(V4F_Agility1)
    Player.RemovePerk(V4F_Agility2)
    Player.RemovePerk(V4F_Agility3)
    Player.RemovePerk(V4F_Agility4)
    Player.RemovePerk(V4F_Agility5)
    if PerkProgress >= 1.0
        Player.AddPerk(V4F_Agility1)
    endif
    if PerkProgress >= 2.0
        Player.AddPerk(V4F_Agility2)
    endif
    if PerkProgress >= 3.0
        Player.AddPerk(V4F_Agility3)
    endif
    if PerkProgress >= 4.0
        Player.AddPerk(V4F_Agility4)
    endif
    if PerkProgress >= 5.0
        Player.AddPerk(V4F_Agility5)
    endif
endfunction