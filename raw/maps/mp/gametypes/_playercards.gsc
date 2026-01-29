#include common_scripts\utility;
#include maps\mp\_utility;


init()
{	
	level thread onPlayerConnect();
}


onPlayerConnect()
{
	for(;;)
	{
		level waittill( "connected", player );

		//@NOTE: Should we make sure they're really unlocked before setting them? Catch cheaters...
		//			e.g. isItemUnlocked( iconHandle )

		iconIndex = player getCommonPlayerData( "cardIcon" );
		iconHandle = TableLookupByRow( "mp/cardIconTable.csv", iconIndex, 0 );
		player SetCardIcon( iconHandle );
		
		titleIndex = player getCommonPlayerData( "cardTitle" );
		titleHandle = TableLookupByRow( "mp/cardTitleTable.csv", titleIndex, 0 );
		player SetCardTitle( titleHandle );
		
		nameplateHandle = player getCommonPlayerData( "cardNameplate" );
		player SetCardNameplate( nameplateHandle );
	}
}