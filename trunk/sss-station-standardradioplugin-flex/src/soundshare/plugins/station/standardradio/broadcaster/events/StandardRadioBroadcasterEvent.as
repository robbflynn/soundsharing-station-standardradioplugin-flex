package soundshare.plugins.station.standardradio.broadcaster.events
{
	import socket.client.managers.events.events.ClientEventDispatcherEvent;
	
	public class StandardRadioBroadcasterEvent extends ClientEventDispatcherEvent
	{
		public static const PREPARE_COMPLETE:String = "prepareComplete";
		public static const PREPARE_ERROR:String = "prepareError";
		
		public static const LOAD_AUDIO_DATA_ERROR:String = "loadAudioDataError";
		
		public function StandardRadioBroadcasterEvent(type:String, data:Object=null, body:Object=null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, data, body, bubbles, cancelable);
		}
	}
}