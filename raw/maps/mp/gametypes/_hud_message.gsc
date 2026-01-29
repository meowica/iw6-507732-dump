#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;

init()
{
	precacheString( &"MP_FIRSTPLACE_NAME" );
	precacheString( &"MP_SECONDPLACE_NAME" );
	precacheString( &"MP_THIRDPLACE_NAME" );
	precacheString( &"MP_MATCH_BONUS_IS" );

	precacheMenu( "perk_display" );
	precacheMenu( "perk_hide" );
	//precacheMenu( "killedby_card_display" );
	precacheMenu( "killedby_card_hide" );
	precacheMenu( "youkilled_card_display" );

	game["menu_endgameupdate"] = "endgameupdate";
	if ( level.splitscreen )
		game["menu_endgameupdate"] += "_splitscreen";
	precacheMenu(game["menu_endgameupdate"]);

	game["strings"]["draw"] = &"MP_DRAW";
	game["strings"]["round_draw"] = &"MP_ROUND_DRAW";
	game["strings"]["round_win"] = &"MP_ROUND_WIN";
	game["strings"]["round_loss"] = &"MP_ROUND_LOSS";
	game["strings"]["victory"] = &"MP_VICTORY";
	game["strings"]["defeat"] = &"MP_DEFEAT";
	game["strings"]["halftime"] = &"MP_HALFTIME";
	game["strings"]["overtime"] = &"MP_OVERTIME";
	game["strings"]["roundend"] = &"MP_ROUNDEND";
	game["strings"]["intermission"] = &"MP_INTERMISSION";
	game["strings"]["side_switch"] = &"MP_SWITCHING_SIDES";
	game["strings"]["match_bonus"] = &"MP_MATCH_BONUS_IS";
	
	level thread onPlayerConnect();
}


onPlayerConnect()
{
	for(;;)
	{
		level waittill( "connected", player );

		player thread hintMessageDeathThink();
		player thread lowerMessageThink();
		
		player thread initNotifyMessage();
	}
}


hintMessage( hintText )
{
	notifyData = spawnstruct();
	
	notifyData.notifyText = hintText;
	notifyData.glowColor = (0.3, 0.6, 0.3);
	
	notifyMessage( notifyData );
}


initNotifyMessage()
{
	if ( level.splitscreen || self isSplitscreenPlayer() )
	{
		titleSize = 1.5;
		textSize = 1.25;
		iconSize = 24;
		font = "default";
		point = "TOP";
		relativePoint = "BOTTOM";
		yOffset = 0;
		xOffset = 0;
	}
	else
	{
		titleSize = 2.5;
		textSize = 1.75;
		iconSize = 30;
		font = "objective";
		point = "TOP";
		relativePoint = "BOTTOM";
		yOffset = 50;
		xOffset = 0;
	}
	
	self.notifyTitle = createFontString( font, titleSize );
	self.notifyTitle setPoint( point, undefined, xOffset, yOffset );
	self.notifyTitle.glowColor = (0.2, 0.3, 0.7);
	self.notifyTitle.glowAlpha = 1;
	self.notifyTitle.hideWhenInMenu = true;
	self.notifyTitle.archived = false;
	self.notifyTitle.alpha = 0;

	self.notifyText = createFontString( font, textSize );
	self.notifyText setParent( self.notifyTitle );
	self.notifyText setPoint( point, relativePoint, 0, 0 );
	self.notifyText.glowColor = (0.2, 0.3, 0.7);
	self.notifyText.glowAlpha = 1;
	self.notifyText.hideWhenInMenu = true;
	self.notifyText.archived = false;
	self.notifyText.alpha = 0;

	self.notifyText2 = createFontString( font, textSize );
	self.notifyText2 setParent( self.notifyTitle );
	self.notifyText2 setPoint( point, relativePoint, 0, 0 );
	self.notifyText2.glowColor = (0.2, 0.3, 0.7);
	self.notifyText2.glowAlpha = 1;
	self.notifyText2.hideWhenInMenu = true;
	self.notifyText2.archived = false;
	self.notifyText2.alpha = 0;

	self.notifyIcon = createIcon( "white", iconSize, iconSize );
	self.notifyIcon setParent( self.notifyText2 );
	self.notifyIcon setPoint( point, relativePoint, 0, 0 );
	self.notifyIcon.hideWhenInMenu = true;
	self.notifyIcon.archived = false;
	self.notifyIcon.alpha = 0;

	self.notifyOverlay = createIcon( "white", iconSize, iconSize );
	self.notifyOverlay setParent( self.notifyIcon );
	self.notifyOverlay setPoint( "CENTER", "CENTER", 0, 0 );
	self.notifyOverlay.hideWhenInMenu = true;
	self.notifyOverlay.archived = false;
	self.notifyOverlay.alpha = 0;

	self.doingSplash = [];
	self.doingSplash[0] = undefined;
	self.doingSplash[1] = undefined;
	self.doingSplash[2] = undefined;
	self.doingSplash[3] = undefined;

	self.splashQueue = [];
	self.splashQueue[0] = [];
	self.splashQueue[1] = [];
	self.splashQueue[2] = [];
	self.splashQueue[3] = [];
}


oldNotifyMessage( titleText, notifyText, iconName, glowColor, sound, duration )
{
	notifyData = spawnstruct();
	
	notifyData.titleText = titleText;
	notifyData.notifyText = notifyText;
	notifyData.iconName = iconName;
	notifyData.glowColor = glowColor;
	notifyData.sound = sound;
	notifyData.duration = duration;
	
	notifyMessage( notifyData );
}


notifyMessage( notifyData )
{
	self endon ( "death" );
	self endon ( "disconnect" );
	
	if ( !IsDefined( notifyData.slot ) )
		notifyData.slot = 0;
	
	slot = notifyData.slot;

	if ( !IsDefined( notifyData.type ) )
		notifyData.type = "";
	
	if ( !IsDefined( self.doingSplash[ slot ] ) )
	{
		self thread showNotifyMessage( notifyData );
		return;
	}/*
	else if ( notifyData.type == "rank" && self.doingSplash[ slot ].type != "challenge_splash" && self.doingSplash[ slot ].type != "killstreak_splash" )
	{
		self thread showNotifyMessage( notifyData );
		return;
	}*/
	
	self.splashQueue[ slot ][ self.splashQueue[ slot ].size ] = notifyData;
}


dispatchNotify( slot )
{	
	nextNotifyData = self.splashQueue[ slot ][ 0 ];
		
	for ( i = 1; i < self.splashQueue[ slot ].size; i++ )
		self.splashQueue[ slot ][i-1] = self.splashQueue[ slot ][i];
	self.splashQueue[ slot ][i-1] = undefined;

	if ( IsDefined( nextNotifyData.name ) )
		actionNotify( nextNotifyData );
	else
		showNotifyMessage( nextNotifyData );
}


promotionSplashNotify()
{
	self endon ( "disconnect" );

	actionData = spawnStruct();
	
	splashRef = "promotion";
	actionData.name = splashRef;
	actionData.type = TableLookup( "mp/splashTable.csv", 0, splashRef, 11 );
	actionData.sound = TableLookup( "mp/splashTable.csv", 0, splashRef, 9 );
	actionData.slot = 0;

	self thread actionNotify( actionData );
}

weaponPromotionSplashNotify()
{
	self endon ( "disconnect" );

	actionData = spawnStruct();

	splashRef = "promotion_weapon";
	actionData.name = splashRef;
	actionData.type = TableLookup( "mp/splashTable.csv", 0, splashRef, 11 );
	actionData.sound = TableLookup( "mp/splashTable.csv", 0, splashRef, 9 );
	actionData.slot = 0;

	self thread actionNotify( actionData );
}

showNotifyMessage( notifyData )
{
	self endon("disconnect");

	assert( IsDefined( notifyData.slot ) );
	slot = notifyData.slot;

	if ( level.gameEnded )
	{
		if ( IsDefined( notifyData.type ) && notifyData.type == "rank" )
		{
			self setClientDvar( "ui_promotion", 1 );
			self.postGamePromotion = true;
		}
		
		if ( self.splashQueue[ slot ].size )
			self thread dispatchNotify( slot );

		return;
	}
	
	self.doingSplash[ slot ] = notifyData;

	waitRequireVisibility( 0 );

	if ( IsDefined( notifyData.duration ) )
		duration = notifyData.duration;
	else if ( level.gameEnded )
		duration = 2.0;
	else
		duration = 4.0;
	
	self thread resetOnCancel();

	if ( IsDefined( notifyData.sound ) )
		self PlayLocalSound( notifyData.sound );

	if ( IsDefined( notifyData.leaderSound ) )
		self leaderDialogOnPlayer( notifyData.leaderSound );
	
	if ( IsDefined( notifyData.glowColor ) )
		glowColor = notifyData.glowColor;
	else
		glowColor = (0.3, 0.6, 0.3);

	anchorElem = self.notifyTitle;

	if ( IsDefined( notifyData.titleText ) )
	{
		if ( IsDefined( notifyData.titleLabel ) )
			self.notifyTitle.label = notifyData.titleLabel;
		else
			self.notifyTitle.label = &"";

		if ( IsDefined( notifyData.titleLabel ) && !IsDefined( notifyData.titleIsString ) )
			self.notifyTitle setValue( notifyData.titleText );
		else
			self.notifyTitle setText( notifyData.titleText );
		self.notifyTitle setPulseFX( int(25*duration), int(duration*1000), 1000 );
		self.notifyTitle.glowColor = glowColor;	
		self.notifyTitle.alpha = 1;
	}

	if ( IsDefined( notifyData.textGlowColor ) )
		glowColor = notifyData.textGlowColor;

	if ( IsDefined( notifyData.notifyText ) )
	{
		if ( IsDefined( notifyData.textLabel ) )
			self.notifyText.label = notifyData.textLabel;
		else
			self.notifyText.label = &"";

		if ( IsDefined( notifyData.textLabel ) && !IsDefined( notifyData.textIsString ) )
			self.notifyText setValue( notifyData.notifyText );
		else
			self.notifyText setText( notifyData.notifyText );
		self.notifyText setPulseFX( 100, int(duration*1000), 1000 );
		self.notifyText.glowColor = glowColor;	
		self.notifyText.alpha = 1;
		anchorElem = self.notifyText;
	}

	if ( IsDefined( notifyData.notifyText2 ) )
	{
		self.notifyText2 setParent( anchorElem );
		
		if ( IsDefined( notifyData.text2Label ) )
			self.notifyText2.label = notifyData.text2Label;
		else
			self.notifyText2.label = &"";

		self.notifyText2 setText( notifyData.notifyText2 );
		self.notifyText2 setPulseFX( 100, int(duration*1000), 1000 );
		self.notifyText2.glowColor = glowColor;	
		self.notifyText2.alpha = 1;
		anchorElem = self.notifyText2;
	}

	if ( IsDefined( notifyData.iconName ) )
	{
		self.notifyIcon setParent( anchorElem );
		
		if( level.splitscreen || self isSplitscreenPlayer() )
			self.notifyIcon setShader( notifyData.iconName, 30, 30 );
		else
			self.notifyIcon setShader( notifyData.iconName, 60, 60 );
			
		self.notifyIcon.alpha = 0;

		if ( IsDefined( notifyData.iconOverlay ) )
		{
			self.notifyIcon fadeOverTime( 0.15 );
			self.notifyIcon.alpha = 1;

			//if ( !IsDefined( notifyData.overlayOffsetY ) )
				notifyData.overlayOffsetY = 0;

			self.notifyOverlay setParent( self.notifyIcon );
			self.notifyOverlay setPoint( "CENTER", "CENTER", 0, notifyData.overlayOffsetY );
			self.notifyOverlay setShader( notifyData.iconOverlay, 511, 511 );
			self.notifyOverlay.alpha = 0;
			self.notifyOverlay.color = (1,0,0);

			self.notifyOverlay fadeOverTime( 0.4 );
			self.notifyOverlay.alpha = 0.85;
	
			self.notifyOverlay scaleOverTime( 0.4, 32, 32 );
			
			waitRequireVisibility( duration );

			self.notifyIcon fadeOverTime( 0.75 );
			self.notifyIcon.alpha = 0;
	
			self.notifyOverlay fadeOverTime( 0.75 );
			self.notifyOverlay.alpha = 0;
		}
		else
		{
			self.notifyIcon fadeOverTime( 1.0 );
			self.notifyIcon.alpha = 1;

			waitRequireVisibility( duration );

			self.notifyIcon fadeOverTime( 0.75 );
			self.notifyIcon.alpha = 0;
		}		
	}
	else
	{
		waitRequireVisibility( duration );
	}

	self notify ( "notifyMessageDone" );
	self.doingSplash[ slot ] = undefined;

	if ( self.splashQueue[ slot ].size )
		self thread dispatchNotify( slot );
}


killstreakSplashNotify( splashRef, streakVal, appendString )
{
	self endon ( "disconnect" );
	waittillframeend;

	if ( level.gameEnded )
		return;

	actionData = spawnStruct();
	
	if ( IsDefined( appendString ) )
		splashRef += "_" + appendString;

	actionData.name = splashRef;
	actionData.type = TableLookup( "mp/splashTable.csv", 0, splashRef, 11 );
	actionData.optionalNumber = streakVal;	
	actionData.sound = getKillstreakSound( splashRef );
	actionData.leaderSound = splashRef;
	actionData.leaderSoundGroup = "killstreak_earned";
	actionData.slot = 0;

	self thread actionNotify( actionData );
}


defconSplashNotify( defconLevel, forceNotify )
{
	/*
	actionData = spawnStruct();
	
	actionData.name = "defcon_" + defconLevel;
	actionData.sound = TableLookup( "mp/splashTable.csv", 0, actionData.name, 9 );
	actionData.slot = 0;
	actionData.forceNotify = forceNotify;

	self thread actionNotify( actionData );
	*/
}


challengeSplashNotify( challengeRef )
{
	self endon ( "disconnect" );
	waittillframeend;
	
	// this is used to ensure the client receives the new challenge state before the splash is shown.
	wait ( 0.05 );

	//subtracting one from state becase state was incremented after completing challenge
	challengeState = ( self ch_getState( challengeRef ) - 1 );
	challengeTarget = ch_getTarget( challengeRef, challengeState );
	
	if( challengeTarget == 0 )
		challengeTarget = 1;
	
	if( challengeRef == "ch_longersprint_pro" || challengeRef == "ch_longersprint_pro_daily" || challengeRef == "ch_longersprint_pro_weekly" )
		challengeTarget = int( challengeTarget/5280 );
	
	actionData = spawnStruct();

	actionData.name = challengeRef;
	actionData.type = TableLookup( "mp/splashTable.csv", 0, challengeRef, 11 );
	actionData.optionalNumber = challengeTarget;
	actionData.sound = TableLookup( "mp/splashTable.csv", 0, challengeRef, 9 );
	actionData.slot = 0;

	self thread actionNotify( actionData );
}


splashNotify( splashRef, optionalNumber )
{
	if ( !IsPlayer(self) )
		return;
	
	self endon ( "disconnect" );
	// wait until any challenges have been processed
	//self waittill( "playerKilledChallengesProcessed" );
	wait .05;

	actionData = spawnStruct();
	
	actionData.name = splashRef;
	actionData.type = TableLookup( "mp/splashTable.csv", 0, splashRef, 11 );
	actionData.optionalNumber = optionalNumber;
	actionData.sound = TableLookup( "mp/splashTable.csv", 0, actionData.name, 9 );
	actionData.slot = 0;

	self thread actionNotify( actionData );
}

splashNotifyUrgent( splashRef, optionalNumber )
{
	self endon ( "disconnect" );
	// wait until any challenges have been processed
	//self waittill( "playerKilledChallengesProcessed" );
	wait .05;

	actionData = spawnStruct();
	
	actionData.name = splashRef;
	actionData.type = TableLookup( "mp/splashTable.csv", 0, splashRef, 11 );
	actionData.optionalNumber = optionalNumber;
	actionData.sound = TableLookup( "mp/splashTable.csv", 0, splashRef, 9 );
	actionData.slot = 0;

	self thread actionNotify( actionData );
}

splashNotifyDelayed( splashRef, optionalNumber )
{
	if ( level.hardcoreMode )
		return;
	
	self endon ( "disconnect" );
	waittillframeend;

	if ( level.gameEnded )
		return;

	actionData = spawnStruct();
	
	actionData.name = splashRef;
	actionData.type = TableLookup( "mp/splashTable.csv", 0, splashRef, 11 );
	actionData.optionalNumber = optionalNumber;
	actionData.sound = TableLookup( "mp/splashTable.csv", 0, splashRef, 9 );
	actionData.slot = 0;

	self thread actionNotify( actionData );
}


playerCardSplashNotify( splashRef, player, optionalNumber )
{
	self endon ( "disconnect" );
	waittillframeend;

	if ( level.gameEnded )
		return;

	actionData = spawnStruct();
	
	actionData.name = splashRef;
	actionData.type = TableLookup( "mp/splashTable.csv", 0, splashRef, 11 );
	actionData.optionalNumber = optionalNumber;
	actionData.sound = TableLookup( "mp/splashTable.csv", 0, splashRef, 9 );
	actionData.playerCardPlayer = player;
	actionData.slot = 1;

	self thread actionNotify( actionData );
}


actionNotify( actionData )
{
	self endon ( "death" );
	self endon ( "disconnect" );
	
	assert( IsDefined( actionData.slot ) );
	
	slot = actionData.slot;

	if ( !IsDefined( actionData.type ) )
		actionData.type = "";
	
	if ( !IsDefined( self.doingSplash[ slot ] ) )
	{
		self thread actionNotifyMessage( actionData );
		return;
	}
	else if ( actionData.type == "urgent_splash" )
	{
		self.notifyText.alpha = 0;
		self.notifyText2.alpha = 0;
		self.notifyIcon.alpha = 0;
		self thread actionNotifyMessage( actionData );
		return;
	}
	else if ( actionData.type == "killstreak_splash" && self.doingSplash[ slot ].type != "challenge_splash" && self.doingSplash[ slot ].type != "promotion_splash" )
	{
		self.notifyText.alpha = 0;
		self.notifyText2.alpha = 0;
		self.notifyIcon.alpha = 0;
		self thread actionNotifyMessage( actionData );
		return;
	}
	else if ( actionData.type == "challenge_splash" && self.doingSplash[ slot ].type != "killstreak_splash" && self.doingSplash[ slot ].type != "challenge_splash" && self.doingSplash[ slot ].type != "promotion_splash" )
	{
		self.notifyText.alpha = 0;
		self.notifyText2.alpha = 0;
		self.notifyIcon.alpha = 0;
		self thread actionNotifyMessage( actionData );
		return;
	}	
	
	// push to front of queue
	if ( actionData.type == "challenge_splash" || actionData.type == "killstreak_splash" )
	{
		if ( actionData.type == "killstreak_splash" )
			self removeTypeFromQueue( "killstreak_splash", slot );
		
		for ( i = self.splashQueue[ slot ].size; i > 0; i-- )
			self.splashQueue[ slot ][ i ] = self.splashQueue[ slot ][ i-1 ];

		self.splashQueue[ slot ][ 0 ] = actionData;
	}
	else
	{
		self.splashQueue[ slot ][ self.splashQueue[ slot ].size ] = actionData;
	}
}


removeTypeFromQueue( actionType, slot )
{
	newQueue = [];

	for ( i = 0; i < self.splashQueue[ slot ].size; i++ )
	{
		if ( self.splashQueue[ slot ][ i ].type != "killstreak_splash" )
			newQueue[ newQueue.size ] = self.splashQueue[ slot ][ i ];
	}

	self.splashQueue[ slot ] = newQueue;
}


actionNotifyMessage( actionData )
{
	self endon ( "disconnect" );

	assert( IsDefined( actionData.slot ) );
	slot = actionData.slot;
	
	if ( level.gameEnded )
	{
		// added to prevent potential stack overflow
		wait ( 0 );

		if ( IsDefined( actionData.type ) && ( actionData.type == "promotion_splash" || actionData.type == "promotion_weapon_splash" ) )
		{
			self setClientDvar( "ui_promotion", 1 );
			self.postGamePromotion = true;
		}		
		else if ( IsDefined( actionData.type ) && actionData.type == "challenge_splash" )
		{
			self.pers["postGameChallenges"]++;
			self setClientDvar( "ui_challenge_"+ self.pers["postGameChallenges"] +"_ref", actionData.name );
		}

		if ( self.splashQueue[ slot ].size )
			self thread dispatchNotify( slot );

		return;
	}

	assertEx( TableLookup( "mp/splashTable.csv", 0, actionData.name, 0 ) != "", "ERROR: unknown splash - " + actionData.name );

	// defensive ship hack for missing table entries
	if ( TableLookup( "mp/splashTable.csv", 0, actionData.name, 0 ) != "" )
	{
		splashIdx = TableLookupRowNum( "mp/splashTable.csv", 0, actionData.name );
		duration = stringToFloat( TableLookupByRow( "mp/splashTable.csv", splashIdx, 4 ) );

		// need to let the ui know that a splash has been called
		switch( actionData.type )
		{
		case "killstreak_splash":		
			self SetClientOmnvar( "ui_splash_killstreak_idx", splashIdx );
			if ( IsDefined( actionData.playerCardPlayer ) && actionData.playerCardPlayer != self )
				self SetClientOmnvar( "ui_splash_killstreak_clientnum", actionData.playerCardPlayer GetEntityNumber() );
			else
				self SetClientOmnvar( "ui_splash_killstreak_clientnum", -1 );
			if( IsDefined( actionData.optionalNumber ) )
				self SetClientOmnvar( "ui_splash_killstreak_optional_number", actionData.optionalNumber );
			break;

		case "playercard_splash":
			if ( IsDefined( actionData.playerCardPlayer	) )	// actionData.playerCardPlayer could have disconnected during the wait
			{
				assert( IsPlayer( actionData.playerCardPlayer ) );
				self SetClientOmnvar( "ui_splash_playercard_idx", splashIdx );
				self SetClientOmnvar( "ui_splash_playercard_clientnum", actionData.playerCardPlayer GetEntityNumber() );			
				if( IsDefined( actionData.optionalNumber ) )
					self SetClientOmnvar( "ui_splash_playercard_optional_number", actionData.optionalNumber );
			}
			break;

		case "splash":
		case "urgent_splash":
			self SetClientOmnvar( "ui_splash_idx", splashIdx );
			if( IsDefined( actionData.optionalNumber ) )
				self SetClientOmnvar( "ui_splash_optional_number", actionData.optionalNumber );
			break;

		case "challenge_splash":
		case "perk_challenge_splash":
			// TODO: when we turn challenges back on
			break;

		case "promotion_splash":
		case "promotion_weapon_splash":
			// TODO: when we turn progression back on
			break;

		default:
			AssertMsg( "Splashes should have a type! FIX IT! Splash: " + actionData.name );
			break;
		}
	
		self.doingSplash[ slot ] = actionData;
	
		if ( IsDefined( actionData.sound ) )
			self PlayLocalSound( actionData.sound );
	
		if ( IsDefined( actionData.leaderSound ) )
		{
			if ( IsDefined( actionData.leaderSoundGroup ) )
				self leaderDialogOnPlayer( actionData.leaderSound, actionData.leaderSoundGroup, true );
			else
				self leaderDialogOnPlayer( actionData.leaderSound );
		}
	
		self notify ( "actionNotifyMessage" + slot );
		self endon ( "actionNotifyMessage" + slot );
	
		wait ( duration - 0.05 );

		self.doingSplash[ slot ] = undefined;
	}

	if ( self.splashQueue[ slot ].size )
		self thread dispatchNotify( slot );
}


// waits for waitTime, plus any time required to let flashbangs go away.
waitRequireVisibility( waitTime )
{
	interval = .05;
	
	while ( !self canReadText() )
		wait interval;
	
	while ( waitTime > 0 )
	{
		wait interval;
		if ( self canReadText() )
			waitTime -= interval;
	}
}


canReadText()
{
	if ( self maps\mp\_flashgrenades::isFlashbanged() )
		return false;
	
	return true;
}


resetOnDeath()
{
	self endon ( "notifyMessageDone" );
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	self waittill ( "death" );

	resetNotify();
}


resetOnCancel()
{
	self notify ( "resetOnCancel" );
	self endon ( "resetOnCancel" );
	self endon ( "notifyMessageDone" );
	self endon ( "disconnect" );

	level waittill ( "cancel_notify" );
	
	resetNotify();
}


resetNotify()
{
	self.notifyTitle.alpha = 0;
	self.notifyText.alpha = 0;
	self.notifyIcon.alpha = 0;
	self.notifyOverlay.alpha = 0;
	
	self.doingSplash[0] = undefined;
	self.doingSplash[1] = undefined;
	self.doingSplash[2] = undefined;
	self.doingSplash[3] = undefined;
}


hintMessageDeathThink()
{
	self endon ( "disconnect" );

	for ( ;; )
	{
		self waittill ( "death" );
		
		if ( IsDefined( self.hintMessage ) )
			self.hintMessage destroyElem();
	}
}

lowerMessageThink()
{
	self endon ( "disconnect" );
	
	self.lowerMessages = [];
	
	self.lowerMessage = createFontString( "default", level.lowerTextFontSize );
	self.lowerMessage setText( "" );
	self.lowerMessage.archived = false;
	self.lowerMessage.sort = 10;
	
	if ( level.splitscreen || self isSplitscreenPlayer() )
	{
		self.lowerMessage setPoint( "CENTER", level.lowerTextYAlign, 0, level.lowerTextY );
		timerFontSize = 0.5;
	}
	else
	{
		self.lowerMessage setPoint( "CENTER", level.lowerTextYAlign, 0, (level.lowerTextY-40) );
		timerFontSize = 0.75;	
	}
	
	self.lowerTimer = createFontString( "hudbig", timerFontSize );
	self.lowerTimer setParent( self.lowerMessage );
	self.lowerTimer setPoint( "TOP", "BOTTOM", 0, 0 );
	self.lowerTimer setText( "" );
	self.lowerTimer.archived = false;
	self.lowerTimer.sort = 10;
}


outcomeOverlay( winner )
{
	if ( level.teamBased )
	{
		if ( winner == "tie" )
			self matchOutcomeNotify( "draw" );
		else if ( winner == self.team )
			self matchOutcomeNotify( "victory" );
		else
			self matchOutcomeNotify( "defeat" );
	}
	else
	{
		if ( winner == self )
			self matchOutcomeNotify( "victory" );
		else
			self matchOutcomeNotify( "defeat" );
	}
}


matchOutcomeNotify( outcome )
{
	team = self.team;
	
	outcomeTitle = createFontString( "bigfixed", 1.0 );
	outcomeTitle setPoint( "TOP", undefined, 0, 50 );
	outcomeTitle.foreground = true;
	outcomeTitle.glowAlpha = 1;
	outcomeTitle.hideWhenInMenu = false;
	outcomeTitle.archived = false;

	outcomeTitle setText( game["strings"][outcome] );
	outcomeTitle.alpha = 0;
	outcomeTitle fadeOverTime( 0.5 );
	outcomeTitle.alpha = 1;	
	
	switch( outcome )
	{
		case "victory":
			outcomeTitle.glowColor = (0.6, 0.9, 0.6);
			break;
		default:
			outcomeTitle.glowColor = (0.9, 0.6, 0.6);
			break;
	}

	centerIcon = createIcon( game["icons"][team], 64, 64 );
	centerIcon setParent( outcomeTitle );
	centerIcon setPoint( "TOP", "BOTTOM", 0, 30 );
	centerIcon.foreground = true;
	centerIcon.hideWhenInMenu = false;
	centerIcon.archived = false;
	centerIcon.alpha = 0;
	centerIcon fadeOverTime( 0.5 );
	centerIcon.alpha = 1;	
	
	wait ( 3.0 );
	
	outcomeTitle destroyElem();
	centerIcon destroyElem();
}


isDoingSplash()
{
	if ( IsDefined( self.doingSplash[0] ) )
		return true;

	if ( IsDefined( self.doingSplash[1] ) )
		return true;

	if ( IsDefined( self.doingSplash[2] ) )
		return true;

	if ( IsDefined( self.doingSplash[3] ) )
		return true;

	return false;		
}


teamOutcomeNotify( winner, isRound, endReasonText )
{
	self endon ( "disconnect" );
	self notify ( "reset_outcome" );

	wait ( 0.5 );

	team = self.pers["team"];
	if ( !IsDefined( team ) || (team != "allies" && team != "axis") )
		team = "allies";

	// wait for notifies to finish
	while ( self isDoingSplash() )
		wait 0.05;

	self endon ( "reset_outcome" );
	
	if ( level.splitscreen || self isSplitscreenPlayer() )
	{
		// These are mostly fullscreen values divided by 1.5
		titleSize = 1;
		titleOffset = -76;
		textSize = 0.667;
		textOffset = 12;
		numberSize = 0.833;
		iconSize = 46;
		iconSpacingH = 40;
		iconSpacing = 30;
		scoreSpacing = 0;
		bonusSpacing = 60;
		font = "hudbig";
	}
	else
	{
		titleSize = 1.5;
		titleOffset = -134;
		textSize = 1.0;
		textOffset = 18;
		numberSize = 1.25;
		iconSize = 70;
		iconSpacingH = 60;
		iconSpacing = 45;
		scoreSpacing = 0;
		bonusSpacing = 90;
		font = "hudbig";
	}

	duration = 60000;

	outcomeTitle = createFontString( font, titleSize );
	outcomeTitle setPoint( "CENTER", undefined, 0, titleOffset );
	outcomeTitle.foreground = true;
	outcomeTitle.glowAlpha = 1;
	outcomeTitle.hideWhenInMenu = false;
	outcomeTitle.archived = false;

	outcomeText = createFontString( font, textSize );
	outcomeText setParent( outcomeTitle );
	outcomeText.foreground = true;
	outcomeText setPoint( "TOP", "BOTTOM", 0, textOffset );
	outcomeText.glowAlpha = 1;
	outcomeText.hideWhenInMenu = false;
	outcomeText.archived = false;
	
	if ( winner == "halftime" )
	{
		outcomeTitle.glowColor = (0.2, 0.3, 0.7);
		outcomeTitle setText( game["strings"]["halftime"] );
		outcomeTitle.color = (1, 1, 1);
		
		winner = "allies";
	}
	else if ( winner == "intermission" )
	{
		outcomeTitle.glowColor = (0.2, 0.3, 0.7);
		outcomeTitle setText( game["strings"]["intermission"] );
		outcomeTitle.color = (1, 1, 1);
		
		winner = "allies";
	}
	else if ( winner == "roundend" )
	{
		outcomeTitle.glowColor = (0.2, 0.3, 0.7);
		outcomeTitle setText( game["strings"]["roundend"] );
		outcomeTitle.color = (1, 1, 1);
		
		winner = "allies";
	}
	else if ( winner == "overtime" )
	{
		outcomeTitle.glowColor = (0.2, 0.3, 0.7);
		outcomeTitle setText( game["strings"]["overtime"] );
		outcomeTitle.color = (1, 1, 1);
		
		winner = "allies";
	}
	else if ( winner == "tie" )
	{
		outcomeTitle.glowColor = (0.2, 0.3, 0.7);
		if ( isRound )
			outcomeTitle setText( game["strings"]["round_draw"] );
		else
			outcomeTitle setText( game["strings"]["draw"] );
		outcomeTitle.color = (1, 1, 1);
		
		winner = "allies";
	}
	else if ( IsDefined( self.pers["team"] ) && winner == team )
	{
		outcomeTitle.glowColor = (0, 0, 0);
		if ( isRound )
			outcomeTitle setText( game["strings"]["round_win"] );
		else
			outcomeTitle setText( game["strings"]["victory"] );
		outcomeTitle.color = (0.6, 0.9, 0.6);
	}
	else
	{
		outcomeTitle.glowColor = (0, 0, 0);
		if ( isRound )
			outcomeTitle setText( game["strings"]["round_loss"] );
		else
			outcomeTitle setText( game["strings"]["defeat"] );
		outcomeTitle.color = (0.7, 0.3, 0.2);
	}
	
	outcomeText.glowColor = (0.2, 0.3, 0.7);
	outcomeText setText( endReasonText );
	
	outcomeTitle setPulseFX( 100, duration, 1000 );
	outcomeText setPulseFX( 100, duration, 1000 );
	
	if ( getIntProperty( "useRelativeTeamColors", 0 ) )
		leftIcon = createIcon( game["icons"][team] + "_blue", iconSize, iconSize );
	else
		leftIcon = createIcon( game["icons"][team], iconSize, iconSize );
	leftIcon setParent( outcomeText );
	leftIcon setPoint( "TOP", "BOTTOM", (iconSpacingH*-1), iconSpacing );
	leftIcon.foreground = true;
	leftIcon.hideWhenInMenu = false;
	leftIcon.archived = false;
	leftIcon.alpha = 0;
	leftIcon fadeOverTime( 0.5 );
	leftIcon.alpha = 1;

	if ( getIntProperty( "useRelativeTeamColors", 0 ) )
		rightIcon = createIcon( game["icons"][level.otherTeam[team]] + "_red", iconSize, iconSize );
	else
		rightIcon = createIcon( game["icons"][level.otherTeam[team]], iconSize, iconSize );
	rightIcon setParent( outcomeText );
	rightIcon setPoint( "TOP", "BOTTOM", iconSpacingH, iconSpacing );
	rightIcon.foreground = true;
	rightIcon.hideWhenInMenu = false;
	rightIcon.archived = false;
	rightIcon.alpha = 0;
	rightIcon fadeOverTime( 0.5 );
	rightIcon.alpha = 1;

	leftScore = createFontString( font, numberSize );
	leftScore setParent( leftIcon );
	leftScore setPoint( "TOP", "BOTTOM", 0, scoreSpacing );
	if ( getIntProperty( "useRelativeTeamColors", 0 ) )
		leftScore.glowColor = game["colors"]["blue"];
	else
		leftScore.glowColor = game["colors"][team];
	leftScore.glowAlpha = 1;
	if ( !isRoundBased() || !isObjectiveBased() )
		leftScore setValue( maps\mp\gametypes\_gamescore::_getTeamScore( team ) );
	else
		leftScore setValue( game["roundsWon"][team] );
	leftScore.foreground = true;
	leftScore.hideWhenInMenu = false;
	leftScore.archived = false;
	leftScore setPulseFX( 100, duration, 1000 );

	rightScore = createFontString( font, numberSize );
	rightScore setParent( rightIcon );
	rightScore setPoint( "TOP", "BOTTOM", 0, scoreSpacing );
	if ( getIntProperty( "useRelativeTeamColors", 0 ) )
		rightScore.glowColor = game["colors"]["red"];
	else
		rightScore.glowColor = game["colors"][level.otherTeam[team]];
	rightScore.glowAlpha = 1;
	if ( !isRoundBased() || !isObjectiveBased() )
		rightScore setValue( maps\mp\gametypes\_gamescore::_getTeamScore( level.otherTeam[team] ) );
	else
		rightScore setValue( game["roundsWon"][level.otherTeam[team]] );
	rightScore.foreground = true;
	rightScore.hideWhenInMenu = false;
	rightScore.archived = false;
	rightScore setPulseFX( 100, duration, 1000 );

	matchBonus = undefined;
	if ( IsDefined( self.matchBonus ) )
	{
		matchBonus = createFontString( font, textSize );
		matchBonus setParent( outcomeText );
		matchBonus setPoint( "TOP", "BOTTOM", 0, iconSize + bonusSpacing + leftScore.height );
		matchBonus.glowAlpha = 1;
		matchBonus.foreground = true;
		matchBonus.hideWhenInMenu = false;
		matchBonus.color = (1,1,0.5);
		matchBonus.archived = false;
		matchBonus.label = game["strings"]["match_bonus"];
		matchBonus setValue( self.matchBonus );
	}
	
	self thread resetTeamOutcomeNotify( outcomeTitle, outcomeText, leftIcon, rightIcon, leftScore, rightScore, matchBonus );
}


outcomeNotify( winner, endReasonText )
{
	self endon ( "disconnect" );
	self notify ( "reset_outcome" );

	// wait for notifies to finish
	while ( self isDoingSplash() )
		wait 0.05;

	self endon ( "reset_outcome" );

	if ( level.splitscreen || self isSplitscreenPlayer() )
	{
		titleSize = 2.0;
		winnerSize = 1.5;
		otherSize = 1.5;
		iconSize = 30;
		spacing = 2;
		font = "default";
	}
	else
	{
		titleSize = 3.0;
		winnerSize = 2.0;
		otherSize = 1.5;
		iconSize = 30;
		spacing = 20;
		font = "objective";
	}

	duration = 60000;

	players = level.placement["all"];
	firstPlace =	players[0];
	secondPlace =	players[1];
	thirdPlace =	players[2];

	outcomeTitle = createFontString( font, titleSize );
	outcomeTitle setPoint( "TOP", undefined, 0, spacing );
	// this is going to be non team based and we display the top three
	// if this player is tied for first then show the tie message
	tied = false;
	if( IsDefined( firstPlace ) && 
		self.score == firstPlace.score && 
		self.deaths == firstPlace.deaths )
	{
		if( self != firstPlace )
			tied = true;
		else
		{
			if( IsDefined( secondPlace ) && 
				secondPlace.score == firstPlace.score && 
				secondPlace.deaths == firstPlace.deaths )
			{
				tied = true;
			}			
		}
	}
	
	if( tied )
	{
		outcomeTitle setText( game["strings"]["tie"] );
		outcomeTitle.glowColor = (0.2, 0.3, 0.7);
	}
	else
	{
		if( IsDefined( firstPlace ) && self == firstPlace )
		{
			outcomeTitle setText( game["strings"]["victory"] );
			outcomeTitle.glowColor = (0.2, 0.3, 0.7);
		}
		else
		{
			outcomeTitle setText( game["strings"]["defeat"] );
			outcomeTitle.glowColor = (0.7, 0.3, 0.2);
		}
	}

	outcomeTitle.glowAlpha = 1;
	outcomeTitle.foreground = true;
	outcomeTitle.hideWhenInMenu = false;
	outcomeTitle.archived = false;
	outcomeTitle setPulseFX( 100, duration, 1000 );

	outcomeText = createFontString( font, 2.0 );
	outcomeText setParent( outcomeTitle );
	outcomeText setPoint( "TOP", "BOTTOM", 0, 0 );
	outcomeText.glowAlpha = 1;
	outcomeText.foreground = true;
	outcomeText.hideWhenInMenu = false;
	outcomeText.archived = false;
	outcomeText.glowColor = (0.2, 0.3, 0.7);
	outcomeText setText( endReasonText );

	firstTitle = createFontString( font, winnerSize );
	firstTitle setParent( outcomeText );
	firstTitle setPoint( "TOP", "BOTTOM", 0, spacing );
	firstTitle.glowColor = (0.3, 0.7, 0.2);
	firstTitle.glowAlpha = 1;
	firstTitle.foreground = true;
	firstTitle.hideWhenInMenu = false;
	firstTitle.archived = false;
	if ( IsDefined( firstPlace ) )
	{
		firstTitle.label = &"MP_FIRSTPLACE_NAME";
		firstTitle setPlayerNameString( firstPlace );
		firstTitle setPulseFX( 100, duration, 1000 );
	}

	secondTitle = createFontString( font, otherSize );
	secondTitle setParent( firstTitle );
	secondTitle setPoint( "TOP", "BOTTOM", 0, spacing );
	secondTitle.glowColor = (0.2, 0.3, 0.7);
	secondTitle.glowAlpha = 1;
	secondTitle.foreground = true;
	secondTitle.hideWhenInMenu = false;
	secondTitle.archived = false;
	if ( IsDefined( secondPlace ) )
	{
		secondTitle.label = &"MP_SECONDPLACE_NAME";
		secondTitle setPlayerNameString( secondPlace );
		secondTitle setPulseFX( 100, duration, 1000 );
	}
	
	thirdTitle = createFontString( font, otherSize );
	thirdTitle setParent( secondTitle );
	thirdTitle setPoint( "TOP", "BOTTOM", 0, spacing );
	thirdTitle setParent( secondTitle );
	thirdTitle.glowColor = (0.2, 0.3, 0.7);
	thirdTitle.glowAlpha = 1;
	thirdTitle.foreground = true;
	thirdTitle.hideWhenInMenu = false;
	thirdTitle.archived = false;
	if ( IsDefined( thirdPlace ) )
	{
		thirdTitle.label = &"MP_THIRDPLACE_NAME";
		thirdTitle setPlayerNameString( thirdPlace );
		thirdTitle setPulseFX( 100, duration, 1000 );
	}

	matchBonus = createFontString( font, 2.0 );
	matchBonus setParent( thirdTitle );
	matchBonus setPoint( "TOP", "BOTTOM", 0, spacing );
	matchBonus.glowAlpha = 1;
	matchBonus.foreground = true;
	matchBonus.hideWhenInMenu = false;
	matchBonus.archived = false;
	if ( IsDefined( self.matchBonus ) )
	{
		matchBonus.label = game["strings"]["match_bonus"];
		matchBonus setValue( self.matchBonus );
	}

	self thread updateOutcome( firstTitle, secondTitle, thirdTitle );
	self thread resetOutcomeNotify( outcomeTitle, outcomeText, firstTitle, secondTitle, thirdTitle, matchBonus );
}

MTDM_outcomeNotify( winner, endReasonText )
{
	//This is stubbed in and modified from the FFA version, this will most likley be reshaped to meed any design requirements.
	
	self endon ( "disconnect" );
	self notify ( "reset_outcome" );

	// wait for notifies to finish
	while ( self isDoingSplash() )
		wait 0.05;

	self endon ( "reset_outcome" );

	if ( level.splitscreen )
	{
		titleSize = 2.0;
		winnerSize = 1.5;
		otherSize = 1.5;
		iconSize = 30;
		spacing = 2;
		font = "default";
	}
	else
	{
		titleSize = 3.0;
		winnerSize = 2.0;
		otherSize = 1.5;
		iconSize = 30;
		spacing = 20;
		font = "objective";
	}

	duration = 60000;

	teams = [];
	scores = [];
	for( i = 0; i < level.teamNameList.size; i++ )
	{
		teams[teams.size] = level.teamNameList[i];
		scores[scores.size] = maps\mp\gametypes\_gamescore::_getTeamScore( teams[i] );
	}
	
	//bubble sort it
	score_1 = 0;
	score_2 = 0;
	swap_score = 0;
	swap_team = "";
	swaps = true;
	
	while ( swaps )
	{
		swaps = false;
		for( i = 0; i < level.teamNameList.size - 1; i++ )
		{	
			score_1 = maps\mp\gametypes\_gamescore::_getTeamScore( teams[i] );
			score_2 = maps\mp\gametypes\_gamescore::_getTeamScore( teams[i+1] );

			if( score_2 > score_1 )
			{
				swap_team = teams[i];
				teams[i] = teams[i+1];
				teams[i+1] = swap_team;
				
				swap_score = scores[i];
				scores[i] = scores[i+1];
				scores[i+1] = swap_score;
				
				swaps = true;
			}
			
		}
	}
		
	outcomeTitle = createFontString( font, titleSize );
	outcomeTitle setPoint( "TOP", undefined, 0, spacing );
	if ( scores[0] == scores[1] && ( self.pers["team"] == teams[0] || self.pers["team"] == teams[1] ))
	{
		outcomeTitle setText( game["strings"]["tie"] );
		outcomeTitle.glowColor = (0.2, 0.3, 0.7);
	}
	else if ( scores[0] == scores[2] && self.pers["team"] == teams[2] )
	{
		outcomeTitle setText( game["strings"]["tie"] );
		outcomeTitle.glowColor = (0.2, 0.3, 0.7);
	}
	else if ( self.pers["team"] == teams[0] )
	{
		outcomeTitle setText( game["strings"]["victory"] );
		outcomeTitle.glowColor = (0.2, 0.3, 0.7);
	}
	else
	{
		outcomeTitle setText( game["strings"]["defeat"] );
		outcomeTitle.glowColor = (0.7, 0.3, 0.2);
	}
	
	outcomeTitle.glowAlpha = 1;
	outcomeTitle.foreground = true;
	outcomeTitle.hideWhenInMenu = false;
	outcomeTitle.archived = false;
	outcomeTitle setPulseFX( 100, duration, 1000 );

	outcomeText = createFontString( font, 2.0 );
	outcomeText setParent( outcomeTitle );
	outcomeText setPoint( "TOP", "BOTTOM", 0, 0 );
	outcomeText.glowAlpha = 1;
	outcomeText.foreground = true;
	outcomeText.hideWhenInMenu = false;
	outcomeText.archived = false;
	outcomeText.glowColor = (0.2, 0.3, 0.7);
	outcomeText setText( endReasonText );

	firstTitle = createFontString( font, winnerSize );
	firstTitle setParent( outcomeText );
	firstTitle setPoint( "TOP", "BOTTOM", 0, spacing );
	firstTitle.glowColor = (0.3, 0.7, 0.2);
	firstTitle.glowAlpha = 1;
	firstTitle.foreground = true;
	firstTitle.hideWhenInMenu = false;
	firstTitle.archived = false;
	if ( IsDefined( teams[0] ) )
	{
		firstTitle.label = &"MP_FIRSTPLACE_NAME";
		str_team_name = teams[0] + "_name";
		firstTitle setText( game["strings"][str_team_name] );
		firstTitle setPulseFX( 100, duration, 1000 );
	}

	secondTitle = createFontString( font, otherSize );
	secondTitle setParent( firstTitle );
	secondTitle setPoint( "TOP", "BOTTOM", 0, spacing );
	secondTitle.glowColor = (0.2, 0.3, 0.7);
	secondTitle.glowAlpha = 1;
	secondTitle.foreground = true;
	secondTitle.hideWhenInMenu = false;
	secondTitle.archived = false;
	if ( IsDefined( teams[1] ) )
	{
		secondTitle.label = &"MP_SECONDPLACE_NAME";
		str_team_name = teams[1] + "_name";
		secondTitle setText( game["strings"][str_team_name] );
		secondTitle setPulseFX( 100, duration, 1000 );
	}
	
	thirdTitle = createFontString( font, otherSize );
	thirdTitle setParent( secondTitle );
	thirdTitle setPoint( "TOP", "BOTTOM", 0, spacing );
	thirdTitle setParent( secondTitle );
	thirdTitle.glowColor = (0.2, 0.3, 0.7);
	thirdTitle.glowAlpha = 1;
	thirdTitle.foreground = true;
	thirdTitle.hideWhenInMenu = false;
	thirdTitle.archived = false;
	if ( IsDefined( teams[2] ) )
	{
		thirdTitle.label = &"MP_THIRDPLACE_NAME";
		str_team_name = teams[2] + "_name";
		thirdTitle setText( game["strings"][str_team_name] );
		thirdTitle setPulseFX( 100, duration, 1000 );
	}

	matchBonus = createFontString( font, 2.0 );
	matchBonus setParent( thirdTitle );
	matchBonus setPoint( "TOP", "BOTTOM", 0, spacing );
	matchBonus.glowAlpha = 1;
	matchBonus.foreground = true;
	matchBonus.hideWhenInMenu = false;
	matchBonus.archived = false;
	if ( IsDefined( self.matchBonus ) )
	{
		matchBonus.label = game["strings"]["match_bonus"];
		matchBonus setValue( self.matchBonus );
	}

	self thread updateOutcome( firstTitle, secondTitle, thirdTitle );
	self thread resetOutcomeNotify( outcomeTitle, outcomeText, firstTitle, secondTitle, thirdTitle, matchBonus );
}


resetOutcomeNotify( outcomeTitle, outcomeText, firstTitle, secondTitle, thirdTitle, matchBonus )
{
	self endon ( "disconnect" );
	self waittill ( "reset_outcome" );
	
	if ( IsDefined( outcomeTitle ) )
		outcomeTitle destroyElem();
	if ( IsDefined( outcomeText ) )
		outcomeText destroyElem();
	if ( IsDefined( firstTitle ) )
		firstTitle destroyElem();
	if ( IsDefined( secondTitle ) )
		secondTitle destroyElem();
	if ( IsDefined( thirdTitle ) )
		thirdTitle destroyElem();
	if ( IsDefined( matchBonus ) )
		matchBonus destroyElem();
}

resetTeamOutcomeNotify( outcomeTitle, outcomeText, leftIcon, rightIcon, LeftScore, rightScore, matchBonus )
{
	self endon ( "disconnect" );
	self waittill ( "reset_outcome" );

	if ( IsDefined( outcomeTitle ) )
		outcomeTitle destroyElem();
	if ( IsDefined( outcomeText ) )
		outcomeText destroyElem();
	if ( IsDefined( leftIcon ) )
		leftIcon destroyElem();
	if ( IsDefined( rightIcon ) )
		rightIcon destroyElem();
	if ( IsDefined( leftScore ) )
		leftScore destroyElem();
	if ( IsDefined( rightScore ) )
		rightScore destroyElem();
	if ( IsDefined( matchBonus ) )
		matchBonus destroyElem();
}


updateOutcome( firstTitle, secondTitle, thirdTitle )
{
	self endon( "disconnect" );
	self endon( "reset_outcome" );
	
	while( true )
	{
		self waittill( "update_outcome" );

		players = level.placement["all"];
		firstPlace =	players[0];
		secondPlace =	players[1];
		thirdPlace =	players[2];

		if ( IsDefined( firstTitle ) && IsDefined( firstPlace ) )
			firstTitle setPlayerNameString( firstPlace );
		else if ( IsDefined( firstTitle ) )
			firstTitle.alpha = 0;
		
		if ( IsDefined( secondTitle ) && IsDefined( secondPlace ) )
			secondTitle setPlayerNameString( secondPlace );
		else if ( IsDefined( secondTitle ) )
			secondTitle.alpha = 0;
		
		if ( IsDefined( thirdTitle ) && IsDefined( thirdPlace ) )
			thirdTitle setPlayerNameString( thirdPlace );
		else if ( IsDefined( thirdTitle ) )
			thirdTitle.alpha = 0;
	}	
}

canShowSplash( type )
{
	
}