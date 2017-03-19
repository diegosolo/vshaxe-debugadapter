package vshaxeDebug;

class PlatformParameters {

    public static function getEndOfLineSign():String {
        return js.Node.process.platform == "win32" ? "\r\n" : "\n";
    }

    public static function getPathSlashSign():String {
        return js.Node.process.platform == "win32" ? "\\" : "/";
    }
}