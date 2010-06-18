/* 
Gregorio unicode headers.
Copyright (C) 2008 Elie Roux <elie.roux@telecom-bretagne.eu>.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

This file is used only for the ALL_STATIC option, it contains the definitions of
the functions called to read or write scores for the different plugins.
*/

#ifndef PLUGINS_H
#define PLUGINS_H

void dump_write_score (FILE * f, gregorio_score * score);

gregorio_score *gabc_read_score (FILE * f_in);
void gabc_write_score (FILE * f, gregorio_score * score);

void gregoriotex_write_score (FILE * f, gregorio_score * score);

void opustex_write_score (FILE * f, gregorio_score * score);

gregorio_score * xml_read_score (FILE * f);
void xml_write_score (FILE * f, gregorio_score * score);

#endif
