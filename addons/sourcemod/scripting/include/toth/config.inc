stock bool CheckMapConfig() {
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

		ConfigEntity configEntity[ConfigEntity];

		kv.GotoFirstSubKey(false);
		ParseEntityConfig(kv, configEntity);
		kv.GoBack();

		strcopy(configEntity[CWTargetname], 64, keyName);

		gConfigEntitys.SetArray(keyName, configEntity[0], view_as<int>(ConfigEntity), true);
	} while(kv.GotoNextKey(false));
}

stock void ParseEntityConfig(KeyValues kv, ConfigEntity configEntity[ConfigEntity]) {
	do {
		char keyName[50];

		kv.GetSectionName(keyName, 50);

		if(StrEqual(keyName, "name", false)) {
			kv.GetString(NULL_STRING, configEntity[CDEName], 64, "");

			continue;
		}

		// if(StrEqual(keyName, "defindex", false)) {
		// 	configEntity[CWDefindex] = kv.GetNum(NULL_STRING, 0);

		// 	continue;
		// }
	} while(kv.GotoNextKey(false));
}
