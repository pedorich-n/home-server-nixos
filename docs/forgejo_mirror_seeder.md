# Forgejo Mirror Seeder

## Collecting a list of Github repositories

Base list can be collected using this command:

```shell

gh api --paginate --slurp "/user/repos?affiliation=owner,collaborator,organization_member&per_page=100" \
| jq '[.[][]]
    | map({
        source: .full_name,
        owner: .owner.login,
        name: .name,
        private: .private
      })' \
> mirror-repos.json

```

This:

- Includes private repositories.
- Includes repositories from organizations you belong to.
- Includes repositories you collaborate on.
- Excludes forks.
- Produces a stable, sorted manifest.
- Carries the GitHub private flag into each entry.
