"""
Module for working with [Keyhole Markup Language (KML) file format](https://en.wikipedia.org/wiki/Keyhole_Markup_Language).

Be aware that this module only support a part of gx:Track extension only.

Have a look at https://developers.google.com/kml/documentation for more information.
"""
module KMLTracks

using Dates
using TimeZones
using EzXML

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
    xdoc = readxml(fname)
    return _parse_kml(xdoc)
end

"""
    parse_kml_string(s) -> KMLDocument


Parse GPX data from String `s`.
"""
function parse_kml_string(s)
    xdoc = parsexml(s)
    return _parse_kml(xdoc)
end

"""
    _parse_kml(xdoc::EzXML.Document) -> KMLDocument

Parse `EzXML.Document` and return a `KMLDocument`.
"""
function _parse_kml(xdoc::EzXML.Document)
    kmls = root(xdoc)

    kmldoc = KMLDocument()

    ns = namespaces(xdoc.root)
    d_ns = Dict(ns)
    @assert(d_ns == KML_NS, "Namespace error $d_ns different from $KML_NS")

    ns[1] = "x" => ns[1][2]  # change default namespace key

    a_when = findall("//x:Placemark/gx:Track/x:when/text()", xdoc.root, ns)
    a_when = nodecontent.(a_when)
    a_when = ZonedDateTime.(a_when, dateformat"yyyy-mm-ddTHH:MM:SSzzz")

    a_coords = findall("//x:Placemark/gx:Track/gx:coord/text()", xdoc.root, ns)
    a_coords = nodecontent.(a_coords)

    @assert(length(a_coords) == length(a_when), "a_coords/a_when length mismatch")

    for (i, dt) in enumerate(a_when)
        coord = a_coords[i]
        coord = replace(coord, "," => ".")  # fix issue with some badly formatted kml files
        long, lat, alt = split(coord, " ")
        long, lat, alt = parse.(Float64, (long, lat, alt))
        p = KMLTrackPoint(dt, long, lat, alt)
        push!(kmldoc.placemark.track.points, p)
    end

    return kmldoc
end

end # module
