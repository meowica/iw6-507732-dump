#include maps\mp\gametypes\_spawnfactor;
#include common_scripts\utility;
#include maps\mp\_utility;

//===========================================
// 			getSpawnpoint_NearTeam
//===========================================
getSpawnpoint_NearTeam( spawnPoints )
{
	spawnPoints = checkDynamicSpawns( spawnPoints );
	bestSpawn 	= spawnPoints[0];
	
	foreach( spawnPoint in spawnPoints )
	{
		initScoreData( spawnPoint );

		// spawn points must pass all critical factors to be selected
		if( !criticalFactors_NearTeam( spawnPoint ) )
		{
			continue;
		}
	
		// calculates the total score of the spawn point
		scoreFactors_NearTeam( spawnPoint );
		
		// select the spawn point with the largest score
		if( spawnPoint.totalScore > bestSpawn.totalScore )
		{
			bestSpawn = spawnPoint;
		}
	}
	
	bestSpawn = selectBestSpawnPoint( bestSpawn, spawnPoints );
	
	return bestSpawn;
}


//============================================
// 			checkDynamicSpawns
//============================================
checkDynamicSpawns( spawnPoints )
{
	// a function callback that allows level script to adjust spawn points dynamically based on level specific events
	if( isDefined( level.dynamicSpawns ) )
	{
		spawnPoints = [[level.dynamicSpawns]]( spawnPoints );
	}
	
	return spawnPoints;
}


//============================================
// 			selectBestSpawnPoint
//============================================
selectBestSpawnPoint( highestScoringSpawn, spawnPoints )
{
	bestSpawn = highestScoringSpawn;
	numberOfPossibleSpawnChoices = 0;
	
	// calcualte the number of available spawns
	foreach( spawnPoint in spawnPoints )
	{
		if( spawnPoint.totalScore > 0 )
		{
			numberOfPossibleSpawnChoices++;
		}
	}
	
	// there are enough good spawns to safely apply additional spawn selection logic
	if( numberOfPossibleSpawnChoices > 3 )
	{
		// if the best spawn point was the last spawn point, find the second best spawn point
		if( IsDefined( self.lastspawnpoint ) && ( bestSpawn == self.lastspawnpoint ) )
		{
			bestSpawn = findSecondHighestSpawnScore( highestScoringSpawn, spawnPoints );
		}
	}
		
	// not enough avaliable spawns to guarantee a good spawn
	if( ( numberOfPossibleSpawnChoices == 0 ) || level.forceBuddySpawn )
	{
		// try to spawn on a buddy
		if( level.teamBased )
		{
			teamSpawnPoint = findBuddySpawn();

			if( teamSpawnPoint.buddySpawn )
			{
				bestSpawn = teamSpawnPoint;
			}
		}

		// if all spawn points are bad, pick randomly
		if( bestSpawn.totalScore == 0 )
		{
			bestSpawn = spawnPoints[RandomInt( spawnPoints.size )];
		}
	}
	
	/#
	bestSpawn.numberOfPossibleSpawnChoices = numberOfPossibleSpawnChoices;
	#/
	
	return bestSpawn;
}


//============================================
// 		 	findSecondHighestSpawnScore
//============================================
findSecondHighestSpawnScore( highestScoringSpawn, spawnPoints )
{
	if( spawnPoints.size < 2 )
	{
		return highestScoringSpawn;
	}
	
	bestSpawn = spawnPoints[0];
	
	// exclude the highest scoring spawn
	if( bestSpawn == highestScoringSpawn )
	{
		bestSpawn = spawnPoints[1];
	}
	
	foreach( spawnPoint in spawnPoints )
	{
		// exclude the highest scoring spawn
		if( spawnPoint == highestScoringSpawn )
		{
			continue;
		}
		
		// select the spawn point with the largest score
		if( spawnPoint.totalScore > bestSpawn.totalScore )
		{
			bestSpawn = spawnPoint;
		}
	}
	
	return bestSpawn;
}


//============================================
// 				findBuddySpawn
//============================================
findBuddySpawn()
{
	spawnLocation = SpawnStruct();
	initScoreData( spawnLocation );
	
	teamMates = getTeamMatesOutOfCombat( self.team );
	
	trace = SpawnStruct();
	trace.maxTraceCount = 18;
	trace.currentTraceCount = 0;
	
	foreach( player in teamMates )
	{
		location = findSpawnLocationNearPlayer( player );
		
		if( !IsDefined( location ) )
		{
			continue;
		}
		
		if( isSafeToSpawnOn( player, location, trace ) )
		{
			spawnLocation.totalScore 	= 999;
			spawnLocation.buddySpawn	= true;
			spawnLocation.origin 		= location;
			spawnLocation.angles		= getBuddySpawnAngles( player, spawnLocation.origin );
			break;
		}
		
		if( trace.currentTraceCount == trace.maxTraceCount )
		{
			break;
		}
	}
	
	return spawnLocation;
}


//============================================
// 			getBuddySpawnAngles
//============================================
getBuddySpawnAngles( buddy, spawnLocation )
{
	// start with the buddy's angles
	spawnAngles = ( 0, buddy.angles[1], 0 );
	
	entranceNodes = FindEntrances( spawnLocation );
	
	// pick an angle that faces an entrace
	if( IsDefined(entranceNodes) && (entranceNodes.size > 0) )
	{
		spawnAngles = VectorToAngles( entranceNodes[0].origin - spawnLocation );
	}
	
	return spawnAngles;
}


//============================================
// 			getTeamMatesOutOfCombat
//============================================
getTeamMatesOutOfCombat( team )
{
	teamMates = [];
	
	foreach( player in level.players )
	{
		// only find teammates
		if( player.team != team )
		{
			continue;
		}
		
		// only find active teammates
		if( player.sessionstate != "playing" )
		{
			continue;
		}
		
		if( !isReallyAlive(player) )
		{
			continue;
		}
		
		if( player == self )
		{
			continue;
		}
		
		// only find players not in combat
		if( isPlayerInCombat( player ) )
		{
			continue;
		}
		
		teamMates[teamMates.size] = player;
	}

	return array_randomize( teamMates );
}


//============================================
// 			isPlayerInCombat
//============================================
isPlayerInCombat( player )
{
	if( player IsSighted() )
	{
		return true;
	}
		
	// player must be on the ground
	if( !player IsOnGround() )
	{
		return true;
	}
	
	if( player IsOnLadder() )
	{
		return true;
	}
	
	if( player isFlashed() )
	{
		return true;
	}
	
	// player must be at max health
	if( player.health < player.maxhealth )
	{
		return true;
	}
	
	// player cannot be near any grenades
	if( !avoidGrenades( player ) )
	{
		return true;
	}
	
	// player cannot be near any explosives
	if( !avoidMines( player ) )
	{
		return true;
	}
	
	return false;
}


//============================================
// 		findSpawnLocationNearPlayer
//============================================
findSpawnLocationNearPlayer( player )
{
	playerHeight = maps\mp\gametypes\_spawnlogic::getPlayerTraceHeight( player, true );
	buddyNode = findBuddyPathNode( player, playerHeight );
	
	if( IsDefined( buddyNode ) )
	{
		return buddyNode.origin;
	}
	
	return undefined;
}


//============================================
// 			findBuddyPathNode
//============================================
findBuddyPathNode( buddy, playerHeight )
{
	nodeArray 	= GetNodesInRadiusSorted( buddy.origin, 192, 64, playerHeight, "Path" );
	bestNode 	= undefined;
	
	if( IsDefined(nodeArray) && nodeArray.size > 0 )
	{
		buddyDir = AnglesToForward( buddy.angles );
		
		// loop to find a node that is not in the player's current FOV
		foreach( buddyNode in nodeArray )
		{
			directionToNode = VectorNormalize( buddyNode.origin - buddy.origin );
			dot = VectorDot( buddyDir, directionToNode );
			
			// the node is not in the player's FOV ( cos 45 = 0.525 )
			if( (dot < 0.525) && !positionWouldTelefrag( buddyNode.origin ) )
			{
				// trace from the buddy to the buddySpawnLocation at head level 
				// this check ensures players do not buddy spawn on the opposite side of a wall  
				if( sightTracePassed( buddy.origin + (0,0,playerHeight), buddyNode.origin + (0,0,playerHeight), false, buddy ) )
				{
					bestNode = buddyNode;
					break;
				}
			}
		}
	}
	
	return bestNode;
}


//============================================
// 			isSafeToSpawnOn
//============================================
isSafeToSpawnOn( teamMember, pointToSpawnCheck, trace )
{
	if( teamMember IsSighted() )
	{
		return false;
	}
	
	foreach( player in level.players )
	{
		if( trace.currentTraceCount == trace.maxTraceCount )
		{
			return false;
		}
				
		if( player.team == self.team )
		{
			continue;
		}
		
		if( player.sessionstate != "playing" )
		{
			continue;
		}
		
		if( !isReallyAlive(player) )
		{
			continue;
		}
		
		if( player == self )
		{
			continue;
		}
		
		trace.currentTraceCount++;
		playerHeight = maps\mp\gametypes\_spawnlogic::getPlayerTraceHeight( player );
		
		sightValue = SpawnSightTrace( trace, pointToSpawnCheck + (0,0,playerHeight), player.origin + (0,0,playerHeight) );
		
		if( sightValue > 0 )
		{
			return false;
		}
	}
	
	return true;	
}


//===========================================
// 			initScoreData
//===========================================
initScoreData( spawnPoint )
{
	spawnPoint.totalScore = 0;
	spawnPoint.numberOfPossibleSpawnChoices = 0;
	spawnPoint.buddySpawn = false;
	
	/#
	spawnPoint.debugScoreData = [];
	spawnPoint.debugCriticalData = [];
	spawnPoint.totalPossibleScore = 0;
	#/
}


//===========================================
// 			criticalFactors_NearTeam
//===========================================
criticalFactors_NearTeam( spawnPoint )
{
	// never spawn with line of sight to an enemy
	if( !critical_factor( ::avoidVisibleEnemies, spawnPoint ) )
	{
		return false;
	}
	
	// never spawn on top of a grenade
	if( !critical_factor( ::avoidGrenades, spawnPoint ) )
	{
		return false;
	}
	
	// never spawn on top of a mine/claymore
	if( !critical_factor( ::avoidMines, spawnPoint ) )
	{
		return false;
	}
	
	// never spawn on an airstrike location
	if( !critical_factor( ::avoidAirStrikeLocations, spawnPoint ) )
	{
		return false;
	}
	
	// never spawn on top of a care package
	if( !critical_factor( ::avoidCarePackages, spawnPoint ) )
	{
		return false;
	}
	
	// never spawn inside another player
	if( !critical_factor( ::avoidTelefrag, spawnPoint ) )
	{
		return false;
	}
	
	// never spawn at a point where an enemy just spawned
	if( !critical_factor( ::avoidEnemySpawn, spawnPoint ) )
	{
		return false;
	}
	
	return true;
}


//===========================================
// 			scoreFactors_NearTeam
//===========================================
scoreFactors_NearTeam( spawnPoint )
{
	// perfer nearby teammates
	scoreFactor = score_factor( 2.5, ::preferAlliesByDistance, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid nearby enemies
	scoreFactor = score_factor( 1.25, ::avoidEnemiesByDistance, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid spawning near your last death location
	scoreFactor = score_factor( 0.25, ::avoidLastDeathLocation, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid spawning near your last attacker
	scoreFactor = score_factor( 0.25, ::avoidLastAttackerLocation, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid choosing the same spawn twice in a row
	scoreFactor = score_factor( 0.25, ::avoidSameSpawn, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
}


//===========================================
// 		  getSpawnpoint_Domination
//===========================================
getSpawnpoint_Domination( spawnPoints, perferdDomPointArray )
{
	spawnPoints = checkDynamicSpawns( spawnPoints );
	bestSpawn 	= spawnPoints[0];
	
	foreach( spawnPoint in spawnPoints )
	{
		initScoreData( spawnPoint );

		// spawn points must pass all critical factors to be selected
		if( !criticalFactors_Domination( spawnPoint ) )
		{
			continue;
		}
	
		// calculates the total score of the spawn point
		scoreFactors_Domination( spawnPoint, perferdDomPointArray );
		
		// select the spawn point with the largest score
		if( spawnPoint.totalScore > bestSpawn.totalScore )
		{
			bestSpawn = spawnPoint;
		}
	}
	
	bestSpawn = selectBestSpawnPoint( bestSpawn, spawnPoints );
	
	return bestSpawn;
}


//===========================================
// 		criticalFactors_Domination
//===========================================
criticalFactors_Domination( spawnPoint )
{
	return criticalFactors_NearTeam( spawnPoint );
}


//===========================================
// 		scoreFactors_Domination
//===========================================
scoreFactors_Domination( spawnPoint, perferdDomPointArray )
{
	// prefer spawns near dom points
	scoreFactor = score_factor( 1.5, ::preferDomPoints, spawnPoint, perferdDomPointArray );
	spawnPoint.totalScore += scoreFactor;
	
	// perfer nearby teammates
	scoreFactor = score_factor( 1.0, ::preferAlliesByDistance, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid nearby enemies
	scoreFactor = score_factor( 1.0, ::avoidEnemiesByDistance, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid spawning near your last death location
	scoreFactor = score_factor( 0.25, ::avoidLastDeathLocation, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid spawning near your last attacker
	scoreFactor = score_factor( 0.25, ::avoidLastAttackerLocation, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid choosing the same spawn twice in a row
	scoreFactor = score_factor( 0.25, ::avoidSameSpawn, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
}


//===========================================
// 		getSpawnpoint_FreeForAll
//===========================================
getSpawnpoint_FreeForAll( spawnpoints )
{
	spawnPoints = checkDynamicSpawns( spawnPoints );
	bestSpawn 	= spawnPoints[0];
	
	foreach( spawnPoint in spawnPoints )
	{
		initScoreData( spawnPoint );

		// spawn points must pass all critical factors to be selected
		if( !criticalFactors_FreeForAll( spawnPoint ) )
		{
			continue;
		}
	
		// calculates the total score of the spawn point
		scoreFactors_FreeForAll( spawnPoint );
		
		// select the spawn point with the largest score
		if( spawnPoint.totalScore > bestSpawn.totalScore )
		{
			bestSpawn = spawnPoint;
		}
	}
	
	bestSpawn = selectBestSpawnPoint( bestSpawn, spawnPoints );
	
	return bestSpawn;
}


//===========================================
// 		criticalFactors_FreeForAll
//===========================================
criticalFactors_FreeForAll( spawnPoint )
{
	return criticalFactors_NearTeam( spawnPoint );
}


//===========================================
// 		scoreFactors_FreeForAll
//===========================================
scoreFactors_FreeForAll( spawnPoint )
{	
	// avoid nearby enemies
	scoreFactor = score_factor( 3.0, ::avoidEnemiesByDistance, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid spawning near your last death location
	scoreFactor = score_factor( 0.5, ::avoidLastDeathLocation, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid spawning near your last attacker
	scoreFactor = score_factor( 0.5, ::avoidLastAttackerLocation, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid choosing the same spawn twice in a row
	scoreFactor = score_factor( 0.5, ::avoidSameSpawn, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
}


//===========================================
// 		getSpawnpoint_SearchAndRescue
//===========================================
getSpawnpoint_SearchAndRescue( spawnPoints )
{
	spawnPoints = checkDynamicSpawns( spawnPoints );
	bestSpawn 	= spawnPoints[0];
	
	foreach( spawnPoint in spawnPoints )
	{
		initScoreData( spawnPoint );

		// spawn points must pass all critical factors to be selected
		if( !criticalFactors_SearchAndRescue( spawnPoint ) )
		{
			continue;
		}
	
		// calculates the total score of the spawn point
		scoreFactors_SearchAndRescue( spawnPoint );
		
		// select the spawn point with the largest score
		if( spawnPoint.totalScore > bestSpawn.totalScore )
		{
			bestSpawn = spawnPoint;
		}
	}
	
	bestSpawn = selectBestSpawnPoint( bestSpawn, spawnPoints );
	
	return bestSpawn;
}


//===========================================
// 		criticalFactors_SearchAndRescue
//===========================================
criticalFactors_SearchAndRescue( spawnPoint )
{
	return criticalFactors_NearTeam( spawnPoint );
}


//===========================================
// 		scoreFactors_SearchAndRescue
//===========================================
scoreFactors_SearchAndRescue( spawnPoint )
{	
	// avoid nearby enemies
	scoreFactor = score_factor( 3.0, ::avoidEnemiesByDistance, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// perfer nearby teammates
	scoreFactor = score_factor( 1.0, ::preferAlliesByDistance, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid spawning near your last death location
	scoreFactor = score_factor( 0.5, ::avoidLastDeathLocation, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid spawning near your last attacker
	scoreFactor = score_factor( 0.5, ::avoidLastAttackerLocation, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
}


//===========================================
// 		getSpawnpoint_awayFromEnemies
//===========================================
getSpawnpoint_awayFromEnemies( spawnPoints, team )
{
	spawnPoints = checkDynamicSpawns( spawnPoints );
	bestSpawn 	= spawnPoints[0];
	
	foreach( spawnPoint in spawnPoints )
	{
		initScoreData( spawnPoint );

		// spawn points must pass all critical factors to be selected
		if( !criticalFactors_awayFromEnemies( spawnPoint ) )
		{
			continue;
		}
	
		// calculates the total score of the spawn point
		scoreFactors_awayFromEnemies( spawnPoint, team );
		
		// select the spawn point with the largest score
		if( spawnPoint.totalScore > bestSpawn.totalScore )
		{
			bestSpawn = spawnPoint;
		}
	}
	
	bestSpawn = selectBestSpawnPoint( bestSpawn, spawnPoints );
	
	return bestSpawn;
}


//===========================================
// 		criticalFactors_awayFromEnemies
//===========================================
criticalFactors_awayFromEnemies( spawnPoint )
{
	return criticalFactors_NearTeam( spawnPoint );
}


//===========================================
// 		scoreFactors_awayFromEnemies
//===========================================
scoreFactors_awayFromEnemies( spawnPoint, team )
{	
	// avoid nearby enemies
	scoreFactor = score_factor( 2.5, ::avoidEnemiesByDistance, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid spawning near your last attacker
	scoreFactor = score_factor( 1.0, ::avoidLastAttackerLocation, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// perfer nearby teammates
	scoreFactor = score_factor( 1.0, ::preferAlliesByDistance, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid spawning near your last death location
	scoreFactor = score_factor( 0.25, ::avoidLastDeathLocation, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid choosing the same spawn twice in a row
	scoreFactor = score_factor( 0.25, ::avoidSameSpawn, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
}