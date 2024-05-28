# Volume Sweeper

A tool to scan and clean cloud infrastruture for unattached block volumes without kubernetes clusters persistent volumes.

## Supported Clouds

- [x] OCI
- [ ] AWS.
- [ ] GCP.

## Supported Kubernetes

Any distributions + v1.19.

## Prerequisits

1. Kubernetes: a service account with read/update access to the cluster is required, scoped to `PV` resources.
2. Cloud: access is required for block volumes service (BV) with read and delete roles.


## Installation

```bash
$ gem install volume_sweeper
```

## Usage

To scan and generate a report:

```bash
volume_sweeper --account-id <ID> --cloud aws|oci
```

To apply deletion for unattached block volumes:

```bash
volume_sweeper --mode delete
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/abarrak/volume_sweeper.

## License

[MIT License](https://opensource.org/licenses/MIT).
