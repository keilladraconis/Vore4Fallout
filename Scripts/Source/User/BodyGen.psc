Scriptname BodyGen Native Hidden
{This script stub is a reference for resolving the types and names of LooksMenu's extended functions.}

; Sets the specified actors morph and key to value (LooksMenu internally uses None for the keyword)
; This keyword should be a Keyword in a plugin so that when the plugin is uninstalled the morph is removed automatically
Function SetMorph(Actor akActor, bool isFemale, string morph, keyword akKeyword, float value) global native

; Acquires the particular value of the specified morph with the specified keyword
float Function GetMorph(Actor akActor, bool isFemale, string morph, keyword akKeyword) global native

; Removes all morphs that were applied to the actor with the specified morph name
Function RemoveMorphsByName(Actor akActor, bool isFemale, string morph) global native

; Removes all morphs on the actor that were applied with the specified keyword
Function RemoveMorphsByKeyword(Actor akActor, bool isFemale, Keyword akKeyword) global native

; Removes all morphs on the specified actor (Actor becomes applicable for BodyGen when they are no active morphs, use a dummy morph to prevent)
Function RemoveAllMorphs(Actor akActor, bool isFemale) global native

; Returns all keywords that are used by the particular morph
Keyword[] Function GetKeywords(Actor akActor, bool isFemale, string morph) global native

; Return all morphs used by the specified actor
string[] Function GetMorphs(Actor akActor, bool isFemale) global native

; Clears all existing morphs and Regenerates BodyGen morphs for the specified actor
; based on their current gender; doUpdate will internally call UpdateMorphs
Function RegenerateMorphs(Actor akActor, bool doUpdate = true) global native

; Visually updates all the actor's worn armor shapes that is associated with BodyMorphing
Function UpdateMorphs(Actor akActor) global native

; Removes all morphs from all actors making them re-eligible for generation (does not perform update)
Function ClearAll() global native

bool Function SetSkinOverride(Actor akActor, string id) global native

bool Function RemoveSkinOverride(Actor akActor) global native