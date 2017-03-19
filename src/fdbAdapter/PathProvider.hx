package fdbAdapter;

import vshaxeDebug.IPathProvider;
import vshaxeDebug.ICommandBuilder;
import vshaxeDebug.IDebugger;
import vshaxeDebug.Types;

class PathProvider implements IPathProvider {

    var debugger:IDebugger;
    var nameToAbsPath:Map<String, String>;
    var initWaiting:Array<Void -> Void>;
    var loaded:Bool;

    public function new(debugger:IDebugger) {
        this.debugger = debugger;
        initWaiting = [];
        nameToAbsPath = new Map<String, String>();
        loaded = false;
    }
    
    public function init() {
        debugger.queueSend("show files", processShowFilesResult);
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
        return fileName;
    }

    public function forEditor(fileName:String):String {
        return nameToAbsPath.get(fileName);
    }

    function parseShowFiles(lines:Array<String>):Array<SourceInfo> {
        var result:Array<SourceInfo> = [];
        var rRow = ~/^([0-9]+) (.+), ([a-zA-Z0-9:.]+)$/;
        for (l in lines) {
            if (rRow.match(l)) {
                result.push({
                    name : rRow.matched(3),
                    path : rRow.matched(2)
                });
            }
        }
        return result;
    }

    function processShowFilesResult(lines:Array<String>):Bool {
        var sources:Array<SourceInfo> = parseShowFiles(lines);
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
