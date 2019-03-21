set -o errexit

# https://stackoverflow.com/questions/25288194/dont-display-pushd-popd-stack-across-several-bash-scripts-quiet-pushd-popd
# Quiet pushd popd
pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

declare -A PARSE_OPT
OPTIONS=()
OPTIONS+=("r;release;RELEASE;true;Path to the release repo")
OPTIONS+=("p;prefix;PREFIX;true;(Optional) prefix to add while copying")
OPTIONS+=("n;no-verify;NO-VERIFY;false;Disable verification step")
OPTIONS+=("s;push;PUSH;false;Push to git repo")
OPTIONS+=("h;help;HELP;false;Display this help message")
opt_len=${#OPTIONS[@]}

usage() {
  echo "Usage: ./deploy.sh [options] path/to/assignment"
  for i in `seq 0 $((opt_len-1))`
  do
    IFS=';'; OPT=(${OPTIONS[$i]}); unset IFS
    echo -e "\t-${OPT[0]} | --${OPT[1]}  ${OPT[4]}"
  done
  echo "Example: To deploy vector:"
  echo -e "\t./deploy.sh -r ../_release mp/vector -s"
  echo "Example: To deploy potd/my_strstr (without pushing):"
  echo -e "\t./deploy.sh -r ../_release potd/my_strstr -p potd/"

}

parse_opt() {
  shortform=""
  longform=""
  for i in `seq 0 $((opt_len-1))`
  do
    IFS=';'; OPT=(${OPTIONS[$i]}); unset IFS
    shortform+=${OPT[0]}
    longform+=${OPT[1]}
    if [ "${OPT[3]}" == "true" ]
    then
      longform+=":"
      shortform+=":"
    fi
    longform+=","
  done

  GETOPT_STR=`getopt -o ${shortform} --long ${longform} -n 'deploy' -- "$@"`
  if [ $? != 0 ] ; then usage; exit 1 ; fi
  eval set -- "$GETOPT_STR"

  parser='
  while true;
  do
    case "$1" in
  '
  for i in `seq 0 $((opt_len-1))`
  do
    IFS=';'; OPT=(${OPTIONS[$i]}); unset IFS
    case_str=""
    case_str+="-${OPT[0]} | --${OPT[1]} ) PARSE_OPT[${OPT[2]}]="
    count=1
    if [ "${OPT[3]}" == "true" ]
    then
      case_str+="\"\$2\""
      count=2
    else
      case_str+="true"
    fi
    case_str+="; shift ${count} ;;"
    case_str+=`echo -e "\n"`
    parser+=$case_str
  done
  parser+="* ) break;; esac; done;"
  eval $parser

  case $1 in
    -- ) shift ;;
  esac
  PARSE_OPT[_UNPARSED]=$@
}

parse_opt $@
if [ "${PARSE_OPT[HELP]}" == "true" ]
then
  usage; exit;
fi

_RELEASE=${PARSE_OPT[RELEASE]}
ASSIGNMENT=${PARSE_OPT[_UNPARSED]}
if [ "$ASSIGNMENT" == "" ] || \
  ! [ -e $_RELEASE ] || ! [ -e $ASSIGNMENT ]
then
  usage
  exit
fi
