/******************************************************************* 
//						_perkfunctions.gsc  
//	
//	Holds all the perk set/unset and listening functions 
//	
//	Jordan Hirsh	Sept. 11th 	2008
********************************************************************/

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\perks\_perks;


setOverkillPro()
{
}

unsetOverkillPro()
{	
}

setEMPImmune()
{
}

unsetEMPImmune()
{	
}

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

//faster health regen
setRegenFaster()
{
	// the commented out section is if we want it to only be on for a certain amount of time
//	self endon( "disconnect" );
//	level endon( "game_ended" );
//
//	regenFasterTime = 60;
//	self.hasRegenFaster = true;
//
//	endTime = ( regenFasterTime * 1000 ) + GetTime();
//	self SetClientDvar( "ui_regen_faster_end_milliseconds", endTime );
//
//	wait( regenFasterTime );
//
//	self timeOutRegenFaster();
}

unsetRegenFaster()
{	
}

timeOutRegenFaster()
{
	self.hasRegenFaster = undefined;
	self _unsetPerk( "specialty_regenfaster" );
	self SetClientDvar( "ui_regen_faster_end_milliseconds", 0 );
	self notify( "timeOutRegenFaster" );
}

//shellshock Reduction
setHardShell()
{
	self.shellShockReduction = .25;
}

unsetHardShell()
{	
	self.shellShockReduction = 0;
}

//viewkick Reduction
setSharpFocus()
{
	self setViewKickScale( .15 );
}

unsetSharpFocus()
{	
	self setViewKickScale( 1 );
}

setDoubleLoad()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	self endon ( "endDoubleLoad" );
	level endon ( "game_ended" );
	
	for( ;; )
	{
		self waittill( "reload" );
		
		weapons = self GetWeaponsList( "primary" );
		
		foreach( weapon in weapons )
		{
			
			ammoInClip = self GetWeaponAmmoClip( weapon );
			clipSize = weaponClipSize( weapon );
			difference =  clipSize - ammoInClip;
			ammoReserves = self getWeaponAmmoStock( weapon );
			
			if ( ammoInClip != clipSize && ammoReserves > 0 )
			{
				
				if ( ammoInClip + ammoReserves >= clipSize )
				{
					self setWeaponAmmoClip( weapon, clipSize );
					self setWeaponAmmoStock( weapon, (ammoReserves - difference ) );
				}
				else
				{
					self setWeaponAmmoClip( weapon, ammoInClip + ammoReserves );
					
					if ( ammoReserves - difference > 0 )
						self setWeaponAmmoStock( weapon, ( ammoReserves - difference ) );	
					else
						self setWeaponAmmoStock( weapon, 0 );
				}
			}
		}
	}

}

unsetDoubleLoad()
{	
	self notify( "endDoubleLoad" );
}


setMarksman( power )
{
	if ( !IsDefined( power ) )
		power = 10;
	else
		power = Int( power ) * 2;
	
	self setRecoilScale( power );
	self.recoilScale = power;
}

unsetMarksman()
{	
	self setRecoilScale( 0 );
	self.recoilScale = 0;
}


setStunResistance( power )
{	
	if ( !isDefined( power ) )
		power = 10;
	
	power = Int( power );
		
	if ( power == 10 )
		self.stunScaler = 0;
	else	
		self.stunScaler = power/10;
}

unsetStunResistance()
{	
	self.stunScaler = 1;
}

applyStunResistence( time )
{
	if ( IsDefined( self.stunScaler ) )
	{
		return self.stunScaler * time;
	}
	else
	{
		return time;
	}
}

setSteadyAimPro()
{
	self setaimspreadmovementscale( 0.5 );
}

unsetSteadyAimPro()
{
	self notify( "end_SteadyAimPro" );
	self setaimspreadmovementscale( 1.0 ); 
}

blastshieldUseTracker( perkName, useFunc )
{
	self endon ( "death" );
	self endon ( "disconnect" );
	self endon ( "end_perkUseTracker" );
	level endon ( "game_ended" );

	for ( ;; )
	{
		self waittill ( "empty_offhand" );

		if ( !isOffhandWeaponEnabled() )
			continue;
			
		self [[useFunc]]( self _hasPerk( "_specialty_blastshield" ) );
	}
}

perkUseDeathTracker()
{
	self endon ( "disconnect" );
	
	self waittill("death");
	self._usePerkEnabled = undefined;
}

setRearView()
{
	//self thread perkUseTracker( "specialty_rearview", ::toggleRearView );
}

unsetRearView()
{
	self notify ( "end_perkUseTracker" );
}

/* NO LONGER FUNCTIONS
toggleRearView( isEnabled )
{
	if ( isEnabled )
	{
		self givePerk( "_specialty_rearview" );
		self SetRearViewRenderEnabled(true);
	}
	else
	{
		self _unsetPerk( "_specialty_rearview" );
		self SetRearViewRenderEnabled(false);
	}
}
*/

setEndGame()
{
	if ( IsDefined( self.endGame ) )
		return;
		
	self.maxhealth = ( maps\mp\gametypes\_tweakables::getTweakableValue( "player", "maxhealth" ) * 4 );
	self.health = self.maxhealth;
	self.endGame = true;
	self.attackerTable[0] = "";
	self visionSetNakedForPlayer("end_game", 5 );
	self thread endGameDeath( 7 );
	maps\mp\gametypes\_gamelogic::setHasDoneCombat( self, true );
}


unsetEndGame()
{
	self notify( "stopEndGame" );
	self.endGame = undefined;
	revertVisionSet();
	
	if (! IsDefined( self.endGameTimer ) )
		return;
	
	self.endGameTimer destroyElem();
	self.endGameIcon destroyElem();		
}


revertVisionSet()
{
	if ( IsDefined( level.nukeDetonated ) )
		self VisionSetNakedForPlayer( level.nukeVisionSet, 1 );
	else
		self VisionSetNakedForPlayer( "", 1 ); // go to default visionset
}

endGameDeath( duration )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "joined_team" );
	level endon( "game_ended" );
	self endon( "stopEndGame" );
		
	//self visionSetNakedForPlayer("end_game2", 1 );
	
	wait( duration + 1 );
	self _suicide();			
}


setChallenger()
{
	if ( !level.hardcoreMode )
	{
		self.maxhealth = maps\mp\gametypes\_tweakables::getTweakableValue( "player", "maxhealth" );
		
		if ( IsDefined( self.xpScaler ) && self.xpScaler == 1 && self.maxhealth > 30 )
		{		
			self.xpScaler = 2;
		}	
	}
}

unsetChallenger()
{
	self.xpScaler = 1;
}


setSaboteur()
{
	self.objectiveScaler = 1.2;
}

unsetSaboteur()
{
	self.objectiveScaler = 1;
}


setCombatSpeed()
{
	self endon( "death" );
	self endon( "disconnect" );	
	self endon( "unsetCombatSpeed" );

	self.inCombatSpeed = false;
	self unsetCombatSpeedScalar();
		
	for(;;)
	{	
		self waittill( "damage", dmg, attacker );
		
		if( !IsDefined(attacker.team) )
			continue;
		
		if ( level.teamBased && attacker.team == self.team )
			continue;
		
		if ( self.inCombatSpeed )
			continue;
		
		self setCombatSpeedScalar();
		self.inCombatSpeed = true;
		self thread endOfSpeedWatcher();
	}
}

endOfSpeedWatcher()
{
	self notify( "endOfSpeedWatcher" );
	self endon( "endOfSpeedWatcher" );
	self endon ( "death" );
	self endon ( "disconnect" );
	
	self waittill( "healed" );
	
	self unsetCombatSpeedScalar();
	self.inCombatSpeed = false;
}

setCombatSpeedScalar()
{
	if ( IsDefined( self.isJuggernaut ) && self.isJuggernaut )
		return;
	
	if ( self.weaponSpeed <= .8 )
		self.combatSpeedScalar = 1.4;
	else if ( self.weaponSpeed <= .9 )
		self.combatSpeedScalar = 1.3;
	else
		self.combatSpeedScalar = 1.2;
	
	self maps\mp\gametypes\_weapons::updateMoveSpeedScale();
}

unsetCombatSpeedScalar()
{
	self.combatSpeedScalar = 1;
	self maps\mp\gametypes\_weapons::updateMoveSpeedScale();
}

unsetCombatSpeed()
{
	unsetCombatSpeedScalar();
	self notify( "unsetCombatSpeed" );
}

setLightWeight( power )
{
	if( !IsDefined ( power ) )
		power = 10;
	
	self.moveSpeedScaler = lightWeightScalar( power );	
	self maps\mp\gametypes\_weapons::updateMoveSpeedScale();
}

unsetLightWeight()
{
	self.moveSpeedScaler = 1;
	self maps\mp\gametypes\_weapons::updateMoveSpeedScale();
}


setBlackBox()
{
	self.killStreakScaler = 1.5;
}

unsetBlackBox()
{
	self.killStreakScaler = 1;
}

setSteelNerves()
{
	self givePerk( "specialty_bulletaccuracy", true );
	self givePerk( "specialty_holdbreath", false );
}

unsetSteelNerves()
{
	self _unsetperk( "specialty_bulletaccuracy" );
	self _unsetperk( "specialty_holdbreath" );
}

setDelayMine()
{
}

unsetDelayMine()
{
}


setBackShield()
{
	self AttachShieldModel( "weapon_riot_shield_mp", "tag_shield_back" );	
}


unsetBackShield()
{
	self DetachShieldModel( "weapon_riot_shield_mp", "tag_shield_back" );
}


setLocalJammer()
{
	if ( !self isEMPed() )
		self RadarJamOn();
}


unsetLocalJammer()
{
	self RadarJamOff();
}


setAC130()
{
	self thread killstreakThink( "ac130", 7, "end_ac130Think" );
}

unsetAC130()
{
	self notify ( "end_ac130Think" );
}


setSentryMinigun()
{
	self thread killstreakThink( "airdrop_sentry_minigun", 2, "end_sentry_minigunThink" );
}

unsetSentryMinigun()
{
	self notify ( "end_sentry_minigunThink" );
}

setTank()
{
	self thread killstreakThink( "tank", 6, "end_tankThink" );
}

unsetTank()
{
	self notify ( "end_tankThink" );
}

setPrecision_airstrike()
{
	println( "!precision airstrike!" );
	self thread killstreakThink( "precision_airstrike", 6, "end_precision_airstrike" );
}

unsetPrecision_airstrike()
{
	self notify ( "end_precision_airstrike" );
}

setPredatorMissile()
{
	self thread killstreakThink( "predator_missile", 4, "end_predator_missileThink" );
}

unsetPredatorMissile()
{
	self notify ( "end_predator_missileThink" );
}


setHelicopterMinigun()
{
	self thread killstreakThink( "helicopter_minigun", 5, "end_helicopter_minigunThink" );
}

unsetHelicopterMinigun()
{
	self notify ( "end_helicopter_minigunThink" );
}



killstreakThink( streakName, streakVal, endonString )
{
	self endon ( "death" );
	self endon ( "disconnect" );
	self endon ( endonString );
	
	for ( ;; )
	{
		self waittill ( "killed_enemy" );
		
		if ( self.pers["cur_kill_streak"] != streakVal )
			continue;

		self thread maps\mp\killstreaks\_killstreaks::giveKillstreak( streakName );
		self thread maps\mp\gametypes\_hud_message::killstreakSplashNotify( streakName, streakVal );
		return;
	}
}


setThermal()
{
	self ThermalVisionOn();
}


unsetThermal()
{
	self ThermalVisionOff();
}


setOneManArmy()
{
	self thread oneManArmyWeaponChangeTracker();
}


unsetOneManArmy()
{
	self notify ( "stop_oneManArmyTracker" );
}


oneManArmyWeaponChangeTracker()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	self endon ( "stop_oneManArmyTracker" );
	
	for ( ;; )
	{
		self waittill( "weapon_change", newWeapon );

		if ( newWeapon != "onemanarmy_mp" )	
			continue;
	
		//if ( self isUsingRemote() )
		//	continue;
		
		self thread selectOneManArmyClass();	
	}
}


isOneManArmyMenu( menu )
{
	if ( menu == game["menu_onemanarmy"] )
		return true;

	if ( IsDefined( game["menu_onemanarmy_defaults_splitscreen"] ) && menu == game["menu_onemanarmy_defaults_splitscreen"] )
		return true;

	if ( IsDefined( game["menu_onemanarmy_custom_splitscreen"] ) && menu == game["menu_onemanarmy_custom_splitscreen"] )
		return true;

	return false;
}


selectOneManArmyClass()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	
	self _disableWeaponSwitch();
	self _disableOffhandWeapons();
	self _disableUsability();
	
	self openPopupMenu( game["menu_onemanarmy"] );
	
	self thread closeOMAMenuOnDeath();
	
	self waittill ( "menuresponse", menu, className );

	self _enableWeaponSwitch();
	self _enableOffhandWeapons();
	self _enableUsability();
	
	if ( className == "back" || !isOneManArmyMenu( menu ) || self isUsingRemote() )
	{
		if ( self getCurrentWeapon() == "onemanarmy_mp" )
		{
			self _disableWeaponSwitch();
			self _disableOffhandWeapons();
			self _disableUsability();
			self switchToWeapon( self getLastWeapon() );
			self waittill ( "weapon_change" );
			self _enableWeaponSwitch();
			self _enableOffhandWeapons();
			self _enableUsability();
		}
		return;
	}	
	
	self thread giveOneManArmyClass( className );	
}

closeOMAMenuOnDeath()
{
	self endon ( "menuresponse" );
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	
	self waittill ( "death" );

	self _enableWeaponSwitch();
	self _enableOffhandWeapons();
	self _enableUsability();
}

giveOneManArmyClass( className )
{
	self endon ( "death" );
	self endon ( "disconnect" );
	level endon ( "game_ended" );

	if ( self _hasPerk( "specialty_omaquickchange" ) )
	{
		changeDuration = 3.0;
		self playLocalSound( "foly_onemanarmy_bag3_plr" );
		self playSoundToTeam( "foly_onemanarmy_bag3_npc", "allies", self );
		self playSoundToTeam( "foly_onemanarmy_bag3_npc", "axis", self );
	}
	else
	{
		changeDuration = 6.0;
		self playLocalSound( "foly_onemanarmy_bag6_plr" );
		self playSoundToTeam( "foly_onemanarmy_bag6_npc", "allies", self );
		self playSoundToTeam( "foly_onemanarmy_bag6_npc", "axis", self );
	}
		
	self thread omaUseBar( changeDuration );
		
	self _disableWeapon();
	self _disableOffhandWeapons();
	self _disableUsability();
	
	wait ( changeDuration );

	self _enableWeapon();
	self _enableOffhandWeapons();
	self _enableUsability();
	
	self.OMAClassChanged = true;

	self maps\mp\gametypes\_class::giveLoadout( self.pers["team"], className, false );
	
	// handle the fact that detachAll in giveLoadout removed the CTF flag from our back
	// it would probably be better to handle this in _detachAll itself, but this is a safety fix
	if ( IsDefined( self.carryFlag ) )
		self attach( self.carryFlag, "J_spine4", true );
	
	self notify ( "changed_kit" );
	level notify ( "changed_kit" );
}


omaUseBar( duration )
{
	self endon( "disconnect" );
	
	useBar = createPrimaryProgressBar( 0, -25 );
	useBarText = createPrimaryProgressBarText( 0, -25 );
	useBarText setText( &"MPUI_CHANGING_KIT" );

	useBar updateBar( 0, 1 / duration );
	for ( waitedTime = 0; waitedTime < duration && isAlive( self ) && !level.gameEnded; waitedTime += 0.05 )
		wait ( 0.05 );
	
	useBar destroyElem();
	useBarText destroyElem();
}


setBlastShield()
{
	//self thread blastshieldUseTracker( "specialty_blastshield", ::toggleBlastShield );
	//self givePerk( "_specialty_blastshield" );
	self SetWeaponHudIconOverride( "primaryoffhand", "specialty_blastshield" );
}


unsetBlastShield()
{
	//self notify ( "end_perkUseTracker" );
	//self _unsetPerk( "_specialty_blastshield" );
	self SetWeaponHudIconOverride( "primaryoffhand", "none" );
}

//toggleBlastShield( isEnabled )
//{
//	if ( !isEnabled )
//	{
//		self VisionSetNakedForPlayer( "black_bw", 0.15 );
//		wait ( 0.15 );
//		self givePerk( "_specialty_blastshield" );
//		self VisionSetNakedForPlayer( "", 0 ); // go to default visionset
//		self playSoundToPlayer( "item_blast_shield_on", self );
//	}
//	else
//	{
//		self VisionSetNakedForPlayer( "black_bw", 0.15 );
//		wait ( 0.15 );	
//		self _unsetPerk( "_specialty_blastshield" );
//		self VisionSetNakedForPlayer( "", 0 ); // go to default visionset
//		self playSoundToPlayer( "item_blast_shield_off", self );
//	}
//}


setFreefall()
{
	//eventually set a listener to do a roll when falling damage is taken
}

unsetFreefall()
{
}


setTacticalInsertion()
{
	self SetOffhandSecondaryClass( "flash" );
	self _giveWeapon( "flare_mp", 0 );
	self giveStartAmmo( "flare_mp" );
	
	self thread monitorTIUse();
}

unsetTacticalInsertion()
{
	self notify( "end_monitorTIUse" );
}

clearPreviousTISpawnpoint()
{
	self waittill_any ( "disconnect", "joined_team", "joined_spectators" );
	
	if ( IsDefined ( self.setSpawnpoint ) )
		self deleteTI( self.setSpawnpoint );
}

updateTISpawnPosition()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	self endon ( "end_monitorTIUse" );
	
	while ( isReallyAlive( self ) )
	{
		if ( self isValidTISpawnPosition() )
			self.TISpawnPosition = self.origin;

		wait ( 0.05 );
	}
}

isValidTISpawnPosition()
{
	if ( CanSpawn( self.origin ) && self IsOnGround() )
		return true;
	else
		return false;
}

monitorTIUse()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	self endon ( "end_monitorTIUse" );

	self thread updateTISpawnPosition();
	self thread clearPreviousTISpawnpoint();
	
	for ( ;; )
	{
		self waittill( "grenade_fire", lightstick, weapName );
				
		if ( weapName != "flare_mp" )
			continue;
		
		//lightstick delete();
		
		if ( IsDefined( self.setSpawnPoint ) )
			self deleteTI( self.setSpawnPoint );

		if ( !IsDefined( self.TISpawnPosition ) )
			continue;

		if ( self touchingBadTrigger() )
			continue;

		TIGroundPosition = playerPhysicsTrace( self.TISpawnPosition + (0,0,16), self.TISpawnPosition - (0,0,2048) ) + (0,0,1);
		
		glowStick = spawn( "script_model", TIGroundPosition );
		glowStick.angles = self.angles;
		glowStick.team = self.team;
		glowStick.owner = self;
		glowStick.enemyTrigger =  spawn( "script_origin", TIGroundPosition );
		glowStick thread GlowStickSetupAndWaitForDeath( self );
		glowStick.playerSpawnPos = self.TISpawnPosition;
		
		glowStick thread maps\mp\gametypes\_weapons::createBombSquadModel( "weapon_light_stick_tactical_bombsquad", "tag_fire_fx", self );
		
		self.setSpawnPoint = glowStick;		
		return;
	}
}


GlowStickSetupAndWaitForDeath( owner )
{
	self setModel( level.spawnGlowModel["enemy"] );
	if ( level.teamBased )
		self maps\mp\_entityheadIcons::setTeamHeadIcon( self.team , (0,0,20) );
	else
		self maps\mp\_entityheadicons::setPlayerHeadIcon( owner, (0,0,20) );

	self thread GlowStickDamageListener( owner );
	self thread GlowStickEnemyUseListener( owner );
	self thread GlowStickUseListener( owner );
	self thread GlowStickTeamUpdater( self.team, level.spawnGlow["enemy"], owner );

	dummyGlowStick = spawn( "script_model", self.origin+ (0,0,0) );
	dummyGlowStick.angles = self.angles;
	dummyGlowStick setModel( level.spawnGlowModel["friendly"] );
	dummyGlowStick setContents( 0 );
	dummyGlowStick thread GlowStickTeamUpdater( self.team, level.spawnGlow["friendly"], owner );
	
	dummyGlowStick playLoopSound( "emt_road_flare_burn" );

	self waittill ( "death" );
	
	dummyGlowStick stopLoopSound();
	dummyGlowStick delete();
}


GlowStickTeamUpdater( ownerTeam, showEffect, owner )
{
	self endon ( "death" );
	
	// PlayFXOnTag fails if run on the same frame the parent entity was created
	wait ( 0.05 );
	
	//PlayFXOnTag( showEffect, self, "TAG_FX" );
	angles = self getTagAngles( "tag_fire_fx" );
	fxEnt = SpawnFx( showEffect, self getTagOrigin( "tag_fire_fx" ), anglesToForward( angles ), anglesToUp( angles ) );
	TriggerFx( fxEnt );
	
	self thread deleteOnDeath( fxEnt );
	
	for ( ;; )
	{
		self hide();
		fxEnt hide();
		foreach ( player in level.players )
		{
			//friendly tac insert 
			if ( player.team == ownerTeam && level.teamBased && showEffect == level.spawnGlow["friendly"] )
			{
				self showToPlayer( player );
				fxEnt showToPlayer( player );
			}
			//enemy tac insert
			else if ( player.team != ownerTeam && level.teamBased && showEffect == level.spawnGlow["enemy"] )
			{
				self showToPlayer( player );
				fxEnt showToPlayer( player );
			}
			else if ( !level.teamBased && player == owner && showEffect == level.spawnGlow["friendly"] )
			{
				self showToPlayer( player );
				fxEnt showToPlayer( player );
			}
			else if ( !level.teamBased && player != owner && showEffect == level.spawnGlow["enemy"] )
			{
				self showToPlayer( player );
				fxEnt showToPlayer( player );
			}
		}
		
		level waittill_either ( "joined_team", "player_spawned" );
	}
}

deleteOnDeath( ent )
{
	self waittill( "death" );
	if ( IsDefined( ent ) )
		ent delete();
}

GlowStickDamageListener( owner )
{
	self endon ( "death" );

	self setCanDamage( true );
	// use a health buffer to prevent dying to friendly fire
	self.health = 999999; // keep it from dying anywhere in code
	self.maxHealth = 100; // this is the health we'll check
	self.damageTaken = 0; // how much damage has it taken

	while( true )
	{
		self waittill( "damage", damage, attacker, direction_vec, point, type, modelName, tagName, partName, iDFlags, weapon );

		// don't allow people to destroy equipment on their team if FF is off
		if ( !maps\mp\gametypes\_weapons::friendlyFireCheck( self.owner, attacker ) )
			continue;

		if( IsDefined( weapon ) )
		{
			switch( weapon )
			{
			case "concussion_grenade_mp":
			case "flash_grenade_mp":
			case "smoke_grenade_mp":
				continue;
			}
		}

		if ( !IsDefined( self ) )
			return;

		if ( type == "MOD_MELEE" )
			self.damageTaken += self.maxHealth;

		if ( IsDefined( iDFlags ) && ( iDFlags & level.iDFLAGS_PENETRATION ) )
			self.wasDamagedFromBulletPenetration = true;

		self.wasDamaged = true;

		self.damageTaken += damage;

		if( isPlayer( attacker ) )
		{
			attacker maps\mp\gametypes\_damagefeedback::updateDamageFeedback( "tactical_insertion" );
		}

		if ( self.damageTaken >= self.maxHealth )
		{
			if ( IsDefined( owner ) && attacker != owner )
			{
				attacker notify ( "destroyed_insertion", owner );
				attacker notify( "destroyed_explosive" ); // count towards SitRep Pro challenge
				owner thread leaderDialogOnPlayer( "ti_destroyed", undefined, undefined, self.origin );
			}
			
			attacker thread deleteTI( self );
		}
	}
}

GlowStickUseListener( owner )
{
	self endon ( "death" );
	level endon ( "game_ended" );
	owner endon ( "disconnect" );
	
	self setCursorHint( "HINT_NOICON" );
	self setHintString( &"MP_PATCH_PICKUP_TI" );
	
	self thread updateEnemyUse( owner );

	for ( ;; )
	{
		self waittill ( "trigger", player );
		
		player playSound( "chemlight_pu" );
		
		if( !player isJuggernaut() )
			player thread setTacticalInsertion();
			
		player thread deleteTI( self );
	}
}

updateEnemyUse( owner )
{
	self endon ( "death" );
	
	for ( ;; )
	{
		self setSelfUsable( owner );
		level waittill_either ( "joined_team", "player_spawned" );
	}
}

deleteTI( TI )
{
	if (IsDefined( TI.enemyTrigger ) )
		TI.enemyTrigger Delete();
	
	spot = TI.origin;
	spotAngles = TI.angles;
	
	TI Delete();
	
	dummyGlowStick = spawn( "script_model", spot );
	dummyGlowStick.angles = spotAngles;
	dummyGlowStick setModel( level.spawnGlowModel["friendly"] );
	
	dummyGlowStick setContents( 0 );
	thread dummyGlowStickDelete( dummyGlowStick );
}

dummyGlowStickDelete( stick )
{
	wait(2.5);
	stick Delete();
}

GlowStickEnemyUseListener( owner )
{
	self endon ( "death" );
	level endon ( "game_ended" );
	owner endon ( "disconnect" );
	
	self.enemyTrigger setCursorHint( "HINT_NOICON" );
	self.enemyTrigger setHintString( &"MP_PATCH_DESTROY_TI" );
	self.enemyTrigger makeEnemyUsable( owner );
	
	for ( ;; )
	{
		self.enemyTrigger waittill ( "trigger", player );
		
		player notify ( "destroyed_insertion", owner );
		player notify( "destroyed_explosive" ); // count towards SitRep Pro challenge

		//playFX( level.spawnGlowSplat, self.origin);		
		
		if ( IsDefined( owner ) && player != owner )
			owner thread leaderDialogOnPlayer( "ti_destroyed", undefined, undefined, self.origin );

		player thread deleteTI( self );
	}	
}

setLittlebirdSupport()
{
	self thread killstreakThink( "littlebird_support", 2, "end_littlebird_support_think" );
}

unsetLittlebirdSupport()
{
	self notify ( "end_littlebird_support_think" );
}

setPainted() // self == victim
{
	// this is called from cac_modified_damage, not the perk functions
	if( IsPlayer( self ) )
	{
		paintedTime = 10.0;
		//// half the time if they have the anti-perk (whatever it may be)
		//if( self _hasPerk( "specialty_quieter" ) )
		//	paintedTime *= 0.5;

		self.painted = true;
		self setPerk( "specialty_radararrow", true, false );

		self thread unsetPainted( paintedTime );
		self thread watchPaintedDeath();
	}
}

watchPaintedDeath()
{
	self endon( "disconnect" );
	level endon( "game_ended" );

	self waittill( "death" );

	self.painted = false;
}

unsetPainted( time )
{
	self notify( "painted_again" );
	self endon( "painted_again" );

	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );

	wait( time );

	self.painted = false;
	self unsetPerk( "specialty_radararrow", true );
}

isPainted()
{
	return ( IsDefined( self.painted ) && self.painted );
}

setRefillGrenades()
{
	if( IsDefined( self.primaryGrenade ) )
	{
		self GiveMaxAmmo( self.primaryGrenade );
	}
	if( IsDefined( self.secondaryGrenade ) )
	{
		self GiveMaxAmmo( self.secondaryGrenade );
	}
}

unsetRefillGrenades()
{
}

setRefillAmmo()
{
	if( IsDefined( self.primaryWeapon ) )
	{
		self GiveMaxAmmo( self.primaryWeapon );
	}
	if( IsDefined( self.secondaryWeapon ) )
	{
		self GiveMaxAmmo( self.secondaryWeapon );
	}
}

unsetRefillAmmo()
{
}

/***************************************************************************************************************
*	DEATH STREAKS
***************************************************************************************************************/


/////////////////////////////////////////////////////////////////
// FINAL STAND: the player falls into last stand but can get back up if they survive long enough
setFinalStand()
{
	self givePerk( "specialty_pistoldeath", false );
}

unsetFinalStand()
{
	self _unsetperk( "specialty_pistoldeath" );
}
// END FINAL STAND
/////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////
// CARE PACKAGE: give the player a care package on spawn
setCarePackage()
{
	self thread maps\mp\killstreaks\_killstreaks::giveKillstreak( "airdrop_assault", false, false, self );
}

unsetCarePackage()
{

}
// END CARE PACKAGE
/////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////
// UAV: give the player a uav on spawn
setUAV()
{
	self thread maps\mp\killstreaks\_killstreaks::giveKillstreak( "uav", false, false, self );
}

unsetUAV()
{

}
// END CARE PACKAGE
/////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////
// STOPPING POWER: give the player more bullet damage
setStoppingPower()
{
	self givePerk( "specialty_bulletdamage", false );
	self thread watchStoppingPowerKill();
}

watchStoppingPowerKill()
{
	self notify( "watchStoppingPowerKill" );
	self endon( "watchStoppingPowerKill" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	self waittill( "killed_enemy" );

	self unsetStoppingPower();
}

unsetStoppingPower()
{
	self _unsetperk( "specialty_bulletdamage" );
	self notify( "watchStoppingPowerKill" );
}
// END STOPPING POWER
/////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////
// C4 DEATH: player falls into last stand with a c4 clacker for an explosive ending
setC4Death()
{
	if( !self _hasperk( "specialty_pistoldeath" ) )
		self givePerk( "specialty_pistoldeath", false );
}

unsetC4Death()
{
	if( self _hasperk( "specialty_pistoldeath" ) )
		self _unsetperk( "specialty_pistoldeath" );
}
// END C4 DEATH
/////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////
// JUICED: give a speed boost for a set amount of time
setJuiced( waitTime )
{
	self endon( "death" );
	self endon( "faux_spawn" );
	self endon( "disconnect" );
	self endon( "unset_juiced" );
	level endon( "game_ended" );
	
	self.isJuiced = true;
	self.moveSpeedScaler = 1.25;
	self maps\mp\gametypes\_weapons::updateMoveSpeedScale();

	// reloading == specialty_fastreload
	self givePerk( "specialty_fastreload", false );

	// ads'ing == specialty_quickdraw
	self givePerk( "specialty_quickdraw", false );

	// movement == specialty_stalker
	self givePerk( "specialty_stalker", false );

	// throwing grenades == specialty_fastoffhand
	self givePerk( "specialty_fastoffhand", false );

	// sprint recovery == specialty_fastsprintrecovery
	self givePerk( "specialty_fastsprintrecovery", false );

	// NOTE: deprecated with new mantling
	// mantling == specialty_fastmantle
	//self givePerk( "specialty_fastmantle", false );

	// switching weapons == specialty_quickswap
	self givePerk( "specialty_quickswap", false );

	self thread unsetJuicedOnDeath();
	self thread unsetJuicedOnRide();
	self thread unsetJuicedOnMatchEnd();

	if ( !IsDefined( waitTime ) )
	{
		waitTime = 10;
	}
	endTime = ( waitTime * 1000 ) + GetTime();
	if ( !IsAI( self ) )
	{
		self SetClientDvar( "ui_juiced_end_milliseconds", endTime );
	}
	wait( waitTime );

	self unsetJuiced();
}

unsetJuiced( death )
{	
	if( !IsDefined( death ) )
	{
		Assert( IsAlive( self ) );
		if( self isJuggernaut() )
		{
			Assert( IsDefined( self.juggMoveSpeedScaler ) );
			if( IsDefined( self.juggMoveSpeedScaler ) )
				self.moveSpeedScaler = self.juggMoveSpeedScaler;
			else							// handle the assert case for ship
				self.moveSpeedScaler = 0.7;	// compromise of the expected .65 or .75
		}
		else
		{
			self.moveSpeedScaler = 1;
			if( self _hasPerk( "specialty_lightweight" ) )
				self.moveSpeedScaler = lightWeightScalar();
		}
		Assert( IsDefined( self.moveSpeedScaler ) );
		self maps\mp\gametypes\_weapons::updateMoveSpeedScale();
	}
	
	// reloading == specialty_fastreload
	self _unsetPerk( "specialty_fastreload" );

	// ads'ing == specialty_quickdraw
	self _unsetPerk( "specialty_quickdraw" );

	// movement == specialty_stalker
	self _unsetPerk( "specialty_stalker" );

	// throwing grenades == specialty_fastoffhand
	self _unsetPerk( "specialty_fastoffhand" );

	// sprint recovery == specialty_fastsprintrecovery
	self _unsetPerk( "specialty_fastsprintrecovery" );

	// NOTE: deprecated with new mantling
	// mantling == specialty_fastmantle
	//self _unsetPerk( "specialty_fastmantle" );

	// switching weapons == specialty_quickswap
	self _unsetPerk( "specialty_quickswap" );

	// give them back their loadout perks
	//// TODO: once we do a more complicated perk system, this will need to be updated
	//if( self.loadoutPerk1 != "specialty_null" )
	//	self givePerk( self.loadoutPerk1, false );
	//if( self.loadoutPerk2 != "specialty_null" )
	//	self givePerk( self.loadoutPerk2, false );
	//if( self.loadoutPerk3 != "specialty_null" )
	//	self givePerk( self.loadoutPerk3, false );
	
	// 2013-25-04 wsh - commenting out the give*perks functions
	// since we've moved away from the point based ability sys
	/*
	self maps\mp\perks\_abilities::giveSpeedPerks( self.speedAbility );
	self maps\mp\perks\_abilities::giveHandlingPerks( self.handlingAbility );
	self maps\mp\perks\_abilities::giveStealthPerks( self.stealthAbility );
	self maps\mp\perks\_abilities::giveAwarenessPerks( self.awarenessAbility );
	self maps\mp\perks\_abilities::giveResistancePerks( self.resistanceAbility );
	self maps\mp\perks\_abilities::giveEquipmentPerks( self.equipmentAbility );
	*/
	
	// restore the new iw6 perks system
	if ( IsDefined( self.loadoutPerks ) )
	{
		self maps\mp\perks\_abilities::givePerksFromKnownLoadout( self.loadoutPerks );
	}

	self.isJuiced = undefined;
	if ( !IsAI( self ) )
	{
		self SetClientDvar( "ui_juiced_end_milliseconds", 0 );
	}

	self notify( "unset_juiced" );
}

unsetJuicedOnRide()
{
	self endon ( "disconnect" );
	self endon ( "unset_juiced" );
	
	while( true )
	{
		wait( 0.05 );
		
		if( self isUsingRemote() )
		{
			self thread unsetJuiced();
			break;
		}
	}
	
}

unsetJuicedOnDeath()
{
	self endon ( "disconnect" );
	self endon ( "unset_juiced" );
	
	self waittill_any( "death", "faux_spawn" );
	
	self thread unsetJuiced( true );
}

unsetJuicedOnMatchEnd()
{
	self endon ( "disconnect" );
	self endon ( "unset_juiced" );

	level waittill_any( "round_end_finished", "game_ended" );

	self thread unsetJuiced();
}

hasJuiced()	// self == player
{
	return ( IsDefined( self.isJuiced ) );
}
// END JUICED
/////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////
// COMBAT HIGH: painkiller, give a health boost for a set time
setCombatHigh()
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "unset_combathigh" );
	level endon( "end_game" );

	self.damageBlockedTotal = 0;
	//self visionSetNakedForPlayer( "end_game", 1 );

	if ( level.splitscreen )
	{
		yOffset = 56;
		iconSize = 21; // 32/1.5
	}
	else
	{
		yOffset = 112;
		iconSize = 32;
	}

	// since we can have more than one deathstreak, juiced might have an overlay and timer up, so delete them
	//if( IsDefined( self.juicedOverlay ) )
	//	self.juicedOverlay Destroy();
	if( IsDefined( self.juicedTimer ) )
		self.juicedTimer Destroy();
	if( IsDefined( self.juicedIcon ) )
		self.juicedIcon Destroy();

	self.combatHighOverlay = newClientHudElem( self );
	self.combatHighOverlay.x = 0;
	self.combatHighOverlay.y = 0;
	self.combatHighOverlay.alignX = "left";
	self.combatHighOverlay.alignY = "top";
	self.combatHighOverlay.horzAlign = "fullscreen";
	self.combatHighOverlay.vertAlign = "fullscreen";
	self.combatHighOverlay setshader ( "combathigh_overlay", 640, 480 );
	self.combatHighOverlay.sort = -10;
	self.combatHighOverlay.archived = true;

	self.combatHighTimer = createTimer( "hudsmall", 1.0 );
	self.combatHighTimer setPoint( "CENTER", "CENTER", 0, yOffset );
	self.combatHighTimer setTimer( 10.0 );
	self.combatHighTimer.color = (.8,.8,0);
	self.combatHighTimer.archived = false;
	self.combatHighTimer.foreground = true;

	self.combatHighIcon = self createIcon( "specialty_painkiller", iconSize, iconSize );
	self.combatHighIcon.alpha = 0;
	self.combatHighIcon setParent( self.combatHighTimer );
	self.combatHighIcon setPoint( "BOTTOM", "TOP" );
	self.combatHighIcon.archived = true;
	self.combatHighIcon.sort = 1;
	self.combatHighIcon.foreground = true;

	self.combatHighOverlay.alpha = 0.0;	
	self.combatHighOverlay fadeOverTime( 1.0 );
	self.combatHighIcon fadeOverTime( 1.0 );
	self.combatHighOverlay.alpha = 1.0;
	self.combatHighIcon.alpha = 0.85;

	self thread unsetCombatHighOnDeath();
	self thread unsetCombatHighOnRide();

	wait( 8 );

	self.combatHighIcon	fadeOverTime( 2.0 );
	self.combatHighIcon.alpha = 0.0;

	self.combatHighOverlay fadeOverTime( 2.0 );
	self.combatHighOverlay.alpha = 0.0;

	self.combatHighTimer fadeOverTime( 2.0 );
	self.combatHighTimer.alpha = 0.0;

	wait( 2 );
	self.damageBlockedTotal = undefined;

	self _unsetPerk( "specialty_combathigh" );
}

unsetCombatHighOnDeath()
{
	self endon ( "disconnect" );
	self endon ( "unset_combathigh" );

	self waittill ( "death" );

	self thread _unsetPerk( "specialty_combathigh" );
}

unsetCombatHighOnRide()
{
	self endon ( "disconnect" );
	self endon ( "unset_combathigh" );

	for ( ;; )
	{
		wait( 0.05 );

		if ( self isUsingRemote() )
		{
			self thread _unsetPerk( "specialty_combathigh" );
			break;
		}
	}
}

unsetCombatHigh()
{
	self notify ( "unset_combathigh" );
	self.combatHighOverlay destroy();
	self.combatHighIcon destroy();
	self.combatHighTimer destroy();
}
// END COMBAT HIGH
/////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////
// ARMOR: give a health boost
setLightArmor( optionalArmorValue )
{
	self notify( "give_light_armor" );

	if( IsDefined( self.lightArmorHP ) )
		unsetLightArmor();

	self thread removeLightArmorOnDeath();	
	self thread removeLightArmorOnMatchEnd();

	self.lightArmorHP = 150;
	
	if( IsDefined(optionalArmorValue) )
		self.lightArmorHP = optionalArmorValue;
	
	
	if ( IsPlayer(self) )
		self SetClientOmnvar( "ui_light_armor", true );
}

removeLightArmorOnDeath()
{
	self endon ( "disconnect" );
	self endon( "give_light_armor" );
	self endon( "remove_light_armor" );

	self waittill ( "death" );
	unsetLightArmor();		
}

unsetLightArmor()
{
	self.lightArmorHP = undefined;
	if ( IsPlayer(self) )
		self SetClientOmnvar( "ui_light_armor", false );

	self notify( "remove_light_armor" );
}

removeLightArmorOnMatchEnd()
{
	self endon ( "disconnect" );
	self endon ( "remove_light_armor" );

	level waittill_any( "round_end_finished", "game_ended" );

	self thread unsetLightArmor();
}

hasLightArmor()
{
	return ( IsDefined( self.lightArmorHP ) && self.lightArmorHP > 0 );
}

hasHeavyArmor( player )
{
	return ( IsDefined( player.heavyArmorHP ) && (player.heavyArmorHP > 0) );
}

setHeavyArmor( armorValue )
{
	if( IsDefined(armorValue) )
	{
		self.heavyArmorHP = armorValue;
	}
}

// END ARMOR
/////////////////////////////////////////////////////////////////


/////////////////////////////////////////////////////////////////
// REVENGE: show the last player who killed you, on your mini-map or in the world with a head icon
setRevenge() // this version does the head icon
{
	self notify( "stopRevenge" );
	wait( 0.05 ); // let all of the already running threads stop and clean up

	if( !IsDefined( self.lastKilledBy ) )
		return;

	if( level.teamBased && self.team == self.lastKilledBy.team )
		return;

	revengeParams = SpawnStruct();
	revengeParams.showTo = self;
	revengeParams.icon = "compassping_revenge";
	revengeParams.offset = ( 0, 0, 64 );
	revengeParams.width = 10;
	revengeParams.height = 10;
	revengeParams.archived = false;
	revengeParams.delay = 1.5;
	revengeParams.constantSize = false;
	revengeParams.pinToScreenEdge = true;
	revengeParams.fadeOutPinnedIcon = false;
	revengeParams.is3D = false;
	self.revengeParams = revengeParams;

	self.lastKilledBy maps\mp\_entityheadIcons::setHeadIcon( 
		revengeParams.showTo, 
		revengeParams.icon, 
		revengeParams.offset, 
		revengeParams.width, 
		revengeParams.height, 
		revengeParams.archived, 
		revengeParams.delay, 
		revengeParams.constantSize, 
		revengeParams.pinToScreenEdge, 
		revengeParams.fadeOutPinnedIcon,
		revengeParams.is3D );
	
	self thread watchRevengeDeath();
	self thread watchRevengeKill();
	self thread watchRevengeDisconnected();
	self thread watchRevengeVictimDisconnected();
	self thread watchStopRevenge();
}

//setRevenge() // this version does the mini-map objective
//{
//	self notify( "stopRevenge" );
//	wait( 0.05 ); // let all of the already running threads stop and clean up
//
//	if( !IsDefined( self.lastKilledBy ) )
//		return;
//
//	// show objective only to a single player, not the whole team
//	curObjID = maps\mp\gametypes\_gameobjects::getNextObjID();	
//	Objective_Add( curObjID, "invisible", (0,0,0) );
//	Objective_OnEntity( curObjID, self.lastKilledBy );
//	Objective_State( curObjID, "active" );
//	Objective_Icon( curObjID, "compassping_revenge" );
//	Objective_Player( curObjID, self GetEntityNumber() );
//	self.objIdFriendly = curObjID;
//
//	self thread watchRevengeKill();
//	self thread watchRevengeDisconnected();
//	self thread watchRevengeVictimDisconnected();
//	self thread watchStopRevenge();
//}

watchRevengeDeath() // self == player with the deathstreak
{
	self endon( "stopRevenge" );
	self endon( "disconnect" );

	lastKilledBy = self.lastKilledBy;
	// since head icons get deleted on death, we need to keep giving this player a head icon until stop revenge
	while( true )
	{
		lastKilledBy waittill( "spawned_player" );
		lastKilledBy maps\mp\_entityheadIcons::setHeadIcon( 
			self.revengeParams.showTo, 
			self.revengeParams.icon, 
			self.revengeParams.offset, 
			self.revengeParams.width, 
			self.revengeParams.height, 
			self.revengeParams.archived, 
			self.revengeParams.delay, 
			self.revengeParams.constantSize, 
			self.revengeParams.pinToScreenEdge, 
			self.revengeParams.fadeOutPinnedIcon,
			self.revengeParams.is3D );
	}
}

watchRevengeKill()
{
	self endon( "stopRevenge" );

	self waittill( "killed_enemy" );

	self notify( "stopRevenge" );
}

watchRevengeDisconnected()
{
	self endon( "stopRevenge" );

	self.lastKilledBy waittill( "disconnect" );

	self notify( "stopRevenge" );
}

watchStopRevenge() // self == player with the deathstreak
{
	lastKilledBy = self.lastKilledBy;	
	
	// if the player gets any kill, then stop the revenge on the last killed by player
	// if the player dies again without getting any kills, have the new killer show and the old not	
	self waittill( "stopRevenge" );

	if( !IsDefined( lastKilledBy ) )
		return;

	foreach( key, headIcon in lastKilledBy.entityHeadIcons )
	{	
		if( !IsDefined( headIcon ) )
			continue;

		headIcon destroy();
	}

	//if( IsDefined( self.objIdFriendly ) )
	//	_objective_delete( self.objIdFriendly );
}

watchRevengeVictimDisconnected()
{
	// if the player with revenge gets disconnected then clean up
	objID = self.objIdFriendly;
	lastKilledBy = self.lastKilledBy;
	lastKilledBy endon( "disconnect" );
	level endon( "game_ended" );
	self endon( "stopRevenge" );

	self waittill( "disconnect" );

	if( !IsDefined( lastKilledBy ) )
		return;

	foreach( key, headIcon in lastKilledBy.entityHeadIcons )
	{	
		if( !IsDefined( headIcon ) )
			continue;

		headIcon destroy();
	}

	//if( IsDefined( objID ) )
	//	_objective_delete( objID );
}

unsetRevenge()
{	
	self notify( "stopRevenge" );
}
// END REVENGE
/////////////////////////////////////////////////////////////////


/***************************************************************************************************************
*	END DEATH STREAKS
***************************************************************************************************************/
