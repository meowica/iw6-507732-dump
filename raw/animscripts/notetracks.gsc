// split from shared.gsc 4/8/2010

#include maps\_utility;
#include animscripts\shared;
#include animscripts\utility;
#include animscripts\combat_utility;
#include common_scripts\utility;

#using_animtree( "generic_human" );


/#
showNoteTrack( note )
{
	if ( getdebugdvar( "scr_shownotetracks" ) != "on" && getdebugdvarint( "scr_shownotetracks" ) != self getentnum() )
		return;

	self endon( "death" );

	anim.showNotetrackSpeed = 30;// units / sec
	anim.showNotetrackDuration = 30;// frames

	if ( !IsDefined( self.a.shownotetrackoffset ) )
	{
		thisoffset = 0;
		self.a.shownotetrackoffset = 10;
		self thread reduceShowNotetrackOffset();
	}
	else
	{
		thisoffset = self.a.shownotetrackoffset;
		self.a.shownotetrackoffset += 10;
	}

	duration = anim.showNotetrackDuration + int( 20.0 * thisoffset / anim.showNotetrackSpeed );

	color = ( .5, .75, 1 );
	if ( note == "end" || note == "finish" )
		color = ( .25, .4, .5 );
	else if ( note == "undefined" )
		color = ( 1, .5, .5 );

	for ( i = 0; i < duration; i++ )
	{
		if ( duration - i <= anim.showNotetrackDuration )
			amnt = 1.0 * ( i - ( duration - anim.showNotetrackDuration ) ) / anim.showNotetrackDuration;
		else
			amnt = 0.0;
		time = 1.0 * i / 20;

		alpha = 1.0 - amnt * amnt;
		pos = self geteye() + ( 0, 0, 20 + anim.showNotetrackSpeed * time - thisoffset );

		print3d( pos, note, color, alpha );

		wait .05;
	}
}
reduceShowNotetrackOffset()
{
	self endon( "death" );
	while ( self.a.shownotetrackoffset > 0 )
	{
		wait .05;
		self.a.shownotetrackoffset -= anim.showNotetrackSpeed * .05;
	}
	self.a.shownotetrackoffset = undefined;
}
#/

HandleDogFootstepNotetracks( note )
{
	switch ( note )
	{
	case "footstep_front_left_small":
	case "footstep_front_right_small":
	case "footstep_back_left_small":
	case "footstep_back_right_small":
	case "footstep_front_left_large":
	case "footstep_front_right_large":
	case "footstep_back_left_large":
	case "footstep_back_right_large":
		{
			groundType = undefined;
			if ( IsDefined( self.groundType ) )
			{
				groundType = self.groundType;
				self.lastGroundType = groundType;
			}
			else if ( IsDefined( self.lastGroundType ) )
			{
				groundType = self.lastGroundType;
			}
			else
			{
				groundType = "dirt";
			}

			if ( groundType != "dirt" && groundType != "cement" && groundType != "wood" && groundType != "metal" )
				groundType = "dirt";

			moveType = self.moveAnimType;
			if ( !IsDefined( moveType ) )
				moveType = "run";

			if ( self IsDogBeingDriven() || isdefined( self.controlling_dog ) )
				self playSound( "dogstep_plr_" + moveType + "_" + groundType );
			else
				self playSound( "dogstep_" + moveType + "_" + groundType );
		}

		return true;
	}

	return false;
}

HandleDogSoundNoteTracks( note )
{	
	if ( self HandleDogFootstepNotetracks( note ) )
		return true;

	if ( note == "sound_dogstep_run_default" )
	{
		self playsound( "dogstep_run_default" );
		return true;
	}

	prefix = getsubstr( note, 0, 5 );

	if ( prefix != "sound" )
		return false;

	alias = "anml" + getsubstr( note, 5 );

//	if ( growling() && !issubstr( alias, "growl" ) )
//		return false;

	if ( isalive( self ) )
		self thread play_sound_on_tag_endon_death( alias, "tag_eye" );
	else
		self thread play_sound_in_space( alias, self GetEye() );
	return true;
}

HandleAlienSoundNoteTracks( note )
{
	if ( isDefined( note ) )
	{
		switch( note )
		{
			case "alien_footstep":
			case "alien_footstep_small":
			case "alien_footstep_fence":
			case "alien_test_attack_sounds":
			case "alien_test_idle_sounds":
			case "alien_voice":
			case "alien_attack":
			case "alien_land_big":
			case "alien_jump":
			case "alien_pain_heavy":
			case "alien_pain_light":
			case "alien_death":
			case "alien_idle_02":
			case "alien_idle_03":
			case "alien_idle_04":
				self PlaySound( note );
				break;
			default:
				break;
		}
	}
}

growling()
{
	return IsDefined( self.script_growl );
}

registerNoteTracks()
{
	anim.notetracks[ "anim_pose = \"stand\"" ] = ::noteTrackPoseStand;
	anim.notetracks[ "anim_pose = \"crouch\"" ] = ::noteTrackPoseCrouch;
	anim.notetracks[ "anim_pose = \"prone\"" ] = ::noteTrackPoseProne;
	anim.notetracks[ "anim_pose = \"crawl\"" ] = ::noteTrackPoseCrawl;
	anim.notetracks[ "anim_pose = \"back\"" ] = ::noteTrackPoseBack;

	anim.notetracks[ "anim_movement = \"stop\"" ] = ::noteTrackMovementStop;
	anim.notetracks[ "anim_movement = \"walk\"" ] = ::noteTrackMovementWalk;
	anim.notetracks[ "anim_movement = \"run\"" ] = ::noteTrackMovementRun;

	anim.notetracks[ "anim_aiming = 1" ] = ::noteTrackAlertnessAiming;
	anim.notetracks[ "anim_aiming = 0" ] = ::noteTrackAlertnessAlert;
	anim.notetracks[ "anim_alertness = causal" ] = ::noteTrackAlertnessCasual;
	anim.notetracks[ "anim_alertness = alert" ] = ::noteTrackAlertnessAlert;
	anim.notetracks[ "anim_alertness = aiming" ] = ::noteTrackAlertnessAiming;

	anim.notetracks[ "gunhand = (gunhand)_left" ] = ::noteTrackGunhand;
	anim.notetracks[ "anim_gunhand = \"left\"" ] = ::noteTrackGunhand;
	anim.notetracks[ "gunhand = (gunhand)_right" ] = ::noteTrackGunhand;
	anim.notetracks[ "anim_gunhand = \"right\"" ] = ::noteTrackGunhand;
	anim.notetracks[ "anim_gunhand = \"none\"" ] = ::noteTrackGunhand;
	anim.notetracks[ "gun drop" ] = ::noteTrackGunDrop;
	anim.notetracks[ "dropgun" ] = ::noteTrackGunDrop;

	anim.notetracks[ "gun_2_chest" ] = ::noteTrackGunToChest;
	anim.notetracks[ "gun_2_back" ] = ::noteTrackGunToBack;
	anim.notetracks[ "pistol_pickup" ] = ::noteTrackPistolPickup;
	anim.notetracks[ "pistol_putaway" ] = ::noteTrackPistolPutaway;
	anim.notetracks[ "drop clip" ] = ::noteTrackDropClip;
	anim.notetracks[ "refill clip" ] = ::noteTrackRefillClip;
	anim.notetracks[ "reload done" ] = ::noteTrackRefillClip;
	anim.notetracks[ "load_shell" ] = ::noteTrackLoadShell;
	anim.notetracks[ "pistol_rechamber" ] = ::noteTrackPistolRechamber;

	anim.notetracks[ "gravity on" ] = ::noteTrackGravity;
	anim.notetracks[ "gravity off" ] = ::noteTrackGravity;
		
	anim.notetracks[ "footstep_right_large" ] = ::noteTrackFootStep;
	anim.notetracks[ "footstep_right_small" ] = ::noteTrackFootStep;
	anim.notetracks[ "footstep_left_large" ] = ::noteTrackFootStep;
	anim.notetracks[ "footstep_left_small" ] = ::noteTrackFootStep;
	anim.notetracks[ "footscrape" ] = ::noteTrackFootScrape;
	anim.notetracks[ "land" ] = ::noteTrackLand;

	anim.notetracks[ "bodyfall large" ] = ::noteTrackBodyFall;
	anim.notetracks[ "bodyfall small" ] = ::noteTrackBodyFall;
		
	anim.notetracks[ "code_move" ] = ::noteTrackCodeMove;
	anim.notetracks[ "face_enemy" ] = ::noteTrackFaceEnemy;

	anim.notetracks[ "laser_on" ] = ::noteTrackLaser;
	anim.notetracks[ "laser_off" ] = ::noteTrackLaser;

	anim.notetracks[ "start_ragdoll" ] = ::noteTrackStartRagdoll;

	anim.notetracks[ "fire" ] = ::noteTrackFire;
	anim.notetracks[ "fire_spray" ] = ::noteTrackFireSpray;

	anim.notetracks[ "bloodpool" ] = animscripts\death::play_blood_pool;
	
	/#
	anim.notetracks[ "attach clip left" ] = animscripts\shared::insure_dropping_clip;
	anim.notetracks[ "attach clip right" ] = animscripts\shared::insure_dropping_clip;
	anim.notetracks[ "detach clip left" ] = animscripts\shared::insure_dropping_clip;
	anim.notetracks[ "detach clip right" ] = animscripts\shared::insure_dropping_clip;
	#/
	
	anim.notetracks[ "space_jet_top" ] = ::noteTrackSpaceJet;
	anim.notetracks[ "space_jet_bottom" ] = ::noteTrackSpaceJet;
	anim.notetracks[ "space_jet_left" ] = ::noteTrackSpaceJet;
	anim.notetracks[ "space_jet_right" ] = ::noteTrackSpaceJet;

	if ( IsDefined( level._notetrackFX ) )
	{
		keys = getArrayKeys( level._notetrackFX );
		foreach( key in keys )
			anim.notetracks[ key ] = ::customNotetrackFX;
	}
}

noteTrackFire( note, flagName )
{
	if ( IsDefined( anim.fire_notetrack_functions[ self.script ] ) )
		thread [[ anim.fire_notetrack_functions[ self.script ] ]]();
	else
		thread [[ ::shootNotetrack ]]();
}

noteTrackLaser( note, flagName )
{
	if ( isSubStr( note, "on" ) )
		self.a.laserOn = true;
	else
		self.a.laserOn = false;
	self animscripts\shared::updateLaserStatus();
}


noteTrackStopAnim( note, flagName )
{
}

unlinkNextFrame()
{
	// by waiting a couple frames, we let ragdoll inherit our velocity.
	wait .1;
	if ( IsDefined( self ) )
		self unlink();
}

noteTrackStartRagdoll( note, flagName )
{
	if ( IsDefined( self.noragdoll ) )
	{
		return; // Nate - hack for armless zakhaev who doesn't do ragdoll
	}

	// Since we're setting the ragdolltime, ignore the notetrack version
	if ( IsDefined( self.ragdolltime ) )
	{
		return;
	}

	if ( !IsDefined( self.dont_unlink_ragdoll ) )
	{
		self thread unlinkNextFrame();
	}

	self StartRagdoll();

/#
	if ( isalive( self ) )
	{
		println( "^4Warning!! Living guy did ragdoll!" );
	}
#/
}

noteTrackMovementStop( note, flagName )
{
	self.a.movement = "stop";
}

noteTrackMovementWalk( note, flagName )
{
	self.a.movement = "walk";
}

noteTrackMovementRun( note, flagName )
{
	self.a.movement = "run";
}


noteTrackAlertnessAiming( note, flagName )
{
	//self.a.alertness = "aiming";
}

noteTrackAlertnessCasual( note, flagName )
{
	//self.a.alertness = "casual";
}

noteTrackAlertnessAlert( note, flagName )
{
	//self.a.alertness = "alert";
}

stopOnBack()
{
	self ExitProneWrapper( 1.0 );// make code stop lerping in the prone orientation to ground
	self.a.onback = undefined;
}

setPose( pose )
{
	self.a.pose = pose;
	
	if ( IsDefined( self.a.onback ) )
		stopOnBack();
	
	self notify( "entered_pose" + pose );
}

noteTrackPoseStand( note, flagName )
{
	if ( self.a.pose == "prone" )
	{
		self OrientMode( "face default" );	// We were most likely in "face current" while we were prone.
		self ExitProneWrapper( 1.0 );// make code stop lerping in the prone orientation to ground
	}
	setPose( "stand" );
}

noteTrackPoseCrouch( note, flagName )
{
	if ( self.a.pose == "prone" )
	{
		self OrientMode( "face default" );	// We were most likely in "face current" while we were prone.
		self ExitProneWrapper( 1.0 );// make code stop lerping in the prone orientation to ground
	}
	setPose( "crouch" );
}

noteTrackPoseProne( note, flagName )
{
	if ( !issentient( self ) )
		return;
		
	self setProneAnimNodes( -45, 45, %prone_legs_down, %exposed_aiming, %prone_legs_up );
	self EnterProneWrapper( 1.0 );// make code start lerping in the prone orientation to ground
	setPose( "prone" );
	
	if ( IsDefined( self.a.goingToProneAim ) )
		self.a.proneAiming = true;
	else
		self.a.proneAiming = undefined;
}


noteTrackPoseCrawl( note, flagName )
{
	if ( !issentient( self ) )
		return;

	self setProneAnimNodes( -45, 45, %prone_legs_down, %exposed_aiming, %prone_legs_up );
	self EnterProneWrapper( 1.0 );// make code start lerping in the prone orientation to ground
	setPose( "prone" );
	self.a.proneAiming = undefined;
}


noteTrackPoseBack( note, flagName )
{
	if ( !issentient( self ) )
		return;

	setPose( "crouch" );
	self.a.onback = true;
	self.a.movement = "stop";
	
	self setProneAnimNodes( -90, 90, %prone_legs_down, %exposed_aiming, %prone_legs_up );
	self EnterProneWrapper( 1.0 );// make code start lerping in the prone orientation to ground
}


noteTrackGunHand( note, flagName )
{
	if ( isSubStr( note, "left" ) )
	{
		animscripts\shared::placeWeaponOn( self.weapon, "left" );
		self notify( "weapon_switch_done" );
	}
	else if ( isSubStr( note, "right" ) )
	{
		animscripts\shared::placeWeaponOn( self.weapon, "right" );
		self notify( "weapon_switch_done" );
	}
	else if ( isSubStr( note, "none" ) )
	{
		animscripts\shared::placeWeaponOn( self.weapon, "none" );
	}
}


noteTrackGunDrop( note, flagName )
{
	self DropAIWeapon();
	
	self.lastWeapon = self.weapon;
}


noteTrackGunToChest( note, flagName )
{
	//assert( !usingSidearm() );
	animscripts\shared::placeWeaponOn( self.weapon, "chest" );
}


noteTrackGunToBack( note, flagName )
{
	animscripts\shared::placeWeaponOn( self.weapon, "back" );
	// TODO: more asserts and elegant handling of weapon switching here
	self.weapon = self getPreferredWeapon();
	self.bulletsInClip = weaponClipSize( self.weapon );
}


noteTrackPistolPickup( note, flagName )
{
	animscripts\shared::placeWeaponOn( self.sidearm, "right" );
	self.bulletsInClip = weaponClipSize( self.weapon );
	self notify( "weapon_switch_done" );
}


noteTrackPistolPutaway( note, flagName )
{
	animscripts\shared::placeWeaponOn( self.weapon, "none" );
	// TODO: more asserts and elegant handling of weapon switching here
	self.weapon = self getPreferredWeapon();
	self.bulletsInClip = weaponClipSize( self.weapon );
}


noteTrackDropClip( note, flagName )
{
	self thread handleDropClip( flagName );
}


noteTrackRefillClip( note, flagName )
{
	if ( weaponClass( self.weapon ) == "rocketlauncher" )
		self showRocket();
	self animscripts\weaponList::RefillClip();
	self.a.needsToRechamber = 0;
}

noteTrackLoadShell( note, flagName )
{
	self playSound( "weap_reload_shotgun_loop_npc" );
}

noteTrackPistolRechamber( note, flagName )
{
	self playSound( "weap_reload_pistol_chamber_npc" );
}

noteTrackGravity( note, flagName )
{
	if ( isSubStr( note, "on" ) )
        self animMode( "gravity" );
	else if ( isSubStr( note, "off" ) )
		self animMode( "nogravity" );
}


noteTrackFootStep( note, flagName )
{
	is_left = IsSubStr( note, "left" );
	is_large = IsSubStr( note, "large" );

	playFootStep( is_left, is_large );

	run_type = get_notetrack_movement();
	
	cloth_sound = self GetClothMoveSound( run_type );
	if ( IsDefined( cloth_sound ) && cloth_sound != "" )
		self PlaySound( cloth_sound );
	
	equip_sound = self GetEquipMoveSound( self.weapon, run_type );
	if ( IsDefined( equip_sound ) && equip_sound != "" )
		self PlaySound( equip_sound );
}

get_notetrack_movement()
{
	run_type = "run";
	if ( IsDefined( self.sprint ) )
	{
		run_type = "sprint";
	}

	if ( IsDefined( self.a ) )
	{
		if ( IsDefined( self.a.movement ) )
		{
			if ( self.a.movement == "walk" )
			{
				run_type = "walk";
			}
		}

		if ( IsDefined( self.a.pose ) )
		{
			if ( self.a.pose == "prone" )
			{
				run_type = "prone";
			}
		}
	}

	return run_type;
}

noteTrackSpaceJet( note, flagName )
{
	
	tag_joint = undefined;
	joint_test = undefined;
	
	switch( note )
	{
	case "space_jet_bottom":
			tag_joint = "TAG_JET_BOTTOM";
			break;
	case "space_jet_top":
			tag_joint = "TAG_JET_TOP";
			break;
	case "space_jet_left":
			tag_joint = "TAG_JET_LE";
			break;
	case "space_jet_right":
			tag_joint = "TAG_JET_RI";
			break;
	}
	
	if (( fxExists( "space_jet_small" ) ) && ( IsDefined( tag_joint ) ) )
	{	
		//Make sure space character models are used.
		if ( IsSubStr( self.classname, "space" ) )
		{
			PlayFXOnTag( level._effect[ "space_jet_small" ], self, tag_joint );
		}
	}
}

customNotetrackFX( note, flagName )
{
	assert( IsDefined( level._notetrackFX[ note ] ) );
	
	if ( IsDefined( self.groundType ) )
		groundType = self.groundType;
	else
		groundType = "dirt";
	
	struct = undefined;
	if ( IsDefined( level._notetrackFX[ note ][ groundType ] ) )
		struct = level._notetrackFX[ note ][ groundType ];
	else if ( IsDefined( level._notetrackFX[ note ][ "all" ] ) )
		struct = level._notetrackFX[ note ][ "all" ];
	
	if ( !IsDefined( struct ) )
		return;

	if ( isAI( self ) && IsDefined( struct.fx ) )
		PlayFXOnTag( struct.fx, self, struct.tag );
	
	if ( !IsDefined( struct.sound_prefix ) && !IsDefined( struct.sound_suffix ) )
		return;

	alias = "" + struct.sound_prefix + groundType + struct.sound_suffix;
	self PlaySound( alias );
}

noteTrackFootScrape( note, flagName )
{
	if ( IsDefined( self.groundType ) )
		groundType = self.groundType;
	else
		groundType = "dirt";

	self playsound( "step_scrape_" + groundType );
}


noteTrackLand( note, flagName )
{
	if ( IsDefined( self.groundType ) )
		groundType = self.groundType;
	else
		groundType = "dirt";

	self playsound( "land_" + groundType );
	
	cloth_sound = self GetClothMoveSound( "land" );
	if ( IsDefined( cloth_sound ) && cloth_sound != "" )
		self PlaySound( cloth_sound );
	
	equip_sound = self GetEquipMoveSound( self.weapon, "land" );
	if ( IsDefined( equip_sound ) && equip_sound != "" )
		self PlaySound( equip_sound );
}


noteTrackCodeMove( note, flagName )
{
	return "code_move";
}


noteTrackFaceEnemy( note, flagName )
{
	if ( self.script != "reactions" )
	{
		self orientmode( "face enemy" );
	}
	else
	{
		if ( IsDefined( self.enemy ) && distanceSquared( self.enemy.origin, self.reactionTargetPos ) < 64 * 64 )
			self orientmode( "face enemy" );
		else
			self orientmode( "face point", self.reactionTargetPos );
	}
}

noteTrackBodyFall( note, flagName )
{
	suffix = "_small";
	if ( IsSubStr( note, "large" ) )
	{
		suffix = "_large";
	}

	if ( IsDefined( self.groundType ) )
	{
		groundType = self.groundType;
	}
	else
	{
		groundType = "dirt";
	}

	self PlaySound( "bodyfall_" + groundType + suffix );
}

HandleNoteTrack( note, flagName, customFunction )
{
	 /#
	self thread showNoteTrack( note );
	#/

	if( isAI( self ) && self.type == "alien" )
		HandleAlienSoundNoteTracks( note );
				
	if ( isAI( self ) && self.type == "dog" )
		if ( HandleDogSoundNoteTracks( note ) )
			return;

	notetrackFunc = anim.notetracks[ note ];
	if ( IsDefined( notetrackFunc ) )
	{
		return [[ notetrackFunc ]]( note, flagName );
	}

	switch( note )
	{
	case "end":
	case "finish":
	case "undefined":
		return note;

	case "finish early":
		if ( IsDefined( self.enemy ) )
			return note;
		break;		

	case "swish small":
		self thread play_sound_in_space( "melee_swing_small", self gettagorigin( "TAG_WEAPON_RIGHT" ) );
		break;
	case "swish large":
		self thread play_sound_in_space( "melee_swing_large", self gettagorigin( "TAG_WEAPON_RIGHT" ) );
		break;

	case "rechamber":
		if ( weapon_pump_action_shotgun() )
			self playSound( "weap_reload_shotgun_pump_npc" );
		self.a.needsToRechamber = 0;
		break;
	case "no death":
		// does not play a death anim when he dies
		self.a.nodeath = true;
		break;
	case "no pain":
		self.allowpain = false;
		break;
	case "allow pain":
		self.allowpain = true;
		break;
	case "anim_melee = right":
	case "anim_melee = \"right\"":
		self.a.meleeState = "right";
		break;
	case "anim_melee = left":
	case "anim_melee = \"left\"":
		self.a.meleeState = "left";
		break;
	case "swap taghelmet to tagleft":
		if ( IsDefined( self.hatModel ) )
		{
			if ( IsDefined( self.helmetSideModel ) )
			{
				self detach( self.helmetSideModel, "TAG_HELMETSIDE" );
				self.helmetSideModel = undefined;
			}
			self detach( self.hatModel, "" );
			self attach( self.hatModel, "TAG_WEAPON_LEFT" );
			self.hatModel = undefined;
		}
		break;
	case "stop anim":
		anim_stopanimscripted();
		return note;
	case "break glass":
		level notify( "glass_break", self );
		break;
	case "break_glass":
		level notify( "glass_break", self );
		break;
	default:
		if ( IsDefined( customFunction ) )
			return [[ customFunction ]]( note );
		break;
	}
}


DoNoteTracksIntercept( flagName, interceptFunction, debugIdentifier )// debugIdentifier isn't even used. we should get rid of it.
{
	assert( IsDefined( interceptFunction ) );

	for ( ;; )
	{
		self waittill( flagName, note );

		if ( !IsDefined( note ) )
			note = "undefined";

		intercepted = [[ interceptFunction ]]( note );
		if ( IsDefined( intercepted ) && intercepted )
			continue;

		//prof_begin("HandleNoteTrack");
		val = self HandleNoteTrack( note, flagName );
		//prof_end("HandleNoteTrack");

		if ( IsDefined( val ) )
			return val;
	}
}


DoNoteTracksPostCallback( flagName, postFunction )
{
	assert( IsDefined( postFunction ) );

	for ( ;; )
	{
		self waittill( flagName, note );

		if ( !IsDefined( note ) )
			note = "undefined";

		//prof_begin("HandleNoteTrack");
		val = self HandleNoteTrack( note, flagName );
		//prof_end("HandleNoteTrack");

		[[ postFunction ]]( note );

		if ( IsDefined( val ) )
			return val;
	}
}

DoNoteTracksForTimeout( flagName, killString, customFunction, debugIdentifier )
{
	DoNoteTracks( flagName, customFunction, debugIdentifier );
}

// Don't call this function except as a thread you're going to kill - it lasts forever.
DoNoteTracksForever( flagName, killString, customFunction, debugIdentifier )
{
	DoNoteTracksForeverProc( ::DoNoteTracks, flagName, killString, customFunction, debugIdentifier );
}

DoNoteTracksForeverIntercept( flagName, killString, interceptFunction, debugIdentifier )
{
	DoNoteTracksForeverProc( ::DoNoteTracksIntercept, flagName, killString, interceptFunction, debugIdentifier );
}

DoNoteTracksForeverProc( notetracksFunc, flagName, killString, customFunction, debugIdentifier )
{
	if ( IsDefined( killString ) )
		self endon( killString );
	self endon( "killanimscript" );
	if ( !IsDefined( debugIdentifier ) )
		debugIdentifier = "undefined";

	for ( ;; )
	{
		//prof_begin( "DoNoteTracksForeverProc" );
		time = GetTime();
		//prof_begin( "notetracksFunc" );
		returnedNote = [[ notetracksFunc ]]( flagName, customFunction, debugIdentifier );
		//prof_end( "notetracksFunc" );
		timetaken = GetTime() - time;
		if ( timetaken < 0.05 )
		{
			time = GetTime();
			//prof_begin( "notetracksFunc" );
			returnedNote = [[ notetracksFunc ]]( flagName, customFunction, debugIdentifier );
			//prof_end( "notetracksFunc" );
			timetaken = GetTime() - time;
			if ( timetaken < 0.05 )
			{
				println( GetTime() + " " + debugIdentifier + " animscripts\shared::DoNoteTracksForever is trying to cause an infinite loop on anim " + flagName + ", returned " + returnedNote + "." );
				wait( 0.05 - timetaken );
			}
		}
		//(GetTime()+" "+debugIdentifier+" DoNoteTracksForever returned in "+timetaken+" ms.");#/
		//prof_end( "DoNoteTracksForeverProc" );
	}
}


// Designed for using DoNoteTracks until "end" is reached, or a specified amount of time, whichever happens first
DoNoteTracksWithTimeout( flagName, time, customFunction, debugIdentifier )
{
	ent = spawnstruct();
	ent thread doNoteTracksForTimeEndNotify( time );
	DoNoteTracksForTimeProc( ::DoNoteTracksForTimeout, flagName, customFunction, debugIdentifier, ent );
}

// Designed for using DoNoteTracks on looping animations, so you can wait for a time instead of the "end" parameter
DoNoteTracksForTime( time, flagName, customFunction, debugIdentifier )
{
	ent = spawnstruct();
	ent thread doNoteTracksForTimeEndNotify( time );
	DoNoteTracksForTimeProc( ::DoNoteTracksForever, flagName, customFunction, debugIdentifier, ent );
}

DoNoteTracksForTimeIntercept( time, flagName, interceptFunction, debugIdentifier )
{
	ent = spawnstruct();
	ent thread doNoteTracksForTimeEndNotify( time );
	DoNoteTracksForTimeProc( ::DoNoteTracksForeverIntercept, flagName, interceptFunction, debugIdentifier, ent );
}

DoNoteTracksForTimeProc( doNoteTracksForeverFunc, flagName, customFunction, debugIdentifier, ent )
{
	ent endon( "stop_notetracks" );
	[[ doNoteTracksForeverFunc ]]( flagName, undefined, customFunction, debugIdentifier );
}

doNoteTracksForTimeEndNotify( time )
{
	wait( time );
	self notify( "stop_notetracks" );
}

playFootStep( is_left, is_large )
{
	if ( ! isAI( self ) )
	{
		self playsound( "step_run_dirt" );
		return;
	}

	groundType = undefined;
	// gotta record the groundtype in case it goes undefined on us
	if ( !IsDefined( self.groundtype ) )
	{
		if ( !IsDefined( self.lastGroundtype ) )
		{
			self playsound( "step_run_dirt" );
			return;
		}

		groundtype = self.lastGroundtype;
	}
	else
	{
		groundtype = self.groundtype;
		self.lastGroundtype = self.groundType;
	}

	foot = "J_Ball_RI";
	if ( is_left )
	{
		foot = "J_Ball_LE";
	}

	run_type = get_notetrack_movement();

	self playsound( "step_" + run_type + "_" + groundType );
	if ( is_large )
	{
		if ( ![[ anim.optionalStepEffectFunction ]]( foot, groundType ) )
		{
			playFootStepEffectSmall( foot, groundType );
		}
	}
	else
	{
		if ( ![[ anim.optionalStepEffectSmallFunction ]]( foot, groundType ) )
		{
			playFootStepEffect( foot, groundType );
		}
	}
}

playFootStepEffect( foot, groundType )
{
	if ( !IsDefined( anim.optionalStepEffects[ groundType ] ) )
			return false;

	org = self gettagorigin( foot );
	angles = self.angles;
	forward = anglestoforward( angles );
	back = forward * - 1;
	up = anglestoup( angles );
	
	playfx( level._effect[ "step_" + groundType ], org, up, back );
	return true;
}

playFootStepEffectSmall( foot, groundType )
{
	if ( !IsDefined( anim.optionalStepEffectsSmall[ groundType ] ) )
		return false;
	
	org = self gettagorigin( foot );
	angles = self.angles;
	forward = anglestoforward( angles );
	back = forward * - 1;
	up = anglestoup( angles );
	
	playfx( level._effect[ "step_small_" + groundType ], org, up, back );
	return true;
}

shootNotetrack()
{
	waittillframeend;// this gives a chance for anything else waiting on "fire" to shoot
	if ( IsDefined( self ) && gettime() > self.a.lastShootTime )
	{
		self shootEnemyWrapper();
		self decrementBulletsInClip();
		if ( weaponClass( self.weapon ) == "rocketlauncher" )
			self.a.rockets -- ;
	}
}

fire_straight()
{
	if ( self.a.weaponPos[ "right" ] == "none" )
		return;

	if ( IsDefined( self.dontShootStraight ) )
	{
		shootNotetrack();
		return;
	}

	weaporig = self gettagorigin( "tag_weapon" );
	dir = anglestoforward( self getMuzzleAngle() );
	pos = weaporig + ( dir * 1000 );
	// note, shootwrapper is not called because shootwrapper applies a random spread, and shots
	// fired in a scripted sequence need to go perfectly straight so they get the same result each time.
	self shoot( 1, pos );
	self decrementBulletsInClip();
}

noteTrackFireSpray( note, flagName )
{
	if ( !isalive( self ) && self isBadGuy() )
	{
		if ( IsDefined( self.changed_team ) )
			return;
			

		self.changed_team = true;
		teams[ "axis" ] = "team3";
		teams[ "team3" ] = "axis";
		assertex( IsDefined( teams[ self.team ] ), "no team for " + self.team );
		self.team = teams[ self.team ];
	}

	// TODO: make AI not use anims with this notetrack if they don't have a weapon
	if ( !issentient( self ) )
	{
		// for drones
		self notify( "fire" );
//		self shoot();
		return;
	}
	 
	if ( self.a.weaponPos[ "right" ] == "none" )
		return;

	//prof_begin( "noteTrackFireSpray" );

	weaporig = self getMuzzlePos();
	dir = anglestoforward( self getMuzzleAngle() );
	
	// rambo set sprays at a wider range than other fire_spray anims
	ang = 10;
	if ( IsDefined( self.isRambo ) )
		ang = 20;
	
	hitenemy = false;
	// check if we're aiming closish to our enemy
	if ( isalive( self.enemy ) && issentient( self.enemy ) && self canShootEnemy() )
	{
		enemydir = vectornormalize( self.enemy geteye() - weaporig );
		if ( vectordot( dir, enemydir ) > cos( ang ) )
		{
			hitenemy = true;
		}
	}

	if ( hitenemy )
	{
		self shootEnemyWrapper();
	}
	else
	{
		dir += ( ( randomfloat( 2 ) - 1 ) * .1, ( randomfloat( 2 ) - 1 ) * .1, ( randomfloat( 2 ) - 1 ) * .1 );
		pos = weaporig + ( dir * 1000 );

		self shootPosWrapper( pos );
	}

	self decrementBulletsInClip();

	//prof_end( "noteTrackFireSpray" );
}

