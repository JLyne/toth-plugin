#include <sourcemod>
#include <tf2_stocks>
#include <halflife>
#include <SteamWorks>
#include <smjansson>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1"
#define HOLOGRAM_MODEL "models/blap/cappoint_hologram.mdl"
#define CAMPAIGN_URL "https://tiltify.com/api/v3/campaigns/17129"

public Plugin myinfo = 
{
	name = "Toth stuff",
	author = "Jim",
	description = "Server tothification",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

enum DonationEntity {
	DEParent,
	Float:DEScale,
	ObjectiveType:DEType,

	//Ent references for 3 sets of digits
	DEDigits1,
	DEDigits2,
	DEDigits3,
	DEDigits4
}

enum ObjectiveType {
	ObjectiveType_None = 0,
	ObjectiveType_ControlPoint = 1,
	ObjectiveType_PayloadCart = 2,
	ObjectiveType_Intel = 3,
};

ArrayList gDuckModels;
ArrayList gDonationEntities;

Handle gDonationTimer = INVALID_HANDLE;
int gDonationTotal = 0;
int gLastMilestone = 0;

public void OnPluginStart() {
	gDuckModels = new ArrayList(PLATFORM_MAX_PATH);
	gDonationEntities = new ArrayList(view_as<int>(DonationEntity));

	gDuckModels.PushString("models/blap/bonus_blap.mdl");
	gDuckModels.PushString("models/blap/bonus_blap_2.mdl");
	gDuckModels.PushString("models/blap/bonus_blap_3.mdl");
	gDuckModels.PushString("models/blap/bonus_blap_4.mdl");

	HookEvent("teamplay_round_start", OnRoundStart);
}

public void OnPluginEnd() {
	for(int i = 0; i < gDonationEntities.Length; i++) {
		DonationEntity entity[DonationEntity];

		gDonationEntities.GetArray(i, entity[0], view_as<int>(DonationEntity));

		AcceptEntityInput(entity[DEDigits1], "Kill");
		AcceptEntityInput(entity[DEDigits2], "Kill");
		AcceptEntityInput(entity[DEDigits3], "Kill");
		AcceptEntityInput(entity[DEDigits4], "Kill");
	}
}

public void OnMapStart() {
	gDonationEntities.Clear();
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

	RequestFrame(FindResupplyCabinets);
	RequestFrame(FindObjectives);

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

void FindResupplyCabinets(any data) {
	int index = -1;
	
	//Add total to cabinet prop for each trigger
	while((index = FindEntityByClassname(index, "func_regenerate")) != -1) {
		int entity = GetEntPropEnt(index, Prop_Data, "m_hAssociatedModel");
		DonationEntity donationEntity[DonationEntity];

		SetupResupplyDonationEntities(entity, donationEntity);
		gDonationEntities.PushArray(donationEntity[0]);
	}
}


void FindObjectives(any data) {
	int index = -1;

	while((index = FindEntityByClassname(index, "team_control_point")) != -1) {
		PrepareControlPoint(index);
	}

	while((index = FindEntityByClassname(index, "item_teamflag")) != -1) {
		PrepareFlag(index);
	}

	while((index = FindEntityByClassname(index, "team_train_watcher")) != -1) {
		int train = GetEntPropEnt(index, Prop_Send, "m_hGlowEnt");

		PreparePayload(train);
	}
}

void SetupResupplyDonationEntities(int entity, DonationEntity donationEntity[DonationEntity]) {
	float origin[3]; //Position of entity center
	float angles[3]; //Entity rotation

	float mins[3]; //Entity bottom corner
	float maxs[3]; //Entity top corner

	float direction[3]; //Vector pointing towards corner
	
	float spritePosition[3]; //Calculated sprite position

	char scale[10];

	// int color[4] = {0, 255, 0, 255};

	//Get Stuff
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
	GetEntPropVector(entity, Prop_Send, "m_angRotation", angles);
	GetEntPropVector(entity, Prop_Send, "m_vecMins", mins);
	GetEntPropVector(entity, Prop_Send, "m_vecMaxs", maxs);

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

	donationEntity[DEParent] = entity;
	donationEntity[DEType] = ObjectiveType_None;
	donationEntity[DEScale] = 1.0;
	donationEntity[DEDigits1] = CreateDonationDigit(false);
	donationEntity[DEDigits2] = CreateDonationDigit(true);
	donationEntity[DEDigits3] = CreateDonationDigit(false);
	donationEntity[DEDigits4] = CreateDonationDigit(false, true);

	angles[2] += 90.0;
	angles[1] -= 180.0;

	ApplyMapTweaks(donationEntity, spritePosition, angles);

	Format(scale, sizeof(scale), "%00.2f", 0.25 * donationEntity[DEScale]);

	spritePosition[2] -= (38.0 * donationEntity[DEScale]);

	DispatchKeyValue(donationEntity[DEDigits1], "scale", scale);
	TeleportEntity(donationEntity[DEDigits1], spritePosition, angles, NULL_VECTOR);

	spritePosition[2] += (33.0 * donationEntity[DEScale]);

	DispatchKeyValue(donationEntity[DEDigits2], "scale", scale);
	TeleportEntity(donationEntity[DEDigits2], spritePosition, angles, NULL_VECTOR);

	spritePosition[2] += (33.0 * donationEntity[DEScale]);

	DispatchKeyValue(donationEntity[DEDigits3], "scale", scale);
	TeleportEntity(donationEntity[DEDigits3], spritePosition, angles, NULL_VECTOR);

	spritePosition[2] += (33.0 * donationEntity[DEScale]);

	DispatchKeyValue(donationEntity[DEDigits4], "scale", scale);
	TeleportEntity(donationEntity[DEDigits4], spritePosition, angles, NULL_VECTOR);

	SetVariantString("!activator");
	AcceptEntityInput(donationEntity[DEDigits1], "SetParent", entity, entity);
	SetVariantString("!activator");
	AcceptEntityInput(donationEntity[DEDigits2], "SetParent", entity, entity);
	SetVariantString("!activator");
	AcceptEntityInput(donationEntity[DEDigits3], "SetParent", entity, entity);
	SetVariantString("!activator");
	AcceptEntityInput(donationEntity[DEDigits4], "SetParent", entity, entity);
}

void SetupObjectiveDonationEntities(int entity, ObjectiveType type, DonationEntity donationEntity[DonationEntity]) {
	float spritePosition[3]; //Position of entity center
	float angles[3] = { 0.0, 90.0, 0.0 }; //Entity rotation
	char scale[10];

	//Get Stuff
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", spritePosition);

	donationEntity[DEParent] = entity;
	donationEntity[DEType] = type;
	donationEntity[DEScale] = 1.0;
	donationEntity[DEDigits1] = CreateDonationDigit(false);
	donationEntity[DEDigits2] = CreateDonationDigit(true);
	donationEntity[DEDigits3] = CreateDonationDigit(false);
	donationEntity[DEDigits4] = CreateDonationDigit(false, true);

	switch(type) {
		case ObjectiveType_ControlPoint :
		{
			//Position above control point hologram
			spritePosition[2] += 190.0;
		}

		case ObjectiveType_PayloadCart :
		{
			//Position above control point hologram
			spritePosition[2] += 50.0;
		}

		case ObjectiveType_Intel :
		{
			//Position above control point hologram
			spritePosition[2] += 30.0;
		}
	}
	
	ApplyMapTweaks(donationEntity, spritePosition, angles);

	Format(scale, sizeof(scale), "%00.2f", 0.25 * donationEntity[DEScale]);

	//Start to the left of the center
	spritePosition[0] += (30.0 * donationEntity[DEScale]); //22 30 34 40

	DispatchKeyValue(donationEntity[DEDigits1], "scale", scale);
	TeleportEntity(donationEntity[DEDigits1], spritePosition, angles, NULL_VECTOR);

	spritePosition[0] -= (33.0 * donationEntity[DEScale]);

	DispatchKeyValue(donationEntity[DEDigits2], "scale", scale);
	TeleportEntity(donationEntity[DEDigits2], spritePosition, angles, NULL_VECTOR);

	spritePosition[0] -= (33.0 * donationEntity[DEScale]);

	DispatchKeyValue(donationEntity[DEDigits3], "scale", scale);
	TeleportEntity(donationEntity[DEDigits3], spritePosition, angles, NULL_VECTOR);
	
	spritePosition[0] -= (33.0 * donationEntity[DEScale]);

	TeleportEntity(donationEntity[DEDigits4], spritePosition, angles, NULL_VECTOR);
	DispatchKeyValue(donationEntity[DEDigits4], "scale", scale);


	SetVariantString("!activator");
	AcceptEntityInput(donationEntity[DEDigits1], "SetParent", entity, entity);
	SetVariantString("!activator");
	AcceptEntityInput(donationEntity[DEDigits2], "SetParent", entity, entity);
	SetVariantString("!activator");
	AcceptEntityInput(donationEntity[DEDigits3], "SetParent", entity, entity);
	SetVariantString("!activator");
	AcceptEntityInput(donationEntity[DEDigits4], "SetParent", entity, entity);
}

void PrepareControlPoint(int entity) {
	entity = EntRefToEntIndex(entity);

	if(entity != INVALID_ENT_REFERENCE) {
		DonationEntity donationEntity[DonationEntity];

		DispatchKeyValue(entity, "team_model_3", HOLOGRAM_MODEL);
		DispatchKeyValue(entity, "team_model_2", HOLOGRAM_MODEL);
		DispatchKeyValue(entity, "team_model_0", HOLOGRAM_MODEL);
		SetEntityModel(entity, HOLOGRAM_MODEL);

		SetupObjectiveDonationEntities(entity, ObjectiveType_ControlPoint, donationEntity);
		int i = gDonationEntities.PushArray(donationEntity[0]);

		RequestFrame(ParentControlPointDonationEntities, i);
	}
}

void PrepareFlag(int entity) {
	DonationEntity donationEntity[DonationEntity];

	SetEntityModel(entity, "models/items/currencypack_large.mdl");

	float origin[3];

	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
	origin[2] -= 10.0;
	TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);

	SetupObjectiveDonationEntities(entity, ObjectiveType_Intel, donationEntity);
	gDonationEntities.PushArray(donationEntity[0]);
}

void PreparePayload(int entity) {
	DonationEntity donationEntity[DonationEntity];

	SetupObjectiveDonationEntities(entity, ObjectiveType_PayloadCart, donationEntity);
	gDonationEntities.PushArray(donationEntity[0]);
}

//TODO: Move to cfg
void ApplyMapTweaks(DonationEntity donationEntity[DonationEntity], float spritePosition[3], float spriteAngles[3]) {
	char map[32];
	char name[32];

	GetCurrentMap(map, sizeof(map));
	GetEntPropString(donationEntity[DEParent], Prop_Data, "m_iName", name, sizeof(name));

	if(StrEqual(map, "plr_bananabay") && donationEntity[DEType] == ObjectiveType_ControlPoint) {
		spritePosition[2] -= 75.0;
	}

	if(StrEqual(map, "pl_frontier_final") && donationEntity[DEType] == ObjectiveType_PayloadCart) {
		spritePosition[2] += 110.0;
	}

	if(StrEqual(name, "objective_train") && donationEntity[DEType] == ObjectiveType_PayloadCart) {
		donationEntity[DEScale] = 5.0;
		spritePosition[2] -= 75.0;
		spritePosition[0] -= 1775.0;
	}

	if(StrEqual(map, "cp_overgrown_rc5a") && donationEntity[DEType] == ObjectiveType_PayloadCart) {
		donationEntity[DEScale] = 2.0;
		spritePosition[1] -= 1750.0;
		spritePosition[2] -= 60.0;
	}

	if(StrEqual(map, "koth_traingrid_b2") && donationEntity[DEType] == ObjectiveType_PayloadCart) {
		spritePosition[2] += 55.0;
		donationEntity[DEScale] = 5.0;
	}

	if(StrEqual(map, "koth_conveyor_v2") && donationEntity[DEType] == ObjectiveType_ControlPoint) {
		spritePosition[2] -= 1450.0;
		donationEntity[DEScale] = 8.0;
	}

	if(StrEqual(map, "koth_weeeeeeeeeeeeeeeeell_rc2") && donationEntity[DEType] == ObjectiveType_PayloadCart) {
		spritePosition[2] += 40.0;
		donationEntity[DEScale] = 5.0;
	}
}

void ParentControlPointDonationEntities(any index) {
	DonationEntity donationEntity[DonationEntity];

	gDonationEntities.GetArray(index, donationEntity[0], view_as<int>(DonationEntity));
	
	SetVariantString("donations");
	AcceptEntityInput(donationEntity[DEDigits1], "SetParentAttachmentMaintainOffset");
	SetVariantString("donations");
	AcceptEntityInput(donationEntity[DEDigits2], "SetParentAttachmentMaintainOffset");
	SetVariantString("donations");
	AcceptEntityInput(donationEntity[DEDigits3], "SetParentAttachmentMaintainOffset");
	SetVariantString("donations");
	AcceptEntityInput(donationEntity[DEDigits4], "SetParentAttachmentMaintainOffset");
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
			UpdateDonationEntities();
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

public int UpdateDonationEntities() {
	float digits[4] = { 110.0, 110.0, 110.0, 110.0 };
	int divisor = 1;
	bool milestone = false;

	//Divide total into groups of 2 digits and work out which sprite frame to display for each
	for(int i = 0; i < 4; i++) {
		float amount = float((gDonationTotal / divisor) % 100);

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


	if((gDonationTotal - (gDonationTotal % 1000)) > gLastMilestone) {
		gLastMilestone = (gDonationTotal - (gDonationTotal % 1000));
		milestone = true;
	}

	for(int i = 0; i < gDonationEntities.Length; i++) {
		DonationEntity entity[DonationEntity];

		gDonationEntities.GetArray(i, entity[0], view_as<int>(DonationEntity));

		SetEntPropFloat(entity[DEDigits1], Prop_Send, "m_flFrame", digits[0]);
		SetEntPropFloat(entity[DEDigits2], Prop_Send, "m_flFrame", digits[1]);
		SetEntPropFloat(entity[DEDigits3], Prop_Send, "m_flFrame", digits[2]);
		SetEntPropFloat(entity[DEDigits4], Prop_Send, "m_flFrame", digits[3]);

		if(milestone) {
			char sound[PLATFORM_MAX_PATH];

			Format(sound, PLATFORM_MAX_PATH, "misc/happy_birthday_tf_%02i.wav", GetRandomInt(1, 29));

			EmitSoundToAll(sound, entity[DEDigits3]);
			TE_Particle("bday_confetti", NULL_VECTOR, NULL_VECTOR, NULL_VECTOR, entity[DEDigits2]);
		}
		
		TE_Particle("repair_claw_heal_blue", NULL_VECTOR, NULL_VECTOR, NULL_VECTOR, entity[DEDigits3]);
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