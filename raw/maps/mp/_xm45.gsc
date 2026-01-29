#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;

init()
{
	level.MAX_XM45_MINES = 4;
	level.XM45_TRIGGER_RADIUS = 128;
	level.XM45_EXPLO_RADIUS = 256;
	level.XM45_TRIGGER_HEIGHT = 72;
	level.XM45_MIN_DMG = 5;
	level.XM45_MAX_DMG = 35;
	level.CONCUSSED_TIME = 0.75;
	level.XM45MAXHEALTH = 35;
	
	thread onPlayerConnect();
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

	for(;;)
	{
		self waittill( "spawned_player" );
		
		weapons = self GetWeaponsListPrimaries();
		self.xm45MinesActive = [];
		
		self thread watchXM45Fire();
		self thread watchPlayerDeath();
		self thread watchPlayerDisconnect();
	}
}


watchXM45Fire()
{
	self endon( "death" );
	self endon( "disconnect" );
	
	for(;;)
	{
		self waittill( "projectile_impact", weapon, impactPoint, normal );
		
		if( weapon != "xm45_mp" )
			continue;
		
		mine = spawnMine( impactPoint );
		self manageXm45Mines( mine );
		mine thread watchMineForDeath();
		self thread watchForProxyDetonation( mine );
	}
}


watchMineForDeath()
{
	self endon( "delete" );

	self waittill( "death" );
		
	if ( isDefined( self ) )
		self.owner detonateMine( self, true );
	
	//delete killcamEnt?
	wait(1);
	
	if ( isDefined( self.killCamEnt ) )
		self.killCameEnt delete();

}


watchForProxyDetonation( mine )
{
	self endon( "death" );
	self endon( "disconnect" );
	mine endon( "death" );
	
	wait( 1 );  //prime delay time
	
	if( !isDefined(mine) )
		return;
	
	for( ;; )
	{
		mine.trigger waittill( "trigger", player );
		
		if( !isDefined(mine) )
			return;
		
		if ( isDefined( player.owner ) )
			continue;
		
		if ( player == mine.owner )
			continue;
		
		if( level.teamBased && player.team == mine.owner.team )
			continue;
		
		self detonateMine( mine );
	}
}


spawnMine( impactPoint )
{
	xm45mine = spawn( "script_model", impactPoint );
	
	trigger = Spawn( "trigger_radius", impactPoint, 0, level.XM45_TRIGGER_RADIUS, level.XM45_TRIGGER_HEIGHT );
	xm45mine.trigger = trigger;
	xm45mine.health = level.XM45MAXHEALTH;
	xm45mine.team = self.team;
	xm45mine.owner = self;
	xm45mine setCanDamage( true );
	xm45mine.bombSquadModel = xm45mine thread maps\mp\gametypes\_weapons::createBombSquadModel( "projectile_bouncing_betty_grenade_bombsquad", "tag_origin", self );
	
	xm45mine.killCamEnt = Spawn( "script_model", impactPoint + ( 0,0,65 ) );
	xm45mine.killCamEnt SetScriptMoverKillCam( "explosive" );
	xm45mine.killCamEnt LinkTo( xm45Mine );
	
	//xm45mine SetModel( "projectile_semtex_grenade" );
	xm45mine SetModel( "projectile_bouncing_betty_grenade" );
	
	xm45mine.damagetaken = 0;
	//xm45mine.maxhealth = 1025; //we dont want code deleting these
	xm45mine thread mineBeacon();
	
	return xm45mine;
}

manageXM45Mines( mine )
{
	if( self.xm45MinesActive.size < level.MAX_XM45_MINES )
	{
		self.xm45MinesActive[ self.xm45MinesActive.size ] = mine;
	}
	else
	{
		self detonateMine( self.xm45MinesActive[ 0 ], true );
		self.xm45MinesActive[ self.xm45MinesActive.size ] = mine;
	}
}


detonateMine( mine, noDelay )
{
	if ( !isDefined(mine) )
		return;
	
	if ( isDefined(mine.trigger) )
		mine.trigger delete();
	
	mine playsound ("xm45_trigger");
	
	if( !isDefined( noDelay ) || noDelay == false )
	{
		wait(.5);
		wait(randomFloat(.5));
	}
	
	if ( !isDefined( mine ) )
		return;
	
	PlayFX( level.mine_explode, mine.origin );
	self playsound("explo_mine");
	RadiusDamage( mine.origin + (0,0,10), level.XM45_EXPLO_RADIUS, level.XM45_MAX_DMG, level.XM45_MIN_DMG, mine, "MOD_EXPLOSIVE", "xm45_mp" );
	mine thread maps\mp\gametypes\_shellshock::grenade_earthQuake();
		
	mineOwner = mine.owner;
	
	mine notify( "death" );
	
	mine delete();
	mineOwner reOrderMines();
}


reOrderMines()
{
	newarray = [];
	
	foreach ( index, value in self.xm45MinesActive )
	{
		if ( !isDefined( value ) )
			continue;
		
		newarray[ newarray.size ] = value;
	}
	
	self.xm45MinesActive = newarray;
}


watchPlayerDeath()
{
	self waittill( "death" );
	
	foreach( mine in self.xm45MinesActive )
	{
		if ( isDefined( mine.trigger) )
			mine.trigger delete();
		
		mine notify( "death" );
		mine notify( "delete" );
		mine delete();
	}
	
}

watchPlayerDisconnect()
{
	self waittill( "disconnect" );
	
	foreach( mine in self.xm45MinesActive )
	{
		if( isDefined( mine) )
		{
			if ( isDefined( mine.trigger) )
				mine.trigger delete();
			
			mine notify( "death" );
			mine notify( "delete" );
			mine delete();
		}
	}
	
}

mineBeacon()
{
	wait( 0.05 );
	
	if ( !isDefined( self ) )
		return;
	
	effect["friendly"] = SpawnFx( level.mine_beacon["friendly"], self getTagOrigin( "tag_fx" ) + (0,0,1.5) );
	effect["enemy"] = SpawnFx( level.mine_beacon["enemy"], self getTagOrigin( "tag_fx" ) + (0,0,1.5) );

	self thread mineBeaconTeamUpdater( effect );
	self waittill( "death" );
	
	effect["friendly"] delete();
	effect["enemy"] delete();
}

mineBeaconTeamUpdater( effect )
{
	self endon ( "death" );
	
	ownerTeam = self.owner.team;
	
	// PlayFXOnTag fails if run on the same frame the parent entity was created
	wait ( 0.05 );
	
	TriggerFx( effect["friendly"] );
	TriggerFx( effect["enemy"] );
	
	for ( ;; )
	{
		effect["friendly"] Hide();
		effect["enemy"] Hide();

		foreach ( player in level.players )
		{
			if ( level.teamBased )
			{
				if ( player.team == ownerTeam )
					effect["friendly"] showToPlayer( player );
				else
					effect["enemy"] showToPlayer( player );
			}
			else
			{
				if ( player == self.owner )
					effect["friendly"] showToPlayer( player );
				else
					effect["enemy"] showToPlayer( player );
			}
		}
		
		level waittill_either ( "joined_team", "player_spawned" );
	}
}
