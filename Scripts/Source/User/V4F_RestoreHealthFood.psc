Scriptname V4F_RestoreHealthFood extends activemagiceffect

V4F_VoreCore Property VoreCore Auto Const Mandatory

int version = 0
float consumeVolume =  0.0016

event OnEffectStart(Actor akTarget, Actor akCaster)
    ; Increment to update script properties.
    if version < 3
        Update(3)
    endif
    VoreCore.AddFood(consumeVolume, self)
endevent

function Update(int newVersion)
    version = newVersion
    ; Reduced from 0.016 to 0.0016 to try to slow casual weight gain from food.
    consumeVolume = 0.0016
endfunction
    
