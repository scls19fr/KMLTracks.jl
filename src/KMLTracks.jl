"""
Module for working with [Keyhole Markup Language (KML) file format](https://en.wikipedia.org/wiki/Keyhole_Markup_Language).

Be aware that this module only support a part of gx:Track extension only.

Have a look at https://developers.google.com/kml/documentation for more information.
"""
module KMLTracks

using Dates
using LightXML
using TimeZones

export read_kml_file, parse_kml_string


"""
Constant defining KML Format version
"""
const KML_VERSION = "2.2"

"""
Constant dictionary defining default namespaces
"""
const KML_NS = Dict(
    "" => "http://www.opengis.net/kml/2.2",
    "gx" => "http://www.google.com/kml/ext/2.2"
)

const dt0 = ZonedDateTime(0, tz"UTC")

"""
    KMLTrackPoint(time::ZonedDateTime, longitude::Float64, latitude::Float64, altitude::Float64)

Point in a KML Track.
"""
struct KMLTrackPoint
    time::ZonedDateTime
    longitude::Float64
    latitude::Float64
    altitude::Float64
end


"""
    KMLTrack()

A KMLTrack is a collection of track points.

`gx:Track` element is an extension of the OGC KML 2.2 standard and is supported in Google Earth 5.2 and later.
"""
struct KMLTrack
    points::Vector{KMLTrackPoint}
    KMLTrack() = new(Vector{KMLTrackPoint}[])
end

"""
    KMLPlacemark()

Placemark is a special kind of Feature. It contains all of the elements that belong to Feature, and it adds some elements that are specific to the Placemark element.

See `Placemark` tag.
"""
struct KMLPlacemark
    track::KMLTrack
    KMLPlacemark() = new(KMLTrack())
end


"""
    KMLDocument()

A KML Document is a container for placemark.

Be aware that `KMLDocument` is related to `kml` tag not to `Document` tag.
"""
struct KMLDocument
    placemark::KMLPlacemark
    KMLDocument() = new(KMLPlacemark())
end

"""
    read_kml_file(fname) -> KMLDocument

Read KML file from filename `fname`.
"""
function read_kml_file(fname)
    xdoc = parse_file(fname)
    return _parse_kml(xdoc)
end

"""
    parse_kml_string(s) -> KMLDocument


Parse GPX data from String `s`.
"""
function parse_kml_string(s)
    xdoc = parse_string(s)
    return _parse_kml(xdoc)
end

"""
    _parse_kml(xdoc::XMLDocument) -> KMLDocument

Parse `XMLDocument` and return a `KMLDocument`.
"""
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
