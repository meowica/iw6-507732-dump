#include common_scripts\utility;
#include maps\_utility;
#include maps\_vehicle;
#include maps\_hud_util;

/*QUAKED trigger_multiple_fx_volume (1.0 0.5 0.0) ? AI_AXIS AI_ALLIES AI_NEUTRAL NOTPLAYER VEHICLE TRIGGER_SPAWN TOUCH_ONCE
an fx volume gets asigned an array of createfx ents at load time.  this can be used for whatever.

target to a trigger_multiple_fx_volume_on / trigger_multiple_fx_volume_off  turn on and off this volumes effects.

defaulttexture="trigger"
*/
/*QUAKED trigger_multiple_fx_volume_on (1.0 0.5 0.0) ? AI_AXIS AI_ALLIES AI_NEUTRAL NOTPLAYER VEHICLE TRIGGER_SPAWN TOUCH_ONCE
turns on the effects in the trigger_multiple_fx_volume that targets this.
defaulttexture="trigger"
*/
/*QUAKED trigger_multiple_fx_volume_off (1.0 0.5 0.0) ? AI_AXIS AI_ALLIES AI_NEUTRAL NOTPLAYER VEHICLE TRIGGER_SPAWN TOUCH_ONCE
turns off the effects in the trigger_multiple_fx_volume that targets this.
defaulttexture="trigger"
*/

/*QUAKED trigger_multiple_spawn (1.0 0.5 0.0) ? AI_AXIS AI_ALLIES AI_NEUTRAL NOTPLAYER VEHICLE TRIGGER_SPAWN TOUCH_ONCE
defaulttexture="spawner_trigger"
Spawns whatever is targetted. Currently supports AI.*/

/*QUAKED trigger_multiple_spawn_reinforcement (0.12 0.23 1.0) ? AI_AXIS AI_ALLIES AI_NEUTRAL NOTPLAYER VEHICLE TRIGGER_SPAWN TOUCH_ONCE
defaulttexture="spawner_trigger"
Spawns whatever is targetted. When the targeted AI dies a reinforcement spawner will be spawned if the spawner targets another spawner. Currently supports AI.*/

/*QUAKED trigger_use_flag_set (0.12 0.23 1.0) ? AI_AXIS AI_ALLIES AI_NEUTRAL NOTPLAYER VEHICLE TRIGGER_SPAWN TOUCH_ONCE
defaulttexture="flag"
Sets the script_flag when triggered. The entity that triggered it is passed with the level notify and to the flag_wait.*/

/*QUAKED trigger_use_flag_clear (0.12 0.23 1.0) ? AI_AXIS AI_ALLIES AI_NEUTRAL NOTPLAYER VEHICLE TRIGGER_SPAWN TOUCH_ONCE
defaulttexture="flag"
Sets the script_flag when triggered. The entity that triggered it is passed with the level notify and to the flag_wait.*/

/*QUAKED trigger_damage_doradius_damage (0.12 0.23 1.0) ? PISTOL_NO RIFLE_NO PROJ_NO EXPLOSION_NO SPLASH_NO MELEE_NO
defaulttexture="trigger"
Wait for trigger then do lots of damage at target spot. */

/*QUAKED trigger_multiple_doradius_damage (0.12 0.23 1.0) ? AI_AXIS AI_ALLIES AI_NEUTRAL NOTPLAYER VEHICLE TRIGGER_SPAWN
defaulttexture="trigger"
Wait for trigger then do lots of damage at target spot. */

/*QUAKED trigger_damage_player_flag_set (0.12 0.23 1.0) ? PISTOL_NO RIFLE_NO PROJ_NO EXPLOSION_NO SPLASH_NO MELEE_NO
defaulttexture="flag"
Sets the script_flag when player does damage to the trigger. */

/*QUAKED trigger_multiple_nobloodpool (0.12 0.23 1.0) ? AI_AXIS AI_ALLIES AI_NEUTRAL NOTPLAYER VEHICLE TRIGGER_SPAWN
defaulttexture="trigger_nobloodpool"
When triggered the touching character will no longer spawn blood pools on death. When the character leaves the trigger the blood pool will be re-enabled after a short delay. */

/*QUAKED trigger_multiple_flag_set (0.12 0.23 1.0) ? AI_AXIS AI_ALLIES AI_NEUTRAL NOTPLAYER VEHICLE TRIGGER_SPAWN TOUCH_ONCE
defaulttexture="flag"
Sets the script_flag when triggered. The entity that triggered it is passed with the level notify and to the flag_wait.*/

/*QUAKED trigger_multiple_flag_clear (0.12 0.23 1.0) ? AI_AXIS AI_ALLIES AI_NEUTRAL NOTPLAYER VEHICLE TRIGGER_SPAWN TOUCH_ONCE
defaulttexture="flag"
Clears the script_flag when triggered.*/

/*QUAKED trigger_multiple_flag_set_touching (0.12 0.23 1.0) ? AI_AXIS AI_ALLIES AI_NEUTRAL NOTPLAYER VEHICLE TRIGGER_SPAWN TOUCH_ONCE
defaulttexture="flag"
Sets the script_flag when touched and then clears the flag when no longer touched.*/

/*QUAKED trigger_multiple_flag_lookat (0.12 0.23 1.0) ? AI_AXIS AI_ALLIES AI_NEUTRAL NOTPLAYER VEHICLE TRIGGER_SPAWN TOUCH_ONCE
defaulttexture="flag"
The trigger targets a script origin. When the trigger is touched and a player looks at the origin, the script_flag gets set. If there is no script_flag then any triggers targetted by the trigger_multiple_lookat get triggered. Change SCRIPT_DOT to change required dot product*/

/*QUAKED trigger_multiple_flag_looking (0.12 0.23 1.0) ? AI_AXIS AI_ALLIES AI_NEUTRAL NOTPLAYER VEHICLE TRIGGER_SPAWN TOUCH_ONCE
The trigger targets a script origin. When the trigger is touched and a player looks at the origin, the script_flag gets set. Change SCRIPT_DOT to change required dot product.

When the player looks away from the script origin, the script_flag is cleared.

If there is no script_flag then any triggers targetted by the trigger_multiple_lookat get triggered.
defaulttexture="flag"
*/

/*QUAKED trigger_multiple_no_prone (0.12 0.23 1.0) ? AI_AXIS AI_ALLIES AI_NEUTRAL  ? ? ? TOUCH_ONCE
defaulttexture="trigger_no_prone"
*/

/*QUAKED trigger_multiple_no_crouch_or_prone (0.12 0.23 1.0) ? AI_AXIS AI_ALLIES AI_NEUTRAL  ? ? ? TOUCH_ONCE
defaulttexture="trigger_no_crouch_or_prone"
*/


/*QUAKED trigger_multiple_autosave (1.0 0.23 1.0) ? AI_AXIS AI_ALLIES AI_NEUTRAL NOTPLAYER VEHICLE TRIGGER_SPAWN TOUCH_ONCE
Autosaves when the trigger is hit.

defaulttexture="autosave"
*/

/*QUAKED trigger_multiple_physics ( 0.0 0.63 1.0) ? AI_AXIS AI_ALLIES AI_NEUTRAL NOTPLAYER VEHICLE TRIGGER_SPAWN TOUCH_ONCE

Activate a physics jolt at a specified origin.
Use script_parameters to set amount of jolt.

defaulttexture="trigger"
*/

/*QUAKED trigger_multiple_visionset (1.0 0.23 1.0) ? AI_AXIS AI_ALLIES AI_NEUTRAL VEHICLE TRIGGER_SPAWN TOUCH_ONCE
Changes vision set to script_visionset. 

For Timed transition:
"script_visionset" - name that will be on the menu [Requires script_delay to be set]
"script_delay" - specifies how long to spend on the transition.

For Progressional Visionset Transition:
This trigger must target 1 script_struct which targets another. This will determine the start and end points the player must travel through.
"script_visionset_start" - specfies the start vision set
"script_visionset_end" - specfies the end vision set

Exporting from CreateArt sets up the script for you ( updating the fog too ).

default:"script_delay" "5"
defaulttexture="trigger_environment"
*/

/*QUAKED trigger_multiple_sunflare (1.0 0.23 1.0) ? AI_AXIS AI_ALLIES AI_NEUTRAL VEHICLE TRIGGER_SPAWN TOUCH_ONCE
Changes sunflare setting to script_visionset.
"script_visionset" IS NOT related to vision sets in game

For Timed transition:
"script_visionset" - name that will be on the menu [Requires script_delay to be set]
"script_delay" - specifies how long to spend on the transition.

Exporting from CreateArt sets up the script for you ( updating the fog too ).

default:"script_delay" "5"
defaulttexture="trigger_environment"
*/

/*QUAKED trigger_multiple_slide (1.0 0.23 1.0) ?
Forces the player to slide.


defaulttexture="trigger"
*/

/*QUAKED trigger_multiple_fog (1.0 0.23 1.0) ?
Fog transition trigger.

script_fogset_start="example_start_fog"
script_fogset_end="example_end_fog"
"example_start_fog" is made from maps\_utility::create_fog("example_start_fog")

Trigger must target a script_origin to define the entry side,
this script_origin can target another optional script_origin to define exit side.

See also trigger_multiple_visionset ( sets fog and vision together )

defaulttexture="trigger"
*/

/*QUAKED trigger_multiple_depthoffield (1.0 0.23 1.0) ?
Depth of field transition trigger.

"script_dof_near_start" - specifies the start of the near range
"script_dof_near_end" - specifies the end of the near range
"script_dof_near_blur" - specifies the blur factor of the near range
"script_dof_far_start" - specifies the start of the far range
"script_dof_far_end" - specifies the end of the far range
"script_dof_far_blur" - specifies the blur factor of the far range
"script_delay" - specifies how long to spend on the transition

default:"script_dof_near_start" "1"
default:"script_dof_near_end" "1"
default:"script_dof_near_blur" "4.5"
default:"script_dof_far_start" "500"
default:"script_dof_far_end" "500"
default:"script_dof_far_blur" ".05"
default:"script_delay" "1"
defaulttexture="trigger"
*/

/*QUAKED trigger_multiple_ambient (1.0 0.23 1.0) ? AI_AXIS AI_ALLIES AI_NEUTRAL NOTPLAYER VEHICLE TRIGGER_SPAWN TOUCH_ONCE
.ambient determines the ambience for the trigger. Can be two values, like "interior exterior" and it will blend between them.
For blending, needs a targetted origin to determine blend direction.

Current sets are:
ac130
alley
bunker
city
container
exterior
exterior1
exterior2
exterior3
exterior4
exterior5
forrest
hangar
interior
interior_metal
interior_stone
interior_vehicle
interior_wood
mountains
pipe
shanty
snow_base
snow_cliff
tunnel
underpass

defaulttexture="ambient"
*/

/*QUAKED trigger_radius_glass_break (0 0.25 0.5) (-16 -16 -16) (16 16 16) ? AI_AXIS AI_ALLIES AI_NEUTRAL NOTPLAYER VEHICLE
Target to a func_glass. When an entity touching this trigger sends a level notify of "glass_break", the func_glass targeted by this trigger will break.
*/

/*QUAKED trigger_multiple_glass_break (0 0.25 0.5) ? AI_AXIS AI_ALLIES AI_NEUTRAL NOTPLAYER VEHICLE
Target to a func_glass. When an entity touching this trigger sends a level notify of "glass_break", the func_glass targeted by this trigger will break.

defaulttexture="trigger"
*/

/*QUAKED trigger_multiple_friendly_respawn (0 1 0.25) ? AI_AXIS AI_ALLIES AI_NEUTRAL NOTPLAYER VEHICLE TRIGGER_SPAWN TOUCH_ONCE
Target a script origin. Replacement friendlies will spawn from the origin.

defaulttexture="aitrig"
*/

/*QUAKED trigger_multiple_friendly_stop_respawn (0.25 1 0.25) ? AI_AXIS AI_ALLIES AI_NEUTRAL NOTPLAYER VEHICLE TRIGGER_SPAWN TOUCH_ONCE
Stops friendly respawning.

defaulttexture="aitrig"
*/

/*QUAKED trigger_multiple_friendly (0 1.0 0.0) ? AI_AXIS AI_ALLIES AI_NEUTRAL NOTPLAYER VEHICLE TRIGGER_SPAWN TOUCH_ONCE
Assign color codes to this trigger to control friendlies.

defaulttexture="aitrig"
*/

/*QUAKED trigger_multiple_compass (0.2 0.9 0.7) ? AI_AXIS AI_ALLIES AI_NEUTRAL NOTPLAYER VEHICLE TRIGGER_SPAWN TOUCH_ONCE
Activates the compass map set in its script_parameters.

defaulttexture="trigger"
*/

/*QUAKED trigger_multiple_specialops_flag_set (0.12 0.23 1.0) ? AI_AXIS AI_ALLIES AI_NEUTRAL NOTPLAYER VEHICLE TRIGGER_SPAWN TOUCH_ONCE
defaulttexture="flag"
Sets the script_flag after being triggered by all player in a specialops map. The last entity that triggered it is passed with the level notify and to the flag_wait.*/

/*QUAKED trigger_multiple_sun_off (0.12 0.23 1.0) ?
defaulttexture="trigger"
sets sm_sunenable to 0
Use with trigger_multiple_sun_off in caves to enable/disable the sun for more primary lighte`
*/

/*QUAKED trigger_multiple_sun_on (0.12 0.23 1.0) ?
defaulttexture="trigger"
sets sm_sunenable to 1
Use In caves where you can't see the sun and wish to gain an extra Primary light
*/

/*QUAKED trigger_createart_transient (1.0 0.23 1.0) ?
defaulttexture="trigger_transient_createart"
For CreateArt and CreateFX to work with transients files. 
When the player is in this volume, it will unload all transients and load in the given transient.
script_transient - the name of the transient file
*/




get_load_trigger_classes()
{
	trigger_classes = [];
	trigger_classes[ "trigger_multiple_nobloodpool" ] = ::trigger_nobloodpool;
	trigger_classes[ "trigger_multiple_flag_set" ] = ::trigger_flag_set;
	trigger_classes[ "trigger_multiple_flag_clear" ] = ::trigger_flag_clear;
	trigger_classes[ "trigger_multiple_sun_off" ] = ::trigger_sun_off;
	trigger_classes[ "trigger_multiple_sun_on" ] = ::trigger_sun_on;
	trigger_classes[ "trigger_use_flag_set" ] = ::trigger_flag_set;
	trigger_classes[ "trigger_use_flag_clear" ] = ::trigger_flag_clear;
	trigger_classes[ "trigger_multiple_flag_set_touching" ] = ::trigger_flag_set_touching;
	trigger_classes[ "trigger_multiple_flag_lookat" ] = ::trigger_lookat;
	trigger_classes[ "trigger_multiple_flag_looking" ] = ::trigger_looking;
	trigger_classes[ "trigger_multiple_no_prone" ] = ::trigger_no_prone;
	trigger_classes[ "trigger_multiple_no_crouch_or_prone" ] = ::trigger_no_crouch_or_prone;
	trigger_classes[ "trigger_multiple_compass" ] = ::trigger_multiple_compass;
	trigger_classes[ "trigger_multiple_specialops_flag_set" ] = ::trigger_flag_set_specialops;
	trigger_classes[ "trigger_multiple_fx_volume" ] = ::trigger_multiple_fx_volume;
	trigger_classes[ "trigger_multiple_light_sunshadow" ] = maps\_lights::sun_shadow_trigger;
	

	if ( ! is_no_game_start() )
	{
		trigger_classes[ "trigger_multiple_autosave" ] = maps\_autosave::trigger_autosave;
		trigger_classes[ "trigger_multiple_spawn" ] = maps\_spawner::trigger_spawner;
		trigger_classes[ "trigger_multiple_spawn_reinforcement" ] = maps\_spawner::trigger_spawner_reinforcement;
	}

	trigger_classes[ "trigger_multiple_slide" ] = ::trigger_slide;
	trigger_classes[ "trigger_multiple_fog" ] = ::trigger_fog;
	trigger_classes[ "trigger_multiple_depthoffield" ] = ::trigger_multiple_depthoffield;

	trigger_classes[ "trigger_damage_player_flag_set" ] = ::trigger_damage_player_flag_set;
	trigger_classes[ "trigger_multiple_visionset" ] = ::trigger_multiple_visionset;
	trigger_classes[ "trigger_multiple_sunflare" ] = ::trigger_multiple_sunflare;
	trigger_classes[ "trigger_multiple_glass_break" ] = ::trigger_glass_break;
	trigger_classes[ "trigger_radius_glass_break" ] = ::trigger_glass_break;
	trigger_classes[ "trigger_multiple_friendly_respawn" ] = ::trigger_friendly_respawn;
	trigger_classes[ "trigger_multiple_friendly_stop_respawn" ] = ::trigger_friendly_stop_respawn;
	trigger_classes[ "trigger_multiple_physics" ] = ::trigger_physics;
	
	trigger_classes[ "trigger_multiple_fx_watersheeting" ] = ::trigger_multiple_fx_watersheeting;
	trigger_classes[ "trigger_multiple_audio" ] = maps\_audio::trigger_multiple_audio_trigger;
/#
	trigger_classes[ "trigger_createart_transient" ] = ::trigger_createart_transient;
#/

	return trigger_classes;
}

//Nate slop.. I'm moving this here because _fx.gsc is going away.

/*QUAKED trigger_multiple_fx_watersheeting (0.12 0.23 1.0) ? AI_AXIS AI_ALLIES AI_NEUTRAL NOTPLAYER VEHICLE TRIGGER_SPAWN TOUCH_ONCE
defaulttexture="trigger_fx"
Activates the water sheeting effect covering the screen.
Set script_duration to specify the duration. defaults to 3 seconds.
*/
trigger_multiple_fx_watersheeting( trigger )
{
	duration = 3;
	if ( isdefined( trigger.script_duration ) )
		duration = trigger.script_duration;

	while( true )
	{
		trigger waittill( "trigger", other );
		if ( IsPlayer( other ) )
		{
			other SetWaterSheeting( 1, duration );
			wait duration * 0.2;
		}
	}
}

get_load_trigger_funcs()
{

	trigger_funcs = [];
	trigger_funcs[ "friendly_wave" ] = maps\_spawner::friendly_wave;
	trigger_funcs[ "friendly_wave_off" ] = maps\_spawner::friendly_wave;
	trigger_funcs[ "friendly_mgTurret" ] = maps\_spawner::friendly_mgTurret;

	if (  ! is_no_game_start() )
	{
		trigger_funcs[ "camper_spawner" ] = maps\_spawner::camper_trigger_think;
		trigger_funcs[ "flood_spawner" ] = maps\_spawner::flood_trigger_think;
		trigger_funcs[ "trigger_spawner" ] = maps\_spawner::trigger_spawner;
		trigger_funcs[ "trigger_autosave" ] = maps\_autosave::trigger_autosave;
		trigger_funcs[ "trigger_spawngroup" ] = ::trigger_spawngroup;
		trigger_funcs[ "two_stage_spawner" ] = maps\_spawner::two_stage_spawner_think;
		trigger_funcs[ "trigger_vehicle_spline_spawn" ] = ::trigger_vehicle_spline_spawn;
		trigger_funcs[ "trigger_vehicle_spawn" ] = ::trigger_vehicle_spawn;
		trigger_funcs[ "trigger_vehicle_getin_spawn" ] = ::trigger_vehicle_getin_spawn;
		trigger_funcs[ "random_spawn" ] = maps\_spawner::random_spawn;
	}

	trigger_funcs[ "autosave_now" ] = maps\_autosave::autosave_now_trigger;
	trigger_funcs[ "trigger_autosave_tactical" ] = maps\_autosave::trigger_autosave_tactical;
	trigger_funcs[ "trigger_autosave_stealth" ] = maps\_autosave::trigger_autosave_stealth;
	trigger_funcs[ "trigger_unlock" ] = ::trigger_unlock;
	trigger_funcs[ "trigger_lookat" ] = ::trigger_lookat;
	trigger_funcs[ "trigger_looking" ] = ::trigger_looking;
	trigger_funcs[ "trigger_cansee" ] = ::trigger_cansee;
	trigger_funcs[ "autosave_immediate" ] = maps\_autosave::trigger_autosave_immediate;
	trigger_funcs[ "flag_set" ] = ::trigger_flag_set;
	if ( is_coop() )
		trigger_funcs[ "flag_set_coop" ] = ::trigger_flag_set_coop;
	trigger_funcs[ "flag_set_player" ] = ::trigger_flag_set_player;
	trigger_funcs[ "flag_unset" ] = ::trigger_flag_clear;
	trigger_funcs[ "flag_clear" ] = ::trigger_flag_clear;
	trigger_funcs[ "objective_event" ] = maps\_spawner::objective_event_init;
	trigger_funcs[ "friendly_respawn_trigger" ] = ::trigger_friendly_respawn;
	trigger_funcs[ "radio_trigger" ] = ::trigger_radio;
	trigger_funcs[ "trigger_ignore" ] = ::trigger_ignore;
	trigger_funcs[ "trigger_pacifist" ] = ::trigger_pacifist;
	trigger_funcs[ "trigger_delete" ] = ::trigger_turns_off;
	trigger_funcs[ "trigger_delete_on_touch" ] = ::trigger_delete_on_touch;
	trigger_funcs[ "trigger_off" ] = ::trigger_turns_off;
	trigger_funcs[ "trigger_outdoor" ] = maps\_spawner::outdoor_think;
	trigger_funcs[ "trigger_indoor" ] = maps\_spawner::indoor_think;
	trigger_funcs[ "trigger_hint" ] = ::trigger_hint;
	trigger_funcs[ "trigger_grenade_at_player" ] = ::trigger_throw_grenade_at_player;
	trigger_funcs[ "flag_on_cleared" ] = ::trigger_flag_on_cleared;
	trigger_funcs[ "flag_set_touching" ] = ::trigger_flag_set_touching;
	trigger_funcs[ "delete_link_chain" ] = ::trigger_delete_link_chain;
	trigger_funcs[ "trigger_fog" ] = ::trigger_fog;
	trigger_funcs[ "trigger_slide" ] = ::trigger_slide;
	trigger_funcs[ "trigger_dooropen" ] = ::trigger_dooropen;

	trigger_funcs[ "no_crouch_or_prone" ] = ::trigger_no_crouch_or_prone;
	trigger_funcs[ "no_prone" ] = ::trigger_no_prone;
	return trigger_funcs;
}

init_script_triggers()
{
	// run logic on these triggers from radiant
	trigger_classes = get_load_trigger_classes();
	trigger_funcs = get_load_trigger_funcs();


	foreach ( classname, function in trigger_classes )
	{
		triggers = GetEntArray( classname, "classname" );
		array_levelthread( triggers, function );
	}

	// old style targetname triggering

	// trigger_multiple and trigger_radius can have the trigger_spawn flag set
	trigger_multiple = GetEntArray( "trigger_multiple", "classname" );
	trigger_radius = GetEntArray( "trigger_radius", "classname" );
	triggers = array_merge( trigger_multiple, trigger_radius );
	trigger_disk = GetEntArray( "trigger_disk", "classname" );
	triggers = array_merge( triggers, trigger_disk );
	trigger_once = GetEntArray( "trigger_once", "classname" );
	triggers = array_merge( triggers, trigger_once );

	if ( ! is_no_game_start() )
	{
		for ( i = 0; i < triggers.size; i++ )
		{
			if ( triggers[ i ].spawnflags & 32 )
				thread maps\_spawner::trigger_spawner( triggers[ i ] );
		}
	}

	for ( p = 0; p < 7; p++ )
	{
		switch( p )
		{
			case 0:
				triggertype = "trigger_multiple";
				break;

			case 1:
				triggertype = "trigger_once";
				break;

			case 2:
				triggertype = "trigger_use";
				break;

			case 3:
				triggertype = "trigger_radius";
				break;

			case 4:
				triggertype = "trigger_lookat";
				break;

			case 5:
				triggertype = "trigger_disk";
				break;

			default:
				Assert( p == 6 );
				triggertype = "trigger_damage";
				break;
		}

		triggers = GetEntArray( triggertype, "code_classname" );

		for ( i = 0; i < triggers.size; i++ )
		{
			if ( IsDefined( triggers[ i ].script_flag_true ) )
				level thread trigger_script_flag_true( triggers[ i ] );

			if ( IsDefined( triggers[ i ].script_flag_false ) )
				level thread trigger_script_flag_false( triggers[ i ] );

			if ( IsDefined( triggers[ i ].script_autosavename ) || IsDefined( triggers[ i ].script_autosave ) )
				level thread maps\_autosave::autoSaveNameThink( triggers[ i ] );

			if ( IsDefined( triggers[ i ].script_fallback ) )
				level thread maps\_spawner::fallback_think( triggers[ i ] );

			if ( IsDefined( triggers[ i ].script_mgTurretauto ) )
				level thread maps\_mgturret::mgTurret_auto( triggers[ i ] );

			if ( IsDefined( triggers[ i ].script_killspawner ) )
				level thread maps\_spawner::kill_spawner( triggers[ i ] );

			if ( IsDefined( triggers[ i ].script_kill_vehicle_spawner ) )
				level thread maps\_vehicle_code::kill_vehicle_spawner( triggers[ i ] );

			if ( IsDefined( triggers[ i ].script_emptyspawner ) )
				level thread maps\_spawner::empty_spawner( triggers[ i ] );

			if ( IsDefined( triggers[ i ].script_prefab_exploder ) )
				triggers[ i ].script_exploder = triggers[ i ].script_prefab_exploder;

			if ( IsDefined( triggers[ i ].script_exploder ) )
				level thread maps\_load::exploder_load( triggers[ i ] );

			if ( IsDefined( triggers[ i ].ambient ) )
				level thread maps\_audio::trigger_multiple_audio_trigger( triggers[ i ] );

			if ( IsDefined( triggers[ i ].script_triggered_playerseek ) )
				level thread trigger_playerseek( triggers[ i ] );

			if ( IsDefined( triggers[ i ].script_bctrigger ) )
				level thread trigger_battlechatter( triggers[ i ] );

			if ( IsDefined( triggers[ i ].script_trigger_group ) )
				triggers[ i ] thread trigger_group();

			if ( IsDefined( triggers[ i ].script_random_killspawner ) )
				level thread maps\_spawner::random_killspawner( triggers[ i ] );

			if ( IsDefined( triggers[ i ].targetname ) )
			{
				// do targetname specific functions
				targetname = triggers[ i ].targetname;
				if ( IsDefined( trigger_funcs[ targetname ] ) )
				{
					level thread [[ trigger_funcs[ targetname ] ]]( triggers[ i ] );
				}
			}
		}
	}
}

trigger_createart_transient( trigger )
{
	delete_trigger = true;
/#
	delete_trigger = false;
	AssertEx( IsDefined( trigger.script_transient ), "Createart Transient Trigger at " + trigger.origin + " is missing script_transient." );

	if ( !IsDefined( level.createart_transients ) )
	{
		level.createart_transients = [];
	}
	
	level.createart_transients[ level.createart_transients.size ] = trigger;	
	level thread createart_transient_thread();
#/
	if ( delete_trigger )
	{
		trigger Delete();
	}
}

createart_transient_thread()
{
/#
	level notify( "createart_transient_thread" );
	level endon( "createart_transient_thread" );


	while ( GetDvarInt( "scr_art_tweak" ) == 0 && GetDvar( "createfx" ) == "" )
	{
		wait( 1 );
	}	
	
	current_trans = "";
	foreach ( key, trigger in level.createart_transients )
	{
		trans = trigger.script_transient;
		if ( flag( trans + "_loaded" ) )
		{
			current_trans = trans;
		}
	}
	
	new_trans = current_trans;
	while ( 1 )
	{
		wait( 1 );
		
		if ( GetDvarInt( "scr_art_tweak" ) == 0 && GetDvar( "createfx" ) == "" )
		{
			continue;
		}
		
		is_in_volume = true;
		
		foreach ( trigger in level.createart_transients )
		{
			if ( level.player IsTouching( trigger ) )
			{
				new_trans = trigger.script_transient;
				break;
			}
		}
		
		if ( current_trans != new_trans )
		{
			current_trans = new_trans;

			UnloadAllTransients();
			LoadTransient( new_trans );
			while ( !IsTransientLoaded( new_trans ) )
			{
				wait( 0.1 );
			}
		}
	}
#/
}

trigger_damage_player_flag_set( trigger )
{
	flag = trigger get_trigger_flag();

	if ( !isdefined( level.flag[ flag ] ) )
	{
		flag_init( flag );
	}

	for ( ;; )
	{
		trigger waittill( "trigger", other );
		if ( !isalive( other ) )
			continue;
		if ( !isplayer( other ) )
			continue;
		trigger script_delay();
		flag_set( flag, other );
	}
}

trigger_flag_clear( trigger )
{
	flag = trigger get_trigger_flag();

	if ( !isdefined( level.flag[ flag ] ) )
		flag_init( flag );
	for ( ;; )
	{
		trigger waittill( "trigger" );
		trigger script_delay();
		flag_clear( flag );
	}
}

trigger_flag_on_cleared( trigger )
{
	flag = trigger get_trigger_flag();

	if ( !isdefined( level.flag[ flag ] ) )
	{
		flag_init( flag );
	}

	for ( ;; )
	{
		trigger waittill( "trigger" );
		wait( 1 );
		if ( trigger found_toucher() )
		{
			continue;
		}

		break;
	}

	flag_set( flag );
}

found_toucher()
{
	ai = GetAIArray( "bad_guys" );
	for ( i = 0; i < ai.size; i++ )
	{
		guy = ai[ i ];
		if ( !isalive( guy ) )
		{
			continue;
		}

		if ( guy IsTouching( self ) )
		{
			return true;
		}

		// spread the touches out over time
		wait( 0.1 );
	}

	// couldnt find any touchers so do a single frame complete check just to make sure

	ai = GetAIArray( "bad_guys" );
	for ( i = 0; i < ai.size; i++ )
	{
		guy = ai[ i ];
		if ( guy IsTouching( self ) )
		{
			return true;
		}
	}

	return false;
}

trigger_flag_set( trigger )
{
	flag = trigger get_trigger_flag();

	if ( !isdefined( level.flag[ flag ] ) )
	{
		flag_init( flag );
	}

	for ( ;; )
	{
		trigger waittill( "trigger", other );
		trigger script_delay();
		flag_set( flag, other );
	}
}

trigger_flag_set_coop( trigger )
{
	AssertEx( is_coop(), "trigger_flag_set_coop() was called but co-op is not enabled." );
	flag = trigger get_trigger_flag();

	if ( !isdefined( level.flag[ flag ] ) )
	{
		flag_init( flag );
	}

	agents = [];

	for ( ;; )
	{
		trigger waittill( "trigger", user );

		if ( !isplayer( user ) )
			continue;

		add = [];
		add[ add.size ] = user;

		agents = array_merge( agents, add );

		if ( agents.size == level.players.size )
			break;
	}

	trigger script_delay();
	flag_set( flag );
}

trigger_flag_set_specialops( trigger )
{
	flag = trigger get_trigger_flag();

	if ( !isdefined( level.flag[ flag ] ) )
	{
		flag_init( flag );
	}

	trigger.player_touched_arr = level.players;
	trigger thread trigger_flag_set_specialops_clear( flag );

	for ( ;; )
	{
		trigger waittill( "trigger", other );

		trigger.player_touched_arr = array_remove( trigger.player_touched_arr, other );
		if ( trigger.player_touched_arr.size )
			continue;

		trigger script_delay();
		flag_set( flag, other );
	}
}

trigger_flag_set_specialops_clear( flag )
{
	// sets self.player_touched_arr when the flag is set or cleared from script.
	while ( true )
	{
		level waittill( flag );
		if ( flag( flag ) )
		{
			self.player_touched_arr = [];
		}
		else
		{
			self.player_touched_arr = level.players;
		}
	}
}

trigger_friendly_respawn( trigger )
{
	trigger endon( "death" );

	org = GetEnt( trigger.target, "targetname" );
	origin = undefined;
	if ( IsDefined( org ) )
	{
		origin = org.origin;
		org Delete();

	}
	else
	{
		org = getstruct( trigger.target, "targetname" );
		AssertEx( IsDefined( org ), "trigger_multiple_friendly_respawn doesn't target an origin." );
		origin = org.origin;
	}

	for ( ;; )
	{
		trigger waittill( "trigger" );
		level.respawn_spawner_org = origin;
		flag_set( "respawn_friendlies" );
		wait( 0.5 );
	}
}

trigger_flag_set_touching( trigger )
{
	flag = trigger get_trigger_flag();

	if ( !isdefined( level.flag[ flag ] ) )
	{
		flag_init( flag );
	}

	for ( ;; )
	{
		trigger waittill( "trigger", other );
		trigger script_delay();
		if ( IsAlive( other ) && other IsTouching( trigger ) && IsDefined( trigger ) )
			flag_set( flag );
		while ( IsAlive( other ) && other IsTouching( trigger ) && IsDefined( trigger ) )
		{
			wait( 0.25 );
		}
		flag_clear( flag );
	}
}


trigger_friendly_stop_respawn( trigger )
{
	for ( ;; )
	{
		trigger waittill( "trigger" );
		flag_clear( "respawn_friendlies" );
	}
}

trigger_group()
{
	self thread trigger_group_remove();

	level endon( "trigger_group_" + self.script_trigger_group );
	self waittill( "trigger" );
	level notify( "trigger_group_" + self.script_trigger_group, self );
}

trigger_group_remove()
{
	level waittill( "trigger_group_" + self.script_trigger_group, trigger );
	if ( self != trigger )
		self Delete();
}

trigger_nobloodpool( trigger )
{
	// Issue: If a guy dies and animates into the trigger, he will still spawn a blood pool.
	for ( ;; )
	{
		trigger waittill( "trigger", other );
		if ( !isalive( other ) )
			continue;

		other.skipBloodPool = true;
		other thread set_wait_then_clear_skipBloodPool();
	}
}

set_wait_then_clear_skipBloodPool()
{
	// Issue: If a guy dies during this timer even though he has left the trigger area, he will not spawn a pool. Deemed acceptable.
	self notify( "notify_wait_then_clear_skipBloodPool" );
	self endon( "notify_wait_then_clear_skipBloodPool" );
	self endon( "death" );

	wait 2;
	self.skipBloodPool = undefined;
}

trigger_physics( trigger )
{
	AssertEx( IsDefined( trigger.target ), "Trigger_physics at " + trigger.origin + " has no target for physics." );

	ents = [];

	structs = getstructarray( trigger.target, "targetname" );
	orgs = GetEntArray( trigger.target, "targetname" );

	foreach ( org in orgs )
	{
		// save ents by moving script origins to structs
		struct = SpawnStruct();
		struct.origin = org.origin;
		struct.script_parameters = org.script_parameters;
		struct.script_damage = org.script_damage;
		struct.radius = org.radius;
		structs[ structs.size ] = struct;
		org Delete();
	}

	AssertEx( structs.size, "Trigger_physics at " + trigger.origin + " has no target for physics." );

	trigger.org = structs[ 0 ].origin;
	trigger waittill( "trigger" );
	trigger script_delay();

	foreach ( struct in structs )
	{
		radius = struct.radius;
		vel = struct.script_parameters;
		damage = struct.script_damage;

		if ( !isdefined( radius ) )
			radius = 350;
		if ( !isdefined( vel ) )
			vel = 0.25;

		// convert string to float
		SetDvar( "tempdvar", vel );
		vel = GetDvarFloat( "tempdvar" );

		if ( IsDefined( damage ) )
		{
			RadiusDamage( struct.origin, radius, damage, damage * 0.5 );
		}
		PhysicsExplosionSphere( struct.origin, radius, radius * 0.5, vel );
	}
}

trigger_playerseek( trig )
{
	groupNum = trig.script_triggered_playerseek;
	trig waittill( "trigger" );

	ai = GetAIArray();
	for ( i = 0; i < ai.size; i++ )
	{
		if ( !isAlive( ai[ i ] ) )
			continue;
		if ( ( IsDefined( ai[ i ].script_triggered_playerseek ) ) && ( ai[ i ].script_triggered_playerseek == groupNum ) )
		{
			ai[ i ].goalradius = 800;
			ai[ i ] SetGoalEntity( level.player );
			level thread maps\_spawner::delayed_player_seek_think( ai[ i ] );
		}
	}
}

trigger_script_flag_false( trigger )
{
	// all of these flags must be false for the trigger to be enabled
	tokens = create_flags_and_return_tokens( trigger.script_flag_false );
	trigger add_tokens_to_trigger_flags( tokens );
	trigger update_trigger_based_on_flags();
}

trigger_script_flag_true( trigger )
{
	// all of these flags must be false for the trigger to be enabled
	tokens = create_flags_and_return_tokens( trigger.script_flag_true );
	trigger add_tokens_to_trigger_flags( tokens );
	trigger update_trigger_based_on_flags();
}

add_tokens_to_trigger_flags( tokens )
{
	for ( i = 0; i < tokens.size; i++ )
	{
		flag = tokens[ i ];
		if ( !isdefined( level.trigger_flags[ flag ] ) )
		{
			level.trigger_flags[ flag ] = [];
		}

		level.trigger_flags[ flag ][ level.trigger_flags[ flag ].size ] = self;
	}
}


trigger_spawngroup( trigger )
{
	waittillframeend;// so level.spawn_groups is defined

	AssertEx( IsDefined( trigger.script_spawngroup ), "spawngroup Trigger at " + trigger.origin + " has no script_spawngroup" );
	spawngroup = trigger.script_spawngroup;
	if ( !isdefined( level.spawn_groups[ spawngroup ] ) )
		return;

	trigger waittill( "trigger" );

	spawners = random( level.spawn_groups[ spawngroup ] );

	foreach ( _, spawner in spawners )
	{
		spawner spawn_ai();
	}
}

trigger_sun_off( trigger )
{
    for ( ;; )
	{
		trigger waittill( "trigger", other );
		if( GetDvarInt( "sm_sunenable" ) == 0 )
		    continue;
		SetSavedDvar( "sm_sunenable", 0 );   
	}
} 

trigger_sun_on( trigger )
{
    for ( ;; )
	{
		trigger waittill( "trigger", other );
		if( GetDvarInt( "sm_sunenable" ) == 1 )
		    continue;
		SetSavedDvar( "sm_sunenable", 1 );   
	}
} 

trigger_vehicle_getin_spawn( trigger )
{
	vehicle_spawners = GetEntArray( trigger.target, "targetname" );
	foreach ( spawner in vehicle_spawners )
	{
		targets = GetEntArray( spawner.target, "targetname" );
		foreach ( target in targets )
		{
			if ( !IsSubStr( target.code_classname, "actor" ) )
				continue;
			if ( !( target.spawnflags & 1 ) )
				continue;
			target.dont_auto_ride = true;
		}
	}
	trigger waittill( "trigger" );

	vehicle_spawners = GetEntArray( trigger.target, "targetname" );
	array_thread( vehicle_spawners, ::add_spawn_function, maps\_vehicle_code::vehicle_spawns_targets_and_rides );
	array_thread( vehicle_spawners, ::spawn_vehicle );
}

trigger_vehicle_spline_spawn( trigger )
{
	trigger waittill( "trigger" );
	//wait( 3 );
	spawners = GetEntArray( trigger.target, "targetname" );
	foreach ( spawner in spawners )
	{
		spawner thread maps\_vehicle_code::spawn_vehicle_and_attach_to_spline_path( 70 );
		wait( 0.05 );// slow start it up so spread it out
	}
}

//---------------------------------------------------------
// TRIGGER_LOOKAT
//---------------------------------------------------------
get_trigger_targs()
{
	triggers = [];
	target_origin = undefined;// was self.origin
	if ( IsDefined( self.target ) )
	{
		targets = GetEntArray( self.target, "targetname" );
		orgs = [];
		foreach ( target in targets )
		{
			if ( target.classname == "script_origin" )
				orgs[ orgs.size ] = target;
			if ( IsSubStr( target.classname, "trigger" ) )
				triggers[ triggers.size ] = target;
		}

		targets = getstructarray( self.target, "targetname" );

		foreach ( target in targets )
		{
			orgs[ orgs.size ] = target;
		}

		AssertEx( orgs.size < 2, "Trigger at " + self.origin + " targets multiple script origins" );
		if ( orgs.size == 1 )
		{
			org = orgs[ 0 ];
			target_origin = org.origin;
			if ( IsDefined( org.code_classname ) )
				org Delete();
		}
	}

	/#
	if ( IsDefined( self.targetname ) )
		AssertEx( IsDefined( target_origin ), self.targetname + " at " + self.origin + " has no target origin." );
	else
		AssertEx( IsDefined( target_origin ), self.classname + " at " + self.origin + " has no target origin." );
	#/

	array = [];
	array[ "triggers" ] = triggers;
	array[ "target_origin" ] = target_origin;
	return array;
}

trigger_lookat( trigger )
{
	// ends when the flag is hit
	trigger_lookat_think( trigger, true );
}

trigger_looking( trigger )
{
	// flag is only set while the thing is being looked at
	trigger_lookat_think( trigger, false );
}

trigger_lookat_think( trigger, endOnFlag )
{
	success_dot = 0.78;
	if ( IsDefined( trigger.script_dot ) )
	{
		success_dot = trigger.script_dot;
		AssertEx( success_dot <= 1, "Script_dot should be between 0 and 1" );
	}

	array = trigger get_trigger_targs();
	triggers = array[ "triggers" ];
	target_origin = array[ "target_origin" ];

	has_flag = IsDefined( trigger.script_flag ) || IsDefined( trigger.script_noteworthy );
	flagName = undefined;

	if ( has_flag )
	{
		flagName = trigger get_trigger_flag();
		if ( !isdefined( level.flag[ flagName ] ) )
			flag_init( flagName );
	}
	else
	{
		if ( !triggers.size )
			AssertEx( IsDefined( trigger.script_flag ) || IsDefined( trigger.script_noteworthy ), "Trigger_lookat at " + trigger.origin + " has no script_flag! The script_flag is used as a flag that gets set when the trigger is activated." );
	}

	if ( endOnFlag && has_flag )
	{
		level endon( flagName );
	}

	trigger endon( "death" );
	do_sighttrace = false;

	if ( IsDefined( trigger.script_parameters ) )
	{
		do_sighttrace = !issubstr( "no_sight", trigger.script_parameters );
	}

//	touching_trigger = [];

	for ( ;; )
	{
		if ( has_flag )
			flag_clear( flagName );

		trigger waittill( "trigger", other );

		AssertEx( IsPlayer( other ), "trigger_lookat currently only supports looking from the player" );
		touching_trigger = [];

		while ( other IsTouching( trigger ) )
		{
			if ( do_sighttrace && !sightTracePassed( other GetEye(), target_origin, false, undefined ) )
			{
				if ( has_flag )
					flag_clear( flagName );
				wait( 0.5 );
				continue;
			}

			normal = VectorNormalize( target_origin - other.origin );
		    player_angles = other GetPlayerAngles();
		    player_forward = AnglesToForward( player_angles );

			// Debug stuff:
	 		//angles = VectorToAngles( target_origin - other.origin );
		    //forward = AnglesToForward( angles );
	 		//draw_arrow( level.player.origin, level.player.origin + forward * 150, ( 1, 0.5, 0 ) );
	 		//draw_arrow( level.player.origin, level.player.origin + player_forward * 150, ( 0, 0.5, 1 ) );
	 		//angle = ACos(success_dot);
	 		//for(i = 0; i < 360; i += 10)
	 		//{
	 		//	point1 = level.player GetEye() + 10000 * AnglesToForward(CombineAngles(player_angles + (0, 0, i     ), (0, angle, 0)));
	 		//	point2 = level.player GetEye() + 10000 * AnglesToForward(CombineAngles(player_angles + (0, 0, i + 10), (0, angle, 0)));
	 		//	line( point1, point2, (1, 1, 1), 1.0);
	 		//}

			dot = VectorDot( player_forward, normal );
			if ( dot >= success_dot )
			{
				// notify targetted triggers as well
				array_thread( triggers, ::send_notify, "trigger" );

				if ( has_flag )
					flag_set( flagName, other );

				if ( endOnFlag )
					return;
				wait( 2 );
			}
			else
			{
				if ( has_flag )
					flag_clear( flagName );
			}

			if ( do_sighttrace )
				wait( 0.5 );
			else
				wait 0.05;
		}
	}
}

//---------------------------------------------------------
// TRIGGER_CANSEE
//---------------------------------------------------------
trigger_cansee( trigger )
{
	triggers = [];
	target_origin = undefined;// was trigger.origin

	array = trigger get_trigger_targs();
	triggers = array[ "triggers" ];
	target_origin = array[ "target_origin" ];

	has_flag = IsDefined( trigger.script_flag ) || IsDefined( trigger.script_noteworthy );
	flagName = undefined;

	if ( has_flag )
	{
		flagName = trigger get_trigger_flag();
		if ( !isdefined( level.flag[ flagName ] ) )
			flag_init( flagName );
	}
	else
	{
		if ( !triggers.size )
			AssertEx( IsDefined( trigger.script_flag ) || IsDefined( trigger.script_noteworthy ), "Trigger_cansee at " + trigger.origin + " has no script_flag! The script_flag is used as a flag that gets set when the trigger is activated." );
	}

	trigger endon( "death" );

	range = 12;
	offsets = [];
	offsets[ offsets.size ] = ( 0, 0, 0 );
	offsets[ offsets.size ] = ( range, 0, 0 );
	offsets[ offsets.size ] = ( range * -1, 0, 0 );
	offsets[ offsets.size ] = ( 0, range, 0 );
	offsets[ offsets.size ] = ( 0, range * -1, 0 );
	offsets[ offsets.size ] = ( 0, 0, range );

	for ( ;; )
	{
		if ( has_flag )
			flag_clear( flagName );

		trigger waittill( "trigger", other );
		AssertEx( IsPlayer( other ), "trigger_cansee currently only supports looking from the player" );

		while ( level.player IsTouching( trigger ) )
		{
			if ( !( other cantraceto( target_origin, offsets ) ) )
			{
				if ( has_flag )
					flag_clear( flagName );
				wait( 0.1 );
				continue;
			}

			if ( has_flag )
				flag_set( flagName );

			// notify targetted triggers as well
			array_thread( triggers, ::send_notify, "trigger" );
			wait( 0.5 );
		}
	}
}

cantraceto( target_origin, offsets )
{
	for ( i = 0; i < offsets.size; i++ )
	{
		if ( SightTracePassed( self GetEye(), target_origin + offsets[ i ], true, self ) )
			return true;
	}
	return false;
}

//---------------------------------------------------------
// TRIGGER_UNLOCK
//---------------------------------------------------------
trigger_unlock( trigger )
{
	// trigger unlocks unlock another trigger. When that trigger is hit, all unlocked triggers relock
	// trigger_unlocks with the same script_noteworthy relock the same triggers

	noteworthy = "not_set";
	if ( IsDefined( trigger.script_noteworthy ) )
		noteworthy = trigger.script_noteworthy;

	target_triggers = GetEntArray( trigger.target, "targetname" );

	trigger thread trigger_unlock_death( trigger.target );

	for ( ;; )
	{
		array_thread( target_triggers, ::trigger_off );
		trigger waittill( "trigger" );
		array_thread( target_triggers, ::trigger_on );

		wait_for_an_unlocked_trigger( target_triggers, noteworthy );

		array_notify( target_triggers, "relock" );
	}
}

trigger_unlock_death( target )
{
	self waittill( "death" );
	target_triggers = GetEntArray( target, "targetname" );
	array_thread( target_triggers, ::trigger_off );
}

wait_for_an_unlocked_trigger( triggers, noteworthy )
{
	level endon( "unlocked_trigger_hit" + noteworthy );
	ent = SpawnStruct();
	for ( i = 0; i < triggers.size; i++ )
	{
		triggers[ i ] thread report_trigger( ent, noteworthy );
	}
	ent waittill( "trigger" );
	level notify( "unlocked_trigger_hit" + noteworthy );
}


report_trigger( ent, noteworthy )
{
	self endon( "relock" );
	level endon( "unlocked_trigger_hit" + noteworthy );
	self waittill( "trigger" );
	ent notify( "trigger" );
}

trigger_battlechatter( trigger )
{
	realTrigger = undefined;

	// see if this targets an auxiliary trigger for advanced usage
	if ( IsDefined( trigger.target ) )
	{
		targetEnts = GetEntArray( trigger.target, "targetname" );

		if ( IsSubStr( targetEnts[ 0 ].classname, "trigger" ) )
		{
			realTrigger = targetEnts[ 0 ];
		}
	}

	// if we target an auxiliary trigger, that one kicks off the custom battlechatter event
	if ( IsDefined( realTrigger ) )
	{
		realTrigger waittill( "trigger", other );
	}
	else
	{
		trigger waittill( "trigger", other );
	}

	soldier = undefined;

	// for advanced usage: target an auxiliary trigger that kicks off the battlechatter event, but only
	//  if the player is touching the trigger that targets it.
	if ( IsDefined( realTrigger ) )
	{
		// enemy touched trigger, have a friendly tell the player about it
		if ( ( other.team != level.player.team ) && level.player IsTouching( trigger ) )
		{
			soldier = level.player animscripts\battlechatter::getClosestFriendlySpeaker( "custom" );
		}
		// friendly touched auxiliary trigger, have the enemy AI chatter about it
		else if ( other.team == level.player.team )
		{
			enemyTeam = "axis";
			if ( level.player.team == "axis" )
			{
				enemyTeam = "allies";
			}

			soldiers = animscripts\battlechatter::getSpeakers( "custom", enemyTeam );
			// for some reason, get_array_of_farthest returns the closest at index 0
			soldiers = get_array_of_farthest( level.player.origin, soldiers );

			foreach ( guy in soldiers )
			{
				if ( guy IsTouching( trigger ) )
				{
					soldier = guy;

					if ( battlechatter_dist_check( guy.origin ) )
					{
						break;
					}
				}
			}
		}
	}
	// otherwise we're just using one trigger
	else if ( IsPlayer( other ) )
	{
		soldier = other animscripts\battlechatter::getClosestFriendlySpeaker( "custom" );
	}
	else
	{
		soldier = other;
	}

	if ( !IsDefined( soldier ) )
	{
		return;
	}

	if ( battlechatter_dist_check() )
	{
		return;
	}

	success = soldier custom_battlechatter( trigger.script_bctrigger );

	// if the chatter didn't play successfully, rethread the function on the trigger
	if ( !success )
	{
		level delayThread( 0.25, ::trigger_battlechatter, trigger );
	}
	else
	{
		trigger notify( "custom_battlechatter_done" );
	}
}

battlechatter_dist_check( origin )
{
	return ( DistanceSquared( origin, level.player GetOrigin() ) <= 512 * 512 );
}

trigger_vehicle_spawn( trigger )
{
	trigger waittill( "trigger" );

	spawners = GetEntArray( trigger.target, "targetname" );
	foreach ( spawner in spawners )
	{
		spawner thread maps\_vehicle::spawn_vehicle_and_gopath();
		wait( 0.05 );// slow start it up so spread it out
	}
}

trigger_dooropen( trigger )
{
	trigger waittill( "trigger" );
	targets = GetEntArray( trigger.target, "targetname" );
	rotations = [];
	rotations[ "left_door" ] = -170;
	rotations[ "right_door" ] = 170;
	foreach ( door in targets )
	{
		AssertEx( IsDefined( door.script_noteworthy ), "Door had no script_noteworthy to indicate which door it is. Must be left_door or right_door." );
		rotation = rotations[ door.script_noteworthy ];
		door ConnectPaths();
		door RotateYaw( rotation, 1, 0, 0.5 );
	}
}

trigger_glass_break( trigger )
{
	glassID = GetGlassArray( trigger.target );

	if ( !IsDefined( glassID ) || glassID.size == 0 )
	{
		AssertMsg( "Glass shatter trigger at origin " + trigger.origin + " needs to target a func_glass." );
		return;
	}

	while ( 1 )
	{
		level waittill( "glass_break", other );

		// the ent that sent the notify needs to be touching the trigger_glass_break
		if ( other IsTouching( trigger ) )
		{
			// try to figure out the direction of movement
			ref1 = other.origin;
			wait( 0.05 );
			ref2 = other.origin;

			direction = undefined;
			if ( ref1 != ref2 )
			{
				direction = ref2 - ref1;
			}

			if ( IsDefined( direction ) )
			{
				foreach ( glass in glassID )
					DestroyGlass( glass, direction );
				break;
			}
			else
			{
				foreach ( glass in glassID )
					DestroyGlass( glass );
				break;
			}
		}
	}

	trigger Delete();
}

trigger_delete_link_chain( trigger )
{
	// deletes all entities that it script_linkto's, and all entities that entity script linktos, etc.
	trigger waittill( "trigger" );

	targets = trigger get_script_linkto_targets();
	array_thread( targets, ::delete_links_then_self );
}

get_script_linkto_targets()
{
	targets = [];
	if ( !isdefined( self.script_linkTo ) )
		return targets;

	tokens = StrTok( self.script_linkto, " " );
	for ( i = 0; i < tokens.size; i++ )
	{
		token = tokens[ i ];
		target = GetEnt( token, "script_linkname" );
		if ( IsDefined( target ) )
			targets[ targets.size ] = target;
	}
	return targets;
}

delete_links_then_self()
{
	targets = get_script_linkto_targets();
	array_thread( targets, ::delete_links_then_self );
	self Delete();
}

trigger_throw_grenade_at_player( trigger )
{
	trigger endon( "death" );

	trigger waittill( "trigger" );

	ThrowGrenadeAtPlayerASAP();
}

trigger_hint( trigger )
{
	AssertEx( IsDefined( trigger.script_hint ), "Trigger_hint at " + trigger.origin + " has no .script_hint" );

	if ( !isdefined( level.displayed_hints ) )
	{
		level.displayed_hints = [];
	}
	// give level script a chance to set the hint string and optional boolean functions on this hint
	waittillframeend;

	hint = trigger.script_hint;
	AssertEx( IsDefined( level.trigger_hint_string[ hint ] ), "Trigger_hint with hint " + hint + " had no hint string assigned to it. Define hint strings with add_hint_string()" );
	trigger waittill( "trigger", other );

	AssertEx( IsPlayer( other ), "Tried to do a trigger_hint on a non player entity" );

	if ( IsDefined( level.displayed_hints[ hint ] ) )
		return;
	level.displayed_hints[ hint ] = true;

	other display_hint( hint );
}

trigger_delete_on_touch( trigger )
{
	for ( ;; )
	{
		trigger waittill( "trigger", other );
		if ( IsDefined( other ) )
		{
			// might've been removed before we got it
			other Delete();
		}
	}
}

trigger_turns_off( trigger )
{
	trigger waittill( "trigger" );
	trigger trigger_off();

	if ( !isdefined( trigger.script_linkTo ) )
		return;

	// also turn off all triggers this trigger links to
	tokens = StrTok( trigger.script_linkto, " " );
	for ( i = 0; i < tokens.size; i++ )
		array_thread( GetEntArray( tokens[ i ], "script_linkname" ), ::trigger_off );
}

trigger_ignore( trigger )
{
	thread trigger_runs_function_on_touch( trigger, ::set_ignoreme, ::get_ignoreme );
}

trigger_pacifist( trigger )
{
	thread trigger_runs_function_on_touch( trigger, ::set_pacifist, ::get_pacifist );
}

trigger_runs_function_on_touch( trigger, set_func, get_func )
{
	for ( ;; )
	{
		trigger waittill( "trigger", other );
		if ( !isalive( other ) )
			continue;
		if ( other [[ get_func ]]() )
			continue;
		other thread touched_trigger_runs_func( trigger, set_func );
	}
}

touched_trigger_runs_func( trigger, set_func )
{
	self endon( "death" );
	self.ignoreme = true;
	[[ set_func ]]( true );
	// so others can touch the trigger
	self.ignoretriggers = true;
	wait( 1 );
	self.ignoretriggers = false;

	while ( self IsTouching( trigger ) )
	{
		wait( 1 );
	}

	[[ set_func ]]( false );
}

trigger_radio( trigger )
{
	trigger waittill( "trigger" );
	radio_dialogue( trigger.script_noteworthy );
}


trigger_flag_set_player( trigger )
{
	if ( is_coop() )
	{
		thread trigger_flag_set_coop( trigger );
		return;
	}

	flag = trigger get_trigger_flag();

	if ( !isdefined( level.flag[ flag ] ) )
	{
		flag_init( flag );
	}

	for ( ;; )
	{
		trigger waittill( "trigger", other );
		if ( !isplayer( other ) )
			continue;
		trigger script_delay();
		flag_set( flag );
	}
}

trigger_multiple_sunflare( trigger )
{
	while( 1 )
	{
		trigger waittill( "trigger", player );
		player maps\_art::sunflare_changes( trigger.script_visionset, trigger.script_delay );
		waitframe();
	}
}

trigger_multiple_visionset( trigger )
{
	is_progressional = false;
	dist = undefined;
	start = undefined;
	end = undefined;

	if ( IsDefined( trigger.script_visionset_start ) && IsDefined( trigger.script_visionset_end ) )
	{
		is_progressional = true;

		AssertEx( IsDefined( trigger.target ), "Vision set trigger at " + trigger.origin + " does not target a start point (script_struct or script_origin)." );

		start = GetEnt( trigger.target, "targetname" );
		if ( !IsDefined( start ) )
		{
			start = getstruct( trigger.target, "targetname" );
		}

		end = GetEnt( start.target, "targetname" );
		if ( !IsDefined( end ) )
		{
			end = getstruct( start.target, "targetname" );
		}

		AssertEx( IsDefined( start ), "Vision set trigger at " + trigger.origin + " does not target a start point (script_struct or script_origin)." );
		AssertEx( IsDefined( end ), "Vision set trigger at " + trigger.origin + " does not target a start point that targets an end point (script_struct or script_origin)." );

		start = start.origin;
		end = end.origin;
		dist = Distance( start, end );

		trigger init_visionset_progress_trigger();
	}

/#
	if ( !is_progressional )	
	{
		AssertEx( IsDefined( trigger.script_delay ), "Vision set trigger at " + trigger.origin + " has no script_delay to control the fade time." );
		AssertEx( IsDefined( trigger.script_visionset ), "Vision set trigger at " + trigger.origin + " has no script_visionset to control the vision set." );
	}
#/

	old_progress = -1;
	for ( ;; )
	{
		trigger waittill( "trigger", player );
		if ( IsPlayer( player ) )
		{
			if ( is_progressional )
			{
				progress = 0;
				while ( player IsTouching( trigger ) )
				{
					progress = get_progress( start, end, player.origin, dist );
//					println( "Progress = " + progress );
		
					progress = Clamp( progress, 0, 1 );
	
					if ( progress != old_progress )
					{
						old_progress = progress;
						player vision_set_fog_progress( trigger, progress );
					}
					wait( 0.05 );
				}

				if ( progress < 0.5 )
				{
					player vision_set_fog_changes( trigger.script_visionset_start, trigger.script_delay );
				}
				else
				{
					player vision_set_fog_changes( trigger.script_visionset_end, trigger.script_delay );
				}
			}
			else
			{
				player vision_set_fog_changes( trigger.script_visionset, trigger.script_delay );
			}
		}
	}
}

init_visionset_progress_trigger()
{
	if ( !IsDefined( self.script_delay ) )
	{
		self.script_delay = 2;
	}

	fog_start 	= get_vision_set_fog( self.script_visionset_start );
	fog_end 	= get_vision_set_fog( self.script_visionset_end );

	if ( !IsDefined( fog_start ) || !IsDefined( fog_end ) )
	{
		return;
	}

	ent 						= SpawnStruct();
	ent.startDist 				= fog_end.startDist - fog_start.startDist;
	ent.halfwayDist 			= fog_end.halfwayDist - fog_start.halfwayDist;
	ent.red 					= fog_end.red - fog_start.red;
	ent.blue 					= fog_end.blue - fog_start.blue;
	ent.green 					= fog_end.green - fog_start.green;
	ent.HDRColorIntensity		= fog_end.HDRColorIntensity - fog_start.HDRColorIntensity;
	ent.maxOpacity 				= fog_end.maxOpacity - fog_start.maxOpacity;
	ent.sunFogEnabled 			= IsDefined( fog_start.sunFogEnabled ) || IsDefined( fog_end.sunFogEnabled );
	ent.HDRSunColorIntensity	= fog_end.HDRSunColorIntensity - fog_start.HDRSunColorIntensity;
	ent.skyFogIntensity			= fog_end.skyFogIntensity - fog_start.skyFogIntensity;
	ent.skyFogMinAngle			= fog_end.skyFogMinAngle - fog_start.skyFogMinAngle;
	ent.skyFogMaxAngle			= fog_end.skyFogMaxAngle - fog_start.skyFogMaxAngle;

	// Sun Fog - which are optional params
	// sunRed
	fog_start_sunred = 0;
	if ( IsDefined( fog_start.sunRed ) )
	{
		fog_start_sunred = fog_start.sunRed;
	}

	fog_end_sunred = 0;
	if ( IsDefined( fog_end.sunRed ) )
	{
		fog_end_sunred = fog_end.sunRed;
	}

	ent.sunRed_start = fog_start_sunred;
	ent.sunRed = fog_end_sunred - fog_start_sunred;

	// sunGreen
	fog_start_sunGreen = 0;
	if ( IsDefined( fog_start.sunGreen ) )
	{
		fog_start_sunGreen = fog_start.sunGreen;
	}

	fog_end_sunGreen = 0;
	if ( IsDefined( fog_end.sunGreen ) )
	{
		fog_end_sunGreen = fog_end.sunGreen;
	}

	ent.sunGreen_start = fog_start_sunGreen;
	ent.sunGreen =fog_end_sunGreen - fog_start_sunGreen;

	// sunBlue
	fog_start_sunBlue = 0;
	if ( IsDefined( fog_start.sunBlue ) )
	{
		fog_start_sunBlue = fog_start.sunBlue;
	}

	fog_end_sunBlue = 0;
	if ( IsDefined( fog_end.sunBlue ) )
	{
		fog_end_sunBlue = fog_end.sunBlue;
	}

	ent.sunBlue_start = fog_start_sunBlue;
	ent.sunBlue = fog_end_sunBlue - fog_start_sunBlue;

	// sunDir
	fog_start_sunDir = ( 0, 0, 0 );
	if ( IsDefined( fog_start.sunDir ) )
	{
		fog_start_sunDir = fog_start.sunDir;
	}

	fog_end_sunDir = ( 0, 0, 0 );
	if ( IsDefined( fog_end.sunDir ) )
	{
		fog_end_sunDir = fog_end.sunDir;
	}

	ent.sunDir_start = fog_start_sundir;
	ent.sunDir = ( fog_end_sunDir - fog_start_sunDir );

	// sunBeginFadeAngle
	fog_start_sunBeginFadeAngle = 0;
	if ( IsDefined( fog_start.sunBeginFadeAngle ) )
	{
		fog_start_sunBeginFadeAngle = fog_start.sunBeginFadeAngle;
	}

	fog_end_sunBeginFadeAngle = 0;
	if ( IsDefined( fog_end.sunBeginFadeAngle ) )
	{
		fog_end_sunBeginFadeAngle = fog_end.sunBeginFadeAngle;
	}

	ent.sunBeginFadeAngle_start = fog_start_sunBeginFadeAngle;
	ent.sunBeginFadeAngle = fog_end_sunBeginFadeAngle - fog_start_sunBeginFadeAngle;

	// sunEndFadeAngle
	fog_start_sunEndFadeAngle = 0;
	if ( IsDefined( fog_start.sunEndFadeAngle ) )
	{
		fog_start_sunEndFadeAngle = fog_start.sunEndFadeAngle;
	}

	fog_end_sunEndFadeAngle = 0;
	if ( IsDefined( fog_end.sunEndFadeAngle ) )
	{
		fog_end_sunEndFadeAngle = fog_end.sunEndFadeAngle;
	}

	ent.sunEndFadeAngle_start = fog_start_sunEndFadeAngle;
	ent.sunEndFadeAngle = fog_end_sunEndFadeAngle - fog_start_sunEndFadeAngle;

	// normalFogScale
	fog_start_normalFogScale = 0;
	if ( IsDefined( fog_start.normalFogScale ) )
	{
		fog_start_normalFogScale = fog_start.normalFogScale;
	}

	fog_end_normalFogScale = 0;
	if ( IsDefined( fog_end.normalFogScale ) )
	{
		fog_end_normalFogScale = fog_end.normalFogScale;
	}

	ent.normalFogScale_start = fog_start_normalFogScale;
	ent.normalFogScale = fog_end_normalFogScale - fog_start_normalFogScale;

	self.visionset_diff = ent;
}

vision_set_fog_progress( trigger, progress )
{
	self init_self_visionset();

	if ( progress < 0.5 )
	{
		self.vision_set_transition_ent.vision_set = trigger.script_visionset_start;
	}
	else
	{
		self.vision_set_transition_ent.vision_set = trigger.script_visionset_end;
	}

	self.vision_set_transition_ent.time = 0;

	if ( trigger.script_visionset_start == trigger.script_visionset_end )
	{
		return;
	}

	self VisionSetNakedForPlayer_Lerp( trigger.script_visionset_start, trigger.script_visionset_end, progress );

	// Fog
	fog_start 	= get_vision_set_fog( trigger.script_visionset_start );
	fog_end 	= get_vision_set_fog( trigger.script_visionset_end );

	diff = trigger.visionset_diff;

	ent 					= SpawnStruct();
	ent.startDist 			= fog_start.startDist + ( diff.startDist * progress );
	ent.halfwayDist			= fog_start.halfwayDist + ( diff.halfwayDist * progress );
	ent.halfwayDist			= max( 1, ent.halfwayDist );
	ent.red 				= fog_start.red + ( diff.red * progress );
	ent.green 				= fog_start.green + ( diff.green * progress );
	ent.blue 				= fog_start.blue + ( diff.blue * progress );
	ent.HDRColorIntensity	= fog_start.HDRColorIntensity + ( diff.HDRColorIntensity * progress );
	ent.maxOpacity 			= fog_start.maxOpacity + ( diff.maxOpacity * progress );
	ent.skyFogIntensity		= fog_start.skyFogIntensity + ( diff.skyFogIntensity * progress );
	ent.skyFogMinAngle		= fog_start.skyFogMinAngle + ( diff.skyFogMinAngle * progress );
	ent.skyFogMaxAngle		= fog_start.skyFogMaxAngle + ( diff.skyFogMaxAngle * progress );

	if ( diff.sunFogEnabled )
	{
		ent.sunFogEnabled			= true;
		ent.sunRed 					= diff.sunRed_start + ( diff.sunRed * progress );
		ent.sunGreen 				= diff.sunGreen_start + ( diff.sunGreen * progress );
		ent.sunBlue 				= diff.sunBlue_start + ( diff.sunBlue * progress );
		ent.HDRSunColorIntensity	= fog_start.HDRSunColorIntensity + ( diff.HDRSunColorIntensity * progress );
		ent.sunDir					= diff.sunDir_start + ( diff.sunDir * progress );
		ent.sunBeginFadeAngle		= diff.sunBeginFadeAngle_start + ( diff.sunBeginFadeAngle * progress );
		ent.sunEndFadeAngle			= diff.sunEndFadeAngle_start + ( diff.sunEndFadeAngle * progress );
		ent.normalFogScale			= diff.normalFogScale_start + ( diff.normalFogScale * progress );
	} 

	self set_fog_to_ent_values( ent, 0.05 );
}

/*
	A depth trigger that sets fog
*/
trigger_fog( trigger )
{
	waittillframeend;

	start_fog 	 = trigger.script_fogset_start;
	end_fog 	 = trigger.script_fogset_end;

	AssertEx( IsDefined( start_fog ), "Fog trigger is missing .script_fogset_start" );
	AssertEx( IsDefined( end_fog ), "Fog trigger is missing .script_fogset_end" );

	trigger.sunfog_enabled = false;

	if ( IsDefined( start_fog ) && IsDefined( end_fog ) )
	{
		start_fog_ent = get_fog( start_fog );
		end_fog_ent = get_fog( end_fog );

		AssertEx( IsDefined( start_fog_ent ), "Fog set " + start_fog + " does not exist, please use create_fog() in level_fog.gsc." );
		AssertEx( IsDefined( end_fog_ent ), "Fog set " + end_fog + " does not exist, please use create_fog() in level_fog.gsc." );

		trigger.sunfog_enabled 			 = ( IsDefined( start_fog_ent.sunred ) ||  IsDefined( end_fog_ent.sunred ) );

		trigger.start_neardist 			 = start_fog_ent.startDist;
		trigger.start_fardist 			 = start_fog_ent.halfwayDist;
		trigger.start_color 			 = ( start_fog_ent.red, start_fog_ent.green, start_fog_ent.blue );
		trigger.start_HDRColorIntensity	 = start_fog_ent.HDRColorIntensity;
		trigger.start_opacity 			 = start_fog_ent.maxOpacity;

		trigger.start_skyFogIntensity	 = start_fog_ent.skyFogIntensity;
		trigger.start_skyFogMinAngle	 = start_fog_ent.skyFogMinAngle;
		trigger.start_skyFogMaxAngle	 = start_fog_ent.skyFogMaxAngle;

		if ( IsDefined( start_fog_ent.sunred ) )
		{
			Assert( IsDefined( start_fog_ent.sungreen ) );
			Assert( IsDefined( start_fog_ent.sunblue ) );
			Assert( IsDefined( start_fog_ent.sundir ) );
			Assert( IsDefined( start_fog_ent.sunBeginFadeAngle ) );
			Assert( IsDefined( start_fog_ent.sunEndFadeAngle ) );
			Assert( IsDefined( start_fog_ent.normalFogScale ) );

			trigger.start_suncolor				= ( start_fog_ent.sunred, start_fog_ent.sungreen, start_fog_ent.sunblue );
			trigger.start_HDRSunColorIntensity	= start_fog_ent.HDRSunColorIntensity;
			trigger.start_sundir				= start_fog_ent.sundir;
			trigger.start_sunBeginFadeAngle		= start_fog_ent.sunBeginFadeAngle;
			trigger.start_sunEndFadeAngle 		= start_fog_ent.sunEndFadeAngle;
			trigger.start_sunFogScale 			= start_fog_ent.normalFogScale;
		}
		else
		{
			if ( trigger.sunfog_enabled )
			{
				trigger.start_suncolor			 	= trigger.start_color;
				trigger.start_HDRSunColorIntensity	= 1;
				trigger.start_sundir			 	= ( 0, 0, 0 );
				trigger.start_sunBeginFadeAngle 	= 0;
				trigger.start_sunEndFadeAngle 	 	= 90;
				trigger.start_sunFogScale 		 	= 1;
			}
		}

		trigger.end_neardist 			 = end_fog_ent.startDist;
		trigger.end_fardist 			 = end_fog_ent.halfwayDist;
		trigger.end_color 				 = ( end_fog_ent.red, end_fog_ent.green, end_fog_ent.blue );
		trigger.end_HDRColorIntensity	 = end_fog_ent.HDRColorIntensity;
		trigger.end_opacity 			 = end_fog_ent.maxOpacity;

		trigger.end_skyFogIntensity		 = end_fog_ent.skyFogIntensity;
		trigger.end_skyFogMinAngle		 = end_fog_ent.skyFogMinAngle;
		trigger.end_skyFogMaxAngle		 = end_fog_ent.skyFogMaxAngle;

		if ( IsDefined( end_fog_ent.sunred ) )
		{
			Assert( IsDefined( end_fog_ent.sungreen ) );
			Assert( IsDefined( end_fog_ent.sunblue ) );
			Assert( IsDefined( end_fog_ent.sundir ) );
			Assert( IsDefined( end_fog_ent.sunBeginFadeAngle ) );
			Assert( IsDefined( end_fog_ent.sunEndFadeAngle ) );
			Assert( IsDefined( end_fog_ent.normalFogScale ) );

			trigger.end_suncolor				= ( end_fog_ent.sunred, end_fog_ent.sungreen, end_fog_ent.sunblue );
			trigger.end_HDRSunColorIntensity	= end_fog_ent.HDRSunColorIntensity;
			trigger.end_sundir					= end_fog_ent.sundir;
			trigger.end_sunBeginFadeAngle 		= end_fog_ent.sunBeginFadeAngle;
			trigger.end_sunEndFadeAngle 		= end_fog_ent.sunEndFadeAngle;
			trigger.end_sunFogScale 			= end_fog_ent.normalFogScale;

		}
		else
		{
			if ( trigger.sunfog_enabled )
			{
				trigger.end_suncolor			 	= trigger.end_color;
				trigger.end_HDRSunColorIntensity	= 1;
				trigger.end_sundir				 	= ( 0, 0, 0 );
				trigger.end_sunBeginFadeAngle 	 	= 0;
				trigger.end_sunEndFadeAngle 	 	= 90;
				trigger.end_sunFogScale 		 	= 1;
			}
		}
	}

	AssertEx( IsDefined( trigger.start_neardist ), "trigger_fog lacks start_neardist" );
	AssertEx( IsDefined( trigger.start_fardist ), "trigger_fog lacks start_fardist" );
	AssertEx( IsDefined( trigger.start_color ), "trigger_fog lacks start_color" );

	AssertEx( IsDefined( trigger.end_color ), "trigger_fog lacks end_color" );
	AssertEx( IsDefined( trigger.end_neardist ), "trigger_fog lacks end_neardist" );
	AssertEx( IsDefined( trigger.end_fardist ), "trigger_fog lacks end_fardist" );

	AssertEx( IsDefined( trigger.target ), "trigger_fog doesnt target an origin to set the start plane" );
	ent = GetEnt( trigger.target, "targetname" );
	AssertEx( IsDefined( ent ), "trigger_fog doesnt target an origin to set the start plane" );

	start = ent.origin;
	end = undefined;

	if ( IsDefined( ent.target ) )
	{
		// if the origin targets a second origin, use it as the end point
		target_ent = GetEnt( ent.target, "targetname" );
		end = target_ent.origin;
	}
	else
	{
		// otherwise double the difference between the target origin and start to get the endpoint
		end = start + ( (trigger.origin - start)* 2 );
	}

//	thread linedraw( start, end, (1,0.5,1) );
//	thread print3ddraw( start, "start", (1,0.5,1) );
//	thread print3ddraw( end, "end", (1,0.5,1) );
	dist = Distance( start, end );

	for ( ;; )
	{
		trigger waittill( "trigger", other );
		AssertEx( IsPlayer( other ), "Non - player entity touched a trigger_fog." );

		progress = 0;
		while ( other IsTouching( trigger ) )
		{
			progress = get_progress( start, end, other.origin, dist );
//			PrintLn( "progress " + progress );

			progress = Clamp( progress, 0, 1 );
			trigger maps\_art::set_fog_progress( progress );
			wait( 0.05 );
		}

		// when you leave the trigger set it to whichever point it was closest too
		if ( progress > 0.5 )
			progress = 1;
		else
			progress = 0;

		trigger maps\_art::set_fog_progress( progress );
	}
}

trigger_multiple_depthoffield( trigger )
{
	waittillframeend;
	
	while ( 1 )
	{
		trigger waittill( "trigger", player );
			
		nearStart 	= trigger.script_dof_near_start;
		nearEnd 	= trigger.script_dof_near_end;
		nearBlur 	= trigger.script_dof_near_blur;
		farStart 	= trigger.script_dof_far_start;
		farEnd 		= trigger.script_dof_far_end;
		farBlur 	= trigger.script_dof_far_blur;
		time 		= trigger.script_delay;
		
		if ( ( nearStart 	!= level.dof["base"]["goal"]["nearStart"] ) ||
		     ( nearEnd 		!= level.dof["base"]["goal"]["nearEnd"] ) 	||
		     ( nearBlur 	!= level.dof["base"]["goal"]["nearBlur"] ) 	||
		     ( farStart 	!= level.dof["base"]["goal"]["farStart"] ) 	||
		     ( farEnd 		!= level.dof["base"]["goal"]["farEnd"] ) 	||
		     ( farBlur 		!= level.dof["base"]["goal"]["farBlur"] ) )
		{
			maps\_art::dof_set_base( nearStart, nearEnd, nearBlur, farStart, farEnd, farBlur, time );
			wait( time );
		}
		else
		{
			waitframe();
		}
	}
}

trigger_slide( trigger )
{
	while ( 1 )
	{
		trigger waittill( "trigger", player );
		player thread slideTriggerPlayerThink( trigger );
	}
}

slideTriggerPlayerThink( trig )
{
	if ( IsDefined( self.vehicle ) )
		return;

	if ( self IsSliding() )
		return;
		
	if ( isdefined( self.player_view ) )
		return;

	self endon( "death" );
	
	if ( SoundExists( "SCN_cliffhanger_player_hillslide" ) )
		self PlaySound( "SCN_cliffhanger_player_hillslide" );

	accel = undefined;
	if ( IsDefined( trig.script_accel ) )
	{
		accel = trig.script_accel;
	}

	self BeginSliding( undefined, accel );
	while ( 1 )
	{
		if ( !self IsTouching( trig ) )
			break;
		wait .05;
	}
	if ( IsDefined( level.end_slide_delay ) )
		wait( level.end_slide_delay );
	self EndSliding();
}

trigger_multiple_fx_volume( trigger )
{
    dummy = spawn( "script_origin", ( 0, 0, 0 ) );
    trigger.fx = [];
	foreach ( EntFx in level.createfxent )
    	assign_fx_to_trigger( EntFx, trigger, dummy );
    	
    dummy delete();
    
    if( !isdefined( trigger.target ) )
        return;

    targets = GetEntArray( trigger.target, "targetname" );
    foreach(target in targets )
    {
        switch( target.classname )
        {
            case "trigger_multiple_fx_volume_on":
                target thread trigger_multiple_fx_trigger_on_think( trigger );
                break;
            case "trigger_multiple_fx_volume_off":
                target thread trigger_multiple_fx_trigger_off_think( trigger );
                break;
            default:
                break;
        }
    }
    
}

trigger_multiple_fx_trigger_on_think( volume )
{
	while( true )
	{
		self waittill( "trigger" );
		array_thread( volume.fx, ::restartEffect );
		wait( 1 );
	}
}

trigger_multiple_fx_trigger_off_think( volume )
{
	wait( 1 );
	array_thread( volume.fx, ::pauseEffect );
	
	while( true )
	{
		self waittill( "trigger" );
		array_thread( volume.fx, ::pauseEffect );
		wait( 1 );
	}
}

assign_fx_to_trigger( EntFx, trigger, dummy )
{
    if ( IsDefined( EntFx.v[ "soundalias" ] ) && ( EntFx.v[ "soundalias" ] != "nil" ) )
        if ( !IsDefined( EntFx.v[ "stopable" ] ) || !EntFx.v[ "stopable" ] )
            return;
	dummy.origin = EntFx.v[ "origin" ];
	if ( dummy istouching( trigger ) )
		trigger.fx [ trigger.fx.size ] = EntFx;
}


trigger_multiple_compass( trigger )
{
	minimap_image = trigger.script_parameters;
	AssertEx( IsDefined( minimap_image ), "trigger_multiple_compass has no script_parameters for its minimap_image." );

	if ( !isdefined( level.minimap_image ) )
		level.minimap_image = "";
	for ( ;; )
	{
		trigger waittill( "trigger" );
		if ( level.minimap_image != minimap_image )
		{
			maps\_compass::setupMiniMap( minimap_image );
		}
	}
}

trigger_no_crouch_or_prone( trigger )
{
	array_thread( level.players, ::no_crouch_or_prone_think_for_player, trigger );
}

no_crouch_or_prone_think_for_player( trigger )
{
	assert( isplayer( self ) );
	for ( ;; )
	{
		trigger waittill( "trigger", player );
		
		if ( !isdefined( player ) )
			continue;
		
		if ( player != self )
			continue;
		
		while ( player IsTouching( trigger ) )
		{
			player AllowProne( false );
			player AllowCrouch( false );
			wait( 0.05 );
		}
		player AllowProne( true );
		player AllowCrouch( true );
	}
}

trigger_no_prone( trigger )
{
	array_thread( level.players, ::no_prone_for_player, trigger );
}

no_prone_for_player( trigger )
{
	assert( isplayer( self ) );
	for ( ;; )
	{
		trigger waittill( "trigger", player );
		
		if ( !isdefined( player ) )
			continue;
		
		if ( player != self )
			continue;
		
		while ( player IsTouching( trigger ) )
		{
			player AllowProne( false );
			wait( 0.05 );
		}
		player AllowProne( true );
	}
}