``` wget https://raw.githubusercontent.com/quenorha/mosquitto_tls/refs/heads/main/create_mosquitto_tls.sh && chmod +x create_mosquitto_tls.sh ```
``` docker run -d -p 8883:8883 --restart unless-stopped -v /root/mosquitto/config:/mosquitto/config eclipse-mosquitto ```
