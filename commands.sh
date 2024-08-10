# First, create a dedicated Linux user for Prometheus and download Prometheus:
sudo useradd --system --no-create-home --shell /bin/false prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.47.1/prometheus-2.47.1.linux-amd64.tar.gz

# 2. Extract Prometheus files, move them, and create directories:
tar -xvf prometheus-2.47.1.linux-amd64.tar.gz
cd prometheus-2.47.1.linux-amd64/
sudo mkdir -p /data /etc/prometheus
sudo mv prometheus promtool /usr/local/bin/
sudo mv consoles/ console_libraries/ /etc/prometheus/
sudo mv prometheus.yml /etc/prometheus/prometheus.yml


# 3. Set ownership for directories:
sudo useradd prometheus
sudo chown -R prometheus:prometheus /etc/prometheus/ /data/

# 4. Create a systemd unit configuration file for Prometheus:
sudo vi /etc/systemd/system/prometheus.service

# 5 Add the following content to the file:
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=500
StartLimitBurst=5
[Service]
User=prometheus
Group=prometheus
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/data \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=0.0.0.0:9090 \
  --web.enable-lifecycle
[Install]
WantedBy=multi-user.target

# 5. Enable and start Prometheus:
sudo systemctl enable prometheus
sudo systemctl start prometheus
sudo systemctl status prometheus

#  Installing Node Exporter:
# Create a system user for Node Exporter and download Node Exporter:
sudo useradd --system --no-create-home --shell /bin/false node_exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz

# 2. Extract Node Exporter files, move the binary, and clean up:
tar -xvf node_exporter-1.6.1.linux-amd64.tar.gz
sudo mv node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter*

# 3. Create a systemd unit configuration file for Node Exporter:
sudo vi /etc/systemd/system/node_exporter.service

# 4. Add the following content to the file:
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=default.target

# 4. Enable and start Node Exporter:
sudo useradd -m -s /bin/bash node_exporter
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

# 5. Enable and start Node Exporter
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter
sudo systemctl status node_exporter

# Configure Prometheus Plugin Integration:
# 1 go to your EC2 and run →
cd /etc/prometheus

# 2. you have to edit the prometheus.yml file to moniter anything

scrape_configs:
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
  - job_name: 'jenkins'
    metrics_path: '/prometheus'
    static_configs:
      - targets: ['54.226.179.211:8080']

# a Check the validity of the configuration file →
promtool check config /etc/prometheus/prometheus.yml

# b. Reload the Prometheus configuration without restarting →
curl -X POST http://localhost:9090/-/reload

# go to your prometheus tab again and click on status and select targets you will there 
#is three targets present as we enter in yaml file for moniterning

#  Setup Grafana
# 1. Install Dependencies:
sudo apt-get update
sudo apt-get install -y apt-transport-https software-properties-common

# 2. Add the GPG Key for Grafana:
curl -fsSL https://packages.grafana.com/gpg.key | sudo tee /usr/share/keyrings/grafana-archive-keyring.gpg > /dev/null

# 3. Add the Grafana repository for Grafana stable releases:
echo "deb [signed-by=/usr/share/keyrings/grafana-archive-keyring.gpg] https://packages.grafana.com/oss/deb stable main" | sudo tee /etc/apt/sources.list.d/grafana.list > /dev/null

# 4. Update the package list and install Grafana:
sudo apt-get update
sudo apt-get install -y grafana
sudo systemctl enable grafana-server
sudo systemctl start grafana-server
sudo systemctl status grafana-server

# Go and browse http://public_ip:3000 to access your grafana web interface


# 5. Import Prometheus data source:
# Go to Grafana -> Data Sources -> + -> Prometheus
# Enter the URL: http://localhost:9090/  #http://localhost:9090/api/datasources
# Click on Save & Test

# 6. Create a new Grafana dashboard for Prometheus:
# Go to Grafana -> Dashboards -> + -> Add new -> Prometheus

# Import Dashbord
Select “Dashboard.”
Click on the “Import” dashboard option.
Enter the dashboard code you want to import (e.g., code 1860).
Click the “Load” button.

# 7. Add your Prometheus data source to the dashboard:
# Click on the "+" icon to add a new target
# Choose Prometheus as the data source
# Enter the URL: http://localhost:9090/api/v1/query

# other Commands for troubleshooting
curl http://localhost:9090/metrics
tail -f /var/log/prometheus/prometheus.log
tail -f /var/log/grafana/grafana.log

https://aakibkhan1.medium.com/project-11-deployment-of-chat-gpt-clone-app-on-kubernetes-using-terraform-and-jenkins-ci-cd-904d9460aaf5