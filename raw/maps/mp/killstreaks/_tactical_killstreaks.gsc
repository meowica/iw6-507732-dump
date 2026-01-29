#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

/*
	Tactical killstreak selection: the player will earn the killstreak and be able to select either one of them from a group
*/

KILLSTREAK_GIMME_SLOT = 0;
KILLSTREAK_SLOT_1 = 1;
KILLSTREAK_SLOT_2 = 2;
KILLSTREAK_SLOT_3 = 3;

init()
{
	level.killStreakFuncs[ "tactical_assault_1" ] =	::tryUseTactical;
	level.killStreakFuncs[ "tactical_assault_2" ] =	::tryUseTactical;
	level.killStreakFuncs[ "tactical_assault_3" ] =	::tryUseTactical;
	level.killStreakFuncs[ "tactical_assault_4" ] =	::tryUseTactical;
	level.killStreakFuncs[ "tactical_assault_5" ] =	::tryUseTactical;
	level.killStreakFuncs[ "tactical_assault_6" ] =	::tryUseTactical;
	level.killStreakFuncs[ "tactical_assault_7" ] =	::tryUseTactical;
	level.killStreakFuncs[ "tactical_assault_8" ] =	::tryUseTactical;

	// assault
	level.tacticalKillstreaks[ "assault" ][ "tactical_assault_1" ][ 0 ] = "speed_boost";
	level.tacticalKillstreaks[ "assault" ][ "tactical_assault_1" ][ 2 ] = "regen_faster";

	//level.tacticalKillstreaks[ "assault" ][ "tactical_assault_2" ][ 0 ] = "refill_grenades";
	//level.tacticalKillstreaks[ "assault" ][ "tactical_assault_2" ][ 1 ] = "refill_ammo";
	level.tacticalKillstreaks[ "assault" ][ "tactical_assault_2" ][ 0 ] = "deployable_grenades";
	level.tacticalKillstreaks[ "assault" ][ "tactical_assault_2" ][ 1 ] = "deployable_ammo";
	level.tacticalKillstreaks[ "assault" ][ "tactical_assault_2" ][ 2 ] = "personal_3dping";

	level.tacticalKillstreaks[ "assault" ][ "tactical_assault_3" ][ 0 ] = "predator_missile";
	level.tacticalKillstreaks[ "assault" ][ "tactical_assault_3" ][ 1 ] = "guard_dog";
	level.tacticalKillstreaks[ "assault" ][ "tactical_assault_3" ][ 2 ] = "ims";

	level.tacticalKillstreaks[ "assault" ][ "tactical_assault_4" ][ 0 ] = "sentry";
	level.tacticalKillstreaks[ "assault" ][ "tactical_assault_4" ][ 1 ] = "lasedStrike";
	level.tacticalKillstreaks[ "assault" ][ "tactical_assault_4" ][ 2 ] = "precision_airstrike";

	level.tacticalKillstreaks[ "assault" ][ "tactical_assault_5" ][ 0 ] = "agent";
	level.tacticalKillstreaks[ "assault" ][ "tactical_assault_5" ][ 1 ] = "helicopter";
	level.tacticalKillstreaks[ "assault" ][ "tactical_assault_5" ][ 2 ] = "heli_sniper";

	level.tacticalKillstreaks[ "assault" ][ "tactical_assault_6" ][ 0 ] = "airdrop_juggernaut_maniac";
	level.tacticalKillstreaks[ "assault" ][ "tactical_assault_6" ][ 1 ] = "stealth_airstrike";
	level.tacticalKillstreaks[ "assault" ][ "tactical_assault_6" ][ 2 ] = "littlebird_support";

	level.tacticalKillstreaks[ "assault" ][ "tactical_assault_7" ][ 0 ] = "airdrop_juggernaut";
	level.tacticalKillstreaks[ "assault" ][ "tactical_assault_7" ][ 1 ] = "remote_mortar";
	level.tacticalKillstreaks[ "assault" ][ "tactical_assault_7" ][ 2 ] = "remote_tank";

	level.tacticalKillstreaks[ "assault" ][ "tactical_assault_8" ][ 0 ] = "ac130";
	level.tacticalKillstreaks[ "assault" ][ "tactical_assault_8" ][ 1 ] = "helicopter_flares";
	level.tacticalKillstreaks[ "assault" ][ "tactical_assault_8" ][ 2 ] = "none"; // TODO: finish heli_pilot
}

tryUseTactical( tacticalName, lifeId, kID )
{
	// NOTE: maybe everything can live in this function and not run another thread
	result = self showTacticalSelections( level.tacticalKillstreaks[ self.streakType ][ tacticalName ], lifeId, kID );
	return result;
}

showTacticalSelections( tacticalArray, lifeId, kID ) // self == player
{
	self endon( "disconnect" );
	self notify( "showTacticalSelections" );

	ksUp =		tacticalArray[ 0 ];
	ksLeft =	tacticalArray[ 1 ];
	ksDown =	tacticalArray[ 2 ];

	level thread watchGameEnded( self );

	// need to let the killstreak toggling know that we're using the dpad up/down right now
	self.showingTacticalSelections = true;

	// TODO: need a way to turn off altmode (left dpad)
	self NotifyOnPlayerCommand( "dpad_up", "+actionslot 1" );
	self NotifyOnPlayerCommand( "dpad_down", "+actionslot 2" );
	self NotifyOnPlayerCommand( "dpad_left", "+actionslot 3" );
	self NotifyOnPlayerCommand( "dpad_right", "+actionslot 4" );

	self _setActionSlot( 3, "" ); // dpad left

	// get the icons and names to show
	ksUp_icon = TableLookupRowNum( "mp/killstreakTable.csv", 1, ksUp );
	ksLeft_icon = TableLookupRowNum( "mp/killstreakTable.csv", 1, ksLeft );
	ksDown_icon = TableLookupRowNum( "mp/killstreakTable.csv", 1, ksDown );

	// LUA: let the killstreak section of the hud know that the player has engaged in a killstreak selection
	self SetClientDvar( "ui_killstreak_show_selections_icon_1", ksUp_icon );
	self SetClientDvar( "ui_killstreak_show_selections_icon_2", ksLeft_icon );
	self SetClientDvar( "ui_killstreak_show_selections_icon_3", ksDown_icon );
	self SetClientDvar( "ui_killstreak_show_selections", 1 );
	// END LUA

	// have the user push up or down on the dpad for now
	// don't let them put it away, keep it up until they make a selection
	string_array = [ "dpad_up", "dpad_left", "dpad_down", "dpad_right", "death", "showTacticalSelections", "game_ended" ];
	
	// TEMP: checking for "none" and coming back around, really there should be no "none" so no need for the loop
	while( true )
	{
		result = self waittill_any_in_array_return( string_array );

		if( result == "dpad_up" && ksUp == "none" )
			continue;
		if( result == "dpad_left" && ksLeft == "none" )
			continue;
		if( result == "dpad_down" && ksDown == "none" )
			continue;

		break;
	}

	switch( result )
	{
	case "dpad_up":
	case "dpad_left":
	case "dpad_down":
		if( !self validateUseStreak() )
			return false;
		break;
	}

	// call the killstreak
	switch( result )
	{
	case "dpad_up":
		self callTacticalKillstreak( ksUp );
		break;
	case "dpad_left":
		self callTacticalKillstreak( ksLeft );
		break;
	case "dpad_down":
		self callTacticalKillstreak( ksDown );
		break;
	case "dpad_right": // cancel
		self PlayLocalSound( "detpack_trigger" );
		break;
	default:
		break;
	}

	// LUA: let the killstreak section of the hud know that the player is done with the killstreak selection
	self SetClientDvar( "ui_killstreak_show_selections", 0 );
	// END LUA

	wait( 0.5 );

	if( result != "showTacticalSelections" )
	{
		self.showingTacticalSelections = false;
		self _setActionSlot( 3, "altMode" ); // dpad left
	}
	
	if( result == "death" || result == "dpad_right" )
		return false;

	return true;
}

callTacticalKillstreak( streakName ) // self == player
{
	// first clear the slot the tactical killstreak was using
	if( self.killstreakIndexWeapon == KILLSTREAK_GIMME_SLOT )
		self.pers[ "killstreaks" ][ self.pers["killstreaks"][ KILLSTREAK_GIMME_SLOT ].nextSlot ] = undefined;
	else
		self.pers[ "killstreaks" ][ self.killstreakIndexWeapon ].available = false;

	// now call in the selected killstreak
	self maps\mp\killstreaks\_killstreaks::giveKillstreak( streakName );
	killstreakWeapon = getKillstreakWeapon( streakName );

	while( self isChangingWeapon() )
		wait( 0.05 );

	self SwitchToWeapon( killstreakWeapon );
}

watchGameEnded( player ) // self == level
{
	player endon( "disconnect" );
	
	level notify( "watchGameEnded" );
	level endon( "watchGameEnded" );

	self waittill( "game_ended" );
	
	if( IsDefined( player ) )
		player notify( "game_ended" );
}

watchTacticalKillstreakUse() // self == player
{
	self notify( "watchTacticalKillstreakUse" );
	self endon( "watchTacticalKillstreakUse" );

	self endon( "disconnect" );
	self endon( "game_ended" );

	self NotifyOnPlayerCommand( "dpad_right", "+actionslot 4" );
	
	while( true )
	{
		self waittill( "dpad_right" );

		if( !IsDefined( self.killstreakIndexWeapon ) )
			return;

		if( self isUsingRemote() )
			continue;

 		self_pers_killstreaks = self.pers[ "killstreaks" ];

		streakName =	self_pers_killstreaks[ self.killstreakIndexWeapon ].streakName;
		lifeId =		self_pers_killstreaks[ self.killstreakIndexWeapon ].lifeId;
		isEarned =		self_pers_killstreaks[ self.killstreakIndexWeapon ].earned;
		awardXp =		self_pers_killstreaks[ self.killstreakIndexWeapon ].awardXp;
		kID =			self_pers_killstreaks[ self.killstreakIndexWeapon ].kID;
		isGimme =		self_pers_killstreaks[ self.killstreakIndexWeapon ].isGimme;

		if( !isTacticalKillstreak( streakName ) )
			continue;

		self PlayLocalSound( "detpack_trigger" );

		if( self [[ level.killstreakFuncs[ streakName ] ]]( streakName, lifeId, kID ) )
		{
			self_pers_killstreaks = self.pers[ "killstreaks" ];
			// do we still have other tactical killstreaks to use?
			any_available = false;
			for( i = KILLSTREAK_GIMME_SLOT; i < self_pers_killstreaks.size; i++ )
			{
				if( IsDefined( self_pers_killstreaks[ i ].streakName ) && isTacticalKillstreak( self_pers_killstreaks[ i ].streakName ) )
				{
					any_available = true;
					break;
				}
			}

			if( !any_available )
				return;
		}
	}
}