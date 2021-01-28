---
title: 解决macOS上编译VASP时遇到的libparser.a未定义符号问题
date: 2018-01-02 12:00:00
updated: 2018-01-02 12:00:00
tags: [VASP, Compilation, macOS, Bugfix]
categories: Software
toc: true
comment: true
---

{% alert success %}
介绍了笔者在 macOS High Sierra 上编译 VASP.5.4.4 时解决 libparser.a 中 undefined symbols 问题.
{% endalert %}
<!-- more -->

## 背景

购买mac后，我希望能在 macOS 运行常用的科学计算程序，方便我做小规模测试，其中之一是 [VASP](https://www.vasp.at/)。系统环境为 macOS High Sierra 10.13，编译环境为

- Intel Parallel Composer XE 2018.0.1
- Intel ifort 和 icc 编译的 MPICH3
- Intel ifort 和 icc 编译的 FFTW3 (MPICH3 并行)
- Intel ifort 和 icc 编译的 ScaLAPACK 和 BLACS (MPICH3 并行)

我的目标是编译5.4.1和VASP.5.4.4两个版本并成功用于Silicon的算例. VASP.5.4.1的编译很容易就通过了并能够正常地跑Silicon的例子, 但VASP.5.4.4始终无法编译通过，主要问题是在用C++编译parser库时无法链接到部分symbol上。

## 问题细节

VASP编译过程用到的`makefile.include`文件如下所示。5.4.4版同5.4.1版include文件的主要区别，除了最后的GPU部分外，还有一个用C++编译`libparser.a`的选项，即`CXX_PARS`。

```makefile
# Precompiler options
CPP_OPTIONS = -DHOST="LinuxIFC" \
              -DMPI -DMPI_BLOCK=8000 \
              -Duse_collective \
              -DscaLAPACK \
              -DCACHE_SIZE=4000 \
              -Davoidalloc \
              -Duse_bse_te \
              -Dtbdyn \
              -Duse_shmem
CPP        = fpp -f_com=no -free -w0  $*$(FUFFIX) $*$(SUFFIX) $(CPP_OPTIONS)
FC         = mpifort
FCL        = mpifort #-mkl=sequential -lstdc++
FREE       = -free -names lowercase
FFLAGS     = -assume byterecl -w
OFLAG      = -O2
OFLAG_IN   = $(OFLAG)
DEBUG      = -O0
MKL_PATH   = $(MKLROOT)/lib/
BLAS       =
LAPACK     = $(MKLROOT)/lib/libmkl_intel_lp64.a $(MKLROOT)/lib/libmkl_sequential.a $(MKLROOT)/lib/libmkl_core.a -lpthread -lm -ldl
BLACS      =
SCALAPACK  = /Users/stevezhang/software/mathlib/scalapack/2.0.2/intel/18.0.1/libscalapack.a

OBJECTS    = fftmpiw.o fftmpi_map.o fft3dlib.o fftw3d.o $(HOME)/lib/libfftw3xf_intel.a

INCS       = -m64 -I$(MKLROOT)/include/fftw -I$(MKLROOT)/include/

LLIBS      = $(SCALAPACK) $(LAPACK)


OBJECTS_O1 += fftw3d.o fftmpi.o fftmpiw.o
OBJECTS_O2 += fft3dlib.o

# For what used to be vasp.5.lib
CPP_LIB    = $(CPP)
FC_LIB     = $(FC)
CC_LIB     = icc
CFLAGS_LIB = -O
FFLAGS_LIB = -O1
FREE_LIB   = $(FREE)

OBJECTS_LIB= linpack_double.o getshmem.o

# For the parser library
CXX_PARS   = icpc

LIBS       += parser
LLIBS      += -Lparser -lparser -lstdc++

# Normally no need to change this
SRCDIR     = ../../src
BINDIR     = ../../bin

### GPU stuff below
```

输入命令

```bash
make std
```

在最后链接产生`vasp`前报错, 提示libparser.a中大量Undefined symbols,

```plaintext
Undefined symbols for architecture x86_64:
...
...
ld: symbol(s) not found for architecture x86_64
make[2]: *** [vasp] Error 1
cp: vasp: No such file or directory
make[1]: *** [all] Error 1
make: *** [std] Error 2
```

`Undefined symbols for architecture x86_64`表示在x86_64架构下符号未被定义, 具体错误信息在[这里](libparser_undefined_sym.error), 总结起来未定义的符号包括

```text
__ZNKSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE7compareEmmPKcm
__ZNKSt3__120__vector_base_commonILb1EE20__throw_length_errorEv
__ZNKSt3__16locale9use_facetERNS0_2idE
__ZNKSt3__18ios_base6getlocEv
__ZNSt11logic_errorC2EPKc
__ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6__initEPKcm
__ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6__initEmc
__ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE6appendEPKcm
__ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEE9push_backEc
__ZNSt3__112basic_stringIcNS_11char_traitsIcEENS_9allocatorIcEEED1Ev
__ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEE3putEc
__ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEE5flushEv
__ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEE6sentryC1ERS3_
__ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEE6sentryD1Ev
__ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEElsEd
__ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEElsEf
__ZNSt3__113basic_ostreamIcNS_11char_traitsIcEEElsEi
__ZNSt3__14coutE
__ZNSt3__15ctypeIcE2idE
__ZNSt3__16localeD1Ev
__ZNSt3__18ios_base33__set_badbit_and_consider_rethrowEv
__ZNSt3__18ios_base5clearEj
```

## 解决过程

首先在`makefile.include`里面的`CXX_PARS`后面加上Homebrew安装的GCC库和`-lstdc++`，即

```text
-L/usr/local/Cellar/gcc/7.2.0/lib/gcc/7 -lstdc++
```

这样子可以正常编译通过。但是跑VASP时会出现错误

```text
 running on    1 total cores
 distrk:  each k-point on    1 cores,    1 groups
 distr:  one band on    1 cores,    1 groups
 using from now: INCAR
 vasp.5.4.4.18Apr17-6-g9f103f2a35 (build Jan 09 2018 16:27:40) complex

 POSCAR found type information on POSCAR  Si
 POSCAR found :  1 types and       2 ions
 scaLAPACK will be used
dyld: lazy symbol binding failed: Symbol not found: __ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1Ev
  Referenced from: /Users/stevezhang/software/sci/vasp/vasp.5.4.4-intel-2018.0.1/common/build/std/vasp
  Expected in: flat namespace

dyld: Symbol not found: __ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1Ev
  Referenced from: /Users/stevezhang/software/sci/vasp/vasp.5.4.4-intel-2018.0.1/common/build/std/vasp
  Expected in: flat namespace

forrtl: error (76): Abort trap signal
Image              PC                Routine            Line        Source
vasp               0000000103C7ABFA  for__signal_handl     Unknown  Unknown
libsystem_platfor  00007FFF6C6DEF5A  _sigtramp             Unknown  Unknown
fish: 'vasp' terminated by signal SIGABRT (Abort)
```

主要错误是`dyld`没有找到symbol。用`nm`命令检查`libstdc++.a`和`libstdc++.dylib`，可以看到`__ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEC1Ev`都是有定义的，但始终链接不上去。考虑`dyld`的搜索路径`DYLD_LD_LIBRARY`。将`/usr/local/Cellar/gcc/7.2.0/lib/gcc/7`添加到环境变量`DYLD_LD_LIBRARY`中后重新编译`libparser.a`，再编译`vasp`就能成功运行。

最后5.4.4编译成功时的环境变量

```bash
$ echo $DYLD_LIBRARY_PATH
/usr/local/Cellar/gcc/7.2.0/lib/gcc/7:/usr/local/Cellar/gcc/7.2.0/lib/gcc/7/gcc/x86_64-apple-darwin17.0.0/7.2.0/:/Users/stevezhang/software/compiler/mpich/3.2.1/intel/18.0.1/lib:/opt/intel/compilers_and_libraries_2018.1.126/mac/compiler/lib:/opt/intel/compilers_and_libraries_2018.1.126/mac/compiler/lib/intel64:/opt/intel/compilers_and_libraries_2018.1.126/mac/ipp/lib:/opt/intel/compilers_and_libraries_2018.1.126/mac/compiler/lib:/opt/intel/compilers_and_libraries_2018.1.126/mac/mkl/lib:/opt/intel/compilers_and_libraries_2018.1.126/mac/tbb/lib:/opt/intel/compilers_and_libraries_2018.1.126/mac/tbb/lib:/opt/intel/compilers_and_libraries_2018.1.126/mac/daal/lib:/opt/intel/compilers_and_libraries_2018.1.126/mac/daal/../tbb/lib:/usr/local/opt/tcl-tk/lib:/usr/local/lib:/usr/lib:
$ echo $LIBRARY_PATH
... # 和DYLD一样
$ echo $LD_LIBRARY_PATH
/usr/local/Cellar/gcc/7.2.0/lib/gcc/7:/usr/local/Cellar/gcc/7.2.0/lib/gcc/7/gcc/x86_64-apple-darwin17.0.0/7.2.0/:/Users/stevezhang/software/mathlib/scalapack/2.0.2/intel/18.0.1/:/Users/stevezhang/software/mathlib/fftw/3.3.7/intel/18.0.1/lib:/Users/stevezhang/software/compiler/mpich/3.2.1/intel/18.0.1/lib:/usr/local/opt/tcl-tk/lib:/usr/local/lib:/usr/lib:
```

注意到`LD_LIBRARY_PATH`和`LIBRARY_PATH`之间的差别, 由于MKLROOT之类的环境变量是通过

```bash
source compilervars.sh intel64
```

来添加的，可见`compilervars.sh`并没有编辑`LD_LIBRARY_PATH`这一变量。

最终可用的include文件如下

```makefile
# Precompiler options
CPP_OPTIONS = -DHOST="LinuxIFC" \
              -DMPI -DMPI_BLOCK=8000 \
              -Duse_collective \
              -DscaLAPACK \
              -DCACHE_SIZE=4000 \
              -Davoidalloc \
              -Duse_bse_te \
              -Dtbdyn \
              -Duse_shmem

CPP        = fpp -f_com=no -free -w0  $*$(FUFFIX) $*$(SUFFIX) $(CPP_OPTIONS)
FC         = mpifort
FCL        = mpifort -mkl=sequential -lstdc++

FREE       = -free -names lowercase

FFLAGS     = -assume byterecl -w
OFLAG      = -O2
OFLAG_IN   = $(OFLAG)
DEBUG      = -O0

MKL_PATH   = $(MKLROOT)/lib/
BLAS       =
LAPACK     = $(MKLROOT)/lib/libmkl_intel_lp64.a $(MKLROOT)/lib/libmkl_sequential.a $(MKLROOT)/lib/libmkl_core.a -lpthread -lm -ldl
BLACS      =
SCALAPACK  = /Users/stevezhang/software/mathlib/scalapack/2.0.2/intel/18.0.1/libscalapack.a

OBJECTS    = fftmpiw.o fftmpi_map.o fft3dlib.o fftw3d.o $(HOME)/lib/libfftw3xf_intel.a

INCS       = -m64 -I$(MKLROOT)/include/fftw -I$(MKLROOT)/include/

LLIBS      = -L/usr/local/lib/gcc/7/ $(SCALAPACK) $(LAPACK)  


OBJECTS_O1 += fftw3d.o fftmpi.o fftmpiw.o
OBJECTS_O2 += fft3dlib.o

# For what used to be vasp.5.lib
CPP_LIB    = $(CPP)
FC_LIB     = $(FC)
CC_LIB     = icc
CFLAGS_LIB = -O
FFLAGS_LIB = -O1
FREE_LIB   = $(FREE)

OBJECTS_LIB= linpack_double.o getshmem.o

# For the parser library
#CXX_PARS   = c++ #/usr/local/lib/gcc/7/libstdc++.a
#CXX_PARS = clang++ -++ -std=gnu++11
CXX_PARS = icpc -lstdc++

LIBS       += parser
LLIBS      += -Lparser  -lparser -L/usr/local/lib/gcc/7/ -lstdc++

# Normally no need to change this
SRCDIR     = ../../src
BINDIR     = ../../bin

#================================================
# GPU Stuff
#... # skipped for clarity
```

## 总结

macOS的操作系统是Darwin。

> Darwin是由苹果电脑于2000年所释出的一个开放原始码操作系统。Darwin 是MacOSX 操作环境的操作系统成份。苹果电脑于2000年把Darwin 释出给开放原始码社群。现在的Darwin皆可以在苹果电脑的PowerPC 架构和X86 架构下执行，而后者的架构只有有限的驱动程序支援。

在Darwin内存储函数库搜索路径的不是像Fedora和Ubuntu的`LD_LIBRARY_PATH`，而是`LIBRARY_PATH`和`DYLD_LIBRARY_PATH`。前者是`ld`的搜索路径，后者是动态链接指令`dyld`的搜索路径。需要使用`.la`和`.dylib`动态库时，需要将库路径加入`DYLD_LIBRARY_PATH`内。

## 附录

编译成功后，我在几乎所有的modulefile中增加了`prepend-path DYLD_LIBRARY_PATH`行，在module load它们时出现警告

```bash
dyld: warning, unknown environment variable: DYLD_LIBRARY_PATH_modshare
```

这个错误在跑vasp的时候也会产生。出现原因是`dyld`和Tcl版的`module`之间不兼容。更新到最新版本的Environment module可以解决这个问题.

## 更新

### 2019-05-02

Environment module 4.2.1已经修正了`DYLD_LIBRARY_PATH`的问题

## 参考链接

[Darwin 百度百科](https://baike.baidu.com/item/Darwin/2537108?fr=aladdin)

<http://d.hatena.ne.jp/kimuraw/20150919/p1>

[man dyld](https://developer.apple.com/legacy/library/documentation/Darwin/Reference/ManPages/man1/dyld.1.html)
