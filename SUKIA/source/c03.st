Object subclass: #RDNet
	instanceVariableNames: 'root route caseInsert caseCompare ciDesc currNorm problemCase solution recursionCount '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Main'!
RDNet comment:
'RDNet

Purpose: Entry access structure to a redundant discrimination net.  This class implements all necessary methods to establish a net root,
and add new cases, indices, and norms.

Messages with subclassResponsibility: None.

Instance variables:
root:  Instance of class Root.  This is the main entry structure to the rest of the net.
route: Control structure (CBRStack) used by the case-adding methods.  As new Norm''s are reached during net traversal, their attributes are placed
in this stack to make sure that no indices will be duplicated.
caseInsert: Pointer to the Case to be inserted into the net.
caseCompare: A CBRStack that contains instances of Case''s found during net traversal.
ciDesc: Case-To-Insert description, used to traverse the net, and create new Norms and indices.
currNorm: Pointer to the current Norm during net traversal.
problemCase: Instance of a Problem Case to be resolved.
solution: Solution object obtained from the adaptation of a Case found.
recursionCount: Integer that controls the number of recusrive calls during case-to-insert and case-to-compare comparisons, in the cas-adding methods.

Class variables: None.'!


!RDNet methodsFor: 'initializing'!

initialize

	root := Root new.
	route := CBRStack new.
	caseInsert := nil.
	caseCompare := CBRStack new.
	ciDesc := OrderedCollection new.
	currNorm := nil.
	problemCase := ProblemCase new.
	solution := Solution new.
	self resetRecursionCount.
	^self.! !

!RDNet methodsFor: 'accessing'!

caseToCompare

	^caseCompare top.!

caseToInsert

	^caseInsert!

caseToInsertDesc

	^ciDesc!

currNorm

	^currNorm.!

numRouteElements

	^(route size).!

problemCase

	"Devuelve el caso problema actual de la red."
	^problemCase.!

recursionCount

	^recursionCount.!

root

	^root.!

route 

	^route top.!

solution

	"Devuelve el vector que contiene todos los casos que podrian solucionar el problema."
	^solution.! !

!RDNet methodsFor: 'adding'!

add: aCase

	"Step 1. Check that the case's status is correct (i.e., neither pending nor unknown)"
	((aCase isPending) | (aCase isStatusUnknown)) ifTrue: [ ^nil ].

	"Step 2. Get ready: Clear working variables, get the case's description, copy the case, and set the current norm"
	self flush.
	self getCaseDescription: aCase.
	self copyCase: aCase.
	currNorm := (self root).
	currNorm incrementNumCasesBy: 1.

	"Step 3: Start the adding process"
	((self processCase) = nil)
	ifTrue: [ ^nil ]
	ifFalse: [ ^self ].! !

!RDNet methodsFor: 'resetting'!

flush

	route flush.
	caseInsert := nil.
	caseCompare flush.
	self flushCaseToInsertDesc.
	currNorm := nil.
	problemCase flush.
	solution flush.
	self resetRecursionCount.
	^self.!

flushCaseToInsertDesc

	[ ciDesc isEmpty ] whileFalse: [ ciDesc removeFirst ].
	^self.!

resetRecursionCount

	^(recursionCount := 0).!

resetRootTo: aSAVRoot

	"Changes the root reference by of of the class SAVRoot.  This root modification is necessary for the 'CBR - Sukia' implementation"

	(((aSAVRoot class) name) = (SAVRoot getClassName)) ifFalse: [ ^nil ].
	root := aSAVRoot.
	^self.! !

!RDNet methodsFor: 'reading'!

copyCase: aCase

	caseInsert := aCase.
	^self.!

getCaseDescription: aCase

	| desc |

	desc := aCase description.
	1 to: desc size do:
		[:i | ciDesc add: (desc at: i) ].
	^self.!

moveDescElementsFrom: oneDescList to: anotherDescList

	(oneDescList isEmpty) ifTrue: [ ^nil ].
	[oneDescList isEmpty] whileFalse: [ anotherDescList add: oneDescList removeFirst. ].
	^self.! !

!RDNet methodsFor: 'removing'!

removeMatchingElementsInTheRouteFrom: aDescriptionList

	"Removes elements from a (case's) description, whose attribute is already included in the Route.
	 IMPORTANT NOTE: The elements from aDescriptionList MUST be able to provide the descriptor's
	 attribute."

	| i |

	i := 1.
	[ i <= (aDescriptionList size) ] 
	whileTrue: [

		(route containsTheObject: ((aDescriptionList at: i) attribute))
		ifTrue: [ aDescriptionList removeAtIndex: i ]
		ifFalse: [ i := i + 1 ] 

	].    "END [ i <= (aDescriptionList size) ] whileTrue: ["

	^aDescriptionList.! !

!RDNet methodsFor: 'operations-private'!

decrementRecursionCount

	^(recursionCount := recursionCount - 1).!

doReturn

	self decrementRecursionCount.
	((self recursionCount) = 0)
	ifTrue: [
		(self caseToCompare) restoreDescription.
		(self caseToCompare) flushDescriptionCopy.
		(self caseToCompare) flushStructureCopy.
	].

	caseCompare pop.
	route pop.
	currNorm := (currNorm predecessor).
	^self.!

incrementRecursionCount

	^(recursionCount := recursionCount + 1).!

moveToNormWith: aDescriptor incrementValue: aNumber

	| tmpDesc retVal |

	currNorm := (self currNorm successorWith: aDescriptor).
	currNorm incrementNumCasesBy: aNumber.
	route push: ((currNorm descriptor) attribute).

	(self isCaseToInsertDescUsedUp)
	ifTrue: [

		(self currNorm) addSuccessor: (self caseToInsert).
		(self caseToInsert) addPredecessorWith: (self currNorm) and: (self currNorm descriptor value).

		route pop.
		currNorm := (currNorm predecessor).
		^self.

	].    "END (self isCaseToInsertDescUsedUp) ifTrue:"

	"Save current state of ciDesc, since a totally new checking process (with ciDesc) will take place, considering all description elements"
	tmpDesc := OrderedCollection new.
	self moveDescElementsFrom: (self caseToInsertDesc) to: tmpDesc.
	self getCaseDescription: (self caseToInsert).

	"Keep moving"
	retVal := (self processCase).

	"Set ciDesc and everything else to the current state"
	self moveDescElementsFrom: tmpDesc to: (self caseToInsertDesc). 
	self removeMatchingElementsInTheRouteFrom: ciDesc.
	route pop.
	currNorm := (currNorm predecessor).

	^retVal.!

processCase

	| d ix ixv ixvSuccessors succ  |

	"Discard from the case's description all descriptors whose attribute is already in the route"
	((self removeMatchingElementsInTheRouteFrom: ciDesc) isEmpty)
	ifTrue: [ ^self ].

	[ ciDesc isEmpty ] 
	whileFalse: [

		"Remove the first descriptor in the case-to-insert description"
		d := ciDesc removeFirst.

		"Search for an index with the label's value equal to d's attribute"
		ix := currNorm getIndexWith: (d attribute).
		(ix = nil)
		ifTrue: [

			"An index with d's value was not found. Must create a new one"
			ix := Index new.
			ix addLabel: (d attribute).
			ix addPredecessor: (self currNorm).
			(self currNorm) addSuccessor: ix.
			ixv := IndexValue new. 
			(ixv addValue: (d value) withSuccessor: (self caseToInsert)) = nil ifTrue: [^nil].
			ix addIndexValue: ixv.
			(self caseToInsert) addPredecessorWith: ix and: (d value) 

		] "END (ix =nil) ifTrue: "

		"(ix = nil)"
		ifFalse: [

			"An index with d's attribute was found. Find an index value with d's value"
			ixv := (ix getIndexValueWith: (d value)).
			(ixv = nil) 
			ifTrue: [ 

				"An index value was not found.  Create a new IndexValue and append the caseToInsert as successor"
				ixv := IndexValue new.
				(ixv addValue: (d value) withSuccessor: (self caseToInsert)) = nil ifTrue: [^nil].
				ix addIndexValue: ixv. 
				(self caseToInsert) addPredecessorWith: ix and: (d value) 

			] "END (ixv = nil) ifTrue:"

			"(ixv = nil) ifFalse: an IndexValue matching (d value) was found"
			ifFalse: [

				"Get the list of successors of the current IndexValue"
				ixvSuccessors :=  (ixv successors).

				"Each IndexValue MUST point to only one successor. If it doesn't, raise
				 an exception and get the hell out"
				((ixvSuccessors size) = 1)
				ifFalse: [ ^nil ].

				"Get the ONLY successor from the successors' list"
				succ := (ixvSuccessors first).

				"If successor is a NORM, set it as the new current norm and continue"
				(self isANorm: succ)
				ifTrue: [
					((self moveToNormWith: d incrementValue: 1) = nil) 
					ifTrue: [ ^nil ] 

				]    "END (self isANorm: succ) ifTrue:"

				"(self isANorm: succ)"
				ifFalse: [

					"If the successor is NOT a CASE, raise an exception and get the hell out. Else,
					 process the case-to-insert and case-to-compare accordingly"
					(self isACase: succ)
					ifFalse: [ ^nil ]
					ifTrue: [

						(ciDesc isEmpty)
						ifTrue: [ ((self processCICCWithCIDescEmpty: d index: ix indexValue: ixv successor: succ) = nil) ifTrue: [ ^nil ] ]
						ifFalse: [ ((self processCICCWithCIDescNotEmpty: d index: ix indexValue: ixv successor: succ) = nil) ifTrue: [ ^nil ] ].

					].    "END (self isACase: succ) ifTrue:"

				].    "END (self isANorm: succ) ifFalse"

			].    "END (ixv = nil) ifFalse:"

		].    "END (ix =nil) ifFalse:"

	].    "END [ciDesc isEmpty] whileFalse:"

	^self.!

processCICCWithCIDescEmpty: aDescriptor index: anIndex indexValue: anIndexValue successor: aSuccessor

	| norm CIInserted CCInserted |

	(self areDescriptionsEqualFor: (self caseToInsert) and: aSuccessor)
	ifTrue: [ ^(self processCICCWithCIDescNotEmpty: aDescriptor index: anIndex indexValue: anIndexValue successor: aSuccessor) ].

	CIInserted := false.
	CCInserted := false.

	norm := Norm new.
	norm addDescriptor: aDescriptor.
	norm addPredecessor: anIndex.
	norm incrementNumCasesBy: 2.

	caseCompare push: (anIndexValue removeSuccessor: aSuccessor).
	(self caseToCompare) prepareDescriptionWith: (caseInsert currentStructure).
	(self caseToCompare) removePredecessorWith: anIndex and: (aDescriptor value).

	anIndexValue addSuccessor: norm.

	route push: (norm descriptor attribute).
	currNorm := (self currNorm successorWith: aDescriptor).

	(self isCaseToInsertDescUsedUp)
	ifTrue: [

		(self currNorm) addSuccessor: (self caseToInsert).
		(self caseToInsert) addPredecessorWith: (self currNorm) and: (self currNorm descriptor value).
		CIInserted := true.
	].

	(self isCaseToCompareDescUsedUp)
	ifTrue: [ 

		(self currNorm) addSuccessor: (self caseToCompare).
		(self caseToCompare) addPredecessorWith: (self currNorm) and: (self currNorm descriptor value).
		CCInserted := true.

	].    "(self isCaseToCompareDescUsedUp) ifTrue:"

	self resetRecursionCount.

	((CIInserted = false) | (CCInserted = false))
	ifTrue: [ 
		self whenCCExists. ]
	ifFalse: [

		(self caseToCompare) restoreDescription.
		(self caseToCompare) flushDescriptionCopy.
		(self caseToCompare) flushStructureCopy.

		caseCompare pop.
		route pop.
		currNorm := (currNorm predecessor). ].

	^self.!

processCICCWithCIDescNotEmpty: aDescriptor index: anIndex indexValue: anIndexValue successor: aSuccessor
									
	| norm |

	norm := Norm new.
	norm addDescriptor: aDescriptor.

	"Both caseToInsert and caseToCompare will live together under this new norm. Thus
	increment the number of (underlying) cases for it by 2"
	norm incrementNumCasesBy: 2.

	"Remove the case-to-compare as successor from the IndexValue"
	caseCompare push: (anIndexValue removeSuccessor: aSuccessor).

	"Remove old index reference in the case-to-compare's index list"
	(self caseToCompare) prepareDescriptionWith: (caseInsert currentStructure).
	(self caseToCompare) removePredecessorWith: anIndex and: (aDescriptor value).

	anIndexValue addSuccessor: norm.
	norm addPredecessor: anIndex.
	route push: (anIndex label).
	currNorm := (self currNorm successorWith: aDescriptor).

	(self isCaseToCompareDescUsedUp)
	ifTrue: [ 

		(self currNorm) addSuccessor: (self caseToCompare).
		(self caseToCompare) addPredecessorWith: (self currNorm) and: (self currNorm descriptor value).
	].

	self resetRecursionCount.
	^(self whenCCExists).!

removeRepeatingElementsInRouteFrom: aTable

	| i t |

	i := 1.
	[ i <= (aTable size) ]
	whileTrue: [

		t := (aTable at: i).
		((((self currNorm) getIndexWith: (t attribute) and: (t caseToInsertValue)) = nil) |
		 (((self currNorm) getIndexWith: (t attribute) and: (t caseToCompareValue)) = nil))
		ifFalse: [ aTable removeAtIndex: i ]
		ifTrue: [ i := i + 1 ].
	].

	^self.!

whenCCExists

	"Recursive method that makes description comparisons between a case to be inserted and a case found during net traversal.
	 Upon each call, a ComparingTable is created and it will contain tuples with every Descriptor in both case descriptions.  Next,
	 the comparison task begins by removing, one by one, each of the ComparingTableTuple's.  If the values for the given tuple
	 attribute are different, new indices are created and the cases are linked to them.  If the values for the given tuple are the same,
	 a new Norm is created and the method is invoked again to start a new Descriptor comparison.  The method stops when all the
	 tuples have been removed from the ComparingTable."

	| table tuple ix ixv norm d |

	self incrementRecursionCount.

	"Create a table with all the descriptors for both the case to insert and the case to compare"
	table := ComparingTable new.
	table fillWith: (self caseToInsert) and: (self caseToCompare).

	"Discard from the table all tuples whose attribute is already in the route"
	self removeMatchingElementsInTheRouteFrom: table.

	"If the resulting table is empty, then both (CC and CI) descriptions are already on the route. This means that,
	 at this point, both descriptions are equal and used up along the net traversing. Thus, no more traversing is
	 possible."
	(table isEmpty) ifTrue: [ 

		"Place the case-to-insert as successor of the current norm"
		(self currNorm) addSuccessor: (self caseToInsert).
		(self caseToInsert) addPredecessorWith: (self currNorm) and: (self currNorm descriptor value).

		"Place the case-to-compare as successor of the current norm"
		(self currNorm) addSuccessor: (self caseToCompare).
		(self caseToCompare) addPredecessorWith: (self currNorm) and: (self currNorm descriptor value).

		^self doReturn.
	].

	"At this point, the table CAN NOT be empty, and one of the following three situations is possible:
	 1. CI description is already used up, and CC description has at least one tuple lined up in the table;
	 2. CI description has at least one tuple lined up in the table, and CC description is used up;
	 3. There is at least one tuple in the table with CI and CC values."

	"Situation 1: If CI description is used up, place CI as successor of the current norm"
	(self isCaseToInsertDescUsedUp)
	ifTrue: [
		(self currNorm) addSuccessor: (self caseToInsert).
		(self caseToInsert) addPredecessorWith: (self currNorm) and: (self currNorm descriptor value).
	].

	"Situation 2: If CC description is empty, place CC as successor of the current norm"
	(self isCaseToCompareDescUsedUp)
	ifTrue: [
		(self currNorm) addSuccessor: (self caseToCompare).
		(self caseToCompare) addPredecessorWith: (self currNorm) and: (self currNorm descriptor value).
	].

	"Situation 3: Compare each table tuple"
	[ (tuple := table extractTuple) = nil ] 
	whileFalse: [

		"Create a new index and label it with the tuple's attribute"
		ix := Index new.
		ix addLabel: (tuple attribute).

		"Add the index to the current norm's index list"
		(self currNorm) addSuccessor: ix.

		"Set the index predecessor (current) norm"
		ix addPredecessor: (self currNorm). 

		"Check if the values for the tuple are different"
		((tuple caseToInsertValue) = (tuple caseToCompareValue))

		"Values are diferent. Create a new index using the tuple's attribute"
		ifFalse: [

			"If the case-to-insert value is non-nil, attach it to the index"
			((tuple caseToInsertValue) = nil) 
			ifFalse: [ 

				ixv := IndexValue new. 
				ixv addValue: (tuple caseToInsertValue) withSuccessor: (self caseToInsert).
				ix addIndexValue: ixv.

				"Add the index-and-value to the case's index list"
				(self caseToInsert) addPredecessorWith: ix and: (tuple caseToInsertValue) 

			].    "END ((tuple caseToInsertValue) = nil) ifFalse:"

			"If the case-to-compare value is non-nil, attach it to the index"
			((tuple caseToCompareValue) = nil) 
			ifFalse: [ 

				ixv := IndexValue new. 
				ixv addValue: (tuple caseToCompareValue) withSuccessor: (self caseToCompare).
				ix addIndexValue: ixv.

				"Add the index-and-value to the case's index list"
				(self caseToCompare) addPredecessorWith: ix and: (tuple caseToCompareValue) 

			].    "END ((tuple caseToCompareValue) = nil) ifFalse:"

		]    "END ((tuple caseToInsertValue) = (tuple caseToCompareValue)) ifFalse: ["

		"Tuple values are equal"
		ifTrue: [

			"Create an empty norm and fill its values"
			norm := Norm new.
			d := Descriptor new.
			d addAttribute: (tuple attribute) withValue: (tuple caseToInsertValue).
			norm addDescriptor: d.
			norm incrementNumCasesBy: 2.

			"Link the recently created index to this new norm"
			norm addPredecessor: ix.
			ixv := IndexValue new.
			ixv addValue: (tuple caseToInsertValue) withSuccessor: norm.
			ix addIndexValue: ixv.

			"Add the tuple's attribute to the route"
			route push: (tuple attribute).

			"Push a new case to compare"
			caseCompare push: (self caseToCompare).

			"Move to the new norm"
			currNorm := currNorm successorWith: d.

			"Repeat the procedure for the new case to compare"
			self whenCCExists.

			self removeRepeatingElementsInRouteFrom: table.

		]    "END ((tuple caseToInsertValue) = (tuple caseToCompareValue)) ifTrue: ["

	].    "END [ (tuple := table extractTuple) = nil ] whileFalse:["

	^self doReturn.! !

!RDNet methodsFor: 'testing'!

areDescriptionsEqualFor: aCase1 and: aCase2

	| desc2 d j |

	((self isACase: aCase1) & (self isACase: aCase2)) ifFalse: [ ^false ].

	"If the cases' descriptions are of different size, then they are not equal"
	((aCase1 description size) = (aCase2 description size)) ifFalse: [ ^false ].

	"Copy aCase2 description into desc2"
	desc2 := OrderedCollection new.
	1 to: (aCase2 description size) do:
		[:i | desc2 add: ((aCase2 description) at: i) ].

	"For every element in the description of aCase1: if its attribute-value pair matches one in desc2, then delete that element from desc2"
	1 to: (aCase1 description size) do:
		[: i |	d := (aCase1 description at: i).
			j := 1. 
			[ j <= (desc2 size) ]
			whileTrue: [
				(((d attribute) = ((desc2 at: j) attribute)) & ((d value) = ((desc2 at: j) value))) 
				ifTrue: [ (desc2 removeAtIndex: j). j := (desc2 size) + 1. ]
				ifFalse: [ j := j + 1. ].
			] 
		].

		"If the resulting desc2 is empty, then every element in aCase1 description matched with desc2. Thus, both descriptions are equal"
		(desc2 isEmpty) ifTrue: [ ^true ].

		"Descriptions are different by at least one element"
		^false.!

isACase: anObject

	^(((anObject class) name = (Case getClassName)) |
	  ((anObject class) name = (SAVCase getClassName))).!

isANorm: anObject

	^((anObject class) name = (Norm getClassName)).!

isCaseToCompareDescUsedUp

	| ccCopy i a |

	ccCopy := ((self caseToCompare) description) copyFrom: 1 to: ((self caseToCompare description) size).
	i := 1.
	[ i <= (ccCopy size) ]
	whileTrue: [
		a := (ccCopy at: i) attribute.
		(route includes: a)
		ifTrue: [ ccCopy removeAtIndex: i. i := 1 ]
		ifFalse: [ i := i + 1. ].
	].

	(ccCopy isEmpty) ifFalse: [ ^false ].
	^true.!

isCaseToInsertDescUsedUp

	| ccCopy i a |

	ccCopy := ((self caseToInsert) description) copyFrom: 1 to: ((self caseToInsert description) size).
	i := 1.
	[ i <= (ccCopy size) ]
	whileTrue: [
		a := (ccCopy at: i) attribute.
		(route includes: a)
		ifTrue: [ ccCopy removeAtIndex: i. i := 1 ]
		ifFalse: [ i := i + 1. ].
	].

	(ccCopy isEmpty) ifFalse: [ ^false ].
	^true.!

isDescOf: aCase1 aStrictlySmallerSubsetOfDescOf: aCase2

	| desc1 d j |

	((self isACase: aCase1) & (self isACase: aCase2)) ifFalse: [ ^false ].

	((aCase1 description size) >= (aCase2 description size)) ifTrue: [ ^false ].

	"Copy aCase1 description into desc1"
	desc1 := OrderedCollection new.
	1 to: (aCase1 description size) do:
		[:i | desc1 add: ((aCase1 description) at: i) ].

	1 to: (aCase2 description size) do:
		[:i |	d := (aCase2 description at: i).
			j := 1. 
			[ j <= (desc1 size) ] 
			whileTrue: [
				(((d attribute) = ((desc1 at: j) attribute)) & ((d value) = ((desc1 at: j) value))) 
				ifTrue: [	(desc1 removeAtIndex: j). j := (desc1 size) + 1 ]
				ifFalse: [ j := j + 1. ].

			]    "END [ j <= (desc1 size) ] whileTrue: ["

		].    "END [:i | d := (aCase2 description at: i)."

		"If the resulting desc1 is empty, then every element in desc1 was matched by elements of aCase2. Thus, the description of aCase1 is subset 
		 of the description of aCase2"
		(desc1 isEmpty) ifTrue: [ ^true ].

		"There is at least one element in desc1 that is not in the description of aCase2"
		^false.!

isDescOf: aCase1 subsetOfDescOf: aCase2

	| desc1 d j |

	((self isACase: aCase1) & (self isACase: aCase2)) ifFalse: [ ^false ].

	((aCase1 description size) > (aCase2 description size)) ifTrue: [ ^false ].

	"Copy aCase1 description into desc1"
	desc1 := OrderedCollection new.
	1 to: (aCase1 description size) do:
		[:i | desc1 add: ((aCase1 description) at: i) ].

	1 to: (aCase2 description size) do:
		[:i |	d := (aCase2 description at: i).
			j := 1. 
			[ j <= (desc1 size) ] 
			whileTrue: [
				(((d attribute) = ((desc1 at: j) attribute)) & ((d value) = ((desc1 at: j) value))) 
				ifTrue: [	(desc1 removeAtIndex: j). j := (desc1 size) + 1 ]
				ifFalse: [ j := j + 1. ].

			]    "END [ j <= (desc1 size) ] whileTrue: ["

		].    "END [:i | d := (aCase2 description at: i)."

		"If the resulting desc1 is empty, then every element in desc1 was matched by elements of aCase2. Thus, the description of aCase1 is subset 
		 of the description of aCase2"
		(desc1 isEmpty) ifTrue: [ ^true ].

		"There is at least one element in desc1 that is not in the description of aCase2"
		^false.! !

!RDNet methodsFor: 'matching'!

betterMatch
	"Llena el vector solucion con los casos que podrian resolver el problema."
	
	| str |
	route flush.
	solution flush.
	currNorm := root.

	self readProblemCase.

	self nextBestMatch.

	"Actualiza la solucion del caso problema"
	self problemCase solutionCases: self solution .
	
	str := ''.

	 1 to: ( problemCase solutionCases size ) do:
		[ :sol |  str := ( str,  ' ', (( problemCase solutionCases at: sol ) solution) ) ].


	( str = '' 	 )
		ifTrue: [  DialogView request:  'No hay solución' initialAnswer:''.]
		ifFalse:[  DialogView request:  'Posible solución: '  initialAnswer:  str .].

      ^self.!

computeWeights
	"Calcula los pesos correspondientes a cada (atributo, valor) del caso problema en la norma actual."
	
	| descriptorAct  indiceAct sucesor | 
      
	"Para cada par (atributo, valor) del caso problema "
     1 to: ( problemCase description size ) do:
         [ :caract | 
		descriptorAct := (problemCase description) at: caract.
	"	( ( ( (problemCase weightAt: caract )  = -1) not)  & ( (route containsTheObject: ( descriptorAct attribute ) ) not ) ) "
		( (route containsTheObject: ( descriptorAct attribute ) ) not ) 
			ifTrue:  [ 
           			 "Indice correspondiente a descriptor del caso problema." 
          		 	indiceAct :=  currNorm  getIndexWith: (descriptorAct attribute) and: (descriptorAct value).

				"Si el indice para el atributo del caso problema no existe"
           			 indiceAct = nil			
		           		ifTrue:   [  
						self problemCase weightsAt: caract  modifiedWith: -1 ]
          				ifFalse: [   

						"OJO: HAY QUE ARREGLAR ESTA PARTE"
						sucesor := indiceAct successors: (descriptorAct value).
						sucesor = nil
      	     	      			ifTrue:   [ 
								self problemCase weightsAt: caract  modifiedWith: -1 ]
          						ifFalse: [   
								( ( ( sucesor class) name =  Case getClassName) |
								  ( ( sucesor class) name =  SAVCase getClassName) )
 
									ifTrue:   [  self problemCase weightsAt:  caract  modifiedWith: 1 ]  " Es un caso "
          								ifFalse: [   
											  self problemCase weightsAt: caract  modifiedWith: ( sucesor numCases ).
											]  "Es una norma "

									]. "Existe indice pero no tiene valor "  
							 ].      " No existe indice "                        
               
					]. " Para cada descriptor del caso problema "
    		]. " Valor no es infinito ni atributo esta en ruta "
       ^self.!

gotDeadEnd: aNorm

	"Cuando ya no existen mas atributos  en el caso,  que guien la busqueda de la solución,  busca en los indices de la norma actual,  posibles soluciones que no contradigan al caso problema, de forma que los indices no hayan sido utilizados.
	aNorm : corresponde a la norma actual (utilizada en el backtracking)."

	| sucesoresIndice |

	1 to: ( (aNorm indices) size) do:
		[ :caract | 

			"Si no existe el atributo en el caso problema, es una posible ruta a visitar."
			( ( problemCase valueOf: ( ( aNorm indices at: caract ) label) ) = nil )
				ifTrue: [
					sucesoresIndice := (aNorm indices at: caract ) successors.
					1 to: (sucesoresIndice size) do:
						[ :sucesor | 

							( ( ( ( ( (sucesoresIndice at: sucesor) successor ) class ) name )  = Case getClassName) | 
							  ( ( ( ( (sucesoresIndice at: sucesor) successor ) class ) name )  = SAVCase getClassName) )

								ifTrue: [  "Si es un caso hay que propornerlo como solucion."

									self solution add: ((sucesoresIndice at: sucesor)  successor ) for: self problemCase.
									] "Es un caso."

								ifFalse: [ "Si es una norma hay con continuar buscando casos bajo esta norma."
									self gotDeadEnd: ( (sucesoresIndice at: sucesor) successor ).
									]. "Es una norma."

						]. "Para cada sucesor del indice. "
						
					]. "Existen indices no definidos para el caso problema"
		]. "Para todos los indices de la norma actual"!

lowestWeight
	"Devuelve el indice del menor de los pesos del caso problema de forma que el atributo asociado no este en la ruta actual.
	 Si no existe un mínimo válido (es decir diferente de -1 y que no pertenece a la ruta) devuelve nil."

	| posicion  min valor |

	posicion := 0.
	min := root numCases.

	1 to: (problemCase description size)  do:
		[ :i |   valor := (self problemCase weightAt:  i ).
			( ( (route containsTheObject:  ( ( self problemCase description) at: i ) attribute) not)  & 
				( valor <= min)    &	( ( valor = -1 ) not ) )
				ifTrue: [	min := valor.
						posicion := i.
					] "Encontramos un nuevo minimo"
		]. "Para cada uno  de los pesos de los descriptores del caso problema "

	posicion = 0
		ifTrue: [^nil ].
	^posicion.!

nextBestMatch
	"Busca el siguiente mejor caso para solucionar el problema"

	| posMasPredictivo indicePredictivo  descriptorMasPredictivo sucesorIndice |

	self computeWeights.
	posMasPredictivo :=  self lowestWeight.

	(( posMasPredictivo = nil ) not )
		ifTrue: [
				descriptorMasPredictivo := ( ( problemCase description ) at: posMasPredictivo).

        			"Indice correspondiente al descriptor mas predictivo del caso problema." 
          		 	indicePredictivo := currNorm getIndexWith: (descriptorMasPredictivo attribute) 
												and: (descriptorMasPredictivo value).

				"OJO: HAY QUE ARREGLAR ESTA PARTE"
				sucesorIndice := indicePredictivo successors: (descriptorMasPredictivo value).

				( ( ( ( sucesorIndice class) name ) = Case getClassName) |
				  ( ( ( sucesorIndice class) name ) = SAVCase getClassName) )

					ifTrue: [  "Es un caso. "
							route push: ( descriptorMasPredictivo attribute ).

							"Como la red es redundantisima no es necesario utilizar mas de una vez un atributo
						 	self problemCase weightsAt: posMasPredictivo  modifiedWith: -1."

							solution add: sucesorIndice for:  problemCase.
							posMasPredictivo :=  self lowestWeight.
							(( posMasPredictivo = nil ) not )
								ifTrue: [
										"self route flush."
										currNorm := root.
										self nextBestMatch.																															
									]. "Existen par(es) en el casoProblema que no han sido usados"
							
							] "Si el indice lleva a un caso"

					ifFalse: [	
							"El indice me lleva a una norma"
							route push: ( descriptorMasPredictivo attribute).

							"Como la red es redundantisima no es necesario utilizar mas de una vez un atributo"
						 	problemCase weightsAt: posMasPredictivo  modifiedWith: -1.

							currNorm := sucesorIndice.
							self nextBestMatch.																															

						]. "Si el indice lleva a una norma"  				

			] "Existe indice mas predictivo"

		ifFalse: [ "Los atributos restantes no tienen valor en la memoria de casos"
				"Hay que guiar al usuario para descubrir que mas sabe 
				Si sabe algo mas => metodo de preguntas.  Actualice la norma actual."
				
				"Cuando el usuario ya no sabe nada mas, saque todos los casos hacia abajo de la norma actual"
				self gotDeadEnd: currNorm.
				
				"Verifique si aun quedan atributos del caso problema sin usar"
				
				currNorm := root.
				self computeWeights.
				posMasPredictivo :=  self lowestWeight.

				(( posMasPredictivo = nil ) not )
					ifTrue: [
						self nextBestMatch.																															
						].
			]. "Los atributos restantes no tienen valor en la memoria de casos"
	^self!

readProblemCase
	"Permite leer y buscar la solucuón para un nuevo caso problema."
	
	| indicesRaiz  valor valorSimbolo desc |
	indicesRaiz := self root indices.

	"Limpia el vector de deficion del csao problema"
	problemCase flush.

	desc := Descriptor new.

	1 to: (indicesRaiz size) do:
		[ :i| 
			valor :=  ( DialogView request: ( ( indicesRaiz at: i ) label ) initialAnswer: '' ).
			valor = ''
				ifFalse: [
					( ( ( ( ( indicesRaiz at: i ) successors at: 1) value)  class) name = #ByteSymbol) 
						ifTrue:[ 
							valorSimbolo :=  valor asSymbol.
							]
						ifFalse:[ 
							valorSimbolo :=  valor asNumber.
							].

					desc addAttribute: (  (indicesRaiz at: i ) label)  withValue: valorSimbolo.
					( self problemCase) addToDescription: desc.

					].  "Si valor no es vacio."
		]. "Para cada indice."

	^self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RDNet class
	instanceVariableNames: ''!


!RDNet class methodsFor: 'instance creation'!

new

	| net |

	net := super new.
	^net initialize.! !

Object subclass: #Norm
	instanceVariableNames: 'descriptor successors predecessorIndex numCases '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Main'!
Norm comment:
'Norm

Purpose: Structure that groups (generalizes) a set of cases that share a common Descriptor.  Such cases may be
linked directly to the norm (when the cases'' descriptions terminate at the Norm), or accessed via indices.  A Norm
may NOT directly point to another Norm.

IMPORTANT NOTES: 
1. There shall be no Index or Case duplication in the Norm''s list of successors.
3. A Norm may exist only in the context of a net.
4. The only valid predecessor for an Norm is either an Index.

Messages with subclassResponsibility: None.

Instance variables:
descriptor: An instance of Descriptor depicting the grouping (generalizing) concept.
successors: A list (OrderedCollection) of items directly linked to the Norm, i.e, cases or indices.
predecessorIndex: Pointer to the Norm''s parent Index .
numCases: Number of cases grouped by the Norm, whether linked directly or located levels below.

Class variables: None.
'!


!Norm methodsFor: 'initializing'!

initialize

	descriptor := Descriptor new.
	successors := OrderedCollection new.
	predecessorIndex := nil.
	numCases := 0.
	^self.! !

!Norm methodsFor: 'adding'!

addDescriptor: aDescriptor

	"Sets the variable descriptor with the value of aDescriptor"

	(self isDescriptorArg: aDescriptor) ifFalse: [ descriptor setDefaults. ^nil. ].
	descriptor addAttribute: aDescriptor attribute withValue: aDescriptor value.
	^self.!

addPredecessor: anIndex

	((anIndex class) name = Index getClassName) ifFalse: [ ^nil ].
	^predecessorIndex := anIndex.!

addSuccessor: aSuccessor

	| i |

	"Make sure that an identical object hasn't already been included"
	(successors includes: aSuccessor) ifTrue: [ ^nil. ].

	"If aSuccessor is an Index, make sure that all Index-labels are unique"
	((aSuccessor class name) = (Index getClassName)) 
	ifTrue: [

		i := 1.
		[ i <= successors size ]
		whileTrue: [

			(((successors at: i) class name) = (Index getClassName))
			ifFalse: [ i := i + 1 ]
			ifTrue: [ (((successors at: i) label) = (aSuccessor label))
					ifTrue: [ ^nil ]
					ifFalse: [ i := i + 1 ] ].

		]    "END [ i <= successors size ] whileTrue: ["

	].    "END ((aSuccessor class name) = (Index getClassName)) ifTrue: ["

	successors add: aSuccessor.
	^self.!

incrementNumCasesBy: anInteger

	numCases := (numCases + anInteger).! !

!Norm methodsFor: 'accessing'!

descriptor

	^descriptor.!

numCases

	^numCases!

successors

	^successors.! !

!Norm methodsFor: 'testing'!

isDescriptorArg: aDescriptor

	^((aDescriptor class) name = Descriptor getClassName)!

isRoot

	"Si la norma es la raiz devuelve true, de lo contrario devuelve false ."

	^ (self descriptor attribute = nil).! !

!Norm methodsFor: 'navigating'!

predecessor

	(predecessorIndex = nil) ifTrue: [ ^self ].
	^(predecessorIndex predecessor).!

successorCases

	"This method returns a collection of cases that are immediate successors of this Norm.  That is, all retrieved cases 
	are generalized by the Norm's Descriptor"

	| i s |

	s := OrderedCollection new.

	i := 1.
	[ i <= successors size ]
	whileTrue: [

		((((successors at: i) class name) = (Case getClassName)) | (((successors at: i) class name) = (SAVCase getClassName)))
		ifTrue: [ s add: (successors at: i) ].
		i := i + 1. ].
	^s.!

successorWith: aDescriptor

	"Given a Descriptor, this method searches for an Index that matches the attribute-value parameters, and returns:
		- the successor Norm, or
		- nil, otherwise"

	| ix |

	((aDescriptor class) name = Descriptor getClassName) |
	((aDescriptor class) name = SAVDescriptor getClassName)
	ifFalse: [ ^nil ].

	ix := self getIndexWith: aDescriptor attribute.
	(ix = nil) ifFalse: [ ^self getSuccessorNormFor: ix With: aDescriptor value ].

	^nil.! !

!Norm methodsFor: 'searching'!

getIndexWith: aLabel

	| i |

	((aLabel class) name = #ByteSymbol) ifFalse: [ ^nil ].

	i := 1.
	[ i <= successors size ]
	whileTrue: [

		(((successors at: i) class name) = (Index getClassName))
		ifTrue: [ (aLabel = (successors at: i) label) ifTrue: [ ^(successors at: i) ] ].
		i := i + 1. ].
	^nil.!

getIndexWith: anAttribute and: aValue

	| i |

	((anAttribute class) name = #ByteSymbol) ifFalse: [ ^nil ].

	i := 1.
	[ i <= successors size ]
	whileTrue: [

		(((successors at: i) class name) = (Index getClassName))
		ifTrue: [ 
			((anAttribute = (successors at: i) label) & ((((successors at: i) getIndexValueWith: aValue) = nil) not)) 
			ifTrue: [ ^(successors at: i) ] ].
		i := i + 1. ].
	^nil.!

getSuccessorFor: anIndex With: aValue

	((anIndex class) name = Index getClassName) ifFalse: [ ^nil ].
	^anIndex successors: aValue.!

getSuccessorNormFor: anIndex With: aValue

	| succ |

	((anIndex class) name = Index getClassName) ifFalse: [ ^nil ].

	succ := anIndex successors: aValue.
	((succ size) = 1) ifFalse: [ ^nil. ].

	(succ first class name) = (Norm getClassName) ifFalse: [ ^nil ].
	^(succ first)! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Norm class
	instanceVariableNames: ''!


!Norm class methodsFor: 'instance creation'!

new

	"Creates a new, empty norm"

	| norm |

	norm := super new.
	norm initialize.
	^norm.! !

!Norm class methodsFor: 'class name'!

getClassName

	"Returns the Norm class name"

	^#Norm.! !

Object subclass: #Index
	instanceVariableNames: 'label successors predecessorNorm '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Main'!
Index comment:
'Index

Purpose: Structure that points to one or more Case''s or Norm''s, according to: 
a) an attribute, and 
b) a set of values that the attribute may have.  

The identifier of an Index is its label, that is, the attribute name (e.g., shape, color). The elements pointed to are packed 
in instances of IndexValue, and placed in a list. 

IMPORTANT NOTES: 
1. There must be at least one IndexValue for each Index.
2. There shall be no value duplication in the Index''s set of IndexValue''s.
3. An index may exist only in the context of a net.
4. The only valid predecessor for an Index is either a Norm or net root.

Messages with subclassResponsibility: None.

Instance variables:
label: A Symbol that represents an attribute.
successors: List of IndexValues, each pointing to a case or a norm.
predecessorNorm: Pointer to the Index''s predecessor norm.

Class variables: None.'!


!Index methodsFor: 'initializing'!

clear

	"Clears and resets the Index's instance variables"

	label := #''.
	[successors isEmpty] whileFalse: [ successors removeFirst ].
	predecessorNorm := nil.
	^self.!

initialize

	label := Symbol new.
	successors := OrderedCollection new.
	predecessorNorm := nil.
	^self.! !

!Index methodsFor: 'adding'!

addIndexValue: anIndexValue

	| ixv i |

	"If argument is not an IndexValue, or if argument contains invalid data, do not add"
	((anIndexValue class) name = IndexValue getClassName) ifFalse: [ ^nil ].
	 (anIndexValue isValid) ifFalse: [ ^nil ].

	"If argument is already included, do not add"
	(self isValueIncluded: anIndexValue value) |
	(self isSuccessorIncluded: anIndexValue successors) ifTrue: [ ^nil ].

	ixv := IndexValue new.
	((ixv addValue: (anIndexValue value) withSuccessor: (anIndexValue successors first)) = nil) ifTrue: [ ^nil ].
	i := 2.
	[ i <= (anIndexValue successors size) ]
	whileTrue: [ ixv appendSuccessor: ((anIndexValue successors) at: i). i := i + 1. ].

	successors add: ixv.
	^self.!

addLabel: aLabel

	((aLabel class) name = #ByteSymbol) ifFalse: [ self clear. ^nil ].
	^label := aLabel.!

addPredecessor: aNorm

	"IMPORTANT NOTE: The only valid predecessor for an INDEX  is either a Norm or net root"
	^predecessorNorm := aNorm.! !

!Index methodsFor: 'testing'!

isSuccessorIncluded: aSuccessorList

	"All successors of an Index are represented by instances of IndexValue, which have the form: (val, succ ) | ( val, succ1, ..., succN ).
	 A successor succ may be a Norm, a Case, or a set of Cases. Since the number of successors for an IndexValue may vary (i.e., one or more),
	then, IndexValue returns them in a collection.  

	Returns: true -  if there is at least ONE succesor, that belongs to any of the IndexValue successor lists, that matches an element in aSuccessorList;
			 false - if there is no match; i.e., ALL elements in aSuccessorList are new."

	| s |

	1 to: successors size do:
		[:i | 
			s := (successors at: i) successors.
			1 to: aSuccessorList size do:
				[:j |
					(s includes: (aSuccessorList at: j)) ifTrue: [ ^true ] ] ].
	^false.!

isValueIncluded: aValue

	1 to: successors size do:
		[:i | aValue = ((successors at: i) value) ifTrue: [^true]].
	^false! !

!Index methodsFor: 'accessing'!

label

	^label.!

successors

	^successors.! !

!Index methodsFor: 'navigating'!

predecessor

	^predecessorNorm.!

successors: aValue

	1 to: successors size do:
		[:i | aValue = ((successors at: i) value) ifTrue: [^((successors at: i) successors)]].
	^nil.! !

!Index methodsFor: 'searching'!

getIndexValueWith: aValue

	(successors isEmpty) ifTrue: [ ^nil ].

	1 to: (successors size) do:
	[:i | ((successors at: i) value = aValue) ifTrue: [ ^(successors at: i) ] ].
	^nil.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Index class
	instanceVariableNames: ''!


!Index class methodsFor: 'instance creation'!

new

	| index |

	index := super new.
	index initialize.
	^index.! !

!Index class methodsFor: 'class name'!

getClassName

	^#Index.! !

Norm subclass: #Root
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Main'!
Root comment:
'Root

Purpose: Specialization of a Norm, and its mission is to act as a net''s entry point.  The two most important features of a Root
are: 1. it does not have a predecessor, and 2. its Descriptor is of the form ( nil nil ).

Messages with subclassResponsibility: None.

Instance variables: None.

Class variables: None.'!


!Root methodsFor: 'adding'!

addDescriptor: aDescriptor

	^nil.!

addPredecessor: anIndex

	^nil.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Root class
	instanceVariableNames: ''!


!Root class methodsFor: 'class name'!

getClassName

	^#Root.! !

Object subclass: #Case
	instanceVariableNames: 'description solution justification predecessors status '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Main'!
Case comment:
'Case

Purpose:  A case is a representation of a situation, whereby a description (i.e., a set of Descriptor''s) and a solution illustrate how a particular
problem was solved.  Besides, a justification explains the reasons for solving the case.  When a case (problem) is resolved, it is added to a
net for future reference via heuristic search methods.

Messages with subclassResponsibility:
currentStructure - implemented by SAVCase.
flushDescriptionCopy - implemented by SAVCase.
flushStructureCopy - implemented by SAVCase.
prepareDescriptionWith: - implemented by SAVCase.
restoreDescription - implemented by SAVCase.

Instance variables:
description: A list containing a set of Descriptor''s (a description of the problem);
solution: An object that represents the solution to the case.  Such object may be a text string, or a compund object with more associated information.
justification: A list containing a set of Descriptor''s (the solution path of the case, i.e., the result of the traversal across the net and other reference structures).
predecessors: A list containing links to the case''s predecessor norms and/or indices within the net.
status: A case may be "positive" (i.e., the given solution is correct) or "negative" (i.e., the given solution is incorrect).  The status indicates (with the
symbols + and -) such degrees of correctness, thus providing valuable information to the case-searching methods.  If a case has not been corroborated,
its default status is P (for Pending).

Class variables: None.'!


!Case methodsFor: 'initializing'!

initialize

	"Sets a new case's instance variables to initial values.
	 NOTE: Default value for a new case's status: #P
	 Returns: nil - if an error occurred while assigning a value to status;
	              self - if everything''s OK."

	description := OrderedCollection new.
	solution := nil.
	justification := OrderedCollection new.
	predecessors := OrderedCollection new.
	status := Symbol new.
	(self setStatusWith: #P) = nil ifTrue: [ ^nil ].
	^self.! !

!Case methodsFor: 'adding'!

addPredecessorWith: aPredecessor and: aValue

	"Argument aPredecessor can be an Index or a Norm"

	| ixv |

	ixv := OrderedCollection new.
	ixv add: aValue.
	ixv add: aPredecessor.
	^predecessors add: ixv.!

addToDescription: aDescriptor

	"Appends aDescriptor to the variable description"

	| descriptor |

	(self isDescriptorArg: aDescriptor) ifFalse: [ ^nil ].
	(self isDescriptionMember: aDescriptor) ifTrue: [ ^nil ].

	descriptor := Descriptor new.
	descriptor addAttribute: aDescriptor attribute withValue: aDescriptor value.
	description add: descriptor.
	^self.!

addToJustification: aDescriptor

	"Appends aDescriptor to the variable description"

	| descriptor |

	(self isDescriptorArg: aDescriptor) ifFalse: [ ^nil ].
	(self isJustificationMember: aDescriptor) ifTrue: [ ^nil ].

	descriptor := Descriptor new.
	descriptor addAttribute: aDescriptor attribute withValue: aDescriptor value.
	justification add: descriptor.
	^self.!

setSolutionWith: aSolution

	"Adds an instance of a case solution. In order to view and process this solution, the methods 
	to be invoked are those belonging to the argument aSolution."

	solution := aSolution.
	^self.!

setStatusWith: aStatus

	"Sets a case's status with the value of aStatus.
	 NOTE: The only possible values for status are: 
		#P : for a pending case;
		#+ : for a successfully resolved case;
		 #- : for an unsuccessfully resolved case.
 	      #'' : for bad input.
	 Returns: nil - if the value of sStatus is invalid;
		        self - if OK."

	((aStatus = #P) | (aStatus = #+) | (aStatus = #-)) ifFalse: [ status := #''. ^nil. ].
	status := aStatus.
	^self.! !

!Case methodsFor: 'accessing'!

description

	"Returns the list of descriptors in the variable description"

	^description.!

justification

	"Returns the value of the variable justification"

	^justification.!

predecessors

	"Returns the value of the variable predecessorIndices"

	^predecessors.!

solution

	"Returns the value of the variable solution"

	^solution.!

status

	"Returns the value of the variable status"

	^status.! !

!Case methodsFor: 'testing'!

isDescriptionMember: aDescriptor

	^description includes: aDescriptor.!

isDescriptorArg: aDescriptor

	^((aDescriptor class) name = Descriptor getClassName)!

isJustificationMember: aDescriptor

	^justification includes: aDescriptor.!

isNegative

	^(status = #-)!

isPending

	^(status = #P)!

isPositive

	^(status = #+)!

isStatusUnknown

	^(((status = #P) | (status = #+) | (status = #-)) not).! !

!Case methodsFor: 'resetting'!

flush

	"Clears and resets all of the case's instance variables"

	self flushDescription.
	solution := nil.
	[ justification isEmpty ] whileFalse: [ justification removeFirst ].
	[ predecessors isEmpty ] whileFalse: [ predecessors removeFirst ].
	(self setStatusWith: #P) = nil ifTrue: [ ^nil ].
	^self.!

flushDescription

	"Clears the case's description list"

	[ description isEmpty ] whileFalse: [ description removeFirst ].
	^self.! !

!Case methodsFor: 'removing'!

removePredecessorWith: aPredecessor and: aValue

	1 to: (predecessors size) do:
		[:i | (((predecessors at: i) first = aValue) & ((predecessors at: i) last = aPredecessor))
			ifTrue: [ ^(predecessors removeAtIndex: i) ] ].

	^nil.! !

!Case methodsFor: 'special'!

currentStructure

	"Implemented by SAVCase.  For polymorphism reasons, this method is needed by Case, since a net may be composed of Case's or SAVCase's"

	^self.!

flushDescriptionCopy

	"Implemented by SAVCase.  For polymorphism reasons, this method is needed by Case, since a net may be composed of Case's or SAVCase's"

	^self.!

flushStructureCopy

	"Implemented by SAVCase.  For polymorphism reasons, this method is needed by Case, since a net may be composed of Case's or SAVCase's"

	^self.!

prepareDescriptionWith: aStructure

	"Implemented by SAVCase.  For polymorphism reasons, this method is needed by Case, since a net may be composed of Case's or SAVCase's"

	^self.!

restoreDescription

	"Implemented by SAVCase.  For polymorphism reasons, this method is needed by Case, since a net may be composed of Case's or SAVCase's"

	^self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Case class
	instanceVariableNames: ''!


!Case class methodsFor: 'instance creation'!

new

	"Creates a new case"

	| case | 

	case := super new.
	(case initialize) = nil ifTrue: [ ^nil ].
	^case.! !

!Case class methodsFor: 'class name'!

getClassName

	"Returns the Case class name"

	^#Case.! !

OrderedCollection variableSubclass: #Descriptor
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Main'!
Descriptor comment:
'Descriptor

Purpose:  List that represents the pair attribute x value.  A Descriptor is used to create case descriptions, and as generalizing concepts in norms.
All net roots (specializations of Norm''s) contain a Descriptor of the form (nil, nil), since no particular attribute x value pair generalizes all the cases 
underneath them.

Upon creation, a Descriptor is of the form: ( nil nil ).

Messages with subclassResponsibility: None.

Instance variables: None.

Class variables: None.'!


!Descriptor methodsFor: 'initializing'!

clear

	"Sets self to default values: self = (nil, nil)"

	[ self isEmpty ] whileFalse: [ self removeFirst ].
	^self initialize.!

initialize

	"Class instance invariant: self MUST always have exactly two values. The first
	 element corresponds to the descriptor's attribute, and the second one to the value.
	 Extreme care should be taken when using this method, as it assumes an empty self."

	self add: nil.
	self add: nil.
	^self.! !

!Descriptor methodsFor: 'adding'!

addAttribute: anAttribute withValue: aValue

	"Precondition: self = (nil, nil), or self = (a, v)"
	(self addAttribute: anAttribute) = nil ifTrue: [ ^nil ].

	"Postcondition: self = (nil, nil), or self = (anAttribute, aValue)"
	^self addValue: aValue.! !

!Descriptor methodsFor: 'accessing'!

attribute

	^self first.!

value

	^self last.! !

!Descriptor methodsFor: 'adding-private'!

addAttribute: anAttribute

	"Precondition: anAttribute MUST be a ByteSymbol, and self first = (nil or a)"
	((anAttribute class) name = #ByteSymbol) ifFalse: [ self clear. ^nil ].

	"Postcondition: self = (nil, nil), or self first = anAttribute"
	self removeFirst.
	^self addFirst: anAttribute.!

addValue: aValue

	"Precondition: self last = (nil or v)"
	self removeLast.

	"Postcondition: self last = aValue"
	^self addLast: aValue.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Descriptor class
	instanceVariableNames: ''!


!Descriptor class methodsFor: 'instance creation'!

new

	"Creates a new descriptor"

	| descriptor |

	descriptor := super new.
	descriptor initialize.
	^descriptor.! !

!Descriptor class methodsFor: 'class name'!

getClassName

	"Returns the Descriptor class name"

	^#Descriptor.! !

