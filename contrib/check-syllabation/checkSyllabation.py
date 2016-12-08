#! /usr/bin/env python3

"""
    A script to check the syllabation of a gabc file

    See checkSyllabation.py -h for help

    Copyright (C) 2016 Elie Roux
    
    Permission is hereby granted, free of charge, to any person obtaining a copy of
    this software and associated documentation files (the "Software"), to deal in
    the Software without restriction, including without limitation the rights to
    use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
    of the Software, and to permit persons to whom the Software is furnished to do
    so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

    Depends on pyphen: http://pyphen.org/
    You also need the hyph_la_liturgical.dic file. To get it, get the
      hyphen-la project on https://github.com/gregorio-project/hyphen-la
      and run "make" in the "patterns" directory.

"""

import sys
import re
import argparse
import pyphen

def get_parser():
    "Return command line parser"
    parser = argparse.ArgumentParser(
        description='A script to check the syllabation of a gabc file.')
    parser.add_argument('-p', '--pat-path',
                        help='path to the .pat file, mandatory',
                        action='store', required=True)
    parser.add_argument('gabc_path', 
                        help='The Gabc file to check',
                        action='store')
    return parser

def deacc(accstr):
  return accstr.replace('á', 'a').replace('é', 'e').replace('í', 'i').replace('ó', 'o').replace('ú', 'u').replace('ý', 'y').replace('́', '').replace('ǽ', 'æ')

def checkwords(words_list, hyphenator):
    nb_errors = 0
    for word in words_list:
        initialword = deacc(word.lower())
        if initialword.find('-') == -1:
            # no need for noise
            continue
        correctword = hyphenator.inserted(initialword.replace('-',''))
        if correctword != initialword:
            print(initialword+' should be '+correctword)
            nb_errors += 1
    return nb_errors

def get_words_list(gabc_content):
    gabc_content = gabc_content.split('%%\n', 1)[1] # no headers
    gabc_content = re.sub(r'%.*\n', '', gabc_content)
    gabc_content = gabc_content.replace('\n', ' ').replace('\r', ' ').replace('{','').replace('}','').replace('<sp>\'ae</sp>', 'æ').replace('<sp>ae</sp>', 'æ')
    gabc_content = gabc_content.replace('<sp>oe</sp>', 'œ').replace('<sp>\'oe</sp>', 'œ').replace('.','').replace(':','').replace(';','').replace(',','').replace('*','').replace('?','').replace('!','')
    gabc_content = re.sub(r'\([^\)]*\)', '-', gabc_content)
    gabc_content = re.sub(r'<\/?[ibuc]>', '', gabc_content)
    gabc_content = re.sub(r'<\/?sc>', '', gabc_content)
    gabc_content = re.sub(r'<\/?eu>', '', gabc_content)
    gabc_content = re.sub(r'<v>[^>]*</v>', '', gabc_content)
    gabc_content = re.sub(r'<alt>[^>]*</alt>', '', gabc_content)
    gabc_content = re.sub(r'\[[^\]]*\]', '', gabc_content)
    gabc_content = re.sub(r'-+', '-', gabc_content)
    gabc_content = re.sub(r'-?\s+', ' ', gabc_content)
    gabc_content = re.sub(r'\s+-', ' ', gabc_content)
    return gabc_content.split()

def main():
    "Main function"
    parser = get_parser()
    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit(1)
    args = parser.parse_args()
    hyphenator = pyphen.Pyphen(filename=args.pat_path,left=1,right=1)
    words_list = []
    with open(args.gabc_path, 'r') as inputf:
        words_list = get_words_list(inputf.read())
    nb_errors = checkwords(words_list, hyphenator)
    if nb_errors == 0:
        print('no error!')

if __name__ == "__main__":
    main()
