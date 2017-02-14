package vshaxeDebug.commands;

import vshaxeDebug.Types;
import protocol.debug.Types;

class StackTrace extends BaseCommand<StackTraceResponse, StackTraceArguments> {

    override public function execute() {
        debugger.queueSend(cmd.stackTrace(), processResult);
    }

    function processResult(lines:Array<String>):Bool {
        var pathProvider:String->String = context.fileNameToFullPathDict.get;
        var frames = parser.parseStackTrace(lines, pathProvider);
        response.body = {
            stackFrames : frames
        };
        context.onEvent(SetFrames(frames));
        context.protocol.sendResponse(response);
        return true;
    }
}
