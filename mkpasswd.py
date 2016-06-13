#!/usr/bin/python3

"""
mkpasswd implementation in python.
"""

from argparse import ArgumentParser
from crypt import crypt
from getpass import getpass
from random import SystemRandom
from string import ascii_letters, digits


def random_string(length):
    """Generate a random string of alphanumerical characters."""
    return ''.join(SystemRandom().choice(ascii_letters + digits)
                   for i in range(length))


def generate_password(plain_password, salt):
    """Generate a password to put into ``/etc/shadow``."""
    return crypt(plain_password, "$6$%s" % salt)


if __name__ == '__main__':
    # pylint: disable=C0103
    parser = ArgumentParser(description="Generate password for /etc/shadow")
    # pylint: enable=C0103
    parser.add_argument("-r", "--random",
                        action='store_true',
                        help="generate a random password")
    parser.add_argument("-e", "--echo",
                        action='store_true',
                        help="echo plaintext password afterwards")
    parser.add_argument("-l", "--length",
                        nargs='?',
                        default=32,
                        type=int,
                        help="lenght of random passwords")
    parser.add_argument("-s", "--saltlength",
                        nargs='?',
                        default=16,
                        type=int,
                        help="lenght of the random salt")
    parser.add_argument("password", nargs='?', help="desired password")
    parser.add_argument("salt", nargs='?', help="desired salt")
    args = parser.parse_args()  # pylint: disable=C0103

    if args.random:
        args.password = random_string(args.length)

    if not args.password:
        args.password = getpass("Password:")

    if not args.salt:
        args.salt = random_string(args.saltlength)

    if args.echo:
        print(args.password)

    print(generate_password(args.password, args.salt))
