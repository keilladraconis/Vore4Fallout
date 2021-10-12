Scriptname V4F_IntelligenceQ extends Quest
V4F_VoreCore Property VoreCore Auto Const Mandatory
Perk Property V4F_Intelligence1 Auto Const
Perk Property V4F_Intelligence2 Auto Const
Perk Property V4F_Intelligence3 Auto Const
Perk Property V4F_Intelligence4 Auto Const
Perk Property V4F_Intelligence5 Auto Const

; Timer hacks
bool timersInitialized
int RealTimerID_HackClockSyncer = 5 const
int TIMER_main = 1 const
int TIMER_cooldown = 2 const
float HackClockLowestTime
float GameTimeElapsed

float PerkProgress = 0.0

float PerkDecay = 0.01
float PerkRate = 0.04
int version
; This is used for updating script-level variables. To invoke this, also update the OnPlayerLoadGame event to bump the version
function Updateversion(int v)
    if v > version
        PerkDecay = 0.01
        PerkRate = 0.04
        version = v
    endif
endfunction

Event Actor.OnPlayerLoadGame(Actor akSender)
	Updateversion(3)
EndEvent

Actor Player

; Called when the quest initializes
Event OnInit()
    Player = Game.GetPlayer()
    RegisterForRemoteEvent(Player, "OnPlayerLoadGame")
    RegisterForRemoteEvent(Player, "OnDifficultyChanged")
    RegisterForCustomEvent(VoreCore, "BodyShapeEvent")
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
            Debug.Trace("IntelligenceQ Clock Sync @ " + currentGameTime + " # " + HackClockLowestTime)
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

Event V4F_VoreCore.BodyShapeEvent(V4F_VoreCore akSender, Var[] args)
    float topFat = args[0] as float
    ApplyPerks(topFat)
EndEvent

; ========
; Public
; ========

function Increment()
    PerkProgress += PerkRate * difficultyScaling
    if PerkProgress > 2.0
        PerkProgress = 2.0
    endif
    VoreCore.BreastMax = PerkProgress
    Debug.Trace("IntelligenceQ +:" + PerkProgress)
endfunction

; ========
; Private
; ========

function PerkDecay(float time)
    PerkProgress -= time * PerkDecay * difficultyScaling
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