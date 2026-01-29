#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\perks\_perkfunctions;

PERK_STRING_TABLE =	"mp/perkTable.csv";
PERK_REF_COLUMN =	1;
PERK_NAME_COLUMN =	2;
PERK_ICON_COLUMN =	3;

init()
{
	level.perkFuncs = [];

	//level.spawnGlowSplat = loadfx( "fx/misc/flare_ambient_destroy" );

	level.spawnGlowModel["enemy"] = "mil_emergency_flare_mp";
	level.spawnGlowModel["friendly"] = "mil_emergency_flare_mp";
	level.spawnGlow["enemy"] = loadfx( "fx/misc/flare_ambient" );
	level.spawnGlow["friendly"] = loadfx( "fx/misc/flare_ambient_green" );
	level.c4Death = loadfx( "fx/explosions/javelin_explosion" );

	level.spawnFire = loadfx( "fx/props/barrelexp" );

	level._effect["ricochet"] = loadfx( "fx/impacts/large_metalhit_1" );

	// perks that currently only exist in script: these will error if passed to "setPerk", etc... CASE SENSITIVE! must be lower
	level.scriptPerks = [];
	level.perkSetFuncs = [];
	level.perkUnsetFuncs = [];
	level.fauxPerks = [];

	level.scriptPerks["specialty_blastshield"] = true;
	level.scriptPerks["_specialty_blastshield"] = true;
	level.scriptPerks["specialty_akimbo"] = true;
	level.scriptPerks["specialty_falldamage"] = true;
	level.scriptPerks["specialty_shield"] = true;
	level.scriptPerks["specialty_feigndeath"] = true;
	level.scriptPerks["specialty_shellshock"] = true;
	level.scriptPerks["specialty_delaymine"] = true;
	level.scriptPerks["specialty_localjammer"] = true;
	level.scriptPerks["specialty_thermal"] = true;
	level.scriptPerks["specialty_blackbox"] = true;
	level.scriptPerks["specialty_steelnerves"] = true;
	level.scriptPerks["specialty_flashgrenade"] = true;
	level.scriptPerks["specialty_smokegrenade"] = true;
	level.scriptPerks["specialty_concussiongrenade"] = true;
	level.scriptPerks["specialty_challenger"] = true;
	level.scriptPerks["specialty_saboteur"] = true;
	level.scriptPerks["specialty_endgame"] = true;
	level.scriptPerks["specialty_rearview"] = true;
	level.scriptPerks["specialty_hardline"] = true;
	level.scriptPerks["specialty_ac130"] = true;
	level.scriptPerks["specialty_sentry_minigun"] = true;
	level.scriptPerks["specialty_predator_missile"] = true;
	level.scriptPerks["specialty_helicopter_minigun"] = true;
	level.scriptPerks["specialty_tank"] = true;
	level.scriptPerks["specialty_precision_airstrike"] = true;
	level.scriptPerks["specialty_onemanarmy"] = true;
	level.scriptPerks["specialty_littlebird_support"] = true;
	level.scriptPerks["specialty_primarydeath"] = true;
	level.scriptPerks["specialty_secondarybling"] = true;
	level.scriptPerks["specialty_explosivedamage"] = true;
	level.scriptPerks["specialty_laststandoffhand"] = true;
	level.scriptPerks["specialty_dangerclose"] = true;
	level.scriptPerks["specialty_luckycharm"] = true;
	level.scriptPerks["specialty_hardjack"] = true;
	level.scriptPerks["specialty_extraspecialduration"] = true;
	level.scriptPerks["specialty_rollover"] = true;
	level.scriptPerks["specialty_armorpiercing"] = true;
	level.scriptPerks["specialty_omaquickchange"] = true;
	level.scriptPerks["_specialty_rearview"] = true;
	level.scriptPerks["_specialty_onemanarmy"] = true;
	level.scriptPerks["specialty_steadyaimpro"] = true;
	level.scriptPerks["specialty_stun_resistance"] = true;
	level.scriptPerks["specialty_double_load"] = true;
	level.scriptPerks["specialty_hard_shell"] = true;
	level.scriptPerks["specialty_regenfaster"] = true;
	level.scriptPerks["specialty_twoprimaries"] = true;
	level.scriptPerks["specialty_autospot"] = true;
	level.scriptPerks["specialty_overkillpro"] = true;
	level.scriptPerks["specialty_anytwo"] = true;
	level.scriptPerks["specialty_assists"] = true;
	level.scriptPerks["specialty_fasterlockon"] = true;
	level.scriptPerks["specialty_paint"] = true;
	level.scriptPerks["specialty_paint_pro"] = true;
	level.scriptPerks["specialty_refill_grenades"] = true;
	level.scriptPerks["specialty_refill_ammo"] = true;
	level.scriptPerks["specialty_combat_speed"] = true;
	level.scriptPerks["specialty_extra_equipment"] = true;
	level.scriptPerks["specialty_extra_deadly"] = true;
	level.scriptPerks["specialty_moreHealth"] = true;

	level.fauxPerks["specialty_shield"] = true;

	// weapon buffs
	level.scriptPerks["specialty_marksman"] = true;
	level.scriptPerks["specialty_sharp_focus"] = true;
	level.scriptPerks["specialty_bling"] = true;
	level.scriptPerks["specialty_moredamage"] = true;

	// death streaks
	level.scriptPerks["specialty_copycat"] = true;
	level.scriptPerks["specialty_combathigh"] = true;
	level.scriptPerks["specialty_finalstand"] = true;
	level.scriptPerks["specialty_c4death"] = true;
	level.scriptPerks["specialty_juiced"] = true;
	level.scriptPerks["specialty_revenge"] = true;
	level.scriptPerks["specialty_light_armor"] = true;
	level.scriptPerks["specialty_carepackage"] = true;
	level.scriptPerks["specialty_stopping_power"] = true;
	level.scriptPerks["specialty_uav"] = true;

	// equipment
	level.scriptPerks["bouncingbetty_mp"] = true;
	level.scriptPerks["c4_mp"] = true;
	level.scriptPerks["claymore_mp"] = true;
	level.scriptPerks["frag_grenade_mp"] = true;
	level.scriptPerks["semtex_mp"] = true;
	level.scriptPerks["throwingknife_mp"] = true;
	level.scriptPerks["thermobaric_grenade_mp"] = true;
	level.scriptPerks["mortar_shell_mp"] = true;

	// special grenades
	level.scriptPerks["concussion_grenade_mp"] = true;
	level.scriptPerks["flash_grenade_mp"] = true;
	level.scriptPerks["smoke_grenade_mp"] = true;
	level.scriptPerks["emp_grenade_mp"] = true;
	level.scriptPerks["specialty_portable_radar"] = true;
	level.scriptPerks["specialty_scrambler"] = true;
	level.scriptPerks["specialty_tacticalinsertion"] = true;
	level.scriptPerks["trophy_mp"] = true;
	level.scriptPerks["motion_sensor_mp"] = true;

	// specialty_null is assigned as a perk sometimes and it's not a code perk
	level.scriptPerks["specialty_null"] = true;

	level.perkSetFuncs["specialty_blastshield"] = ::setBlastShield;
	level.perkUnsetFuncs["specialty_blastshield"] = ::unsetBlastShield;

	level.perkSetFuncs["specialty_falldamage"] = ::setFreefall;
	level.perkUnsetFuncs["specialty_falldamage"] = ::unsetFreefall;

	level.perkSetFuncs["specialty_localjammer"] = ::setLocalJammer;
	level.perkUnsetFuncs["specialty_localjammer"] = ::unsetLocalJammer;

	level.perkSetFuncs["specialty_thermal"] = ::setThermal;
	level.perkUnsetFuncs["specialty_thermal"] = ::unsetThermal;

	level.perkSetFuncs["specialty_blackbox"] = ::setBlackBox;
	level.perkUnsetFuncs["specialty_blackbox"] = ::unsetBlackBox;

	level.perkSetFuncs["specialty_lightweight"] = ::setLightWeight;
	level.perkUnsetFuncs["specialty_lightweight"] = ::unsetLightWeight;

	level.perkSetFuncs["specialty_steelnerves"] = ::setSteelNerves;
	level.perkUnsetFuncs["specialty_steelnerves"] = ::unsetSteelNerves;

	level.perkSetFuncs["specialty_delaymine"] = ::setDelayMine;
	level.perkUnsetFuncs["specialty_delaymine"] = ::unsetDelayMine;

	level.perkSetFuncs["specialty_challenger"] = ::setChallenger;
	level.perkUnsetFuncs["specialty_challenger"] = ::unsetChallenger;

	level.perkSetFuncs["specialty_saboteur"] = ::setSaboteur;
	level.perkUnsetFuncs["specialty_saboteur"] = ::unsetSaboteur;

	level.perkSetFuncs["specialty_endgame"] = ::setEndGame;
	level.perkUnsetFuncs["specialty_endgame"] = ::unsetEndGame;

	level.perkSetFuncs["specialty_rearview"] = ::setRearView;
	level.perkUnsetFuncs["specialty_rearview"] = ::unsetRearView;

	level.perkSetFuncs["specialty_ac130"] = ::setAC130;
	level.perkUnsetFuncs["specialty_ac130"] = ::unsetAC130;

	level.perkSetFuncs["specialty_sentry_minigun"] = ::setSentryMinigun;
	level.perkUnsetFuncs["specialty_sentry_minigun"] = ::unsetSentryMinigun;

	level.perkSetFuncs["specialty_predator_missile"] = ::setPredatorMissile;
	level.perkUnsetFuncs["specialty_predator_missile"] = ::unsetPredatorMissile;

	level.perkSetFuncs["specialty_tank"] = ::setTank;
	level.perkUnsetFuncs["specialty_tank"] = ::unsetTank;

	level.perkSetFuncs["specialty_precision_airstrike"] = ::setPrecision_airstrike;
	level.perkUnsetFuncs["specialty_precision_airstrike"] = ::unsetPrecision_airstrike;

	level.perkSetFuncs["specialty_helicopter_minigun"] = ::setHelicopterMinigun;
	level.perkUnsetFuncs["specialty_helicopter_minigun"] = ::unsetHelicopterMinigun;

	level.perkSetFuncs["specialty_onemanarmy"] = ::setOneManArmy;
	level.perkUnsetFuncs["specialty_onemanarmy"] = ::unsetOneManArmy;

	level.perkSetFuncs["specialty_littlebird_support"] = ::setLittlebirdSupport;
	level.perkUnsetFuncs["specialty_littlebird_support"] = ::unsetLittlebirdSupport;

	level.perkSetFuncs["specialty_tacticalinsertion"] = ::setTacticalInsertion;
	level.perkUnsetFuncs["specialty_tacticalinsertion"] = ::unsetTacticalInsertion;

	level.perkSetFuncs["specialty_scrambler"] = maps\mp\gametypes\_scrambler::setScrambler;
	level.perkUnsetFuncs["specialty_scrambler"] = maps\mp\gametypes\_scrambler::unsetScrambler;

	level.perkSetFuncs["specialty_portable_radar"] = maps\mp\gametypes\_portable_radar::setPortableRadar;
	level.perkUnsetFuncs["specialty_portable_radar"] = maps\mp\gametypes\_portable_radar::unsetPortableRadar;

	level.perkSetFuncs["specialty_steadyaimpro"] = ::setSteadyAimPro;
	level.perkUnsetFuncs["specialty_steadyaimpro"] = ::unsetSteadyAimPro;

	level.perkSetFuncs["specialty_stun_resistance"] = ::setStunResistance;
	level.perkUnsetFuncs["specialty_stun_resistance"] = ::unsetStunResistance;

	level.perkSetFuncs["specialty_marksman"] = ::setMarksman;
	level.perkUnsetFuncs["specialty_marksman"] = ::unsetMarksman;

	level.perkSetFuncs["specialty_double_load"] = ::setDoubleLoad;
	level.perkUnsetFuncs["specialty_double_load"] = ::unsetDoubleLoad;

	level.perkSetFuncs["specialty_sharp_focus"] = ::setSharpFocus;
	level.perkUnsetFuncs["specialty_sharp_focus"] = ::unsetSharpFocus;

	level.perkSetFuncs["specialty_hard_shell"] = ::setHardShell;
	level.perkUnsetFuncs["specialty_hard_shell"] = ::unsetHardShell;

	level.perkSetFuncs["specialty_regenfaster"] = ::setRegenFaster;
	level.perkUnsetFuncs["specialty_regenfaster"] = ::unsetRegenFaster;

	level.perkSetFuncs["specialty_autospot"] = ::setAutoSpot;
	level.perkUnsetFuncs["specialty_autospot"] = ::unsetAutoSpot;

	level.perkSetFuncs["specialty_empimmune"] = ::setEmpImmune;
	level.perkUnsetFuncs["specialty_empimmune"] = ::unsetEmpImmune;

	level.perkSetFuncs["specialty_overkill_pro"] = ::setOverkillPro;
	level.perkUnsetFuncs["specialty_overkill_pro"] = ::unsetOverkillPro;

	level.perkSetFuncs["specialty_refill_grenades"] = ::setRefillGrenades;
	level.perkUnsetFuncs["specialty_refill_grenades"] = ::unsetRefillGrenades;

	level.perkSetFuncs["specialty_refill_ammo"] = ::setRefillAmmo;
	level.perkUnsetFuncs["specialty_refill_ammo"] = ::unsetRefillAmmo;
	
	level.perkSetFuncs["specialty_combat_speed"] = ::setCombatSpeed;
	level.perkUnsetFuncs["specialty_combat_speed"] = ::unsetCombatSpeed;

	// death streaks
	level.perkSetFuncs["specialty_combathigh"] = ::setCombatHigh;
	level.perkUnsetFuncs["specialty_combathigh"] = ::unsetCombatHigh;

	level.perkSetFuncs["specialty_light_armor"] = ::setLightArmor;
	level.perkUnsetFuncs["specialty_light_armor"] = ::unsetLightArmor;

	level.perkSetFuncs["specialty_revenge"] = ::setRevenge;
	level.perkUnsetFuncs["specialty_revenge"] = ::unsetRevenge;

	level.perkSetFuncs["specialty_c4death"] = ::setC4Death;
	level.perkUnsetFuncs["specialty_c4death"] = ::unsetC4Death;

	level.perkSetFuncs["specialty_finalstand"] = ::setFinalStand;
	level.perkUnsetFuncs["specialty_finalstand"] = ::unsetFinalStand;

	level.perkSetFuncs["specialty_juiced"] = ::setJuiced;
	level.perkUnsetFuncs["specialty_juiced"] = ::unsetJuiced;

	level.perkSetFuncs["specialty_carepackage"] = ::setCarePackage;
	level.perkUnsetFuncs["specialty_carepackage"] = ::unsetCarePackage;

	level.perkSetFuncs["specialty_stopping_power"] = ::setStoppingPower;
	level.perkUnsetFuncs["specialty_stopping_power"] = ::unsetStoppingPower;

	level.perkSetFuncs["specialty_uav"] = ::setUAV;
	level.perkUnsetFuncs["specialty_uav"] = ::unsetUAV;
	// end death streaks

	initPerkDvars();

	level thread onPlayerConnect();
}

validatePerk( perkIndex, perkName )
{
	if ( getDvarInt ( "scr_game_perks" ) == 0 )
	{
		if ( tableLookup( "mp/perkTable.csv", 1, perkName, 5 ) != "equipment" )
			return "specialty_null";
	}

	/* Validation disabled for now
	if ( tableLookup( "mp/perkTable.csv", 1, perkName, 5 ) != ("perk"+perkIndex) )
	{
		println( "^1Warning: (" + self.name + ") Perk " + perkName + " is not allowed for perk slot index " + perkIndex + "; replacing with no perk" );
		return "specialty_null";
	}
	*/

	return perkName;
}

onPlayerConnect()
{
	for(;;)
	{
		level waittill( "connected", player );
		player thread onPlayerSpawned();
	}
}

onPlayerSpawned()
{
	self endon( "disconnect" );

	self.perks = [];
	self.perksPerkName = [];
	self.perksUseSlot = [];
	self.perksPerkPower = [];
	
	self.weaponList = [];
	self.omaClassChanged = false;

	for( ;; )
	{
		self waittill( "spawned_player" );

		self.omaClassChanged = false;
		//self thread maps\mp\gametypes\_scrambler::scramblerProximityTracker();
		self thread maps\mp\killstreaks\_portableAOEgenerator::generatorAOETracker();
	}
}


cac_modified_damage( victim, attacker, damage, sMeansOfDeath, sWeapon, impactPoint, impactDir, sHitLoc, inflictor )
{
	assert( isPlayer( victim ) || isAgent( victim ) );
	assert( IsDefined( victim.team ) );

	damageAdd = 0;

	// NOTE: not sure why this was here, commenting out for now
	//if( ( victim.xpScaler == 2 && IsDefined( attacker ) ) && ( isPlayer( attacker ) || attacker.classname == "script_vehicle" ) )
	//	damageAdd += 200;

	if( isBulletDamage( sMeansOfDeath ) )
	{
		assert( IsDefined( attacker ) );

		// show the victim on the minimap for N seconds
		if( IsPlayer( attacker ) && attacker _hasPerk( "specialty_paint_pro" ) && !isKillstreakWeapon( sWeapon ) )
		{
			// make sure they aren't already painted before we process the challenge
			if( !victim isPainted() )
				attacker maps\mp\gametypes\_missions::processChallenge( "ch_bulletpaint" );

			victim thread maps\mp\perks\_perkfunctions::setPainted();
		}
		
		// TODO: this needs to be fixed in code where the silencer being on the sniper rifle adheres to the damage value reduction for the silencer attachment gdt entry
		////20% damage reduction for using silencer on sniper since range reduction has no effect on snipers. 
		//if( IsPlayer( attacker ) && IsDefined( sWeapon ) && getWeaponClass( sWeapon ) == "weapon_sniper" && isSubStr( sWeapon, "silencer" ) )
		//	damage *= 0.75;

		// stopping power and armor vest cancel each other out
		if( IsPlayer( attacker ) && 
			( attacker _hasPerk( "specialty_bulletdamage" ) && victim _hasPerk( "specialty_armorvest" ) ) )
		{
			// purposely left empty
		}
		// if the attacker has the stopping power or has the more damage weapon buff
		else if( IsPlayer( attacker ) && 
				 ( attacker _hasPerk( "specialty_bulletdamage" ) || attacker _hasPerk( "specialty_moredamage" ) ) ) 
		{
			damageAdd += damage * level.bulletDamageMod;
		}
		// if the victim has armor vest take some damage off
		else if ( victim _hasPerk( "specialty_armorvest" ) )
		{
			damageAdd -= damage * level.armorVestMod;
		}
		
		// JC-ToDo: This seems like the wrong way to implement specialty_morehealth. For now ignore giant damage amounts that should kill the player.
		// for perk morehealth. Don't ignore bullet damage that is very high
		if ( victim _hasPerk( "specialty_moreHealth" ) && victim.health == victim.maxHealth && damage <= 133 )
		{	
			//small amount of damage for first shot
			damage = 5; 
		}

		// let's handle juggernaut damaging here after all of the damageAdd math has happened
		if( victim isJuggernaut() )
		{
			if( IsDefined( self.isJuggernautManiac ) && self.isJuggernautManiac )
			{
				damage *= level.juggernautManiacMod;
				damageAdd *= level.juggernautManiacMod;
			}
			else
			{
				damage *= level.juggernautMod;
				damageAdd *= level.juggernautMod;
			}

			// TODO: maybe bring this back if we think jugg needs a good counter
			//// player shooting jugg
			//if( IsPlayer( attacker ) )
			//{
			//	if( weaponInheritsPerks( sWeapon ) )
			//	{
			//		if( attacker _hasPerk( "specialty_armorpiercing" ) )
			//		{
			//			damage = damage * level.armorPiercingMod;
			//		}
			//	}
			//}
		}
	}
	else if( IsExplosiveDamageMOD( sMeansOfDeath ) )
	{
		// show the victim on the minimap for N seconds
		if ( isPlayer(attacker) )
		{
			
			if( attacker != victim && 
				( attacker IsItemUnlocked( "specialty_paint" ) && attacker _hasPerk( "specialty_paint" ) )
				&& !isKillstreakWeapon( sWeapon ) )
			{
				if( !victim isPainted() )
					attacker maps\mp\gametypes\_missions::processChallenge( "ch_paint_pro" );		
	
				victim thread maps\mp\perks\_perkfunctions::setPainted();
			}
		}

		if( isPlayer( attacker ) && 
		    weaponInheritsPerks( sWeapon ) &&
			( attacker _hasPerk( "specialty_explosivedamage" ) && victim _hasPerk( "_specialty_blastshield" ) ) )
		{
			// purposely left empty
		}
		else if( isPlayer( attacker ) && 
				 weaponInheritsPerks( sWeapon ) &&
				 attacker _hasPerk( "specialty_explosivedamage" ) )
		{
			damageAdd += damage * level.explosiveDamageMod;
		}
		else if( isPlayer( attacker ) && 
			     isKillstreakWeapon( sWeapon ) &&
				 attacker _hasPerk( "specialty_explosivedamage" ) )
		{
			damageAdd += damage * level.explosiveDamageMod;
		}
		else if( victim _hasPerk( "_specialty_blastshield" ) && 
			     ( sWeapon != "semtex_mp" || damage != 120 ) )
		{
			// TODO: remove the check once abilities go live
			//if ( IsDefined( level.abilitiesActive ) && level.abilitiesActive )
			//	damageAdd -= int( damage * ( 1 - self.blastShieldMod ) );
			//else
				damageAdd -= int( damage * ( 1 - level.blastShieldMod ) );
		}


		// let's handle juggernaut damaging here after all of the damageAdd math has happened
		if( victim isJuggernaut() )
		{
			if( IsDefined( self.isJuggernautManiac ) && self.isJuggernautManiac )
				damageAdd *= level.juggernautManiacMod;
			else
				damageAdd *= level.juggernautMod;

			switch( sWeapon )
			{
			case "ac130_25mm_mp": // this is because the 25mm shoots a bunch of bullets and can do over 1000 with multiple hits at once
				if( IsDefined( self.isJuggernautManiac ) && self.isJuggernautManiac )
					damage *= level.juggernautManiacMod;
				else
					damage *= level.juggernautMod;
				break;

			case "remote_mortar_missile_mp": // jugg will be able to take 3 hits from reaper if full health
				damage *= 0.2; // 20% of 200(max damage in gdt) is 40
				break;

			default:
				if( damage < 1000 ) 	
				{
					if ( damage > 1 )
					{
						if( IsDefined( self.isJuggernautManiac ) && self.isJuggernautManiac )
							damage *= level.juggernautManiacMod;
						else
							damage *= level.juggernautMod;
					}
				}
				break;
			}
		}
		
		//fix for grenade spam at start of round
		if ( GetDvar( "g_gametype" ) != "aliens" )
		{
			if ( ( 10 - (level.gracePeriod - level.inGracePeriod) ) > 0 )
				damage *= level.juggernautMod;
		}
		
	}
	else if( sMeansOfDeath == "MOD_FALLING" )
	{
		if( victim _hasPerk( "specialty_falldamage" ) )
		{
			if( damage > 0 )
				victim maps\mp\gametypes\_missions::processChallenge( "ch_falldamage" );

			//eventually set a msg to do a roll
			damageAdd = 0;
			damage = 0;
		}
		else
		{
			if( victim isJuggernaut() )
			{
				if( IsDefined( self.isJuggernautManiac ) && self.isJuggernautManiac )
					damage *= level.juggernautManiacMod;
				else
					damage *= level.juggernautMod;
			}
		}
	}
	else if( sMeansOfDeath == "MOD_MELEE" )
	{
		if ( IsDefined( victim.lightArmorHP ) )
		{
			if ( IsSubStr( sWeapon, "riotshield" ) )
				damage = Int(victim.maxHealth*0.66);
			else //knife
				damage = victim.maxHealth+1;
		}
		
		if( hasHeavyArmor(victim) )
		{
			damage = 100;
		}

		// let's handle juggernaut damaging here
		if( victim isJuggernaut() )
		{
			damage = 20;
			damageAdd = 0;
		}
	}
	else if( sMeansOfDeath == "MOD_IMPACT" )
	{
		// let's handle juggernaut damaging here
		if( victim isJuggernaut() )
		{
			switch( sWeapon )
			{
			case "concussion_grenade_mp":
			case "flash_grenade_mp":
			case "smoke_grenade_mp":
			case "frag_grenade_mp":
			case "semtex_mp":
				damage = 5;
				break;
			
			default:
				if( damage < 1000 )
					damage = 25;
				break;
			}

			damageAdd = 0;
		}
	}
	else if( sMeansOfDeath == "MOD_UNKNOWN" || sMeansOfDeath == "MOD_MELEE_DOG" )
	{
		if( IsAgent( attacker ) )
		{
			if( IsDefined( attacker.agent_type ) && attacker.agent_type == "dog" )
			{
				if( victim isJuggernaut() )
				{
					victim ShellShock( "dog_bite", 2 );
					if( IsDefined( self.isJuggernautManiac ) && self.isJuggernautManiac )
						damage *= level.juggernautManiacMod;
					else
						damage *= level.juggernautMod;
				}
			}
		}
	}

	if ( victim _hasperk( "specialty_combathigh" ) )
	{
		if ( IsDefined( self.damageBlockedTotal ) && (!level.teamBased || (IsDefined( attacker ) && IsDefined( attacker.team ) && victim.team != attacker.team)) )
		{
			damageTotal = damage + damageAdd;
			damageBlocked = (damageTotal - ( damageTotal / 3 ));
			self.damageBlockedTotal += damageBlocked;

			if ( self.damageBlockedTotal >= 101 )
			{
				self notify( "combathigh_survived" );
				self.damageBlockedTotal = undefined;
			}
		}

		if ( sWeapon != "throwingknife_mp" )
		{
			switch ( sMeansOfDeath )
			{
				case "MOD_FALLING":
				case "MOD_MELEE":
					break;
				default:
					damage = Int( damage/3 );
					damageAdd = Int( damageAdd/3 );
					break;
			}
		}

	}

	if( IsDefined( victim.lightArmorHP ) )
	{
		switch( sWeapon )
		{
		case "throwingknife_mp":
			damage = victim.health;
			damageAdd = 0;
			break;

		case "semtex_mp":
			if( IsDefined( inflictor ) && IsDefined( inflictor.stuckEnemyEntity ) && inflictor.stuckEnemyEntity == victim )
			{
				damage = victim.health;
				damageAdd = 0;	
			}
			break;
		
		default:
			// don't do damage to the armor if we fell or their was a headshot
			switch( sMeansOfDeath )
			{
			case "MOD_FALLING":
				break;
			
			case "MOD_MELEE":
				damage = victim.health;
				damageAdd = 0;	
				break;

			default:
				if( !isHeadShot( sWeapon, sHitLoc, sMeansOfDeath, attacker ) )
				{
					victim.lightArmorHP -= (damage + damageAdd);
					damage = 0;
					damageAdd = 0;
					if( victim.lightArmorHP <= 0 )
					{
						// since the light armor is gone, adjust the damage to be the excess damage that happens after the light armor hp is reduced
						damage = abs( victim.lightArmorHP );
						damageAdd = 0;
						unsetLightArmor();
					}
				}
				break;
			}
			break;
		}
	}
	
	if( hasHeavyArmor(victim) )
	{
		victim.heavyArmorHP -= (damage + damageAdd);
		damage = 0;
		
		if( victim.heavyArmorHP < 0 )
		{
			damage = abs( victim.heavyArmorHP );
		}
	}

	if ( damage <= 1 )
	{	
		damage = 1;
		return damage;
	}
	else
		return int( damage + damageAdd );
}

initPerkDvars()
{
	level.juggernautMod =			8/100;	// percentage of damage juggernaut takes
	level.juggernautManiacMod =		8/100;	// percentage of damage juggernaut takes
	level.armorPiercingMod =		1.5;	// increased bullet damage * this on vehicles and juggernauts
	level.regenFasterMod =			0.25;	// regen health will start at a percent of the normal speed
	level.regenFasterHealthMod =	2;		// regen health multiplied times the normal speed

	level.bulletDamageMod =		getIntProperty( "perk_bulletDamage",	40 )/100;	// increased bullet damage by this %
	level.explosiveDamageMod =	getIntProperty( "perk_explosiveDamage", 40 )/100;	// increased explosive damage by this %
	//level.blastShieldMod =		getIntProperty( "perk_blastShield",		85 )/100;	// percentage of damage you take
	level.blastShieldMod = 0.15;
	level.riotShieldMod =		getIntProperty( "perk_riotShield",		100 )/100;
	level.armorVestMod =		getIntProperty( "perk_armorVest",		75 )/100;	// percentage of damage you take
	
	if( IsDefined( level.hardcoreMode ) && level.hardcoreMode )
	{
		level.blastShieldMod = getIntProperty( "perk_blastShield_hardcore", 45 )/100;		// percentage of damage you take
	}
}

// CAC: Selector function, calls the individual cac features according to player's class settings
// Info: Called every time player spawns during loadout stage
cac_selector()
{
	perks = self.specialty;

	/*
	self.detectExplosives = false;

	if ( self _hasPerk( "specialty_detectexplosive" ) )
		self.detectExplosives = true;

	maps\mp\gametypes\_weapons::setupBombSquad();
	*/
}


giveBlindEyeAfterSpawn()
{
	self endon( "death" );
	self endon( "disconnect" );

	self givePerk( "specialty_blindeye", false );
	self.spawnPerk = true;
	while( self.avoidKillstreakOnSpawnTimer > 0 )
	{
		self.avoidKillstreakOnSpawnTimer -= 0.05;
		wait( 0.05 );
	}

	self _unsetPerk( "specialty_blindeye" );
	self.spawnPerk = false;
}

getPerkIcon( perkName )
{
	return TableLookup( PERK_STRING_TABLE, PERK_REF_COLUMN, perkName, PERK_ICON_COLUMN );
}

getPerkName( perkName )
{
	return TableLookupIString( PERK_STRING_TABLE, PERK_REF_COLUMN, perkName, PERK_NAME_COLUMN );
}
