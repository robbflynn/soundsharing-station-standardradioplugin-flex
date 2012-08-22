package soundshare.plugins.station.standardradio.managers.configuration
{
	import flash.events.EventDispatcher;
	import flash.net.dns.AAAARecord;
	
	import soundshare.station.data.StationContext;
	import soundshare.sdk.data.SoundShareContext;
	import soundshare.sdk.data.platlists.PlaylistContext;
	import soundshare.sdk.data.plugin.PluginConfigurationData;
	import soundshare.sdk.data.plugin.PluginData;
	import soundshare.sdk.plugins.manager.IPluginManager;
	import soundshare.sdk.plugins.manager.events.PluginManagerEvent;
	
	public class StandardRadioPluginConfigurationManager extends EventDispatcher implements IPluginManager
	{
		private var stationContext:StationContext;
		private var _pluginData:PluginData;
		
		private var playlists:Array;
		
		public function StandardRadioPluginConfigurationManager()
		{
			super();
		}
		
		public function prepare(data:Object = null):void
		{
			playlists = data as Array;
		}
		
		public function destroy():void
		{
			playlists = null;
			dispatchEvent(new PluginManagerEvent(PluginManagerEvent.DESTROY));
		}
		
		public function save():void
		{
			if (!stationContext.selectedChannel.plugin)
				stationContext.selectedChannel.plugin = new PluginConfigurationData();
			
			var pl:Array = new Array();
			
			for (var i:int = 0;i < playlists.length;i ++)
				pl.push((playlists[i] as PlaylistContext)._id);
			
			stationContext.selectedChannel.plugin.pluginId = pluginData._id;
			stationContext.selectedChannel.plugin.configuration = {
				serverData: null,
				broadcasterRoute: null,
				playlists: pl
			};
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
	}
}