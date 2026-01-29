#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;


//============================================
// 				constants
//============================================
CONST_UPLINK_WEAPON 	= "killstreak_uplink_mp";
CONST_UPLINK_DEPLOY_SFX = "mp_vest_deployed_ui";
CONST_UPLINK_MODEL		= "mp_trophy_system";
CONST_UPLINK_TIME		= 30;
CONST_UPLINK_MIN 		= 0;
CONST_EYES_ON 			= 1;
CONST_UPLINK_FULL_RADAR	= 2;
CONST_UPLINK_FAST_PING	= 2;
CONST_DIRECTIONAL		= 3;
CONST_UPLINK_MAX 		= 3;
CONST_FAST_SWEEP		= "normal_radar";
CONST_NORMAL_SWEEP		= "normal_radar";
CONST_HEAD_ICON_OFFSET	= 56;


//============================================
// 				init
//============================================
init()
{		
	level.uplinks = [];
	level.killstreakFuncs["uplink"] 		= ::tryUseUpLink;
	level.killstreakFuncs["uplink_support"] = ::tryUseUpLink;
	
	unblockTeamRadar( "axis" );
	unblockTeamRadar( "allies" );
	
	level thread upLinkTracker();
}	


//============================================
// 				upLinkTracker
//============================================
upLinkTracker()
{
	level endon ( "game_ended" );
	
	while( true )
	{
		level waittill( "update_uplink" );
		
		if( level.teamBased )
		{
			level childthread updateTeamUpLink( "axis" );
			level childthread updateTeamUpLink( "allies" );
		}
		else
		{
			level childthread updatePlayerUpLink();
		}
	}
}

	
//============================================
// 				updateTeamUpLink
//============================================
updateTeamUpLink( team )
{
	radarStrength 		= getRadarStrengthForTeam( team );
	shouldBeEyesOn		= ( radarStrength == CONST_EYES_ON );
	shouldBeFullRadar	= ( radarStrength >= CONST_UPLINK_FULL_RADAR );
	shouldBeFastSweep	= ( radarStrength >= CONST_UPLINK_FAST_PING );
	shouldBeDirectional = ( radarStrength >= CONST_DIRECTIONAL );
	
	if( shouldBeFullRadar )
	{
		unblockTeamRadar( team );
	}
	
	if( shouldBeFastSweep )
	{
		level.radarMode[team] = CONST_FAST_SWEEP;
	}
	else
	{
		level.radarMode[team] = CONST_NORMAL_SWEEP;
	}
	
	foreach( player in level.players )
	{
		if( player.team != team )
		{
			continue;
		}
		
		player SetEyesOnUplinkEnabled( shouldBeEyesOn );
		player.radarMode = level.radarMode[player.team];
		player.radarShowEnemyDirection = shouldBeDirectional;				
	}
	
	setTeamRadar( team, shouldBeFullRadar );
	level notify( "radar_status_change", team );
}


//============================================
// 				updatePlayerUpLink
//============================================
updatePlayerUpLink()
{
	foreach ( player in level.players )
	{
		radarStrength 		= getRadarStrengthForPlayer( player );
		shouldBeEyesOn		= ( radarStrength == CONST_EYES_ON );
		shouldBeFullRadar	= ( radarStrength >= CONST_UPLINK_FULL_RADAR );
		shouldBeFastSweep	= ( radarStrength >= CONST_UPLINK_FAST_PING );
		shouldBeDirectional = ( radarStrength >= CONST_DIRECTIONAL );
	
		player SetEyesOnUplinkEnabled( shouldBeEyesOn );	
		player.radarShowEnemyDirection = shouldBeDirectional;
		player.radarMode = CONST_NORMAL_SWEEP;
		player.hasRadar = shouldBeFullRadar;
		player.isRadarBlocked = false;
		
		if( shouldBeFastSweep )
		{
			player.radarMode = CONST_FAST_SWEEP;
		}
	}
}


//============================================
// 				tryUseUpLink
//============================================
tryUseUpLink( lifeId )
{
	return useUpLink( self, lifeId );
}


//============================================
// 				useUpLink
//============================================
useUpLink( player, lifeId )
{
	level thread monitorUpLinkCancel( player );
	level thread monitorUpLinkPlacement( player );
	
	while( true )
	{
		result = player waittill_any_return( "uplink_canceled", "uplink_deployed", "death", "disconnect" );
		
		if( result == "uplink_deployed" )
		{
			return true;
		}
		
		return false;
	}
}


//============================================
// 			monitorUpLinkCancel
//============================================
monitorUpLinkCancel( player )
{
	player endon( "death" );
	player endon( "disconnect" );
	player endon( "uplink_deployed" );
	
	currentWeapon = player getCurrentWeapon();

	while( currentWeapon == CONST_UPLINK_WEAPON )
	{	
		player waittill( "weapon_change", currentWeapon );
	}
	
	player notify( "uplink_canceled" );
}


//============================================
// 			monitorUpLinkPlacement
//============================================
monitorUpLinkPlacement( player )
{
	player endon( "death" );
	player endon( "disconnect" );
	player endon( "uplink_canceled" );
	
	while( true )
	{
		player waittill( "grenade_fire", upLinkGrenade, weaponName );
		
		if( isReallyAlive(player) )
		{
			break;
		}
	}
	
	player notify( "uplink_deployed" );
	
	if( player HasWeapon( weaponName ) )
	{
		player TakeWeapon( weaponName );
		player switch_to_last_weapon( player getLastWeapon() );
	}
	
	upLinkGrenade playSoundToPlayer( CONST_UPLINK_DEPLOY_SFX, player );
	upLinkGrenade waittill( "missile_stuck" );
	
	// need to spawn in a model and delete the "grenade" so we can damage it properly
	upLinkEnt = Spawn( "script_model", upLinkGrenade.origin );
	upLinkEnt SetModel( CONST_UPLINK_MODEL );
	
	upLinkEnt.angles 		= upLinkGrenade.angles;
	upLinkEnt.owner 		= player;
	upLinkEnt.team 			= player.team;
	upLinkEnt.weaponName 	= weaponName;
	upLinkEnt make_entity_sentient_mp( player.team, true );
	
	addUplinkToLevelList( upLinkEnt );
	upLinkGrenade Delete();
	
	level thread monitorDisownKillstreaks( upLinkEnt  );
	level thread monitorUpLinkDamage( upLinkEnt );
	level thread monitorDeath( upLinkEnt );
	level thread setUpLinkHeadIcon( upLinkEnt );
}


//============================================
// 			setUpLinkHeadIcon
//============================================
setUpLinkHeadIcon( upLinkEnt )
{
	upLinkEnt endon( "death" );
	
	waitframe();
	
	if( level.teamBased )
	{
		upLinkEnt maps\mp\_entityheadicons::setTeamHeadIcon( upLinkEnt.team, (0,0,CONST_HEAD_ICON_OFFSET) );
	}
	else
	{
		upLinkEnt maps\mp\_entityheadicons::setPlayerHeadIcon( upLinkEnt.owner, (0,0,CONST_HEAD_ICON_OFFSET) );
	}
}


//============================================
// 			monitorDisownKillstreaks
//============================================
monitorDisownKillstreaks( killStreakEnt )
{
	killStreakEnt endon( "death" );
	
	killStreakEnt.owner waittill( "killstreak_disowned" );
	
	killStreakEnt notify( "death" );
}

//============================================
// 				monitorDeath
//============================================
monitorDeath( killStreakEnt )
{
	killStreakEnt waittill_notify_or_timeout_return( "death", CONST_UPLINK_TIME );
	
	PlayFXOnTag( getfx( "sentry_explode_mp" ), killStreakEnt, "tag_origin" );
	PlayFXOnTag( getfx( "sentry_smoke_mp" ), killStreakEnt, "tag_origin" );
	killStreakEnt PlaySound( "sentry_explode" );
	
	removeUplinkFromLevelList( killStreakEnt );
	
	wait( 3.0 );
	
	if( IsDefined(killStreakEnt) )
	{
		killStreakEnt Delete();
	}
}


//============================================
// 			monitorUpLinkDamage
//============================================
monitorUpLinkDamage( killStreakEnt )
{
	killStreakEnt endon( "death" );
	
	killStreakEnt SetCanDamage( true );
	killStreakEnt.health 		= 999999; 	// keep it from dying anywhere in code
	killStreakEnt.maxHealth 	= 250; 		// this is the health we'll check
	killStreakEnt.damageTaken 	= 0; 		// how much damage has it taken
	
	while( true )
	{
		killStreakEnt waittill( "damage", damage, attacker, direction_vec, point, type, modelName, tagName, partName, iDFlags, weapon );
		
		if( !isPlayer(attacker) )
		{
			continue;
		}
		
		if( !maps\mp\gametypes\_weapons::friendlyFireCheck( killStreakEnt.owner, attacker ) )
		{
			continue;
		}
		
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
		
		if( type == "MOD_MELEE" )
		{
			killStreakEnt.damageTaken += killStreakEnt.maxHealth;
		}
		
		killStreakEnt.damageTaken += damage;
		
		if( isPlayer( attacker ) )
		{
			attacker maps\mp\gametypes\_damagefeedback::updateDamageFeedback( "trophy" );
		}
		
		if( killStreakEnt.damageTaken >= killStreakEnt.maxHealth )
		{
			if( IsPlayer(attacker) && (attacker != killStreakEnt.owner) )
			{
				attacker thread maps\mp\gametypes\_rank::giveRankXP( "kill", 100 );	
				attacker thread maps\mp\killstreaks\_killstreaks::giveAdrenaline( "vehicleDestroyed" ); 
			}
			
			killStreakEnt notify( "death" );
		}
	}
}

//============================================
// 			addUplinkToLevelList
//============================================
addUplinkToLevelList( obj )
{
	entNum = obj GetEntityNumber();
	level.uplinks[entNum] = obj;
	level notify( "update_uplink" );
}


//============================================
// 			removeUplinkFromLevelList
//============================================
removeUplinkFromLevelList( obj )
{
	entNum = obj GetEntityNumber();
	level.uplinks[ entNum ] = undefined;
	level notify( "update_uplink" );
}


//============================================
// 			getRadarStrengthForTeam
//============================================
getRadarStrengthForTeam( team )
{
	currentRadarStrength = 0;
	
	foreach( satellite in level.uplinks )
	{
		if( IsDefined(satellite) && (satellite.team == team) )
			currentRadarStrength++;
	}
	
	return clamp( currentRadarStrength, CONST_UPLINK_MIN, CONST_UPLINK_MAX );
}

//============================================
// 			getRadarStrengthForPlayer
//============================================
getRadarStrengthForPlayer( player )
{
	currentRadarStrength = 0;
	
	foreach( satellite in level.uplinks )
	{
		if( IsDefined(satellite) && (satellite.owner.guid == player.guid) )
			currentRadarStrength++;
	}
	
	return clamp( currentRadarStrength, CONST_UPLINK_MIN, CONST_UPLINK_MAX );
}
