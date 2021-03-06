package
{
	import LS_Classes.larTween;
	import fl.motion.easing.Quartic;
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	
	public dynamic class InfoStat extends MovieClip
	{
		public var hl_mc:MovieClip;
		public var icon_mc:MovieClip;
		public var minus_mc:MovieClip;
		public var plus_mc:MovieClip;
		public var texts_mc:MovieClip;
		public var timeline:larTween;
		public var base:MovieClip;

		//CharacterExpansionLib Changes
		public var statID:Number;
		public var statType:int = 0;
		public var tooltip:Number; // The tooltip ID
		public var callbackStr:String = "showStatTooltip";
		public var isCustom:Boolean = false;
		public var hasCustomIcon:Boolean = false;
		public var customIcon_mc:IggyIcon;
		public var type:String = "InfoStat";

		public function MakeCustom(statID:Number, b:Boolean=true) : *
		{
			this.statID = statID;
			this.isCustom = b;
			if(b)
			{
				this.callbackStr = "showStatTooltipCustom";
				this.minus_mc.callbackStr = "minusSecStatCustom";
				this.plus_mc.callbackStr = "plusSecStatCustom";
			}
			else
			{
				this.callbackStr = "showStatTooltip";
				this.minus_mc.callbackStr = "minusSecStat";
				this.plus_mc.callbackStr = "plusSecStat";
			}
		}
		
		public function InfoStat()
		{
			super();
			addFrameScript(0,this.frame1);
		}
		
		public function onOver(e:MouseEvent) : *
		{
			!isCustom ? this.base.showCustomTooltipForMC(this, this.callbackStr, this.tooltip) : this.base.showCustomTooltipForMC(this, this.callbackStr, this.statID);
			if(this.timeline && this.timeline.isPlaying)
			{
				this.timeline.stop();
			}
			this.timeline = new larTween(this.hl_mc,"alpha",Quartic.easeIn,this.hl_mc.alpha,0.4,0.01);
		}
		
		public function onOut(e:MouseEvent) : *
		{
			this.timeline = new larTween(this.hl_mc,"alpha",Quartic.easeOut,this.hl_mc.alpha,0,0.01,this.hlInvis);
			this.base.hasTooltip = false;
			ExternalInterface.call("hideTooltip");
		}
		
		public function hlInvis() : *
		{
		}

		//CharacterExpansionLib
		public function SetCustomIcon(iconName:String, offsetX:Number = 0, offsetY:Number = 0, useDefaultOffset:Boolean = true) : Boolean
		{
			if(useDefaultOffset) {
				this.base = root as MovieClip;
				offsetX = this.base.stats_mc.customSecStatIconOffsetX;
				offsetY = this.base.stats_mc.customSecStatIconOffsetY;
			}
			this.icon_mc.visible = false;
			if(this.customIcon_mc == undefined)
			{
				this.customIcon_mc = new IggyIcon();
				this.customIcon_mc.mouseEnabled = false;
				this.addChild(this.customIcon_mc);
				this.customIcon_mc.scale = 0.4375; // 28/64
			}
			this.customIcon_mc.x = this.icon_mc.x + offsetX;
			this.customIcon_mc.y = this.icon_mc.y + offsetY;
			this.customIcon_mc.name = iconName;
			this.customIcon_mc.visible = true;
			this.hasCustomIcon = true;
			this.texts_mc.x = 2.0;
			this.texts_mc.text_txt.x = 206.95999145508;
			return true;
		}

		public function RemoveCustomIcon() : Boolean
		{
			this.hasCustomIcon = false;
			this.icon_mc.visible = true;
			if(this.customIcon_mc != undefined)
			{
				this.removeChild(this.customIcon_mc);
				this.customIcon_mc = null;
				return true;
			}
			return false;
		}
		
		public function frame1() : *
		{
			this.base = root as MovieClip;
			this.hl_mc.addEventListener(MouseEvent.ROLL_OVER,this.onOver);
			this.hl_mc.addEventListener(MouseEvent.ROLL_OUT,this.onOut);
			this.hl_mc.alpha = 0;
			// this.minus_mc.callbackStr = "minusSecStat";
			// this.plus_mc.callbackStr = "plusSecStat";
		}
	}
}
