GIT_ROOT := $(shell git rev-parse --show-toplevel)
include $(GIT_ROOT)/share.mk

t2=$(word 2,$^)

TGTS= fgh.sobj pubkey.sobj ntru_lattice.sobj small_vec.sobj u_vec.sobj

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
NN=79
qq=64
pp=3
df=15
dfp=11
dfm=0
dg=12
dgp=12
dgm=0

params.sobj:
	sage -c "$(PARAMS_PY)"

define PARAMS_PY
params = { 'N' : $(NN), 'q' : $(qq), 'p' : $(pp), 'df' : $(df), 'dfp' : $(dfp), \
	'dfm' : $(dfm), 'dg' : $(dg), 'dgp' : $(dgp), 'dgm' : $(dgm)}; \
save(params,'$@')
endef

# original small challenge problem
#n = 167, q = 128, p = 3, d_f = 61, d_g = 20

fgh.sobj:
	sage -c "$(NTRU_KEYGEN)"

# R.<x> = PolynomialRing(ZZ) can do this in one go
define NTRU_KEYGEN
ZZx = PolynomialRing(ZZ, 'x'); \
x = ZZx.gen(); \
xnmo = x^$(NN) - 1; \
CYCx = ZZx.quotient(xnmo); \
CYCqx = PolynomialRing(Zmod($(qq)), 'x').quotient(xnmo); \
f_poly = ZZx(sample([1]*$(dfp) + [-1]*$(dfm) + [0]*($(NN)-$(dfp)-$(dfm)), $(NN))); \
g_poly = ZZx(sample([1]*$(dgp) + [-1]*$(dgm) + [0]*($(NN)-$(dgp)-$(dgm)), $(NN))); \
d, u, v = xgcd(f_poly, xnmo); \
'''this is slightly too strong e.g. 1/(x+1) = 1+x+x^2+...x^{N-1} is invertible mod X^N-1, and any constant multiples '''; \
assert d.degree() == 0 and gcd(Integer(d[0]), $(qq)) == 1, 'f not invertible mod q: '+str(d); \
f,g = CYCqx(f_poly), CYCqx(g_poly); \
finv = CYCqx(u)/CYCqx(d); \
h = $(pp)*g*finv; \
save([f,g,h], '$@');
endef

check_key: fgh.sobj
	sage -c "f,g,h = load('$<'); print(f*h-$(pp)*g)"

pubkey.sobj: fgh.sobj
	sage -c "h=load('$<')[2]; save(vector(h.lift().list() + [0]*($(NN) - len(h.lift().list()))), '$@')"

small_vec.sobj: fgh.sobj ntru_lattice.sobj
	sage -c "$(SMALL_VEC_PY)"

# i dont think it matters if things are mod q or not
define SMALL_VEC_PY
f=load('$<')[0]; \
f_modq = vector(f.lift().list() + [0]*($(NN) - len(f.lift().list()))); \
L=load('$(d2)'); \
u1=vector(zero_vector($(NN)).list()+f_modq.list()); \
sm_modq = vector(Zmod($(qq)),u1*L); \
sm_centered = vector([x.lift_centered() for x in sm_modq]); \
sm_zz = vector(ZZ,sm_centered); \
save(vector(ZZ,sm_centered), '$@')
endef

u_vec.sobj: small_vec.sobj ntru_lattice.sobj
	sage -c "$(U_VEC_PY)"

define U_VEC_PY
sm=load('$<'); \
L=load('$(d2)'); \
u=sm*(L.inverse()); \
save(u.change_ring(ZZ), '$@')
endef

check_mat: u_vec.sobj ntru_lattice.sobj small_vec.sobj
	sage -c "u=load('$<'); L=load('$(d2)'); sm=load('$(d3)'); print(u*L-sm)"

#assert gcd == 1, 'h not invertible over Z, gcd=' + str(gcd); \

# q 0
# H I

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

