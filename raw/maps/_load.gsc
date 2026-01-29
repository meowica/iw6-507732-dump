#include common_scripts\utility;
#include maps\_utility;
//#include maps\_debug;
#include maps\_vehicle;
#include maps\_hud_util;

/*QUAKED script_origin_start_nogame (0.8 0.7 0.2) (-16 -16 0) (16 16 72)

    This is used to tell the game where the player will start on no_game.  
    
    The script will find the closest one to the player start and put you there. 
    
    set "script_startname" on the trigger to create a new start point in the start menu and this one will be the one that you go to with that start.

*/

/*QUAKED script_origin_mini (1.0 0.0 0.0) (-2 -2 -2) (2 2 2)*/

/*QUAKED script_origin_small (1.0 0.0 0.0) (-4 -4 -4) (4 4 4)*/

/*QUAKED script_struct_mini (0.9 0.3 0.0) (-1 -1 -1) (1 1 1)*/

/*QUAKED script_struct_small (0.9 0.3 0.0) (-2 -2 -2) (2 2 2)*/

/*QUAKED script_struct_heli (0.9 0.8 0.0) (-16 -16 -16) (16 16 16) START_NODE
*/

main()
{
	if ( !isdefined( level.func ) )
	{
		level.func = [];
	}
	level.func[ "setsaveddvar" ] 	= ::setsaveddvar;
	level.func[ "useanimtree" ] 	= ::useAnimTree;
	level.func[ "setanim" ]			= ::setAnim;
	level.func[ "setanimknob" ]	 	= ::setAnimKnob;
	level.func[ "clearanim" ]		= ::clearAnim;
	level.func[ "kill" ]			= ::Kill;
	level.func[ "magicgrenade" ]	= ::magicgrenade;

	set_early_level();
	
	/#
	
		// Moving here so that we can convert the old barrels to destructibles before destructibles are run.	
		thread maps\_debug::interactive_warnings();
	
	#/
	
	//*****************************************			STEALTH SYSTEM CALLBACKS		*****************************************/

	//->since stealth is so integrated into many global scripts, these call backs refer to an empty function...if they are actually
	//called, that means the designer called a stealth function without initilizing the stealth system first.  This is done so stealth
	//scripts dont have to be loaded globally into every level
	level.global_callbacks = [];

	level.global_callbacks[ "_autosave_stealthcheck" ] 		 = ::global_empty_callback;
	level.global_callbacks[ "_patrol_endon_spotted_flag" ] 	 = ::global_empty_callback;
	level.global_callbacks[ "_spawner_stealth_default" ] 	 = ::global_empty_callback;
	//this one's for _idle...its peppered with stealth stuff so it got quarentined too.
	level.global_callbacks[ "_idle_call_idle_func" ] 		 = ::global_empty_callback;

	//*****************************************			STEALTH SYSTEM CALLBACKS		*****************************************/

	/#
	weapon_list_debug();
	#/

	if ( !isdefined( level.visionThermalDefault ) )
		level.visionThermalDefault = "cheat_bw";
	VisionSetThermal( level.visionThermalDefault );

	VisionSetPain( "near_death" );

	level.func[ "damagefeedback" ] = maps\_damagefeedback::updateDamageFeedback;// for player shooting sentry guns
	array_thread( GetEntArray( "script_model_pickup_claymore", "classname" ), ::claymore_pickup_think_global );
	array_thread( GetEntArray( "ammo_cache", "targetname" ), ::ammo_cache_think_global );
	
	//softlanding is multiplayer only
	array_delete( GetEntArray( "trigger_multiple_softlanding", "classname" ) );

	/# star( randomintrange( 4,8 ) ); #/

	if ( GetDvar( "debug" ) == "" )
		SetDvar( "debug", "0" );

	if ( GetDvar( "fallback" ) == "" )
		SetDvar( "fallback", "0" );

	if ( GetDvar( "angles" ) == "" )
		SetDvar( "angles", "0" );

	if ( GetDvar( "noai" ) == "" )
		SetDvar( "noai", "off" );

	if ( GetDvar( "scr_RequiredMapAspectratio" ) == "" )
		SetDvar( "scr_RequiredMapAspectratio", "1" );

	//if ( GetDvar( "ac130_player_num" ) == "" )
		SetDvar( "ac130_player_num", -1 );	// reset ac130 player number for proper display of HUD
	
	SetDvar( "ui_remotemissile_playernum", 0 );
	SetDvar( "ui_pmc_won", 0 );
	
	SetDvar( "minimap_sp", 0 );
	SetDvar( "minimap_full_sp", 0 );

	CreatePrintChannel( "script_debug" );

	if ( !isdefined( anim.notetracks ) )
	{
		// string based array for notetracks
		anim.notetracks = [];
		animscripts\notetracks::registerNoteTracks();
	}
	
	flag_init( "introscreen_complete" );
	
	// default start for killing script.
	add_start( "no_game", ::start_nogame );
	add_no_game_starts();
	

	level._loadStarted = true;
	level.first_frame = true;
	level.level_specific_dof = false;
	thread remove_level_first_frame();

	level.wait_any_func_array 		 = [];
	level.run_func_after_wait_array = [];
	level.run_call_after_wait_array = [];
	level.run_noself_call_after_wait_array = [];
	level.do_wait_endons_array 		 = [];
	level.abort_wait_any_func_array = [];
	if ( !isdefined( level.script ) )
		level.script = ToLower( GetDvar( "mapname" ) );
	
	// disables shared ammo - otherwise the ammo of a base weapon ( ex:mp5k ) on the ground will 
	// be picked up as ammo by player with an advanced version of the base weapon ( ex:mp5k_acog )
	//setsaveddvar( "so_auto_shared_ammo", 0 );

	/*
	no_game_levels = [];
	no_game_levels[ "contingency" ] = true;

	if ( IsDefined( no_game_levels[ level.script ] ) )
	{
		SetDvar( "start", "no_game" );
	}
	else
	{
		if ( GetDvar( "start" ) == "no_game" )
			SetDvar( "start", "" );
	}
	*/

	level.dirtEffectMenu[ "center" ] = "dirt_effect_center";
	level.dirtEffectMenu[ "left" ] = "dirt_effect_left";
	level.dirtEffectMenu[ "right" ] = "dirt_effect_right";
	PrecacheMenu( level.dirtEffectMenu[ "center" ] );
	PrecacheMenu( level.dirtEffectMenu[ "left" ] );
	PrecacheMenu( level.dirtEffectMenu[ "right" ] );
	PreCacheShader( "fullscreen_dirt_bottom_b" );
	PreCacheShader( "fullscreen_dirt_bottom" );
	PreCacheShader( "fullscreen_dirt_left" );
	PreCacheShader( "fullscreen_dirt_right" );
	PreCacheShader( "fullscreen_bloodsplat_bottom" );
	PreCacheShader( "fullscreen_bloodsplat_left" );
	PreCacheShader( "fullscreen_bloodsplat_right" );

/*
=============
///ScriptFieldDocBegin
"Name: .ai_number"
"Summary: ai_number"
"Module: load"
"SPMP: singleplayer"
///ScriptDocEnd
=============
*/	
	level.ai_number = 0;
	// flag_struct is used as a placeholder when a flag is set without an entity

	if ( !isdefined( level.flag ) )
	{
		init_flags();
	}
	else
	{
		// flags initialized before this should be checked for stat tracking
		flags = GetArrayKeys( level.flag );
		array_levelthread( flags, ::check_flag_for_stat_tracking );
	}

	init_level_players();

	if ( IsSplitScreen() )
	{
		SetSavedDvar( "cg_fovScale", "0.75" );// 65 - > 40 fov// 0.54
	}
	else
	{
		SetSavedDvar( "cg_fovScale", "1" );
	}

	level.radiation_totalpercent = 0;

	flag_init( "missionfailed" );
	flag_init( "auto_adjust_initialized" );
	flag_init( "_radiation_poisoning" );
	flag_init( "gameskill_selected" );
	flag_init( "battlechatter_on_thread_waiting" );
	flag_init( "start_is_set" );

	thread maps\_gameskill::aa_init_stats();
	thread player_death_detection();

	level.default_run_speed = 190;
	SetSavedDvar( "g_speed", level.default_run_speed );

	if ( is_specialop() )
	{
		SetSavedDvar( "sv_saveOnStartMap", false );
	}
	else if (isdefined(level.credits_active))
	{
		SetSavedDvar( "sv_saveOnStartMap", false );
	}
	else
	{
		SetSavedDvar( "sv_saveOnStartMap", true );
	}

	create_lock( "mg42_drones" );
	create_lock( "mg42_drones_target_trace" );
	
	level.dronestruct = [];

	// remove delete_on_load structs
	foreach ( index, struct in level.struct )
	{
		if ( !isdefined( struct.targetname ) )
			continue;
		if ( struct.targetname == "delete_on_load" )
			level.struct[ index ] = undefined;
	}

	struct_class_init();

	// can be turned on and off to control friendly_respawn_trigger
	flag_init( "respawn_friendlies" );
	flag_init( "player_flashed" );

	//function pointers so I can share _destructible script with SP and MP where code commands don't exist in MP
	level.connectPathsFunction = ::connectPaths;
	level.disconnectPathsFunction = ::disconnectPaths;
	level.badplace_cylinder_func = ::badplace_cylinder;
	level.badplace_delete_func = ::badplace_delete;
	level.isAIfunc = ::isAI;
	level.createClientFontString_func = maps\_hud_util::createClientFontString;
	level.HUDsetPoint_func = maps\_hud_util::setPoint;
	level.makeEntitySentient_func = ::makeEntitySentient;
	level.freeEntitySentient_func = ::freeEntitySentient;
	level.laserOn_func = ::laserForceOn;
	level.laserOff_func = ::laserForceOff;
	level.stat_track_kill_func = maps\_player_stats::register_kill;
	level.stat_track_damage_func = maps\_player_stats::register_shot_hit;
	level.doPickyAutosaveChecks = true;
	level.autosave_threat_check_enabled = true;
	level.getNodeFunction = ::GetNode;
	level.getNodeArrayFunction = ::GetNodeArray;

	if ( !isdefined( level._notetrackFX ) )
		level._notetrackFX = [];

	foreach ( player in level.players )
	{
		player.maxhealth = level.player.health;
		player.shellshocked = false;
		player.inWater = false;
		player thread watchWeaponChange();// for thermal
	}

	level.last_mission_sound_time = -5000;
	level.hero_list = [];
	thread precache_script_models();

// 	level.ai_array = [];

	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[ i ];
		player thread flashMonitor();
		player thread shock_ondeath();
	}

	//un-developer commented. I was precaching this model in _vehicle anyway.
	PreCacheModel( "fx" );

	PreCacheModel( "tag_origin" );
	PreCacheModel( "tag_ik_target" );
	PreCacheShellShock( "victoryscreen" );
	PreCacheShellShock( "default" );
	PreCacheShellShock( "flashbang" );
	PreCacheShellShock( "dog_bite" );
	PreCacheRumble( "damage_heavy" );
	PreCacheRumble( "damage_light" );
	PreCacheRumble( "grenade_rumble" );
	PreCacheRumble( "artillery_rumble" );

	PreCacheRumble( "slide_start" );
	PreCacheRumble( "slide_loop" );

	// You are Hurt. Get to Cover!
	PreCacheString( &"GAME_GET_TO_COVER" );
	// Kill an enemy to get back up!
	PreCacheString( &"GAME_LAST_STAND_GET_BACK_UP" );
	// You were killed by a grenade.\nWatch out for the grenade danger indicator.
	PreCacheString( &"SCRIPT_GRENADE_DEATH" );
	// You died holding a grenade for too long.
	PreCacheString( &"SCRIPT_GRENADE_SUICIDE_LINE1" );
	// Holding ^3[{+frag}]^7 allows you to cook off live grenades.
	PreCacheString( &"SCRIPT_GRENADE_SUICIDE_LINE2" );
	// You were killed by an exploding vehicle.\nVehicles on fire are likely to explode.
	PreCacheString( &"SCRIPT_EXPLODING_VEHICLE_DEATH" );
	// You were killed by an explosion.\nSome burning objects can explode.
	PreCacheString( &"SCRIPT_EXPLODING_DESTRUCTIBLE_DEATH" );
	// You were killed by an exploding barrel.\nRed barrels will explode when shot.
	PreCacheString( &"SCRIPT_EXPLODING_BARREL_DEATH" );
	PreCacheShader( "hud_grenadeicon" );
	PreCacheShader( "hud_grenadepointer" );
	PreCacheShader( "hud_burningcaricon" );
	PreCacheShader( "death_juggernaut" );
	PreCacheShader( "death_friendly_fire" );
	PreCacheShader( "hud_destructibledeathicon" );
	PreCacheShader( "hud_burningbarrelicon" );
	PreCacheShader( "waypoint_ammo" );

	level._effect[ "deathfx_bloodpool_generic" ] = LoadFX( "fx/impacts/deathfx_bloodpool_generic" );
	animscripts\pain::initPainFx();

	animscripts\melee::Melee_Init();

	level.createFX_enabled = ( GetDvar( "createfx" ) != "" );

	slowmo_system_init();

	maps\_mgturret::main();

	maps\_exploder::setupExploders();
	maps\_art::main();
	maps\_gameskill::setSkill();

	maps\_anim::init();

	thread common_scripts\_fx::initFX();
	if ( level.createFX_enabled )
	{
		/#
		level.stop_load = true;
		maps\_createfx::createfx();
		#/
	}
	// global effects for objects
	maps\_global_fx_code::init();
	maps\_global_fx::main();

	default_footsteps();
	
	maps\_detonategrenades::init();

	thread setup_simple_primary_lights();

	// --------------------------------------------------------------------------------
	// ---- PAST THIS POINT THE SCRIPTS DONT RUN WHEN GENERATING REFLECTION PROBES ----
	// --------------------------------------------------------------------------------
	/#
	if ( GetDvar( "r_reflectionProbeGenerate" ) == "1" )
	{
		level.stop_load = true;
		level waittill( "eternity" );
	}
	#/

	/#
	if ( string_starts_with( level.script, "so_" ) )
	{
		AssertEx( is_specialop(), "Attempted to run a Special Op, but not in Special Ops mode. Probably need to add +set specialops 1 to Launcher Custom Command Line Options (launcher should do this automatically)." );
		AssertEx( IsDefined( level.so_pre_sp_load ), "Special Ops " + level.script + " gsc called _load::main() instead of _load_so::main()" );
	}
	
	if ( string_starts_with( level.script, "so_survival" ) && !is_survival() )
	{
		AssertMsg( "Attempted to run a Special Op Survival Map, but not in Survival mode. Probably need to add +set so_survival 1 to Launcher Custom Command Line Options (launcher should do this automatically)." );
	}
	#/
	
	maps\_names::setup_names();

	if( isdefined( level.handle_starts_endons ) )
		thread [[ level.handle_starts_endons ]]();
	else
		thread handle_starts();
	
	/#
		thread maps\_debug::mainDebug();
	#/

	if ( !isdefined( level.trigger_flags ) )
	{
		// may have been defined by AI spawning
		init_trigger_flags();
	}

	level.killspawn_groups = [];

	// init_audio - should be before triggers since it requires audio level vars
	maps\_audio::init_audio();

	maps\_trigger::init_script_triggers();

	SetSavedDvar( "ufoHitsTriggers", "0" );

	//don't go past here on no_game start
	do_no_game_start();

	if ( GetDvar( "g_connectpaths" ) == "2" )
	{
		/# PrintLn( "g_connectpaths == 2; halting script execution" ); #/
		level waittill( "eternity" );
	}

	PrintLn( "level.script: ", level.script );

	maps\_autosave::main();
	
	if ( !isdefined( level.animSounds ) )
		thread init_animSounds();
	maps\_anim::init();
	
	// lagacy... necessary?
	anim.useFacialAnims = false;

	if ( !isdefined( level.MissionFailed ) )
		level.MissionFailed = false;

	if( !is_specialop() )
	{
		maps\_loadout::init_loadout();
		// JC-ToDo: Potentially move this into _loadout::init_loadout(), right now it happens hear and in _load_so:main() after load out set
		SetSavedDvar( "ui_campaign", level.campaign );// level.campaign is set in maps\_loadout::init_loadout
	}
	
	common_scripts\_destructible::init();
	thread maps\_vehicle::init_vehicles();
	SetObjectiveTextColors();

	common_scripts\_dynamic_world::init();

	//thread devhelp();// disabled due to localization errors
	
	thread maps\_autosave::beginningOfLevelSave();
	thread maps\_introscreen::main();
	thread maps\_endmission::main();
	thread maps\_damagefeedback::init();
	maps\_friendlyfire::main();

	// For _anim to track what animations have been used. Uncomment this locally if you need it.
// 	thread usedAnimations();

	array_levelthread( GetEntArray( "badplace", "targetname" ), ::badplace_think );
	array_levelthread( GetEntArray( "delete_on_load", "targetname" ), ::deleteEnt );
	array_thread( GetNodeArray( "traverse", "targetname" ), ::traverseThink );
	/# array_thread( GetNodeArray( "deprecated_traverse", "targetname" ), ::deprecatedTraverseThink ); #/
	array_thread( GetEntArray( "piano_key", "targetname" ), ::pianoThink );
	array_thread( GetEntArray( "piano_damage", "targetname" ), ::pianoDamageThink );
	array_thread( GetEntArray( "water", "targetname" ), ::waterThink );
	array_thread( GetEntArray( "kill_all_players", "targetname" ), ::kill_all_players_trigger );

	flag_init( "allow_ammo_pickups" );
	flag_set( "allow_ammo_pickups" );

	array_thread( GetEntArray( "ammo_pickup_grenade_launcher", "targetname" ), ::ammo_pickup, "grenade_launcher" );
	array_thread( GetEntArray( "ammo_pickup_rpg", "targetname" ), ::ammo_pickup, "rpg" );
	array_thread( GetEntArray( "ammo_pickup_c4", "targetname" ), ::ammo_pickup, "c4" );
	array_thread( GetEntArray( "ammo_pickup_claymore", "targetname" ), ::ammo_pickup, "claymore" );
	array_thread( GetEntArray( "ammo_pickup_556", "targetname" ), ::ammo_pickup, "556" );
	array_thread( GetEntArray( "ammo_pickup_762", "targetname" ), ::ammo_pickup, "762" );
	array_thread( GetEntArray( "ammo_pickup_45", "targetname" ), ::ammo_pickup, "45" );
	array_thread( GetEntArray( "ammo_pickup_pistol", "targetname" ), ::ammo_pickup, "pistol" );

	thread maps\_intelligence::main();

	thread maps\_gameskill::playerHealthRegenInit();

	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[ i ];
		if ( ! ( in_alien_mode() ) )
		{
			player thread maps\_gameskill::playerHealthRegen();
		}
		player thread playerDamageRumble();
	}

	thread maps\_player_death::main();

	// this has to come before _spawner moves the turrets around
	thread massNodeInitFunctions();

	// Various newvillers globalized scripts
	flag_init( "spawning_friendlies" );
	flag_init( "friendly_wave_spawn_enabled" );
	flag_clear( "spawning_friendlies" );

	level.friendly_spawner[ "rifleguy" ] = GetEntArray( "rifle_spawner", "script_noteworthy" );
	level.friendly_spawner[ "smgguy" ] = GetEntArray( "smg_spawner", "script_noteworthy" );
	level.spawn_funcs = [];
	level.spawn_funcs[ "allies" ] = [];
	level.spawn_funcs[ "axis" ] = [];
	level.spawn_funcs[ "team3" ] = [];
	level.spawn_funcs[ "neutral" ] = [];
	thread maps\_spawner::goalVolumes();
	thread maps\_spawner::friendlyChains();
	thread maps\_spawner::friendlychain_onDeath();

// 	array_thread( GetEntArray( "ally_spawn", "targetname" ), maps\_spawner::squadThink );
	array_thread( GetEntArray( "friendly_spawn", "targetname" ), maps\_spawner::friendlySpawnWave );
	array_thread( GetEntArray( "flood_and_secure", "targetname" ), maps\_spawner::flood_and_secure );


	array_thread( GetEntArray( "window_poster", "targetname" ), ::window_destroy );


	if ( !isdefined( level.trigger_hint_string ) )
	{
		level.trigger_hint_string = [];
		level.trigger_hint_func = [];
	}

	level.shared_portable_turrets = [];
	level.spawn_groups = [];
	maps\_spawner::main();

	// for cobrapilot extended visible distance and potentially others, stretch that horizon! - nate
	// origin of prefab is copied manually by LD to brushmodel contained in the prefab, no real way to automate this AFAIK
	array_thread( GetEntArray( "background_block", "targetname" ), ::background_block );

	maps\_hud::init();
	// maps\_hud_weapons::init();

	thread load_friendlies();

	thread maps\_animatedmodels::main();
	
	// Old way of using Chickens, see destructibles
	//thread maps\_cagedchickens::initChickens();

	thread weapon_ammo();
	
	// set has-played-SP when player plays the frist level in the game for the first time.
	assert( isdefined( level.missionsettings ) && isdefined( level.missionsettings.levels ) );
	assert( isdefined( level.script ) );
	
	if ( level.script == level.missionsettings.levels[0].name && !( level.player getLocalPlayerProfileData( "hasEverPlayed_SP" ) ) )
	{
		level.player SetLocalPlayerProfileData( "hasEverPlayed_SP", true );
		UpdateGamerProfile();
	}
	
	level notify ( "load_finished" );
	run_post_function();
}

run_post_function()
{
	if ( IsDefined( level.post_load_funcs ) )
		foreach ( func in level.post_load_funcs )
			[[ func ]]();
}

set_early_level()
{
	level.early_level = [];
	level.early_level[ "intro" ] = true;
	level.early_level[ "sp_ny_harbor" ] = true;
	level.early_level[ "sp_ny_manhattan" ] = true;
	level.early_level[ "warlord" ] = true;
	level.early_level[ "london" ] = true;
}

setup_simple_primary_lights()
{
	flickering_lights = GetEntArray( "generic_flickering", "targetname" );
	pulsing_lights = GetEntArray( "generic_pulsing", "targetname" );
	double_strobe = GetEntArray( "generic_double_strobe", "targetname" );
	burning_trash_fire = GetEntArray( "burning_trash_fire", "targetname" );

	array_thread( flickering_lights, maps\_lights::generic_flickering );
	array_thread( pulsing_lights, maps\_lights::generic_pulsing );
	array_thread( double_strobe, maps\_lights::generic_double_strobe );
	array_thread( burning_trash_fire, maps\_lights::burning_trash_fire );
}

weapon_ammo()
{
	ents = GetEntArray();
	for ( i = 0; i < ents.size; i++ )
	{
		if ( ( IsDefined( ents[ i ].classname ) ) && ( GetSubStr( ents[ i ].classname, 0, 7 ) == "weapon_" ) )
		{
			weap = ents[ i ];
			
			weaponName = GetSubStr( weap.classname, 7 );

			// if we're maxing everything out, do that and earlyout
			if ( IsDefined( weap.script_ammo_max ) )
			{
				clip = WeaponClipSize( weaponName );
				reserve = WeaponMaxAmmo( weaponName );

				weap ItemWeaponSetAmmo( clip, reserve, clip, 0 ); // primary mode
				
				altWeaponName = WeaponAltWeaponName( weaponName );
				if( altWeaponName != "none" )
				{
					altclip = WeaponClipSize( altWeaponName );
					altreserve = WeaponMaxAmmo( altWeaponName );
					weap ItemWeaponSetAmmo( altclip, altreserve, altclip, 1 ); // altmode
				}

				continue;
			}

			change_ammo = false;
			clip = undefined;
			extra = undefined;

			change_alt_ammo = false;
			alt_clip = undefined;
			alt_extra = undefined;

			if ( IsDefined( weap.script_ammo_clip ) )
			{
				clip = weap.script_ammo_clip;
				change_ammo = true;
			}
			if ( IsDefined( weap.script_ammo_extra ) )
			{
				extra = weap.script_ammo_extra;
				change_ammo = true;
			}

			if ( IsDefined( weap.script_ammo_alt_clip ) )
			{
				alt_clip = weap.script_ammo_alt_clip;
				change_alt_ammo = true;
			}
			if ( IsDefined( weap.script_ammo_alt_extra ) )
			{
				alt_extra = weap.script_ammo_alt_extra;
				change_alt_ammo = true;
			}

			if ( change_ammo )
			{
				if ( !isdefined( clip ) )
					AssertMsg( "weapon: " + weap.classname + " " + weap.origin + " sets script_ammo_extra but not script_ammo_clip" );
				if ( !isdefined( extra ) )
					AssertMsg( "weapon: " + weap.classname + " " + weap.origin + " sets script_ammo_clip but not script_ammo_extra" );

				weap ItemWeaponSetAmmo( clip, extra );
			}

			if ( change_alt_ammo )
			{
				if ( !isdefined( alt_clip ) )
					AssertMsg( "weapon: " + weap.classname + " " + weap.origin + " sets script_ammo_alt_extra but not script_ammo_alt_clip" );
				if ( !isdefined( alt_extra ) )
					AssertMsg( "weapon: " + weap.classname + " " + weap.origin + " sets script_ammo_alt_clip but not script_ammo_alt_extra" );

				weap ItemWeaponSetAmmo( alt_clip, alt_extra, 0, 1 );
			}
		}
	}
}

/#
star( total )
{
	PrintLn( "         " );
	PrintLn( "         " );
	PrintLn( "         " );
	for ( i = 0; i < total; i++ )
	{
		for ( z = total - i; z > 1; z-- )
			Print( " " );
		Print( "*" );
		for ( z = 0; z < i; z++ )
			Print( "**" );
		PrintLn( "" );
	}
	for ( i = total - 2; i > -1; i-- )
	{
		for ( z = total - i; z > 1; z-- )
		Print( " " );
		Print( "*" );
		for ( z = 0; z < i; z++ )
			Print( "**" );
		PrintLn( "" );
	}

	PrintLn( "         " );
	PrintLn( "         " );
	PrintLn( "         " );
}
#/


exploder_load( trigger )
{
	level endon( "killexplodertridgers" + trigger.script_exploder );
	trigger waittill( "trigger" );
	if ( IsDefined( trigger.script_chance ) && RandomFloat( 1 ) > trigger.script_chance )
	{
		if ( !trigger script_delay() )
			wait 4;

		level thread exploder_load( trigger );
		return;
	}

	if ( !trigger script_delay() && IsDefined( trigger.script_exploder_delay ) )
	{
		wait( trigger.script_exploder_delay );
	}

	exploder( trigger.script_exploder );
	level notify( "killexplodertridgers" + trigger.script_exploder );
}

//usedAnimations()
//{
//	SetDvar( "usedanim", "" );
//	while ( 1 )
//	{
//		if ( GetDvar( "usedanim" ) == "" )
//		{
//			wait( 2 );
//			continue;
//		}
//
//		animname = GetDvar( "usedanim" );
//		SetDvar( "usedanim", "" );
//
//		if ( !isdefined( level.completedAnims[ animname ] ) )
//		{
//			PrintLn( "^d -- -- No anims for ", animname, "^d -- -- -- -- -- - " );
//			continue;
//		}
//
//		PrintLn( "^d -- -- Used animations for ", animname, "^d: ", level.completedAnims[ animname ].size, "^d -- -- -- -- -- - " );
//		for ( i = 0; i < level.completedAnims[ animname ].size; i++ )
//			PrintLn( level.completedAnims[ animname ][ i ] );
//	}
//}


badplace_think( badplace )
{
	if ( !isdefined( level.badPlaces ) )
		level.badPlaces = 0;

	level.badPlaces++;
	BadPlace_Cylinder( "badplace" + level.badPlaces, -1, badplace.origin, badplace.radius, 1024 );
}


//nearAIRushesPlayer()
//{
//	if ( IsAlive( level.enemySeekingPlayer ) )
//		return;
//	enemy = get_closest_ai( level.player.origin, "bad_guys" );
//	if ( !isdefined( enemy ) )
//		return;
//
//	if ( Distance( enemy.origin, level.player.origin ) > 400 )
//		return;
//
//	level.enemySeekingPlayer = enemy;
//	enemy SetGoalEntity( level.player );
//	enemy.goalradius = 512;
//
//}


playerDamageRumble()
{
	while ( true )
	{
		self waittill( "damage", amount );

		if ( IsDefined( self.specialDamage ) )
			continue;

		self PlayRumbleOnEntity( "damage_heavy" );
	}
}

map_is_early_in_the_game()
{
	/#
	if ( IsDefined( level.map_without_loadout ) )
		return true;
	#/

	if ( IsDefined( level.early_level[ level.script ] ) )
		return level.early_level[ level.script ];
	else
		return false;
}

traverseThink()
{
	ent = GetEnt( self.target, "targetname" );
	self.traverse_height = ent.origin[ 2 ];
	self.traverse_height_delta = ent.origin[ 2 ] - self.origin[2];
	ent Delete();
}

/#
deprecatedTraverseThink()
{
	wait .05;
	PrintLn( "^1Warning: deprecated traverse used in this map somewhere around " + self.origin );
	if ( GetDvarInt( "scr_traverse_debug" ) )
	{
		while ( 1 )
		{
			Print3d( self.origin, "deprecated traverse!" );
			wait .05;
		}
	}
}
#/

pianoDamageThink()
{
	org = self GetOrigin();
	// 
// 	self SetHintString( &"SCRIPT_PLATFORM_PIANO" );
	note[ 0 ] = "large";
	note[ 1 ] = "small";
	for ( ;; )
	{
		self waittill( "trigger" );
		thread play_sound_in_space( "bullet_" + random( note ) + "_piano", org );
	}
}

pianoThink()
{
	org = self GetOrigin();
	note = "piano_" + self.script_noteworthy;
	// 
	self SetHintString( &"SCRIPT_PLATFORM_PIANO" );
	for ( ;; )
	{
		self waittill( "trigger" );
		thread play_sound_in_space( note, org );
	}
}

waterThink()
{
	Assert( IsDefined( self.target ) );
	targeted = GetEnt( self.target, "targetname" );
	Assert( IsDefined( targeted ) );
	waterHeight = targeted.origin[ 2 ];
	targeted = undefined;

	level.depth_allow_prone = 8;
	level.depth_allow_crouch = 33;
	level.depth_allow_stand = 50;
	
	wasInWater = false;
	//prof_begin( "water_stance_controller" );

	for ( ;; )
	{
		wait 0.05;
		// restore all defaults
		if ( !level.player.inWater && wasInWater )
		{
			wasInWater = false;
			level.player AllowProne( true );
			level.player AllowCrouch( true );
			level.player AllowStand( true );
			thread waterThink_rampSpeed( level.default_run_speed );
		}

		// wait until in water
		self waittill( "trigger" );
		level.player.inWater = true;
		wasInWater = true;
		while ( level.player IsTouching( self ) )
		{
			level.player.inWater = true;
			playerOrg = level.player GetOrigin();
			d = ( playerOrg[ 2 ] - waterHeight );
			if ( d > 0 )
				break;

			// slow the players movement based on how deep it is
			newSpeed = Int( level.default_run_speed - abs( d * 5 ) );
			if ( newSpeed < 50 )
				newSpeed = 50;
			Assert( newSpeed <= 190 );
			thread waterThink_rampSpeed( newSpeed );

			// controll the allowed stances in this water height
			if ( abs( d ) > level.depth_allow_crouch )
				level.player AllowCrouch( false );
			else
				level.player AllowCrouch( true );

			if ( abs( d ) > level.depth_allow_prone )
				level.player AllowProne( false );
			else
				level.player AllowProne( true );

			wait 0.5;
		}
		level.player.inWater = false;
		wait 0.05;
	}

	//prof_end( "water_stance_controller" );
}

waterThink_rampSpeed( newSpeed )
{
	level notify( "ramping_water_movement_speed" );
	level endon( "ramping_water_movement_speed" );

	rampTime = 0.5;
	numFrames = Int( rampTime * 20 );

	currentSpeed = GetDvarInt( "g_speed" );

	qSlower = false;
	if ( newSpeed < currentSpeed )
		qSlower = true;

	speedDifference = Int( abs( currentSpeed - newSpeed ) );
	speedStepSize = Int( speedDifference / numFrames );

	for ( i = 0; i < numFrames; i++ )
	{
		currentSpeed = GetDvarInt( "g_speed" );
		if ( qSlower )
			SetSavedDvar( "g_speed", ( currentSpeed - speedStepSize ) );
		else
			SetSavedDvar( "g_speed", ( currentSpeed + speedStepSize ) );
		wait 0.05;
	}
	SetSavedDvar( "g_speed", newSpeed );
}



massNodeInitFunctions()
{
	nodes = GetAllNodes();

	thread maps\_mgturret::auto_mgTurretLink( nodes );
	thread maps\_mgturret::saw_mgTurretLink( nodes );
	thread maps\_colors::init_color_grouping( nodes );
}

indicate_start( start )
{
	hudelem = NewHudElem();
	hudelem.alignX = "left";
	hudelem.alignY = "middle";
	hudelem.x = 10;
	hudelem.y = 400;
//	hudelem.label = "Loading from start: " + start;
	hudelem SetText( start );
	hudelem.alpha = 0;
	hudelem.fontScale = 3;
	wait( 1 );
	hudelem FadeOverTime( 1 );
	hudelem.alpha = 1;
	wait( 5 );
	hudelem FadeOverTime( 1 );
	hudelem.alpha = 0;
	wait( 1 );
	hudelem Destroy();
}

handle_starts()
{
	level.start_struct = SpawnStruct();
	create_dvar( "start", "" );

	if ( GetDvar( "scr_generateClipModels" ) != "" && GetDvar( "scr_generateClipModels" ) != "0" )
		return;// shortcut for generating clipmodels gah.

 	if ( !isdefined( level.start_functions ) )
		level.start_functions = [];

/#
	PrecacheMenu( "start" );
#/

	AssertEx( GetDvar( "jumpto" ) == "", "Use the START dvar instead of JUMPTO" );

	start = ToLower( GetDvar( "start" ) );

	// find the start that matches the one the dvar is set to, and execute it
	dvars = get_start_dvars();
	
/*
=============
///ScriptFieldDocBegin
"Name: .start_point"
"Summary: The current start point being used"
"Module: load"
"SPMP: singleplayer"
///ScriptDocEnd
=============
*/		

	if ( IsDefined( level.start_point ) )
		start = level.start_point;
	
	// first try to find the start based on the dvar
	start_index = 0;
	for ( i = 0; i < dvars.size; i++ )
	{
		if ( start == dvars[ i ] )
		{
			start_index = i;
			level.start_point = dvars[ i ];
			break;
		}
	}

	// then try based on the override
	if ( IsDefined( level.default_start_override ) && !isdefined( level.start_point ) )
	{
		foreach ( index, dvar in dvars )
		{
			if ( level.default_start_override == dvar )
			{
				start_index = index;
				level.start_point = dvar;
				break;
			}
		}
	}

	if ( !isdefined( level.start_point ) )
	{
		// was a start set with default_start()?
		if ( IsDefined( level.default_start ) )
			level.start_point = "default";
		else
		if ( level_has_start_points() )
			level.start_point = level.start_functions[ 0 ][ "name" ];
		else
			level.start_point = "default";
	}
	
	if ( level.start_point != "default" )
	{
		start_array = level.start_arrays[ level.start_point ];
		if ( IsDefined( start_array[ "transient" ] ) )
		{
			LoadStartPointTransient( start_array[ "transient" ] );
			flag_set( start_array[ "transient" ] + "_loaded" );
		}
		else
			LoadStartPointTransient( "" );
	}
	else
		LoadStartPointTransient( "" );

	waittillframeend;// starts happen at the end of the first frame, so threads in the mission have a chance to run and init stuff
	
	flag_set( "start_is_set" );
	thread start_menu();

	if ( level.start_point == "default" )
	{
		if ( IsDefined( level.default_start ) )
		{
			level thread [[ level.default_start ]]();
		}

	}
	else
	{
		start_array = level.start_arrays[ level.start_point ];
        
		/#
		if ( IsDefined( start_array[ "start_loc_string" ] ) )
			thread indicate_start( start_array[ "start_loc_string" ] );
		else
			thread indicate_start( level.start_point );
		#/
		thread [[ start_array[ "start_func" ] ]]();
	}

	if ( is_default_start() )
	{
		string = get_string_for_starts( dvars );
		SetDvar( "start", string );
	}

	waittillframeend;// let the frame finish for all ai init type stuff that goes on in start points

	previously_run_logic_functions = [];
	// run each logic function in order
	for ( i = start_index; i < level.start_functions.size; i++ )
	{
		start_array = level.start_functions[ i ];
		if ( !isdefined( start_array[ "logic_func" ] ) )
			continue;

		if ( already_ran_function( start_array[ "logic_func" ], previously_run_logic_functions ) )
			continue;

		level.start_struct [[ start_array[ "logic_func" ] ]]();
		previously_run_logic_functions[ previously_run_logic_functions.size ] = start_array[ "logic_func" ];
	}
}

already_ran_function( func, previously_run_logic_functions )
{
	foreach ( logic_function in previously_run_logic_functions )
	{
		if ( logic_function == func )
			return true;
	}
	return false;
}

get_string_for_starts( dvars )
{
	string = " ** No starts have been set up for this map with maps\_utility::add_start().";
	if ( dvars.size )
	{
		string = " ** ";
		for ( i = dvars.size - 1; i >= 0; i-- )
		{
			string = string + dvars[ i ] + " ";
		}
	}

	SetDvar( "start", string );
	return string;
}


create_start( start, index )
{
	alpha = 1;
	color = ( 0.9, 0.9, 0.9 );
	if ( index != -1 )
	{
		middle = 5;
		if ( index != middle )
		{
			alpha = 1 - ( abs( middle - index ) / middle );
		}
		else
		{
			color = ( 1, 1, 0 );
		}
	}

	if ( alpha == 0 )
	{
		alpha = 0.05;
	}

	hudelem = NewHudElem();
	hudelem.alignX = "left";
	hudelem.alignY = "middle";
	hudelem.x = 80;
	hudelem.y = 80 + index * 18;
	hudelem SetText( start );
	hudelem.alpha = 0;
	hudelem.foreground = true;
	hudelem.color = color;

	hudelem.fontScale = 1.75;
	hudelem FadeOverTime( 0.5 );
	hudelem.alpha = alpha;
	return hudelem;
}

start_menu()
{
/#

	for ( ;; )
	{
		if ( GetDvarInt( "debug_start" ) )
		{
			SetDevDvar( "debug_start", 0 );
			SetSavedDvar( "hud_drawhud", 1 );
			display_starts();
		}
		else
		{
			level.display_starts_Pressed = false;
		}
		wait( 0.05 );
	}
#/
}

start_nogame()
{
	//empty.. this start for when you want to play without playing. for viewing geo maybe?
	array_call( GetAIArray(), ::Delete );
	array_call( GetSpawnerArray(), ::Delete );
	//array_call( GetEntArray( "trigger_multiple", "code_classname" ), ::Delete );
	//array_call( GetEntArray( "trigger_radius", "code_classname" ), ::Delete );
	
}

get_start_dvars()
{
	dvars = [];
	for ( i = 0; i < level.start_functions.size; i++ )
	{
		dvars[ dvars.size ] = level.start_functions[ i ][ "name" ];
	}
	return dvars;
}

display_starts()
{
	level.display_starts_Pressed = true;
	if ( level.start_functions.size <= 0 )
		return;

	dvars = get_start_dvars();
	dvars[ dvars.size ] = "default";
	dvars[ dvars.size ] = "cancel";

//	dvars = array_reverse( dvars );
	elems = start_list_menu();
	
	// Available Starts:
	title = create_start( "Selected Start:", -1 );
	title.color = ( 1, 1, 1 );
	strings = [];

	for ( i = 0; i < dvars.size; i++ )
	{
		dvar = dvars[ i ];
		start_string = "[" + dvars[ i ] + "]";
	

	    if( dvar != "cancel" && dvar != "default" )
		{
    		if (IsDefined( level.start_arrays[ dvar ][ "start_loc_string" ] ) )
    		{
    			start_string += " -> ";
    			start_string += level.start_arrays[ dvar ][ "start_loc_string" ];
    		}
		}

		strings[ strings.size ] = start_string;
//		elems[ elems.size ] = create_start( start_string, dvars.size - i );
	}

	selected = dvars.size - 1;
	up_pressed = false;
	down_pressed = false;
	
	found_current_start = false;
	
	while( selected > 0 )
	{
	    if( dvars[ selected ] == level.start_point )
	    {
	        found_current_start = true;
	        break;
	    }
	    selected--;
	}
	
	if( !found_current_start )
	{
	    selected = dvars.size - 1;
	}

	start_list_settext( elems, strings, selected );
	old_selected = selected;
	
	for ( ;; )
	{
		if ( !( level.player ButtonPressed( "F10" ) ) )
		{
			level.display_starts_Pressed = false;

		}

		if ( old_selected != selected )
		{		
			start_list_settext( elems, strings, selected );
			old_selected = selected;
		}

		if ( !up_pressed )
		{
			if ( level.player ButtonPressed( "UPARROW" ) || level.player ButtonPressed( "DPAD_UP" ) || level.player ButtonPressed( "APAD_UP" ) )
			{
				up_pressed = true;
				selected--;
			}
		}
		else
		{
			if ( !level.player ButtonPressed( "UPARROW" ) && !level.player ButtonPressed( "DPAD_UP" ) && !level.player ButtonPressed( "APAD_UP" ) )
			{
				up_pressed = false;
			}
		}


		if ( !down_pressed )
		{
			if ( level.player ButtonPressed( "DOWNARROW" ) || level.player ButtonPressed( "DPAD_DOWN" ) || level.player ButtonPressed( "APAD_DOWN" ) )
			{
				down_pressed = true;
				selected++;
			}
		}
		else
		{
			if ( !level.player ButtonPressed( "DOWNARROW" ) && !level.player ButtonPressed( "DPAD_DOWN" ) && !level.player ButtonPressed( "APAD_DOWN" ) )
			{
				down_pressed = false;
			}
		}

		if ( selected < 0 )
		{
			selected = dvars.size - 1;
		}

		if ( selected >= dvars.size )
		{
			selected = 0;
		}

		if ( level.player ButtonPressed( "BUTTON_B" ) )
		{
			start_display_cleanup( elems, title );
			break;
		}

		if ( level.player ButtonPressed( "kp_enter" ) || level.player ButtonPressed( "BUTTON_A" ) || level.player ButtonPressed( "enter" ) )
		{
			if ( dvars[ selected ] == "cancel" )
			{
				start_display_cleanup( elems, title );
				break;
			}


			SetDvar( "start", dvars[ selected ] );
			level.player OpenPopupMenu( "start" );
//			ChangeLevel( level.script, false );
		}
		wait( 0.05 );
	}
}

start_list_menu()
{
	hud_array = [];
	for ( i = 0; i < 11; i++ )
	{
		hud = create_start( "", i );
		hud_array[ hud_array.size ] = hud;
	}

	return hud_array;
}

start_list_settext( hud_array, strings, num )
{
	for ( i = 0; i < hud_array.size; i++ )
	{
		index = i + ( num - 5 );
		if ( IsDefined( strings[ index ] ) )
		{
			text = strings[ index ];
		}
		else
		{
			text = "";
		}

		hud_array[ i ] SetText( text );
	}

}

start_display_cleanup( elems, title )
{
	title Destroy();
	for ( i = 0; i < elems.size; i++ )
	{
		elems[ i ] Destroy();
	}
}

//devhelp_hudElements( hudarray, alpha )
//{
//	for ( i = 0; i < hudarray.size; i++ )
//		for ( p = 0; p < 5; p++ )
//			hudarray[ i ][ p ].alpha = alpha;
//
//}
//
//devhelp()
//{
//	/#
//	helptext = [];
//	helptext[ helptext.size ] = "P: pause                                                       ";
//	helptext[ helptext.size ] = "T: super speed                                                 ";
//	helptext[ helptext.size ] = ".: fullbright                                                  ";
//	helptext[ helptext.size ] = "U: toggle normal maps                                          ";
//	helptext[ helptext.size ] = "Y: print a line of text, useful for putting it in a screenshot ";
//	helptext[ helptext.size ] = "H: toggle detailed ent info                                    ";
//	helptext[ helptext.size ] = "g: toggle simplified ent info                                  ";
//	helptext[ helptext.size ] = ", : show the triangle outlines                                  ";
//	helptext[ helptext.size ] = " - : Back 10 seconds                                             ";
//	helptext[ helptext.size ] = "6: Replay mark                                                 ";
//	helptext[ helptext.size ] = "7: Replay goto                                                 ";
//	helptext[ helptext.size ] = "8: Replay live                                                 ";
//	helptext[ helptext.size ] = "0: Replay back 3 seconds                                       ";
//	helptext[ helptext.size ] = "[ : Replay restart                                              ";
//	helptext[ helptext.size ] = "\: map_restart                                                 ";
//	helptext[ helptext.size ] = "U: draw material name                                          ";
//	helptext[ helptext.size ] = "J: display tri counts                                          ";
//	helptext[ helptext.size ] = "B: cg_ufo                                                      ";
//	helptext[ helptext.size ] = "N: ufo                                                         ";
//	helptext[ helptext.size ] = "C: god                                                         ";
//	helptext[ helptext.size ] = "K: Show ai nodes                                               ";
//	helptext[ helptext.size ] = "L: Show ai node connections                                    ";
//	helptext[ helptext.size ] = "Semicolon: Show ai pathing                                     ";
//
//
//	strOffsetX = [];
//	strOffsetY = [];
//	strOffsetX[ 0 ] = 0;
//	strOffsetY[ 0 ] = 0;
//	strOffsetX[ 1 ] = 1;
//	strOffsetY[ 1 ] = 1;
//	strOffsetX[ 2 ] = -2;
//	strOffsetY[ 2 ] = 1;
//	strOffsetX[ 3 ] = 1;
//	strOffsetY[ 3 ] = -1;
//	strOffsetX[ 4 ] = -2;
//	strOffsetY[ 4 ] = -1;
//	hudarray = [];
//	for ( i = 0; i < helptext.size; i++ )
//	{
//		newStrArray = [];
//		for ( p = 0; p < 5; p++ )
//		{
//			// setup instructional text
//			newStr = NewHudElem();
//			newStr.alignX = "left";
//			newStr.location = 0;
//			newStr.foreground = 1;
//			newStr.fontScale = 1.30;
//			newStr.sort = 20 - p;
//			newStr.alpha = 1;
//			newStr.x = 54 + strOffsetX[ p ];
//			newStr.y = 80 + strOffsetY[ p ] + i * 15;
//			newstr SetText( helptext[ i ] );
//			if ( p > 0 )
//				newStr.color = ( 0, 0, 0 );
//
//			newStrArray[ newStrArray.size ] = newStr;
//		}
//		hudarray[ hudarray.size ] = newStrArray;
//	}
//
//	devhelp_hudElements( hudarray, 0 );
//
//	while ( 1 )
//	{
//		update = false;
//		if ( level.player ButtonPressed( "F1" ) )
//		{
//				devhelp_hudElements( hudarray, 1 );
//				while ( level.player ButtonPressed( "F1" ) )
//					wait .05;
//		}
//		devhelp_hudElements( hudarray, 0 );
//		wait .05;
//	}
//	#/
//}

background_block()
{
	Assert( IsDefined( self.script_bg_offset ) );
	self.origin -= self.script_bg_offset;
}


set_player_viewhand_model( viewhandModel )
{
	Assert( !isdefined( level.player_viewhand_model ) );	// only set this once per level
	AssertEx( IsSubStr( viewhandModel, "player" ), "Must set with viewhands_player_*" );
	level.player_viewhand_model = viewhandModel;
	PreCacheModel( level.player_viewhand_model );
}


 /*
rpg_aim_assist()
{
	level.player endon( "death" );
	for ( ;; )
	{
		level.player waittill( "weapon_fired" );
		currentweapon = level.player GetCurrentWeapon();
		if ( ( currentweapon == "rpg" ) || ( currentweapon == "rpg_player" ) )
			thread rpg_aim_assist_attractor();
	}
}

rpg_aim_assist_attractor()
{
	prof_begin( "rpg_aim_assist" );

	// Trace to where the player is looking
	start = level.player GetEye();
	direction = level.player GetPlayerAngles();
	coord = BulletTrace( start, start + vector_multiply( AnglesToForward( direction ), 15000 ), true, level.player )[ "position" ];

	thread draw_line_for_time( level.player.origin, coord, 1, 0, 0, 10000 );

	prof_end( "rpg_aim_assist" );

	attractor = Missile_CreateAttractorOrigin( coord, 10000, 3000 );
	wait 3.0;
	Missile_DeleteAttractor( attractor );
}
*/

SetObjectiveTextColors()
{
	// The darker the base color, the more-readable the text is against a stark-white backdrop.
	// However; this sacrifices the "white-hot"ness of the text against darker backdrops.

	MY_TEXTBRIGHTNESS_DEFAULT = "1.0 1.0 1.0";
	MY_TEXTBRIGHTNESS_90 = "0.9 0.9 0.9";
	MY_TEXTBRIGHTNESS_85 = "0.85 0.85 0.85";

	SetSavedDvar( "con_typewriterColorBase", MY_TEXTBRIGHTNESS_DEFAULT );
}

ammo_pickup( sWeaponType )
{
	// possible weapons that the player could have that get this type of ammo
	validWeapons = [];
	if ( sWeaponType == "grenade_launcher" )
	{
		validWeapons[ validWeapons.size ] = "alt_m4_grenadier";
		validWeapons[ validWeapons.size ] = "alt_m4m203_acog";
		validWeapons[ validWeapons.size ] = "alt_m4m203_acog_payback";
		validWeapons[ validWeapons.size ] = "alt_m4m203_eotech";
		validWeapons[ validWeapons.size ] = "alt_m4m203_motion_tracker";
		validWeapons[ validWeapons.size ] = "alt_m4m203_reflex";
		validWeapons[ validWeapons.size ] = "alt_m4m203_reflex_arctic";
		validWeapons[ validWeapons.size ] = "alt_m4m203_silencer";
		validWeapons[ validWeapons.size ] = "alt_m4m203_silencer_reflex";
		validWeapons[ validWeapons.size ] = "alt_m16_grenadier";
		validWeapons[ validWeapons.size ] = "alt_ak47_grenadier";
		validWeapons[ validWeapons.size ] = "alt_ak47_desert_grenadier";
		validWeapons[ validWeapons.size ] = "alt_ak47_digital_grenadier";
		validWeapons[ validWeapons.size ] = "alt_ak47_fall_grenadier";
		validWeapons[ validWeapons.size ] = "alt_ak47_woodland_grenadier";
	}
	else if ( sWeaponType == "rpg" )
	{
		validWeapons[ validWeapons.size ] = "rpg";
		validWeapons[ validWeapons.size ] = "rpg_player";
		validWeapons[ validWeapons.size ] = "rpg_straight";
	}
	else if ( sWeaponType == "c4" )
	{
		validWeapons[ validWeapons.size ] = "c4";
	}
	else if ( sWeaponType == "claymore" )
	{
		validWeapons[ validWeapons.size ] = "claymore";
	}
	else if ( sWeaponType == "556" )
	{
		validWeapons[ validWeapons.size ] = "m4_grenadier";
		validWeapons[ validWeapons.size ] = "m4_grunt";
		validWeapons[ validWeapons.size ] = "m4_sd_cloth";
		validWeapons[ validWeapons.size ] = "m4_shotgun";
		validWeapons[ validWeapons.size ] = "m4_silencer";
		validWeapons[ validWeapons.size ] = "m4_silencer_acog";
		validWeapons[ validWeapons.size ] = "m4m203_acog";
		validWeapons[ validWeapons.size ] = "m4m203_acog_payback";
		validWeapons[ validWeapons.size ] = "m4m203_eotech";
		validWeapons[ validWeapons.size ] = "m4m203_motion_tracker";
		validWeapons[ validWeapons.size ] = "m4m203_reflex";
		validWeapons[ validWeapons.size ] = "m4m203_reflex_arctic";
		validWeapons[ validWeapons.size ] = "m4m203_silencer";
		validWeapons[ validWeapons.size ] = "m4m203_silencer_reflex";
		validWeapons[ validWeapons.size ] = "m4m203_silencer";
	}
	else if ( sWeaponType == "762" )
	{
		validWeapons[ validWeapons.size ] = "ak47";
		validWeapons[ validWeapons.size ] = "ak47_acog";
		validWeapons[ validWeapons.size ] = "ak47_eotech";
		validWeapons[ validWeapons.size ] = "ak47_grenadier";
		validWeapons[ validWeapons.size ] = "ak47_reflex";
		validWeapons[ validWeapons.size ] = "ak47_shotgun";
		validWeapons[ validWeapons.size ] = "ak47_silencer";
		validWeapons[ validWeapons.size ] = "ak47_thermal";

		validWeapons[ validWeapons.size ] = "ak47_desert";
		validWeapons[ validWeapons.size ] = "ak47_desert_acog";
		validWeapons[ validWeapons.size ] = "ak47_desert_eotech";
		validWeapons[ validWeapons.size ] = "ak47_desert_grenadier";
		validWeapons[ validWeapons.size ] = "ak47_desert_reflex";

		validWeapons[ validWeapons.size ] = "ak47_digital";
		validWeapons[ validWeapons.size ] = "ak47_digital_acog";
		validWeapons[ validWeapons.size ] = "ak47_digital_eotech";
		validWeapons[ validWeapons.size ] = "ak47_digital_grenadier";
		validWeapons[ validWeapons.size ] = "ak47_digital_reflex";

		validWeapons[ validWeapons.size ] = "ak47_fall";
		validWeapons[ validWeapons.size ] = "ak47_fall_acog";
		validWeapons[ validWeapons.size ] = "ak47_fall_eotech";
		validWeapons[ validWeapons.size ] = "ak47_fall_grenadier";
		validWeapons[ validWeapons.size ] = "ak47_fall_reflex";

		validWeapons[ validWeapons.size ] = "ak47_woodland";
		validWeapons[ validWeapons.size ] = "ak47_woodland_acog";
		validWeapons[ validWeapons.size ] = "ak47_woodland_eotech";
		validWeapons[ validWeapons.size ] = "ak47_woodland_grenadier";
		validWeapons[ validWeapons.size ] = "ak47_woodland_reflex";
	}
	else if ( sWeaponType == "45" )
	{
		validWeapons[ validWeapons.size ] = "ump45";
		validWeapons[ validWeapons.size ] = "ump45_acog";
		validWeapons[ validWeapons.size ] = "ump45_eotech";
		validWeapons[ validWeapons.size ] = "ump45_reflex";
		validWeapons[ validWeapons.size ] = "ump45_silencer";

		validWeapons[ validWeapons.size ] = "ump45_arctic";
		validWeapons[ validWeapons.size ] = "ump45_arctic_acog";
		validWeapons[ validWeapons.size ] = "ump45_arctic_eotech";
		validWeapons[ validWeapons.size ] = "ump45_arctic_reflex";

		validWeapons[ validWeapons.size ] = "ump45_digital";
		validWeapons[ validWeapons.size ] = "ump45_digital_acog";
		validWeapons[ validWeapons.size ] = "ump45_digital_eotech";
		validWeapons[ validWeapons.size ] = "ump45_digital_reflex";
	}
	else if ( sWeaponType == "pistol" )
	{
		validWeapons[ validWeapons.size ] = "beretta";
		validWeapons[ validWeapons.size ] = "beretta393";
		validWeapons[ validWeapons.size ] = "usp";
		validWeapons[ validWeapons.size ] = "usp_scripted";
		validWeapons[ validWeapons.size ] = "usp_silencer";
		validWeapons[ validWeapons.size ] = "glock";
	}

	Assert( validWeapons.size > 0 );

	trig = Spawn( "trigger_radius", self.origin, 0, 25, 32 );

	for ( ;; )
	{
		flag_wait( "allow_ammo_pickups" );

		trig waittill( "trigger", triggerer );

		if ( !flag( "allow_ammo_pickups" ) )
			continue;

		if ( !isdefined( triggerer ) )
			continue;

		if ( !isplayer( triggerer ) )
			continue;

		// check if the player is carrying one of the valid grenade launcher weapons
		weaponToGetAmmo = undefined;
		emptyActionSlotAmmo = undefined;
		weapons = triggerer GetWeaponsListAll();
		for ( i = 0; i < weapons.size; i++ )
		{
			for ( j = 0; j < validWeapons.size; j++ )
			{
				if ( weapons[ i ] == validWeapons[ j ]	 )
					weaponToGetAmmo = weapons[ i ];
			}
		}

		//check if weapon if C4 or claymore and the player has zero of them
		if ( ( !isdefined( weaponToGetAmmo ) ) && ( sWeaponType == "claymore" ) )
		{
			emptyActionSlotAmmo = true;
			weaponToGetAmmo = "claymore";
			break;
		}


		//check if weapon if C4 or claymore and the player has zero of them
		if ( ( !isdefined( weaponToGetAmmo ) ) && ( sWeaponType == "c4" ) )
		{
			emptyActionSlotAmmo = true;
			weaponToGetAmmo = "c4";
			break;
		}

		// no grenade launcher found
		if ( !isdefined( weaponToGetAmmo ) )
			continue;

		// grenade launcher found - check if the player has max ammo already
		if ( triggerer GetFractionMaxAmmo( weaponToGetAmmo ) >= 1 )
			continue;

		// player picks up the ammo
		break;
	}

	// give player one more ammo, play pickup sound, and delete the ammo and trigger
	if ( IsDefined( emptyActionSlotAmmo ) )
		triggerer GiveWeapon( weaponToGetAmmo );	// this will only be for C4 and claymores if the player is totally out of them
	else
	{
		rounds = 1;
		if ( sWeaponType == "556" || sWeaponType == "762" )
		{
			rounds = 30;
		}
		else if ( sWeaponType == "45" )
		{
			rounds = 25;
		}
		else if ( sWeaponType == "pistol" )
		{
			rounds = 15;
		}
		triggerer SetWeaponAmmoStock( weaponToGetAmmo, triggerer GetWeaponAmmoStock( weaponToGetAmmo ) + rounds );
	}

	triggerer PlayLocalSound( "grenade_pickup" );
	trig Delete();

	// usable items might not exist anymore at this point since they are deleted in code on player touch
	if ( IsDefined( self ) )
	{
		self Delete();
	}
}

remove_level_first_frame()
{
	wait( 0.05 );
	level.first_frame = -1;
}

load_friendlies()
{
	if ( IsDefined( game[ "total characters" ] ) )
	{
		game_characters = game[ "total characters" ];
		PrintLn( "Loading Characters: ", game_characters );
	}
	else
	{
		PrintLn( "Loading Characters: None!" );
		return;
	}

	ai = GetAIArray( "allies" );
	total_ai = ai.size;
	index_ai = 0;

	spawners = GetSpawnerTeamArray( "allies" );
	total_spawners = spawners.size;
	index_spawners = 0;

	while ( 1 )
	{
		if ( ( ( total_ai <= 0 ) && ( total_spawners <= 0 ) ) || ( game_characters <= 0 ) )
			return;

		if ( total_ai > 0 )
		{
			if ( IsDefined( ai[ index_ai ].script_friendname ) )
			{
				total_ai--;
				index_ai++;
				continue;
			}

			PrintLn( "Loading character.. ", game_characters );
			ai[ index_ai ] codescripts\character::new();
			ai[ index_ai ] thread codescripts\character::load( game[ "character" + ( game_characters - 1 ) ] );
			total_ai--;
			index_ai++;
			game_characters--;
			continue;
		}

		if ( total_spawners > 0 )
		{
			if ( IsDefined( spawners[ index_spawners ].script_friendname ) )
			{
				total_spawners--;
				index_spawners++;
				continue;
			}

			PrintLn( "Loading character.. ", game_characters );
			info = game[ "character" + ( game_characters - 1 ) ];
			precache( info [ "model" ] );
			precache( info [ "model" ] );
			spawners[ index_spawners ] thread spawn_setcharacter( game[ "character" + ( game_characters - 1 ) ] );
			total_spawners--;
			index_spawners++;
			game_characters--;
			continue;
		}
	}
}

check_flag_for_stat_tracking( msg )
{
	if ( !issuffix( msg, "aa_" ) )
		return;

	[[ level.sp_stat_tracking_func ]]( msg );
}


precache_script_models()
{
	waittillframeend;
	if ( !isdefined( level.scr_model ) )
		return;
	models = GetArrayKeys( level.scr_model );
	for ( i = 0; i < models.size; i++ )
	{
		if ( IsArray( level.scr_model[ models[ i ] ] ) )
		{
			for ( modelIndex = 0; modelIndex < level.scr_model[ models[ i ] ].size; modelIndex++ )
				PreCacheModel( level.scr_model[ models[ i ] ][ modelIndex ] );
		}
		else
			PreCacheModel( level.scr_model[ models[ i ] ] );
	}
}

player_death_detection()
{
	// a dvar starts high then degrades over time whenever the player dies,
	// checked from maps\_utility::player_died_recently()
	SetDvar( "player_died_recently", "0" );
	thread player_died_recently_degrades();

	level add_wait( ::flag_wait, "missionfailed" );
	level.player add_wait( ::waittill_msg, "death" );
	do_wait_any();

	recently_skill = [];
	recently_skill[ 0 ] = 70;
	recently_skill[ 1 ] = 30;
	recently_skill[ 2 ] = 0;
	recently_skill[ 3 ] = 0;

	SetDvar( "player_died_recently", recently_skill[ level.gameskill ] );
}

player_died_recently_degrades()
{
	for ( ;; )
	{
		recent_death_time = GetDvarInt( "player_died_recently", 0 );
		if ( recent_death_time > 0 )
		{
			recent_death_time -= 5;
			SetDvar( "player_died_recently", recent_death_time );
		}
		wait( 5 );
	}
}

//{NOT_IN_SHIP
recon_player()
{
	// for now, only catches where player dies
	self notify("new_recon_player");	// ensure there's only one of these threads alive for each player
	self endon("new_recon_player");
	self waittill( "death", attacker, cause, weaponName );
	if (!isdefined(weaponName))
		weaponName="script_kill";	// script killed the player
	dp = 0;
	attackerclass = "none";
	attackerpos = (0,0,0);
	if (isdefined(attacker))
	{
		attackerclass = attacker.classname;
		attackerpos = attacker.origin;
		player2enemy = VectorNormalize(attackerpos - self.origin);
		forward = AnglesToForward(self GetPlayerAngles());
		dp = VectorDot(player2enemy, forward);
	}
    ReconSpatialEvent( self.origin, "script_player_death: playerid %s, enemy %s, enemyposition %v, enemydotproduct %f, cause %s, weapon %s", self.unique_id, attackerclass, attackerpos, dp, cause, weaponName  );
    if (isdefined(attacker))
    	ReconSpatialEvent( attacker.origin, "script_player_killer: playerid %s, enemy %s, playerposition %v, enemydotproduct %f, cause %s, weapon %s", self.unique_id, attackerclass, self.origin, dp, cause, weaponName  );
    /#
    println("script_player_death: playerid "+self.unique_id+", enemy "+attackerclass+", enemyposition ("+attackerpos[0]+","+attackerpos[1]+","+attackerpos[2]+"), enemydotproduct "+dp+", cause "+cause+", weapon "+weaponName);
    #/
    
    //Blackbox
    bbprint( "kills", "attackername %s attackerteam %s attackerx %f attackery %f attackerz %f attackerweapon %s victimx %f victimy %f victimz %f victimname %s victimteam %s damage %i damagetype %s damagelocation %s attackerisbot %i victimisbot %i timesincespawn %f", attacker.classname, "enemy", attacker.origin[0], attacker.origin[1], attacker.origin[2], weaponName, self.origin[0], self.origin[1], self.origin[2], self.unique_id, "player", 0, cause, "", 1, 0, (GetLevelTicks()*0.05) );
    //Blackbox
}
//}NOT_IN_SHIP

//{NOT_IN_SHIP
recon_player_downed()
{
	self notify("new_player_downed_recon");
	self endon("new_player_downed_recon");
	self endon("death");
	while (true)
	{
		self waittill("player_downed");
		time = GetLevelTicks()*0.05;
		leveltime = time;
		if (isdefined(self.last_downed_time))
			time = leveltime - self.last_downed_time;
		self.last_downed_time = leveltime;
	    ReconSpatialEvent( self.origin, "script_player_downed: playerid %s, leveltime %d, deltatime %d", self.unique_id, leveltime, time );
	    /#
	    println("script_player_downed: "+self.unique_id+" leveltime "+time);
	    #/
	}
}
//}NOT_IN_SHIP


init_level_players()
{
	level.players = GetEntArray( "player", "classname" );
	for ( i = 0; i < level.players.size; i++ )
	{
		level.players[ i ].unique_id = "player" + i;
	}

	level.player = level.players[ 0 ];
	if ( level.players.size > 1 )
		level.player2 = level.players[ 1 ];

	level notify( "level.players initialized" );
	//{NOT_IN_SHIP
	foreach ( player in level.players )
	{
		player thread recon_player();
		if (is_specialop())
			player thread recon_player_downed();	// only needed for specialops maps
	}
	//}NOT_IN_SHIP
}

kill_all_players_trigger()
{
	self waittill( "trigger", player );

	self kill_wrapper();
}


watchWeaponChange()
{
	if ( !isdefined( level.friendly_thermal_Reflector_Effect ) )
		level.friendly_thermal_Reflector_Effect = LoadFX( "fx/misc/thermal_tapereflect_inverted" );
	self endon( "death" );

	//if ( IsSubStr( self GetCurrentWeapon(), "_thermal" ) )
	weap = self GetCurrentWeapon();
	if ( weap_has_thermal( weap ) )
		self thread thermal_tracker();

	while ( 1 )
	{
		self waittill( "weapon_change", newWeapon );

		if ( weap_has_thermal( newWeapon ) )
			self thread thermal_tracker();
		else
			self notify( "acogThermalTracker" );
	}
}

weap_has_thermal( weap )
{
	if ( !isdefined( weap ) )
		return false;
	if ( weap == "none" )
		return false;
	if ( WeaponHasThermalScope( weap ) )
		return true;

	return false;
}

thermal_tracker()
{
	self endon( "death" );

	self notify( "acogThermalTracker" );
	self endon( "acogThermalTracker" );

	curADS = 0;

	for ( ;; )
	{
		lastADS = curADS;
		curADS = self PlayerAds();

		if ( turn_thermal_on( curADS, lastADS ) )
		{
			thermal_EffectsOn();
		}
		else
		if ( turn_thermal_off( curADS, lastADS ) )
		{
			thermal_EffectsOff();
		}

		wait( 0.05 );
	}
}

turn_thermal_on( curADS, lastADS )
{
	if ( curADS <= lastADS )
		return false;

	if ( curADS <= 0.65 )
		return false;

	return !isdefined( self.is_in_thermal_Vision );
}

turn_thermal_off( curADS, lastADS )
{
	if ( curADS >= lastADS )
		return false;

	if ( curADS >= 0.80 )
		return false;

	return IsDefined( self.is_in_thermal_Vision );
}


thermal_EffectsOn()
{
	self.is_in_thermal_Vision = true;

	friendlies = GetAIArray( "allies" );
	foreach ( guy in friendlies )
	{
		if ( IsDefined( guy.has_thermal_fx ) )
			continue;

		guy.has_thermal_fx = true;
		guy thread loop_friendly_thermal_Reflector_Effect( self.unique_id );
	}

	if ( is_coop() )
	{
		other_player = get_other_player( self );
		if ( !isdefined( other_player.has_thermal_fx ) )
		{
			other_player.has_thermal_fx = true;
			other_player thread loop_friendly_thermal_Reflector_Effect( self.unique_id, self );
		}
	}
}

thermal_EffectsOff()
{
	self.is_in_thermal_Vision = undefined;
	level notify( "thermal_fx_off" + self.unique_id );

	friendlies = GetAIArray( "allies" );
	for ( index = 0; index < friendlies.size; index++ )
	{
		friendlies[ index ].has_thermal_fx = undefined;
	}

	if ( is_coop() )
	{
		other_player = get_other_player( self );
		other_player.has_thermal_fx = undefined;
	}
}

loop_friendly_thermal_Reflector_Effect( player_id, onlyForThisPlayer )
{
	if ( IsDefined( self.has_no_ir ) )
	{
		AssertEx( self.has_no_ir, ".has_ir must be true or undefined" );
		return;
	}

	level endon( "thermal_fx_off" + player_id );
	self endon( "death" );

	for ( ;; )
	{
		if ( IsDefined( onlyForThisPlayer ) )
			PlayFXOnTagForClients( level.friendly_thermal_Reflector_Effect, self, "J_Spine4", onlyForThisPlayer );
		else
			PlayFXOnTag( level.friendly_thermal_Reflector_Effect, self, "J_Spine4" );

		//"tag_reflector_arm_ri"

		wait( 0.2 );
	}
}


claymore_pickup_think_global()
{
	PreCacheItem( "claymore" );
	self endon( "deleted" );
	self SetCursorHint( "HINT_NOICON" );
	// Press and hold &&1 to pickup claymore
	self SetHintString( &"WEAPON_CLAYMORE_PICKUP" );
	self MakeUsable();

	// if nothing no ammo count is set assume max ammo.
	ammo_count = WeaponMaxAmmo( "claymore" ) + WeaponClipSize( "claymore" );

	if ( isdefined( self.script_ammo_clip ) )
	{
		ammo_count = self.script_ammo_clip;
	}

	while( ammo_count > 0 )
	{
		self waittill( "trigger", player );

		player PlaySound( "weap_pickup" );

		current_ammo_count = 0;
		if ( !player HasWeapon( "claymore" ) )
		{
			player GiveWeapon( "claymore" );
		}
		else
		{
			current_ammo_count = player GetAmmoCount( "claymore" );
		}

		if ( IsDefined( ammo_count ) && ammo_count > 0 )
		{
			ammo_count = current_ammo_count + ammo_count;

			max_ammo = WeaponMaxAmmo( "claymore" );
			clip_size = WeaponClipSize( "claymore" );

			if ( ammo_count >= clip_size )
			{
				ammo_count -= clip_size;
				player setweaponammoclip( "claymore", clip_size );
			}

			if ( ammo_count >= max_ammo )
			{
				ammo_count -= max_ammo;
				player SetWeaponAmmoStock( "claymore", max_ammo );
			}
			else if ( ammo_count > 0 )
			{
				player SetWeaponAmmoStock( "claymore", ammo_count );
				ammo_count = 0;
			}
		}
		else
		{
			player GiveMaxAmmo( "claymore" );
		}

		slotnum = 4;
		if ( IsDefined( player.remotemissile_actionslot ) && player.remotemissile_actionslot == 4 )
		{
			slotnum = 2;
		}
		player SetActionSlot( slotnum, "weapon", "claymore" );

		player SwitchToWeapon( "claymore" );
	}

	if ( IsDefined( self.target ) )
	{
		targets = GetEntArray( self.target, "targetname" );
		//give_ammo_count = targets.size + 1;
		foreach ( t in targets )
			t Delete();
	}

	self MakeUnusable();
	self Delete();

}


ammo_cache_think_global( show_ammo_icon )
{
	self endon( "remove_ammo_cache" );
	
	self.use_trigger = spawn( "script_model", self.origin + ( 0, 0, 28 ) ); // offset can't be higher than prone height of 30
	self.use_trigger setModel( "tag_origin" );
	self.use_trigger makeUsable();
	self.use_trigger SetCursorHint( "HINT_NOICON" );
	// Press and hold &&1 to refill your ammo
	self.use_trigger setHintString( &"WEAPON_CACHE_USE_HINT" );

	if ( !IsDefined( show_ammo_icon ) || ( IsDefined( show_ammo_icon ) && show_ammo_icon ) )
	{
		self thread ammo_icon_think();
	}

	while ( 1 )
	{
		self.use_trigger waittill( "trigger", player );
		
		self notify( "used_ammo_cache" );

		self.use_trigger MakeUnusable();
		player PlaySound( "player_refill_all_ammo" );
		player DisableWeapons();
		heldweapons = player GetWeaponsListAll();
		foreach ( weapon in heldweapons )
		{
			if ( weapon == "claymore" )
				continue;
			if ( weapon == "c4" )
				continue;
			player GiveMaxAmmo( weapon );
			
			clipSize = WeaponClipSize( weapon );
			if( isdefined( clipSize ) )
			{
				if ( player GetWeaponAmmoClip( weapon ) < clipSize )
					player SetWeaponAmmoClip( weapon, clipSize );
			}
		}
		wait 1.5;
		player EnableWeapons();
		self.use_trigger MakeUsable();
	}
}

ammo_icon_think()
{
	self endon( "remove_ammo_cache" );
	
	trigger = Spawn( "trigger_radius", self.origin, 0, 320, 72 );

	icon = NewHudElem();
	icon SetShader( "waypoint_ammo", 1, 1 );
	icon.alpha = 0;
	icon.color = ( 1, 1, 1 );
	icon.x = self.origin[ 0 ];
	icon.y = self.origin[ 1 ];
	icon.z = self.origin[ 2 ] + 16;
	icon SetWayPoint( true, true );
	
	// so we can get these if we want to change position
	self.ammo_icon = icon;
	self.ammo_icon_trig = trigger;
	
	if ( isdefined( self.icon_always_show ) && self.icon_always_show )
	{
		ammo_icon_fade_in( icon );
		return;
	}
	
	wait( 0.05 );

	while ( true )
	{
		trigger waittill( "trigger", other );

		if ( !isplayer( other ) )
			continue;

		while ( other IsTouching( trigger ) )
		{
			show = true;
			weapon = other GetCurrentWeapon();
			if ( weapon == "none" )
				show = false;
			else
			if ( ( other GetFractionMaxAmmo( weapon ) ) > .9 )
				show = false;

			if ( player_looking_at( self.origin, 0.8, true ) && show )
				ammo_icon_fade_in( icon );
			else
				ammo_icon_fade_out( icon );
			wait 0.25;
		}
		ammo_icon_fade_out( icon );
	}
}

ammo_icon_fade_in( icon )
{
	if ( icon.alpha != 0 )
		return;

	icon FadeOverTime( 0.2 );
	icon.alpha = .3;
	wait( 0.2 );
}

ammo_icon_fade_out( icon )
{
	if ( icon.alpha == 0 )
		return;

	icon FadeOverTime( 0.2 );
	icon.alpha = 0;
	wait( 0.2 );
}

window_destroy()
{
	Assert( IsDefined( self.target ) );

	glassID = GetGlass( self.target );

	// this can happen with myMapEnts
	//assertex( IsDefined( glassID ), "couldn't find glass for ent with targetname \"window_poster\" at "+ self GetOrigin() );
	if ( !isDefined( glassID ) )
	{
		PrintLn( "Warning: Couldn't find glass with targetname \"" + self.target + "\" for ent with targetname \"window_poster\" at " + self.origin );
		return;
	}

	level waittillmatch( "glass_destroyed", glassID );
	self Delete();
}

global_empty_callback( empty1, empty2, empty3, empty4, empty5 )
{
	AssertMsg( "a _stealth or _idle related function was called in a global script without being initilized by the stealth system.  If you've already initilized those scripts, then this is a bug for Mo." );
}

weapon_list_debug()
{
	create_dvar( "weaponlist", "0" );
	if ( !getdvarint( "weaponlist" ) )
		return;

	ents = GetEntArray();
	list = [];
	foreach ( ent in ents )
	{
		if ( !isdefined( ent.code_classname ) )
			continue;
		if ( IsSubStr( ent.code_classname, "weapon" ) )
		{
			list[ ent.classname ] = true;
		}
	}

	PrintLn( "Placed weapons list: " );
	foreach ( weapon, _ in list )
	{
		PrintLn( weapon );
	}

	spawners = GetSpawnerArray();
	classes = [];
	foreach ( spawner in spawners )
	{
		classes[ spawner.code_classname ] = true;
	}

	PrintLn( "" );
	PrintLn( "Spawner classnames: " );

	foreach ( class, _ in classes )
	{
		PrintLn( class );
	}
}

slowmo_system_init()
{
	level.slowmo = spawnstruct();

	slowmo_system_defaults();

	notifyOnCommand( "_cheat_player_press_slowmo", "+melee" );
	notifyOnCommand( "_cheat_player_press_slowmo", "+melee_breath" );
	notifyOnCommand( "_cheat_player_press_slowmo", "+melee_zoom" );
}

slowmo_system_defaults()
{
	level.slowmo.lerp_time_in = 0.0;
	level.slowmo.lerp_time_out = .25;
	level.slowmo.speed_slow = 0.4;
	level.slowmo.speed_norm = 1.0;
}

add_no_game_starts()
{
	start_spots = GetEntArray( "script_origin_start_nogame", "classname" );
	if ( !start_spots.size )
    	return;
    	
    foreach ( spot in start_spots )
    {
        if ( !IsDefined( spot.script_startname ) )
            continue;
        add_start( "no_game_" + spot.script_startname, ::start_nogame );
    }
    
}

do_no_game_start()
{
    if ( !is_no_game_start() )
	    return;
	    
	// we want ufo/noclip to hit triggers in no_game
	SetSavedDvar( "ufoHitsTriggers", "1" );

	level.stop_load = true;
	// SRS 11/25/08: LDs can run a custom setup function for their levels to get back some
	//  selected script calls (loadout, vision, etc).  be careful, this function is not threaded!
	if ( IsDefined( level.custom_no_game_setupFunc ) )
	{
		level [[ level.custom_no_game_setupFunc ]]();
	}
	
	maps\_loadout::init_loadout();
	maps\_audio::init_audio();
	maps\_global_fx::main();

    do_no_game_start_teleport();
	    
    array_call ( GetEntArray( "truckjunk", "targetname" ), ::delete );
    array_call ( GetEntArray( "truckjunk", "script_noteworthy" ), ::delete );
	
	level waittill( "eternity" );
}

do_no_game_start_teleport()
{
    start_spots = GetEntArray( "script_origin_start_nogame", "classname" );

    if ( ! start_spots.size )
        return;

    start_spots = SortByDistance( start_spots, level.player.origin );
    
    if( level.start_point == "no_game" )
    {
        level.player teleport_player( start_spots[ 0 ] );
        return;
    }
    
    start_point_name = GetSubStr( level.start_point, 8 );
    
    found_spot = false;
    
    foreach ( point in start_spots )
    {
        if ( !IsDefined( point.script_startname ) )
            continue;
        if ( start_point_name != point.script_startname )
            continue;
            
        if( isdefined( point.script_visionset ) )
            vision_set_fog_changes( point.script_visionset, 0 );
            
        level.player teleport_player( point );
        
        found_spot = true;
        break;
    }
    
    if ( ! found_spot )
        level.player teleport_player( start_spots[ 0 ] );
}


init_animSounds()
{
	level.animSounds = [];
	level.animSound_aliases = [];
	waittillframeend;// now we know _load has run and the level.scr_notetracks have been defined
	waittillframeend;// wait one extra frameend because _audio.gso files waittillframeend and we have to start after them

	animnames = GetArrayKeys( level.scr_notetrack );
	for ( i = 0; i < animnames.size; i++ )
	{
		init_notetracks_for_animname( animnames[ i ] );
	}

	animnames = GetArrayKeys( level.scr_animSound );
	for ( i = 0; i < animnames.size; i++ )
	{
		init_animSounds_for_animname( animnames[ i ] );
	}
}

init_animSounds_for_animname( animname )
{
	// copy all the scr_animSounds into animsound_aliases so they show up properly
	animes = GetArrayKeys( level.scr_animSound[ animname ] );

	for ( i = 0; i < animes.size; i++ )
	{
		anime = animes[ i ];
		soundalias = level.scr_animSound[ animname ][ anime ];
		level.animSound_aliases[ animname ][ anime ][ "#" + anime ][ "soundalias" ] = soundalias;
		level.animSound_aliases[ animname ][ anime ][ "#" + anime ][ "created_by_animSound" ] = true;
	}
}


init_notetracks_for_animname( animname )
{
	// copy all the scr_notetracks into animsound_aliases so they show up properly
	// level.scr_notetrack[ animname ][ anime ][ notetrack ][ index ][ "dialog" ] = soundalias;
	foreach ( anime, anime_array in level.scr_notetrack[ animname ] )
	{
		foreach ( notetrack, notetrack_array in anime_array )
		{
			foreach ( scr_notetrack in notetrack_array )
			{
				soundAlias = scr_notetrack[ "sound" ];
				if ( !isdefined( soundAlias ) )
					continue;

				level.animSound_aliases[ animname ][ anime ][ notetrack ][ "soundalias" ] = soundalias;
				if ( IsDefined( scr_notetrack[ "created_by_animSound" ] ) )
				{
					level.animSound_aliases[ animname ][ anime ][ notetrack ][ "created_by_animSound" ] = true;
				}
			}
		}
	}
}

default_footsteps()
{
	animscripts\utility::setFootstepEffect( "default", 	LoadFX( "fx/misc/blank" ) );
	animscripts\utility::setFootstepEffect( "asphalt", 	LoadFX( "fx/misc/blank" ) );
	animscripts\utility::setFootstepEffect( "brick", 	LoadFX( "fx/misc/blank" ) );
	animscripts\utility::setFootstepEffect( "carpet", 	LoadFX( "fx/misc/blank" ) );
	animscripts\utility::setFootstepEffect( "cloth",  	LoadFX( "fx/misc/blank" ) );
	animscripts\utility::setFootstepEffect( "concrete", LoadFX( "fx/misc/blank" ) );
	animscripts\utility::setFootstepEffect( "cushion",  LoadFX( "fx/misc/blank" ) );
	animscripts\utility::setFootstepEffect( "dirt", 	LoadFX( "fx/impacts/footstep_dust" ) );
	animscripts\utility::setFootstepEffect( "foliage", 	LoadFX( "fx/misc/blank" ) );
	animscripts\utility::setFootstepEffect( "grass", 	LoadFX( "fx/misc/blank" ) );
	animscripts\utility::setFootstepEffect( "gravel", 	LoadFX( "fx/misc/blank" ) );
	animscripts\utility::setFootstepEffect( "mud", 		LoadFX( "fx/impacts/footstep_mud" ) );
	animscripts\utility::setFootstepEffect( "rock", 	LoadFX( "fx/misc/blank" ) );
	animscripts\utility::setFootstepEffect( "sand", 	LoadFX( "fx/misc/blank" ) );
	animscripts\utility::setFootstepEffect( "wood", 	LoadFX( "fx/misc/blank" ) );
	animscripts\utility::setFootstepEffect( "water", 	LoadFX( "fx/impacts/footstep_water" ) );
	animscripts\utility::setFootstepEffect( "snow", 	LoadFX( "fx/misc/blank" ) );
	animscripts\utility::setFootstepEffect( "ice", 		LoadFX( "fx/misc/blank" ) );

	animscripts\utility::setFootstepEffectSmall( "default", 	LoadFX( "fx/misc/blank" ) );
	animscripts\utility::setFootstepEffectSmall( "asphalt", 	LoadFX( "fx/misc/blank" ) );
	animscripts\utility::setFootstepEffectSmall( "brick", 		LoadFX( "fx/misc/blank" ) );
	animscripts\utility::setFootstepEffectSmall( "carpet", 		LoadFX( "fx/misc/blank" ) );
	animscripts\utility::setFootstepEffectSmall( "cloth", 		LoadFX( "fx/misc/blank" ) );
	animscripts\utility::setFootstepEffectSmall( "concrete", 	LoadFX( "fx/misc/blank" ) );
	animscripts\utility::setFootstepEffectSmall( "cushion", 	LoadFX( "fx/misc/blank" ) );
	animscripts\utility::setFootstepEffectSmall( "dirt", 		LoadFX( "fx/impacts/footstep_dust" ) );
	animscripts\utility::setFootstepEffectSmall( "foliage", 	LoadFX( "fx/misc/blank" ) );
	animscripts\utility::setFootstepEffectSmall( "grass", 		LoadFX( "fx/misc/blank" ) );
	animscripts\utility::setFootstepEffectSmall( "gravel", 		LoadFX( "fx/misc/blank" ) );
	animscripts\utility::setFootstepEffectSmall( "mud", 		LoadFX( "fx/impacts/footstep_mud" ) );
	animscripts\utility::setFootstepEffectSmall( "rock", 		LoadFX( "fx/misc/blank" ) );
	animscripts\utility::setFootstepEffectSmall( "sand", 		LoadFX( "fx/misc/blank" ) );
	animscripts\utility::setFootstepEffectSmall( "wood", 		LoadFX( "fx/misc/blank" ) );
	animscripts\utility::setFootstepEffectSmall( "water", 		LoadFX( "fx/impacts/footstep_water" ) );
	animscripts\utility::setFootstepEffectSmall( "snow", 		LoadFX( "fx/misc/blank" ) );
	animscripts\utility::setFootstepEffectSmall( "ice", 		LoadFX( "fx/misc/blank" ) );
  
	/* Other notetrack fx
	setNotetrackEffect( <notetrack>, <tag>, <surface>, <LoadFX>, <sound_prefix>, <sound_suffix> )
		<notetrack>: name of the notetrack to do the fx/sound on
		<tag>: name of the tag on the AI to use when playing fx
		<surface>: the fx will only play when the AI is on this surface. Specify "all" to make it work for all surfaces.
		<LoadFX>: load the fx to play here
		<sound_prefix>: when this notetrack hits a sound can be played. This is the prefix of the sound alias to play ( gets followed by surface type )
		<sound_suffix>: suffix of sound alias to play, follows the surface type. Example: prefix of "bodyfall_" and suffix of "_large" will play sound alias "bodyfall_dirt_large" when the notetrack happens on dirt.
	*/

	note = "bodyfall small";
	tag = "J_SpineLower";
	prefix = "bodyfall_";
	suffix = "_small";
	animscripts\utility::setNotetrackEffect( note, tag, "dirt",		LoadFX( "fx/impacts/bodyfall_default_large_runner" ), prefix, suffix );
	animscripts\utility::setNotetrackEffect( note, tag, "concrete",	LoadFX( "fx/impacts/bodyfall_default_large_runner" ), prefix, suffix );
	animscripts\utility::setNotetrackEffect( note, tag, "asphalt",	LoadFX( "fx/impacts/bodyfall_default_large_runner" ), prefix, suffix );
	animscripts\utility::setNotetrackEffect( note, tag, "rock",		LoadFX( "fx/impacts/bodyfall_default_large_runner" ), prefix, suffix );

	// New audio-only notetrackSounds, if you want to tie an FX, then use setNotetrackEffect()
	sound_only_surfaces = [ "brick", "carpet", "foliage", "grass", "gravel", "ice", "metal", "painted metal", 
							"mud", "plaster", "sand", "snow", "slush", "water", "wood", "ceramic" ];

	foreach ( surface in sound_only_surfaces )
	{
		animscripts\utility::setNotetrackSound( note, surface, prefix, suffix );
	}
	
	note = "bodyfall small";
	tag = "J_SpineLower";
	prefix = "bodyfall_";
	suffix = "_large";
	animscripts\utility::setNotetrackEffect( note, tag, "dirt",		LoadFX( "fx/impacts/bodyfall_default_large_runner" ), prefix, suffix );
	animscripts\utility::setNotetrackEffect( note, tag, "concrete",	LoadFX( "fx/impacts/bodyfall_default_large_runner" ), prefix, suffix );
	animscripts\utility::setNotetrackEffect( note, tag, "asphalt",	LoadFX( "fx/impacts/bodyfall_default_large_runner" ), prefix, suffix );
	animscripts\utility::setNotetrackEffect( note, tag, "rock",		LoadFX( "fx/impacts/bodyfall_default_large_runner" ), prefix, suffix );

	// New audio-only notetrackSounds, if you want to tie an FX, then use setNotetrackEffect()
	foreach ( surface in sound_only_surfaces )
	{
		animscripts\utility::setNotetrackSound( note, surface, prefix, suffix );
	}

	/* Will revive this when we get knee impact notetracks
	animscripts\utility::setNotetrackEffect( "knee fx left", 		"J_Knee_LE", 			"dirt",		LoadFX ( "fx/impacts/footstep_dust" ) );
	animscripts\utility::setNotetrackEffect( "knee fx left", 		"J_Knee_LE", 			"concrete",	LoadFX ( "fx/impacts/footstep_dust" ) );
	animscripts\utility::setNotetrackEffect( "knee fx left", 		"J_Knee_LE", 			"asphalt",	LoadFX ( "fx/impacts/footstep_dust" ) );
	animscripts\utility::setNotetrackEffect( "knee fx left", 		"J_Knee_LE", 			"rock",		LoadFX ( "fx/impacts/footstep_dust" ) );
	animscripts\utility::setNotetrackEffect( "knee fx left", 		"J_Knee_LE", 			"mud",		LoadFX ( "fx/impacts/footstep_mud" ) );
	
	animscripts\utility::setNotetrackEffect( "knee fx right", 		"J_Knee_RI", 			"dirt",		LoadFX ( "fx/impacts/footstep_dust" ) );
	animscripts\utility::setNotetrackEffect( "knee fx right", 		"J_Knee_RI", 			"concrete",	LoadFX ( "fx/impacts/footstep_dust" ) );
	animscripts\utility::setNotetrackEffect( "knee fx right", 		"J_Knee_RI", 			"asphalt",	LoadFX ( "fx/impacts/footstep_dust" ) );
	animscripts\utility::setNotetrackEffect( "knee fx right", 		"J_Knee_RI", 			"rock",		LoadFX ( "fx/impacts/footstep_dust" ) );
	animscripts\utility::setNotetrackEffect( "knee fx right", 		"J_Knee_RI", 			"mud",		LoadFX ( "fx/impacts/footstep_mud" ) );
	*/
}
