#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

init()
{
	level.killcam = maps\mp\gametypes\_tweakables::getTweakableValue( "game", "allowkillcam" );
}

killcam(
	attackerNum, // entity number of the attacker
	killcamentityindex, // entity number of the entity to view (grenade, airstrike, etc)
	killcamentitystarttime, // time at which the killcamentity came into being
	sWeapon, // killing weapon
	predelay, // time between player death and beginning of killcam
	offsetTime, // something to do with how far back in time the killer was seeing the world when he made the kill; latency related, sorta
	timeUntilRespawn, // will the player be allowed to respawn after the killcam?
	maxtime, // time remaining until map ends; the killcam will never last longer than this. undefined = no limit
	attacker, // entity object of attacker
	victim, // entity object of the victim
	sMeansOfDeath // the means of death
)
{
	// monitors killcam and hides HUD elements during killcam session
	//if ( !level.splitscreen )
	//	self thread killcam_HUD_off();
	
	self endon("disconnect");
	self endon("spawned");
	level endon("game_ended");
	
	if ( attackerNum < 0 || !IsDefined(attacker) )
		return;

	// length from killcam start to killcam end
	if (getdvar("scr_killcam_time") == "") {
		if ( sWeapon == "artillery_mp" || sWeapon == "stealth_bomb_mp" )
			camtime = (gettime() - killcamentitystarttime) / 1000 - predelay - .1;
		else if( sWeapon == "remote_mortar_missile_mp" )
			camtime = 6.5;
		else if ( level.showingFinalKillcam	|| sWeapon == "agent_mp" || sWeapon == "guard_dog_mp" )
			camtime = 4.0;
		else if ( sWeapon == "apache_minigun_mp" )
			camtime = 3.0;
		else if ( sWeapon == "javelin_mp" )
			camtime = 8;
		else if ( issubstr( sWeapon, "remotemissile_" ) )
			camtime = 5;
		else if ( !timeUntilRespawn || timeUntilRespawn > 5.0 ) // if we're not going to respawn, we can take more time to watch what happened
			camtime = 5.0;
		else if ( sWeapon == "frag_grenade_mp" || sWeapon == "frag_grenade_short_mp" || sWeapon == "semtex_mp" || sWeapon == "thermobaric_grenade_mp" || sWeapon == "mortar_shell__mp" )
			camtime = 4.25; // show long enough to see grenade thrown
		else
			camtime = 2.5;
	}
	else
		camtime = getdvarfloat("scr_killcam_time");

	if (isdefined(maxtime)) {
		if (camtime > maxtime)
			camtime = maxtime;
		if (camtime < .05)
			camtime = .05;
	}
	
	// time after player death that killcam continues for
	if (getdvar("scr_killcam_posttime") == "")
		postdelay = 2;
	else {
		postdelay = getdvarfloat("scr_killcam_posttime");
		if (postdelay < 0.05)
			postdelay = 0.05;
	}
	
	/* timeline:
	
	|        camtime       |      postdelay      |
	|                      |   predelay    |
	
	^ killcam start        ^ player death        ^ killcam end
	                                       ^ player starts watching killcam
	
	*/
	
	killcamlength = camtime + postdelay;
	
	// don't let the killcam last past the end of the round.
	if (isdefined(maxtime) && killcamlength > maxtime)
	{
		// first trim postdelay down to a minimum of 1 second.
		// if that doesn't make it short enough, trim camtime down to a minimum of 1 second.
		// if that's still not short enough, cancel the killcam.
		if ( maxtime < 2 )
			return;

		if (maxtime - camtime >= 1) {
			// reduce postdelay so killcam ends at end of match
			postdelay = maxtime - camtime;
		}
		else {
			// distribute remaining time over postdelay and camtime
			postdelay = 1;
			camtime = maxtime - 1;
		}
		
		// recalc killcamlength
		killcamlength = camtime + postdelay;
	}

	// LUA: we need to reset this dvar so the killcam will reset if we come in here for the final killcam while you're watching a killcam
	self SetClientOmnvar( "ui_killcam_end_milliseconds", 0 );
	// END LUA

	// LUA: we need to show attacker info in the lua killcam
	assert( IsGameParticipant( attacker ) );
	
	if( IsPlayer(attacker) )
		self SetClientOmnvar( "ui_killcam_killedby_id", attacker GetEntityNumber() );
	
	if ( isKillstreakWeapon( sWeapon ) )
	{
		killstreakRowIdx = getKillstreakRowNum( level.killstreakWeildWeapons[ sWeapon ] );
		self SetClientOmnvar( "ui_killcam_killedby_killstreak", killstreakRowIdx );
		self SetClientOmnvar( "ui_killcam_killedby_weapon", -1 );
		self SetClientOmnvar( "ui_killcam_killedby_attachment1", -1 );
		self SetClientOmnvar( "ui_killcam_killedby_attachment2", -1 );
		self SetClientOmnvar( "ui_killcam_killedby_attachment3", -1 );
	}
	else
	{
		attachments = [];
		
		weaponName = GetWeaponBaseName( sWeapon );
		if(IsDefined(weaponName))
		{
			if( sMeansOfDeath == "MOD_MELEE" && !maps\mp\gametypes\_weapons::isRiotShield( sWeapon ) )
				weaponName = "iw5_knifeonly";
			else
			{
				weaponName = strip_suffix( weaponName, "_mp" );
			}
			weaponRowIdx = TableLookupRowNum( "mp/statsTable.csv", 4, weaponName );
			self SetClientOmnvar( "ui_killcam_killedby_weapon", weaponRowIdx );
			self SetClientOmnvar( "ui_killcam_killedby_killstreak", -1 );
			
			if( weaponName != "iw5_knifeonly" )
				attachments = GetWeaponAttachments( sWeapon );
		}
		else
		{
			self SetClientOmnvar( "ui_killcam_killedby_weapon", -1 );
			self SetClientOmnvar( "ui_killcam_killedby_killstreak", -1 );
		}
		
		for( i = 0; i < 3; i++ )
		{
			if( IsDefined( attachments[ i ] ) )
			{
				attachmentRowIdx = TableLookupRowNum( "mp/attachmentTable.csv", 4, validateAttachment( attachments[ i ] ) );
				self SetClientOmnvar( "ui_killcam_killedby_attachment" + ( i + 1 ), attachmentRowIdx );
			}
			else
			{
				self SetClientOmnvar( "ui_killcam_killedby_attachment" + ( i + 1 ), -1 );
			}
		}
	}

	if ( timeUntilRespawn && !level.gameEnded || ( isDefined( self ) && isDefined(self.battleBuddy) && !level.gameEnded ) )
	{
		//setLowerMessage( "kc_info", &"PLATFORM_PRESS_TO_SKIP", undefined, undefined, undefined, undefined, undefined, undefined, true );
		self SetClientOmnvar( "ui_killcam_text", "skip" );
	}
	else if ( !level.gameEnded )
	{
		//setLowerMessage( "kc_info", &"PLATFORM_PRESS_TO_RESPAWN", undefined, undefined, undefined, undefined, undefined, undefined, true );
		self SetClientOmnvar( "ui_killcam_text", "respawn" );	
	}
	else
	{
		self SetClientOmnvar( "ui_killcam_text", "none" );	
	}
	// END LUA

	killcamoffset = camtime + predelay;
	
	startTime = getTime();
	self notify ( "begin_killcam", startTime );

	if ( !isAgent(attacker) && isDefined( attacker ) ) // attacker may have disconnected
		attacker visionsyncwithplayer( victim );
	
	self updateSessionState( "spectator" );
	self.spectatekillcam = true;
	
	if( IsAgent( attacker) )
		attackerNum =  victim GetEntityNumber();

	self.forcespectatorclient = attackerNum;
	self.killcamentity = -1;
	if ( killcamentityindex >= 0 )
	{
		self SetClientOmnvar( "killcam_scene", -1 );
		self thread setKillCamEntity( killcamentityindex, killcamoffset, killcamentitystarttime );
	}
	else
	{
		// make sure this index follows the scenes setup in "game/share/raw/mp/cinematic_camera/camera_scenes.txt"
		if ( level.showingFinalKillcam )
			self SetClientOmnvar( "killcam_scene", 1 );
		else
			self SetClientOmnvar( "killcam_scene", 0 );
	}
	self.archivetime = killcamoffset;
	self.killcamlength = killcamlength;
	self.psoffsettime = offsetTime;
	
	// ignore spectate permissions
	self allowSpectateTeam("allies", true);
	self allowSpectateTeam("axis", true);
	self allowSpectateTeam("freelook", true);
	self allowSpectateTeam("none", true);
	if( level.multiTeamBased )
	{
		foreach( teamname in level.teamNameList )
		{
			self allowSpectateTeam( teamname, true );
		}
	}

	self thread endedKillcamCleanup();

	// wait till the next server frame to allow code a chance to update archivetime if it needs trimming
	wait 0.05;	
	
	if( !isDefined( self ) )
		return;
	
	assertex( self.archivetime <= killcamoffset + 0.0001, "archivetime: " + self.archivetime + ", killcamoffset: " + killcamoffset );
	if ( self.archivetime < killcamoffset )
		println( "WARNING: Code trimmed killcam time by " + (killcamoffset - self.archivetime) + " seconds because it doesn't have enough game time recorded!" );
	
	camtime = self.archivetime - .05 - predelay;
	killcamlength = camtime + postdelay;
	self.killcamlength = killcamlength;

	if ( camtime <= 0 ) // if we're not looking back in time far enough to even see the death, cancel
	{
		println( "Cancelling killcam because we don't even have enough recorded to show the death." );
		
		self updateSessionState( "dead" );
		self ClearKillcamState();
		
		self notify ( "killcam_ended" );
		
		return;
	}
	
	// LUA: we need to show timer info in the lua killcam, this will tell the killcam to display and eveything else to hide
	self SetClientOmnvar( "ui_killcam_end_milliseconds", int( killcamlength * 1000 ) + GetTime() );
	// END LUA

	if ( level.showingFinalKillcam )
		thread doFinalKillCamFX( camtime );
	
	self.killcam = true;

	if ( isDefined( self.battleBuddy ) && !level.gameEnded )
	{
		self.battleBuddyRespawnTimeStamp = GetTime();
	}
	
	self thread spawnedKillcamCleanup();
	
	self.skippedKillCam = false;
	
	if ( !level.showingFinalKillcam )
		self thread waitSkipKillcamButton( timeUntilRespawn );
	else
		self notify ( "showing_final_killcam" );
	
	self thread endKillcamIfNothingToShow();
	
	self waittillKillcamOver();
	
	if ( level.showingFinalKillcam )
	{
		self thread maps\mp\gametypes\_playerlogic::spawnEndOfGame();
		return;
	}
	
	self thread calculateKillCamTime( startTime );
	
	self thread killcamCleanup( true );
}


doFinalKillCamFX( camTime )
{
	if ( isDefined( level.doingFinalKillcamFx ) )
		return;
	level.doingFinalKillcamFx = true;
	
	intoSlowMoTime = camTime;
	if ( intoSlowMoTime > 1.0 )
	{
		intoSlowMoTime = 1.0;
		wait( camTime - 1.0 );
	}
	
	setSlowMotion( 1.0, 0.25, intoSlowMoTime ); // start timescale, end timescale, lerp duration
	wait( intoSlowMoTime + .5 );
	setSlowMotion( 0.25, 1, 1.0 );
	
	level.doingFinalKillcamFx = undefined;
}


calculateKillCamTime( startTime )
{
	watchedTime = int(getTime() - startTime);
	self incPlayerStat( "killcamtimewatched", watchedTime );
}

waittillKillcamOver()
{
	self endon("abort_killcam");
	
	wait(self.killcamlength - 0.05);
}

setKillCamEntity( killcamentityindex, killcamoffset, starttime )
{
	self endon("disconnect");
	self endon("killcam_ended");
	
	killcamtime = (gettime() - killcamoffset * 1000);
	
	if ( starttime > killcamtime )
	{
		wait .05;
		// code may have trimmed archivetime after the first frame if we couldn't go back in time as far as requested.
		killcamoffset = self.archivetime;
		killcamtime = (gettime() - killcamoffset * 1000);
		
		if ( starttime > killcamtime )
			wait (starttime - killcamtime) / 1000;
	}
	self.killcamentity = killcamentityindex;
}

waitSkipKillcamButton( timeUntilRespawn )
{
	self endon("disconnect");
	self endon("killcam_ended");
	
	/*
	self NotifyOnPlayerCommand( "kc_respawn", "+usereload" );
	self waittill("kc_respawn");
	*/
	
	while(self useButtonPressed())
		wait .05;

	while(!(self useButtonPressed()))
		wait .05;
	
	self.skippedKillCam = true;
	
	if ( !matchMakingGame() )
		self incPlayerStat( "killcamskipped", 1 );

	if ( timeUntilRespawn <= 0 )
		clearLowerMessage( "kc_info" );
	
	self notify("abort_killcam");
}

endKillcamIfNothingToShow()
{
	self endon("disconnect");
	self endon("killcam_ended");
	
	while(1)
	{
		// code may trim our archivetime to zero if there is nothing "recorded" to show.
		// this can happen when the person we're watching in our killcam goes into killcam himself.
		// in this case, end the killcam.
		if ( self.archivetime <= 0 )
			break;
		wait .05;
	}
	
	self notify("abort_killcam");
}

spawnedKillcamCleanup()
{
	self endon("disconnect");
	self endon("killcam_ended");
	
	self waittill("spawned");
	self thread killcamCleanup( false );
}

endedKillcamCleanup()
{
	self endon("disconnect");
	self endon("killcam_ended");
	
	level waittill("game_ended");

	self thread killcamCleanup( true );
}

killcamCleanup( clearState )
{
	// LUA: we need to reset this dvar so the killcam will reset
	self SetClientOmnvar( "ui_killcam_end_milliseconds", 0 );
	// END LUA

	self.killcam = undefined;

	if ( !level.gameEnded )
		self clearLowerMessage( "kc_info" );
	
	self thread maps\mp\gametypes\_spectating::setSpectatePermissions();
	
	self notify("killcam_ended"); // do this last, in case this function was called from a thread ending on it

	if ( !clearState )
		return;
			
	self updateSessionState( "dead" );
	self ClearKillcamState();
}



cancelKillCamOnUse()
{
	self.cancelKillcam = false;
	self thread cancelKillCamOnUse_specificButton( ::cancelKillCamUseButton, ::cancelKillCamCallback );
	//self thread cancelKillCamOnUse_specificButton( ::cancelKillCamSafeSpawnButton, ::cancelKillCamSafeSpawnCallback );
}

cancelKillCamUseButton()
{
	return self useButtonPressed();
}
cancelKillCamSafeSpawnButton()
{
	return self fragButtonPressed();
}
cancelKillCamCallback()
{
	self.cancelKillcam = true;
}
cancelKillCamSafeSpawnCallback()
{
	self.cancelKillcam = true;
	self.wantSafeSpawn = true;
}

cancelKillCamOnUse_specificButton( pressingButtonFunc, finishedFunc )
{
	self endon ( "death_delay_finished" );
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	
	for ( ;; )
	{
		if ( !self [[pressingButtonFunc]]() )
		{
			wait ( 0.05 );
			continue;
		}
		
		buttonTime = 0;
		while( self [[pressingButtonFunc]]() )
		{
			buttonTime += 0.05;
			wait ( 0.05 );
		}
		
		if ( buttonTime >= 0.5 )
			continue;
		
		buttonTime = 0;
		
		while ( !self [[pressingButtonFunc]]() && buttonTime < 0.5 )
		{
			buttonTime += 0.05;
			wait ( 0.05 );
		}
		
		if ( buttonTime >= 0.5 )
			continue;
			
		self [[finishedFunc]]();
		return;
	}	
}