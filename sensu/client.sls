{% from "sensu/pillar_map.jinja" import sensu with context %}
{% from "sensu/service_map.jinja" import services with context %}

include:
  - sensu
  - sensu.rabbitmq_conf
  - sensu.etcdefaultsensu

/etc/sensu/conf.d/client.json:
  file.managed:
    - source: salt://sensu/files/client.json
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: sensu

/etc/sensu/plugins:
  file.recurse:
    - source: salt://sensu/files/plugins
    - file_mode: 555
    - require:
      - pkg: sensu
    - require_in:
      - service: sensu-client
    - watch_in:
      - service: sensu-client

sensu-client:
  service.running:
    - enable: True
    - require:
      - file: /etc/sensu/conf.d/client.json
      - file: /etc/sensu/conf.d/rabbitmq.json
      - file: /etc/default/sensu
    - watch:
      - file: /etc/sensu/conf.d/*

/etc/rc0.d/K25delete-sensu-client.sh:
  file.managed:
    - mode: 775
    - source: salt://sensu/files/delete-sensu-client.sh
    - template: jinja



{% if sensu.client.nagios_plugins %}
{{ services.nagios_plugins }}:
  pkg:
    - installed
    - require_in:
      - service: sensu-client
{% endif %}

{% if sensu.client.embedded_ruby %}
{% set gem_path = '/opt/sensu/embedded/bin/gem' %}
{% else %}
{% set gem_path = 'gem' %}
{% endif %}

{% set gem_list = salt['pillar.get']('sensu:client:install_gems', []) %}
{% for gem in gem_list %}
client_install_{{ gem }}:
  cmd.run:
    - name: {{ gem_path }} install {{ gem }} --no-ri --no-rdoc
    - unless: {{ gem_path }} list | grep -q {{ gem }}
{% endfor %}
