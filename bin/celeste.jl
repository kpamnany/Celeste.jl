#!/usr/bin/env julia

using DocOpt
import Celeste
import Celeste.SDSSIO.RunCamcolField

const DOC =
"""Run Celeste.

Usage:
  celeste.jl [options] stage-box <ramin> <ramax> <decmin> <decmax>
  celeste.jl [options] infer-box <ramin> <ramax> <decmin> <decmax> <outdir>
  celeste.jl [options] infer-field <run> <camcol> <field> <outdir>
  celeste.jl [options] infer-object <run> <camcol> <field> <objid> <outdir>
  celeste.jl [options] score-field <run> <camcol> <field> <resultdir> <truthfile>
  celeste.jl [options] score-object <run> <camcol> <field> <objid> <resultdir> <truthfile>
  celeste.jl -h | --help
  celeste.jl --version

Options:
  -h, --help         Show this screen.
  --version          Show the version.
  --logging=<level>  Level for the Lumberjack package (debug, info, warn, error). [default: info]

The `stage-box` subcommand copies and/or uncompresses all files covering the
given RA/Dec range from /project to user's SCRATCH directory.

The `infer-box` subcommand runs Celeste on all sources in the given
RA/Dec range, using all available images. It depends on `stage-box` having
already been run on the same patch of sky.

The `infer-field` subcommand runs Celeste on all sources in the given
field, using only that field.

The `score-field` subcommand is not yet implemented for the new API.
"""

function main()
    args = docopt(DOC, version=v"0.1.0", options_first=true)
#   TODO: re-enable selective logging by level
#    set_logging_level(args["--logging"])
    stagedir = joinpath(ENV["SCRATCH"], "celeste")
    if args["stage-box"] || args["infer-box"]
        ramin = parse(Float64, args["<ramin>"])
        ramax = parse(Float64, args["<ramax>"])
        decmin = parse(Float64, args["<decmin>"])
        decmax = parse(Float64, args["<decmax>"])
        box = Celeste.BoundingBox(ramin, ramax, decmin, decmax)
        if args["stage-box"]
            sdssdir = ENV["SDSS_ROOT_DIR"]
            Celeste.stage_box(box, sdssdir, stagedir)
        elseif args["infer-box"]
            outdir = args["<outdir>"]
            Celeste.infer_box(box, stagedir, outdir)
        end
    else
        run = parse(Int, args["<run>"])
        camcol = parse(Int, args["<camcol>"])
        field = parse(Int, args["<field>"])
        rcf = RunCamcolField(run, camcol, field)
        if args["infer-field"]
            sdssdir = ENV["SDSS_ROOT_DIR"]
            Celeste.stage_field(rcf, sdssdir, stagedir)
            outdir = args["<outdir>"]
            Celeste.infer_field(rcf, stagedir, outdir)
        elseif args["infer-object"]
            outdir = args["<outdir>"]
            objid = args["<objid>"]
            Celeste.infer_field(rcf, stagedir, outdir; objid=objid)
        elseif args["score-field"]
            resultdir = args["<resultdir>"]
            truthfile = args["<truthfile>"]
            Celeste.score_field_disk(rcf, resultdir, truthfile)
        elseif args["score-object"]
            objid = args["<objid>"]
            resultdir = args["<resultdir>"]
            truthfile = args["<truthfile>"]
            Celeste.score_object_disk(rcf, objid, resultdir, truthfile)
        end
    end
end


main()
