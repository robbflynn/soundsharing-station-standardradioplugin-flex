package soundshare.plugins.station.standardradio.broadcaster.events
{
	import flash.events.Event;
	
	import socket.client.managers.events.events.ClientEventDispatcherEvent;
	
	public class StandardRadioRemoteControllerEvent extends ClientEventDispatcherEvent
	{
		public static const DESTROY_COMPLETE:String = "DESTROY_COMPLETE";
		public static const DESTROY_ERROR:String = "DESTROY_ERROR";
		
		public function StandardRadioRemoteControllerEvent(type:String, data:Object=null, body:Object=null, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, data, body, bubbles, cancelable);
		}
	}
}