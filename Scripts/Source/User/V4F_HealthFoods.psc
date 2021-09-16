Scriptname V4F_HealthFoods extends activemagiceffect

V4F_VoreCore Property VoreCore Auto Const Mandatory

event OnEffectStart(Actor akTarget, Actor akCaster)
    VoreCore.HealthFood()
endevent