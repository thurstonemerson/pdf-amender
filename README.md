# PDF Amender

This perl script takes a PDF file and modifies it to include user specified outline entries 
(also known as bookmarks). This script was originally developed to be used with the [Greenstone](http://www.greenstone.org/) digital library.

## Environment

You'll need the following for your development environment:

- [Perl](https://www.perl.org/)

## Local Installation

The following assumes you have all of the tools listed above installed.

1. Clone the project:

    ```
	$ git clone https://github.com/thurstonemerson/pdf-amender.git
	$ cd pdf-amender
    ```

1. Install required modules:

    ```
	$ cpan PDF
    ```

## Run the program

- Edit related_documents.csv to contain a list of bookmark titles and urls
 	
- The perl script may be run with the following command:
    ```
	$ perl amend_pdf.pl test.pdf related_documents.csv
	```
	
- A file called tmp_test.pdf will be created, containing a set of bookmarks linked to urls as specified in the related_documents.csv
 	

## Known Issues

- The PDF specification has likely changed since 2001, this script needs to be tested against modern pdf files

## License

The MIT License (MIT)

Copyright (c) 2001 Thurston Emerson

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

