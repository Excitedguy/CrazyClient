// Decompiled by AS3 Sorcerer 5.48
// www.as3sorcerer.com

//kabam.rotmg.mysterybox.services.GetMysteryBoxesTask

package kabam.rotmg.mysterybox.services
{
import com.company.assembleegameclient.util.TimeUtil;


import kabam.lib.tasks.BaseTask;
import kabam.rotmg.account.core.Account;
import kabam.rotmg.appengine.api.AppEngineClient;
import kabam.rotmg.dialogs.control.OpenDialogSignal;
import kabam.rotmg.fortune.model.FortuneInfo;
import kabam.rotmg.fortune.services.FortuneModel;
import kabam.rotmg.language.model.LanguageModel;
import kabam.rotmg.mysterybox.model.MysteryBoxInfo;

import robotlegs.bender.framework.api.ILogger;

public class GetMysteryBoxesTask extends BaseTask
{

    private static var version:String = "0";

    [Inject]
    public var client:AppEngineClient;
    [Inject]
    public var mysteryBoxModel:MysteryBoxModel;
    [Inject]
    public var fortuneModel:FortuneModel;
    [Inject]
    public var account:Account;
    [Inject]
    public var logger:ILogger;
    [Inject]
    public var languageModel:LanguageModel;
    [Inject]
    public var openDialogSignal:OpenDialogSignal;


    override protected function startTask():void
    {
        var _local_2:*=this.account.getCredentials();
            _local_2.language = this.languageModel.getLanguage();
            _local_2.version = version;
            this.client.sendRequest("/mysterybox/getBoxes", _local_2);
            this.client.complete.addOnce(this.onComplete);
    }

    private function onComplete(_arg_1:Boolean, _arg_2:*):void
    {
        if (_arg_1)
        {
            this.handleOkay(_arg_2);
        }
        else
        {
            this.logger.warn("GetMysteryBox.onComplete: Request failed.");
            completeTask(true);
        }
    }

    internal function handleOkay(arg1:*):void
    {
        version = XML(arg1).attribute("version").toString();
        var loc1:*=XML(arg1).child("MysteryBox");
        var loc2:*=XML(arg1).child("SoldCounter");
        if (loc2.length() > 0)
        {
            this.updateSoldCounters(loc2);
        }
        if (loc1.length() > 0)
        {
            this.parse(loc1);
        }
        else if (this.mysteryBoxModel.isInitialized())
        {
            this.mysteryBoxModel.updateSignal.dispatch();
        }
        var loc3:*;
        if ((loc3 = XML(arg1).child("FortuneGame")).length() > 0)
        {
            this.parseFortune(loc3);
        }
        completeTask(true);
        return;
    }

    private function hasNoBoxes(_arg_1:*):Boolean
    {
        var _local_2:XMLList = XML(_arg_1).children();
        return (_local_2.length() == 0);
    }

    private function parseFortune(_arg_1:XMLList):void
    {
        var _local_2:FortuneInfo = new FortuneInfo();
        _local_2.id = _arg_1.attribute("id").toString();
        _local_2.title = _arg_1.attribute("title").toString();
        _local_2.weight = _arg_1.attribute("weight").toString();
        _local_2.description = _arg_1.Description.toString();
        _local_2.contents = _arg_1.Contents.toString();
        _local_2.priceFirstInGold = _arg_1.Price.attribute("firstInGold").toString();
        _local_2.priceFirstInToken = _arg_1.Price.attribute("firstInToken").toString();
        _local_2.priceSecondInGold = _arg_1.Price.attribute("secondInGold").toString();
        _local_2.iconImageUrl = _arg_1.Icon.toString();
        _local_2.infoImageUrl = _arg_1.Image.toString();
        _local_2.startTime = TimeUtil.parseUTCDate(_arg_1.StartTime.toString());
        _local_2.endTime = TimeUtil.parseUTCDate(_arg_1.EndTime.toString());
        _local_2.parseContents();
        this.fortuneModel.setFortune(_local_2);
    }

    internal function updateSoldCounters(arg1:XMLList):void
    {
        var loc1:*=null;
        var loc2:*=null;
        var loc3:*=0;
        var loc4:*=arg1;
        for each (loc1 in loc4)
        {
            loc2 = this.mysteryBoxModel.getBoxById(loc1.attribute("id").toString());
            loc2.unitsLeft = loc1.attribute("left");
        }
        return;
    }

    private function parse(_arg_1:XMLList):void
    {
        var _local_4:XML;
        var _local_5:MysteryBoxInfo;
        var _local_2:Array = [];
        var _local_3:Boolean;
        for each (_local_4 in _arg_1)
        {
            _local_5 = new MysteryBoxInfo();
            _local_5.id = _local_4.attribute("id").toString();
            _local_5.title = _local_4.attribute("title").toString();
            _local_5.weight = _local_4.attribute("weight").toString();
            _local_5.description = _local_4.Description.toString();
            _local_5.contents = _local_4.Contents.toString();
            _local_5.priceAmount = int(_local_4.Price.attribute("amount").toString());
            _local_5.priceCurrency = _local_4.Price.attribute("currency").toString();
            if (_local_4.hasOwnProperty("Sale"))
            {
                _local_5.saleAmount = _local_4.Sale.attribute("price").toString();
                _local_5.saleCurrency = _local_4.Sale.attribute("currency").toString();
                _local_5.saleEnd = TimeUtil.parseUTCDate(_local_4.Sale.End.toString());
            }
            if (_local_4.hasOwnProperty("Left"))
            {
                _local_5.unitsLeft = _local_4.Left;
            }
            if (_local_4.hasOwnProperty("Total"))
            {
                _local_5.totalUnits = _local_4.Total;
            }
            if (_local_4.hasOwnProperty("Slot"))
            {
                _local_5.slot = _local_4.Slot;
            }
            if (_local_4.hasOwnProperty("Jackpots"))
            {
                _local_5.jackpots = _local_4.Jackpots;
            }
            if (_local_4.hasOwnProperty("DisplayedItems"))
            {
                _local_5.displayedItems = _local_4.DisplayedItems;
            }
            if (_local_4.hasOwnProperty("Rolls"))
            {
                _local_5.rolls = int(_local_4.Rolls);
            }
            if (_local_4.hasOwnProperty("Tags"))
            {
                _local_5.tags = _local_4.Tags;
            }
            _local_5.iconImageUrl = _local_4.Icon.toString();
            _local_5.infoImageUrl = _local_4.Image.toString();
            _local_5.startTime = TimeUtil.parseUTCDate(_local_4.StartTime.toString());
            if (_local_4.EndTime.toString())
            {
                _local_5.endTime = TimeUtil.parseUTCDate(_local_4.EndTime.toString());
            }
            _local_5.parseContents();
            if (((!(_local_3)) && ((_local_5.isNew()) || (_local_5.isOnSale()))))
            {
                _local_3 = true;
            }
            _local_2.push(_local_5);
        }
        this.mysteryBoxModel.setMysetryBoxes(_local_2);
        this.mysteryBoxModel.isNew = _local_3;
    }


}
}//package kabam.rotmg.mysterybox.services

