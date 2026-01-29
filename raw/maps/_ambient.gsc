#include maps\_audio;
//#include maps\_audio_reverb;


/*
=============
///ScriptDocBegin
"Name: use_eq_settings( <presetname> , <eqIndex> )"
"Summary: Enable EQ track settings on one of the two EQ indices."
"Module: Ambience"
"MandatoryArg: <presetname>: The EQ preset from either soundtables/common_filter.csv or soundtables/LEVELNAME_filter.csv"
"MandatoryArg: <eqIndex>: You must select either the main track or the mix track, preferably using level.eq_main_track or level.eq_mix_track. See ::blend_to_eq_track."
"Example: thread maps\_ambient::use_eq_settings( "gulag_cavein", level.eq_mix_track );"
"SPMP: singleplayer"
///ScriptDocEnd
=============
*/
use_eq_settings( name, index )
{
	assertEx( IsString( name ), "use_eq_settings: requires a presetname." );
	assertEx( IsDefined( index ), "use_eq_settings: requires an eqIndex parameter." );
	
	// red flashing overwrites eq
	if ( level.player maps\_utility::ent_flag( "player_has_red_flashing_overlay" ) )
		return;	
	
	set_filter( name, index );
		
}

deactivate_index( eqIndex )
{
	assert(IsDefined(eqIndex));
	
	level.eq_track[ eqIndex ] = "";
	level.player Deactivateeq( eqIndex );
}

/*
=============
///ScriptDocBegin
"Name: blend_to_eq_track( <eqIndex> , <time> )"
"Summary: Blends from one EQ track to another. NOTE that when you play this command, it will blend from zero to 100% on the track you select. If you were already on this track, this may sound weird."
"Module: Ambience"
"MandatoryArg: <eqIndex>: Which of the two EQ tracks to blend to, main or mix (level.eq_main_track, level.eq_mix_track)"
"OptionalArg: <time>: How much time to blend over. (defaults: 1.0 sec)"
"Example: thread maps\_ambient::blend_to_eq_track( level.eq_mix_track, 2 );"
"SPMP: singleplayer"
///ScriptDocEnd
=============
*/
blend_to_eq_track( eqIndex, time_ )
{
	assertEx(IsDefined(eqIndex), "blend_to_eq_track requires an eqIndex.");
	
	time = 1.0;
	if (IsDefined(time_))
		time = time_;

	interval = .05;
	count = time / interval;
	fraction = 1 / count;
	
	for ( i = 0; i <= 1; i += fraction )
	{
		level.player SetEqLerp( i, eqIndex );
		wait( interval );
	}
	
	level.player SetEqLerp( 1, eqIndex );
}
