# AGENTS.md — artifacts/

Parent guide: [`../AGENTS.md`](../AGENTS.md)

## Purpose

The Docker build context that produces the `esignet-artifactory-server`
image: an nginx server pre-loaded with wrapper/plugin JARs and static
i18n/theme/image assets that eSignet deployments fetch at runtime. This
folder contains the packaged artifact content; `../deploy/` installs,
restarts, and deletes the Helm release for the image this folder
builds (see `../deploy/AGENTS.md`).

## Layout

```text
artifacts/
├── Dockerfile         # nginx base image + Maven artifact download + configure.sh — see below
├── pom.xml              # declares which JARs to download and where — see below
├── configure.sh            # zips the downloaded JARs/assets into the files nginx serves
├── nginx.conf                # base nginx config, patched by the Dockerfile to listen on 8080
├── src/i18n/                    # per-module i18n JSON bundles: esignet, esignet-signup, mock-relying-party, oidc-demo
├── src/theme/                      # CSS variables/theme config for esignet, esignet-signup
├── src/image/                         # PNG/SVG assets for esignet, esignet-signup
└── src/mosip-plugins/sign-in-with-esignet/sign-in-with-esignet.zip   # prebuilt, copied in as-is
```

## `pom.xml` — what actually gets downloaded

`maven-dependency-plugin`'s `copy` goal resolves 5 JARs and drops them
into two locations under `${base_path}/libs-release-local/esignet/`:

- **`esignet-wrapper/`** (root `AGENTS.md` calls these "wrapper" JARs):
  - `esignet-mock-wrapper.jar` ← artifact `mock-esignet-integration-impl`,
    version property `esignet-mock-wrapper.version`.
  - `esignet-ida-wrapper.jar` ← artifact `esignet-integration-impl`,
    version property `esignet-ida-wrapper.version`.
  - `esignet-digital-credential-wrapper` (root `AGENTS.md`'s name) ←
    artifact **`sunbird-rc-esignet-integration-impl`**, version property
    `esignet-digital-credential-wrapper.version`. The property name and
    the actual Maven artifactId don't match — don't search for a
    `digital-credential`-named artifact upstream, it's the Sunbird-RC
    integration jar.
- **`esignet-plugins/`**:
  - `esignet-mock-plugin.jar` ← artifact `mock-plugin`, version property
    `esignet-mock-plugin.version`.
  - `mosip-identity-plugin.jar` ← artifact `mosip-identity-plugin`,
    version property `mosip-identity-plugin.version`.

Bump the matching `<*.version>` property in `pom.xml` to change which
version of a JAR gets packaged — see `../AGENTS.md`'s guidance on
verifying release vs. snapshot coordinates before doing so.

## `Dockerfile`

`FROM nginx@<digest>` (pinned), then: installs `openjdk-11-jdk` +
`unzip`/`wget`/`zip`, downloads Maven 3.8.8 via `wget`, creates a
non-root `container_user`. **The Maven download has two known,
unaddressed issues**: it's fetched from `dlcdn.apache.org`, which only
mirrors the current release and 404s for an archived version like
3.8.8 (`archive.apache.org` is the correct permanent host for old
releases); and the downloaded archive is `tar`-extracted with no
checksum/signature verification, so a compromised mirror or
man-in-the-middle could substitute a tampered Maven distribution before
it ever runs. There is no formal tracked security exception (owner/review-date) for
this — it's simply been touched and reverted before in this repo's
history, so treat it as a deliberate maintainer choice, not an
oversight: confirm with a maintainer before changing this line rather
than "fixing" it unilaterally. Defines the working paths
as `ENV` vars
(`base_path=/usr/share/nginx/html/artifactory`, plus
`cache_path`/`mosip_plugins_zip_path`/`i18n_zip_path`/`theme_zip_path`/
`image_zip_path`/`esignet_wrapper_lib_zip_path`, all derived from
`base_path`) — `configure.sh` consumes these exact variable names, so a
path change here must be mirrored there (see root `AGENTS.md`'s
Repository-Specific Considerations). Copies every `src/...` asset
directory and the plugin zip into the image, then runs
`mvn dependency:resolve && mvn clean install` (the `install` here has
nothing to install — this pom has no source, it just forces dependency
resolution to fail loudly if a JAR can't be found), then `bash
configure.sh`, then patches `nginx.conf`'s listen port from 80 to 8080
via `sed`.

## `configure.sh`

Zips each downloaded/copied asset set in place and removes the
now-redundant unzipped directory:

- `esignet-wrapper/` and `esignet-plugins/` (the JARs from `pom.xml`,
  each directory zipped into one `.zip`).
- Four i18n bundles: `oidc-demo-i18n-bundle.zip`,
  `mock-relying-party-i18n-bundle.zip`, `esignet-i18n-bundle.zip`,
  `esignet-signup-i18n-bundle.zip`.
- Two theme bundles: `esignet-theme.zip`, `esignet-signup-theme.zip`.
- Two image bundles: `esignet-image.zip`, `esignet-signup-image.zip`.

If you add a new i18n/theme/image module, add both the `COPY` line in
`Dockerfile` **and** the matching `zip`/`rm -rf` pair in `configure.sh`
— they are not driven by a shared list, each is hand-maintained.

## Build & Test Commands

```bash
cd artifacts
docker build -t esignet-artifactory-server .
```

To check what Maven would resolve without a full image build:

```bash
cd artifacts
mvn dependency:resolve
```

## Agent rules

### Do

1. Add new static assets under the matching `src/{i18n,theme,image}`
   subdirectory, then update both `Dockerfile`'s `COPY` lines and
   `configure.sh`'s zip/cleanup lines for a new bundle.
2. Verify a version bump in `pom.xml` against the actual artifactId
   (not just the property name) — see the wrapper/plugin table above,
   since two of the five don't share their property name's wording
   with their real Maven artifactId.

### Do not

1. Do not assume `pom.xml`'s property names match the underlying Maven
   artifactIds — `esignet-digital-credential-wrapper.version` resolves
   `sunbird-rc-esignet-integration-impl`, not a "digital-credential"-named
   artifact.
2. Do not change an `ENV` path in `Dockerfile` without updating the
   corresponding reference in `configure.sh`, or vice versa.
