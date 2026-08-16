# WebGL CI/CD — auto-build & auto-publish

Goal: every push to `claude/extract-into-repo-b738b0` builds the Unity WebGL
player on GitHub's servers and publishes it to the live URL automatically — no
UBA, no zips, no manual steps.

Live URL: **https://fullstackassets.com/quahog/**

The main workflow is:
- `.github/workflows/deploy-webgl.yml` — the build + deploy pipeline.

Some branches may also include `.github/workflows/unity-activation.yml`, a
one-time helper that only prints the same license steps below.

You only have to do the setup below **once**.

---

## What you need to add: repository secrets

Go to the repo on GitHub → **Settings → Secrets and variables → Actions →
New repository secret**, and add:

| Secret name      | Value                                              |
|------------------|----------------------------------------------------|
| `UNITY_EMAIL`    | The email you log into Unity with                  |
| `UNITY_PASSWORD` | Your Unity account password                        |
| `UNITY_LICENSE`  | The **contents** of your `.ulf` license file (personal/free — steps below) |
| `UNITY_SERIAL`   | Your Unity serial number **(Pro/Plus only — alternative to `UNITY_LICENSE`)** |

You need `UNITY_EMAIL` + `UNITY_PASSWORD` plus **one** of `UNITY_LICENSE` or
`UNITY_SERIAL` depending on your license type.

---

## Getting `UNITY_LICENSE` (free Personal license)

Unity no longer supports the CI-based `.alf` activation workflow. You must
activate locally and then paste the resulting license into a GitHub secret.

1. Open **Unity Hub** on your machine.
2. Go to **Preferences → Licenses → Add → Get a free personal license**.
3. Unity Hub writes the license to a `.ulf` file on your machine:
   - **Windows:** `C:\ProgramData\Unity\Unity_lic.ulf` or `C:\ProgramData\Unity\config\Unity_lic.ulf`
   - **macOS:** `/Library/Application Support/Unity/Unity_lic.ulf`
   - **Linux:** `~/.local/share/unity3d/Unity/Unity_lic.ulf`
4. Open the `.ulf` in a text editor, copy **everything**, and paste it as the
   value of a new secret named **`UNITY_LICENSE`**.

> **Tip:** If your branch includes the **Acquire Unity Activation File**
> workflow (`.github/workflows/unity-activation.yml`), it now prints manual
> activation instructions when run — it no longer generates an artifact.

> **Have a paid Unity Pro/Enterprise plan?** Add a `UNITY_SERIAL` secret with
> your serial key (plus `UNITY_EMAIL` / `UNITY_PASSWORD`) — the workflow
> already forwards `UNITY_SERIAL` to the builder, so no other changes are
> needed.

---

## Make sure Pages points at the right place (one-time)

Repo → **Settings → Pages**:
- **Source:** Deploy from a branch
- **Branch:** `gh-pages` · **/(root)** · Save

(The pipeline pushes the built player to `gh-pages` on every run, so Pages just
serves whatever the latest build produced.)

---

## That's it

Once the required secrets are set:
- **Push to the branch → it builds → it deploys.** Check progress under the
  **Actions** tab. First build is ~20–30 min (no cache); later builds are faster.
- You can also trigger a build by hand: **Actions → Build & Deploy WebGL →
  Run workflow**.

### Notes
- The build runs the project's pre-build hook, which sets WebGL **Decompression
  Fallback** so the player loads on Pages without special server headers.
- The Unity version comes from `QUAHOG_Unity/ProjectSettings/ProjectVersion.txt`.
  If GitHub can't find a matching editor image, bump that file to a published
  Unity 6 version and push again.
- Private repos consume Actions minutes (WebGL builds are long). Public repos
  build for free.

---

## Troubleshooting

### `Error: Code 20110 ... (status: serial invalid)` → activation fails after 5 retries

This is the failure that has blocked every CI build so far. The build log shows
login and entitlement activation **succeeding**, then aborting:

```
User *** logged in successfully
[Licensing::Module] Successfully activated the entitlement license
[Licensing::Client] Error: Code 20110 while processing request (status: serial invalid)
[Licensing::Module] License activation has failed. Aborting.
Activation failed after 5 retries
```

`UNITY_EMAIL` / `UNITY_PASSWORD` are correct (login succeeds) — **the broken
secret is `UNITY_SERIAL`.** `game-ci/unity-builder` switches to serial-based
(Pro/Plus) activation whenever `UNITY_SERIAL` is **set and non-empty**, and the
serial it was given is invalid (`20110`).

**Fix — pick the path that matches your license:**

- **Free Personal license (most common here):** there is no serial. **Delete the
  `UNITY_SERIAL` secret entirely** (Settings → Secrets and variables → Actions →
  `UNITY_SERIAL` → Remove) and make sure `UNITY_LICENSE` holds the full contents
  of your `.ulf` file (see *Getting `UNITY_LICENSE`* above). An empty/whitespace
  value does **not** count as unset — it must be removed.
- **Pro / Plus:** keep `UNITY_SERIAL` but set it to your real serial in the exact
  format `XX-XXXX-XXXX-XXXX-XXXX-XXXX` (and remove `UNITY_LICENSE` so the serial
  path is used). A typo, trailing newline, or placeholder value triggers `20110`.

After fixing the secret, re-run **Actions → Build & Deploy WebGL → Run workflow**
(the trigger is `workflow_dispatch` — manual — so a bad config doesn't spam
20-minute failing builds on every push). Once it goes green you can re-enable the
auto-build-on-push trigger that is commented out at the top of
`deploy-webgl.yml`.
