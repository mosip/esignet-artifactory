# AGENTS.md

## Repository Overview

This repo builds the **esignet-artifactory** Docker image: an nginx server that
serves static assets used by eSignet deployments — i18n language bundles,
UI themes, images, and a "sign-in with eSignet" plugin zip — plus a set of
Maven-downloaded wrapper/plugin JARs (mock auth wrapper, IDA wrapper, digital
credential wrapper, identity/mock plugins). It is a packaging repo, not an
application: there is no application source code, no unit tests, and no
business logic to modify. Changes here are almost always about updating a
static asset, bumping an artifact version in `artifacts/pom.xml`, or adjusting
the Docker/Helm packaging.

## Technology Stack

- **Base image**: `nginx` (Docker), built with `openjdk-11-jdk` and
  `apache-maven-3.8.8` installed at build time to fetch dependency JARs.
- **Build tool**: Maven (`artifacts/pom.xml`), used only to download prebuilt
  JAR artifacts from Maven Central / OSSRH via `maven-dependency-plugin`
  (`dependency:resolve` + `copy` goal) — it does not compile any Java code in
  this repo.
- **Packaging**: shell scripts (`configure.sh`) that zip the downloaded assets
  into `.zip` files nginx serves.
- **Deployment**: Helm chart `mosip/artifactory`, driven by the shell scripts
  in `deploy/`.
- **CI**: GitHub Actions (`.github/workflows/push-trigger.yml`), which calls
  the shared `mosip/kattu` reusable Docker-build workflow on push to
  `master`, `develop`, `1.*`, `MOSIP*`, `release*`, on PR open/reopen/sync,
  and on published releases. It builds and publishes the Docker image; it
  does not run tests, since none exist in this repo.

## Build & Test Commands

There is no test suite in this repo. The only "build" is the Docker image
build, which downloads the artifact JARs via Maven and zips the static assets:

```shell
cd artifacts
docker build -t esignet-artifactory-server .
```

To inspect what Maven would resolve without a full Docker build:

```shell
cd artifacts
mvn dependency:resolve
```

## Configuration

- **Artifact versions and coordinates** are set as Maven properties at the
  top of `artifacts/pom.xml` (e.g. `esignet-mock-wrapper.version`,
  `esignet-ida-wrapper.version`, `esignet-digital-credential-wrapper.version`,
  `mosip-identity-plugin.version`, `esignet-mock-plugin.version`). Bump these
  to change which JAR version gets packaged into the image.
- **Docker build-time config** comes from `ARG`/`ENV` values in
  `artifacts/Dockerfile` (e.g. `container_user`, `container_user_uid/gid`,
  `version`, `idp_auth_wrapper_version`, and the various `*_zip_path`
  locations under `/usr/share/nginx/html/artifactory`).
- **nginx config** is `artifacts/nginx.conf`, copied into the image and then
  patched by a `sed` command in the Dockerfile to change the listen port from
  80 to 8080.
- **Deployment config**: `deploy/install.sh` hardcodes the namespace
  (`esignet`) and Helm chart version (`CHART_VERSION=0.0.1-develop`); update
  these values there if the chart version changes.
- There are no secrets, credential files, or `.env`-style overrides in this
  repo — the only local-machine variance is the optional `KUBECONFIG` path
  accepted as `$1` by `deploy/install.sh`, `deploy/delete.sh`, and
  `deploy/restart.sh`.

## Project Structure Notes

- `artifacts/` — Docker build context (see [`artifacts/AGENTS.md`](artifacts/AGENTS.md)).
  - `Dockerfile` — builds the nginx image, resolves Maven artifacts, runs
    `configure.sh`.
  - `pom.xml` — declares which JARs to download and where to place them.
  - `configure.sh` — zips the downloaded wrapper/plugin JARs and the i18n,
    theme, and image directories into `.zip` files under the nginx web root.
  - `nginx.conf` — base nginx config used inside the image.
  - `src/i18n/` — per-module i18n JSON bundles (esignet, esignet-signup,
    mock-relying-party, oidc-demo), one directory per bundle, one JSON file
    per locale (plus a `default.json`).
  - `src/theme/` — CSS variables and theme config for esignet and
    esignet-signup.
  - `src/image/` — PNG/SVG image assets for esignet and esignet-signup.
  - `src/mosip-plugins/sign-in-with-esignet/` — a prebuilt plugin zip that is
    copied into the image as-is (not built from source here).
- `deploy/` — Helm-based install/restart/delete scripts and a short
  `deploy/README.md` (see [`deploy/AGENTS.md`](deploy/AGENTS.md)).
- `.github/workflows/push-trigger.yml` — the only CI workflow; triggers a
  Docker image build/publish via the shared `mosip/kattu` workflow.

## Development Workflow

1. Branch from `develop` (the active integration branch used by CI).
   `deploy/install.sh` defaults to Helm chart version `0.0.1-develop`
   (`--version $CHART_VERSION`) and, separately, Docker image tag
   `develop` (`--set image.tag=develop`) — these are two different
   values, not one "chart tag".
2. If adding or updating a static asset (i18n JSON, theme CSS, image), place
   it under the matching `artifacts/src/...` directory and update
   `configure.sh` only if you are introducing a new bundle/zip, not just
   changing file contents.
3. If bumping a wrapper or plugin JAR version, edit the corresponding
   `*.version` property in `artifacts/pom.xml`.
4. Validate locally with `docker build` (see Build & Test Commands) before
   opening a PR — there is no automated test to catch a broken artifact
   reference.
5. Commit with sign-off (`git commit -s`) per MOSIP contribution norms.

## Pull Request Guidelines

- Target the `develop` branch, not `master`.
- Reference the tracking issue in the PR description.
- Keep PRs scoped to one concern (e.g. one artifact-version bump, or one
  asset update) since there is no test suite to isolate regressions —
  reviewers rely on a small, readable diff.
- Since CI (`push-trigger.yml`) only builds the Docker image and does not run
  tests, a green CI check confirms the image builds, not that the packaged
  assets are functionally correct — call out in the PR description what was
  verified manually (e.g. "confirmed new locale file is valid JSON").

## Repository-Specific Considerations

- This repo has **no application code** and **no unit/integration tests** —
  do not assume Java source exists to edit; the Maven build here only
  downloads prebuilt JARs, it does not compile anything.
- Artifact JARs referenced in `artifacts/pom.xml` (mock wrapper, IDA wrapper,
  digital credential wrapper, identity plugin, mock plugin) are built in
  *other* MOSIP repos; version bumps here must resolve, or the Docker build
  will fail to resolve the dependency. The check differs by version type:
  a plain release version (e.g. `1.3.0`) must exist in the configured
  release repository, while a `-SNAPSHOT` version (e.g. `1.3.0-SNAPSHOT`,
  used by `esignet-mock-plugin` and `mosip-identity-plugin` as of this
  writing) must exist in the `ossrh` **snapshot** repository declared in
  `<distributionManagement>`/`<repositories>` — it will never be on Maven
  Central, so checking Central for a snapshot coordinate proves nothing.
- `deploy/*.sh` scripts assume `kubectl` and `helm` are installed and that a
  `mosip` Helm repo is already added (`helm repo update` is called, but not
  `helm repo add`).
- File paths inside `Dockerfile` and `configure.sh` are coupled together
  (`ENV` variables define paths that `configure.sh` consumes) — if you change
  a path in one, update the other.

## Agent rules

### Do

1. Verify any artifact version bump against the actual published
   coordinate before editing `artifacts/pom.xml`: check the release
   repository for a plain version, or the snapshot repository (not
   Maven Central) for a `-SNAPSHOT` version.
2. Keep new static assets under the correct `artifacts/src/{i18n,theme,image}`
   subdirectory, matching the existing per-module layout.
3. Run `docker build` locally when changing `Dockerfile`, `configure.sh`, or
   `pom.xml` to confirm the image still builds.
4. Target the `develop` branch for new work and PRs.
5. Keep commit messages and PR descriptions specific about which artifact or
   asset changed, since there is no test output to describe the change.

### Do not

1. Do not invent or assume Java/Node application source exists in this repo —
   it does not.
2. Do not claim CI runs tests — `push-trigger.yml` only builds and publishes
   the Docker image.
3. Do not hardcode secrets or credentials into `deploy/*.sh` or the
   Dockerfile; the only externally supplied value is the optional
   `KUBECONFIG` path argument.
4. Do not change a path in `Dockerfile` without updating the matching path in
   `configure.sh` (or vice versa) — they must stay in sync.
5. Do not target `master` for PRs; `develop` is the active integration branch.
