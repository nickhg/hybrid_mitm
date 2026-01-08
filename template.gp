# this is an example gnuplot template

# the use of variables avoids needing to know the set syntax, e.g.
# gnuplot -e "ofile='my_file.pdf'; x=...' ex.gp
# vs.
# gnuplot -e "set output 'my_file.pdf'; set ..."  ex.gp

# variables:
# out_file
# in_file

line_width=2
point_type=7
point_size=1.5

set terminal pdf
set output out_file
set xlabel 'Basis Vector Index'
set ylabel 'Norm'
set title 'Norms of LLL-Reduced Basis Vectors'
set grid


plot in_file with linespoints \
  linewidth line_width \
  pointtype point_type \
  pointsize point_size \
  title 'LLL Reduced'

