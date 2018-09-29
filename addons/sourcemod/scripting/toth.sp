#include <sourcemod>
#include <regex>
#include <tf2_stocks>
#include <halflife>
#include <SteamWorks>
#include <smjansson>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.1"
#define HOLOGRAM_MODEL "models/toth/cappoint_hologram.mdl"
#define CAMPAIGN_URL "https://tiltify.com/api/v3/campaigns/17129"
#define _DEBUG 1

public Plugin myinfo = 
{
	name = "Toth stuff",
	author = "Jim",
	description = "Server tothification",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

//Represents an active donation total linked to an entity on the map
enum DonationDisplay {
	DDParent,
	Float:DDScale,
	Float:DDPosition[3],
	Float:DDRotation[3],
	EntityType:DDType,

	//Ent references for 4 sets of digits
	DDDigits[4],
}

enum ConfigEntry {
	String:CETargetname[64], //Entity targetname
	bool:CERegex, //Whether the targetname is a regex
	Float:CEScale, //Digit sprite scale
	Float:CEPosition[3], //Position relative to entity center
	Float:CERotation[3], //Rotation relative to entity angles
	//TODO: Rotation? Alignment?
}

enum ConfigRegex {
	Regex:CRRegex,
	String:CRConfigEntry[64],
}

enum EntityType {
	EntityType_None = 0,
	EntityType_ControlPoint = 1,
	EntityType_PayloadCart = 2,
	EntityType_Intel = 3,
	EntityType_Resupply = 4,
	EntityType_Custom = 5,
};

int gDonationTotal = 0;
int gDigitsRequired = 0;
int gLastMilestone = 0;

ArrayList gDuckModels;
ArrayList gDonationDisplays;

StringMap gConfigEntries;
ArrayList gConfigRegexes;

Handle gDonationTimer = INVALID_HANDLE;

#include <toth/config>

public void OnPluginStart() {
	gDuckModels = new ArrayList(PLATFORM_MAX_PATH);
	gDonationDisplays = new ArrayList(view_as<int>(DonationDisplay));
	gConfigEntries = new StringMap();
	gConfigRegexes = new ArrayList(view_as<int>(ConfigRegex));

	gDuckModels.PushString("models/toth/bonus_tip.mdl");
	gDuckModels.PushString("models/toth/bonus_tip_2.mdl");
	gDuckModels.PushString("models/toth/bonus_tip_3.mdl");
	gDuckModels.PushString("models/toth/bonus_tip_4.mdl");

	HookEvent("teamplay_round_start", OnRoundStart);
}

public void OnPluginEnd() {
	for(int i = 0; i < gDonationDisplays.Length; i++) {
		DonationDisplay entity[DonationDisplay];

		gDonationDisplays.GetArray(i, entity[0], view_as<int>(DonationDisplay));

		for(int j = 0; j < 4; j++) {
			AcceptEntityInput(entity[DDDigits][j], "Kill");
		}
	}
}

public void OnMapStart() {
	gDonationDisplays.Clear();
	gDonationTotal = 0;

	for(int i = 0; i < gDuckModels.Length; i++) {
		char model[PLATFORM_MAX_PATH];

		gDuckModels.GetString(i, model, PLATFORM_MAX_PATH);
		PrecacheModel(model);
		AddFileToDownloadsTable(model);
	}

	PrecacheModel("models/items/currencypack_large.mdl");
	PrecacheModel(HOLOGRAM_MODEL);
	AddFileToDownloadsTable(HOLOGRAM_MODEL);

	PrecacheGeneric("materials/toth/numbers.vmt");
	PrecacheGeneric("materials/toth/numbers.vtf");
	PrecacheGeneric("materials/toth/numbers-comma.vmt");
	PrecacheGeneric("materials/toth/numbers-comma.vtf");

	AddFileToDownloadsTable("materials/toth/numbers.vmt");
	AddFileToDownloadsTable("materials/toth/numbers.vtf");
	AddFileToDownloadsTable("materials/toth/numbers-comma.vmt");
	AddFileToDownloadsTable("materials/toth/numbers-comma.vtf");

	AddFileToDownloadsTable("materials/models/toth/cappoint_logo_blue.vtf");
	AddFileToDownloadsTable("materials/models/toth/cappoint_logo_red.vtf");
	AddFileToDownloadsTable("materials/models/toth/cappoint_logo_neutral.vtf");
	AddFileToDownloadsTable("materials/models/toth/cappoint_logo_blue.vmt");
	AddFileToDownloadsTable("materials/models/toth/cappoint_logo_blue_dark.vmt");
	AddFileToDownloadsTable("materials/models/toth/cappoint_logo_red.vmt");
	AddFileToDownloadsTable("materials/models/toth/cappoint_logo_red_dark.vmt");
	AddFileToDownloadsTable("materials/models/toth/cappoint_logo_neutral.vmt");
	AddFileToDownloadsTable("materials/models/toth/cappoint_logo_neutral_dark.vmt");
	
	AddFileToDownloadsTable("models/toth/bonus_tip.dx80.vtx");
	AddFileToDownloadsTable("models/toth/bonus_tip.dx90.vtx");
	AddFileToDownloadsTable("models/toth/bonus_tip.sw.vtx");
	AddFileToDownloadsTable("models/toth/bonus_tip.vvd");
	AddFileToDownloadsTable("models/toth/bonus_tip_2.dx80.vtx");
	AddFileToDownloadsTable("models/toth/bonus_tip_2.dx90.vtx");
	AddFileToDownloadsTable("models/toth/bonus_tip_2.sw.vtx");
	AddFileToDownloadsTable("models/toth/bonus_tip_2.vvd");
	AddFileToDownloadsTable("models/toth/bonus_tip_3.dx80.vtx");
	AddFileToDownloadsTable("models/toth/bonus_tip_3.dx90.vtx");
	AddFileToDownloadsTable("models/toth/bonus_tip_3.sw.vtx");
	AddFileToDownloadsTable("models/toth/bonus_tip_3.vvd");
	AddFileToDownloadsTable("models/toth/bonus_tip_4.dx80.vtx");
	AddFileToDownloadsTable("models/toth/bonus_tip_4.dx90.vtx");
	AddFileToDownloadsTable("models/toth/bonus_tip_4.sw.vtx");
	AddFileToDownloadsTable("models/toth/bonus_tip_4.vvd");
	AddFileToDownloadsTable("models/toth/cappoint_hologram.dx80.vtx");
	AddFileToDownloadsTable("models/toth/cappoint_hologram.dx90.vtx");
	AddFileToDownloadsTable("models/toth/cappoint_hologram.sw.vtx");
	AddFileToDownloadsTable("models/toth/cappoint_hologram.vvd");

	for(int i = 1; i <= 29; i++) {
		char sound[PLATFORM_MAX_PATH];
		Format(sound, PLATFORM_MAX_PATH, "misc/happy_birthday_tf_%02i.wav", i);
		PrecacheSound(sound);
	}

	LoadMapConfig();
	RequestFrame(FindMapEntities);

	ScheduleDonationRequest();
}

public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast) {
	bool full = event.GetBool("full_reset");

	if(full) {
		OnMapStart();
	}
}
	
public void OnEntityCreated(int entity, const char[] classname) {
	if(!strcmp(classname, "tf_bonus_duck_pickup", false)) {
		RequestFrame(SetDuckModel, EntIndexToEntRef(entity));
	}
}

public void SetDuckModel(any entity) {
	entity = EntRefToEntIndex(entity);

	if(entity != INVALID_ENT_REFERENCE) {
		int index = GetRandomInt(0, gDuckModels.Length -1);
		char model[PLATFORM_MAX_PATH];

		gDuckModels.GetString(index, model, PLATFORM_MAX_PATH);
		PrintToServer(model);

		SetEntityModel(entity, model);
		SetEntPropFloat(entity, Prop_Data, "m_flModelScale", 1.0);
	}
}

//Loops over map entities and creates donation displays on appropriate ones
void FindMapEntities(any unused) {
	ArrayList payloads = new ArrayList(32);
	ArrayList cabinets = new ArrayList();
	int index = -1;

	//Find payload trains
	while((index = FindEntityByClassname(index, "team_train_watcher")) != -1) {
		char name[32];
		GetEntPropString(index, Prop_Data, "m_iszTrain", name, sizeof(name));

		if(strlen(name)) {
			payloads.PushString(name);
		}
	}

	//Find resupply cabinet props
	while((index = FindEntityByClassname(index, "func_regenerate")) != -1) {
		cabinets.Push(GetEntPropEnt(index, Prop_Data, "m_hAssociatedModel"));
	}

	for(int i = MaxClients; i < GetMaxEntities(); i++) {
		if(!IsValidEntity(i)) {
			continue;
		}
	
		char name[32];
		char class[32];
		GetEntPropString(i, Prop_Data, "m_iName", name, sizeof(name));
		GetEntityClassname(i, class, 32);
		
		ConfigEntry configEntry[ConfigEntry];
		DonationDisplay donationDisplay[DonationDisplay];

		donationDisplay[DDParent] = i;

		//Check if entity has a config entry and use if so
		if(gConfigEntries.GetArray(name, configEntry[0], view_as<int>(ConfigEntry))) {
			#if defined _DEBUG
				PrintToServer("Entity %s has config entry", name);
			#endif

			donationDisplay[DDScale] = configEntry[CEScale];
			donationDisplay[DDType] = EntityType_Custom;
			
			donationDisplay[DDPosition][0] = configEntry[CEPosition][0];
			donationDisplay[DDPosition][1] = configEntry[CEPosition][1];
			donationDisplay[DDPosition][2] = configEntry[CEPosition][2];

			donationDisplay[DDRotation][0] = configEntry[CERotation][0];
			donationDisplay[DDRotation][1] = configEntry[CERotation][1];
			donationDisplay[DDRotation][2] = configEntry[CERotation][2];
		}

		//Check for regex matches and use it's config entry if matching
		for(int j = 0; j < gConfigRegexes.Length; j++) {
			ConfigRegex configRegex[ConfigRegex];
			gConfigRegexes.GetArray(j, configRegex[0], view_as<int>(ConfigRegex));

			if(configRegex[CRRegex].Match(name) > 0) {
				#if defined _DEBUG
					PrintToServer("Entity %s matched config regex", name);
				#endif

				gConfigEntries.GetArray(configRegex[CRConfigEntry], configEntry[0], view_as<int>(ConfigEntry));

				donationDisplay[DDScale] = configEntry[CEScale];
				donationDisplay[DDType] = EntityType_Custom;
				
				donationDisplay[DDPosition][0] = configEntry[CEPosition][0];
				donationDisplay[DDPosition][1] = configEntry[CEPosition][1];
				donationDisplay[DDPosition][2] = configEntry[CEPosition][2];

				donationDisplay[DDRotation][0] = configEntry[CERotation][0];
				donationDisplay[DDRotation][1] = configEntry[CERotation][1];
				donationDisplay[DDRotation][2] = configEntry[CERotation][2];
			}
		}

		//Reskin and setup display for control points
		if(StrEqual(class, "team_control_point", false)) {
			donationDisplay[DDType] = EntityType_ControlPoint;
			PrepareControlPoint(i);
		}

		//Reskin and setup display for intel
		if(StrEqual(class, "item_teamflag", false)) {
			donationDisplay[DDType] = EntityType_Intel;
			PrepareFlag(i);
		}

		//Payloads
		if(payloads.FindString(name) > -1) {
			donationDisplay[DDType] = EntityType_PayloadCart;
		}

		//Resupply cabinets
		if(cabinets.FindValue(i) > -1) {
			donationDisplay[DDType] = EntityType_Resupply;			
		}

		//If entity should have a donation display create it
		if(donationDisplay[DDType] != EntityType_None) {
			#if defined _DEBUG
				PrintToServer("Entity %s has donation display of type %d", name, donationDisplay[DDType]);
			#endif

			SetupDonationDisplay(i, donationDisplay);
		}
	}
}

void SetupDonationDisplay(int entity, DonationDisplay donationDisplay[DonationDisplay]) {
	if(!donationDisplay[DDParent]) {
		donationDisplay[DDParent] = entity;
	}

	if(!donationDisplay[DDScale]) {
		donationDisplay[DDScale] = 1.0;
	}

	donationDisplay[DDDigits][0] = CreateDonationDigit(false);
	donationDisplay[DDDigits][1] = CreateDonationDigit(true);
	donationDisplay[DDDigits][2] = CreateDonationDigit(false);
	donationDisplay[DDDigits][3] = CreateDonationDigit(false, true);

	PositionDonationDisplay(donationDisplay);

	for(int i = 0; i < 4; i++) {
		SetVariantString("!activator");
		AcceptEntityInput(donationDisplay[DDDigits][i], "SetParent", donationDisplay[DDParent], donationDisplay[DDParent]);
	}

	int index = gDonationDisplays.PushArray(donationDisplay[0]);

	if(donationDisplay[DDType] == EntityType_ControlPoint) {
		RequestFrame(ParentControlPointDonationEntities, index);
	}
}

void PositionDonationDisplay(DonationDisplay donationDisplay[DonationDisplay]) {
	float position[3]; //Entity origin
	float angles[3]; //Entity rotation

	float offset[3]; //Offset from entity origin to use for positioning sprite
	float rotationOffset[3]; 
	float displayPosition[3]; //Final sprite position

	float firstDigitOffset = 30.0 * donationDisplay[DDScale]; //Initial offset before first digit to roughly "center" the display around the desired position
	float digitSpacing = 33.0 * donationDisplay[DDScale]; //Spacing between digits

	char scale[10];

	GetEntPropVector(donationDisplay[DDParent], Prop_Send, "m_vecOrigin", position);
	GetEntPropVector(donationDisplay[DDParent], Prop_Send, "m_angRotation", angles);

	switch(donationDisplay[DDType]) {
		case EntityType_Resupply :
		{
			rotationOffset[1] += 180.0;
			rotationOffset[2] += 90.0;
			offset[2] += 52.0;
			offset[1] -= 34.0;
			offset[0] += 14.0;
			PrintToServer("%f %f %f", angles[0], angles[1], angles[2]);
		}

		//Position above control point hologram
		case EntityType_ControlPoint :
		{
			rotationOffset[1] += 90.0;
			offset[2] += 190.0;
		}

		//Position above control point hologram
		case EntityType_PayloadCart :
		{
			rotationOffset[1] += 90.0;
			offset[2] += 75.0;
		}
		
		//Position above control point hologram
		case EntityType_Intel :
			offset[2] += 30.0;
	}

	//Add position offset from config
	offset[0] += donationDisplay[DDPosition][0];
	offset[1] += donationDisplay[DDPosition][1];
	offset[2] += donationDisplay[DDPosition][2];

	//Add rotation offset from config
	rotationOffset[0] += donationDisplay[DDRotation][0];
	rotationOffset[1] += donationDisplay[DDRotation][1];
	rotationOffset[2] += donationDisplay[DDRotation][2];

	//Angle vectors
	float fwd[3];
	float right[3];
	float up[3];
	
	GetAngleVectors(angles, fwd, right, up);

	ScaleVector(fwd, offset[0]);
	ScaleVector(right, offset[1]);
	ScaleVector(up, offset[2]);

	AddVectors(position, fwd, displayPosition);
	AddVectors(displayPosition, right, displayPosition);
	AddVectors(displayPosition, up, displayPosition);

	//Apply rotation offset
	AddVectors(angles, rotationOffset, angles);
	GetAngleVectors(angles, fwd, right, up);

	//Add first digit offset for centering
	ScaleVector(right, firstDigitOffset);
	AddVectors(displayPosition, right, displayPosition);

	//Position each digit
	for(int i = 0; i < 4; i++) {		
		if(i) {
			NormalizeVector(right, right); //Reset distance
			ScaleVector(right, digitSpacing);
			SubtractVectors(displayPosition, right, displayPosition);
		}

		DispatchKeyValue(donationDisplay[DDDigits][i], "scale", scale);
		TeleportEntity(donationDisplay[DDDigits][i], displayPosition, angles, NULL_VECTOR);
	}
	//22 30 34 40
}

void PrepareControlPoint(int entity) {
	entity = EntRefToEntIndex(entity);

	if(entity != INVALID_ENT_REFERENCE) {
		DispatchKeyValue(entity, "team_model_3", HOLOGRAM_MODEL);
		DispatchKeyValue(entity, "team_model_2", HOLOGRAM_MODEL);
		DispatchKeyValue(entity, "team_model_0", HOLOGRAM_MODEL);
		SetEntityModel(entity, HOLOGRAM_MODEL);
	}
}

void PrepareFlag(int entity) {
	SetEntityModel(entity, "models/items/currencypack_large.mdl");

	float origin[3];

	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
	origin[2] -= 10.0;
	TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);
}

void ParentControlPointDonationEntities(any index) {
	DonationDisplay donationDisplay[DonationDisplay];

	gDonationDisplays.GetArray(index, donationDisplay[0], view_as<int>(DonationDisplay));

	for(int i = 0; i < 4; i++) {
		SetVariantString("donations");
		AcceptEntityInput(donationDisplay[DDDigits][i], "SetParentAttachmentMaintainOffset");
	}
}

int CreateDonationDigit(bool comma, bool startBlank = false) {
	int entity = CreateEntityByName("env_sprite_oriented");

	if(comma) {
		DispatchKeyValue(entity, "model", "toth/numbers-comma.vmt");
	} else {
		DispatchKeyValue(entity, "model", "toth/numbers.vmt");
	}

	DispatchKeyValue(entity, "framerate", "0");
	DispatchKeyValue(entity, "spawnflags", "1");
	DispatchKeyValue(entity, "scale", "0.25");
	
	SetEntityRenderMode(entity, RENDER_TRANSALPHAADD);

	DispatchSpawn(entity);
	AcceptEntityInput(entity, "ShowSprite");
	SetVariantFloat(244.0);
	AcceptEntityInput(entity, "ColorRedValue");
	SetVariantFloat(116.0);
	AcceptEntityInput(entity, "ColorGreenValue");
	SetVariantFloat(37.0);
	AcceptEntityInput(entity, "ColorBlueValue");

	if(startBlank) {
		SetEntPropFloat(entity, Prop_Data, "m_flFrame", 110.0);
		SetEntPropFloat(entity, Prop_Send, "m_flFrame", 110.0);
	} else {
		SetEntPropFloat(entity, Prop_Data, "m_flFrame", 113.0);
		SetEntPropFloat(entity, Prop_Send, "m_flFrame", 113.0);
	}

	SetEntPropFloat(entity, Prop_Send, "m_flGlowProxySize", 64.0);
	SetEntPropFloat(entity, Prop_Data, "m_flGlowProxySize", 64.0);
	SetEntPropFloat(entity, Prop_Send, "m_flHDRColorScale", 1.0);
	SetEntPropFloat(entity, Prop_Data, "m_flHDRColorScale", 1.0);

	return EntIndexToEntRef(entity);
}

void ScheduleDonationRequest() {
	if(gDonationTimer != INVALID_HANDLE) {
		KillTimer(gDonationTimer);
	}

	#if defined _DEBUG
	PrintToServer("Scheduling donation request");
	#endif

	gDonationTimer = CreateTimer(5.0, MakeDonationRequest);
}

public Action MakeDonationRequest(Handle timer, any data) {
	#if defined _DEBUG
	PrintToServer("Making donation request");
	#endif

	Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, CAMPAIGN_URL);

	SteamWorks_SetHTTPRequestHeaderValue(request, "Authorization", "Bearer d19ceb915b719fb02a1cdc5cc60c3d8ee73cd4d69f067db138d93320595e08f1");

	SteamWorks_SetHTTPCallbacks(request, OnTotalRequestCompleted);

	if(!SteamWorks_SendHTTPRequest(request)) {
		LogError("Donation total HTTP request failed");
		ScheduleDonationRequest();
	}

	gDonationTimer = INVALID_HANDLE;
	return Plugin_Stop;
}

public int OnTotalRequestCompleted(Handle request, bool failure, bool successful, EHTTPStatusCode eStatusCode) {
	ScheduleDonationRequest();

	if(!successful || eStatusCode != k_EHTTPStatusCode200OK) {
		LogError("Donation total HTTP request failed %d");

	} else {
		int size;

		SteamWorks_GetHTTPResponseBodySize(request, size);

		char[] sBody = new char[size];

		SteamWorks_GetHTTPResponseBodyData(request, sBody, size);

		int newTotal = ParseTotalJsonResponse(sBody);

		if(newTotal > 0 && newTotal != gDonationTotal) {
			gDonationTotal = newTotal;
			UpdateDonationDisplays();
		}
	}

	CloseHandle(request);
}

public int ParseTotalJsonResponse(const char[] json) {
	Handle parsed = json_load(json);

	if(parsed == INVALID_HANDLE) {
		LogError("Invalid json (failed to parse)");

		return -1;
	}

	Handle data = json_object_get(parsed, "data");

	if(data == INVALID_HANDLE) {
		LogError("Invalid json (data object missing)");

		return -1;
	}

	int total = RoundToFloor(json_object_get_float(data, "amountRaised"));

	if(!total) {
		LogError("Invalid json (invalid total)");

		return -1;
	}

	CloseHandle(parsed);
	CloseHandle(data);

	return total;
}

public int UpdateDonationDisplays() {
	float digits[4] = { 110.0, 110.0, 110.0, 110.0 };
	int divisor = 1;
	int digitsRequired = 0;
	bool milestone = false;

	//Divide total into groups of 2 digits and work out which sprite frame to display for each
	for(int i = 0; i < 4; i++) {
		float amount = float((gDonationTotal / divisor) % 100);
		digitsRequired++;

		if(!amount && gDonationTotal < divisor) { //Total is below the range of this digit, display $ sign and skip the rest
			digits[i] = 111.0; //111th frame is empty
			break;
		} else if((amount && amount < 10.0) && (gDonationTotal < (divisor * 100))) { //Total is within range but only uses one of the 2 numbers, display with $ sign
			digits[i] = amount + 100.0; //Frames 100 - 109 are single numbers with dollar signs
			break;
		} else { //Total uses both numbers within this digit, display normally
			digits[i] = amount;
		}

		divisor *= 100;
	}

	if(digitsRequired != gDigitsRequired) {

	}

	if((gDonationTotal - (gDonationTotal % 1000)) > gLastMilestone) {
		gLastMilestone = (gDonationTotal - (gDonationTotal % 1000));
		milestone = true;
	}

	for(int i = 0; i < gDonationDisplays.Length; i++) {
		DonationDisplay entity[DonationDisplay];

		gDonationDisplays.GetArray(i, entity[0], view_as<int>(DonationDisplay));

		for(int j = 0; j < 4; j++) {
			SetEntPropFloat(entity[DDDigits][j], Prop_Send, "m_flFrame", digits[j]);
		}

		if(milestone) {
			char sound[PLATFORM_MAX_PATH];

			Format(sound, PLATFORM_MAX_PATH, "misc/happy_birthday_tf_%02i.wav", GetRandomInt(1, 29));

			EmitSoundToAll(sound, entity[DDDigits][2]);
			TE_Particle("bday_confetti", NULL_VECTOR, NULL_VECTOR, NULL_VECTOR, entity[DDDigits][1]);
		}
		
		TE_Particle("repair_claw_heal_blue", NULL_VECTOR, NULL_VECTOR, NULL_VECTOR, entity[DDDigits][2]);
	}
}

void TE_Particle(char[] Name, float origin[3]=NULL_VECTOR, float start[3]=NULL_VECTOR, float angles[3]=NULL_VECTOR, int entindex=-1, int attachtype=-1, int attachpoint=-1, bool resetParticles=true, float delay=0.0) {
    // find string table
    int tblidx = FindStringTable("ParticleEffectNames");

    if(tblidx == INVALID_STRING_TABLE) {
        LogError("Could not find string table: ParticleEffectNames");
        return;
    }
    
    // find particle index
    char tmp[256];
    
    int count = GetStringTableNumStrings(tblidx);
    int stridx = INVALID_STRING_INDEX;
    int i;

    for(i = 0; i < count; i++) {
        ReadStringTable(tblidx, i, tmp, sizeof(tmp));
        
        if(StrEqual(tmp, Name, false)) {
            stridx = i;
            break;
        }
    }

    if(stridx == INVALID_STRING_INDEX) {
        LogError("Could not find particle: %s", Name);
        return;
    }
    
    TE_Start("TFParticleEffect");
    TE_WriteFloat("m_vecOrigin[0]", origin[0]);
    TE_WriteFloat("m_vecOrigin[1]", origin[1]);
    TE_WriteFloat("m_vecOrigin[2]", origin[2]);
    TE_WriteFloat("m_vecStart[0]", start[0]);
    TE_WriteFloat("m_vecStart[1]", start[1]);
    TE_WriteFloat("m_vecStart[2]", start[2]);
    TE_WriteVector("m_vecAngles", angles);
    TE_WriteNum("m_iParticleSystemIndex", stridx);
   
    if(entindex != -1) {
        TE_WriteNum("entindex", entindex);
    }

    if(attachtype!=-1) {
        TE_WriteNum("m_iAttachType", attachtype);
    }

    if(attachpoint!=-1) {
        TE_WriteNum("m_iAttachmentPointIndex", attachpoint);
    }

    TE_WriteNum("m_bResetParticles", resetParticles ? 1 : 0);    
    TE_SendToAll(delay);
}