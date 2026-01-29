#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;

// _plane.gsc
// a modular component intended to control a plane flying overhead
// adapted from _airstrike.gsc

init()
{
	if ( !IsDefined( level.planes ) )
	{
		level.planes = [];
	}
	
	if ( !IsDefined( level.planeConfigs ) )
	{
		level.planeConfigs = [];
	}
	
	level.fighter_deathfx = loadfx ("fx/explosions/aerial_explosion_harrier");
	level.fx_airstrike_afterburner = loadfx ("fx/fire/jet_afterburner");
	level.fx_airstrike_contrail = loadfx ("fx/smoke/jet_contrail");
	
	/*
	 * streakName
	 * modelNames[]	// alllied, axis
	 * halfDistance
	 * speed
	 * initialHeight
	 * flightSound
	 * flyTime
	 * attackTime
	 * inboundFlightAnim?
	 * outboundFlightAnim = "airstrike_mp"
	 * onAttackDelegate
	 * killcam stuff?
	 * planeFX?
	 */
}

getFlightPath( coord, directionVector, planeHalfDistance, absoluteHeight, planeFlyHeight, planeFlySpeed, attackDistance, streakName )
{
	// stealth_airstrike moves this a lot more
	startPoint = coord + ( directionVector * ( -1 * planeHalfDistance ) );
	endPoint = coord + ( directionVector * planeHalfDistance );
	
	if ( absoluteHeight ) // used in the new height system
	{
		startPoint *= (1, 1, 0);
		endPoint *= (1, 1, 0);
	}
	
	startPoint += ( 0, 0, planeFlyHeight );
	endPoint += ( 0, 0, planeFlyHeight );
		
	// Make the plane fly by
	d = length( startPoint - endPoint );
	flyTime = ( d / planeFlySpeed );
	
	// bomb explodes planeBombExplodeDistance after the plane passes the center
	d = abs( 0.5 * d + attackDistance  );
	attackTime = ( d / planeFlySpeed );
	
	assert( flyTime > attackTime );

	flightPath["startPoint"] = startPoint;
	flightPath["endPoint"] = endPoint;
	flightPath["attackTime"] = attackTime;
	flightPath["flyTime"] = flyTime;
	
	return flightPath;
}

//doPlaneStrike( lifeId, owner, requiredDeathCount, bombsite, startPoint, endPoint, bombTime, flyTime, direction, streakName )
doFlyby( lifeId, owner, requiredDeathCount, startPoint, endPoint, attackTime, flyTime, directionVector, streakName )
{
	plane = planeSpawn( lifeId, owner, startPoint, directionVector, streakName );
	
	plane endon( "death" );
	
	// plane spawning randomness = up to 125 units, biased towards 0
	// radius of bomb damage is 512
	endPathRandomness = 150;
	pathEnd  = endPoint + ( (RandomFloat(2) - 1) * endPathRandomness, (RandomFloat(2) - 1) * endPathRandomness, 0 );
	
	plane planeMove( pathEnd, flyTime, attackTime, streakName );
	
	plane planecleanup();
}

planeSpawn( lifeId, owner, startPoint, directionVector, streakName )
{
	if ( !isDefined( owner ) ) 
		return;
	
	startPathRandomness = 100;
	pathStart = startPoint + ( (RandomFloat(2) - 1) * startPathRandomness,	(RandomFloat(2) - 1) * startPathRandomness, 0 );
	
	//self thread DrawLine(pathStart, (AnglesToForward( direction ) * 200000), 120, (1,0,1) );
	
	configData = level.planeConfigs[ streakName ];
	
	plane = undefined;
	
	if ( IsDefined( configData.compassIconFriendly ) )
	{
		plane = SpawnPlane( owner, "script_model", pathStart, configData.compassIconFriendly, configData.compassIconEnemy );
	}
	else
	{
		plane = Spawn( "script_model", pathStart );
		plane.origin = pathStart;
	}
	plane.owner = owner;
	
	plane SetModel( configData.modelNames[ owner.team ] );
	plane.angles = VectorToAngles( directionVector );
	plane.lifeId = lifeId;
	
	plane thread handleDeath();
	plane thread handleEMP( owner );
	
	startTrackingPlane( plane );
	
	// stealth bomber doesn't have effects
	plane thread playPlaneFx();
	plane PlayLoopSound( configData.inboundSfx );
	
	return plane;
}

planeMove( destination, flyTime, attackTime, streakName )	// self == plane
{
	configData = level.planeConfigs[ streakName ];
	
	// begin flight
	self MoveTo( destination, flyTime, 0, 0 ); 
	
	// begin attack
	//thread callStrike_planeSound( plane, bombsite );
	// hmm, don't like the timing of these flybys
	if ( IsDefined( configData.onAttackDelegate ) )
	{
		self thread [[ configData.onAttackDelegate ]]( destination, flyTime, attackTime, self.owner, streakName );
	}
	
	// fly away
	wait( attackTime - .75 );
	
	if ( IsDefined( configData.outboundSfx ) )
	{
		self StopLoopSound();
		self PlayLoopSound( configData.outboundSfx );
	}
	
	if ( IsDefined( configData.outboundFlightAnim ) )
	{
		// self ScriptModelPlayAnimDeltaMotion( configData.outboundFlightAnim );
	}
	
	wait (flyTime - attackTime);
	
	if ( IsDefined( configData.onFlybyCompleteDelegate ) )
	{
		thread [[ configData.onFlybyCompleteDelegate ]]( self.owner, self, streakName );
	}
}

planeCleanup()	// self == plane
{
	stopTrackingPlane( self );
	
	self notify( "delete" );
	self delete();
}

handleEMP( owner ) // self == plane
{
	self endon ( "death" );

	while ( true )
	{
		if ( owner isEMPed() )
		{
			self notify( "death" );
			return;
		}
		
		level waittill ( "emp_update" );
	}
}

handleDeath() // self == plane
{
	level endon( "game_ended" );
	self endon( "delete" );

	self waittill( "death" );
	
	forward = AnglesToForward( self.angles ) * 200;
	// vfx in plane config?
	PlayFX( level.fighter_deathfx, self.origin, forward );
	stopTrackingPlane( self );
	
	self delete();
}

playPlaneFX()
{
	self endon ( "death" );

	wait( 0.5);
	PlayFXOnTag( level.fx_airstrike_afterburner, self, "tag_engine_right" );
	wait( 0.5);
	PlayFXOnTag( level.fx_airstrike_afterburner, self, "tag_engine_left" );
	wait( 0.5);
	PlayFXOnTag( level.fx_airstrike_contrail, self, "tag_right_wingtip" );
	wait( 0.5);
	PlayFXOnTag( level.fx_airstrike_contrail, self, "tag_left_wingtip" );
}

getPlaneFlyHeight()
{
	heightEnt = GetEnt( "airstrikeheight", "targetname" );
	if ( IsDefined( heightEnt ) )
	{
		return heightEnt.origin[2];
	}
	else
	{
		println( "NO DEFINED AIRSTRIKE HEIGHT SCRIPT_ORIGIN IN LEVEL" );
		planeFlyHeight = 950;
		if ( isdefined( level.airstrikeHeightScale ) )
			planeFlyHeight *= level.airstrikeHeightScale;
		
		return planeFlyHeight;
	}
}

getExplodeDistance( height )
{
	standardHeight = 850;
	standardDistance = 1500;
	distanceFrac = standardHeight/height;
	
	newDistance = distanceFrac * standardDistance;
	
	return newDistance;
}

startTrackingPlane( obj )
{
	entNum = obj GetEntityNumber();
	level.planes[ entNum ] = obj;
}

stopTrackingPlane( obj )
{
	entNum = obj GetEntityNumber();
	level.planes[ entNum ] = undefined;
}

selectAirstrikeLocation( lifeId, streakname, doStrikeFn )
{
	targetSize = level.mapSize / 6.46875; // 138 in 720
	if ( level.splitscreen )
		targetSize *= 1.5;
	
	config = level.planeConfigs[ streakname ];
	if ( IsDefined( config.selectLocationVO ) )
	{
		self PlayLocalSound( game[ "voice" ][ self.team ] + config.selectLocationVO );
	}
	
	self _beginLocationSelection( streakname, "map_artillery_selector", config.chooseDirection, targetSize );

	self endon( "stop_location_selection" );
	
	// wait for the selection. randomize the yaw if we're not doing a precision airstrike.
	self waittill( "confirm_location", location, directionYaw );
	
	if ( !config.chooseDirection )
	{
		directionYaw = randomint(360);
	}

	self setblurforplayer( 0, 0.3 );
	
	if ( IsDefined( config.inboundVO ) )
	{
		self PlayLocalSound( game[ "voice" ][ self.team ] + config.inboundVO );
	}
	
	self maps\mp\_matchdata::logKillstreakEvent( streakName, location );

	self thread [[ doStrikeFn ]]( lifeId, location, directionYaw, streakName );
	
	return true;
}