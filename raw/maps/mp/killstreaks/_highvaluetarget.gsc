#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;
#include maps\mp\gametypes\_hostmigration;

//============================================
// 				constants
//============================================
CONST_XP_INCREASE		= 0.5;
CONST_MIN_MULTIPLIER	= 1;
CONST_MAX_MULTIPLIER 	= (2 * CONST_XP_INCREASE) + CONST_MIN_MULTIPLIER;
CONST_HVT_TIME 			= 30.0;


//============================================
// 				init
//============================================
init()
{	
	level.killstreakFuncs["high_value_target"] 	= ::tryUseHighValueTarget;
}	


//============================================
// 			tryUseHighValueTarget
//============================================
tryUseHighValueTarget( lifeId )
{
	return useHighValueTarget( self, lifeId );
}


//============================================
// 			useHighValueTarget
//============================================
useHighValueTarget( player, lifeId )
{
	if( !isReallyAlive( player ) )
	{
		return false;
	}
	
	if( player.team == "spectator" )
	{
		return false;
	}
	
	if( level.teamXPScale[player.team] == CONST_MAX_MULTIPLIER )
	{
		self iPrintLnBold( &"KILLSTREAKS_HVT_MAX" );
		return false;
	}
	
	level thread setHighValueTarget( player );
		
	return true;
}


//============================================
// 			setHighValueTarget
//============================================
setHighValueTarget( player )
{
	team = player.team;
	
	level.teamXPScale[team] += CONST_XP_INCREASE;
	level.teamXPScale[team] = clamp( level.teamXPScale[team], CONST_MIN_MULTIPLIER, CONST_MAX_MULTIPLIER );
	
	waitLongDurationWithHostMigrationPause( CONST_HVT_TIME );
	
	level.teamXPScale[player.team] -= CONST_XP_INCREASE;
	level.teamXPScale[team] = clamp( level.teamXPScale[team], CONST_MIN_MULTIPLIER, CONST_MAX_MULTIPLIER );
}