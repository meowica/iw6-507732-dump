#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

CRATE_KILLCAM_OFFSET = ( 0, 0, 300);
GRAVITY_UNITS_PER_SECOND = 800;

init()
{
	level._effect[ "airdrop_crate_destroy" ] = loadfx( "fx/explosions/sentry_gun_explosion" );

	// TODO: this can be removed once we get the frontend done
	if ( level.script == "mp_character_room" )
		return;
	
	setAirDropCrateCollision( "airdrop_crate" ); 	// old care package entities
	setAirDropCrateCollision( "care_package" );		// new care package entities
	assert( IsDefined(level.airDropCrateCollision) );
	
	level.killStreakFuncs["airdrop_assault"] 			= ::tryUseAssaultAirdrop;
	level.killStreakFuncs["airdrop_support"] 			= ::tryUseSupportAirdrop;
	level.killStreakFuncs["airdrop_mega"] 				= ::tryUseMegaAirdrop;
	level.killStreakFuncs["airdrop_predator_missile"] 	= ::tryUseAirdropPredatorMissile;
	level.killStreakFuncs["airdrop_sentry_minigun"] 	= ::tryUseAirdropSentryMinigun;
	level.killStreakFuncs["airdrop_juggernaut"] 		= ::tryUseJuggernautAirdrop;
	level.killStreakFuncs["airdrop_juggernaut_recon"]	= ::tryUseJuggernautReconAirdrop;
	level.killStreakFuncs["airdrop_juggernaut_maniac"] 	= ::tryUseJuggernautManiacAirdrop;	
	level.killStreakFuncs["airdrop_remote_tank"] 		= ::tryUseAirdropRemoteTank;

	level.numDropCrates = 0;
	level.littleBirds 	= [];
	level.crateTypes	= [];
	level.crateMaxVal 	= [];

	friendly_crate_model 		= "com_plasticcase_friendly";
	enemy_crate_model 			= "com_plasticcase_enemy";
	juggernaut_crate_model 		= "mp_juggernaut_carepackage";

	// ASSAULT
	//				Drop Type			Type							Weight  Function				Friendly Model			Enemy Model				Hint String
	addCrateType(	"airdrop_assault",	"uplink",						25,		::killstreakCrateThink,	friendly_crate_model,	enemy_crate_model, 		&"KILLSTREAKS_UPLINK_PICKUP" );
	addCrateType(	"airdrop_assault",	"ims",							25,		::killstreakCrateThink,	friendly_crate_model,	enemy_crate_model,		&"KILLSTREAKS_IMS_PICKUP" );
	addCrateType(	"airdrop_assault",	"drone_hive",					20,		::killstreakCrateThink,	friendly_crate_model,	enemy_crate_model,		&"KILLSTREAKS_DRONE_HIVE_PICKUP" );
	addCrateType(	"airdrop_assault",	"guard_dog",					20,		::killstreakCrateThink,	friendly_crate_model,	enemy_crate_model,		&"KILLSTREAKS_GUARD_DOG_PICKUP" );
	addCrateType(	"airdrop_assault",	"ball_drone_backup",			4,		::killstreakCrateThink,	friendly_crate_model,	enemy_crate_model,		&"KILLSTREAKS_BALL_DRONE_BACKUP_PICKUP" );
	addCrateType(	"airdrop_assault",	"vanguard",						4,		::killstreakCrateThink,	friendly_crate_model,	enemy_crate_model,		&"KILLSTREAKS_VANGUARD_PICKUP" );
	addCrateType(	"airdrop_assault",	"agent",						4,		::killstreakCrateThink,	friendly_crate_model,	enemy_crate_model,		&"KILLSTREAKS_AGENT_PICKUP" );
	addCrateType(	"airdrop_assault",	"airdrop_juggernaut_maniac",	3,		::juggernautCrateThink, juggernaut_crate_model,	juggernaut_crate_model,	&"KILLSTREAKS_JUGGERNAUT_PICKUP" );
	addCrateType(	"airdrop_assault",	"remote_tank",					3,		::killstreakCrateThink, friendly_crate_model,	enemy_crate_model,		&"KILLSTREAKS_REMOTE_TANK_PICKUP" );
	addCrateType(	"airdrop_assault",	"helicopter_flares",			2,		::killstreakCrateThink,	friendly_crate_model,	enemy_crate_model,		&"KILLSTREAKS_HELICOPTER_FLARES_PICKUP" );
	addCrateType(	"airdrop_assault",	"ac130",						2,		::killstreakCrateThink,	friendly_crate_model,	enemy_crate_model,		&"KILLSTREAKS_AC130_PICKUP" );
	addCrateType(	"airdrop_assault",	"airdrop_juggernaut",			2,		::juggernautCrateThink, juggernaut_crate_model,	juggernaut_crate_model,	&"KILLSTREAKS_JUGGERNAUT_PICKUP" );
	addCrateType(	"airdrop_assault",	"heli_pilot",					1,		::killstreakCrateThink,	friendly_crate_model,	enemy_crate_model,		&"KILLSTREAKS_HELI_PILOT_PICKUP" );

	// SUPPORT
	addCrateType(	"airdrop_support",	"deployable_vest",				8,		::killstreakCrateThink,	friendly_crate_model,	enemy_crate_model,		&"KILLSTREAKS_DEPLOYABLE_VEST_PICKUP" );
	addCrateType(	"airdrop_support",	"sam_turret",					6,		::killstreakCrateThink,	friendly_crate_model,	enemy_crate_model,		&"KILLSTREAKS_SAM_TURRET_PICKUP" );
	addCrateType(	"airdrop_support",	"escort_airdrop",				1,		::killstreakCrateThink,	friendly_crate_model,	enemy_crate_model,		"TEMP NEEDS HINT" );	
	addCrateType(	"airdrop_support",	"emp",							1,		::killstreakCrateThink,	friendly_crate_model,	enemy_crate_model,		"TEMP NEEDS HINT" );	

	// GRINDER DROP			
	addCrateType(	"airdrop_grnd",	"uav",								25,		::killstreakCrateThink,	friendly_crate_model,		enemy_crate_model,	"TEMP NEEDS HINT" );	
	addCrateType(	"airdrop_grnd",	"counter_uav",						25,		::killstreakCrateThink,	friendly_crate_model,		enemy_crate_model,	"TEMP NEEDS HINT" );	
	addCrateType(	"airdrop_grnd",	"deployable_vest",					21,		::killstreakCrateThink,	friendly_crate_model,		enemy_crate_model,	"TEMP NEEDS HINT" );	
	addCrateType(	"airdrop_grnd",	"sentry",							21,		::killstreakCrateThink,	friendly_crate_model,		enemy_crate_model,	"TEMP NEEDS HINT" );		
	addCrateType(	"airdrop_grnd",	"remote_mg_turret",					17,		::killstreakCrateThink,	friendly_crate_model,		enemy_crate_model,	"TEMP NEEDS HINT" );			
	addCrateType(	"airdrop_grnd",	"ims",								17,		::killstreakCrateThink,	friendly_crate_model,		enemy_crate_model,	"TEMP NEEDS HINT" );			
	addCrateType(	"airdrop_grnd",	"directional_uav",					13,		::killstreakCrateThink,	friendly_crate_model,		enemy_crate_model,	"TEMP NEEDS HINT" );	
	addCrateType(	"airdrop_grnd",	"predator_missile",					13,		::killstreakCrateThink,	friendly_crate_model,		enemy_crate_model,	"TEMP NEEDS HINT" );	
	addCrateType(	"airdrop_grnd",	"precision_airstrike",				9,		::killstreakCrateThink,	friendly_crate_model,		enemy_crate_model,	"TEMP NEEDS HINT" );		
	addCrateType(	"airdrop_grnd",	"stealth_airstrike",				9,		::killstreakCrateThink,	friendly_crate_model,		enemy_crate_model,	"TEMP NEEDS HINT" );	
	addCrateType(	"airdrop_grnd",	"helicopter",						9,		::killstreakCrateThink,	friendly_crate_model,		enemy_crate_model,	"TEMP NEEDS HINT" );	
	addCrateType(	"airdrop_grnd",	"remote_tank",						7,		::killstreakCrateThink,	friendly_crate_model,		enemy_crate_model,	"TEMP NEEDS HINT" );	
	addCrateType(	"airdrop_grnd",	"sam_turret",						7,		::killstreakCrateThink,	friendly_crate_model,		enemy_crate_model,	"TEMP NEEDS HINT" );	
	addCrateType(	"airdrop_grnd",	"littlebird_support",				4,		::killstreakCrateThink,	friendly_crate_model,		enemy_crate_model,	"TEMP NEEDS HINT" );	
	addCrateType(	"airdrop_grnd",	"littlebird_flock",					2,		::killstreakCrateThink,	friendly_crate_model,		enemy_crate_model,	"TEMP NEEDS HINT" );	
	addCrateType(	"airdrop_grnd",	"helicopter_flares",				2,		::killstreakCrateThink,	friendly_crate_model,		enemy_crate_model,	"TEMP NEEDS HINT" );	
	addCrateType(	"airdrop_grnd",	"remote_mortar",					2,		::killstreakCrateThink,	friendly_crate_model,		enemy_crate_model,	"TEMP NEEDS HINT" );	
	addCrateType(	"airdrop_grnd",	"ac130",							2,		::killstreakCrateThink,	friendly_crate_model,		enemy_crate_model,	"TEMP NEEDS HINT" );		
	addCrateType(	"airdrop_grnd",	"emp",								1,		::killstreakCrateThink,	friendly_crate_model,		enemy_crate_model,	"TEMP NEEDS HINT" );	

	// MUGGER DROP			
	addCrateType(	"airdrop_mugger",	"airdrop_jackpot",				1,		::muggerCrateThink );	

	//			  Drop Type						Type						Weight	Function					
	addCrateType( "airdrop_sentry_minigun",		"sentry",					100,	::killstreakCrateThink,	friendly_crate_model,		enemy_crate_model,		"TEMP NEEDS HINT" );	
	addCrateType( "airdrop_juggernaut",			"airdrop_juggernaut",		100,	::juggernautCrateThink, juggernaut_crate_model,		juggernaut_crate_model,	&"KILLSTREAKS_JUGGERNAUT_PICKUP" );
	addCrateType( "airdrop_juggernaut_recon",	"airdrop_juggernaut_recon",	100,	::juggernautCrateThink, juggernaut_crate_model,		juggernaut_crate_model,	&"KILLSTREAKS_JUGGERNAUT_PICKUP" );
	addCrateType( "airdrop_juggernaut_maniac",	"airdrop_juggernaut_maniac",100,	::juggernautCrateThink, juggernaut_crate_model,		juggernaut_crate_model,	&"KILLSTREAKS_JUGGERNAUT_PICKUP" );	
	addCrateType( "littlebird_support",			"littlebird_support",		100,	::killstreakCrateThink,	friendly_crate_model,		enemy_crate_model,		"TEMP NEEDS HINT" );	
	addCrateType( "airdrop_remote_tank",		"remote_tank"		,		100,	::killstreakCrateThink,	friendly_crate_model,		enemy_crate_model, 		&"KILLSTREAKS_REMOTE_TANK_PICKUP" );
	
	// generate the max weighted value
	foreach( dropTypeArray in level.crateTypes )
	{
		foreach( crateType in dropTypeArray )
		{
			dropType = crateType.dropType;
			
			if( !IsDefined( level.crateMaxVal[ dropType ] ) )
				level.crateMaxVal[ dropType ] = 0;	

			type = crateType.type;
			if( !level.crateTypes[ dropType ][ type ].weight )
				continue;

			level.crateMaxVal[ dropType ] += level.crateTypes[ dropType ][ type ].weight;
			level.crateTypes[ dropType ][ type ].weight = level.crateMaxVal[ dropType ];
		}
	}

/#
	SetDevDvarIfUninitialized( "scr_crateOverride", "" );
	SetDevDvarIfUninitialized( "scr_crateTypeOverride", "" );
#/
}

setAirDropCrateCollision( carePackageName )
{
	airDropCrates = GetEntArray( carePackageName, "targetname" );
	
	if( !IsDefined(airDropCrates) || (airDropCrates.size == 0 ) )
	{
		return;
	}
	
	level.airDropCrateCollision = GetEnt( airDropCrates[0].target, "targetname" );
	
	foreach( crate in airDropCrates )
	{
		crate deleteCrate();
	}
}

addCrateType( dropType, crateType, crateWeight, crateFunc, crateModelFriendly, crateModelEnemy, hintString )
{
	if( !IsDefined( crateModelFriendly ) )
		crateModelFriendly = "com_plasticcase_friendly";
	if( !IsDefined( crateModelEnemy ) )
		crateModelEnemy = "com_plasticcase_enemy";

	level.crateTypes[ dropType ][ crateType ] = SpawnStruct();
	level.crateTypes[ dropType ][ crateType ].dropType = dropType;
	level.crateTypes[ dropType ][ crateType ].type = crateType;
	level.crateTypes[ dropType ][ crateType ].weight = crateWeight;
	level.crateTypes[ dropType ][ crateType ].func = crateFunc;
	level.crateTypes[ dropType ][ crateType ].model_name_friendly = crateModelFriendly;
	level.crateTypes[ dropType ][ crateType ].model_name_enemy = crateModelEnemy;

	if( IsDefined( hintString ) )
		game[ "strings" ][ crateType + "_hint" ] = hintString;
}


getRandomCrateType( dropType )
{
	value = RandomInt( level.crateMaxVal[ dropType ] );
	
	selectedCrateType = undefined;
	foreach( crateType in level.crateTypes[ dropType ] )
	{
		type = crateType.type;
		if( !level.crateTypes[ dropType ][ type ].weight )
			continue;

		selectedCrateType = type;

		if( level.crateTypes[ dropType ][ type ].weight > value )
		{
			break;
		}
	}
	
	return( selectedCrateType );
}


getCrateTypeForDropType( dropType )
{
	switch	( dropType )
	{
		case "airdrop_mugger":
			return "airdrop_jackpot";
		case "airdrop_sentry_minigun":
			return "sentry";
		case "airdrop_predator_missile":
			return "predator_missile";
		case "airdrop_juggernaut":
			return "airdrop_juggernaut";
		case "airdrop_juggernaut_def":
			return "airdrop_juggernaut_def";
		case "airdrop_juggernaut_gl":
			return "airdrop_juggernaut_gl";
		case "airdrop_juggernaut_recon":
			return "airdrop_juggernaut_recon";
		case "airdrop_juggernaut_maniac":
			return "airdrop_juggernaut_maniac";
		case "airdrop_remote_tank":
			return "remote_tank";
		case "airdrop_lase":
			return "lasedStrike";
		case "airdrop_assault":
		case "airdrop_support":
		case "airdrop_escort":
		case "airdrop_mega":
		case "airdrop_grnd":
		case "airdrop_grnd_mega":
		default:
			return getRandomCrateType( dropType );
	}
}



/**********************************************************
*		 Usage functions
***********************************************************/

tryUseLasedStrike( lifeId, kID )
{
	return ( self tryUseAirdrop( lifeId, kID, "airdrop_lase" ) );
}

tryUseAssaultAirdrop( lifeId, kID )
{
	return ( self tryUseAirdrop(  lifeId, kID, "airdrop_assault" ) );
}

tryUseSupportAirdrop( lifeId, kID )
{
	return ( self tryUseAirdrop(  lifeId, kID, "airdrop_support" ) );
}

tryUseAirdropPredatorMissile( lifeId, kID )
{
	return ( self tryUseAirdrop(  lifeId, kID, "airdrop_predator_missile" ) );
}

tryUseAirdropSentryMinigun(  lifeId, kID )
{
	return ( self tryUseAirdrop(  lifeId, kID, "airdrop_sentry_minigun" ) );
}

tryUseJuggernautAirdrop( lifeId, kID )
{
	return ( self tryUseAirdrop( lifeId, kID, "airdrop_juggernaut" ) );
}

tryUseJuggernautReconAirdrop( lifeId, kID )
{
	return ( self tryUseAirdrop( lifeId, kID, "airdrop_juggernaut_recon" ) );
}

tryUseJuggernautManiacAirdrop( lifeId, kID )
{
	return ( self tryUseAirdrop( lifeId, kID, "airdrop_juggernaut_maniac" ) );
}

tryUseMegaAirdrop( lifeId, kID )
{
	return ( self tryUseAirdrop(  lifeId, kID, "airdrop_mega" ) );
}

tryUseAirdropRemoteTank( lifeId, kID )
{
	return ( self tryUseAirdrop( lifeId, kID, "airdrop_remote_tank" ) );
}


tryUseAirdrop( lifeId, kID, dropType )
{
	result = undefined;
	
	if ( !IsDefined( dropType ) )
		dropType = "airdrop_assault";

	//if ( !IsDefined( self.pers["kIDs_valid"][kID] ) )
	//	return true;
		
	numIncomingVehicles = 1;
	if( ( level.littleBirds.size >= 4 || level.fauxVehicleCount >= 4 ) && dropType != "airdrop_mega" && !isSubStr( toLower( dropType ), "juggernaut" ) )
	{
		self iPrintLnBold( &"KILLSTREAKS_AIR_SPACE_TOO_CROWDED" );
		return false;
	} 
	else if( currentActiveVehicleCount() >= maxVehiclesAllowed() || level.fauxVehicleCount + numIncomingVehicles >= maxVehiclesAllowed() )
	{
		self iPrintLnBold( &"KILLSTREAKS_TOO_MANY_VEHICLES" );
		return false;
	}		
	else if( dropType == "airdrop_lase" && IsDefined( level.lasedStrikeCrateActive ) && level.lasedStrikeCrateActive )
	{
		self iPrintLnBold( &"KILLSTREAKS_AIR_SPACE_TOO_CROWDED" );
		return false;
	} 
	
	if ( dropType != "airdrop_mega" && !isSubStr( toLower( dropType ), "juggernaut" ) )
	{
		self thread watchDisconnect();
	}
	
	// increment the faux vehicle count before we spawn the vehicle so no other vehicles try to spawn
	if( !IsSubStr( dropType, "juggernaut" ) )
		incrementFauxVehicleCount();

	result = self beginAirdropViaMarker( lifeId, kID, dropType );
	
	if ( (!IsDefined( result ) || !result) /*&& IsDefined( self.pers["kIDs_valid"][kID] )*/ )
	{
		self notify( "markerDetermined" );

		// decrement the faux vehicle count since this failed to spawn
		decrementFauxVehicleCount();

		return false;
	}
	
	if ( dropType == "airdrop_mega" )
		thread teamPlayerCardSplash( "used_airdrop_mega", self );
	
	self notify( "markerDetermined" );
	
	self maps\mp\_matchdata::logKillstreakEvent( dropType, self.origin );	
	
	return true;
}

watchDisconnect()
{
	self endon( "markerDetermined" );
	
	self waittill( "disconnect" );
	return;
}


/**********************************************************
*		 Marker functions
***********************************************************/

beginAirdropViaMarker( lifeId, kID, dropType )
{	
	self notify( "beginAirdropViaMarker" );
	self endon( "beginAirdropViaMarker" );

	self endon( "disconnect" );
	level endon( "game_ended" );

	// reworked this to thread all of the functions at once and then watch for what returns
	// this fixes an infinite care package bug where you can kill the player as they throw it and they'll respawn with another one
	self.threwAirDropMarker = undefined;
	self.threwAirDropMarkerIndex = undefined;
	self thread watchAirDropWeaponChange( lifeId, kID, dropType );
	self thread watchAirDropMarkerUsage( lifeId, kID, dropType );
	self thread watchAirDropMarker( lifeId, kID, dropType );

	result = self waittill_any_return( "notAirDropWeapon", "markerDetermined" );
	if( IsDefined( result ) && result == "markerDetermined" )
		return true;
	// result comes back as undefined if the player is killed while throwing, so we need to check to see if they threw the marker before dying
	else if( !IsDefined( result ) && IsDefined( self.threwAirDropMarker ) )
		return true;

	return false;
}

watchAirDropWeaponChange( lifeId, kID, dropType )
{
	level endon( "game_ended" );
	
	self notify( "watchAirDropWeaponChange" );
	self endon( "watchAirDropWeaponChange" );
	
	self endon( "disconnect" );
	self endon( "markerDetermined" );

	while( self isChangingWeapon() )
		wait ( 0.05 );	

	currentWeapon = self getCurrentWeapon();

	if ( isAirdropMarker( currentWeapon ) )
		airdropMarkerWeapon = currentWeapon;
	else
		airdropMarkerWeapon = undefined;

	while( isAirdropMarker( currentWeapon ) /*|| currentWeapon == "none"*/ )
	{
		self waittill( "weapon_change", currentWeapon );

		if ( isAirdropMarker( currentWeapon ) )
			airdropMarkerWeapon = currentWeapon;
	}

	if( IsDefined( self.threwAirDropMarker ) )
	{
		// need to take the killstreak weapon here because the weapon_change happens before it can be taken in _killstreaks::waitTakeKillstreakWeapon()
		killstreakWeapon = getKillstreakWeapon( self.pers["killstreaks"][self.threwAirDropMarkerIndex].streakName );
		self TakeWeapon( killstreakWeapon );

		self notify( "markerDetermined" );
	}
	else
		self notify( "notAirDropWeapon" );
}

watchAirDropMarkerUsage( lifeId, kID, dropType )
{
	level endon( "game_ended" );
	
	self notify( "watchAirDropMarkerUsage" );
	self endon( "watchAirDropMarkerUsage" );

	self endon( "disconnect" );
	self endon( "markerDetermined" );
	
	while( true )
	{
		self waittill( "grenade_pullback", weaponName );

		// could've thrown a grenade while holding the airdrop weapon
		if( !isAirdropMarker( weaponName ) )
			continue;

		self _disableUsability();

		self beginAirDropMarkerTracking();
	}
}

watchAirDropMarker( lifeId, kID, dropType )
{
	level endon( "game_ended" );
	
	self notify( "watchAirDropMarker" );
	self endon( "watchAirDropMarker" );

	self endon( "disconnect" );
	self endon( "markerDetermined" );

	while( true )
	{
		self waittill( "grenade_fire", airDropWeapon, weapname );
		
		if ( !isAirdropMarker( weapname ) )
			continue;
		
		//if( !IsAlive( self ) )
		//{
		//	airDropWeapon delete();
		//	return;
		//}
	
		//if ( !IsDefined( self.pers["kIDs_valid"][kID] ) )
		//{
		//	airDropWeapon delete();
		//	continue;
		//}
			
		//self.pers["kIDs_valid"][kID] = undefined;

		self.threwAirDropMarker = true;
		self.threwAirDropMarkerIndex = self.killstreakIndexWeapon;
		airDropWeapon thread airdropDetonateOnStuck();
			
		airDropWeapon.owner = self;
		airDropWeapon.weaponName = weapname;
		
		airDropWeapon thread airDropMarkerActivate( dropType );		
	}
}

beginAirDropMarkerTracking()
{
	level endon( "game_ended" );
	
	self notify( "beginAirDropMarkerTracking" );
	self endon( "beginAirDropMarkerTracking" );

	self endon( "death" );
	self endon( "disconnect" );

	self waittill_any( "grenade_fire", "weapon_change" );
	self _enableUsability();
}

airDropMarkerActivate( dropType, lifeId )
{	
	level endon( "game_ended" );
	
	self notify( "airDropMarkerActivate" );
	self endon( "airDropMarkerActivate" );

	self waittill( "explode", position );

	owner = self.owner;

	if ( !IsDefined( owner ) )
		return;
	
	if ( owner isEMPed() )
		return;
		
	if ( owner isAirDenied() )
		return;
	
	if( IsSubStr( toLower( dropType ), "escort_airdrop" ) && IsDefined( level.chopper ) )
		return;

	//// play an additional smoke fx that is longer than the normal for the escort airdrop
	//if( IsSubStr( toLower( dropType ), "escort_airdrop" ) && IsDefined( level.chopper_fx["smoke"]["signal_smoke_30sec"] ) )
	//{
	//	PlayFX( level.chopper_fx["smoke"]["signal_smoke_30sec"], position, ( 0, 0, -1 ) );
	//}

	wait 0.05;
	
	if ( IsSubStr( toLower( dropType ), "juggernaut" ) )
		level doC130FlyBy( owner, position, randomFloat( 360 ), dropType );
	else if ( IsSubStr( toLower( dropType ), "escort_airdrop" ) )
		owner maps\mp\killstreaks\_escortairdrop::finishSupportEscortUsage( lifeId, position, randomFloat( 360 ), "escort_airdrop" );
	else
		level doFlyBy( owner, position, randomFloat( 360 ), dropType );
}

/**********************************************************
*		 crate functions
***********************************************************/
initAirDropCrate()
{
	self.inUse = false;
	self hide();

	if ( IsDefined( self.target ) )
	{
		self.collision = getEnt( self.target, "targetname" );
		self.collision notSolid();
	}
	else
	{
		self.collision = undefined;
	}
}


deleteOnOwnerDeath( owner )
{
	wait ( 0.25 );
	self linkTo( owner, "tag_origin", (0,0,0), (0,0,0) );

	owner waittill ( "death" );
	
	self delete();
}


crateTeamModelUpdater() // self == crate team model (the logo)
{
	self endon ( "death" );

	self hide();
	foreach ( player in level.players )
	{
		if ( player.team != "spectator" )
			self ShowToPlayer( player );
	}

	for ( ;; )
	{
		level waittill ( "joined_team" );
		
		self hide();
		foreach ( player in level.players )
		{
			if ( player.team != "spectator" )
				self ShowToPlayer( player );
		}
	}	
}


crateModelTeamUpdater( showForTeam ) // self == crate model (friendly or enemy)
{
	self endon ( "death" );

	self hide();

	foreach ( player in level.players )
	{
		if( player.team == showForTeam )
			self ShowToPlayer( player );
	}

	for ( ;; )
	{
		level waittill ( "joined_team" );
		
		self hide();
		foreach ( player in level.players )
		{
			if ( player.team == showForTeam )
				self ShowToPlayer( player );
		}
	}	
}

crateModelEnemyTeamsUpdater( ownerTeam ) // self == crate model (enemyTeams only)
{
	self endon ( "death" );

	self hide();

	foreach ( player in level.players )
	{
		if( player.team != ownerTeam )
			self ShowToPlayer( player );
	}

	for ( ;; )
	{
		level waittill ( "joined_team" );
		
		self hide();
		foreach ( player in level.players )
		{
			if ( player.team != ownerTeam )
				self ShowToPlayer( player );
		}
	}	
}

// for FFA
crateModelPlayerUpdater( owner, friendly ) // self == crate model (friendly or enemy)
{
	self endon ( "death" );

	self hide();

	foreach ( player in level.players )
	{
		if( friendly && IsDefined( owner ) && player != owner )
			continue;
		if( !friendly && IsDefined( owner ) && player == owner )
			continue;

		self ShowToPlayer( player );
	}

	for ( ;; )
	{
		level waittill ( "joined_team" );

		self hide();
		foreach ( player in level.players )
		{
			if( friendly && IsDefined( owner ) && player != owner )
				continue;
			if( !friendly && IsDefined( owner ) && player == owner )
				continue;

			self ShowToPlayer( player );
		}
	}	
}

crateUseTeamUpdater( team )
{
	self endon ( "death" );

	for ( ;; )
	{
		setUsableByTeam( team );

		level waittill ( "joined_team" );
		
	}	
}

crateUseTeamUpdater_multiTeams( team )
{
	self endon ( "death" );

	for ( ;; )
	{
		setUsableByOtherTeams( team );

		level waittill ( "joined_team" );
		
	}	
}

crateUseJuggernautUpdater()
{
	if ( !isSubStr( self.crateType, "juggernaut" ) )
		return;
	
	self endon( "death" );
	level endon( "game_ended" );
	
	for ( ;; )
	{
		level waittill ( "juggernaut_equipped", player );
		
		self disablePlayerUse( player );
		self thread crateUsePostJuggernautUpdater( player );
	}	
}

crateUsePostJuggernautUpdater( player )
{
	self endon( "death" );
	level endon( "game_ended" );
	player endon( "disconnect" );
	
	player waittill( "death" );
	self enablePlayerUse( player );	
}

createAirDropCrate( owner, dropType, crateType, startPos )
{
	dropCrate = Spawn( "script_model", startPos );
	
	dropCrate.curProgress = 0;
	dropCrate.useTime = 0;
	dropCrate.useRate = 0;
	dropCrate.team = self.team;
	
	if ( IsDefined( owner ) )
		dropCrate.owner = owner;
	else
		dropCrate.owner = undefined;
	
	dropCrate.crateType = crateType;
	dropCrate.dropType = dropType;
	dropCrate.targetname = "care_package";
	
	if ( crateType == "airdrop_jackpot" )
	{
		dropCrate SetModel( level.crateTypes[ dropType ][ crateType ].model_name_friendly );
		dropCrate.friendlyModel = Spawn( "script_model", startPos );
		dropCrate.friendlyModel SetModel( level.crateTypes[ dropType ][ crateType ].model_name_friendly );
		dropCrate.friendlyModel thread deleteOnOwnerDeath( dropCrate );
	}
	else
	{
		// TODO: need the new jugg crate rigged
		//if( IsSubStr( level.crateTypes[ dropType ][ crateType ].type, "juggernaut" ) )
		//	dropCrate SetModel( level.crateTypes[ dropType ][ crateType ].model_name_friendly );	
		//else
			dropCrate SetModel( maps\mp\gametypes\_teams::getTeamCrateModel( dropCrate.team ) );	
		
		dropCrate thread crateTeamModelUpdater();	
	
		dropCrate.friendlyModel = Spawn( "script_model", startPos );
		dropCrate.friendlyModel SetModel( level.crateTypes[ dropType ][ crateType ].model_name_friendly );
		dropCrate.enemyModel = Spawn( "script_model", startPos );
		dropCrate.enemyModel SetModel( level.crateTypes[ dropType ][ crateType ].model_name_enemy );
	
		dropCrate.friendlyModel thread deleteOnOwnerDeath( dropCrate );
		if( level.teambased )
			dropCrate.friendlyModel thread crateModelTeamUpdater( dropCrate.team );
		else
			dropCrate.friendlyModel thread crateModelPlayerUpdater( owner, true );
	
		dropCrate.enemyModel thread deleteOnOwnerDeath( dropCrate );
		if( level.multiTeambased )
			dropCrate.enemyModel thread crateModelEnemyTeamsUpdater( dropCrate.team );
		else if( level.teambased )
			dropCrate.enemyModel thread crateModelTeamUpdater( level.otherTeam[dropCrate.team] );
		else
			dropCrate.enemyModel thread crateModelPlayerUpdater( owner, false );
	}

	dropCrate.inUse = false;
	
	dropCrate CloneBrushmodelToScriptmodel( level.airDropCrateCollision );
	dropCrate thread entity_path_disconnect_thread( 1.0 );
	
	dropCrate.killCamEnt = Spawn( "script_model", dropCrate.origin + CRATE_KILLCAM_OFFSET );
	dropCrate.killCamEnt SetScriptMoverKillCam( "explosive" );
	dropCrate.killCamEnt LinkTo( dropCrate );

	level.numDropCrates++;
	dropCrate thread dropCrateExistence();

	return dropCrate;
}

dropCrateExistence()
{
	level endon( "game_ended" );
	
	self waittill( "death" );
	
	level.numDropCrates--;
}

crateSetupForUse( hintString, mode, icon )
{	
	self setCursorHint( "HINT_NOICON" );
	self setHintString( hintString );
	self makeUsable();
	self.mode = mode;

	if( level.multiTeamBased )
	{
		for( i = 0; i < level.teamNameList.size; i++ )
		{
			curObjID = maps\mp\gametypes\_gameobjects::getNextObjID();	
			objective_add( curObjID, "invisible", (0,0,0) );
			objective_position( curObjID, self.origin );
			objective_state( curObjID, "active" );
			
			if( level.teamNameList[i] == self.team )
			{	
				shaderName = "compass_objpoint_ammo_friendly";
				objective_team( curObjID, level.teamNameList[i] );
				objective_icon( curObjID, "compass_objpoint_ammo_friendly" );
				self.objIdFriendly = curObjID;
			}
			else
			{
				objective_team( curObjID, level.teamNameList[i] );
				objective_icon( curObjID, "compass_objpoint_ammo_enemy" );
				self.objIdEnemy[level.teamNameList[i]] = curObjID;
			}
		}
	}
	else
	{
		//setup owner team
		if ( level.teamBased || IsDefined( self.owner ) )
		{
			curObjID = maps\mp\gametypes\_gameobjects::getNextObjID();	
			objective_add( curObjID, "invisible", (0,0,0) );
			objective_position( curObjID, self.origin );
			objective_state( curObjID, "active" );
		
			shaderName = "compass_objpoint_ammo_friendly";
			objective_icon( curObjID, shaderName );
		
			if ( !level.teamBased && IsDefined( self.owner ) )
				Objective_PlayerTeam( curObjId, self.owner GetEntityNumber() );
			else
				Objective_Team( curObjID, self.team );
		
			self.objIdFriendly = curObjID;
		}

		curObjID = maps\mp\gametypes\_gameobjects::getNextObjID();	
		objective_add( curObjID, "invisible", (0,0,0) );
		objective_position( curObjID, self.origin );
		objective_state( curObjID, "active" );
		objective_icon( curObjID, "compass_objpoint_ammo_enemy" );

		if ( !level.teamBased && IsDefined( self.owner ) )
			Objective_PlayerEnemyTeam( curObjId, self.owner GetEntityNumber() );
		else
			Objective_Team( curObjID, level.otherTeam[self.team] );

		self.objIdEnemy = curObjID;
	}

	self thread crateUseTeamUpdater();	
	
	if ( isSubStr( self.crateType, "juggernaut" ) )
	{
		foreach ( player in level.players )
			if ( player isJuggernaut() )
				self thread crateUsePostJuggernautUpdater( player );
	}		

	if ( level.teamBased )
		self maps\mp\_entityheadIcons::setHeadIcon( self.team, icon, (0,0,24), 14, 14, undefined, undefined, undefined, undefined, undefined, false );
	else if ( IsDefined( self.owner ) )
		self maps\mp\_entityheadIcons::setHeadIcon( self.owner, icon, (0,0,24), 14, 14, undefined, undefined, undefined, undefined, undefined, false );

	if ( icon != "none" )
	{
		if ( level.teamBased )
			self maps\mp\_entityheadIcons::setHeadIcon( self.team, icon, (0,0,24), 14, 14, undefined, undefined, undefined, undefined, undefined, false );
		else if ( IsDefined( self.owner ) )
			self maps\mp\_entityheadIcons::setHeadIcon( self.owner, icon, (0,0,24), 14, 14, undefined, undefined, undefined, undefined, undefined, false );
	}
	
	self thread crateUseJuggernautUpdater();
}

setUsableByTeam( team )
{
	foreach ( player in level.players )
	{
		if ( isSubStr( self.crateType, "juggernaut" ) && player isJuggernaut() )
		{
			self DisablePlayerUse( player );
		}
		else if ( isSubStr( self.crateType, "lased" ) && IsDefined(player.hasSoflam) && player.hasSoflam )
		{
			self DisablePlayerUse( player );
		}
		else if ( !IsDefined( team ) || team == player.team )
			self EnablePlayerUse( player );
		else
			self DisablePlayerUse( player );
	}	
}

//adding reverse logic version for when there are more than two teams
setUsableByOtherTeams( team )
{
	foreach ( player in level.players )
	{
		if ( isSubStr( self.crateType, "juggernaut" ) && player isJuggernaut() )
		{
			self DisablePlayerUse( player );
		}
		else if ( !IsDefined( team ) || team != player.team )
			self EnablePlayerUse( player );
		else
			self DisablePlayerUse( player );
	}	
}



dropTheCrate( dropPoint, dropType, lbHeight, dropImmediately, crateOverride, startPos, dropImpulse, previousCrateTypes, tagName )
{
	dropCrate = [];
	self.owner endon ( "disconnect" );
	
	if ( !IsDefined( crateOverride ) )
	{
		//	verify emergency airdrops don't drop dupes
		if ( IsDefined( previousCrateTypes ) )
		{
			foundDupe = undefined;
			crateType = undefined;
			for ( i=0; i<100; i++ )
			{
				crateType = getCrateTypeForDropType( dropType );
				foundDupe = false;
				for ( j=0; j<previousCrateTypes.size; j++ )
				{
					if ( crateType == previousCrateTypes[j] )
					{
						foundDupe = true;
						break;
					}
				}
				if ( foundDupe == false )
					break;
			}
			//	if 100 attempts fail, just get whatever, we tried		
			if ( foundDupe == true )
			{
				crateType = getCrateTypeForDropType( dropType );
			}
		}
		else
			crateType = getCrateTypeForDropType( dropType );	
	}	
	else
		crateType = crateOverride;
		
	if ( !IsDefined( dropImpulse ) )
		dropImpulse = (RandomInt(50),RandomInt(50),RandomInt(50));
		
	dropCrate = createAirDropCrate( self.owner, dropType, crateType, startPos );
	
	switch( dropType )
	{
	case "airdrop_mega":
	case "nuke_drop":
	case "airdrop_juggernaut":
	case "airdrop_juggernaut_recon":
	case "airdrop_juggernaut_maniac":
		dropCrate LinkTo( self, "tag_ground" , (64,32,-128) , (0,0,0) );
		break;
	case "airdrop_escort":
	case "airdrop_osprey_gunner":
		dropCrate LinkTo( self, tagName, (0,0,0), (0,0,0) );
		break;
	default:
		dropCrate LinkTo( self, "tag_ground" , (32,0,5) , (0,0,0) );
		break;
	}

	dropCrate.angles = (0,0,0);
	dropCrate show();
	dropSpeed = self.veh_speed;
	
	self thread waitForDropCrateMsg( dropCrate, dropImpulse, dropType, crateType );
	dropCrate.droppingToGround = true;
	
	return crateType;
}


killPlayerFromCrate_FastVelocityPush()
{
	self endon( "death" );

	while( 1 )
	{
		self waittill( "player_pushed", hitEnt, platformMPH );
		if ( isPlayer( hitEnt ) )
		{
			if ( platformMPH[2] < -20 )
			{
				hitEnt DoDamage( 1000, hitEnt.origin );
			}
		}
		wait 0.05;
	}
}


killPlayerFromCrate_UnresolvedCollision()
{
	self endon( "death" );

	while( 1 )
	{
		self waittill( "unresolved_collision", hitEnt );
		if ( isPlayer( hitEnt ) )
		{
			hitEnt DoDamage( 1000, hitEnt.origin );
		}
		wait 0.05;
	}
}

airdrop_generic_collision_destroy()
{
	self endon( "death" );
	level endon ( "game_ended" );

	platform = self maps\mp\_movers::script_mover_generic_collision_destroy( false );
	self deleteCrate();
}

waitForDropCrateMsg( dropCrate, dropImpulse, dropType, crateType )
{
	self waittill ( "drop_crate" );
	
	dropCrate Unlink();
	dropCrate PhysicsLaunchServer( (0,0,0), dropImpulse );		
	dropCrate thread physicsWaiter( dropType, crateType );
	dropCrate thread killPlayerFromCrate_UnresolvedCollision();
	dropCrate thread killPlayerFromCrate_FastVelocityPush();

	if( IsDefined( dropCrate.killCamEnt ) )
	{
		// calculate the time it takes to get from here to the ground
		dropCrate.killCamEnt Unlink();
		groundTrace = BulletTrace( dropCrate.origin, dropCrate.origin + ( 0, 0, -10000 ), false, dropCrate );
		travelDistance = Distance( dropCrate.origin, groundTrace[ "position" ] );
		//travelDistance *= 2;
		travelTime = travelDistance / GRAVITY_UNITS_PER_SECOND;
		//travleTime = sqrt( travelTime );
		dropCrate.killCamEnt MoveTo( groundTrace[ "position" ] + CRATE_KILLCAM_OFFSET, travelTime );
		//dropCrate.killCamEnt MoveGravity( ( 0, 0, -1 ), travelTime );
	}
}	

physicsWaiter( dropType, crateType )
{
	self waittill( "physics_finished" );

	self.droppingToGround = false;
	self thread [[ level.crateTypes[ dropType ][ crateType ].func ]]( dropType );
	level thread dropTimeOut( self, self.owner, crateType );
	self thread airdrop_generic_collision_destroy();
		
	killTriggers = getEntArray( "trigger_hurt", "classname" );	
	foreach ( trigger in killTriggers )
	{
		if ( self.friendlyModel isTouching( trigger ) )
		{
			self deleteCrate();
			return;
		}
	}
			
	if( IsDefined(self.owner) && ( abs(self.origin[2] - self.owner.origin[2]) > 3000 ) )
	{
		self deleteCrate();	
	}
}


//deletes if crate wasnt used after 90 seconds
dropTimeOut( dropCrate, owner, crateType )
{
	level endon ( "game_ended" );
	dropCrate endon( "death" );
	
	if ( dropCrate.dropType == "nuke_drop" )
		return;	
	
	timeOut = 90.0;
	if ( crateType == "supply" )
		timeOut = 20.0;
	
	maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( timeOut );
	
	while ( dropCrate.curProgress != 0 )
		wait 1;
	
	dropCrate deleteCrate();
}


getPathStart( coord, yaw )
{
	pathRandomness = 100;
	lbHalfDistance = 15000;

	direction = (0,yaw,0);

	startPoint = coord + ( AnglesToForward( direction ) * ( -1 * lbHalfDistance ) );
	startPoint += ( (randomfloat(2) - 1)*pathRandomness, (randomfloat(2) - 1)*pathRandomness, 0 );
	
	return startPoint;
}


getPathEnd( coord, yaw )
{
	pathRandomness = 150;
	lbHalfDistance = 15000;

	direction = (0,yaw,0);

	endPoint = coord + ( AnglesToForward( direction + ( 0, 90, 0 ) ) * lbHalfDistance );
	endPoint += ( (randomfloat(2) - 1)*pathRandomness  , (randomfloat(2) - 1)*pathRandomness  , 0 );
	
	return endPoint;
}


getFlyHeightOffset( dropSite )
{
	lbFlyHeight = 850;
	
	heightEnt = GetEnt( "airstrikeheight", "targetname" );
	
	if ( !IsDefined( heightEnt ) )//old system 
	{
		/#
		println( "NO DEFINED AIRSTRIKE HEIGHT SCRIPT_ORIGIN IN LEVEL" );
		#/
		if ( IsDefined( level.airstrikeHeightScale ) )
		{	
			if ( level.airstrikeHeightScale > 2 )
			{
				lbFlyHeight = 1500;
				return( lbFlyHeight * (level.airStrikeHeightScale ) );
			}
			
			return( lbFlyHeight * level.airStrikeHeightScale + 256 + dropSite[2] );
		}
		else
			return ( lbFlyHeight + dropsite[2] );	
	}
	else
	{
		return heightEnt.origin[2];
	}
	
}


/**********************************************************
*		 Helicopter Functions
***********************************************************/

doFlyBy( owner, dropSite, dropYaw, dropType, heightAdjustment, crateOverride )
{	
	if ( !IsDefined( owner ) ) 
		return;
		
	flyHeight = self getFlyHeightOffset( dropSite );
	if ( IsDefined( heightAdjustment ) )
		flyHeight += heightAdjustment;	
	foreach( littlebird in level.littlebirds )
	{
		if ( IsDefined( littlebird.dropType ) )
			flyHeight += 128;
	}

	pathGoal = dropSite * (1,1,0) +  (0,0,flyHeight);	
	pathStart = getPathStart( pathGoal, dropYaw );
	pathEnd = getPathEnd( pathGoal, dropYaw );		
	
	pathGoal = pathGoal + ( AnglesToForward( ( 0, dropYaw, 0 ) ) * -50 );

	chopper = heliSetup( owner, pathStart, pathGoal );
	assert ( IsDefined( chopper ) );
	
	chopper endon( "death" );
	
	if ( !IsDefined( crateOverride ) )
		crateOverride = undefined;		

/#
	if( GetDvar( "scr_crateOverride" ) != "" )
	{
		crateOverride = GetDvar( "scr_crateOverride" );
		dropType = GetDvar( "scr_crateTypeOverride" );
	}
#/

	chopper.dropType = dropType;
	
	chopper setVehGoalPos( pathGoal, 1 );
		
	chopper thread dropTheCrate( dropSite, dropType, flyHeight, false, crateOverride, pathStart );
	
	wait ( 2 );
	
	chopper Vehicle_SetSpeed( 75, 40 );
	chopper SetYawSpeed( 180, 180, 180, .3 );
	
	chopper waittill ( "goal" );
	wait( .10 );
	chopper notify( "drop_crate" );
	chopper setvehgoalpos( pathEnd, 1 );
	chopper Vehicle_SetSpeed( 300, 75 );
	chopper.leaving = true;
	chopper waittill ( "goal" );
	chopper notify( "leaving" );
	chopper notify( "delete" );

	// decrement the faux vehicle count right before it is deleted this way we know for sure it is gone
	decrementFauxVehicleCount();

	chopper delete();
}

doMegaFlyBy( owner, dropSite, dropYaw, dropType )
{
	level thread doFlyBy( owner, dropSite, dropYaw, dropType, 0 );
	wait( RandomIntRange( 1,2 ) );
	level thread doFlyBy( owner, dropSite + (128,128,0), dropYaw, dropType, 128 );
	wait( RandomIntRange( 1,2 ) );
	level thread doFlyBy( owner, dropSite + (172,256,0), dropYaw, dropType, 256 );
	wait( RandomIntRange( 1,2 ) );
	level thread doFlyBy( owner, dropSite + (64,0,0), dropYaw, dropType, 0 );
}

doC130FlyBy( owner, dropSite, dropYaw, dropType )
{	
	planeHalfDistance = 18000;
	planeFlySpeed = 3000;
	yaw = VectorToYaw( dropsite - owner.origin );
	
	direction = ( 0, yaw, 0 );
	
	flyHeight = self getFlyHeightOffset( dropSite );
	
	pathStart = dropSite + ( AnglesToForward( direction ) * ( -1 * planeHalfDistance ) );
	pathStart = pathStart * ( 1, 1, 0 ) + ( 0, 0, flyHeight );

	pathEnd = dropSite + ( AnglesToForward( direction ) * planeHalfDistance );
	pathEnd = pathEnd * ( 1, 1, 0 ) + ( 0, 0, flyHeight );
	
	d = length( pathStart - pathEnd );
	flyTime = ( d / planeFlySpeed );
	
	c130 = c130Setup( owner, pathStart, pathEnd );
	c130.veh_speed = planeFlySpeed;
	c130.dropType = dropType;
 	c130 PlayLoopSound( "veh_ac130_dist_loop" );

	c130.angles = direction;
	forward = AnglesToForward( direction );
	c130 MoveTo( pathEnd, flyTime, 0, 0 ); 
	
	minDist = Distance2D( c130.origin, dropSite );
	boomPlayed = false;
	
	for(;;)
	{
		dist = Distance2D( c130.origin, dropSite );
		
		// handle missing our target
		if ( dist < minDist )
			minDist = dist;
		else if ( dist > minDist )
			break;
		
		if ( dist < 320 )
		{
			break;
		}
		else if ( dist < 768 )
		{
			earthquake( 0.15, 1.5, dropSite, 1500 );
			if ( !boomPlayed )
			{
				c130 playSound( "veh_ac130_sonic_boom" );
				//c130 thread stopLoopAfter( 0.5 );
				boomPlayed = true;
			}
		}	
		
		wait ( .05 );	
	}	
	wait( 0.05 );
	
	dropImpulse = (0,0,0);
	
	if ( GetDvar( "g_gametype" ) != "aliens" )
	{
		crateType[0] = c130 thread dropTheCrate( dropSite, dropType, flyHeight, false, undefined, pathStart, dropImpulse );
	}
	wait ( 0.05 );
	c130 notify ( "drop_crate" );

	newPathEnd = dropSite + ( AnglesToForward( direction ) * (planeHalfDistance*1.5) );
	c130 MoveTo( newPathEnd, flyTime/2, 0, 0 ); 

	wait ( 6 );
	c130 delete();
}


doMegaC130FlyBy( owner, dropSite, dropYaw, dropType, forwardOffset )
{	
	planeHalfDistance = 24000;
	planeFlySpeed = 2000;
	yaw = VectorToYaw( dropsite - owner.origin );
	direction = ( 0, yaw, 0 );
	forward = AnglesToForward( direction );
	
	if ( IsDefined( forwardOffset ) )
		dropSite = dropSite + forward * forwardOffset;	
	
	flyHeight = self getFlyHeightOffset( dropSite );
	
	pathStart = dropSite + ( AnglesToForward( direction ) * ( -1 * planeHalfDistance ) );
	pathStart = pathStart * ( 1, 1, 0 ) + ( 0, 0, flyHeight );

	pathEnd = dropSite + ( AnglesToForward( direction ) * planeHalfDistance );
	pathEnd = pathEnd * ( 1, 1, 0 ) + ( 0, 0, flyHeight );
	
	d = length( pathStart - pathEnd );
	flyTime = ( d / planeFlySpeed );
	
	c130 = c130Setup( owner, pathStart, pathEnd );
	c130.veh_speed = planeFlySpeed;
	c130.dropType = dropType;
 	c130 PlayLoopSound( "veh_ac130_dist_loop" );

	c130.angles = direction;
	forward = AnglesToForward( direction );
	c130 MoveTo( pathEnd, flyTime, 0, 0 ); 
	
	minDist = Distance2D( c130.origin, dropSite );
	boomPlayed = false;
	
	for(;;)
	{
		dist = Distance2D( c130.origin, dropSite );
		
		// handle missing our target
		if ( dist < minDist )
			minDist = dist;
		else if ( dist > minDist )
			break;
		
		if ( dist < 256 )
		{
			break;
		}
		else if ( dist < 768 )
		{
			earthquake( 0.15, 1.5, dropSite, 1500 );
			if ( !boomPlayed )
			{
				c130 playSound( "veh_ac130_sonic_boom" );
				//c130 thread stopLoopAfter( 0.5 );
				boomPlayed = true;
			}
		}	
		
		wait ( .05 );	
	}	
	wait( 0.05 );
	
	crateType[0] = c130 thread dropTheCrate( dropSite, dropType, flyHeight, false, undefined, pathStart );	
	wait ( 0.05 );
	c130 notify ( "drop_crate" );
	wait ( 0.05 );

	crateType[1] = c130 thread dropTheCrate( dropSite, dropType, flyHeight, false, undefined, pathStart, undefined, crateType );
	wait ( 0.05 );
	c130 notify ( "drop_crate" );
	wait ( 0.05 );

	crateType[2] = c130 thread dropTheCrate( dropSite, dropType, flyHeight, false, undefined, pathStart, undefined, crateType );
	wait ( 0.05 );
	c130 notify ( "drop_crate" );
	wait ( 0.05 );

	crateType[3] = c130 thread dropTheCrate( dropSite, dropType, flyHeight, false, undefined, pathStart, undefined, crateType );	
	wait ( 0.05 );
	c130 notify ( "drop_crate" );

	wait ( 4 );
	c130 delete();
}


dropNuke( dropSite, owner, dropType )
{
	planeHalfDistance = 24000;
	planeFlySpeed = 2000;
	yaw = RandomInt( 360 );
	
	direction = ( 0, yaw, 0 );
	
	flyHeight = self getFlyHeightOffset( dropSite );
	
	pathStart = dropSite + ( AnglesToForward( direction ) * ( -1 * planeHalfDistance ) );
	pathStart = pathStart * ( 1, 1, 0 ) + ( 0, 0, flyHeight );

	pathEnd = dropSite + ( AnglesToForward( direction ) * planeHalfDistance );
	pathEnd = pathEnd * ( 1, 1, 0 ) + ( 0, 0, flyHeight );
	
	d = length( pathStart - pathEnd );
	flyTime = ( d / planeFlySpeed );
	
	c130 = c130Setup( owner, pathStart, pathEnd );
	c130.veh_speed = planeFlySpeed;
	c130.dropType = dropType;
 	c130 PlayLoopSound( "veh_ac130_dist_loop" );

	c130.angles = direction;
	forward = AnglesToForward( direction );
	c130 MoveTo( pathEnd, flyTime, 0, 0 ); 
	
	// TODO: fix this... it's bad.  if we miss our distance (which could happen if plane speed is changed in the future) we stick in this thread forever
	boomPlayed = false;
	minDist = Distance2D( c130.origin, dropSite );
	for(;;)
	{
		dist = Distance2D( c130.origin, dropSite );

		// handle missing our target
		if ( dist < minDist )
			minDist = dist;
		else if ( dist > minDist )
			break;
		
		if ( dist < 256 )
		{
			break;
		}
		else if ( dist < 768 )
		{
			earthquake( 0.15, 1.5, dropSite, 1500 );
			if ( !boomPlayed )
			{
				c130 playSound( "veh_ac130_sonic_boom" );
				//c130 thread stopLoopAfter( 0.5 );
				boomPlayed = true;
			}
		}	
		
		wait ( .05 );	
	}	
	
	c130 thread dropTheCrate( dropSite, dropType, flyHeight, false, "nuke", pathStart );
	wait ( 0.05 );
	c130 notify ( "drop_crate" );

	wait ( 4 );
	c130 delete();
}

stopLoopAfter( delay )
{
	self endon ( "death" );
	
	wait ( delay );
	self stoploopsound();
}


playloopOnEnt( alias )
{
	soundOrg = Spawn( "script_origin", ( 0, 0, 0 ) );
	soundOrg hide();
	soundOrg endon( "death" );
	thread delete_on_death( soundOrg );
	
	soundOrg.origin = self.origin;
	soundOrg.angles = self.angles;
	soundOrg linkto( self );
	
	soundOrg PlayLoopSound( alias );
	
	self waittill( "stop sound" + alias );
	soundOrg stoploopsound( alias );
	soundOrg delete();
}


// spawn C130 at a start node and monitors it
c130Setup( owner, pathStart, pathGoal )
{
	forward = vectorToAngles( pathGoal - pathStart );
	c130 = SpawnPlane( owner, "script_model", pathStart, "compass_objpoint_c130_friendly", "compass_objpoint_c130_enemy" );
	c130 SetModel( "vehicle_ac130_low_mp" );
	
	if ( !IsDefined( c130 ) )
		return;

	//chopper playLoopSound( "littlebird_move" );
	c130.owner = owner;
	c130.team = owner.team;
	level.c130 = c130;
	
	return c130;
}

// spawn helicopter at a start node and monitors it
heliSetup( owner, pathStart, pathGoal )
{
	
	forward = vectorToAngles( pathGoal - pathStart );
	lb = SpawnHelicopter( owner, pathStart, forward, "littlebird_mp", level.littlebird_model );

	if ( !IsDefined( lb ) )
		return;

	lb maps\mp\killstreaks\_helicopter::addToLittleBirdList();
	lb thread maps\mp\killstreaks\_helicopter::removeFromLittleBirdListOnDeath();

	//lb playLoopSound( "littlebird_move" );

	lb.health = 999999; // keep it from dying anywhere in code 
	lb.maxhealth = 500; // this is the health we'll check
	lb.damageTaken = 0; // how much damage has it taken
	lb setCanDamage( true );
	lb.owner = owner;
	lb.team = owner.team;
	lb.isAirdrop = true;
	lb thread watchTimeOut();
	lb thread heli_existence();
	lb thread heliDestroyed();
	lb thread heli_handleDamage();
	lb SetMaxPitchRoll( 45, 85 );	
	lb Vehicle_SetSpeed( 250, 175 );
	lb.heliType = "airdrop";

	lb.specialDamageCallback = ::Callback_VehicleDamage;
	
	return lb;
}

watchTimeOut()
{
	level endon( "game_ended" );
	self endon( "leaving" );	
	self endon( "helicopter_gone" );
	self endon( "death" );
	
	maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( 25.0 );
	
	self notify( "death" );
}

heli_existence()
{
	self waittill_any( "crashing", "leaving" );
	
	self notify( "helicopter_gone" );
}

heli_handleDamage() // self == heli
{
	self endon( "death" );
	level endon( "game_ended" );

	while( true )
	{
		self waittill( "damage", damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon );

		if( IsDefined( self.specialDamageCallback ) )
			self [[self.specialDamageCallback]]( undefined, attacker, damage, iDFlags, meansOfDeath, weapon, point, direction_vec, undefined, undefined, modelName, partName );
	}
}

Callback_VehicleDamage( inflictor, attacker, damage, iDFlags, meansOfDeath, weapon, point, dir, hitLoc, timeOffset, modelIndex, partName )
{
	if( IsDefined( self.alreadyDead ) && self.alreadyDead )
		return;

	if( !IsDefined( attacker ) || attacker == self )
		return;
		
	// don't allow people to destroy things on their team if FF is off
	if( !maps\mp\gametypes\_weapons::friendlyFireCheck( self.owner, attacker ) )
		return;			
		
	if( IsDefined( iDFlags ) && ( iDFlags & level.iDFLAGS_PENETRATION ) )
		self.wasDamagedFromBulletPenetration = true;
	
	self.wasDamaged = true;

	modifiedDamage = damage;

	if ( isPlayer( attacker ) )
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
			modifiedDamage = self.maxhealth + 1;
			break;

		case "sam_projectile_mp":
			self.largeProjectileDamage = true;		
			modifiedDamage = self.maxHealth * 0.5; // takes about 1 burst of sam rockets
			break;

		case "emp_grenade_mp":
			self.largeProjectileDamage = false;
			modifiedDamage = self.maxhealth + 1;
			break;
		}
		
		maps\mp\killstreaks\_killstreaks::killstreakHit( attacker, weapon, self );
	}

	self.damageTaken += modifiedDamage;		

	if( self.damageTaken >= self.maxhealth )
	{
		if ( isPlayer( attacker ) && ( !IsDefined( self.owner ) || attacker != self.owner ) )
		{
			self.alreadyDead = true;
			attacker notify( "destroyed_helicopter" );
			attacker notify( "destroyed_killstreak", weapon );
			thread teamPlayerCardSplash( "callout_destroyed_helicopter", attacker );			
			attacker thread maps\mp\gametypes\_rank::giveRankXP( "kill", 300, weapon, meansOfDeath );			
			attacker thread maps\mp\gametypes\_rank::xpEventPopup( &"SPLASHES_DESTROYED_HELICOPTER" );
			thread maps\mp\gametypes\_missions::vehicleKilled( self.owner, self, undefined, attacker, damage, meansOfDeath, weapon );		
		}

		self notify ( "death" );
	}			
}

heliDestroyed()
{
	self endon( "leaving" );
	self endon( "helicopter_gone" );
	
	self waittill( "death" );
	
	if (! IsDefined(self) )
		return;
		
	self Vehicle_SetSpeed( 25, 5 );
	self thread lbSpin( RandomIntRange(180, 220) );
	
	wait( RandomFloatRange( .5, 1.5 ) );
	
	self notify( "drop_crate" );
	
	lbExplode();
}

// crash explosion
lbExplode()
{
	forward = ( self.origin + ( 0, 0, 1 ) ) - self.origin;
	playfx ( level.chopper_fx["explode"]["death"]["cobra"], self.origin, forward );
	
	// play heli explosion sound
	self playSound( "cobra_helicopter_crash" );
	self notify ( "explode" );

	// decrement the faux vehicle count right before it is deleted this way we know for sure it is gone
	decrementFauxVehicleCount();

	self delete();
}


lbSpin( speed )
{
	self endon( "explode" );
	
	// tail explosion that caused the spinning
	playfxontag( level.chopper_fx["explode"]["medium"], self, "tail_rotor_jnt" );
	playfxontag( level.chopper_fx["fire"]["trail"]["medium"], self, "tail_rotor_jnt" );
	
	self setyawspeed( speed, speed, speed );
	while ( isdefined( self ) )
	{
		self settargetyaw( self.angles[1]+(speed*0.9) );
		wait ( 1 );
	}
}

/**********************************************************
*		 crate trigger functions
***********************************************************/

nukeCaptureThink()
{
	while ( IsDefined( self ) )
	{
		self waittill ( "trigger", player );

		if ( !player isOnGround() )
			continue;
			
		if ( !useHoldThink( player ) )
			continue;
			
		self notify ( "captured", player );
	}
}

crateOtherCaptureThink( useText )
{
	while ( IsDefined( self ) )
	{
		self waittill ( "trigger", player );

		if ( IsDefined( self.owner ) && player == self.owner )
			continue;
			
		if ( !self validateOpenConditions( player ) )
			continue;			

		player.isCapturingCrate = true;
		useEnt = self createUseEnt();
		result = useEnt useHoldThink( player, undefined, useText );
		
		if ( IsDefined( useEnt ) )
			useEnt delete();
		
		if ( !result )
		{
			player.isCapturingCrate = false;
			continue;
		}
			
		player.isCapturingCrate = false;
		self notify ( "captured", player );
	}
}

crateOwnerCaptureThink( useText )
{
	while ( IsDefined( self ) )
	{
		self waittill ( "trigger", player );

		if ( IsDefined( self.owner ) && player != self.owner )
			continue;
				
		if ( !self validateOpenConditions( player ) )
			continue;

		player.isCapturingCrate = true;
		if ( !useHoldThink( player, 500, useText ) )
		{
			player.isCapturingCrate = false;
			continue;
		}
		
		player.isCapturingCrate = false;
		self notify ( "captured", player );
	}
}


validateOpenConditions( opener )
{
	//if ( !opener isOnGround() )
		//return false;	
	
	// don't let a juggernaut pick up a juggernaut crate
	if ( ( self.crateType == "airdrop_juggernaut_recon" || self.crateType == "airdrop_juggernaut" || self.crateType == "airdrop_juggernaut_maniac" ) && 
	   ( opener isJuggernaut() ) )
		return false;
	
	// don't let them open crates while using killstreaks, except being juggernaut
	currWeapon = opener GetCurrentWeapon();
	juggWeapon = ( IsSubStr( currWeapon, "jugg_mp" ) || ( ( currWeapon == "iw5_knifeonly_mp" ) && IsDefined( opener.isJuggernautManiac ) && opener.isJuggernautManiac == true ) );
	if( isKillstreakWeapon( currWeapon ) && !juggWeapon )
		return false;
	if( IsDefined( opener.changingWeapon ) && isKillstreakWeapon( opener.changingWeapon ) && !IsSubStr( opener.changingWeapon, "jugg_mp" ) )
		return false;

	return true;
}

muggerCrateThink( dropType )
{
	self endon ( "death" );
	
	level notify( "airdrop_jackpot_landed", self.origin );
	
	wait(0.5);
	self deleteCrate();
}

killstreakCrateThink( dropType )
{
	self endon ( "death" );
	
	if ( IsDefined( game["strings"][self.crateType + "_hint"] ) )
		crateHint = game["strings"][self.crateType + "_hint"];
	else 
		crateHint = &"PLATFORM_GET_KILLSTREAK";
	
	crateSetupForUse( crateHint, "all", getKillstreakOverheadIcon( self.crateType ) );

	self thread crateOtherCaptureThink();
	self thread crateOwnerCaptureThink();

	for ( ;; )
	{
		self waittill ( "captured", player );
		
		if ( IsDefined( self.owner ) && player != self.owner )
		{
			if ( !level.teamBased || player.team != self.team )
			{
				switch( dropType )
				{
				case "airdrop_assault":
				case "airdrop_support":
				case "airdrop_escort":
				case "airdrop_osprey_gunner":
					player thread maps\mp\gametypes\_missions::genericChallenge( "hijacker_airdrop" );
					player thread hijackNotify( self, "airdrop" );
					break;
				case "airdrop_sentry_minigun":
					player thread maps\mp\gametypes\_missions::genericChallenge( "hijacker_airdrop" );
					player thread hijackNotify( self, "sentry" );
					break;
				case "airdrop_remote_tank":
					player thread maps\mp\gametypes\_missions::genericChallenge( "hijacker_airdrop" );
					player thread hijackNotify( self, "remote_tank" );
					break;
				case "airdrop_mega":
					player thread maps\mp\gametypes\_missions::genericChallenge( "hijacker_airdrop_mega" );
					player thread hijackNotify( self, "emergency_airdrop" );
					break;
				}
			}
			else
			{
				self.owner thread maps\mp\gametypes\_rank::giveRankXP( "killstreak_giveaway", Int(( maps\mp\killstreaks\_killstreaks::getStreakCost( self.crateType ) / 10 ) * 50) );
				//self.owner maps\mp\gametypes\_hud_message::playerCardSplashNotify( "giveaway_airdrop", player );
				self.owner thread maps\mp\gametypes\_hud_message::SplashNotifyDelayed( "sharepackage", Int(( maps\mp\killstreaks\_killstreaks::getStreakCost( self.crateType ) / 10 ) * 50) );
			}
		}		
	
		player playLocalSound( "ammo_crate_use" );
		player thread maps\mp\killstreaks\_killstreaks::giveKillstreak( self.crateType, false, false, self.owner );

		// commented out because we handle this in _killstreaks::giveKillstreak as a mini-splash
		//player maps\mp\gametypes\_hud_message::killstreakSplashNotify( self.crateType, undefined );
		
		self deleteCrate();
	}
}

//NOT USED
lasedStrikeCrateThink( dropType )
{
	self endon ( "death" );

	crateSetupForUse( game["strings"]["marker_hint"], "all", getKillstreakOverheadIcon( self.crateType ) );

	level.lasedStrikeCrateActive = true;
	self thread crateOwnerCaptureThink();
	self thread crateOtherCaptureThink();

	numCount = 0;
	
	remote = self thread maps\mp\killstreaks\_lasedStrike::spawnRemote( self.owner );
	level.lasedStrikeDrone = remote;
	level.lasedStrikeActive = true;
	
	level.soflamCrate = self;
	
	for ( ;; )
	{
		self waittill ( "captured", player );

		if ( IsDefined( self.owner ) && player != self.owner )
		{
			if ( !level.teamBased || player.team != self.team )
			{
				self deleteCrate();
			}
		}
		
		//self DisablePlayerUse( player );
		self maps\mp\killstreaks\_airdrop::setUsableByTeam( self.team );
	
		player thread maps\mp\killstreaks\_lasedStrike::giveMarker();
		
		numCount++;
		
		if ( numCount >= 5 )
			self deleteCrate();
	}
}


nukeCrateThink( dropType )
{
	self endon ( "death" );
	
	crateSetupForUse( &"PLATFORM_CALL_NUKE", "nukeDrop", getKillstreakOverheadIcon( self.crateType ) );

	self thread nukeCaptureThink();

	for ( ;; )
	{
		self waittill ( "captured", player );
		
		player thread [[ level.killstreakFuncs[ self.crateType ] ]]( level.gtnw );
		level notify( "nukeCaptured", player );
		
		if ( IsDefined( level.gtnw ) && level.gtnw )
			player.capturedNuke = 1;
		
		player playLocalSound( "ammo_crate_use" );
		self deleteCrate();
	}
}


juggernautCrateThink( dropType )
{
	self endon ( "death" );

	crateSetupForUse( game["strings"][self.crateType + "_hint"], "all", getKillstreakOverheadIcon( self.crateType ) );

	self thread crateOtherCaptureThink();
	self thread crateOwnerCaptureThink();

	for ( ;; )
	{
		self waittill ( "captured", player );
		
		if ( IsDefined( self.owner ) && player != self.owner )
		{
			if ( !level.teamBased || player.team != self.team )
			{
				player thread hijackNotify( self, "juggernaut" );
			}
			else
			{
				self.owner thread maps\mp\gametypes\_rank::giveRankXP( "killstreak_giveaway", Int( maps\mp\killstreaks\_killstreaks::getStreakCost( self.crateType ) / 10 ) * 50 );
				self.owner maps\mp\gametypes\_hud_message::playerCardSplashNotify( "giveaway_juggernaut", player );
			}
		}		
	
		player playLocalSound( "ammo_crate_use" );
		
		juggType = "juggernaut";
		switch( self.crateType )
		{
		case "airdrop_juggernaut":
			juggType = "juggernaut";
			break;
		case "airdrop_juggernaut_recon":
			juggType = "juggernaut_recon";
			break;
		case "airdrop_juggernaut_maniac":
			juggType = "juggernaut_maniac";
			break;
		}
		player thread maps\mp\killstreaks\_juggernaut::giveJuggernaut( juggType );
		
		self deleteCrate();
	}
}


sentryCrateThink( dropType )
{
	self endon ( "death" );

	crateSetupForUse( game["strings"]["sentry_hint"], "all", getKillstreakOverheadIcon( self.crateType ) );

	self thread crateOtherCaptureThink();
	self thread crateOwnerCaptureThink();

	for ( ;; )
	{
		self waittill ( "captured", player );
		
		if ( IsDefined( self.owner ) && player != self.owner )
		{
			if ( !level.teamBased || player.team != self.team )
			{
				if ( isSubStr(dropType, "airdrop_sentry" ) )
					player thread hijackNotify( self, "sentry" );
				else
					player thread hijackNotify( self, "emergency_airdrop" );
			}
			else
			{
				self.owner thread maps\mp\gametypes\_rank::giveRankXP( "killstreak_giveaway", Int( maps\mp\killstreaks\_killstreaks::getStreakCost( "sentry" ) / 10 ) * 50 );
				self.owner maps\mp\gametypes\_hud_message::playerCardSplashNotify( "giveaway_sentry", player );
			}
		}		
	
		player playLocalSound( "ammo_crate_use" );
		player thread sentryUseTracker();
		
		self deleteCrate();
	}
}


deleteCrate()
{
	self notify( "crate_deleting" );
	
	if ( IsDefined( self.objIdFriendly ) )
		_objective_delete( self.objIdFriendly );

	if ( IsDefined( self.objIdEnemy ) )
	{
		if( level.multiTeamBased )
		{
			foreach( obj in self.objIdEnemy )
			{
				_objective_delete( obj );
			}
		}
		else
		{
			_objective_delete( self.objIdEnemy );
		}
	}

	if ( IsDefined( self.bomb ) && IsDefined( self.bomb.killcamEnt ) )
		self.bomb.killcamEnt delete();

	if ( IsDefined( self.bomb ) )
		self.bomb delete();

	if ( IsDefined( self.killCamEnt ) )
		self.killCamEnt delete();
	
	if ( IsDefined( self.dropType ) )
		PlayFX( getfx( "airdrop_crate_destroy" ), self.origin );
	

	self delete();
}

sentryUseTracker()
{
	if ( !self maps\mp\killstreaks\_autosentry::giveSentry( "sentry_minigun" ) )
		self maps\mp\killstreaks\_killstreaks::giveKillstreak( "sentry" );
}


hijackNotify( crate, crateType )
{
	self notify( "hijacker", crateType, crate.owner );
}


refillAmmo( refillEquipment )
{
	weaponList = self GetWeaponsListAll();
	
	if ( refillEquipment )
	{
		if ( self _hasPerk( "specialty_tacticalinsertion" ) && self getAmmoCount( "flare_mp" ) < 1 )
			self givePerkOffhand( "specialty_tacticalinsertion", false );	
		
		if ( self _hasPerk( "specialty_scrambler" ) && self getAmmoCount( "scrambler_mp" ) < 1 )
			self givePerkOffhand( "specialty_scrambler", false );	
		
		if ( self _hasPerk( "specialty_portable_radar" ) && self getAmmoCount( "portable_radar_mp" ) < 1 )
			self givePerkOffhand( "specialty_portable_radar", false );	
	}
		
	foreach ( weaponName in weaponList )
	{
		if ( isSubStr( weaponName, "grenade" ) || ( GetSubStr( weaponName, 0, 2 ) == "gl" ) )
		{
			if ( !refillEquipment || self getAmmoCount( weaponName ) >= 1 )
				continue;
		} 
		
		self giveMaxAmmo( weaponName );
	}
}


/**********************************************************
*		 Capture crate functions
***********************************************************/
useHoldThink( player, useTime, useText ) 
{
	if ( IsPlayer( player ) )
		player playerLinkTo( self );
	else
		player LinkTo( self );
	player playerLinkedOffsetEnable();
    
    player _disableWeapon();
    
    self.curProgress = 0;
    self.inUse = true;
    self.useRate = 0;
    
	if ( IsDefined( useTime ) )
		self.useTime = useTime;
	else
		self.useTime = 3000;
    
	if ( IsPlayer( player ) )
	    player thread personalUseBar( self, useText );
   
    result = useHoldThinkLoop( player );
	assert ( IsDefined( result ) );
    
    if ( isAlive( player ) )
    {
        player _enableWeapon();
        player unlink();
    }
    
    if ( !IsDefined( self ) )
    	return false;

    self.inUse = false;
	self.curProgress = 0;

	return ( result );
}


personalUseBar( object, useText )
{
    self endon( "disconnect" );
    
    useBar = createPrimaryProgressBar( 0, 25 );
    useBarText = createPrimaryProgressBarText( 0, 25 );
    if ( !IsDefined( useText ) )
    	useText = &"KILLSTREAKS_CAPTURING_CRATE";
    useBarText setText( useText );

    lastRate = -1;
    while ( isReallyAlive( self ) && IsDefined( object ) && object.inUse && !level.gameEnded )
    {
        if ( lastRate != object.useRate )
        {
            if( object.curProgress > object.useTime)
                object.curProgress = object.useTime;
               
            useBar updateBar( object.curProgress / object.useTime, (1000 / object.useTime) * object.useRate );

            if ( !object.useRate )
            {
                useBar hideElem();
                useBarText hideElem();
            }
            else
            {
                useBar showElem();
                useBarText showElem();
            }
        }    
        lastRate = object.useRate;
        wait ( 0.05 );
    }
    
    useBar destroyElem();
    useBarText destroyElem();
}

useHoldThinkLoop( player )
{
    while( !level.gameEnded && IsDefined( self ) && isReallyAlive( player ) && player useButtonPressed() && self.curProgress < self.useTime )
    {
        self.curProgress += (50 * self.useRate);
       
       	if ( IsDefined(self.objectiveScaler) )
        	self.useRate = 1 * self.objectiveScaler;
		else
			self.useRate = 1;

        if ( self.curProgress >= self.useTime )
            return ( isReallyAlive( player ) );
       
        wait 0.05;
    } 
    
    return false;
}

isAirdropMarker( weaponName )
{
	switch ( weaponName )
	{
		case "airdrop_marker_mp":
		case "airdrop_mega_marker_mp":
		case "airdrop_sentry_marker_mp":
		case "airdrop_juggernaut_mp":
		case "airdrop_juggernaut_def_mp":
		case "airdrop_tank_marker_mp":
		case "airdrop_escort_marker_mp":
			return true;
		default:
			return false;
	}
}


createUseEnt()
{
	useEnt = Spawn( "script_origin", self.origin );
	useEnt.curProgress = 0;
	useEnt.useTime = 0;
	useEnt.useRate = 3000;
	useEnt.inUse = false;

	useEnt thread deleteUseEnt( self );

	return ( useEnt );
}


deleteUseEnt( owner )
{
	self endon ( "death" );
	
	owner waittill ( "death" );
	
	self delete();
}


airdropDetonateOnStuck()
{
	self endon ( "death" );
	
	self waittill( "missile_stuck" );
	
	self detonate();
}