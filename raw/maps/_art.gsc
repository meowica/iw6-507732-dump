// This function should take care of grain and glow settings for each map, plus anything else that artists 
// need to be able to tweak without bothering level designers.
#include maps\_utility;
#include common_scripts\utility;
#include common_scripts\_artCommon;

main()
{
	/#
	SetDevDvarIfUninitialized( "scr_art_tweak", 0 );
	SetDevDvarIfUninitialized( "scr_cmd_plr_sun", "0" );
	SetDevDvarIfUninitialized( "scr_cmd_plr_sunflare", "0" );
	SetSavedDvar( "r_artUseTweaks", false );
	if ( !IsDefined( level.vision_set_names ) )
	    level.vision_set_names = [];
	#/

	level.current_sunflare_setting = "default";
			
	level._clearalltextafterhudelem = false;

	dof_init();
	
	PrecacheMenu( "dev_vision_noloc" );
	PrecacheMenu( "dev_vision_exec" );
	
	level.special_weapon_dof_funcs = [];
	level.buttons = [];
		
	if ( !isdefined( level.vision_set_transition_ent ) )
	{
		level.vision_set_transition_ent = SpawnStruct();
		level.vision_set_transition_ent.vision_set = "";
		level.vision_set_transition_ent.time = 0;
	}

	if( !IsDefined( level.sunflare_settings ) )
	{
		level.sunflare_settings = [];
	}
	
	if( !IsDefined( level.vision_set_fog ) )
	{
		level.vision_set_fog = [];
		create_default_vision_set_fog( level.script );
		common_scripts\_artCommon::setfogsliders();
	}
	
/#	
	// Add existing vision sets for any fog that's been created thus far
	foreach( key, value in level.vision_set_fog )
	{
		common_scripts\_artCommon::add_vision_set_to_list( key );
	}		
		
	thread tweakart();
#/

	if ( !isdefined( level.script ) )
		level.script = ToLower( GetDvar( "mapname" ) );
}

/#
tweakart()
{
	if ( !isdefined( level.tweakfile ) )
		level.tweakfile = false;

	// not in DEVGUI
	SetDvar( "scr_fog_fraction", "1.0" );
	SetDvar( "scr_art_dump", "0" );
	SetDvar( "scr_cmd_sunflare_dump", "0" );

	// update the devgui variables to current settings
	SetDvar( "scr_dof_nearStart", level.dof["base"]["current"]["nearStart"] );
	SetDvar( "scr_dof_nearEnd", level.dof["base"]["current"]["nearEnd"] );
	SetDvar( "scr_dof_farStart", level.dof["base"]["current"]["farStart"] );
	SetDvar( "scr_dof_farEnd", level.dof["base"]["current"]["farEnd"] );
	SetDvar( "scr_dof_nearBlur", level.dof["base"]["current"]["nearBlur"] );
	SetDvar( "scr_dof_farBlur", level.dof["base"]["current"]["farBlur"] );

	// not in DEVGUI
	level.fogfraction = 1.0;

	file = undefined;

	// set dofvars from < levelname > _art.gsc
	dofvarupdate();

	printed = false;
	
	last_vision_set = "";
	last_sunflare = "";
	
	for ( ;; )
	{
		while ( GetDvarInt( "scr_art_tweak" ) == 0 )
			wait .05;

		SetSavedDvar( "r_artUseTweaks", true );
		
		// work around so art tweak doesn't break the vision set when it has been set on a player
		if ( IsDefined( level.player ) )
		{
			// use the player's vision_set when it is set
			if ( IsDefined( level.player.vision_set_transition_ent ) )
				level.vision_set_transition_ent = level.player.vision_set_transition_ent;
			
			// use the player's fog transition when it is set
			if ( IsDefined( level.player.fog_transition_ent ) )
				level.fog_transition_ent = level.player.fog_transition_ent;
		}

		if ( !printed )
		{
			printed = true;
			
			// This craziness calls updateCharPrimaryTweaks, updateFilmTweaks, and updateGlowTweaks to pull current values from renderer dvars into tweak dvars
			level.player openpopupmenu( "dev_vision_noloc" );
			wait .05;
			level.player  closepopupmenu( "dev_vision_noloc" );
			
			IPrintLnBold( "ART TWEAK ENABLED" );
			
			// create new vision sets for those triggers that aren't yet hooked up
			add_vision_sets_from_triggers();
			construct_sunflare_ents();
			hud_init();
			playerInit();
		}

		//translate the slider values to script variables
		common_scripts\_artCommon::translateFogSlidersToScript();

		dofvarupdate();

		// catch all those cases where a slider can be pushed to a place of conflict
		dofslidercheck();
		
		common_scripts\_artCommon::fogslidercheck();

		updateSunFlarePosition();		
		
		dump = dumpsettings();// dumps and returns true if the dump dvar is set

		updateFogEntFromScript();
		
		if ( getdvarint( "scr_select_art_next" ) || button_down( "dpad_down", "kp_downarrow" ) )
			setgroup_down();
		else if ( getdvarint( "scr_select_art_prev" ) || button_down( "dpad_up", "kp_uparrow" ) )
			setgroup_up();
		else if( level.vision_set_transition_ent.vision_set != last_vision_set )
		{
			last_vision_set = level.vision_set_transition_ent.vision_set;
			setcurrentgroup( last_vision_set );
		}

		if ( getdvarint( "scr_select_sunflare_next" ) )
			setsunflare_down();
		else if ( getdvarint( "scr_select_sunflare_prev" ) )
			setsunflare_up();
		else if ( level.current_sunflare_setting != last_sunflare )
		{
			setcurrentsunflare( level.current_sunflare_setting );
			last_sunflare = level.current_sunflare_setting;
		}
		
		wait .05;
	}
}
#/

/#
dofvarupdate()
{
	nearStart 	= GetDvarInt( "scr_dof_nearStart" );
	nearEnd 	= GetDvarInt( "scr_dof_nearEnd" );
	nearBlur 	= GetDvarFloat( "scr_dof_nearBlur" );
	farStart 	= GetDvarInt( "scr_dof_farStart" );
	farEnd 		= GetDvarInt( "scr_dof_farEnd" );
	farBlur 	= GetDvarFloat( "scr_dof_farBlur" );
	
	foreach( player in level.players )
	{
		player SetDepthOfField( nearStart, nearEnd, farStart, farEnd, nearBlur, farBlur );
	}
}

updateSunFlarePosition()
{	
	if ( GetDvarInt( "scr_cmd_plr_sunflare" ) )
	{
		SetDevDvar( "scr_cmd_plr_sunflare", 0 );

		pos = level.player GetPlayerAngles();
		setSunFlarePosition( pos );
		SetDvar( "r_sunflare_position", pos );
	}
}

button_down( btn, btn2 )
{
	pressed = level.player ButtonPressed( btn );

	if ( !pressed )
	{
		pressed = level.player ButtonPressed( btn2 );
	}

	if ( !IsDefined( level.buttons[ btn ] ) )
	{
		level.buttons[ btn ] = 0;
	}

	// To Prevent Spam
	if ( GetTime() < level.buttons[ btn ] )
	{
		return false;
	}

	level.buttons[ btn ] = GetTime() + 400;
	return pressed;
}

updateFogEntFromScript()
{
	if ( GetDvarInt( "scr_cmd_plr_sun" ) )
	{
		SetDevDvar( "scr_sunFogDir", AnglesToForward( level.player GetPlayerAngles() ) );
		SetDevDvar( "scr_cmd_plr_sun", 0 );
	}
	
	ent = level.vision_set_fog[ ToLower(level.vision_set_transition_ent.vision_set) ];

	if ( using_hdr_fog() && isdefined( ent ) && isdefined( ent.HDROverride ) && isdefined( level.vision_set_fog[ ToLower(ent.HDROverride) ] ) )
	{
		ent = level.vision_set_fog[ ToLower(ent.HDROverride) ];
	}
	
	if( IsDefined( ent ) && isdefined( ent.name ) )
	{
		ent.startDist 				= level.fognearplane;
		ent.halfwayDist 			= level.fogexphalfplane;
		ent.red 					= level.fogcolor[ 0 ];
		ent.green 					= level.fogcolor[ 1 ];
		ent.blue 					= level.fogcolor[ 2 ];
		ent.HDRColorIntensity 		= level.fogHDRColorIntensity;
		ent.maxOpacity 				= level.fogmaxopacity;
		
		ent.sunFogEnabled 			= level.sunFogEnabled;
		ent.sunRed 					= level.sunFogColor[ 0 ];
		ent.sunGreen 				= level.sunFogColor[ 1 ];
		ent.sunBlue 				= level.sunFogColor[ 2 ];
		ent.HDRSunColorIntensity 	= level.sunFogHDRColorIntensity;
		ent.sunDir 					= level.sunFogDir;
		ent.sunBeginFadeAngle 		= level.sunFogBeginFadeAngle;
		ent.sunEndFadeAngle 		= level.sunFogEndFadeAngle;
		ent.normalFogScale 			= level.sunFogScale;
		
		ent.skyFogIntensity 		= level.skyFogIntensity;
		ent.skyFogMinAngle 			= level.skyFogMinAngle;
		ent.skyFogMaxAngle 			= level.skyFogMaxAngle;

		if ( GetDvarInt( "scr_fog_disable" ) )
		{
			ent.startDist 				= 2000000000;
			ent.halfwayDist 			= 2000000001;
			ent.red 					= 0;
			ent.green 					= 0;
			ent.blue 					= 0;
			ent.HDRSunColorIntensity 	= 1;
			ent.maxOpacity 				= 0;
			ent.skyFogIntensity 		= 0;
		}		
		
		set_fog_to_ent_values( ent, 0 );
	}
}

dofslidercheck()
{
	nearStart 	= GetDvarInt( "scr_dof_nearStart" );
	nearEnd 	= GetDvarInt( "scr_dof_nearEnd" );
	nearBlur 	= GetDvarFloat( "scr_dof_nearBlur" );
	farStart 	= GetDvarInt( "scr_dof_farStart" );
	farEnd 		= GetDvarInt( "scr_dof_farEnd" );
	farBlur 	= GetDvarFloat( "scr_dof_farBlur" );

	// catch all those cases where a slider can be pushed to a place of conflict
	if ( nearStart >= nearEnd )
	{
		nearStart = nearEnd - 1;
		SetDvar( "scr_dof_nearStart", nearStart );
	}
	if ( nearEnd <= nearStart )
	{
		nearEnd = nearStart + 1;
		SetDvar( "scr_dof_nearEnd", nearEnd );
	}
	if ( farStart >= farEnd )
	{
		farStart = farEnd - 1;
		SetDvar( "scr_dof_farStart", farStart );
	}
	if ( farEnd <= farStart )
	{
		farEnd = farStart + 1;
		SetDvar( "scr_dof_farEnd", farEnd );
	}
	if ( farBlur >= nearBlur )
	{
		farBlur = nearBlur - .1;
		SetDvar( "scr_dof_farBlur", farBlur );
	}
	if ( farStart <= nearEnd )
	{
		farStart = nearEnd + 1;
		SetDvar( "scr_dof_farStart", farStart );
	}
}

add_vision_sets_from_triggers()
{
	assert( IsDefined( level.vision_set_fog ) );

	triggers = GetEntArray( "trigger_multiple_visionset" , "classname" );
	
	foreach( trigger in triggers )
	{
		name = undefined;
		
		if( IsDefined( trigger.script_visionset ) )
			name = ToLower( trigger.script_visionset );
		else if ( IsDefined( trigger.script_visionset_start ) )
			name = ToLower( trigger.script_visionset_start );
		else if ( IsDefined( trigger.script_visionset_end ) )
			name = ToLower( trigger.script_visionset_end );
	   	if ( IsDefined( name ) )
			add_vision_set( name );
	}
}

add_vision_set( vision_set_name )
{
	assert( vision_set_name == ToLower( vision_set_name ) );
	
	if ( IsDefined( level.vision_set_fog[ vision_set_name ] ) )
		return;

	create_default_vision_set_fog( vision_set_name );
	common_scripts\_artCommon::add_vision_set_to_list( vision_set_name );

	IPrintLnBold( "new vision: " + vision_set_name );
}
#/

create_default_vision_set_fog( name )
{
	ent = create_vision_set_fog( name );
	ent.startDist 		= 3764.17;
	ent.halfwayDist 	= 19391;
	ent.red 			= 0.661137;
	ent.green 			= 0.554261;
	ent.blue 			= 0.454014;
	ent.maxOpacity 		= 0.7;
	ent.transitionTime 	= 0;
	ent.skyFogIntensity	= 0;
	ent.skyFogMinAngle 	= 0;
	ent.skyFogMaxAngle 	= 0;
}

/#
construct_sunflare_ents()
{
	if( !isdefined( level.sunflare_settings ))
	 	level.sunflare_settings = [];
	
	triggers = GetEntArray( "trigger_multiple_sunflare" , "classname" );
	
	foreach( trigger in triggers )
	{
		if( IsDefined( trigger.script_visionset ) )
			construct_sunflare_ent( trigger.script_visionset );
	}
	
	if ( !isdefined( level.sunflare_settings[ "default" ] ) )
	{
		create_default_sunflare_setting();
	}
}

create_default_sunflare_setting()
{
	ent = create_sunflare_setting( "default" );
	ent.position = ( -30, 85, 0 );
}

construct_sunflare_ent( vision_set_name )
{
	if ( IsDefined( level.sunflare_settings[ vision_set_name ] ) )
		return;
	
	ent = create_sunflare_setting( vision_set_name );
	ent.position = ( 0, 0, 0 );
	
	IPrintLnBold( "new sunflare: " + vision_set_name );
}

dumpsettings()
{
	if ( GetDvar( "scr_art_dump" ) == "0" && GetDvar( "scr_cmd_sunflare_dump" ) == "0" )
		return;
	
	dump_art 		= GetDvar( "scr_art_dump" ) != "0";
	dump_sunflares 	= GetDvar( "scr_cmd_sunflare_dump" ) != "0";
	
	SetDvar( "scr_art_dump", "0" );
	SetDvar( "scr_cmd_sunflare_dump", "0" );

	if ( dump_sunflares )
	{
		save_current_sunflare_settings();
	}

	////////////////// _art.gsc
	fileprint_launcher_start_file();
	fileprint_launcher( "// _createart generated.  modify at your own risk. Changing values should be fine." );
	fileprint_launcher( "main()" );
	fileprint_launcher( "{" );
	fileprint_launcher( "" );
	fileprint_launcher( "\tlevel.tweakfile = true;" );
	fileprint_launcher( "\tlevel.player = GetEntArray( \"player\", \"classname\" )[0]; " );
	fileprint_launcher( "\tmaps\\createart\\" + get_template_level() + "_fog::main();" );
	fileprint_launcher( "" );
	fileprint_launcher( "}" );
	if ( !fileprint_launcher_end_file( "\\share\\raw\\maps\\createart\\" + level.script + "_art.gsc", true ) )
		return;
	////////////////////////////// 

	
	
	////////////////// _art.csv
	fileprint_launcher_start_file();
    fileprint_launcher( "// _createart generated.  modify at your own risk. " );
    fileprint_launcher( "rawfile,maps/createart/"+ get_template_level() + "_art.gsc"  );
    fileprint_launcher( "rawfile,maps/createart/"+ get_template_level() + "_fog.gsc"  );
    fileprint_launcher( "rawfile,vision/"+ get_template_level() + ".vision" ) ;
    common_scripts\_artCommon::print_fog_ents_csv();
    if ( !fileprint_launcher_end_file( "\\share\\zone_source\\" + get_template_level() + "_art.csv", true ) )
    	return;
	////////////////////////////// 

	
	
	////////////////// _fog.gsc
	fileprint_launcher_start_file();
    fileprint_launcher( "// _createart generated.  modify at your own risk. " );
    fileprint_launcher( "main()" );
    fileprint_launcher( "{" );
    fileprint_launcher( "\tsunflare();" );
    fileprint_launcher( "" );
    common_scripts\_artCommon::print_fog_ents( false );
    fileprint_launcher( "}" );
    fileprint_launcher( "" );    
    fileprint_launcher( "sunflare()" );
    fileprint_launcher( "{" );
    print_sunflare_ents();
	fileprint_launcher( "\tmaps\\_art::sunflare_changes( \"default\", 0 );");
    fileprint_launcher( "}" );
    if ( !fileprint_launcher_end_file( "\\share\\raw\\maps\\createart\\" + get_template_level() + "_fog.gsc", true ) )
    	return;
	////////////////////////////// 
	
	// only print the currently selected vision file
	if ( dump_art )
	{
		if ( !common_scripts\_artCommon::print_vision( level.vision_set_transition_ent.vision_set ) )
			return;
	}


	iprintlnbold( "Save successful!" );

	PrintLn( "Art settings dumped success!" );
	addstring = "maps\\createart\\" + level.script + "_art::main();";
	AssertEx( level.tweakfile, "Remove all art setting in " + level.script + ".gsc ,add This before _load: \n" + addstring + "\nAND: add This to your "+level.script+".csv: \ninclude,"+level.script+"_art");
}

save_current_sunflare_settings()
{
	if ( isdefined( level.sunflare_settings[ level.current_sunflare_setting ] ) )
		level.sunflare_settings[ level.current_sunflare_setting ].position = GetDvarVector( "r_sunflare_position" );
}
	
print_sunflare_ents()
{
	foreach( ent in level.sunflare_settings )
	{
		if( !isdefined( ent.name ) )
			continue;
		fileprint_launcher( "\tent = maps\\_utility::create_sunflare_setting( \""+ent.name+"\" );");
		if( isdefined( ent.position ) )
			fileprint_launcher( "\tent.position = "+ent.position + ";" );
	}
}
#/

dof_set_generic( layerName, subsetName, nearStart, nearEnd, nearBlur, farStart, farEnd, farBlur, weight )
{
	level.dof[layerName][subsetName]["nearStart"] 	= nearStart;
	level.dof[layerName][subsetName]["nearEnd"] 	= nearEnd;
	level.dof[layerName][subsetName]["nearBlur"] 	= nearBlur;
	level.dof[layerName][subsetName]["farStart"] 	= farStart;
	level.dof[layerName][subsetName]["farEnd"] 		= farEnd;
	level.dof[layerName][subsetName]["farBlur"] 	= farBlur;
	level.dof[layerName][subsetName]["weight"] 		= weight;
}

dof_blend_interior_generic( layerName )
{
	if ( level.dof[layerName]["timeRemaining"] <= 0.0 )
		return;
	
	lerpFrac = Min( 1.0, ( 0.05 / level.dof[layerName]["timeRemaining"] ) );
	
	// Note: May be beneficial to apply smooth step scaling to the lerp frac for better blending
	
	level.dof[layerName]["timeRemaining"] -= 0.05;
	if ( level.dof[layerName]["timeRemaining"] <= 0.0 )
	{
		// Done with interior blend -- copy values from goal to current
		level.dof[layerName]["timeRemaining"] = 0.0;
		
		level.dof[layerName]["current"]["nearStart"] 	= level.dof[layerName]["goal"]["nearStart"];
		level.dof[layerName]["current"]["nearEnd"] 		= level.dof[layerName]["goal"]["nearEnd"];
		level.dof[layerName]["current"]["nearBlur"] 	= level.dof[layerName]["goal"]["nearBlur"];
		level.dof[layerName]["current"]["farStart"] 	= level.dof[layerName]["goal"]["farStart"];
		level.dof[layerName]["current"]["farEnd"] 		= level.dof[layerName]["goal"]["farEnd"];
		level.dof[layerName]["current"]["farBlur"] 		= level.dof[layerName]["goal"]["farBlur"];
		level.dof[layerName]["current"]["weight"] 		= level.dof[layerName]["goal"]["weight"];
		
		return;
	}
	
	level.dof[layerName]["current"]["nearStart"]  	+= ( lerpFrac * ( level.dof[layerName]["goal"]["nearStart"] - level.dof[layerName]["current"]["nearStart"] ) );
	level.dof[layerName]["current"]["nearEnd"] 		+= ( lerpFrac * ( level.dof[layerName]["goal"]["nearEnd"] 	- level.dof[layerName]["current"]["nearEnd"] ) );
	level.dof[layerName]["current"]["nearBlur"] 	+= ( lerpFrac * ( level.dof[layerName]["goal"]["nearBlur"] 	- level.dof[layerName]["current"]["nearBlur"] ) );
	level.dof[layerName]["current"]["farStart"] 	+= ( lerpFrac * ( level.dof[layerName]["goal"]["farStart"] 	- level.dof[layerName]["current"]["farStart"] ) );
	level.dof[layerName]["current"]["farEnd"] 		+= ( lerpFrac * ( level.dof[layerName]["goal"]["farEnd"] 	- level.dof[layerName]["current"]["farEnd"] ) );
	level.dof[layerName]["current"]["farBlur"] 		+= ( lerpFrac * ( level.dof[layerName]["goal"]["farBlur"] 	- level.dof[layerName]["current"]["farBlur"] ) );
	level.dof[layerName]["current"]["weight"] 		+= ( lerpFrac * ( level.dof[layerName]["goal"]["weight"] 	- level.dof[layerName]["current"]["weight"] ) );
}

dof_init()
{		
	if ( GetDvar( "scr_dof_enable" ) == "" )
		SetSavedDvar( "scr_dof_enable", "1" );
	
	SetDvar( "ads_dof_tracedist", 		8192 );
	SetDvar( "ads_dof_maxEnemyDist", 	10000 );
	SetDvar( "ads_dof_nearStartScale", 	0.25 );
	SetDvar( "ads_dof_nearEndScale", 	0.85 );
	SetDvar( "ads_dof_farStartScale", 	1.15 );
	SetDvar( "ads_dof_farEndScale", 	3 );
	SetDvar( "ads_dof_nearBlur", 		4 );
	SetDvar( "ads_dof_farBlur", 		1.5 );
	SetDvar( "ads_dof_debug", 			0 );
	
	// Default Depth of Field (Disabled)
	nearStart 	= 1;
	nearEnd 	= 1;
	nearBlur	= 4.5;
	farStart 	= 500;
	farEnd 		= 500;
	farBlur 	= 0.05;
	
	//level.dof 					= SpawnStruct();
	level.dof = [];
	
	// Base Layer (weight is implicit 1) (default values are such that DOF is disabled)
	level.dof["base"] 						= [];
	level.dof["base"]["current"] 			= [];
	level.dof["base"]["goal"] 				= [];
	level.dof["base"]["timeRemaining"] 		= 0.0;
	dof_set_generic( "base", "current", nearStart, nearEnd, nearBlur, farStart, farEnd, farBlur, 1.0 );
	dof_set_generic( "base", "goal", 0, 0, 0, 0, 0, 0, 0.0 );
	
	// Script Layer (overrides base layer) (weight > 0 means active)
	level.dof["script"] 					= [];
	level.dof["script"]["current"] 			= [];
	level.dof["script"]["goal"] 			= [];
	level.dof["script"]["timeRemaining"]	= 0.0;
	dof_set_generic( "script", "current", 0, 0, 0, 0, 0, 0, 0.0 );
	dof_set_generic( "script", "goal", 0, 0, 0, 0, 0, 0, 0.0 );
	
	// ADS Layer (overrides base/script layers) (weight > 0 means active)
	level.dof["ads"] 						= [];
	level.dof["ads"]["current"]				= [];
	level.dof["ads"]["goal"] 				= [];
	dof_set_generic( "ads", "current", 0, 0, 0, 0, 0, 0, 0.0 );
	dof_set_generic( "ads", "goal", 0, 0, 0, 0, 0, 0, 0.0 );
	
	// Results (blend processing funnels here before being sent to code)
	level.dof["results"] 					= [];
	level.dof["results"]["current"] 		= [];
	dof_set_generic( "results", "current", nearStart, nearEnd, nearBlur, farStart, farEnd, farBlur, 1.0 );
	
	foreach( player in level.players )
		player thread dof_update();
}

dof_set_base( nearStart, nearEnd, nearBlur, farStart, farEnd, farBlur, blend_time )
{
	dof_set_generic( "base", "goal", nearStart, nearEnd, nearBlur, farStart, farEnd, farBlur, 1.0 );
	level.dof["base"]["timeRemaining"] = blend_time;
	
	// Instant switch?
	if ( blend_time <= 0.0 )
		dof_set_generic( "base", "current", nearStart, nearEnd, nearBlur, farStart, farEnd, farBlur, 1.0 );
}

dof_enable_script( nearStart, nearEnd, nearBlur, farStart, farEnd, farBlur, blend_time )
{
	dof_set_generic( "script", "goal", nearStart, nearEnd, nearBlur, farStart, farEnd, farBlur, 1.0 );
	level.dof["script"]["timeRemaining"] = blend_time;
		
	if ( blend_time <= 0.0 )
		dof_set_generic( "script", "current", nearStart, nearEnd, nearBlur, farStart, farEnd, farBlur, 1.0 );
	else if ( level.dof["script"]["current"]["weight"] <= 0.0 )
		dof_set_generic( "script", "current", nearStart, nearEnd, nearBlur, farStart, farEnd, farBlur, 0.0 );
}

dof_disable_script( blend_time )
{
	level.dof["script"]["goal"]["weight"] = 0.0;
	level.dof["script"]["timeRemaining"] = blend_time;
	
	// Instant switch?
	if ( blend_time <= 0.0 )
		level.dof["script"]["current"]["weight"] = 0.0;
}

dof_enable_ads( nearStart, nearEnd, nearBlur, farStart, farEnd, farBlur, adsFrac )
{
	dof_set_generic( "ads", "goal", nearStart, nearEnd, nearBlur, farStart, farEnd, farBlur, adsFrac );
	if ( level.dof["ads"]["current"]["weight"] <= 0.0 )
		dof_set_generic( "ads", "current", nearStart, nearEnd, nearBlur, farStart, farEnd, farBlur, 0.0 );
}

dof_blend_interior_ads_element( currentValue, targetValue, maxChange, changeRate )
{
	if ( currentValue > targetValue )
	{
		changeVal = ( currentValue - targetValue ) * changeRate;
		if ( changeVal > maxChange )
			changeVal = maxChange;
		else if ( changeVal < 1 )
			changeVal = 1;
		
		if ( ( currentValue - changeVal ) <= targetValue )
			return targetValue;
		else
			return ( currentValue - changeVal );
	}
	else if ( currentValue < targetValue )
	{
		changeVal = ( targetValue - currentValue ) * changeRate;
		if ( changeVal > maxChange )
			changeVal = maxChange;
		else if ( changeVal < 1 )
			changeVal = 1;
		
		if ( ( currentValue + changeVal ) >= targetValue )
			return targetValue;
		else
			return ( currentValue + changeVal );
	}
	
	// No change
	return currentValue;
}

dof_blend_interior_ads()
{
	assert( IsPlayer( self ) );
		
	// Update weight of current based on adsFrac stored in goal
	adsFrac = level.dof["ads"]["goal"]["weight"];
	if ( adsFrac < 1.0 )
	{
		if ( self AdsButtonPressed() && self PlayerAds() > 0.0 )
			adsFrac = Min( 1, adsFrac + 0.7 );
		else
			adsFrac = 0;
		
		// Use the goal values directly at the adjusted fractional weight
		level.dof["ads"]["current"]["nearStart"] 	= level.dof["ads"]["goal"]["nearStart"];
		level.dof["ads"]["current"]["nearEnd"] 		= level.dof["ads"]["goal"]["nearEnd"];
		level.dof["ads"]["current"]["nearBlur"] 	= level.dof["ads"]["goal"]["nearBlur"];
		level.dof["ads"]["current"]["farStart"] 	= level.dof["ads"]["goal"]["farStart"];
		level.dof["ads"]["current"]["farEnd"] 		= level.dof["ads"]["goal"]["farEnd"];
		level.dof["ads"]["current"]["farBlur"] 		= level.dof["ads"]["goal"]["farBlur"];
		level.dof["ads"]["current"]["weight"] 		= adsFrac;

		return;
	}
	
	// Move current values towards goal values based on max change rate
	nearFarScalar 	 	= 0.1;
	nearFarMinChange 	= 10;
	nearStartMaxChange 	= Max( nearFarMinChange, Abs( level.dof["ads"]["current"]["nearStart"]  - level.dof["ads"]["goal"]["nearStart"] ) * nearFarScalar );
	nearEndMaxChange 	= Max( nearFarMinChange, Abs( level.dof["ads"]["current"]["nearEnd"]    - level.dof["ads"]["goal"]["nearEnd"] )   * nearFarScalar );
	farStartMaxChange 	= Max( nearFarMinChange, Abs( level.dof["ads"]["current"]["farStart"]   - level.dof["ads"]["goal"]["farStart"] )  * nearFarScalar );
	farEndMaxChange 	= Max( nearFarMinChange, Abs( level.dof["ads"]["current"]["farEnd"]     - level.dof["ads"]["goal"]["farEnd"] )    * nearFarScalar );
	blurMaxChange 	= 0.1;
	
	level.dof["ads"]["current"]["nearStart"] 	= dof_blend_interior_ads_element( level.dof["ads"]["current"]["nearStart"],	level.dof["ads"]["goal"]["nearStart"], 	nearStartMaxChange, 0.33 );
	level.dof["ads"]["current"]["nearEnd"] 		= dof_blend_interior_ads_element( level.dof["ads"]["current"]["nearEnd"], 	level.dof["ads"]["goal"]["nearEnd"], 	nearEndMaxChange, 0.33 );
	level.dof["ads"]["current"]["nearBlur"] 	= dof_blend_interior_ads_element( level.dof["ads"]["current"]["nearBlur"], 	level.dof["ads"]["goal"]["nearBlur"], 	blurMaxChange, 0.33 );
	level.dof["ads"]["current"]["farStart"] 	= dof_blend_interior_ads_element( level.dof["ads"]["current"]["farStart"], 	level.dof["ads"]["goal"]["farStart"], 	farStartMaxChange, 0.33 );
	level.dof["ads"]["current"]["farEnd"] 		= dof_blend_interior_ads_element( level.dof["ads"]["current"]["farEnd"], 	level.dof["ads"]["goal"]["farEnd"], 	farEndMaxChange, 0.33 );
	level.dof["ads"]["current"]["farBlur"] 		= dof_blend_interior_ads_element( level.dof["ads"]["current"]["farBlur"], 	level.dof["ads"]["goal"]["farBlur"], 	blurMaxChange, 0.33 );
	level.dof["ads"]["current"]["weight"] 		= 1.0;
}

dof_disable_ads()
{
	level.dof["ads"]["goal"]["weight"] = 0.0;
	level.dof["ads"]["current"]["weight"] = 0.0;
}

dof_apply_to_results( layerName )
{
	layer_weight = level.dof[layerName]["current"]["weight"];
	inverse_weight = 1.0 - layer_weight;
	
	level.dof["results"]["current"]["nearStart"] 	= ( level.dof["results"]["current"]["nearStart"] * inverse_weight )	+ ( level.dof[layerName]["current"]["nearStart"] * layer_weight );
	level.dof["results"]["current"]["nearEnd"] 		= ( level.dof["results"]["current"]["nearEnd"] * inverse_weight ) 	+ ( level.dof[layerName]["current"]["nearEnd"] * layer_weight );
	level.dof["results"]["current"]["nearBlur"] 	= ( level.dof["results"]["current"]["nearBlur"] * inverse_weight ) 	+ ( level.dof[layerName]["current"]["nearBlur"] * layer_weight );
	level.dof["results"]["current"]["farStart"] 	= ( level.dof["results"]["current"]["farStart"] * inverse_weight ) 	+ ( level.dof[layerName]["current"]["farStart"] * layer_weight );
	level.dof["results"]["current"]["farEnd"] 		= ( level.dof["results"]["current"]["farEnd"] * inverse_weight ) 	+ ( level.dof[layerName]["current"]["farEnd"] * layer_weight );
	level.dof["results"]["current"]["farBlur"] 		= ( level.dof["results"]["current"]["farBlur"] * inverse_weight ) 	+ ( level.dof[layerName]["current"]["farBlur"] * layer_weight );
}

dof_calc_results()
{
	Assert( IsPlayer( self ) );
	
	// Blend each layer internally
	dof_blend_interior_generic( "base" );
	dof_blend_interior_generic( "script" );
	self dof_blend_interior_ads();
	
	// Apply layers in succession with their associated weights
	dof_apply_to_results( "base" );
	dof_apply_to_results( "script" );
	dof_apply_to_results( "ads" );
	
	// Clamp the results
	nearStart 	= level.dof["results"]["current"]["nearStart"];
	nearEnd 	= level.dof["results"]["current"]["nearEnd"];
	nearBlur 	= level.dof["results"]["current"]["nearBlur"];
	farStart 	= level.dof["results"]["current"]["farStart"];
	farEnd 		= level.dof["results"]["current"]["farEnd"];
	farBlur 	= level.dof["results"]["current"]["farBlur"];

	// All ranges must be >= 0
	nearStart 	= Max( 0, nearStart );
	nearEnd 	= Max( 0, nearEnd );
	farStart 	= Max( 0, farStart );
	farEnd 		= Max( 0, farEnd );
	
	// Near blur 4 <= val <= 10
	nearBlur 	= Max( 4, nearBlur );
	nearBlur 	= Min( 10, nearBlur );
	
	// Far blur 0 <= val <= near blur
	farBlur 	= Max( 0, farBlur );
	farBlur 	= Min( nearBlur, farBlur );
	
	// Far start >= nearEnd unless farBlur is 0
	if ( farBlur > 0.0 )
	{
		farStart = Max( nearEnd, farStart );
	}
	
	level.dof["results"]["current"]["nearStart"]	= nearStart;
	level.dof["results"]["current"]["nearEnd"]		= nearEnd;
	level.dof["results"]["current"]["nearBlur"]		= nearBlur;
	level.dof["results"]["current"]["farStart"]		= farStart;
	level.dof["results"]["current"]["farEnd"]		= farEnd;
	level.dof["results"]["current"]["farBlur"]		= farBlur;
}

dof_process_ads()
{
	Assert( IsPlayer( self ) );
	
	adsFrac = self PlayerAds();
/#
	if ( getDvarInt( "ads_dof_debug", 0 ) )
		adsFrac = 1.0;
#/	
	if ( adsFrac <= 0.0 )
	{
		dof_disable_ads();
		return;
	}
	
	traceDist 		= getdvarfloat( "ads_dof_tracedist", 		4096 );
	maxEnemyDist	= getdvarfloat( "ads_dof_maxEnemyDist",		0 );
	nearStartScale 	= getdvarfloat( "ads_dof_nearStartScale", 	0.25 );
	nearEndScale 	= getdvarfloat( "ads_dof_nearEndScale", 	0.85 );
	farStartScale 	= getdvarfloat( "ads_dof_farStartScale", 	1.15 );
	farEndScale 	= getdvarfloat( "ads_dof_farEndScale", 		3 );
	nearBlur 		= getdvarfloat( "ads_dof_nearBlur", 		4 );
	farBlur 		= getdvarfloat( "ads_dof_farBlur", 			2.5 );
	
	playerEye = self GetEye();
	playerAnglesRel = self GetPlayerAngles();
	if ( IsDefined( self.dof_ref_ent ) )
		playerAngles = CombineAngles( self.dof_ref_ent.angles, playerAnglesRel );
	else
		playerAngles = playerAnglesRel;
	playerForward = VectorNormalize( AnglesToForward( playerAngles ) );

	trace = BulletTrace( playerEye, playerEye + ( playerForward * traceDist ), true, self, true );
	enemies = GetAIArray( "axis" );

	// Level-specific weapon ADS overrides
	weapon = self getcurrentweapon();
	if ( isdefined( level.special_weapon_dof_funcs[ weapon ] ) )
	{
		[[ level.special_weapon_dof_funcs[ weapon ] ]]( trace, enemies, playerEye, playerForward, adsFrac );
		return;
	}
	
	if ( trace[ "fraction" ] == 1 )
	{
		traceDist = 2048;
		nearEnd = 256;
		farStart = traceDist * farStartScale * 2;
	}
	else
	{
		traceDist = Distance( playerEye, trace[ "position" ] );
		nearEnd = traceDist * nearStartScale;	// mkornkven: Shouldn't this be nearEndScale?
		farStart = traceDist * farStartScale;
	}

	foreach( enemy in enemies )
	{
		enemyDir = VectorNormalize( enemy.origin - playerEye );
		
		dot = VectorDot( playerForward, enemyDir );
		if ( dot < 0.923 ) // 45 degrees
			continue;
		
		distFrom = Distance( playerEye, enemy.origin );
		
		if ( distFrom - 30 < nearEnd )
			nearEnd = distFrom - 30;

		distFromFar = Min( distFrom, maxEnemyDist );
		
		if ( distFromFar + 30 > farStart )
			farStart = distFromFar + 30;
	}
	
	if ( nearEnd > farStart )
		nearEnd = farStart - 256;

	if ( nearEnd > traceDist )
		nearEnd = traceDist - 30;

	if ( nearEnd < 1 )
		nearEnd = 1;

	if ( farStart < traceDist )
		farStart = traceDist;
		
	nearStart 	= nearEnd * nearStartScale;
	farEnd 		= farStart * farEndScale;
	
	dof_enable_ads( nearStart, nearEnd, nearBlur, farStart, farEnd, farBlur, adsFrac );
}

javelin_dof( trace, enemies, playerEye, playerForward, adsFrac )
{
	if ( adsFrac < 0.88 )
	{
		self dof_disable_ads();
		return;
	}

	nearEnd 	= 10000;
	farStart 	= -1;
	nearEnd 	= 2400;
	nearStart 	= 2400;

	for ( index = 0; index < enemies.size; index++ )
	{
		enemyDir = VectorNormalize( enemies[ index ].origin - playerEye );

		dot = VectorDot( playerForward, enemyDir );
		if ( dot < 0.923 )// 45 degrees
			continue;

		distFrom = Distance( playerEye, enemies[ index ].origin );
		if ( distFrom < 2500 )
			distFrom = 2500;

		if ( distFrom - 30 < nearEnd )
			nearEnd = distFrom - 30;

		if ( distFrom + 30 > farStart )
			farStart = distFrom + 30;
	}
	
	if ( nearEnd > farStart )
	{
		nearEnd 	= 2400;
		farStart 	= 3000;
	}
	else
	{
		if ( nearEnd < 50 )
			nearEnd = 50;

		if ( farStart > 2500 )
			farStart = 2500;
		else 
		if ( farStart < 1000 )
			farStart = 1000;
	}

	traceDist = Distance( playerEye, trace[ "position" ] );
	if ( traceDist < 2500 )
		traceDist = 2500;

	if ( nearEnd > traceDist )
		nearEnd = traceDist - 30;

	if ( nearEnd < 1 )
		nearEnd = 1;

	if ( farStart < traceDist )
		farStart = traceDist;
		
	if ( nearStart >= nearEnd )
		nearStart = nearEnd - 1;

	farEnd 		= farStart * 4;
	nearBlur 	= 4;
	farBlur 	= 1.8;
		
	dof_enable_ads( nearStart, nearEnd, nearBlur, farStart, farEnd, farBlur, adsFrac );
}

dof_update()
{
	Assert( IsPlayer( self ) );
	
/#
	self thread dof_debug();			
#/

	while( 1 )
	{
		waitframe();
		
		if ( level.level_specific_dof )
			continue;
/# 
		if ( GetDvarInt( "scr_art_tweak" ) )
			continue;
#/
		if ( !GetDvarInt( "scr_dof_enable" ) )
			continue;
		
		// Update the DOF
		self dof_process_ads();
		
		// Calc the results
		self dof_calc_results();
		
		// Clamp the results
		nearStart 	= level.dof["results"]["current"]["nearStart"];
		nearEnd 	= level.dof["results"]["current"]["nearEnd"];
		nearBlur 	= level.dof["results"]["current"]["farStart"];
		farStart 	= level.dof["results"]["current"]["farEnd"];
		farEnd 		= level.dof["results"]["current"]["nearBlur"];
		farBlur 	= level.dof["results"]["current"]["farBlur"];
			
		// Set the DOF
		self SetDepthOfField( nearStart, nearEnd, nearBlur, farStart, farEnd, farBlur );
	}
}

/#
dof_debug()
{
	assert( IsPlayer( self ) );
	
	setDvarIfUninitialized( "scr_dof_debug", "0" );
	
	while( 1 )
	{
		while( 1 )
		{
			if ( GetDebugDvar( "scr_dof_debug" ) != "0" )
				break;
			wait .5;
		}
		self thread dof_debug_start();
		while( 1 )
		{
			if ( GetDebugDvar( "scr_dof_debug" ) == "0" )
				break;
			wait .5;
		}
		self thread dof_debug_stop();
	}
}

dof_debug_add_hudelem_for_layer( layerName, xVal, yVal )
{
	textelem 			= NewHudElem();
	textelem.x 			= xVal;
	textelem.y 			= yVal;
	textelem.alignx 	= "left";
	textelem.aligny 	= "top";
	textelem.horzalign 	= "fullscreen";
	textelem.vertalign 	= "fullscreen";
	textelem.font 		= "smallfixed";
	textelem.fontscale 	= 0.5;
	textelem setText( layerName );
	
	barelem 			= NewHudElem();
	barelem.x 			= xVal + 240;
	barelem.y 			= yVal;
	barelem.alignx 		= "left";
	barelem.aligny 		= "top";
	barelem.horzalign 		= "fullscreen";
	barelem.vertalign		= "fullscreen";
	barelem SetShader( "black", 1, 8 );
	
	textelem.bar = barelem;
	
	level.dof_debug_elems[layerName] = textelem;
}

dof_debug_update_hudelem_for_layer( layerName )
{
	elem = level.dof_debug_elems[layerName];
	
	if ( layerName == "heading" )
	{
		layerName 	= "";
		nearStart 	= "NS";
		nearEnd 	= "NE";
		nearBlur 	= "NB";
		farStart 	= "FS";
		farEnd 		= "FE";
		farBlur 	= "FB";
		weight 		= "W";
		actual_weight = 0.0;
	}
	else
	{
		nearStart 	= round_float( level.dof[layerName]["current"]["nearStart"], 2 );
		nearEnd 	= round_float( level.dof[layerName]["current"]["nearEnd"], 2 );
		nearBlur 	= round_float( level.dof[layerName]["current"]["nearBlur"], 2 );
		farStart 	= round_float( level.dof[layerName]["current"]["farStart"], 2 );
		farEnd 		= round_float( level.dof[layerName]["current"]["farEnd"], 2 );
		farBlur 	= round_float( level.dof[layerName]["current"]["farBlur"], 2 );
		weight 		= round_float( level.dof[layerName]["current"]["weight"], 2 );
		actual_weight = level.dof[layerName]["current"]["weight"];
	}

	layer_width = 10;
	value_width = 8;
	
	text = layerName;
	for ( i = 0; i < ( layer_width - layerName.size ); i++ )
		text += " ";
	text += nearStart;
	for ( i = 0; i < ( value_width - string( nearStart ).size ); i++ )
		text += " ";
	text += nearEnd;
	for ( i = 0; i < ( value_width - string( nearEnd ).size ); i++ )
		text += " ";
	text += nearBlur;
	for ( i = 0; i < ( value_width - string( nearBlur ).size ); i++ )
		text += " ";
	text += farStart;
	for ( i = 0; i < ( value_width - string( farStart ).size ); i++ )
		text += " ";
	text += farEnd;
	for ( i = 0; i < ( value_width - string( farEnd ).size ); i++ )
		text += " ";
	text += farBlur;
	for ( i = 0; i < ( value_width - string( farBlur ).size ); i++ )
		text += " ";
	text += weight;

	elem setText( text );
	
	bar_width = 100;
	
	bar = elem.bar;
	bar SetShader( "black", int( bar_width * actual_weight ), 8 );
}

dof_debug_start()
{
	level notify( "dof_debug_stop" );
	level endon( "dof_debug_stop" );
	
	x = 40;
	y = 40;
	ySpacing = 10;
	
	level.dof_debug_elems = [];
	dof_debug_add_hudelem_for_layer( "heading", x, y );
	y += ySpacing;
	dof_debug_add_hudelem_for_layer( "base", x, y );
	y += ySpacing;
	dof_debug_add_hudelem_for_layer( "script", x, y );
	y += ySpacing;
	dof_debug_add_hudelem_for_layer( "ads", x, y );
	y += ySpacing;
	dof_debug_add_hudelem_for_layer( "results", x, y );
		
	dof_debug_update_hudelem_for_layer( "heading" );
	
	while( 1 )
	{
		waitframe();
		
		dof_debug_update_hudelem_for_layer( "base" );
		dof_debug_update_hudelem_for_layer( "script" );
		dof_debug_update_hudelem_for_layer( "ads" );
		dof_debug_update_hudelem_for_layer( "results" );
	}
}

dof_debug_stop()
{
	level notify( "dof_debug_stop" );
	
	level.dof_debug_elems["heading"].bar destroy();
	level.dof_debug_elems["base"].bar destroy();
	level.dof_debug_elems["script"].bar destroy();
	level.dof_debug_elems["ads"].bar destroy();
	level.dof_debug_elems["results"].bar destroy();

	level.dof_debug_elems["heading"] destroy();
	level.dof_debug_elems["base"] destroy();
	level.dof_debug_elems["script"] destroy();
	level.dof_debug_elems["ads"] destroy();
	level.dof_debug_elems["results"] destroy();
	
	level.dof_debug_elems = undefined;
}
#/

/#
hud_init()
{
	listsize = 7;

	hudelems = [];
	spacer = 15;
	div = int( listsize / 2 );
	org = 240 - div * spacer;
	alphainc = .5 / div;
	alpha = alphainc;

	for ( i = 0;i < listsize;i++ )
	{
		hudelems[ i ] = _newhudelem();
		hudelems[ i ].location = 0;
		hudelems[ i ].alignX = "left";
		hudelems[ i ].alignY = "middle";
		hudelems[ i ].foreground = 1;
		hudelems[ i ].fontScale = 2;
		hudelems[ i ].sort = 20;
		if ( i == div )
			hudelems[ i ].alpha = 1;
		else
			hudelems[ i ].alpha = alpha;

		hudelems[ i ].x = 20;
		hudelems[ i ].y = org;
		hudelems[ i ] _settext( "." );

		if ( i == div )
			alphainc *= -1;

		alpha += alphainc;

		org += spacer;
	}

	level.spam_group_hudelems = hudelems;

	crossHair = _newhudelem();
	crossHair.location = 0;
	crossHair.alignX = "center";
	crossHair.alignY = "bottom";
	crossHair.foreground = 1;
	crossHair.fontScale = 2;
	crossHair.sort = 20;
	crossHair.alpha = 1;
	crossHair.x = 320;
	crossHair.y = 244;
	crossHair _settext( "." );
	level.crosshair = crossHair;

	// setup "crosshair"
	crossHair = _newhudelem();
	crossHair.location = 0;
	crossHair.alignX = "center";
	crossHair.alignY = "bottom";
	crossHair.foreground = 1;
	crossHair.fontScale = 2;
	crossHair.sort = 20;
	crossHair.alpha = 0;
	crossHair.x = 320;
	crossHair.y = 244;
	crossHair setvalue( 0 );
	level.crosshair_value = crossHair;

	sunflare = maps\_hud_util::createFontString( "default", 2 );
	sunflare.alignX = "right";
	sunflare.horzAlign = "right";
	sunflare.vertAlign = "middle";
	level.sunflare_hudelem = sunflare;
}

_newhudelem()
{
	if ( !isdefined( level.scripted_elems ) )
	 	level.scripted_elems = [];
	elem = newhudelem();
	level.scripted_elems[ level.scripted_elems.size ] = elem;
	return elem;
}

_settext( text )
{
	self.realtext = text;
	self setDevText( "_" );
	self thread _clearalltextafterhudelem();
	sizeofelems = 0;
	foreach ( elem in level.scripted_elems )
	{
		if ( isdefined( elem.realtext ) )
		{
			sizeofelems += elem.realtext.size;
			elem setDevText( elem.realtext );
		}
	}
	println( "Size of elems: " + sizeofelems );
}

_clearalltextafterhudelem()
{
	if ( level._clearalltextafterhudelem )
		return;
	level._clearalltextafterhudelem = true;
	self clearalltextafterhudelem();
	wait .05;
	level._clearalltextafterhudelem = false;

}

setgroup_up()
{
	reset_cmds();
	
	current_vision_set_name = level.vision_set_transition_ent.vision_set;
	
	index = array_find( level.vision_set_names, current_vision_set_name );
	if ( !IsDefined( index ) )
		return;
	
	index -= 1;
	
	if ( index < 0 )
		return;

	setcurrentgroup( level.vision_set_names[index] );
}

setgroup_down()
{
	reset_cmds();
	
	current_vision_set_name = level.vision_set_transition_ent.vision_set;
	
	index = array_find( level.vision_set_names, current_vision_set_name );
	if ( !IsDefined( index ) )
		return;

	index += 1;
	
	if ( index >= level.vision_set_names.size )
		return;
	
	setcurrentgroup( level.vision_set_names[index] );
}

setsunflare_up()
{
	reset_cmds();
	index = 0;
	keys = getarraykeys( level.sunflare_settings );
	for ( i = 0;i < keys.size;i++ )
		if ( keys[ i ] == level.current_sunflare_setting )
		{
			index = (i + 1)%keys.size;
				break;
		}
	setcurrentsunflare( keys[index] );
}

setsunflare_down()
{
	reset_cmds();
	index = 0;
	keys = getarraykeys( level.sunflare_settings );
	for ( i = 0;i < keys.size;i++ )
		if ( keys[ i ] == level.current_sunflare_setting )
		{
			index = (i - 1 + keys.size)%keys.size;
				break;
		}
	setcurrentsunflare( keys[index] );
}

reset_cmds()
{
	SetDevDvar( "scr_select_art_next", 0 );
	SetDevDvar( "scr_select_art_prev", 0 );
	SetDevDvar( "scr_select_sunflare_next", 0 );
	SetDevDvar( "scr_select_sunflare_prev", 0 );
}

setcurrentgroup( group )
{
	level.spam_model_current_group = group;
	
	index = array_find( level.vision_set_names, group );
	if ( !IsDefined( index ) )
		index = -1;
	
	hud_list_size = level.spam_group_hudelems.size;
	hud_start_index = index - int( hud_list_size / 2 );
	
	for ( i = 0; i < hud_list_size; i++ )
	{
		hud_index = hud_start_index + i;
		if ( hud_index < 0 || hud_index >= level.vision_set_names.size )
		{
			level.spam_group_hudelems[i] _settext( "." );
			continue;
		}
		
		level.spam_group_hudelems[i] _settext( level.vision_set_names[hud_index] );
	}
	
	group_name = "";
	if ( index >= 0 )
		group_name = level.vision_set_names[ index ];
	
	vision_set_fog_changes( group_name, 0 );
}

setcurrentsunflare( sunflare )
{
	level.sunflare_hudelem setText( "Sunflare: " + sunflare );
	sunflare_changes( sunflare, 0 );
}
#/
	
sunflare_changes( sunflare_name, script_delay )
{
	if ( !isdefined( level.sunflare_settings[ sunflare_name ] ) )
		return;
	
	self notify( "sunflare_start_adjust" );
	self endon( "sunflare_start_adjust" );
	
	start_time = GetTime();
	time_total = script_delay * 1000;
	start_position = GetDvarVector( "r_sunflare_position", (0,0,0) );
	time_elapsed = GetTime() - start_time;
	target_position = level.sunflare_settings[ sunflare_name ].position;
	level.current_sunflare_setting = sunflare_name;
	
	while( time_elapsed < time_total )
	{
		target_position = level.sunflare_settings[ sunflare_name ].position;
		fraction = Min( float( time_elapsed / time_total ), 1 );
		pos = start_position + (( target_position - start_position )*(fraction));
		SetDvar( "r_sunflare_position", pos );
		setSunFlarePosition( pos );
		wait( 0.05 );
		time_elapsed = GetTime() - start_time;
	}
	
	SetDvar( "r_sunflare_position", level.sunflare_settings[ sunflare_name ].position );
	setSunFlarePosition( target_position );
}

init_fog_transition()
{
	if ( !IsDefined( level.fog_transition_ent ) )
	{
		level.fog_transition_ent = SpawnStruct();
		level.fog_transition_ent.fogset = "";
		level.fog_transition_ent.time = 0;
	}
}
/#
playerInit()
{
 	last_vision_set = level.vision_set_transition_ent.vision_set;
 	if ( !IsDefined( last_vision_set ) || last_vision_set == "" )
 		last_vision_set = level.script;
 	
	//clear these so the vision set will happen.
 	level.vision_set_transition_ent.vision_set = "";
 	level.vision_set_transition_ent.time = "";

	init_fog_transition();
 	level.fog_transition_ent.fogset = "";
 	level.fog_transition_ent.time = ""; 

 	setcurrentgroup( last_vision_set );
}
#/
	
set_fog_progress( progress )
{
	anti_progress 		= 1 - progress;
	startdist 			= self.start_neardist * anti_progress + self.end_neardist * progress;
	halfwayDist 		= self.start_fardist * anti_progress + self.end_fardist * progress;
	color 				= self.start_color * anti_progress + self.end_color * progress;
	HDRColorIntensity	= self.start_HDRColorIntensity * anti_progress + self.end_HDRColorIntensity * progress;
	start_opacity 		= self.start_opacity;
	end_opacity 		= self.end_opacity;
	skyFogIntensity		= self.start_skyFogIntensity;
	skyFogMinAngle		= self.start_skyFogMinAngle;
	skyFogMaxAngle		= self.start_skyFogMaxAngle;

	skyFogIntensity		= self.start_skyFogIntensity * anti_progress + self.end_skyFogIntensity * progress;
	skyFogMinAngle		= self.start_skyFogMinAngle * anti_progress + self.end_skyFogMinAngle * progress;
	skyFogMaxAngle		= self.start_skyFogMaxAngle * anti_progress + self.end_skyFogMaxAngle * progress;

	if ( !isdefined( start_opacity ) )
		start_opacity = 1;

	if ( !isdefined( end_opacity ) )
		end_opacity = 1;

	opacity = start_opacity * anti_progress + end_opacity * progress;

	if ( self.sunfog_enabled )
	{
		sun_color				= self.start_suncolor * anti_progress + self.end_suncolor * progress;
		HDRSunColorIntensity	= self.start_HDRSunColorIntensity * anti_progress + self.end_HDRSunColorIntensity * progress;
		sun_dir					= self.start_sundir * anti_progress + self.end_sundir * progress;
		begin_angle				= self.start_sunBeginFadeAngle * anti_progress + self.end_sunBeginFadeAngle * progress;
		end_angle				= self.start_sunEndFadeAngle * anti_progress + self.end_sunEndFadeAngle * progress;
		sun_fog_scale			= self.start_sunFogScale * anti_progress + self.end_sunFogScale * progress;	

		SetExpFog(
			startdist,
			halfwaydist,
			color[ 0 ],
			color[ 1 ],
			color[ 2 ],
			HDRColorIntensity,
			opacity,
			0.4,
			sun_color[ 0 ],
			sun_color[ 1 ],
			sun_color[ 2 ],
			HDRSunColorIntensity,
			sun_dir,
			begin_angle,
			end_angle,
			sun_fog_scale,
			skyFogIntensity,	
			skyFogMinAngle,	
			skyFogMaxAngle
		 );
	}
	else
	{
		SetExpFog(
			startdist,
			halfwaydist,
			color[ 0 ],
			color[ 1 ],
			color[ 2 ],
			HDRColorIntensity,
			opacity,
			0.4,
			skyFogIntensity,	
			skyFogMinAngle,	
			skyFogMaxAngle	
		 );
	}
}
