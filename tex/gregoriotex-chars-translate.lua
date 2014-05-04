#!/usr/bin/env texlua

infile = io.open("gregoriotex-chars.tex.in");
outfile = io.open("gregoriotex-chars.tex", 'w');

charrangestart = 161

for line in infile:lines() do
  newline = line
  if (string.sub(line,1,1)~='%') then
  newline = string.gsub(line, '([0-9]+)', function(match)
        if (match ~= '0' and match ~= '1') then
          return match+charrangestart
        end
      end)
    end
  outfile:write(newline.."\n")
end

infile:close()
outfile:close()
