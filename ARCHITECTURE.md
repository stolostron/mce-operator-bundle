# Architecture: mce-operator-bundle

## Overview

`mce-operator-bundle` is the **OLM (Operator Lifecycle Manager) bundle
image** for the **MultiCluster Engine (MCE)** operator. It packages, per
OLM's `registry+v1` bundle format, the metadata and manifests needed to
install/upgrade the MCE operator on OpenShift/Kubernetes via OLM. It does
not contain application code — it is a packaging/delivery artifact.

The actual operator this bundle installs is `backplane-operator`
(`registry.redhat.io/multicluster-engine/backplane-rhel9-operator`). This
bundle wraps that operator's CSV/CRD, declares the ~45 operand images MCE
deploys, and is consumed downstream by the File-Based Catalog in
`acm-mce-operator-catalogs`, which OLM uses to surface MCE in OperatorHub.
MCE is a foundational building block beneath Red Hat Advanced Cluster
Management (ACM).

### Role in the ecosystem

```
backplane-operator (built as an image + CSV/CRD source)
                │  (Konflux Snapshot captures component image digests)
                ▼
mce-operator-bundle           (this repo: assembles the OLM bundle)
                │  (bundle push pipeline "nudges" the catalog repo)
                ▼
acm-mce-operator-catalogs     (builds the File-Based Catalog)
                │
                ▼
OLM / OperatorHub on OpenShift
```

## Repository Structure

| Path | Purpose |
|------|---------|
| `Dockerfile` | Bundle image build. `FROM scratch`, copies `manifests/`, `metadata/`, `extras/`. |
| `manifests/` | The OLM bundle payload: CSV, CRD, config `ConfigMap`, webhook `Service`. |
| `metadata/annotations.yaml` | OLM bundle annotations (mediatype, package, channels). |
| `extras/<version>.json` | Full image manifest (image key → digest + git provenance) for all bundled images. |
| `config/` | Generation inputs: CSV template, image-manifest config, bundle-gen bash config, Dockerfile template. |
| `latest-snapshot.yaml` | The Konflux `Snapshot` CR that seeds bundle generation. |
| `BUILD-NUMBER`, `Z_RELEASE_VERSION` | Build iteration number and base release version. |
| `.tekton/` | Konflux/Tekton PipelineRun definitions (push + pull-request). |
| `.github/workflows/` | GitHub Action that regenerates bundle contents when the snapshot changes. |

## Core Components

### ClusterServiceVersion (`manifests/multicluster-engine.v<version>.clusterserviceversion.yaml`)

- `spec.version`, `spec.replaces`/`olm.skipRange` define the upgrade graph
  (notably spanning a version-numbering realignment from the 2.x series to
  5.x, requiring a wide `skipRange`).
- `operatorframework.io/initialization-resource` and `alm-examples` both
  point at a `MultiClusterEngine` sample.
- `installModes`: OwnNamespace and AllNamespaces.
- **Owned CRD**: `MultiClusterEngine` (`multiclusterengines.multicluster.openshift.io`).
- `spec.install.strategy: deployment` — a single `multicluster-engine-operator`
  Deployment (2 replicas, pod anti-affinity) running the `backplane-operator`
  binary, with ~40 `OPERAND_IMAGE_*` environment variables each pinned to a
  digest — this is how `backplane-operator` learns which operand images to
  deploy.
- `spec.relatedImages` mirrors the operand image set for OLM mirroring in
  disconnected environments.

### CRD (`manifests/multicluster.openshift.io_multiclusterengines.yaml`)

`MultiClusterEngine` — cluster-scoped, shortname `mce`.

### Supporting manifests

A controller-manager `ConfigMap` (health/metrics/webhook ports, leader
election) and a webhook `Service` routing to pods labeled
`control-plane: backplane-operator`.

### Generation inputs (`config/`)

- `mce-bundle-gen-config` — bash configuration: package name, supported OCP
  version range, supported archs/OS, EUS configuration, minimum upgrade
  version.
- `mce-manifest-gen-config.json` — maps product image keys to their Konflux
  component/published names, plus external images (some expressed as
  ranked `image-ref` arrays for fallback resolution).
- `mce-csv-template.yaml` — the CSV skeleton filled in during generation.
- `Dockerfile.in` — templated Dockerfile.

## Data / Control Flow

1. **`latest-snapshot.yaml`** is a Konflux `Snapshot` listing every
   component image digest and its source git revision; it is updated by an
   automated bot PR whenever component images are rebuilt.
2. That PR triggers `.github/workflows/gen-bundle-contents-when-triggered.yaml`,
   which authenticates to registries and runs
   `tools/run-script-from-tools-repo config/bundle-pr-config-vars`.
3. The shim clones `stolostron/release` and invokes the shared
   bundle-generation logic, which consumes the Snapshot plus `config/*` to
   regenerate `manifests/*.csv.yaml`, `manifests/*crd*`, the `ConfigMap`/
   `Service`, `extras/<version>.json`, and `Dockerfile`, bumping
   `BUILD-NUMBER`.
4. The regenerated files are committed back to the release branch.
5. The Konflux `.tekton` pipeline builds and pushes the bundle image; the
   push pipeline's `build-nudge-files` annotation triggers regeneration of
   the downstream FBC catalog in `acm-mce-operator-catalogs`.
6. OLM/OperatorHub reads the catalog, and installing the operator applies
   the CSV/CRD; creating a `MultiClusterEngine` CR causes `backplane-operator`
   to deploy operands using the pinned `OPERAND_IMAGE_*` values.

## Build, Test & Release

- **Dockerfile**: single-stage `FROM scratch`, copies manifests/metadata/
  extras, applies OLM + Red Hat delivery labels.
- **Konflux/Tekton** (`.tekton/`): push and pull-request PipelineRuns
  referencing the shared pipeline `pipelines/common-oci-ta.yaml` in
  `stolostron/konflux-build-catalog`; hermetic, source-image builds; push
  pipeline nudges the catalog repo.
- **GitHub Actions**: bundle-content regeneration on snapshot change.
- **Version/release mapping**: `Z_RELEASE_VERSION` + `BUILD-NUMBER` compose
  the image `version`/`release` (e.g. `5.0.0-202`); OLM channel is
  `stable-5.0`; branch naming follows `backplane-<X.Y>`.

## Dependencies & Integrations

- **`stolostron/backplane-operator`** — the operator whose CSV/CRD this
  bundle ships.
- **`stolostron/acm-mce-operator-catalogs`** — downstream FBC catalog,
  nudged by the bundle push pipeline.
- **`stolostron/release`** — shared bundle-generation tooling.
- **`stolostron/konflux-build-catalog`** — shared Tekton pipeline
  definitions.
- **~45 operand images** (each a separate `stolostron/*` or `openshift/*`
  repo) referenced by digest — cluster lifecycle (Hive, HyperShift, Cluster
  API providers), registration/work/placement, assisted installation,
  console-mce, and more.
- **Registries**: operands published under `registry.redhat.io/multicluster-engine/`;
  bundle images built to `quay.io/redhat-user-workloads/crt-redhat-acm-tenant/`.

## Conventions & Patterns

- **Everything is generated, not hand-edited** — manifests, CSV, Dockerfile,
  and `extras/` are produced from `config/` templates plus
  `latest-snapshot.yaml`. Edits should target `config/` and the snapshot,
  not the generated outputs.
- **Fully pinned digests** on all operand and related images.
- **Dual image expression**: operands appear both as `OPERAND_IMAGE_*`
  environment variables (consumed at runtime by `backplane-operator`) and
  as `spec.relatedImages` (for OLM mirroring).
- **Branching**: `backplane-<X.Y>` release branches, with automated
  "Gen Latest Snapshot" bot PRs updating the snapshot.
- **Component naming**: Konflux component suffix encodes the release
  (e.g. `mce-50`); image keys are snake_case, Konflux component names are
  kebab-case (mapped explicitly in the manifest-gen config).
