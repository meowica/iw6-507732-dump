#include maps\mp\_utility;
#include common_scripts\utility;

FACTION_REF_COL 					= 0;
FACTION_NAME_COL 					= 1;
FACTION_SHORT_NAME_COL 				= 2;
FACTION_ELIMINATED_COL 				= 3;
FACTION_FORFEITED_COL 				= 4;
FACTION_ICON_COL 					= 5;
FACTION_HUD_ICON_COL 				= 6;
FACTION_VOICE_PREFIX_COL 			= 7;
FACTION_SPAWN_MUSIC_COL 			= 8;
FACTION_WIN_MUSIC_COL 				= 9;
FACTION_FLAG_MODEL_COL 				= 10;
FACTION_FLAG_CARRY_MODEL_COL 		= 11;
FACTION_FLAG_ICON_COL 				= 12;
FACTION_FLAG_FX_COL 				= 13;
FACTION_COLOR_R_COL 				= 14;
FACTION_COLOR_G_COL 				= 15;
FACTION_COLOR_B_COL 				= 16;
FACTION_HEAD_ICON_COL 				= 17;
FACTION_CRATE_MODEL_COL 			= 18;
FACTION_DEPLOY_MODEL_COL 			= 19;

MT_REF_COL							= 0;
MT_NAME_COL							= 1;
MT_ICON_COL							= 2;
MT_HEAD_ICON_COL					= 3;

init()
{
	initScoreBoard();

	level.teamBalance = getDvarInt("scr_teambalance");
	level.maxClients = getDvarInt( "sv_maxclients" );

	setPlayerModels();

	level.freeplayers = [];

	if( level.teamBased )
	{
		level thread onPlayerConnect();
		level thread updateTeamBalance();

		wait .15;
		level thread updatePlayerTimes();
	}
	else
	{
		level thread onFreePlayerConnect();

		wait .15;
		level thread updateFreePlayerTimes();
	}
}


initScoreBoard()
{
	//NOTE: multi team teams do not need to set these dvars, the team names used on the scoreboard are taken from MTTable.csv
	//currently there are no team icons used for the MT scoreboard, and enemy teams will use g_teamTitleColor_EnemyTeam when needed.
	
	setDvar("g_TeamName_Allies", getTeamShortName( "allies" ));
	setDvar("g_TeamIcon_Allies", getTeamIcon( "allies" ));
	setDvar("g_TeamIcon_MyAllies", getTeamIcon( "allies" ));
	setDvar("g_TeamIcon_EnemyAllies", getTeamIcon( "allies" ));
	scoreColor = getTeamColor( "allies" );	
	setDvar("g_ScoresColor_Allies", scoreColor[0] + " " + scoreColor[1] + " " + scoreColor[2] );

	setDvar("g_TeamName_Axis", getTeamShortName( "axis" ));
	setDvar("g_TeamIcon_Axis", getTeamIcon( "axis" ));
	setDvar("g_TeamIcon_MyAxis", getTeamIcon( "axis" ));
	setDvar("g_TeamIcon_EnemyAxis", getTeamIcon( "axis" ));
	scoreColor = getTeamColor( "axis" );	
	setDvar("g_ScoresColor_Axis", scoreColor[0] + " " + scoreColor[1] + " " + scoreColor[2] );

	setdvar("g_ScoresColor_Spectator", ".25 .25 .25");
	setdvar("g_ScoresColor_Free", ".76 .78 .10");
	setdvar("g_teamTitleColor_MyTeam", ".6 .8 .6" );
	setdvar("g_teamTitleColor_EnemyTeam", "1 .45 .5" );	
}

onPlayerConnect()
{
	for(;;)
	{
		level waittill( "connected", player );

		player thread onJoinedTeam();
		player thread onJoinedSpectators();
		player thread onPlayerSpawned();

		player thread trackPlayedTime();
	}
}


onFreePlayerConnect()
{
	for(;;)
	{
		level waittill( "connected", player );

		player thread trackFreePlayedTime();
	}
}


onJoinedTeam()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill( "joined_team" );
		//self logString( "joined team: " + self.pers["team"] );
		self updateTeamTime();
	}
}


onJoinedSpectators()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("joined_spectators");
		self.pers["teamTime"] = undefined;
	}
}


trackPlayedTime()
{
	self endon( "disconnect" );

	self.timePlayed["allies"] = 0;
	self.timePlayed["axis"] = 0;
	self.timePlayed["free"] = 0;
	self.timePlayed["other"] = 0;
	self.timePlayed["total"] = 0;

	gameFlagWait( "prematch_done" );

	for ( ;; )
	{
		if ( game["state"] == "playing" )
		{
			if ( self.sessionteam == "allies" )
			{
				self.timePlayed["allies"]++;
				self.timePlayed["total"]++;
			}
			else if ( self.sessionteam == "axis" )
			{
				self.timePlayed["axis"]++;
				self.timePlayed["total"]++;
			}
			else if ( self.sessionteam == "spectator" )
			{
				self.timePlayed["other"]++;
			}

		}

		wait ( 1.0 );
	}
}


updatePlayerTimes()
{
	if ( !level.rankedmatch )
		return;
	
	level endon( "game_ended" );
	
	for ( ;; )
	{
		maps\mp\gametypes\_hostmigration::waitTillHostMigrationDone();
		
		foreach ( player in level.players )
			player updatePlayedTime();

		wait( 1.0 );
	}
}


updatePlayedTime()
{
	// bots dont need this logic running and its one of the lowest hanging script performance costs
	if ( IsAI( self ) )
		return;
	
	if ( !self rankingEnabled() )
		return;

	if ( self.timePlayed["allies"] )
	{
		self maps\mp\gametypes\_persistence::statAddBuffered( "timePlayedAllies", self.timePlayed["allies"] );
		self maps\mp\gametypes\_persistence::statAddBuffered( "timePlayedTotal", self.timePlayed["allies"] );
		self maps\mp\gametypes\_persistence::statAddChildBuffered( "round", "timePlayed", self.timePlayed["allies"] );

		if ( !self.prestigeDoubleXp )
		{
			self maps\mp\gametypes\_persistence::statAddChildBufferedWithMax( "xpMultiplierTimePlayed", 0, self.timePlayed["allies"], self.bufferedChildStatsMax[ "xpMaxMultiplierTimePlayed" ][ 0 ] );
			self maps\mp\gametypes\_persistence::statAddChildBufferedWithMax( "xpMultiplierTimePlayed", 1, self.timePlayed["allies"], self.bufferedChildStatsMax[ "xpMaxMultiplierTimePlayed" ][ 1 ] );
			self maps\mp\gametypes\_persistence::statAddChildBufferedWithMax( "xpMultiplierTimePlayed", 2, self.timePlayed["allies"], self.bufferedChildStatsMax[ "xpMaxMultiplierTimePlayed" ][ 2 ] );
		}
		
		self maps\mp\gametypes\_persistence::statAddChildBufferedWithMax( "challengeXPMultiplierTimePlayed", 0, self.timePlayed["allies"], self.bufferedChildStatsMax[ "challengeXPMaxMultiplierTimePlayed" ][ 0 ] );
		self maps\mp\gametypes\_persistence::statAddChildBufferedWithMax( "weaponXPMultiplierTimePlayed", 0, self.timePlayed["allies"], self.bufferedChildStatsMax[ "weaponXPMaxMultiplierTimePlayed" ][ 0 ] );
	
		//prestige 
		self maps\mp\gametypes\_persistence::statAddBufferedWithMax( "prestigeDoubleXpTimePlayed", self.timePlayed["allies"], self.bufferedStatsMax["prestigeDoubleXpMaxTimePlayed"] ); 
		self maps\mp\gametypes\_persistence::statAddBufferedWithMax( "prestigeDoubleWeaponXpTimePlayed", self.timePlayed["allies"], self.bufferedStatsMax["prestigeDoubleWeaponXpMaxTimePlayed"] ); 
	}

	if ( self.timePlayed["axis"] )
	{
		self maps\mp\gametypes\_persistence::statAddBuffered( "timePlayedOpfor", self.timePlayed["axis"] );
		self maps\mp\gametypes\_persistence::statAddBuffered( "timePlayedTotal", self.timePlayed["axis"] );
		self maps\mp\gametypes\_persistence::statAddChildBuffered( "round", "timePlayed", self.timePlayed["axis"] );

		if ( !self.prestigeDoubleXp )
		{
			self maps\mp\gametypes\_persistence::statAddChildBufferedWithMax( "xpMultiplierTimePlayed", 0, self.timePlayed["axis"], self.bufferedChildStatsMax[ "xpMaxMultiplierTimePlayed" ][ 0 ] );
			self maps\mp\gametypes\_persistence::statAddChildBufferedWithMax( "xpMultiplierTimePlayed", 1, self.timePlayed["axis"], self.bufferedChildStatsMax[ "xpMaxMultiplierTimePlayed" ][ 1 ] );
			self maps\mp\gametypes\_persistence::statAddChildBufferedWithMax( "xpMultiplierTimePlayed", 2, self.timePlayed["axis"], self.bufferedChildStatsMax[ "xpMaxMultiplierTimePlayed" ][ 2 ] );
		}
		
		self maps\mp\gametypes\_persistence::statAddChildBufferedWithMax( "challengeXPMultiplierTimePlayed", 0, self.timePlayed["axis"], self.bufferedChildStatsMax[ "challengeXPMaxMultiplierTimePlayed" ][ 0 ] );
		self maps\mp\gametypes\_persistence::statAddChildBufferedWithMax( "weaponXPMultiplierTimePlayed", 0, self.timePlayed["axis"], self.bufferedChildStatsMax[ "weaponXPMaxMultiplierTimePlayed" ][ 0 ] );
	
		//prestige 
		self maps\mp\gametypes\_persistence::statAddBufferedWithMax( "prestigeDoubleXpTimePlayed", self.timePlayed["axis"], self.bufferedStatsMax[ "prestigeDoubleXpMaxTimePlayed" ] );
		self maps\mp\gametypes\_persistence::statAddBufferedWithMax( "prestigeDoubleWeaponXpTimePlayed", self.timePlayed["axis"], self.bufferedStatsMax["prestigeDoubleWeaponXpMaxTimePlayed"] ); 
	}

	if ( self.timePlayed["other"] )
	{
		self maps\mp\gametypes\_persistence::statAddBuffered( "timePlayedOther", self.timePlayed["other"] );
		self maps\mp\gametypes\_persistence::statAddBuffered( "timePlayedTotal", self.timePlayed["other"] );
		self maps\mp\gametypes\_persistence::statAddChildBuffered( "round", "timePlayed", self.timePlayed["other"] );

		if ( !self.prestigeDoubleXp )
		{
			self maps\mp\gametypes\_persistence::statAddChildBufferedWithMax( "xpMultiplierTimePlayed", 0, self.timePlayed["other"], self.bufferedChildStatsMax[ "xpMaxMultiplierTimePlayed" ][ 0 ] );
			self maps\mp\gametypes\_persistence::statAddChildBufferedWithMax( "xpMultiplierTimePlayed", 1, self.timePlayed["other"], self.bufferedChildStatsMax[ "xpMaxMultiplierTimePlayed" ][ 1 ] );
			self maps\mp\gametypes\_persistence::statAddChildBufferedWithMax( "xpMultiplierTimePlayed", 2, self.timePlayed["other"], self.bufferedChildStatsMax[ "xpMaxMultiplierTimePlayed" ][ 2 ] );
		}
		
		self maps\mp\gametypes\_persistence::statAddChildBufferedWithMax( "challengeXPMultiplierTimePlayed", 0, self.timePlayed["other"], self.bufferedChildStatsMax[ "challengeXPMaxMultiplierTimePlayed" ][ 0 ] );
		self maps\mp\gametypes\_persistence::statAddChildBufferedWithMax( "weaponXPMultiplierTimePlayed", 0, self.timePlayed["other"], self.bufferedChildStatsMax[ "weaponXPMaxMultiplierTimePlayed" ][ 0 ] );
		
		//prestige 
		self maps\mp\gametypes\_persistence::statAddBufferedWithMax( "prestigeDoubleXpTimePlayed", self.timePlayed["other"], self.bufferedStatsMax[ "prestigeDoubleXpMaxTimePlayed" ] );
		self maps\mp\gametypes\_persistence::statAddBufferedWithMax( "prestigeDoubleWeaponXpTimePlayed", self.timePlayed["other"], self.bufferedStatsMax["prestigeDoubleWeaponXpMaxTimePlayed"] ); 
	}

	if ( game["state"] == "postgame" )
		return;

	self.timePlayed["allies"] = 0;
	self.timePlayed["axis"] = 0;
	self.timePlayed["other"] = 0;
}


updateTeamTime()
{
	if ( game["state"] != "playing" )
		return;

	self.pers["teamTime"] = getTime();
}


updateTeamBalanceDvar()
{
	for(;;)
	{
		teambalance = getdvarInt("scr_teambalance");
		if(level.teambalance != teambalance)
			level.teambalance = getdvarInt("scr_teambalance");

		wait 1;
	}
}


updateTeamBalance()
{
	level.teamLimit = level.maxclients / 2;

	level thread updateTeamBalanceDvar();

	wait .15;

	if ( level.teamBalance && isRoundBased() )
	{
    	if( IsDefined( game["BalanceTeamsNextRound"] ) )
    		iPrintLnbold( &"MP_AUTOBALANCE_NEXT_ROUND" );

		// TODO: add or change
		level waittill( "restarting" );

		if( IsDefined( game["BalanceTeamsNextRound"] ) )
		{
			level balanceTeams();
			game["BalanceTeamsNextRound"] = undefined;
		}
		else if( !getTeamBalance() )
		{
			game["BalanceTeamsNextRound"] = true;
		}
	}
	else
	{
		level endon ( "game_ended" );
		for( ;; )
		{
			if( level.teamBalance )
			{
				if( !getTeamBalance() )
				{
					iPrintLnBold( &"MP_AUTOBALANCE_SECONDS", 15 );
				    wait 15.0;

					if( !getTeamBalance() )
						level balanceTeams();
				}

				wait 59.0;
			}

			wait 1.0;
		}
	}

}


getTeamBalance()
{
	level.team["allies"] = 0;
	level.team["axis"] = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if((IsDefined(players[i].pers["team"])) && (players[i].pers["team"] == "allies"))
			level.team["allies"]++;
		else if((IsDefined(players[i].pers["team"])) && (players[i].pers["team"] == "axis"))
			level.team["axis"]++;
	}

	if((level.team["allies"] > (level.team["axis"] + level.teamBalance)) || (level.team["axis"] > (level.team["allies"] + level.teamBalance)))
		return false;
	else
		return true;
}


balanceTeams()
{
	iPrintLnBold( game["strings"]["autobalance"] );
	//Create/Clear the team arrays
	AlliedPlayers = [];
	AxisPlayers = [];

	// Populate the team arrays
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(!IsDefined(players[i].pers["teamTime"]))
			continue;

		if((IsDefined(players[i].pers["team"])) && (players[i].pers["team"] == "allies"))
			AlliedPlayers[AlliedPlayers.size] = players[i];
		else if((IsDefined(players[i].pers["team"])) && (players[i].pers["team"] == "axis"))
			AxisPlayers[AxisPlayers.size] = players[i];
	}

	MostRecent = undefined;

	while((AlliedPlayers.size > (AxisPlayers.size + 1)) || (AxisPlayers.size > (AlliedPlayers.size + 1)))
	{
		if(AlliedPlayers.size > (AxisPlayers.size + 1))
		{
			// Move the player that's been on the team the shortest ammount of time (highest teamTime value)
			for(j = 0; j < AlliedPlayers.size; j++)
			{
				if(IsDefined(AlliedPlayers[j].dont_auto_balance))
					continue;

				if(!IsDefined(MostRecent))
					MostRecent = AlliedPlayers[j];
				else if(AlliedPlayers[j].pers["teamTime"] > MostRecent.pers["teamTime"])
					MostRecent = AlliedPlayers[j];
			}

			MostRecent [[level.onTeamSelection]]("axis");
		}
		else if(AxisPlayers.size > (AlliedPlayers.size + 1))
		{
			// Move the player that's been on the team the shortest ammount of time (highest teamTime value)
			for(j = 0; j < AxisPlayers.size; j++)
			{
				if(IsDefined(AxisPlayers[j].dont_auto_balance))
					continue;

				if(!IsDefined(MostRecent))
					MostRecent = AxisPlayers[j];
				else if(AxisPlayers[j].pers["teamTime"] > MostRecent.pers["teamTime"])
					MostRecent = AxisPlayers[j];
			}

			MostRecent [[level.onTeamSelection]]("allies");
		}

		MostRecent = undefined;
		AlliedPlayers = [];
		AxisPlayers = [];

		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			if((IsDefined(players[i].pers["team"])) && (players[i].pers["team"] == "allies"))
				AlliedPlayers[AlliedPlayers.size] = players[i];
			else if((IsDefined(players[i].pers["team"])) &&(players[i].pers["team"] == "axis"))
				AxisPlayers[AxisPlayers.size] = players[i];
		}
	}
}


setPlayerModels()
{
	// new way
	setTeamCharacterData();

	// for juggernauts
	game[ "allies_model" ][ "JUGGERNAUT" ] = mptype\mptype_ally_juggernaut::main;
	game[ "axis_model" ][ "JUGGERNAUT" ] = mptype\mptype_opforce_juggernaut::main;
	game[ "allies_model" ][ "JUGGERNAUT_MANIAC" ] = maps\mp\killstreaks\_juggernaut::setJuggManiac;
	game[ "axis_model" ][ "JUGGERNAUT_MANIAC" ] = maps\mp\killstreaks\_juggernaut::setJuggManiac;
}


playerModelForWeapon( weapon, secondary )
{
	// Not necessary. May need to revisit for ghillie with the new system	
}

CountPlayers()
{
	player_counts = [];

	for( i = 0; i < level.teamNameList.size; i++ )
	{
		player_counts[level.teamNameList[i]] = 0;
	}
	
	for( i = 0; i < level.players.size; i++ )
	{
		if( level.players[i] == self )
			continue;

		if( level.players[i].pers["team"] == "spectator" )
			continue;

		if( isdefined( level.players[i].pers["team"] ))
		{
			assert( isdefined( player_counts[level.players[i].pers["team"]] ));
			player_counts[level.players[i].pers["team"]]++;
		}
	}

	return player_counts;
}

addTeamCharacterHeadModel( teamType, headModel )
{
	level.headModels[ teamType ][ level.headModels[ teamType ].size ] = headModel;
}

addTeamCharacterBodyModel( teamType, bodyModel, clothType )
{
	level.bodyModels[ teamType ][ level.bodyModels[ teamType ].size ] = bodyModel;
	level.clothTypes[ teamType ][ level.clothTypes[ teamType ].size ] = clothType;
}

setTeamCharacterData()
{
	if( !IsDefined( level.headModels ) )
	{
		level.headModels = [];
		level.headModels[ "allies" ] = [];
		level.headModels[ "axis" ] = [];
		addTeamCharacterHeadModel( "allies", "head_mp_test_military_head_a" );
		addTeamCharacterHeadModel( "allies", "head_mp_test_military_head_aa" );
		addTeamCharacterHeadModel( "allies", "head_mp_test_military_head_k" );
		addTeamCharacterHeadModel( "allies", "head_mp_test_military_head_ka" );
		addTeamCharacterHeadModel( "allies", "head_mp_test_military_head_l" );
		addTeamCharacterHeadModel( "allies", "head_mp_test_military_head_la" );
		addTeamCharacterHeadModel( "allies", "head_mp_test_military_head_s" );

		addTeamCharacterHeadModel( "axis", "head_mp_test_pmc_head_a" );
		addTeamCharacterHeadModel( "axis", "head_mp_test_pmc_head_aa" );
		addTeamCharacterHeadModel( "axis", "head_mp_test_pmc_head_k" );
		addTeamCharacterHeadModel( "axis", "head_mp_test_pmc_head_ka" );
		addTeamCharacterHeadModel( "axis", "head_mp_test_pmc_head_l" );
		addTeamCharacterHeadModel( "axis", "head_mp_test_pmc_head_la" );
		addTeamCharacterHeadModel( "axis", "head_mp_test_pmc_head_s" );
	}

	if( !IsDefined( level.bodyModels ) )
	{
		level.bodyModels = [];
		level.bodyModels[ "allies" ] = [];
		level.bodyModels[ "axis" ] = [];

		level.clothTypes = [];
		level.clothTypes[ "allies" ] = [];
		level.clothTypes[ "axis" ] = [];

		// TODO: get base body models, right now we're going to use the urban as the base
		addTeamCharacterBodyModel( "allies", "body_mp_test_military_assault_a_urban", "vestlight" );
		addTeamCharacterBodyModel( "allies", "body_mp_test_military_assault_d_urban", "vestlight" );
		addTeamCharacterBodyModel( "allies", "body_mp_test_military_lmg_a_urban", "vestlight" );
		addTeamCharacterBodyModel( "allies", "body_mp_test_military_lmg_d_urban", "vestlight" );
		addTeamCharacterBodyModel( "allies", "body_mp_test_military_shotgun_a_urban", "vestlight" );
		addTeamCharacterBodyModel( "allies", "body_mp_test_military_shotgun_d_urban", "vestlight" );
		addTeamCharacterBodyModel( "allies", "body_mp_test_military_smg_a_urban", "vestlight" );

		addTeamCharacterBodyModel( "axis", "body_mp_test_pmc_assault_a_urban", "vestlight" );
		addTeamCharacterBodyModel( "axis", "body_mp_test_pmc_assault_d_urban", "vestlight" );
		addTeamCharacterBodyModel( "axis", "body_mp_test_pmc_lmg_a_urban", "vestlight" );
		addTeamCharacterBodyModel( "axis", "body_mp_test_pmc_lmg_d_urban", "vestlight" );
		addTeamCharacterBodyModel( "axis", "body_mp_test_pmc_shotgun_a_urban", "vestlight" );
		addTeamCharacterBodyModel( "axis", "body_mp_test_pmc_shotgun_d_urban", "vestlight" );
		addTeamCharacterBodyModel( "axis", "body_mp_test_pmc_smg_a_urban", "vestlight" );
	}

	if( !IsDefined( level.viewArmModels ) )
	{
		level.viewArmModels = [];
		level.viewArmModels[ "allies" ] = [];
		level.viewArmModels[ "axis" ] = [];

		level.viewArmModels[ "allies" ][ level.viewArmModels[ "allies" ].size ] = "viewhands_delta";
		level.viewArmModels[ "axis" ][ level.viewArmModels[ "axis" ].size ] = "viewhands_pmc";
	}

	if( !IsDefined( level.voices ) )
	{
		level.voices = [];
		level.voices[ "allies" ] = [];
		level.voices[ "axis" ] = [];

		level.voices[ "allies" ][ level.voices[ "allies" ].size ] = "delta";

		level.voices[ "axis" ][ level.voices[ "axis" ].size ] = "russian";
	}
}

playerModelFromPlayerData() // self == player
{
	team = self.team;

	entNum = self GetEntityNumber();

	// set a random model for the time being
	headId = entNum % level.headModels[ team ].size;
	bodyId = entNum % level.bodyModels[ team ].size;

	// body
	// get the model and add the outfit that the map has set
	body_model = level.bodyModels[ team ][ bodyId ];
	
	// TODO: This should pick the camo type depending on the team.
	// Currently it picks the outfit based on the team

	self SetModel( body_model );

	// cloth
	self SetClothType( level.clothTypes[ team ][ bodyId ] );
	// head
	self Attach( level.headModels[ team ][ headId ], "", true );
	self.headModel = level.headModels[ team ][ headId ];
	// view arms
	self SetViewModel( level.viewArmModels[ team ][ 0 ] );
	// voice
	self.voice = level.voices[ team ][ 0 ];

	if( IsBot( self ) && IsDefined( level.bot_funcs ) && IsDefined( level.bot_funcs["setup_appearance"] ) )
		self [[ level.bot_funcs["setup_appearance"] ]]( bodyId, headId );
	
	// set jugg stuff
	if( self isJuggernaut() )
	{
		if( IsDefined( self.isJuggernautManiac ) && self.isJuggernautManiac )
			[[game[team+"_model"]["JUGGERNAUT_MANIAC"]]]();
		else
			[[game[team+"_model"]["JUGGERNAUT"]]]();
	}
}

trackFreePlayedTime()
{
	self endon( "disconnect" );

	self.timePlayed["allies"] = 0;
	self.timePlayed["axis"] = 0;
	self.timePlayed["other"] = 0;
	self.timePlayed["total"] = 0;

	for ( ;; )
	{
		if ( game["state"] == "playing" )
		{
			if ( IsDefined( self.pers["team"] ) && self.pers["team"] == "allies" && self.sessionteam != "spectator" )
			{
				self.timePlayed["allies"]++;
				self.timePlayed["total"]++;
			}
			else if ( IsDefined( self.pers["team"] ) && self.pers["team"] == "axis" && self.sessionteam != "spectator" )
			{
				self.timePlayed["axis"]++;
				self.timePlayed["total"]++;
			}
			else
			{
				self.timePlayed["other"]++;
			}
		}

		wait ( 1.0 );
	}
}


/#
playerConnectedTest()
{
	if ( getdvarint( "scr_runlevelandquit" ) == 1 )
		return;
	
	level endon( "exitLevel_called" );
	
	// every frame, do a getPlayerData on each player in level.players.
	// this will force a script error if a player in level.players isn't connected.
	for ( ;; )
	{
		foreach ( player in level.players )
		{
			player getPlayerData( "experience" );
		}
		wait .05;
	}
}
#/


updateFreePlayerTimes()
{
	if ( !level.rankedmatch )
		return;
	
	/#
	thread playerConnectedTest();
	#/
	
	nextToUpdate = 0;
	for ( ;; )
	{
		nextToUpdate++;
		if ( nextToUpdate >= level.players.size )
			nextToUpdate = 0;

		if ( IsDefined( level.players[nextToUpdate] ) )
			level.players[nextToUpdate] updateFreePlayedTime();

		wait ( 1.0 );
	}
}


updateFreePlayedTime()
{
	if ( !self rankingEnabled() )
		return;

	// bots dont need this logic running and its one of the lowest hanging script performance costs
	if ( IsAI( self ) )
		return;
	
	if ( self.timePlayed["allies"] )
	{
		self maps\mp\gametypes\_persistence::statAddBuffered( "timePlayedAllies", self.timePlayed["allies"] );
		self maps\mp\gametypes\_persistence::statAddBuffered( "timePlayedTotal", self.timePlayed["allies"] );
		self maps\mp\gametypes\_persistence::statAddChildBuffered( "round", "timePlayed", self.timePlayed["allies"] );
		
		if ( !self.prestigeDoubleXp )
		{
			self maps\mp\gametypes\_persistence::statAddChildBufferedWithMax( "xpMultiplierTimePlayed", 0, self.timePlayed["allies"], self.bufferedChildStatsMax[ "xpMaxMultiplierTimePlayed" ][ 0 ] );
			self maps\mp\gametypes\_persistence::statAddChildBufferedWithMax( "xpMultiplierTimePlayed", 1, self.timePlayed["allies"], self.bufferedChildStatsMax[ "xpMaxMultiplierTimePlayed" ][ 1 ] );
			self maps\mp\gametypes\_persistence::statAddChildBufferedWithMax( "xpMultiplierTimePlayed", 2, self.timePlayed["allies"], self.bufferedChildStatsMax[ "xpMaxMultiplierTimePlayed" ][ 2 ] );
		}
		
		//IW5 Prestige 
		self maps\mp\gametypes\_persistence::statAddBufferedWithMax( "prestigeDoubleXpTimePlayed", self.timePlayed["allies"], self.bufferedStatsMax["prestigeDoubleXpMaxTimePlayed"] ); 
		self maps\mp\gametypes\_persistence::statAddBufferedWithMax( "prestigeDoubleWeaponXpTimePlayed", self.timePlayed["allies"], self.bufferedStatsMax["prestigeDoubleWeaponXpMaxTimePlayed"] ); 
	}

	if ( self.timePlayed["axis"] )
	{
		self maps\mp\gametypes\_persistence::statAddBuffered( "timePlayedOpfor", self.timePlayed["axis"] );
		self maps\mp\gametypes\_persistence::statAddBuffered( "timePlayedTotal", self.timePlayed["axis"] );
		self maps\mp\gametypes\_persistence::statAddChildBuffered( "round", "timePlayed", self.timePlayed["axis"] );
		
		if ( !self.prestigeDoubleXp )
		{
			self maps\mp\gametypes\_persistence::statAddChildBufferedWithMax( "xpMultiplierTimePlayed", 0, self.timePlayed["axis"], self.bufferedChildStatsMax[ "xpMaxMultiplierTimePlayed" ][ 0 ] );
			self maps\mp\gametypes\_persistence::statAddChildBufferedWithMax( "xpMultiplierTimePlayed", 1, self.timePlayed["axis"], self.bufferedChildStatsMax[ "xpMaxMultiplierTimePlayed" ][ 1 ] );
			self maps\mp\gametypes\_persistence::statAddChildBufferedWithMax( "xpMultiplierTimePlayed", 2, self.timePlayed["axis"], self.bufferedChildStatsMax[ "xpMaxMultiplierTimePlayed" ][ 2 ] );
		}
		
		//IW5 Prestige
		self maps\mp\gametypes\_persistence::statAddBufferedWithMax( "prestigeDoubleXpTimePlayed", self.timePlayed["axis"], self.bufferedStatsMax["prestigeDoubleXpMaxTimePlayed"] ); 
		self maps\mp\gametypes\_persistence::statAddBufferedWithMax( "prestigeDoubleWeaponXpTimePlayed", self.timePlayed["axis"], self.bufferedStatsMax["prestigeDoubleWeaponXpMaxTimePlayed"] ); 
	}

	if ( self.timePlayed["other"] )
	{
		self maps\mp\gametypes\_persistence::statAddBuffered( "timePlayedOther", self.timePlayed["other"] );
		self maps\mp\gametypes\_persistence::statAddBuffered( "timePlayedTotal", self.timePlayed["other"] );
		self maps\mp\gametypes\_persistence::statAddChildBuffered( "round", "timePlayed", self.timePlayed["other"] );
		
		if ( !self.prestigeDoubleXp )
		{
			self maps\mp\gametypes\_persistence::statAddChildBufferedWithMax( "xpMultiplierTimePlayed", 0, self.timePlayed["other"], self.bufferedChildStatsMax[ "xpMaxMultiplierTimePlayed" ][ 0 ] );
			self maps\mp\gametypes\_persistence::statAddChildBufferedWithMax( "xpMultiplierTimePlayed", 1, self.timePlayed["other"], self.bufferedChildStatsMax[ "xpMaxMultiplierTimePlayed" ][ 1 ] );
			self maps\mp\gametypes\_persistence::statAddChildBufferedWithMax( "xpMultiplierTimePlayed", 2, self.timePlayed["other"], self.bufferedChildStatsMax[ "xpMaxMultiplierTimePlayed" ][ 2 ] );
		}
		
		//IW5 Prestige
		self maps\mp\gametypes\_persistence::statAddBufferedWithMax( "prestigeDoubleXpTimePlayed", self.timePlayed["other"], self.bufferedStatsMax["prestigeDoubleXpMaxTimePlayed"] ); 
		self maps\mp\gametypes\_persistence::statAddBufferedWithMax( "prestigeDoubleWeaponXpTimePlayed", self.timePlayed["other"], self.bufferedStatsMax["prestigeDoubleWeaponXpMaxTimePlayed"] ); 
	}

	if ( game["state"] == "postgame" )
		return;

	self.timePlayed["allies"] = 0;
	self.timePlayed["axis"] = 0;
	self.timePlayed["other"] = 0;
}


getJoinTeamPermissions( team )
{
	if ( GetDvar( "g_gametype" ) == "aliens" )
		return true;
	
	teamcount = 0;
	botcount = 0;

	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];

		if((IsDefined(player.pers["team"])) && (player.pers["team"] == team))
		{
			teamcount++;
			
			if( IsBot( player ) )
				botcount++;
		}
	}

	if( teamCount < level.teamLimit )
		return true;
	else if ( botcount > 0 ) 	// If team is full but has bots, still allow human player on
		return true;
	else
		return false;
}


onPlayerSpawned()
{
	level endon ( "game_ended" );

	for ( ;; )
	{
		self waittill ( "spawned_player" );
	}
}

MT_getTeamName( teamRef )
{
	return ( tableLookupIString( "mp/MTTable.csv", MT_REF_COL, teamRef, MT_NAME_COL ));
}

MT_getTeamIcon( teamRef )
{
	return ( tableLookup( "mp/MTTable.csv", MT_REF_COL, teamRef, MT_ICON_COL ));
}

MT_getTeamHeadIcon( teamRef )
{
	return ( tableLookup( "mp/MTTable.csv", MT_REF_COL, teamRef, MT_HEAD_ICON_COL ));	
}

getTeamName( teamRef )
{
	return ( tableLookupIString( "mp/factionTable.csv", FACTION_REF_COL, game[teamRef], FACTION_NAME_COL ) );
}

getTeamShortName( teamRef )
{
	return ( tableLookupIString( "mp/factionTable.csv", FACTION_REF_COL, game[teamRef], FACTION_SHORT_NAME_COL ) );
}

getTeamForfeitedString( teamRef )
{
	return ( tableLookupIString( "mp/factionTable.csv", FACTION_REF_COL, game[teamRef], FACTION_FORFEITED_COL ) );
}

getTeamEliminatedString( teamRef )
{
	return ( tableLookupIString( "mp/factionTable.csv", FACTION_REF_COL, game[teamRef], FACTION_ELIMINATED_COL ) );
}

getTeamIcon( teamRef )
{
	return ( tableLookup( "mp/factionTable.csv", FACTION_REF_COL, game[teamRef], FACTION_ICON_COL ) );
}

getTeamHudIcon( teamRef )
{
	return ( tableLookup( "mp/factionTable.csv", FACTION_REF_COL, game[teamRef], FACTION_HUD_ICON_COL ) );
}

getTeamHeadIcon( teamRef )
{
	return ( tableLookup( "mp/factionTable.csv", FACTION_REF_COL, game[teamRef], FACTION_HEAD_ICON_COL ) );
}

getTeamVoicePrefix( teamRef )
{
	return ( tableLookup( "mp/factionTable.csv", FACTION_REF_COL, game[teamRef], FACTION_VOICE_PREFIX_COL ) );
}

getTeamSpawnMusic( teamRef )
{
	return ( tableLookup( "mp/factionTable.csv", FACTION_REF_COL, game[teamRef], FACTION_SPAWN_MUSIC_COL ) );
}

getTeamWinMusic( teamRef )
{
	return ( tableLookup( "mp/factionTable.csv", FACTION_REF_COL, game[teamRef], FACTION_WIN_MUSIC_COL ) );
}

getTeamFlagModel( teamRef )
{
	return ( tableLookup( "mp/factionTable.csv", FACTION_REF_COL, game[teamRef], FACTION_FLAG_MODEL_COL ) );
}

getTeamFlagCarryModel( teamRef )
{
	return ( tableLookup( "mp/factionTable.csv", FACTION_REF_COL, game[teamRef], FACTION_FLAG_CARRY_MODEL_COL ) );
}

getTeamFlagIcon( teamRef )
{
	return ( tableLookup( "mp/factionTable.csv", FACTION_REF_COL, game[teamRef], FACTION_FLAG_ICON_COL ) );
}

getTeamFlagFX( teamRef )
{
	return ( tableLookup( "mp/factionTable.csv", FACTION_REF_COL, game[teamRef], FACTION_FLAG_FX_COL ) );
}

getTeamColor( teamRef )
{
	return ( (stringToFloat( tableLookup( "mp/factionTable.csv", FACTION_REF_COL, game[teamRef], FACTION_COLOR_R_COL ) ),
				stringToFloat( tableLookup( "mp/factionTable.csv", FACTION_REF_COL, game[teamRef], FACTION_COLOR_G_COL ) ),
				stringToFloat( tableLookup( "mp/factionTable.csv", FACTION_REF_COL, game[teamRef], FACTION_COLOR_B_COL ) ))
			);
}

getTeamCrateModel( teamRef )
{
	return ( tableLookup( "mp/factionTable.csv", FACTION_REF_COL, game[teamRef], FACTION_CRATE_MODEL_COL ) );	
}

getTeamDeployModel( teamRef )
{
	return ( tableLookup( "mp/factionTable.csv", FACTION_REF_COL, game[teamRef], FACTION_DEPLOY_MODEL_COL ) );	
}
