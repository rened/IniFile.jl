module IniFile
using Base

import Base.get,
       Base.haskey,
       Base.read,
       Base.write,
       Base.show

export Inifile,
       defaults,
       get,
       set,
       get_bool,
       get_int,
       get_float,
       has_section,
       read,
       write,
       section,
       sections,
       show

typealias INIVAL Union(String,Number,Bool,Nothing)
typealias HTSS Dict{String,INIVAL}

type Inifile
    sections::Dict{String,HTSS}
    defaults::HTSS
end

Inifile() = Inifile(Dict{String,HTSS}(), HTSS())

defaults(inifile::Inifile) = inifile.defaults

sections(inifile::Inifile) = inifile.sections

function read(inifile::Inifile, stream::IO)
    current_section = inifile.defaults
    for line in EachLine(stream)
        s = strip(line)
        # comments start with # or ;
        if length(s) < 3 || s[1] == '#' || s[1] == ';'
            continue
        elseif s[1] == '[' && s[end] == ']'
            section = s[2:end-1]
            if !haskey(inifile.sections, section)
                inifile.sections[section] = HTSS()
            end
            current_section = inifile.sections[section]
        else
            i = search(s, '=')
            j = search(s, ':')
            if i == 0 && j == 0
                # TODO: allow multiline values
                println("skipping malformed line: $s")
            else
                idx = min(i, j)
                if idx == 0
                    idx = max(i, j)
                end
                key = rstrip(s[1:idx-1])
                val = lstrip(s[idx+1:end])
                current_section[key] = val
            end
        end
    end
    inifile
end

function read(inifile::Inifile, filename::String)
    open(filename) do f
        read(inifile, f)
    end
    inifile
end

show(io::IO, inifile::Inifile) = write(io, inifile)
function write(io::IO, inifile::Inifile)
    for (key, value) in defaults(inifile)
        println(io, "$key=$value")
    end
    for (name, htss) in sections(inifile)
        println(io, "[$name]")
        for (key, value) in htss
            println(io, "$key=$value")
        end
    end
end

get(inifile::Inifile, section::String, key::String) = get(inifile, section, key, :notfound)

function get(inifile::Inifile, section::String, key::String, notfound)
    if haskey(inifile.sections, section) && haskey(inifile.sections[section], key)
        return inifile.sections[section][key]
    elseif haskey(inifile.defaults, key)
        return inifile.defaults[key]
    end
    notfound
end

# This get function uses the defaults section
get(inifile::Inifile, key::String) = get(inifile, key, :notfound)

function get(inifile::Inifile,  key::String, notfound)
    if haskey(inifile.defaults, key)
        return inifile.defaults[key]
    end
    notfound
end

function set(inifile::Inifile, section::String, key::String, val::INIVAL)
    if !haskey(inifile.sections, section)
        (val == nothing) && return val
        inifile.sections[section] = HTSS()
    end
   
    sec = inifile.sections[section] 
    if val == nothing
        if haskey(sec, key)
            delete!(sec, key)
        end
        return val
    end
    sec[key] = val
    val
end

# This set function uses the defaults section
function set(inifile::Inifile, key::String, val::INIVAL)
    sec = inifile.defaults
    if val == nothing
        if haskey(sec, key)
            delete!(sec, key)
        end
        return val
    end
    sec[key] = val
    val
end

get_bool(inifile::Inifile, section::String, key::String) = 
    lowercase(get(inifile, section, key)) == "true"

get_int(inifile::Inifile, section::String, key::String) = 
    parseint(get(inifile, section, key))

get_float(inifile::Inifile, section::String, key::String) = 
    parsefloat(get(inifile, section, key))

haskey(inifile::Inifile, section::String, key::String) =
    haskey(inifile.sections, section) && haskey(inifile.sections[section], key)

has_section(inifile::Inifile, section::String) = haskey(inifile.sections, section)

section(inifile::Inifile, section::String) = inifile.sections[section]

end # module
