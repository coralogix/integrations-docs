'use strict';

const https = require('https');
const assert = require('assert');

assert(process.env.private_key, 'No private key')
const appName = process.env.app_name ? process.env.app_name : 'NO_APPLICATION';
const subName = process.env.sub_name ? process.env.sub_name : 'NO_SUBSYSTEM';
const newlinePattern = (process.env.newline_pattern) ? RegExp(process.env.newline_pattern) : /(?:\r\n|\r|\n)/g;
const coralogixUrl = (process.env.CORALOGIX_URL) ? process.env.CORALOGIX_URL : 'api.coralogix.com';

exports.handler = (event, context, callback) => {
    function extractEvent(streamEventRecord) {
        return new Buffer(streamEventRecord.kinesis.data, 'base64').toString('ascii');
    }

    function parseEvents(eventsData) {
        return eventsData.split(newlinePattern).map((eventRecord) => {
            return {
                "timestamp": Date.now(),
                "severity": getSeverityLevel(eventRecord),
                "text": eventRecord
            };
        });
    }

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

    postEventsToCoralogix({
        "privateKey": process.env.private_key,
        "applicationName": appName,
        "subsystemName": subName,
        "logEntries": parseEvents(event.Records.map(extractEvent).join('\n'))
    });
};
