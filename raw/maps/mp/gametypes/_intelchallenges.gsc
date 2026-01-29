#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;


giveChallenge( challengeIndex )
{
	challengeReference = level.intelChallengeStruct.challengeName[challengeIndex];
	
	self thread deathWatcher();
	
	switch( challengeReference )
	{
		case "ch_intel_headshots":
			self thread intelHeadshotChallenge(challengeIndex);
			return;
		case "ch_intel_kills":
			self thread intelKillsChallenge(challengeIndex);
			return;
		//case "ch_intel_killtopenemy":
		//	self thread intelTopKillChallenge(challengeIndex);
		//	return;
		case "ch_intel_knifekill":
			self thread intelKnifeKillChallenge(challengeIndex);
			return;
		case "ch_intel_explosivekill":
			self thread intelBombKillChallenge(challengeIndex);
			return;
		case "ch_intel_crouchkills":
			self thread intelCrouchKillsChallenge(challengeIndex);
			return;
		case "ch_intel_pronekills":
			self thread intelProneKillsChallenge(challengeIndex);
			return;
		case "ch_intel_backshots":
			self thread intelBackKillsChallenge(challengeIndex);
			return;
		case "ch_intel_target":
			self thread intelTargetKillsChallenge(challengeIndex);
			return;
		case "ch_intel_jumpshot":
			self thread intelJumpShotKillsChallenge(challengeIndex);
			return;
		case "ch_intel_secondarykills":
			self thread intelSecondaryKillsChallenge(challengeIndex);
			return;
		case "ch_intel_foundshot":
			self thread intelFoundshotKillsChallenge(challengeIndex);
			return;
		case "ch_intel_tbag":
			self thread intelTbagChallenge(challengeIndex);
			return;
		default:
			AssertMsg( challengeReference );
			println( "HIT DEFAULT FOR SOME REASON!!!!!!!!!!!!!-------------------------------------------------" );
	}
}


deathWatcher()
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	self endon( "intel_challenge_complete" );
	self endon( "intel_failed" );
	
	self waittill( "death" );
	
	if( IsDefined( self.targetObjId ) )
	{
		if( IsDefined( self.playerTarget ) )
		{
			self.playerTarget SetClientDvar( "ui_intelActiveIndex", -1 );
			self.playerTarget SetClientDvar( "ui_intelTargetPlayer", -1 );

			// clean up
			if( IsDefined( self.playerTarget.targetObjId ) )
				Objective_Delete( self.playerTarget.targetObjId );

			self.playerTarget = undefined;
		}
		
		Objective_Delete( self.targetObjId );
	}
	
	self SetClientDvar( "ui_intelActiveIndex", -1 );
	self SetClientDvar( "ui_intelTargetPlayer", -1 );
	
	self thread maps\mp\gametypes\_hud_message::SplashNotifyDelayed( "ch_intel_failed" );
}


//Challenges
intelHeadshotChallenge( index )
{
	self endon("disconnect");
	self endon("death");
	
	numHeadshots = 0;
	headshotTarget = Int( level.intelChallengeStruct.challengeTarget[index] );
	challengeReference = level.intelChallengeStruct.challengeName[index];
	
	self thread maps\mp\gametypes\_hud_message::SplashNotifyDelayed( challengeReference + "_received", headshotTarget );
	self SetClientDvar( "ui_intelActiveIndex", (index) );

	while( numHeadshots < headshotTarget )
	{
		self waittill( "got_a_kill", victim, weapon, meansOfDeath );
		
		if ( meansOfDeath == "MOD_HEAD_SHOT" )		
			numHeadshots++;
	}
	
	self maps\mp\gametypes\_intel::awardPlayerChallengeComplete( index );
}


intelKillsChallenge( index )
{
	self endon("disconnect");
	self endon("death");
	
	numKills = 0;
	numKillsTarget = Int( level.intelChallengeStruct.challengeTarget[index] );
	challengeReference = level.intelChallengeStruct.challengeName[index];
	
	self thread maps\mp\gametypes\_hud_message::SplashNotifyDelayed( challengeReference + "_received", numKillsTarget );
	self SetClientDvar( "ui_intelActiveIndex", (index) );
	
	while( numKills < numKillsTarget )
	{
		self waittill( "got_a_kill" );
		numKills++;
	}
	
	self maps\mp\gametypes\_intel::awardPlayerChallengeComplete( index );
}


addEnemyToMinimap( enemy )
{
	self endon("disconnect");
	self endon("death");
	
	if ( !isReallyAlive( enemy ) )
		enemy waittill( "spawned" );
	
	//add this guy to the minimap and let the target know they are marked
	curObjID = maps\mp\gametypes\_gameobjects::getNextObjID();
	objective_add( curObjID, "invisible", (0,0,0), "compass_objpoint_enemy_target", self );
	objective_onEntity( curObjID, enemy );
	objective_state( curObjID, "active" );
	objective_icon( curObjID, "compass_objpoint_enemy_target" );
	objective_player( curObjID, self GetEntityNumber() );
	return curObjId;
}

watchForHunterDeath( targetPlayer )
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	self endon( "intel_challenge_complete" );
	self endon( "intel_failed" );
	
	self waittill( "death", attacker );
	
	if( !IsPlayer( attacker ) && IsDefined( attacker.owner ) )
		attacker = attacker.owner;

	if ( attacker == targetPlayer )
	{
		//splash you killed the hunter
		targetPlayer thread maps\mp\gametypes\_hud_message::SplashNotifyDelayed( "killedTheHunter", 500 );
		
		//Give Killstreak Reward
		targetPlayer thread maps\mp\killstreaks\_killstreaks::giveKillstreak( "airdrop_assault", false, false, self );
		targetPlayer thread maps\mp\gametypes\_rank::giveRankXP( "intel", 500 );	

		// clean up
		if( IsDefined( targetPlayer.targetObjId ) )
			Objective_Delete( targetPlayer.targetObjId );
	}
	
}

hunterDisconnectWatcher( targetplayer )
{
	level endon( "game_ended" );
	self endon( "intel_challenge_complete" );
	self endon( "intel_failed" );
	self endon ( "death" );
	
	objectiveMarkerID = self.targetObjId;
	
	self waittill( "disconnect" );
	
	if ( IsDefined( targetplayer ) )
	{
		targetplayer SetClientDvar( "ui_intelActiveIndex", -1 );
		targetplayer SetClientDvar( "ui_intelTargetPlayer", -1 );
	}
	
	Objective_Delete( objectiveMarkerID );
}

//intelTopKillChallenge( index )
//{
//	self endon("disconnect");
//	self endon("death");
//	
//	numKills = 0;
//	numKillsTarget = Int( level.intelChallengeStruct.challengeTarget[index] );
//	challengeReference = level.intelChallengeStruct.challengeName[index];
//	self thread maps\mp\gametypes\_hud_message::SplashNotifyDelayed( challengeReference + "_received" );
//	
//	topScore = 0;
//	topPlayer = undefined;
//	
//	foreach ( player in level.players )
//	{
//		if ( player.team == self.team )
//			continue;
//		
//		if ( player.score >= topScore )
//		{
//			topScore = player.score;
//			topPlayer = player;
//		}
//	}
//	
//	if ( !IsDefined(topPlayer) )
//	{
//		self maps\mp\gametypes\_intel::awardPlayerChallengeComplete( index );
//		return;
//	}
//	
//	topPlayerName = topPlayer.name;
//	cID = topPlayer.clientID;
//	self.playerTarget = topPlayer;
//	
//	//blocking call so it doesnt show up on a corpse if the guy is dead
//	objID = self addEnemyToMinimap(topPlayer);
//	self.targetObjId = objID;
//	
//	//need to set target player first for the menu logic to function properly
//	self SetClientDvar( "ui_intelTargetPlayer", cID );
//	self SetClientDvar( "ui_intelActiveIndex", (index) );
//	
//	//using this to set the targeted players HUD
//	topPlayer SetClientDvar( "ui_intelActiveIndex", 1337 );
//	topPlayer SetClientDvar( "ui_intelTargetPlayer", self.clientid );
//	
//	self thread targetDisconnectWatcher( topPlayer, index );
//	
//	self thread watchForHunterDeath( topPlayer );
//	self thread hunterDisconnectWatcher( topPlayer );
//	
//	while( numKills < numKillsTarget )
//	{
//		self waittill( "got_a_kill", victim );
//		
//		if( victim == topPlayer )
//			numKills++;
//	}
//	
//	topPlayer SetClientDvar( "ui_intelActiveIndex", -1 );
//	topPlayer SetClientDvar( "ui_intelTargetPlayer", -1 );
//	self.playerTarget = undefined;
//	
//	self notify( "intel_challenge_complete" );
//	
//	Objective_Delete(objID);
//	self maps\mp\gametypes\_intel::awardPlayerChallengeComplete( index );
//}


intelTargetKillsChallenge( index )
{
	self endon("disconnect");
	self endon("death");
	
	numKills = 0;
	numKillsTarget = Int( level.intelChallengeStruct.challengeTarget[index] );
	challengeReference = level.intelChallengeStruct.challengeName[index];
	self thread maps\mp\gametypes\_hud_message::SplashNotifyDelayed( challengeReference + "_received" );
	
	targetPlayer = undefined;

	numEnemies = 0;
	if( level.multiTeamBased )
	{
		foreach ( teamName in level.teamNameList )
		{
			if( teamName != self.team )
			{
				numEnemies += level.teamcount[teamName];
			}
		}
	}
	else
	{
		otherTeam = getOtherTeam( self.team );
		numEnemies = level.teamcount[otherTeam];
	}
	
	if( numEnemies > 1 )
		randNum = RandomIntRange( 1, numEnemies );
	else 
		randNum = 1;

	loopCount = 0;
	
	foreach ( player in level.players )
	{
		if ( player.team == self.team )
			continue;
		
		loopCount++;
		
		if ( loopCount >= randNum )
			targetPlayer = player;
	}
	
	if ( !IsDefined(targetPlayer) )
	{
		self maps\mp\gametypes\_intel::awardPlayerChallengeComplete( index );
		return;
	}
	
	targetPlayerName = targetPlayer.name;
	self.playerTarget = targetPlayer;
	
	assert( IsPlayer( targetPlayer ) );
	assert( IsPlayer( self ) );
	
	//blocking call so it doesnt show up on a corpse is the guy is dead
	objID = self addEnemyToMinimap( targetPlayer );
	self.targetObjId = objID;
	
	//need to set target player first for the menu logic to function properly
	self SetClientDvar( "ui_intelTargetPlayer", targetPlayer GetEntityNumber() );
	self SetClientDvar( "ui_intelActiveIndex", (index) );
	
	//using this to set the targeted players HUD
	targetPlayer SetClientDvar( "ui_intelActiveIndex", 1337 );
	targetPlayer SetClientDvar( "ui_intelTargetPlayer", self GetEntityNumber() );
	
	// only fair to add the hunter to the target's minimap
	//	blocking call so it doesn't show up on a corpse is the guy is dead
	objID = targetPlayer addEnemyToMinimap( self );
	targetPlayer.targetObjId = objID;

	self thread targetDisconnectWatcher( targetPlayer, index );
	self thread watchForHunterDeath( targetPlayer );
	self thread hunterDisconnectWatcher( targetPlayer );
	
	while( numKills < numKillsTarget )
	{
		self waittill( "got_a_kill", victim );
		
		if( victim == targetPlayer )
			numKills++;
	}
	
	targetPlayer SetClientDvar( "ui_intelActiveIndex", -1 );
	targetPlayer SetClientDvar( "ui_intelTargetPlayer", -1 );
	self.playerTarget = undefined;
	
	if( IsDefined( self.targetObjId ) )
		Objective_Delete( self.targetObjId );
	
	if( IsDefined( targetPlayer.targetObjId ) )
		Objective_Delete( targetPlayer.targetObjId );
		
	self notify( "intel_challenge_complete" );
	
	self maps\mp\gametypes\_intel::awardPlayerChallengeComplete( index );
}

targetDisconnectWatcher( playerToWatch, index )
{
	self endon( "death" );
	self endon( "intel_challenge_complete" );
	self endon( "intel_failed" );
	self endon( "disconnect" );
	
	playerToWatch waittill( "disconnect" );
	
	self SetClientDvar( "ui_intelActiveIndex", -1 );
	self SetClientDvar( "ui_intelTargetPlayer", -1 );
	self.playerTarget = undefined;
		
	Objective_Delete(self.targetObjId);
	
	self maps\mp\gametypes\_intel::awardPlayerChallengeComplete( index );
	
	self notify( "intel_challenge_complete" );
}

intelCrouchKillsChallenge( index )
{
	self endon("disconnect");
	self endon("death");
	
	numKills = 0;
	numKillsTarget = Int( level.intelChallengeStruct.challengeTarget[index] );
	challengeReference = level.intelChallengeStruct.challengeName[index];
	
	self thread maps\mp\gametypes\_hud_message::SplashNotifyDelayed( challengeReference + "_received", numKillsTarget );
	self SetClientDvar( "ui_intelActiveIndex", (index) );
	
	while( numKills < numKillsTarget )
	{
		self waittill( "got_a_kill", victim, weapon );
		
		if ( self getStance() == "crouch" )
		{
			if ( !isKillstreakWeapon( weapon ) && weapon != "iw5_knifeonly_mp" )
				continue;
			
			numKills++;
		}
	}
	
	self maps\mp\gametypes\_intel::awardPlayerChallengeComplete( index );
}


intelFoundshotKillsChallenge( index )
{
	self endon("disconnect");
	self endon("death");
	
	numKills = 0;
	numKillsTarget = Int( level.intelChallengeStruct.challengeTarget[index] );
	challengeReference = level.intelChallengeStruct.challengeName[index];
	
	self thread maps\mp\gametypes\_hud_message::SplashNotifyDelayed( challengeReference + "_received", numKillsTarget );
	self SetClientDvar( "ui_intelActiveIndex", (index) );

	while( numKills < numKillsTarget )
	{
		self waittill( "got_a_kill", victim, weapon );
		
		if ( !IsSubStr( weapon, self.loadoutprimary ) && !IsSubStr( weapon, self.loadoutsecondary ) && !isKillstreakWeapon( weapon ) )
			numKills++;
	}
	
	self maps\mp\gametypes\_intel::awardPlayerChallengeComplete( index );
}


intelSecondaryKillsChallenge( index )
{
	self endon("disconnect");
	self endon("death");
	
	numKills = 0;
	numKillsTarget = Int( level.intelChallengeStruct.challengeTarget[index] );
	challengeReference = level.intelChallengeStruct.challengeName[index];
	
	self thread maps\mp\gametypes\_hud_message::SplashNotifyDelayed( challengeReference + "_received", numKillsTarget );
	self SetClientDvar( "ui_intelActiveIndex", (index) );
	
	while( numKills < numKillsTarget )
	{
		self waittill( "got_a_kill", victim, weapon );
		
		if ( isCACSecondaryWeapon(weapon) )
		{
			numKills++;	
		}
	}
	
	self maps\mp\gametypes\_intel::awardPlayerChallengeComplete( index );
}


intelBackKillsChallenge( index )
{
	self endon("disconnect");
	self endon("death");
	
	numKills = 0;
	numKillsTarget = Int( level.intelChallengeStruct.challengeTarget[index] );
	challengeReference = level.intelChallengeStruct.challengeName[index];
	
	self thread maps\mp\gametypes\_hud_message::SplashNotifyDelayed( challengeReference + "_received", numKillsTarget );
	self SetClientDvar( "ui_intelActiveIndex", (index) );
		
	while( numKills < numKillsTarget )
	{
		self waittill( "got_a_kill", victim, weapon, meansOfDeath );
		
		if( isKillstreakWeapon( weapon ) && !isJuggernautWeapon( weapon )  )
			continue;
		
		vAngles = victim.anglesOnDeath[1];
		pAngles = self.anglesOnKill[1];
		angleDiff = AngleClamp180( vAngles - pAngles );
		if ( abs(angleDiff) < 45 )
		{
			numKills++;	
		}
	}
	
	self maps\mp\gametypes\_intel::awardPlayerChallengeComplete( index );
}


intelJumpShotKillsChallenge( index )
{
	self endon("disconnect");
	self endon("death");
	
	numKills = 0;
	numKillsTarget = Int( level.intelChallengeStruct.challengeTarget[index] );
	challengeReference = level.intelChallengeStruct.challengeName[index];
	
	self thread maps\mp\gametypes\_hud_message::SplashNotifyDelayed( challengeReference + "_received", numKillsTarget );
	self SetClientDvar( "ui_intelActiveIndex", (index) );
	
	while( numKills < numKillsTarget )
	{
		self waittill( "got_a_kill", victim, weapon, meansOfDeath );
		
		if( isKillstreakWeapon( weapon ) && !isJuggernautWeapon( weapon ) )
			continue;
		
		if ( !self isOnGround() )
		{
			numKills++;	
		}
	}
	
	self maps\mp\gametypes\_intel::awardPlayerChallengeComplete( index );
}

			
intelKnifeKillChallenge( index )
{
	self endon("disconnect");
	self endon("death");
	
	numKills = 0;
	numKillsTarget = Int( level.intelChallengeStruct.challengeTarget[index] );
	challengeReference = level.intelChallengeStruct.challengeName[index];
	
	self thread maps\mp\gametypes\_hud_message::SplashNotifyDelayed( challengeReference + "_received", numKillsTarget );
	self SetClientDvar( "ui_intelActiveIndex", (index) );
	
	while( numKills < numKillsTarget )
	{
		self waittill( "got_a_kill", victim, weapon, meansOfDeath );
		
		if ( meansOfDeath == "MOD_MELEE" )
			numKills++;
	}
	
	self maps\mp\gametypes\_intel::awardPlayerChallengeComplete( index );
}


intelBombKillChallenge( index )
{
	self endon("disconnect");
	self endon("death");
	
	numKills = 0;
	numKillsTarget = Int( level.intelChallengeStruct.challengeTarget[index] );
	challengeReference = level.intelChallengeStruct.challengeName[index];
	
	self thread maps\mp\gametypes\_hud_message::SplashNotifyDelayed( challengeReference + "_received", numKillsTarget );
	self SetClientDvar( "ui_intelActiveIndex", (index) );
	
	while( numKills < numKillsTarget )
	{
		self waittill( "got_a_kill", victim, weapon, meansOfDeath );
		
		if( isKillstreakWeapon( weapon ) && !isJuggernautWeapon( weapon ) )
			continue;
		
		if ( weapon == "throwingknife_mp" )
			continue;
		
		if ( meansOfDeath == "MOD_EXPLOSIVE" || meansOfDeath == "MOD_GRENADE" || meansOfDeath == "MOD_GRENADE_SPLASH" || meansOfDeath == "MOD_PROJECTILE" || meansOfDeath == "MOD_IMPACT" )
			numKills++;
	}
	
	self maps\mp\gametypes\_intel::awardPlayerChallengeComplete( index );
}


intelProneKillsChallenge( index )
{
	self endon("disconnect");
	self endon("death");
	
	numKills = 0;
	numKillsTarget = Int( level.intelChallengeStruct.challengeTarget[index] );
	challengeReference = level.intelChallengeStruct.challengeName[index];
	
	self thread maps\mp\gametypes\_hud_message::SplashNotifyDelayed( challengeReference + "_received", numKillsTarget );
	self SetClientDvar( "ui_intelActiveIndex", (index) );
	
	while( numKills < numKillsTarget )
	{
		self waittill( "got_a_kill", victim, weapon, meansOfDeath );
		
		if( isKillstreakWeapon( weapon ) && !isJuggernautWeapon( weapon ) )
			continue;
		
		if ( self getStance() == "prone" )
			numKills++;
	}
	
	self maps\mp\gametypes\_intel::awardPlayerChallengeComplete( index );
}


intelTbagChallenge( index )
{
	self endon("disconnect");
	self endon("death");
	self endon( "complete" );
	self endon( "intel_failed" );
	
	//numKills = 0;
	numKillsTarget = Int( level.intelChallengeStruct.challengeTarget[index] );
	challengeReference = level.intelChallengeStruct.challengeName[index];
	
	self thread maps\mp\gametypes\_hud_message::SplashNotifyDelayed( challengeReference + "_received" );
	self SetClientDvar( "ui_intelActiveIndex", (index) );
	
	self waittill( "got_a_kill", victim );
	self thread watchForTbag( victim.origin, index );
	wait( 7 );
	self thread maps\mp\gametypes\_intel::intelFailed();
}


watchForTbag( position, index )
{
	self endon("death");
	self endon( "intel_failed" );
	
	numTbag = 0;
	
	while( true )
	{
		// make sure they start in a standing position
		while( self GetStance() != "stand" )
			wait( 0.05 );

		self waittill( "adjustedStance" );
		
		while( self GetStance() != "crouch" )
			wait( 0.05 );

		if( Distance2D( self.origin, position ) < 128 )
		{
			self waittill( "adjustedStance" );
			
			while( self GetStance() != "stand" )
				wait( 0.05 );

			if( Distance2D( self.origin, position ) < 128 )
				numTbag++;
		}
		
		if( numTbag )
		{
			self thread maps\mp\gametypes\_intel::awardPlayerChallengeComplete( index );
			self notify( "complete" );
			return;
		}
	}
}