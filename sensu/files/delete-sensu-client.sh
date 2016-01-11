{%- from "sensu/pillar_map.jinja" import sensu with context %}
#!/bin/bash

# chkconfig: 345 90 90
# description: Sensu monitoring framework client - Remove Client in stop

### BEGIN INIT INFO
# Provides:       sensu-client
# Required-Start: $remote_fs $network
# Required-Stop:  $remote_fs $network
# Default-Start:
# Default-Stop:   0 1 6
# Description:    Sensu monitoring framework client - Remove Client on stop
### END INIT INFO

curl -X DELETE http://access:granted@{{ sensu.rabbitmq.host }}:4567/clients/{{ grains['fqdn'] }}-{{ grains['machine_id'] }}
