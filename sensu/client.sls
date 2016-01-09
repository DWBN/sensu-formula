{% from "sensu/pillar_map.jinja" import sensu with context %}
{% from "sensu/service_map.jinja" import services with context %}
{% from "sensu/configfile_map.jinja" import files with context %}

include:
  - sensu
  - sensu.rabbitmq_conf
  - sensu.etcdefaultsensu

{% if grains['os_family'] == 'Windows' %}
/opt/sensu/bin/sensu-client.xml:
  file.managed:
    - source: salt://sensu/files/windows/sensu-client.xml
    - template: jinja
    - require:
      - pkg: sensu
sensu_install_dotnet35:
  cmd.run:
    - name: 'powershell.exe "Import-Module ServerManager;Add-WindowsFeature Net-Framework-Core"'
sensu_enable_windows_service:
  cmd.run:
    - name: 'sc create sensu-client start= delayed-auto binPath= c:\opt\sensu\bin\sensu-client.exe DisplayName= "Sensu Client"'
    - unless: 'sc query sensu-client'
{% endif %}
/etc/sensu/conf.d/client.json:
  file.serialize:
    - formatter: json
    - user: {{files.files.user}}
    - group: {{files.files.group}}
    {% if grains['os_family'] != 'Windows' %}
    - mode: 644
    {% endif %}
    - makedirs: True
    - dataset:
        client:
          name: {{ sensu.client.name }}
          address: {{ sensu.client.address }}
          subscriptions: {{ sensu.client.subscriptions }}
          safe_mode: {{ sensu.client.safe_mode }}
{% if sensu.client.get("command_tokens") %}
          command_tokens: {{ sensu.client.command_tokens }}
{% endif %}
    - require:
      - pkg: sensu

/etc/sensu/plugins:
  file.recurse:
    - source: salt://sensu/files/plugins
    {% if grains['os_family'] != 'Windows' %}
    - file_mode: 555
    {% endif %}
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
      - file: /etc/default/sensu

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

{% set gem_list = salt['pillar.get']('sensu:client:install_gems', []) %}
{% for gem in gem_list %}
install_{{ gem }}:
  gem.installed:
    - name: {{ gem }}
    {% if sensu.client.embedded_ruby %}
    - gem_bin: /opt/sensu/embedded/bin/gem
    {% else %}
    - gem_bin: None
    {% endif %}
    - rdoc: False
    - ri: False
{% endfor %}
