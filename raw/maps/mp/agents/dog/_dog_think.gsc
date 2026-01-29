#include common_scripts\utility;
#include maps\mp\agents\_scriptedAgents;

main()
{
	self.bLockGoalPos = false;

	self.ownerRadiusSq =				144 * 144;
	self.meleeRadiusSq =				128 * 128;
	self.attackOffset =					25 + self.radius;
	self.attackRadiusSq =				450 * 450;
	self.warningRadiusSq =				550 * 550;
	self.warningZHeight =				128 * 0.75; // min floor to ceiling in a map is 128 units
	self.ownerDamagedRadiusSq =			1500 * 1500; // if the owner takes damage and the attacker is within this radius
	self.dogDamagedRadiusSq =			1500 * 1500; // if the dog takes damage and the attacker is within this radius
	self.keepPursuingTargetRadiusSq	=	1000 * 1000; // stop pursuing the target after the target gets this far away from my owner, unless he's my favorite enemy.
	self.preferredOffsetFromOwner =		76;
	self.minOffsetFromOwner =			50;			// need to keep this above owner.radius + self.radius.
	self.forceAttack =					false; // if we want to send after a target

	self.ignoreCloseFoliage =			true;

	self ScrAgentSetGoalRadius(24);		// dog will get real twitchy about stopping if this falls below 16.

	self thread think();
	self thread watchOwnerDamage();
	self thread watchOwnerDeath();
	self thread watchOwnerTeamChange();

/#
	self thread debug_dog();
#/
}

init()
{
	self.animCBs = SpawnStruct();
	self.animCBs.OnEnter = [];
	self.animCBs.OnEnter[ "idle" ] = maps\mp\agents\dog\_dog_idle::main;
	self.animCBs.OnEnter[ "move" ] = maps\mp\agents\dog\_dog_move::main;
	self.animCBs.OnEnter[ "traverse" ] = maps\mp\agents\dog\_dog_traverse::main;
	self.animCBs.OnEnter[ "melee" ] = maps\mp\agents\dog\_dog_melee::main;

	self.animCBs.OnExit = [];
	self.animCBs.OnExit[ "idle" ] = maps\mp\agents\dog\_dog_idle::end_script;
	self.animCBs.OnExit[ "move" ] = maps\mp\agents\dog\_dog_move::end_script;
	self.animCBs.OnExit[ "melee" ] = maps\mp\agents\dog\_dog_melee::end_script;
	
	self.watchAttackStateFunc = ::watchAttackState;

	self.radius = 15;
	self.height = 40;
}

onEnterAnimState( prevState, nextState )
{
	self notify( "killanimscript" );

	if ( !IsDefined( self.animCBs.OnEnter[ nextState ] ) )
		return;

	if ( prevState == nextState && ( nextState != "traverse" ) )
		return;

	if ( IsDefined( self.animCBs.OnExit[ prevState ] ) )
		self [[ self.animCBs.OnExit[ prevState ] ]] ();

	self.aiState = nextState;

	self [[ self.animCBs.OnEnter[ nextState ] ]]();
}

think()
{
	self endon( "death" );
	level endon( "game_ended" );

	if ( IsDefined( self.owner ) )
	{
		self endon( "owner_disconnect" );
		self thread destroyOnOwnerDisconnect( self.owner );
	}

	self.aiState = "idle";

	// self.aiState comes from code, so we need something to tell us what attack state we're in
	self.attackState = "idle";
	self thread [[self.watchAttackStateFunc]]();

	while ( true )
	{
		if ( self.aiState != "melee" && self readyToMeleeTarget() )
			self enterAIState( "melee" );

		switch ( self.aiState )
		{
		case "idle":
			self updateIdle();
			break;
		case "move":
			self updateMove();
			break;
		case "melee":
			self updateMelee();
			break;
		}
		wait( 0.05 );
	}
}

enterAIState( state )
{
	self ExitAIState( self.aiState );
	self.aiState = state;

	switch ( state )
	{
	case "melee":
		self ScrAgentBeginMelee( self.curMeleeTarget );
		break;
	default:
		break;
	}
}

ExitAIState( state )
{
	switch ( state )
	{
	case "move":
		self.ownerPrevPos = undefined;
		break;
	default:
		break;
	}
}


updateIdle()
{
	self updateMoveToPos();
}

updateMove()
{
	self updateMoveToPos();
}

updateMelee()
{
}


updateMoveToPos()
{
	if ( self.bLockGoalPos )
		return;

	if ( self wantsToContinueRunningToTarget() )
	{
		self ScrAgentSetGoalPos( self getAttackPoint( self.curMeleeTarget ) );
		self.moveMode = "sprint";
		self.bArrivalsEnabled = false;
	}
	else if ( self wantsToAttackTarget() )
	{
		self ScrAgentSetGoalPos( self getAttackPoint( self.enemy ) );
		self.curMeleeTarget = self.enemy;
		self.moveMode = "sprint";
		self.bArrivalsEnabled = false;
	}
	else if ( IsDefined( self.owner ) )
	{
		self.moveMode = "run";
		myPos = self GetPathGoalPos();
		if ( !IsDefined( myPos ) )
			myPos = self.origin;

		// also take into account the owner's stance changes
		currStance = self.owner GetStance();
		if( !IsDefined( self.owner.prevStance ) && IsDefined( self.owner ) )
			self.owner.prevStance = currStance;

		bOwnerHasMoved = !IsDefined( self.ownerPrevPos ) || Distance2DSquared( self.ownerPrevPos, self.owner.origin ) > 100;
		if ( bOwnerHasMoved )
			self.ownerPrevPos = self.owner.origin;

		distFromOwnerSq = Distance2DSquared( myPos, self.owner.origin );
		if ( ( distFromOwnerSq > self.ownerRadiusSq && bOwnerHasMoved ) || self.owner.prevStance != currStance )
		{
			self ScrAgentSetGoalPos( self findPointNearOwner() );
			self.curMeleeTarget = undefined;
			self.owner.prevStance = currStance;
		}

		self.bArrivalsEnabled = true;
	}
	else
	{
		self.bArrivalsEnabled = true;
		self.moveMode = "run";
	}
}

readyToMeleeTarget()
{
	if ( !IsDefined( self.curMeleeTarget ) )
		return false;

	if ( DistanceSquared( self.origin, self.curMeleeTarget.origin ) > self.meleeRadiusSq )
		return false;

	if ( abs( self.origin[2] - self.curMeleeTarget.origin[2] ) > 48 )
		return false;

	return true;
}

wantsToContinueRunningToTarget()
{
	if ( !IsDefined( self.curMeleeTarget ) || !IsDefined( self.enemy ) )
		return false;

	if ( self.curMeleeTarget != self.enemy )
		return false;

	if ( DistanceSquared( self.origin, self.curMeleeTarget.origin ) > self.warningRadiusSq )
		return false;

	if ( IsDefined( self.owner ) )
	{
		if ( !IsDefined( self.favoriteEnemy ) || self.curMeleeTarget != self.favoriteEnemy )
		{
			if ( DistanceSquared( self.owner.origin, self.curMeleeTarget.origin ) > self.keepPursuingTargetRadiusSq )
				return false;
		}
	}

	return true;
}

wantsToAttackTarget()
{
	if ( !IsDefined( self.enemy ) )
		return false;

	if( self.forceAttack )
		return true;

	// first make sure the enemy is within the same height as the dog
	if( abs( self.origin[ 2 ] - self.enemy.origin[ 2 ] ) > self.warningZHeight )
		return false;

	if ( DistanceSquared( self.origin, self.enemy.origin ) > self.attackRadiusSq )
		return false;

	if ( IsDefined( self.owner ) )
	{
		if ( !IsDefined( self.favoriteEnemy ) || self.enemy != self.favoriteEnemy )
		{
			if ( DistanceSquared( self.owner.origin, self.enemy.origin ) > self.keepPursuingTargetRadiusSq )
				return false;
		}
	}

	return true;
}

wantsToGrowlAtTarget()
{
	if ( !IsDefined( self.enemy ) )
		return false;

	// first make sure the enemy is within the same height as the dog
	if( abs( self.origin[ 2 ] - self.enemy.origin[ 2 ] ) <= self.warningZHeight )
	{
		// now see if the enemy is within the warning radius
		distSq = DistanceSquared( self.origin, self.enemy.origin );
		if ( distSq < self.warningRadiusSq && distSq > self.attackRadiusSq )
			return true;
	}

	return false;
}

getAttackPoint( enemy )
{
	meToTarget = enemy.origin - self.origin;
	meToTarget = VectorNormalize( meToTarget );
	//return enemy.origin;	// <- obviously not a good idea.
	attackPoint = enemy.origin - meToTarget * self.attackOffset;

	if ( !self CanMovePointToPoint( enemy.origin, attackPoint ) )
		return enemy.origin;

	return attackPoint;
}

// > 0 right
cross2D( a, b )
{
	return a[0] * b[1] - b[0] * a[1];
}

// finds a valid point near the owner with two traces (nearest node and ground trace) by finding
// a point on the pathgraph somewhere.  nodes and points on node links are pre-determined to be valid.
// except i might get in trouble if the player's closest node is a negotation begin node...
findPointNearOwner()
{
	assert( IsDefined( self.owner ) );

	meToOwner = VectorNormalize( self.owner.origin - self.origin );
	ownerForward = AnglesToForward( self.owner.angles );
	ownerForward = ( ownerForward[0], ownerForward[1], 0 );
	ownerForward = VectorNormalize( ownerForward );
	currentDirFromOwner = cross2D( meToOwner, ownerForward );

	nodeClosestToOwner = GetClosestNodeInSight( self.owner.origin );
	if ( !IsDefined( nodeClosestToOwner ) )
		return self.origin;

	links = GetLinkedNodes( nodeClosestToOwner );

	distanceWeight = 10;
	angleWeight = 20;

	// prefer nodes to side which i'm already on (and slightly ahead).  else behind owner.  else in front of.
	bestScore = 0;
	bestLink = 0;

	links[ links.size ] = nodeClosestToOwner;
	foreach ( link in links )
	{
		score = 0;

		ownerToLink = link.origin - self.owner.origin;
		ownerToLinkDist = Length( ownerToLink );
		if ( ownerToLinkDist >= self.preferredOffsetFromOwner )
			score += distanceWeight;
		else if ( ownerToLinkDist < self.minOffsetFromOwner )
		{
			scale = 1 - ( self.minOffsetFromOwner - ownerToLinkDist ) / self.minOffsetFromOwner;
			score += distanceWeight * scale * scale;
		}
		else
			score += distanceWeight * ownerToLinkDist / self.preferredOffsetFromOwner;

		ownerToLink = ownerToLink / ownerToLinkDist;
		angleCos = VectorDot( ownerForward, ownerToLink );
		
		// situate the dog in position depending on the owner's stance
		//	standing == ahead
		//	crouching == next to
		//	prone == behind
		currStance = self.owner GetStance();
		updateAng = false;
		switch( currStance )
		{
		case "stand":
			if( angleCos < cos( 35 ) && angleCos > cos( 45 ) )
				updateAng = true;
			break;
		case "crouch":
			if( angleCos < cos( 75 ) && angleCos > cos( 90 ) )
				updateAng = true;
			break;
		case "prone":
			if( angleCos < cos( 125 ) && angleCos > cos( 135 ) )
				updateAng = true;
			break;
		}
		
		if( updateAng )
		{
			dirFromOwner = cross2D( ownerToLink, ownerForward );
			if ( dirFromOwner * currentDirFromOwner > 0 )		// i.e. both the same sign
				score += angleWeight;
			else
				score += angleWeight * 0.75;
		}

		if( score > bestScore )
		{
			bestScore = score;
			bestLink = link;
		}
	}

	if ( !IsDefined( bestLink ) )
		return self.origin;

	ownerToNode = bestLink.origin - self.owner.origin;
	ownerToNodeDist = Length( ownerToNode );
	if ( ownerToNodeDist > self.preferredOffsetFromOwner )
	{
		ownerToOwnerNode = nodeClosestToOwner.origin - self.owner.origin;
		if ( VectorDot( ownerToOwnerNode, ownerToNode / ownerToNodeDist ) < 0 )	// owner is between nodeClosest and bestLink.
		{
			resultPos = bestLink.origin;
		}
		else
		{
			ownerNodeToNode = VectorNormalize( bestLink.origin - nodeClosestToOwner.origin );
			resultPos = nodeClosestToOwner.origin + ownerNodeToNode * self.preferredOffsetFromOwner;
		}
	}
	else
	{
		resultPos = bestLink.origin;
	}
	
	resultPos = self DropPosToGround( resultPos );

	if ( !IsDefined( resultPos ) )	// technically, we should probably go down through the list of nodes until we find a good one.
		return self.origin;

	return resultPos;
}

destroyOnOwnerDisconnect( owner )
{
	self endon( "death" );
	owner waittill_any( "disconnect", "joined_team" );

	self notify( "killanimscript" );
	if ( IsDefined( self.animCBs.OnExit[ self.aiState ] ) )
		self [[ self.animCBs.OnExit[ self.aiState ] ]] ();

	self notify( "owner_disconnect" );
	self Suicide();
}

watchAttackState() // self == dog
{
	self endon( "death" );
	level endon( "game_ended" );

	while( true )
	{
		if( self.aiState == "melee" )
		{
			if( self.attackState != "melee" )
			{
				self.attackState = "melee";
			}
		}
		else if( self wantsToAttackTarget() )
		{
			if( self.attackState != "attacking" )
			{
				self.attackState = "attacking";
				self thread playBark( "attacking" );
			}
		}
		else if( !self wantsToAttackTarget() )
		{
			if( self.attackState != "warning" )
			{
				if( self wantsToGrowlAtTarget() )
				{
					self.attackState = "warning";
					self thread playGrowl( "warning" );
				}
				else
				{
					self.attackState = self.aiState;
				}
			}
			else
			{
				if( !self wantsToGrowlAtTarget() )
				{
					self.attackState = self.aiState;
				}
			}
		}

		wait( 0.05 );
	}
}

playBark( state ) // self == dog
{
	self endon( "death" );
	level endon( "game_ended" );

	if( !isDefined( self.barking_sound ) )
	{
		self PlaySound( "anml_dog_bark" );
		self.barking_sound = true;
		self thread watchBarking();
	}
}

watchBarking() // self == dog
{
	self endon( "death" );
	level endon( "game_ended" );

	wait( RandomIntRange( 5, 10 ) );
	self.barking_sound = undefined;
}

playGrowl( state ) // self == dog
{
	self endon( "death" );
	level endon( "game_ended" );

	// while the dog is in this state randomly play growl
	while( self.attackState == state )
	{
		self PlaySound( "anml_dog_growl" );
		wait( RandomIntRange( 3, 6 ) );
	}
}

watchOwnerDamage() // self == dog
{
	self endon( "death" );
	level endon( "game_ended" );

	while( true )
	{
		if( !IsDefined( self.owner ) )
			return;
		
		self.owner waittill( "damage", damage, attacker );

		if( IsPlayer( attacker ) )
		{
			// is the dog close to the owner?
			if( DistanceSquared( self.owner.origin, self.origin ) > self.ownerDamagedRadiusSq )
				continue;

			// is the dog already attacking?
			if( self.attackState == "attacking" )
				continue;

			// is the attacker within the owner damaged range?
			if( DistanceSquared( self.owner.origin, attacker.origin ) <= self.ownerDamagedRadiusSq )
			{
				self.favoriteEnemy = attacker;
				self.forceAttack = true;
				self thread watchFavoriteEnemyDeath();
			}
		}
	}
}

watchOwnerDeath() // self == dog
{
	self endon( "death" );
	level endon( "game_ended" );

	while( true )
	{
		if( !IsDefined( self.owner ) )
			return;
		
		self.owner waittill( "death" );

		switch( level.gameType )
		{
			case "sd":
				// the dog needs to die when the owner dies because killstreaks go away when the owner dies in sd
				killDog();
				break;
			case "sr":
				// the dog needs to die when the owner is eliminated because killstreaks go away when the owner dies in sr
				result = level waittill_any_return( "sr_player_eliminated", "sr_player_respawned" );
				if( IsDefined( result ) && result == "sr_player_eliminated" )
					killDog();
				break;
		}
	}
}

watchOwnerTeamChange() // self == dog
{
	self endon( "death" );
	level endon( "game_ended" );

	while( true )
	{
		if( !IsDefined( self.owner ) )
			return;
		
		result = self.owner waittill_any_return_no_endon_death( "joined_team", "joined_spectators" );

		if( IsDefined( result ) && ( result == "joined_team" || result == "joined_spectators" ) )
			killDog();
	}
}

killDog() // self == dog
{
	self thread [[ level.agent_funcs[ self.agent_type ][ "on_damaged" ] ]](
		level, // eInflictor The entity that causes the damage.(e.g. a turret)
		undefined, // eAttacker The entity that is attacking.
		self.health + 1, // iDamage Integer specifying the amount of damage done
		0, // iDFlags Integer specifying flags that are to be applied to the damage
		"MOD_CRUSH", // sMeansOfDeath Integer specifying the method of death
		"none", // sWeapon The weapon number of the weapon used to inflict the damage
		( 0, 0, 0 ), // vPoint The point the damage is from?
		(0, 0, 0), // vDir The direction of the damage
		"none", // sHitLoc The location of the hit
		0 // psOffsetTime The time offset for the damage
	);
}

watchFavoriteEnemyDeath() // self == dog
{
	self notify( "watchFavoriteEnemyDeath" );
	self endon( "watchFavoriteEnemyDeath" );

	self endon( "death" );

	self.favoriteEnemy waittill_any_timeout( 5.0, "death", "disconnect" );

	self.favoriteEnemy = undefined;
	self.forceAttack = false;
}

/#
debug_dog() // self == dog
{
	self endon( "death" );

	while( true )
	{
		if( GetDvarInt( "scr_debugdog" ) > 0 )
		{
			start = self.origin;
			end = self.origin;
			if( IsDefined( self.enemy ) )
				end = self.enemy.origin;
			color = [ 1, 1, 1 ];

			switch( self.attackState )
			{
			case "idle":
				color = [ 1, 1, 1 ];
				break;
			case "move":
				color = [ 0, 1, 0 ];
				break;
			case "traverse":
				color = [ 0.5, 0.5, 0.5 ];
				break;
			case "melee":
			case "attacking":
				color = [ 1, 0, 0 ];
				break;
			case "warning":
				color = [ 0.8, 0.8, 0 ];
				break;
			default:
				break;
			}
			
			Print3d( self.origin + ( 0, 0, 10 ), self.attackState, ( color[0], color[1], color[2] ) );
			Line( start, end, ( color[0], color[1], color[2] ) );
		}

		wait( 0.05 );
	}
}
#/