Scriptname V4F_HealthFoods extends activemagiceffect

V4F_PerceptionQ Property PerceptionQ Auto Const Mandatory

event OnEffectStart(Actor akTarget, Actor akCaster)
    PerceptionQ.Increment()
endevent