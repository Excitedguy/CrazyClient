package io.decagames.rotmg.shop.packages
{
import flash.display.*;
import io.decagames.rotmg.shop.genericBox.*;
import io.decagames.rotmg.shop.genericBox.data.*;
import io.decagames.rotmg.ui.sliceScaling.*;
import kabam.rotmg.packages.model.*;

public class PackageBoxTile extends io.decagames.rotmg.shop.genericBox.GenericBoxTile
{
    public function PackageBoxTile(arg1:io.decagames.rotmg.shop.genericBox.data.GenericBoxInfo, arg2:Boolean=false)
    {
        buyButtonBitmapBackground = "buy_button_background";
        backgroundContainer = new flash.display.Sprite();
        super(arg1, arg2);
        return;
    }

    protected override function createBoxBackground():void
    {
        addChild(backgroundContainer);
        this.resizeBackgroundImage();
        return;
    }

    internal function resizeBackgroundImage():void
    {
        var loc1:*=null;
        if (_isPopup)
        {
            loc1 = kabam.rotmg.packages.model.PackageInfo(_boxInfo).popupLoader;
        }
        else
        {
            loc1 = kabam.rotmg.packages.model.PackageInfo(_boxInfo).loader;
        }
        if (loc1 && !(loc1.parent == backgroundContainer))
        {
            backgroundContainer.addChild(loc1);
            backgroundContainer.cacheAsBitmap = true;
            this.imageMask = background.clone();
            addChild(this.imageMask);
            this.imageMask.cacheAsBitmap = true;
            backgroundContainer.mask = this.imageMask;
        }
        if (this.imageMask)
        {
            this.imageMask.width = background.width - 6;
            this.imageMask.height = background.height - 6;
            this.imageMask.x = background.x + 3;
            this.imageMask.y = background.y + 3;
            this.imageMask.cacheAsBitmap = true;
        }
        return;
    }

    public override function dispose():void
    {
        this.imageMask.dispose();
        super.dispose();
        return;
    }

    public override function resize(arg1:int, arg2:int=-1):void
    {
        background.width = arg1;
        if (backgroundTitle)
        {
            backgroundTitle.width = arg1;
            backgroundTitle.y = 2;
        }
        backgroundButton.width = 158;
        if (arg2 != -1)
        {
            background.height = arg2;
        }
        else
        {
            background.height = 184;
        }
        titleLabel.x = Math.round((arg1 - titleLabel.textWidth) / 2);
        titleLabel.y = 6;
        backgroundButton.y = background.height - 51;
        backgroundButton.x = Math.round((arg1 - backgroundButton.width) / 2);
        _buyButton.y = backgroundButton.y + 4;
        _buyButton.x = backgroundButton.x + backgroundButton.width - _buyButton.width - 6;
        if (_infoButton)
        {
            _infoButton.x = background.width - _infoButton.width - 3;
            _infoButton.y = 2;
        }
        _spinner.x = backgroundButton.x + 34;
        _spinner.y = background.height - 53;
        this.resizeBackgroundImage();
        updateSaleLabel();
        updateClickMask(arg1);
        updateTimeEndString(arg1);
        updateStartTimeString(arg1);
        return;
    }

    internal var imageMask:io.decagames.rotmg.ui.sliceScaling.SliceScalingBitmap;
}
}
