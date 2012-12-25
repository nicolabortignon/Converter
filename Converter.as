package
{
	import com.bit101.components.ComboBox;
	import com.bortignon.HitTester;
	import com.bortignon.UpdateFramework;
	import com.greensock.TweenMax;
	
	import flash.desktop.DockIcon;
	import flash.desktop.NativeApplication;
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.desktop.SystemTrayIcon;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.NativeMenu;
	import flash.display.NativeMenuItem;
	import flash.events.Event;
	import flash.events.FileListEvent;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.geom.Point;
	import flash.net.FileFilter;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.system.Capabilities;
	import flash.text.TextField;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.getTimer;
	
	
	public class Converter extends MovieClip
	{
		private const _currentVersion:Number = 1.0;
		private var binaryData:ByteArray;
		private var file:File = new File();
		private var nativeProcessStartupInfo:NativeProcessStartupInfo;
		private var nativeProcess:File = new File();
		private var process:NativeProcess;
		
		
		private var kbps64:NativeMenuItem = new NativeMenuItem("64 kbps");
		private var kbps96:NativeMenuItem = new NativeMenuItem("96 kbps");
		private var kbps128:NativeMenuItem = new NativeMenuItem("128 kbps");
		private var kbps160:NativeMenuItem = new NativeMenuItem("160 kbps");
		private var kbps192:NativeMenuItem = new NativeMenuItem("192 kbps");
		private var kbps320:NativeMenuItem = new NativeMenuItem("320 kbps");
		
		private var defaultKbpsValue:NativeMenuItem = kbps192;
		private var contatore:int = 0;
		private	var UF:UpdateFramework;
		
		// CONVERSION FILE
		private var fileArray:Array;
		private var currentFileProcessed:int;
		private var outputFolderFile:File = File.desktopDirectory;
		private var isEncoding:Boolean = false;
		// TOOLS 
		private var startDraggingTime:int;
		
		public const DRAG_TIME_CONSTANT:int = 500;
		
		
		// GRAPHIC BUTTONS
		
		public var openFileButton:MovieClip;
		public var convertFileButton:MovieClip;
		public var outputFolder:MovieClip;
		
		
		
		public function Converter()
		{
			super();
			startCommunication();
			updateText.visible = false;
			updateButton.visible = false;
			updateButton.mouseChildren = false;
			updateButton.buttonMode = true;
			updateButton.useHandCursor = true;
			bg.close.addEventListener(MouseEvent.CLICK, closeApplicationGui);
			bg.addEventListener(MouseEvent.MOUSE_DOWN, letDragApplicationHandler);
			open.buttonMode = true;
			open.mouseChildren = false;
			open.useHandCursor = true;
			bg.addEventListener(MouseEvent.MOUSE_OVER, showCloseBtn);
			bg.addEventListener(MouseEvent.MOUSE_OUT, hideCloseBtn);
			bg.close.buttonMode = true;
			bg.close.mouseChildren = false;
			bg.close.useHandCursor = true;
			bg.close.visible = false;
			bg.close.alpha = 0;
			
			
			// MENU 
			generaContextMenu();
			UF = new UpdateFramework(_currentVersion);
			
			UF.addEventListener("NEW VERSION", newVersion);
			
			this.stage.nativeWindow.alwaysInFront = true;
			progressBar.normalText.text = "CLICK THE DISK AGAIN TO START CONVERTION";
			open.addEventListener(MouseEvent.MOUSE_DOWN, letDragApplicationHandler);
			
			openFileButton.addEventListener(MouseEvent.MOUSE_DOWN, letDragApplicationHandler);
			openFileButton.addEventListener(MouseEvent.MOUSE_UP, ChooseFile);
			openFileButton.addEventListener(MouseEvent.MOUSE_MOVE, overStateOptionButtons);
			openFileButton.addEventListener(MouseEvent.MOUSE_OUT, outStateOptionButtons);
			
			convertFileButton.addEventListener(MouseEvent.MOUSE_DOWN, letDragApplicationHandler);
			convertFileButton.addEventListener(MouseEvent.MOUSE_UP, convertHandler);
			convertFileButton.addEventListener(MouseEvent.MOUSE_MOVE, overStateOptionButtons);
			convertFileButton.addEventListener(MouseEvent.MOUSE_OUT, outStateOptionButtons);
			
			outputFolder.addEventListener(MouseEvent.MOUSE_DOWN, letDragApplicationHandler);
			outputFolder.addEventListener(MouseEvent.MOUSE_UP, pickOutputFolderHandler);
			outputFolder.addEventListener(MouseEvent.MOUSE_MOVE, overStateOptionButtons);
			outputFolder.addEventListener(MouseEvent.MOUSE_OUT, outStateOptionButtons);
			
			openFileButton.buttonMode = 
				outputFolder.buttonMode = 
				convertFileButton.buttonMode = true;
			
			openFileButton.mouseChildren = 
				outputFolder.mouseChildren =
				convertFileButton.mouseChildren = false;
			
			openFileButton.useHandCursor = 
				outputFolder.useHandCursor =
				convertFileButton.useHandCursor = true;
			
		}
		private function overStateOptionButtons(e:MouseEvent):void{
			if(HitTester.realHitTest(e.target as DisplayObject, new Point(e.stageX, e.stageY))){
				e.target.gotoAndStop(2);
			}else {
				e.target.gotoAndStop(1);
			}
		}
		private function outStateOptionButtons(e:MouseEvent):void{
			e.target.gotoAndStop(1);
		}
		
		
		private function newVersion(e:Event){
			updateText.visible = true;
			updateButton.visible = true;
			
			progressBar.visible = false;
			
			updateButton.addEventListener(MouseEvent.CLICK , openNewBrowser);
			updateButton.addEventListener(MouseEvent.MOUSE_OVER,  overState);
			updateButton.addEventListener(MouseEvent.MOUSE_OUT, outState);
			
			
			try{
				open.removeEventListener(MouseEvent.MOUSE_DOWN, ChooseFile);
			} catch(e:Error){}
			try{
				open.removeEventListener(MouseEvent.MOUSE_DOWN, convertHandler);
			} catch(e:Error){}
			
		}
		
		
		private function overState(e:Event):void{
			updateButton.gotoAndStop(2);
		}
		
		private function outState(e:Event):void{
			updateButton.gotoAndStop(1);
		}
		
		private function openNewBrowser(e:Event){
			
			navigateToURL(new URLRequest(UF.newDownloadPath));
		}
		
		private function generaContextMenu():void{
			if(NativeApplication.supportsDockIcon){
				var dockIcon:DockIcon = NativeApplication.nativeApplication.icon as DockIcon;
				
				dockIcon.menu = createIconMenu();
			} else if (NativeApplication.supportsSystemTrayIcon){
				var sysTrayIcon:SystemTrayIcon =
					NativeApplication.nativeApplication.icon as SystemTrayIcon;
				sysTrayIcon.tooltip = "Converter";
				sysTrayIcon.menu = createIconMenu();
			}
			
		}
		
		private function createIconMenu():NativeMenu{
			var iconMenu:NativeMenu = new NativeMenu();
			iconMenu.addItem(kbps64);
			iconMenu.addItem(kbps96);
			iconMenu.addItem(kbps128);
			iconMenu.addItem(kbps160);
			iconMenu.addItem(kbps192);
			iconMenu.addItem(kbps320);
			
			kbps64.addEventListener(Event.SELECT, changeKbps);
			kbps96.addEventListener(Event.SELECT, changeKbps);
			kbps128.addEventListener(Event.SELECT, changeKbps);
			kbps160.addEventListener(Event.SELECT, changeKbps);
			kbps192.addEventListener(Event.SELECT, changeKbps);
			kbps320.addEventListener(Event.SELECT, changeKbps);
			
			kbps192.checked = true;
			return iconMenu;
		}
		
		private function changeKbps(e:Event):void{
			var a:Array = (e.target as NativeMenuItem).label.split(" ");
			defaultKbpsValue.checked = false;
			defaultKbpsValue = (e.target as NativeMenuItem);
			defaultKbpsValue.checked = true;
			trace(a[0]);
		}
		
		private function showCloseBtn(e:MouseEvent):void{
			TweenMax.to(bg.close,1,{autoAlpha:1});
		}
		private function hideCloseBtn(e:MouseEvent):void{
			TweenMax.to(bg.close,1,{autoAlpha:0});
		}
		
		private function pickOutputFolderHandler(e:MouseEvent):void{
			if((getTimer()-startDraggingTime > DRAG_TIME_CONSTANT)  || isEncoding){
				return;
			} else {
				try
				{
					outputFolderFile.browseForDirectory("Select directory for the output files");
					outputFolderFile.addEventListener(Event.SELECT, directorySelected);
				}
				catch (error:Error)
				{
					trace("Failed:", error.message);
				}
			}
		}
		private function directorySelected(event:Event):void 
		{
			outputFolderFile = event.target as File;
		
		}
		private function ChooseFile(e:MouseEvent):void{
			if(getTimer()-startDraggingTime > DRAG_TIME_CONSTANT || isEncoding){
				return;
			} else {
				
				file.addEventListener(FileListEvent.SELECT_MULTIPLE, fileChosen);
				var fFilter:FileFilter = new FileFilter("AUDIO", "*.AIFF;*.aiff;*.aif;*.wav;*.mp3");
				file.browseForOpenMultiple("Choose the raw audio file to convert",[fFilter]);
			}
		}
		
		private function fileChosen(event:FileListEvent):void {
			currentFileProcessed=0;
			fileArray = event.files;
		}
		
		private function letDragApplicationHandler(e:MouseEvent):void{
			e.target.gotoAndStop(1);
			startDraggingTime = getTimer();
			stage.nativeWindow.startMove();
		}
		
		
		/**
		 * Method that closes the application.
		 */
		private function closeApplicationGui(e:MouseEvent):void{
			stage.nativeWindow.close();
			process.exit(true);
		}
		
		
		private function read():void {
			addDebug("READ ");
			var chunkID:String = binaryData.readMultiByte(4, "us-ascii");
			var dataSize:int = binaryData.readInt();
			
			var aiffForm:String = binaryData.readMultiByte(4, "us-ascii");
			if (aiffForm == "AIFF") {
				binaryData.endian = Endian.BIG_ENDIAN;
			} else if (aiffForm == "AIFC") {
				binaryData.endian = Endian.LITTLE_ENDIAN;
			}
		}
		
		
		
		protected function convertHandler(event:MouseEvent = null):void
		{
			if((getTimer()-startDraggingTime > DRAG_TIME_CONSTANT && (event != null)) || isEncoding){
				return;
			} else {
				isEncoding = true;
				open.background.alpha = .3;
				var file:File = fileArray[currentFileProcessed] as File;
				var filename =  file.name.split(".");
				trace(filename[0]);
				addDebug("INIT CONVERT");
				var args:Vector.<String> = new Vector.<String>;
				// optional parameters
				args.push('--abr');
				args.push(defaultKbpsValue.label);
				/*		args.push('-b');
				args.push('defaultKbpsValue');
				args.push('-B');
				args.push('320');
				*/
				args.push(file.nativePath);
				args.push(outputFolderFile.resolvePath(filename[0]+"_converted.mp3").nativePath);
				
				
				//	addDebug(file.nativePath + " _ " + File.desktopDirectory.nativePath + '/clip_per_nicola.mp3');
				trace("CONVERTO " + file.nativePath );
				nativeProcessStartupInfo.arguments = args;
				try{
					process.start(nativeProcessStartupInfo);
				}catch(e:Error){ addDebug("---------- ERRRORE " + e.message)};
				process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
				process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
				process.addEventListener(NativeProcessExitEvent.EXIT, onExit);
				process.addEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, onIOError);
				process.addEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, onIOError);
			}			
			
		}
		
		public function onOutputData(event:ProgressEvent):void
		{
			addDebug("Got: "+ process.standardOutput.readUTFBytes(process.standardOutput.bytesAvailable)); 
		}
		
		public function onErrorData(event:ProgressEvent):void
		{
			open.overlay.alpha = 1-(contatore%10/30);
			updatePercen(contatore++);
			var s:String = process.standardError.readUTFBytes(process.standardError.bytesAvailable);
			var percentuale:String = s.substr(s.indexOf(")|")-3,2);
			if(percentuale == "00") percentuale = "100";
			updatePercen(int (percentuale));
			
		}
		
		public function onExit(event:NativeProcessExitEvent):void
		{
			finished();
			addDebug("Process exited with "+ event.exitCode);
		}
		
		public function onIOError(event:IOErrorEvent):void
		{
			addDebug(event.toString());
		}
		
		
		
		private function startCommunication():void
		{
			addDebug("START COMUNICATION ");
			open.background.alpha = .3;
			
			var nativeProcess:File = File.applicationDirectory;
			nativeProcess = nativeProcess.resolvePath("apps");
			
			if (Capabilities.os.toLowerCase().indexOf("mac") > -1)
				nativeProcess = nativeProcess.resolvePath("lame.bin");
			else if ( Capabilities.os.toLowerCase().indexOf("win") > -1)
				nativeProcess = nativeProcess.resolvePath("lame.exe");
			
			nativeProcessStartupInfo = new NativeProcessStartupInfo();
			nativeProcessStartupInfo.executable = nativeProcess;
			process = new NativeProcess();
			
		}
		
		public function updatePercen(i:int):void{
			progressBar.normalText.text = "Converting: " + i+"%";
			progressBar.overText.text = "Converting: " + i+"%";
			trace(i);
			TweenMax.to(open.maskBar, .5, {y:32-i*0.16});
			
		}
		
		private function finished():void{
			currentFileProcessed++;
			if(fileArray.length == currentFileProcessed){ // se ho lunghezza uguale
				currentFileProcessed = 0 ;
				updatePercen(0);
				open.background.alpha = 1;
				open.maskBar.y = 32;
				isEncoding = false;
				return;	
			} else {
				convertHandler();
			}
			
			/*
			progressBar.normalText.text = "Convertion Finished";
			progressBar.overText.text = "Convertion Finished";
			
			TweenMax.to(open,1,{delay:5.5,alpha:.5, onComplete:function(){
			updatePercen(0);
			open.gotoAndStop(1);
			open.alpha = .8;
			progressBar.normalText.text = "CLICK THE DISK AGAIN TO START CONVERTION";
			open.addEventListener(MouseEvent.MOUSE_DOWN, ChooseFile);
			
			}});
			*/
		}
		private function addDebug(s:String){
			(msg as TextField).appendText(" ------ TESTO "  +s); 
		}
		
		
	}
}

