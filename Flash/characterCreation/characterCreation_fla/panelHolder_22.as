package characterCreation_fla
{
	import LS_Classes.tooltipHelper;
	import flash.display.MovieClip;
	import flash.external.ExternalInterface;
	import flash.text.TextField;
	
	public dynamic class panelHolder_22 extends MovieClip
	{
		public var abilities_mc:MovieClip;
		public var appearance_mc:MovieClip;
		public var armourBtnHolder_mc:MovieClip;
		public var attributes_mc:MovieClip;
		public var class_mc:MovieClip;
		public var instruments_mc:MovieClip;
		public var origins_mc:MovieClip;
		public var skills_mc:MovieClip;
		public var tags_mc:MovieClip;
		public var talents_mc:MovieClip;
		public var title_txt:TextField;
		public var panelArray:Array;
		public var contentArray:Array;
		public var root_mc:MovieClip;
		
		public function panelHolder_22()
		{
			super();
			addFrameScript(0,this.frame1);
		}
		
		public function onInit(mainTimeline:MovieClip) : *
		{
			this.root_mc = mainTimeline;
			this.panelArray = new Array(this.origins_mc,this.appearance_mc,this.class_mc,this.attributes_mc,this.abilities_mc,null,this.skills_mc,this.talents_mc,this.tags_mc,this.instruments_mc);
			this.contentArray = new Array(this.origins_mc.originSelector_mc,this.origins_mc.presetSelector_mc,this.root_mc.header_mc.textFieldName_mc,this.appearance_mc.faceSelector_mc,this.appearance_mc.facialSelector_mc,this.appearance_mc.hairSelector_mc,this.appearance_mc.skinSelector_mc,this.appearance_mc.hairColourSelector_mc,this.appearance_mc.voiceSelector_mc,this.class_mc.classSelector_mc);
			var i:uint = 0;
			while(i < this.panelArray.length)
			{
				if(this.panelArray[i] != null)
				{
					this.panelArray[i].onInit(this.root_mc);
					if(this.panelArray[i].nextBtn_mc)
					{
						this.panelArray[i].nextBtn_mc.visible = false;
					}
					if(this.panelArray[i].backBtn_mc)
					{
						this.panelArray[i].backBtn_mc.visible = false;
					}
				}
				i++;
			}
			i = 0;
			while(i < this.contentArray.length)
			{
				if(this.contentArray[i] != null && this.contentArray[i].onInit != null)
				{
					this.contentArray[i].onInit(this.root_mc);
					this.contentArray[i].contentID = i;
				}
				i++;
			}
			this.origins_mc.maleBtn_mc.onOverFunc = this.origins_mc.femaleBtn_mc.onOverFunc = this.showButtonTooltip;
			this.armourBtnHolder_mc.armourBtn_mc.onOverFunc = this.armourBtnHolder_mc.helmetBtn_mc.onOverFunc = this.showButtonTooltip;
			this.origins_mc.maleBtn_mc.onOutFunc = this.origins_mc.femaleBtn_mc.onOutFunc = this.hideButtonTooltip;
			this.armourBtnHolder_mc.armourBtn_mc.onOutFunc = this.armourBtnHolder_mc.helmetBtn_mc.onOutFunc = this.hideButtonTooltip;
		}
		
		public function showButtonTooltip(mc:MovieClip) : *
		{
			ExternalInterface.call("PlaySound","UI_Generic_Over");
			if(mc.tooltip != null)
			{
				tooltipHelper.ShowTooltipForMC(mc,this.root_mc,"top");
			}
		}
		
		public function hideButtonTooltip() : *
		{
			ExternalInterface.call("hideTooltip");
		}
		
		public function prevPanel() : *
		{
			ExternalInterface.call("previousStep",this.root_mc.currentPanel);
		}
		
		public function nextPanel() : *
		{
			ExternalInterface.call("nextStep",this.root_mc.currentPanel);
		}
		
		public function updateContent(arr:Array) : *
		{
			var val2:uint = 0;
			var val3:uint = 0;
			var val4:uint = 0;
			var val5:uint = 0;
			var val6:String = null;
			var val7:uint = 0;
			var val8:MovieClip = null;
			var val9:MovieClip = null;
			var val10:uint = 0;
			var val11:Array = null;
			var val12:uint = 0;
			var val13:String = null;
			var val14:* = undefined;
			var val15:uint = 0;
			if(arr.length > 0)
			{
				val2 = 0;
				while(val2 < arr.length)
				{
					val3 = arr[val2++];
					switch(val3)
					{
						case 0:
						case 3:
							ExternalInterface.call("UIAssert","Keyboard CC isn\'t dynamic! Got Parser ID: " + val3);
							continue;
						case 1:
							val4 = arr[val2++];
							val5 = arr[val2++];
							val6 = arr[val2++];
							//id:uint, optionID:uint, text:String
							this.addOption(val4,val5,val6);
							continue;
						case 2:
							val4 = arr[val2++];
							val5 = arr[val2++];
							val7 = arr[val2++];
							val8 = this.findContentByID(val4);
							val9 = null;
							switch(val7)
							{
								case 0:
									val6 = arr[val2++];
									val9 = new txtContent();
									val9.canCenter = false;
									val9.setText(val6);
									break;
								case 1:
									val6 = arr[val2++];
									val10 = arr[val2++];
									val11 = new Array();
									val12 = 0;
									while(val12 < val10)
									{
										val11.push(arr[val2++]);
										val11.push(arr[val2++]);
										val12++;
									}
									val9 = new listContent();
									val9.canCenter = true;
									val9.onInit(this.root_mc);
									val9.setupList(val6,val11);
									break;
								case 2:
									val13 = arr[val2++];
									val14 = arr[val2++];
									val9 = new cdContent();
									val9.canCenter = true;
									val9.onInit(this.root_mc);
									//name:String, skillCount:uint
									val9.setIcon(val13,val14);
									break;
								case 3:
									val6 = arr[val2++];
									val8.addTooltip(val5,val6);
							}
							if(val9 && val8)
							{
								val8.addContent(val5,val9);
							}
							continue;
						case 4:
							val15 = arr[val2++];
							val6 = arr[val2++];
							val9 = this.findContentByID(val15);
							if(val9)
							{
								val9.setTitle(val6.toUpperCase());
							}
							continue;
						default:
							continue;
					}
				}
			}
		}
		
		public function findOptionByID(id:uint) : Object
		{
			var content_mc:MovieClip = null;
			var option_mc:Object = null;
			for each(content_mc in this.contentArray)
			{
				option_mc = content_mc.findOptionByID(id);
				if(option_mc != null)
				{
					break;
				}
			}
			return option_mc;
		}
		
		public function setTextField(index:uint, text:String, canInput:Boolean) : *
		{
			var tf_mc:MovieClip = index < this.contentArray.length?this.contentArray[index]:null;
			if(tf_mc && tf_mc.setText != null)
			{
				tf_mc.setText(text,canInput);
			}
		}
		
		public function clearPanelSelectors(panelIndex:uint) : *
		{
			if(panelIndex == 1)
			{
				this.appearance_mc.faceSelector_mc.clearOptions();
				this.appearance_mc.facialSelector_mc.clearOptions();
				this.appearance_mc.hairSelector_mc.clearOptions();
				this.appearance_mc.skinSelector_mc.clearOptions();
				this.appearance_mc.hairColourSelector_mc.clearOptions();
			}
		}
		
		public function addOption(id:uint, optionID:uint, text:String) : *
		{
			var content_mc:MovieClip = this.findContentByID(id);
			if(content_mc)
			{
				content_mc.addOption(optionID,text);
			}
		}
		
		public function setPanel(index:uint, selectTabIndex:uint) : *
		{
			var i:uint = 0;
			while(i < this.panelArray.length)
			{
				if(this.panelArray[i] != null)
				{
					this.panelArray[i].visible = i == index;
				}
				i++;
			}
			if(index == 10)
			{
				this.root_mc.header_mc.stepTabs.visible = false;
			}
			else
			{
				this.root_mc.header_mc.selectTab(selectTabIndex);
			}
			this.root_mc.currentPanel = index;
			var titleIndex:Number = index;
			if(titleIndex > 4)
			{
				titleIndex--;
			}
			if(titleIndex < this.panelArray.length)
			{
				this.title_txt.htmlText = this.root_mc.panelTitles[titleIndex].toUpperCase();
			}
			this.title_txt.visible = titleIndex < this.panelArray.length;
		}
		
		public function findContentByID(id:uint) : MovieClip
		{
			var content_mc:MovieClip = null;
			if(id < this.contentArray.length)
			{
				content_mc = this.contentArray[id];
			}
			return content_mc;
		}
		
		public function frame1() : *
		{
		}
	}
}