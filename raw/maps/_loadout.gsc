#include maps\_utility;
#include common_scripts\utility;
#include maps\_loadout_code;

init_loadout()
{
	if ( !IsDefined( level.Campaign ) )
		level.Campaign = "american";
	give_loadout();
	loadout_complete();
}

give_loadout()
{
	if ( IsDefined( level.dodgeloadout ) )
		return;
    loadout_name = get_loadout();
	level.player SetDefaultActionSlot();
	level.has_loadout = false;
	
	Campaign( "british" );
	
		 //   Levelname    PrevLoadout    secondary_offhand   
	Persist( "innocent", "london"	, "flash" );

		 //   Levelname 	    Starting_Weapon 				      Weapon2 	      Weapon3 		   Weapon4 	      Set_View_Model 		    Offhand_Secondary   
	LoadOut( "las_vegas"	 , "kriss"							   , "fraggrenade" , undefined		, undefined	   , "viewhands_gs_hostage"	 , undefined );
	LoadOut( "homecoming"	 , "sc2010+reflex_sp"					, "usp_no_knife", "fraggrenade"	, undefined	   , "viewhands_delta"		 , undefined );
	LoadOut( "ship_graveyard", "aps_underwater+swim"			   , undefined	   , undefined		, undefined	   , "viewhands_udt"		 , undefined );
	LoadOut( "jungle_ghosts" , "m4_silencer_reflex"					,"fraggrenade" , undefined		, undefined	   , "viewhands_gs_jungle", undefined );
	LoadOut( "deer_hunt"	 ,"acr_hybrid_silenced"					,"fraggrenade" , undefined		, undefined	   , "viewhands_sas_woodland", undefined );
	LoadOut( "london"		 , "mp5_silencer_eotech"			   , "fraggrenade" , "flash_grenade", undefined	   , "viewhands_sas"		 , "flash" );
	LoadOut( "innocent"		 , "mp5_silencer_eotech"			   , "usp_silencer", "flash_grenade", "fraggrenade", "viewhands_sas"		 , "flash" );
	
	Campaign( "delta" );
	
	
	/*
	 * FROM FIRING RANGE 3/21/2013
		//IW6 Weapons
	weaponslots = weaponadd("ak12",weaponslots);
	weaponslots = weaponadd("sc2010",weaponslots);
	weaponslots = weaponadd("kriss",weaponslots);
	weaponslots = weaponadd("pp19",weaponslots);
	weaponslots = weaponadd("m27",weaponslots);
	weaponslots = weaponadd("fp6",weaponslots);
	weaponslots = weaponadd("mk32",weaponslots);
	weaponslots = weaponadd("m9a1",weaponslots);
	weaponslots = weaponadd("vks",weaponslots);
	
	*/
	
		 //   Levelname     Starting_Weapon 			     Weapon2 								    Weapon3 	     Weapon4 	    Set_View_Model 				    Offhand_Secondary   
	LoadOut( "hamburg"	 , "m4m203_acog_payback"		  , "smaw_nolock"							 , "flash_grenade", "fraggrenade", "viewhands_delta"			 , "flash" );
	LoadOut( "prague"	 , "rsass_hybrid_silenced"		  , "usp_silencer"							 , "flash_grenade", "fraggrenade", "viewhands_yuri_europe"		 , "flash" );
	LoadOut( "payback"	 , "m4m203_acog_payback"		  , "deserteagle"							 , "flash_grenade", "fraggrenade", "viewhands_yuri"				 , "flash" );
	LoadOut( "black_ice" , "m4_grunt_reflex"			  , "p99_tactical"							 , "flash_grenade", "fraggrenade", "viewhands_ranger_dirty"		 , "flash" );
	LoadOut( "flood"	 , "cz805bren+reflex_sp"		  , "m9a1"									 , "flash_grenade", "fraggrenade", "viewhands_ranger_dirty_urban", "flash" );
	LoadOut( "clockwork" , "m14_scoped_silencer_arctic"	  , "ak47_silencer_reflex_iw6"				 , "flash_grenade", "fraggrenade", "viewhands_yuri"				 , "flash" );
	LoadOut( "factory"	 , "honeybadger+reflex_sp"		  , "uspflir2_silencer"						 , "flash_grenade", "fraggrenade", "viewmodel_base_viewhands"	 , "flash" );
	LoadOut( "cornered"	 , "imbel+acog_sp+silencer_sp"    , "kriss+eotechsmg_sp+silencer_sp"		 , "flash_grenade", "fraggrenade", "viewhands_sas"			     , "flash" );
	LoadOut( "nml"		 , "honeybadger+reflex_sp"		  , "l115a3+scopel115a3_sp+silencerl115a3_sp", "flash_grenade", "fraggrenade", "viewhands_ranger_dirty"		 , "flash" );
	LoadOut( "skyway"	 , "m4_grunt_reflex"			  , "p99_tactical"							 , "flash_grenade", "fraggrenade", "viewmodel_base_viewhands"	 , "flash" );
	LoadOut( "oilrocks"	 , "sc2010"						  , "m9a1"									 , "flash_grenade", "fraggrenade", "viewmodel_base_viewhands"	 , "flash" );
	LoadOut( "youngblood", "noweapon_youngblood"		  , undefined								 , undefined	  , undefined	 , "viewhands_gs_hostage"		 , undefined );
	LoadOut( "loki"		 , "kriss"						  , undefined								 , undefined	  , "fraggrenade", "viewhands_us_lunar"			 , "flash" );
	LoadOut( "odin"		 , "kriss_space"				  , undefined								 , undefined	  , undefined	 , "viewhands_us_lunar"			 , undefined );
	LoadOut( "prologue"	 , "noweapon_youngblood"		  , undefined								 , undefined	  , undefined	 , "viewhands_gs_hostage"		 , undefined );
	LoadOut( "carrier"	 , "honeybadger+acog_sp"		  , "m9a1"									 , "flash_grenade", "fraggrenade", "viewmodel_base_viewhands"	 , undefined );
	LoadOut( "satfarm"	 , "honeybadger+acog_sp"		  , "kriss+eotechsmg_sp"					 , "flash_grenade", "fraggrenade", "viewmodel_base_viewhands"	 , "flash" );
	LoadOut( "enemyhq"	 , "sc2010+acog_sp"				  , "deserteagle"							 , "flash_grenade", "fraggrenade", "viewmodel_base_viewhands"	 , undefined );
	default_loadout_if_notset();
}
