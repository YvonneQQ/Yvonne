#!/usr/bin/env bash
function errecho {
    printf "%s\n" "$*" 2>&1
}

###############################################################################
# function iecho
#
# This function enables the script to display the specified text only if
# the global variable $VERBOSE is set to true.
###############################################################################
function iecho {
    if [[ $VERBOSE == true ]]; then
        echo "$@"
    fi
}

function get_instance_info {

    # Declare local variables.
    local INSTANCE_ID RESPONSE

    # This function accepts a single parameter.
    INSTANCE_ID=$1

    # The following --filters parameter causes server-side filtering to limit
    # results to only the records that match the specified ID. The --query
    # parameter causes CLI client-side filtering to include only the values of
    # the InstanceType and State.Code fields.

    RESPONSE=$(aws ec2 describe-instances \
                   --query 'Reservations[*].Instances[*].[State.Name, InstanceType]' \
                   --filters Name=instance-id,Values="$INSTANCE_ID" \
                   --output text \
               )

    if [[ $? -ne 0 ]] || [[ -z "$RESPONSE" ]]; then
        # There was no response, so no such instance.
        return 1        # 1 in Bash script means error/false
    fi

    # If we got a response, the instance exists.
    # Retrieve the values of interest and set them as global variables.
    EXISTING_STATE=$(echo "$RESPONSE" | cut -f 1 )
    EXISTING_TYPE=$(echo "$RESPONSE" | cut -f 2 )

    return 0        # 0 in Bash script means no error/true
}

######################################
#
#  See header at top of this file
#
######################################

function change_ec2_instance_type {

    function usage() (
        echo ""
        echo "This function changes the instance type of the specified instance."
        echo "Parameter:"
        echo "  -i  Specify the instance ID whose type you want to modify."
        echo "  -t  Specify the instance type to convert the instance to."
        echo "  -f  If the instance was originally running, this option prevents"
        echo "      the script from asking permission before stopping the instance."
        echo "  -r  Start instance after changing the type."
        echo "  -v  Enable verbose logging."
        echo ""
    )

    local FORCE RESTART REQUESTED_TYPE INSTANCE_ID VERBOSE OPTION RESPONSE ANSWER
    local OPTIND OPTARG # Required to use getopts command in a function.

    # Set default values.
    FORCE=false
    RESTART=false
    REQUESTED_TYPE=""
    INSTANCE_ID=""
    VERBOSE=false

    # Retrieve the calling parameters.
    while getopts "i:t:frvh" OPTION; do
        case "${OPTION}"
        in
            i)  INSTANCE_ID="${OPTARG}";;
            t)  REQUESTED_TYPE="${OPTARG}";;
            f)  FORCE=true;;
            r)  RESTART=true;;
            v)  VERBOSE=true;;
            h)  usage; return 0;;
            \?) echo "Invalid parameter"; usage; return 1;;
        esac
    done

    if [[ -z "$INSTANCE_ID" ]]; then
        errecho "ERROR: You must provide an instance ID with the -i parameter."
        usage
        return 1
    fi

    if [[ -z "$REQUESTED_TYPE" ]]; then
        errecho "ERROR: You must provide an instance type with the -t parameter."
        usage
        return 1
    fi

    iecho "Parameters:\n"
    iecho "    Instance ID:   $INSTANCE_ID"
    iecho "    Requests type: $REQUESTED_TYPE"
    iecho "    Force stop:    $FORCE"
    iecho "    Restart:       $RESTART"
    iecho "    Verbose:       $VERBOSE"
    iecho ""

    # Check that the specified instance exists.
    iecho -n "Confirming that instance $INSTANCE_ID exists..."
    get_instance_info "$INSTANCE_ID"
    # If the instance doesn't exist, the function returns an error code <> 0.
    if [[ ${?} -ne 0 ]]; then
        errecho "ERROR: I can't find the instance \"$INSTANCE_ID\" in the current AWS account."
        return 1
    fi
    # Function get_instance_info has returned two global values:
    #   $EXISTING_TYPE  -- The instance type of the specified instance
    #   $EXISTING_STATE -- Whether the specified instance is running

    iecho "confirmed $INSTANCE_ID exists."
    iecho "      Current type: $EXISTING_TYPE"
    iecho "      Current state code: $EXISTING_STATE"

    # Are we trying to change the instance to the same type?
    if [[ "$EXISTING_TYPE" == "$REQUESTED_TYPE" ]]; then
        errecho "ERROR: Can't change instance type to the same type: $REQUESTED_TYPE."
        return 1
    fi

    # Check if the instance is currently running.
    # 16="running"
    if [[ "$EXISTING_STATE" == "running" ]]; then
        # If it is, we need to stop it.
        # Do we have permission to stop it?
        # If -f (FORCE) was set, we do.
        # If not, we need to ask the user.
        if [[ $FORCE == false ]]; then
            while true; do
                echo ""
                echo "The instance $INSTANCE_ID is currently running. It must be stopped to change the type."
                read -r -p "ARE YOU SURE YOU WANT TO STOP THE INSTANCE? (Y or N) " ANSWER
                case $ANSWER in
                    [yY]* )
                        break;;
                    [nN]* )
                        echo "Aborting."
                        exit;;
                    * )
                        echo "Please answer Y or N."
                        ;;
                esac
            done
        else
            iecho "Forcing stop of instance without prompt because of -f."
        fi

        # stop the instance
        iecho -n "Attempting to stop instance $INSTANCE_ID..."
        RESPONSE=$( aws ec2 stop-instances \
                        --instance-ids "$INSTANCE_ID" )

        if [[ ${?} -ne 0 ]]; then
            echo "ERROR - AWS reports that it's unable to stop instance $INSTANCE_ID.\n$RESPONSE"
            return 1
        fi
        iecho "request accepted."
    else
        iecho "Instance is not in running state, so not requesting a stop."
    fi;

    # Wait until stopped.
    iecho "Waiting for $INSTANCE_ID to report 'stopped' state..."
    aws ec2 wait instance-stopped \
        --instance-ids "$INSTANCE_ID"
    if [[ ${?} -ne 0 ]]; then
        echo "\nERROR - AWS reports that Wait command failed.\n$RESPONSE"
        return 1
    fi
    iecho "stopped.\n"

    # Change the type - command produces no output.
    iecho "Attempting to change type from $EXISTING_TYPE to $REQUESTED_TYPE..."
    RESPONSE=$(aws ec2 modify-instance-attribute \
                   --instance-id "$INSTANCE_ID" \
                   --instance-type "{\"Value\":\"$REQUESTED_TYPE\"}"
              )
    if [[ ${?} -ne 0 ]]; then
        errecho "ERROR - AWS reports that it's unable to change the instance type for instance $INSTANCE_ID from $EXISTING_TYPE to $REQUESTED_TYPE.\n$RESPONSE"
        return 1
    fi
    iecho "changed.\n"

    # Restart if asked
    if [[ "$RESTART" == "true" ]]; then

        iecho "Requesting to restart instance $INSTANCE_ID..."
        RESPONSE=$(aws ec2 start-instances \
                        --instance-ids "$INSTANCE_ID" \
                   )
        if [[ ${?} -ne 0 ]]; then
            errecho "ERROR - AWS reports that it's unable to restart instance $INSTANCE_ID.\n$RESPONSE"
            return 1
        fi
        iecho "started.\n"
        iecho "Waiting for instance $INSTANCE_ID to report 'running' state..."
        RESPONSE=$(aws ec2 wait instance-running \
                       --instance-ids "$INSTANCE_ID" )
        if [[ ${?} -ne 0 ]]; then
            errecho "ERROR - AWS reports that Wait command failed.\n$RESPONSE"
            return 1
        fi

        iecho "running.\n"

    else
        iecho "Restart was not requested with -r.\n"
    fi
}


# $(change_ec2_instance_type -i i-01d8251d726577f33 -t t2.small -v -r)
