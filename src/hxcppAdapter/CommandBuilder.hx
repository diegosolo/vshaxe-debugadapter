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
        return "TODO";

    public function next():String 
        return "next";

    public function continueCommand():String 
        return "c";

    public function pause():String 
        return "\ny";

    public function stackTrace():String 
        return "bt";

    public function addBreakpoint(fileName:String, filePath:String, line:Int):String
        return 'break $filePath:${line}';
    
    public function removeBreakpoint(fileName:String, filePath:String, line:Int):String
        return 'clear $filePath:${line}';

    public function printLocalVariables():String 
        return "TODO";

    public function printFunctionArguments():String 
        return "TODO";

    public function printGlobalVariables():String 
        return "TODO";

    public function printObjectProperties(?objectName:String):String 
        return 'print $objectName.';

    public function printMembers():String 
        return "print this.";

    public function showFiles():String
        return "files";

    public function evaluate(expr:String):String
        return 'print $expr';

    public function disconnect():String
        return "kill\ny\nquit";
}
