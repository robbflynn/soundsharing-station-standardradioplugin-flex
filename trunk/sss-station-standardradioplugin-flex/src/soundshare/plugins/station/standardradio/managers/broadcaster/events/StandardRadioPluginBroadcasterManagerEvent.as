package soundshare.plugins.station.standardradio.managers.broadcaster.events
{
	import flash.events.Event;
	
	public class StandardRadioPluginBroadcasterManagerEvent extends Event
	{
		public static const START_BROADCASTING_COMPLETE:String = "startBroadcastingComplete";
		public static const START_BROADCASTING_ERROR:String = "startBroadcastingError";
		
		public static const STOP_BROADCASTING_COMPLETE:String = "stopBroadcastingComplete";
		public static const STOP_BROADCASTING_ERROR:String = "stopBroadcastingError";
		
		public function StandardRadioPluginBroadcasterManagerEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}