import argparse
import logging
from dataclasses import dataclass
from typing import Callable, TypeVar, Union, get_args, get_origin

import dacite
import toml
from mcstatus import BedrockServer, JavaServer, MCServer
from mcstatus.address import Address
from pystemd.systemd1 import Unit as SDUnit
from tenacity import retry, wait_fixed, retry_if_result, stop_after_attempt


S = TypeVar("S", bound=MCServer)

logging.addLevelName(logging.WARNING, "WARN")
logging.basicConfig(
    level=logging.INFO,
    format="[{asctime}] [{levelname:<4s}] - {message}",
    datefmt="%Y-%m-%dT%H:%M:%S%z",
    style="{",
)
logger = logging.getLogger("server-check")


@dataclass
class Config:
    remote_server_address: str
    local_server_address: str
    minecraft_service_name: str
    tunnel_service_name: str
    timeout: int


@dataclass
class ServerStatus:
    address: str
    players_online: int
    latency: float


class FailedToGetServerStatus(Exception):
    def __str__(self) -> str:
        return f"FailedToGetServerStatus({super().__str__()})"


def stringify_address(address: Address) -> str:
    return f"{address.host}:{address.port}"


@retry(
    wait=wait_fixed(10),
    stop=stop_after_attempt(5),
    retry=retry_if_result(lambda x: isinstance(x, FailedToGetServerStatus)),
)
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


def main():
    parser = argparse.ArgumentParser("server-check")
    parser.add_argument("--config", type=str, required=True)

    args = parser.parse_args()

    config = dacite.from_dict(
        data_class=Config,
        data=toml.load(args.config),
    )

    java_server = JavaServer.lookup(config.remote_server_address, config.timeout)
    java_server_local = JavaServer.lookup(config.local_server_address, config.timeout)

    java_server_status = try_check_server(java_server, check_java_server)
    java_server_local_status = try_check_server(java_server_local, check_java_server)

    if isinstance(java_server_status, FailedToGetServerStatus):
        logger.warning(f"External address is unreachable. {java_server_status}")
        if isinstance(java_server_local_status, FailedToGetServerStatus):
            logger.warning(f"Local address is unreachable! Restarting Minecraft Server...")
            restart_service(config.minecraft_service_name)
        else:
            logger.warning(f"Local Server is reachable, restarting tunnel...")
            restart_service(config.tunnel_service_name)
    else:
        logger.info("All addresses are reachable.")
