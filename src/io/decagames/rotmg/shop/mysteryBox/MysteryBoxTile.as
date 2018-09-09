package io.decagames.rotmg.shop.mysteryBox
{
import flash.geom.*;
import io.decagames.rotmg.shop.genericBox.*;
import io.decagames.rotmg.shop.mysteryBox.contentPopup.*;
import io.decagames.rotmg.ui.gird.*;
import kabam.rotmg.mysterybox.model.*;

public class MysteryBoxTile extends io.decagames.rotmg.shop.genericBox.GenericBoxTile
{
    public function MysteryBoxTile(arg1:kabam.rotmg.mysterybox.model.MysteryBoxInfo)
    {
        buyButtonBitmapBackground = "shop_box_button_background";
        super(arg1);
        return;
    }

    internal function prepareResultGrid(arg1:int):void
    {
        this.maxResultWidth = 160;
        this.gridConfig = this.calculateGrid(arg1);
        this.resultElementWidth = this.calculateElementSize(this.gridConfig);
        this.displayedItemsGrid = new io.decagames.rotmg.ui.gird.UIGrid(this.resultElementWidth * this.gridConfig.x, this.gridConfig.x, 0);
        this.displayedItemsGrid.x = 20 + Math.round((this.maxResultWidth - this.resultElementWidth * this.gridConfig.x) / 2);
        this.displayedItemsGrid.y = Math.round(42 + (this.maxResultHeight - this.resultElementWidth * this.gridConfig.y) / 2);
        this.displayedItemsGrid.centerLastRow = true;
        addChild(this.displayedItemsGrid);
        return;
    }

    internal function calculateGrid(arg1:int):flash.geom.Point
    {
        var loc4:*=0;
        var loc5:*=0;
        var loc1:*=new flash.geom.Point(11, 4);
        var loc2:*=int.MIN_VALUE;
        if (arg1 >= loc1.x * loc1.y)
        {
            return loc1;
        }
        var loc3:*=11;
        while (loc3 >= 1)
        {
            loc4 = 4;
            while (loc4 >= 1)
            {
                if (loc3 * loc4 >= arg1 && (loc3 - 1) * (loc4 - 1) < arg1)
                {
                    if ((loc5 = this.calculateElementSize(new flash.geom.Point(loc3, loc4))) != -1)
                    {
                        if (loc5 > loc2)
                        {
                            loc2 = loc5;
                            loc1 = new flash.geom.Point(loc3, loc4);
                        }
                        else if (loc5 == loc2)
                        {
                            if (loc1.x * loc1.y - arg1 > loc3 * loc4 - arg1)
                            {
                                loc2 = loc5;
                                loc1 = new flash.geom.Point(loc3, loc4);
                            }
                        }
                    }
                }
                --loc4;
            }
            --loc3;
        }
        return loc1;
    }

    internal function calculateElementSize(arg1:flash.geom.Point):int
    {
        var loc1:*=Math.floor(this.maxResultHeight / arg1.y);
        if (loc1 * arg1.x > this.maxResultWidth)
        {
            loc1 = Math.floor(this.maxResultWidth / arg1.x);
        }
        if (loc1 * arg1.y > this.maxResultHeight)
        {
            return -1;
        }
        return loc1;
    }

    protected override function createBoxBackground():void
    {
        var loc2:*=0;
        var loc4:*=null;
        var loc1:*=kabam.rotmg.mysterybox.model.MysteryBoxInfo(_boxInfo).displayedItems.split(",");
        if (loc1.length == 0 || kabam.rotmg.mysterybox.model.MysteryBoxInfo(_boxInfo).displayedItems == "")
        {
            return;
        }
        if (_infoButton)
        {
            _infoButton.alpha = 0;
        }
        var loc5:*=loc1.length;
        switch (loc5)
        {
            case 1:
            {
                break;
            }
            case 2:
            {
                loc2 = 50;
                break;
            }
            case 3:
            {
                break;
            }
        }
        this.prepareResultGrid(loc1.length);
        var loc3:*=0;
        while (loc3 < loc1.length)
        {
            loc4 = new io.decagames.rotmg.shop.mysteryBox.contentPopup.UIItemContainer(loc1[loc3], 0, 0, this.resultElementWidth);
            this.displayedItemsGrid.addGridElement(loc4);
            ++loc3;
        }
        return;
    }

    public override function resize(arg1:int, arg2:int=-1):void
    {
        background.width = arg1;
        backgroundTitle.width = arg1;
        backgroundButton.width = arg1;
        background.height = 184;
        backgroundTitle.y = 2;
        titleLabel.x = Math.round((arg1 - titleLabel.textWidth) / 2);
        titleLabel.y = 6;
        backgroundButton.y = 133;
        _buyButton.y = backgroundButton.y + 4;
        _buyButton.x = arg1 - 110;
        _infoButton.x = 130;
        _infoButton.y = 45;
        if (this.displayedItemsGrid)
        {
            this.displayedItemsGrid.x = 10 + Math.round((this.maxResultWidth - this.resultElementWidth * this.gridConfig.x) / 2);
        }
        updateSaleLabel();
        updateClickMask(arg1);
        updateTimeEndString(arg1);
        updateStartTimeString(arg1);
        return;
    }

    public override function dispose():void
    {
        if (this.displayedItemsGrid)
        {
            this.displayedItemsGrid.dispose();
        }
        super.dispose();
        return;
    }

    internal var displayedItemsGrid:io.decagames.rotmg.ui.gird.UIGrid;

    internal var maxResultHeight:int=75;

    internal var maxResultWidth:int;

    internal var resultElementWidth:int;

    internal var gridConfig:flash.geom.Point;
}
}
