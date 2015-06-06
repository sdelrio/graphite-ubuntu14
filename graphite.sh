#!/bin/bash

apt-get update

# Install Graphite
# there is a prompt asking to delete database when purging graphite, answer NO

DEBIAN_FRONTEND=noninteractive apt-get install graphite-web graphite-carbon -y

# Install PostgreSQL

apt-get install postgresql libpq-dev python-psycopg2 -y

# Create a Database User and Database 

# sudo -u postgres psql
# CREATE USER graphite WITH PASSWORD 'vagrant';
# CREATE DATABASE graphite WITH OWNER graphite;
# \q

sudo -u postgres psql -c "CREATE USER graphite WITH PASSWORD 'vagrant';"
sudo -u postgres psql -c "CREATE DATABASE graphite WITH OWNER graphite;"
sudo -u postgres psql -c "\list"

graphitelocalsettings=/etc/graphite/local_settings.py

sed -i "s/#SECRET_KEY.*$/SECRET_KEY='1234567890'/g" $graphitelocalsettings
sed -i "s/TIME_ZONE.*$/TIME_ZONE'Madrid\/Spain'/g" $graphitelocalsettings
sed -i "s/.*USE_REMOTE_USER_AUTHENTICATION.*$/USE_REMOTE_USER_AUTHENTICATION = True/g" $graphitelocalsettings

sed -i "s/'NAME': '\/var\/lib\/graphite\/graphite.db',/'NAME': 'graphite',/g" $graphitelocalsettings
sed -i "s/'ENGINE': 'django.db.backends.sqlite3',/'ENGINE': 'django.db.backends.postgresql_psycopg2',/g" $graphitelocalsettings
sed -i "s/'USER': '',/'USER': 'graphite',/g" $graphitelocalsettings
sed -i "s/'PASSWORD': '',/'PASSWORD': 'vagrant',/g" $graphitelocalsettings
sed -i "s/'HOST': '',/'HOST': '127.0.0.1',/g" $graphitelocalsettings

# Sync the Database

graphite-manage syncdb

carbonconfig=/etc/carbon/carbon.conf

echo "CARBON_CACHE_ENABLED=true" > /etc/default/graphite-carbon
sed -i "s/ENABLE_LOGROTATION = False/ENABLE_LOGROTATION = True/g" $carbonconfig

# Storage aggregation

cp /usr/share/doc/graphite-carbon/examples/storage-aggregation.conf.example /etc/carbon/storage-aggregation.conf

# Setting Storage Schema and Aggretation

storageschema=/etc/carbon/storage-schemas.conf

cat >> $storageschema << EOF
[test]
pattern = ^test\.
retentions = 10s:10m,1m:1h,10m:1d

[collectd]
pattern = ^collectd.*
retentions = 10s:1d,1m:7d,10m:1y

[carbon]
pattern = ^carbon\.
retentions = 60:90d

[default_1min_for_1day]
pattern = .*
retentions = 60s:1d

EOF

service carbon-cache stop   
sleep 5
service carbon-cache start   

# Install and configure apache

apt-get install apache2 libapache2-mod-wsgi -y
a2dissite 000-default
cp /usr/share/graphite-web/apache2-graphite.conf /etc/apache2/sites-available
a2ensite apache2-graphite

apachegraphiteconf=/etc/apache2/sites-available/apache2-graphite.conf

sed -i "s/<\/VirtualHost>//g" $apachegraphiteconf
cat >> $apachegraphiteconf << EOF

        <Location "/server-status">
            SetHandler server-status
            Require all granted
        </Location>
</VirtualHost>
EOF

service apache2 reload

# Install Collectd

apt-get install collectd collectd-utils -y

# Configure Collectd 

collectdconf=/etc/collectd/collectd.conf

sed -i 's/Hostname.*$/Hostname "graph_host"/g' $collectdconf

sed -i 's/#LoadPlugin apache/LoadPlugin apache/g' $collectdconf
sed -i 's/#LoadPlugin cpu/LoadPlugin cpu/g' $collectdconf
sed -i 's/#LoadPlugin df/LoadPlugin df/g' $collectdconf
sed -i 's/#LoadPlugin entropy/LoadPlugin entropy/g' $collectdconf
sed -i 's/#LoadPlugin interface/LoadPlugin interface/g' $collectdconf
sed -i 's/#LoadPlugin load/LoadPlugin load/g' $collectdconf
sed -i 's/#LoadPlugin memory/LoadPlugin memory/g' $collectdconf
sed -i 's/#LoadPlugin processes/LoadPlugin processes/g' $collectdconf
sed -i 's/#LoadPlugin rrdtool/LoadPlugin rrdtool/g' $collectdconf
sed -i 's/#LoadPlugin users/LoadPlugin users/g' $collectdconf
sed -i 's/#LoadPlugin write_graphite/LoadPlugin write_graphite/g' $collectdconf

cat >> $collectdconf << EOF
<Plugin apache>
    <Instance "Graphite">
        URL "http://localhost/server-status?auto"
        Server "apache"
    </Instance>
</Plugin>

<Plugin df>
    Device "/dev/sda"
    MountPoint "/"
    FSType "ext3"
</Plugin>

<Plugin interface>
    Interface "eth0"
    IgnoreSelected false
</Plugin>

<Plugin write_graphite>
    <Node "graphing">
        Host "localhost"
        Port "2003"
        Protocol "tcp"
        LogSendErrors true
        Prefix "collectd."
        StoreRates true
        AlwaysAppendDS false
        EscapeCharacter "_"
    </Node>
</Plugin>

EOF

service collectd stop
service collectd start


