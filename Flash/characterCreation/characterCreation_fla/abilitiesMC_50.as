package characterCreation_fla
{
	import LS_Classes.scrollList;
	import flash.display.MovieClip;
	import flash.external.ExternalInterface;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	public dynamic class abilitiesMC_50 extends MovieClip
	{
		public var abilitiesContainer_mc:MovieClip;
		public var backBtn_mc:brownBtn;
		public var button_mc:greenBtn;
		public var freePoints2_txt:TextField;
		public var freePoints_txt:TextField;
		public var nextBtn_mc:greenBtn;
		public var title2_txt:TextField;
		public var title_txt:TextField;
		public var root_mc:MovieClip;
		public var abilityGroupList:scrollList;
		public var civilAbilityGroupList:scrollList;
		
		public function abilitiesMC_50()
		{
			super();
			addFrameScript(0,this.frame1);
		}
		
		public function onInit(mainTimeline:MovieClip) : *
		{
			this.root_mc = mainTimeline;
			var val2:Number = 321;
			var val3:Number = 372;
			this.button_mc.init(this.root_mc.CCPanel_mc.nextPanel);
			this.backBtn_mc.init(this.root_mc.CCPanel_mc.prevPanel);
			this.nextBtn_mc.init(this.root_mc.CCPanel_mc.nextPanel);
			this.button_mc.visible = this.root_mc.creationType == 0 || this.root_mc.creationType == 2;
			this.backBtn_mc.visible = this.root_mc.creationType == 1;
			this.nextBtn_mc.visible = this.root_mc.creationType == 1;
			this.abilityGroupList = new scrollList();
			this.abilitiesContainer_mc.addChild(this.abilityGroupList);
			this.abilityGroupList.setFrame(340,val2);
			this.abilityGroupList.m_scrollbar_mc.m_hideWhenDisabled = false;
			this.abilityGroupList.m_scrollbar_mc.y = -51;
			this.abilityGroupList.m_scrollbar_mc.setLength(val3);
			this.civilAbilityGroupList = new scrollList();
			this.abilitiesContainer_mc.addChild(this.civilAbilityGroupList);
			this.civilAbilityGroupList.y = 374;
			this.civilAbilityGroupList.setFrame(340,val2);
			this.civilAbilityGroupList.m_scrollbar_mc.m_hideWhenDisabled = false;
			this.civilAbilityGroupList.m_scrollbar_mc.y = -51;
			this.civilAbilityGroupList.m_scrollbar_mc.setLength(val3);
			this.abilityGroupList.mouseWheelWhenOverEnabled = true;
			this.civilAbilityGroupList.mouseWheelWhenOverEnabled = true;
			this.title_txt.multiline = this.title_txt.wordWrap = false;
			this.title_txt.autoSize = TextFieldAutoSize.CENTER;
			this.freePoints_txt.multiline = this.freePoints_txt.wordWrap = false;
			this.freePoints_txt.autoSize = TextFieldAutoSize.CENTER;
			this.title2_txt.multiline = this.title_txt.wordWrap = false;
			this.title2_txt.autoSize = TextFieldAutoSize.CENTER;
			this.freePoints2_txt.multiline = this.freePoints_txt.wordWrap = false;
			this.freePoints2_txt.autoSize = TextFieldAutoSize.CENTER;
		}
		
		public function onPlus(mc:MovieClip) : *
		{
			ExternalInterface.call(mc.plus_mc.callbackStr, mc.statID, mc.isCivil);
		}
		
		public function onMin(mc:MovieClip) : *
		{
			ExternalInterface.call(mc.min_mc.callbackStr, mc.statID, mc.isCivil);
		}
		
		public function updateAbilities(param1:Array) : *
		{
			var contentArr:Array = null;
			var i:uint = 0;
			var groupID:uint = 0;
			var groupTitle:String = null;
			var statID:uint = 0;
			var abilityLabel:String = null;
			var abilityValue:Number = NaN;
			var abilityDelta:Number = NaN;
			var isCivil:Boolean = false;
			if(param1.length > 0)
			{
				contentArr = new Array();
				i = 0;
				while(i < param1.length)
				{
					groupID = param1[i++];
					groupTitle = param1[i++];
					statID = param1[i++];
					abilityLabel = param1[i++];
					abilityValue = param1[i++];
					abilityDelta = param1[i++];
					isCivil = param1[i++];
					this.addAbility(groupID,groupTitle,statID,abilityLabel,abilityValue,abilityDelta,isCivil);
					if(abilityDelta > 0)
					{
						contentArr.push(statID);
						contentArr.push(abilityLabel);
						contentArr.push(abilityDelta);
					}
					this.root_mc.CCPanel_mc.class_mc.addTabTextContent(1,contentArr);
				}
				this.freePoints_txt.htmlText = this.root_mc.textArray[13] + " " + this.root_mc.availableAbilityPoints;
				this.freePoints2_txt.htmlText = this.root_mc.textArray[13] + " " + this.root_mc.availableCivilPoints;
			}
			this.postUpdate(this.civilAbilityGroupList);
			this.postUpdate(this.abilityGroupList);
		}

		public function updateComplete() : *
		{
			this.freePoints_txt.htmlText = this.root_mc.textArray[13] + " " + this.root_mc.availableAbilityPoints;
			this.freePoints2_txt.htmlText = this.root_mc.textArray[13] + " " + this.root_mc.availableCivilPoints;
			this.postUpdate(this.civilAbilityGroupList);
			this.postUpdate(this.abilityGroupList);
		}
		
		public function postUpdate(param1:scrollList) : *
		{
			var val2:MovieClip = null;
			for each(val2 in param1.content_array)
			{
				val2.abilities.cleanUpElements();
				val2.calculateTotalVal();
			}
			param1.cleanUpElements();
		}
		
		public function addAbility(groupID:uint, groupTitle:String, statID:uint, abilityLabel:String, abilityValue:Number, abilityDelta:Number, isCivil:Boolean, isCustom:Boolean=false) : *
		{
			var abilityGroup_mc:MovieClip = this.findGroup(groupID,groupTitle,isCivil);
			abilityGroup_mc.addAbility(statID,abilityLabel,abilityValue,abilityDelta,isCivil,isCustom);
		}

		public function addAbilityGroup(groupID:uint, title:String, isCivil:Boolean) : void
		{
			this.findGroup(groupID, title, isCivil);
		}
		
		public function findGroup(groupID:uint, title:String, isCivil:Boolean) : MovieClip
		{
			var abilityGroup_mc:MovieClip = !!isCivil?this.civilAbilityGroupList.getElementByNumber("groupID",groupID):this.abilityGroupList.getElementByNumber("groupID",groupID);
			if(!abilityGroup_mc)
			{
				abilityGroup_mc = new abilityGroup();
				abilityGroup_mc.onInit(this.root_mc);
				if(isCivil)
				{
					this.civilAbilityGroupList.addElement(abilityGroup_mc,false);
				}
				else
				{
					this.abilityGroupList.addElement(abilityGroup_mc,false);
				}
				abilityGroup_mc.groupID = groupID;
			}
			abilityGroup_mc.setTitle(title);
			abilityGroup_mc.isUpdated = true;
			return abilityGroup_mc;
		}
		
		public function frame1() : * {}
	}
}
