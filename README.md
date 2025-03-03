# Volume Sweeper
[![CI (tests)](https://github.com/abarrak/volume_sweeper/actions/workflows/ci.yml/badge.svg)](https://github.com/abarrak/volume_sweeper/actions/workflows/ci.yml) [![Gem Version](https://badge.fury.io/rb/volume_sweeper.svg)](https://badge.fury.io/rb/volume_sweeper) [![Test Coverage](https://api.codeclimate.com/v1/badges/b9d24a336e67236937dd/test_coverage)](https://codeclimate.com/github/abarrak/volume_sweeper/test_coverage) [![Maintainability](https://api.codeclimate.com/v1/badges/b9d24a336e67236937dd/maintainability)](https://codeclimate.com/github/abarrak/volume_sweeper/maintainability) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A tool to scan and clean cloud infrastruture for unattached block volumes without kubernetes clusters persistent volumes.

* [Supported Clouds](#supported-clouds)
* [Supported Kubernetes](#supported-kubernetes)
* [Prerequisits](#prerequisits)
* [Installation](#installation)
* [Usage](#usage)
* [Documentation](#documentation)
  + [Design](#design)
  + [Algorithm](#algorithm)
  + [Deployment](#deployment)
  + [Code](#code)
  + [Limitations](#limitations)
* [Contributing](#contributing)
* [License](#license)

## Supported Clouds

- [x] OCI
- [x] AWS.
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
volume_sweeper --account-id <ID> --cloud aws|oci --region <region>
```

To apply deletion for unattached block volumes:

```bash
volume_sweeper --mode delete
```

For all options:

```bash
volume_sweeper -h
```

<img src="https://github.com/user-attachments/assets/0f73d0c9-b419-4c4a-ae07-405cf693928c" width="100%" />

--- 
## Documentation

This tool tracks down unused block volumes in cloud accounts to clean once certain conditions met.

### Design

<img src="https://github.com/user-attachments/assets/fd4eb825-68e8-4155-bea4-b6d9890ca9e3" width="80%" />

### Algorithm

```pascal
FOR each_cluster IN oci|aws:
  A] Fetch PVs (name, volHandle)
  B] Fetch BLOCK VOL where (instance_attachment) = nil
  C] Compare A ^ B to Extract Bx NOT IN Ax
     THEN:
       DEL [C] result
END
```

### Deployment

- Models:
  * Can be run on demand as a CLI locally or remotely.
  * background processing [CronJob].
- Has 2 modes: audit and delete.
- Notifications for email and teams channels.

### Code

- The library is a ruby CLI-based application.
- Cluster integration layer is unified, using Kubernetes REST API server.
- The cloud integration layer is written in provider design pattern. 
- Functionality can be extended for different cloud providers per the interface contract.
    
  ```ruby
  module VolumeSweeper
    module Providers
      class Base
        attr_reader :base_link
  
        def initialize **kwargs
          ...
        end
  
        def scan_volumes; end
        def delete_volumes ids_list; end
      end
    end
  end
    ```

### Limitations

- No support for multiple clusters in the accounts or compartment.

--- 
## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/abarrak/volume_sweeper.

## License

[MIT License](https://opensource.org/licenses/MIT).
