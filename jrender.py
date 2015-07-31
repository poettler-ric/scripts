#!/usr/bin/python

from jinja2 import Environment, FileSystemLoader
import argparse
import yaml

parser = argparse.ArgumentParser(description="Render a jinja template with data parsed from a yaml file.")
parser.add_argument('template', help="jinja2 template file to parse")
parser.add_argument('data', help="yaml file to parse")
config = parser.parse_args()

jinja_env = Environment(loader=FileSystemLoader('.'))
template = jinja_env.get_template(config.template)
with open(config.data) as f:
    data = yaml.load(f)
    print(template.render(data));

