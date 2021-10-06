Scriptname V4F_CharismaQ extends Quest
V4F_VoreCore Property VoreCore Auto Const Mandatory
Perk Property V4F_Charisma1 Auto Const
Perk Property V4F_Charisma2 Auto Const
Perk Property V4F_Charisma3 Auto Const
Perk Property V4F_Charisma4 Auto Const
Perk Property V4F_Charisma5 Auto Const
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
    float bottomFat = args[1] as float
    ApplyPerks(bottomFat)
EndEvent

; ========
; Public
; ========

function Increment()
    PerkProgress += PerkRate
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
    PerkProgress -= time * PerkDecay
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