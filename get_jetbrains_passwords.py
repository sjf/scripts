import re
import subprocess

if __name__ == '__main__':
    # located in project folder .idea/dataSources.xml
    with open('dataSources.xml', 'r') as f:
        data = f.read()
        data_sources = sorted(re.findall(r".*data-source.*name=\"(.*?)\".*uuid=\"(.*?)\".*", data))
        for name, uuid in data_sources:
            command = f'security find-generic-password -l "IntelliJ Platform DB — {uuid}" -w'
            result = subprocess.run(command, shell=True, capture_output=True, text=True)
            print(f"{name}={result.stdout.strip()}")
