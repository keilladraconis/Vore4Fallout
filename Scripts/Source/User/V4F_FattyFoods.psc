Scriptname V4F_FattyFoods extends activemagiceffect

V4F_CharismaQ Property CharismaQ Auto Const Mandatory

event OnEffectStart(Actor akTarget, Actor akCaster)
    CharismaQ.Increment()
endevent