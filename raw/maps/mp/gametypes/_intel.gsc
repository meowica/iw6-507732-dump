#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;


init()
{
	level thread populateIntelChallenges();
	level.intelActive = false;
	
	if( !IsDefined(level.supportIntel) || level.supportIntel )
	{
		level thread onPlayerConnect();
	}

/#
	SetDevDvarIfUninitialized( "scr_devIntelChallengeNum", -1 );
#/
}

populateIntelChallenges()
{
	level endon ( "game_ended" );
	
	wait(0.05);
	
	level.intelChallengeStruct = spawnStruct();
	
	level.intelChallengeStruct.challengeName = [];
	level.intelChallengeStruct.challengeReward = [];
	level.intelChallengeStruct.challengeTarget = [];
	
	//Challenge Name
	challengeTempField = "temp";
	rowIndex = 0;
	while( challengeTempField != "" )
	{
		available = true;
		if( level.gameType == "sd" )
			available = int( TableLookupByRow( "mp/intelChallenges.csv", rowIndex, 4 ) ) == 1;

		challengeTempField = TableLookupByRow( "mp/intelChallenges.csv", rowIndex, 0 );

		if( challengeTempField == "" )
			break;

		if( available )
			level.intelChallengeStruct.challengeName[ level.intelChallengeStruct.challengeName.size ] = challengeTempField;	

		rowIndex++;
	}
	
	//Challenge Reward
	challengeTempField = "temp";
	rowIndex = 0;
	while( challengeTempField != "" )
	{
		available = true;
		if( level.gameType == "sd" )
			available = int( TableLookupByRow( "mp/intelChallenges.csv", rowIndex, 4 ) ) == 1;

		challengeTempField = TableLookupByRow( "mp/intelChallenges.csv", rowIndex, 2 );

		if( challengeTempField == "" )
			break;

		if( available )
			level.intelChallengeStruct.challengeReward[ level.intelChallengeStruct.challengeReward.size ] = challengeTempField;	

		rowIndex++;
	}
	
	//Challenge Target
	challengeTempField = "temp";
	rowIndex = 0;
	while( challengeTempField != "" )
	{
		available = true;
		if( level.gameType == "sd" )
			available = int( TableLookupByRow( "mp/intelChallenges.csv", rowIndex, 4 ) ) == 1;

		challengeTempField = TableLookupByRow( "mp/intelChallenges.csv", rowIndex, 3 );

		if( challengeTempField == "" )
			break;

		if( available )
			level.intelChallengeStruct.challengeTarget[ level.intelChallengeStruct.challengeTarget.size ] = challengeTempField;	

		rowIndex++;
	}

}

onPlayerConnect()
{
	for(;;)
	{
		level waittill( "connected", player );
		
		player SetClientDvar( "ui_intelActiveIndex", -1 );
		player SetClientDvar( "ui_intelTargetPlayer", -1 );
		
		player thread intelDeathWatcher();
	}
}

intelDeathWatcher() // self == player
{
	level endon ( "game_ended" );
	self endon( "disconnect" );
	self endon( "intelFailed" );
	
	for(;;)
	{
		self waittill( "death" );
		
		if( !level.intelActive )
		{
			level.intelActive = true;
			self spawnFirstIntel();
		}
		
		if ( isDefined( self.hasIntel ) && self.hasIntel )
		{
			self.hasIntel = false;
			self onDropIntel();
		}
	}
}

intelFailed() // self == player
{
	self notify( "intel_failed" );
	self thread maps\mp\gametypes\_hud_message::SplashNotifyDelayed( "ch_intel_failed" );
	
	//removes target marker if its there
	if( isDefined(self.targetObjId) )
	{
		Objective_Delete(self.targetObjId);
	}
	
	//removes targets challenge info if its there
	if( isDefined( self.playerTarget ) )
	{
		self.playerTarget SetClientDvar( "ui_intelActiveIndex", -1 );
		self.playerTarget SetClientDvar( "ui_intelTargetPlayer", -1 );
		self.playerTarget = undefined;
	}
	
	self SetClientDvar( "ui_intelActiveIndex", -1 );
	self SetClientDvar( "ui_intelTargetPlayer", -1 );
	
	if( !level.intelActive )
	{
		level.intelActive = true;
		self spawnFirstIntel();
	}
	
	if ( isDefined( self.hasIntel ) && self.hasIntel )
	{
		self.hasIntel = false;
		level randAssignIntel(); // blocking call
	}
}

spawnFirstIntel() // self == player
{
	//Do player physics trace to get ground position
	position = GetGroundPosition( self.origin + ( 0, 0, 32 ), 42 );
	
	intelCase = spawn( "script_model", position + ( 0, 0, 20 ) );
	intelCase.angles = (0,0,0);
	intelCase SetModel( "com_metal_briefcase_intel" );
	intelTrigger = Spawn( "trigger_radius", position, 0, 96, 60 );
	intelEnt = [];
	intelEnt["visuals"] = intelCase;
	intelEnt["trigger"] = intelTrigger;
	intelEnt["owner"] = "none";
	intelEnt["isActive"] = true;
	intelEnt["firstTriggerPlayer"] = undefined;
	intelEnt["useRate"] = 1;
	intelEnt["useTime"] = 0.5;
	intelEnt["useProgress"] = 0;
	intelEnt["dropped_time"] = GetTime();

	intelEnt["visuals"] ScriptModelPlayAnim( "mp_briefcase_spin" );
	level.intelEnt = intelEnt;
	
	//rand assign if touching bad trigger
	if ( self touchingBadTrigger() )
	{
		level.intelEnt["isActive"] = false;
		level.intelEnt["visuals"] Hide();
		
		level thread randAssignIntel();
		return;
	}
	
	level.intelEnt thread intelEmergencyRespawnTimer();
	self thread intelTriggerWatcher();
}

intelTriggerWatcher() // self == player
{
	level notify ( "intelTriggerWatcher" );
	level endon ( "intelTriggerWatcher" );
	
	level endon( "game_ended" );
	level.intelEnt["visuals"] endon( "pickedUp" );
	
	intelTrigger = level.intelEnt["trigger"];
	
	for( ;; )
	{
		intelTrigger waittill( "trigger", player );
		
		if ( !IsPlayer(player) )
			continue;
		
		if ( isAI( player ) )
			continue;
		
		if ( !isAlive( player ) || ( isDefined( player.fauxDead ) && player.fauxDead ) )
		{
			//there is a time when you kill your self with remote that this will pass
			wait( .25 );
			continue;
		}
		
		if ( level.intelEnt["isActive"] )
		{
			if ( isDefined( player.hasIntel ) && player.hasIntel )
				continue;
			
			//blocking call
			result = intelTrigger proximityThink( player );
			
			if( result )
				player onPickupIntel();
		}
	}
}

onDropIntel() // self == player
{
	//Do player physics trace to get ground position
	newOrigin = GetGroundPosition( self.origin + ( 0, 0, 32 ), 42 );
	
	level.intelEnt["visuals"].origin = newOrigin + ( 0, 0, 20 );
	level.intelEnt["trigger"].origin = newOrigin;
	
	//rand assign if touching bad trigger
	if ( level.intelEnt["visuals"] touchingBadTrigger() )
	{
		level thread randAssignIntel();
		return;
	}
	
	self.hasIntel = false;
	
	level.intelEnt["owner"] = "none";
	level.intelEnt["isActive"] = true;
	level.intelEnt["dropped_time"] = getTime();
	level.intelEnt["visuals"] Show();
	
	level.intelEnt["visuals"] ScriptModelPlayAnim( "mp_briefcase_spin" );
	
	//restart trigger watcher
	self thread intelTriggerWatcher();
	
	//start emergency respawn timer if players cant pick it up
	level.intelEnt thread intelEmergencyRespawnTimer();
}

intelEmergencyRespawnTimer() // self == intel
{
	level.intelEnt["visuals"] endon( "pickedUp" );
	
	for( ;; )
	{
		if( GetTime() > ( self["dropped_time"] + 60000 ) )
			break;
	
		wait 1;
	}
	
	//not picked up for 2 minutes
	//random place intel on player
	level.intelEnt["isActive"] = false;
	level.intelEnt["visuals"] Hide();
	
	level thread randAssignIntel();
}

onPickupIntel() // self == player
{
	self.hasIntel = true;
	level.intelEnt["isActive"] = false;
	level.intelEnt["visuals"] Hide();
	level.intelEnt["owner"] = self;

	challengeNum = RandomIntRange( 0, level.intelChallengeStruct.challengeName.size - 1 );
	
/#
	devChallengeNum = GetDvarInt( "scr_devIntelChallengeNum" );
	if( devChallengeNum != -1 )
		challengeNum = devChallengeNum;
#/

	self maps\mp\gametypes\_intelchallenges::giveChallenge( challengeNum );
	
	self thread watchForPlayerDisconnect();

	level.intelEnt["visuals"] notify("pickedUp");
}

watchForPlayerDisconnect() // self == player
{
	self endon( "death" );
	
	self waittill( "disconnect" );
	
	level thread randAssignIntel();
}

randAssignIntel() // self == level
{
	wait ( 1 );
	randNum = RandomIntRange( 0, level.players.size );
	
	level.players[randNum].hasIntel = true;
	level.intelEnt["owner"] = level.players[randNum];
}

awardPlayerChallengeComplete( index )
{
	self endon( "disconnect" );
	
	self replenishAmmo();
	self.hasIntel = false;
	reference = level.intelChallengeStruct.challengeName[index];
	rewardXP = Int( level.intelChallengeStruct.challengeReward[index] );
	
	//remove target marker if its there
	if( isDefined(self.targetObjId) )
	{
		Objective_Delete(self.targetObjId);
	}
	
	//remove targets info if its there
	if( isDefined( self.playerTarget ) )
	{
		self.playerTarget SetClientDvar( "ui_intelActiveIndex", -1 );
		self.playerTarget SetClientDvar( "ui_intelTargetPlayer", -1 );
		self.playerTarget = undefined;
	}
	
	self SetClientDvar( "ui_intelActiveIndex", -1 );
	self SetClientDvar( "ui_intelTargetPlayer", -1 );
	
	//Give Killstreak Reward
	self thread maps\mp\killstreaks\_killstreaks::giveKillstreak( "airdrop_assault", false, false, self );
	
	self thread maps\mp\gametypes\_hud_message::SplashNotifyDelayed( reference, rewardXP );
	self thread maps\mp\gametypes\_rank::giveRankXP( "intel", rewardXP );
	
	level thread randAssignIntel();
	
	self notify( "intel_challenge_complete" );
}

replenishAmmo()
{
	weaponList = self GetWeaponsListAll();
	
	foreach ( weaponName in weaponList )
	{
		self giveMaxAmmo( weaponName );
	}
}

/***************************************
 * USE BAR
 * 
 * 
 ***************************************/

proximityThink( player ) // self == intel trigger
{
	if ( !isDefined( self ) )
		return false;

	self.inUse = true;
    
    player thread personalUseBar();
    result = self proximityThinkLoop( player );
    
    assert ( isDefined( result ) );
	
    if ( !isDefined( self ) )
    	return false;

	level.intelEnt["useProgress"] = 0;

	if ( isDefined( player.intelUseBar ) )
    {
		player.intelUseBarText destroyElem();
		player.intelUseBar destroyElem();
	}
	
	return ( result );
}


personalUseBar() // self == player
{
    self endon( "disconnect" );
    
    self.intelUseBar = createPrimaryProgressBar( 0, 25 );
    self.intelUseBarText = createPrimaryProgressBarText( 0, 25 );
    useText = &"LUA_MENU_ACQUIRING_INTEL";
    self.intelUseBarText setText( useText );
    
    useRate = level.intelEnt["useRate"];
    useTime = level.intelEnt["useTime"];
    
    lastRate = -1;
    
    while ( isReallyAlive( self ) && !level.gameEnded )
    {
        if ( lastRate != useRate )
        {
            if( level.intelEnt["useProgress"] > useTime )
                level.intelEnt["useProgress"] = useTime;
               
            self.intelUseBar updateBar( useTime, 1/useTime );

            if ( !useRate )
            {
                self.intelUseBar hideElem();
                self.intelUseBarText hideElem();
            }
            else
            {
                self.intelUseBar showElem();
                self.intelUseBarText showElem();
            }
        }
        lastRate = useRate;
        wait ( 0.05 );
    }
    
    if ( isDefined( self.useBar ) )
    {
    	self.intelUseBar destroyElem();
    	self.intelUseBarText destroyElem();
    }
}


proximityThinkLoop( player ) // self == intel trigger
{
    useRate = level.intelEnt["useRate"];
    useTime = level.intelEnt["useTime"];
	
    while( !level.gameEnded && isDefined( self ) && isReallyAlive( player ) )
    {
        level.intelEnt["useProgress"] += 0.05;

        if ( level.intelEnt["useProgress"] >= useTime )
            return ( isReallyAlive( player ) );
       
        wait 0.05;
    }
    
    return false;
}
