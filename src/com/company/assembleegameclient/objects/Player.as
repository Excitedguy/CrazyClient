﻿//com.company.assembleegameclient.objects.Player

package com.company.assembleegameclient.objects
{
import com.company.assembleegameclient.game.events.ReconnectEvent;
import com.company.assembleegameclient.map.Camera;
import com.company.assembleegameclient.map.Square;
import com.company.assembleegameclient.map.mapoverlay.CharacterStatusText;
import com.company.assembleegameclient.objects.particles.HealingEffect;
import com.company.assembleegameclient.objects.particles.LevelUpEffect;
import com.company.assembleegameclient.parameters.Parameters;
import com.company.assembleegameclient.sound.SoundEffectLibrary;
import com.company.assembleegameclient.ui.TradeSlot;
import com.company.assembleegameclient.ui.options.Options;
import com.company.assembleegameclient.util.AnimatedChar;
import com.company.assembleegameclient.util.ConditionEffect;
import com.company.assembleegameclient.util.FameUtil;
import com.company.assembleegameclient.util.FreeList;
import com.company.assembleegameclient.util.MaskedImage;
import com.company.assembleegameclient.util.TextureRedrawer;
import com.company.assembleegameclient.util.redrawers.GlowRedrawer;
import com.company.util.CachingColorTransformer;
import com.company.util.ConversionUtil;
import com.company.util.GraphicsUtil;
import com.company.util.IntPoint;
import com.company.util.MoreColorUtil;
import com.company.util.PointUtil;
import com.company.util.Trig;

import flash.display.BitmapData;
import flash.display.GraphicsPath;
import flash.display.GraphicsSolidFill;
import flash.display.IGraphicsData;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Vector3D;
import flash.utils.Dictionary;
import flash.utils.getTimer;

import kabam.rotmg.assets.services.CharacterFactory;
import kabam.rotmg.chat.control.ParseChatMessageCommand;
import kabam.rotmg.chat.model.ChatMessage;
import kabam.rotmg.constants.ActivationType;
import kabam.rotmg.constants.GeneralConstants;
import kabam.rotmg.constants.UseType;
import kabam.rotmg.core.StaticInjectorContext;
import kabam.rotmg.game.model.PotionInventoryModel;
import kabam.rotmg.game.model.UseBuyPotionVO;
import kabam.rotmg.game.signals.AddTextLineSignal;
import kabam.rotmg.game.signals.UseBuyPotionSignal;
import kabam.rotmg.messaging.impl.GameServerConnection;
import kabam.rotmg.messaging.impl.GameServerConnectionConcrete;
import kabam.rotmg.servers.api.Server;
import kabam.rotmg.stage3D.GraphicsFillExtra;
import kabam.rotmg.text.model.TextKey;
import kabam.rotmg.text.view.BitmapTextFactory;
import kabam.rotmg.text.view.stringBuilder.LineBuilder;
import kabam.rotmg.text.view.stringBuilder.StaticStringBuilder;
import kabam.rotmg.text.view.stringBuilder.StringBuilder;
import kabam.rotmg.ui.model.HUDModel;

import org.osflash.signals.Signal;
import org.swiftsuspenders.Injector;

public class Player extends Character
{

    public static const MS_BETWEEN_TELEPORT:int = 10000;
    public static const MS_REALM_TELEPORT:int = 120000;
    private static const MOVE_THRESHOLD:Number = 0.4;
    public static var isAdmin:Boolean = false;
    public static var isMod:Boolean = false;
    private static const NEARBY:Vector.<Point> = new <Point>[new Point(0, 0), new Point(1, 0), new Point(0, 1), new Point(1, 1)];
    private static var newP:Point = new Point();
    private static const RANK_OFFSET_MATRIX:Matrix = new Matrix(1, 0, 0, 1, 2, 2);
    private static const NAME_OFFSET_MATRIX:Matrix = new Matrix(1, 0, 0, 1, 20, 0);
    private static const MIN_MOVE_SPEED:Number = 0.004;
    private static const MAX_MOVE_SPEED:Number = 0.0096;
    private static const MIN_ATTACK_FREQ:Number = 0.0015;
    private static const MAX_ATTACK_FREQ:Number = 0.008;
    private static const MIN_ATTACK_MULT:Number = 0.5;
    private static const MAX_ATTACK_MULT:Number = 2;
    public static const SEARCH_LOOT_FREQ:int = 20;
    public static const MAX_LOOT_DIST:Number = 1;
    public static const VAULT_CHEST:int = 1284;
    public static const HEALTH_POT:int = 2594;
    public static const MAGIC_POT:int = 2595;
    public static const MAX_STACK_POTS:int = 6;
    public static const LOOT_EVERY_MS:int = 550;
    public static const WEAP_ARMOR_MIN_TIER:int = 10;
    public static const HEALTH_SLOT:int = 254;
    public static const MAGIC_SLOT:int = 0xFF;
    public static var wantedList:Vector.<int> = null;
    public static var lastSearchTime:int = 0;
    public static var lastLootTime:int = 0;
    public static var nextLootSlot:int = -1;
    public static var pItems:eItems = new eItems();
    public static var reconRealm:ReconnectEvent;

    private var lastreconnect:int = 0;
    private var nextSwap:int = 0;
    public var followTarget:GameObject;
    public var questMob:GameObject;
    public var questMob1:GameObject;
    public var questMob2:GameObject;
    public var questMob3:GameObject;
    public var mapLightSpeed:Boolean = false;
    public var afkMsg:String = "";
    public var sendStr:int = 2147483647;
    private var timerStep:int = 500;
    private var timerCount:int = 1;
    private var startTime:int = 0;
    private var endCount:int = 0;
    public var select_:int = -1;
    private var nextSelect:int = 0;
    private var loopStart:int = 4;
    private var nextAutoAbil:int = 0;
    public var mapAutoAbil:Boolean = true;
    private var opFailed:Boolean = false;
    private var potionInventoryModel:PotionInventoryModel;
    private var useBuyPotionSignal:UseBuyPotionSignal;
    private var lastPotionUse:int = 0;
    private var lastManaUse:int = 0;
    private var lastteleport:int = 0;
    public var chp:Number = -1;
    public var cmaxhp:int = -1;
    public var cmaxhpboost:int = -1;
    private var vitTime:int = -1;
    public var xpTimer:int;
    public var skinId:int;
    public var skin:AnimatedChar;
    public var isShooting:Boolean;
    public var fameWasChanged:Signal = new Signal();
    private var famePortrait_:BitmapData = null;
    public var accountId_:String = "";
    public var credits_:int = 0;
    public var tokens_:int = 0;
    public var numStars_:int = 0;
    public var fame_:int = 0;
    public var nameChosen_:Boolean = false;
    public var currFame_:int = 0;
    public var nextClassQuestFame_:int = -1;
    public var legendaryRank_:int = -1;
    public var guildName_:String = null;
    public var guildRank_:int = -1;
    public var isFellowGuild_:Boolean = false;
    public var breath_:int = -1;
    public var nextLevelExp_:int = 1000;
    public var exp_:int = 0;
    public var attack_:int = 0;
    public var speed_:int = 0;
    public var dexterity_:int = 0;
    public var vitality_:int = 0;
    public var wisdom_:int = 0;
    public var maxHPBoost_:int = 0;
    public var maxMPBoost_:int = 0;
    public var attackBoost_:int = 0;
    public var defenseBoost_:int = 0;
    public var speedBoost_:int = 0;
    public var vitalityBoost_:int = 0;
    public var wisdomBoost_:int = 0;
    public var dexterityBoost_:int = 0;
    public var xpBoost_:int = 0;
    public var healthPotionCount_:int = 0;
    public var magicPotionCount_:int = 0;
    public var attackMax_:int = 0;
    public var defenseMax_:int = 0;
    public var speedMax_:int = 0;
    public var dexterityMax_:int = 0;
    public var vitalityMax_:int = 0;
    public var wisdomMax_:int = 0;
    public var maxHPMax_:int = 0;
    public var maxMPMax_:int = 0;
    public var hasBackpack_:Boolean = false;
    public var starred_:Boolean = false;
    public var ignored_:Boolean = false;
    public var distSqFromThisPlayer_:Number = 0;
    protected var rotate_:Number = 0;
    public var relMoveVec_:Point = null;
    protected var moveMultiplier_:Number = 1;
    public var attackPeriod_:int = 0;
    public var lastAltAttack_:int = 0;
    public var nextAltAttack_:int = 0;
    public var nextTeleportAt_:int = 0;
    public var dropBoost:int = 0;
    public var tierBoost:int = 0;
    protected var healingEffect_:HealingEffect = null;
    protected var nearestMerchant_:Merchant = null;
    public var isDefaultAnimatedChar:Boolean = true;
    public var projectileIdSetOverrideNew:String = "";
    public var projectileIdSetOverrideOld:String = "";
    private var addTextLine:AddTextLineSignal;
    private var factory:CharacterFactory;
    private var breathBackFill_:GraphicsSolidFill = null;
    private var breathBackPath_:GraphicsPath = null;
    private var breathFill_:GraphicsSolidFill = null;
    private var breathPath_:GraphicsPath = null;
    public var collect:int;
    public var thunderTime:int;
    public var recordPointer:int;
    public var autohealtimer:int = 0;
    private var bools:Array = [false, false, false, false, false, false, false, false];
    public var remBuff:Vector.<int> = new Vector.<int>(0);
    public var creditsWereChanged:Signal = new Signal();
    private var ip_:IntPoint = new IntPoint();
    public var lastSwap_:int=-1;
    [Inject]
    public var hudModel:HUDModel;

    public function Player(_arg_1:XML)
    {
        var _local_2:Injector = StaticInjectorContext.getInjector();
        this.addTextLine = _local_2.getInstance(AddTextLineSignal);
        this.factory = _local_2.getInstance(CharacterFactory);
        this.potionInventoryModel = _local_2.getInstance(PotionInventoryModel);
        this.useBuyPotionSignal = _local_2.getInstance(UseBuyPotionSignal);
        super(_arg_1);
        this.attackMax_ = int(_arg_1.Attack.@max);
        this.defenseMax_ = int(_arg_1.Defense.@max);
        this.speedMax_ = int(_arg_1.Speed.@max);
        this.dexterityMax_ = int(_arg_1.Dexterity.@max);
        this.vitalityMax_ = int(_arg_1.HpRegen.@max);
        this.wisdomMax_ = int(_arg_1.MpRegen.@max);
        this.maxHPMax_ = int(_arg_1.MaxHitPoints.@max);
        this.maxMPMax_ = int(_arg_1.MaxMagicPoints.@max);
        texturingCache_ = new Dictionary();
    }

    public static function fromPlayerXML(_arg_1:String, _arg_2:XML):Player
    {
        var _local_3:int = int(_arg_2.ObjectType);
        var _local_4:XML = ObjectLibrary.xmlLibrary_[_local_3];
        var _local_5:Player = new Player(_local_4);
        _local_5.name_ = _arg_1;
        _local_5.level_ = int(_arg_2.Level);
        _local_5.exp_ = int(_arg_2.Exp);
        _local_5.equipment_ = ConversionUtil.toIntVector(_arg_2.Equipment);
        _local_5.maxHP_ = int(_arg_2.MaxHitPoints);
        _local_5.hp_ = int(_arg_2.HitPoints);
        _local_5.maxMP_ = int(_arg_2.MaxMagicPoints);
        _local_5.mp_ = int(_arg_2.MagicPoints);
        _local_5.attack_ = int(_arg_2.Attack);
        _local_5.defense_ = int(_arg_2.Defense);
        _local_5.speed_ = int(_arg_2.Speed);
        _local_5.dexterity_ = int(_arg_2.Dexterity);
        _local_5.vitality_ = int(_arg_2.HpRegen);
        _local_5.wisdom_ = int(_arg_2.MpRegen);
        _local_5.tex1Id_ = int(_arg_2.Tex1);
        _local_5.tex2Id_ = int(_arg_2.Tex2);
        return (_local_5);
    }

    private static function makeErrorMessage(_arg_1:String, _arg_2:Object=null):ChatMessage
    {
        return (ChatMessage.make(Parameters.ERROR_CHAT_NAME, _arg_1, -1, -1, "", false, _arg_2));
    }

    public function getFamePortrait(_arg_1:int):BitmapData{
        var _local_2:MaskedImage;
        if (this.famePortrait_ == null){
            _local_2 = animatedChar_.imageFromDir(AnimatedChar.RIGHT, AnimatedChar.STAND, 0);
            _arg_1 = int(((4 / _local_2.image_.width) * _arg_1));
            this.famePortrait_ = TextureRedrawer.resize(_local_2.image_, _local_2.mask_, _arg_1, true, tex1Id_, tex2Id_);
            this.famePortrait_ = GlowRedrawer.outlineGlow(this.famePortrait_, 0);
        }
        return (this.famePortrait_);
    }

    public function getFameBonus():int{
        var _local_3:int;
        var _local_4:XML;
        var _local_1:int;
        var _local_2:uint;
        while (_local_2 < GeneralConstants.NUM_EQUIPMENT_SLOTS) {
            if (((equipment_) && (equipment_.length > _local_2))){
                _local_3 = equipment_[_local_2];
                if (_local_3 != -1){
                    _local_4 = ObjectLibrary.xmlLibrary_[_local_3];
                    if (((!(_local_4 == null)) && (_local_4.hasOwnProperty("FameBonus")))){
                        _local_1 = (_local_1 + int(_local_4.FameBonus));
                    }
                }
            }
            _local_2++;
        }
        return (_local_1);
    }

    public function setRelativeMovement(_arg_1:Number, _arg_2:Number, _arg_3:Number):void
    {
        var _local_4:Number;
        if (this.relMoveVec_ == null)
        {
            this.relMoveVec_ = new Point();
        }
        this.rotate_ = _arg_1;
        this.relMoveVec_.x = _arg_2;
        this.relMoveVec_.y = _arg_3;
        if (isConfused())
        {
            _local_4 = this.relMoveVec_.x;
            this.relMoveVec_.x = -(this.relMoveVec_.y);
            this.relMoveVec_.y = -(_local_4);
            this.rotate_ = -(this.rotate_);
        }
    }

    public function setCredits(_arg_1:int):void
    {
        this.credits_ = _arg_1;
        this.creditsWereChanged.dispatch();
    }

    public function setFame(_arg_1:int):void{
        this.fame_ = _arg_1;
        this.fameWasChanged.dispatch();
    }

    public function setTokens(_arg_1:int):void
    {
        this.tokens_ = _arg_1;
    }

    public function setGuildName(_arg_1:String):void
    {
        var _local_2:GameObject;
        var _local_3:Player;
        var _local_4:Boolean;
        this.guildName_ = _arg_1;
        var _local_5:Player = map_.player_;
        if (_local_5 == this)
        {
            for each (_local_2 in map_.goDict_)
            {
                _local_3 = (_local_2 as Player);
                if (((!(_local_3 == null)) && (!(_local_3 == this))))
                {
                    _local_3.setGuildName(_local_3.guildName_);
                }
            }
        }
        else
        {
            _local_4 = ((((!(_local_5 == null)) && (!(_local_5.guildName_ == null))) && (!(_local_5.guildName_ == ""))) && (_local_5.guildName_ == this.guildName_));
            if (_local_4 != this.isFellowGuild_)
            {
                this.isFellowGuild_ = _local_4;
                nameBitmapData_ = null;
            }
        }
    }

    public function isTeleportEligible(_arg_1:Player):Boolean
    {
        return (!(((_arg_1.dead_) || (_arg_1.isPaused())) || (_arg_1.isInvisible())));
    }

    public function msUtilTeleport():int
    {
        var _local_1:int = getTimer();
        return (Math.max(0, (this.nextTeleportAt_ - _local_1)));
    }

    public function teleportTo(_arg_1:Player):Boolean
    {
        if (isPaused())
        {
            this.addTextLine.dispatch(makeErrorMessage(TextKey.PLAYER_NOTELEPORTWHILEPAUSED));
            return (false);
        }
        if (!this.isTeleportEligible(_arg_1))
        {
            if (_arg_1.isInvisible())
            {
                this.addTextLine.dispatch(makeErrorMessage(TextKey.TELEPORT_INVISIBLE_PLAYER, {"player":_arg_1.name_}));
            }
            else
            {
                this.addTextLine.dispatch(makeErrorMessage(TextKey.PLAYER_TELEPORT_TO_PLAYER, {"player":_arg_1.name_}));
            }
            return (false);
        }
        map_.gs_.gsc_.teleport(_arg_1.name_);
        return (true);
    }

    public function levelUpEffect(_arg_1:String, _arg_2:Boolean=true):void
    {
        if (Options.hidden) {
            return;
        }
        if (_arg_2)
        {
            this.levelUpParticleEffect();
        }
        var _local_3:CharacterStatusText = new CharacterStatusText(this, 0xFF00, 2000);
        _local_3.setStringBuilder(new LineBuilder().setParams(_arg_1));
        map_.mapOverlay_.addStatusText(_local_3);
    }

    public function handleLevelUp(_arg_1:Boolean):void
    {
        var _local_2:XML;
        var _local_3:Array;
        var _local_4:String;
        var _local_5:Array;
        var _local_6:Array;
        var _local_7:int;
        var _local_8:XML;
        var _local_9:int;
        var _local_10:Number;
        var _local_11:Number;
        SoundEffectLibrary.play("level_up");
        if (_arg_1)
        {
            this.levelUpEffect(TextKey.PLAYER_NEWCLASSUNLOCKED, false);
            this.levelUpEffect(TextKey.PLAYER_LEVELUP);
        }
        else
        {
            this.levelUpEffect(TextKey.PLAYER_LEVELUP);
        }
        if (objectId_ == map_.player_.objectId_)
        {
            this.chp = maxHP_;
            _local_2 = ObjectLibrary.xmlLibrary_[objectType_];
            _local_3 = [];
            _local_4 = "You rolled ";
            _local_5 = ["HP", "MP", "ATT", "DEF", "SPD", "DEX", "VIT", "WIS"];
            _local_6 = [((maxHP_ - this.maxHPBoost_) - _local_2.MaxHitPoints), ((this.maxMP_ - this.maxMPBoost_) - _local_2.MaxMagicPoints), ((this.attack_ - this.attackBoost_) - _local_2.Attack), ((defense_ - this.defenseBoost_) - _local_2.Defense), ((this.speed_ - this.speedBoost_) - _local_2.Speed), ((this.dexterity_ - this.dexterityBoost_) - _local_2.Dexterity), ((this.vitality_ - this.vitalityBoost_) - _local_2.HpRegen), ((this.wisdom_ - this.wisdomBoost_) - _local_2.MpRegen)];
            _local_7 = 0;
            for each (_local_8 in _local_2.LevelIncrease)
            {
                _local_10 = ((int(_local_8.@min) + int(_local_8.@max)) / 2);
                _local_11 = (_local_6[_local_7] - ((level_ - 1) * _local_10));
                _local_3.push(_local_11);
                _local_7++;
            }
            _local_9 = 0;
            while (_local_9 < 8)
            {
                if (_local_3[_local_9] > 0)
                {
                    _local_4 = (_local_4 + (((("+" + _local_3[_local_9]) + " ") + _local_5[_local_9]) + ", "));
                }
                else
                {
                    _local_4 = (_local_4 + (((_local_3[_local_9] + " ") + _local_5[_local_9]) + ", "));
                }
                _local_9++;
            }
            this.addTextLine.dispatch(ChatMessage.make(Parameters.HELP_CHAT_NAME, _local_4.substr(0, (_local_4.length - 2))));
        }
    }

    public function levelUpParticleEffect(_arg_1:uint=0xFF00FF00):void
    {
        map_.addObj(new LevelUpEffect(this, _arg_1, 20), x_, y_);
    }

    public function handleExpUp(_arg_1:int):void
    {
        if (((level_ == 20) && (!(this.bForceExp()))))
        {
            return;
        }
        if (((Parameters.data_.AntiLag) && (!(this.objectId_ == map_.player_.objectId_))))
        {
            return;
        }
        var _local_2:CharacterStatusText = new CharacterStatusText(this, 0xFF00, 1000);
        _local_2.setStringBuilder(new LineBuilder().setParams(TextKey.PLAYER_EXP, {"exp":_arg_1}));
        map_.mapOverlay_.addStatusText(_local_2);
    }

    private function bForceExp():Boolean{
        return ((Parameters.data_.forceEXP) && ((Parameters.data_.forceEXP == 1) || ((Parameters.data_.forceEXP == 2) && (map_.player_ == this))));
    }

    private function getNearbyMerchant():Merchant
    {
        var _local_1:Point;
        var _local_2:Merchant;
        var _local_3:int = (((x_ - int(x_)) > 0.5) ? 1 : -1);
        var _local_4:int = (((y_ - int(y_)) > 0.5) ? 1 : -1);
        for each (_local_1 in NEARBY)
        {
            this.ip_.x_ = (x_ + (_local_3 * _local_1.x));
            this.ip_.y_ = (y_ + (_local_4 * _local_1.y));
            _local_2 = map_.merchLookup_[this.ip_];
            if (_local_2 != null)
            {
                return ((PointUtil.distanceSquaredXY(_local_2.x_, _local_2.y_, x_, y_) < 1) ? _local_2 : null);
            }
        }
        return (null);
    }

    public function walkTo(_arg_1:Number, _arg_2:Number):Boolean
    {
        this.modifyMove(_arg_1, _arg_2, newP);
        return (this.moveTo(newP.x, newP.y));
    }

    override public function moveTo(_arg_1:Number, _arg_2:Number):Boolean
    {
        var _local_3:Boolean = super.moveTo(_arg_1, _arg_2);
        if (map_.gs_.evalIsNotInCombatMapArea())
        {
            this.nearestMerchant_ = this.getNearbyMerchant();
        }
        return (_local_3);
    }

    public function targetAA():void{
        var _local_1:int;
        var _local_2:Boolean;
        if (this.aimAssistPoint != null){
            if (!this.aimAssistTarget.isStasis() && !this.aimAssistTarget.isInvincible() && !this.aimAssistTarget.isInvulnerable() && this.aimAssistTarget.maxHP_ >= Parameters.data_.spellThreshold) {
                this.useAltWeapon_(this.aimAssistPoint.x, this.aimAssistPoint.y, 1, true);
            }
        }
    }

    public function autoAbility():void{
        var _local_1:int = equipment_[1];
        var _local_2:int = ObjectLibrary.xmlLibrary_[_local_1].MpCost;
        if (_local_2 > this.mp_ || this.nextAltAttack_ > getTimer() || _local_1 == -1 || isSilenced())
        {
            return;
        }

        switch (this.objectType_){
            case 801:
            case 782:
            case 803:
            case 802:
            case 775:
            case 805:
            case 798:
            case 800:
            case 785:
                this.targetAA();
                return;
            default:
                return;
        }
    }

    public function modifyMove(_arg_1:Number, _arg_2:Number, _arg_3:Point):void
    {
        var _local_4:Boolean;
        if (((isParalyzed()) || (isPetrified())))
        {
            _arg_3.x = x_;
            _arg_3.y = y_;
            return;
        }
        var _local_5:Number = (_arg_1 - x_);
        var _local_6:Number = (_arg_2 - y_);
        if (((((_local_5 < MOVE_THRESHOLD) && (_local_5 > -(MOVE_THRESHOLD))) && (_local_6 < MOVE_THRESHOLD)) && (_local_6 > -(MOVE_THRESHOLD))))
        {
            this.modifyStep(_arg_1, _arg_2, _arg_3);
            return;
        }
        var _local_7:Number = (MOVE_THRESHOLD / Math.max(Math.abs(_local_5), Math.abs(_local_6)));
        var _local_8:Number = 0;
        _arg_3.x = x_;
        _arg_3.y = y_;
        while ((!(_local_4)))
        {
            if ((_local_8 + _local_7) >= 1)
            {
                _local_7 = (1 - _local_8);
                _local_4 = true;
            }
            this.modifyStep((_arg_3.x + (_local_5 * _local_7)), (_arg_3.y + (_local_6 * _local_7)), _arg_3);
            _local_8 = (_local_8 + _local_7);
        }
    }

    public function modifyStep(_arg_1:Number, _arg_2:Number, _arg_3:Point):void
    {
        var _local_4:Number;
        var _local_5:Number;
        var _local_6:Boolean = ((((x_ % 0.5) == 0) && (!(_arg_1 == x_))) || (!(int((x_ / 0.5)) == int((_arg_1 / 0.5)))));
        var _local_7:Boolean = ((((y_ % 0.5) == 0) && (!(_arg_2 == y_))) || (!(int((y_ / 0.5)) == int((_arg_2 / 0.5)))));
        if ((((!(_local_6)) && (!(_local_7))) || (this.isValidPosition(_arg_1, _arg_2))))
        {
            _arg_3.x = _arg_1;
            _arg_3.y = _arg_2;
            return;
        }
        if (_local_6)
        {
            _local_4 = ((_arg_1 > x_) ? (int((_arg_1 * 2)) / 2) : (int((x_ * 2)) / 2));
            if (int(_local_4) > int(x_))
            {
                _local_4 = (_local_4 - 0.01);
            }
        }
        if (_local_7)
        {
            _local_5 = ((_arg_2 > y_) ? (int((_arg_2 * 2)) / 2) : (int((y_ * 2)) / 2));
            if (int(_local_5) > int(y_))
            {
                _local_5 = (_local_5 - 0.01);
            }
        }
        if (!_local_6)
        {
            _arg_3.x = _arg_1;
            _arg_3.y = _local_5;
            if (((!(square_ == null)) && (!(square_.props_.slideAmount_ == 0))))
            {
                this.resetMoveVector(false);
            }
            return;
        }
        if (!_local_7)
        {
            _arg_3.x = _local_4;
            _arg_3.y = _arg_2;
            if (((!(square_ == null)) && (!(square_.props_.slideAmount_ == 0))))
            {
                this.resetMoveVector(true);
            }
            return;
        }
        var _local_8:Number = ((_arg_1 > x_) ? (_arg_1 - _local_4) : (_local_4 - _arg_1));
        var _local_9:Number = ((_arg_2 > y_) ? (_arg_2 - _local_5) : (_local_5 - _arg_2));
        if (_local_8 > _local_9)
        {
            if (this.isValidPosition(_arg_1, _local_5))
            {
                _arg_3.x = _arg_1;
                _arg_3.y = _local_5;
                return;
            }
            if (this.isValidPosition(_local_4, _arg_2))
            {
                _arg_3.x = _local_4;
                _arg_3.y = _arg_2;
                return;
            }
        }
        else
        {
            if (this.isValidPosition(_local_4, _arg_2))
            {
                _arg_3.x = _local_4;
                _arg_3.y = _arg_2;
                return;
            }
            if (this.isValidPosition(_arg_1, _local_5))
            {
                _arg_3.x = _arg_1;
                _arg_3.y = _local_5;
                return;
            }
        }
        _arg_3.x = _local_4;
        _arg_3.y = _local_5;
    }

    private function resetMoveVector(_arg_1:Boolean):void
    {
        moveVec_.scaleBy(-0.5);
        if (_arg_1)
        {
            moveVec_.y = (moveVec_.y * -1);
        }
        else
        {
            moveVec_.x = (moveVec_.x * -1);
        }
    }

    public function isValidPosition(_arg_1:Number, _arg_2:Number):Boolean
    {
        var _local_3:Square = map_.getSquare(_arg_1, _arg_2);
        if (Parameters.data_.SafeWalk != false)
        {
            if ((((!(map_.gs_.mui_.mouseDown_ == true)) && (!(_local_3.props_.maxDamage_ == 0))) && (_local_3.obj_ == null)))
            {
                return (false);
            }
        }
        if (((!(square_ == _local_3)) && ((_local_3 == null) || (!(_local_3.isWalkable())))))
        {
            return (false);
        }
        var _local_4:Number = (_arg_1 - int(_arg_1));
        var _local_5:Number = (_arg_2 - int(_arg_2));
        if (_local_4 < 0.5)
        {
            if (this.isFullOccupy((_arg_1 - 1), _arg_2))
            {
                return (false);
            }
            if (_local_5 < 0.5)
            {
                if (((this.isFullOccupy(_arg_1, (_arg_2 - 1))) || (this.isFullOccupy((_arg_1 - 1), (_arg_2 - 1)))))
                {
                    return (false);
                }
            }
            else
            {
                if (_local_5 > 0.5)
                {
                    if (((this.isFullOccupy(_arg_1, (_arg_2 + 1))) || (this.isFullOccupy((_arg_1 - 1), (_arg_2 + 1)))))
                    {
                        return (false);
                    }
                }
            }
        }
        else
        {
            if (_local_4 > 0.5)
            {
                if (this.isFullOccupy((_arg_1 + 1), _arg_2))
                {
                    return (false);
                }
                if (_local_5 < 0.5)
                {
                    if (((this.isFullOccupy(_arg_1, (_arg_2 - 1))) || (this.isFullOccupy((_arg_1 + 1), (_arg_2 - 1)))))
                    {
                        return (false);
                    }
                }
                else
                {
                    if (_local_5 > 0.5)
                    {
                        if (((this.isFullOccupy(_arg_1, (_arg_2 + 1))) || (this.isFullOccupy((_arg_1 + 1), (_arg_2 + 1)))))
                        {
                            return (false);
                        }
                    }
                }
            }
            else
            {
                if (_local_5 < 0.5)
                {
                    if (this.isFullOccupy(_arg_1, (_arg_2 - 1)))
                    {
                        return (false);
                    }
                }
                else
                {
                    if (_local_5 > 0.5)
                    {
                        if (this.isFullOccupy(_arg_1, (_arg_2 + 1)))
                        {
                            return (false);
                        }
                    }
                }
            }
        }
        return (true);
    }

    public function isFullOccupy(_arg_1:Number, _arg_2:Number):Boolean
    {
        var _local_3:Square = map_.lookupSquare(_arg_1, _arg_2);
        return (((_local_3 == null) || (_local_3.tileType_ == 0xFF)) || ((!(_local_3.obj_ == null)) && (_local_3.obj_.props_.fullOccupy_)));
    }

    public function notifyPlayer(_arg_1:String, _arg_2:int=0xFF00, _arg_3:int=1500):void
    {
        if (Options.hidden) {
            return;
        }
        var _local_4:CharacterStatusText = new CharacterStatusText(this, _arg_2, _arg_3);
        _local_4.setStringBuilder(new StaticStringBuilder(_arg_1));
        map_.mapOverlay_.addStatusText(_local_4);
    }

    public function lootNotif(_arg_1:String, _arg_2:GameObject):void
    {
        if (Options.hidden) {
            return;
        }
        var _local_3:CharacterStatusText = new CharacterStatusText(_arg_2, 0xFFFF, 4000);
        _local_3.setStringBuilder(new StaticStringBuilder(_arg_1));
        map_.mapOverlay_.addStatusText(_local_3);
    }

    public function notWanted(_arg_1:XML):Boolean
    {
        var _local_2:Boolean;
        var _local_3:String;
        var _local_4:String;
        for each (_local_4 in Parameters.data_.NoLoot)
        {
            if (String(_arg_1.@id).toLowerCase().search(_local_4) != -1)
            {
                return (true);
            }
        }
        return (false);
    }

    public function genWantedList():Vector.<int>
    {
        var _local_1:XML;
        var _local_2:String;
        var _local_3:int;
        var _local_4:Vector.<int> = new Vector.<int>();
        _local_4.push(HEALTH_POT);
        _local_4.push(MAGIC_POT);
        for each (_local_1 in ObjectLibrary.xmlLibrary_)
        {
            if (_local_1.hasOwnProperty("Item"))
            {
                if (!this.notWanted(_local_1))
                {
                    if (_local_1.hasOwnProperty("Activate"))
                    {
                        for each (_local_2 in _local_1.Activate)
                        {
                            if (_local_2 == "IncrementStat")
                            {
                                _local_3 = int(_local_1.Activate.@stat);
                                switch (_local_3)
                                {
                                    case 21:
                                    case 20:
                                    case 0:
                                    case 3:
                                        if (Parameters.data_.potsMajor)
                                        {
                                            _local_4.push(ObjectLibrary.idToType_[String(_local_1.@id)]);
                                        }
                                        break;
                                    case 22:
                                    case 26:
                                    case 27:
                                    case 28:
                                        if (Parameters.data_.potsMinor)
                                        {
                                            _local_4.push(ObjectLibrary.idToType_[String(_local_1.@id)]);
                                        }
                                        break;
                                }
                            }
                        }
                    }
                    if (!_local_1.hasOwnProperty("Tier"))
                    {
                        _local_4.push(ObjectLibrary.idToType_[String(_local_1.@id)]);
                    }
                    else
                    {
                        if (((_local_1.hasOwnProperty("Usable")) && (_local_1.Tier >= Parameters.data_.LNAbility)))
                        {
                            _local_4.push(ObjectLibrary.idToType_[String(_local_1.@id)]);
                        }
                        else
                        {
                            if ((((_local_1.hasOwnProperty("SlotType")) && (_local_1.SlotType == 9)) && (_local_1.Tier >= Parameters.data_.LNRing)))
                            {
                                _local_4.push(ObjectLibrary.idToType_[String(_local_1.@id)]);
                            }
                            else
                            {
                                if ((((!(_local_1.hasOwnProperty("Usable"))) && (_local_1.Tier >= Parameters.data_.LNWeap)) && (_local_1.hasOwnProperty("Projectile"))))
                                {
                                    _local_4.push(ObjectLibrary.idToType_[String(_local_1.@id)]);
                                }
                                else
                                {
                                    if (((!(_local_1.hasOwnProperty("Usable"))) && (_local_1.Tier >= Parameters.data_.LNArmor)))
                                    {
                                        _local_4.push(ObjectLibrary.idToType_[String(_local_1.@id)]);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return (_local_4);
    }

    public function bagDist(_arg_1:GameObject, _arg_2:Container):Number
    {
        var _local_3:Number = (_arg_1.x_ - _arg_2.x_);
        var _local_4:Number = (_arg_1.y_ - _arg_2.y_);
        return (Math.sqrt(((_local_3 * _local_3) + (_local_4 * _local_4))));
    }

    public function getLootableBags(_arg_1:Vector.<Container>, _arg_2:Number):Vector.<Container>
    {
        var _local_3:Container;
        var _local_4:Vector.<Container> = new Vector.<Container>();
        for each (_local_3 in _arg_1)
        {
            if (this.bagDist(map_.player_, _local_3) <= _arg_2)
            {
                _local_4.push(_local_3);
            }
        }
        return (_local_4);
    }

    public function getLootBags():Vector.<Container>
    {
        var _local_1:GameObject;
        var _local_2:Vector.<Container> = new Vector.<Container>();
        for each (_local_1 in map_.goDict_)
        {
            if ((((_local_1 is Container) && (!(_local_1.objectType_ == VAULT_CHEST))) && (!(_local_1.objectType_ == 1860))))
            {
                _local_2.push(_local_1);
            }
        }
        return (_local_2);
    }

    public function lookForLoot():Boolean
    {
        var _local_1:int = getTimer();
        var _local_2:int = int((1000 / SEARCH_LOOT_FREQ));
        if (((this == map_.player_) && ((_local_1 - lastSearchTime) > _local_2)))
        {
            lastSearchTime = _local_1;
            return (true);
        }
        return (false);
    }

    public function isWantedItem(_arg_1:int):Boolean
    {
        var _local_2:int;
        for each (_local_2 in Parameters.data_.lootIgnore)
        {
            if (_arg_1 == _local_2)
            {
                return (false);
            }
        }
        for each (_local_2 in wantedList)
        {
            if (_arg_1 == _local_2)
            {
                return (true);
            }
        }
        return (false);
    }

    public function lootItem(_arg_1:int, _arg_2:Container, _arg_3:int, _arg_4:int, _arg_5:int):void
    {
        var _local_5:Boolean = ((!(_arg_1 == HEALTH_SLOT)) && (!(_arg_1 == MAGIC_SLOT)));
        var _local_6:Boolean = ((_arg_4 == HEALTH_POT) || (_arg_4 == MAGIC_POT));
        if ((((this.healthPotionCount_ < MAX_STACK_POTS) && (_arg_4 == HEALTH_POT)) || ((this.magicPotionCount_ < MAX_STACK_POTS) && (_arg_4 == MAGIC_POT))))
        {
            map_.gs_.gsc_.invSwapPotion(this, _arg_2, _arg_3, _arg_4, this, (_arg_4 - 2340), -1);
        }
        else
        {
            if ((((_local_5) && (_local_6)) && (!((nextLootSlot == HEALTH_POT) || (nextLootSlot == MAGIC_POT)))))
            {
                if ((((_arg_4 == 2594) && (!(Parameters.data_.lootHP))) || ((_arg_4 == 2595) && (!(Parameters.data_.lootMP)))))
                {
                    return;
                }
                map_.gs_.gsc_.invSwap(this, this, _arg_1, nextLootSlot, _arg_2, _arg_3, _arg_4);
            }
            else
            {
                if (((_local_5) && (!(_local_6))))
                {
                    if (nextLootSlot == -1)
                    {
                        map_.gs_.gsc_.invSwap(this, _arg_2, _arg_3, _arg_4, this, _arg_1, -1);
                    }
                    else
                    {
                        if (Parameters.data_.drinkPot)
                        {
                            map_.gs_.gsc_.useItem(getTimer(), this.objectId_, _arg_1, nextLootSlot, this.x_, this.y_, 0);
                            map_.gs_.gsc_.invSwap(this, _arg_2, _arg_3, _arg_4, this, _arg_1, -1);
                        }
                        else
                        {
                            map_.gs_.gsc_.invSwap(this, _arg_2, _arg_3, _arg_4, this, _arg_1, equipment_[_arg_1]);
                        }
                    }
                }
            }
        }
        lastLootTime = getTimer();
        this.map_.gs_.gsc_.lastInvSwapTime = _arg_5;
    }

    public function nextAvailableInventorySlotMod():int
    {
        var _local_1:int = ((this.hasBackpack_) ? equipment_.length : (equipment_.length - GeneralConstants.NUM_INVENTORY_SLOTS));
        var _local_2:uint = 4;
        while (_local_2 < _local_1)
        {
            if (equipment_[_local_2] == -1)
            {
                nextLootSlot = equipment_[_local_2];
                return (_local_2);
            }
            _local_2++;
        }
        _local_2 = 4;
        while (_local_2 < _local_1)
        {
            if (((equipment_[_local_2] == HEALTH_POT) || (equipment_[_local_2] == MAGIC_POT)))
            {
                nextLootSlot = equipment_[_local_2];
                return (_local_2);
            }
            _local_2++;
        }
        return (-1);
    }

    public function okToLoot(_arg_1:int):Boolean
    {
        var _local_2:int = getTimer();
        var _local_3:int = (_local_2 - lastLootTime);
        if (_local_3 < LOOT_EVERY_MS)
        {
            return (false);
        }
        if ((((!(this.nextAvailableInventorySlotMod() == -1)) || ((_arg_1 == HEALTH_POT) && (this.healthPotionCount_ < 6))) || ((_arg_1 == MAGIC_POT) && (this.magicPotionCount_ < 6))))
        {
            return (true);
        }
        return (false);
    }

    public function autoloot_(_arg_1:int):void
    {
        if ((_arg_1 - this.map_.gs_.gsc_.lastInvSwapTime) < 500){
            return;
        }
        var _local_1:Container;
        var _local_2:int;
        var _local_3:Player;
        var _local_4:int;
        var _local_5:Vector.<Container> = this.getLootBags();
        _local_5 = this.getLootableBags(_local_5, MAX_LOOT_DIST);
        for each (_local_1 in _local_5)
        {
            _local_4 = 0;
            for each (_local_2 in _local_1.equipment_)
            {
                if (((this.isWantedItem(_local_2)) && (this.okToLoot(_local_2))))
                {
                    if (_local_1.objectId_ != GameServerConnectionConcrete.ignoredBag)
                    {
                        this.lootItem(this.nextAvailableInventorySlotMod(), _local_1, _local_4, _local_2, _arg_1);
                    }
                    return;
                }
                _local_4 = (_local_4 + 1);
            }
        }
    }

    public function vault_():void
    {
        var _local_1:int;
        var _local_2:GameObject;
        var _local_3:int;
        var _local_4:int;
        var _local_5:Container;
        var _local_6:int;
        _local_1 = 4;
        while (_local_1 < equipment_.length)
        {
            if (((!(this.hasBackpack_)) && (_local_1 > 11))) break;
            if (((this.collect > 0) && (equipment_[_local_1] == -1)))
            {
                _local_6 = _local_1;
                break;
            }
            if (((this.collect < 0) && (equipment_[_local_1] == (0 - this.collect))))
            {
                _local_6 = _local_1;
                break;
            }
            if (this.collect == int.MIN_VALUE)
            {
                switch (equipment_[_local_1])
                {
                    case 2592:
                    case 2591:
                    case 2593:
                    case 2636:
                    case 2612:
                    case 2613:
                    case 2793:
                    case 2794:
                        _local_6 = _local_1;
                        break;
                }
            }
            _local_1++;
        }
        if (_local_6 == 0)
        {
            this.collect = 0;
            this.notifyPlayer("Stopping", 0xFF0000, 1500);
            return;
        }
        for each (_local_2 in map_.goDict_)
        {
            if (_local_2.objectType_ == VAULT_CHEST)
            {
                if (_local_5 == null)
                {
                    _local_5 = (_local_2 as Container);
                    _local_3 = int((((x_ - _local_5.x_) * (x_ - _local_5.x_)) + ((y_ - _local_5.y_) * (y_ - _local_5.y_))));
                }
                else
                {
                    _local_4 = int((((x_ - _local_2.x_) * (x_ - _local_2.x_)) + ((y_ - _local_2.y_) * (y_ - _local_2.y_))));
                    if (_local_4 < _local_3)
                    {
                        _local_3 = _local_4;
                        _local_5 = (_local_2 as Container);
                    }
                }
            }
        }
        if (_local_5 == null)
        {
            return;
        }
        if (_local_3 > MAX_LOOT_DIST)
        {
            return;
        }
        _local_1 = 0;
        while (_local_1 < _local_5.equipment_.length)
        {
            if (_local_5.equipment_[_local_1] == this.collect)
            {
                map_.gs_.gsc_.invSwap(this, _local_5, _local_1, _local_5.equipment_[_local_1], this, _local_6, equipment_[_local_6]);
                lastLootTime = getTimer();
                return;
            }
            if (((_local_5.equipment_[_local_1] == -1) && (this.collect < 0)))
            {
                map_.gs_.gsc_.invSwap(this, this, _local_6, equipment_[_local_6], _local_5, _local_1, _local_5.equipment_[_local_1]);
                lastLootTime = getTimer();
                return;
            }
            if (this.collect == int.MAX_VALUE)
            {
                switch (_local_5.equipment_[_local_1])
                {
                    case 2592:
                    case 2591:
                    case 2593:
                    case 2636:
                    case 2612:
                    case 2613:
                    case 2793:
                    case 2794:
                        map_.gs_.gsc_.invSwap(this, _local_5, _local_1, _local_5.equipment_[_local_1], this, _local_6, equipment_[_local_6]);
                        lastLootTime = getTimer();
                        return;
                }
            }
            _local_1++;
        }
        this.collect = 0;
        this.notifyPlayer("Stopping", 0xFF0000, 1500);
    }

    private function swapInvBp(_arg_1:int):void
    {
        if (getTimer() >= this.nextSwap)
        {
            map_.gs_.gsc_.invSwap(this, this, (_arg_1 + 4), equipment_[(_arg_1 + 4)], this, (_arg_1 + 12), equipment_[(_arg_1 + 12)]);
            this.bools[_arg_1] = false;
            this.nextSwap = (getTimer() + 600);
        }
    }

    private function selectSlot(_arg_1:TradeSlot):void
    {
        var _local_2:int;
        var _local_3:Vector.<Boolean> = new <Boolean>[false, false, false, false];
        this.nextSelect = (getTimer() + 175);
        _arg_1.setIncluded((!(_arg_1.included_)));
        _local_2 = 4;
        while (_local_2 < 12)
        {
            _local_3[_local_2] = map_.gs_.hudView.tradePanel.myInv_.slots_[_local_2].included_;
            _local_2++;
        }
        map_.gs_.gsc_.changeTrade(_local_3);
        map_.gs_.hudView.tradePanel.tradeButton_.setState(0);
    }

    private function naturalize(_arg_1:int):TradeSlot
    {
        var _local_2:Vector.<int> = new <int>[4, 8, 5, 9, 6, 10, 7, 11];
        return (map_.gs_.hudView.tradePanel.myInv_.slots_[_local_2[_arg_1]]);
    }

    private function findSlots():void
    {
        var _local_1:Player;
        var _local_2:int;
        while (_local_2 < 8)
        {
            _local_1 = map_.player_;
            if (_local_1.equipment_[(_local_2 + 4)] != _local_1.equipment_[(_local_2 + 12)])
            {
                this.bools[_local_2] = true;
            }
            _local_2++;
        }
    }

    public function startTimer(_arg_1:int, _arg_2:int=500):void
    {
        this.timerCount = 0;
        this.endCount = _arg_1;
        this.timerStep = _arg_2;
        this.startTime = getTimer();
    }

    override public function damage(_arg_1:Boolean, _arg_2:int, _arg_3:Vector.<uint>, _arg_4:Boolean, _arg_5:Projectile, _arg_6:Boolean = false):void
    {
        this.negateHealth(_arg_2);
        super.damage(_arg_1, _arg_2, _arg_3, false, _arg_5);
    }

    public function damageWithoutAck(_arg_1:int):void
    {
        this.negateHealth(_arg_1);
        showDamageText(_arg_1, false);
    }

    public function negateHealth(_arg_1:int):void
    {
        if (this == map_.player_)
        {
            this.chp = (this.chp - _arg_1);
            this.checkOPAuto();
        }
    }

    private function checkOPAuto():void
    {
        if ((((this.chp / maxHP_) * 100) <= (Parameters.AutoNexus + 10)) && (this.lastteleport <= getTimer()) && (Parameters.data_.tpBeforeNexus))
        {
            map_.gs_.gsc_.teleportId(this.map_.gs_.map.player_.objectId_);
            this.lastteleport = (getTimer() + MS_BETWEEN_TELEPORT);
        }
        if (((((this.chp / maxHP_) * 100) <= Parameters.AutoNexus) && !map_.gs_.isSafeMap && Parameters.AutoNexus != 0))
        {
            this.addTextLine.dispatch(ChatMessage.make("", (("You were saved at " + this.chp.toFixed(0)) + " health")));
            map_.gs_.gsc_.escape();
            if (this.opFailed)
            {
                this.addTextLine.dispatch(ChatMessage.make("*Error*", "Unable to find Nexus, disconnecting"));
                map_.gs_.closed.dispatch();
            }
            this.opFailed = true;
        }
    }

    public function getItemHp():int
    {
        var _local_1:XML;
        var _local_2:XML;
        var _local_3:int;
        var _local_4:int;
        while (_local_4 < 4)
        {
            if (equipment_[_local_4] != -1)
            {
                _local_1 = ObjectLibrary.xmlLibrary_[equipment_[_local_4]];
                if (_local_1.hasOwnProperty("ActivateOnEquip"))
                {
                    for each (_local_2 in _local_1.ActivateOnEquip)
                    {
                        if (_local_2.@stat == 0)
                        {
                            _local_3 = (_local_3 + _local_2.@amount);
                        }
                    }
                }
            }
            _local_4++;
        }
        return (_local_3);
    }

    public function checkAutonexus():void
    {
        if (((this == map_.player_) && (!(map_.gs_.isSafeMap))))
        {
            if (((hp_ / maxHP_) * 100) <= Parameters.AutoNexus)
            {
                map_.gs_.gsc_.escape();
            }
            if (((((hp_ / maxHP_) * 100) <= Parameters.data_.autoPot) && (!(isSick()))))
            {
                if (((this.potionInventoryModel.getPotionModel(PotionInventoryModel.HEALTH_POTION_ID).available) && ((this.lastPotionUse + 500) <= getTimer())))
                {
                    this.useBuyPotionSignal.dispatch(new UseBuyPotionVO(PotionInventoryModel.HEALTH_POTION_ID, UseBuyPotionVO.CONTEXTBUY));
                    this.lastPotionUse = getTimer();
                }
            }
        }
    }

    public override function update(arg1:int, arg2:int):Boolean
    {
        var loc2:*=0;
        var loc3:*=NaN;
        var loc4:*=NaN;
        var loc5:*=NaN;
        var loc6:*=null;
        var loc7:*=NaN;
        var loc8:*=0;
        var loc9:*=null;
        var loc10:*=0;
        var loc11:*=null;
        var loc12:*=null;
        var loc13:*=0;
        var loc14:*=null;
        var loc15:*=0;
        var loc16:*=0;
        var loc17:*=0;
        var loc18:*=NaN;
        var loc19:*=NaN;
        var loc20:*=null;
        var loc21:*=0;
        var loc22:*=NaN;
        var loc23:*=null;
        var loc24:*=null;
        var loc25:*=null;
        var loc26:*=null;
        var loc1:*=map_.gs_.gsc_;
        if (this == map_.player_)
        {
            if (com.company.assembleegameclient.parameters.Parameters.data_.dodBot)
            {
                com.company.assembleegameclient.objects.Party.dodBot(this);
            }
            if (com.company.assembleegameclient.parameters.Parameters.data_.templeBot)
            {
                com.company.assembleegameclient.objects.Party.templeBot(this);
            }
            if (com.company.assembleegameclient.parameters.Parameters.data_.thunderMove && com.company.assembleegameclient.parameters.Parameters.data_.preferredServer == "Proxy" && flash.utils.getTimer() > this.thunderTime + 50)
            {
                this.thunderTime = flash.utils.getTimer();
                map_.gs_.gsc_.thunderMove(this);
            }
            if (!(this.vitTime == -1) && !isPaused())
            {
                if (isBleeding())
                {
                    this.chp = this.chp - (flash.utils.getTimer() - this.vitTime) * 0.02;
                }
                else if (!isSick())
                {
                    if (isHealing())
                    {
                        this.chp = this.chp + (flash.utils.getTimer() - this.vitTime) * Number((21 + 0.12 * this.vitality_) / 1000);
                    }
                    else
                    {
                        this.chp = this.chp + (flash.utils.getTimer() - this.vitTime) * Number((1 + 0.12 * this.vitality_) / 1000);
                    }
                }
                if (this.breath_ == 0)
                {
                    this.chp = this.chp - (flash.utils.getTimer() - this.vitTime) * 0.094;
                }
                this.checkOPAuto();
                if (this.chp > maxHP_)
                {
                    this.chp = maxHP_;
                }
            }
            this.vitTime = flash.utils.getTimer();
            loc10 = -1;
            if (map_.quest_.getObject(1) != null)
            {
                loc10 = (loc12 = map_.quest_.getObject(1)).objectType_;
            }
            if (!(loc10 == 3366) && !(loc10 == 3367) && !(loc10 == 3368))
            {
                this.questMob = loc12;
            }
            else
            {
                this.questMob = null;
            }
            if (map_.gs_.gsc_.oncd && flash.utils.getTimer() >= this.nextTeleportAt_)
            {
                map_.gs_.gsc_.retryTeleport();
            }
            if (this.remBuff.length > 0 && flash.utils.getTimer() >= this.remBuff[(this.remBuff.length - 1)])
            {
                if (!((loc13 = this.getItemHp()) == this.cmaxhpboost) && !isHpBoosted())
                {
                    this.cmaxhp = this.cmaxhp - (this.cmaxhpboost - loc13);
                    this.cmaxhpboost = loc13;
                }
                this.remBuff.pop();
            }
            if (this.vitTime >= this.sendStr)
            {
                map_.gs_.gsc_.playerText(this.afkMsg);
                this.sendStr = int.MAX_VALUE;
            }
            if (wantedList == null)
            {
                wantedList = this.genWantedList();
            }
            if (com.company.assembleegameclient.parameters.Parameters.data_.AutoLootOn && this.lookForLoot())
            {
                this.autoloot_(arg1);
            }
            if (!(this.collect == 0) && map_.name_ == "Vault" && lastLootTime + 550 < flash.utils.getTimer())
            {
                this.vault_();
            }
            if (kabam.rotmg.chat.control.ParseChatMessageCommand.switch_)
            {
                this.findSlots();
                kabam.rotmg.chat.control.ParseChatMessageCommand.switch_ = false;
            }
            if (!(this.select_ == -1) && flash.utils.getTimer() >= this.nextSelect)
            {
                loc2 = this.loopStart;
                while (loc2 < 12)
                {
                    if ((loc14 = this.naturalize(loc2 - 4)).item_ == this.select_)
                    {
                        this.selectSlot(loc14);
                        this.loopStart = loc2 + 1;
                        if (loc2 == 11)
                        {
<<<<<<< HEAD
                        }
=======
                        };
>>>>>>> 0b99d611ef06705c12b96f965777905f657384b9
                    }
                    if (loc2 == 11)
                    {
                        this.select_ = -1;
                        this.loopStart = 4;
                    }
                    ++loc2;
                }
            }
            loc2 = 0;
            while (loc2 < 8)
            {
                if (this.bools[loc2])
                {
                    this.swapInvBp(loc2);
                    break;
                }
                ++loc2;
            }
            loc11 = map_.player_;
            if (lastLootTime + 550 < flash.utils.getTimer())
            {
                if (loc11.healthPotionCount_ < 0)
                {
                    if ((loc15 = loc11.getSlotwithItem(2594)) != -1)
                    {
                        map_.gs_.gsc_.invSwapPotion(loc11, loc11, loc15, 2594, loc11, 254, -1);
                        lastLootTime = flash.utils.getTimer();
                    }
                }
            }
            if (this.timerCount <= this.endCount && this.startTime + this.timerStep * this.timerCount <= flash.utils.getTimer())
            {
                loc16 = this.endCount * this.timerStep;
                loc17 = this.timerCount * this.timerStep;
                loc18 = (loc16 - loc17) / 1000;
                if (int(loc16 / 60000) > 0)
                {
                    loc20 = (loc19 = loc18 % 60).toFixed(this.timerStep < 1000 ? 1 : 0);
                    this.notifyPlayer(int(loc18 / 60).toString() + ":" + (loc19 < 10 ? "0" + loc20 : loc20), com.company.assembleegameclient.objects.GameObject.green2red(100 - loc17 / loc16 * 100));
                }
                else
                {
                    this.notifyPlayer(loc18.toFixed(this.timerStep < 1000 ? 1 : 0), com.company.assembleegameclient.objects.GameObject.green2red(100 - loc17 / loc16 * 100));
                }
                var loc27:*;
                var loc28:*=((loc27 = this).timerCount + 1);
                loc27.timerCount = loc28;
            }
<<<<<<< HEAD
            if (this == this.map_.player_ && !this.map_.gs_.isSafeMap && com.company.assembleegameclient.parameters.Parameters.data_.autoAbil && !(this.equipment_[1] == -1) && !isSilenced())
            {
                this.autoAbility();
            }
            if (this.mapAutoAbil && com.company.assembleegameclient.parameters.Parameters.data_.autoAbil && this.nextAutoAbil <= flash.utils.getTimer() && !com.company.assembleegameclient.parameters.Parameters.data_.blockAbil && !isSilenced())
=======
            if (this == this.map_.player_ && !this.map_.gs_.isSafeMap && com.company.assembleegameclient.parameters.Parameters.data_.autoAbil && !(this.equipment_[1] == -1))
            {
                this.autoAbility();
            }
            if (this.mapAutoAbil && this.nextAutoAbil <= flash.utils.getTimer() && !com.company.assembleegameclient.parameters.Parameters.data_.blockAbil)
>>>>>>> 0b99d611ef06705c12b96f965777905f657384b9
            {
                loc21 = 0;
                loc22 = 1 + this.wisdom_ / 150;
                loc27 = equipment_[1];
                switch (loc27)
                {
                    case com.company.assembleegameclient.objects.eItems.Cloak_of_Ghostly_Concealment:
                    case com.company.assembleegameclient.objects.eItems.Cloak_of_Endless_Twilight:
                    case com.company.assembleegameclient.objects.eItems.Cloak_of_Winter:
                    case com.company.assembleegameclient.objects.eItems.Ghastly_Drape:
                    {
                        loc21 = 6500;
<<<<<<< HEAD
                        break;
                    }
                    case com.company.assembleegameclient.objects.eItems.Helm_of_the_Great_General:
                    case com.company.assembleegameclient.objects.eItems.Golden_Helm:
                    case com.company.assembleegameclient.objects.eItems.Pathfinders_Helm:
                    case com.company.assembleegameclient.objects.eItems.Hivemaster_Helm:
                    {
                        loc21 = 7000;
                        break;
                    }
                    case com.company.assembleegameclient.objects.eItems.Helm_of_the_Juggernaut:
                    case com.company.assembleegameclient.objects.eItems.Helm_of_the_Jack_o_naut:
                    {
                        loc21 = 6000;
                        break;
                    }
                    case com.company.assembleegameclient.objects.eItems.Seal_of_the_Blasphemous_Prayer:
                    {
                        loc21 = 5000;
                        break;
                    }
                    case com.company.assembleegameclient.objects.eItems.Marble_Seal:
                    {
                        loc21 = 5500;
=======
                        break;
                    }
                    case com.company.assembleegameclient.objects.eItems.Helm_of_the_Great_General:
                    case com.company.assembleegameclient.objects.eItems.Golden_Helm:
                    case com.company.assembleegameclient.objects.eItems.Pathfinders_Helm:
                    case com.company.assembleegameclient.objects.eItems.Hivemaster_Helm:
                    {
                        loc21 = 7000;
                        break;
                    }
                    case com.company.assembleegameclient.objects.eItems.Helm_of_the_Juggernaut:
                    case com.company.assembleegameclient.objects.eItems.Helm_of_the_Jack_o_naut:
                    {
                        loc21 = 6000;
>>>>>>> 0b99d611ef06705c12b96f965777905f657384b9
                        break;
                    }
                    case com.company.assembleegameclient.objects.eItems.Seal_of_the_Blessed_Champion:
                    case com.company.assembleegameclient.objects.eItems.Seal_of_the_Holy_Warrior:
                    case com.company.assembleegameclient.objects.eItems.Advent_Seal:
                    {
                        if (com.company.assembleegameclient.parameters.Parameters.data_.palaSpam)
                        {
                            loc21 = 500;
                        }
                        else
                        {
                            loc21 = 2010;
                        }
                        break;
                    }
                    case com.company.assembleegameclient.objects.eItems.Seal_of_the_Initiate:
                    case com.company.assembleegameclient.objects.eItems.Seal_of_the_Pilgrim:
                    case com.company.assembleegameclient.objects.eItems.Seal_of_the_Seeker:
                    case com.company.assembleegameclient.objects.eItems.Seal_of_the_Aspirant:
                    case com.company.assembleegameclient.objects.eItems.Seal_of_the_Divine:
                    case com.company.assembleegameclient.objects.eItems.Tome_of_Renewing:
                    case com.company.assembleegameclient.objects.eItems.Tome_of_Holy_Guidance:
                    case com.company.assembleegameclient.objects.eItems.Nativity_Tome:
                    {
                        if (com.company.assembleegameclient.parameters.Parameters.data_.palaSpam)
                        {
                            loc21 = 500;
                        }
                        break;
                    }
                    case com.company.assembleegameclient.objects.eItems.Tome_of_Divine_Favor:
                    {
                        loc21 = 2000;
                        break;
                    }
                    case com.company.assembleegameclient.objects.eItems.Tome_of_Holy_Protection:
                    case com.company.assembleegameclient.objects.eItems.Tome_of_Purification:
                    case com.company.assembleegameclient.objects.eItems.Tome_of_Frigid_Protection:
<<<<<<< HEAD
                    case com.company.assembleegameclient.objects.eItems.Tome_of_Pain:
=======
>>>>>>> 0b99d611ef06705c12b96f965777905f657384b9
                    {
                        if (com.company.assembleegameclient.parameters.Parameters.data_.palaSpam)
                        {
                            loc21 = 500;
                        }
                        else
                        {
                            loc21 = 3000;
                        }
                        break;
                    }
                }
                if (loc21 > 0)
                {
                    this.useAltWeapon(x_, y_, kabam.rotmg.constants.UseType.START_USE, loc21);
                }
            }
            if (this.lastManaUse <= flash.utils.getTimer())
            {
                this.handleAutoMana();
            }
            if (this.autohealtimer <= flash.utils.getTimer())
            {
                loc21 = 0;
                loc22 = 1 + this.wisdom_ / 150;
                loc27 = equipment_[1];
                switch (loc27)
                {
                    case com.company.assembleegameclient.objects.eItems.Seal_of_the_Blessed_Champion:
                    case com.company.assembleegameclient.objects.eItems.Seal_of_the_Holy_Warrior:
                    case com.company.assembleegameclient.objects.eItems.Advent_Seal:
                    {
                        loc21 = 4000 * loc22 - 200;
                        break;
                    }
                    case com.company.assembleegameclient.objects.eItems.Seal_of_the_Initiate:
                    {
                        loc21 = 2500 * loc22 - 200;
                        break;
                    }
                    case com.company.assembleegameclient.objects.eItems.Seal_of_the_Pilgrim:
                    case com.company.assembleegameclient.objects.eItems.Seal_of_the_Seeker:
                    {
                        loc21 = 3000 * loc22 - 200;
                        break;
                    }
                    case com.company.assembleegameclient.objects.eItems.Seal_of_the_Aspirant:
                    case com.company.assembleegameclient.objects.eItems.Seal_of_the_Divine:
                    {
                        loc21 = 3500 * loc22 - 200;
                        break;
                    }
                    case com.company.assembleegameclient.objects.eItems.Tome_of_Renewing:
                    case com.company.assembleegameclient.objects.eItems.Tome_of_Divine_Favor:
                    case com.company.assembleegameclient.objects.eItems.Tome_of_Holy_Guidance:
                    case com.company.assembleegameclient.objects.eItems.Tome_of_Purification:
                    case com.company.assembleegameclient.objects.eItems.Nativity_Tome:
                    case com.company.assembleegameclient.objects.eItems.Tome_of_Holy_Protection:
                    case com.company.assembleegameclient.objects.eItems.Tome_of_Frigid_Protection:
                    case com.company.assembleegameclient.objects.eItems.Tome_of_Rejuvenation:
<<<<<<< HEAD
                    case com.company.assembleegameclient.objects.eItems.Tome_of_Pain:
=======
>>>>>>> 0b99d611ef06705c12b96f965777905f657384b9
                    {
                        loc21 = 500;
                        break;
                    }
                }
                if (loc21 > 0)
                {
                    this.handleAutoH(loc21);
                }
            }
        }
        if (this.tierBoost && !isPaused())
        {
            this.tierBoost = this.tierBoost - arg2;
            if (this.tierBoost < 0)
            {
                this.tierBoost = 0;
            }
        }
        if (this.dropBoost && !isPaused())
        {
            this.dropBoost = this.dropBoost - arg2;
            if (this.dropBoost < 0)
            {
                this.dropBoost = 0;
            }
        }
        if (this.xpTimer && !isPaused())
        {
            this.xpTimer = this.xpTimer - arg2;
            if (this.xpTimer < 0)
            {
                this.xpTimer = 0;
            }
        }
        if (isHealing() && !isPaused())
        {
            if (!com.company.assembleegameclient.parameters.Parameters.data_.AntiLag && this.healingEffect_ == null || this.healingEffect_ == null && !com.company.assembleegameclient.parameters.Parameters.data_.noParticlesMaster)
            {
                this.healingEffect_ = new com.company.assembleegameclient.objects.particles.HealingEffect(this);
                map_.addObj(this.healingEffect_, x_, y_);
            }
        }
        else if (this.healingEffect_ != null)
        {
            map_.removeObj(this.healingEffect_.objectId_);
            this.healingEffect_ = null;
        }
        if (map_.player_ == this && isPaused())
        {
            return true;
        }
        if (this.relMoveVec_ == null)
        {
            if (!super.update(arg1, arg2))
            {
                return false;
            }
        }
        else
        {
            loc3 = com.company.assembleegameclient.parameters.Parameters.data_.cameraAngle;
            if (this.rotate_ != 0)
            {
                loc3 = loc3 + arg2 * com.company.assembleegameclient.parameters.Parameters.PLAYER_ROTATE_SPEED * this.rotate_;
                com.company.assembleegameclient.parameters.Parameters.data_.cameraAngle = loc3;
            }
            loc4 = this.getMoveSpeed();
            if (map_.gs_.gsc_.record != 2)
            {
                if (this.followTarget == null)
                {
                    if (!(this.relMoveVec_.x == 0) || !(this.relMoveVec_.y == 0))
                    {
                        loc5 = Math.atan2(this.relMoveVec_.y, this.relMoveVec_.x);
                        if (square_.props_.slideAmount_ > 0 && com.company.assembleegameclient.parameters.Parameters.data_.slideOnIce)
                        {
                            (loc6 = new flash.geom.Vector3D()).x = loc4 * Math.cos(loc3 + loc5);
                            loc6.y = loc4 * Math.sin(loc3 + loc5);
                            loc6.z = 0;
                            loc7 = loc6.length;
                            loc6.scaleBy(-1 * (square_.props_.slideAmount_ - 1));
                            moveVec_.scaleBy(square_.props_.slideAmount_);
                            if (moveVec_.length < loc7)
                            {
                                moveVec_ = moveVec_.add(loc6);
                            }
                        }
                        else
                        {
                            moveVec_.x = loc4 * Math.cos(loc3 + loc5);
                            moveVec_.y = loc4 * Math.sin(loc3 + loc5);
                        }
                    }
                    else if (moveVec_.length > 0.00012 && square_.props_.slideAmount_ > 0 && com.company.assembleegameclient.parameters.Parameters.data_.slideOnIce)
                    {
                        moveVec_.scaleBy(square_.props_.slideAmount_);
                    }
                    else
                    {
                        moveVec_.x = 0;
                        moveVec_.y = 0;
                    }
                }
                else if ((loc5 = (this.followTarget.y_ - y_) * (this.followTarget.y_ - y_) + (this.followTarget.x_ - x_) * (this.followTarget.x_ - x_)) < 0.1)
                {
                    moveVec_.x = 0;
                    moveVec_.y = 0;
                }
                else
                {
                    if (this.lastteleport <= flash.utils.getTimer())
                    {
                        loc1.teleport(this.followTarget.name_);
                        this.lastteleport = flash.utils.getTimer() + MS_BETWEEN_TELEPORT;
                    }
                    loc5 = Math.atan2(this.followTarget.y_ - y_, this.followTarget.x_ - x_);
                    moveVec_.x = loc4 * Math.cos(loc5);
                    moveVec_.y = loc4 * Math.sin(loc5);
                }
            }
            else
            {
                if ((loc5 = ((loc24 = (loc23 = map_.gs_.gsc_.recorded)[this.recordPointer]).y - y_) * (loc24.y - y_) + (loc24.x - x_) * (loc24.x - x_)) < 0.1)
                {
                    loc28 = ((loc27 = this).recordPointer + 1);
                    loc27.recordPointer = loc28;
                    if (this.recordPointer >= loc23.length)
                    {
                        this.recordPointer = 0;
                    }
                    loc24 = loc23[this.recordPointer];
                }
                loc5 = Math.atan2(loc24.y - y_, loc24.x - x_);
                moveVec_.x = loc4 * Math.cos(loc5);
                moveVec_.y = loc4 * Math.sin(loc5);
            }
            if (!(square_ == null) && square_.props_.push_)
            {
                if (!com.company.assembleegameclient.parameters.Parameters.data_.SWNoTileMove)
                {
                    moveVec_.x = moveVec_.x - square_.props_.animate_.dx_ / 1000;
                    moveVec_.y = moveVec_.y - square_.props_.animate_.dy_ / 1000;
                }
            }
            this.walkTo(x_ + arg2 * moveVec_.x, y_ + arg2 * moveVec_.y);
        }
        if (map_.player_ == this && square_.props_.maxDamage_ > 0 && square_.lastDamage_ + 500 < arg1 && !isInvincible() && (square_.obj_ == null || !square_.obj_.props_.protectFromGroundDamage_))
        {
            loc8 = map_.gs_.gsc_.getNextDamage(square_.props_.minDamage_, square_.props_.maxDamage_);
            (loc9 = new Vector.<uint>()).push(com.company.assembleegameclient.util.ConditionEffect.GROUND_DAMAGE);
            this.damage(true, loc8, loc9, hp_ < loc8, null);
            map_.gs_.gsc_.groundDamage(arg1, x_, y_);
            square_.lastDamage_ = arg1;
        }
        if (com.company.assembleegameclient.parameters.Parameters.data_.autoRecon)
        {
            if (this.lastreconnect <= flash.utils.getTimer())
            {
                if (map_.player_ == this && map_.name_ == "Nexus")
                {
                    if ((loc2 = int(this.chp / this.maxHP_ * 100)) > 75)
                    {
                        if (reconRealm == null)
                        {
                            (loc25 = new kabam.rotmg.servers.api.Server()).setName(com.company.assembleegameclient.parameters.Parameters.data_.servName);
                            loc25.setAddress(com.company.assembleegameclient.parameters.Parameters.data_.servAddr);
                            loc25.setPort(2050);
                            loc26 = new com.company.assembleegameclient.game.events.ReconnectEvent(loc25, com.company.assembleegameclient.parameters.Parameters.data_.reconGID, false, map_.gs_.gsc_.charId_, com.company.assembleegameclient.parameters.Parameters.data_.reconTime, com.company.assembleegameclient.parameters.Parameters.data_.reconKey, false);
                            map_.gs_.dispatchEvent(loc26);
                        }
                        else
                        {
                            reconRealm.charId_ = map_.gs_.gsc_.charId_;
                            map_.gs_.dispatchEvent(reconRealm);
                        }
                        this.lastreconnect = flash.utils.getTimer() + 2000;
                    }
                }
            }
        }
        return true;
    }

    public function onMove():void
    {
        if (map_ == null)
        {
            return;
        }
        var _local_1:Square = map_.getSquare(x_, y_);
        if (_local_1.props_.sinking_)
        {
            sinkLevel_ = Math.min((sinkLevel_ + 1), Parameters.MAX_SINK_LEVEL);
            this.moveMultiplier_ = (0.1 + ((1 - (sinkLevel_ / Parameters.MAX_SINK_LEVEL)) * (_local_1.props_.speed_ - 0.1)));
        }
        else
        {
            sinkLevel_ = 0;
            this.moveMultiplier_ = _local_1.props_.speed_;
        }
    }

    override protected function makeNameBitmapData():BitmapData
    {
        var _local_1:StringBuilder = new StaticStringBuilder(name_);
        var _local_2:BitmapTextFactory = StaticInjectorContext.getInjector().getInstance(BitmapTextFactory);
        var _local_3:BitmapData = _local_2.make(_local_1, 16, this.getNameColor(), true, NAME_OFFSET_MATRIX, true);
        _local_3.draw(FameUtil.numStarsToIcon(this.numStars_), RANK_OFFSET_MATRIX);
        return (_local_3);
    }

    private function getNameColor():uint
    {
        if (this.isFellowGuild_)
        {
            return (Parameters.FELLOW_GUILD_COLOR);
        }
        if (((Parameters.data_.lockHighlight) && (this.starred_)))
        {
            return (4240365);
        }
        if (this.nameChosen_)
        {
            return (Parameters.NAME_CHOSEN_COLOR);
        }
        return (0xFFFFFF);
    }

    protected function drawBreathBar(_arg_1:Vector.<IGraphicsData>, _arg_2:int):void
    {
        var _local_3:Number;
        var _local_4:Number;
        if (this.breathPath_ == null)
        {
            this.breathBackFill_ = new GraphicsSolidFill();
            this.breathBackPath_ = new GraphicsPath(GraphicsUtil.QUAD_COMMANDS, new Vector.<Number>());
            this.breathFill_ = new GraphicsSolidFill(2542335);
            this.breathPath_ = new GraphicsPath(GraphicsUtil.QUAD_COMMANDS, new Vector.<Number>());
        }
        if (this.breath_ <= Parameters.BREATH_THRESH)
        {
            _local_3 = ((Parameters.BREATH_THRESH - this.breath_) / Parameters.BREATH_THRESH);
            this.breathBackFill_.color = MoreColorUtil.lerpColor(0x545454, 0xFF0000, (Math.abs(Math.sin((_arg_2 / 300))) * _local_3));
        }
        else
        {
            this.breathBackFill_.color = 0x545454;
        }
        var _local_5:int = 20;
        var _local_6:int = 8;
        var _local_7:int = 6;
        var _local_8:Vector.<Number> = (this.breathBackPath_.data as Vector.<Number>);
        _local_8.length = 0;
        _local_8.push((posS_[0] - _local_5), (posS_[1] + _local_6), (posS_[0] + _local_5), (posS_[1] + _local_6), (posS_[0] + _local_5), ((posS_[1] + _local_6) + _local_7), (posS_[0] - _local_5), ((posS_[1] + _local_6) + _local_7));
        _arg_1.push(this.breathBackFill_);
        _arg_1.push(this.breathBackPath_);
        _arg_1.push(GraphicsUtil.END_FILL);
        if (this.breath_ > 0)
        {
            _local_4 = (((this.breath_ / 100) * 2) * _local_5);
            this.breathPath_.data.length = 0;
            _local_8 = (this.breathPath_.data as Vector.<Number>);
            _local_8.length = 0;
            _local_8.push((posS_[0] - _local_5), (posS_[1] + _local_6), ((posS_[0] - _local_5) + _local_4), (posS_[1] + _local_6), ((posS_[0] - _local_5) + _local_4), ((posS_[1] + _local_6) + _local_7), (posS_[0] - _local_5), ((posS_[1] + _local_6) + _local_7));
            _arg_1.push(this.breathFill_);
            _arg_1.push(this.breathPath_);
            _arg_1.push(GraphicsUtil.END_FILL);
        }
        GraphicsFillExtra.setSoftwareDrawSolid(this.breathFill_, true);
        GraphicsFillExtra.setSoftwareDrawSolid(this.breathBackFill_, true);
    }

    override public function draw(_arg_1:Vector.<IGraphicsData>, _arg_2:Camera, _arg_3:int):void {
        if (!Options.hidden && (Parameters.data_.hideLockList || Parameters.lowCPUMode))
        {
            if (this != map_.player_)
            {
                if (!this.starred_)
                {
                    return;
                }
            }
        }
        super.draw(_arg_1, _arg_2, _arg_3);
        if (this != map_.player_) {
            if (!Parameters.screenShotMode_)
            {
                drawName(_arg_1, _arg_2, false);
            }
        } else {
            if (this.breath_ >= 0)
            {
                this.drawBreathBar(_arg_1, _arg_3);
            }
        }
    }

    private function getMoveSpeed():Number
    {
        if (isSlowed())
        {
            return (MIN_MOVE_SPEED * this.moveMultiplier_);
        }
        var _local_1:Number = (MIN_MOVE_SPEED + ((this.speed_ / 75) * (MAX_MOVE_SPEED - MIN_MOVE_SPEED)));
        if (((!(Parameters.data_.speedy)) && ((isSpeedy()) || (isNinjaSpeedy()))))
        {
            _local_1 = (_local_1 * 1.5);
        }
        return (_local_1 * this.moveMultiplier_);
    }

    public function attackFrequency():Number
    {
        if (isDazed())
        {
            return (MIN_ATTACK_FREQ);
        }
        var _local_1:Number = (MIN_ATTACK_FREQ + ((this.dexterity_ / 75) * (MAX_ATTACK_FREQ - MIN_ATTACK_FREQ)));
        if (isBerserk())
        {
            _local_1 = (_local_1 * 1.5);
        }
        return (_local_1);
    }

    private function attackMultiplier():Number
    {
        if (isWeak())
        {
            return (MIN_ATTACK_MULT);
        }
        var _local_1:Number = (MIN_ATTACK_MULT + ((this.attack_ / 75) * (MAX_ATTACK_MULT - MIN_ATTACK_MULT)));
        if (isDamaging())
        {
            _local_1 = (_local_1 * 1.5);
        }
        return (_local_1);
    }

    private function makeSkinTexture():void
    {
        var _local_1:MaskedImage = this.skin.imageFromAngle(0, AnimatedChar.STAND, 0);
        animatedChar_ = this.skin;
        texture_ = _local_1.image_;
        mask_ = _local_1.mask_;
        this.isDefaultAnimatedChar = true;
    }

    private function setToRandomAnimatedCharacter():void
    {
        var _local_1:Vector.<XML> = ObjectLibrary.hexTransforms_;
        var _local_2:uint = uint(Math.floor((Math.random() * _local_1.length)));
        var _local_3:int = int(_local_1[_local_2].@type);
        var _local_4:TextureData = ObjectLibrary.typeToTextureData_[_local_3];
        texture_ = _local_4.texture_;
        mask_ = _local_4.mask_;
        animatedChar_ = _local_4.animatedChar_;
        this.isDefaultAnimatedChar = false;
    }

    override protected function getTexture(_arg_1:Camera, _arg_2:int):BitmapData
    {
        var _local_3:MaskedImage;
        var _local_4:int;
        var _local_5:Dictionary;
        var _local_6:Number;
        var _local_7:int;
        var _local_8:ColorTransform;
        var _local_9:BitmapData;
        var _local_10:Number = 0;
        var _local_11:int = AnimatedChar.STAND;
        if (((this.isShooting) || (_arg_2 < (attackStart_ + this.attackPeriod_))))
        {
            facing_ = attackAngle_;
            _local_10 = (((_arg_2 - attackStart_) % this.attackPeriod_) / this.attackPeriod_);
            _local_11 = AnimatedChar.ATTACK;
        }
        else
        {
            if (((!(moveVec_.x == 0)) || (!(moveVec_.y == 0))))
            {
                _local_4 = int((3.5 / this.getMoveSpeed()));
                if (((!(moveVec_.y == 0)) || (!(moveVec_.x == 0))))
                {
                    facing_ = Math.atan2(moveVec_.y, moveVec_.x);
                }
                _local_10 = ((_arg_2 % _local_4) / _local_4);
                _local_11 = AnimatedChar.WALK;
            }
        }
        if (this.isHexed())
        {
            ((this.isDefaultAnimatedChar) && (this.setToRandomAnimatedCharacter()));
        }
        else
        {
            if (!this.isDefaultAnimatedChar)
            {
                this.makeSkinTexture();
            }
        }
        if (_arg_1.isHallucinating_)
        {
            _local_3 = new MaskedImage(getHallucinatingTexture(), null);
        }
        else
        {
            _local_3 = animatedChar_.imageFromFacing(facing_, _arg_1, _local_11, _local_10);
        }
        var _local_12:int = tex1Id_;
        var _local_13:int = tex2Id_;
        if (this.nearestMerchant_)
        {
            _local_5 = texturingCache_[this.nearestMerchant_];
            if (_local_5 == null)
            {
                texturingCache_[this.nearestMerchant_] = new Dictionary();
            }
            else
            {
                _local_9 = _local_5[_local_3];
            }
            _local_12 = this.nearestMerchant_.getTex1Id(tex1Id_);
            _local_13 = this.nearestMerchant_.getTex2Id(tex2Id_);
        }
        else
        {
            _local_9 = texturingCache_[_local_3];
        }
        if (_local_9 == null)
        {
            _local_9 = TextureRedrawer.resize(_local_3.image_, _local_3.mask_, size_, false, _local_12, _local_13);
            if (this.nearestMerchant_ != null)
            {
                texturingCache_[this.nearestMerchant_][_local_3] = _local_9;
            }
            else
            {
                texturingCache_[_local_3] = _local_9;
            }
        }
        if (hp_ < (maxHP_ * 0.2))
        {
            _local_6 = (int((Math.abs(Math.sin((_arg_2 / 200))) * 10)) / 10);
            _local_7 = 128;
            _local_8 = new ColorTransform(1, 1, 1, 1, (_local_6 * _local_7), (-(_local_6) * _local_7), (-(_local_6) * _local_7));
            _local_9 = CachingColorTransformer.transformBitmapData(_local_9, _local_8);
        }
        var _local_14:BitmapData = texturingCache_[_local_9];
        if (_local_14 == null)
        {
            _local_14 = GlowRedrawer.outlineGlow(_local_9, ((this.legendaryRank_ == -1) ? 0 : 0xFF0000));
            texturingCache_[_local_9] = _local_14;
        }
        if ((((isPaused()) || (isStasis())) || (isPetrified())))
        {
            _local_14 = CachingColorTransformer.filterBitmapData(_local_14, PAUSED_FILTER);
        }
        else
        {
            if (isInvisible())
            {
                _local_14 = CachingColorTransformer.alphaBitmapData(_local_14, 0.4);
            } else {
                if (!Options.hidden && Parameters.data_.alphaOnOthers && this.objectId_ != map_.player_.objectId_ && !this.starred_) {
                    _local_14 = CachingColorTransformer.alphaBitmapData(_local_14, Parameters.data_.alphaMan);
                }
            }
        }
        return (_local_14);
    }

    override public function getPortrait():BitmapData
    {
        var _local_1:MaskedImage;
        var _local_2:int;
        if (portrait_ == null)
        {
            _local_1 = animatedChar_.imageFromDir(AnimatedChar.RIGHT, AnimatedChar.STAND, 0);
            _local_2 = int(((4 / _local_1.image_.width) * 100));
            portrait_ = TextureRedrawer.resize(_local_1.image_, _local_1.mask_, _local_2, true, tex1Id_, tex2Id_);
            portrait_ = GlowRedrawer.outlineGlow(portrait_, 0);
        }
        return (portrait_);
    }

    public function useAltWeapon(_arg_1:Number, _arg_2:Number, _arg_3:int, _arg_4:int=0):Boolean
    {
        var _local_5:XML;
        var _local_6:int;
        var _local_7:Number;
        var _local_8:int;
        var _local_9:int;
        var _local_10:Point;
        var _local_11:Number;
        if (((map_ == null) || (isPaused()) || (Parameters.data_.blockAbil)))
        {
            return (false);
        }
        var _local_12:int = equipment_[1];
        if (_local_12 == -1)
        {
            return (false);
        }
        var _local_13:XML = ObjectLibrary.xmlLibrary_[_local_12];
        if (int(_local_13.MpCost) > this.mp_)
        {
            return (false);
        }
        if (Parameters.data_.inaccurate)
        {
            _local_10 = this.pSTopW(_arg_1, _arg_2);
        }
        else
        {
            _local_10 = this.sToW(_arg_1, _arg_2);
        }
        if (_local_10 == null)
        {
            SoundEffectLibrary.play("error");
            return (false);
        }
        if (isSilenced())
        {
            SoundEffectLibrary.play("error");
            return (false);
        }
        for each (_local_5 in _local_13.Activate)
        {
            if (((_local_5.toString() == ActivationType.TELEPORT) && (!(Parameters.data_.spellVoid))))
            {
                if (!this.isValidPosition(_local_10.x, _local_10.y))
                {
                    SoundEffectLibrary.play("error");
                    return (false);
                }
            }
        }
        _local_6 = getTimer();
        if (_arg_3 == UseType.START_USE)
        {
            if (_local_6 < this.nextAltAttack_)
            {
                SoundEffectLibrary.play("error");
                return (false);
            }
            if (_arg_4 > 0)
            {
                this.nextAutoAbil = (getTimer() + _arg_4);
            }
            _local_9 = 500;
            if (_local_13.hasOwnProperty("Cooldown"))
            {
                _local_9 = (Number(_local_13.Cooldown) * 1000);
            }
            this.nextAltAttack_ = (_local_6 + _local_9);
            this.lastAltAttack_ = _local_6;
            map_.gs_.gsc_.useItem(_local_6, objectId_, 1, _local_12, _local_10.x, _local_10.y, _arg_3);
            if (_local_13.Activate == ActivationType.SHOOT)
            {
                _local_7 = Math.atan2(_arg_2, _arg_1);
                this.doShoot(_local_6, _local_12, _local_13, (Parameters.data_.cameraAngle + _local_7), false);
            }
            if (Parameters.data_.abilTimer)
            {
                _local_11 = (1 + (this.wisdom_ / 150));
                switch (equipment_[1])
                {
                    case 2650:
                    case 8610:
                    case 2785:
                    case 2855:
                    case 8333:
                        this.startTimer(11);
                        break;
                    case 3080:
                        this.startTimer(9);
                        break;
                    case 2857:
                    case 2667:
                    case 8335:
                    case 2225:
                        this.startTimer(12);
                        break;
                    case 3078:
                        this.startTimer(int((10 * _local_11)));
                        break;
                    case 2854:
                    case 2645:
                    case 8344:
                    case 3102:
                    case 5854:
                        this.startTimer(int((8 * _local_11)));
                        break;
                }
            }
        }
        else
        {
            if (_local_13.hasOwnProperty("MultiPhase"))
            {
                map_.gs_.gsc_.useItem(_local_6, objectId_, 1, _local_12, _local_10.x, _local_10.y, _arg_3);
                _local_8 = int(_local_13.MpEndCost);
                if (_local_8 <= this.mp_)
                {
                    _local_7 = Math.atan2(_arg_2, _arg_1);
                    this.doShoot(_local_6, _local_12, _local_13, (Parameters.data_.cameraAngle + _local_7), false);
                }
            }
        }
        return (true);
    }

    public function useAltWeapon_(_arg_1:Number, _arg_2:Number, _arg_3:int, _arg_4:Boolean=false):Boolean
    {
        var _local_5:XML;
        var _local_6:int;
        var _local_8:int;
        var _local_9:int;
        var _local_7:Number = NaN;
        if (((map_ == null) || (isPaused())))
        {
            return (false);
        }
        var _local_10:int = equipment_[1];
        if (_local_10 == -1)
        {
            return (false);
        }
        var _local_11:XML = ObjectLibrary.xmlLibrary_[_local_10];
        if (((_local_11 == null) || (!(_local_11.hasOwnProperty("Usable")))))
        {
            return (false);
        }
        if (isSilenced())
        {
            SoundEffectLibrary.play("error");
            return (false);
        }
        var _local_12:Point = ((_arg_4) ? new Point(_arg_1, _arg_2) : this.sToW(_arg_1, _arg_2));
        if (_local_12 == null)
        {
            SoundEffectLibrary.play("error");
            return (false);
        }
        for each (_local_5 in _local_11.Activate)
        {
            if (_local_5.toString() == ActivationType.TELEPORT)
            {
                if (!this.isValidPosition(_local_12.x, _local_12.y))
                {
                    SoundEffectLibrary.play("error");
                    return (false);
                }
            }
        }
        _local_6 = getTimer();
        if (_arg_3 == UseType.START_USE)
        {
            if (_local_6 < this.nextAltAttack_)
            {
                SoundEffectLibrary.play("error");
                return (false);
            }
            _local_8 = int(_local_11.MpCost);
            if (_local_8 > this.mp_)
            {
                SoundEffectLibrary.play("no_mana");
                return (false);
            }
            _local_9 = 500;
            if (_local_11.hasOwnProperty("Cooldown"))
            {
                _local_9 = (Number(_local_11.Cooldown) * 1000);
            }
            this.nextAltAttack_ = (_local_6 + _local_9);
            map_.gs_.gsc_.useItem(_local_6, objectId_, 1, _local_10, _local_12.x, _local_12.y, _arg_3);
            if (_local_11.Activate == ActivationType.SHOOT)
            {
                _local_7 = Math.atan2(((_arg_4) ? Number((_arg_2 - this.y_)) : Number(_arg_2)), ((_arg_4) ? Number((_arg_1 - this.x_)) : Number(_arg_1)));
                this.doShoot(_local_6, _local_10, _local_11, (((_arg_4) ? 0 : Parameters.data_.cameraAngle) + _local_7), false);
                this.isShooting = false;
            }
        }
        else
        {
            if (_local_11.hasOwnProperty("MultiPhase"))
            {
                this.map_.gs_.gsc_.useItem(_local_6, objectId_, 1, _local_10, _local_12.x, _local_12.y, _arg_3);
                _local_8 = int(_local_11.MpEndCost);
                if (_local_8 <= this.mp_)
                {
                    _local_7 = Math.atan2(((_arg_4) ? Number((_arg_2 - this.y_)) : Number(_arg_2)), ((_arg_4) ? Number((_arg_1 - this.x_)) : Number(_arg_1)));
                    this.doShoot(_local_6, _local_10, _local_11, (((_arg_4) ? 0 : Parameters.data_.cameraAngle) + _local_7), false);
                    this.isShooting = false;
                }
            }
        }
        return (true);
    }

    public function attemptAttackAngle(_arg_1:Number):void
    {
        this.aim_(_arg_1);
    }

    public function autoAim_(_arg_1:Vector3D, _arg_2:Vector3D, _arg_3:ProjectileProperties):Vector3D
    {
        var _local_4:Vector3D;
        var _local_5:GameObject;
        var _local_6:Vector3D;
        var _local_7:Number;
        var _local_8:Number;
        var _local_9:int;
        var _local_10:Boolean;
        var _local_11:int;
        var _local_12:Boolean;
        var _local_13:* = undefined;
        var _local_14:int = Parameters.data_.aimMode;
        var _local_15:Number = (_arg_3.speed_ / 10000);
        var _local_16:Number = ((_local_15 * _arg_3.lifetime_) + ((Parameters.data_.AAAddOne) ? 1 : 0));
        var _local_17:Number = 0;
        var _local_18:Number = int.MAX_VALUE;
        var _local_19:Number = int.MAX_VALUE;
        aimAssistTarget = null;
        for each (_local_5 in map_.goDict_)
        {
            if (_local_5.props_.isEnemy_)
            {
                _local_10 = false;
                for each (_local_11 in Parameters.data_.AAException)
                {
                    if (_local_11 == _local_5.props_.type_)
                    {
                        _local_10 = true;
                        break;
                    }
                }
                if ((((!(Parameters.data_.tombHack)) && (_local_5.props_.type_ >= 3366)) && (_local_5.props_.type_ <= 3368)))
                {
                    _local_10 = false;
                }
                if (((_local_10) || (_local_5 is Character)))
                {
                    if (!((!(_local_10)) && (((_local_5.isStasis()) || (_local_5.isInvulnerable())) || (_local_5.isInvincible()))))
                    {
                        _local_12 = false;
                        for each (_local_11 in Parameters.data_.AAIgnore)
                        {
                            if (_local_11 == _local_5.props_.type_)
                            {
                                _local_12 = true;
                                break;
                            }
                        }
                        if (!_local_12)
                        {
                            if ((((_local_5.jittery) || (!(Parameters.data_.AATargetLead))) || (_local_5.objectType_ == 3334)))
                            {
                                _local_6 = new Vector3D(_local_5.x_, _local_5.y_);
                            }
                            else
                            {
                                _local_6 = this.leadPos(_arg_1, new Vector3D(_local_5.x_, _local_5.y_), new Vector3D(_local_5.moveVec_.x, _local_5.moveVec_.y), _local_15);
                            }
                            if (_local_6 != null)
                            {
                                _local_13 = this.getDist(_arg_1.x, _arg_1.y, _local_6.x, _local_6.y);
                                if (_local_13 <= _local_16)
                                {
                                    if (_local_14 == 1)
                                    {
                                        _local_8 = _local_5.maxHP_;
                                        switch (_local_5.objectType_)
                                        {
                                            case 1625:
                                                _local_8 = 3000;
                                            case 3369:
                                                _local_8 = 7500;
                                            case 3371:
                                                _local_8 = 8000;
                                        }
                                        for each (_local_9 in Parameters.data_.AAPriority)
                                        {
                                            if (_local_9 == _local_5.objectType_)
                                            {
                                                _local_8 = int.MAX_VALUE;
                                            }
                                        }
                                        if (((Parameters.data_.tombHack) && (((_local_5.objectType_ >= 3366) && (_local_5.objectType_ <= 3368)) || ((_local_5.objectType_ >= 32692) && (_local_5.objectType_ <= 32694)))))
                                        {
                                            if (((!(_local_5.objectType_ == Parameters.data_.curBoss)) && (!(_local_5.objectType_ == (Parameters.data_.curBoss + 29326))))) continue;
                                        }
                                        if (_local_8 >= _local_17)
                                        {
                                            if (_local_8 == _local_17)
                                            {
                                                if (_local_5.hp_ > _local_18) continue;
                                                if (((_local_5.hp_ == _local_18) && (_local_13 > _local_19))) continue;
                                                _local_18 = _local_5.hp_;
                                                _local_4 = _local_6;
                                                _local_19 = _local_13;
                                                aimAssistTarget = _local_5;
                                            }
                                            else
                                            {
                                                _local_4 = _local_6;
                                                _local_18 = _local_5.hp_;
                                                _local_17 = _local_8;
                                                _local_19 = _local_13;
                                                aimAssistTarget = _local_5;
                                            }
                                        }
                                    }
                                    else
                                    {
                                        if (_local_14 == 2)
                                        {
                                            if (_local_13 < _local_19)
                                            {
                                                _local_4 = _local_6;
                                                _local_18 = _local_5.hp_;
                                                _local_17 = _local_5.maxHP_;
                                                _local_19 = _local_13;
                                                aimAssistTarget = _local_5;
                                            }
                                        }
                                        else
                                        {
                                            _local_7 = Parameters.data_.AABoundingDist;
                                            _local_13 = this.getDist(_arg_2.x, _arg_2.y, _local_5.x_, _local_5.y_);
                                            if (((Math.abs((_arg_2.x - _local_6.x)) <= _local_7) && (Math.abs((_arg_2.y - _local_6.y)) <= _local_7)))
                                            {
                                                if (_local_13 <= _local_19)
                                                {
                                                    _local_4 = _local_6;
                                                    _local_18 = _local_5.hp_;
                                                    _local_17 = _local_5.maxHP_;
                                                    _local_19 = _local_13;
                                                    aimAssistTarget = _local_5;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return (_local_4);
    }

    public function getDist(_arg_1:Number, _arg_2:Number, _arg_3:Number, _arg_4:Number):Number
    {
        var _local_5:* = (_arg_1 - _arg_3);
        var _local_6:* = (_arg_2 - _arg_4);
        return (Math.sqrt(((_local_6 * _local_6) + (_local_5 * _local_5))));
    }

    public function leadPos(_arg_1:Vector3D, _arg_2:Vector3D, _arg_3:Vector3D, _arg_4:Number):Vector3D
    {
        var _local_5:Vector3D = _arg_2.subtract(_arg_1);
        var _local_6:* = (_arg_3.dotProduct(_arg_3) - (_arg_4 * _arg_4));
        var _local_7:* = (2 * _local_5.dotProduct(_arg_3));
        var _local_8:* = _local_5.dotProduct(_local_5);
        var _local_9:* = ((-(_local_7) + Math.sqrt(((_local_7 * _local_7) - ((4 * _local_6) * _local_8)))) / (2 * _local_6));
        var _local_10:* = ((-(_local_7) - Math.sqrt(((_local_7 * _local_7) - ((4 * _local_6) * _local_8)))) / (2 * _local_6));
        if (((_local_9 < _local_10) && (_local_9 >= 0)))
        {
            _arg_3.scaleBy(_local_9);
        }
        else
        {
            if (_local_10 >= 0)
            {
                _arg_3.scaleBy(_local_10);
            }
            else
            {
                return (null);
            }
        }
        return (_arg_2.add(_arg_3));
    }

    public function getAimAngle():Number
    {
        var _local_1:Vector3D;
        var _local_2:Vector3D;
        var _local_3:Point;
        var _local_4:ProjectileProperties;
        var _local_5:Vector3D;
        _local_3 = this.sToW(map_.mouseX, map_.mouseY);
        if (_local_3 == null)
        {
            _local_3 = new Point(x_, y_);
        }
        _local_2 = new Vector3D(_local_3.x, _local_3.y);
        _local_1 = new Vector3D(x_, y_);
        _local_4 = ObjectLibrary.propsLibrary_[equipment_[0]].projectiles_[0];
        aimAssistPoint = this.autoAim_(_local_1, _local_2, _local_4);
        if (aimAssistPoint != null)
        {
            return (Math.atan2((aimAssistPoint.y - y_), (aimAssistPoint.x - x_)));
        }
        return (Number.MAX_VALUE);
    }

    public function pSTopW(_arg_1:Number, _arg_2:Number):Point
    {
        var _local_3:Point = this.sToW(_arg_1, _arg_2);
        _local_3.x = (int(_local_3.x) + (1 / 2));
        _local_3.y = (int(_local_3.y) + (1 / 2));
        return (_local_3);
    }

    public function sToW(_arg_1:Number, _arg_2:Number):Point
    {
        var _local_3:* = Parameters.data_.cameraAngle;
        var _local_4:* = Math.cos(_local_3);
        var _local_5:* = Math.sin(_local_3);
        _arg_1 = (_arg_1 / 50.5);
        _arg_2 = (_arg_2 / 50.5);
        var _local_6:* = ((_arg_1 * _local_4) - (_arg_2 * _local_5));
        var _local_7:* = ((_arg_1 * _local_5) + (_arg_2 * _local_4));
        return (new Point((map_.player_.x_ + _local_6), (map_.player_.y_ + _local_7)));
    }

    public function aim_(_arg_1:Number):void
    {
        var _local_2:Number = NaN;
        var _local_3:Boolean = map_.gs_.mui_.mouseDown_;
        var _local_4:Boolean = map_.gs_.mui_.autofire_;
        var _local_5:Boolean = Parameters.data_.AAOn;
        if (((_local_5) && (!(_local_3))))
        {
            _local_2 = this.getAimAngle();
            if (((!(_local_2 == Number.MAX_VALUE)) && (!(isUnstable()))))
            {
                this.shoot(_local_2);
                this.isShooting = false;
                return;
            }
            if (!_local_4)
            {
                return;
            }
        }
        this.shoot((Parameters.data_.cameraAngle + _arg_1));
    }

    public function hasWeapon():Boolean
    {
        var _local_1:int = equipment_[0];
        if (_local_1 == -1)
        {
            return (false);
        }
        return (true);
    }

    override public function setAttack(_arg_1:int, _arg_2:Number):void
    {
        var _local_3:XML = ObjectLibrary.xmlLibrary_[_arg_1];
        if (((_local_3 == null) || (!(_local_3.hasOwnProperty("RateOfFire")))))
        {
            return;
        }
        var _local_4:Number = Number(_local_3.RateOfFire);
        this.attackPeriod_ = ((1 / this.attackFrequency()) * (1 / _local_4));
        super.setAttack(_arg_1, _arg_2);
    }

    private function shoot(_arg_1:Number):void
    {
        if (((((map_ == null) || (isStunned())) || (isPaused())) || (isPetrified())))
        {
            return;
        }
        var _local_2:int = equipment_[0];
        if (_local_2 == -1)
        {
            return;
        }
        var _local_3:XML = ObjectLibrary.xmlLibrary_[_local_2];
        var _local_4:int = getTimer();
        var _local_5:Number = Number(_local_3.RateOfFire);
        this.attackPeriod_ = ((1 / this.attackFrequency()) * (1 / _local_5));
        if (_local_4 < (attackStart_ + this.attackPeriod_))
        {
            return;
        }
        attackAngle_ = _arg_1;
        attackStart_ = _local_4;
        this.doShoot(attackStart_, _local_2, _local_3, attackAngle_, true);
    }

    public function doShoot(arg1:int, arg2:int, arg3:XML, arg4:Number, arg5:Boolean):void
    {
        var loc1:*=0;
        var loc2:*=null;
        var loc3:*=0;
        var loc4:*=0;
        var loc5:*=NaN;
        var loc6:*=0;
        var loc7:*=0;
        var loc8:*=arg3.hasOwnProperty("NumProjectiles") ? int(arg3.NumProjectiles) : 1;
        var loc9:*=(arg3.hasOwnProperty("ArcGap") ? Number(arg3.ArcGap) : 11.25) * 0.0174532925199;
        var loc10:*=loc9 * (loc8 - 1);
        var loc11:*=arg4 - loc10 * 0.5;
        this.isShooting = arg5;
        if (arg2 == 580 && com.company.assembleegameclient.parameters.Parameters.data_.cultistStaffDisable)
        {
            loc11 = loc11 + Math.PI;
        }
        while (loc7 < loc8)
        {
            loc1 = getBulletId();
            if (arg2 == 8608 && com.company.assembleegameclient.parameters.Parameters.data_.etheriteDisable)
            {
                loc11 = loc11 + (loc1 % 2 == 0 ? -0.0436332312999 : 0.0436332312999);
            }
            else if (arg2 == 596 && com.company.assembleegameclient.parameters.Parameters.data_.offsetColossus)
            {
                loc11 = loc11 + (loc1 % 2 == 0 ? -com.company.assembleegameclient.parameters.Parameters.data_.coloOffset : com.company.assembleegameclient.parameters.Parameters.data_.coloOffset);
            }
            else if (arg2 == 588 && com.company.assembleegameclient.parameters.Parameters.data_.voidbowDisable)
            {
                loc11 = loc11 + (loc1 % 2 == 0 ? -0.06 : 0.06);
            }
            else if (arg2 == 3113 && com.company.assembleegameclient.parameters.Parameters.data_.spiritdaggerDisable)
            {
                loc11 = loc11 + (loc1 % 2 == 0 ? -0.0433332312999 : 0.0423332312999);
            }
            loc2 = com.company.assembleegameclient.util.FreeList.newObject(com.company.assembleegameclient.objects.Projectile) as com.company.assembleegameclient.objects.Projectile;
            if (arg5 && !(this.projectileIdSetOverrideNew == ""))
            {
                loc2.reset(arg2, 0, objectId_, loc1, loc11, arg1, this.projectileIdSetOverrideNew, this.projectileIdSetOverrideOld);
            }
            else
            {
                loc2.reset(arg2, 0, objectId_, loc1, loc11, arg1);
            }
            loc3 = int(loc2.projProps_.minDamage_);
            loc4 = int(loc2.projProps_.maxDamage_);
            loc5 = arg5 ? this.attackMultiplier() : 1;
            loc6 = map_.gs_.gsc_.getNextDamage(loc3, loc4) * loc5;
            if (arg1 > map_.gs_.moveRecords_.lastClearTime_ + 600)
            {
                loc6 = 0;
            }
            loc2.setDamage(loc6);
            if (loc7 == 0 && !(loc2.sound_ == null))
            {
                com.company.assembleegameclient.sound.SoundEffectLibrary.play(loc2.sound_, 0.75, false);
            }
            map_.addObj(loc2, x_ + Math.cos(arg4) * 0.3, y_ + Math.sin(arg4) * 0.3);
            map_.gs_.gsc_.playerShoot(arg1, loc2);
            loc11 = loc11 + loc9;
            ++loc7;
        }
    }

    public function isHexed():Boolean
    {
        return (!((condition_[ConditionEffect.CE_FIRST_BATCH] & ConditionEffect.HEXED_BIT) == 0));
    }

    public function isInventoryFull():Boolean
    {
        if (equipment_ == null)
        {
            return (false);
        }
        var _local_1:int = equipment_.length;
        var _local_2:uint = 4;
        while (_local_2 < _local_1)
        {
            if (equipment_[_local_2] <= 0)
            {
                return (false);
            }
            _local_2++;
        }
        return (true);
    }

    public function nextAvailableInventorySlot():int
    {
        var _local_1:int = ((this.hasBackpack_) ? equipment_.length : (equipment_.length - GeneralConstants.NUM_INVENTORY_SLOTS));
        var _local_2:uint = 4;
        while (_local_2 < _local_1)
        {
            if (equipment_[_local_2] <= 0)
            {
                return (_local_2);
            }
            _local_2++;
        }
        return (-1);
    }

    public function getSlotwithItem(_arg_1:int):int
    {
        var _local_2:int = ((this.hasBackpack_) ? equipment_.length : (equipment_.length - GeneralConstants.NUM_INVENTORY_SLOTS));
        var _local_3:uint = 4;
        while (_local_3 < _local_2)
        {
            if (equipment_[_local_3] == _arg_1)
            {
                return (_local_3);
            }
            _local_3++;
        }
        return (-1);
    }

    public function getItemwithSlot(_arg_1:int):int
    {
        var _local_2:int = ((this.hasBackpack_) ? equipment_.length : (equipment_.length - GeneralConstants.NUM_INVENTORY_SLOTS));
        var _local_3:uint = 4;
        while (_local_3 < _local_2)
        {
            if (equipment_[_local_3] == _arg_1)
            {
                return (_local_3);
            }
            _local_3++;
        }
        return (-1);
    }

    public function numberOfAvailableSlots():int
    {
        var _local_1:int;
        var _local_2:int = ((this.hasBackpack_) ? equipment_.length : (equipment_.length - GeneralConstants.NUM_INVENTORY_SLOTS));
        var _local_3:uint = 4;
        while (_local_3 < _local_2)
        {
            if (equipment_[_local_3] <= 0)
            {
                _local_1++;
            }
            _local_3++;
        }
        return (_local_1);
    }

    public function swapInventoryIndex(_arg_1:int):int
    {
        var _local_2:int;
        var _local_3:int;
        if (!this.hasBackpack_)
        {
            return (-1);
        }
        if (_arg_1 > 11)
        {
            _local_2 = GeneralConstants.NUM_EQUIPMENT_SLOTS;
            _local_3 = (GeneralConstants.NUM_EQUIPMENT_SLOTS + GeneralConstants.NUM_INVENTORY_SLOTS);
        }
        else
        {
            _local_2 = (GeneralConstants.NUM_EQUIPMENT_SLOTS + GeneralConstants.NUM_INVENTORY_SLOTS);
            _local_3 = equipment_.length;
        }
        var _local_4:uint = _local_2;
        while (_local_4 < _local_3)
        {
            if (equipment_[_local_4] <= 0)
            {
                return (_local_4);
            }
            _local_4++;
        }
        return (-1);
    }

    public function getPotionCount(_arg_1:int):int
    {
        switch (_arg_1)
        {
            case PotionInventoryModel.HEALTH_POTION_ID:
                return (this.healthPotionCount_);
            case PotionInventoryModel.MAGIC_POTION_ID:
                return (this.magicPotionCount_);
        }
        return (0);
    }

    public function getTex1():int
    {
        return (tex1Id_);
    }

    public function getTex2():int
    {
        return (tex2Id_);
    }

    public function handleAutoH(_arg_1:int):void
    {
        if (((this.chp / maxHP_) * 100) <= Parameters.data_.autoHealP)
        {
            if (((this.hasHealingSeal()) || (this.hasTome())))
            {
                if (!isSick())
                {
                    this.useAltWeapon(0, 0, UseType.START_USE);
                    this.autohealtimer = (getTimer() + _arg_1);
                }
            }
        }
    }

    public function handleAutoMana():void
    {
        if (((mp_ / maxMP_) * 100) <= Parameters.data_.autoMana)
        {
            if (this.potionInventoryModel.getPotionModel(PotionInventoryModel.MAGIC_POTION_ID).available)
            {
                if (((!(isQuiet())) && (!(mp_ == 0))))
                {
                    this.useBuyPotionSignal.dispatch(new UseBuyPotionVO(PotionInventoryModel.MAGIC_POTION_ID, UseBuyPotionVO.CONTEXTBUY));
                    this.lastManaUse = (getTimer() + 500);
                }
            }
        }
    }

    public function hasSeal():Boolean
    {
        var _local_1:Boolean;
        switch (this.equipment_[1])
        {
            case eItems.Seal_of_the_Initiate:
            case eItems.Seal_of_the_Pilgrim:
            case eItems.Seal_of_the_Seeker:
            case eItems.Seal_of_the_Aspirant:
            case eItems.Seal_of_the_Divine:
            case eItems.Seal_of_the_Holy_Warrior:
            case eItems.Advent_Seal:
            case eItems.Seal_of_the_Enchanted_Forest:
            case eItems.Marble_Seal:
            case eItems.Seal_of_the_Blasphemous_Prayer:
            case eItems.Seal_of_the_Blessed_Champion:
                _local_1 = true;
                break;
        }
        return (_local_1);
    }

    public function hasHealingSeal():Boolean
    {
        var _local_1:Boolean;
        switch (this.equipment_[1])
        {
            case eItems.Seal_of_the_Initiate:
            case eItems.Seal_of_the_Pilgrim:
            case eItems.Seal_of_the_Seeker:
            case eItems.Seal_of_the_Aspirant:
            case eItems.Seal_of_the_Divine:
            case eItems.Seal_of_the_Holy_Warrior:
            case eItems.Advent_Seal:
            case eItems.Seal_of_the_Blasphemous_Prayer:
            case eItems.Seal_of_the_Blessed_Champion:
                _local_1 = true;
                break;
        }
        return (_local_1);
    }

    public function hasTome():Boolean
    {
        var _local_1:Boolean;
        switch (this.equipment_[1])
        {
            case eItems.Healing_Tome:
            case eItems.Nativity_Tome:
            case eItems.pD_Tome:
            case eItems.Remedy_Tome:
            case eItems.Spirit_Salve_Tome:
            case eItems.Tome_of_Divine_Favor:
            case eItems.Tome_of_Frigid_Protection:
            case eItems.Tome_of_Holy_Guidance:
            case eItems.Tome_of_Holy_Protection:
            case eItems.Tome_of_Purification:
            case eItems.Tome_of_Rejuvenation:
            case eItems.Tome_of_Renewing:
            case eItems.Tome_of_Pain:
                _local_1 = true;
                break;
        }
        return (_local_1);
    }

    public function sbAssist(_arg_1:int, _arg_2:int):void
    {
        var _local_3:Point;
        var _local_4:GameObject;
        var _local_5:Number;
        var _local_6:GameObject;
        var _local_7:Number;
        var _local_10:XML;
        var _local_8:int = this.equipment_[1];
        if (_local_8 == -1)
        {
            return;
        }
        var _local_9:XML = ObjectLibrary.xmlLibrary_[_local_8];
        for each (_local_10 in _local_9.Activate)
        {
            if (_local_10.toString() == ActivationType.TELEPORT)
            {
                this.useAltWeapon(_arg_1, _arg_2, 1, 0);
            }
        }
        _local_3 = this.sToW(_arg_1, _arg_2);
        _local_4 = null;
        _local_5 = Number.MAX_VALUE;
        _local_6 = null;
        for each (_local_4 in map_.goDict_)
        {
            if (_local_4.props_.isEnemy_)
            {
                if ((((!(_local_4.isInvincible())) && (!(_local_4.isInvulnerable()))) && (!(_local_4.dead_))))
                {
                    _local_7 = PointUtil.distanceSquaredXY(_local_4.x_, _local_4.y_, _local_3.x, _local_3.y);
                    if (_local_7 < _local_5)
                    {
                        _local_5 = _local_7;
                        _local_6 = _local_4;
                    }
                }
            }
        }
        if (_local_5 <= 25)
        {
            this.useAltWeapon(_local_6.x_, _local_6.y_, 1, 1);
        }
        else
        {
            this.useAltWeapon(_arg_1, _arg_2, 1, 0);
        }
    }

    public function getPSpeed():Number{
        return (this.getMoveSpeed());
    }


}
}//package com.company.assembleegameclient.objects

