#include common_scripts\utility;
#include maps\_utility;
#include maps\_utility_code;
#include maps\_audio;
#include maps\_audio_code;

init_ambient()
{
	if ( IsDefined( level._audio.ambient ) )
	{
		return;
	}
	
	level._audio.ambient = SpawnStruct();
	level._audio.ambient.thread_active = false;

	level._audio.ambient.current_zone = "";
	
	level._audio.ambient.current = [];
	level._audio.ambient.current[ "zone" ] = [];

	level._audio.ambient.elem_weights = [];
	
	level._audio.ambient.cached_ambients = [];
	level._audio.ambient.cached_elems = [];

	level._audio.ambient.max_sound_ents = 15;
	level._audio.ambient.sound_ents = [];

	// Debug
/#
	level._audio.ambient.sound_ents_count = 0;
#/
}

//---------------------------------------------------------
// start Section
//---------------------------------------------------------

start_ambient_event_zone( event_name )
{
	start_ambient_event_internal( "zone", event_name );
}

start_ambient_event_internal( type, name, coord, dist, max_dist_fade )
{
	cache_ambient( name );

	if ( !IsDefined( level._audio.ambient.cached_ambients[ name ] ) )
	{
		return;
	}

//		add_ambient_event( type, name, event );
	level._audio.ambient.current_zone = name;

	if ( !level._audio.ambient.thread_active )
	{
		level thread ambient_event_thread();
	}
}

//---------------------------------------------------------
// Stop Section
//---------------------------------------------------------
stop_ambient_event_zone( name, fade )
{
	if ( name == "" )
	{
		return;
	}

	if ( level._audio.ambient.current_zone == name )
	{
		level._audio.ambient.current_zone = "";
		fade_ambient_elems( name, fade );
	}
}

stop_current_ambient()
{
	if ( level._audio.ambient.current_zone == "" )
	{
		return;
	}

	stop_ambient_event_zone( level._audio.ambient.current_zone );
}

stop_all_ambient_events()
{
	// TODO: When we get "scripted" or "free" zones working, then we need to stop those here as well
	stop_ambient_event_zone( level._audio.ambient.current_zone );
}

fade_ambient_elems( name, fade )
{
	if ( !IsDefined( fade ) )
	{
		fade = 1;
	}

	foreach ( ent in level._audio.ambient.sound_ents )
	{
		if ( !IsDefined( ent.ambient ) || ent.ambient != name )
		{
			continue;
		}

		ent thread fade_ambient_elem_internal( fade );
	}
}

fade_ambient_elem_internal( fade )
{
	if ( IsDefined( self.fading ) )
	{
		return;
	}
	
	self endon( "sounddone" );
	self.fading = true;
	self thread fade_ambient_elem_reset();
	self ScaleVolume( 0.0, fade );
	wait( fade );
	self StopSounds();
	self notify( "sounddone" );
}

fade_ambient_elem_reset()
{
	self waittill( "sounddone" );
	self ScaleVolume( 1 );
	self.fading = undefined;
}

//---------------------------------------------------------
// Swap Section -- handles mixing between zone
//---------------------------------------------------------
swap_ambient_event_zones( name1, prob1, name2, prob2 )
{
	swap_ambient_event_zone_internal( name1, prob1 );
	swap_ambient_event_zone_internal( name2, prob2 );

/# 
	// Debug hud stuff
	from = "";
	to = "";
	method = "";
	percent1 = "";
	percent2 = "";

	if ( IsDefined( name1 ) && IsDefined( name2 ) )
	{
		if ( prob1 != 0 && prob2 == 0 )
		{
			method = name1;
		}
		else if ( prob1 == 0 && prob2 != 0 )
		{
			method = name2;
		}
		else if ( prob1 != 0 && prob2 != 0 )
		{
			percent1 = prob1;
			percent2 = prob2;
			from = name1;
			to = name2;
			method = "blending";	
		}
		
	}
	else if ( IsDefined( name1 ) )
	{
		if ( prob1 == 1 )
		{
			method = name1;
		}
		else if ( prob1 > 0 )
		{
			from = name1;
			percent1 = prob1;
			method = "progress";
		}
	}
	else if ( IsDefined( name2 ) )
	{
		if ( prob2 == 1 )
		{
			method = name2;
		}
		else if ( prob1 > 0 )
		{
			to = name2;
			percent2 = prob2;
			method = "progress";
		}
	}

	if ( method == "none" )
		method = "";

	if ( from == "none" )
		from = "";

	if ( to == "none" )
		to = "";

	set_hud_value( "ambient_elem", method );
	set_hud_name_percent_value( "ambient_elem_from", from, percent1 );
	set_hud_name_percent_value( "ambient_elem_to", to, percent2 );
#/
}

swap_ambient_event_zone_internal( name, prob )
{
	if ( IsDefined( name ) && name != "" && name != "none" )
	{
		if ( prob == 0 )
		{
			stop_ambient_event_zone( name );
		}
		else
		{
			start_ambient_event_zone( name );
		}
	}
}

//---------------------------------------------------------
// Play/Thread Section
//---------------------------------------------------------
ambient_event_thread()
{
	level endon( "stop_ambient_event_thread" );

	last_played = "";
	level._audio.ambient.thread_active = true;
	while ( true )
	{
		time = GetTime();

		// Zone - only 1 zone should be active
		if ( level._audio.ambient.current_zone != "" )
		{
			name = level._audio.ambient.current_zone;
			ambient = level._audio.ambient.cached_ambients[ name ];

			//TODO: Support "free" (scripted) ambients

			if ( IsDefined( ambient.serialized ) )
			{
				if ( !IsDefined( ambient.next_play_time ) )
				{
					ambient set_next_play_time( true );
				}

				if ( ambient.next_play_time <= time )
				{
					if ( ambient.events.size > 1 )
					{
						event = ambient get_random_event();
						while ( event.elem == last_played )
						{
							wait( 0.05 );
							event = ambient get_random_event();
						}
					}
					else
					{
						event = ambient.events[ 0 ];
					}
	
					play_ambient_elem( event, name );

					// make sure the current_zone is valid before getting data from it - in set_next_play_time.
					if ( level._audio.ambient.current_zone != "" )
					{
						last_played = event.elem;
						ambient set_next_play_time( true );
					}
				}
			}
			else
			{
				foreach ( event in ambient.events )
				{
					if ( !IsDefined( event.next_play_time ) )
					{
						event set_next_play_time();						
					}

					if ( event.next_play_time <= time )
					{
						level thread play_ambient_elem( event, name );
						event set_next_play_time();
					}
				}
			}
		}

		wait( 0.05 );
	}
}

stop_ambient_event_thread()
{
	level notify( "stop_ambient_event_thread" );
	level._audio.ambient.thread_active = false;
}

play_ambient_elem( event, ambient_name )
{
	elem = level._audio.ambient.cached_elems[ event.elem ];
	play_ambient_elem_oneshot( elem, ambient_name );
}

play_ambient_elem_oneshot( elem, ambient_name )
{
	alias = elem[ "alias" ];
	ent = get_sound_ent();

	if ( !IsDefined( ent ) )
	{
		debug_println( "^3play_ambient_elem_oneshot cannot play, out of sound ents" );
		return;
	}

	debug_println( "play_ambient_elem_oneshot -- ambient: \"" + ambient_name + "\" alias: \"" + alias + "\"" ); 

	ent.ambient = ambient_name;
	ent.is_playing = true;

	pos = get_elem_position( elem );

	// Keep the level.player.origin here, in case we want it to be specops friendly later
	ent.origin = pos + level.player.origin;

	/#
	level._audio.ambient.sound_ents_count++;
	set_hud_value( "ambient_elem_count", level._audio.ambient.sound_ents_count );
	#/
	
	ent PlaySound( alias, "sounddone" );
	ent waittill( "sounddone" );

	/#
	level._audio.ambient.sound_ents_count--;
	set_hud_value( "ambient_elem_count", level._audio.ambient.sound_ents_count );
	#/

	// wait for sounddone to be removed compeletely
	// bug in prague port to iw6 where in the same frame this got called again after the sounddone notify
	// odd thing, even 0.05 doesn't work. Code should fix this!
	wait( 0.1 );
	ent.ambient = undefined;
	ent.is_playing = false;
}

get_elem_position( elem )
{
	range = RandomFloatRange( elem[ "range" ][ 0 ], elem[ "range" ][ 1 ] );
	
	yaw = undefined;
	if ( IsDefined( elem[ "cone" ] ) )
	{
		yaw = RandomFloatRange( elem[ "cone" ][ 0 ], elem[ "cone" ][ 1 ] );
	}
	else
	{
		yaw = RandomFloatRange( 0, 360 );
	}

	pos = ( AnglesToForward( ( 0, yaw, 0 ) ) ) * range;
	return ( pos[ 0 ], pos[ 1 ], 0 );
}

set_next_play_time( is_serialized )
{
	if ( IsDefined( is_serialized ) )
	{
			data = level._audio.ambient.cached_ambients[ level._audio.ambient.current_zone ].data;
	}
	else
	{
			data = level._audio.ambient.cached_elems[ self.elem ];
	}
	
	time = 	RandomFloatRange( data[ "time" ][ 0 ], data[ "time" ][ 1 ] );
	self.next_play_time = GetTime() + ( time * 1000 );
}

get_random_event()
{
	total_weight = 0;

	foreach ( e in self.events )
	{
		total_weight += e.weight;
	}

	random_weight = RandomFloat( total_weight );
	weight = 0;

	elem = undefined;
	foreach ( e in self.events )
	{
		weight += e.weight;
		if ( random_weight < weight )
		{
			elem = e;
			break;
		}
	}

	return elem;
}

get_sound_ent()
{
	foreach ( ent in level._audio.ambient.sound_ents )
	{
		if ( !ent.is_playing )
		{
			return ent;
		}
	}

	if ( level._audio.ambient.sound_ents.size < level._audio.ambient.max_sound_ents )
	{
		ent = Spawn( "script_origin", ( 0, 0, 0 ) );
		ent.is_playing = false;

		level._audio.ambient.sound_ents[ level._audio.ambient.sound_ents.size ] = ent;

		return ent;
	}

	return undefined;
}