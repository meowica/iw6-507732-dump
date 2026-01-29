#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;
#include maps\mp\agents\_agent_utility;

/*
	Mugger
	Objective: 	Score points by eliminating players.
				Score bonus points for picking up dogtags from downed enemies.
				Drop dogtags when meleed.
				"Bank" your tags every 10 tags. (Banked tags are not dropped)
	Map ends:	When one player reaches the score limit, or time limit is reached
	Respawning:	No wait

	Level requirements
	------------------
		Spawnpoints:
			classname		mp_dm_spawn
			All players spawn from these. The spawnpoint chosen is dependent on the current locations of enemies
			at the time of spawn. Players generally away from enemies.

		Spectator Spawnpoints:
			classname		mp_global_intermission
			Spectators spawn from these and intermission is viewed from these positions.
			At least one is required, any more and they are randomly chosen between.
*/

/*
 * 
 * TODO:
 * * Custom VO?
 * * Obit shows how many tags someone was mugged for?  Example: Killer *knife* Loser (9)
 * * Maybe MOAB mugs everyone at once?
 * * Mugger Leaderboard?
 * * Decide which playlist group it goes in, map sizes and map rotations, etc.
 * ! Only allow 50 tags max - remove oldest if hit limit.  Spawn them all at start and move them around like it does for client tags.
 * * get throwing knife kill percentage working
 * * shotgun drops 2 tags?
 * * fix lobby summary scoreboard to list TAGS instead of ASSISTS...
 * 
 */

compile_me()
{
}

main()
{
	if(getdvar("mapname") == "mp_background")
		return;
	
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
		registerTimeLimitDvar( level.gameType, 7 );
		registerScoreLimitDvar( level.gameType, 2500 );
		registerRoundLimitDvar( level.gameType, 1 );
		registerWinLimitDvar( level.gameType, 1 );
		registerNumLivesDvar( level.gameType, 0 );
		registerHalfTimeDvar( level.gameType, 0 );
		
		level.matchRules_damageMultiplier = 0;
		level.matchRules_vampirism = 0;	

		level.mugger_bank_limit = GetDvarInt( "scr_mugger_bank_limit", 10 );
	}

    SetTeamMode( "ffa" );

//	level.objectiveBased = true;
//	level.initGametypeAwards = ::initGametypeAwards;
	level.onPrecacheGameType = ::onPrecacheGameType;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.getSpawnPoint = ::getSpawnPoint;
	level.onNormalDeath = ::onNormalDeath;
	//level.onPlayerKilled = ::onPlayerKilled;
	level.onPlayerScore = ::onPlayerScore;
	level.onTimeLimit = ::onTimeLimit;
	level.onXPEvent = ::onXPEvent;
//	level.updatePlacement = ::updatePlacement;

	level.assists_disabled = true;//no kill-assists tracked - for us, assists means tags banked
	
	if ( level.matchRules_damageMultiplier || level.matchRules_vampirism )
		level.modifyPlayerDamage = maps\mp\gametypes\_damage::gamemodeModifyPlayerDamage;

	//game["dialog"]["gametype"] = "kill_confirmed";
	
	level.mugger_fx["vanish"] = loadFx( "impacts/small_snowhit" );

	level.mugger_fx["smoke"] = loadFx( "smoke/airdrop_flare_mp_effect_now" );
	//level.mugger_fx["flare"] = loadFx( "smoke/signal_smoke_airdrop" );
	level.mugger_targetFXID = loadfx( "misc/ui_flagbase_red" );
	
	level thread onPlayerConnect();
}


initializeMatchRules()
{
	//	set common values
	setCommonRulesFromMatchRulesData();
	
	//	set everything else (private match options, default .cfg file values, and what normally is registered in the 'else' below)
	SetDynamicDvar( "scr_mugger_roundswitch", 0 );
	registerRoundSwitchDvar( "mugger", 0, 0, 9 );
	SetDynamicDvar( "scr_mugger_roundlimit", 1 );
	registerRoundLimitDvar( "mugger", 1 );		
	SetDynamicDvar( "scr_mugger_winlimit", 1 );
	registerWinLimitDvar( "mugger", 1 );			
	SetDynamicDvar( "scr_mugger_halftime", 0 );
	registerHalfTimeDvar( "mugger", 0 );
		
	SetDynamicDvar( "scr_mugger_promode", 0 );	

	level.mugger_bank_limit = GetMatchRulesData( "muggerData", "bankLimit" );
	SetDynamicDvar( "scr_mugger_bank_limit", level.mugger_bank_limit );

	level.mugger_jackpot_limit = GetMatchRulesData( "muggerData", "jackpotLimit" );
	SetDynamicDvar( "scr_mugger_jackpot_limit", level.mugger_jackpot_limit );

	level.mugger_throwing_knife_mug_frac = GetMatchRulesData( "muggerData", "throwKnifeFrac" );
	SetDynamicDvar( "scr_mugger_throwing_knife_mug_frac", level.mugger_throwing_knife_mug_frac );
}


onPrecacheGameType()
{
//	precachemodel( "prop_dogtags_friend" );
	precachemodel( "prop_dogtags_foe_animated" );
	precacheModel( "weapon_us_smoke_grenade_burnt2" );

	precacheMpAnim( "mp_dogtag_spin" );

	precacheshader( "waypoint_dogtags2" );
	precacheshader( "waypoint_dogtag_pile" );
	precacheshader( "waypoint_jackpot" );
	precacheshader( "hud_tagcount" );

	PrecacheSound( "mugger_mugging" );
	PrecacheSound( "mugger_mega_mugging" );
	PrecacheSound( "mugger_you_mugged" );
	PrecacheSound( "mugger_got_mugged" );
	PrecacheSound( "mugger_mega_drop" );
	PrecacheSound( "mugger_muggernaut" );
	PrecacheSound( "mugger_tags_banked" );
	//PrecacheSound( "mugger_jackpot_vo" );
	
	PreCacheString( &"MPUI_MUGGER_JACKPOT" );
}


onStartGameType()
{
	setClientNameMode("auto_change");

	setObjectiveText( "allies", &"OBJECTIVES_MUGGER" );
	setObjectiveText( "axis", &"OBJECTIVES_MUGGER" );
	
	if ( level.splitscreen )
	{
		setObjectiveScoreText( "allies", &"OBJECTIVES_MUGGER" );
		setObjectiveScoreText( "axis", &"OBJECTIVES_MUGGER" );
	}
	else
	{
		setObjectiveScoreText( "allies", &"OBJECTIVES_MUGGER_SCORE" );
		setObjectiveScoreText( "axis", &"OBJECTIVES_MUGGER_SCORE" );
	}
	setObjectiveHintText( "allies", &"OBJECTIVES_MUGGER_HINT" );
	setObjectiveHintText( "axis", &"OBJECTIVES_MUGGER_HINT" );
			
	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );	
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_dm_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_dm_spawn" );
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );	
	
	maps\mp\gametypes\_rank::registerScoreInfo( "kill", 50 );
//	maps\mp\gametypes\_rank::registerScoreInfo( "kill", 25 );
//	maps\mp\gametypes\_rank::registerScoreInfo( "headshot", 10 );
	maps\mp\gametypes\_rank::registerScoreInfo( "assist", 0 );
//	maps\mp\gametypes\_rank::registerScoreInfo( "suicide", 0 );
	//maps\mp\gametypes\_rank::registerScoreInfo( "suicide", -50 );
	//FIXME: I can't customize this!  Right now players lose 0 for suicide
	//maps\mp\gametypes\_tweakables::settweakablevalue( "game", "suicidepointloss", 50 );
//	maps\mp\gametypes\_rank::registerScoreInfo( "teamkill", 0 );
//	maps\mp\gametypes\_rank::registerScoreInfo( "execution", 25 );
//	maps\mp\gametypes\_rank::registerScoreInfo( "avenger", 10 );
//	maps\mp\gametypes\_rank::registerScoreInfo( "defender", 10 );
//	maps\mp\gametypes\_rank::registerScoreInfo( "posthumous", 5 );
//	maps\mp\gametypes\_rank::registerScoreInfo( "revenge", 10 );
//	maps\mp\gametypes\_rank::registerScoreInfo( "double", 10 );
//	maps\mp\gametypes\_rank::registerScoreInfo( "triple", 15 );
//	maps\mp\gametypes\_rank::registerScoreInfo( "multi", 25 );
//	maps\mp\gametypes\_rank::registerScoreInfo( "buzzkill", 25 );
//	maps\mp\gametypes\_rank::registerScoreInfo( "firstblood", 25 );
//	maps\mp\gametypes\_rank::registerScoreInfo( "comeback", 25 );
//	maps\mp\gametypes\_rank::registerScoreInfo( "longshot", 10 );
//	maps\mp\gametypes\_rank::registerScoreInfo( "assistedsuicide", 25 );
//	maps\mp\gametypes\_rank::registerScoreInfo( "knifethrow", 25 );
	
	maps\mp\gametypes\_rank::registerScoreInfo( "kill_confirmed", 50 );
	maps\mp\gametypes\_rank::registerScoreInfo( "kill_denied", 50 );
	maps\mp\gametypes\_rank::registerScoreInfo( "tags_retrieved", 50 );
	
	maps\mp\gametypes\_rank::registerScoreInfo( "muggernaut", 250 );
	
	level.dogtags = [];
	
	allowed[0] = level.gameType;
	allowed[1] = "dm";
	
	maps\mp\gametypes\_gameobjects::main(allowed);	

	//ensure the defaults are set since that appears to be totally broken - often starting X-Box Live matches with a 0 scorelimit
	level.mugger_timelimit = GetDvarInt( "scr_mugger_timelimit", 7 );
	SetDynamicDvar( "scr_mugger_timeLimit", level.mugger_timelimit );
	registerTimeLimitDvar( "mugger", level.mugger_timelimit );

	level.mugger_scorelimit = GetDvarInt( "scr_mugger_scorelimit", 2500 );
	if ( level.mugger_scorelimit == 0 )
	{//WTF!!!!!  Native code is ACTUALLY setting this dvar to 0!
		level.mugger_scorelimit = 2500;
	}
	SetDynamicDvar( "scr_mugger_scoreLimit", level.mugger_scorelimit );
	registerScoreLimitDvar( "mugger", level.mugger_scorelimit );
	
	level.mugger_bank_limit = GetDvarInt( "scr_mugger_bank_limit", 10 );
	level.mugger_muggernaut_window = GetDvarInt( "scr_mugger_muggernaut_window", 3000 );//5000 );
	level.mugger_muggernaut_muggings_needed = GetDvarInt( "scr_mugger_muggernaut_muggings_needed", 3 );
	level.mugger_min_spawn_dist_sq = squared(GetDvarFloat( "mugger_min_spawn_dist", 350 ));
 	level.mugger_jackpot_limit = GetDvarInt( "scr_mugger_jackpot_limit", 0 );
	level.mugger_jackpot_wait_sec = GetDvarFloat( "scr_mugger_jackpot_wait_sec", 10 );
	level.mugger_throwing_knife_mug_frac = GetDvarInt( "scr_mugger_throwing_knife_mug_frac", 1.0 );

//	mugger_jackpot_hud_create();
		
	level mugger_init_tags();
	
	level thread mugger_monitor_tank_pickups();
	level thread mugger_monitor_remote_uav_pickups();
	//TODO: Let AI buddy pick up tags for you too?  They go to him and to you when he dies?  Or they go directly to you?
	
	createZones();

	level.jackpot_zone = spawn( "script_model", (0,0,0) );
	level.jackpot_zone.origin = (0,0,0);
	level.jackpot_zone.angles = ( 90, 0, 0 );
	level.jackpot_zone setModel( "weapon_us_smoke_grenade_burnt2" );
	level.jackpot_zone hide();
	level.jackpot_zone.mugger_fx_playing = false;

	level thread mugger_jackpot_watch();
	
	//level thread mugger_endgame_setTotalTags();
}


createZones()
{
	level.grnd_dropZones = [];
	
	//	future way
	dropZones = getEntArray( "grnd_dropZone", "targetname" );
	if ( isDefined( dropZones ) && dropZones.size )
	{
		i=0;
		foreach ( dropZone in dropZones )
		{
			level.grnd_dropZones[level.script][i] = dropZone.origin;
			i++;
		}
	}
}

onPlayerConnect()
{
	while ( true )
	{
		level waittill( "connected", player );
		player.tags_carried = 0;
		player.total_tags_banked = 0;
		player.assists = player.total_tags_banked;//player.tags_carried;
		player.pers["assists"] = player.total_tags_banked;//player.tags_carried;
		player.game_extrainfo = player.tags_carried;
//		player UpdateGameExtraInfoToAll();
		player.muggings = [];
	
		player.dogtagsIcon = player createIcon( "hud_tagcount", 48, 48 );//32
		player.dogtagsIcon setPoint( "TOP LEFT", "TOP LEFT", 200, 0 );//( "BOTTOM LEFT", "BOTTOM LEFT", 0, -72 );
		player.dogtagsIcon.alpha = 1;
		player.dogtagsIcon.hideWhenInMenu = true;
		player.dogtagsIcon.archived = true;
		level thread hideHudElementOnGameEnd( player.dogtagsIcon );
	
		player.dogtagsText = player createFontString( "bigfixed", 1.0 );//"small", 1.6 );	
		player.dogtagsText setParent( player.dogtagsIcon );
		player.dogtagsText setPoint( "CENTER", "CENTER", -24 );//-16 );
		player.dogtagsText setValue( player.tags_carried );
		player.dogtagsText.alpha = 1;
		player.dogtagsText.color = (1,1,0.5);
		player.dogtagsText.glowAlpha = 1;
		player.dogtagsText.sort = 1;
		player.dogtagsText.hideWhenInMenu = true;
		player.dogtagsText.archived = true;
		player.dogtagsText maps\mp\gametypes\_hud::fontPulseInit( 3.0 );
		level thread hideHudElementOnGameEnd( player.dogtagsText );
	}
}

onSpawnPlayer()
{
	self.muggings = [];
	self thread waitReplaySmokeFxForNewPlayer();
}

hideHudElementOnGameEnd( hudElement )
{
	level waittill( "game_ended" );
	
	if ( isDefined( hudElement ) )
		hudElement.alpha = 0;
}

getSpawnPoint()
{
	spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.pers["team"] );
	/*
 	validSpawnpoints = [];
	foreach( sp in spawnPoints )
	{
		too_close = false;
		foreach( player in level.players )
		{
			if ( IsDefined( player ) && IsAlive( player ) )
			{
				if ( DistanceSquared( player.origin, sp.origin ) < level.mugger_min_spawn_dist_sq )
				{
					too_close = true;
					break;
				}
			}
		}
		if ( !too_close )
		{
			validSpawnpoints[validSpawnpoints.size] = sp;
		}
	}

	spawnPoint = undefined;
	if ( validSpawnpoints.size < 1 )
	{//none, use whole list
		spawnPoint = maps\mp\gametypes\_spawnscoring::getSpawnpoint_FreeForAll( spawnPoints );
	}
	else if ( validSpawnpoints.size > 1 )
	{//filtered down, but more than one, use the usual logic on the remainder
		spawnPoint = maps\mp\gametypes\_spawnscoring::getSpawnpoint_FreeForAll( validSpawnpoints );
	}
	else
	{//only one
		spawnPoint = validSpawnpoints[0];
	}
	*/
	spawnPoint = maps\mp\gametypes\_spawnscoring::getSpawnpoint_FreeForAll( spawnPoints );

	return spawnPoint;	return spawnPoint;
}

onXPEvent( event )
{
	if ( IsDefined( event ) && event == "suicide" )
	{
		level thread spawnDogTags( self, self );
	}
	self maps\mp\gametypes\_globallogic::onXPEvent( event );
}

onNormalDeath( victim, attacker, lifeId )
{
	level thread spawnDogTags( victim, attacker );

	if ( game["state"] == "postgame" && game["teamScores"][attacker.team] > game["teamScores"][level.otherTeam[attacker.team]] )
		attacker.finalKill = true;
}

mugger_init_tags()
{
	level.mugger_max_extra_tags = GetDvarInt( "scr_mugger_max_extra_tags", 50 );
	
	level.mugger_extra_tags = [];
}

spawnDogTags( victim, attacker )
{
	//if attacker is an agent, owner of the agent gets credit for the attack
	if ( IsAgent( attacker ) )
	{
		attacker = attacker.owner;
	}

	num_extra_tags = 0;
	was_a_stabbing = false;
	if ( IsDefined( attacker ) )
	{
		if ( victim == attacker )
		{//suicided - drop your tags
			if ( victim.tags_carried > 0 )
			{
				num_extra_tags = victim.tags_carried;
				victim.tags_carried = 0;
				//victim.assists = victim.tags_carried;
				//victim.pers["assists"] = victim.tags_carried;
				victim.game_extrainfo = 0;
//				victim UpdateGameExtraInfoToAll();
				victim.dogtagsText setValue( victim.tags_carried );
				victim.dogtagsText thread maps\mp\gametypes\_hud::fontPulse( victim );
				victim thread maps\mp\gametypes\_hud_message::SplashNotifyUrgent( "mugger_suicide", num_extra_tags );
			}
		}
		else if ( IsDefined( victim.attackerData ) && victim.attackerData.size > 0 )
		{
			if ( IsPlayer( attacker ) && IsDefined( victim.attackerData ) && IsDefined( attacker.guid ) && IsDefined( victim.attackerData[attacker.guid] ) )
			{
				attData = victim.attackerData[attacker.guid];
				if ( IsDefined( attData ) && IsDefined( attData.attackerEnt ) && attData.attackerEnt == attacker )
				{
					if ( IsDefined( attData.sMeansOfDeath ) && (attData.sMeansOfDeath == "MOD_MELEE" || (attData.weapon == "throwingknife_mp" && level.mugger_throwing_knife_mug_frac > 0.0) ) )
					{
						was_a_stabbing = true;
						if ( victim.tags_carried > 0 )
						{
							num_extra_tags = victim.tags_carried;
							if ( attData.weapon == "throwingknife_mp" && level.mugger_throwing_knife_mug_frac < 1.0 )
							{//knife doesn't take ALL tags
								num_extra_tags = int(ceil(victim.tags_carried*level.mugger_throwing_knife_mug_frac));//ceil so we guarantee at least 1
							}
							victim.tags_carried -= num_extra_tags;
							//victim.assists = victim.tags_carried;
							//victim.pers["assists"] = victim.tags_carried;
							victim.game_extrainfo = victim.tags_carried;
//							victim UpdateGameExtraInfoToAll();
							victim.dogtagsText setValue( victim.tags_carried );
							victim.dogtagsText thread maps\mp\gametypes\_hud::fontPulse( victim );
							victim thread maps\mp\gametypes\_hud_message::SplashNotifyUrgent( "callout_mugged", num_extra_tags );
							victim PlayLocalSound( "mugger_got_mugged" );
							playSoundAtPos( victim.origin, "mugger_mugging" );
							
							attacker thread maps\mp\gametypes\_hud_message::SplashNotifyUrgent( "callout_mugger", num_extra_tags );
							if ( attData.weapon == "throwingknife_mp" )
								attacker PlayLocalSound( "mugger_you_mugged" );
							//playSoundAtPos( victim.origin, "mugger_you_mugged" );
							
							//see if the mugger got 3 muggings in 3 seconds - that's a MUGGERNAUT!
							//attacker.muggings[attacker.muggings.size] = GetTime();
							//attacker thread mugger_check_muggernaut();
						}
						//see if the attacker got 3 stabbing in 3 seconds - that's a MUGGERNAUT!
						attacker.muggings[attacker.muggings.size] = GetTime();
						//FIXME: MOAB is triggering muggernaut?!
						attacker thread mugger_check_muggernaut();
					}
				}
			}
		}
	}
	
	//if victim is an agent - they carry no tags, so you always only get one tag
	if ( IsAgent( victim ) )
	{
		pos = victim.origin + (0,0,14);
		playSoundAtPos( pos, "mp_killconfirm_tags_drop" );
	
		level notify( "mugger_jackpot_increment" );

		dropped_dogtag = mugger_tag_temp_spawn( victim.origin, 40, 160 );

		dropped_dogtag.victim = victim.owner;
		
		if ( IsDefined( attacker ) && victim != attacker )
		{
			dropped_dogtag.attacker = attacker;
		}
		else
		{
			dropped_dogtag.attacker = undefined;
		}
		return;
	}
	else if ( isDefined( level.dogtags[victim.guid] ) )
	{
		PlayFx( level.mugger_fx["vanish"], level.dogtags[victim.guid].curOrigin );
		level.dogtags[victim.guid] notify( "reset" );
		
		//if ( isDefined( level.dogtags[victim.guid].attacker ) /*&& level.dogtags[victim.guid].attacker != attacker*/ && isAlive( level.dogtags[victim.guid].attacker ) )
			//level.dogtags[victim.guid].attacker thread maps\mp\gametypes\_rank::xpEventPopup( &"SPLASHES_UNCONFIRMED_KILL" );		
	}
	else
	{
		visuals[0] = spawn( "script_model", (0,0,0) );
		visuals[0] setModel( "prop_dogtags_foe_animated" );
		
		trigger = spawn( "trigger_radius", (0,0,0), 0, 32, 32 );
		trigger.targetname = "trigger_dogtag";
		trigger hide();
		
		level.dogtags[victim.guid] = maps\mp\gametypes\_gameobjects::createUseObject( "any", trigger, visuals, (0,0,16) );
		
		//	we don't need these
		//NOTE: not created anymore
		//_objective_delete( level.dogtags[victim.guid].objIDAllies );
		//_objective_delete( level.dogtags[victim.guid].objIDAxis );		
		maps\mp\gametypes\_objpoints::deleteObjPoint( level.dogtags[victim.guid].objPoints["allies"] );
		maps\mp\gametypes\_objpoints::deleteObjPoint( level.dogtags[victim.guid].objPoints["axis"] );		
		
		level.dogtags[victim.guid] maps\mp\gametypes\_gameobjects::setUseTime( 0 );
		level.dogtags[victim.guid].onUse = ::onUse;
		trigger.dogtag = level.dogtags[victim.guid];
		level.dogtags[victim.guid].victim = victim;
		//level.dogtags[victim.guid].victimTeam = victim.pers["team"];
		
		level.dogtags[victim.guid].objId = maps\mp\gametypes\_gameobjects::getNextObjID();	
		objective_add( level.dogtags[victim.guid].objId, "invisible", (0,0,0) );
		objective_icon( level.dogtags[victim.guid].objId, "waypoint_dogtags2" );	
		
//		level.dogtags[victim.guid].visuals[0] BobSpin( true );
		level.dogtags[victim.guid].visuals[0] ScriptModelPlayAnim( "mp_dogtag_spin" );

		level thread clearOnVictimDisconnect( victim );
		//victim thread tagTeamUpdater( level.dogtags[victim.guid] );
	}	
	
	pos = victim.origin + (0,0,14);
	level.dogtags[victim.guid].curOrigin = pos;
	level.dogtags[victim.guid].trigger.origin = pos;
	level.dogtags[victim.guid].visuals[0].origin = pos;
	
	level.dogtags[victim.guid] maps\mp\gametypes\_gameobjects::allowUse( "any" );	
			
	level.dogtags[victim.guid].visuals[0] show();
	
	if ( IsDefined( attacker ) && victim != attacker )
	{
		level.dogtags[victim.guid].attacker = attacker;
	}
	else
	{
		level.dogtags[victim.guid].attacker = undefined;
	}
	level.dogtags[victim.guid] thread timeOut();

	if ( num_extra_tags < 5 )
	{//Only show a single tag on the radar
		objective_position( level.dogtags[victim.guid].objId, pos );
		objective_state( level.dogtags[victim.guid].objId, "active" );
	//	objective_player( level.dogtags[victim.guid].objId, attacker getEntityNumber() );		
	}
	else
	{
		mugger_tag_pile_notify( pos, "mugger_megadrop", num_extra_tags, victim, attacker );
	}
	
	playSoundAtPos( pos, "mp_killconfirm_tags_drop" );
	
	//level.dogtags[victim.guid] thread bounce();
	level.dogtags[victim.guid].temp_tag = false;

	//every stabbing raises the jackpot - whether or not a tag dropped
	if ( num_extra_tags == 0 )//was_a_stabbing )
		level notify( "mugger_jackpot_increment" );

	for( i = 0; i < num_extra_tags; i++ )
	{
		dropped_dogtag = mugger_tag_temp_spawn( victim.origin, 40, 160 );

		dropped_dogtag.victim = victim;
		
		if ( IsDefined( attacker ) && victim != attacker )
		{
			dropped_dogtag.attacker = attacker;
		}
		else
		{
			dropped_dogtag.attacker = undefined;
		}
	}
}

mugger_tag_pickup_wait()
{
	level endon ( "game_ended" );
	self endon ( "reset" );
	self endon ( "reused" );
	self endon ( "deleted" );
	
	while ( true )
	{
		self.trigger waittill ( "trigger", player );
		if ( !isReallyAlive( player ) )
			continue;
			
		if ( player isUsingRemote() || isDefined( player.spawningAfterRemoteDeath ) )
			continue;
			
		if ( IsDefined( player.classname ) && player.classname == "script_vehicle" )
			continue;

		self thread onUse( player );
		return;
	}
}

mugger_add_extra_tag( index )
{
	visuals[0] = spawn( "script_model", (0,0,0) );
	visuals[0] setModel( "prop_dogtags_foe_animated" );
	
	trigger = spawn( "trigger_radius", (0,0,0), 0, 32, 32 );
	trigger.targetname = "trigger_dogtag";
	trigger hide();
	
	level.mugger_extra_tags[index] = spawnStruct();
	new_extra_tag = level.mugger_extra_tags[index];
	
	new_extra_tag.type = "useObject";
	new_extra_tag.curOrigin = trigger.origin;
	new_extra_tag.entNum = trigger getEntityNumber();
	
	// associated trigger
	new_extra_tag.trigger = trigger;
	new_extra_tag.triggerType = "proximity";
	new_extra_tag maps\mp\gametypes\_gameobjects::allowUse( "any" );
	
	visuals[0].baseOrigin = visuals[0].origin;
	new_extra_tag.visuals = visuals;
	new_extra_tag.offset3d = (0,0,16);
	
	new_extra_tag.temp_tag = true;
	new_extra_tag.last_used_time = 0;
	
//	new_extra_tag.visuals[0] BobSpin( true );
	new_extra_tag.visuals[0] ScriptModelPlayAnim( "mp_dogtag_spin" );
	
	new_extra_tag thread mugger_tag_pickup_wait();
	
	return new_extra_tag;
}

mugger_first_unused_or_oldest_extra_tag()
{
	oldest_tag = undefined;
	oldest_time = -1;
	foreach( extra_tag in level.mugger_extra_tags )
	{
		if ( extra_tag.interactTeam == "none" )
		{
			extra_tag.last_used_time = GetTime();
			extra_tag.visuals[0] show();
			return extra_tag;
		}
		if ( !IsDefined( oldest_tag ) || extra_tag.last_used_time < oldest_time )
		{
			oldest_time = extra_tag.last_used_time;
			oldest_tag = extra_tag;
		}
	}
	
	//all spawned tags are being used, is there room to spawn a new one?
	if ( level.mugger_extra_tags.size < level.mugger_max_extra_tags )
	{
		new_tag = mugger_add_extra_tag( level.mugger_extra_tags.size );
		if ( IsDefined( new_tag ) )
		{
			new_tag.last_used_time = GetTime();
			return new_tag;
		}
	}
	
/#
	LogPrint( "Warning: mugger mode ran out of tags, recycling oldest\n" );
#/
	//if got this far, ALL extra tags are spawned and currently in use, so just reuse the oldest one
	oldest_tag.last_used_time = GetTime();
	oldest_tag notify( "reused" );
	PlayFx( level.mugger_fx["vanish"], oldest_tag.curOrigin );
	return oldest_tag;
}

mugger_tag_temp_spawn( org, distMin, distMax )
{
	dropped_dogtag = mugger_first_unused_or_oldest_extra_tag();
	
	startpos = org + (0,0,14);
	random_angle = (0,RandomFloat(360),0);
	random_dir = AnglesToForward(random_angle);
	
	/*if ( 0 )
	{//fake physics - looks awkward, expensive, tend to lose some tags if don't do expensive traces
		dropped_dogtag.curOrigin = startpos;
		dropped_dogtag.visuals[0].origin = startpos;

		random_force = random_dir * RandomFloatRange( 150, 450 );
		random_force += (0,0,250);
		dropped_dogtag.visuals[0] MoveGravity( random_force, Length(random_force)/1000.0 );

		dropped_dogtag.trigger.origin = startpos;
		dropped_dogtag.trigger EnableLinkTo();
		dropped_dogtag.trigger LinkTo( dropped_dogtag.visuals[0] );

		dropped_dogtag maps\mp\gametypes\_gameobjects::allowUse( "none" );
		dropped_dogtag delayThread( 1, maps\mp\gametypes\_gameobjects::allowUse, "any" );

		dropped_dogtag thread bounce_physics_fake();
		dropped_dogtag thread spin();
	}
	else if ( 0 )
	{//real physics - looks great, but tags fall over
		dropped_dogtag.curOrigin = startpos;
		dropped_dogtag.visuals[0].origin = startpos;

		random_force = random_dir * RandomFloatRange( 100, 400 );
		random_force += (0,0,100);
		dropped_dogtag.visuals[0] PhysicsLaunchServer(startpos, random_force);

		dropped_dogtag.trigger.origin = startpos;
		dropped_dogtag.trigger EnableLinkTo();
		dropped_dogtag.trigger LinkTo( dropped_dogtag.visuals[0] );

		dropped_dogtag maps\mp\gametypes\_gameobjects::allowUse( "none" );
		dropped_dogtag delayThread( 1, maps\mp\gametypes\_gameobjects::allowUse, "any" );

		//dropped_dogtag thread bounce_physics();
		dropped_dogtag thread spin();
	}
	else*/
	{//teleport - most reliable, least flashy
		random_dist = RandomFloatRange( 40, 160 );//(20, 150);
		testpos = startpos + (random_dist * random_dir);
		//trace up a bit, too - for slopes, stairs, etc.
		testpos = testpos + (0,0,40);
		pos = PlayerPhysicsTrace( startpos, testpos );
		//now trace back down so they're less likely to be way up in the air
		startpos = pos;
		testpos = startpos + (0,0,-100);
		pos = PlayerPhysicsTrace( startpos, testpos );
		//if the trace actually hit something (didn't get all the way to testpos[2]), then raise it back up
		if ( pos[2] != testpos[2] )
		{
			pos = pos + (0,0,14);
		}

		dropped_dogtag.curOrigin = pos;
		dropped_dogtag.trigger.origin = pos;
		dropped_dogtag.visuals[0].origin = pos;

		dropped_dogtag maps\mp\gametypes\_gameobjects::allowUse( "any" );
	}
	
	dropped_dogtag thread mugger_tag_pickup_wait();
	dropped_dogtag thread timeOut();// victim );
	
	return dropped_dogtag;
}

mugger_tag_pile_notify( pos, event, num_tags, victim, attacker )
{
	//show a tag pile on the radar!
	dogtagPileObjId = maps\mp\gametypes\_gameobjects::getNextObjID();	
	objective_add( dogtagPileObjId, "active", pos );
	objective_icon( dogtagPileObjId, "waypoint_dogtag_pile" );	//FIXME: need dogtag pile art
	//FIXME: fadeout first?
	level delayThread( 5, ::mugger_pile_icon_remove, dogtagPileObjId );
	if ( num_tags >= 10 )
	{
		level.mugger_last_mega_drop = GetTime();
		level.mugger_jackpot_num_tags = 0;//start over
		//call it out for everyone and start the feeding frenzy!
		foreach( player in level.players )
		{
			player PlaySoundToPlayer( "mp_defcon_one", player );
			
			if ( IsDefined( victim ) && player == victim )
				continue;
			
			if ( IsDefined( attacker ) && player == attacker )
				continue;
			
			player thread maps\mp\gametypes\_hud_message::SplashNotify( event, num_tags );
		}
		//3D icon that everyone can see
		dogtagPileIcon = newHudElem();
		dogtagPileIcon setShader( "waypoint_dogtag_pile", 10, 10 );
		dogtagPileIcon SetWayPoint( false, true, false, false );
		dogtagPileIcon.x = pos[0];
		dogtagPileIcon.y = pos[1];
		dogtagPileIcon.z = pos[2] + 32;
		dogtagPileIcon.alpha = 1;
		dogtagPileIcon FadeOverTime( 5 );
		dogtagPileIcon.alpha = 0;
		dogtagPileIcon delayThread( 5, ::hudElemDestroy );
	}
}

/*
onPlayerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration, killId )
{
	if ( IsDefined( sWeapon ) && sWeapon == "nuke_mp" )
	{//drop all tags?
	}
}
*/

hudElemDestroy()
{
	if ( IsDefined( self ) )
	{
		self destroy();
	}
}

mugger_monitor_tank_pickups()
{
	//FIXME: if the player is dead and still driving, they can bank and not worry about being mugged...
	level endon( "game_ended" );
	while(1)
	{
		remote_tanks = GetEntArray( "remote_tank", "targetname" );
		dogtag_triggers = GetEntArray( "trigger_dogtag", "targetname" );
		foreach( player in level.players )
		{
			if ( isdefined( player.using_remote_tank ) && player.using_remote_tank == true )
			{//player is using a remote tank
				foreach( rtank in remote_tanks )
				{
					if ( IsDefined( rtank ) && IsDefined( rtank.owner ) && rtank.owner == player )
					{//this is their tank
						foreach( trig in dogtag_triggers )
						{
							if ( IsDefined( trig ) && IsDefined( trig.dogtag ) )
							{//this is a dogtag trigger
								if ( IsDefined( trig.dogtag.interactTeam ) && trig.dogtag.interactTeam != "none" )
								{//dogtag can be picked up
									if ( rtank IsTouching( trig ) )
									{//tank is touching the trigger
										trig.dogtag onUse( rtank.owner );
									}
								}
							}
						}
					}
				}
			}
		}
		wait(0.2);
	}
}

mugger_monitor_remote_uav_pickups()
{
	//FIXME: if the player is dead and still driving, they can bank and not worry about being mugged...
	level endon( "game_ended" );
	while(1)
	{
		dogtag_triggers = GetEntArray( "trigger_dogtag", "targetname" );
		foreach( player in level.players )
		{
			if (  IsDefined( player) && IsDefined( player.remoteUAV )  )
			{//this is their tank
				foreach( trig in dogtag_triggers )
				{
					if ( IsDefined( trig ) && IsDefined( trig.dogtag ) )
					{//this is a dogtag trigger
						if ( IsDefined( trig.dogtag.interactTeam ) && trig.dogtag.interactTeam != "none" )
						{//dogtag can be picked up
							if ( player.remoteUAV IsTouching( trig ) )
							{//tank is touching the trigger
								trig.dogtag onUse( player );
							}
						}
					}
				}
			}
		}
		wait(0.2);
	}
}

mugger_check_muggernaut()
{
	level endon( "game_ended" );
	self  endon( "disconnect" );
	
	self  notify( "checking_muggernaut" );
	self  endon( "checking_muggernaut" );
	
	wait( 2 );
	
	if ( self.muggings.size < level.mugger_muggernaut_muggings_needed )
		return;
	
	last_mug_time = self.muggings[self.muggings.size-1];
	mug_time_threshhold = last_mug_time - level.mugger_muggernaut_window;
	muggings_in_threshhold = [];
	foreach( mug_time in self.muggings )
	{
		if ( mug_time >= mug_time_threshhold )
		{
			muggings_in_threshhold[muggings_in_threshhold.size] = mug_time;
		}
	}
	
	if ( muggings_in_threshhold.size >= level.mugger_muggernaut_muggings_needed )
	{
		//give the reward - NOTE: this does not affect your score!  Just XP.
		self thread maps\mp\gametypes\_hud_message::SplashNotifyUrgent( "muggernaut", self.tags_carried );//muggings_in_threshhold.size );
		self thread maps\mp\gametypes\_rank::giveRankXP( "muggernaut" );//TODO: scale by muggings_in_threshhold.size?
		//reward: bank any tags you're currently holding instantly!
		self mugger_bank_tags( true, true );
		//start over
		self.muggings = [];
	}
	else
	{//only remember the ones that were still within the threshhold
		self.muggings = muggings_in_threshhold;
	}
}

mugger_pile_icon_remove( dogtagPileObjId )
{
	objective_delete( dogtagPileObjId );
}

HideFromPlayer( pPlayer )
{
	self hide();

	foreach ( player in level.players )
	{
		if( player != pPlayer )
			self ShowToPlayer( player );
	}
}


onUse( player )
{	
	// If this is a squadmate, give credit to the agent's owner player
	if ( IsDefined(player.owner) )
	{
		player = player.owner;
	}
	
	// mugging tag pickup
	if ( self.temp_tag )
	{
		self.trigger playSound( "mp_killconfirm_tags_deny" );
		
		event = "kill_denied";
		splash = undefined;
	}
	//	killer pickup
	else if ( IsDefined( self.attacker ) && player == self.attacker )
	{
		self.trigger playSound( "mp_killconfirm_tags_pickup" );
		
		event = "kill_confirmed";
		splash = undefined;//&"SPLASHES_KILL_CONFIRMED";
		
		player incPlayerStat( "killsconfirmed", 1 );
		player incPersStat( "confirmed", 1 );
		player maps\mp\gametypes\_persistence::statSetChild( "round", "confirmed", player.pers["confirmed"] );
		
		//	if not us, tell the attacker their kill was confirmed
		if ( self.attacker != player )
			self.attacker thread onPickup( event, splash );
		
		//self.trigger playsoundtoplayer( (game[ "voice" ][ player.team ] + "kill_confirmed") , player);
		
		//player maps\mp\gametypes\_gamescore::giveTeamScoreForObjective( player.pers["team"], 1 );			
	}
	else
	{
		self.trigger playSound( "mp_killconfirm_tags_deny" );
		
		player incPlayerStat( "killsdenied", 1 );
		player incPersStat( "denied", 1 );
		player maps\mp\gametypes\_persistence::statSetChild( "round", "denied", player.pers["denied"] );
		
		//	victim pickup
		if ( self.victim == player )
		{
			event = "tags_retrieved";
			splash = undefined;//&"SPLASHES_TAGS_RETRIEVED";
		}
		//	3rd party pickup
		else
		{
			event = "kill_denied";
			splash = undefined;//&"SPLASHES_KILL_DENIED";	
		}
		
		//	tell the attacker their kill was denied
		/*if ( isDefined( self.attacker ) && !self.temp_tag )
			self.attacker thread maps\mp\gametypes\_rank::xpEventPopup( &"SPLASHES_DENIED_KILL", (1,0.5,0.5) );*/
	}
		
	player thread onPickup( event, splash );
	
	//	do all this at the end now so the location doesn't change before playing the sound on the entity
	self resetTags( true );		
}


onPickup( event, splash )
{
	level endon( "game_ended" );
	self  endon( "disconnect" );
	
	while ( !isDefined( self.pers ) )
		wait( 0.05 );
	
	if ( IsDefined( splash ) )
	{
		self thread maps\mp\gametypes\_rank::xpEventPopup( splash );
	}
	/*if ( event == "tags_retrieved" )
	{
		maps\mp\gametypes\_gamescore::givePlayerScore( event, self, undefined, true );
		self thread maps\mp\gametypes\_rank::giveRankXP( event );	
	}*/

	self thread mugger_delayed_banking();
}

mugger_delayed_banking()
{
	self notify( "banking" );
	self endon( "banking" );
	level endon( "banking_all" );
	
	self.tags_carried++;
	//self.assists = self.tags_carried;
	//self.pers["assists"] = self.tags_carried;
	self.game_extrainfo = self.tags_carried;
//	self UpdateGameExtraInfoToAll();
	self.dogtagsText setValue( self.tags_carried );
	self.dogtagsText thread maps\mp\gametypes\_hud::fontPulse( self );
	
	wait( 1.5 );
	tags_left = level.mugger_bank_limit-self.tags_carried;
	if ( tags_left > 0 && tags_left <= 5 )
	{
		progress_sound = undefined;
		switch ( tags_left )
		{
			case 1:
				progress_sound = "mugger_1more";
				break;
			case 2:
				progress_sound = "mugger_2more";
				break;
			case 3:
				progress_sound = "mugger_3more";
				break;
			case 4:
				progress_sound = "mugger_4more";
				break;
			case 5:
				progress_sound = "mugger_5more";
				break;
		}
		if ( IsDefined( progress_sound ) )
		{
			self PlaySoundToPlayer( progress_sound, self );
		}
	}
		
	
	wait( 0.5 );
	
	mugger_bank_tags( false );
}

mugger_bank_tags( bank_all, noSplash )
{
	//bank them if we go over a multiple of level.mugger_bank_limit
	tags_to_bank = 0;
	if ( bank_all == true )
	{
		tags_to_bank = self.tags_carried;
	}
	else
	{
		tags_remainder = self.tags_carried % level.mugger_bank_limit;
		tags_to_bank = self.tags_carried-tags_remainder;//this should always be a multiple of level.mugger_bank_limit...
	}
	
	if ( tags_to_bank > 0 )
	{
		self.tags_to_bank = tags_to_bank;
		if ( !IsDefined( noSplash ) )
		{
			self thread maps\mp\gametypes\_hud_message::SplashNotifyUrgent( "callout_tags_banked", tags_to_bank );
		}
		self thread maps\mp\gametypes\_rank::giveRankXP( "tags_banked", self.tags_to_bank * maps\mp\gametypes\_rank::getScoreInfoValue( "kill_confirmed" ) );	
		level thread maps\mp\gametypes\_gamescore::givePlayerScore( "tags_banked", self, undefined, true );
		self.total_tags_banked += tags_to_bank;
		self.tags_carried -= tags_to_bank;
		self.game_extrainfo = self.tags_carried;
//		self UpdateGameExtraInfoToAll();
		self.dogtagsText setValue( self.tags_carried );
		self.dogtagsText thread maps\mp\gametypes\_hud::fontPulse( self );

		//NOTE: we hijack this to show tags collected on the scoreboard
		//if ( bank_all )
		{//show the total for the game
			self.assists = self.total_tags_banked;
			self.pers["assists"] = self.total_tags_banked;
		}
		/*else
		{//show how many we currently are carrying, unbanked
			self.assists = self.tags_carried;
			self.pers["assists"] = self.tags_carried;
		}*/
		self UpdateScores();
//		if ( self.total_tags_banked >= getWatchedDvar( "scorelimit" ) )
//			thread maps\mp\gametypes\_gamelogic::endGame( self, game["strings"]["score_limit_reached"] );
	}
}

onPlayerScore( event, player, victim )
{
	//FIXME: make sure the score popup reflects the tags they got and nothing else (payback, first blood, etc)
	if ( event == "tags_banked" && IsDefined( player ) && IsDefined( player.tags_to_bank ) && player.tags_to_bank > 0 )
	{
		banking_score = player.tags_to_bank * maps\mp\gametypes\_rank::getScoreInfoValue( "kill_confirmed" );
		player.tags_to_bank = 0;
		return banking_score;
	}
	//FIXME: make the score *only* tags?  Can get XP for other things, but score only counts tags banked...?
	return 0;
	//return undefined;
}
/*
getBetterPlayer( playerA, playerB )
{
	if ( playerA.total_tags_banked > playerB.total_tags_banked )
		return playerA;
	
	if ( playerB.total_tags_banked > playerA.total_tags_banked )
		return playerB;

	if ( playerA.score > playerB.score )
		return playerA;
		
	if ( playerB.score > playerA.score )
		return playerB;
		
	if ( playerA.kills > playerB.kills )
		return playerA;
		
	if ( playerB.kills > playerA.kills )
		return playerB;

	if ( playerA.deaths < playerB.deaths )
		return playerA;
		
	if ( playerB.deaths < playerA.deaths )
		return playerB;
		
	// TODO: more metrics for getting the better player
		
	if ( cointoss() )
		return playerA;
	else
		return playerB;
}

updatePlacement()
{
	placementAll = [];
	foreach ( player in level.players )
	{
		if ( isDefined( player.connectedPostGame ))
			continue;

		if( player.pers["team"] == "spectator" || player.pers["team"] == "none" )
			continue;
			
		placementAll[placementAll.size] = player;
	}
	
	for ( i = 1; i < placementAll.size; i++ )
	{
		player = placementAll[i];
		playerScore = player.total_tags_banked;
//		for ( j = i - 1; j >= 0 && (player.score > placementAll[j].score || (player.score == placementAll[j].score && player.deaths < placementAll[j].deaths)); j-- )
		for ( j = i - 1; j >= 0 && getBetterPlayer( player, placementAll[j] ) == player; j-- )
			placementAll[j + 1] = placementAll[j];
		placementAll[j + 1] = player;
	}
	
	level.placement["all"] = placementAll;
}
*/
resetTags( picked_up )
{
	/*if ( self.temp_tag )
	{
		self tag_delete( picked_up );
	}
	else*/
	{
		if ( !picked_up )
		{
			level notify( "mugger_jackpot_increment" );
		}
		self.attacker = undefined;
		self notify( "reset" );
		self.visuals[0] hide();
		self.curOrigin = (0,0,1000);
		self.trigger.origin = (0,0,1000);
		self.visuals[0].origin = (0,0,1000);
		self maps\mp\gametypes\_gameobjects::allowUse( "none" );
		if ( !self.temp_tag )
		{
			objective_state( self.objId, "invisible" );	
		}
	}
}

/*
spin()
{
	level endon( "game_ended" );
	self endon( "reset" );	
	self endon( "death" );	
	self endon( "deleted" );
	
	while( true )
	{
		self.visuals[0] rotateYaw( 180, 0.5 );
		
		wait( 0.5 );

		self.visuals[0] rotateYaw( 180, 0.5 );	
		
		wait( 0.5 );		
	}
}


bounce_physics_fake()
{
	level endon( "game_ended" );
	self endon( "reset" );	
	self endon( "death" );	
	self endon( "deleted" );
	
	//wait until we stop moving
	oldOrigin = (0,0,0);
	while( oldOrigin != self.visuals[0].origin )
	{
		if ( oldOrigin != (0,0,0) )
		{
			testPos = PlayerPhysicsTrace(oldOrigin, self.visuals[0].origin );
			if ( testPos != self.visuals[0].origin )
			{//will this stop the MoveGravity?
				self.visuals[0].origin = testPos;
			}
		}
		oldOrigin = self.visuals[0].origin;
		wait( 0.1 );
	}
	
	//drop to the floor
	testpos = self.visuals[0].origin + (0,0,-300);
	floorPos = PlayerPhysicsTrace(self.visuals[0].origin, testpos );
	//floorPos = PhysicsTrace(self.visuals[0].origin, testpos );
	floorPos += (0,0,14);
	fall_time = abs(self.visuals[0].origin[2]-floorPos[2])/1000.0/2.0;
	self.visuals[0] MoveTo( floorPos, fall_time );
	wait(fall_time);

	//bounce
	while( true )
	{
		topPos = self.visuals[0].origin + (0,0,12);
		self.visuals[0] moveTo( topPos, 0.5, 0.15, 0.15 );
		
		wait( 0.5 );

		self.visuals[0] moveTo( floorPos, 0.5, 0.15, 0.15 );
		
		wait( 0.5 );		
	}
}

bounce_physics()
{
	level endon( "game_ended" );
	self endon( "reset" );	
	self endon( "death" );	
	self endon( "deleted" );
	
	oldOrigin = (0,0,0);
	while( oldOrigin != self.visuals[0].origin )
	{
		oldOrigin = self.physicsModel.origin;
		wait( 0.1 );
	}

	while( true )
	{
		topPos = self.visuals[0].origin + (0,0,12);
		self.visuals[0] moveTo( topPos, 0.5, 0.15, 0.15 );
		
		wait( 0.5 );

		bottomPos = self.visuals[0].origin - (0,0,12);;
		self.visuals[0] moveTo( bottomPos, 0.5, 0.15, 0.15 );
		
		wait( 0.5 );		
	}
}

bounce()
{
	level endon( "game_ended" );
	self endon( "reset" );	
	self endon( "death" );	
	self endon( "deleted" );
	
	bottomPos = self.curOrigin;
	topPos = self.curOrigin + (0,0,12);
	
	while( true )
	{
		self.visuals[0] moveTo( topPos, 0.5, 0.15, 0.15 );
		self.visuals[0] rotateYaw( 180, 0.5 );
		
		wait( 0.5 );
		
		self.visuals[0] moveTo( bottomPos, 0.5, 0.15, 0.15 );
		self.visuals[0] rotateYaw( 180, 0.5 );	
		
		wait( 0.5 );		
	}
}
*/

timeOut()// victim )
{
	level  endon( "game_ended" );
	//victim endon( "disconnect" );
	self endon( "death" );
	self endon( "deleted" );
	self endon( "reset" );
	self endon( "reused" );
	
	self notify( "timeout_start" );
	self endon( "timeout_start" );
	
	level maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( 27.0 );

	//blink for the last 3 seconds	
	time_left = 3.0;
	while( time_left > 0.0 )
	{
		self.visuals[0] Hide();
		wait( 0.25 );
		self.visuals[0] Show();
		wait( 0.25 );
		time_left -= 0.5;
	}
	PlayFx( level.mugger_fx["vanish"], self.curOrigin );
	self thread resetTags( false );
}

/*tag_delete( picked_up )
{
	//sanity check
	if ( isDefined( self ) )
	{
		if ( !picked_up )
		{
			level notify( "mugger_jackpot_increment" );
		}
		
		if ( IsDefined( self.jackpot_tag ) )
		{
			level.mugger_jackpot_tags_spawned--;
		}
		//	delete objective and visuals
		//objective_delete( self.objId );
		self.trigger delete();
		for ( i=0; i<self.visuals.size; i++ )
			self.visuals[i] delete();
		if ( IsDefined( self.physicsModel ) )
		{
			self.physicsModel delete();
		}
		self notify ( "deleted" );
		self Delete();
	}
}*/


/*
tagTeamUpdater( tags )
{
	level endon( "game_ended" );
	self endon( "disconnect" );
	
	while( true )
	{
		self waittill( "joined_team" );
		
		tags.victimTeam = self.pers["team"];
		tags resetTags();
	}
}
*/

clearOnVictimDisconnect( victim )
{
	level endon( "game_ended" );	
	
	guid = victim.guid;
	victim waittill( "disconnect" );
	
	if ( isDefined( level.dogtags[guid] ) )
	{
		//	block further use
		level.dogtags[guid] maps\mp\gametypes\_gameobjects::allowUse( "none" );
		
		//	tell the attacker their kill was denied
		if ( isDefined( level.dogtags[guid].attacker ) )
			level.dogtags[guid].attacker thread maps\mp\gametypes\_rank::xpEventPopup( &"SPLASHES_DENIED_KILL", (1,0.5,0.5) );		
		
		//	play vanish effect, reset, and wait for reset to process
		PlayFx( level.mugger_fx["vanish"], level.dogtags[guid].curOrigin );
		level.dogtags[guid] notify( "reset" );		
		wait( 0.05 );
		
		//	sanity check before removal
		if ( isDefined( level.dogtags[guid] ) )
		{
			//	delete objective and visuals
			objective_delete( level.dogtags[guid].objId );
			level.dogtags[guid].trigger delete();
			for ( i=0; i<level.dogtags[guid].visuals.size; i++ )
				level.dogtags[guid].visuals[i] delete();
			level.dogtags[guid] notify ( "deleted" );
			
			//	remove from list
			level.dogtags[guid] = undefined;		
		}	
	}	
}


/*
initGametypeAwards()
{
	maps\mp\_awards::initStatAward( "killsconfirmed",		0, maps\mp\_awards::highestWins );
}
*/

onTimeLimit()
{
	level notify( "banking_all" );
	//bank all remaining tags!
	foreach( player in level.players )
	{
		player mugger_bank_tags( true );
	}
	wait(0.1);
	maps\mp\gametypes\_gamelogic::default_onTimeLimit();
}
/*
mugger_endgame_setTotalTags()
{
	level waittill( "game_ended" );	
	wait(0.5);
	foreach( player in level.players )
	{
		player.assists = player.total_tags_banked;
		player.pers["assists"] = player.total_tags_banked;
	}
}
*/

MUGGER_ZONE_DROP_RADIUS = 50;
mugger_jackpot_watch()
{
	level endon( "game_ended" );
	level endon( "jackpot_stop" );
	
	//FIXME: do this in the playlist, not in code
	//if ( level.hardcoreMode )
	//	return;
	
	if ( level.mugger_jackpot_limit <= 0 )
		return;
	
	level.mugger_jackpot_num_tags = 0;
	level.mugger_jackpot_tags_unspawned = 0;
	level.mugger_jackpot_num_tags = 0;
	if ( IsDefined( level.mugger_jackpot_bar ) )
	{
		level.mugger_jackpot_bar updateBar( 0.0 );//, 1.0 );
		level.mugger_jackpot_text.alpha = 1;
		level.mugger_jackpot_bar.alpha = 1;
	}

	level thread mugger_jackpot_timer();

	while(1)
	{
		level waittill( "mugger_jackpot_increment" );
		do_increment = true;
		/*if ( IsDefined( level.mugger_last_mega_drop ) )
		{
			time_since_last_mega_drop = GetTime() - level.mugger_last_mega_drop;
			//if there was a megadrop in the last 10 seconds, don't even increment
			if ( time_since_last_mega_drop < 10000 )
			{
				do_increment = false;
			}
		}*/
		if ( do_increment )
		{
			level.mugger_jackpot_num_tags++;
			bar_frac = clamp(float(level.mugger_jackpot_num_tags/level.mugger_jackpot_limit), 0.0, 1.0);
			if ( IsDefined( level.mugger_jackpot_bar ) )
				level.mugger_jackpot_bar updateBar( bar_frac );//, 1.0 );
			if ( level.mugger_jackpot_num_tags >= level.mugger_jackpot_limit )
			{
				if ( IsDefined( level.mugger_jackpot_text ) )
					level.mugger_jackpot_text thread maps\mp\gametypes\_hud::fontPulse( level.players[0] );
				//we were dropping the limit each time, but random is more unpredictable and fun
				level.mugger_jackpot_num_tags = 15 + RandomIntRange( 0, 3 ) * 5;//15-25 in increments of 5
				//level.mugger_jackpot_num_tags = 10 + RandomIntRange( 0, 5 ) * 5;//10-30 in increments of 5
				level thread mugger_jackpot_drop();
				break;
			}
		}
	}
}

mugger_jackpot_timer()
{
	level endon( "game_ended" );
	level endon( "jackpot_stop" );
	
	gameFlagWait( "prematch_done" );
	
	while(1)
	{
		wait( level.mugger_jackpot_wait_sec );
		level notify( "mugger_jackpot_increment" );
	}
}

mugger_jackpot_drop()
{
	level endon( "game_ended" );
	level notify( "reset_airdrop" );
	level endon( "reset_airdrop" );
	
	//drop it
	position = level.grnd_dropZones[level.script][RandomInt(level.grnd_dropZones[level.script].size)];
	position = position + ( randomIntRange( (-1*MUGGER_ZONE_DROP_RADIUS), MUGGER_ZONE_DROP_RADIUS ), randomIntRange( (-1*MUGGER_ZONE_DROP_RADIUS), MUGGER_ZONE_DROP_RADIUS ), 0 );
	
	while( true )
	{
		owner = level.players[0];
		numIncomingVehicles = 1;
		if( isDefined( owner ) && 
			currentActiveVehicleCount() < maxVehiclesAllowed() && 
			level.fauxVehicleCount + numIncomingVehicles < maxVehiclesAllowed() && 
			level.numDropCrates < 8 )
		{
			//Let everyone know one is coming
			//owner thread maps\mp\gametypes\_rank::xpEventPopup( &"SPLASHES_EARNED_CAREPACKAGE" );
			//thread teamPlayerCardSplash( "airdrop_points_incoming", owner, owner.team );
			//thread teamPlayerCardSplash( "airdrop_points_incoming", owner, level.otherTeam[owner.team] );
			foreach( player in level.players )
			{
				player thread maps\mp\gametypes\_hud_message::SplashNotify( "mugger_jackpot_incoming" );
			}
			
			incrementFauxVehicleCount();
			level thread maps\mp\killstreaks\_airdrop::doFlyBy( owner, position, randomFloat( 360 ), "airdrop_mugger", 0, "airdrop_jackpot" );
			break;
		}		
		else
		{
			wait(0.5);
			continue;
		}
	}
		
	level.mugger_jackpot_tags_unspawned = level.mugger_jackpot_num_tags;
	level thread mugger_jackpot_run( position );
}

mugger_jackpot_pile_notify( pos, event, num_tags )
{
	//show a tag pile on the radar!
	if ( !IsDefined( level.jackpotPileObjId ) )
	{
		level.jackpotPileObjId = maps\mp\gametypes\_gameobjects::getNextObjID();	
		objective_add( level.jackpotPileObjId, "active", pos );
		objective_icon( level.jackpotPileObjId, "waypoint_jackpot" );//waypoint_dogtag_pile
	}
	else
	{
		Objective_Position( level.jackpotPileObjId, pos );
	}
	
	if ( num_tags >= 10 )
	{
		//call it out for everyone and start the feeding frenzy!
		foreach( player in level.players )
		{
//			player PlaySoundToPlayer( "mp_defcon_one", player );
			player playLocalSound( game["music"]["victory_" + player.pers["team"] ] );
			//player PlayLocalSound( "mugger_jackpot_vo" );
			//player thread maps\mp\gametypes\_hud_message::SplashNotify( event, num_tags );
		}
		//3D icon that everyone can see
		if ( !IsDefined( level.jackpotPileIcon ) )
		{
			level.jackpotPileIcon = newHudElem();
			level.jackpotPileIcon setShader( "waypoint_jackpot", 64, 64 );
			level.jackpotPileIcon SetWayPoint( false, true, false, false );
		}
		level.jackpotPileIcon.x = pos[0];
		level.jackpotPileIcon.y = pos[1];
		level.jackpotPileIcon.z = pos[2] + 12;
		level.jackpotPileIcon.alpha = 0.75;
	}
}

mugger_jackpot_pile_notify_cleanup()
{
	Objective_State( level.jackpotPileObjId, "invisible" );
	level.jackpotPileIcon FadeOverTime( 2 );
	level.jackpotPileIcon.alpha = 0;
	level.jackpotPileIcon delayThread( 2, ::hudElemDestroy );
}

mugger_jackpot_fx( jackpot_origin )
{
	mugger_jackpot_fx_cleanup();
	
	//move zone
	traceStart = jackpot_origin + (0,0,30);
	traceEnd = jackpot_origin + (0,0,-1000);
	trace = bulletTrace( traceStart, traceEnd, false, undefined );		
	level.jackpot_zone.origin = trace["position"]+(0,0,1);
	level.jackpot_zone show();
	
	//	target
	upangles = vectorToAngles( trace["normal"] );
	forward = anglesToForward( upangles );
	right = anglesToRight( upangles );		
	thread spawnFxDelay( trace["position"], forward, right, 0.5 );			
	
	//	smoke
	wait( 0.1 );
	PlayFxOnTag( level.mugger_fx["smoke"], level.jackpot_zone, "tag_fx" );	
	foreach ( player in level.players )
		player.mugger_fx_playing = true;
	level.jackpot_zone.mugger_fx_playing = true;
}

mugger_jackpot_fx_cleanup()
{
	StopFxOnTag( level.mugger_fx["smoke"], level.jackpot_zone, "tag_fx" );
	level.jackpot_zone hide();
	if ( isDefined( level.jackpot_targetFX ) )
		level.jackpot_targetFX delete();
	if ( level.jackpot_zone.mugger_fx_playing )
	{
		level.jackpot_zone.mugger_fx_playing = false;
		StopFxOnTag( level.mugger_fx["smoke"], level.jackpot_zone, "tag_fx" );
		wait( 0.05 );
	}
}

spawnFxDelay( pos, forward, right, delay )
{
	if ( isDefined( level.jackpot_targetFX ) )
		level.jackpot_targetFX delete();
	wait delay;
	level.jackpot_targetFX = spawnFx( level.mugger_targetFXID, pos, forward, right );
	triggerFx( level.jackpot_targetFX );
}

waitReplaySmokeFxForNewPlayer()
{
	level endon( "game_ended" );
	self  endon( "disconnect" );
	
	gameFlagWait( "prematch_done" );
	
	//	let cycleZones() do it's initial work so we only catch people who are joining late
	wait( 0.5 );
	
	if ( level.jackpot_zone.mugger_fx_playing == true && !isDefined( self.mugger_fx_playing ) )
	{
		PlayFxOnTagForClients( level.mugger_fx["smoke"], level.jackpot_zone, "tag_fx", self );		
		self.mugger_fx_playing = true;
	}
}

mugger_jackpot_run( jackpot_origin )
{
	level endon( "game_ended" );
	
	level notify( "jackpot_stop" );

	//let at the players know
	mugger_jackpot_pile_notify( jackpot_origin, "mugger_jackpot", level.mugger_jackpot_tags_unspawned );
	
	level thread mugger_jackpot_fx( jackpot_origin );

	//wait until the crate is ready
	level waittill( "airdrop_jackpot_landed", jackpot_origin );
	Objective_Position( level.jackpotPileObjId, jackpot_origin );
	level.jackpotPileIcon.x = jackpot_origin[0];
	level.jackpotPileIcon.y = jackpot_origin[1];
	level.jackpotPileIcon.z = jackpot_origin[2] + 32;
	
	foreach( player in level.players )
	{
		player PlaySoundToPlayer( "mp_defcon_one", player );
		player thread maps\mp\gametypes\_hud_message::SplashNotify( "mugger_jackpot", level.mugger_jackpot_tags_unspawned );
	}

	//now spawn them
	level.mugger_jackpot_tags_spawned = 0;
	while ( level.mugger_jackpot_tags_unspawned > 0 )
	{
		if ( level.mugger_jackpot_tags_spawned < 10 )
		{
			level.mugger_jackpot_tags_unspawned--;
			spawned_tag = mugger_tag_temp_spawn( jackpot_origin, 0, 400 );
			spawned_tag.jackpot_tag = true;
			level.mugger_jackpot_tags_spawned++;
			wait(0.1);
		}
		else
		{
			wait( 0.5 );
		}
	}

	//all spawned, remove the jackpot HUD element	
	level.mugger_jackpot_num_tags = 0;
	if ( IsDefined( level.mugger_jackpot_bar ) )
	{
		level.mugger_jackpot_bar updateBar( 0.0 );//, 1.0 );
		level.mugger_jackpot_text.alpha = 0;
		level.mugger_jackpot_bar.alpha = 0;
		level.mugger_jackpot_bar.bar.alpha = 0;
	}

	while( level.mugger_jackpot_tags_spawned > 0 )
	{
		wait(1);
	}
	
	mugger_jackpot_pile_notify_cleanup();
	mugger_jackpot_fx_cleanup();

	//restart the jackpot
	level thread mugger_jackpot_watch();
}

mugger_jackpot_hud_create()
{
	level.mugger_jackpot_text = createServerFontString( "default", 1.25 );
	level.mugger_jackpot_text setPoint("TOP", "TOP", 0, 10);
	level.mugger_jackpot_text setText( &"MPUI_MUGGER_JACKPOT" );
	level.mugger_jackpot_text maps\mp\gametypes\_hud::fontPulseInit( 3.0 );
	
	level.mugger_jackpot_bar = createServerBar( (1,1,0), 100, 10, 0.9 );
	level.mugger_jackpot_bar setPoint("TOP", "TOP", 0, 28);
	level.mugger_jackpot_bar updateBar( 0.0 );
	level.mugger_jackpot_bar.bar thread flashThread();
}
