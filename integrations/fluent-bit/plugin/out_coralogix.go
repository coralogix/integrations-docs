package main

import (
    "C"
    "os"
    "log"
    "time"
    "strconv"
    "regexp"
    "unsafe"
)

// Import vendor libraries
import (
    "github.com/fluent/fluent-bit-go/output"
    "github.com/elastic/go-lumber/client/v2"
    "github.com/json-iterator/go"
    "github.com/thedevsaddam/gojsonq"
)

// Initialize connection details
var endpoint string = "logstashserver.coralogix.com:5044"

//export FLBPluginRegister
func FLBPluginRegister(def unsafe.Pointer) int {
    return output.FLBPluginRegister(def, "coralogix", "Send output to Coralogix")
}

//export FLBPluginInit
func FLBPluginInit(plugin unsafe.Pointer) int {
    // Get output parameters
    private_key := output.FLBPluginConfigKey(plugin, "Private_Key")
    company_id := output.FLBPluginConfigKey(plugin, "Company_Id")
    app_name := output.FLBPluginConfigKey(plugin, "App_Name")
    sub_name := output.FLBPluginConfigKey(plugin, "Sub_Name")
    app_name_key := output.FLBPluginConfigKey(plugin, "App_Name_Key")
    sub_name_key := output.FLBPluginConfigKey(plugin, "Sub_Name_Key")
    time_key := output.FLBPluginConfigKey(plugin, "Time_Key")
    log_key := output.FLBPluginConfigKey(plugin, "Log_Key")
    host_key := output.FLBPluginConfigKey(plugin, "Host_Key")
    compression := output.FLBPluginConfigKey(plugin, "Compression")
    debug := output.FLBPluginConfigKey(plugin, "Debug")

    // Debug output
    log.SetPrefix("[CORALOGIX] ")
    log.Println("Initialize sending to Coralogix...")
    log.Printf("private_key = ********-****-****-****-******%s\n", private_key[len(private_key)-6:])
    log.Println("company_id =", company_id)

    // Validate credentials
    if private_key == "" || company_id == "" {
        log.Println("ERROR: Private_Key and Company_Id need to be configured!")
        return output.FLB_ERROR
    }

    // Check Private Key
    private_key_pattern, _ := regexp.Compile("[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}")
    if !private_key_pattern.MatchString(private_key) {
        log.Println(" ERROR: invalid Private_Key!")
        return output.FLB_ERROR
    }

    // Check Company ID
    if company_id_integer, err := strconv.ParseInt(company_id, 10, 64); err != nil || company_id_integer < 0 {
        log.Println(" ERROR: invalid Company_Id!")
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

    // Check compression level
    if compression_integer, err := strconv.ParseInt(compression, 10, 64); err != nil || compression_integer < 0 || compression_integer > 9 {
        compression = "3"
    }

    if debug == "On" {
        log.Printf("The Application Name %s and Subsystem Name %s from the Fluent-Bit, has started to send data.", app_name, sub_name)
    }

    // Pass output configuration to context
    output.FLBPluginSetContext(plugin, map[string]string{
        "private_key": private_key,
        "company_id": company_id,
        "app_name": app_name,
        "sub_name": sub_name,
        "app_name_key": app_name_key,
        "sub_name_key": sub_name_key,
        "time_key": time_key,
        "log_key": log_key,
        "host_key": host_key,
        "debug": debug,
        "compression": compression,
    })

    return output.FLB_OK
}

//export FLBPluginFlushCtx
func FLBPluginFlushCtx(ctx, data unsafe.Pointer, length C.int, tag *C.char) int {
    var batch []interface{}

    // Get hostname
    hostname, err := os.Hostname()
    if err != nil {
        hostname = "localhost"
    }

    // Create Fluent-Bit decoder
    dec := output.NewDecoder(data, int(length))

    // Get plugin instance configuration
    config := output.FLBPluginGetContext(ctx).(map[string]string)

    // Get compression level
    compression, err := strconv.Atoi(config["compression"])

    // Establish connection to Coralogix Logstash
    connection, err := v2.SyncDial(endpoint, v2.CompressionLevel(compression), v2.Timeout(30 * time.Second))
    if err != nil {
        log.Printf(" ERROR: unable connect to %s: %v\n", endpoint, err)
        return output.FLB_ERROR
    }

    // Iterate Records
    for {
        // Extract Record
        ret, _, record := output.GetRecord(dec)
        if ret != 0 {
            break
        }

        // Convert Record to JSON
        json_record, err := jsoniter.MarshalToString(encodeJSON(record))
        if err != nil {
            log.Printf(" ERROR: %v\n", err)
            continue
        }

        // Build Records Batch
        batch = append(batch, map[string]interface{}{
            "@timestamp": extractField(json_record, config["time_key"], time.Now().Format(time.RFC3339)),
            "type": "fluent-bit",
            "beat": map[string]interface{}{
                "hostname": extractField(json_record, config["host_key"], hostname),
            },
            "message": extractField(json_record, config["log_key"], json_record),
            "fields": map[string]interface{}{
                "PRIVATE_KEY": config["private_key"],
                "COMPANY_ID": config["company_id"],
                "APP_NAME": extractField(json_record, config["app_name_key"], config["app_name"]),
                "SUB_SYSTEM": extractField(json_record, config["sub_name_key"], config["sub_name"]),
            },
        })
    }

    // Send Records Batch
    if config["debug"] == "On" {
        log.Printf(" INFO: Sending %d records to %s...\n", len(batch), endpoint)
    }
    _, err = connection.Send(batch)
    if err != nil {
        log.Println(" ERROR: cannot send logs batch:", err)
        return output.FLB_RETRY
    }

    // Close connection
    connection.Close()
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
    res := jq.Find(key)
    if jq.Error() != nil {
        log.Printf(" WARNING: cannot extract field %s from record: %v\n", key, jq.Errors())
        return def
    }
    return res.(string)
}

func main() {}
