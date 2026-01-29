#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;


init()
{
	//sets level.air_start_nodes
	self maps\mp\killstreaks\_helicopter_guard::lbSupport_setAirStartNodes();
	
	//sets level.air_node_mesh
	self maps\mp\killstreaks\_helicopter_guard::lbSupport_setAirNodeMesh();
	
	level.sniper_explode = loadfx( "fx/explosions/sniper_incendiary" );

	level.killStreakFuncs["heli_sniper"] = ::tryUseHeliSniper;
}


tryUseHeliSniper( lifeId, streakName )
{
	closestStart = getClosestStartNode( self.origin ); 
	closestNode = getClosestNode( self.origin ); 	
	
//	context fail cases
	if ( !IsDefined( level.air_node_mesh ) ||
		 !IsDefined( closestStart ) ||
		 !IsDefined( closestNode ) )
	{
		self iPrintLnBold( &"KILLSTREAKS_UNAVAILABLE_IN_LEVEL" );
		return false;		
	}	

	if ( IsDefined( level.chopper ) || IsDefined( level.lbSniper ) )
	{
		self iPrintLnBold( &"KILLSTREAKS_AIR_SPACE_TOO_CROWDED" );
		return false;
	}

	if( currentActiveVehicleCount() >= maxVehiclesAllowed() || level.fauxVehicleCount >= maxVehiclesAllowed() )
	{
		self iPrintLnBold( &"KILLSTREAKS_TOO_MANY_VEHICLES" );
		return false;
	}
	
	//	create heli	
	chopper = createHeli( self, closestStart, streakName, lifeId );
	
	if ( !IsDefined( chopper ) )
		return false;
	
	//	this is where the heli starts
	self thread heliPickup( chopper, streakName );

	return true;
}


createHeli( owner, locationNode, streakName, lifeId )
{
	heightEnt = GetEnt( "airstrikeheight", "targetname" );
	flyHeight = heightEnt.origin[2];
	locIndex = locationNode.origin;
	
	pathGoal = locationNode.origin;
	pathStart = pathGoal + ( AnglesToRight( locationNode.angles ) * 12000 );
	
	pathStart += (0,0,flyHeight);
	
	pathEnd = pathGoal + ( AnglesToRight( locationNode.angles ) * -12000 );
	forward = vectorToAngles( pathGoal - pathStart );
		
	chopper = spawnHelicopter( owner, pathStart, forward, "attack_littlebird_mp" , level.littlebird_model );
	
	if ( !IsDefined( chopper ) )
		return;
		
	chopper maps\mp\killstreaks\_helicopter::addToLittleBirdList( "lbSniper" );
	chopper thread maps\mp\killstreaks\_helicopter::removeFromLittleBirdListOnDeath( "lbSniper" );

	chopper.lifeId = lifeId;	
		
	chopper.forward = forward;
	chopper.pathStart = pathStart;
	chopper.pathGoal = pathGoal;
	chopper.pathEnd = pathEnd;
	chopper.flyHeight = flyHeight;
	chopper.onGroundPos = locationNode.origin;
	chopper.pickupPos = chopper.onGroundPos+(0,0,300);
	chopper.hoverPos = chopper.onGroundPos+(0,0,600);
	
	chopper.forwardYaw = forward[1];
	chopper.backwardYaw = forward[1] + 180;
	if ( chopper.backwardYaw > 360 )
		chopper.backwardYaw-= 360;
	
	chopper.heliType = "littlebird";
	chopper.heli_type = "littlebird";
	chopper.locIndex = locIndex;
	chopper.allowSafeEject = true;
	
	//	damage / existence
	chopper.attractor = Missile_CreateAttractorEnt( chopper, level.heli_attract_strength, level.heli_attract_range );
	chopper.isDestroyed = false;	
	chopper.maxhealth = level.heli_maxhealth;
	chopper thread maps\mp\killstreaks\_helicopter::heli_flares_monitor();
	chopper thread maps\mp\killstreaks\_helicopter::heli_damage_monitor( "heli_sniper" );
	chopper thread heliHealth();
	chopper thread heliDeathCleanup( streakName );
	
	//	ownership
	chopper.owner = owner;
	chopper.team = owner.team;
	chopper thread leaveOnOwnerDisconnect();
	
	//	params	
	chopper.speed = 100;
	chopper.followSpeed = 40;
	chopper setCanDamage( true );
	chopper SetMaxPitchRoll( 45, 45 );	
	chopper Vehicle_SetSpeed( chopper.speed, 100, 40 );
	chopper SetYawSpeed( 120, 60 );
	chopper SetHoverParams( 10, 10, 60 );
	chopper setneargoalnotifydist( 512 );
	chopper.killCount = 0;
	chopper.streakName = "heli_sniper";

	chopper.allowBoard = false;
	chopper.ownerBoarded = false;
	
	return chopper;
}

getBestHeight( centerPoint )
{
	self endon ( "death" );
	self endon ( "crashing" );
	self endon ( "helicopter_removed" );
	self endon ( "heightReturned" );
	
	heightEnt = GetEnt( "airstrikeheight", "targetname" );
	
	if ( IsDefined( heightEnt ) )
		trueHeight = heightEnt.origin[2];
	else if( IsDefined( level.airstrikeHeightScale ) )
		trueHeight = 850 * level.airstrikeHeightScale;
	else
		trueHeight = 850;
	
	bestHeightPoint = BulletTrace( self.origin, self.origin - (0, 0,10000), false, self );	
	bestHeight = bestHeightPoint["position"][2];
	offset = 0;
	offset2 = 0;
	
	for( i = 0; i < 30; i++ )
	{
		wait( 0.05 );
		
		turn = i % 8; 
		
		globalOffset = i*7;
		
		switch ( turn )
		{
		case 0:
			offset = globalOffset;
			offset2 = globalOffset;
			break;
		case 1:
			offset = globalOffset * -1;
			offset2 = globalOffset * -1;
			break;
		case 2:
			offset = globalOffset * -1;
			offset2 = globalOffset;
			break;
		case 3:
			offset = globalOffset;
			offset2 = globalOffset * -1;
			break;
		case 4:
			offset = 0;
			offset2 = globalOffset * -1;
			break;
		case 5:
			offset = globalOffset * -1;
			offset2 = 0;
			break;
		case 6:
			offset = globalOffset;
			offset2 = 0;
			break;
		case 7:
			offset = 0;
			offset2 = globalOffset;
			break;	
		
		default:
			break;
		}
		
		trace = BulletTrace( centerPoint + (offset, offset2, 1000), centerPoint - (offset, offset2,10000), true, self );		
		//self thread drawLine( centerPoint + (offset, offset2, 1000), centerPoint - (offset, offset2,10000), 120, (1,0,0) );
		
		if ( trace["position"][2] + 145 > bestHeight )
		{
			bestHeight = trace["position"][2] + 145;
			//self thread drawLine( centerPoint, trace["position"] + (0,0,125), 120, (0,0,1) );
		}
	}
	
	return bestHeight;
}

getRandomNeighborNode()
{
	rand = RandomIntRange( 0, self.currentNode.neighbors.size);
	return self.currentNode.neighbors[rand];
}

getClosestEnemyNode( pos ) // self == lb
{
	// gets the linked node that is closest to the current position and moving towards the position passed in
	closestNode = undefined;
	totalDistance = Distance2D( self.currentNode.origin, pos );
	closestDistance = totalDistance;
	
	tempDistArray = [];
	
	// loop through each neighbor and find the closest to the final goal
	foreach( loc in self.currentNode.neighbors )
	{ 	
		nodeDistance = Distance2D( loc.origin, pos );
		
		if ( nodeDistance < totalDistance && nodeDistance < closestDistance )
		{
			tempDistArray[ tempDistArray.size ] = loc;
			
			closestNode = loc;
			closestDistance = nodeDistance;
		}
	}
	
	if ( !isdefined(closestNode) )
		return self.currentNode;
	else if ( tempDistArray.size > 0 )
		return tempDistArray[ tempDistArray.size - 1 ] ;
	else
		return tempDistArray[ tempDistArray.size ] ;
}


//Higher confidence (but more expensive) point finding than just distance
getBestPoint()
{
	validEnemies = [];
	bestDistance = 999999999;
	bestPoint = undefined;
	
	points = GetEntArray( "mp_airsupport", "classname" );

	foreach ( player in level.players )
	{
		if ( !isReallyAlive( player ) )
			continue;

		if ( player.team == self.team )
			continue;
		
		if ( player.team == "spectator" )
			continue;
		
		validEnemies[validEnemies.size] = player;
	}

	foreach ( point in points )
	{
		point.enemsInRange = 0;
		
		foreach( enem in validEnemies )
		{
			squareDistance = distanceSquared( enem.origin, point.origin );
			
			if ( squareDistance < 1048576 )
			{
				if ( BulletTracePassed( enem.origin, point.origin, false, enem ) ) 
					point.enemsInRange++;
				
				wait( 0.05);		
			}
		}
		
		if ( !isdefined( bestPoint ) || bestPoint.enemsInRange < point.enemsInRange )
			bestPoint = point;
	}
	
	return ( bestPoint.origin );
}


getClosestLinkedNode( pos ) // self == lb
{
	// gets the linked node that is closest to the current position and moving towards the position passed in
	closestNode = undefined;
	
	if ( !IsDefined( self.currentNode.script_parameters ) || self.currentNode.script_parameters != "pickupNode" )
	{
		totalDistance = Distance2D( self.currentNode.origin, pos ) + 6000;
	}
	else
	{
		totalDistance = Distance2D( self.currentNode.origin, pos );
	}
	
	closestDistance = totalDistance;
	
	// loop through each neighbor and find the closest to the final goal
	foreach( loc in self.currentNode.neighbors )
	{ 	
		if ( IsDefined( loc.script_parameters ) && loc.script_parameters == "pickupNode" )
			nodeDistance = Distance2D( loc.origin, pos );
		else
			nodeDistance = Distance2D( loc.origin, pos ) + 700;
		
		if ( nodeDistance < totalDistance && nodeDistance < closestDistance )
		{
			closestNode = loc;
			closestDistance = nodeDistance;
		}
	}
	
	if ( !isdefined(closestNode) )
		return self.currentNode;
	else if ( Distance2D( self.currentNode.origin, pos ) < closestDistance  && ( IsDefined( self.currentNode.script_parameters ) && self.currentNode.script_parameters == "pickupNode" ) )
		return self.currentNode;
	else
		return closestNode;
}


ChopperSniperfollowPlayer( streakName )
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "crashing" );
	self endon( "leaving" );
	self endon ("picked_up_passenger");
	
	self.owner endon( "disconnect" );	
	self.owner endon( "joined_team" );
	self.owner endon( "joined_spectators" );
	
	self Vehicle_SetSpeed( self.followSpeed, 15, 10 );
			
	while( true )
	{
		currentNode = getClosestLinkedNode( self.owner.origin );
		
		while ( ( IsDefined( currentNode ) && currentNode != self.currentNode ) || ( ! IsDefined( self.currentNode.script_parameters ) || self.currentNode.script_parameters != "pickupNode" ) )
		{
			if ( IsDefined(self.trigger) )
				self.trigger delete();
				
			self Vehicle_SetSpeed( self.followSpeed, 15, 10 );
			
			self.currentNode = currentNode;
			self moveToPlayer();
			wait ( .25 );
			currentNode = getClosestLinkedNode( self.owner.origin );
			self.movedLow = false;
		}
		
		if ( IsDefined( self.movedLow ) && self.movedLow )
		{
			wait 5;
			continue;	
		}
		
		//get low position
		lowTempHeight = self getBestHeight( self.origin );
		lowHeightPos = self.currentNode.origin * (1,1,0);
		lowHeightPos = lowHeightPos + (0,0,lowTempHeight);
		
		//self thread drawLine( self.origin, lowHeightPos, 120 );
		
		//wait till stopped at node
		if ( IsDefined( self.inTransit ) && self.inTransit )
			self waittill( "hit_goal" );

		//Begin to lower
		self setVehGoalPos( lowHeightPos, 16 );
		self waittill( "goal" );
		
		self.movedLow = true;
		
		//get ground pos	
		groundPosition = getGroundPosition( self.origin, 2 );
		self.allowBoard = true;
		self thread heliBoard( streakName, groundPosition );
		
		wait( 5 );
	}
}


heliPickup( chopper, streakName )
{	
	level endon( "game_ended" );
	chopper endon( "death" );
	chopper endon( "crashing" );
	chopper endon( "owner_disconnected" );
	chopper endon( "owner_death" );
	
	closestStartNode = getClosestStartNode( self.origin );	
	
	if( IsDefined( closestStartNode.angles ) )
		startAng = closestStartNode.angles;
	else
		startAng = ( 0, 0, 0);

	flyHeight = self maps\mp\killstreaks\_airdrop::getFlyHeightOffset( self.origin );	
	
	closestNode = getClosestNode( self.origin );	
	forward = anglesToForward( self.angles );
	
	targetPos = ( closestNode.origin*(1,1,0) ) + ( (0,0,1)*flyHeight ) + ( forward * -100 );
	chopper.targetPos = targetPos;    
	chopper.currentNode = closestNode;
	
	self thread movePlayerToChopper(chopper);
	
	chopper SetYawSpeed( 1, 1, 1, 0.1 );

	chopper notify("picked_up_passenger");
	chopper Vehicle_SetSpeed( chopper.speed, 100, 40 );
	
	self.OnHeliSniper = true;

	//	only now end and leave if owner dies (since they can't get back on)
	chopper endon( "owner_death" );
	chopper thread leaveOnOwnerDeath();
	chopper thread pushCorpseOnOwnerDeath();
	
	chopper setVehGoalPos( self.origin + ( 0,0,1000 ), 1 );
	
	chopper waittill ( "near_goal" );
	
	chopper thread heliMovementControl();
	chopper thread heliCreateLookAtEnt();
	
	wait( 90 );
	chopper notify( "dropping" );
	chopper thread heliReturnToDropsite();
	chopper waittill( "at_dropoff" );
	//chopper notify( "dropping" );
	
	chopper Vehicle_SetSpeed( 60 );
	chopper SetYawSpeed( 180, 180, 180, .3 );

	wait( 1 );
	
	//remove all cool stuff
	self thread setTempNoFallDamage();
	self unlink();		
	self allowJump( true );
	self setStance( "stand" );
	self.OnHeliSniper = false;
	self takeWeapon( "iw5_barrettexp_mp_barrettscope" );
	self enableWeaponSwitch();
	self switchToWeapon( self getLastWeapon() );
	
	wait( 1 );
	
	chopper thread heliLeave();
}

movePlayerToChopper( chopper )
{
	self endon( "disconnect" );
	
	self VisionSetNakedForPlayer( "black_bw", 0.50 );
	blackOutWait = self waittill_any_timeout( 0.50, "death" );
	maps\mp\gametypes\_hostmigration::waitTillHostMigrationDone();
	
	if ( blackOutWait == "death" )
	{
		self thread maps\mp\killstreaks\_killstreaks::clearRideIntro( 1.0 );
	}
	
	//Warping In Player
	chopper attachPlayerToChopper();
	chopper giveCoolAssGun();

	if ( blackOutWait != "disconnect" ) 
	{
		self thread maps\mp\killstreaks\_killstreaks::clearRideIntro( 1.0, .75 );
		
		if ( self.team == "spectator" )
			return "fail";
	}
}

heliCreateLookAtEnt()
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "crashing" );
	self endon( "leaving" );
	self.owner endon( "death" );
	
	placementOrigin = self.origin + AnglesToRight( self.owner.angles ) * 1000;
		
	self.LookAtEnt = Spawn( "script_origin", placementOrigin );
	self SetLookAtEnt( self.LookAtEnt );
	self SetYawSpeed( 360, 120 );
	
	for( ;; )
	{
		wait( .25 );
		placementOrigin = self.origin + AnglesToRight( self.owner.angles ) * 1000;
		self.LookatEnt.origin = placementOrigin;
	}
}

attachPlayerToChopper()
{
	//	stow any carry items
	self.owner notify( "force_cancel_sentry" );
	self.owner notify( "force_cancel_ims" );
	self.owner notify( "cancel_carryRemoteUAV" );	
	wait( 0.05 );
	
	self.owner setPlayerAngles( self getTagAngles( "TAG_PLAYER_ATTACH_LEFT" ) + ( 30,0,0 ) );
	self.owner PlayerLinkToDelta( self, "TAG_PLAYER_ATTACH_LEFT", 0, 0, 120, 10, 70, true );
	self.owner setStance( "crouch" );
	self.owner allowJump( false );
	
	self thread reEquipLightArmor();
	
	self.ownerBoarded = true;
	self notify( "boarded" );
		
	self.owner.chopper = self;
}


ChopperSniperFindTargets()
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "crashing" );
	self endon( "leaving" );
	self endon ("picked_up_passenger");
	
	self.owner endon( "disconnect" );	
	self.owner endon( "joined_team" );
	self.owner endon( "joined_spectators" );
	
	self Vehicle_SetSpeed( self.followSpeed, 15, 10 );
	
	while( true )
	{
		self.moveMsg.alpha = 1;
		self.owner waittill( "change_position" );
		self.moveMsg.alpha = 0;
		
		startNode = self.currentNode;
		
		//probably best point based on enemy locations
		enemyPos = getAverageEnemyPosition();
		currentNode = getClosestEnemyNode( enemyPos );
		
		//moveing anyway to random neighbor node (we could store a list here to avoid moving back and forth)
		if ( currentNode == startNode )
			currentNode = self getRandomNeighborNode();
		
		while ( IsDefined( currentNode ) && currentNode != self.currentNode )
		{
			if ( IsDefined(self.trigger) )
				self.trigger delete();
				
			self Vehicle_SetSpeed( self.followSpeed, 15, 10 );
			
			self.currentNode = currentNode;
			
			self moveToTarget();
			wait ( .25 );
			self.movedLow = false;
		}
	}
}


getAverageEnemyPosition()
{
	enemyPoints = [];
	
	foreach( player in level.players )
	{
		if ( player == self )
			continue;
			
		if ( !level.teambased || player.team != self.team )
			enemyPoints[enemyPoints.size] = player.origin;
	}	
	
	if ( enemyPoints.size )
	{	
		return AveragePoint( enemyPoints );
	}
	else
	{
		return self.origin;
	}
}

moveToTarget()
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "leaving" );
	self.owner endon( "death" );
	self.owner endon( "disconnect" );
	self.owner endon( "joined_team" );
	self.owner endon( "joined_spectators" );
	
	self notify( "moveToPlayer" );
	self endon( "moveToPlayer" );
	
	self.inTransit = true;
	self setVehGoalPos( self.currentNode.origin, 1 );
	self waittill ( "goal" );
	self.inTransit = false;
	self notify( "hit_goal" );
}


deployLadder( streakName )
{
	self endon( "death" );
	self endon( "crashing" );
	self endon( "owner_disconnected" );	
	
	self.ladder ScriptModelPlayAnim( "ropeladder_mp_hind_drop" );
	wait( 1 );
	self.ladder ScriptModelPlayAnim( "ropeladder_mp_hind_dropped_idle" );	
	self.allowBoard = true;
}


showBoardMsg( chopper )
{
	self notify( "showBoardMsg" );
	self endon( "showBoardMsg" );
	
	level 	endon( "game_ended" );	
	self	endon( "disconnect" );
	chopper endon( "death" );
	chopper endon( "crashing" );
	
	chopper.msg = self maps\mp\gametypes\_hud_util::createFontString( "bigfixed", 0.8 );
	chopper.msg maps\mp\gametypes\_hud_util::setPoint( "CENTER", "CENTER", 0 , -40 );
	chopper.msg setText( &"KILLSTREAKS_HELI_GUNNER_INCOMING" );
	chopper.msg.color = ( 0.2, 0.8, 0.2 );	
	
	wait( 2.5 );
	
	if ( IsDefined( chopper.msg ) )
		chopper.msg destroyElem();	
}


heliBoard( streakName, pos )
{	
	self notify( "heliBoard" );
	self endon( "heliBoard" );
	
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "crashing" );

	self.ownerBoarded = false;
	
	if ( IsDefined(self.trigger) )
		self.trigger delete();
	
	self.trigger = Spawn( "trigger_radius", pos, 0, 256, 100 );
		
	//self.trigger maps\mp\_entityheadIcons::setHeadIcon( self.owner, "headicon_heli_extract_point", (0,0,45), 24, 24, undefined, undefined, undefined, undefined, undefined, false );	
	self.owner thread showBoardMsg( self );	

	while( true )
	{
		//	disconnect
		if ( !IsDefined( self.owner ) )
		{
			if ( IsDefined( self.trigger ) )
				self.trigger delete();
			return;
		}
		//	chopper death
		if ( !IsDefined( self.trigger ) )
			return;			
		
		if(  isAlive( self.owner ) &&
			 self.allowBoard == true && 
			!self.owner isUsingRemote() && 
			!IsDefined( self.owner.selectingLocation ) &&
			( !IsDefined( self.owner.changingWeapon ) || ( IsDefined( self.owner.changingWeapon ) && self.owner.changingWeapon != "trophy_mp" ) ) &&
			 self.owner IsTouching( self.trigger ) )
		{
			break;
		}

		wait( 0.05 );
	}
	
	//	stow any carry items
	self.owner notify( "force_cancel_sentry" );
	self.owner notify( "force_cancel_ims" );
	self.owner notify( "cancel_carryRemoteUAV" );	
	wait( 0.05 );
	
	self.owner setPlayerAngles( self getTagAngles( "TAG_PLAYER_ATTACH_LEFT" ) + ( 30,90,0 ) );
	self.owner PlayerLinkToDelta( self, "TAG_PLAYER_ATTACH_LEFT", 0, 240, 240, 10, 70, true );
	self.owner setStance( "crouch" );
	self.owner allowJump( false );		
	
	self thread reEquipLightArmor();
	//self thread keepCrouched();
	
	self.ownerBoarded = true;
	self notify( "boarded" );
	if ( IsDefined( self.trigger ) )
		self.trigger delete();
		
	self.owner.chopper = self;
}


heliCruise()
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "crashing" );
	self endon( "owner_disconnected" );
	self endon( "owner_death" );
	self endon( "do_dropoff" );
			
	//self thread heliCruiseSwitchSides();	
	//self thread heliMovementControl();
	
	//chopper thread createHeliLookAtEnt();
	
	//	get start node
	nextNode = getStartNode( self.origin );	
	
	//	cruise the route
	self ClearGoalYaw();
	self Vehicle_SetSpeed( 10, 6 );		
	self SetYawSpeed( 100, 60, 60, .3 );		
	for ( ;; )
	{	
		self setVehGoalPos( nextNode.origin, 0 );
		self waittill ( "goal" );
			
		prevNode = nextNode;	
		nextNode = getEnt( nextNode.target, "targetname" );
		if ( !IsDefined( nextNode ) )
		{
			assertEx( IsDefined( nextNode ), "Next node in path is undefined, but has targetname: " + prevNode.target );	
			break;
		}		
	}
}


getStartNode( curPos )
{
	closestNode = undefined;
	closestDistance = 999999;
	
	searchedNodes = [];	
	
	currentNode = level.heli_loop_nodes[0];
	while ( IsDefined( currentNode.target ) )
	{
		//	get the next node
		nextNode = getEnt( currentNode.target, "targetname" );
		
		//	stop when we've looked at all the nodes in the loop
		stopLooking = false;
		for( i=0; i<searchedNodes.size; i++ )
		{
			if ( nextNode.targetName == searchedNodes[i] )
			{
				stopLooking = true;
				break;
			}
		}
		if ( stopLooking == true )
			break;	
		
		//	check distance		
		distanceToLoc = Distance( curPos, nextNode.origin );
		if ( distanceToLoc < closestDistance )
		{
			closestNode = nextNode;
			closestDistance = distanceToLoc;
		}
		
		//	mark node as checked
		searchedNodes[searchedNodes.size] = nextNode.targetName;
		
		currentNode = nextNode;			
	}
	
	if ( IsDefined( closestNode ) )
		//	seems the next one in the list is usually the smoothest direction (closest often sometimes behind)
		return getEnt( closestNode.target, "targetname" );
	else
		return level.heli_loop_nodes[0];
}


heliReturnToDropsite()
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "crashing" );
	self endon( "owner_disconnected" );
	self endon( "owner_death" );
	
	DropOffNode = undefined;
	closestNode = undefined;
	closestDistance = undefined;

	self setVehGoalPos( self.origin + (0,0,1000) , 1 );
	self waittill( "goal" );
	
	foreach( loc in level.air_node_mesh )
	{ 	
		if ( !isDefined( loc.script_parameters ) || loc.script_parameters != "pickupNode" )
			continue;
		
		nodeDistance = DistanceSquared( loc.origin, self.origin );
		if ( !isDefined ( closestDistance ) || nodeDistance < closestDistance )
		{
			closestNode = loc;
			closestDistance = nodeDistance;
		}
	}
			
	DropOffNodeOrig = closestNode.origin * (1, 1, 0);
	DropOffNodeOrig += ( 0, 0, self.origin[2] );
	
	self setVehGoalPos( DropOffNodeOrig, 1 );
	self waittill( "goal" );
	self.movedLow = false;

	//Begin to lower
	//groundPosition = getGroundPosition( self.origin, 32, DropOffNodeOrig[2]*2, DropOffNodeOrig[2] );
	
	lowTempHeight = self getBestHeight( self.origin );
	lowHeightPos = self.currentNode.origin * (1,1,0);
	groundPosition = lowHeightPos + (0,0,lowTempHeight);
	
	
	self setVehGoalPos( groundPosition + (0,0,200), 16 );
	self waittill( "goal" );
	
	self.movedLow = true;
	
	self notify( "at_dropoff" );
}


heliCruiseSwitchSides()
{
	level endon( "game_ended" );
	self  endon( "death" );
	self  endon( "crashing" );
	self.owner endon( "death" );
	self.owner endon( "disconnect" );
	self  endon( "dropping" );
		
	self.switchMsg = self.owner maps\mp\gametypes\_hud_util::createFontString( "bigfixed", 0.6 );
	self.switchMsg maps\mp\gametypes\_hud_util::setPoint( "CENTER", "CENTER", 0 , 200 );
	self.switchMsg setText( &"KILLSTREAKS_HELI_SNIPER_SWITCH_SIDES" );
	self.switchMsg.color = ( 0.8, 0.8, 0.8 );		
		
	self.owner notifyOnPlayerCommand( "switch_sides", "+actionslot 4" );
	
	self.owner.switchedSides = false;
	for (;;)
	{
		self.owner waittill ( "switch_sides" );
		
		if ( !self.owner.switchedSides )
		{
			self.owner setPlayerAngles( self getTagAngles( "TAG_PLAYER_ATTACH_RIGHT" ) + ( 30,-90,0 ) );
			self.owner PlayerLinkToDelta( self, "TAG_PLAYER_ATTACH_RIGHT", 0, 240, 240, 10, 70, true );	
			self.owner.switchedSides = true;			
		}
		else
		{		
			self.owner setPlayerAngles( self getTagAngles( "TAG_PLAYER_ATTACH_LEFT" ) + ( 30,90,0 ) );
			self.owner PlayerLinkToDelta( self, "TAG_PLAYER_ATTACH_LEFT", 0, 240, 240, 10, 70, true );
			self.owner.switchedSides = false;
		}
		
		wait( 0.5 );	
	}
}


heliMovementControl()
{
	level endon( "game_ended" );
	self  endon( "death" );
	self  endon( "crashing" );
	self.owner endon( "death" );
	self.owner endon( "disconnect" );
	self  endon( "dropping" );
		
	//self.moveMsg = self.owner maps\mp\gametypes\_hud_util::createFontString( "bigfixed", 0.6 );
	//self.moveMsg maps\mp\gametypes\_hud_util::setPoint( "CENTER", "CENTER", 0 , 180 );
	//self.moveMsg setText( &"KILLSTREAKS_HELI_SNIPER_CHANGE_POSITION" );
	//self.moveMsg.color = ( 0.8, 0.8, 0.8 );			
	//self.owner notifyOnPlayerCommand( "change_position", "+actionslot 1" );
	
	self Vehicle_SetSpeed( 60, 45, 20 );
	self setneargoalnotifydist( 8 );
	
	for ( ;; )
	{
		movementDirection = self.owner GetNormalizedMovement();
		
		if ( movementDirection[0] >= 0.15 || movementDirection[1] >= 0.15 || movementDirection[0] <= -0.15 || movementDirection[1] <= -0.15 )
			self thread manualMove( movementDirection );
		
		wait 0.05;
	}
	
}


manualMove( direction )
{
	level endon( "game_ended" );
	self  endon( "death" );
	self  endon( "crashing" );
	self.owner endon( "death" );
	self.owner endon( "disconnect" );
	self  endon( "dropping" );
	
	self notify ( "manualMove" );
	self endon ( "manualMove" );
	
	fwrd = AnglesToForward( self.owner.angles ) * ( 250 * direction[0] );
	rght = AnglesToRight( self.owner.angles ) * ( 250 * direction[1] );
	vec = fwrd + rght;
	
	moveToPoint = self.origin + vec;
	
	traceOffset = ( 0, 0, 2500 );
	traceStart = ( moveToPoint ) + ( getHeliPilotMeshOffset() + traceOffset );
	traceEnd = ( moveToPoint ) + ( getHeliPilotMeshOffset() - traceOffset );
	
	//This will force the helisniper on the vehicle mesh until outside its bounds.
	tracePos = BulletTrace( traceStart, traceEnd, false, false, false, false, true );
	
	if ( IsDefined( tracePos["entity"] ) && tracePos[ "normal" ][2] > .1 )
	{
		moveToPoint = tracePos[ "position" ] - getHeliPilotMeshOffset() + (0,0,128);
	}
		
	self SetVehGoalPos( moveToPoint, 1 );
	self waittill( "goal" );
}


heliLeave()
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "crashing" );
	self notify( "end_disconnect_check" );
	self notify( "end_death_check" );
	self notify( "leaving" );
	
	if ( IsDefined( self.ladder ) )
		self.ladder delete();
	if ( IsDefined( self.trigger ) )
		self.trigger delete();
	if ( IsDefined( self.turret ) )
		self.turret delete();		
	if ( IsDefined( self.msg ) )
		self.msg destroyElem();		
	if ( IsDefined( self.switchMsg ) )
		self.switchMsg destroyElem();
	if ( IsDefined( self.moveMsg ) )
		self.moveMsg destroyElem();
	
	self ClearLookAtEnt();
	
	//	rise to leave
	self SetYawSpeed( 220, 220, 220, .3 );
	self Vehicle_SetSpeed( 120, 60 );
	
	self SetVehGoalPos( self.origin + (0,0,1200),1);
	self waittill( "goal" );
	
	self setVehGoalPos( self.pathGoal, 1 );
	self waittill ( "goal" );
	
	//	leave
	self setvehgoalpos( self.pathEnd, 1 );
	self Vehicle_SetSpeed( 300, 75 );
	self.leaving = true;
	
	if ( IsDefined( level.lbSniper ) && level.lbSniper == self )
		level.lbSniper = undefined;
	
	self waittill ( "goal" );
	self notify( "delete" );
	self delete();
}


heliHealth()
{
	self endon( "death" );
	self endon( "leaving" );
	self endon( "crashing" );
	
	self.currentstate = "ok";
	self.laststate = "ok";
	self setdamagestage( 3 );
	
	damageState = 3;
	self setDamageStage( damageState );
	
	for ( ;; )
	{
		if ( self.damageTaken >= (self.maxhealth * 0.33) && damageState == 3 )
		{
			damageState = 2;
			self setDamageStage( damageState );
			self.currentstate = "light smoke";
			playFxOnTag( level.chopper_fx["damage"]["light_smoke"], self, "tag_origin" );
		}
		else if ( self.damageTaken >= (self.maxhealth * 0.66) && damageState == 2 )
		{
			damageState = 1;
			self setDamageStage( damageState );
			self.currentstate = "heavy smoke";
			stopFxOnTag( level.chopper_fx["damage"]["light_smoke"], self, "tag_origin" );
			playFxOnTag( level.chopper_fx["damage"]["heavy_smoke"], self, "tag_origin" );
		}
		else if( self.damageTaken > self.maxhealth )
		{
			damageState = 0;
			self setDamageStage( damageState );

			stopFxOnTag( level.chopper_fx["damage"]["heavy_smoke"], self, "tag_origin" );
			
			self thread maps\mp\killstreaks\_helicopter_flock::heliDestroyed();
			self notify( "crashing" );
			break;
		}
		
		wait 0.05;
	}
}


heliDeathCleanup( streakName )
{
	level endon( "game_ended" );
	self endon( "leaving" );
	
	self waittill( "death" );	
	
	//	cleanup
	if ( IsDefined( self.ladder ) )
		self.ladder delete();
	if ( IsDefined( self.trigger ) )
		self.trigger delete();	
	if ( IsDefined( self.turret ) )
		self.turret delete();	
	if ( IsDefined( self.msg ) )
		self.msg destroyElem();
	if ( IsDefined( self.switchMsg ) )
		self.switchMsg destroyElem();	
	if ( IsDefined( self.moveMsg ) )
		self.moveMsg destroyElem();
	
	//	what to do with player?
	if ( IsDefined( self.owner ) && isAlive( self.owner ) && self.ownerBoarded == true )
	{		
		self.owner unlink();
		
		if ( IsDefined( self.validAttacker ) )
			RadiusDamage( self.owner.origin, 200, 600, 600, self.validAttacker );
		else
			RadiusDamage( self.owner.origin, 200, 600, 600 );
	}
}


setTempNoFallDamage()
{	
	if ( !self _hasPerk( "specialty_falldamage" ) )
	{
		level endon( "game_ended" );
		self  endon( "death" );		
		self  endon( "disconnect" );
		
		self givePerk( "specialty_falldamage", false );
		wait ( 2 );
		self _unsetPerk( "specialty_falldamage" );
	}	
}


reEquipLightArmor()
{
	level endon( "game_ended" );
	self  endon( "death" );
	self  endon( "crashing" );
	self.owner endon( "death" );
	self.owner endon( "disconnect" );
	self  endon( "dropping" );
	
	timesReEquipped = 0;
	
	for( ;; )
	{
		wait( 0.05 );
		if ( !IsDefined( self.owner.lightArmorHP )	)
		{
			self.owner maps\mp\perks\_perkfunctions::setLightArmor();
			timesReEquipped++;
			if ( timesReEquipped > 2 )
				break;
		}
	}
}


keepCrouched()
{
	level endon( "game_ended" );
	self  endon( "death" );
	self  endon( "crashing" );
	self.owner endon( "death" );
	self.owner endon( "disconnect" );
	self  endon( "dropping" );
	
	for( ;; )
	{
		if ( self.owner GetStance() != "crouch") 
		{
			self.owner setStance( "crouch" );
		}
		wait( 0.05 );
	}
}


giveCoolAssGun()
{
	level endon( "game_ended" );
	self  endon( "death" );
	self  endon( "crashing" );
	self  endon( "dropping" );
	self.owner endon( "death" );
	self.owner endon( "disconnect" );
	
	self.owner GiveWeapon( "iw5_barrettexp_mp_barrettscope" );
	self.owner SwitchToWeaponImmediate( "iw5_barrettexp_mp_barrettscope" );
	self.owner disableWeaponSwitch();
	self.owner setRecoilScale( 0,100 );
	self thread restockOwnerAmmo();
}


restockOwnerAmmo()
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "crashing" );
	self.owner endon( "death" );
	self.owner endon( "disconnect" );
	self.owner endon( "dropping" );
	
	for( ;; )
	{
		self.owner waittill ("weapon_fired");
		self.owner GiveMaxAmmo( "iw5_barrettexp_mp_barrettscope" );
	}
}


pushCorpseOnOwnerDeath()
{
	level endon( "game_ended" );
	self.owner endon( "disconnect" );
	self  endon( "dropping" );
	self  endon( "death" );
	self  endon( "crashing" );
	
	self.owner waittill( "death" );
	self.owner.OnHeliSniper = false;
	self.ownerBoarded = false;

	//race condition can cause undefined origin here
	if ( isDefined ( self.origin ) )	
		PhysicsExplosionSphere( self.origin, 200, 200, 1 );
}


leaveOnOwnerDisconnect()
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "crashing" );
	self endon( "end_disconnect_check" );

	self.owner waittill( "disconnect" );
	
	self notify ( "owner_disconnected" );
	
	self thread heliLeave();		
}


leaveOnOwnerDeath()
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "crashing" );
	self endon( "end_death_check" );

	self.owner waittill( "death" );
	
	self notify ( "owner_death" );
	
	self thread heliLeave();		
}


clearLocOnHeliGone( locIndex )
{
	level endon( "game_ended" );
	
	self waittill_any ( "leaving", "death", "crashing" );

	level.air_support_locs[level.script][locIndex]["in_use"] = false;	
}	


Callback_VehicleDamage( inflictor, attacker, damage, dFlags, meansOfDeath, weapon, point, dir, hitLoc, timeOffset, modelIndex, partName )
{
	if ( self.destroyed == true )
		return;
	
	if ( !IsDefined( attacker ) || ( level.teamBased && attacker.team == self.team ) )
		return;
	
	if ( attacker == self || attacker == self.owner )
		return;
		
	if ( isPlayer( attacker ) )
		attacker maps\mp\gametypes\_damagefeedback::updateDamageFeedback( "lb" );
		
	if ( IsDefined(weapon) && weapon == "emp_grenade_mp" )
	{
		damage = self.maxhealth + 1;
	}
	
	maps\mp\killstreaks\_killstreaks::killstreakHit( attacker, weapon, self );
	self.damageTaken+=damage;		
	if ( self.damageTaken >= self.maxhealth  && ( (level.teamBased && self.team != attacker.team) || !level.teamBased) )
	{
		self.destroyed = true;
		validAttacker = undefined;
		if ( IsDefined( attacker.owner ) && (!IsDefined(self.owner) || attacker.owner != self.owner) )
			validAttacker = attacker.owner;				
		else if ( !IsDefined(self.owner) || attacker != self.owner )
			validAttacker = attacker;
			
		//	sanity checks	
		if ( !IsDefined(attacker.owner) && attacker.classname == "script_vehicle" )
				validAttacker = undefined;
		if ( IsDefined( attacker.class ) && attacker.class == "worldspawn" )
				validAttacker = undefined;			

		if ( IsDefined( validAttacker ) )
		{
			self.validAttacker = validAttacker;
			validAttacker notify( "destroyed_helicopter" );
			validAttacker notify( "destroyed_killstreak", weapon );
			thread teamPlayerCardSplash( "callout_destroyed_helicopter", validAttacker );			
			validAttacker thread maps\mp\gametypes\_rank::giveRankXP( "kill", 300, weapon, meansOfDeath );			
			validAttacker thread maps\mp\gametypes\_rank::xpEventPopup( &"SPLASHES_DESTROYED_HELICOPTER" );
			thread maps\mp\gametypes\_missions::vehicleKilled( self.owner, self, undefined, validAttacker, damage, meansOfDeath, weapon );		
		}
	}			

	self Vehicle_FinishDamage( inflictor, attacker, damage, dFlags, meansOfDeath, weapon, point, dir, hitLoc, timeOffset, modelIndex, partName );
}

getClosestStartNode( pos )
{
	// gets the start node that is closest to the position passed in
	closestNode = undefined;
	closestDistance = 999999;

	foreach( loc in level.air_start_nodes )
	{ 	
		nodeDistance = distance( loc.origin, pos );
		if ( nodeDistance < closestDistance )
		{
			closestNode = loc;
			closestDistance = nodeDistance;
		}
	}

	return closestNode;
}

getClosestNode( pos )
{
	// gets the closest node to the position passed in, regardless of link
	closestNode = undefined;
	closestDistance = 999999;
	
	foreach( loc in level.air_node_mesh )
	{ 	
		nodeDistance = distance( loc.origin, pos );
		if ( nodeDistance < closestDistance )
		{
			closestNode = loc;
			closestDistance = nodeDistance;
		}
	}
	
	return closestNode;
}

moveToPlayer() // self == lb
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "leaving" );
	self.owner endon( "death" );
	self.owner endon( "disconnect" );
	self.owner endon( "joined_team" );
	self.owner endon( "joined_spectators" );
	
	self notify( "moveToPlayer" );
	self endon( "moveToPlayer" );
	
	self.inTransit = true;
	self setVehGoalPos( self.currentNode.origin, 1 );
	self waittill ( "goal" );
	self.inTransit = false;
	self notify( "hit_goal" );		
}