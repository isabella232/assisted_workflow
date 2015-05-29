Releasing
=========

Assisted Workflow uses a set of `rake` tasks to create packages and bundles [traveling
ruby][traveling_ruby] to simplify the dependency on Ruby.

Generating packages
-------------------

Packages can be generated for the following systems:

* OSX `rake package:osx`
* Linux x86 `rake package:linux:x86`
* Linux x86_64 `rake package:linux:x86_64`

You can generate all packages with `rake package:all`

[traveling_ruby]: https://github.com/phusion/traveling-ruby

The packages generated are tarballs of the following directory structure:

    aw-package
    ├── bin # shims
    └── lib
        ├── app # where aw is installed as a gem with its dependencies
        └── ruby # traveling ruby for target system

Releasing a new version
-----------------------

1. Update the version in `lib/assisted_workflow/version.rb`
1. Update the `CHANGELOG.md` with the news
1. Use `rake release` to tag and publish the new version as a gem
1. Generate the osx package with `rake package:osx`
1. Create a [release] for the latest tag and attach the packages
1. Update the [homebrew formula] to point to the latest OSX package

[release]: https://github.com/inaka/assisted_workflow/releases
[homebrew formula]: https://github.com/inaka/homebrew-formulas