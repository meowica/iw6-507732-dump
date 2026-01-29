#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;
#include maps\mp\agents\_agent_utility;
#include maps\mp\gametypes\_damage;
#include maps\mp\bots\_bots_util;
#include maps\mp\bots\_bots_strategy;

//===========================================
// 				constants
//===========================================
CONST_MAX_ACTIVE_KILLSTREAK_AGENTS_PER_GAME		= 5;
CONST_MAX_ACTIVE_KILLSTREAK_AGENTS_PER_PLAYER 	= 2;


//===========================================
// 					init
//===========================================
init()
{
	level.killStreakFuncs["agent"] 			= ::tryUseSquadmate;
	level.killStreakFuncs["recon_agent"] 	= ::tryUseReconSquadmate;
}


//===========================================
// 				setup_callbacks
//===========================================
setup_callbacks()
{
	level.agent_funcs["squadmate"] = level.agent_funcs["player"];
	
	level.agent_funcs["squadmate"]["think"] 		= ::squadmate_agent_think;
	level.agent_funcs["squadmate"]["on_killed"]		= ::on_agent_squadmate_killed;
	level.agent_funcs["squadmate"]["on_damaged"]	= maps\mp\agents\_agents::on_agent_player_damaged;
}


//===========================================
// 				tryUseSquadmate
//===========================================
tryUseSquadmate( lifeId )
{
	return useSquadmate( "agent" );
}


//===========================================
// 			tryUseReconSquadmate
//===========================================
tryUseReconSquadmate( lifeId )
{
	return useSquadmate( "reconAgent" );
}


//===========================================
// 				useSquadmate
//===========================================
useSquadmate( killStreakType )
{
	// limit the number of active "squadmate" agents allowed per game
	if( getNumActiveAgents( "squadmate" ) >= CONST_MAX_ACTIVE_KILLSTREAK_AGENTS_PER_GAME )
	{
		self iPrintLnBold( &"KILLSTREAKS_AGENT_MAX" );
		return false;
	}
	
	// limit the number of active agents allowed per player
	if( getNumOwnedActiveAgents( self ) >= CONST_MAX_ACTIVE_KILLSTREAK_AGENTS_PER_PLAYER )
	{
		self iPrintLnBold( &"KILLSTREAKS_AGENT_MAX" );
		return false;
	}
		
	// try to spawn the agent on a path node near the player
	nearestPathNode = self getPathNodeNearPlayer();
	
	if( !IsDefined(nearestPathNode) )
	{
		return false;
	}

	// make sure the player is still alive before the agent trys to spawn on the player
	if( !isReallyAlive(self) )
	{
		return false;
	}
	
	// find an available agent
	agent = getFreeAgent( "squadmate" );	
	if( !IsDefined( agent ) )
	{
		self iPrintLnBold( &"KILLSTREAKS_AGENT_MAX" );
		return false;
	}

	// set the agent to the player's team
	agent set_agent_team( self.team, self );
	
	spawnOrigin = nearestPathNode.origin;
	spawnAngles = VectorToAngles( self.origin - nearestPathNode.origin );
	
	agent.agent_gameParticipant = true;
	agent.killStreakType = killStreakType;
	
	agent thread [[ agent agentFunc("spawn") ]]( spawnOrigin, spawnAngles, self );
	
	agent bot_set_personality("default");
	agent BotSetDifficulty( "veteran" );

	return true;
}


//=======================================================
//				squadmate_agent_think
//=======================================================
squadmate_agent_think()
{
	if( self.killStreakType == "reconAgent" )
	{
		if ( !self isJuggernaut() )
		{
			self thread maps\mp\killstreaks\_juggernaut::giveJuggernaut( "juggernaut_recon" );
			wait(0.05);	// Need to wait 0.05s here, so that next time we run squadmate_agent_think() self.isJuggernautRecon has been set (giveJuggernaut has a 0.05s wait)
		}
	}
	
	if ( !self bot_is_guarding_player( self.owner ) )
	{
		self bot_guard_player( self.owner, 350 );
	}
}


//=======================================================
//				on_agent_squadmate_killed
//=======================================================
on_agent_squadmate_killed(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration)
{
	// ragdoll
	self.body = self CloneAgent( deathAnimDuration );
	thread delayStartRagdoll( self.body, sHitLoc, vDir, sWeapon, eInflictor, sMeansOfDeath );
		
	// award XP for killing agents
	if( isPlayer( eAttacker ) && (!isDefined(self.owner) || eAttacker != self.owner) )
	{
		eAttacker thread maps\mp\gametypes\_rank::giveRankXP( "kill", 100, sWeapon, sMeansOfDeath );	
		eAttacker thread maps\mp\killstreaks\_killstreaks::giveAdrenaline( "vehicleDestroyed" );		
	}

	self maps\mp\agents\_agents::removeKillCamEntity();
	self maps\mp\agents\_agent_utility::deactivateAgent();
}
