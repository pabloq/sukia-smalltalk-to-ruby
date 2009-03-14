Object subclass: #SimRanges
	instanceVariableNames: ''
	classVariableNames: 'Ranges '
	poolDictionaries: ''
	category: 'CBR - Sukia Similarity Assessment'!

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SimRanges class
	instanceVariableNames: ''!


!SimRanges class methodsFor: 'non-comparable'!

nonComparable

	"If a given value does not exist in a given value-weight list, nothing can be said about the
	 similarity degree of the value.  Thus, return a symbol which expresses this fact.  This symbol
	can be regarded as a special type of SimRange with range (-1.0 -1.0)"

	^#valorNoComparable.! !

!SimRanges class methodsFor: 'ranges-value assignment'!

assignValuesUsing: aValueWeightList

	"Creates a list with the range names and associated range values. 
	The range values are computed using parameter aValueWeightList.
	NOTE: The resulting values for each range are integers, so the union
	of ranges will go from 0 to 100.  The reason for having integers instead 
	of floats (thus having a union of ranges from 0.0 to 1.0) is that floats 
	present a lot of (decimal digit) of precision problems."

	| valuedRangesList vrInstance vRange rCopy p1 p2 |

	"This algorithm will not work if self has less than 3 ranges defined"
	(self ranges size < 3) ifTrue: [ ^nil. ].

	"Create the output list and make a copy of the ranges defines in self."
	valuedRangesList := OrderedCollection new.
	rCopy := self copy.

	"Compute the upper value for the #diferente range name"
	p1 := ((SimAssessor maxWeightOf: aValueWeightList) * 100) truncated.
	p1 := 100 - p1.

	"Compute the length of each range"
	p2 := ((99 - p1) / ((rCopy size) - 2)) truncated.

	"Start with range name: #diferente.  This should always be the first range. The range values 
	will go from 0 to p1. Once the range values have been established, increment p1 to be the 
	start of the next range"
	vrInstance := OrderedCollection new.
	vRange := OrderedCollection new.
	vRange add: 0.
	vRange add: p1.
	vrInstance add: (rCopy removeFirst).
	vrInstance add: vRange.
	valuedRangesList add: vrInstance.
	p1 := p1 + 1.

	"So long as there are more than two range names, compute their associated range values"
	[ rCopy size > 2 ] whileTrue: [
		vrInstance := OrderedCollection new.
		vRange := OrderedCollection new.
		vRange add: p1.
		vRange add: (p1 + p2).
		vrInstance add: (rCopy removeFirst).
		vrInstance add: vRange.
		valuedRangesList add: vrInstance.
		p1 := (p1 + p2 + 1).
	].

	"Compute the range values for the before-last range. Its upper bound will always be 99"
	vrInstance := OrderedCollection new.
	vRange := OrderedCollection new.
	vRange add: p1.
	vRange add: 99.
	vrInstance add: (rCopy removeFirst).
	vrInstance add: vRange.
	valuedRangesList add: vrInstance.

	"The last range name is always #igual.  Its values will always be the defaults 1.0 and 1.0"
	vrInstance := OrderedCollection new.
	vRange := OrderedCollection new.
	vRange add: 100.
	vRange add: 100.
	vrInstance add: (rCopy removeFirst).
	vrInstance add: vRange.
	valuedRangesList add: vrInstance.

	^valuedRangesList.! !

!SimRanges class methodsFor: 'private'!

ranges

	^Ranges.! !

!SimRanges class methodsFor: 'copying'!

copy

	| rangesCopy |

	rangesCopy := OrderedCollection new.

	1 to: (self ranges size) do:
	[:i |  rangesCopy add: (self ranges at: i) ].

	^rangesCopy.!

rangesStartingAt: aRangeName

	| outRanges idx |

	outRanges := OrderedCollection new.
	
	idx := Ranges indexOf: aRangeName.
	(idx = 0) ifTrue: [ ^outRanges ].

	idx to: (Ranges size) do:
	[:i | outRanges add: (Ranges at: i) ].

	^outRanges.! !

!SimRanges class methodsFor: 'class initialization'!

initialize

	"Assigns the range names to be used to assess similarity between the values of attributes.
	IMPORTANT NOTES: 
	1. The first element should ALWAYS be called #diferente and the last one should always be called #igual.  
	    These are special symbols around which functionality in other components will be built.
	2. self should ALWAYS have at least 3 elements (i.e., (#diferente #xxx1 ... #xxxN  #igual)), where #xxxK is some 
	    arbitrary similarity measure).  Otherwise, most methods won't work.  The reason for having at least 3 range names 
	    is simple: if only two were defined (i.e., (#diferente #igual)), none of this similarity assessment stuff would be necessary. 
	    It would just suffice to perform an exact match between two values and, if they don't match the implicit answer is 
	    #diferente; likewise, if the values match, the implicit answer is #igual.
	3. Take a look at method self nonComparable for more range details."

	(Ranges = nil)
	ifTrue: [

		Ranges := OrderedCollection new.
		Ranges add: #diferente.
		Ranges add: #pocoSimilar.
		Ranges add: #relativamenteSimilar.
		Ranges add: #medianamenteSimilar.
		Ranges add: #considerablementeSimilar.
		Ranges add: #altamenteSimilar.
		Ranges add: #igual.
	].! !

Object subclass: #SimAssessor
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Similarity Assessment'!

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SimAssessor class
	instanceVariableNames: ''!


!SimAssessor class methodsFor: 'calculating'!

distanceBetween: aValue1 and: aValue2 in: aValueWeightList

	| w1 w2 |

	w1 := self getTheWeightOf: aValue1 in: aValueWeightList.
	(w1 = nil) ifTrue: [ ^nil ].

	w2 := self getTheWeightOf: aValue2 in: aValueWeightList.
	(w2 = nil) ifTrue: [ ^nil ].

	^((((w1 * 100) truncated) - ((w2 * 100) truncated)) abs)!

getTheWeightOf: aValue in: aValueWeightList

	"Returns the weight associated to aValue, if aValue exists in aValueWeightList.
	 If it doesn't exist, returns nil"

	1 to: aValueWeightList size do:
	[:i | ((aValueWeightList at: i) value = aValue) ifTrue: [ ^(aValueWeightList at: i) weight ] ].

	^nil.!

similarityDegreeOf: aValue in: aValueWeightList

	| d |

	d := self distanceBetween: ((self maxValueWeightOf: aValueWeightList) value) and: aValue in: aValueWeightList.
	(d = nil) ifTrue: [ ^(-1) ].

	^(100 - d).!

similarityRangeOf: aValue in: aValueWeightList

	| sd sr r lb ub |

	sd := self similarityDegreeOf: aValue in: aValueWeightList.
	(sd < 0) ifTrue: [ ^(SimRanges nonComparable) ].

	sr := SimRanges assignValuesUsing: aValueWeightList.

	[ sr isEmpty ]
	whileFalse: [

		r := sr removeFirst.
		lb := (r at: 2) at: 1.
		ub := (r at: 2) at: 2.

		((sd >= lb) & (sd <= ub))
		ifTrue: [ ^(r at: 1) ].
	].

	^nil.! !

!SimAssessor class methodsFor: 'weight assessment'!

maxValueWeightOf: aValueWeightList

	| w maxWeight idx |

	maxWeight := (aValueWeightList at: 1) weight.
	idx := 1.

	2 to: aValueWeightList size do:
	[:i |
		w := (aValueWeightList at: i) weight.
		(w > maxWeight) ifTrue: [ idx := i ].
	].

	^(aValueWeightList at: idx).!

maxWeightOf: aValueWeightList

	| w maxWeight |

	maxWeight := (aValueWeightList at: 1) weight.
	2 to: aValueWeightList size do:
	[:i |
		w := (aValueWeightList at: i) weight.
		(w > maxWeight) ifTrue: [ maxWeight := w. ].
	].

	^maxWeight.! !
SimRanges initialize!


