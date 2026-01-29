#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

UNLOCK_TABLE_ASSAULT_NAME = "mp/unlocktable_assault.csv";
UNLOCK_TABLE_LMG_NAME	  = "mp/unlocktable_lmg.csv";
UNLOCK_TABLE_SHOTGUN_NAME = "mp/unlocktable_shotgun.csv";
UNLOCK_TABLE_SMG_NAME	  = "mp/unlocktable_smg.csv";
UNLOCK_TABLE_SNIPER_NAME  = "mp/unlocktable_sniper.csv";
UNLOCK_WEAPON_COL		  = 0;

ABILITY_TABLE_NAME = "mp/abilityTable.csv";
ABILITY_NAME_COL = 1;
ABILITY_IMAGE_COL = 4;
ABILITY_TIME_OUT_COL = 6;
ABILITY_RECHARGE_COL = 7;
ABILITY_SCRIPT_MADE_COL = 8;
ABILITY_USE_SOUND_COL = 9;
ABILITY_USE_DIALOG_COL = 10;
ABILITY_READY_SOUND_COL = 11;
ABILITY_TIME_OUT_SOUND_COL = 12;

init()
{
	PreCacheShader( "ability_quieter" );
	PreCacheShader( "ability_lightweight" );
	PreCacheShader( "ability_scavenger" );
	PreCacheShader( "ability_radar" );
	PreCacheShader( "ability_bulletdamage" );
	PreCacheShader( "ability_suppressweapon" );

	// abilities that currently only exist in script: these will error if passed to "setPerk", etc... CASE SENSITIVE! must be lower
	level.scriptAbilities = [];
	level.abilityCanSetFuncs = [];
	level.abilitySetFuncs = [];
	level.abilityUnsetFuncs = [];

	level.scriptAbilities[ "specialty_autospot" ] = true;
	level.scriptAbilities[ "specialty_paint" ] = true;
	level.scriptAbilities[ "specialty_lightweight" ] = true;
	level.scriptAbilities[ "specialty_armorvest" ] = true;
	level.scriptAbilities[ "specialty_explosivedamage" ] = true;
	level.scriptAbilities[ "specialty_infiniteammo" ] = true;
	level.scriptAbilities[ "specialty_radar" ] = true;
	level.scriptAbilities[ "specialty_regenfaster" ] = true;
	level.scriptAbilities[ "specialty_absorb" ] = true;
	level.scriptAbilities[ "specialty_doublexp" ] = true;
	level.scriptAbilities[ "specialty_fastrecharge" ] = true;
	level.scriptAbilities[ "specialty_extratime" ] = true;
	level.scriptAbilities[ "specialty_suppressweapon" ] = true;

	level.abilitySetFuncs[ "specialty_autospot" ] = ::setAutoSpot;
	level.abilityUnsetFuncs[ "specialty_autospot" ] = ::unsetAutoSpot;

	level.abilitySetFuncs[ "specialty_detectexplosive" ] = ::setDetectExplosive;
	level.abilityUnsetFuncs[ "specialty_detectexplosive" ] = ::unsetDetectExplosive;

	level.abilitySetFuncs[ "specialty_lightweight" ] = ::setLightWeight;
	level.abilityUnsetFuncs[ "specialty_lightweight" ] = ::unsetLightWeight;

	level.abilitySetFuncs[ "specialty_radar" ] = ::setPersonalRadar;
	level.abilityUnsetFuncs[ "specialty_radar" ] = ::unsetPersonalRadar;

	level.abilitySetFuncs[ "specialty_infiniteammo" ] = ::setInfiniteAmmo;
	level.abilityUnsetFuncs[ "specialty_infiniteammo" ] = ::unsetInfiniteAmmo;

	level.abilitySetFuncs[ "specialty_quieter" ] = ::setQuieter;
	level.abilityUnsetFuncs[ "specialty_quieter" ] = ::unsetQuieter;
	
	level.abilityCanSetFuncs[ "specialty_suppressweapon" ] = ::canSetSuppressWeapon;
	level.abilitySetFuncs[ "specialty_suppressweapon" ] = ::setSuppressWeapon;
	level.abilityUnsetFuncs[ "specialty_suppressweapon" ] = ::unsetSuppressWeapon;

	level.fastRechargeMod = 5.0; // seconds to take off the recharge time when the player has the fast recharge passive ability
	level.extraTimeMod = 5.0; // seconds to add to the usage time when the player has the extra time passive ability

	level thread onPlayerConnect();

/#
	SetDevDvarIfUninitialized( "scr_ability_timeout", 0 );
	SetDevDvarIfUninitialized( "scr_ability_recharge", 0 );
#/
}

onPlayerConnect()
{
	while( true )
	{
		level waittill( "connected", player );
		player thread onPlayerSpawned();
		player thread watchAbilityUse();
	}
}

onPlayerSpawned()
{
	self endon( "disconnect" );

	self.abilities = [];
	self.pers[ "ability" ] = "specialty_null";
	
	while( true )
	{
		self waittill( "spawned_player" );

		// make sure we keep the ability going for the full time even after death and respawn
		if( IsDefined( self.pers[ "abilityOn" ] ) && self.pers[ "abilityOn" ] )
			self giveAbility( self.pers[ "ability" ], false );
	}
}

setupActiveAbility( abilityName ) // self == player
{
	// TODO: check if current game rules allow abilities

	// TODO: check if the player can have this ability

	// set the ability and recharge rate on the player so we can use it later	
	// name comes in as ability_ so we need to reformat it for now
	nameTokens = StrTok( abilityName, "_" );
	self.pers[ "ability" ] = "specialty";
	foreach( tok in nameTokens )
	{
		if( IsSubStr( tok, "ability" ) )
			continue;
		self.pers[ "ability" ] = self.pers[ "ability" ] + "_" + tok;
	}
	self.pers[ "abilityName" ] = abilityName;
	
	self.pers[ "abilityImage" ] =			TableLookup( ABILITY_TABLE_NAME, ABILITY_NAME_COL, abilityName, ABILITY_IMAGE_COL );
	self.pers[ "abilityTimeOut" ] =			int( TableLookup( ABILITY_TABLE_NAME, ABILITY_NAME_COL, abilityName, ABILITY_TIME_OUT_COL ) );
	self.pers[ "abilityRechargeTime" ] =	int( TableLookup( ABILITY_TABLE_NAME, ABILITY_NAME_COL, abilityName, ABILITY_RECHARGE_COL ) );
	self.pers[ "abilityScriptMade" ] =		int( TableLookup( ABILITY_TABLE_NAME, ABILITY_NAME_COL, abilityName, ABILITY_SCRIPT_MADE_COL ) );
	self.pers[ "abilityUseSound" ] =		TableLookup( ABILITY_TABLE_NAME, ABILITY_NAME_COL, abilityName, ABILITY_USE_SOUND_COL );
	self.pers[ "abilityUseDialog" ] =		TableLookup( ABILITY_TABLE_NAME, ABILITY_NAME_COL, abilityName, ABILITY_USE_DIALOG_COL );
	self.pers[ "abilityReadySound" ] =		TableLookup( ABILITY_TABLE_NAME, ABILITY_NAME_COL, abilityName, ABILITY_READY_SOUND_COL );
	self.pers[ "abilityTimeOutSound" ] =	TableLookup( ABILITY_TABLE_NAME, ABILITY_NAME_COL, abilityName, ABILITY_TIME_OUT_SOUND_COL );
	self SetClientDvar( "ui_activeAbility_name", abilityName );
}

setupPassiveAbility( abilityName ) // self == player
{
	// TODO: check if current game rules allow abilities

	// TODO: check if the player can have this ability

	// name comes in as ability_ so we need to reformat it for now
	nameTokens = StrTok( abilityName, "_" );
	ability = "specialty";
	foreach( tok in nameTokens )
	{
		if( IsSubStr( tok, "ability" ) )
			continue;
		ability = ability + "_" + tok;
	}

	// clear the abilities first in case they changed classes we don't want carry over
	self.abilities = [];

	self giveAbility( ability, false );

	self SetClientDvar( "ui_passiveAbility_name", abilityName );
}

watchAbilityUse() // self == player
{
	self endon( "disconnect" );
	level endon( "game_ended" );

	// TODO: store the timers on the ability and have them all run seperately from each other
	//			this fixes the changing class penalty, where if you change class then you have to wait for the recharge from the other ability
	//			each could have their own timers so they don't interfere with each other
	
	// TODO (maybe): have the timer stop when you are dead, only tick down usage and not just straight time, this could be nice for round based modes like s&d

	self SetClientDvar( "ui_ability_timer", 0 );
	self SetClientDvar( "ui_ability_end_milliseconds", 0 );
	self SetClientDvar( "ui_ability_recharging", 0 );
	self NotifyOnPlayerCommand( "ability_used", "+smoke" );

	while( true )
	{
		if( IsDefined( self.pers[ "abilityOn" ] ) && self.pers[ "abilityOn" ] )
		{
			// if the ability is already on let's go straight to the timeout
			self watchTimeOut();
		}
		else if( IsDefined( self.pers[ "abilityRecharging" ] ) && self.pers[ "abilityRecharging" ] )
		{
			// if the ability is already rechargine then go straight to recharging
		}
		else
		{
			self waittill( "ability_used" );

			// don't let the player use their ability while dead/spectating
			//	also while in prematch timer
			if( !isReallyAlive( self ) || GetDvarInt( "ui_inprematch" ) )
				continue;
			
			if ( !self canGiveAbility( self.pers[ "ability" ] ) )
			{
				// let the player remove the supressor when they want, if we're recharging though they can't put it back on
				if( self.pers[ "abilityName" ] == "ability_suppressweapon" )
				{
					weapon_name = self GetCurrentWeapon();
					if ( weaponHasSilencer( weapon_name ) )
						self setSuppressWeapon();
				}

				continue;
			}

			if( IsDefined( self.pers[ "abilityUseSound" ] ) && self.pers[ "abilityUseSound" ] != "null" )
				self PlayLocalSound( self.pers[ "abilityUseSound" ] );
			
			if( IsDefined( self.pers[ "abilityUseDialog" ] ) && self.pers[ "abilityUseDialog" ] != "null" )
				self leaderDialogOnPlayer( self.pers[ "abilityUseDialog" ] );
		
			self giveAbility( self.pers[ "ability" ], false );
			self.pers[ "abilityOn" ] = true;
			
			// start timing out
			self watchTimeOut();
		}

		// start recharging
		self watchRecharging();
	}
}

watchTimeOut() // self == player
{
	self endon( "disconnect" );
	level endon( "game_ended" );

	if( IsDefined( self.pers[ "abilityTimeOut" ] ) )
		timeOut = self.pers[ "abilityTimeOut" ];
	else
		timeOut = int( TableLookup( ABILITY_TABLE_NAME, ABILITY_NAME_COL, self.pers[ "abilityName" ], ABILITY_TIME_OUT_COL ) );

/#
	if( GetDvarInt( "scr_ability_timeout" ) > 0 )
		timeOut = GetDvarInt( "scr_ability_timeout" );
#/	
	// If the timeout is zero do not wait. Instead
	// set up the ability icon to pulse for one second,
	// then early out to allow the recharge to begin
	if ( timeOut == 0 )
	{
		self createAbilityIcon();
		self thread pulseAbilityIconOnce();
		
		// Register this ability off because with a timeout of
		// 0 it does not persist.
		self.pers[ "abilityOn" ] = undefined;
		
		return;
	}
	
	// since we have round changes we'll need to double check the player's temp persistent data to see if there is still timeout time or recharge time
	if( IsDefined( self.pers[ "abilityCurrentTimeOut" ] ) && self.pers[ "abilityCurrentTimeOut" ] > 0 )
		timeOut = self.pers[ "abilityCurrentTimeOut" ];

	self SetClientDvar( "ui_ability_timer", 1 );
	self thread update_ui_timers( timeOut );
	self thread storeCountdownTime( timeOut, "abilityCurrentTimeOut" );

	self createAbilityIcon();
	self thread pulseAbilityIcon();
	
	// TODO: play a sound when 5 seonds left

	while( true )
	{
		result = self waittill_any_timeout_pause_on_death_and_prematch( timeOut, "changed_class", "abilityExtraTime" );
		AssertEx( IsDefined( result ), "Ability in use and waittill result is undefined and shouldn't be!" );

		if( result == "abilityExtraTime" )
		{
			timeOut = self.pers[ "abilityCurrentTimeOut" ] + level.extraTimeMod;

			// stop and re-run the ability timers to reflect the new time
			self notify( "stopAbilityTimers" );
			self thread update_ui_timers( timeOut );
			self thread storeCountdownTime( timeOut, "abilityCurrentTimeOut" );

			self thread showTimeText( &"ABILITIES_PLUS_5_SECONDS" );

			if( timeOut <= 0 )
				break;

			continue;
		}
		else
			break;
	}

	self notify( "abilityOff" );

	// reset the temp persistent data
	self notify( "stopAbilityTimers" );
	self.pers[ "abilityOn" ] = undefined;
	self.pers[ "abilityCurrentTimeOut" ] = undefined;

	if( IsDefined( self.pers[ "abilityTimeOutSound" ] ) && self.pers[ "abilityTimeOutSound" ] != "null" )
		self PlayLocalSound( self.pers[ "abilityTimeOutSound" ] );
	
	self _unsetAbility( self.pers[ "ability" ] );
	self SetClientDvar( "ui_ability_timer", 0 );

	self destroyAbilityIconPulse();

	return;
}

createAbilityIcon()
{
	self.abilityIcon = self createIcon( self.pers[ "abilityImage" ], 32, 32 );
	self.abilityIcon.alpha = 1;
	self.abilityIcon setPoint( "CENTER", "CENTER", 0, 80 );
	self.abilityIcon.archived = true;
	self.abilityIcon.sort = 1;
	self.abilityIcon.foreground = true;
}

pulseAbilityIconOnce()
{
	self endon( "disconnect" );
	self endon( "stop_ability_pulse_once" );
	level endon( "game_ended" );
	
	fade_time = 0.5;
	
	self thread pulseAbilityIconOnceDestroy( fade_time * 3.0 );
	
	i = 0;
	while ( 1 )
	{
		self.abilityIcon FadeOverTime( fade_time );
		self.abilityIcon.alpha = 0;
		wait( fade_time );
		
		if ( i >= 1 )
			break;
		
		self.abilityIcon FadeOverTime( fade_time );
		self.abilityIcon.alpha = 1;
		wait( fade_time );
		
		i++;
	}
}

pulseAbilityIconOnceDestroy( timeout )
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	self waittill_any_timeout_pause_on_death_and_prematch( timeout, "changed_class", "abilityExtraTime" );
	self notify( "ability_stop_pulse_once" );
	
	self destroyAbilityIconPulse();
}

destroyAbilityIconPulse()
{
	if( IsDefined( self.abilityIcon ) )
	{
		self.abilityIcon Destroy();
	}
}

showTimeText( timeString ) // self == player
{
	self endon( "disconnect" );

	fadeTime = 3.0;

	abilityTextTime = newClientHudElem( self );
	abilityTextTime.horzAlign = "right";
	abilityTextTime.vertAlign = "bottom";
	abilityTextTime.alignX = "right";
	abilityTextTime.alignY = "bottom";
	abilityTextTime.x = 17;
	abilityTextTime.y = -10;
	abilityTextTime.font = "hudbig";
	abilityTextTime.fontscale = 0.65;
	abilityTextTime.archived = false;
	abilityTextTime.color = (1.0,1.0,0.5);
	abilityTextTime.sort = 10000;
	abilityTextTime.elemType = "msgText";
	abilityTextTime maps\mp\gametypes\_hud::fontPulseInit( 3.0 );	
	abilityTextTime SetText( timeString );

	abilityTextTime thread maps\mp\gametypes\_hud::fontPulse( self );

	wait( 1.0 );

	abilityTextTime FadeOverTime( fadeTime );
	abilityTextTime.alpha = 0;

	wait( fadeTime );

	if( IsDefined( abilityTextTime ) )
		abilityTextTime Destroy();
}

pulseAbilityIcon() // self == player
{
	level endon( "game_ended" );
	self endon( "disconnect" );
	self endon( "abilityOff" );

	maxWaitTime = 1.0;
	minWaitTime = 0.25;
	warningTime = 10.0;
	while( IsDefined( self.abilityIcon ) )
	{
		waitTime = max( minWaitTime, min( maxWaitTime, maxWaitTime * ( ( self.pers[ "abilityCurrentTimeOut" ] / warningTime ) * 0.5 ) ) );
		
		self.abilityIcon FadeOverTime( waitTime );
		self.abilityIcon.alpha = 0;
		wait( waitTime );
		self.abilityIcon FadeOverTime( waitTime );
		self.abilityIcon.alpha = 0.5;
		wait( waitTime );
	}
}

watchRecharging() // self == player
{
	// no need to recharge if they changed classes while the ability was active
	self SetClientDvar( "ui_ability_recharging", 1 );

	if( IsDefined( self.pers[ "abilityRechargeTime" ] ) )
		rechargeTime = self.pers[ "abilityRechargeTime" ];
	else
		rechargeTime = int( TableLookup( ABILITY_TABLE_NAME, ABILITY_NAME_COL, self.pers[ "abilityName" ], ABILITY_RECHARGE_COL ) );

/#
	if( GetDvarInt( "scr_ability_recharge" ) > 0 )
		rechargeTime = GetDvarInt( "scr_ability_recharge" );
#/

	// since we have round changes we'll need to double check the player's temp persistent data to see if there is still timeout time or recharge time
	if( IsDefined( self.pers[ "abilityCurrentRechargeTime" ] ) && self.pers[ "abilityCurrentRechargeTime" ] > 0 )
		rechargeTime = self.pers[ "abilityCurrentRechargeTime" ];

	self thread update_ui_timers( rechargeTime );
	self thread storeCountdownTime( rechargeTime, "abilityCurrentRechargeTime" );
	self.pers[ "abilityRecharging" ] = true;

	while( true )
	{
		result = self waittill_any_timeout_pause_on_death_and_prematch( rechargeTime, "abilityFastRecharge", "ability_used" );
		AssertEx( IsDefined( result ), "Ability recharging and waittill result is undefined and shouldn't be!" );

		if( result == "abilityFastRecharge" )
		{
			rechargeTime = self.pers[ "abilityCurrentRechargeTime" ] - level.fastRechargeMod;
			
			// stop and re-run the ability timers to reflect the new time
			self notify( "stopAbilityTimers" );
			self thread update_ui_timers( rechargeTime );
			self thread storeCountdownTime( rechargeTime, "abilityCurrentRechargeTime" );
			
			self thread showTimeText( &"ABILITIES_MINUS_5_SECONDS" );

			if( rechargeTime <= 0 )
				break;

			continue;
		}
		else if( result == "ability_used" )
		{
			// let the player remove the supressor when they want, if we're recharging though they can't put it back on
			if( self.pers[ "abilityName" ] == "ability_suppressweapon" )
			{
				weapon_name = self GetCurrentWeapon();
				if ( weaponHasSilencer( weapon_name ) )
					self setSuppressWeapon();
			}
			rechargeTime = self.pers[ "abilityCurrentRechargeTime" ];
			continue;
		}
		else
			break;
	}

	// reset the temp persistent data
	self notify( "stopAbilityTimers" );
	self.pers[ "abilityRecharging" ] = undefined;
	self.pers[ "abilityCurrentRechargeTime" ] = undefined;

	if( IsDefined( self.pers[ "abilityReadySound" ] ) && self.pers[ "abilityReadySound" ] != "null" )
		self PlayLocalSound( self.pers[ "abilityReadySound" ] );

	self SetClientDvar( "ui_ability_recharging", 0 );

	return;
}

update_ui_timers( time ) // self == player
{
	level endon( "game_ended" );
	self endon( "disconnect" );
	self endon( "stopAbilityTimers" );

	abilityEndMilliseconds = ( time * 1000) + GetTime();
	self SetClientDvar( "ui_ability_end_milliseconds", abilityEndMilliseconds );

	// save the end time stamp for later use (since we don't have a way to grab client dvars)
	self.pers[ "abilityEndTimeStamp" ] = abilityEndMilliseconds;

	self thread update_ui_timers_on_host_migration();
	self thread update_ui_timers_on_death();
	self thread update_ui_timer_on_prematch();
}

update_ui_timers_on_host_migration() // self == player
{
	level endon( "game_ended" );
	self endon( "disconnect" );
	self endon( "abilityOff" ); // called when the ability times out or the player changed classes
	self endon( "stopAbilityTimers" );

	while( true )
	{
	level waittill( "host_migration_begin" );

	timePassed = maps\mp\gametypes\_hostmigration::waitTillHostMigrationDone();

	self.pers[ "abilityEndTimeStamp" ] += timePassed;

	if ( timePassed > 0 )
	{
			self SetClientDvar( "ui_ability_end_milliseconds", self.pers[ "abilityEndTimeStamp" ] );
		}
	}
}

update_ui_timers_on_death() // self == player
{
	level endon( "game_ended" );
	self endon( "disconnect" );
	self endon( "abilityOff" ); // called when the ability times out or the player changed classes
	self endon( "stopAbilityTimers" );

	while( true )
	{
		self waittill( "death" );
		timePassed = GetTime();
		
		self waittill( "spawned_player" );
		
		timePassed = GetTime() - timePassed;
		self.pers[ "abilityEndTimeStamp" ] += timePassed;

		if( timePassed > 0 )
		{
			self SetClientDvar( "ui_ability_end_milliseconds", self.pers[ "abilityEndTimeStamp" ] );
		}
	}
}

update_ui_timer_on_prematch()
{
	level endon( "game_ended" );
	self endon( "disconnect" );
	self endon( "abilityOff" ); // called when the ability times out or the player changed classes
	self endon( "stopAbilityTimers" );

	while( true )
	{
		if( GetDvarInt( "ui_inprematch" ) )
		{
			timePassed = GetTime();
			
			level waittill( "prematch_over" );
			
			timePassed = GetTime() - timePassed;
			self.pers[ "abilityEndTimeStamp" ] += timePassed;

			if( timePassed > 0 )
			{
				self SetClientDvar( "ui_ability_end_milliseconds", self.pers[ "abilityEndTimeStamp" ] );
			}
		}

		wait( 0.05 );
	}
}

storeCountdownTime( timeOut, persName ) // self == player
{
	level endon( "game_ended" );
	self endon( "disconnect" );
	self endon( "stopAbilityTimers" );

	// keep how much time is left in the player's persistent data
	inc = 0.05;
	while( timeOut > 0 )
	{
		if( !isReallyAlive( self ) )
		{
			self waittill( "spawned_player" );
		}
		if( GetDvarInt( "ui_inprematch" ) )
		{
			level waittill( "prematch_over" );
		}

		self.pers[ persName ] = timeOut;
		wait( inc );
		timeOut -= inc;
	}
}






/////////////////////////////////////////////////////////////////////////////////////////////////
//
// Abilty Functions
//

// highlight enemies while sniping
setAutoSpot()
{
	self autoSpotAdsWatcher();
	self autoSpotDeathWatcher();
}

autoSpotDeathWatcher()
{
	self waittill( "death" );
	self endon ( "disconnect" );
	self endon ( "endAutoSpotAdsWatcher" );
	level endon ( "game_ended" );

	self AutoSpotOverlayOff();
}

unsetAutoSpot()
{	
	self notify( "endAutoSpotAdsWatcher" );
	self AutoSpotOverlayOff();
}

autoSpotAdsWatcher()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	self endon ( "endAutoSpotAdsWatcher" );
	level endon ( "game_ended" );

	spotter = false;

	for( ;; )
	{
		wait( 0.05 );

		if( self IsUsingTurret() )
		{
			self AutoSpotOverlayOff();
			continue;
		}

		adsLevel = self PlayerADS();

		if( adsLevel < 1 && spotter )
		{
			spotter = false;
			self AutoSpotOverlayOff();
		}	

		if( adsLevel < 1 && !spotter )
			continue;

		if( adsLevel == 1 && !spotter )
		{
			spotter = true;
			self AutoSpotOverlayOn();		
		}
	}
}

// need to update the bomb squad
setDetectExplosive()
{
	level notify( "update_bombsquad" );
}

unsetDetectExplosive()
{
	level notify( "update_bombsquad" );
}

// change move speed scalar
setLightWeight()
{
	self.moveSpeedScaler = 1.25;	
	self maps\mp\gametypes\_weapons::updateMoveSpeedScale();

	// also give them marathon
	self giveAbility( "specialty_marathon", false );
}

unsetLightWeight()
{
	self.moveSpeedScaler = 1;
	self maps\mp\gametypes\_weapons::updateMoveSpeedScale();

	// take away marathon
	self _unsetAbility( "specialty_marathon" );
}

// attach portable radar to a player
setPersonalRadar() // self == player
{
	// don't set it twice
	if( IsDefined( self.personalRadar ) )
		return;

	portable_radar = Spawn( "script_model", self.origin );
	portable_radar.team = self.team;

	portable_radar MakePortableRadar( self );
	self.personalRadar = portable_radar;

	self thread radarMover( portable_radar );
	self thread radarMoverWatchDeath();
}

radarMover( portableRadar ) // self == player
{
	level endon("game_ended");
	self endon( "disconnect" );
	self endon( "radar_removed" );
	self endon( "death" );

	while( true )
	{
		if( IsDefined( portableRadar ) )
			portableRadar MoveTo( self.origin, .05 );
		wait (0.05);
	}
}

radarMoverWatchDeath() // self == player
{
	level endon("game_ended");
	self endon( "radar_removed" );

	if( isReallyAlive( self ) )
		self waittill( "death" );

	if( IsDefined( self.personalRadar ) )
		self.personalRadar delete();

	self notify( "radar_removed" );
}

unsetPersonalRadar() // self == player
{
	self notify( "radar_removed" );

	if( IsDefined( self.personalRadar ) )
		self.personalRadar delete();
}

// refill ammo and make infinite
setInfiniteAmmo() // self == player
{
	level endon( "game_ended" );
	self endon( "infinite_ammo_done" );

	self.savedWeaponClipAmmo = [];
	self.savedWeaponStockAmmo = [];
	self.savedWeaponsToRestore = [];

	// we need to keep track of the ammo for when we restore them
	foreach( weapon in self.weaponlist )
	{
		weaponTokens = StrTok( weapon, "_" );
		if( weaponTokens[0] == "alt" )
		{
			// we don't need to take the alt weapons but we do need to store the ammo for when we restore them
			self.savedWeaponClipAmmo[ weapon ] = self GetWeaponAmmoClip( weapon );
			self.savedWeaponStockAmmo[ weapon ] = self GetWeaponAmmoStock( weapon );
			continue;
		}

		self.savedWeaponClipAmmo[ weapon ] = self GetWeaponAmmoClip( weapon );
		self.savedWeaponStockAmmo[ weapon ] = self GetWeaponAmmoStock( weapon );

		// keep a list of the weapons we take because self.weaponlist isn't reliable
		self.savedWeaponsToRestore[ self.savedWeaponsToRestore.size ] = weapon;
	}

	//// primary and secondary grenades
	//class = self.pers["class"];
	//primaryGrenade = level.classGrenades[class]["primary"]["type"];
	//secondaryGrenade = level.classGrenades[class]["secondary"]["type"];
	//self.savedWeaponClipAmmo[ primaryGrenade ] = self GetAmmoCount( primaryGrenade );
	//self.savedWeaponClipAmmo[ secondaryGrenade ] = self GetAmmoCount( secondaryGrenade );

	while( true )
	{
		foreach( weapon in self.weaponlist )
		{
			self GiveMaxAmmo( weapon );
			self SetWeaponAmmoClip( weapon, 999 );
			
			//if ( self getAmmoCount( level.classGrenades[class]["primary"]["type"] ) < level.classGrenades[class]["primary"]["count"] )
			//	self SetWeaponAmmoClip( level.classGrenades[class]["primary"]["type"], level.classGrenades[class]["primary"]["count"] );

			//if ( self getAmmoCount( level.classGrenades[class]["secondary"]["type"] ) < level.classGrenades[class]["secondary"]["count"] )
			//	self SetWeaponAmmoClip( level.classGrenades[class]["secondary"]["type"], level.classGrenades[class]["secondary"]["count"] );	
		}

		wait( 0.05 );
	}
}

unsetInfiniteAmmo() // self == player
{
	self notify( "infinite_ammo_done" );

	// restore old ammo values
	if( !IsDefined( self.savedWeaponClipAmmo ) ||
		!IsDefined( self.savedWeaponStockAmmo ) ||
		!IsDefined( self.savedWeaponsToRestore ) )
		return;

	altWeapons = [];
	foreach( weapon in self.savedWeaponsToRestore )
	{
		weaponTokens = StrTok( weapon, "_" );
		if( weaponTokens[0] == "alt" )
		{
			// we don't need to give the alt weapons but we do need to restore the ammo
			altWeapons[ altWeapons.size ] = weapon;
			continue;
		}

		self _giveWeapon( weapon );
		if( IsDefined( self.savedWeaponClipAmmo[ weapon ] ) )
			self SetWeaponAmmoClip( weapon, self.savedWeaponClipAmmo[ weapon ] );
		if( IsDefined( self.savedWeaponStockAmmo[ weapon ] ) )
			self SetWeaponAmmoStock( weapon, self.savedWeaponStockAmmo[ weapon ] );
	}

	foreach( altWeapon in altWeapons )
	{
		if( IsDefined( self.savedWeaponClipAmmo[ altWeapon ] ) )
			self SetWeaponAmmoClip( altWeapon, self.savedWeaponClipAmmo[ altWeapon ] );
		if( IsDefined( self.savedWeaponStockAmmo[ altWeapon ] ) )
			self SetWeaponAmmoStock( altWeapon, self.savedWeaponStockAmmo[ altWeapon ] );
	}

	//// primary and secondary grenades
	//class = self.pers["class"];
	//self SetWeaponAmmoClip( level.classGrenades[class]["primary"]["type"], level.classGrenades[class]["primary"]["count"] );
	//self SetWeaponAmmoClip( level.classGrenades[class]["secondary"]["type"], level.classGrenades[class]["secondary"]["count"] );

	self.savedWeaponClipAmmo = undefined;
	self.savedWeaponStockAmmo = undefined;
}

// make invisible
setQuieter()
{
	// also give them blindeye
	self giveAbility( "specialty_blindeye", false );
}

unsetQuieter()
{
	// take away blindeye
	self _unsetAbility( "specialty_blindeye" );
}

canSetSuppressWeapon()
{
	if ( !self isWeaponEnabled() || self isChangingWeapon() )
		return false;
	
	weapon_name = self GetCurrentWeapon();
	if ( weapon_name == "none" )
		return false;
	
	// Only certain weapon types can have silencers
	silencer_name = getSuppressorAttachmentName( weapon_name );
	if ( !IsDefined( silencer_name ) )
		return false;
	
	// If weapon already has silencer early out
	attachments = GetWeaponAttachments( weapon_name );
	foreach( name in attachments )
	{
		if ( IsSubStr( name, "silencer" ) )
			return false;
	}
	
	weapon_and_silencer = getBaseWeaponName( weapon_name ) + " " + silencer_name;
	
	return ( weapon_and_silencer == TableLookup( getSuppressorUnlockTable( weapon_name ), UNLOCK_WEAPON_COL, weapon_and_silencer, UNLOCK_WEAPON_COL ) );
}

setSuppressWeapon()
{
	weapon_name = self GetCurrentWeapon();
	attachments = GetWeaponAttachments( weapon_name );
	
	// If the weapon doesn't already have a silencer
	// add the appropriate silencer string to the 
	// weapon string
	remove_silencer = true;
	if ( !weaponHasSilencer( weapon_name ) )
	{
		attachments[ attachments.size ] = getSuppressorAttachmentName( weapon_name );
		attachments = alphabetize( attachments );
		remove_silencer = false;
	}
	
	weapon_name_new = GetWeaponBaseName( weapon_name );
	foreach ( attachment in attachments )
	{
		if ( remove_silencer && IsSubStr( attachment, "silencer" ) )
			continue;
		
		weapon_name_new += "_" + attachment;
	}
	
	ammo_clip = self GetWeaponAmmoClip( weapon_name );
	ammo_stock = self GetWeaponAmmoStock( weapon_name );
	
	self TakeWeapon( weapon_name );
	self GiveWeapon( weapon_name_new );
	self SetWeaponAmmoClip( weapon_name_new, ammo_clip );
	self SetWeaponAmmoStock( weapon_name_new, ammo_stock );
	self SwitchToWeaponImmediate( weapon_name_new );
}

unsetSuppressWeapon()
{
	// currently leave suppressor on
}

weaponHasSilencer( weapon_name )
{
	attachments = GetWeaponAttachments( weapon_name );
	foreach( name in attachments )
	{
		if ( IsSubStr( name, "silencer" ) )
			return true;
	}
	
	return false;
}

getSuppressorAttachmentName( weapon_name )
{
	weapon_class = WeaponClass( weapon_name );
	
	name = undefined;
	
	switch ( weapon_class )
	{
		case "pistol":
			name = "silencer02";
			break;
		
		case "rifle":
		case "mg":
			name = "silencer";
			break;
		
		case "smg":
			name = "silencer";
			if ( IsSubStr( weapon_name, "_fmg9_" ) || IsSubStr( weapon_name, "_g18_" ) || IsSubStr( weapon_name, "_skorpion_" ) || IsSubStr( weapon_name, "_mp9_" ) )
			{
				name = "silencer02";
			}
			break;
			
		case "sniper":
		case "spread":
			name = "silencer03";
			break;
		
		default:
			break;
	}
	
	return name;
}

getSuppressorUnlockTable( weapon_name )
{
	weapon_class = WeaponClass( weapon_name );
	
	table = undefined;
	
	switch ( weapon_class )
	{
		// ToDo: Break pistols out into their own unlock table, for now use assault.
		case "pistol":
			table = UNLOCK_TABLE_ASSAULT_NAME;
			break;
		
		case "rifle":
			table = UNLOCK_TABLE_ASSAULT_NAME;
			break;
		
		case "mg":
			table = UNLOCK_TABLE_LMG_NAME;
			break;
		
		case "smg":
			table = UNLOCK_TABLE_SMG_NAME;
			break;
		
		case "sniper":
			table = UNLOCK_TABLE_SNIPER_NAME;
			break;
		
		case "spread":
			table = UNLOCK_TABLE_SHOTGUN_NAME;
			break;
		
		default:
			AssertMsg( "Could not choose unlock table for weapon: " + weapon_name );
			table = UNLOCK_TABLE_ASSAULT_NAME;
			break;
	}
	
	return table;
}

// absorb the ability and get it right now from your victim
absorbAbility( victim ) // self == player
{
	self endon( "disconnect" );
	level endon( "game_ended" );

	// if the victim's ability is on, give it to the attacker
	abilityName = "";
	icon = "";
	useSound = "";
	useDialog = "";
	if( IsDefined( victim.pers[ "abilityOn" ] ) && victim.pers[ "abilityOn" ] )
	{
		abilityName = victim.pers[ "ability" ];
		icon = victim.pers[ "abilityImage" ];
		useSound = victim.pers[ "abilityUseSound" ];
		useDialog = victim.pers[ "abilityUseDialog" ];
	}
	else
		return;

	// show the ability icon that they just got
	fadeTime = 3.0;

	self.abilityIconAbsorbed = self createIcon( icon, 32, 32 );
	self.abilityIconAbsorbed.alpha = 1;
	self.abilityIconAbsorbed setPoint( "CENTER", "CENTER", 0, 80 );
	self.abilityIconAbsorbed.archived = true;
	self.abilityIconAbsorbed.sort = 1;
	self.abilityIconAbsorbed.foreground = true;
	self.abilityIconAbsorbed FadeOverTime( fadeTime );
	self.abilityIconAbsorbed.alpha = 0;

	// text of what they just got
	self.abilityTextAbsorbed = newClientHudElem( self );
	self.abilityTextAbsorbed.horzAlign = "center";
	self.abilityTextAbsorbed.vertAlign = "middle";
	self.abilityTextAbsorbed.alignX = "center";
	self.abilityTextAbsorbed.alignY = "middle";
	self.abilityTextAbsorbed.x = 0;
	self.abilityTextAbsorbed.y = 100;
	self.abilityTextAbsorbed.font = "hudbig";
	self.abilityTextAbsorbed.fontscale = 0.65;
	self.abilityTextAbsorbed.archived = false;
	self.abilityTextAbsorbed.color = (1.0,1.0,0.5);
	self.abilityTextAbsorbed.sort = 10000;
	self.abilityTextAbsorbed.elemType = "msgText";
	//self.abilityTextAbsorbed maps\mp\gametypes\_hud::fontPulseInit( 3.0 );	
	self.abilityTextAbsorbed SetText( &"ABILITIES_ABSORBED" );
	//self.abilityTextAbsorbed thread maps\mp\gametypes\_hud::fontPulse( self );
	self.abilityTextAbsorbed FadeOverTime( fadeTime );
	self.abilityTextAbsorbed.alpha = 0;


	if( IsDefined( useSound ) && useSound != "null" )
		self PlayLocalSound( useSound );
	if( IsDefined( useDialog ) && useDialog != "null" )
		self leaderDialogOnPlayer( useDialog );

	self giveAbility( abilityName, false );

	// take it away on death
	self waittill( "death" );

	self _unsetAbility( abilityName );

	if( IsDefined( self.abilityIconAbsorbed ) )
	{
		self.abilityIconAbsorbed Destroy();
	}
	if( IsDefined( self.abilityTextAbsorbed ) )
	{
		self.abilityTextAbsorbed Destroy();
	}
}

//
// End Abilty Functions
//
/////////////////////////////////////////////////////////////////////////////////////////////////
