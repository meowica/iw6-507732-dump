#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;

NUM_KILLS_GIVE_ALL_PERKS = 8;

KILLSTREAK_GIMME_SLOT = 0;
KILLSTREAK_SLOT_1 = 1;
KILLSTREAK_SLOT_2 = 2;
KILLSTREAK_SLOT_3 = 3;
KILLSTREAK_ALL_PERKS_SLOT = 4;
KILLSTREAK_STACKING_START_SLOT = 5;

init()
{	
	initKillstreakData();

	level.killstreakFuncs = [];
	level.killstreakSetupFuncs = [];
	level.killstreakWeapons = [];

	thread maps\mp\killstreaks\_ac130::init();
	thread maps\mp\killstreaks\_remotemissile::init();
	thread maps\mp\killstreaks\_uav::init();
	thread maps\mp\killstreaks\_airstrike::init();
	thread maps\mp\killstreaks\_plane::init();	// eventually, move this above airstrike and simplify the existing killstreaks
	thread maps\mp\killstreaks\_airdrop::init();
	thread maps\mp\killstreaks\_helicopter::init();
	thread maps\mp\killstreaks\_helicopter_flock::init();
	thread maps\mp\killstreaks\_helicopter_guard::init();
	thread maps\mp\killstreaks\_autosentry::init();
	//thread maps\mp\killstreaks\_tank::init();
	thread maps\mp\killstreaks\_emp::init();
	thread maps\mp\killstreaks\_nuke::init();
	thread maps\mp\killstreaks\_escortairdrop::init();
	//thread maps\mp\killstreaks\_mobilemortar::init();
	thread maps\mp\killstreaks\_remotemortar::init();
	//thread maps\mp\killstreaks\_a10::init();
	thread maps\mp\killstreaks\_deployablebox::init();
	thread maps\mp\killstreaks\_deployablebox_vest::init();
	thread maps\mp\killstreaks\_deployablebox_soflam::init();
	thread maps\mp\killstreaks\_deployablebox_ammo::init();
	thread maps\mp\killstreaks\_deployablebox_grenades::init();
	thread maps\mp\killstreaks\_deployablebox_juicebox::init();
	thread maps\mp\killstreaks\_portableAOEgenerator::init();
	thread maps\mp\gametypes\_scrambler::init();
	thread maps\mp\gametypes\_portable_radar::init();
	//thread maps\mp\killstreaks\_teamammorefill::init();
	//thread maps\mp\killstreaks\_heligunner::init();
	thread maps\mp\killstreaks\_ims::init();
	//thread maps\mp\killstreaks\_aastrike::init();
	thread maps\mp\killstreaks\_perkstreaks::init();
	thread maps\mp\killstreaks\_remoteturret::init();
	thread maps\mp\killstreaks\_remoteuav::init();
	thread maps\mp\killstreaks\_remotetank::init();
	thread maps\mp\killstreaks\_juggernaut::init();
	thread maps\mp\killstreaks\_ball_drone::init();
	thread maps\mp\killstreaks\_lasedStrike::init();
	thread maps\mp\killstreaks\_heliSniper::init();
	thread maps\mp\killstreaks\_helicopter_pilot::init();
	thread maps\mp\killstreaks\_mrsiartillery::init();
	thread maps\mp\killstreaks\_tactical_killstreaks::init();
	thread maps\mp\killstreaks\_vanguard::init();
	thread maps\mp\killstreaks\_uplink::init();
	thread maps\mp\killstreaks\_droneHive::init();
	thread maps\mp\killstreaks\_jammer::init();
	thread maps\mp\killstreaks\_air_superiority::init();
	thread maps\mp\killstreaks\_odin::init();
	thread maps\mp\killstreaks\_highValueTarget::init();
	thread maps\mp\killstreaks\_AALauncher::init();
	thread maps\mp\killstreaks\_gas_airstrike::init();
	thread maps\mp\killstreaks\_placeable::init();
	thread maps\mp\killstreaks\_placeable_barrier::init();
	
	//	all killstreak weapons that kill, this is used for weapon to killstreak association
	level.killstreakWeildWeapons = [];
	level.killstreakWeildWeapons["artillery_mp"] = 					"precision_airstrike";		// Precision Airstrike
	level.killstreakWeildWeapons["stealth_bomb_mp"] = 				"stealth_airstrike";		// Stealth Bomber
	level.killstreakWeildWeapons["pavelow_minigun_mp"] = 			"helicopter_flares";		// Pave Low
	level.killstreakWeildWeapons["sentry_minigun_mp"] = 			"sentry";					// Sentry Gun
	level.killstreakWeildWeapons["ac130_105mm_mp"] = 				"ac130";					// AC130
	level.killstreakWeildWeapons["ac130_40mm_mp"] = 				"ac130";					// AC130
	level.killstreakWeildWeapons["ac130_25mm_mp"] = 				"ac130";					// AC130
	level.killstreakWeildWeapons["remotemissile_projectile_mp"] = 	"predator_missile";			// Predator Missile
	level.killstreakWeildWeapons["cobra_ffar_mp"] = 				"helicopter";				// Attack Helicopter, Missile
	level.killstreakWeildWeapons["cobra_20mm_mp"] = 				"helicopter";				// Attack Helicopter
	level.killstreakWeildWeapons["nuke_mp"] = 						"nuke";						// Nuke		
	level.killstreakWeildWeapons["littlebird_guard_minigun_mp"] = 	"littlebird_support";		// littlebird guard/support
	level.killstreakWeildWeapons["osprey_minigun_mp"] = 			"escort_airdrop";			// escort airdrop
	level.killstreakWeildWeapons["remote_mortar_missile_mp"] = 		"remote_mortar";			// remote mortar
	level.killstreakWeildWeapons["manned_littlebird_sniper_mp"] = 	"heli_sniper";				// heli sniper	
	level.killstreakWeildWeapons["iw5_m60jugg_mp"] = 				"airdrop_juggernaut";		// juggernaut assault primary	
	level.killstreakWeildWeapons["iw5_mp412jugg_mp"] = 				"airdrop_juggernaut";		// juggernaut assault secondary	
	level.killstreakWeildWeapons["iw5_riotshieldjugg_mp"] = 		"airdrop_juggernaut_recon";	// juggernaut support primary	
	level.killstreakWeildWeapons["iw5_usp45jugg_mp"] = 				"airdrop_juggernaut_recon";	// juggernaut support secondary	
	level.killstreakWeildWeapons["iw5_knifeonly_mp"] = 				"airdrop_juggernaut_maniac";// juggernaut maniac primary	
	level.killstreakWeildWeapons["remote_turret_mp"] = 				"remote_mg_turret";			// remote turret
	level.killstreakWeildWeapons["osprey_player_minigun_mp"] = 		"osprey_gunner";			// osprey gunner
	level.killstreakWeildWeapons["deployable_vest_marker_mp"] = 	"deployable_vest";			// deployable vest
	level.killstreakWeildWeapons["ugv_turret_mp"] = 				"remote_tank";				// remote tank turret
	level.killstreakWeildWeapons["ugv_gl_turret_mp"] = 				"remote_tank";				// remote tank gl turret
	level.killstreakWeildWeapons["remote_tank_projectile_mp"] = 	"vanguard";					// vanguard missile
	level.killstreakWeildWeapons["uav_remote_mp"] = 				"remote_uav";				// remote uav and vanguard
	level.killstreakWeildWeapons["heli_pilot_turret_mp"] = 			"heli_pilot";				// heli pilot
	level.killstreakWeildWeapons["lasedstrike_missile_mp"] = 		"lasedStrike";				// lased Strike
	level.killstreakWeildWeapons["agent_mp"] = 						"agent";					// agent
	level.killstreakWeildWeapons["guard_dog_mp"] = 					"guard_dog";				// guard dog
	level.killstreakWeildWeapons["kineticbombardment_mp"] = 		"??";						// thor / kinetic bomboardment
	level.killstreakWeildWeapons["mrsiartillery_mp"] = 				"mrsiartillery";			// mortar strike
	level.killstreakWeildWeapons["ims_projectile_mp"] = 			"ims";						// ims
	level.killstreakWeildWeapons["ball_drone_gun_mp"] = 			"ball_drone_backup";		// backup buddy
	level.killstreakWeildWeapons["drone_hive_projectile_mp"] = 		"drone_hive";				// drone hive
	level.killstreakWeildWeapons["stinger_mp"] = 					"aa_launcher";				// aa launcher
	level.killstreakWeildWeapons["killstreak_uplink_mp"] = 			"uplink";					// uplink
	level.killstreakWeildWeapons["gas_strike_mp"] = 				"gas_airstrike";			// uplink
	

	//	killstreak weapons that allow chaining	
	level.killstreakChainingWeapons = [];
	level.killstreakChainingWeapons["remotemissile_projectile_mp"] = 	"predator_missile";		// Predator Missile/Hellfire
	level.killstreakChainingWeapons["ims_projectile_mp"] = 				"ims";					// IMS
	level.killstreakChainingWeapons["sentry_minigun_mp"] = 				"sentry";				// Sentry Gun
	level.killstreakChainingWeapons["artillery_mp"] = 					"precision_airstrike";	// Precision Airstrike
	level.killstreakChainingWeapons["cobra_20mm_mp"] = 					"helicopter";			// attack helicopter
	level.killstreakChainingWeapons["apache_minigun_mp"] = 				"littlebird_flock";		// helicopter flock
	level.killstreakChainingWeapons["littlebird_guard_minigun_mp"] = 	"littlebird_support";	// littlebird guard
	level.killstreakChainingWeapons["remote_mortar_missile_mp"] = 		"remote_mortar";		// remote mortar
	level.killstreakChainingWeapons["ugv_turret_mp"] = 					"airdrop_remote_tank";	// remote tank
	level.killstreakChainingWeapons["ugv_gl_turret_mp"] = 				"airdrop_remote_tank";	// remote tank
	level.killstreakChainingWeapons["remote_tank_projectile_mp"] = 		"vanguard";				// vanguard
	level.killstreakChainingWeapons["pavelow_minigun_mp"] = 			"helicopter_flares";	// Pave Low
	level.killstreakChainingWeapons["ac130_105mm_mp"] = 				"ac130";				// AC130
	level.killstreakChainingWeapons["ac130_40mm_mp"] = 					"ac130";				// AC130
	level.killstreakChainingWeapons["ac130_25mm_mp"] = 					"ac130";				// AC130
	level.killstreakChainingWeapons["iw5_m60jugg_mp"] = 				"airdrop_juggernaut";	// juggernaut assault primary	
	level.killstreakChainingWeapons["iw5_mp412jugg_mp"] = 				"airdrop_juggernaut";	// juggernaut assault/def secondary	
	level.killstreakChainingWeapons["iw5_knifeonly_mp"] = 				"airdrop_juggernaut";	// juggernaut maniac primary	
	level.killstreakChainingWeapons["osprey_player_minigun_mp"] = 		"osprey_gunner";		// osprey gunner
	level.killstreakChainingWeapons["agent_mp"] = 						"agent";				// agent
	level.killstreakChainingWeapons["guard_dog_mp"] = 					"guard_dog";			// guard dog
	level.killstreakChainingWeapons["mrsiartillery_mp"] = 				"mrsiartillery";		// mortar strike
	level.killstreakChainingWeapons["drone_hive_projectile_mp"] = 		"drone_hive";			// drone hive
	level.killstreakChainingWeapons["ball_drone_gun_mp"] = 				"ball_drone_backup";	// backup buddy
	level.killstreakChainingWeapons["stinger_mp"] = 					"aa_launcher";			// aa_launcher

	level.killstreakRoundDelay = getIntProperty( "scr_game_killstreakdelay", 8 );

	level thread onPlayerConnect();
}

initKillstreakData()
{
	for ( i = 1; true; i++ )
	{
		retVal = TableLookup( level.global_tables[ "killstreakTable" ].path, level.global_tables[ "killstreakTable" ].index_col, i, level.global_tables[ "killstreakTable" ].ref_col );
		if ( !IsDefined( retVal ) || retVal == "" )
			break;

		streakRef = TableLookup( level.global_tables[ "killstreakTable" ].path, level.global_tables[ "killstreakTable" ].index_col, i, level.global_tables[ "killstreakTable" ].ref_col );
		assert( streakRef != "" );

		streakUseHint = TableLookupIString( level.global_tables[ "killstreakTable" ].path, level.global_tables[ "killstreakTable" ].index_col, i, level.global_tables[ "killstreakTable" ].earned_hint_col );
		assert( streakUseHint != &"" );

		streakEarnDialog = TableLookup( level.global_tables[ "killstreakTable" ].path, level.global_tables[ "killstreakTable" ].index_col, i, level.global_tables[ "killstreakTable" ].earned_dialog_col );
		assert( streakEarnDialog != "" );
		game["dialog"][ streakRef ] = streakEarnDialog;

		streakAlliesUseDialog = TableLookup( level.global_tables[ "killstreakTable" ].path, level.global_tables[ "killstreakTable" ].index_col, i, level.global_tables[ "killstreakTable" ].allies_dialog_col );
		assert( streakAlliesUseDialog != "" );
		game["dialog"][ "allies_friendly_" + streakRef + "_inbound" ] = "use_" + streakAlliesUseDialog;
		game["dialog"][ "allies_enemy_" + streakRef + "_inbound" ] = "enemy_" + streakAlliesUseDialog;

		streakAxisUseDialog = TableLookup( level.global_tables[ "killstreakTable" ].path, level.global_tables[ "killstreakTable" ].index_col, i, level.global_tables[ "killstreakTable" ].enemy_dialog_col );
		assert( streakAxisUseDialog != "" );
		game["dialog"][ "axis_friendly_" + streakRef + "_inbound" ] = "use_" + streakAxisUseDialog;
		game["dialog"][ "axis_enemy_" + streakRef + "_inbound" ] = "enemy_" + streakAxisUseDialog;

		streakPoints = int( TableLookup( level.global_tables[ "killstreakTable" ].path, level.global_tables[ "killstreakTable" ].index_col, i, level.global_tables[ "killstreakTable" ].score_col ) );
		assert( streakPoints != 0 );
		maps\mp\gametypes\_rank::registerScoreInfo( "killstreak_" + streakRef, streakPoints );
	}
}


onPlayerConnect()
{
	for ( ;; )
	{
		level waittill( "connected", player );
		
		if( !IsDefined ( player.pers[ "killstreaks" ] ) )
			player.pers[ "killstreaks" ] = [];

		if( !IsDefined ( player.pers[ "kID" ] ) )
			player.pers[ "kID" ] = 10;

		//if( !IsDefined ( player.pers[ "kIDs_valid" ] ) )
		//	player.pers[ "kIDs_valid" ] = [];
		
		player.lifeId = 0;
		player.curDefValue = 0;
			
		if ( IsDefined( player.pers["deaths"] ) )
			player.lifeId = player.pers["deaths"];

		player VisionSetMissilecamForPlayer( game["thermal_vision"] );	
	
		player thread onPlayerSpawned();
		player thread monitorDisownKillstreaks();
	
		player.spUpdateTotal = 0;
	}
}

onPlayerSpawned()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		self waittill( "spawned_player" );			
		
		self thread killstreakUseWaiter();
		self thread waitForChangeTeam();		
		
		// these three threads need to be run regardless of the streak type because you could switch during the grace period from specialist to assault or support and not be able to toggle up/down
		self thread streakSelectUpTracker();
		self thread streakSelectDownTracker();
		
		if( level.console )
		{
			self thread streakUseTimeTracker();
		}
		else
		{
			// pc doesn't do killstreak selections, just a single button press
			self thread pc_watchStreakUse();
		}
		self thread streakNotifyTracker();	

		if ( !IsDefined( self.pers["killstreaks"][ KILLSTREAK_GIMME_SLOT ] ) )
			self initPlayerKillstreaks();
		if ( !IsDefined( self.earnedStreakLevel ) )
			self.earnedStreakLevel = 0;
		// we want to reset the adrenaline back to what it was for round based games
		// we reset the adrenaline on first connect in playerlogic and if they are in the game until the end
		if( !IsDefined( self.adrenaline ) )
		{
			self.adrenaline = self GetCommonPlayerData( "killstreaksState", "count" );
		}
		// if we reset stats then countToNext will be 0 and no bars will show until you kill someone
		// this also means the first time someone plays the game they won't see bars, so we need to set it
		//if( self.adrenaline == self GetCommonPlayerData( "killstreaksState", "countToNext" ) )
		{
			self setStreakCountToNext();
			self updateStreakSlots();
		}

		if ( self.streakType == "specialist" )
			self updateSpecialistKillstreaks();
		else
			self giveOwnedKillstreakItem();
	}
}

initPlayerKillstreaks()
{
	// this IsDefined check keeps the clearkillstreaks call when we quit the game without selecting a class, from erroring out
	if( !IsDefined( self.streakType ) )
		return;

	if ( self.streakType == "specialist" )
		self setCommonPlayerData( "killstreaksState", "isSpecialist", true );
	else
		self setCommonPlayerData( "killstreaksState", "isSpecialist", false );
	
	// gimme slot is where care package items and special given items go
	// we want the gimme slot to be stackable so we don't lose killstreaks when we pick another up
	// so we'll make index 0 be a pointer of sorts to show where the next usable killstreak is in the killstreak array
	self.pers["killstreaks"][ KILLSTREAK_GIMME_SLOT ] = spawnStruct();
	self.pers["killstreaks"][ KILLSTREAK_GIMME_SLOT ].available = false;
	self.pers["killstreaks"][ KILLSTREAK_GIMME_SLOT ].streakName = undefined;
	self.pers["killstreaks"][ KILLSTREAK_GIMME_SLOT ].earned = false;
	self.pers["killstreaks"][ KILLSTREAK_GIMME_SLOT ].awardxp = undefined;
	self.pers["killstreaks"][ KILLSTREAK_GIMME_SLOT ].owner = undefined;
	self.pers["killstreaks"][ KILLSTREAK_GIMME_SLOT ].kID = undefined;
	self.pers["killstreaks"][ KILLSTREAK_GIMME_SLOT ].lifeId = undefined;
	self.pers["killstreaks"][ KILLSTREAK_GIMME_SLOT ].isGimme = true;		
	self.pers["killstreaks"][ KILLSTREAK_GIMME_SLOT ].isSpecialist = false;		
	self.pers["killstreaks"][ KILLSTREAK_GIMME_SLOT ].nextSlot = undefined;		

	// reserved for each killstreak whether they have them or not
	for( i = 1; i < KILLSTREAK_ALL_PERKS_SLOT; i++ )
	{
		self.pers["killstreaks"][ i ] = spawnStruct();
		self.pers["killstreaks"][ i ].available = false;
		self.pers["killstreaks"][ i ].streakName = undefined;
		self.pers["killstreaks"][ i ].earned = true;
		self.pers["killstreaks"][ i ].awardxp = 1;
		self.pers["killstreaks"][ i ].owner = undefined;
		self.pers["killstreaks"][ i ].kID = undefined;
		self.pers["killstreaks"][ i ].lifeId = -1;
		self.pers["killstreaks"][ i ].isGimme = false;		
		self.pers["killstreaks"][ i ].isSpecialist = false;		
	}

	// reserved for specialist all perks bonus
	self.pers["killstreaks"][ KILLSTREAK_ALL_PERKS_SLOT ] = spawnStruct();
	self.pers["killstreaks"][ KILLSTREAK_ALL_PERKS_SLOT ].available = false;
	self.pers["killstreaks"][ KILLSTREAK_ALL_PERKS_SLOT ].streakName = "all_perks_bonus";
	self.pers["killstreaks"][ KILLSTREAK_ALL_PERKS_SLOT ].earned = true;
	self.pers["killstreaks"][ KILLSTREAK_ALL_PERKS_SLOT ].awardxp = 0;
	self.pers["killstreaks"][ KILLSTREAK_ALL_PERKS_SLOT ].owner = undefined;
	self.pers["killstreaks"][ KILLSTREAK_ALL_PERKS_SLOT ].kID = undefined;
	self.pers["killstreaks"][ KILLSTREAK_ALL_PERKS_SLOT ].lifeId = -1;
	self.pers["killstreaks"][ KILLSTREAK_ALL_PERKS_SLOT ].isGimme = false;		
	self.pers["killstreaks"][ KILLSTREAK_ALL_PERKS_SLOT ].isSpecialist = true;		

	// init all of the icons to 0 in case the player hasn't selected all 3 streaks
	//	also init the hasStreak to false
	for( i = KILLSTREAK_GIMME_SLOT; i < KILLSTREAK_SLOT_3 + 1; i++ )
	{
		self setCommonPlayerData( "killstreaksState", "icons", i, 0 );
		self setCommonPlayerData( "killstreaksState", "hasStreak", i, false );
	}
	self setCommonPlayerData( "killstreaksState", "hasStreak", KILLSTREAK_GIMME_SLOT, false );
	
	index = 1;
	foreach ( streakName in self.killstreaks )
	{
		self.pers["killstreaks"][index].streakName = streakName;
		self.pers["killstreaks"][index].isSpecialist = ( self.streakType == "specialist" );	
		
		killstreakIndexName = self.pers["killstreaks"][index].streakName;
		// if specialist then we need to check to see if they have the pro version of the perk and get that icon
		if( self.streakType == "specialist" )
		{
			perkTokens = StrTok( self.pers["killstreaks"][index].streakName, "_" );
			if( perkTokens[ perkTokens.size - 1 ] == "ks" )
			{
				perkName = undefined;
				foreach( token in perkTokens )
				{
					if( token != "ks" )
					{
						if( !IsDefined( perkName ) )
							perkName = token;
						else
							perkName += ( "_" + token );
					}
				}

				// blastshield has an _ at the beginning
				if( isStrStart( self.pers["killstreaks"][index].streakName, "_" ) )
					perkName = "_" + perkName;

				if( IsDefined( perkName ) && self maps\mp\gametypes\_class::getPerkUpgrade( perkName ) != "specialty_null" )
					killstreakIndexName = self.pers["killstreaks"][index].streakName + "_pro";
			}
		}

		self setCommonPlayerData( "killstreaksState", "icons", index, getKillstreakIndex( killstreakIndexName ) );
		self setCommonPlayerData( "killstreaksState", "hasStreak", index, false );
		
		index++;	
	}

	self setCommonPlayerData( "killstreaksState", "nextIndex", 1 );		
	self setCommonPlayerData( "killstreaksState", "selectedIndex", -1 );
	self setCommonPlayerData( "killstreaksState", "numAvailable", 0 );

	// specialist shows one more icon
	self setCommonPlayerData( "killstreaksState", "hasStreak", KILLSTREAK_ALL_PERKS_SLOT, false );
}

updateStreakCount()
{
	if ( !IsDefined( self.pers["killstreaks"] ) )
		return;	
	if ( self.adrenaline == self.previousAdrenaline )
		return;	

	curCount = self.adrenaline;
	
	self setCommonPlayerData( "killstreaksState", "count", self.adrenaline );
		
	if ( self.adrenaline >= self getCommonPlayerData( "killstreaksState", "countToNext" ) )
		self setStreakCountToNext();		
}

resetStreakCount()
{
	self setCommonPlayerData( "killstreaksState", "count", 0 );
	self setStreakCountToNext();
}

setStreakCountToNext()
{
	// this IsDefined check keeps the resetadrenaline call when we first connect in playerlogic, from erroring out
	if( !IsDefined( self.streakType ) )
	{
		// if they have no streak then count to next should be zero
		self setCommonPlayerData( "killstreaksState", "countToNext", 0 );
		return;
	}

	// if they have no killstreaks
	if( self getMaxStreakCost() == 0 )
	{
		self setCommonPlayerData( "killstreaksState", "countToNext", 0 );
		return;
	}

	// specialist but have maxed out
	if( self.streakType == "specialist" )
	{
		if( self.adrenaline >= self getMaxStreakCost() )
			return;
	}

	// set the next streaks cost
	nextStreakName = getNextStreakName();
	if ( !IsDefined( nextStreakname ) )
		return;
	nextStreakCost = getStreakCost( nextStreakName );
	self setCommonPlayerData( "killstreaksState", "countToNext", nextStreakCost );
}

getNextStreakName()
{
	if ( self.adrenaline == self getMaxStreakCost() && ( self.streakType != "specialist" ) )
	{
		adrenaline = 0;
	}
	else
	{
		adrenaline = self.adrenaline;
	}
	
	foreach ( streakName in self.killstreaks )
	{
		streakVal = self getStreakCost( streakName );	
		
		if ( streakVal > adrenaline )
		{					
			return streakName;
		}
	}	
	return undefined;
}

getMaxStreakCost()
{
	maxCost = 0;
	foreach ( streakName in self.killstreaks )
	{
		streakVal = self getStreakCost( streakName );	
		
		if ( streakVal > maxCost )	
		{
			maxCost = streakVal;
		}
	}	
	return maxCost;
}

updateStreakSlots()
{
	// this IsDefined check keeps the clearkillstreaks call when we quit the game without selecting a class, from erroring out
	if( !IsDefined( self.streakType ) )
		return;

	if ( !isReallyAlive(self) )
		return;
	
	self_pers_killstreaks = self.pers["killstreaks"];

	//	what's available?
	numStreaks = 0;
	for( i = 0; i < KILLSTREAK_SLOT_3 + 1; i++ )
	{
		if( IsDefined( self_pers_killstreaks[i] ) && IsDefined( self_pers_killstreaks[i].streakName ) )
		{
			self setCommonPlayerData( "killstreaksState", "hasStreak", i, self_pers_killstreaks[i].available );	
			if ( self_pers_killstreaks[i].available == true )
				numStreaks++;	
		}	
	}	
	if ( self.streakType != "specialist" )
		self setCommonPlayerData( "killstreaksState", "numAvailable", numStreaks );
	
	//	next to earn
	minLevel = self.earnedStreakLevel;
	maxLevel = self getMaxStreakCost();
	if ( self.earnedStreakLevel == maxLevel && self.streakType != "specialist" )
		minLevel = 0;
			
	nextIndex = 1;
	
	foreach ( streakName in self.killstreaks )
	{
		streakVal = self getStreakCost( streakName );	
		
		if ( streakVal > minLevel )	
		{
			nextStreak = streakName;
			break;
		}

		// for specialsit we don't want the next index to go above the max
		if( self.streakType == "specialist" )
		{
			if( self.earnedStreakLevel == maxLevel )
				break;
		}

		nextIndex++;
	} 
	
	self setCommonPlayerData( "killstreaksState", "nextIndex", nextIndex );	
	
	//	selected index
	if ( IsDefined( self.killstreakIndexWeapon ) && ( self.streakType != "specialist" ) )
	{
		self setCommonPlayerData( "killstreaksState", "selectedIndex", self.killstreakIndexWeapon );
	}
	else
	{
		if( self.streakType == "specialist" && self_pers_killstreaks[ KILLSTREAK_GIMME_SLOT ].available )
			self setCommonPlayerData( "killstreaksState", "selectedIndex", 0 );	
		else
			self setCommonPlayerData( "killstreaksState", "selectedIndex", -1 );	
	}
}


waitForChangeTeam()
{
	self endon ( "disconnect" );
	self endon( "faux_spawn" );
	
	self notify ( "waitForChangeTeam" );
	self endon ( "waitForChangeTeam" );
	
	for ( ;; )
	{
		self waittill ( "joined_team" );
		clearKillstreaks();
	}
}

killstreakUsePressed()
{
	self_pers_killstreaks = self.pers["killstreaks"];
	
	streakName = self_pers_killstreaks[self.killstreakIndexWeapon].streakName;
	lifeId = self_pers_killstreaks[self.killstreakIndexWeapon].lifeId;
	isEarned = self_pers_killstreaks[self.killstreakIndexWeapon].earned;
	awardXp = self_pers_killstreaks[self.killstreakIndexWeapon].awardXp;
	kID = self_pers_killstreaks[self.killstreakIndexWeapon].kID;
	isGimme = self_pers_killstreaks[self.killstreakIndexWeapon].isGimme;

	if( !self validateUseStreak() )
		return false;

	////	Balance for anyone using the explosive ammo killstreak, remove it when they activate the next killstreak
	//removeExplosiveAmmo = false;
	//if ( self _hasPerk( "specialty_explosivebullets" ) && !issubstr( streakName, "explosive_ammo" ) )
	//	removeExplosiveAmmo = true;

	if( IsSubStr( streakName, "airdrop" ) || streakName == "littlebird_flock" )	
	{
		if ( !self [[ level.killstreakFuncs[ streakName ] ]]( lifeId, kID ) )
			return ( false );
	}
	else
	{
		if ( !self [[ level.killstreakFuncs[ streakName ] ]]( lifeId ) )
		  return ( false );
	}
	
/#
	// let test client bots (not AI bots) use the full functionality of the killstreak usage	
	if( !IsBot( self ) && IsDefined( self.pers[ "isBot" ] ) && self.pers[ "isBot" ] )
		return true;
#/

	////	Balance for anyone using the explosive ammo killstreak, remove it when they activate the next killstreak
	//if ( removeExplosiveAmmo )
	//	self _unsetPerk( "specialty_explosivebullets" );
	
	self thread updateKillstreaks();
	self usedKillstreak( streakName, awardXp );

	//// NOTE: match leveling prototype
	////	clear the active killstreak bonus after use, this keeps it from being given back after death if nothing else has been earned
	//if( IsDefined( self.pers[ "activeKillstreakBonuses" ][0] ) )
	//	self.pers[ "activeKillstreakBonuses" ][0] = undefined;

	return ( true );
}


usedKillstreak( streakName, awardXp )
{	
	if ( awardXp )
	{
		self thread [[ level.onXPEvent ]]( "killstreak_" + streakName );
		self thread maps\mp\gametypes\_missions::useHardpoint( streakName );
	}
	
	awardref = maps\mp\_awards::getKillstreakAwardRef( streakName );
	if ( IsDefined( awardref ) )
		self thread incPlayerStat( awardref, 1 );

	if( isAssaultKillstreak( streakName ) )
	{
		self thread incPlayerStat( "assaultkillstreaksused", 1 );
	}
	else if( isSupportKillstreak( streakName ) )
	{
		self thread incPlayerStat( "supportkillstreaksused", 1 );
	}
	else if( isSpecialistKillstreak( streakName ) )
	{
		self thread incPlayerStat( "specialistkillstreaksearned", 1 );
		// no need to play specialist because we do leader dialog on the player with killstreakSplashNotify() and not just team specific things
		return;
	}

	// play killstreak dialog
	team = self.team;
	if ( level.teamBased )
	{
		thread leaderDialog( team + "_friendly_" + streakName + "_inbound", team );
		
		if ( getKillstreakEnemyUseDialog( streakName ) )
			thread leaderDialog( team + "_enemy_" + streakName + "_inbound", level.otherTeam[ team ] );
	}
	else
	{
		self thread leaderDialogOnPlayer( team + "_friendly_" + streakName + "_inbound" );
		
		if ( getKillstreakEnemyUseDialog( streakName ) )
		{
			excludeList[0] = self;
			thread leaderDialog( team + "_enemy_" + streakName + "_inbound", undefined, undefined, excludeList );
		}
	}
}


updateKillstreaks( keepCurrent )
{
	// early exit for when you give bots a killstreak to use
	if( !IsDefined( self.killstreakIndexWeapon ) )
		return;
	
	if ( !IsDefined( keepCurrent ) )
	{
		self.pers["killstreaks"][self.killstreakIndexWeapon].available = false;
	
		// if this is the gimme slot and we still have some stacked then leave available and set the new icon
		if( self.killstreakIndexWeapon == KILLSTREAK_GIMME_SLOT )
		{
			// if this is the gimme slot then clear the last used stacked killstreak before updating killstreaks
			self.pers["killstreaks"][ self.pers["killstreaks"][ KILLSTREAK_GIMME_SLOT ].nextSlot ] = undefined;		

			// loop through the stacked killstreaks and find the next available one
			streakName = undefined;
			self_pers_killstreaks = self.pers["killstreaks"];
			for( i = KILLSTREAK_STACKING_START_SLOT; i < self_pers_killstreaks.size; i++ )
			{
				if( !IsDefined( self_pers_killstreaks[i] ) || !IsDefined( self_pers_killstreaks[i].streakName ) )
					continue;

				streakName = self_pers_killstreaks[i].streakName;
				self_pers_killstreaks[ KILLSTREAK_GIMME_SLOT ].nextSlot = i;
			}
			
			if( IsDefined( streakName ) )
			{
				self_pers_killstreaks[ KILLSTREAK_GIMME_SLOT ].available = true;
				self_pers_killstreaks[ KILLSTREAK_GIMME_SLOT ].streakName = streakName;

				streakIndex = getKillstreakIndex( streakName );	
				self setCommonPlayerData( "killstreaksState", "icons", KILLSTREAK_GIMME_SLOT, streakIndex );

				// pc need to put this new one in the actionslot for use
				if( !level.console && !self is_player_gamepad_enabled() )
				{
					killstreakWeapon = getKillstreakWeapon( streakName );
					_setActionSlot( 4, "weapon", killstreakWeapon );	
				}
			}
		}
	}
	
	//	find the highest remaining streak and select it
	highestStreakIndex = undefined;
	if( self.streakType == "specialist" )
	{
		if ( self.pers["killstreaks"][ KILLSTREAK_GIMME_SLOT ].available )
			highestStreakIndex = KILLSTREAK_GIMME_SLOT;
	}	
	else
	{
		for ( i = KILLSTREAK_GIMME_SLOT; i < KILLSTREAK_SLOT_3 + 1; i++ )
		{
			self_pers_killstreaks_i = self.pers["killstreaks"][i];
			if( IsDefined( self_pers_killstreaks_i ) && 
				IsDefined( self_pers_killstreaks_i.streakName ) &&
				self_pers_killstreaks_i.available )
			{
				highestStreakIndex = i;
			}
		}
	}

	if ( IsDefined( highestStreakIndex ) )
	{
		if( level.console || self is_player_gamepad_enabled() )
		{
			self.killstreakIndexWeapon = highestStreakIndex;
			self.pers["lastEarnedStreak"] = self.pers["killstreaks"][highestStreakIndex].streakName;

			self giveSelectedKillstreakItem();			
		}
		// pc doesn't select killstreaks
		else
		{
			// make sure we still have all of the available killstreak weapons, things like the airdrop will get taken if you have more than one
			for ( i = KILLSTREAK_GIMME_SLOT; i < KILLSTREAK_SLOT_3 + 1; i++ )
			{
				self_pers_killstreaks_i = self.pers["killstreaks"][i];
				if( IsDefined( self_pers_killstreaks_i ) && 
					IsDefined( self_pers_killstreaks_i.streakName ) &&
					self_pers_killstreaks_i.available )
				{
					killstreakWeapon = getKillstreakWeapon( self_pers_killstreaks_i.streakName );
					weaponsListItems = self GetWeaponsListItems();
					hasKillstreakWeapon = false;
					for( j = 0; j < weaponsListItems.size; j++ )
					{
						if( killstreakWeapon == weaponsListItems[j] )
						{
							hasKillstreakWeapon = true;
							break;
						}
					}

					if( !hasKillstreakWeapon )
					{
						self _giveWeapon( killstreakWeapon );
					}
					else
					{
						// if we have more than one airdrop type weapon the ammo gets set to 0 because we give the next airdrop weapon before we take the last one
						//	this is a quicker fix than trying to figure out how to take and give at the right times
						if( IsSubStr( killstreakWeapon, "airdrop_" ) )
							self SetWeaponAmmoClip( killstreakWeapon, 1 );
					}

					// we should re-set the action slot just to make sure everything is correct (juggernaut needs this or they won't be able to use their killstreaks once obtained because we clear the action slots in giveLoadout())
					self _setActionSlot( i + 4, "weapon", killstreakWeapon );
				}
			}

			self.killstreakIndexWeapon = undefined;
			self.pers["lastEarnedStreak"] = self.pers["killstreaks"][highestStreakIndex].streakName;
			self updateStreakSlots();
		}
	}
	else
	{
		self.killstreakIndexWeapon = undefined;
		self.pers["lastEarnedStreak"] = undefined;
		self updateStreakSlots();

		// NOTE: we used to take item weapons from the player here but that stopped killstreak weapon animations from playing if it was the only killstreak
		//		since we take the item weapons when we give a killstreak weapon anyways, no need to do that here
		//		we've also added the waitTakeKillstreakWeapon() function to take them when appropriate
		// VERY IMPORTANT: with the current system, we NEVER want to loop and take all weapon list items
	}
}

clearKillstreaks()
{
	for( i = self.pers["killstreaks"].size - 1; i > -1; i-- )
	{
		if( IsDefined( self.pers["killstreaks"][i] ) )
			self.pers["killstreaks"][i] = undefined;
	}		
	
	initPlayerKillstreaks();
		
	self resetAdrenaline();
	self.killstreakIndexWeapon = undefined;
	self updateStreakSlots();
}

updateSpecialistKillstreaks()
{
	// reset if no adrenaline
	if( self.adrenaline == 0 )
	{
		for( i = KILLSTREAK_SLOT_1; i < KILLSTREAK_SLOT_3 + 1; i++ )
		{
			if( IsDefined( self.pers["killstreaks"][i] ) )
			{
				self.pers["killstreaks"][i].available = false;
				self setCommonPlayerData( "killstreaksState", "hasStreak", i, false );
			}
		}
		self setCommonPlayerData( "killstreaksState", "nextIndex", 1 );
		self setCommonPlayerData( "killstreaksState", "hasStreak", KILLSTREAK_ALL_PERKS_SLOT, false );
	}
	else
	{
		// loop through each earnable killstreak
		for( i = KILLSTREAK_SLOT_1; i < KILLSTREAK_SLOT_3 + 1; i++ )
		{
			self_pers_killstreaks_i = self.pers["killstreaks"][i];
			if( IsDefined( self_pers_killstreaks_i ) && 
				IsDefined( self_pers_killstreaks_i.streakName ) &&
				self_pers_killstreaks_i.available )
			{
				streakVal = getStreakCost( self_pers_killstreaks_i.streakName );
				if( streakVal > self.adrenaline )
				{
					// reset them because we're going to check them again and set them
					self.pers["killstreaks"][i].available = false;
					self setCommonPlayerData( "killstreaksState", "hasStreak", i, false );
					continue;
				}

				if( self.adrenaline >= streakVal )
				{
					// no need to give this again if we've already got it, this fixes a bug where all of the achieved sounds play as you enter the next round
					//	this also fixes a possibility of getting credit for getting another set of this killstreak in your player stats
					if( self getCommonPlayerData( "killstreaksState", "hasStreak", i ) )
					{
						// just call the killstreak function so we give the specialist perk back to the player each round
						if( IsDefined( level.killstreakFuncs[ self.pers["killstreaks"][i].streakName ] ) )
							self [[ level.killstreakFuncs[ self.pers["killstreaks"][i].streakName ] ]]();
						
						continue;
					}
					
					self giveKillstreak( self.pers["killstreaks"][i].streakName, self.pers["killstreaks"][i].earned, false, self );
				}
			}
		}

		// at a certain number of kills we'll give you all perks
		numKills = NUM_KILLS_GIVE_ALL_PERKS;
		if( self _hasPerk( "specialty_hardline" ) )
			numKills--;

		if( self.adrenaline >= numKills )
		{
			self setCommonPlayerData( "killstreaksState", "hasStreak", KILLSTREAK_ALL_PERKS_SLOT, true );
			self giveAllPerks();
		}
		else
			self setCommonPlayerData( "killstreaksState", "hasStreak", KILLSTREAK_ALL_PERKS_SLOT, false );
	}

	// update gimme slot killstreak regardless
	if ( self.pers["killstreaks"][ KILLSTREAK_GIMME_SLOT ].available )
	{
		streakName = self.pers["killstreaks"][ KILLSTREAK_GIMME_SLOT ].streakName;
		killstreakWeapon = getKillstreakWeapon( streakName );
		
		if( level.console || self is_player_gamepad_enabled() )
		{
			self giveKillstreakWeapon( killstreakWeapon );		
			self.killstreakIndexWeapon = KILLSTREAK_GIMME_SLOT;		
		}
		else
		{
			self _giveWeapon( killstreakWeapon );
			self _setActionSlot( 4, "weapon", killstreakWeapon );
			self.killstreakIndexWeapon = undefined;		
		}
	}
}

getFirstPrimaryWeapon()
{
	weaponsList = self getWeaponsListPrimaries();
	
	assert ( IsDefined( weaponsList[0] ) );
	assert ( !isKillstreakWeapon( weaponsList[0] ) );

	return weaponsList[0];
}


killstreakUseWaiter()
{
	self endon( "disconnect" );
	self endon( "finish_death" );
	self endon( "joined_team" );
	self endon( "faux_spawn" );
	level endon( "game_ended" );
	
	self notify( "killstreakUseWaiter" );
	self endon( "killstreakUseWaiter" );

	self.lastKillStreak = 0;
	if ( !IsDefined( self.pers["lastEarnedStreak"] ) )
		self.pers["lastEarnedStreak"] = undefined;
		
	self thread finishDeathWaiter();

	for ( ;; )
	{
		self waittill ( "weapon_change", newWeapon );
		
		if ( !isAlive( self ) )
			continue;

		if ( !IsDefined( self.killstreakIndexWeapon ) )
			continue;

		if ( !IsDefined( self.pers["killstreaks"][self.killstreakIndexWeapon] ) || !IsDefined( self.pers["killstreaks"][self.killstreakIndexWeapon].streakName ) )
			continue;

		killstreakWeapon = getKillstreakWeapon( self.pers["killstreaks"][self.killstreakIndexWeapon].streakName );
		if ( newWeapon != killstreakWeapon )
		{
			// since this weapon is not the killstreak we have selected, go back to the last weapon if we're holding an airdrop canister
			if( isStrStart( newWeapon, "airdrop_" ) )
			{
				self TakeWeapon( newWeapon );
				self SwitchToWeapon( self.lastdroppableweapon );
			}
			continue;
		}

		waittillframeend;
		
		//	get this stuff now because self.killstreakIndexWeapon will change after killstreakUsePressed()
		streakName = self.pers["killstreaks"][self.killstreakIndexWeapon].streakName;
		isGimme = self.pers["killstreaks"][self.killstreakIndexWeapon].isGimme;		
		
		assert( IsDefined( streakName ) );
		assert( IsDefined( level.killstreakFuncs[ streakName ] ) );		
		
		result = self killstreakUsePressed();

		lastWeapon = undefined;
		
		if ( !result && !isAlive( self ) && !self hasWeapon( self getLastWeapon() ) )
		{
			//	on death your weapon is dropped, if a private match default class was created with no secondary
			//	then getFirstPrimaryWeapon() in the 'else if' below will assert because you have no weapons left
			lastWeapon = self getLastWeapon();
			self _giveWeapon( lastWeapon );
		}		
		else if( !self hasWeapon( self getLastWeapon() ) )
		{
			lastWeapon = self getFirstPrimaryWeapon();			
		}
		else
		{
			lastWeapon = self getLastWeapon();
		}
		
		// we need to take the killstreak weapon away once we've switched back to our last weapon
		// this fixes an issue where you can call in a killstreak and then press right again to pull the killstreak weapon out
		if( result )
			self thread waitTakeKillstreakWeapon( killstreakWeapon, lastWeapon );

		//no force switching weapon for ridable killstreaks
		if ( shouldSwitchWeaponPostKillstreak( result, streakName ) )
		{
			self switch_to_last_weapon( lastWeapon );
		}

		// give time to switch to the near weapon; when the weapon is none (such as during a "disableWeapon()" period
		// re-enabling the weapon immediately does a "weapon_change" to the killstreak weapon we just used.  In the case that 
		// we have two of that killstreak, it immediately uses the second one
		if ( self GetCurrentWeapon() == "none" )
		{
			while ( self GetCurrentWeapon() == "none" )
				wait ( 0.05 );

			waittillframeend;
		}
	}
}

waitTakeKillstreakWeapon( killstreakWeapon, lastWeapon )
{
	self endon( "disconnect" );
	self endon( "finish_death" );
	self endon( "joined_team" );
	level endon( "game_ended" );

	self notify( "waitTakeKillstreakWeapon" );
	self endon( "waitTakeKillstreakWeapon" );

	// planted killstreaks like the sam, sentry, remote turret, and ims, will come in here with none as the current weapon sometimes because we _disableWeapons() while you carry them
	//	we need to know this so we can take the weapon correctly in these cases
	wasNone = ( self GetCurrentWeapon() == "none" );

	// this lets the killstreak weapon animation play and then take it once we switch away from it
	self waittill( "weapon_change", newWeapon );

	if( newWeapon == lastWeapon )
	{
		takeKillstreakWeaponIfNoDupe( killstreakWeapon );
		// pc needs to reset the killstreakIndexWeapon because we set this when they press the use button and we don't want the value lingering
		if( !level.console && !self is_player_gamepad_enabled() )
			self.killstreakIndexWeapon = undefined;
	}
	// this could happen with ridden killstreaks like the ac130
	else if( newWeapon != killstreakWeapon )
	{
		self thread waitTakeKillstreakWeapon( killstreakWeapon, lastWeapon );
	}
	// this could happen with planted killstreaks like the sam, sentry, remote turret, and ims
	//	they come into this function with current weapon as none and then the weapon change fires off immediately because we call _enableWeapons()
	//	that gives us back the killstreak weapon and it plays an animation before switching back to your normal weapon
	else if( wasNone && self GetCurrentWeapon() == killstreakWeapon )
	{
		self thread waitTakeKillstreakWeapon( killstreakWeapon, lastWeapon );
	}
}

takeKillstreakWeaponIfNoDupe( killstreakWeapon )
{
	// only take the killstreak weapon if they don't have anymore
	// the player could have two of the same killstreak and if we take the weapon then they can't use the second one
	hasKillstreak = false;
	for( i = 0; i < self.pers["killstreaks"].size; i++ )
	{
		if( IsDefined( self.pers["killstreaks"][i] ) && 
			IsDefined( self.pers["killstreaks"][i].streakName ) &&
			self.pers["killstreaks"][i].available )
		{
			// the specialist streaks use the killstreak_uav_mp weapon so don't try to compare specialist killstreak weapons
			//	this fixes a bug where you earn a uav, change classes to specialist and earn the first streak, use the uav and the killstreak weapon doesn't get taken because it thinks you still have one
			if( !isSpecialistKillstreak( self.pers["killstreaks"][i].streakName ) && killstreakWeapon == getKillstreakWeapon( self.pers["killstreaks"][i].streakName ) )
			{
				hasKillstreak = true;
				break;
			}
		}
	}

	// if they have the killstreak then check to see if the currently selected killstreak is the same killstreak, if not take the weapon because it'll be given to them when they select it
	if( hasKillstreak )
	{
		if( level.console || self is_player_gamepad_enabled() )
		{
			if( IsDefined( self.killstreakIndexWeapon ) && killstreakWeapon != getKillstreakWeapon( self.pers["killstreaks"][self.killstreakIndexWeapon].streakName ) )
			{
				// take the weapon because it's currently not the selected killstreak
				self TakeWeapon( killstreakWeapon );
			}
			else if( IsDefined( self.killstreakIndexWeapon ) && killstreakWeapon == getKillstreakWeapon( self.pers["killstreaks"][self.killstreakIndexWeapon].streakName ) )
			{
				// take and give it right back, this fixes an issue where you could have two of the same weapons and after using the first then you couldn't use the second
				//	this was reproduced by doing predator, precision airstrike, strafe run, where airstrike and strafe run use the same weapon
				//	so if you called in the predator, then called in the strafe, you couldn't use the airstrike because you no longer have the weapon
				//	script isn't taking the weapon from you but code was saying clear that slot because the weapons were 'clip only', they shouldn't be
				self TakeWeapon( killstreakWeapon );
				self _giveWeapon( killstreakWeapon, 0 );
				self _setActionSlot( 4, "weapon", killstreakWeapon );
			}
		}
		// pc doesn't have selected killstreaks
		else
		{
			// we still want to take and give to make sure they have the weapon
			self TakeWeapon( killstreakWeapon );
			self _giveWeapon( killstreakWeapon, 0 );
		}
	}
	else
		self TakeWeapon( killstreakWeapon );
}

shouldSwitchWeaponPostKillstreak( result, streakName )
{
	// certain killstreaks handle the weapon switching
	if( !result )
		return true;
	if( isRideKillstreak( streakName ) )
		return false;

	return true;	
}


finishDeathWaiter()
{
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	
	self notify ( "finishDeathWaiter" );
	self endon ( "finishDeathWaiter" );
	
	self waittill ( "death" );
	wait ( 0.05 );
	self notify ( "finish_death" );
	self.pers["lastEarnedStreak"] = undefined;
}

checkStreakReward()
{
	foreach ( streakName in self.killstreaks )
	{
		streakVal = getStreakCost( streakName );
		
		if ( streakVal > self.adrenaline )
			break;
		
		if ( self.previousAdrenaline < streakVal && self.adrenaline >= streakVal )
		{
			// to avoid confusion about not really earning a killstreak if you already have it and come around again
			//	we're going to give you the killstreak again and also allow it to chain
			self earnKillstreak( streakName, streakVal ); 

			////	No stacking (double earning)
			//alreadyEarned = false;
			//for ( i=1; i<self.pers["killstreaks"].size; i++ )
			//{
			//	if( IsDefined( self.pers["killstreaks"][i] ) && 
			//		( IsDefined( self.pers["killstreaks"][i].streakName ) && self.pers["killstreaks"][i].streakName == streakName ) && 
			//		( IsDefined( self.pers["killstreaks"][i].available ) && self.pers["killstreaks"][i].available == true ) )
			//	{
			//		alreadyEarned = true;
			//		break;
			//	}
			//}
			//if ( alreadyEarned )
			//{
			//	self.earnedStreakLevel = streakVal;
			//	updateStreakSlots();
			//}
			//else
			//	self earnKillstreak( streakName, streakVal ); 
			break;
		}
	}
}


killstreakEarned( streakName )
{
	streakArray = "assault";
	switch ( self.streakType )
	{
		case "assault":
			streakArray = "assaultStreaks";
			break;
		case "support":
			streakArray = "supportStreaks";
			break;
		case "specialist":
			streakArray = "specialistStreaks";
			break;
	}

	if( IsDefined( self.class_num ) )
	{
		if ( self getCacPlayerData( self.class_num, streakArray, 0 ) == streakName )
		{
			self.firstKillstreakEarned = getTime();
		}	
		else if ( self getCaCPlayerData( self.class_num, streakArray, 2 ) == streakName && IsDefined( self.firstKillstreakEarned ) )
		{
			if ( getTime() - self.firstKillstreakEarned < 20000 )
				self thread maps\mp\gametypes\_missions::genericChallenge( "wargasm" );
		}
	}
}


earnKillstreak( streakName, streakVal )
{
	level notify ( "gave_killstreak", streakName );
	
	self.earnedStreakLevel = streakVal;

	if ( !level.gameEnded )
	{
		appendString = undefined;
		// if this is specialist then we need to see if they are using the pro versions of perks in the streak
		if( self.streakType == "specialist" )
		{
			perkName = GetSubStr( streakName, 0, streakName.size - 3 );
			if( maps\mp\gametypes\_class::isPerkUpgraded( perkName ) )
			{
				appendString = "pro";
			}
		}
		self thread maps\mp\gametypes\_hud_message::killstreakSplashNotify( streakName, streakVal, appendString );
		//In Fireteam mode, notify my commander if I got a killstreak
		if ( bot_is_fireteam_mode() )
		{
			if ( IsDefined( appendString ) )
			{
				self notify( "bot_killstreak_earned", streakName+"_"+appendString, streakVal );
			}
			else
			{
				self notify( "bot_killstreak_earned", streakName, streakVal );
			}
		}
	}

	self thread killstreakEarned( streakName );
	self.pers["lastEarnedStreak"] = streakName;

	self setStreakCountToNext();

	/* UNUSED IW6 TEAMSTREAK
	if ( level.teamBased && isAllTeamStreak( streakName ) )
	{
		
		if ( streakName == "lasedStrike" )
			self thread teamPlayerCardSplash( "team_lasedStrike", self, self.team );
					
		foreach ( player in level.players )
		{
						
			if ( streakName == "lasedStrike" )
			{
				if ( player.hasSoflam )
					continue;
				
				player.soflamAmmoUsed = 0;
			}
				
			if ( player.team == self.team && player != self )
			{
				player giveKillstreak( streakName, false, false, player );
			}
				
			if ( player == self )
			{
				player giveKillstreak( streakName, false, true, self );
			}
			
		}
	}
	else */
		
	self giveKillstreak( streakName, true, true );
}

giveKillstreak( streakName, isEarned, awardXp, owner )
{
	self endon( "givingLoadout" );

	if ( !IsDefined( level.killstreakFuncs[streakName] ) )
	{
		AssertMsg( "giveKillstreak() called with invalid killstreak: " + streakName );
		return;
	}	
	//	for devmenu give with spectators in match 
	if( self.team == "spectator" )
		return;
	
	self endon ( "disconnect" );	
	
	//	streaks given from crates go in the gimme 
	index = undefined;
	if ( !IsDefined( isEarned ) || isEarned == false )
	{
		// put this killstreak in the next available position
		// 0 - gimme slot (that will index stacked killstreaks)
		// 1-3 - cac selected killstreaks
		// 4 - specialist all perks bonus
		// 5 or more - stacked killstreaks

		// MW3 way so it will stack in the gimme slot
		nextSlot = self.pers[ "killstreaks" ].size; // the size should be 5 by default, it will grow as they get stacked killstreaks
		// NOTE: match leveling prototype
		//	replacing whatever is in slot 0 every time we get a killstreak, MW3 did stacking
		//nextSlot = 5;
		if( !IsDefined( self.pers[ "killstreaks" ][ nextSlot ] ) )
			self.pers[ "killstreaks" ][ nextSlot ] = spawnStruct();

		self.pers[ "killstreaks" ][ nextSlot ].available = false;
		self.pers[ "killstreaks" ][ nextSlot ].streakName = streakName;
		self.pers[ "killstreaks" ][ nextSlot ].earned = false;
		self.pers[ "killstreaks" ][ nextSlot ].awardxp = IsDefined( awardXp ) && awardXp;
		self.pers[ "killstreaks" ][ nextSlot ].owner = owner;
		self.pers[ "killstreaks" ][ nextSlot ].kID = self.pers["kID"];
		self.pers[ "killstreaks" ][ nextSlot ].lifeId = -1;
		self.pers[ "killstreaks" ][ nextSlot ].isGimme = true;		
		self.pers[ "killstreaks" ][ nextSlot ].isSpecialist = false;		

		self.pers[ "killstreaks" ][ KILLSTREAK_GIMME_SLOT ].nextSlot = nextSlot;		
		self.pers[ "killstreaks" ][ KILLSTREAK_GIMME_SLOT ].streakName = streakName;

		index = KILLSTREAK_GIMME_SLOT;	
		streakIndex = getKillstreakIndex( streakName );	
		self setCommonPlayerData( "killstreaksState", "icons", KILLSTREAK_GIMME_SLOT, streakIndex );
	}
	else
	{
		for( i = KILLSTREAK_SLOT_1; i < KILLSTREAK_SLOT_3 + 1; i++ )
		{
			if( IsDefined( self.pers["killstreaks"][i] ) && 
				IsDefined( self.pers["killstreaks"][i].streakName ) &&
				streakName == self.pers["killstreaks"][i].streakName )
			{
				index = i;
				break;
			}
		}		
		if ( !IsDefined( index ) )
		{
			AssertMsg( "earnKillstreak() trying to give unearnable killstreak with giveKillstreak(): " + streakName );
			return;
		}		
	}
	
	self.pers["killstreaks"][index].available = true;
	self.pers["killstreaks"][index].earned = IsDefined( isEarned ) && isEarned;
	self.pers["killstreaks"][index].awardxp = IsDefined( awardXp ) && awardXp;
	self.pers["killstreaks"][index].owner = owner;
	self.pers["killstreaks"][index].kID = self.pers["kID"];
	//self.pers["kIDs_valid"][self.pers["kID"]] = true;
	self.pers["kID"]++;

	if ( !self.pers["killstreaks"][index].earned )
		self.pers["killstreaks"][index].lifeId = -1;
	else
		self.pers["killstreaks"][index].lifeId = self.pers["deaths"];
	
	AssertEx( isDefined(self), "Player to be rewarded is undefined" );
	AssertEx( IsPlayer(self), "Somehow a non player ent is receiving a killstreak reward" );
	AssertEx( isDefined(self.streakType), "Player: "+ self.name + " doesn't have a streakType defined" );
	
	// the specialist streak type automatically turns on and there is no weapon to use
	if( self.streakType == "specialist" && index != KILLSTREAK_GIMME_SLOT )
	{
		self.pers[ "killstreaks" ][ index ].isSpecialist = true;		
		if( IsDefined( level.killstreakFuncs[ streakName ] ) )
			self [[ level.killstreakFuncs[ streakName ] ]]();
		//self thread updateKillstreaks();
		self usedKillstreak( streakName, awardXp );
	}
	else
	{
		if( level.console || self is_player_gamepad_enabled() )
		{
			weapon = getKillstreakWeapon( streakName );
			self giveKillstreakWeapon( weapon );	

			// NOTE_A (also see NOTE_B): before we change the killstreakIndexWeapon, let's make sure it's not the one we're holding
			//	if we're currently holding something like an airdrop marker and we earned a killstreak while holding it then we want that to remain the weapon index
			//	because if it's not, then when you throw it, it'll think we're using a different killstreak and not take it away but it'll take away the other one
			if( IsDefined( self.killstreakIndexWeapon ) )
			{
				streakName = self.pers["killstreaks"][self.killstreakIndexWeapon].streakName;
				killstreakWeapon = getKillstreakWeapon( streakName );
				if( !( self isCurrentlyHoldingKillstreakWeapon( killstreakWeapon ) ) )
				{
					self.killstreakIndexWeapon = index;
				}
			}
			else
			{
				self.killstreakIndexWeapon = index;		
			}
		}
		else
		{
			// for pc, we need to give you the killstreak weapon in the right action slot

			// if this is the gimme slot then take away the weapon for what is in there right now and just give them this new one
			//	we don't want to keep giving weapons every time they get something in the gimme slot because there is a cap eventually
			if( KILLSTREAK_GIMME_SLOT == index && self.pers[ "killstreaks" ][ KILLSTREAK_GIMME_SLOT ].nextSlot > KILLSTREAK_STACKING_START_SLOT )
			{
				// since nextSlot has already been incremented, get the next lowest and take the weapon
				slotToTake = self.pers[ "killstreaks" ][ KILLSTREAK_GIMME_SLOT ].nextSlot - 1;
				killstreakWeaponToTake = getKillstreakWeapon( self.pers["killstreaks"][ slotToTake ].streakName );		
				self TakeWeapon( killstreakWeaponToTake );
			}

			killstreakWeapon = getKillstreakWeapon( streakName );		
			self _giveWeapon( killstreakWeapon, 0 );
			self _setActionSlot( index + 4, "weapon", killstreakWeapon );
		}
	}
		
	self updateStreakSlots();
	
	if ( IsDefined( level.killstreakSetupFuncs[ streakName ] ) )
		self [[ level.killstreakSetupFuncs[ streakName ] ]]();
		
	if ( IsDefined( isEarned ) && isEarned && IsDefined( awardXp ) && awardXp )
		self notify( "received_earned_killstreak" );
}

isCurrentlyHoldingKillstreakWeapon( weaponName )
{
	curWeapon = self GetCurrentWeapon();
	switch ( weaponName )
	{
		case "killstreak_uav_mp":
			return curWeapon == "killstreak_remote_uav_mp";
	}
	return curWeapon == weaponName;
}

giveKillstreakWeapon( weapon )
{
	self endon( "disconnect" );

	// pc doesn't need to give the weapon because you use on a single button press (unless using gamepad)
	if( !level.console && !self is_player_gamepad_enabled() )
		return;

	weaponList = self GetWeaponsListItems();
	
	foreach( item in weaponList )
	{
		if( !isStrStart( item, "killstreak_" ) && !isStrStart( item, "airdrop_" ) && !isStrStart( item, "deployable_" ) )
			continue;
	
		// need to do an extra check here because current weapon could be "none" but the weapon we're changing to could be one of the items in the weaponList
		//	this fixes a bug where you could be pulling out a care package when you earned the next killstreak and it would not give you the next killstreak but give you an extra care package instead
		if( self GetCurrentWeapon() == item || 
			( IsDefined( self.changingWeapon ) && self.changingWeapon == item ) )
			continue;
		
		while( self isChangingWeapon() )
			wait ( 0.05 );	
			
		self TakeWeapon( item );
	}
	
	// NOTE_B (also see NOTE_A) : before we giving the killstreak weapon, let's make sure it's not the one we're holding
	//	if we're currently holding something like an airdrop marker and we earned a killstreak while holding it then we want that to remain the killstreak weapon
	//	because if it's not, then when we earn the new killstreak, we won't be able to put this one away because it thinks it's something else
	if( IsDefined( self.killstreakIndexWeapon ) )
	{
		streakName = self.pers["killstreaks"][self.killstreakIndexWeapon].streakName;
		killstreakWeapon = getKillstreakWeapon( streakName );
		if( self GetCurrentWeapon() != killstreakWeapon )
		{
			if( weapon != "" )
			{
				self _giveWeapon( weapon, 0 );
				self _setActionSlot( 4, "weapon", weapon );
			}
		}
	}
	else
	{
		self _giveWeapon( weapon, 0 );
		self _setActionSlot( 4, "weapon", weapon );
	}
}


getStreakCost( streakName )
{
	cost = int( getKillstreakKills( streakName ) );

	if( IsDefined( self ) && IsPlayer( self ) )
	{
		if( isSpecialistKillstreak( streakName ) )
		{
			if ( isDefined( self.pers["gamemodeLoadout"] ) )
			{
				if ( isDefined( self.pers["gamemodeLoadout"]["loadoutKillstreak1"] ) && self.pers["gamemodeLoadout"]["loadoutKillstreak1"] == streakName )
					cost = 2;
				else if ( isDefined( self.pers["gamemodeLoadout"]["loadoutKillstreak2"] ) && self.pers["gamemodeLoadout"]["loadoutKillstreak2"] == streakName )
					cost = 4;
				else if ( isDefined( self.pers["gamemodeLoadout"]["loadoutKillstreak3"] ) && self.pers["gamemodeLoadout"]["loadoutKillstreak3"] == streakName )
					cost = 6;
				else
					AssertMsg( "getStreakCost: killstreak doesn't exist in player's loadout" );	
			}			
			else if ( IsSubStr( self.curClass, "custom" ) )
			{
				index = 0;
				for( ; index < 3; index++ )
				{
					killstreak = self getCaCPlayerData( self.class_num, "specialistStreaks", index );
					if( killstreak == streakName )
						break;
				}
				AssertEx( index <= 2, "getStreakCost: killstreak index greater than 2 when it shouldn't be" );
				cost = self getCaCPlayerData( self.class_num, "specialistStreakKills", index );
			}
			else if ( isSubstr( self.curClass, "axis" ) || isSubstr( self.curClass, "allies" ) )
			{
				index = 0;
				teamName = "none";
				if( isSubstr( self.curClass, "axis" ) )
				{
					teamName = "axis";
				}
				else if( isSubstr( self.curClass, "allies" ) )
				{
					teamName = "allies";
				}

				classIndex = getClassIndex( self.curClass );
				for( ; index < 3; index++ )
				{
					killstreak = GetMatchRulesData( "defaultClasses", teamName, classIndex, "class", "specialistStreaks", index );					
					if( killstreak == streakName )
						break;
				}
				AssertEx( index <= 2, "getStreakCost: killstreak index greater than 2 when it shouldn't be" );
				cost = GetMatchRulesData( "defaultClasses", teamName, classIndex, "class", "specialistStreakKills", index );
			}
		}

		if( self _hasPerk( "specialty_hardline" ) && cost > 0 )
			cost--;
	}
	return cost;
}

streakTypeResetsOnDeath( streakType )
{
	switch ( streakType )
	{
		case "assault":
		case "specialist":
			return true;
		case "support":
			return false;
	}
}

giveOwnedKillstreakItem( skipDialog )
{
	self_pers_killstreaks = self.pers["killstreaks"];
	
	if( level.console || self is_player_gamepad_enabled() )
	{
		//	find the highest costing streak
		keepIndex = -1;
		highestCost = -1;
		for( i = KILLSTREAK_GIMME_SLOT; i < KILLSTREAK_SLOT_3 + 1; i++ )
		{
			if( IsDefined( self_pers_killstreaks[i] ) && 
				IsDefined( self_pers_killstreaks[i].streakName ) &&
				self_pers_killstreaks[i].available && 
				getStreakCost( self_pers_killstreaks[i].streakName ) > highestCost )
			{
				// make sure the gimme slot is the lowest regardless of the cost of the killstreak in it
				highestCost = 0;
				if( !self_pers_killstreaks[i].isGimme )
					highestCost = getStreakCost( self_pers_killstreaks[i].streakName );
				keepIndex = i;	
			} 
		}

		if ( keepIndex != -1 )
		{
			//	select it
			self.killstreakIndexWeapon = keepIndex;

			//	give the weapon
			streakName = self_pers_killstreaks[self.killstreakIndexWeapon].streakName;
			weapon = getKillstreakWeapon( streakName );
			self giveKillstreakWeapon( weapon );		
		}	
		else
			self.killstreakIndexWeapon = undefined;			
	}
	// pc doesn't select killstreaks
	else
	{
		keepIndex = -1;
		highestCost = -1;
		// make sure we still have all of the available killstreak weapons
		for( i = KILLSTREAK_GIMME_SLOT; i < KILLSTREAK_SLOT_3 + 1; i++ )
		{
			if( IsDefined( self_pers_killstreaks[i] ) && 
				IsDefined( self_pers_killstreaks[i].streakName ) &&
				self_pers_killstreaks[i].available )
			{
				killstreakWeapon = getKillstreakWeapon( self_pers_killstreaks[i].streakName );
				weaponsListItems = self GetWeaponsListItems();
				hasKillstreakWeapon = false;
				for( j = 0; j < weaponsListItems.size; j++ )
				{
					if( killstreakWeapon == weaponsListItems[j] )
					{
						hasKillstreakWeapon = true;
						break;
					}
				}

				if( !hasKillstreakWeapon )
				{
					self _giveWeapon( killstreakWeapon );
				}
				else
				{
					// if we have more than one airdrop type weapon the ammo gets set to 0 because we give the next airdrop weapon before we take the last one
					//	this is a quicker fix than trying to figure out how to take and give at the right times
					if( IsSubStr( killstreakWeapon, "airdrop_" ) )
						self SetWeaponAmmoClip( killstreakWeapon, 1 );
				}

				// since the killstreak is available, make sure the actionslot is set correctly
				//	this fixes a bug where you could have, for example, a uav in your gimme slot and earned a uav before you died, when you respawned the earned uav actionslot wasn't set and you couldn't use it
				self _setActionSlot( i + 4, "weapon", killstreakWeapon );

				// get the highest value killstreak so we can show hint text for it on spawn
				// make sure the gimme slot is the lowest regardless of the cost of the killstreak in it
				if( getStreakCost( self_pers_killstreaks[i].streakName ) > highestCost )
				{
					highestCost = 0;
					if( !self_pers_killstreaks[i].isGimme )
						highestCost = getStreakCost( self_pers_killstreaks[i].streakName );
					keepIndex = i;	
				}
			}
		}

		if ( keepIndex != -1 )
		{
			streakName = self_pers_killstreaks[ keepIndex ].streakName;
		}

		self.killstreakIndexWeapon = undefined;
	}
		
	updateStreakSlots();	
}


initRideKillstreak( streak )
{
	self _disableUsability();
	result = self initRideKillstreak_internal( streak );

	if ( IsDefined( self ) )
		self _enableUsability();
		
	return result;
}


initRideKillstreak_internal( streak )
{	
	if ( IsDefined( streak ) && isLaptopTimeoutKillstreak( streak ) )
		laptopWait = "timeout";
	else
		laptopWait = self waittill_any_timeout( 1.0, "disconnect", "death", "weapon_switch_started" );
		
	maps\mp\gametypes\_hostmigration::waitTillHostMigrationDone();

	if ( laptopWait == "weapon_switch_started" )
		return ( "fail" );

	if ( !isAlive( self ) )
		return "fail";

	if ( laptopWait == "disconnect" || laptopWait == "death" )
	{
		if ( laptopWait == "disconnect" )
			return ( "disconnect" );

		if ( self.team == "spectator" )
			return "fail";

		return ( "success" );		
	}
	
	if ( self isEMPed() || self isNuked() || self isAirDenied() )
	{
		return ( "fail" );
	}
	
	self VisionSetNakedForPlayer( "black_bw", 0.75 );
	blackOutWait = self waittill_any_timeout( 0.80, "disconnect", "death" );

	maps\mp\gametypes\_hostmigration::waitTillHostMigrationDone();

	if ( blackOutWait != "disconnect" ) 
	{
		self thread clearRideIntro( 1.0 );
		
		if ( self.team == "spectator" )
			return "fail";
	}

	if ( self isOnLadder() )
		return "fail";	

	if ( !isAlive( self ) )
		return "fail";

	if ( self isEMPed() || self isNuked() || self isAirDenied() )
		return "fail";
	
	if ( blackOutWait == "disconnect" )
		return ( "disconnect" );
	else
		return ( "success" );		
}

isLaptopTimeoutKillstreak( streak )
{
	switch( streak )
	{
		case "osprey_gunner":
		case "remote_uav":
		case "remote_tank":
		case "heli_pilot":
		case "vanguard":
		case "drone_hive":
		case "odin_support":
			return true;
	}
	return false;
}

clearRideIntro( delay, fadeBack )
{
	self endon( "disconnect" );

	if ( IsDefined( delay ) )
		wait( delay );
	
	if ( !isDefined( fadeBack ) )
		fadeBack = 0;

	//self freezeControlsWrapper( false );
	
	if ( IsDefined( level.nukeDetonated ) )
		self VisionSetNakedForPlayer( level.nukeVisionSet, fadeBack );
	else
		self VisionSetNakedForPlayer( "", fadeBack ); // go to default visionset

	self notify( "intro_cleared" );
}


giveSelectedKillstreakItem()
{
	streakName = self.pers["killstreaks"][self.killstreakIndexWeapon].streakName;

	weapon = getKillstreakWeapon( streakName );
	self giveKillstreakWeapon( weapon );
	
	self updateStreakSlots();
}

getKillstreakCount()
{
	numAvailable = 0;
	for( i = KILLSTREAK_GIMME_SLOT; i < KILLSTREAK_SLOT_3 + 1; i++ )
	{
		if( IsDefined( self.pers["killstreaks"][i] ) && 
			IsDefined( self.pers["killstreaks"][i].streakName ) &&
			self.pers["killstreaks"][i].available )
		{
			numAvailable++;
		}
	}
	return numAvailable;
}

shuffleKillstreaksUp()
{
	if ( getKillstreakCount() > 1 )
	{		
		while ( true )
		{
			self.killstreakIndexWeapon++;		
			if ( self.killstreakIndexWeapon > KILLSTREAK_SLOT_3 )
				self.killstreakIndexWeapon = 0;
			if ( self.pers["killstreaks"][self.killstreakIndexWeapon].available == true )
				break;			
		}
		
		giveSelectedKillstreakItem();		
	}
}

shuffleKillstreaksDown()
{
	if ( getKillstreakCount() > 1 )
	{
		while ( true )
		{
			self.killstreakIndexWeapon--;		
			if ( self.killstreakIndexWeapon < 0 )
				self.killstreakIndexWeapon = KILLSTREAK_SLOT_3;
			if ( self.pers["killstreaks"][self.killstreakIndexWeapon].available == true )
				break;
		}
		
		giveSelectedKillstreakItem();		
	}
}

streakSelectUpTracker()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	self endon ( "faux_spawn" );
	level endon ( "game_ended" );
	
	for (;;)
	{
		self waittill( "toggled_up" );
		
		if ( !level.Console && !self is_player_gamepad_enabled() )
			continue;
		
		if( IsDefined( self.showingTacticalSelections ) && self.showingTacticalSelections )
			continue;

		if( !self isMantling() &&
			( !IsDefined( self.changingWeapon ) || ( IsDefined( self.changingWeapon ) && self.changingWeapon == "none" ) ) && 
			( !isKillstreakWeapon( self GetCurrentWeapon() ) || ( isKillstreakWeapon( self GetCurrentWeapon() ) && self isJuggernaut() ) ) &&
			self.streakType != "specialist" &&
			( !IsDefined( self.isCarrying ) || ( IsDefined( self.isCarrying ) && self.isCarrying == false ) ) &&
			( !IsDefined( self.lastStreakUsed ) || ( IsDefined( self.lastStreakUsed ) && ( GetTime() - self.lastStreakUsed ) > 100 ) ) )
		{
			self shuffleKillstreaksUp();
		}
		wait( .12 );
	}
}

streakSelectDownTracker()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	self endon ( "faux_spawn" );
	level endon ( "game_ended" );
	
	for (;;)
	{
		self waittill( "toggled_down" );
		
		if ( !level.Console && !self is_player_gamepad_enabled() )
			continue;
		
		if( IsDefined( self.showingTacticalSelections ) && self.showingTacticalSelections )
			continue;

		if( !self isMantling() &&
			( !IsDefined( self.changingWeapon ) || ( IsDefined( self.changingWeapon ) && self.changingWeapon == "none" ) ) && 
			( !isKillstreakWeapon( self GetCurrentWeapon() ) || ( isKillstreakWeapon( self GetCurrentWeapon() ) && self isJuggernaut() ) ) &&
			self.streakType != "specialist" &&
			( !IsDefined( self.isCarrying ) || ( IsDefined( self.isCarrying ) && self.isCarrying == false ) ) &&
			( !IsDefined( self.lastStreakUsed ) || ( IsDefined( self.lastStreakUsed ) && ( GetTime() - self.lastStreakUsed ) > 100 ) ) )
		{
			self shuffleKillstreaksDown();
		}
		wait( .12 );
	}
}

streakUseTimeTracker()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	self endon ( "faux_spawn" );
	level endon ( "game_ended" );
	
	for (;;)
	{
		self waittill( "streakUsed" );
		self.lastStreakUsed = GetTime();
	}
}

streakNotifyTracker()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	
	gameFlagWait( "prematch_done" );

	if( level.console )
	{
		self notifyOnPlayerCommand( "toggled_up", "+actionslot 1" );
		self notifyOnPlayerCommand( "toggled_down", "+actionslot 2" );
	}
	else
	if( level.console )
	{
		self notifyOnPlayerCommand( "toggled_up", "+actionslot 1" );
		self notifyOnPlayerCommand( "toggled_down", "+actionslot 2" );

		self notifyOnPlayerCommand( "streakUsed", "+actionslot 4" );
		self notifyOnPlayerCommand( "streakUsed", "+actionslot 5" );
		self notifyOnPlayerCommand( "streakUsed", "+actionslot 6" );
		self notifyOnPlayerCommand( "streakUsed", "+actionslot 7" );
	}
	else
	self notifyOnPlayerCommand( "toggled_up", "+actionslot 1" );
	self notifyOnPlayerCommand( "toggled_down", "+actionslot 2" );
	
	if( !level.console )
	{
		self notifyOnPlayerCommand( "streakUsed1", "+actionslot 4" );
		self notifyOnPlayerCommand( "streakUsed2", "+actionslot 5" );
		self notifyOnPlayerCommand( "streakUsed3", "+actionslot 6" );
		self notifyOnPlayerCommand( "streakUsed4", "+actionslot 7" );
	}
}



//	ADRENALINE STUFF MOVED FROM _UTILITY.GSC
//	TODO: rename

registerAdrenalineInfo( type, value )
{
	if ( !IsDefined( level.adrenalineInfo ) )
		level.adrenalineInfo = [];
		
	level.adrenalineInfo[type] = value;
}


giveAdrenaline( type )
{	
	assertEx( IsDefined( level.adrenalineInfo[type] ), "Unknown adrenaline type: " + type );	
	
	if ( level.adrenalineInfo[type] == 0 )
		return;		
	
	//fixes bug with juggernaut bomb carrier
	if ( self isJuggernaut() && self.streakType == "specialist" )
		return;
	
	newAdrenaline = self.adrenaline + level.adrenalineInfo[type];
	adjustedAdrenaline = newAdrenaline;
	maxStreakCost = self getMaxStreakCost();
	if ( adjustedAdrenaline > maxStreakCost && ( self.streakType != "specialist" ) )
	{
		adjustedAdrenaline = adjustedAdrenaline - maxStreakCost;
	}
	else if ( level.killstreakRewards && adjustedAdrenaline > maxStreakCost && self.streakType == "specialist" )
	{
		// at a certain number of kills we'll give you all perks
		numKills = NUM_KILLS_GIVE_ALL_PERKS;
		if( self _hasPerk( "specialty_hardline" ) )
			numKills--;

		if( adjustedAdrenaline == numKills )
		{
			//self thread giveKillstreak( "airdrop_assault", false, true, self );
			//self thread maps\mp\gametypes\_hud_message::killstreakSplashNotify( "airdrop_assault", 8 );

			self giveAllPerks();

			self usedKillstreak( "all_perks_bonus", true );
			self thread maps\mp\gametypes\_hud_message::killstreakSplashNotify( "all_perks_bonus", numKills );
			self setCommonPlayerData( "killstreaksState", "hasStreak", KILLSTREAK_ALL_PERKS_SLOT, true );
			self.pers["killstreaks"][ KILLSTREAK_ALL_PERKS_SLOT ].available = true;
		}

		// give a little xp for being maxed out and continued streaking, for the specialist only
		// every two kills after max
		if( maxStreakCost > 0 && !( ( adjustedAdrenaline - maxStreakCost ) % 2 ) )
		{
			self thread maps\mp\gametypes\_rank::xpEventPopup( &"KILLSTREAKS_SPECIALIST_STREAKING_XP" );
			self thread maps\mp\gametypes\_rank::giveRankXP( "kill" );
		}
	}

	self setAdrenaline( adjustedAdrenaline );
	self checkStreakReward();
	
	if ( newAdrenaline == maxStreakCost && ( self.streakType != "specialist" ) )
		setAdrenaline( 0 );
}

giveAllPerks() // self == player
{
	// for the specialist strike package when you get to a certain number of kills
	// give them all of the perks
	perks = [];
	//perks[ perks.size ] = "specialty_longersprint";
	perks[ perks.size ] = "specialty_fastreload";
	perks[ perks.size ] = "specialty_scavenger";
	perks[ perks.size ] = "specialty_blindeye";
	perks[ perks.size ] = "specialty_paint";
	perks[ perks.size ] = "specialty_hardline"; // give hardline because of the hidden killstreaks, like the nuke
	perks[ perks.size ] = "specialty_coldblooded";
	perks[ perks.size ] = "specialty_quickdraw";
	// two primaries doesn't make sense to give
	perks[ perks.size ] = "_specialty_blastshield";
	perks[ perks.size ] = "specialty_detectexplosive";
	perks[ perks.size ] = "specialty_autospot";
	perks[ perks.size ] = "specialty_bulletaccuracy";
	// we aren't doing steadyimpro right now
	perks[ perks.size ] = "specialty_quieter";
	perks[ perks.size ] = "specialty_stalker";
	perks[ perks.size ] = "specialty_marathon";
	perks[ perks.size ] = "specialty_explosivedamage";
	// give weapon buffs also as an added bonus
	// don't give bullet penetration because there is a performance issue with shotguns and fx when they shoot 8 chunks at once
	perks[ perks.size ] = "specialty_marksman";
	perks[ perks.size ] = "specialty_sharp_focus";
	// don't give hold breath while ads because it'll show up on things like pistols
	perks[ perks.size ] = "specialty_longerrange";
	perks[ perks.size ] = "specialty_fastermelee";
	perks[ perks.size ] = "specialty_reducedsway";
	perks[ perks.size ] = "specialty_lightweight";

	perks[ perks.size ] = "specialty_combat_speed";
	perks[ perks.size ] = "specialty_regenfaster";
	perks[ perks.size ] = "specialty_delaymine";

	foreach( perkName in perks )
	{
		if( !self _hasPerk( perkName ) )
		{
			self givePerk( perkName, false );
			if( maps\mp\gametypes\_class::isPerkUpgraded( perkName ) )
			{
				perkUpgrade = tablelookup( "mp/perktable.csv", 1, perkName, 8 );
				self givePerk( perkUpgrade, false );
			}
		}
	}
}

resetAdrenaline()
{
	self.earnedStreakLevel = 0;
	self setAdrenaline(0);		
	self resetStreakCount();	
	if ( IsDefined( self.pers["lastEarnedStreak"] ) )
		self.pers["lastEarnedStreak"] = undefined;
}


setAdrenaline( value )
{
	if ( value < 0 )
		value = 0;
	
	if ( IsDefined( self.adrenaline ) )
		self.previousAdrenaline = self.adrenaline;
	else
		self.previousAdrenaline = 0;
	
	self.adrenaline = value;
	
	self setClientDvar( "ui_adrenaline", self.adrenaline );
	
	self updateStreakCount();
}

pc_watchStreakUse() // self == player
{
	self endon ( "death" );
	self endon ( "disconnect" );
	level endon ( "game_ended" );

	self.actionSlotEnabled = [];
	self.actionSlotEnabled[ KILLSTREAK_GIMME_SLOT ] = true;
	self.actionSlotEnabled[ KILLSTREAK_SLOT_1 ] = true;
	self.actionSlotEnabled[ KILLSTREAK_SLOT_2 ] = true;
	self.actionSlotEnabled[ KILLSTREAK_SLOT_3 ] = true;

	while( true )
	{
		result = self waittill_any_return( "streakUsed1", "streakUsed2", "streakUsed3", "streakUsed4" );
		
		if( self is_player_gamepad_enabled() )
			continue;

		if( !IsDefined( result ) )
			continue;

		// specialist can only use the gimme slot
		if( self.streakType == "specialist" && result != "streakUsed1" )
			continue;

		// don't let the killstreakIndexWeapon change while we are at none weapon because that could mean we're carrying something like sentry or ims
		if( IsDefined( self.changingWeapon ) && self.changingWeapon == "none" )
			continue;

		switch( result )
		{
		case "streakUsed1":
			if( self.pers["killstreaks"][ KILLSTREAK_GIMME_SLOT ].available && self.actionSlotEnabled[ KILLSTREAK_GIMME_SLOT ] )
				self.killstreakIndexWeapon = KILLSTREAK_GIMME_SLOT;
			break;
		case "streakUsed2":
			if( self.pers["killstreaks"][ KILLSTREAK_SLOT_1 ].available && self.actionSlotEnabled[ KILLSTREAK_SLOT_1 ] )
				self.killstreakIndexWeapon = KILLSTREAK_SLOT_1;
			break;
		case "streakUsed3":
			if( self.pers["killstreaks"][ KILLSTREAK_SLOT_2 ].available && self.actionSlotEnabled[ KILLSTREAK_SLOT_2 ] )
				self.killstreakIndexWeapon = KILLSTREAK_SLOT_2;
			break;
		case "streakUsed4":
			if( self.pers["killstreaks"][ KILLSTREAK_SLOT_3 ].available && self.actionSlotEnabled[ KILLSTREAK_SLOT_3 ] )
				self.killstreakIndexWeapon = KILLSTREAK_SLOT_3;
			break;
		}

		// just a sanity check to make sure we reset the killstreakIndexWeapon
		if( IsDefined( self.killstreakIndexWeapon ) && !self.pers["killstreaks"][ self.killstreakIndexWeapon ].available )
			self.killstreakIndexWeapon = undefined;

		if( IsDefined( self.killstreakIndexWeapon ) )
		{
			self disableKillstreakActionSlots();
			while( true )
			{
				self waittill( "weapon_change", newWeapon );
				if( IsDefined( self.killstreakIndexWeapon ) )
				{
					killstreakWeapon = getKillstreakWeapon( self.pers["killstreaks"][ self.killstreakIndexWeapon ].streakName );
					// if this is the killstreak weapon or none then continue and wait for the next weapon change
					//	remote uav gives you a different weapon than the killstreak weapon from the killstreaktable.csv, so we need to also check for that
					if( newWeapon == killstreakWeapon || 
						newWeapon == "none" || 
						( killstreakWeapon == "killstreak_uav_mp" && newWeapon == "killstreak_remote_uav_mp" ) ||
						( killstreakWeapon == "killstreak_uav_mp" && newWeapon == "uav_remote_mp" ) )
						continue;

					break;
				}
				
				break;
			}
			// they either used the killstreak or cancelled it
			self enableKillstreakActionSlots();
			self.killstreakIndexWeapon = undefined;
		}
	}
}

disableKillstreakActionSlots() // self == player
{
	for( i = KILLSTREAK_GIMME_SLOT; i < KILLSTREAK_SLOT_3 + 1; i++ )
	{
		if( !IsDefined( self.killstreakIndexWeapon ) )
			break;

		if( self.killstreakIndexWeapon == i )
			continue;

		// clear all other killstreak slots while we are using a killstreak so they can't try to use another one
		self _setActionSlot( i + 4, "" );
		self.actionSlotEnabled[ i ] = false;
	}
}

enableKillstreakActionSlots() // self == player
{
	for( i = KILLSTREAK_GIMME_SLOT; i < KILLSTREAK_SLOT_3 + 1; i++ )
	{
		// turn all of the action slots back on
		if( self.pers["killstreaks"][ i ].available )
		{
			killstreakWeapon = getKillstreakWeapon( self.pers["killstreaks"][ i ].streakName );
			self _setActionSlot( i + 4, "weapon", killstreakWeapon );
		}
		else
		{
			// since this killstreak isn't available, clear the action slot so they can't pull an empty weapon out
			self _setActionSlot( i + 4, "" );
		}

		// even if they don't have a killstreak in this slot we need to switch this flag for later uses
		//	if we don't, then once they earn it they won't be able to use it because this flag is off
		self.actionSlotEnabled[ i ] = true;
	}
}

killstreakHit( attacker, weapon, vehicle )
{
	if( IsDefined( weapon ) && isPlayer( attacker ) && IsDefined( vehicle.owner ) && IsDefined( vehicle.owner.team ) )
	{
		if ( ( (level.teamBased && vehicle.owner.team != attacker.team) || !level.teamBased ) && attacker != vehicle.owner )
		{
			if( isKillstreakWeapon( weapon ) )
				return;
				
			if ( !isDefined( attacker.lastHitTime[ weapon ] ) )
				attacker.lastHitTime[ weapon ] = 0;
		
			// already hit with this weapon on this frame
			if ( attacker.lastHitTime[ weapon ] == getTime() )
				return;

			attacker.lastHitTime[ weapon ] = getTime();
			
			attacker thread maps\mp\gametypes\_gamelogic::threadedSetWeaponStatByName( weapon, 1, "hits" );
				
			totalShots = attacker maps\mp\gametypes\_persistence::statGetBuffered( "totalShots" );		
			hits = attacker maps\mp\gametypes\_persistence::statGetBuffered( "hits" ) + 1;

			if ( hits <= totalShots )
			{
				attacker maps\mp\gametypes\_persistence::statSetBuffered( "hits", hits );
				attacker maps\mp\gametypes\_persistence::statSetBuffered( "misses", int(totalShots - hits) );
				attacker maps\mp\gametypes\_persistence::statSetBuffered( "accuracy", int(hits * 10000 / totalShots) );
			}
		}
	}
}

copy_killstreak_status( from, noTransfer )
{
	self.streakType = from.streakType;
	self.pers[ "cur_kill_streak" ] = from.pers[ "cur_kill_streak" ];
	//self setPlayerStat( "killstreak", from getPlayerStat( "killstreak" ) );
	self maps\mp\gametypes\_persistence::statSetChild( "round", "killStreak", self.pers[ "cur_kill_streak" ] );

	self.pers["killstreaks"] = from.pers["killstreaks"];
	self.killstreaks = from.killstreaks;

	if ( !IsDefined( noTransfer ) || noTransfer == false )
	{
		//this is pretty ugly and possibly quite unsafe, but the owner of a killstreak needs to change
		allEntities = GetEntArray();
		foreach( ent in allEntities )
		{
			if ( !IsDefined( ent ) || IsPlayer( ent ) )//don't transfer ownership of clients, this is just for owned objects in the world, not leadership transfer
				continue;
			
			if ( IsDefined( ent.owner ) && ent.owner == from )
			{
				if ( ent.classname == "misc_turret" )
					ent maps\mp\killstreaks\_autosentry::sentry_setOwner( self );
				else
					ent.owner = self;
			}
		}
	}
	
	self.adrenaline = undefined;
	self setAdrenaline( from.adrenaline );
	self resetStreakCount();
	self updateStreakCount();

	if ( IsDefined( noTransfer ) && noTransfer == true && IsDefined( self.killstreaks ) )
	{//just copying the info, need to update our HUD
		//update the icons
		index = 1;
		foreach ( streakName in self.killstreaks )
		{
			killstreakIndexName = self.pers["killstreaks"][index].streakName;
			// if specialist then we need to check to see if they have the pro version of the perk and get that icon
			if( self.streakType == "specialist" )
			{
				perkTokens = StrTok( self.pers["killstreaks"][index].streakName, "_" );
				if( perkTokens[ perkTokens.size - 1 ] == "ks" )
				{
					perkName = undefined;
					foreach( token in perkTokens )
					{
						if( token != "ks" )
						{
							if( !IsDefined( perkName ) )
								perkName = token;
							else
								perkName += ( "_" + token );
						}
					}
	
					// blastshield has an _ at the beginning
					if( isStrStart( self.pers["killstreaks"][index].streakName, "_" ) )
						perkName = "_" + perkName;
	
					if( IsDefined( perkName ) && self maps\mp\gametypes\_class::getPerkUpgrade( perkName ) != "specialty_null" )
						killstreakIndexName = self.pers["killstreaks"][index].streakName + "_pro";
				}
			}
	
			self setCommonPlayerData( "killstreaksState", "icons", index, getKillstreakIndex( killstreakIndexName ) );
			index++;	
		}
	}

	self updateStreakSlots();

	//copy over perks	
	foreach( perkName in from.perksPerkName )
	{
		//FIXME: this will restart a perk's threads - timer, etc.  So all timed perks get reset to full length
		if ( !self _hasPerk( perkName ) )
		{
			useSlot = false;
			if ( IsDefined( self.perksUseSlot[ perkName ] ) )
				useSlot = self.perksUseSlot[ perkName ];
			self givePerk( perkName, useSlot, self.perksPerkPower[ perkName ] );
		}
		if ( !IsDefined( noTransfer ) || noTransfer == false )
		{//stop & remove perks from other guy
			from _unsetPerk( perkName );
		}
	}
}

copy_adrenaline( from )
{
	self.adrenaline = undefined;
	self setAdrenaline( from.adrenaline );
	self resetStreakCount();
	self updateStreakCount();
	self updateStreakSlots();
}

is_using_killstreak()
{
	curWeap = self GetCurrentWeapon();
	usingKS = IsSubStr( curWeap, "killstreak" ) || (IsDefined(self.selectingLocation) && self.selectingLocation == true) || !(self isWeaponEnabled()) && !(self maps\mp\gametypes\_damage::attackerInRemoteKillstreak());
	return usingKS;
}

monitorDisownKillstreaks()
{
	while(IsDefined(self))
	{
		if ( bot_is_fireteam_mode() )
		{
			self waittill( "disconnect" );
		}
		else
		{
			self waittill_any( "disconnect", "joined_team", "joined_spectators" );
		}
		self notify( "killstreak_disowned" );
	}
}

PROJECTILE_TRACE_OBSTRUCTED_THRESHOLD = 0.99;	// this allows us to reject cases where we only see a tiny part of the target point
PROJECTILE_TRACE_YAW_ANGLE_INCREMENT = 30;

// should I allow user to specify flight distance or height?
/* 
============= 
///ScriptDocBegin
"Name: findUnobstructedFiringPointAroundZ( <player>, <targetPosition>, <flightDistance>, <angleOfAttack> )"
"Summary: Find a suitible flight path for a projectile around the +Z axis. Starts from behind the player and sweeps around in a circle in 30 degree increments. Returns undefined if all paths are blocked. Useful for tall narrow spaces."
"Module: Killstreaks"
"MandatoryArg: <player> : The player whose POV we'll use as a reference"
"MandatoryArg: <targetPosition> : The position to aim at."
"MandatoryArg: <flightDistance> : # of units for the projectile to travel. Very large values may collide with the skybox."
"MandatoryArg: <angleOfAttack> : The angle from +Z axis"
"Example: findUnobstructedFiringPointAroundZ( player, designatorEntity.origin, 10000, 30 )
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
findUnobstructedFiringPointAroundZ( player, targetPosition, flightDistance, angleOfAttack  )	// self == player
{
	initialVector = RotateVector( (0, 0, 1), (-1 * angleOfAttack, 0, 0) );
	
	anglesToPlayer = VectorToAngles( targetPosition - player.origin );
	for ( deltaAngle = 0; deltaAngle < 360; deltaAngle += PROJECTILE_TRACE_YAW_ANGLE_INCREMENT )
	{
		// want to start from behind the target
		approachVector = flightDistance * RotateVector( initialVector, (0,  deltaAngle + anglesToPlayer[1], 0 ) );
		startPosition = targetPosition + approachVector;
		
		// if ( deltaAngle == 0 )
		//	player thread drawLine( startPosition, targetPosition, 20, (0, 0, 1) );
				
		if ( _findUnobstructedFiringPointHelper( player, startPosition, targetPosition ) )
		{
			return startPosition;
		}
	}
	
	return undefined;
}

/* 
============= 
///ScriptDocBegin
"Name: findUnobstructedFiringPointAroundY( <player>, <targetPosition>, <flightDistance>, <minPitch>, <maxPitch>, <angleStep> )"
"Summary: Find a suitible flight path for a projectile behind the player. Starts high and lowers angle of attack. Useful for getting into doorways and windows. Returns undefined if all paths blocked.
"Module: Killstreaks"
"MandatoryArg: <player> : The player whose POV we'll use as a reference"
"MandatoryArg: <targetPosition> : The position to aim at."
"MandatoryArg: <flightDistance> : # of units for the projectile to travel. Very large values may collide with the skybox."
"MandatoryArg: <minPitch> : shallowest pitch angle (0 = parallel to ground)
"MandatoryArg: <maxPitch> : steepest ptich angle (90 = straight up)
"MandatoryArg: <angleStep> : # of degrees to step from max to min pitch
"Example: findUnobstructedFiringPointAroundZ( player, designatorEntity.origin, 10000, 15, 75, 15 )
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
findUnobstructedFiringPointAroundY( player, targetPosition, flightDistance, minPitch, maxPitch, angleStep )
{
	anglesToPlayer = VectorToAngles( player.origin - targetPosition );
	
	for ( deltaAngle = minPitch; deltaAngle <= maxPitch; deltaAngle += angleStep )
	{
		// since we're starting with the front vector, keep pitching up (so the firing angle becomes shallower)
		initialVector = RotateVector( (1, 0, 0), ( deltaAngle - 90, 0, 0 ) );
		// not sure why, but can't yaw the vector towards the player before pitching
		// so we have to do two rotates per check
		approachVector = flightDistance * RotateVector( initialVector, (0, anglesToPlayer[1], 0) );
		startPosition = targetPosition + approachVector;
		
		//if ( deltaAngle == minPitch )
		//	player thread drawLine( startPosition, targetPosition, 20, (0, 0, 1) );
		
		if ( _findUnobstructedFiringPointHelper( player, startPosition, targetPosition ) )
		{
			return startPosition;
		}
	}
	
	return undefined;
}

_findUnobstructedFiringPointHelper( player, startPosition, targetPosition )
{
	traceResult = BulletTrace( startPosition, targetPosition, false );
		
	if ( traceResult[ "fraction" ] > PROJECTILE_TRACE_OBSTRUCTED_THRESHOLD )
	{
		//player thread drawLine( startPosition, targetPosition, 20, (0, 1, 0) );
		// player thread drawSphere( traceResult[ "position" ], 3, (0, 1, 0) );
		return true;
	}
	/*
	else
	{
		player thread drawLine( startPosition, targetPosition, 20, (1, 0, 0) );
	}
	*/
	
	return false;
}

/* 
============= 
///ScriptDocBegin
"Name: findUnobstructedFiringPoint( <player>, <targetPosition>, <flightDistance> )"
"Summary: Find a suitible flight path for a projectile to hit the target point. Will try to find a firing point high and behind the player."
"Module: Killstreaks"
"MandatoryArg: <player> : The player whose POV we'll use as a reference"
"MandatoryArg: <targetPosition> : The position to aim at."
"MandatoryArg: <flightDistance> : # of units for the projectile to travel. Very large values may collide with the skybox."
"Example: findUnobstructedFiringPointAroundZ( player, designatorEntity.origin, 10000 )
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
findUnobstructedFiringPoint( player, targetPosition, flightDistance )
{
	result = findUnobstructedFiringPointAroundZ( player, targetPosition, flightDistance, 30 );
	
	if ( !IsDefined( result ) )
	{
		result = findUnobstructedFiringPointAroundY( player, targetPosition, flightDistance, 15, 75, 15 );
	}
	
	return result;
}
