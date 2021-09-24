Scriptname V4F_SwallowEffect extends activemagiceffect

V4F_VoreCore Property VoreCore Auto Const Mandatory

event OnEffectStart(Actor akTarget, Actor akCaster)
    VoreCore.HandleSwallow(akTarget)
endevent