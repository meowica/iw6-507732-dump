#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

BOX_TYPE = "deployable_juicebox";

// we depend on deployablebox being init'd first
init ()
{
	boxConfig = SpawnStruct();
	boxConfig.weaponInfo		= "deployable_vest_marker_mp";
	boxConfig.modelBase			= "afr_mortar_ammo_01";
	boxConfig.hintString		= &"KILLSTREAKS_DEPLOYABLE_JUICEBOX_PICKUP";	//
	boxConfig.capturingString	= &"KILLSTREAKS_DEPLOYABLE_JUICEBOX_TAKING";		//
	boxConfig.eventString		= &"KILLSTREAKS_DEPLOYABLE_JUICEBOX_TAKEN";	//
	boxConfig.streakName		= BOX_TYPE;	//
	boxConfig.splashName		= "used_deployable_juicebox";	//	
	boxConfig.shaderName		= "compass_objpoint_deploy_juiced_friendly";
	boxConfig.headIconOffset	= 25;
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
	boxConfig.deathWeaponInfo	= "deployable_ammo_mp";
	boxConfig.deathVfx			= loadfx( "fx/fire/ballistic_vest_death" );
	boxConfig.killXP			= 100;
	boxConfig.allowMeleeDamage	= true;
	boxConfig.allowGrenadeDamage = false;	// this doesn't seem dependable, like with c-4. Why isn't this in an object description?
	boxConfig.maxUses			= 4;
	
	level.boxSettings[ BOX_TYPE ] = boxConfig;
	
	level.killStreakFuncs[ BOX_TYPE ] = ::tryUseDeployableJuiced;
}

tryUseDeployableJuiced( lifeId ) // self == player
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
	return true;
}

onUseDeployable( boxEnt )	// self == player
{
	if ( GetDvar ( "g_gametype" ) == "aliens" )
	{
		if ( Isdefined ( boxEnt.upgrade_rank ) && boxEnt.upgrade_rank == 0 )
		{
			self thread maps\mp\perks\_perkfunctions::setJuiced( 15 );
		}
		if ( Isdefined ( boxEnt.upgrade_rank ) && boxEnt.upgrade_rank == 1 )
		{
			self thread maps\mp\perks\_perkfunctions::setJuiced( 30 );
		}
		if ( Isdefined ( boxEnt.upgrade_rank ) && boxEnt.upgrade_rank == 2 )
		{
			self thread maps\mp\perks\_perkfunctions::setJuiced( 45 );
		}
		if ( Isdefined ( boxEnt.upgrade_rank ) && boxEnt.upgrade_rank == 3 )
		{
			self thread maps\mp\perks\_perkfunctions::setJuiced( 60 );
		}
		if ( Isdefined ( boxEnt.upgrade_rank ) && boxEnt.upgrade_rank == 4 )
		{
			self thread maps\mp\perks\_perkfunctions::setJuiced( 75 );
		}
	}
	else
	{
		self thread maps\mp\perks\_perkfunctions::setJuiced( 15 );
	}
}

canUseDeployable()	// self == player
{
	return ( !(self isJuggernaut()) && !(self maps\mp\perks\_perkfunctions::hasJuiced()) );
}


