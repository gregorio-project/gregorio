#!/usr/bin/env texlua
--[[
Gregorio gabc optimization script.
Copyright (C) 2010 Elie Roux <elie.roux@telecom-bretagne.eu>

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

You must run this program with texlua, if possible under a TeXLive 2010.
--]]

kpse.set_program_name("luatex")
require("lualibs")
require("alt_getopt")

local function log(...)
    texio.write_nl(string.format(...))
end

local function help_msg()
    texio.write([[
Usage: optimize_gabc.lua [OPTION] gabc_file tex_file
    
Optimize a gabc file according to a .tex file.

Valid options:
  -f --force                   remove end of lines in base gabc
  -a --agressive               agressive optimization
  -d --debug                   write debug files
  -V --version                 print version and exit
  -h --help                    print this message

The script optimizes the gabc file by forcing end of lines. 
]])
end

local version = '1.00'

local function version_msg()
    texio.write(string.format(
        "optimize_gabc version %s.\n", version))
end

--[[
Command-line processing.
Here we fill cmdargs with the good values, and then analyze it.
--]]

local long_opts = {
    debug            = "d",
    help             = "h",
    force            = "f",
    agressive        = "a",
    version          = "V",
}

local short_opts = "Vhadf"
local gabc_file, tex_file = nil, nil
local forced, agressive, debug = false, false, false

local function process_cmdline()
    local opts, optind, optarg = alt_getopt.get_ordered_opts (arg, short_opts, long_opts)
    for i,v in ipairs(opts) do
        if v == "V" then
            version_msg()
            os.exit(0)
        elseif v == "h" then
            help_msg()
            os.exit(0)
        elseif v == "f" then
            forced = true
        elseif v == "a" then
            agressive = true
        elseif v == "d" then
            debug = true
        end
    end
    if optind > #arg-1 then
        texio.write_nl("error: not enough arguments.\n")
        os.exit(1)
    end
    gabc_file = arg[optind]
    tex_file = arg[optind + 1]
end

process_cmdline()

function read_gabc_syllables(gabc_file)
    local f = io.open(gabc_file)
    local res = {}
    if not f then
        error("Cannot open the file "..gabc_file)
    end
    data = f:read("*a")
    for syllable in string.gmatch(data, "([^%(%%]*%([^%)]*%))") do
        syllable = syllable:gsub("[\n\r\t ]+", " ")
        res[#res+1] = syllable
    end
    res[1] = res[1]:gsub("^ ", '')
    local headers = string.find(data, '\n%%')
    if headers then
        res[0] = string.sub(data, 1, headers -1)
    end
    return res
end

function read_gabc_file(gabc_file, forced)
    local res = read_gabc_syllables(gabc_file)
    -- Now we have a table with all the syllables, and we analyze it.
    -- We remove spurious - and end of lines, and we keep in mind if we're at
    -- an end of words or not.
    for i, syl in ipairs(res) do
        local end_of_word = true
        local forced_eol = false
        local text = syl:sub(1, syl:find('%(')-1)
        if text:find('-$') or (res[i+1] and res[i+1]:sub(1, 1) ~= " ") then
            end_of_word = false
        end
        if forced then
            text = text:gsub('-$', '')
        end
        text = text:gsub('^ ', '')
        local notes = syl:sub(syl:find('%('), -1)
        -- ugly trickery: we want to keep z0, but remove z and Z
        notes = notes:gsub('z0', 'UUUU')
        if notes:find('[zZ]') then
            forced_eol = true
        end
        if forced then
            notes = notes:gsub('[zZ]+', '')
        end
        notes = notes:gsub('UUUU', 'z0')
        res[i] = {text..notes, end_of_word, forced_eol}
    end
    return res
end

function file_manipulation(gabc_file, gabc_tex_file)
    os.execute(string.format("unlink optimize-gabc.tex", gabc_tex_file))
    os.execute(string.format("ln -s %s optimize-gabc.tex", gabc_tex_file))
end

function simple_compile(gabc_file, tex_file, produce_pdf, iteration)
    log("executing gregorio %s", gabc_file)
    os.execute(string.format("gregorio %s", gabc_file))
    log("executing lualatex -draftmode %s", tex_file)
    -- we count the number of overfull boxes
    local test = nil
    local res = 0
    if not produce_pdf then
        test = io.popen(string.format("lualatex -interaction batchmode -draftmode %s |grep \"Overfull\"|wc -l", tex_file))
        --os.execute(string.format("lualatex %s", tex_file))
    else
        os.execute(string.format("lualatex -interaction batchmode %s >/dev/null", tex_file))
    end
    if test then
        res = test:read("*n")
        test:close()
    elseif not produce_pdf then
        log("unable to execute lualatex or error, exiting.\n")
        os.exit(1)
    end
    return res
end

function one_iteration(gabc_file, tex_file, syllables, lines, to_line, forced, final)
    if not final then
      simple_compile(gabc_file, tex_file, final, to_line)
    end
    local data = syllables[0].."\n%%\n"
    local line, syllables_in_line = 1, 1
    for i, syl in ipairs(syllables) do
        local eow, forced_eol
        forced_eol, eow, syl = syl[3], syl[2], syl[1]
        if line <= to_line and i == lines[line] and syllables[i+1] and (forced or not forced_eol) then
            -- we end the line
            line = line + 1
            if eow then
                if not final then
                    data = data..syl:sub(1, syl:find('%(')-1)..'<v>\\goptpos</v>'..syl:sub(syl:find('%('),-2)..'z)\n'
                else
                    data = data..syl:sub(1, -2)..'z)\n'
                end
            else
                --data = data..syl:sub(1, syl:find('%(')-1)..'<sp>-</sp>'..syl:sub(syl:find('%('),-2)..'z)\n'
                data = data..syl:sub(1, syl:find('%(')-1)..'-'..syl:sub(syl:find('%('),-2)..'z)\n'
            end
            -- here could be a big side-effect: as we insert a (z) in gabc, there is
            -- one more syllable which is not in the syllables table...
        else
            if i == lines[line] then
                line = line + 1
            end
            if eow and forced_eol and not forced then
                if final then
                    data = data..syl..'\n'
                else
                    data = data..syl:sub(1, syl:find('%(')-1)..'<v>\\goptforcedeol</v>'..syl:sub(syl:find('%('),-1)..'\n'
                end
            elseif eow and syllables[i+1] then
                data = data..syl..' '
            else
                data = data..syl
            end
        end
    end
    io.savedata(gabc_file, data)
    if debug then
        io.savedata(string.format(gabc_file..'.it%02d', to_line), data)
    end
    if not final then
      local res = dofile(".optimize_gabc.tmp")
      return res
    else
      return
    end
end

-- when we are in the forced case, we need to write a gabc file without the
-- forced end of lines first, this function does it. 
function simple_write_first(gabc_file, syllables, forced)
    local data = syllables[0].."\n%%\n"
    for _, syl in ipairs(syllables) do
        local eow, forced_eol
        forced_eol, eow, syl = syl[3], syl[2], syl[1]
        if forced_eol and not forced then
            data = data..syl:sub(1, syl:find('%(')-1)..'<v>\\goptforcedeol</v>'..syl:sub(syl:find('%('),-1)..'\n'
        elseif eow then
            data = data..syl..' '
        else
            data = data..syl
        end
    end
    io.savedata(gabc_file, data)
end

function old_simple_optimize(gabc_file, tex_file, syllables, res, forced)
    local lines = res.lines
    local newlines = lines
    local oldlines
    for i = 1, #lines, 1 do
        if i == #lines then
            one_iteration(gabc_file, tex_file, syllables, newlines, i, forced, true)
            --simple_compile(gabc_file, tex_file, true, i)
        else
            one_iteration(gabc_file, tex_file, syllables, newlines, i, forced, false)
            if debug then
                --simple_compile(gabc_file, tex_file, true, i)
                os.execute(string.format("cp %s.pdf %s.it%02d.pdf", file.nameonly(tex_file), file.nameonly(tex_file), i))
            else
                simple_compile(gabc_file, tex_file, false, i)
            end
            newlines = dofile(".optimize_gabc.tmp")
            newlines = newlines.lines
            if debug then
                os.execute(string.format("cp .optimize_gabc.tmp .optimize_gabc.it%02d.tmp", i))
            end
            if #newlines > #lines then
                texio.write_nl("error: new score has more lines that the old one...")
            end
        end
    end
end

-- returns 0 if everything is ok, or the first line where there is something wrong
function results_wrong(res)
    for i, pos in ipairs(res.endpos) do
        if pos > res.maxpos + res.tolerance then
            return i
        end
    end
    return 0
end

function simple_optimize(gabc_file, tex_file, syllables, res, forced)
    local all_ok = false
    local to_try_lines = res.lines
    local line = 1
    -- we need to do one iteration first, in order to know which line is the first line
    local obtained_res = nil --one_iteration(gabc_file, syllables, to_try_lines, line, forced, false)
    local nblines = #(res.lines)
    while line <= nblines do
        -- we check if the line is forced or not:
        if forced and syllables[res.lines[line]][3] == true then -- TODO: check this
            line = line + 1
        else
            -- line is not forced
            -- first we try to make the linebreak as it is now:
            obtained_res = one_iteration(gabc_file, tex_file, syllables, to_try_lines, line, forced, false)
            if results_wrong(obtained_res) ~= line and #(obtained_res.lines) <= nblines then
               -- everything's fine, we keep it as it is
               texio.write_nl("line "..line.." ok")
               line = line + 1
            else
               texio.write_nl("line "..line.." not ok")
                -- we do the line break one syllable before, only if there is at least one 
               local nbs = to_try_lines[line]
               if nbs > 1 then
                 to_try_lines[line] = nbs -1
                 obtained_res = one_iteration(gabc_file, tex_file, syllables, to_try_lines, line, forced, false)
                 if results_wrong(obtained_res) == line or #(obtained_res.lines) > nblines  then
                    texio.write_nl("error: can't find a good way to break lines, there will be some mistakes in the score, stopping now.")
                    return false
                 else
                    texio.write_nl("line "..line.." corrected")
                 end
               else
                 texio.write_nl("error: can't find a good way to break lines, there will be some mistakes in the score, stopping now.")
                   return false
               end
               line = line + 1
            end
            to_try_lines = obtained_res.lines
        end
    end
    return to_try_lines
end

function agressive_optimize(gabc_file, tex_file, syllables, res, forced)
    local to_try_lines = res.lines
    local line = 1
    -- we need to do one iteration first, in order to know which line is the first line
    local obtained_res = nil --one_iteration(gabc_file, syllables, to_try_lines, line, forced, false)
    local nblines = #(res.lines)
    while line <= nblines do
        -- we check if the line is forced or not:
        if forced and syllables[res.lines[line]][3] == true then -- TODO: check this
            line = line + 1
        else
            -- line is not forced
            -- first we try to make the linebreak one syllable before as it is now:
            to_try_lines[line] = to_try_lines[line] + 1
            obtained_res = one_iteration(gabc_file, tex_file, syllables, to_try_lines, line, forced, false)
            if results_wrong(obtained_res) ~= line and #(obtained_res.lines) <= nblines then
               -- everything's fine, we keep it as it is
               texio.write_nl("line "..line.." optimized")
               line = line + 1
            else
               texio.write_nl("can't optimize line "..line)
               to_try_lines[line] = to_try_lines[line] - 1
               obtained_res = one_iteration(gabc_file, tex_file, syllables, to_try_lines, line, forced, false)
               if results_wrong(obtained_res) ~= line and #(obtained_res.lines) <= nblines then
                 texio.write_nl("line "..line.." ok")
                 line = line + 1
               else
                 texio.write_nl("line "..line.." not ok, trying to correct it...")
                -- we do the line break one syllable before, only if there is at least one 
                 if to_try_lines[line] > 1 then
                   to_try_lines[line] = to_try_lines[line] -1
                   obtained_res = one_iteration(gabc_file, tex_file, syllables, to_try_lines, line, forced, false)
                   if results_wrong(obtained_res) == line or #(obtained_res.lines) > nblines  then
                      texio.write_nl("error: can't find a good way to break lines, there will be some mistakes in the score, stopping now.")
                      return false
                   else
                      texio.write_nl("line "..line.." corrected")
                   end
                 else
                   texio.write_nl("error: can't find a good way to break lines, there will be some mistakes in the score, stopping now.")
                   return false
                 end
                 line = line + 1
              end
            end
            to_try_lines = obtained_res.lines
        end
    end
    return to_try_lines
end

function main()
    os.execute(string.format("rm -f %s.opt*", gabc_file))
    local syllables = read_gabc_file(gabc_file, forced)
    simple_write_first(gabc_file..'.opt', syllables, forced)
    local gabc_file = gabc_file..".opt"
    local gabc_tex_file = string.sub(gabc_file, 1, -5)..'.tex'
    --texio.write_nl(table.serialize(syllables))
    file_manipulation(gabc_file, gabc_tex_file)
    texio.write("first pass:")
    simple_compile(gabc_file, tex_file)
    local res = dofile(".optimize_gabc.tmp")
    if debug then
        os.execute("cp .optimize_gabc.tmp .optimize_gabc.base.tmp")
    end
    if not res or not next(res) then error("unknown error") end
    -- now we have the syllables and how they are on the score without doing anything
    texio.write_nl("starting optimization:")
    local final_lines
    if agressive then
      final_lines = agressive_optimize(gabc_file, tex_file, syllables, res, forced)
    else
      final_lines = simple_optimize(gabc_file, tex_file, syllables, res, forced)
    end
    if final_lines then
      one_iteration(gabc_file, tex_file, syllables, final_lines, #final_lines, forced, true)
    else
      return
    end
    log("producing " .. file.nameonly(tex_file) .. ".pdf")
    os.execute(string.format("lualatex -interaction batchmode %s >/dev/null", tex_file))
    log("optimized gabc file: "..gabc_file..'\n')
end

main()
