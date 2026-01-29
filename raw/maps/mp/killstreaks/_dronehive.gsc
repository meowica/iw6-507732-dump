#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;


//============================================
// 				constants
//============================================
CONST_DRONE_HIVE_DEBUG 	= false;
CONST_MISSILE_COUNT		= 3;


//============================================
// 					init
//============================================
init()
{		
	level.killstreakFuncs["drone_hive"] = ::tryUseDroneHive;
	
	level.droneMissileSpawnArray = GetEntArray( "remoteMissileSpawn", "targetname" );
	
	foreach( missileSpawn in level.droneMissileSpawnArray )
	{
		missileSpawn.targetEnt = GetEnt( missileSpawn.target, "targetname" );	
	}
}	


//============================================
// 				tryUseDroneHive
//============================================
tryUseDroneHive( lifeId )
{
	/#
	if( (!IsDefined(level.droneMissileSpawnArray) || !level.droneMissileSpawnArray.size) )
	{
		AssertMsg( "map needs remoteMissileSpawn entities" );
	}
	#/
		
	return useDroneHive( self, lifeId );
}


//============================================
// 				useDroneHive
//============================================
useDroneHive( player, lifeId )
{	
	result = player maps\mp\killstreaks\_killstreaks::initRideKillstreak();
	
	if( result != "success"  )
	{
		return false;
	}
	
	player setUsingRemote( "remotemissile" );
	level thread runDroneHive( player, lifeId);
	level thread monitorDisownKillstreaks( player );
	level thread monitorGameEnd( player );
	
	return true;
}


//============================================
// 				useDroneHive
//============================================
runDroneHive( player, lifeId )
{
	player endon( "killstreak_disowned" );
	level  endon( "game_ended" );
	
	player notifyOnPlayerCommand( "missileTargetSet", "+attack" );
	remoteMissileSpawn = getBestMissileSpawnPoint( player, level.droneMissileSpawnArray );
	
	for( i = 0; i < CONST_MISSILE_COUNT; i++ )
	{
		startPos 	= remoteMissileSpawn.origin;	
		targetPos 	= remoteMissileSpawn.targetEnt.origin;
		vector 		= VectorNormalize( startPos - targetPos );		
		startPos 	= ( vector * 14000 ) + targetPos;
	
		/#
		if( CONST_DRONE_HIVE_DEBUG )
		{
			level thread drawLine( startPos, targetPos, 15, (1,0,0) );
		}
		#/
		
		rocket = MagicBullet( "drone_hive_projectile_mp", startpos, targetPos, player );
		rocket SetCanDamage( true );
	
		rocket.team 		= player.team;
		rocket.lifeId 		= lifeId;
		rocket.type 		= "remote";
		rocket.owner 		= player;
		rocket.entityNumber = rocket GetEntityNumber();
		
		level.rockets[ rocket.entityNumber ] = rocket;
		level.remoteMissileInProgress = true;
		
		level thread monitorDeath( rocket );
		level thread monitorBoost( rocket );
		
		missileEyes( player, rocket, i );
		
		if( i == 0 )
		{
			player SetClientDvar( "ui_predator_missile", true );
		}
		
		result = rocket waittill_any_return( "death", "missileTargetSet" );
		
		if( i < (CONST_MISSILE_COUNT - 1) )
		{
			player freezeControlsWrapper( true );
			player SetClientDvar( "ui_predator_missile", false );
			player VisionSetMissilecamForPlayer( "black_bw", 0 );
			wait(0.35);
		}
		else
		{
			if( result != "death" )
			{
				rocket waittill( "death" );
			}
		}
	}
	
	level thread returnPlayer( player );
}


//============================================
// 			getNextMissileSpawnIndex
//============================================
getNextMissileSpawnIndex( oldIndex )
{
	index = oldIndex + 1;
	
	if( index == level.droneMissileSpawnArray.size )
	{
		index = 0;
	}
	
	return index;
}


//============================================
// 				monitorBoost
//============================================
monitorBoost( rocket )
{
	rocket endon( "death" );
	
	rocket.owner waittill( "missileTargetSet" );
	rocket notify( "missileTargetSet" );
}


//============================================
// 			getBestMissileSpawnPoint
//============================================
getBestMissileSpawnPoint( owner, remoteMissileSpawnPoints )
{
	validEnemies = [];
	
	foreach( player in level.players )
	{
		if( !isReallyAlive( player ) )
			continue;

		if( player.team == owner.team )
			continue;
		
		if( player.team == "spectator" )
			continue;
	
		validEnemies[validEnemies.size] = player;
	}

	if( !validEnemies.size )
	{
		return remoteMissileSpawnPoints[ RandomInt(remoteMissileSpawnPoints.size)];
	}
	
	bestMissleSpawn = remoteMissileSpawnPoints[0];
	
	// select a missile spawn that can see the most enemies
	foreach( missileSpawn in remoteMissileSpawnPoints )
	{
		missileSpawn.sightedEnemies = 0;
		
		foreach( enemy in validEnemies )
		{
			if( BulletTracePassed( enemy.origin + (0,0,32), missileSpawn.origin, false, enemy ) )
				missileSpawn.sightedEnemies += 1;
		}
		
		if( missileSpawn.sightedEnemies > bestMissleSpawn.sightedEnemies )
		{
			bestMissleSpawn = missileSpawn;
		}
	}
	
	return bestMissleSpawn;
}


//============================================
// 				missileEyes
//============================================
missileEyes( player, rocket, i )
{
	player ControlsUnlink();
	delayTime = 1.0;
	
	waitframe();
	
	player ThermalVisionFOFOverlayOn();	
	player CameraLinkTo( rocket, "tag_origin" );
	player ControlsLinkTo( rocket );
	player VisionSetMissilecamForPlayer( "default", delayTime );
	level thread unfreezeControls( player, delayTime, i );
}


//============================================
// 			unfreezeControls
//============================================
unfreezeControls( player, delayTime, i )
{
	wait( delayTime - 0.35 );
	player freezeControlsWrapper( false );
	
	if( i != 0 )
	{
		player SetClientDvar( "ui_predator_missile", true );
	}
}


//============================================
// 			monitorDisownKillstreaks
//============================================
monitorDisownKillstreaks( player )
{
	player endon( "end_kill_streak" );
	
	player waittill( "killstreak_disowned" );
	
	level thread returnPlayer( player );
}


//============================================
// 			monitorGameEnd
//============================================
monitorGameEnd( player )
{
	player endon( "end_kill_streak" );
	
	level waittill( "game_ended" );
	
	level thread returnPlayer( player );
}


//============================================
// 				monitorDeath
//============================================
monitorDeath( killStreakEnt )
{
	killStreakEnt waittill( "death" );
	
	level.rockets[ killStreakEnt.entityNumber ] = undefined;
	level.remoteMissileInProgress = undefined;
}


//============================================
// 				returnPlayer
//============================================
returnPlayer( player )
{
	if( !IsDefined(player) )
		return;
	
	player notify( "end_kill_streak" );
		
	player ThermalVisionFOFOverlayOff();
	player CameraUnlink();
	player ControlsUnlink();
	player clearUsingRemote();
	player SetClientDvar( "ui_predator_missile", false );
}