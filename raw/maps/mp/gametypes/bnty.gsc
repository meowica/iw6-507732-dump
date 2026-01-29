#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\agents\_agent_utility;
#include maps\mp\bots\_bots_util;

// bounty game mode

main()
{
	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();

	if ( isUsingMatchRulesData() )
	{
		level.initializeMatchRules = ::initializeMatchRules;
		[[level.initializeMatchRules]]();
		level thread reInitializeMatchRulesOnMigration();
	}
	else
	{
		registerTimeLimitDvar( level.gameType,12 );
		registerScoreLimitDvar( level.gameType,50 );
		registerRoundLimitDvar( level.gameType, 1 );
		registerWinLimitDvar( level.gameType, 1 );
		registerNumLivesDvar( level.gameType, 0 );
		registerHalfTimeDvar( level.gameType, 0 );
		registerRoundSwitchDvar( level.gameType, 1, 1, 1 );
		
		level.matchRules_damageMultiplier = 0;
	}
	
	level.objectiveBased 	= true;
	level.teamBased 		= true;
	level.onStartGameType 	= ::onStartGameType;
	level.getSpawnPoint 	= ::getSpawnPoint;
	level.onTimeLimit 		= ::onTimeLimit;
	level.onNormalDeath 	= ::onNormalDeath;
	
	if( level.matchRules_damageMultiplier )
		level.modifyPlayerDamage = maps\mp\gametypes\_damage::gamemodeModifyPlayerDamage;
}

initializeMatchRules()
{
	//	set common values
	setCommonRulesFromMatchRulesData();
	
	SetDynamicDvar( "scr_bnty_roundlimit", 1 );
	registerRoundLimitDvar( "bnty", 1 );					
	SetDynamicDvar( "scr_bnty_winlimit", 1 );
	registerWinLimitDvar( "bnty", 1 );			
	SetDynamicDvar( "scr_bnty_halftime", 0 );
	registerHalfTimeDvar( "bnty", 0 );
		
	SetDynamicDvar( "scr_bnty_promode", 0 );		
}

onNormalDeath( victim, attacker, lifeId )
{
	attacker thread maps\mp\gametypes\_rank::xpEventPopup( &"MP_KILL" );
}

onStartGameType()
{
	setClientNameMode("auto_change");

	if ( !isdefined( game["switchedsides"] ) )
		game["switchedsides"] = false;
	
	if ( game["switchedsides"] )
	{
		oldAttackers = game["attackers"];
		oldDefenders = game["defenders"];
		game["attackers"] = oldDefenders;
		game["defenders"] = oldAttackers;
	}

	setObjectiveText( game["attackers"], &"OBJECTIVES_WAR" );
	setObjectiveText( game["defenders"], &"OBJECTIVES_WAR" );
	
	if ( level.splitscreen )
	{
		setObjectiveScoreText( game["attackers"], &"OBJECTIVES_WAR" );
		setObjectiveScoreText( game["defenders"], &"OBJECTIVES_WAR" );
	}
	else
	{
		setObjectiveScoreText( game["attackers"], &"OBJECTIVES_WAR_SCORE" );
		setObjectiveScoreText( game["defenders"], &"OBJECTIVES_WAR_SCORE" );
	}
	
	setObjectiveHintText( game["attackers"], &"OBJECTIVES_WAR_HINT" );
	setObjectiveHintText( game["defenders"], &"OBJECTIVES_WAR_HINT" );
			
	initSpawns();
	createZones();
	createTags();
	assginTeamSpawns();
	createTimers();
	
	maps\mp\gametypes\_rank::registerScoreInfo( "kill", 50 );
	maps\mp\gametypes\_rank::registerScoreInfo( "headshot", 50 );
	maps\mp\gametypes\_rank::registerScoreInfo( "assist", 20 );
	maps\mp\gametypes\_rank::registerScoreInfo( "tag", 100 );
	
	level._effect["portal_fx_green"] 	= LoadFX("fx/misc/ui_flagbase_green");
	level._effect["blitz_teleport"] 	= LoadFX("fx/fire/ballistic_vest_death");
	
	allowed[0] = level.gameType;	
	maps\mp\gametypes\_gameobjects::main( allowed );

	level thread runBounty();
}

createTimers()
{
	level.timerDisplay = [];
		
	level.timerDisplay[game["attackers"]] = createServerTimer( "objective", 1.4, game["attackers"] );
	level.timerDisplay[game["attackers"]] setPoint( "TOP LEFT", "TOP LEFT", 25, 105 );
	level.timerDisplay[game["attackers"]].label = &"OBJECTIVES_BNTY_VIP_TIMER";
	level.timerDisplay[game["attackers"]].alpha = 0;
	level.timerDisplay[game["attackers"]].archived = false;
	level.timerDisplay[game["attackers"]].hideWhenInMenu = true;
	
	level.timerDisplay[game["defenders"]] = createServerTimer( "objective", 1.4, game["defenders"] );
	level.timerDisplay[game["defenders"]] setPoint( "TOP LEFT", "TOP LEFT", 25, 105 );
	level.timerDisplay[game["defenders"]].label = &"OBJECTIVES_BNTY_VIP_TIMER";
	level.timerDisplay[game["defenders"]].alpha = 0;
	level.timerDisplay[game["defenders"]].archived = false;
	level.timerDisplay[game["defenders"]].hideWhenInMenu = true;
	
	level thread hideTimerDisplayOnGameEnd( level.timerDisplay[game["attackers"]] );
	level thread hideTimerDisplayOnGameEnd( level.timerDisplay[game["defenders"]] );
}

hideTimerDisplayOnGameEnd( timerDisplay )
{
	level waittill("game_ended");
	timerDisplay.alpha = 0;
}


assginTeamSpawns()
{
	spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_dom_spawn" );
	
	level.teamSpawnPoints[game["attackers"]] = [];
	level.teamSpawnPoints[game["defenders"]] = [];
	
	numTeamSpawns = Int(spawnPoints.size / 2);
	
	foreach( spawnPoint in spawnPoints )
	{
		spawnPoint.dist = DistanceSquared( level.zonelist[0].origin, spawnPoint.origin );
	}
	
	while( level.teamSpawnPoints[game["defenders"]].size < numTeamSpawns )
	{
		bestSpawn = spawnPoints[0];
		
		foreach( spawnPoint in spawnPoints )
		{	
			if( spawnPoint.dist < bestSpawn.dist )
			{
				bestSpawn = spawnPoint;
			}
		}
		
		level.teamSpawnPoints[game["defenders"]][level.teamSpawnPoints[game["defenders"]].size] = bestSpawn;
		spawnPoints = array_remove( spawnPoints, bestSpawn ) ;
	}

	level.teamSpawnPoints[game["attackers"]]= spawnPoints;
}

createTags()
{
	level.tagArray = [];
	
	for( i = 0; i < 50; i++ )
	{
		visuals[0] = spawn( "script_model", (0,0,0) );
		visuals[0] setModel( "prop_dogtags_foe_animated" );
		visuals[0].baseOrigin = visuals[0].origin;
		
		visuals[1] = spawn( "script_model", (0,0,0) );
		visuals[1] setModel( "prop_dogtags_friend_animated" );
		visuals[1].baseOrigin = visuals[0].origin;
		
		trigger = spawn( "trigger_radius", (0,0,0), 0, 32, 32 );
		trigger.targetname = "trigger_dogtag";
		trigger hide();
		
		newTag = spawnStruct();
		newTag.type = "useObject";
		newTag.curOrigin = trigger.origin;
		newTag.entNum = trigger getEntityNumber();
		newTag.lastUsedTime = 0;
		newTag.visuals = visuals;
		newTag.offset3d = (0,0,16);
		newTag.trigger = trigger;
		newTag.triggerType = "proximity";
		newTag maps\mp\gametypes\_gameobjects::allowUse( "none" );
	
		newTag.visuals[0] ScriptModelPlayAnim( "mp_dogtag_spin" );
		newTag.visuals[1] ScriptModelPlayAnim( "mp_dogtag_spin" );
		
		level.tagArray[level.tagArray.size] = newTag;
	}
}

getTag()
{
	bestTag 	= level.tagArray[0];
	oldestTime 	= GetTime();
	
	foreach( tag in level.tagArray )
	{
		if( tag.interactTeam == "none" )
		{
			bestTag = tag;
			break;
		}
		
		if( tag.lastUsedTime < oldestTime )
		{
			oldestTime 	= tag.lastUsedTime;
			bestTag 	= tag;
		}
	}
	
	bestTag notify( "reset" );
	bestTag.lastUsedTime = GetTime();
	
	return bestTag;
}

createZones()
{
	level.zoneList = [];
	
	campLocations = GetNodeArray( "camp_node", "targetname" );
	AssertEx( IsDefined(campLocations) && (campLocations.size > 0), "map needs bounty game objects" );
	
	foreach( campLocation in campLocations)
	{
		level.zoneList[level.zoneList.size] = createZone( campLocation );
	}
}

createZone( campLocation )
{			
	zone 				= SpawnStruct();
	zone.origin 		= campLocation.origin;
	zone.node			= campLocation;
	zone.ownerTeam		= game["defenders"];
	
	return zone;
}



runBounty()
{
	gameFlagWait( "prematch_done" );
	
	while( !IsDefined(level.bot_loadouts_initialized) || (level.bot_loadouts_initialized == false) )
	{
		waitframe();
	}

	level thread runZone( level.zoneList[ RandomInt(level.zoneList.size)] );
}


runZone( zone )
{
	level endon ( "game_ended" );
	
	respawnTime 	= 5.0;
	spawnLocation 	= zone.origin;
	
	while( true )
	{
		agent = undefined;
				
		while( !IsDefined(agent) )
		{
			agent = maps\mp\agents\_agents::add_player_agent( zone.ownerTeam, undefined, spawnLocation, (0,0,0) );
			
			if( IsDefined(agent) )
			{
				agent BotSetDifficulty( "veteran" );
				agent.zone = zone;
			}
			else
			{
				waitframe();
			}
		}
		
		ownerTeamID = maps\mp\gametypes\_gameobjects::getNextObjID();
		objective_add( ownerTeamID, "active", (0,0,0), "waypoint_defend_flag" );
		objective_onEntity( ownerTeamID, agent );
		Objective_Team( ownerTeamID, agent.team );
		
		enemyTeamID = maps\mp\gametypes\_gameobjects::getNextObjID();
		objective_add( enemyTeamID, "active", (0,0,0), "waypoint_target" );
		objective_onEntity( enemyTeamID, agent );
		Objective_Team( enemyTeamID, getOtherTeam(agent.team) );
		
		teamHeadIcon 		= agent maps\mp\_entityheadIcons::setHeadIcon( agent.team, "waypoint_defend_flag", (0,0,72), 4, 4, undefined, undefined, undefined, true, undefined, false );
		enemyteamHeadIcon 	= agent maps\mp\_entityheadIcons::setHeadIcon( getOtherTeam(agent.team), "waypoint_target", (0,0,72), 4, 4, undefined, undefined, undefined, true, undefined, false );
		agent notify ( "destroyIconsOnDeath" );
		
		agent waittill( "death" );
		
		foreach( player in level.players )
		{
			if( !isReallyAlive(player) )
			{
				continue;
			}
			
			player PlaySoundToPlayer( "mp_defcon_one", player );
			
			if( player.team == zone.ownerTeam )
			{
				player thread maps\mp\gametypes\_hud_message::SplashNotify( "bnty_friendly_down" );
			}
			else
			{
				player thread maps\mp\gametypes\_hud_message::SplashNotify( "bnty_enemy_down" );
			}
		}
		
		teamHeadIcon destroy();
		enemyteamHeadIcon destroy();
		_objective_delete( ownerTeamID );
		_objective_delete( enemyTeamID );
		
		effect = spawnFx( level._effect["blitz_teleport"], zone.dropLocation + ( 0,0,42) );
		triggerFx( effect );
			
		tagDropRate = 1;
		tagCount 	= 0;
		tagArray	= [];
		
		//while( tagCount < tagDropRate )
		//{
			newTag = spawnTag( zone.dropLocation, 0, 400, zone.ownerTeam );
			tagArray[tagArray.size] = newTag;
			//tagCount++;
			//waitframe();
		//}
		
		level thread tagPileMarker( tagArray, zone.ownerTeam, zone.dropLocation );
		monitorTagUse( newTag );
		
		spawnLocation = zone.dropLocation;
		zone.spawnLocation = spawnLocation;
			
		headIconEnt = spawn( "script_origin", spawnLocation + (0,0,5) );
		headIconEnt.icon = headIconEnt maps\mp\_entityheadIcons::setHeadIcon( zone.ownerTeam, "waypoint_waitfor_flag", (0,0,32), 4, 4, undefined, undefined, undefined, true, undefined, false );
		
		respawnTeamID = maps\mp\gametypes\_gameobjects::getNextObjID();
		objective_add( respawnTeamID, "active", spawnLocation, "waypoint_waitfor_flag" );
		Objective_Team( respawnTeamID, zone.ownerTeam );
		
		level.timerDisplay[zone.ownerTeam] setTimer( respawnTime );
		level.timerDisplay[zone.ownerTeam].alpha = 1;
		
		wait( respawnTime );
		
		level.timerDisplay[zone.ownerTeam].alpha = 0;
		
		_objective_delete( respawnTeamID );
		headIconEnt Delete();
	}
}

tagPileMarker( tagArray, friendlyTeam, dropLocation )
{
	timeStamp = GetTime();
	
	friendlyTeamID = maps\mp\gametypes\_gameobjects::getNextObjID();
	objective_add( friendlyTeamID, "active", dropLocation, "waypoint_dogtags_friendly" );
	Objective_Team( friendlyTeamID, friendlyTeam );
		
	enemyTeamID = maps\mp\gametypes\_gameobjects::getNextObjID();
	objective_add( enemyTeamID, "active", dropLocation, "waypoint_dogtags" );
	Objective_Team( enemyTeamID, getOtherTeam(friendlyTeam) );
	
	headEnt = spawn( "script_origin",  dropLocation );
	teamHeadIcon 		= headEnt maps\mp\_entityheadIcons::setHeadIcon( friendlyTeam, "waypoint_defend_flag", (0,0,72), 4, 4, undefined, undefined, undefined, true, undefined, false );
	enemyteamHeadIcon 	= headEnt maps\mp\_entityheadIcons::setHeadIcon( getOtherTeam(friendlyTeam), "waypoint_target", (0,0,72), 4, 4, undefined, undefined, undefined, true, undefined, false );
	
	while( tagArray.size != 0 )
	{
		foreach( tag in tagArray )
		{
			// tag was collected
			if( tag.interactTeam == "none" )
			{
				tagArray = array_remove( tagArray, tag );
				break;
			}
			
			// tag was recycled 
			if( tag.lastUsedTime >  timeStamp )
			{
				tagArray = array_remove( tagArray, tag );
				break;
			}
		}
		
		waitframe();
	}
	
	teamHeadIcon destroy();
	enemyteamHeadIcon destroy();
		
	_objective_delete( friendlyTeamID );
	_objective_delete( enemyTeamID );
	
	headEnt Delete();
}

spawnTag( dropLocation, distMin, distMax, team  )
{
	startPos 		= dropLocation + (0,0,14);
	//randomAngle 	= (0,RandomFloat(360),0);
	//randomDir 		= AnglesToForward(randomAngle);
	//randomDst 		= RandomFloatRange( 40, 300 );
	
	//testpos = startpos + (randomDst * randomDir);
	//pos = PlayerPhysicsTrace( startPos, testpos );
	
	newTag = getTag();
	newTag.team					= team;
	newTag.curOrigin 			= startPos;
	newTag.trigger.origin 		= startPos;
	newTag.visuals[0].origin 	= startPos;
	newTag.visuals[1].origin 	= startPos;
	newTag.visuals[0] thread showToTeam( newTag, getOtherTeam( team ) );
	newTag.visuals[1] thread showToTeam( newTag, team );

	newTag maps\mp\gametypes\_gameobjects::allowUse( "any" );
	
	return newTag;
}

showToTeam( gameObject, team )
{
	gameObject endon( "death" );

	self hide();

	foreach ( player in level.players )
	{
		if( player.team == team )
			self ShowToPlayer( player );
	}
}

monitorTagUse( tag )
{
	level endon ( "game_ended" );
	tag endon ( "deleted" );
	tag endon( "reset" );
	
	while ( true )
	{
		tag.trigger waittill ( "trigger", player );
		
		if ( !isReallyAlive( player ) )
			continue;
			
		if ( player isUsingRemote() || isDefined( player.spawningAfterRemoteDeath ) )
			continue;
			
		if ( IsDefined( player.classname ) && player.classname == "script_vehicle" )
			continue;
		
		tag.visuals[0] hide();
		tag.visuals[1] hide();
		tag.curOrigin = (0,0,1000);
		tag.trigger.origin = (0,0,1000);
		tag.visuals[0].origin = (0,0,1000);
		tag.visuals[1].origin = (0,0,1000);
		tag maps\mp\gametypes\_gameobjects::allowUse( "none" );	

		player thread maps\mp\gametypes\_rank::giveRankXP( "tag", 50 );
		
		if( player.team != tag.team )
		{
			level thread bountyEndGame( player.team, game["strings"]["time_limit_reached"] );
			//player maps\mp\gametypes\_gamescore::giveTeamScoreForObjective( player.pers["team"], 1 );	
		}		
		
		break;
	}
}

bountyEndGame( winningTeam, endReasonText )
{
	level.finalKillCam_winner = winningTeam;
	level thread maps\mp\gametypes\_gamelogic::endGame( winningTeam, endReasonText );	
}

initSpawns()
{
	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );	
	
	maps\mp\gametypes\_spawnlogic::addStartSpawnPoints( "mp_dom_spawn_allies_start" );
	maps\mp\gametypes\_spawnlogic::addStartSpawnPoints( "mp_dom_spawn_axis_start" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_dom_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_dom_spawn" );
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );
}


getSpawnPoint()
{
	spawnteam = self.team;
	if ( game["switchedsides"] )
		spawnteam = getOtherTeam( spawnteam );

	if ( level.inGracePeriod )
	{
		spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_dom_spawn_" + spawnteam + "_start" );
		spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
	}
	else
	{
		spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( spawnteam );
		spawnPoint = maps\mp\gametypes\_spawnscoring::getSpawnpoint_awayFromEnemies( spawnPoints, spawnteam );
	}
	
	return spawnPoint;
}


onTimeLimit()
{
	level.finalKillCam_winner = game["defenders"];
	level thread maps\mp\gametypes\_gamelogic::endGame( game["defenders"], game["strings"]["time_limit_reached"] );
}