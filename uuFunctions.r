# \brief orderclause	helper functions to determine order clause
# \param[in] column	Column to check
# \param[in] orderby	The column to orderby
# \param[in] ascdesc	"asc" for ascending order, "desc" for descending order. Defaults to Ascending
# \returnvalue		Returns either "" for no ordering, "ORDER_DESC" or "ORDER" when column needs ordering
uuorderclause(*column, *orderby, *ascdesc) = if *column == *orderby then uuorderdirection(*ascdesc) else ""
uuorderdirection(*ascdesc) = if *ascdesc == "desc" then "ORDER_DESC" else "ORDER"

uuiscollection(*collectionOrDataObject) = if *collectionOrDataObject == "Collection" then true else false

# \datatype	uucondition
# \description  a triple of strings to represent the elements of a condition query
# \constructor uucondition	Construct new conditions with condition(*column, *operator, *expression)	
data uucondition =
	| uucondition : string * string * string -> uucondition

# \function uumakelikecondition	Helper function to create the most used condition. A searchstring
#				surrounded by wildcards
# \param[in] column		The irods column to search
# \param[in] searchstring	Part of the string to search on.
# \returnvalue	uucondition	A triple of strings of type uucondition
uumakelikecondition(*column, *searchstring) = uucondition(*column, "like", "%%*searchstring%%")

# \function uumakelikecollcondition Helper function to search within the clientZone
# \param[in] column		The irods column to search
# \param[in] searchstring	Part of the string to search on.
uumakelikecollcondition(*column, *searchstring) = uucondition(*column, "like", "/$rodsZoneClient/home/%%*searchstring%%")

# \function uumakestartswithcondition	Helper function to create a condition for strings starting
#					with the searchstring
# \param[in] column		The irods column to search
# \param[in] searchstring	Part of the string to search on.
# \returnvalue uucondition	A triple of strings of type uucondition
uumakestartswithcondition(*column, *searchstring) = uucondition(*column, "like", "*searchstring%%")

# \function uuiso8601  Return irods style timestamp in iso8601 format
# \param[in] *timestamp		irods style timestamp (epoch as string) 
# \returnvalue uuiso8601	string with timestamp in iso8601 format
uuiso8601(*timestamp) = timestrf(datetime(int(*timestamp)), "%Y%m%dT%H%M%S%z")

# \function uuisod8601date Return irods style timestamp as a iso8601 date
uuiso8601date(*timestamp) = timestrf(datetime(int(*timestamp)), "%Y-%m-%d")
