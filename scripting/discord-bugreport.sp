#include <sourcemod>
#include <discord>
#pragma newdecls required
#pragma semicolon 1


#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0.3"

char g_cCurrentMap[PLATFORM_MAX_PATH];

ConVar g_cvHostname;
ConVar g_cvWebhook;
ConVar g_cvBotName;
ConVar g_cvThumbnailUrl;
ConVar g_cvFooterUrl;
ConVar g_cvEmbedColor;

char g_cHostname[128];

public Plugin myinfo =  {
	name = "Bug Report Discord",
	author = "SaengerItsWar",
	description = "Sends a Bug Report to a discord channel over a webhook",
	version = PLUGIN_VERSION,
	url = "https://git.purple-horizon-clan.net/SaengerItsWar/Bug-Report"
};

public void OnPluginStart() {
	CreateConVar("sm_discord_bugreport_version", PLUGIN_VERSION, "Sends a Bug Report to a discord channel over a webhook", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cvWebhook = CreateConVar("sm_bugreport_webhook", "", "Webhook URL for the Discord channel", 0, false);
	g_cvThumbnailUrl = CreateConVar("sm_bugreport_thumbnail_url", "", "Thumbnail url to add a Picture of the Map the report was Created or leave blank to disable", 0, false);
	g_cvFooterUrl = CreateConVar("sm_bugreport_footer_url", "", "The url of the footer icon, leave blank to disable", 0, false);
	g_cvEmbedColor = CreateConVar("sm_bugreport_embed_color", "#00ffff", "Color of embed", 0, false);
	g_cvBotName = CreateConVar("sm_bugreport_botname", "", "Username of the Bot over the Webhook", 0, false);
	
	g_cvHostname = FindConVar("hostname");
	g_cvHostname.GetString( g_cHostname, sizeof( g_cHostname ) );
	g_cvHostname.AddChangeHook( OnConVarChanged );
	
	AutoExecConfig(true, "bug-report");	
	
	RegConsoleCmd("sm_bugreport", Command_bugreport, "Create a bug report");
	RegConsoleCmd("sm_bug", Command_bugreport, "Create a bug report");
}

public void OnConVarChanged( ConVar convar, const char[] oldValue, const char[] newValue ) {
	g_cvHostname.GetString( g_cHostname, sizeof( g_cHostname ) );
}

public void OnMapStart() {
	GetCurrentMap( g_cCurrentMap, sizeof g_cCurrentMap );
}

public Action Command_bugreport(int client, int args) {
	if (args < 1) {
		ReplyToCommand(client, "[\x04SM\x01] Usage:sm_bug <Bug Info>");
		return Plugin_Handled;
	}
	
	char sWebhook[512];
	char sEmbedColor[64];
	char sBotName[128];
	
	GetConVarString(g_cvWebhook, sWebhook, sizeof(sWebhook));
	GetConVarString(g_cvEmbedColor, sEmbedColor, sizeof(sEmbedColor));
	GetConVarString(g_cvBotName, sBotName, sizeof(sBotName));
	
	DiscordWebHook hook = new DiscordWebHook(sWebhook);
	hook.SlackMode = true;
	hook.SetUsername(sBotName);
	
	MessageEmbed embed = new MessageEmbed();
	
	embed.SetColor(sEmbedColor);
	
	char buffer[512]; 
	Format(buffer, sizeof(buffer), "__**New Bug Report**__ | **%s**", g_cCurrentMap);
	embed.SetTitle(buffer);
	
	char steamid[66];
	GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
	Format(buffer, sizeof(buffer), "[%N](http://www.steamcommunity.com/profiles/%s)", client, steamid);
	embed.AddField("Player:", buffer, true);
	
	char buginfo[256];
	GetCmdArg(1, buginfo, sizeof(buginfo));
	char bugmsg[256];
	GetCmdArgString(bugmsg, sizeof(bugmsg));
	Format(buffer, sizeof(buffer), "%s", bugmsg);
	embed.AddField("Report:", buffer, false);
	
	char sURL[1024]; 
	
	GetConVarString(g_cvThumbnailUrl, sURL, sizeof(sURL));
	
	if(!StrEqual(sURL, "")) {
		ReplaceString(sURL, sizeof(sURL), "${mapname}", g_cCurrentMap);
	}
	
	embed.SetThumb(sURL);
	
	char sFooterUrl[1024];
	GetConVarString(g_cvFooterUrl, sFooterUrl, sizeof(sFooterUrl));
	if (!StrEqual(sFooterUrl, ""))
	embed.SetFooterIcon(sFooterUrl);
	
	Format(buffer, sizeof(buffer), "Server: %s", g_cHostname);
	embed.SetFooter(buffer);
	
	hook.Embed(embed);
	hook.Send();
	
	ReplyToCommand(client, "[\x04BUG\x01] BUG Report has been Submitted");
	return Plugin_Handled;
}