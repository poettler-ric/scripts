#!/usr/bin/python3

"""Download images from wallhaven.cc

Usage::

    usage: wallhaven.py [-h] [-c CONFIG] [-u USERAGENT] [-d DIR] [-l LOGIN]
                        [-p PASSWORD] [-t] [-w] [-s] [-n]
                        query [query ...]

    Download images from wallhaven.cc

    positional arguments:
      query                 string to search for on wallhaven

    optional arguments:
      -h, --help            show this help message and exit
      -c CONFIG, --config CONFIG
                            configuration file (default: ~/.wallhaven.yaml)
      -u USERAGENT, --userAgent USERAGENT
                            User-Agent to use for the requests
      -d DIR, --dir DIR     output directory
      -l LOGIN, --login LOGIN
                            login for wallhaven
      -p PASSWORD, --password PASSWORD
                            password for wallhaven
      -t, --tag             treat query as tag name
      -w, --sfw             get suitable-for-work wallpapers
      -s, --sketchy         get sketchy wallpapers
      -n, --nsfw            get not-suitable-for-work wallpapers

Config File
===========
The following variables can be set in the config file:
* userAgent - User-Agent to use for the requests
* dir - output directory
* login - login for wallhaven
* password - password for wallhaven
* sfw (on|off) - get suitable-for-work wallpapers
* sketchy (on|off) - get sketchy wallpapers
* nsfw (on|off) - get not-suitable-for-work wallpapers
"""


from argparse import ArgumentParser
from getpass import getpass
from http.cookiejar import CookieJar
from itertools import count
from os import makedirs
from os.path import expanduser, isdir, isfile
from sys import stderr
from urllib.parse import quote, urlencode
from urllib.request import build_opener, install_opener, urlopen, urlretrieve, \
    HTTPCookieProcessor
import os.path as path

from bs4 import BeautifulSoup
import yaml


__DEFAULT_CONFIG_FILE = '~/.wallhaven.yaml'
__QUERY_URL_TEMPLATE = 'https://alpha.wallhaven.cc/search?q={}&purity={}'
__INFO_URL_TEMPLATE = 'https://alpha.wallhaven.cc/wallpaper/{}'
__LOGIN_URL = 'https://alpha.wallhaven.cc/auth/login'


def configure_urllib(agent):
    """Concigure urllib to accept cookies and set the user-agent"""
    opener = build_opener(HTTPCookieProcessor(CookieJar()))
    opener.addheaders = [('User-Agent', agent)]
    install_opener(opener)


def get_query(query, output_dir, purity):
    """Downloads all images of a given query"""
    _get_images(__QUERY_URL_TEMPLATE.format(quote(query), purity),
                path.join(output_dir, query))


def get_tag(query, output_dir, purity):
    """Downloads all images of a given tag"""
    _get_images(
        __QUERY_URL_TEMPLATE.format(quote('"{}"'.format(query)), purity),
        path.join(output_dir, "tag-" + query))


def _get_images(url, output_dir):
    """Downloads all images of a given url"""
    # iterate through all pages
    for i in count(1):
        with urlopen((url + '&page={}').format(i)) as content:
            soup = BeautifulSoup(content, 'lxml')
            # get image ids
            ids = [j.get('href').split('/')[-1]
                   for j in soup.find_all('a', 'preview')]
            if not len(ids):
                # if there are no images we reached the last page
                break
            for j in ids:
                download_image(j, output_dir)


def download_image(image_id, output_dir):
    """Downloads an image with a given id"""
    output_dir = expanduser(output_dir)
    with urlopen(__INFO_URL_TEMPLATE.format(image_id)) as content:
        soup = BeautifulSoup(content, 'lxml')
        # src attribute of the img tag
        src = soup.find(id='wallpaper').get('src')

        filename = src.split('/')[-1]
        destination_file = path.join(output_dir, filename)

        if not isfile(destination_file):
            if not isdir(output_dir):
                makedirs(output_dir)
            print('http:' + src)
            urlretrieve('http:' + src, destination_file)


def login(login_name, password):
    """Logs into wallhaven.com with a given login"""
    if not password:
        password = getpass("Password:")

    parameters = {
        'username': login_name,
        'password': password
    }
    data = urlencode(parameters)
    data = data.encode('ascii')
    urlopen(__LOGIN_URL, data)


if __name__ == '__main__':
    # pylint: disable=C0103
    parser = ArgumentParser(description="Download images from wallhaven.cc")
    # pylint: enable=C0103
    parser.add_argument('-c', '--config',
                        default=__DEFAULT_CONFIG_FILE,
                        help='configuration file (default: {})'
                        .format(__DEFAULT_CONFIG_FILE))
    parser.add_argument('-u', '--userAgent',
                        help='User-Agent to use for the requests')
    parser.add_argument('-d', '--dir',
                        help='output directory')
    parser.add_argument('-l', '--login',
                        help='login for wallhaven')
    parser.add_argument('-p', '--password',
                        help='password for wallhaven')
    parser.add_argument('-t', '--tag', action='store_true',
                        help='treat query as tag name')
    parser.add_argument('-w', '--sfw', action='store_true',
                        help='get suitable-for-work wallpapers')
    parser.add_argument('-s', '--sketchy', action='store_true',
                        help='get sketchy wallpapers')
    parser.add_argument('-n', '--nsfw', action='store_true',
                        help='get not-suitable-for-work wallpapers')
    parser.add_argument('query', nargs='+',
                        help='string to search for on wallhaven')
    args = parser.parse_args()  # pylint: disable=C0103

    if isfile(expanduser(args.config)):
        with open(expanduser(args.config)) as f:
            configuration = yaml.load(f)  # pylint: disable=C0103
            if not args.userAgent and 'userAgent' in configuration:
                args.userAgent = configuration['userAgent']
            if not args.dir and 'dir' in configuration:
                args.dir = configuration['dir']
            if not args.login and 'login' in configuration:
                args.login = configuration['login']
            if not args.password and 'password' in configuration:
                args.password = configuration['password']
            if not args.sfw and 'sfw' in configuration:
                args.sfw = configuration['sfw']
            if not args.sketchy and 'sketchy' in configuration:
                args.sketchy = configuration['sketchy']
            if not args.nsfw and 'nsfw' in configuration:
                args.nsfw = configuration['nsfw']

    if not args.userAgent:
        print("No User-Agent set. Specify on command line or set 'userAgent'"
              + "in the config file", file=stderr)
        exit(1)
    if not args.dir:
        print("No output directory set. Specify on command line or set 'dir'"
              + "in the config file", file=stderr)
        exit(1)

    configure_urllib(args.userAgent)
    purity_string = ''.join('1' if i else '0'  # pylint: disable=C0103
                            for i in (args.sfw, args.sketchy, args.nsfw))

    if args.login:
        login(args.login, args.password)

    for q in args.query:
        if not args.tag:
            get_query(q, args.dir, purity_string)
        else:
            get_tag(q, args.dir, purity_string)
