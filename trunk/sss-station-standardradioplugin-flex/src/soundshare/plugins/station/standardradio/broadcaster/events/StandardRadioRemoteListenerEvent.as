package soundshare.plugins.station.standardradio.broadcaster.events
{
	import flash.events.Event;
	
	public class StandardRadioRemoteListenerEvent extends Event
	{
		public static const PLAY:String = "play";
		public static const STOP:String = "stop";
		public static const NEXT:String = "next";
		public static const PREVIOUS:String = "previous";
		public static const CHANGE_PLAY_ORDER:String = "changePlayOrder";
		public static const DESTROY:String = "destroy";
		
		public var index:int;
		public var order:int;
		
		public function StandardRadioRemoteListenerEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}