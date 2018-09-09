package io.decagames.rotmg.shop.genericBox.data
{
import com.company.assembleegameclient.util.*;
import io.decagames.rotmg.utils.date.*;
import org.osflash.signals.*;

public class GenericBoxInfo extends Object
{
    public function GenericBoxInfo()
    {
        super();
        return;
    }

    public function get startTime():Date
    {
        return this._startTime;
    }

    public function set startTime(arg1:Date):void
    {
        this._startTime = arg1;
        return;
    }

    public function get endTime():Date
    {
        return this._endTime;
    }

    public function set endTime(arg1:Date):void
    {
        this._endTime = arg1;
        return;
    }

    public function get unitsLeft():int
    {
        return this._unitsLeft;
    }

    public function set unitsLeft(arg1:int):void
    {
        this._unitsLeft = arg1;
        this.updateSignal.dispatch();
        return;
    }

    public function get priceAmount():int
    {
        return this._priceAmount;
    }

    public function get totalUnits():int
    {
        return this._totalUnits;
    }

    public function set totalUnits(arg1:int):void
    {
        this._totalUnits = arg1;
        return;
    }

    public function get slot():int
    {
        return this._slot;
    }

    public function set slot(arg1:int):void
    {
        this._slot = arg1;
        return;
    }

    public function set tags(arg1:String):void
    {
        this._tags = arg1;
        return;
    }

    public function getSecondsToEnd():Number
    {
        if (!this._endTime)
        {
            return int.MAX_VALUE;
        }
        var loc1:*=new Date();
        return (this._endTime.time - loc1.time) / 1000;
    }

    public function getSecondsToStart():Number
    {
        var loc1:*=new Date();
        return (this._startTime.time - loc1.time) / 1000;
    }

    public function isOnSale():Boolean
    {
        var loc1:*=null;
        if (this._saleEnd)
        {
            loc1 = new Date();
            return loc1.time < this._saleEnd.time;
        }
        return false;
    }

    public function isNew():Boolean
    {
        var loc1:*=new Date();
        if (this._startTime.time > loc1.time)
        {
            return false;
        }
        return Math.ceil(com.company.assembleegameclient.util.TimeUtil.secondsToDays((loc1.time - this._startTime.time) / 1000)) <= 1;
    }

    public function getStartTimeString():String
    {
        var loc1:*="Available in: ";
        var loc2:*=this.getSecondsToStart();
        if (loc2 <= 0)
        {
            return "";
        }
        if (loc2 > com.company.assembleegameclient.util.TimeUtil.DAY_IN_S)
        {
            loc1 = loc1 + io.decagames.rotmg.utils.date.TimeLeft.parse(loc2, "%dd %hh");
        }
        else if (loc2 > com.company.assembleegameclient.util.TimeUtil.HOUR_IN_S)
        {
            loc1 = loc1 + io.decagames.rotmg.utils.date.TimeLeft.parse(loc2, "%hh %mm");
        }
        else
        {
            loc1 = loc1 + io.decagames.rotmg.utils.date.TimeLeft.parse(loc2, "%mm %ss");
        }
        return loc1;
    }

    public function getEndTimeString():String
    {
        if (!this._endTime)
        {
            return "";
        }
        var loc1:*="Ends in: ";
        var loc2:*=this.getSecondsToEnd();
        if (loc2 <= 0)
        {
            return "";
        }
        if (loc2 > com.company.assembleegameclient.util.TimeUtil.DAY_IN_S)
        {
            loc1 = loc1 + io.decagames.rotmg.utils.date.TimeLeft.parse(loc2, "%dd %hh");
        }
        else if (loc2 > com.company.assembleegameclient.util.TimeUtil.HOUR_IN_S)
        {
            loc1 = loc1 + io.decagames.rotmg.utils.date.TimeLeft.parse(loc2, "%hh %mm");
        }
        else
        {
            loc1 = loc1 + io.decagames.rotmg.utils.date.TimeLeft.parse(loc2, "%mm %ss");
        }
        return loc1;
    }

    public function get id():String
    {
        return this._id;
    }

    public function set id(arg1:String):void
    {
        this._id = arg1;
        return;
    }

    public function get title():String
    {
        return this._title;
    }

    public function set title(arg1:String):void
    {
        this._title = arg1;
        return;
    }

    public function get description():String
    {
        return this._description;
    }

    public function set description(arg1:String):void
    {
        this._description = arg1;
        return;
    }

    public function get weight():String
    {
        return this._weight;
    }

    public function set weight(arg1:String):void
    {
        this._weight = arg1;
        return;
    }

    public function get contents():String
    {
        return this._contents;
    }

    public function set contents(arg1:String):void
    {
        this._contents = arg1;
        return;
    }

    public function get tags():String
    {
        return this._tags;
    }

    public function set priceAmount(arg1:int):void
    {
        this._priceAmount = arg1;
        return;
    }

    public function get priceCurrency():int
    {
        return this._priceCurrency;
    }

    public function set priceCurrency(arg1:int):void
    {
        this._priceCurrency = arg1;
        return;
    }

    public function get saleAmount():int
    {
        return this._saleAmount;
    }

    public function set saleAmount(arg1:int):void
    {
        this._saleAmount = arg1;
        return;
    }

    public function get saleCurrency():int
    {
        return this._saleCurrency;
    }

    public function set saleCurrency(arg1:int):void
    {
        this._saleCurrency = arg1;
        return;
    }

    public function get quantity():int
    {
        return this._quantity;
    }

    public function set quantity(arg1:int):void
    {
        this._quantity = arg1;
        return;
    }

    public function get saleEnd():Date
    {
        return this._saleEnd;
    }

    public function set saleEnd(arg1:Date):void
    {
        this._saleEnd = arg1;
        return;
    }

    public const updateSignal:org.osflash.signals.Signal=new org.osflash.signals.Signal();

    protected var _id:String;

    protected var _title:String;

    protected var _description:String;

    protected var _weight:String;

    protected var _contents:String;

    protected var _priceAmount:int;

    protected var _saleAmount:int;

    protected var _saleCurrency:int;

    protected var _quantity:int;

    protected var _saleEnd:Date;

    protected var _startTime:Date;

    protected var _endTime:Date;

    protected var _unitsLeft:int=-1;

    protected var _totalUnits:int=-1;

    protected var _slot:int=0;

    protected var _tags:String="";

    protected var _priceCurrency:int;
}
}
