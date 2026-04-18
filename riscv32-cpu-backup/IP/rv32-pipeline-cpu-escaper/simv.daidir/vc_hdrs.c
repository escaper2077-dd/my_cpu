#ifndef _GNU_SOURCE
#define _GNU_SOURCE
#endif
#include <stdio.h>
#include <dlfcn.h>
#include "svdpi.h"

#ifdef __cplusplus
extern "C" {
#endif

/* VCS error reporting routine */
extern void vcsMsgReport1(const char *, const char *, int, void *, void*, const char *);

#ifndef _VC_TYPES_
#define _VC_TYPES_
/* common definitions shared with DirectC.h */

typedef unsigned int U;
typedef unsigned char UB;
typedef unsigned char scalar;
typedef struct { U c; U d;} vec32;

#define scalar_0 0
#define scalar_1 1
#define scalar_z 2
#define scalar_x 3

extern long long int ConvUP2LLI(U* a);
extern void ConvLLI2UP(long long int a1, U* a2);
extern long long int GetLLIresult();
extern void StoreLLIresult(const unsigned int* data);
typedef struct VeriC_Descriptor *vc_handle;

#ifndef SV_3_COMPATIBILITY
#define SV_STRING const char*
#else
#define SV_STRING char*
#endif

#endif /* _VC_TYPES_ */

#ifndef __VCS_IMPORT_DPI_STUB_dpi_instr_mem_read
#define __VCS_IMPORT_DPI_STUB_dpi_instr_mem_read
__attribute__((weak)) int dpi_instr_mem_read(/* INPUT */int A_1)
{
    static int _vcs_dpi_stub_initialized_ = 0;
    static int (*_vcs_dpi_fp_)(/* INPUT */int A_1) = NULL;
    if (!_vcs_dpi_stub_initialized_) {
        _vcs_dpi_fp_ = (int (*)(int A_1)) dlsym(RTLD_NEXT, "dpi_instr_mem_read");
        _vcs_dpi_stub_initialized_ = 1;
    }
    if (_vcs_dpi_fp_) {
        return _vcs_dpi_fp_(A_1);
    } else {
        const char *fileName;
        int lineNumber;
        svGetCallerInfo(&fileName, &lineNumber);
        vcsMsgReport1("DPI-DIFNF", fileName, lineNumber, 0, 0, "dpi_instr_mem_read");
        return 0;
    }
}
#endif /* __VCS_IMPORT_DPI_STUB_dpi_instr_mem_read */

#ifndef __VCS_IMPORT_DPI_STUB_dpi_read_regfile
#define __VCS_IMPORT_DPI_STUB_dpi_read_regfile
__attribute__((weak)) void dpi_read_regfile(const /* INPUT */svOpenArrayHandle A_1)
{
    static int _vcs_dpi_stub_initialized_ = 0;
    static void (*_vcs_dpi_fp_)(const /* INPUT */svOpenArrayHandle A_1) = NULL;
    if (!_vcs_dpi_stub_initialized_) {
        _vcs_dpi_fp_ = (void (*)(const svOpenArrayHandle A_1)) dlsym(RTLD_NEXT, "dpi_read_regfile");
        _vcs_dpi_stub_initialized_ = 1;
    }
    if (_vcs_dpi_fp_) {
        _vcs_dpi_fp_(A_1);
    } else {
        const char *fileName;
        int lineNumber;
        svGetCallerInfo(&fileName, &lineNumber);
        vcsMsgReport1("DPI-DIFNF", fileName, lineNumber, 0, 0, "dpi_read_regfile");
    }
}
#endif /* __VCS_IMPORT_DPI_STUB_dpi_read_regfile */

#ifndef __VCS_IMPORT_DPI_STUB_dpi_read_csrfile
#define __VCS_IMPORT_DPI_STUB_dpi_read_csrfile
__attribute__((weak)) void dpi_read_csrfile(const /* INPUT */svOpenArrayHandle A_1)
{
    static int _vcs_dpi_stub_initialized_ = 0;
    static void (*_vcs_dpi_fp_)(const /* INPUT */svOpenArrayHandle A_1) = NULL;
    if (!_vcs_dpi_stub_initialized_) {
        _vcs_dpi_fp_ = (void (*)(const svOpenArrayHandle A_1)) dlsym(RTLD_NEXT, "dpi_read_csrfile");
        _vcs_dpi_stub_initialized_ = 1;
    }
    if (_vcs_dpi_fp_) {
        _vcs_dpi_fp_(A_1);
    } else {
        const char *fileName;
        int lineNumber;
        svGetCallerInfo(&fileName, &lineNumber);
        vcsMsgReport1("DPI-DIFNF", fileName, lineNumber, 0, 0, "dpi_read_csrfile");
    }
}
#endif /* __VCS_IMPORT_DPI_STUB_dpi_read_csrfile */

#ifndef __VCS_IMPORT_DPI_STUB_dpi_mem_read
#define __VCS_IMPORT_DPI_STUB_dpi_mem_read
__attribute__((weak)) int dpi_mem_read(/* INPUT */int A_1, /* INPUT */int A_2, /* INPUT */unsigned long long A_3)
{
    static int _vcs_dpi_stub_initialized_ = 0;
    static int (*_vcs_dpi_fp_)(/* INPUT */int A_1, /* INPUT */int A_2, /* INPUT */unsigned long long A_3) = NULL;
    if (!_vcs_dpi_stub_initialized_) {
        _vcs_dpi_fp_ = (int (*)(int A_1, int A_2, unsigned long long A_3)) dlsym(RTLD_NEXT, "dpi_mem_read");
        _vcs_dpi_stub_initialized_ = 1;
    }
    if (_vcs_dpi_fp_) {
        return _vcs_dpi_fp_(A_1, A_2, A_3);
    } else {
        const char *fileName;
        int lineNumber;
        svGetCallerInfo(&fileName, &lineNumber);
        vcsMsgReport1("DPI-DIFNF", fileName, lineNumber, 0, 0, "dpi_mem_read");
        return 0;
    }
}
#endif /* __VCS_IMPORT_DPI_STUB_dpi_mem_read */

#ifndef __VCS_IMPORT_DPI_STUB_dpi_mem_write
#define __VCS_IMPORT_DPI_STUB_dpi_mem_write
__attribute__((weak)) void dpi_mem_write(/* INPUT */int A_1, /* INPUT */int A_2, /* INPUT */int A_3, /* INPUT */unsigned long long A_4)
{
    static int _vcs_dpi_stub_initialized_ = 0;
    static void (*_vcs_dpi_fp_)(/* INPUT */int A_1, /* INPUT */int A_2, /* INPUT */int A_3, /* INPUT */unsigned long long A_4) = NULL;
    if (!_vcs_dpi_stub_initialized_) {
        _vcs_dpi_fp_ = (void (*)(int A_1, int A_2, int A_3, unsigned long long A_4)) dlsym(RTLD_NEXT, "dpi_mem_write");
        _vcs_dpi_stub_initialized_ = 1;
    }
    if (_vcs_dpi_fp_) {
        _vcs_dpi_fp_(A_1, A_2, A_3, A_4);
    } else {
        const char *fileName;
        int lineNumber;
        svGetCallerInfo(&fileName, &lineNumber);
        vcsMsgReport1("DPI-DIFNF", fileName, lineNumber, 0, 0, "dpi_mem_write");
    }
}
#endif /* __VCS_IMPORT_DPI_STUB_dpi_mem_write */


#ifdef __cplusplus
}
#endif

