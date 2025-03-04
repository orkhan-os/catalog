import os
import yaml
from jinja2 import Template
from mkdocs.plugins import BasePlugin
from mkdocs.config import config_options

def generate_apps():
    apps_dir = 'mkdocs/apps'
    template_path = 'mkdocs/apps/app.tpl.md'

    # Read template
    with open(template_path, 'r', encoding='utf-8') as f:
        template_content = f.read()
    template = Template(template_content)

    # Iterate over each app directory
    for app in os.listdir(apps_dir):
        app_path = os.path.join(apps_dir, app)
        data_file = os.path.join(app_path, 'data.yaml')
        md_file = os.path.join(app_path, app + '.md')

        if os.path.isdir(app_path) and os.path.exists(data_file):
            with open(data_file, 'r', encoding='utf-8') as f:
                metadata = yaml.safe_load(f)

            # Render the template with metadata
            rendered_md = template.render(**metadata)

            # Write the generated markdown
            with open(md_file, 'w', encoding='utf-8') as f:
                print("render file")
                f.write(rendered_md)

generate_apps()
