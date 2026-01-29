#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

/*
	Deployable box killstreaks: the player will be able to place a box in the world and teammates can grab items from it
		this will be used on multiple killstreaks where you can place a box in the world with something in it
*/

BOX_TIMEOUT_UPDATE_INTERVAL = 1.0;
DEFAULT_USE_TIME = 3000;
BOX_DEFAULT_HEALTH = 999999;	// so that boxes aren't killed in code

init()
{
	if ( !IsDefined( level.boxSettings ) )
	{
		level.boxSettings = [];
	}
}

///////////////////////////////////////////////////
// MARKER FUNCTIONS
//////////////////////////////////////////////////

beginDeployableViaMarker( lifeId, boxType )
{
	self endon ( "death" );
	self.marker = undefined;

	self thread watchMarkerUsage( lifeId, boxType );

	currentWeapon = self getCurrentWeapon();

	markerWeapon = undefined;
	while (	isMarker( currentWeapon, boxType ) )
	{
		markerWeapon = currentWeapon;
		
		self waittill( "weapon_change", currentWeapon );
	}
	
	
	self notify ( "stopWatchingMarker" );

	if ( !isDefined( markerWeapon ) )
		return false;

	return( !( self getAmmoCount( markerWeapon ) && self hasWeapon( markerWeapon ) ) );
}

watchMarkerUsage( lifeId, boxType ) // self == player
{
	self notify( "watchMarkerUsage" );

	self endon( "death" );
	self endon( "disconnect" );
	self endon( "watchMarkerUsage" );
	self endon( "stopWatchingMarker" );

	self thread watchMarker( lifeId, boxType );

	while( true )
	{
		self waittill( "grenade_pullback", weaponName );

		if ( isMarker( weaponName, boxType ) )
		{
			self _disableUsability();

			self beginMarkerTracking();
		}
	}
}

watchMarker( lifeId, boxType ) // self == player
{
	self notify( "watchMarker" );

	self endon( "watchMarker" );
	self endon( "spawned_player" );
	self endon( "disconnect" );
	self endon( "stopWatchingMarker" );

	while( true )
	{
		self waittill( "grenade_fire", marker, weapName );

		if ( !isMarker( weapName, boxType ) )
			continue;
		if( !IsAlive( self ) )
		{
			marker delete();
			return;
		}

		marker.owner = self;
		marker.weaponName = weapName;

		self.marker = marker;

		self takeWeaponOnStuck( marker, weapName, boxType );

		marker thread markerActivate( lifeId, boxType, ::box_setActive );		
	}
}

takeWeaponOnStuck( weap, weapName, boxType )
{
	weap playSoundToPlayer( level.boxSettings[ boxType ].deployedSfx, self );
	
	// take the weapon away now because they've used it
	// this let's us not do a endon("grenade_fire") in beginStrikeViaMarker so it can finish correctly
	if( self HasWeapon( weapName ) )
	{
		self TakeWeapon( weapName );
		self SwitchToWeapon( self getLastWeapon() );
	}
}

beginMarkerTracking() // self == player
{
	self notify( "beginMarkerTracking" );
	self endon( "beginMarkerTracking" );
	self endon( "death" );
	self endon( "disconnect" );

	self waittill_any( "grenade_fire", "weapon_change" );
	self _enableUsability();
}

markerActivate( lifeId, boxType, usedCallback ) // self == marker
{	
	self notify( "markerActivate" );
	self endon( "markerActivate" );
	//self waittill( "explode", position );
	self waittill( "missile_stuck" );
	owner = self.owner;
	position = self.origin;

	if ( !isDefined( owner ) )
		return;

	box = createBoxForPlayer( boxType, position, owner );

	// For moving platforms. 
	parent = self GetLinkedParent();
	if ( IsDefined( parent ) )
	{
		box linkto( parent );
	}

	wait 0.05;

	//self playSound( "sentry_gun_beep" );
	box thread [[ usedCallback ]]();

	box thread maps\mp\_movers::script_mover_generic_collision_destroy( true );

	self delete();
}

isMarker( weaponName, boxType )
{
	return ( weaponName == level.boxSettings[ boxType ].weaponInfo );
}

isHoldingDeployableBox()
{
	curWeap = self GetCurrentWeapon();
	if ( IsDefined( curWeap ) )
	{
		foreach( deplBoxWeap in level.boxSettings )
		{
			if ( curWeap == deplBoxWeap.weaponInfo )
				return true;
		}
	}
	
	return false;
}
///////////////////////////////////////////////////
// END MARKER FUNCTIONS
//////////////////////////////////////////////////

///////////////////////////////////////////////////
// BOX HANDLER FUNCTIONS
//////////////////////////////////////////////////

createBoxForPlayer( boxType, position, owner )
{
	assertEx( isDefined( owner ), "createBoxForPlayer() called without owner specified" );
	
	boxConfig = level.boxSettings[ boxType ];

	box = Spawn( "script_model", position );
	box setModel( boxConfig.modelBase );
	box.health = BOX_DEFAULT_HEALTH;
	box.maxHealth = boxConfig.maxHealth;
	box.angles = owner.angles;
	box.boxType = boxType;
	box.owner = owner;
	box.team = owner.team;
	if ( IsDefined( boxConfig.maxUses ) )
	{
		box.usesRemaining = boxConfig.maxUses;
	}
	
	if ( GetDvar( "g_gametype" ) == "aliens" )
	{
		player = box.owner;
		
		if ( IsDefined( player.team_ammo_rank ) )
		{
			if ( player.team_ammo_rank == 0  )
				box.upgrade_rank = 0;	
			if ( player.team_ammo_rank == 1 )
				box.upgrade_rank = 1;	
			if ( player.team_ammo_rank == 2 )
				box.upgrade_rank = 2;	
			if ( player.team_ammo_rank == 3 )
				box.upgrade_rank = 3;	
			if ( player.team_ammo_rank == 4 )
				box.upgrade_rank = 4;	
		}
		if ( IsDefined( player.team_boost_rank ) )
		{
			if ( player.team_boost_rank == 0 )
				box.upgrade_rank = 0;	
			if ( player.team_boost_rank == 1 )
				box.upgrade_rank = 1;	
			if ( player.team_boost_rank == 2 )
				box.upgrade_rank = 2;	
			if ( player.team_boost_rank == 3 )
				box.upgrade_rank = 3;	
			if ( player.team_boost_rank == 4 )
				box.upgrade_rank = 4;	
		}
			if ( IsDefined( player.team_armor_rank ) )
		{
			if ( player.team_armor_rank == 0 )
				box.upgrade_rank = 0;	
			if ( player.team_armor_rank == 1 )
				box.upgrade_rank = 1;	
			if ( player.team_armor_rank == 2 )
				box.upgrade_rank = 2;	
			if ( player.team_armor_rank == 3 )
				box.upgrade_rank = 3;	
			if ( player.team_armor_rank == 4 )
				box.upgrade_rank = 4;	
		}
	}

	box box_setInactive();
	box thread box_handleOwnerDisconnect();

	return box;	
}

box_setActive() // self == box
{
	self setCursorHint( "HINT_NOICON" );
	boxConfig = level.boxSettings[ self.boxType ];
	self setHintString( boxConfig.hintString );

	self.inUse = false;

	curObjID = maps\mp\gametypes\_gameobjects::getNextObjID();	
	Objective_Add( curObjID, "invisible", (0,0,0) );
	Objective_Position( curObjID, self.origin );
	Objective_State( curObjID, "active" );
	Objective_Icon( curObjID, boxConfig.shaderName );
	self.objIdFriendly = curObjID;
	
	// use the deployable on the owner once
	if ( IsDefined( boxConfig.onuseCallback ) 
	    && ( !IsDefined( boxconfig.canUseCallback ) || (self.owner [[ boxConfig.canUseCallback ]]() ) )
	   )
	{
		self.owner [[ boxConfig.onUseCallback ]]( self );
	}	
	
	if ( level.teamBased )
	{
		Objective_Team( curObjID, self.team );
		foreach ( player in level.players )
		{
			if ( self.team == player.team 
			    && (!IsDefined(boxConfig.canUseCallback) || player [[ boxConfig.canUseCallback ]]() )
			   )
			{
				self box_SetIcon( player, boxConfig.streakName, boxConfig.headIconOffset );
			}
		}
	}
	else
	{
		Objective_Player( curObjID, self.owner GetEntityNumber() );

		if( !IsDefined(boxConfig.canUseCallback) || self.owner [[ boxConfig.canUseCallback ]]() )
		{
			self box_SetIcon( self.owner, boxConfig.streakName, boxConfig.headIconOffset );
		}
	}

	self MakeUsable();
	self.isUsable = true;
	self SetCanDamage( true );
	self thread box_handleDamage();
	self thread box_handleDeath();
	self thread box_timeOut();
	self thread disableWhenJuggernaut();
	self make_entity_sentient_mp( self.team, true );
	
	if ( IsDefined( self.owner ) )
		self.owner notify( "new_deployable_box", self );
	
	if (level.teamBased)
	{
		foreach ( player in level.participants )
		{
			_box_setActiveHelper( player, self.team == player.team, boxConfig.canUseCallback );
		}
	}
	else
	{
		foreach ( player in level.participants )
		{
			_box_setActiveHelper( player, IsDefined( self.owner ) && self.owner == player, boxConfig.canUseCallback );
		}
	}

	level thread teamPlayerCardSplash( boxConfig.splashName, self.owner, self.team );

	self thread box_playerConnected();
	self thread box_agentConnected();
}

_box_setActiveHelper( player, bActivate, canUseFunc )
{
	if ( bActivate )
	{
		if ( !IsDefined( canUseFunc ) || player [[ canUseFunc ]]() )
		{
			self box_enablePlayerUse( player );
		}
		else
		{
			self box_disablePlayerUse( player );
			// if this player is already a juggernaut then when they die, let them use the box
			self thread doubleDip( player );
		}
		self thread boxThink( player );
	}
	else
	{
		self box_disablePlayerUse( player );
	}
}

box_playerConnected() // self == box
{
	self endon( "death" );

	// when new players connect they need a boxthink thread run on them
	while( true )
	{
		level waittill( "connected", player );
		self childthread box_waittill_player_spawn_and_add_box( player );
	}
}

box_agentConnected() // self == box
{
	self endon( "death" );
	
	// when new agents connect they need a boxthink thread run on them
	while( true )
	{
		level waittill( "spawned_agent", agent );
		self box_addBoxForPlayer( agent );
	}
}

box_waittill_player_spawn_and_add_box( player ) // self == box
{
	player waittill( "spawned_player" );
	if ( level.teamBased )
	{
		self box_addBoxForPlayer( player );
	}
}

box_playerJoinedTeam( player ) // self == box
{
	self endon( "death" );
	player endon( "disconnect" );

	// when new players connect they need a boxthink thread run on them
	while( true )
	{
		player waittill( "joined_team" );
		if ( level.teamBased )
		{
			self box_addBoxForPlayer( player );
		}
	}
}

box_addBoxForPlayer( player ) // self == box
{
	if ( self.team == player.team )
	{
		self box_enablePlayerUse( player );
		self thread boxThink( player );
		self box_SetIcon( player, level.boxSettings[ self.boxType ].streakName, level.boxSettings[ self.boxType ].headIconOffset );
	}
	else
	{
		self box_disablePlayerUse( player );
		self maps\mp\_entityheadIcons::setHeadIcon( player, "", (0,0,0) );
	}
}

box_SetIcon( player, streakName, vOffset )
{
	if ( GetDvar( "g_gametype" ) == "aliens" )  
	{
		if ( self.boxType == "deployable_ammo" )
		{
			if ( self.upgrade_rank == 0 )
				self maps\mp\_entityheadIcons::setHeadIcon( player, "alien_dpad_icon_team_ammo", (0, 0, vOffset), 14, 14, undefined, undefined, undefined, undefined, undefined, false );
			if ( self.upgrade_rank == 1 )
				self maps\mp\_entityheadIcons::setHeadIcon( player, "alien_dpad_icon_team_ammo_1", (0, 0, vOffset), 14, 14, undefined, undefined, undefined, undefined, undefined, false );
			if ( self.upgrade_rank == 2 )
				self maps\mp\_entityheadIcons::setHeadIcon( player, "alien_dpad_icon_team_ammo_2", (0, 0, vOffset), 14, 14, undefined, undefined, undefined, undefined, undefined, false );
			if ( self.upgrade_rank == 3 )
				self maps\mp\_entityheadIcons::setHeadIcon( player, "alien_dpad_icon_team_ammo_3", (0, 0, vOffset), 14, 14, undefined, undefined, undefined, undefined, undefined, false );
			if ( self.upgrade_rank == 4 )
				self maps\mp\_entityheadIcons::setHeadIcon( player, "alien_dpad_icon_team_ammo_4", (0, 0, vOffset), 14, 14, undefined, undefined, undefined, undefined, undefined, false );
		}
		
		if ( self.boxType == "deployable_juicebox" )
		{
			if ( self.upgrade_rank == 0 )
				self maps\mp\_entityheadIcons::setHeadIcon( player, "alien_dpad_icon_team_boost", (0, 0, vOffset), 14, 14, undefined, undefined, undefined, undefined, undefined, false );
			if ( self.upgrade_rank == 1 )
				self maps\mp\_entityheadIcons::setHeadIcon( player, "alien_dpad_icon_team_boost_1", (0, 0, vOffset), 14, 14, undefined, undefined, undefined, undefined, undefined, false );
			if ( self.upgrade_rank == 2 )
				self maps\mp\_entityheadIcons::setHeadIcon( player,  "alien_dpad_icon_team_boost_2", (0, 0, vOffset), 14, 14, undefined, undefined, undefined, undefined, undefined, false );
			if ( self.upgrade_rank == 3 )
				self maps\mp\_entityheadIcons::setHeadIcon( player,  "alien_dpad_icon_team_boost_3", (0, 0, vOffset), 14, 14, undefined, undefined, undefined, undefined, undefined, false );
			if ( self.upgrade_rank == 4 )
				self maps\mp\_entityheadIcons::setHeadIcon( player, "alien_dpad_icon_team_boost_4", (0, 0, vOffset), 14, 14, undefined, undefined, undefined, undefined, undefined, false );
		}

		if ( self.boxType == "deployable_vest" )
		{
			if ( self.upgrade_rank == 0 )
				self maps\mp\_entityheadIcons::setHeadIcon( player, "alien_dpad_icon_team_armor", (0, 0, vOffset), 14, 14, undefined, undefined, undefined, undefined, undefined, false );
			if ( self.upgrade_rank == 1 )
				self maps\mp\_entityheadIcons::setHeadIcon( player, "alien_dpad_icon_team_armor_1", (0, 0, vOffset), 14, 14, undefined, undefined, undefined, undefined, undefined, false );
			if ( self.upgrade_rank == 2 )
				self maps\mp\_entityheadIcons::setHeadIcon( player,  "alien_dpad_icon_team_armor_2", (0, 0, vOffset), 14, 14, undefined, undefined, undefined, undefined, undefined, false );
			if ( self.upgrade_rank == 3 )
				self maps\mp\_entityheadIcons::setHeadIcon( player,  "alien_dpad_icon_team_armor_3", (0, 0, vOffset), 14, 14, undefined, undefined, undefined, undefined, undefined, false );
			if ( self.upgrade_rank == 4 )
				self maps\mp\_entityheadIcons::setHeadIcon( player, "alien_dpad_icon_team_armor_4", (0, 0, vOffset), 14, 14, undefined, undefined, undefined, undefined, undefined, false );
		}
	}
	else
	{
		self maps\mp\_entityheadIcons::setHeadIcon( player, getKillstreakOverheadIcon( streakName ), (0, 0, vOffset), 14, 14, undefined, undefined, undefined, undefined, undefined, false );
	}
}
box_enablePlayerUse( player ) // self == box
{
	if ( IsPlayer(player) )
		self EnablePlayerUse( player );
	
	self.disabled_use_for[player GetEntityNumber()] = false;
}

box_disablePlayerUse( player ) // self == box
{
	if ( IsPlayer(player) )
		self DisablePlayerUse( player );
	
	self.disabled_use_for[player GetEntityNumber()] = true;
}

box_setInactive()
{
	self makeUnusable();
	self.isUsable = false;
	self maps\mp\_entityheadIcons::setHeadIcon( "none", "", (0,0,0) );
	if ( isDefined( self.objIdFriendly ) )
		_objective_delete( self.objIdFriendly );	
}

box_handleDamage()	// self == box
{
	self.health = BOX_DEFAULT_HEALTH; // keep it from dying anywhere in code
	// the real health should be set in the kill streak's config
	// self.maxHealth = 300; // this is the health we'll check
	self.damageTaken = 0; // how much damage has it taken

	while( true )
	{
		self waittill( "damage", damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon );

		if( !IsDefined( self ) )
			return;
		
		// don't allow people to destroy equipment on their team if FF is off
		if( !maps\mp\gametypes\_weapons::friendlyFireCheck( self.owner, attacker ) )
			continue;
		
		boxConfig = level.boxSettings[ self.boxType ];

		if( !boxConfig.allowGrenadeDamage
			&& IsDefined( weapon ) )
		{
			switch( weapon )
			{
			case "concussion_grenade_mp":
			case "flash_grenade_mp":
			case "smoke_grenade_mp":
				continue;
			}
		}

		if( meansOfDeath == "MOD_MELEE" )
		{
			if ( boxConfig.allowMeleeDamage )
			{
				self.damageTaken += self.maxHealth;
			}
			else
			{
				continue;
			}
		}

		if( IsDefined( iDFlags ) && ( iDFlags & level.iDFLAGS_PENETRATION ) )
			self.wasDamagedFromBulletPenetration = true;

		self.wasDamaged = true;

		modifiedDamage = damage;

		if( IsPlayer( attacker ) )
		{
			attacker maps\mp\gametypes\_damagefeedback::updateDamageFeedback( boxConfig.damageFeedback );

			if( meansOfDeath == "MOD_RIFLE_BULLET" || meansOfDeath == "MOD_PISTOL_BULLET" )
			{
				if( attacker _hasPerk( "specialty_armorpiercing" ) )
					modifiedDamage += damage * level.armorPiercingMod;
			}
		}
		// in case we are shooting from a remote position, like being in the osprey gunner shooting this
		else if( IsDefined( attacker.owner ) && IsPlayer( attacker.owner ) )
		{
			attacker.owner maps\mp\gametypes\_damagefeedback::updateDamageFeedback( boxConfig.damageFeedback );
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

			case "artillery_mp":
			case "stealth_bomb_mp":
				self.largeProjectileDamage = false;
				modifiedDamage += ( damage * 4 );
				break;

			case "bomb_site_mp":
				self.largeProjectileDamage = false;
				modifiedDamage = self.maxHealth + 1;
				break;
			}
			
			maps\mp\killstreaks\_killstreaks::killstreakHit( attacker, weapon, self );
		}

		self.damageTaken += modifiedDamage;

		if( self.damageTaken >= self.maxHealth )
		{
			if( IsPlayer( attacker ) && (!IsDefined(self.owner) || attacker != self.owner) )
			{
				attacker thread maps\mp\gametypes\_rank::giveRankXP( "kill", boxConfig.killXP, weapon, meansOfDeath );				
				attacker notify( "destroyed_killstreak" );
			}

			if( IsDefined( self.owner ) )
				self.owner thread leaderDialogOnPlayer( boxConfig.voDestroyed, undefined, undefined, self.origin );

			self notify( "death" );
			return;
		}
	}
}

box_handleDeath()
{
	self waittill ( "death" );

	// this handles cases of deletion
	if ( !isDefined( self ) )
		return;

	self box_setInactive();

	boxConfig = level.boxSettings[ self.boxType ];
	PlayFX( boxConfig.deathVfx, self.origin );
	// 2013-03-08 wsh: whould probably validate all the used fields...
	if ( IsDefined( boxConfig.deathDamageMax ) )
	{
		owner = undefined;
		if ( IsDefined(self.owner) )
			owner = self.owner;
		
		// somewhat hacky:
		// shift the origin of the damage because it'll collide with the box otherwise
		// we could also apply the damage after we delete the item?
		RadiusDamage( self.origin + (0, 0, boxConfig.headIconOffset),
					 boxConfig.deathDamageRadius, 
					 boxConfig.deathDamageMax,
					 boxConfig.deathDamageMin,
					 owner,
					 "MOD_EXPLOSIVE",
					 boxConfig.deathWeaponInfo
					);
	}
	
	wait( 0.1 );

	self notify( "deleting" );

	self delete();
}

box_handleOwnerDisconnect() // self == box
{
	self endon ( "death" );
	level endon ( "game_ended" );

	self notify ( "box_handleOwner" );
	self endon ( "box_handleOwner" );

	self.owner waittill( "killstreak_disowned" );

	self notify( "death" );
}

boxThink( player )
{	
	self endon ( "death" );

	self thread boxCaptureThink( player );
	
	if ( !IsDefined(player.boxes) )
	{
		player.boxes = [];
	}
	player.boxes[player.boxes.size] = self;
	
	boxConfig = level.boxSettings[ self.boxType ];

	for ( ;; )
	{
		self waittill ( "captured", capturer );
		
		if (capturer == player)
		{
			player PlayLocalSound( boxConfig.onUseSfx );
			
			if ( IsDefined( boxConfig.onuseCallback ) )
			{
				player [[ boxConfig.onUseCallback ]]( self );
			}
		
			// if this is not the owner then give the owner some xp
			if( IsDefined( self.owner ) && player != self.owner )
			{
				self.owner thread maps\mp\gametypes\_rank::xpEventPopup( boxConfig.eventString );
				self.owner thread maps\mp\gametypes\_rank::giveRankXP( "support", boxConfig.useXP );
			}
			
			if ( IsDefined( self.usesRemaining ) )
			{
				self.usesRemaining--;
				if ( self.usesRemaining == 0)
				{
					self box_Cleanup();
					break;
				}
			}
	
			self maps\mp\_entityheadIcons::setHeadIcon( player, "", (0,0,0) );
			self box_disablePlayerUse( player );
			self thread doubleDip( player );
		}
	}
}

doubleDip( player ) // self == box
{
	self endon( "death" );
	player endon( "disconnect" );

	// once they die, let them take from the box again
	player waittill( "death" );

	if( level.teamBased )
	{
		if( self.team == player.team )
		{
			self box_SetIcon( player, level.boxSettings[ self.boxType ].streakName, level.boxSettings[ self.boxType ].headIconOffset );
			self box_enablePlayerUse( player );
		}
	}
	else
	{
		if( IsDefined( self.owner ) && self.owner == player )
		{
			self box_SetIcon( player, level.boxSettings[ self.boxType ].streakName, level.boxSettings[ self.boxType ].headIconOffset );
			self box_enablePlayerUse( player );
		}
	}
}

boxCaptureThink( player )	// self == box
{
	while( isDefined( self ) )
	{
		self waittill( "trigger", tiggerer );
		
		if (tiggerer == player
		    && self useHoldThink( player, level.boxSettings[ self.boxType ].useTime )
		   )
		{
			self notify( "captured", player );
		}	
	}
}

isFriendlyToBox( box )
{
	return ( level.teamBased 
		     && self.team == box.team );
}

box_timeOut() // self == box
{
	self endon( "death" );
	level endon ( "game_ended" );

	lifeSpan = level.boxSettings[ self.boxType ].lifeSpan;

	while ( lifeSpan > 0.0 )
	{
		wait ( BOX_TIMEOUT_UPDATE_INTERVAL );
		maps\mp\gametypes\_hostmigration::waitTillHostMigrationDone();

		if ( !isDefined( self.carriedBy ) )
		{
			// is there a way to get the actual time elapsed?
			lifeSpan -= BOX_TIMEOUT_UPDATE_INTERVAL;
		}
	}
	
	self box_Cleanup();
}

box_Cleanup()
{
	// TODO: get sound for this
	//if ( isDefined( self.owner ) )
	//	self.owner thread leaderDialogOnPlayer( "sentry_gone" );

	self box_setInactive();
	PlayFX( getfx( "airdrop_crate_destroy" ), self.origin );
	
	wait( 0.05 );

	self notify( "deleting" );

	self delete();
}

deleteOnOwnerDeath( owner ) // self == box.friendlyModel or box.enemyModel, owner == box
{
	wait ( 0.25 );
	self linkTo( owner, "tag_origin", (0,0,0), (0,0,0) );

	owner waittill ( "death" );

	box_Cleanup();
}

box_ModelTeamUpdater( showForTeam ) // self == box model (enemy or friendly)
{
	self endon ( "death" );

	self hide();

	foreach ( player in level.players )
	{
		if ( player.team == showForTeam )
			self showToPlayer( player );
	}

	for ( ;; )
	{
		level waittill ( "joined_team" );

		self hide();
		foreach ( player in level.players )
		{
			if ( player.team == showForTeam )
				self showToPlayer( player );
		}
	}	
}

useHoldThink( player, useTime ) 
{
	if ( IsPlayer(player) )
		player playerLinkTo( self );
	else
		player LinkTo( self );
	player playerLinkedOffsetEnable();

	player _disableWeapon();

	player.boxParams = SpawnStruct();
	player.boxParams.curProgress = 0;
	player.boxParams.inUse = true;
	player.boxParams.useRate = 0;

	if ( isDefined( useTime ) )
	{
		player.boxParams.useTime = useTime;
	}
	else
	{
		player.boxParams.useTime = DEFAULT_USE_TIME;
	}

	if ( IsPlayer(player) )
		player thread personalUseBar( self );

	result = useHoldThinkLoop( player );
	assert ( isDefined( result ) );

	if ( isAlive( player ) )
	{
		player _enableWeapon();
		player unlink();
	}

	if ( !isDefined( self ) )
		return false;

	player.boxParams.inUse = false;
	player.boxParams.curProgress = 0;

	return ( result );
}

personalUseBar( object ) // self == player
{
	self endon( "disconnect" );

	useBar = createPrimaryProgressBar( 0, 25 );
	useBarText = createPrimaryProgressBarText( 0, 25 );
	useBarText setText( level.boxSettings[ object.boxType ].capturingString );

	lastRate = -1;
	while ( isReallyAlive( self ) && isDefined( object ) && self.boxParams.inUse && object.isUsable && !level.gameEnded )
	{
		if ( lastRate != self.boxParams.useRate )
		{
			if( self.boxParams.curProgress > self.boxParams.useTime)
				self.boxParams.curProgress = self.boxParams.useTime;

			useBar updateBar( self.boxParams.curProgress / self.boxParams.useTime, (1000 / self.boxParams.useTime) * self.boxParams.useRate );

			if ( !self.boxParams.useRate )
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
		lastRate = self.boxParams.useRate;
		wait ( 0.05 );
	}

	useBar destroyElem();
	useBarText destroyElem();
}

useHoldThinkLoop( player )
{
	while( !level.gameEnded && isDefined( self ) && isReallyAlive( player ) && player useButtonPressed() && player.boxParams.curProgress < player.boxParams.useTime )
	{
		player.boxParams.curProgress += (50 * player.boxParams.useRate);

		if ( isDefined( player.objectiveScaler ) )
			player.boxParams.useRate = 1 * player.objectiveScaler;
		else
			player.boxParams.useRate = 1;

		if ( player.boxParams.curProgress >= player.boxParams.useTime )
			return ( isReallyAlive( player ) );

		wait 0.05;
	} 

	return false;
}

disableWhenJuggernaut() // self == box
{
	level endon( "game_ended" );
	self endon( "death" );

	while( true )
	{
		level waittill( "juggernaut_equipped", player );
		self maps\mp\_entityheadIcons::setHeadIcon( player, "", (0,0,0) );
		self box_disablePlayerUse( player );
		self thread doubleDip( player );
	}
}
