// Run with osascript -l JavaScript. One watcher per Annotate mode.
ObjC.import("AppKit");

function run([rex, token, session, block]) {
    const bundle = "com.superlogical.rex";
    const clipboard = $.NSPasteboard.generalPasteboard;
    const workspace = $.NSWorkspace.sharedWorkspace;
    let seen = Number(clipboard.changeCount);
    let heartbeat = Date.now() + 5000;

    function report(text) {
        const task = $.NSTask.alloc.init;
        const input = $.NSPipe.pipe;
        const output = $.NSPipe.pipe;
        task.launchPath = rex;
        task.arguments = ["--autostart=false", "do", "annotate_selection", "-s", session, "-b", block, "--args", "-", "--json"];
        task.standardInput = input;
        task.standardOutput = output;
        task.launch;
        input.fileHandleForWriting.writeData($(JSON.stringify({ token, text })).dataUsingEncoding($.NSUTF8StringEncoding));
        input.fileHandleForWriting.closeFile;
        const reply = output.fileHandleForReading.readDataToEndOfFile;
        output.fileHandleForReading.closeFile;
        task.waitUntilExit;
        if (Number(task.terminationStatus) !== 0) return false;
        return JSON.parse(ObjC.unwrap($.NSString.alloc.initWithDataEncoding(reply, $.NSUTF8StringEncoding))).active;
    }

    for (;;) {
        $.NSThread.sleepForTimeInterval(0.1);
        // Rex leaves key modes when it loses focus, so Annotate mode ends here too.
        const app = workspace.frontmostApplication;
        if (app.isNil() || ObjC.unwrap(app.bundleIdentifier) !== bundle) return;
        const count = Number(clipboard.changeCount);
        let text;
        if (count !== seen) {
            seen = count;
            const copied = ObjC.unwrap(clipboard.stringForType($.NSPasteboardTypeString));
            if (typeof copied === "string" && copied.trim()) text = copied;
        }
        if (text === undefined && Date.now() < heartbeat) continue;
        if (!Number($.NSRunningApplication.runningApplicationsWithBundleIdentifier(bundle).count) || !report(text)) return;
        // Don't replay copies made while the action was running.
        seen = Number(clipboard.changeCount);
        heartbeat = Date.now() + 5000;
    }
}
