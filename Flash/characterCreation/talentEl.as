package
{
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	public dynamic class talentEl extends MovieClip
	{
		public var hit_mc:hit;
		public var min_mc:minusButton;
		public var plus_mc:plusButton;
		public var text_txt:TextField;
		public const racialColour:Number = 6574152;
		public var root_mc:MovieClip;
		public var isRacial:Boolean;
		public var isActive:Boolean;
		public var dColour:Number;

		//CharacterExpansionLib Changes
		public var statID:Number;
		public var callbackStr:String = "showTalentTooltip";
		public var isCustom:Boolean = false;
		public var type:String = "Talent";

		public function MakeCustom(id:Number, b:Boolean=true) : *
		{
			this.statID = id;
			this.isCustom = b;
			if(b)
			{
				this.callbackStr = "showTalentTooltipCustom";
				this.min_mc.callbackStr = "minusTalentCustom";
				this.plus_mc.callbackStr = "plusTalentCustom";
			}
			else
			{
				this.callbackStr = "showTalentTooltip";
				this.min_mc.callbackStr = "minusTalent";
				this.plus_mc.callbackStr = "plusTalent";
			}
		}
		
		public function talentEl()
		{
			super();
		}

		private function onPlus() : void
		{
			if(!this.isCustom)
			{
				ExternalInterface.call("toggleTalent",this.statID);
			}
			else
			{
				ExternalInterface.call(this.plus_mc.callbackStr,this.statID);
			}
		}

		private function onMinus() : void
		{
			if(!this.isCustom)
			{
				ExternalInterface.call("toggleTalent",this.statID);
			}
			else
			{
				ExternalInterface.call(this.min_mc.callbackStr,this.statID);
			}
		}
		
		public function onInit(param1:MovieClip, param2:Boolean) : *
		{
			this.root_mc = param1;
			this.isRacial = param2;
			this.min_mc.visible = false;
			this.plus_mc.visible = false;
			this.text_txt.wordWrap = this.text_txt.multiline = false;
			this.text_txt.autoSize = TextFieldAutoSize.LEFT;
			this.gotoAndStop(1);
			this.plus_mc.init(this.onPlus,this);
			this.min_mc.init(this.onMinus,this);
			this.hit_mc.addEventListener(MouseEvent.ROLL_OVER,this.onOver);
			this.hit_mc.addEventListener(MouseEvent.ROLL_OUT,this.onOut);
		}
		
		public function setState(isActive:Boolean) : *
		{
			if(!this.isRacial)
			{
				this.isActive = isActive;
				this.gotoAndStop(!!isActive?2:1);
				this.plus_mc.visible = !!this.choosable?!isActive && this.root_mc.availableTalentPoints > 0:false;
				this.min_mc.visible = !!this.choosable?Boolean(isActive):false;
				this.text_txt.textColor = this.dColour;
			}
			else
			{
				this.isActive = true;
				this.gotoAndStop(3);
				this.text_txt.textColor = this.racialColour;
			}
		}
		
		public function setText(htmlText:String) : *
		{
			this.text_txt.htmlText = htmlText;
		}
		
		public function onOver(e:MouseEvent) : *
		{
			var globalPos:Point = this.localToGlobal(new Point(0,0));
			ExternalInterface.call(this.callbackStr,this.root_mc.characterHandle,this.statID,globalPos.x - this.root_mc.x,globalPos.y,this.hit_mc.width,this.hit_mc.height,"left");
			//ExternalInterface.call("showTalentTooltip",this.root_mc.characterHandle,this.statID,globalPos.x - this.root_mc.x,globalPos.y,this.hit_mc.width,this.hit_mc.height,"left");
		}
		
		public function onOut(e:MouseEvent) : *
		{
			ExternalInterface.call("hideTooltip");
		}
	}
}
