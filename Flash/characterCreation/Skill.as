package
{
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Point;
	
	public dynamic class Skill extends MovieClip
	{
		public var chosenSkillBg_mc:MovieClip;
		public var hl_mc:MovieClip;
		public var skillActivated_mc:MovieClip;
		public const minMouseOffset:Number = 5;
		public var root_mc:MovieClip;
		public var mousePosX:Number;
		public var mousePosY:Number;
		public var m_slotPos:int;
		
		public function Skill()
		{
			super();
			addFrameScript(0,this.frame1);
		}
		
		public function set slotPos(index:int) : void
		{
			this.m_slotPos = index;
			this.chosenSkillBg_mc.slotPos = this.m_slotPos;
		}
		
		public function get slotPos() : int
		{
			return this.m_slotPos;
		}
		
		public function set unused(b:Boolean) : void
		{
			this.chosenSkillBg_mc.visible = b;
			this.hl_mc.visible = !b;
			this.skillActivated_mc.visible = false;
		}
		
		public function Init() : void
		{
			this.hl_mc.addEventListener(MouseEvent.ROLL_OVER,this.onOver);
			this.hl_mc.addEventListener(MouseEvent.ROLL_OUT,this.onOut);
			this.hl_mc.addEventListener(MouseEvent.MOUSE_DOWN,this.onDown);
			this.hl_mc.alpha = 0;
			if(this.isChosenSkill)
			{
				this.skillActivated_mc.visible = false;
			}
			this.chosenSkillBg_mc.visible = false;
		}
		
		public function onOver(e:MouseEvent) : void
		{
			var pos:Point = null;
			if(!this.root_mc.isDragging)
			{
				pos = this.localToGlobal(new Point(0,0));
				ExternalInterface.call("showSkillTooltip",this.root_mc.characterHandle,this.skillID,pos.x + 10 - this.root_mc.x,pos.y,this.hl_mc.width,this.hl_mc.height);
			}
			else
			{
				addEventListener(MouseEvent.MOUSE_UP,this.onUp);
			}
			if(!this.root_mc.isDragging || this.isChosenSkill)
			{
				this.hl_mc.alpha = 0.3;
			}
		}
		
		public function onOut(e:MouseEvent) : void
		{
			removeEventListener(MouseEvent.MOUSE_UP,this.onUp);
			removeEventListener(MouseEvent.MOUSE_MOVE,this.dragging);
			ExternalInterface.call("hideTooltip");
			this.hl_mc.alpha = 0;
		}
		
		public function onDown(e:MouseEvent) : void
		{
			addEventListener(MouseEvent.MOUSE_MOVE,this.dragging);
			addEventListener(MouseEvent.MOUSE_UP,this.onUp);
			this.hl_mc.alpha = 0.3;
			this.mousePosX = stage.mouseX;
			this.mousePosY = stage.mouseY;
		}
		
		public function dragging() : void
		{
			if((this.mousePosX + this.minMouseOffset < stage.mouseX || this.mousePosX - this.minMouseOffset > stage.mouseX || this.mousePosY + this.minMouseOffset < stage.mouseY || this.mousePosY - this.minMouseOffset > stage.mouseY) && !this.root_mc.isDragging)
			{
				ExternalInterface.call("startDragging",this.skillID,this.listPos != null?this.listPos:-1);
				removeEventListener(MouseEvent.MOUSE_UP,this.onUp);
				removeEventListener(MouseEvent.MOUSE_MOVE,this.dragging);
			}
		}
		
		public function onUp(e:MouseEvent) : void
		{
			removeEventListener(MouseEvent.MOUSE_UP,this.onUp);
			ExternalInterface.call("useSkill",this.skillID,this.listPos != null?this.listPos:-1);
			this.hl_mc.alpha = 0;
		}
		
		private function frame1() : void
		{
			this.mousePosX = 0;
			this.mousePosY = 0;
		}
	}
}
