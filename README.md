Built against Node.js 0.10.36.

Install it:

```
npm install --global panoptes-subject-uploader
```

Then run it on (a) manifest file(s). **Images must be in the same directory as their manifest.**

```
panoptes-subject-uploader ./path/to/manifest.csv ./another/path/to/a/different/one.csv
```

All manifests specified in a single run of the command are put in the same subject set.

Flags (required):

- `--username` defaults to env's `PANOPTES_USERNAME`

- `--password` defaults to env's `PANOPTES_PASSWORD`

- `--project` ID, defaults to env's `PANOPTES_PROJECT`

- `--workflow` ID, defaults to env's `PANOPTES_WORKFLOW`

Optional:

- `--subject-set` ID, **defaults to a new subject set**

Defaults to the staging server. Switch it with e.g. `NODE_ENV=production`.

You can also set `PANOPTES_API_HOST` and `PANOPTES_API_APPLICATION` manually if you want to do this on another host.
