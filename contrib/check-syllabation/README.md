# Syllabation checker

The scripts in this folder allow to check the syllabation of a gabc score against syllabation rules that you must provide.

## Dependencies

The main script, `checkSyllabation.py` is in Python3, so you obviously need it. It uses the [pyphen](http://pyphen.org/) package. You will also need the hyphenation of the text language in order to run it.

If you want liturgical Latin hyphenation rules, you can pick those in [hyphen-la](https://github.com/gregorio-project/hyphen-la). Note that you will have to convert them to the `libhyphen` format in order to use them with `pyphen`, see [hyphen-la pattern documentation](https://github.com/gregorio-project/hyphen-la/tree/master/patterns#converting-to-libhyphen-format) for that.

## Running the scripts

Once you have the hyphenation rules in the `libhyphen` format, you can check one score by running

```
checkSyllabation.py -p path/to/file.dic my_file.gabc
```

where `path/to/file.dic` is the path to the hyphenation rules file (default is `hyph_la_liturgical.dic` in the current directory). You can also analyze all gabc scores of a directory (with subdirectories) by replacing `my_file.gabc` by the name of the directory. By default, the script analyzes the current directory. The script outputs the report to `stdout` on Unix systems, and to `check-syllabation.log` on Windows systems.

You can see more options by running

```
checkSyllabation.py --help
```

## Hyphenation problems

If you encounter problems of hyphenation, meaning you disagree with the proposed hyphenation, please contact the author of the hyphenation rules you are using ([here](https://github.com/gregorio-project/hyphen-la/issues) for `hyphen-la` for example).

If you encounter problems because the script got confused by a gabc construct you are using or has bugs not directly related to hyphenation, please report it on the [gregorio tracker](https://github.com/gregorio-project/gregorio/issues).
