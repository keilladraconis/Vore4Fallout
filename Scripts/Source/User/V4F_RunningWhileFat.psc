Scriptname V4F_RunningWhileFat extends activemagiceffect
V4F_AgilityQ Property AgilityQ Auto Const Mandatory

event OnEffectStart(Actor akTarget, Actor akCaster)
    GotoState("RunningCooldown")
    StartTimer(300.0, 1) ; 5 minute cooldown
    AgilityQ.Increment()
endevent

State RunningCooldown
    event OnTimer(int timerId)
        GotoState("")
    endevent

    event OnEffectStart(Actor akTarget, Actor akCaster)
    endevent    
EndState