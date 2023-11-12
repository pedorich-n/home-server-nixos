import argparse
import logging
import signal
import sys
import time
import tomllib
from dataclasses import dataclass
from typing import Callable, TypeVar, Union

import dacite
import schedule
from mcstatus import BedrockServer, JavaServer, MCServer
from mcstatus.address import Address
from pystemd import SDUnit
from tenacity import retry, retry_if_exception_type, stop_after_attempt, wait_fixed

S = TypeVar("S", bound=MCServer)

# region GlobalConfig

logging.addLevelName(logging.WARNING, "WARN")
logging.basicConfig(
    level=logging.INFO,
    format="[{asctime}] [{levelname:<4s}] - {message}",
    datefmt="%Y-%m-%dT%H:%M:%S%z",
    style="{",
)
logger = logging.getLogger("server-check")


def graceful_shutdown(signum, frame):
    logger.info("Received signal to shut down gracefully...")

    # Cancel the scheduled job
    if schedule.jobs:
        schedule.clear()

    sys.exit(0)


signal.signal(signal.SIGTERM, graceful_shutdown)
signal.signal(signal.SIGINT, graceful_shutdown)

# endregion


@dataclass
class Config:
    remote_server_address: str
    local_server_address: str


@dataclass
class ServerStatus:
    address: str
    players_online: int
    latency: float


@dataclass
class LoopConfig:
    remote_server_address: str
    local_server_address: str
    server_service: str
    tunnel_service: str
    timeout: int
    restart_timeout: int


class FailedToGetServerStatus(Exception):
    def __str__(self) -> str:
        return f"FailedToGetServerStatus({super().__str__()})"


def stringify_address(address: Address) -> str:
    return f"{address.host}:{address.port}"


@retry(wait=wait_fixed(10), stop=stop_after_attempt(3), retry=retry_if_exception_type(), reraise=True)
def try_check_server(
    server: S, get_status: Callable[[S], ServerStatus]
) -> Union[FailedToGetServerStatus, ServerStatus]:
    try:
        status = get_status(server)
        return status
    except Exception as e:
        return FailedToGetServerStatus(e)


def check_java_server(server: JavaServer) -> ServerStatus:
    status_response = server.status()
    status = ServerStatus(
        address=stringify_address(server.address),
        players_online=status_response.players.online,
        latency=status_response.latency,
    )
    return status


# Unused
def check_bedrock_server(server: BedrockServer) -> ServerStatus:
    status_response = server.status()
    status = ServerStatus(
        address=stringify_address(server.address),
        players_online=status_response.players.online,
        latency=status_response.latency,
    )
    return status


def restart_service(service_name: str):
    with SDUnit(service_name.encode()) as service:
        service.Unit.Restart(b"replace")


def loop(config: LoopConfig):
    logger.info(f"Checking server...")
    java_server = JavaServer.lookup(config.remote_server_address, config.timeout)
    java_server_local = JavaServer.lookup(config.local_server_address, config.timeout)

    java_server_status = try_check_server(java_server, check_java_server)
    java_server_local_status = try_check_server(java_server_local, check_java_server)

    if isinstance(java_server_status, FailedToGetServerStatus):
        logger.warning(f"External address is unreachable. {java_server_status}")
        if isinstance(java_server_local_status, FailedToGetServerStatus):
            logger.warning(f"Local address is unreachable! Restarting Minecraft Server...")
            restart_service(config.server_service)
            time.sleep(config.restart_timeout)
        else:
            logger.warning(f"Local Server is reachable, restarting tunnel...")
            restart_service(config.tunnel_service)
    else:
        logger.info("All addresses are reachable.")


def main():
    parser = argparse.ArgumentParser("server-check")
    parser.add_argument("--config", type=str, required=True)
    parser.add_argument("--server-service", type=str, required=True)
    parser.add_argument("--tunnel-service", type=str, required=True)
    parser.add_argument(
        "--timeout", type=int, required=False, default=10, help="How long to wait for server response. In seconds"
    )
    parser.add_argument(
        "--restart-timeout",
        type=int,
        required=False,
        default=120,
        help="How long to wait after server restart, before another check. In seconds",
    )
    parser.add_argument("--interval", type=int, required=False, default=60, help="Run check every X seconds")

    args = parser.parse_args()

    with open(args.config, "rb") as config_file:
        config = dacite.from_dict(
            data_class=Config,
            data=tomllib.load(config_file),
        )

        logger.info("Program started")

        loop_config = LoopConfig(
            remote_server_address=config.remote_server_address,
            local_server_address=config.local_server_address,
            server_service=args.server_service,
            tunnel_service=args.tunnel_service,
            timeout=args.timeout,
            restart_timeout=args.restart_timeout,
        )

        logger.info(f"Sleeping for {args.restart_timeout} seconds...")
        time.sleep(args.restart_timeout)
        job = schedule.every(args.interval).seconds.do(loop, config=loop_config)
        logger.info(f"Starting a job, running every {args.interval} seconds...")

        while True:
            schedule.run_pending()
            time.sleep(1)
