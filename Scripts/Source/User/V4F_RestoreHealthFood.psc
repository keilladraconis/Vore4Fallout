Scriptname V4F_RestoreHealthFood extends activemagiceffect

V4F_VoreCore Property VoreCore Auto Const Mandatory

; Increment to update script properties.
int version = 0
float consumeVolume =  0.016

event OnEffectStart(Actor akTarget, Actor akCaster)
    if version < 1
        Update(1)
    endif
    VoreCore.AddFood(consumeVolume * 10, self)
endevent

function Update(int newVersion)
    version = newVersion
    ; If the belly 100% volume is 60 gallons, and each food is about a gallon, then the volume expressed as a percent should be 1.6%. In integer 10,000ths, it's 160 10,000ths.
    consumeVolume = 0.016
endfunction
    
