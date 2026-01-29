#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

BOX_TYPE = "deployable_ammo";

// we depend on deployablebox being init'd first
init ()
{
	boxConfig = SpawnStruct();
	boxConfig.weaponInfo		= "deployable_vest_marker_mp";
	boxConfig.modelBase			= "mil_ammo_case_1_open";
	boxConfig.hintString		= &"KILLSTREAKS_DEPLOYABLE_AMMO_PICKUP";	//
	boxConfig.capturingString	= &"KILLSTREAKS_DEPLOYABLE_AMMO_TAKING";		//
	boxConfig.eventString		= &"KILLSTREAKS_DEPLOYABLE_AMMO_TAKEN";	//
	boxConfig.streakName		= BOX_TYPE;	//
	boxConfig.splashName		= "used_deployable_ammo";	//	
	boxConfig.shaderName		= "compass_objpoint_deploy_ammo_friendly";
	boxConfig.headIconOffset	= 25;
	boxConfig.lifeSpan			= 90.0;	
	boxConfig.useXP				= 50;	
	boxConfig.voDestroyed		= "ballistic_vest_destroyed";
	boxConfig.deployedSfx		= "mp_vest_deployed_ui";
	boxConfig.onUseSfx			= "ammo_crate_use";
	boxConfig.onUseCallback		= ::onUseDeployable;
	boxConfig.canUseCallback	= ::canUseDeployable;
	boxConfig.useTime			= 500;
	boxConfig.maxHealth			= 150;
	boxConfig.damageFeedback	= "deployable_bag";
	boxConfig.deathWeaponInfo	= "deployable_ammo_mp";
	boxConfig.deathVfx			= loadfx( "fx/explosions/clusterbomb_exp_direct_runner" );
	boxConfig.deathDamageRadius	= 256;	 // these params taken from frag_grenade
	boxConfig.deathDamageMax	= 130;
	boxconfig.deathDamageMin	= 50;
	boxConfig.killXP			= 100;
	boxConfig.allowMeleeDamage	= true;
	boxConfig.allowGrenadeDamage = true;	// this doesn't seem dependable, like with c-4. Why isn't this in an object description?
	boxConfig.maxUses			= 4;
	
	level.boxSettings[ BOX_TYPE ] = boxConfig;
	
	level.killStreakFuncs[ BOX_TYPE ] = ::tryUseDeployableAmmo;
}

tryUseDeployableAmmo( lifeId ) // self == player
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
	if( (GetDvar("g_gametype")) == "aliens" )
	{
		self addAlienWeaponAmmo( boxEnt );
	}
	else
	{
		self addAllWeaponAmmo();
	}
}
addAllWeaponAmmo()
{
	weaponList = self GetWeaponsListAll();
	
	if ( IsDefined( weaponList ) )
	{
		foreach ( weaponName in weaponList )
		{
			// allow bullet weapons to get extra clips
			if ( maps\mp\gametypes\_weapons::isBulletWeapon( weaponName ) )
			{
				self addOneWeaponAmmo( weaponName, 2 );
			}
			// limit the ammo of launchers so they aren't abused
			else if ( WeaponClass( weaponName ) == "rocketlauncher" )
			{
				self addOneWeaponAmmo( weaponName, 1 );
				// self GiveStartAmmo( weaponName );
			}
		}
	}
}

addOneWeaponAmmo( weaponName, numClips )	// self == plyaer
{
	// want players to be able to go above starting ammo
	// but don't want it to be too crazy
	clipSize = WeaponClipSize( weaponName );
	curStock = self GetWeaponAmmoStock( weaponName );
	self SetWeaponAmmoStock( weaponName, curStock + numClips * clipSize );
	
	// self GiveStartAmmo( weaponName );
}

addAlienWeaponAmmo( boxEnt )
{
	primary_weapons = self GetWeaponsListPrimaries();

	if ( Isdefined ( boxEnt.upgrade_rank ) && boxEnt.upgrade_rank == 0 )
	{
		foreach ( weapon in primary_weapons )
		{
			start_stock = WeaponStartAmmo( weapon );
			self SetWeaponAmmoStock( weapon, start_stock );
		}
	}
	
	if ( Isdefined ( boxEnt.upgrade_rank ) && boxEnt.upgrade_rank == 1 )
	{
		foreach ( weapon in primary_weapons )
		{
			max_stock = WeaponMaxAmmo( weapon );
			self SetWeaponAmmoStock( weapon, max_stock );
		}
	}
	
	if ( Isdefined ( boxEnt.upgrade_rank ) && boxEnt.upgrade_rank == 2 )
	{
		foreach ( weapon in primary_weapons )
		{
			max_stock = WeaponMaxAmmo( weapon );
			self SetWeaponAmmoStock( weapon, max_stock );
		}
	}
	
	if ( Isdefined ( boxEnt.upgrade_rank ) && boxEnt.upgrade_rank == 3 )
	{
		foreach ( weapon in primary_weapons )
		{
			max_stock = WeaponMaxAmmo( weapon );
			self SetWeaponAmmoStock( weapon, max_stock );
		}
	}
	
	if ( Isdefined ( boxEnt.upgrade_rank ) && boxEnt.upgrade_rank == 4 )
	{
		foreach ( weapon in primary_weapons )
		{
			max_stock = WeaponMaxAmmo( weapon );
			self SetWeaponAmmoStock( weapon, max_stock );
		}
	}
	
}

canUseDeployable()	// self == player
{
	return ( !self isJuggernaut() );
}
