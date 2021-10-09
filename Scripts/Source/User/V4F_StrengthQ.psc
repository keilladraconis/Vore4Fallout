Scriptname V4F_StrengthQ extends Quest
V4F_VoreCore Property VoreCore Auto Const Mandatory
Perk Property V4F_Strength1 Auto Const
Perk Property V4F_Strength2 Auto Const
Perk Property V4F_Strength3 Auto Const
Perk Property V4F_Strength4 Auto Const
Perk Property V4F_Strength5 Auto Const

; Timer hacks
bool timersInitialized
int RealTimerID_HackClockSyncer = 5 const
int TIMER_main = 1 const
int TIMER_cooldown = 2 const
float HackClockLowestTime
float GameTimeElapsed

float PerkProgress = 0.0

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
    Player = Game.GetPlayer()
    StrengthAV = Game.GetStrengthAV()
    RegisterForRemoteEvent(Player, "OnPlayerLoadGame")
    RegisterForRemoteEvent(Player, "OnDifficultyChanged")
    RegisterForCustomEvent(VoreCore, "VoreEvent")
    UpdateDifficultyScaling(Game.GetDifficulty())
    ; HACK! The game clock gets adjusted early game to set lighting and such.
    ; This will fix out clocks from getting out of alignment on new game start.
    timersInitialized = false
    StartTimer(1.0, RealTimerID_HackClockSyncer)
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
Event OnTimer(int timer)
    if timer == RealTimerID_HackClockSyncer
        float currentGameTime = Utility.GetCurrentGameTime()
        if !timersInitialized || currentGameTime < HackClockLowestTime
            GameTimeElapsed = currentGameTime
            HackClockLowestTime = currentGameTime
            StartTimerGameTime(10.0/60.0, 1)
            timersInitialized = true
        endif
        
        if currentGameTime <= HackClockLowestTime + 0.05
            StartTimer(30.0, RealTimerID_HackClockSyncer)
            Debug.Trace("StrengthQ Clock Sync @ " + currentGameTime + " # " + HackClockLowestTime)
        endif
    endif
EndEvent

Event OnTimerGameTime(int timer)
    if timer == TIMER_main
        ; Time is reported as a floating point number where 1 is a whole day. 1 hour is 1/24 expressed as a decimal. (1.0 / 24.0) * 60 * 60 = 150
        float timeDelta = (Utility.GetCurrentGameTime() - GameTimeElapsed) / (1.0 / 24.0) * 60 * 60
        GameTimeElapsed = Utility.GetCurrentGameTime()
        PerkDecay(timeDelta / 3600.0)
        StartTimerGameTime(10.0/60.0, 1)
    elseif timer == TIMER_cooldown
        GotoState("")
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
    GotoState("Cooldown")
    PerkProgress += PerkRate * difficultyScaling
    ApplyPerks()
    Debug.Trace("StrengthQ +:" + PerkProgress)
    if PerkProgress > 7.5
        PerkProgress = 7.5
    endif
    StartTimerGameTime(1.0, TIMER_cooldown)
endfunction

state Cooldown
    function Increment()
        Debug.Trace("StrengthQ Cooldown")
    endfunction
endstate

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