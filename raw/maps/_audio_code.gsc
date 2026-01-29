#include maps\_utility_code;
#include maps\_utility;
#include maps\_audio;
#include common_scripts\utility;

get_channel_array()
{
	array = [];
	array[ "physics"		 ]	= "physics";
	array[ "ambdist1"		 ]	= "ambdist1";
	array[ "ambdist2"		 ]	= "ambdist2";
	array[ "alarm"			 ]	= "alarm";
	array[ "auto"			 ]	= "auto";
	array[ "auto2"			 ]	= "auto2";
	array[ "auto2d"			 ]	= "auto2d";
	array[ "autodog"		 ]	= "autodog";
	array[ "explosiondist1"	 ]	= "explosiondist1";
	array[ "explosiondist2"	 ]	= "explosiondist2";
	array[ "explosiveimpact" ]	= "explosiveimpact";
	array[ "element"		 ]	= "element";
	array[ "foley_plr_mvmt"	 ]	= "foley_plr_mvmt";
	array[ "foley_plr_weap"	 ]	= "foley_plr_weap";
	array[ "foley_npc_mvmt"	 ]	= "foley_npc_mvmt";
	array[ "foley_npc_weap"	 ]	= "foley_npc_weap";
	array[ "element_int"	 ]	= "element_int";
	array[ "element_ext"	 ]	= "element_ext";
	array[ "foley_dog_mvmt"	]	= "foley_dog_mvmt";
	array[ "voice_dog"	]	= "voice_dog";
	array[ "voice_dog_dist"	]	= "voice_dog_dist";
	array[ "bulletflesh1npc_npc"	]	= "bulletflesh1npc_npc";
	array[ "bulletflesh2npc_npc"	]	= "bulletflesh2npc_npc";
	array[ "bulletimpact"	 ]	= "bulletimpact";
	array[ "bulletflesh1"	 ]	= "bulletflesh1";
	array[ "bulletflesh2"	 ]	= "bulletflesh2";
	array[ "vehicle"		 ]	= "vehicle";
	array[ "vehiclelimited"	 ]	= "vehiclelimited";
	array[ "menu"			 ]	= "menu";
	array[ "menulim1"		 ]	= "menulim1";
	array[ "menulim2"		 ]	= "menulim2";
	array[ "bulletflesh1npc"	]	= "bulletflesh1npc";
	array[ "bulletflesh2npc"	]	= "bulletflesh2npc";
	array[ "bulletwhizbyin"	 ]	= "bulletwhizbyin";
	array[ "bulletwhizbyout" ]	= "bulletwhizbyout";
	array[ "body"			 ]	= "body";
	array[ "body2d"			 ]	= "body2d";
	array[ "reload"			 ]	= "reload";
	array[ "reload2d"		 ]	= "reload2d";
	array[ "foley_plr_step"  ]	= "foley_plr_step";
	array[ "foley_plr_step_unres"  ]	= "foley_plr_step";
	array[ "foley_npc_step"  ]	= "foley_npc_step";
	array[ "foley_dog_step"	]	= "foley_dog_step";
	array[ "item"			 ]	= "item";
	array[ "explosion1"		 ]	= "explosion1";
	array[ "explosion2"		 ]	= "explosion2";
	array[ "explosion3"		 ]	= "explosion3";
	array[ "explosion4"		 ]	= "explosion4";
	array[ "explosion5"		 ]	= "explosion5";
	array[ "effects1"		 ]	= "effects1";
	array[ "effects2"		 ]	= "effects2";
	array[ "effects3"		 ]	= "effects3";
	array[ "effects2d1"		 ]	= "effects2d1";
	array[ "effects2d2"		 ]	= "effects2d2";
	array[ "norestrict"		 ]	= "norestrict";
	array[ "norestrict2d"	 ]	= "norestrict2d";
	array[ "aircraft"		 ]	= "aircraft";
	array[ "vehicle2d"		 ]	= "vehicle2d";
	array[ "weapon_dist"	 ]	= "weapon_dist";
	array[ "weapon_mid"		 ]	= "weapon_mid";
	array[ "weapon"			 ]	= "weapon";
	array[ "weapon2d"		 ]	= "weapon2d";
	array[ "nonshock"		 ]	= "nonshock";
	array[ "nonshock2"		 ]	= "nonshock2";
	array[ "voice"			 ]	= "voice";
	array[ "music_emitter"	]	= "music_emitter";
	array[ "voice_dog_attack"	]	= "voice_dog_attack";
	array[ "local"			 ]	= "local";
	array[ "local2"			 ]	= "local2";
	array[ "local3"			 ]	= "local3";
	array[ "ambient"		 ]	= "ambient";
	array[ "plr_weap_fire_2d" ]	= "plr_weap_fire_2d";
	array[ "plr_weap_mech_2d" ]	= "plr_weap_mech_2d";
	array[ "hurt"			 ]	= "hurt";
	array[ "player1"		 ]	= "player1";
	array[ "player2"		 ]	= "player2";
	array[ "music"			 ]	= "music";
	array[ "musicnopause"	 ]	= "musicnopause";
	array[ "mission"		 ]	= "mission";
	array[ "missionfx"		 ]	= "missionfx";
	array[ "announcer"		 ]	= "announcer";
	array[ "shellshock"		 ]	= "shellshock";
	
	return array;
}

//---------------------------------------------------------
// Ambient Section
//---------------------------------------------------------
cache_ambient( name )
{
	if ( IsDefined( level._audio.ambient.cached_ambients[ name ] ) )
	{
		return;
	}

	column_names = [ "ambient_name", "time_min", "time_max" ];
	data = get_table_data( get_map_soundtable(), name, column_names );

	if ( data.size == 0 )
	{
		return;
	}

	data[ "time_min" ] = string_to_float( data[ "time_min" ] );
	data[ "time_max" ] = string_to_float( data[ "time_max" ] );
	data[ "time" ] = [ data[ "time_min" ], data[ "time_max" ] ];

	data[ "time_min" ] = undefined;
	data[ "time_max" ] = undefined;

	temp = SpawnStruct();
	temp.data = data;

	if ( data[ "time" ][ 0 ] > 0 && data[ "time" ][ 1 ] > 0 )
	{
		temp.serialized = true;
	}

	level._audio.ambient.cached_ambients[ name ] = temp;

	cache_ambient_event( name );
}

cache_ambient_event( name )
{
	column_names = [ "ambient_event", "element", "weight" ];
	array = get_table_data_array( get_map_soundtable(), name, column_names );

	if ( array.size == 0 )
	{
		return;
	}

	foreach ( i, item in array )
	{
		array[ i ][ "weight" ] = string_to_float( item[ "weight" ] );
	}

	events = [];
	foreach ( item in array )
	{
		event = SpawnStruct();
		event.elem = item[ "element" ];
		event.weight = item[ "weight" ];
		events[ events.size ] = event;

		cache_ambient_element( event );
	}

	level._audio.ambient.cached_ambients[ name ].events = events;
}

cache_ambient_element( event )
{
	name = event.elem;
	if ( IsDefined( level._audio.ambient.cached_elems[ name ] ) )
	{
		return;
	}

	column_names = [ "ambient_element", "alias", "range_min", "range_max", "cone_min", "cone_max", 
					 "time_min", "time_max", "travel_min", "travel_max", "travel_time_min", 
					 "travel_time_max" ];

	data = get_table_data( get_map_soundtable(), name, column_names );

	if ( data.size == 0 )
	{
		return;
	}

	foreach ( i, item in data )
	{
		if ( item == "" )
		{
			data[ i ] = undefined;
			continue;
		}

		if ( i == "alias" )
		{
			continue;
		}

		data[ i ] = string_to_float( data[ i ] );
	}

	prefixes = [ "range", "cone", "time", "travel", "travel_time" ];

	foreach ( prefix in prefixes )
	{
		if ( IsDefined( data[ prefix + "_min" ] ) && IsDefined( data[ prefix + "_max" ] ) )
		{
			data[ prefix ] = [ data[ prefix + "_min" ], data[ prefix + "_max" ] ];
			data[ prefix + "_min" ] = undefined;
			data[ prefix + "_max" ] = undefined;
		}
	}

//	if ( IsDefined( data[ "time" ] ) && data[ "time" ][ 0 ] > 0 && data[ "time" ][ 1 ] > 0 )
//	{
//		event.data[ "time" ] = data[ "time" ];
//	}

	level._audio.ambient.cached_elems[ name ] = data;
}

//---------------------------------------------------------
// Zone Section
//---------------------------------------------------------
cache_zone( name )
{
	if ( IsDefined( level._audio.zone.cached[ name ] ) )
	{
		return;
	}

	column_names = [ "zone_name", "ambience", "ambient_name", "mix", "reverb", "filter", "occlusion" ];
	data = get_table_data( get_map_soundtable(), name, column_names );

	if ( data.size == 0 )
	{
		return;
	}
	
	level._audio.zone.cached[ name ] = data;
}

//---------------------------------------------------------
// Zone Blending Section
//---------------------------------------------------------
get_zone_blend_args( zone_from, zone_to )
{
	// the current zone ( which should be "from" )
	if ( !IsDefined( level._audio.zone.cached[ zone_from ] ) )
	{
		cache_zone( zone_from );
		if ( !IsDefined( level._audio.zone.cached[ zone_from ] ) )
		{
			debug_warning( "Couldn't find zone: " + zone_from );
			return undefined; // failed to load
		}
	}

	current_zone = level._audio.zone.cached[ zone_from ];

	if ( !IsDefined( level._audio.zone.cached[ zone_to ] ) )
	{
		cache_zone( zone_to );
		if ( !IsDefined( level._audio.zone.cached[ zone_to ] ) ) 
		{
			debug_warning( "Couldn't find zone: " + zone_to );
			return undefined; // failed to load zone
		}
	}	

	destination_zone = level._audio.zone.cached[ zone_to ];

	// Store the zone_from and zone_to parameters
	array = [ "ambience", "occlusion", "filter", "reverb", "mix" ];

	args = [];
	args[ "zone1" ] = zone_from;
	args[ "zone2" ] = zone_to;

	foreach ( value in array )
	{
		args[ value + "1" ] = current_zone[ value ];
		args[ value + "2" ] = destination_zone[ value ];
	}

	// SET UP DYNAMIC AMBI ARGS -- Can below be done better?
	args[ "ambient_name1" ] = level._audio.ambient.current_zone;
	maps\_audio_ambient::stop_current_ambient();

/#
	if ( IsDefined( current_zone[ "ambient_name" ] ) )
	{
		if ( args[ "ambient_name1" ] != current_zone[ "ambient_name" ] )
		{
			debug_warning( "Blending from a dynamic ambience ( " + args[ "ambient_name1" ] + " ) which isn't the current zone's ( " + current_zone[ "ambient_name" ] + " ) ." );
		}
	}
#/
		
	args[ "ambient_name2" ] = destination_zone[ "ambient_name" ];
	
	return args;
}

/************************************************************************************************
	[Zone] Filters out cases where we DO NOT want to change or xfade the ambis at all:
	1) The "to" ambi is undefined.
	2) The "from" ambi is already playing, and is the same ambi as the "to" ambi.
************************************************************************************************/	
is_dyn_ambience_valid( from, to )
{
	if ( !IsDefined( from ) && !IsDefined( to ) )
	{
		return false;
	}

	if ( IsDefined( from ) || IsDefined( to ) )
	{
		return true;
	}

	if ( from == to )
	{
		return false;
	}

	return true;
}

is_ambience_blend_valid( from, to )
{
	if ( !IsDefined( from ) && !IsDefined( to ) )
	{
		return false;
	}

	if ( from == to )
	{
		return false;
	}

	if ( !IsDefined( to ) )
	{
		return false;
	}

	return true;
}

blend_zones( level_1, level_2, args, is_backward )
{	
	assert(IsDefined(level_1));
	assert(IsDefined(level_2));
	assert(IsDefined(args));

	levels = [ level_1, level_2 ];

	// Since we never reverse filters, we need to make sure we reverse the level for eq only properly as well
	// look at trigger_multiple_audio_trigger() for note
	eq_levels = levels;
	if ( is_backward )
	{
		eq_levels = array_reverse( eq_levels );
	}
	
	if 	( is_ambience_blend_valid( args[ "ambience1" ], args[ "ambience2" ] ) )
	{
		alias_info = [];
					
		// Only fade the "from" ambi if it's already playing (don't start/fade it if it's not already playing).
		for( i = 0; i < 2; i++ )
		{
			num = i + 1;
			index = "ambience" + num;
			if ( IsDefined( args[ index ] ) && args[ index ] != "" )
			{
				zone = level._audio.zone.cached[ args[ "zone" + num ] ];
				assert( IsDefined( zone ) );

				alias_info[ i ] 			= SpawnStruct();
				alias_info[ i ].alias 		= args[ index ];
				alias_info[ i ].volume 		= levels[ i ];
				alias_info[ i ].fade 		= 0.5; // TODO: This was "interrupt_fade" which was always set to 0.1, make this data driven?
			}
		}

		if ( alias_info.size > 0 )
		{
			mix_ambient_tracks( alias_info );
		}
	}

	if ( is_dyn_ambience_valid( args[ "ambient_name1" ], args[ "ambient_name2" ] ) )
	{
//		DAMB_prob_mix_damb_presets( args[ "ambient_name1" ], level_1, args[ "ambient_name2" ], level_2 );
		maps\_audio_ambient::swap_ambient_event_zones( args[ "ambient_name1" ], level_1, args[ "ambient_name2" ], level_2 );
	}
	
	filter_count = 0;

	// Store eq in slots 0 and 1.
	for ( i = 0; i < 2; i++ )
	{
		num = i + 1;
		filter = undefined;
		if ( IsDefined( args[ "filter" + num ] ) )
		{
			filter_count++;
			filter = args[ "filter" + num ];
		}

		if ( !IsDefined( filter ) || filter == "" )
		{
			clear_filter( i );
		}
		else
		{
			set_filter( filter, i );
		}
		
/#
		hud_refs = [ "filter_0", "filter_1" ];
		if ( IsDefined( filter ) )
			set_hud_name_percent_value( hud_refs[ i ], filter, eq_levels[ i ] );
		else
			set_hud_name_percent_value( hud_refs[ i ], "", "" );
#/
	}
	
	if ( filter_count == 2 )
	{
		level.player SetEqLerp( eq_levels[ 0 ], 0 );
	}
	
	// TODO: Can the below section be done simpler?
	if ( level_1 >= 0.75 )
	{
		if ( IsDefined( args[ "reverb1" ] ) )
		{
			if ( args[ "reverb1" ] == "" )
			{
//				set_reverb( undefined ); // Not sure what this was intended for?
			}
			else
				set_reverb( args[ "reverb1" ] );
		}
	
		if ( IsDefined( args[ "mix1" ] ) )
		{
			if ( args[ "mix1" ] == "" )
				clear_mix( 2 );
			else
				set_mix( args[ "mix1" ] );
		}
		
		if ( IsDefined( args[ "occlusion1" ] ) )
		{
			if ( args[ "occlusion1" ] == "" )
				deactivate_occlusion();
			else
				set_occlusion( args[ "occlusion1" ] );
		}
		// set occlusion 1 here
	}
	else if ( level_2 >= 0.75 )
	{
		if ( IsDefined( args[ "reverb2" ] ) )
		{
			if ( args[ "reverb2" ] == "" )
			{
//				set_reverb( undefined ); // Not sure what this was intended for?
			}
			else
				set_reverb( args[ "reverb2" ] );
		}

		if ( IsDefined( args[ "mix2" ] ) )
		{
			if ( args[ "mix2" ] == "" )
				clear_mix( 2 );
			else
				set_mix( args[ "mix2" ] );
		}
		
		if ( IsDefined( args[ "occlusion2" ] ) )
		{
			if ( args[ "occlusion2" ] == "" )
				deactivate_occlusion();
			else
				set_occlusion( args[ "occlusion2" ] );
		}
	}
}

//---------------------------------------------------------
// Zone Utility section
//---------------------------------------------------------
get_current_audio_zone()
{
	return level._audio.zone.current_zone;
}

set_current_audio_zone( zone )
{
	assert( IsString( zone ) );
	level._audio.zone.current_zone = zone;
}

//---------------------------------------------------------
// Zone Debug Section
//---------------------------------------------------------
validate_zone(zone, name)
{
/#
	assert( IsDefined( zone ) );
	assert( IsDefined( name ) );
	if ( zone.size == 0 )
	{
		return;
	}
	
	// NOTE: the validations performed here just make sure that the zone preset manager is filled out correctly. The
	// various managers do their own validation to ensure that they are themselves existent and set up correctly...
	if ( IsDefined( zone[ "priority" ] ) )
	{
		assertEx( zone[ "priority" ] >= 0.0, "ZONE preset, \"" + name + "\", must have a priority greater than zero." );
	}
	
	indexes = [ "ambience", "ambient_name", "reverb", "occlusion", "mix" ];
	foreach ( index in indexes )
	{
		if ( IsDefined( zone[ index ] ) )
		{
			assertEx( IsString( zone[ index ] ) , "ZONE preset, \"" + name + "\", must have a string-valued " + index + " preset." );
		}
	}
#/
}

//---------------------------------------------------------
// Filter Section
//---------------------------------------------------------
cache_filter( name )
{
	if ( IsDefined( level._audio.filter.cached[ name ] ) )
	{
		return;
	}

	column_names = [ "filter_name", "channel", "band", "type", "freq", "gain", "q" ];
	array = get_table_data_array( get_map_soundtable(), name, column_names );

	if ( array.size == 0 )
	{
		return;
	}

	foreach ( i, data in array )
	{
		array[ i ][ "band" ] 	= string_to_int( data[ "band" ] );
		array[ i ][ "freq" ] 	= string_to_float( data[ "freq" ] );
		array[ i ][ "gain" ] 	= string_to_float( data[ "gain" ] );
		array[ i ][ "q" ] 		= string_to_float( data[ "q" ] );
	}

	level._audio.filter.cached[ name ] = array;
}

//---------------------------------------------------------
// Occlusion Section
//---------------------------------------------------------
cache_occlusion( name )
{
	if ( IsDefined( level._audio.occlusion.cached[ name ] ) )
	{
		return;
	}

	column_names = [ "occlusion_name", "channel", "freq", "type", "gain", "q" ];
	array = get_table_data_array( get_map_soundtable(), name, column_names );

	if ( array.size == 0 )
	{
		return;
	}

	foreach ( i, data in array )
	{
		array[ i ][ "freq" ] 	= string_to_float( data[ "freq" ] );
		array[ i ][ "gain" ] 	= string_to_float( data[ "gain" ] );
		array[ i ][ "q" ] 		= string_to_float( data[ "q" ] );
	}

	level._audio.occlusion.cached[ name ] = array;
}

//---------------------------------------------------------
// Mix Section
//---------------------------------------------------------
cache_mix( name )
{
	if ( IsDefined( level._audio.mix.cached[ name ] ) )
	{
		return;
	}

	column_names = [ "mix_name", "mix_bus", "volume", "fade" ];
	array = get_table_data_array( get_map_soundtable(), name, column_names );

	if ( array.size == 0 )
	{
		return;
	}

	// NOTE: i is the mix_bus variable
	foreach ( i, data in array )
	{
		array[ i ][ "volume" ] 		= string_to_float( data[ "volume" ] );
		array[ i ][ "fade" ] 		= string_to_float( data[ "fade" ] );
		array[ i ][ "mix_bus" ]		= undefined; // save some variables
	}

	level._audio.mix.cached[ name ] = array;
}

cache_mix_default()
{
	column_names = [ "mix_bus", "volume" ];
	array = read_in_table( "soundaliases/volumemodgroups.svmod", column_names );
	
	// NOTE: i is the mix_bus variable
	foreach ( i, data in array )
	{
		array[ i ][ "volume" ] 		= string_to_float( data[ "volume" ] );
		array[ i ][ "fade" ] 		= 1;
		array[ i ][ "mix_bus" ]		= undefined; // save some variables
	}
	
	level._audio.mix.cached[ "default" ] = array;
}

//---------------------------------------------------------
// Reverb Section
//---------------------------------------------------------
cache_reverb( name )
{
	if ( IsDefined( level._audio.reverb.cached[ name ] ) )
	{
		return;
	}

	column_names = [ "reverb_name", "roomtype", "drylevel", "wetlevel", "fade" ];

	data = get_table_data( get_map_soundtable(), name, column_names );

	if ( data.size == 0 )
	{
		return;
	}

	data[ "drylevel" ] 	= string_to_float( data[ "drylevel" ] );
	data[ "wetlevel" ] 	= string_to_float( data[ "wetlevel" ] );
	data[ "fade" ] 		= string_to_float( data[ "fade" ] );

	level._audio.reverb.cached[ name ] = data;
}

//---------------------------------------------------------
// Whizby Section
//---------------------------------------------------------
cache_whizby( name )
{
	if ( IsDefined( level._audio.whizby.cached[ name ] ) )
	{
		return;
	}

	column_names = [ "whizby_name", "near_radius", "medium_radius", "far_radius", 
					 "radius_offset", "near_spread", "medium_spread", "far_spread", 
					 "near_prob", "medium_prob", "far_prob" ];

	data = get_table_data( get_map_soundtable(), name, column_names );

	if ( data.size == 0 )
	{
		return;
	}

	foreach ( i, _ in data )
	{
		data[ i ] = string_to_float( data[ i ] );
	}

	level._audio.whizby.cached[ name ] = data;
}

//---------------------------------------------------------
// Timescale Section
//---------------------------------------------------------
cache_timescale( name )
{
	if ( IsDefined( level._audio.timescale.cached[ name ] ) )
	{
		return;
	}

	column_names = [ "timescale_name", "channel", "scale" ];

	array = get_table_data_array( get_map_soundtable(), name, column_names );

	if ( array.size == 0 )
	{
		return;
	}

	foreach ( i, data in array )
	{
		array[ i ][ "scale" ] = string_to_float( data[ "scale" ] );
	}

	level._audio.timescale.cached[ name ] = array;
}

//---------------------------------------------------------
// Table Section
//---------------------------------------------------------
get_table_data( filename, name, column_names )
{
	data = [];
	if ( TableExists( get_map_soundtable() ) )
	{
		data = get_table_data_array_internal( get_map_soundtable(), name, column_names, true );
	}

	if ( data.size == 0 )
	{
		debug_println( "^2Looking in common soundtable for " + name );
		data = get_table_data_array_internal( get_common_soundtable(), name, column_names, true );
	}

	return data;
}

get_table_data_array( filename, name, column_names )
{
	array = [];
	if ( TableExists( get_map_soundtable() ) )
	{
		array = get_table_data_array_internal( get_map_soundtable(), name, column_names );
	}

	if ( array.size == 0 )
	{
		debug_println( "^2Looking in common soundtable for " + name );
		array = get_table_data_array_internal( get_common_soundtable(), name, column_names );
	}

	return array;
}

get_table_data_array_internal( filename, name, column_names, no_array )
{
	section_name = column_names[ 0 ];
	row = TableLookupRowNum( filename, 0, section_name );

	row_count = 0; // used for stopping loop
	array = [];

	if ( row < 0 )
	{
		return array;
	}

	prev_row_name = undefined;
	while ( 1 )
	{
		row++;

		row_name = TableLookUpByRow( filename, row, 0 );

		if ( row_name == "" )
		{
			row_count++;
			if ( row_count > 10 )
			{
				break;
			}

			continue;
		}

		row_count = 0;

		// We got to a new grouping after we found what we were looking for
		if ( IsDefined( prev_row_name ) && prev_row_name != row_name )
		{
			break;
		}

		if ( row_name != name )
		{
			continue;
		}

		if ( row_name == "END_OF_FILE" || in_new_section( section_name, row_name ) )
		{
			break;
		}

		prev_row_name = name;

		data = [];
		index = undefined;
		for ( i = 1; i < column_names.size; i++ )
		{
			value = TableLookupByRow( filename, row, i );
			data[ column_names[ i ] ] = value;
			
			// for building the array.
			if ( i == 1 )
			{
				index = value;
			}
		}

		if ( IsDefined( no_array ) )
		{
			return data;
		}

		array[ index ] = data;
	}
	
	return array;
}

in_new_section( current_section, row_name )
{
	sections = [ "zone_name", "whizby_name", "reverb_name", "mix_name", "filter_name", 
				 "occlusion_name", "timescale_name", "ambient_name", "ambient_event", "ambient_element", "adsr_name", "adsr_zone_player", "adsr_zone_npc" ];
	sections = array_remove( sections, current_section );

	foreach ( section in sections )
	{
		if ( section == row_name )
		{
			return true;
		}
	}

	return false;
}

read_in_table( filename, column_names )
{
	row = 0;
	row_count = 0; // used for stopping loop
	array = [];

	while ( 1 )
	{
		row++;

		row_name = TableLookUpByRow( filename, row, 0 );

		if ( row_name == "" )
		{
			row_count++;
			if ( row_count > 10 )
			{
				break;
			}

			continue;
		}

		row_count = 0;

		data = [];
		data[ column_names[ 0 ] ] = row_name;
		for ( i = 1; i < column_names.size; i++ )
		{
			value = TableLookupByRow( filename, row, i );
			data[ column_names[ i ] ] = value;
		}

		array[ row_name ] = data;
	}
	
	return array;
}

//---------------------------------------------------------
// Utility section
//---------------------------------------------------------

get_map_soundtable()
{
	return ( "soundtables/" + get_template_level() + ".csv" );
}

get_common_soundtable()
{
	return "soundtables/common.csv";
}

string_to_float( value )
{
	if ( value == "" )
	{
		return 0;
	}

	return float( value );
}

string_to_int( value )
{
	if ( value == "" )
	{
		return 0;
	}

	return int( value );
}

//---------------------------------------------------------
// Debug Section
//---------------------------------------------------------
round_to( val, mult )
{
	return ( int( val * mult ) / mult );
}

debug_println( msg, dvar_num )
{
/#
	if ( !IsDefined( dvar_num ) )
	{
		dvar_num = 1;
	}

	if ( debug_enabled() < 1 )
	{
		return;
	}

	println( "    ^5" + msg );
#/
}

debug_iprintln( msg )
{
/#
	if ( !debug_enabled() )
	{
		return;
	}

	iprintln( "^5" + msg );
#/
}

debug_enabled()
{
/#
	dvar = GetDvarInt( "debug_audio" );
	if ( dvar > 0 )
	{
		return dvar;
	}
#/
	
	return false;
}

debug_warning( msg )
{
	debug_println( "^2" + msg );
}

debug_error( msg )
{
	debug_println( "^3" + msg );
}

get_headroom_dvar()
{
	return GetDvarFloat( "debug_headroom" );
}

create_submix_hud()
{
/#
	while ( !IsDefined( level.uiParent ) )
	{
		wait(0.05);
	}
	
	level._audio.using_submix_hud = true;
	
	hud_data = spawnstruct();	
	hud_data.fontsize = 1.0;
	hud_data.value_x = 50;
	hud_data.label_x = 100;
	hud_data.y = 100;
	hud_data.label_color = (0.4, 0.9, 0.6);
	hud_data.value_color = (0.4, 0.6, 0.9);
	hud_data.volmod_color = (0.9, 0.4, 0.6);

	hud_data.number_color = (1.0, 1.0, 1.0);
	hud_data.spacing = 10;
	
	level._audio.submix_data = hud_data;
	
	new_submix_hud( "header", hud_data.label_x, hud_data.y, hud_data.label_color, "Submixes:", hud_data.fontsize );
		
//	update_volmod_submix_hud();
#/
}

destroy_submix_hud()
{
/#
	foreach ( submix_label, value in level._audio.submix_hud )
	{
		name = "submix_" + submix_label;
		remove_hud_text( name );
	}
	
	foreach ( submix_label, value in level._audio.volmod_submix_hud )
	{
		name = "volmod_submix_" + submix_label;
		remove_hud_text( name );
	}
	level._audio.submix_hud 		= [];
	level._audio.volmod_submix_hud 	= [];
	level._audio.using_submix_hud 	= false;
#/
}
	
new_volmod_hud( store_label, x, y, color, label, fontsize )
{
/#
	init_hud( "volmod_submix_" + store_label, x, y, color, label, fontsize );
	level._audio.volmod_submix_hud[ store_label ] = true;
#/
}	
	
new_submix_hud( store_label, x, y, color, label, fontsize )
{
/#
	init_hud( "submix_" + store_label, label, x, y, color, fontsize );
	level._audio.submix_hud[store_label] = true;
#/
}
	
delete_volmod_hud( store_label )
{
/#
	if ( IsDefined( level._audio.volmod_submix_hud[ store_label ] ) )
	{
		remove_hud_text( "volmod_submix_" + store_label );
		level._audio.volmod_submix_hud[store_label] = undefined;
	}
#/
}

create_zone_hud()
{
/#
	level._audio.debug_hud = true;
	
	fontsize = 1.0;
	value_x = 530;
	label_x = value_x - 75;
	y = 150;
	label_color = ( 0.4, 0.9, 0.6 );
	value_color = ( 0.4, 0.6, 0.9 );
	zone_color = ( 0.4, 0.9, 0.9 );
	number_color = (1.0, 1.0, 1.0);
	indent = 10; // sub-text from streamed ambience
	amp_indent = 30; // indents from label
	label_indent = amp_indent + 50; // indents from the amplitude
	zone_indent = 10;
	
	// ZONE
	init_hud( "zone", "Zone: ", label_x, y, label_color, fontsize);
	
	// STREAM
	y += 13;
	init_hud( "ambient", "Ambient Track: ", label_x  + zone_indent, y, zone_color, fontsize );

	// STREAM FROM
	y += 10;
	init_hud_percent( "ambient_from", "From: ", label_x  + zone_indent + indent, y, value_color, fontsize);

	// STREAM TO
	y += 10;
	
	init_hud_percent( "ambient_to", "To: ", label_x  + zone_indent + indent, y, value_color, fontsize);

	// DAMB
	y += 13;
	init_hud( "ambient_elem", "Ambient Event: ", label_x + zone_indent, y, zone_color, fontsize );

	// DAMB FROM
	y += 10;
	init_hud_percent( "ambient_elem_from", "From: ", label_x  + zone_indent + indent, y, value_color, fontsize);

	// DAMB TO
	y += 10;
	init_hud_percent( "ambient_elem_to", "To: ", label_x  + zone_indent + indent, y, value_color, fontsize);

	// MIX
	y += 13;
	init_hud( "mix", "Mix: ", label_x + zone_indent, y, zone_color, fontsize );
	
	// REVERB
	y += 13;
	init_hud( "reverb", "Reverb: ", label_x + zone_indent, y, zone_color, fontsize );

	// FILTER
	y += 13;
	init_hud( "filter", "Filter: ", label_x + zone_indent, y, zone_color, fontsize );
	
	// FILTER FROM
	y += 10;
	init_hud_percent( "filter_0", "0: ", label_x  + zone_indent + indent, y, value_color, fontsize);

	// FILTER TO
	y += 10;
	init_hud_percent( "filter_1", "1: ", label_x  + zone_indent + indent, y, value_color, fontsize);
	
	// OCCLUSION
	y += 13;
	init_hud( "occlusion", "Occlusion: ", label_x + zone_indent, y, zone_color, fontsize );

	// MUSIC
	y += 15;
	init_hud( "music", "Music: ", label_x, y, label_color, fontsize );
	
	// MUSIC SUBMIX
	y += 13;
	init_hud( "music_submix", "Music Submix: ", label_x + zone_indent, y, zone_color, fontsize );
	
	// DAMB ENTITY COUNTER
	y += 15;
	init_hud( "ambient_elem_count", "Ambient Element Count: ", label_x, y, label_color, fontsize );

//	set_hud_values();
#/
}

destroy_zone_hud()
{
/#
	if ( IsDefined( level._audio.huds ) )
	{
		foreach ( idx, hud in level._audio.huds )
		{
			if ( IsDefined( hud.percent_hud ) )
			{
				hud.percent_hud Destroy();
			}
			hud Destroy();
		}

		level._audio.huds = array_removeundefined( level._audio.huds );
		level._audio.debug_hud = false;
	}
#/
}

remove_hud_text( index )
{
	if ( !IsDefined( level._audio.huds[ index ] ) )
	{
		return;
	}

	level._audio.huds[ index ] Destroy();
	level._audio.huds = array_removeundefined( level._audio.huds );
}

debug_hud_disabled()
{
/#
	if ( getdvar( "loc_warnings", 0 ) == "1" )
		return true;
	if ( getdvarint( "debug_hud" ) )
		return true;
	return !IsDefined( level._audio.hud );
#/
}


debug_audio_hud()
{
/#
	while ( 1 )
	{
		wait( 0.5 );
//		check_debug_mix_dvar();
		check_zone_hud_dvar();
		check_submix_hud_dvar();
	}
#/
}

check_zone_hud_dvar()
{
/#
	dvar = GetDvarInt( "debug_audio" );
	if ( dvar > 0 )
	{
		if (!level._audio.debug_hud)
		{
			create_zone_hud();
		}
	}
	else if ( dvar == 0 )
	{
		if (level._audio.debug_hud)
		{
			destroy_zone_hud();
		}
	}
#/
}
	
check_submix_hud_dvar()
{
/#
	SetDvarIfUninitialized( "submix_hud", "0" );
	dvar = GetDvar( "submix_hud" );
	if ( dvar == "1")
	{
		if (!level._audio.using_submix_hud)
		{
			create_submix_hud();
		}				
	}
	else if ( dvar == "0" )
	{
		if (level._audio.using_submix_hud)
		{
			destroy_submix_hud();
		}
	}
#/
}

create_hud( index, label, value, x, y, color, fontsize )
{
/#
	if ( !IsDefined( fontsize ) )
	{
		fontsize = 2;
	}
			
	hud = NewHudElem();
	hud.fontscale = fontsize;
	hud.x = x;
	hud.y = y;
	hud.horzAlign = "fullscreen";
	hud.vertAlign = "fullscreen";
	hud.sort = 1;
	hud.alpha = 1.0;

	if ( IsDefined( label ) )
	{
		hud.label = label;
	}

	if ( !IsDefined( color ) )
	{
		color = ( 1, 1, 1 );
	}

	hud.color = color;

	return hud;
#/
}

init_hud( index, label, x, y, color, fontsize )
{
/#
	hud = init_hud_internal( index, label, x, y, color, fontsize );
#/
}

init_hud_internal( index, label, x, y, color, fontsize )
{
/#
	if ( !IsDefined( level._audio.huds ) )
	{
		level._audio.huds = [];

		if ( !IsDefined( level._audio.huds_values ) )
		{
			level._audio.huds_values = [];
		}
	}	

	if ( !IsDefined( level._audio.huds[ index ] ) )
	{
		hud = create_hud( index, label, "", x, y, color, fontsize );
		level._audio.huds[ index ] = hud;
	}
	else
	{
		hud = level._audio.huds[ index ];
	}

	value = undefined;
	if ( IsDefined( level._audio.huds_values[ index ] ) )
	{
		value = level._audio.huds_values[ index ];
	}

	set_hud_value( index, value );

	return hud;
#/
}

init_hud_percent( index, label, x, y, color, fontsize )
{
/#
	hud = init_hud_internal( index, label, x, y, color, fontsize );

	if ( !IsDefined( hud.percent_hud ) )
	{
		hud.percent_hud = create_hud( index + "_percent", "", "", x + 100, y, color, fontsize );
	}

	value = undefined;
	if ( IsDefined( level._audio.huds_values[ index + "_percent" ] ) )
	{
		value = level._audio.huds_values[ index + "_percent" ];
	}

	set_hud_percent_value( index, value );
#/
}

set_hud_value( index, value )
{
/#
	if ( !IsDefined( level._audio.huds_values ) )
	{
		level._audio.huds_values = [];
	}

	if ( !IsDefined( value ) )
	{
		value = "";
	}

	level._audio.huds_values[ index ] = "" + value;

	if ( !IsDefined( level._audio.huds ) || !IsDefined( level._audio.huds[ index ] ) )
	{
		return;
	}

	hud = level._audio.huds[ index ];
	hud set_hud_value_internal( value );
#/
}

set_hud_percent_value( index, value )
{
/#
	if ( !IsDefined( level._audio.huds_values ) )
	{
		level._audio.huds_values = [];
	}

	level._audio.huds_values[ index + "_percent" ] = value;

	if ( !IsDefined( level._audio.huds ) || !IsDefined( level._audio.huds[ index ] ) )
	{
		return;
	}

	hud = level._audio.huds[ index ];
	hud.percent_hud set_hud_value_internal( value );
#/
}

set_hud_value_internal( value )
{
/#
	if ( !IsDefined( value ) )
	{
		value = "";
	}

	if ( IsDefined( self.value ) )
	{
		temp = "" + value;
		temp2 = "" + self.value;
		if ( temp2 == temp )
		{
			return;
		}
	}

	self.value = value;

	if ( IsString( value ) )
	{
		self SetText( value );
	}
	else
	{
		value = round_to( value, 100 );	
		self SetValue( value );
	}
#/
}

set_hud_name_percent_value( index, name, value )
{
/#
	if ( !IsDefined( name ) )
		name = "";
		
	if ( !IsDefined( value ) || name == "" )
		value = "";
	
	set_hud_value( index, name );

	if ( IsString( value ) && value == "last" )
	{
		return;
	}
	
	set_hud_percent_value( index, value );
#/
}
