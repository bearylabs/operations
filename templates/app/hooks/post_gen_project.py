import os

app_name = "{{ cookiecutter.app_name }}"
os.rename("application.yaml", os.path.join("..", f"{app_name}.yaml"))
