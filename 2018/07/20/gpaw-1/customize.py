import numpy as np

compiler = 'mpiicc -fPIC'
mpicompiler = 'mpiicc -fPIC'  # use None if you don't want to build a gpaw-python
mpilinker = mpicompiler

#FFTW3_HOME = '/gpfs/share/home/1501210186/program/fftw-3.3.4-intel-2017.1'
#MKLROOT    = '/gpfs/share/software/intel/compilers_and_libraries_2017.1.132/linux/mkl'
#LIBXC_HOME = '/gpfs/share/home/1501210186/program/libxc-4.2.3-intel-2017.1'

FFTW3_HOME = '/path/to/FFTW3'
MKLROOT    = '/path/to/mkl'
LIBXC_HOME = '/path/to/libxc'

scalapack = True
libraries = [ 
              'mkl_scalapack_lp64', 
              'mkl_intel_lp64' ,'mkl_sequential' ,'mkl_core',
              'mkl_blacs_intelmpi_lp64',
              'pthread','m','dl', 
              'xc'
            ]
library_dirs = [ MKLROOT+'/lib/intel64/' , FFTW3_HOME+'/lib/']
include_dirs += [np.get_include(), MKLROOT+'/include/', FFTW3_HOME+'/include/']
mpi_libraries = []

if scalapack:
    define_macros += [('GPAW_NO_UNDERSCORE_CBLACS', '1')]
    define_macros += [('GPAW_NO_UNDERSCORE_CSCALAPACK', '1')]

# - dynamic linking (requires rpath or setting LD_LIBRARY_PATH at runtime):
if True:
    include_dirs += [LIBXC_HOME+'/include']
    library_dirs += [LIBXC_HOME+'/lib']
    # You can use rpath to avoid changing LD_LIBRARY_PATH:
    extra_link_args += ['-Wl,-rpath=%s/lib' % LIBXC_HOME]
    if 'xc' not in libraries:
        libraries.append('xc')

