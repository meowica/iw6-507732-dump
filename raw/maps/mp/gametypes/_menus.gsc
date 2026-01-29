#include maps\mp\_utility;

init()
{
	if ( !isDefined( game["gamestarted"] ) )
	{
		game["menu_team"] = "team_marinesopfor";
		if( level.multiTeamBased )
		{
			game["menu_team"] = "team_mt_options";
		}

		if ( bot_is_fireteam_mode() )
		{
			//Use a different pause menu that lets you spectate, do substitutions and pick your tactics
			//note: this works because this .gsc is initialized *after* the menu.gsc.  If that changes, this will stop working
			level.fireteam_menu = "class_commander_"+level.gametype;
			game["menu_class"] = level.fireteam_menu;
			game["menu_class_allies"] = level.fireteam_menu;//+team?
			game["menu_class_axis"] = level.fireteam_menu;//+team?
		}
		else
		{
			game["menu_class"] = "class";
			game["menu_class_allies"] = "class_marines";
			game["menu_class_axis"] = "class_opfor";
		}

		game["menu_changeclass_allies"] = "changeclass_marines";
		game["menu_changeclass_axis"] = "changeclass_opfor";

		//give multi team teams the "allies" menus for this
		if( level.multiTeamBased )
		{
			for( i = 0; i < level.teamNameList.size; i++ )
			{
				str_menu_class = "menu_class_" + level.teamNameList[i];
				str_menu_changeclass = "menu_changeclass_" + level.teamNameList[i];
				game[str_menu_class] = game["menu_class_allies"];
				game[str_menu_changeclass] = "changeclass_marines";
			}
		}

		game["menu_changeclass"] = "changeclass";

		if ( level.console )
		{
			game["menu_controls"] = "ingame_controls";

			if ( level.splitscreen )
			{
				if( level.multiTeamBased )
				{
					for( i = 0; i < level.teamNameList.size; i++ )
					{
						str_menu_class = "menu_class_" + level.teamNameList[i];
						str_menu_changeclass = "menu_changeclass_" + level.teamNameList[i];
						game[str_menu_class] += "_splitscreen";
						game[str_menu_changeclass] += "_splitscreen";
					}
				}
				
				game["menu_team"] += "_splitscreen";
				game["menu_class_allies"] += "_splitscreen";
				game["menu_class_axis"] += "_splitscreen";
				game["menu_changeclass_allies"] += "_splitscreen";
				game["menu_changeclass_axis"] += "_splitscreen";
				game["menu_controls"] += "_splitscreen";
			
				game["menu_changeclass_defaults_splitscreen"] = "changeclass_splitscreen_defaults";
				game["menu_changeclass_custom_splitscreen"] = "changeclass_splitscreen_custom";

				precacheMenu(game["menu_changeclass_defaults_splitscreen"]);
				precacheMenu(game["menu_changeclass_custom_splitscreen"]);
			}

			precacheMenu(game["menu_controls"]);
		}

		precacheMenu(game["menu_team"]);
		precacheMenu(game["menu_class_allies"]);
		precacheMenu(game["menu_class_axis"]);
		precacheMenu(game["menu_changeclass"]);
		precacheMenu(game["menu_changeclass_allies"]);
		precacheMenu(game["menu_changeclass_axis"]);

		PrecacheMenu( game["menu_class"] );

		precacheString( &"MP_HOST_ENDED_GAME" );
		precacheString( &"MP_HOST_ENDGAME_RESPONSE" );
	}

	level thread onPlayerConnect();
}

onPlayerConnect()
{
	for(;;)
	{
		level waittill("connected", player);
		
		player thread watchForClassChange();
		player thread watchForTeamChange();
		player thread watchForLeaveGame();
		player thread connectedMenus();
	}
}

connectedMenus()
{
	println("do stuff");
}

//CLASS CHANGE HANDLERS
watchForClassChange()
{
	
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	for ( ;; )
	{
		self waittill( "luinotifyserver", channel, newClass );
		
		if ( channel != "class_select" )
			continue;
		
		//used for blocking wait for class selection on team change
		if ( isDefined( self.waitingToSelectClass ) && self.waitingToSelectClass )
			continue;
		
		if( !self allowClassChoice() )
			continue;
		
		//JHIRSH TODO wrap the testclient stuff for dev only 
		if ( ( "" + newClass ) != "callback" )
		{
			//adding one to go from zero base index to 1 base index
			if ( isDefined( self.pers["isBot"] ) && self.pers["isBot"] )
			{
				self.pers["class"] = newClass;
				self.class = newClass;
			}
			else
			{
				newClassChoice = newClass + 1;
				newClassChoice = "custom" + newClassChoice; 
				
				if ( !isDefined( self.pers["class"] ) || newClassChoice == self.pers["class"] )
					continue;
			
				self.pers["class"] = newClassChoice;
				self.class = newClassChoice;
				
				
				//FOR EARLY MATCH
				if ( level.inGracePeriod && !self.hasDoneCombat ) // used weapons check?
				{
					self maps\mp\gametypes\_class::setClass( self.pers["class"] );
					self.tag_stowed_back = undefined;
					self.tag_stowed_hip = undefined;
					self maps\mp\gametypes\_class::giveLoadout( self.pers["team"], self.pers["class"] );
				}
				else
				{
					self iPrintLnBold( game["strings"]["change_class"] );
				}
			}
		}
		else
		{
			menuClass( "callback" );
		}		
	}
}

//LEAVE GAME HANDLER
watchForLeaveGame()
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	for ( ;; )
	{
		self waittill( "luinotifyserver", channel, val );
		
		if ( channel != "end_game" )
			continue;
		
		level thread maps\mp\gametypes\_gamelogic::forceEnd();
	}
}

//TEAM CHANGE HANDLERS
watchForTeamChange()
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	//------------------
	// 0 = axis
	// 1 = allies
	// 2 = auto
	// 3 = spectate
	//------------------
	
	for ( ;; )
	{
		self waittill( "luinotifyserver", channel, teamSelected );
		
		if ( channel != "team_select" )
			continue;
		
		if ( matchMakingGame() )
			continue;
		
		if ( teamSelected == 0 )
			teamSelected = "axis";
		else if ( teamSelected == 1 )
			teamSelected = "allies";
		else if ( teamSelected == 2 )
			teamSelected = "random";
		else
			teamSelected = "spectator";
		
		if ( isDefined( self.pers["team"] ) && teamSelected == self.pers["team"] )
		    continue;
	
		if( teamSelected == "axis" )
		{
			self thread setTeam( "axis" );
		}
		else if( teamSelected == "allies" )
		{
			self thread setTeam( "allies" );
		}
		else if ( teamSelected == "random" )
		{
			self thread autoAssign();
		}
		else if ( teamSelected == "spectator" )
		{
			self thread setSpectator();
		}
	}
}

autoAssign()
{
	if ( GetDvar( "g_gametype" ) == "aliens" )
	{
		self thread setTeam( "allies" );
		return;		
	}
	
	if ( !isDefined( self.team ) )
	{
		if ( level.teamcount["axis"] < level.teamcount["allies"] )
		{
			self thread setTeam( "axis" );
		}
		else if ( level.teamcount["allies"] < level.teamcount["axis"] )
		{
			self thread setTeam( "allies" );				
		}
		else
		{
			if ( GetTeamScore("allies" ) > GetTeamScore("axis" ) )
				self thread setTeam( "axis" );
			else 
				self thread setTeam( "allies" );	
		}
		return;
	}
	
	if ( level.teamcount["axis"] < level.teamcount["allies"] && self.team != "axis" )
	{
		self thread setTeam( "axis" );
	}
	else if ( level.teamcount["allies"] < level.teamcount["axis"] && self.team != "allies" )
	{
		self thread setTeam( "allies" );				
	}
	else if( level.teamcount["allies"] == level.teamcount["axis"] )
	{
		if ( GetTeamScore("allies" ) > GetTeamScore("axis" ) && self.team != "axis" )
			self thread setTeam( "axis" );
		else if ( self.team != "allies" )
			self thread setTeam( "allies" );	
	}
}

setTeam( selection )
{
	self endon( "disconnect" );
	
	if( level.teamBased && !maps\mp\gametypes\_teams::getJoinTeamPermissions( selection ) )
	{
		return;
		/# println( "cant change teams here... would be good to handle this logic in menu" ); #/
	}
	
	// allow respawn when switching teams during grace period.
	if ( level.inGracePeriod && !self.hasDoneCombat )
		self.hasSpawned = false;
		
	if( self.sessionstate == "playing" )
	{
		self.switching_teams = true;
		self.joining_team = selection;
		self.leaving_team = self.pers["team"];
	}
	
	self addToTeam( selection );
	
	if( self.sessionstate == "playing" )
		self suicide();
	
	//this is a blocking call waiting for the player to select a class
	//menu flow logic handled by menus
	self waitForClassSelect();
	
	if( self.sessionstate == "spectator" )
	{
		if ( game["state"] == "postgame" )
			return;

		if ( game["state"] == "playing" && !isInKillcam() )
			self thread maps\mp\gametypes\_playerlogic::spawnClient();
	
		self thread maps\mp\gametypes\_spectating::setSpectatePermissions();
	}
	
	self notify( "okToSpawn" );
	self notify("end_respawn");
}

setSpectator()
{
	if( isDefined( self.pers["team"] ) && self.pers["team"] == "spectator" )
		return;

	if( isAlive( self ) )
	{
		assert( isDefined( self.pers["team"] ) );
		self.switching_teams = true;
		self.joining_team = "spectator";
		self.leaving_team = self.pers["team"];
		self suicide();
	}

	self addToTeam( "spectator" );
	self.pers["class"] = undefined;
	self.class = undefined;

	self thread maps\mp\gametypes\_playerlogic::spawnSpectator();
}

//this is a blocking call
waitForClassSelect()
{
	//adding one to go from zero base index to 1 base index
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	self.waitingToSelectClass = true;
	
	for ( ;; )
	{
		
		if ( allowClassChoice() )
		{
			self waittill( "luinotifyserver", channel, newClass );
		}
		else
		{
			bypassClassChoice();
			break;
		}
		
		if ( channel != "class_select" )
			continue;
		
		//JHIRSH TODO wrap the testclient stuff for dev only 
		if ( ( "" + newClass ) != "callback" )
		{
			if ( isDefined( self.pers["isBot"] ) && self.pers["isBot"] )
			{
				self.pers["class"] = newClass;
				self.class = newClass;
			}
			else
			{
				classSelection = newClass+1;
				self.pers["class"] = "custom"+ classSelection;
				self.class = "custom"+classSelection;
			}
			
			self.waitingToSelectClass = false;
		}
		else
		{
			self.waitingToSelectClass = false;	// menuClass actually will attempt to spawn the client, so need to set this first
			menuClass( "callback" );
		}
		break;
	}
}

/*
isOptionsMenu( menu )
{
	if ( menu == game["menu_changeclass"] )
		return true;

	if ( menu == game["menu_team"] )
		return true;

	if ( level.console )
	{
		if ( menu == game["menu_controls"] )
			return true;
	}
	else
	{
		if ( isSubStr( menu, "pc_options" ) )
			return true;
	}

	return false;
}
*/


/*
onMenuResponse()
{
	self endon("disconnect");
	
	for(;;)
	{
		self waittill( "menuresponse", menu, response );
		
		if( response == "back" )
		{
			//dont let spectators back out of the menu_team screen if we arent allowed to be spectators
			if ( ( menu != game["menu_team"] ) || ( self.pers["team"] != "spectator" ) || ( maps\mp\gametypes\_tweakables::getTweakableValue( "game", "spectatetype" ) != 0  ) )
			{
				self closeMenus();

				if ( isOptionsMenu( menu ) )
				{
					if( menu == game[ "menu_changeclass" ] )
						self SetClientDvar( "ui_changeclass_menu_open", 0 );
					if( menu == game[ "menu_team" ] )
						self SetClientDvar( "ui_changeteam_menu_open", 0 );
					if( level.console )
					{
						if( menu == game[ "menu_controls" ] )
							self SetClientDvar( "ui_controls_menu_open", 0 );
					}
					else
					{
						if( isSubStr( menu, "pc_options" ) )
							self SetClientDvar( "ui_controls_menu_open", 0 );
					}

					if( self.pers["team"] == "allies" )
						self openpopupMenu( game["menu_class_allies"] );
					if( self.pers["team"] == "axis" )
						self openpopupMenu( game["menu_class_axis"] );
				}
				else if( menu == "-1" ) // no idea why
				{
					self SetClientDvar( "ui_class_menu_open", 0 );
					self SetClientDvar( "ui_changeclass_menu_open", 0 );
					self SetClientDvar( "ui_changeteam_menu_open", 0 );
					self SetClientDvar( "ui_controls_menu_open", 0 );
				}
			}
			continue;
		}
		
		if( response == "changeteam" )
		{
			self closepopupMenu();
			self closeInGameMenu();
			self openpopupMenu( game[ "menu_team" ] );
			self SetClientDvar( "ui_changeteam_menu_open", 1 );
		}
	
		if( response == "changeclass_marines" )
		{
			self closepopupMenu();
			self closeInGameMenu();
			self openpopupMenu( game[ "menu_changeclass_allies" ] );
			self SetClientDvar( "ui_changeclass_menu_open", 1 );
			continue;
		}

		if( response == "changeclass_opfor" )
		{
			self closepopupMenu();
			self closeInGameMenu();
			self openpopupMenu( game[ "menu_changeclass_axis" ] );
			self SetClientDvar( "ui_changeclass_menu_open", 1 );
			continue;
		}

		if( response == "changeclass_marines_splitscreen" )
		{
			self openpopupMenu( "changeclass_marines_splitscreen" );
			self SetClientDvar( "ui_changeclass_menu_open", 1 );
		}

		if( response == "changeclass_opfor_splitscreen" )
		{
			self openpopupMenu( "changeclass_opfor_splitscreen" );
			self SetClientDvar( "ui_changeclass_menu_open", 1 );
		}
		
		if(response == "endgame")
		{
			if(level.splitscreen)
			{
				endparty();

				if ( !level.gameEnded )
				{
					level thread maps\mp\gametypes\_gamelogic::forceEnd();
				}
			}
				
			continue;
		}

		if ( response == "endround" )
		{
			if ( !level.gameEnded )
			{
				level thread maps\mp\gametypes\_gamelogic::forceEnd();
			}
			else
			{
				self closepopupMenu();
				self closeInGameMenu();
				self iprintln( &"MP_HOST_ENDGAME_RESPONSE" );
			}			
			continue;
		}

		if( menu == game[ "menu_team" ] )
		{
			switch(response)
			{
			case "autoassign":
				self [[level.autoassign]]();
				break;

			case "spectator":
				self [[level.spectator]]();
				break;
			
			default:
				self [[level.onTeamSelection]]( response );
			}

			self SetClientDvar( "ui_changeteam_menu_open", 0 );
			self SetClientDvar( "ui_changeclass_menu_open", 1 );
		}	// the only responses remain are change class events
		else if ( menu == game["menu_changeclass"] ||
				( isDefined( game["menu_changeclass_defaults_splitscreen"] ) && menu == game["menu_changeclass_defaults_splitscreen"] ) ||
				( isDefined( game["menu_changeclass_custom_splitscreen"] ) && menu == game["menu_changeclass_custom_splitscreen"] ) )
		{
			self closepopupMenu();
			self closeInGameMenu();

			self SetClientDvar( "ui_changeclass_menu_open", 0 );

			self.selectedClass = true;
			self [[level.class]](response);
		}

		// Removed, not currently in-use
		//else if ( !level.console )
		//{
		//	if(menu == game["menu_quickcommands"])
		//		maps\mp\gametypes\_quickmessages::quickcommands(response);
		//	else if(menu == game["menu_quickstatements"])
		//		maps\mp\gametypes\_quickmessages::quickstatements(response);
		//	else if(menu == game["menu_quickresponses"])
		//		maps\mp\gametypes\_quickmessages::quickresponses(response);
		//}
		
	}
}
*/
/*
getTeamAssignment()
{
	teams[0] = "allies";
	teams[1] = "axis";
	
	if ( !level.teamBased )
		return teams[randomInt(2)];

	if ( isDefined( level.getTeamAssignment ) )
		return [[level.getTeamAssignment]]();
	
	if ( self.sessionteam != "none" && self.sessionteam != "spectator" && self.sessionstate != "playing" && self.sessionstate != "dead" )
	{
		assignment = self.sessionteam;
	}
	else if( level.multiTeamBased )
	{
		numTeams = level.teamNameList.size;
		
		//scan for smallest team, assign new player to that team
		teamAssignment = level.teamNameList[0];
		for( i = 0; i < level.teamNameList.size; i++ )
		{
			/#
			println( level.teamNameList[i] + " has " + level.teamCount[level.teamNameList[i]] + " players on it." );
			#/
			
			if ( level.teamCount[level.teamNameList[i]] < level.teamCount[teamAssignment] )
			{
				teamAssignment = level.teamNameList[i];
			}
		}
		return teamAssignment;
	}
	else
	{
		playerCounts = self maps\mp\gametypes\_teams::CountPlayers();
				
		// if teams are equal return the team with the lowest score
		if ( playerCounts["allies"] == playerCounts["axis"] )
		{
			if( getTeamScore( "allies" ) == getTeamScore( "axis" ) )
				assignment = teams[randomInt(2)];
			else if ( getTeamScore( "allies" ) < getTeamScore( "axis" ) )
				assignment = "allies";
			else
				assignment = "axis";
		}
		else if( playerCounts["allies"] < playerCounts["axis"] )
		{
			assignment = "allies";
		}
		else
		{
			assignment = "axis";
		}
	}
	
	return assignment;
}
*/
 
/*
menuAutoAssign()
{
	self closeMenus();

	assignment = getTeamAssignment();
		
	if ( isDefined( self.pers["team"] ) && (self.sessionstate == "playing" || self.sessionstate == "dead") )
	{		
		if ( assignment == self.pers["team"] )
		{
			self beginClassChoice();
			return;
		}
		else
		{
			self.switching_teams = true;
			self.joining_team = assignment;
			self.leaving_team = self.pers["team"];
			self suicide();
		}
	}	

	self addToTeam( assignment );
	self.pers["class"] = undefined;
	self.class = undefined;
	
	if ( !isAlive( self ) )
		self.statusicon = "hud_status_dead";
	
	self notify("end_respawn");
	
	self beginClassChoice();
}
*/

beginClassChoice( forceNewChoice )
{
	team = self.pers["team"];
	assert( team == "axis" || team == "allies" || IsSubStr( team, "team_" ));

	// menu_changeclass_team is the one where you choose one of the n classes to play as.
	// menu_class_team is where you can choose to change your team, class, controls, or leave game.
	
	//	if game mode allows class choice
	if ( allowClassChoice() )
		self openpopupMenu( game[ "menu_changeclass_" + team ] );
	else
		self thread bypassClassChoice();
	
	if ( !isAlive( self ) )
		self thread maps\mp\gametypes\_playerlogic::predictAboutToSpawnPlayerOverTime( 0.1 );
}


//	JHIRSH TODO: allow private matches to override class selection
bypassClassChoice()
{
	self.selectedClass = true;
	self.waitingToSelectClass = false;
	
	if ( IsDefined( level.bypassClassChoiceFunc ) )
	{
		class_choice = self [[level.bypassClassChoiceFunc]]();
		self.class = class_choice;
	}
	else
	{
		self.class = "class0";	
	}
}


beginTeamChoice()
{
	self setClientDvar( "ui_options_menu", 1 );
}


showMainMenuForTeam()
{
	assert( self.pers["team"] == "axis" || self.pers["team"] == "allies" );
	
	team = self.pers["team"];
	
	// menu_changeclass_team is the one where you choose one of the n classes to play as.
	// menu_class_team is where you can choose to change your team, class, controls, or leave game.	
	self openpopupMenu( game[ "menu_class_" + team ] );
}

onMenuTeamSelect( selection )
{
	if(self.pers["team"] != selection)
	{
		if( level.teamBased && !maps\mp\gametypes\_teams::getJoinTeamPermissions( selection ) )
		{
			self openpopupMenu(game["menu_team"]);
			return;
		}
		
		// allow respawn when switching teams during grace period.
		if ( level.inGracePeriod && !self.hasDoneCombat )
			self.hasSpawned = false;
			
		if(self.sessionstate == "playing")
		{
			self.switching_teams = true;
			self.joining_team = selection;
			self.leaving_team = self.pers["team"];
			self suicide();
		}
		
		self addToTeam( selection );
		self.pers["class"] = undefined;
		self.class = undefined;

		self notify("end_respawn");
	}
	
	self beginClassChoice();
}


menuAllies()
{
	if(self.pers["team"] != "allies")
	{
		if( level.teamBased && !maps\mp\gametypes\_teams::getJoinTeamPermissions( "allies" ) )
		{
			self openpopupMenu(game["menu_team"]);
			return;
		}
		
		// allow respawn when switching teams during grace period.
		if ( level.inGracePeriod && !self.hasDoneCombat )
			self.hasSpawned = false;
			
		if(self.sessionstate == "playing")
		{
			self.switching_teams = true;
			self.joining_team = "allies";
			self.leaving_team = self.pers["team"];
			self suicide();
		}

		self addToTeam( "allies" );
		self.pers["class"] = undefined;
		self.class = undefined;

		self notify("end_respawn");
	}
	
	self beginClassChoice();
}


menuAxis()
{
	if(self.pers["team"] != "axis")
	{
		if( level.teamBased && !maps\mp\gametypes\_teams::getJoinTeamPermissions( "axis" ) )
		{
			self openpopupMenu(game["menu_team"]);
			return;
		}

		// allow respawn when switching teams during grace period.
		if ( level.inGracePeriod && !self.hasDoneCombat )
			self.hasSpawned = false;

		if(self.sessionstate == "playing")
		{
			self.switching_teams = true;
			self.joining_team = "axis";
			self.leaving_team = self.pers["team"];
			self suicide();
		}

		self addToTeam( "axis" );
		self.pers["class"] = undefined;
		self.class = undefined;

		self notify("end_respawn");
	}
	
	self beginClassChoice();
}


menuSpectator()
{
	if( isDefined( self.pers["team"] ) && self.pers["team"] == "spectator" )
		return;

	if( isAlive( self ) )
	{
		assert( isDefined( self.pers["team"] ) );
		self.switching_teams = true;
		self.joining_team = "spectator";
		self.leaving_team = self.pers["team"];
		self suicide();
	}

	self addToTeam( "spectator" );
	self.pers["class"] = undefined;
	self.class = undefined;

	self thread maps\mp\gametypes\_playerlogic::spawnSpectator();
}


menuClass( response )
{
	// clear new status of unlocked classes
	if ( response == "demolitions_mp,0" && self getPlayerData( "featureNew", "demolitions" ) )
	{
		self setPlayerData( "featureNew", "demolitions", false );
	}
	if ( response == "sniper_mp,0" && self getPlayerData( "featureNew", "sniper" ) )
	{
		self setPlayerData( "featureNew", "sniper", false );
	}

	// this should probably be an assert... OK, so i made it an assert
	assert( isDefined( self.pers["team"] ));
	team = self.pers["team"];
	assert(team == "allies" || team == "axis" || IsSubStr( team, "team_" ));

	class = self maps\mp\gametypes\_class::getClassChoice( response );
	primary = self maps\mp\gametypes\_class::getWeaponChoice( response );

	if ( class == "restricted" )
	{
		self beginClassChoice();
		return;
	}

	if( (isDefined( self.pers["class"] ) && self.pers["class"] == class) && 
		(isDefined( self.pers["primary"] ) && self.pers["primary"] == primary) )
		return;

	if ( self.sessionstate == "playing" )
	{
		// if last class is already set then we don't want an undefined class to replace it
		if( IsDefined( self.pers["lastClass"] ) && IsDefined( self.pers["class"] ) )
		{
			self.pers["lastClass"] = self.pers["class"];
			self.lastClass = self.pers["lastClass"];
		}

		self.pers["class"] = class;
		self.class = class;
		self.pers["primary"] = primary;

		if ( game["state"] == "postgame" )
			return;

		if ( level.inGracePeriod && !self.hasDoneCombat ) // used weapons check?
		{
			self maps\mp\gametypes\_class::setClass( self.pers["class"] );
			self.tag_stowed_back = undefined;
			self.tag_stowed_hip = undefined;
			self maps\mp\gametypes\_class::giveLoadout( self.pers["team"], self.pers["class"] );
		}
		else
		{
			self iPrintLnBold( game["strings"]["change_class"] );
		}
	}
	else
	{
		// if last class is already set then we don't want an undefined class to replace it
		if( IsDefined( self.pers["lastClass"] ) && IsDefined( self.pers["class"] ) )
		{
			self.pers["lastClass"] = self.pers["class"];
			self.lastClass = self.pers["lastClass"];
		}

		self.pers["class"] = class;
		self.class = class;
		self.pers["primary"] = primary;

		if ( game["state"] == "postgame" )
			return;

		if ( game["state"] == "playing" && !isInKillcam() )
			self thread maps\mp\gametypes\_playerlogic::spawnClient();
	}

	self thread maps\mp\gametypes\_spectating::setSpectatePermissions();
}



addToTeam( team, firstConnect )
{
	// UTS update playerCount remove from team
	// this checks self.team because the only time we set it is below, so if a player has already been set up this removes them
	//	DO NOT check self.pers["team"] here because the removeFromTeamCount() function asserts if self.team isn't defined plus other checks
	if ( IsDefined( self.team ) )
		self maps\mp\gametypes\_playerlogic::removeFromTeamCount();
		
	self.pers["team"] = team;
	// this is the only place self.team should ever be set
	self.team = team;

	// session team is readonly in ranked matches on console
	if ( !matchMakingGame() || isDefined( self.pers["isBot"] ) || !allowTeamChoice() )
	{
		if ( level.teamBased )
		{
			self.sessionteam = team;
		}
		else
		{
			if ( team == "spectator" )
				self.sessionteam = "spectator";
			else
				self.sessionteam = "none";
		}
	}

	// UTS update playerCount add to team
	if ( game["state"] != "postgame" )
		self maps\mp\gametypes\_playerlogic::addToTeamCount();	

	self updateObjectiveText();

	// give "joined_team" and "joined_spectators" handlers a chance to start
	// these are generally triggered from the "connected" notify, which can happen on the same
	// frame as these notifies
	if ( isDefined( firstConnect ) && firstConnect )
		waittillframeend;

	self updateMainMenu();

	if ( team == "spectator" )
	{
		self notify( "joined_spectators" );
		level notify( "joined_team", self );
	}
	else
	{
		self notify( "joined_team" );
		level notify( "joined_team", self );
	}
}
