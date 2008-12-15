local hlist = node.id('hlist')
tempnode=node.new(node.id('glyph'), 0)
tempnode.font=65 --% TODO : don't know why 65...
tempnode.char=tex.defaulthyphenchar
dashnode=node.hpack(tempnode)
dashnode.shift=393216 --% TODO : a less static value

function addhyphen(h, groupcode, glyphes)
    local lastseennode=nil
    local attributeid=1
    local potentialdashvalue=3
    local nopotentialdashvalue=2
    local adddash=false
    --% we explore the lines
    for a in node.traverse_id(hlist, h) do
        for b in node.traverse_id(hlist, a.list) do
            if adddash == false then
                if node.has_attribute(b, attributeid, potentialdashvalue) then
                    adddash=true
                    lastseennode=b
                    attr = b.attr.next
                    --texio.write_nl('ATTR number = ' .. attr.number .. ' value = ' .. attr.value)
                end
            else
                if node.has_attribute(b, attributeid, nopotentialdashvalue) then
                    adddash=false
                    attr = b.attr.next
                    --texio.write_nl('ATTR number = ' .. attr.number .. ' value = ' .. attr.value)
                end 
            end
        end
        if adddash==true then
            local temp= node.copy(dashnode)
            --%TODO: remove the last glue in b first, and insert a glue of ancient glue - withdof(dashnode) after the dash
            node.insert_after(a.list, b, temp)
            addash=false
        end
    end
    return true
end 

function atScoreBeggining()
    callback.register('post_linebreak_filter', addhyphen)
end
