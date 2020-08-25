package main

import (
    "C"
    "os"
    "log"
    "time"
    "bytes"
    "regexp"
    "unsafe"
    "net/http"
    "compress/gzip"
)

// Import vendor libraries
import (
    "github.com/fluent/fluent-bit-go/output"
    "github.com/json-iterator/go"
    "github.com/thedevsaddam/gojsonq"
    "github.com/araddon/dateparse"
)

//export FLBPluginRegister
func FLBPluginRegister(def unsafe.Pointer) int {
    return output.FLBPluginRegister(def, "coralogix", "Send output to Coralogix")
}

//export FLBPluginInit
func FLBPluginInit(plugin unsafe.Pointer) int {
    // Get output parameters
    private_key := output.FLBPluginConfigKey(plugin, "Private_Key")
    app_name := output.FLBPluginConfigKey(plugin, "App_Name")
    sub_name := output.FLBPluginConfigKey(plugin, "Sub_Name")
    app_name_key := output.FLBPluginConfigKey(plugin, "App_Name_Key")
    sub_name_key := output.FLBPluginConfigKey(plugin, "Sub_Name_Key")
    time_key := output.FLBPluginConfigKey(plugin, "Time_Key")
    log_key := output.FLBPluginConfigKey(plugin, "Log_Key")
    host_key := output.FLBPluginConfigKey(plugin, "Host_Key")
    debug := output.FLBPluginConfigKey(plugin, "Debug")

    // Debug output
    log.SetPrefix("[CORALOGIX] ")
    log.Println("Initialize sending to Coralogix...")
    log.Printf("Private_Key = ********-****-****-****-******%s\n", private_key[len(private_key)-6:])

    // Check Private Key
    private_key_pattern, _ := regexp.Compile("[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}")
    if private_key == "" || !private_key_pattern.MatchString(private_key) {
        log.Println(" ERROR: invalid Private_Key!")
        return output.FLB_ERROR
    }

    // Check Application name
    if app_name == "" {
        app_name = "NO_APP_NAME"
    }

    // Check Subsystem name
    if sub_name == "" {
        sub_name = "NO_SUB_NAME"
    }

    // Check debug status
    if debug == "On" {
        log.Printf("The Application Name %s and Subsystem Name %s from the Fluent-Bit, has started to send data.", app_name, sub_name)
    }

    // Pass output configuration to context
    output.FLBPluginSetContext(plugin, map[string]string{
        "private_key": private_key,
        "app_name": app_name,
        "sub_name": sub_name,
        "app_name_key": app_name_key,
        "sub_name_key": sub_name_key,
        "time_key": time_key,
        "log_key": log_key,
        "host_key": host_key,
        "debug": debug,
    })

    return output.FLB_OK
}

//export FLBPluginFlushCtx
func FLBPluginFlushCtx(ctx, data unsafe.Pointer, length C.int, tag *C.char) int {
    // Get Coralogix endpoint URL
    endpoint, exists := os.LookupEnv("CORALOGIX_LOG_URL")
	if !exists {
        endpoint = "https://api.coralogix.com/logs/rest/singles"
    }
    
    log.Printf(" INFO: Sending %s records...\n", endpoint)

    // Get hostname
    hostname, err := os.Hostname()
    if err != nil {
        hostname = "localhost"
    }

    // Create Fluent-Bit decoder
    decoder := output.NewDecoder(data, int(length))

    // Get plugin instance configuration
    config := output.FLBPluginGetContext(ctx).(map[string]string)

    // Build records batch
    var batch []interface{}
    for {
        // Extract record
        ret, _, record := output.GetRecord(decoder)
        if ret != 0 {
            break
        }

        // Convert record to JSON
        json_record, err := jsoniter.MarshalToString(encodeJSON(record))
        if err != nil {
            log.Printf(" ERROR: %v\n", err)
            continue
        }

        // Parse timestamp
        timestamp, err := dateparse.ParseAny(extractField(json_record, config["time_key"], time.Now().Format(time.RFC3339)))
        if err != nil {
            timestamp = time.Now()
        }

        // Add record to batch
        batch = append(batch, map[string]interface{}{
            "applicationName": extractField(json_record, config["app_name_key"], config["app_name"]),
            "subsystemName": extractField(json_record, config["sub_name_key"], config["sub_name"]),
            "computerName": extractField(json_record, config["host_key"], hostname),
            "timestamp": timestamp.UnixNano() / 1000000,
            "text": extractField(json_record, config["log_key"], json_record),
        })
    }
    json_batch, _ := jsoniter.Marshal(batch)

    // Compress data
    var buffer bytes.Buffer
    zipper, err := gzip.NewWriterLevel(&buffer, 9)
    zipper.Write(json_batch)
    zipper.Close()
    if err != nil {
        log.Println(" ERROR: cannot compress the data:", err)
        return output.FLB_RETRY
    }

    // Build request
    request, err := http.NewRequest(http.MethodPost, endpoint, &buffer)
    request.Header.Set("Content-Type", "application/json")
    request.Header.Set("Content-Encoding", "gzip")
    request.Header.Set("private_key", config["private_key"])
    if err != nil {
        log.Println(" ERROR: cannot build request:", err)
        return output.FLB_RETRY
    }

    // Send records batch
    if config["debug"] == "On" {
        log.Printf(" INFO: Sending %d records...\n", len(batch))
    }
    client := &http.Client{Timeout: 30 * time.Second}
    response, err := client.Do(request)
    if err != nil {
        log.Println(" ERROR: cannot send logs batch:", err)
        return output.FLB_RETRY
    } else if response.StatusCode != 200 {
        log.Println(" ERROR: cannot send logs batch:", response.StatusCode)
        return output.FLB_RETRY
    }

    return output.FLB_OK
}

//export FLBPluginExit
func FLBPluginExit() int {
    return output.FLB_OK
}

// Encode record to UTF-8
func encodeJSON(record map[interface{}]interface{}) map[string]interface{} {
	m := make(map[string]interface{})
	for k, v := range record {
		switch t := v.(type) {
		    case []byte:
			    // prevent encoding to base64
			    m[k.(string)] = string(t)
		    case map[interface{}]interface{}:
			    if nextValue, ok := record[k].(map[interface{}]interface{}); ok {
				    m[k.(string)] = encodeJSON(nextValue)
			    }
		    default:
			    m[k.(string)] = v
		}
	}
	return m
}

// Extract field value from record
func extractField(json_record string, key string, def string) (string) {
    if key == "" {
        return def
    }
    jq := gojsonq.New().FromString(json_record)
    result := jq.Find(key)
    if jq.Error() != nil {
        log.Printf(" WARNING: cannot extract field %s from record: %v\n", key, jq.Errors())
        return def
    }
    switch t := result.(type) {
        case string:
            return t
        default:
            sub_record, err := jsoniter.MarshalToString(result)
            if err != nil {
                log.Printf(" WARNING: cannot extract field %s from record: %v\n", key, err)
                return def
            }
            return sub_record
    }
}

func main() {}
