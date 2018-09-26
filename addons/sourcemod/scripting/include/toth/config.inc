
stock bool LoadMapConfig() {
	char map[50];
	char configPath[PLATFORM_MAX_PATH];
	KeyValues config = new KeyValues("toth");
	bool opened;

	GetCurrentMap(map, sizeof(map));

	BuildPath(Path_SM, configPath, PLATFORM_MAX_PATH, "configs/toth.cfg");

	opened = config.ImportFromFile(configPath);

	if(!opened) {
		//SetFailState("Failed to load config file addons/sourcemod/configs/toth.cfg");

		return false;
	}

	if(config.JumpToKey(map, false)) {
		config.GotoFirstSubKey(false);
		ParseMapConfig(config);
	} else {
		return false;
	}

	return true;
}

stock void ParseMapConfig(KeyValues kv) {
	do {
		char keyName[64];

		kv.GetSectionName(keyName, 64);

		ConfigEntry configEntry[ConfigEntry];

		kv.GotoFirstSubKey(false);
		ParseEntityConfig(kv, configEntry);
		kv.GoBack();

		strcopy(configEntry[CETargetname], 64, keyName);

		gConfigEntries.SetArray(keyName, configEntry[0], view_as<int>(ConfigEntry), true);
	} while(kv.GotoNextKey(false));
}

stock void ParseEntityConfig(KeyValues kv, ConfigEntry configEntry[ConfigEntry]) {
	do {
		char keyName[50];

		kv.GetSectionName(keyName, 50);

		if(StrEqual(keyName, "scale", false)) {
			configEntry[CEScale] = kv.GetFloat(NULL_STRING, 1.0);
			continue;
		}

		if(StrEqual(keyName, "position", false)) {
			float position[3];

			kv.GetVector(NULL_STRING, position, NULL_VECTOR);

			configEntry[CEPosition][0] = position[0];
			configEntry[CEPosition][1] = position[1];
			configEntry[CEPosition][2] = position[2];

			continue;
		}
	} while(kv.GotoNextKey(false));
}
