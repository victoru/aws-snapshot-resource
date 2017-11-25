export TMPDIR=${TMPDIR:-/tmp}

metadata_basic() {
  snapshot_json=$1 
  prefix=$2

  local snapshotCreateTime=$( echo $snapshot_json | jq .SnapshotCreateTime)
  local snapshotIdentifier=$( echo $snapshot_json | jq .${prefix}SnapshotIdentifier)
  local identifier=$( echo $snapshot_json | jq .${prefix}Identifier)

  jq ". + [
    {name: \"SnapshotCreateTime\", value: ${snapshotCreateTime}},
    {name: \"${prefix}SnapshotIdentifier\", value: ${snapshotIdentifier}},
    {name: \"${prefix}Identifier\", value: ${identifier}, type: \"time\"}
  ]"
}

get_kind_prefix() {
  payload=$1
  kind=$(jq -r '.source.kind // "instance"' < $payload)
  case "$kind" in
    instance)
      echo -n DB
      ;;
    cluster)
      echo -n DBCluster
      ;;
    *)
      echo "unknown kind: $kind"
      exit 44
      ;;
  esac
}

describe_cmd() {
  local payload=$1
  local snapshot_identifier=$2

  local identifier=$(jq -r '.source.identifier // ""' < $payload)
  local kind=$(jq -r '.source.kind // "instance"' < $payload)
  local type=$(jq -r '.source.type // "automated"' < $payload)
  local region=$(jq -r '.source.region // ""' < $payload)

  case "$kind" in
    instance)
      local snapshot_identifier_flag=--db-snapshot-identifier
      local rds_sub_cmd=describe-db-snapshots
      ;;
    cluster)
      local snapshot_identifier_flag=--db-cluster-snapshot-identifier
      local rds_sub_cmd=describe-db-cluster-snapshots
      ;;
    *)
      echo "unknown kind: $kind"
      ;;
  esac

  local snapshot_type_arg="--snapshot-type=$type"
  if [ "$type" = shared ]; then
    local include_shared_arg="--include-shared"
  fi

  if [ -n "$region" ]; then
    local region_arg="--region=$region"
  fi

  if [ -n "$snapshot_identifier" ]; then
    local snif='| [?'"$prefix"'SnapshotIdentifier==`'"$snapshot_identifier"'`]'
  fi

  prefix=$(get_kind_prefix $payload)
  aws rds "$rds_sub_cmd" \
      --output json \
      --query ''"$prefix"'Snapshots[?'"$prefix"'Identifier==`'"$identifier"'`]
            | sort_by([], &SnapshotCreateTime) '"$snif"'' \
      $region_arg $snapshot_type_arg $include_shared_arg
}

get_versions() {
  local payload=$1
  jsonlist=$(describe_cmd $payload)
  prefix=$(get_kind_prefix $payload)
  echo $jsonlist | jq -c "map({ref: .${prefix}SnapshotIdentifier})"
}

describe_single_snapshot() {
  payload=$1
  snapshot_identifier=$2
  jsonlist=$(describe_cmd $payload $snapshot_identifier)
  echo $jsonlist | jq -c ".[0]"
}

configure_credentials() {
  local region=$(jq -r '.source.region // ""' < $1)
  local AWS_ACCESS_KEY_ID="$(jq -r '.source.aws_access_key_id // ""' < $1)"
  local AWS_SECRET_ACCESS_KEY="$(jq -r '.source.aws_secret_access_key // ""' < $1)"

  if [ "$AWS_ACCESS_KEY_ID" != "" -a "$AWS_SECRET_ACCESS_KEY" != "" ]; then
    echo export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
    echo export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
  fi

  aws rds describe-db-instances --region $region > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "unable to obtain AWS credentials"
    exit 44
  fi
}
