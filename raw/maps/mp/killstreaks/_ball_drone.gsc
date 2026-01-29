/*
	Ball Drone
	Author: Aaron Eady
	Description: The idea is to have a companion killstreak that stays with you and acts as a helper.
*/

#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;
#include maps\mp\gametypes\_hostmigration;

STUNNED_TIME = 7.0;
Z_OFFSET = ( 0, 0, 90 );

BALL_DRONE_STAND_UP_OFFSET		= 118;
BALL_DRONE_CROUCH_UP_OFFSET		= 70;
BALL_DRONE_PRONE_UP_OFFSET		= 36;
BALL_DRONE_BACK_OFFSET			= 40;
BALL_DRONE_SIDE_OFFSET			= 40;
	
init()
{
	level.killStreakFuncs[ "ball_drone_radar" ] = ::tryUseBallDroneRadar;
	level.killStreakFuncs[ "ball_drone_backup" ] = ::tryUseBallDroneBackup;
	level.killStreakFuncs[ "ball_drone_3dping" ] = ::tryUseBallDrone3DPing;

	level.ballDroneSettings = [];

	level.ballDroneSettings[ "ball_drone_radar" ] = SpawnStruct();
	level.ballDroneSettings[ "ball_drone_radar" ].timeOut =					60.0;	
	level.ballDroneSettings[ "ball_drone_radar" ].health =					999999; // keep it from dying anywhere in code	
	level.ballDroneSettings[ "ball_drone_radar" ].maxHealth =				250; // this is what we check against for death	
	level.ballDroneSettings[ "ball_drone_radar" ].streakName =				"ball_drone_radar";
	level.ballDroneSettings[ "ball_drone_radar" ].vehicleInfo =				"ball_drone_mp";
	level.ballDroneSettings[ "ball_drone_radar" ].modelBase =				"vehicle_drone_ball";
	level.ballDroneSettings[ "ball_drone_radar" ].teamSplash =				"used_ball_drone_radar";	
	level.ballDroneSettings[ "ball_drone_radar" ].fxId_sparks =				LoadFX( "fx/explosions/generator_sparks_d" );	
	level.ballDroneSettings[ "ball_drone_radar" ].fxId_explode =			LoadFX( "fx/explosions/bouncing_betty_explosion" );	
	level.ballDroneSettings[ "ball_drone_radar" ].fxId_enemy_light1 =		LoadFX( "fx/lights/light_detonator_blink" );
	level.ballDroneSettings[ "ball_drone_radar" ].fxId_enemy_light2 =		LoadFX( "fx/lights/light_detonator_blink" );
	level.ballDroneSettings[ "ball_drone_radar" ].fxId_enemy_light3 =		LoadFX( "fx/lights/light_detonator_blink" );
	level.ballDroneSettings[ "ball_drone_radar" ].fxId_enemy_light4 =		LoadFX( "fx/lights/light_detonator_blink" );
	level.ballDroneSettings[ "ball_drone_radar" ].fxId_friendly_light1 =	LoadFX( "fx/misc/light_mine_blink_friendly" );
	level.ballDroneSettings[ "ball_drone_radar" ].fxId_friendly_light2 =	LoadFX( "fx/misc/light_mine_blink_friendly" );
	level.ballDroneSettings[ "ball_drone_radar" ].fxId_friendly_light3 =	LoadFX( "fx/misc/light_mine_blink_friendly" );
	level.ballDroneSettings[ "ball_drone_radar" ].fxId_friendly_light4 =	LoadFX( "fx/misc/light_mine_blink_friendly" );
	level.ballDroneSettings[ "ball_drone_radar" ].sound_explode =			"ball_drone_explode";	
	level.ballDroneSettings[ "ball_drone_radar" ].voDestroyed =				"radar_destroyed";	

	level.ballDroneSettings[ "ball_drone_backup" ] = SpawnStruct();
	level.ballDroneSettings[ "ball_drone_backup" ].timeOut =				60.0;	
	level.ballDroneSettings[ "ball_drone_backup" ].health =					999999; // keep it from dying anywhere in code	
	level.ballDroneSettings[ "ball_drone_backup" ].maxHealth =				250; // this is what we check against for death	
	level.ballDroneSettings[ "ball_drone_backup" ].streakName =				"ball_drone_backup";
	level.ballDroneSettings[ "ball_drone_backup" ].vehicleInfo =			"tricopter_drone_mp";
	level.ballDroneSettings[ "ball_drone_backup" ].modelBase =				"vehicle_drone_tricopter";
	level.ballDroneSettings[ "ball_drone_backup" ].teamSplash =				"used_ball_drone_radar";	
	level.ballDroneSettings[ "ball_drone_backup" ].fxId_sparks =			LoadFX( "fx/explosions/generator_sparks_d" );	
	level.ballDroneSettings[ "ball_drone_backup" ].fxId_explode =			LoadFX( "fx/explosions/bouncing_betty_explosion" );	
	level.ballDroneSettings[ "ball_drone_backup" ].fxId_enemy_light1 =		LoadFX( "fx/lights/light_detonator_blink" );
	level.ballDroneSettings[ "ball_drone_backup" ].fxId_enemy_light2 =		LoadFX( "fx/lights/light_detonator_blink" );
	level.ballDroneSettings[ "ball_drone_backup" ].fxId_enemy_light3 =		LoadFX( "fx/lights/light_detonator_blink" );
	level.ballDroneSettings[ "ball_drone_backup" ].fxId_enemy_light4 =		LoadFX( "fx/lights/light_detonator_blink" );
	level.ballDroneSettings[ "ball_drone_backup" ].fxId_friendly_light1 =	LoadFX( "fx/misc/light_mine_blink_friendly" );
	level.ballDroneSettings[ "ball_drone_backup" ].fxId_friendly_light2 =	LoadFX( "fx/misc/light_mine_blink_friendly" );
	level.ballDroneSettings[ "ball_drone_backup" ].fxId_friendly_light3 =	LoadFX( "fx/misc/light_mine_blink_friendly" );
	level.ballDroneSettings[ "ball_drone_backup" ].fxId_friendly_light4 =	LoadFX( "fx/misc/light_mine_blink_friendly" );
	level.ballDroneSettings[ "ball_drone_backup" ].sound_explode =			"ball_drone_explode";	
	level.ballDroneSettings[ "ball_drone_backup" ].voDestroyed =			"backup_destroyed";	
	level.ballDroneSettings[ "ball_drone_backup" ].weaponInfo =				"ball_drone_gun_mp";
	level.ballDroneSettings[ "ball_drone_backup" ].projectileInfo =			"ball_drone_projectile_mp";
	level.ballDroneSettings[ "ball_drone_backup" ].weaponModel =			"turret_drone_ball";
	level.ballDroneSettings[ "ball_drone_backup" ].weaponTag =				"tag_turret";	
	level.ballDroneSettings[ "ball_drone_backup" ].sound_weapon =			"weap_p99_fire_npc";	
	level.ballDroneSettings[ "ball_drone_backup" ].sound_targeting =		"ball_drone_targeting";	
	level.ballDroneSettings[ "ball_drone_backup" ].sound_lockon =			"ball_drone_lockon";	
	level.ballDroneSettings[ "ball_drone_backup" ].sentryMode =				"sentry";	
	level.ballDroneSettings[ "ball_drone_backup" ].visual_range_sq =			1200 * 1200; // distance radius it will acquire targets (see)
	//level.ballDroneSettings[ "ball_drone_backup" ].target_recognition = 0.5; // percentage of the player's body it sees before it labels him as a target
	level.ballDroneSettings[ "ball_drone_backup" ].burstMin =				5;
	level.ballDroneSettings[ "ball_drone_backup" ].burstMax =				10;
	level.ballDroneSettings[ "ball_drone_backup" ].pauseMin =				0.15;
	level.ballDroneSettings[ "ball_drone_backup" ].pauseMax =				0.35;	
	level.ballDroneSettings[ "ball_drone_backup" ].lockonTime =				0.5;	

	level.ballDroneSettings[ "ball_drone_3dping" ] = SpawnStruct();
	level.ballDroneSettings[ "ball_drone_3dping" ].timeOut =				67.5;	
	level.ballDroneSettings[ "ball_drone_3dping" ].health =					999999; // keep it from dying anywhere in code	
	level.ballDroneSettings[ "ball_drone_3dping" ].maxHealth =				250; // this is what we check against for death	
	level.ballDroneSettings[ "ball_drone_3dping" ].streakName =				"ball_drone_3dping";
	level.ballDroneSettings[ "ball_drone_3dping" ].vehicleInfo =			"ball_drone_mp";
	level.ballDroneSettings[ "ball_drone_3dping" ].modelBase =				"vehicle_drone_ball";
	level.ballDroneSettings[ "ball_drone_3dping" ].teamSplash =				"used_ball_drone_3dping";	
	level.ballDroneSettings[ "ball_drone_3dping" ].fxId_sparks =			LoadFX( "fx/explosions/generator_sparks_d" );	
	level.ballDroneSettings[ "ball_drone_3dping" ].fxId_explode =			LoadFX( "fx/explosions/bouncing_betty_explosion" );	
	level.ballDroneSettings[ "ball_drone_3dping" ].fxId_enemy_light1 =		LoadFX( "fx/lights/light_detonator_blink" );
	level.ballDroneSettings[ "ball_drone_3dping" ].fxId_enemy_light2 =		LoadFX( "fx/lights/light_detonator_blink" );
	level.ballDroneSettings[ "ball_drone_3dping" ].fxId_enemy_light3 =		LoadFX( "fx/lights/light_detonator_blink" );
	level.ballDroneSettings[ "ball_drone_3dping" ].fxId_enemy_light4 =		LoadFX( "fx/lights/light_detonator_blink" );
	level.ballDroneSettings[ "ball_drone_3dping" ].fxId_friendly_light1 =	LoadFX( "fx/misc/light_mine_blink_friendly" );
	level.ballDroneSettings[ "ball_drone_3dping" ].fxId_friendly_light2 =	LoadFX( "fx/misc/light_mine_blink_friendly" );
	level.ballDroneSettings[ "ball_drone_3dping" ].fxId_friendly_light3 =	LoadFX( "fx/misc/light_mine_blink_friendly" );
	level.ballDroneSettings[ "ball_drone_3dping" ].fxId_friendly_light4 =	LoadFX( "fx/misc/light_mine_blink_friendly" );
	level.ballDroneSettings[ "ball_drone_3dping" ].sound_explode =			"ball_drone_explode";	
	level.ballDroneSettings[ "ball_drone_3dping" ].voDestroyed =			"gpsb_destroyed";	
	level.ballDroneSettings[ "ball_drone_3dping" ].pingTime =				15.0; // time between pings	
	level.ballDroneSettings[ "ball_drone_3dping" ].highlightFadeTime =		7.5; // time it takes to fade out the hightlight
	level.ballDroneSettings[ "ball_drone_3dping" ].fxId_ping =				LoadFX( "fx/ui/3d_world_ping" );
	level.ballDroneSettings[ "ball_drone_3dping" ].sound_ping =				"ball_drone_3Dping";
	level.ballDroneSettings[ "ball_drone_3dping" ].modelHighlightS =		"mp_body_delta_elite_assault_aa_highlight";
	level.ballDroneSettings[ "ball_drone_3dping" ].modelHighlightC =		"mp_body_delta_elite_assault_aa_highlight";
	level.ballDroneSettings[ "ball_drone_3dping" ].modelHighlightP =		"mp_body_delta_elite_assault_aa_highlight";

	//ballDrone_setAirNodeMesh();
	
	level.ballDrones = [];

/#
	SetDevDvarIfUninitialized( "scr_balldrone_timeout", 60.0 );
	SetDevDvarIfUninitialized( "scr_balldrone_3dping_pingTime", level.ballDroneSettings[ "ball_drone_3dping" ].pingTime );
	SetDevDvarIfUninitialized( "scr_balldrone_3dping_highlightFadeTime", level.ballDroneSettings[ "ball_drone_3dping" ].highlightFadeTime );
	SetDevDvarIfUninitialized( "scr_balldrone_debug_position", 0 );
	SetDevDvarIfUninitialized( "scr_balldrone_debug_position_forward", 50.0 );
	SetDevDvarIfUninitialized( "scr_balldrone_debug_position_height", 35.0 );
	SetDevDvarIfUninitialized( "scr_balldrone_debug_path", 0 );
#/
}

tryUseBallDroneRadar( lifeId ) // self == player
{
	return useBallDrone( "ball_drone_radar" );
}

tryUseBallDroneBackup( lifeId ) // self == player
{
	return useBallDrone( "ball_drone_backup" );
}

tryUseBallDrone3DPing( lifeId ) // self == player
{
	return useBallDrone( "ball_drone_3dping" );
}

useBallDrone( ballDroneType )
{
	numIncomingVehicles = 1;
	if( self isUsingRemote() )
	{
		return false;
	}	
	else if( exceededMaxBallDrones( ballDroneType ) )
	{
		self IPrintLnBold( &"KILLSTREAKS_AIR_SPACE_TOO_CROWDED" );
		return false;	
	}
	else if( currentActiveVehicleCount() >= maxVehiclesAllowed() || level.fauxVehicleCount + numIncomingVehicles >= maxVehiclesAllowed() )
	{
		self IPrintLnBold( &"KILLSTREAKS_TOO_MANY_VEHICLES" );
		return false;
	}		
	else if( IsDefined( self.ballDrone ) )
	{
		self IPrintLnBold( &"KILLSTREAKS_COMPANION_ALREADY_EXISTS" );
		return false;
	}

	// increment the faux vehicle count before we spawn the vehicle so no other vehicles try to spawn
	incrementFauxVehicleCount();

	ballDrone = createBallDrone( ballDroneType );
	if( !IsDefined( ballDrone ) )
	{
		// decrement the faux vehicle count since this failed to spawn
		decrementFauxVehicleCount();

		return false;	
	}

	self.ballDrone = ballDrone;
	self thread startBallDrone( ballDrone );

	//level thread teamPlayerCardSplash( level.ballDroneSettings[ ballDroneType ].teamSplash, self, self.team );

	return true;
}

createBallDrone( ballDroneType ) // self == player
{
	// Node way
	//closestStartNode = ballDrone_getClosestNode( self.origin );	
	//if( IsDefined( closestStartNode.angles ) )
	//	startAng = closestStartNode.angles;
	//else
	//	startAng = ( 0, 0, 0);

	//closestNode = ballDrone_getClosestNode( self.origin );

	//forward = AnglesToForward( self.angles );
	//targetPos = closestNode.origin;

	//startPos = closestStartNode.origin;

	// new way
	startAng = self.angles;
	forward = AnglesToForward( self.angles );
	startPos = self.origin + ( forward * 100 ) + Z_OFFSET;
	playerStartPos = self.origin + Z_OFFSET;
	trace = BulletTrace( playerStartPos, startPos, false );
	// make sure we aren't starting in geo
	attempts = 3;
	while( trace[ "surfacetype" ] != "none" && attempts > 0 )
	{
		startPos = self.origin + ( VectorNormalize( playerStartPos - trace[ "position" ] ) * 5 );
		trace = BulletTrace( playerStartPos, startPos, false );
		attempts--;
		wait( 0.05 );
	}
	if( attempts <= 0 )
		return;
	
	right = AnglesToRight( self.angles );
	targetPos = self.origin + ( right * 20 ) + Z_OFFSET;
	trace = BulletTrace( startPos, targetPos, false );
	// make sure we aren't sending it into geo
	attempts = 3;
	while( trace[ "surfacetype" ] != "none" && attempts > 0 )
	{
		targetPos = startPos + ( VectorNormalize( startPos - trace[ "position" ] ) * 5 );
		trace = BulletTrace( startPos, targetPos, false );
		attempts--;
		wait( 0.05 );
	}
	if( attempts <= 0 )
		return;
	
	drone = SpawnHelicopter( self, startPos, startAng, level.ballDroneSettings[ ballDroneType ].vehicleInfo, level.ballDroneSettings[ ballDroneType ].modelBase );
	if( !IsDefined( drone ) )
		return;

	drone MakeVehicleNotCollideWithPlayers( true );
	
	drone addToBallDroneList();
	drone thread removeFromBallDroneListOnDeath();

	drone.health = level.ballDroneSettings[ ballDroneType ].health;
	drone.maxHealth = level.ballDroneSettings[ ballDroneType ].maxHealth;
	drone.damageTaken = 0; // how much damage has it taken

	drone.speed = 140;
	drone.followSpeed = 140;
	drone.owner = self;
	drone.team = self.team;
	drone Vehicle_SetSpeed( drone.speed, 16, 16 );
	drone SetYawSpeed( 120, 90 );
	drone SetNearGoalNotifyDist( 16 );
	drone.ballDroneType = ballDroneType;
	drone SetHoverParams( 30, 10, 5 );
	
	if( level.teamBased )
		drone maps\mp\_entityheadicons::setTeamHeadIcon( drone.team, ( 0, 0, 25 ) );
	else
		drone maps\mp\_entityheadicons::setPlayerHeadIcon( drone.owner, ( 0, 0, 25 ) );
	
	// for special settings on different types of drones
	maxPitch = 45;
	maxRoll = 45;
	switch( ballDroneType )
	{
	case "ball_drone_radar":
		maxPitch = 90;
		maxRoll = 90;
		
		radar = Spawn( "script_model", self.origin );
		radar.team = self.team;
		radar MakePortableRadar( self );
		drone.radar = radar;
		drone thread radarMover();
		drone.ammo = 99999; // trophy "ammo" for how many things it can shot down before dying
		drone thread maps\mp\gametypes\_equipment::trophyActive( self );
		break;

	case "ball_drone_backup":
		turret = SpawnTurret( "misc_turret", drone GetTagOrigin( level.ballDroneSettings[ ballDroneType ].weaponTag ), level.ballDroneSettings[ ballDroneType ].weaponInfo );
		turret LinkTo( drone, level.ballDroneSettings[ ballDroneType ].weaponTag, ( 0, 0, -8 ), ( 0, 0, 0 ) );
		turret SetModel( level.ballDroneSettings[ ballDroneType ].weaponModel );
		turret.angles = drone.angles;
		turret.owner = drone.owner;
		turret.team = self.team;
		turret MakeTurretInoperable();
		turret MakeUnusable();
		turret.vehicle = drone;	
		
		// when the turret is idle it needs to look at something behind the player
		idleTargetPos = self.origin + ( forward * -100 ) + ( 0, 0, 40 ); 
		turret.idleTarget = Spawn( "script_origin", idleTargetPos );
		turret.idleTarget.targetname = "test";
		self thread idleTargetMover( turret.idleTarget );

		if( level.teamBased )
			turret SetTurretTeam( self.team );
		turret SetMode( level.ballDroneSettings[ ballDroneType ].sentryMode );
		turret SetSentryOwner( self );
		turret SetLeftArc( 180 );
		turret SetRightArc( 180 );
		turret SetBottomArc( 50 );
		turret thread ballDrone_attackTargets();

		killCamOrigin = ( drone.origin + ( ( AnglesToForward( drone.angles ) * -10 ) + ( AnglesToRight( drone.angles ) * -10 )  ) ) + ( 0, 0, 10 );
		turret.killCamEnt = Spawn( "script_model", killCamOrigin );
		turret.killCamEnt SetScriptMoverKillCam( "explosive" );
		turret.killCamEnt LinkTo( drone );
		//turret.killCamEnt LinkTo( drone, "tag_origin" );

		drone.turret = turret; 

		// this is for using the vehicle's turret
		//drone SetVehWeapon( level.ballDroneSettings[ ballDroneType ].weaponInfo );
		//drone thread ballDrone_targeting();
		//drone thread ballDrone_attackTargets();
		break;

	case "ball_drone_3dping":
		maxPitch = 90;
		maxRoll = 90;
		
		drone thread watch3DPing();
		break;

	default:
		break;
	}

	drone SetMaxPitchRoll( maxPitch, maxRoll );	

	drone.targetPos = targetPos;
	//drone.currentNode = closestNode;

	drone.attract_strength = 10000;
	drone.attract_range = 150;
	drone.attractor = Missile_CreateAttractorEnt( drone, drone.attract_strength, drone.attract_range );

	drone.hasDodged = false;
	drone.stunned = false;
	drone.inactive = false;

	drone thread ballDrone_handleDamage();
	drone thread ballDrone_watchDeath();
	drone thread ballDrone_watchTimeout();
	drone thread ballDrone_watchOwnerLoss();
	drone thread ballDrone_watchOwnerDeath();
	drone thread ballDrone_watchRoundEnd();
	drone thread ballDrone_enemy_lightFX();
	drone thread ballDrone_friendly_lightFX();

	drone.owner maps\mp\_matchdata::logKillstreakEvent( level.ballDroneSettings[ drone.ballDroneType ].streakName, drone.targetPos );	

	return drone;
}

idleTargetMover( ent ) // self == player
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	ent endon( "death" );

	// keep the idleTarget entity behind the player so the turret is always default looking back there
	forward = AnglesToForward( self.angles );
	while( true )
	{
		if( isReallyAlive( self ) && !self isUsingRemote() && AnglesToForward( self.angles ) != forward )
		{
			forward = AnglesToForward( self.angles );
			pos = self.origin + ( forward * -100 ) + ( 0, 0, 40 ); 
			ent MoveTo( pos, 0.5 );
		}
		wait( 0.5 );
	}
}

ballDrone_enemy_lightFX() // self == drone
{
	// non-looping fx

	self endon( "death" );

	while ( true )
	{
		foreach( player in level.players )
		{
			if( IsDefined( player ) && player.team != self.team )
			{
				PlayFXOnTagForClients( level.ballDroneSettings[ self.ballDroneType ].fxId_enemy_light1, self, "tag_fx", player );
				PlayFXOnTagForClients( level.ballDroneSettings[ self.ballDroneType ].fxId_enemy_light2, self, "tag_fx1", player );
				PlayFXOnTagForClients( level.ballDroneSettings[ self.ballDroneType ].fxId_enemy_light3, self, "tag_fx2", player );
				PlayFXOnTagForClients( level.ballDroneSettings[ self.ballDroneType ].fxId_enemy_light4, self, "tag_fx3", player );
			}
		}

		wait( 1.0 );
	}
}

ballDrone_friendly_lightFX() // self == drone
{
	// looping fx

	self endon( "death" );

	foreach( player in level.players )
	{
		if( IsDefined( player ) && player.team == self.team )
		{
			PlayFXOnTagForClients( level.ballDroneSettings[ self.ballDroneType ].fxId_friendly_light1, self, "tag_fx", player );
			PlayFXOnTagForClients( level.ballDroneSettings[ self.ballDroneType ].fxId_friendly_light2, self, "tag_fx1", player );
			PlayFXOnTagForClients( level.ballDroneSettings[ self.ballDroneType ].fxId_friendly_light3, self, "tag_fx2", player );
			PlayFXOnTagForClients( level.ballDroneSettings[ self.ballDroneType ].fxId_friendly_light4, self, "tag_fx3", player );
		}
	}

	self thread watchConnectedPlayFX();
	self thread watchJoinedTeamPlayFX();
}

watchConnectedPlayFX() // self == drone
{
	self endon( "death" );

	// play fx for late comers
	while( true )
	{
		level waittill( "connected", player );
		player waittill( "spawned_player" );

		if( IsDefined( player ) && player.team == self.team )
		{
			PlayFXOnTagForClients( level.ballDroneSettings[ self.ballDroneType ].fxId_friendly_light1, self, "tag_fx", player );
			PlayFXOnTagForClients( level.ballDroneSettings[ self.ballDroneType ].fxId_friendly_light2, self, "tag_fx1", player );
			PlayFXOnTagForClients( level.ballDroneSettings[ self.ballDroneType ].fxId_friendly_light3, self, "tag_fx2", player );
			PlayFXOnTagForClients( level.ballDroneSettings[ self.ballDroneType ].fxId_friendly_light4, self, "tag_fx3", player );
		}
	}
}

watchJoinedTeamPlayFX() // self == drone
{
	self endon( "death" );

	// play fx for team changers
	while( true )
	{
		level waittill( "joined_team", player );
		player waittill( "spawned_player" );

		if( IsDefined( player ) && player.team == self.team )
		{
			PlayFXOnTagForClients( level.ballDroneSettings[ self.ballDroneType ].fxId_friendly_light1, self, "tag_fx", player );
			PlayFXOnTagForClients( level.ballDroneSettings[ self.ballDroneType ].fxId_friendly_light2, self, "tag_fx1", player );
			PlayFXOnTagForClients( level.ballDroneSettings[ self.ballDroneType ].fxId_friendly_light3, self, "tag_fx2", player );
			PlayFXOnTagForClients( level.ballDroneSettings[ self.ballDroneType ].fxId_friendly_light4, self, "tag_fx3", player );
		}
	}
}

startBallDrone( ballDrone ) // self == player
{			
	level endon( "game_ended" );
	ballDrone endon( "death" );

	switch( ballDrone.ballDroneType )
	{
	case "ball_drone_backup":
		// watch the player's back
		if( IsDefined( ballDrone.turret ) && IsDefined( ballDrone.turret.idleTarget ) )
			ballDrone SetLookAtEnt( ballDrone.turret.idleTarget );
		else
			ballDrone SetLookAtEnt( self );
		break;

	default:
		// look at the player
		ballDrone SetLookAtEnt( self );
		break;
	}

	//	go to pos
	targetOffset	= (0, 0, BALL_DRONE_STAND_UP_OFFSET);
	ballDrone SetDroneGoalPos( self, targetOffset );
	ballDrone waittill( "near_goal" );
	ballDrone Vehicle_SetSpeed( ballDrone.speed, 10, 10 );	
	ballDrone waittill( "goal" );	

	//	begin following player	
	ballDrone thread ballDrone_followPlayer();
}

ballDrone_followPlayer() // self == drone
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "leaving" );

	if( !IsDefined( self.owner ) )
	{
		self thread ballDrone_leave();
		return;
	}

	self.owner endon( "disconnect" );	
	self endon( "owner_gone" );

	self Vehicle_SetSpeed( self.followSpeed, 10, 10 );
	previousOrigin = ( 0, 0, 0 );
	destRadiusSq = 64 * 64;
	
	while( true )
	{
		if( IsDefined( self.owner ) && IsAlive( self.owner ) )
		{
			// check to see if the player has moved
			//	make sure the turret isn't currently trying to shoot anyone
			//	check if player is still within a radius
			if( self.owner.origin != previousOrigin &&
			   	DistanceSquared( self.owner.origin, previousOrigin ) > destRadiusSq )
			{
				if( self.ballDroneType == "ball_drone_backup" )
				{
					if( !IsDefined( self.turret GetTurretTarget( false ) ) )
					{
						previousOrigin = self.owner.origin;
						ballDrone_moveToPlayer();
						continue;
					}
				}
				else
				{
					previousOrigin = self.owner.origin;
					ballDrone_moveToPlayer();
					continue;
				}
			}
		}
		wait( 1 );
	}
}

ballDrone_moveToPlayer() // self == drone
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "leaving" );
	self.owner endon( "death" );
	self.owner endon( "disconnect" );
	self endon( "owner_gone" );

	self notify( "ballDrone_moveToPlayer" );
	self endon( "ballDrone_moveToPlayer" );

	
	// collect the ideal offsets from the player
	backOffset = BALL_DRONE_BACK_OFFSET;
	
	sideOffset = BALL_DRONE_SIDE_OFFSET;
	
	heightOffset = BALL_DRONE_STAND_UP_OFFSET;
	switch( self.owner getStance() )
	{
		case "stand":
			heightOffset = BALL_DRONE_STAND_UP_OFFSET;
			break;
		case "crouch":
			heightOffset = BALL_DRONE_CROUCH_UP_OFFSET;
			break;
		case "prone":
			heightOffset = BALL_DRONE_PRONE_UP_OFFSET;
			break;
	}
	
	targetOffset	= (sideOffset, backOffset, heightOffset);
	
/#
	if( GetDvarInt( "scr_balldrone_debug_position" ) )
	{
		targetOffset = (0, -1*GetDvarFloat( "scr_balldrone_debug_position_forward" ), GetDvarFloat( "scr_balldrone_debug_position_height" ) );
	}
#/

	// ask code to navigate us as close as possible to the offset from the owner, set us as in-transit and start a thread waiting for us to get to the goal
	self SetDroneGoalPos( self.owner, targetOffset );
	self.inTransit = true;
	self thread ballDrone_watchForGoal();
}

/#
debugDrawDronePath()
{
	self endon( "death" );
	self endon( "hit_goal" );
	
	self notify( "debugDrawDronePath" );
	self endon( "debugDrawDronePath" );
	
	while( true )
	{
		nodePath = GetNodesOnPath( self.owner.origin, self.origin );
		if( IsDefined( nodePath ) )
		{
			for( i = 0; i < nodePath.size; i++ )
			{
				if( IsDefined( nodePath[ i + 1 ] ) )
				   Line( nodePath[ i ].origin + Z_OFFSET, nodePath[ i + 1 ].origin + Z_OFFSET, ( 1, 0, 0 ) );
			}
		}
		wait( 0.05 );
	}
}
#/
	
ballDrone_watchForGoal() // self == drone
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "leaving" );
	self.owner endon( "death" );
	self.owner endon( "disconnect" );
	self endon( "owner_gone" );
	
	self notify( "ballDrone_watchForGoal" );
	self endon( "ballDrone_watchForGoal" );

	result = self waittill_any_return( "goal", "near_goal", "hit_goal" );
	self.inTransit = false;
	self.inactive = false;
	self notify( "hit_goal" );		
}

radarMover() // self == drone
{
	level endon("game_ended");
	self endon( "death" );

	while( true )
	{
		if( IsDefined( self.stunned ) && self.stunned )
		{
			wait( 0.5 );
			continue;
		}
		if( IsDefined( self.inactive ) && self.inactive )
		{
			wait( 0.5 );
			continue;
		}

		if( IsDefined( self.radar ) )
			self.radar MoveTo( self.origin, 0.5 );
			
		wait( 0.5 );
	}
}

watch3DPing() // self == drone
{
	self endon( "death" );
	level endon( "game_ended" );

	// every N seconds do a ping of the world and show enemies in red
	pingTime = level.ballDroneSettings[ self.ballDroneType ].pingTime;

	while( true )
	{
		if( IsDefined( self.stunned ) && self.stunned )
		{
			wait( 0.5 );
			continue;
		}
		if( IsDefined( self.inactive ) && self.inactive )
		{
			wait( 0.5 );
			continue;
		}

		//PrintLn( "watch3DPing: GetTime() " + GetTime() + " PingTime " + pingTime );
		PlayFX( level.ballDroneSettings[ self.ballDroneType ].fxId_ping, self.origin );
		
		if( IsDefined( self.owner ) )
		{
			self PlaySoundToPlayer( level.ballDroneSettings[ self.ballDroneType ].sound_ping, self.owner );
		}

		// highlight all enemies in the world that can't be seen
		foreach( player in level.players )
		{
			if( !isReallyAlive( player ) )
				continue;

			if( player.team == self.team )
				continue;

			modelHighlight = Spawn( "script_model", player.origin );
			modelHighlight.angles = player.angles;
			modelHighlight SetContents( 0 );
			modelHighlight Hide();
			
			if( !SightTracePassed( self.owner GetEye(), player GetEye(), false, self.owner, player ) )
				modelHighlight ShowToPlayer( self.owner );

			stance = player GetStance();
			switch( stance )
			{
			case "stand":
				modelHighlight SetModel( level.ballDroneSettings[ self.ballDroneType ].modelHighlightS );
				break;
			case "crouch":
				modelHighlight SetModel( level.ballDroneSettings[ self.ballDroneType ].modelHighlightC );
				break;
			case "prone":
				modelHighlight SetModel( level.ballDroneSettings[ self.ballDroneType ].modelHighlightP );
				break;
			}

			fadeTime = level.ballDroneSettings[ self.ballDroneType ].highlightFadeTime;
/#
			fadeTime = GetDvarFloat( "scr_balldrone_3dping_highlightFadeTime" );
#/
			modelHighlight thread fadeHighlightOverTime( fadeTime );
		}

/#
		pingTime = GetDvarFloat( "scr_balldrone_3dping_pingTime" );
		// host migration wipes out this dvar for some reason and causes the loop to continue when it shouldn't
		if( pingTime < 1 )
			pingTime = level.ballDroneSettings[ self.ballDroneType ].pingTime;
#/
		waitLongDurationWithHostMigrationPause( pingTime );
	}
}

fadeHighlightOverTime( time ) // self == highlight (model for now)
{
	self endon( "death" );

	wait( time );
	self delete();
}

/* ============================
State Trackers
============================ */

ballDrone_watchDeath() // self == drone
{
	level endon( "game_ended" );
	self endon( "gone" );

	self waittill( "death" );

	self thread ballDroneDestroyed();
}


ballDrone_watchTimeout() // self == drone
{
	level endon ( "game_ended" );
	self endon( "death" );
	self.owner endon( "disconnect" );
	self endon( "owner_gone" );

	timeout = level.ballDroneSettings[ self.ballDroneType ].timeOut;
/#
	timeout = GetDvarFloat( "scr_balldrone_timeout" );
#/
	maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( timeout );

	self thread ballDrone_leave();
}


ballDrone_watchOwnerLoss() // self == drone
{
	level endon ( "game_ended" );
	self endon( "death" );
	self endon( "leaving" );

	self.owner waittill( "killstreak_disowned" );	

	self notify( "owner_gone" );
	//	leave
	self thread ballDrone_leave();
}

ballDrone_watchOwnerDeath() // self == drone
{
	level endon ( "game_ended" );
	self endon( "death" );
	self endon( "leaving" );

	while( true )
	{
		self.owner waittill( "death" );	

		if( getGametypeNumLives() && self.owner.pers[ "deaths" ] == getGametypeNumLives() )
			self thread ballDrone_leave();
//		else
//			self.inactive = true;
	}
}

ballDrone_watchRoundEnd() // self == drone
{
	self endon( "death" );
	self endon( "leaving" );	
	self.owner endon( "disconnect" );
	self endon( "owner_gone" );

	level waittill_any( "round_end_finished", "game_ended" );

	//	leave
	self thread ballDrone_leave();
}

ballDrone_leave() // self == drone
{
	self endon( "death" );
	self notify( "leaving" );

	ballDroneExplode();
}

/* ============================
End State Trackers
============================ */

/* ============================
Damage and Death Monitors
============================ */

ballDrone_handleDamage() // self == drone
{
	self endon( "death" );
	level endon( "game_ended" );

	self SetCanDamage( true );

	while( true )
	{
		self waittill( "damage", damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon );

		// don't allow people to destroy things on their team ifFF is off
		if( !maps\mp\gametypes\_weapons::friendlyFireCheck( self.owner, attacker ) )
			continue;

		if( !IsDefined( self ) )
			return;

		if( IsDefined( iDFlags ) && ( iDFlags & level.iDFLAGS_PENETRATION ) )
			self.wasDamagedFromBulletPenetration = true;

		self.wasDamaged = true;

		modifiedDamage = damage;

		if( IsPlayer( attacker ) )
		{					
			attacker maps\mp\gametypes\_damagefeedback::updateDamageFeedback( "ball_drone" );

			if( meansOfDeath == "MOD_RIFLE_BULLET" || meansOfDeath == "MOD_PISTOL_BULLET" )
			{
				if( attacker _hasPerk( "specialty_armorpiercing" ) )
					modifiedDamage += damage * level.armorPiercingMod;
			}
		}

		// in case we are shooting from a remote position, like being in the osprey gunner shooting this
		if( IsDefined( attacker.owner ) && IsPlayer( attacker.owner ) )
		{
			attacker.owner maps\mp\gametypes\_damagefeedback::updateDamageFeedback( "ball_drone" );
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
			case "sam_projectile_mp":
				self.largeProjectileDamage = true;
				modifiedDamage = self.maxHealth + 1;
				break;

			case "emp_grenade_mp":
				modifiedDamage = self.maxHealth + 1;
			case "flash_grenade_mp":
			case "concussion_grenade_mp":
				self thread ballDrone_stunned();
				break;

			case "osprey_player_minigun_mp":
				self.largeProjectileDamage = false;
				modifiedDamage *= 2; // since it's a larger caliber, make it hurt
				break;
			}

			maps\mp\killstreaks\_killstreaks::killstreakHit( attacker, weapon, self );
		}

		self.damageTaken += modifiedDamage;		

		if( self.damageTaken >= self.maxHealth )
		{
			if( IsPlayer( attacker ) && ( !IsDefined( self.owner ) || attacker != self.owner ) )
			{
				//attacker notify( "destroyed_helicopter" );
				attacker notify( "destroyed_killstreak", weapon );
				attacker thread maps\mp\gametypes\_rank::giveRankXP( "kill", 300, weapon, meansOfDeath );			
				attacker thread maps\mp\gametypes\_rank::xpEventPopup( &"SPLASHES_DESTROYED_BALL_DRONE" );
				//thread maps\mp\gametypes\_missions::vehicleKilled( self.owner, self, undefined, attacker, damage, meansOfDeath, weapon );		
			}

			if( IsDefined( self.owner ) )
				self.owner thread leaderDialogOnPlayer( level.ballDroneSettings[ self.ballDroneType ].voDestroyed, undefined, undefined, self.origin );

			self notify ( "death" );
			return;
		}
	}
}

ballDrone_stunned() // self == drone
{
	self notify( "ballDrone_stunned" );
	self endon( "ballDrone_stunned" );

	self endon( "death" );
	self.owner endon( "disconnect" );
	level endon( "game_ended" );

	self.stunned = true;
	
	if( IsDefined( level.ballDroneSettings[ self.ballDroneType ].fxId_sparks ) )
	{
		PlayFXOnTag( level.ballDroneSettings[ self.ballDroneType ].fxId_sparks, self, "tag_origin" );
	}

	// for the portable radar we need to destroy it and recreate it
	if( self.ballDroneType == "ball_drone_radar" )
	{
		if( IsDefined( self.radar ) )
			self.radar delete();
	}

	wait( STUNNED_TIME );

	self.stunned = false;

	if( self.ballDroneType == "ball_drone_radar" )
	{
		radar = Spawn( "script_model", self.origin );
		radar.team = self.team;
		radar MakePortableRadar( self.owner );
		self.radar = radar;
	}
}

ballDroneDestroyed() // self == drone
{
	if( !IsDefined( self ) )
		return;
	
	// TODO: could put some drama here as it crashes

	ballDroneExplode();
}

ballDroneExplode() // self == drone
{
	// TODO: get explosion fx and sound for this
	//forward = ( self.origin + ( 0, 0, 1 ) ) - self.origin;

	//deathAngles = self getTagAngles( "tag_deathfx" );
	if( IsDefined( level.ballDroneSettings[ self.ballDroneType ].fxId_explode ) )
	{
		PlayFX( level.ballDroneSettings[ self.ballDroneType ].fxId_explode, self.origin );
	}

	if( IsDefined( level.ballDroneSettings[ self.ballDroneType ].sound_explode ) )
	{
		self PlaySound( level.ballDroneSettings[ self.ballDroneType ].sound_explode );
	}

	self notify( "explode" );

	self removeBallDrone();
}

removeBallDrone() // self == drone
{	
	// decrement the faux vehicle count right before it is deleted this way we know for sure it is gone
	decrementFauxVehicleCount();

	if( IsDefined( self.radar ) )
		self.radar delete();

	if( IsDefined( self.turret ) )
	{
		if( IsDefined( self.turret.idleTarget ) )
			self.turret.idleTarget delete();

		if( IsDefined( self.turret.killCamEnt ) )
			self.turret.killCamEnt delete();

		self.turret delete();
	}

	if( IsDefined( self.owner ) && IsDefined( self.owner.ballDrone ) )
		self.owner.ballDrone = undefined;

	self delete();	
}

/* ============================
End Damage and Death Monitors
============================ */

/* ============================
List and Count Management
============================ */

addToBallDroneList()
{
	level.ballDrones[ self GetEntityNumber() ] = self;	
}

removeFromBallDroneListOnDeath()
{
	entNum = self GetEntityNumber();

	self waittill ( "death" );

	level.ballDrones[ entNum ] = undefined;
}

exceededMaxBallDrones( streakName )
{
	if( level.ballDrones.size >= maxVehiclesAllowed() )
		return true;	
	else
		return false;	
}

/* ============================
End List and Count Management
============================ */

/* ============================
Turret Logic Functions
============================ */

ballDrone_attackTargets() // self == turret
{
	self.vehicle endon( "death" );
	level endon( "game_ended" );

	while( true )
	{
		self waittill( "turretstatechange" );

		if( self IsFiringTurret() && 
			( IsDefined( self.vehicle.stunned ) && !self.vehicle.stunned ) &&
			( IsDefined( self.vehicle.inactive ) && !self.vehicle.inactive ) )
		{
			self LaserOn();
			self thread ballDrone_burstFireStart();
		}
		else
		{
			self LaserOff();
			self thread ballDrone_burstFireStop();
		}
	}
}

ballDrone_burstFireStart() // self == turret
{
	self.vehicle endon( "death" );
	self endon( "stop_shooting" );
	level endon( "game_ended" );

	vehicle = self.vehicle;
	
	fireTime = WeaponFireTime( level.ballDroneSettings[ vehicle.ballDroneType ].weaponInfo );
	minShots = level.ballDroneSettings[ vehicle.ballDroneType ].burstMin;
	maxShots = level.ballDroneSettings[ vehicle.ballDroneType ].burstMax;
	minPause = level.ballDroneSettings[ vehicle.ballDroneType ].pauseMin;
	maxPause = level.ballDroneSettings[ vehicle.ballDroneType ].pauseMax;
	lockOnTime = level.ballDroneSettings[ vehicle.ballDroneType ].lockonTime;

	while( true )
	{		
		numShots = RandomIntRange( minShots, maxShots + 1 );

		self doLockOn( lockOnTime );
		
		for( i = 0; i < numShots; i++ )
		{			
			// don't shoot when inactive
			if( IsDefined( vehicle.inactive ) && vehicle.inactive )
				break;

			targetEnt = self GetTurretTarget( false );
			if( IsDefined( targetEnt ) && canBeTargeted( targetEnt ) )
			{
				vehicle SetLookAtEnt( targetEnt );
				//self PlaySound( level.ballDroneSettings[ vehicle.ballDroneType ].sound_weapon );
				self ShootTurret();
				//MagicBullet( level.ballDroneSettings[ vehicle.ballDroneType ].projectileInfo, self GetTagOrigin( "tag_flash" ), targetEnt.origin, self.owner );
			}

			wait( fireTime );
		}

		wait( RandomFloatRange( minPause, maxPause ) );
	}
}

doLockOn( time ) // self == turret
{
	// lock-on time
	while( time > 0 )
	{
		self PlaySoundToPlayer( level.ballDroneSettings[ self.vehicle.ballDroneType ].sound_targeting, self.vehicle.owner );

		wait( 0.5 );
		time -= 0.5;
	}

	// locked on
	self PlaySoundToPlayer( level.ballDroneSettings[ self.vehicle.ballDroneType ].sound_lockon, self.vehicle.owner );
}

ballDrone_burstFireStop() // self == turret
{
	self notify( "stop_shooting" );
	if( IsDefined( self.idleTarget ) )
		self.vehicle SetLookAtEnt( self.idleTarget );
}

canBeTargeted( ent ) // self == turret
{
	canTarget = true;

	if( IsPlayer( ent ) )
	{
		if( !isReallyAlive( ent ) || ent.sessionstate != "playing" )
			return false;
	}

	if( level.teamBased && IsDefined( ent.team ) && ent.team == self.team )
		return false;

	if( IsDefined( ent.team ) && ent.team == "spectator" )
		return false;

	if( IsPlayer( ent ) && ent == self.owner )
		return false;

	if( IsPlayer( ent ) && IsDefined( ent.spawntime ) && ( GetTime() - ent.spawntime ) / 1000 <= 5 )
		return false;

	if( IsPlayer( ent ) && ent _hasPerk( "specialty_blindeye" ) )
		return false;

	if( DistanceSquared( ent.origin, self.origin ) > level.ballDroneSettings[ self.vehicle.ballDroneType ].visual_range_sq )
		return false;

	turret_point = self GetTagOrigin( "tag_flash" );

	return canTarget;
}
