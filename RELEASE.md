# Release Instructions

  1. Bump version in related files below
  2. Run tests:
      - `mix test` in the root folder
  3. Commit, push code
  4. Publish package and docs after pruning any extraneous uncommitted files
  5. Create a release on GitHub or push a tag with `git tag -a v1.0` && `git push origin v1.0`

## Files with version

  * `mix.exs`
  * `README.md` (Installation section)
  * `CHANGELOG.md`
