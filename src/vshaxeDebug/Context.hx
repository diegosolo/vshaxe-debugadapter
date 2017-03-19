package vshaxeDebug;

import adapter.Handles;
import adapter.ProtocolServer;
import protocol.debug.Types.Response;
import protocol.debug.Types.Breakpoint;
import protocol.debug.Types.OutputEventCategory;
import vshaxeDebug.EDebuggerState.StateController;
import vshaxeDebug.EDebuggerState.EStateControlEvent;
import vshaxeDebug.Types;
import vshaxeDebug.IPathProvider;
import adapter.DebugSession.OutputEvent as OutputEventImpl;

class Context {

    public var variableHandles(default, null):Handles<String>;
    public var knownObjects(default, null):Map<Int, String>;
    public var sourcePath(default, default):String;
    public var breakpoints(default, null):Map<String, Array<Breakpoint>>;
    public var debugger(default, null):IDebugger;
    public var protocol(default, null):ProtocolServer;
    public var debuggerState(default, null):EDebuggerState;
    public var pathProvider(default, null):IPathProvider;

    public function new(protocol:ProtocolServer, debugger:IDebugger, pathProvider:IPathProvider) {
        this.protocol = protocol;
        this.debugger = debugger;
        this.pathProvider = pathProvider;

        debuggerState = WaitingGreeting;
        breakpoints = new Map<String, Array<Breakpoint>>();
        variableHandles = new Handles<String>();
        knownObjects = new Map<Int, String>();
    }

    public function onEvent(event:EStateControlEvent) {
        debuggerState = StateController.onEvent(this, event);
    }

    public function sendToOutput(output:String, category:OutputEventCategory = OutputEventCategory.console) {
        protocol.sendEvent(new OutputEventImpl(output + "\n", category));
    }

    public function sendError(response:Response<Dynamic>, message:String):Void {
        response.success = false;
        response.message = message;
        protocol.sendResponse(response);
    }
}
