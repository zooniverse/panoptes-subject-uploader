Built against Node.js 0.10.36.

Install it:

```
npm install --global panoptes-subject-uploader
```

Then run it on a manifest file. **Images must be in the same directory as the manifest.**

```
panoptes-subject-uploader path/to/manifest.csv
```

Options (all required):

- `--username` defaults to env's `PANOPTES_USERNAME`

- `--password` defaults to env's `PANOPTES_PASSWORD`

- `--project` ID, defaults to env's `PANOPTES_PROJECT`

- `--workflow` ID, defaults to env's `PANOPTES_WORKFLOW`

Defaults to staging server. Switch it with `NODE_ENV`.

You can also set `PANOPTES_API_HOST` and `PANOPTES_API_APPLICATION` if you want to do this on another host.
