Object subclass: #WeightedIndicator
	instanceVariableNames: 'indicatorName accumulatedWeight numberTaxa '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Search Hints Elts'!


!WeightedIndicator methodsFor: 'initializing'!

initialize

	indicatorName := nil.
	accumulatedWeight := 0.0.
	numberTaxa := 0.
	^self.! !

!WeightedIndicator methodsFor: 'accessing'!

accumulatedWeight 

	^accumulatedWeight.!

meanWeight 

	^(accumulatedWeight / numberTaxa).!

name

	^indicatorName.!

numberTaxa 

	^numberTaxa.! !

!WeightedIndicator methodsFor: 'adding'!

accumulatedWeight: aNumericValue

	accumulatedWeight := (accumulatedWeight + aNumericValue).
	^self.!

incrementNumberTaxa

	numberTaxa := (numberTaxa + 1).
	^self.!

name: anIndicatorName

	indicatorName := anIndicatorName.
	^self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WeightedIndicator class
	instanceVariableNames: ''!


!WeightedIndicator class methodsFor: 'instance creation'!

new

	| wi |

	wi := super new.
	wi initialize.
	^wi.! !

Object subclass: #FrequentGroupingHeuristicElt
	instanceVariableNames: 'groupingHeuristicName value successFrequency failureFrequency '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Search Hints Elts'!


!FrequentGroupingHeuristicElt methodsFor: 'accessing'!

failureFrequency

	^failureFrequency.!

groupingHeuristicName

	^groupingHeuristicName.!

successFrequency

	^successFrequency.!

value

	^value.! !

!FrequentGroupingHeuristicElt methodsFor: 'adding'!

groupingHeuristicName: aGroupingHeuristicName

	groupingHeuristicName := aGroupingHeuristicName.
	^self.!

incrementFailureFrequency

	failureFrequency := (failureFrequency + 1).
	^self.!

incrementSuccessFrequency

	successFrequency := (successFrequency + 1).
	^self.!

value: aValue

	value := aValue.
	^self.! !

!FrequentGroupingHeuristicElt methodsFor: 'initializing'!

initialize

	"Initialize the frequent grouping heuristic element.  The instance variable 'value' will NOT be an instance of Value,
	because (at least for now) it doesn't need to store extra information, such as value levels, weights or ranges. Thus,  
	the contents of the variable value will be a discreet symbol (no ranges)."

	groupingHeuristicName := nil.
	value := 0.
	successFrequency := 0.
	failureFrequency := 0.
	^self.! !

!FrequentGroupingHeuristicElt methodsFor: 'list membership'!

whatList

	^FrequentGroupingHeuristicList className.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FrequentGroupingHeuristicElt class
	instanceVariableNames: ''!


!FrequentGroupingHeuristicElt class methodsFor: 'instance creation'!

new

	| fgh |

	fgh := super new.
	fgh initialize.
	^fgh.! !

Object subclass: #FrequentStructurePatternElt
	instanceVariableNames: 'structureName frequentDescriptorPatternList '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Search Hints Elts'!


!FrequentStructurePatternElt methodsFor: 'accessing'!

frequentDescriptorPatternList

	^frequentDescriptorPatternList.!

structureName

	^structureName.! !

!FrequentStructurePatternElt methodsFor: 'adding'!

addPattern: aFrequentDescriptorPattern

	| fdp |

	fdp := self includes: (aFrequentDescriptorPattern pattern).
	(fdp = nil)
	ifTrue: [ frequentDescriptorPatternList add: aFrequentDescriptorPattern. ^self. ].

	fdp incrementFrequencyBy: (aFrequentDescriptorPattern frequency).
	^self.!

structureName: aStructureName

	structureName := aStructureName.
	^self.! !

!FrequentStructurePatternElt methodsFor: 'initializing'!

initialize

	structureName := nil.
	frequentDescriptorPatternList := SortedCollection new.
	frequentDescriptorPatternList sortBlock: [:x :y | (x pattern size) >= (y pattern size)].
	^self.! !

!FrequentStructurePatternElt methodsFor: 'list membership'!

whatList

	^FrequentStructurePatternList className.! !

!FrequentStructurePatternElt methodsFor: 'testing'!

hasAPatternSimilarTo: aPattern

	| p |

	p := self whatPatternIsMostSimilarTo: aPattern.
	(p = nil)
	ifTrue: [ ^false ].

	^true.!

includes: aPattern

	"Determines if the argument aPattern is equal to a pattern contained in self. Being equal to a pattern
	in self means two things: 1. both the pattern in self and aPattern MUST be of the same length (i.e., both
	patterns must have the same number of Descriptors); 2. all Descriptors in aPattern MUST match the 
	descriptors of the pattern in self (a 1 to 1 correspondence).
	Returns: 	nil - if aPattern is NOT included in self;
				an instance of FrequentDescriptorPattern, whose pattern matches the argument."

	| fdp c |

	(self frequentDescriptorPatternList isEmpty)
	ifTrue: [ ^nil ].

	"If aPattern's size is greater than the largest pattern in self, then aPattern is not included in self"
	(aPattern size > (self frequentDescriptorPatternList at: 1) pattern size)
	ifTrue: [ ^nil ].

	"Scan the entire pattern list in self"
	1 to: (self frequentDescriptorPatternList size) do:
	[:i |

		"Obtain the next FrequentDescriptorPattern in self"
		fdp := self frequentDescriptorPatternList at: i.

		"Both the retrieved FrequentDescriptorPattern and aPattern MUST be of the same length"
		((fdp pattern size) = (aPattern size))
		ifTrue: [

			"Scan the entire list of Descriptors in aPattern. Initialize a 'match-keeping counter'"
			c := 0.
			1 to: (aPattern size) do:
			[:j |

				"If the next Descriptor of aPattern is included in the retrieved FrequentDescriptorPattern 
				pattern, increment the counter"
				(fdp includes: (aPattern at: j))
				ifTrue: [ c := (c + 1) ].
			].

			"Determine if both patterns are equal. If so, return the FrequentDescriptorPattern instance"
			(c = fdp pattern size)
			ifTrue: [ ^fdp ].

		].  "END ((fdp pattern size) = (aPattern size)) ifTrue:"

	].  "END 1 to: (self frequentDescriptorPatternList size) do:"

	"self did not have a pattern that matches the argument"
	^nil.! !

!FrequentStructurePatternElt methodsFor: 'determining similarity'!

minimalSimilarityRateFor: aPatternSize

	"This method returns the minimal percentage of similarity accepted, according to the size of a pattern,
	which is given by the argument.  The idea is to set a flexible similarity threshold, based on two aspects:
	1. the maximum size of any two patterns to be compared; 2. the assumption that the pattern with the 
	smaller size might make a near complete match (i.e., an exact match of aPatternSize -1 elements)"

	"1 out of 2 matches: as default, accept only a complete match (i.e., 100% of both elements). The largest
	 pattern is too small"
	(aPatternSize <= 2)
	ifTrue: [ ^1.0 ].

	"2 out of 3 matches"
	(aPatternSize = 3)
	ifTrue: [ ^0.66 ].

	"3 out of 4 matches"
	(aPatternSize = 4)
	ifTrue: [ ^0.75 ].

	"4 out of 5 matches"
	(aPatternSize = 5)
	ifTrue: [ ^0.8 ].

	"5 out of 6 matches"
	(aPatternSize = 6)
	ifTrue: [ ^0.83 ].

	"(n >= 6) out of ((m > 6) & (n <= m)) matches. Set 85% similarity rate as default. This default is arbitrary.
	NOTE: As an optimization, it might be necessary to increase the 85% minimal similarity rate for larger 
	descriptions, in order to keep, as small as possible, the number of Descriptors that don't match. For 
	example, 85% of 30 Descriptors allows for a minimum number of matches of +- 25 -- and 5 non-matches.  
	So, for 30 Descriptors, an 88% minimal similarity rate might be more suitable; as the number of non-matches 
	could be kept down to +- 4. For 50 Descriptors 91% might be a more suitable minimal similarity rate, as the 
	number of non-matches is kept down to +- 5 (as opposed to +- 8 non-matches is 85% were applied).  However, 
	at this point it is unknown whether descriptions might get THAT large. Thus, this topic will be dealt with when 
	the Reasoner is operational, and real data is used. (HB - 23-May-1999)"
	^0.85!

whatPatternIsMostSimilarTo: aPattern

	"Determines if a pattern (i.e., a list with Descriptors) is sufficiently similar to a pattern contained in self.
	 Returns:	nil - if aPattern is NOT similar to any of the patterns contained in self;
				an instance of FrequentDescriptorPattern - if a similar or equal pattern is found in self."

	| min max simThreshold simRate |

	"Scan the entire pattern list in self"
	1 to: (self frequentDescriptorPatternList size) do:
	[:i |

		"Get the max and min pattern lengths (number of Descriptors) between the current pattern and the argument"
		((self frequentDescriptorPatternList at: i) pattern size >= (aPattern size))
		ifTrue: [ max := (self frequentDescriptorPatternList at: i) pattern size. min := (aPattern size) ]
		ifFalse: [ max := (aPattern size). min := (self frequentDescriptorPatternList at: i) pattern size. ].

		"Get the minimal accepted similarity rate, according to the longest pattern"
		simThreshold := (self minimalSimilarityRateFor: max).

		"Determine if OK to compare the current pattern against the argument, according to pattern lenghts"
		((min / max) >= simThreshold)
		ifTrue: [

			"Determine how similar is the argument to the current pattern in self"
			simRate := (self frequentDescriptorPatternList at: i) howSimilarTo: aPattern.

			"If both patterns are sufficiently similar, return the current pattern in self"
			(simRate >= simThreshold)
			ifTrue: [ ^(self frequentDescriptorPatternList at: i) ].

		].  "END ((min / max) >= simThreshold) ifTrue:"

	].  "END 1 to: (self frequentDescriptorPatternList size) do:"

	"There were no patterns in self similar to the argument"
	^nil.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FrequentStructurePatternElt class
	instanceVariableNames: ''!


!FrequentStructurePatternElt class methodsFor: 'instance creation'!

new

	| fsp |

	fsp := super new.
	fsp initialize.
	^fsp.! !

Object subclass: #SpecificStructureAttributeElt
	instanceVariableNames: 'structureName specificAttributeList '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Search Hints Elts'!


!SpecificStructureAttributeElt methodsFor: 'adding'!

specificAttribute: aSpecificAttribute

	"Checks if the attribute name of the argument is already included in the specific attributes list.
	 If the attribute name already exists, then its frequency is incremented by the frequency value
	 contained in the argument. Else, the argument is included in the specific attributes list."

	1 to: (self attributes size) do:
	[:i |
		((aSpecificAttribute attribute) = (self attributes at: i) attribute)
		ifTrue: [ (self attributes at: i) incrementFrequencyBy: (aSpecificAttribute frequency). ^self. ]
	].

	self attributes add: aSpecificAttribute.
	^self.!

structureName: aStructureName

	structureName := aStructureName.
	^self.! !

!SpecificStructureAttributeElt methodsFor: 'accessing'!

attributes

	^specificAttributeList.!

name

	^structureName.! !

!SpecificStructureAttributeElt methodsFor: 'initializing'!

initialize

	structureName := nil.
	specificAttributeList := SortedCollection new.
	specificAttributeList sortBlock: [:x :y | (x attribute asText) <= (y attribute asText)].
	^self.! !

!SpecificStructureAttributeElt methodsFor: 'testing'!

includesAttribute: anAttribute

	1 to: (self attributes size) do:
	[:i |
		((self attributes at: i) attribute = anAttribute name)
		ifTrue: [ ^(self attributes at: i) ]
	].

	^nil.! !

!SpecificStructureAttributeElt methodsFor: 'list membership'!

whatList

	^SpecificStructureAttributeList className.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SpecificStructureAttributeElt class
	instanceVariableNames: ''!


!SpecificStructureAttributeElt class methodsFor: 'instance creation'!

new

	| ssa |

	ssa := super new.
	^(ssa initialize).! !

OrderedCollection variableSubclass: #SpecificAttribute
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Search Hints Elts'!


!SpecificAttribute methodsFor: 'accessing'!

attribute

	^self first.!

frequency

	^self last.! !

!SpecificAttribute methodsFor: 'adding'!

attribute: anAttributeName

	"Assigns an attribute name to self"

	self removeFirst.
	self addFirst: anAttributeName.
	^self.!

frequency: aFrequencyValue

	"Assigns aFrequencyValue to self, overriding the previous value"

	self removeLast.
	self addLast: aFrequencyValue.
	^self.!

incrementFrequencyBy: aFrequencyValue

	"Increments the existing frequency in self by aFrequencyValue"
	| x |

	x := self frequency.
	x := (x + aFrequencyValue).
	self frequency: x.

	^self.! !

!SpecificAttribute methodsFor: 'initializing'!

initialize

	"First element is the attribute name; second element is the frequency"

	self add: nil.
	self add: 0.
	^self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SpecificAttribute class
	instanceVariableNames: ''!


!SpecificAttribute class methodsFor: 'instance creation'!

new

	| sa |

	sa := super new.
	sa initialize.
	^sa.! !

WeightedIndicator subclass: #WeightedStructureElt
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Search Hints Elts'!


!WeightedStructureElt methodsFor: 'list membership'!

whatList

	^WeightedStructureList className.! !

Object subclass: #FrequentDescriptorPattern
	instanceVariableNames: 'pattern frequency '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Search Hints Elts'!


!FrequentDescriptorPattern methodsFor: 'testing'!

howSimilarTo: aPattern

	"Precondition: all Descriptors in aPattern must be different, in order to keep the percentage of similarity between 0 and 1.
	 Return value:	v = 0 : different.
					0 < v < 1 : similar in v%.
					v = 1 : equal."
	| c |

	c := 0.

	1 to: (aPattern size) do:
	[:i |
		(self includes: (aPattern at: i))
		ifTrue: [ c := (c + 1) ].
	].

	(aPattern size) >= (self pattern size)
	ifTrue: [ ^((c / (aPattern size)) asFloat) ].

	^((c / (self pattern size)) asFloat)!

includes: aDescriptor

	1 to: (self pattern size) do:
	[:i |
		(((self pattern at: i) attribute = aDescriptor attribute) & 
		 ((self pattern at: i) value = aDescriptor value)) ifTrue: [ ^true ] 
	].
	^false.! !

!FrequentDescriptorPattern methodsFor: 'accessing'!

frequency

	^frequency.!

pattern

	^pattern.! !

!FrequentDescriptorPattern methodsFor: 'adding'!

addDescriptor: aDescriptor

	(self includes: aDescriptor)
	ifTrue: [ ^nil ].

	^(self pattern add: aDescriptor).!

incrementFrequency

	frequency := (self frequency + 1).!

incrementFrequencyBy: anInteger

	frequency := (self frequency + anInteger).! !

!FrequentDescriptorPattern methodsFor: 'initializing'!

initialize

	pattern := OrderedCollection new.
	frequency := 0.
	^self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FrequentDescriptorPattern class
	instanceVariableNames: ''!


!FrequentDescriptorPattern class methodsFor: 'instance creation'!

new

	| fdp |

	fdp := super new.
	fdp initialize.
	^fdp.! !

WeightedIndicator subclass: #WeightedGroupingHeuristicElt
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Search Hints Elts'!


!WeightedGroupingHeuristicElt methodsFor: 'list membership'!

whatList

	^WeightedGroupingHeuristicList className.! !

