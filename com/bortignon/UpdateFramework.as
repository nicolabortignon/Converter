package com.bortignon
{
	import flash.desktop.Updater;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.*;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLStream;
	import flash.utils.ByteArray;


	public class UpdateFramework extends EventDispatcher
	{
		private var pathToUpgrade:String = "http://www.nicolabortignon.com/APPconverter/versions.xml";
		private var currentVersion:Number;
		private var newerVersion:Number;
		private var urlReq:URLRequest;
		private var urlStream:URLStream = new URLStream(); 
		private var fileData:ByteArray = new ByteArray(); 

		public var newDownloadPath:String;


		public function UpdateFramework(_currentVersion:Number)
		{
			currentVersion = _currentVersion;
			var l:URLLoader = new URLLoader();
			l.load(new URLRequest(pathToUpgrade));
			l.addEventListener(Event.COMPLETE,loadedVersion);



		}

		private function loadedVersion(e:Event){

			var xml:XML = new XML(e.target.data);
			if (currentVersion < Number(xml.children().attributes())){
				newDownloadPath  = xml.children();
				dispatchEvent(new Event("NEW VERSION"));
			}


		}
		public function downloadNewVersion(){

			urlStream.addEventListener(Event.COMPLETE, loaded); 
			urlStream.load(urlReq); 
		}

		function loaded(event:Event):void { 

			trace("CARICATO AIR");
			urlStream.readBytes(fileData, 0, urlStream.bytesAvailable); 
			writeAirFile(); 
		} 

		function writeAirFile():void { 
			var file:File = File.applicationStorageDirectory.resolvePath("FlashIt.air"); 
			var fileStream:FileStream = new FileStream(); 
			fileStream.open(file, FileMode.WRITE); 
			fileStream.writeBytes(fileData, 0, fileData.length); 
			fileStream.close(); 
			trace("The New Version was Written Down."); 
			var updater:Updater = new Updater(); 

			trace("UPDATER TO VERSIN "+this.newerVersion.toString());
			updater.update(file, this.newerVersion.toString());


		}
	}
}

