#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

BOX_TYPE = "deployable_vest";

// we depend on deployablebox being init'd first
init ()
{
	boxConfig = SpawnStruct();
	boxConfig.weaponInfo		= "deployable_vest_marker_mp";
	boxConfig.modelBase			= "com_deploy_ballistic_vest_friend_world";
	boxConfig.hintString		= &"KILLSTREAKS_LIGHT_ARMOR_PICKUP";	
	boxConfig.capturingString	= &"KILLSTREAKS_BOX_GETTING_VEST";	
	boxConfig.eventString		= &"KILLSTREAKS_DEPLOYED_VEST";	
	boxConfig.streakName		= BOX_TYPE;	
	boxConfig.splashName		= "used_deployable_vest";	
	boxConfig.shaderName		= "compass_objpoint_deploy_friendly";
	boxConfig.headIconOffset	= 20;
	boxConfig.lifeSpan			= 90.0;	
	boxConfig.useXP				= 50;	
	boxConfig.voDestroyed		= "ballistic_vest_destroyed";
	boxConfig.deployedSfx		= "mp_vest_deployed_ui";
	boxConfig.onUseSfx			= "ammo_crate_use";
	boxConfig.onUseCallback		= ::onUseDeployable;
	boxConfig.canUseCallback	= ::canUseDeployable;
	boxConfig.useTime			= 500;
	boxConfig.maxHealth			= 300;
	boxConfig.damageFeedback	= "deployable_bag";
	boxConfig.deathVfx			= loadfx( "fx/fire/ballistic_vest_death" );
	boxConfig.killXP			= 100;
	boxConfig.allowMeleeDamage	= true;
	boxConfig.allowGrenadeDamage = false;	// this doesn't seem dependable, like with c-4. Why isn't this in an object description?
	boxConfig.maxUses			= 4;
	
	level.boxSettings[ BOX_TYPE ] = boxConfig;
	
	level.killStreakFuncs[ BOX_TYPE ] = ::tryUseDeployableVest;
}

tryUseDeployableVest( lifeId ) // self == player
{
	result = self maps\mp\killstreaks\_deployablebox::beginDeployableViaMarker( lifeId, BOX_TYPE );

	if( ( !IsDefined( result ) || !result ) )
	{
		return false;
	}

	if( (GetDvar("g_gametype")) != "aliens" )
	{
		self maps\mp\_matchdata::logKillstreakEvent( BOX_TYPE, self.origin );
	}

	// we used to give the player a vest/health after we deployed the box
	// instead, we automatically call onUseCallback once in _deployabox.gsc
	// (because we don't want the player to be able to manually use vest again until he dies
	
	return true;
}

canUseDeployable()	// self == player
{
	return ( !(self maps\mp\perks\_perkfunctions::hasLightArmor()) && !self isJuggernaut() );
}

onUseDeployable( boxEnt )	// self == player
{

	if ( GetDvar ( "g_gametype" ) == "aliens" )
	{
		if ( Isdefined ( boxEnt.upgrade_rank ) && boxEnt.upgrade_rank == 0 )
		{
			self maps\mp\perks\_perkfunctions::setLightArmor( 25 );
		}
		if ( Isdefined ( boxEnt.upgrade_rank ) && boxEnt.upgrade_rank == 1 )
		{
			self maps\mp\perks\_perkfunctions::setLightArmor( 50 );
		}
		if ( Isdefined ( boxEnt.upgrade_rank ) && boxEnt.upgrade_rank == 2 )
		{
			self maps\mp\perks\_perkfunctions::setLightArmor( 75 );
		}
		if ( Isdefined ( boxEnt.upgrade_rank ) && boxEnt.upgrade_rank == 3 )
		{
			self maps\mp\perks\_perkfunctions::setLightArmor( 100 );
		}
		if ( Isdefined ( boxEnt.upgrade_rank ) && boxEnt.upgrade_rank == 4 )
		{
			self maps\mp\perks\_perkfunctions::setLightArmor( 125 );
		}
		
		self notify( "enable_armor" );
	}		
	else
		self maps\mp\perks\_perkfunctions::setLightArmor();
}