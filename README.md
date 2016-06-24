# Panoptes Subject Uploader

A command line client for uploading subjects to projects built on zooniverse.org (Panoptes).

## Setup

The client is working against Node.js >=0.10.36. Node.js must be setup first prior to installing it. [Instructions for node.js installation](https://nodejs.org/en/download/package-manager/).

### Installation

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
- `--skip-media-upload` boolean, **defaults to false**

Defaults to the staging server. Switch it with e.g. `NODE_ENV=production`.

You can also set `PANOPTES_API_HOST` and `PANOPTES_API_APPLICATION` manually if you want to do this on another host.

#### Example

A full example of a run of the panoptes-subject-uploader command in production:

```
NODE_ENV=production panoptes-subject-uploader ./manifest1.csv --username user --password p@ssw0rd --project 1110 --workflow 2343
```

#### Best Practices

**General Usage:** It's recommended to upload relatively small batches at a time, 1000-2000 subjects. OSX and Linux users should consider running the client using [screen](https://www.gnu.org/software/screen/manual/screen.html) so the client can continue to run even if you close the terminal window.

**Links without file extensions:** If you’re using media hosted elsewhere, the links to the media files must have one of the following file extensions: jpg, jpeg, gif, png, svg, mp4, txt. Links without one of those file extensions will be interpreted as subject metadata, not as a subject location.

**Logging:** The client will generate a log file, `panoptes-subject-uploader.log`, which will be written to the same folder that the client is run under. The log file will be appended on subsequent runs in the same folder. Logs are written in JSON format for ease of script use with it. 

**Error Handling:** The client will reattempt http requests on network errors and 5xx errors every 5 seconds up to 5 times. If there is an error after the 5 attempts, then it will be logged in `panoptes-subject-uploader.log`. A good indicator of an error is if the number of subjects linked to a subject-set (final line of the client run) does not match the number of subject rows in the manifest.

### License

Copyright 2015 Zooniverse

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.