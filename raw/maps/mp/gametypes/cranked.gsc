#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
/*
	Cranked
	Objective: 	Score points for your team by eliminating players on the opposing team. 
		Players who are carrying the "hot potatoes" will score more points. 
		The "hot potatoes" are ticking time bombs and need kills and assists to refresh the timer.
	Map ends:	When one team reaches the score limit, or time limit is reached
	Respawning:	No wait / Near teammates

	Level requirementss
	------------------
		Spawnpoints:
			classname		mp_tdm_spawn
			All players spawn from these. The spawnpoint chosen is dependent on the current locations of teammates and enemies
			at the time of spawn. Players generally spawn behind their teammates relative to the direction of enemies.

		Spectator Spawnpoints:
			classname		mp_global_intermission
			Spectators spawn from these and intermission is viewed from these positions.
			Atleast one is required, any more and they are randomly chosen between.
*/

/*QUAKED mp_tdm_spawn (0.0 0.0 1.0) (-16 -16 0) (16 16 72)
Players spawn away from enemies and near their team at one of these positions.*/

/*QUAKED mp_tdm_spawn_axis_start (0.5 0.0 1.0) (-16 -16 0) (16 16 72)
Axis players spawn away from enemies and near their team at one of these positions at the start of a round.*/

/*QUAKED mp_tdm_spawn_allies_start (0.0 0.5 1.0) (-16 -16 0) (16 16 72)
Allied players spawn away from enemies and near their team at one of these positions at the start of a round.*/

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
		registerTimeLimitDvar( level.gameType, 10 );
		registerScoreLimitDvar( level.gameType, 500 );
		registerRoundLimitDvar( level.gameType, 1 );
		registerWinLimitDvar( level.gameType, 1 );
		registerNumLivesDvar( level.gameType, 0 );
		registerHalfTimeDvar( level.gameType, 0 );
		
		level.matchRules_damageMultiplier = 0;
		level.matchRules_vampirism = 0;
	}

	level.teamBased = true;
	level.onStartGameType = ::onStartGameType;
	level.getSpawnPoint = ::getSpawnPoint;
	level.onNormalDeath = ::onNormalDeath;
	level.onSuicideDeath = ::onSuicideDeath;
	
	if ( level.matchRules_damageMultiplier || level.matchRules_vampirism )
		level.modifyPlayerDamage = maps\mp\gametypes\_damage::gamemodeModifyPlayerDamage;

	game["dialog"]["gametype"] = "tm_death";
	
	if ( getDvarInt( "g_hardcore" ) )
		game["dialog"]["gametype"] = "hc_" + game["dialog"]["gametype"];
	else if ( getDvarInt( "camera_thirdPerson" ) )
		game["dialog"]["gametype"] = "thirdp_" + game["dialog"]["gametype"];
	else if ( getDvarInt( "scr_diehard" ) )
		game["dialog"]["gametype"] = "dh_" + game["dialog"]["gametype"];
	else if (getDvarInt( "scr_" + level.gameType + "_promode" ) )
		game["dialog"]["gametype"] = game["dialog"]["gametype"] + "_pro";
	
	game["strings"]["overtime_hint"] = &"MP_FIRST_BLOOD";
	
	level thread onPlayerConnect();
}

onPlayerConnect()
{
	while( true )
	{
		level waittill( "connected", player );
		player thread onPlayerSpawned();
	}
}

onPlayerSpawned()
{
	self endon( "disconnect" );

	while( true )
	{
		self waittill( "spawned_player" );
	}
}

initializeMatchRules()
{
	//	set common values
	setCommonRulesFromMatchRulesData();
	
	//	set everything else (private match options, default .cfg file values, and what normally is registered in the 'else' below)
	SetDynamicDvar( "scr_cranked_roundswitch", 0 );
	registerRoundSwitchDvar( "cranked", 0, 0, 9 );
	SetDynamicDvar( "scr_cranked_roundlimit", 1 );
	registerRoundLimitDvar( "cranked", 1 );		
	SetDynamicDvar( "scr_cranked_winlimit", 1 );
	registerWinLimitDvar( "cranked", 1 );			
	SetDynamicDvar( "scr_cranked_halftime", 0 );
	registerHalfTimeDvar( "cranked", 0 );
		
	SetDynamicDvar( "scr_cranked_promode", 0 );	
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
	
	maps\mp\gametypes\_rank::registerScoreInfo( "team_score_increment", 1 );
	maps\mp\gametypes\_rank::registerScoreInfo( "kill", 100 );
	maps\mp\gametypes\_rank::registerScoreInfo( "kill_cranked", 100 );
	maps\mp\gametypes\_rank::registerScoreInfo( "assist_cranked", 0 );
	
	cranked();

	allowed[0] = level.gameType;
	maps\mp\gametypes\_gameobjects::main( allowed );	
}


initSpawns()
{
	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );	
	
	maps\mp\gametypes\_spawnlogic::addStartSpawnPoints( "mp_tdm_spawn_allies_start" );
	maps\mp\gametypes\_spawnlogic::addStartSpawnPoints( "mp_tdm_spawn_axis_start" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_tdm_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_tdm_spawn" );
	
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
		spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_tdm_spawn_" + spawnteam + "_start" );
		spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
	}
	else
	{
		spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( spawnteam );
		spawnPoint = maps\mp\gametypes\_spawnscoring::getSpawnpoint_NearTeam( spawnPoints );
	}
	
	return spawnPoint;
}


onNormalDeath( victim, attacker, lifeId )
{
	victim SetClientOmnvar( "ui_cranked_bomb_timer_end_milliseconds", 0 );
	victim.cranked = undefined;
	victim.cranked_end_time = undefined;

	score = maps\mp\gametypes\_rank::getScoreInfoValue( "team_score_increment" );
	assert( isDefined( score ) );

	if( IsDefined( attacker.cranked ) )
	{
		score *= 2;
		
		event = "kill_cranked";
		splash = &"SPLASHES_KILL_CRANKED";
		attacker thread onKill( event, splash );
	}
	else
		attacker makeCranked();
	
	// give half time back on assists while cranked
	if( IsDefined( victim.attackers ) && !IsDefined( level.assists_disabled ) )
	{
		foreach( player in victim.attackers )
		{
			if( !IsDefined( player ) )
				continue;

			if( player == attacker )
				continue;

			// don't let the victim get an assist off of themselves
			if( victim == player )
				continue;
			
			if( !IsDefined( player.cranked ) )
				continue;
			
			player thread onAssist();
		}
	}

	level maps\mp\gametypes\_gamescore::giveTeamScoreForObjective( attacker.pers["team"], score );
	
	if ( game["state"] == "postgame" && game["teamScores"][attacker.team] > game["teamScores"][level.otherTeam[attacker.team]] )
		attacker.finalKill = true;
}

onSuicideDeath( victim )
{
	victim SetClientOmnvar( "ui_cranked_bomb_timer_end_milliseconds", 0 );
	victim.cranked = undefined;
	victim.cranked_end_time = undefined;
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

cranked()
{
	level.crankedBombTimer = 30;
}

makeCranked() // self == attacker
{
	self setCrankedBombTimer( "kill" );

	self.cranked = true;
	
	// give a little pick me up
	// reloading == specialty_fastreload
	self givePerk( "specialty_fastreload", false );

	// ads'ing == specialty_quickdraw
	self givePerk( "specialty_quickdraw", false );

	// movement == specialty_stalker
	self givePerk( "specialty_stalker", false );

	// throwing grenades == specialty_fastoffhand
	self givePerk( "specialty_fastoffhand", false );

	// sprint recovery == specialty_fastsprintrecovery
	self givePerk( "specialty_fastsprintrecovery", false );

	// endless sprint == specialty_marathon
	self givePerk( "specialty_marathon", false );

	// switching weapons == specialty_quickswap
	self givePerk( "specialty_quickswap", false );

	// ads strafe == specialty_stalker
	self givePerk( "specialty_stalker", false );

	self.moveSpeedScaler = 1.2;
	self maps\mp\gametypes\_weapons::updateMoveSpeedScale();
}

onKill( event, splash ) // self == player
{
	level endon( "game_ended" );
	self  endon( "disconnect" );
	
	while ( !isDefined( self.pers ) )
		wait( 0.05 );
	
	self thread maps\mp\gametypes\_rank::xpEventPopup( splash );
	maps\mp\gametypes\_gamescore::givePlayerScore( event, self, undefined, true );
	self thread maps\mp\gametypes\_rank::giveRankXP( event );

	self PlaySoundToPlayer( "earn_superbonus", self );
	self setCrankedBombTimer( "kill" );
}

onAssist() // self == player
{
	level endon( "game_ended" );
	self  endon( "disconnect" );
	
	self PlaySoundToPlayer( "earn_superbonus", self );
	self setCrankedBombTimer( "assist" );
}

watchBombTimer() // self == player
{
	self notify( "watchBombTimer" );
	self endon( "watchBombTimer" );
	
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	// when time expires, blow them up
	wait( level.crankedBombTimer );
	
	if( IsDefined( self ) && isReallyAlive( self ) )
	{
		self PlaySound( "grenade_explode_metal" );
		PlayFX( level.mine_explode, self.origin + ( 0, 0, 1 ) );
		RadiusDamage( self.origin, 8, 1000, 1000, self, "MOD_EXPLOSIVE" );
		self SetClientOmnvar( "ui_cranked_bomb_timer_end_milliseconds", 0 );
	}
}

setCrankedBombTimer( type ) // self == player
{
	waitTime = level.crankedBombTimer;
	// for assists add half of the time back onto their current time
	if( type == "assist" )
		waitTime = int( min( ( ( self.cranked_end_time - GetTime() ) / 1000 ) + ( level.crankedBombTimer * 0.5 ), level.crankedBombTimer ) );
	
	endTime = ( waitTime * 1000 ) + GetTime();
	self SetClientOmnvar( "ui_cranked_bomb_timer_end_milliseconds", endTime );
	self.cranked_end_time = endTime;
	
	self thread watchBombTimer();
}