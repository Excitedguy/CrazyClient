package kabam.rotmg.ui.view.components 
{
    import flash.display.*;
    import flash.events.*;
    import flash.utils.*;
    import kabam.rotmg.assets.*;
    
    public class Spinner extends flash.display.Sprite
    {
        public function Spinner()
        {
            super();
            this.secondsElapsed = 0;
            this.defaultConfig();
            this.addGraphic();
            addEventListener(flash.events.Event.ENTER_FRAME, this.onEnterFrame);
            addEventListener(flash.events.Event.REMOVED_FROM_STAGE, this.onRemoved);
            return;
        }

        internal function defaultConfig():void
        {
            this.degreesPerSecond = 50;
            return;
        }

        internal function addGraphic():void
        {
            addChild(this.graphic);
            this.graphic.x = -1 * width / 2;
            this.graphic.y = -1 * height / 2;
            return;
        }

        internal function onRemoved(arg1:flash.events.Event):void
        {
            removeEventListener(flash.events.Event.REMOVED_FROM_STAGE, this.onRemoved);
            removeEventListener(flash.events.Event.ENTER_FRAME, this.onEnterFrame);
            return;
        }

        internal function onEnterFrame(arg1:flash.events.Event):void
        {
            this.updateTimeElapsed();
            rotation = this.degreesPerSecond * this.secondsElapsed % 360;
            return;
        }

        internal function updateTimeElapsed():void
        {
            var loc1:*=flash.utils.getTimer() / 1000;
            if (this.previousSeconds) 
            {
                this.secondsElapsed = this.secondsElapsed + (loc1 - this.previousSeconds);
            }
            this.previousSeconds = loc1;
            return;
        }

        public const graphic:flash.display.DisplayObject=new kabam.rotmg.assets.EmbeddedAssets.StarburstSpinner();

        public var degreesPerSecond:Number;

        internal var secondsElapsed:Number;

        internal var previousSeconds:Number;
    }
}
