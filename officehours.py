#!/usr/bin/python

import argparse
from datetime import datetime, timedelta

__DATE_FORMAT = "%Y%m%d%H%M"
__HOUR_FORMAT = "%H:%M"
__START_TIME = "197001010800"
__SIX_HOURS = timedelta(0, 0, 0, 0, 0, 6)
__THIRDY_MINUTES = timedelta(0, 0, 0, 0, 30)

def decimal_delta(delta):
    return delta.total_seconds() / 3600

def parse_weeks(filename):
    weeks = {}
    with open(filename) as f:
        for line in f:
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
        print("booking: %s - %s"
            % (start.strftime(__HOUR_FORMAT), end.strftime(__HOUR_FORMAT)))
        print("comments:")
        for comment in week['comments']:
            print(comment)
        print("")

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Summarize worked hours.")
    parser.add_argument('file', help="File containing the hours")
    args = parser.parse_args()

    print_weeks(parse_weeks(args.file))
