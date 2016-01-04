{% from "sensu/pillar_map.jinja" import sensu with context %}

/etc/default/sensu:
  file.managed:
    - source: salt://sensu/files/etc-default-sensu
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: sensu

