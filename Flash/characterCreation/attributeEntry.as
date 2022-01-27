package
{
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.external.ExternalInterface;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	public dynamic class attributeEntry extends MovieClip
	{
		public var hit_mc:hit;
		public var icon_mc:MovieClip;
		public var min_mc:minusButton;
		public var plus_mc:plusButton;
		public var title_txt:TextField;
		public var value_txt:TextField;
		public var root_mc:MovieClip;
		public var currentValue:Number;
		public var deltaValue:Number;
		public var attributeInfo:String;

		//CharacterExpansionLib Changes
		public var statID:Number;
		public var callbackID:Number;
		public var attrID:Number; // Just in case Larian checks this in engine
		public var tooltip:Number; // The tooltip ID
		public var callbackStr:String = "showStatTooltip";
		public var isCustom:Boolean = false;
		public var type:String = "PrimaryStat";

		public function MakeCustom(id:Number, b:Boolean=true) : *
		{
			this.statID = id;
			this.isCustom = b;
			if(b)
			{
				this.callbackStr = "showStatTooltipCustom";
				this.min_mc.callbackStr = "minusStatCustom";
				this.plus_mc.callbackStr = "plusStatCustom";
			}
			else
			{
				this.attrID = id;
				this.callbackStr = "showStatTooltip";
				this.min_mc.callbackStr = "minAttribute";
				this.plus_mc.callbackStr = "plusAttribute";
			}
		}

		//CharacterExpansionLib
		public function SetCustomIcon(iconName:String, offsetX:Number = 0, offsetY:Number = 0, iconScale:Number = 0.5) : Boolean
		{
			this.icon_mc.visible = false;
			if(this.customIcon_mc == undefined)
			{
				this.customIcon_mc = new IggyCont();
				this.customIcon_mc.mouseEnabled = false;
				this.addChild(this.customIcon_mc);
				this.customIcon_mc.scale = iconScale; // 0.5 = 32 regular icon size / 64 iggy icon size
			}
			this.customIcon_mc.x = this.icon_mc.x + offsetX;
			this.customIcon_mc.y = this.icon_mc.y + offsetY;
			this.customIcon_mc.name = iconName;
			this.customIcon_mc.visible = true;
			this.hasCustomIcon = true;
			return true;
		}

		public function RemoveCustomIcon() : Boolean
		{
			this.icon_mc.visible = true;
			this.hasCustomIcon = false;
			if(this.customIcon_mc != undefined)
			{
				this.removeChild(this.customIcon_mc);
				this.customIcon_mc = null;
				return true;
			}
			return false;
		}
		
		public function attributeEntry()
		{
			super();
		}
		
		public function onInit(param1:MovieClip, param2:Function, param3:Function) : *
		{
			this.root_mc = param1;
			this.title_txt.wordWrap = false;
			this.title_txt.multiline = false;
			this.title_txt.autoSize = TextFieldAutoSize.LEFT;
			this.plus_mc.init(param2,this);
			this.min_mc.init(param3,this);
			this.hit_mc.addEventListener(MouseEvent.ROLL_OVER,this.onHover);
			this.hit_mc.addEventListener(MouseEvent.ROLL_OUT,this.onOut);
		}
		
		public function onHover(e:MouseEvent) : *
		{
			var pos:Point = this.localToGlobal(new Point(0,0));
			ExternalInterface.call(this.callbackStr, this.root_mc.characterHandle, this.statID, pos.x - this.root_mc.x, pos.y, this.hit_mc.width, this.hit_mc.height,"left");
		}
		
		public function onOut(e:MouseEvent) : *
		{
			ExternalInterface.call("hideTooltip");
		}
		
		public function setAttribute(label:String, attributeInfo:String) : *
		{
			this.title_txt.htmlText = label;
			this.attributeInfo = attributeInfo;
			this.hit_mc.width = this.title_txt.width;
			this.hit_mc.height = this.title_txt.height;
		}
		
		public function setValue(value:Number, delta:Number) : *
		{
			this.currentValue = value;
			this.deltaValue = delta;
			this.min_mc.visible = this.deltaValue > 0;
			this.plus_mc.visible = this.root_mc.availableAttributePoints > 0 && (this.deltaValue < this.root_mc.attributeCap || this.root_mc.attributeCap < 0);
			this.value_txt.htmlText = String(value);

			this.hit_mc.x = -30;
			this.hit_mc.width = this.icon_mc.width + this.value_txt.x + this.value_txt.width;
			this.hit_mc.height = 27;
		}
	}
}
