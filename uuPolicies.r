# \file
# \brief iRODS policies for Yoda (changes to core.re)
# \author Ton Smeele
# \copyright Copyright (c) 2015, Utrecht university. All rights reserved
# \license GPLv3, see LICENSE
#
#test {
#	acPreProcForExecCmd("foo");
#}

# \brief preProcForExecCmd
# 			limit the use of OS callouts to a user group "priv-execcmd-all"
#
# \param[in]		cmd  name of executable
#
acPreProcForExecCmd(*cmd, *args, *addr, *hint) {
	*accessAllowed = false;
	foreach (*rows in SELECT USER_GROUP_NAME WHERE USER_NAME='$userNameClient'
		             AND USER_ZONE='$rodsZoneClient') {
		msiGetValByKey(*rows, "USER_GROUP_NAME", *group);
		if (*group == "priv-execcmd-all") {
			*accessAllowed = true;
		}
	}
	if (*accessAllowed == false) {
		cut;
		msiOprDisallowed;
	}
}

# acCreateUserZoneCollections extended to also set inherit on the home coll
# this is needed for groupcollections to allow users to share objects
acCreateUserZoneCollections {
	uuGetUserType($otherUserName, *type);
	if (*type == "rodsuser") {
		# Do not create home directories for regular users.
		# but do create trash directories as iRODS always uses the personal trash folder evan when in a group directory
		acCreateCollByAdmin("/"++$rodsZoneProxy++"/trash/home", $otherUserName);
	} else if (*type == "rodsgroup" && ($otherUserName like "read-*")) {
		# Do not create home directories for read- groups.
	} else {
		# *Do* create home directories for all other user types and groups (e.g.
		# rodsadmin, research-, datamanager- and intake groups).
		acCreateCollByAdmin("/"++$rodsZoneProxy++"/home", $otherUserName);
		acCreateCollByAdmin("/"++$rodsZoneProxy++"/trash/home", $otherUserName);
		msiSetACL("default", "admin:inherit", $otherUserName, "/"++$rodsZoneProxy++"/home/"++$otherUserName);
		if ($otherUserName like regex "research-.*" && uuCollectionExists("/" ++ $rodsZoneProxy ++ UUREVISIONCOLLECTION)) {
			*revisionColl = "/"++$rodsZoneProxy++UUREVISIONCOLLECTION;
			acCreateCollByAdmin(*revisionColl, $otherUserName);
			msiSetACL("default", "admin:inherit", $otherUserName, "*revisionColl/$otherUserName");
		}
	}
}


# acPreProcForObjRename is fired before a data object is renamed or moved.
# Disallows renaming or moving the data object if it is directly under home.
acPreProcForObjRename(*src, *dst) {
        ON($objPath like regex "/[^/]+/home/" ++ ".[^/]*") {
                uuGetUserType(uuClientFullName, *userType);
                if (*userType != "rodsadmin") {
                        cut;
                        msiOprDisallowed;
                }
        }
}

#input null
#output ruleExecOut
