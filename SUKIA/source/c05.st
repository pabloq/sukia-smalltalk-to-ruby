OrderedCollection variableSubclass: #SAVDescriptor
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Redund. Discrim. Net'!
SAVDescriptor comment:
'SAVDescriptor

Purpose:  List that represents the structure x attribute x value tuple.  A SAVDescriptor is used to create case descriptions.

Upon creation, a Descriptor is of the form: ( nil nil nil ).

Messages with subclassResponsibility: None.

Instance variables: None.

Class variables: None.
'!


!SAVDescriptor methodsFor: 'initializing'!

clear

	"Sets self to default values: self = (nil, nil, nil)"

	[ self isEmpty ] whileFalse: [ self removeFirst ].
	^self initialize.!

initialize

	"Class instance invariant: self MUST always have exactly three values. The first element corresponds to the SAV descriptor's structure name, 
       the second element corresponds to the structure's attribute, and the third one to the attribute's value.
	 IMPORTANT NOTE: Extreme care should be taken when using this method, as it assumes an empty self."

	self add: nil.
	self add: nil.
      self add: nil.
	^self.! !

!SAVDescriptor methodsFor: 'adding'!

addStructure: aStructure Attribute: anAttribute Value: aValue

	"Precondition: self = (nil, nil, nil), or self = (s, a, v)"
	(self addStructure: aStructure) = nil ifTrue: [ ^nil ].
	(self addAttribute: anAttribute) = nil ifTrue: [ ^nil ].

	"Postcondition: self = (nil, nil, nil), or self = (aStructure, anAttribute, aValue)"
	^self addValue: aValue.! !

!SAVDescriptor methodsFor: 'accessing'!

attribute

	^self at: 2.!

structure

	^self at: 1.!

value

	^self at: 3.! !

!SAVDescriptor methodsFor: 'adding-private'!

addAttribute: anAttribute

	"Precondition: anAttribute MUST be a ByteSymbol, and self first = (nil or a)"
	((anAttribute class) name = #ByteSymbol) ifFalse: [ self clear. ^nil ].

	"Postcondition: self = (nil, nil, nil), or (self at: 2) = anAttribute"
	self removeAtIndex: 2.
	^self add: anAttribute after: (self first).!

addStructure: aStructure

	"Precondition: aStructure MUST be a String, and self first = (nil or a)"
	(aStructure isString) ifFalse: [ self clear. ^nil. ].

	"Postcondition: self = (nil, nil, nil), or (self at: 1) = aStructure"
	self removeAtIndex: 1.
	^self add: aStructure before: (self first).!

addValue: aValue

	"Precondition: self last = (nil or v)"
	self removeLast.

	"Postcondition: self last = aValue"
	^self addLast: aValue.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SAVDescriptor class
	instanceVariableNames: ''!


!SAVDescriptor class methodsFor: 'class name'!

getClassName

	"Returns the Descriptor class name"

	^#SAVDescriptor.! !

!SAVDescriptor class methodsFor: 'instance creation'!

new

	"Creates a new SAV (structure, attribute, value) descriptor"

	| descriptor |

	descriptor := super new.
	descriptor initialize.
	^descriptor.! !

Root subclass: #SAVRoot
	instanceVariableNames: 'structure '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Redund. Discrim. Net'!
SAVRoot comment:
'SAVRoot

Purpose: Specialization of a Root, and its mission is to act as a net''s entry point.  The three most important features of a SAVRoot
are: 1. it does not have a predecessor, 2. its Descriptor is of the form ( nil nil ), and 3. it is identified by a structure name.

Messages with subclassResponsibility: None.

Instance variables: None.

Class variables: None.'!


!SAVRoot methodsFor: 'initializing'!

initializeWith: aStructureName

	"Initializes the local variables for this sublcass.  The predecessor's variables have already been initialized when method new was executed."

	structure := aStructureName.
	^self.! !

!SAVRoot methodsFor: 'accessing'!

structure

	"Returns the structure label for this net root"
	^structure.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SAVRoot class
	instanceVariableNames: ''!


!SAVRoot class methodsFor: 'class name'!

getClassName

	"Returns the NetRoot class name"

	^#SAVRoot.! !

!SAVRoot class methodsFor: 'instance creation'!

newWith: aStructureName

	"Creates a new net root.  After initialization, the net root will contain a structure name as its identification label"

	| netRoot |

	"Step 1. Make sure argument is the right object"
	((aStructureName isString) not) ifTrue: [ ^nil ].

	"Step 2. Create the new object. Initialize both its predecessor's and own variables"
	netRoot := super new.
	netRoot initializeWith: aStructureName.

	^netRoot.! !

Case subclass: #SAVCase
	instanceVariableNames: 'descriptionCopy structureCopy '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Redund. Discrim. Net'!
SAVCase comment:
'SAVCase

Purpose: Specialization of the class Case; the main difference between these two classes is that the SAVCase''s description contains 
three-tuple, structure-attribute-value SAVDescriptor''s, instead of the regular two-tuple, attibute-value Descriptor''s. Because of this 
difference, the SAVCase description must be modified before the net building methods add them to the redundant discrimination nets.

In general terms, the SAVCase''s description is modified as follows:
a) Create a backup copy of the original description (the one with three-tuple SAVDescriptor''s) and save it in the instance variable descriptionCopy.
b) Group all SAVDescriptor''s in the description by structure name.
c) For each of the grouped SAVDescriptor: create a new instance of Descriptor, extract the attribute-value part from the SAVDescriptor and 
add it to the newly created Descriptor.
d) Create a new case description based on the current structure name-group, using all the created Descriptor''s.  The resulting description will be, 
of course, a subset of the original description.

Next, the SAVCase is added to a net represented by the structure name-group criterion.  Once the adding process is over, the case description
is flushed, and a new description is created in terms of the next structure name-group.  The same case is then added to another net represented
by the corresponding criterion.  The case-adding process repeats until all the structure name-groups have been worked.  The last step before
continuing on another case is to restore the original description from the the descriptionCopy variable.

Messages with subclassResponsibility: None.

Instance variables:
descriptionCopy: Instance of OrderedCollection that keeps a copy of the SAVCase''s original description, while the case is being added to
all the required nets.
structureCopy: Instance of OrderedCollection that keeps a list of the structure names. The first structure of the list is the one currently being
processed, along with all the decriptors in the case''s description. 

Class variables: None.'!


!SAVCase methodsFor: 'initializing'!

initialize

	"Initializes the variables of its object parent.  The local variable 'descriptionCopy' is initialized as an instance of 
	OrderedCollection"

	super initialize.
	descriptionCopy := OrderedCollection new.
	structureCopy := OrderedCollection new.
	^self.! !

!SAVCase methodsFor: 'adding'!

addPredecessorWith: aPredecessor and: aValue

	| ixv sList s aStructure |

	aStructure := (self currentStructure).
	(aStructure = nil) ifTrue: [ ^nil ].

	sList := nil.
	s := 1.

	[ s <= (predecessors size) ]
	whileTrue: [ 
		(((predecessors at: s) first) = aStructure) 
			ifTrue: [ sList := (predecessors at: s). s := (predecessors size) + 1. ]
			ifFalse: [ s := s + 1 ] ].

	(sList = nil) ifTrue: [ sList := OrderedCollection new. sList add: aStructure. ].
	
	ixv := OrderedCollection new.
	ixv add: aValue.
	ixv add: aPredecessor.
	sList add: ixv.
	(predecessors includes: sList) ifFalse: [ ^predecessors add: sList. ].
	^self.!

addToDescription: aDescriptor

	"Appends aDescriptor to the variable description"

	| descriptor |

	descriptor := SAVDescriptor new.
	descriptor addStructure: aDescriptor structure Attribute: aDescriptor attribute Value: aDescriptor value.
	description add: descriptor.
	^self.!

addToJustification: aDescriptor

	"Appends aDescriptor to the variable justification"

	| descriptor |

	descriptor := SAVDescriptor new.
	descriptor addStructure: aDescriptor structure Attribute: aDescriptor attribute Value: aDescriptor value.
	justification add: descriptor.
	^self.!

addToSuperClassDescription: aDescriptor

	super addToDescription: aDescriptor.
	^self.! !

!SAVCase methodsFor: 'accessing'!

currentStructure

	"Returns the current structure name (the one being handled in some way).  If the list is empty, returns nil. 
	 NOTE: This method assumes the first structure in the list as the current one. It is the responsiblity of the 
	driver process to remove the current structure from the list when not needed any more"

	(structureCopy isEmpty) ifTrue: [ ^nil ].
	^structureCopy first.!

descriptionCopy

	"Returns the ordered collection which contains a copy of the case's original description"

	^descriptionCopy.!

structureCopy

	^structureCopy.! !

!SAVCase methodsFor: 'resetting'!

flush

	super flush.
	self flushDescriptionCopy.
	^self.!

flushDescriptionCopy

	[ descriptionCopy isEmpty ] whileFalse: [ descriptionCopy removeFirst ].
	^self.!

flushStructureCopy

	[ structureCopy isEmpty ] whileFalse: [ structureCopy removeFirst ].
	^self.! !

!SAVCase methodsFor: 'removing'!

removeCurrentStructure

	^structureCopy removeFirst.!

removePredecessorWith: aPredecessor and: aValue

	| currStructure s x |

	currStructure := (self currentStructure).
	(currStructure = nil) ifTrue: [ ^nil ].

	s := 1.
	[ s <= (predecessors size) ]
	whileTrue: [ 
		(((predecessors at: s) first) = currStructure) 
			ifFalse: [ s := s + 1 ]
			ifTrue: [
				x := 2.
				[ x <= ((predecessors at: s) size) ]
				whileTrue: [ 
					((((predecessors at: s) at: x) first = aValue) & (((predecessors at: s) at: x) last  = aPredecessor)) 
					ifTrue: [ ((predecessors at: s) removeAtIndex: x). ^self. ] 
					ifFalse: [ x:= x + 1 ] ].
					s := ((predecessors size) + 1) ] ].
	^nil.! !

!SAVCase methodsFor: 'copying'!

backupDescription

	"Creates a copy of the SAV case's description"

	self flushDescriptionCopy.
	1 to: (description size) do:
		[ :i |  descriptionCopy add: (description at: i) ].
	^self.!

copyStructureListWith: aSList

	(aSList isEmpty) ifTrue: [ ^nil ].
	1 to: (aSList size) do: [:i | structureCopy add: (aSList at: i) ].
	^self structureCopy.!

restoreDescription

	"Restores a SAV case's original description into the variable 'description'"

	self flushDescription.
	1 to: (descriptionCopy size) do:
		[ :i |  description add: (descriptionCopy at: i) ].
	^self.! !

!SAVCase methodsFor: 'private'!

prepareDescriptionWith: aStructure

	| aDescriptor sList |

	self backupDescription.
	self flushDescription.

	sList := OrderedCollection new.
	sList add: aStructure.
	self copyStructureListWith: sList.

	1 to: (descriptionCopy size) do:
		[:i |	((descriptionCopy at: i) structure = aStructure)
			ifTrue: [	
				aDescriptor := Descriptor new.
				aDescriptor addAttribute: ((descriptionCopy at: i) attribute) withValue: ((descriptionCopy at: i) value).
				self addToSuperClassDescription: aDescriptor ] ].
	^self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SAVCase class
	instanceVariableNames: ''!


!SAVCase class methodsFor: 'class name'!

getClassName

	"Returns the Case class name"

	^#SAVCase.! !

Object subclass: #RDMultiNet
	instanceVariableNames: 'root '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Redund. Discrim. Net'!
RDMultiNet comment:
'RDMultiNet

Purpose: Implements the entry structure for a set of redundant discrimination networks, all linked by a common root.
The reasons for having several redundant nets are:
a) This application uses a different type of Descriptor that, instead of consisting of an attribute-value two-tuple, consists
of a structure-attribute-value three-tuple.
b) User requirements specify that user-system interaction should be focused on a structure basis.  That is, it is undesirable 
to evaluate Descriptors belonging to a structure different from the one indicated by the user.
c) This application should reuse, as much as possible, the existing functionality to create and traverse redundant nets
based on two-tuple Descriptors.

Therefore, in order to keep all attribute-value pairs grouped in nets by their corresponding structure, the RDMultiNet creates 
as many redundant discrimination nets as structures there are.  The root of each net is represented by the corresponding
structure name, the structure part of the three-tuple Descriptor is factored out thus leaving the two-tuple Descriptor''s, and the 
final redundant discrimination nets will all be constructed in terms of attibutes and values.

Messages with subclassResponsibility: None.

Instance variables:
root: Instance of RDMultiNetRoot, which contains pointers to all the redundant nets in this muti-net structure.

Class variables: None.'!


!RDMultiNet methodsFor: 'adding'!

add: aCase

	| s structureList descriptorLists SAVdescriptor descriptor SDescription anRDNet |

	"Step 1: Restore the (SAV) case's description"
	aCase backupDescription.

	"Step 2: Segregate the case's description components (.i.e., the tuples (structure, attribute, value)) in separate Descriptor lists
		       represented each of the structures"
	descriptorLists := OrderedCollection new.
	structureList    := OrderedCollection new.
	1 to: (aCase description) size do:

		"Get the next SAVdescriptor"
		[:i |	SAVdescriptor := (aCase description) at: i.

			"Create a new Descriptor and assign its values with those of SAVdescriptor"
			descriptor := Descriptor new.
			descriptor addAttribute: (SAVdescriptor attribute) withValue: (SAVdescriptor value).

			"Determine if the structure name in SAVdescriptor has already been included in structureList"
			(structureList includes: (SAVdescriptor structure)) 
			ifFalse:	[ 
				"The structure name was not found in structureList. Append it to structureList"
				structureList add: (SAVdescriptor structure).

				"Create a new list that will contain all descriptors referenced by the structure name (in SAVdesscriptor).  
				 Append this new list to descriptorLists"
				SDescription := OrderedCollection new.
				SDescription add: descriptor.
				descriptorLists add: SDescription.]

			ifTrue:	[
				"Find the structure name position in structureList (i..e, the index value)"
				s := 1.
				[ s <= (structureList size) ] 
					whileTrue:  [ 

						((SAVdescriptor structure) = (structureList at: s)) 
						ifTrue: [ 
							"Append the descriptor to the corresponding SDescription" 
							(descriptorLists at: s) add: descriptor. 

							"Break out of the loop"
							s := ((structureList size) + 1) ]
						ifFalse: [
							"Try the next element"
							s := s + 1. ] ] ].

		].    "END 1 to: (aCase description) size do:"

	"Step 3: For every (structure-defined) list: a) Copy the segregated description list to the case's description. 
	             b) Create a new NetRoot. c) Add the case to the structure-defined network."
	aCase flushStructureCopy.
	aCase copyStructureListWith: structureList.
	1 to: (structureList size) do:
		[:i |
			aCase flushDescription. 
			[(descriptorLists at: i) isEmpty]
			whileFalse: [ 
						aCase addToSuperClassDescription: (descriptorLists at: i) first. 
						(descriptorLists at: i) removeFirst. ].

			((self root) includes: (structureList at: i))
				ifFalse: [ anRDNet := (self root) addNewRDNetWith: (structureList at: i) ]
				ifTrue: [ anRDNet := (self root) getNetWith: (structureList at: i) ].

			anRDNet add: aCase.
			aCase removeCurrentStructure.

		].    "END 1 to: (structureList size) do:"
			
	"Step 4: Restore the case's original description"
	aCase restoreDescription.
	aCase flushDescriptionCopy.
	aCase flushStructureCopy.

	^self.! !

!RDMultiNet methodsFor: 'initializing'!

initialize

	"Initializes a newly created redundant discrimination multi-network."

	root := RDMultiNetRoot new.
	^self.! !

!RDMultiNet methodsFor: 'accessing'!

root

	"Returns the multi-network root object"

	^root.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RDMultiNet class
	instanceVariableNames: ''!


!RDMultiNet class methodsFor: 'instance creation'!

new

	"Creates a new redundant discrimination multi-network object"

	| RDMN |

	RDMN := super new.
	RDMN initialize.
	^RDMN.! !

!RDMultiNet class methodsFor: 'class name'!

getClassName

	"Returns the redundant discrimination multi-network (i.e., RDMultiNet) class name"

	^#RDMultiNet.! !

Object subclass: #RDMultiNetRoot
	instanceVariableNames: 'nets '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Redund. Discrim. Net'!
RDMultiNetRoot comment:
'RDMultiNetRoot

Purpose: Main element of an RDMultiNet.  The main feature of an RDMultiNetRoot is that it contains a collection of
pointers to all the redundant discrimination nets.

Messages with subclassResponsibility: None.

Instance variables:
nets: Instance of OrderedCollection whose elements should all be of type RDNet.

Class variables: None.'!


!RDMultiNetRoot methodsFor: 'adding'!

addNewRDNetWith: aStructure

	"Adds a new instance of RDNet to the nets list.  Before doing so, the root reference of the newly-created RDNet is changed for one
	 belonging to the class SAVRoot (a subclass of Root).  This way, the 'structure' attribute in the changed root can be accessed"

	| anRDNet aSAVRoot |

	anRDNet := RDNet new.
	aSAVRoot := SAVRoot newWith: aStructure.

	anRDNet resetRootTo: aSAVRoot.
	(self nets) add: anRDNet.
	^anRDNet.! !

!RDMultiNetRoot methodsFor: 'accessing'!

getNetWith: NetRootStructure

	"Returns an RDNet whose root's descriptor has the same name as NetRootStructure; nil otherwise."

	1 to: ((self nets) size) do:
		[:i | (((((self nets) at: i) root) structure) = NetRootStructure) ifTrue: [ ^((self nets) at:i) ] ].
	^nil.!

nets

	"Returns the reference to the nets list"
	^nets.! !

!RDMultiNetRoot methodsFor: 'testing'!

includes: aStructure

	"Returns true if aStructure is the descriptor of an RDNet's root, in the nets list. Returns false otherwise"

	1 to: ((self nets) size) do:
		[:i | (((((self nets) at: i) root) structure) = aStructure) ifTrue: [ ^true ] ].
	^false.! !

!RDMultiNetRoot methodsFor: 'initializing'!

initialize

	"Initializes a newly created multi-net root.  The nets ordered collection is empty at first"

	nets := OrderedCollection new.
	^self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RDMultiNetRoot class
	instanceVariableNames: ''!


!RDMultiNetRoot class methodsFor: 'class name'!

getClassName

	"Returns the RDMultiNetRoot class name"

	^#RDMultiNetRoot.! !

!RDMultiNetRoot class methodsFor: 'instance creation'!

new

	"Creates a new, empty multi-net root"

	| MNR |

	MNR := super new.
	MNR initialize.
	^MNR.! !

