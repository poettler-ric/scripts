#!/usr/bin/python

"""
Summarize worked hours.

Usage::

    usage: officehours.py [-h] file

    Summarize worked hours.

    positional arguments:
      file        File containing the hours

    optional arguments:
      -h, --help  show this help message and exit
"""

import argparse
from datetime import datetime, timedelta

__DATE_FORMAT = "%Y%m%d%H%M"
__HOUR_FORMAT = "%H:%M"
__START_TIME = "197001010800"
__SIX_HOURS = timedelta(0, 0, 0, 0, 0, 6)
__THIRDY_MINUTES = timedelta(0, 0, 0, 0, 30)


def decimal_delta(delta):
    """Returns the given delta as hours in decimal format."""
    return delta.total_seconds() / 3600


def parse_weeks(filename):
    """Parse worked weeks from a file."""
    weeks = {}
    with open(filename) as file:
        for line in file:
            parts = line.split()

            from_time = datetime.strptime(parts[0] + parts[1], __DATE_FORMAT)
            to_time = datetime.strptime(parts[0] + parts[2], __DATE_FORMAT)
            week_number = "{:4d}{:02d}".format(from_time.year,
                                               from_time.isocalendar()[1])

            week = weeks.get(week_number, {
                'duration': timedelta(),
                'comments': []})
            week['duration'] = week['duration'] + (to_time - from_time)
            week['comments'].append(" ".join(parts[3:]))
            weeks[week_number] = week

    return weeks


def print_weeks(weeks):
    """Print parsed weeks"""
    start = datetime.strptime(__START_TIME, __DATE_FORMAT)
    for week_number in sorted(weeks):
        week = weeks[week_number]
        print("week {}".format(week_number))
        duration = week['duration']
        print("duration: %s (%.2f)" % (duration, decimal_delta(duration)))
        end = start + duration
        if duration > __SIX_HOURS:
            end = end + __THIRDY_MINUTES
            print("!! BOOK BREAK !!")
        print("booking: {} - {}".format(start.strftime(__HOUR_FORMAT),
                                        end.strftime(__HOUR_FORMAT)))
        print("comments:")
        for comment in week['comments']:
            print(comment)
        print("")

if __name__ == '__main__':
    # pylint: disable=C0103
    parser = argparse.ArgumentParser(description="Summarize worked hours.")
    # pylint: enable=C0103
    parser.add_argument('file', help="File containing the hours")
    args = parser.parse_args() # pylint: disable=C0103

    print_weeks(parse_weeks(args.file))
