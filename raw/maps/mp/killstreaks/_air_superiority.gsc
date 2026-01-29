#include maps\mp\_utility;
#include common_scripts\utility;

// replacement for EMP
// only affects aircraft
// remarkably similar to aastrike, should probably get rid of that...
KS_NAME = "air_superiority";

init()
{
	precacheItem( "aamissile_projectile_mp" );
	
	config = SpawnStruct();
	config.modelNames = [];
	config.modelNames[ "allies" ] = "vehicle_av8b_harrier_jet_mp";
	config.modelNames[ "axis" ] = "vehicle_av8b_harrier_jet_opfor_mp";
	config.inboundSfx = "veh_mig29_dist_loop";
	//config.inboundSfx = "veh_aastrike_flyover_loop";
	//config.outboundSfx = "veh_aastrike_flyover_outgoing_loop";
	config.compassIconFriendly = "compass_objpoint_airstrike_friendly";
	config.compassIconEnemy = "compass_objpoint_airstrike_busy";
	// sonic boom?
	config.speed = 6000;
	config.halfDistance = 20000;
	config.distFromPlayer = 4000;
	config.heightRange = 500;
	//config.attackTime = 2.0;
	config.numMissileVolleys = 3;
	config.outboundFlightAnim = "airstrike_mp";
	config.onAttackDelegate = ::attackEnemyAircraft;
	config.onFlybyCompleteDelegate = ::cleanupFlyby;
	
	level.planeConfigs[ KS_NAME ] = config;
	
	level.killstreakFuncs[KS_NAME] = ::onUse;
	
	level.teamAirDenied["axis"] = false;
	level.teamAirDenied["allies"] = false;
}

onUse( lifeId )
{
	assert( isDefined( self ) );
	
	// check for active air_superiority strikes
	otherTeam = getOtherTeam( self.team );
	if ( (level.teamBased && level.teamAirDenied[ otherTeam] )
		|| (!level.teamBased && IsDefined( level.airDeniedPlayer ) && level.airDeniedPlayer == self )
		)
	{
		self IPrintLnBold( &"KILLSTREAKS_AIR_SPACE_TOO_CROWDED" );
		return false;
	}
	else
	{
		// scramble the fighters
		self thread doStrike( lifeId, KS_NAME );
	
		//self maps\mp\_matchdata::logKillstreakEvent( "aastrike", self.origin );
		//self thread teamPlayerCardSplash( "used_aastrike", self, self.team );
	
		return true;	
	}
	    
}

doStrike( lifeId, streakName )
{
	config = level.planeConfigs[ streakName ];
	
	planeFlyHeight = maps\mp\killstreaks\_plane::getPlaneFlyHeight();
	// planeBombExplodeDistance = maps\mp\killstreaks\_plane::getExplodeDistance( planeFlyHeight );
	
	// have the plane pass in front of the player, across the current view
	forwardVec = AnglesToForward( self.angles );
	rightVec = AnglesToRight( self.angles );
	leftVec = -1 * rightVec;
	
	targetPos = self.origin + config.distFromPlayer * forwardVec;
	
	// play inbound vo
	
	wait( 1 );
	
	level.teamAirDenied[getOtherTeam(self.team)] = true;
	level.airDeniedPlayer = self;
	
	doOneFlyby( streakName, lifeId, targetPos, leftVec, planeFlyHeight );
	
	self waittill( "aa_flyby_complete" );
	
	// coming back around vo
	wait( 2 );
	maps\mp\gametypes\_hostmigration::waitTillHostMigrationDone();
	
	doOneFlyby( streakName, lifeId, targetPos, rightVec, planeFlyHeight );
	
	self waittill( "aa_flyby_complete" );
	
	level.teamAirDenied[getOtherTeam(self.team)] = false;
	level.airDeniedPlayer = undefined;
	
	// play outbound vo
	// should check if there are still enemy aircraft in the air and play appropriate vo
}

doOneFlyby( streakName, lifeId, targetPos, dir, flyHeight )
{
	config = level.planeConfigs[ streakName ];
	
	// absolute height should be derived from the heightEnt
	flightPath = maps\mp\killstreaks\_plane::getFlightPath( targetPos, dir, config.halfDistance, true, flyHeight, config.speed, -0.5 * config.halfDistance, streakName );
	
	// may want to break this up into spawn, move, cleanup components
	// so that we can reuse the plane
	level thread maps\mp\killstreaks\_plane::doFlyby( lifeId, self, lifeId, 
													 flightPath["startPoint"] + (0, 0, randomInt(config.heightRange) ), 
													 flightPath["endPoint"] + (0, 0, randomInt(config.heightRange) ), 
													 flightPath["attackTime"],
													 flightPath["flyTime"],
													 dir, 
													 streakName );
}


attackEnemyAircraft( pathEnd, flyTime, beginAttackTime, owner, streakName )	// self == plane
{
	wait (beginAttackTime);
	
	targets = self.owner findTargets();
	config = level.planeConfigs[ streakName ];
	numVolleys = config.numMissileVolleys;
	targetIndex = targets.size - 1;
	
	while (targetIndex >= 0
		   && numVolleys > 0
		  )
	{
		target = targets[ targetIndex ];
		if ( IsDefined( target ) && IsAlive( target ) )
		{
			self fireAtTarget( target );
			numVolleys--;
			wait ( 1 );
		}
		targetIndex--;
	}
}

cleanupFlyby( owner, plane, streakName )
{
	owner notify( "aa_flyby_complete" );
}

// unlike the aa strike, we only search for targets once
// because we block new air strikes from behing launched
// also: probably could flip the order that targets are acquired if we want
// the jets to go after low-cost killstreaks first
findTargets()	// self == player
{
	self endon ( "disconnect" );
	self endon ( "owner_gone" );
	self endon ( "game_ended" );
	
	targets = [];
	
	// need to handle the multi-team, FFA cases
	if ( level.multiTeamBased )
	{
		
	}
	else if ( level.teamBased )
	{
		otherTeam = getOtherTeam( self.team );
	 	
		if ( IsDefined( level.activeUAVs[otherTeam] ) )
		{
			foreach ( uav in level.uavmodels[otherTeam] )
			{
				targets[ targets.size ] = uav;
			}	
		}
	}
	else
	{
		
	}
	
	checkFunc = undefined;
	if ( level.teamBased )
	{
		checkFunc = ::isValidTeamTarget;
	}
	else
	{
		checkFunc = ::isValidFFATarget;
	}
	
	if ( IsDefined( level.remote_uav ) )
	{
		foreach ( remote in level.remote_uav )
		{
			if ( [[ checkFunc ]]( self, remote ) )
			{
				targets[ targets.size ] = remote;
			}
		}
	}
	
	if ( IsDefined( level.littleBirds ) && level.littleBirds.size )
 	{
 		foreach ( lb in level.littleBirds )
 		{
 			if ( [[ checkFunc ]]( self, lb ) )
 			{
 				targets[ targets.size ] = lb;
 			}
 		}		
 	}
	
	if ( IsDefined(level.helis) && level.helis.size )
 	{
 		foreach ( heli in level.helis )
 		{
 			if ( [[ checkFunc ]]( self, heli ) )
 			{
 				targets[ targets.size ] = heli;
 			}
 		}
 	}
	
	// planes must exist if we're here
	foreach ( plane in level.planes )
	{
		if ( [[ checkFunc ]]( self, plane ) )
		{
			targets[ targets.size ] = plane;
		}
	}
	
	if( level.ac130InUse 
	   && [[ checkFunc ]]( self, level.ac130.owner ) 
	  )
 	{
		targets[ targets.size ] = level.ac130.planemodel;
	}
	
	return targets;
}

fireAtTarget( curTarget )	// self == plane
{
	if ( !isDefined(curTarget) )
		return;
	
	// aamissile_projectile_mp
	// sam_projectile_mp
	offsetVec = AnglesToRight( self.angles );
	rocket1 = MagicBullet( "aamissile_projectile_mp", self.origin + 100 * offsetVec, curTarget.origin, self.owner );
	rocket1 Missile_SetTargetEnt( curTarget );
	rocket1 Missile_SetFlightmodeDirect();
	
	rocket2 = MagicBullet( "aamissile_projectile_mp", self.origin - 100 * offsetVec, curTarget.origin, self.owner );
	rocket2 Missile_SetTargetEnt( curTarget );
	// mix up the flight modes to get better coverag?
	//rocket2 Missile_SetFlightmodeDirect();
	rocket2 Missile_SetFlightmodeTop();
}

destroyActiveVehicles( attacker, targetTeam )
{
	// thread all of the things that need to get destroyed, this way we can put frame waits in between each destruction so we don't hit the server with a lot at one time
	thread destroyTargets( attacker, targetTeam, level.helis );
	thread destroyTargets( attacker, targetTeam, level.littleBirds );
	thread destroyActiveUAVs( attacker, targetTeam );
	thread destroyActiveAC130( attacker, targetTeam );
	thread destroyTargets( attacker, targetTeam, level.remote_uav );
}

destroyTargets( attacker, targetTeam, targetList )
{
	meansOfDeath = "MOD_EXPLOSIVE";
	weapon = "killstreak_emp_mp";

	damage = 5000;
	direction_vec = ( 0, 0, 0 );
	point = ( 0, 0, 0 );
	modelName = "";
	tagName = "";
	partName = "";
	iDFlags = undefined;

	foreach ( target in targetList )
	{
		if ( level.teamBased && IsDefined( targetTeam ) )
		{
			if( IsDefined( target.team ) && target.team != targetTeam )
				continue;
		}
		else
		{
			if( IsDefined( target.owner ) && target.owner == attacker )
				continue;
		}

		target notify( "damage", damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon );
		wait( 0.05 );
	}
}

destroyActiveUAVs( attacker, targetTeam )
{
	uavArray = level.uavModels;
	if ( level.teamBased && IsDefined( targetTeam ) )
		uavArray = level.uavModels[ targetTeam ];
	
	destroyTargets( attacker, targetTeam, uavArray );
}

destroyActiveAC130( attacker, targetTeam )
{
	meansOfDeath = "MOD_EXPLOSIVE";
	weapon = "killstreak_emp_mp";

	damage = 5000;
	direction_vec = ( 0, 0, 0 );
	point = ( 0, 0, 0 );
	modelName = "";
	tagName = "";
	partName = "";
	iDFlags = undefined;

	if ( level.teamBased && IsDefined( targetTeam ) )
	{
		if ( IsDefined( level.ac130player ) && IsDefined( level.ac130player.team ) && level.ac130player.team == targetTeam )
			level.ac130.planeModel notify( "damage", damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon );
	}
	else
	{
		if ( IsDefined( level.ac130player ) )
		{
			if( !IsDefined( level.ac130.owner ) || ( IsDefined( level.ac130.owner ) && level.ac130.owner != attacker ) )
				level.ac130.planeModel notify( "damage", damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon );
		}
	}
}
