package soundshare.plugins.station.standardradio.broadcaster
{
	import socket.message.FlashSocketMessage;
	
	import soundshare.station.data.StationContext;
	import soundshare.plugins.station.standardradio.broadcaster.events.StandardRadioRemoteListenerEvent;
	import soundshare.sdk.managers.events.SecureClientEventDispatcher;
	
	public class StandardRadioRemoteListener extends SecureClientEventDispatcher
	{
		public var context:StationContext;
		
		public function StandardRadioRemoteListener()
		{
			super();
			
			addAction("PLAY", executePlaySong);
			addAction("STOP", executeStopSong);
			addAction("NEXT", executeNextSong);
			addAction("PREVIOUS", executePreviousSong);
			addAction("CHANGE_PLAY_ORDER", executeChangePlayOrder);
			addAction("DESTROY", executeDestroy);
		}
		
		private function executeDestroy(message:FlashSocketMessage):void
		{
			dispatchEvent(new StandardRadioRemoteListenerEvent(StandardRadioRemoteListenerEvent.DESTROY));
		}
		
		public function dispatchDestroyComplete():void
		{
			trace("-StandardRadioRemoteListener[dispatchDestroyComplete]-", route, receiverRoute);
			
			dispatchSocketEvent({
				event: {
					type: "DESTROY_COMPLETE"
				}
			});
		}
		
		public function dispatchDestroyError(error:String, code:int):void
		{
			trace("-StandardRadioRemoteListener[dispatchDestroyError]-", route, receiverRoute);
			
			dispatchSocketEvent({
				event: {
					type: "DESTROY_ERROR",
					data: {
						error: error,
						code: code
					}
				}
			});
		}
		
		private function executePlaySong(message:FlashSocketMessage):void
		{
			trace("-StandardRadioRemoteListener[executePlaySong]-", route, receiverRoute);
			
			var body:Object = message.getJSONBody();
			var index:int = body.index ? body.index : 0;
			var order:int = body.order ? body.order : -1;
			
			var event:StandardRadioRemoteListenerEvent = new StandardRadioRemoteListenerEvent(StandardRadioRemoteListenerEvent.PLAY);
			event.index = index;
			event.order = order;
			
			dispatchEvent(event);
		}
		
		private function executeStopSong(message:FlashSocketMessage):void
		{
			trace("-StandardRadioRemoteListener[executeStopSong]-");
			
			dispatchEvent(new StandardRadioRemoteListenerEvent(StandardRadioRemoteListenerEvent.STOP));
		}
		
		private function executeNextSong(message:FlashSocketMessage):void
		{
			trace("-StandardRadioRemoteListener[executeNextSong]-");
			
			dispatchEvent(new StandardRadioRemoteListenerEvent(StandardRadioRemoteListenerEvent.NEXT));
		}
		
		private function executePreviousSong(message:FlashSocketMessage):void
		{
			trace("-StandardRadioRemoteListener[executePreviousSong]-");
			
			dispatchEvent(new StandardRadioRemoteListenerEvent(StandardRadioRemoteListenerEvent.PREVIOUS));
		}
		
		private function executeChangePlayOrder(message:FlashSocketMessage):void
		{
			trace("-StandardRadioRemoteListener[executeChangePlayOrder]-");
			
			var body:Object = message.getJSONBody();
			var order:int = body.order ? body.order : 0;
			
			var event:StandardRadioRemoteListenerEvent = new StandardRadioRemoteListenerEvent(StandardRadioRemoteListenerEvent.CHANGE_PLAY_ORDER);
			event.order = order;
			
			dispatchEvent(event);
		}
	}
}