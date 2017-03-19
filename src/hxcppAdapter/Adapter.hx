package hxcppAdapter;

import vshaxeDebug.Context;
import vshaxeDebug.CLIAdapter;
import vshaxeDebug.Types;
import vshaxeDebug.BaseAdapter;
import vshaxeDebug.ICommandBuilder;
import vshaxeDebug.IParser;
import vshaxeDebug.PlatformParameters;
import vshaxeDebug.commands.BaseCommand;
import vshaxeDebug.EDebuggerState;
import protocol.debug.Types;
import adapter.DebugSession;
import js.node.Fs;
import haxe.ds.Option;

class Adapter extends BaseAdapter {

    static var logPath:String;

    static function main() {
        setupTrace();
        DebugSession.run(Adapter);
    }

    static function setupTrace() {
        haxe.Log.trace = function(v, ?i) {
            var r = [Std.string(v)];
        }
    }

    public function new() {
        var deps:AdapterDependencies = {
            createContext : createContext,
            getLaunchCommand : getLaunchCommand,
            getAttachCommand : getAttachCommand
        };
        super(deps);
    }

    function getLaunchCommand(context:Context, response:LaunchResponse, args:ExtLaunchRequestArguments):BaseCommand<LaunchResponse, ExtLaunchRequestArguments> {
        return new hxcppAdapter.commands.Launch(context, response, args);
    }

    function getAttachCommand(context:Context,
                              response:AttachResponse,
                              args:ExtAttachRequestArguments):Option<BaseCommand<AttachResponse, ExtAttachRequestArguments>> {
                                  
        var command:BaseCommand<AttachResponse, ExtAttachRequestArguments> = new fdbAdapter.commands.Attach(context, response, args);
        return Some(command);
    }

    function createContext(program:String):Context {
        var scriptPath = js.Node.__dirname;
        var commandBuilder:ICommandBuilder = new CommandBuilder();
        var eolSign = PlatformParameters.getEndOfLineSign();
        var parser:IParser = new Parser(eolSign);
        var cliAdapterConfig = {
            cmd:program,
            cmdParams:["-DHXCPP_DEBUGGER"],
            onPromptGot:onPromptGot,
            onError: function(error) {
                return "Could not start fdb. Make sure that PATH contains the Java executable or JAVA_HOME is set correctly.";
            },
            allOutputReceiver:allOutputReceiver,
            commandBuilder : commandBuilder,
            parser : parser
        };

        debugger = new CLIAdapter(cliAdapterConfig);
        debugger.start();
        return new Context(this, debugger, new PathProvider(debugger));
    }

    function onPromptGot(lines:Array<String>) {
        switch (context.debuggerState) {
            case EDebuggerState.WaitingGreeting:
                if (parser.isGreetingMatched(lines)) {
                    context.pathProvider.init();
                    context.onEvent(GreetingReceived);
                }
                else
                    trace('Start FAILED: [$lines]');
            case _:
        }
    }

    function allOutputReceiver(rawInput:String):Bool {
        var proceed:Bool = false;
        if (parser.isExitMatched(rawInput)) {
            var event = new TerminatedEvent(false);
            traceJson(event);
            sendEvent(event);
            terminated = true;
            debugger.stop();
            return true;
        }

        switch (context.debuggerState) {
            case EDebuggerState.Running:
                if (parser.isStopOnBreakpointMatched(rawInput)) {
                    context.onEvent(Stop(StopReason.breakpoint));
                    proceed = true;
                }
                else if (parser.isStopOnExceptionMatched(rawInput)) {
                    context.onEvent(Stop(StopReason.exception));
                    proceed = true;
                }
                else {
                    var lines:Array<String> = parser.getTraces(rawInput);
                    for (line in lines) {
                        context.sendToOutput(line);
                        proceed = true;
                    }
                }
            default:
        }
        return proceed;
    }
}
