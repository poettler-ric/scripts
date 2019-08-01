#!/usr/bin/env python3

from argparse import ArgumentParser
from os import getcwd
from os.path import join as pjoin
from subprocess import run


def execute_command(cmd, log=None):
    result = run(cmd.split(), encoding='utf-8', capture_output=True)

    if log:
        with open(log, 'a') as l:
            l.write(30 * '=' + '\n')
            l.write(f"command: {cmd}\n")
            l.write("stdout: \n")
            l.write("------- \n")
            l.write(result.stdout)
            l.write("stderr: \n")
            l.write("------- \n")
            l.write(result.stderr)
            l.write(f"exitcode: {result.returncode}\n")

    return result, result.returncode == 0

if __name__ == '__main__':
    DEFAULT_PLAYBOOK = 'site.yml'
    DEFAULT_INVENTORY = 'hosts'
    DEFAULT_PATH = pjoin(getcwd(), 'setupfedora.py.tmp')
    DEFAULT_LOGFILE = 'setupfedora.py.log'

    parser = ArgumentParser(
        description="Initializes a fresh Fedora installation")
    parser.add_argument('hostname', help="hostname to set")
    parser.add_argument(
        'repository', help="repository hosting the ansible configuration")
    parser.add_argument('-p', '--playbook', default=DEFAULT_PLAYBOOK,
                        help="playbook to execute")
    parser.add_argument('-t', '--tmp', default=DEFAULT_PATH,
                        help="directory for temporary files (must be absolute)")
    parser.add_argument('-i', '--inventory', default=DEFAULT_INVENTORY,
                        help="ansible inventory file")
    parser.add_argument('-l', '--log', default=DEFAULT_LOGFILE,
                        help="logfile to write")
    parser.add_argument('-c', '--checkout', help="branch to checkout")
    parser.add_argument('-d', '--dump', action='store_true',
                        help="perform a dump http clone")
    args = parser.parse_args()

    print("installing needed packages")
    _, ok = execute_command("dnf install -y ansible git", args.log)
    if not ok:
        print(f"execution failed. see log file: {args.log}")
        exit(1)

    print("setting hostname")
    _, ok = execute_command(f"hostnamectl set-hostname {args.hostname}",
                            args.log)
    if not ok:
        print(f"execution failed. see log file: {args.log}")
        exit(2)

    print("pulling configuration")
    checkout_args = f"-C {args.checkout}" if args.checkout else ""
    if args.dump:
        checkout_args += ' --full'
    _, ok = execute_command(f"ansible-pull -U {args.repository} " +
                            f"-d {args.tmp} -i {args.inventory} " +
                            f"{checkout_args} {args.playbook}",
                            args.log)
    if not ok:
        print(f"execution failed. see log file: {args.log}")
        exit(3)

    print("host sucessfully setup")
