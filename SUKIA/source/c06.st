SortedCollection variableSubclass: #StructureIndex
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Domain Theory'!


!StructureIndex methodsFor: 'accessing'!

structureWith: aStructureName

	1 to: self size do:
	[:i | ((self at: i) name = aStructureName)
		ifTrue: [ ^(self at: i) ] ].

	^nil.! !

!StructureIndex methodsFor: 'testing'!

includes: aStructureName

	1 to: self size do:
	[:i | ((self at: i) name = aStructureName)
		ifTrue: [ ^true ] ].

	^false.! !

!StructureIndex methodsFor: 'initializing'!

initialize

	^(self sortBlock: [ :x :y | (x name) <= (y name) ]).! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

StructureIndex class
	instanceVariableNames: ''!


!StructureIndex class methodsFor: 'instance creation'!

new

	| si |

	si := super new.
	^(si initialize).! !

Object subclass: #Structure
	instanceVariableNames: 'name weight attributes '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Domain Theory'!


!Structure methodsFor: 'accessing'!

attributes

	^attributes.!

attributeWith: anAttributeName

	1 to: attributes size do:
	[:i | ((attributes at: i) name = anAttributeName)
		ifTrue: [ ^(attributes at: i) ] ].

	^nil.!

name

	^name.!

weight

	^weight.! !

!Structure methodsFor: 'initializing'!

initialize

	name := nil.
	weight := 0.0.
	attributes := SortedCollection new.
	attributes sortBlock: [:x :y | (x name) <= (y name)].
	^self.! !

!Structure methodsFor: 'copying'!

copyFrom: aStructure referencing: aTaxon

	| oa na |

	self name: (aStructure name).
	self weight: (aStructure weight).

	1 to: (aStructure attributes size) do:
	[:i |
		oa := aStructure attributes at: i.
		na := Attribute new.
		na copyFrom: oa referencing: aTaxon.
		self attribute: na.
	].

	^self.! !

!Structure methodsFor: 'adding'!

attribute:  anAttribute

	(self includes: anAttribute name)
	ifTrue: [ ^nil ].

	attributes add: anAttribute.
	^self.!

name: aName

	name := aName.
	^self.!

weight: aWeight

	"aWeight must be a floating point number between 0 and 1.
	 NOTE: 0 weight value means no relevance for this structure; 1 weight value means the most relevant"

	| w |

	w := aWeight.
	((w class name) = #Float) ifFalse: [ w := (weight coerce: w) ].
	weight := w.
	^self.! !

!Structure methodsFor: 'testing'!

includes: anAttributeName


	1 to: attributes size do:
	[:i | ((attributes at: i) name = anAttributeName)
		ifTrue: [ ^true ] ].

	^false.! !

!Structure methodsFor: 'description generation'!

createSAVDescription: aDummyName

	"The purpose of this method is to create a list of attribute-unique SAVDescriptors.
	 Since this list is to be used in the identification process, this program assumes
	 that the receiver has been created to collect the user's description. In other words,
	 it is neither a Structure index nor a taxon's Structure.  For this reason, the receiver's
	 attributes must contain a single value, AND no value descriptor can be a range.

	NOTE: The argument aDummyName is to be ignored. This argument was included
	just for polymorphism reasons.

	Returns: nil - if the receiver has no attributes, OR more than one value container 
				 is detected (it is assumed that the receiver is a Structure index), OR 
				 more than ONE value descriptor is detected, OR the value descriptor 
				 is a range.
			 decription: a non-empty list of SAVDescriptors."

	| a vdList vd d description |

	"Make sure there's at least one attribute"
	(self attributes isEmpty)
	ifTrue: [ ^nil ].

	"Check the first attribute, to see if its value has more than one value descriptor container"
	(((self attributes at: 1) values size) = Attribute oneLevel)
	ifFalse: [ ^nil ].

	"Create the description holder"
	description := OrderedCollection new.

	"Scan the receiver's attributes"
	1 to: (self attributes size) do:
	[:i |
		"Get the next attribute and set of value descriptors"
		a := (self attributes at: i).
		vdList := a values valueDescriptorsIn: Attribute oneLevel.

		"Make sure that the value descriptor list only contains ONE item"
		((vdList size) = 1) ifFalse: [ ^nil ].

		"Get the value descriptor and make sure it isn't a range descriptor"
		vd := vdList at: 1.
		(vd asRange) ifTrue: [ ^nil ].

		"Create the new SAVDescriptor and assign its values"
		d := SAVDescriptor new.
		d addStructure: (self name) Attribute: (a name) Value: (vd value).
				
		description add: d.
	
	].    "END 1 to: (self attributes size) do:"

	^description.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Structure class
	instanceVariableNames: ''!


!Structure class methodsFor: 'class name'!

getClassName

	^#Structure.! !

!Structure class methodsFor: 'instance creation'!

new

	|s|

	s := super new.
	^(s initialize).! !

Object subclass: #Taxon
	instanceVariableNames: 'level name predecessor successors SAVdescription GHdescription '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Domain Theory'!


!Taxon methodsFor: 'initializing'!

initialize

	level := nil.
	name := nil.
	predecessor := nil.

	successors := SortedCollection new.
	successors sortBlock: [:x :y | (x name) <= (y name) ].

	SAVdescription := SortedCollection new.
	SAVdescription sortBlock: [:x :y | (x name) <= (y name) ].

	GHdescription := SortedCollection new.
	GHdescription sortBlock: [:x :y | (x name) <= (y name) ].

	^self.! !

!Taxon methodsFor: 'accessing'!

GHdescription

	^GHdescription.!

level

	^level.!

name

	^name.!

predecessor

	^predecessor.!

SAVdescription

	^SAVdescription.!

successors

	^successors.! !

!Taxon methodsFor: 'linking'!

linkTo: aTaxon

	self predecessor: aTaxon.
	aTaxon successor: self.
	^self.!

unlinkFromTheHierarchy

	| p |

	p := self predecessor.
	1 to: (p successors) size do:
	[:i |
		((p successors at: i) = self)
		ifTrue: [ p successors removeAtIndex: i. self predecessor: nil. ^self. ].
	].

	^nil.! !

!Taxon methodsFor: 'adding-private'!

predecessor: aTaxon

	predecessor := aTaxon.
	^self.!

successor: aTaxon

	successors add: aTaxon.
	^self.! !

!Taxon methodsFor: 'inheritance'!

isSuccessorOf: aTaxon

	| predecessorTaxon |

	((TaxonomicLevels transformToIndex: (self level)) <=
	 (TaxonomicLevels transformToIndex: (aTaxon level)))
	ifTrue: [ ^false ].

	predecessorTaxon := self predecessor.
	[ predecessorTaxon level = TaxonomicLevels root ]
	whileFalse: [

		(predecessorTaxon name = aTaxon name)
		ifTrue: [ ^true ].

		predecessorTaxon := (predecessorTaxon predecessor).
	].

	^false.! !

!Taxon methodsFor: 'testing'!

GHRangesConsistentWith: aParentTaxon

	"If the receiver's GH description contains grouping heuristics with range values, then, for each one of those grouping heuristics:
	 seek a grouping heuristic in the receiver's predecessor's GH description whose name matches the (receiver's) grouping heuristic name;
	 if the grouping heuristic is found, seek a ValueDescriptor that is a range value;
	 if the ValueDescriptor is found, determine if the measuring units are the same, and if the receiver's range value lies within  the ValueDescriptor 
	 range just found.
	 If the ranges are consistent, return true. Else, return false (i.e., inconsistent ranges).
	 If neither the first nor the second steps are satisfied, get the receiver's predecessor's predecessor, and start again.
	 This method will stop when the predecessor's level is ROOT"

	| gh vd pt pgh pvd |

	((self predecessor level) = (TaxonomicLevels levels first))
	ifTrue: [ ^true ].

	"Parse the receiver's grouping heuristic (GH) description"
	1 to: GHdescription size do:
	[:i |

		"Get the next grouping heuristic in the receiver's GH description"
		gh := GHdescription at: i.
		1 to: ((gh values at: GroupingHeuristic oneLevel) size) do:
		[:j |
			"Get the next value descriptor, and test if it's a range value"
			vd := ((gh values) at: GroupingHeuristic oneLevel) at: j.
			(vd asRange)
			ifTrue: [

				"The grouping heuristic's value descriptor is a range value.  Get the receiver's predecessor 
				 and loop while the predecessor's level is not ROOT"
				pt := aParentTaxon.
				[ ((pt level) = (TaxonomicLevels root)) ]
				whileFalse: [

					"Find a grouping heuristic, in the predecessor's GH description, such that its name matches the
	 				 receiver's retrieved grouping heuristic"
					pgh := (pt getAnObjectWith: (gh name) in: (pt GHdescription)).
					(pgh = nil) 
					ifTrue: [ 

						"Grouping heuristic not found. Get the predecessor's predecessor, and loop all over again"
						pt := pt predecessor.
					]
					ifFalse: [

						"The grouping heuristic was found.  Find a value descriptor, in the predecessor's grouping heuristic's value 
						 descriptor list, such that it is a range value"
						1 to: ((pgh values) at: GroupingHeuristic oneLevel) size do: 
						[:k |
							pvd := ((pgh values) at: GroupingHeuristic oneLevel) at: k.
							(pvd asRange) 
							ifTrue: [

								"Value descriptor found. If the measuring units for the receiver's retrieved range value and the 
								 predecessor's range value are different, then there is an inconsistency"
								((vd measuringUnit) = (pvd measuringUnit))
								ifFalse: [ ^false ]
								ifTrue: [ 

									"Measuring units are the same for both ranges.  Determine if the receiver's value descriptor
									 range lies within the predecessor's value descriptor range"
									(vd rangeWIthin: (pvd lowerBound) and: (pvd upperBound)) 
									ifTrue: [ ^true ].
									^false.

								].    "END ((vd measuringUnit) = (ptvd measuringUnit)) ifTrue: ["

							].    "END (ptvd asRange) ifTrue: [ "

						]    "END 1 to: ((ptgh values) at: GroupingHeuristic oneLevel) size do: "

					]    "END (pgh = nil) ifFalse: ["

				]    "END [ pt = TaxonomicLevels first ] whileFalse: ["

			]    "END (vd asRange) ifTrue: ["

		]    "END 1 to: ((gh values at: GroupingHeuristic oneLevel) size) do:"

	].    "END 1 to: GHdescription do:"

	"The entire GH decription of the receiver was parsed and nothing was found in the GH description of all its
	 predecessors. Thus, assume there are no inconsistencies"
	^true.!

includes: aName in: aDescription

	1 to: (aDescription size) do:
	[:i |
		(((aDescription at: i) name) = aName)
		ifTrue: [ ^true ].
	].
	^false.!

SAVRangesConsistentWith: aParentTaxon

	"If the receiver's SAV description contains structures with attributes that have range values, then, for each one of those structures:
	 seek a structure in the receiver's predecessor's SAV description whose name matches the (receiver's) structure name;
	 if the structure is found, seek in the attributes of the found structure for an attribute that matches the (receiver's structure) attribute name;
	 if the attribute is found, seek a ValueDescriptor that is a range value;
	 if the ValueDescriptor is found, determine if the measuring units are the same, and if the receiver's range value lies within the ValueDescriptor 
	 range just found.
	 If the ranges are consistent, return true. Else, return false (i.e., inconsistent ranges).
	 If neither the first nor the second steps are satisfied, get the receiver's predecessor's predecessor, and start again.
	 This method will stop when the predecessor's level is ROOT"

	| s a vd pt pts pta ptvd |

	(self predecessor level = TaxonomicLevels levels first)	
	ifTrue: [ ^true ].

	"Parse the receiver's SAV (structure) description"
	1 to: SAVdescription size do:
	[:i |

		"Get the next structure in the receiver's SAV description"
		s := SAVdescription at: i.
		1 to: (s attributes size) do:
		[:j |

			"Get the next attribute a from the retrieved structure"
			a := (s attributes) at: j.
			1 to: ((a values) at: Attribute oneLevel) size do:
			[:k |

				"For the retrieved attribute, get the next value descriptor, and test if it's a range value"
				vd := ((a values) at: Attribute oneLevel) at: k.
				(vd asRange)
				ifTrue: [

					"The attribute's value descriptor is a range value.  Get the receiver's predecessor and loop while the 
					 predecessor's level is not ROOT"
					pt := aParentTaxon.
					[ ((pt level) = (TaxonomicLevels root)) ]
					whileFalse: [

						"Find a structure, in the predecessor's SAV description, such that its name matches the
	 					 receiver's retrieved structure"
						pts := (pt getAnObjectWith: (s name) in: (pt SAVdescription)).
						(pts = nil) 
						ifTrue: [ 

							"Structure not found. Get the predecessor's predecessor, and loop all over again"
							pt := pt predecessor.
						]
						ifFalse: [

							"The structure was found.  Find an attribute, in the predecessor's structure's attribute list, 
							 such that its name matches the receiver's retrieved attribute name"
							pta := (pts attributeWith: (a name)).
							(pta = nil)
							ifTrue: [

								"Attribute not found. Get the predecessor's predecessor, and loop all over again"
								pt := pt predecessor.
							]
							ifFalse: [

								"Attribute found"
								1 to: ((pta values) at: Attribute oneLevel) size do:
								[:m |

									"Find a value descriptor, in the predecessor's attribute value descriptor list, such that it is a range value"
									ptvd := ((pta values) at: Attribute oneLevel) at: m.
									(ptvd asRange) 
									ifTrue: [

										"Value descriptor found. If the measuring units for the receiver's retrieved range value and the 
										 predecessor's range value are different, then there is an inconsistency"
										((vd measuringUnit) = (ptvd measuringUnit))
										ifFalse: [ ^false ]
										ifTrue: [ 

											"Measuring units are the same for both ranges.  Determine if the receiver's value descriptor
											 range lies within the predecessor's value descriptor range"
											(vd rangeWIthin: (ptvd lowerBound) and: (ptvd upperBound)) 
											ifTrue: [ ^true ].
											^false.

										].    "END ((vd measuringUnit) = (ptvd measuringUnit)) ifTrue: ["

									].    "END (ptvd asRange) ifTrue: [ "

								]    "END 1 to: (pta values size) do:"

							]    "END (pta = nil) ifFalse: ["

						]    "END (pts = nil) ifFalse: ["

					]    "END [ pt = TaxonomicLevels first ] whileFalse: ["

				]    "END (vd asRange) ifTrue: ["

			]    "END 1 to: ((a values) at: Attribute oneLevel) size do:"

		]    "END 1 to: (s attributes size) do:"

	].    "END 1 to: SAVdescription do:"

	"The entire SAV decription of the receiver was parsed and nothing was found in the SAV description of all its
	 predecessors. Thus, assume there are no inconsistencies"
	^true.! !

!Taxon methodsFor: 'searching'!

getAnObjectWith: aName in: aDescription

	1 to: (aDescription size) do:
	[:i |
		(((aDescription at: i) name) = aName)
		ifTrue: [ ^(aDescription at: i) ].
	].
	^nil.! !

!Taxon methodsFor: 'adding'!

GHdescription: aGroupingHeuristic

	(self includes: aGroupingHeuristic name in: self GHdescription)
	ifTrue: [ ^nil ].

	^(GHdescription add: aGroupingHeuristic).!

level: aLevel

	"The name of any taxonomic level must be a sequnce of ByteSymbol characters, and it must 
	be included in the class TaxonomicLevels (i.e., TaxonomicLevels includes: aLevel must be TRUE 
	before the argument can be assigned to the instance variable 'level'.
	NOTE: This program assumes that the argument has been previously verified by the View-related objects."

	level := aLevel.
	^self.!

name: aName

	"The name of  any taxon must be a single sequence of ByteSymbol characters. This program assumes
	that the argument 'aName' has been previously verified by the View-related objects. To avoid name
	confusion or duplications, without exception ALL NAMES MUST BE IN LOWERCASE LETTERS.
	Names belonging to the species level MUST have an underscore between the genus name and the
	epithet. The two main reasons for having species names in this format are:
	1. Search speed: it's faster to compare against the species' instance variable 'name', than having to 
	    compare the epithet part against the species' 'name' and then asking its corresponding predecessor 
	    taxon (the genus) for it's name, before any comparison can be made.
	2. In the unlikely event that a species Taxon ever became unlinked from the hierarchy, it would a lot 
	    easier to link it again to its parent genus if the name is complete (i..e, genus + epithet) that if the
	    name consisted only of the epithet.
	Examples:
	For a family, the name might be: #fabaceae.
	For a genus: #lantana.
	For a species, the name MUST be composed of the corresponding genus name plus the epithet, 
	separated by an undersore: #lantana_camara."

	name := aName.
	^self.!

SAVdescription: aStructure

	(self includes: aStructure name in: self SAVdescription)
	ifTrue: [ ^nil ].

	^(SAVdescription add: aStructure).! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Taxon class
	instanceVariableNames: ''!


!Taxon class methodsFor: 'instance creation'!

new

	| t |

	t := super new.
	t initialize.
	^t.! !

!Taxon class methodsFor: 'class name'!

getClassName

	^#Taxon.! !

Object variableSubclass: #TaxonomicLevels
	instanceVariableNames: ''
	classVariableNames: 'Levels '
	poolDictionaries: ''
	category: 'CBR - Sukia Domain Theory'!

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TaxonomicLevels class
	instanceVariableNames: ''!


!TaxonomicLevels class methodsFor: 'class initialization'!

initialize

	"Adds taxonomic level names to the Levels list. The first level MUST always be #root. All other level names MUST be added 
	according to their hierarchical ordering.  Thus, the second name in the list represents the MOST general taxonomic level, while 
	the last name represents the most specific taxonomic level.

	PRECONDITION: There must be at least two taxonomic level names: #root + #aTaxonomicLevelName."

	(Levels = nil)
	ifTrue: [

		Levels := OrderedCollection new.
		Levels add: #root.
		Levels add: #family.
		Levels add: #genus.
		Levels add: #species.
	].! !

!TaxonomicLevels class methodsFor: 'testing'!

includes: aTaxonomicLevelName

	^(Levels includes: aTaxonomicLevelName).!

isLinkOKBetween: aParentTaxon and: aSuccessorTaxon

	^(((TaxonomicLevels getNumberByName: (aSuccessorTaxon level)) - (TaxonomicLevels getNumberByName: (aParentTaxon level))) = 1)! !

!TaxonomicLevels class methodsFor: 'accessing'!

levels

	"Returns the list of taxonomic levels"

	^Levels.!

mostGeneralLevel

	"Returns the most general taxonomic level name, which always must be the second name in the levels list (i.e., the taxonomic hierarchy)"

	^(self levels at: 2).!

mostSpecificLevel

	"Returns the most specific taxonomic level name, which always must be the last name in the levels list (i.e., the taxonomic hierarchy)"

	^(self levels last).!

root

	"Returns the root level name, which always must be the first name in the levels list (i.e., the taxonomic hierarchy)"

	^(self levels first).! !

!TaxonomicLevels class methodsFor: 'class messages'!

getNameByNumber: aNumber

	(aNumber < 0) | (aNumber > ((self levels size) - 1))
	ifTrue: [ ^nil ].

	^(self levels at: (aNumber+1)).!

getNumberByName: aName

	1 to: (self levels size) do:
	[:i | (((self levels) at: i) = aName) ifTrue: [ ^(i - 1) ] ].
	^nil.!

nomenclaturalNumber

	"Three taxonomic levels for this implementation: 1 - family; 2 - genus; 3 - species"
	^(self levels size - 1).!

totalNumber

	"Four taxonomic levels for this implementation: 0 - #root; 1 - family; 2 - genus; 3 - species"
	^(self levels size).!

transformToIndex: aLevel

	| levelNumber |

	((aLevel class name) = #ByteSymbol)
	ifTrue: [ levelNumber := (self getNumberByName: aLevel) ]
	ifFalse: [ 
		((aLevel class name) = #SmallInteger) 
		ifTrue: [ levelNumber := aLevel ]
		ifFalse: [ levelNumber := nil ] 
	].

	((levelNumber = nil) | (levelNumber < (self getNumberByName: #family)) | (levelNumber > (self nomenclaturalNumber)))
	ifTrue: [ ^nil ]
	ifFalse: [ ^levelNumber ].! !

SortedCollection variableSubclass: #GroupingHeuristicIndex
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Domain Theory'!


!GroupingHeuristicIndex methodsFor: 'testing'!

includes: aGroupingHeuristicName

	1 to: self size do:
	[:i | ((self at: i) name = aGroupingHeuristicName)
		ifTrue: [ ^true ] ].

	^false.! !

!GroupingHeuristicIndex methodsFor: 'initializing'!

initialize

	^(self sortBlock: [ :x :y | (x name) <= (y name) ]).! !

!GroupingHeuristicIndex methodsFor: 'accessing'!

groupingHeuristicWith: aGHName

	1 to: self size do:
	[:i | ((self at: i) name = aGHName)
		ifTrue: [ ^(self at: i) ] ].

	^nil.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

GroupingHeuristicIndex class
	instanceVariableNames: ''!


!GroupingHeuristicIndex class methodsFor: 'instance creation'!

new

	| ghi |

	ghi := super new.
	^(ghi initialize).! !

Object subclass: #GroupingHeuristic
	instanceVariableNames: 'name weight values '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Domain Theory'!


!GroupingHeuristic methodsFor: 'initializing'!

initialize

	name := nil.
	weight := 0.0.
	values := Value new.
	^self.! !

!GroupingHeuristic methodsFor: 'adding'!

name: aName

	name := aName.
	^self.!

weight: aWeight

	"aWeight must be a floating point number between 0 and 1.
	 NOTE: 0 weight value means no relevance for this structure; 1 weight value means the most relevant"

	| w |

	w := aWeight.
	((w class name) = #Float) ifFalse: [ w := (weight coerce: w) ].
	weight := w.
	^self.! !

!GroupingHeuristic methodsFor: 'accessing'!

name

	^name.!

values 

	^values.!

weight

	^weight.! !

!GroupingHeuristic methodsFor: 'copying'!

copyFrom: aGroupingHeuristic referencing: aTaxon

	| ovd nvd vList |

	((self values size) < (aGroupingHeuristic values size))
	ifTrue: [ ^nil ].

	self name: (aGroupingHeuristic name).
	self weight: (aGroupingHeuristic weight).

	1 to: (aGroupingHeuristic values size) do:
	[:i |
		vList := (aGroupingHeuristic values at: i).
		1 to: (vList size) do:
		[:j |
			ovd := (vList at: j).
			nvd := ValueDescriptor new.
			nvd copyFrom: ovd referencing: aTaxon.

			((self values size) = (aGroupingHeuristic values size))
			ifTrue: [ (self values) valueDescriptor: nvd for: i ]
			ifFalse: [ (self values) valueDescriptor: nvd for: aTaxon level ].
		].
	].

	^self.! !

!GroupingHeuristic methodsFor: 'description generation'!

createSAVDescription: aTaxonomicGroupName

	"The purpose of this method is to create a list of one SAVDescriptor. Since this list 
	 is to be used in the identification process, this program assumes that the receiver 
	 has been created to collect the user's description. In other words, it is neither a 
	 GroupingHeuristic index nor a taxon's GroupingHeuristic.  For this reason, the receiver's
	 values list must contain ONE value descriptor, AND the value descriptor can not be a range.

	Returns: nil - if more than one value container is detected (it is assumed that the receiver 
				 is a GroupingHeuristic index), OR more than ONE value descriptor is detected, 
				 OR the value descriptor is a range.
			 decription: a non-empty list of SAVDescriptors."

	| vdList vd d description |

	"Check if its value has more than one value descriptor container"
	((self values size) = GroupingHeuristic oneLevel)
	ifFalse: [ ^nil ].

	"Create the description holder"
	description := OrderedCollection new.

	"Get the set of value descriptors"
	vdList := self values valueDescriptorsIn: GroupingHeuristic oneLevel.

	"Make sure that the value descriptor list only contains ONE item"
	((vdList size) = 1) ifFalse: [ ^nil ].

	"Get the value descriptor and make sure it isn't a range descriptor"
	vd := vdList at: 1.
	(vd asRange) ifTrue: [ ^nil ].

	"Create the new SAVDescriptor and assign its values"
	d := SAVDescriptor new.
	d addStructure: aTaxonomicGroupName Attribute: (self name) Value: (vd value).
				
	description add: d.

	^description.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

GroupingHeuristic class
	instanceVariableNames: ''!


!GroupingHeuristic class methodsFor: 'instance creation'!

new

	|gh|

	gh := super new.
	^(gh initialize).!

newWithOneLevel

	|gh|

	gh := super new.
	gh initialize.
	[ gh values size > 1 ]
	whileTrue: [ gh values removeFirst ].
	^gh.! !

!GroupingHeuristic class methodsFor: 'class name'!

getClassName 

	^#GroupingHeuristic.! !

!GroupingHeuristic class methodsFor: 'one level'!

oneLevel

	^1.! !

Object subclass: #Attribute
	instanceVariableNames: 'name values '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Domain Theory'!


!Attribute methodsFor: 'initializing'!

initialize

	name := nil.
	values := Value new.
	^self.! !

!Attribute methodsFor: 'adding'!

name: aName

	name := aName.
	^self.! !

!Attribute methodsFor: 'accessing'!

name 

	^name.!

values

	^values.! !

!Attribute methodsFor: 'copying'!

copyFrom: anAttribute referencing: aTaxon

	| ovd nvd vList |

	((self values size) < (anAttribute values size))
	ifTrue: [ ^nil ].

	self name: (anAttribute name).

	1 to: (anAttribute values size) do:
	[:i |
		vList := (anAttribute values at: i).
		1 to: (vList size) do:
		[:j |
			ovd := (vList at: j).
			nvd := ValueDescriptor new.
			nvd copyFrom: ovd referencing: aTaxon.
			((self values size) = (anAttribute values size))
			ifTrue: [ (self values) valueDescriptor: nvd for: i ]
			ifFalse: [ (self values) valueDescriptor: nvd for: aTaxon level ].
		].
	].

	^self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Attribute class
	instanceVariableNames: ''!


!Attribute class methodsFor: 'instance creation'!

new

	|a|

	a := super new.
	^(a initialize).!

newWithOneLevel

	|a|

	a := super new.
	a initialize.
	[ a values size > 1 ]
	whileTrue: [ a values removeFirst ].
	^a.! !

!Attribute class methodsFor: 'one level'!

oneLevel

	^1.! !

Object subclass: #Taxonomy
	instanceVariableNames: 'structureIndex groupingHeuristicIndex rootTaxon levelIndex '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'CBR - Sukia Domain Theory'!


!Taxonomy methodsFor: 'searching'!

taxonInDividedList: aListDividedByLevels with: aTaxonName

	1 to: (aListDividedByLevels size) do:
	[: i |
		1 to: (aListDividedByLevels at: i) size do:
		[:j |
			(((aListDividedByLevels at: i) at: j) name = aTaxonName)
			ifTrue: [ ^((aListDividedByLevels at: i) at: j) ].
		].
	].

	^nil.!

taxonInSimpleList: aList with: aTaxonName

	1 to: (aList size) do:
	[:i |
		((aList at: i) name = aTaxonName)
		ifTrue: [ ^(aList at: i) ].
	].

	^nil.! !

!Taxonomy methodsFor: 'accessing'!

getTaxonByName: aTaxonName

	^(self taxonInDividedList: (self levelIndex) with: aTaxonName).!

getTaxonByName: aTaxonName level: aLevel

	^(self taxonInSimpleList: (self levelIndexAt: (TaxonomicLevels transformToIndex: aLevel)) with: aTaxonName).!

groupingHeuristicIndex 

	^groupingHeuristicIndex.!

levelIndex

	^levelIndex.!

levelIndexAt: aLevel

	| levelNumber |

	levelNumber := TaxonomicLevels transformToIndex: aLevel.
	(levelNumber = nil) ifTrue: [ ^nil ].

	^(levelIndex at: levelNumber).!

rootTaxon 

	^rootTaxon.!

structureIndex

	^structureIndex.! !

!Taxonomy methodsFor: 'taxonomic dependencies'!

processTaxonomicDependenciesBetween: aParentTaxon and: aSuccessorTaxon

	"Step 1: Make sure that (at least) the SAV description of the successor taxon is not empty"
	((aSuccessorTaxon SAVdescription) isEmpty)
	ifTrue: [ ^nil ].

	"Step 2: Make sure that the successor taxon's level name exists"
	(TaxonomicLevels includes: (aSuccessorTaxon level))
	ifFalse: [ ^nil ].

	"Step 3: Make sure that the successor taxon can indeed be linked to the parent taxon"
	(TaxonomicLevels isLinkOKBetween: aParentTaxon and: aSuccessorTaxon)
	ifFalse: [ ^nil ].

	"Step 4: Make sure that a taxon with the successor's name does not already exist"
	(self includes: aSuccessorTaxon)
	ifTrue: [ ^nil ].

	"*****     *****     ***** 
	Step 5: Special case for SPECIES: Make sure that the associated genus does not contain another 
	species with the same name.  
	NOTE (26-Jun-1999, HB): Step 5 is now obsolete, since ALL taxon names are now assumed to be unique, even
	at the species level (names at the species level are composite; see the name: method of class Taxon for details).
	(aSuccessorTaxon level = #species)
	ifTrue: [ (aParentTaxon includes: (aSuccessorTaxon name) in: (aParentTaxon successors)) ifTrue: [ ^nil ] ]. 
	*****     *****     *****"

	"Step 6: Link the successor taxon to the hierarchy"
	aSuccessorTaxon linkTo: aParentTaxon.

	"Step 7: Make sure that all the value ranges specified in the SAV description of the successor taxon are consistent with those of its predecessors' "
	(aSuccessorTaxon SAVRangesConsistentWith: aParentTaxon)
	ifFalse: [ aSuccessorTaxon unlinkFromTheHierarchy. ^nil ].

	"Step 8: Make sure that all the value ranges specified in the GH description of the successor taxon are consistent with those of its predecessors' "
	(aSuccessorTaxon GHdescription isEmpty)
	ifFalse: [ 
		(aSuccessorTaxon GHRangesConsistentWith: aParentTaxon)
		  ifFalse: [ aSuccessorTaxon unlinkFromTheHierarchy. ^nil ]
	].

	^self.! !

!Taxonomy methodsFor: 'testing'!

includes: aTaxon

	"This program assumes the name of all taxa to be unique, regarless of the level.  That is, even at the
	 species level, names MUST be unique because they are composite names (see the name: method in
	 class Taxon for details"

	| t |

	1 to: (levelIndex size) do:
	[:i |
		1 to: (levelIndex at: i) size do:
		[:j |

			t := (levelIndex at: i) at: j.
			(t name = aTaxon name)
			ifTrue: [ ^true ].

		]    "END 1 to: (levelIndex at: i) size do:"

	].    "END 1 to: (levelIndex size) do:"

	^false.!

includes_old: aTaxon

	"This program assumes the name of a species as: taxon->species name + taxon->species predecessor name.
	That's the reason why the species level is NOT scanned: epithets may repeat for different genera"

	| t |

	1 to: (levelIndex size) do:
	[:i |
		(i = (TaxonomicLevels getNumberByName: #species))
		ifFalse: [
			1 to: (levelIndex at: i) size do:
			[:j |

				t := (levelIndex at: i) at: j.
				(t name = aTaxon name)
				ifTrue: [ ^true ].

			]    "END 1 to: (levelIndex at: i) size do:"

		]    "END (i = TaxonomicLevels getNumberByName: #species) ifFalse: ["

	].    "END 1 to: (levelIndex size) do:"

	^false.! !

!Taxonomy methodsFor: 'adding'!

add: aNewTaxon linkedTo: anExistingTaxon

	"Step 1: link the new taxon to the existing taxon in the hierarchy, if all taxonomic dependencies are OK."
	((self processTaxonomicDependenciesBetween: anExistingTaxon and: aNewTaxon) = nil)
	ifTrue: [ ^nil ].

	"Step 2: Reference the new taxon in levelIndex (i.e., alphabetically by taxon name, by taxonomic level)"
	(self levelIndex: aNewTaxon) = nil
	ifTrue: [ aNewTaxon unlinkFromTheHierarchy. ^nil ].

	"Step 3: Reference the new taxon in structureIndex"
	self structureIndex: aNewTaxon.

	"Step 4: Reference the new taxon in groupingHeuristicIndex"
	self groupingHeuristicIndex: aNewTaxon.

	^self.! !

!Taxonomy methodsFor: 'adding-private'!

groupingHeuristicIndex: aNewTaxon

	"Precondition: all attributes included in the structures of aNewTaxon MUST have one-level values"

	| ngh gh nvd vd |

	1 to: (aNewTaxon GHdescription size) do:
	[:i |
		"Get the next grouping heuristic from the new taxon"
		ngh := aNewTaxon GHdescription at: i.

		"Find a grouping heuristic, in the Grouping Heuristic Index, with a name that matches the new taxon's heuristic name"
		gh := self groupingHeuristicIndex groupingHeuristicWith: (ngh name).
		(gh = nil)
		ifTrue: [

			"Grouping heuristic not found.  Create a new grp. heuristic, copy its contents from the new taxon's grp. heurist.
			 (referencing the new taxon in all the ValueDescriptor instances), and add it to the Grouping Heuristic Index"
			gh := GroupingHeuristic new.
			gh copyFrom: ngh referencing: aNewTaxon.
			gh weight: 0.0.
			self groupingHeuristicIndex add: gh.

		]    "END (s = nil) ifTrue: ["

		"(gh = nil)"
		ifFalse: [

			"Grouping heuristic found in the Grouping Heuristic Index"
			1 to: (ngh values at: (GroupingHeuristic oneLevel)) size do:
			[:j |

				"Get the next value descriptor that belongs to the new taxon's grouping heuristic"
				nvd := (ngh values at: (GroupingHeuristic oneLevel)) at: j.

				"Find a value descriptor for the grouping heuristic (that was found in the Grouping Heuristic Index), 
				 with a descriptor matching that of the new taxon's grouping heuristic descriptor"
				vd := (gh values) getMatchingValueDescriptorFor: nvd in: (aNewTaxon level).

				(vd = nil)
				ifTrue: [

					"ValueDescriptor not found.  Create a new value descriptor, copy its contents from the new taxon's grouping
					 heuristic value descriptor (referencing the new taxon), and add it to the grouping heuristic values list"
					vd := ValueDescriptor new.
					vd copyFrom: nvd referencing: aNewTaxon.
					(gh values) valueDescriptor: vd for: aNewTaxon level.

				]    "END (vd = nil) ifTrue:["

				"(vd = nil)"
				ifFalse: [

					"ValueDescriptor found for the grp. heurist. (that belongs to the Grouping Heuristic Index).
					 Here, all that we need to do is reference the new taxon to this ValueDescriptor"
					vd taxon: aNewTaxon.

				].    "END (vd = nil) ifFalse:["

			].    "END (gh values at: (GroupingHeuristic oneLevel)) size do:"

		].    "END (gh = nil) ifFalse: ["

	].    "END 1 to: (aNewTaxon GHdescription size) do:"

	^self.!

levelIndex: aTaxon

	| levelNumber |

	levelNumber := TaxonomicLevels transformToIndex: aTaxon level.
	(levelNumber = nil) ifTrue: [ ^nil ].

	(self levelIndex at: levelNumber) add: aTaxon.
	^self.!

structureIndex: aNewTaxon

	"Precondition: all attributes included in the structures of aNewTaxon MUST have one-level values"

	| ns s na a nvd vd |

	1 to: (aNewTaxon SAVdescription size) do:
	[:i |
		"Get the next structure from the new taxon's description"
		ns := aNewTaxon SAVdescription at: i.

		"Find a structure, in the Structure Index, with a name that matches the new taxon's structure name"
		s := self structureIndex structureWith: (ns name).
		(s = nil)
		ifTrue: [

			"Structure not found.  Create a new structure, copy its contents from the new taxon's structure
			 (referencing the new taxon in all the ValueDescriptor instances), and add it to the Structure Index"
			s := Structure new.
			s copyFrom: ns referencing: aNewTaxon.
			s weight: 0.0.
			self structureIndex add: s.

		]    "END (s = nil) ifTrue: ["

		"(s = nil)"
		ifFalse: [

			"Structure found in the Structure Index"
			1 to: (ns attributes size) do:
			[:j |
				"Get the next attribute from the new taxon's structure"
				na := ns attributes at: j.

				"Find an attribute, belonging to the structure found in in the Structure Index, with a name 
				 that matches the new taxon's structure attribute name"
				a := s attributeWith: (na name).
				(a = nil)
				ifTrue: [

					"Attribute not found.  Create a new attribute, copy its contents from the new taxon's structure
					 attribute (referencing the new taxon in all the ValueDescriptor instances), and add it to the structure's
					attribute list"
					a := Attribute new.
					a copyFrom: na referencing: aNewTaxon.
					s attribute: a.

				]    "END (a = nil) ifTrue: ["

				"(a = nil)"
				ifFalse: [

					"Attribute found in the structure's list (the structure that belongs to the Structure Index)"
					1 to: (na values at: (Attribute oneLevel)) size do:
					[:k |

						"Get the next value descriptor from the attribute that belongs to the new taxon's structure"
						nvd := (na values at: (Attribute oneLevel)) at: k.

						"Find a value descriptor for the attribute (that was found in the structure that belongs to the Structure Index), 
						 with a descriptor matching that of the new taxon's structure-attribute descriptor"
						vd := (a values) getMatchingValueDescriptorFor: nvd in: (aNewTaxon level).

						(vd = nil)
						ifTrue: [

							"ValueDescriptor not found.  Create a new value descriptor, copy its contents from the new taxon's structure
							 attribute value descriptor (referencing the new taxon), and add it to the structure's attribute values list"
							vd := ValueDescriptor new.
							vd copyFrom: nvd referencing: aNewTaxon.
							(a values) valueDescriptor: vd for: aNewTaxon level.

						]    "END (vd = nil) ifTrue:["

						"(vd = nil)"
						ifFalse: [

							"ValueDescriptor found for the attribute (that belongs to the structure found in the Structure Index).
							 Here, all that we need to do is reference the new taxon to this ValueDescriptor"
							vd taxon: aNewTaxon.

						].    "END (vd = nil) ifFalse:["

					].    "END 1 to: (na values at: (Attribute oneLevel)) do:"

				].    "END (a = nil) ifFalse: ["

			].    "END 1 to: (s attributes size) do:"

		].    "END (s = nil) ifFalse: ["

	].    "END 1 to: (aNewTaxon SAVdescription size) do:"

	^self.! !

!Taxonomy methodsFor: 'initializing'!

initialize

	| level |

	structureIndex := StructureIndex new.
	groupingHeuristicIndex := GroupingHeuristicIndex new.

	rootTaxon := Taxon new.
	rootTaxon name: nil.
	rootTaxon level: #root.

	levelIndex := OrderedCollection new.
	(TaxonomicLevels nomenclaturalNumber) timesRepeat:
	[ level := SortedCollection new. level sortBlock: [:x :y | (x name) <= (y name)].
	  levelIndex add: level. ].
	^self.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Taxonomy class
	instanceVariableNames: ''!


!Taxonomy class methodsFor: 'class initialization'!

initializeClasses

	"Initialize all classes needed by Taxonomy"

	TaxonomicLevels initialize.
	MeasuringUnit initialize.! !

!Taxonomy class methodsFor: 'instance creation'!

new

	| t |

	self initializeClasses.

	t := super new.
	t initialize.
	^t.! !
TaxonomicLevels initialize!


