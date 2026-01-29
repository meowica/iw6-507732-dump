#include maps\mp\_utility;
#include common_scripts\utility;

/*
	Perks as killstreaks: 
		The player will earn the killstreak and automatically get the perk.
		This has been repurposed to be used for very simple killstreaks that are perk-like.
*/

KILLSTREAK_GIMME_SLOT = 0;
KILLSTREAK_SLOT_1 = 1;
KILLSTREAK_SLOT_2 = 2;
KILLSTREAK_SLOT_3 = 3;
KILLSTREAK_ALL_PERKS_SLOT = 4;
KILLSTREAK_STACKING_START_SLOT = 5;

init()
{
	level.killStreakFuncs[ "specialty_longersprint_ks" ] =		::tryUseExtremeConditioning;
	level.killStreakFuncs[ "specialty_fastreload_ks" ] =		::tryUseSleightOfHand;
	level.killStreakFuncs[ "specialty_scavenger_ks" ] =			::tryUseScavenger;
	level.killStreakFuncs[ "specialty_blindeye_ks" ] =			::tryUseBlindEye;
	level.killStreakFuncs[ "specialty_paint_ks" ] =				::tryUsePaint;
	level.killStreakFuncs[ "specialty_hardline_ks" ] =			::tryUseHardline;
	level.killStreakFuncs[ "specialty_coldblooded_ks" ] =		::tryUseColdBlooded;
	level.killStreakFuncs[ "specialty_quickdraw_ks" ] =			::tryUseQuickdraw;
	level.killStreakFuncs[ "specialty_assists_ks" ] =			::tryUseAssists;
	level.killStreakFuncs[ "_specialty_blastshield_ks" ] =		::tryUseBlastshield;
	level.killStreakFuncs[ "specialty_detectexplosive_ks" ] =	::tryUseSitRep;
	level.killStreakFuncs[ "specialty_autospot_ks" ] =			::tryUseIronLungs;
	level.killStreakFuncs[ "specialty_bulletaccuracy_ks" ] =	::tryUseSteadyAim;
	level.killStreakFuncs[ "specialty_quieter_ks" ] =			::tryUseDeadSilence;
	level.killStreakFuncs[ "specialty_stalker_ks" ] =			::tryUseStalker;
	level.killStreakFuncs[ "specialty_marathon_ks" ] =			::tryUseMarathon;
	level.killStreakFuncs[ "specialty_bulletpenetration_ks" ] = ::tryUseBulletPenetration;
	level.killStreakFuncs[ "specialty_explosivedamage_ks" ] =	::tryUseExplosiveDamage;
	level.killStreakFuncs[ "all_perks_bonus" ] =				::tryUseAllPerks;

	level.killStreakFuncs[ "speed_boost" ] =		::tryUseSpeedBoost;
	level.killStreakFuncs[ "refill_grenades" ] =	::tryUseRefillGrenades;
	level.killStreakFuncs[ "refill_ammo" ] =		::tryUseRefillAmmo;
	level.killStreakFuncs[ "regen_faster" ] =		::tryUseRegenFaster;
}

tryUseSpeedBoost( lifeId )
{
	self doKillstreakFunctions( "specialty_juiced", "speed_boost" );
	return true;
}

tryUseRefillGrenades( lifeId )
{
	self doKillstreakFunctions( "specialty_refill_grenades", "refill_grenades" );
	return true;
}

tryUseRefillAmmo( lifeId )
{
	self doKillstreakFunctions( "specialty_refill_ammo", "refill_ammo" );
	return true;
}

tryUseRegenFaster( lifeId )
{
	self doKillstreakFunctions( "specialty_regenfaster", "regen_faster" );
	return true;
}

tryUseAllPerks()
{
	// left blank on purpose
}

tryUseBlindEye( lifeId )
{
	self doPerkFunctions( "specialty_blindeye" );
}

tryUsePaint( lifeId )
{
	self doPerkFunctions( "specialty_paint" );
}

tryUseAssists( lifeId )
{
	self doPerkFunctions( "specialty_assists" );
}

tryUseSteadyAim( lifeId )
{
	self doPerkFunctions( "specialty_bulletaccuracy" );
}

tryUseStalker( lifeId )
{
	self doPerkFunctions( "specialty_stalker" );
}

tryUseExtremeConditioning( lifeId )
{
	self doPerkFunctions( "specialty_longersprint" );
}

tryUseSleightOfHand( lifeId )
{
	self doPerkFunctions( "specialty_fastreload" );
}

tryUseScavenger( lifeId )
{
	self doPerkFunctions( "specialty_scavenger" );
}

tryUseHardline( lifeId )
{
	self doPerkFunctions( "specialty_hardline" );
	self maps\mp\killstreaks\_killstreaks::setStreakCountToNext();
}

tryUseColdBlooded( lifeId )
{
	self doPerkFunctions( "specialty_coldblooded" );
}

tryUseQuickdraw( lifeId )
{
	self doPerkFunctions( "specialty_quickdraw" );
}

tryUseBlastshield( lifeId )
{
	self doPerkFunctions( "_specialty_blastshield" );
}

tryUseSitRep( lifeId )
{
	self doPerkFunctions( "specialty_detectexplosive" );
}

tryUseIronLungs( lifeId )
{
	self doPerkFunctions( "specialty_autospot" );
}

tryUseAssassin( lifeId )
{
	self doPerkFunctions( "specialty_heartbreaker" );
}

tryUseDeadSilence( lifeId )
{
	self doPerkFunctions( "specialty_quieter" );
}

tryUseMarathon( lifeId )
{
	self doPerkFunctions( "specialty_marathon" );
}

tryUseBulletPenetration( lifeId )
{
	self doPerkFunctions( "specialty_bulletpenetration" );
}

tryUseExplosiveDamage( lifeId )
{
	self doPerkFunctions( "specialty_explosivedamage" );
}

doPerkFunctions( perkName )
{
	self givePerk( perkName, false );
	self thread watchDeath( perkName );
	self thread checkForPerkUpgrade( perkName );

	self maps\mp\_matchdata::logKillstreakEvent( perkName + "_ks", self.origin );
}

doKillstreakFunctions( perkName, killstreakEvent )
{
	self givePerk( perkName, false );

	if( IsDefined( killstreakEvent ) )
		self maps\mp\_matchdata::logKillstreakEvent( killstreakEvent, self.origin );
}

watchDeath( perkName )
{
	self endon( "disconnect" );
	self waittill( "death" );
	self _unsetPerk( perkName );
	//self _unsetExtraPerks( perkName );
}

checkForPerkUpgrade( perkName )
{
	// check for pro version
	perk_upgrade = self maps\mp\gametypes\_class::getPerkUpgrade( perkName );
	if( perk_upgrade != "specialty_null" )
	{
		self givePerk( perk_upgrade, false );
		self thread watchDeath( perk_upgrade );
	}
}

isPerkStreakOn( streakName ) // self == player
{
	// return whether the perk is available right now or not
	for( i = KILLSTREAK_SLOT_1; i < KILLSTREAK_SLOT_3 + 1; i++ )
	{
		if( IsDefined( self.pers[ "killstreaks" ][ i ].streakName ) && self.pers[ "killstreaks" ][ i ].streakName == streakName )
		{
			if( self.pers[ "killstreaks" ][ i ].available )
				return true;
		}
	}

	return false;
}
