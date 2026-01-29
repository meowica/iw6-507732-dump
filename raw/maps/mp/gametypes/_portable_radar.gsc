#include maps\mp\_utility;
#include common_scripts\utility;

GENERATOR_TYPE = "portable_radar";

init()
{
	config = SpawnStruct();
	config.generatorType = GENERATOR_TYPE;
	config.weaponName = "portable_radar_mp";
	config.targetType = "enemy"; // valid types { "friendly", "enemy", "all" }
	// callbacks are in the format: generator callbackFunc( player, generatorType )
	config.onDeployCallback = ::onCreatePortableRadar;
	config.onDestroyCallback = ::onDestroyPortableRadar;
	// callbacks are in the format: player callbackFunc()
	config.onEnterCallback = ::onEnterPortableRadar;
	config.onExitCallback = ::onExitPortableRadar;
	// config.timeLimit = undefined;
	config.health = 100;
	config.placementZTolerance = 40;
	config.placedModel = "weapon_radar";
	config.bombSquadModel = "weapon_radar_bombsquad";
	config.damageFeedback = "portable_radar";
	config.useHintString = &"KILLSTREAK_PATCH_PICKUP_PORTABLE_RADAR";
	config.headIconHeight = 25;
	config.useSound = "scavenger_pack_pickup";
	config.aoeRadius = 512;
	
	level.portableAOEgeneratorSettings[ GENERATOR_TYPE ] = config;
}

onCreatePortableRadar( owner, generatorType )	// self == generator
{
	self MakePortableRadar( owner );
	self thread portableRadarBeepSounds();
}

portableRadarBeepSounds()
{
	self endon( "death" );
	level endon ( "game_ended" );

	for ( ;; )
	{
		wait ( 2.0 );
		self playSound( "sentry_gun_beep" );
	}
}

onDestroyPortableRadar( owner, generatorType )
{
	self playsound( "sentry_explode" );
	self.deathEffect = PlayFX( getfx( "equipment_explode" ), self.origin );
}

onEnterPortableRadar()
{
	self.inPlayerPortableRadar = self.owner;
}

onExitPortableRadar()
{
	self.inPlayerPortableRadar = undefined;
}

setPortableRadar()
{
	maps\mp\killstreaks\_portableAOEgenerator::setWeapon( GENERATOR_TYPE );
}

unsetPortableRadar()
{
	maps\mp\killstreaks\_portableAOEgenerator::unsetWeapon( GENERATOR_TYPE );
}

// !!! hack
// 2013-03-25 wsh
// Leave this in for juggernaut legacy support
// not sure what it's for
deletePortableRadar( portable_radar )
{
	if ( !isDefined( portable_radar ) )
		return;
	
	foreach( player in level.players )
	{
		if( IsDefined( player ) )
			player.inPlayerPortableRadar = undefined;
	}

	portable_radar notify( "death" );
	portable_radar Delete();
	
	self.deployedPortableRadar = undefined;
}