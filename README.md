# toth-plugin
Sourcemod plugin for TOTH 2018. Displays donation total ingame among other things.

## Features

* Displays donation totals on resupply cabinets, and all main objective types. Visiblity, positon, scale and rotation can be changed in the config, and new displays can also be added. Donation total is fetched from a socket server which uses the TOTH donation repeater, falling back to HTTP requests to tipofthehats.org/stats if this is unavailable.
* Control points are reskinned with the TOTH logo
* EOTL ducks dropped by players are reskinned to one of several past TOTH medals

## Cvars

* `toth_ducks_enabled` - Whether dropped ducks are reskinned
* `toth_cps_enabled` - Whether control points are reskinned. Disabling this will also disable control point donation display rotation, as the attachment point used for this is part of the custom model.
* `toth_donations_enabled` - Whether donation displays are created and shown.

## Commands
* `sm_reloadtoth` - Reloads the config file and recreates donation displays.

## License

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/ or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
