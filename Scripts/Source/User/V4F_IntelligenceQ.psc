Scriptname V4F_IntelligenceQ extends Quest
V4F_VoreCore Property VoreCore Auto Const Mandatory
Perk Property V4F_Intelligence1 Auto Const
Perk Property V4F_Intelligence2 Auto Const
Perk Property V4F_Intelligence3 Auto Const
Perk Property V4F_Intelligence4 Auto Const
Perk Property V4F_Intelligence5 Auto Const

float PerkProgress = 0.0
float PerkRate
float PerkDecay
float sleepStart

Actor Player

; Called when the quest initializes
Event OnInit()
    Setup()
EndEvent

function Setup()
    PerkRate = 0.005
    PerkDecay = 0.00025
    StartTimer(3600.0, 1)
    Player = Game.GetPlayer()
    Self.RegisterForPlayerSleep()
    Self.RegisterForPlayerWait()
    RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
    RegisterForCustomEvent(VoreCore, "BodyShapeEvent")
endfunction

; ======
; EVENTS
; ======
Event Actor.OnPlayerLoadGame(Actor akSender)
	; Setup()
EndEvent

Event OnPlayerSleepStart(float afSleepStartTime, float afDesiredSleepEndTime, ObjectReference akBed)
    sleepStart = afSleepStartTime
EndEvent

Event OnPlayerSleepStop(bool abInterrupted, ObjectReference akBed)
    ; Time is reported as a floating point number where 1 is a whole day. 1 hour is 1/24 expressed as a decimal. (1.0 / 24.0) * 60 * 60 = 150
    float timeDelta = (Utility.GetCurrentGameTime() - sleepStart) / (1.0 / 24.0) * 60 * 60
   
    PerkDecay(timeDelta / 3600.0)
EndEvent

Event OnPlayerWaitStart(float afWaitStartTime, float afDesiredWaitEndTime)
    sleepStart = afWaitStartTime
EndEvent

Event OnPlayerWaitStop(bool abInterrupted)
    ; Time is reported as a floating point number where 1 is a whole day. 1 hour is 1/24 expressed as a decimal. (1.0 / 24.0) * 60 * 60 = 150
    float timeDelta = (Utility.GetCurrentGameTime() - sleepStart) / (1.0 / 24.0) * 60 * 60
    PerkDecay(timeDelta / 3600.0)
EndEvent

Event OnTimer(int timer)
    PerkDecay(1.0)
    StartTimer(3600.0, 1)
endevent

Event V4F_VoreCore.BodyShapeEvent(V4F_VoreCore akSender, Var[] args)
    float topFat = args[0] as float
    ApplyPerks(topFat)
EndEvent

; ========
; Public
; ========

function Increment()
    PerkProgress += PerkRate
    if PerkProgress > 1.0
        PerkProgress = 1.0
    endif
    VoreCore.BreastMax = PerkProgress
    Debug.Trace("IntelligenceQ +:" + PerkProgress)
endfunction

; ========
; Private
; ========

function PerkDecay(float time)
    PerkProgress -= time * PerkDecay
    if PerkProgress < 0.0
        PerkProgress = 0.0
    endif
    VoreCore.BreastMax = PerkProgress
    Debug.Trace("IntelligenceQ -:" + PerkProgress)
endfunction

function ApplyPerks(float topFat)
    Player.RemovePerk(V4F_Intelligence1)
    Player.RemovePerk(V4F_Intelligence2)
    Player.RemovePerk(V4F_Intelligence3)
    Player.RemovePerk(V4F_Intelligence4)
    Player.RemovePerk(V4F_Intelligence5)
    if topFat >= 0.2
        Player.AddPerk(V4F_Intelligence1)
    endif
    if topFat >= 0.4
        Player.AddPerk(V4F_Intelligence2)
    endif
    if topFat >= 0.6
        Player.AddPerk(V4F_Intelligence3)
    endif
    if topFat >= 0.8
        Player.AddPerk(V4F_Intelligence4)
    endif
    if topFat >= 1.0
        Player.AddPerk(V4F_Intelligence5)
    endif
endfunction