package soundshare.plugins.station.standardradio.builders
{
	import soundshare.station.data.StationContext;
	import soundshare.station.data.channels.ChannelContext;
	import soundshare.plugins.station.standardradio.managers.broadcaster.StandardRadioPluginBroadcasterManager;
	import soundshare.plugins.station.standardradio.managers.configuration.StandardRadioPluginConfigurationManager;
	import soundshare.plugins.station.standardradio.managers.listener.StandardRadioPluginListenerManager;
	import soundshare.plugins.station.standardradio.views.broadcaster.StandardRadioBroadcasterView;
	import soundshare.plugins.station.standardradio.views.configuration.StandardRadioConfigurationView;
	import soundshare.plugins.station.standardradio.views.listener.StandardRadioListenerView;
	import soundshare.sdk.data.SoundShareContext;
	import soundshare.sdk.data.plugin.PluginData;
	import soundshare.sdk.plugins.builder.IPluginBuilder;
	import soundshare.sdk.plugins.builder.result.PluginBuilderResult;
	import soundshare.sdk.plugins.manager.events.PluginManagerEvent;
	
	import utils.collection.CollectionUtil;
	
	public class StandardRadioPluginBuilder implements IPluginBuilder
	{
		private static const MAX_LISTENERS_CACHE:int = 5;
		private static const MAX_BROADCASTERS_CACHE:int = 5;
		private static const MAX_CONFIGURATION_CACHE:int = 5;
		
		private var stationContext:StationContext;
		
		private var broadcasterView:StandardRadioBroadcasterView;
		private var listenerView:StandardRadioListenerView;
		private var configurationView:StandardRadioConfigurationView;
		
		private var activeBroadcasterManagers:Array = new Array();
		
		private var broadcasterManagersCache:Vector.<StandardRadioPluginBroadcasterManager> = new Vector.<StandardRadioPluginBroadcasterManager>();
		private var listenerManagersCache:Vector.<StandardRadioPluginListenerManager> = new Vector.<StandardRadioPluginListenerManager>();
		private var configurationManagersCache:Vector.<StandardRadioPluginConfigurationManager> = new Vector.<StandardRadioPluginConfigurationManager>();
		
		public function StandardRadioPluginBuilder()
		{
		}
		
		protected function buildListenerView():StandardRadioListenerView
		{
			if (!listenerView)
				listenerView = new StandardRadioListenerView();
			
			return listenerView;
		}
		
		protected function buildListenerManager():StandardRadioPluginListenerManager
		{
			var manager:StandardRadioPluginListenerManager;
			
			if (listenerManagersCache.length > 0)
				manager = listenerManagersCache.shift();
			else
				manager = new StandardRadioPluginListenerManager();
				
			manager.context = context;
			
			return manager;
		}
		
		public function buildListener(pluginData:PluginData, buildView:Boolean = true, data:Object = null):PluginBuilderResult
		{
			var manager:StandardRadioPluginListenerManager = buildListenerManager();
			manager.addEventListener(PluginManagerEvent.DESTROY, onDestroyListenerPlugin);
			manager.pluginData = pluginData;
			
			var view:StandardRadioListenerView = buildListenerView();
			view.manager = manager;
			
			return new PluginBuilderResult(manager, view);
		}
		
		protected function onDestroyListenerPlugin(e:PluginManagerEvent):void
		{
			e.currentTarget.removeEventListener(PluginManagerEvent.DESTROY, onDestroyListenerPlugin);
			
			if (listenerManagersCache.length < MAX_LISTENERS_CACHE)
				listenerManagersCache.push(e.currentTarget as StandardRadioPluginListenerManager);
		}
		
		// ************************************************************************************************************************
		// ************************************************************************************************************************
		// ************************************************************************************************************************
		
		protected function buildBroadcasterView():StandardRadioBroadcasterView
		{
			if (!broadcasterView)
				broadcasterView = new StandardRadioBroadcasterView();
			
			return broadcasterView;
		}
		
		protected function buildBroadcasterManager(data:Object = null):StandardRadioPluginBroadcasterManager
		{
			var manager:StandardRadioPluginBroadcasterManager;
			var cc:ChannelContext;
			var _id:String;
			
			if (data != null)
			{
				cc = CollectionUtil.getItemFromCollection("_id", data.channelId, stationContext.channels) as ChannelContext;
				_id = cc._id + "-R";
			}
			else
			{
				cc = stationContext.selectedChannel;
				_id = cc._id;
			}
			
			
			manager = activeBroadcasterManagers[_id] as StandardRadioPluginBroadcasterManager;
			
			if (!manager)
			{
				if (broadcasterManagersCache.length > 0)
					manager = broadcasterManagersCache.shift();
				else
					manager = new StandardRadioPluginBroadcasterManager();
			
				activeBroadcasterManagers[_id] = manager;
			}
			
			manager.context = context;
			
			return manager;
		}
		
		public function buildBroadcaster(pluginData:PluginData, buildView:Boolean = true, data:Object = null):PluginBuilderResult
		{
			var manager:StandardRadioPluginBroadcasterManager = buildBroadcasterManager(data);
			manager.addEventListener(PluginManagerEvent.DESTROY, onDestroyBroadcasterPlugin);
			manager.pluginData = pluginData;
			
			var view:StandardRadioBroadcasterView;
			
			if (buildView)
			{
				view = buildBroadcasterView();
				view.manager = manager;
			}
			
			return new PluginBuilderResult(manager, view);
		}
		
		protected function onDestroyBroadcasterPlugin(e:PluginManagerEvent):void
		{
			var manager:StandardRadioPluginBroadcasterManager = e.currentTarget as StandardRadioPluginBroadcasterManager;
			manager.removeEventListener(PluginManagerEvent.DESTROY, onDestroyBroadcasterPlugin);
			
			trace("StandardRadioPluginBuilder[onDestroyBroadcasterPlugin]:", activeBroadcasterManagers[manager.remote ? manager.channelContext._id + "-R" : manager.channelContext._id]);
			
			delete activeBroadcasterManagers[manager.remote ? manager.channelContext._id + "-R" : manager.channelContext._id];
			
			if (broadcasterManagersCache.length < MAX_BROADCASTERS_CACHE)
				broadcasterManagersCache.push(manager);
		}
		
		// ************************************************************************************************************************
		// ************************************************************************************************************************
		// ************************************************************************************************************************
		
		protected function buildConfigurationView():StandardRadioConfigurationView
		{
			if (!configurationView)
				configurationView = new StandardRadioConfigurationView();
			
			return configurationView;
		}
		
		protected function buildConfigurationManager():StandardRadioPluginConfigurationManager
		{
			var manager:StandardRadioPluginConfigurationManager;
			
			if (configurationManagersCache.length > 0)
				manager = configurationManagersCache.shift();
			else
				manager = new StandardRadioPluginConfigurationManager();
			
			manager.context = context;
			
			return manager;
		}
		
		public function buildConfiguration(pluginData:PluginData, buildView:Boolean = true, data:Object = null):PluginBuilderResult
		{
			var manager:StandardRadioPluginConfigurationManager = buildConfigurationManager();
			manager.addEventListener(PluginManagerEvent.DESTROY, onDestroyConfigurationPlugin);
			manager.pluginData = pluginData;
			
			var view:StandardRadioConfigurationView = buildConfigurationView();
			view.manager = manager;
			
			return new PluginBuilderResult(manager, view);
		}
		
		protected function onDestroyConfigurationPlugin(e:PluginManagerEvent):void
		{
			e.currentTarget.removeEventListener(PluginManagerEvent.DESTROY, onDestroyConfigurationPlugin);
			
			if (configurationManagersCache.length < MAX_CONFIGURATION_CACHE)
				configurationManagersCache.push(e.currentTarget as StandardRadioPluginConfigurationManager);
		}
		
		// ************************************************************************************************************************
		// ************************************************************************************************************************
		// ************************************************************************************************************************
		
		public function set context(value:SoundShareContext):void
		{
			stationContext = value as StationContext;
		}
		
		public function get context():SoundShareContext
		{
			return stationContext;
		}
	}
}