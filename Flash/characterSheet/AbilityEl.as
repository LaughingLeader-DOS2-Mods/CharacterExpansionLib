package
{
	import LS_Classes.larTween;
	import fl.motion.easing.Quartic;
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	
	public dynamic class AbilityEl extends MovieClip
	{
		public var abilTooltip_mc:MovieClip;
		public var hl_mc:MovieClip;
		public var texts_mc:MovieClip;
		public var timeline:larTween;
		public var base:MovieClip;
		public var isCivil:Boolean;

		//CharacterExpansionLib Changes
		public var statID:Number;
		public var callbackStr:String = "showAbilityTooltip";
		public var isCustom:Boolean = false;
		public var type:String = "Ability";

		public function MakeCustom(id:Number, b:Boolean=true) : *
		{
			this.statID = id;
			this.isCustom = b;
			if(b)
			{
				this.callbackStr = "showAbilityTooltipCustom";
				this.texts_mc.minus_mc.callbackStr = "minusAbilityCustom";
				this.texts_mc.plus_mc.callbackStr = "plusAbilityCustom";
			}
			else
			{
				this.callbackStr = "showAbilityTooltip";
				this.texts_mc.minus_mc.callbackStr = "minusAbility";
				this.texts_mc.plus_mc.callbackStr = "plusAbility";
			}
		}
		
		public function AbilityEl()
		{
			super();
			addFrameScript(0,this.frame1);
		}
		
		public function onOver(param1:MouseEvent) : *
		{
			if(this.timeline && this.timeline.isPlaying)
			{
				this.timeline.stop();
			}
			this.hl_mc.visible = true;
			this.timeline = new larTween(this.hl_mc,"alpha",Quartic.easeIn,this.hl_mc.alpha,1,0.01);
		}
		
		public function onOut(e:MouseEvent) : *
		{
			this.timeline = new larTween(this.hl_mc,"alpha",Quartic.easeOut,this.hl_mc.alpha,0,0.01,this.hlInvis);
		}
		
		public function onHLOver(e:MouseEvent) : *
		{
			if(this.isCivil)
			{
				this.mOffsetY = -this.base.stats_mc.civicAbilityHolder_mc.list.m_scrollbar_mc.scrolledY - 27;
			}
			else
			{
				this.mOffsetY = -this.base.stats_mc.combatAbilityHolder_mc.list.m_scrollbar_mc.scrolledY - 27;
			}
			this.mOffsetX = -26;
			this.base.showCustomTooltipForMC(this, this.callbackStr, this.statID);
		}
		
		public function onHLOut(e:MouseEvent) : *
		{
			this.base.hasTooltip = false;
			ExternalInterface.call("hideTooltip");
		}
		
		public function hlInvis() : *
		{
			this.hl_mc.visible = false;
		}
		
		public function frame1() : *
		{
			this.base = root as MovieClip;
			addEventListener(MouseEvent.ROLL_OVER,this.onOver);
			addEventListener(MouseEvent.ROLL_OUT,this.onOut);
			this.abilTooltip_mc.addEventListener(MouseEvent.ROLL_OVER,this.onHLOver);
			this.abilTooltip_mc.addEventListener(MouseEvent.ROLL_OUT,this.onHLOut);
			this.hl_mc.visible = false;
			this.hl_mc.alpha = 0;
			// this.texts_mc.minus_mc.callbackStr = "minusAbility";
			// this.texts_mc.plus_mc.callbackStr = "plusAbility";
			hitArea = this.hl_mc;
			this.texts_mc.label_txt.mouseEnabled = false;
			this.texts_mc.text_txt.mouseEnabled = false;
		}
	}
}
