# Panoptes Subject Uploader

A command line client for uploading subjects to projects built on zooniverse.org (Panoptes).

## Setup

Panoptes Subject Uploader depends on node.js to function and this must first be installed before the client can be installed and run.

### Linux or Windows
For Linux or Windows users depending on which OS and distribution you use, refer to [node.js's guide](https://nodejs.org/en/download/package-manager/) on how to install it. The rest of this documentation will focus on OS X setup.

### OS X
For OS X users, several dependencies are needed prior to installing the client. All of the following commands will be used in the terminal app. 

Xcode is a set of developer tools published by Apple. Xcode's Command Line Tools will need to be installed:

`xcode-select --install`

> If necessary, Xcode itself can be updated from the App Store or from the [Apple Developer Website](https://developer.apple.com/xcode/).

Node.js can be installed using Homebrew, a package manager. Install Homebrew:  

`/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`

You'll need to configure OS X to use the packages that Homebrew installs instead of the OS X defaults if they exist. This can be set in your bash profile.

If you don't have an existing `.bash_profile` file, you can create one by:

`cd ~`

to go to your home folder and then: 

`touch .bash_profile`.

To add the configuration to use Homebrew instead of OS X defaults to your bash profile:

`echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bash_profile`

Open a new terminal window and close the old one. Ensure successful Homebrew installation and any packages it is managing.

`brew doctor`

Now that Homebrew is setup, you can install node.js:

`brew install node`

A package manager called NPM will be installed with node.js and with it you can install Panoptes Subject Uploader.
> Node can be updated by: 

>`brew update` 

> then

> `brew upgrade node`

## Installing

You can install the client from [NPM](https://www.npmjs.com/package/panoptes-subject-uploader):

`npm install --global panoptes-subject-uploader`

## Getting Started

Panoptes Subject Uploader can be used to assist with subjects upload after a project is setup with a workflow. the filenames and associated metadata must also be in (a) manifest CSV file(s). The [How To Build a Project guide](https://www.zooniverse.org/lab-how-to) on [zooniverse.org](https://www.zooniverse.org/) provides a step through process on how to prep any of these requirements.

__If you're uploading subject media, the subject media files must be in the same directory as their manifest(s).__ 

__If you're using media hosted elsewhere, you must provide https links to the media for each subject in the subject's row in the manifest.__

All manifests specified in a single run of the `panoptes-subject-uploader` command are put in the same subject set.

Flags that can be set when running:

### Required Flags
flags | defaults (can be set by environment variables)
--- | ---
`--username` | defaults to env's `PANOPTES_USERNAME`
`--password` | defaults to env's `PANOPTES_PASSWORD`
`--project` | project ID, defaults to env's `PANOPTES_PROJECT`
`--workflow` | workflow ID, defaults to env's `PANOPTES_WORKFLOW`

### Optional Flags
flags | defaults
--- | ---
`--subject-set` | subject set ID, __defaults to a new subject set__
`--skip-media-upload` | boolean, __defaults to false__

If you do not specify a subject set ID, the uploader will default to a new subject set and the new set will also be visible to the specified workflow in the classifier. If you do not want the subjects to be visible in the classifier yet, then create the subject set ahead of time in the project builder and specify the ID in the subject set flag.

If you want to use media hosted elsewhere, set `--skip-media-upload=true`. You must provide a https url to the media for each subject in the manifest.

Panoptes Subject Uploader __defaults to the staging server.__ Switch it with `NODE_ENV=production` in the command line. The production environment is what zooniverse.org uses.

Any of the environment variables can be added to your bash profile:

`echo 'export PANOPTES_PROJECT="1110"' >>~/.bash_profile`

Alternatively you can edit the `.bash_profile` file in a text editor like sublime text or vim.

### Example

A full example of a run of the `panoptes-subject-uploader` command:

`NODE_ENV=production panoptes-subject-uploader ./manifest1.csv --username=user --password=p@ssw0rd --project=1110 --workflow=2343`


