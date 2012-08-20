////////////////////////////////////////////////////////////////////////////////
//  zengrong.net
//  创建者:	zrong(zrongzrong@gmail.com)
//  创建时间：2011-8-9
////////////////////////////////////////////////////////////////////////////////

package events
{
import flash.events.Event;

public class SSEvent extends Event
{
	public static const ENTER_STATE:String = 'enterState';
	public static const EXIT_STATE:String = 'exitState';
	
	public static const FRAME_AND_LABEL_CHANGE:String = 'frameAndLabelChange';
	
	/**
	 * 选择的帧变化了
	 */
	public static const SELECTED_FRAMEINDICES_CHANGE:String = 'selectedFrameIndicesChange';
	public static const ADD_FRAME:String = 'addFrame';
	
	
	public static const CAPTURE_DONE:String = 'captureDone';
	
	public static const SAVE_PIC:String = 'savePic';
	public static const SAVE_META:String = 'saveMeta';
	public static const SAVE_ALL:String = 'saveAll';
	public static const SAVE_SEQ:String = 'saveSeq';
	
	/**
	 * 收到此事件的时候开始优化Sheet，一般在删除或者增加帧内容的时候执行
	 */
	public static const OPTIMIZE_SHEET:String = 'optimizeSheet';
	/**
	 * 优化完成之后发布此事件
	 */
	public static const OPTIMIZE_SHEET_DONE:String = 'optimizeSheetDone';
	
	public static const FILE_MANAGER_SELECTION_CHANGE:String = 'selectionChange';
	public static const FILE_MANAGER_SELECTION_CHANGING:String = 'selectionChanging';
	
	public static const PREVIEW_LOAD_COMPLETE:String = 'previewLoadComplete';
	public static const PREVIEW_CLICK:String = 'previewClick';
	
	/**
	 * 控制SS的播放
	 */
	public static const PREVIEW_SS_PLAY:String = 'previewSSPlay';
	
	/**
	 * 改变SS中每一帧的大小
	 */
	public static const PREVIEW_SS_RESIZE_SAVE:String = 'previewSSResizeSize';
	
	/**
	 * 发送要预览的帧信息
	 */
	public static const PREVIEW_SS_SHOW:String = 'previewSSShow';
	
	/**
	 * 要预览的帧信息变化
	 */
	public static const PREVIEW_SS_CHANGE:String = 'previewSSDisChange';
	
	/**
	 * 建立或优化SpriteSheet
	 */
	public static const BUILD:String = 'build';
	
	public var info:*;
	
	public function SSEvent($type:String, $info:*=null, $bubbles:Boolean=false, $cancelable:Boolean=false)
	{
		super($type, $bubbles, $cancelable);
		info = $info;
	}
	
	override public function clone():Event
	{
		return new SSEvent(type, info, bubbles, cancelable);
	}		
}
}