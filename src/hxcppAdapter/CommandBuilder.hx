package hxcppAdapter;

class CommandBuilder implements vshaxeDebug.ICommandBuilder {

    public function new() {}

    public function launch(program:String):String
        return "";

    public function frameUp():String 
        return "up";

    public function frameDown():String 
        return "down";

    public function stepIn():String 
        return "step";

    public function stepOut():String 
        return "finish";

    public function next():String 
        return "next";

    public function continueCommand():String 
        return "c";

    public function pause():String 
        return "\ny";

    public function stackTrace():String 
        return "w";

    public function addBreakpoint(path:String, line:Int):String
        return 'break $path:${line}';
    
    public function removeBreakpoint(path:String, line:Int):String
        return 'clear $path:${line}';

    public function printLocalVariables():String 
        return "variables";

    public function printFunctionArguments():String 
        return "";

    public function printGlobalVariables():String 
        return "";

    public function printObjectProperties(?objectName:String):String 
        return 'print $objectName';

    public function printMembers():String 
        return "print this";

    public function evaluate(expr:String):String
        return 'print $expr';

    public function disconnect():String
        return "exit";
}
