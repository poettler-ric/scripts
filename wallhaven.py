#!/usr/bin/python3

from argparse import ArgumentParser
from getpass import getpass
from http.cookiejar import CookieJar
from itertools import count
from os import makedirs
from os.path import expanduser, isdir, isfile
from sys import exit, stderr
from urllib.parse import quote, urlencode
from urllib.request import build_opener, install_opener, urlopen, urlretrieve, \
    HTTPCookieProcessor, Request
import os.path as path

from bs4 import BeautifulSoup
import yaml


__DEFAULT_CONFIG_FILE = '~/.wallhaven.yaml'
__QUERY_URL_TEMPLATE = 'https://alpha.wallhaven.cc/search?q={}&purity={}'
__INFO_URL_TEMPLATE = 'https://alpha.wallhaven.cc/wallpaper/{}'
__LOGIN_URL = 'https://alpha.wallhaven.cc/auth/login'


def configureUrllib(agent):
    opener = build_opener(HTTPCookieProcessor(CookieJar()))
    opener.addheaders = [('User-Agent', agent)]
    install_opener(opener)


def getQuery(query, outputDir, purity):
    _getImages(__QUERY_URL_TEMPLATE.format(quote(query), purity),
               path.join(outputDir, query))


def getTag(query, outputDir, purity):
    _getImages(__QUERY_URL_TEMPLATE.format(
               quote('"{}"'.format(query)), purity),
               path.join(outputDir, "tag-" + query))


def _getImages(url, outputDir):
    # iterate through all pages
    for i in count(1):
        with urlopen((url + '&page={}').format(i)) as u:
            soup = BeautifulSoup(u, 'lxml')
            # get image ids
            ids = [j.get('href').split('/')[-1]
                   for j in soup.find_all('a', 'preview')]
            if not len(ids):
                # if there are no images we reached the last page
                break
            for j in ids:
                downloadImage(j, outputDir)


def downloadImage(id, outputDir):
    outputDir = expanduser(outputDir)
    with urlopen(__INFO_URL_TEMPLATE.format(id)) as u:
        soup = BeautifulSoup(u, 'lxml')
        # src attribute of the img tag
        src = soup.find(id='wallpaper').get('src')

        filename = src.split('/')[-1]
        destinationFile = path.join(outputDir, filename)

        if not isfile(destinationFile):
            if not isdir(outputDir):
                makedirs(outputDir)
            print('http:' + src)
            urlretrieve('http:' + src, destinationFile)


def login(login, password):
    if not password:
        password = getpass("Password:")

    parameters = {
        'username': login,
        'password': password
    }
    data = urlencode(parameters)
    data = data.encode('ascii')
    urlopen(__LOGIN_URL, data)


if __name__ == '__main__':

    parser = ArgumentParser(description="Download images from wallhaven.cc")
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
    parser.add_argument('query',
                        help='string to search for on wallhaven')
    args = parser.parse_args()

    if isfile(expanduser(args.config)):
        with open(expanduser(args.config)) as f:
            c = yaml.load(f)
            if not args.userAgent and 'userAgent' in c:
                args.userAgent = c['userAgent']
            if not args.dir and 'dir' in c:
                args.dir = c['dir']
            if not args.login and 'login' in c:
                args.login = c['login']
            if not args.password and 'password' in c:
                args.password = c['password']
            if not args.sfw and 'sfw' in c:
                args.sfw = c['sfw']
            if not args.sketchy and 'sketchy' in c:
                args.sketchy = c['sketchy']
            if not args.nsfw and 'nsfw' in c:
                args.nsfw = c['nsfw']

    if not args.userAgent:
        print("No User-Agent set. Specify on command line or set 'userAgent'"
              + "in the config file", file=stderr)
        exit(1)
    if not args.dir:
        print("No output directory set. Specify on command line or set 'dir'"
              + "in the config file", file=stderr)
        exit(1)

    configureUrllib(args.userAgent)
    purity = ''.join('1' if i else '0'
                     for i in (args.sfw, args.sketchy, args.nsfw))

    if (args.login):
        login(args.login, args.password)

    if not args.tag:
        getQuery(args.query, args.dir, purity)
    else:
        getTag(args.query, args.dir, purity)
