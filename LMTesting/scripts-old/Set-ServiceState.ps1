# Script to start/stop services

# Getting parameters from calling process
Param
(
    [parameter(Mandatory=$TRUE,
    HelpMessage="Requires state to set on service: Start/Stop/Restart")]
    [string]$STATE,
    [parameter(Mandatory=$TRUE,
    HelpMessage="Requires service name")]
    [string]$SERVICE
)

write-host

# Verifying service exists
get-service $SERVICE -erroraction "stop" | out-null

switch ($STATE)
    {
        # Stop service
        stop
        {
            write-host "Stopping '$SERVICE' service..."
            if ((get-service $SERVICE).Status -eq "Stopped")
            {
                write-host "'$SERVICE' service is already stopped."
                break
            }
            stop-service $SERVICE -force -erroraction "stop"
            #(get-service $SERVICE).WaitForStatus('Stopped')
            write-host "'$SERVICE' stopped."
        } 
        # Start service
        start
        {
            write-host "Starting '$SERVICE' service..."
            if ((get-service $SERVICE).Status -eq "Running")
            {
                write-host "'$SERVICE' service is already running."
                break
            }
            if ((get-service $SERVICE).Status -eq "StartPending")
            {
                write-host "'$SERVICE' service already has a start pending."
                break
            }
            start-service $SERVICE -erroraction "stop"
            #(get-service $SERVICE).WaitForStatus('Running')
            write-host "'$SERVICE' started."
        } 
        # Stop then start service
        restart
        {
            Set-ServiceState stop helpsvc
            Set-ServiceState start helpsvc
        }
        # Fail on unavailable argument passed
        default
        {
            write-error "ERROR: Invalid parameter '$STATE'."
            exit 1
        }
    }

exit 0 
