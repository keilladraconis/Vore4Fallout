Scriptname V4F_RunningWhileFat extends activemagiceffect
V4F_AgilityQ Property AgilityQ Auto Const Mandatory
V4F_PerceptionQ Property PerceptionQ Auto Const
V4F_VoreCore Property VoreCore Auto Const

event OnEffectStart(Actor akTarget, Actor akCaster)
    AgilityQ.Increment(1.0)
    PerceptionQ.SetExerciseBoost()
    VoreCore.SetExerciseBoost()
endevent
