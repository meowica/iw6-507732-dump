#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;

//============================================
// 				constants
//============================================
CONST_AA_LAUNCHER_WEAPON 	= "stinger_mp";


//============================================
// 					init
//============================================
init()
{		
	level.killstreakFuncs["aa_launcher"] = ::tryUseAALauncher;
}	


//============================================
// 				tryUseAALauncher
//============================================
tryUseAALauncher( lifeId )
{		
	return useAALauncher( self, lifeId );
}


//============================================
// 				useAALauncher
//============================================
useAALauncher( player, lifeId )
{	
	level thread monitorWeaponSwitch( player );
	level thread monitorLauncherAmmo( player );
	
	while( true )
	{
		result = player waittill_any_return( "aa_launcher_switch", "aa_launcher_empty", "death", "disconnect" );
		
		if( result == "aa_launcher_empty" )
		{
			return true;
		}
		
		return false;
	}
}


//============================================
// 			monitorWeaponSwitch
//============================================
monitorWeaponSwitch( player )
{
	player endon( "death" );
	player endon( "disconnect" );
	player endon( "aa_launcher_empty" );
	
	currentWeapon = player getCurrentWeapon();

	while( currentWeapon == CONST_AA_LAUNCHER_WEAPON )
	{	
		player waittill( "weapon_change", currentWeapon );
	}
	
	player notify( "aa_launcher_switch" );
}


//============================================
// 			monitorLauncherAmmo
//============================================
monitorLauncherAmmo( player )
{
	player endon( "death" );
	player endon( "disconnect" );
	player endon( "aa_launcher_switch" );
	
	player notifyOnPlayerCommand( "aa_launcher_fire", "+attack" );
	
	while( true )
	{
		player waittill( "aa_launcher_fire" );
			
		ammoCount = player GetAmmoCount( CONST_AA_LAUNCHER_WEAPON ) - 1;	// -1 because the shot we just fired has not been subtracted from the ammo count yet
			
		if( !ammoCount )
		{
			player notify( "aa_launcher_empty" );
		}
	}
}