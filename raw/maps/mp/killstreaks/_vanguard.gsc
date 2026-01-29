#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;


//============================================
// 				constants
//============================================
UAV_REMOTE_MAX_PAST_RANGE 		= 200;
UAV_REMOTE_MIN_HELI_PROXIMITY 	= 150;
UAV_REMOTE_MAX_HELI_PROXIMITY 	= 300;
UAV_REMOTE_PAST_RANGE_COUNTDOWN = 6;
UAV_REMOTE_HELI_RANGE_COUNTDOWN = 3;
UAV_REMOTE_COLLISION_RADIUS 	= 18;
UAV_REMOTE_Z_OFFSET 			= -9;

VANGUARD_AMMO_COUNT 			= 100;
VANGUARD_TRANSITION_TIME		= 1;
VANGUARD_FLY_TIME 				= 60;

//============================================
// 				init
//============================================
init()
{	
	setupFx();
	setupDialog();
	setupHeliRange();
	level.remote_uav = [];	
	level.killstreakFuncs["vanguard"] = ::tryUseVanguard;
	level.RemoteUAV_lastDialogTime = 0;
}	


//============================================
// 					setupFx
//============================================
setupFx()
{
	level.RemoteUAV_fx["hit"] 				= loadfx("fx/impacts/large_metal_painted_hit");
	level.RemoteUAV_fx["smoke"] 			= loadfx( "fx/smoke/remote_heli_damage_smoke_runner" );
	level.RemoteUAV_fx["explode"] 			= loadfx( "fx/explosions/bouncing_betty_explosion" );	
	level.RemoteUAV_fx["missile_explode"] 	= loadfx( "fx/explosions/stinger_explosion" );
	
	level.RemoteUAV_fx["target_marker_circle"]	 = loadfx("fx/misc/target_marker_circle");
}


//============================================
// 				setupDialog
//============================================
setupDialog()
{
	level.RemoteUAV_dialog["out_of_range"][0] 	= "ac130_plt_cleanup";
	level.RemoteUAV_dialog["out_of_range"][1] 	= "ac130_plt_targetreset";
	
	level.RemoteUAV_dialog["launch"][0] 		= "ac130_plt_yeahcleared";
	level.RemoteUAV_dialog["launch"][1] 		= "ac130_plt_rollinin";
	level.RemoteUAV_dialog["launch"][2] 		= "ac130_plt_scanrange";
	
	level.RemoteUAV_dialog["track"][0] 			= "ac130_fco_moreenemy";
	level.RemoteUAV_dialog["track"][1] 			= "ac130_fco_getthatguy";
	level.RemoteUAV_dialog["track"][2] 			= "ac130_fco_guymovin";
	level.RemoteUAV_dialog["track"][3] 			= "ac130_fco_getperson";
	level.RemoteUAV_dialog["track"][4] 			= "ac130_fco_guyrunnin";
	level.RemoteUAV_dialog["track"][5] 			= "ac130_fco_gotarunner";
	level.RemoteUAV_dialog["track"][6] 			= "ac130_fco_backonthose";
	level.RemoteUAV_dialog["track"][7] 			= "ac130_fco_gonnagethim";
	level.RemoteUAV_dialog["track"][8] 			= "ac130_fco_personnelthere";
	level.RemoteUAV_dialog["track"][9] 			= "ac130_fco_rightthere";
	level.RemoteUAV_dialog["track"][10] 		= "ac130_fco_tracking";

	level.RemoteUAV_dialog["tag"][0] 			= "ac130_fco_nice";
	level.RemoteUAV_dialog["tag"][1] 			= "ac130_fco_yougothim";
	level.RemoteUAV_dialog["tag"][2]			= "ac130_fco_yougothim2";
	level.RemoteUAV_dialog["tag"][3]			= "ac130_fco_okyougothim";	
	
	level.RemoteUAV_dialog["assist"][0] 		= "ac130_fco_goodkill";
	level.RemoteUAV_dialog["assist"][1] 		= "ac130_fco_thatsahit";
	level.RemoteUAV_dialog["assist"][2] 		= "ac130_fco_directhit";
	level.RemoteUAV_dialog["assist"][3]		 	= "ac130_fco_rightontarget";
}


//============================================
// 				setupHeliRange
//============================================
setupHeliRange()
{
	level.vanguardRangeTrigger 	= GetEnt( "remote_heli_range", "targetname" );
	level.vanguardMaxHeightEnt 	= GetEnt( "airstrikeheight", "targetname" );
	
	if( IsDefined(level.vanguardMaxHeightEnt) )
	{
		level.vanguardMaxHeight 	= level.vanguardMaxHeightEnt.origin[2];
		level.vanguradMaxDistanceSq = 12800 * 12800;
	}
}


//============================================
// 				tryUseVanguard
//============================================
tryUseVanguard( lifeId )
{
	return useVanguard( lifeId, "remote_uav" );
}


//============================================
// 			useVanguard
//============================================
useVanguard( lifeId, streakName )
{
	if( self isUsingRemote() || ( self isUsingTurret() ) || isDefined(level.nukeIncoming) )
	{
		return false;
	}	
	
	if( IsDefined(self.underWater) && self.underWater )
	{
		return false;
	}
	
	if( exceededMaxRemoteUAVs( self.team ) || (level.littleBirds.size >= 4) )
	{
		self iPrintLnBold( &"KILLSTREAKS_AIR_SPACE_TOO_CROWDED" );
		return false;
	}		
	else if( ( currentActiveVehicleCount() >= maxVehiclesAllowed() ) || ( level.fauxVehicleCount >= maxVehiclesAllowed() ) )
	{
		self iPrintLnBold( &"KILLSTREAKS_TOO_MANY_VEHICLES" );
		return false;
	}		
	
	incrementFauxVehicleCount();
	result = self giveCarryRemoteUAV( lifeId, streakName );
	
	if ( result )
	{
		self maps\mp\_matchdata::logKillstreakEvent( streakName, self.origin );
		self thread teamPlayerCardSplash( "used_remote_uav", self );
	}
	else
	{
		decrementFauxVehicleCount();
	}
	
	self.isCarrying = false;
	
	return result;
}


//============================================
// 			exceededMaxRemoteUAVs
//============================================
exceededMaxRemoteUAVs( team )
{
	if( level.teamBased )
	{
		if( isDefined(level.remote_uav[team]) )
		{
			return true;
		}
	}
	else
	{
		if( isDefined(level.remote_uav[team]) || isDefined(level.remote_uav[level.otherTeam[team]]) )
		{
			return true;
		}
	}
	
	return false;
}


giveCarryRemoteUAV( lifeId, streakName )
{
	carryObject = createCarryRemoteUAV( streakName, self );	
	
	// get rid of clicker and give hand model
	self takeWeapon( "killstreak_uav_mp" );
	self _giveWeapon( "killstreak_remote_uav_mp" );
	self SwitchToWeaponImmediate( "killstreak_remote_uav_mp" );		
	
	// give carry object and wait for placement (blocking loop)
	self setCarryingRemoteUAV( carryObject );
	
	// we're back, what happened?
	if ( isAlive( self ) && isDefined( carryObject ) )
	{		
		//	if it placed, start the killstreak at that location
		origin = carryObject.origin;
		angles = self.angles;
		carryObject.soundEnt delete();
		carryObject delete();		
		
		result = self startRemoteUAV( lifeId, streakName, origin, angles );		
	}	
	else
	{
		// cancelled placement or died
		result = false;
		if ( isAlive( self ) )
		{							
			// get rid of hand model
			self takeWeapon( "killstreak_remote_uav_mp" );
			
			// give back the clicker to be able to active killstreak again
			self _giveWeapon( "killstreak_uav_mp" );		
		}	
	}
	
	return result;
}


createCarryRemoteUAV( streakName, owner )
{
	pos = owner.origin + ( anglesToForward( owner.angles ) * 4 ) + ( anglesToUp( owner.angles ) * 50 );	

	carryRemoteUAV = spawnTurret( "misc_turret", pos, "sentry_minigun_mp" );
	carryRemoteUAV.origin = pos;
	carryRemoteUAV.angles = owner.angles;	
	
	carryRemoteUAV.sentryType = "sentry_minigun";
	carryRemoteUAV.canBePlaced = true;
	carryRemoteUAV setTurretModeChangeWait( true );
	carryRemoteUAV setMode( "sentry_offline" );
	carryRemoteUAV makeUnusable();	
	carryRemoteUAV makeTurretInoperable();
	carryRemoteUAV.owner = owner;
	carryRemoteUAV SetSentryOwner( carryRemoteUAV.owner );
	carryRemoteUAV.scale = 3;
	carryRemoteUAV.inHeliProximity = false;

	carryRemoteUAV thread carryRemoteUAV_handleExistence();	
	
	//	apparently can't call playLoopSound on a turret?
	carryRemoteUAV.soundEnt = spawn( "script_origin", carryRemoteUAV.origin );
	carryRemoteUAV.soundEnt.angles = carryRemoteUAV.angles;
	carryRemoteUAV.soundEnt.origin = carryRemoteUAV.origin;
	carryRemoteUAV.soundEnt linkTo( carryRemoteUAV );
	carryRemoteUAV.soundEnt playLoopSound( "recondrone_idle_high" );		

	return carryRemoteUAV;	
}


setCarryingRemoteUAV( carryRemoteUAV )
{	
	carryRemoteUAV thread carryRemoteUAV_setCarried( self );		

	self notifyOnPlayerCommand( "place_carryRemoteUAV", "+attack" );
	self notifyOnPlayerCommand( "place_carryRemoteUAV", "+attack_akimbo_accessible" ); // support accessibility control scheme
	self notifyOnPlayerCommand( "cancel_carryRemoteUAV", "+actionslot 4" );
	if( !level.console )
	{
		self notifyOnPlayerCommand( "cancel_carryRemoteUAV", "+actionslot 5" );
		self notifyOnPlayerCommand( "cancel_carryRemoteUAV", "+actionslot 6" );
		self notifyOnPlayerCommand( "cancel_carryRemoteUAV", "+actionslot 7" );
	}

	for ( ;; )
	{
		result = waittill_any_return( "place_carryRemoteUAV", "cancel_carryRemoteUAV", "weapon_switch_started", "force_cancel_placement", "killstreak_disowned", "death" );

		self forceUseHintOff();
		
		if ( result != "place_carryRemoteUAV" )
		{							
			self carryRemoteUAV_delete( carryRemoteUAV );
			break;
		}

		if ( !carryRemoteUAV.canBePlaced )
		{
			if ( self.team != "spectator" )
				self ForceUseHintOn( &"KILLSTREAKS_VANGUARD_CANNOT_PLACE" );
			continue;	
		}					
		
		if( isDefined( level.nukeIncoming ) || 
			self isEMPed() || 
			exceededMaxRemoteUAVs( self.team ) || 
			currentActiveVehicleCount() >= maxVehiclesAllowed() || 
			level.fauxVehicleCount >= maxVehiclesAllowed() )
		{
			if ( isDefined( level.nukeIncoming ) || self isEMPed() )
			{
				self iPrintLnBold( &"KILLSTREAKS_UNAVAILABLE_FOR_N_WHEN_EMP", level.empTimeRemaining );
			}
			else
			{
				self iPrintLnBold( &"KILLSTREAKS_TOO_MANY_VEHICLES" );
			}
			
			self carryRemoteUAV_delete( carryRemoteUAV );
			
			break;
		}		

		self.isCarrying = false;
		carryRemoteUAV.carriedBy = undefined;		
	
		carryRemoteUAV playSound( "sentry_gun_plant" );	
		carryRemoteUAV notify ( "placed" );		
		break;
	}
}


carryRemoteUAV_setCarried( carrier )
{
	self setCanDamage( false );
	self setSentryCarrier( carrier );
	self setContents( 0 );

	self.carriedBy = carrier;
	carrier.isCarrying = true;

	carrier thread updateCarryRemoteUAVPlacement( self );
	self notify ( "carried" );	
}


carryRemoteUAV_delete( carryRemoteUAV )
{
	self.isCarrying = false;
	
	if ( isDefined( carryRemoteUAV ) )
	{
		if ( isDefined( carryRemoteUAV.soundEnt ) )
		{
			carryRemoteUAV.soundEnt delete();
		}
		
		carryRemoteUAV delete();	
	}	
}


updateCarryRemoteUAVPlacement( carryRemoteUAV )
{
	self endon ( "death" );
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	
	carryRemoteUAV endon ( "placed" );
	carryRemoteUAV endon ( "death" );
	
	carryRemoteUAV.canBePlaced = true;
	lastCanPlaceCarryRemoteUAV = -1; // force initial update
	self _enableUsability();

	for( ;; )
	{		
		heightOffset = UAV_REMOTE_COLLISION_RADIUS;
		switch( self getStance() )
		{
			case "stand":
				heightOffset = 40;
				break;
			case "crouch":
				heightOffset = 25;
				break;
			case "prone":
				heightOffset = 10;
				break;
		}
		
		placement = self CanPlayerPlaceTank( 22, 22, 50, heightOffset, 0, 0 );
		carryRemoteUAV.origin = placement[ "origin" ] + ( anglesToUp(self.angles) * ( UAV_REMOTE_COLLISION_RADIUS - UAV_REMOTE_Z_OFFSET ) );
		carryRemoteUAV.angles = placement[ "angles" ];		
		carryRemoteUAV.canBePlaced = self isOnGround() && placement[ "result" ]; //&& carryRemoteUAV remoteUAV_in_range();			
	
		if ( carryRemoteUAV.canBePlaced != lastCanPlaceCarryRemoteUAV )
		{
			if ( carryRemoteUAV.canBePlaced )
			{
				if ( self.team != "spectator" )
					if ( GetDVAR( "g_gametype" ) != "aliens" )
						self ForceUseHintOn( &"KILLSTREAKS_VANGUARD_PLACE" );
					else
						self ForceUseHintOn( &"ALIEN_COLLECTIBILES_VANGUARD_PLACE" );
				
				//	if they're holding it in launch position just launch now
				if ( self attackButtonPressed() )
					self notify( "place_carryRemoteUAV" );				
			}
			else
			{
				if ( self.team != "spectator" )
					self ForceUseHintOn( &"KILLSTREAKS_VANGUARD_CANNOT_PLACE" );
			}
		}
		
		lastCanPlaceCarryRemoteUAV = carryRemoteUAV.canBePlaced;		
		wait ( 0.05 );
	}
}


carryRemoteUAV_handleExistence()
{
	level endon ( "game_ended" );
	self.owner endon ( "place_carryRemoteUAV" );
	self.owner endon ( "cancel_carryRemoteUAV" );

	self.owner waittill_any( "death", "disconnect", "joined_team", "joined_spectators" );

	if ( isDefined( self ) )
	{
		if ( isDefined( self.soundEnt ) )
			self.soundEnt delete();		
		self delete();
	}
}


removeRemoteWeapon()
{
	level endon( "game_ended" );
	self endon ( "disconnect" );
	
	wait(0.7);
	
}

startRemoteUAV( lifeId, streakName, origin, angles )
{		
	self lockPlayerForRemoteUAVLaunch();
	self setUsingRemote( streakName );
	
	self _giveWeapon("uav_remote_mp");
	self SwitchToWeaponImmediate("uav_remote_mp");	
	self VisionSetNakedForPlayer( "black_bw", 0.0 );	
	result = self maps\mp\killstreaks\_killstreaks::initRideKillstreak( "remote_uav" );		
	
	if ( result != "success" )
	{
		if ( result != "disconnect" )
		{
			self notify( "remoteuav_unlock" );
			self takeWeapon("uav_remote_mp");
			self clearUsingRemote();
		}
		return false;
	}	
	
	if( exceededMaxRemoteUAVs( self.team ) || 
		currentActiveVehicleCount() >= maxVehiclesAllowed() || 
		level.fauxVehicleCount >= maxVehiclesAllowed() )
	{
		self iPrintLnBold( &"KILLSTREAKS_TOO_MANY_VEHICLES" );
		self notify( "remoteuav_unlock" );
		self takeWeapon("uav_remote_mp");
		self clearUsingRemote();
		return false;
	}		

	self notify( "remoteuav_unlock" );
	remoteUAV = createRemoteUAV( lifeId, self, streakName, origin, angles );
	if ( isDefined( remoteUAV ) )
	{
		self thread remoteUAV_Ride( lifeId, remoteUAV, streakName );
		return true;
	}
	else
	{
		self iPrintLnBold( &"KILLSTREAKS_TOO_MANY_VEHICLES" );
		self takeWeapon("uav_remote_mp");
		self clearUsingRemote();
		return false;	
	}		
}


lockPlayerForRemoteUAVLaunch()
{
	//	lock
	lockSpot = spawn( "script_origin", self.origin );
	lockSpot hide();	
	self playerLinkTo( lockSpot );	
	
	//	wait for unlock
	self thread clearPlayerLockFromRemoteUAVLaunch( lockSpot );
}


clearPlayerLockFromRemoteUAVLaunch( lockSpot )
{
	level endon( "game_ended" );
	
	msg = self waittill_any_return( "disconnect", "death", "remoteuav_unlock" );
	
	//	do unlock stuff
	if ( msg != "disconnect" )
		self unlink();
	lockSpot delete();
}


createRemoteUAV( lifeId, owner, streakName, origin, angles )
{
	if ( level.console )
	{
		remoteUAV = spawnHelicopter( owner, origin, angles, "remote_uav_mp", "vehicle_drone_tricopter" );	
	}
	else
	{
		remoteUAV = spawnHelicopter( owner, origin, angles, "remote_uav_mp_pc", "vehicle_remote_uav" );	
	}
	
	if ( !isDefined( remoteUAV ) )
		return undefined;
	
	remoteUAV maps\mp\killstreaks\_helicopter::addToLittleBirdList();
	remoteUAV thread maps\mp\killstreaks\_helicopter::removeFromLittleBirdListOnDeath();

	//radius and offset should match vehHelicopterBoundsRadius (GDT) and bg_vehicle_sphere_bounds_offset_z.
	remoteUAV MakeVehicleSolidCapsule( UAV_REMOTE_COLLISION_RADIUS, UAV_REMOTE_Z_OFFSET, UAV_REMOTE_COLLISION_RADIUS ); 
	
	// target fx
	remoteUAV.attackArrow = spawn( "script_model", ( 0, 0, 0 ) );
	remoteUAV.attackArrow setModel( "tag_origin" );
	remoteUAV.attackArrow.angles = ( -90, 0, 0 );
	remoteUAV.attackArrow.offset = 4;
	
	remoteUAV.attackArrow Hide();
	
	// don't show arrow to friendly players
	foreach( player in level.players )
	{
		if( player.team != owner.team )
		{
			remoteUAV.attackArrow ShowToPlayer( player );
		}
		
		if( player == owner )
		{
			remoteUAV.attackArrow ShowToPlayer( player );
		}
	}
		
	remoteUAV.lifeId = lifeId;
	remoteUAV.team = owner.team;
	remoteUAV.pers["team"] = owner.team;	
	remoteUAV.owner = owner;
	remoteUAV make_entity_sentient_mp( owner.team );

	remoteUAV.health = 999999; // keep it from dying anywhere in code
	remoteUAV.maxHealth = 250; // this is the health we'll check
	remoteUAV.damageTaken = 0;	
	remoteUAV.destroyed = false;
	remoteUAV setCanDamage( true );
	remoteUAV.specialDamageCallback = ::Callback_VehicleDamage;
	
	//	scrambler
	remoteUAV.scrambler = spawn( "script_model", origin );
	remoteUAV.scrambler linkTo( remoteUAV, "tag_origin", (0,0,-160), (0,0,0) );
	remoteUAV.scrambler makeScrambler( owner );
	
	remoteUAV.smoking = false;
	remoteUAV.inHeliProximity = false;		
	remoteUAV.heliType = "remote_uav";	
	
	level thread vanguard_monitorKillStreakDisowned( remoteUAV);
	level thread vanguard_monitorTimeout( remoteUAV );
	level thread vanguard_monitorDeath( remoteUAV );
		
	remoteUAV thread remoteUAV_watch_distance();
	remoteUAV thread remoteUAV_watchHeliProximity();	
	remoteUAV thread remoteUAV_handleDamage();
	
	level.remote_uav[remoteUAV.team] = remoteUAV;
	return remoteUAV;
}


remoteUAV_ride( lifeId, remoteUAV, streakName )
{		
	remoteUAV.playerLinked = true;
	self.restoreAngles = self.angles;
	
	if ( getDvarInt( "camera_thirdPerson" ) )
		self setThirdPersonDOF( false );	
		
	maps\mp\killstreaks\_juggernaut::disableJuggernaut();
		
	self CameraLinkTo( remoteUAV, "tag_origin" );	
	self RemoteControlVehicle( remoteUAV );	
	remoteUAV.ammoCount = VANGUARD_AMMO_COUNT;
	
	self thread vanguard_think( remoteUAV );
	self thread vanguard_monitorFire( remoteUAV );
	self thread vanguard_monitorManualPlayerExit( remoteUAV );

	self.remote_uav_rideLifeId = lifeId;
	self.remoteUAV = remoteUAV;
	
	self thread remoteUAV_delayLaunchDialog( remoteUAV );
	
	self VisionSetNakedForPlayer( "black_bw", 0.0 );
	self restoreVisionSet();
}


remoteUAV_delayLaunchDialog( remoteUAV )
{
	level endon( "game_ended" );
	self endon ( "disconnect" );
	remoteUAV endon ( "death" );
	remoteUAV endon ( "end_remote" );
	remoteUAV endon ( "end_launch_dialog" );	
	
	wait( 3 );
	self remoteUAV_dialog( "launch" );
}


//============================================
// 	   vanguard_monitorManualPlayerExit
//============================================
vanguard_monitorManualPlayerExit( vanguard )
{
	level endon( "game_ended" );
	self endon ( "disconnect" );
	vanguard endon ( "death" );
	vanguard endon ( "end_remote" );
	
	//	delay exit for transition into remote
	wait( 2 );
	
	while( true )
	{
		timeUsed = 0;
		while(	self UseButtonPressed() )
		{	
			timeUsed += 0.05;
			if( timeUsed > 0.75 )
			{	
				vanguard notify( "death" );
				return;
			}
			wait( 0.05 );
		}
		waitframe();
	}
}


//============================================
// 			vanguard_think
//============================================
vanguard_think( vanguard )
{
	level endon ( "game_ended" );
	self endon ( "disconnect" );
	vanguard endon ( "death" );
	vanguard endon ( "end_remote" );
	
	wait( VANGUARD_TRANSITION_TIME );
	
	self ThermalVisionFOFOverlayOn();
	
	while( true )
	{
		self.lockedLocation = vanguard_selectTarget( vanguard );
		waitframe();
	}
}


//============================================
// 			vanguard_selectTarget
//============================================
vanguard_selectTarget( vanguard )
{
	result = getTargetPoint( vanguard.owner, vanguard);
	
	if( IsDefined(result) )
	{
		if( !IsDefined(vanguard.missile) )
		{
			vanguard.attackArrow.origin = result[0] + (0,0,4);
			vanguard.attackArrow.angles = vectortoangles( result[1] );
		}
		stopfxontag( level.RemoteUAV_fx["target_marker_circle"], vanguard.attackArrow, "tag_origin" );	
		playfxontag( level.RemoteUAV_fx["target_marker_circle"], vanguard.attackArrow, "tag_origin" );
		
		return result[0];
	}
	
	return undefined;
}


getTargetPoint( player, vanguard)
{
	origin = vanguard getTagOrigin( "tag_turret" );
	angles = player GetPlayerAngles();
	forward = AnglesToForward( angles );
	endpoint = origin + forward * 15000;
	
	res = BulletTrace( origin, endpoint, false, vanguard );

	if ( res["surfacetype"] == "none" )
		return undefined;
	if ( res["surfacetype"] == "default" )
		return undefined;

	ent = res["entity"];
	if ( IsDefined( ent ) )
	{
		if ( ent == level.ac130.planeModel )
			return undefined;
	}

	results = [];
	results[0] = res["position"];
	results[1] = res["normal"];
	
	return results;
}


//============================================
// 			vanguard_monitorFire
//============================================
vanguard_monitorFire( vanguard )
{
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	vanguard endon ( "death" );
	vanguard endon ( "end_remote" );
	
	wait( VANGUARD_TRANSITION_TIME );
	
	self notifyOnPlayerCommand( "vanguard_fire", "+attack" );
	self notifyOnPlayerCommand( "vanguard_fire", "+attack_akimbo_accessible" );
	
	while ( true )
	{		
		self waittill( "vanguard_fire" ); 
		
		if( isDefined( self.lockedLocation ) )
		{
			self vanguard_fireMissile( vanguard, self.lockedLocation );			
		}
	}
}


vanguard_rumble( vanguard, numFrames )
{
	self      endon ( "disconnect" );
	level     endon ( "game_ended" );
	
	vanguard endon ( "death" );
	vanguard endon ( "end_remote" );
	vanguard notify( "end_rumble" );
	vanguard endon ( "end_rumble" );
	
	for( i = 0; i < numFrames; i++ )
	{
		self playRumbleOnEntity( "damage_heavy" );
		waitframe();
	}	
}


//============================================
// 			vanguard_fireMissile
//============================================
vanguard_fireMissile( vanguard, targetLocation )
{	
	level endon( "game_ended" );
		
	if( vanguard.ammoCount <= 0 )
	{
		return;
	}
	
	vanguard.ammoCount--;
	
	// player feedback for missile fire
	self playLocalSound( "recondrone_tag" );
	self thread vanguard_rumble( vanguard, 1 );	
	
	// call in missile on player
	startPoistion = getStartPosition( vanguard, targetLocation );
	vanguard.missile = MagicBullet( "remote_tank_projectile_mp", startPoistion, targetLocation, self );
	
	// wait until missile explodes
	vanguard.missile waittill( "death" );
	
	// missile hit
	self thread vanguard_rumble( vanguard, 12 );	
	Earthquake( 0.3, 0.75, vanguard.origin, 128 );
	
	if( vanguard.ammoCount == 0 )
	{
		wait( 0.75 );
		vanguard notify( "death" );
	}
	else
	{
		wait(0.35);
	}
}

getStartPosition( vanguard, targetPoint )
{
	traceLength = (3000,3000,3000);
	dir 		= VectorNormalize( vanguard.origin - ( targetPoint + (0,0,-400) ) );
	
	// try an angle over the shoulder of the vanguard
	dirRotated 	= RotateVector(dir, (0,25,0) );
	startPos 	= targetPoint + (dirRotated*traceLength);
	
	if( isValidStartPoint( startPos, targetPoint ) )
	{
		return startPos;
	}
	
	// try an angle over the other shoulder of the vanguard 
	dirRotated 	= RotateVector(dir, (0,-25,0) );
	startPos 	= targetPoint + (dirRotated*traceLength);
	
	if( isValidStartPoint( startPos, targetPoint ) )
	{
		return startPos;
	}
	
	// try an angle directly behind
	startPos = targetPoint + (dir*traceLength);
	
	if( isValidStartPoint( startPos, targetPoint ) )
	{
		return startPos;
	}
		
	// drop the missile straight down
	return ( targetPoint + (0,0,3000) );
}

isValidStartPoint( startPoint, enPoint )
{
	skyTrace = bulletTrace( startPoint, enPoint , false );
	//level thread drawLine( startPoint, enPoint, 25, (1,0,0) );
	
	if( skyTrace["fraction"] > .99 )
	{
		return true;	
	}
	
	return false;;
}

remoteUAV_watch_distance()
{
	self endon ("death" );
		
	//	shouldn't be possible to start out of range, but just in case
	inRangePos = self.origin;		
	
	self.rangeCountdownActive = false;
	
	//	loop
	while ( true )
	{
		if ( !self remoteUAV_in_range() )
		{
			//	increase static with distance from exit point or distance to heli in proximity
			staticAlpha = 0;		
			while ( !self remoteUAV_in_range() )
			{
				self.owner remoteUAV_dialog( "out_of_range" );
				if ( !self.rangeCountdownActive )
				{
					self.rangeCountdownActive = true;
					self thread remoteUAV_rangeCountdown();
				}
				if ( isDefined( self.heliInProximity ) )
				{
					dist = distance( self.origin, self.heliInProximity.origin );
					staticAlpha = 1 - ( (dist-UAV_REMOTE_MIN_HELI_PROXIMITY) / (UAV_REMOTE_MAX_HELI_PROXIMITY-UAV_REMOTE_MIN_HELI_PROXIMITY) );
				}
				else
				{
					dist = distance( self.origin, inRangePos );
					staticAlpha = min( 1, dist/UAV_REMOTE_MAX_PAST_RANGE );					
				}
				
				//self.owner setPlayerData( "reconDroneState", "staticAlpha", staticAlpha );
				self.owner SetClientDvar( "ui_predator_missile", true );				
				self.owner SetClientDvar( "ui_predator_missile_static", true );
				
				waitframe();
			}
			
			//	end countdown
			self notify( "in_range" );
			self.rangeCountdownActive = false;
			
			//	fade out static
			//self thread remoteUAV_staticFade( staticAlpha );
			self.owner SetClientDvar( "ui_predator_missile", false );				
			self.owner SetClientDvar( "ui_predator_missile_static", false );
		}		
		inRangePos = self.origin;
		wait ( 0.05 );
	}
}


remoteUAV_in_range()
{
	if( self.inHeliProximity  )
	{
		return false;
	}
	
	if( IsDefined( level.vanguardRangeTrigger ) )
	{
		if( !self isTouching( level.vanguardRangeTrigger )  )
			return true;
	}
	else
	{
		if( (Distance2DSquared( self.origin, level.mapCenter ) < level.vanguradMaxDistanceSq ) && (self.origin[2] < level.vanguardMaxHeight) )
			return true;
	}
	
	return false;
}


remoteUAV_staticFade( staticAlpha )
{
	self endon ( "death" );
	while( self remoteUAV_in_range() )
	{
		staticAlpha -= 0.05;
		if ( staticAlpha < 0 )
		{
			self.owner setPlayerData( "reconDroneState", "staticAlpha", 0 );
			break;
		}
		self.owner setPlayerData( "reconDroneState", "staticAlpha", staticAlpha );			
		
		waitframe();
	}
}


remoteUAV_rangeCountdown()
{
	self endon( "death" );
	self endon( "in_range" );
	
	if ( isDefined( self.heliInProximity ) )
		countdown = UAV_REMOTE_HELI_RANGE_COUNTDOWN;
	else
		countdown = UAV_REMOTE_PAST_RANGE_COUNTDOWN;
	
	maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( countdown );
	
	self notify( "death" );
}


//============================================
// 	  vanguard_monitorKillStreakDisowned
//============================================
vanguard_monitorKillStreakDisowned( vanguard )
{
	vanguard endon( "death" );	

	vanguard.owner waittill_any( "killstreak_disowned" );
	
	vanguard notify( "death" );
}


//============================================
// 			vanguard_monitorTimeout
//============================================
vanguard_monitorTimeout( vanguard )
{
	vanguard endon ( "death" );	
	
	maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( VANGUARD_FLY_TIME );
	
	vanguard notify( "death" );
}


//============================================
// 			vanguard_monitorDeath
//============================================
vanguard_monitorDeath( vanguard )
{
	level endon( "game_ended" );
	
	vanguard waittill( "death" );			
		
	vanguard playSound( "recondrone_destroyed" );
	playFX( level.RemoteUAV_fx["explode"], vanguard.origin );
	
	vanguard_endride( vanguard.owner, vanguard );	
}


//============================================
// 			vanguard_endride
//============================================
vanguard_endride( player, vanguard )
{
	vanguard notify( "end_remote" );
	vanguard.playerLinked = false;

	vanguard_removePlayer( player, vanguard );
	
	if( isDefined( vanguard.scrambler ) )
	{
		vanguard.scrambler delete();
	}
	
	stopFXOnTag( level.RemoteUAV_fx["smoke"], vanguard, "tag_origin" );
	
	level.remote_uav[player.team] = undefined;

	decrementFauxVehicleCount();
	vanguard.attackArrow delete();
	vanguard delete();
}

//============================================
// 			restoreVisionSet
//============================================
restoreVisionSet()
{
	if( IsDefined(level.nukeDetonated) )
	{
		self VisionSetNakedForPlayer( level.nukeVisionSet, 1 );
	}
	else
	{
		self VisionSetNakedForPlayer( "", 1 );
	}
}

//============================================
// 			vanguard_removePlayer
//============================================
vanguard_removePlayer( player, vanguard )
{
	player clearUsingRemote();
	player restoreVisionSet();
	
	player SetClientDvar( "ui_predator_missile", false );				
	player SetClientDvar( "ui_predator_missile_static", false );
	
	if( getDvarInt( "camera_thirdPerson" ) )
	{
		player setThirdPersonDOF( true );	
	}
		
	maps\mp\killstreaks\_juggernaut::enableJuggernaut();
	
	player CameraUnlink( vanguard );
	player RemoteControlVehicleOff( vanguard );
	player ThermalVisionFOFOverlayOff();
	player setPlayerAngles( player.restoreAngles );	
	
	lastWeapon = player getLastWeapon();
	
	if( !player hasWeapon( lastWeapon ) )
	{
		lastWeapon = player maps\mp\killstreaks\_killstreaks::getFirstPrimaryWeapon();
	}
	
	player switchToWeapon( lastWeapon );
	player TakeWeapon( "uav_remote_mp" );
	level thread vanguard_freezeControlsBuffer( player );
	
	player.remoteUAV = undefined;
}


//============================================
// 		vanguard_freezeControlsBuffer
//============================================
vanguard_freezeControlsBuffer( player )
{
	player endon( "disconnect" );
	player endon( "death" );
	level endon( "game_ended" );
	
	player freezeControlsWrapper( true );
	waitframe();
	player freezeControlsWrapper( false );
}


remoteUAV_dialog( dialogGroup )
{
	if ( dialogGroup == "tag" )
		waitTime = 1000;
	else
		waitTime = 5000;
	
	if ( getTime() - level.RemoteUAV_lastDialogTime < waitTime )
		return;
	
	level.RemoteUAV_lastDialogTime = getTime();
	
	randomIndex = randomInt( level.remoteUAV_dialog[ dialogGroup ].size );
	soundAlias = level.remoteUAV_dialog[ dialogGroup ][ randomIndex ];
	
	fullSoundAlias = maps\mp\gametypes\_teams::getTeamVoicePrefix( self.team ) + soundAlias;
	
	self playLocalSound( fullSoundAlias );
}


remoteUAV_watchHeliProximity()
{
	level endon( "game_ended" );
	self  endon( "death" );
	self  endon( "end_remote" );
	
	while( true )
	{
		inHeliProximity = false;
		foreach( heli in level.helis )
		{
			if ( distance( heli.origin, self.origin ) < UAV_REMOTE_MAX_HELI_PROXIMITY )
			{
				inHeliProximity = true;
				self.heliInProximity = heli;
			}
		}
		foreach( littlebird in level.littleBirds )
		{
			if ( littlebird != self && ( !isDefined(littlebird.heliType) || littlebird.heliType != "remote_uav" ) && distance( littlebird.origin, self.origin ) < UAV_REMOTE_MAX_HELI_PROXIMITY )
			{
				inHeliProximity = true;
				self.heliInProximity = littlebird;	
			}
		}
		
		if ( !self.inHeliProximity && inHeliProximity )
			self.inHeliProximity = true;
		else if ( self.inHeliProximity && !inHeliProximity )
		{
			self.inHeliProximity = false;
			self.heliInProximity = undefined;
		}
		
		wait( 0.05 );
	}
}


remoteUAV_handleDamage()
{
	level endon( "game_ended" );
	self  endon( "death" );
	self  endon( "end_remote" );

	while( true )
	{
		self waittill( "damage", damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon );

		if( IsDefined( self.specialDamageCallback ) )
			self [[self.specialDamageCallback]]( undefined, attacker, damage, iDFlags, meansOfDeath, weapon, point, direction_vec, undefined, undefined, modelName, partName );
	}
}


Callback_VehicleDamage( inflictor, attacker, damage, iDFlags, meansOfDeath, weapon, point, dir, hitLoc, timeOffset, modelIndex, partName )
{
	if( self.destroyed == true )
	{
		return;
	}
		
	if( !maps\mp\gametypes\_weapons::friendlyFireCheck( self.owner, attacker ) )
	{
		return;
	}
			
	modifiedDamage = damage;

	if( isPlayer( attacker ) )
	{
		attacker maps\mp\gametypes\_damagefeedback::updateDamageFeedback( "remote_uav" );		

		if( attacker _hasPerk( "specialty_armorpiercing" ) )
		{
			modifiedDamage = damage * level.armorPiercingMod;			
		}
	}
	
	// in case we are shooting from a remote position, like being in the osprey gunner shooting this
	if( IsDefined( attacker.owner ) && IsPlayer( attacker.owner ) )
	{
		attacker.owner maps\mp\gametypes\_damagefeedback::updateDamageFeedback( "remote_uav" );
	}

	if( IsDefined( weapon ) )
	{
		switch( weapon )
		{
			case "ac130_105mm_mp":
			case "ac130_40mm_mp":
			case "stinger_mp":
			case "javelin_mp":
			case "remote_mortar_missile_mp":		
			case "remotemissile_projectile_mp":
			case "bomb_site_mp":
			case "remote_tank_projectile_mp":
				modifiedDamage = modifiedDamage * 1.5;
				break;
			case "emp_grenade_mp":
				modifiedDamage = self.maxHealth + 1;
				break;
			default:
				break;
		}
		
		maps\mp\killstreaks\_killstreaks::killstreakHit( attacker, weapon, self );
	}
	
	if( isDefined( meansOfDeath ) && meansOfDeath == "MOD_MELEE" )
	{
		modifiedDamage = self.maxHealth + 1;
	}

	self.damageTaken += modifiedDamage;	
	
	PlayFXOnTagForClients( level.RemoteUAV_fx["hit"], self, "tag_origin", self.owner );
	self playsound( "recondrone_damaged" );
	
	if( self.smoking == false && self.damageTaken >= self.maxhealth/2 )
	{
		self.smoking = true;

		playFxOnTag( level.RemoteUAV_fx["smoke"], self, "tag_origin" );
	}
	
	if( self.damageTaken >= self.maxhealth )
	{
		self.destroyed = true;
		validAttacker = undefined;
		if ( isDefined( attacker.owner ) && (!isDefined(self.owner) || attacker.owner != self.owner) )
			validAttacker = attacker.owner;				
		else if ( !isDefined(self.owner) || attacker != self.owner )
			validAttacker = attacker;
			
		//	sanity checks	
		if ( !isDefined(attacker.owner) && attacker.classname == "script_vehicle" )
				validAttacker = undefined;
		if ( isDefined( attacker.class ) && attacker.class == "worldspawn" )
				validAttacker = undefined;	
		if ( attacker.classname == "trigger_hurt" )
				validAttacker = undefined;		

		if ( isDefined( validAttacker ) )
		{
			validAttacker notify( "destroyed_killstreak", weapon );
			thread teamPlayerCardSplash( "callout_destroyed_remote_uav", validAttacker );			
			validAttacker thread maps\mp\gametypes\_rank::giveRankXP( "kill", 50, weapon, meansOfDeath );			
			validAttacker thread maps\mp\gametypes\_rank::xpEventPopup( &"SPLASHES_DESTROYED_REMOTE_UAV" );
			thread maps\mp\gametypes\_missions::vehicleKilled( self.owner, self, undefined, validAttacker, damage, meansOfDeath, weapon );	
		}

		self notify ( "death" );
	}			
}
