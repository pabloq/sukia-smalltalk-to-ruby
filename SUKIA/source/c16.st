Object subclass: #GoalApproachingDialog
	instanceVariableNames: 'goal processList OKList hypothesis status taxonomy similarityRanges '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Search Automata'!
GoalApproachingDialog comment:
'Instances of this class are invoked when the search automatas have performed successfully (i.e., with at least one possible solution), but the taxonomic level of all the possible solutions is more general than the stated identification goal.  The purpose of this class is then, for each qualifying possible solution, establish a dialog with the user asking him/her questions about successor taxa of each solution, *all related to the descriptive element*.  As questions are positively answered, the corresponding taxon moves "one level down", approaching the stated goal.

This dialog stopswhen the user cancels, when all possible solutions have been processed but no positive "down-movement" was done, or when at least ONE taxon reaches the stated goal.'!


!GoalApproachingDialog methodsFor: 'accessing'!

goal

	^goal.!

hypothesis

	^hypothesis.!

OKList

	^OKList.!

processList

	^processList.!

similarityRanges

	^similarityRanges.!

status

	^status.!

taxonomy

	^taxonomy.! !

!GoalApproachingDialog methodsFor: 'dialog preparation'!

chat

	"The purpose of this method is to initially do all the administrative work necessary to select
	 those possible solutions (from the associated hypothesis) that are elegible for processing. 
	 That is, ONLY positive cases or Taxon instances will be processed. Once a possible solution 
	 is selected, it is placed in the processList.  Next, out of those previously filtered in, a second 
	 selection comes about: select only those (positive cases or taxa)  possible solutions whose 
	 taxonomic level is *closest to the stated identification goal*. These elements will remain in the 
	 processList; the rest will be filtered out.

	Precondition: the associated hypothesis MUST have at least one possible solution.

	Returns: nil - if the precondition fails, or a processing error occurred, or processList is empty.
			 value returned by doDialog."

	| ps taxon psLevelAsIndex goalAsIndex |

	"Check precondition"
	(self hypothesis possibleSolutions isEmpty)
	ifTrue: [ ^nil ].

	"Transform the stated identification goal to a numeric value"
	goalAsIndex := (TaxonomicLevels transformToIndex: (self goal)).

	"Scan the associated hypothesis possible solutions list"
	1 to: (self hypothesis possibleSolutions size) do:
	[:i |

		"Get the next possible solution"
		ps := (self hypothesis possibleSolutions) at: i.

		"Transform the possible solution level to a numeric value"
		psLevelAsIndex := (TaxonomicLevels transformToIndex: (ps level)).

		"If the possible solution's level is equal to, or more specific than the goal, ignore it"
		(psLevelAsIndex >= goalAsIndex) 
		ifFalse: [

			"If the possible solution is a taxon, place it in the process list. Else, it must be a case. Before placing 
			 the possible solution in the process list, find its corresponding taxon in the associated taxonomy"
			(ps solution class name = Taxon getClassName)
			ifTrue: [ self processList: ps ]
			ifFalse: [ 

				"If the taxon's status is positive, continue processing it. Else, ignore it"
				(ps solution status = #+)
				ifTrue: [

					"Solution is a positive case. Retrieve the corresponding taxon from the taxonomy"
					taxon := (self taxonomy getTaxonByName: (ps name) level: psLevelAsIndex).

					"If the taxon is not found, there is an error. Set ba tate of error and return"
					(taxon = nil) ifTrue: [ self status: #error. ^nil ].

					"Exchange the case for the taxon. Finally, place it in the process list"
					ps solution: taxon.
					self processList: ps.

				].    "END (ps solution status = #+) ifTrue:"

			].    "END (ps solution class name = Taxon getClassName) ifFalse:"

		].    "END (psLevelAsIndex >= goalAsIndex) ifFalse:"

	].    "END 1 to: (self hypothesis possibleSolutions size) do:"

	"If the process list ends up having zip, return fail status (default)"
	(self processList isEmpty) ifTrue: [ ^nil ].

	"At this point, processList contains a set of possible solutions whose level is more general than the
	 stated identificaction goal. Moreover, all solutions are taxa. Proceed to select those items whose
	 level is *closest* to the goal"
	self selectPossibleSolutionsNearestToGoal.

	^(self doDialog).!

doDialog

	| ps nextLevelTaxon structure attributeList attribute taxon valueList savDescriptor vd result OKSAVDescriptorList v displayValues returnValues |

	"Scan the processList"
	[ self processList isEmpty ]
	whileFalse: [

		"Remove the next possible solution"
		ps := (self processList removeFirst).

		"Get the next possible solution's taxon"
		taxon := ps solution.

		"Scan the taxon's successor list"
		1 to: (taxon successors size) do:
		[:i |

			"Get the next-level successor taxon"
			nextLevelTaxon := (taxon successors) at: i.

			"Get the related structure from the successor taxon's SAV description"
			structure := (nextLevelTaxon 
							getAnObjectWith: (self hypothesis descriptiveElement name) 
							in: (nextLevelTaxon SAVdescription)).

			(structure = nil)
			ifFalse: [

				"Get the attributes from the retrieved structure"
				attributeList := structure attributes.

				"Scan the attributes list"
				1 to: (attributeList size) do:
				[:j |

					"Get the next attribute"
					attribute := (attributeList at: j).

					"Make sure this attribute is not already processed (i.e., included in the solution or
					 confirmed descriptions of ANY item in the processList)"
					(self isAttributeAlreadyProcessed: attribute)
					ifFalse: [

						"Get the attribute's list of values"
						valueList := (attribute values) valueDescriptorsIn: (Attribute oneLevel).
						(valueList = nil) ifTrue: [ self status: #error. ^nil ].

						OKSAVDescriptorList := OrderedCollection new.
						displayValues := List new.
						returnValues := List new.

						"Scan the value descriptor list: valueList with range value descriptors: only ONE element.
						 valueList with non-range value descriptors: at least one element"
						1 to: (valueList size) do:
						[:k |

							"Get the next value descriptor"
							vd := (valueList at: k).

							"If the value decriptor is a range, do a range-driven dialog"
							(vd asRange)
							ifTrue: [ 

								[ OKSAVDescriptorList isEmpty ]
								whileFalse: [ OKSAVDescriptorList removeFirst ].

								result := (self rangeValueDescriptorDialogWith: vd attribute: attribute).
								(((result at: 1) = #cancel) | ((result at: 1) = #error)) ifTrue: [ self status: (result at: 1). ^nil ].

								((result at: 1) = #reject)
								ifTrue: [ ps unconfirmedDescription: (result at: 2)  ].

								((result at: 1) = #unmatch)
								ifTrue: [ self hypothesis unmatchedDescription: (result at: 2) ].

								"The user typed a value within the range. Thus result contains a SAVDescriptor
								 that can be used to update ps confirmedDescription. Additionally, assign
								 nextLevelTaxon to ps solution, and place ps in the OKList. Finally, do a recursive
								 call to doDialog, in order to process the next possible solution in processList"
								((result at: 1) = #confirm)
								ifTrue: [
									ps solution: nextLevelTaxon.
									ps confirmedDescription: (result at: 2). 
									self OKList: ps.
									^(self doDialog)
								].

							]    "END (vd asRange) ifTrue:"

							"(vd asRange)"
							ifFalse: [

								"Create a SAV descriptor for each [structure-attribute]-value"
								savDescriptor := SAVDescriptor new.
								savDescriptor 
									addStructure: (self hypothesis descriptiveElement name) 
									Attribute: (attribute name) 
									Value: (vd value).

								"Make sure the SAV descriptor is not already processed (i.e., included in the unconfirmed,
								 doubtful, or unmatched descriptions of ANY item in the processList. The reason for this 
								 check is to avoid asking the user questions previously answered"
								(self isDescriptorAlreadyProcessed: savDescriptor)
								ifFalse: [

									"For the new descriptor's value, make sure its degree of similarity (with respect to 
									 the attribute's typical value) is acceptable. If it isn't, ignore it"
									((self determineSimilarityFor: savDescriptor context: nextLevelTaxon) = nil)
									ifFalse: [

										"Place the SAV descriptor value in the Array that will be displayed"
										((savDescriptor value) respondsToArithmetic)
										ifTrue: [ v := (savDescriptor value) printString ]
										ifFalse: [ v := (savDescriptor value) asString ].
										displayValues add: v.
										returnValues add: (savDescriptor value).

										"Place the descriptor is a separate descriptor list. Process the next value"
										OKSAVDescriptorList add: savDescriptor.

									].    "END ((self determineSimilarityFor: ...) = nil) ifFalse:"

								].    "END (self isDescriptorAlreadyProcessed: savDescriptor) ifFalse:"

							].    "END (vd asRange) ifFalse:"

						].    "END 1 to: (valueList size) do:"

						"Once all of the attribute's values have been processed, the number of items in the 
						 display array MUST be equal to the number of descriptors in the descriptor list. If 
						 such number is greater than zero, display the dialog"
						(OKSAVDescriptorList isEmpty)
						ifFalse: [

							result := (self valueDescriptorDialogWith: displayValues 
										returnValueList: returnValues 
										attribute: attribute).

							"User rejects. Flush the descriptor list by placing all SAVDescriptors in the unconfirmed 
							 description. Continue processing the next attribute"
							(result = #reject) 
							ifTrue: [
								[OKSAVDescriptorList isEmpty] 
								whileFalse: [ ps unconfirmedDescription: (OKSAVDescriptorList removeFirst) ]
							].

							"User is in doubt. Flush the descriptor list by placing all SAVDescriptors in the doubtful 
							 description. Continue processing the next attribute"
							(result = #doubt) 
							ifTrue: [
								[OKSAVDescriptorList isEmpty] 
								whileFalse: [ ps doubtfulDescription: (OKSAVDescriptorList removeFirst) ]
							].

							"User cancels. Cancel the process and exit."
							(result = #cancel) ifTrue: [ self status: #cancel. ^nil ].

							"User selects one item. The dialog method returns the value included in a SAVDescriptor. 
							 Assign nextLevelTaxon to ps solution. Place ps in the OKList. Call doDialog recursively"
							(result class name = SAVDescriptor getClassName)
							ifTrue: [ 
								ps solution: nextLevelTaxon.
								ps confirmedDescription: result. 
								self OKList: ps.
								^(self doDialog)
							].

						].    "END (OKSAVDescriptorList isEmpty) ifFalse:"

					].    "END (self isAttributeAlreadyProcessed: attribute) ifFalse:"

				].    "END 1 to: (attributeList size) do:"

			].    "END (structure = nil) ifFalse:"

		].    "END 1 to (taxon successors) do:"

	].    "END [ self processList isEmpty ] whileFalse:"

	"At this point, all of the possible solutions have been processed. If the OKList is NOT empty, all the elements now 
	 included in it have advanced one level with respect to the original ps solution. If the If the FIRST possible solution's 
	 level meets the goal, exit successfully. Else, copy everything back to the processList and call doDialog again. The
	 return value is whatever this new call returns"
	(self OKList isEmpty)
	ifFalse: [

		((self goal) = (self OKList first) level)
		ifTrue: [ self status: #success. ^self ].

		[ self OKList isEmpty ]
		whileFalse: [ self processList: (self OKList) removeFirst ].
		^(self doDialog).

	].    "END (self OKList isEmpty) ifFalse:"

	^nil.!

selectPossibleSolutionsNearestToGoal

	"The instance list variable processList contains possible solutions ordered by level. Furthermore, only 
	 possible solutions whose level is more general than the stated goal are included in this list. The idea
	 of this method is to select those items whose level is *nearest* to the goal, that is, those items whose
	 level is equal to the level of the first item.

	 Precondition: processList is NOT empty"

	| level i |

	"Check precondition"
	(self processList isEmpty)
	ifTrue: [ ^nil ].

	"If the processList contains only one element, there's nothing to do"
	((self processList size) = 1)
	ifTrue: [ ^self ].

	"Get the level of the first element"
	level := (self processList first) level.

	"Starting with the second element, process the list"
	i := 2.
	[ i <= (self processList size) ]
	whileTrue: [

		(level = ((self processList) at: i) level)
		ifTrue: [ i := i + 1 ]
		ifFalse: [ (self processList) removeAtIndex: i ].

	].    "END [ i <= (self processList size) ] whileTrue:"

	^self.! !

!GoalApproachingDialog methodsFor: 'dialog display'!

rangeValueDescriptorDialogWith: vd attribute: anAttribute

	| msg suggestedValue result d value returnValues |

	returnValues := OrderedCollection new.

	msg :=	'Estructura: ' , (self hypothesis descriptiveElement name) , 
			'.\Por favor digite un valor en ' , (vd measuringUnit) ,
			'\para el atributo: ' , (anAttribute name) ,
			'.\\Si no es posible proveer la respuesta,\deje el campo en blanco ' ,
			'y haga click\en OK.'.

	suggestedValue := (((vd lowerBound) + (vd upperBound)) / 2) asFloat.

	result := (SukiaDialog
				request: msg withCRs
				initialAnswer: (suggestedValue printString)
				for: SukiaDialog defaultParentWindow).

	(result = #cancel)
	ifTrue: [ 
		returnValues add: #cancel. 
		returnValues add: nil. 
		^returnValues
	].

	(result = '')
	ifTrue: [
		d := SAVDescriptor new.
		d addStructure: (self hypothesis descriptiveElement name) 
	   		Attribute: (anAttribute name) 
	   		Value: suggestedValue.
		returnValues add: #reject.
		returnValues add: d.
		^returnValues.
	].

	value := (result asNumber).
	d := SAVDescriptor new.
	d addStructure: (self hypothesis descriptiveElement name) 
		Attribute: (anAttribute name) 
		Value: value.
	
	((value >= (vd lowerBound)) & (value <= (vd upperBound)))
	ifTrue: [ returnValues add: #confirm ]
	ifFalse: [ returnValues add: #unmatch ].

	returnValues add: d.
	^returnValues.!

valueDescriptorDialogWith: displayValues returnValueList: returnValues attribute: anAttribute

	| msg result d |

	msg :=	'Presenta el atributo ' , 
			(anAttribute name) , 
			'\de la estructura: ' , 
			(self hypothesis descriptiveElement name) , 
			'\uno de los siguientes valores?'.

	result := (SukiaDialog
				choose: msg
				fromList: displayValues 
				values: returnValues 
				lines: 8
				for: SukiaDialog defaultParentWindow).

	((result = #reject) | (result = #doubt) | (result = #cancel))
	ifTrue: [ ^result ].

	d := SAVDescriptor new.
	d addStructure: (self hypothesis descriptiveElement name) 
	   Attribute: (anAttribute name) 
	   Value: result.
	^d.! !

!GoalApproachingDialog methodsFor: 'initializing'!

initializeGoal: aGoal hypothesis: aHypothesis taxonomy: aTaxonomy similarityRanges: simRangesList

	| sb | 

	"The argument aGoal MUST be a value valid for TaxonomicLevels (e.g., #genus)"
	goal := aGoal.

	"The elements of simrangesList MUST be defined in SimRanges"
	similarityRanges := simRangesList.

	hypothesis := aHypothesis.
	taxonomy := aTaxonomy.

	"The instance variable status indicates the search status at the end of the process.
	 The possible values it may have are: 
	#fail - the dialog was unsuccessful. This is the default value.
	#success - at least one taxon reached the goal.
	#cancel - the user canceled the dialog process.
	#error - a processing error occurred."
	self status: #fail.

	sb := [:x :y | 
			(TaxonomicLevels transformToIndex: (x level)) >=
			(TaxonomicLevels transformToIndex: (y level)) ].

	"This list must contain zero or more instances of PossibleSolution"
	processList := SortedCollection new.
	processList sortBlock: sb.

	"This list must contain zero or more instances of PossibleSolution"
	OKList := SortedCollection new.
	OKList sortBlock: sb.		

	^self.! !

!GoalApproachingDialog methodsFor: 'adding'!

OKList: aPossibleSolution

	OKList add: aPossibleSolution.
	^self.!

processList: aPossibleSolution

	processList add: aPossibleSolution.
	^self.!

status: aStatusValue

	"The instance variable status indicates the search status at the end of the process.
	 The possible values it may have are: 
	#fail - the dialog was unsuccessful. This is the default value.
	#success - at least one taxon reached the goal.
	#cancel - the user canceled the dialog process.
	#error - a processing error occurred."
	status := aStatusValue.
	^self.! !

!GoalApproachingDialog methodsFor: 'testing'!

determineSimilarityFor: aSAVDescriptor context: aTaxon

	"Determines the similarity range between aSAVDescriptor's value and aTaxon's value
	 weight list.  If there exists a range of similarity, it is checked against the accepted 
	 ranges.

	 Returns: nil : if there is no similarity.
			  aTaxon : if there was an acceptable degree of similarity."

	| weightedValues similarity |

	weightedValues := 
		(((aTaxon getAnObjectWith: (aSAVDescriptor structure) in: (aTaxon SAVdescription))
		   attributeWith: (aSAVDescriptor attribute)) values at: (Attribute oneLevel)).

	similarity := SimAssessor similarityRangeOf: (aSAVDescriptor value) in: weightedValues.
	(self similarityRanges includes: similarity) ifFalse: [ ^nil ].

	^aTaxon.!

isAttributeAlreadyProcessed: anAttribute

	| d ps |

	d := SAVDescriptor new.
	d addStructure: (self hypothesis descriptiveElement name) Attribute: (anAttribute name) Value: nil.

	1 to: (self hypothesis possibleSolutions size) do:
	[:i |

		ps := (self hypothesis possibleSolutions at: i).

		((ps includes: d in: (ps solutionDescription)) = nil)
		ifFalse: [ ^true ].

		((ps includes: d in: (ps confirmedDescription)) = nil)
		ifFalse: [ ^true ].

	].    "END 1 to: (self hypothesis possibleSolutions size) do:"

	^false.!

isDescriptorAlreadyProcessed: aSAVDescriptor

	| ps |

	((self hypothesis includesFull: aSAVDescriptor in: (self hypothesis unmatchedDescription)) = nil)
	ifFalse: [ ^true ].

	1 to: (self hypothesis possibleSolutions size) do:
	[:i |

		ps := (self hypothesis possibleSolutions at: i).

		((ps includesFull: aSAVDescriptor in: (ps unconfirmedDescription)) = nil)
		ifFalse: [ ^true ].

		((ps includesFull: aSAVDescriptor in: (ps doubtfulDescription)) = nil)
		ifFalse: [ ^true ].

	].    "END 1 to: (self hypothesis possibleSolutions size) do:"

	^false.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

GoalApproachingDialog class
	instanceVariableNames: ''!


!GoalApproachingDialog class methodsFor: 'instance creation'!

newWithGoal: aGoal hypothesis: aHypothesis taxonomy: aTaxonomy similarityRanges: simRangesList

	| gad |

	"Make sure the hypothesis descriptive element is a structure"
	((aHypothesis descriptiveElement) class name = (Structure getClassName))
	ifFalse: [ ^nil ].

	gad := super new.
	gad initializeGoal: aGoal hypothesis: aHypothesis taxonomy: aTaxonomy similarityRanges: simRangesList.
	^gad.! !

Object subclass: #TaxonSearchAutomaton
	instanceVariableNames: 'searchIndex valueDescriptors taxonList tSolutionDesc tUnmatchedDesc justification searchOutput status '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Search Automata'!


!TaxonSearchAutomaton methodsFor: 'initializing'!

initialize

	self newOutput.

	"taxonList: list of [Taxon] possible solutions, ordered by taxonomic level: from the most
	 specific level the the most general. The main reason is that the method self compress checks
	 for hierarchy (using Taxon isSuccessorOf), and temporarily removes items from taxonList. So,
	 it's convenient to process the most specific taxa first"
	taxonList := SortedCollection new.
	taxonList sortBlock: [ :x :y | 
							(TaxonomicLevels transformToIndex: (x level)) >=
							(TaxonomicLevels transformToIndex: (y level)) ].

	valueDescriptors := OrderedCollection new.
	tSolutionDesc := OrderedCollection new.
	tUnmatchedDesc := OrderedCollection new.
	justification := OrderedCollection new.

	"The instance variable status indicates the search status at the end of the process.
	 The possible values it may have are: 
	#fail - the search was unsuccessful. This is the default value.
	#success - at least one possible solution was found.
	#cancel - the user canceled the search process.
	#error - a processing error occurred."
	self status: #fail.

	^self.!

newOutput

	^(searchOutput := TaxonAutomatonOutput new).! !

!TaxonSearchAutomaton methodsFor: 'adding'!

status: aStatusValue

	"The possible values for the argument aStatusValue are:
	#fail - the search was unsuccessful. This is the default value.
	#success - at least one possible solution was found.
	#cancel - the user canceled the search process.
	#error - a processing error occurred."

	status := aStatusValue.
	^self.!

taxonList: aTaxon

	taxonList add: aTaxon.
	^self.!

tSolutionDescription: aSAVDescriptor

	"Automaton reference: AtS"

	((self includes: aSAVDescriptor in: (self tSolutionDescription)) = nil)
	ifFalse: [ ^self ].

	tSolutionDesc add: aSAVDescriptor.
	^self.!

tUnmatchedDescription: aSAVDescriptor

	"Automaton reference: AtUMD"

	((self includes: aSAVDescriptor in: (self tUnmatchedDescription)) = nil)
	ifFalse: [ ^self ].

	tUnmatchedDesc add: aSAVDescriptor.
	^self.!

valueDescriptors: aValueDescriptorList

	[ aValueDescriptorList isEmpty ]
	whileFalse: [ valueDescriptors add: (aValueDescriptorList removeFirst) ].
	
	^self.! !

!TaxonSearchAutomaton methodsFor: 'accessing'!

justification 

	^justification.!

searchIndex 

	^searchIndex.!

searchOutput 

	^searchOutput.!

status

	^status.!

taxonList 

	^taxonList.!

tSolutionDescription

	^tSolutionDesc.!

tUnmatchedDescription

	^tUnmatchedDesc.!

valueDescriptors 

	^valueDescriptors.! !

!TaxonSearchAutomaton methodsFor: 'private'!

associateTaxaToPossibleSolutions: aTaxonList

	"This method is used in conjuntion with prepareSuccessfulOutput.  The purpose
	 of this method is to create an instance of PossibleSolution for every taxon in the
	 list argument aTaxonList.

	Returns: a list of PossibleSolutions.

	 Automaton reference: none."

	| ps psList |

	psList := OrderedCollection new.

	1 to: (aTaxonList size) do:
	[ :i |
		ps := PossibleSolution new.
		ps solution: (aTaxonList at: i).
		ps copy: (self tSolutionDescription) to: (ps solutionDescription).
		psList add: ps.
	].

	^psList.!

checkPrecondition: aProblemDescription

	"beginWith Check:
	 1. aProblemDescription is a non-empty set of SAVDescriptors.
	 2. For all s1, s2::SAVDescriptor in aProblemDescription : (s1 structure) = (s2 structure).

	Returns: self - OK.
			  nil - Precondition failed."

	| sName |

	"Check part 1. of precondition"
	(aProblemDescription isEmpty)
	ifTrue: [ ^nil ].

	"Check part 2. of precondition"
	(aProblemDescription at: 1) class name = (SAVDescriptor getClassName)
	ifFalse: [ ^nil ].

	"Get the structure name of the first descriptor"
	sName := (aProblemDescription at: 1) structure.

	"Check the precondition for the rest of the elements"
	((aProblemDescription size) > 1)
	ifTrue: [
		2 to: (aProblemDescription size) do:
		[:i | 
			((aProblemDescription at: i) class name = (SAVDescriptor getClassName)) ifFalse: [ ^nil ].
		      (sName = ((aProblemDescription at: i) structure)) ifFalse: [ ^nil ] ].
	].

	^self.!

prepareFailedOutput

	"This method is called from beginWith, and is executed whenn the automaton has failed to provide 
	 a solution for the given problem description.

	 Automaton reference: PFO"

	((self searchOutput) justification = nil)
	ifFalse: [ ^self ].

	(self searchOutput) justification: (self justification).
	(self searchOutput) unmatchedDescription: (self tUnmatchedDescription).
	^self.!

prepareSuccessfulOutputWith: aPossibleSolutionsList
 
	"Automaton reference: PSO"

	(((self searchOutput) possibleSolutions) = nil)
	ifFalse: [ ^self ].

	(self searchOutput) possibleSolutions: aPossibleSolutionsList.
	(self searchOutput) justification: (self justification).
	(self searchOutput) unmatchedDescription: (self tUnmatchedDescription).
	self status: #success.
	^self.!

resetList: anOrderedCollection

	[ anOrderedCollection isEmpty ]
	whileFalse: [ anOrderedCollection removeFirst ].

	^self.!

searchIndex: aSearchIndex

	searchIndex := aSearchIndex.
	^self.! !

!TaxonSearchAutomaton methodsFor: 'testing'!

includes: aSAVDescriptor in: aDescription

	"Determines if aSAVDescriptor is already a member of aDescriptionList. The argument aSAVDescriptor is a member of 
	aDescriptionList when its structure name, its attribute name, and its value match with the structure, attribute, and value 
	of a list element.
	Returns: 	-1 (error state): The argument aDescriptionList IS NOT a valid list for self.
				nil: aSAVDescriptor IS NOT a member of aDescriptionList.
				not nil: an element of aDescriptionList whose structure and attribute names match those of aSAVDescriptor"

	| d |

	"First step: make sure that the process is executed against one of my lists"
	((aDescription = (self tSolutionDescription)) | 
	(aDescription = (self tUnmatchedDescription)))
	ifFalse: [ ^(-1) ].

	1 to: (aDescription size) do:
	[:i |
		d := aDescription at: i.

		((d structure = aSAVDescriptor structure) & (d attribute = aSAVDescriptor attribute) & (d value = aSAVDescriptor value))
		ifTrue: [ ^d ].
	].

	^nil.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TaxonSearchAutomaton class
	instanceVariableNames: ''!


!TaxonSearchAutomaton class methodsFor: 'instance creation'!

new

	| automaton |

	automaton := super new.
	automaton initialize.
	^automaton.! !

Object subclass: #SAVCaseDFSAutomaton
	instanceVariableNames: 'netRoot currentNorm currentLevel stopLevel tSolutionDesc tConfirmedDesc tUnconfirmedDesc tDoubtfulDesc tUnmatchedDesc justification searchOutput status '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Search Automata'!
SAVCaseDFSAutomaton comment:
'SAVCase Depth-First-Search Automaton.
1. The search process is based on a problem description composed of a non-empty set of SAVDescriptors.
2. The search strategy is depth-first. That is, using all possible SAVDescriptors from the problem description, advance as 
	deep as possible within the Case Memory, before selecting solution cases.  This strategy ensures that all descriptors
	are considered.'!


!SAVCaseDFSAutomaton methodsFor: 'initializing'!

initializeWith: aSAVRoot

	netRoot := aSAVRoot.
	self currentNorm: nil.

	self resetLevel.
	self stopLevel: self currentLevel.

	tSolutionDesc := OrderedCollection new.
	tConfirmedDesc := OrderedCollection new.
	tUnconfirmedDesc := OrderedCollection new.
	tDoubtfulDesc := OrderedCollection new.
	tUnmatchedDesc := OrderedCollection new.
	justification := OrderedCollection new.
	self newOutput.

	"The instance variable status indicates the search status at the end of the process.
	 The possible values it may have are: 
	#fail - the search was unsuccessful. This is the default value.
	#success - at least one possible solution was found.
	#cancel - the user canceled the search process.
	#error - a processing error occurred."
	self status: #fail.

	^self.!

newOutput

	^(searchOutput := DFSAutomatonOutput new).! !

!SAVCaseDFSAutomaton methodsFor: 'adding'!

currentNorm: aNorm

	"Automaton reference: CN"

	currentNorm := aNorm.
	^self.!

justification: aJustificationElement

	justification add: aJustificationElement.
	^self.!

nextLevel

	currentLevel := currentLevel + 1.
	^self.!

previousLevel

	currentLevel := currentLevel - 1.
	^self.!

resetLevel

	currentLevel := 0.
	^self.!

status: aStatusValue

	"The possible values for the argument aStatusValue are:
	#fail - the search was unsuccessful. This is the default value.
	#success - at least one possible solution was found.
	#cancel - the user canceled the search process.
	#error - a processing error occurred."

	status := aStatusValue.
	^self.!

stopLevel: aLevelNumber

	stopLevel := aLevelNumber.
	^self.!

tConfirmedDescription: aSAVDescriptor

	"Automaton reference: AtCD"

	tConfirmedDesc add: aSAVDescriptor.
	^self.!

tDoubtfulDescription: aSAVDescriptor

	"Automaton reference: AtDD"

	tDoubtfulDesc add: aSAVDescriptor.
	^self.!

tSolutionDescription: aSAVDescriptor

	"Automaton reference: AtSD"

	tSolutionDesc add: aSAVDescriptor.
	^self.!

tUnconfirmedDescription: aSAVDescriptor

	"Automaton reference: AtUD"

	tUnconfirmedDesc add: aSAVDescriptor.
	^self.!

tUnmatchedDescription: aSAVDescriptor

	"Automaton reference: AtUMD"

	tUnmatchedDesc add: aSAVDescriptor.
	^self.! !

!SAVCaseDFSAutomaton methodsFor: 'accessing'!

currentLevel

	^currentLevel.!

currentNorm 

	^currentNorm.!

justification 

	^justification.!

netRoot

	^netRoot.!

rootLevel

	^1.!

searchOutput

	^searchOutput.!

status

	^status.!

stopLevel

	^stopLevel.!

tConfirmedDescription

	^tConfirmedDesc.!

tDoubtfulDescription

	^tDoubtfulDesc.!

tSolutionDescription

	^tSolutionDesc.!

tUnconfirmedDescription

	^tUnconfirmedDesc.!

tUnmatchedDescription

	^tUnmatchedDesc.! !

!SAVCaseDFSAutomaton methodsFor: 'backtracking'!

backtrack

	"A backtrack operation consists of moving up a norm, in order to present the user
	 with that norm's indices.  During a backtrack operation, the descriptor that corresponds
	 to the current norm is extracted from the confirmed list, and placed in the unconfirmed
	 list.  The reason for this action is that such descriptor was once confirmed, and now the
	 user 'states' that it's no good.

	 Returns: - nil - if the backtracking process fails, or indexDialog returns nil,
			   self - if indexDialog returns self after a successful backtrack.

	 Automaton reference: BkTk"

	((self removeSAVDescriptorFromTConfirmedDesc: (self currentNorm)) = nil)
	ifTrue: [self prepareFailedOutput. ^nil. ].

	((self processPreviousNorm) = nil)
	ifTrue: [ self prepareFailedOutput. ^nil. ].

	^(self indexDialog).!

processPreviousNorm

	"Moves up a norm. This operation fails if an attempt is made to move 
	 farther up than the stop-level norm, or if control is already at the net
	 root.  If all goes well, an index verification is performed on the norm.

	Returns: nil - if the process fails;
			self - if everything dandy.

	Automaton reference: PPN"

	| r |

	self currentNorm: (self currentNorm predecessor).
	self previousLevel.
	((self currentLevel < self stopLevel) | (self currentNorm = self netRoot))
	ifTrue: [ ^nil ].

	r := self verifyIndices.
	(r = nil) ifTrue: [ ^nil ].
	(r = #backtrack) ifTrue: [ ^(self processPreviousNorm) ].

	^self.!

removeSAVDescriptorFromTConfirmedDesc: aNorm

	"Removes, from tConfirmedDescription, a SAVDescriptor that matches aNorm's attribute
	 and value.  The removed SAVDescriptor is placed in the tUnconfirmedDescription.

	 Returns: nil - if the aNorm's level (i.e., currentLevel) is the less than or equal to the stopLevel,
				   or if the SAVDescriptor was not found in tConfirmedDescriptor;
			  self - if all OK.

	 Automaton reference: RtCD"

	(self currentLevel <= self stopLevel)
	ifTrue: [ ^nil ].

	1 to: (self tConfirmedDescription size) do:
	[:i |
		((((self tConfirmedDescription) at: i) attribute = (aNorm descriptor) attribute) & 
		 (((self tConfirmedDescription) at: i) value = (aNorm descriptor) value))
		ifTrue: [ self tUnconfirmedDescription: ((self tConfirmedDescription) removeAtIndex: i). ^self ].
	].

	^nil.!

verifyIndices

	"This method is called during the backtracking process.  The purpose here is to determine if there is at least
	 one index to show to the user, hence continuing with the dialog. All of the current norm's successors are
	 scanned. As a reminder, at this point all of the current norm's successors must be indices. For every retrieved 
	 index, all its index values should be checked against the unconfirmed or doubtful descriptions. If at least ONE 
	 index value is not a member of either list, the dialog with the user may continue in the context of the current norm. 
	 Else, a new backtrack operation should be performed.

	NOTE: The possibility of finding successor cases for the current norm is discarded, because successor cases have 
	already been searched for by the method retrieveCasesUnderNorm.

	Returns: 
		self - if at least one index value (in the form of a SAVDescriptor) is not member of either the the unconfirmed 
			  or doubtful lists;
		nil - if removeSAVDescriptorFromTConfirmedDesc: returns nil;
		#backtrack - if a new bactrack operation should be performed.

	 Automaton reference: VIdx"

	| normSucc idxSucc d |

	"Scan the list of successors for the current norm"
	1 to: (self currentNorm successors) size do:
	[:i |
		"Get the next successor. It's got to be an index!!!!"
		normSucc := (self currentNorm successors) at: i.

		"Get its list of successors (i.e., IndexValues)"
		idxSucc := normSucc successors.

		"Scan the list of successors for the current index"
		1 to: idxSucc size do:
		[:j |
			"Create a SAVDescriptor"
			d := SAVDescriptor new.
			d addStructure: (self netRoot structure) Attribute: (normSucc label) Value: (idxSucc at: j) value.

			"If the SAVDescriptor is not a member of the unconfirmed description, check it against
			 the doubtful description. If this time the SAVDescriptior is NOT a member of the doubtful
			 description, return self, indicating that there is at least one index-value to show to the user"
			((self includes: d in: (self tUnconfirmedDescription)) = nil)
			ifTrue: [
				((self includes: d in: (self tDoubtfulDescription)) = nil)
				ifTrue: [ ^self. ].

			].    "END (self includes: d in: (self tUnconfirmedDescription) = nil) ifTrue:"

		].    "END 1 to: idxSucc size do:"

	].    "END 1 to: (self currentNorm successors) size do:"

	"At this point, the entire list of norm successors was scanned, and all of them were members
	 of either the unconfirmed or doubtful descriptions. Return nil to indicate that another backtrack 
	 must be performed. Before returning, the descriptor of the current norm must be removed from
	 the confirmed description and placed in the unconfirmed description"
	(self removeSAVDescriptorFromTConfirmedDesc: (self currentNorm)) = nil
	ifTrue: [ ^nil ].

	^#backtrack.! !

!SAVCaseDFSAutomaton methodsFor: 'case-pointing search'!

searchForCasesUnderCurrNormUsing: aProblemDescription saveIn: aPossibleSolutionsList

	"This method searches for indices, strictly under a norm other than the net root, that point to cases. If a Descriptor in
	 the argument list aProblemDescription matches one such index, it is placed in the solution description. If a Descriptor 
	 matches an index that points to a Norm, it will remain in aProblemDescription. If a Descriptor does not match any index, 
	 it will also remain in aProblemDescription.

	 Returns:	self : if the process ran OK;
				#cancel : is the user cancels.
				-1 : error value, if the precondition is not met.

	 PRECONDITION: 
	(aProblemDescription isEmpty not) and (self currentNorm !!= self netRoot not) and (aPossibleSolutionsList isEmpty)"

	| d idx succ tempList pSolutionList result |

	"Check precondition"
	((aProblemDescription isEmpty) | (self currentNorm = self netRoot) | ((aPossibleSolutionsList isEmpty) not))
	ifTrue: [ ^-1 ].

	"Create the temporary process lists"
	tempList := OrderedCollection new.
	pSolutionList := OrderedCollection new.

	"Scan the the Descriptor list of the problem description. Look for indices that strictly point to cases"
	[ aProblemDescription isEmpty ]
	whileFalse: [

		"Remove the next SAVDescriptor"
		d := aProblemDescription removeFirst.

		"Look for a matching index"
		idx := (self currentNorm) getIndexWith: d attribute and: d value.

		"If the descriptor did not match any index, take it out of the problem description and 
		 place it in the temporary list"
		(idx = nil)
		ifTrue: [
			"The descriptor may have an inaccurate value. Try to establish a dialog with the user."
			result := self searchCasesDialogUsing: d saveIn: aPossibleSolutionsList.
			(result = #cancel) ifTrue: [ ^#cancel. ].
			(result = #fail) | (result = #idxNotFound) ifTrue: [ tempList add: d ].
			(result = #success) ifTrue: [ self tUnmatchedDescription: d ].
		]
		ifFalse: [

			"Index found. Get the IndexValue successor"
			succ := ((idx getIndexValueWith: d value) successors) at: 1.

			"If a matched index points to a Norm, don't process it. Place the descriptor in a temporary list"
			(succ class name = Norm getClassName)
			ifTrue: [ tempList add: d ]
			ifFalse: [ 

				"The matched index points to a case. Place the corresponding descriptor in the solution description
		 		 and associate the corresponding case to a PossibleSolution. Next, place the possible solution in the
		 		output possible solutions list. Finally, remove the descriptor from the solution description"
				self tSolutionDescription: d.
				pSolutionList add: succ.
				pSolutionList := (self associateCasesToPossibleSolutions: pSolutionList).
				aPossibleSolutionsList add: (pSolutionList removeFirst).
				self tSolutionDescription removeLast.

			]    "END (succ class name = Norm getClassName) ifFalse:"

		].    "END (idx = nil) ifFalse:"

	].    "END [ aProblemDescription isEmpty ] whileFalse:"

	"Put the descriptors that didn't match indices back in the problem description list"
	[ tempList isEmpty ]
	whileFalse: [ aProblemDescription add: (tempList removeFirst) ].

	^self.!

searchForCasesUnderRootUsing: aProblemDescription saveIn: aPossibleSolutionsList

	"This method searches for indices, strictly under the net root, that point to cases. If a Descriptor in
	 the argument list aProblemDescription matches one such index, it is placed in the solution description.
	 If a Descriptor matches an index that points to a Norm, it will remain in aProblemDescription. If a Descriptor
	 does not match any index, it will be placed in the unmatched descriptor list.

	 Returns: self : if the process ran OK;
			   #cancel : is the user cancels.
			     -1 : error value, if the precondition is not met.

	 PRECONDITION: 
	(aProblemDescription isEmpty not) and (self currentNorm = self netRoot) and
	(aPossibleSolutionsList isEmpty) and  (tSolutionDescription isEmpty)"

	| d idx succ tempList pSolutionList result |

	"Check precondition"
	(aProblemDescription isEmpty)
	ifTrue: [ ^-1 ].
	(((self currentNorm = self netRoot) & (aPossibleSolutionsList isEmpty) & (self tSolutionDescription isEmpty)) not)
	ifTrue: [ ^-1 ].

	"Create the temporary process lists"
	tempList := OrderedCollection new.
	pSolutionList := OrderedCollection new.

	"Scan the the Descriptor list of the problem description. Look for indices that strictly point to cases"
	[ aProblemDescription isEmpty ]
	whileFalse: [

		"Remove the next SAVDescriptor"
		d := aProblemDescription removeFirst.

		"Look for a matching index"
		idx := (self currentNorm) getIndexWith: d attribute and: d value.

		"If the descriptor did not match any index, take it out of the problem description and 
		 place it in the unmatched descriptor list"
		(idx = nil)
		ifTrue: [ 

			"At this point, the descriptor inevitably goes to the unmatched description"
			self tUnmatchedDescription: d.

			"However, the descriptor may have an inaccurate value. Try to establish a dialog with the user
			 using a partial match."
			result := self searchCasesDialogUsing: d saveIn: aPossibleSolutionsList.
			(result = #cancel) ifTrue: [ ^#cancel ].
		]
		ifFalse: [

			"Index found. Get the IndexValue successor"
			succ := ((idx getIndexValueWith: d value) successors) at: 1.

			"If a matched index points to a Norm, don't process it. Place the descriptor in a temporary list"
			(succ class name = Norm getClassName)
			ifTrue: [ tempList add: d ]
			ifFalse: [ 

				"The matched index points to a case. Place the corresponding descriptor in the solution description
		 		 and associate the corresponding case to a PossibleSolution. Next, place the possible solution in the
		 		output possible solutions list. Finally, remove the descriptor from the solution description"
				self tSolutionDescription: d.
				pSolutionList add: succ.
				pSolutionList := (self associateCasesToPossibleSolutions: pSolutionList).
				aPossibleSolutionsList add: (pSolutionList removeFirst).
				self tSolutionDescription removeFirst.

			]    "END (succ class name = Norm getClassName) ifFalse:"

		].    "END (idx = nil) ifFalse:"

	].    "END [ aProblemDescription isEmpty ] whileFalse:"

	"Put the descriptors that match Norms back in the problem description list"
	[ tempList isEmpty ]
	whileFalse: [ aProblemDescription add: (tempList removeFirst) ].

	^self.!

searchForCasesUsing: aProblemDescription

	"At this point, the problem description still contains descriptors, and control is located either at a norm within
	 the net, or still at the root.  The purpose of this method is to use those descriptors to find matching indices 
	 that strictly point to cases

	 Returns: nil - if the process failed to find cases, or there was a processing error, or the user cancels;
			self - if at least ONE case was found.

	 Automaton reference: SCW"

	| savNorm savLevel possibleSolutions pSolutions tempDeleteSolution tempDeleteConfirmed result |

	"If the argument search-list is empty, something wrong happened. Return error value"
	(aProblemDescription isEmpty)
	ifTrue: [ self prepareFailedOutput. self status: #error. ^nil. ].

	"Make sure the current level is ALWAYS greater than or equal to the root level"
	(self currentLevel < self rootLevel)
	ifTrue: [ self prepareFailedOutput. self status: #error. ^nil. ].

	possibleSolutions := OrderedCollection new.

	"Check if control is located at the root (i.e., no Norm was ever found in the previous state)"
	(self currentLevel = self rootLevel)
	ifTrue: [
		"Search for cases pointed to by indices directly under the root. If there are any, the argument
		list possibleSolutions will not be empty"

		result := self searchForCasesUnderRootUsing: aProblemDescription saveIn: possibleSolutions.
		(result = #cancel) ifTrue: [ self prepareFailedOutput. self status: #cancel. ^nil ].
		(result = -1) ifTrue: [ self prepareFailedOutput. self status: #error. ^nil. ].

		"If the possible solutions list has at least one item, return self along  with whatever Descriptors 
		 remained in the problem description. This guarantees that all left-over Descriptors point to Norms"
		(possibleSolutions isEmpty)
		ifFalse: [ ^(self prepareSuccessfulOutputWith: possibleSolutions) ].

		"If the case list is empty, either the problem description has all descriptors that point to Norms 
		 in other paths, OR all descriptors are located in the unmatched list. Return nil"
		self prepareFailedOutput. 
		^nil.
 	].

	"At this point, control is located on a Norm other than the net root. Initially, scan the Descriptor list in search of indices 
	 that strictly point to cases. If a matched index points to a case, remove the corresponding Descriptor from the problem
	 description and place it in the solution description.  Next, associate the retrieved case to a PossibleSolution, and place
	 this possible solution in the case list. Finally, remove the last descriptor of the solution list. If the matched index DOES 
	 NOT point to a case, leave the corresponding Descriptor in the problem description"
	result := self searchForCasesUnderCurrNormUsing: aProblemDescription saveIn: possibleSolutions.
	(result = #cancel) ifTrue: [ self prepareFailedOutput. self status: #cancel. ^nil ].
	(result = -1)  ifTrue: [ self prepareFailedOutput. self status: #error. ^nil. ].

	"If at the end of the scanning process, the problem description is empty, the possible solutions list MUST have at least 
	one item. Else, something weird happened.  In that situation, return the error value. However, if the case list is not empty, 
	return self"
	(aProblemDescription isEmpty)
	ifTrue: [ 
		(possibleSolutions isEmpty) 
		ifTrue: [ self prepareFailedOutput. self status: #error. ^nil. ].
		^(self prepareSuccessfulOutputWith: possibleSolutions).
	].

	"At this point, the problem description is not empty. Move control to the root and search for 
	 indices that strictly point to cases."
	savNorm := (self currentNorm).
	savLevel := (self currentLevel).
	self currentNorm: (self netRoot).
	self resetLevel. self nextLevel.

	"Searching for cases under the root means that the solution description thus far obtained is invalid.
	 Therefore, this description should be considered as unmatched. Thus, place the solution description 
	 items in the unmatched description, and also copy them to a temporary list. The reason for the copy 
	 list is that, depending on the output from the root-search, it may be necessary to put all descriptors 
	 back in the solution description, in order to try the next search strategy"
	tempDeleteSolution := OrderedCollection new.
	self moveDescriptorsFrom: (self tSolutionDescription) to: (self tUnmatchedDescription) 
		copyTo: tempDeleteSolution.

	"Same sitution as with the solution description.  In this case, place the confirmed description items in the
	 unconfirmed description, and also copy them to another temporary list"
	tempDeleteConfirmed := OrderedCollection new.
	self moveDescriptorsFrom: (self tConfirmedDescription) to: (self tUnconfirmedDescription) 
		copyTo: tempDeleteConfirmed.

	"Call the search-cases-under-root method with a clean & empty possible solutions list (its part of the precondition)"
	pSolutions := OrderedCollection new.
	result := self searchForCasesUnderRootUsing: aProblemDescription saveIn: pSolutions.
	(result = #cancel) ifTrue: [ self prepareFailedOutput. self status: #cancel. ^nil ].
	(result = -1)  ifTrue: [ self prepareFailedOutput. self status: #error. ^nil. ].

	"Concatenate the solution lists into one single list"
	[ pSolutions isEmpty ] whileFalse: [ possibleSolutions add: (pSolutions removeFirst) ].

	"Restore everything to its previous state"
	self currentNorm: savNorm.
	self resetLevel.
	[ savLevel > 0 ] whileTrue: [ self nextLevel. savLevel := savLevel - 1 ].

	"If after the root-search the possible solutions and problem description lists are empty, the next strategy is to try
	 retrieving cases from the current norm. Therefore, just as with the current norm and current level, both the solution 
	 and confirmed descriptions MUST be set back to their original state (i.e., before doing the root-search). So, remove 
	 all the matching items in the temporary lists from the unmatched and unconfirmed descriptions and place them back 
	 in the corresponding solution and confirmed ones"
	self deleteDescriptorsIn: tempDeleteSolution from: (self tUnmatchedDescription) andPlaceIn: (self tSolutionDescription).
	self deleteDescriptorsIn: tempDeleteConfirmed from: (self tUnconfirmedDescription) andPlaceIn: (self tConfirmedDescription).

	"Upon return from the root search, the following situations may occur:
	a) the possible solutions list is empty.
		a1) if the problem description is now empty (i.e., all Descriptors are located in the unmatched list), then call the 
		     state-method retrieveCasesUnderCurrNorm, in order to give the search process a last chance.
		a2) if the problem description is still NOT empty (i.e., the remaining descriptors point to Norms in other paths), return nil.
	b) the possible solutions list is NOT empty. Return self, regardless of whether or not the problem description is empty."
	(possibleSolutions isEmpty)
	ifTrue: [
		"Precondition for method retrieveCasesUnderCurrNorm : isEmpty(aProblemDescription)"
		(aProblemDescription isEmpty) ifTrue: [ ^(self retrieveCasesUnderCurrNorm) ].
		self prepareFailedOutput. ^nil.
	].

	^(self prepareSuccessfulOutputWith: possibleSolutions).! !

!SAVCaseDFSAutomaton methodsFor: 'private'!

associateCasesToPossibleSolutions: aCaseList

	"This method is used in conjuntion with prepareSuccessfulOutput.  The purpose
	 of this method is to create an instance of PossibleSolution for every case in the
	 list argument aCaseList.

	Returns: a list of PossibleSolutions.

	 Automaton reference: none."

	| ps psList |

	psList := OrderedCollection new.

	1 to: (aCaseList size) do:
	[ :i |
		ps := PossibleSolution new.
		ps solution: (aCaseList at: i).
		ps copy: (self tSolutionDescription) to: (ps solutionDescription).
		ps copy: (self tConfirmedDescription) to: (ps confirmedDescription).
		ps copy: (self tUnconfirmedDescription) to: (ps unconfirmedDescription).
		ps copy: (self tDoubtfulDescription) to: (ps doubtfulDescription).
		psList add: ps.
	].

	^psList.!

deleteDescriptorsIn: aTempDeleteList from: aList andPlaceIn: anotherList

	| d j |
	1 to: (aTempDeleteList size) do:
	[:i |
		d := (aTempDeleteList at: i).

		j := 1.
		[ j <= (aList size) ]
		whileTrue:
		[
			(((aList at: j) attribute = (d attribute)) & ((aList at: j) value = (d value)))
			ifTrue: [ (aList removeAtIndex: j). j := (aList size) + 1. ]
			ifFalse: [ j := j + 1 ].
		].

		anotherList add: d.
	].

	^self.!

filterUselessNorms: aNormAlternativeList

	| newList normAlternative n successorList idx idxSuccessors d |

	newList := OrderedCollection new.

	[aNormAlternativeList isEmpty]
	whileFalse: [

		normAlternative := aNormAlternativeList removeFirst.
		n := (normAlternative last successors) first.

		((n successorCases) isEmpty)
		ifFalse: [ newList add: normAlternative ]
		ifTrue: [
			"First, get the list of successors for the current norm"
			successorList := n successors.

			1 to: (successorList size) do:
			[:i |
				"Proceed to extract the next index" 
				idx := (successorList at: i).

				"Parse the list of IndexValues associated to the index"
				idxSuccessors := idx successors.
				1 to: (idxSuccessors size) do:
				[:j |
					"For every associated IndexValue: create a SAVDescriptor"
					d := SAVDescriptor new.
					d addStructure: (netRoot structure) Attribute: (idx label) Value: ((idxSuccessors at: j) value).

					"Make sure that the descriptor is NOT already included in neither the unconfirmed and doubtful descriptions"
					(((self includes: d in: (self tUnconfirmedDescription)) = nil) & ((self includes: d in: (self tDoubtfulDescription)) = nil))
					ifTrue: [ newList add: normAlternative ] 

				].    "END 1 to: (idxSuccessors size) do:"

			].    "END 1 to: (successorList size) do:"

		].    "END ((n successorCases) isEmpty) ifTrue:"

	].    "END [aNormAlternativeList isEmpty] whileFalse:"

	^newList.!

flush: aList

	[ aList isEmpty ]
	whileFalse: [ aList removeFirst ].
	^self.!

isUseless: anAlternative

	| d n successorList idx idxSuccessors |

	n := (anAlternative last successors) first.

	((n class name = SAVCase getClassName) | (n class name = Case getClassName))
	ifTrue: [ ^false ].

	((n successorCases) isEmpty)
	ifFalse: [ ^false ].

	"First, get the list of successors for the current norm"
	successorList := n successors.

	1 to: (successorList size) do:
	[:i |
		"Proceed to extract the next index" 
		idx := (successorList at: i).

		"Parse the list of IndexValues associated to the index"
		idxSuccessors := idx successors.
		1 to: (idxSuccessors size) do:
		[:j |
			"For every associated IndexValue: create a SAVDescriptor"
			d := SAVDescriptor new.
			d addStructure: (netRoot structure) Attribute: (idx label) Value: ((idxSuccessors at: j) value).

			"Make sure that the descriptor is NOT already included in neither the unconfirmed and doubtful descriptions"
			(((self includes: d in: (self tUnconfirmedDescription)) = nil) & ((self includes: d in: (self tDoubtfulDescription)) = nil))
			ifTrue: [ ^false. ] 

		].    "END 1 to: (idxSuccessors size) do:"

	].    "END 1 to: (successorList size) do:"

	^true.!

moveDescriptorsFrom: aList to: anotherList copyTo: aCopyList

	| d |

	[ aList isEmpty ]
	whileFalse: [
		d := (aList removeFirst).
		anotherList add: d.
		aCopyList add: d.
	].

	^self.!

newSearchWith: anOldProblemDescription

	"If the automaton returns a non-empty problem description list, then the REASONER MUST call it again with that remaining description,
	 using this method. Before doing so, all lists, except the doubtful and unconfirmed ones, MUST be flushed. Make sure the new search 
	 begins at root level, and all necessary control variables are correctly set. This process repeats until the problem description list is EMPTY"

	self flush: (self tSolutionDescription).
	self flush: (self tConfirmedDescription).
	self flush: (self tUnmatchedDescription).
	self flush: (self justification).
	self status: #fail.
	self currentNorm: nil.
	self resetLevel.
	self stopLevel: (self currentLevel).
	self newOutput.

	^(self beginWith: anOldProblemDescription).!

prepareFailedOutput

	"This method is called from indexDialog, and it may be called recursively. However, it needs to be executed
	 only once. In order to avoid continuous execution of this method, check the (list) variable 'justification' of
	 searchOutput. Upon termination of the automaton process, 'justification' MUST always be non-nil. Thus, 
	 if it's non-nil, then don't execute this method.

	 This method is executed whennthe automaton has failed to provide a solution for the given problem description.

	 Automaton reference: PFO"

	((self searchOutput) justification = nil)
	ifFalse: [ ^self ].

	(self searchOutput) justification: (self justification).
	(self searchOutput) unmatchedDescription: (self tUnmatchedDescription).
	^self.!

prepareSuccessfulOutputWith: aPossibleSolutionsList

	"Automaton reference: PSO"

	(((self searchOutput) possibleSolutions) = nil)
	ifFalse: [ ^self ].

	(self searchOutput) possibleSolutions: aPossibleSolutionsList.
	(self searchOutput) justification: (self justification).
	(self searchOutput) unmatchedDescription: (self tUnmatchedDescription).
	self status: #success.
	^self.! !

!SAVCaseDFSAutomaton methodsFor: 'user dialog'!

indexDialog

	"MANAGEMENT OF AN INCOMPLETE DESCRIPTION.
	 A dialog with the user is established when the automaton has run out of descriptors from the
	 problem description, and has not located any cases.  In addition, the current norm does not
	 have any successor cases. The idea is then to present index alternatives to the user, initially
	 those indices pointing to cases. If no case is retrieved, index alternatives pointing to norms
	 is then presented to the user. If nothing works, the user has the chance to cancel the operation
	 or backtrack to a previous norm.

	 PRECONDITION: The successor list of the current norm does not contain any associated cases.

	Returns: nil - If the process was unsuccessful in finding a case.
			self - If one case was found.

	Automaton reference: IdxDial"

	| idx d idxSuccessors successorList caseAlternatives normAlternatives alternative result answer newList nA |

	caseAlternatives := OrderedCollection new.
	normAlternatives := OrderedCollection new.

	"First, get the list of successors for the current norm"
	successorList := currentNorm successors.

	1 to: (successorList size) do:
	[:i |
		"Proceed to extract the next index" 
		idx := (successorList at: i).

		"Parse the list of IndexValues associated to the index"
		idxSuccessors := idx successors.
		1 to: (idxSuccessors size) do:
		[:j |
			"For every associated IndexValue: create a SAVDescriptor"
			d := SAVDescriptor new.
			d addStructure: (netRoot structure) Attribute: (idx label) Value: ((idxSuccessors at: j) value).

			"Make sure that the descriptor is NOT already included in neither the unconfirmed and doubtful descriptions"
			(((self includes: d in: (self tUnconfirmedDescription)) = nil) & ((self includes: d in: (self tDoubtfulDescription)) = nil))
			ifTrue: [
				"Pack the descriptor, along with the associated IndexValue, in a list called alternative. The form of this list
				 will be (SAVDescriptor IndexValue)"
				alternative := OrderedCollection new.
				alternative add: d.
				alternative add: (idxSuccessors at: j).

				(((idxSuccessors at: j) successors) first class name = Norm getClassName)
				ifTrue: [ normAlternatives add: alternative ]
				ifFalse: [ caseAlternatives add: alternative ].

			].    "END ((self includes: d in: (self tUnconfirmedDescription)) & (self includes: d in: (self tDoubtfulDescription))) ifFalse: ["

		].    "END 1 to: (idxSuccessors size) do:"

	].    "END 1 to: (successorList size) do:"

	"Present the list of alternatives (associated to one index) to the user, preferably the cases"
	(caseAlternatives isEmpty)
	ifFalse:[ 
		result := (self presentChoices: caseAlternatives).
		(result = self) ifTrue: [ ^self ].
		(result = nil) ifTrue: [ self prepareFailedOutput. ^nil ].
		(result = #cancel) ifTrue: [ self prepareFailedOutput. self status: result. ^nil ].
	].

	(normAlternatives isEmpty)
	ifFalse:[ 
		newList := OrderedCollection new.
		[normAlternatives isEmpty]
		whileFalse: [
			nA := normAlternatives removeFirst.
			(self isUseless: nA) ifFalse: [ newList add: nA ].
		].
		(newList isEmpty)
		ifFalse: [
			result := (self presentChoices: newList).
			(result = self) ifTrue: [ ^self ].
			(result = nil) ifTrue: [ self prepareFailedOutput. ^nil ].
			(result = #cancel) ifTrue: [ self prepareFailedOutput. self status: result. ^nil ].

		].    "END (newList isEmpty) ifFalse:"

	].    "END (normAlternatives isEmpty) ifFalse:["

	"At this point, all alternatives for this norm failed because they were either unconfirmed or rejected 
	due to doubt. Present to the user the possibility to BACKTRACK"
	answer := (SukiaDialog
				confirm: 'Hasta ahora las alternativas presentadas \no han ayudado a resolver el problema.\Desea continuar evaluando otras alternativas?'
				initialAnswer: false).
	(answer = false)
	ifTrue: [ self prepareFailedOutput. ^nil ].

	^(self backtrack).!

presentChoices: alternativeList

	"The elements of the argument alternativeList are lists of the form: (SAVDescriptor IndexValue)
	Returns:	self - if successful (i.e., at least one possible solution was found).
				nil - if retrieveCasesUnderNorm fails.
				#cancel - if the user cancels the dialog.
				#fail - if all alternatives were rejected (either because they did not match or the user was in doubt)

	Automaton reference: This method is an extension of indexDialog, referenced by IdxDial"

	| alternative message answer solution caseList value |

	1 to: (alternativeList size) do:
	[:i |
		
		(self isUseless: (alternativeList at: i))
		ifFalse: [

			alternative := (alternativeList at: i) first.
			solution := ((alternativeList at: i) last successors) first.

			((alternative value) respondsToArithmetic)
			ifTrue: [ value := (alternative value) printString ]
			ifFalse: [ value := (alternative value) asString ].

			"Prepare the inquiry to be presented to the user"
			message := 'Presenta ' , ((alternative structure) asString) , ' la característica ' , ((alternative attribute) asString) , 
				' ' , value , '?'.

			answer := (SukiaDialog
						choose: message
						for: SukiaDialog defaultParentWindow).

			(answer = #confirm) 
			ifTrue: [ 

				"The solution is a norm"
				(solution class name = Norm getClassName)
				ifTrue: [ 
					self processNextNormWith: alternative and: solution. 
					^(self retrieveCasesUnderCurrNorm)
				]

				"The solution is a case"
				ifFalse: [
					self tConfirmedDescription: alternative.
					caseList := OrderedCollection new. 
					caseList add: solution. 
					^(self prepareSuccessfulOutputWith: (self associateCasesToPossibleSolutions: caseList)) 
				].

			].    "END (answer = #confirm) ifTrue: ["

			(answer = #reject) ifTrue: [ self tUnconfirmedDescription: alternative ].
			(answer = #doubt) ifTrue: [ self tDoubtfulDescription: alternative ].
			(answer = #cancel) ifTrue: [ ^answer ].

		].    "END (self isUseless: (alternativeList at: i) ifFalse:"

	].    "END 1 to: (alternativeList size) do: ["

	^#fail.!

processNextNormWith: aSAVDescriptor and: aNorm

	"Automaton reference: PNN"

	self tConfirmedDescription: aSAVDescriptor.
	self currentNorm: aNorm.
	self nextLevel.
	^self.!

searchCasesDialogUsing: aSAVDescriptor saveIn: aPossibleSolutionsList

	"MANAGEMENT OF A POSSIBLY INNACURATE DESCRIPTOR.
	 This method establishes a dialog with the user. First, an index is searched, under the current
	 norm, that matches the descriptor argument's attribute only. If there is a match, a new SAVDescriptor
	 is created for every index value found for the retrieved index. The new information is presented to 
 	 the user, in order for him/her to determine if it applies.

	 Returns:	#idxNotFound - if an index was not found using the descriptor argument's attribute.
				#cancel - if the user cancels.
				#success - if a case was accepted.
				#fail - if index values point to norms, or the user rejected possibilities, or a combination 
				       of both situtions occurred."

	| idx indexValues idxValue descValue succ message pSolutionList d result displayValues returnValues descriptorList |

	"Partial match: Look for an index under the current norm, whose label matches the 
	 descriptor's attribute. Disregard the descriptor's value"
	idx := (self currentNorm) getIndexWith: (aSAVDescriptor attribute).
	(idx = nil) ifTrue: [ ^#idxNotFound ].

	"The index was found. Create a temporary possible solutions list"
	pSolutionList := OrderedCollection new.

	displayValues := List new.
	returnValues := List new.
	descriptorList := OrderedCollection new.

	"Scan the index's index-values"
	indexValues := idx successors.
	1 to: (indexValues size) do:
	[:i |
		"Get the next index value successor"
		succ := ((indexValues at: i) successors) at: 1.

		"Determine if the successor is a norm"
		(succ class name = (Norm getClassName))
		ifFalse: [
			"The successor is a case. Create a new SAVDescriptor with the information from the current 
			 structure, index, and index value"
			d := SAVDescriptor new.
			d addStructure: (netRoot structure) Attribute: (idx label) Value: (indexValues at: i) value.

			"Since this descriptor corresponds to a partial match, make sure that it is NOT already 
			 included in neither the unconfirmed, doubtful, unmatched, solution, or confirmed descriptions"
			(((self includes: d in: (self tUnconfirmedDescription)) = nil) & 
			 ((self includes: d in: (self tDoubtfulDescription)) = nil) &
			 ((self includes: d in: (self tUnmatchedDescription)) = nil) &
			 ((self includes: d in: (self tSolutionDescription)) = nil) &
			 ((self includes: d in: (self tConfirmedDescription)) = nil))
			ifTrue: [

				"FUTURE IMPROVEMENT (documented by HB on 10-Sep-1999):
				 1. Retrieve the taxon corresponding to the successor case.
				 2. Retrieve the structure-atribute, from the taxon's description, that matches (d structure) and (d attribbute).
				 3. Retrieve the weighted-value list from the corresponding taxon's structure-attribute.
				 4. Determine, using the weighted-value list, SimAssessor, and SimRanges, the degree of similarity 
					between d and aSAVDescriptor.
				 5. If the degree of similarity satisfies the user-defined expectation E7, then present d to the user. 
					Else, don't present it to the user and continue with the rest of this process.
				 6. Document the whole process in the search process justification."

				((d value) respondsToArithmetic)
				ifTrue: [ idxValue := (d value) printString ]
				ifFalse: [ idxValue := (d value) asString ].

				displayValues add: idxValue.
				returnValues add: succ.
				descriptorList add: d.

			].    "END (((self includes: d in: (self tUnconfirmedDescription)) = nil) & ... ifTrue:"

		].    "END (succ class name = (Norm getClassName)) ifFalse:"

	].    "END 1 to: (indexValues size) do:"

	(displayValues size = 0) ifTrue: [ ^#fail. ].

	((aSAVDescriptor value) respondsToArithmetic)
	ifTrue: [ descValue := (aSAVDescriptor value) printString ]
	ifFalse: [ descValue := (aSAVDescriptor value) asString ].

	message :=	(netRoot structure) , ': ' , (aSAVDescriptor attribute) , '.' ,
				'\No reconozco el valor ' , descValue , '\brindado en la descripción del\espécimen. '.

	(displayValues size = 1)
	ifTrue: [ message := message , 'Sin embargo, sí puedo\reconocer el siguiente valor.\Es válido?' ]
	ifFalse: [ message := message , 'Sin embargo, sí puedo\reconocer los siguientes valores.\Es alguno válido?' ].

	result := (SukiaDialog
				choose: message 
				fromList: displayValues 
				values: returnValues 
				lines: 8 
				for: SukiaDialog defaultParentWindow).

	(result = #cancel) ifTrue: [ ^#cancel ].
	(result = #reject) ifTrue: [ [descriptorList isEmpty ] whileFalse: [ self tUnconfirmedDescription: (descriptorList removeFirst) ]. ^#fail ].
	(result = #doubt) ifTrue: [ [descriptorList isEmpty ] whileFalse: [ self tDoubtfulDescription: (descriptorList removeFirst) ]. ^#fail ].

	"At this point, the answer must be successful. Associate the confirmed case to PossibleSolution. Then exit successfully"
	self tConfirmedDescription: (descriptorList at: (returnValues indexOf: result)). 
	pSolutionList add: result.
	pSolutionList := (self associateCasesToPossibleSolutions: pSolutionList).
	aPossibleSolutionsList add: (pSolutionList removeFirst).
	self tConfirmedDescription removeLast.

	^#success.! !

!SAVCaseDFSAutomaton methodsFor: 'norm-pointing search'!

beginWith: aProblemDescription

	"Initial state of the search automaton.  Control is placed on the root norm. The final step is a call to the next state 
	 (i.e., searchForNormWith). NOTE: The argument aProblemDescription is a non-empty list of Descriptors.

	 Precondition:
	 1. aProblemDescription is a non-empty set of SAVDescriptors.
	 2. For all s1, s2::SAVDescriptor in aProblemDescription : (s1 structure) = (s2 structure).

	 Returns: nil - if the argument is an empty list, or
			  object returned by searchForNormWith:

	Automaton reference: bW"

	| sName |

	"Check part 1. of the precondition"
	(aProblemDescription isEmpty)
	ifTrue: [ ^nil ].

	"Check part 2. of precondition"
	(aProblemDescription at: 1) class name = (SAVDescriptor getClassName)
	ifFalse: [ ^nil ].

	((aProblemDescription size) > 1)
	ifTrue: [
		"Get the structure name of the first descriptor"
		sName := (aProblemDescription at: 1) structure.

		2 to: (aProblemDescription size) do:
		[:i | 
			((aProblemDescription at: i) class name = (SAVDescriptor getClassName)) ifFalse: [ ^nil ].
		      (sName = ((aProblemDescription at: i) structure)) ifFalse: [ ^nil ] ].
	].

	"Initialization steps. At this point, nextLevel = 1. Thus, the root level is 1"
	self currentNorm: (self netRoot).
	self nextLevel.

	"Move to the next state, and return its returning value (nil or self)"
	^(self searchForNormWith: aProblemDescription).!

retrieveCasesUnderCurrNorm

	"This method attempts to retrieve norm-dependant cases, from the stop-level norm.
	 At this point, the problem description is empty of descriptors.  If at least one case 
	 was retrieved, prepare the successful output and stop the automaton. Else, start a
	 dialog with the user.

	 Returns: object returned by either prepareSuccessfulOutputWith: (self), or indexDialog.

	Automaton reference: RCUN" 

	| caseList |

	caseList := (self currentNorm) successorCases.
	(caseList isEmpty)
	ifFalse: [ ^(self prepareSuccessfulOutputWith: (self associateCasesToPossibleSolutions: caseList)) ].

	^(self indexDialog).!

searchForNormWith: aProblemDescription

	"The argument aProblemDescription is scanned in search for descriptors that correspond
	 to indices pointing to norms. Every time one such descriptor is located, currNorm is reassigned and
	 the descriptor placed in the solution description.  If after the process the argument list is empty, a call 
	 to state retrieveCasesUnderNorm is performed.  If the list is completely scanned and no descriptor was 
	 located, a call to state searchForCasesWith is executed.

 	 NOTE: The argument aProblemDescription is a list of Descriptors

	 Returns: self, or
			  object returned by retrieveCasesUnderCurrNorm, or
			  object returned by searchForCasesUsing:

	Automaton reference: SNW"

	| i d nextNorm |

	"If the problem description is empty, all its descriptors matched norms. Make the current norm
	 the stop-level norm, and start the search for cases under it"
	(aProblemDescription isEmpty)
	ifTrue: [ self stopLevel: (self currentLevel). ^(self retrieveCasesUnderCurrNorm) ].

	"Scan the problem description"
	d := nil.
	i := 1.
	[ i <= (aProblemDescription size) ]
	whileTrue: [

		"Search for a norm whose descriptor matches the scanned descriptor. If found,
		 remove the descriptor from the problem case and stop the loop"
		nextNorm := (self currentNorm) successorWith: (aProblemDescription at: i).
		(nextNorm = nil)
		ifTrue: [ i := i + 1 ]
		ifFalse: [ d := (aProblemDescription removeAtIndex: i). i := (aProblemDescription size) + 1 ].
	].

	"if no descriptor available, the entire list was scanned and no norm was found.  Start the search
	 for indices (using the remaining descriptors) that point to cases"
	(d = nil)
	ifTrue: [ 

		self stopLevel: (self currentLevel).
		^(self searchForCasesUsing: aProblemDescription).

	].    "END (d = nil) ifTrue:"

	"A norm with a matching descriptor was found.  Add the removed descriptor to the solution
	 list, and move on to the next (recursive) norm search"
	self updateNormSearchWith: d and: nextNorm.
	^(self searchForNormWith: aProblemDescription).!

updateNormSearchWith: aSAVDescriptor and: aNewNorm

	"Automaton reference: UNS"

	self tSolutionDescription: aSAVDescriptor.
	self currentNorm: aNewNorm.
	self nextLevel.
	^self.! !

!SAVCaseDFSAutomaton methodsFor: 'testing'!

includes: aSAVDescriptor in: aDescription

	"Determines if aSAVDescriptor is already a member of aDescriptionList. The argument aSAVDescriptor is a member of 
	aDescriptionList when its structure name, its attribute name, and its value match with the structure, attribute, and value 
	of a list element.
	Returns: 	-1 (error state): The argument aDescriptionList IS NOT a valid list for self.
				nil: aSAVDescriptor IS NOT a member of aDescriptionList.
				not nil: an element of aDescriptionList whose structure and attribute names match those of aSAVDescriptor"

	| d |

	"First step: make sure that the process is executed against one of my lists"
	((aDescription = (self tSolutionDescription)) | 
	 (aDescription = (self tConfirmedDescription)) | 
	 (aDescription = (self tUnconfirmedDescription)) | 
	(aDescription = (self tUnmatchedDescription)) | 
	 (aDescription = (self tDoubtfulDescription)))
	ifFalse: [ ^(-1) ].

	1 to: (aDescription size) do:
	[:i |
		d := aDescription at: i.

		((d structure = aSAVDescriptor structure) & (d attribute = aSAVDescriptor attribute) & (d value = aSAVDescriptor value))
		ifTrue: [ ^d ].
	].

	^nil.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SAVCaseDFSAutomaton class
	instanceVariableNames: ''!


!SAVCaseDFSAutomaton class methodsFor: 'instance creation'!

newWith: aSAVRoot

	| searchAutomaton |

	searchAutomaton := super new.
	searchAutomaton initializeWith: aSAVRoot.
	^searchAutomaton.! !

TaxonSearchAutomaton subclass: #TaxonGHISAutomaton
	instanceVariableNames: 'groupingHeuristic '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Search Automata'!
TaxonGHISAutomaton comment:
'Taxon GroupingHeuristic-Index Search Automaton.

1. The search is based on a problem description composed of a one-element set of SAVDescriptor.

2. The form of the SAVDescriptor MUST be:
	aSAVDescriptor = ( generalStructureName, groupingHeuristicName, value ), where:
	 generalStructureName = name of the organism for which the Reasoner is set up (e.g., ''planta''),
	 groupingHeuristicName = a valid grouping heuristic name (e.g., #esLenoso),
	 value = (ByteSymbol | Number)

3. The search strategy is to use the GroupingHeuristicIndex defined in the class Taxonomy.'!


!TaxonGHISAutomaton methodsFor: 'initializing'!

initializeWithIndex: aGroupingHeuristicIndex

	self searchIndex: aGroupingHeuristicIndex.
	self resetGroupingHeuristic.
	^self.!

resetGroupingHeuristic

	groupingHeuristic := nil.
	^nil.! !

!TaxonGHISAutomaton methodsFor: 'adding'!

groupingHeuristic: aGroupingHeuristic

	groupingHeuristic := aGroupingHeuristic.
	^self.! !

!TaxonGHISAutomaton methodsFor: 'accessing'!

groupingHeuristic

	^groupingHeuristic.!

groupingHeuristicIndex 

	^self searchIndex.! !

!TaxonGHISAutomaton methodsFor: 'searching'!

beginWith: aProblemDescription

	"The argument aProblemDescription MUST consist of one SAVDescriptor of the form:
	 aSAVDescriptor = ( generalStructureName, groupingHeuristicName, value ), where:

	 generalStructureName = name of the organism for which the Reasoner is set up (e.g., 'planta'),
	 groupingHeuristicName = a valid grouping heuristic name (e.g., #esLenoso),
	 value = (ByteSymbol | Number)

	Returns: nil - if the precondition was not met, or an error occurred, or the process failed to find possible solutions.
			value returned by prepareSuccessfulOutputWith:

	 Automaton reference: bW"

	"Check general description precondition"
	((self checkPrecondition: aProblemDescription) = nil)
	ifTrue: [ self status: #error. ^nil ].

	"Local precondition: Make sure that aProblemDescription consists of only ONE element"
	((aProblemDescription size) > 1)
	ifTrue: [ self status: #error. ^nil ].

	"Search the corresponding grouping heuristic in the grouping heuristic index"
	self groupingHeuristic: (self groupingHeuristicIndex groupingHeuristicWith: ((aProblemDescription first) attribute)).
	(self groupingHeuristic = nil) ifTrue: [ self prepareFailedOutput. ^nil ].

	((self searchValueDescriptors: (aProblemDescription removeFirst)) = -1)
	ifTrue: [ self status: #error. ^nil ].

	(self taxonList isEmpty)
	ifTrue: [ self prepareFailedOutput. ^nil. ].

	^(self prepareSuccessfulOutputWith: (self taxonList)).!

searchValueDescriptors: aSAVDescriptor

	"This method searchs for value descriptors that either match aSAVDescriptor value, or correspond
	 to a range for which aSAVDescriptor value applies.  If valueDescriptors are found, each associated
	 taxon will be set up as a possible solution. All possible solutions will be stored in taxonList.

	Returns: -1 : if a processing error occurred.
			 nil : if no value descriptors were found.
			 self : if at least one descriptor was found.

	Automaton reference: SVD"

	| bSymbol attrValues i vd taxa |

	"This variable is set just to test if aSAVDescriptor value is a ByteSymbol"
	bSymbol := ByteSymbol new: 1.

	attrValues := (self groupingHeuristic values).

	i := 1.
	[ i <= (attrValues size) ]
	whileTrue: [

		"Set the list of possible value descriptors to nil"
		vd := nil.

		"If the argument's value is not ByteSymbol, then it MUST be a number. If so, search for
		 a match using value descriptor ranges. If the search was unsuccessful, reset vd to nil"
		((aSAVDescriptor value) class name = bSymbol class name)
		ifFalse: [ 
			vd := attrValues numberInRange: (aSAVDescriptor value) atLevel: i.
			(vd = nil) ifTrue: [ ^-1 ].
			(vd isEmpty) ifTrue: [ vd := nil ].
		].

		"If the list of possible value descriptors is not nil, a successful range-based descriptor search was done.
		 Place the value descriptor in the valueDescriptors instance variable"
		(vd = nil) 
		ifFalse: [ self valueDescriptors: vd ]
		ifTrue: [
			"At this point, either: a) the argument's value is a ByteSymbol, or a range search was
			 unsuccessful. Do then an exact match search"
			vd := attrValues value: (aSAVDescriptor value) in: i.
			(vd = nil) ifTrue: [ ^-1 ].
			(vd isEmpty) ifFalse: [ self valueDescriptors: vd ].
		].

		i := i + 1.

	].    "END [ i <= (attrValues size) ] whileTrue:"

	(self valueDescriptors isEmpty)
	ifTrue: [ self tUnmatchedDescription: aSAVDescriptor. ^nil ].

	"Extract the taxa included in each of the retrieved value descriptors"
	self tSolutionDescription: aSAVDescriptor.
	[ self valueDescriptors isEmpty ]
	whileFalse: [

		vd := (self valueDescriptors removeFirst).
		taxa := vd taxonList.
		taxa := self associateTaxaToPossibleSolutions: taxa.
		[ taxa isEmpty ] whileFalse: [ self taxonList: (taxa removeFirst) ].

	].     "END [ self valueDescriptors isEmpty ] whileFalse:"

	^self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TaxonGHISAutomaton class
	instanceVariableNames: ''!


!TaxonGHISAutomaton class methodsFor: 'instance creation'!

newWith: aGroupingHeuristicIndex

	| searchAutomaton |

	searchAutomaton := super new.
	searchAutomaton initializeWithIndex: aGroupingHeuristicIndex.
	^searchAutomaton.! !

TaxonSearchAutomaton subclass: #TaxonSISAutomaton
	instanceVariableNames: 'structure attribute similarityRanges '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Search Automata'!
TaxonSISAutomaton comment:
'Taxon Structure-Index Search Automaton.
1. The search is based on a problem description composed of a non-empty set of SAVDescriptors.
2. The search strategy is to use the StructureIndex defined in the class Taxonomy.'!


!TaxonSISAutomaton methodsFor: 'initializing'!

initializeWithIndex: aStructureIndex minSimilarityRange: aSimilarityRangeList

	self searchIndex: aStructureIndex.
	similarityRanges := aSimilarityRangeList.
	self resetStructure.
	self resetAttribute.
	^self.!

resetAttribute

	attribute := nil.
	^self.!

resetStructure

	structure := nil.
	^self.! !

!TaxonSISAutomaton methodsFor: 'adding'!

attribute: anAttribute

	attribute := anAttribute.
	^self.!

structure: aStructure

	structure := aStructure.
	^self.! !

!TaxonSISAutomaton methodsFor: 'accessing'!

attribute 

	^attribute.!

similarityRanges

	^similarityRanges.!

structure 

	^structure.!

structureIndex 

	^self searchIndex.! !

!TaxonSISAutomaton methodsFor: 'searching'!

beginWith: aProblemDescription

	"Initial state of the search automaton.  

	 Precondition:
	 1. aProblemDescription is a non-empty set of SAVDescriptors.
	 2. For all s1, s2::SAVDescriptor in aProblemDescription : (s1 structure) = (s2 structure).

	Returns: nil - if the precondition was not satisfied or the search process failed;
			 object returned by prepareSuccessfulOutputWith:

	Automaton reference: bW"

	((self checkPrecondition: aProblemDescription) = nil)
	ifTrue: [ self status: #error. ^nil ].

	"Search the corresponding structure in the structure index"
	self structure: (self structureIndex structureWith: (aProblemDescription at: 1) structure).
	(self structure = nil) ifTrue: [ self prepareFailedOutput. ^nil ].

	[ aProblemDescription isEmpty ]
	whileFalse: [ 
		self resetAttribute.
		self resetList: (self valueDescriptors).
		((self searchAttribute: (aProblemDescription removeFirst)) = -1)
		ifTrue: [ self status: #error. ^nil ].
	].

	(self compress = self)
	ifTrue: [ ^(self prepareSuccessfulOutputWith: (self taxonList)) ].

	self prepareFailedOutput. 
	^nil.!

determineSimilarityFor: aSAVDescriptor context: aTaxon

	"Determines the similarity range between aSAVDescriptor's value and aTaxon's value
	 weight list.  If there exists a range of similrity, it is checked against the accepted 
	 ranges.

	 Returns: nil : if there is no similarity.
			  aTaxon : if there was an acceptable degree of similarity.

	Automaton reference: DS"

	| weightedValues similarity |

	weightedValues := 
		(((aTaxon getAnObjectWith: (aSAVDescriptor structure) in: (aTaxon SAVdescription))
		   attributeWith: (aSAVDescriptor attribute)) values at: (Attribute oneLevel)).

	similarity := SimAssessor similarityRangeOf: (aSAVDescriptor value) in: weightedValues.
	(self similarityRanges includes: similarity) ifFalse: [ ^nil ].

	^aTaxon.!

retrieveTaxa: aSAVDescriptor

	"This method extracts all taxa from the value descriptors located in the instance list variable
	 valueDescriptors.  ONLY exact-match value descriptors may exist at this point. The reason
	 is that a similarity check will be performed between the argument's value and the descriptor's 
	 taxa weighted-value list; this check will not work with range value descriptors.

	 Returns: -1 : if a processing error occurred.
			 nil : if the argument's value is NOT similar to any value in the taxon's weighted value list.
		     self : if at least one taxon's weighted value list contains a similar item to the argument's value.

	 Automaton reference: RT"

	| vd taxa taxon tempList |

	tempList := OrderedCollection new.

	1 to: (self valueDescriptors size) do:
	[:i |
		vd := (self valueDescriptors at: i).
		taxa := vd taxonList.
		(taxa isEmpty) ifTrue: [ ^-1 ].

		[ taxa isEmpty ]
		whileFalse: [

			taxon := self determineSimilarityFor: aSAVDescriptor context: (taxa removeFirst).
			(taxon = nil) ifFalse: [ tempList add: taxon ].

		].    "END [taxa isEmpty] whileFalse:"

	].    "END 1 to: (self valueDescriptors size) do:"

	(tempList isEmpty) ifTrue: [ ^nil ].

	self tSolutionDescription: aSAVDescriptor.
	taxa := self associateTaxaToPossibleSolutions: tempList.
	[ taxa isEmpty ] whileFalse: [ self taxonList: (taxa removeFirst) ].
	self resetList: (self tSolutionDescription).

	^self.!

searchAttribute: aSAVDescriptor

	"Automaton reference: SA"

	self attribute: (self structure attributeWith: (aSAVDescriptor attribute)).
	((self attribute) = nil)
	ifTrue: [ self tUnmatchedDescription: aSAVDescriptor. ^nil ].

	^(self searchValueDescriptors: aSAVDescriptor).!

searchValueDescriptors: aSAVDescriptor

	"This method searches for value descriptors that that do an exact match with aSAVDescriptor's values,
	 or value range-descriptors for which aSAVDescriptor value applies

	 Returns: -1 : if a processing error occurred.
			 nil : if no value descriptors were found.
			self : if range descriptors were found.
			value returned by methodRetrieveTaxa (this method is invoked for exact-match value descriptors).

	Automaton reference: SVD"

	| bSymbol attrValues i vd taxa tempList |

	"This variable is set just to test if aSAVDescriptor value is a ByteSymbol"
	bSymbol := ByteSymbol new: 1.

	attrValues := (self attribute) values.

	i := 1.
	[ i <= (attrValues size) ]
	whileTrue: [

		"Set the list of possible value descriptors to nil"
		vd := nil.

		"If the argument's value is not ByteSymbol, then it MUST be a number. If so, search for
		 a match using value descriptor ranges. If the search was unsuccessful, reset vd to nil"
		((aSAVDescriptor value) class name = bSymbol class name)
		ifFalse: [ 
			vd := attrValues numberInRange: (aSAVDescriptor value) atLevel: i.
			(vd = nil) ifTrue: [ ^-1 ].
			(vd isEmpty) ifTrue: [ vd := nil ].
		].

		"If the list of possible value descriptors is not nil, a successful range-based descriptor search was done.
		 Place the value descriptor in the valueDescriptors instance variable"
		(vd = nil) 
		ifFalse: [ self valueDescriptors: vd ]
		ifTrue: [
			"At this point, either: a) the argument's value is a ByteSymbol, or a range search was
			 unsuccessful. Do then an exact match search"
			vd := attrValues value: (aSAVDescriptor value) in: i.
			(vd = nil) ifTrue: [ ^-1 ].
			(vd isEmpty) ifFalse: [ self valueDescriptors: vd ].
		].

		i := i + 1.

	].    "END [ i <= (attrValues size) ] whileTrue:"

	(self valueDescriptors isEmpty)
	ifTrue: [ self tUnmatchedDescription: aSAVDescriptor. ^nil ].

	"Separate the range descriptors from the exact-match descriptors"
	tempList := OrderedCollection new.
	[ self valueDescriptors isEmpty ]
	whileFalse: [

		vd := (self valueDescriptors removeFirst).
		(vd asRange)
		ifTrue: [ 
			"Value desscriptor is a range. Associate all taxa to possible solutions, place them in the taxon list"
			taxa := vd taxonList.
			self tSolutionDescription: aSAVDescriptor.
			taxa := self associateTaxaToPossibleSolutions: taxa.
			self resetList: (self tSolutionDescription).
			[ taxa isEmpty ] whileFalse: [ self taxonList: (taxa removeFirst) ].
		]

		"Value descriptor is not a range. Place it in a temporary list"
		ifFalse: [ tempList add: vd ]

	].    "END [ self valueDescriptors isEmpty ]"

	"At this point, all descriptors have been verified and processed. If there are no exact-match value descriptors left, return"
	(tempList isEmpty) ifTrue: [ ^self ].

	"Remove all exact-match value descriptors from the temporary list, put them back in the valueDescriptos
	 list, and continue processing"
	self valueDescriptors: tempList.
	^(self retrieveTaxa: aSAVDescriptor).! !

!TaxonSISAutomaton methodsFor: 'private'!

compress

	"Since this automaton searches for taxa one SAVDescriptor at a time, at the end of the process there may
	 exist a number of possible solutions (with one SAVDescriptor solution descriptions) refering to: a) the same 
	 taxon or b) a successor taxon of another possible solution.  What this method does is to place the solution 
	 descriptions of several possible solutions (that refer to the same taxon) in a single one, and to inherit the 
	 solution description of a predecessor possible-solution taxon.

	Precondition: (self taxonList is NOT empty)

	 Returns: -1: error condition. All posible solutions' solution description MUST consist of ONE SAVDescriptor.
				 The reason for this is that since earch search was done one SAVDescriptor at a time, then all possible
				 solutions must contain exactly one SAVDescriptor in their solution description.
			nil - if the precondition is not met.
			self - the process ran OK.

	 Automaton reference: C"

	| ps compSolution tempList i inheritedDescription |

	"Check precondition"
	(self taxonList isEmpty)
	ifTrue: [ ^nil ].

	tempList := OrderedCollection new.
	inheritedDescription := OrderedCollection new.

	"Scan the taxonList, which contains set of PossibleSolutions"
	[ self taxonList isEmpty ]
	whileFalse: [

		"Remove the next possible solution from the taxon list"
		ps := (self taxonList) removeFirst.
		(ps solutionDescription size > 1) ifTrue: [ ^-1 ].

		"Compare ps against the rest of the possible solutions in taxonList"
		i := 1.
		[ i <= (self taxonList size) ]
		whileTrue: [

			"Get the next possible solution to compare against"
			compSolution := ((self taxonList) at: i).
			(compSolution solutionDescription size > 1) ifTrue: [ ^-1 ].

			"Determine if the current possible solution's attribute is different from the compare possible solution's attribute"
			(((ps solutionDescription) at: 1) attribute = ((compSolution solutionDescription) at: 1) attribute)
			ifTrue: [ i := i + 1 ]
			ifFalse: [

				"Check if the proposed solutions are the same object"
				(ps solution = compSolution solution)
				ifTrue: [

					"Inherit the compare solutions solutionDescription and remove it from the taxonList"
					[ compSolution solutionDescription isEmpty ]
					whileFalse: [ inheritedDescription add: (compSolution solutionDescription) removeFirst ].
					(self taxonList) removeAtIndex: i.

				]    "END (ps solution = compSolution solution) ifTrue:"

				"At this point, ps and compSolution are different taxa"
				ifFalse: [

					"Check if ps is a successor of compSolution"
					((ps solution) isSuccessorOf: (compSolution solution))
					ifTrue: [

						"ps inherits compSolution's description"
						1 to: (compSolution solutionDescription size) do:
						[:j | inheritedDescription add: ((compSolution solutionDescription) at: j) ].

					].    "END ((ps solution) isSuccessorOf: (compSolution solution)) ifTrue:"

					i := i + 1.

				].    "END (ps solution = compSolution solution) ifFalse:"

			].    "END (((ps solutionDescription) at: 1) attribute = ((compSolution ...) ifFalse:"

		].    "END [ i <= (self taxonList size) ] whileTrue:"

		"Place the current possible solution in a temporary list"
		[ inheritedDescription isEmpty ] whileFalse: [ ps solutionDescription: (inheritedDescription removeFirst) ].
		tempList add: ps.
		ps := nil.

	].    "END [ self taxonList isEmpty ] whileFalse:"

	"Put all processed taxa back in the taxonList"
	[ tempList isEmpty ]
	whileFalse: [ self taxonList: (tempList removeFirst) ].

	^self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TaxonSISAutomaton class
	instanceVariableNames: ''!


!TaxonSISAutomaton class methodsFor: 'instance creation'!

newWith: aStructureIndex and: aMinSimilarityRange

	| searchAutomaton |

	searchAutomaton := super new.
	searchAutomaton initializeWithIndex: aStructureIndex minSimilarityRange: aMinSimilarityRange.
	^searchAutomaton.! !

