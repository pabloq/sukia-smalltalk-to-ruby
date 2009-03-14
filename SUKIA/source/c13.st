Object subclass: #SearchAutomatonOutput
	instanceVariableNames: 'possibleSolutions unmatchedDescription justification '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Output'!
SearchAutomatonOutput comment:
'This is the base class for search outputs done on the Case Memory or the Taxonomic Hierarchy.'!


!SearchAutomatonOutput methodsFor: 'adding'!

justification: aJustificationsList

	justification := (aJustificationsList copy).
	^self.!

possibleSolutions: aPossibleSolutionList

	possibleSolutions := (aPossibleSolutionList copy).
	^self.!

unmatchedDescription: anUnmatchedDescription

	unmatchedDescription := (anUnmatchedDescription copy).
	^self.! !

!SearchAutomatonOutput methodsFor: 'initializing'!

initialize

	possibleSolutions := nil.
	unmatchedDescription := nil.
	justification := nil.
	^self.! !

!SearchAutomatonOutput methodsFor: 'accessing'!

justification

	^justification.!

possibleSolutions

	^possibleSolutions.!

unmatchedDescription

	^unmatchedDescription.! !

!SearchAutomatonOutput methodsFor: 'appending'!

appendToJustification: aJustificationList

	(aJustificationList = nil)
	ifTrue: [ ^nil ].

	1 to: (aJustificationList size) do:
	[:i | justification add: (aJustificationList at: i) ].
	^self.!

appendToPossibleSolutions: aPossibleSolutionsList

	(aPossibleSolutionsList = nil)
	ifTrue: [ ^nil ].

	1 to: (aPossibleSolutionsList size) do:
	[:i | possibleSolutions add: (aPossibleSolutionsList at: i) ].
	^self.!

appendToUnmatchedDescription: anUnmatchedDescription

	(anUnmatchedDescription = nil)
	ifTrue: [ ^nil ].

	1 to: (anUnmatchedDescription size) do:
	[:i |
		((self includes: (anUnmatchedDescription at: i) in: (self unmatchedDescription)) = nil)
		ifTrue: [ unmatchedDescription add: (anUnmatchedDescription at: i) ]
	].

	^self.! !

!SearchAutomatonOutput methodsFor: 'testing'!

includes: aSAVDescriptor in: aDescription

	"Determines if a full aSAVDescriptor is already a member of aDescription. The argument aSAVDescriptor is a member of 
	aDescriptionList when its structure, attribute and value match with the structure name, attribute name, and value of a list element.
	Returns: 	-1 (error state): The argument aDescriptionList IS NOT a valid list for self.
				nil: aSAVDescriptor IS NOT a member of aDescriptionList.
				not nil: an element of aDescriptionList whose structure and attribute names match those of aSAVDescriptor"

	| d |

	"First step: make sure that the process is executed against one of my lists"
	(aDescription = (self unmatchedDescription))
	ifFalse: [ ^(-1) ].

	1 to: (aDescription size) do:
	[:i |
		d := aDescription at: i.
		((d structure = aSAVDescriptor structure) & (d attribute = aSAVDescriptor attribute) & (d value = aSAVDescriptor value))
		ifTrue: [ ^d ].
	].

	^nil.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SearchAutomatonOutput class
	instanceVariableNames: ''!


!SearchAutomatonOutput class methodsFor: 'instance creation'!

new

	| output |

	output := super new.
	output initialize.
	^output.! !

SearchAutomatonOutput subclass: #TaxonAutomatonOutput
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Output'!
TaxonAutomatonOutput comment:
'Instances of this class will contain the output values of Index-based Searches (DFS) done on the Taxonomic Hierarchy.'!


SearchAutomatonOutput subclass: #DFSAutomatonOutput
	instanceVariableNames: 'taxonomy '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Output'!
DFSAutomatonOutput comment:
'Instances of this class will contain the output values of Depth-First Searches (DFS) done on the Case Memory.'!


!DFSAutomatonOutput methodsFor: 'private'!

compress

	"Every PossibleSolution contains a search path for the given descriptive element. Thus, there may exist possible solutions 
	(with different search paths) that are either: a) the same case or b) a successor taxon of another possible solution.  What this 
	method does is to place the solution descriptions of several possible solutions (that refer to the same taxon) in a single one, 
	and to inherit the solution description of a predecessor possible-solution taxon.

	Precondition: (self possibleSolutions size > 1) && (self taxonomy is NOT nil).

	 Returns: 	nil - If the precondition is NOT met.
				self - If the process runs OK."

	| i ps compSolution processList tempList psTaxon compSolutionTaxon |

	"Check precondition"
	((self possibleSolutions size < 2) | (self taxonomy = nil))
	ifTrue: [ ^nil ].

	"Make the process list a sorted list ordered by taxonomic level, most specific level first"
	processList := SortedCollection new.
	processList sortBlock: [ :x :y | 
							(TaxonomicLevels transformToIndex: (x level)) >=
							(TaxonomicLevels transformToIndex: (y level)) ].

	"Empty all possible solutions into the sorted-by-taxonomic-level list"
	[ self possibleSolutions isEmpty ]
	whileFalse: [ processList add: (self possibleSolutions) removeFirst ].

	tempList := OrderedCollection new.

	"Scan the process list"
	[ processList isEmpty ]
	whileFalse: [

		"Remove the next possible solution from the process list"
		ps := processList removeFirst.

		"Get the corresponding taxon of the SAVCase"
		psTaxon := (self taxonomy getTaxonByName: (ps name) level: (ps level)).

		"Compare ps against the rest of the possible solutions in processList"
		i := 1.
		[ i <= (processList size) ]
		whileTrue: [

			"Get the next possible solution to compare against"
			compSolution := processList at: i.

			"Check if the proposed solutions are the same object"
			(ps solution = compSolution solution)
			ifTrue: [

				"Inherit the compare solution's descriptions and remove it from aPossibleSolutionsList"
				self inheritPossibleSolutionDescriptionsFrom: compSolution to: ps.
				processList removeAtIndex: i.

			]    "END (ps solution = compSolution solution) ifTrue:"

			"At this point, ps and compSolution are different cases"
			ifFalse: [

				compSolutionTaxon := (self taxonomy getTaxonByName: (compSolution name) level: (compSolution level)).

				(psTaxon isSuccessorOf: compSolutionTaxon)
				ifTrue: [ self inheritPossibleSolutionDescriptionsFrom: compSolution to: ps ].

				i := i + 1.

			].    "END (ps solution = compSolution solution) ifFalse:"

		].    "END [ i <= (self processList size) ] whileTrue:"

		"Place the current possible solution in a temporary list"
		tempList add: ps.
		ps := nil.

	].    "END [ processList isEmpty ] whileFalse:"

	"Put all processed taxa back in the possible solutions list"
	self appendToPossibleSolutions: tempList.

	^self.!

inheritPossibleSolutionDescriptionsFrom: anOldPossibleSolution to: aNewPossibleSolution

	aNewPossibleSolution appendToSolutionDescription: (anOldPossibleSolution solutionDescription).
	aNewPossibleSolution appendToConfirmedDescription: (anOldPossibleSolution confirmedDescription).
	aNewPossibleSolution appendToUnconfirmedDescription: (anOldPossibleSolution unconfirmedDescription).
	aNewPossibleSolution appendToDoubtfulDescription: (anOldPossibleSolution doubtfulDescription).

	^self.! !

!DFSAutomatonOutput methodsFor: 'initialization'!

initialize

	taxonomy := nil.
	^self.! !

!DFSAutomatonOutput methodsFor: 'accessing'!

taxonomy

	^taxonomy.! !

!DFSAutomatonOutput methodsFor: 'adding'!

taxonomy: aTaxonomy

	taxonomy := aTaxonomy.
	^self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

DFSAutomatonOutput class
	instanceVariableNames: ''!


!DFSAutomatonOutput class methodsFor: 'instance creation'!

new

	| output |

	output := super new.
	output initialize.
	^output.! !

