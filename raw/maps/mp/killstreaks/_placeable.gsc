#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;

init()
{
	if ( !IsDefined( level.placeableConfigs ) )
	{
		level.placeableConfigs = [];
	}
}

givePlaceable( streakName ) // self == player
{
	placeable = self createPlaceable( streakName );
	
	//	returning from this streak activation seems to strip this?
	//	manually removing and restoring
	self removePerks();
	
	self.carriedItem = placeable;
	
	result = self onBeginCarrying( streakName, placeable, true );
	
	self.carriedItem = undefined;
	
	self restorePerks();

	if ( IsDefined( result ) )
	{
		return result;
	}
	else
	{
		return IsDefined( placeable );
	}
}

createPlaceable( streakName )
{
	if( IsDefined( self.isCarrying ) )
		return;
	
	config = level.placeableConfigs[ streakName ];
	
	obj = Spawn( "script_model", self.origin );
	obj SetModel( config.modelBase );
	obj.angles = self.angles;
	obj.team = self.team;

	/*
	obj = SpawnTurret( "misc_turret", self.origin + ( 0, 0, 25 ), "sentry_minigun_mp" );

	obj.angles = self.angles;
	obj.owner = self;

	obj SetModel( config.modelBase );

	obj MakeTurretInoperable();
	obj SetTurretModeChangeWait( true );
	obj SetMode( "sentry_offline" );
	obj MakeUnusable();
	obj SetSentryOwner( self );
	*/
	
	// inits happen here
	if ( IsDefined( config.onCreateDelegate ) )
	{
		obj [[ config.onCreateDelegate ]]( streakName );
	}
	
	obj deactivate( streakName );
	
	obj thread handleDamage( streakName );
	obj thread handleDeath( streakName );
	obj thread timeOut( streakName );
	obj thread handleUse( streakName );
	// owner disconnect

	return obj;	
}


handleUse( streakName ) // self == placeable
{
	self endon ( "death" );
	level endon ( "game_ended" );
	
	while ( true )
	{
		self waittill ( "trigger", player );
		
		assert( player == self.owner );
		assert( !IsDefined( self.carriedBy ) );

		if ( !isReallyAlive( player ) )
			continue;
		
		// why does the IMS create a second one?
		
		player onBeginCarrying( streakName, self, false );
	}
}

// setCarrying
onBeginCarrying( streakName, placeable, allowCancel )	// self == player
{
	self endon ( "death" );
	self endon ( "disconnect" );
	
	assert( isReallyAlive( self ) );
	
	placeable.owner = self;
	placeable thread onCarried( streakName, self );
	
	self _disableWeapon();

	self notifyOnPlayerCommand( "placePlaceable", "+attack" );
	self notifyOnPlayerCommand( "placePlaceable", "+attack_akimbo_accessible" ); // support accessibility control scheme
	self notifyOnPlayerCommand( "cancelPlaceable", "+actionslot 4" );
	if( !level.console )
	{
		self notifyOnPlayerCommand( "cancelPlaceable", "+actionslot 5" );
		self notifyOnPlayerCommand( "cancelPlaceable", "+actionslot 6" );
		self notifyOnPlayerCommand( "cancelPlaceable", "+actionslot 7" );
	}
	
	while (true)
	{
		result = waittill_any_return( "placePlaceable", "cancelPlaceable", "force_cancel_placement" );

		// object was deleted
		if ( !IsDefined( placeable ) )
		{
			self _enableWeapon();
			return true;
		}
		else if ( (result == "cancelPlaceable" && allowCancel)
			  || result == "force_cancel_placement" )
		{
			placeable onCancel( streakName );
			self _enableWeapon();
			return false;
		}
		else if ( placeable.canBePlaced )
		{
			placeable thread onPlaced( streakName );
			self _enableWeapon();
			return true;
		}
	}
}

onCancel( streakName )	// self == placeable
{
	self.carriedBy ForceUseHintOff();
	if( IsDefined( self.owner ) )
	{
		self.owner.isCarrying = undefined;
	}
	
	config = level.placeableConfigs[ streakName ];
	if ( IsDefined( config.onCancelDelegate ) )
	{
		self [[ config.onCancelDelegate ]]( streakName );
	}

	self delete();
}

onPlaced( streakName )	// self == placeable
{
	config = level.placeableConfigs[ streakName ];
	
	self SetCanDamage( true );
	self PlaySound( config.placedSfx );

	if ( IsDefined( config.onPlacedDelegate ) )
	{
		self [[ config.onPlacedDelegate ]]( streakName );
	}
	
	self setCursorHint( "HINT_NOICON" );
	self setHintString( config.hintString );

	owner = self.owner;
	owner ForceUseHintOff();
	owner.isCarrying = undefined;
	self.carriedBy = undefined;

	if ( IsDefined( config.headIconHeight ) )
	{
		if ( level.teamBased )
		{
			self maps\mp\_entityheadicons::setTeamHeadIcon( self.team, (0,0,config.headIconHeight) );
		}
		else
		{
			self maps\mp\_entityheadicons::setPlayerHeadIcon( owner, (0,0,config.headIconHeight) );
		}
	}

	self MakeUsable();
	self SetCanDamage( true );	

	foreach ( player in level.players )
	{
		if( player == owner )
			self EnablePlayerUse( player );
		else
			self DisablePlayerUse( player );
	}	

	if( IsDefined( self.shouldSplash ) )
	{
		level thread teamPlayerCardSplash( config.splashName, owner );
		self.shouldSplash = false;
	}
	
	self notify ( "placed" );
}

onCarried( streakName, carrier )	// self == placeable
{
	config = level.placeableConfigs[ streakName ];
	
	assert( isPlayer( carrier ) );
	assertEx( carrier == self.owner, "ims_setCarried() specified carrier does not own this ims" );
	
	self SetModel( config.modelPlacement );

	// self SetSentryCarrier( carrier );
	self SetCanDamage( false );
	// don't know if this is the same
	// self SetContents( 0 );

	self.carriedBy = carrier;
	carrier.isCarrying = true;
	
	self deactivate( streakName );
	
	if ( IsDefined( config.onCarriedDelegate ) )
	{
		self [[ config.onCarriedDelegate ]]( streakName );
		
		// self SetContents( 0 );
		// self sentry_makeNotSolid();
		// self FreeEntitySentient();
	}
	
	self thread updatePlacement( streakName, carrier );
	
	self thread onCarrierDeath( streakName, carrier );
	self thread onCarrierDisconnect( streakName, carrier );
	self thread onCarrierChangedTeam( streakName, carrier );
	self thread onGameEnded( streakName );

	self notify ( "carried" );
}

updatePlacement( streakName, carrier )	// self == placeable
{
	carrier endon ( "death" );
	carrier endon ( "disconnect" );
	level endon ( "game_ended" );
	
	self endon ( "placed" );
	self endon ( "death" );
	
	self.canBePlaced = true;
	prevCanBePlaced = -1; // force initial update
	
	config = level.placeableConfigs[ streakName ];

	while ( true )
	{
		// placement = carrier CanPlayerPlaceTank( 22, 22, 50, 45, 0, 0 );
		placement = carrier CanPlayerPlaceSentry();

		self.origin = placement[ "origin" ];
		self.angles = placement[ "angles" ];
		
		// hack for the barrier!
		self AddYaw(90);
		
		self.canBePlaced = carrier IsOnGround() && placement[ "result" ] && ( abs(self.origin[2] - carrier.origin[2]) < 10 );
	
		if ( self.canBePlaced != prevCanBePlaced )
		{
			if ( self.canBePlaced )
			{
				self SetModel( config.modelPlacement );
				carrier ForceUseHintOn( config.placeString );
			}
			else
			{
				self SetModel( config.modelPlacementFailed );
				carrier ForceUseHintOn( config.cannotPlaceString );
			}
		}
		
		prevCanBePlaced = self.canBePlaced;		
		wait ( 0.05 );
	}
}

deactivate( streakName )	// self == placeable
{
	self MakeUnusable();

	self hideHeadIcons();
	
	config = level.placeableConfigs[ streakName ];
	if ( IsDefined( config.onDeactiveDelegate ) )
	{
		self [[ config.onDeactiveDelegate ]]( streakName );
	}
}

hideHeadIcons()
{
	if ( level.teamBased )
	{
		self maps\mp\_entityheadicons::setTeamHeadIcon( "none", ( 0, 0, 0 ) );
	}
	else if ( IsDefined( self.owner ) )
	{
		self maps\mp\_entityheadicons::setPlayerHeadIcon( undefined, ( 0, 0, 0 ) );
	}	
}

// important callbacks:
// onDamagedDelegate - filter out or amplify damage based on specifics
// onDestroyedDelegate - any extra handling when the object is killed
handleDamage( streakName ) // self == placeable
{
	self endon( "death" );
	level endon( "game_ended" );
	
	config = level.placeableConfigs[ streakName ];

	self.health = 999999; // keep it from dying anywhere in code
	self.maxHealth = config.maxHealth; // this is the health we'll check
	self.damageTaken = 0; // how much damage has it taken

	while( true )
	{
		self waittill( "damage", damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon );

		// don't allow people to destroy equipment on their team if FF is off
		if ( !maps\mp\gametypes\_weapons::friendlyFireCheck( self.owner, attacker ) )
			continue;
		
		if ( IsDefined( config.onDamagedDelegate ) )
		{
			damage = self [[ config.onDamagedDelegate ]]( streakName, attacker, self.owner, damage );
			if ( damage == 0 )
			{
				continue;
			}
		}

		if ( meansOfDeath == "MOD_MELEE" && config.allowMeleeDamage )
		{
			self.damageTaken += self.maxHealth;
		}
		
		if ( IsDefined( iDFlags ) && ( iDFlags & level.iDFLAGS_PENETRATION ) )
			self.wasDamagedFromBulletPenetration = true;

		self.wasDamaged = true;

		modifiedDamage = damage;
		if ( isPlayer( attacker ) )
		{
			attacker maps\mp\gametypes\_damagefeedback::updateDamageFeedback( config.damageFeedback );

			if ( attacker _hasPerk( "specialty_armorpiercing" ) )
			{
				modifiedDamage = damage * level.armorPiercingMod;			
			}
		}

		// in case we are shooting from a remote position, like being in the osprey gunner shooting this
		if( IsDefined( attacker.owner ) && IsPlayer( attacker.owner ) )
		{
			attacker.owner maps\mp\gametypes\_damagefeedback::updateDamageFeedback( config.damageFeedback );
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
			case "emp_grenade_mp":
				self.largeProjectileDamage = false;
				modifiedDamage = self.maxHealth + 1;
				break;
			}
			
			maps\mp\killstreaks\_killstreaks::killstreakHit( attacker, weapon, self );
		}

		self.damageTaken += modifiedDamage;		
		
		if ( self.damageTaken >= self.maxHealth )
		{
			thread maps\mp\gametypes\_missions::vehicleKilled( self.owner, self, undefined, attacker, damage, meansOfDeath, weapon );

			if ( isPlayer( attacker ) && (!IsDefined(self.owner) || attacker != self.owner) )
			{
				attacker thread maps\mp\gametypes\_rank::giveRankXP( "kill", 100, weapon, meansOfDeath );
				attacker notify( "destroyed_killstreak" );
				
				if ( IsDefined( config.onDestroyedDelegate ) )
				{
					self [[ config.onDestroyedDelegate ]]( streakName, attacker, self.owner, meansOfDeath );
				}
			}

			if ( IsDefined( self.owner ) )
			{
				self.owner thread leaderDialogOnPlayer( config.destroyedVO, undefined, undefined, self.origin );
			}

			self notify ( "death" );
			return;
		}
	}
}

handleDeath( streakName )
{
	self waittill ( "death" );
	
	config = level.placeableConfigs[ streakName ];
	
	// this handles cases of deletion
	if ( IsDefined( self ) )
	{	
		// play sound
		
		self deactivate( streakName );
		
		// set destroyed model
		self SetModel( config.modelDestroyed );
		
		// or do it in the callbacks?
		
		if ( IsDefined( config.onDeathDelegate ) )
		{
			self [[ config.onDeathDelegate ]]( streakName );
		}
		
		self Delete();
	}
}

//--------------------------------------------------------------------
onCarrierDeath( streakName, carrier ) // self == placeable
{
	self endon ( "placed" );
	self endon ( "death" );
	carrier endon( "disconnect" );

	carrier waittill ( "death" );
	
	if ( self.canBePlaced )
	{
		self thread onPlaced( streakName );
	}
	else
	{
		self onCancel( streakName );
	}
}


onCarrierDisconnect( streakName, carrier ) // self == placeable
{
	self endon ( "placed" );
	self endon ( "death" );

	carrier waittill ( "disconnect" );
	
	self onCancel( streakName );
}

onCarrierChangedTeam( streakName, carrier ) // self == placeable
{
	self endon ( "placed" );
	self endon ( "death" );

	carrier waittill_any( "joined_team", "joined_spectators" );

	self delete();
}

onGameEnded( streakName ) // self == placeable
{
	self endon ( "placed" );
	self endon ( "death" );

	level waittill ( "game_ended" );
	
	self onCancel( streakName );
}

onPlayerConnected() // self == placeable
{
	self endon( "death" );

	// when new players connect they need to not be able to use the planted ims
	level waittill( "connected", player );
	player waittill( "spawned_player" );

	// this can't possibly be the owner because the ims is destroyed if the owner leaves the game, so disable use for this player
	self DisablePlayerUse( player );
}

timeOut( streakName )
{
	self endon( "death" );
	level endon ( "game_ended" );
	
	config = level.placeableConfigs[ streakName ];
	lifeSpan = config.lifeSpan;
	
	while ( lifeSpan > 0.0 )
	{
		wait ( 1.0 );
		maps\mp\gametypes\_hostmigration::waitTillHostMigrationDone();
		
		if ( !IsDefined( self.carriedBy ) )
		{
			lifeSpan -= 1.0;
		}
	}
	
	if ( IsDefined( self.owner ) && IsDefined( config.goneVO ) )
	{
		self.owner thread leaderDialogOnPlayer( config.goneVO );
	}
	
	self notify ( "death" );
}

onPlayerJoinedTeam( player ) // self == placeable
{
	self endon( "death" );
	player endon( "disconnect" );

	// when new players connect they need to not be able to use the planted ims
	while( true )
	{
		player waittill( "joined_team" );
		
		// this can't possibly be the owner because the ims is destroyed if the owner leaves the game, so disable use for this player
		self DisablePlayerUse( player );
	}
}

//--------------------------------------------------------------------
removeWeapons()
{
	if ( self HasWeapon( "riotshield_mp" ) )
	{
		self.restoreWeapon = "riotshield_mp";
		self takeWeapon( "riotshield_mp" );
	}	
}

removePerks()
{
	if ( self _hasPerk( "specialty_explosivebullets" ) )
	{
		self.restorePerk = "specialty_explosivebullets";
		self _unsetPerk( "specialty_explosivebullets" );
	}		
}

restoreWeapons()
{
	if ( IsDefined( self.restoreWeapon ) )	
	{
		self _giveWeapon( self.restoreWeapon );
		self.restoreWeapon = undefined;
	}	
}

restorePerks()
{
	if ( IsDefined( self.restorePerk ) )
	{
		self givePerk( self.restorePerk, false );	
		self.restorePerk = undefined;
	}	
}