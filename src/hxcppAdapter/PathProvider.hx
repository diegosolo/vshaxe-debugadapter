package hxcppAdapter;

import vshaxeDebug.IPathProvider;
import vshaxeDebug.ICommandBuilder;
import vshaxeDebug.IDebugger;
import vshaxeDebug.Types;
import vshaxeDebug.PlatformParameters;

class PathProvider implements IPathProvider {

    var debugger:IDebugger;
    var nameToAbsPath:Map<String, String>;
    var nameToWorkspacePath:Map<String, String>;
    var initWaiting:Array<Void -> Void>;
    var loaded:Bool;

    public function new(debugger:IDebugger) {
        this.debugger = debugger;
        initWaiting = [];
        nameToAbsPath = new Map<String, String>();
        nameToWorkspacePath = new Map<String, String>();
        loaded = false;
    }
    
    public function init() {
        debugger.queueSend("files", processWorkspaceFilesResult);
        debugger.queueSend("filespath", processAbsFilesResult);
    }

    public function initWait(callback:Void -> Void) {
        if (loaded) {
            callback();
        }
        else {
            initWaiting.push(callback);
        }
    }
    
    public function forBreakpointSetting(fileName:String):String {
        return nameToWorkspacePath.get(fileName);
    }

    public function forEditor(fileName:String):String {
        return nameToAbsPath.get(fileName);
    }

    function parseFiles(lines:Array<String>):Array<SourceInfo> {
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

    function parseFilesPath(lines:Array<String>):Array<SourceInfo> {
        var result:Array<SourceInfo> = [];
        var rRow = ~/^(.)*\.hx$/;
        var pathSplitter = PlatformParameters.getPathSlashSign();
        for (l in lines) {
            if (rRow.match(l)) {
                var splited:Array<String> = l.split(pathSplitter);
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

    function processWorkspaceFilesResult(lines:Array<String>):Bool {
        var sources:Array<SourceInfo> = parseFiles(lines);
        for (source in sources) {
            nameToWorkspacePath.set(source.name, source.path);
        }
        return true;
    }

    function processAbsFilesResult(lines:Array<String>):Bool {
        var sources:Array<SourceInfo> = parseFilesPath(lines);
        for (source in sources) {
            nameToAbsPath.set(source.name, source.path);
        }
        loaded = true;
        for (callback in initWaiting) {
            callback();
        }
        initWaiting = [];
        return true;
    }
}
