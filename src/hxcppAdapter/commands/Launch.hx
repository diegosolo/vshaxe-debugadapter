package hxcppAdapter.commands;

import vshaxeDebug.Types;
import vshaxeDebug.commands.BaseCommand;
import protocol.debug.Types;
import vshaxeDebug.PathUtils;
import js.node.Fs;

class Launch extends BaseCommand<LaunchResponse, ExtLaunchRequestArguments> {

    override public function execute() {
        var program = args.program;
        if (!PathUtils.isAbsolutePath(program)) {
            if (!PathUtils.isOnPath(program)) {
                context.sendError(response, 'Cannot find runtime $program on PATH.');
                context.protocol.sendResponse(response);
                return;
            }
        } 
        else if (!Fs.existsSync(program)) {
            response.success = false;
            response.message = 'Cannot find $program';
            context.protocol.sendResponse(response);
            return;
        }
        debugger.queueSend(cmd.launch(program), processResult);
        context.sendToOutput('running $program', OutputEventCategory.stdout);
    }

    function processResult(lines:Array<String>):Bool {
        context.sendToOutput("launch success", OutputEventCategory.stdout);
        return true;
    }
}
