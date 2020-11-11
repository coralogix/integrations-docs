'use strict';

const https = require('https');
const zlib = require('zlib');
const assert = require('assert');

assert(process.env.private_key, 'No private key');
const appName = process.env.app_name ? process.env.app_name : 'NO_APPLICATION';
const newlinePattern = (process.env.newline_pattern) ? RegExp(process.env.newline_pattern) : /(?:\r\n|\r|\n)/g;
const coralogixUrl = (process.env.CORALOGIX_URL) ? process.env.CORALOGIX_URL : 'api.coralogix.com';

exports.handler = (event, context, callback) => {
    const payload = new Buffer(event.awslogs.data, 'base64');

    function postEventsToCoralogix(parsedEvents) {
        try {
            let retries = 3;
            let timeoutMs = 10000;
            let retryNum = 0;
            let sendRequest = function sendRequest() {
                let req = https.request({
                    hostname: coralogixUrl,
                    port: 443,
                    path: '/api/v1/logs',
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    }
                }, function (res) {
                    console.log('Status: ' + res.statusCode);
                    console.log('Headers: ' + JSON.stringify(res.headers));
                    res.setEncoding('utf8');
                    res.on('data', function (body) {
                        console.log('Body: ' + body);
                    });
                });
                req.setTimeout(timeoutMs, () => {
                    req.abort();
                    if (retryNum++ < retries) {
                        console.log('problem with request: timeout reached. retrying ' + retryNum + '/' + retries);
                        sendRequest();
                    } else {
                        console.log('problem with request: timeout reached. failed all retries.');
                    }
                });
                req.on('error', function (e) {
                    console.log('problem with request: ' + e.message);
                });
                req.write(JSON.stringify(parsedEvents));
                req.end();
            };
            sendRequest();
        } catch (ex) {
            console.log(ex.message);
            callback(ex.message);
        }
    }

    function getSeverityLevel(message) {
        let severity = 3;
        if (message.includes('debug'))
            severity = 1;
        if (message.includes('verbose'))
            severity = 2;
        if (message.includes('info'))
            severity = 3;
        if (message.includes('warn') || message.includes('warning'))
            severity = 4;
        if (message.includes('error'))
            severity = 5;
        if (message.includes('critical') || message.includes('panic'))
            severity = 6;
        return severity;
    }

    zlib.gunzip(payload, (error, result) => {
        if (error) {
            callback(error);
        } else {
            const resultParsed = JSON.parse(result.toString('ascii'));
            const parsedEvents = resultParsed.logEvents.map(logEvent => logEvent.message).join("\r\n").split(newlinePattern);

            postEventsToCoralogix({
                "privateKey": process.env.private_key,
                "applicationName": appName,
                "subsystemName": process.env.sub_name ? process.env.sub_name : resultParsed.logGroup,
                "logEntries": parsedEvents.filter((logEvent) => logEvent.length > 0).map((logEvent) => {
                    return {
                        "timestamp": Date.now(),
                        "severity": getSeverityLevel(logEvent.toLowerCase()),
                        "text": logEvent,
                        "threadId": resultParsed.logStream
                    };
                })
            });
        }
    });
};
