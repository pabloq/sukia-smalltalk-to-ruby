OrderedCollection variableSubclass: #HintsList
	instanceVariableNames: 'percentageItemsProcessed '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Search Hints Lists'!


!HintsList methodsFor: 'initializing'!

initialize

	^(self resetPercentageItemsProcessed).! !

!HintsList methodsFor: 'accessing'!

percentageItemsProcessed

	^percentageItemsProcessed.! !

!HintsList methodsFor: 'adding'!

percentageItemsProcessed: aNumber

	percentageItemsProcessed := (aNumber asFloat).
	^self.! !

!HintsList methodsFor: 'resetting'!

resetPercentageItemsProcessed

	percentageItemsProcessed = 0.0.
	^self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HintsList class
	instanceVariableNames: ''!


!HintsList class methodsFor: 'instance creation'!

new

	| hl |

	hl := super new.
	hl initialize.
	^hl.! !

!HintsList class methodsFor: 'class name'!

className

	^#HintsList.! !

HintsList variableSubclass: #FrequentGroupingHeuristicList
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Search Hints Lists'!


!FrequentGroupingHeuristicList methodsFor: 'private'!

sortList: aHeuristicsList withBlock: aSortBlock

	"This method takes as argument a list of grouping heuristics (each with a value), and sorts them according
	to their success or failure rate when compared to the elements in self.  The process is as follows: 1. all grouping 
	heuristics that can be compared against the elements in self are first introduced in a temporary list (i.e., tempList), 
	while the corresponding references in self are passed to a SortedCollection (which is setup to sort by success or
	failre frequency -- the sort block).; 2. all elements in the argument list that can NOT be compared against the elements 
	in self are stored in another temporary list (i.e., leftOvers); 3. all elements in tempList are put back into the argument list, 
	BUT in the order dictated by the references in the SortedCollection; 4. all elements in the list called LeftOvers are 
	appended to the end of the argument list.

	PRECONDITION: (self isEmpty not) and (aHeuristicsList isEmpty not)

	RETURNS:	An empty list if either self or the argument list are empty;
				The argument list possibly sorted by (success or failure) frequency."

	| gh sortedList leftOvers ghElt tempList i numElements numProcessedElts |

	"First thing is to set the number of processed items to 0"
	self resetPercentageItemsProcessed.

	tempList := OrderedCollection new.

	"Check precondition"
	((self isEmpty) | (aHeuristicsList isEmpty))
	ifTrue: [ ^tempList ].

	numElements := aHeuristicsList size.
	sortedList := SortedCollection new.
	sortedList sortBlock: aSortBlock.
	leftOvers := OrderedCollection new.

	[aHeuristicsList isEmpty]
	whileFalse: [
		gh := aHeuristicsList removeFirst.
		ghElt := self isMember: gh.
		(ghElt = nil)
		ifTrue: [ leftOvers add: gh ]
		ifFalse: [ tempList add: gh. sortedList add: ghElt. ].
	].

	"Get the number of elements to be processed"
	numProcessedElts := tempList size.

	[sortedList isEmpty]
	whileFalse: [ 
		ghElt := sortedList removeFirst.
		i := 1.
		[i <= (tempList size)] whileTrue:
		[	((tempList at: i) name = ghElt groupingHeuristicName) & 
			((((tempList at: i) values at: (GroupingHeuristic oneLevel)) at: (GroupingHeuristic oneLevel)) value = ghElt value)
			ifTrue: [ aHeuristicsList add: (tempList removeAtIndex: i). i := tempList size ].
			i := i + 1.
		].
	].

	[leftOvers isEmpty]
	whileFalse: [ aHeuristicsList add: (leftOvers removeFirst) ].

	"Determine the percentage of processed elements and return the processed list"
	self percentageItemsProcessed: (numProcessedElts / numElements).
	^aHeuristicsList.! !

!FrequentGroupingHeuristicList methodsFor: 'sorting'!

sortByFailureCriteria: aHeuristicsList

	"Return the argument list sorted by (lowest) failure rate, if possible."

	^(self sortList: aHeuristicsList withBlock: [ :x :y | (x failureFrequency) <= (y failureFrequency) ]).!

sortBySuccessCriteria: aHeuristicsList

	"Return the argument list sorted by (highest) success rate, if possible."

	^(self sortList: aHeuristicsList withBlock: [ :x :y | (x successFrequency) >= (y successFrequency) ]).! !

!FrequentGroupingHeuristicList methodsFor: 'adding'!

add: aListElement

	| elt |

	(self isElementOK: aListElement) 
	ifFalse: [ ^nil ].

	(((aListElement successFrequency) < 1) &
	 ((aListElement failureFrequency) < 1))
	ifTrue: [ ^nil ].

	elt := self includes: aListElement.
	(elt = nil) ifTrue: [ super add: aListElement. ^self ].

	(aListElement successFrequency) > 0
	ifTrue: [ elt incrementSuccessFrequency ].

	(aListElement failureFrequency) > 0
	ifTrue: [ elt incrementFailureFrequency ].

	^self.! !

!FrequentGroupingHeuristicList methodsFor: 'testing'!

includes: aListElement

	1 to: self size do:
	[:i | 
		((self at: i) groupingHeuristicName = (aListElement groupingHeuristicName)) &
		((self at: i) value = (aListElement value))
		ifTrue: [ ^(self at: i) ] 
	].

	^nil.!

isElementOK: aListElement

	"Determines if OK to include aListElement in self (i.e., all elements in self must belong to a class that self can handle)
	Returns: TRUE - Element OK;
	             FALSE - Element not OK"
	^(aListElement whatList = self class className).!

isMember: aGroupingHeuristic

	1 to: self size do:
	[:i | 
		((self at: i) groupingHeuristicName = (aGroupingHeuristic name)) &
		((self at: i) value = (((aGroupingHeuristic values at: (GroupingHeuristic oneLevel)) at: (GroupingHeuristic oneLevel)) value))
		ifTrue: [ ^(self at: i) ] 
	].

	^nil.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FrequentGroupingHeuristicList class
	instanceVariableNames: ''!


!FrequentGroupingHeuristicList class methodsFor: 'class name'!

className

	^#FrequentGroupingHeuristicList.! !

HintsList variableSubclass: #SpecificStructureAttributeList
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Search Hints Lists'!


!SpecificStructureAttributeList methodsFor: 'testing'!

includes: aListElement

	"Determines if the argument's name (i.e., a Structure name or a SpecificStructureAttributeElt name)
	 is already included in self"

	1 to: self size do:
	[:i | 
		((self at: i) name = (aListElement name))
		ifTrue: [ ^(self at: i) ] 
	].

	^nil.!

isElementOK: aListElement

	"Determines if OK to include aListElement in self (i.e., all elements in self must belong to a class that self can handle)
	Returns: TRUE - Element OK;
	             FALSE - Element not OK"
	^(aListElement whatList = self class className).! !

!SpecificStructureAttributeList methodsFor: 'adding'!

add: aListElement

	"Performs one of two actions:
	 1. If the argument is not included in self (i.e., self is empty OR the argument's name is different from 
	     the names of all elements in self), then it is included as a new element in self.

	 2. If the argument already exists in self (i.e., self contains an element whose name is the same as the 
	     argument), then the attributes of the argument are either added to the attributes of the existing element 
	     in self, OR the frequency values are updated (in case attributes in the argument already exist for the element
	     in self."

	| elt |

	(self isElementOK: aListElement) 
	ifFalse: [ ^nil ].

	(aListElement attributes isEmpty)
	ifTrue: [ ^nil ].

	elt := self includes: aListElement.
	(elt = nil) ifTrue: [ super add: aListElement. ^self ].

	1 to: (aListElement attributes) do:
	[:i | elt specificAttribute: (aListElement attributes at: i) ].

	^self.! !

!SpecificStructureAttributeList methodsFor: 'sorting'!

sortBySuccessCriteria: aStructure

	"Return a structure's attribute list sorted by their frequency as indices to successful cases in the case memory."

	^(self sortList: aStructure withBlock: [ :x :y | (x frequency) >= (y frequency) ]).! !

!SpecificStructureAttributeList methodsFor: 'private'!

sortList: aStructure withBlock: aSortBlock

	"This method takes a structure as argument.  The structure's attributes may be sorted according to their 
	frequency (as successful top-level indices in the case memory), when compared against the SpecificAttributes
	belonging to a structure reference in self. The process is as follows:
	1. Determine if the name of the structure argument exists in self. If so, obtain the corresponding element from self. 
	    Else, return an empty list (because the structure's attributes can't be sorted).
	2. All structure attributes, that can be compared against the SpecificAttributes in the retrieved element from self, 
	   are introduced in a temporary list (i.e., tempList), while the corresponding SpecificAttributes are passed to a 
	   SortedCollection (which is setup to sort by frquency -- the sort block).
	3. All structure attributes that can NOT be compared against the SpecificAttributes are stored in another temporary 
	    list (i.e., leftOvers); 
	4. All structure attributes in tempList are put back into the structure's attribute list, BUT in the order dictated by the 
	   references in the SortedCollection; 
	5. All structure attributes in the list called LeftOvers are appended to the end of the structure's attribute list.

	PRECONDITION: (self isEmpty not) and (aStructure attributes isEmpty not)

	RETURNS:	An empty list, if either self or the list to be processed are empty;
				The attribute list of the structure, possibly sorted by frequency."

	| sortedList outList leftOvers tempList i a aElt s numElements numProcessedElts |

	"First thing is to set the number of processed items to 0"
	self resetPercentageItemsProcessed.

	tempList := OrderedCollection new.

	"Check precondition"
	((self isEmpty) | (aStructure attributes isEmpty))
	ifTrue: [ ^tempList ].

	numElements := aStructure attributes size.
	s := self includes: aStructure.
	(s = nil) ifTrue: [ ^tempList ].

	sortedList := SortedCollection new.
	sortedList sortBlock: aSortBlock.

	"Output list: all sorted attributes are stored in this list, as well as in the structure's attribute list.  However, outList
	 is the list to be returned as result from this process because the structure's attribute list is sorted by name (default)."
	outList := OrderedCollection new.
	leftOvers := OrderedCollection new.

	[aStructure attributes isEmpty]
	whileFalse: [
		a := aStructure attributes removeFirst.
		aElt := (s includesAttribute: a).
		(aElt = nil)
		ifTrue: [ leftOvers add: a ]
		ifFalse: [ tempList add: a. sortedList add: aElt. ].
	].

	"Get the number of elements to be processed"
	numProcessedElts := tempList size.

	[sortedList isEmpty]
	whileFalse: [ 
		aElt := sortedList removeFirst.
		i := 1.
		[i <= (tempList size)] whileTrue:
		[	((tempList at: i) name = aElt attribute)
			ifTrue: [ a := (tempList removeAtIndex: i). aStructure attributes add: a. outList add: a. i := tempList size ].
			i := i + 1.
		].
	].

	[leftOvers isEmpty]
	whileFalse: [ a := (leftOvers removeFirst). aStructure attributes add: a. outList add: a ].

	"Determine the percentage of processed elements and return the processed list"
	self percentageItemsProcessed: (numProcessedElts / numElements).
	^outList.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SpecificStructureAttributeList class
	instanceVariableNames: ''!


!SpecificStructureAttributeList class methodsFor: 'class name'!

className

	^#SpecificStructureAttributeList.! !

HintsList variableSubclass: #FrequentStructurePatternList
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Search Hints Lists'!


!FrequentStructurePatternList methodsFor: 'testing'!

includes: aListElement

	1 to: self size do:
	[:i | 
		((self at: i) structureName = (aListElement structureName))
		ifTrue: [ ^(self at: i) ] 
	].

	^nil.!

includesStructure: aStructure

	1 to: self size do:
	[:i | 
		((self at: i) structureName = (aStructure name))
		ifTrue: [ ^(self at: i) ] 
	].

	^nil.!

isElementOK: aListElement

	"Determines if OK to include aListElement in self (i.e., all elements in self must belong to a class that self can handle)
	Returns: TRUE - Element OK;
	             FALSE - Element not OK"
	^(aListElement whatList = self class className).! !

!FrequentStructurePatternList methodsFor: 'adding'!

add: aListElement

	| elt |

	(self isElementOK: aListElement) 
	ifFalse: [ ^nil ].

	((aListElement structureName) = nil)
	ifTrue: [ ^nil ].

	(aListElement frequentDescriptorPatternList isEmpty)
	ifTrue: [ ^nil ].

	elt := self includes: aListElement.
	(elt = nil) ifTrue: [ super add: aListElement. ^self ].

	1 to: (aListElement frequentDescriptorPatternList size) do:
	[:i | elt addPattern: (aListElement frequentDescriptorPatternList at: i) ].

	^self.! !

!FrequentStructurePatternList methodsFor: 'sorting'!

sortByFrequencyCriteria: anUnsortedList

	"Receives an unsorted list of Structures, each with a set of Attributes (i.e., the description of the Structure).
	Returns the same list but sorted (in descending order) according to the frequency of description patterns 
	found in the elements of self that are similar to the Structures' descriptions"

	^(self sortList: anUnsortedList withBlock: [ :x :y | 
		((x frequentDescriptorPatternList at: 1) frequency) >= ((y frequentDescriptorPatternList at: 1) frequency) ]).! !

!FrequentStructurePatternList methodsFor: 'private'!

convertAttributesToDescriptorsOf: aStructure

	| aDescriptorList a d vd |

	aDescriptorList := OrderedCollection new.

	1 to: aStructure attributes size do:
	[:i |
		a := aStructure attributes at: i.
		vd := a values valueDescriptors.
		(vd size > 1) ifTrue: [ ^nil ].

		d := Descriptor new.
		d addAttribute: a name withValue: (((vd at: Attribute oneLevel) at: Attribute oneLevel) value).
		aDescriptorList add: d.
	].

	^aDescriptorList.!

sortList: anUnsortedList withBlock: aSortBlock

	"This method takes as argument an unsorted list of Structures, and sorts them in according to the frequency rate
	of patterns in self that are similar or equal to the Structures' descriptions (i.e., their list of Attributes). The process 
	is as follows: 1. if the next Structure's name does not match the name of any the elements in self, such Structure 
	is added to a leftOvers list (i.e., a list that contains all Structures that can't be processed); 2. if the Structure's name 
	matches an element in self, the Structure's description is checked against the patterns contained in the retrieved 
	element from self, to determine if there is a similar pattern; 3. if there is a similar pattern, the Structure is stored in a 
	temporary list, and the element along with the pattern are stored in a sorted list (sort criteria: pattern frequency); 
	4. if no similar pattern is found, the Structure is added to the leftOvers list; 5. all Structures in the temporary list are
	added back to the argument list, according to the sort order dictated by the sorted list; 5. all Structures in the leftOvers 
	list are appended to the end of the argument list.

	PRECONDITION: (self isEmpty not) and (anUnsorted isEmpty not)

	RETURNS:	An empty list, if either self or the argument list are empty;
				The argument list possibly sorted by similar pattern frequency."

	| sortedList leftOvers tempList i s fsp descriptors p fspSinglePattern numElements numProcessedElts |

	"First thing is to set the number of processed items to 0"
	self resetPercentageItemsProcessed.

	tempList := OrderedCollection new.

	"Check precondition"
	((self isEmpty) | (anUnsortedList isEmpty))
	ifTrue: [ ^tempList ].

	numElements := anUnsortedList size.
	sortedList := SortedCollection new.
	sortedList sortBlock: aSortBlock.
	leftOvers := OrderedCollection new.

	[anUnsortedList isEmpty]
	whileFalse: [

		s := anUnsortedList removeFirst.
		fsp := self includesStructure: s.
		(fsp = nil) 
		ifTrue: [ leftOvers add: s ]
		ifFalse: [

			descriptors := self convertAttributesToDescriptorsOf: s.
			p := fsp whatPatternIsMostSimilarTo: descriptors.
			(p = nil)
			ifTrue: [ leftOvers add: s ]
			ifFalse: [

				tempList add: s.
				fspSinglePattern := FrequentStructurePatternElt new.
				fspSinglePattern structureName: fsp structureName.
				fspSinglePattern addPattern: p.
				sortedList add: fspSinglePattern.

			].    "END (p=nil) ifFalse:["

		].    "END (fsp=nil) ifFalse:["

	].    "END [anUnsortedList isEmpty] whileFalse: ["

	"Get the number of elements to be processed"
	numProcessedElts := tempList size.

	[sortedList isEmpty]
	whileFalse: [ 
		fspSinglePattern := sortedList removeFirst.
		i := 1.
		[i <= (tempList size)] whileTrue:[
			((tempList at: i) name = fspSinglePattern structureName)
			ifTrue: [ anUnsortedList add: (tempList removeAtIndex: i). i := tempList size ].
			i := i + 1.
		].
	].

	[leftOvers isEmpty]
	whileFalse: [ anUnsortedList add: (leftOvers removeFirst) ].

	"Determine the percentage of processed elements and return the processed list"
	self percentageItemsProcessed: (numProcessedElts / numElements).
	^anUnsortedList.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FrequentStructurePatternList class
	instanceVariableNames: ''!


!FrequentStructurePatternList class methodsFor: 'class name'!

className

	^#FrequentStructurePatternList.! !

HintsList variableSubclass: #WeightedList
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Search Hints Lists'!


!WeightedList methodsFor: 'testing'!

includes: aListElement

	1 to: self size do:
	[:i | 
		((self at: i) name = (aListElement name))
		ifTrue: [ ^(self at: i) ] 
	].

	^nil.!

isElementOK: aListElement

	"Determines if OK to include aListElement in self (i.e., all elements in self must belong to a class that self can handle)
	Returns: TRUE - Element OK;
	             FALSE - Element not OK"
	^(aListElement whatList = self class className).! !

!WeightedList methodsFor: 'adding'!

add: aListElement

	| elt |

	(self isElementOK: aListElement) 
	ifFalse: [ ^nil ].

	((aListElement accumulatedWeight) <= 0.0)
	ifTrue: [ ^nil ].

	elt := self includes: aListElement.
	(elt = nil) ifTrue: [ super add: aListElement. ^self ].

	elt accumulatedWeight: (aListElement accumulatedWeight).
	elt incrementNumberTaxa.

	^self.! !

!WeightedList methodsFor: 'sorting'!

sortBySuccessCriteria: anUnsortedList

	"Return the argument list sorted by (highest) mean weight, if possible.
	NOTE: The elements of anUnsortedList may be instances of ONE of the following classes:
	GroupingHeuristic or Structure."

	^(self sortList: anUnsortedList withBlock: [ :x :y | (x meanWeight) >= (y meanWeight) ]).! !

!WeightedList methodsFor: 'private'!

sortList: anUnsortedList withBlock: aSortBlock

	"This method takes as argument a list of EITHER grouping heuristics OR structures, and sorts them according
	to their mean weight when compared to the elements in self.  The process is as follows: 1. all elements that can 
	be compared against the elements in self are first introduced in a temporary list (i.e., tempList), while the corresponding 
	references in self are passed to a SortedCollection (which is setup to sort by mean weight -- the sort block).; 2. all elements 
	in the argument list that can NOT be compared against the elements in self are stored in another temporary list (i.e., leftOvers); 
	3. all elements in tempList are put back into the argument list, BUT in the order dictated by the references in the 
	SortedCollection; 4. all elements in the list called LeftOvers are appended to the end of the argument list.

	PRECONDITION: (self isEmpty not) and (anUnsorted isEmpty not)

	RETURNS:	An empty list, if either self or the argument list are empty;
				The argument list possibly sorted by mean weight."

	| sortedList leftOvers tempList i ule wlElt numProcessedElts numElements |

	"First thing is to set the number of processed items to 0"
	self resetPercentageItemsProcessed.

	tempList := OrderedCollection new.

	"Check precondition"
	((self isEmpty) | (anUnsortedList isEmpty))
	ifTrue: [ ^tempList ].

	numElements := anUnsortedList size.
	sortedList := SortedCollection new.
	sortedList sortBlock: aSortBlock.
	leftOvers := OrderedCollection new.

	[anUnsortedList isEmpty]
	whileFalse: [
		ule := anUnsortedList removeFirst.
		wlElt := self includes: ule.
		(wlElt = nil)
		ifTrue: [ leftOvers add: ule ]
		ifFalse: [ tempList add: ule. sortedList add: wlElt. ].
	].

	"Get the number of elements to be processed"
	numProcessedElts := tempList size.

	[sortedList isEmpty]
	whileFalse: [ 
		wlElt := sortedList removeFirst.
		i := 1.
		[i <= (tempList size)] whileTrue:
		[	((tempList at: i) name = wlElt name)
			ifTrue: [ anUnsortedList add: (tempList removeAtIndex: i). i := tempList size ].
			i := i + 1.
		].
	].

	[leftOvers isEmpty]
	whileFalse: [ anUnsortedList add: (leftOvers removeFirst) ].

	"Determine the percentage of processed elements and return the processed list"
	self percentageItemsProcessed: (numProcessedElts / numElements).
	^anUnsortedList.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WeightedList class
	instanceVariableNames: ''!


!WeightedList class methodsFor: 'class name'!

className

	^#WeightedList.! !

WeightedList variableSubclass: #WeightedStructureList
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Search Hints Lists'!

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WeightedStructureList class
	instanceVariableNames: ''!


!WeightedStructureList class methodsFor: 'class name'!

className

	^#WeightedStructureList.! !

WeightedList variableSubclass: #WeightedGroupingHeuristicList
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Search Hints Lists'!

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WeightedGroupingHeuristicList class
	instanceVariableNames: ''!


!WeightedGroupingHeuristicList class methodsFor: 'class name'!

className

	^#WeightedGroupingHeuristicList.! !

