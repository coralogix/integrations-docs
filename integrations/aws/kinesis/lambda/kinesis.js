'use strict';

const AWS = require('aws-sdk');
const https = require('https');
const assert = require('assert');

assert(process.env.private_key, 'No private key')
const appName = process.env.app_name ? process.env.app_name : 'NO_APPLICATION';
const subName = process.env.sub_name ? process.env.sub_name : 'NO_SUBSYSTEM';

exports.handler = (event, context, callback) => {

    function parseEvent(streamEventRecord) {
        let streamEventData = new Buffer(streamEventRecord.kinesis.data, 'base64').toString('ascii');
        return {
            "timestamp": streamEventRecord.kinesis.approximateArrivalTimestamp * 1000,
            "severity": getSeverityLevel(streamEventData),
            "text": streamEventData
        };
    }

    function postEventsToCoralogix(parsedEvents) {
        try {
            var options = {
                hostname: 'api.coralogix.com',
                port: 443,
                path: '/api/v1/logs',
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                }
            };

            let retries = 3;
            let timeoutMs = 10000;
            let retryNum = 0;
            let sendRequest = function sendRequest() {
                let req = https.request(options, function (res) {
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
            }

            sendRequest();
        } catch (ex) {
            console.log(ex.message);
            callback(ex.message);
        }
    }

    function getSeverityLevel(message) {
        var severity = 3;

        if(message.includes('debug'))
            severity = 1
        if(message.includes('verbose'))
            severity = 2
        if(message.includes('info'))
            severity = 3
        if(message.includes('warn') || message.includes('warning'))
            severity = 4
        if(message.includes('error'))
            severity = 5
        if(message.includes('critical') || message.includes('panic'))
            severity = 6

        return severity;
    }

    postEventsToCoralogix({
        "privateKey": process.env.private_key,
        "applicationName": appName,
        "subsystemName": subName,
        "logEntries": event.Records.map((eventRecord) => parseEvent(eventRecord))
    });
};
