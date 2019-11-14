module KMLTracks

using Dates
using LightXML
using TimeZones

export read_kml_file, parse_kml_string

const dt0 = ZonedDateTime(0, tz"UTC")


struct KMLTrackPoint
    time::ZonedDateTime
    longitude::Float64
    latitude::Float64
    altitude::Float64
end

struct KMLTrack
    points::Vector{KMLTrackPoint}
    KMLTrack() = new(Vector{KMLTrackPoint}[])
end

struct KMLPlacemark
    track::KMLTrack
    KMLPlacemark() = new(KMLTrack())
end

struct KMLDocument
    placemark::KMLPlacemark
    KMLDocument() = new(KMLPlacemark())
end

function read_kml_file(fname)
    xdoc = parse_file(fname)
    return _parse_kml(xdoc)
end

function parse_kml_string(s)
    xdoc = parse_string(s)
    return _parse_kml(xdoc)
end

function _parse_kml(xdoc::XMLDocument)
    kmls = root(xdoc)

    kmldoc = KMLDocument()

    for kml in child_nodes(kmls)
        if name(kml) == "Placemark"
            for track in child_nodes(kml)
                if name(track) == "Track"
                    dt = dt0
                    for d in child_nodes(track)
                        if name(d) == "when" && dt == dt0
                            s = content(d)
                            fmt = dateformat"yyyy-mm-ddTHH:MM:SSzzz"
                            s = replace(s, "Z" => "+00:00")  # bug https://github.com/JuliaTime/TimeZones.jl/pull/227
                            dt = parse(ZonedDateTime, s, fmt)
                        elseif name(d) == "coord" && dt != dt0
                            s = content(d)
                            s = replace(s, "," => ".")  # fix bug with decimal separator
                            long, lat, alt = split(s, " ")
                            long, lat, alt = parse.(Float64, (long, lat, alt))
                            p = KMLTrackPoint(dt, long, lat, alt)
                            push!(kmldoc.placemark.track.points, p)
                            dt = dt0
                        end
                    end
                end
            end
        end
    end

    free(xdoc)

    return kmldoc
end

end # module
