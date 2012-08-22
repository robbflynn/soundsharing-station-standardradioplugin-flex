package soundshare.plugins.station.standardradio.broadcaster
{
	import socket.message.FlashSocketMessage;
	
	import soundshare.station.data.StationContext;
	import soundshare.plugins.station.standardradio.broadcaster.events.StandardRadioBroadcasterEvent;
	import soundshare.plugins.station.standardradio.builders.messages.broadcaster.StandardRadioBroadcasterMessageBuilder;
	import soundshare.sdk.managers.broadcaster.Broadcaster;
	import soundshare.sdk.sound.channels.playlist.PlaylistChannel;
	import soundshare.sdk.sound.channels.playlist.events.PlaylistsChannelEvent;
	
	public class StandardRadioBroadcaster extends Broadcaster
	{
		public var context:StationContext;
		
		private var playlistChannel:PlaylistChannel;
		private var messageBuilder:StandardRadioBroadcasterMessageBuilder;
		
		public function StandardRadioBroadcaster()
		{
			super();
			
			playlistChannel = new PlaylistChannel();
			playlistChannel.addEventListener(PlaylistsChannelEvent.CHANGE_SONG, onChangeSong);
			playlistChannel.addEventListener(PlaylistsChannelEvent.LOAD_AUDIO_DATA_ERROR, onLoadAudioDataError);
			playlistChannel.addEventListener(PlaylistsChannelEvent.STOP_PLAYING, onStopPlaying);
			
			channelsMixer.addChannel(playlistChannel, "PlaylistChannel");
			
			messageBuilder = new StandardRadioBroadcasterMessageBuilder(this);
			
			/*addAction("PLAY", executePlaySong);
			addAction("STOP", executeStopSong);
			addAction("NEXT", executeNextSong);
			addAction("PREVIOUS", executePreviousSong);
			addAction("CHANGE_PLAY_ORDER", executeChangePlayOrder);*/
		}
		
		public function prepareMessage():void
		{
			message = messageBuilder.buildBroadcastMessage();
		}
		
		// ***********************************************************************************************************************************************
		
		public function playSong(index:int = 0):void
		{
			trace("-RemotePlaylistBroadcast[playSong]-", index);
			
			start();
			playlistChannel.play(index);
		}
		
		public function stopSong():void
		{
			trace("-RemotePlaylistBroadcast[stopSong]-");
			
			playlistChannel.stop();
			sendStopPlaying();
		}
		
		public function nextSong():void
		{
			trace("-RemotePlaylistBroadcast[nextSong]-");
			
			playlistChannel.next();
		}
		
		public function previousSong():void
		{
			trace("-RemotePlaylistBroadcast[previousSong]-");
			
			playlistChannel.previous();
		}
		
		public function changePlayOrder(order:int = -1):void
		{
			trace("-RemotePlaylistBroadcast[changePlayOrder]-", order);
			
			if (order != -1)
				playlistChannel.playOrder = order;
		}
		
		// ***********************************************************************************************************************************************
		
		public function reset():void
		{
			trace("-RemotePlaylistBroadcast[reset]-");
			
			stop();
			playlistChannel.reset();
		}
		
		public function close():void
		{
			trace("--RemotePlaylistBroadcast[close]-");
			
			var message:FlashSocketMessage = messageBuilder.buildCloseConnectionMessage();
			
			if (message)
				send(message);
		}
		
		// ***********************************************************************************************************************************************
		
		private function onChangeSong(e:PlaylistsChannelEvent):void
		{
			trace("-RemotePlaylistBroadcast[onChangeSong]-");
			
			var message:FlashSocketMessage = messageBuilder.buildChangeSongMessage(e.songIndex);
			
			if (message)
				send(message);
		}
		
		private function onStopPlaying(e:PlaylistsChannelEvent):void
		{
			trace("-RemotePlaylistBroadcast[onStopPlaying]-");
			
			stop();
			sendStopPlaying();
		}
		
		private function sendStopPlaying():void
		{
			trace("-RemotePlaylistBroadcast[sendStopPlaying]-");
			
			var message:FlashSocketMessage = messageBuilder.buildStopPlayingMessage();
			
			if (message)
				send(message);
		}
		
		private function onLoadAudioDataError(e:PlaylistsChannelEvent):void
		{
			trace("-RemotePlaylistBroadcast[onPlaylistError]-");
			
			var message:FlashSocketMessage = messageBuilder.buildLoadAudioDataErrorMessage();
			
			if (message)
				send(message);
			
			dispatchEvent(new StandardRadioBroadcasterEvent(StandardRadioBroadcasterEvent.LOAD_AUDIO_DATA_ERROR));
		}
		
		// ******************************************************************************************************************
		// 													ACTIONS
		// ******************************************************************************************************************
		
		/*private function executePlaySong(message:FlashSocketMessage):void
		{
			trace("-RemotePlaylistBroadcast[executePlaySong]-", route, receiverRoute);
			
			var body:Object = message.getJSONBody();
			var index:int = body.index ? body.index : 0;
			var order:int = body.order ? body.order : -1;
				
			start();
			playlistChannel.play(index);
			
			if (order != -1)
				playlistChannel.playOrder = order;
		}
		
		private function executeStopSong(message:FlashSocketMessage):void
		{
			trace("-RemotePlaylistBroadcast[executePlaySong]-");
			
			playlistChannel.stop();
			sendStopPlaying();
		}
		
		private function executeNextSong(message:FlashSocketMessage):void
		{
			trace("-RemotePlaylistBroadcast[executeNextSong]-");
			
			playlistChannel.next();
		}
		
		private function executePreviousSong(message:FlashSocketMessage):void
		{
			trace("-RemotePlaylistBroadcast[executePreviousSong]-");
			
			playlistChannel.previous();
		}
		
		private function executeChangePlayOrder(message:FlashSocketMessage):void
		{
			trace("-RemotePlaylistBroadcast[executePlaySong]-");
			
			var body:Object = message.getJSONBody();
			var order:int = body.order ? body.order : 0;
			
			playlistChannel.playOrder = order;
		}*/
		
		public function set playlist(value:Array):void
		{
			playlistChannel.playlist = value;
		}
		
		public function get playlist():Array
		{
			return playlistChannel.playlist;
		}
	}
}