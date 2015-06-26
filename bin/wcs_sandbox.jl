using Celeste
using CelesteTypes

using DataFrames
using SampleData

import SDSS
import PSF
import FITSIO
import PyPlot

# Some examples of the SDSS fits functions.
field_dir = joinpath(dat_dir, "sample_field")
run_num = "003900"
camcol_num = "6"
field_num = "0269"

const band_letters = ['u', 'g', 'r', 'i', 'z']

b = 1
b_letter = band_letters[b]

#############
# Load and subsample the catalog

original_blob = SDSS.load_sdss_blob(field_dir, run_num, camcol_num, field_num);
original_cat_df = SDSS.load_catalog_df(field_dir, run_num, camcol_num, field_num);


sub_rows_x = 40:60
sub_rows_y = 120:140
x_min = minimum(collect(sub_rows_x))
y_min = minimum(collect(sub_rows_y))
x_max = maximum(collect(sub_rows_x))
y_max = maximum(collect(sub_rows_y))
blob = deepcopy(original_blob);
cat_df = deepcopy(original_cat_df);
cat_loc = convert(Array{Float64}, cat_df[[:ra, :dec]]);
entry_in_range = Bool[true for i=1:size(cat_loc, 1) ];
for b=1:5
	blob[b].pixels = blob[b].pixels[sub_rows, sub_rows]
	blob[b].H = size(blob[b].pixels, 1)
	blob[b].W = size(blob[b].pixels, 2)
	wcs_range = Util.world_to_pixel(blob[b].wcs, cat_loc)
	entry_in_range = entry_in_range &
		(x_min .<= wcs_range[:, 1] .<= x_max) &
		(y_min .<= wcs_range[:, 2] .<= y_max)
end
cat_df = cat_df[entry_in_range, :]
cat_entries = SDSS.convert_catalog_to_celeste(cat_df, blob);
cat_loc = convert(Array{Float64}, cat_df[[:ra, :dec]]);

pix_loc = Util.world_to_pixel(blob[b].wcs, cat_loc)
Util.pixel_to_world(blob[b].wcs, pix_loc)

psf_point_x = 80.
psf_point_y = 100.

raw_psf = Array(Array{Float64}, 5)
for b=1:5
	rrows, rnrow, rncol, cmat = SDSS.load_psf_data(field_dir, run_num, camcol_num, field_num, b);
	raw_psf[b] = PSF.get_psf_at_point(psf_point_x, psf_point_y, rrows, rnrow, rncol, cmat);
end


if false
	# This shows that imshow is screwed up and you have to offset the scatterplot by one.
	example_mat = zeros(11, 11)
	example_mat[6, 6] = 1.0
	PyPlot.figure()
	im = PyPlot.imshow(example_mat, interpolation = "nearest")
	PyPlot.scatter(6, 6, marker="o", c="r", s=25)
	PyPlot.scatter(5, 5, marker="o", c="k", s=25)

	b = 4
	PyPlot.figure()
	PyPlot.imshow(raw_psf[4], interpolation = "nearest")
	PyPlot.scatter(26 - 1, 26 - 1, marker="o", c="w", s=25)
	PyPlot.title("Band $b psf at ($psf_point_x, $psf_point_y)")
end





PyPlot.close()
for b=1:5
#for b=4
	# Plotting the transpose matches the images in the SDSS image browser
	# http://skyserver.sdss.org/dr7/en/tools/getimg/fields.asp

	# Here's how to look up an object:
	# http://skyserver.sdss.org/dr12/en/tools/explore/summary.aspx?id=1237662226208063597

	objid = "1237662226208063597"
	pixel_graph = blob[b].pixels
	clip = 8000
	pixel_graph[pixel_graph .>= clip] = clip
	PyPlot.figure()
	PyPlot.plt.subplot(1, 2, 1)
	PyPlot.imshow(pixel_graph', cmap=PyPlot.ColorMap("gray"), interpolation = "nearest")
	PyPlot.title("Band $b image")

	PyPlot.plt.subplot(1, 2, 2)
	PyPlot.imshow(pixel_graph', cmap=PyPlot.ColorMap("gray"), interpolation = "nearest")
	cat_px = Util.world_to_pixel(blob[b].wcs, cat_loc) - min_row + 1
	PyPlot.scatter(cat_px[:, 1] - x_min - 1, cat_px[:, 2] - y_min - 1, marker="o", c="r", s=25)

	obj_row = cat_df[:objid] .== objid 
	PyPlot.scatter(cat_px[obj_row, 1] - x_min - 1, cat_px[obj_row, 2] - y_min - 1,
		           marker="x", c="w", s=25)

	PyPlot.title("Band $b with catalog")
end




# Plot neighboring points.
function make_rot_mat(theta::Float64)
    [ cos(theta) -sin(theta); sin(theta) cos(theta) ]
end

offset = [0, 0]
rot = make_rot_mat(pi / 3)
poly = Float64[1 1; -1 1; -1 -1; 1 -1]
poly = broadcast(+, poly, offset') * rot'
radius = 0.3

poly_graph = vcat(poly, poly[1,:])

PyPlot.plot(poly_graph[:,1],  poly_graph[:,2], "k")

in_poly = [ (x, y, Util.point_within_radius_of_polygon(Float64[x, y], radius, poly))
            for x in -3:0.1:6, y in -3:0.1:6 ]
for p in in_poly
	if p[3]
		PyPlot.plot(p[1], p[2], "r+")
	end
end




