# AWS Snapshot Resoruce

Tracks AWS snapshots 

## AWS IAM permissions

The following permissions are required for this resource to run properly.

```
rds:DescribeDBClusterSnapshots
rds:DescribeDBSnapshots
```

## Source Configuration

* `identifier`: *Required.* The identifier of the snapshot kind to restore. i.e.
   The value of `.DBClusterSnapshot.DBClusterIdentifier` if the snapshot is from 
   a cluster or `.DBSnapshot.DBInstanceIdentifier` if the snapshot is from an instance.

* `kind`: *Optional.* The kind of snapshot to track (i.e. cluster or instance.) 
  Defaults to "instance"

* `type`: *Optional.* SnapshotType to filter by. i.e. automated (default), 
  shared, manual 

* `region`: *Required.* Region there the snapshot is located

* `aws_access_key_id`: *Optional.* AWS access key ID for static credentials. 
* `aws_secret_access_key`: *Optional.* AWS secret access key for static credentials

### Example

Given the following DB cluster snapshot

```json
{
  "SnapshotCreateTime": "2017-11-01T00:00:00.644Z",
  "DBClusterIdentifier": "prod-db-cluster",
  "Status": "available",
  "DBClusterSnapshotIdentifier": "arn:aws:rds:us-east-1:xxxxxxxxxxxx:cluster-snapshot:prod-db-cluster-2017-11-01-00-00-shared",
  "SnapshotType": "automated",
  "ClusterCreateTime": "2017-05-05T00:00:00.888Z"
}
```

The following configuration will keep track of the latest snapshot versions 
created from the `prod-db-cluster` DBCluster

``` yaml
resources:
- name: prod-db-cluster-snapshot
  type: aws-snapshot
  source:
  	identifier: prod-db-cluster
  	kind: cluster
    type: automated
```


```json
{
  "SnapshotCreateTime": "2017-11-01T00:00:00.644Z",
  "DBInstanceIdentifier": "shared-db",
  "Status": "available",
  "DBSnapshotIdentifier": "arn:aws:rds:us-east-1:xxxxxxxxxxxx:cluster-snapshot:shared-db-2017-11-01-00-00-shared",
  "SnapshotType": "shared",
  "InstanceCreateTime": "2017-05-05T00:00:00.888Z"
}
```
Resource configuration for a shared
``` yaml
resources:
- name: shared-db-snapshot
  type: aws-snapshot
  source:
  	identifier: shared-db
  	kind: instance
    type: shared
```


## Behavior

### `check`: Check for new snapshots by kind and type.

The latest snapshot is queried from AWS

### `in`: Clone the repository, at the given ref.

Fetches metadata data about the given snapshot

#### Parameters

None


#### Additional files populated

 * `SnapshotIdentifier`: 
 * `DBClusterSnapshotIdentifier` or `DBSnapshotIdentifier`: same as 
   `SnapshotIdentifier` but using the same property name for the snapshots kind.

### `out`: Noop

## Development

### Prerequisites

TBD

### Running the tests

The tests have been embedded with the `Dockerfile`; ensuring that the testing
environment is consistent across any `docker` enabled platform. When the docker
image builds, the test are run inside the docker container, on failure they
will stop the build.

Run the tests with the following command:

```sh
docker build -t aws-snapshot-resource .
```

### Contributing

Please make all pull requests to the `master` branch and ensure tests pass
locally.
