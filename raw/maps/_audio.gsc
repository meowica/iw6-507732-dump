#include maps\_utility_code;
#include maps\_utility;
//#include maps\_audio_reverb;
#include common_scripts\utility;
#include maps\_audio_code;
#include maps\_audio_ambient;
//#include maps\_audio_music;
//#include maps\_audio_mix_manager;
//#include maps\_audio_vehicles;

//---------------------------------------------------------
//	Audio Initialization.
//---------------------------------------------------------
init_audio()
{
	if ( IsDefined( level._audio ) )
	{
		return;
	}
	
	// Dvars
	SetDvarIfUninitialized( "debug_audio", "0" );
	SetDvarIfUninitialized( "debug_headroom", "-1" );
	SetDvarIfUninitialized( "music_enable", "0" );

	// AUDIO VARS -----------------------------------------
	level._audio = SpawnStruct();

	level._audio.using_string_tables = false;	
	
	// Create Audio Callback Trigger - Callback Array
	level._audio.progress_trigger_callbacks = [];
	
	// Maps used for custom zone blending
	level._audio.progress_maps = [];
			
/#
	// dvar-triggered debug modes/huds	
	level._audio.debug_hud = false;
	level._audio.using_submix_hud = false;
#/

	// SYSTEMS --------------------------------------------
	init_tracks();
	init_filter();
	init_occlusion();
	init_ambient();
	init_mix();
	init_reverb();
	init_timescale();
	init_whizby();
	init_zones();
	
	// set up level fade in
	thread level_fadein();
	
/#
	thread debug_audio_hud();
#/
}

//---------------------------------------------------------
// Special OPs Init
//---------------------------------------------------------
//TODO CHANGE FUNCTION NAME!
aud_set_spec_ops()
{
/#
	// Why is this /# #/ !?!?!?
	if (!IsDefined(level.players))
	{
		level waittill("level.players initialized");
	}
	
	// initialize a "zones" array to hold data on the current zones players are in
	level._audio.specops_zones = [];
	
	for(i = 0; i < level.players.size; i++)
	{
		level._audio.specops_zones[i] = spawnstruct();
		level._audio.specops_zones[i].player = level.players[i]; // the player entity for this zone
		level._audio.specops_zones[i].zonename = ""; // the name of the zone this player is in
	}
#/
}

//---------------------------------------------------------
// PROGRESS MAPPING FUNCTIONS
//---------------------------------------------------------

// add a named mapping array for custom progress/zone blending.
aud_add_progress_map( name, map_array )
{
	assert( IsDefined( level._audio.progress_maps ) );
	level._audio.progress_maps[ name ] = map_array;
}

//---------------------------------------------------------
// DEATHSDOOR FUNCTIONS
//---------------------------------------------------------
is_deathsdoor_audio_enabled()
{
	if ( !IsDefined( level._audio.deathsdoor_enabled ) )
	{
		return true;
	}
	else
	{
		return level._audio.deathsdoor_enabled;
	}
}

aud_enable_deathsdoor_audio()
{
	level.player.disable_breathing_sound = false;
	level._audio.deathsdoor_enabled = true;
}

aud_disable_deathsdoor_audio()
{
	level.player.disable_breathing_sound = true;
	level._audio.deathsdoor_enabled = false;
}

// used to restore the state of occlusion, filter, and reverb after recovering from deathsdoor
restore_after_deathsdoor()
{
	if ( is_deathsdoor_audio_enabled() || IsDefined( level._audio.in_deathsdoor ) )
	{
		level._audio.in_deathsdoor = undefined;
		assert( IsDefined( level._audio.deathsdoor ) );

//		if ( IsDefined( level._audio.deathsdoor.occlusion ) && level._audio.deathsdoor.occlusion != "" )
//			thread set_occlusion( level._audio.deathsdoor.occlusion );

		if ( IsDefined( level._audio.deathsdoor.filter ) )
		{
			foreach ( i, filter in level._audio.deathsdoor.filter )
			{
				if ( filter == "" )
				{
					clear_filter( i );
				}
				else
				{
					thread set_filter( filter, i );
				}
			}
			
			set_hud_value( "filter", "" );
		}
		
		if ( IsDefined( level._audio.deathsdoor.reverb ) && level._audio.deathsdoor.reverb != "" )
			set_reverb( level._audio.deathsdoor.reverb );
		else
			clear_reverb();
	}
}

// used to send the game audio state to "deathsdoor". 
set_deathsdoor()
{
	level._audio.in_deathsdoor = true;
		
	if ( !IsDefined( level._audio.deathsdoor ) )
	{
		level._audio.deathsdoor = spawnstruct();
	}
	
	level._audio.deathsdoor.filter = undefined;
	level._audio.deathsdoor.reverb = undefined;
	
	level._audio.deathsdoor.filter = level._audio.filter.current;
	level._audio.deathsdoor.reverb = level._audio.reverb.current;

	if (is_deathsdoor_audio_enabled())
	{	
		set_filter( "deathsdoor", 0 );
		set_filter( "deathsdoor", 1 );
		set_hud_value( "filter", "^3DEATHSDOOR" );
		set_reverb( "deathsdoor" );
	}
}

//-----------------------------------------------------------------------------------------------------
//	TRIGGER HANDLER:  AUDIO TRIGGER (trigger_multiple_audio)
//-----------------------------------------------------------------------------------------------------
/*QUAKED trigger_multiple_audio (1.0 0.23 1.0) ? AI_AXIS AI_ALLIES AI_NEUTRAL NOTPLAYER VEHICLE TRIGGER_SPAWN TOUCH_ONCE
defaulttexture="ambient"
Crossfades between two "Audio Zones" defined via the Audio Zone Manager.
Audio zones may contain the following (defined in _audio_presets_zones.gsc):  Streamed Ambience, Dynamic Ambience, Mix Snaphot, Music Specification, etc.
Calls messages and/or functions when entering, exiting or progressing through the trigger.

Key: script_audio_zones -- Value = Pair of location names to be blended.
Key: script_audio_blend_mode -- Value = Mode is either "blend" or "trigger", defaults to "blend".
Key: script_audio_progress_map -- Value = Name of mapping array specified in aud_add_progress_map(name, map_array) function.

Key: script_audio_enter_msg -- Value = Message to be called when entering the trigger.
Key: script_audio_exit_msg -- Value = Message to be called when exiting the trigger.
Key: script_audio_progress_msg -- Value = Message to be called while progressing through the trigger.

Key: script_audio_update_rate -- Value = Time in seconds (float) that the progress will wait per loop while player is inside trigger.
*/
trigger_multiple_audio_trigger( trigger )
{
	// Be sure to be added only once
	if ( IsDefined( trigger._audio_trigger ) )
	{
		return;
	}

	trigger._audio_trigger = true;
	tokens = undefined;
	
	if ( IsDefined( trigger.ambient ) )
	{
		tokens = strtok( trigger.ambient, " " );
	}
	else if ( IsDefined( trigger.script_audio_zones ) )
	{
		tokens = strtok( trigger.script_audio_zones, " " );
	}
	else if ( IsDefined( trigger.audio_zones ) )
	{
		tokens = strtok( trigger.audio_zones, " " );
	}
		
	if ( IsDefined( tokens ) && tokens.size == 2 )
	{
		assertEx( IsDefined( trigger.target ) , "Trigger Multiple Audio Trigger: audio zones given without setting up target entities ( script_origins ) ." ); 		
	}
	else if ( IsDefined( tokens ) && tokens.size == 1 ) // in this case, NO BLENDING will go on, so no special tokens, and we enter a special mode... this is deprecated, and supported for backward compatibility
	{
		for ( ;; )
		{
			trigger waittill( "trigger", other );
			assertEx( isplayer( other ) , "Non - player entity touched an ambient trigger." );

			set_zone( tokens[ 0 ], trigger.script_duration );
		}
	}
	
	if ( IsDefined( trigger.script_audio_progress_map ) )
	{
		assert( IsDefined( level._audio.progress_maps ) );
		
		if ( !IsDefined( level._audio.progress_maps[ trigger.script_audio_progress_map ] ) )
		{
			debug_error( "Trying to set a progress_map_function without defining the envelope in the level.aud.envs array." );
			trigger.script_audio_progress_map = undefined;
		}
	}

	if ( !IsDefined( trigger.script_audio_blend_mode ) )
	{
		trigger.script_audio_blend_mode = "blend";
	}
		
	point_a = undefined;
	point_b = undefined;
	dist = undefined;

	if ( IsDefined( trigger.target ) )
	{
		if ( !IsDefined( trigger get_target_ent() ) )
		{
			debug_error( "Audo Zone Trigger at " + trigger.origin + " has defined a target, " + trigger.target + ", but that target doesn't exist." );
			return;
		}
		
		// if there are 2 script origins.
		if ( IsDefined( trigger get_target_ent_target() ) ) 
		{
			point_a = trigger get_target_ent_origin();
			if ( !IsDefined( trigger get_target_ent_target_ent() ) )
			{
				debug_error( "Audo Zone Trigger at " + trigger.origin + " has defined a target, " + get_target_ent_target() + ", but that target doesn't exist." );
				return;
			}
			point_b  = trigger get_target_ent_target_ent_origin();
		}
		else
		{
			// NOTE: THIS CODE IS TAKEN FROM IW CODE TO SUPPORT ONE SCRIPT ORIGIN.
			// It is deprecated for SHG maps
			assert( IsDefined( trigger.target ) );
			target_ent = trigger get_target_ent();
			diff = 2 * ( trigger.origin - target_ent.origin );
			// otherwise double the difference between the target origin and start to get the endpoint
			angles = VectorToAngles( diff );
			point_a = trigger get_target_ent_origin();
			point_b = point_a + diff;
			// If the pitch is not steep enough
			// Make sure the Z is level so you do not get a "pitched" plane when checking for progress.
			// If you want the angled pitched plane less than 45, then use 2 structs/ents.
			if ( AngleClamp180( angles[ 0 ] ) < 45 )
			{
				point_a = ( point_a[ 0 ], point_a[ 1 ], 0 );
				point_b = ( point_b[ 0 ], point_b[ 1 ], 0 );
			}
		}
		
		dist = distance( point_a, point_b );
	}
	
	is_backward = false;
	
	while ( 1 )
	{
		// Wait Until Player Hits Trigger 
		trigger waittill( "trigger", other );
		assertEx( IsPlayer( other ) , "Non - player entity touched an ambient trigger." );
		
		// in specops, if we are not in split screen, and the person who triggers this is 
		// not the local client ( level.player ) , then don't do any zone transitions
		if ( is_specialop() && other != level.player )
		{
/#
			if ( IsSplitScreen() && IsDefined( tokens ) )
			{
				if ( IsDefined( tokens[ 1 ] ) )
				{
					level._audio.specops_zones[ 1 ].zonename = tokens[ 1 ];
				}
				else if ( IsDefined( tokens[ 0 ] ) )
				{
					level._audio.specops_zones[ 1 ].zonename = tokens[ 1 ];
				}
			}
#/
			continue;
		}
		
		// At this point, we know which side of the trigger we're hitting. 
		
		if ( IsDefined( point_a ) && IsDefined( point_b ) )
		{
			progress = trigger_multiple_audio_progress( point_a, point_b, dist, other.origin );
			if ( progress < 0.5 ) // We're going forward.
			{
				is_backward = false;
				// Going from zone a to zone b.
			}
			else // We're going backward.
			{
				is_backward = true;
				// Going from zone a to zone b.
			}
		}

		blend_args = undefined;
		zone_from = get_zone_from( tokens, is_backward );
		zone_to = get_zone_to( tokens, is_backward );
		if ( IsDefined( zone_from ) && IsDefined( zone_to ) )
		{
			blend_args = get_zone_blend_args( zone_from, zone_to );
			if ( !IsDefined( blend_args ) )
			{
				return;
			}

			// add the blend mode to the blend_args
			blend_args[ "mode" ] = trigger.script_audio_blend_mode;

			// Filters should never be reversed
			if ( is_backward )
			{
				filter1 = blend_args[ "filter1" ];
				filter2 = blend_args[ "filter2" ];
				blend_args[ "filter1" ] = filter2;
				blend_args[ "filter2" ] = filter1;
				filter1 = undefined;
				filter2 = undefined;
			}
		}

/#
		if ( is_specialop() && IsDefined( blend_args ) )
		{
			assert( other == level.player );
			aud_set_specops_zone( other, "blending" );
		}
#/
		
		// Loop while player is inside trigger. 
		last_progress = -1;
		progress = -1;
		while ( other istouching( trigger ) )
		{
			if ( IsDefined( trigger.script_audio_point_func ) )
			{
				progress_point = trigger_multiple_audio_progress_point( point_a, point_b, other.origin );
				if ( IsDefined( level._audio.trigger_functions[ trigger.script_audio_point_func ] ) )
				{
					[[ level._audio.trigger_functions[ trigger.script_audio_point_func ]] ]( progress_point );
				}
			}
			
			// don't do any blend functionality without defined points ( from the script_origins )
			if ( IsDefined( point_a ) && IsDefined( point_b ) )
			{
				// get the progress value
				progress = trigger_multiple_audio_progress( point_a, point_b, dist, other.origin );
				
				if ( IsDefined( trigger.script_audio_progress_map ) )
				{
					assert( IsDefined( level._audio.progress_maps[ trigger.script_audio_progress_map ] ) );
					progress = aud_map( progress, level._audio.progress_maps[ trigger.script_audio_progress_map ] );
				}
				
				// Blend the ambiences base on progress. 
				if ( progress != last_progress )
				{
					if ( IsDefined( blend_args ) )
					{
						// Perform blend.
						trigger_multiple_audio_blend( progress, blend_args, is_backward ); 
					}
					// Store progress.
					last_progress = progress;
				}
			}
			
			// Sleep a little while .
			if ( IsDefined( trigger.script_audio_update_rate ) )
			{
				wait( trigger.script_audio_update_rate );
			}
			else
			{
				wait( 0.05 );
			}
		}

		
		// don't do any blend functionality without defined points ( from the script_origins )
		if ( IsDefined( point_a ) && IsDefined( point_b ) )
		{
			assert( IsDefined( progress ) );
			// Clean Up:  Just exited trigger, so only one abmbinece should play; no more blending. 
			if ( progress > 0.5 )
			{
/#
				if ( IsDefined( get_zone_from( tokens, is_backward ) ) && IsDefined( get_zone_to( tokens, is_backward ) ) )
				{
					set_hud_value( "zone", tokens[ 1 ] );
				}
#/
				
				if ( IsDefined( tokens ) && IsDefined( tokens[ 1 ] ) )
				{
					set_current_audio_zone( tokens[ 1 ] );
				}
				
				progress = 1;
			}
			else
			{
/#
				if ( IsDefined( get_zone_from( tokens, is_backward ) ) && IsDefined( get_zone_to( tokens, is_backward ) ) )
				{
					set_hud_value( "zone", tokens[ 0 ] );
				}
#/
				
				if ( IsDefined( tokens ) && IsDefined( tokens[ 0 ] ) )
				{
					set_current_audio_zone( tokens[ 0 ] );
				}

				progress = 0;
			}
			
			if ( IsDefined( blend_args ) )
			{
				// FINAL BLEND:  One full off, the other full on.
				trigger_multiple_audio_blend( progress, blend_args, is_backward );
				
/#
				filter_progress = progress;
				if ( is_backward ) // flip progress if going backward
					filter_progress = 1.0 - progress;

				if ( filter_progress < 0.5 && IsDefined( blend_args[ "filter1" ] ) )
					set_hud_name_percent_value( "filter_0", blend_args[ "filter1" ], "last" );
				else if ( filter_progress > 0.5 && IsDefined( blend_args[ "filter2" ] ) )
					set_hud_name_percent_value( "filter_1", blend_args[ "filter2" ], "last" );
#/
				
			}
		}
		
		// PRINT:  We are done here, display which side we came out of.
		// At this pont progress is either 1 or 0.
// TODO: WTF, why is this section /# #/ ? !? !
/#
		if ( IsDefined( point_a ) && IsDefined( point_b ) )
		{
			assert( progress == 1 || progress == 0 );
			if ( IsDefined( tokens ) && IsDefined( tokens[ 0 ] ) && IsDefined( tokens[ 1 ] ) )
			{
				if ( progress == 0 )
				{
					if ( is_specialop() )
					{
						aud_set_specops_zone( other, tokens[ 0 ] );
					}
				}
				else
				{
					if ( is_specialop() )
					{
						aud_set_specops_zone( other, tokens[ 1 ] );
					}
				}
			}
		}
#/
	}
}

/#
aud_set_specops_zone(other, zone)
{
	assert(is_specialop());
	assert(level.player == other);
	level._audio.specops_zones[0].zonename = zone;
}
#/

trigger_multiple_audio_progress( start, end, dist, org  )
{
	normal = vectorNormalize( end - start );
	vec = org - start;
	progress = vectorDot( vec, normal );
	progress = progress / dist;			
	return clamp(progress, 0, 1.0);
}

trigger_multiple_audio_progress_point( start, end, org )
{
	normal = vectorNormalize( end - start );
	vec = org - start;
	progress_length = vectorDot( vec, normal ); // projection of vec on normal
	
	return normal * progress_length + start; // offset from the start
}


trigger_multiple_audio_blend(progress, blend_args, is_backward)
{
	assert(IsDefined(progress));
	assert(IsDefined(blend_args));
	
	progress = clamp(progress, 0, 1.0);
	
	// flip the context of what "progress" means if we are going backward... 
	if (is_backward)
	{
		progress = 1 - progress;
	}
	
	assert(IsDefined(blend_args[ "mode" ]));
	mode = blend_args[ "mode" ];
	assert(mode == "blend" || mode == "trigger");
	if ( mode == "blend" )
	{
		level_a = 1 - progress;
		level_b = progress;
		blend_zones( level_a, level_b, blend_args, is_backward );
	}
	else
	{
		if ( progress < 0.33 )
		{
			set_zone( blend_args[ "zone_from" ] );
		}
		else if ( progress > 0.66 )
		{
			set_zone( blend_args[ "zone_to" ] );
		}
	}
}

//-----------------------------------------------------------------------------------------------------
//	Misc Utils
//-----------------------------------------------------------------------------------------------------
get_target_ent_target()
{
	target_ent = get_target_ent();
	return target_ent.target;
}

get_target_ent_origin()
{
	target_ent = get_target_ent();
	return target_ent.origin;
}

get_target_ent_target_ent()
{
	target_ent = get_target_ent();
	return target_ent get_target_ent();
}

get_target_ent_target_ent_origin()
{
	target_ent_target_ent = get_target_ent_target_ent();
	return target_ent_target_ent.origin;
}

get_zone_from(tokens, is_backwards)
{
	if (!IsDefined(tokens) || !IsDefined(is_backwards))
	{
		return undefined;
	}
	
	assert(IsDefined(tokens[0]) && IsDefined(tokens[1]));
	
	if (is_backwards)
	{
		return tokens[1];
	}
	else
	{
		return tokens[0];
	}
}

get_zone_to(tokens, is_backwards)
{
	assert(IsDefined(is_backwards));
	
	if (!IsDefined(tokens) || !IsDefined(is_backwards))
	{
		return undefined;
	}
	
	assert(IsDefined(tokens[0]) && IsDefined(tokens[1]));
	
	if (is_backwards)
	{
		return tokens[0];
	}
	else
	{
		return tokens[1];
	}
}
    
/*
///ScriptDocBegin
"Name: aud_map(input, env_points)"
"Summary: Remaps input_value to corresponding output_value based on values in envelop_array."
"Module: Audio"
"CallOn: Nothing"
"MandatoryArg: <env_points> : Array of "node-points" that define a function envelope."
"MandatoryArg: <input_value> : Value to be remapped."
"SPMP: singleplayer"
///ScriptDocEnd
*/
aud_map(input, env_points)
{
	// input is zero to one
	assert(IsDefined(input));
	assert(input >= 0.0 && input <= 1.0);
	assert(IsDefined(env_points));
	
	/# 
	// this ensures that the given envelope is in order, otherwise we'd have to perform a sorting function.
	audx_validate_env_array(env_points);
	#/
	output = 0.0;
	num_points = env_points.size;
	
	// find the x-values which are relevant for the input
	prev_point = env_points[0]; // grab the first point
	for (i = 1; i < env_points.size; i++)
	{
		next_point = env_points[i];
		if (input >= prev_point[0] && input <= next_point[0])
		{
			prev_x = prev_point[0];
			next_x = next_point[0];
			prev_y = prev_point[1];
			next_y = next_point[1];
			x_fract = (input - prev_x) / (next_x - prev_x);
			output = prev_y + x_fract * (next_y - prev_y);
			break;
		}
		else
		{
			prev_point = next_point;
		}
	}
	
	assert(output >= 0.0 && output <= 1.0);
	
	return output;
}

aud_map_range(input, range_min, range_max, env_points)
{
	assert(IsDefined(input));
	assert(IsDefined(env_points));
	
	assert(range_max != range_min);
	val = (input - range_min) / ( range_max - range_min);
	val = clamp(val, 0.0, 1.0);
	return aud_map(val, env_points);
}


/*  Example of how to define an envelope 
env_points = [];
env_points[env_points.size] = [0.0, 1.0];
env_points[env_points.size] = [0.2, 0.7];
env_points[env_points.size] = [0.4, 0.5];
env_points[env_points.size] = [1.0, 0.0];
*/

audx_validate_env_array(env_points)
{
/#
	assert(IsDefined(env_points));
	assert(env_points.size >= 2); // need at least 2 points
	
	// assert that the first point defines x = 0 behavior
	first_point = env_points[0];
	assert(first_point[0] == 0.0);
	
	// assert that the last point defines x = 1.0 behavior
	last_point = env_points[env_points.size - 1];
	assert(last_point[0] == 1.0);
	
	// lets enforce that the person who creates the envelope has to do it in increasing x-value order
	prev_x_value = -1.0;
	is_monotonic = true;
	for (i = 0; i < env_points.size; i++)
	{
		point = env_points[i];
		// assert both x and y values are given
		assert(IsDefined(point[0])); 
		assert(IsDefined(point[1]));
		
		// assert that the points are in valid ranges
		
		if(!(point[0] >= 0.0 && point[0] <= 1.0))
			debug_error( "Envelope x value is out of range.");
		if (!(point[1] >= 0.0 && point[1] <= 1.0))
			debug_error( "Envelope y value is out of range.");
		
		if (point[0] <= prev_x_value)
		{
			is_monotonic = false;
			break;
		}
		else
		{
			prev_x_value = point[0];
		}
	}
	
	if (!is_monotonic)
	{
		debug_error( "Supplied envelope array's x-values are not monotonically increasing.");
	}
#/
}

//-----------------------------------------------------------------------------------------------------
//	ENTITY-BASED PLAY SOUND FUNCTIONS
//-----------------------------------------------------------------------------------------------------
/*
///ScriptDocBegin
"Name: aud_play_linked_sound()"
"Summary: Utility function for playing a sound that is linked to another entity. Returns the entity used, but cleans the entity up itself when sound is done."
"Module: Audio"
"CallOn: Nothing"
"MandatoryArg: aliasname: sound alias string."
"MandatoryArg: ent_to_linkto: entity that you want to attach a sound to."
"OptionalArg: type_: "loop" or "oneshot". If a "loop", you must also supply a loop_stop_notify argument.
"OptionalArg: loop_stop_notify_: message to wait for to stop the loop. to stop the loop, and thus clean up the entity, do a "level notify(loop_stop_notify)" whereever you want."
"Example: thread aud_play_linked_sound(hind_alias, level.player_hind);"
"SPMP: singleplayer"
///ScriptDocEnd
*/
// TODO: Move to utility! DO NOT USE ME!
play_linked_sound( aliasname, ent_to_linkto, type, loop_stop_notify, offset )
{
	assert( IsDefined( ent_to_linkto ) );
	assert( IsDefined( aliasname ) );

	if ( !IsDefined( type ) )
	{
		type = "oneshot";
	}

	ent = Spawn( "script_origin", ent_to_linkto.origin );
	if ( IsDefined( offset ) )
	{
		ent LinkTo( ent_to_linkto, "tag_origin", offset, ( 0, 0, 0 ) );
	}
	else
	{
		ent LinkTo( ent_to_linkto );
	}
	
	if ( type == "loop" )
	{
		// monitor the valid-ness of the linked entity to automatically stop the loop and delete the ent
		ent_to_linkto thread play_linked_sound_think( ent, loop_stop_notify );
	}
	
	ent thread play_linked_sound_internal( type, aliasname, loop_stop_notify );
	return ent;
}

play_linked_sound_internal( type, aliasname, loop_stop_notify_ )
{
	if ( type == "loop" )
	{
		assert( IsDefined( loop_stop_notify_ ) );
		level endon( loop_stop_notify_ + "internal" );
		
		self playloopsound( aliasname );
		level waittill( loop_stop_notify_ );
		if ( IsDefined( self ) )
		{
			self stoploopsound( aliasname );
			wait( 0.05 );
			self delete();
		}
	}
	else if ( type == "oneshot" )
	{
		self playsound( aliasname, "sounddone" );
		self waittill( "sounddone" );
		if ( IsDefined( self ) )
		{
			self delete();
		}
	}
}

play_linked_sound_think( ent, loop_stop_notify )
{
	level endon( loop_stop_notify );
	
	while ( IsDefined( self ) )
	{
		wait( 0.1 );
	}
		
	// tell the normal playloopsound thread, audx_play_linked_sound_internal, to end
	level notify( loop_stop_notify + "internal" );
	
	// the linked entity is no longer valid, so if ent is still valid, stop the looping sound + delete the entity
	if ( IsDefined( ent ) )
	{
		ent stoploopsound();
		wait( 0.05 );
		ent delete();
	}
}

//---------------------------------------------------------
// Level FadeIn section
//---------------------------------------------------------
level_fadein()
{
	if ( !IsDefined( level._audio.level_fade_time ) )
	{
		level._audio.level_fade_time = 1.0; // default...
	}

	wait( 0.05 );
	// Move to code? -- Maybe just removing this works fine?
	LevelSoundFade( 1, level._audio.level_fade_time );    
}

//---------------------------------------------------------
// Ambient Track Section
//---------------------------------------------------------
init_tracks()
{
	level._audio.ambient_track = SpawnStruct();
	level._audio.ambient_track.current 	= create_track_struct();
	level._audio.ambient_track.previous = create_track_struct();
}

create_track_struct()
{
	struct = SpawnStruct();
	struct.name 	= "";
	struct.volume 	= 0.0;
	struct.fade 	= 0.0;

	return struct;
}

clear_track_struct( struct )
{
	struct.name 	= "";
	struct.volume 	= 0.0;
	struct.fade 	= 0.0;
}

set_current_track_struct( struct, alias, volume, fade )
{
	struct.previous set_track_values( struct.current.name, 	struct.current.volume, 	struct.current.fade );
	struct.current 	set_track_values( alias, 				volume, 				fade );
}


set_track_values( name, volume, fade )
{
	self.name 	= name;
	self.volume = volume;
	self.fade 	= fade;
}

set_ambient_track( alias, fade, volume )
{
	if ( !IsDefined( fade ) )
	{
		fade = 1;
	}
	
	if ( !IsDefined( volume ) )
	{
		volume = 1;
	}

	set_current_track_struct( level._audio.ambient_track, alias, volume, fade );

	set_hud_value( "ambient", alias);
	set_hud_name_percent_value( "ambient_from", "" );
	set_hud_name_percent_value( "ambient_to", "" );

	AmbientPlay( alias, fade, volume );
}

stop_ambient_track( alias, fade )
{
	if ( alias == "" )
	{
		return;
	}

	if ( !IsDefined( fade ) )
	{
		fade = 1;
	}

	if ( level._audio.ambient_track.current.name == alias )
	{
		level._audio.ambient_track.current = level._audio.ambient_track.previous;

		set_hud_value( "ambient", "" );
		set_hud_name_percent_value( "ambient_from", "" );
		set_hud_name_percent_value( "ambient_to", "" );

		clear_track_struct( level._audio.ambient_track.previous );
	}
	else if ( level._audio.ambient_track.previous.name == alias )
	{
		clear_track_struct( level._audio.ambient_track.previous );
	}

	AmbientStop( fade, alias );
}

stop_ambient_tracks( fade )
{
	if ( !IsDefined( fade ) )
	{
		fade = 1;
	}

	clear_track_struct( level._audio.ambient_track.current );
	clear_track_struct( level._audio.ambient_track.previous );
		
/#
	set_hud_value( "ambient", "" );
	set_hud_name_percent_value( "ambient_from", "", "" );
	set_hud_name_percent_value( "ambient_to", "", "" );
#/

	AmbientStop( fade );
}

mix_ambient_tracks( info_array )
{
	threshold = 0.009;

	current_track = level._audio.ambient_track.current;
	prevous_track = level._audio.ambient_track.previous;
	
	if ( info_array.size == 1 )
	{
/#
		set_hud_name_percent_value( "ambient_from", "", "" );
		
		if ( info_array[ 0 ].volume < threshold || 1.0 - info_array[ 0 ].volume < threshold )
		{
			set_hud_name_percent_value( "ambient_to", "", "" );
			if ( 1.0 - info_array[ 0 ].volume < threshold )
				set_hud_value( "ambient", info_array[ 0 ].alias );
			else
				set_hud_value( "ambient", "" );
		}
		else
		{
			set_hud_name_percent_value( "ambient_to", info_array[ 0 ].alias, info_array[ 0 ].volume );
		}
#/
		current_track set_track_values( info_array[ 0 ].alias, info_array[ 0 ].volume, info_array[ 0 ].fade );
	}
	else if ( info_array.size == 2 ) // from 0 to 1
	{
/#
		is_close = [ false, false ];
		is_close[ 0 ] = ( info_array[ 0 ].volume < threshold || 1.0 - info_array[ 0 ].volume < threshold );
		is_close[ 1 ] = ( info_array[ 1 ].volume < threshold || 1.0 - info_array[ 1 ].volume < threshold );
		
		if ( is_close[ 0 ] && is_close[ 1 ] )
		{
			set_hud_name_percent_value( "ambient_to", "", "" );
			set_hud_name_percent_value( "ambient_from", "", "" );
				
			if ( info_array[ 0 ].volume > info_array[ 1 ].volume )
				set_hud_value( "ambient", info_array[ 0 ].alias );
			else
				set_hud_value( "ambient", info_array[ 1 ].alias );
		}
		else
		{
			set_hud_name_percent_value( "ambient_to", info_array[ 1 ].alias, info_array[ 1 ].volume );
			set_hud_name_percent_value( "ambient_from", info_array[ 0 ].alias, info_array[ 0 ].volume );
			set_hud_value( "ambient", "blending" );
		}
#/

		prevous_track set_track_values( info_array[ 0 ].alias, info_array[ 0 ].volume, info_array[ 0 ].fade );
		current_track set_track_values( info_array[ 1 ].alias, info_array[ 1 ].volume, info_array[ 1 ].fade );
	}
		
	for ( i = 0; i < info_array.size; i++ )
	{
		alias = info_array[ i ].alias;
		volume = max( info_array[ i ].volume, 0 );
		fade = clamp( info_array[ i ].fade, 0, 1 );

		if ( alias != "" )
		{
			if ( volume < threshold )
				AmbientStop( fade, alias );
			else
				AmbientPlay( alias, fade, volume, false ); // non-exclusive mix
		}
	}
}

empty_string_if_none( str )
{
	if ( str == "none" )
		return "";

	return str;
}

//---------------------------------------------------------
// Zone Section
//---------------------------------------------------------
init_zones()
{
	level._audio.zone 				= SpawnStruct();
	level._audio.zone.current_zone 	= "";
	level._audio.zone.cached 		= [];
}

set_zone( name, fade, specops_player )
{
	if ( IsDefined( specops_player ) )
		assert( specops_player == level.player );

	if ( level._audio.zone.current_zone == name )
	{
		return;
	}

	if ( level._audio.zone.current_zone != "" )
	{
		stop_zone( level._audio.zone.current_zone, fade );
	}

	level._audio.zone.current_zone = name;
	
	if ( IsDefined( level._audio.zone.cached[ name ] ) && IsDefined( level._audio.zone.cached[ name ][ "state" ] ) && level._audio.zone.cached[ name ][ "state" ] != "stopping" )
	{
		debug_error( "set_zone( \"" + name + "\" ) being called even though audio zone, \"" + name + "\", is already started." );
		return;
	}

	if ( !IsDefined( fade ) )
	{
		fade = 2;
	}

	cache_zone( name );

	assertEx( IsDefined( level._audio.zone.cached[ name ] ), "set_zone() - ZONE \"" + name + "\" is not defined. Check your soundtable for typos and be sure to include your soundtable into your level zone_source." );

	debug_println( "ZONE START: " + name );

	// set the state to "playing"
	level._audio.zone.cached[ name ][ "state" ] = "playing";
	
	set_hud_value( "zone", name );

	zone = level._audio.zone.cached[ name ];
	
	// now start everything up if it's been defined for the zone	
	if ( IsDefined( zone[ "ambience" ] ) )
	{
		if ( zone[ "ambience" ] != "" )
		{
			set_ambient_track( zone[ "ambience" ], fade );
		}
		else
		{
			stop_ambient_tracks( fade );
		}
	}
	
	if ( IsDefined( zone[ "ambient_name" ] ) )
	{
		if ( zone[ "ambient_name" ] != "" )
		{
			set_hud_value( "ambient_elem", zone[ "ambient_name" ] );
			set_hud_name_percent_value( "ambient_elem_from", "", "" );
			set_hud_name_percent_value( "ambient_elem_to", "", "" );

			maps\_audio_ambient::start_ambient_event_zone( zone[ "ambient_name" ] );
		}
		else
		{
			set_hud_value( "ambient_elem", "" );
			set_hud_name_percent_value( "ambient_elem_from", "", "" );
			set_hud_name_percent_value( "ambient_elem_to", "", "" );

			maps\_audio_ambient::stop_current_ambient();
		}
	}

	if ( IsDefined( zone[ "occlusion" ] ) )
	{
		if ( zone[ "occlusion" ] != "" )
		{
			set_occlusion( zone[ "occlusion" ] );
		}
		else
		{
			deactivate_occlusion();
		}
	}
	
	// apply the occlusion, reverb, and mix, which may or may not have values...
	if ( IsDefined( zone[ "filter" ] ) )
	{
		if ( zone[ "filter" ] != "" )
		{
			set_filter( zone[ "filter" ], 0 );
			level.player SetEqLerp( 1, level._audio.filter.eq_index );	
		}
		// if starting an occlusion preset FROm a zone start, then there should be no
		// lerping going on, and there should be only one eq... which is the main ( in slot 1 )
	}	
	
	if ( IsDefined( zone[ "reverb" ] ) )
	{
		if ( zone[ "reverb" ] != "" )
		{
			set_reverb( zone[ "reverb" ] );
		}
		else
		{
			clear_reverb();
		}
	}
	
	if ( IsDefined( zone[ "mix" ] ) )
	{
		if ( zone[ "mix" ] != "" )
		{
			set_mix( zone[ "mix" ], fade );
		}
		else
		{
			clear_mix();
		}
	}
}

stop_zones( fade )
{
	if ( !IsDefined( fade ) )
	{
		fade = 1.0;
	}
	
	debug_println( "ZONE STOP ALL" );
		
	foreach ( zone in level._audio.zone.cached )
	{
		stop_zone( zone[ "name" ], fade ); // false = don't print in this case
	}
}

stop_zone( name, fade )
{
	// only stop the zone if it has already played	
	if ( IsDefined( level._audio.zone.cached[ name ] ) && IsDefined( level._audio.zone.cached[ name ][ "state" ] ) && level._audio.zone.cached[ name ][ "state" ] != "stopping" )
	{
		if ( !IsDefined( fade ) )
		{
			fade = 1.0;
		}
		
		zone = level._audio.zone.cached[ name ];		
		debug_println( "ZONE STOP " + name );
		
		// "stopping" an audio zone currently only stops the streamed ambience and the dynamic ambience
		// it doesn't "stop" the reverb, the occlusion, or the mix, since it doesn't really make 
		// sense to stop those systems. 
		
		if ( IsDefined( zone[ "ambience" ] ) )
		{
			stop_ambient_track( zone[ "ambience" ], fade );
		}
		
		if ( IsDefined( zone[ "ambient_name" ] ) )
		{
//			stop_ambient_elems( fade, zone[ "ambient_name" ] );
			maps\_audio_ambient::stop_ambient_event_zone( zone[ "ambient_name" ] );
		}
		
		level._audio.zone.cached[ name ][ "state" ] = "stopping"; // make sure that we don't try to stop WHILE we're already stopping
	}
}


//---------------------------------------------------------
// FILTER SECTION
//---------------------------------------------------------
init_filter()
{
	level._audio.filter = SpawnStruct();
	level._audio.filter.eq_index = 0;
	level._audio.filter.current = [];
	level._audio.filter.current[ 0 ] = "";
	level._audio.filter.current[ 1 ] = "";
//	level._audio.filter.cached = [];
	
	level._audio.filter.previous = [];
	level._audio.filter.previous[ 0 ] = "";
	level._audio.filter.previous[ 1 ] = "";	
}

set_filter( name, index )
{
	if ( !IsDefined( index ) )
	{
		index = 0;
	}
	
	if ( level._audio.filter.current[ index ] == name )
	{
		return;
	}

	if ( IsDefined( level._audio.in_deathsdoor ) )
	{
		level._audio.deathsdoor.filter[ index ] = name;
		return;
	}

	// Decactivate all of the channels not used
	if ( level._audio.filter.current[ index ] != name )
	{
		debug_println( "filter DeactivateEq() " + "index=" + index, 2 );
		level.player DeactivateEq( index );
	}

	set_current_filter( index, name );

/#
	msg = "filter SetEQFromTable(): name=" + name;
	msg += " index=" + index;
	debug_println( msg, 2 );
#/
	level.player SetEQFromTable( get_map_soundtable(), name, index );
}

set_current_filter( index, name )
{
	if ( name == "deathsdoor" )
	{
		return;
	}

	level._audio.filter.previous[ index ] = level._audio.filter.current[ index ];
	level._audio.filter.current[ index ] = name;
	
	set_hud_name_percent_value( "filter_" + index, name, "last" );	
}

clear_filter( index )
{
	if ( !IsDefined( index ) )
	{
		index = 0;
	}

	set_current_filter( index, "" );
	debug_println( "filter DeactivateEq() " + "index=" + index, 2 );
	level.player DeactivateEq( index );

	set_hud_name_percent_value( "filter_" + index, ""	  , "last" );
}

//---------------------------------------------------------
// OCCLUSION SECTION
//---------------------------------------------------------
init_occlusion()
{
	level._audio.occlusion = SpawnStruct();
	level._audio.occlusion.current = "";

	set_occlusion( "default" );
}

set_occlusion( name )
{
	if ( level._audio.occlusion.current == name )
	{
		return;
	}
	
	thread set_occlusion_thread( name );
}
	
set_occlusion_thread( name )
{
	if ( level._audio.occlusion.current == name )
	{
		return;
	}

	level._audio.occlusion.current = name;
	
	debug_println( "occlusion SetOcclusionFromTable() " + "name=" + name, 2 );
	set_hud_value( "occlusion", name );
	level.player SetOcclusionFromTable( get_map_soundtable(), name );
}

deactivate_occlusion()
{
	debug_println( "occlusion DeactivateAllOcclusion() " );
	level.player DeactivateAllOcclusion();
}

//---------------------------------------------------------
// Reverb section
//---------------------------------------------------------
init_reverb(args)
{
	level._audio.reverb = SpawnStruct();
	level._audio.reverb.current = "";
}

set_reverb( name )
{
	if ( !IsDefined( name ) )
	{
		return;
	}

	if ( level._audio.reverb.current == name )
	{
		return;
	}

	if ( IsDefined( level._audio.in_deathsdoor ) && name != "deathsdoor" )
	{
		level._audio.deathsdoor.reverb = name;
		return;
	}

	level._audio.reverb.current = name;

/#
	if ( name == "deathsdoor" )
	{
		set_hud_value( "reverb", "^3DEATHSDOOR" );
	}
	else
	{
		set_hud_value( "reverb", name );
	}
#/

	debug_println( "reverb SetReverbFromTable(): " + "name=" + name, 2 );
	level.player SetReverbFromTable( get_map_soundtable(), name, "snd_enveffectsprio_level" );
}

clear_reverb()
{
	debug_println( "deactivatereverb" );
	level.player DeactivateReverb( "snd_enveffectsprio_level", 2 );

	level._audio.reverb.current = "";

	set_hud_value( "reverb", "" );

}

//---------------------------------------------------------
// Mix Section
//---------------------------------------------------------
init_mix()
{
	level._audio.mix			= SpawnStruct();
	level._audio.mix.current	= "";
	level._audio.mix.previous	= "";
	
	set_mix( "default" );
}

set_mix( name, fade )
{
	if ( level._audio.mix.current == name )
	{		
		return;
	}
	
	change_mix( name, "default", fade );
}

change_mix( new_mix, compared_mix, fade )
{
	if ( !IsDefined( compared_mix ) )
	{
		compared_mix = "default";
	}
	
	if ( new_mix == compared_mix )
	{
		return;
	}

/#
	msg = "mix SetVolModFromTable(): name=" + new_mix;
	debug_println( msg, 2 );
#/

	if ( IsDefined( fade ) )
	{
		level.player SetVolModFromTable( get_map_soundtable(), new_mix, fade );
	}
	else
	{
		level.player SetVolModFromTable( get_map_soundtable(), new_mix );
	}
	
	set_hud_value( "mix", new_mix );
	
	level._audio.mix.previous	= level._audio.mix.current;
	level._audio.mix.current	= new_mix;
}

clear_mix( fade )
{
	if ( level._audio.mix.current == "" )
	{
		return;
	}

	if ( !IsDefined( fade ) )
	{
		fade = 1;
	}
	
	change_mix( "default", level._audio.mix.current );
}

//---------------------------------------------------------
// Whizby SECTION
//---------------------------------------------------------
init_whizby()
{
	level._audio.whizby = SpawnStruct();
	level._audio.whizby.current = "";

	thread set_whizby( "default" );
}

set_whizby( name )
{
	if ( level._audio.whizby.current == name )
	{
		return;
	}

	level._audio.whizby.current = name;

/#
	msg = "whizby SetWhizbyFromTable(): name=" + name;
	debug_println( msg, 2 );
#/

	level.player SetWhizbyFromTable( get_map_soundtable(), name );
}

//---------------------------------------------------------
// TIMESCALE SECTION
//---------------------------------------------------------
init_timescale()
{
	level._audio.timescale = SpawnStruct();
	level._audio.timescale.current = "";

	set_timescale( "default" );
}

set_timescale( name )
{
	if ( level._audio.timescale.current == name )
	{
		return;
	}

	level._audio.timescale.current = name;

/#
	msg = "timescale SetTimeScaleFactorFromTable(): name=" + name;
	debug_println( msg, 2 );
#/

	level.player SetTimeScaleFactorFromTable( get_map_soundtable(), name );
}