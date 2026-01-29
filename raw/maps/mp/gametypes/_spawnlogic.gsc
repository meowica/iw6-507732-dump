#include common_scripts\utility;
#include maps\mp\_utility;


//============================================
// 		 		init
//============================================
init()
{
	level.killstreakSpawnShield = 5000;
	level.forceBuddySpawn = false;
	level.spawnMins = (0,0,0);
	level.spawnMaxs = (0,0,0);
	level.clientTraceSpawnClass = getClientTraceSpawnClass();
	level.disableClientSpawnTraces = false;
	
	/#
	level.debugSpawning = false;
	#/

	level.players 			= [];
	level.participants		= [];
	level.spawnPointArray 	= [];
	level.grenades 			= [];
	level.missiles			= [];
	level.carePackages		= [];
	level.helis 			= [];
	level.turrets 			= [];
	level.tanks 			= [];
	level.scramblers 		= [];
	level.ims 				= [];
	level.ugvs 				= [];
	level.ballDrones 		= [];
	
	level thread onPlayerConnect();
	level thread spawnPointUpdate();
	level thread trackGrenades();
	level thread trackMissiles();
	level thread trackCarePackages();
	level thread trackHostMigrationEnd();

	for( i = 0; i < level.teamNameList.size; i++ )
	{
		level.teamSpawnPoints[level.teamNameList[i]] = [];
	}
}


//============================================
// 		 	trackHostMigrationEnd
//============================================
trackHostMigrationEnd()
{
	while( true )
	{
		self waittill( "host_migration_end" );
		
		foreach( player in level.participants )
		{
			player.canPerformClientTraces = canPerformClientTraces( player );
		}
	}
}


//============================================
// 		 		onPlayerConnect
//============================================
onPlayerConnect()
{
	while( true )
	{
		level waittill( "connected", player );

		level thread startClinetSpawnPointTraces( player );
		level thread eyesOnSightChecks( player );
	}
}


//============================================
// 		 		eyesOnSightChecks
//============================================
eyesOnSightChecks( player )
{
	player endon( "disconnect" );
	
	while( true )
	{
		if( (player.sessionstate == "playing") && isReallyAlive(player) && !(player _hasPerk("specialty_coldblooded")) )
		{
			sighted = false;
			sightingPlayers = player GetPlayersSightingMe();
			
			foreach( otherPlayer in sightingPlayers )
			{
				// ignore teammates 
				if( level.teamBased && (otherPlayer.team == player.team) )
				{
					continue;
				}
				
				if( (player.sessionstate != "playing") || !isReallyAlive(player) )
				{
					continue;
				}
				
				sighted = true;
				break;
			}
			player MarkForEyesOn( sighted );			
		}
		else
		{
			player MarkForEyesOn( false );
		}
		
		wait(0.05);
	}
}


//============================================
// 		 startClinetSpawnPointTraces
//============================================
startClinetSpawnPointTraces( player )
{
	player.canPerformClientTraces = canPerformClientTraces( player );
	
	if( !player.canPerformClientTraces )
	{
		return;
	}
	
	wait(0.05);
	
	player SetClientSpawnSightTraces( level.clientTraceSpawnClass );
}


//============================================
// 		 	canPerformClientTraces
//============================================
canPerformClientTraces( player )
{
	if( level.disableClientSpawnTraces )
	{
		return false;
	}
	
	if( !IsDefined(level.clientTraceSpawnClass) )
	{
		return false;
	}
		
	if( IsDefined(level.dynamicSpawns) )
	{
		return false;
	}
	
	// AI is server side
	if( IsAI(player) )
	{
		return false;
	}
	
	// the host is server side
	if( player IsHost() )
	{
		return false;
	}
	
	return true;
}


//============================================
// 		 	getClientTraceSpawnClass
//============================================
getClientTraceSpawnClass()
{
	spawnClass = undefined;
	
	switch( level.gameType )
	{
		case "dom":
			spawnClass = "mp_dom_spawn";
			break;
		case "war":
		case "conf":
			spawnClass = "mp_tdm_spawn";
			break;
		case "dm":
			spawnClass = "mp_dm_spawn";
			break;
	}
	
	return spawnClass;
}


//============================================
// 		 	addStartSpawnPoints
//============================================
addStartSpawnPoints( spawnPointName )
{
	spawnPoints = getSpawnpointArray( spawnPointName );
		
	if( !spawnPoints.size )
	{
		assertmsg( "^1Error: No " + spawnPointName + " spawnpoints found in level!" );
		return;
	}
	
	if( !isDefined(level.startSpawnPoints) )
	{
		level.startSpawnPoints = [];
	}

	for( index = 0; index < spawnPoints.size; index++ )
	{
		spawnPoints[index] spawnPointInit();
		level.startSpawnPoints[ level.startSpawnPoints.size ] = spawnPoints[index];
	}
}


//============================================
// 		 		addSpawnPoints
//============================================
addSpawnPoints( team, spawnPointName, isSetOptional )
{
	if( !isDefined(level.spawnpoints) )
	{
		level.spawnpoints = [];
	}
	
	if( !isDefined(level.teamSpawnPoints[team]) )
	{
		level.teamSpawnPoints[team] = [];
	}
		
	if( !isDefined( isSetOptional ) )
	{
		isSetOptional = false;
	}
	
	// grab the new spawn points
	newSpawnPoints = [];
	newSpawnPoints = getSpawnpointArray( spawnPointName );
	
	if( !newSpawnPoints.size && !isSetOptional )
	{
		assertmsg( "^1Error: No " + spawnPointName + " spawnpoints found in level!" );
		return;
	}
	
	// initialize and save the new spawns
	foreach( spawnPoint in newSpawnPoints )
	{
		if( !isdefined( spawnpoint.inited ) )
		{
			spawnpoint spawnPointInit();
			level.spawnpoints[ level.spawnpoints.size ] = spawnpoint;
		
			/#
			bbprint( "spawns", "name %s x %f y %f z %f", "initialized", spawnpoint.origin[0], spawnpoint.origin[1], spawnpoint.origin[2] );
			#/
		}
		
		// different teams can share the same spawn point 
		level.teamSpawnPoints[team][ level.teamSpawnPoints[team].size ] = spawnPoint;
	}
}


//============================================
// 		 		spawnPointInit
//============================================
spawnPointInit()
{
	spawnpoint = self;
	
	level.spawnMins = expandMins( level.spawnMins, spawnpoint.origin );
	level.spawnMaxs = expandMaxs( level.spawnMaxs, spawnpoint.origin );
	
	spawnpoint.forward 			= anglesToForward( spawnpoint.angles );
	spawnpoint.sightTracePoint 	= spawnpoint.origin + (0,0,50);
	spawnpoint.lastspawntime 	= gettime();
	spawnpoint.outside 			= true;
	spawnpoint.inited 			= true;
	spawnpoint.alternates 		= [];
	
	skyHeight = 1024;

	if( !bullettracepassed( spawnpoint.sightTracePoint, spawnpoint.sightTracePoint + (0,0,skyHeight), false, undefined ) )
	{
		startpoint = spawnpoint.sightTracePoint + spawnpoint.forward * 100;
		if( !bullettracepassed( startpoint, startpoint + (0,0,skyHeight), false, undefined ) )
		{
			spawnpoint.outside = false;
		}
	}
	
	right = anglesToRight( spawnpoint.angles );
	
	AddAlternateSpawnpoint( spawnpoint, spawnpoint.origin + right * 45 );
	AddAlternateSpawnpoint( spawnpoint, spawnpoint.origin - right * 45 );
	
	initSpawnPointValues( spawnpoint );
}


//============================================
// 		 	AddAlternateSpawnpoint
//============================================
AddAlternateSpawnpoint( spawnpoint, alternatepos )
{
	spawnpointposRaised = playerPhysicsTrace( spawnpoint.origin, spawnpoint.origin + (0,0,18), false, undefined );
	zdiff = spawnpointposRaised[2] - spawnpoint.origin[2];
	
	alternateposRaised = (alternatepos[0], alternatepos[1], alternatepos[2] + zdiff );
	
	traceResult = playerPhysicsTrace( spawnpointposRaised, alternateposRaised, false, undefined );
	if ( traceResult != alternateposRaised )
		return;
	
	finalAlternatePos = playerPhysicsTrace( alternateposRaised, alternatepos );
	
	spawnpoint.alternates[ spawnpoint.alternates.size ] = finalAlternatePos;
}


//============================================
// 		 	getSpawnpointArray
//============================================
getSpawnpointArray( classname )
{
	if( !IsDefined(level.spawnPointArray) )
	{
		level.spawnPointArray = [];
	}
	
	if( !IsDefined(level.spawnPointArray[classname]) )
	{
		level.spawnPointArray[classname] = [];
		level.spawnPointArray[classname] = getSpawnArray( classname );
		
		foreach( spawnPoint in level.spawnPointArray[classname] )
		{
			spawnPoint.classname = classname;
		}
	}
	
	return level.spawnPointArray[classname];
}


//============================================
// 		 	getSpawnpoint_Random
//============================================
getSpawnpoint_Random( spawnPoints )
{
	if( !IsDefined( spawnPoints ) )
	{
		return undefined;
	}

	randomSpawnPoint 	= undefined;
	spawnPoints 		= maps\mp\gametypes\_spawnscoring::checkDynamicSpawns( spawnPoints );
 	spawnPoints 		= array_randomize( spawnPoints );
	
	// select the first valid spawn point
	foreach( spawnPoint in spawnPoints )
	{
		randomSpawnPoint = spawnPoint;
		
		if( CanSpawn( randomSpawnPoint.origin ) && !PositionWouldTelefrag( randomSpawnPoint.origin ) )
		{
			break;
		}
	}
	
	return randomSpawnPoint;
}


//============================================
// 		 	getSpawnpoint_NearTeam
//============================================
getSpawnpoint_NearTeam( spawnpoints, favoredspawnpoints )
{
	assertMsg( "game mode not supported by the new spawning system" );
	
	while( true )
	{
		wait( 5 );
	}
}


//============================================
// 		 		trackGrenades
//============================================
trackGrenades()
{
	while( true )
	{
		level.grenades = getentarray("grenade", "classname");
		wait(0.05);
	}
}


//============================================
// 		 		trackMissiles
//============================================
trackMissiles()
{
	while( true )
	{
		level.missiles = getentarray( "rocket", "classname" );
		wait(0.05);
	}
}


//============================================
// 		 	trackCarePackages
//============================================
trackCarePackages()
{
	while( true )
	{
		level.carePackages = getEntArray( "care_package", "targetname" );
		wait(0.05);
	}
}


//===========================================
// 			getTeamSpawnPoints
//===========================================
getTeamSpawnPoints( team )
{
	return level.teamSpawnPoints[team];
}


//===========================================
// 			isPathDataAvailable
//===========================================
isPathDataAvailable()
{
	if( !IsDefined( level.pathDataAvailable ) )
	{
		nodes = GetAllNodes();
		level.pathDataAvailable = ( IsDefined(nodes) && ( nodes.size > 150 ) );
	}
	
	return level.pathDataAvailable;
}


//============================================
// 			addToParticipantsArray
//============================================
addToParticipantsArray()
{
	assert( IsGameParticipant(self) );
	level.participants[level.participants.size] = self;
}


//============================================
// 			removeFromParticipantsArray
//============================================
removeFromParticipantsArray()
{
	found = false;
	for ( entry = 0; entry < level.participants.size; entry++ )
	{
		if ( level.participants[entry] == self )
		{
			found = true;
			while ( entry < level.participants.size-1 )
			{
				level.participants[entry] = level.participants[entry + 1];
				assert( level.participants[entry] != self );
				entry++;
			}
			level.participants[entry] = undefined;
			break;
		}
	}
	assert( found );
}


//============================================
// 			spawnPointUpdate
//============================================
spawnPointUpdate()
{
	while( !isDefined(level.spawnPoints) || (level.spawnPoints.size == 0) )
	{
		wait(0.05);
	}
	
	setDevDvarIfUninitialized( "scr_disableClientSpawnTraces", "0" );
	
	/#
	setDevDvarIfUninitialized( "scr_spawnpointdebug", "0" );
	setDevDvarIfUninitialized( "scr_forceBuddySpawn", "0" );
	#/
		
	level thread spawnPointSightUpdate();
	level thread spawnPointDistanceUpdate();
	
	
	while( true )
	{
		/#
		level.debugSpawning 	= ( getdvarint("scr_spawnpointdebug") > 0 );
		level.forceBuddySpawn 	= ( getdvarint("scr_forceBuddySpawn") > 0 );
		#/
		
		level.disableClientSpawnTraces = ( getdvarint("scr_disableClientSpawnTraces") > 0 );
		
		wait(0.05);
	}
	
}

//============================================
// 			spawnPointSightUpdate
//============================================
spawnPointSightUpdate()
{
	maxTracePerFrame 	= 18;
	traceCount 			= 0;
	loopCount			= 0;
	
	while( true )
	{	
		// all spawns have been updated this frame
		if( loopCount == 1 )
		{
			traceCount 	= 0;
			loopCount	= 0;
			wait(0.05);
		}
		
		loopCount++;
		spawnPoints = level.spawnPoints;
		spawnPoints = maps\mp\gametypes\_spawnscoring::checkDynamicSpawns( spawnPoints );
	
		foreach( spawnPoint in spawnPoints )
		{
			clearSpawnPointSightData( spawnpoint );
			
			foreach( player in level.participants )
			{
				if( player.sessionstate != "playing" )
				{
					continue;
				}
				
				if( !isReallyAlive(player) )
				{
					continue;
				}
				
				team = getSpawnTeam( player );
				
				if( spawnpoint.sights[team] )
				{
					continue;
				}
				
				if( player.canPerformClientTraces )
				{
					sightValue = player ClientSpawnSightTracePassed( spawnpoint.index );
				}
				else
				{
					playerHeight = getPlayerTraceHeight( player );
					sightValue = SpawnSightTrace( spawnpoint, spawnpoint.origin + (0,0,playerHeight), player.origin + (0,0,playerHeight) );
					traceCount++;
				}
				
				if( sightValue > 0 )
				{
					spawnpoint.sights[team]++;
				}
			}
			
			// perform additional sight checks on kill streak entities
			additionalSightTraceEntities( spawnpoint, level.turrets );
			additionalSightTraceEntities( spawnpoint, level.ugvs );
			
			if( shouldSightTraceWait(maxTracePerFrame, traceCount)  )
			{
				traceCount 	= 0;
				loopCount	= 0;
				wait(0.05);
			}
		}
	}
}


//============================================
// 			shouldSightTraceWait
//============================================
shouldSightTraceWait( maxCount, currentCount )
{
	potentialTraceCost = 0;
		
	foreach( player in level.participants )
	{
		if( !player.canPerformClientTraces )
		{
			potentialTraceCost++;
		}
	}
		
	if( (currentCount + potentialTraceCost) > maxCount )
	{
		return true;
	}
	
	return false;
}


//============================================
// 			spawnPointDistanceUpdate
//============================================
spawnPointDistanceUpdate()
{
	waitInterval = 4;
	
	while( true )
	{	
		spawnPoints = level.spawnPoints;
		spawnPoints = maps\mp\gametypes\_spawnscoring::checkDynamicSpawns( spawnPoints );
		currentTime = getTime();
		
		foreach( i, spawnPoint in spawnPoints )
		{
			clearSpawnPointDistanceData( spawnPoint );
			
			foreach( player in level.participants )
			{
				if( player.sessionstate != "playing" )
				{
					continue;
				}
				
				if( !isReallyAlive(player) )
				{
					continue;
				}
						
				team = getSpawnTeam( player );
				
				// calculate distance between the player and the spawn point
				distSquared = DistanceSquared( player.origin, spawnpoint.origin );
				
				// save the closest player distance away from the spawn point
				if( distSquared < spawnpoint.minDistSquared[team] )
				{
					spawnpoint.minDistSquared[team] = distSquared;
				}
				
				weight = getPlayerWeight( player, currentTime );
				
				spawnpoint.distSumSquared[ team ] += distSquared;
				spawnpoint.weightedDistSumSquared[ team ] += distSquared * weight;
				spawnpoint.totalPlayers[team]++;
			}
			
			if( ( (i+1) % waitInterval ) == 0 )
			{
				wait(0.05);
				currentTime = getTime();
			}
		}
		
		// prevent infinte loop if there are fewer than waitInterval number of spawns in a map
		if( level.spawnPoints.size < waitInterval )
		{
			wait(0.05);
		}
	}
}


//============================================
// 				getSpawnTeam
//============================================
getSpawnTeam( ent )
{
	team = "all";
	
	if( level.teambased )
	{
		team = ent.team;
	}
	
	return team;
}


//============================================
// 			initSpawnPointValues
//============================================
initSpawnPointValues( spawnPoint )
{
	clearSpawnPointSightData( spawnPoint );
	clearSpawnPointDistanceData( spawnPoint );
}


//============================================
// 		clearSpawnPointSightData
//============================================
clearSpawnPointSightData( spawnPoint )
{
	if( level.teambased )
	{
		foreach( teamName in level.teamNameList )
		{
			clearTeamSpawnPointSightData( spawnPoint, teamName );
		}
	}
	else
	{
		clearTeamSpawnPointSightData( spawnPoint, "all" );
	}
}


//============================================
// 		 clearSpawnPointDistanceData
//============================================
clearSpawnPointDistanceData( spawnPoint )
{
	if( level.teambased )
	{
		foreach( teamName in level.teamNameList )
		{
			clearTeamSpawnPointDistanceData( spawnPoint, teamName );
		}
	}
	else
	{
		clearTeamSpawnPointDistanceData( spawnPoint, "all" );
	}
}


//============================================
// 		clearTeamSpawnPointSightData
//============================================
clearTeamSpawnPointSightData( spawnPoint, team )
{
	spawnPoint.sights[team] = 0;
}


//============================================
// 		clearTeamSpawnPointDistanceData
//============================================
clearTeamSpawnPointDistanceData( spawnPoint, team )
{
	spawnPoint.distSumSquared[team] 			= 0;
	spawnPoint.weightedDistSumSquared[team] 	= 0;	
	spawnPoint.minDistSquared[team] 			= 9999999;
	spawnPoint.totalPlayers[team] 				= 0;
}


//============================================
// 			getPlayerTraceHeight
//============================================
getPlayerTraceHeight( player, bReturnMaxHeight )
{
	if( IsDefined(bReturnMaxHeight) && bReturnMaxHeight )
	{
		return 72;
	}
	
	stance = player GetStance();
	
	if( stance == "stand" )
	{
		return 72;
	}
		
	if( stance == "crouch" )
	{
		return 54;
	}
		
	return 32;
}


//============================================
// 			getPlayerWeight
//============================================
getPlayerWeight( player, currentTime )
{
	weight = 1.0; 
		
	// reduce the wight of recent tactical insertion spawns
	if( player.wasTI && ( (currentTime - player.spawnTime) < 15000) )
	{
		weight *= 0.1;
	}
	
	// reduce the wight of snipers
	if( player.isSniper )
	{
		weight *= 0.5;
	}
		
	return weight;
}


//============================================
// 		additionalSightTraceEntities
//============================================
additionalSightTraceEntities( spawnPoint, entArray )
{
	foreach( ent in entArray )
	{
		if( !isDefined( ent ) )
		{
			continue;
		}
		
		team = getSpawnTeam( ent );
				
		if( spawnpoint.sights[team] )
		{
			continue;
		}

		sightValue = SpawnSightTrace( spawnpoint, spawnpoint.sightTracePoint, ent.origin + (0,0,50) );

		if( sightValue > 0 )
		{
			spawnpoint.sights[team]++;
		}
	}
}


//============================================
// 		finalizeSpawnpointChoice
//============================================
finalizeSpawnpointChoice( spawnpoint )
{
	time = getTime();
	
	self.lastspawnpoint 		= spawnpoint;
	self.lastspawntime 			= time;
	
	spawnpoint.lastspawntime 	= time;
	spawnpoint.lastspawnteam 	= self.team;
	
	/#
	bbprint( "spawns", "name %s x %f y %f z %f buddyspawn %i", "selected", spawnpoint.origin[0], spawnpoint.origin[1], spawnpoint.origin[2], spawnpoint.buddySpawn );
	
	spawningDebugHUD( spawnpoint );
	#/
}


//============================================
// 		 	expandSpawnpointBounds
//============================================
expandSpawnpointBounds( classname )
{
	spawnPoints = getSpawnpointArray( classname );
	for( index = 0; index < spawnPoints.size; index++ )
	{
		level.spawnMins = expandMins( level.spawnMins, spawnPoints[index].origin );
		level.spawnMaxs = expandMaxs( level.spawnMaxs, spawnPoints[index].origin );
	}
}


//============================================
// 		 		expandMins
//============================================
expandMins( mins, point )
{
	if ( mins[0] > point[0] )
		mins = ( point[0], mins[1], mins[2] );
	if ( mins[1] > point[1] )
		mins = ( mins[0], point[1], mins[2] );
	if ( mins[2] > point[2] )
		mins = ( mins[0], mins[1], point[2] );
	return mins;
}


//============================================
// 		 		expandMaxs
//============================================
expandMaxs( maxs, point )
{
	if ( maxs[0] < point[0] )
		maxs = ( point[0], maxs[1], maxs[2] );
	if ( maxs[1] < point[1] )
		maxs = ( maxs[0], point[1], maxs[2] );
	if ( maxs[2] < point[2] )
		maxs = ( maxs[0], maxs[1], point[2] );
	return maxs;
}


//============================================
// 		 		findBoxCenter
//============================================
findBoxCenter( mins, maxs )
{
	center = ( 0, 0, 0 );
	center = maxs - mins;
	center = ( center[0]/2, center[1]/2, center[2]/2 ) + mins;
	return center;
}
	
	
//============================================
// 		 	setMapCenterForDev
//============================================
setMapCenterForDev()
{
	level.spawnMins = (0,0,0);
	level.spawnMaxs = (0,0,0);
	
	maps\mp\gametypes\_spawnlogic::expandSpawnpointBounds( "mp_tdm_spawn_allies_start" );
	maps\mp\gametypes\_spawnlogic::expandSpawnpointBounds( "mp_tdm_spawn_axis_start" );
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );
}
	
	
/#
//============================================
// 			spawningDebugHUD
//============================================
spawningDebugHUD( spawnPoint )
{
	if( !allowDebugHud() )
	{
		destroySpawningDebugHUD();
		return;
	}
	
	createSpawningHUD();
	
	spawningHUDColor = ( 0, 1, 0 );
	
	// buddy spawning
	if( IsDefined(spawnPoint.buddySpawn) && spawnPoint.buddySpawn )
	{
		spawningHUDColor = ( 0.5, 0.5, 1 );
		spawnPoint.numberOfPossibleSpawnChoices = 999;
	}
	
	// display the number of available spawns that the player could possibly choose from
	if( IsDefined( spawnPoint.numberOfPossibleSpawnChoices ) )
	{
		self.spawningAvailableNum setValue( spawnPoint.numberOfPossibleSpawnChoices );
		
		// the hud turns red when there are few than 3 spawn points available 
		if( spawnPoint.numberOfPossibleSpawnChoices < 3 )
		{
			spawningHUDColor = ( 1, 0, 0 );
		}
	}
	
	// display the spawn point's final score value
	if( IsDefined(spawnPoint.totalScore ) )
	{
		self.spawningScoreNum setValue( spawnPoint.totalScore );
	}
		
	setSpawningHUDColor( spawningHUDColor );
}


//============================================
// 				allowDebugHud
//============================================
allowDebugHud()
{
	if( !level.debugSpawning )
		return false;
	
	if( level.inGracePeriod )
		return false;
		
	if( level.players.size == 1 )
		return false;
	
	switch( level.gametype )
	{
		case "war":
		case "conf":
		case "dom":
		case "dm":
		case "blitz":
			return true;
		default:
			return false;
	}
	
	return  false;
}


//============================================
// 			setSpawningHUDColor
//============================================
setSpawningHUDColor( color )
{ 
	self.spawningAvailableText.color 	= color;
	self.spawningAvailableNum.color 	= color;
	self.spawningScoreText.color 		= color;
	self.spawningScoreNum.color 		= color;
}


//============================================
// 			destroySpawningDebugHUD
//============================================
destroySpawningDebugHUD()
{
	if( isDefined( self.spawningAvailableText ) )
	{
		self.spawningAvailableText Destroy();
	}
	
	if( isDefined( self.spawningAvailableNum ) )
	{
		self.spawningAvailableNum Destroy();
	}
	
	if ( isDefined( self.spawningScoreText ) )
	{
		self.spawningScoreText Destroy();
	}
	
	if ( isDefined( self.spawningScoreNum ) )
	{
		self.spawningScoreNum Destroy();
	}
}


//============================================
// 			createSpawningHUD
//============================================
createSpawningHUD()
{
	if( !isDefined( self.spawningAvailableText ) )
	{
		self.spawningAvailableText = createSpawningHUDElement( 0, 200 );
		self.spawningAvailableText setText( &"MP_DEV_AVAILABLE_SPAWNS" );
	}
	
	if( !isDefined( self.spawningAvailableNum ) )
	{
		self.spawningAvailableNum = createSpawningHUDElement( 95, 200 );
		self.spawningAvailableNum setValue( 0 );
	}
	
	if ( !isDefined( self.spawningScoreText ) )
	{
		self.spawningScoreText = createSpawningHUDElement( 0, 212 );
		self.spawningScoreText setText( &"MP_DEV_AVAILABLE_SPAWNS_SCORE" );
	}
	
	if ( !isDefined( self.spawningScoreNum ) )
	{
		self.spawningScoreNum = createSpawningHUDElement( 95, 212 );
		self.spawningScoreNum setValue( 0 );
	}
}


//============================================
// 		createSpawningHUDElement
//============================================
createSpawningHUDElement( xOffset, yOffset )
{
	spawningHUD = newClientHudElem( self );
	
	spawningHUD.archived 		= false;
	spawningHUD.x 				= -100 + xOffset;		
	spawningHUD.y 				= 10 + yOffset;
	spawningHUD.alignX 			= "left";
	spawningHUD.alignY 			= "top";
	spawningHUD.horzAlign 		= "right";
	spawningHUD.vertAlign 		= "top";
	spawningHUD.sort 			= 10;
	spawningHUD.font 			= "small";
	spawningHUD.foreground 		= true;
	spawningHUD.hideWhenInMenu 	= true;
	spawningHUD.fontscale 		= 1.2;
	spawningHUD.alpha 			= 1;
	
	return spawningHUD;
}
#/