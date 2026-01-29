#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

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
		registerRoundSwitchDvar( level.gameType, 0, 0, 9 );
		registerTimeLimitDvar( level.gameType, 10 );
		registerScoreLimitDvar( level.gameType, 500 );
		registerRoundLimitDvar( level.gameType, 1 );
		registerWinLimitDvar( level.gameType, 1 );
		registerNumLivesDvar( level.gameType, 0 );
		registerHalfTimeDvar( level.gameType, 0 );
	}

	level.teamBased 			= true;
	level.onStartGameType		= ::onStartGameType;
	level.getSpawnPoint 		= ::getSpawnPoint;
	level.onNormalDeath 		= ::onNormalDeath;
	level.onPrecacheGameType 	= ::onPrecacheGameType;
	level.onXPEvent 			= ::onXPEvent;
}

onXPEvent( event )
{
	if ( IsDefined( event ) && (event == "suicide") )
	{
		level thread dropTags( self, self );
	}
	self maps\mp\gametypes\_globallogic::onXPEvent( event );
}

onPrecacheGameType()
{
	level._effect["portal_fx_green"] 	= LoadFX("misc/ui_flagbase_green");
	level._effect["portal_fx_red"] 		= LoadFX("misc/ui_flagbase_red");
}

initializeMatchRules()
{
	//	set common values
	setCommonRulesFromMatchRulesData();
	
	SetDynamicDvar( "scr_grind_roundswitch", 0 );
	registerRoundSwitchDvar( "grind", 0, 0, 9 );
	SetDynamicDvar( "scr_grind_roundlimit", 1 );
	registerRoundLimitDvar( "grind", 1 );		
	SetDynamicDvar( "scr_grind_winlimit", 1 );
	registerWinLimitDvar( "grind", 1 );			
	SetDynamicDvar( "scr_grind_halftime", 0 );
	registerHalfTimeDvar( "grind", 0 );
	SetDynamicDvar( "scr_grind_promode", 0 );	
}


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
	
	setObjectiveHintText( "allies", &"OBJECTIVES_WAR_HINT" );
	setObjectiveHintText( "axis", &"OBJECTIVES_WAR_HINT" );
			
	initSpawns();
	createTags();
	createZones();
	
	allowed[0] = level.gameType;
	maps\mp\gametypes\_gameobjects::main( allowed );

	level thread onPlayerConnect();
	level thread runZones();
}

createTags()
{
	level.tagArray = [];
	
	for( i = 0; i < 65; i++ )
	{
		visual = spawn( "script_model", (0,0,0) );
		visual setModel( "prop_dogtags_foe_animated" );
		visual.baseOrigin = visual.origin;
		visual ScriptModelPlayAnim( "mp_dogtag_spin" );
		visual hide();
		
		trigger = spawn( "trigger_radius", (0,0,0), 0, 32, 32 );
		trigger.targetname = "trigger_dogtag";
		trigger Hide();
		
		newTag = spawnStruct();
		newTag.type = "useObject";
		newTag.curOrigin = trigger.origin;
		newTag.entNum = trigger getEntityNumber();
		newTag.lastUsedTime = 0;
		newTag.visual = visual;
		newTag.offset3d = (0,0,16);
		newTag.trigger = trigger;
		newTag.triggerType = "proximity";
		newTag maps\mp\gametypes\_gameobjects::allowUse( "none" );
		
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

spawnTag( dropLocation, bRabdom )
{
	startPos = dropLocation + (0,0,14);
	
	if( IsDefined(bRabdom) && bRabdom )
	{
		randomAngle = (0,RandomFloat(360),0);
		randomDir = AnglesToForward(randomAngle);
		randomDst = RandomFloatRange( 40, 300 );
		
		testpos = startpos + (randomDst * randomDir);
		startPos = PlayerPhysicsTrace( startPos, testpos );
	}
	
	newTag = getTag();
	newTag.curOrigin 			= startPos;
	newTag.trigger.origin 		= startPos;
	newTag.visual.origin		= startPos;
	
	newTag.trigger show();
	newTag.visual show();

	newTag maps\mp\gametypes\_gameobjects::allowUse( "any" );
	
	return newTag;
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
		
		if( IsAgent(player) && IsDefined(player.owner) )
			player = player.owner;
		
		tag.visual hide();
		tag.trigger hide();
		
		tag.curOrigin = (0,0,1000);
		tag.trigger.origin = (0,0,1000);
		tag.visual.origin = (0,0,1000);
	
		tag maps\mp\gametypes\_gameobjects::allowUse( "none" );	

		player thread maps\mp\gametypes\_rank::giveRankXP( "tag", 50 );
		player.tagsCarried++;
		player.game_extrainfo = player.tagsCarried;
		player.tagsText setValue( player.tagsCarried );
		player playSound( "mp_killconfirm_tags_pickup" );
		
		break;
	}
}

onPlayerConnect()
{
	while ( true )
	{
		level waittill( "connected", player );
		
		player.isScoring		= false;
		player.tagsCarried 		= 1;
		player.game_extrainfo 	= player.tagsCarried;
	
		player.tagsIcon = player createIcon( "hud_tagcount", 48, 48 );
		player.tagsIcon setPoint( "BOTTOM LEFT", "BOTTOM LEFT", 90, -50 );
		player.tagsIcon.alpha = 1;
		player.tagsIcon.hideWhenInMenu = true;
		player.tagsIcon.archived = true;
		level thread hideHudElementOnGameEnd( player.tagsIcon );
	
		player.tagsText = player createFontString( "bigfixed", 1.0 );
		player.tagsText setParent( player.tagsIcon );
		player.tagsText setPoint( "CENTER", "CENTER", -24 );
		player.tagsText setValue( player.tagsCarried );
		player.tagsText.alpha = 1;
		player.tagsText.color = (1,1,0.5);
		player.tagsText.glowAlpha = 1;
		player.tagsText.sort = 1;
		player.tagsText.hideWhenInMenu = true;
		player.tagsText.archived = true;
		player.tagsText maps\mp\gametypes\_hud::fontPulseInit( 3.0 );
		level thread hideHudElementOnGameEnd( player.tagsText );
	}
}

hideHudElementOnGameEnd( hudElement )
{
	level waittill( "game_ended" );
	
	if( isDefined( hudElement ) )
		hudElement.alpha = 0;
}

createZones()
{
	level.zoneList 		= [];
	game["flagmodels"] 	= [];
	
	game["flagmodels"]["neutral"] 	= "prop_flag_neutral";
	game["flagmodels"]["allies"] 	= maps\mp\gametypes\_teams::getTeamFlagModel( "allies" );
	game["flagmodels"]["axis"] 		= maps\mp\gametypes\_teams::getTeamFlagModel( "axis" );

	grindTriggers = getEntArray( "grind_location", "targetname" );
	
	foreach( grindTrigger in grindTriggers )
	{
		level.zoneList[level.zoneList.size] = addZone( grindTrigger );
	}
}

addZone( zoneTrigger )
{
	AssertEx( IsDefined(zoneTrigger), "map needs grind game objects" );

	zone 			= SpawnStruct();
	zone.origin 	= zoneTrigger.origin;
	zone.angles		= zoneTrigger.angles;
	zone.trigger 	= zoneTrigger;
	zone.ownerTeam	= "neutral";
	
	traceStart 		= zone.origin + (0,0,32);
	traceEnd 		= zone.origin + (0,0,-32);
	trace 			= bulletTrace( traceStart, traceEnd, false, undefined );
	
	zone.origin		= trace["position"];	
	zone.upangles 	= vectorToAngles( trace["normal"] );
	zone.forward 	= anglesToForward( zone.upangles );
	zone.right 		= anglesToRight( zone.upangles );	
	
	zone.visuals[0] = spawn( "script_model", zone.origin );
	zone.visuals[0].angles = zone.angles;
	zone.visuals[0] SetModel( game["flagmodels"]["neutral"] );

	return zone;
}

runZones()
{	
	foreach( zone in level.zoneList )
	{
		level thread startZone( zone, zone.trigger.script_label );
	}
}

startZone( zone, hudIcon )
{
	level thread runZoneFX( zone );
	level thread runZoneStatus( zone, hudIcon );	
	level thread runZoneThink( zone );	
}

runZoneFX( zone )
{
	gameFlagWait( "prematch_done" );
	
	zoneFX = spawnFx( level._effect["portal_fx_green"], zone.origin, zone.forward, zone.upangles );
	triggerFx( zoneFX );
}

runZoneStatus( zone, hudIcon )
{
	offset = (0,0,100);
	
	zone.objId_axis = maps\mp\gametypes\_gameobjects::getNextObjID();
	objective_add( zone.objId_axis, "active", zone.origin + offset, "waypoint_target_" + hudIcon );
	Objective_Team( zone.objId_axis, "axis" );
	
	zone.objId_allies = maps\mp\gametypes\_gameobjects::getNextObjID();
	objective_add( zone.objId_allies, "active", zone.origin + offset, "waypoint_target_" + hudIcon );
	Objective_Team( zone.objId_allies, "allies" );
	
	while( true )
	{
		ownerTeam = "neutral";
		
		foreach( player in level.players )
		{
			if( player.team == ownerTeam )
			{
				continue;
			}
			
			if( isInZone( player, zone ) )
			{
				if( ownerTeam == "neutral" )
				{
					ownerTeam = player.team;
					continue;
				}
		
				ownerTeam = "contested";
				break;
			}
		}
		zone.ownerTeam = ownerTeam;
		
		switch(ownerTeam)
		{
			case "neutral":
				zone.grind_headIcon_allies = zone maps\mp\_entityheadIcons::setHeadIcon( "allies", "waypoint_captureneutral_" + hudIcon, offset, 4, 4, undefined, undefined, undefined, true, undefined, false );
				zone.grind_headIcon_axis = zone maps\mp\_entityheadIcons::setHeadIcon( "axis", "waypoint_captureneutral_" + hudIcon, offset, 4, 4, undefined, undefined, undefined, true, undefined, false );
				Objective_Icon( zone.objId_allies, "waypoint_captureneutral_" + hudIcon );
				Objective_Icon( zone.objId_axis, "waypoint_captureneutral_" + hudIcon );
				break;
			case "contested":
				zone.grind_headIcon_allies = zone maps\mp\_entityheadIcons::setHeadIcon( "allies", "waypoint_contested_" + hudIcon, offset, 4, 4, undefined, undefined, undefined, true, undefined, false );
				zone.grind_headIcon_axis = zone maps\mp\_entityheadIcons::setHeadIcon( "axis", "waypoint_contested_" + hudIcon, offset, 4, 4, undefined, undefined, undefined, true, undefined, false );
				Objective_Icon( zone.objId_allies, "waypoint_contested_" + hudIcon );
				Objective_Icon( zone.objId_axis, "waypoint_contested_" + hudIcon );
				break;
			case "axis":
				zone.grind_headIcon_allies = zone maps\mp\_entityheadIcons::setHeadIcon( "allies", "waypoint_target_" + hudIcon, offset, 4, 4, undefined, undefined, undefined, true, undefined, false );
				zone.grind_headIcon_axis = zone maps\mp\_entityheadIcons::setHeadIcon( "axis", "waypoint_defend_" + hudIcon, offset, 4, 4, undefined, undefined, undefined, true, undefined, false );
				Objective_Icon( zone.objId_allies, "waypoint_target_" + hudIcon );
				Objective_Icon( zone.objId_axis, "waypoint_defend_" + hudIcon );
				break;
			case "allies":
				zone.grind_headIcon_allies = zone maps\mp\_entityheadIcons::setHeadIcon( "allies", "waypoint_defend_" + hudIcon, offset, 4, 4, undefined, undefined, undefined, true, undefined, false );
				zone.grind_headIcon_axis = zone maps\mp\_entityheadIcons::setHeadIcon( "axis", "waypoint_target_" + hudIcon, offset, 4, 4, undefined, undefined, undefined, true, undefined, false );
				Objective_Icon( zone.objId_allies, "waypoint_defend_" + hudIcon );
				Objective_Icon( zone.objId_axis, "waypoint_target_" + hudIcon );
				break;
		}
		
		waitframe();
	}
}


isInZone( player, zone )
{
	if( isReallyAlive(player) && (player IsTouching(zone.trigger)) )
	{
		return true;
	}

	return false;
}


runZoneThink( zone )
{	
	level endon( "game_ended" );
	
	while( true )
	{
		zone.trigger waittill( "trigger", player );
			
		if( IsAgent(player) )
			continue;
		
		if( player.isScoring )
			continue;
		
		player.isScoring = true;
		
		level thread processScoring( player, zone ); 
	}
}


processScoring( player, zone )
{
	while( player.tagsCarried && isInZone( player, zone) )
	{
		player.tagsCarried--;
		player.game_extrainfo = player.tagsCarried;
		player.tagsText setValue( player.tagsCarried );
		maps\mp\gametypes\_gamescore::giveTeamScoreForObjective( player.team, 1 );	
		wait(2);
	}
	
	player.isScoring = false;
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
	spawnteam = self.pers["team"];
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
		spawnPoint = maps\mp\gametypes\_spawnscoring::getSpawnpoint_NearTeam( spawnPoints );
	}
	
	return spawnPoint;
}


onTimeLimit()
{
	level.finalKillCam_winner = "none";
	if ( game["status"] == "overtime" )
	{
		winner = "forfeit";
	}
	else if ( game["teamScores"]["allies"] == game["teamScores"]["axis"] )
	{
		winner = "overtime";
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


onNormalDeath( victim, attacker, lifeId )
{
	level thread dropTags( victim, attacker );

	if ( game["state"] == "postgame" && game["teamScores"][attacker.team] > game["teamScores"][level.otherTeam[attacker.team]] )
		attacker.finalKill = true;
}


dropTags( victim, attacker )
{
	if( IsAgent(victim) )
		return;
	
	dropNumber = 1;
	radomDropLocation = false;
		
	if( IsDefined(victim.attackerData) && (victim.attackerData.size > 0) )
	{
		if( IsPlayer(attacker) && IsDefined(attacker.guid) && IsDefined(victim.attackerData[attacker.guid]) )
		{
			attackerData = victim.attackerData[attacker.guid];
			if( IsDefined(attackerData.attackerEnt) && (attackerData.attackerEnt == attacker) )
			{
				if( IsDefined(attackerData.sMeansOfDeath) && (attackerData.sMeansOfDeath == "MOD_MELEE") )
				{
					dropNumber = int( min( 10, victim.tagsCarried ) );
					radomDropLocation = true;
					
					victim PlayLocalSound( "mugger_got_mugged" );
					playSoundAtPos( victim.origin, "mugger_mugging" );
				}
			}
		}
	}
		
	counter = 0;
	
	while( counter < dropNumber )
	{
			
		newTag = spawnTag( victim.origin, radomDropLocation );
		level thread monitorTagUse( newTag );
		counter++;
	}
	
	playSoundAtPos( victim.origin, "mp_killconfirm_tags_drop" );
	
	victim.tagsCarried = victim.tagsCarried - dropNumber;
	victim.tagsCarried = int( max( 1, victim.tagsCarried ) );
	victim.game_extrainfo = victim.tagsCarried;
	victim.tagsText setValue( victim.tagsCarried );
}