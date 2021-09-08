Scriptname V4F_RestoreHealthFood extends activemagiceffect

V4F_VoreCore Property VoreCore Auto Const Mandatory

; Increment to update script properties.
int version = 0

event OnEffectStart(Actor akTarget, Actor akCaster)
    if version < 1
        Update(1)
    endif
    VoreCore.AddFood(1, self)
endevent

function Update(int newVersion)
    version = newVersion
endfunction
    
