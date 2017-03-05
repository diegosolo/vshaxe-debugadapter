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
        throw "TODO: replace it";
        return parseVariables(lines);
    }

    public function parseGlobalVariables(lines:Array<String>):Array<VariableItem> {
        throw "TODO: replace it";
        return parseVariables(lines);
    }

    public function parseLocalVariables(lines:Array<String>):Array<VariableItem> {
        throw "TODO: replace it";
        return parseVariables(lines);
    }

    public function parseMembers(lines:Array<String>):Array<VariableItem> {
        throw "TODO: replace it";
        lines.shift();
        return parseVariables(lines);
    }

    public function parseObjectProperties(lines:Array<String>):Array<VariableItem> {
        throw "TODO: replace it";
        lines.shift();
        return parseVariables(lines);
    }

    public function parseEvaluate(lines:Array<String>):Option<VariableItem> {
        throw "TODO: replace it";
        var variables:Array<VariableItem> = parseVariables(lines);
        trace(variables);
        return (variables.length > 0) ? Some(variables[0]) : None;
    }

    public function parseStackTrace(lines:Array<String>, pathProvider:String -> String):Array<StackFrame> {
        throw "TODO: replace it";
        var result = [];
        var rMethod = ~/#([0-9]+)\s+this = \[Object [0-9]+, class='(.+)'\]\.(.+)\(.*\) at (.*):([0-9]+).*/;
        var anonFunction = ~/#([0-9]+)\s+this = \[Function [0-9]+, name='(.*)'\]\.([a-zA-Z0-9\/\$<>]+).*\) at (.*):([0-9]+).*/;
        var globalCall = ~/#([0-9]+)\s+(.*)\(\) at (.*):([0-9]+)/;
        for (l in lines) {
            if (rMethod.match(l)) {
                result.push({
                    id : Std.parseInt(rMethod.matched(1)),
                    name : rMethod.matched(2) + "." + rMethod.matched(3),
                    line : Std.parseInt( rMethod.matched(5)),
                    source : { name : rMethod.matched(4), path : pathProvider(rMethod.matched(4))},
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
            else if (globalCall.match(l)) {
                result.push({
                    id : Std.parseInt(globalCall.matched(1)),
                    name : globalCall.matched(2),
                    line : Std.parseInt( globalCall.matched(4)),
                    source : { path : "global", name: "global"},
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

    public function parseShowFiles(lines:Array<String>):Array<SourceInfo> {
        var result:Array<SourceInfo> = [];
        var rRow = ~/^(.)*\.hx$/;
        for (l in lines) {
            if (rRow.match(l)) {
                var splited:Array<String> = l.split("/");
                var name = splited.pop();
                var path = l;
                result.push({
                    name : name,
                    path : path
                });
            }
        }
        return result;
    }

    public function getLines(rawInput:String):Array<String> {
        return [for (line in rawInput.split(eolSign)) if (line != "") line];
    }

    public function getLinesExceptPrompt(rawInput:String):Array<String> {
        var withoutPrompt:String = rawInput.substring(0, rawInput.length - promptLength);
        return getLines(withoutPrompt);
    }

    public function getTraces(rawInput:String):Array<String> {
        throw "TODO: replace it";
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
        var promptR = ~/(\d+>)/;
        if (promptR.match(rawInput)) {
            var prompt:String = promptR.matched(1);
            promptLength = prompt.length;
        }
        return (promptR.match(rawInput));
    }

    public function isExitMatched(rawInput:String):Bool {
        throw "TODO: replace it";
        var exitR = ~/\[UnloadSWF\]/;
        return (exitR.match(rawInput));
    }

    public function isGreetingMatched(lines:Array<String>):Bool {
        var greeting = "-=- hxcpp built-in debugger";
        var firstLine = lines[0];
        var result = (firstLine != null) ? (firstLine.substr(0, greeting.length) == greeting) : false;
        trace(result);
        return result;
    }

    public function isStopOnBreakpointMatched(lines:Array<String>):Bool {
        throw "TODO: replace it";
        trace(lines);
        for (line in lines) {
            var r = ~/Breakpoint ([0-9]+),(.*) (.+).hx:([0-9]+)/;
            if (r.match(line)) {
                return true;
            }
        }
        return false;
    }

    public function isStopOnExceptionMatched(lines:Array<String>):Bool {
        throw "TODO: replace it";
        for (line in lines) {
            var r = ~/^\[Fault\].*/;
            if (r.match(line)) {
                return true;
            }
        }
        return false;
    }

    function parseVariables(lines:Array<String>):Array<VariableItem> {
        throw "TODO: replace it";
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
        throw "TODO: replace it";
        var rObjectType = ~/^\[Object (\d+),/;
        var rIntType = ~/^\d+ \(0\x\d+\)/;
        var rFloatType = ~/^\d+\.\d+$/;
        var rStringType = ~/^[\\"].*[\\"]$/;
        var rBoolType = ~/^[t|f]\S+$/;

        return if (rObjectType.match(expr)) {
            var objectId = Std.parseInt(rObjectType.matched(1));
            Object(objectId);
        }
        else if (rIntType.match(expr))
            Simple("Int");
        else if (rFloatType.match(expr))
            Simple("Float");
        else if (rStringType.match(expr))
            Simple("String");
        else if (rBoolType.match(expr))
            Simple("Bool");
        else
            Simple("Unknown");
    }
}