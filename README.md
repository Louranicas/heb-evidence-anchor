# HEB evidence anchor

Off-host, append-only custody for the HEB residual-evidence corpus.

This repository is **public and deliberately content-free**. It publishes hashes and
nothing else — no file paths, no filenames, no evidence content, no source. Every record
under `anchors/` is a small JSON object of SHA-256 values.

## Why it exists

HEB residual **#4.8** requires the evidence anchor to live on a governed remote with
*protected append-only / compare-and-swap behaviour* — the remote must **refuse** a
history rewrite at push time, not merely detect one afterwards.

Two prior tranches each solved half of it:

| tranche | venue | enforcement |
|---|---|---|
| `r29-quarantine-governed-remote` | real external remote ✅ | tamper-**evidence** only ❌ |
| `r68-governed-remote-enforcement` | local bare repo over `file://` ❌ | real server-side **refusal** ✅ |

Neither supplied both in one leg. This repository is the venue half done properly:
a genuinely off-host remote, on infrastructure that enforces append-only server-side
via GitHub repository rulesets.

## What is published

```json
{
  "schema": "heb.external-anchor.v1",
  "anchored_utc": "...",
  "branch": "...",
  "head_commit": "<sha1>",
  "head_tree": "<sha1>",
  "manifest_sha256": "<sha256 of the private MANIFEST.md>",
  "digest_leaves": 1309,
  "digest_merkle_root": "<sha256>"
}
```

`digest_merkle_root` is a Merkle root over the **sorted, de-duplicated set** of every
SHA-256 digest named in the private manifest. It lets any single evidence digest be
proven to have been anchored at a point in time, without this repository ever holding
the path, the filename, or the bytes it refers to.

## Verifying an anchor

Holding the private corpus:

```bash
# recompute and compare against the published record
sha256sum docs/residual-evidence/MANIFEST.md      # -> manifest_sha256
git rev-parse HEAD HEAD^{tree}                    # -> head_commit, head_tree
```

If any evidence file, or the manifest itself, is altered after anchoring, the recomputed
values diverge from the published record — and because the ruleset below forbids rewriting
this repository's history, the published record cannot be quietly brought back into line.

## Enforcement

A repository ruleset on `main` blocks **non-fast-forward pushes**, **deletion**, and
requires **linear history**. These are enforced by the host at push time, server-side and
off-machine. The drill transcript proving each refusal is committed under `drills/`.

## Threat model — stated honestly

- **Prevents:** silent rewriting, deletion, or replacement of anchored history by anyone
  holding push credentials, including this machine.
- **Does not prevent:** a repository owner disabling the ruleset first. That action is
  itself logged by the host and is not silent. This is the same bound `r68` states: the
  guarantee is that tampering becomes *evident and refused*, not metaphysically impossible.
- **Discloses:** that a corpus of this size exists, and its hashes. Nothing about content.
