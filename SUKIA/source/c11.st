Object variableSubclass: #Scope
	instanceVariableNames: ''
	classVariableNames: 'ScopeItems '
	poolDictionaries: ''
	category: 'CBR - Sukia Scopes'!

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Scope class
	instanceVariableNames: ''!


!Scope class methodsFor: 'accessing'!

scopeItems

	^ScopeItems.! !

!Scope class methodsFor: 'adding'!

addItem: aScopeItem

	"NOTE: THIS METHOD MUST BE OPTIMIZED TO AVOID THE ADDITION OF REPEATED ITEMS, THAT IS,
	 SCOPE ITEMS WITH NAMES NAMES ALREADY EXISTING"

	ScopeItems add: aScopeItem.
	^self.! !

!Scope class methodsFor: 'testing'!

includes: aScopeItemName

	1 to: (ScopeItems size) do:
	[:i |
		((ScopeItems at: i) name = aScopeItemName)
		ifTrue: [ ^(ScopeItems at: i) ].
	].

	^nil.! !

!Scope class methodsFor: 'initializing'!

init

	ScopeItems := SortedCollection new.
	ScopeItems sortBlock: [:item1 :item2 | item1 name <= item2 name ].
	^self.! !

Scope variableSubclass: #StructureScope
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Scopes'!
StructureScope comment:
'This class contains all structures defined in the system. Each structure MUST contain all the attributes that define it.  Each
attribute is determined by its name; values are not important here because they don''t desscribe any particular taxon.

Examples:
#leaf:(#color #shape #disposition)
#raquis: (#shape #length)
#flowering: (#color #disposition)'!

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

StructureScope class
	instanceVariableNames: ''!


!StructureScope class methodsFor: 'accessing'!

attributesFor: aStructureName

	| s |

	s := self includes: aStructureName.
	(s = nil) ifTrue: [ ^nil ].

	^(s attributes).! !

Scope variableSubclass: #AttributeScope
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Scopes'!
AttributeScope comment:
'This class contains all (structure) attributes defined in the system. Each attribute MUST contain a "one-Level" set of all the 
symbol-based, values that define it.  Attributes defined by numeric values will contain an EMPTY "one-Level" values list.  
Symbol-based values shouldn''t have weights.  Weights are useful to determine value similarity in the context of a taxon''s 
description, not in a general list of values for an unassociated attribute.

Examples:
#color: (#green #greenish #turquoise #acqua #blue #navyblue #skyblue #lightblue #violet #purple #black ...)
#shape: (#circular #rounded #ovaled #triangular #square #rectangular ...)
#disposition: (#opposed #adyacent ...)
#length: ()
#numberFilaments: ()
'!


Scope variableSubclass: #GroupingHeuristicScope
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Scopes'!
GroupingHeuristicScope comment:
'This class contains all grouping heuristics defined in the system. Each grouping heuristic MUST contain all the values that define it.
Weights for the values are not important here since they don''t describe any particular taxon.

Examples:
#woody: (#yes #no)
#collectedin: (#acg #cahuita #highplains #irazuvolcano ...)
#epiphyte: (#yes #no)
#lifeform: (#bryophyte #fern #epiphyte #palm #vine #grass ...)'!


