package soundshare.plugins.station.standardradio.broadcaster
{
	import socket.message.FlashSocketMessage;
	
	import soundshare.station.data.StationContext;
	import soundshare.plugins.station.standardradio.broadcaster.events.StandardRadioRemoteControllerEvent;
	import soundshare.plugins.station.standardradio.builders.messages.broadcaster.StandardRadioRemoteControllerMessageBuilder;
	import soundshare.sdk.managers.events.SecureClientEventDispatcher;
	
	public class StandardRadioRemoteController extends SecureClientEventDispatcher
	{
		public var context:StationContext;
		
		private var messageBuilder:StandardRadioRemoteControllerMessageBuilder;
		
		public function StandardRadioRemoteController()
		{
			super();
			
			messageBuilder = new StandardRadioRemoteControllerMessageBuilder(this);
		}
		
		override protected function $dispatchSocketEvent(message:FlashSocketMessage):void
		{
			var event:Object = getActionData(message);
			
			trace("-StandardRadioRemoteController[$dispatchSocketEvent]-", event);
			
			if (event)
				dispatchEvent(new StandardRadioRemoteControllerEvent(event.type, event.data));
		}
		
		public function playSong(songIndex:int):void
		{
			trace("-StandardRadioRemoteController[playSong]-", songIndex);
			
			var message:FlashSocketMessage = messageBuilder.buildPlaySongMessage(songIndex);
			
			if (message)
				send(message);
		}
		
		public function stopSong():void
		{
			trace("-StandardRadioRemoteController[stopSong]-");
			
			var message:FlashSocketMessage = messageBuilder.buildStopPlayingMessage();
			
			if (message)
				send(message);
		}
		
		public function previousSong():void
		{
			trace("-StandardRadioRemoteController[previousSong]-");
			
			var message:FlashSocketMessage = messageBuilder.buildPreviousPlayingMessage();
			
			if (message)
				send(message);
		}
		
		public function nextSong():void
		{
			trace("-StandardRadioRemoteController[nextSong]-");
			
			var message:FlashSocketMessage = messageBuilder.buildNextPlayingMessage();
			
			if (message)
				send(message);
		}
		
		public function changePlayOrder(order:int = 0):void
		{
			trace("-StandardRadioRemoteController[changePlayOrder]-", order);
			
			var message:FlashSocketMessage = messageBuilder.buildChangePlayOrderMessage(order);
			
			if (message)
				send(message);
		}
		
		public function destroy():void
		{
			trace("-StandardRadioRemoteController[destroy]-");
			
			var message:FlashSocketMessage = messageBuilder.buildDestroyMessage();
			
			if (message)
				send(message);
		}
	}
}