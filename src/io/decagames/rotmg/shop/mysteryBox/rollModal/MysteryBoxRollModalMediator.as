// Decompiled by AS3 Sorcerer 5.94
// www.as3sorcerer.com

//io.decagames.rotmg.shop.mysteryBox.rollModal.MysteryBoxRollModalMediator

package io.decagames.rotmg.shop.mysteryBox.rollModal
{
import robotlegs.bender.bundles.mvcs.Mediator;
import kabam.rotmg.appengine.api.AppEngineClient;
import kabam.rotmg.account.core.Account;
import io.decagames.rotmg.ui.popups.signals.ClosePopupSignal;
import kabam.rotmg.game.model.GameModel;
import kabam.rotmg.core.model.PlayerModel;
import io.decagames.rotmg.ui.popups.signals.ShowPopupSignal;
import kabam.rotmg.mysterybox.services.GetMysteryBoxesTask;
import flash.utils.Timer;
import io.decagames.rotmg.ui.buttons.SliceScalingButton;
import flash.events.TimerEvent;
import io.decagames.rotmg.ui.texture.TextureParser;
import io.decagames.rotmg.ui.popups.header.PopupHeader;
import flash.utils.clearTimeout;
import flash.utils.setTimeout;
import flash.utils.Dictionary;
import com.company.assembleegameclient.objects.Player;
import io.decagames.rotmg.utils.dictionary.DictionaryUtils;
import kabam.rotmg.text.view.stringBuilder.LineBuilder;
import io.decagames.rotmg.ui.popups.modal.error.ErrorModal;
import io.decagames.rotmg.shop.genericBox.BoxUtils;
import io.decagames.rotmg.ui.buttons.BaseButton;

public class MysteryBoxRollModalMediator extends Mediator
{

    [Inject]
    public var view:MysteryBoxRollModal;
    [Inject]
    public var client:AppEngineClient;
    [Inject]
    public var account:Account;
    [Inject]
    public var closePopupSignal:ClosePopupSignal;
    [Inject]
    public var gameModel:GameModel;
    [Inject]
    public var playerModel:PlayerModel;
    [Inject]
    public var showPopupSignal:ShowPopupSignal;
    [Inject]
    public var getMysteryBoxesTask:GetMysteryBoxesTask;
    private var boxConfig:Array;
    private var swapImageTimer:Timer = new Timer(80);
    private var totalRollDelay:int = 2000;
    private var nextRollDelay:int = 550;
    private var quantity:int = 1;
    private var requestComplete:Boolean;
    private var timerComplete:Boolean;
    private var rollNumber:int = 0;
    private var timeout:uint;
    private var rewardsList:Array = [];
    private var totalRewards:int = 0;
    private var closeButton:SliceScalingButton;
    private var totalRolls:int = 1;


    override public function initialize():void
    {
        this.configureRoll();
        this.swapImageTimer.addEventListener(TimerEvent.TIMER, this.swapItems);
        this.closeButton = new SliceScalingButton(TextureParser.instance.getSliceScalingBitmap("UI", "close_button"));
        this.closeButton.clickSignal.addOnce(this.onClose);
        this.view.header.addButton(this.closeButton, PopupHeader.RIGHT_BUTTON);
        this.boxConfig = this.parseBoxContents();
        this.quantity = this.view.quantity;
        this.playRollAnimation();
        this.sendRollRequest();
    }

    override public function destroy():void
    {
        this.closeButton.clickSignal.remove(this.onClose);
        this.closeButton.dispose();
        this.swapImageTimer.removeEventListener(TimerEvent.TIMER, this.swapItems);
        this.view.spinner.valueWasChanged.remove(this.changeAmountHandler);
        this.view.buyButton.clickSignal.remove(this.buyMore);
        this.view.finishedShowingResult.remove(this.onAnimationFinished);
        clearTimeout(this.timeout);
    }

    private function sendRollRequest():void
    {
        this.view.spinner.valueWasChanged.remove(this.changeAmountHandler);
        this.view.buyButton.clickSignal.remove(this.buyMore);
        this.closeButton.clickSignal.remove(this.onClose);
        this.requestComplete = false;
        this.timerComplete = false;
        var _local_1:Object = this.account.getCredentials();
        _local_1.boxId = this.view.info.id;
        if (this.view.info.isOnSale())
        {
            _local_1.quantity = this.quantity;
            _local_1.price = this.view.info.saleAmount;
            _local_1.currency = this.view.info.saleCurrency;
        }
        else
        {
            _local_1.quantity = this.quantity;
            _local_1.price = this.view.info.priceAmount;
            _local_1.currency = this.view.info.priceCurrency;
        };
        this.client.sendRequest("/account/purchaseMysteryBox", _local_1);
        this.client.complete.addOnce(this.onRollRequestComplete);
        this.timeout = setTimeout(this.showRewards, this.totalRollDelay);
    }

    private function showRewards():void
    {
        var _local_1:Dictionary;
        this.timerComplete = true;
        clearTimeout(this.timeout);
        if (this.requestComplete)
        {
            this.view.finishedShowingResult.add(this.onAnimationFinished);
            this.view.bigSpinner.pause();
            this.view.littleSpinner.pause();
            this.swapImageTimer.stop();
            _local_1 = this.rewardsList[this.rollNumber];
            if (this.rollNumber == 0)
            {
                this.view.prepareResultGrid(this.totalRewards);
            };
            this.view.displayResult([_local_1]);
        };
    }

    internal function onRollRequestComplete(arg1:Boolean, arg2:*):void
    {
        var loc1:*=null;
        var loc2:*=null;
        var loc3:*=null;
        var loc4:*=null;
        var loc5:*=null;
        var loc6:*=null;
        var loc7:*=null;
        var loc8:*=0;
        var loc9:*=null;
        var loc10:*=0;
        var loc11:*=null;
        this.requestComplete = true;
        if (arg1)
        {
            loc1 = new XML(arg2);
            this.rewardsList = [];
            var loc12:*=0;
            var loc13:*=loc1.elements("Awards");
            for each (loc2 in loc13)
            {
                loc4 = loc2.toString().split(",");
                loc5 = this.convertItemsToAmountDictionary(loc4);
                this.totalRewards = this.totalRewards + io.decagames.rotmg.utils.dictionary.DictionaryUtils.countKeys(loc5);
                this.rewardsList.push(loc5);
            }
            if (loc1.hasOwnProperty("Left") && !(this.view.info.unitsLeft == -1))
            {
                this.view.info.unitsLeft = int(loc1.Left);
                if (this.view.info.unitsLeft == 0)
                {
                    this.view.buyButton.soldOut = true;
                }
            }
            if ((loc3 = this.gameModel.player) == null)
            {
                if (this.playerModel != null)
                {
                    if (loc1.hasOwnProperty("Gold"))
                    {
                        this.playerModel.setCredits(int(loc1.Gold));
                    }
                    else if (loc1.hasOwnProperty("Fame"))
                    {
                        this.playerModel.setFame(int(loc1.Fame));
                    }
                }
            }
            else if (loc1.hasOwnProperty("Gold"))
            {
                loc3.setCredits(int(loc1.Gold));
            }
            else if (loc1.hasOwnProperty("Fame"))
            {
                loc3.setFame(int(loc1.Fame));
            }
            if (this.timerComplete)
            {
                this.showRewards();
            }
        }
        else
        {
            flash.utils.clearTimeout(this.timeout);
            loc6 = "MysteryBoxRollModal.pleaseTryAgainString";
            if (kabam.rotmg.text.view.stringBuilder.LineBuilder.getLocalizedStringFromKey(arg2) != "")
            {
                loc6 = arg2;
            }
            if (arg2.indexOf("MysteryBoxError.soldOut") >= 0)
            {
                if ((loc7 = arg2.split("|")).length == 2)
                {
                    loc8 = loc7[1];
                    this.view.info.unitsLeft = loc8;
                    if (loc8 != 0)
                    {
                        loc6 = kabam.rotmg.text.view.stringBuilder.LineBuilder.getLocalizedStringFromKey("MysteryBoxError.soldOutLeft", {"left":this.view.info.unitsLeft, "box":this.view.info.unitsLeft != 1 ? kabam.rotmg.text.view.stringBuilder.LineBuilder.getLocalizedStringFromKey("MysteryBoxError.boxes") : kabam.rotmg.text.view.stringBuilder.LineBuilder.getLocalizedStringFromKey("MysteryBoxError.box")});
                    }
                    else
                    {
                        loc6 = "MysteryBoxError.soldOutAll";
                    }
                }
            }
            if (arg2.indexOf("MysteryBoxError.maxPurchase") >= 0)
            {
                if ((loc9 = arg2.split("|")).length == 2)
                {
                    if ((loc10 = loc9[1]) != 0)
                    {
                        loc6 = kabam.rotmg.text.view.stringBuilder.LineBuilder.getLocalizedStringFromKey("MysteryBoxError.maxPurchaseLeft", {"left":loc10});
                    }
                    else
                    {
                        loc6 = "MysteryBoxError.maxPurchase";
                    }
                }
            }
            if (arg2.indexOf("blockedForUser") >= 0)
            {
                if ((loc11 = arg2.split("|")).length == 2)
                {
                    loc6 = kabam.rotmg.text.view.stringBuilder.LineBuilder.getLocalizedStringFromKey("MysteryBoxError.blockedForUser", {"date":loc11[1]});
                }
            }
            this.showErrorMessage(loc6);
        }
        return;
    }

    private function showErrorMessage(_arg_1:String):void
    {
        this.closePopupSignal.dispatch(this.view);
        this.showPopupSignal.dispatch(new ErrorModal(300, LineBuilder.getLocalizedStringFromKey("MysteryBoxRollModal.purchaseFailedString", {}), LineBuilder.getLocalizedStringFromKey(_arg_1, {})));
        this.getMysteryBoxesTask.start();
    }

    private function configureRoll():void
    {
        if (this.view.info.quantity > 1)
        {
            this.totalRollDelay = 1000;
        };
    }

    private function convertItemsToAmountDictionary(_arg_1:Array):Dictionary
    {
        var _local_2:String;
        var _local_3:Dictionary = new Dictionary();
        for each (_local_2 in _arg_1)
        {
            if (_local_3[_local_2])
            {
                _local_3[_local_2]++;
            }
            else
            {
                _local_3[_local_2] = 1;
            };
        };
        return (_local_3);
    }

    private function parseBoxContents():Array
    {
        var _local_1:String;
        var _local_2:Array;
        var _local_3:Array;
        var _local_4:String;
        var _local_7:int;
        var _local_5:Array = this.view.info.contents.split("|");
        var _local_6:Array = [];
        for each (_local_1 in _local_5)
        {
            _local_2 = [];
            _local_3 = _local_1.split(";");
            for each (_local_4 in _local_3)
            {
                _local_2.push(this.convertItemsToAmountDictionary(_local_4.split(",")));
            };
            _local_6[_local_7] = _local_2;
            _local_7++;
        };
        this.totalRolls = _local_7;
        return (_local_6);
    }

    private function onAnimationFinished():void
    {
        this.rollNumber++;
        if (this.rollNumber < this.view.quantity)
        {
            this.playRollAnimation();
            this.timeout = setTimeout(this.showRewards, (this.view.totalAnimationTime(this.totalRolls) + this.nextRollDelay));
        }
        else
        {
            this.closeButton.clickSignal.addOnce(this.onClose);
            this.view.spinner.valueWasChanged.add(this.changeAmountHandler);
            this.view.spinner.value = this.view.quantity;
            this.view.showBuyButton();
            this.view.buyButton.clickSignal.add(this.buyMore);
        };
    }

    private function changeAmountHandler(_arg_1:int):void
    {
        if (this.view.info.isOnSale())
        {
            this.view.buyButton.price = (_arg_1 * int(this.view.info.saleAmount));
        }
        else
        {
            this.view.buyButton.price = (_arg_1 * int(this.view.info.priceAmount));
        };
    }

    private function buyMore(_arg_1:BaseButton):void
    {
        var _local_2:Boolean = BoxUtils.moneyCheckPass(this.view.info, this.view.spinner.value, this.gameModel, this.playerModel, this.showPopupSignal);
        if (_local_2)
        {
            this.rollNumber = 0;
            this.totalRewards = 0;
            this.view.buyMore(this.view.spinner.value);
            this.configureRoll();
            this.quantity = this.view.quantity;
            this.playRollAnimation();
            this.sendRollRequest();
        };
    }

    private function playRollAnimation():void
    {
        this.view.bigSpinner.resume();
        this.view.littleSpinner.resume();
        this.swapImageTimer.start();
        this.swapItems(null);
    }

    private function swapItems(_arg_1:TimerEvent):void
    {
        var _local_2:Array;
        var _local_3:int;
        var _local_4:Array = [];
        for each (_local_2 in this.boxConfig)
        {
            _local_3 = int(Math.floor((Math.random() * _local_2.length)));
            _local_4.push(_local_2[_local_3]);
        };
        this.view.displayItems(_local_4);
    }

    private function onClose(_arg_1:BaseButton):void
    {
        this.closePopupSignal.dispatch(this.view);
    }


}
}//package io.decagames.rotmg.shop.mysteryBox.rollModal

