#include maps\mp\_utility;
#include common_scripts\utility;

GENERATOR_TYPE = "scrambler";

init()
{
	config = SpawnStruct();
	config.generatorType = GENERATOR_TYPE;
	config.weaponName = "scrambler_mp";
	config.targetType = "enemy"; // valid types { "friendly", "enemy", "all" }
	// callbacks are in the format: generator callbackFunc( player, generatorType )
	config.onDeployCallback = ::onCreateScrambler;
	config.onDestroyCallback = ::onDestroyScrambler;
	// callbacks are in the format: player callbackFunc()
	config.onEnterCallback = ::onEnterScrambler;
	config.onExitCallback = ::onExitScrambler;
	// config.timeLimit = undefined;
	config.health = 100;
	config.placementZTolerance = 40;
	config.placedModel = "weapon_jammer";
	config.bombSquadModel = "weapon_jammer_bombsquad";
	config.damageFeedback = "scrambler";
	config.useHintString = &"MP_PATCH_PICKUP_SCRAMBLER";
	config.headIconHeight = 25;
	config.useSound = "scavenger_pack_pickup";
	config.aoeRadius = 512;
	
	level.portableAOEgeneratorSettings[ GENERATOR_TYPE ] = config;
}

onCreateScrambler( owner, generatorType )	// self == generator
{
	self MakeScrambler( owner );
	
	self thread scramblerBeepSounds();
}

scramblerBeepSounds()
{
	self endon( "death" );
	level endon ( "game_ended" );

	for ( ;; )
	{
		wait ( 3.0 );
		self playSound( "scrambler_beep" );
	}
}

// for now, let the particular equipment handle its death sequence
// the scrambler and portable radar are simple,
// but the trophy system's is pretty complex
onDestroyScrambler( owner, generatorType )	// self == scrambler
{
	// TODO: get sound and fx
	self playsound( "sentry_explode" );
	self.deathEffect = PlayFX( getfx( "equipment_explode" ), self.origin );
}

onEnterScrambler()
{
	self givePerk( "specialty_blindeye", false );
	self.scramProxyPerk = true;
}

onExitScrambler()
{
	// did we get the perk from the scram proxy
	if( IsDefined( self.scramProxyPerk ) )
	{
		// now make sure they didn't earn it using the specialist strike package
		if( !self maps\mp\killstreaks\_perkstreaks::isPerkStreakOn( "specialty_blindeye_ks" ) )
			self _unsetPerk( "specialty_blindeye" );

		self.scramProxyPerk = undefined;
	}
}

setScrambler()
{
	maps\mp\killstreaks\_portableAOEgenerator::setWeapon( GENERATOR_TYPE );
}

unsetScrambler()
{
	maps\mp\killstreaks\_portableAOEgenerator::unsetWeapon( GENERATOR_TYPE );
}