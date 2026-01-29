init()
{
}

updateDamageFeedback( typeHit )
{
	if( !IsPlayer( self ) )
		return;

	switch( typeHit )
	{
	case "scavenger":
		self PlayLocalSound( "scavenger_pack_pickup" );		
		if( !level.hardcoreMode )
			self SetDamageFeedback( GetIndexForLuiNCString( typeHit ) );
		break;
	
	case "hitblastshield":
	case "hitlightarmor":
	case "hitjuggernaut":
	case "hitmorehealth":
	case "hitmotionsensor":
		self PlayLocalSound( "MP_hit_alert" );	
		self SetDamageFeedback( GetIndexForLuiNCString( typeHit ) );
		break;

	case "none":
		break;

	default:
		self PlayLocalSound( "MP_hit_alert" );	
		self SetDamageFeedback( GetIndexForLuiNCString( "standard" ) );
		break;
	}
}