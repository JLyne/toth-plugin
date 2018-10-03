void InitDonationSocket() {
	if(gSocket[SSocket] != INVALID_HANDLE && SocketIsConnected(gSocket[SSocket])) {
		return;
	}

	//Cancel any fallback requests
	if(gFallbackTimer != INVALID_HANDLE) {
		KillTimer(gFallbackTimer);
		gFallbackTimer = INVALID_HANDLE;
	}

	#if defined _DEBUG
	LogMessage("Socket: Connecting");
	#endif
	
	gSocket[SAttempts]++;
	gSocket[SSocket] = SocketCreate(SOCKET_TCP, OnSocketError);
	SocketConnect(gSocket[SSocket], OnSocketConnected, OnSocketReceive, OnSocketDisconnected, SOCKET_HOST, SOCKET_PORT);
}

public Action RetryDonationSocket(Handle timer, any data) {
	//Fallback to HTTP if cannot connect repeatedly
	if(gSocket[SAttempts] == 3) {
		LogError("Socket: 3 failed attempts, falling back to HTTP for now.");
		ScheduleDonationRequest(true);
		return;	
	}

	gSocket[SAttempts] = 0;

	InitDonationSocket();
}

public int OnSocketConnected(Handle socket, any arg) {
	#if defined _DEBUG
	LogMessage("Socket: Connected");
	#endif
}

public int OnSocketError(Handle socket, const int errorType, const int errorNum, any arg) {
	LogError("Socket: Error %d %d", errorType, errorNum);
	CloseHandle(socket);
	gSocket[SSocket] = INVALID_HANDLE;
	CreateTimer(3.0, RetryDonationSocket);
}

public int OnSocketReceive(Handle socket, const char[] receiveData, const int dataSize, any arg) {
	Handle parsed = json_load(receiveData);
	char newTotal[16];
	int total;

	if(parsed == INVALID_HANDLE) {
		LogError("Socket: Invalid json (failed to parse)");
		return;
	}

	if(json_object_get_string(parsed, "newTotal", newTotal, sizeof(newTotal)) == -1) {
		LogError("Socket: Invalid json (invalid total)");
		CloseHandle(parsed);

		return;
	}

	CloseHandle(parsed);
	total = RoundToFloor(StringToFloat(newTotal));

	if(total > gDonationTotal) {
		#if defined _DEBUG
		LogMessage("Socket: New total received %d", total);
		#endif

		gSocket[SAttempts] = 0;
		gDonationTotal = total;
		UpdateDonationDisplays();
	}
}

public int OnSocketDisconnected(Handle socket, any arg) {
	#if defined _DEBUG
	LogMessage("Socket: Disconnected");
	#endif

	CloseHandle(socket);
	gSocket[SSocket] = INVALID_HANDLE;
	CreateTimer(3.0, RetryDonationSocket);
}
