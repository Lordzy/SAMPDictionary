/*
________________________________________________________________________________

			SAMPDictionary - English Dictionary System For SA-MP
						        By
							  Lordzy

Version : 1.0
MySQL English Dictionary (.sql) file by x16bkkamz6rkb78 AKA "john smith".
Download -
http://sourceforge.net/p/mysqlenglishdictionary/code/ci/master/tree/dictionaryStudyTool.sql?format=raw

Thanks to :
x16bkkamz6rkb78 	- For dictionary database.
BlueG & maddinat0r 	- For MySQL plugin.
ZeeX                - For zcmd.
________________________________________________________________________________    */


#define FILTERSCRIPT

#include <a_samp>
#include <a_mysql>
#include <zcmd>


#define         SQL_HOST          		"change"
#define         SQL_USER                "change"
#define         SQL_PASS                ""
#define         SQL_DATA                ""

#define         PRONOUNCE_WORD          1 		//Set it to 0 if you don't want word to be pronounced at first.
#define         DIALOG_ID_DICTIONARY    12767 	//Change if it collides with your current dialogs.


new
	g_DictionaryHandle,
	g_PlayerSearchCounts[MAX_PLAYERS char],
	g_PlayerSearchWord[MAX_PLAYERS][32]
;
	
public OnFilterScriptInit() {

	g_DictionaryHandle = mysql_connect(SQL_HOST, SQL_USER, SQL_DATA, SQL_PASS);
	if(mysql_errno(g_DictionaryHandle) != 0) {
	
	    print("Failed loading Dictionary system! (Connection to the database failed)");
		return 1;
	}
	for(new i = 0, j = GetMaxPlayers(); i< j; i++) {
	
	    if(!IsPlayerConnected(i)) continue;
	    OnPlayerConnect(i);
	}
	print("____________________________________________________\n");
	print("\tSAMPDictionary v1.0 loaded!");
	print("____________________________________________________");
	
	return 1;
}

public OnFilterScriptExit() {

	mysql_close(g_DictionaryHandle);
	print("SAMPDictionary v1.0 unloaded!");
	
	return 1;
}

public OnPlayerConnect(playerid) {

	g_PlayerSearchCounts{playerid} = 0;
	return 1;
}

CMD:dictionary(playerid, params[]) {

	if(isnull(params))
			return SendClientMessage(playerid, 0xFF0000FF, "USAGE : /dictionary [word]");

	new
	    temp_Query[100];

	g_PlayerSearchCounts{playerid} = 1;
	strcat((g_PlayerSearchWord[playerid][0] = '\0', g_PlayerSearchWord[playerid]), params, 32);
	
	mysql_format(g_DictionaryHandle, temp_Query, sizeof(temp_Query),
	    "SELECT `definition` FROM `entries` WHERE `word`='%e' LIMIT 0,5", params);
	mysql_tquery(g_DictionaryHandle, temp_Query, "OnDictionaryResponse", "is", playerid, params);

	return 1;
}

forward OnDictionaryResponse(playerid, word[]);

public OnDictionaryResponse(playerid, word[]) {

	new
	    temp_Counts = cache_get_row_count(g_DictionaryHandle);

	if(temp_Counts) {

	    new
	        temp_dString[2000],
	        temp_Definition[500] //Some definitions are large.
		;
		
	#if PRONOUNCE_WORD == 1
		if(g_PlayerSearchCounts{playerid} == 1) {
		
			format(temp_Definition, sizeof(temp_Definition), "http://translate.google.com/translate_tts?tl=en&q=%s",
			    word);
			PlayAudioStreamForPlayer(playerid, temp_Definition);
			temp_Definition[0] = '\0';
		}

	#endif
		format(temp_dString, sizeof(temp_dString), "{F2C80C}%s\n", word);
		for(new i = 0; i < ((temp_Counts > 4) ? 4 : temp_Counts); i++) {
		
			cache_get_row(i, 0, temp_Definition, g_DictionaryHandle, sizeof(temp_Definition));
			format(temp_dString, sizeof(temp_dString), "%s\n\n{F2C80C}#%d. {FFFFFF}%s", temp_dString, i + g_PlayerSearchCounts{playerid}, temp_Definition);
		}
		ShowPlayerDialog(playerid, DIALOG_ID_DICTIONARY, DIALOG_STYLE_MSGBOX, "SAMPDictionary", temp_dString,
		    "Okay", (temp_Counts > 4) ? ("Next") : (""));
		g_PlayerSearchCounts{playerid} += 4;
	}
	else {
	
	    if(g_PlayerSearchCounts{playerid} == 1)
	        SendClientMessage(playerid, 0xFF0000FF, "ERROR : The searched word could not be found in the dictionary!");
	}
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]) {

	if(dialogid == DIALOG_ID_DICTIONARY) {
	
	    if(!response) {

			if(g_PlayerSearchCounts{playerid} < 4)
			    return 1;
	        new
	            temp_Query[100];

			mysql_format(g_DictionaryHandle, temp_Query, sizeof(temp_Query),
			"SELECT `definition` FROM `entries` WHERE `word`='%e' LIMIT %d,5",
			    g_PlayerSearchWord[playerid], g_PlayerSearchCounts{playerid});
			mysql_tquery(g_DictionaryHandle, temp_Query, "OnDictionaryResponse", "is",
				playerid, g_PlayerSearchWord[playerid]);

			return 1;
		}
		else {
		
		    g_PlayerSearchCounts{playerid} = 0;
		    return 1;
		}
	}
	return 1;
}


	    
