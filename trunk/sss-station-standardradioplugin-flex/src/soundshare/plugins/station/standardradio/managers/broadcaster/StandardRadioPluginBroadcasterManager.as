package soundshare.plugins.station.standardradio.managers.broadcaster
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import socket.client.base.ClientSocketUnit;
	import socket.client.events.FlashSocketClientEvent;
	import socket.json.JSONFacade;
	
	import soundshare.station.data.StationContext;
	import soundshare.station.data.channels.ChannelContext;
	import soundshare.station.data.channels.RemoteChannelContext;
	import soundshare.plugins.station.standardradio.broadcaster.StandardRadioBroadcaster;
	import soundshare.plugins.station.standardradio.broadcaster.StandardRadioRemoteController;
	import soundshare.plugins.station.standardradio.broadcaster.StandardRadioRemoteListener;
	import soundshare.plugins.station.standardradio.broadcaster.events.StandardRadioRemoteControllerEvent;
	import soundshare.plugins.station.standardradio.broadcaster.events.StandardRadioRemoteListenerEvent;
	import soundshare.plugins.station.standardradio.managers.broadcaster.events.StandardRadioPluginBroadcasterManagerEvent;
	import soundshare.sdk.controllers.connection.client.ClientConnection;
	import soundshare.sdk.controllers.connection.client.events.ClientConnectionEvent;
	import soundshare.sdk.data.BroadcastServerContext;
	import soundshare.sdk.data.SoundShareContext;
	import soundshare.sdk.data.plugin.PluginData;
	import soundshare.sdk.data.servers.ServerData;
	import soundshare.sdk.db.mongo.base.events.MongoDBRestEvent;
	import soundshare.sdk.db.mongo.channels.ChannelsDataManager;
	import soundshare.sdk.db.mongo.playlists.loader.PlaylistsLoader;
	import soundshare.sdk.db.mongo.playlists.loader.events.PlaylistsLoaderEvent;
	import soundshare.sdk.managers.connections.server.ConnectionsManager;
	import soundshare.sdk.managers.connections.server.events.ConnectionsManagerEvent;
	import soundshare.sdk.managers.plugins.PluginsManager;
	import soundshare.sdk.managers.plugins.events.PluginsManagerEvent;
	import soundshare.sdk.managers.servers.ServersManager;
	import soundshare.sdk.managers.servers.events.ServersManagerEvent;
	import soundshare.sdk.managers.stations.StationsManager;
	import soundshare.sdk.managers.stations.events.StationsManagerEvent;
	import soundshare.sdk.plugins.manager.IPluginManager;
	import soundshare.sdk.plugins.manager.events.PluginManagerEvent;
	
	import utils.collection.CollectionUtil;
	
	public class StandardRadioPluginBroadcasterManager extends EventDispatcher implements IPluginManager
	{
		public static const NONE_STATE:String = "";
		
		public static const PREPARE_STATE:String = "PREPARE_STATE";
		public static const PREPARE_COMPLETE_STATE:String = "PREPARE_COMPLETE_STATE";
		
		public static const CREATE_BROADCAST_STATE:String = "CREATE_BROADCAST_STATE";
		public static const CREATE_BROADCAST_COMPLETE_STATE:String = "CREATE_BROADCAST_COMPLETE_STATE";
		
		private var stationContext:StationContext;
		private var _pluginData:PluginData;
		
		private var playlistsLoader:PlaylistsLoader;
		
		private var connectionsManager:ConnectionsManager;
		private var connection:ClientConnection;
		
		private var serverData:ServerData = new ServerData();
		
		private var state:String = NONE_STATE;
		
		private var broadcaster:StandardRadioBroadcaster;
		private var bsContext:BroadcastServerContext;
		
		private var stationsManager:StationsManager;
		private var targetRoutingMap:Object;
		
		private var playlistId:String;
		
		private var _channelContext:ChannelContext;
		
		private var _local:Boolean = false;
		private var _remote:Boolean = false;
		
		private var _playlist:Array;
		
		private var requestPluginsManager:PluginsManager;
		private var serverRequestPluginsManager:PluginsManager;
		
		private var serversManager:ServersManager;
		
		private var remoteController:StandardRadioRemoteController = new StandardRadioRemoteController();
		private var remoteListener:StandardRadioRemoteListener = new StandardRadioRemoteListener();
		
		private var tmpChannelContext:ChannelContext= new ChannelContext();
		private var activateChannelsDataManager:ChannelsDataManager;
		private var deactivateChannelsDataManager:ChannelsDataManager;
		
		public function StandardRadioPluginBroadcasterManager()
		{
			super();
			
			remoteController = new StandardRadioRemoteController();
			
			remoteListener = new StandardRadioRemoteListener();
			remoteListener.addEventListener(StandardRadioRemoteListenerEvent.PLAY, onPlaySong);
			remoteListener.addEventListener(StandardRadioRemoteListenerEvent.STOP, onStopSong);
			remoteListener.addEventListener(StandardRadioRemoteListenerEvent.PREVIOUS, onPreviousSong);
			remoteListener.addEventListener(StandardRadioRemoteListenerEvent.NEXT, onNextSong);
			remoteListener.addEventListener(StandardRadioRemoteListenerEvent.CHANGE_PLAY_ORDER, onChangePlayOrder);
			remoteListener.addEventListener(StandardRadioRemoteListenerEvent.DESTROY, onDestroy);
			
			broadcaster = new StandardRadioBroadcaster();
		}
		
		public function prepare(data:Object = null):void
		{
			trace("StandardRadioPluginBroadcasterManager[prepare]:", data ? JSONFacade.stringify(data) : "NULL");
			
			if (state == NONE_STATE)
			{
				state == PREPARE_STATE;
				_remote = data && data.remote ? true : false;
				
				if (!_remote)
					prepareBroadcast(); // PREPARE BROADCAST
				else 
					prepareRemoteBroadcast(data); // PREPARE REMOTE BROADCAST
			}
			else
			{
				destroy();
				dispatchEvent(new PluginManagerEvent(PluginManagerEvent.ERROR, null, "Unable to create plugin broadcast.", 200));
			}
		}
		
		// ********************************************************************************************************************************************
		//													PREPARE BROADCAST
		// ********************************************************************************************************************************************
		
		private function prepareBroadcast():void
		{
			trace("StandardRadioPluginBroadcasterManager[prepareBroadcast]:");
			
			_local = false;
			_channelContext = stationContext.selectedChannel;
			
			stationsManager = context.stationsManagersBuilder.build();
			stationsManager.addSocketEventListener(StationsManagerEvent.START_WATCH_COMPLETE, onStartWatchComplete);
			stationsManager.addSocketEventListener(StationsManagerEvent.START_WATCH_ERROR, onStartWatchError);
			stationsManager.startWatchStations([channelContext.stationId]);
			
			/*if (stationContext.stationData._id != channelContext.stationId) 
			{
			// REMOTE BROADCAST
			_local = false;
			
			stationsManager = context.stationsManagersBuilder.build();
			stationsManager.addSocketEventListener(StationsManagerEvent.START_WATCH_COMPLETE, onStartWatchComplete);
			stationsManager.addSocketEventListener(StationsManagerEvent.START_WATCH_ERROR, onStartWatchError);
			stationsManager.startWatchStations([channelContext.stationId]);
			}
			else 
			{
			// LOCAL BROADCAST
			_local = true;
			loadPlaylists();
			}*/
		}
		
		private function onStartWatchComplete(e:StationsManagerEvent):void
		{
			stationsManager.removeSocketEventListener(StationsManagerEvent.START_WATCH_COMPLETE, onStartWatchComplete);
			stationsManager.removeSocketEventListener(StationsManagerEvent.START_WATCH_ERROR, onStartWatchError);
			
			var stationsReport:Object = e.data.stationsReport;
			
			trace("1.--StandardRadioPluginBroadcasterManager[onStartWatchComplete]-", stationsReport, stationsReport ? stationsReport[channelContext.stationId] : "SHITT");
			
			if (stationsReport && stationsReport[channelContext.stationId])
			{
				trace("2.--StandardRadioPluginBroadcasterManager[onStartWatchComplete]-", stationsReport);
				targetRoutingMap = stationsReport[channelContext.stationId].routingMap;
				dispatchEvent(new StationsManagerEvent(StationsManagerEvent.STATION_UP_DETECTED, e.data));
			}
			else
			{
				targetRoutingMap = null;
				dispatchEvent(new StationsManagerEvent(StationsManagerEvent.STATION_DOWN_DETECTED, e.data));
			}
			
			stationsManager.addSocketEventListener(StationsManagerEvent.STATION_UP_DETECTED, onStationUpDetected);
			stationsManager.addSocketEventListener(StationsManagerEvent.STATION_DOWN_DETECTED, onStationDownDetected);
			
			playlistsLoader = context.playlistsLoaderBuilder.build();
			playlistsLoader.addEventListener(PlaylistsLoaderEvent.PLAYLISTS_COMPLETE, onPlaylistsForRemoteComplete);
			playlistsLoader.addEventListener(PlaylistsLoaderEvent.PLAYLISTS_ERROR, onPlaylistsForRemoteError);
			playlistsLoader.load(channelContext.plugin.configuration.playlists as Array);
		}
		
		private function onStartWatchError(e:StationsManagerEvent):void
		{
			trace("--StandardRadioPluginBroadcasterManager[onStartWatchError]-");
			
			context.stationsManagersBuilder.destroy(stationsManager);
			stationsManager = null;
			
			reset();
			dispatchEvent(new PluginManagerEvent(PluginManagerEvent.ERROR, null, "Station error please try again.", 101));
		}
		
		private function onStationUpDetected(e:StationsManagerEvent):void
		{
			trace("--StandardRadioPluginBroadcasterManager[onLoginDetected]-");
			
			targetRoutingMap = e.data.routingMap;
			dispatchEvent(new StationsManagerEvent(StationsManagerEvent.STATION_UP_DETECTED, e.data));
		}
		
		private function onStationDownDetected(e:StationsManagerEvent):void
		{
			trace("--StandardRadioPluginBroadcasterManager[onLogoutDetected]-");
			
			targetRoutingMap = null;
			
			if (state == CREATE_BROADCAST_STATE)
			{
				dispatchEvent(new PluginManagerEvent(PluginManagerEvent.ERROR, null, "Unable to play sound because station connection is lost.", 102));
				reset();
			}
			else
			if (state == CREATE_BROADCAST_COMPLETE_STATE)
				reset();
			
			dispatchEvent(new StationsManagerEvent(StationsManagerEvent.STATION_DOWN_DETECTED, e.data));
		}
		
		// ******************************************************************************************************************
		
		private function onPlaylistsForRemoteComplete(e:PlaylistsLoaderEvent):void
		{
			trace("1.StandardRadioPluginBroadcasterManager[onPlaylistsForRemoteComplete]:", e.playlists.length);
			
			playlistsLoader.removeEventListener(PlaylistsLoaderEvent.PLAYLISTS_COMPLETE, onPlaylistsForRemoteComplete);
			playlistsLoader.removeEventListener(PlaylistsLoaderEvent.PLAYLISTS_ERROR, onPlaylistsForRemoteError);
			
			context.playlistsLoaderBuilder.destroy(playlistsLoader);
			playlistsLoader = null;
			
			var pl:Array = new Array();
			
			while (e.playlists.length > 0)
				pl = pl.concat(e.playlists.shift() as Array);
			
			trace("2.StandardRadioPluginBroadcasterManager[onPlaylistsForRemoteComplete]:", e.playlists.length, pl.length);
			
			_playlist = pl;
			state = PREPARE_COMPLETE_STATE;
			
			dispatchEvent(new PluginManagerEvent(PluginManagerEvent.READY, {broadcasterRoute: broadcaster.route}));
		}
		
		private function onPlaylistsForRemoteError(e:PlaylistsLoaderEvent):void
		{
			playlistsLoader.removeEventListener(PlaylistsLoaderEvent.PLAYLISTS_COMPLETE, onPlaylistsForRemoteComplete);
			playlistsLoader.removeEventListener(PlaylistsLoaderEvent.PLAYLISTS_ERROR, onPlaylistsForRemoteError);
			
			context.playlistsLoaderBuilder.destroy(playlistsLoader);
			playlistsLoader = null;
			
			trace("-StandardRadioPluginBroadcasterManager[onPlaylistsForRemoteError]- Error loading playlists!");
			
			dispatchEvent(new PluginManagerEvent(PluginManagerEvent.ERROR, null, "Unable to load playlist.", 205));
			destroy();
		}
		
		// ********************************************************************************************************************************************
		//													PREPARE REMOTE BROADCAST
		// ********************************************************************************************************************************************
		
		private function prepareRemoteBroadcast(data:Object):void
		{
			trace("--StandardRadioPluginBroadcasterManager[prepareRemoteBroadcast]-");
			
			_local = true;
			_channelContext = CollectionUtil.getItemFromCollection("_id", data.channelId, stationContext.channels) as ChannelContext;
			
			remoteListener.receiverRoute = data.remoteControllerRoute;
			context.connection.addUnit(remoteListener);
			
			serversManager = context.serversManagersBuilder.build();
			serversManager.addSocketEventListener(ServersManagerEvent.GET_AVAILABLE_SERVER_COMPLETE, onGetAvailableServerComplete);
			serversManager.addSocketEventListener(ServersManagerEvent.GET_AVAILABLE_SERVER_ERROR, onGetAvailableServerError);
			serversManager.getAvailableServer([pluginData.data]);
		}
		
		private function onGetAvailableServerComplete(e:ServersManagerEvent):void
		{
			trace("--StandardRadioPluginBroadcasterManager[onGetAvailableServerComplete]-");
			
			serversManager.removeSocketEventListener(ServersManagerEvent.GET_AVAILABLE_SERVER_COMPLETE, onGetAvailableServerComplete);
			serversManager.removeSocketEventListener(ServersManagerEvent.GET_AVAILABLE_SERVER_ERROR, onGetAvailableServerError);
			
			context.serversManagersBuilder.destroy(serversManager);
			serversManager = null;
			
			serverData.readObject(e.data);
			
			connection = context.connectionsController.createConnection("CONNECTION-" + broadcaster.id);
			connection.addUnit(broadcaster);
			
			bsContext = context.broadcastServerContextBuilder.build();
			bsContext.connection = connection;
			
			playlistsLoader = context.playlistsLoaderBuilder.build();
			playlistsLoader.addEventListener(PlaylistsLoaderEvent.PLAYLISTS_COMPLETE, onPlaylistsForLocalComplete);
			playlistsLoader.addEventListener(PlaylistsLoaderEvent.PLAYLISTS_ERROR, onPlaylistsForLocalError);
			playlistsLoader.load(channelContext.plugin.configuration.playlists as Array);
		}
		
		private function onGetAvailableServerError(e:ServersManagerEvent):void
		{
			trace("--StandardRadioPluginBroadcasterManager[onGetAvailableServerError]-");
			
			serversManager.removeSocketEventListener(ServersManagerEvent.GET_AVAILABLE_SERVER_COMPLETE, onGetAvailableServerComplete);
			serversManager.removeSocketEventListener(ServersManagerEvent.GET_AVAILABLE_SERVER_ERROR, onGetAvailableServerError);
			
			context.serversManagersBuilder.destroy(serversManager);
			serversManager = null;
			
			reset();
			dispatchEvent(new PluginManagerEvent(PluginManagerEvent.ERROR, null, "There are no active servers.", 104));
		}
		
		private function onPlaylistsForLocalComplete(e:PlaylistsLoaderEvent):void
		{
			trace("StandardRadioPluginBroadcasterManager[onPlaylistsForLocalComplete]:", e.playlists.length);
			
			playlistsLoader.removeEventListener(PlaylistsLoaderEvent.PLAYLISTS_COMPLETE, onPlaylistsForLocalComplete);
			playlistsLoader.removeEventListener(PlaylistsLoaderEvent.PLAYLISTS_ERROR, onPlaylistsForLocalError);
			
			context.playlistsLoaderBuilder.destroy(playlistsLoader);
			playlistsLoader = null;
			
			var pl:Array = new Array();
			
			while (e.playlists.length > 0)
				pl = pl.concat(e.playlists.shift() as Array);
			
			trace("StandardRadioPluginBroadcasterManager[onPlaylistsForLocalComplete]:", e.playlists.length, pl.length);
			
			_playlist = pl;
			broadcaster.playlist = pl;
			
			connection.addEventListener(FlashSocketClientEvent.DISCONNECTED, onInitializationDisconnect);
			connection.addEventListener(FlashSocketClientEvent.ERROR, onInitializationError);
			connection.addEventListener(ClientConnectionEvent.INITIALIZATION_COMPLETE, onInitializationComplete);
			connection.address = serverData.address;
			connection.port = serverData.port;
			connection.connect();
		}
		
		private function onPlaylistsForLocalError(e:PlaylistsLoaderEvent):void
		{
			playlistsLoader.removeEventListener(PlaylistsLoaderEvent.PLAYLISTS_COMPLETE, onPlaylistsForLocalComplete);
			playlistsLoader.removeEventListener(PlaylistsLoaderEvent.PLAYLISTS_ERROR, onPlaylistsForLocalError);
			
			context.playlistsLoaderBuilder.destroy(playlistsLoader);
			playlistsLoader = null;
			
			trace("-StandardRadioPluginBroadcasterManager[onPlaylistsForLocalError]- Error loading playlists!");
			
			dispatchEvent(new PluginManagerEvent(PluginManagerEvent.ERROR, null, "Unable to load playlist.", 205));
			destroy();
		}
		
		private function onInitializationDisconnect(e:FlashSocketClientEvent):void
		{
			trace("--StandardRadioPluginBroadcasterManager[onInitializationDisconnect]-");
			
			connection.removeEventListener(FlashSocketClientEvent.DISCONNECTED, onInitializationDisconnect);
			connection.removeEventListener(FlashSocketClientEvent.ERROR, onInitializationError);
			connection.removeEventListener(ClientConnectionEvent.INITIALIZATION_COMPLETE, onInitializationComplete);
			
			context.connectionsController.destroyConnection(connection);
			
			connection.removeUnit(broadcaster.id);
			connection = null;
			
			reset();
			dispatchEvent(new PluginManagerEvent(PluginManagerEvent.ERROR, null, "Connection is lost.", 105));
		}
		
		private function onInitializationError(e:FlashSocketClientEvent):void
		{
			trace("--StandardRadioPluginBroadcasterManager[onInitializationError]-");
			
			connection.removeEventListener(FlashSocketClientEvent.DISCONNECTED, onInitializationDisconnect);
			connection.removeEventListener(FlashSocketClientEvent.ERROR, onInitializationError);
			connection.removeEventListener(ClientConnectionEvent.INITIALIZATION_COMPLETE, onInitializationComplete);
			
			context.connectionsController.destroyConnection(connection);
			
			connection.removeUnit(broadcaster.id);
			connection = null;
			
			reset();
			dispatchEvent(new PluginManagerEvent(PluginManagerEvent.ERROR, null, "Unable to create connection with the server.", 106));
		}
		
		private function onInitializationComplete(e:ClientConnectionEvent):void
		{
			trace("--StandardRadioPluginBroadcasterManager[onInitializationComplete]-", broadcaster.route);
			
			connection.removeEventListener(FlashSocketClientEvent.DISCONNECTED, onInitializationDisconnect);
			connection.removeEventListener(FlashSocketClientEvent.ERROR, onInitializationError);
			connection.removeEventListener(ClientConnectionEvent.INITIALIZATION_COMPLETE, onInitializationComplete);
			
			connection.addEventListener(FlashSocketClientEvent.DISCONNECTED, onDisconnect);
			
			serverRequestPluginsManager = bsContext.pluginsManagersBuilder.build();
			serverRequestPluginsManager.addSocketEventListener(PluginsManagerEvent.PLUGIN_REQUEST_COMPLETE, onServerPluginRequestComplete);
			serverRequestPluginsManager.addSocketEventListener(PluginsManagerEvent.PLUGIN_REQUEST_ERROR, onServerPluginRequestError);
			serverRequestPluginsManager.pluginRequest(pluginData._id, PluginsManager.BROADCASTER, {});
			
			trace("---- YES ---", broadcaster.route)
		}
		
		private function onServerPluginRequestComplete(e:PluginsManagerEvent):void
		{
			trace("--StandardRadioPluginBroadcasterManager[onServerPluginRequestComplete]-");
			
			e.currentTarget.removeSocketEventListener(PluginsManagerEvent.PLUGIN_REQUEST_COMPLETE, onServerPluginRequestComplete);
			e.currentTarget.removeSocketEventListener(PluginsManagerEvent.PLUGIN_REQUEST_ERROR, onServerPluginRequestError);
			
			bsContext.pluginsManagersBuilder.destroy(e.currentTarget as PluginsManager);
			serverRequestPluginsManager = null;
			
			broadcaster.receiverRoute = e.data.broadcasterRoute;
			broadcaster.prepareMessage();
			
			tmpChannelContext.clearObject();
			tmpChannelContext.readObject(channelContext);
			tmpChannelContext.active = true;
			tmpChannelContext.plugin.configuration.broadcasterRoute = e.data.broadcasterRoute;
			
			activateChannelsDataManager = context.channelsDataManagersBuilder.build();
			activateChannelsDataManager.addEventListener(MongoDBRestEvent.COMPLETE, onActivateChannelComplete);
			activateChannelsDataManager.addEventListener(MongoDBRestEvent.ERROR, onActivateChannelError);
			activateChannelsDataManager.updateRecord(channelContext._id, context.sessionId, tmpChannelContext.data);
		}
		
		private function onServerPluginRequestError(e:PluginsManagerEvent):void
		{
			trace("--StandardRadioPluginBroadcasterManager[onServerPluginRequestError]-");
			
			e.currentTarget.removeSocketEventListener(PluginsManagerEvent.PLUGIN_REQUEST_COMPLETE, onServerPluginRequestComplete);
			e.currentTarget.removeSocketEventListener(PluginsManagerEvent.PLUGIN_REQUEST_ERROR, onServerPluginRequestError);
			
			bsContext.pluginsManagersBuilder.destroy(e.currentTarget as PluginsManager);
			serverRequestPluginsManager = null;
			
			//reset(false);
			dispatchEvent(new PluginManagerEvent(PluginManagerEvent.ERROR, null, e.data.error, e.data.code));
		}
		
		private function onActivateChannelComplete(e:MongoDBRestEvent):void
		{
			e.currentTarget.removeEventListener(MongoDBRestEvent.COMPLETE, onActivateChannelComplete);
			e.currentTarget.removeEventListener(MongoDBRestEvent.ERROR, onActivateChannelError);
			
			channelContext.readObject(tmpChannelContext);
			stationContext.channels.refresh();
			
			context.channelsDataManagersBuilder.destroy(e.currentTarget as ChannelsDataManager);
			activateChannelsDataManager = null;
			
			dispatchEvent(new PluginManagerEvent(PluginManagerEvent.READY, {remoteListenerRoute: remoteListener.route}));
		}
		
		private function onActivateChannelError(e:MongoDBRestEvent):void
		{
			e.currentTarget.removeEventListener(MongoDBRestEvent.COMPLETE, onActivateChannelComplete);
			e.currentTarget.removeEventListener(MongoDBRestEvent.ERROR, onActivateChannelError);	
			
			context.channelsDataManagersBuilder.destroy(e.currentTarget as ChannelsDataManager);
			activateChannelsDataManager = null;
			
			dispatchEvent(new PluginManagerEvent(PluginManagerEvent.ERROR, null, e.error, e.code));
		}
		
		// ********************************************************************************************************************************************
		//													REQUEST REMOTE BROADCAST
		// ********************************************************************************************************************************************
		
		public function startBroadcasting():void
		{
			trace("--StandardRadioPluginBroadcasterManager[startBroadcasting]-", state);
			
			if (state == PREPARE_COMPLETE_STATE)
			{
				state = CREATE_BROADCAST_STATE;
				pluginRequest();
			}
		}
		
		private function pluginRequest():void
		{
			trace("--StandardRadioPluginBroadcasterManager[pluginRequest]-");
			
			context.connection.addUnit(remoteController);
			
			requestPluginsManager = context.pluginsManagersBuilder.build(targetRoutingMap);
			requestPluginsManager.addSocketEventListener(PluginsManagerEvent.PLUGIN_REQUEST_COMPLETE, onPluginRequestComplete);
			requestPluginsManager.addSocketEventListener(PluginsManagerEvent.PLUGIN_REQUEST_ERROR, onPluginRequestError);
			requestPluginsManager.pluginRequest(pluginData._id, PluginsManager.BROADCASTER, {
				remote: true,
				channelId: channelContext._id,
				remoteControllerRoute: remoteController.route
			});
			
			//trace("---- YES ---", remotePlaylistListener.route)
		}
		
		private function onPluginRequestComplete(e:PluginsManagerEvent):void
		{
			trace("--StandardRadioPluginBroadcasterManager[onPluginRequestComplete]-", e.data.remoteListenerRoute);
			
			e.currentTarget.removeSocketEventListener(PluginsManagerEvent.PLUGIN_REQUEST_COMPLETE, onPluginRequestComplete);
			e.currentTarget.removeSocketEventListener(PluginsManagerEvent.PLUGIN_REQUEST_ERROR, onPluginRequestError);
			
			context.pluginsManagersBuilder.destroy(e.currentTarget as PluginsManager);
			requestPluginsManager = null;
			
			remoteController.receiverRoute = e.data.remoteListenerRoute;
			state == CREATE_BROADCAST_COMPLETE_STATE;
			
			dispatchEvent(new StandardRadioPluginBroadcasterManagerEvent(StandardRadioPluginBroadcasterManagerEvent.START_BROADCASTING_COMPLETE));
		}
		
		private function onPluginRequestError(e:PluginsManagerEvent):void
		{
			trace("--StandardRadioPluginBroadcasterManager[onPluginRequestError]-");
			
			e.currentTarget.removeSocketEventListener(PluginsManagerEvent.PLUGIN_REQUEST_COMPLETE, onPluginRequestComplete);
			e.currentTarget.removeSocketEventListener(PluginsManagerEvent.PLUGIN_REQUEST_ERROR, onPluginRequestError);
			
			context.pluginsManagersBuilder.destroy(e.currentTarget as PluginsManager);
			requestPluginsManager = null;
			
			remoteController.receiverRoute = null;
			context.connection.removeUnit(remoteController.id);
			
			state = PREPARE_COMPLETE_STATE;
			dispatchEvent(new StandardRadioPluginBroadcasterManagerEvent(StandardRadioPluginBroadcasterManagerEvent.START_BROADCASTING_ERROR));
		}
		
		// ********************************************************************************************************************************************
		//													DESTROY REMOTE BROADCAST
		// ********************************************************************************************************************************************
		
		public function stopBroadcasting():void
		{
			trace("--StandardRadioPluginBroadcasterManager[startBroadcasting]-", state);
			
			remoteController.addSocketEventListener(StandardRadioRemoteControllerEvent.DESTROY_COMPLETE, onDestroyComplete);
			remoteController.addSocketEventListener(StandardRadioRemoteControllerEvent.DESTROY_ERROR, onDestroyError);
			remoteController.destroy();
		}
		
		private function onDestroyComplete(e:StandardRadioRemoteControllerEvent):void
		{
			trace("--StandardRadioPluginBroadcasterManager[onDestroyComplete]-", state);
			
			remoteController.removeSocketEventListener(StandardRadioRemoteControllerEvent.DESTROY_COMPLETE, onDestroyComplete);
			remoteController.removeSocketEventListener(StandardRadioRemoteControllerEvent.DESTROY_ERROR, onDestroyError);
			remoteController.receiverRoute = null;
			
			state = PREPARE_COMPLETE_STATE;
			dispatchEvent(new StandardRadioPluginBroadcasterManagerEvent(StandardRadioPluginBroadcasterManagerEvent.STOP_BROADCASTING_COMPLETE));
		}
		
		private function onDestroyError(e:StandardRadioRemoteControllerEvent):void
		{
			trace("--StandardRadioPluginBroadcasterManager[onDestroyError]-", state);
			
			remoteController.removeSocketEventListener(StandardRadioRemoteControllerEvent.DESTROY_COMPLETE, onDestroyComplete);
			remoteController.removeSocketEventListener(StandardRadioRemoteControllerEvent.DESTROY_ERROR, onDestroyError);
			
			dispatchEvent(new StandardRadioPluginBroadcasterManagerEvent(StandardRadioPluginBroadcasterManagerEvent.STOP_BROADCASTING_ERROR));
		}
		
		// ********************************************************************************************************************************************
		// ********************************************************************************************************************************************
		// ********************************************************************************************************************************************
		
		protected function onPlaySong(e:StandardRadioRemoteListenerEvent):void
		{
			trace("onPlaySong:", e.index);
			playSong(e.index);
		}
		
		protected function onStopSong(e:StandardRadioRemoteListenerEvent):void
		{
			trace("onStopSong:");
			stopSong();
		}
		
		protected function onPreviousSong(e:StandardRadioRemoteListenerEvent):void
		{
			trace("onPreviousSong:");
			previousSong();
		}
		
		protected function onNextSong(e:StandardRadioRemoteListenerEvent):void
		{
			trace("onNextSong:");
			nextSong();
		}
		
		protected function onChangePlayOrder(e:StandardRadioRemoteListenerEvent):void
		{
			trace("onChangePlayOrder:", e.order);
			changePlayOrder(e.order);
		}
		
		protected function onDestroy(e:StandardRadioRemoteListenerEvent):void
		{
			trace("-onDestroy-");
			
			tmpChannelContext.clearObject();
			tmpChannelContext.readObject(channelContext);
			tmpChannelContext.active = false;
			tmpChannelContext.plugin.configuration.broadcasterRoute = null;
			
			deactivateChannelsDataManager = context.channelsDataManagersBuilder.build();
			deactivateChannelsDataManager.addEventListener(MongoDBRestEvent.COMPLETE, onDeactivateChannelComplete);
			deactivateChannelsDataManager.addEventListener(MongoDBRestEvent.ERROR, onDeactivateChannelError);
			deactivateChannelsDataManager.updateRecord(channelContext._id, context.sessionId, tmpChannelContext.data);
		}
		
		private function onDeactivateChannelComplete(e:MongoDBRestEvent):void
		{
			e.currentTarget.removeEventListener(MongoDBRestEvent.COMPLETE, onDeactivateChannelComplete);
			e.currentTarget.removeEventListener(MongoDBRestEvent.ERROR, onDeactivateChannelError);
			
			channelContext.readObject(tmpChannelContext);
			stationContext.channels.refresh();
			
			context.channelsDataManagersBuilder.destroy(e.currentTarget as ChannelsDataManager);
			deactivateChannelsDataManager = null;
			
			remoteListener.dispatchDestroyComplete();
			executeDestroy();
		}
		
		private function onDeactivateChannelError(e:MongoDBRestEvent):void
		{
			e.currentTarget.removeEventListener(MongoDBRestEvent.COMPLETE, onDeactivateChannelComplete);
			e.currentTarget.removeEventListener(MongoDBRestEvent.ERROR, onDeactivateChannelError);	
			
			context.channelsDataManagersBuilder.destroy(e.currentTarget as ChannelsDataManager);
			deactivateChannelsDataManager = null;
			
			remoteListener.dispatchDestroyError(e.error, e.code);
		}
		
		// ********************************************************************************************************************************************
		// ********************************************************************************************************************************************
		// ********************************************************************************************************************************************
		
		public function playSong(index:int = 0):void
		{
			if (local)
				broadcaster.playSong(index);
			else
				remoteController.playSong(index);
		}
		
		public function stopSong():void
		{
			if (local)
				broadcaster.stopSong();
			else
				remoteController.stopSong();
		}
		
		public function previousSong():void
		{
			if (local)
				broadcaster.previousSong();
			else
				remoteController.previousSong();
		}
		
		public function nextSong():void
		{
			if (local)
				broadcaster.nextSong();
			else
				remoteController.nextSong();
		}
		
		public function changePlayOrder(order:int = -1):void
		{
			if (local)
				broadcaster.changePlayOrder(order);
			else
				remoteController.changePlayOrder(order);
		}
		
		// ****************************************************************************************************************
		
		private function onDisconnect(e:FlashSocketClientEvent):void
		{
			trace("--StandardRadioPluginBroadcasterManager[onDisconnect]-");
			
			if (state == PREPARE_STATE)
				dispatchEvent(new PluginManagerEvent(PluginManagerEvent.ERROR, null, "Connection is lost.", 206));
			
			destroy();
		}
		
		private function onListenerDisconnect(e:ConnectionsManagerEvent):void
		{
			trace("--StandardRadioPluginBroadcasterManager[onListenerDisconnect]-");
			
			destroy();
		}
		
		public function destroy():void
		{
			trace("--StandardRadioPluginBroadcasterManager[destroy]-");

			if (local)
			{
				if (!broadcasting)
					executeDestroy();
			}
			else
				executeDestroy();
		}
		
		private function executeDestroy():void
		{
			reset();
			dispatchEvent(new PluginManagerEvent(PluginManagerEvent.DESTROY));
		}
		
		// ******************************************************************************************************************
		
		public function reset():void
		{
			trace("-StandardRadioPluginBroadcasterManager[reset]", state);
			
			if (state == NONE_STATE)
				return ;
			
			state = NONE_STATE;
			broadcaster.reset();
			
			if (playlistsLoader)
			{
				context.playlistsLoaderBuilder.destroy(playlistsLoader);
				playlistsLoader = null;
			}
			
			if (remoteController.parent)
			{
				remoteController.receiverRoute = null;
				remoteController.parent.removeUnit(remoteController.id);
			}
			
			if (remoteListener.parent)
			{
				remoteListener.receiverRoute = null;
				remoteListener.parent.removeUnit(remoteListener.id);
			}
			
			if (bsContext)
			{
				if (connectionsManager)
				{
					bsContext.connectionsManagerBuilder.destroy(connectionsManager);
					connectionsManager = null;
				}
				
				connection.removeEventListener(FlashSocketClientEvent.DISCONNECTED, onInitializationDisconnect);
				connection.removeEventListener(FlashSocketClientEvent.ERROR, onInitializationError);
				connection.removeEventListener(ClientConnectionEvent.INITIALIZATION_COMPLETE, onInitializationComplete);
				connection.removeEventListener(FlashSocketClientEvent.DISCONNECTED, onDisconnect);
				
				context.connectionsController.destroyConnection(connection);
				
				connection.removeUnit(broadcaster.id);
				connection = null;
				
				context.broadcastServerContextBuilder.destroy(bsContext);
				bsContext = null;
			}
		}
		
		public function set context(value:SoundShareContext):void
		{
			stationContext = value as StationContext;
		}
		
		public function get context():SoundShareContext
		{
			return stationContext;
		}
		
		public function set pluginData(value:PluginData):void
		{
			_pluginData = value;
		}
		
		public function get pluginData():PluginData
		{
			return _pluginData;
		}
		
		public function get channelContext():ChannelContext
		{
			return _channelContext;
		}
		
		public function get playlist():Array
		{
			return _playlist;
		}
		
		public function get local():Boolean
		{
			return _local;
		}
		
		public function get remote():Boolean
		{
			return _remote;
		}
		
		public function get broadcasting():Boolean
		{
			return state == CREATE_BROADCAST_COMPLETE_STATE;
		}
	}
}