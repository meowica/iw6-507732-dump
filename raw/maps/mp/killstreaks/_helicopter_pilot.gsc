#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;

init()
{
	level.killstreakFuncs[ "heli_pilot" ] = ::tryUseHeliPilot;
	
	level.heli_pilot = [];	
	
	level.heliPilotSettings = [];	

	level.heliPilotSettings[ "heli_pilot" ] = SpawnStruct();
	level.heliPilotSettings[ "heli_pilot" ].timeOut =				60.0;	
	level.heliPilotSettings[ "heli_pilot" ].health =				999999; // keep it from dying anywhere in code	
	level.heliPilotSettings[ "heli_pilot" ].maxHealth =				2000; // this is what we check against for death	
	level.heliPilotSettings[ "heli_pilot" ].streakName =			"heli_pilot";
	level.heliPilotSettings[ "heli_pilot" ].vehicleInfo =			"heli_pilot_mp";
	level.heliPilotSettings[ "heli_pilot" ].modelBase =				level.littlebird_model;
	level.heliPilotSettings[ "heli_pilot" ].teamSplash =			"used_heli_pilot";	

	heliPilot_setAirStartNodes();
	
	// throw the mesh way up into the air, the gdt entry for the vehicle must match
	level.heli_pilot_mesh = GetEnt( "heli_pilot_mesh", "targetname" );
	if( !IsDefined( level.heli_pilot_mesh ) )
		PrintLn( "heli_pilot_mesh doesn't exist in this level: " + level.script );
	else
		level.heli_pilot_mesh.origin += getHeliPilotMeshOffset();
	
/#
	SetDevDvarIfUninitialized( "scr_helipilot_timeout", 60.0 );
#/
}

tryUseHeliPilot( lifeId )
{
	heliPilotType = "heli_pilot";
	
	numIncomingVehicles = 1;
	
	if( exceededMaxHeliPilots( self.team ) )
	{
		self IPrintLnBold( &"KILLSTREAKS_AIR_SPACE_TOO_CROWDED" );
		return false;
	}
	else if( currentActiveVehicleCount() >= maxVehiclesAllowed() || level.fauxVehicleCount + numIncomingVehicles >= maxVehiclesAllowed() )
	{
		self IPrintLnBold( &"KILLSTREAKS_TOO_MANY_VEHICLES" );
		return false;
	}
	
	// increment the faux vehicle count before we spawn the vehicle so no other vehicles try to spawn
	incrementFauxVehicleCount();
	
	heli = createHeliPilot( heliPilotType );
	
	if( !IsDefined( heli ) )
	{
		// decrement the faux vehicle count since this failed to spawn
		decrementFauxVehicleCount();

		return false;	
	}

	level.heli_pilot[ self.team ] = heli;
	
	self thread startHeliPilot( heli );
	
	level thread teamPlayerCardSplash( level.heliPilotSettings[ heliPilotType ].teamSplash, self, self.team );

	return true;
}

exceededMaxHeliPilots( team )
{
	if ( level.gameType == "dm" )
	{
		if ( IsDefined( level.heli_pilot[ team ] ) || IsDefined( level.heli_pilot[ level.otherTeam[ team ] ] ) )
			return true;
		else
			return false;
	}
	else
	{
		if ( IsDefined( level.heli_pilot[ team ] ) )
			return true;
		else
			return false;
	}
}

createHeliPilot( heliPilotType )
{
	closestStartNode = heliPilot_getClosestStartNode( self.origin );		
	closestNode = heliPilot_getLinkedStruct( closestStartNode );
	startAng = VectorToAngles( closestNode.origin - closestStartNode.origin );
	
	forward = AnglesToForward( self.angles );
	targetPos = closestNode.origin + ( forward * -100 );
	
	startPos = closestStartNode.origin;
	
	heli = SpawnHelicopter( self, startPos, startAng, level.heliPilotSettings[ heliPilotType ].vehicleInfo, level.heliPilotSettings[ heliPilotType ].modelBase );
	if( !IsDefined( heli ) )
		return;

	// radius and offset should match vehHelicopterBoundsRadius (GDT) and bg_vehicle_sphere_bounds_offset_z.
	heli MakeVehicleSolidCapsule( 18, -9, 18 ); 
	
	heli maps\mp\killstreaks\_helicopter::addToLittleBirdList();
	heli thread maps\mp\killstreaks\_helicopter::removeFromLittleBirdListOnDeath();

	heli.health = level.heliPilotSettings[ heliPilotType ].health;
	heli.maxHealth = level.heliPilotSettings[ heliPilotType ].maxHealth;
	heli.damageTaken = 0; // how much damage has it taken

	heli.speed = 40;
	heli.owner = self;
	heli SetOtherEnt(self);
	heli.team = self.team;
	heli.heliType = "littlebird";
	heli.heliPilotType = "heli_pilot";
	heli SetMaxPitchRoll( 45, 45 );	
	heli Vehicle_SetSpeed( heli.speed, 40, 40 );
	heli SetYawSpeed( 120, 60 );
	heli SetNearGoalNotifyDist( 32 );
	heli SetHoverParams( 100, 100, 100 );
	heli make_entity_sentient_mp( heli.team );

	heli.targetPos = targetPos;
	heli.currentNode = closestNode;
			
	heli.attract_strength = 10000;
	heli.attract_range = 150;
	heli.attractor = Missile_CreateAttractorEnt( heli, heli.attract_strength, heli.attract_range );

	heli thread heliPilot_handleDamage(); // since the model is what players will be shooting at, it should handle the damage
	heli thread heliPilot_lightFX();
	heli thread heliPilot_watchDeath();
	heli thread heliPilot_watchTimeout();
	heli thread heliPilot_watchOwnerLoss();
	heli thread heliPilot_watchRoundEnd();

	heli.owner maps\mp\_matchdata::logKillstreakEvent( level.heliPilotSettings[ heli.heliPilotType ].streakName, heli.targetPos );	
	
	return heli;
}

heliPilot_lightFX()
{
	PlayFXOnTag( level.chopper_fx["light"]["left"], self, "tag_light_nose" );
	wait ( 0.05 );
	PlayFXOnTag( level.chopper_fx["light"]["belly"], self, "tag_light_belly" );
	wait ( 0.05 );
	PlayFXOnTag( level.chopper_fx["light"]["tail"], self, "tag_light_tail1" );
	wait ( 0.05 );
	PlayFXOnTag( level.chopper_fx["light"]["tail"], self, "tag_light_tail2" );
}

startHeliPilot( heli )
{
	level endon( "game_ended" );
	heli endon( "death" );

	self setUsingRemote( heli.heliPilotType );

	if( GetDvarInt( "camera_thirdPerson" ) )
		self setThirdPersonDOF( false );

	self.restoreAngles = self.angles;
	
	self thread watchIntroCleared();

	self freezeControlsWrapper( true );
	result = self maps\mp\killstreaks\_killstreaks::initRideKillstreak( heli.heliPilotType );
	if( result != "success" )
	{
		if ( result != "disconnect" )
			self clearUsingRemote();

		if( IsDefined( self.disabledWeapon ) && self.disabledWeapon )
			self _enableWeapon();
		self notify( "death" );

		return false;
	}	
	
	maps\mp\killstreaks\_juggernaut::disableJuggernaut();
	
	self freezeControlsWrapper( false );
	/*
	// need to link the player here but not give control yet
	self CameraLinkTo( heli, "tag_player" );
	
	//	go to pos
	heli SetVehGoalPos( heli.targetPos );	
	heli waittill( "near_goal" );
	heli Vehicle_SetSpeed( heli.speed, 60, 30 );	
	heli waittill( "goal" );
	*/

	
	// make sure we go to the mesh as we enter the map
	traceOffset = ( 0, 0, 2500 );
	traceStart = ( heli.currentNode.origin ) + ( getHeliPilotMeshOffset() + traceOffset );
	traceEnd = ( heli.currentNode.origin ) + ( getHeliPilotMeshOffset() - traceOffset );
	traceResult = BulletTrace( traceStart, traceEnd, false, undefined, false, false, true );
	if( !IsDefined( traceResult["entity"] ) )
	{
/#
		// draw where it thinks this is breaking down
		self thread drawSphere( traceResult[ "position" ] - getHeliPilotMeshOffset(), 32, 10000, ( 1, 0, 0 ) );
		self thread drawSphere( heli.currentNode.origin, 16, 10000, ( 0, 1, 0 ) );
		self thread drawLine( traceStart - getHeliPilotMeshOffset(), traceEnd - getHeliPilotMeshOffset(), 10000, ( 0, 0, 1 ) );
#/
		AssertMsg( "The trace didn't hit the heli_pilot_mesh. Please grab an MP scripter." );
	}
	
	targetOrigin = ( traceResult[ "position" ] - getHeliPilotMeshOffset() ) + ( 0, 0, 250 ); // offset to make sure we're on top of the mesh
	targetNode = Spawn( "script_origin", targetOrigin );

	// link the heli into the mesh and give them control
	self RemoteControlVehicle( heli );
	
	heli RemoteControlVehicleTarget( targetNode );
	heli waittill( "goal_reached" );
	heli RemoteControlVehicleTargetOff();
	
	targetNode delete();
}

watchIntroCleared() // self == player
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	self waittill( "intro_cleared" );
	self SetClientDvar( "ui_heli_pilot", true );
}

//
//	state trackers
//

heliPilot_watchDeath()
{
	level endon( "game_ended" );
	self endon( "gone" );
	
	self waittill( "death" );
	
	self thread heliDestroyed();
	self.owner heliPilot_EndRide( self );
}


heliPilot_watchTimeout()
{
	level endon ( "game_ended" );
	self endon( "death" );
	self.owner endon( "disconnect" );
	self.owner endon( "joined_team" );
	self.owner endon( "joined_spectators" );
		
	timeout = level.heliPilotSettings[ self.heliPilotType ].timeOut;
/#
	timeout = GetDvarFloat( "scr_helipilot_timeout" );
#/
	maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( timeout );
	
	self thread heliPilot_leave();
}


heliPilot_watchOwnerLoss()
{
	level endon ( "game_ended" );
	self endon( "death" );
	self endon( "leaving" );

	self.owner waittill_any( "disconnect", "joined_team", "joined_spectators" );	
		
	//	leave
	self thread heliPilot_leave();
}

heliPilot_watchRoundEnd()
{
	self endon( "death" );
	self endon( "leaving" );	
	self.owner endon( "disconnect" );
	self.owner endon( "joined_team" );
	self.owner endon( "joined_spectators" );	

	level waittill_any( "round_end_finished", "game_ended" );

	//	leave
	self thread heliPilot_leave();
}

heliPilot_leave()
{
	self endon( "death" );
	self notify( "leaving" );

	self.owner heliPilot_EndRide( self );
	
	//	rise
	flyHeight = self maps\mp\killstreaks\_airdrop::getFlyHeightOffset( self.origin );	
	targetPos = self.origin + ( 0, 0, flyHeight );
	self Vehicle_SetSpeed( 140, 60 );
	self SetMaxPitchRoll( 45, 180 );
	self SetVehGoalPos( targetPos );
	self waittill( "goal" );	
	
	//	leave
	targetPos = targetPos + AnglesToForward( self.angles ) * 15000;
	// make sure it doesn't fly away backwards
	endEnt = Spawn( "script_origin", targetPos );
	if( IsDefined( endEnt ) )
	{
		self SetLookAtEnt( endEnt );
		endEnt thread wait_and_delete( 3.0 );
	}
	self SetVehGoalPos( targetPos );
	self waittill( "goal" );
	
	//	remove
	self notify( "gone" );	
	self removeLittlebird();
}

wait_and_delete( waitTime )
{
	self endon( "death" );
	level endon( "game_ended" );
	wait( waitTime );
	self delete();
}

heliPilot_EndRide( heli )
{
	if( IsDefined( heli ) )
	{		
		self SetClientDvar( "ui_heli_pilot", false );
		
		heli notify( "end_remote" );
		
		self clearUsingRemote();
		
		if( GetDvarInt( "camera_thirdPerson" ) )
			self setThirdPersonDOF( true );			
			
		maps\mp\killstreaks\_juggernaut::enableJuggernaut();
		
		self RemoteControlVehicleOff( heli );
		
		self SetPlayerAngles( self.restoreAngles );	
					
		self thread heliPilot_FreezeBuffer();
	}
}

heliPilot_FreezeBuffer()
{
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );
	
	self freezeControlsWrapper( true );
	wait( 0.5 );
	self freezeControlsWrapper( false );
}

//
//	Damage, death, and destruction
//

heliPilot_handleDamage() // self == heli
{
	self endon( "death" );
	level endon( "game_ended" );
	
	self SetCanDamage( true );

	while( true )
	{
		self waittill( "damage", damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon );

		// don't allow people to destroy things on their team if FF is off
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
			attacker maps\mp\gametypes\_damagefeedback::updateDamageFeedback( "helicopter" );

			if( meansOfDeath == "MOD_RIFLE_BULLET" || meansOfDeath == "MOD_PISTOL_BULLET" )
			{
				if ( attacker _hasPerk( "specialty_armorpiercing" ) )
					modifiedDamage += damage * level.armorPiercingMod;
			}
		}
		
		// in case we are shooting from a remote position, like being in the osprey gunner shooting this
		if( IsDefined( attacker.owner ) && IsPlayer( attacker.owner ) )
		{
			attacker.owner maps\mp\gametypes\_damagefeedback::updateDamageFeedback( "helicopter" );
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
				self.largeProjectileDamage = true;
				modifiedDamage = self.maxHealth + 1;
				break;

			case "sam_projectile_mp":
				self.largeProjectileDamage = true;		
				modifiedDamage = self.maxHealth * 0.25; // takes about 1 burst of sam rockets
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
				attacker notify( "destroyed_helicopter" );
				attacker notify( "destroyed_killstreak", weapon );
				thread teamPlayerCardSplash( "callout_destroyed_little_bird", attacker );			
				attacker thread maps\mp\gametypes\_rank::giveRankXP( "kill", 300, weapon, meansOfDeath );			
				attacker thread maps\mp\gametypes\_rank::xpEventPopup( &"SPLASHES_DESTROYED_LITTLE_BIRD" );
				thread maps\mp\gametypes\_missions::vehicleKilled( self.owner, self, undefined, attacker, damage, meansOfDeath, weapon );		
			}

			// TODO: get vo for this
			if( IsDefined( self.owner ) )
				self.owner thread leaderDialogOnPlayer( "lbguard_destroyed" );

			self notify ( "death" );
			return;
		}
	}
}

heliDestroyed()
{
	if( !IsDefined( self ) )
		return;
		
	self Vehicle_SetSpeed( 25, 5 );
	self thread lbSpin( RandomIntRange( 180, 220 ) );
	
	wait( RandomFloatRange( .5, 1.5 ) );
	
	lbExplode();
}

lbExplode()
{
	forward = ( self.origin + ( 0, 0, 1 ) ) - self.origin;

	deathAngles = self GetTagAngles( "tag_deathfx" );
	playFx( level.chopper_fx[ "explode" ][ "air_death" ][ "littlebird" ], self GetTagOrigin( "tag_deathfx" ), AnglesToForward( deathAngles ), AnglesToUp( deathAngles ) );
	
	self PlaySound( "cobra_helicopter_crash" );
	self notify( "explode" );
	
	self removeLittlebird();
}

lbSpin( speed )
{
	self endon( "explode" );
	
	//// tail explosion that caused the spinning
	//playfxontag( level.chopper_fx["explode"]["medium"], self, "tail_rotor_jnt" );
 //	self thread trail_fx( level.chopper_fx["smoke"]["trail"], "tail_rotor_jnt", "stop tail smoke" );
	
	self SetYawSpeed( speed, speed, speed );
	while( IsDefined( self ) )
	{
		self SetTargetYaw( self.angles[ 1 ] + ( speed * 0.9 ) );
		wait( 1 );
	}
}

trail_fx( trail_fx, trail_tag, stop_notify )
{
	// only one instance allowed
	self notify( stop_notify );
	self endon( stop_notify );
	self endon( "death" );
		
	while( true )
	{
		PlayFXOnTag( trail_fx, self, trail_tag );
		wait( 0.05 );
	}
}

removeLittlebird()
{	
	// decrement the faux vehicle count right before it is deleted this way we know for sure it is gone
	decrementFauxVehicleCount();

	level.heli_pilot[ self.team ] = undefined;
	
	self delete();	
}

//
//	node funcs
//

heliPilot_setAirStartNodes()
{
	level.air_start_nodes = getstructarray( "chopper_boss_path_start", "targetname" );
}

heliPilot_getLinkedStruct( struct )
{
	if( IsDefined( struct.script_linkTo ) )
	{
		linknames = struct get_links();
		for( i = 0; i < linknames.size; i++ )
		{
			ent = getstruct( linknames[ i ], "script_linkname" );
			if( IsDefined( ent ) )
			{
				return ent;
			}
		}
	}

	return undefined;
}

heliPilot_getClosestStartNode( pos )
{
	// gets the start node that is closest to the position passed in
	closestNode = undefined;
	closestDistance = 999999;

	foreach( loc in level.air_start_nodes )
	{ 	
		nodeDistance = Distance( loc.origin, pos );
		if ( nodeDistance < closestDistance )
		{
			closestNode = loc;
			closestDistance = nodeDistance;
		}
	}

	return closestNode;
}