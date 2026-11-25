import os
import subprocess
import socket

cwd = os.getcwd()
logs_dir = f"{cwd}/logs"

broker_ip = socket.gethostbyname(os.environ['MT_MQTT_BROKER'].split(":")[0])

s_patterns = [
    f"s/{os.environ['MT_MQTT_BROKER']}/*REDACTED*/g",
    f"s/{broker_ip}/*REDACTED*/g",
    f"s/Password:.*/*REDACTED*/",
    f"s/User [Nn]ame:.*/*REDACTED*/",
]

for p in s_patterns:
    subprocess.run(['find', logs_dir, '-type', 'f', '-exec', 'sed', '-i', p, '{}', '+'])

subprocess.run(['git', 'add', 'logs'])

exit(0)
