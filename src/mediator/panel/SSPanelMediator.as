package mediator.panel
{
import flash.display.BitmapData;
import flash.events.Event;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.text.ReturnKeyLabel;

import events.SSEvent;

import gnu.as3.gettext.FxGettext;

import mediator.comps.FramesAndLabelMediator;

import model.FileProcessor;
import model.SpriteSheetModel;
import model.StateModel;

import org.robotlegs.mvcs.Mediator;
import org.zengrong.display.spritesheet.ISpriteSheetMetadata;
import org.zengrong.display.spritesheet.MaskType;
import org.zengrong.display.spritesheet.SpriteSheetMetadata;
import org.zengrong.display.spritesheet.SpriteSheetMetadataJSON;
import org.zengrong.display.spritesheet.SpriteSheetMetadataStarling;
import org.zengrong.display.spritesheet.SpriteSheetMetadataTXT;
import org.zengrong.display.spritesheet.SpriteSheetMetadataXML;
import org.zengrong.file.FileEnding;
import org.zengrong.utils.BitmapUtil;

import type.StateType;

import utils.Funs;

import view.panel.SSPanel;

import vo.FrameVO;
import vo.LabelListVO;
import vo.SaveVO;

public class SSPanelMediator extends Mediator
{
	[Inject] public var v:SSPanel;
	[Inject] public var file:FileProcessor;
	[Inject] public var stateModel:StateModel;
	[Inject] public var ssModel:SpriteSheetModel;
	
	override public function onRegister():void
	{
		addContextListener(SSEvent.ENTER_STATE, handler_enterState);
		addContextListener(SSEvent.OPTIMIZE_SHEET, handler_optimizeSheet);
		addContextListener(SSEvent.PREVIEW_SS_CHANGE, handler_displayChange);
		addContextListener(SSEvent.PREVIEW_SS_SHOW, handler_previewShow);
		addContextListener(SSEvent.SELECTED_FRAMEINDICES_CHANGE, handler_selected_frameindices_change);
		
		eventMap.mapListener(v.saveSheet, SSEvent.SAVE_ALL, handler_saveAll);
		eventMap.mapListener(v.saveSheet, SSEvent.SAVE_META, handler_saveMeta);
		eventMap.mapListener(v.saveSheet, SSEvent.SAVE_PIC, handler_savePic);
		eventMap.mapListener(v.saveSeq, SSEvent.SAVE_SEQ, handler_saveSeq);
		eventMap.mapListener(v.optPanel, SSEvent.BUILD, handler_build);
		eventMap.mapListener(v.saveSheet.nameCB, Event.CHANGE, handler_nameCBChange);
		eventMap.mapListener(v.sheetPreview, SSEvent.PREVIEW_CLICK, handler_sheetPreviewClick);
		
		enterState();
	}
	
	override public function onRemove():void
	{
		trace('remove');
		removeContextListener(SSEvent.ENTER_STATE, handler_enterState);
		removeContextListener(SSEvent.OPTIMIZE_SHEET, handler_optimizeSheet);
		removeContextListener(SSEvent.PREVIEW_SS_CHANGE, handler_displayChange);
		removeContextListener(SSEvent.PREVIEW_SS_SHOW, handler_previewShow);
		removeContextListener(SSEvent.SELECTED_FRAMEINDICES_CHANGE, handler_selected_frameindices_change);
		
		eventMap.unmapListener(v.saveSheet, SSEvent.SAVE_ALL, handler_saveAll);
		eventMap.unmapListener(v.saveSheet, SSEvent.SAVE_META, handler_saveMeta);
		eventMap.unmapListener(v.saveSheet, SSEvent.SAVE_PIC, handler_savePic);
		eventMap.unmapListener(v.saveSeq, SSEvent.SAVE_SEQ, handler_saveSeq);
		eventMap.unmapListener(v.optPanel, SSEvent.BUILD, handler_build);
		eventMap.unmapListener(v.saveSheet.nameCB, Event.CHANGE, handler_nameCBChange);
		eventMap.unmapListener(v.sheetPreview, SSEvent.PREVIEW_CLICK, handler_sheetPreviewClick);
		
		exitState();
	}
	
	private function handler_sheetPreviewClick($evt:SSEvent):void
	{
		dispatch($evt);
	}
	
	protected function handler_nameCBChange($evt:Event):void
	{
		ssModel.adjustedSheet.metadata.hasName = v.saveSheet.nameCB.selected;
	}
	
	private function handler_displayChange($evt:SSEvent):void
	{
		v.saveSeq.titleLabel.text = ssModel.displayCrop ? 
			FxGettext.gettext("trimmed size"):
			FxGettext.gettext("original size");
	}
	
	private function handler_saveAll($evt:SSEvent):void
	{
		file.save(getAllSave());
		dispatch(new SSEvent(SSEvent.SAVE, getAllSave()));
	}
	
	protected function handler_saveMeta($event:SSEvent):void
	{
		file.save(getMetaSave());
	}
	
	protected function handler_savePic($event:SSEvent):void
	{
		file.save(getPicSave());
		
	}
	
	private function handler_saveSeq($evt:SSEvent):void
	{
		var __vo:SaveVO = getSeqSave();
		file.save(__vo);
	}

	private function handler_enterState($evt:SSEvent):void
	{
		enterState();
	}
	
	private function enterState():void
	{
		if(stateModel.state != StateType.SS) return;
		//更新调整后的Sheet
		ssModel.updateAdjustedSheet();
		v.init(ssModel.adjustedSheet.bitmapData, ssModel.originalSheet.metadata.hasName);
		
		mediatorMap.createMediator(v.framesAndLabels);
	}
	
	private function exitState():void
	{
		ssModel.destroySheet();
		v.destroy();
		
		mediatorMap.removeMediatorByView(v.framesAndLabels);
	}
	
	protected function handler_build($evt:SSEvent):void
	{
		dispatch(new SSEvent(SSEvent.OPTIMIZE_SHEET));
	}
	
	protected function handler_optimizeSheet($evt:SSEvent):void
	{
		optimizeSheet();
	}
	
	//在预览更新的时候，绘制帧的范围
	private function handler_previewShow($evt:SSEvent):void
	{
		//仅在播放的时候才绘制帧的范围
		if(ssModel.playing)
		{
			var __rect:Rectangle = $evt.info.rect as Rectangle;
			v.sheetPreview.clearCanva();
			v.sheetPreview.drawRect(__rect.x, __rect.y, __rect.width, __rect.height);
		}
	}
	
	//在选择帧的时候，绘制选择的帧的范围
	private function handler_selected_frameindices_change($evt:SSEvent):void
	{
		var __frames:Vector.<FrameVO> = $evt.info as Vector.<FrameVO>;
		if(__frames && __frames.length>0)
		{
			v.sheetPreview.clearCanva();
			for (var i:int = 0; i < __frames.length; i++) 
			{
				var __rect:Rectangle = __frames[i].frameRect;
				v.sheetPreview.drawRect(__rect.x, __rect.y, __rect.width, __rect.height);
			}
		}
	}
	
	/**
	 * 根据当前的选择优化Sheet，优化的信息会被写入adjustedSheet中
	 */
	private function optimizeSheet():void
	{
		v.sheetPreview.destroy();
		if(ssModel.originalSheet.metadata.totalFrame==0 || ssModel.adjustedSheet.metadata.totalFrame==0)
		{
			Funs.alert(FxGettext.gettext("No frame info, can not generate the sheet."));
			v.leftPanelBG.enabled = false;
			return;
		}
		trace('优化帧数：', ssModel.originalSheet.metadata.totalFrame, ssModel.adjustedSheet.metadata.totalFrame);
		var __list:Object = ssModel.getRectsAndBmds(v.optPanel.trimCB.selected, v.optPanel.resetRectCB.selected);
		trace('新生成的：', __list.bmd, __list.frame, __list.origin)
		//保存新计算出的WH
		var __whRect:Rectangle = new Rectangle();
		//保存新计算出的每个帧在大Sheet中放置的位置
		var __newFrameRects:Vector.<Rectangle> = new Vector.<Rectangle>;
		//重新计算出最终Sheet的宽高以及修改过的frameRect
		Funs.calculateSize(	
			__list.frame, 
			__newFrameRects, 
			__whRect,
			v.optPanel.whDDL.selectedIndex == 0, 
			v.optPanel.whNS.value,
			v.optPanel.powerOf2CB.selected,
			v.optPanel.squareCB.selected
		);
		ssModel.adjustedSheet.setFrames(__list.bmd, __newFrameRects, __list.origin, ssModel.originalSheet.metadata.names);
		//绘制大Sheet位图
		var __sheetBmd:BitmapData = new BitmapData(__whRect.width, __whRect.height, v.optPanel.transparentCB.selected, v.optPanel.bgColorPicker.selectedColor);
		ssModel.drawAdjustedSheet(__sheetBmd);
		v.sheetPreview.source = ssModel.adjustedSheet.bitmapData;
		//优化完毕，FramesAndLabel需要更新
		dispatch(new SSEvent(SSEvent.OPTIMIZE_SHEET_DONE));
	}
		
	/**
	 * 获取要保存的metadata和位图
	 */
	public function getAllSave():SaveVO
	{
		updateMetadata();
		var __vo:SaveVO = new SaveVO();
		var __bmd:BitmapData = ssModel.getBitmapDataForSave(v.maskTypeValue, v.transparent, v.bgColor);
		__vo.bitmapData = __bmd;
		__vo.metadata = getMetadata();
		__vo.picType = v.saveSheet.imageSetting.imageType;
		__vo.metaType = v.saveSheet.metaRBG.selectedValue.toString();
		__vo.quality = v.saveSheet.imageSetting.qualityValue;
		__vo.type = StateType.SAVE_ALL;
		__vo.isSimple = v.isSimple;
		__vo.includeName = v.includeName;
		return __vo;
	}
	
	public function getMetaSave():SaveVO
	{
		updateMetadata();
		var __vo:SaveVO = new SaveVO();
		__vo.metadata = getMetadata();
		__vo.metaType = v.saveSheet.metaRBG.selectedValue.toString();
		__vo.type = StateType.SAVE_META;
		__vo.isSimple = v.isSimple;
		__vo.includeName = v.includeName;
		return __vo;
	}
	
	public function getPicSave():SaveVO
	{
		updateMetadata();
		var __vo:SaveVO = new SaveVO();
		__vo.bitmapData = ssModel.getBitmapDataForSave(v.maskTypeValue, v.transparent, v.bgColor);
		__vo.picType = v.imageType;
		__vo.quality = v.qualityValue;
		__vo.type = StateType.SAVE_SHEET_PIC;
		return __vo;
	}
	
	public function getSeqSave():SaveVO
	{
		var __vo:SaveVO = new SaveVO();
		__vo.fileNameList = v.saveSeq.getFileNames(ssModel.adjustedSheet.metadata.totalFrame);
		__vo.quality = v.qualityValue;
		__vo.type = StateType.SAVE_SEQ;
		//根据显示的帧类型来保存序列
		__vo.bitmapDataList = ssModel.getBMDList();
		return __vo;
	}
	
	/**
	 * 更新spriteSheet的metadata。在生成新的SpriteSheet前调用。
	 */
	private function updateMetadata():void
	{
		//hasName, names, namesIndex, totalFrame, frameRects, originalFrameRects 这几个变量
		//是在生成Sheet的时候填充的，因此这里不需要更新
		var __meta:ISpriteSheetMetadata = ssModel.adjustedSheet.metadata;
		__meta.type = v.sheetType;
		__meta.maskType = v.saveSheet.maskDDL.selectedIndex;
		var __mediator:FramesAndLabelMediator = mediatorMap.retrieveMediator(v.framesAndLabels) as FramesAndLabelMediator;
		var __labelMeta:LabelListVO = __mediator.getLabels();
		__meta.hasLabel = __labelMeta.hasLabel;
		__meta.labels = __labelMeta.labels;
		__meta.labelsFrame = __labelMeta.labelsFrame;
	}
	
	private function getMetadata():ISpriteSheetMetadata
	{
		var __meta:ISpriteSheetMetadata = null;
		if(v.saveSheet.jsonRB.selected)
		{
			__meta = new SpriteSheetMetadataJSON(ssModel.adjustedSheet.metadata);
		}
		else if(v.saveSheet.xmlRB.selected)
		{
			__meta = new SpriteSheetMetadataXML(ssModel.adjustedSheet.metadata);
			SpriteSheetMetadataXML(__meta).header = Funs.getXMLHeader(FileEnding.UNIX);
		}
		else if(v.saveSheet.starlingRB.selected)
		{
			__meta = new SpriteSheetMetadataStarling(ssModel.adjustedSheet.metadata);
			SpriteSheetMetadataStarling(__meta).header = Funs.getXMLHeader(FileEnding.UNIX);
		}
		else
		{
			__meta = new SpriteSheetMetadataTXT(ssModel.adjustedSheet.metadata);
		}
		return __meta;
	}
}
}