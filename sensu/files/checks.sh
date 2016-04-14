{%- from "sensu/pillar_map.jinja" import sensu with context %}
#!/bin/bash
curl -s http://access:granted@{{ sensu.rabbitmq.host }}:4567/clients/{{ grains['fqdn'] }}-{{ grains['machine_id'] }}
