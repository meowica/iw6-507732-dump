#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;


/*QUAKED mp_blitz_spawn (0.0 0.0 1.0) (-16 -16 0) (16 16 72)
Respawn Point.*/

/*QUAKED mp_blitz_spawn_axis_start (0.5 0.0 1.0) (-16 -16 0) (16 16 72)
Start Spawn.*/

/*QUAKED mp_blitz_spawn_allies_start (0.0 0.5 1.0) (-16 -16 0) (16 16 72)
Start Spawn.*/


//============================================
// 		 			main
//============================================
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
		registerTimeLimitDvar( level.gameType, 5 );
		registerScoreLimitDvar( level.gameType, 0 );
		registerRoundLimitDvar( level.gameType, 1 );
		registerWinLimitDvar( level.gameType, 1 );
		registerNumLivesDvar( level.gameType, 0 );
		registerHalfTimeDvar( level.gameType, 0 );
		
		level.matchRules_damageMultiplier = 0;
	}
	
	level.teamBased 			= true;
	level.objectiveBased 		= false;
	level.onStartGameType 		= ::onStartGameType;
	level.getSpawnPoint 		= ::getSpawnPoint;
	level.onTimeLimit 			= ::onTimeLimit;
	level.onNormalDeath 		= ::onNormalDeath;
	level.onPrecacheGameType 	= ::onPrecacheGameType;
	
	if ( level.matchRules_damageMultiplier )
		level.modifyPlayerDamage = maps\mp\gametypes\_damage::gamemodeModifyPlayerDamage;
}


//============================================
// 		 	initializeMatchRules
//============================================
initializeMatchRules()
{
	//	set common values
	setCommonRulesFromMatchRulesData();
	
	SetDynamicDvar( "scr_blitz_roundlimit", 1 );
	registerRoundLimitDvar( "blitz", 1 );					
	SetDynamicDvar( "scr_blitz_winlimit", 1 );
	registerWinLimitDvar( "blitz", 1 );			
	SetDynamicDvar( "scr_blitz_halftime", 0 );
	registerHalfTimeDvar( "blitz", 0 );
		
	SetDynamicDvar( "scr_blitz_promode", 0 );		
}


//============================================
// 		 	onPrecacheGameType
//============================================
onPrecacheGameType()
{
	level._effect["portal_fx_green"] 	= LoadFX("misc/ui_flagbase_green");
	level._effect["portal_fx_red"] 		= LoadFX("misc/ui_flagbase_red");
	level._effect["blitz_teleport"] 	= LoadFX("fire/ballistic_vest_death");
}


//============================================
// 		 	onStartGameType
//============================================
onStartGameType()
{
	setClientNameMode("auto_change");
	
	if ( !isdefined( game["switchedsides"] ) )
		game["switchedsides"] = false;
	
	setObjectiveText( "allies", &"OBJECTIVES_WAR" );
	setObjectiveText( "axis", &"OBJECTIVES_WAR" );
	
	if ( level.splitscreen )
	{
		setObjectiveScoreText( "allies", &"OBJECTIVES_WAR" );
		setObjectiveScoreText( "axis", &"OBJECTIVES_WAR" );
	}
	else
	{
		setObjectiveScoreText( "allies", &"OBJECTIVES_WAR_SCORE" );
		setObjectiveScoreText( "axis", &"OBJECTIVES_WAR_SCORE" );
	}
	
	setObjectiveHintText( "allies", &"OBJECTIVES_1WAR_HINT" );
	setObjectiveHintText( "axis", &"OBJECTIVES_WAR_HINT" );

	initSpawns();
	
	maps\mp\gametypes\_rank::registerScoreInfo( "kill", 50 );
	maps\mp\gametypes\_rank::registerScoreInfo( "headshot", 50 );
	maps\mp\gametypes\_rank::registerScoreInfo( "assist", 20 );
	maps\mp\gametypes\_rank::registerScoreInfo( "capture", 100 );
	
	allowed[0] = level.gameType;
	maps\mp\gametypes\_gameobjects::main( allowed );
	
	createPortals();
	assginTeamSpawns();
	level thread runBlitz();
}


//============================================
// 		 		initSpawns
//============================================
initSpawns()
{
	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );
	
	maps\mp\gametypes\_spawnlogic::addStartSpawnPoints( "mp_blitz_spawn_axis_start" );
	maps\mp\gametypes\_spawnlogic::addStartSpawnPoints( "mp_blitz_spawn_allies_start" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_blitz_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_blitz_spawn" );
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );
}


//============================================
// 		 		createPortals
//============================================
createPortals()
{
	level.portals = [];
	
	axisPortalTrigger = getEnt( "axis_portal", "targetname" );
	level.portalList["axis"] = createPortal( axisPortalTrigger, "axis" );
	
	alliesPortalTrigger = getEnt( "allies_portal", "targetname" );
	level.portalList["allies"] 	= createPortal( alliesPortalTrigger, "allies" );
}


//============================================
// 		 		cretaePortal
//============================================
createPortal( trigger, team )
{
	AssertEx( IsDefined(trigger), "map needs blitz game objects" );
	
	portal 				= SpawnStruct();
	portal.origin 		= trigger.origin;
	portal.ownerTeam	= team;
	portal.open 		= true;
	portal.trigger 		= trigger;
	
	return portal;
}


//============================================
// 		 		assginTeamSpawns
//============================================
assginTeamSpawns()
{
	spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_blitz_spawn" );
	
	level.teamSpawnPoints["axis"] 	= [];
	level.teamSpawnPoints["allies"] = [];
	
	foreach( spawnPoint in spawnPoints )
	{	
		spawnPoint.teamBase = getNearestPortalTeam( spawnPoint );
		
		if( spawnPoint.teamBase == "axis" )
		{
			level.teamSpawnPoints["axis"][level.teamSpawnPoints["axis"].size] = spawnPoint;
		}
		else
		{
			level.teamSpawnPoints["allies"][level.teamSpawnPoints["allies"].size] = spawnPoint;
		}
	}	
	
	/#
	level thread blitzDebug();
	#/
}


//===========================================
// 			getNearestPortalTeam
//===========================================
getNearestPortalTeam( spawnPoint )
{
	isPathDataAvailable = maps\mp\gametypes\_spawnlogic::isPathDataAvailable();
	nearestPortal		= undefined;
	nearestDist			= undefined;

	foreach( portal in level.portalList )
	{
		dist = undefined;
		
		// find the actual pathing distance between the portal and spawn point
		if( isPathDataAvailable )
		{
			dist = GetPathDist( spawnPoint.origin, portal.origin, 999999 );
		}
		
		// fail safe for bad pathing data		
		if( !IsDefined(dist) || (dist == -1) )
		{
			dist = distancesquared( portal.origin, spawnPoint.origin );
		}
		
		// record the nearest portal
		if( !isdefined( nearestPortal ) || dist < nearestDist )
		{
			nearestPortal 	= portal;
			nearestDist 	= dist;
		}
	}
	
	return nearestPortal.ownerTeam;
}

//============================================
// 		 		onNormalDeath
//============================================
onNormalDeath( victim, attacker, lifeId )
{
	attacker thread maps\mp\gametypes\_rank::xpEventPopup( &"MP_KILL" );
}


//============================================
// 		 		runBlitz
//============================================
runBlitz()
{
	gameFlagWait( "prematch_done" );
	
	startPortal( level.portalList["axis"] );
	startPortal( level.portalList["allies"] );	
}


//============================================
// 		 		startPortal
//============================================
startPortal( portal )
{
	level thread runPortalFX( portal );
	level thread runPortalStatus( portal );
	level thread runPortalThink( portal );
}


//============================================
// 		 		runPortalFX
//============================================
runPortalFX( portal )
{
	effect = undefined;
	
	while( true )
	{
		if( IsDefined(effect) )
			effect Delete();
		
		effect_name = "portal_fx_red";
		
		if( portal.open )
		{
			effect_name = "portal_fx_green";
		}
		
		effect = spawnFx( level._effect[effect_name], portal.origin );
		triggerFx( effect );
		
		level waittill_any( "player_spawned", "portal_used", "portal_ready" );
	}
}

runPortalStatus( portal, label )
{
	offset = (0,0,72);
	enemyTeam = getOtherTeam( portal.ownerTeam );
	
	portal.ownerTeamID = maps\mp\gametypes\_gameobjects::getNextObjID();
	objective_add( portal.ownerTeamID, "active", portal.origin + offset, "waypoint_defend_flag" ); 
	Objective_Team( portal.ownerTeamID, portal.ownerTeam );
	
	portal.enemyTeamID = maps\mp\gametypes\_gameobjects::getNextObjID();
	objective_add( portal.enemyTeamID, "active", portal.origin + offset, "waypoint_targetneutral" );
	Objective_Team( portal.enemyTeamID, enemyTeam );
	
	while( true )
	{
		if( portal.open )
		{
			portal.teamHeadIcon 	= portal maps\mp\_entityheadIcons::setHeadIcon( portal.ownerTeam, "waypoint_defend_flag", offset, 4, 4, undefined, undefined, undefined, true, undefined, false );
			portal.enemyHeadIcon 	= portal maps\mp\_entityheadIcons::setHeadIcon( enemyTeam, "waypoint_targetneutral", offset, 4, 4, undefined, undefined, undefined, true, undefined, false );
			Objective_Icon( portal.ownerTeamID, "waypoint_defend_flag" );
			Objective_Icon( portal.enemyTeamID, "waypoint_targetneutral" );
		}
		else
		{
			portal.teamHeadIcon 	= portal maps\mp\_entityheadIcons::setHeadIcon( portal.ownerTeam, "waypoint_waitfor_flag", offset, 4, 4, undefined, undefined, undefined, true, undefined, false );
			portal.enemyHeadIcon 	= portal maps\mp\_entityheadIcons::setHeadIcon( enemyTeam, "waypoint_target", offset, 4, 4, undefined, undefined, undefined, true, undefined, false );
			Objective_Icon( portal.ownerTeamID, "waypoint_waitfor_flag" );
			Objective_Icon( portal.enemyTeamID, "waypoint_target" );
		}
		
		level waittill_any( "portal_used", "portal_ready" );
	}
}

runPortalThink( portal )
{
	level endon( "game_ended" );
	
	while( true )
	{
		portal.open = true;
		level notify("portal_ready");
		
		portal.trigger waittill( "trigger", player );
		
		if( !isPlayer(player) )
		{
			waitframe();
			continue;
		}
		
		if( player.team == portal.ownerTeam )
		{
			waitframe();
			continue;
		}
		
		maps\mp\gametypes\_gamescore::givePlayerScore( "capture", player );	
		player maps\mp\killstreaks\_killstreaks::giveAdrenaline( "capture" );
		giveTeamScore( player.team );
	
		spawnPoint = player getSpawnPoint();
		player teleport_player(spawnPoint.origin, spawnPoint.angles, 0);
	
		portal.open = false;
		level notify( "portal_used" );
		
		wait( 5.0 );
	}
}


//============================================
// 		 		giveTeamScore
//============================================
giveTeamScore(team)
{
	maps\mp\gametypes\_gamescore::giveTeamScoreForObjective( team, 1 );
	
	foreach( player in level.players )
	{
		if( player.team == team )
		{
			player thread maps\mp\gametypes\_hud_message::SplashNotifyUrgent( "blitz_score_team" );
		}
		else
		{
			player thread maps\mp\gametypes\_hud_message::SplashNotifyUrgent( "blitz_score_enemy" );
		}
	}
}


teleport_player( origin, angles, delay )
{
	flashTime = 1;
	white = create_client_overlay( "white", 1, self );
	white thread fade_over_time( 0, flashTime );
	white thread hudDelete( flashTime );
	
	fx_origin = self gettagorigin( "j_SpineUpper" );
	PlayFX( level._effect["blitz_teleport"], fx_origin );
	
	self playLocalSound( "copycat_steal_class" );
	
	//Clear Tac insert on teleport
	if ( isDefined( self.setSpawnPoint ) )
		self maps\mp\perks\_perkfunctions::deleteTI( self.setSpawnPoint );
	
	wait delay;
	self SetOrigin(origin);
	self SetPlayerAngles( angles );
	self SetStance("stand");
}

create_client_overlay( shader_name, start_alpha, player )
{
	if ( isdefined( player ) )
		overlay = newClientHudElem( player );
	else
		overlay = newHudElem();
	overlay.x = 0;
	overlay.y = 0;
	overlay setshader( shader_name, 640, 480 );
	overlay.alignX = "left";
	overlay.alignY = "top";
	overlay.sort = 1;
	overlay.horzAlign = "fullscreen";
	overlay.vertAlign = "fullscreen";
	overlay.alpha = start_alpha;
	overlay.foreground = true;
	return overlay;
}

fade_over_time( target_alpha, fade_time )
{
	assertex( isdefined( target_alpha ), "fade_over_time must be passed a target_alpha." );
	
	if ( isdefined( fade_time ) && fade_time > 0 )
	{
		self fadeOverTime( fade_time );
	}
	
	self.alpha = target_alpha;
	
	if ( isdefined( fade_time ) && fade_time > 0 )
	{
		wait fade_time;
	}
}


//============================================
// 		 		hudDelete
//============================================
hudDelete( delay )
{
	self endon("death");
	wait( delay );
	
	self Destroy();
}


//============================================
// 		 		getSpawnPoint
//============================================
getSpawnPoint()
{
	spawnteam = self.pers["team"];
	if ( game["switchedsides"] )
		spawnteam = getOtherTeam( spawnteam );

	if ( level.inGracePeriod )
	{
		spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_blitz_spawn_" + spawnteam + "_start" );
		spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
	}
	else
	{
		spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( spawnteam );
		spawnPoint = maps\mp\gametypes\_spawnscoring::getSpawnpoint_awayFromEnemies( spawnPoints, spawnteam );
	}
	
	return spawnPoint;;
}


//============================================
// 		 		onTimeLimit
//============================================
onTimeLimit()
{
	level.finalKillCam_winner = "none";
	
	if ( game["status"] == "overtime" )
	{
		winner = "forfeit";
	}
	else if ( game["teamScores"]["allies"] == game["teamScores"]["axis"] )
	{
		winner = "axis";
	}
	else if ( game["teamScores"]["axis"] > game["teamScores"]["allies"] )
	{
		level.finalKillCam_winner = "axis";
		winner = "axis";
	}
	else
	{
		level.finalKillCam_winner = "allies";
		winner = "allies";
	}
	
	thread maps\mp\gametypes\_gamelogic::endGame( winner, game["strings"]["time_limit_reached"] );
}

/#
//============================================
// 		 		blitzDebug
//============================================
blitzDebug()
{
	setDevDvarIfUninitialized( "scr_blitzdebug", "0" );
	
	spawnPoints 		= maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_blitz_spawn" );
	isPathDataAvailable = maps\mp\gametypes\_spawnlogic::isPathDataAvailable();
	heightOffsetLines 	= (0,0,12);
	heightOffsetNames 	= (0,0,64);
	
	while( true )
	{
		if( getdvar("scr_blitzdebug") != "1" ) 
		{
			wait( 1 );
			continue;
		}
		
		SetDevDvar( "scr_showspawns", "1" );
		
		while( true )
		{
			if( getdvar("scr_blitzdebug") != "1" )
			{
				SetDevDvar( "scr_showspawns", "0" );
				break;
			}
			
			// draw the path from each spawn point to the nearest portal
			foreach( spawnPoint in spawnPoints )
			{
				if( isPathDataAvailable )
				{
					if( !IsDefined(spawnPoint.nodeArray) )
					{
						spawnPoint.nodeArray = GetNodesOnPath( spawnPoint.origin, level.portalList[spawnPoint.teamBase].origin );
					}
					
					if( !IsDefined(spawnPoint.nodeArray) || (spawnPoint.nodeArray.size == 0) )
					{
						continue;
					}
					
					line( spawnPoint.origin + heightOffsetLines, spawnPoint.nodeArray[0].origin + heightOffsetLines, (0.2, 0.2, 0.6) );
					
					for( i = 0; i <  spawnPoint.nodeArray.size - 1; i++ )
					{
						line( spawnPoint.nodeArray[i].origin + heightOffsetLines, spawnPoint.nodeArray[i+1].origin + heightOffsetLines, (0.2, 0.2, 0.6) );
					}
				}
				else
				{
					line( level.portalList[spawnPoint.teamBase].origin + heightOffsetLines, spawnPoint.origin + heightOffsetLines, (0.2, 0.2, 0.6) );
				}
			}
			
			foreach( portal in level.portalList )
			{
				if ( portal.ownerTeam == "allies" )
					print3d( portal.origin + heightOffsetNames, "allies portal" );
				
				if ( portal.ownerTeam == "axis" )
					print3d( portal.origin + heightOffsetNames, "axis portal" );
			}
			
			waitframe();
		}
	}
}
#/