# \file
# \brief generic function to walk collection trees
# \author Ton Smeele
# \copyright Copyright (c) 2015, Utrecht university. All rights reserved
# \license GPLv3, see LICENSE

#test {
#	uuTreeWalk(*direction, *topLevelCollection, *ruleToProcess, *error);
#	writeLine("stdout","result treewalk = *error");
#}

# here is an example of a rule that can be processed via uuTreeWalk:
#
#uuTreeWalkTestrule(*itemParent, *itemName, *itemIsCollection, *buffer) {
#	writeLine("stdout","*itemParent - *itemName - *itemIsCollection");
#	*buffer."error" = "0"; # zero means no error 
#   if (*itemName == "tree.r" ) {
#		*buffer."error" = "0";
#	}
#}


# \brief walks through a collection tree and calls an arbitrary rule for each tree-item
# 
# \param[in] direction           can be "forward" or "reverse" 
#                                forward means process collection itself, then childs
#                                reverse means process childs first
#                                reverse is useful e.g. to delete collection trees
# \param[in] topLevelCollection  pathname of the root of the tree, must be collection
#                                NB: the root itself is also processed
# \param[in] ruleToProcess       name of the rule that can perform an action on tree items
#                                Requirement: rule must be preloaded in rulebase
#                                The rule should expect the following parameters:
#                                  itemParent  = full iRODS path to the parent of this object
#                                  itemName  = basename of collection or dataobject
#                                  itemIsCollection = true if the item is a collection
#                                  buffer = in/out Key-Value variable
#                                       the buffer is maintained by treewalk and passed
#                                       on to the processing rule. can be used by the rule
#                                       to communicate data to subsequent rule invocations
#                                       buffer."error" can be updated by the rule to indicate
#                                       an error, the treewalk will stop
# \param[out] error             error result as may be set by the rule that is processed
#                                  a value of "0" means no error
#                                  other values indicate an error and process is interrupted
uuTreeWalk(*direction, *topLevelCollection, *ruleToProcess,*error) {

# create a buffer that can be used by the rule that we will call for each item
# content is arbitrary, just put something in to cast the variable to KV in this scope
	*buffer."path" = *topLevelCollection;
	*buffer."error" = "0";
# start walking at the root of the tree...
	uuTreeWalkCollection(
			*direction,
			*topLevelCollection,
			*buffer, 
			*ruleToProcess
	);
	*error = *buffer."error";
}

# \brief walk a subtree 
# \param [in] direction   can be "forward" or "reverse"
# \param [in] path
# \param [in/out] buffer  (exclusively to be used by the rule we will can)
# \param [in] rule        name of the rule to be executed in the context of a tree-item 
uuTreeWalkCollection(
			*direction,
			*path,
			*buffer, 
			*ruleToProcess
	) {
	uuChopPath(*path, *parentCollection, *collection);
	if (*direction == "forward") {
		# first process this collection itself
		if (*buffer."error" == "0") {
			# ugly: need to use many if's, irods offers no means to break to end of action
			eval("{ *ruleToProcess(\*parentCollection,\*collection,true,\*buffer); }");
		}
		# and the dataobjects located directly within the collection
		if (*buffer."error" == "0" ) {
			foreach (*row in SELECT DATA_NAME WHERE COLL_NAME = *path) {
				msiGetValByKey(*row, "DATA_NAME", *dataObject);
				eval("{ *ruleToProcess(\*path,\*dataObject,false,\*buffer); }");
				if (*buffer."error" != "0" ) {
					break;
				}
			}
		}
		if (*buffer."error" == "0" ) {
			# then increase depth to walk through the subcollections
			foreach (*row in SELECT COLL_NAME WHERE COLL_PARENT_NAME = *path) {
			msiGetValByKey(*row, "COLL_NAME", *subCollectionPath);
			uuTreeWalkCollection(
						*direction,
						*subCollectionPath,
						*buffer, 
						*ruleToProcess
				);
			}
		}
	}
	if (*direction == "reverse") {
		# first deal with any subcollections within this collection
		if (*buffer."error" == "0") {
			foreach (*row in SELECT COLL_NAME WHERE COLL_PARENT_NAME = *path) {
				msiGetValByKey(*row, "COLL_NAME", *subCollectionPath);
				uuTreeWalkCollection(
						*direction, 
						*subCollectionPath, 
						*buffer,
						*ruleToProcess
				);
			}
		}
		# when done then process the dataobjects directly located within this collection
		if (*buffer."error" == "0") {
			foreach (*row in SELECT DATA_NAME WHERE COLL_NAME = *path) {
				msiGetValByKey(*row, "DATA_NAME", *dataObject);
				eval("{ *ruleToProcess(\*path,\*dataObject,false,\*buffer); }");
				if (*buffer."error" != "0" ) {
					break;
				}
			}
		}
		# and lastly process the collection itself
		if (*buffer."error" == "0") {
			eval("{ *ruleToProcess(\*parentCollection,\*collection,true,\*buffer); }");
		}
	}
}


#
#input *direction="forward",*topLevelCollection="/tsm/home/rods",*ruleToProcess="uuTreeWalkTestrule"
#output ruleExecOut
