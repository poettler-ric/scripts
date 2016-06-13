#!/usr/bin/python3

"""
Renders a jinja template with data taken from a yaml file.

Usage::

    usage: jrender.py [-h] template data

    Render a jinja template with data parsed from a yaml file.

    positional arguments:
      template    jinja2 template file to parse
      data        yaml file to parse

    optional arguments:
      -h, --help  show this help message and exit
"""

from argparse import ArgumentParser

from jinja2 import Environment, FileSystemLoader
import yaml


def render(template_file, data_file):
    """Renders a jinja template with data taken from a yaml file."""
    jinja_env = Environment(loader=FileSystemLoader('.'))
    template = jinja_env.get_template(template_file)
    with open(data_file) as file:
        data = yaml.load(file)
        return template.render(data)


if __name__ == '__main__':
    # pylint: disable=C0103
    description = "Render a jinja template with data parsed from a yaml file."
    # pylint: enable=C0103

    parser = ArgumentParser(description=description)  # pylint: disable=C0103
    parser.add_argument('template', help="jinja2 template file to parse")
    parser.add_argument('data', help="yaml file to parse")
    config = parser.parse_args()  # pylint: disable=C0103

    print(render(config.template, config.data))
