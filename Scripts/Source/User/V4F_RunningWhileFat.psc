Scriptname V4F_RunningWhileFat extends activemagiceffect
V4F_AgilityQ Property AgilityQ Auto Const Mandatory

event OnEffectStart(Actor akTarget, Actor akCaster)
    AgilityQ.Increment()
endevent
