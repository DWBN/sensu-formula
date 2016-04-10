{% from "sensu/pillar_map.jinja" import sensu with context %}
{% if grains['os_family'] != 'Windows' %}
/etc/default/sensu:
  file.managed:
    - source: salt://sensu/files/etcdefaultsensu
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: sensu
{% endif %}

