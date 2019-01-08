# jl-pkgman Design Notes

# Requirements and Goals

Package discovery via package metadata ("directory") sources. Supported package directory (metadata) sources:

* MathWorks File Exchange
  * List projects, get version for a particular project
* GitHub
  * Point at a package repo - should provide a list of versions from GitHub Releases
* Git repos holding metadata (like Homebrew taps)
  * A central one managed by me
  * Custom user-managed ones
* Local files
  * Like taps, just on the local filesystem. Probably stored under the Repositories.

Both conventions and explicit configuration for the install and load process. Conventions:
* Auto-detect source code dirs (like ., Mcode/, and src/; check to see if
  they contain .m files)
* A conventional location for Java, Python, and C libs? E.g. `lib/(python|java)/<libname>-<version>`

Dependency management
* With version specification

* Multiple versions of a package can be installed
* Special `HEAD` version for installing from the head of a source control repo
  * Updating `HEAD` versions as part of update when there are more commits

Test support, like `brew test <pkg>`.

Caching of downloaded distribution files. May want to support shared caches in
the system and site repositories in addition to the user repository.

### Version identification

Support arbitrary strings as versions. Support both SemVer and non-SemVer version
styles. (Parse version to decide if it's SemVer; assume that anything matching
the pattern is.)

Only SemVer versions can be compared for ordering (i.e. `<`/`<=`/`>=`/`>` and `sort()`
calls).

Special pseudo-versions:
  * `HEAD` - the latest commit in the development source code repo
  * `latest` - the latest actual release, within the context of some metadata scope

### Package "loading"

This is what loads an installed package into a Matlab session and makes it ready
for use. Involves getting stuff on the Matlab, Java, and Python paths, and possibly
calling a library initialization function.

### Cross-platform support

Support for all three of Linux, Mac, and Windows.

This includes locating files under appropriate special directories in the Windows
user profile instead of naively using ~/.jl-pkgman. Config info should go in
roaming profile; installed packages and other repository data in the local
profile.

### Enterprise features

* Support for a "site" configuration file, that goes behind the system and user config
files
  * Defining the site config file path via environment variables and other things that
    sysadmins can manage. Maybe registry entries? How would you locate that on Windows?
* Multiple repositories on network drives, in addition to the default system and user repos
* Site-level download/data caching

### Matlab Compiler SDK support

I want to be able to build stuff with `mcc` in a way that picks up installed
packages. Can't rely on just Matlab's `depfun` detection, because of `eval()`,
and because that doesn't pick up resource files (or Python source) in packages.
Prob need a wrapper that adds the entire package directories.

# Terms

* Package - a collection of Matlab code to be installed
* PackageVersion - a specific version of a package
  * A PackageVersion corresponds to the Maven notion of an artifact. This is the
    concrete level that actually defines dependencies, build, and load steps.
  * This is a lousy name, because PackageVersion means "Package of a particular
    version", not "version of a package".
* Maybe PackageMeta and PackageVersionMeta, for the metadata describing Packages
  and PackageVersions.
* Repository - a filesystem location that holds installed packages, locally-defined
  metadata, and maybe config
* PackageList - a list of package name/version pairs. This is used to indicate which
  installed packages to load. That's our equivalent of virtualenvs. May also
  be used to identify sets of packages to install. It's a List, not a Set, because
  it is ordered: it can be used to specify a specific package load order, for
  manual resolution of dependencies. (Since we won't support dependency graph
  resolution that well in our initial implementations. And maybe we can't even
  do that for everything, since there may be circular dependencies.)

# Package metadata

### Package level

* Name
* Source code repo (e.g. )
* Project home page (URL)
* Enumeration of existing versions
* Maintainer info?

### PackageVersion level

* Name
* Version
* Dependencies
* Download location(s)
* Installation process
* Test process

### Metadata mutability

Neither Package nor PackageVersion definitions are immutable. A package's home
page or source code hosting may change.

And a PackageVersion may get more info about
its dependencies after it is initially released. For example, package `foo` v `1.0` may
depend on package `bar` v `2.0` or later. At the time of foo 1.0's release, all
bar 2.x versions worked. But then let's say a bar 2.4 version comes out that
despite it being just a minor version change, broke things. So now foo knows its
dependencies are `bar >=2.0 <2.4`, not just `bar >=2.0`.

Since a package's distribution file should not be changed after posting, this
means that PackageVersion metadata needs to maintained outside the package dist itself,
and can be changed over its lifetime. (Unlike Maven. Maven gets away with it because
it only allows dependencies on specific versions. I don't want to be that inflexible.)

### Representation

Within `pkgman`, this metadata should be represented as objects, and may be drawn
from various metadata source objects (e.g. a FileExchangeClient or TapClient or
GitHubClient or files in a local repository). But we should define file formats
for managing the definitions locally. Could be JSON or XML. JSON would be more
user-friendly. Maybe support both JSON and XML formats.

# Building packages

Some packages may need build steps, including MEX file compilation, Java or other
C code compilation, and ...?

Special note: we want to support a scenario where an installed package at a single
location can be compiled to have cross-platform support (that is, MEX files for
Windows, Mac, and Linux all side-by-side in the same directory.) This means the install
process can't be a linear extract-to-staging/build/copy-to-destination sequence,
because the products from multiple OSes need to be merged. So we probably need
to support a build-in-place method for installed packages. Useful for enterprise
users mostly, that want to retain a network drive repository that can be used
in a heterogeneous environment.

Because of the requirements for multi-platform builds, and because the build steps
of a Matlab package might bake detected paths to self in to files, we might need
to do the builds in the actual in-repository location instead of a staging
directory. Then cross-platform builds are just skipping the fetch/extract/patch/munge
steps and going right to the build/post-build steps.

## Steps in a build

* Fetch/download
* Extract (to staging tempdir?)
* Patch - apply patch files
* Munge - arbitray modifications of the source files
* Build - run necessary compilation steps
* Post-build hook, maybe?
* Test?
* Install - move to destination dir in repository

#  Interface

* Everything in package `jl.pkgman`
* Main user-facing `jl.pkgman.pkgman` object that does everything
  * Probably needs to be one you construct and call instance methods on, instead
    of supplying static methods. Because it'll need to read config info and construct
    the "world" as part of initialization, and provide hooks for changing that
    configuration at run time.
* Maybe some convenience comman-style functions like `jl.pkgman.install`, `jl.pkgman.test`
  * These will be wrappers around the public API of `jl.pkgman.pkgman`. Everything
    you can do with them, you can also do with calls to `jl.pkgman.pkgman`.


#  Questions

Do we need to support per-Matlab-version installation of packages? E.g. there
are different versions of MEX file compatibility and their relevant files. And
version-dependent data files (like .mat caches) might be generated as part of
the package build step.

Do we need a group or scope element for package identifiers, like Maven's "groupId"?
