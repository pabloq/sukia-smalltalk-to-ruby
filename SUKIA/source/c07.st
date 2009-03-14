OrderedCollection variableSubclass: #Value
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Values'!


!Value methodsFor: 'accessing-range values'!

numberInRange: aNumber atLevel: aLevel

	"Returns nil or a (possibly empty) list of ValueDescriptors, such that
	 aNumber lies within the range determined by their lower and
	 upper bounds.
	IMPORTANT: Returning nil means that this method is in a state of error."

	| levelNumber vd vdList n f |

	"Get the level-list index (in self) corresponding to aLevel"
	levelNumber := TaxonomicLevels transformToIndex: aLevel.
	(levelNumber = nil) ifTrue: [ ^nil ].

	n := aNumber.
	f := 0.0.
	((n class name) = #Float) ifFalse: [ n := (f coerce: n) ].

	vdList := OrderedCollection new.

	1 to: (self at: levelNumber) size do:
	[:i |
		vd := (self at: levelNumber) at: i.
		(vd asRange)
		ifTrue: [
			(n >= vd lowerBound) & (n <= vd upperBound)
			ifTrue: [ vdList add: vd ].
		].
	].

	^vdList.!

rangeMatching: aLowerBound and: anUpperBound inLevel: aLevel

	"Returns nil or a (possibly empty) list of one ValueDescriptor, such that
	 its lower bound and upper bound match the arguments aLowerBound
	 and anUpperBound. NOTE: Each level-list should contain unique-valued
	 ranges. That's the reason for stopping loop execution when a descriptor is 
	 found. Method valueDescriptor:for: MUST ensure the addition of descriptors 
	 with UNIQUE VALUES.

	IMPORTANT: Returning nil means that this method is in a state of error."

	| levelNumber vd vdList lb ub f |

	"Get the level-list index (in self) corresponding to aLevel"
	levelNumber := TaxonomicLevels transformToIndex: aLevel.
	(levelNumber = nil) ifTrue: [ ^nil ].

	f := 0.0.
	lb := aLowerBound.
	ub := anUpperBound.
	((lb class name) = #Float) ifFalse: [ lb := (f coerce: lb) ].
	((ub class name) = #Float) ifFalse: [ ub := (f coerce: ub) ].

	vdList := OrderedCollection new.

	1 to: (self at: levelNumber) size do:
	[:i |
		vd := (self at: levelNumber) at: i.
		(vd asRange)
		ifTrue: [
			(lb = vd lowerBound) & (ub = vd upperBound)
			ifTrue: [ vdList add: vd. ^vdList ].
		].
	].

	^vdList.! !

!Value methodsFor: 'accessing-general'!

getMatchingValueDescriptorFor: aDescriptor in: aLevel

	| vd |

	(aDescriptor asRange)
	ifTrue: [ vd := (self rangeMatching: (aDescriptor lowerBound) and: (aDescriptor upperBound) inLevel: aLevel) ]
	ifFalse: [ vd :=(self value: (aDescriptor value) weight: (aDescriptor weight) in: aLevel operator: #=) ].

	(vd = nil) ifTrue: [ ^nil ].
	((vd isEmpty) | ((vd size) > 1)) ifTrue: [ ^nil ].
	^(vd first).!

valueDescriptors

	"Return the entire list of ValueDescriptors, distributed in level-lists"

	^self.!

valueDescriptorsIn: aLevel

	"Returns nil or all ValueDescriptors in a level-list"

	| levelNumber |

	"Get the level-list index (in self) corresponding to aLevel"
	levelNumber := TaxonomicLevels transformToIndex: aLevel.
	(levelNumber = nil) ifTrue: [ ^nil ].

	"Return the level-list indexed in self (i.e, Value) by levelNumber"
	^(self at: levelNumber).! !

!Value methodsFor: 'accessing-weighted values'!

value: aValue in: aLevel

	"Returns nil or a (possibly empty) list with all ValueDescriptors from a level-list, such that their value matches aValue.
	 IMPORTANT: Returning nil means that this method is in an error condition"

	| levelNumber vd vdList |

	"Get the level-list index (in self) corresponding to aLevel"
	levelNumber := TaxonomicLevels transformToIndex: aLevel.
	(levelNumber = nil) ifTrue: [ ^nil ].

	"Create the output ValueDescriptor list (vdList)"
	vdList := OrderedCollection new.

	"Parse all ValueDescriptors in the level-list"
	1 to: (self at: levelNumber) size do:
	[:i |	
		vd := (self at: levelNumber) at: i.
		(vd asRange)
		ifFalse: [
			(vd value = aValue)
			ifTrue: [ vdList add: vd ]
		]
	].

	"Return the list of ValueDescriptors"
	^vdList.!

value: aValue in: aLevel weightBetween: aLowerBound and: anUpperBound

	"Returns nil or a (possibly empty) list with all ValueDescriptors from a level-list such that 
	 their value matches aValue and their weights lie between a range determined by aLowerBound 
	 and anUpperBound.
	 IMPORTANT: Returning nil means that this method is in an error condition"

	| levelNumber vd vdList f lb ub |

	"Get the level-list index (in self) corresponding to aLevel"
	levelNumber := TaxonomicLevels transformToIndex: aLevel.
	(levelNumber = nil) ifTrue: [ ^nil ].

	"Make a copy of the lower and upper bound arguments"
	lb := aLowerBound.
	ub := anUpperBound.

	"Make sure that both the lower and upper bound arguments are Floats"
	f := 0.0.
	((lb class name) = #Float) ifFalse: [ lb := (f coerce: lb) ].
	((ub class name) = #Float) ifFalse: [ ub := (f coerce: ub) ].

	"Create the output ValueDescriptor list (vdList)"
	vdList := OrderedCollection new.

	"Parse all ValueDescriptors in the level-list and copy, into vwList, all those whose value matches aValue and their 
	 weight is between the range given by lb and ub"
	1 to: (self at: levelNumber) size do:
	[:i |
		vd := (self at: levelNumber) at: i.
		(vd asRange)
		ifFalse: [
			(vd value = aValue)	
			ifTrue: [
				((vd weight >= lb) & (vd weight <= ub))
				ifTrue: [ vdList add: vd ]
			].
		].
	].

	"Return the list of ValueDescriptors"
	^vdList.!

value: aValue weight: aWeight in: aLevel operator: anOperator

	"Returns nil or a (possibly empty) list with all ValueDescriptors from a level-list,
	 such that their value matches aValue and their weight is compared against
	 a given binary operator (i.e., =, ~=, < , <=, >, >=).
	 IMPORTANT: Returning nil means that this method is in an error condition"

	| levelNumber vd vdList flag stop i w f |

	"Get the level-list index (in self) corresponding to aLevel"
	levelNumber := TaxonomicLevels transformToIndex: aLevel.
	(levelNumber = nil) ifTrue: [ ^nil ].

	"Make a copy of the argument aWeight and make sure that it is a Float"
	f := 0.0.
	w := aWeight.
	((w class name) = #Float) ifFalse: [ w := (f coerce: w) ].

	"Create the output ValueDescriptor list (vdList)"
	vdList := OrderedCollection new.

	"Parse the level-list and copy, into vdList, all those ValueDescriptors whose value matches aValue and their 
	 weight compares to true according to the given binary operator.  NOTE: It is assumed that for any given 
	 instance of  Value (i.e., self), all instances of ValueDescriptor must be UNIQUE, that is, the combination 
	 value/weight can not be repeated. That is the reason for stopping the loop when the '=' operator is used. 
	 This way, once the corresponding ValueDescriptor is found, it becomes unnecessary to continue parsing 
	 the level-list"
	i := 1.
	stop := false.
 	[i <= (self at: levelNumber) size]
	whileTrue: [

		vd := (self at: levelNumber) at: i.
		(vd asRange)
		ifFalse: [

			(vd value = aValue)
			ifTrue: [

				flag := false.
				(anOperator = #=) ifTrue: [ flag := ((vd weight) = w). stop := true. ].
				(anOperator = #~=) ifTrue: [ flag := ((vd weight) ~= w) ].
				(anOperator = #<) ifTrue: [ flag := ((vd weight) < w) ].
				(anOperator = #<=) ifTrue: [ flag := ((vd weight) <= w) ].
				(anOperator = #>) ifTrue: [ flag := ((vd weight) > w) ].
				(anOperator = #>=) ifTrue: [ flag := ((vd weight) >= w) ].

				(flag = true) ifTrue: [ vdList add: vd ].
				(stop = true) ifTrue: [ i := (self at: levelNumber) size ].
				
			].    "END (vd value = aValue) ifTrue: ["

		].    "(vd asRange) ifFalse: ["

		i := i + 1.

	].    "[i <= (self at: levelNumber) size] whileTrue: ["

	"Return the list of ValueDescriptors"
	^vdList.!

weight: aWeight in: aLevel between: aLowerBound and: anUpperBound

	"Returns nil or a (possibly empty) list with all ValueDescriptors from a level-list
	 such that their weights lie between a range determined by aLowerBound and anUpperBound.
	 IMPORTANT: Returning nil means that this method is in an error condition"

	| levelNumber vd vdList f lb ub |

	"Get the level-list index (in self) corresponding to aLevel"
	levelNumber := TaxonomicLevels transformToIndex: aLevel.
	(levelNumber = nil) ifTrue: [ ^nil ].

	"Make a copy of the lower and upper bound arguments"
	lb := aLowerBound.
	ub := anUpperBound.

	"Make sure that the lower and upper bound arguments are Floats"
	f := 0.0.
	((lb class name) = #Float) ifFalse: [ lb := (f coerce: lb) ].
	((ub class name) = #Float) ifFalse: [ ub := (f coerce: ub) ].

	"Create the output ValueDescriptor list (vdList)"
	vdList := OrderedCollection new.

	"Parse the level-list and copy, into vdList, all those ValueDescriptors whose weight lies between 
	 the range defined by lb and ub"
	1 to: (self at: levelNumber) size do:
	[:i |
		vd := (self at: levelNumber) at: i.
		(vd asRange)
		ifFalse: [

			((vd weight >= lb) & (vd weight <= ub))
			ifTrue: [ vdList add: vd ] 
		].
	].

	"Return the list of ValueDescriptors"
	^vdList.!

weight: aWeight in: aLevel operator: anOperator

	"Returns nil or a (possibly empty) list with all ValueDescriptors from a level-list
	 such that their weight is compared against a given binary operator (i.e., =, ~=, <, <=, >, >=).
	 IMPORTANT: Returning nil means that this method is in an error condition"

	| levelNumber vd vdList flag f w |

	"Get the level-list index (in self) corresponding to aLevel"
	levelNumber := TaxonomicLevels transformToIndex: aLevel.
	(levelNumber = nil) ifTrue: [ ^nil ].

	"Make a copy of the aWeight argument and make sure that it is a Float"
	f := 0.0.
	w := aWeight.
	((w class name) = #Float) ifFalse: [ w := (f coerce: w) ].

	"Create the output ValaueDescriptor list (vdList)"
	vdList := OrderedCollection new.

	"Parse the level-list and copy, into vdList, all those ValueDescriptors whose weight compares 
	 to true according to the given binary operator"
	1 to: (self at: levelNumber) size do:
	[:i |

		vd := (self at: levelNumber) at: i.
		(vd asRange)
		ifFalse: [

			flag := false.
			(anOperator = #=) ifTrue: [ flag := ((vd weight) = w) ].
			(anOperator = #~=) ifTrue: [ flag := ((vd weight) ~= w) ].
			(anOperator = #<) ifTrue: [ flag := ((vd weight) < w) ].
			(anOperator = #<=) ifTrue: [ flag := ((vd weight) <= w) ].
			(anOperator = #>) ifTrue: [ flag := ((vd weight) > w) ].
			(anOperator = #>=) ifTrue: [ flag := ((vd weight) >= w) ].

			(flag = true) ifTrue: [ vdList add: vd ].
		].
	].

	"Return the list of ValueDescriptors"
	^vdList.! !

!Value methodsFor: 'testing'!

includes: aDescriptor in: aLevel

	"Determines whether or not aDescriptor exists in the level-list determined by aLevel.
	 Returns: 	nil - bad input;
				true - there is a descriptor that matches aDescriptor;
				false - a descriptor matching aDescriptor was not found"

	| levelNumber vd |

	levelNumber := TaxonomicLevels transformToIndex: aLevel.
	(levelNumber = nil) ifTrue: [ ^nil ].

	1 to: (self at: levelNumber) size do:
	[:i |

		vd := (self at: levelNumber) at: i.
		(aDescriptor asRange)
		ifTrue: [

			(vd asRange)
			ifTrue: [

				((vd lowerBound = aDescriptor lowerBound) & (vd upperBound = aDescriptor upperBound))
				ifTrue: [ ^true ].

			]    "END (vd asRange) ifTrue: ["

		]    "END (aDescriptor asRange) ifTrue: ["

		"(aDescriptor asRange)"
		ifFalse: [

			(vd asRange)
			ifFalse: [

				((vd value = aDescriptor value)  & (vd weight = aDescriptor weight))
				ifTrue: [ ^true ].

			].    "END (vd asRange) ifFalse: ["

		].    "END (aDescriptor asRange) ifFalse: ["

	].    "END 1 to: (self at: levelNumber) size do:"

	^false.!

includesUniqueValue: aDescriptor in: aLevel

	"Determines whether or not aDescriptor exists in the level-list determined by aLevel.
	 Returns: 	nil - bad input;
				true - there is a descriptor that matches aDescriptor;
				false - a descriptor matching aDescriptor was not found"

	| levelNumber vd |

	levelNumber := TaxonomicLevels transformToIndex: aLevel.
	(levelNumber = nil) ifTrue: [ ^nil ].

	1 to: (self at: levelNumber) size do:
	[:i |

		vd := (self at: levelNumber) at: i.
		(aDescriptor asRange)
		ifTrue: [

			(vd asRange)
			ifTrue: [

				((vd lowerBound = aDescriptor lowerBound) & (vd upperBound = aDescriptor upperBound))
				ifTrue: [ ^true ].

			]    "END (vd asRange) ifTrue: ["

		]    "END (aDescriptor asRange) ifTrue: ["

		"(aDescriptor asRange)"
		ifFalse: [

			(vd asRange)
			ifFalse: [

				"Disregard the weight in this comparison"
				(vd value = aDescriptor value)
				ifTrue: [ ^true ].

			].    "END (vd asRange) ifFalse: ["

		].    "END (aDescriptor asRange) ifFalse: ["

	].    "END 1 to: (self at: levelNumber) size do:"

	^false.! !

!Value methodsFor: 'adding'!

valueDescriptor: aValueDescriptor for: aLevel

	| levelNumber |

	"Adds a ValueDescriptor to a level-list in self.  This method makes sure that: a) if aDescriptor is not a range,
	 then its pair value-weight must be unique, or b) if aDescriptor is a range, its lower and upper bounds must
	 be unique.
	 Returns: 	nil - Bad input or ValueDescriptor already exists;
				self - Process OK.
	NOTE: This method should be used when creating the StructureIndex for Taxonomy"

	levelNumber := TaxonomicLevels transformToIndex: aLevel.
	(levelNumber = nil) ifTrue: [ ^nil ].

	"IMPORTANT ACTION TO ENSURE THE ADDITION OF DESCRIPTORS WITH UNIQUE VALUE-WEIGHTS OR RANGES:
	 Make sure that aDescriptor DOES NOT exist in aLevel.  NOTE: Since the argument for includes: is levelNumber, the return 
	 value (in this case) from includes:in: will always be either true or false"
	(self includes: aValueDescriptor in: levelNumber)
	ifTrue: [ ^nil ].

	(self at: levelNumber) add: aValueDescriptor.
	^self.!

valueDescriptorWithUniqueValue: aValueDescriptor for: aLevel

	| levelNumber |

	"Adds a ValueDescriptor to a level-list in self.  This method makes sure that: a) if aDescriptor is not a range,
	 then its value must be unique (disregards the weight), or b) if aDescriptor is a range, its lower and upper bounds
	 must be unique.
	 Returns: 	nil - Bad input or ValueDescriptor already exists;
				self - Process OK.
	NOTE: This method should be used when creating a Taxon's SAV or GH description"

	levelNumber := TaxonomicLevels transformToIndex: aLevel.
	(levelNumber = nil) ifTrue: [ ^nil ].

	"IMPORTANT ACTION TO ENSURE THE ADDITION OF DESCRIPTORS WITH UNIQUE VALUES OR RANGES:
	 Make sure that the value of aDescriptor DOES NOT exist in aLevel.  NOTE: Since the argument for the method
	 includesUniqueValue:in: is levelNumber, the return value (in this case) from includes: will always be either true or false"
	(self includesUniqueValue: aValueDescriptor in: levelNumber)
	ifTrue: [ ^nil ].

	(self at: levelNumber) add: aValueDescriptor.
	^self.! !

!Value methodsFor: 'initializing'!

init

	| level |

	(TaxonomicLevels nomenclaturalNumber) timesRepeat:
	[ level := OrderedCollection new.
	  self add: level. ].

	^self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Value class
	instanceVariableNames: ''!


!Value class methodsFor: 'instance creation'!

new

	| v |

	v := super new.
	^(v init).! !

Object subclass: #MeasuringUnit
	instanceVariableNames: ''
	classVariableNames: 'UnitList '
	poolDictionaries: ''
	category: 'CBR - Sukia Values'!

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MeasuringUnit class
	instanceVariableNames: ''!


!MeasuringUnit class methodsFor: 'testing'!

exists: aMeasuringUnit

	^(UnitList includes: aMeasuringUnit).! !

!MeasuringUnit class methodsFor: 'class initialization'!

initialize

	(UnitList = nil)
	ifTrue: [

		UnitList := OrderedCollection new.
		UnitList add: # mm.
		UnitList add: # cm.
		UnitList add: # inch.
	].! !

OrderedCollection variableSubclass: #ValueDescriptor
	instanceVariableNames: 'asRange measuringUnit '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Values'!


!ValueDescriptor methodsFor: 'initializing'!

initialize

	"Self is set up for weighted values as default"

	self add: nil.
	self add: 0.0.
	asRange := false.
	measuringUnit := nil.
	^self.! !

!ValueDescriptor methodsFor: 'accessing-range values'!

asRange

	^asRange.!

lowerBound

	(self asRange = true)
	ifTrue: [ ^(self at: 1) ]
	ifFalse: [ ^nil ].!

measuringUnit

	^measuringUnit.!

upperBound

	(self asRange = true)
	ifTrue: [ ^(self at: 2) ]
	ifFalse: [ ^nil ].! !

!ValueDescriptor methodsFor: 'accessing-general'!

taxonList

	| taxonList |

	taxonList := OrderedCollection new.

	3 to: (self size) do:
	[:i | taxonList add: (self at: i) ].

	^taxonList.! !

!ValueDescriptor methodsFor: 'accessing-weighted values'!

value

	(self asRange = true)
	ifTrue: [ ^nil ]
	ifFalse: [ ^(self at: 1) ].!

weight

	(self asRange = true)
	ifTrue: [ ^nil ]
	ifFalse: [ ^(self at: 2) ].! !

!ValueDescriptor methodsFor: 'adding-general'!

taxon: aTaxon

	| range mUnit |

	"Copy the current values of the instance variables asRange and measuringUnit"
	range := self asRange.
	mUnit := self measuringUnit.

	"Add the taxon. What happens here is that, if the receiver needs to open space to add the new taxon, 
	 the parent class will do so by creating a new instance of the receiver with enhanced space, copying the 
	 elements of the receiver to that new instance, adding the new taxon using the enhanced space, and 
	 replacing the receiver for that new instance. The problem with this procedure is that, once the new instance 
	 of the receiver is created, asRange and measuringUnit will have default values (from the initialize method), 
	 which may not correspond to the values that the receiver had before adding the taxon"
	self add: aTaxon.

	"To avoid the befre-mentioned problem with adding a new taxon, set asRange and measuringUnit with
	 the values they had before the method add: aTaxon was called"
	asRange := range.
	measuringUnit := mUnit.

	^self.! !

!ValueDescriptor methodsFor: 'adding-range values'!

lowerBound: aNumber

	| f n |

	(self asRange = true)
	ifFalse: [ ^nil ].

	n := aNumber.
	f := 0.0.

	((n class name) = #Float)
	ifFalse: [ n := (f coerce: n) ].

	self removeFirst.
	^(self addFirst: n).!

upperBound: aNumber

	| f n |

	(self asRange = true)
	ifFalse: [ ^nil ].

	n := aNumber.
	f := 0.0.

	((n class name) = #Float)
	ifFalse: [ n := (f coerce: n) ].

	(self lowerBound > n)
	ifTrue: [ ^nil ].

	self removeAtIndex: 2.
	^(self add: n after: (self first)).! !

!ValueDescriptor methodsFor: 'adding-weighted values'!

value: aValue

	(self asRange = true)
	ifTrue: [ ^nil ].

	self removeFirst.
	^(self addFirst: aValue).!

weight: aWeight

	| f w |

	(self asRange = true)
	ifTrue: [ ^nil ].

	w := aWeight.
	f := 0.0.

	((w class name) = #Float)
	ifFalse: [ w := (f coerce: w) ].

	self removeAtIndex: 2.
	^(self add: w after: (self first)).! !

!ValueDescriptor methodsFor: 'setting-range values (private)'!

measuringUnit: aMeasuringUnit

	"aMeasuringUnit can be #cm, #mm, #inch"

	(MeasuringUnit exists: aMeasuringUnit)
	ifFalse: [ ^nil ].

	measuringUnit := aMeasuringUnit.
	^self.!

setAsRange

	^asRange := true.! !

!ValueDescriptor methodsFor: 'setting-range values'!

setAsRangeWithUnit: aMeasuringUnit

	self setAsRange.
	((self measuringUnit: aMeasuringUnit) = nil )
	ifTrue: [ ^nil ].

	^self.! !

!ValueDescriptor methodsFor: 'copying'!

copyFrom: aValueDescriptor referencing: aTaxon

	self removeFirst.
	self addFirst: (aValueDescriptor at: 1).

	self removeAtIndex: 2.
	self add: (aValueDescriptor at: 2) after: (self first).

	self taxon: aTaxon.

	asRange := (aValueDescriptor asRange).
	^self.! !

!ValueDescriptor methodsFor: 'testing'!

rangeWIthin: aLowerBound and: anUpperBound

	(self asRange) ifFalse: [ ^false ].

	(aLowerBound > anUpperBound)
	ifTrue: [ ^false ].

	^((self lowerBound >= aLowerBound) & (self upperBound <= anUpperBound)).! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ValueDescriptor class
	instanceVariableNames: ''!


!ValueDescriptor class methodsFor: 'instance creation'!

new

	^(self new: 5).!

new: anInteger

	| vw |

	vw := super new: anInteger.
	^(vw initialize).! !
MeasuringUnit initialize!


