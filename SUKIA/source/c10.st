Object subclass: #HintsBase
	instanceVariableNames: 'weightedGrpHeuristicList weightedStructList specStructAttrList successfulFreqStructPattList failedFreqStructPattList freqGrpHeuristicList '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Search Hints Base'!


!HintsBase methodsFor: 'accessing'!

failedFrequentStructurePatternList

	^failedFreqStructPattList.!

frequentGroupingHeuristicList

	^freqGrpHeuristicList.!

specificStructureAttributeList

	^specStructAttrList .!

successfulFrequentStructurePatternList

	^successfulFreqStructPattList .!

weightedGroupingHeuristicList

	^weightedGrpHeuristicList!

weightedStructureList

	^weightedStructList .! !

!HintsBase methodsFor: 'adding'!

add: aListElement

	"Adds a list element in its corresponding list.
	Returns: 	the list instance where the list element was successfully added;
				nil - if it was not possible to add the list element in any of the lists in self."

	| aList |

	aList := freqGrpHeuristicList add: aListElement.
	(aList = nil) ifFalse: [ ^aList ].

	aList := successfulFreqStructPattList add: aListElement.
	(aList = nil) ifFalse: [ ^aList ].

	aList := failedFreqStructPattList add: aListElement.
	(aList = nil) ifFalse: [ ^aList ].

	aList := specStructAttrList add: aListElement.
	(aList = nil) ifFalse: [ ^aList ].

	aList := weightedGrpHeuristicList add: aListElement.
	(aList = nil) ifFalse: [ ^aList ].

	aList := weightedStructList add: aListElement.
	(aList = nil) ifFalse: [ ^aList ].

	^nil.! !

!HintsBase methodsFor: 'initializing'!

initialize

	"This list must contain objects of class: FrequentGroupingHeuristicElt"
	freqGrpHeuristicList := FrequentGroupingHeuristicList new.

	"This list must contain objects of class: FrequentStructurePatternElt. All patterns therein MUST be successful 
	(i.e., patterns that have contributed to solve cases successfully)"
	successfulFreqStructPattList := FrequentStructurePatternList new.

	"This list must contain objects of class: FrequentStructurePatternElt. All patterns therein MUST be unsuccessful 
	(i.e., patterns that have NOT contributed to solve cases)"
	failedFreqStructPattList := FrequentStructurePatternList new.

	"This list must contain objects of class: SpecificStructureAttributeElt"
	specStructAttrList := SpecificStructureAttributeList new.

	"This list must contain objects of class: WeightedGroupingHeuristicElt"
	weightedGrpHeuristicList :=  WeightedGroupingHeuristicList new.

	"This list must contain objects of class: WeightedStructureElt"
	weightedStructList := WeightedStructureList new.

	^self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HintsBase class
	instanceVariableNames: ''!


!HintsBase class methodsFor: 'instance creation'!

new

	| hb |

	hb := super new.
	hb initialize.
	^hb.! !

