# Importing scrobbles from Last.fm to Maloja

Sometimes it's possible that Multi-Scrobbler will get stuck for some reason and won't get updates from Spotify. Usually, in these cases, Last.fm still gets updates and logs listening history.

If Multi-Scrobbler hasn't been stuck for too long (<50 tracks), then just restarting it will fetch the recent history from Spotify.
But if more than 50 tracks are missing, the data needs to be fetched from Last.fm and imported into Maloja.

## Steps

1. Go to Maloja and find the latest known scrobble
2. Convert the scroblle timestamp into Unix epoch
3. Go to https://mainstream.ghan.nl/export.html and fetch the listening history since that timestamp in CSV
4. Clean up the file if needed. Make sure it only contains missing scrobbles to avoid duplicates
5. Rename the file to follow the pattern `recenttracks-XXXX.csv` (This step is important, as Maloja relies on the filename to choose the parser)
6. Upload the file to the server
7. Put the file under `/data/import` folder (`/mnt/store/music-history/maloja/data/import`)
8. Run `podman exec --interactive --tty maloja bash`
9. Run `/venv/bin/python -m maloja import /data/import/recenttracks-XXXX.csv`
10. Restart Maloja
11. Verify the data in Maloja

## Notes

1. Expected columns for the parser: [link](https://github.com/krateng/maloja/blob/9e44cc3ce6d4259c32026ba50ee934e024b43a7a/maloja/proccontrol/tasks/import_scrobbles.py#L439-L451)
2. Supported parsers: [link](https://github.com/krateng/maloja/blob/9e44cc3ce6d4259c32026ba50ee934e024b43a7a/maloja/proccontrol/tasks/import_scrobbles.py#L37-L82)
