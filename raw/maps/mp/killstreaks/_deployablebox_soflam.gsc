#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

BOX_TYPE = "deployable_soflam";

// we depend on deployablebox being init'd first
init ()
{
	boxConfig = SpawnStruct();
	boxConfig.weaponInfo		= "deployable_vest_marker_mp";
	boxConfig.modelBase			= "com_deploy_ballistic_vest_friend_world";
	boxConfig.hintString		= &"KILLSTREAKS_SOFLAM_PICKUP";	
	boxConfig.capturingString	= &"KILLSTREAKS_BOX_GETTING_SOFLAM";	
	boxConfig.eventString		= &"KILLSTREAKS_DEPLOYED_SOFLAM";	
	boxConfig.streakName		= BOX_TYPE;	
	boxConfig.splashName		= "used_deployable_soflam";	
	boxConfig.shaderName		= "compass_objpoint_deploy_friendly";
	boxConfig.headIconOffset	= 20;
	boxConfig.lifeSpan			= 120.0;	
	boxConfig.useXP				= 50;	
	boxConfig.voDestroyed		= "ballistic_vest_destroyed";
	boxConfig.deployedSfx		= "mp_vest_deployed_ui";
	boxConfig.onUseSfx			= "ammo_crate_use";
	boxConfig.onUseCallback		= ::onUseDeployable;
	boxConfig.useTime			= 2000;
	boxConfig.maxHealth			= 300;
	boxConfig.damageFeedback	= "deployable_bag";
	boxConfig.deathVfx			= loadfx( "fx/fire/ballistic_vest_death" );
	boxConfig.killXP			= 100;
	boxConfig.allowMeleeDamage	= true;
	boxConfig.allowGrenadeDamage = false;

	level.boxSettings[ BOX_TYPE ] = boxConfig;
	
	level.killStreakFuncs[ BOX_TYPE ] = ::tryUseDeployableSoflam;
}

tryUseDeployableSoflam( lifeId ) // self == player
{
	result = self maps\mp\killstreaks\_deployablebox::beginDeployableViaMarker( lifeId, BOX_TYPE );

	if( ( !IsDefined( result ) || !result ) )
	{
		return false;
	}

	self maps\mp\_matchdata::logKillstreakEvent( "lasedStrike", self.origin );

	return true;
}

onUseDeployable( boxEnt )	// self == player
{
	self maps\mp\killstreaks\_killstreaks::giveKillstreak( "lasedStrike", false, false, boxEnt );
}