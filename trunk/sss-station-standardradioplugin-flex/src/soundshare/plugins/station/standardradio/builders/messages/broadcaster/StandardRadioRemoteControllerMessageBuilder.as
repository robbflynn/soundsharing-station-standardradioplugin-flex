package soundshare.plugins.station.standardradio.builders.messages.broadcaster
{
	import flash.utils.ByteArray;
	
	import socket.message.FlashSocketMessage;
	import socket.client.base.ClientSocketUnit;
	
	import soundshare.sdk.data.SoundShareContext;
	import soundshare.sdk.managers.events.SecureClientEventDispatcher;
	
	public class StandardRadioRemoteControllerMessageBuilder
	{
		public var target:SecureClientEventDispatcher;
		
		public function StandardRadioRemoteControllerMessageBuilder(target:SecureClientEventDispatcher)
		{
			this.target = target;
		}
		
		protected function build(xtype:String):FlashSocketMessage
		{
			if (!xtype)
				throw new Error("Invalid xtype!");
			
			var message:FlashSocketMessage = new FlashSocketMessage();
			message.setJSONHeader({
				route: {
					sender: target.route,
					receiver: target.receiverRoute
				},
				data: {
					token: target.token,
					action: {
						xtype: xtype
					}
				}
			});
			
			return message;
		}
		
		public function buildPlaySongMessage(index:int):FlashSocketMessage
		{
			var message:FlashSocketMessage = build("PLAY");
			
			if (message)
			{
				message.setJSONBody({
					index: index
				});
			}
			
			return message;
		}
		
		public function buildStopPlayingMessage():FlashSocketMessage
		{
			return build("STOP");
		}
		
		public function buildPreviousPlayingMessage():FlashSocketMessage
		{
			return build("PREVIOUS");
		}
		
		public function buildNextPlayingMessage():FlashSocketMessage
		{
			return build("NEXT");
		}
		
		public function buildChangePlayOrderMessage(order:int):FlashSocketMessage
		{
			var message:FlashSocketMessage = build("CHANGE_PLAY_ORDER");
			
			if (message)
			{
				message.setJSONBody({
					order: order
				});
			}
			
			return message;
		}
		
		public function buildDestroyMessage():FlashSocketMessage
		{
			return build("DESTROY");
		}
	}
}