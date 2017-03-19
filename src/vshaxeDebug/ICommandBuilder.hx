package vshaxeDebug;

interface ICommandBuilder {

    function launch(program:String):String;
    function frameUp():String;
    function frameDown():String;
    function stepIn():String;
    function stepOut():String;
    function next():String;
    function continueCommand():String;
    function pause():String;
    function stackTrace():String;
    function addBreakpoint(path:String, line:Int):String;
    function removeBreakpoint(path:String, line:Int):String;
    function printLocalVariables():String;
    function printFunctionArguments():String;
    function printGlobalVariables():String;
    function printObjectProperties(?objectName:String):String;
    function printMembers():String;
    function evaluate(expr:String):String;
    function disconnect():String;
}