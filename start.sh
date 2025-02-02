#!/bin/sh

ETC_DIR=/fluentd/etc
SUPPORTED_STORES="stdout s3 cloudwatch splunk-hec datadog azure-loganalytics sumologic"

get_intput_conf_name() {
    echo $1 | awk '{ gsub(/ /,""); print tolower($0) }'
}

get_output_conf_stores() {
    for s in $SUPPORTED_STORES; do
        contains=$(echo $LOG_EXPORT_CONTAINER_OUTPUT | grep -wq $s; echo $?)
        if [ $contains -eq 0 ]; then
            export conf="$conf $s"
        fi
    done
    if [ "$conf" == "" ]; then
        echo "stdout"
    else
        echo $conf
    fi
}

get_input_conf_filename() {
    conf=$(get_intput_conf_name $LOG_EXPORT_CONTAINER_INPUT)
    if [ "$conf" == "csv" ]; then
        echo $ETC_DIR/input-rsyslog-csv.conf
    else
        echo $ETC_DIR/input-rsyslog-json.conf
    fi
}

get_classify_conf_filename() {
    conf=$(get_intput_conf_name $LOG_EXPORT_CONTAINER_INPUT)
    if [ "$conf" == "csv" ]; then
        echo $ETC_DIR/classify-csv.conf
    else
        echo $ETC_DIR/classify-json.conf
    fi
}

get_output_conf() {
  new_line=""
  for s in $(get_output_conf_stores); do
    export stores="$stores$new_line$(cat $ETC_DIR/output-$s.conf)"
    if [ "$new_line" = "" ]; then
      new_line=$'\n'
    fi
  done
  envsubst < $ETC_DIR/output-template.conf
}

create_fluent_conf() {
    cat $(get_input_conf_filename) $(get_classify_conf_filename) > $ETC_DIR/fluent.conf
    cat $ETC_DIR/process.conf >> $ETC_DIR/fluent.conf
    echo "$(get_output_conf)" >> $ETC_DIR/fluent.conf
}

create_fluent_conf
exec fluentd -c $ETC_DIR/fluent.conf -p /fluentd/plugins
