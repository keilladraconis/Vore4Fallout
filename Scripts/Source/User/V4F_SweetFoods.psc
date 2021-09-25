Scriptname V4F_SweetFoods extends activemagiceffect

V4F_IntelligenceQ Property IntelligenceQ Auto Const Mandatory


event OnEffectStart(Actor akTarget, Actor akCaster)
    IntelligenceQ.Increment()
endevent