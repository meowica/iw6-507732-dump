/*
New Destructible Types Setup

Here's a new system for Adding Destructibles.  I robotically converted them all over to the new style for you!

Instead of putting your "destructible_type" in the giant switch statement, you simply create a GSC file with the same name as the destructible_type key in your .map file. 

Repackager takes care of adding the scripts and zone source reference.

Put your script in 
destructible_scripts\<destructible_type>.gsc

give add a function called main() in there with the old destructible_types.gsc destructible lines.

see examples in: share\raw\destructible_scripts

NOTES:
-we don't have to use that weird get_precached_anim() function. just throw the animations in the script the way you really want to.
-some of the names were too long for a script function call, I simply only-ents compiled those maps with updated references to the new names.
-SCRIPTDEVELOP is awesome! it's very nice it was to lean on the integrated script compiler to help mash out the errors as moved a TON of stuff around.
-I fixed up some Script Errors but not all that weren't related to this change in testing.
-I only rebuilt packages for sp_list maps and a handful of more recent test maps. If you run into weird destructible errors just Repackage zone/script

SCRIPT FILE PATHS HAVE A LIMIT, if you have a really long Destructible_type name and are running into issues. Try reducing the length of the destructible type name.

*/	

#include common_scripts\_destructible;
#using_animtree( "destructibles" );

makeType( destructibleType )
{
	// if it's already been created dont create it again
	infoIndex = getInfoIndex( destructibleType );
	if ( infoIndex >= 0 )
		return infoIndex;

	// This is the new stuff, Each Script describes this function.
	if( IsDefined( level.destructible_functions[ destructibleType ] ) )
	{
		[[ level.destructible_functions[ destructibleType ] ]]();
		infoIndex = getInfoIndex( destructibleType );
		assert( infoIndex >= 0 );
		return infoIndex;
	}
	
	switch( destructibleType )
	{		
		//here's some ghost script
		/*
		case "pb_cubical_planter":
			pb_cubical_planter();
			break;
		*/

		default: // Default means invalid type
			AssertMsg( "Destructible object 'destructible_type' key/value of '" + destructibleType + "' is not valid. Have you Repackaged Zone/Script? Sometimes you need to rebuild BSP ents." );
			break;
	}
	

	infoIndex = getInfoIndex( destructibleType );
	assert( infoIndex >= 0 );
	return infoIndex;
}

getInfoIndex( destructibleType )
{
	if ( !isdefined( level.destructible_type ) )
		return - 1;
	if ( level.destructible_type.size == 0 )
		return - 1;

	for ( i = 0 ; i < level.destructible_type.size ; i++ )
	{
		if ( destructibleType == level.destructible_type[ i ].v[ "type" ] )
			return i;
	}

	// didn't find it in the array, must not exist
	return - 1;
}



/*
pb_cubical_planter()
{
	dest	= "pb_cubical_planter_dam";
	fx		= "fx/explosions/brick_chunk";

	destructible_create("pb_cubical_planter","tag_origin",1150,undefined,32);
		destructible_state( "tag_origin", dest, undefined, undefined, "no_meele" );
			destructible_fx( "tag_fx", fx);
			destructible_fx( "tag_fx", fx);
			//destructible_explode( 4000, 5000, 150, 250, 50, 300, undefined, undefined, 0.3, 500 );
}
*/