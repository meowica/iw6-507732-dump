#include maps\mp\agents\_scriptedAgents;

main()
{
	self endon( "killanimscript" );

	if ( !IsDefined( level.dogTraverseAnims ) )
		InitDogTraverseAnims();

	startNode = self GetNegotiationStartNode();
	endNode = self GetNegotiationEndNode();
	assert( IsDefined( startNode ) && IsDefined( endNode ) );

	animState = undefined;
	
	animState = level.dogTraverseAnims[ startNode.animscript ];

	if ( !IsDefined( animState ) )
	{
		assertmsg( "no animation for traverse " + startNode.animscript );
		return;
	}

	startToEnd = endNode.origin - startNode.origin;
	startToEnd2D = ( startToEnd[0], startToEnd[1], 0 );
	anglesToEnd = VectorToAngles( startToEnd2D );

	self ScrAgentSetOrientMode( "face angle abs", anglesToEnd );
	self ScrAgentSetAnimMode( "anim deltas" );

	traverseAnim = self GetAnimEntry( animState, 0 );
	moveDelta = GetMoveDelta( traverseAnim, 0, 1 );

	scaleFactors = GetAnimScaleFactors( startToEnd, moveDelta );

	self ScrAgentSetPhysicsMode( "noclip" );

	// the end node is higher than the start node.  we can't use gravity to fall upward.  use lerp.
	if ( startToEnd[2] > 0 )
	{
		animLength = GetAnimLength( traverseAnim );
		self ScrAgentDoAnimLerp( startNode.origin, endNode.origin, animLength );

		self PlayAnimNUntilNotetrack( animState, 0, "traverse" );
	}
	else
	{
		gravityOnNotetracks = GetNotetrackTimes( traverseAnim, "gravity on" );
		if ( gravityOnNotetracks.size > 0 )
		{
			self ScrAgentSetAnimScale( scaleFactors.xy, 1 );
			self PlayAnimNUntilNotetrack( animState, 0, "traverse", "gravity on" );

			gravityOnMoveDelta = GetMoveDelta( traverseAnim, 0, gravityOnNotetracks[0] );
			zAnimDelta = gravityOnMoveDelta[2] - moveDelta[2];

			if ( abs( zAnimDelta ) > 0 )
			{
				zMeToEnd = self.origin[2] - endNode.origin[2];

				zScale = zMeToEnd / zAnimDelta;
				assert( zScale > 0 );

				self ScrAgentSetAnimScale( scaleFactors.xy, zScale );

				animrate = Clamp( 2 / zScale, 0.5, 1 );

				norestart = animState + "_norestart";
				self SetAnimState( norestart, 0, animrate );
			}

			self WaitUntilNotetrack( "traverse", "code_move" );
		}
		else
		{
			self ScrAgentSetAnimScale( scaleFactors.xy, scaleFactors.z );

			self PlayAnimNUntilNotetrack( animState, 0, "traverse" );
		}

		self ScrAgentSetAnimScale( 1, 1 );
	}
}

InitDogTraverseAnims()
{
	level.dogTraverseAnims = [];

	level.dogTraverseAnims[ "hjk_tree_hop" ]			= "traverse_jump_over_24";
	level.dogTraverseAnims[ "jump_across_72" ]			= "traverse_jump_over_24";
	level.dogTraverseAnims[ "wall_hop" ]				= "traverse_jump_over_36";
	level.dogTraverseAnims[ "window_2" ]				= "traverse_jump_over_36";
	level.dogTraverseAnims[ "wall_over_40" ]			= "traverse_jump_over_36";
	level.dogTraverseAnims[ "wall_over" ]				= "traverse_jump_over_36";
	level.dogTraverseAnims[ "window_divethrough_36" ]	= "traverse_jump_over_36";
	level.dogTraverseAnims[ "window_over_40" ]			= "traverse_jump_over_36";
	level.dogTraverseAnims[ "window_over_quick" ]		= "traverse_jump_over_36";
	level.dogTraverseAnims[ "jump_up_80" ]				= "traverse_jump_up_70";
	level.dogTraverseAnims[ "jump_down_80" ]			= "traverse_jump_down_70";
	level.dogTraverseAnims[ "jump_up_40" ]				= "traverse_jump_up_40";
	level.dogTraverseAnims[ "jump_down_40" ]			= "traverse_jump_down_40";
	level.dogTraverseAnims[ "step_up" ]					= "traverse_jump_up_24";
	level.dogTraverseAnims[ "step_down" ]				= "traverse_jump_down_24";
	level.dogTraverseAnims[ "jump_down" ]				= "traverse_jump_down_24";
	level.dogTraverseAnims[ "jump_across" ]				= "traverse_jump_over_36";
	level.dogTraverseAnims[ "jump_across_100" ]			= "traverse_jump_over_36";
}
