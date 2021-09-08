Scriptname Vore4Fallout:RestoreHealthFood extends ActiveMagicEffect
{Activated whenever healing food is consumed.}

CustomEvent FoodConsumed

Event OnEffectStart(Actor akTarget, Actor akCaster)
	SendCustomEvent("FoodConsumed")
EndEvent