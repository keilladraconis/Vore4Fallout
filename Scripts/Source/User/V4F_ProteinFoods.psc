Scriptname V4F_ProteinFoods extends activemagiceffect

V4F_StrengthQ Property StrengthQ Auto Const Mandatory

event OnEffectStart(Actor akTarget, Actor akCaster)
    StrengthQ.Increment()
endevent