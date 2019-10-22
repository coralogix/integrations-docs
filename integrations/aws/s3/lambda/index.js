'use strict';

const aws = require('aws-sdk');
const zlib = require('zlib');
const Coralogix = require("coralogix-logger");
const s3 = new aws.S3();
let newlinePattern = /(?:\r\n|\r|\n)/g;
const logEntries = process.env.log_entries ? process.env.log_entries : null;
const assert = require('assert');

assert(process.env.private_key, 'No private key')
const appName = process.env.app_name ? process.env.app_name : 'NO_APPLICATION';
const subName = process.env.sub_name ? process.env.sub_name : 'NO_SUBSYSTEM';
if (process.env.newline_pattern)
    newlinePattern = RegExp(process.env.newline_pattern);

const config = new Coralogix.LoggerConfig({
    applicationName: appName,
    privateKey: process.env.private_key,
    subsystemName: subName,
});

Coralogix.CoralogixLogger.configure(config);

// create a new logger with category 
const logger = new Coralogix.CoralogixLogger(appName);

exports.handler = function (event, context, callback) {
    // Get the object from the event and show its content type
    const bucket = event.Records[0].s3.bucket.name;
    const key = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, ' '));
    const params = {
        Bucket: bucket,
        Key: key,
    };
    s3.getObject(params, (err, data) => {
        if (err) {
            console.log(err);
            callback(err);
        } else {
            if (data.ContentType == 'application/octet-stream' ||
                data.ContentType == 'application/x-gzip' ||
                data.ContentEncoding == 'gzip' ||
                data.ContentEncoding == 'compress' ||
                key.endsWith('.gz')) {

                zlib.gunzip(data.Body, function (error, result) {
                    if (error) {
                        context.fail(error);
                    } else {
                        sendLogs(Buffer.from(result));
                        callback(null, data.ContentType);
                    }
                });
            } else {
                sendLogs(Buffer.from(data.Body));
            }
        }
    });

    function sendLogs(content) {
        let logs = null;

        if (logEntries) {
            try {
                logs = [];
                let entries = JSON.parse(content)[logEntries];
                entries.forEach(log => {
                    logs.push(JSON.stringify(log));
                });
            } catch (err) {
                console.log(err);
            }
        } else {
            logs = content.toString('utf8').split(newlinePattern);
        }

        console.log('numbers of logs:', logs.length);

        for (let i = 0; i < logs.length; i++) {
            // create a log 
            if (!logs[i]) continue;
            const log = new Coralogix.Log({
                text: logs[i],
                severity: getSeverityLevel(logs[i])
            });
            // send log to coralogix 
            logger.addLog(log);
        }
    }

    function getSeverityLevel(message) {
        let severity = 3;

        if (!message)
            return severity;
        if (message.includes('Warning' || 'warn'))
            severity = 4;
        if (message.includes('Error') | message.includes('Exception'))
            severity = 5;
        return severity;
    }
};
