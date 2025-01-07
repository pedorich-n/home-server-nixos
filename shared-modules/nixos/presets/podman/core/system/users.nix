{
  users = {
    users.containers = {
      isSystemUser = true;
      group = "containers";

      # Per podman's recommendation allocating 2 billion UIDs & GIDs for containers
      # https://docs.podman.io/en/v5.3.1/markdown/podman-run.1.html#userns-mode
      subUidRanges = [{
        count = 2147483647;
        startUid = 2147483648;
      }];
      subGidRanges = [{
        count = 2147483647;
        startGid = 2147483648;
      }];
    };

    groups.containers = { };
  };

}
