#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

// we want normalized weapon xp kill points regardless of game mode
WEAPONXP_KILL =	100;

HACK_MAX_PRESTIGE_PRECACHE = 10;	// hack for config string patch

STATS_TABLE = "mp/statsTable.csv";
RANK_TABLE = "mp/rankTable.csv";
RANK_ICON_TABLE = "mp/rankIconTable.csv";
WEAPON_RANK_TABLE = "mp/weaponRankTable.csv";

init()
{
	level.scoreInfo = [];
	level.xpScale = getDvarInt( "scr_xpscale" );
	
	if ( level.xpScale > 4 || level.xpScale < 0)
		exitLevel( false );

	level.xpScale = min( level.xpScale, 4 );
	level.xpScale = max( level.xpScale, 0 );
	
	level.teamXPScale["axis"] 	= 1;
	level.teamXPScale["allies"] = 1;

	level.rankTable = [];
	level.weaponRankTable = [];

	precacheShader("white");

	precacheString( &"RANK_PLAYER_WAS_PROMOTED_N" );
	precacheString( &"RANK_PLAYER_WAS_PROMOTED" );
	precacheString( &"RANK_WEAPON_WAS_PROMOTED" );
	precacheString( &"RANK_PROMOTED" );
	precacheString( &"RANK_PROMOTED_WEAPON" );
	precacheString( &"MP_MINUS" );
	precacheString( &"MP_PLUS" );
	precacheString( &"RANK_ROMANI" );
	precacheString( &"RANK_ROMANII" );
	precacheString( &"RANK_ROMANIII" );
	
	precacheString( &"SPLASHES_LONGSHOT" );
	precacheString( &"SPLASHES_PROXIMITYASSIST" );
	precacheString( &"SPLASHES_PROXIMITYKILL" );
	precacheString( &"SPLASHES_EXECUTION" );	
	precacheString( &"SPLASHES_AVENGER" );	
	precacheString( &"SPLASHES_ASSISTEDSUICIDE" );	
	precacheString( &"SPLASHES_DEFENDER" );	
	precacheString( &"SPLASHES_POSTHUMOUS" );	
	precacheString( &"SPLASHES_REVENGE" );	
	precacheString( &"SPLASHES_DOUBLEKILL" );	
	precacheString( &"SPLASHES_TRIPLEKILL" );	
	precacheString( &"SPLASHES_MULTIKILL" );			
	precacheString( &"SPLASHES_BUZZKILL" );	
	precacheString( &"SPLASHES_COMEBACK" );
	precacheString( &"SPLASHES_KNIFETHROW" );
	precacheString( &"SPLASHES_ONE_SHOT_KILL" );	

	if ( level.teamBased )
	{
		registerScoreInfo( "kill", 100 );
		registerScoreInfo( "headshot", 100 );
		registerScoreInfo( "assist", 20 );
		registerScoreInfo( "proximityassist", 20 );
		registerScoreInfo( "proximitykill", 20 );
		registerScoreInfo( "suicide", 0 );
		registerScoreInfo( "teamkill", 0 );
	}
	else
	{
		registerScoreInfo( "kill", 50 );
		registerScoreInfo( "headshot", 50 );
		registerScoreInfo( "assist", 0 );
		registerScoreInfo( "suicide", 0 );
		registerScoreInfo( "teamkill", 0 );
	}
	
	registerScoreInfo( "win", 1 );
	registerScoreInfo( "loss", 0.5 );
	registerScoreInfo( "tie", 0.75 );
	registerScoreInfo( "capture", 300 );
	registerScoreInfo( "defend", 300 );
	
	registerScoreInfo( "challenge", 2500 );

	level.maxRank = int(tableLookup( RANK_TABLE, 0, "maxrank", 1 ));
	level.maxPrestige = int(tableLookup( RANK_TABLE, 0, "maxprestige", 1 ));

	pId = 0;
	rId = 0;
	for ( pId = 0; pId <= min( HACK_MAX_PRESTIGE_PRECACHE, level.maxPrestige ); pId++ )
	{
		for ( rId = 0; rId <= level.maxRank; rId++ )
			precacheShader( tableLookup( RANK_ICON_TABLE, 0, rId, pId+1 ) );
	}

	rankId = 0;
	rankName = tableLookup( RANK_TABLE, 0, rankId, 1 );
	assert( IsDefined( rankName ) && rankName != "" );
		
	while ( IsDefined( rankName ) && rankName != "" )
	{
		level.rankTable[rankId][1] = tableLookup( RANK_TABLE, 0, rankId, 1 );
		level.rankTable[rankId][2] = tableLookup( RANK_TABLE, 0, rankId, 2 );
		level.rankTable[rankId][3] = tableLookup( RANK_TABLE, 0, rankId, 3 );
		level.rankTable[rankId][7] = tableLookup( RANK_TABLE, 0, rankId, 7 );

		precacheString( tableLookupIString( RANK_TABLE, 0, rankId, 16 ) );

		rankId++;
		rankName = tableLookup( RANK_TABLE, 0, rankId, 1 );		
	}

	weaponMaxRank = int(tableLookup( WEAPON_RANK_TABLE, 0, "maxrank", 1 ));
	for( i = 0; i < weaponMaxRank + 1; i++ )
	{
		level.weaponRankTable[i][1] = tableLookup( WEAPON_RANK_TABLE, 0, i, 1 );
		level.weaponRankTable[i][2] = tableLookup( WEAPON_RANK_TABLE, 0, i, 2 );
		level.weaponRankTable[i][3] = tableLookup( WEAPON_RANK_TABLE, 0, i, 3 );
	}

	maps\mp\gametypes\_missions::buildChallegeInfo();

	level thread patientZeroWaiter();
	
	level thread onPlayerConnect();

/#
	SetDevDvarIfUninitialized( "scr_devweaponxpmult", "0" );
	SetDevDvarIfUninitialized( "scr_devsetweaponmaxrank", "0" );

	level thread watchDevDvars();
#/
}

patientZeroWaiter()
{
	level endon( "game_ended" );
	
	while ( !IsDefined( level.players ) || !level.players.size )
		wait ( 0.05 );
	
	if ( !matchMakingGame() )
	{
		if ( (getDvar( "mapname" ) == "mp_rust" && randomInt( 1000 ) == 999) )
			level.patientZeroName = level.players[0].name;
	}
	else
	{
		if ( getDvar( "scr_patientZero" ) != "" )
			level.patientZeroName = getDvar( "scr_patientZero" );
	}
}

isRegisteredEvent( type )
{
	if ( IsDefined( level.scoreInfo[ type ] ) )
		return true;
	else
		return false;
}


registerScoreInfo( type, value )
{
	level.scoreInfo[ type ][ "value" ] = value;
}


getScoreInfoValue( type )
{
	overrideDvar = "scr_" + level.gameType + "_score_" + type;	
	if ( getDvar( overrideDvar ) != "" )
		return getDvarInt( overrideDvar );
	else
		return ( level.scoreInfo[ type ][ "value" ] );
}


getScoreInfoLabel( type )
{
	return ( level.scoreInfo[ type ][ "label" ] );
}


getRankInfoMinXP( rankId )
{
	return int( level.rankTable[ rankId ][ 2 ] );
}

getWeaponRankInfoMinXP( rankId )
{
	return int( level.weaponRankTable[ rankId ][ 1 ] );
}

getRankInfoXPAmt( rankId )
{
	return int( level.rankTable[ rankId ][ 3 ] );
}

getWeaponRankInfoXPAmt( rankId )
{
	return int( level.weaponRankTable[ rankId ][ 2 ] );
}

getRankInfoMaxXP( rankId )
{
	return int( level.rankTable[ rankId ][ 7 ] );
}

getWeaponRankInfoMaxXp( rankId )
{
	return int( level.weaponRankTable[ rankId ][ 3 ] );
}

getRankInfoFull( rankId )
{
	return tableLookupIString( RANK_TABLE, 0, rankId, 16 );
}


getRankInfoIcon( rankId, prestigeId )
{
	return tableLookup( RANK_ICON_TABLE, 0, rankId, prestigeId+1 );
}

getRankInfoLevel( rankId )
{
	return int( tableLookup( RANK_TABLE, 0, rankId, 13 ) );
}


onPlayerConnect()
{
	for(;;)
	{
		level waittill( "connected", player );

		/#
		if ( getDvarInt( "scr_forceSequence" ) )
			player setPlayerData( "experience", 145499 );
		#/
		
		// old way with overrall xp
		//player.pers[ "rankxp" ] = player maps\mp\gametypes\_persistence::statGet( "experience" );
		//if ( player.pers[ "rankxp" ] < 0 ) // paranoid defensive
		//	player.pers[ "rankxp" ] = 0;
		//
		//rankId = player getRankForXp( player getRankXP() );
		//player.pers[ "rank" ] = rankId;
		//
		//prestige = player getPrestigeLevel();
		//player setRank( rankId, prestige );
		//player.pers["prestige"] = prestige;
		//
		//if ( player.clientid < level.MaxLogClients )
		//{
		//	setMatchData( "players", player.clientid, "rank", rankId );
		//	setMatchData( "players", player.clientid, "Prestige", prestige );
		//}

		player.pers[ "participation" ] = 0;

		player.xpUpdateTotal = 0;
		player.bonusUpdateTotal = 0;

		player.postGamePromotion = false;
		if ( !IsDefined( player.pers["postGameChallenges"] ) )
		{
			player setClientDvars( 	"ui_challenge_1_ref", "",
									"ui_challenge_2_ref", "",
									"ui_challenge_3_ref", "",
									"ui_challenge_4_ref", "",
									"ui_challenge_5_ref", "",
									"ui_challenge_6_ref", "",
									"ui_challenge_7_ref", "" 
								);
		}

		player setClientDvar( 	"ui_promotion", 0 );
		
		if ( !IsDefined( player.pers["summary"] ) )
		{
			player.pers["summary"] = [];
			player.pers["summary"]["xp"] = 0;
			player.pers["summary"]["score"] = 0;
			player.pers["summary"]["challenge"] = 0;
			player.pers["summary"]["match"] = 0;
			player.pers["summary"]["misc"] = 0;

			// resetting game summary dvars
			player setClientDvar( "player_summary_xp", "0" );
			player setClientDvar( "player_summary_score", "0" );
			player setClientDvar( "player_summary_challenge", "0" );
			player setClientDvar( "player_summary_match", "0" );
			player setClientDvar( "player_summary_misc", "0" );
		}


		// resetting summary vars
		
		player setClientDvar( "ui_opensummary", 0 );
		
		player thread maps\mp\gametypes\_missions::updateChallenges();
		player.explosiveKills[0] = 0;
		player.xpGains = [];
		
		player.hud_xpPointsPopup = player createXpPointsPopup();
		player.hud_xpEventPopup = player createXpEventPopup();

		player thread onPlayerSpawned();
		player thread onJoinedTeam();
		player thread onJoinedSpectators();
		player thread setGamesPlayed();
		player thread onPlayerGiveLoadout();

		//sets double XP on player var
		if ( player GetPlayerData("prestigeDoubleXp") )
			player.prestigeDoubleXp = true;
		else
			player.prestigeDoubleXp = false;
			
		//sets double Weapon XP on player var
		if ( player GetPlayerData("prestigeDoubleWeaponXp") )
			player.prestigeDoubleWeaponXp = true;
		else
			player.prestigeDoubleWeaponXp = false;
				
	}
}

setGamesPlayed()
{
	self endon ( "disconnect" );
	
	for( ;; )
	{
		wait(30);
		
		if ( !self.hasDoneCombat )	
			continue;
			
		self maps\mp\gametypes\_persistence::statAdd("gamesPlayed", 1 );
		break; 
	}	
}

onJoinedTeam()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill( "joined_team" );
		self thread removeRankHUD();
	}
}


onJoinedSpectators()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill( "joined_spectators" );
		self thread removeRankHUD();
	}
}


onPlayerSpawned()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill( "spawned_player" );
		
		// new way with individual character xp

		if( !level.rankedMatch )
		{
			self.pers[ "rankxp" ] = 0;
		}
		else
		{
			AssertEx( IsDefined( self.class ), "Player should have class here." );
			if( !IsAI( self ) )
			{
				AssertEx( IsDefined( self.class_num ), "Player should have class_num here." );
				self.pers[ "rankxp" ] = self GetPlayerData( "characterXP", self.class_num );
				PrintLn( "player -> " + self.name + " spawned character -> " + self.class_num + " with characterXP -> " + self.pers[ "rankxp" ] + "." );
			}
			else
			{
				self.pers[ "rankxp" ] = self get_rank_xp_for_bot();
			}
		}

		if ( self.pers[ "rankxp" ] < 0 ) // paranoid defensive
			self.pers[ "rankxp" ] = 0;

		rankId = self getRankForXp( self getRankXP() );
		self.pers[ "rank" ] = rankId;

		prestige = self getPrestigeLevel();
		self setRank( rankId, prestige );
		self.pers["prestige"] = prestige;

		if ( self.clientid < level.MaxLogClients )
		{
			setMatchData( "players", self.clientid, "rank", rankId );
			setMatchData( "players", self.clientid, "Prestige", prestige );
		}
	}
}

onPlayerGiveLoadout() // self == player
{
	self endon( "disconnect" );

	while( true )
	{
		self waittill_any( "giveLoadout", "changed_kit" );

		// since you still have a chance to change your class during the grace period, we need to make sure the character xp stays legit
		//	this should fix an xp regression issue we were having when you changed you class during the grace period
		AssertEx( IsDefined( self.class ), "Player should have class here." );
		if( IsSubStr( self.class, "custom" ) )
		{
			if( !level.rankedMatch )
			{
				self.pers[ "rankxp" ] = 0;
			}
			else
			{
				if( IsAI( self ) )
					self.pers[ "rankxp" ] = 0;
				else
				{
					AssertEx( IsDefined( self.class_num ), "Player should have class_num here." );
					self.pers[ "rankxp" ] = self GetPlayerData( "characterXP", self.class_num );
					PrintLn( "player -> " + self.name + " got loadout for character -> " + self.class_num + " with characterXP -> " + self.pers[ "rankxp" ] + "." );
				}
			}
		}
	}
}

roundUp( floatVal )
{
	if ( int( floatVal ) != floatVal )
		return int( floatVal+1 );
	else
		return int( floatVal );
}

giveRankXP( type, value, weapon, sMeansOfDeath, challengeName, victim )
{
	self endon("disconnect");
	
	lootType = "none";
	
	if ( IsDefined(self.owner) && !IsBot( self ) )
	{
		// Call this function on the player's owner instead
		self.owner giveRankXP( type, value, weapon, sMeansOfDeath, challengeName, victim );
	}
		
	if ( !IsBot( self ) )
	{
		//If a player is commanding a bot, give the credit to the bot, not the player
		if ( IsDefined( self.commanding_bot ) )
		{
			//also give it to the bot
			self.commanding_bot giveRankXP( type, value, weapon, sMeansOfDeath, challengeName, victim );
		}
	}

	if ( !IsPlayer(self) )
		return;
	
	if ( !self rankingEnabled() )
	{
		if ( type == "assist" )
		{
			if ( IsDefined( self.taggedAssist ) )
				self.taggedAssist = undefined;
			else
			{
				assist_string = &"MP_ASSIST";
				if( self _hasPerk( "specialty_assists" ) )
				{
					if( !( self.pers["assistsToKill"] % 2 ) )
					{
						assist_string = &"MP_ASSIST_TO_KILL";
					}
				}
				self thread maps\mp\gametypes\_rank::xpEventPopup( assist_string );
			}
		}
		return;
	}
	
	//exit conditions
    if( level.multiTeamBased )
	{
		numteams = 0;
		for( i = 0; i < level.teamNameList.size; i++ )
		{
			if( level.teamCount[level.teamNameList[i]] )
			{
				numteams = numteams + 1;
			}
		}
		if( numteams < 2 )
		{
			return;
		}
	}
	else if ( level.teamBased && (!level.teamCount["allies"] || !level.teamCount["axis"]) )
		return;
	else if ( !level.teamBased && (level.teamCount["allies"] + level.teamCount["axis"] < 2) )
		return;
	else if ( IsDefined( level.disableRanking ) && level.disableRanking )
		return;
	
	if ( !IsDefined( value ) )
		value = getScoreInfoValue( type );
	
	if ( !IsDefined( self.xpGains[type] ) )
		self.xpGains[type] = 0;

	modifiedValue = value;
	
	if( IsDefined( victim ) && getTimePassed() > ( 60 * 1000 ) * 1.5 ) // only do this once the match has gone for a little while
	{
		attacker = self;

		if( level.teamBased )
		{
			// give extra xp if the victim is higher level than the attacker, meaning they have a higher match score
			enemies_sorted_by_rank = array_sort_with_func( level.teamList[ getOtherTeam( attacker.team ) ], ::is_score_a_greater_than_b );
			friendlies_sorted_by_rank = array_sort_with_func( level.teamList[ attacker.team ], ::is_score_a_greater_than_b );
			if( IsDefined( enemies_sorted_by_rank[ 0 ] ) && victim == enemies_sorted_by_rank[ 0 ] )
			{
				// now check to see if the attacker is at least two ranks below
				if( IsDefined( friendlies_sorted_by_rank[ 1 ] ) && attacker.score < friendlies_sorted_by_rank[ 1 ].score )
				{
					modifiedValue *= 2.0;
					attacker thread xpEventPopup( &"MP_FIRST_PLACE_KILL" );
				}
			}
			else if( IsDefined( enemies_sorted_by_rank[ 1 ] ) && victim == enemies_sorted_by_rank[ 1 ] )
			{
				// now check to see if the attacker is at least two ranks below
				if( IsDefined( friendlies_sorted_by_rank[ 2 ] ) && attacker.score < friendlies_sorted_by_rank[ 2 ].score )
				{
					modifiedValue *= 1.5;
					attacker thread xpEventPopup( &"MP_SECOND_PLACE_KILL" );
				}
			}
		}
		else // ffa
		{
			// give extra xp if the victim is higher level than the attacker, meaning they have a higher match score
			enemies_sorted_by_rank = array_sort_with_func( level.players, ::is_score_a_greater_than_b );
			if( IsDefined( enemies_sorted_by_rank[ 0 ] ) && victim == enemies_sorted_by_rank[ 0 ] )
			{
				// now check to see if the attacker is at least two ranks below
				if( IsDefined( enemies_sorted_by_rank[ 1 ] ) && attacker.score < enemies_sorted_by_rank[ 1 ].score )
				{
					modifiedValue *= 2.0;
					attacker thread xpEventPopup( &"MP_FIRST_PLACE_KILL" );
				}
			}
			else if( IsDefined( enemies_sorted_by_rank[ 1 ] ) && victim == enemies_sorted_by_rank[ 1 ] )
			{
				// now check to see if the attacker is at least two ranks below
				if( IsDefined( enemies_sorted_by_rank[ 2 ] ) && attacker.score < enemies_sorted_by_rank[ 2 ].score )
				{
					modifiedValue *= 1.5;
					attacker thread xpEventPopup( &"MP_SECOND_PLACE_KILL" );
				}
			}
			else if( IsDefined( enemies_sorted_by_rank[ 2 ] ) && victim == enemies_sorted_by_rank[ 2 ] )
			{
				// now check to see if the attacker is at least ranked lower than third
				if( IsDefined( enemies_sorted_by_rank[ 2 ] ) && attacker.score < enemies_sorted_by_rank[ 2 ].score )
				{
					modifiedValue *= 1.5;
					attacker thread xpEventPopup( &"MP_THIRD_PLACE_KILL" );
				}
			}
		}
		
		// give extra xp for streaking
		cur_kill_streak = attacker.pers[ "cur_kill_streak" ];
		if( cur_kill_streak > 2 )
		{
			// do a callout every 5 kill streak
			if( !( cur_kill_streak % 5 ) )
				attacker thread teamPlayerCardSplash( "callout_kill_streaking", attacker, undefined, cur_kill_streak );
		}
	}

	momentumBonus = 0;
	gotRestXP = false;
	
	switch( type )
	{
		case "kill":
		case "headshot":
		case "shield_damage":
			modifiedValue *= self.xpScaler;
		case "assist":
		case "suicide":
		case "teamkill":
		case "capture":
		case "defend":
		case "obj_return":
		case "pickup":
		case "assault":
		case "plant":
		case "destroy":
		case "save":
		case "defuse":
		case "kill_confirmed":
		case "kill_denied":
		case "tags_retrieved":
		case "team_assist":
		case "kill_bonus":
		case "kill_carrier":
		case "draft_rogue":
		case "survivor":
		case "final_rogue":
		case "gained_gun_rank":
		case "dropped_enemy_gun_rank":
		case "got_juggernaut":
		case "kill_as_juggernaut":
		case "kill_juggernaut":
		case "jugg_on_jugg":
		case "team_restock":
			if ( getGametypeNumLives() > 0 && type != "shield_damage" )
			{
				multiplier = max(1,int( 10/getGametypeNumLives() ));
				modifiedValue = int(modifiedValue * multiplier);
			}
			
			// do we have an entitlement or prestige-award to give us an additional xp multiplier
			entitlement_xp = 0;
			prestigeBonus_xp = 0;
			
			if ( self.prestigeDoubleXp )
			{
				howMuchTimePlayed = self GetPlayerData( "prestigeDoubleXpTimePlayed" );
				if ( howMuchTimePlayed >= self.bufferedStatsMax["prestigeDoubleXpMaxTimePlayed"] )
				{
					self setPlayerData( "prestigeDoubleXp", false );
					self setPlayerData( "prestigeDoubleXpTimePlayed", 0 );
					self setPlayerData( "prestigeDoubleXpMaxTimePlayed", 0 );
					self.prestigeDoubleXp = false;
				}
				else	
				{				
					prestigeBonus_xp = 2;
				}
			}
			
			//allow entitlement doubleXp if no prestige double xp
			if ( !self.prestigeDoubleXp )
			{
				for ( i = 0; i < 3; i++ )
				{
					if ( self GetPlayerData( "xpMultiplierTimePlayed", i) < self.bufferedChildStatsMax[ "xpMaxMultiplierTimePlayed" ][ i ] )
					{
						entitlement_xp += int( self GetPlayerData( "xpMultiplier", i) );
					}
				}
			}
			
			if ( prestigeBonus_xp > 0 ) //we do have prestige bonus
			{
				modifiedValue = int( modifiedValue * prestigeBonus_xp );
			}
			else if ( entitlement_xp > 0 ) //we do have an entitlement xp multiplier
			{
				modifiedValue = int( modifiedValue * entitlement_xp );
			}
			
			modifiedValue = int( modifiedValue * level.xpScale * level.teamXPScale[self.team] ) ;	
			
			
			// if the nuke has been detonated, give that team or player an xp boost
			if( IsDefined( level.nukeDetonated ) && level.nukeDetonated )
			{
				if( level.teamBased && level.nukeInfo.team == self.team )
					modifiedValue *= level.nukeInfo.xpScalar;
				else if( !level.teamBased && level.nukeInfo.player == self )
					modifiedValue *= level.nukeInfo.xpScalar;
			
				modifiedValue = int( modifiedValue );
			}
				
			/#
			AssertEx( (modifiedValue < 100000), "Tried to award "+ self.name +"over 100000 XP: " + modifiedValue );
			#/
			
			restXPAwarded = getRestXPAward( modifiedValue );
			modifiedValue += restXPAwarded;
			if ( restXPAwarded > 0 )
			{
				if ( isLastRestXPAward( modifiedValue ) )
					thread maps\mp\gametypes\_hud_message::splashNotify( "rested_done" );

				gotRestXP = true;
			}
			break;
		case "challenge":
			entitlement_xp = 0;
			if ( self GetPlayerData( "challengeXPMultiplierTimePlayed", 0 ) < self.bufferedChildStatsMax[ "challengeXPMaxMultiplierTimePlayed" ][ 0 ] )
			{
				entitlement_xp += int( self GetPlayerData( "challengeXPMultiplier", 0 ) );
				if ( entitlement_xp > 0 )
					modifiedValue = int( modifiedValue * entitlement_xp );
			}

			break;
	}
	
	if ( !gotRestXP )
	{
		// if we didn't get rest XP for this type, we push the rest XP goal ahead so we didn't waste it
		if ( self GetPlayerData( "restXPGoal" ) > self getRankXP() )
			self setPlayerData( "restXPGoal", self GetPlayerData( "restXPGoal" ) + modifiedValue );
	}
	
	oldxp = self getRankXP();
	self.xpGains[type] += modifiedValue;
	
	self incRankXP( modifiedValue );

	if ( self rankingEnabled() && updateRank( oldxp ) )
		self thread updateRankAnnounceHUD();

	// Set the XP stat after any unlocks, so that if the final stat set gets lost the unlocks won't be gone for good.
	self syncXPStat();

	// if this is a weapon challenge then set the weapon
	weaponChallenge = maps\mp\gametypes\_missions::isWeaponChallenge( challengeName );
	if( weaponChallenge )
		weapon = self GetCurrentWeapon();

	// riot shield gives xp for taking shield damage
	if( type == "shield_damage" )
	{
		weapon = self GetCurrentWeapon();
		sMeansOfDeath = "MOD_MELEE";
	}
	
	//////////////////////////////////////////////////////////////
	// WEAPON RANKING
	// check for weapon xp gains, they need to have cac unlocked before we start weapon xp gains
	if( weaponShouldGetXP( weapon, sMeansOfDeath ) || weaponChallenge ) 
	{
		// we just want the weapon name up to the first underscore
		weaponTokens = StrTok( weapon, "_" );
		//curWeapon = self GetCurrentWeapon();
		
		if ( weaponTokens[0] == "iw5" || weaponTokens[0] == "iw6" )
			weaponName = weaponTokens[0] + "_" + weaponTokens[1];
		else if ( weaponTokens[0] == "alt" )
			weaponName = weaponTokens[1] + "_" + weaponTokens[2];
		else
			weaponName = weaponTokens[0];
		
		if( weaponTokens[0] == "gl" )
			weaponName = weaponTokens[1];

		if( /*IsDefined( curWeapon ) && curWeapon == weapon &&*/ self IsItemUnlocked( weaponName ) )
		{
			// is the weapon their class loadout weapon or a weapon they picked up?
			if( self.primaryWeapon == weapon || 
				self.secondaryWeapon == weapon || 
				WeaponAltWeaponName( self.primaryWeapon ) == weapon ||
				( IsDefined( self.tookWeaponFrom ) && IsDefined( self.tookWeaponFrom[ weapon ] ) ) )
			{
				oldWeaponXP = self getWeaponRankXP( weaponName );
				
				// we want normalized weapon xp kill points regardless of game mode
				switch( type )
				{
				case "kill":
					modifiedWeaponValue = WEAPONXP_KILL;				
					break;
				default:
					modifiedWeaponValue = value;
					break;
				}
/#
				if( GetDvarInt( "scr_devweaponxpmult" ) > 0 )
					modifiedWeaponValue *= GetDvarInt( "scr_devweaponxpmult" );
#/
				//IW5 Prestige bonus weapon XP
				if ( self.prestigeDoubleWeaponXp )
				{
					howMuchWeaponXPTimePlayed = self GetPlayerData( "prestigeDoubleWeaponXpTimePlayed" );
					if ( howMuchWeaponXPTimePlayed >= self.bufferedStatsMax["prestigeDoubleWeaponXpMaxTimePlayed"] )
					{
						self setPlayerData( "prestigeDoubleWeaponXp", false );
						self setPlayerData( "prestigeDoubleWeaponXpTimePlayed", 0 );
						self setPlayerData( "prestigeDoubleWeaponXpMaxTimePlayed", 0 );
						self.prestigeDoubleWeaponXp = false;
					}
					else	
					{				
						modifiedWeaponValue *= 2;
					}
				}

				if ( self GetPlayerData( "weaponXPMultiplierTimePlayed", 0 ) < self.bufferedChildStatsMax[ "weaponXPMaxMultiplierTimePlayed" ][ 0 ] )
				{
					weaponXPMult = int( self GetPlayerData( "weaponXPMultiplier", 0 ) );
					if ( weaponXPMult > 0 )
						modifiedWeaponValue *= weaponXPMult;
				}
				
				newWeaponXP = oldWeaponXP + modifiedWeaponValue;

				if( !isWeaponMaxRank( weaponName ) )
				{
					// make sure we don't give more than the max xp
					weaponMaxRankXP = getWeaponMaxRankXP( weaponName );
					if( newWeaponXP > weaponMaxRankXP )
					{
						newWeaponXP = weaponMaxRankXP;
						modifiedWeaponValue = weaponMaxRankXP - oldWeaponXP;
					}
					
					//for tracking weaponXP earned on a weapon per game
					if ( !IsDefined( self.weaponsUsed ) )
					{
						self.weaponsUsed = [];
						self.weaponXpEarned = [];
					}
					
					weaponFound = false;
					foundIndex = 999;
					for( i = 0; i < self.weaponsUsed.size; i++ )
					{
						if ( self.weaponsUsed[i] == weaponName )
						{
							weaponFound = true;
							foundIndex = i;
						}
					}
					
					if ( weaponFound )
					{
						self.weaponXpEarned[foundIndex] += modifiedWeaponValue;
					}
					else
					{
						self.weaponsUsed[self.weaponsUsed.size] = weaponName;
						self.weaponXpEarned[self.weaponXpEarned.size] = modifiedWeaponValue;
					}

					self SetPlayerData( "weaponXP", weaponName, newWeaponXP );
					self maps\mp\_matchdata::logWeaponStat( weaponName, "XP", modifiedWeaponValue );
					self incPlayerStat( "weaponxpearned", modifiedWeaponValue );
					if ( self rankingEnabled() && updateWeaponRank( newWeaponXP, weaponName ) && (GetDvar("g_gametype")) != "aliens" )
					{
						self thread updateWeaponRankAnnounceHUD();
					}
				}
			}
		}
	}
	// END WEAPON RANKING
	//////////////////////////////////////////////////////////////

	if ( !level.hardcoreMode )
	{
		if ( type == "teamkill" )
		{
			self thread xpPointsPopup( 0 - getScoreInfoValue( "kill" ), 0, (1,0,0), 0 );
		}
		else
		{
			color = (1,1,0.5);
			if ( gotRestXP )
				color = (1,.65,0);
			
			self thread xpPointsPopup( modifiedValue, momentumBonus, color, 0 );
			
			if ( type == "assist" )
			{
				if ( IsDefined( self.taggedAssist ) )
					self.taggedAssist = undefined;
				else
				{
					assist_string = &"MP_ASSIST";
					if( level.gameType == "cranked" )
					{
						if( IsDefined( self.cranked ) )
							assist_string = &"SPLASHES_ASSIST_CRANKED";
					}
					if( self _hasPerk( "specialty_assists" ) )
					{
						if( !( self.pers["assistsToKill"] % 2 ) )
						{
							assist_string = &"MP_ASSIST_TO_KILL";
						}
					}
					self thread maps\mp\gametypes\_rank::xpEventPopup( assist_string );
				}
			}
		}
	}

	switch( type )
	{
		case "kill":
		case "headshot":
		case "suicide":
		case "teamkill":
		case "assist":
		case "capture":
		case "defend":
		case "obj_return":
		case "pickup":
		case "assault":
		case "plant":
		case "defuse":
		case "kill_confirmed":
		case "kill_denied":
		case "tags_retrieved":
		case "team_assist":
		case "kill_bonus":
		case "kill_carrier":
		case "draft_rogue":
		case "survivor":
		case "final_rogue":
		case "gained_gun_rank":
		case "dropped_enemy_gun_rank":
		case "got_juggernaut":
		case "kill_as_juggernaut":
		case "kill_juggernaut":
		case "jugg_on_jugg":
		case "team_restock":
			self.pers["summary"]["score"] += modifiedValue;
			self.pers["summary"]["xp"] += modifiedValue;
			break;

		case "win":
		case "loss":
		case "tie":
			self.pers["summary"]["match"] += modifiedValue;
			self.pers["summary"]["xp"] += modifiedValue;
			break;

		case "challenge":
			self.pers["summary"]["challenge"] += modifiedValue;
			self.pers["summary"]["xp"] += modifiedValue;
			break;
			
		default:
			self.pers["summary"]["misc"] += modifiedValue;	//keeps track of ungrouped match xp reward
			self.pers["summary"]["xp"] += modifiedValue;
			break;
	}
}

is_score_a_greater_than_b( a, b )
{
	if( a.score > b.score )
		return true;
	return false;
}

weaponShouldGetXP( weapon, meansOfDeath )
{
	if( self IsItemUnlocked( "cac" ) &&
		!self isJuggernaut() &&
		IsDefined( weapon ) &&
		IsDefined( meansOfDeath ) &&
		!isKillstreakWeapon( weapon ) )
	{
		if( isBulletDamage( meansOfDeath ) )
		{
			return true;
		}
		if( IsExplosiveDamageMOD( meansOfDeath ) || meansOfDeath == "MOD_IMPACT" )
		{
			if( getWeaponClass( weapon ) == "weapon_projectile" || getWeaponClass( weapon ) == "weapon_assault" )
				return true;
		}
		if( meansOfDeath == "MOD_MELEE" )
		{
			if( getWeaponClass( weapon ) == "weapon_riot" )
				return true;
		}
	}

	return false;
}

characterTypeBonusXP( weapon, xp )
{
	percent = 1.2;

	if( IsDefined( weapon ) && IsDefined( self.character_type ) )
	{
		switch( getWeaponClass( weapon ) )
		{
			case "weapon_smg":
				if( self.character_type == "charactertype_smg" )
					xp *= percent;
				break;
			case "weapon_assault":
				if( self.character_type == "charactertype_assault" )
					xp *= percent;
				break;
			case "weapon_shotgun":
				if( self.character_type == "charactertype_shotgun" )
					xp *= percent;
				break;
			case "weapon_dmr":
				if( self.character_type == "charactertype_dmr" )
					xp *= percent;
				break;
			case "weapon_sniper":
				if( self.character_type == "charactertype_sniper" )
					xp *= percent;
				break;
			case "weapon_lmg":
				if( self.character_type == "charactertype_lmg" )
					xp *= percent;
				break;
			default:
				break;
		};
	}

	return int( xp );
}

updateRank( oldxp )
{
	newRankId = self getRank();
	if ( newRankId == self.pers[ "rank" ] || self.pers[ "rank" ] == level.maxRank )
		return false;

	oldRank = self.pers[ "rank" ];
	self.pers[ "rank" ] = newRankId;

	//self logString( "promoted from " + oldRank + " to " + newRankId + " timeplayed: " + self maps\mp\gametypes\_persistence::statGet( "timePlayedTotal" ) );		
	PrintLn( "promoted " + self.name + " from rank " + oldRank + " to " + newRankId + ". Experience went from " + oldxp + " to " + self getRankXP() + "." );
	
	self SetRank( newRankId );
	
	return true;
}

updateWeaponRank( oldxp, weapon )
{
	// NOTE: weapon is already coming in tokenized, so it should be the weapon without attachments and _mp
	newRankId = self getWeaponRank( weapon );
	if ( newRankId == self GetPlayerData( "weaponRank", weapon ) )
		return false;

	self.pers[ "weaponRank" ] = newRankId;
	self SetPlayerData( "weaponRank", weapon, newRankId );

	//self logString( "promoted from " + oldRank + " to " + newRankId + " timeplayed: " + self maps\mp\gametypes\_persistence::statGet( "timePlayedTotal" ) );		
/#
	oldRank = self GetPlayerData( "weaponRank", weapon );
	PrintLn( "promoted " + self.name + "'s weapon from rank " + oldRank + " to " + newRankId + ". Experience went from " + oldxp + " to " + self getWeaponRankXP( weapon ) + "." );
#/

	// now that we've ranked up, process the mastery challenge
	self thread maps\mp\gametypes\_missions::masteryChallengeProcess( weapon );

	return true;
}

updateRankAnnounceHUD()
{
	self endon("disconnect");

	self notify("update_rank");
	self endon("update_rank");

	team = self.pers["team"];
	if ( !isdefined( team ) )
		return;	

	// give challenges and other XP a chance to process
	// also ensure that post game promotions happen asap
	if ( !levelFlag( "game_over" ) )
		level waittill_notify_or_timeout( "game_over", 0.25 );
	
	
	newRankName = self getRankInfoFull( self.pers[ "rank" ] );	
	rank_char = level.rankTable[ self.pers[ "rank" ] ][ 1 ];
	subRank = int( rank_char[ rank_char.size-1 ] );
	
	// TEMPORARY: no spalsh notify for leveling up while we prototype
	//thread maps\mp\gametypes\_hud_message::promotionSplashNotify();

	if ( subRank > 1 )
		return;
	
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		playerteam = player.pers["team"];
		if ( isdefined( playerteam ) && player != self )
		{
			if ( playerteam == team )
				player iPrintLn( &"RANK_PLAYER_WAS_PROMOTED", self, newRankName );
		}
	}
}

updateWeaponRankAnnounceHUD()
{
	self endon("disconnect");

	self notify("update_weapon_rank");
	self endon("update_weapon_rank");

	team = self.pers["team"];
	if ( !isdefined( team ) )
		return;	

	// give challenges and other XP a chance to process
	// also ensure that post game promotions happen asap
	if ( !levelFlag( "game_over" ) )
		level waittill_notify_or_timeout( "game_over", 0.25 );

	// TEMPORARY: no spalsh notify for leveling up while we prototype
	//thread maps\mp\gametypes\_hud_message::weaponPromotionSplashNotify();

	//for ( i = 0; i < level.players.size; i++ )
	//{
	//	player = level.players[i];
	//	playerteam = player.pers["team"];
	//	if ( isdefined( playerteam ) && player != self )
	//	{
	//		if ( playerteam == team )
	//			player iPrintLn( &"RANK_WEAPON_WAS_PROMOTED", self );
	//	}
	//}
}

endGameUpdate()
{
	player = self;			
}

createXpPointsPopup()
{
	hud_xpPointsPopup = newClientHudElem( self );
	hud_xpPointsPopup.horzAlign = "center";
	hud_xpPointsPopup.vertAlign = "middle";
	hud_xpPointsPopup.alignX = "center";
	hud_xpPointsPopup.alignY = "middle";
	hud_xpPointsPopup.x = 30;
	if ( level.splitScreen )
		hud_xpPointsPopup.y = -30;
	else
		hud_xpPointsPopup.y = -50;
	hud_xpPointsPopup.font = "hudbig";
	hud_xpPointsPopup.fontscale = 0.65;
	hud_xpPointsPopup.archived = false;
	hud_xpPointsPopup.color = (0.5,0.5,0.5);
	hud_xpPointsPopup.sort = 10000;
	hud_xpPointsPopup maps\mp\gametypes\_hud::fontPulseInit( 3.0 );	
	return hud_xpPointsPopup;
}

xpPointsPopup( amount, bonus, hudColor, glowAlpha )
{
	self endon( "disconnect" );
	self endon( "joined_team" );
	self endon( "joined_spectators" );

	if ( amount == 0 )
		return;

	self notify( "xpPointsPopup" );
	self endon( "xpPointsPopup" );

	self.xpUpdateTotal += amount;
	self.bonusUpdateTotal += bonus;

	wait ( 0.05 );

	if ( self.xpUpdateTotal < 0 )
		self.hud_xpPointsPopup.label = &"MP_MINUS";
	else
		self.hud_xpPointsPopup.label = &"MP_PLUS";

	self.hud_xpPointsPopup.color = hudColor;
	self.hud_xpPointsPopup.glowColor = hudColor;
	self.hud_xpPointsPopup.glowAlpha = glowAlpha;

	self.hud_xpPointsPopup setValue(self.xpUpdateTotal);
	self.hud_xpPointsPopup.alpha = 0.85;
	self.hud_xpPointsPopup thread maps\mp\gametypes\_hud::fontPulse( self );

	increment = max( int( self.bonusUpdateTotal / 20 ), 1 );
		
	if ( self.bonusUpdateTotal )
	{
		while ( self.bonusUpdateTotal > 0 )
		{
			self.xpUpdateTotal += min( self.bonusUpdateTotal, increment );
			self.bonusUpdateTotal -= min( self.bonusUpdateTotal, increment );
			
			self.hud_xpPointsPopup setValue( self.xpUpdateTotal );
			
			wait ( 0.05 );
		}
	}	
	else
	{
		wait ( 1.0 );
	}

	self.hud_xpPointsPopup fadeOverTime( 0.75 );
	self.hud_xpPointsPopup.alpha = 0;
	
	self.xpUpdateTotal = 0;		
}

createXpEventPopup()
{
	hud_xpEventPopup = newClientHudElem( self );
	hud_xpEventPopup.children = [];		
	hud_xpEventPopup.horzAlign = "center";
	hud_xpEventPopup.vertAlign = "middle";
	hud_xpEventPopup.alignX = "center";
	hud_xpEventPopup.alignY = "middle";
	hud_xpEventPopup.x = 55;
	if ( level.splitScreen )
		hud_xpEventPopup.y = -20;
	else
		hud_xpEventPopup.y = -35;
	hud_xpEventPopup.font = "hudbig";
	hud_xpEventPopup.fontscale = 0.65;
	hud_xpEventPopup.archived = false;
	hud_xpEventPopup.color = (0.5,0.5,0.5);
	hud_xpEventPopup.sort = 10000;
	hud_xpEventPopup.elemType = "msgText";
	hud_xpEventPopup maps\mp\gametypes\_hud::fontPulseInit( 3.0 );
	return hud_xpEventPopup;
}

xpEventPopupFinalize( event, hudColor, glowAlpha )
{
	self endon( "disconnect" );
	self endon( "joined_team" );
	self endon( "joined_spectators" );

	self notify( "xpEventPopup" );
	self endon( "xpEventPopup" );
	
	if( level.hardcoreMode )
		return;

	wait ( 0.05 );

	/*if ( self.spUpdateTotal < 0 )
	self.hud_xpEventPopup.label = &"";
	else
	self.hud_xpEventPopup.label = &"MP_PLUS";*/

	if ( !IsDefined( hudColor ) )
		hudColor = (1,1,0.5);
	if ( !IsDefined( glowAlpha ) )
		glowAlpha = 0;

	if( !IsDefined( self ) )
		return;

	self.hud_xpEventPopup.color = hudColor;
	self.hud_xpEventPopup.glowColor = hudColor;
	self.hud_xpEventPopup.glowAlpha = glowAlpha;

	self.hud_xpEventPopup setText(event);
	self.hud_xpEventPopup.alpha = 0.85;

	wait ( 1.0 );

	if( !IsDefined( self ) )
		return;

	self.hud_xpEventPopup fadeOverTime( 0.75 );
	self.hud_xpEventPopup.alpha = 0;	
	self notify( "PopComplete" );		
}

xpEventPopupTerminate()
{
	self endon( "PopComplete" );
	self waittill_any( "joined_team", "joined_spectators" );

	self.hud_xpEventPopup fadeOverTime( 0.05 );
	self.hud_xpEventPopup.alpha = 0;	
}

xpEventPopup( event, hudColor, glowAlpha )
{
	if ( IsDefined(self.owner) )
	{
		// Call this function on the player's owner instead
		self.owner xpEventPopup( event, hudColor, glowAlpha );
	}
	
	if ( !IsPlayer(self) )
		return;
	
	self thread xpEventPopupFinalize( event, hudColor, glowAlpha );
	self thread xpEventPopupTerminate();
}

removeRankHUD()
{
	self.hud_xpPointsPopup.alpha = 0;
}

getRank()
{	
	rankXp = self.pers[ "rankxp" ];
	rankId = self.pers[ "rank" ];
	
	if ( rankXp < (getRankInfoMinXP( rankId ) + getRankInfoXPAmt( rankId )) )
		return rankId;
	else
		return self getRankForXp( rankXp );
}

getWeaponRank( weapon )
{	
	// NOTE: weapon is already coming in tokenized, so it should be the weapon without attachments and _mp
	rankXp = self GetPlayerData( "weaponXP", weapon );
	return self getWeaponRankForXp( rankXp, weapon );
}

levelForExperience( experience )
{
	return getRankForXP( experience );
}

weaponLevelForExperience( experience )
{
	return getWeaponRankForXP( experience );
}

getCurrentWeaponXP()
{
	weapon = self GetCurrentWeapon();
	if( IsDefined( weapon ) )
	{
		return self GetPlayerData( "weaponXP", weapon );	
	}

	return 0;
}

getRankForXp( xpVal )
{
	rankId = 0;
	rankName = level.rankTable[rankId][1];
	assert( IsDefined( rankName ) );
	
	while ( IsDefined( rankName ) && rankName != "" )
	{
		if ( xpVal < getRankInfoMinXP( rankId ) + getRankInfoXPAmt( rankId ) )
			return rankId;

		rankId++;
		if ( IsDefined( level.rankTable[rankId] ) )
			rankName = level.rankTable[rankId][1];
		else
			rankName = undefined;
	}
	
	rankId--;
	return rankId;
}

getWeaponRankForXp( xpVal, weapon )
{
	// NOTE: weapon is already coming in tokenized, so it should be the weapon without attachments and _mp
	if( !IsDefined( xpVal ) )
		xpVal = 0;

	weaponClass = tablelookup( STATS_TABLE, 4, weapon, 2 );
	weaponMaxRank = int( tableLookup( WEAPON_RANK_TABLE, 0, weaponClass, 1 ) );
	for( rankId = 0; rankId < weaponMaxRank + 1; rankId++ )
	{
		if ( xpVal < getWeaponRankInfoMinXP( rankId ) + getWeaponRankInfoXPAmt( rankId ) )
			return rankId;
	}

	return ( rankId - 1 );
}

getSPM()
{
	rankLevel = self getRank() + 1;
	return (3 + (rankLevel * 0.5))*10;
}

getPrestigeLevel()
{
	if ( IsAI( self ) && IsDefined( self.pers[ "prestige_fake" ] ) )
	{
		return self.pers[ "prestige_fake" ];
	}
	else
	{
		return self maps\mp\gametypes\_persistence::statGet( "prestige" );
	}
}

getRankXP()
{
	return self.pers[ "rankxp" ];
}

getWeaponRankXP( weapon )
{
	return self GetPlayerData( "weaponXP", weapon );
}

getWeaponMaxRankXP( weapon )
{
	// NOTE: weapon is already coming in tokenized, so it should be the weapon without attachments and _mp
	weaponClass = tablelookup( STATS_TABLE, 4, weapon, 2 );
	weaponMaxRank = int( tableLookup( WEAPON_RANK_TABLE, 0, weaponClass, 1 ) );
	weaponMaxRankXP = getWeaponRankInfoMaxXp( weaponMaxRank );

	return weaponMaxRankXP;
}

isWeaponMaxRank( weapon )
{	
	// NOTE: weapon is already coming in tokenized, so it should be the weapon without attachments and _mp
	weaponRankXP = self GetPlayerData( "weaponXP", weapon );
	weaponMaxRankXP = getWeaponMaxRankXP( weapon );

	return ( weaponRankXP >= weaponMaxRankXP );
}

// TODO: waiting to see how we decide to do this
//checkWeaponUnlocks( weapon )
//{
//	// see if the weapon has unlocked anything new
//	// NOTE: weapon is already coming in tokenized, so it should be the weapon without attachments and _mp
//	weaponClass = tablelookup( STATS_TABLE, 4, weapon, 2 );
//	
//	weaponAttachmentCol = tablelookup( STATS_TABLE, 0, weaponClass, 2 );
//	weaponCamoCol = tablelookup( STATS_TABLE, 0, weaponClass, 3 );
//	weaponBuffCol = tablelookup( STATS_TABLE, 0, weaponClass, 4 );
//	weaponCustomCol = tablelookup( STATS_TABLE, 0, weaponClass, 5 );
//
//	weaponRank = self getWeaponRank( weapon );
//
//	attachment = tablelookup( STATS_TABLE, 0, weaponRank, weaponAttachmentCol );
//	if( attachment != "" )
//	{
//		// unlocked a new attachment
//		self SetPlayerData( "attachmentNew", weapon, attachment, true );
//	}
//
//	// TODO: when we get camos online
//	//camo = tablelookup( STATS_TABLE, 0, weaponRank, weaponCamoCol );
//	//if( camo != "" )
//	//{
//	//	// unlocked a new camo
//	//	self SetPlayerData( "camoNew", weapon, camo, true );
//	//}
//
//	buff = tablelookup( STATS_TABLE, 0, weaponRank, weaponBuffCol );
//	if( buff != "" )
//	{
//		// unlocked a new buff
//		self SetPlayerData( "perkNew", weapon, buff, true );
//	}
//
//	// TODO: when we get customs online
//	//custom = tablelookup( STATS_TABLE, 0, weaponRank, weaponCustomCol );
//	//if( custom != "" )
//	//{
//	//	// unlocked a new custom
//	//	self SetPlayerData( "customNew", weapon, custom, true );
//	//}
//}

incRankXP( amount )
{
	if ( !self rankingEnabled() )
		return;

	if ( IsDefined( self.isCheater ) )
		return;
	
	
	points = self getPlayerData( "points" );
	updatedPoints = points + amount;
	
	if ( updatedPoints >= 2000 )
	{
		updatedPoints = updatedPoints - 2000;
		self setPlayerData( "points", updatedPoints );
		
		//splash 
		self thread maps\mp\gametypes\_hud_message::playerCardSplashNotify( "earned_unlock", self );
		
		unlockPoints = self getPlayerData( "unlockPoints" );
		newUnlockPoints = unlockPoints +1;
		
		self setPlayerData( "unlockPoints", newUnlockPoints );
	}
	else
	{
		self setPlayerData( "points", updatedPoints );	
	}
	
	
	xp = self getRankXP();
	newXp = (int( min( xp, getRankInfoMaxXP( level.maxRank ) ) ) + amount);
	
	if ( self.pers[ "rank" ] == level.maxRank && newXp >= getRankInfoMaxXP( level.maxRank ) )
		newXp = getRankInfoMaxXP( level.maxRank );
	
	self.pers[ "rankxp" ] = newXp;
}

getRestXPAward( baseXP )
{
	if ( !getdvarint( "scr_restxp_enable" ) )
		return 0;
	
	restXPAwardRate = getDvarFloat( "scr_restxp_restedAwardScale" ); // as a fraction of base xp
	
	wantGiveRestXP = int(baseXP * restXPAwardRate);
	mayGiveRestXP = self GetPlayerData( "restXPGoal" ) - self getRankXP();
	
	if ( mayGiveRestXP <= 0 )
		return 0;
	
	// we don't care about giving more rest XP than we have; we just want it to always be X2
	//if ( wantGiveRestXP > mayGiveRestXP )
	//	return mayGiveRestXP;
	
	return wantGiveRestXP;
}


isLastRestXPAward( baseXP )
{
	if ( !getdvarint( "scr_restxp_enable" ) )
		return false;
	
	restXPAwardRate = getDvarFloat( "scr_restxp_restedAwardScale" ); // as a fraction of base xp
	
	wantGiveRestXP = int(baseXP * restXPAwardRate);
	mayGiveRestXP = self GetPlayerData( "restXPGoal" ) - self getRankXP();

	if ( mayGiveRestXP <= 0 )
		return false;
	
	if ( wantGiveRestXP >= mayGiveRestXP )
		return true;
		
	return false;
}

syncXPStat()
{
	if ( level.xpScale > 4 || level.xpScale <= 0)
		exitLevel( false );

//	// old way with overall xp
//	xp = self getRankXP();
//
///#
//	// Attempt to catch xp regression
//	oldXp = self GetPlayerData( "experience" );
//	assert( xp >= oldXp, "Attempted XP regression in syncXPStat - " + oldXp + " -> " + xp + " for player " + self.name );
//#/
//	
//	self maps\mp\gametypes\_persistence::statSet( "experience", xp );
	
	// new way with individual character xp
	//	need to use lastClass here because everything else changes as soon as you select a new class
	//	also make sure it's not a default class
	if( IsDefined( self.lastClass ) && IsSubStr( self.lastClass, "custom" ) )
	{
		xp = self getRankXP();
		classIndex = getClassIndex( self.lastClass );	

/#
		// Attempt to catch xp regression
		oldXp = self GetPlayerData( "characterXP", classIndex );
		if( xp < oldXp )
			self logString( "Attempted character XP regression in syncXPStat - " + oldXp + " -> " + xp + " for player " + self.name + " using class " + classIndex );
		AssertEx( xp >= oldXp, "Attempted character XP regression in syncXPStat - " + oldXp + " -> " + xp + " for player " + self.name + " using class " + classIndex );
#/

		self SetPlayerData( "characterXP", classIndex, xp );
	}
}

//createLevelingBonusIcon( icon )
//{
//	levelingBonusIcon = self createIcon( icon, 32, 32 );
//	levelingBonusIcon.alpha = 1;
//	levelingBonusIcon setPoint( "CENTER", "CENTER", 0, 80 );
//	levelingBonusIcon.archived = true;
//	levelingBonusIcon.sort = 1;
//	levelingBonusIcon.foreground = true;
//
//	fade_time = 3.0;
//
//	levelingBonusIcon FadeOverTime( fade_time );
//	wait( fade_time );
//	levelingBonusIcon.alpha = 0;
//
//	levelingBonusIcon Destroy();
//}

createMultiplierText()
{
	hud_multiplierText = newClientHudElem( self );
	hud_multiplierText.horzAlign = "center";
	hud_multiplierText.vertAlign = "bottom";
	hud_multiplierText.alignX = "center";
	hud_multiplierText.alignY = "middle";
	hud_multiplierText.x = 70;
	if ( level.splitScreen )
		hud_multiplierText.y = -55;
	else
		hud_multiplierText.y = -10;
	hud_multiplierText.font = "hudbig";
	hud_multiplierText.fontscale = 0.65;
	hud_multiplierText.archived = false;
	hud_multiplierText.color = ( 1.0, 1.0, 1.0 );
	hud_multiplierText.sort = 10000;
	hud_multiplierText maps\mp\gametypes\_hud::fontPulseInit( 1.5 );	
	return hud_multiplierText;
}

multiplierTextPopup( string )
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	level endon( "round_end_finished" );
	self endon( "death" );

	self notify( "multiplierTextPopup" );
	self endon( "multiplierTextPopup" );

	if( !IsDefined( self.hud_multiplierText ) )
		self.hud_multiplierText = self createMultiplierText();

	wait ( 0.05 );

	self thread multiplierTextPopup_watchDeath();
	self thread multiplierTextPopup_watchGameEnd();
		 
	self.hud_multiplierText SetText( string );
	while( true )
	{
		self.hud_multiplierText.alpha = 0.85;
		self.hud_multiplierText thread maps\mp\gametypes\_hud::fontPulse( self );
		wait( 1.0 );

		self.hud_multiplierText fadeOverTime( 0.75 );
		self.hud_multiplierText.alpha = 0.25;
		wait( 1.0 );
	}
}

multiplierTextPopup_watchDeath()
{
	self waittill( "death" );
	if( IsDefined( self.hud_multiplierText ) )
		self.hud_multiplierText.alpha = 0;
}

multiplierTextPopup_watchGameEnd()
{
	level waittill( "game_ended" );
	if( IsDefined( self.hud_multiplierText ) )
		self.hud_multiplierText.alpha = 0;
}

/#
watchDevDvars()
{
	level endon( "game_ended" );

	while( true )
	{
		if( GetDvarInt( "scr_devsetweaponmaxrank" ) > 0 )
		{
			// grab all of the players and max their current weapon rank
			foreach( player in level.players )
			{
				if( IsDefined( player.pers[ "isBot" ] ) && player.pers[ "isBot" ] )
					continue;

				weapon = player GetCurrentWeapon();

				// we just want the weapon name up to the first underscore
				weaponTokens = StrTok( weapon, "_" );

				if ( weaponTokens[0] == "iw5" || weaponTokens[0] == "iw6" )
					weaponName = weaponTokens[0] + "_" + weaponTokens[1];
				else if ( weaponTokens[0] == "alt" )
					weaponName = weaponTokens[1] + "_" + weaponTokens[2];
				else
					weaponName = weaponTokens[0];

				if( weaponTokens[0] == "gl" )
					weaponName = weaponTokens[1];

				weaponMaxRankXP = getWeaponMaxRankXP( weaponName );
				player SetPlayerData( "weaponXP", weaponName, weaponMaxRankXP );
				player updateWeaponRank( weaponMaxRankXP, weaponName );
			}
			SetDevDvar( "scr_devsetweaponmaxrank", 0 );
		}

		wait( 0.05 );
	}
}
#/