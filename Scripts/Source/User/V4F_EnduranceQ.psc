Scriptname V4F_EnduranceQ extends Quest
V4F_VoreCore Property VoreCore Auto Const Mandatory
Perk Property V4F_Endurance1 Auto
Perk Property V4F_Endurance2 Auto
Perk Property V4F_Endurance3 Auto
Perk Property V4F_Endurance4 Auto
Perk Property V4F_Endurance5 Auto

float PerkProgress = 0.0
float PerkRate
float PerkDecay
float sleepStart

Actor Player

; Called when the quest initializes
Event OnInit()
    Setup()
    Self.RegisterForPlayerSleep()
    RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
EndEvent

function Setup()
    PerkRate = 0.025
    PerkDecay = 0.125
    StartTimer(3600.0, 1)
    Player = Game.GetPlayer()
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

Event OnTimer(int timer)
    PerkDecay(1.0)
    StartTimer(3600.0, 1)
endevent

; ========
; Public
; ========

function Increment()
    PerkProgress += PerkRate
    ApplyPerks()
endfunction

; ========
; Private
; ========

function PerkDecay(float time)
    if PerkProgress > 0.0
        PerkProgress -= time * PerkDecay
        if PerkProgress < 0.0
            PerkProgress = 0.0
        endif
        ApplyPerks()
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