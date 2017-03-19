package hxcppAdapter;

import vshaxeDebug.Types;
import protocol.debug.Types;
import haxe.ds.Option;

class Parser implements vshaxeDebug.IParser {

    var eolSign:String;
    var promptLength:Int;

    public function new(eolSign:String) {
        this.eolSign = eolSign;
        promptLength = 0;
    }

    public function parseFunctionArguments(lines:Array<String>):Array<VariableItem> {
        return [];
    }

    public function parseGlobalVariables(lines:Array<String>):Array<VariableItem> {
        return [];
    }

    public function parseLocalVariables(lines:Array<String>):Array<VariableItem> {
        return parseVariables(lines);
    }

    public function parseMembers(lines:Array<String>):Array<VariableItem> {
        return parseVariables(lines);
    }

    public function parseObjectProperties(lines:Array<String>):Array<VariableItem> {
        return parseVariables(lines);
    }

    public function parseEvaluate(lines:Array<String>):Option<VariableItem> {
        var variables:Array<VariableItem> = parseVariables(lines);
        return (variables.length > 0) ? Some(variables[0]) : None;
    }

    public function parseStackTrace(lines:Array<String>, pathProvider:String -> String):Array<StackFrame> {
        var result = [];
        var rMethod = ~/([0-9]+) : (.+) at (.*):([0-9]+).*/;
        var anonFunction = ~/#([0-9]+)\s+this = \[Function [0-9]+, name='(.*)'\]\.([a-zA-Z0-9\/\$<>]+).*\) at (.*):([0-9]+).*/;
        var globalCall = ~/([0-9]+) : (.+) at \?:([0-9]+).*/;

        /*"Thread 0 (stopped in breakpoint 1):,
        *     2 : somePack.WeirdThings.new() at somePack/WeirdThings.hx:6,
              1 : Test.main() at Test.hx:13,
              0 : hxcpp.__hxcpp_main() at ?:1";
        */
        for (l in lines) {
            if (globalCall.match(l)) {
                result.push({
                    id : Std.parseInt(globalCall.matched(1)),
                    name : globalCall.matched(2),
                    line : Std.parseInt(globalCall.matched(3)),
                    source : { path : "global", name: "global"},
                    column : 0
                });
            }
            else if (rMethod.match(l)) {
                var path:String =  rMethod.matched(3);
                var splited:Array<String> = path.split("/");
                var name = splited.pop();
                result.push({
                    id : Std.parseInt(rMethod.matched(1)),
                    name : rMethod.matched(2),
                    line : Std.parseInt(rMethod.matched(4)),
                    source : {name : name, path : pathProvider(name)},
                    column : 0
                });
            }
            else if (anonFunction.match(l)) {
                result.push({
                    id : Std.parseInt(anonFunction.matched(1)),
                    name : anonFunction.matched(2) + "." + anonFunction.matched(3),
                    line : Std.parseInt( anonFunction.matched(5)),
                    source : { name : anonFunction.matched(4), path : pathProvider(anonFunction.matched(4))},
                    column : 0
                });
            }
        }
        return result;
    }

    public function parseAddBreakpoint(lines:Array<String>):Option<BreakpointInfo> {
        var result:Option<BreakpointInfo> = None;
        var breakpointData = lines[0];
        var r = ~/Breakpoint ([0-9]+) set and enabled(.*)/;
        if (r.match(breakpointData)) {
            result = Some({
                id : Std.parseInt(r.matched(1)),
                lineInfo : None
            });
        }
        return result;
    }

    public function getLines(rawInput:String):Array<String> {
        return [for (line in rawInput.split(eolSign)) if (line != "") line];
    }

    public function getLinesExceptPrompt(rawInput:String):Array<String> {
        var withoutPrompt:String = rawInput.substring(0, rawInput.length - promptLength);
        var lines = getLines(withoutPrompt);
        return lines;
    }

    public function getTraces(rawInput:String):Array<String> {
        trace('getTraces: TODO: replace it');
        trace(rawInput);
        var result:Array<String> = [];
        var lines = getLines(rawInput);
        var traceR = ~/\[trace\](.*)/;
        for (line in lines) {
            if (traceR.match(line)) {
                result.push(line);
            }
        }
        return result;
    }

    public function isPromptMatched(rawInput:String):Bool {
        var promptR = ~/(\d+> )$/;
        var result = false;
        if (promptR.match(rawInput)) {
            var prompt:String = promptR.matched(1);
            promptLength = prompt.length;
            result = true;
        }
        return result;
    }

    public function isExitMatched(rawInput:String):Bool {
       return false;
    }

    public function isGreetingMatched(lines:Array<String>):Bool {
        var greeting = "-=- hxcpp built-in debugger";
        var firstLine = lines[0];
        var result = (firstLine != null) ? (firstLine.substr(0, greeting.length) == greeting) : false;
        return result;
    }

    public function isStopOnBreakpointMatched(rawInput:String):Bool {
        var lines = getLines(rawInput);
        var regexp = ~/Thread (\d+) stopped in (.*) at .*\/(\S+\.hx):(\d+)\./;
        for (line in lines) {
            if (regexp.match(line)) {
                return true;
            }
        }
        return false;
    }

    public function isStopOnExceptionMatched(rawInput:String):Bool {
        var lines = getLines(rawInput);
        return false;
    }

    function parseVariables(lines:Array<String>):Array<VariableItem> {
        var rVar = ~/^(.*) = (.*)$/;
        var result:Array<VariableItem> = [];

        for (line in lines) {
            if (rVar.match(line)) {
                var name = StringTools.trim(rVar.matched(1));
                var value = rVar.matched(2);
                var type = detectExpressionType(value);

                result.push({
                    name: name,
                    type: type,
                    value: value
                });
            }
        }

        return result;
    }

    function detectExpressionType(expr:String):VariableType {
        var rObjectType = ~/^\[Object (\d+),/;
        var rIntType = ~/^\d+ \(0\x\d+\)/;
        var rFloatType = ~/^\d+\.\d+$/;
        var rStringType = ~/^[\\"].*[\\"]$/;
        var rBoolType = ~/^[t|f]\S+$/;

        return if (rObjectType.match(expr)) {
            var objectId = Std.parseInt(rObjectType.matched(1));
            Object(objectId);
        }
        else if (rIntType.match(expr)) {
            Simple("Int");
        } 
        else if (rFloatType.match(expr)) {
            Simple("Float");
        }
        else if (rStringType.match(expr)) {
            Simple("String");
        }
        else if (rBoolType.match(expr)) {
            Simple("Bool");
        }
        else {
            Simple("Unknown");
        }
    }
}