package vshaxeDebug.commands;

import protocol.debug.Types;
import vshaxeDebug.Types;

class StackTrace extends BaseCommand<StackTraceResponse, StackTraceArguments> {

    override public function execute() {
        debugger.queueSend(cmd.stackTrace(), processResult);
    }

    function processResult(lines:Array<String>):Bool {
        var frames = parser.parseStackTrace(lines, pathProvider);
        response.body = {
            stackFrames : frames
        };
        context.onEvent(SetFrames(frames));
        context.protocol.sendResponse(response);
        return true;
    }

    function pathProvider(fileName:String):String {
        return context.fileNameToFullPathDict.get(fileName);
    }
}
