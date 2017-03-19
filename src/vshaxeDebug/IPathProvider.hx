package vshaxeDebug;

interface IPathProvider {

    function init():Void;
    function initWait(callback:Void -> Void):Void;
    function forBreakpointSetting(fileName:String):String;
    function forEditor(fileName:String):String;
}
