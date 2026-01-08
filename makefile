
t2=$(word 2,$^)

TGTS: ex.txt ex.pdf fgh.sobj pubkey.sobj ntru_lattice.sobj

all: $(TGTS)

%.txt: %.py
	python3 $< > $@

# templates could be per-pdf or for many pdfs
# the pdf can be opened with
# xdg-open
# which on my system is
# xdg-mime query default application/pdf
# org.gnome.Evince.desktop

# xdg = cross desktop group, aka freedesktop.org

%.pdf: %.dat template.gp
	gnuplot -e "out_file='$@'; in_file='$<'" $(t2)

# vsmall
# n = 79, q = 64, p = 3, d_f = 12, d_g = 12

# small
NN=101
qq=128
pp=3
df=15
dfp=$(df)
dfm=$(df)
dg=15
dgp=$(dg)
dgm=$(dg)

# original small challenge problem
#n = 167, q = 128, p = 3, d_f = 61, d_g = 20

fgh.sobj:
	sage -c "$(NTRU_KEYGEN)"

define NTRU_KEYGEN
R.<x> = PolynomialRing(ZZ); \
Rq = R.quotient(x^$(NN) - 1); \
f_poly = R(sample([1]*$(dfp) + [-1]*$(dfm) + [0]*($(NN)-$(dfp)-$(dfm)), $(NN))); \
g_poly = R(sample([1]*$(dgp) + [-1]*$(dgm) + [0]*($(NN)-$(dgp)-$(dgm)), $(NN))); \
f = Rq(f_poly); \
g = Rq(g_poly); \
from sage.rings.polynomial.polynomial_quotient_ring import PolynomialQuotientRing_generic; \
gcd, u, v = xgcd(f_poly, x^$(NN) - 1); \
f_inv_ZZ = Rq(u); \
Rq_mod = PolynomialRing(Zmod($(qq)), 'x').quotient(x^$(NN) - 1); \
f_inv_q = Rq_mod(f_inv_ZZ.lift()); \
g_q = Rq_mod(g.lift()); \
h = $(pp) * g_q * f_inv_q; \
save([f,g,h], '$@');
endef

pubkey.sobj: fgh.sobj
	sage -c "h=load('$<')[2]; save(vector(h.lift().list() + [0]*($(NN) - len(h.lift().list()))), '$@')"

ntru_lattice.sobj: pubkey.sobj
	sage -c "$(NTRU_LATTICE_PY)"

define NTRU_LATTICE_PY
h_vec = load('$<'); \
H = matrix.circulant([ZZ(x) for x in h_vec]); \
I_n = identity_matrix($(NN)); \
Z_n = zero_matrix($(NN)); \
L = block_matrix([[$(qq)*I_n, Z_n], [H, I_n]]); \
save(L, '$@')
endef

# 1s
%.lll_reduced.sobj: %.sobj
	sage -c "L=load('$<'); L_reduced = L.LLL(); save(L_reduced, '$@')"

# 10s
%.bkz10_reduced.sobj: %.sobj
	sage -c "L = load('$<'); L_reduced = L.BKZ(block_size=10); save(L_reduced, '$@')"

# 1 min
%.bkz20_reduced.sobj: %.sobj
	sage -c "L = load('$<'); L_reduced = L.BKZ(block_size=20); save(L_reduced, '$@')"

# this errored out after 10 hours
#  what():  infinite loop in babai
%.bkz30_reduced.sobj: %.sobj
	sage -c "L = load('$<'); L_reduced = L.BKZ(block_size=30); save(L_reduced, '$@')"

#print(h_vec)

# Define the polynomial ring
R.<x> = PolynomialRing(ZZ)
n = 251  # NTRU parameter
q = 128  # public key modulus

# Quotient ring for NTRU operations
Rq = R.quotient(x^n - 1)


clean:
	rm -f $(TGTS)

