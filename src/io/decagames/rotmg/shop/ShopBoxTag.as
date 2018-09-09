package io.decagames.rotmg.shop
{
import flash.display.*;
import flash.text.*;
import io.decagames.rotmg.ui.defaults.*;
import io.decagames.rotmg.ui.labels.*;
import io.decagames.rotmg.ui.sliceScaling.*;
import io.decagames.rotmg.ui.texture.*;

public class ShopBoxTag extends flash.display.Sprite
{
    public function ShopBoxTag(arg1:String, arg2:String, arg3:Boolean=false)
    {
        super();
        this._color = arg1;
        this.background = io.decagames.rotmg.ui.texture.TextureParser.instance.getSliceScalingBitmap("UI", arg1);
        this.background.scaleType = io.decagames.rotmg.ui.sliceScaling.SliceScalingBitmap.SCALE_TYPE_9;
        addChild(this.background);
        this._label = new io.decagames.rotmg.ui.labels.UILabel();
        this._label.autoSize = flash.text.TextFieldAutoSize.LEFT;
        this._label.text = arg2;
        this._label.x = 4;
        if (arg3)
        {
            io.decagames.rotmg.ui.defaults.DefaultLabelFormat.popupTag(this._label);
        }
        else
        {
            io.decagames.rotmg.ui.defaults.DefaultLabelFormat.shopTag(this._label);
        }
        addChild(this._label);
        this.background.width = this._label.textWidth + 8;
        this.background.height = this._label.textHeight + 8;
        return;
    }

    public function updateLabel(arg1:String):void
    {
        this._label.text = arg1;
        this.background.width = this._label.textWidth + 8;
        this.background.height = this._label.textHeight + 8;
        return;
    }

    public function dispose():void
    {
        this.background.dispose();
        return;
    }

    public function get color():String
    {
        return this._color;
    }

    public static const BLUE_TAG:String="shop_blue_tag";

    public static const ORANGE_TAG:String="shop_orange_tag";

    public static const GREEN_TAG:String="shop_green_tag";

    public static const PURPLE_TAG:String="shop_purple_tag";

    public static const RED_TAG:String="shop_red_tag";

    internal var background:io.decagames.rotmg.ui.sliceScaling.SliceScalingBitmap;

    internal var _color:String;

    internal var _label:io.decagames.rotmg.ui.labels.UILabel;
}
}
