#include maps\mp\agents\_scriptedAgents;

main()
{
	self endon( "death" );
	self endon( "killanimscript" );
	
	assert( IsDefined( self.curMeleeTarget ) );

	self.curMeleeTarget endon( "disconnect" );
	
	meleeAnimState = self GetMeleeAnimState();

	// get desired end pos.
	meToTarget = self.curMeleeTarget.origin - self.origin;
	distMeToTarget = Length( meToTarget );

	if ( distMeToTarget < self.attackOffset )
	{
		attackPos = self.origin;
	}
	else
	{
		meToTarget = meToTarget / distMeToTarget;
		attackPos = self.curMeleeTarget.origin - meToTarget * self.attackOffset;
	}

	bLerp = false;

	if ( !self CanMovePointToPoint( self.origin, attackPos ) )
	{
		if ( self AgentCanSeeSentient( self.curMeleeTarget ) )
		{
			groundPos = self DropPosToGround( self.curMeleeTarget.origin );
			if ( IsDefined( groundPos ) )
			{
				bLerp = true;
				attackPos = groundPos;	// i'm going to clip the heck through him, but i need a guaranteed safe spot.
			}
			else
			{
				return;
			}
		}
		else
			return;
	}

	//if ( bLerp )
	//{
		attackAnim = self GetAnimEntry( meleeAnimState, 0 );
		animLength = GetAnimLength( attackAnim );
		meleeNotetracks = GetNotetrackTimes( attackAnim, "dog_melee" );
		if ( meleeNotetracks.size > 0 )
			lerpTime = meleeNotetracks[0] * animLength;
		else
			lerpTime = animLength;

		self ScrAgentDoAnimLerp( self.origin, attackPos, lerpTime );
	//}
	//else
	//{
	//	distMeToAttackPos = Distance2D( self.origin, attackPos );

	//	if ( distMeToAttackPos <= 0 )
	//	{
	//		scaleXY = 0;
	//	}
	//	else
	//	{
	//		attackAnim = self GetAnimEntry( meleeAnimState, 0 );
	//		animDelta = GetMoveDelta( attackAnim );
	//		animDistXY = Length2D( animDelta );
	//		scaleXY = distMeToAttackPos / animDistXY;
	//	}

	//	self ScrAgentSetAnimScale( scaleXY, 1 );
	//}

	self PlayAnimNUntilNotetrack( meleeAnimState, 0, "attack", "dog_melee" );

	damageDealt = self.curMeleeTarget.health;
	if ( IsDefined( self.meleeDamage ) )
		damageDealt = self.meleeDamage;
	
	self.curMeleeTarget DoDamage( damageDealt, self.origin, self, self, "MOD_MELEE_DOG" );
	self PlaySound( "anml_dog_attack_jump" );

	self.curMeleeTarget = undefined;	// dude's dead now, or soon will be.

	self ScrAgentSetPhysicsMode( "gravity" );
	//if ( bLerp )
		self ScrAgentSetAnimMode( "anim deltas" );

	self WaitUntilNotetrack( "attack", "end" );
}

end_script()
{
	self ScrAgentSetAnimScale( 1, 1 );
}

GetMeleeAnimState()
{
	return "attack_run_and_jump";
}