#pragma semicolon 1
#include <sourcemod>

#pragma newdecls required
#include <smrpg>

#define UPGRADE_SHORTNAME "Conversion"
#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
	name = "SM:RPG Upgrade > Conversion ",
	author = "WanekWest",
	description = "Conversion allows the player to turn excess money into credits.",
	version = PLUGIN_VERSION,
	url = "https://vk.com/wanek_west"
}

ConVar g_hCvMoneyConvertType, g_hCvMoneyConvertRequestMoney
		, g_hCvMoneyConvertIncreaserPerLevel, g_hCvMoneyConvertAmountToCheck;

int hCvMoneyConvertType, hCvMoneyConvertRequestMoney, hCvMoneyConvertAmountToCheck;
float hCvMoneyConvertIncreaserPerLevel;

public void OnPluginStart()
{
	LoadTranslations("smrpg_stock_upgrades.phrases");

	HookEvent("player_spawn", Event_OnPlayerSpawn);
}

public void OnPluginEnd()
{
	if(SMRPG_UpgradeExists(UPGRADE_SHORTNAME))
		SMRPG_UnregisterUpgradeType(UPGRADE_SHORTNAME);
}

public void OnAllPluginsLoaded()
{
	OnLibraryAdded("smrpg");
}

public void OnLibraryAdded(const char[] name)
{
	// Register this upgrade in SM:RPG
	if(StrEqual(name, "smrpg"))
	{
		// Register the upgrade type.
		SMRPG_RegisterUpgradeType("Conversion", UPGRADE_SHORTNAME, "Conversion allows the player to turn excess money into credits.", 10, true, 5, 15, 10);
		SMRPG_SetUpgradeTranslationCallback(UPGRADE_SHORTNAME, SMRPG_TranslateUpgrade);

		g_hCvMoneyConvertType = SMRPG_CreateUpgradeConVar(UPGRADE_SHORTNAME, "smrpg_conversion_type", "0", "Conversion type. 0 - to EXP, 1 - to Credits", _, true, 0.0);
		g_hCvMoneyConvertType.AddChangeHook(OnConverChangeType);
		hCvMoneyConvertType = g_hCvMoneyConvertType.IntValue;

		g_hCvMoneyConvertRequestMoney = SMRPG_CreateUpgradeConVar(UPGRADE_SHORTNAME, "smrpg_conversion_request_money", "100", "How many credits to take for 1 unit of Experience/Credits.", _, true, 0.0);
		g_hCvMoneyConvertRequestMoney.AddChangeHook(OnConverChangeReqMoney);
		hCvMoneyConvertRequestMoney = g_hCvMoneyConvertRequestMoney.IntValue;

		g_hCvMoneyConvertIncreaserPerLevel = SMRPG_CreateUpgradeConVar(UPGRADE_SHORTNAME, "smrpg_conversion_increase", "2.0", "Increase value per level.", _, true, 0.0);
		g_hCvMoneyConvertIncreaserPerLevel.AddChangeHook(OnConverChangeIncreaseValue);
		hCvMoneyConvertIncreaserPerLevel = g_hCvMoneyConvertIncreaserPerLevel.FloatValue;

		g_hCvMoneyConvertAmountToCheck = SMRPG_CreateUpgradeConVar(UPGRADE_SHORTNAME, "smrpg_conversion_increase", "16000", "Amount of min money value for check(If put 100 user must have 101).", _, true, 0.0);
		g_hCvMoneyConvertAmountToCheck.AddChangeHook(OnConverChangeAmountToCheck);
		hCvMoneyConvertAmountToCheck = g_hCvMoneyConvertAmountToCheck.IntValue;
	}
}

public void OnConverChangeType(ConVar hCvar, const char[] szOldValue, const char[] szNewValue)
{
	hCvMoneyConvertType = hCvar.IntValue;
}

public void OnConverChangeReqMoney(ConVar hCvar, const char[] szOldValue, const char[] szNewValue)
{
	hCvMoneyConvertRequestMoney = hCvar.IntValue;
}

public void OnConverChangeIncreaseValue(ConVar hCvar, const char[] szOldValue, const char[] szNewValue)
{
	hCvMoneyConvertIncreaserPerLevel = hCvar.FloatValue;
}

public void OnConverChangeAmountToCheck(ConVar hCvar, const char[] szOldValue, const char[] szNewValue)
{
	hCvMoneyConvertAmountToCheck = hCvar.IntValue;
}

// The core wants to display your upgrade somewhere. Translate it into the clients language!
public void SMRPG_TranslateUpgrade(int client, const char[] shortname, TranslationType type, char[] translation, int maxlen)
{
	// Easy pattern is to use the shortname of your upgrade in the translation file
	if(type == TranslationType_Name)
		Format(translation, maxlen, "%T", UPGRADE_SHORTNAME, client);
	// And "shortname description" as phrase in the translation file for the description.
	else if(type == TranslationType_Description)
	{
		char sDescriptionKey[MAX_UPGRADE_SHORTNAME_LENGTH+12] = UPGRADE_SHORTNAME;
		StrCat(sDescriptionKey, sizeof(sDescriptionKey), " description");
		Format(translation, maxlen, "%T", sDescriptionKey, client);
	}
}

public void Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!client)
		return;

	int currentClientMoney = GetEntProp(client, Prop_Send, "m_iAccount");
	if (currentClientMoney > hCvMoneyConvertAmountToCheck)
	{
		// SM:RPG is disabled?
		if(!SMRPG_IsEnabled())
			return;
		
		// The upgrade is disabled completely?
		if(!SMRPG_IsUpgradeEnabled(UPGRADE_SHORTNAME))
			return;
		
		// Are bots allowed to use this upgrade?
		if(IsFakeClient(client) && SMRPG_IgnoreBots())
			return;
		
		// Player didn't buy this upgrade yet.
		int iLevel = SMRPG_GetClientUpgradeLevel(client, UPGRADE_SHORTNAME);
		if(iLevel <= 0)
			return;
		
		int amountToGive = RoundToCeil((currentClientMoney - 16000) / hCvMoneyConvertRequestMoney * hCvMoneyConvertIncreaserPerLevel);
		SetEntProp(client, Prop_Send, "m_iAccount", 16000);

		if (hCvMoneyConvertType == 0)
			SMRPG_AddClientExperience(client, amountToGive, "Convertion", false, -1);
		else
			SMRPG_SetClientCredits(client, SMRPG_GetClientCredits(client) + amountToGive);
	}

	return;
}