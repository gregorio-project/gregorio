# Contributing guide for Gregorio

## Reporting an issue

You can report a bug and request a new feature on the [bug tracker](https://github.com/gregorio-project/gregorio/issues).

Please search for existing issues before reporting a new one. 

Please do not use the issue tracker for personal support requests, instead use the mailing-list (https://gna.org/mail/?group=gregorio) or IRC: #gregorio on freenode.

### Report a bug

When you report a bug, please provide the following information:

 * version of Gregorio
 * a minimal example (gabc or gabc+tex if relevant) showing the bug
 * a screenshot of the wrong result
 * a precise description (if possible with a picture) of the expected output

### Request feature

When requesting a feature, please provide the following informations:

 * a minimal example (gabc or gabc+tex) that currently doesn't work, but would
   if the feature was done
 * a precise description (if possible with a picture) of the expected output

## Contributing code

### Development environment

It is not currently possible to compile Gregorio under Windows. The build requirements
are the same under GNU/Linux and Mac OSX:

 * [git](http://git-scm.com/)
 * the [GNU Build System](http://airs.com/ian/configure/) (often referred to as "Autotools")
 * [gcc](https://gcc.gnu.org/) (and associated tools)
 * [GNU indent](https://www.gnu.org/software/indent/) (OSX default indent won't work)

### Coding standards

##### C files

The C code follows the [GNU coding standards](https://www.gnu.org/prep/standards/html_node/Writing-C.html). 

Use indent on your code before commiting it, with the `.indent.pro` file in repository's root folder: run `indent path/to/my/file.c` from the root directory.

##### Other files

The rest of the code uses four spaces for indentation.

Gregorio provides an [`.editorconfig` file](../.editorconfig), using an [editorconfig plugin](http://editorconfig.org/#download) for your editor will configure it automatically.


### Tests

When your changes are significant, please provide a test demonstrating the change. See [test documentation](tests/).

### Git Workflow

The Gregorio team is following the [classical Github workflow](https://guides.github.com/introduction/flow/). More precisely it follows what is sometimes described as "[Gitflow Worflow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow)", keeping the same branch naming convention.

### Make a pull request

Once you are ready to contribute code:

 * fork the repository and checkout your fork
 * create a new branch for the pull request you want to make
 * commit your changes to this new branch
 * make a pull request from this new branch to the relevant branch (usually `develop`)
 * the Gregorio developers will inspect and comment your pull request, and finally merge it (or not)
