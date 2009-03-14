OrderedCollection variableSubclass: #CBRStack
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Auxiliary'!
CBRStack comment:
'CBRStack

Purpose:  Implements a stack s a specialization of the class OrderedCollection.  Besides the regular push: and pop methods, this class has the flush 
method which clears up the entire structure.  Additionally, the method containsTheObject: verifies whether a given object is a member of the stack.

Messages with subclassResponsibility: None.

Instance variables: None.

Class variables: None.'!


!CBRStack methodsFor: 'operations'!

flush

	"Removes every element of the stack"

	[ self isEmpty ] whileFalse: [	self pop ].
	^self.!

pop

	"Removes the object which is at the top of the stack"

	(self isEmpty) ifFalse: [ ^self removeLast ].
	^nil.!

push: anObject

	"Inserts an object at the top of the stack"

	^self add: anObject.! !

!CBRStack methodsFor: 'accessing'!

top

	"Returns a reference of the object located at the top of the stack"

	self isEmpty ifTrue: [ ^nil ].
	^self last.! !

!CBRStack methodsFor: 'testing'!

containsTheObject: anObject

	"Returns true if anObject is a member of the stack; false otherwise"

	self isEmpty ifTrue: [ ^false ].
	^self includes: anObject.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CBRStack class
	instanceVariableNames: ''!


!CBRStack class methodsFor: 'instance creation'!

new 

	"Creates a new stack"

	^super new.! !

OrderedCollection variableSubclass: #IndexValue
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Auxiliary'!
IndexValue comment:
'IndexValue

Purpose:  An IndexValue is a list that, for most applications, contains two elements: an attribute value (e.g., #red, #square, 15), and a reference 
to an object.  The object pointed to may be either a case or a norm.  Although this structure is meant to handle two elements, it may accept more 
elements (by way of the appendSuccessor: method), if and only if these other elements are cases.  When an IndexValue is created and the values 
are added, its final destination is to be a component of an Index.

Messages with subclassResponsibility: None.

Instance variables: None.

Class variables: None.'!


!IndexValue methodsFor: 'initializing'!

clear

	"Sets self to default values: self = (nil, nil)"

	[ self isEmpty ] whileFalse: [ self removeFirst ].
	^self initialize.!

initialize

	"By default, an IndexValue consists of two elements: the first one is ALWAYS
	 the index value, and the second one is the successor of  the index. However, 
	 in some situations, an IndexValue may be more than one successor. So, the rule 
	 applies as follows:

		1. If the sucessor is a NORM, then IndexValue may have excatly ONE successor.
		2. If the successor is a CASE, then IndexValue may have one or more successors."

	self add: nil.
	self add: nil.
	^self.! !

!IndexValue methodsFor: 'adding'!

addValue: aValue withSuccessor: aSuccessor

	"Precondition: self = (nil, nil), or self = (v, s): 
	This method is to be used when an IndexValue instance has only two values,
	 i.e., ( nil, nil ) or ( value, successor ), where successor is either a Norm or a Case."

	((self size) > 2) ifTrue: [ ^nil ].

	"Add the value first."
	self addValue: aValue.

	"Add the successor (Case or Norm) next"
	(self addSuccessor: aSuccessor) = nil ifTrue: [ ^nil ].

	"Postcondition: self = (nil, nil), or self = (aValue, aSuccessor)"
	^self.!

appendSuccessor: aSuccessor

	"In some situations, an IndexValue may be more than one successor. The append-rule 
	 applies as follows:

		1. if position nbr. 2 of IndexValue (start of the successors list) is nil, DO NOT append anything;
		2. if position nbr. 2 of IndexValue (start of the successors list) is a Norm, DO NOT append anything;
		3. if aSuccessor is NOT a case, DO NOT append it;
		Else, append successor."

	((self at: 2) = nil)  |
	(((self at: 2) class name) = (Norm getClassName)) |
	((((aSuccessor class name) = (Case getClassName)) not) & (((aSuccessor class name) = (SAVCase getClassName)) not))
		ifTrue: [ ^nil. ].
	^self add: aSuccessor.! !

!IndexValue methodsFor: 'adding-private'!

addSuccessor: aSuccessor

	"Precondition: self last = (nil or s)
	IMPORTANT NOTE: The only valid succesors for an IndexValue are Cases or Norms"

	((self size) > 2) ifTrue: [ ^nil ].

	"Postcondition: self = (nil, nil), or self last = aSuccessor"
	self removeLast.
	^self addLast: aSuccessor.!

addValue: aValue

	"Precondition: self first = (nil or v)"

	self removeFirst.

	"Postcondition: self first = aValue"
	^self addFirst: aValue.! !

!IndexValue methodsFor: 'accessing'!

successors

	"Precondition: self = ( nil, nil ) | ( val, nil ) | ( val, succ ) | ( val, succ1, ..., succN )"

	| s i |

	s := OrderedCollection new.

	i := 2.
	[ i <= self size ]
	whileTrue: [
		s add: (self at: i).
		i := i + 1. ].

	"Postcondition: self has no change AND s = ( nil ) | ( succ ) | ( succ1, ..., succN )"
	^s.!

value

	^self first.! !

!IndexValue methodsFor: 'removing'!

removeSuccessor: aSuccessor

	"Precondition: self = ( val, succ ) | ( val, succ1, succ2, ..., succN )"

	| i s |

	i := 2.
	[ i <= self size ]
	whileTrue: [

		((self at: i) = aSuccessor) 
			ifTrue: [
				s := (self removeAtIndex: i). 
				((self size) = 1) ifTrue: [ self addLast: nil ]. 
				^s ].
			i := i + 1. ].

	"Postcondition: 	self = ( val, succ ) | ( val, succ1, succ2, ..., succN ) : aSuccessor not found, thus nothing removed from self. Return value: nil, OR
					self = ( val, nil ). Return value: s, OR
					self = (val, succ ). Return value: s, OR
					self = ( val, succ1, ..., succN-1 ). Return value: s"
	^nil.!

removeSuccessors

	"Precondition: ( val, succ ) | ( val, succ1, succ2, ..., succN )"

	| s |

	s := OrderedCollection new.

	[ (self size) >= 2 ]
	whileTrue: [ s add: (self removeAtIndex: 2) ].
	self addLast: nil.

	"Postcondition: self = ( val, nil ). Return value: s."
	^s.!

removeValue

	| v |

	"Precondition: first self = (nil or v)"
	v := self removeFirst.

	"Postcondition: first self = nil"
	self addFirst: nil.
	^v.! !

!IndexValue methodsFor: 'testing'!

isValid

	"self = ( nil, nil ) : not valid, OR
	 self = ( val, nil ) : not valid, OR
	 self = ( val, succ ) : valid, OR
	 self = ( val, succ1, ..., succN ) : valid."

	^(((self value = nil) | ((self at: 2) = nil)) not).! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

IndexValue class
	instanceVariableNames: ''!


!IndexValue class methodsFor: 'instance creation'!

new

	"Creates a new instance of IndexValue"

	| idxVal |

	idxVal := super new.
	idxVal initialize.
	^idxVal.! !

!IndexValue class methodsFor: 'class name'!

getClassName

	^#IndexValue.! !

OrderedCollection variableSubclass: #ComparingTable
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Auxiliary'!
ComparingTable comment:
'ComparingTable

Purpose:  This class is used when the case-adding process needs to compare the descriptors of two cases.  When a case is being added to the net,
every descriptor is evaluated against indices and norms, in order to traverse the net until a spot is found to insert the new case.  If during net traversal 
another case is found, then a new set of indices and norms must be created according to the similarities and differences between the descriptors of both 
cases (i.e., the case-to-insert and the case-to-compare --the case found).  In this situation a ComparingTable is created, and ComparingTableTuple''s 
are added to it.

Messages with subclassResponsibility: None.

Instance variables: None.

Class variables: None.'!


!ComparingTable methodsFor: 'filling'!

fillWith: aCase1 and: aCase2

	"Takes the descriptors of aCase1 and aCase2 and:
	 a) Creates ComparingTableTuple's according to similarities and differences between these descriptors;
	 b) Each newly created ComparingTableTuple is added to the ComparingTable"

	| desc1 desc2 d1 d2 tuple |

	desc1 := OrderedCollection new.
	desc2 := OrderedCollection new.

	1 to: 2 do:
	[:i |
		(i = 1) 
			ifTrue: [ 
				self copyDescription: (aCase1 description) into: desc1. 
				self copyDescription: (aCase2 description) into: desc2. ]
			ifFalse: [ 
				(desc2 isEmpty) ifFalse: [ 
					self copyDescription: desc2 into: desc1. 
					[desc2 isEmpty] whileFalse: [ desc2 removeFirst ] ] ].

		[ desc1 isEmpty ] whileFalse: [

			d1 := desc1 removeFirst.
			d2 := self removeDescriptorIn: desc2 with: (d1 attribute).

			(i = 1) 
				ifTrue: [   
				tuple := ComparingTableTuple newWith: (d1 attribute) caseToInsertValue: (d1 value) caseToCompareValue: ((d2 = nil) ifFalse: [ (d2 value) ] ifTrue: [ nil ]) ]
				ifFalse: [
				tuple := ComparingTableTuple newWith: (d1 attribute) caseToInsertValue: nil caseToCompareValue: (d1 value) ].
			self add: tuple. ] ].
	^self.! !

!ComparingTable methodsFor: 'reading'!

copyDescription: anInputDescription into: anOutputDescription

	1 to: (anInputDescription size) do:
		[:i | anOutputDescription add: (anInputDescription at: i) ].
	^self.! !

!ComparingTable methodsFor: 'removing'!

extractTuple

	(self isEmpty) ifTrue: [ ^nil ].
	^self removeFirst.!

removeDescriptorIn: aDescription with: anAttribute

	(aDescription isEmpty) ifTrue: [ ^nil ].

	1 to: (aDescription size) do:
	[:i |
		((aDescription at: i) attribute = anAttribute)
			ifTrue: [ ^(aDescription removeAtIndex: i) ] ].
	^nil.! !

OrderedCollection variableSubclass: #ComparingTableTuple
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Auxiliary'!
ComparingTableTuple comment:
'ComparingTableTuple

Purpose: Implements the tuples that will be added to a ComparingTable.  A ComparingTableTuple is a list (i.e., OrderedCollection) of three items 
that represent the following information:

1st element: a descriptor attribute (e.g., #color, #size, #shape);

2nd element: the case-to-insert value corresponding to the attribute, taken from a descriptor in the case''s description .  If the case-to-insert description 
does not contain a descriptor with that attribute, then the corresponding value in the ComparingTableTuple is nil.

3rd element: the case-to-compare value corresponding to the attribute, taken from a descriptor in the case''s description.  If the case-to-compare description 
does not contain a descriptor with that attribute, then the corresponding value in the ComparingTableTuple is nil.

Thus, the form of a ComparingTableTuple is: ( #attribute ci-val cc-val ).

Messages with subclassResponsibility: None.

Instance variables: None.

Class variables: None.'!


!ComparingTableTuple methodsFor: 'adding'!

add: anAttribute caseToInsertValue: aCIValue caseToCompareValue: aCCValue

	((anAttribute class) name = #ByteSymbol) ifFalse: [ ^nil ].

	self add: anAttribute.
	self add: aCIValue.
	self add: aCCValue.
	^self.! !

!ComparingTableTuple methodsFor: 'reading'!

attribute

	"Returns the attribute name"

	^self at: 1.!

caseToCompareValue

	"Returns the value of the attribute, found in the case-to-compare description"

	^self at: 3.!

caseToInsertValue

	"Returns the value of the attribute, found in the case-to-insert description"

	^self at: 2.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ComparingTableTuple class
	instanceVariableNames: ''!


!ComparingTableTuple class methodsFor: 'instance creation'!

newWith: anAttribute caseToInsertValue: aCIValue caseToCompareValue: aCCValue

	| t |

	t := super new.
	(t add: anAttribute caseToInsertValue: aCIValue caseToCompareValue: aCCValue) = nil
		ifTrue: [ ^nil ].
	^t.! !

