#!/bin/bash
# Copyright (c) 2021 Samuel T. Denton, III

usage="Usage: $(/bin/basename $0) [-h] [-o <OPTSTRING>] [-n <FULL_NAME>] [-y <YEAR>] <SCRIPTNAME>"
while getopts "ho:n:y:" arg
do
        case "${arg}" in
        h)
                /bin/cat <<HELP
Create a bash script from boiler-plate.

$usage

FULL_NAME and YEAR can also be set via environment variables.  If not
set, YEAR defaults to the current year, and FULL_NAME defaults to the
first sub-field of the GECOS field of the current user's passwd entry."
HELP
                exit 0
                ;;
        o)
                OPTSTRING=${OPTARG}
                ;;
        n)
                FULL_NAME=${OPTARG}
                ;;
        y)
                YEAR=${OPTARG}
                ;;
        \?)
                echo "Error: Unknown option -${OPTARG}" >&2
                echo "$usage" >&2
                exit 1
                ;;
        esac
done
shift $((OPTIND-1))

: ${OPTSTRING:=h}
: ${FULL_NAME:=$( /bin/getent passwd $LOGNAME | /bin/cut -d: -f5 | /bin/cut -d, -f1 )}
: ${YEAR:=$( /bin/date +%Y )}

SCRIPTNAME=${1:?SCRIPTNAME missing
$usage}

set -o noclobber
{

HELP='Usage: $(/bin/basename $0)'
for flag in $( echo ${OPTSTRING} | /bin/grep -E -o '[a-z]:?' )
do
        if [[ ${flag} =~ .*: ]]
        then
                HELP="$HELP [-"${flag%:}" <ARG>]"
        else
                HELP="$HELP [-"${flag%:}"]"
        fi
done

/bin/cat <<TEMPLATE
#!/bin/bash
# Copyright (c) $YEAR $FULL_NAME

usage="$HELP"
TEMPLATE

/bin/sed -e "s/{{OPTSTRING}}/${OPTSTRING}/g" <<'TEMPLATE'
while getopts "{{OPTSTRING}}" arg
do
        case "${arg}" in
TEMPLATE

for flag in $( echo ${OPTSTRING} | /bin/grep -E -o '[a-z]:?' )
do
        if [[ ${flag} =~ .*: ]]
        then
                sed -e "s/{{FLAG}}/${flag%:}/g" <<'TEMPLATE'
        {{FLAG}})
                opt_{{FLAG}}=${OPTARG}
                ;;
TEMPLATE
        elif [[ ${flag} == h ]]
        then
                /bin/sed -e "s/{{FLAG}}/${flag}/g" <<'TEMPLATE'
        {{FLAG}})
                echo "$usage"; exit
                ;;
TEMPLATE
        else
                sed -e "s/{{FLAG}}/${flag}/g" <<'TEMPLATE'
        {{FLAG}})
                opt_{{FLAG}}=true
                ;;
TEMPLATE
        fi
done

[[ ${OPTSTRING} =~ ^: ]] && cat <<'TEMPLATE'
        :)
                echo "Error: -${OPTARG} requires an argument" >&2
                echo "$usage" >&2
                exit 1
                ;;
TEMPLATE

/bin/cat <<'TEMPLATE'
        \?)
                echo "Error: Unknown option -${OPTARG}" >&2
                echo "$usage" >&2
                exit 1
                ;;
        esac
done
shift $((OPTIND-1))
REQUIRED=${1:?REQUIRED missing
$usage}
TEMPLATE

} >${SCRIPTNAME}

/bin/chmod +x ${SCRIPTNAME}
