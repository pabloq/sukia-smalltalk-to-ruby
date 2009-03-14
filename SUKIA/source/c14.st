Object subclass: #PossibleSolutionEvaluator
	instanceVariableNames: 'successfulStructConflictSet failedStructConflictSet successfulGrpHeuristicConflictSet failedGrpHeuristicConflictSet taxonomy '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Reasoner'!


!PossibleSolutionEvaluator methodsFor: 'initializing'!

initializeWith: aSuccessfulStructList and: aFailedStructList and: aSuccessfulGrpHeuristicList and: aFailedGrpHeuristicList and: aTaxonomy

	successfulStructConflictSet := aSuccessfulStructList.
	failedStructConflictSet := aFailedStructList.
	successfulGrpHeuristicConflictSet := aSuccessfulGrpHeuristicList.
	failedGrpHeuristicConflictSet := aFailedGrpHeuristicList.
	taxonomy := aTaxonomy.

	^self.! !

!PossibleSolutionEvaluator methodsFor: 'accessing'!

failedGroupingHeuristicConflictSet

	^failedGrpHeuristicConflictSet.!

failedStructureConflictSet

	^failedStructConflictSet.!

successfulGroupingHeuristicConflictSet

	^successfulGrpHeuristicConflictSet.!

successfulStructureConflictSet

	^successfulStructConflictSet.!

taxonomy

	^taxonomy.! !

!PossibleSolutionEvaluator methodsFor: 'evaluating'!

evaluate

	"Conflict set evaluation process"

	"Step 1: Evaluate each conflict set individually"
	self evaluate: (self successfulStructureConflictSet) winOrLose: (PossibleSolutionEvaluator winPoints).
	self evaluate: (self failedStructureConflictSet) winOrLose: (PossibleSolutionEvaluator winPoints).
	self evaluate: (self successfulGroupingHeuristicConflictSet) winOrLose: (PossibleSolutionEvaluator winPoints).
	self evaluate: (self failedGroupingHeuristicConflictSet) winOrLose: (PossibleSolutionEvaluator winPoints).

	"Step 2: Evaluate every conflict set against other conflict sets"
	self evaluate:  (self successfulStructureConflictSet) against: (self failedStructureConflictSet) winOrLose: (PossibleSolutionEvaluator losePoints).
	self evaluate:  (self successfulStructureConflictSet) against: (self successfulGroupingHeuristicConflictSet) winOrLose: (PossibleSolutionEvaluator winPoints).
	self evaluate:  (self successfulStructureConflictSet) against: (self failedGroupingHeuristicConflictSet) winOrLose: (PossibleSolutionEvaluator losePoints).

	self evaluate: (self successfulGroupingHeuristicConflictSet) against: (self failedStructureConflictSet) winOrLose: (PossibleSolutionEvaluator losePoints).
	self evaluate: (self successfulGroupingHeuristicConflictSet) against: (self failedGroupingHeuristicConflictSet) winOrLose: (PossibleSolutionEvaluator losePoints).

	self evaluate: (self failedStructureConflictSet) against: (self failedGroupingHeuristicConflictSet) winOrLose: (PossibleSolutionEvaluator winPoints).

	^self.!

evaluate: aConflictSet against: aCompConflictSet winOrLose: aPointAccumulatingScheme

	"The argument aConflictSet contains a set of Hypotheses, at least one of which may contain an empty set of 
	 PossibleSolutions. The argument aCompConflictSet also contains a set of Hypotheses, at least one of which 
	 may also contain an empty set of PossibleSolutions.  All Hypotheses in either aConflictSet or aCompConflictSet 
	 are associated to descriptive elements of the same kind (either all Structures or all GroupingHeuristics). 

	 The idea behind this method is to evaluate the PossibleSolutions of one Hypothesis, in aConflictSet, against the 
	 PossibleSolutions of all the Hypotheses in aCompConflictSet, in order to a) reduce the total number of PossibleSolutions 
	 in aCompConflictSet (that is, in case two evaluated PossibleSolutions refer to the same object), and b) determine taxonomic 
	 hierarchical dependencies.  If two compared PossibleSolutions refer to the same object, the current one will inherit the 
	 compared-one's descriptions, and the compared one will be deleted from the corresponding Hypothesis. If the current 
	 PossibleSolution is successor of another one, the current one will inherit the other's descriptions.  In either case, the current 
	 PossibleSolution will  gain or lose one point, according to the criteria established by the argument aPointAccumulatingScheme.

	NOTE: 	The execution-time analysis of this program shows that it is rather inefficient; its many loops may cause the program
			to delay if the evaluated lists are large. For the time being (04-oct-1999) it's OK to leave at that, since the important
			issue is to test this logic and try to find ways to improve the PossibleSolution evaluation scheme.  It is convenient, 
			though, to find a way to optimize this process as soon as the knowledge base starts having a considerable size.

	ASSUMPTIONS: 
	1. The set of PossibleSolutions of every Hypothesis has been previously compressed, by either the taxon search automaton, 
	    or the SAV case search automaton output.
	2. The set of PossibleSolutions of every Hypothesisis ordered by taxonomic level, most specific level first.

	 PRECONDITION: aConflictSet is not empty and aCompConflictSet is not empty.

	Returns: nil : If an error occurred (no corresponding taxon was found for a given SAVCase-based PossibleSolution
			 self : If aConflicSet is empty, or the process ran OK"

	| evalHypothesis compHypothesis evalPossibleSolution compPossibleSolution evalPossibleSolutionTaxon compPossibleSolutionTaxon tempList k |

	"Check the precondition"
	((aConflictSet isEmpty) | (aCompConflictSet isEmpty))
	ifTrue: [ ^self ].

	tempList := OrderedCollection new.

	"Process while aConflicSet is not empty"
	[ aConflictSet isEmpty ]
	whileFalse: [

		"Remove the next hypothesis-to-evaluate from aConflictSet"
		evalHypothesis := (aConflictSet removeFirst).

		"Scan the entire list of possible solutions belonging to the current hypothesis-to-evaluate"
		1 to: (evalHypothesis possibleSolutions size) do:
		[:i |
			"Get the next possibleSolution-to-evaluate, which belongs to the current hypothesis-to-evaluate"
			evalPossibleSolution := (evalHypothesis possibleSolutions at: i).

			"Get the corresponding taxon of the possibleSolution-to-evaluate, if applicable"
			((evalPossibleSolution solution class name) = Taxon getClassName)
			ifTrue: [ evalPossibleSolutionTaxon := (evalPossibleSolution solution) ]
			ifFalse: [ evalPossibleSolutionTaxon := (self taxonomy getTaxonByName: (evalPossibleSolution name) level: (evalPossibleSolution level)) ].
			(evalPossibleSolutionTaxon = nil) ifTrue: [ ^nil ].
	
			"Scan all the hypotheses in aCompConflictSet"
			1 to: (aCompConflictSet size) do:
			[:j |
				"Get the next hypothesis-to-compare from aConflictSet"
				compHypothesis := (aCompConflictSet at: j).

				"Scan the entire list of possible solutions belonging to the current hypothesis-to-compare"
				k := 1.
				[ k <= (compHypothesis possibleSolutions size) ]
				whileTrue: [

					"Get the next possibleSolution-to-comapre, which belongs to the current hypothesis-to-compare"
					compPossibleSolution := (compHypothesis possibleSolutions at: k).

					((compPossibleSolution solution class name) = Taxon getClassName)
					ifTrue: [ compPossibleSolutionTaxon := (compPossibleSolution solution) ]
					ifFalse: [ compPossibleSolutionTaxon := (self taxonomy getTaxonByName: (compPossibleSolution name) level: (compPossibleSolution level)) ].
					(compPossibleSolutionTaxon = nil) ifTrue: [ ^nil ].

					"Check if the possible solutions are the same object"
					(evalPossibleSolutionTaxon = compPossibleSolutionTaxon)
					ifTrue: [

						(aPointAccumulatingScheme = PossibleSolutionEvaluator winPoints)
						ifTrue: [ 
							"Inherit the compare solution's descriptions and remove it from the hypothesis-to-compare possibleSolutions list"
							self inheritPossibleSolutionDescriptionsFrom: compPossibleSolution to: evalPossibleSolution.
							evalPossibleSolution incrementPoints ]
						ifFalse: [ 
							"AQUI SE DEBE PONER LAS DESCRIPCIONES EN LA JUSTIFICACION, NO HEREDARLAS"
							evalPossibleSolution incrementPointsBy: -1 ].

						compHypothesis possibleSolutions removeAtIndex: k.

					]    "END (evalPossibleSolution solution = compPossibleSolution solution) ifTrue:"

					"At this point, evalPossibleSolutionTaxon and compPossibleSolutionTaxon are different objects"
					ifFalse: [

						"Determine if the possibleSolution-to-evaluate is a successor taxon of the possibleSolution-to-compare"
						(evalPossibleSolutionTaxon isSuccessorOf: compPossibleSolutionTaxon)
						ifTrue: [ 

							(aPointAccumulatingScheme = PossibleSolutionEvaluator winPoints)
							ifTrue: [ 
								self inheritPossibleSolutionDescriptionsFrom: compPossibleSolution to: evalPossibleSolution.
								evalPossibleSolution incrementPoints ]
							ifFalse: [ 
								"AQUI SE DEBE PONER LAS DESCRIPCIONES EN LA JUSTIFICACION, NO HEREDARLAS"
								evalPossibleSolution incrementPointsBy: -1 ].

						].    "END (evalPossibleSolutionTaxon isSuccessorOf: compPossibleSolutionTaxon) ifTrue:"

						k := k + 1.

					].    "END (ps solution = compSolution solution) ifFalse:"

				].    "END [ k <= (compHypothesis possibleSolutions size) ] whileTrue:"

			].    "END 1 to: (aConflictSet size) do:"

		].    "END 1 to: (evalHypothesis possibleSolutions size) do:"

		tempList add: evalHypothesis.
		evalHypothesis := nil.

	].    "END [ aConflictSet isEmpty ] whileTrue:"

	[ tempList isEmpty ]
	whileFalse: [ aConflictSet add: (tempList removeFirst) ].

	^self.!

evaluate: aConflictSet winOrLose: aPointAccumulatingScheme

	"The argument aConflictSet contains a set of Hypotheses, each of which initially contains a non-empty set of PossibleSolutions.  
	 All Hypotheses are associated to descriptive elements of the same kind (either all Structures or all GroupingHeuristics).  
	 The idea behind this method is to evaluate the PossibleSolutions of one Hypothesis against the PossibleSolutions of all 
	 other Hypotheses, in order to a) reduce the total number of PossibleSolutions in aConflictSet (that is, in case two evaluated 
	 PossibleSolutions refer to the same object), and b) determine taxonomic hierarchical dependencies.  If two compared 
	 PossibleSolutions refer to the same object, the current one will inherit the compared-one's descriptions, and the compared 
	 one will be deleted from the corresponding Hypothesis. If the current PossibleSolution is successor of another one, the 
	 current one will inherit the other's descriptions.  In either case, the current PossibleSolution will  gain or lose one point, 
	 according to the criteria established by the argument aPointAccumulatingScheme.

	NOTE: 	The execution-time analysis of this program shows that it is rather inefficient; its many loops may cause the program
			to delay if the evaluated lists are large. For the time being (04-oct-1999) it's OK to leave at that, since the important
			issue is to test this logic and try to find ways to improve the PossibleSolution evaluation scheme.  It is convenient, 
			though, to find a way to optimize this process as soon as the knowledge base starts having a considerable size.

	ASSUMPTIONS: 
	1. The set of PossibleSolutions of every Hypothesis has been previously compressed, by either the taxon search automaton, 
	    or the SAV case search automaton output.
	2. The set of PossibleSolutions of every Hypothesisis ordered by taxonomic level, most specific level first.

	 PRECONDITION: aConflictSet is not empty.

	 POSTCONDITION: aConflictSet is not empty and at least one Hypothesis MAY contain an empty set of PossibleSolutions.

	Returns: nil : If an error occurred (no corresponding taxon was found for a given SAVCase-based PossibleSolution
			 self : If aConflicSet is empty, or the process ran OK"

	| evalHypothesis compHypothesis evalPossibleSolution compPossibleSolution evalPossibleSolutionTaxon compPossibleSolutionTaxon tempList k |

	"Check the precondition"
	(aConflictSet isEmpty)
	ifTrue: [ ^self ].

	tempList := OrderedCollection new.

	"Process while aConflicSet size has at least two hypotheses"
	[ aConflictSet size > 1 ]
	whileTrue: [

		"Remove the next hypothesis-to-evaluate from aConflictSet"
		evalHypothesis := (aConflictSet removeFirst).

		"Scan the entire list of possible solutions belonging to the current hypothesis-to-evaluate"
		1 to: (evalHypothesis possibleSolutions size) do:
		[:i |
			"Get the next possibleSolution-to-evaluate, which belongs to the current hypothesis-to-evaluate"
			evalPossibleSolution := (evalHypothesis possibleSolutions at: i).

			"Get the corresponding taxon of the possibleSolution-to-evaluate, if applicable"
			((evalPossibleSolution solution class name) = Taxon getClassName)
			ifTrue: [ evalPossibleSolutionTaxon := (evalPossibleSolution solution) ]
			ifFalse: [ evalPossibleSolutionTaxon := (self taxonomy getTaxonByName: (evalPossibleSolution name) level: (evalPossibleSolution level)) ].
			(evalPossibleSolutionTaxon = nil) ifTrue: [ ^nil ].
	
			"Scan the rest of the hypotheses in aConflictSet"
			1 to: (aConflictSet size) do:
			[:j |
				"Get the next hypothesis-to-compare from aConflictSet"
				compHypothesis := (aConflictSet at: j).

				"Scan the entire list of possible solutions belonging to the current hypothesis-to-compare"
				k := 1.
				[ k <= (compHypothesis possibleSolutions size) ]
				whileTrue: [

					"Get the next possibleSolution-to-comapre, which belongs to the current hypothesis-to-compare"
					compPossibleSolution := (compHypothesis possibleSolutions at: k).

					((compPossibleSolution solution class name) = Taxon getClassName)
					ifTrue: [ compPossibleSolutionTaxon := (compPossibleSolution solution) ]
					ifFalse: [ compPossibleSolutionTaxon := (self taxonomy getTaxonByName: (compPossibleSolution name) level: (compPossibleSolution level)) ].
					(compPossibleSolutionTaxon = nil) ifTrue: [ ^nil ].

					"Check if the possible solutions are the same object"
					(evalPossibleSolutionTaxon = compPossibleSolutionTaxon)
					ifTrue: [

						(aPointAccumulatingScheme = PossibleSolutionEvaluator winPoints)
						ifTrue: [ 
							"Inherit the compare solution's descriptions and remove it from the hypothesis-to-compare possibleSolutions list"
							self inheritPossibleSolutionDescriptionsFrom: compPossibleSolution to: evalPossibleSolution.
							evalPossibleSolution incrementPoints ]
						ifFalse: [ 
							"AQUI SE DEBE PONER LAS DESCRIPCIONES EN LA JUSTIFICACION, NO HEREDARLAS"
							evalPossibleSolution incrementPointsBy: -1 ].

						compHypothesis possibleSolutions removeAtIndex: k.

					]    "END (evalPossibleSolution solution = compPossibleSolution solution) ifTrue:"

					"At this point, evalPossibleSolutionTaxon and compPossibleSolutionTaxon are different objects"
					ifFalse: [

						"Determine if the possibleSolution-to-evaluate is a successor taxon of the possibleSolution-to-compare"
						(evalPossibleSolutionTaxon isSuccessorOf: compPossibleSolutionTaxon)
						ifTrue: [ 

							(aPointAccumulatingScheme = PossibleSolutionEvaluator winPoints)
							ifTrue: [ 
								self inheritPossibleSolutionDescriptionsFrom: compPossibleSolution to: evalPossibleSolution.
								evalPossibleSolution incrementPoints ]
							ifFalse: [ 
								"AQUI SE DEBE PONER LAS DESCRIPCIONES EN LA JUSTIFICACION, NO HEREDARLAS"
								evalPossibleSolution incrementPointsBy: -1 ].

						].    "END (evalPossibleSolutionTaxon isSuccessorOf: compPossibleSolutionTaxon) ifTrue:"

						k := k + 1.

					].    "END (ps solution = compSolution solution) ifFalse:"

				].    "END [ k <= (compHypothesis possibleSolutions size) ] whileTrue:"

			].    "END 1 to: (aConflictSet size) do:"

		].    "END 1 to: (evalHypothesis possibleSolutions size) do:"

		tempList add: evalHypothesis.
		evalHypothesis := nil.

	].    "END [ aConflictSet size > 1 ] whileTrue:"

	[ tempList isEmpty ]
	whileFalse: [ aConflictSet add: (tempList removeFirst) ].

	^self.! !

!PossibleSolutionEvaluator methodsFor: 'inheritance'!

inheritPossibleSolutionDescriptionsFrom: anOldPossibleSolution to: aNewPossibleSolution

	aNewPossibleSolution appendToSolutionDescription: (anOldPossibleSolution solutionDescription).
	aNewPossibleSolution appendToConfirmedDescription: (anOldPossibleSolution confirmedDescription).
	aNewPossibleSolution appendToUnconfirmedDescription: (anOldPossibleSolution unconfirmedDescription).
	aNewPossibleSolution appendToDoubtfulDescription: (anOldPossibleSolution doubtfulDescription).

	^self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PossibleSolutionEvaluator class
	instanceVariableNames: ''!


!PossibleSolutionEvaluator class methodsFor: 'instance creation'!

newWith: aSuccessfulStructList and: aFailedStructList and: aSuccessfulGrpHeuristicList and: aFailedGrpHeuristicList and: aTaxonomy

	| pse |

	pse := super new.
	pse initializeWith: aSuccessfulStructList 
				and: aFailedStructList 
				and: aSuccessfulGrpHeuristicList 
				and: aFailedGrpHeuristicList 
				and: aTaxonomy.
	^pse.! !

!PossibleSolutionEvaluator class methodsFor: 'point-accummulating scheme'!

losePoints

	^#-.!

winPoints

	^#+.! !

Object subclass: #CaseSolution
	instanceVariableNames: 'taxonLevel taxonName '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Reasoner'!


!CaseSolution methodsFor: 'accessing'!

level

	^taxonLevel.!

name

	^taxonName.! !

!CaseSolution methodsFor: 'adding'!

level: aTaxonomicLevel

	"Check the argument's class. If it isn't ByteSymbol, there's no need to search in the element list
	of the class TaxonomicLevels"
	((aTaxonomicLevel class name) = #ByteSymbol)
	ifFalse: [ ^nil ].

	"Search in the element list for the given name"
	(TaxonomicLevels includes: aTaxonomicLevel)
	ifFalse: [ ^nil ].

	taxonLevel := aTaxonomicLevel.
	^self.!

name: aTaxonName

	"Check the argument's class. By default, it must be ByteSymbol. NOTE: the 'name:' method of the class
	Taxon contains useful information about the format of taxon names"
	((aTaxonName class name) = #ByteSymbol)
	ifFalse: [ ^nil ].

	taxonName := aTaxonName.
	^self.! !

!CaseSolution methodsFor: 'initializing'!

initialize

	taxonLevel := nil.
	taxonName := nil.
	^self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CaseSolution class
	instanceVariableNames: ''!


!CaseSolution class methodsFor: 'instance creation'!

new

	| cs |

	cs := super new.
	cs initialize.
	^cs.! !

Object subclass: #Sukia
	instanceVariableNames: 'taxonomicGroupName hintsBase caseMemory taxonomy reasoner learner '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Reasoner'!


!Sukia methodsFor: 'initializing'!

initialize

	"Initialize auxiliary classes"
	TaxonomicLevels initialize.
	SimRanges initialize.

	"Initialize scope classes"
	StructureScope init.
	AttributeScope init.
	GroupingHeuristicScope init.

	taxonomicGroupName := nil.

	hintsBase := HintsBase new.
	(self loadHintsBase = nil) ifTrue: [ ^nil ].

	caseMemory := RDMultiNet new.
	(self loadCaseMemory = nil) ifTrue: [ ^nil ].

	taxonomy := Taxonomy new.
	(self loadTaxonomy = nil) ifTrue: [ ^nil ].

	self loadReasoner.

	learner := nil.

	^self.! !

!Sukia methodsFor: 'preparing'!

loadCaseMemory

	"THIS IS THE METHOD TO BE USED IN ORDER TO READ THE CASE MEMORY
	 DATA FROM DISK, AND ASSEMBLING IT IN MEMORY"

	^self.!

loadHintsBase

	"THIS IS THE METHOD TO BE USED IN ORDER TO READ THE HINTS BASE DATA
	 FROM DISK, AND ASSEMBLING IT IN MEMORY"

	^self.!

loadReasoner

	reasoner := Reasoner newWith: self.
	^self.!

loadTaxonomy

	"THIS IS THE METHOD TO BE USED IN ORDER TO READ THE TAXONOMIC
	 DATA FROM DISK, AND ASSEMBLING IT IN MEMORY"

	^self.! !

!Sukia methodsFor: 'adding'!

taxonomicGroupName: aCommonName

	"Examples of the argument aCommonName: #plant, #mollusk, #fungus"

	taxonomicGroupName := aCommonName.
	^self.! !

!Sukia methodsFor: 'accessing'!

caseMemory 

	^caseMemory.!

hintsBase 

	^hintsBase.!

learner

	^learner.!

reasoner 

	^reasoner.!

taxonomicGroupName

	^taxonomicGroupName.!

taxonomy 

	^taxonomy.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Sukia class
	instanceVariableNames: ''!


!Sukia class methodsFor: 'instance creation'!

new

	| sukia |

	sukia := super new.
	sukia initialize.
	^sukia.! !

Object subclass: #ProposedSolution
	instanceVariableNames: 'solution status degreeOfCertainty '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Reasoner'!


!ProposedSolution methodsFor: 'adding'!

degreeOfCertainty: aDegreeOfCertainty

	"The only possible values for this variable are:
		#unknown or #uncertain or #doubfult or #certain"

	((aDegreeOfCertainty = #unknown) |
	 (aDegreeOfCertainty = #uncertain) |
	 (aDegreeOfCertainty = #doubfult) |
	 (aDegreeOfCertainty = #certain))
	ifFalse: [ ^nil ].

	degreeOfCertainty := aDegreeOfCertainty.
	^self.!

solution: aPossibleSolution

	solution := aPossibleSolution.
	^self.!

status: aStatusSymbol

	"The only possible values for this variable are:
		#+ (a positive PossibleSolution)
		#- (a negative PossibleSolution)"

	((aStatusSymbol = #+) |
	 (aStatusSymbol = #-))
	ifFalse: [ ^nil ].

	status := aStatusSymbol.
	^self.! !

!ProposedSolution methodsFor: 'accessing'!

degreeOfCertainty

	^degreeOfCertainty.!

solution

	^solution.!

status

	^status.! !

!ProposedSolution methodsFor: 'initialization'!

initialize

	solution := nil.
	self status: #+.
	self degreeOfCertainty: #unknown.
	^self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ProposedSolution class
	instanceVariableNames: ''!


!ProposedSolution class methodsFor: 'instance creation'!

new

	| ps |

	ps := super new.
	ps initialize.
	^ps.! !

Object subclass: #Hypothesis
	instanceVariableNames: 'descriptiveElement possibleSolutions justification unmatchedDescription points '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Reasoner'!


!Hypothesis methodsFor: 'testing'!

includes: aSAVDescriptor in: aDescription

	"Determines if the argument aSAVDescriptor is a member of the argument aDescription.
	 Returns:	-1 (error value) : if aDescription is NOT a description list belonging to self.
				nil : if aSAVDescriptor was NOT found in aDescription.
				not nil: the instance in aDescription that matched aSAVDescriptor's structure and attribute names."

	| d dSize |

	"Make sure that aDescription is indeed one of my description lists. If not, return the -1 error value"
	 (aDescription = (self unmatchedDescription))
	ifFalse: [ ^(-1) ].

	dSize := aDescription size.

	1 to: dSize do:
	[:i |
		d := aDescription at: i.

		((d structure = aSAVDescriptor structure) & (d attribute = aSAVDescriptor attribute))
		ifTrue: [ ^d ].

		"Stop searching if the next descriptor's structure name is (alphabetically) greater than the argument's structure name"
		(i < dSize) ifTrue: [ (aSAVDescriptor structure < (aDescription at: (i + 1)) structure) ifTrue: [^nil] ].
	].

	^nil.!

includesFull: aSAVDescriptor in: aDescription

	"Determines if a full aSAVDescriptor is already a member of aDescriptionList. The argument aSAVDescriptor is a member of 
	aDescriptionList when its structure, attribute and value match with the structure and attribute names of a list element.
	Returns: 	-1 (error state): The argument aDescriptionList IS NOT a valid list for self.
				nil: aSAVDescriptor IS NOT a member of aDescriptionList.
				not nil: an element of aDescriptionList whose structure and attribute names match those of aSAVDescriptor"

	| d dSize |

	"First step: make sure that the process is executed against one of my lists"
	(aDescription = unmatchedDescription)
	ifFalse: [ ^(-1) ].

	dSize := aDescription size.

	1 to: dSize do:
	[:i |
		d := aDescription at: i.

		((d structure = aSAVDescriptor structure) & (d attribute = aSAVDescriptor attribute) & (d value = aSAVDescriptor value))
		ifTrue: [ ^d ].

		"Stop searching if the next descriptor's structure name is (alphabetically) greater than the argument's structure name"
		(i < dSize) ifTrue: [ (aSAVDescriptor structure < (aDescription at: (i + 1)) structure) ifTrue: [^nil] ].
	].

	^nil.! !

!Hypothesis methodsFor: 'adding'!

copyToJustificationFrom: aJustificationDescription

	(aJustificationDescription = nil)
	ifTrue: [ ^nil ].

	1 to: (aJustificationDescription size) do:
	[:i | self justification: (aJustificationDescription at: i) ].

	^self.!

copyToUnmatchedDescriptionFrom: anUnmatchedDescription

	(anUnmatchedDescription = nil)
	ifTrue: [ ^nil ].

	1 to: (anUnmatchedDescription size) do:
	[:i | self unmatchedDescription: (anUnmatchedDescription at: i) ].

	^self.!

descriptiveElement: aDescElt

	| dClassName |

	dClassName := aDescElt class name.
	((dClassName = Structure getClassName) | (dClassName = GroupingHeuristic getClassName))
	ifFalse: [ ^nil ].

	descriptiveElement := aDescElt.
	^self.!

incrementPoints

	points := (points + 1).
	^self.!

incrementPointsBy: anInteger

	points := (points + anInteger).
	^self.!

justification: aJustification

	justification add: aJustification.
	^self.!

possibleSolutions: aPossibleSolution

	"Adds aPossibleSolution under the following conditions:
	 1. If the list is empty, the possible solution may be added directly.
	 2. The list may contain ONLY taxa or positive instances of Case or SAVCase, or
	 3. The list may contain ONLY negative instances of SAVCase"

	| firstEltStatus possSolStatus |

	(possibleSolutions isEmpty)
	ifTrue: [ possibleSolutions add: aPossibleSolution. aPossibleSolution hypothesis: self. ^self ].

	firstEltStatus := ((self possibleSolutions) at: 1) status.
	possSolStatus := aPossibleSolution status.

	(firstEltStatus = possSolStatus)
	ifTrue: [ possibleSolutions add: aPossibleSolution. aPossibleSolution hypothesis: self. ^self ].	

	^nil.!

unmatchedDescription: aSAVDescriptor

	| retVal |

	retVal := self includesFull: aSAVDescriptor in: unmatchedDescription.
	((retVal = -1) | ((retVal = nil)  not)) ifTrue: [ ^retVal ].

	unmatchedDescription add: aSAVDescriptor.
	^self.! !

!Hypothesis methodsFor: 'initializing'!

initialize

	descriptiveElement := nil.

	"Sort criteria: taxonomic level"
	possibleSolutions := SortedCollection new.
	possibleSolutions sortBlock: [ :pSolution1 :pSolution2 | 
									(TaxonomicLevels getNumberByName: (pSolution1 level)) >= 
									(TaxonomicLevels getNumberByName: (pSolution2 level)) ].

	"Sort criteria: concatenated structure and attribute names"
	unmatchedDescription := SortedCollection new.
	unmatchedDescription sortBlock: [:SAVDesc1 :SAVDesc2 | 
										(SAVDesc1 structure , SAVDesc1 attribute) <= 
										(SAVDesc2 structure , SAVDesc2 attribute) ].

	justification := OrderedCollection new.
	points := 0.

	^self.! !

!Hypothesis methodsFor: 'accessing'!

descriptiveElement 

	^descriptiveElement.!

justification 

	^justification.!

points 

	^points.!

possibleSolutions 

	^possibleSolutions.!

unmatchedDescription 

	^unmatchedDescription.! !

!Hypothesis methodsFor: 'description generation'!

problemDescriptionFor: aTaxonomicGroupName

	(self descriptiveElement = nil)
	ifTrue: [ ^nil ].

	^(self descriptiveElement createSAVDescription: aTaxonomicGroupName).! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Hypothesis class
	instanceVariableNames: ''!


!Hypothesis class methodsFor: 'instance creation'!

new

	| h |

	h := super new.
	h initialize.
	^h.! !

Object subclass: #Reasoner
	instanceVariableNames: 'identSystem identGoal maxNumberSolutions presentFailedSolutions minSimilarityDegree structDescription groupHDescription succStructConflictSet failStructConflictSet succGHConflictSet failGHConflictSet noResultsSet proposedSolutions routeSelectJustification caseMemorySearchJustification taxonHierarchySearchJustification '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Reasoner'!


!Reasoner methodsFor: 'initializing'!

initializeWith: anIdentificationSystem

	"identSystem will be associated to the Sukia system object. Through this object, access is
	 gained main data structures: the memory case, the taxonomic hierarchy, and the hints base"
	identSystem := anIdentificationSystem.

	^self reset.!

reset

	"Initializes all instance variables needed for the identification process."

	"The identification goal. Default value: species"
	self identGoal: (TaxonomicLevels mostSpecificLevel).

	"USER EXPECTATION: Maximum number of solutions to present. Default value: 3"
	self maxNumberSolutions: 3.

	"USER EXPECTATION: Show failed cases, in case no successful ones are available.
	 Default: true (i.e., show them)"
	self presentFailedSolutions: true.

	"USER EXPECTATION: Minimal similarity degree used in comparisons. 
	 Default: moderately similar to equal"
	self minSimilarityDegree: #medianamenteSimilar.
	(self minSimilarityDegree isEmpty) ifTrue: [ ^nil ].

	"List with Structures that constitute the morphological description given by the user"
	structDescription := OrderedCollection new.

	"List with GroupingHeuristics which complement the description given by the user"
	groupHDescription := OrderedCollection new.

	"CONFLICT SET: Hypotheses that contain successful possible solutions (i.e., positive cases or taxa) 
	 for a given Structure belonging to the problem description"
	succStructConflictSet := OrderedCollection new.

	"CONFLICT SET: Hypothesis that contain failed possible solutions (i.e., negative cases only) for a given 
	 Structure belonging to the problem description"
	failStructConflictSet := OrderedCollection new.

	"CONFLICT SET: Hypothesis that contain successful possible solutions (i.e., positive cases or taxa) for 
	 a given GroupingHeuristic belonging to the problem description"
	succGHConflictSet := OrderedCollection new.

	"CONFLICT SET: Hypothesis that contain failed possible solutions (i.e., negative cases only) for a given 
	 GroupingHeuristic belonging to the problem description"
	failGHConflictSet := OrderedCollection new.

	"CONFLICT SET: Hypothesis that do not contain any possible solutions.  These Hypotheses are associated
	 to either Structures or GroupingHeuristics for which the search was unsuccessful"
	noResultsSet := OrderedCollection new.

	"Set of solutions to present to the user"
	self proposedSolutions: nil.

	"Justification list: route selection (using the HintsBase)" 
	routeSelectJustification := OrderedCollection new.

	"Justification list: case memory search" 
	caseMemorySearchJustification := OrderedCollection new.

	"Justification list: taxonomic hierarchy serach"
	taxonHierarchySearchJustification := OrderedCollection new.

	^self.! !

!Reasoner methodsFor: 'adding'!

caseMemorySearchJustification: aJustificationItem

	caseMemorySearchJustification add: aJustificationItem.
	^self.!

failGHConflictSet: aHypothesis

	failGHConflictSet add: aHypothesis.
	^self.!

failStructConflictSet: aHypothesis

	failStructConflictSet add: aHypothesis.
	^self.!

groupHDescription: aGroupingHeuristic

	1 to: (groupHDescription size) do:
	[:i |
		((groupHDescription at: i) name = aGroupingHeuristic name)
		ifTrue: [ ^nil ].
	].

	groupHDescription add: aGroupingHeuristic.
	^self.!

identGoal: aTaxonomicLevelsValue

	(TaxonomicLevels includes: aTaxonomicLevelsValue)
	ifTrue: [ identGoal := aTaxonomicLevelsValue. ^self. ].

	^nil.!

maxNumberSolutions: anInteger

	maxNumberSolutions := anInteger.
	^self.!

minSimilarityDegree: aSimRangesValue

	minSimilarityDegree := SimRanges rangesStartingAt: aSimRangesValue.
	(minSimilarityDegree isEmpty) ifTrue: [ ^nil ].
	^self.!

noResultsSet: aHypothesis

	noResultsSet add: aHypothesis.
	^self.!

presentFailedSolutions: aBoolean

	presentFailedSolutions := aBoolean.
	^self.!

proposedSolutions: aProposedSolutionsList

	proposedSolutions := aProposedSolutionsList.
	^self.!

routeSelectJustification: aJustificationItem

	routeSelectJustification add: aJustificationItem.
	^self.!

structDescription: aStructure

	1 to: (structDescription size) do:
	[:i |
		((structDescription at: i) name = aStructure name)
		ifTrue: [ ^nil ].
	].

	structDescription add: aStructure.
	^self.!

succGHConflictSet: aHypothesis

	succGHConflictSet add: aHypothesis.
	^self.!

succStructConflictSet: aHypothesis

	succStructConflictSet add: aHypothesis.
	^self.!

taxonHierarchySearchJustification: aJustificationItem

	taxonHierarchySearchJustification add: aJustificationItem.
	^self.! !

!Reasoner methodsFor: 'accessing'!

caseMemory

	^(self identSystem caseMemory).!

caseMemorySearchJustification 

	^caseMemorySearchJustification.!

failGHConflictSet 

	^failGHConflictSet.!

failStructConflictSet 

	^failStructConflictSet.!

groupHDescription 

	^groupHDescription.!

hintsBase

	^(self identSystem hintsBase).!

identGoal 

	^identGoal.!

identSystem

	^identSystem.!

maxNumberSolutions 

	^maxNumberSolutions.!

minSimilarityDegree 

	^minSimilarityDegree.!

noResultsSet 

	^noResultsSet.!

presentFailedSolutions 

	^presentFailedSolutions.!

proposedSolutions 

	^proposedSolutions.!

routeSelectJustification 

	^routeSelectJustification.!

structDescription 

	^structDescription.!

succGHConflictSet 

	^succGHConflictSet.!

succStructConflictSet 

	^succStructConflictSet.!

taxonHierarchySearchJustification

	^taxonHierarchySearchJustification.!

taxonomicGroupName

	^(self identSystem taxonomicGroupName).!

taxonomy

	^(self identSystem taxonomy).! !

!Reasoner methodsFor: 'evaluating and selecting'!

evaluatePossibleSolutions

	"Evaluation of all possible solutions belonging to Hypotheses stored in all conflict sets"

	| evaluator |

	evaluator := PossibleSolutionEvaluator 
					newWith: (self succStructConflictSet) 
					and: (self failStructConflictSet) 
					and: (self succGHConflictSet)
					and: (self failGHConflictSet) 
					and: (self taxonomy).

	^(evaluator evaluate).!

selectSolutions

	"Selection of the best possible solutions, as proposed solutions for an identification session."

	| selector |

	selector := PossibleSolutionSelector
					newWith: (self identGoal) 
					and: (self succStructConflictSet)  
					and: (self failStructConflictSet)  
					and: (self succGHConflictSet) 
					and: (self failGHConflictSet)
					and: (self maxNumberSolutions) 
					and: (self presentFailedSolutions).

	^(selector select).! !

!Reasoner methodsFor: 'reasoning'!

identify

	"Main driver for the Reasoner. The first thing is to do is to read in a problem description (structure 
	 and grouping heuristic descriptions), along with the identification goal and all the user-defined
	 system behavior expectations.  Once the problem description is obtanied, the HintsBase is
	 consulted, in order to arrange the descriptive elements (i.e., Structures and/or GroupingHeuristics)
	 in a search-effective way. Next, if Sukia has a case memory, it will be used as first resort to begin 
	 the problem solution process. If no case memory is available, the taxonomic hierarchy is used 
	 instead. Once the search process is done, the other two processes left are the possible solution
	 evaluation and the solution(s) selection.

	Precondition: (at least the taxonomy MUST be available)

	Returns: nil : if the precondition is not met, OR any involved of the processes fails.
			 self : if the process runs OK. This doesn't mean that the problem is solved, because the
				   empty solution is a valid response."

	"Check the precondition"
	(self taxonomy rootTaxon successors isEmpty)
	ifTrue: [ ^nil ].

	"Get a problem description from the user. The process may continue if either the Structure-based or 
	 GroupingHeuristic-based descriptions is NOT empty"
	(self getProblemDescription = nil)
	ifTrue: [ ^nil ].

	"Use the HintsBase with the Structure-based description"
	(self chooseIndexHintsForStructures = nil)
	ifTrue: [ ^nil ].

	"Use the HintsBase with the GroupingHeuristic-based description"
	(self chooseIndexHintsForGroupingHeuristics = nil)
	ifTrue: [ ^nil ].

	"First choice: use the case memory primary search data structure"
	((self caseMemory root nets isEmpty) not)
	ifTrue: [ (self useCaseMemory = nil) ifTrue: [ ^nil ] ]

	"Second choice: use the taxonomic hierarchy as primary search data structure"
	ifFalse: [ (self useTaxonomicHierarchy = nil) ifTrue: [ ^nil ] ].

	"If there are no available possible solutions, exit"
	(self succStructConflictSet isEmpty) & (self failStructConflictSet isEmpty) &
	(self succGHConflictSet isEmpty) & (self failGHConflictSet isEmpty)
	ifTrue: [ ^self ].

	"Evaluate all possible solutions"
	(self evaluatePossibleSolutions = nil)
	ifTrue: [ ^nil ].

	"Select the proposed solutions"
	self proposedSolutions: (self selectSolutions).

	"Return OK"
	^self.! !

!Reasoner methodsFor: 'private - index choosing'!

chooseIndexHintsForGroupingHeuristics

	"This method uses the HintsBase lists, and tries to arrange the GroupingHeuristic description 
	 in a search-efective way (i.e., the GroupingHeuristics at the beginning of the list are the ones 
	 with more possibilities to find positive solution cases).  For now (08-Oct-1999):
		a) 	If the percentage of items successfully processed is greater than zero, then it suffices.
			It is convenient, though, to device a way to determine if certain percentage is acceptable
			or not.
		b)	Failed lists will not be used.

	RETURNS: self."

	| hb |

	hb := (self hintsBase).

	(hb weightedGroupingHeuristicList sortBySuccessCriteria: (self groupHDescription)) isEmpty
	ifFalse: [ ((hb weightedGroupingHeuristicList percentageItemsProcessed) > 0.0) ifTrue: [ ^self ] ].

	hb frequentGroupingHeuristicList sortBySuccessCriteria: (self groupHDescription).
	^self.!

chooseIndexHintsForStructures

	"This method uses the HintsBase lists, and tries to arrange the Structure description in a
	 search-efective way (i.e., the Structures at the beginning of the list are the ones with more
	 possibilities to find positive solution cases).  For now (08-Oct-1999):
		a) 	If the percentage of items successfully processed is greater than zero, then it suffices.
			It is convenient, though, to device a way to determine if certain percentage is acceptable
			or not.
		b) 	The (hb failedFrequentStructurePatternList) will not be used.

	RETURNS: self."

	| hb s |

	hb := (self hintsBase).

	(hb weightedStructureList sortBySuccessCriteria: (self structDescription)) isEmpty
	ifFalse: [ ((hb weightedStructureList percentageItemsProcessed) > 0.0) ifTrue: [ ^self ] ].

	(hb successfulFrequentStructurePatternList sortByFrequencyCriteria: (self structDescription)) isEmpty
	ifFalse: [ ((hb successfulFrequentStructurePatternList percentageItemsProcessed) > 0.0) ifTrue: [ ^self ] ].

	1 to: (self structDescription size) do:
	[:i |
		hb specificStructureAttributeList resetPercentageItemsProcessed.

		s := (self structDescription at: i).
		(hb specificStructureAttributeList sortBySuccessCriteria: s).
	].

	^self.! !

!Reasoner methodsFor: 'private - general'!

getProblemDescription

	"Reads the description given by the user. The following instance variables are updated at this point:
	 1) identGoal: the identification goal; a taxonomic level defined in TaxonomicLevels.
	 2) maxNumberSolutions: maximum number of solutions that the user wants to see.
	 3) presentFailedSolutions: true if the user wants to inspect cases previously solved incorrectly.
	 4) minSimilarityDegree: minimal similarity degree that user expects the system to consider when comparing values (see SimRanges).
	 5) structDescription: problem description in terms of Structures.
	 6) groupHDescription: problem description in terms of GroupingHeuristics.

	 For now (8-Oct-1999), this method will not enter a dialog with the user. The before-mentioned variables will be
	 updated via method calls (see the adding category) from one of Smalltalk's workspace screens.  Once this method 
	 is developed, it must satisfy the following conditions:
		* Aceptar una meta de identificación: el nombre de un nivel taxonómico.
		* Aceptar la descripción del espécimen a identificar: una lista de Estructuras y Heurísticas de Agrupamiento.

		Condiciones que debe cumplir la descripción:
		i) La descripción no puede tener dos Estructuras con el mismo nombre.
		ii) Las Estructuras pueden tener asignado un peso entre 0.0 y 1.0, el cual se interpreta como 'el grado de interés 
		   que el usuario muestra por la estructura descrita.
		iii) Cada Estructura debe tener al menos un atributo.
		iv) Ninguna Estructura puede tener dos atributos con el mismo nombre.
		v) El atributo de una Estructura debe tener solo un valor.
		vi) El valor de un atributo debe ser ByteSymbol o Número (no rango).
		vii) El valor de un atributo puede ser obtenido de la lista de valores definidos para ese atributo, o ser un valor nuevo.
		viii) El valor de un atributo puede tener un peso asignado, el cual se interpreta como 'el grado de certidumbre del 
		     usuario': 0.0 -- no tiene grado de certidumbre asignado; 0.5 - el usuario no está seguro del valor brindado; 
		     1.0 - el usuario está seguro del valor brindado.
		ix) La descripción no puede tener dos Heurísticas de Agrupamiento con el mismo nombre.
		x) Las Heurísticas de Agrupamiento pueden tener asignado un peso entre 0.0 y 1.0, el cual se interpreta como 
		    'el grado de interés que el usuario muestra por la heurística de agrupamiento descrita'.
		xi) Cada Heurística de Agrupamiento debe tener solo un valor.
		xii) El valor de una Heurística de Agrupamiento debe ser ByteSymbol o Número (no rango).
		xiii) El valor de una Heurística de Agrupamiento puede ser obtenido de la lista de valores definidos para esa Heurística 
			de Agrupamiento, o ser un valor nuevo.
		xiv) El valor de una Heurística de Agrupamiento puede tener un peso asignado, interpretado como 'el grado de certidumbre 
		     del usuario': 0.0 -- no tiene grado de certidumbre asignado; 0.5 - el usuario no está seguro del valor brindado; 1.0 - el 
		     usuario está seguro del valor brindado.

		* Expectativas de desempeño:
		E1 (expectativa del sistema): Satisfacer la meta establecida.
		NO: E2 (expectativa del usuario): Presentar soluciones cuyos niveles taxonómicos sean más generales que la meta 
			establecida (S | N, valor default: S).
		NO: E3 (expectativa del usuario): Presentar soluciones cuyos niveles taxonómicos sean más específicos que la meta 
			establecida (S | N, valor default: S).
		E4 (expectativa del usuario): Número máximo de soluciones a presentar: (Integer > 0, número default: 3). 
		E5 (expectativa del usuario): Si no se encontraron soluciones para la descripción dada, presentar posibles alternativas 
			de casos fallidos, cuyos taxones asociados no corresponden a dicha descripción: (S | N, default: S).
		NO: E6 (expectativa del usuario): Tiempo máximo (en minutos) para el proceso de inferencia: (nil | Integer > 0). El valor 
			nil representa un tiempo indefinido.  La razón de ser de esta expectativa es que el proceso de inferencia puede 
			prolongarse demasiado debido a actividades como la determinación de similitud entre descriptores, la verificación 
			de descriptores contra la Jerarquía Taxonómica y el diálogo con el usuario. Si el tiempo de proceso de inferencia 
			se cumple, el Razonador podría verse obligado a seleccionar soluciones con las hipótesis que tenga disponibles 
			en ese momento.
		E7 (expectativa del usuario): Grado de similitud mínimo (default: el elemento en la posición ((número de elementos / 2) + 1) 
			de SimRanges.
		NO: E8 (expectativa del usuario): Número máximo de posibles soluciones a confirmar mediante diálogo (Integer > 0, número 
			default: 3).

	 Returns: self."

	^self.!

useCaseMemory

	(self searchCaseGroupingHeuristics = nil)
	ifTrue: [ ^nil ].

	(self searchCaseStructures = nil)
	ifTrue: [ ^nil ].

	^self.!

useTaxonomicHierarchy

	(self searchTaxonGroupingHeuristics = nil)
	ifTrue: [ ^nil ].

	(self searchTaxonStructures = nil)
	ifTrue: [ ^nil ].

	^self.! !

!Reasoner methodsFor: 'private - case search by grouping heuristic'!

processSuccessfulGHSearchOutputWith: searchAutomaton and: hypothesis1 and: hypothesis2

	"PRECONDITION: (Search atuomaton's possible solutions list is NOT empty)

	 RETURNS:	nil - if the precondition is not met, OR an error occurred.
				self - if all OK"

	| ps index currHypothesis |

	"Check the precondition"
	(searchAutomaton searchOutput possibleSolutions = nil)
	ifTrue: [ ^nil ].

	"Successful search: at least one case was found. Scan the search automaton's possible solution's list"
	[ searchAutomaton searchOutput possibleSolutions isEmpty ]
	whileFalse: [

		"Get the next possible solution from the search automaton's output"
		ps := searchAutomaton searchOutput possibleSolutions removeFirst.

		"Attempt to add the possible solution to the first hypothesis. If not successful, attempt
		to add it to the second hypothesis. If unsuccessful again, return an error value"
		((hypothesis1 possibleSolutions: ps) = nil)
		ifTrue: [ ((hypothesis2 possibleSolutions: ps) = nil) ifTrue: [ ^nil ] ].

	].    "END [ searchAutomaton searchOutput possibleSolutions isEmpty ] whileFalse:"

	"Once all possible solutions have been loaded, copy the search automaton's unmatched description"
	(hypothesis1 possibleSolutions isEmpty)
	ifFalse: [ hypothesis1 copyToUnmatchedDescriptionFrom: (searchAutomaton searchOutput unmatchedDescription) ].

	(hypothesis2 possibleSolutions isEmpty)
	ifFalse: [ hypothesis2 copyToUnmatchedDescriptionFrom: (searchAutomaton searchOutput unmatchedDescription) ].

	"Now copy the justification"
	(hypothesis1 possibleSolutions isEmpty)
	ifFalse: [ hypothesis1 copyToJustificationFrom: (searchAutomaton searchOutput justification) ].

	(hypothesis2 possibleSolutions isEmpty)
	ifFalse: [ hypothesis2 copyToJustificationFrom: (searchAutomaton searchOutput justification) ].

	"Finally, add the hypotheses to conflict sets"
	index := 1.
	currHypothesis := hypothesis1.
	[ index <= 2 ]
	whileTrue: [

		(currHypothesis possibleSolutions isEmpty)
		ifFalse: [

			((currHypothesis possibleSolutions at: 1) status = #+)
			ifTrue: [ (self succGHConflictSet: currHypothesis) ]
			ifFalse: [

				((currHypothesis possibleSolutions at: 1) status = #-)
				ifTrue: [ (self failGHConflictSet: currHypothesis) ]
				ifFalse: [ ^nil ].
			].

		].    "END (currHypothesis possibleSolutions isEmpty) ifFalse:"

		currHypothesis := hypothesis2.
		index := index + 1.

	].    "END [ i<=2 ] whileTrue:"

	^self.!

searchCaseGroupingHeuristics

	"Use the grouping heuristic description as search data.

	 RETURNS: nil - If an error occurred, or the user cancelled the search process.
				self - OK"

	| gh hypothesis1 hypothesis2 problemDescription caseNetRoot searchAutomaton status |

	[ self groupHDescription isEmpty ]
	whileFalse: [

		"Remove the next grouping heuristic from the description"
		gh := self groupHDescription removeFirst.

		"Create a first instance of Hypothesis and assign the grouping heuristic as descriptive element"
		hypothesis1 := Hypothesis new.
		hypothesis1 descriptiveElement: gh.

		"Create a second instance of hypothesis, and again, assign the same grouping heuristic as descriptive element"
		hypothesis2 := Hypothesis new.
		hypothesis2 descriptiveElement: gh.

		"Get the SAV problem description from the grouping heuristic. If no description available, return error value"
		problemDescription := gh createSAVDescription: (self taxonomicGroupName).
		(problemDescription = nil) ifTrue: [ ^nil ].

		"Get the net root that corresponds to the grouping heuristic"
		caseNetRoot := (self caseMemory root getNetWith: (self taxonomicGroupName)).
		(caseNetRoot = nil)
		ifFalse: [

			"Create a new instance of case net search automaton"
			searchAutomaton := SAVCaseDFSAutomaton newWith: caseNetRoot.

			"Begin the search with the given problem description"
			searchAutomaton beginWith: problemDescription.
			status := searchAutomaton status.

			((status = #error) | (status = #cancel))
			ifTrue: [ ^nil ].

			(status = #success)
			ifTrue: [
				self processSuccessfulGHSearchOutputWith: searchAutomaton and: hypothesis1 and: hypothesis2.
				^(self searchCaseGroupingHeuristics).
			].

			(status = #fail)
			ifTrue: [ 
				"Copy the unmatched description and the justification to the first hypothesis, which is the one
				 we'll continue to use from now on."
				hypothesis1 copyToUnmatchedDescriptionFrom: (searchAutomaton searchOutput unmatchedDescription).
				hypothesis1 copyToJustificationFrom: (searchAutomaton searchOutput justification).
			].

		].    "END (caseNetRoot = nil) ifFalse:"

		"At this point, either: a) no net root was found, or b) the status of the net search was unsuccessful 
		 (i.e., status = #fail). Try doing a taxonomic search"

		"Refresh the problem description"
		problemDescription := gh createSAVDescription: (self taxonomicGroupName).
		(problemDescription = nil) ifTrue: [ ^nil ].

		"Perform a taxonomic search"
		searchAutomaton := TaxonGHISAutomaton newWith: (self taxonomy groupingHeuristicIndex).
		searchAutomaton beginWith: problemDescription.
		status := searchAutomaton status.

		((status = #error) | (status = #cancel))
		ifTrue: [ ^nil ].

		(status = #success)
		ifTrue: [

			"Load all the possible solutions into the hypothesis"
			[ searchAutomaton searchOutput possibleSolutions isEmpty ]
			whileFalse: [

				"Attempt to add the possible solution to the first hypothesis. If not successful,
				 return an error value"
				 ((hypothesis1 possibleSolutions: searchAutomaton searchOutput possibleSolutions removeFirst) = nil)
				 ifTrue: [ ^nil ].

			].    "END [ searchAutomaton searchOutput possibleSolutions isEmpty ] whileFalse:"

			hypothesis1 copyToUnmatchedDescriptionFrom: (searchAutomaton searchOutput unmatchedDescription).
			hypothesis1 copyToUnmatchedDescriptionFrom: (searchAutomaton searchOutput unmatchedDescription).

			"Add the hypothesis to the successful conflict set"
			self succGHConflictSet: hypothesis1.

			^(self searchCaseGroupingHeuristics).

		].    "END (status = #success) ifTrue:"

		"Search was unsuccessful. Add hypothesis to the no-results set"
		self noResultsSet: hypothesis1.

	].    "END [ self groupHDescription isEmpty ] whileFalse:"

	^self.! !

!Reasoner methodsFor: 'private - case search by structure'!

processSuccessfulStructSearchOutputWith: anOutputCopy and: hypothesis1 and: hypothesis2

	"PRECONDITION: (anOutputCopy possible solutions list is NOT empty)

	 RETURNS:	nil - if the precondition is not met, OR an error occurred.
				self - if all OK"

	| ps index currHypothesis dialog status |

	"Check the precondition"
	(anOutputCopy possibleSolutions = nil)
	ifTrue: [ ^nil ].

	(anOutputCopy possibleSolutions isEmpty)
	ifTrue: [ ^nil ].

	"Successful search: at least one case was found. Scan the output copy's possible solution's list"
	[ anOutputCopy possibleSolutions isEmpty ]
	whileFalse: [

		"Get the next possible solution from anOutputCopy'"
		ps := anOutputCopy possibleSolutions removeFirst.

		"Attempt to add the possible solution to the first hypothesis. If not successful, attempt
		to add it to the second hypothesis. If unsuccessful again, return an error value. At the 
		end of this loop, the following assertion will always hold: hypothesis1 will never be empty
		(it will always have at least ONE element), and hypothesis2 may be empty"
		((hypothesis1 possibleSolutions: ps) = nil)
		ifTrue: [ ((hypothesis2 possibleSolutions: ps) = nil) ifTrue: [ ^nil ] ].

	].    "END [ anOutputCopy possibleSolutions isEmpty ] whileFalse:"

	"Once all possible solutions have been loaded, copy anOutputCopy's unmatched description"
	(hypothesis1 possibleSolutions isEmpty)
	ifFalse: [ hypothesis1 copyToUnmatchedDescriptionFrom: (anOutputCopy unmatchedDescription) ].

	(hypothesis2 possibleSolutions isEmpty)
	ifFalse: [ hypothesis2 copyToUnmatchedDescriptionFrom: (anOutputCopy unmatchedDescription) ].

	"Now copy the justification"
	(hypothesis1 possibleSolutions isEmpty)
	ifFalse: [ hypothesis1 copyToJustificationFrom: (anOutputCopy justification) ].

	(hypothesis2 possibleSolutions isEmpty)
	ifFalse: [ hypothesis2 copyToJustificationFrom: (anOutputCopy justification) ].

	"HYPOTHESIS1: If none of the possible solutions is equal to, or more specific than
	 the identification goal, establish a new dialog with the user, in order to try to draw
	 the existing possible solutions nearer to the said goal"
	((hypothesis1 possibleSolutions at: 1) status = #+)
	ifTrue: [

		((TaxonomicLevels transformToIndex: ((hypothesis1 possibleSolutions at: 1) level)) <
		 (TaxonomicLevels transformToIndex: (self identGoal)))
		ifTrue: [

			dialog := GoalApproachingDialog newWithGoal: (self identGoal) 
											hypothesis: hypothesis1
											taxonomy: (self taxonomy) 
											similarityRanges: (self minSimilarityDegree).
			dialog chat.
			status := dialog status.
			((status = #error) | (status = #cancel))
			ifTrue: [ ^nil ].

		].    "END ((TaxonomicLevels transformToIndex:...) ifTrue:"

	]    "END ((hypothesis1 possibleSolutions at: 1) status = #+) ifTrue:"

	"hypothesis1 does not contain positive cases"
	ifFalse: [

		"HYPOTHESIS2: If none of the possible solutions is equal to, or more specific than
		 the identification goal, establish a new dialog with the user, in order to try to draw
	 	the existing possible solutions nearer to the said goal"
		(hypothesis2 isEmpty)
		ifFalse: [

			((TaxonomicLevels transformToIndex: ((hypothesis2 possibleSolutions at: 1) level)) <
			 (TaxonomicLevels transformToIndex: (self identGoal)))
			ifTrue: [

				dialog := GoalApproachingDialog newWithGoal: (self identGoal) 
												hypothesis: hypothesis2
												taxonomy: (self taxonomy) 
												similarityRanges: (self minSimilarityDegree).
				dialog chat.
				status := dialog status.
				((status = #error) | (status = #cancel))
				ifTrue: [ ^nil ].

			].    "END ((TaxonomicLevels transformToIndex:...) ifTrue:"

		].    "END (hypothesis2 isEmpty) ifFalse:"

	].    "END ((hypothesis1 possibleSolutions at: 1) status = #+) ifFalse"

	"Finally, add the hypotheses to conflict sets"
	index := 1.
	currHypothesis := hypothesis1.
	[ index <= 2 ]
	whileTrue: [

		(currHypothesis possibleSolutions isEmpty)
		ifFalse: [

			((currHypothesis possibleSolutions at: 1) status = #+)
			ifTrue: [ (self succStructConflictSet: currHypothesis) ]
			ifFalse: [

				((currHypothesis possibleSolutions at: 1) status = #-)
				ifTrue: [ (self failStructConflictSet: currHypothesis) ]
				ifFalse: [ ^nil ].
			].

		].    "END (currHypothesis possibleSolutions isEmpty) ifFalse:"

		currHypothesis := hypothesis2.
		index := index + 1.

	].    "END [ i<=2 ] whileTrue:"

	^self.!

searchCaseStructures

	"Use the structure description as search data.

	 RETURNS: nil - If an error occurred, or the user cancelled the search process.
				self - OK"

	| net hypothesis1 hypothesis2 problemDescription caseNetRoot searchAutomaton status s outputCopy dialog |

	[ self structDescription isEmpty ]
	whileFalse: [

		"Remove the next structure from the description"
		s := self structDescription removeFirst.

		"Create a first instance of Hypothesis and assign the structure as descriptive element"
		hypothesis1 := Hypothesis new.
		hypothesis1 descriptiveElement: s.

		"Create a second instance of hypothesis, and again, assign the same structure as descriptive element"
		hypothesis2 := Hypothesis new.
		hypothesis2 descriptiveElement: s.

		"Get the SAV problem description from the structure. If no description available, return error value"
		problemDescription := s createSAVDescription: (self taxonomicGroupName).
		(problemDescription = nil) ifTrue: [ ^nil ].

		"Get the net root that corresponds to the structure"
		net := (self caseMemory root getNetWith: (s name)).
		(net = nil) 
		ifTrue: [ caseNetRoot := nil. ]
		ifFalse: [ caseNetRoot := net root. ].

		(caseNetRoot = nil)
		ifFalse: [

			"Create a new instance of case net search automaton"
			searchAutomaton := SAVCaseDFSAutomaton newWith: caseNetRoot.

			"Begin the search with the given problem description"
			searchAutomaton beginWith: problemDescription.
			status := searchAutomaton status.

			((status = #error) | (status = #cancel))
			ifTrue: [ ^nil ].

			"If the automaton returns a non-empty problem description list, then the REASONER MUST call 
			 it again with that remaining description. Before doing so, all lists, except the doubtful and unconfirmed 
			 ones, MUST be flushed. Make sure the new search begins at root level, and all necessary control variables 
			 are correctly set. This process repeats until the problem description list is EMPTY. After each successive 
			 call, the unmatched description, the justification and whatever possible solutions MUST be concatenated 
			 to the original search-automaton output copy"
			outputCopy := (searchAutomaton searchOutput) copy.
			outputCopy taxonomy: (self taxonomy).
			[ problemDescription isEmpty ]
			whileFalse: [

				searchAutomaton newSearchWith: problemDescription.
				status := searchAutomaton status.

				((status = #error) | (status = #cancel))
				ifTrue: [ ^nil ].

				outputCopy appendToPossibleSolutions: (searchAutomaton searchOutput possibleSolutions).
				outputCopy appendToJustification: (searchAutomaton searchOutput justification).
				outputCopy appendToUnmatchedDescription: (searchAutomaton searchOutput unmatchedDescription).
			].
			outputCopy compress.

			((outputCopy possibleSolutions) = nil)
			ifFalse: [
				(outputCopy possibleSolutions isEmpty)
				ifFalse: [

					((self processSuccessfulStructSearchOutputWith: outputCopy and: hypothesis1 and: hypothesis2) = nil)
					ifTrue: [ ^nil ].

					^(self searchCaseStructures).
				].
			].

			"At this point, status is neither #error, #cancel, nor #success (this value is implied by the
			 condition (outputCopy possibleSolutions isEmpty) ifFalse:. Thus, is must be #fail. Copy 
			 the unmatched description and the justification to the first hypothesis, which is the one
		   	 we'll continue to use from now on."
			hypothesis1 copyToUnmatchedDescriptionFrom: (outputCopy unmatchedDescription).
			hypothesis1 copyToJustificationFrom: (outputCopy justification).

		].    "END (caseNetRoot = nil) ifFalse:"

		"At this point, either: a) no net root was found, or b) the status of the net search was unsuccessful 
		 (i.e., status = #fail). Try doing a taxonomic search"

		"Refresh the problem description"
		problemDescription := s createSAVDescription: (self taxonomicGroupName).
		(problemDescription = nil) ifTrue: [ ^nil ].

		"Perform a taxonomic search"
		searchAutomaton := TaxonSISAutomaton newWith: (self taxonomy structureIndex) and: (self minSimilarityDegree).
		searchAutomaton beginWith: problemDescription.
		status := searchAutomaton status.

		((status = #error) | (status = #cancel))
		ifTrue: [ ^nil ].

		(status = #success)
		ifTrue: [

			"Load all the possible solutions into the hypothesis"
			[ searchAutomaton searchOutput possibleSolutions isEmpty ]
			whileFalse: [

				"Attempt to add the possible solution to the first hypothesis. If not successful,
				 return an error value"
				 ((hypothesis1 possibleSolutions: searchAutomaton searchOutput possibleSolutions removeFirst) = nil)
				 ifTrue: [ ^nil ].

			].    "END [ searchAutomaton searchOutput possibleSolutions isEmpty ] whileFalse:"

			hypothesis1 copyToUnmatchedDescriptionFrom: (searchAutomaton searchOutput unmatchedDescription).
			hypothesis1 copyToUnmatchedDescriptionFrom: (searchAutomaton searchOutput unmatchedDescription).

			"HYPOTHESIS1: If none of the possible solutions is equal to, or more specific than the identification goal, 
			 establish a new dialog with the user, in order to try to draw the existing possible solutions nearer to the goal"
			((hypothesis1 possibleSolutions at: 1) status = #+)
			ifTrue: [

				((TaxonomicLevels transformToIndex: ((hypothesis1 possibleSolutions at: 1) level)) <
				 (TaxonomicLevels transformToIndex: (self identGoal)))
				ifTrue: [

					dialog := GoalApproachingDialog newWithGoal: (self identGoal) 
													hypothesis: hypothesis1
													taxonomy: (self taxonomy) 
													similarityRanges: (self minSimilarityDegree).
					dialog chat.
					status := dialog status.
					((status = #error) | (status = #cancel))
					ifTrue: [ ^nil ].

				].    "END ((TaxonomicLevels transformToIndex:...) ifTrue:"

			].    "END ((hypothesis1 possibleSolutions at: 1) status = #+) ifTrue:"

			"Add the hypothesis to the successful conflict set"
			self succStructConflictSet: hypothesis1.

			^(self searchCaseStructures).

		].    "END (status = #success) ifTrue:"

		"Search was unsuccessful. Add hypothesis to the no-results set"
		self noResultsSet: hypothesis1.

	].    "END [ self structDescription isEmpty ] whileFalse:"

	^self.! !

!Reasoner methodsFor: 'private - taxon search by grouping heuristic'!

searchTaxonGroupingHeuristics

	"Performs  a search in the taxonomic hierarchy, using a set of grouping
	 heuristics as input data.

	 RETURNS: nil - if an error occurs, OR the user cancels the search process.
				self - OK"

	| gh hypothesis problemDescription searchAutomaton status |

	[ self groupHDescription isEmpty ]
	whileFalse: [

		"Remove the next grouping heuristic from the description"
		gh := self groupHDescription removeFirst.

		"Create a first instance of Hypothesis and assign the grouping heuristic as descriptive element"
		hypothesis := Hypothesis new.
		hypothesis descriptiveElement: gh.

		"Get the SAV problem description from the grouping heuristic"
		problemDescription := gh createSAVDescription: (self taxonomicGroupName).
		(problemDescription = nil) ifTrue: [ ^nil ].

		"Perform a taxonomic search"
		searchAutomaton := TaxonGHISAutomaton newWith: (self taxonomy groupingHeuristicIndex).
		searchAutomaton beginWith: problemDescription.
		status := searchAutomaton status.

		((status = #error) | (status = #cancel))
		ifTrue: [ ^nil ].

		(status = #success)
		ifTrue: [

			"Load all the possible solutions into the hypothesis"
			[ searchAutomaton searchOutput possibleSolutions isEmpty ]
			whileFalse: [

				"Attempt to add the possible solution to the hypothesis. If not successful, return an error value"
				 ((hypothesis possibleSolutions: searchAutomaton searchOutput possibleSolutions removeFirst) = nil)
				 ifTrue: [ ^nil ].

			].    "END [ searchAutomaton searchOutput possibleSolutions isEmpty ] whileFalse:"

			hypothesis copyToUnmatchedDescriptionFrom: (searchAutomaton searchOutput unmatchedDescription).
			hypothesis copyToUnmatchedDescriptionFrom: (searchAutomaton searchOutput unmatchedDescription).

			"Add the hypothesis to the successful conflict set"
			self succGHConflictSet: hypothesis.

			^(self searchTaxonGroupingHeuristics).

		].    "END (status = #success) ifTrue:"

		"Search was unsuccessful. Add hypothesis to the no-results set"
		self noResultsSet: hypothesis.

	].    "END [ self groupHDescription isEmpty ] whileFalse:"

	^self.! !

!Reasoner methodsFor: 'private - taxon search by structure'!

searchTaxonStructures

	"Performs  a search in the taxonomic hierarchy, using a set of structures
	 as input data.

	 RETURNS: nil - if an error occurs, OR the user cancels the search process.
				self - OK"

	| hypothesis problemDescription searchAutomaton status s dialog |

	[ self structDescription isEmpty ]
	whileFalse: [

		"Remove the next structure from the description"
		s := self structDescription removeFirst.

		"Create a first instance of Hypothesis and assign the structure as descriptive element"
		hypothesis := Hypothesis new.
		hypothesis descriptiveElement: s.

		"Get the SAV problem description from the structure"
		problemDescription := s createSAVDescription: (self taxonomicGroupName).
		(problemDescription = nil) ifTrue: [ ^nil ].

		"Perform a taxonomic search"
		searchAutomaton := TaxonSISAutomaton newWith: (self taxonomy structureIndex) and: (self minSimilarityDegree).
		searchAutomaton beginWith: problemDescription.
		status := searchAutomaton status.

		((status = #error) | (status = #cancel))
		ifTrue: [ ^nil ].

		(status = #success)
		ifTrue: [

			"Load all the possible solutions into the hypothesis"
			[ searchAutomaton searchOutput possibleSolutions isEmpty ]
			whileFalse: [

				"Attempt to add the possible solution to the hypothesis. If not successful, return an error value"
				 ((hypothesis possibleSolutions: searchAutomaton searchOutput possibleSolutions removeFirst) = nil)
				 ifTrue: [ ^nil ].

			].    "END [ searchAutomaton searchOutput possibleSolutions isEmpty ] whileFalse:"

			hypothesis copyToUnmatchedDescriptionFrom: (searchAutomaton searchOutput unmatchedDescription).
			hypothesis copyToUnmatchedDescriptionFrom: (searchAutomaton searchOutput unmatchedDescription).

			"Determine if necessary to establish a dialog with the user (in case none of the possible solutions is
			 equal to or more specific than the identification goal)"
			((TaxonomicLevels transformToIndex: ((hypothesis possibleSolutions at: 1) level)) <
			 (TaxonomicLevels transformToIndex: (self identGoal)))
			ifTrue: [

				dialog := GoalApproachingDialog newWithGoal: (self identGoal) 
												hypothesis: hypothesis
												taxonomy: (self taxonomy) 
												similarityRanges: (self minSimilarityDegree).
				dialog chat.
				status := dialog status.
				((status = #error) | (status = #cancel))
				ifTrue: [ ^nil ].

			].    "END ((TaxonomicLevels transformToIndex:...) ifTrue:"

			"Add the hypothesis to the successful conflict set"
			self succStructConflictSet: hypothesis.

			^(self searchTaxonStructures).

		].    "END (status = #success) ifTrue:"

		"Search was unsuccessful. Add hypothesis to the no-results set"
		self noResultsSet: hypothesis.

	].    "END [ self structDescription isEmpty ] whileFalse:"

	^self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Reasoner class
	instanceVariableNames: ''!


!Reasoner class methodsFor: 'instance creation'!

newWith: anIdentificationSystem

	| reasoner |

	reasoner := super new.
	^(reasoner initializeWith: anIdentificationSystem).! !

Object subclass: #PossibleSolution
	instanceVariableNames: 'solution solutionDescription confirmedDescription unconfirmedDescription doubtfulDescription contradictions evaluated points hypothesis '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Reasoner'!


!PossibleSolution methodsFor: 'accessing'!

confirmedDescription

	^confirmedDescription.!

contradictions 

	^contradictions.!

doubtfulDescription

	^doubtfulDescription.!

evaluated 

	^evaluated.!

hypothesis

	^hypothesis.!

level

	| className |

	(self solution = nil)
	ifTrue: [ ^nil ].

	className := (self solution) class name.

	((className = SAVCase getClassName) |
	 (className = Case getClassName))
	ifTrue: [ ^((self solution) solution level) ].

	(className = Taxon getClassName) 
	ifTrue: [ ^((self solution) level) ].

	^nil.!

name

	| className |

	(self solution = nil)
	ifTrue: [ ^nil ].

	className := (self solution) class name.

	((className = SAVCase getClassName) |
	 (className = Case getClassName))
	ifTrue: [ ^((self solution) solution name) ].

	(className = Taxon getClassName) 
	ifTrue: [ ^((self solution) name) ].

	^nil.!

points 

	^points.!

solution 

	^solution.!

solutionDescription

	^solutionDescription.!

status

	"Taxon instances always have a positive status"
	((self solution) class name = Taxon getClassName)
	ifTrue: [ ^#+ ].

	"Return the status of the associated Case or SAVCase"
	^(self solution status).!

unconfirmedDescription

	^unconfirmedDescription.! !

!PossibleSolution methodsFor: 'testing'!

includes: aSAVDescriptor in: aDescription

	"Determines if aSAVDescriptor is already a member of aDescriptionList. The argument aSAVDescriptor is a member of 
	aDescriptionList when its structure and attribute names match with the structure and attribute names of a list element.
	Returns: 	-1 (error state): The argument aDescriptionList IS NOT a valid list for self.
				nil: aSAVDescriptor IS NOT a member of aDescriptionList.
				not nil: an element of aDescriptionList whose structure and attribute names match those of aSAVDescriptor"

	| d dSize |

	"First step: make sure that the process is executed against one of my lists"
	((aDescription = solutionDescription) | 
	 (aDescription = confirmedDescription) | 
	 (aDescription = unconfirmedDescription) | 
	 (aDescription = doubtfulDescription) | 
	 (aDescription = contradictions))
	ifFalse: [ ^(-1) ].

	dSize := aDescription size.

	1 to: dSize do:
	[:i |
		d := aDescription at: i.

		((d structure = aSAVDescriptor structure) & (d attribute = aSAVDescriptor attribute))
		ifTrue: [ ^d ].

		"Stop searching if the next descriptor's structure name is (alphabetically) greater than the argument's structure name"
		(i < dSize) ifTrue: [ (aSAVDescriptor structure < ((aDescription at: (i + 1)) structure)) ifTrue: [^nil] ].
	].

	^nil.!

includesFull: aSAVDescriptor in: aDescription

	"Determines if a full aSAVDescriptor is already a member of aDescriptionList. The argument aSAVDescriptor is a member of 
	aDescriptionList when its structure, attribute and value match with the structure and attribute names of a list element.
	Returns: 	-1 (error state): The argument aDescriptionList IS NOT a valid list for self.
				nil: aSAVDescriptor IS NOT a member of aDescriptionList.
				not nil: an element of aDescriptionList whose structure and attribute names match those of aSAVDescriptor"

	| d dSize |

	"First step: make sure that the process is executed against one of my lists"
	((aDescription = solutionDescription) | 
	 (aDescription = confirmedDescription) | 
	 (aDescription = unconfirmedDescription) | 
	 (aDescription = doubtfulDescription) | 
	 (aDescription = contradictions))
	ifFalse: [ ^(-1) ].

	dSize := aDescription size.

	1 to: dSize do:
	[:i |
		d := aDescription at: i.

		((d structure = aSAVDescriptor structure) & (d attribute = aSAVDescriptor attribute) & (d value = aSAVDescriptor value))
		ifTrue: [ ^d ].

		"Stop searching if the next descriptor's structure name is (alphabetically) greater than the argument's structure name"
		(i < dSize) ifTrue: [ (aSAVDescriptor structure < ((aDescription at: (i + 1)) structure)) ifTrue: [^nil] ].
	].

	^nil.! !

!PossibleSolution methodsFor: 'copying'!

copy: anExternalDescription to: aLocalDescription

	"First step: make sure that the process is executed against one of my lists"
	((aLocalDescription = solutionDescription) | 
	 (aLocalDescription = confirmedDescription) | 
	 (aLocalDescription = unconfirmedDescription) | 
	 (aLocalDescription = doubtfulDescription) | 
	 (aLocalDescription = contradictions))
	ifFalse: [ ^nil ].

	1 to: (anExternalDescription size) do:
	[:i | aLocalDescription add: (anExternalDescription at: i) ].

	^self.! !

!PossibleSolution methodsFor: 'adding'!

confirmedDescription: aSAVDescriptor

	| retVal |

	retVal := self includes: aSAVDescriptor in: confirmedDescription.
	((retVal = -1) | ((retVal = nil)  not)) ifTrue: [ ^retVal ].

	confirmedDescription add: aSAVDescriptor.
	^self.!

contradictions: aSAVDescriptor

	| retVal |

	retVal := self includes: aSAVDescriptor in: contradictions.
	((retVal = -1) | ((retVal = nil)  not)) ifTrue: [ ^retVal ].

	contradictions add: aSAVDescriptor.
	^self.!

doubtfulDescription: aSAVDescriptor

	| retVal |

	retVal := self includesFull: aSAVDescriptor in: doubtfulDescription.
	((retVal = -1) | ((retVal = nil)  not)) ifTrue: [ ^retVal ].

	doubtfulDescription add: aSAVDescriptor.
	^self.!

evaluated: aBoolean

	evaluated := aBoolean.
	^self.!

hypothesis: aHypothesis

	hypothesis := aHypothesis.
	^self.!

incrementPoints

	points := (points + 1).
	^self.!

incrementPointsBy: anInteger

	points := (points + anInteger).
	^self.!

solution: aPossibleSolution

	| className |

	"Make sure class of the PossibleSolution is OK"
	className := aPossibleSolution class name.
	((className = SAVCase getClassName) | (className = Case getClassName) | (className = Taxon getClassName))
	ifFalse: [ ^nil ].

	solution := aPossibleSolution.
	^self.!

solutionDescription: aSAVDescriptor

	| retVal |

	retVal := self includes: aSAVDescriptor in: solutionDescription.
	((retVal = -1) | ((retVal = nil)  not)) ifTrue: [ ^retVal ].

	solutionDescription add: aSAVDescriptor.
	^self.!

unconfirmedDescription: aSAVDescriptor

	| retVal |

	retVal := self includesFull: aSAVDescriptor in: unconfirmedDescription.
	((retVal = -1) | ((retVal = nil)  not)) ifTrue: [ ^retVal ].

	unconfirmedDescription add: aSAVDescriptor.
	^self.! !

!PossibleSolution methodsFor: 'initializing'!

initialize

	| sb |

	"Sort criteria: concatenated structure and attribute names"
	sb := [:SAVDesc1 :SAVDesc2 | 
			(SAVDesc1 structure , SAVDesc1 attribute) <= 
			(SAVDesc2 structure , SAVDesc2 attribute) ].

	solution := nil.

	solutionDescription := SortedCollection new.
	solutionDescription sortBlock: sb.

	confirmedDescription := SortedCollection new.
	confirmedDescription sortBlock: sb.

	unconfirmedDescription := SortedCollection new.
	unconfirmedDescription sortBlock: sb.

	doubtfulDescription := SortedCollection new.
	doubtfulDescription sortBlock: sb.

	contradictions := SortedCollection new.
	contradictions sortBlock: sb.

	evaluated := false.
	points := 0.
	hypothesis := nil.

	^self.! !

!PossibleSolution methodsFor: 'inheritance'!

appendToConfirmedDescription: aDescription

	1 to: (aDescription size) do:
	[:i | self confirmedDescription: (aDescription at: i) ].

	^self.!

appendToDoubtfulDescription: aDescription

	1 to: (aDescription size) do:
	[:i | self doubtfulDescription: (aDescription at: i) ].

	^self.!

appendToSolutionDescription: aDescription

	1 to: (aDescription size) do:
	[:i | self solutionDescription: (aDescription at: i) ].

	^self.!

appendToUnconfirmedDescription: aDescription

	1 to: (aDescription size) do:
	[:i | self unconfirmedDescription: (aDescription at: i) ].

	^self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PossibleSolution class
	instanceVariableNames: ''!


!PossibleSolution class methodsFor: 'instance creation'!

new

	| ps |

	ps := super new.
	ps initialize.
	^ps.! !

Object subclass: #PossibleSolutionSelector
	instanceVariableNames: 'identificationGoal successfulStructConflictSet failedStructConflictSet successfulGrpHeuristicConflictSet failedGrpHeuristicConflictSet maxNumberSolutions showFailedSolutions goalSolutions specificSolutions generalSolutions status '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Reasoner'!


!PossibleSolutionSelector methodsFor: 'initializing'!

initializeWith: anIdentGoal and: aSuccSList and: aFailSList and: aSuccGHList and: aFailGHList and: aNumberOfSolutions and: showFailed

	"USER EXPECTATION: aNumberOfSolutions is an integer argument, that determines the maximum number of solutions the user wants to see.
	 USER EXPECTATION: showFailed is a boolean argument, that determines whether or not to show failed solutions to the user."

	| sb |

	identificationGoal := anIdentGoal.
	successfulStructConflictSet := aSuccSList.
	failedStructConflictSet := aFailSList.
	successfulGrpHeuristicConflictSet := aSuccGHList.
	failedGrpHeuristicConflictSet := aFailGHList.
	maxNumberSolutions := aNumberOfSolutions.
	showFailedSolutions := showFailed.

	self status: #undefined.

	"#certain < #doubtful < #uncertain"
	sb := [ :x :y | (((x degreeOfCertainty) <= (y degreeOfCertainty)) & ((x solution points) >= (y solution points))) ].

	goalSolutions := SortedCollection new.
	goalSolutions sortBlock: sb.

	specificSolutions := SortedCollection new.
	specificSolutions sortBlock: sb.

	generalSolutions := SortedCollection new.
	generalSolutions sortBlock: sb.

	^self.! !

!PossibleSolutionSelector methodsFor: 'accessing'!

failedGrpHeuristicConflictSet 

	^failedGrpHeuristicConflictSet.!

failedStructConflictSet 

	^failedStructConflictSet.!

generalSolutions

	^generalSolutions.!

goalSolutions

	^goalSolutions.!

identificationGoal

	^identificationGoal.!

maxNumberSolutions 

	^maxNumberSolutions.!

showFailedSolutions

	^showFailedSolutions.!

specificSolutions

	^specificSolutions.!

status

	^status.!

successfulGrpHeuristicConflictSet 

	^successfulGrpHeuristicConflictSet.!

successfulStructConflictSet 

	^successfulStructConflictSet.! !

!PossibleSolutionSelector methodsFor: 'selecting solutions'!

distribute: aSortedPossibleSolutionsList

	"This method takes as argument a list of possible solutions, sorted by their point score. Each possible solution 
	 has a taxonomic level, which can be represented numerically. This level is compared against the [numeric representation 
	 of the] level stated in the identification goal. If the possible solution's level is less than the stated identification goal, then 
	 that possible solution is added to the general-solutions list. If the level is equal to the stated identification goal, the possible 
	 solution is added to the goal-solutions list. Finally, if the level is greater than the stated identification goal, the possible solution 
	 is added to the specific-solutions list.

	 NOTE: Since the argument is a sorted list, then the first elements to be added to any of the solutions lists are those
	 with the highest scores.

	 The process will stop when either of these conditions hold:
	     1) The number of elements in the goal-solutions list is equal to the maximum number of solutions expected by the user.
	     2) The number of elements in the specific-solutions list is equal to the maximum number of solutions expected by the user.
	     3) The sum of the elements belonging to the goal-solutions and specific-solutions lists is greater than or equal to the
	         maximum number of solutions expected by the user.
	     4) The argument aSortedPossibleSolutionsList is empty.

	 PRECONDITION: aSortedPossibleSolutionsList is NOT empty.

	 Returns: self. The process ran OK."

	| i max ps goalLevel psLevel |

	"Check the precondition"
	(aSortedPossibleSolutionsList isEmpty)
	ifTrue: [ ^self ].

	"Get the maximum number of elements that can be added  to any solutions list"
	((aSortedPossibleSolutionsList size) <= (self maxNumberSolutions))
	ifTrue: [ max := (aSortedPossibleSolutionsList size) ]
	ifFalse: [ max := (self maxNumberSolutions) ].

	"Get the identification goal as number"
	goalLevel := TaxonomicLevels transformToIndex: (self identificationGoal).

	i := 1.
	[ i <= max ]
	whileTrue: [

		ps := ProposedSolution new.
		ps status: (self status).
		ps solution: (aSortedPossibleSolutionsList removeFirst).

		((ps solution points) < 0) ifTrue: [ ps degreeOfCertainty: #uncertain ].
		((ps solution points) = 0) ifTrue: [ ps degreeOfCertainty: #doubtful ].
		((ps solution points) > 0) ifTrue: [ ps degreeOfCertainty: #certain ].

		psLevel := TaxonomicLevels transformToIndex: (ps solution level).

		"If applicable, insert the new proposed solution to the general solutions list"
		((psLevel < goalLevel) & ((self generalSolutions size) < (self maxNumberSolutions)))
		ifTrue: [ self generalSolutions: ps ].

		"If applicable, insert the new proposed solution to the goal solutions list"
		((psLevel = goalLevel) & ((self goalSolutions size) < (self maxNumberSolutions)))
		ifTrue: [ self goalSolutions: ps ].

		"If applicable, insert the new proposed solution to the specific solutions list"
		((psLevel > goalLevel) & ((self specificSolutions size) < (self maxNumberSolutions)))
		ifTrue: [ self specificSolutions: ps ].

		i := i + 1.

	].    "END [ i <= max ] whileTrue:"

	"Condition to stop the process: either the number of elements in either the specific or goal 
	 solutions lists is equal to maximum expected by the user, OR the sum of both lists satisfies
	 this user expectation"
	(((self goalSolutions size) = (self maxNumberSolutions)) |
	 ((self specificSolutions size) = (self maxNumberSolutions)) |
	 (((self goalSolutions size) + (self specificSolutions size)) >= (self maxNumberSolutions)))
	ifTrue: [ ^self ].

	"Try to load some more PossibleSolutions to the solutions lists"
	^(self distribute: aSortedPossibleSolutionsList).!

select

	"Driver method for this class. First, it calls method sortPossibleSolutions, in order to sort the possible 
	 solutions (by point score) of all eligible hypotheses included in the conflict sets. Next, the method 
	 distribute: is called, in order to distribute all sorted-out possible solutions into their corresponding 
	 solutions lists. Finally, an attempt is made to extract, from the goal-solutions list first, the number of 
	 proposed solutions that the user is willing to see.  If that list becomes empty, the specific-solutions 
	 list is used instead. Finally, if the specific-solutions list also becomes empty, the general-solutions 
	 list is used as last resort.

	 The solution lists are ordered by degree of certainty and by point score also. Hence, the first elements 
	 to be subtracted from each of the solutions lists are the best ones.

	Returns: an empty list, OR a list with THE BEST identification solutions."

	| i proposedSolutionsList solutions |

	proposedSolutionsList := (self sortPossibleSolutions).
	solutions := OrderedCollection new.

	(proposedSolutionsList isEmpty)
	ifTrue: [ ^solutions ].

	self distribute: proposedSolutionsList.

	i := 1.
	[ i <= (self maxNumberSolutions) ]
	whileTrue: [

		(self goalSolutions isEmpty)
		ifFalse: [ solutions add: (self goalSolutions removeFirst) ]
		ifTrue: [ 

			(self specificSolutions isEmpty)
			ifFalse: [ solutions add: (self specificSolutions removeFirst) ]

			ifTrue: [ 

				(self generalSolutions isEmpty)
				ifFalse: [ solutions add: (self generalSolutions removeFirst) ]
				ifTrue: [ i := (self maxNumberSolutions) ].

			].    "END (self specificSolutions isEmpty) ifTrue:"

		].    "END (self goalSolutions isEmpty) ifTrue:"

		i := i + 1.

	].    "END [ i <= (self maxNumberSolutions) ] whileTrue:"

	^solutions.!

sortPossibleSolutions

	"This method sorts possible solutions by their point scores.
	 Returns: a [possibly empty] sorted possible solutions list."

	| pSolutions hypothesis |

	"All possible solutions will be sorted by their point number: those with higher scores will 
	 be at the beginning of the list"
	pSolutions := SortedCollection new.
	pSolutions sortBlock: [ :x :y | (x points) >= (y points) ].

	"FIRST CHOICE: Load all successful (i.e., positive) structure possible solutions, if any"
	1 to: (self successfulStructConflictSet size) do:
	[:i |
		hypothesis := (self successfulStructConflictSet at: i).
		1 to: (hypothesis possibleSolutions size) do:
		[:j | pSolutions add: (hypothesis possibleSolutions at: j) ].
	].

	"SECOND CHOICE: Load all successful (i.e., positive) grouping heuristic possible solutions, if any"
	1 to: (self successfulGrpHeuristicConflictSet size) do:
	[:i |
		hypothesis := (self successfulGrpHeuristicConflictSet at: i).
		1 to: (hypothesis possibleSolutions size) do:
		[:j | pSolutions add: (hypothesis possibleSolutions at: j) ].
	].

	(pSolutions isEmpty)
	ifFalse: [ self status: #+. ^pSolutions ].

	"If the user wants to see failed solutions, *in case there aren't any positive solutions*, 
	  load them in the list"
	(self showFailedSolutions)
	ifTrue: [

		"Load all failed (i.e., negative) structure possible solutions, if any"
		1 to: (self failedStructConflictSet size) do:
		[:i |
			hypothesis := (self failedStructConflictSet at: i).
			1 to: (hypothesis possibleSolutions size) do:
			[:j | pSolutions add: (hypothesis possibleSolutions at: j) ].
		].

		"Load all failed (i.e., negative) grouping heuristic possible solutions, if any"
		1 to: (self failedGrpHeuristicConflictSet size) do:
		[:i |
			hypothesis := (self failedGrpHeuristicConflictSet at: i).
			1 to: (hypothesis possibleSolutions size) do:
			[:j | pSolutions add: (hypothesis possibleSolutions at: j) ].
		].

		(pSolutions isEmpty)
		ifFalse: [ self status: #- ].

	].    "END (self showFailedSolutions) ifTrue:"

	^pSolutions.! !

!PossibleSolutionSelector methodsFor: 'adding'!

generalSolutions: aProposedSolution

	generalSolutions add: aProposedSolution.
	^self.!

goalSolutions: aProposedSolution

	goalSolutions add: aProposedSolution.
	^self.!

specificSolutions: aProposedSolution

	specificSolutions add: aProposedSolution.
	^self.!

status: aStatusSymbol

	"The only possible values for this variable are:
		#+ (a positive PossibleSolution)
		#- (a negative PossibleSolution)
		#undefined"

	((aStatusSymbol = #undefined) |
	 (aStatusSymbol = #+) |
	 (aStatusSymbol = #-))
	ifFalse: [ ^nil ].

	status := aStatusSymbol.
	^self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PossibleSolutionSelector class
	instanceVariableNames: ''!


!PossibleSolutionSelector class methodsFor: 'instance creation'!

newWith: anIdentGoal and: aSuccSList and: aFailSList and: aSuccGHList and: aFailGHList and: aNumberOfSolutions and: showFailed

	| pse |

	pse := super new.
	pse initializeWith: anIdentGoal
			and: aSuccSList 
			and: aFailSList 
			and: aSuccGHList 
			and: aFailGHList 
			and: aNumberOfSolutions
			and: showFailed.
	^pse.! !

