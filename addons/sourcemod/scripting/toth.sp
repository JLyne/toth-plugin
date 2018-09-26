#include <sourcemod>
#include <tf2_stocks>
#include <halflife>
#include <SteamWorks>
#include <smjansson>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.1"
#define HOLOGRAM_MODEL "models/blap/cappoint_hologram.mdl"
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
	EntityType:DDType,

	//Ent references for 4 sets of digits
	DDDigits1,
	DDDigits2,
	DDDigits3,
	DDDigits4
}

enum ConfigEntry {
	String:CETargetname[64], //Entity targetname
	Float:CEScale, //Digit sprite scale
	Float:CEPosition[3], //Position relative to entity center
	//TODO: Rotation? Alignment?
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

Handle gDonationTimer = INVALID_HANDLE;

#include <toth/config>

public void OnPluginStart() {
	gDuckModels = new ArrayList(PLATFORM_MAX_PATH);
	gDonationDisplays = new ArrayList(view_as<int>(DonationDisplay));
	gConfigEntries = new StringMap();

	gDuckModels.PushString("models/blap/bonus_blap.mdl");
	gDuckModels.PushString("models/blap/bonus_blap_2.mdl");
	gDuckModels.PushString("models/blap/bonus_blap_3.mdl");
	gDuckModels.PushString("models/blap/bonus_blap_4.mdl");

	HookEvent("teamplay_round_start", OnRoundStart);
}

public void OnPluginEnd() {
	for(int i = 0; i < gDonationDisplays.Length; i++) {
		DonationDisplay entity[DonationDisplay];

		gDonationDisplays.GetArray(i, entity[0], view_as<int>(DonationDisplay));

		AcceptEntityInput(entity[DDDigits1], "Kill");
		AcceptEntityInput(entity[DDDigits2], "Kill");
		AcceptEntityInput(entity[DDDigits3], "Kill");
		AcceptEntityInput(entity[DDDigits4], "Kill");
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

	PrecacheModel(HOLOGRAM_MODEL);
	PrecacheModel("models/items/currencypack_large.mdl");
	AddFileToDownloadsTable(HOLOGRAM_MODEL);

	PrecacheGeneric("materials/blap/numbers.vmt");
	PrecacheGeneric("materials/blap/numbers.vtf");
	PrecacheGeneric("materials/blap/numbers-comma.vmt");
	PrecacheGeneric("materials/blap/numbers-comma.vtf");

	AddFileToDownloadsTable("materials/blap/numbers.vmt");
	AddFileToDownloadsTable("materials/blap/numbers.vtf");
	AddFileToDownloadsTable("materials/blap/numbers-comma.vmt");
	AddFileToDownloadsTable("materials/blap/numbers-comma.vtf");

	AddFileToDownloadsTable("materials/models/blap/cappoint_logo_blue.vtf");
	AddFileToDownloadsTable("materials/models/blap/cappoint_logo_red.vtf");

	AddFileToDownloadsTable("materials/models/effects/blap_cappoint_logo_blue.vmt");
	AddFileToDownloadsTable("materials/models/effects/blap_cappoint_logo_blue_dark.vmt");
	AddFileToDownloadsTable("materials/models/effects/blap_cappoint_logo_red.vmt");
	AddFileToDownloadsTable("materials/models/effects/blap_cappoint_logo_red_dark.vmt");
	
	AddFileToDownloadsTable("models/blap/blapature_bonus_duck.dx80.vtx");
	AddFileToDownloadsTable("models/blap/bonus_blap_3.dx80.vtx");
	AddFileToDownloadsTable("models/blap/bonus_blap.dx80.vtx");
	AddFileToDownloadsTable("models/blap/blapature_bonus_duck.dx90.vtx");
	AddFileToDownloadsTable("models/blap/bonus_blap_3.dx90.vtx");
	AddFileToDownloadsTable("models/blap/bonus_blap.dx90.vtx");
	AddFileToDownloadsTable("models/blap/blapature_bonus_duck.mdl");
	AddFileToDownloadsTable("models/blap/bonus_blap_3.mdl");
	AddFileToDownloadsTable("models/blap/bonus_blap.mdl");
	AddFileToDownloadsTable("models/blap/blapature_bonus_duck.sw.vtx");
	AddFileToDownloadsTable("models/blap/bonus_blap_3.sw.vtx");
	AddFileToDownloadsTable("models/blap/bonus_blap.phy");
	AddFileToDownloadsTable("models/blap/blapature_bonus_duck.vvd");
	AddFileToDownloadsTable("models/blap/bonus_blap_3.vvd");
	AddFileToDownloadsTable("models/blap/bonus_blap.sw.vtx");
	AddFileToDownloadsTable("models/blap/bonus_blap_2.dx80.vtx");
	AddFileToDownloadsTable("models/blap/bonus_blap_4.dx80.vtx");
	AddFileToDownloadsTable("models/blap/bonus_blap.vvd");
	AddFileToDownloadsTable("models/blap/bonus_blap_2.dx90.vtx");
	AddFileToDownloadsTable("models/blap/bonus_blap_4.dx90.vtx");
	AddFileToDownloadsTable("models/blap/cappoint_hologram.dx80.vtx");
	AddFileToDownloadsTable("models/blap/bonus_blap_2.mdl");
	AddFileToDownloadsTable("models/blap/bonus_blap_4.mdl");
	AddFileToDownloadsTable("models/blap/cappoint_hologram.dx90.vtx");
	AddFileToDownloadsTable("models/blap/bonus_blap_2.phy");
	AddFileToDownloadsTable("models/blap/bonus_blap_4.phy");
	AddFileToDownloadsTable("models/blap/cappoint_hologram.mdl");
	AddFileToDownloadsTable("models/blap/bonus_blap_2.sw.vtx");
	AddFileToDownloadsTable("models/blap/bonus_blap_4.sw.vtx");
	AddFileToDownloadsTable("models/blap/cappoint_hologram.sw.vtx");
	AddFileToDownloadsTable("models/blap/bonus_blap_2.vvd");
	AddFileToDownloadsTable("models/blap/bonus_blap_4.vvd");
	AddFileToDownloadsTable("models/blap/cappoint_hologram.vvd");

	AddFileToDownloadsTable("materials/blap/numbers-comma.vtf");
	AddFileToDownloadsTable("materials/blap/numbers-comma.vtf");

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

		SetEntityModel(entity, model);
		SetEntPropFloat(entity, Prop_Data, "m_flModelScale", 1.0);
	}
}

//Loops over map entities and creates donation displays on appropriate ones
void FindMapEntities(any unused) {
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
			donationDisplay[DDPosition][0] = configEntry[CEPosition][0];
			donationDisplay[DDPosition][1] = configEntry[CEPosition][1];
			donationDisplay[DDPosition][2] = configEntry[CEPosition][2];
			donationDisplay[DDType] = EntityType_Custom;
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

		//Setup display on train prop for payload train watchers
		if(StrEqual(class, "team_train_watcher", false)) {
			int train = GetEntPropEnt(i, Prop_Send, "m_hGlowEnt");

			donationDisplay[DDParent] = train;
			donationDisplay[DDType] = EntityType_PayloadCart;
		}

		//Setup display on cabinet propp for resupply areas
		if(StrEqual(class, "func_regenerate", false)) {
			int prop = GetEntPropEnt(i, Prop_Data, "m_hAssociatedModel");

			donationDisplay[DDParent] = prop;
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

	donationDisplay[DDDigits1] = CreateDonationDigit(false);
	donationDisplay[DDDigits2] = CreateDonationDigit(true);
	donationDisplay[DDDigits3] = CreateDonationDigit(false);
	donationDisplay[DDDigits4] = CreateDonationDigit(false, true);

	PositionDonationDisplay(donationDisplay);

	SetVariantString("!activator");
	AcceptEntityInput(donationDisplay[DDDigits1], "SetParent", donationDisplay[DDParent], donationDisplay[DDParent]);
	SetVariantString("!activator");
	AcceptEntityInput(donationDisplay[DDDigits2], "SetParent", donationDisplay[DDParent], donationDisplay[DDParent]);
	SetVariantString("!activator");
	AcceptEntityInput(donationDisplay[DDDigits3], "SetParent", donationDisplay[DDParent], donationDisplay[DDParent]);
	SetVariantString("!activator");
	AcceptEntityInput(donationDisplay[DDDigits4], "SetParent", donationDisplay[DDParent], donationDisplay[DDParent]);

	int index = gDonationDisplays.PushArray(donationDisplay[0]);

	if(donationDisplay[DDType] == EntityType_ControlPoint) {
		RequestFrame(ParentControlPointDonationEntities, index);
	}
}

void PositionDonationDisplay(DonationDisplay donationDisplay[DonationDisplay]) {
	float spritePosition[3]; //Position of entity center
	float angles[3] = { 0.0, 90.0, 0.0 }; //Entity rotation
	char scale[10];

	GetEntPropVector(donationDisplay[DDParent], Prop_Send, "m_vecOrigin", spritePosition);

	switch(donationDisplay[DDType]) {
		case EntityType_Resupply :
		{
			PositionResupplyDonationDisplay(donationDisplay);
			return;
		}

		case EntityType_ControlPoint :
		{
			//Position above control point hologram
			spritePosition[2] += 190.0;
		}

		case EntityType_PayloadCart :
		{
			//Position above control point hologram
			spritePosition[2] += 75.0;
		}

		case EntityType_Intel :
		{
			//Position above control point hologram
			spritePosition[2] += 30.0;
		}
	}

	Format(scale, sizeof(scale), "%00.2f", 0.25 * donationDisplay[DDScale]);

	//Add position offset from config
	spritePosition[0] += donationDisplay[DDPosition][0];
	spritePosition[1] += donationDisplay[DDPosition][1];
	spritePosition[2] += donationDisplay[DDPosition][2];

	//Start to the left of the center
	spritePosition[0] += (30.0 * donationDisplay[DDScale]); //22 30 34 40

	DispatchKeyValue(donationDisplay[DDDigits1], "scale", scale);
	TeleportEntity(donationDisplay[DDDigits1], spritePosition, angles, NULL_VECTOR);

	spritePosition[0] -= (33.0 * donationDisplay[DDScale]);

	DispatchKeyValue(donationDisplay[DDDigits2], "scale", scale);
	TeleportEntity(donationDisplay[DDDigits2], spritePosition, angles, NULL_VECTOR);

	spritePosition[0] -= (33.0 * donationDisplay[DDScale]);

	DispatchKeyValue(donationDisplay[DDDigits3], "scale", scale);
	TeleportEntity(donationDisplay[DDDigits3], spritePosition, angles, NULL_VECTOR);
	
	spritePosition[0] -= (33.0 * donationDisplay[DDScale]);

	TeleportEntity(donationDisplay[DDDigits4], spritePosition, angles, NULL_VECTOR);
	DispatchKeyValue(donationDisplay[DDDigits4], "scale", scale);
}

void PositionResupplyDonationDisplay(DonationDisplay donationDisplay[DonationDisplay]) {
	float origin[3]; //Position of entity center
	float angles[3]; //Entity rotation

	float mins[3]; //Entity bottom corner
	float maxs[3]; //Entity top corner

	float direction[3]; //Vector pointing towards corner
	
	float spritePosition[3]; //Calculated sprite position

	char scale[10];

	// int color[4] = {0, 255, 0, 255};

	//Get Stuff
	GetEntPropVector(donationDisplay[DDParent], Prop_Send, "m_vecOrigin", origin);
	GetEntPropVector(donationDisplay[DDParent], Prop_Send, "m_angRotation", angles);
	GetEntPropVector(donationDisplay[DDParent], Prop_Send, "m_vecMins", mins);
	GetEntPropVector(donationDisplay[DDParent], Prop_Send, "m_vecMaxs", maxs);

	//Point towards corner
	angles[1] += 65.0;

	//Get corner position by calculating hypotenuse length of the mins triangle
	GetAngleVectors(angles, direction, NULL_VECTOR, NULL_VECTOR);	
	ScaleVector(direction, SquareRoot(Pow(-16.0, 2.0) + Pow(-32.0, 2.0)));
	AddVectors(origin, direction, spritePosition);

	//Revert angle changes for later use
	angles[1] -= 65.0;

	//Add half the the entity height to get half way point
	spritePosition[2] += ((FloatAbs(mins[2]) + FloatAbs(maxs[2])) / 2);

	angles[2] += 90.0;
	angles[1] -= 180.0;

	Format(scale, sizeof(scale), "%00.2f", 0.25 * donationDisplay[DDScale]);

	spritePosition[2] -= (38.0 * donationDisplay[DDScale]);

	DispatchKeyValue(donationDisplay[DDDigits1], "scale", scale);
	TeleportEntity(donationDisplay[DDDigits1], spritePosition, angles, NULL_VECTOR);

	spritePosition[2] += (33.0 * donationDisplay[DDScale]);

	DispatchKeyValue(donationDisplay[DDDigits2], "scale", scale);
	TeleportEntity(donationDisplay[DDDigits2], spritePosition, angles, NULL_VECTOR);

	spritePosition[2] += (33.0 * donationDisplay[DDScale]);

	DispatchKeyValue(donationDisplay[DDDigits3], "scale", scale);
	TeleportEntity(donationDisplay[DDDigits3], spritePosition, angles, NULL_VECTOR);

	spritePosition[2] += (33.0 * donationDisplay[DDScale]);

	DispatchKeyValue(donationDisplay[DDDigits4], "scale", scale);
	TeleportEntity(donationDisplay[DDDigits4], spritePosition, angles, NULL_VECTOR);
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
	
	SetVariantString("donations");
	AcceptEntityInput(donationDisplay[DDDigits1], "SetParentAttachmentMaintainOffset");
	SetVariantString("donations");
	AcceptEntityInput(donationDisplay[DDDigits2], "SetParentAttachmentMaintainOffset");
	SetVariantString("donations");
	AcceptEntityInput(donationDisplay[DDDigits3], "SetParentAttachmentMaintainOffset");
	SetVariantString("donations");
	AcceptEntityInput(donationDisplay[DDDigits4], "SetParentAttachmentMaintainOffset");
}

int CreateDonationDigit(bool comma, bool startBlank = false) {
	int entity = CreateEntityByName("env_sprite_oriented");

	if(comma) {
		DispatchKeyValue(entity, "model", "blap/numbers-comma.vmt");
	} else {
		DispatchKeyValue(entity, "model", "blap/numbers.vmt");
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
		LogError("Donation total HTTP request failed");

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

		SetEntPropFloat(entity[DDDigits1], Prop_Send, "m_flFrame", digits[0]);
		SetEntPropFloat(entity[DDDigits2], Prop_Send, "m_flFrame", digits[1]);
		SetEntPropFloat(entity[DDDigits3], Prop_Send, "m_flFrame", digits[2]);
		SetEntPropFloat(entity[DDDigits4], Prop_Send, "m_flFrame", digits[3]);

		if(milestone) {
			char sound[PLATFORM_MAX_PATH];

			Format(sound, PLATFORM_MAX_PATH, "misc/happy_birthday_tf_%02i.wav", GetRandomInt(1, 29));

			EmitSoundToAll(sound, entity[DDDigits3]);
			TE_Particle("bday_confetti", NULL_VECTOR, NULL_VECTOR, NULL_VECTOR, entity[DDDigits2]);
		}
		
		TE_Particle("repair_claw_heal_blue", NULL_VECTOR, NULL_VECTOR, NULL_VECTOR, entity[DDDigits3]);
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