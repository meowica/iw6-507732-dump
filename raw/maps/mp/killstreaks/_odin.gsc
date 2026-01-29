#include maps\mp\_utility;
#include common_scripts\utility;

init()
{
	level.killstreakFuncs[ "odin_support" ] = ::tryUseOdinSupport;

	level.odinSettings = [];	

	level.odinSettings[ "odin_support" ] = SpawnStruct();
	level.odinSettings[ "odin_support" ].timeOut =				60.0;	
	level.odinSettings[ "odin_support" ].streakName =			"odin_support";
	level.odinSettings[ "odin_support" ].vehicleInfo =			"odin_mp";
	level.odinSettings[ "odin_support" ].modelBase =			"vehicle_odin_mp";
	level.odinSettings[ "odin_support" ].teamSplash =			"used_odin_support";	
	level.odinSettings[ "odin_support" ].ui_num =				0; // let lua know what to show	
	level.odinSettings[ "odin_support" ].targetingFXID = 		LoadFX( "fx/misc/ui_flagbase_green" );
	level.odinSettings[ "odin_support" ].airdropTimer =			20;
	level.odinSettings[ "odin_support" ].smokeTimer = 			10;
	level.odinSettings[ "odin_support" ].markingTimer = 		7;
	level.odinSettings[ "odin_support" ].juggernautTimer = 		60;
	// the weapon can be mutliple types
	level.odinSettings[ "odin_support" ].weapon[ "airdrop" ] = SpawnStruct();
	level.odinSettings[ "odin_support" ].weapon[ "airdrop" ].projectile = 		"odin_projectile_airdrop_mp";
	level.odinSettings[ "odin_support" ].weapon[ "airdrop" ].rumble = 			"smg_fire";
	level.odinSettings[ "odin_support" ].weapon[ "airdrop" ].ammoOmnvar = 		"ui_odin_airdrop_ammo";
	level.odinSettings[ "odin_support" ].weapon[ "airdrop" ].reloadTimer = 		20;
	
	level.odinSettings[ "odin_support" ].weapon[ "marking" ] = SpawnStruct();
	level.odinSettings[ "odin_support" ].weapon[ "marking" ].projectile = 		"odin_projectile_marking_mp";
	level.odinSettings[ "odin_support" ].weapon[ "marking" ].rumble = 			"heavygun_fire";
	level.odinSettings[ "odin_support" ].weapon[ "marking" ].ammoOmnvar = 		"ui_odin_marking_ammo";
	level.odinSettings[ "odin_support" ].weapon[ "marking" ].reloadTimer = 		4;
	
	level.odinSettings[ "odin_support" ].weapon[ "smoke" ] = SpawnStruct();
	level.odinSettings[ "odin_support" ].weapon[ "smoke" ].projectile = 		"odin_projectile_smoke_mp";
	level.odinSettings[ "odin_support" ].weapon[ "smoke" ].rumble = 			"smg_fire";
	level.odinSettings[ "odin_support" ].weapon[ "smoke" ].ammoOmnvar = 		"ui_odin_smoke_ammo";
	level.odinSettings[ "odin_support" ].weapon[ "smoke" ].reloadTimer = 		7;
	
	level.odinSettings[ "odin_support" ].weapon[ "juggernaut" ] = SpawnStruct();
	level.odinSettings[ "odin_support" ].weapon[ "juggernaut" ].projectile = 	"odin_projectile_smoke_mp";
	level.odinSettings[ "odin_support" ].weapon[ "juggernaut" ].rumble = 		"heavygun_fire";
	level.odinSettings[ "odin_support" ].weapon[ "juggernaut" ].ammoOmnvar = 	"ui_odin_juggernaut_ammo";
	level.odinSettings[ "odin_support" ].weapon[ "juggernaut" ].reloadTimer = 	level.odinSettings[ "odin_support" ].timeOut; // make sure they can only call 1 in
	
	// check to see if the mesh already exists, b/c heli_pilot sets this up in the init
	if( !IsDefined( level.heli_pilot_mesh ) )
	{
		// throw the mesh way up into the air, the gdt entry for the vehicle must match
		level.heli_pilot_mesh = GetEnt( "heli_pilot_mesh", "targetname" );
		if( !IsDefined( level.heli_pilot_mesh ) )
			PrintLn( "heli_pilot_mesh doesn't exist in this level: " + level.script );
		else
			level.heli_pilot_mesh.origin += getHeliPilotMeshOffset();
	}

/#
	SetDevDvarIfUninitialized( "scr_odin_support_timeout", 60.0 );
#/
}

tryUseOdinSupport( lifeId )
{
	odinType = "odin_support";
		
	numIncomingVehicles = 1;
	
	if( currentActiveVehicleCount() >= maxVehiclesAllowed() || level.fauxVehicleCount + numIncomingVehicles >= maxVehiclesAllowed() )
	{
		self IPrintLnBold( &"KILLSTREAKS_TOO_MANY_VEHICLES" );
		return false;
	}

	// increment the faux vehicle count before we spawn the vehicle so no other vehicles try to spawn
	incrementFauxVehicleCount();
	
	odin = createOdin( odinType );

	if( !IsDefined( odin ) )
	{
		// decrement the faux vehicle count since this failed to spawn
		decrementFauxVehicleCount();

		return false;	
	}
	
	self thread startOdin( odin );
	
	level thread teamPlayerCardSplash( level.odinSettings[ odinType ].teamSplash, self, self.team );
	
	return true;
}

createOdin( odinType ) // self == player
{
	traceOffset = ( 0, 0, 2500 );
	traceStart = ( self.origin * ( 1, 1, 0 ) ) + ( getHeliPilotMeshOffset() + traceOffset );
	traceEnd = ( self.origin * ( 1, 1, 0 ) ) + ( getHeliPilotMeshOffset() - traceOffset );
	traceResult = BulletTrace( traceStart, traceEnd, false, undefined, false, false, true );
	if( !IsDefined( traceResult ) )
		AssertMsg( "The trace didn't hit the heli_pilot_mesh. Please grab an MP scripter." );
	
	startPos = ( traceResult[ "position" ] - getHeliPilotMeshOffset() ) + ( 0, 0, 1000 ); // offset to make sure we're on top of the mesh
	startAng = ( 0, 0, 0 );
	
	odin = SpawnHelicopter( self, startPos, startAng, level.odinSettings[ odinType ].vehicleInfo, level.odinSettings[ odinType ].modelBase );
	if( !IsDefined( odin ) )
		return;

	odin.speed = 40;
	odin.owner = self;
	odin SetOtherEnt( self );
	odin.team = self.team;
	odin.odinType = odinType;
		
	odin thread odin_playerExit();
	odin thread odin_watchDeath();
	odin thread odin_watchTimeout();
	odin thread odin_watchOwnerLoss();
	odin thread odin_watchRoundEnd();
	odin thread odin_watchTargeting();

	odin.owner maps\mp\_matchdata::logKillstreakEvent( level.odinSettings[ odinType ].streakName, startPos );	
	
	return odin;
}

startOdin( odin ) // self == player
{
	// TODO: we're doing a fade to black now but we should try and do a reverse slam zoom to get into this
	
	level endon( "game_ended" );
	odin endon( "death" );

	self.restoreAngles = VectorToAngles( AnglesToForward( self.angles ) );
	
	self setUsingRemote( odin.odinType );

	if( GetDvarInt( "camera_thirdPerson" ) )
		self setThirdPersonDOF( false );
	
	self thread watchIntroCleared( odin );
	
	self freezeControlsWrapper( true );
	result = self maps\mp\killstreaks\_killstreaks::initRideKillstreak( odin.odinType );
	if( result != "success" )
	{
		if ( result != "disconnect" )
			self clearUsingRemote();

		if( IsDefined( self.disabledWeapon ) && self.disabledWeapon )
			self _enableWeapon();
		self notify( "death" );

		return false;
	}	

	maps\mp\killstreaks\_juggernaut::disableJuggernaut();
		
	self freezeControlsWrapper( false );

	self PlayLocalSound( "odin_slamzoom_out" );
	
	// link the heli into the mesh and give them control
	self RemoteControlVehicle( odin );
}

watchIntroCleared( odin ) // self == player
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	self waittill( "intro_cleared" );
	self SetClientOmnvar( "ui_odin", level.odinSettings[ odin.odinType ].ui_num );
}

//
//	state trackers
//

odin_watchDeath()
{
	level endon( "game_ended" );
	self endon( "gone" );
	
	self waittill( "death" );
	
	self.owner odin_EndRide( self );

	// decrement the faux vehicle count right before it is deleted this way we know for sure it is gone
	decrementFauxVehicleCount();
	
	if( IsDefined( self.targeting_marker ) )
		self.targeting_marker delete();
	
	self delete();
}

odin_watchTimeout()
{
	level endon ( "game_ended" );
	self endon( "death" );
	self.owner endon( "disconnect" );
	self.owner endon( "joined_team" );
	self.owner endon( "joined_spectators" );
		
	timeout = level.odinSettings[ self.odinType ].timeOut;
/#
	timeout = GetDvarFloat( "scr_" + self.odinType + "_timeout" );
#/
	maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( timeout );
	
	self thread odin_leave();
}


odin_watchOwnerLoss()
{
	level endon ( "game_ended" );
	self endon( "death" );
	self endon( "leaving" );

	self.owner waittill_any( "disconnect", "joined_team", "joined_spectators" );	
		
	//	leave
	self thread odin_leave();
}

odin_watchRoundEnd()
{
	self endon( "death" );
	self endon( "leaving" );	
	self.owner endon( "disconnect" );
	self.owner endon( "joined_team" );
	self.owner endon( "joined_spectators" );	

	level waittill_any( "round_end_finished", "game_ended" );

	//	leave
	self thread odin_leave();
}

odin_leave()
{
	self endon( "death" );
	self notify( "leaving" );

	self.owner odin_EndRide( self );
	
	//	remove
	self notify( "gone" );	

	// decrement the faux vehicle count right before it is deleted this way we know for sure it is gone
	decrementFauxVehicleCount();
	
	if( IsDefined( self.targeting_marker ) )
		self.targeting_marker delete();

	self delete();
}

odin_EndRide( odin )
{
	if( IsDefined( odin ) )
	{		
		self SetClientOmnvar( "ui_odin", -1 );
		
		odin notify( "end_remote" );
		
		self clearUsingRemote();
		
		if( GetDvarInt( "camera_thirdPerson" ) )
			self setThirdPersonDOF( true );			
			
		maps\mp\killstreaks\_juggernaut::enableJuggernaut();
		
		self RemoteControlVehicleOff( odin );
		
		self SetPlayerAngles( self.restoreAngles );	
					
		self thread odin_FreezeBuffer();
	}
}

odin_FreezeBuffer()
{
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );
	
	self freezeControlsWrapper( true );
	wait( 0.5 );
	self freezeControlsWrapper( false );
}

odin_playerExit() // self == odin
{
	if( !IsDefined( self.owner ) )
		return;

	owner = self.owner;

	level endon( "game_ended" );
	owner endon ( "disconnect" );
	owner endon ( "end_remote" );
	self endon ( "death" );

	while( true )
	{
		timeUsed = 0;
		while(	owner UseButtonPressed() )
		{	
			timeUsed += 0.05;
			if( timeUsed > 0.75 )
			{	
				self notify( "death" );
				return;
			}
			wait( 0.05 );
		}
		wait( 0.05 );
	}
}

odin_watchTargeting() // self == odin
{
	self endon( "death" );
	level endon( "game_ended" );
	
	owner = self.owner;
	owner endon( "disconnect" );
	
	// show a marker in the ground
	startTrace = self.origin;
	endTrace = startTrace + ( AnglesToForward( owner GetPlayerAngles() ) * 10000 );
	markerPos = BulletTrace( startTrace, endTrace, false, self );
	marker = Spawn( "script_model", markerPos[ "position" ] );
	marker SetModel( "projectile_bouncing_betty_grenade" );
	
	self.targeting_marker = marker;
	
	// keep it on the ground
	trace = BulletTrace( marker.origin + ( 0, 0, 50 ), marker.origin + ( 0, 0, -100 ), false, marker );
	marker.origin = trace[ "position" ];
	 
	// only the owner can see the targeting
	marker Hide();
	marker ShowToPlayer( owner );
	
	self thread showFX();
	self thread watchAirdropUse();
	self thread watchSmokeUse();
	self thread watchMarkingUse();
	self thread watchJuggernautUse();
	
	while( true )
	{
		startTrace = self.origin;
		endTrace = startTrace + ( AnglesToForward( owner GetPlayerAngles() ) * 10000 );
		markerPos = BulletTrace( startTrace, endTrace, false, self );
		marker.origin = markerPos[ "position" ];

		// keep it on the ground
		trace = BulletTrace( marker.origin + ( 0, 0, 50 ), marker.origin + ( 0, 0, -100 ), false, marker );
		marker.origin = trace[ "position" ];
		
		wait( 0.05 );
	}
}

watchAirdropUse() // self == odin
{
	self endon( "death" );
	level endon( "game_ended" );
	
	owner = self.owner;
	owner endon( "disconnect" );

	airdropUseTime = 0;
	owner SetClientOmnvar( "ui_odin_airdrop_ammo", 1 );
	
	owner NotifyOnPlayerCommand( "airdrop_action", "+frag" );
	
	// watch for button presses
	while( true )
	{
		owner waittill( "airdrop_action" );
		
		if( GetTime() >= airdropUseTime )
		{
			airdropUseTime = self odin_fireWeapon( "airdrop" );
			level thread maps\mp\killstreaks\_airdrop::doFlyBy( owner, self.targeting_marker.origin, randomFloat( 360 ), "airdrop_assault" );
		}
		else
			owner PlayLocalSound( "odin_negative_action" );
	
		wait( 1.0 );
	}
}

watchSmokeUse() // self == odin
{
	self endon( "death" );
	level endon( "game_ended" );
	
	owner = self.owner;
	owner endon( "disconnect" );

	smokeUseTime = 0;
	owner SetClientOmnvar( "ui_odin_smoke_ammo", 1 );

	owner NotifyOnPlayerCommand( "smoke_action", "+smoke" );
	
	// watch for button presses
	while( true )
	{
		owner waittill( "smoke_action" );
		
		if( GetTime() >= smokeUseTime )
			smokeUseTime = self odin_fireWeapon( "smoke" );
		else
			owner PlayLocalSound( "odin_negative_action" );
		
		wait( 1.0 );
	}
}

watchMarkingUse() // self == odin
{
	self endon( "death" );
	level endon( "game_ended" );
	
	owner = self.owner;
	owner endon( "disconnect" );

	markingUseTime = 0;
	owner SetClientOmnvar( "ui_odin_marking_ammo", 1 );

	owner NotifyOnPlayerCommand( "marking_action", "+attack" );
	owner NotifyOnPlayerCommand( "marking_action", "+attack_akimbo_accessible" ); // support accessibility control scheme

	// watch for button presses
	while( true )
	{
		owner waittill( "marking_action" );

		if( GetTime() >= markingUseTime )
		{
			markingUseTime = self odin_fireWeapon( "marking" );
			self thread doMarkingFlash( self.targeting_marker.origin + ( 0, 0, 10 ) );
		}
		else
			owner PlayLocalSound( "odin_negative_action" );

		wait( 1.0 );
	}
}

watchJuggernautUse() // self == odin
{
	self endon( "death" );
	level endon( "game_ended" );
	
	owner = self.owner;
	owner endon( "disconnect" );

	juggernautUseTime = 0;
	owner SetClientOmnvar( "ui_odin_juggernaut_ammo", 1 );

	owner NotifyOnPlayerCommand( "juggernaut_action", "+speed_throw" );
	owner NotifyOnPlayerCommand( "juggernaut_action", "+ads_akimbo_accessible" );

	// watch for button presses
	while( true )
	{
		owner waittill( "juggernaut_action" );

		if( GetTime() >= juggernautUseTime )
		{
			node = getJuggStartingPathNode( self.targeting_marker.origin );
			if( IsDefined( node ) )
			{
				juggernautUseTime = self odin_fireWeapon( "juggernaut" );
				self thread waitAndSpawnJugg( "reconAgent", node );
			}
			else 
				owner PlayLocalSound( "odin_negative_action" );
		}
		else if( IsDefined( self.juggernaut ) )
		{
			// since the juggernaut is already out, this will mark the position that he will guard
			owner PlayLocalSound( "odin_positive_action" );
			owner PlayRumbleOnEntity( "pistol_fire" );
			self.juggernaut maps\mp\bots\_bots_strategy::bot_protect_point( self.targeting_marker.origin, 128 );
			owner SetClientOmnvar( "ui_odin_juggernaut_ammo", 0 );
		}

		wait( 1.0 );
		
		// set the ammo to 2 so it'll show the move text
		if( IsDefined( self.juggernaut ) )
			owner SetClientOmnvar( "ui_odin_juggernaut_ammo", 2 );
	}
}

odin_fireWeapon( weaponType ) // self == odin
{
	owner = self.owner;
	weaponStruct = level.odinSettings[ self.odinType ].weapon[ weaponType ];
	
	MagicBullet( weaponStruct.projectile, self.origin + ( AnglesToForward( owner GetPlayerAngles() ) * 100 ), self.targeting_marker.origin, owner );
	owner PlayRumbleOnEntity( weaponStruct.rumble );
	owner SetClientOmnvar( weaponStruct.ammoOmnvar, 0 );
	self thread watchReload( weaponStruct.ammoOmnvar, weaponStruct.reloadTimer );
	
	return ( GetTime() + ( weaponStruct.reloadTimer * 1000 ) );
}

getJuggStartingPathNode( pos ) // self == odin
{
	// try to spawn the agent on a path node near the marker
	nearestPathNode = GetNodesInRadiusSorted( pos, 256, 0, 128, "Path" );	
	if( !IsDefined( nearestPathNode[ 0 ] ) )
		return;
	
	return nearestPathNode[ 0 ];
}

waitAndSpawnJugg( juggType, nearestPathNode ) // self == odin
{
	self endon( "death" );
	level endon( "game_ended" );
	
	owner = self.owner;
	owner endon( "disconnect" );
	
	pos = self.targeting_marker.origin;
	
	// waiting for the smoke to rise
	wait( 1.0 );
	
	// find an available agent
	agent = maps\mp\agents\_agent_utility::getFreeAgent( "squadmate" );	
	if( !IsDefined( agent ) )
		return false;

	// set the agent to the player's team
	agent maps\mp\agents\_agent_utility::set_agent_team( owner.team, owner );
	
	spawnOrigin = nearestPathNode.origin;
	spawnAngles = VectorToAngles( pos - spawnOrigin );
	
	agent.agent_gameParticipant = true;
	agent.killStreakType = juggType;
	
	agent thread [[ agent maps\mp\agents\_agent_utility::agentFunc( "spawn" ) ]]( spawnOrigin, spawnAngles, owner );
	
	agent maps\mp\bots\_bots_util::bot_set_personality( "default" );
	agent BotSetDifficulty( "veteran" );
	
	agent maps\mp\bots\_bots_strategy::bot_protect_point( pos, 128 );

	self.juggernaut = agent;
}

showFX() // self == odin
{
	self endon( "death" );
	wait( 1.0 );
	PlayFXOnTag( level.odinSettings[ self.odinType ].targetingFXID, self.targeting_marker, "tag_fx" );
}

watchReload( dvar, time ) // self == odin
{
	self endon( "death" );
	level endon( "game_ended" );
	
	owner = self.owner;
	owner endon( "disconnect" );
	
	wait( time );
	owner SetClientOmnvar( dvar, 1 );
}

// this is copied from the doNineBang() function, it needed its own flavor
doMarkingFlash( pos ) // self == odin
{
	level endon( "game_ended" );
	
	attacker = self.owner;
	
	radius_max = 800; // straight from the gdt entry
	radius_min = 200; // straight from the gdt entry
	radius_max_sq = radius_max * radius_max;
	radius_min_sq = radius_min * radius_min;

	viewHeightStanding = 60;
	viewHeightCrouching = 40;
	viewHeightProne = 11;

	//playSoundAtPos( pos, "flashbang_explode_default" );

	// get players within the radius
	foreach( player in level.players )
	{
		if( !isReallyAlive( player ) || player.sessionstate != "playing" )
			continue;

		// first make sure they are within distance
		dist = DistanceSquared( pos, player.origin );
		if( dist > radius_max_sq )
			continue;

		stance = player GetStance();
		viewOrigin = player.origin;
		switch( stance )
		{
		case "stand":
			viewOrigin = ( viewOrigin[0], viewOrigin[1], viewOrigin[2] + viewHeightStanding );
			break;
		case "crouch":
			viewOrigin = ( viewOrigin[0], viewOrigin[1], viewOrigin[2] + viewHeightCrouching );
			break;
		case "prone":
			viewOrigin = ( viewOrigin[0], viewOrigin[1], viewOrigin[2] + viewHeightProne );
			break;
		}

		// now make sure they can be hit by it
		if( !BulletTracePassed( pos, viewOrigin, false, player ) )
			continue;

		if ( dist <= radius_min_sq )
			percent_distance = 1.0;
		else
			percent_distance = 1.0 - ( dist - radius_min_sq ) / ( radius_max_sq - radius_min_sq );

		forward = AnglesToForward( player GetPlayerAngles() );

		toBlast = pos - viewOrigin;
		toBlast = VectorNormalize( toBlast );

		percent_angle = 0.5 * ( 1.0 + VectorDot( forward, toBlast ) );

		extra_duration = 1; // first blast is 1 sec, each after is 2 sec
		player notify( "flashbang", pos, percent_distance, percent_angle, attacker, extra_duration );
	}

	ents = maps\mp\gametypes\_weapons::getEMPDamageEnts( pos, 512, false );

	foreach ( ent in ents )
	{
		if ( isDefined( ent.owner ) && !maps\mp\gametypes\_weapons::friendlyFireCheck( self.owner, ent.owner ) )
			continue;

		ent notify( "emp_damage", self.owner, 8.0 );
	}
}
