// create handler to accept sns messages and pipe them to os exec command
exports.handler = function(event, context) {
    console.log('Received event:', JSON.stringify(event, null, 2));
    var records = event.Records;
    var record = records[0];
    var body = record.Sns.Message;
    var cmd = body;
    console.log('Received command:', cmd);
    var exec = require('child_process').exec;
    exec(cmd, function(error, stdout, stderr) {
        console.log('stdout: ' + stdout);
        console.log('stderr: ' + stderr);
        if (error !== null) {
            console.log('exec error: ' + error);
        }
    });
}

