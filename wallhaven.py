#!/usr/bin/python

from argparse import ArgumentParser
from itertools import count
from os import makedirs
from os.path import expanduser, isdir, isfile
from urllib.error import HTTPError
from urllib.parse import quote
from urllib.request import urlopen, urlretrieve, build_opener, install_opener
from sys import exit, stderr
import os.path as path

from bs4 import BeautifulSoup
import yaml


__DEFAULT_CONFIG_FILE = '~/.wallhaven.yaml'
__QUERY_URL_TEMPLATE = 'https://alpha.wallhaven.cc/search?q={}'
__INFO_URL_TEMPLATE = 'https://alpha.wallhaven.cc/wallpaper/{}'


def setUserAgent(agent):
    opener = build_opener()
    opener.addheaders = [('User-Agent', agent)]
    install_opener(opener)


def getQuery(query, outputDir):
    _getImages(__QUERY_URL_TEMPLATE.format(quote(query)),
               path.join(outputDir, query))


def getTag(query, outputDir):
    _getImages(__QUERY_URL_TEMPLATE.format(quote('"{}"'.format(query))),
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
    parser.add_argument('-t', '--tag', action='store_true',
                        help='treat query as tag name')
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

    if not args.userAgent:
        print("No User-Agent set. Specify on command line or set 'userAgent'"
              + "in the config file", file=stderr)
        exit(1)
    if not args.dir:
        print("No output directory set. Specify on command line or set 'dir'"
              + "in the config file", file=stderr)
        exit(1)

    setUserAgent(args.userAgent)

    if not args.tag:
        getQuery(args.query, args.dir)
    else:
        getTag(args.query, args.dir)
