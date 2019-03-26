package main

import (
    "C"
    "os"
    "fmt"
    "log"
    "time"
    "encoding/json"
    "strconv"
    "regexp"
    "unsafe"
    "reflect"
)

// Import vendor libraries
import (
    "github.com/fluent/fluent-bit-go/output"
    "github.com/ugorji/go/codec"
    "github.com/elastic/go-lumber/client/v2"
)

// Initialize output parameters
var (
    private_key string
    company_id string
    app_name string
    sub_name string
)

// Initialize connection details
var endpoint string = "logstashserver.coralogix.com:5044"

//export FLBPluginRegister
func FLBPluginRegister(ctx unsafe.Pointer) int {
    return output.FLBPluginRegister(ctx, "coralogix", "Send output to Coralogix")
}

//export FLBPluginInit
func FLBPluginInit(ctx unsafe.Pointer) int {
    // Get output parameters
    private_key = output.FLBPluginConfigKey(ctx, "private_key")
    company_id = output.FLBPluginConfigKey(ctx, "company_id")
    app_name = output.FLBPluginConfigKey(ctx, "app_name")
    sub_name = output.FLBPluginConfigKey(ctx, "sub_name")

    // Debug output
    log.SetPrefix("[CORALOGIX] ")
    log.Println("Initialize sending to Coralogix...")
    log.Printf("private_key = ********-****-****-****-******%s\n", private_key[len(private_key)-6:])
    log.Println("company_id =", company_id)

    // Validate credentials
    if private_key == "" || company_id == "" {
        log.Println("ERROR: private_key and company_id need to be configured!")
        return output.FLB_ERROR
    }

    // Check private_key
    private_key_pattern, _ := regexp.Compile("[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}")
    if !private_key_pattern.MatchString(private_key) {
        log.Println(" ERROR: invalid private_key!")
        return output.FLB_ERROR
    }

    // Check company_id
    if company_id_integer, err := strconv.ParseInt(company_id, 10, 64); err != nil || company_id_integer < 0 {
        log.Println(" ERROR: invalid company_id!")
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

    log.Printf("The Application Name %s and Subsystem Name %s from the Fluent-Bit, has started to send data.", app_name, sub_name)
    return output.FLB_OK
}

//export FLBPluginFlush
func FLBPluginFlush(data unsafe.Pointer, length C.int, tag *C.char) int {
    var h codec.Handle = new(codec.MsgpackHandle)
    var b []byte
    var m interface{}
    var batch []interface{}

    // Get hostname
    hostname, err := os.Hostname()
    if err != nil {
        hostname = "localhost"
    }

    // Decode Fluent-Bit records data
    b = C.GoBytes(data, length)
    dec := codec.NewDecoderBytes(b, h)

    // Send logs batch to Logstash
    connection, err := v2.SyncDial(endpoint, v2.CompressionLevel(3), v2.Timeout(30 * time.Second))
    if err != nil {
        log.Printf(" ERROR: unable connect to %s: %v\n", endpoint, err)
        return output.FLB_ERROR
    }

    // Iterate Records
    for {
        // Decode record
        err := dec.Decode(&m)
        if err != nil {
            break
        }

        // Convert record data to map
        slice := reflect.ValueOf(m)
        data := slice.Index(1)
        record := data.Interface().(map[interface{}] interface{})

        // Convert record to JSON
        json_record, err := createJSON(record)
        if err != nil {
            log.Printf(" ERROR: %v\n", err)
            continue
        }

        // Build logs batch
        batch = append(batch, map[string]interface{}{
            "@timestamp": time.Now(),
            "type": "fluent-bit",
            "host": hostname,
            "message": string(json_record[:]),
            "fields": map[string]interface{}{
                "PRIVATE_KEY": private_key,
                "COMPANY_ID": company_id,
                "APP_NAME": app_name,
                "SUB_SYSTEM": sub_name,
            },
        })

        //log.Printf("[CORALOGIX] Sending %d records to %s...\n", len(batch), endpoint)
        _, err = connection.Send(batch)
        if err != nil {
            log.Println(" ERROR: cannot send logs batch:", err)
            return output.FLB_RETRY
        }
    }

    // Close connection
    connection.Close()
    return output.FLB_OK
}

//export FLBPluginExit
func FLBPluginExit() int {
    return output.FLB_OK
}

// Convert record to JSON
func createJSON(record map[interface{}]interface{}) ([]byte, error) {
    m := make(map[string]interface{})
    for k, v := range record {
        switch t := v.(type) {
        case []byte:
            // prevent encoding to base64
            m[k.(string)] = string(t)
        default:
            m[k.(string)] = v
        }
    }
    js, err := json.Marshal(m)
    if err != nil {
        return nil, fmt.Errorf("cannot convert message to JSON: %v", err)
    }
    return js, nil
}

func main() {
}
