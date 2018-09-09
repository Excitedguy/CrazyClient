// Decompiled by AS3 Sorcerer 5.48
// www.as3sorcerer.com

//io.decagames.rotmg.shop.ShopPopupMediator

package io.decagames.rotmg.shop
{
import com.company.assembleegameclient.parameters.Parameters;
import com.company.assembleegameclient.ui.tooltip.TextToolTip;

import io.decagames.rotmg.shop.genericBox.GenericBoxTile;
import io.decagames.rotmg.shop.genericBox.data.GenericBoxInfo;
import io.decagames.rotmg.shop.mysteryBox.MysteryBoxTile;
import io.decagames.rotmg.shop.packages.PackageBoxTile;
import io.decagames.rotmg.ui.buttons.BaseButton;
import io.decagames.rotmg.ui.buttons.SliceScalingButton;
import io.decagames.rotmg.ui.defaults.DefaultLabelFormat;
import io.decagames.rotmg.ui.gird.UIGrid;
import io.decagames.rotmg.ui.popups.header.PopupHeader;
import io.decagames.rotmg.ui.popups.signals.ClosePopupSignal;
import io.decagames.rotmg.ui.tabs.TabButton;
import io.decagames.rotmg.ui.tabs.UITab;
import io.decagames.rotmg.ui.tabs.UITabs;
import io.decagames.rotmg.ui.texture.TextureParser;

import kabam.rotmg.account.core.signals.OpenMoneyWindowSignal;
import kabam.rotmg.core.signals.HideTooltipsSignal;
import kabam.rotmg.core.signals.ShowTooltipSignal;
import kabam.rotmg.game.model.GameModel;
import kabam.rotmg.mysterybox.model.MysteryBoxInfo;
import kabam.rotmg.mysterybox.services.MysteryBoxModel;
import kabam.rotmg.packages.model.PackageInfo;
import kabam.rotmg.packages.services.PackageModel;
import kabam.rotmg.tooltips.HoverTooltipDelegate;

import robotlegs.bender.bundles.mvcs.Mediator;

public class ShopPopupMediator extends Mediator
{

    [Inject]
    public var view:ShopPopupView;
    [Inject]
    public var mysteryBoxModel:MysteryBoxModel;
    [Inject]
    public var packageBoxModel:PackageModel;
    [Inject]
    public var gameModel:GameModel;
    [Inject]
    public var openMoneyWindow:OpenMoneyWindowSignal;
    [Inject]
    public var closePopupSignal:ClosePopupSignal;
    [Inject]
    public var showTooltipSignal:ShowTooltipSignal;
    [Inject]
    public var hideTooltipSignal:HideTooltipsSignal;
    private var closeButton:SliceScalingButton;
    private var addButton:SliceScalingButton;
    private var mysteryBoxesGrid:UIGrid;
    private var packageBoxesGrid:UIGrid;
    private var toolTip:TextToolTip = null;
    private var hoverTooltipDelegate:HoverTooltipDelegate;
    private var tabs:UITabs;
    private var packageTab:TabButton;


    internal function createPackageBoxTab():io.decagames.rotmg.ui.tabs.UITab
    {
        var loc1:*=null;
        loc1 = new io.decagames.rotmg.ui.tabs.UITab("Packages");
        this.packageBoxesGrid = new io.decagames.rotmg.ui.gird.UIGrid(550, 2, 6, 384, 3, loc1);
        this.packageBoxesGrid.x = 10;
        this.packageBoxesGrid.decorBitmap = "tabs_tile_decor";
        this.updatePackages();
        loc1.addContent(this.packageBoxesGrid);
        return loc1;
    }

    internal function createMysteryBoxTab():io.decagames.rotmg.ui.tabs.UITab
    {
        var loc1:*=new io.decagames.rotmg.ui.tabs.UITab("Mystery Boxes", true);
        this.mysteryBoxesGrid = new io.decagames.rotmg.ui.gird.UIGrid(550, 3, 6, 384, 3, loc1);
        this.mysteryBoxesGrid.decorBitmap = "tabs_tile_decor";
        this.mysteryBoxesGrid.x = 10;
        this.updateMysteryBoxes();
        loc1.addContent(this.mysteryBoxesGrid);
        return loc1;
    }

    internal function updateMysteryBoxes():void
    {
        var loc2:*=null;
        this.mysteryBoxesGrid.clearGrid();
        var loc1:*=this.mysteryBoxModel.getBoxesForGrid();
        var loc3:*=0;
        var loc4:*=loc1;
        for each (loc2 in loc4)
        {
            if (!(!(loc2 == null) && (!loc2.endTime || loc2.getSecondsToEnd() > 0)))
            {
                continue;
            }
            this.mysteryBoxesGrid.addGridElement(this.createBoxTile(loc2, io.decagames.rotmg.shop.mysteryBox.MysteryBoxTile));
        }
        return;
    }

    internal function updatePackages():void
    {
        var loc2:*=null;
        this.packageBoxesGrid.clearGrid();
        var loc1:*=this.packageBoxModel.getBoxesForGrid();
        var loc3:*=0;
        var loc4:*=loc1;
        for each (loc2 in loc4)
        {
            if (!(!(loc2 == null) && (!loc2.endTime || loc2.getSecondsToEnd() > 0)))
            {
                continue;
            }
            this.packageBoxesGrid.addGridElement(this.createBoxTile(loc2, io.decagames.rotmg.shop.packages.PackageBoxTile));
        }
        return;
    }


    private function createBoxTile(_arg_1:GenericBoxInfo, _arg_2:Class):GenericBoxTile
    {
        return (new _arg_2(_arg_1));
    }

    override public function initialize():void
    {
        var _local_4:PackageInfo;
        this.closeButton = new SliceScalingButton(TextureParser.instance.getSliceScalingBitmap("UI", "close_button"));
        this.addButton = new SliceScalingButton(TextureParser.instance.getSliceScalingBitmap("UI", "add_button"));
        this.tabs = new UITabs(590);
        this.tabs.addTab(this.createMysteryBoxTab(), true);
        this.tabs.addTab(this.createPackageBoxTab());
        this.tabs.y = 115;
        this.tabs.x = 3;
        this.view.header.setTitle("Shop", 319, DefaultLabelFormat.defaultPopupTitle);
        this.view.header.showCoins(132).coinsAmount = this.gameModel.player.credits_;
        this.view.header.showFame(132).fameAmount = this.gameModel.player.fame_;
        this.closeButton.clickSignal.addOnce(this.onClose);
        this.view.header.addButton(this.closeButton, PopupHeader.RIGHT_BUTTON);
        this.addButton.clickSignal.add(this.onAdd);
        this.view.header.addButton(this.addButton, PopupHeader.LEFT_BUTTON);
        this.view.addChild(this.tabs);
        var _local_1:Vector.<PackageInfo> = this.packageBoxModel.getBoxesForGrid();
        var _local_2:Date = new Date();
        _local_2.setTime(Parameters.data_["packages_indicator"]);
        var _local_3:Boolean;
        for each (_local_4 in _local_1)
        {
            if (((!(_local_4 == null)) && ((!(_local_4.endTime)) || (_local_4.getSecondsToEnd() > 0))))
            {
                if (((_local_4.isNew()) && ((_local_4.startTime.getTime() > _local_2.getTime()) || (!(Parameters.data_["packages_indicator"])))))
                {
                    _local_3 = true;
                }
            }
        }
        this.packageTab = this.tabs.getTabButtonByLabel("Packages");
        if (this.packageTab)
        {
            this.packageTab.showIndicator = _local_3;
            this.packageTab.clickSignal.add(this.onPackageClick);
        }
        this.gameModel.player.creditsWereChanged.add(this.refreshCoins);
        this.gameModel.player.fameWasChanged.add(this.refreshFame);
        this.toolTip = new TextToolTip(0x363636, 0x9B9B9B, "Buy Gold", "Click to buy more Realm Gold!", 200);
        this.hoverTooltipDelegate = new HoverTooltipDelegate();
        this.hoverTooltipDelegate.setShowToolTipSignal(this.showTooltipSignal);
        this.hoverTooltipDelegate.setHideToolTipsSignal(this.hideTooltipSignal);
        this.hoverTooltipDelegate.setDisplayObject(this.addButton);
        this.hoverTooltipDelegate.tooltip = this.toolTip;
    }

    private function onPackageClick(_arg_1:BaseButton):void
    {
        if (TabButton(_arg_1).hasIndicator)
        {
            Parameters.data_["packages_indicator"] = new Date().getTime();
            TabButton(_arg_1).showIndicator = false;
        }
    }

    override public function destroy():void
    {
        this.view.dispose();
        this.closeButton.dispose();
        this.addButton.dispose();
        this.gameModel.player.creditsWereChanged.remove(this.refreshCoins);
        this.gameModel.player.fameWasChanged.remove(this.refreshFame);
        this.tabs.dispose();
        this.mysteryBoxesGrid.dispose();
        this.packageBoxesGrid.dispose();
        this.toolTip = null;
        this.hoverTooltipDelegate.removeDisplayObject();
        this.hoverTooltipDelegate = null;
        if (this.packageTab)
        {
            this.packageTab.clickSignal.remove(this.onPackageClick);
        }
    }

    private function refreshCoins():void
    {
        this.view.header.showCoins(132).coinsAmount = this.gameModel.player.credits_;
    }

    private function refreshFame():void
    {
        this.view.header.showFame(132).fameAmount = this.gameModel.player.fame_;
    }

    private function onAdd(_arg_1:BaseButton):void
    {
        this.openMoneyWindow.dispatch();
    }

    private function onClose(_arg_1:BaseButton):void
    {
        this.closePopupSignal.dispatch(this.view);
    }


}
}//package io.decagames.rotmg.shop

