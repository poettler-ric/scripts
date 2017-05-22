#!/usr/bin/env python3

"""Determine scores for assignments."""

from argparse import ArgumentParser
from configparser import ConfigParser, ExtendedInterpolation
from glob import glob
from os import listdir
from os.path import join
import sys


def print_student(config, score, boni, mali):
    print("base: {}".format(config['base'].getint('base_score')))
    for i in mali:
        print(i)
    for i in boni:
        print(i)
    print("=> {}".format(score))


def score_student(config, student_id):
    folder = glob(config['base']['folder_template'].format(student_id))[0]
    score, boni, mali = get_file_stats(config, join(folder, 'notes.txt'))
    print_student(config, score, boni, mali)


def get_file_stats(config, file):
    basescore = config['base'].getint('base_score')
    maxscore = config['base'].getint('max_score')
    score = basescore
    boni, mali = set(), set()
    with open(file) as f:
        for l in f:
            if l.startswith('-'):
                name = l.split()[1]
                value = config['mali'].getfloat(name)
                if value is None:
                    sys.exit("unknown malus: {}".format(name))
                mali.add("{} (-{})".format(name, value))
                score -= value
            elif l.startswith('+'):
                name = l.split()[1]
                value = config['boni'].getfloat(name)
                if value is None:
                    sys.exit("unknown bonus: {}".format(name))
                boni.add("{} ({})".format(name, value))
                score += value
    score = max(0, score) # there are no negative scores
    score = min(maxscore, score) # limit the maximum amount of points
    return score, boni, mali


def stat_categories():
    boni, mali = {}, {}
    for d in listdir('.'):
        with open(join(d, 'notes.txt')) as f:
            for l in f:
                if l.startswith('-'):
                    name = l.split()[1]
                    if not name in mali.keys():
                        mali[name] = 0
                    mali[name] += 1
                elif l.startswith('+'):
                    name = l.split()[1]
                    if not name in boni.keys():
                        boni[name] = 0
                    boni[name] += 1
    return boni, mali


def determine_categories():
    boni, mali = stat_categories()
    return boni.keys(), mali.keys()


def print_stats(config):
    scores = []
    basescore = config['base'].getint('base_score')
    for d in listdir('.'):
        score, _, _ = get_file_stats(config, join(d, 'notes.txt'))
        scores.append(score)
    print('average: {:.1f}'.format(sum(scores)/float(len(scores))))
    print('above {}: {}'.format(basescore,
                                sum(i > basescore for i in scores)))
    print('failed: {}'.format(sum(i < basescore/float(2) for i in scores)))

    boni, mali = stat_categories()
    print()
    print("=== mali count:")
    for category, count in mali.items():
        print("{}: {}".format(category, count))
    print()
    print("=== boni count:")
    for category, count in boni.items():
        print("{}: {}".format(category, count))


def print_csv(config):
    for d in listdir('.'):
        score, _, _ = get_file_stats(config, join(d, 'notes.txt'))
        print("{},{}".format(d, score))


def print_failed(config):
    basescore = config['base'].getint('base_score')
    for d in listdir('.'):
        score, boni, mali = get_file_stats(config, join(d, 'notes.txt'))
        if score < basescore/float(2):
            print(d)
            print_student(config, score, boni, mali)


def set_categories(config):
    boni, mali = determine_categories()
    config['boni'] = {i: '1' for i in boni}
    config['mali'] = {i: '1' for i in mali}


def update_categories(config):
    boni, mali = determine_categories()
    for i in boni:
        if i not in config['boni'].keys():
            config['boni'][i] = '1'
    for i in mali:
        if i not in config['mali'].keys():
            config['mali'][i] = '1'


if __name__ == '__main__':
    argparser = ArgumentParser(description="determine scores for assignments")
    argparser.add_argument('config', help="config file for the assignment")
    argparser.add_argument('-s',
                           help='set boni, mali and write to config',
                           action='store_true')
    argparser.add_argument('-u',
                           help='update boni, mali and write to config',
                           action='store_true')
    argparser.add_argument('-f',
                           help='list failed students',
                           action='store_true')
    argparser.add_argument('-c',
                           help='export csv',
                           action='store_true')
    argparser.add_argument('student_id',
                           help="id of the student to score",
                           nargs='?')
    args = argparser.parse_args()

    config = ConfigParser(interpolation=ExtendedInterpolation())
    config.read(args.config)

    if args.s:
        set_categories(config)
        with open(args.config, 'w') as f:
            config.write(f)
    elif args.u:
        update_categories(config)
        with open(args.config, 'w') as f:
            config.write(f)
    elif args.f:
        print_failed(config)
    elif args.c:
        print_csv(config)
    elif args.student_id:
        score_student(config, args.student_id)
    else:
        print_stats(config)
