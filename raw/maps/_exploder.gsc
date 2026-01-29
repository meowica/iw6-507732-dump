#include common_scripts\utility;
#include maps\_utility;

/*
 * this is script has been around since the original CoD it's heavy on ent use and should be be used sparingly.
  * 
  * */

setup_individual_exploder( ent )
{
	exploder_num = ent.script_exploder;
	if ( !IsDefined( level.exploders[ exploder_num ] ) )
	{
		level.exploders[ exploder_num ] = [];
	}

	targetname = ent.targetname;
	if ( !IsDefined( targetname ) )
		targetname = "";

	level.exploders[ exploder_num ][ level.exploders[ exploder_num ].size ] = ent;
	if ( exploder_model_starts_hidden( ent ) )
	{
		ent Hide();
		return;
	}

	if ( exploder_model_is_damaged_model( ent ) )
	{
		ent Hide();
		ent NotSolid();
		if ( IsDefined( ent.spawnflags ) && ( ent.spawnflags & 1 ) )
		{
			if ( IsDefined( ent.script_disconnectpaths ) )
			{
				ent ConnectPaths();
			}
		}
		return;
	}

	if ( exploder_model_is_chunk( ent ) )
	{
		ent Hide();
		ent NotSolid();
		if ( IsDefined( ent.spawnflags ) && ( ent.spawnflags & 1 ) )
			ent ConnectPaths();
		return;
	}
}

setupExploders()
{
	level.exploders = [];

	// Hide exploder models.
	ents = GetEntArray( "script_brushmodel", "classname" );
	smodels = GetEntArray( "script_model", "classname" );
	for ( i = 0; i < smodels.size; i++ )
		ents[ ents.size ] = smodels[ i ];

	foreach ( ent in ents )
	{
		if ( IsDefined( ent.script_prefab_exploder ) )
			ent.script_exploder = ent.script_prefab_exploder;
			
        if ( IsDefined( ent.masked_exploder ) )
            continue;
            
		if ( IsDefined( ent.script_exploder ) )
		{
			setup_individual_exploder( ent );
		}
	}

	script_exploders = [];

	potentialExploders = GetEntArray( "script_brushmodel", "classname" );
	for ( i = 0; i < potentialExploders.size; i++ )
	{
		if ( IsDefined( potentialExploders[ i ].script_prefab_exploder ) )
			potentialExploders[ i ].script_exploder = potentialExploders[ i ].script_prefab_exploder;

		if ( IsDefined( potentialExploders[ i ].script_exploder ) )
			script_exploders[ script_exploders.size ] = potentialExploders[ i ];
	}

	potentialExploders = GetEntArray( "script_model", "classname" );
	for ( i = 0; i < potentialExploders.size; i++ )
	{
		if ( IsDefined( potentialExploders[ i ].script_prefab_exploder ) )
			potentialExploders[ i ].script_exploder = potentialExploders[ i ].script_prefab_exploder;

		if ( IsDefined( potentialExploders[ i ].script_exploder ) )
			script_exploders[ script_exploders.size ] = potentialExploders[ i ];
	}

	potentialExploders = GetEntArray( "item_health", "classname" );
	for ( i = 0; i < potentialExploders.size; i++ )
	{
		if ( IsDefined( potentialExploders[ i ].script_prefab_exploder ) )
			potentialExploders[ i ].script_exploder = potentialExploders[ i ].script_prefab_exploder;

		if ( IsDefined( potentialExploders[ i ].script_exploder ) )
			script_exploders[ script_exploders.size ] = potentialExploders[ i ];
	}
	
	
	potentialExploders = level.struct;
	for ( i = 0; i < potentialExploders.size; i++ )
	{
		if ( !IsDefined( potentialExploders[ i ] ) )
			continue; // these must be getting deleted somewhere else?
		if ( IsDefined( potentialExploders[ i ].script_prefab_exploder ) )
			potentialExploders[ i ].script_exploder = potentialExploders[ i ].script_prefab_exploder;

		if ( IsDefined( potentialExploders[ i ].script_exploder ) )
		{
			if ( !IsDefined( potentialExploders[ i ].angles ) )
				potentialExploders[ i ].angles = ( 0, 0, 0 );
			script_exploders[ script_exploders.size ] = potentialExploders[ i ];

		}
	}	
	

	if ( !IsDefined( level.createFXent ) )
		level.createFXent = [];

	acceptableTargetnames							 = [];
	acceptableTargetnames[ "exploderchunk visible" ] = true;
	acceptableTargetnames[ "exploderchunk"		   ] = true;
	acceptableTargetnames[ "exploder"			   ] = true;

	thread setup_flag_exploders();

	for ( i = 0; i < script_exploders.size; i++ )
	{
		exploder = script_exploders[ i ];
		
		
		ent						 = createExploder( exploder.script_fxid );
		ent.v					 = [];
		ent.v[ "origin"		   ] = exploder.origin;
		ent.v[ "angles"		   ] = exploder.angles;
		ent.v[ "delay"		   ] = exploder.script_delay;
		ent.v[ "delay_post"	   ] = exploder.script_delay_post;
		ent.v[ "firefx"		   ] = exploder.script_firefx;
		ent.v[ "firefxdelay"   ] = exploder.script_firefxdelay;
		ent.v[ "firefxsound"   ] = exploder.script_firefxsound;
		ent.v[ "earthquake"	   ] = exploder.script_earthquake;
		ent.v[ "rumble"		   ] = exploder.script_rumble;
		ent.v[ "damage"		   ] = exploder.script_damage;
		ent.v[ "damage_radius" ] = exploder.script_radius;
		ent.v[ "soundalias"	   ] = exploder.script_soundalias;
		ent.v[ "repeat"		   ] = exploder.script_repeat;
		ent.v[ "delay_min"	   ] = exploder.script_delay_min;
		ent.v[ "delay_max"	   ] = exploder.script_delay_max;
		ent.v[ "target"		   ] = exploder.target;
		ent.v[ "ender"		   ] = exploder.script_ender;
		ent.v[ "physics"	   ] = exploder.script_physics;
		ent.v[ "type"		   ]  = "exploder";
// 		ent.v[ "worldfx" ] = true;
		if ( !IsDefined( exploder.script_fxid ) )
			ent.v[ "fxid" ] = "No FX";
		else
			ent.v[ "fxid"	  ]	 = exploder.script_fxid;
		ent.v	 [ "exploder" ]	 = exploder.script_exploder;
		AssertEx( IsDefined( exploder.script_exploder ), "Exploder at origin " + exploder.origin + " has no script_exploder" );
		if ( IsDefined( level.createFXexploders ) )
		{	// if we're using the optimized lookup, add it in the proper place
			ary = level.createFXexploders[ ent.v[ "exploder" ] ];
			if ( !IsDefined( ary ) )
				ary = [];
			ary[ ary.size ]								   = ent;
			level.createFXexploders[ ent.v[ "exploder" ] ] = ary;
		}

		if ( !IsDefined( ent.v[ "delay" ] ) )
			ent.v[ "delay" ] = 0;

		if ( IsDefined( exploder.target ) )
		{
			get_ent = GetEntArray( ent.v[ "target" ], "targetname" )[ 0 ];
			if ( IsDefined( get_ent ) )
			{
				org				  = get_ent.origin;
				ent.v[ "angles" ] = VectorToAngles( org - ent.v[ "origin" ] );
			}
			else
			{
				get_ent = get_target_ent( ent.v[ "target" ] );
				if ( IsDefined( get_ent ) )
				{
					org				  = get_ent.origin;
					ent.v[ "angles" ] = VectorToAngles( org - ent.v[ "origin" ] );
				}
			}
  //		  forward = AnglesToForward( angles );
  //		  up	  = AnglesToUp( angles );
		}
		
		// this basically determines if its a brush / model exploder or not
		if ( !IsDefined( exploder.code_classname ) )
		{
			//I assume everything that doesn't have a code_classname is a struct that needs a script_modelname to make its way into the game
			ent.model = exploder;
			if ( IsDefined( ent.model.script_modelname ) )
			{
				PreCacheModel( ent.model.script_modelname );
			}
		}
		else if ( exploder.code_classname == "script_brushmodel" || IsDefined( exploder.model ) )
		{
			ent.model				   = exploder;
			ent.model.disconnect_paths = exploder.script_disconnectpaths;
		}

		if ( IsDefined( exploder.targetname ) && IsDefined( acceptableTargetnames[ exploder.targetname ] ) )
			ent.v[ "exploder_type" ] = exploder.targetname;
		else
			ent.v[ "exploder_type" ] = "normal";
        
        if ( IsDefined( exploder.masked_exploder ) )
        {
			ent.v[ "masked_exploder"						] = exploder.model;
			ent.v[ "masked_exploder_spawnflags"				] = exploder.spawnflags;
			ent.v[ "masked_exploder_script_disconnectpaths" ] = exploder.script_disconnectpaths;
            exploder Delete();
        }
		ent common_scripts\_createfx::post_entity_creation_function();
	}
}

setup_flag_exploders()
{
	// createfx has to do 2 waittillframeends so we have to do 3 to make sure this comes after
	// createfx is all done setting up. Who will raise the gambit to 4? 
	waittillframeend;
	waittillframeend;
	waittillframeend;
	exploder_flags = [];

	foreach ( ent in level.createFXent )
	{
		if ( ent.v[ "type" ] != "exploder" )
			continue;
		theFlag = ent.v[ "flag" ];

		if ( !IsDefined( theFlag ) )
		{
			continue;
		}

		if ( theFlag == "nil" )
		{
			ent.v[ "flag" ] = undefined;
		}

		exploder_flags[ theFlag ] = true;
	}

	foreach ( msg, _ in exploder_flags )
	{
		thread exploder_flag_wait( msg );
	}
}

exploder_flag_wait( msg )
{
	if ( !flag_exist( msg ) )
		flag_init( msg );
	flag_wait( msg );

	foreach ( ent in level.createFXent )
	{
		if ( ent.v[ "type" ] != "exploder" )
			continue;
		theFlag = ent.v[ "flag" ];

		if ( !IsDefined( theFlag ) )
		{
			continue;
		}

		if ( theFlag != msg )
			continue;
		ent activate_individual_exploder();
	}
}

exploder_model_is_damaged_model( ent )
{
	return( IsDefined( ent.targetname ) ) && ( ent.targetname == "exploder" );
}

exploder_model_starts_hidden( ent )
{
	return( ent.model == "fx" ) && ( ( !IsDefined( ent.targetname ) ) || ( ent.targetname != "exploderchunk" ) );
}

exploder_model_is_chunk( ent )
{
	return( IsDefined( ent.targetname ) ) && ( ent.targetname == "exploderchunk" );
}

show_exploder_models_proc( num )
{
	num += "";

	//prof_begin( "hide_exploder" );
	if ( IsDefined( level.createFXexploders ) )
	{	// do optimized flavor if available
		exploders = level.createFXexploders[ num ];
		if ( IsDefined( exploders ) )
		{
			foreach ( ent in exploders )
			{
				//pre exploded geo.  don't worry about deleted exploder geo..
				if ( ! exploder_model_starts_hidden( ent.model )
				     && ! exploder_model_is_damaged_model( ent.model )
				     && !exploder_model_is_chunk( ent.model ) )
				{
						ent.model Show();
				}
	
				//exploded geo and should be shown
				if ( IsDefined( ent.brush_shown ) )
					ent.model Show();
			}
		}
	}
	else
	{
		for ( i = 0; i < level.createFXent.size; i++ )
		{
			ent = level.createFXent[ i ];
			if ( !IsDefined( ent ) )
				continue;
	
			if ( ent.v[ "type" ] != "exploder" )
				continue;
	
			// make the exploder actually removed the array instead?
			if ( !IsDefined( ent.v[ "exploder" ] ) )
				continue;
	
			if ( ent.v[ "exploder" ] + "" != num )
				continue;
	
			if ( IsDefined( ent.model ) )
			{
	
				//pre exploded geo.  don't worry about deleted exploder geo..
				if ( ! exploder_model_starts_hidden( ent.model ) && ! exploder_model_is_damaged_model( ent.model ) && !exploder_model_is_chunk( ent.model ) )
				{
						ent.model Show();
				}
	
				//exploded geo and should be shown
				if ( IsDefined( ent.brush_shown ) )
					ent.model Show();
	
			}
		}
	}
	//prof_end( "hide_exploder" );
}

stop_exploder_proc( num )
{
	num += "";

	if ( IsDefined( level.createFXexploders ) )
	{	// do optimized flavor if available
		exploders = level.createFXexploders[ num ];
		if ( IsDefined( exploders ) )
		{
			foreach ( ent in exploders )
			{
				if ( !IsDefined( ent.looper ) )
					continue;
		
				ent.looper Delete();
			}
		}
	}
	else
	{
		for ( i = 0; i < level.createFXent.size; i++ )
		{
			ent = level.createFXent[ i ];
			if ( !IsDefined( ent ) )
				continue;
	
			if ( ent.v[ "type" ] != "exploder" )
				continue;
	
			// make the exploder actually removed the array instead?
			if ( !IsDefined( ent.v[ "exploder" ] ) )
				continue;
	
			if ( ent.v[ "exploder" ] + "" != num )
				continue;
	
			if ( !IsDefined( ent.looper ) )
				continue;
	
			ent.looper Delete();
		}
	}
}

get_exploder_array_proc( msg )
{
	msg += "";
	array = [];
	if ( IsDefined( level.createFXexploders ) )
	{	// do optimized flavor if available
		exploders = level.createFXexploders[ msg ];
		if ( IsDefined( exploders ) )
		{
			array = exploders;
		}
	}
	else
	{
		foreach ( ent in level.createFXent )
		{
			if ( ent.v[ "type" ] != "exploder" )
				continue;
	
			// make the exploder actually removed the array instead?
			if ( !IsDefined( ent.v[ "exploder" ] ) )
				continue;
	
			if ( ent.v[ "exploder" ] + "" != msg )
				continue;
	
			array[ array.size ] = ent;
		}
	}
	return array;
}

hide_exploder_models_proc( num )
{
	num += "";

	//prof_begin( "hide_exploder" );

	if ( IsDefined( level.createFXexploders ) )
	{	// do optimized flavor if available
		exploders = level.createFXexploders[ num ];
		if ( IsDefined( exploders ) )
		{
			foreach ( ent in exploders )
			{
				if ( IsDefined( ent.model ) )
					ent.model Hide();
			}
		}
	}
	else
	{
		for ( i = 0; i < level.createFXent.size; i++ )
		{
			ent = level.createFXent[ i ];
			if ( !IsDefined( ent ) )
				continue;
	
			if ( ent.v[ "type" ] != "exploder" )
				continue;
	
			// make the exploder actually removed the array instead?
			if ( !IsDefined( ent.v[ "exploder" ] ) )
				continue;
	
			if ( ent.v[ "exploder" ] + "" != num )
				continue;
	
	
			if ( IsDefined( ent.model ) )
					ent.model Hide();
	
		}
	}
	//prof_end( "hide_exploder" );
}

delete_exploder_proc( num )
{
	num += "";

	//prof_begin( "delete_exploder" );
	if ( IsDefined( level.createFXexploders ) )
	{	// do optimized flavor if available
		exploders = level.createFXexploders[ num ];
		if ( IsDefined( exploders ) )
		{
			foreach ( ent in exploders )
			{
				if ( IsDefined( ent.model ) )
					ent.model Delete();
			}
		}
	}
	else
	{
		for ( i = 0; i < level.createFXent.size; i++ )
		{
			ent = level.createFXent[ i ];
			if ( !IsDefined( ent ) )
				continue;
	
			if ( ent.v[ "type" ] != "exploder" )
				continue;
	
			// make the exploder actually removed the array instead?
			if ( !IsDefined( ent.v[ "exploder" ] ) )
				continue;
	
			if ( ent.v[ "exploder" ] + "" != num )
				continue;
	
			if ( IsDefined( ent.model ) )
				ent.model Delete();
		}
	}
	//ends trigger threads.
	level notify( "killexplodertridgers" + num );

	//prof_end( "delete_exploder" );
}