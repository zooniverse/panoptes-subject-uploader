Working against Node.js >=0.10.36.

Detailed documentation on how to setup is available at [https://zooniverse.github.io/panoptes-subject-uploader/](https://zooniverse.github.io/panoptes-subject-uploader/).

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

License

Copyright 2015 Zooniverse

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.