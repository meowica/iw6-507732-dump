#include maps\mp\_utility;
#include common_scripts\utility;

init()
{
}

shellshockOnDamage( cause, damage )
{
	if ( self maps\mp\_flashgrenades::isFlashbanged() )
		return; // don't interrupt flashbang shellshock
	
	if ( cause == "MOD_EXPLOSIVE" ||
	     cause == "MOD_GRENADE" ||
	     cause == "MOD_GRENADE_SPLASH" ||
	     cause == "MOD_PROJECTILE" ||
	     cause == "MOD_PROJECTILE_SPLASH" )
	{	
		if ( damage > 10 )
		{
			if (  isDefined(self.shellShockReduction) && self.shellShockReduction )
				self shellshock( "frag_grenade_mp", self.shellShockReduction );
			else	
				self shellshock("frag_grenade_mp", 0.5);
		}
	}
}

endOnDeath()
{
	self waittill( "death" );
	waittillframeend;
	self notify ( "end_explode" );
}

grenade_earthQuake()
{
	self thread endOnDeath();
	self endon( "end_explode" );
	self waittill( "explode", position );
	PlayRumbleOnPosition( "grenade_rumble", position );
	Earthquake( 0.5, 0.75, position, 800 );
	
	foreach ( player in level.players )
	{
		if ( player isUsingRemote() )
			continue;
			
		if ( distance( position, player.origin ) > 600 )
			continue;
			
		if ( player DamageConeTrace( position ) )
			player thread dirtEffect( position );
		
		// do some hud shake
		player SetClientDvar( "ui_hud_shake", 1 );
	}
}


dirtEffect( position )
{
	self notify( "dirtEffect" );
	self endon( "dirtEffect" );

	self endon ( "disconnect" );
	
	forwardVec = VectorNormalize( AnglesToForward( self.angles ) );
	rightVec = VectorNormalize( AnglesToRight( self.angles ) );
	grenadeVec = VectorNormalize( position - self.origin );
	
	fDot = VectorDot( grenadeVec, forwardVec );
	rDot = VectorDot( grenadeVec, rightVec );
	
/#
	if( GetDvarInt( "g_debugDamage" ) )
	{
		PrintLn( fDot );
		PrintLn( rDot );
	}
#/
	
	string_array = [ "death", "damage" ];

	// center
	if( fDot > 0 && fDot > 0.5 && self GetCurrentWeapon() != "riotshield_mp" )
	{
		self SetClientOmnvar( "ui_screen_effects_dirt_center", true );
		
		if( IsAlive( self ) )
			self waittill_any_in_array_or_timeout( string_array, 2.0 );
	}
	else if( abs( fDot ) < 0.866 )
	{
		// right
		if( rDot > 0 )
		{
			self SetClientOmnvar( "ui_screen_effects_dirt_right", true );

			if( IsAlive( self ) )
				self waittill_any_in_array_or_timeout( string_array, 2.0 );
		}
		// left
		else
		{
			self SetClientOmnvar( "ui_screen_effects_dirt_left", true );

			if( IsAlive( self ) )
				self waittill_any_in_array_or_timeout( string_array, 2.0 );
		}
	}
}

bloodEffect( position )
{
	self notify( "bloodEffect" );
	self endon( "bloodEffect" );

	self endon ( "disconnect" );

	forwardVec = VectorNormalize( AnglesToForward( self.angles ) );
	rightVec = VectorNormalize( AnglesToRight( self.angles ) );
	damageVec = VectorNormalize( position - self.origin );

	fDot = VectorDot( damageVec, forwardVec );
	rDot = VectorDot( damageVec, rightVec );

/#
	if( GetDvarInt( "g_debugDamage" ) )
	{
		PrintLn( fDot );
		PrintLn( rDot );
	}
#/

	string_array = [ "death", "damage" ];

	// center
	if( fDot > 0 && fDot > 0.5 )
	{
		self SetClientOmnvar( "ui_screen_effects_blood_center", true );

		if( IsAlive( self ) )
			self waittill_any_in_array_or_timeout( string_array, 7.0 );
	}
	else if( abs( fDot ) < 0.866 )
	{
		// right
		if( rDot > 0 )
		{
			self SetClientOmnvar( "ui_screen_effects_blood_right", true );

			if( IsAlive( self ) )
				self waittill_any_in_array_or_timeout( string_array, 7.0 );
		}
		// left
		else
		{
			self SetClientOmnvar( "ui_screen_effects_blood_left", true );

			if( IsAlive( self ) )
				self waittill_any_in_array_or_timeout( string_array, 7.0 );
		}
	}
}

bloodMeleeEffect() // self == player
{
	self endon ( "disconnect" );

	// HACK: waiting for the knife to come out before showing the blood, this needs to come from somewhere to match perfectly
	wait( 0.5 );

	self SetClientOmnvar( "ui_screen_effects_blood_melee", true );

	if( IsAlive( self ) )
		self waittill_notify_or_timeout( "death", 1.5 );
}

c4_earthQuake()
{
	self thread endOnDeath();
	self endon( "end_explode" );
	self waittill( "explode", position );
	PlayRumbleOnPosition( "grenade_rumble", position );
	Earthquake( 0.4, 0.75, position, 512 );

	foreach( player in level.players )
	{
		if( player isUsingRemote() )
			continue;

		if( distance( position, player.origin ) > 512 )
			continue;

		if( player DamageConeTrace( position ) )
			player thread dirtEffect( position );

		// do some hud shake
		player SetClientDvar( "ui_hud_shake", 1 );
	}
}

barrel_earthQuake()
{
	position = self.origin;
	PlayRumbleOnPosition( "grenade_rumble", position );
	Earthquake( 0.4, 0.5, position, 512 );

	foreach( player in level.players )
	{
		if( player isUsingRemote() )
			continue;

		if( distance( position, player.origin ) > 512 )
			continue;

		if( player DamageConeTrace( position ) )
			player thread dirtEffect( position );

		// do some hud shake
		player SetClientDvar( "ui_hud_shake", 1 );
	}
}


artillery_earthQuake()
{
	position = self.origin;
	PlayRumbleOnPosition( "artillery_rumble", self.origin );
	Earthquake( 0.7, 0.5, self.origin, 800 );

	foreach( player in level.players )
	{
		if( player isUsingRemote() )
			continue;

		if( distance( position, player.origin ) > 600 )
			continue;

		if( player DamageConeTrace( position ) )
			player thread dirtEffect( position );

		// do some hud shake
		player SetClientDvar( "ui_hud_shake", 1 );
	}
}


stealthAirstrike_earthQuake( position )
{
	PlayRumbleOnPosition( "grenade_rumble", position );
	Earthquake( 1.0, 0.6, position, 2000 );

	foreach( player in level.players )
	{
		if( player isUsingRemote() )
			continue;

		if( distance( position, player.origin ) > 1000 )
			continue;

		if( player DamageConeTrace( position ) )
			player thread dirtEffect( position );

		// do some hud shake
		player SetClientDvar( "ui_hud_shake", 1 );
	}
}


airstrike_earthQuake( position )
{
	PlayRumbleOnPosition( "artillery_rumble", position );
	Earthquake( 0.7, 0.75, position, 1000 );

	foreach( player in level.players )
	{
		if( player isUsingRemote() )
			continue;

		if( distance( position, player.origin ) > 900 )
			continue;

		if( player DamageConeTrace( position ) )
			player thread dirtEffect( position );

		// do some hud shake
		player SetClientDvar( "ui_hud_shake", 1 );
	}
}