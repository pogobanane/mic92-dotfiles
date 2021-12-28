#!/usr/bin/env python3

import os
from contextlib import contextmanager
from typing import List, Dict, Tuple, IO, Iterator, Optional, Callable, Any
from threading import Thread
import subprocess
from shlex import quote
from enum import Enum


@contextmanager
def _pipe() -> Iterator[Tuple[IO[str], IO[str]]]:
    (pipe_r, pipe_w) = os.pipe()
    read_end = os.fdopen(pipe_r, "r")
    write_end = os.fdopen(pipe_w, "w")
    try:
        yield (read_end, write_end)
    finally:
        read_end.close()
        write_end.close()


class HostKeyCheck(Enum):
    STRICT = 0
    # trust-on-first-use
    TOFU = 1
    NONE = 2


class DeployHost:
    def __init__(
        self,
        host: str,
        user: str = "root",
        port: int = 22,
        forward_agent: bool = False,
        command_prefix: Optional[str] = None,
        host_key_check: HostKeyCheck = HostKeyCheck.STRICT,
        meta: Dict[str, Any] = {},
    ) -> None:
        self.host = host
        self.user = user
        self.port = port
        if command_prefix:
            self.command_prefix = command_prefix
        else:
            self.command_prefix = host
        self.forward_agent = forward_agent
        self.host_key_check = host_key_check
        self.meta = meta

    def _prefix_output(self, fd: IO[str]) -> None:
        for line in fd:
            print(f"[{self.command_prefix}] {line}", end="")

    def run_local(self, cmd: str) -> int:
        print(f"[{self.command_prefix}] {cmd}")
        with _pipe() as (read_fd, write_fd):
            with subprocess.Popen(
                cmd, text=True, shell=True, stdout=write_fd, stderr=write_fd
            ) as p:
                write_fd.close()
                self._prefix_output(read_fd)
                return p.wait()

    def run(self, cmd: str, become_root: bool = False) -> int:
        sudo = ""
        if become_root and self.user != "root":
            sudo = "sudo"
        print(f"[{self.command_prefix}] {cmd}")
        with _pipe() as (read_fd, write_fd):
            ssh_opts = ["-A"] if self.forward_agent else []

            if self.host_key_check != HostKeyCheck.STRICT:
                ssh_opts.extend(["-o", "StrictHostKeyChecking=no"])
            if self.host_key_check == HostKeyCheck.NONE:
                ssh_opts.extend(["-o", "UserKnownHostsFile=/dev/null"])

            with subprocess.Popen(
                ["ssh", f"{self.user}@{self.host}", "-p", str(self.port)]
                + ssh_opts
                + ["--", f"{sudo} bash -c {quote(cmd)}"],
                stdout=write_fd,
                stderr=write_fd,
                text=True,
            ) as p:
                write_fd.close()
                self._prefix_output(read_fd)
                return p.wait()


DeployResults = List[Tuple[DeployHost, int]]


class DeployGroup:
    def __init__(self, hosts: List[DeployHost]) -> None:
        self.hosts = hosts

    def _run_local(self, cmd: str, host: DeployHost, results: DeployResults) -> None:
        results.append((host, host.run_local(cmd)))

    def _run_remote(self, cmd: str, host: DeployHost, results: DeployResults) -> None:
        results.append((host, host.run(cmd)))

    def _run(self, cmd: str, local: bool = False) -> DeployResults:
        results: DeployResults = []
        threads = []
        for host in self.hosts:
            fn = self._run_local if local else self._run_remote
            thread = Thread(
                target=fn,
                kwargs=dict(results=results, cmd=cmd, host=host),
            )
            thread.start()
            threads.append(thread)

        for thread in threads:
            thread.join()

        return results

    def run(self, cmd: str) -> DeployResults:
        return self._run(cmd)

    def run_local(self, cmd: str) -> DeployResults:
        return self._run(cmd, local=True)

    def run_function(self, func: Callable) -> None:
        threads = []
        for host in self.hosts:
            thread = Thread(
                target=func,
                args=(host,),
            )
            threads.append(thread)

        for thread in threads:
            thread.start()

        for thread in threads:
            thread.join()


def parse_hosts(
    hosts: str,
    host_key_check: HostKeyCheck = HostKeyCheck.STRICT,
    forward_agent: bool = False,
    domain_suffix: str = "",
) -> DeployGroup:
    deploy_hosts = []
    for h in hosts.split(","):
        parts = h.split("@")
        if len(parts) > 1:
            user = parts[0]
            hostname = parts[1]
        else:
            user = "root"
            hostname = parts[0]
        deploy_hosts.append(
            DeployHost(
                hostname + domain_suffix, user=user, host_key_check=host_key_check, forward_agent=False
            )
        )
    return DeployGroup(deploy_hosts)
